package org.openurp.edu.teaching.web.helper

import org.beangle.commons.lang.time.WeekTime

class Activity {
  var id: Option[Long] = None
  var time: WeekTime = _
  var places: String = _
  var activity: String = _
  var users: Option[String] = None
  var comments: Option[String] = None
}
