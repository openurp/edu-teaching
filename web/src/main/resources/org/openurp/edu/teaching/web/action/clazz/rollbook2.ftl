[#ftl]
[@b.head/]
<style>
body{
 width:210mm;
 margin:auto;
}
.contentTableTitleTextStyle {
    color: #1F3D83;
    font-size: 15pt;
    font-style: normal;
    font-weight: bold;
    letter-spacing: 0;
    line-height: 16pt;
    text-decoration: none;
}
.listTable {
    border: 1px solid #006CB2;
    border-collapse: collapse;
    font-size: 14px;
    font-style: normal;
    vertical-align: middle;
}
.darkColumn {
    background-color: #C7DBFF;
    color: #000000;
    letter-spacing: 0;
    text-decoration: none;
}
.infoTitle {
    font-size: 14px;
}
.listTable td {
  border: 1px solid #006CB2;
  border-collapse: collapse;
  overflow: hidden;
  word-wrap:break-word;
  padding:2px 0px;
}
.listTable thead tr {
  background-color: #C7DBFF;
  color: #000000;
  letter-spacing: 0;
  text-decoration: none;
}
</style>
[@b.toolbar title='点名册']
   bar.addItem("${b.text('action.print')}","print()");
   bar.addClose("");
[/@]

[#assign stdCountFirstPage = 25]
[#assign stdCountPerPage = 30]
[#assign units = clazz.schedule.lastWeek - clazz.schedule.firstWeek + 1 /]
[#assign stdIndex = 1 /]
<table width="100%">
  <tr>
    <td align="center" colspan="3">
      <label class="contentTableTitleTextStyle"><b>点名册</b></label>
    </td>
  </tr>

  <tr>
    <td align="center" colspan="3">
      <label class="contentTableTitleTextStyle"><B> ${clazz.semester.schoolYear}学年第${clazz.semester.name}学期</B></label>
    </td>
  </tr>
  <tr class="infoTitle">
    <td>课程序号：${clazz.crn}</td>
    <td>课程名称：${clazz.course.name}</td>
    <td>授课教师：[#list clazz.teachers as teacher]${teacher.name}[#if teacher_has_next],[/#if][/#list]</td>
  </tr>
  <tr class="infoTitle">
    <td>说明：</td>
    <td>
      出勤&nbsp;&radic;&nbsp;&nbsp;
      早退&nbsp;&Omicron;&nbsp;&nbsp;
      旷课&nbsp;&Delta;&nbsp;&nbsp;
      迟到&nbsp;&Phi;&nbsp;&nbsp;
    </td>
    <td>教师签名：[#list 1..10 as j]&nbsp;[/#list]________年____月____日</td>
  </tr>
</table>

  [#assign sortedCourseTakers = clazz.enrollment.courseTakers?sort_by(["std","code"])/]
  [#assign firstPageCourseTakers = []/]
  [#assign otherPageCourseTakers=[]/]
  [#if sortedCourseTakers?size>0]
    [#list 1..sortedCourseTakers?size as i]
      [#if i > stdCountFirstPage]
        [#assign otherPageCourseTakers = otherPageCourseTakers +  [sortedCourseTakers[i-1]] /]
      [#else]
        [#assign firstPageCourseTakers = firstPageCourseTakers + [sortedCourseTakers[i-1]] /]
      [/#if]
    [/#list]
  [/#if]
  [#assign courseTakerChunks =[firstPageCourseTakers] + otherPageCourseTakers?chunk(stdCountPerPage) /]

[#list courseTakerChunks as subCourseTakers]
  <table width="100%" border="0" class="listTable">
    <tr align="center" class="darkColumn">
      <td width="3%" rowspan="2">序号</td>
      <td width="7%" rowspan="2">学号</td>
      <td width="7%" rowspan="2">姓名</td>
      <td width="3%" rowspan="2">姓名</td>
      <td width="16%" rowspan="2">班级</td>
      <td width="4%" rowspan="2">修读类别</td>
    [#list 1..units as i]
      <td width="${60/units}%">${i}</td>
    [/#list]
    </tr>
    <tr>
        [#list 1..units as i]
          <td>&nbsp;</td>
        [/#list]
    </tr>
    [#list subCourseTakers as taker]
      <tr  align="center">
        <td>${stdIndex}</td>
        <td style="font-size: 10px;">${taker.std.code}</td>
        <td>${taker.std.name}</td>
        <td>${taker.std.person.gender.name}</td>
        <td>
          [#if ((taker.std.state.squad.name)!"")?length>13]
             <span style="font-size: 8px;">${(taker.std.state.squad.name)!}</span>
          [#else]
             <span style="font-size: 10px;">${(taker.std.state.squad.name)!}</span>
          [/#if]
        </td>
        <td>${(taker.takeType.name)!}[#if taker.freeListening]免听[/#if][#t/]</td>
        [#list 1..units as i]
        <td>&nbsp;</td>
        [/#list]
      </tr>
      [#assign stdIndex = stdIndex+1]
    [/#list]
  </table>

  [#if subCourseTakers_has_next]<div style='page-break-after:always'></div>[/#if]
[/#list]
[@b.foot/]
