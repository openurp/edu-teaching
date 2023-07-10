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
<body style="width:185mm; margin:auto;">
<style>
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
.listTable tbody tr {
  height:27px;
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
[/@]

[#assign stdCountFirstPage = 30]
[#assign stdCountPerPage = 35]
[#assign units = clazz.schedule.lastWeek - clazz.schedule.firstWeek + 1 /]
[#assign stdIndex = 1 /]
<table width="100%">
  <tr>
    <td align="center" colspan="3">
      <label class="contentTableTitleTextStyle"><b>研究生课堂考勤登记表</b></label>
    </td>
  </tr>

  <tr>
    <td align="center" colspan="3">
      <label class="contentTableTitleTextStyle"><B> （${clazz.semester.schoolYear}学年第${clazz.semester.name}学期）</B></label>
    </td>
  </tr>
  <tr class="infoTitle">
    <td>课程序号：${clazz.crn}</td>
    <td>课程类别：${clazz.courseType.name}</td>
    <td>课程名称：${clazz.courseName}</td>
  </tr>
  <tr class="infoTitle">
    <td>学时：${clazz.course.creditHours}</td>
    <td>授课教师：[#list clazz.teachers as teacher]${teacher.name}[#if teacher_has_next],[/#if][/#list]</td>
    <td>开课院系：${clazz.teachDepart.name}</td>
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
    <thead>
      <tr align="center" class="darkColumn">
        <td width="4%" rowspan="2">序号</td>
        <td width="12%" rowspan="2">学号</td>
        <td width="11%" rowspan="2">姓名</td>
        <td width="22%" rowspan="2">专业方向</td>
        <td width="11%" rowspan="2">导师姓名</td>
        <td width="40%" colspan="${units}">考勤登记</td>
      </tr>
      <tr>
        [#list 1..units as i]
          <td>&nbsp;</td>
        [/#list]
      </tr>
    </thead>
    <tbody>
    [#list subCourseTakers as taker]
      <tr align="center">
        <td>${stdIndex}</td>
        <td  style="font-size:13px">${taker.std.code}</td>
        <td>${taker.std.name}</td>
        <td>${(taker.std.state.direction.name)!}</td>
        <td>${(taker.std.tutor.name)!}</td>
        [#list 1..units as i]
        <td>&nbsp;</td>
        [/#list]
      </tr>
      [#assign stdIndex = stdIndex+1]
    [/#list]
    </tbody>
  </table>

  [#if subCourseTakers_has_next]<div style='page-break-after:always'></div>[/#if]
[/#list]
[@b.foot/]
