[@b.head/]
<div class="container-fluid">
  [@b.messages slash="3"/]
  [#assign weekdays = ["","周一","周二","周三","周四","周五","周六","周日"] /]
  <div class="card card-primary card-outline">
    <div class="card-header">
      <h3 class="card-title">[@ems.avatar username=teacher.code/]主课课程安排</h3>
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
        <caption style="caption-side: top;text-align: center;padding-top: 0px;padding-bottom: 0px;">导师${teacher.name}的课表(课程+主课)</caption>
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
              <td>[#if occupyMap[unitKey]?? ]<span class="text-muted">${occupyMap[unitKey]}</span>[/#if]${miniOccupyMap[unitKey]!}</td>
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
        <p>尚未进行主课安排</p>
      [/#if]
    </div>
  </div>
  <script>
  function changeSemester(semesterId){
    var form = document.gradeForm;
    if(confirm("需要提交成绩吗(提交后修改,需要联系培养办)？")){
      bg.form.addInput(form,"toSemester.id",semesterId);
      bg.form.submit(form);
    }else{
      bg.form.addInput(form,"semester.id",semesterId);
      form.action="${b.url('!index')}";
      bg.form.submit(form);
    }
  }
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

  [#list stds as std]
  <div class="card">
    <div class="card-body">
      <div style="display:flex">
        <div style="margin:0px 10px 0px 0px;">[@ems.avatar username=std.code style="border-radius: 10%;width:50px;"/]</div>
        <div>
          <h6>${std.name} ${std.grade.name}级 ${std.level.name}</h6>
          <span class="text-muted">学号：</span>${std.code}<br/>
          <span class="text-muted">专业：</span>${std.major.name} ${(std.direction.name)!}
          [#if !studentStateHelper.isInschool(std,semester.beginOn,semester.endOn)]
            <br/><span class="text-muted text-danger">状态：</span><span class="text-danger">不在校</span>
          [/#if]
        </div>
        <div style="margin-left: auto;"><span class="badge badge-secondary">${std_index+1}</span></div>
      </div>
      <div>
        [#assign term=stdGroupTerms["${std.id}_${group.name}"]!0/]
        [#if term>0]
          [#assign course = group.getCourse(term?int)/]
          [#if clazzMap.get(course)?? && clazzMap.get(course).get(std)??]
            [#assign clazz = clazzMap.get(course).get(std)/]
              [#assign courseHours=clazz.courseHours/]
              <span class="text-muted">课时：</span><span [#if courseHours != 18*2]class="text-danger" title="课时应为36"[/#if]>${courseHours}课时</span>
              <br/>
            [#assign unitActivities = {}/]
            [#list clazz.activities as act]
              [#assign unit]${act.time.weekday.id}_${act.beginUnit}_${act.endUnit}[/#assign]
              [#if unitActivities[unit]??][#continue/][/#if]
              [#assign unitActivities = unitActivities + {unit:act}/]
            [/#list]

            [#list unitActivities as unit,act]
              <span class="text-muted">时间：</span>${weekdays[act.time.weekday.id]} (${act.time.beginAt}~${act.time.endAt})${act.beginUnit}~${act.endUnit}节
              <br><span class="text-muted">地点：</span>${act.places!}
              [#if act.coach1?? || act.coach2??]<br><span class="text-muted">辅导：</span>${(act.coach1.name)!} ${(act.coach2.name)!}[/#if]
              <div>
                [@b.a href="!edit?std.id=${std.id}&course.id=${course.id}&semester.id=${semester.id}&unit=${unit}"
                      class="btn btn-sm btn-link"]<i class="fa-solid fa-edit"></i>修改[/@]
                [@b.a href="!remove?clazz.id=${clazz.id}&unit=${unit}"
                      class="btn btn-sm btn-link text-danger" onclick="if(confirm('确定删除该课程的本次安排吗?')){return bg.Go(this,null)}else{return false;}"]<i class="fa-solid fa-trash-can"></i>删除[/@]
                [#if !unit_has_next && clazz.courseHours<18*2]
                [@b.a href="!edit?std.id=${std.id}&course.id=${course.id}&semester.id=${semester.id}" class="btn btn-sm btn-link"]<i class="fa-solid fa-plus"></i>增加[/@]
                [/#if]
              </div>

            [/#list]
            [#if clazz.activities?size==0]
              [@b.a href="!edit?std.id=${std.id}&course.id=${course.id}&semester.id=${semester.id}" class="btn btn-sm btn-link"]<i class="fa-solid fa-plus"></i>安排时间地点[/@]
            [/#if]

          [#else]
            <div>[@b.a href="!edit?std.id=${std.id}&course.id=${course.id}&semester.id=${semester.id}" class="btn btn-sm btn-link"]<i class="fa-solid fa-plus"></i>安排时间地点[/@]</div>
          [/#if]
        [/#if]
      </div>
    </div>
  </div>
  [/#list]
</div>
[@b.foot/]
