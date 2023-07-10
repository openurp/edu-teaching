[@b.card class="card-primary card-outline"]
  [@b.card_header]
    <h3 class="card-title"><i class="fa-regular fa-calendar-days"></i> 课程安排</h3>
  [/@]
  [@b.card_body style="padding: 0px 20px;"]
  <strong><i class="fas fa-calendar mr-1"></i> 时间</strong>
  <p class="text-muted" style="line-break: anywhere;">
  [#list clazz.schedule.activities as s]
    [#assign preYear="1"/]
    [#assign preYearMonth="1"/]
    [#list s.time.dates as date]
      [#if date?string("yy") != preYear]
        [#assign preYear=date?string("yy")/]
        [#assign preYearMonth=date?string("yy-M")/]
        ${date?string("E")}(${s.time.beginAt}~${s.time.endAt}) ${date?string("M-d")}[#t/]
      [#else]
        [#if date?string("yy-M") != preYearMonth]
          ;${date?string("M-d")}[#t/]
          [#assign preYearMonth=date?string("yy-M")/]
        [#else]
          &nbsp;${date?string("d")}[#t/]
        [/#if]
      [/#if]
    [/#list][#t/]
  [/#list]
  </p>
  <div id="calendarDiv"></div>
  <script>
  bg.load(["my97"],function(){
    WdatePicker({eCont:'calendarDiv',isShowWeek:true,firstDayOfWeek:${clazz.semester.calendar.firstWeekday.id}})
  })
  </script>

  <strong><i class="fas fa-map-marker-alt mr-1"></i> 地点</strong>
  <p class="text-muted">
    [#if setting.placePublished]
    [#assign rooms=[]/]
    [#list clazz.schedule.activities as s]
      [#list s.rooms as r]
        [#if !rooms?seq_contains(r)][#assign rooms=rooms+[r]/][/#if]
      [/#list]
    [/#list]
    [#list rooms as r]${(r.campus.name)!}&nbsp;${r.name}[#sep],[/#list]
    [#else]尚未发布
    [/#if]
  </p>
  [/@]
[/@]
