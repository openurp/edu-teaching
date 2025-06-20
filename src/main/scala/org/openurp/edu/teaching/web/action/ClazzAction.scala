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

import jakarta.servlet.http.Part
import org.beangle.commons.codec.digest.Digests
import org.beangle.commons.collection.Collections
import org.beangle.commons.lang.time.HourMinute
import org.beangle.commons.lang.{ClassLoaders, Strings}
import org.beangle.data.dao.{EntityDao, OqlBuilder}
import org.beangle.doc.transfer.Format
import org.beangle.doc.transfer.exporter.{ExcelTemplateExporter, ExportContext}
import org.beangle.ems.app.{Ems, EmsApp}
import org.beangle.security.Securities
import org.beangle.web.servlet.util.RequestUtils
import org.beangle.webmvc.context.{ActionContext, Params}
import org.beangle.webmvc.support.ActionSupport
import org.beangle.webmvc.support.helper.PopulateHelper
import org.beangle.webmvc.view.{Status, View}
import org.openurp.base.hr.model.Teacher
import org.openurp.base.model.User
import org.openurp.base.service.{Features, ProjectConfigService}
import org.openurp.base.std.model.Student
import org.openurp.edu.attendance.model.StdLeaveLesson
import org.openurp.edu.clazz.config.ScheduleSetting
import org.openurp.edu.clazz.domain.ClazzProvider
import org.openurp.edu.clazz.model.*
import org.openurp.edu.clazz.service.ClazzDocService
import org.openurp.edu.course.model.{ClazzPlan, Lesson, SyllabusDoc}
import org.openurp.edu.exam.model.ExamActivity
import org.openurp.edu.schedule.service.ScheduleDigestor
import org.openurp.starter.web.helper.ProjectProfile

import java.io.InputStream
import java.time.{Instant, LocalDate}
import scala.collection.mutable

class ClazzAction extends ActionSupport {

  var entityDao: EntityDao = _

  var clazzProvider: ClazzProvider = _

  var configService: ProjectConfigService = _

  var clazzDocService: ClazzDocService = _

  def index(): View = {
    val teacher = entityDao.findBy(classOf[Teacher], "staff.code" -> Securities.user).head
    val clazz = getClazz(teacher)

    val setting = getScheduleSetting(clazz)
    put("setting", setting)
    val avatarUrls = clazz.teachers.map(x => (x.id, Ems.api + "/platform/user/avatars/" + Digests.md5Hex(x.code) + ".jpg")).toMap
    put("avatarUrls", avatarUrls)
    put("clazzes", clazzProvider.getClazzes(clazz.semester, teacher, clazz.project))
    put("tutorSupported", configService.get[Boolean](clazz.project, Features.Std.TutorSupported))

    val q1 = OqlBuilder.from(classOf[StdLeaveLesson], "sll")
    q1.where("sll.clazz=:clazz", clazz)
    q1.orderBy("sll.std.code,sll.lessonOn")
    val stdLeaveLessons = entityDao.search(q1)

    val stdLeaveStats = stdLeaveLessons.groupBy(x => x.std).map(x => new StdLeaveStat(x._1, x._2))
    put("stdLeaveStats", stdLeaveStats.toBuffer.sortBy(_.std.code))
    forward()
  }

  private def getClazz(teacher: Teacher): Clazz = {
    val clazz = entityDao.get(classOf[Clazz], getLongId("clazz"))
    if (null != clazz && clazz.teachers.contains(teacher)) {
      put("clazz", clazz)
      clazz
    } else {
      null
    }
  }

  def notices(): View = {
    val clazzId = getLong("clazz.id").getOrElse(0L)
    val query = OqlBuilder.from(classOf[ClazzNotice], "notice")
    query.where("notice.clazz.id=:clazzId", clazzId)
    put("notices", entityDao.search(query))
    put("clazzId", clazzId)
    forward()
  }

  def saveNotice(): View = {
    val notice = getLong("notice.id") match {
      case None => PopulateHelper.populate(classOf[ClazzNotice], "notice")
      case Some(id) =>
        val notice = entityDao.get(classOf[ClazzNotice], id)
        PopulateHelper.populate(notice, Params.sub("notice"))
    }

    notice.updatedAt = Instant.now
    val clazz = entityDao.get(classOf[Clazz], getLong("notice.clazz.id").getOrElse(0L))
    if (validOwnership(clazz)) {
      notice.clazz = clazz
      notice.updatedBy = entityDao.findBy(classOf[User], "code", List(Securities.user)).head
      entityDao.saveOrUpdate(notice)

      //保存附件
      val parts = getAll("attachment", classOf[Part])
      parts foreach { part =>
        if (part.getSize > 0) {
          clazzDocService.createNoticeFile(notice, part.getInputStream, part.getSubmittedFileName)
        }
      }
    }
    redirect("notices", "clazz.id=" + notice.clazz.id, "info.save.success")
  }

  def removeNotice(): View = {
    var clazzId = 0L
    getLong("notice.id") foreach { noticeId =>
      val notice = entityDao.get(classOf[ClazzNotice], noticeId)
      if (notice.clazz.teachers.exists(x => x.code == Securities.user)) {
        clazzId = notice.clazz.id
        notice.files foreach { f =>
          EmsApp.getBlobRepository(true).remove(f.filePath)
        }
        entityDao.remove(notice)
      }
    }
    redirect("notices", "clazz.id=" + clazzId, "info.remove.success")
  }

  def docs(): View = {
    val clazzId = getLong("clazz.id").getOrElse(0L)
    val query = OqlBuilder.from(classOf[ClazzDoc], "doc")
    query.where("doc.clazz.id=:clazzId", clazzId)
    put("docs", entityDao.search(query))
    put("clazzId", clazzId)
    forward()
  }

  def saveDoc(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLong("doc.clazz.id").getOrElse(0L))
    if (validOwnership(clazz)) {
      val parts = getAll("attachment", classOf[Part])
      var in: Option[InputStream] = None
      var fileName: Option[String] = None
      if (parts.nonEmpty && parts.head.getSize > 0) {
        val part = parts.head
        in = Some(part.getInputStream)
        fileName = Some(part.getSubmittedFileName)
      }
      clazzDocService.createDoc(clazz, get("doc.name").get, get("doc.url"), in, fileName)
    }
    redirect("docs", "clazz.id=" + clazz.id, "info.save.success")
  }

  def removeDoc(): View = {
    var clazzId = 0L
    getLong("doc.id") foreach { docId =>
      val doc = entityDao.get(classOf[ClazzDoc], docId)
      if (doc.clazz.teachers.exists(x => x.code == Securities.user)) {
        doc.filePath foreach { p =>
          EmsApp.getBlobRepository(true).remove(p)
        }
        clazzId = doc.clazz.id
        entityDao.remove(doc)
      }
    }
    redirect("docs", "clazz.id=" + clazzId, "info.remove.success")
  }

  /**
   * 下载公告附件或者课程资料
   *
   * @return
   */
  def download(): View = {
    val noticeFileId = getLong("noticeFile.id").getOrElse(0L)
    val docId = getLong("doc.id").getOrElse(0L)
    val bulletinId = getLong("bulletin.id").getOrElse(0L)
    if (noticeFileId > 0) {
      val noticeFile = entityDao.get(classOf[ClazzNoticeFile], noticeFileId)
      val path = EmsApp.getBlobRepository(true).url(noticeFile.filePath)
      redirect(to(path.get.toString), "x")
    } else if (docId > 0) {
      val doc = entityDao.get(classOf[ClazzDoc], docId)
      doc.filePath match {
        case None => Status.NotFound
        case Some(p) =>
          val path = EmsApp.getBlobRepository(true).url(p)
          redirect(to(path.get.toString), "x")
      }
    } else {
      val bulletin = entityDao.get(classOf[ClazzBulletin], bulletinId)
      bulletin.contactQrcodePath match {
        case None => Status.NotFound
        case Some(p) =>
          val path = EmsApp.getBlobRepository(true).url(p)
          redirect(to(path.get.toString), "x")
      }
    }
  }

  def rollbook(): View = {
    val teacher = entityDao.findBy(classOf[Teacher], "staff.code" -> Securities.user).head
    val clazz = getClazz(teacher)
    val toSheet = getBoolean("excel", false)
    if (toSheet) {
      val context = new ExportContext(Format.Xlsx)
      val response = ActionContext.current.response
      context.exporter = new ExcelTemplateExporter()
      context.template = ClassLoaders.getResource("org/openurp/edu/teaching/components/rollbook.xlsx").get
      RequestUtils.setContentDisposition(response, clazz.crn + "点名册.xlsx")

      val stds = clazz.enrollment.courseTakers.map(_.std).sortBy(_.code)

      val directions = new java.util.HashMap[Student, String]
      val tutors = new java.util.HashMap[Student, String]
      stds.foreach { std =>
        std.state.get.direction foreach { d =>
          directions.put(std, d.name)
        }
      }
      stds.foreach { std =>
        std.tutor.foreach { t =>
          tutors.put(std, t.name)
        }
      }
      val course = clazz.course
      val usedCredits = new mutable.HashSet[Float]
      val cls = course.levels.filter(_.credits.nonEmpty)
      var creditText =
        cls.map { cl =>
          usedCredits += cl.credits.get
          cl.level.name + cl.credits.get + "分"
        }.mkString(",")
      if (!usedCredits.contains(course.defaultCredits)) {
        creditText = course.defaultCredits.toString + " " + creditText
      }
      creditText = Strings.replace(creditText, ".0", "")

      context.put("teacherName", clazz.teachers.map(_.name).mkString(","))
      context.put("clazz", clazz)
      context.put("stds", stds)
      context.put("creditText", creditText)
      context.put("directions", directions)
      context.put("tutors", tutors)
      context.writeTo(response.getOutputStream)
      Status.Ok
    } else {
      put("schedule", ScheduleDigestor.digest(clazz, ":day :units :weeks :room"))
      ProjectProfile.set(clazz.project)
      forward()
    }
  }

  def bulletin(): View = {
    put("bulletin", getBulletin())
    forward()
  }

  def editBulletin(): View = {
    val bulletin = getBulletin().getOrElse(new ClazzBulletin)
    put("bulletin", bulletin)
    forward()
  }

  private def validOwnership(clazz: Clazz): Boolean = {
    clazz.teachers.map(_.code).contains(Securities.user)
  }

  def saveBulletin(): View = {
    val bulletin = getBulletin().getOrElse(new ClazzBulletin)
    val clazz: Clazz = ActionContext.current.attribute("clazz")
    if (null != clazz && validOwnership(clazz)) {
      bulletin.clazz = clazz
      bulletin.contents = get("bulletin.contents")
      bulletin.contactQrcodePath = get("bulletin.contactQrcodePath")
      entityDao.saveOrUpdate(bulletin)

      val parts = getAll("attachment", classOf[Part])
      if (parts.nonEmpty && parts.head.getSize > 0) {
        val part = parts.head
        clazzDocService.createBulletinFile(bulletin, part.getInputStream, part.getSubmittedFileName)
      }
    }
    redirect("bulletin", s"clazz.id=${bulletin.clazz.id}", "info.save.success")
  }

  def removeBulletin(): View = {
    val bulletin = getBulletin().getOrElse(new ClazzBulletin)
    if (bulletin.persisted) {
      bulletin.contactQrcodePath foreach { p =>
        EmsApp.getBlobRepository(true).remove(p)
      }
      if (validOwnership(bulletin.clazz)) {
        entityDao.remove(bulletin)
      }
    }
    redirect("bulletin", s"clazz.id=${bulletin.clazz.id}", "info.remove.success")
  }

  def teachingPlan(): View = {
    put("plan", getTeachingPlan())
    forward()
  }

  def editTeachingPlan(): View = {
    val clazz: Clazz = ActionContext.current.attribute("clazz")
    val tp = getTeachingPlan().getOrElse(new ClazzPlan)
    if (!tp.persisted) {
      tp.clazz = clazz
      tp.semester = clazz.semester
      tp.updatedAt = Instant.now
      var times = Collections.newBuffer[LessonTime]
      clazz.schedule.activities foreach { s =>
        s.time.dates foreach { d => times.addOne(new LessonTime(d, s)) }
      }
      val grouped = times.groupBy(_.openOn)
      val mergedTimes = Collections.newBuffer[LessonTime]
      grouped foreach { case (d, tl) =>
        val head = tl.head
        tl.tail foreach { t => head.merge(t) }
        mergedTimes.addOne(head)
      }
      var i = 1
      times = mergedTimes.sorted
      times foreach { time =>
        val lesson = new Lesson()
        lesson.plan = tp
        lesson.idx = i
        i += 1
        lesson.contents = " "
        tp.lessons += lesson
      }
      if (times.nonEmpty) {
        entityDao.saveOrUpdate(tp)
      }
    }
    put("plan", tp)
    forward()
  }

  class LessonTime extends Ordered[LessonTime] {
    var openOn: LocalDate = _
    var beginAt: HourMinute = _
    var endAt: HourMinute = _
    var places: Option[String] = None
    var units = new mutable.HashSet[Int]

    override def compare(that: LessonTime): Int = {
      (this.openOn.toString + this.beginAt.toString).compareTo(that.openOn.toString + that.beginAt.toString)
    }

    def this(d: LocalDate, ca: ClazzActivity) = {
      this()
      this.openOn = d
      this.beginAt = ca.time.beginAt
      this.endAt = ca.time.endAt
      this.places = Some(ca.rooms.map(_.name).mkString(" "));
      (ca.beginUnit.toInt to ca.endUnit.toInt) foreach (units.addOne)
    }

    def merge(that: LessonTime): Unit = {
      if this.beginAt > that.beginAt then this.beginAt = that.beginAt
      if this.endAt < that.endAt then this.endAt = that.endAt
      this.units ++= that.units
    }
  }

  def saveTeachingPlan(): View = {
    val plan = getTeachingPlan().get
    if (validOwnership(plan.clazz)) {
      plan.lessons foreach { lesson =>
        var contents = get(s"lesson${lesson.id}.contents", "")
        if Strings.isEmpty(contents) then contents = " "
        lesson.contents = contents
        lesson.remark = get(s"lesson${lesson.id}.remark")
      }
      entityDao.saveOrUpdate(plan)
    }
    redirect("teachingPlan", s"clazz.id=${plan.clazz.id}", "info.save.success")
  }

  def removeTeachingPlan(): View = {
    val plan = getTeachingPlan()
    val clazz: Clazz = ActionContext.current.attribute("clazz")
    if (null != clazz && validOwnership(clazz)) {
      plan foreach { p =>
        entityDao.remove(p)
      }
    }
    redirect("teachingPlan", s"clazz.id=${clazz.id}", "info.remove.success")
  }

  def info(): View = {
    val teacher = entityDao.findBy(classOf[Teacher], "staff.code" -> Securities.user).head
    val clazz = getClazz(teacher)
    put("clazz", clazz)

    val setting = getScheduleSetting(clazz)
    if (setting.timePublished) {
      put("schedule", ScheduleDigestor.digest(clazz, ":day :units :weeks"))
    }
    if (setting.placePublished) {
      put("rooms", clazz.schedule.activities.flatMap(_.rooms).map(_.name).mkString(" "))
    }
    val syllabusDocs = entityDao.findBy(classOf[SyllabusDoc], "course", clazz.course).filter(_.within(clazz.semester.beginOn))
    put("syllabusDocs", syllabusDocs)

    val examActivities = entityDao.findBy(classOf[ExamActivity], "clazz", clazz)
    put("examActivities", examActivities)
    forward()
  }

  private def getTeachingPlan(): Option[ClazzPlan] = {
    val teacher = entityDao.findBy(classOf[Teacher], "staff.code" -> Securities.user).head
    val clazz = getClazz(teacher)
    put("clazz", clazz)
    put("teacher", teacher)
    val query = OqlBuilder.from(classOf[ClazzPlan], "plan")
    query.where("plan.clazz=:clazz", clazz)
    entityDao.search(query).headOption
  }

  private def getBulletin(): Option[ClazzBulletin] = {
    val teacher = entityDao.findBy(classOf[Teacher], "staff.code" -> Securities.user).head
    val clazz = getClazz(teacher)
    put("clazz", clazz)
    put("teacher", teacher)
    val query = OqlBuilder.from(classOf[ClazzBulletin], "bulletin")
    query.where("bulletin.clazz=:clazz", clazz)
    entityDao.search(query).headOption
  }

  private def getScheduleSetting(clazz: Clazz): ScheduleSetting = {
    val query = OqlBuilder.from(classOf[ScheduleSetting], "setting")
    query.where("setting.project =:project", clazz.project)
    query.where("setting.semester =:semester", clazz.semester)
    query.cacheable()
    entityDao.search(query).headOption.getOrElse(new ScheduleSetting)
  }
}

class StdLeaveStat(val std: Student, val leaves: collection.Seq[StdLeaveLesson])
