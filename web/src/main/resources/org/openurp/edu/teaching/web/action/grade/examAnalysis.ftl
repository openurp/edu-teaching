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
  [@b.field label="综合分析方向"]
    <div style="white-space: pre-wrap;margin-left:100px">1.考卷内容分析（可从考核重点、题型、题量、难易度、覆盖面等说明）
2.学生答卷情况分析（可从学生较易得分、较难得分，学生的答卷与教师期望的差别等方面说明）
3.按教学大纲提高课堂教学质量的对策
4.进一步提高命题质量的措施</div>
  [/@]
  [@b.textarea name="analysisContents" label="综合分析内容" value=(analysis.contents)! rows="15" cols="90" maxlength="800"
   comment="不少于200字"/]
  [@b.field label="注意事项"]
    <div style="white-space: pre-wrap;margin-left:100px">1.每个课程序号（教学班）需制作一份试卷分析。
2.同一课程代码但有多个课程序号（教学班）的，不需要制作总的试卷分析。
3.本表填写完成后可一式三份双面打印，一份由教研室留存，两份与试卷一起归档至教务处试卷库。</div>
  [/@]
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
