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

package org.openurp.edu.teaching.web.helper

import org.beangle.commons.collection.Collections
import org.beangle.commons.lang.Strings
import org.beangle.data.dao.{EntityDao, OqlBuilder}
import org.beangle.security.Securities
import org.beangle.web.action.context.{ActionContext, Params}
import org.openurp.base.std.model.Student
import org.openurp.code.edu.model.*
import org.openurp.edu.clazz.model.{Clazz, CourseTaker}
import org.openurp.edu.exam.model.ExamTaker
import org.openurp.edu.grade.model.{CourseGrade, CourseGradeState, ExamGrade, ExamGradeState}
import org.openurp.edu.grade.service.{CourseGradeCalculator, GradingModeStrategy}

import java.time.Instant

class GradeInputHelper(private val entityDao: EntityDao, private val calculator: CourseGradeCalculator) {
  /**
   * 查询一个教学班中的学生成绩
   * <p>
   * 要求能够查询到没有clazz_id的，但是是这个课程的学生的已有成绩（例如其他课程序号、或者免修得来的）。
   *
   * @param clazz
   * @param courseTakers
   * @return
   */
  def getGradeMap(clazz: Clazz, courseTakers: Iterable[CourseTaker], addEmpty: Boolean): Map[Student, CourseGrade] = {
    if (null == clazz || courseTakers == null || courseTakers.isEmpty) return Map.empty
    //查找该教学任务的成绩
    val query1 = OqlBuilder.from(classOf[CourseGrade], "cg").where("cg.clazz = :clazz", clazz)
    val gradeMap = Collections.newMap[Student, CourseGrade]
    val grades1 = entityDao.search(query1)
    var stds = courseTakers.map(_.std).toSet
    for (grade <- grades1) {
      gradeMap.put(grade.std, grade)
      stds -= grade.std
    }
    //查找可能出现任务为空，或者别的任务里的该班学生的成绩
    if (stds.nonEmpty) {
      val query2 = OqlBuilder.from(classOf[CourseGrade], "cg")
        .where("cg.project = :project and cg.semester = :semester and cg.course = :course", clazz.project, clazz.semester, clazz.course)
      query2.where("cg.std in(:stds)", clazz, stds)
      val grades2 = entityDao.search(query2)
      for (grade <- grades2) {
        gradeMap.put(grade.std, grade)
        stds -= grade.std
      }
    }
    if addEmpty && stds.nonEmpty then stds foreach { std => gradeMap.put(std, new CourseGrade) }
    gradeMap.toMap
  }

  def getGradeMap(clazz: Clazz, addEmpty: Boolean): Map[Student, CourseGrade] = {
    getGradeMap(clazz, clazz.enrollment.courseTakers, addEmpty)
  }

  def getCourseTakers(clazz: Clazz): List[CourseTaker] = {
    clazz.enrollment.courseTakers.sortBy(_.std.code).toList
  }

  def putGradeMap(clazz: Clazz, takers: List[CourseTaker]): Unit = {
    val courseTakers = if null == takers then this.getCourseTakers(clazz) else takers
    ActionContext.current.attribute("courseTakers", courseTakers)
    ActionContext.current.attribute("gradeMap", getGradeMap(clazz, courseTakers, true))
  }

  /**
   * 处理除百分比记录方式外的录入项
   *
   * @param task
   * @param gradeTypes
   */
  def buildGradeConfig(clazz: Clazz, gradeState: CourseGradeState, gradeTypes: Iterable[GradeType]): Unit = {
    val gradingModes = Collections.newMap[String, GradingMode]
    val examTypes = Collections.newSet[ExamType]
    for (gradeType <- gradeTypes) {
      val gradeTypeState = gradeState.getState(gradeType)
      if (gradeTypeState != null) {
        val gradingMode = gradeTypeState.gradingMode
        if (null == gradingMode) gradeTypeState.gradingMode = gradeState.gradingMode
        gradeType.examType foreach { et => examTypes.add(et) }
      }
    }
    for (gradeTypeState <- gradeState.examStates) {
      gradingModes.put(gradeTypeState.gradeType.id.toString, gradeTypeState.gradingMode)
    }
    ActionContext.current.attribute("gradingModes", gradingModes)
    ActionContext.current.attribute("stdExamTypeMap", getStdExamTypeMap(clazz, examTypes.toSet))
  }

  /**
   * 根据教学任务、教学任务教学班学生和考试类型组装一个Map
   *
   * @param task
   * @param examTypes
   * @return
   */
  protected def getStdExamTypeMap(clazz: Clazz, examTypes: Set[ExamType]): Map[String, ExamTaker] = {
    if (Collections.isEmpty(clazz.enrollment.courseTakers) || examTypes.isEmpty) return Map.empty
    val query = OqlBuilder.from(classOf[ExamTaker], "examTaker").where("examTaker.clazz=:clazz", clazz)
    query.where("examTaker.examType in (:examTypes)", examTypes)
    val stdExamTypeMap = Collections.newMap[String, ExamTaker]
    val examTakers = entityDao.search(query)
    for (examTaker <- examTakers) {
      stdExamTypeMap.put(examTaker.std.id.toString + "_" + examTaker.examType.id, examTaker)
    }
    stdExamTypeMap.toMap
  }

  /**
   * 接受成绩状态的百分比和记录方式
   *
   * @param gradeState
   * @param gradeTypes
   * @return
   */
  def populatePercent(gradeState: CourseGradeState, gradeTypes: Iterable[GradeType]): Boolean = {
    var updatePercent = false
    for (gradeType <- gradeTypes; if !gradeType.isGa) {
      val prefix = "examGradeState" + gradeType.id
      Params.getShort(prefix + ".scorePercent").foreach { percent =>
        val egs = GradingModeStrategy.getOrCreateState(gradeState, gradeType).asInstanceOf[ExamGradeState]
        if (egs.scorePercent.isEmpty || percent != egs.scorePercent.get) {
          egs.scorePercent = Some(percent)
          updatePercent = true
        }
        Params.getInt(prefix + ".gradingMode.id") foreach { examGradingModeId =>
          egs.gradingMode = entityDao.get(classOf[GradingMode], examGradingModeId)
        }
      }
    }
    updatePercent
  }

  /**
   * 每一个学生的成绩
   */
  def build(clazz: Clazz, gradeState: CourseGradeState, existed: Option[CourseGrade], taker: CourseTaker,
            gradeTypes: Iterable[GradeType], status: Int, updatedAt: Instant): CourseGrade = {
    val operator = Securities.user
    val grade = existed match {
      case None => buildNewCourseGrade(taker, gradeState, status, updatedAt)
      case Some(exist) =>
        if (exist.courseTakeType.id == CourseTakeType.Exemption) {
          exist.clazz = Some(clazz)
          exist.crn = clazz.crn
          return exist
        }
        if (null != taker) exist.courseTakeType = taker.takeType
        exist.gradingMode = gradeState.gradingMode
        exist
    }
    Params.get("courseGrade.remark" + taker.std.id) foreach { r => grade.remark = Some(r) }
    grade.operator = Some(operator)
    grade.updatedAt = updatedAt
    // 针对每个成绩类型
    for (gradeType <- gradeTypes) {
      if (!gradeType.isGa) {
        val egs = gradeState.getState(gradeType).asInstanceOf[ExamGradeState]
        var percent = Params.getShort("personPercent_" + gradeType.id + "_" + taker.std.id)
        if (percent.isEmpty && egs.scorePercent.nonEmpty) percent = egs.scorePercent
        buildExamGrade(grade, gradeType, egs.gradingMode, taker, status, percent, updatedAt, operator)
      }
    }
    if (Collections.isEmpty(grade.examGrades)) return null
    val hasMakeup = gradeTypes.exists(_.isMakeupOrDeplay)
    if (hasMakeup) calculator.calcMakeupDelayGa(grade, gradeState)
    else calculator.calcEndGa(grade, gradeState)
    for (gg <- grade.gaGrades) {
      if (gradeTypes.toSeq.contains(gg.gradeType)) if (gg.status < status) gg.status = status
    }
    if (null != clazz.exam && null != clazz.exam.examMode) grade.examMode = clazz.exam.examMode
    if (grade.status < status) grade.status = status
    grade
  }

  /**
   * 每一个成绩类型
   */
  private[helper] def buildExamGrade(grade: CourseGrade, gradeType: GradeType, gradingMode: GradingMode, taker: CourseTaker,
                                     status: Int, percent: Option[Short], updatedAt: Instant, operator: String): Unit = {
    val scoreInputName = gradeType.id + "_" + taker.std.id
    val examScoreStr = Params.get(scoreInputName).getOrElse("")
    var examStatusId = Params.getInt("examStatus_" + scoreInputName).getOrElse(ExamStatus.Normal)
    // 输入值无效
    if (null == examScoreStr && ExamStatus.Normal == examStatusId && !(gradeType.id == GradeType.EndGa)) return
    val examScore = Params.getFloat(scoreInputName)
    // 获得考试情况
    var examStatus: ExamStatus = null
    if (status == 2 && Strings.isEmpty(examScoreStr) && examStatusId == ExamStatus.Normal) examStatusId = ExamStatus.Absent
    examStatus = entityDao.get(classOf[ExamStatus], examStatusId)
    var examGrade = grade.getExamGrade(gradeType).orNull
    if (null == examGrade) {
      //FIXME use ExamGrade(gradeType,,) createdAt,updatedAt
      examGrade = new ExamGrade(0, gradeType, examScore, null, gradingMode, false, status)
      examGrade.createdAt = updatedAt
      grade.addExamGrade(examGrade)
    }
    grade.updatedAt = updatedAt
    examGrade.scorePercent = percent
    examGrade.examStatus = examStatus
    examGrade.status = status
    calculator.updateScore(examGrade, examScore, gradingMode)
  }

  /**
   * 新增成绩
   */
  private[helper] def buildNewCourseGrade(taker: CourseTaker, gradeState: CourseGradeState, status: Int, updatedAt: Instant) = {
    val grade = newGrade(taker)
    grade.gradingMode = gradeState.gradingMode
    grade.status = status
    grade.project = taker.std.project
    grade
  }

  @deprecated("CourseGrade(taker)")
  //FIXME
  private def newGrade(taker: CourseTaker): CourseGrade = {
    val g = new CourseGrade()
    g.std = taker.std
    val clazz = taker.clazz
    g.clazz = Some(clazz)
    g.crn = clazz.crn
    g.semester = clazz.semester
    g.course = clazz.course
    g.courseType = taker.courseType
    g.courseTakeType = taker.takeType
    g.freeListening = taker.freeListening
    g.createdAt = Instant.now
    g
  }
}
