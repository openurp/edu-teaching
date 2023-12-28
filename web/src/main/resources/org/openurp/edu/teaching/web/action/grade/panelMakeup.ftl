[#ftl]
[#--补缓考成绩录入--]
<div class="card card-info card-primary card-outline">
  <div class="card-header">
     <h3 class="card-title"><i class="fa-solid fa-chalkboard-user"></i> <a href="#panelMakeup" onclick="javascript:void(0);return false;">补考缓考</a></h3>
     <div class="card-tools">
        [#assign makeupGaStatus=(gradeState.getState(MakeupGa).status)!0/]
        <span style="margin-right:10px">[#if makeupGaStatus==1]<i class="fa-solid fa-check"></i>已提交[#elseif makeupGaStatus=2]<i class="fa-solid fa-brightness"></i>已发布[/#if]</span>
        [#if (gradeState.getState(MakeupGa).updatedAt)??]上次录入:${gradeState.getState(MakeupGa).updatedAt?string("yyyy-MM-dd HH:mm")}[/#if]
    </div>
  </div>
  <div class="card-body">
  <form method="post" action="" name="actionForm3" id="actionForm3" target="_self">
    <input type="hidden" name="clazzId" value="${clazz.id}"/>
    <input type="hidden" name="gradeTypeIds" value="${Makeup.id},${Delay.id}"/>
    <table align="center" style="font-size:14px;text-align:center" cellpadding="0" cellspacing="0">
      <tr height="35px">
        <td>
        [#if makeupGaStatus<1 && gradeInputSwitch.checkOpen()]
            [@inputHTML url="#" onclick="makeupInput();return false;" caption="录入" /]
            [@b.a href="!removeMakeup?clazzId=${clazz.id}" class="btn btn-sm btn-outline-danger"  onclick="return bg.Go(this,null,'确定删除?')"]
               <i class="fa-solid fa-xmark"></i>删除成绩
             [/@b.a]
        [/#if]

        [#if makeupGaStatus>0]
          [@b.a href="!report?clazzId=${clazz.id}&gradeTypeIds=${Makeup.id},${Delay.id},${FINAL.id}" target="_blank"
             class="btn btn-sm btn-outline-primary"]
             <i class="fa-solid fa-print"></i>补缓考成绩
           [/@b.a]
        [/#if]

        [#if makeupGaStatus==1 && gradeInputSwitch.checkOpen()]
          [@b.a class="btn btn-sm btn-outline-warning" href="grade!revokeMakeup?clazzId="+clazz.id  onclick="return bg.Go(this,null,'确定撤回?')"]<i class="fa-solid fa-undo"></i>撤回[/@]
        [/#if]
        </td>
      </tr>
    </table>
    </form>
  </div><!--card body-->
</div>
<script>
  var form3 = document.actionForm3;
    function makeupInput() {
      bg.form.submit("actionForm3","${b.url('!inputMakeup')}");
    }
</script>
