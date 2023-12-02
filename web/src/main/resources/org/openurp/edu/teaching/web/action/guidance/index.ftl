[@b.head/]
<style>
@media only screen and  (max-width: 760px) {
  .pc-tips{display: none; }
  td, tr { display: block; }
  /* Hide table headers (but not display: none;, for accessibility) */
  thead tr {
    position: absolute;
    top: -9999px;
    left: -9999px;
  }
  tr + tr { margin-top: 1.5em; }
  td {
    /* make like a "row" */
    border: none;
    border-bottom: 1px solid #eee;
    position: relative;
    padding-left: 50%;
    text-align: left;
  }
  td:before {
    content: attr(data-label);
    display: inline-block;
    width: 30%;
    white-space: nowrap;
  }
}
</style>
<div class="container-fluid">
  [@b.toolbar title="${semester.schoolYear}学年度${semester.name}学期 主课及学位论文指导成绩"/]
  [@b.messages slash="3"/]
  [@base.semester_bar value=semester! formName='courseTableForm'/]

  <div class="card card-info card-primary card-outline text-sm">
    <div class="card-header">
      <h3 class="card-title">${teacher.name}的学生和课程
        <span class="badge badge-primary">${stds?size}</span>
      </h3>
      [@b.card_tools]
        <span class="text-muted pc-tips">每个课程支持Tab或者回车键，纵向依次录入</span>
        <button type="button" class="btn btn-sm btn-primary" onclick="bg.form.submit(document.gradeForm)">
          <i class="fas fa-save"></i>保存
        </button>
      [/@]
    </div>
    <div>
     [@b.form name="gradeForm" action="!save"]
     <input type="hidden" name="semester.id" value="${semester.id}"/>
     <input type="hidden" name="project.id" value="${project.id}"/>
     <table class="table table-hover table-sm table-striped" style="text-align:center">
       <thead>
         <th>序号</th><th>年级</th><th>学号</th><th>姓名</th><th>专业</th><th>专业方向</th>
         [#list groups as group]<th>${group.name}</th>[/#list]
       </thead>
       <tbody>
       [#list stds as std]
         <tr>
           <td data-label="序号">${std_index+1}</td>
           <td data-label="年级">${std.state.grade.code}</td>
           <td data-label="学号">${std.code}</td>
           <td data-label="姓名">${std.name}</td>
           <td data-label="专业">${(std.state.major.name)!}</td>
           <td data-label="专业方向">${(std.state.direction.name)!}</td>
           [#list groups as group]
           <td data-label="${group.name}">
             [#assign term=stdGroupTerms["${std.id}_${group.name}"]!0/]
             [#if term>0]
              [#if group.matched(std,teacher)]
             [#assign course =group.getCourse(term?int)/]
             [#assign tabIndex=(std_index+1)+group_index*stds?size/]
             <input name="${std.id}_${course.id}.score" value="${(gradeMap.get(course).get(std).score)!}" placeholder="第${term}学期 ${course.name}" tabIndex="${tabIndex}">
              [#else]
              [#if ((std.tutor.name)!'') != teacher.name]导师 ${(std.tutor.name)!}[/#if][#if ((std.advisor.name)!'') != teacher.name]论文导师 ${(std.advisor.name)!}[/#if]
              [/#if]
             [/#if]
           </td>
           [/#list]
         </tr>
       [/#list]
       </tbody>
     </table>
     [/@]
    </div>
  </div>
<script>
    jQuery(document).ready(function(){
      var form = document.gradeForm
      var onReturn = new beangle.ui.onreturn(document.gradeForm);
      [#list courses as course]
      [#list stds as std]
      if(form['${std.id}_${course.id}.score']){
        onReturn.add('${std.id}_${course.id}.score');
      }
      [/#list]
      [/#list]
      form.onkeypress=function(){onReturn.focus(event);}
    });
</script>
</div>
[@b.foot/]
