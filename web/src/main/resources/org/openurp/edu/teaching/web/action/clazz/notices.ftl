  [@b.card class="card-primary card-outline" style="margin-bottom: 0px;"]
    [@b.card_header]
       <h3 class="card-title">
         <i class="fa-solid fa-bullhorn"></i> 通知
       </h3>
       [@b.card_tools]
          <a title="新拟通知" data-toggle="collapse" href="#newNotice" role="button" aria-expanded="false"
             aria-controls="newNotice">
             <i class="fa fa-edit"></i>新拟
          </a>
       [/@]
    [/@]
    [@b.card_body style="padding:0px"]
      [#assign defaultCollapse="collapse"/]
      [#if notices?size==0][#assign defaultCollapse="collapse show"/][/#if]
      [@b.form action="!saveNotice" theme="list" name="newNotice" class=defaultCollapse]
         [@b.textfield name="notice.title" maxlength="300" style="width:80%" label="标题" comment="300字以内"/]
         [@b.textarea name="notice.contents" maxlength="1000" style="width:80%" rows="5" label="内容" comment="1000字以内"/]
         [@b.file label="附件1" placeholder="上传图片或文件" name="attachment" class="custom-file-input" maxSize="50M" /]
         [@b.file label="附件2" placeholder="上传图片或文件" name="attachment" class="custom-file-input" maxSize="50M" /]
         [@b.formfoot]
            <input name="notice.clazz.id" value="${clazzId}" type="hidden"/>
            [@b.submit value="action.submit"/]
         [/@]
      [/@]
    [/@]
  [/@]
  <style>
    .scalable_img{
       transition: all 0.2s linear;
    }
   .scalable_img:hover{
     transform:scale(3.0);
     transition: all 0.2s linear;
     z-index:200;
    }
  </style>
  [#list notices?sort_by("updatedAt")?reverse as notice]
    <div class="card">
      <div class="card-header" style="padding-bottom: 0px;">
        ${notice.title}&nbsp;<span style="font-size:0.8rem;color: #999;">${notice.updatedAt?string("yy-MM-dd HH:mm")}</span>
        [@b.card_tools]
         [@b.a href="!removeNotice?notice.id="+notice.id onclick="if(confirm('确定删除?')){return bg.Go(this,null)}else{return false;}" class="btn btn-danger btn-sm" title="删除通知"]
         <i class="fa-solid fa-trash-can"></i>
         [/@]
        [/@]
      </div>
      <div class="card-body" style="padding-top: 5px;">
         <p class="card-text">${notice.contents}</p>
         [#if notice.files?size>0]
           [#list notice.files as f]
             附件：
             [#if f.mediaType?starts_with("image")]<image class="scalable_img" src="${b.url('!download?noticeFile.id='+f.id)}" width="40px"/>[/#if]
             [@b.a href="!download?noticeFile.id="+f.id target="_blank"]<i class="fa-solid fa-paperclip"></i> ${f.name}[/@]
           [/#list]
         [/#if]
      </div>
    </div>
  [/#list]
