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
import org.beangle.data.dao.OqlBuilder
import org.beangle.template.freemarker.ProfileTemplateLoader
import org.beangle.web.action.view.View
import org.openurp.base.edu.model.TimeSetting
import org.openurp.base.edu.service.TimeSettingService
import org.openurp.base.hr.model.Teacher
import org.openurp.base.model.{Project, Semester}
import org.openurp.code.edu.model.TeachingNature
import org.openurp.edu.clazz.config.ScheduleSetting
import org.openurp.edu.clazz.domain.{ClazzProvider, WeekTimeBuilder}
import org.openurp.edu.schedule.service.CourseTable
import org.openurp.edu.service.Features
import org.openurp.starter.web.support.TeacherSupport

class CoursetableAction extends TeacherSupport {

  var timeSettingService: TimeSettingService = _

  var clazzProvider: ClazzProvider = _

  override def projectIndex(teacher: Teacher)(using project: Project): View = {
    val semester = getSemester
    val setting = getSwitch(project, semester)
    put("weekdays", semester.calendar.weekdays)
    put("semester", semester)

    val table = new CourseTable(semester, teacher, "teacher")
    table.placePublished = setting.placePublished
    table.timePublished = setting.timePublished
    val weektimes = WeekTimeBuilder.build(semester, "*")
    table.setClazzes(clazzProvider.getClazzes(semester, teacher, project), weektimes)
    val campuses = table.clazzes.map(_.campus).toSet
    val settings = Collections.newBuffer[TimeSetting]
    campuses foreach { c =>
      try {
        val setting = timeSettingService.get(project, semester, Some(c))
        settings.addOne(setting)
      } catch {
        case e: Exception =>
      }
    }
    table.timeSetting = settings.head
    table.style = CourseTable.Style.WEEK_TABLE
    if (getConfig(Features.Clazz.TableStyle) == "UNIT_COLUMN") {
      table.style = CourseTable.Style.UNIT_COLUMN
    }
    put("showClazzIndex", getConfig(Features.Clazz.IndexSupported))
    put("teachingNatures", codeService.get(classOf[TeachingNature]))
    put("table", table)
    ProfileTemplateLoader.setProfile(project.id)
    forward()
  }

  // 该学期课程安排是否发布
  private def getSwitch(project: Project, semester: Semester): ScheduleSetting = {
    val query = OqlBuilder.from(classOf[ScheduleSetting], "setting")
    query.where("setting.project = :project", project)
    query.where("setting.semester =:semester", semester)
    query.cacheable()
    entityDao.search(query).headOption match {
      case None =>
        val ns = new ScheduleSetting
        ns.placePublished = true
        ns.timePublished = true
        ns
      case Some(s) => s
    }
  }

}
