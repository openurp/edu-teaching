  <div class="card">
    <div class="card-body">
      <div style="display:flex">
        <div style="margin:0px 10px 0px 0px;">[@ems.avatar username=std.code style="border-radius: 10%;width:50px;"/]</div>
        <div>
          <h6>${std.name} ${std.grade.name}级 ${std.level.name}</h6>
          <span class="text-muted">学号：</span>${std.code}<span class="text-muted">&nbsp;导师：</span>${std.majorTutorNames!}<br>
          <span class="text-muted">专业：</span>${std.major.name} ${(std.direction.name)!}
        </div>
      </div>
      <div>
        [#assign courseHours=clazz.courseHours/]
        <span class="text-muted">课时：</span><span [#if courseHours != 18*2]class="text-danger" title="课时应为36"[/#if]>${courseHours}课时</span>
        <br/>
        [#assign course=clazz.course/]

        [#assign unitActivities = {}/]
        [#list clazz.activities as act]
          [#assign unit]${act.time.weekday.id}_${act.beginUnit}_${act.endUnit}[/#assign]
          [#if unitActivities[unit]??][#continue/][/#if]
          [#assign unitActivities = unitActivities + {unit:act}/]
        [/#list]

        [#list unitActivities as unit,act]
          <span class="text-muted">时间：</span>${weekdays[act.time.weekday.id]} (${act.time.beginAt}~${act.time.endAt})${act.beginUnit}~${act.endUnit}节
          <br><span class="text-muted">地点：</span>${act.places!}
          [#if act.advisor1?? || act.advisor2??]<br><span class="text-muted">辅导：</span>${(act.advisor1.name)!} ${(act.advisor2.name)!}[/#if]
          <div>
            [@b.a href="!edit?std.id=${std.id}&course.id=${course.id}&semester.id=${semester.id}&unit=${unit}" class="btn btn-sm btn-link"]<i class="fa-solid fa-edit"></i>填写辅导老师[/@]
            [#if !unit_has_next && clazz.coachHours<18*2]
            [@b.a href="!edit?std.id=${std.id}&course.id=${course.id}&semester.id=${semester.id}" class="btn btn-sm btn-link"]<i class="fa-solid fa-plus"></i>增加单独的艺术辅导[/@]
            [/#if]
          </div>
        [/#list]
        [#if unitActivities?size ==0 && clazz.coachHours < 18*2]
          [@b.a href="!edit?std.id=${std.id}&course.id=${course.id}&semester.id=${semester.id}" class="btn btn-sm btn-link"]<i class="fa-solid fa-plus"></i>安排单独的艺术辅导[/@]
        [/#if]
      </div>
    </div>
  </div>
