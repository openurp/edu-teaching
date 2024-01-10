[#ftl]
[@b.head/]
[#include "inputMacros.ftl"/]
[@b.toolbar title="教学班成绩录入"]
  bar.addClose();
[/@]
[@b.messages slash="6"/]

<div class="container" style="font-size:0.875rem;">
    <div align="center" style="font-weight:bold">${clazz.project.school.name}课程成绩登记表<br>
     ${clazz.semester.schoolYear!}学年${(clazz.semester.name)?if_exists?replace('0','第')}学期
    </div>
    [#if courseTakers?size == 0]
     <br/>
    <table width="90%" align="center" style="background-color:yellow">
        <tr style="color:red"><th>当前没有可以录入成绩的学生。<th></tr>
    </table>
    <br/>
    [/#if]

    <table align="center" border="0" style="font-size:0.875rem;border-collapse: collapse;border:solid;border-width:1px;border-color:Wheat;width:100%;">
      <tr style="background-color: #FFFFBB">
        <td width="33%">课程代码:${clazz.course.code}</td>
        <td width="33%">课程名称:${clazz.course.name}</td>
        <td align="left">课程类型:${clazz.courseType.name}</td>
      </tr>
       <tr style="background-color: #FFFFBB">
        <td>课程序号:${(clazz.crn)?if_exists}</td>
        <td>任课教师:[#list clazz.teachers as t]${t.name}[#sep],[/#list]</td>
        <td>
          录入方式:
          <input type="radio" name="inputTabIndex" onclick="gradeTable.changeTabIndex(this.form,true)" value="1" checked>按学生
          <input type="radio"  name="inputTabIndex" value="0" onclick="gradeTable.changeTabIndex(this.form,false)">按成绩类型
        </td>
      </tr>
      <tr style="background-color: #FFFFBB">
        <td>所录成绩:[#list gradeTypes as gradeType]${gradeType.name}&nbsp;[#if (gradeState.getPercent(gradeType))??](${gradeState.getPercent(gradeType)}%)[/#if][/#list]</td>
        <td>成绩精确度:[#if gradeState.scorePrecision=0]保留到整数[#else]保留${gradeState.scorePrecision}位小数[/#if]
         [#if secondInput]<span style="color:red">第二次录入</span>[/#if]
        </td>
        <td id="timeElapse"></td>
      </tr>
    </table>

    <form id="gradeForm" name="gradeForm" action="${b.url("!saveMakeup")}" method="post" >
    <input name="clazzId" value="${clazz.id}" type="hidden"/>
    <input name="gradeTypeIds" value="[#list gradeTypes as t]${t.id},[/#list]${EndGa.id}" type="hidden"/>
    <table class="grid-table" align="center" onkeypress="gradeTable.onReturn.focus(event);">
        <tr align="center" style="backGround-color:LightBlue">
        [#assign canInputedCount = 0/]
        [#assign examGradeTypeCount = 0/]
        [#list 1..2 as i]
            <td align="center" width="20px">序号</td>
            <td align="center" width="60px">学号</td>
            <td width="40px">姓名</td>
            [#list gradeTypes as gradeType]
              [#if !gradeType.ga]
                [#if i == 1 ]
                  [#assign examGradeTypeCount = examGradeTypeCount + 1/]
                  [#if gradeState.getState(gradeType)?? && !gradeState.getState(gradeType).confirmed]
                    [#assign canInputedCount = canInputedCount + 1/]
                [/#if]
              [/#if]
              <td  width="[#if !(gradeType.examType)??]40px[#else]90px[/#if]">${gradeType.name}</td>
              [/#if]
            [/#list]
            <td  width="40px">总评/最终</td>
        [/#list]
        </tr>
        [#assign courseTakers = courseTakers?sort_by(["std","code"])/]
        [#assign pageSize = ((courseTakers?size + 1) / 2)?int/]
        [#list courseTakers as courseTaker]
        <tr align="center" style="backGround-color:MintCream">
            [@displayGrades courseTaker_index, courseTakers[courseTaker_index]/]

            [#assign j = courseTaker_index + pageSize/]
            [#if courseTakers[j]?exists]
                [@displayGrades j, courseTakers[j]/]
            [#else]
                [#list 1..3 + examGradeTypeCount as i]
                <td>&nbsp;</td>
                [/#list]
                <td>&nbsp;</td>
            [/#if]
            [#if !courseTakers[courseTaker_index + 1]?exists || ((courseTaker_index + 1) * 2 >= courseTakers?size)]
        </tr>
                [#break]
            [/#if]
        </tr>
        [/#list]
    </table>
    </form>
    [#if courseTakers?size != 0]
    <table width="100%" height="70px">
      <tr>
        <td align="center" id="submitTd">
        [#if (canInputedCount > 0 && clazz.enrollment.courseTakers?size > 0)]
         <button class="btn btn-sm btn-outline-info" id="bnJustSave" onclick="justSave(event)" title="剩余部分下次录入"><i class="fa-regular fa-floppy-disk"></i>暂存</button>
         &nbsp;&nbsp;&nbsp;
         [#--1) 不支持第二遍录入 2) 第二遍录入，已经录完了第一遍了--]
         [#if !inputTwiceEnabled || inputTwiceEnabled && inputComplete!false]
         <button class="btn btn-sm btn-outline-primary" id="bnSubmit" onclick="return submitSave(event);"><i class="fa-regular fa-floppy-disk"></i>提交</button>
         [/#if]
        [/#if]
        </td>
      </tr>
    </table>
    [/#if]

</div>
[@gradeScripts/]

[#if courseTakers?size != 0 && (canInputedCount <= 0)]
  <script language="JavaScript">
    document.getElementById("timeElapse").innerHTML = "<span style=\"color:red;font-weight:bold;background:yellow;font-size:14pt\">当前成绩录入完成。</span>";
  </script>
[/#if]
[@b.foot/]
