[#ftl]
[@b.head/]
<div class="container">
  [@b.toolbar title="教学任务信息"]
    bar.addClose();
  [/@]
  <style>
    .title{
      padding-right: 2px;
      text-align: right;
    }
  </style>
  <div style="text-align: center;">
    <h5>${clazz.project.school.name}教学任务信息(序号${clazz.crn})</h5>
  </div>
  [@b.card class="card card-info card-outline"]
    [@b.card_header style="padding: 0.5rem 1.25rem;"]
      <h3 class="card-title"><i class="fa-solid fa-circle-info"></i> 基本信息(${clazz.semester.schoolYear}学年${clazz.semester.name}学期 ${clazz.crn})</h3>
    [/@]
    [@b.card_body style="padding-top: 0px;"]
      <table class="table table-sm" style="width:100%">
        <tr>
          <td class="title" width="10%">课程代码:</td>
          <td class="content" width="23%">${clazz.course.code}</td>
          <td class="title" width="10%">课程名称:</td>
          <td class="content"  width="24%"><a href="/edu/course/profile/info/"+clazz.course.id target="_blank">${clazz.course.name}[#if clazz.subject??]--${clazz.subject}[/#if]</a></td>
          <td class="title" width="10%">开课院系:</td>
          <td class="content" width="23%">${clazz.teachDepart.name}</td>
        </tr>
        <tr>
          <td class="title" >学分:</td>
          <td class="content" >${clazz.course.creditsInfo} </td>
          <td class="title" >课程英文名:</td>
          <td class="content" colspan="3">${clazz.course.enName!'--'}</td>
        </tr>
        <tr>
          <td class="title">课程类别:</td>
          <td class="content">${clazz.courseType.name}</td>
          <td class="title">校区:</td>
          <td class="content">${clazz.campus.name}</td>
          <td class="title">考核方式:</td>
          <td class="content">${(clazz.examMode.name)!}</td>
        </tr>
        <tr>
          <td class="title">授课语言:</td>
          <td class="content">${clazz.langType.name}</td>
          <td class="title">任课教师:</td>
          <td class="content">[#list clazz.teachers as teacher]${teacher.name}[#sep]&nbsp;[/#list]</td>
          <td class="title">课程标签:</td>
          <td class="content">[#list clazz.tags as tag]${tag.name}[#sep]&nbsp;[/#list]</td>
        </tr>
        <tr>
         <td class="title">教材选用类型:</td>
         <td class="content">[#if material??]${(material.adoption.title)!}[/#if]</td>
         <td class="title">教学大纲</td>
         <td class="content" colspan="3">
          [#list syllabusDocs as doc]
           <span class="text-muted"> ${doc.writer.name} ${doc.updatedAt?string("yyyy-MM-dd")}</span>
          [@b.a href="/edu/course/profile/info/attachment?doc.id="+doc.id target="_blank"]<span class="text-muted">${doc.docSize/1024.0}K</span><i class="fa-solid fa-paperclip"></i>下载&nbsp;[/@]
          [#if doc_has_next]<br>[/#if]
          [/#list]
          </td>
        </tr>
        [#if material?? && material.books?size>0]
        <tr>
          <td class="title">教材:</td>
          <td class="content" colspan="5">
            [#list material.books as b]
              ${b.name} ${(b.press.name)!} ISBN:${b.isbn} 作者：${b.author!} 版次：${b.edition} 出版年月：${b.publishedOn?string("yyyy-MM")}[#if b_has_next]<br>[/#if]
            [/#list]
          </td>
        </tr>
        [/#if]
        [#if (material.bibliography)??]
        <tr>
          <td class="title">参考书目:</td>
          <td class="content" colspan="5">
            ${material.bibliography!}
          </td>
        </tr>
        [/#if]
        [#if (material.bibliography)??]
        <tr>
          <td class="title">其他教学资源:</td>
          <td class="content" colspan="5">
            ${material.materials!}
          </td>
        </tr>
        [/#if]
      </table>
    [/@]
  [/@]

  [@b.card class="card card-info card-outline"]
    [@b.card_header style="padding: 0.5rem 1.25rem;"]
      <h3 class="card-title"><i class="fa-solid fa-calendar-days"></i> 排课与考试信息</h3>
    [/@]
    [@b.card_body style="padding-top: 0px;"]
      <table class="table table-sm" style="width:100%">
        <tr>
          <td class="title" width="10%">总课时:</td>
          <td class="content" width="23%">${(clazz.schedule.creditHours)!}</td>
          <td class="title" width="10%">周课时:</td>
          <td class="content" width="24%">${clazz.schedule.weekHours?string('#.##')}</td>
          <td class="title" width="10%">起止周:</td>
          <td class="content" width="23%">${(clazz.schedule.firstWeek)!}~${(clazz.schedule.lastWeek)!}</td>
        </tr>
        <tr>
          <td class="title">首次上课:</td>
          <td class="content">[#if schedule??]${(clazz.schedule.firstDateTime?string('yyyy-MM-dd HH:mm'))!}[/#if]</td>
          <td class="title">课程安排:</td>
          <td class="content">${schedule!'--'}</td>
          <td class="title">上课教室:</td>
          <td class="content">${rooms!"--"}</td>
        </tr>
        [#if examActivities?size>0]
        [#list examActivities as ea]
        [#if ea.publishState.timePublished]
        <tr>
          <td class="title">${ea.examType.name}:</td>
          <td class="content">${ea.examOn?string("yyyy-MM-dd")} ${ea.beginAt}</td>
          <td class="title">人数:</td>
          <td class="content">${ea.stdCount}</td>
          <td class="title">考试教室:</td>
          <td class="content">[#if ea.publishState.timePublished][#list ea.rooms as er]${er.room.name}[#sep]&nbsp;[/#list][/#if]</td>
        </tr>
        [/#if]
        [/#list]
        [/#if]
      </table>
    [/@]
  [/@]

  [@b.card class="card card-info card-outline"]
    [@b.card_header style="padding: 0.5rem 1.25rem;"]
      <h3 class="card-title"><i class="fa-solid fa-users"></i> 教学班</h3>
      [#if clazz.enrollment.abilityRates?size>0]
      <span class="text-muted ml-2 text-sm">[#list clazz.enrollment.abilityRates as r]${r.name}[#sep]&nbsp;[/#list]</span>
      [/#if]
      <div class="card-tools">
        [@b.a href="clazz!rollbook?clazz.id="+clazz.id target="_blank"]点名册[/@]
      </div>
    [/@]
    [@b.card_body style="padding-top: 0px;"]
      <table class="table table-sm" style="width:100%">
        <tr>
          <td class="title" width="10%">年级:</td>
          <td class="content"  width="23%">${clazz.enrollment.grades!}</td>
          <td class="title" width="10%">人数上限:</td>
          <td class="content"  width="24%">${clazz.enrollment.capacity}</td>
          <td class="title" width="10%">实际人数:</td>
          <td class="content"  width="24%">${clazz.enrollment.stdCount}</td>
        </tr>
        <tr>
          <td class="title">授课对象:</td>
          <td colspan="5">${clazz.clazzName}</td>
        </tr>
      </table>
      [#macro displayCourseTaker(taker)]
        ${taker.std.name}[#if taker.takeType.id != 1]<sup style="color:red">${taker.takeType.name}</sup>[/#if]
      [/#macro]
      [#if clazz.enrollment.courseTakers?size>0]
      [#assign takers = clazz.enrollment.courseTakers?sort_by(["std","code"])/]
      [#assign takeLists = takers?chunk((takers?size+2)/3)]
      <table class="table table-sm">
        <thead>
          <th class="idx_td">序号</th>
          <th>学号</th>
          <th>姓名</th>
          <th class="idx_td">序号</th>
          <th>学号</th>
          <th>姓名</th>
          <th class="idx_td">序号</th>
          <th>学号</th>
          <th>姓名</th>
        </thead>
        <tbody>
      [#assign firstColSize=takeLists?first?size/]
      [#list 1..firstColSize as i]
        <tr>
          <td class="idx_td">${i}</td>
          <td>${takeLists[0][i-1].std.code}</td>
          <td>[@displayCourseTaker takeLists[0][i-1]/]</td>
          <td class="idx_td">${firstColSize+i}</td>
          <td>${takeLists[1][i-1].std.code}</td>
          <td>[@displayCourseTaker takeLists[1][i-1]/]</td>
          [#if  takeLists[2]?? && takeLists[2][i-1]??]
          <td class="idx_td">${firstColSize*2+i}</td>
          <td>${takeLists[2][i-1].std.code}</td>
          <td>[@displayCourseTaker takeLists[2][i-1]/]</td>
          [#else]
          <td class="idx_td"></td><td></td><td></td>
          [/#if]
        </tr>
      [/#list]
        </tbody>
      </table>
      [/#if]
    [/@]
  [/@]
</div>
[@b.foot/]
