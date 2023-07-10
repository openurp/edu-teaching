[#ftl]
[@b.head/]
<div class="container-fluid">
<script language="JavaScript" type="text/JavaScript" src="${b.base}/static/edu/TaskActivity.js?v=20230531"></script>
[@b.toolbar title="我的课程"/]
[@base.semester_bar value=semester! formName='courseTableForm'/]
 [#macro getTeacherNames(beanList)][#list beanList as bean][#if bean_index>0],[/#if]${(bean.name)!}[/#list][/#macro]
 [#macro getListName(beanList)][#list beanList as bean][#if bean_index>0],[/#if]${(bean.name)!}[/#list][/#macro]
 [#include "/org/openurp/edu/teaching/components/courseTableStyle.ftl"/]
 [@initCourseTable table,1/]
   [#assign taskList=table.clazzes]
   [#include "taskList.ftl"/]
   [@include_optional path="comment.ftl"/]
</div>
[@b.foot/]
