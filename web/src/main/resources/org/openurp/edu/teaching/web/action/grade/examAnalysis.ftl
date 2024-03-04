[@b.head/]
[@b.toolbar title="试卷分析表"]
  bar.addClose();
[/@]
[@b.form name="actionForm" action="!examReport" theme="list" onsubmit="validateContents"]
  [@b.field label="课程"]
    序号${clazz.crn} ${clazz.course.code} ${clazz.course.name}
  [/@]
  [@b.field label="考试成绩"]
    [#list stats as gradeStat]
    ${gradeStat.gradeType.name}
    [#list gradeStat.segments as seg]
    [#if seg.count>0]
    ${seg.min?string("##.#")}-${seg.max?string("##.#")} ${seg.count}人
    [/#if]
    [/#list]
    [/#list]
  [/@]
  [@b.textarea name="analysisContents" label="综合分析" value=(analysis.contents)! rows="15" cols="90" maxlength="500"
   comment="不少于200字"/]
  [@b.formfoot]
    <input type="hidden" name="clazzId" value="${clazz.id}"/>
    [@b.submit value="保存"/]
  [/@]
[/@]
<script>
  function validateContents(form){
    if(form['analysisContents'].value.length<200){
      alert("综合分析内容不少于200字,请修改后保存,现在只有"+form['analysisContents'].value.length+"字");
      return false;
    }else{
      return true;
    }
  }
</script>
[@b.foot/]
