[#ftl]
<!DOCTYPE html>
<html lang="zh_CN">
  <head>
    <title></title>
    <meta http-equiv="content-type" content="text/html;charset=utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
    ${b.static.load(["jquery","beangle","bui"])}
    <script>
      beangle.staticBase="${b.static_base}/";
    </script>
  </head>
<body style="margin:auto;">
<style>
body{
 margin:auto;
}
.contentTableTitleTextStyle {
    font-weight:bold;
    font-size:18pt;
    font-family:宋体
}
.listTable {
    border: 0.5px solid #006CB2;
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
  border: 0.5px solid #006CB2;
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
[@b.toolbar title='课程点名册']
   bar.addItem("${b.text('action.print')}","print()");
[/@]
[#assign stdCountFirstPage = 30]
[#assign stdCountPerPage = 35]
[#assign units = clazz.schedule.lastWeek - clazz.schedule.firstWeek + 1 /]
[#assign stdIndex = 1 /]
<table width="100%">
  <tr><td align="center"><label class="contentTableTitleTextStyle">${clazz.project.school.name}课程点名册</label></td></tr>
  <tr><td align="center"><label class="contentTableTitleTextStyle" style="font-size:14pt;">${clazz.semester.schoolYear}学年第${clazz.semester.name}学期</label></td></tr>
</table>

<table width="100%">
  <tr class="infoTitle">
    <td>课程序号：${clazz.crn}</td>
    <td>课程名称：${clazz.course.name}</td>
    <td>授课教师：[#list clazz.teachers as teacher]${teacher.name}[#if teacher_has_next],[/#if][/#list]</td>
    <td>课程安排：${schedule!}</td>
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
    <colgroup span="5"/>
    <colgroup>
       [#list 1..units as i]<col style="width:${60.0/units}%"></col>[/#list]
    </colgroup>
    <tr align="center" class="darkColumn">
      <td width="4%" rowspan="2">序号</td>
      <td width="8%" rowspan="2">学号</td>
      <td width="8%" rowspan="2">姓名</td>
      <td width="4%" rowspan="2">性别</td>
      <td width="16%" rowspan="2">班级</td>
      <td width="60%" colspan="${units}">考勤登记</td>
    </tr>
    <tr align="center" class="darkColumn">
        [#list 1..units as i]
          <td>${i}</td>
        [/#list]
    </tr>
    [#list subCourseTakers as taker]
      <tr align="center">
        <td>${stdIndex}</td>
        <td style="font-size: 10px;">${taker.std.code}</td>
        <td>${taker.std.name}
        [#if taker.takeType.id!=1]<sup>${(taker.takeType.name)!}[#if taker.freeListening]免听[/#if]</sup>[/#if]
        </td>
        <td>${taker.std.gender.name}</td>
        <td>
          <div class="text-ellipsis" style="max-width:100px">${(taker.std.state.squad.name)!}</div>
        </td>
        [#list 1..units as i]
        <td>&nbsp;</td>
        [/#list]
      </tr>
      [#assign stdIndex = stdIndex+1]
    [/#list]
  </table>
  <table style="width:100%">
    <tr class="infoTitle">
      <td>说明：
        出勤&nbsp;&radic;&nbsp;&nbsp;
        早退&nbsp;&Omicron;&nbsp;&nbsp;
        旷课&nbsp;&Delta;&nbsp;&nbsp;
        迟到&nbsp;&Phi;&nbsp;&nbsp;
      </td>
      <td style="text-align:right;">教师签名：[#list 1..20 as j]&nbsp;[/#list]________年____月____日</td>
    </tr>
  </table>
  [#if subCourseTakers_has_next]<div style='page-break-after:always'></div>[/#if]
[/#list]
[@b.foot/]
