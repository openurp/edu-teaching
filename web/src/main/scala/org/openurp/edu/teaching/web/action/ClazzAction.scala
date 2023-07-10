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
import org.beangle.data.transfer.Format
import org.beangle.data.transfer.excel.{ExcelTemplateExporter, ExcelTemplateWriter}
import org.beangle.data.transfer.exporter.ExportContext
import org.beangle.ems.app.{Ems, EmsApp}
import org.beangle.security.Securities
import org.beangle.template.freemarker.ProfileTemplateLoader
import org.beangle.web.action.context.{ActionContext, Params}
import org.beangle.web.action.support.ActionSupport
import org.beangle.web.action.view.{Status, View}
import org.beangle.web.servlet.util.RequestUtils
import org.beangle.webmvc.support.helper.PopulateHelper
import org.openurp.base.Features
import org.openurp.base.edu.model.{Course, Teacher}
import org.openurp.base.model.User
import org.openurp.base.service.ProjectPropertyService
import org.openurp.base.std.model.Student
import org.openurp.code.edu.model.{TeachingMethod, TeachingNature}
import org.openurp.edu.clazz.config.ScheduleSetting
import org.openurp.edu.clazz.domain.ClazzProvider
import org.openurp.edu.clazz.model.*
import org.openurp.edu.clazz.service.ClazzMaterialService

import java.io.InputStream
import java.time.{Instant, LocalDate}
import java.util
import java.util.Locale
import scala.collection.mutable

class ClazzAction extends ActionSupport {

  var entityDao: EntityDao = _

  var clazzProvider: ClazzProvider = _

  var projectPropertyService: ProjectPropertyService = _

  var clazzMaterialService: ClazzMaterialService = _

  def index(): View = {
    val teacher = entityDao.findBy(classOf[Teacher], "staff.code" -> Securities.user).head
    val clazz = getClazz(teacher)

    val query = OqlBuilder.from(classOf[ScheduleSetting], "setting")
    query.where("setting.project =:project", clazz.project)
    query.where("setting.semester =:semester", clazz.semester)
    query.cacheable()
    val setting = entityDao.search(query).headOption.getOrElse(new ScheduleSetting)
    put("setting", setting)
    val avatarUrls = clazz.teachers.map(x => (x.id, Ems.api + "/platform/user/avatars/" + Digests.md5Hex(x.code) + ".jpg")).toMap
    put("avatarUrls", avatarUrls)
    put("clazzes", clazzProvider.getClazzes(clazz.semester, teacher, clazz.project))
    put("tutorSupported", projectPropertyService.get(clazz.project, Features.StdInfoTutorSupported, false))
    forward()
  }

  private def getClazz(teacher: Teacher): Clazz = {
    val clazz = entityDao.get(classOf[Clazz], getLong("clazz.id").getOrElse(0))
    if (null != clazz && clazz.teachers.contains(teacher)) {
      put("clazz", clazz)
    }
    clazz
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
    notice.clazz = clazz
    notice.updatedBy = entityDao.findBy(classOf[User], "code", List(Securities.user)).head
    entityDao.saveOrUpdate(notice)

    //保存附件
    val parts = getAll("attachment", classOf[Part])
    parts foreach { part =>
      if (part.getSize > 0) {
        clazzMaterialService.createNoticeFile(notice, part.getInputStream, part.getSubmittedFileName)
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

  def materials(): View = {
    val clazzId = getLong("clazz.id").getOrElse(0L)
    val query = OqlBuilder.from(classOf[ClazzMaterial], "notice")
    query.where("notice.clazz.id=:clazzId", clazzId)
    put("materials", entityDao.search(query))
    put("clazzId", clazzId)
    forward()
  }

  def saveMaterial(): View = {
    val clazz = entityDao.get(classOf[Clazz], getLong("material.clazz.id").getOrElse(0L))
    val parts = getAll("attachment", classOf[Part])
    var in: Option[InputStream] = None
    var fileName: Option[String] = None
    if (parts.nonEmpty && parts.head.getSize > 0) {
      val part = parts.head
      in = Some(part.getInputStream)
      fileName = Some(part.getSubmittedFileName)
    }
    clazzMaterialService.createMaterial(clazz, get("material.name").get, get("material.url"), in, fileName)
    redirect("materials", "clazz.id=" + clazz.id, "info.save.success")
  }

  def removeMaterial(): View = {
    var clazzId = 0L
    getLong("material.id") foreach { materialId =>
      val material = entityDao.get(classOf[ClazzMaterial], materialId)
      if (material.clazz.teachers.exists(x => x.code == Securities.user)) {
        material.filePath foreach { p =>
          EmsApp.getBlobRepository(true).remove(p)
        }
        clazzId = material.clazz.id
        entityDao.remove(material)
      }
    }
    redirect("materials", "clazz.id=" + clazzId, "info.remove.success")
  }

  /**
   * 下载公告附件或者课程资料
   *
   * @return
   */
  def download(): View = {
    val noticeFileId = getLong("noticeFile.id").getOrElse(0L)
    val materialId = getLong("material.id").getOrElse(0L)
    val bulletinId = getLong("bulletin.id").getOrElse(0L)
    if (noticeFileId > 0) {
      val noticeFile = entityDao.get(classOf[ClazzNoticeFile], noticeFileId)
      val path = EmsApp.getBlobRepository(true).url(noticeFile.filePath)
      redirect(to(path.get.toString), "x")
    } else if (materialId > 0) {
      val material = entityDao.get(classOf[ClazzMaterial], materialId)
      material.filePath match {
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
      val context = new ExportContext
      val response = ActionContext.current.response
      context.format = Format.Xlsx
      context.exporter = new ExcelTemplateExporter()
      context.writer = new ExcelTemplateWriter(
        ClassLoaders.getResource("org/openurp/edu/teaching/components/rollbook.xlsx").get, context,
        response.getOutputStream)
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
      context.exporter.exportData(context, context.writer)
      Status.Ok
    } else{
      ProfileTemplateLoader.setProfile(clazz.project.id)
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

  def saveBulletin(): View = {
    val bulletin = getBulletin().getOrElse(new ClazzBulletin)
    val clazz: Clazz = ActionContext.current.attribute("clazz")
    bulletin.clazz = clazz
    bulletin.contents = get("bulletin.contents")
    bulletin.contactQrcodePath = get("bulletin.contactQrcodePath")
    entityDao.saveOrUpdate(bulletin)

    val parts = getAll("attachment", classOf[Part])
    if (parts.nonEmpty && parts.head.getSize > 0) {
      val part = parts.head
      clazzMaterialService.createBulletinFile(bulletin, part.getInputStream, part.getSubmittedFileName)
    }
    redirect("bulletin", s"clazz.id=${bulletin.clazz.id}", "info.save.success")
  }

  def removeBulletin(): View = {
    val bulletin = getBulletin().getOrElse(new ClazzBulletin)
    if (bulletin.persisted) {
      bulletin.contactQrcodePath foreach { p =>
        EmsApp.getBlobRepository(true).remove(p)
      }
      entityDao.remove(bulletin)
    }
    redirect("bulletin", s"clazz.id=${bulletin.clazz.id}", "info.remove.success")
  }

  def teachingPlan(): View = {
    put("plan", getTeachingPlan())
    forward()
  }

  def editTeachingPlan(): View = {
    val tp = getTeachingPlan().getOrElse(new TeachingPlan)
    val clazz: Clazz = ActionContext.current.attribute("clazz")
    if (!tp.persisted) {
      tp.clazz = clazz
      tp.docLocale = Locale.SIMPLIFIED_CHINESE
      tp.semester = clazz.semester
      tp.updatedAt = Instant.now
      val times = Collections.newSet[(LocalDate, HourMinute, HourMinute, Option[String])]
      clazz.schedule.activities foreach { s =>
        s.time.dates foreach { d =>
          times.addOne((d, s.time.beginAt, s.time.endAt, s.places))
        }
      }
      var i = 1
      times.toSeq.sortBy(x => x._1) foreach { time =>
        val lesson = new Lesson()
        lesson.openOn = time._1
        lesson.beginAt = time._2
        lesson.endAt = time._3
        lesson.places = time._4
        lesson.plan = tp
        lesson.units = "x"
        lesson.idx = i
        i += 1
        lesson.teachingNature = entityDao.get(classOf[TeachingNature], TeachingNature.Theory)
        lesson.teachingMethod = entityDao.get(classOf[TeachingMethod], TeachingMethod.Offline)
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

  def saveTeachingPlan(): View = {
    val plan = getTeachingPlan().get
    plan.lessons foreach { lesson =>
      var contents = get(s"lesson${lesson.id}.contents", "")
      if Strings.isEmpty(contents) then contents = " "
      lesson.contents = contents
      lesson.places = get(s"lesson${lesson.id}.places")
    }
    entityDao.saveOrUpdate(plan)
    redirect("teachingPlan", s"clazz.id=${plan.clazz.id}", "info.save.success")
  }

  def removeTeachingPlan(): View = {
    val plan = getTeachingPlan()
    val clazz: Clazz = ActionContext.current.attribute("clazz")
    plan foreach { p =>
      entityDao.remove(p)
    }
    redirect("teachingPlan", s"clazz.id=${clazz.id}", "info.remove.success")
  }

  private def getTeachingPlan(): Option[TeachingPlan] = {
    val teacher = entityDao.findBy(classOf[Teacher], "staff.code" -> Securities.user).head
    val clazz = getClazz(teacher)
    put("clazz", clazz)
    put("teacher", teacher)
    val query = OqlBuilder.from(classOf[TeachingPlan], "plan")
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
}
