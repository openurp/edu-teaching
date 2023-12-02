[#ftl]
[@b.head/]
<script>
  var emptyScoreStatuses=[[#list setting.emptyScoreStatuses as s]'${s.id}'[#if s_has_next],[/#if][/#list]];
</script>
<script language="JavaScript" type="text/JavaScript" src="${b.base}/static/edu/grade/input.js?ver=20231212"></script>
[#macro gradeTd(grade, gradeType, courseTaker, index)]
<td id="TD_${(gradeType.id)!}_${courseTaker.std.id}">
[#local examStatus=NormalExamStatus/]
[#--查找考试记录中的考试情况--]
[#if stdExamTypeMap[courseTaker.std.id + "_" + (gradeType.examType.id)?default("")]??]
  [#local examTaker=stdExamTypeMap[courseTaker.std.id + "_" + (gradeType.examType.id)]]
  [#if examTaker.examStatus.id != NormalExamStatus.id]
    [#local unNormalExamStatus=examTaker.examStatus]
    [#local examStatus=unNormalExamStatus/]
  [/#if]
[/#if]

[#--根据策略是否显示输入框--]
[#if gradeTypePolicy.isGradeFor(courseTaker,gradeType,examTaker)]
  [#--判断不能录入考试分数的情况--]
  [#local couldInput=true/]
  [#if unNormalExamStatus??]
    [#list setting.emptyScoreStatuses as s][#if s.id==unNormalExamStatus.id][#local couldInput=false/][#break/][/#if][/#list]
  [/#if]
  [#local currentScoreMarkStyle = gradeState.getState(gradeType).gradingMode/]
  [#if !couldInput]
    <input type="hidden" value="" id="${(gradeType.id)!}_${index + 1}" name="${(gradeType.id)!}_${courseTaker.std.id}"/>
    <input type="hidden" value="${unNormalExamStatus.id}" name="examStatus_${(gradeType.id)!}_${courseTaker.std.id}" id="examStatus_${(gradeType.id)!}_${index + 1}"/>
    ${unNormalExamStatus.name}
  [#else]
      [#if (grade.getGrade(gradeType))??] [#local examGrade=grade.getGrade(gradeType)/][/#if]
      [#if gradeType.id=DELAY.id &&  grade.getGrade(USUAL)??]
      平时:${(grade.getGrade(USUAL).score)!0}
      [/#if]
      [#if currentScoreMarkStyle.numerical]
          <input type="text" class="text"
              onfocus="this.style.backgroundColor='yellow'"
              onblur="this.style.backgroundColor=''"
              onchange="checkScore(${index + 1}, this);"
              tabIndex="${index+1}"
              id="${(gradeType.id)!}_${index + 1}" name="${gradeType.id}_${courseTaker.std.id}"
          value="[#if grade?string != "null"]${(examGrade.score)!}[/#if]" style="width:40px" maxlength="5" role="gradeInput"/>
      [#else]
         <select onfocus="this.style.backgroundColor='yellow'"
                  onchange="checkScore(${index + 1}, this)"
                  id="${(gradeType.id)!}_${index + 1}" name="${(gradeType.id)!}_${courseTaker.std.id}"
                  style="width:70px" role="gradeInput">
              <option value="">...</option>
              [#list gradeRateConfigs.get(currentScoreMarkStyle)?sort_by('defaultScore')?reverse as item]
              <option value="${item.defaultScore}" [#if (examGrade.score)?? && examGrade.score == item.defaultScore ]selected[/#if]>${item.grade}</option>
            [/#list]
         </select>
      [/#if]
      [#if gradeType.examType?? || (gradeState.getPercent(gradeType)!0)=100]
      [@b.select label="" items=examStatuses value=((examGrade.examStatus)!examStatus) name="examStatus_" + (gradeType.id)! + "_" + courseTaker.std.id id="examStatus_" + (gradeType.id)! + "_" + (index + 1) style="width:60px;"
      onchange="changeExamStatus('${(gradeType.id)!}_${index + 1}',this);gradeTable.calcGa(${index + 1});"/]
      [/#if]
    [/#if]
[/#if]
</td>
[/#macro]

[#macro displayGrades(index, courseTaker)]
    <td align="center">${index + 1}</td>
    <td>${courseTaker.std.code}<input type="hidden" value="${(courseTaker.std.project.id)?if_exists}" id="courseTaker_project_${index + 1}"></td>
  [#if gradeMap.get(courseTaker.std)??]
  [#local grade = gradeMap.get(courseTaker.std)]
  [/#if]
    <td>
      ${courseTaker.std.name}[#if courseTaker.takeType != NormalTakeType]<sup>${courseTaker.takeType.name}</sup>[/#if]
    </td>
    <script language="javascript">courseGrade = gradeTable.add(${index}, "${courseTaker.std.id}", ${courseTaker.takeType.id});</script>
    <input type="hidden" id="courseTakeType_${index + 1}" value="${courseTaker.takeType.id}"/>

    [#list gradeTypes as gradeType]
    <script>courseGrade.examGrades["${(gradeType.id)!}"] = "${(grade.getGrade(gradeType).score)!0}";</script>
    [#if !gradeType.ga]
        [#if (grade.getGrade(gradeType).confirmed)!false]
      <td>${grade.getScoreText(gradeType)!"--"}[#if grade.getGrade(gradeType).examStatus != NormalExamStatus]<sup>${grade.getGrade(gradeType).examStatus.name}</sup>[/#if]</td>
        [#elseif ((courseTaker.takeType.id)!0)==5]
        <td>免修</td>
        [#elseif ((courseTaker.takeType.id)!0)==6]
        <td>旁听</td>
        [#else]
         [@gradeTd grade, gradeType, courseTaker, index/]
        [/#if]
    [/#if]
    [/#list]
    <td align="center" id="GA_${index + 1}">
    [#if grade?exists]
      [#list gradeTypes as gradeType]
          [#if gradeType.ga && grade.getGrade(gradeType)??]
            [#local gaGrade=grade.getGrade(gradeType)/]
            [#if gaGrade.passed]${gaGrade.scoreText!}[#else]<font color="red">${gaGrade.scoreText!}</font>[/#if]
            [#break/]
          [/#if]
      [/#list]
    [/#if]
    </td>
[/#macro]

[@b.toolbar title="教学班成绩录入"]
  bar.addClose();
[/@]
[@b.messages slash="6"/]
<script language="JavaScript">
  [#assign inputGradeTypes=[]]
    [#list gradeTypes as g]
      [#if !g.ga]
       [#assign inputGradeTypes=inputGradeTypes + [g]]
       [#if g.id=DELAY.id][#assign inputGradeTypes=inputGradeTypes + [USUAL]][/#if]
      [/#if]
    [/#list]
    gradeTable = new GradeTable();
    gradeTable.calcGaUrl="${b.url('ga-calculator')}";
    [#list inputGradeTypes as gradeType]
    gradeTable.gradeState[${gradeType_index}] = new Object();
    gradeTable.gradeState[${gradeType_index}].id = "${(gradeType.id)!}";
    gradeTable.gradeState[${gradeType_index}].name = "${(gradeType.id)!}";
    gradeTable.gradeState[${gradeType_index}].scorePercent = ${(gradeState.getPercent(gradeType))?default("null")};
    gradeTable.gradeState[${gradeType_index}].inputable=true;
    [/#list]

    gradeTable.precision=${gradeState.scorePrecision};
    gradeTable.gradeStateId="${gradeState.id}";
    gradeTable.hasGa=true;
</script>

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
    <form id="gradeForm" name="gradeForm" action="${b.url("!saveGa")}" method="post" onkeypress="gradeTable.onReturn.focus(event);return false;">
    <input name="clazzId" value="${clazz.id}" type="hidden"/>
    <input name="gradeTypeIds" value="[#list gradeTypes as t]${t.id},[/#list]${EndGa.id}" type="hidden"/>
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
        <td>成绩精确度:[#if gradeState.scorePrecision=0]保留到整数[#else]保留${gradeState.scorePrecision}位小数[/#if]</td>
        <td id="timeElapse"></td>
      </tr>
    </table>
    <table class="grid-table" align="center" >
        <tr align="center" style="backGround-color:LightBlue">
        [#assign canInputedCount = 0/]
        [#list 1..2 as i]
            <td align="center" width="20px">序号</td>
            <td align="center" width="60px">学号</td>
            <td width="40px">姓名</td>
            [#list gradeTypes as gradeType]
                [#if !gradeType.ga]
                [#if i == 1 && gradeState.getState(gradeType)?? && !gradeState.getState(gradeType).confirmed]
                    [#assign canInputedCount = canInputedCount + 1/]
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
                [#list 1..3 + canInputedCount as i]
                <td></td>
                [/#list]
                <td></td>
            [/#if]
            [#if !courseTakers[courseTaker_index + 1]?exists || ((courseTaker_index + 1) * 2 >= courseTakers?size)]
        </tr>
                [#break]
            [/#if]
        </tr>
        [/#list]
    </table>
    [#if courseTakers?size != 0]
    <table width="100%" height="70px">
      <tr>
        <td align="center" id="submitTd">
        [#if (canInputedCount > 0 && clazz.enrollment.courseTakers?size > 0)]
         <button class="btn btn-sm btn-outline-info" id="bnJustSave" onclick="justSave(event)" title="剩余部分下次录入"><i class="fa-regular fa-floppy-disk"></i>暂存</button>
         &nbsp;&nbsp;&nbsp;
         <button class="btn btn-sm btn-outline-primary" id="bnSubmit" onclick="return submitSave(event);"><i class="fa-regular fa-floppy-disk"></i>提交</button>
         [/#if]
        </td>
      </tr>
    </table>
    [/#if]
    </form>
</div>
<script language="JavaScript">
    gradeTable.changeTabIndex(document.gradeForm,true);
    jQuery(document).ready(function(){
      jQuery("input[role='gradeInput']").each(function(){
        var obj = document.getElementById("examStatus_" + this.id);
        var scoreId = this.id;
        changeExamStatus(scoreId,obj);
      })
    })

    [#if courseTakers?size != 0]
        [#if (canInputedCount <= 0)]
      document.getElementById("timeElapse").innerHTML = "<span style=\"color:red;font-weight:bold;background:yellow;font-size:14pt\">当前成绩录入完成。</span>";
        [/#if]
    [/#if]
</script>
[@b.foot/]
