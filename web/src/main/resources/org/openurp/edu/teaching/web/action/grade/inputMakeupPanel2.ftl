[#ftl]
[#--补缓考成绩录入--]
<div class="card card-info card-primary card-outline">
  <div class="card-header">
     <h3 class="card-title"><i class="fa-solid fa-chalkboard-user"></i> 补考缓考</h3>
     <div class="card-tools">
        [#assign gastatus=(gradeState.getState(MakeupGa).status)!0/]
        <span style="margin-right:10px">[#if gastatus==1]<i class="fa-solid fa-check"></i>已提交[#elseif gastatus=2]<i class="fa-solid fa-brightness"></i>已发布[/#if]</span>
        [#if (gradeState.getState(MakeupGa).updatedAt)??]上次录入:${gradeState.getState(MakeupGa).updatedAt?string("yyyy-MM-dd HH:mm")}[/#if]
    </div>
  </div>
  <div class="card-body">
  <form method="post" action="" name="actionForm3" id="actionForm3" target="_self">
    <input type="hidden" name="clazzId" value="${clazz.id}"/>
    <input type="hidden" name="gradeTypeIds" value="${Makeup.id},${Delay.id}"/>
        <div style="display: block;height:100px;padding:5px;font-size:14px;background-color:#E1ECFF;border-color:LightSkyBlue;" class="tab-page" id="tabPage3_1">
            <h2 class="tab" style="background-color:#E1ECFF;font-size:14px;width:100px;border-color:LightSkyBlue;"><b>${b.text('grade.makeupdelay')}</b></h2>
            <table width="100%" height="20px" cellpadding="0" cellspacing="0">
                <tr>[#assign makeupGradeTypeState = gradeState.getState(MakeupGa)!/]
                    [#assign status=(makeupGradeTypeState.status!0)/]
                                       [#if (status>0)]
                                                    <td width="25px"><image src="${b.base}/static/themes/default/images/dialog-ok-apply.png" width="25px"/></td>
                                                    <td width="50px">[#if status==1]已提交[#else]已发布[/#if]</td>
                                                  [#else]
                                                    <td></td>
                                                  [/#if]
                    <td align="right">[#if makeupGradeTypeState?? && makeupGradeTypeState.updatedAt??]上次录入:${makeupGradeTypeState.updatedAt?string("yyyy-MM-dd HH:mm")}[/#if]</td>
                </tr>
            </table>
            <table align="center" width="100%" cellpadding="0" cellpadding="0">
              <tr valign="top">
                <td width="20%">
                    <table cellpadding="0" cellspacing="0" >
                        <tr>
                            [@infoLink url="${b.url('!blank?makeup=1&clazz.id=' +clazz.id)}" onclick=""caption="空白登分表"/]
                        </tr>
                    </table>
                </td>
                <td style="text-align: center;">
            <table align="center" style="font-size:14px;text-align:center" cellpadding="0" cellspacing="0">
                <tr height="35px">
                    [#if !(makeupGradeTypeState.confirmed)?default(false)]
                    [#if gradeInputSwitch.checkOpen()]
                    [@inputHTML url="#" onclick="makeupInput();return false;" caption="录入" /]
                    [@removeGradeHTML url="#" onclick="makeupRemove();return false;" caption="删除成绩"/]
                    [#else]<td width="80px" style="vertical-align:middle;"><a>未开放录入</a></td>[/#if]
                    [/#if]
                    [#if (makeupGradeTypeState.confirmed)?default(false) || (makeupGradeTypeState.published)?default(false)]
                    [@printHTML url="#" onclick="makeupPrint();return false;" tdStyle="vertical-align:middle"/]
                    [/#if]
                </tr>
                [#if !(makeupGradeTypeState.confirmed)?default(false) && !(makeupGradeTypeState.published)?default(false)][/#if]
            </table>
            </td>
            <td width="20%"></td>
            </tr>
        </table>
        </div>
    </form>
  </div><!--card body-->
</div>
<script>
  var form3 = document.actionForm3;
    function makeupInput() {
      bg.form.submit("actionForm3","${b.url('!inputMakeup')}");
    }
    function makeupRemove() {
        if (confirm("要删除该课程该类型成绩吗？")) {
             bg.form.submit("actionForm3","${b.url('!removeMakeup')}");
        }
    }
    function makeupPrint() {
        bg.form.submit("actionForm3","${b.url('!report')}");
    }
</script>
