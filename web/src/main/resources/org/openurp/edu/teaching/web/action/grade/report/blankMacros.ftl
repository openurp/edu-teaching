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
  font-size: 14px;
  table-layout: fixed;
  text-align:center;
  width:95%;
  margin:auto;
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
  font-size:15px;
}

tr.columnTitle td{
  border-width:1px 1px 2px 1px;
  word-break: break-all;
  white-space:pre-wrap;
}

tr.columnTitle td.columnIndexTitle{
  border-width:1px 1px 2px 2px;
}

table.reportFoot{
  margin-bottom:20px;
}

table.reportFoot.tr {
}

.examStatus{
  font-size:13px;
}

.longScoreText{
  font-size:11px;
}
</style>
[/#macro]

[#macro gaReportHead clazz]
  <table align="center" style="text-align:center" cellpadding="0" cellspacing="0">
    <tr>
      <td style="font-weight:bold;font-size:14pt" height="30px">
      ${clazz.project.school.name}(${clazz.semester.schoolYear}学年${clazz.semester.name}学期)
    期末总评成绩登记表
       </td>
    </tr>
  </table>
  <table width='95%' class="reportTitle" align='center' >
    <tr>
      <td width="30%">课程名称:${clazz.course.name}</td>
      <td width="25%">课程序号:${clazz.crn}</td>
      <td width="20%">课程类别:${clazz.courseType.name}</td>
      <td width="15%">教师:[#list clazz.teachers as t]${t.name}&nbsp;[/#list]</td>
    </tr>
    <tr>
      <td class="text-ellipsis" style="max-width:450px">班级名称:${clazz.clazzName!}</td>
      <td>课程代码:${clazz.course.code}</td>
      <td>考核方式:${(clazz.examMode.name)!}</td>
      <td align="left">人数:${courseTakerMap.get(clazz)?size}</td>
    </tr>
    <tr>
      <td align="left">开课院系:${clazz.teachDepart.name}</td>
      <td colspan="3">成绩类型:
        [#list gradeTypes as gradeType][#if gradeType.id!=EndGa.id]&nbsp;${(gradeType.name)!}(${courseGradeState.getPercent(gradeType)!('___')}％)[/#if][/#list]
      </td>
    </tr>
  </table>
[/#macro]

[#macro gaReportFoot(clazz)]
    <table align="center" class="reportFoot" width="95%">
      <tr>
      <td width="20%">统计人数:${courseTakerMap.get(clazz)?size}</td>
      <td width="25%">总评平均成绩:</td>
      <td width="25%">教师签名:</td>
      <td width="30%">成绩录入日期:________年____月____日</td>
    </tr>
  </table>
[/#macro]

[#macro makeupReportHead clazz]
  <table align="center" style="text-align:center" cellpadding="0" cellspacing="0">
    <tr>
      <td style="font-weight:bold;font-size:14pt" height="30px">
      ${clazz.project.school.name}(${clazz.semester.schoolYear}学年${clazz.semester.name}学期)
      补(缓)考成绩登记表
       </td>
    </tr>
  </table>
  <table width='95%' class="reportTitle" align='center'>
    <tr>
      <td width="30%">课程名称:${clazz.course.name}</td>
      <td width="25%">课程序号:${clazz.crn}</td>
      <td width="20%">课程类别:${clazz.courseType.name}</td>
      <td width="15%">教师:[#list clazz.teachers as t]${t.name}&nbsp;[/#list]</td>
    </tr>
    <tr>
      <td class="text-ellipsis" style="max-width:450px">班级名称:${clazz.clazzName!}</td>
      <td>课程代码:${clazz.course.code}</td>
      <td>考核方式:${clazz.examMode.name}</td>
      <td align="left">人数:${(courseTakers?size)!0}</td>
    </tr>
    <tr>
      <td align="left">开课院系:${clazz.teachDepart.name}</td>
      <td colspan="2">百分比:[#if courseGradeState.getPercent(Usual)??]${Usual.name}${(courseGradeState.getPercent(Usual)!('___'))!}％,[/#if]
       ${End.name}${(courseGradeState.getPercent(End)!('___'))!}％
      </td>
      <td></td>
    </tr>
  </table>
[/#macro]

[#macro gaColumnTitle]
  <tr align="center" class="columnTitle">
    [#list 1..2 as i]
    <td class="columnIndexTitle" width="5%">序号</td>
    <td width="15%">学号</td>
    <td width="8%">姓名</td>
      [#list gradeTypes as gradeType]<td width="${22/gradeTypes?size}%">${gradeType.name}</td>[/#list]
    [/#list]
  </tr>
[/#macro]

[#macro makeupColumnTitle]
<tr align="center" class="columnTitle">
  <td class="columnIndexTitle" width="5%">序号</td>
  <td width="17%">学号</td>
  <td width="10%">姓名</td>
  <td width="8%">修读类别</td>
  <td width="10%">${Usual.name}</td>
  <td width="10%">补缓成绩</td>
  <td width="10%">${EndGa.name}</td>
  <td width="30%">期末情况</td>
</tr>
[/#macro]

[#macro makeupReportFoot clazz]
    <table align="center" class="reportFoot" width="95%">
      <tr>
      <td width="20%">统计人数:${courseTakerMap.get(clazz)?size}</td>
      <td width="20%"></td>
      <td width="30%">教师签名:</td>
      <td width="30%">成绩录入日期:________年____月____日</td>
    </tr>
  </table>
[/#macro]

[#macro displayGaTaker(courseTakers, objectIndex)]
[#if courseTakers[objectIndex]??]
  [#assign courseTaker = courseTakers[objectIndex] /]
  <td class="columnIndex">${objectIndex + 1}</td>
  <td>${courseTaker.std.code!}</td>
  <td>${courseTaker.std.name!}[#if courseTaker.takeType?exists && courseTaker.takeType.id != 1]<sup>${courseTaker.takeType.name}</sup>[/#if]</td>

  [#if courseTaker.takeType.id==5]
    <td colspan="${gradeTypes?size}">[#if courseGrades.get(courseTaker.std)??]${courseGrades.get(courseTaker.std).remark!}[/#if]</td>
  [#else]
    [#list gradeTypes as gradeType]
    <td style="font-size:11px">
      [#if gradeType.examType?? && examTakers.get(courseTaker.std)??]
       [#local et = examTakers.get(courseTaker.std)/]
       [#if et.examType==gradeType.examType && et.examStatus.id !=1 ]
       ${et.examStatus.name}
       [/#if]
      [/#if]
    </td>
    [/#list]
  [/#if]
[#else]
  <td class="columnIndex"></td>
  <td></td>
  <td></td>
  [#list gradeTypes as gradeType]
  <td></td>
  [/#list]
[/#if]
[/#macro]

[#macro displayMakeupTaker(courseTakers, objectIndex)]
[#if courseTakers[objectIndex]??]
  [#assign courseTaker = courseTakers[objectIndex]/]
  [#local cg =courseGrades.get(courseTaker.std)!]
  [#local et =examTakers.get(courseTaker.std)]
  <td class="columnIndex">${objectIndex + 1}</td>
  <td>${courseTaker.std.code!}</td>
  <td>${courseTaker.std.name!}[#if courseTaker.takeType?exists && courseTaker.takeType.id != 1]<sup>${courseTaker.takeType.name}</sup>[/#if]</td>
  <td>${courseTaker.takeType.name}</td>
  <td>
  [#if et.examType.name?index_of('缓')> -1]
  ${(courseGrades.get(courseTaker.std).getScoreText(Usual))!}
  [#else]
  --
  [/#if]
  </td>
  <td></td>
  <td></td>
  <td style="font-size:0.8em">
   [#if et.examType.name?index_of('缓')> -1] 缓考[#t]
   [#else]
     [#if ((cg.getExamGrade(End).examStatus.id)!0) != 1]
      ${(cg.getExamGrade(End).examStatus.name)!}[#t]
     [#else]不及格[#t]
     [/#if][#t]
   [/#if]
  </td>
[#else]
  <td class="columnIndex"></td>
  [#list 1..7 as i]<td></td>[/#list]
[/#if]
[/#macro]

[#include "blankMacroExt.ftl"/]
