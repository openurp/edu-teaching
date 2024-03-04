[@b.head/]
[@b.toolbar title="试卷分析表"]
  bar.addItem("修改内容","editReport()");
  bar.addPrint();
  bar.addClose();
[/@]
<style>
.reportTable {
  border-collapse: collapse;
  border:solid;
  border-width:1px;
  border-color:black;
  vertical-align: middle;
}
table.reportTable td{
  border:solid;
  border-width:1px;
  border-right-width:1;
  border-bottom-width:1;
  border-color:black;
}
</style>
<div class="container" style="font-size:15px;">
    <div align='center'><h4>${clazz.project.school.name}课程考核试卷分析表</h4></div>
    <div align='center' style="font-weight:bold;">(${clazz.semester.schoolYear}学年 [#if clazz.semester.name='1']第一学期[#elseif clazz.semester.name='2']第二学期[#else]${clazz.semester.name}[/#if])</div><br>
    <table align="center" width="100%" border='0'>
      <tr>
        <td width='30%' align='left'>课程名称:${clazz.course.name}</td>
        <td>课程序号:${clazz.crn}</td>
        <td align='left'>课程类别:${clazz.courseType.name}</td>
        <td>主讲教师:[#list clazz.teachers as t]${t.name}[#sep],[/#list]</td>
      </tr>
      <tr>
        <td align='left'><div class="text-ellipsis" style="max-width: 400px;">班级名称:${clazz.clazzName}</div></td>
      <td>课程代码:${clazz.course.code}</td>
      <td>开课院(院、部):${clazz.teachDepart.name}</td>
      <td>人数:${clazz.enrollment.stdCount}</td>
      </tr>
    </table>

     [#list stats as gradeStat]
     <table width="100%" class="reportTable">
       <tr align="center">
        <td rowspan="4" align="left">一、成绩分布</td>
        <td align="left">分数段</td>
        [#list gradeStat.segments as seg]
        <td >${seg.min?string("##.#")}-${seg.max?string("##.#")}</td>
        [/#list]
       </tr>
       <tr align="center">
        <td align="left">人数</td>
        [#list gradeStat.segments as seg]
        <td>${seg.count}</td>
        [/#list]
       </tr>
       <tr align="center">
        <td align="left">比例数</td>
        [#list gradeStat.segments as seg]
        <td>${((seg.count/gradeStat.stdCount)*100)?string("##.#")}%</td>
        [/#list]
       </tr>
       <tr align="center">
        <td align="left">实考人数</td>
        <td>${gradeStat.stdCount}</td>
        <td>最高得分数</td>
        <td>${gradeStat.highest?string("##.#")}</td>
        <td>最低得分数</td>
        <td colspan="2">${gradeStat.lowest?if_exists?string("##.#")}</td>
       </tr>
       <tr>
         <td colspan="8">
二、综合分析（要求字数不少于200）：<br>
1.考卷内容分析（可从考核重点、题型、题量、难易度、覆盖面等说明）<br>
2.学生答卷情况分析（可从学生较易得分、较难得分，学生的答卷与教师期望的差别等方面说明）<br>
3.按教学大纲提高课堂教学质量的对策<br>
4.进一步提高命题质量的措施
         </td>
       </tr>
       <tr>
        <td colspan="8">
        <table border="0" cellpadding="0" cellspacing="0" width="100%" style="border-color:white">
          <tr valign="top">
            <td height="380" style="border-color:white;white-space: pre-wrap;">${(analysis.contents)!""}</td>
          </tr>
        </table>
        <div align="right">授课老师签名：<U>[#list 1..30 as  i]&nbsp;[/#list]</U></div>
        <div align="right">日期：<U>[#list 1..30 as  i]&nbsp;[/#list]</U></div>
        </td>
       </tr>
     </table>
     [/#list]
   [#assign segmentSize= stats?first.segments?size/]
     <table align="center" width="100%" border='0' style="font-size:15px;">
      <tr>
       <td style="vertical-align: top;">
       注：
        <div style="margin-left: 20px;">
          1.每个课程序号（教学班）需制作一份试卷分析。<br>
          2.同一课程代码但有多个课程序号（教学班）的，不需要制作总的试卷分析。<br>
          3.本表填写完成后可一式三份双面打印，一份由教研室留存，两份与试卷一起归档至教务处试卷库。
        </div>
      </td>
       <td>
        <div style="margin-top:10px">
          <div align="right">教研室主任签字：<U>[#list 1..30 as  i]&nbsp;[/#list]</U></div>
          <div align="right">日期：<U>[#list 1..30 as  i]&nbsp;[/#list]</U></div>
          <div align="right">院、部领导审核签字：<U>[#list 1..30 as  i]&nbsp;[/#list]</U></div>
          <div align="right">日期：<U>[#list 1..30 as  i]&nbsp;[/#list]</U></div>
        </div>
       </td>
      </tr>
    </table>
</div>
 [@b.form action="!examAnalysis" name="actionForm"]
  <input type="hidden" name="clazzId" value="${clazz.id}"/>
 [/@]
<script type="text/javascript">
     var form = document.actionForm;
     function editReport() {
       bg.form.submit(form);
     }
</script>
[@b.foot/]
