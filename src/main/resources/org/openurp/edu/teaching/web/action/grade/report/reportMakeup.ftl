[#ftl]
[@b.head/]
[#assign perRecordOfPage = 50/]
[#include "reportMacros.ftl"/]
[@reportStyle/]
[@b.toolbar title="教学班补缓成绩打印"]
  bar.addPrint();
  bar.addClose();
[/@]
[#list reports as report]
  [#if report.gradeState??]
    [#assign recordIndex = 0/]
    [#--按页循环一组成绩--]
    [#assign pageSize = ((report.grades?size / perRecordOfPage)?int * perRecordOfPage == report.grades?size)?string(report.grades?size / perRecordOfPage, report.grades?size / perRecordOfPage + 1)?number/]
    [#list (pageSize == 0)?string(0, 1)?number..pageSize as pageIndex]
    [@makeupReportHead report/]
    <table align="center" class="reportBody" width="95%">
       [@makeupReportColumnTitle report/]
       [#list 0..(perRecordOfPage / 2 - 1) as onePageRecordIndex]
       <tr>
    [@displayMakeupGrade report, recordIndex/]
    [@displayMakeupGrade report, recordIndex + perRecordOfPage / 2/]
        [#assign recordIndex = recordIndex + 1/]
       </tr>
       [/#list]
       [#assign recordIndex = perRecordOfPage * pageIndex/]
    </table>
    [@makeupReportFoot report/]
        [#if (pageIndex + 1 < pageSize)]
    <div style="PAGE-BREAK-AFTER: always"></div>
        [/#if]
    [/#list]
    [#if report_has_next]
    <div style="PAGE-BREAK-AFTER: always"></div>
    [/#if]
    [#else]
      该课程没有学生成绩!
    [/#if]
[/#list]
[@b.foot/]
