[@b.head/]
<div class="container-fluid">
  [#include "../project.ftl" /]
  [@b.toolbar title="我的授课计划"]
  [/@]
  [@base.semester_bar value=semester! formName='courseTableForm'/]
  <div class="search-container">
    <div class="search-list">
    [@b.grid items=clazzes var="clazz"]
      [@b.row]
        [@b.col width="5%" title="序号"]${clazz_index+1}[/@]
        [@b.col width="10%" title="课程序号"]${(clazz.crn)?if_exists}[/@]
        [@b.col title="课程名称"]${(clazz.course.name)?if_exists}[/@]
        [@b.col width="12%" title="课程类型"]${(clazz.courseType.name)?if_exists}[/@]
        [@b.col width="5%" title="周课时"]${(clazz.schedule.weekHours)?if_exists}[/@]
        [@b.col width="5%" title="总学时"]${(clazz.schedule.creditHours)?if_exists}[/@]
        [@b.col width="5%" title="学生数"]${clazz.enrollment.courseTakers?size}[/@]
        [@b.col width="19%" title="操作"]
          [@b.a href="!edit?clazz.id="+clazz.id]编写[/@]
          [#if plans.get(clazz)??]
          [@b.a href="!clazz?clazz.id="+clazz.id]打印[/@]
          [/#if]
        [/@]
      [/@]
    [/@]
    </div>
  </div>
</div>
[@b.foot/]
