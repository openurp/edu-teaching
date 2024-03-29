[#ftl]
[@b.head/]
[#assign perRecordOfPage = 70/]
[#include "reportMacros.ftl"/]
[@reportStyle/]
[@b.toolbar title="教学班总评成绩打印"]
  bar.addPrint();
  bar.addClose();
[/@]
[#list reports as report]
  [#if report.gradeState??]
    [#assign recordIndex = 0/]
    [#--按页循环一组成绩--]
    [#assign pageSize = ((report.grades?size / perRecordOfPage)?int * perRecordOfPage == report.grades?size)?string(report.grades?size / perRecordOfPage, report.grades?size / perRecordOfPage + 1)?number/]
    [#list (pageSize == 0)?string(0, 1)?number..pageSize as pageIndex]
    [@gaReportHead report/]
    [#assign totalNormal=0/]
    [#assign totalNormalScore=0/]
    [#list report.grades as courseGrade]
      [#assign examGrade=courseGrade.getGrade(End)!"null"/]
      [#if examGrade!="null" && (examGrade.examStatus.id!0)=1]
        [#assign totalNormal=totalNormal + 1 /] [#assign totalNormalScore=totalNormalScore+(examGrade.courseGrade.getGrade(EndGa).score)!0/]
      [/#if]
    [/#list]
    <table  class="reportBody" width="95%">
       [@reportColumnTitle report/]
       [#list 0..(perRecordOfPage / 2 - 1) as onePageRecordIndex]
       <tr>
    [@displayGaGrade report, recordIndex/]
    [@displayGaGrade report, recordIndex + perRecordOfPage / 2/]
        [#assign recordIndex = recordIndex + 1/]
       </tr>
       [/#list]
       [#assign recordIndex = perRecordOfPage * pageIndex/]
    </table>
    [@gaReportFoot report/]
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
