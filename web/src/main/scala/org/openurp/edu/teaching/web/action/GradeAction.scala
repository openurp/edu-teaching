/*
 * Copyright (C) 2014, The OpenURP Software.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

package org.openurp.edu.teaching.web.action

import org.beangle.commons.collection.Collections
import org.beangle.commons.lang.Strings
import org.beangle.data.dao.{EntityDao, OqlBuilder}
import org.beangle.ems.app.web.WebBusinessLogger
import org.beangle.security.Securities
import org.beangle.web.action.support.ActionSupport
import org.beangle.web.action.view.View
import org.beangle.webmvc.support.action.EntityAction
import org.openurp.base.Features
import org.openurp.base.edu.model.Teacher
import org.openurp.base.model.{Project, Semester}
import org.openurp.code.edu.model.{CourseTakeType, ExamStatus, GradeType, GradingMode}
import org.openurp.code.service.CodeService
import org.openurp.edu.clazz.model.Clazz
import org.openurp.edu.grade.config.{GradeInputSwitch, GradeRateConfig}
import org.openurp.edu.grade.model.*
import org.openurp.edu.grade.service.*
import org.openurp.edu.teaching.web.helper.{ClazzGradeReport, GradeInputHelper}
import org.openurp.starter.web.support.TeacherSupport

import java.time.Instant
import scala.collection.mutable

class GradeAction extends TeacherSupport {

  var settings: CourseGradeSettings = _

  var gradeInputSwitchService: GradeInputSwitchService = _

  var clazzGradeService: ClazzGradeService = _

  var gradeRateService: GradeRateService = _

  var calculator: CourseGradeCalculator = _

  var gradeTypePolicy: GradeTypePolicy = _

  var businessLogger: WebBusinessLogger = _

  /**
   * 录入单个教学任务成绩
   */
  protected override def projectIndex(teacher: Teacher)(using project: Project): View = {
    forward()
  }

  def clazz(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLong("clazzId").get)
    val teacher = getTeacher()
    val msg = checkClazzPermission(clazz, teacher)
    if null != msg then return forward("500", msg)

    given project: Project = clazz.project

    val gradeInputSwitch = getGradeInputSwitch(project, clazz.semester)
    put("gradeInputSwitch", gradeInputSwitch)
    val gaGradeTypes = Collections.newBuffer[GradeType]
    settings.getSetting(clazz.project).gaElementTypes foreach { gradeType =>
      val gt = getCode(classOf[GradeType], gradeType.id)
      if (gradeInputSwitch.types.contains(gt)) gaGradeTypes.addOne(gt)
    }

    val gradeTypes = gaGradeTypes.sortBy(_.code).toList
    put("gradeTypes", gradeTypes)
    put("gaGradeTypes", gradeTypes)

    val state = clazzGradeService.getOrCreateState(clazz, gradeTypes, None, None)
    put("gradeState", state)
    put("MAKEUP_GA", getCode(classOf[GradeType], GradeType.MakeupGa))
    put("GA", getCode(classOf[GradeType], GradeType.EndGa))
    put("DELAY_ID", GradeType.Delay)
    put("gradingModes", gradeRateService.getGradingModes(clazz.project))

    val grades = entityDao.findBy(classOf[CourseGrade], "clazz", clazz)
    val gradeMap = grades.map(g => (g.std, g)).toMap
    put("clazz", clazz)
    put("gradeMap", gradeMap)
    forward()
  }

  def inputGa(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLong("clazzId").get)
    val teacher = getTeacher()
    var gradeTypes = codeService.get(classOf[GradeType], Strings.splitToInt(get("gradeTypeIds", "")): _*).toList
    val gradingMode = getInt("gradingModeId").map(x => getCode(classOf[GradingMode], x))
    val gradeState = clazzGradeService.getOrCreateState(clazz, gradeTypes, getInt("precision"), gradingMode)
    val check = checkSwitch(clazz, teacher, gradeState)
    if (null != check) return check

    given project: Project = clazz.project

    val setting = settings.getSetting(clazz.project)
    val helper = new GradeInputHelper(entityDao, calculator)

    val updatePercent = helper.populatePercent(gradeState, gradeTypes)
    gradeTypes = clazzGradeService.cleanZeroPercents(gradeState, gradeTypes)
    put("gradeTypes", gradeTypes)
    if (updatePercent) clazzGradeService.recalculate(gradeState)

    helper.putGradeMap(clazz, null)
    helper.buildGradeConfig(clazz, gradeState, gradeTypes)
    put("GA", getCode(classOf[GradeType], GradeType.EndGa))
    put("USUAL", getCode(classOf[GradeType], GradeType.Usual))
    put("DELAY", getCode(classOf[GradeType], GradeType.Delay))

    put("ABSENT", ExamStatus.Absent)
    put("NEW", Grade.Status.New)
    put("CONFIRMED", Grade.Status.Confirmed)
    put("gradeRateConfigs", gradeRateService.getGradeItems(project))

    put("examStatuses", getCodes(classOf[ExamStatus]))
    put("NormalTakeType", getCode(classOf[CourseTakeType], CourseTakeType.Normal))
    put("NormalExamStatus", getCode(classOf[ExamStatus], ExamStatus.Normal))
    put("gradeTypePolicy", gradeTypePolicy)
    put("gradeState", gradeState)
    put("setting", setting)
    put("clazz", clazz)
    forward()
  }

  /**
   * 保存总评成绩
   *
   * @return
   */
  def saveGa(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLong("clazzId").get)
    val teacher = getTeacher()
    val project = clazz.project
    val gradeState = clazzGradeService.getState(clazz)
    val check = checkSwitch(clazz, teacher, gradeState)
    if (null != check) return check

    // 查找成绩
    val submit = !getBoolean("justSave", true)
    val helper = new GradeInputHelper(entityDao, calculator)
    val existGradeMap = helper.getGradeMap(clazz, false)
    val setting = settings.getSetting(project)
    val isPublish = setting.submitIsPublish
    if (submit) { //删除多出来的总评组成部分
      existGradeMap.values foreach { grade =>
        if (!grade.published) {
          setting.gaElementTypes foreach { gt =>
            grade.getExamGrade(gt) foreach { eg =>
              gradeState.getState(gt) match {
                case null => grade.examGrades -= eg
                case egs: ExamGradeState => if (egs.scorePercent.getOrElse(0) == 0) grade.examGrades -= eg
              }
            }
          }
        }
      }
    }
    val updatedAt = Instant.now
    val grades = Collections.newBuffer[CourseGrade]
    val status = if (submit) Grade.Status.Confirmed else Grade.Status.New
    // 遍历教学班中的每一个学生
    val takers = helper.getCourseTakers(clazz)
    val gradeTypes = codeService.get(classOf[GradeType], Strings.splitToInt(get("gradeTypeIds", "")): _*).toList
    for (taker <- takers) {
      val grade = helper.build(clazz, gradeState, existGradeMap.get(taker.std), taker, gradeTypes, status, updatedAt)
      if (null != grade) grades.addOne(grade)
    }
    val operator = Securities.user
    if (submit) updateGradeState(gradeState, gradeTypes, Grade.Status.Confirmed, updatedAt, operator)
    else updateGradeState(gradeState, gradeTypes, Grade.Status.New, updatedAt, operator)
    val params = new StringBuilder("&clazzId=" + clazz.id)
    params.append("&gradeTypeIds=")
    for (gradeType <- gradeTypes) {
      params.append(gradeType.id + ",")
    }
    entityDao.saveOrUpdate(grades, gradeState)
    if (submit) {
      if (isPublish) {
        val publishables = collection.mutable.Set.from(clazzGradeService.getPublishableGradeTypes(clazz.project))
        publishables.addOne(new GradeType(GradeType.EndGa))
        publishables.addOne(new GradeType(GradeType.Final))
        clazzGradeService.publish(clazz.id + "", publishables.toArray, true)
      }
      // FIXME 这个event没有对应的handler publish(new CourseGradeSubmitEvent(gradeState))
    }
    params.deleteCharAt(params.length - 1)
    val toInputGradeTypeIdStr = get("toInputGradeType.id", "")
    if (Strings.isNotEmpty(toInputGradeTypeIdStr)) {
      params.append("&toInputGradeType.ids=" + get("toInputGradeType.id"))
      val toInputGradeTypeIds = Strings.splitToInt(toInputGradeTypeIdStr)
      for (gradeTypeId <- toInputGradeTypeIds) {
        if (gradeTypeId != GradeType.EndGa) {
          params.append("&" + gradeTypeId + "Percent=" + get(gradeTypeId + "Percent", ""))
        }
      }
    }
    businessLogger.info((if (submit) "录入" else "提交") + s"${clazz.crn}的期末总评成绩", clazz.id, Map.empty)
    redirect(if submit then "reportGa" else "inputGa", params.toString, "info.save.success")
  }

  def reportGa(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLong("clazzId").get)
    val grades = entityDao.findBy(classOf[CourseGrade], "clazz", clazz)
    val gradeState = clazzGradeService.getState(clazz)
    val reports = ClazzGradeReport.build(gradeState, grades, true, settings.getSetting(clazz.project), 3000)
    put("END", getCode(classOf[GradeType], GradeType.End))
    put("GA", getCode(classOf[GradeType], GradeType.EndGa))
    put("reports", reports)
    forward()
  }

  def removeGa(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLong("clazzId").get)
    val teacher = getTeacher()
    val gradeState = clazzGradeService.getState(clazz)
    val check = checkSwitch(clazz, teacher, gradeState)
    if (null != check) return check

    clazzGradeService.remove(clazz, getCode(classOf[GradeType], GradeType.EndGa))
    businessLogger.info(s"删除了${clazz.crn}的期末总评成绩", clazz.id, Map.empty)
    redirect("clazz", "clazzId=" + clazz.id, "info.remove.success")
  }

  def inputMakeup(): View = {
    forward()
  }

  def saveMakeup(): View = {
    forward()
  }

  private def checkSwitch(clazz: Clazz, teacher: Teacher, gradeState: CourseGradeState): View = {
    val msg = checkClazzPermission(clazz, teacher)
    if null != msg then return forward("500", msg)
    val gradeInputSwitch = getGradeInputSwitch(clazz.project, clazz.semester)
    if (!gradeInputSwitch.checkOpen(Instant.now)) return redirect("index", "录入尚未开放")
    if (gradeState.isStatus(new GradeType(GradeType.EndGa), Grade.Status.Confirmed)) {
      redirect("submitResult", "classId=" + clazz.id, "info.save.success")
    } else null
  }

  private def checkClazzPermission(clazz: Clazz, teacher: Teacher): String = {
    if (null == teacher) "只有教师才可以录入成绩"
    else if (!clazz.teachers.contains(teacher)) "没有权限"
    else null
  }

  @deprecated
  //FIXME use CourseGradeState.updateStatus
  protected def updateGradeState(gradeState: CourseGradeState, gradeTypes: Iterable[GradeType], status: Int, updatedAt: Instant, operator: String): Unit = {
    gradeTypes foreach { gradeType =>
      if (gradeType.id == GradeType.EndGa) gradeState.status = status
      val gs = gradeState.getState(gradeType).asInstanceOf[AbstractGradeState]
      gs.operator = operator
      gs.status = status
      gs.updatedAt = updatedAt
    }
    gradeState.updatedAt = updatedAt
    gradeState.operator = operator
  }

  private def getGradeInputSwitch(project: Project, semester: Semester) = {
    var s = gradeInputSwitchService.getSwitch(project, semester)
    if (null == s) {
      s = new GradeInputSwitch
      s.project = project
      s.semester = semester
      s.types.addAll(codeService.get(classOf[GradeType]))
    }
    s
  }
}
