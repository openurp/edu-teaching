[#ftl]
[@b.head/]
[#assign perRecordOfPage = 70/]
[#include "blankMacros.ftl"/]
[@reportStyle/]
[@b.toolbar title="教学班总评成绩登分表打印"]
  bar.addPrint();
  bar.addClose();
[/@]
[#list clazzes as clazz]
    [#assign recordIndex = 0/]
    [#assign courseTakers = courseTakerMap.get(clazz)?sort_by(["std","code"])/]
    [#assign examTakers = examTakerMap.get(clazz)/]
    [#assign courseGradeState = stateMap.get(clazz)/]
    [#assign courseGrades = courseGradeMap.get(clazz)/]
    [#assign pageSize = ((courseTakers?size / perRecordOfPage)?int * perRecordOfPage == courseTakers?size)?string(courseTakers?size / perRecordOfPage, courseTakers?size / perRecordOfPage + 1)?number/]
    [#list (pageSize == 0)?string(0, 1)?number..pageSize as pageIndex]
    [@gaReportHead clazz/]
    <table align="center" class="reportBody" width="100%">
       [@gaColumnTitle/]
       [#list 0..(perRecordOfPage / 2 - 1) as onePageRecordIndex]
       <tr>
    [@displayGaTake courseTakers, recordIndex/]
    [@displayGaTake courseTakers, recordIndex + perRecordOfPage / 2/]
        [#assign recordIndex = recordIndex + 1/]
       </tr>
       [/#list]
       [#assign recordIndex = perRecordOfPage * pageIndex/]
    </table>
    [@gaReportFoot clazz/]
        [#if (pageIndex + 1 < pageSize)]
    <div style="PAGE-BREAK-AFTER: always"></div>
        [/#if]
    [/#list]
    [#if clazz_has_next]
    <div style="PAGE-BREAK-AFTER: always"></div>
    [/#if]
[/#list]
[@b.foot/]
