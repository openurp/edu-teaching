var normalExamStatusId="1";// "${NORMAL}"
var absentStatusId="3";

function GradeTable() {
  this.valueStyle = [
            {"validator":/^\d+$/, "caption":"请输入0或正整数", "shortCaption":"0或正整数"},
            {"validator":/^\d*\.?\d{1}$/, "caption":"请输入0或正数，且保留一位小数", "shortCaption":"0、正数或保留一位小数的正数"}
            ];
  this.gradeStates = new Array();
  this.gradeMap = new Map();
  this.gradeArray = new Array();
  this.precision = 0;
  this.tabByStd=null;
  this.onReturn=null;
  this.hasGa=false;
  this.hasGradeSelect = false;
  this.calcGaUrl=null;
  this.isSecond=false;

  this.setHasGradeSelect = function(hasGradeSelect) {
    this.hasGradeSelect = hasGradeSelect;
  }

  this.setIsSecond=function(isSecond) {
    this.isSecond = isSecond;
  }

  this.hasEmpty = function () {
    for (var i = 0; i < this.gradeStates.length; i++) {
      for (const grade of this.gradeMap.values()) {
        inputs = jQuery("input[name='"+ grade.stdId + "_" + this.gradeStates[i].gradeTypeId+"']");
        selects = jQuery("select[name='"+grade.stdId + "_" + this.gradeStates[i].gradeTypeId +"']");
        examStatuses=jQuery("select[name='"+ grade.stdId + "_" + this.gradeStates[i].gradeTypeId + "_examStatus']");
        if (null != inputs && inputs.length>0) {
          examStatusId=1;
          if(examStatuses.length>0) examStatusId=examStatuses.val();
          if ((inputs.val() == "" || inputs.val() == null) &&  examStatusId==1 && inputs.is(':visible')) {
            return true;
          }
        }else if(null != selects && selects.length>0){
          examStatusId=1;
          if(examStatuses.length>0) examStatusId=examStatuses.val();
          if ((selects.val() == "" || selects.val() == null) &&  examStatusId==1 && selects.is(':visible')) {
            return true;
          }
        }
      }
    }
    return false;
  }

  this.changeTabIndex = function (form,tabByStd){
    this.onReturn = beangle.ui.onreturn(form);
    if (this.tabByStd != tabByStd){
      this.tabByStd = tabByStd;
    } else {
      return;
    }
    var input = null;
    var inputIndex = 0;
    if (!this.tabByStd) {
      for(var i = 0; i < this.gradeStates.length; i++) {
        for (var j = 0;j < this.gradeArray.length; j++) {
          grade = this.gradeArray[j];
          input = document.getElementById(this.getScoreInputId(grade,this.gradeStates[j]));
          if (null != input) {
            input.tabIndex = j + i * this.gradeArray.length + 1;
            this.onReturn.elemts[input.tabIndex] = input.name;
          }
        }
      }
    } else {
      for(var i = 0;i < this.gradeArray.length; i++) {
        grade = this.gradeArray[i];
        for (var j = 0;j < this.gradeStates.length; j++) {
          input = document.getElementById(this.getScoreInputId(grade,this.gradeStates[j]));
          if (null != input) {
            input.tabIndex = j + i * this.gradeStates.length + 1;
            this.onReturn.elemts[input.tabIndex] = input.name;
          }
        }
      }
    }
  }

  this.getScoreInputId = function(grade,gradeState){
    return grade.stdId +"_" + gradeState.gradeTypeId;
  }

  this.getExamStatusInputId = function(grade,gradeState){
    return grade.stdId +"_" + gradeState.gradeTypeId+"_examStatus";
  }

  this.updateEmptyByAbsentStatus=function () {
    for (var i = 0; i < this.gradeStates.length; i++) {
      for (const grade of this.gradeMap.values()) {
        inputs = document.getElementsByName(this.getScoreInputId(grade,this.gradeStates[i]));
        var statusElem = document.getElementById(this.getExamStatusInputId(grade,this.gradeStates[i]));
        if (null != inputs && inputs.length>0 && null != statusElem && inputs[0].value == "") {
          inputs[0].style.display = "none";
          statusElem.style.display = "block";
          jQuery('#'+inputs[0].id+"_examStatus").val(absentStatusId);
        }
      }
    }
  }

  this.calcGa = function(stdId) {
    if(!this.hasGa) return;
    var grade = this.gradeMap.get(stdId);
    if(!grade) return;

    var gradeContents = "&grade.std.id=" + grade.stdId + "&grade.courseTakeType.id=" + grade.courseTakeTypeId;
    var myExamStatus=normalExamStatusId;
    for(var i=0 ;i<this.gradeStates.length;i++){
      state=this.gradeStates[i];
      if(!state.inputable) continue;
      var statePrefix = grade.stdId + "_" +state.gradeTypeId;
      examScore = (null == document.getElementById(statePrefix) || "" == document.getElementById(statePrefix).value ? "" : document.getElementById(statePrefix).value);
      examStatus = normalExamStatusId;
      if(null!=document.getElementById(statePrefix + "_examStatus") && !document.getElementById(statePrefix + "_examStatus").disabled){
         examStatus = document.getElementById(statePrefix + "_examStatus").value;
      }
      if(examScore!=""||examStatus!=normalExamStatusId){
        gradeContents += "&examGrade"+ state.gradeTypeId + ".gradeType.id="+ state.gradeTypeId +"&examGrade"+state.gradeTypeId+".score=" + examScore;
        gradeContents += "&examGrade"+ state.gradeTypeId +".examStatus.id="+examStatus;
      }
    }
    var gaTd=document.getElementById("GA_" + stdId);
    jQuery.get(this.calcGaUrl+"?gradeStateId="+this.gradeStateId+gradeContents,{},function(data){fillGaScore(gaTd,data);});
  }

  this.add = function(stdId, courseTakeTypeId,examGrades) {
    var grade = new CourseGrade(stdId, courseTakeTypeId, examGrades, this);
    this.gradeMap.set(stdId,grade);
    this.gradeArray.push(grade);
    return grade;
  }

  this.changePrecision = function (precision){
    this.precision = precision == 0 ? "positiveInteger" : "unsignedReal";
    if (0 == precision) {
      for(var i = 0; i < this.gradeArray.length; i++) {
        var grade = this.gradeArray[i];
        for (var j = 0; j < this.gradeStates.length; j++) {
          input = document.getElementById(this.getScoreInputId(grade, this.gradeStates[j]));
          if (isNotEmpty(input) && isNotEmpty(input.value)) {
            input.value = Math.floor(parseInt(input.value,10));
            grade.gradeTable.calcGa(j + 1);
          }
        }
      }
    }
  }

  this.fireCompare=function(input) {
    this.gradeMap.get(input.name.split("_")[0]).fireCompare(input, this);
  }
}

function CourseGrade(stdId, courseTakeTypeId, examGrades, gradeTable) {
  this.stdId = stdId;
  this.courseTakeTypeId = courseTakeTypeId;
  this.gradeTable = gradeTable;
  this.examGrades = examGrades;

  this.fireCompare = function (input) {
    var gradeInfos = input.name.split("_");
    var stdId =  gradeInfos[0];
    var gradeType = gradeInfos[1];
    var score = input.value;
    if (null == score) {
      return;
    }
    if (this.examGrades[gradeType] == score) {
      this.gradeTable.calcGa(stdId);
    } else {
      if(null != this.examGrades[gradeType] && this.examGrades[gradeType]>0) {//0或者空的不做检查
         if (confirm("成绩录入和上次录入结果不一致!\n第一次录入结果为:" + this.examGrades[gradeType] + "\n第二次录入结果:" + input.value
               + "\n是否要以第二次录入的成绩作为该成绩?")) {
           this.gradeTable.calcGa(stdId);
         } else {
           score = this.examGrades[gradeType];
           if (this.gradeTable.hasGradeSelect) {
             setSelected(input.value, score);
           } else {
             input.value = score;
           }
         }
       }
    }
  }
}

function fillGaScore(gaTd,data) {
  var results = data.split(",");
  if (null == data || null == results || null == results[0]) {
    jQuery(gaTd).html("");
  } else if (!Boolean(parseInt(results[1],10))) {
    jQuery(gaTd).html("<font color=\"red\">" + results[0] + "</font>");
  } else {
    jQuery(gaTd).html(results[0]);
  }
}

// 检查分数的合法性
function alterErrorScore(input, msg) {
  alert(msg);
  input.value = "";
  return true;
}

function checkScore(stdId, elem) {
  var score = elem.value;
  var error = false;
  if(score != "" && !/^[+-]?(\d+(\.\d*)?|\.\d+)([Ee]-?\d+)?$/.test(score)){
    error = alterErrorScore(elem, "输入的成绩不是有效的数字");
  }
  scoreInt = parseInt(score,10);
  var maxScore=100;
  var minScore=0;
  if(score==999){
    elem.value="";
    jQuery('#'+elem.id+"_examStatus").val(absentStatusId);
    elem.style.display="none";
  }else{
    if (scoreInt > maxScore) error = alterErrorScore(elem, "输入成绩不能超过"+ maxScore +"分");
    if (scoreInt < minScore) error = alterErrorScore(elem, "输入成绩不能小于"+ minScore +"分");
  }
  if (!error) {
    if (gradeTable.isSecond) {
      gradeTable.fireCompare(elem);
    }
    gradeTable.calcGa(stdId);
  }
}

// ///////////////////////////////////////////////////////////////////////
var intervalId = null;

function justSave(e){
  if(saveGrade(true)) {document.gradeForm.submit();}
}
function submitSave(e){
  if(saveGrade(false)) {document.gradeForm.submit();}
}
function saveGrade(justSave) {
  clearInterval(timer);
  document.getElementById("timeElapse").innerHTML = "";
  if (!justSave) {
    if (gradeTable.hasEmpty()) {
       if(!confirm("当前成绩中有没有录入的，需要批量设置为缺考，然后提交吗？")){
         return false;
       }else{
         gradeTable.updateEmptyByAbsentStatus();
       }
    }else{
      if(!confirm("确定提交成绩?")) return false;
    }
  }
  form =document.gradeForm;
  bg.form.addInput(form, "justSave", justSave, "hidden");
  document.getElementById("submitTd").innerHTML = "成绩" + (justSave ? "暂存" : "提交" ) + "中，请稍侯……";
  if (null != intervalId) {
    clearInterval(intervalId);
    document.getElementById("timeElapse").innerHTML = "";
  }
  return true;
}

// 为保存成绩定时提示
var timeMin=5;// 5分钟
var time = timeMin * 60;
var timeElapse = 0;
function refreshTime() {
  if(document.getElementById("timeElapse")==null){
    clearInterval(timer);
    return;
  }
  document.getElementById("timeElapse").style.textAlign = "left";
  var sec = timeElapse % 60;
  var min = Math.floor(timeElapse / 60) % 60;
  var hh = Math.floor(timeElapse / 3600);
  document.getElementById("timeElapse").innerHTML = "（" + timeMin + "分钟自动保存）时间：" + hh + ":" + (min < 10 ? "0" : "") + min + ":" + (sec < 10 ? "0" : "") + sec;
  if (timeElapse > 0 && timeElapse % time == 0) {
    if(saveGrade(true)) document.gradeForm.submit();
  }
  timeElapse++;
}
var timer = setInterval('refreshTime()',1000);

/**
 * 改变考试状态对分数进行清空和隐藏
 */
function changeExamStatus(scoreId,obj){
  if(obj && obj.value != '1'){
    jQuery("#"+scoreId).val('').hide();
  }else{
    jQuery("#"+scoreId).show();
  }
}
