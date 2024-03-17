[#ftl/]
[@b.head /]

[@b.toolbar title="<b>学生考试签名表</b>"]
  bar.addItem("打印", "print()");
  bar.addClose();
[/@]
<style>
.grid-table { font-size:12pt; }
.grid-table tr {height:8mm}
</style>

[#assign tableNum=0]
[#list examRooms as examRoom]
   [#if examRoom.activities?size != 1]
    [#assign courseStds = courseExamTakers.get(examRoom)/]
    [#list courseStds?keys as c]
      [@displayTable examRoom,c,courseStds.get(c)/]
    [/#list]
  [#else]
    [@displayTable examRoom,examRoom.activities?first.clazz.course,examRoom.examTakers /]
  [/#if]
[/#list]

[#macro displayTable(examRoom,course,ess)]
[#assign examTakesList = ess?sort_by('seatNo')?chunk(30) /]
[#list examTakesList as examTakers]
[#if tableNum!=0]<div style='PAGE-BREAK-BEFORE: always'></div>[/#if]

  <table width="100%" align="center">
    <tr>
      <td align="center" colspan="4" style="font-size:18pt;height:45px" ><B>学生考试签名表</B><br></td>
      </tr>
      <tr>
          [#assign teachers = []/]
          [#assign crns = []/]
          [#if examRoom.activities?size>0]
           [#list examRoom.activities as activity][#if activity.clazz.course=course][#list activity.clazz.teachers as teacher][#if !teachers?seq_contains(teacher)][#assign teachers=teachers+[teacher]][/#if][/#list][/#if][/#list]
           [#list examRoom.activities as activity][#if activity.clazz.course=course][#if !crns?seq_contains(activity.clazz.crn)][#assign crns=crns+[activity.clazz.crn]][/#if][/#if][/#list]
          [#else]
           [#list examRoom.examTakers as es][#if es.clazz.course=course][#list es.clazz.teachers as teacher][#if !teachers?seq_contains(teacher)][#assign teachers=teachers+[teacher]][/#if][/#list][/#if][/#list]
           [#list examRoom.examTakers as es][#if es.clazz.course=course][#if !crns?seq_contains(es.clazz.crn)][#assign crns=crns+[es.clazz.crn]][/#if][/#if][/#list]
          [/#if]
          <td width="35%">课程序号:[#if crns?size>2]${crns?first} 等${crns?size}个[#else][#list crns  as no]${no}&nbsp;[/#list][/#if]</td>
          <td width="35%">课程代码:${course.code}</td>
          <td colspan="2">课程名称:${course.name}</td>
      </tr>
      <tr>
          <td>考试类型:${examRoom.examType.name}</td>
          <td>开课院系:${examRoom.teachDepart.name}</td>
          <td>授课教师:[#list teachers as t] ${t.name}[#if t_has_next]&nbsp;[/#if][/#list]</td>
      </tr>
      <tr>
          <td>考试时间:
          [#--可能出现不同的考试时长，放到一个考场里面了，所以按照活动的时间--]
          [#if examRoom.activities?size>0]
            [#list examRoom.activities as activity][#if activity.clazz.course=course]${activity.examOn?string("yyyy-MM-dd")} ${activity.beginAt}~${activity.endAt}[#break/][/#if][/#list]
          [#else]
            [#if examRoom.examOn??]${examRoom.examOn?string("yyyy-MM-dd")} ${examRoom.beginAt}~${examRoom.endAt}[/#if]
          [/#if]
          </td>
          <td>考试地点:${(examRoom.room.name)!}</td>
      </tr>
  </table>

  <table class="grid-table" width="100%">
    <thead class="grid-head">
      <tr>
        <td style="width:5%"><span style="font-size:0.8em">座位号</span></td>
        [#if crns?size>1]
        <td style="width:15%">学号</td>
        <td style="width:14%">姓名</td>
        <td style="width:17%">院系</td>
        <td style="width:20%">班级</td>
        <td style="width:11%">序号 教师</td>
        <td style="width:10%">签名</td>
        <td style="width:8%">备注</td>
        [#else]
        <td style="width:16%">学号</td>
        <td style="width:14%">姓名</td>
        <td style="width:17%">院系</td>
        <td style="width:23%">班级</td>
        <td style="width:18%">签名</td>
        <td style="width:7%">备注</td>
        [/#if]
      </tr>
    </thead>
    [#list examTakers as es]
    <tr class="brightStyle" align="center">
      [#if es?exists]
        <td>${es.seatNo}</td>
        <td>${es.std.code}</td>
        <td>${es.std.name}</td>
        <td>
          [#if ((es.std.state.department.name)!'-')?length>9]
           <span style="font-size:0.7em">${(es.std.state.department.name)!}</span>
          [#else]
           ${(es.std.state.department.name)!}
          [/#if]
        </td>
        <td>
          [#if ((es.std.state.squad.name)!'-')?length>9]
           <span style="font-size:0.7em">${(es.std.state.squad.name)!}</span>
          [#else]
           ${(es.std.state.squad.name)!}
          [/#if]
        </td>
        [#if crns?size>1]
        <td>${es.clazz.crn} [#list es.clazz.teachers as t]${t.name}&nbsp;[/#list]</td>
        [/#if]
        <td>&nbsp;</td>
        <td>&nbsp;[#if es.examStatus.id!=1]${es.examStatus.name}[/#if]</td>
      [#else]
        <td>&nbsp;</td>
        <td>&nbsp;</td>
        <td>&nbsp;</td>
        <td>&nbsp;</td>
        <td>&nbsp;</td><td>&nbsp;</td>
      [/#if]
    </tr>
    [/#list]
  </table>

  [#assign tableNum=tableNum+1 /]
  [/#list]
[/#macro]
[@b.foot/]
