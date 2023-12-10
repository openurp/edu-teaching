[#ftl/]
[@b.head /]
[@b.toolbar title="打印试卷贴"]
  bar.addPrint();
  bar.addClose();
[/@]
[#macro displayExamStds(examRoom,course,examStds)]
     [#assign idx=idx+1/]
     <table class="examTableStyle">
    <tr style="font-Weight:bold">
      <td width="9%">课程<br>序号</td>
      <td width="9%">课程<br>代码</td>
      <td width="15%">课程<br>名称</td>
      <td width="10%">授课<br>教师</td>
      <td width="15%">开课<br>院系</td>
      <td width="10%">考试<br>人数</td>
      <td width="12%">考试<br>时间</td>
      <td width="11%">考试<br>地点</td>
    </tr>
    <tr>
      <td>[#list examRoom.activities as activity ][#if activity.clazz.course=course][#assign roomActivitiy=activity/]${(activity.clazz.crn)!}[#if activity_has_next] [/#if][/#if][/#list]</td>
          <td>${course.code}</td>
          <td>${course.name}</td>
      <td>[#assign teacherNames=[]][#list examRoom.activities as activity ][#if activity.clazz.course=course][#list activity.clazz.teachers as teacher][#if !teacherNames?seq_contains(teacher.name)][#assign teacherNames =teacherNames +[teacher.name]]${teacher.name}[/#if][/#list][#if activity_has_next] [/#if][/#if][/#list]</td>
      <td>[#if examRoom.teachDepart.shortName??]${examRoom.teachDepart.shortName}[#else]${examRoom.teachDepart.name}[/#if]</td>
      <td><span style="font-weight: bold">${(examStds?size)!}</span></td>
      <td>${(examRoom.examOn?string("yyyy-MM-dd") + " ")!}${(roomActivitiy.beginAt)!}${("～" + roomActivitiy.endAt)!}</td>
      <td>${(examRoom.room.name)!}</td>
    </tr>
    </table>
    <br>
[/#macro]
<style>
.examTableStyle { border : 1px solid #000; border-collapse : collapse; width: 100%; font-size:18px; text-align:center }
.examTableStyle td { border  : 1px solid #000; }
</style>
[#assign idx=0/]
[#list examRooms as examRoom]
    [#if examRoom.activities?size != 1 ]
      [#assign courseStds = courseExamTakers.get(examRoom)/]
      [#list courseStds?keys as c]
      [@displayExamStds examRoom,c,courseStds.get(c)  /]
      [/#list]
    [#else]
      [@displayExamStds examRoom,examRoom.activities?first.clazz.course,examRoom.examTakers /]
    [/#if]
[#if idx >0 && idx%5==0]
  <div style='PAGE-BREAK-AFTER: always'>&nbsp;</div>
[/#if]
[/#list]

[@b.foot/]
