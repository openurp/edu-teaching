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

import org.beangle.webmvc.view.View
import org.openurp.base.hr.model.Teacher
import org.openurp.base.model.Project
import org.openurp.code.edu.model.TeachingMethod
import org.openurp.edu.clazz.domain.ClazzProvider
import org.openurp.edu.clazz.model.Clazz
import org.openurp.edu.course.model.{Lesson, ClazzPlan}
import org.openurp.edu.schedule.service.{LessonSchedule, ScheduleDigestor}
import org.openurp.starter.web.support.TeacherSupport

import java.time.LocalTime

class PlanAction extends TeacherSupport {

  var clazzProvider: ClazzProvider = _

  protected override def projectIndex(teacher: Teacher)(using project: Project): View = {
    val semester = getSemester
    put("semester", semester)
    val clazzes = clazzProvider.getClazzes(semester, teacher, project)
    val scheduled = clazzes.filter(_.schedule.activities.nonEmpty)
    if (scheduled.nonEmpty) {
      put("plans", entityDao.findBy(classOf[ClazzPlan], "clazz", scheduled).groupBy(_.clazz))
    }
    put("clazzes", scheduled)
    forward()
  }

  def clazz(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLongId("clazz"))
    val plans = entityDao.findBy(classOf[ClazzPlan], "clazz", clazz)
    if (plans.isEmpty) {
      redirect("edit", s"&clazz.id=${clazz.id}")
    } else {
      put("plan", plans.head)
      forward()
    }
  }

  def edit(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLongId("clazz"))

    given project: Project = clazz.project

    val plans = entityDao.findBy(classOf[ClazzPlan], "clazz", clazz)
    val plan = plans.headOption.getOrElse(new ClazzPlan)
    put("plan", plan)
    put("clazz", clazz)
    put("schedule_time", ScheduleDigestor.digest(clazz, ":day :units :weeks"))
    put("schedule_space", ScheduleDigestor.digest(clazz, ":room"))
    put("teachingForms", getCodes(classOf[TeachingMethod]))
    val semester = clazz.semester
    val beginAt = semester.beginOn.atTime(LocalTime.MIN)
    val endAt = semester.endOn.atTime(LocalTime.MAX)

    val schedules = LessonSchedule.convert(clazz.schedule.activities, beginAt, endAt)
    if (plan.lessons.isEmpty) {
      var idx = 0
      schedules.sortBy(_.date) foreach { schedule =>
        idx += 1
        val lesson = new Lesson()
        lesson.plan = plan
        lesson.idx = idx
        lesson.remark = Some(schedule.room)
        plan.lessons.addOne(lesson)
      }
    }
    forward()
  }

  def save(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLongId("clazz"))
    val plans = entityDao.findBy(classOf[ClazzPlan], "clazz", clazz)
    val plan = plans.headOption.getOrElse(new ClazzPlan)
    forward()
  }
}
