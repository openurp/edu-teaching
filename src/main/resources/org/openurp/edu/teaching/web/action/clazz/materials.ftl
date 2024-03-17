[@b.card class="card-primary card-outline"]
  [@b.card_header]
    <h3 class="card-title">
      <i class="fa-solid fa-paperclip"></i> 课内资料和附件<span class="badge badge-success">${materials?size}</span>
    </h3>
    [@b.card_tools]
      <a title="新增" data-toggle="collapse" href="#newMaterial" role="button" aria-expanded="false"
         aria-controls="newMaterial">
         <i class="fa fa-edit"></i>新增
      </a>
    [/@]
  [/@]

  [@b.card_body]
    [@b.form action="!saveMaterial" theme="list" name="newMaterial"  class="collapse"]
      [@b.textfield label="名称" name="material.name" required="true"/]
      [@b.textfield label="网址" name="material.url" /]
      [@b.file label="或附件" placeholder="上传文件" name="attachment" class="custom-file-input" maxSize="50M" /]
      [@b.formfoot]
        <input name="material.clazz.id" value="${clazzId}" type="hidden"/>
        [@b.submit value="action.submit"/]
      [/@]
    [/@]
    <ul style="padding:0px">
     [#list materials?sort_by(["updatedAt"])?reverse as material]
      <li>
        [#if material.filePath??]
          [@b.a href="!download?material.id="+material.id target="_blank"]${material.name} <i class="fa-solid fa-paperclip"></i>[/@]
        [#else]
          <a href="${material.url!}" target="_blank">${material.name}</a>
        [/#if]
         <span class="text-sm text-muted">${material.updatedAt?string("MM-dd HH:mm")}</span>
        [@b.a href="!removeMaterial?material.id="+material.id onclick="if(confirm('确定删除?')){return bg.Go(this,null)}else{return false;}" title="删除"]<i class="fa-solid fa-xmark"></i>[/@]
      </li>
     [/#list]
    </ul>
  [/@]
[/@]
