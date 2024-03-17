[#ftl]
[#if projects?size>1]
<ul class="nav">
  [#list projects as p]
  <li class="nav-item">
    <a class="nav-link [#if p.id=project.id]active[/#if]" [#if p.id=project.id]href="javascript:void(0);"[#else] onclick="return bg.Go(this,null)" href="${b.url('!index?projectId=${p.id}')}"[/#if]>${p.name}</a>
  </li>
  [/#list]
</ul>
[/#if]
