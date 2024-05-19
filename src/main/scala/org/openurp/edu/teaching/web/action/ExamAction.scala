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
import org.beangle.web.action.view.View
import org.openurp.base.hr.model.Teacher
import org.openurp.base.model.{Project, Semester}
import org.openurp.code.edu.model.{ExamStatus, ExamType}
import org.openurp.edu.exam.model.*
import org.openurp.edu.teaching.web.helper.{Duty, ExamDuty}
import org.openurp.starter.web.support.TeacherSupport

import scala.collection.mutable

/** 教师查看排考结果
 */
class ExamAction extends TeacherSupport {

  protected override def projectIndex(teacher: Teacher)(using project: Project): View = {
    val semester = getSemester
    put("teacher", teacher)
    put("semester", semester)

    val finalType = entityDao.get(classOf[ExamType], ExamType.Final)
    val makeupDelayType = entityDao.get(classOf[ExamType], ExamType.MakeupDelay)

    val examTypes = List(finalType, makeupDelayType)
    val dutyMap = Collections.newMap[ExamType, mutable.Map[ExamRoom, ExamDuty]]
    val noticeMap = Collections.newMap[ExamType, ExamNotice]
    examTypes foreach { examType =>
      val duties = dutyMap.getOrElseUpdate(examType, new mutable.HashMap[ExamRoom, ExamDuty])
      //列举每一个发布的考试活动
      val activities = getActivityByCourse(teacher, project, semester, examType)
      activities foreach { activity =>
        if (activity.publishState != PublishState.None) {
          activity.rooms foreach { examRoom =>
            val duty =
              examRoom.invigilations.find(_.invigilator.map(_.code).contains(teacher.code)) match
                case None => ExamDuty(teacher, examRoom, Duty.Teacher)
                case Some(i) => ExamDuty(teacher, examRoom, if i.chief then Duty.ChiefInvigilator else Duty.OtherInvigilator)
            duties.put(examRoom, duty)
          }
        }
      }

      //列举每一个参与监考的考场
      val examRooms = getExamRoomByInvigilator(teacher, project, semester, examType)
      examRooms foreach { examRoom =>
        if (examRoom.activities.exists(_.publishState != PublishState.None)) {
          if !duties.contains(examRoom) then
            val duty =
              examRoom.invigilations.find(_.invigilator.map(_.code).contains(teacher.code)) match
                case None => ExamDuty(teacher, examRoom, Duty.Teacher)
                case Some(i) => ExamDuty(teacher, examRoom, if i.chief then Duty.ChiefInvigilator else Duty.OtherInvigilator)
            duties.put(examRoom, duty)
        }
      }

      //查询考试须知
      val noticeQuery = OqlBuilder.from(classOf[ExamNotice], "notice")
      noticeQuery.where("notice.project=:project", project)
      noticeQuery.where("notice.semester=:semester", semester)
      noticeQuery.where("notice.examType=:examType", examType)
      entityDao.search(noticeQuery) foreach { notice =>
        noticeMap.put(examType, notice)
      }
    }

    val examDutyMap = dutyMap.filter(_._2.nonEmpty).map { case (examType, duties) =>
      (examType, duties.values.toBuffer.sorted)
    }

    put("examDutyMap", examDutyMap)
    put("noticeMap", noticeMap)
    forward()
  }

  private def getActivityByCourse(teacher: Teacher, project: Project, semester: Semester, examType: ExamType): Seq[ExamActivity] = {
    val query = OqlBuilder.from(classOf[ExamActivity], "activity")
    query.where("activity.publishState != :publishState", PublishState.None)
    query.where("activity.semester =:semester", semester)
    query.where("activity.examType =:examType", examType)
    query.where("activity.clazz.project =:project", project)
    query.where("exists(from activity.clazz.teachers teacher where teacher =:teacher)", teacher)
    entityDao.search(query)
  }

  private def getExamRoomByInvigilator(teacher: Teacher, project: Project, semester: Semester, examType: ExamType): Seq[ExamRoom] = {
    val query = OqlBuilder.from(classOf[ExamRoom], "examRoom")
    query.where("examRoom.semester =:semester", semester)
    query.where("examRoom.examType =:examType", examType)
    query.where("exists(from examRoom.activities activity where activity.clazz.project =:project)", project)
    query.where("exists (from examRoom.invigilations invigilation where invigilation.invigilator.code =:invigilator)", teacher.code)

    entityDao.search(query)
  }

  /** 打印签名表
   *
   * @return
   */
  def signature(): View = {
    val examRooms = entityDao.find(classOf[ExamRoom], getLongIds("examRoom"))
    put("examRooms", examRooms)
    put("examType", examRooms.head.examType)
    put("courseExamTakers", examRooms.map(x => (x, x.examTakers.groupBy(_.clazz.course))).toMap)
    forward()
  }

  /** 试卷贴
   *
   * @return
   */
  def label(): View = {
    val examRooms = entityDao.find(classOf[ExamRoom], getLongIds("examRoom"))
    put("examRooms", examRooms)
    put("examType", examRooms.head.examType)
    put("semester", examRooms.head.semester)
    put("courseExamTakers", examRooms.map(x => (x, x.examTakers.groupBy(_.clazz.course))).toMap)
    forward()
  }

  /** 考场情况表
   *
   * @return
   */
  def summary(): View = {
    val examRooms = entityDao.find(classOf[ExamRoom], getLongIds("examRoom"))
    put("examRooms", examRooms)
    put("Normal", ExamStatus.Normal)
    put("Absent", ExamStatus.Absent)
    put("courseExamTakers", examRooms.map(x => (x, x.examTakers.groupBy(_.clazz.course))).toMap)
    forward()
  }

}
