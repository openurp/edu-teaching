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

import org.beangle.data.dao.{EntityDao, OqlBuilder}
import org.beangle.web.action.annotation.{mapping, response}
import org.beangle.web.action.context.ActionContext
import org.beangle.web.action.support.ActionSupport
import org.beangle.webmvc.support.action.EntityAction
import org.openurp.code.edu.model.GradeType
import org.openurp.code.service.CodeService
import org.openurp.edu.grade.model.{CourseGrade, CourseGradeState, ExamGrade, GaGrade}
import org.openurp.edu.grade.service.{CourseGradeCalculator, GradeRateService}

class GradeCalculatorAction extends ActionSupport, EntityAction[CourseGrade] {
  var entityDao: EntityDao = _

  var calculator: CourseGradeCalculator = _

  var codeService: CodeService = _

  var gradeRateService: GradeRateService = _

  @response
  @mapping
  def index(): String = {
    val state = entityDao.get(classOf[CourseGradeState], getLong("gradeStateId").get)
    val clazz = state.clazz
    val grade = populate(classOf[CourseGrade], "grade")
    val existGrade = entityDao.search(OqlBuilder.from(classOf[CourseGrade], "cg")
      .where("cg.std=:std and cg.clazz=:clazz", grade.std, clazz)).headOption
    var isMakeup = false
    var isDelay = false

    grade.semester = clazz.semester
    grade.clazz = Some(clazz)
    grade.gradingMode = state.gradingMode

    codeService.get(classOf[GradeType]) foreach { gradeType =>
      get(s"examGrade${gradeType.id}.gradeType.id") foreach { et =>
        val eg = populate(classOf[ExamGrade], s"examGrade${gradeType.id}")
        if (eg.gradeType.id == GradeType.Delay) {
          isDelay = true
          existGrade foreach { exist =>
            exist.getExamGrade(new GradeType(GradeType.Usual)) foreach { e => grade.examGrades.addOne(e) }
            exist.getExamGrade(new GradeType(GradeType.End)) foreach { e => grade.examGrades.addOne(e) }
          }
        } else if (eg.gradeType.id == GradeType.Makeup) {
          isMakeup = true
        }
        grade.addExamGrade(eg)
      }
    }

    var gaGrade: GaGrade = null
    if (isMakeup || isDelay) gaGrade = calculator.calcMakeupDelayGa(grade, state)
    else gaGrade = calculator.calcEndGa(grade, state)

    val rs =
      if (null != gaGrade) {
        val converter = gradeRateService.getConverter(clazz.project, state.gradingMode)
        val ga = gaGrade.score
        val passed = converter.passed(ga)
        converter.convert(ga).getOrElse("") + "," + (if passed then 1 else 0)
      } else ",0"
    ActionContext.current.response.getWriter.print(rs)
    null
  }
}
