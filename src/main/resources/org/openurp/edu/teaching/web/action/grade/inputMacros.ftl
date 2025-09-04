[#ftl/]

[#--填充单个成绩类型的单元格--]
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
    <input type="hidden" value="" id="${courseTaker.std.id}_${gradeType.id}" name="${courseTaker.std.id}_${gradeType.id}"/>
    <input type="hidden" value="${unNormalExamStatus.id}" id="${courseTaker.std.id}_${gradeType.id}_examStatus" name="${courseTaker.std.id}_${gradeType.id}_examStatus"/>
    ${unNormalExamStatus.name}
  [#else]
      [#if (grade.getGrade(gradeType))??] [#local examGrade=grade.getGrade(gradeType)/][/#if]
      [#if gradeType.id=Delay.id && grade.getGrade(Usual)??]
      平时:${(grade.getGrade(Usual).score)!0}
      [/#if]
      [#if currentScoreMarkStyle.numerical]
          <input type="text" class="text"
              onfocus="this.style.backgroundColor='yellow'"
              onblur="this.style.backgroundColor=''"
              onchange="checkScore('${courseTaker.std.id}', this);"
              tabIndex="${index+1}"
              id="${courseTaker.std.id}_${gradeType.id}" name="${courseTaker.std.id}_${gradeType.id}"
              value="[#if !secondInput && grade?string != "null"]${(examGrade.score)!}[/#if]"
              style="width:40px" maxlength="5" role="gradeInput"/>
      [#else]
         <select onfocus="this.style.backgroundColor='yellow'"
                  onchange="checkScore('${courseTaker.std.id}', this)"
                  id="${courseTaker.std.id}_${gradeType.id}" name="${courseTaker.std.id}_${gradeType.id}"
                  style="width:70px" role="gradeInput">
              <option value="">...</option>
              [#list gradeRateConfigs.get(currentScoreMarkStyle)?sort_by('defaultScore')?reverse as item]
              <option value="${item.defaultScore}" [#if !secondInput &&(examGrade.score)?? && examGrade.score == item.defaultScore ]selected[/#if]>${item.grade}</option>
            [/#list]
         </select>
      [/#if]
      [#if gradeType.examType?? || (gradeState.getPercent(gradeType)!0)=100]
      [@b.select label="" items=examStatuses value=((examGrade.examStatus)!examStatus)
        id=courseTaker.std.id+"_"+gradeType.id+"_examStatus" name=courseTaker.std.id+"_"+gradeType.id+"_examStatus" style="width:60px;"
        onchange="changeExamStatus('${courseTaker.std.id}_${gradeType.id}',this);gradeTable.calcGa('${courseTaker.std.id}');"/]
      [/#if]
    [/#if]
[/#if]
</td>
[/#macro]

[#--展示第几个学生的成绩或者输入框--]
[#macro displayGrades(index, courseTaker)]
  <td align="center">${index + 1}</td>
  <td>${courseTaker.std.code}</td>
  [#if gradeMap.get(courseTaker.std)??]
  [#local grade = gradeMap.get(courseTaker.std)]
  [/#if]
  <td>
    ${courseTaker.std.name}[#if courseTaker.takeType != NormalTakeType]<sup>${courseTaker.takeType.name}</sup>[/#if]
  </td>
  [#list gradeTypes as gradeType]
  [#if !gradeType.ga]
    [#if (grade.getGrade(gradeType).confirmed)!false ]
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
  <td align="center" id="GA_${courseTaker.std.id}">
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

[#macro gradeScripts]
<script language="JavaScript" type="text/JavaScript" src="${b.base}/static/edu/grade/input.js?ver=20241217"></script>
<script language="JavaScript">
  var emptyScoreStatuses=[[#list setting.emptyScoreStatuses as s]'${s.id}'[#if s_has_next],[/#if][/#list]];
  [#assign inputGradeTypes=[]]
  [#list gradeTypes as g]
    [#if !g.ga]
     [#assign inputGradeTypes=inputGradeTypes + [g]]
     [#if g.id=Delay.id][#assign inputGradeTypes=inputGradeTypes + [Usual]][/#if]
    [/#if]
  [/#list]
  gradeTable = new GradeTable();
  gradeTable.calcGaUrl="${b.url('ga-calculator')}";
  [#list inputGradeTypes as gradeType]
  gradeTable.gradeStates[${gradeType_index}] ={"gradeTypeId":"${(gradeType.id)!}","name":"${gradeType.name}","weight":${(gradeState.getPercent(gradeType))?default("null")},"inputable":true}
  [/#list]

  gradeTable.precision=${gradeState.scorePrecision};
  gradeTable.gradeStateId="${gradeState.id}";
  gradeTable.hasGa=true;
  [#list courseTakers as courseTaker]
  [#if gradeMap.get(courseTaker.std)??]
  [#local grade = gradeMap.get(courseTaker.std)]
  courseGrade = gradeTable.add("${courseTaker.std.id}", ${courseTaker.takeType.id},{[#list grade.examGrades as eg]"${eg.gradeType.id}":"${(eg.score)!0}"[#sep],[/#list]});
  [#else]
  courseGrade = gradeTable.add("${courseTaker.std.id}", ${courseTaker.takeType.id},{});
  [/#if]
  [/#list]

  gradeTable.changeTabIndex(document.gradeForm,true);
  jQuery(document).ready(function(){
    jQuery("input[role='gradeInput']").each(function(){
      changeExamStatus(this.id,document.getElementById(this.id+"_examStatus"));
    })
  })
  gradeTable.setIsSecond(${(secondInput!false)?c});
</script>
[/#macro]
