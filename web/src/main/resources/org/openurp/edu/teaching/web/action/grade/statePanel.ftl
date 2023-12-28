<p style="margin: 0.5rem 0 0.5rem 0;">录入时间
   <span class="text-muted">
     [#if gradeInputSwitch.checkOpen()]
       (${gradeInputSwitch.beginAt?string("yy-MM-dd")} ~ ${gradeInputSwitch.endAt?string("MM-dd")}开放)
     [#else]
       (未开放录入)
     [/#if]
   </span>
   <hr style="margin:0 0 0.5rem 0">
   期末成绩
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

[#if (makeupTakerCounts.get(clazz)!0)>0]
<br>
补缓成绩
  [#if (gradeState.getState(MakeupGa).confirmed)!false ||  (gradeState.getState(DelayGa).confirmed)!false]
    [@b.a href="!report?clazzId=${clazz.id}&gradeType.id=${MakeupGa.id}&gradeType.id=${DelayGa.id}" target="_blank"]打印[/@]
    [#if !((gradeState.getState(MakeupGa).published)!false)]
      [@b.a href="grade!revokeMakeup?clazzId="+clazz.id target="_blank"]撤回[/@]
    [/#if]
    [#if (gradeState.getState(MakeupGa).updatedAt)??]<span class="text-muted" style="font-size:0.8rem">最后录入:${gradeState.getState(MakeupGa).updatedAt?string("MM-dd HH:mm")}</span>[/#if]
  [#else]
    [#assign openMakeup=false]
    [#list gradeInputSwitch.types as t][#if t.id==4 || t.id==6][#assign openMakeup=true][#break/][/#if][/#list]
    [#if gradeInputSwitch.checkOpen() && openMakeup]
    [@b.a href="!clazz?clazzId=${clazz.id}#panelMakeup" target="_blank"]录入[/@]
    [/#if]
  [/#if]
[/#if]
</p>
