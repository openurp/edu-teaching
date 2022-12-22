[#ftl]

[#assign weekNames = ['--','星期一','星期二','星期三','星期四','星期五','星期六','星期日'] /]
[#macro getListPropertyId(beanList)][#list beanList as bean][#if bean_index>0],[/#if]${(bean.id)!}[/#list][/#macro]
[#macro initCourseTable(table,tableIndex)]
  [#if table.style == "WEEK_TABLE"]
  <div class="grid" style="border:0.5px solid #006CB2">
    <table width="100%" align="center" class="gridtable"  style="text-align:center">
      <thead>
        <tr>
          <th style="background-color:#DEEDF7;" height="10px" width="110px">节次/星期</th>
          [#list table.weekdays as wd]
          <th style="background-color:#DEEDF7;"><font size="2px">${weekNames[wd.id]}</font></th>
          [/#list]
        </tr>
      </thead>
      [#list table.timeSetting.units?sort_by("indexno") as unit]
      <tr>
        <td style="background-color:${unit.part.color};" title="${unit.beginAt}-${unit.endAt}">${unit.name}<span style="font-size:0.6rem;color: #999;">${unit.beginAt}-${unit.endAt}</span></td>
        [#list table.weekdays as wd]
        <td id="TD${unit_index+(wd.id-1)*table.timeSetting.units?size}_${tableIndex}"  style="backGround-Color:#ffffff;font-size:${fontSize?default(12)}px"></td>
        [/#list]
      </tr>
      [/#list]
    </table>
    [@tableScripts table,tableIndex/]
  </div>
  [#else]
  <div class="grid" style="border:0.5px solid #006CB2">
    <table width="100%" align="center" class="gridtable"  style="text-align:center">
        <thead>
         <tr height="10px">
          <th style="background-color: #DEEDF7;width:80px" rowspan="2">星期/节次</th>
          [#list table.timeSetting.units?sort_by("indexno") as unit]
          <th style="background-color:${unit.part.color}">${unit.beginAt}-${unit.endAt}</th>
          [/#list]
         </tr>
         <tr style="background-color: #DEEDF7;">
          [#list table.timeSetting.units?sort_by("indexno") as unit]
          <th>${unit.name}</th>
          [/#list]
         </tr>
        </thead>
      [#list table.weekdays as wd]
      <tr>
          <td style="background-color: #DEEDF7;">${weekNames[wd.id]}</td>
          [#list 1..table.timeSetting.units?size as unit]
          <td id="TD${(wd.id-1)*table.timeSetting.units?size+unit_index}_${tableIndex}" style="backGround-Color:#ffffff;font-size:${fontSize?default(12)}px"></td>
          [/#list]
      </tr>
      [/#list]
    </table>
    [@tableScripts table,tableIndex/]
  </div>
  [/#if]
[/#macro]

[#macro tableScripts(table,tableIndex)]
<script language="JavaScript">
  var table${tableIndex} = new CourseTable('${semester.beginOn?string("yyyy-MM-dd")}',[[#list table.timeSetting.units?sort_by('indexno') as u][${u.beginAt.value},${u.endAt.value}][#if u_has_next],[/#if][/#list]]);
  var activity=null;
  [#list table.sessions as s]
    [#if table.category=="squad"]
      [#assign c=s.clazz.course]
      activity = table${tableIndex}.newActivity("[@getListPropertyId s.teachers/]","[@getTeacherNames s.teachers/]","${c.id}(${(s.clazz.crn)!})","${c.name}(${(s.clazz.crn)!})","[@getListPropertyId s.rooms/]","[#if table.placePublished][@getListName s.rooms/][/#if]","${s.time.startOn?string('yyyy-MM-dd')}",${s.time.weekstate.value});
    [#else]
      activity = table${tableIndex}.newActivity("[@getListPropertyId s.teachers/]","[@getTeacherNames s.teachers/]","${s.clazz.course.id}(${(s.clazz.crn)!})","${s.clazz.course.name}(${(s.clazz.crn)!})","[@getListPropertyId s.rooms/]","[#if table.placePublished][@getListName s.rooms/][/#if]","${s.time.startOn?string('yyyy-MM-dd')}",${s.time.weekstate.value});
    [/#if]
    table${tableIndex}.addActivityByTime(activity,${s.time.weekday.id},${s.time.beginAt.value},${s.time.endAt.value});
  [/#list]
  table${tableIndex}.marshalTable().fillTable("${table.style}",${tableIndex});
</script>
[/#macro]
