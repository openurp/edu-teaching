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

import org.openurp.base.edu.model.Teacher
import org.openurp.edu.exam.model.{ExamActivity, ExamRoom, PublishState}

enum Duty(val id: Int, val name: String) {
  case Teacher extends Duty(1, "任课教师")
  case ChiefInvigilator extends Duty(2, "主考")
  case OtherInvigilator extends Duty(3, "监考")
}

case class ExamDuty(teacher: Teacher, room: ExamRoom, duty: Duty) extends Ordered[ExamDuty] {

  def activities: collection.Seq[ExamActivity] = {
    val acts = room.activities filter { activity =>
      val onDuty = duty match
        case Duty.Teacher => activity.clazz.teachers.contains(teacher)
        case _ => true
      onDuty && activity.publishState != PublishState.None
    }
    acts.sortBy(_.clazz.crn)
  }

  override def compare(that: ExamDuty): Int = {
    val examAt = room.examOn.toString + room.beginAt.toString
    val thatExamAt = that.room.examOn.toString + that.room.beginAt.toString

    var rs = examAt.compareTo(thatExamAt)
    if (rs == 0) {
      val taskCrns = room.activities.map(_.clazz.crn).sorted.mkString(".")
      val thatTaskCrns = that.room.activities.map(_.clazz.crn).sorted.mkString(",")
      rs = taskCrns.compareTo(thatTaskCrns)
      if (rs == 0) {
        room.room.name.compareTo(that.room.room.name)
      } else rs
    } else rs
  }
}
