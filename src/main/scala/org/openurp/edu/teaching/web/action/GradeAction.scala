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
import org.beangle.data.dao.OqlBuilder
import org.beangle.ems.app.web.WebBusinessLogger
import org.beangle.security.Securities
import org.beangle.webmvc.view.View
import org.openurp.base.hr.model.Teacher
import org.openurp.base.model.{Project, Semester}
import org.openurp.base.std.model.Student
import org.openurp.code.edu.model.*
import org.openurp.edu.clazz.domain.ClazzProvider
import org.openurp.edu.clazz.model.{Clazz, CourseTaker}
import org.openurp.edu.course.model.ExamAnalysis
import org.openurp.edu.exam.model.ExamTaker
import org.openurp.edu.grade.config.GradeInputSwitch
import org.openurp.edu.grade.model.*
import org.openurp.edu.grade.service.*
import org.openurp.edu.grade.service.stat.GradeSegStat
import org.openurp.edu.service.Features
import org.openurp.edu.teaching.web.helper.{ClazzGradeReport, GradeInputHelper}
import org.openurp.starter.web.support.TeacherSupport

import java.time.Instant
import scala.collection.immutable.Map
import scala.collection.mutable

class GradeAction extends TeacherSupport {

  var settings: CourseGradeSettings = _

  var gradeInputSwitchService: GradeInputSwitchService = _

  var clazzGradeService: ClazzGradeService = _

  var clazzProvider: ClazzProvider = _

  var gradeRateService: GradeRateService = _

  var calculator: CourseGradeCalculator = _

  var gradeTypePolicy: GradeTypePolicy = _

  var businessLogger: WebBusinessLogger = _

  var makeupStdStrategy: MakeupStdStrategy = _

  /**
   * 录入单个教学任务成绩
   */
  protected override def projectIndex(teacher: Teacher)(using project: Project): View = {
    val semester = getSemester
    put("semester", semester)
    val clazzes = clazzProvider.getClazzes(semester, teacher, project)
    put("clazzes", clazzes)
    val gradeStates = Collections.newMap[Clazz, CourseGradeState]
    clazzes foreach { clazz =>
      val state = clazzGradeService.getState(clazz)
      if (state != null) gradeStates.put(clazz, state)
    }
    put("makeupTakerCounts", makeupStdStrategy.getCourseTakerCounts(clazzes))
    put("gradeStates", gradeStates)
    put("gradeInputSwitch", getGradeInputSwitch(project, semester))
    put("EndGa", codeService.get(classOf[GradeType], GradeType.EndGa))
    put("MakeupGa", codeService.get(classOf[GradeType], GradeType.MakeupGa))
    put("DelayGa", codeService.get(classOf[GradeType], GradeType.DelayGa))
    forward()
  }

  /** 显示成绩状态的小面板
   *
   * @return
   */
  def statePanel(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLongId("clazz"))
    val project = clazz.project
    val gradeInputSwitch = getGradeInputSwitch(project, clazz.semester)
    put("gradeInputSwitch", gradeInputSwitch)
    var state = clazzGradeService.getState(clazz)
    if (null == state) state = new CourseGradeState()
    put("gradeState", state)
    putGradeConsts()
    put("makeupTakerCounts", makeupStdStrategy.getCourseTakerCounts(List(clazz)))
    put("clazz", clazz)
    forward()
  }

  def info(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLong("clazzId").get)
    val grades = entityDao.findBy(classOf[CourseGrade], "clazz", clazz)
    val examGradeTypes = Collections.newSet[GradeType]
    grades.foreach { g => g.examGrades.foreach { eg => examGradeTypes.addOne(eg.gradeType) } }
    val gradeTypes = examGradeTypes.toBuffer.sortBy(_.code)
    gradeTypes.addOne(getCode(classOf[GradeType], GradeType.EndGa))
    put("gradeTypes", gradeTypes)

    val state = clazzGradeService.getState(clazz)
    put("gradeState", state)

    val gradeMap = grades.map(g => (g.std, g)).toMap
    put("clazz", clazz)
    put("grades", grades)
    put("gradeMap", gradeMap)
    put("EndGa", getCode(classOf[GradeType], GradeType.EndGa))
    forward()
  }

  /** 进入单门课程录入的首页面（包括百分比、报表以及录入）
   *
   * @return
   */
  def clazz(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLong("clazzId").get)
    val teacher = getTeacher
    val msg = checkOwnerPermission(clazz, teacher)
    if null != msg then return forward("500", msg)

    given project: Project = clazz.project

    val gradeInputSwitch = getGradeInputSwitch(project, clazz.semester)
    put("gradeInputSwitch", gradeInputSwitch)

    val gaGradeTypes = Collections.newBuffer[GradeType]
    val setting = settings.getSetting(clazz.project)
    setting.gaElementTypes foreach { gradeType =>
      val gt = getCode(classOf[GradeType], gradeType.id)
      if (gradeInputSwitch.types.contains(gt)) gaGradeTypes.addOne(gt)
    }

    val gradeTypes = gaGradeTypes.sortBy(_.code).toList
    put("gradeTypes", gradeTypes)
    put("gaGradeTypes", gradeTypes)

    val state = clazzGradeService.getOrCreateState(clazz, gradeTypes, None, None)
    if (setting.gaElementTypes.size == 1) {
      state.getState(setting.gaElementTypes.head).asInstanceOf[ExamGradeState].weight = Some(100)
    }
    put("gradeState", state)
    putGradeConsts()
    put("gradingModes", gradeRateService.getGradingModes(clazz.project))

    val grades = entityDao.findBy(classOf[CourseGrade], "clazz", clazz)
    val gradeMap = grades.map(g => (g.std, g)).toMap
    put("clazz", clazz)
    put("gradeMap", gradeMap)
    forward()
  }

  private def putGradeConsts(): Unit = {
    put("Usual", getCode(classOf[GradeType], GradeType.Usual))
    put("End", getCode(classOf[GradeType], GradeType.End))
    put("Delay", getCode(classOf[GradeType], GradeType.Delay))
    put("Makeup", getCode(classOf[GradeType], GradeType.Makeup))

    put("EndGa", codeService.get(classOf[GradeType], GradeType.EndGa))
    put("MakeupGa", codeService.get(classOf[GradeType], GradeType.MakeupGa))
    put("DelayGa", codeService.get(classOf[GradeType], GradeType.DelayGa))
    put("FINAL", codeService.get(classOf[GradeType], GradeType.Final))

    put("ABSENT", ExamStatus.Absent)
    put("NEW", Grade.Status.New)
    put("CONFIRMED", Grade.Status.Confirmed)

    put("NormalTakeType", getCode(classOf[CourseTakeType], CourseTakeType.Normal))
    put("NormalExamStatus", getCode(classOf[ExamStatus], ExamStatus.Normal))
  }

  /** 输入总评成绩界面
   *
   * @return
   */
  def inputGa(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLongId("clazz"))
    val teacher = getTeacher
    var gradeTypes = codeService.get(classOf[GradeType], Strings.splitToInt(get("gradeTypeIds", "")): _*).toList
    val gradingMode = getInt("gradingModeId").map(x => getCode(classOf[GradingMode], x))
    val gradeState = clazzGradeService.getOrCreateState(clazz, gradeTypes, getInt("precision"), gradingMode)
    val check = checkEndGaPermission(clazz, teacher, gradeState)
    if (null != check) return check

    given project: Project = clazz.project

    val setting = settings.getSetting(clazz.project)
    val helper = new GradeInputHelper(entityDao, calculator, clazzGradeService)

    val updatePercent = helper.populatePercent(gradeState, gradeTypes)
    gradeTypes = clazzGradeService.cleanZeroPercents(gradeState, gradeTypes)
    put("gradeTypes", gradeTypes)
    if (updatePercent) clazzGradeService.recalculate(gradeState)

    helper.putGradeMap(clazz, null)
    helper.buildGradeConfig(clazz, gradeState, gradeTypes)
    putGradeConsts()
    put("gradeRateConfigs", gradeRateService.getGradeItems(project))

    put("examStatuses", getCodes(classOf[ExamStatus]))
    put("gradeTypePolicy", gradeTypePolicy)
    put("gradeState", gradeState)
    put("setting", setting)
    put("clazz", clazz)
    val inputTwiceEnabled = getConfig(Features.Grade.InputTwice).asInstanceOf[Boolean]
    if (inputTwiceEnabled) {
      put("inputComplete", clazzGradeService.isInputComplete(clazz, clazz.enrollment.courseTakers, gradeTypes))
    }
    put("inputTwiceEnabled", inputTwiceEnabled)
    put("secondInput", getBoolean("secondInput", false))
    forward()
  }

  /**
   * 保存期末总评成绩
   *
   * @return
   */
  def saveGa(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLong("clazzId").get)
    val teacher = getTeacher

    given project: Project = clazz.project

    val gradeState = clazzGradeService.getState(clazz)
    val check = checkEndGaPermission(clazz, teacher, gradeState)
    if (null != check) return check

    // 查找成绩
    val submit = !getBoolean("justSave", true)
    val helper = new GradeInputHelper(entityDao, calculator, clazzGradeService)
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
                case egs: ExamGradeState => if (egs.weight.getOrElse(0) == 0) grade.examGrades -= eg
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

    //如果启用两遍录入，则需要统计提交前是否已经录入了一遍
    val inputTwiceEnabled = getConfig(Features.Grade.InputTwice).asInstanceOf[Boolean]
    var beforeInputComplete = false
    if inputTwiceEnabled then beforeInputComplete = clazzGradeService.isInputComplete(clazz, takers, gradeTypes)

    for (taker <- takers) {
      val grade = helper.build(clazz, gradeState, existGradeMap.get(taker.std), taker, gradeTypes, status, updatedAt)
      if (null != grade) grades.addOne(grade)
    }
    val operator = Securities.user
    if (submit) gradeState.updateStatus(gradeTypes, Grade.Status.Confirmed, updatedAt, operator)
    else gradeState.updateStatus(gradeTypes, Grade.Status.New, updatedAt, operator)

    entityDao.saveOrUpdate(grades, gradeState)
    if (submit & isPublish) {
      val publishables = collection.mutable.Set.from(clazzGradeService.getPublishableGradeTypes(clazz.project))
      publishables.addOne(new GradeType(GradeType.EndGa))
      publishables.addOne(new GradeType(GradeType.Final))
      clazzGradeService.publish(clazz.id + "", publishables.toArray, true)
    }
    val params = new StringBuilder("&clazzId=" + clazz.id)
    params.append("&gradeTypeIds=").append(gradeTypes.map(_.id).mkString(","))
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
    //如果是启用两遍录入，则需要告诉页面是第二遍录入
    if (inputTwiceEnabled) {
      val afterInputComplete = clazzGradeService.isInputComplete(clazz, takers, gradeTypes)
      if !beforeInputComplete && afterInputComplete then params.append("&secondInput=1")
    }
    businessLogger.info((if (submit) "录入" else "提交") + s"${clazz.crn}的期末总评成绩", clazz.id, Map.empty)
    redirect(if submit then "report" else "inputGa", params.toString, "info.save.success")
  }

  def removeGa(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLongId("clazz"))
    val teacher = getTeacher
    val gradeState = clazzGradeService.getState(clazz)
    val check = checkEndGaPermission(clazz, teacher, gradeState)
    if (null != check) return check

    clazzGradeService.remove(clazz, getCode(classOf[GradeType], GradeType.EndGa))
    businessLogger.info(s"删除了${clazz.crn}的期末总评成绩", clazz.id, Map.empty)
    redirect("clazz", "clazzId=" + clazz.id, "info.remove.success")
  }

  /** 撤回期末总评
   *
   * @return
   */
  def revokeGa(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLongId("clazz"))
    val teacher = getTeacher
    val gradeState = clazzGradeService.getState(clazz)
    val check = checkPermission(clazz, teacher, gradeState, GradeType.EndGa, Grade.Status.Published)
    if (null != check) return check
    val setting = settings.getSetting(clazz.project)
    setting.gaElementTypes foreach { gt =>
      val s = gradeState.getState(gt)
      if (null != s) s.status = Grade.Status.New
    }
    gradeState.getState(new GradeType(GradeType.EndGa)).status = Grade.Status.New
    entityDao.saveOrUpdate(gradeState)
    clazzGradeService.recalculate(gradeState)
    redirect("clazz", "clazzId=" + clazz.id, "撤回成功")
  }

  def revokeMakeup(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLongId("clazz"))
    val teacher = getTeacher
    val gradeState = clazzGradeService.getState(clazz)
    val check = checkPermission(clazz, teacher, gradeState, GradeType.MakeupGa, Grade.Status.Published)
    if (null != check) return check
    val setting = settings.getSetting(clazz.project)

    val gradeTypes = Collections.newBuffer[GradeType]
    List(GradeType.Makeup, GradeType.MakeupGa, GradeType.Delay, GradeType.DelayGa) foreach { gradeTypeId =>
      val gt = entityDao.get(classOf[GradeType], gradeTypeId)
      val s = gradeState.getState(gt)
      if (null != s) s.status = Grade.Status.New
    }
    entityDao.saveOrUpdate(gradeState)
    clazzGradeService.recalculate(gradeState)
    redirect("clazz", "clazzId=" + clazz.id, "撤回成功")
  }

  def inputMakeup(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLongId("clazz"))

    given project: Project = clazz.project

    val teacher = getTeacher
    val setting = settings.getSetting(clazz.project)
    val gradeTypes = Collections.newBuffer[GradeType]
    List(GradeType.Makeup, GradeType.MakeupGa, GradeType.Delay, GradeType.DelayGa) foreach { gradeTypeId =>
      gradeTypes.addOne(entityDao.get(classOf[GradeType], gradeTypeId))
    }
    val gradeState = clazzGradeService.getOrCreateState(clazz, gradeTypes, None, None)
    val check = checkPermission(clazz, teacher, gradeState, GradeType.MakeupGa, Grade.Status.Published)
    if (null != check) return check

    val helper = new GradeInputHelper(entityDao, calculator, clazzGradeService)
    val courseTakers = makeupStdStrategy.getCourseTakers(clazz)
    helper.putGradeMap(clazz, courseTakers)
    helper.buildGradeConfig(clazz, gradeState, gradeTypes)
    put("gradeTypes", gradeTypes)
    putGradeConsts()
    val examStatuses = getCodes(classOf[ExamStatus])
    put("examStatuses", examStatuses.toBuffer.subtractAll(examStatuses.filter(x => x.name.contains("缓考"))))
    put("gradeTypePolicy", gradeTypePolicy)
    put("gradeState", gradeState)
    put("setting", setting)
    put("clazz", clazz)
    val inputTwiceEnabled = getConfig(Features.Grade.InputTwice).asInstanceOf[Boolean]
    if (inputTwiceEnabled) {
      put("inputComplete", clazzGradeService.isInputComplete(clazz, courseTakers, gradeTypes))
    }
    put("inputTwiceEnabled", inputTwiceEnabled)
    put("secondInput", getBoolean("secondInput", false))
    forward()
  }

  def saveMakeup(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLong("clazzId").get)
    val teacher = getTeacher

    given project: Project = clazz.project

    val gradeState = clazzGradeService.getState(clazz)
    val check = checkMakeupGaPermission(clazz, teacher, gradeState)
    if (null != check) return check

    // 查找成绩
    val submit = !getBoolean("justSave", true)
    val helper = new GradeInputHelper(entityDao, calculator, clazzGradeService)
    val existGradeMap = helper.getGradeMap(clazz, false)
    val setting = settings.getSetting(project)
    val isPublish = setting.submitIsPublish
    val updatedAt = Instant.now
    val grades = Collections.newBuffer[CourseGrade]
    val status = if (submit) Grade.Status.Confirmed else Grade.Status.New
    // 遍历换补缓考中的每一个学生
    val takers = makeupStdStrategy.getCourseTakers(clazz)
    val gradeTypes = Collections.newBuffer[GradeType]
    List(GradeType.Makeup, GradeType.MakeupGa, GradeType.Delay, GradeType.DelayGa) foreach { gradeTypeId =>
      gradeTypes.addOne(entityDao.get(classOf[GradeType], gradeTypeId))
    }

    //如果启用两遍录入，则需要统计提交前是否已经录入了一遍
    val inputTwiceEnabled = getConfig(Features.Grade.InputTwice).asInstanceOf[Boolean]
    var beforeInputComplete = false
    if inputTwiceEnabled then beforeInputComplete = clazzGradeService.isInputComplete(clazz, takers, gradeTypes)

    for (taker <- takers) {
      val grade = helper.build(clazz, gradeState, existGradeMap.get(taker.std), taker, gradeTypes, status, updatedAt)
      if (null != grade) grades.addOne(grade)
    }
    val operator = Securities.user
    if (submit) gradeState.updateStatus(gradeTypes, Grade.Status.Confirmed, updatedAt, operator)
    else gradeState.updateStatus(gradeTypes, Grade.Status.New, updatedAt, operator)
    entityDao.saveOrUpdate(grades, gradeState)
    if (submit & isPublish) {
      val publishables = collection.mutable.Set.from(clazzGradeService.getPublishableGradeTypes(clazz.project))
      publishables.addOne(new GradeType(GradeType.EndGa))
      publishables.addOne(new GradeType(GradeType.Final))
      clazzGradeService.publish(clazz.id + "", publishables.toArray, true)
    }

    businessLogger.info((if (submit) "录入" else "提交") + s"${clazz.crn}的补缓考成绩", clazz.id, Map.empty)
    if submit then
      redirect("report", s"&clazzId=${clazz.id}&gradeTypeId=${GradeType.MakeupGa}", "info.save.success")
    else
      val params = new StringBuilder("&clazzId=" + clazz.id)
      params.append("&gradeTypeIds=").append(gradeTypes.map(_.id).mkString(","))
      //如果是启用两遍录入，则需要告诉页面是第二遍录入
      if (inputTwiceEnabled) {
        val afterInputComplete = clazzGradeService.isInputComplete(clazz, takers, gradeTypes)
        if !beforeInputComplete && afterInputComplete then params.append("&secondInput=1")
      }
      redirect("inputMakeup", params.toString, "info.save.success")
  }

  def removeMakeup(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLongId("clazz"))
    val teacher = getTeacher
    val gradeState = clazzGradeService.getState(clazz)
    val check = checkMakeupGaPermission(clazz, teacher, gradeState)
    if (null != check) return check

    clazzGradeService.remove(clazz, getCode(classOf[GradeType], GradeType.MakeupGa))
    businessLogger.info(s"删除了${clazz.crn}的补缓成绩", clazz.id, Map.empty)
    redirect("clazz", "clazzId=" + clazz.id, "info.remove.success")
  }

  def report(): View = {
    val gradeTypeIds = getLongIds("gradeType")
    val clazz = entityDao.get(classOf[Clazz], getLong("clazzId").get)
    val grades = entityDao.findBy(classOf[CourseGrade], "clazz", clazz)
    val gradeState = clazzGradeService.getState(clazz)
    val isEndGa = gradeTypeIds.isEmpty || gradeTypeIds.contains(GradeType.EndGa)
    val reports = ClazzGradeReport.build(gradeState, grades, isEndGa, settings.getSetting(clazz.project), 3000)
    put("reports", reports)
    putGradeConsts()
    forward(if isEndGa then "report/reportGa" else "report/reportMakeup")
  }

  /** 空白成绩登分表
   *
   * @return
   */
  def blank(): View = {
    val clazzes = entityDao.find(classOf[Clazz], getLongIds("clazz"))

    var gradeTypes = Collections.newBuffer[GradeType]
    val courseTakers = Collections.newMap[Clazz, collection.Seq[CourseTaker]]
    val courseGrades = Collections.newMap[Clazz, collection.Map[Student, CourseGrade]]
    val examTakers = Collections.newMap[Clazz, collection.Map[Student, ExamTaker]]
    val states = Collections.newMap[Clazz, CourseGradeState]
    var makeup = getBoolean("makeup", false)
    getInt("gradeType.id") foreach { g =>
      makeup = codeService.get(classOf[GradeType], g).isMakeupOrDeplay
    }

    if (makeup) {
      gradeTypes = codeService.get(classOf[GradeType], GradeType.Delay, GradeType.Makeup).toBuffer
      for (clazz <- clazzes) {
        var cgs = clazzGradeService.getState(clazz)
        if (null == cgs) cgs = new CourseGradeState
        states.put(clazz, cgs)
        val takers = makeupStdStrategy.getCourseTakers(clazz)
        courseTakers.put(clazz, takers)
        if (takers.isEmpty) {
          courseGrades.put(clazz, Map.empty)
          examTakers.put(clazz, Map.empty)
        } else {
          //打印补考、缓考成绩时，需要显示平时，或者期末
          val grades = entityDao.findBy(classOf[CourseGrade], "clazz" -> clazz, "std" -> takers.map(_.std))
          courseGrades.put(clazz, grades.map(x => (x.std, x)).toMap)
          examTakers.put(clazz, getExamTakerMap(clazz, ExamType.Delay, ExamType.Makeup))
        }
      }
      put("Usual", entityDao.get(classOf[GradeType], GradeType.Usual))
      put("End", entityDao.get(classOf[GradeType], GradeType.End))
      put("EndGa", entityDao.get(classOf[GradeType], GradeType.EndGa))
    } else {
      for (clazz <- clazzes) {
        var cgs = clazzGradeService.getState(clazz)
        if (null == cgs) cgs = new CourseGradeState
        states.put(clazz, cgs)
        val takers = clazz.enrollment.courseTakers
        courseTakers.put(clazz, takers)
        if (takers.isEmpty) {
          courseGrades.put(clazz, Map.empty)
          examTakers.put(clazz, Map.empty)
        } else {
          val cgBuilder = OqlBuilder.from(classOf[CourseGrade], "cg")
            .where("cg.semester=:semester", clazz.semester)
            .where("cg.project=:project", clazz.project)
            .where("cg.course=:course", clazz.course)
            .where("cg.std in (:stds)", takers.map(_.std))
          cgBuilder.where("cg.courseTakeType.id=:exemption", CourseTakeType.Exemption)
          courseGrades.put(clazz, entityDao.search(cgBuilder).map(x => (x.std, x)).toMap)
          examTakers.put(clazz, getExamTakerMap(clazz, ExamType.Final))
        }
      }
      val setting = settings.getSetting(clazzes.head.project)
      for (gradeType <- setting.gaElementTypes) {
        val freshedGradeType = entityDao.get(classOf[GradeType], gradeType.id)
        gradeTypes.addOne(freshedGradeType)
      }
      val ga = entityDao.get(classOf[GradeType], GradeType.EndGa)
      put("EndGa", ga)
      gradeTypes.addOne(ga)
    }
    put("clazzes", clazzes)
    put("courseTakerMap", courseTakers)
    put("courseGradeMap", courseGrades)
    put("examTakerMap", examTakers)
    put("stateMap", states)
    put("gradeTypes", gradeTypes.sortBy(_.code))
    forward(if (makeup) "report/blankMakeup" else "report/blankGa")
  }

  def examAnalysis(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLongId("clazz"))
    val grades = entityDao.findBy(classOf[CourseGrade], "clazz", clazz)
    val gradeType = entityDao.get(classOf[GradeType], GradeType.End)
    val stats = GradeSegStat.stat(grades, List(gradeType), GradeSegStat.getDefaultSegments)
    put("clazz", clazz)
    put("stats", stats)
    val analysis = entityDao.findBy(classOf[ExamAnalysis], "clazz", clazz)
    put("analysis", analysis.headOption)
    forward()
  }

  def examReport(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLongId("clazz"))
    val teacher = getTeacher
    assert(clazz.teachers.contains(teacher))
    val grades = entityDao.findBy(classOf[CourseGrade], "clazz", clazz)
    val gradeType = entityDao.get(classOf[GradeType], GradeType.End)
    val stats = GradeSegStat.stat(grades, List(gradeType), GradeSegStat.getDefaultSegments)
    put("stats", stats)
    put("clazz", clazz)
    var analysis = entityDao.findBy(classOf[ExamAnalysis], "clazz", clazz).headOption
    get("analysisContents") foreach { c =>
      if (analysis.isEmpty) {
        val n = new ExamAnalysis
        n.clazz = clazz
        n.updatedAt = Instant.now
        n.contents = c
        entityDao.saveOrUpdate(n)
        analysis = Some(n)
      } else {
        analysis.head.contents = c
      }
    }
    if (analysis.isEmpty) {
      forward("examAnalysis")
    } else {
      put("analysis", analysis)
      forward()
    }
  }

  /**
   * 根据教学任务、教学任务教学班学生和考试类型组装一个Map
   *
   * @param clazz
   * @param examTypeIds
   * @return
   */
  protected def getExamTakerMap(clazz: Clazz, examTypeIds: Int*): Map[Student, ExamTaker] = {
    val query = OqlBuilder.from(classOf[ExamTaker], "examTaker").where("examTaker.clazz =:clazz", clazz)
    query.where("examTaker.examType.id in (:examTypeIds)", examTypeIds)
    entityDao.search(query).map(x => (x.std, x)).toMap
  }

  private def checkEndGaPermission(clazz: Clazz, teacher: Teacher, gradeState: CourseGradeState) = {
    checkPermission(clazz, teacher, gradeState, GradeType.EndGa, Grade.Status.Confirmed)
  }

  private def checkMakeupGaPermission(clazz: Clazz, teacher: Teacher, gradeState: CourseGradeState): View = {
    checkPermission(clazz, teacher, gradeState, GradeType.MakeupGa, Grade.Status.Confirmed)
  }

  private def checkPermission(clazz: Clazz, teacher: Teacher, gradeState: CourseGradeState, gaGradeTypeId: Int, checkedStatus: Int): View = {
    val msg = checkOwnerPermission(clazz, teacher)
    if null != msg then return forward("500", msg)
    val s = getGradeInputSwitch(clazz.project, clazz.semester)

    if (!s.checkOpen(Instant.now)) return redirect("index", "录入尚未开放")
    if (gradeState.isStatus(new GradeType(gaGradeTypeId), checkedStatus)) {
      redirect("submitResult", "classId=" + clazz.id, "info.save.success")
    } else null
  }

  private def checkOwnerPermission(clazz: Clazz, teacher: Teacher): String = {
    if (null == teacher) "只有教师才可以录入成绩"
    else if (!clazz.teachers.contains(teacher)) "没有权限"
    else null
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
