var delimiter = "<br>"
var weekCycle = [];
weekCycle[1] = "";// "%u8FDE";
weekCycle[2] = "%u5355";
weekCycle[3] = "%u53CC";
var result = new String("");
var weeksPerYear = 53;
function Dates() {
    this.toDate = function(datestr) {
        var yearIdx = datestr.indexOf('-');
        var monthIdx = datestr.indexOf('-', yearIdx + 1);
        return new Date(Date.parse(datestr.substring(yearIdx + 1, monthIdx)
                + "/" + datestr.substring(monthIdx + 1) + "/"
                + datestr.substring(0, yearIdx)));
    };
    var weekNames = {
        '1' : '星期一',
        '2' : '星期二',
        '3' : '星期三',
        '4' : '星期四',
        '5' : '星期五',
        '6' : '星期六',
        '7' : '星期日'
    }
    this.format = function(d, pattern) {
        var yyyy = d.getFullYear();
        var mm = d.getMonth() + 1;
        var dd = d.getDate();
        var ww = (d.getDay() == 0) ? 7 : d.getDay();
        var rs = pattern;
        rs = rs.replace('yyyy', yyyy);
        rs = rs.replace('MM', mm);
        rs = rs.replace('dd', dd);
        rs = rs.replace('ww', weekNames[ww]);
        return rs;
    };
    this.weeksBetween = function(firstWeekday, date1, date2) {
        while (date1.getDay() != firstWeekday) {
            date1.setTime(date1.getTime() - 24 * 3600000);
        }
        while (date2.getDay() != firstWeekday) {
            date2.setTime(date2.getTime() - 24 * 3600000);
        }
        return (date2.getTime() - date1.getTime()) / (7 * 24 * 3600000);
    };
}
var Dates = new Dates()
// 输出教学活动信息
function activityInfo() {
    return "teacherId:" + this.teacherId + "\n" + "teacherName:"
            + this.teacherName + "\n" + "courseId:" + this.courseId + "\n"
            + "courseName:" + this.courseName + "\n" + "roomId:" + this.roomId
            + "\n" + "roomName:" + this.roomName + "\n" + "vaildWeeks:"
            + this.vaildWeeks;
}
/**
 * 判断是否相同的活动 same acitivity [teacherId,courseId,roomId,vaildWeeks]
 */
function isSameActivity(other) {
    return this.canMergeWith(other) && (this.vaildWeeks == other.vaildWeeks);
}
/**
 * 合并相同的教学活动 same [teacherId,courseId,roomId,remark] can merge
 */
function canMergeWith(other) {
    return (this.teacherId == other.teacherId
            && this.courseId == other.courseId && this.roomId == other.roomId && this.courseName == other.courseName);
}
// utility for repeat char
function repeatChar(str, length) {
    if (length <= 1) {
        return str;
    }
    var rs = "";
    for (var k = 0; k < length; k++) {
        rs += str;
    }
    return rs;
}

/**
 * 添加缩略表示 add a shortName to exists result; Do not use it directly. a white
 * space will delimate the weeks For example:odd1-18 even3-20
 */
function addAbbreviate(cycle, begin, end) {
    if (result !== "") {
        result += " ";
    }
    if (begin == end) { // only one week
        result += begin;
    } else {
        result += unescape(weekCycle[cycle]) + begin + "-" + end;
    }
    return result;
}
// 缩略单周,例如"10101010"
function mashalOdd(result, weekOccupy, from, start) {
    var cycle = 0;
    if ((start - from + 2) % 2 === 0) {
        cycle = 3;
    } else {
        cycle = 2;
    }
    var i = start + 2;
    for (; i < weekOccupy.length; i += 2) {
        if (weekOccupy.charAt(i) == '1') {
            if (weekOccupy.charAt(i + 1) == '1') {
                addAbbreviate(cycle, start - from + 2, i - 2 - from + 2);
                return i;
            }
        } else {
            if (i - 2 == start) {
                cycle = 1;
            }
            addAbbreviate(cycle, start - from + 2, i - 2 - from + 2);
            return i + 1;
        }
    }
    return i;
}

// 缩略连续周
function mashalContinue(result, weekOccupy, from, start) {
    var cycle = 1;
    var i = start + 2;
    for (; i < weekOccupy.length; i += 2) {
        if (weekOccupy.charAt(i) == '1') {
            if (weekOccupy.charAt(i + 1) != '1') {
                addAbbreviate(cycle, start - from + 2, i - from + 2);
                return i + 2;
            }
        } else {
            addAbbreviate(cycle, start - from + 2, i - 1 - from + 2);
            return i + 1;
        }
    }
    return i;
}
/**
 * 对教学周占用串进行缩略表示 marsh a string contain only '0' or '1' which named "vaildWeeks"
 * with length 53 00000000001111111111111111100101010101010101010100000
 */
function marshal(weekOccupy) {
    var from = 2;
    var startWeek = 1;
    var endWeek = weekOccupy.length - 1;

    result = "";
    if (null == weekOccupy) {
        return "";
    }
    var initLength = weekOccupy.length;
    if (weekOccupy.indexOf('1') == -1) {
        return "";
    }
    weekOccupy += "000";
    var start = 0;
    while ('1' != weekOccupy.charAt(start)) {
        start++;
    }
    var i = start + 1;
    while (i < weekOccupy.length) {
        var post = weekOccupy.charAt(start + 1);
        if (post == '0') {
            start = mashalOdd(result, weekOccupy, from, start);
        }
        if (post == '1') {
            start = mashalContinue(result, weekOccupy, from, start);
        }
        while (start < weekOccupy.length && '1' != weekOccupy.charAt(start)) {
            start++;
        }
        i = start;
    }
    return result;
}
/**
 * mashal style is or --------------------------- -------------------- | odd3-18
 * even19-24,room | | odd3-18 | -------------------------- --------------------
 */
function marshalValidWeeks() {
    if (this.roomName !== "") {
        return marshal(this.vaildWeeks) + "," + this.roomName;
    } else {
        return marshal(this.vaildWeeks);
    }
}

function or(first, second) {
    var newStr = "";
    for (var i = 0; i < first.length; i++) {
        if (first.charAt(i) == '1' || second.charAt(i) == '1') {
            newStr += "1";
        } else {
            newStr += "0";
        }
    }
    // alert(first+":first\n"+second+":second\n"+newStr+":result");
    return newStr;
}

// merger activity in every unit.
function mergeAll() {
    for (var i = 0; i < this.unitCounts; i++) {
        if (this.activities[i].length > 1) {
            for (var j = 1; j < this.activities[i].length; j++) {
                this.activities[i][0].vaildWeeks = or(
                        this.activities[i][0].vaildWeeks,
                        this.activities[i][j].vaildWeeks);
                this.activities[i][j] = null;
            }
        }
    }
}
// merger activity in every unit by course.
function mergeByCourse() {
    for (var i = 0; i < this.unitCounts; i++) {
        if (this.activities[i].length > 1) {
            // O(n^2)
            for (var j = 0; j < this.activities[i].length; j++) {
                if (null != this.activities[i][j]) {
                    for (var k = j + 1; j < this.activities[i].length; k++) {
                        if (null != this.activities[i][k]) {
                            if (this.activities[i][j].courseName == this.activities[i][k].courseName) {
                                this.activities[i][j].vaildWeeks = or(
                                        this.activities[i][j].vaildWeeks,
                                        this.activities[i][k].vaildWeeks);
                                this.activities[i][k] = null;
                            }
                        }
                    }
                }
            }
        }
    }
}
function isTimeConflictWith(otherTable) {
    for (var i = 0; i < this.unitCounts; i++) {
        if (this.activities[i].length !== 0
                && otherTable.activities[i].length !== 0) {
            for (var m = 0; m < this.activities[i].length; m++) {
                for (var n = 0; n < otherTable.activities[i].length; n++) {
                    for (var k = 0; k < this.activities[i][m].vaildWeeks.length; k++) {
                        if (this.activities[i][m].vaildWeeks.charAt(k) == '1'
                                && otherTable.activities[i][n].vaildWeeks
                                        .charAt(k) == '1') {
                            return true;
                        }
                    }
                }
            }
        }
    }
    return false;
}

/**
 * aggreagate activity of same course. first merge the activity of same
 * (teacher,course,room). then output mashal vaildWeek string . if course is
 * null. the course name will be ommited in last string. style is
 * -------------------------------- | teacher1Name course1Name | |
 * (odd1-2,room1Name) | | (even2-4,room2Name) | | teacher2Name course1Name | |
 * (odd3-6,room1Name) | | (even5-8,room2Name) |
 * ----------------------------------
 *
 * @param index
 *            time unit index
 */
function marshalByTeacherCourse(index) {
    if (this.activities[index].length === 0) {
        return "";
    }
    if (this.activities[index].length == 1) {
        var cname = this.activities[index][0].courseName;
        var tname = this.activities[index][0].teacherName;
        return tname + " " + cname + delimiter + "("
                + this.activities[index][0].marshal() + ")";
    } else {
        var marshalString = "";
        var tempActivities = new Array();
        tempActivities[0] = this.activities[index][0].clone();
        // merge this.activities to tempActivities by same courseName and
        // roomId .start with 1.
        for (var i = 1; i < this.activities[index].length; i++) {
            var merged = false;
            for (var j = 0; j < tempActivities.length; j++) {
                if (this.activities[index][i].canMergeWith(tempActivities[j])) {
                    merged = true;
                    var secondWeeks = this.activities[index][i].vaildWeeks;
                    tempActivities[j].vaildWeeks = or(
                            tempActivities[j].vaildWeeks, secondWeeks);
                }
            }
            if (!merged) {
                tempActivities[tempActivities.length] = this.activities[index][i];
            }
        }

        // marshal tempActivities
        for (var m = 0; m < tempActivities.length; m++) {
            if (tempActivities[m] === null) {
                continue;
            }
            var courseName = tempActivities[m].courseName;
            var teacherName = tempActivities[m].teacherName;
            // add teacherName and courseName
            if (courseName !== null) {
                marshalString += delimiter + courseName ;
            }
            marshalString += delimiter + teacherName + "(" + tempActivities[m].marshal()  + ")";
            for (var n = m + 1; n < tempActivities.length; n++) {
                // marshal same courseName activity
                if (tempActivities[n] !== null && courseName == tempActivities[n].courseName) {
                    marshalString += delimiter + tempActivities[n].teacherName + "(" + tempActivities[n].marshal() + ")";
                    tempActivities[n] = null;
                }
            }
        }

        if (marshalString.indexOf(delimiter) === 0) {
            return marshalString.substring(delimiter.length);
        } else {
            return marshalString;
        }
    }
}

// return true,if this.activities[first] and this.activities[second] has same
// activities .
function isSameActivities(first, second) {
    if (this.activities[first].length != this.activities[second].length) {
        return false;
    }
    if (this.activities[first].length == 1) {
        return this.activities[first][0].isSame(this.activities[second][0]);
    }
    for (var i = 0; i < this.activities[first].length; i++) {
        var find = false;
        for (var j = 0; j < this.activities[second].length; j++) {
            if (this.activities[first][i].isSame(this.activities[second][j])) {
                find = true;
                break;
            }
        }
        if (find === false) {
            return false;
        }
    }
    return true;
}

// new taskAcitvity
function TaskActivity(teacherId, teacherName, courseId, courseName, roomId,
        roomName, vaildWeeks, taskId, places) {
    this.teacherId = teacherId;
    this.teacherName = teacherName;
    this.courseId = courseId;
    this.courseName = courseName;
    this.roomId = roomId;
    this.roomName = roomName;
    this.vaildWeeks = vaildWeeks;
    this.taskId = taskId;
    this.marshal = marshalValidWeeks;
    this.addAbbreviate = addAbbreviate;
    this.clone = cloneTaskActivity;
    this.canMergeWith = canMergeWith;
    this.isSame = isSameActivity;
    this.toString = activityInfo;
    this.places = places;
}

// clone a activity
function cloneTaskActivity() {
    return new TaskActivity(this.teacherId, this.teacherName, this.courseId,
            this.courseName, this.roomId, this.roomName, this.vaildWeeks,
            this.taskId, this.places);
}
//
function marshalTable() {
    for (var k = 0; k < this.unitCounts; k++) {
        if (this.activities[k].length > 0) {
            this.marshalContents[k] = this.marshal(k);
        }
    }
    return this;
}

function marshalTableForSquad() {
    for (var k = 0; k < this.unitCounts; k++) {
        if (this.activities[k].length > 0) {
            this.marshalContents[k] = this.marshalForSquad(k);
        }
    }
}
function marshalForSquad(index) {
    if (this.activities[index].length === 0) {
        return "";
    }
    if (this.activities[index].length == 1) {
        var cname = this.activities[index][0].courseName;
        var tname = this.activities[index][0].teacherName;
        var roomOccupancy = "(" + this.activities[index][0].marshal() + ")";
        return tname + " " + cname + roomOccupancy;
    } else {
        var marshalString = "";
        var tempActivities = new Array();
        tempActivities[0] = this.activities[index][0].clone();
        // merge this.activities to tempActivities by same courseName and
        // roomId .start with 1.
        for (var i = 1; i < this.activities[index].length; i++) {
            var merged = false;
            for (var j = 0; j < tempActivities.length; j++) {
                if (this.activities[index][i].canMergeWith(tempActivities[j])) {
                    merged = true;
                    var secondWeeks = this.activities[index][i].vaildWeeks;
                    tempActivities[j].vaildWeeks = or(
                            tempActivities[j].vaildWeeks, secondWeeks);
                }
            }
            if (!merged) {
                tempActivities[tempActivities.length] = this.activities[index][i];
            }
        }

        // marshal tempActivities
        for (var m = 0; m < tempActivities.length; m++) {
            if (tempActivities[m] === null) {
                continue;
            }
            var courseName = tempActivities[m].courseName;
            var teacherName = tempActivities[m].teacherName;
            // add teacherName and courseName
            var tipStr = "";
            if (courseName !== null) {
                tipStr = courseName + "(" + tempActivities[m].marshal() + ")";
            }
            if (marshalString.indexOf(tipStr) == -1) {
                marshalString += delimiter + tipStr;
            }
        }

        if (marshalString.indexOf(delimiter) === 0) {
            return marshalString.substring(delimiter.length);
        } else {
            return marshalString;
        }
    }
}

/*******************************************************************************
 * course table dispaly occupy of teacher,room and andminClass. It also
 * represent data model of any course arrangement. For example student's course
 * table,single course's table,teacher's course table,and adminClass's course
 * table,even major's .
 ******************************************************************************/
function CourseTable(beginOn, courseUnits) {
    this.courseUnits = courseUnits;
    this.weekdays = new Array(7);
    this.unitCounts = this.weekdays.length * courseUnits.length;
    this.activities = new Array(this.unitCounts);
    this.marshalContents = new Array(this.unitCounts);
    for (var k = 0; k < this.unitCounts; k++) {
        this.activities[k] = [];
    }
    this.beginOn = Dates.toDate(beginOn);
    this.mergeAll = mergeAll;
    this.marshal = marshalByTeacherCourse;
    // return true,if this.activities[first] and this.activities[second] has
    // same vaildWeeks and roomId pair set.
    this.isSame = isSameActivities;
    this.isTimeConflictWith = isTimeConflictWith;
    this.marshalTable = marshalTable;
    this.marshalTableForSquad = marshalTableForSquad;
    this.marshalForSquad = marshalForSquad;
    this.convertWeekstate2ReverseString = function(weekstate, weekOffset) {
        var str0 = weekstate.toString(2)
        if (weekOffset != 0) {
            if (weekOffset > 0) {
                for (i = 0; i < weekOffset; i++) {
                    str0 = str0 + '0';
                }
            } else {
                str0 = str0.substr(0, str0.length + weekOffset);
            }
        }
        var str = "";
        var end = str0.length - 1;
        for (; end >= 0; end--) {
            str = str + str0.charAt(end);
        }
        for (i = str0.length; i < 53; i++) {
            str = str + "0";
        }
        return str;
    }
    this.getCourseUnit = function(indexno) {
        return courseUnits[indexno - 1];
    }
    this.newActivity = function(teacherId, teacherName, courseId, courseName,
            roomId, roomName, startOn, weekstate, taskId, places) {
        var weekstate_str = "";
        if (startOn) {
            var weeks = Dates.weeksBetween(this.beginOn.getDay(), this.beginOn,
                    Dates.toDate(startOn));
            weekstate_str = this.convertWeekstate2ReverseString(weekstate,
                    weeks);
        }
        return new TaskActivity(teacherId, teacherName, courseId, courseName,
                roomId, roomName, weekstate_str, taskId, places)
    }

    this.addActivityByUnit = function(activity, weekday, startUnit, endUnit) {
        for (i = startUnit - 1; i < endUnit; i++) {
            var index = (weekday - 1) * this.courseUnits.length + i;
            this.activities[index][this.activities[index].length] = activity;
        }
    }

    this.addActivityByTime = function(activity, weekday, beginAt, endAt) {
        var startUnit = 100;
        var endUnit = 0;
        var courseUnit = null;
        for (i = 0; i < this.courseUnits.length; i++) {
            courseUnit = this.courseUnits[i];
            if (courseUnit[1] > beginAt && endAt > courseUnit[0]) {
                if ((i + 1) < startUnit)
                    startUnit = i + 1;
                if ((i + 1) > endUnit)
                    endUnit = i + 1;
            }
        }
        this.addActivityByUnit(activity, weekday, startUnit, endUnit);
    }

    this.fillTable = function(tableStyle, tableIndex) {
        if (tableStyle == "WEEK_TABLE") {
            this.fillWeekTable(tableIndex);
        } else {
            this.fillUnitTable(tableIndex);
        }
    }
    /**
     * 填充星期作为列，小节作为行的表格
     */
    this.fillWeekTable = function(tableIndex) {
        var units = this.courseUnits.length;
        var weeks = this.weekdays.length;
        for (var i = 0; i < weeks; i++) {
            for (var j = 0; j < units - 1; j++) {
                var index = units * i + j;
                var preTd = jQuery("#TD" + index + "_" + tableIndex);
                var nextTd = jQuery("#TD" + (index + 1) + "_" + tableIndex);
                while (this.marshalContents[index] != null
                        && this.marshalContents[index + 1] != null
                        && this.marshalContents[index] == this.marshalContents[index + 1]) {
                    nextTd.remove();
                    var spanNumber = 1;
                    if (preTd.prop("rowSpan"))
                        spanNumber = new Number(preTd.prop("rowSpan"))
                    spanNumber++;
                    preTd.prop("rowSpan", spanNumber);
                    j++;
                    if (j >= units - 1) {
                        break;
                    }
                    index = index + 1;
                    nextTd = jQuery("#TD" + (index + 1) + "_" + tableIndex);
                }
            }
        }

        for (var k = 0; k < this.unitCounts; k++) {
            var td = document.getElementById("TD" + k + "_" + tableIndex);
            if (td != null && this.marshalContents[k] != null) {
                td.innerHTML = this.marshalContents[k];
                td.style.backgroundColor = "#94aef3";
                td.className = "infoTitle";

                var activitiesInCell = this.activities[k];
                if (this.detectCollisionInCell(activitiesInCell)) {
                    td.style.backgroundColor = "red";
                }
                td.className = "infoTitle";
                td.title = this.marshalContents[k].replace(/<br>/g, ";");
            }
        }
    }
    /**
     * 填充小节作为列，星期作为行的表格
     */
    this.fillUnitTable = function(tableIndex) {
        var units = this.courseUnits.length;
        var weeks = this.weekdays.length;
        for (var i = 0; i < weeks; i++) {
            for (var j = 0; j < units - 1; j++) {
                var index = units * i + j;
                var preTd = document.getElementById("TD" + index + "_"  + tableIndex);
                var nextTd = document.getElementById("TD" + (index + units) + "_"  + tableIndex);
                while (this.marshalContents[index] != null
                        && this.marshalContents[index + units] != null
                        && this.marshalContents[index] == this.marshalContents[index + units]) {
                    preTd.parentNode.removeChild(nextTd);
                    var spanNumber = new Number(preTd.colSpan);
                    spanNumber++;
                    preTd.colSpan = spanNumber;
                    j++;
                    if (j >= units - 1) {
                        break;
                    }
                    index = index + units;
                    nextTd = document.getElementById("TD" + (index + units) + "_"  + tableIndex);
                }
            }
        }

        for (var k = 0; k < this.unitCounts; k++) {
            var td = document.getElementById("TD" + k + "_" + tableIndex);
            if (td != null && this.marshalContents[k] != null) {
                td.innerHTML = this.marshalContents[k];
                td.style.backgroundColor = "#94aef3";
                td.className = "infoTitle";

                var activitiesInCell = this.activities[k];
                if (this.detectCollisionInCell(activitiesInCell)) {
                    td.style.backgroundColor = "red";
                }
                td.className = "infoTitle";
                td.title = this.marshalContents[k].replace(/<br>/g, ";");
            }
        }
    }

    /**
     * 检测时间安排是否冲突
     */
    this.detectCollisionInCell = function(activitiesInCell) {
        if (activitiesInCell.length <= 1)
            return false;
        // 单元格的课程集合[courseId(seqNo)->true]
        var cellCourseIds = new Object();
        var mergedValidWeeks = activitiesInCell[0].vaildWeeks.split("");
        // 登记第一个课程
        cellCourseIds[activitiesInCell[0].courseName] = true;
        for (var z = 1; z < activitiesInCell.length; z++) {
            var detectCollision = false;
            var tValidWeeks = activitiesInCell[z].vaildWeeks.split("");
            if (mergedValidWeeks.length != tValidWeeks.length) {
                alert('mergedValidWeeks.length != tValidWeeks.length');
                return;
            }
            for (var x = 0; x < mergedValidWeeks.length; x++) { // 53代表53周
                var m = new Number(mergedValidWeeks[x]);
                var t = new Number(tValidWeeks[x]);
                if (m + t <= 1) {
                    mergedValidWeeks[x] = m + t;
                } else {
                    // 如果已经是登记过的，则不算冲突
                    if (!cellCourseIds[activitiesInCell[z].courseName]) {
                        return true; // 发现冲突
                    }
                }
            }
            // 登记该课程
            cellCourseIds[activitiesInCell[z].courseName] = true;
        }
        return false;
    }

}

/**
 * 合并课程表中相同的单元格
 */
function mergeCellOfCourseTable(weeks, units) {
    for (var i = 0; i < weeks; i++) {
        for (var j = 0; j < units - 1; j++) {
            var index = units * i + j;
            var preTd = document.getElementById("TD" + index);
            var nextTd = document.getElementById("TD" + (index + 1));
            while (preTd.innerHTML !== "" && nextTd.innerHTML !== ""
                    && preTd.innerHTML == nextTd.innerHTML) {
                preTd.parentNode.removeChild(nextTd);
                var spanNumber = new Number(preTd.colSpan);
                spanNumber++;
                preTd.colSpan = spanNumber;
                j++;
                if (j >= units - 1) {
                    break;
                }
                index = index + 1;
                nextTd = document.getElementById("TD" + (index + 1));
            }
        }
    }
}
/**
 * all activities in each unit consists a ActivityCluster
 */
function ActivityCluster(date, courseId, courseName, weeks, places) {
    this.courseId = courseId;
    this.courseName = courseName;
    this.weeks = weeks;
    this.places = places;
    this.weeksMap = {};
    this.activityMap = {};

    /***************************************************************************
     * 添加一个小节中的教学活动组成一个活动集. * *
     **************************************************************************/
    // add acitity to cluster.and weekInex from 0 to weeks-1
    this.add = function(teacherId, teacherName, roomId, roomName, weekIndex) {
        // alert("addActivityToCluster:"+weekIndex)
        if (null == this.weeksMap[teacherId + roomId]) {
            this.weeksMap[teacherId + roomId] = new Array(this.weeks);
            this.activityMap[teacherId + roomId] = new TaskActivity(teacherId,
                    teacherName, this.courseId, this.courseName, roomId,
                    roomName, "");
        }
        this.weeksMap[teacherId + roomId][weekIndex] = "1";
    }
    /*
     * construct a valid Weeks from this.weeksMap by key teacherRoomId this
     * startweek is the position of this.weeksMap[teacherRoomId] in return
     * validWeekStr also it has mininal value 1;
     */
    this.buildWeekstate = function(teacherRoomId) {
        var firstWeeks = new Array(weeksPerYear);
        var weekstates = "";
        for (var i = 0; i < weeksPerYear; i++) {
            firstWeeks[i] = "0";
        }
        for (var weekIndex = 0; weekIndex < this.weeksMap[teacherRoomId].length; weekIndex++) {
            var occupy = "0";
            if (this.weeksMap[teacherRoomId][weekIndex] === undefined)
                occupy == "0";
            else
                occupy = "1";
            // 计算占用周的位置
            var weekIndexNum = new Number(weekIndex);
            firstWeeks[weekIndexNum + 1] = occupy;
        }
        for (i = 0; i < weeksPerYear; i++) {
            weekstates += (firstWeeks[i] == null) ? "0" : firstWeeks[i];
        }
        return weekstates;
    }
    /**
     * 构造教学活动
     *
     */
    this.genActivities = function() {
        var activities = new Array();
        for ( var teacherRoomId in this.activityMap) {
            this.activityMap[teacherRoomId].vaildWeeks = this
                    .buildWeekstate(teacherRoomId);
            this.activityMap[teacherRoomId].places = this.places;
            activities[activities.length] = this.activityMap[teacherRoomId];
        }
        return activities;
    }
}
