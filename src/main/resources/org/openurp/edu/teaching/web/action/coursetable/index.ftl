[#ftl]
[@b.head/]
<div class="container-fluid" style="background-color:white;">
[#include "../project.ftl" /]
<script language="JavaScript" type="text/JavaScript" src="${b.base}/static/edu/Activity.js?v=20250922"></script>
[@b.toolbar title="我的课程"/]
[@base.semester_bar value=semester! formName='courseTableForm'/]
[#include "/org/openurp/edu/teaching/components/courseTableStyle.ftl"/]
[@initCourseTable table,1/]
[#assign taskList=table.clazzes]
[#include "taskList.ftl"/]
[@include_optional path="comment.ftl"/]
</div>
[@b.foot/]
