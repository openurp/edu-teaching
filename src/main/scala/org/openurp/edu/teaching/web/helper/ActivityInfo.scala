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

import org.beangle.commons.lang.time.WeekTime

/** 活动信息
 */
class ActivityInfo {
  /** 主题 */
  var subject: String = _
  /** 时间 */
  var time: WeekTime = _
  /** 地点 */
  var places: Option[String] = None
  /** 人员 */
  var users: Option[String] = None
  /** 备注 */
  var comments: Option[String] = None
  /** data business key */
  var owner: Option[String] = None
  /** 活动类型 */
  var activityType: String = _
}
