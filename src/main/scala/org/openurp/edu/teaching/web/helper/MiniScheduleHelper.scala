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

import org.beangle.commons.bean.orderings.PropertyOrdering
import org.beangle.commons.collection.Collections
import org.beangle.commons.lang.Strings
import org.beangle.commons.lang.time.{WeekState, WeekTime, Weeks}
import org.openurp.base.model.Semester
import org.openurp.edu.clazz.domain.WeekTimeBuilder
import org.openurp.edu.miniclazz.model.{MiniClazz, MiniClazzActivity}

object MiniScheduleHelper {

  val defaultFormat = ":day :units :weeks"

  val day = ":day"
  val units = ":units"
  val weeks = ":weeks"
  val time = ":time"
  val places = ":places"

  private val delimeter = ","
  private val weekdayNamesCn = Array("empty", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六", "星期日")

  def digest(miniClazz: MiniClazz): String = {
    val activities = miniClazz.activities.filter(_.teacher.nonEmpty)
    digest(activities, ":day :units :places")
  }

  def digestCoach(miniClazz: MiniClazz): String = {
    val activities = miniClazz.activities.filter(_.teacher.isEmpty)
    digest(activities, ":day :units :places")
  }

  def digest(activities: collection.Iterable[MiniClazzActivity], f: String = defaultFormat): String = {
    if (activities.isEmpty) return ""
    var format = f
    if (Strings.isEmpty(format)) format = MiniScheduleHelper.defaultFormat
    val clazzx = activities.iterator.next.miniClazz
    val semester = clazzx.semester
    val hasRoom = Strings.contains(format, MiniScheduleHelper.places)
    var mergedActivities = MiniScheduleHelper.merge(semester, activities, hasRoom)

    val buf = new StringBuffer
    mergedActivities = mergedActivities.sorted(PropertyOrdering.by("time.startOn"))
    // 合并后的教学活动
    for (activity <- mergedActivities) {
      buf.append(format)
      var replaceStart = 0
      replaceStart = buf.indexOf(MiniScheduleHelper.day)
      if (-1 != replaceStart) {
        val weekday = activity.time.weekday
        buf.replace(replaceStart, replaceStart + MiniScheduleHelper.day.length, weekdayNamesCn(weekday.id))
      }
      replaceStart = buf.indexOf(MiniScheduleHelper.units)
      if (-1 != replaceStart) {
        buf.replace(replaceStart, replaceStart + MiniScheduleHelper.units.length, activity.beginUnit + "-" + activity.endUnit)
      }
      replaceStart = buf.indexOf(MiniScheduleHelper.time)
      if (-1 != replaceStart) {
        // 如果教学活动中有具体时间
        buf.replace(replaceStart, replaceStart + MiniScheduleHelper.time.length, activity.time.beginAt.toString + "-" + activity.time.endAt.toString)
      }
      replaceStart = buf.indexOf(MiniScheduleHelper.weeks)
      if (-1 != replaceStart) {
        // 以本年度的最后一周(而不是从教学日历周数计算而来)作为结束周进行缩略.
        // 是因为很多日历指定的周数,仅限于教学使用了.
        buf.replace(replaceStart, replaceStart + MiniScheduleHelper.weeks.length, WeekTimeBuilder.digest(activity.time, semester) + " ")
      }
      replaceStart = buf.indexOf(MiniScheduleHelper.places)
      if (-1 != replaceStart) {
        val roomStr = activity.places.getOrElse("--")
        buf.replace(replaceStart, replaceStart + MiniScheduleHelper.places.length, roomStr)
      }
    }
    if (buf.lastIndexOf(delimeter) != -1) buf.delete(buf.lastIndexOf(delimeter), buf.length)
    buf.toString
  }

  def merge(semester: Semester, activities: collection.Iterable[MiniClazzActivity], hasRoom: Boolean): collection.Seq[MiniClazzActivity] = {
    val mergedActivities = Collections.newBuffer[MiniClazzActivity]
    val activitiesList = Collections.newBuffer[MiniClazzActivity]
    for (ca <- activities) {
      activitiesList.addOne(clone(ca))
    }
    //    activitiesList = activitiesList.sorted
    val semesterStartYear = semester.beginOn.getYear
    // 合并相同时间点(不计年份)的教学活动
    for (ca <- activitiesList) {
      val activity = ca
      if (ca.time.startOn.getYear != semesterStartYear) {
        val nextYearStart = activity.time.startOn
        val thisYearStart = WeekTime.getStartOn(semesterStartYear, activity.time.weekday)
        val weeks = Weeks.between(thisYearStart, nextYearStart)
        activity.time.startOn = thisYearStart
        activity.time.weekstate = new WeekState(activity.time.weekstate.value << weeks)
      }
      var merged = false
      for (added <- mergedActivities) {
        if (added.miniClazz == activity.miniClazz && isSameActivityExcept(added, activity, hasRoom)) {
          mergeTime(added, activity)
          merged = true
        }
      }
      if (!merged) mergedActivities.addOne(activity)
    }
    mergedActivities
  }

  def enlarge(clazz: MiniClazz, maxweeks: Int): Boolean = {
    if (clazz.activities.isEmpty) {
      false
    } else {
      var changed = false
      if (enlarge(clazz, maxweeks, false)) {
        changed = true
      }
      if (enlarge(clazz, maxweeks, true)) {
        changed = true
      }
      changed
    }
  }

  private def enlarge(clazz: MiniClazz, maxweeks: Int, isCoach: Boolean): Boolean = {
    val activities = if isCoach then clazz.activities.filter(_.teacher.isEmpty) else clazz.activities.filter(_.teacher.nonEmpty)
    val semester = clazz.semester
    var enlarged = false
    val merged = merge(semester, activities.map(x => clone(x)), true)

    merged foreach { activity =>
      val weeks = activity.time.weekstate.size
      if (weeks < maxweeks) {
        val builder = WeekTimeBuilder.on(semester)
        val times = builder.build(activity.time.weekday, 1 to maxweeks)
        times foreach { t =>
          t.beginAt = activity.time.beginAt
          t.endAt = activity.time.endAt
        }
        val exists = activities.filter { x => x.time.weekday == activity.time.weekday && x.beginUnit == activity.beginUnit }
        val existsIter = exists.iterator
        val timeIter = times.iterator
        while (existsIter.hasNext && timeIter.hasNext) {
          val exist = existsIter.next()
          val time = timeIter.next()
          exist.time.startOn = time.startOn
          exist.time.weekstate = time.weekstate
        }
        while (timeIter.hasNext) {
          val time = timeIter.next()
          val na = clone(activity)
          na.time = time
          clazz.activities.addOne(na)
          enlarged = true
        }
      }
    }
    clazz.calcHours()
    true
  }

  private def clone(a: MiniClazzActivity): MiniClazzActivity = {
    val n = new MiniClazzActivity
    n.miniClazz = a.miniClazz
    n.time = new WeekTime(a.time)
    n.places = a.places
    n.beginUnit = a.beginUnit
    n.endUnit = a.endUnit
    n.teacher = a.teacher
    n.coach1 = a.coach1
    n.coach2 = a.coach2
    n
  }

  private def isSameActivityExcept(target: MiniClazzActivity, other: MiniClazzActivity, room: Boolean): Boolean = {
    if (room) if (!(target.places == other.places)) return false
    target.time.mergeable(other.time, 31) //minutes
  }

  private def mergeTime(first: MiniClazzActivity, that: MiniClazzActivity): Unit = {
    if (first.time.beginAt >= that.time.beginAt) first.time.beginAt = that.time.beginAt
    if (first.time.endAt <= that.time.endAt) first.time.endAt = that.time.endAt
    first.beginUnit = math.min(first.beginUnit, that.beginUnit).toShort
    first.endUnit = math.max(first.endUnit, that.endUnit).toShort
    first.time.weekstate = new WeekState(first.time.weekstate.value | that.time.weekstate.value)
  }
}
