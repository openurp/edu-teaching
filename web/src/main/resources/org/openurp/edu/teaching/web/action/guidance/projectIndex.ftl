[#ftl]
[@b.head/]
<div class="container-fluid">
  [@b.toolbar title="每学期主课成绩"/]
  [@b.messages slash="3"/]
  [@base.semester_bar value=semester! formName='courseTableForm'/]

  <div class="card card-info card-primary card-outline">
    <div class="card-header">
      <h3 class="card-title">学生和课程
        <span class="badge badge-primary">${stds?size}</span>
      </h3>
      [@b.card_tools]
        <span class="text-muted">每个课程支持Tab或者回车键，纵向依次录入</span>
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
         [#list courses as course]<th>${course.name}</th>[/#list]
       </thead>
       <tbody>
       [#list stds as std]
         <tr>
           <td>${std_index+1}</td>
           <td>${std.state.grade.code}</td>
           <td>${std.code}</td>
           <td>${std.name}</td>
           <td>${(std.state.major.name)!}</td>
           <td>${(std.state.direction.name)!}</td>
           [#list courses as course]
           <td style="width:120px">
             [#if stdCourseTerms["${std.id}_${course.id}"]??]
             [#assign tabIndex=(std_index+1)+course_index*stds?size/]
             <input name="${std.id}_${course.id}.score" value="${(gradeMap.get(course).get(std).score)!}" style="width:100%" placeholder="第${stdCourseTerms["${std.id}_${course.id}"]}学期成绩" tabIndex="${tabIndex}">
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

  <script type="text/javascript" crossorigin="anonymous"   src="${b.static_url('bui',"js/OnReturn.js")}"></script>
  <script>
    jQuery(document).ready(function(){
      var form = document.gradeForm
      var onReturn = new OnReturn(document.gradeForm);
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
