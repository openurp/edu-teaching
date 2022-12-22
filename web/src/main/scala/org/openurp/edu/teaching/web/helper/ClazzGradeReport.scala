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
import org.openurp.code.edu.model.GradeType
import org.openurp.edu.clazz.model.Clazz
import org.openurp.edu.grade.model.{CourseGrade, CourseGradeState}
import org.openurp.edu.grade.service.CourseGradeSetting

object ClazzGradeReport {
  def build(gradeState: CourseGradeState, courseGrades: Seq[CourseGrade], isEndGa: Boolean, setting: CourseGradeSetting, pageSize: Int): Seq[ClazzGradeReport] = {
    if (isEndGa) {
      val grades = courseGrades.sortBy(_.std.code)
      val elemTypes = gradeState.examStates.filter(x => setting.gaElementTypes.contains(x.gradeType) && x.scorePercent.isDefined).map(_.gradeType)
      val gradeTypes = elemTypes.toBuffer.sortBy(_.code).addOne(gradeState.getState(new GradeType(GradeType.EndGa)).gradeType)
      Collections.split(grades.toList, pageSize) map { grades =>
        ClazzGradeReport(gradeState.clazz, gradeState, grades, gradeTypes)
      }
    } else {
      val gradeTypes = Set(new GradeType(GradeType.Makeup), new GradeType(GradeType.Delay))
      val grades = courseGrades.filter(x => x.examGrades.exists(eg => gradeTypes.contains(eg.gradeType))).sortBy(_.std.code)
      Collections.split(grades.toList, pageSize) map { grades =>
        ClazzGradeReport(gradeState.clazz, gradeState, grades, gradeTypes)
      }
    }
  }
}

case class ClazzGradeReport(clazz: Clazz, gradeState: CourseGradeState, grades: List[CourseGrade], gradeTypes: Iterable[GradeType]) {

}
