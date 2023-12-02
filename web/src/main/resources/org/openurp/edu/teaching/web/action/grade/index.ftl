[@b.head/]
<div class="container-fluid">
  [#include "../project.ftl" /]
  [@b.toolbar title="课程成绩录入"]
  [/@]
  [@base.semester_bar value=semester! formName='courseTableForm'/]
  <div class="search-container">
    <div class="search-list">
    <script language="JavaScript" type="text/JavaScript" src="${b.base}/static/scripts/grade/gradeSeg.js"></script>
    [@b.grid items=clazzes var="clazz"]
      [@b.row]
        [@b.col width="5%" title="序号"]${clazz_index+1}[/@]
        [@b.col width="10%" title="课程序号"]${(clazz.crn)?if_exists}[/@]
        [@b.col width="19%" title="课程名称"]${(clazz.course.name)?if_exists}[/@]
        [@b.col width="12%" title="课程类型"]${(clazz.courseType.name)?if_exists}[/@]
        [@b.col width="5%" title="学分"]${clazz.course.creditsInfo}[/@]
        [@b.col width="5%" title="周课时"]${(clazz.schedule.weekHours)?if_exists}[/@]
        [@b.col width="5%" title="总学时"]${(clazz.schedule.creditHours)?if_exists}[/@]
        [@b.col width="5%" title="学生数"]${clazz.enrollment.courseTakers?size}[/@]
        [@b.col width="17%" title="期末总评成绩"]
          [@b.a href="!blank?clazz.id=${clazz.id}" target="_blank"]登分册[/@]
          [@b.a href="!info?clazzId=${clazz.id}" target="_blank"]查看[/@]
          [#if (gradeStates.get(clazz).getState(EndGa).confirmed)!false]
            [@b.a href="!report?clazzId=${clazz.id}" target="_blank"]成绩单[/@]
            [#--[@b.a onclick="printReportForExam(this,${clazz.id})" target="_blank"]试卷分析表[/@]--]
          [#else]
            [#assign openEnd=false]
            [#list gradeInputSwitch.types as t][#if t.id==2][#assign openEnd=true][#break/][/#if][/#list]
            [#if gradeInputSwitch.checkOpen() && openEnd]
            [@b.a href="!clazz?clazzId=${clazz.id}" target="_blank"]录入[/@]
            [/#if]
          [/#if]
        [/@]
        [@b.col width="17%" title="补缓考试成绩"]
        [#if (makeupTakeCounts.get(clazz)!0)>0]
          [@b.a href="blank?clazz.id=${clazz.id}&makeup=1" target="_blank"]登分册[/@]
          [#if (gradeStates.get(clazz).getState(MakeupGa).confirmed)!false ||  (gradeStates.get(clazz).getState(DelayGa).confirmed)!false]
            [@b.a href="!report?clazzIds=${clazz.id}&gradeType.id=${MakeupGa.id}&gradeType.id=${DelayGa.id}" target="_blank"]成绩单[/@]
            [#if ((gradeStates.get(clazz).getState(MakeupGa).published)!false)||((gradeStates.get(clazz).getState(DelayGa).published)!false) ]已发布[#else]已提交[/#if]
          [#else]
            [#assign openMakeup=false]
            [#list gradeInputSwitch.types as t][#if t.id==4 || t.id==6][#assign openMakeup=true][#break/][/#if][/#list]
            [#if gradeInputSwitch.checkOpen() && openMakeup]
            [@b.a href="!clazz?clazzId=${clazz.id}" target="_blank"]录入[/@]
            [/#if]
          [/#if]
        [/#if]
        [/@]
      [/@]
    [/@]
    <script>
      var s=""
      for(var i=0;i<seg.length;i++){
        var segAttr="segStat.scoreSegments["+i+"]";
        s = s + "&"+ segAttr+".min="+seg[i].min
        s = s + "&"+ segAttr+".max="+seg[i].max
      }
      s = s+"&scoreSegmentsLength="+seg.length

      [#--function printReportForExam(a,clazzId){
        a.href="${b.url('!reportForExam')}" +"?clazzIds="+clazzId + encodeURI(s);
      }--]
    </script>
    </div>
  </div>

[#if gradeInputSwitch.beginAt??]
  <div class="card text-sm text-muted" style="font-size:0.8em">
    <div class="card-body">
      <h5 class="card-title">注意事项：</h5>
      <p class="card-text">
        <p>录入时间:${gradeInputSwitch.beginAt?string("yyyy-MM-dd HH:mm")}~${gradeInputSwitch.endAt?string("yyyy-MM-dd HH:mm")}<br/>${(gradeInputSwitch.remark!)?html}</p>
      </p>
    </div>
  </div>
[/#if]

</div>
[@b.foot/]
