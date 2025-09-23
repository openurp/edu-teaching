[#ftl]
[@b.head/]
<div class="container">
  [@b.toolbar title="主课安排查询"]
    bar.addItem("返回",function(){
       bg.form.submit(document.searchForm,"${b.url("!index")}");
    },"action-backward");
  [/@]
  <div style="background-color: #cfe2ff;color: #052c65;border: 1px solid #9ec5fe;padding: 1px 1px 1px 1px;height: 30px;">
    <i class="fa-solid fa-circle-info"></i> 按照学号或姓名查找已经安排主课的学生
  </div>
  [@b.form name="searchForm" action="!search"]
    <div class="input-group input-group-sm">
      <input class="form-control form-control-navbar" type="search" name="stdCodeName" value="${Parameters['stdCodeName']!}"
       aria-label="Search" placeholder="学号或姓名" autofocus="autofocus">
      [#list Parameters?keys as k]
       [#if k != 'stdCodeName' && k != 'pageIndex']
      <input type="hidden" name="${k}" value="${Parameters[k]?html}"/>
      [/#if]
      [/#list]
      <div class="input-group-append">
        <button class="input-group-text" type="submit" onclick="bg.form.submit(document.searchForm);return false;">
          <i class="fas fa-search"></i>
        </button>
      </div>
    </div>
  [/@]
  [#assign weekdays = ["","周一","周二","周三","周四","周五","周六","周日"] /]
  [#if clazzes?size>0]
    [#list clazzes as clazz]
      [#assign std = clazz.stds?first /]
      [#include "mini-list-card.ftl"/]
    [/#list]
  [#else]
    <p>没有找到符合条件的专业主课的上课安排</p>
  [/#if]
  <nav aria-label="Page navigation example">
   <ul class="pagination float-right">
     [#if clazzes.pageIndex > 1]
     <li class="page-item"><a class="page-link" href="#" onclick="return listClazz(1)">首页</a></li>
     <li class="page-item"><a class="page-link" href="#" onclick="return listClazz(${clazzes.pageIndex-1})">${clazzes.pageIndex-1}</a></li>
     [/#if]
     <li class="page-item active"><a class="page-link" href="javascript:void(0)">${clazzes.pageIndex}</a></li>
     [#if clazzes.pageIndex < clazzes.totalPages]
     <li class="page-item"><a class="page-link" href="#" onclick="return listClazz(${clazzes.pageIndex+1})">${clazzes.pageIndex+1}</a></li>
     <li class="page-item"><a class="page-link" href="#" onclick="return listClazz(${clazzes.totalPages})">末页</a></li>
     [/#if]
   </ul>
  </nav>
  <script>
   function listClazz(pageIndex){
      bg.form.addInput(document.searchForm,"pageIndex",pageIndex);
      bg.form.submit(document.searchForm);
      return false;
   }
  </script>
</div>

[@b.foot/]
