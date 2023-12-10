[@b.card class="card-primary card-outline"]
  [@b.card_header]
    <h3 class="card-title"><i class="fa-regular fa-hand"></i> 学生请假情况<span class="badge badge-success">${stdLeaveStats?size}</span></h3>
  [/@]
  [@b.card_body style="padding-top: 0px;max-height: 300px;overflow: scroll;"]
      <table class="table table-hover table-sm table-striped" style="font-size: 13px;">
        <thead>
          <th width="30px">#</th>
          <th width="100px">学号</th>
          <th width="100px">姓名</th>
          <th width="50px">次数</th>
          <th>时间、类型</th>
        </thead>
        <tbody>
        [#list stdLeaveStats as stat]
          <tr>
            <td>${stat_index+1}</td>
            <td>${stat.std.code}</td>
            <td>${stat.std.name}</td>
            <td>${stat.leaves?size}</td>
            <td>[#list stat.leaves?sort_by("beginAt") as dayoff]
                <div style="display:inline-block" title="${dayoff.reason?html}">${dayoff.beginAt?string("yyyy-MM-dd")}${dayoff.dayoffType.name}</div>
                [#sep]&nbsp;[/#list]
            </td>
          </tr>
        [/#list]
        </tbody>
      </table>
  [/@]
[/@]
