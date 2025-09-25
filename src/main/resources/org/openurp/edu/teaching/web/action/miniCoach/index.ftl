[@b.head/]
<div class="container-fluid">
  [@b.messages slash="3"/]
  [#assign weekdays = ["","周一","周二","周三","周四","周五","周六","周日"] /]
  <div class="card card-primary card-outline">
    <div class="card-header">
      <h3 class="card-title">[@ems.avatar username=teacher.code/]艺术辅导安排</h3>
      <div class="card-tools">
        <div class="dropdown">
          <button class="btn btn-default dropdown-toggle" type="button" id="dropdownMenuButton" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
          ${semester.year.name}学年${semester.name}学期
          </button>
          <div class="dropdown-menu" aria-labelledby="dropdownMenuButton" id="semester_select" >
          </div>
        </div>
      </div>
    </div>
    <div class="card-body" style="padding-top:0px;">
      [#if maxUnit > 0 && maxWeekday > 0]
      <table class="grid-table" id="occupy-table" style="font-size: 12px;">
        <caption style="caption-side: top;text-align: center;padding-top: 0px;padding-bottom: 0px;">${teacher.name}艺术辅导课表</caption>
        <thead class="grid-head">
          <tr>
            [#list weekdays as weekday]
            [#if weekday_index - maxWeekday < 1]
            <td>${weekday}</td>
            [/#if]
            [/#list]
          </tr>
        </thead>
        <tbody class="grid-body">
          [#list units as unit]
          [#if maxUnit - unit.indexno < 0][#break/][/#if]
          <tr>
            <td>${unit.name}</td>
            [#list weekdays as weekday]
              [#if weekday_index>0 && weekday_index - maxWeekday < 1]
              [#assign unitKey="${weekday_index}_${unit.indexno}"/]
              <td>${occupyMap[unitKey]!}</td>
              [/#if]
            [/#list]
          </tr>
          [/#list]
        </tbody>
      </table>
      <script>
        function mergeRow(tableId, rowStart, colStart) {
          var rows = document.getElementById(tableId).rows;
          var rowLen = rows.length;
          var colLen = rows[0].cells.length;
          for (var j = colLen - 1; j >= colStart; j--) {
            mergeTd = rowStart;
            for (var i = mergeTd + 1; i < rowLen; i++) {
              var tdObj = rows[mergeTd].cells[j]
              var toRemoveTd = rows[i].cells[j]
              if(null == toRemoveTd || "" == toRemoveTd.innerHTML || null == tdObj || "" == tdObj.innerHTML || tdObj.colSpan != toRemoveTd.colSpan || tdObj.innerHTML != toRemoveTd.innerHTML){
                mergeTd = i;
                continue;
              }
              if(tdObj.innerHTML == toRemoveTd.innerHTML) {
                rows[i].removeChild(toRemoveTd);
                tdObj.rowSpan++;
              }
            }
          }
        }
        mergeRow('occupy-table',1,1);
      </script>
      [#else]
        <p>尚未进行艺术辅导安排</p>
      [/#if]
    </div>
  </div>
  <script>
  jQuery.ajax({
    url: "${EmsApi}/base/semesters/${project.id}.json",
    headers:{"Accept":"application/json"},
    success: function(obj){
      var is_restapi = Array.isArray(obj);
      var datas = is_restapi?obj:obj.data;
      var select = $("#semester_select")
      var cnt=0;
      for(var i in datas){
        cnt += 1;
        var data = datas[i], value = data.id;
        var schoolYear = is_restapi?data.schoolYear:data.attributes.schoolYear
        var name = is_restapi?data.name:data.attributes.name
        var title=schoolYear+"学年度"+name+"学期"
        select.prepend('<a href="${b.url("!index")}?semester.id='+value +'" class="dropdown-item">'+title+'</a>');
      }
    }
  });
  </script>

  <div style="text-align:center"><p>[@b.a class="btn btn-sm btn-outline-primary" href="!search?semester.id=${semester.id}"]查找学生，进行排课[/@]</p></div>

  [#list clazzes as clazz]
  [#assign std = clazz.stds?first/]
  <div class="card">
    <div class="card-body">
      <div style="display:flex">
        <div style="margin:0px 10px 0px 0px;">[@ems.avatar username=std.code style="border-radius: 10%;width:50px;"/]</div>
        <div>
          <h6>${std.name} ${std.grade.name}级 ${std.level.name}</h6>
          <span class="text-muted">学号：</span>${std.code}<span class="text-muted">&nbsp;导师：</span>${std.majorTutorNames!}<br/>
          <span class="text-muted">专业：</span>${std.major.name} ${(std.direction.name)!}
        </div>
        <div style="margin-left: auto;"><span class="badge badge-secondary">${clazz_index+1}</span></div>
      </div>
      <div>
        [#assign course=clazz.course/]
        [#assign unitActivities = {}/]
        [#list clazz.activities as act]
          [#assign unit]${act.time.weekday.id}_${act.beginUnit}_${act.endUnit}[/#assign]
          [#if !unitActivities[unit]?? || (((act.coach1.id)!0) == me.id || ((act.coach2.id)!0) == me.id)]
            [#assign unitActivities = unitActivities + {unit:act}/]
          [/#if]
        [/#list]

        [#list unitActivities as unit,act]
          <span class="text-muted">时间：</span>${weekdays[act.time.weekday.id]} (${act.time.beginAt}~${act.time.endAt})${act.beginUnit}~${act.endUnit}节
          <br><span class="text-muted">地点：</span>${act.places!}
          [#if act.coach1?? || act.coach2??]<br><span class="text-muted">辅导：</span>${(act.coach1.name)!} ${(act.coach2.name)!}[/#if]
          <div>
            [#if (((act.coach1.id)!0) == me.id || ((act.coach2.id)!0) == me.id)]
              [@b.a href="!edit?std.id=${std.id}&course.id=${course.id}&semester.id=${semester.id}&unit=${unit}"
                                              class="btn btn-sm btn-link"]<i class="fa-solid fa-edit"></i>修改[/@]
              [@b.a href="!remove?clazz.id=${clazz.id}&unit=${unit}"
                    class="btn btn-sm btn-link text-danger" onclick="return bg.Go(this,null,'确定删除本次艺术辅导安排吗?')"]<i class="fa-solid fa-trash-can"></i>
                    [#if act.teacher??]删除辅导[#else]删除安排[/#if]
              [/@]
            [/#if]
            [#if !unit_has_next]
            [@b.a href="!edit?std.id=${std.id}&course.id=${course.id}&semester.id=${semester.id}" class="btn btn-sm btn-link"]<i class="fa-solid fa-plus"></i>增加单独辅导安排[/@]
            [/#if]
          </div>
        [/#list]
      </div>
    </div>
  </div>
  [/#list]
</div>
[@b.foot/]
