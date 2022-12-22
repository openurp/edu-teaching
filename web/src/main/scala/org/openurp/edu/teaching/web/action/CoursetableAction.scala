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

import org.apache.poi.ss.formula.functions.WeekdayFunc
import org.beangle.data.dao.{EntityDao, OqlBuilder}
import org.beangle.web.action.view.View
import org.openurp.base.edu.model.Teacher
import org.openurp.base.edu.service.TimeSettingService
import org.openurp.base.model.{Project, Semester}
import org.openurp.base.service.SemesterService
import org.openurp.code.edu.model.TeachingNature
import org.openurp.code.service.CodeService
import org.openurp.edu.clazz.config.ScheduleSetting
import org.openurp.edu.clazz.domain.{ClazzProvider, WeekTimeBuilder}
import org.openurp.edu.clazz.model.Clazz
import org.openurp.edu.schedule.service.CourseTable
import org.openurp.starter.web.support.TeacherSupport

class CoursetableAction extends TeacherSupport {

  var timeSettingService: TimeSettingService = _

  var clazzProvider: ClazzProvider = _

  override def projectIndex(teacher: Teacher)(using project: Project): View = {
    val semester = getSemester()
    put("weekdays", semester.calendar.weekdays)
    put("scheduleSetting", getSwitch(project, semester))
    put("semester", semester)

    val weektimes = WeekTimeBuilder.build(semester, "*")
    val table = new CourseTable(semester, teacher, "teacher")
    table.setClazzes(clazzProvider.getClazzes(semester, teacher, project), weektimes)
    table.timeSetting = timeSettingService.get(project, semester, None)
    put("tableStyle", "WEEK_TABLE")
    put("teachingNatures", codeService.get(classOf[TeachingNature]))
    put("table", table)
    forward()
  }

  // 该学期课程安排是否发布
  private def getSwitch(project: Project, semester: Semester): ScheduleSetting = {
    val query = OqlBuilder.from(classOf[ScheduleSetting], "setting")
    query.where("setting.project = :project", project)
    query.where("setting.semester =:semester", semester)
    query.cacheable()
    entityDao.search(query).headOption.getOrElse(new ScheduleSetting)
  }

}
