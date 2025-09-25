[#ftl]
[#macro tableLegend]
  <p class="text-sm text-muted" style="margin:0px">说明:课表中显示"张某某 法律基础(0678)(5-17,2201)" 表示授课教师:张某某,课程名称:法律基础,课程序号:0678,上课起止周:第5周到第17周,上课教室:2201</p>
[/#macro]
[#macro getNames(beanList)][#list beanList as bean][#if bean_index>0],[/#if]${(bean.name)!}[/#list][/#macro]
[#assign weekNames = ['--','星期一','星期二','星期三','星期四','星期五','星期六','星期日'] /]
[#macro initCourseTable(table,tableIndex)]
  [#if table.style == "WEEK_TABLE"]
    <table width="100%" class="grid-table"  style="text-align:center">
      <thead class="grid-head">
        <tr>
          <th height="10px" width="110px">节次/星期</th>
          [#list table.weekdays as wd]
          <th style="font-weight:normal;"><font size="2px">${weekNames[wd.id]}</font></th>
          [/#list]
        </tr>
      </thead>
      [#list table.timeSetting.units?sort_by("indexno") as unit]
      <tr>
        <td style="background-color:${unit.part.color};" title="${unit.beginAt}-${unit.endAt}">${unit.name}<span style="font-size:0.6rem;">${unit.beginAt}-${unit.endAt}</span></td>
        [#list table.weekdays as wd]
        <td id="TD${unit_index+(wd.id-1)*table.timeSetting.units?size}_${tableIndex}"  style="font-size:${fontSize?default(12)}px"></td>
        [/#list]
      </tr>
      [/#list]
    </table>
    [@tableScripts table,tableIndex/]
  [#else]
    <table width="100%" class="grid-table"  style="text-align:center">
        <thead>
         <tr height="10px">
          <th style="background-color: #DEEDF7;width:80px" rowspan="2">星期/节次</th>
          [#list table.timeSetting.units?sort_by("indexno") as unit]
          <th style="background-color:${unit.part.color};font-weight:normal;">${unit.beginAt}-${unit.endAt}</th>
          [/#list]
         </tr>
         <tr style="background-color: #DEEDF7;">
          [#list table.timeSetting.units?sort_by("indexno") as unit]
          <th style="font-weight:normal;">${unit.name}</th>
          [/#list]
         </tr>
        </thead>
      [#list table.weekdays as wd]
      <tr>
          <td style="background-color: #DEEDF7;">${weekNames[wd.id]}</td>
          [#list 1..table.timeSetting.units?size as unit]
          <td id="TD${(wd.id-1)*table.timeSetting.units?size+unit_index}_${tableIndex}" style="font-size:${fontSize?default(12)}px"></td>
          [/#list]
      </tr>
      [/#list]
    </table>
    [@tableScripts table,tableIndex/]
  [/#if]
  [@tableLegend/]
[/#macro]

[#macro tableScripts(table,tableIndex)]
  <script language="JavaScript">
    var table${tableIndex} = new CourseTable('${semester.beginOn?string("yyyy-MM-dd")}',[[#list table.timeSetting.units?sort_by('indexno') as u][${u.beginAt.value},${u.endAt.value}][#if u_has_next],[/#if][/#list]]);
    var activity=null;
    [#if table.timePublished]
    [#list table.activities as s]
      [#if table.category=="squad"]
        [#assign c = s.clazz.course]
        activity = table${tableIndex}.newActivity("${c.name}(${(s.clazz.crn)!})","[@getNames s.teachers/]","[#if table.placePublished][@getNames s.rooms/][/#if]","${s.time.startOn?string('yyyy-MM-dd')}",${s.time.weekstate.value});
      [#else]
        activity = table${tableIndex}.newActivity("${s.clazz.course.name}(${(s.clazz.crn)!})","[@getNames s.teachers/]","[#if table.placePublished][@getNames s.rooms/][/#if]","${s.time.startOn?string('yyyy-MM-dd')}",${s.time.weekstate.value});
      [/#if]
      table${tableIndex}.addActivityByTime(activity,${s.time.weekday.id},${s.time.beginAt.value},${s.time.endAt.value});
    [/#list]
    [/#if]
    [#if miniActivities??]
      [#list miniActivities as k,acts]
        [#list acts as act]
        activity = table${tableIndex}.newActivity("${act.subject}(${act.comments!})","${act.users!}","${act.places!}","${act.time.startOn?string('yyyy-MM-dd')}",${act.time.weekstate.value});
        [#assign sepIdx = k?index_of("_")/]
        table${tableIndex}.addActivityByUnit(activity,${k?substring(0,sepIdx)},${k?substring(sepIdx+1)},${k?substring(sepIdx+1)});
        [/#list]
      [/#list]
    [/#if]
    table${tableIndex}.marshalTable().fillTable("${table.style}",${tableIndex});
  </script>
[/#macro]
