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
import org.beangle.data.dao.{EntityDao, OqlBuilder}
import org.openurp.base.edu.model.Course
import org.openurp.base.hr.model.Teacher
import org.openurp.base.model.{Project, Semester, User}
import org.openurp.base.std.model.Student
import org.openurp.edu.clazz.config.ScheduleSetting
import org.openurp.edu.clazz.domain.ClazzProvider
import org.openurp.edu.clazz.model.{MiniClazz, MiniClazzActivity}

import scala.collection.mutable

class OccupyHelper(entityDao: EntityDao, clazzProvider: ClazzProvider) {
  var maxWeekday = 5
  var maxUnit = 0

  def merge(m1: collection.Map[String, String], m2: collection.Map[String, String]): collection.Map[String, String] = {
    val rs = new mutable.HashMap[String, String]
    rs.addAll(m1)
    m2 foreach { case (k, v) =>
      rs.get(k) match {
        case None => rs.put(k, v)
        case Some(v2) => if (v != v2) rs.put(k, v + " " + v2)
      }
    }
    rs
  }

  def getCoachMiniOccupy(project: Project, semester: Semester, coach: User): collection.Map[String, String] = {
    val q = OqlBuilder.from[MiniClazz](classOf[MiniClazzActivity].getName, "activity")
    q.where("activity.miniClazz.semester=:semester", semester)
    q.where("activity.advisor1 = :me or activity.advisor2 = :me", coach)
    q.select("distinct activity.miniClazz")
    val clazzes = entityDao.search(q)

    getCoachMiniOccupy(coach, clazzes)
  }

  def getCoachMiniOccupy(coach: User, clazzes: Iterable[MiniClazz]): collection.Map[String, String] = {
    val activities = clazzes.flatMap(_.activities)
    val miniOccupyMap = Collections.newMap[String, mutable.Set[Student]]
    activities foreach { a =>
      if (a.advisor1.contains(coach) || a.advisor2.contains(coach)) {
        val weekdayId = a.time.weekday.id
        if weekdayId > maxWeekday then maxWeekday = weekdayId
        (a.beginUnit.intValue to a.endUnit.intValue) foreach { u =>
          if u > maxUnit then maxUnit = u
          miniOccupyMap.getOrElseUpdate(s"${weekdayId}_${u}", new mutable.HashSet[Student]).addAll(a.miniClazz.stds)
        }
      }
    }
    miniOccupyMap.map(x => (x._1, x._2.map(_.name).mkString(",")))
  }

  def getTeacherMiniOccupy(project: Project, semester: Semester, teacher: Teacher): collection.Map[String, String] = {
    val query = OqlBuilder.from(classOf[MiniClazz], "clazz")
    query.where("clazz.semester=:semester", semester)
    query.where("clazz.teacher=:me", teacher)
    val clazzes = entityDao.search(query)
    val miniOccupyMap = Collections.newMap[String, mutable.Set[Student]]
    clazzes foreach { clazz =>
      clazz.activities foreach { a =>
        val weekdayId = a.time.weekday.id
        if weekdayId > maxWeekday then maxWeekday = weekdayId
        (a.beginUnit.intValue to a.endUnit.intValue) foreach { u =>
          if u > maxUnit then maxUnit = u
          miniOccupyMap.getOrElseUpdate(s"${weekdayId}_${u}", new mutable.HashSet[Student]).addAll(clazz.stds)
        }
      }
    }
    miniOccupyMap.map(x => (x._1, x._2.map(_.name).mkString(",")))
  }

  def getTeacherCourseOccupy(project: Project, semester: Semester, teacher: Teacher): collection.Map[String, String] = {
    val occupyMap = Collections.newMap[String, mutable.Set[Course]]
    val scheduleSetting = getScheduleSetting(project, semester)
    if (scheduleSetting.timePublished) {
      clazzProvider.getClazzes(semester, teacher, project) foreach { clazz =>
        clazz.schedule.activities foreach { a =>
          val weekdayId = a.time.weekday.id
          if weekdayId > maxWeekday then maxWeekday = weekdayId
          (a.beginUnit.intValue to a.endUnit.intValue) foreach { u =>
            if u > maxUnit then maxUnit = u
            occupyMap.getOrElseUpdate(s"${weekdayId}_${u}", new mutable.HashSet[Course]).addOne(clazz.course)
          }
        }
      }
    }
    occupyMap.map(x => (x._1, x._2.map(_.name).mkString(",")))
  }

  def getStudentOccupy(std: Student, semester: Semester): collection.Map[String, String] = {
    val occupyMap = Collections.newMap[String, mutable.Set[Course]]
    val scheduleSetting = getScheduleSetting(std.project, semester)
    if (scheduleSetting.timePublished) {
      clazzProvider.getClazzes(semester, std) foreach { ct =>
        val clazz = ct.clazz
        clazz.schedule.activities foreach { a =>
          val weekdayId = a.time.weekday.id
          if weekdayId > maxWeekday then maxWeekday = weekdayId
          (a.beginUnit.intValue to a.endUnit.intValue) foreach { u =>
            if u > maxUnit then maxUnit = u
            occupyMap.getOrElseUpdate(s"${weekdayId}_${u}", new mutable.HashSet[Course]).addOne(clazz.course)
          }
        }
      }
    }
    occupyMap.map(x => (x._1, x._2.map(_.name).mkString(",")))
  }

  // 该学期课程安排是否发布
  private def getScheduleSetting(project: Project, semester: Semester): ScheduleSetting = {
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
