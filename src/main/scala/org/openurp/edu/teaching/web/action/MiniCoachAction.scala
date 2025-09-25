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

import org.beangle.commons.bean.orderings.CollatorOrdering
import org.beangle.commons.collection.Collections
import org.beangle.commons.lang.Strings
import org.beangle.commons.lang.time.WeekDay
import org.beangle.data.dao.OqlBuilder
import org.beangle.ems.app.Ems
import org.beangle.ems.app.web.WebBusinessLogger
import org.beangle.webmvc.context.ActionContext
import org.beangle.webmvc.support.helper.QueryHelper
import org.beangle.webmvc.view.View
import org.openurp.base.edu.model.{Course, CourseUnit}
import org.openurp.base.edu.service.TimeSettingService
import org.openurp.base.hr.model.Teacher
import org.openurp.base.model.{Project, Semester, User}
import org.openurp.base.std.model.Student
import org.openurp.edu.clazz.domain.{ClazzProvider, WeekTimeBuilder}
import org.openurp.edu.clazz.model.{MiniClazz, MiniClazzActivity}
import org.openurp.edu.teaching.web.helper.MiniClazzOccupyHelper
import org.openurp.starter.web.support.TeacherSupport

/** 小课艺术辅导安排
 */
class MiniCoachAction extends TeacherSupport {

  var businessLogger: WebBusinessLogger = _
  var timeSettingServie: TimeSettingService = _
  var clazzProvider: ClazzProvider = _

  override def projectIndex(teacher: Teacher)(using project: Project): View = {
    val semester = getSemester
    val teacher = getTeacher
    put("semester", semester)
    put("teacher", teacher)

    val me = getUser
    val q = OqlBuilder.from[MiniClazz](classOf[MiniClazzActivity].getName, "activity")
    q.where("activity.miniClazz.semester=:semester", semester)
    q.where("activity.coach1 = :me or activity.coach2 = :me", me)
    q.select("distinct activity.miniClazz")
    val clazzes = entityDao.search(q)

    val stds = clazzes.flatMap(_.stds)
    put("stds", stds.sortBy(x => x.grade.code + x.name))
    put("clazzes", clazzes.sortBy { x =>
      val std = x.stds.head;
      std.grade.code + std.name
    }(new CollatorOrdering(true)))

    val occupyHelper = new MiniClazzOccupyHelper(entityDao, null)
    put("occupyMap", occupyHelper.getCoachMiniOccupy(me, clazzes))
    put("maxWeekday", occupyHelper.maxWeekday)
    put("maxUnit", occupyHelper.maxUnit)

    val setting = timeSettingServie.get(project, semester, None)
    put("units", setting.units.sortBy(_.beginAt))
    put("EmsApi", Ems.api)
    put("me", me)
    forward()
  }

  def search(): View = {
    val semester = entityDao.get(classOf[Semester], getIntId("semester"))
    val q = OqlBuilder.from(classOf[MiniClazz], "miniClazz")
    q.where("miniClazz.semester=:semester", semester)
    q.where("miniClazz.coachHours < :maxCoachHour", 18 * 2)
    //q.where("exists(from miniClazz.activities as activity where activity.coach1 is not null or activity.coach2 is not null)")
    QueryHelper.populate(q)
    QueryHelper.sort(q)
    q.tailOrder("miniClazz.id")
    q.limit(QueryHelper.pageLimit)

    get("stdCodeName") foreach { name =>
      if (Strings.isNotBlank(name)) {
        q.where("exists(from miniClazz.stds as std where std.name like :name or std.code like :name)", s"%${name.trim}%")
      }
    }
    val clazzes = entityDao.search(q)

    put("semester", semester)
    put("clazzes", clazzes)
    forward()
  }

  /** 编辑指定节次的安排
   *
   * @return
   */
  def edit(): View = {
    val std = entityDao.get(classOf[Student], getLongId("std"))
    val course = entityDao.get(classOf[Course], getLongId("course"))
    val semester = entityDao.get(classOf[Semester], getIntId("semester"))
    var activity = new MiniClazzActivity

    val query = OqlBuilder.from(classOf[MiniClazz], "clazz")
    query.where("clazz.semester=:semester and clazz.course=:course", semester, course)
    query.where("exists(from clazz.stds std where std.id=:stdId)", std.id)
    val clazz = entityDao.search(query).head
    put("clazz", clazz)
    get("unit") foreach { u =>
      val activities = clazz.activities.filter(x => s"${x.time.weekday.id}_${x.beginUnit}_${x.endUnit}" == u)
      if (activities.nonEmpty) {
        activity = activities.head
      }
      put("unit", u)
    }

    put("std", std)
    put("semester", semester)
    put("course", course)
    val setting = timeSettingServie.get(std.project, semester, None)
    put("setting", setting)
    put("units", setting.units.sortBy(_.beginAt))

    val project = std.project
    val me = getUser
    val occupyHelper = new MiniClazzOccupyHelper(entityDao, clazzProvider)
    val miniOccupy = occupyHelper.getCoachMiniOccupy(project, semester, me)

    if (!activity.persisted || activity.coach1.isEmpty && activity.coach2.isEmpty) {
      activity.coach1 = Some(me)
    }
    put("teacherOccupyMap", miniOccupy)
    put("stdOccupyMap", occupyHelper.getStudentOccupy(std, semester))
    put("maxWeekday", occupyHelper.maxWeekday)
    put("maxUnit", occupyHelper.maxUnit)
    put("teacher", me)
    put("activity", activity)
    forward()
  }

  /** 删除艺术辅导安排
   *
   * @return
   */
  def remove(): View = {
    val me = getUser
    val clazz = entityDao.get(classOf[MiniClazz], getLongId("clazz"))
    val my = getMyCoachActivities(clazz, get("unit"), me)
    if (my.isEmpty) {
      val coachs = getCoachActivities(clazz, get("unit"), me)
      coachs foreach { a =>
        if (a.coach1.contains(me)) {
          a.coach1 = None
        }
        if (a.coach2.contains(me)) {
          a.coach2 = None
        }
      }
      entityDao.saveOrUpdate(clazz)
      businessLogger.info(s"删除了${clazz.crn}的艺术辅导老师", clazz.id, ActionContext.current.params)
    } else {
      clazz.activities.subtractAll(my)
      entityDao.saveOrUpdate(clazz)
      businessLogger.info(s"删除了${clazz.crn}的艺术辅导安排", clazz.id, ActionContext.current.params)
    }
    redirect("index", "删除成功")
  }

  private def getCoachActivities(clazz: MiniClazz, unit: Option[String], coach: User): Iterable[MiniClazzActivity] = {
    val hasMe = clazz.activities filter { a => a.coach1.contains(coach) || a.coach2.contains(coach) }
    unit match {
      case Some(u) => hasMe.filter(x => s"${x.time.weekday.id}_${x.beginUnit}_${x.endUnit}" == u)
      case None => hasMe
    }
  }

  /** 仅仅是艺术指导，且是本人的教学活动
   *
   * @param clazz
   * @param unit
   * @param coach
   * @return
   */
  private def getMyCoachActivities(clazz: MiniClazz, unit: Option[String], coach: User): Iterable[MiniClazzActivity] = {
    val hasMe = clazz.activities filter { a => a.coach1.contains(coach) || a.coach2.contains(coach) }
    val my = hasMe.filter(_.teacher.isEmpty)
    unit match {
      case Some(u) => my.filter(x => s"${x.time.weekday.id}_${x.beginUnit}_${x.endUnit}" == u)
      case None => my
    }
  }

  /** 保存了艺术辅导安排
   *
   * @return
   */
  def save(): View = {
    val me = getUser
    val std = entityDao.get(classOf[Student], getLongId("std"))
    val course = entityDao.get(classOf[Course], getLongId("course"))
    val semester = entityDao.get(classOf[Semester], getIntId("semester"))

    val coach1 = Some(me)
    val coach2 = getLong("coach2.id").map(id => entityDao.get(classOf[User], id))

    val query = OqlBuilder.from(classOf[MiniClazz], "clazz")
    query.where("clazz.semester=:semester and clazz.course=:course", semester, course)
    query.where("exists(from clazz.stds std where std.id=:stdId)", std.id)
    val clazz = entityDao.search(query).head

    getInt("weekday") match {
      case Some(weekday) =>
        val weekday = getInt("weekday", 1)
        val beginUnit = entityDao.get(classOf[CourseUnit], getInt("beginUnit", 0))
        val endUnit = entityDao.get(classOf[CourseUnit], getInt("endUnit", 0))
        val unit = get("unit", s"${weekday}_${beginUnit.indexno}_${endUnit.indexno}")
        val activities = clazz.activities.filter(x => s"${x.time.weekday.id}_${x.beginUnit}_${x.endUnit}" == unit)
        val itor = activities.iterator

        val places = get("places")
        val builder = WeekTimeBuilder.on(semester)
        val times = builder.build(WeekDay.of(weekday), 1 to 17)
        val newActivities = Collections.newBuffer[MiniClazzActivity]

        times.foreach { time =>
          time.beginAt = beginUnit.beginAt
          time.endAt = endUnit.endAt

          val activity =
            if itor.hasNext then
              itor.next()
            else
              val nact = new MiniClazzActivity()
              nact.miniClazz = clazz
              newActivities.addOne(nact)
              nact

          activity.time = time
          activity.teacher = None //不能设置老师，这是单独的艺术辅导
          activity.coach1 = coach1
          activity.coach2 = coach2
          activity.beginUnit = beginUnit.indexno.toShort
          activity.endUnit = endUnit.indexno.toShort
          activity.places = places
        }
        clazz.activities.addAll(newActivities)
        entityDao.saveOrUpdate(clazz)
        businessLogger.info(s"设置了${std.name}的艺术辅导安排", clazz.id, ActionContext.current.params)
      case None =>
        val unit = get("unit").get
        val activities = clazz.activities.filter(x => s"${x.time.weekday.id}_${x.beginUnit}_${x.endUnit}" == unit)
        activities foreach { activity =>
          activity.coach1 = coach1
          activity.coach2 = coach2
        }
        entityDao.saveOrUpdate(clazz)
        businessLogger.info(s"设置了${std.name}的艺术辅导老师", clazz.id, ActionContext.current.params)
    }

    redirect("index", "保存成功")
  }

}
