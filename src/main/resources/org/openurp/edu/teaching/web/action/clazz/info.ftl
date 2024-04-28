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
  [@b.card class="card card-info card-outline"]
    [@b.card_header]
      <h3 class="card-title"><i class="fa-solid fa-circle-info"></i> 基本信息(${clazz.semester.schoolYear}学年${clazz.semester.name}学期 ${clazz.crn})</h3>
    [/@]
    [@b.card_body style="padding-top: 0px;"]
      <table class="table table-sm" style="width:100%">
        <tr>
          <td class="title" width="10%">课程代码:</td>
          <td class="content" width="23%">${clazz.course.code}</td>
          <td class="title" width="10%">课程名称:</td>
          <td class="content"  width="24%">${clazz.course.name}</td>
          <td class="title" width="10%">副标题:</td>
          <td class="content" width="23%">${clazz.subject!}</td>
        </tr>
        <tr>
          <td class="title" >学分:</td>
          <td class="content" >${clazz.course.creditsInfo} </td>
          <td class="title" >课程英文名:</td>
          <td class="content">${clazz.course.enName!'--'}</td>
          <td class="title" >开课院系:</td>
          <td class="content">${clazz.teachDepart.name}</td>
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
      </table>
    [/@]
  [/@]

  [@b.card class="card card-info card-outline"]
    [@b.card_header]
      <h3 class="card-title"><i class="fa-solid fa-users"></i> 授课对象</h3>
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
          <td colspan="5">
            <table style="width:100%">
              [#list clazz.enrollment.restrictions as limitGroup]
              <tr>
                <td rowSpan="${limitGroup.items?size+1}" style="width:40px" align="center">${limitGroup_index+1}</td>
                <td style="width:20%">人数上限</td>
                <td>${limitGroup.maxCount}</td>
              </tr>
                [#list limitGroup.items as limitItem]
                <tr>
                  <td>${limitItem.meta.title} [#if !limitItem.included]不包括[/#if]</td>
                  <td id="limitItem${limitItem.id}_contents"></td>
                </tr>
                [/#list]
              [/#list]
            </table>
          </td>
        </tr>
      </table>
    [/@]
  [/@]

  [@b.card class="card card-info card-outline"]
    [@b.card_header]
      <h3 class="card-title"><i class="fa-solid fa-calendar-days"></i> 排课信息</h3>
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
      </table>
    [/@]
  [/@]

  [#if material??]
  [@b.card class="card card-info card-outline"]
    [@b.card_header]
      <h3 class="card-title"><i class="fa-solid fa-book"></i> 教材信息</h3>
    [/@]
    [@b.card_body style="padding-top: 0px;"]
      <table class="table table-sm" style="width:100%">
        <tr>
          <td class="title" width="10%">教材选用类型:</td>
          <td class="content">${(material.adoption.title)!}</td>
        </tr>
        <tr>
          <td class="title" width="10%">教材:</td>
          <td class="content">
            [#list material.books as b]
              ${b.name} ${(b.press.name)!} ISBN:${b.isbn} 作者：${b.author!} 版次：${b.edition} 出版年月：${b.publishedOn?string("yyyy-MM")}[#if b_has_next]<br>[/#if]
            [/#list]
          </td>
        </tr>
        <tr>
          <td class="title" width="10%">参考书目:</td>
          <td class="content">
            ${material.bibliography!}
          </td>
        </tr>
        <tr>
          <td class="title" width="10%">其他教学资源:</td>
          <td class="content">
            ${material.materials!}
          </td>
        </tr>
      </table>
    [/@]
  [/@]
  [/#if]

  [#if syllabusDocs?size>0]
  <div class="card card-info card-outline">
    <div class="card-header">
      <p class="card-title"><i class="fa-solid fa-list"></i> 教学大纲</p>
    </div>
      <table class="table  table-sm">
      [#list syllabusDocs as doc]
      <tr style="text-align:center">
        <td>${doc.writer.name}</td>
        <td>${doc.semester.schoolYear} 学年 ${doc.semester.name} 学期</td>
        <td class="text-muted">${doc.updatedAt?string("yyyy-MM-dd HH:mm")}</td>
        <td>[@b.a href="/edu/course/profile/info/attachment?doc.id="+doc.id target="_blank"]<span class="text-muted">${doc.docSize/1024.0}K</span><i class="fa-solid fa-paperclip"></i>下载&nbsp;[/@]</td>
      </tr>
      [/#list]
    </table>
  </div>
  [/#if]

  <script>
    jQuery(function(){
    [#list clazz.enrollment.restrictions as limitGroup]
      [#list limitGroup.items as limitItem]
      jQuery.post("${b.url("!getLimitDatas")}",{queryType:"byContent",metaId:"${limitItem.meta.id}",content:"${limitItem.contents!}"},function(res){
        var json = jQuery.parseJSON(res);
        var html = "";
        for(var key in json){
          html+=json[key]+" ";
        }
        jQuery("#limitItem${limitItem.id}_contents").html(html);
      });
      [/#list]
    [/#list]
    });
  </script>
</div>
[@b.foot/]
