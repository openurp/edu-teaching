<hr style="margin: 0px;">
  [@b.card_header]
    <h3 class="card-title">
      <i class="fa-solid fa-list mr-1"></i> 学生名单及成绩<span class="badge badge-success">${clazz.enrollment.courseTakers?size}</span>
    </h3>
    [@b.card_tools]
    [/@]
  [/@]
[#macro displayCourseTaker(taker)]
  ${taker.std.name}[#if taker.takeType.id != 1]<sup style="color:red">${taker.takeType.name}</sup>[/#if]
[/#macro]

  [#assign takes = clazz.enrollment.courseTakers?sort_by(["std","code"])/]
  [#assign takeLists = takes?chunk((takes?size+2)/3)]
  [@b.card_body style="padding-top: 0px;"]
    <table class="table table-hover table-sm table-striped">
      <thead>
        <th width="5%">序号</th>
        <th width="12%">学号</th>
        <th width="10%">姓名</th>
        <th width="6%">成绩</th>
        <th width="5%">序号</th>
        <th width="12%">学号</th>
        <th width="10%">姓名</th>
        <th width="6%">成绩</th>
        <th width="5%">序号</th>
        <th width="12%">学号</th>
        <th width="10%">姓名</th>
        <th width="7%">成绩</th>
      </thead>
      <tbody>
      [#if takes?size>0]
      [#assign firstColSize=takeLists?first?size/]
      [#list 1..firstColSize as i]
        <tr>
          <td>${i}</td>
          <td>${takeLists[0][i-1].std.code}</td>
          <td>[@displayCourseTaker takeLists[0][i-1]/]</td>
          <td>${(gradeMap.get(takeLists[0][i-1].std).scoreText)!}</td>

          <td>${firstColSize+i}</td>
          <td>${takeLists[1][i-1].std.code}</td>
          <td>[@displayCourseTaker takeLists[1][i-1]/]</td>
          <td>${(gradeMap.get(takeLists[1][i-1].std).scoreText)!}</td>

          [#if takeLists[2][i-1]??]
          <td>${firstColSize*2+i}</td>
          <td>${takeLists[2][i-1].std.code}</td>
          <td>[@displayCourseTaker takeLists[2][i-1]/]</td>
          <td>${(gradeMap.get(takeLists[2][i-1].std).scoreText)!}</td>
          [#else]
          <td></td><td></td><td></td><td></td>
          [/#if]
        </tr>
      [/#list]
      [/#if]
      </tbody>
    </table>
  [/@]
