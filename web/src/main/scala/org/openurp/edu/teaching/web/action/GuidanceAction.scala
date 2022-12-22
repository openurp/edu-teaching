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
import org.beangle.web.action.view.View
import org.openurp.base.edu.model.{Course, Teacher, Terms}
import org.openurp.base.model.{Project, Semester}
import org.openurp.base.service.TermCalculator
import org.openurp.base.std.model.Student
import org.openurp.code.edu.model.{CourseTakeType, GradeType, GradingMode}
import org.openurp.edu.grade.model.{CourseGrade, GaGrade, Grade}
import org.openurp.edu.grade.service.CourseGradeCalculator
import org.openurp.starter.web.support.TeacherSupport

import java.time.Instant

/**
 * 导师指导学生的主课成绩录入
 */
class GuidanceAction extends TeacherSupport {
  var businessLogger: WebBusinessLogger = _
  var calculator: CourseGradeCalculator = _

  override def projectIndex(teacher: Teacher)(using project: Project): View = {
    val semester = getSemester()
    put("semester", semester)

    val courseTerms = getGuidanceCourses(project)
    put("courses", courseTerms.keys.toSeq.sortBy(_.code))
    if (courseTerms.nonEmpty) {
      val stds = getStds(teacher, semester)
      val activeStds = Collections.newSet[Student]
      val stdCourseTerms = Collections.newMap[String, Int]
      val termCalculator = new TermCalculator(project, semester, entityDao)
      for (std <- stds; course <- courseTerms.keys) {
        val term = termCalculator.getTerm(std.grade, true)
        if (courseTerms(course).contains(term)) {
          stdCourseTerms.put(s"${std.id}_${course.id}", term)
          activeStds.add(std)
        }
      }
      put("stds", activeStds.toSeq.sortBy(x => x.grade.code + x.code))
      put("stdCourseTerms", stdCourseTerms)
      if (stds.nonEmpty) {
        val grades = getGrades(project, semester, courseTerms.keys, stds)
        val rs = grades.groupBy(_.course).map {
          case (c, gs) => (c, gs.groupBy(_.std).map(x => (x._1, x._2.head)))
        }
        put("gradeMap", rs)
      } else {
        put("gradeMap", Map.empty)
      }
    }
    forward()
  }

  private def getGrades(project: Project, semester: Semester, courses: Iterable[Course], stds: Iterable[Student]): Seq[CourseGrade] = {
    val gradeQuery = OqlBuilder.from(classOf[CourseGrade], "grade")
    gradeQuery.where("grade.std in(:stds)", stds)
    gradeQuery.where("grade.project=:project and grade.semester=:semester", project, semester)
    gradeQuery.where("grade.course in(:course)", courses)
    entityDao.search(gradeQuery)
  }

  private def getGuidanceCourses(project: Project): Map[Course, Terms] = {
    val courseTerms = getProjectProperty("edu.course.guidance_course_terms", "2022101510473710477=1,2,3,4;2022101510481410498=5,6")(using project)
    if (Strings.isBlank(courseTerms)) {
      Map.empty
    } else {
      val course2Term = Collections.newMap[Course, Terms]
      Strings.split(courseTerms, ";") foreach { courseTerm =>
        val data = Strings.split(courseTerm, "=")
        val course = entityDao.get(classOf[Course], data(0).toLong)
        val term = Terms(data(1))
        course2Term.put(course, term)
      }
      course2Term.toMap
    }
  }

  private def getStds(teacher: Teacher, semester: Semester): Seq[Student] = {
    val stdQuery = OqlBuilder.from(classOf[Student], "std").where("std.tutor=:me", teacher)
    stdQuery.where("std.beginOn < :endOn and :beginOn < std.endOn", semester.endOn, semester.beginOn)
    stdQuery.orderBy("std.state.grade.code,std.code")
    entityDao.search(stdQuery)
  }

  def save(): View = {
    val project = getProject()
    val semester = getSemester()
    val teacher = getTeacher()

    val courses = getGuidanceCourses(project).keys
    if (courses.nonEmpty) {
      val stds = getStds(teacher, semester)
      if (stds.nonEmpty) {
        val grades = getGrades(project, semester, courses, stds)
        val gradeMap = grades.groupBy(_.course).map {
          case (c, gs) => (c, gs.groupBy(_.std).map(x => (x._1, x._2.head)))
        }
        val gradingMode = entityDao.get(classOf[GradingMode], GradingMode.Percent)
        val endGaType = entityDao.get(classOf[GradeType], GradeType.EndGa)
        for (std <- stds; course <- courses) {
          getFloat(s"${std.id}_${course.id}.score") match {
            case Some(score) =>
              val grade = gradeMap.getOrElse(course, Map.empty).get(std) match {
                case None =>
                  val g = new CourseGrade
                  g.project = project
                  g.semester = semester
                  g.course = course
                  g.std = std
                  g.createdAt = Instant.now
                  g.updatedAt = Instant.now
                  g.crn = "--"
                  g.operator = Some(Securities.user)
                  g.gradingMode = gradingMode
                  g.courseType = course.courseType
                  g.examMode = course.examMode
                  val ctt = new CourseTakeType()
                  ctt.id = CourseTakeType.Normal
                  g.courseTakeType = ctt
                  val gaGrade = g.addGaGrade(endGaType, Grade.Status.Published)
                  gaGrade.operator = Some(Securities.user)
                  g
                case Some(g) =>
                  val gaGrade = g.addGaGrade(endGaType, Grade.Status.Published)
                  gaGrade.operator = Some(Securities.user)
                  g
              }
              grade.getGaGrade(endGaType) foreach { gaGrade =>
                val oldScore = gaGrade.score.getOrElse(-1f)
                if (oldScore != score) {
                  calculator.updateScore(gaGrade, Some(score), grade.gradingMode)
                  calculator.calcFinal(grade)
                  entityDao.saveOrUpdate(grade)
                  val msg =
                    if oldScore < 0 then s"录入了${std.code}的${course.name}成绩：${score}"
                    else s"修改了${std.code}的${course.name}成绩：从${oldScore}改为${score}"

                  businessLogger.info(msg, grade.id, Map.empty)
                }
              }
            case None =>
              if (get(s"${std.id}_${course.id}.score").nonEmpty) {
                gradeMap.getOrElse(course, Map.empty).get(std) foreach { grade =>
                  val oldScore = grade.score.map(_.toString).getOrElse("")
                  val msg = s"删除了${std.code}的${course.name}成绩：$oldScore"
                  businessLogger.info(msg, grade.id, Map.empty)
                }
              }
          }
        }
      }
    }
    redirect("index", s"semester.id=${semester.id}", "info.save.success")
  }
}
