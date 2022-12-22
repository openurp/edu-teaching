[#ftl]
[@b.head/]
[@b.toolbar title="教学班成绩录入"]
  bar.addBack();
[/@]
[#if (gradeInputSwitch.beginAt)??]
<script language="JavaScript" type="text/JavaScript" src="${b.base}/static/scripts/edu/grade/gradeSeg.js"></script>
<br/>
<div class="container">
    [@b.messages slash="5"/]
    <div class="card card-info card-primary card-outline">
        <div class="card-header">
           <h3 class="card-title"><i class="fa-solid fa-circle-info"></i> 课程信息</h3>
        </div>
    <table align="center" style="text-align:center;width:95%">
        <tr>
            <td align="center">
                <table style="padding:2%;width:100%">
                    <tr>
                        <td width="120px" style="text-align:right">课程序号:</td>
                        <td width="300px">${clazz.crn}</td>
                        <td></td>
                    </tr>
                    <tr>
                        <td style="text-align:right">课程名称:</td>
                        <td>${clazz.course.name}</td>
                        <td>
                          [#if (gradeInputSwitch.beginAt)??]允许录入:
                            [#list gradeInputSwitch.types?sort_by("code") as gradeType]
                            ${gradeType.name}&nbsp;
                            [/#list]
                          [#else]
                            未开放录入
                          [/#if]
                         </td>
                    </tr>
                    [#if gradeState.confirmed]
                    <tr>
                        <td style="text-align:right">成绩记录方式:</td>
                        <td>${gradeState.gradingMode.name}</td>
                        <td>
                          [#if (gradeInputSwitch.beginAt)??]
                            开始时间:${gradeInputSwitch.beginAt?string("yyyy-MM-dd HH:mm")}
                          [/#if]
                        </td>
                    </tr>
                    <tr>
                        <td style="text-align:right">成绩精确度:</td>
                        <td>${(gradeState.scorePrecision == 0)?string("保留整数", "保存一位小数")}</td>
                    [#else]
                    <tr>
                        <td style="text-align:right">成绩记录方式:</td>
                        <td>
                          [@b.select id="gradingModeId" label="" name="gradingModeId" items=gradingModes value=(gradeState.gradingMode)?if_exists style="width:150px"/]
                        </td>
                        <td>[#if (gradeInputSwitch.beginAt)??]开始时间:${gradeInputSwitch.beginAt?string("yyyy-MM-dd HH:mm")}[/#if]</td>
                    </tr>
                    <tr>
                        <td style="text-align:right">成绩精确度:</td>
                        <td>
                           [#assign scoreAccuracy = {'0':'保留整数','1':'最多一位小数','2':'最多两位小数'}/]
                           [@b.select id="precision" label="" name="precision" items=scoreAccuracy value=(gradeState.scorePrecision)!"2" style="width:150px" /]
                        </td>
                    [/#if]
                        <td>[#if (gradeInputSwitch.beginAt)??]截止时间:${gradeInputSwitch.endAt?string("yyyy-MM-dd HH:mm")}[/#if]</td>
                    </tr>
                    <tr>
                      <td colspan="3">
                        [#macro small_stateinfo(status)]
                          [#if (status>0)]
                            &nbsp;<i class="fa-solid fa-check"></i>[#if status==1]已提交[#else]已发布[/#if]
                          [/#if]
                        [/#macro]
                        [#macro infoLink(url,onclick, caption)]<a href="${url}" class="btn btn-sm btn-outline-info" [#if onclick?length>0]onclick="${onclick}"[/#if]><i class="fa-solid fa-circle-info"></i>${caption?default("查看")}</a>[/#macro]
                        [#macro inputHTML(url, onclick, caption)]<a href="${url}" onclick="${onclick}" class="btn btn-sm btn-primary"><i class="fa-solid fa-pen-to-square"></i>${caption?default("录入")}</a>[/#macro]
                        [#macro removeGradeHTML(url,onclick,caption)]<a href="${url}" onclick="${onclick}" class="btn btn-sm btn-danger" ><i class="fa-solid fa-xmark"></i>${caption?default("删除")}</a>[/#macro]
                        [#macro reportLink(url,onclick,caption)]<a href="${url}" class="btn btn-sm btn-outline-info" onclick="${onclick}"><i class="fa-solid fa-print"></i>${caption?default("打印")}</a>[/#macro]
                        [#macro reportLink2(url,onclick,caption)]<a href="${url}" class="btn btn-sm btn-success" onclick="${onclick}"><i class="fa-solid fa-print"></i>${caption?default("打印")}</a>[/#macro]
                      </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
   </div>
  [#if gaGradeTypes?size>0]
      [#include "inputGaPanel.ftl"/]
   [/#if]
   [#if gradeInputSwitch.types?seq_contains(MAKEUP_GA) && ((gradeState.getState(GA).status)!0)>0]
    <hr>
   [#include "inputMakeupPanel.ftl"/]
   [/#if]
    [#else]
        [@b.div style="margin-top:10px;"]成绩还未开放录入![/@]
    [/#if]
 </div>
[@b.foot/]
