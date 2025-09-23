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
import org.beangle.webmvc.view.View
import org.openurp.base.edu.model.{Course, CourseUnit, Terms}
import org.openurp.base.edu.service.TimeSettingService
import org.openurp.base.hr.model.Teacher
import org.openurp.base.model.{Project, Semester, User}
import org.openurp.base.service.TermCalculator
import org.openurp.base.std.model.{Student, StudentTutor}
import org.openurp.edu.clazz.domain.{ClazzProvider, WeekTimeBuilder}
import org.openurp.edu.clazz.model.{MiniClazz, MiniClazzActivity}
import org.openurp.edu.teaching.web.helper.{OccupyHelper, StudentStateHelper}
import org.openurp.starter.web.support.TeacherSupport

import java.time.LocalDate

/**
 * 导师指导学生安排主课安排
 */
class MiniAction extends TeacherSupport {
  var businessLogger: WebBusinessLogger = _
  var timeSettingServie: TimeSettingService = _
  var clazzProvider: ClazzProvider = _

  override def projectIndex(teacher: Teacher)(using project: Project): View = {
    val semester = getSemester
    val teacher = getTeacher
    put("semester", semester)
    put("teacher", teacher)

    val group = this.getGuidanceGroup(project)
    put("group", group)
    var clazzMap: Map[Course, Map[Student, MiniClazz]] = Map.empty
    val stds = getStds(teacher, semester)
    val activeStds = Collections.newSet[Student]
    //std.id_group.name -> term
    val groupTerms = Collections.newMap[String, Int]
    val termCalculator = new TermCalculator(project, semester, entityDao)
    for (std <- stds) {
      val term = calcTerm(std, semester)
      if (group.contains(term)) {
        groupTerms.put(s"${std.id}_${group.name}", term)
        activeStds.add(std)
      }
    }
    put("stds", activeStds.toSeq.sortBy(x => x.grade.code + x.name)(new CollatorOrdering(true)))
    put("stdGroupTerms", groupTerms)

    if (stds.nonEmpty) {
      val query = OqlBuilder.from(classOf[MiniClazz], "clazz")
      query.where("clazz.semester=:semester", semester)
      query.where("clazz.teacher=:me", teacher)
      val clazzes = entityDao.search(query)
      clazzMap = clazzes.groupBy(_.course).map {
        case (c, gs) => (c, gs.flatMap(clz => clz.stds.map((_, clz))).groupBy(_._1).map(x => (x._1, x._2.head._2)))
      }
    }

    val occupyHelper = new OccupyHelper(entityDao, clazzProvider)
    put("miniOccupyMap", occupyHelper.getTeacherMiniOccupy(project, semester, teacher))
    put("occupyMap", occupyHelper.getTeacherCourseOccupy(project, semester, teacher))
    put("maxWeekday", occupyHelper.maxWeekday)
    put("maxUnit", occupyHelper.maxUnit)
    put("clazzMap", clazzMap)
    put("EmsApi", Ems.api)
    val setting = timeSettingServie.get(project, semester, None)
    put("units", setting.units.sortBy(_.beginAt))
    put("studentStateHelper", new StudentStateHelper())
    forward()
  }

  /** 修改课程安排
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
    val clazz = entityDao.search(query).headOption
    put("clazz", clazz)
    clazz foreach { clz =>
      get("unit") foreach { u =>
        val activities = clz.activities.filter(x => s"${x.time.weekday.id}_${x.beginUnit}_${x.endUnit}" == u)
        if (activities.nonEmpty) {
          activity = activities.head
        }
        put("unit", u)
      }
    }

    put("std", std)
    put("semester", semester)
    put("course", course)
    val setting = timeSettingServie.get(std.project, semester, None)
    put("setting", setting)
    put("units", setting.units.sortBy(_.beginAt))

    val project = std.project
    val teacher = getTeacher
    val occupyHelper = new OccupyHelper(entityDao, clazzProvider)
    val courseOccupy = occupyHelper.getTeacherCourseOccupy(project, semester, teacher)
    val miniOccupy = occupyHelper.getTeacherMiniOccupy(project, semester, teacher)

    put("teacherOccupyMap", occupyHelper.merge(courseOccupy, miniOccupy))
    put("stdOccupyMap", occupyHelper.getStudentOccupy(std, semester))
    put("maxWeekday", occupyHelper.maxWeekday)
    put("maxUnit", occupyHelper.maxUnit)
    put("teacher", teacher)
    put("activity", activity)
    forward()
  }

  def remove(): View = {
    val me = getTeacher
    val clazz = entityDao.get(classOf[MiniClazz], getLongId("clazz"))
    if (clazz.teacher.contains(me)) {
      get("unit") match {
        case None => entityDao.remove(clazz)
        case Some(unit) =>
          clazz.activities.subtractAll(clazz.activities.filter(x => s"${x.time.weekday.id}_${x.beginUnit}_${x.endUnit}" == unit))
          clazz.calcHours()
          entityDao.saveOrUpdate(clazz)
      }
      businessLogger.info(s"删除了${clazz.crn}的主课安排", clazz.id, ActionContext.current.params)
    }
    redirect("index", "删除成功")
  }

  def save(): View = {
    val me = getTeacher
    val std = entityDao.get(classOf[Student], getLongId("std"))
    val course = entityDao.get(classOf[Course], getLongId("course"))
    val semester = entityDao.get(classOf[Semester], getIntId("semester"))

    val advisor1 = getLong("advisor1.id").map(id => entityDao.get(classOf[User], id))
    val advisor2 = getLong("advisor2.id").map(id => entityDao.get(classOf[User], id))

    val query = OqlBuilder.from(classOf[MiniClazz], "clazz")
    query.where("clazz.semester=:semester and clazz.course=:course", semester, course)
    query.where("exists(from clazz.stds std where std.id=:stdId)", std.id)
    val clazz = entityDao.search(query).headOption match {
      case None =>
        val newClzz = new MiniClazz(std.code, std.project, semester, course)
        newClzz.stds.addOne(std)
        newClzz.teachDepart = std.department
        newClzz.teacher = Some(me)
        newClzz

      case Some(clz) => clz
    }

    val weekday = getInt("weekday", 1)
    val beginUnit = entityDao.get(classOf[CourseUnit], getInt("beginUnit", 0))
    val endUnit = entityDao.get(classOf[CourseUnit], getInt("endUnit", 0))
    val unit = get("unit", s"${weekday}_${beginUnit.indexno}_${endUnit.indexno}")
    val activities = clazz.activities.filter(x => s"${x.time.weekday.id}_${x.beginUnit}_${x.endUnit}" == unit)
    val itor = activities.iterator

    val places = get("places")
    val builder = WeekTimeBuilder.on(semester)
    val times = builder.build(WeekDay.of(weekday), 1 to 18)
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
      activity.teacher = Some(me)
      activity.advisor1 = advisor1
      activity.advisor2 = advisor2
      activity.beginUnit = beginUnit.indexno.toShort
      activity.endUnit = endUnit.indexno.toShort
      activity.places = places
    }
    while (itor.hasNext) {
      clazz.activities.subtractOne(itor.next())
    }
    clazz.activities.addAll(newActivities)
    clazz.calcHours()
    entityDao.saveOrUpdate(clazz)

    businessLogger.info(s"设置了${std.name}的主课安排", clazz.id, ActionContext.current.params)
    redirect("index", "保存成功")
  }

  /** 计算给定学期是学生的第几个学期
   *
   * @param std
   * @param semester
   * @return
   */
  private def calcTerm(std: Student, semester: Semester): Int = {
    val project = std.project
    if (!isStuding(std, semester.beginOn.plusDays(20), semester.endOn.minusDays(20))) return 0
    val sp = semesterService.get(project, std.beginOn, semester.endOn)
    val semesters = Collections.newBuffer[Semester]
    semesters ++= sp._1
    semesters ++= sp._2
    var notinschool = 0
    semesters foreach { s =>
      val beginOn = s.beginOn.plusDays(20)
      val endOn = s.endOn.minusDays(20)
      if (!isStuding(std, beginOn, endOn)) notinschool += 1
    }
    semesters.size - notinschool
  }

  private def isStuding(std: Student, beginOn: LocalDate, endOn: LocalDate): Boolean = {
    val states = std.states.filter(x => x.beginOn.isBefore(endOn) && beginOn.isBefore(x.endOn))
    states.exists(_.inschool)
    //    if states.exists(_.inschool) then true
    //    else
    //      states.exists(x => x.remark.getOrElse("").contains("交流") || x.remark.getOrElse("").contains("交换"))
  }

  private def getGuidanceGroup(project: Project): GuidanceCourseGroup = {
    var courseTerms = getConfig("edu.course.guidance_course_terms", "")(using project)
    if (Strings.isBlank(courseTerms)) {
      null.asInstanceOf[GuidanceCourseGroup]
    } else {
      courseTerms = Strings.substringBetween(courseTerms, "{", "}")
      val groups = Collections.newBuffer[GuidanceCourseGroup]
      Strings.split(courseTerms, ",") foreach { group =>
        var name = Strings.substringBefore(group, ":")
        name = Strings.replace(name, "'", "")
        name = Strings.replace(name, "\"", "")
        var termList = Strings.substringAfter(group, ":")
        termList = Strings.replace(termList, "'", "")
        termList = Strings.replace(termList, "\"", "")
        val course2Term = Collections.newMap[Course, Terms]
        Strings.split(termList, ";") foreach { courseTerm =>
          val data = Strings.split(courseTerm, "=")
          val course = entityDao.get(classOf[Course], data(0).toLong)
          val term = Terms(data(1))
          course2Term.put(course, term)
        }
        //目前只考虑主课
        if (name.contains("主课")) {
          groups.addOne(new GuidanceCourseGroup(name, course2Term.toMap))
        }
      }
      groups.head
    }
  }

  /** 按照导师或指导老师查找学生
   *
   * @param teacher
   * @param semester
   * @return
   */
  private def getStds(teacher: Teacher, semester: Semester): Seq[Student] = {
    val stdQuery = OqlBuilder.from[Student](classOf[StudentTutor].getName, "st").where("st.tutor=:me", teacher)
    stdQuery.where("st.std.beginOn < :endOn and :beginOn < st.std.endOn", semester.endOn, semester.beginOn)
    stdQuery.orderBy("st.std.state.grade.code,st.std.code")
    stdQuery.select("st.std")
    entityDao.search(stdQuery)
  }

}
