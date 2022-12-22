  <div class="row mb-0">
    <div class="col-sm-9">
    <h4>[@b.a href="!index?clazz.id="+clazz.id]${clazz.crn}[/@] ${clazz.courseName} <span class="text-sm text-muted">${clazz.course.code} ${clazz.semester.schoolYear}学年${clazz.semester.name}学期</span></h4>
    </div>
    <div class="col-sm-3">
      <div style="float:right;padding:0px" class="navbar navbar-expand">
        <ul class="navbar-nav ml-auto">
          <li class="nav-item dropdown">
            <a class="dropdown-toggle nav-link" data-toggle="dropdown" href="#" id="clazz_switcher" aria-expanded="false">更多课程...</a>
            <div class="dropdown-menu">
              [#list clazzes as clz]
              [#if clazz.id !=clz.id]
              [@b.a href="!index?clazz.id="+clz.id  class="dropdown-item" style="font-size:0.8em;width:200px;white-space: break-spaces;"]${clz.crn} ${clz.courseName}[/@]
              [/#if]
              [/#list]
            </div>
          </li>
          <li class="nav-item">
            [@b.a href="coursetable" class="nav-link"]返回课表[/@]
          </li>
        </ul>
      </div>
    </div>
  </div>
