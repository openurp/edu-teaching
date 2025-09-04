[@b.card class="card-primary card-outline"]
  [@b.card_header]
    <h3 class="card-title">
      <i class="fa-solid fa-list mr-1"></i> 学生名单<span class="badge badge-success">${clazz.enrollment.courseTakers?size}</span>
    </h3>
    [@b.card_tools]
       <a href="#" class="btn btn-sm" title="下载考勤表"></a>
       [@b.a href="!rollbook?excel=1&clazz.id="+clazz.id target="_blank" title="下载考勤表"]<i class="fa-solid fa-file-excel"></i>下载[/@]
       &nbsp;
       [@b.a href="!rollbook?clazz.id="+clazz.id target="_blank" title="打印预览考勤表"]<i class="fa-solid fa-print"></i>打印[/@]
    [/@]
  [/@]

  [@b.card_body style="padding-top: 0px;max-height: 500px;overflow: scroll;"]
    <table class="table table-hover table-sm table-striped" style="font-size: 13px;">
      <thead>
        <th width="30px">#</th>
        <th width="12%">学号</th>
        <th width="13%">姓名</th>
        [#if tutorSupported]<th width="10%">导师</th>[/#if]
        <th width="20%">院系</th>
        <th>专业</th>
      </thead>
      <tbody>
      [#list clazz.enrollment.courseTakers?sort_by(["std","code"]) as taker]
        <tr>
          <td>${taker_index+1}</td>
          <td>${taker.std.code}</td>
          <td>${taker.std.name}[#if taker.takeType.id != 1]<sup style="color:red">${taker.takeType.name}</sup>[/#if]</td>
          [#if tutorSupported]<td>${(taker.std.majorTutorNames)!}</td>[/#if]
          <td>${taker.std.state.department.name}</td>
          <td>${(taker.std.state.major.name)!} ${(taker.std.state.direction.name)!}</td>
        </tr>
      [/#list]
      </tbody>
    </table>
  [/@]
[/@]
