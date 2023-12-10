[#ftl/]
[@b.head /]
<div class="container-fluid">
  [@b.toolbar title="考试安排"/]
  [@base.semester_bar name="semester.id" value=semester/]

  [#list examDutyMap?keys as examType]

  [@b.card class="card-primary card-outline"]
    [@b.card_header]
      <h3 class="card-title"><i class="fa-sharp fa-solid fa-chalkboard"></i> ${examType.name}</h3>
      [#assign examRoomIds][#list examDutyMap.get(examType) as duty]${duty.room.id}[#sep],[/#list][/#assign]
      [@b.card_tools]
        [@b.a title="所有签名表"  href="!signature?examRoomIds="+examRoomIds target="_blank"]
           <i class="fa fa-print"></i>所有签名表
        [/@]
        &nbsp;
        [@b.a title="所有试卷袋标签"  href="!label?examRoomIds="+examRoomIds target="_blank"]
           <i class="fa fa-print"></i>所有试卷袋标签
        [/@]
        &nbsp;
        [@b.a title="所有考场情况表"  href="!summary?examRoomIds="+examRoomIds target="_blank"]
           <i class="fa fa-print"></i>所有考场情况表
        [/@]
      [/@]
    [/@]

    [@b.card_body style="padding: 0px 20px;"]
      <table style="width:100%;" class="grid-table">
        <thead class="grid-head">
          <tr>
            <th style="width:6%">课程序号</th>
            <th>课程名称</th>
            <th style="width:10%">开课院系</th>
            <th style="width:20%">教学班</th>
            <th style="width:15%">考试时间</th>
            <th style="width:8%">考试地点</th>
            <th style="width:7%">职责</th>
            <th style="width:15%">操作</th>
          </tr>
        </thead>
        <tbody class="grid-body">
        [#list examDutyMap.get(examType) as duty]
          [#assign examRoom=duty.room/]
          [#assign clazzCount=0/]
          [#assign activities = duty.activities]
          [#list activities as activity]
        <tr>
          <td>${(activity.clazz.crn)!}</td>
          <td>${(activity.clazz.course.name)!}</td>
          <td>${(activity.clazz.teachDepart.shortName)!(activity.clazz.teachDepart.name)}</td>
          <td><div class="text-ellipsis">${(activity.clazz.clazzName)!}</div></td>
          [#if activity_index==0]
          <td rowspan="${activities?size}">[#if activity.publishState.timePublished]${(examRoom.examOn)?string('yyyy-MM-dd')!}&nbsp;&nbsp;${(examRoom.beginAt)!}~${(examRoom.endAt)!}[/#if]</td>
          <td rowspan="${activities?size}">[#if activity.publishState.roomPublished]${(examRoom.room.name)!}[/#if]</td>
          <td rowspan="${activities?size}">${duty.duty.name}</td>
          <td rowspan="${activities?size}">
            [#if activity.publishState.roomPublished]
              [@b.a target="_blank" href="!signature?examRoomIds=${examRoom.id}" title="打印签名表"]签名表[/@]
              [@b.a target="_blank" href="!label?examRoomIds=${examRoom.id}" title="试卷袋标签"]试卷袋标签[/@]
              [@b.a target="_blank" href="!summary?examRoomIds=${examRoom.id}" title="考场情况表"]考场情况表[/@]
            [/#if]
          </td>
          [/#if]
        </tr>
          [/#list]
        [/#list]
        </tbody>
      </table>
    [/@]
  [/@]

  [#if noticeMap.get(examType)??]<div class="callout callout-info">${noticeMap.get(examType).contents}</div>[/#if]

  [/#list]
</div>
[@b.foot/]
