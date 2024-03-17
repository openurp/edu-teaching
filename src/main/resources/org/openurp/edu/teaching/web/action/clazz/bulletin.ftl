  [@b.card class="card-primary card-outline"]
    [@b.card_header]
      <h3 class="card-title"><i class="fa-sharp fa-solid fa-chalkboard"></i> 公告栏</h3>
      [@b.card_tools]
        [@b.a href="!editBulletin?clazz.id="+clazz.id]
           <i class="fa fa-edit"></i>填写
        [/@]
        [#if bulletin??]
          [@b.a href="!removeBulletin?clazz.id="+clazz.id onclick="return bg.Go(this,null,'确定删除?')" title="删除通知"]
            <i class="fa-solid fa-trash-can"></i>删除
          [/@]
        [/#if]
      [/@]
    [/@]
    [@b.card_body style="padding: 0px 20px;"]
       [@b.div id="editPlan"]
       [#if bulletin??]
        <p class="card-text">${bulletin.contents}</p>
        <p class="card-text">
          [#if bulletin.contactQrcodePath??]日常沟通：${bulletin.contactQrcodePath}[/#if]
          [#if bulletin.communicationQrcodePath??]
            <image class="scalable_img" src="${b.url('!download?bulletin.id='+bulletin.id)}" width="40px"/>
            [@b.a href="!download?bulletin.id="+bulletin.id target="_blank"]<i class="fa-solid fa-paperclip"></i>[/@]
          [/#if]
        </p>
        [#else]尚未填写[/#if]
       [/@]
    [/@]
  [/@]
