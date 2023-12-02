[#ftl]
[#macro reportStyle]
<style type="text/css">
.reportBody {
    border:solid;
    border-color:#006CB2;
    border-collapse: collapse;
    border-width:2px;
    vertical-align: middle;
    font-style: normal;
    font-size: 13px;
    font-family:宋体;
    table-layout: fixed;
    text-align:center;
    white-space: nowrap;
}
table.reportBody td{
    border-style:solid;
    border-color:#006CB2;
    border-width:0 1px 1px 0;
}

table.reportBody td.columnIndex{
    border-width:0 1px 1px 2px;
}

table.reportBody tr{
  height:20px;
}
table.reportTitle tr{
  height:20px;
  border-width:1px;
  font-size:13px;
}
tr.columnTitle td{
  border-width:1px 1px 2px 1px;
  word-break: break-all;
  white-space:pre-wrap;
}

tr.columnTitle td.columnIndexTitle{
  border-width:1px 1px 2px 2px;
  font-size:12px;
}

table.reportFoot{
  margin-bottom:20px;
}
table.reportFoot.tr {
}
.examStatus{
  font-size:10px;
}
.longScoreText{
  font-size:10px;
}
</style>

[/#macro]

[#macro gaReportHead report]
<table align="center" style="text-align:center" cellpadding="0" cellspacing="0">
        <tr>
            <td style="font-weight:bold;font-size:14pt" height="30px">
            ${report.clazz.project.school.name}(${(report.clazz.semester.schoolYear)?if_exists}学年${(report.clazz.semester.name)?if_exists?replace("0","第")}学期)
            期末总评成绩登记表
             <td>
        </tr>
    </table>
    <table width='95%' class="reportTitle" align='center'>
        <tr>
          <td width="30%">课程名称:${report.clazz.course.name}</td>
            <td width="25%">
            课程序号:
            [#if report.clazz.crn?starts_with(report.clazz.course.code)]${report.clazz.crn}
            [#else] ${report.clazz.course.code}(${report.clazz.crn})[/#if]
            </td>
            <td width="20%">课程类别:${report.clazz.courseType.name}</td>
            <td width="15%">教师:[#list report.clazz.teachers as t]${t.name}&nbsp;[/#list]</td>
        </tr>
        <tr>
            <td colspan="2">班级名称:
            [#assign len = (report.clazz.clazzName)?length/]
            [#assign squadName = report.clazz.clazzName!/]
            [#assign max = 28/]
            [#if len>max]
              [#list 0..(len/max-1) as i]
                <span style="font-size:11px">${squadName?substring(i*max,i*max+max)} </span>
              [/#list]
              [#if (len%max !=0)]
                <span style="font-size:11px">${squadName?substring(len-(len%max),len)}</span>
              [/#if]
            [#else]
              ${squadName}
            [/#if]
            </td>
            <td>考核方式:${report.clazz.examMode.name}</td>
            <td align="left">人数:${(report.grades?size)!0}</td>
        </tr>
        <tr>
          <td align="left">开课院系:${report.clazz.teachDepart.name}</td>
          <td colspan="3">成绩类型:
            [#list report.gradeTypes as gradeType]
            [#if (report.gradeState.getState(gradeType).scorePercent)??]&nbsp;${(gradeType.name)!}(${report.gradeState.getState(gradeType).scorePercent}％)[/#if]
            [/#list]
          </td>
        </tr>
    </table>
[/#macro]

[#macro gaReportFoot report]
    <table align="center" class="reportFoot" width="95%">
      <tr>
      <td width="20%">统计人数:${totalNormal!0}</td>
      <td width="25%">总评平均成绩:[#if totalNormal>0]${totalNormalScore/totalNormal}[/#if]</td>
      <td width="25%">教师签名:</td>
      <td width="30%">成绩录入日期:${(report.gradeState.getState(EndGa).updatedAt?string('yyyy-MM-dd'))!}</td>
    </tr>
  </table>
[/#macro]

[#macro makeupReportHead report]
<table align="center" style="text-align:center" cellpadding="0" cellspacing="0">
        <tr>
            <td style="font-weight:bold;font-size:14pt" height="30px">
            ${report.clazz.project.school.name}(${(report.clazz.semester.schoolYear)?if_exists}学年${(report.clazz.semester.name)?if_exists?replace("0","第")}学期)
            补(缓)考成绩登记表
             <td>
        </tr>
    </table>
    <table width='95%' class="reportTitle" align='center'>
        <tr>
          <td width="30%">课程名称:${report.clazz.course.name}</td>
            <td width="25%">课程代码:${report.clazz.course.code}</td>
            <td width="20%">课程类别:${report.clazz.courseType.name}</td>
            <td width="15%">教师:[#list report.clazz.teachers as t]${t.name}&nbsp;[/#list]</td>
        </tr>
        <tr>
            <td>班级名称:
            [#assign len = (report.clazz.clazzName)?length/]
            [#assign squadName = report.clazz.clazzName!/]
            [#assign max = 28/]
            [#if len>max]
              [#list 0..(len/max-1) as i]
                ${squadName?substring(i*max,i*max+max)}<br>
              [/#list]
              [#if (len%max !=0)]
                ${squadName?substring(len-(len%max),len)}
              [/#if]
            [#else]
              ${squadName}
            [/#if]
            </td>
            <td>课程序号:${report.clazz.crn}</td>
            <td>考核方式:${(report.clazz.examMode.name)!}</td>
            <td align="left">人数:${(report.grades?size)!0}</td>
        </tr>
        <tr>
          <td align="left">院系:${(report.clazz.enrollment.depart.name)!}</td>
          <td colspan="3"></td>
        </tr>
    </table>
[/#macro]

[#macro reportColumnTitle report]
<tr align="center" class="columnTitle">
         [#list 1..2 as i]
         <td class="columnIndexTitle" width="5%">序号</td>
         <td width="15%">学号</td>
         <td width="10%">姓名</td>
            [#list report.gradeTypes as gradeType]
            <td width="${22/report.gradeTypes?size}%">${gradeType.name!}</td>
            [/#list]
         [/#list]
       </tr>
[/#macro]

[#macro makeupReportColumnTitle report]
<tr align="center" class="columnTitle">
   [#list 1..2 as i]
   <td class="columnIndexTitle" width="5%">序号</td>
   <td width="15%">学号</td>
   <td width="10%">姓名</td>
   [#list report.gradeTypes as gradeType]
      [#if !gradeType.ga && gradeType.id!=FINAL.id]
      <td width="${22/(report.gradeTypes?size)}%">${gradeType.name!}</td>
      [/#if]
   [/#list]
   <td width="${22/(report.gradeTypes?size)}%">总评/最终</td>
   [/#list]
 </tr>
[/#macro]

[#macro makeupReportFoot report]
  <table align="center" class="reportFoot" width="95%">
    <tr>
    <td width="20%">统计人数:${report.grades?size}</td>
    <td width="20%"></td>
    <td width="30%">教师签名:</td>
    <td width="30%">成绩录入日期:${(report.gradeState.updatedAt?string('yyyy-MM-dd'))!}</td>
  </tr>
</table>
[/#macro]

[#macro displayGaGrade(report, objectIndex)]
[#if report.grades[objectIndex]??]
    [#assign courseGrade = report.grades[objectIndex]/]
    <td class="columnIndex">${objectIndex + 1}</td>
    <td style="font-size:11px">${courseGrade.std.code!}</td>
    <td style="font-size:11px">${courseGrade.std.name!}[#if courseGrade.courseTakeType?exists && courseGrade.courseTakeType.id != 1]<sup>${courseGrade.courseTakeType.name}</sup>[/#if]</td>

    [#list report.gradeTypes as gradeType]
    <td>
    [#local examGrade=courseGrade.getGrade(gradeType)!"null"/]
    [#if examGrade!="null"]
    [#if !examGrade.gradingMode.numerical && (examGrade.scoreText!)?length>2]<span class="longScoreText">${examGrade.scoreText!}</span>[#else]${examGrade.scoreText!}[/#if][#if examGrade.examStatus?? && examGrade.examStatus.id!=1]<span class="examStatus"> ${examGrade.examStatus.name}</span>[/#if]
    [/#if]
    </td>
     [/#list]
[#else]
    <td class="columnIndex"></td>
    <td></td>
    <td></td>
    [#list report.gradeTypes as gradeType]
    <td></td>
    [/#list]
[/#if]
[/#macro]

[#macro displayMakeupGrade(report, objectIndex)]
[#if report.grades[objectIndex]??]
    [#assign courseGrade = report.grades[objectIndex]/]
    <td class="columnIndex">${objectIndex + 1}</td>
    <td style="font-size:11px">${courseGrade.std.code!}</td>
    <td style="font-size:11px">${courseGrade.std.name!}[#if courseGrade.courseTakeType?exists && courseGrade.courseTakeType.id != 1]<span style="font-size: 5.5pt; top: -4px; position: relative">${courseGrade.courseTakeType.name}</span>[/#if]</td>
    [#list report.gradeTypes as gradeType]
    [#if !gradeType.ga && gradeType.id!=FINAL.id]
      <td>
      [#local examGrade=courseGrade.getGrade(gradeType)!"null"/]
      [#if examGrade!="null"]
      [#if !examGrade.gradingMode.numerical && (examGrade.scoreText!)?length>2]<span class="longScoreText">${examGrade.scoreText!}</span>[#else]${examGrade.scoreText!}[/#if][#if examGrade.examStatus?? && examGrade.examStatus.id!=1]<span class="examStatus"> ${examGrade.examStatus.name}</span>[/#if]
      [/#if]
      </td>
    [/#if]
     [/#list]
     <td>
     [#list courseGrade.gaGrades as ga]
        [#if ga.gradeType.id!=EndGa.id]
          ${ga.scoreText!}
        [/#if]
      [/#list]
     </td>
[#else]
    <td class="columnIndex"></td>
    <td></td>
    <td></td>
    [#list report.gradeTypes as gradeType]
      [#if !gradeType.ga]
    <td></td>
      [/#if]
    [/#list]
    <td></td>
[/#if]
[/#macro]

[#include "reportMacroExt.ftl"/]
