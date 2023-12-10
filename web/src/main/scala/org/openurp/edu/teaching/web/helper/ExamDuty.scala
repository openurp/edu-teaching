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
    room.activities filter { activity =>
      val onDuty = duty match
        case Duty.Teacher => activity.clazz.teachers.contains(teacher)
        case _ => true
      onDuty && activity.publishState != PublishState.None
    }
  }

  override def compare(that: ExamDuty): Int = {
    val examAt = room.examOn.toString + room.beginAt.toString
    val thatExamAt = that.room.examOn.toString + that.room.beginAt.toString

    var rs = examAt.compareTo(thatExamAt)
    if (rs == 0) {
      val taskCrns = room.activities.map(_.clazz.crn).mkString(",")
      val thatTaskCrns = that.room.activities.map(_.clazz.crn).mkString(",")
      rs = taskCrns.compareTo(thatTaskCrns)
      if (rs == 0) {
        room.room.name.compareTo(that.room.room.name)
      } else rs
    } else rs
  }
}
