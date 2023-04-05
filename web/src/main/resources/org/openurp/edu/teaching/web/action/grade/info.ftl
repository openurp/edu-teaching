[#ftl]
[@b.head/]
[@b.toolbar title="教学班成绩"]
  bar.addBack();
[/@]
[#macro displayCourseTaker(taker)]
  ${taker.std.name}[#if taker.takeType.id != 1]<sup style="color:red">${taker.takeType.name}</sup>[/#if]
[/#macro]
[#macro displayGrade(grade)]
  [#if grade?? && grade.id??]
    [#list gradeTypes as gtype]
      <td>
      [#if grade.getGrade(gtype)??]
        [#assign gg=grade.getGrade(gtype)/]
        [#if gg.passed]${gg.scoreText!}[#else]<span style="color:red">${gg.scoreText!}</span>[/#if]
      [/#if]
      </td>
    [/#list]
  [#else]
    [#list gradeTypes as g]<td></td>[/#list]
  [/#if]
[/#macro]

<style>
  .idx_td{
    border-left:1px solid #c6ccd2;
    border-right:1px solid #c6ccd2;
    text-align:center;
    width:40px;
  }
</style>
<div class="container-fluid text-sm">
  [@b.card_header]
    <h3 class="card-title">
      <i class="fa-solid fa-list mr-1"></i> ${clazz.crn} ${clazz.course.name} 学生成绩
      <span class="badge badge-success">${clazz.enrollment.courseTakers?size}</span>
    </h3>
    [@b.card_tools]
      [#if gradeState?? && gradeState.isStatus(GA,1?int)]
      [@b.a href="grade!reportGa?clazzId="+clazz.id target="_blank" class="btn btn-sm  btn-success"]<i class="fa-solid fa-print"></i> 打印[/@]
      [/#if]
    [/@]
  [/@]

  [#assign takes = clazz.enrollment.courseTakers?sort_by(["std","code"])/]
  [#assign takeLists = takes?chunk((takes?size+2)/3)]
  [@b.card_body style="padding-top: 0px;"]
    [#include "gradeState.ftl"/]
    <div class="row" style="margin-top:10px">
      <div class="col-md-12">
      <table class="table table-hover table-sm table-striped" style="border:1px solid #c6ccd2;">
        <thead>
          <th class="idx_td">序号</th>
          <th>学号</th>
          <th>姓名</th>
          [#list gradeTypes as gradeType]
          <th>${gradeType.name}</th>
          [/#list]
          <th class="idx_td">序号</th>
          <th>学号</th>
          <th>姓名</th>
          [#list gradeTypes as gradeType]
          <th>${gradeType.name}</th>
          [/#list]
          <th class="idx_td">序号</th>
          <th>学号</th>
          <th>姓名</th>
          [#list gradeTypes as gradeType]
          <th>${gradeType.name}</th>
          [/#list]
        </thead>
        <tbody>
      [#if takes?size>0]
      [#assign firstColSize=takeLists?first?size/]
      [#list 1..firstColSize as i]
        <tr>
          <td class="idx_td">${i}</td>
          <td>${takeLists[0][i-1].std.code}</td>
          <td>[@displayCourseTaker takeLists[0][i-1]/]</td>
          [@displayGrade gradeMap.get(takeLists[0][i-1].std)!/]

          <td class="idx_td">${firstColSize+i}</td>
          <td>${takeLists[1][i-1].std.code}</td>
          <td>[@displayCourseTaker takeLists[1][i-1]/]</td>
          [@displayGrade gradeMap.get(takeLists[1][i-1].std)!/]

          [#if takeLists[2][i-1]??]
          <td class="idx_td">${firstColSize*2+i}</td>
          <td>${takeLists[2][i-1].std.code}</td>
          <td>[@displayCourseTaker takeLists[2][i-1]/]</td>
          [@displayGrade gradeMap.get(takeLists[2][i-1].std)!/]
          [#else]
          <td class="idx_td"></td><td></td><td></td>[#list gradeTypes as g]<td></td>[/#list]
          [/#if]
        </tr>
      [/#list]
      [/#if]
        </tbody>
      </table>
      </div>
    </div>
  [/@]
</div>
[@b.foot/]
