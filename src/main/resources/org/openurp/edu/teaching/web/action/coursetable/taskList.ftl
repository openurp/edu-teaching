[#ftl]
[@b.grid items=taskList?sort_by("courseType","name") var="clazz" sortable="false" style="border: 0.5px solid #006CB2;"]
    [@b.row]
        [@b.col title="序号" width="3%"]${clazz_index+1}[/@]
        [@b.col property="crn" title="课程序号" width="5%"]
          [@b.a href="clazz!info?clazz.id="+clazz.id title="查看详情" target="_blank"]${clazz.crn}[/@]
        [/@]
        [@b.col property="course.code" title="课程代码" width="7%"/]
        [@b.col property="course.name" title="课程名称" width="17%"]
          [#if showClazzIndex]
            [@b.a href="clazz?clazz.id="+clazz.id title="进入课程" target="_blank"]${clazz.courseName}[/@]
          [#else]
            [@b.a href="clazz!info?clazz.id="+clazz.id title="查看详情" target="_blank"]${clazz.courseName}[/@]
          [/#if]
        [/@]
        [@b.col property="courseType.name" title="课程类别" width="12%"]
          <span style="font-size:0.8em">${clazz.courseType.name}</span>
        [/@]
        [@b.col property="clazzName" title="教学班"]
          <div class="text-ellipsis" title="${clazz.clazzName}">${clazz.clazzName}</div>
        [/@]
        [@b.col title="周数" width="5%"]
          ${(clazz.schedule.firstWeek)!}~${(clazz.schedule.lastWeek)!}
        [/@]
        [@b.col title="第一次上课" width="10%"]
        [#if table.timePublished]${(clazz.schedule.firstDateTime?string("yyyy-MM-dd HH:mm"))!}[/#if]
        [/@]
        [@b.col title="上课地点" width="10%"]
          [#if table.placePublished]
          [#assign rooms=[]/]
          [#list clazz.schedule.activities as s]
            [#list s.rooms as r]
              [#if !rooms?seq_contains(r.name)][#assign rooms=rooms+[r.name]/][/#if]
            [/#list]
          [/#list]
          [#list rooms as r]${r}[#sep],[/#list]
          [/#if]
        [/@]
        [@b.col property="enrollment.stdCount" title="上课人数" width="5%"]
          [@b.a href="clazz!rollbook?clazz.id="+clazz.id target="_blank"]${clazz.enrollment.stdCount?default(0)}[/@]
        [/@]
        [@b.col title="备注" width="6%"]
          [#if clazz.enrollment.genderRatio.value != 0 ]
            [#if clazz.enrollment.genderRatio =="1:0"]男[#elseif clazz.enrollment.genderRatio =="0:1"]女[#else]男女比:${clazz.enrollment.genderRatio}[/#if]
          [/#if]
          ${clazz.remark!}
          [#list clazz.schedule.activities as activity][#if activity.places??]${activity.places}[#if activity_has_next]<br/>[/#if][/#if][/#list]
        [/@]
    [/@]
[/@]
