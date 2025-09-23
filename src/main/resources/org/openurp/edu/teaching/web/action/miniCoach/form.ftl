[@b.head/]
  <div class="container">
    <div class="card card-primary card-outline">
      <div class="card-header">
        <h3 class="card-title">${std.name}艺术辅导安排</h3>
        [@b.card_tools]
          <button class="btn btn-sm btn-outline-primary" onclick="document.getElementById('sbm_btn').click()"><i class="fas fa-save"></i>保存</button>
          <button class="btn btn-sm btn-outline-primary" onclick="history.back(-1);"><i class="fa-solid fa-arrow-left"></i>后退</button>
        [/@]
      </div>
      [#assign weekdayObjs = [{"id":1,"name":"周一"},{"id":2,"name":"周二"},{"id":3,"name":"周三"},{"id":4,"name":"周四"},{"id":5,"name":"周五"}]/]
      [#assign weekdays = ["","周一","周二","周三","周四","周五","周六","周日"] /]
      <div class="card-body" style="padding-top:0px;">
        [#if maxUnit > 0 && maxWeekday > 0]
        <table class="grid-table" id="occupy-table" style="font-size: 12px;">
          <caption style="caption-side: top;text-align: center;padding-top: 0px;padding-bottom: 0px;">辅导老师${teacher.name}和学生${std.name}的课表</caption>
          <thead class="grid-head">
            <tr>
              [#list weekdays as weekday]
              [#if weekday_index - maxWeekday < 1]
              <td>${weekday}</td>
              [/#if]
              [/#list]
            </tr>
          </thead>
          <tbody class="grid-body">
            [#list units as unit]
            [#if maxUnit - unit.indexno < 0][#break/][/#if]
            <tr>
              <td>${unit.name}</td>
              [#list weekdays as weekday]
                [#if weekday_index>0 && weekday_index - maxWeekday < 1]
                [#assign unitKey="${weekday_index}_${unit.indexno}"/]
                [#assign so=stdOccupyMap[unitKey]!''/]
                [#assign to=teacherOccupyMap[unitKey]!''/]
                <td>[#if so = to]${so}[#else]<span class="text-muted">${to}</span>${so}[/#if]</td>
                [/#if]
              [/#list]
            </tr>
            [/#list]
          </tbody>
        </table>
        <script>
          function mergeRow(tableId, rowStart, colStart) {
            var rows = document.getElementById(tableId).rows;
            var rowLen = rows.length;
            var colLen = rows[0].cells.length;
            for (var j = colLen - 1; j >= colStart; j--) {
              mergeTd = rowStart;
              for (var i = mergeTd + 1; i < rowLen; i++) {
                var tdObj = rows[mergeTd].cells[j]
                var toRemoveTd = rows[i].cells[j]
                if(null == toRemoveTd || "" == toRemoveTd.innerHTML || null == tdObj || "" == tdObj.innerHTML || tdObj.colSpan != toRemoveTd.colSpan || tdObj.innerHTML != toRemoveTd.innerHTML){
                  mergeTd = i;
                  continue;
                }
                if(tdObj.innerHTML == toRemoveTd.innerHTML) {
                  rows[i].removeChild(toRemoveTd);
                  tdObj.rowSpan++;
                }
              }
            }
          }
          mergeRow('occupy-table',1,1);
        </script>
        [/#if]

        [@b.form action="!save" theme="list" name="activityForm"]
          [@b.field label="学生"]${std.name} ${std.level.name} ${std.major.name} ${(std.direction.name)!}[/@]
          [#if activity.teacher??]
            [@b.field label="时间"]${weekdays[activity.time.weekday.id]} ${activity.time.beginAt}~${activity.time.endAt}[/@]
            [@b.field label="授课地点"]${activity.places!}[/@]
          [#else]
            [@b.radios label="周几" name="weekday" items=weekdayObjs value=(activity.time.weekday.id)! required="true"/]
            [@b.select name="beginUnit" label="起始节次"
                items=units value=(setting.getUnit(activity.beginUnit))! option=r"${item.name} (${item.beginAt}~${item.endAt})"  onchange="changeEndUnit(this)" required="true"/]
            [@b.select name="endUnit" label="结束节次"
                items=units value=(setting.getUnit(activity.endUnit))! option=r"${item.name} (${item.beginAt}~${item.endAt})"  required="true"/]
            [@b.textfield label="授课地点" name="places" value=(activity.places)! required="true"/]
          [/#if]
          [@b.textfield label="艺术辅导老师1" name="advisor1.name" id="advisor1_name" value=(activity.advisor1.name)!
                        onchange="searchUser(this,'advisor1_id');" style="width:200px" placeholder="输入姓名搜索" readOnly="true" ]
            <select name="advisor1.id" id="advisor1_id" style="width:200px;display:none" onchange="updateName(this,'advisor1_name')">
              <option value="${(activity.advisor1.id)!}">${(activity.advisor1.name)!}</option>
            </select>
          [/@]
          [@b.textfield label="艺术辅导老师2" name="advisor1.name" id="advisor2_name" value=(activity.advisor2.name)!
                        onchange="searchUser(this,'advisor2_id');" style="width:200px" placeholder="输入姓名搜索" ]
            <select name="advisor2.id" id="advisor2_id" style="width:200px" onchange="updateName(this,'advisor2_name')" >
              <option value="${(activity.advisor2.id)!}">${(activity.advisor2.name)!}</option>
            </select>
          [/@]
          [@b.formfoot]
            <input type="hidden" name="std.id" value="${std.id}"/>
            <input type="hidden" name="course.id" value="${course.id}"/>
            <input type="hidden" name="semester.id" value="${semester.id}"/>
            [#if unit??]<input type="hidden" name="unit" value="${unit}"/>[/#if]
            [@b.submit value="保存" id="sbm_btn"/]
          [/@]
        [/@]
      </div>
    </div>
  </div>
  <script>
    function changeEndUnit(ele){
      jQuery(document.activityForm['endUnit']).val(ele.value);
    }
    function searchUser(ele,selectId){
      if(ele.value){
        $.get("https://yjs.shcmusic.edu.cn/api/base/users.json?q="+encodeURIComponent(ele.value), function(obj){
          jQuery('#'+selectId).empty();
          beangle.select.fillin(selectId,obj,"","id","description",10000);
        });
      }else{
        jQuery('#'+selectId).empty();
      }
    }
    function updateName(ele,inputId){
      jQuery('#'+inputId).val(jQuery(ele).children("option:selected").text());
    }
  </script>
[@b.foot/]
