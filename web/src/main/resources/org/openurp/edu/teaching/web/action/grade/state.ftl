<p style="margin: 0.5rem 0 0.5rem 0;">期末成绩
   <span class="text-muted">
     [#if gradeInputSwitch.checkOpen()]
       (${gradeInputSwitch.beginAt?string("MM-dd")} ~ ${gradeInputSwitch.endAt?string("MM-dd")}开放)
     [#else]
       (未开放录入)
     [/#if]
   </span>
   <hr style="margin:0 0 0.5rem 0">
[#if gradeState.confirmed]
  [@b.a href="grade!info?clazzId="+clazz.id target="main"]查看[/@]
  [@b.a href="grade!report?clazzId="+clazz.id target="_blank"]打印[/@]
  [#if gradeState.confirmed && !gradeState.published]
  [@b.a href="grade!revokeGa?clazzId="+clazz.id target="_blank"]撤回[/@]
  [/#if]
  [#if (gradeState.getState(EndGa).updatedAt)??]<span class="text-muted" style="font-size:0.8rem">最后录入:${gradeState.getState(EndGa).updatedAt?string("MM-dd HH:mm")}</span>[/#if]
[#else]
  [@b.a href="grade!info?clazzId="+clazz.id target="main"]查看[/@]
  [@b.a href="grade!clazz?clazzId="+clazz.id target="_blank"]开始录入[/@]
[/#if]
</p>
