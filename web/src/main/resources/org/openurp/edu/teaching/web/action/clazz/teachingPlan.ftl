  [@b.card class="card-primary card-outline"]
    [@b.card_header]
      <h3 class="card-title"><i class="fa-regular fa-calendar-days"></i> 授课计划</h3>
      [@b.card_tools]
        [@b.a title="填写"  href="!editTeachingPlan?clazz.id="+clazz.id]
           <i class="fa fa-edit"></i>填写
        [/@]
        [#if plan??]
          [@b.a href="!removeTeachingPlan?clazz.id="+clazz.id onclick="return bg.Go(this,null,'确定删除?')" title="删除授课计划"]
            <i class="fa-solid fa-trash-can"></i>删除
          [/@]
        [/#if]
      [/@]
    [/@]
    [@b.card_body style="padding: 0px 20px;"]
       [@b.div id="editPlan"]
       [#if plan??]
       [#assign now=b.now?string("yyyyMMdd")?number/]
        <ul style="padding-left: 10px;">
          [#list plan.lessons?sort_by("idx") as lesson]
            <li [#if lesson.openOn?string("yyyyMMdd")?number<now]class="text-muted"[/#if]>${lesson.openOn?string("MM-dd")} ${lesson.places!} [#if lesson.contents?length>2]<br>[/#if]${lesson.contents!}</li>
          [/#list]
        </ul>
        [#else]尚未填写[/#if]
       [/@]
    [/@]
  [/@]
