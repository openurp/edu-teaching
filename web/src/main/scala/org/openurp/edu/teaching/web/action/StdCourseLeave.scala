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
import org.openurp.base.std.model.Student
import org.openurp.edu.attendance.model.DayoffType
import org.openurp.edu.clazz.model.Clazz

import java.time.Instant

class StdLeaveStat(val clazz: Clazz, val std: Student) {
  val leaves = Collections.newBuffer[StdCourseLeave]

  def addLeave(beginAt: Instant, dayoffType: DayoffType, reason: String, leaveId: Option[Long]): Unit = {
    val l = StdCourseLeave(beginAt, dayoffType, reason, None)
    leaves.addOne(l)
  }
}

case class StdCourseLeave(beginAt: Instant, dayoffType: DayoffType, reason: String, leaveId: Option[Long])
