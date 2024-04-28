[@b.card class="card-primary card-outline"]
  [@b.card_header]
    <h3 class="card-title">
      <i class="fa-solid fa-paperclip"></i> 课内资料和附件<span class="badge badge-success">${docs?size}</span>
    </h3>
    [@b.card_tools]
      <a title="新增" data-toggle="collapse" href="#newDoc" role="button" aria-expanded="false"
         aria-controls="newDoc">
         <i class="fa fa-edit"></i>新增
      </a>
    [/@]
  [/@]

  [@b.card_body]
    [@b.form action="!saveDoc" theme="list" name="newDoc"  class="collapse"]
      [@b.textfield label="名称" name="doc.name" required="true"/]
      [@b.textfield label="网址" name="doc.url" /]
      [@b.file label="或附件" placeholder="上传文件" name="attachment" class="custom-file-input" maxSize="50M" /]
      [@b.formfoot]
        <input name="doc.clazz.id" value="${clazzId}" type="hidden"/>
        [@b.submit value="action.submit"/]
      [/@]
    [/@]
    <ul style="padding:0px">
     [#list docs?sort_by(["updatedAt"])?reverse as doc]
      <li>
        [#if doc.filePath??]
          [@b.a href="!download?doc.id="+doc.id target="_blank"]${doc.name} <i class="fa-solid fa-paperclip"></i>[/@]
        [#else]
          <a href="${doc.url!}" target="_blank">${doc.name}</a>
        [/#if]
         <span class="text-sm text-muted">${doc.updatedAt?string("MM-dd HH:mm")}</span>
        [@b.a href="!removeDoc?doc.id="+doc.id onclick="if(confirm('确定删除?')){return bg.Go(this,null)}else{return false;}" title="删除"]<i class="fa-solid fa-xmark"></i>[/@]
      </li>
     [/#list]
    </ul>
  [/@]
[/@]
