
  [@b.card class="card-primary card-outline"]
    [@b.card_header]
      <h3 class="card-title"><i class="fa-regular fa-calendar-days"></i> 授课计划</h3>
      [@b.card_tools]
        <button class="btn btn-sm btn-primary" onclick="bg.form.submit('teachingPlanForm')"><i class="fa fa-save"></i>保存</button>
      [/@]
    [/@]
    [@b.card_body]
      [@b.form name="teachingPlanForm" action="!saveTeachingPlan?clazz.id="+clazz.id style="text-align:justify;"]
        [@b.field label="统一设置"]
          <input name="allPlaces" value="" placeholder="腾讯会议号、网课链接" style="width:70%" oninput="updatePlaces(this.value)"/>
        [/@]
        [#list plan.lessons?sort_by("idx") as lesson]
          [@b.field label="#"+(lesson_index+1)+" "+ lesson.openOn?string('MM-dd')]
            <input class="lesson_contents" name="lesson${lesson.id}.places" value="${lesson.places!}" placeholder="腾讯会议、网课链接" style="width:70%"/>
            [#if lesson.contents==' '][#assign contents=""/][#else][#assign contents=lesson.contents/][/#if]
            <input name="lesson${lesson.id}.contents" value="${contents}" placeholder="上课内容、主题" style="width:100%">
          [/@]
        [/#list]
        [@b.submit value="保存"/]
      [/@]
    [/@]
  [/@]
  <script>
    function updatePlaces(v){
       jQuery(".lesson_contents").each(function(i,e){
          jQuery(e).val(v);
       });
    }
  </script>
