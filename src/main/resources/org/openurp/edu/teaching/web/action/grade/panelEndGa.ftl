[#ftl]

[#--总评成绩录入--]
[#assign gaGradeTypeState = gradeState.getState(EndGa)!/]
<div class="card card-info card-primary card-outline">
  <div class="card-header">
     <h3 class="card-title"><i class="fa-solid fa-chalkboard-user"></i> 期末总评</h3>
     <div class="card-tools">
        [#assign gastatus=(gradeState.getState(EndGa).status)!0/]
        <span style="margin-right:10px">[#if gastatus==1]<i class="fa-solid fa-check"></i>已提交[#elseif gastatus=2]<i class="fa-solid fa-brightness"></i>已发布[/#if]</span>
        [#if (gradeState.getState(EndGa).updatedAt)??]上次录入:${gradeState.getState(EndGa).updatedAt?string("yyyy-MM-dd HH:mm")}[/#if]
    </div>
  </div>
  <div class="card-body">
    <form method="post" action="" id="actionForm2" name="actionForm2">
      <input type="hidden" name="clazzId" value="${clazz.id}"/>
      <input type="hidden" name="clazzIds" value="${clazz.id}"/>
      <input type="hidden" name="gradeTypeIds" value="[#list gaGradeTypes as t]${t.id},[/#list]${EndGa.id}"/>
      <input type="hidden" name="kind" value="task"/>
      <input type="hidden" name="isChangeGA" value="1"/>
      <table cellpadding="0"  align="center">
      [#list gaGradeTypes?sort_by("code") as gradeType]
        [#if gradeState.getState(gradeType)??]
        [#assign gradeTypeState = gradeState.getState(gradeType)]
        <tr>
          <td style="vertical-align:middle;text-align:right" width="70px">
            ${gradeType.name}:
          </td>
          [#if ((gradeTypeState.confirmed)!false) || ((gaGradeTypeState.confirmed)!false)]
          <td style="border-bottom-width:1px;border-bottom-color:black;border-bottom-style:solid;text-align:center" width="100px">${(gradeTypeState.weight)!}</td>
          [#else]
          <td>
            <input type="text" name="examGradeState${gradeType.id}.weight" value="${(gradeTypeState.weight)!}" style="width:100px;text-align:right" maxlength="3"
                   placeholder="占比" data-toggle="popover" data-trigger="focus" title="录入小贴士"
                   data-content="[#if (gradeTypeState.weight!0)<100]例如30,40等百分数占比。录入该项分数时，请录入折算前的原始分数。例如${gradeType.name}90分，占比30%，需要录入90分，不要录入27分。[#else]请将平时成绩和考核成绩折算后录入[/#if]"
              />
          </td>
          [/#if]
          <td>％</td>
          <td>
          [#if ((gradeTypeState.confirmed)!false) || ((gaGradeTypeState.confirmed)!false)]
          ${gradeTypeState.gradingMode.name}
          [#else]
            [@b.select label="" name="examGradeState${gradeType.id}.gradingMode.id" items=gradingModes value=(gradeTypeState.gradingMode.id)?if_exists style="width:100px"/]
          [/#if]
          </td>
          <td>
            [#if ((gradeTypeState.confirmed)!false) || ((gaGradeTypeState.confirmed)!false)]
             [@small_stateinfo status=(gradeTypeState.status!0)/]
            [#else]
            [#if  (gradeTypeState.weight!0)<100]<div>请直接录入<span style='color: red;'>原始分数</span>，不要折算。</div>[#else]请将平时成绩和考核成绩折算后录入[/#if]
            [/#if]
          </td>
        </tr>
        [/#if]
      [/#list]
      </table>
      <table align="center" align="center" cellpadding="0" cellspacing="0">
        <tr height="50px">
          <td>
            <div class="btn-group">

              [@reportLink url="${b.url('!blank?clazz.id='+clazz.id)}" onclick="" caption="空白登分表"/]
              [#if ((gaGradeTypeState.confirmed)!false)]
                [@reportLink url="#" onclick="printStatReport('clazz');return false;" caption="分段统计表"/]
                [#--[@reportLink url="#" onclick="printStatReportForExam();return false;" caption="试卷分析表"/]--]
              [/#if]
            </div>
            [#if !((gaGradeTypeState.confirmed)!false)]
              [#if gradeInputSwitch.checkOpen()]
              <div class="btn-group">[@inputHTML url="#" onclick="inputGa();return false;" caption="录入"/]</div>
              <div class="btn-group">[@removeGradeHTML url="#" onclick="gaRemove();return false;" caption="删除成绩"/]</div>
              [#else]
                未开放录入
              [/#if]
            [#else]
              [@reportLink2 url="#" onclick="gaPrint();return false;" caption="期末总评"/]
              [#if !gaGradeTypeState.published]
                [@b.a class="btn btn-sm btn-outline-warning" href="grade!revokeGa?clazzId="+clazz.id  onclick="return bg.Go(this,null,'确定撤回?')"]<i class="fa-solid fa-undo"></i>撤回[/@]
              [/#if]
            [/#if]
           </td>
        </tr>
      </table>
    </form>
    [#include "gradeList.ftl"/]
  </div><!--card body-->
</div>
<script>
  var form2 = document.actionForm2;
  function inputGa() {
    var totalPercent=0;
    var onePercent="";
    [#list gaGradeTypes as gradeType]
    [#if gradeState.getState(gradeType)??]
    [#assign gradeTypeState = gradeState.getState(gradeType)]
    [#if gradeTypeState.confirmed]
    onePercent = ${gradeTypeState.weight!0}
    [#else]
    onePercent = form2["examGradeState${gradeType.id}.weight"].value;
    [/#if]
    if("" != onePercent ){
      if(!/^\d+$/.test(onePercent)){
        alert(autoLineFeed("${gradeType.name}不是正整数的数值格式"));
        return;
      }else{
        totalPercent += parseFloat(onePercent);
      }
    }
    [/#if]
    [/#list]
    if(totalPercent != 100) {
        alert("所有设置的百分比数值之和"+totalPercent+"%,应为100％");
        return;
    }
    [#if !gradeState.confirmed]
    bg.form.addInput(form2, "gradingModeId", document.getElementById("gradingModeId").value, "hidden");
    bg.form.addInput(form2, "precision", document.getElementById("precision").value, "hidden");
    [/#if]
    bg.form.submit("actionForm2","${b.url('!inputGa')}");
  }
  function gaRemove() {
    if (confirm("要删除该课程所有总评成绩及其组成部分吗？")) {
      bg.form.submit("actionForm2","${b.url('!removeGa')}");
    }
  }

  function gaPrint() {
    bg.form.submit("actionForm2","${b.url('!report')}","_blank");
  }
  beangle.load(["bootstrap"],function(){
    $('[data-toggle="popover"]').popover({html:true,trigger:"focus"})
  });
</script>
