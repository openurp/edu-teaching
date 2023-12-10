[#ftl]
[@b.head]
  <style>
    .report {
      width: 100%;

      margin-left: auto;
      margin-right: auto;

      font-family: 宋体;
      font-size: 10.5pt;
      text-align: center;
      vertical-align: middle;
    }

    .report .clazz-name {
      padding-top: 2px;
      padding-left: 1px;
      padding-right: 1px;
      overflow: hidden;
      text-overflow: ellipsis;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      border-width: 0px;
    }

    .report > .report-top {
      font-size: 10pt;
    }

    .report > .report-header {
      margin-top: 8mm;
      margin-bottom: 10px;

      font-family: 黑体;
      font-size: 16pt;
    }

    .report > .report-header td {
      padding-top: 0px;
      padding-left: 0px;
      padding-right: 0px;
      padding-bottom: 2px;
      vertical-align: bottom;
    }

    .report .report-table-row {
      height: 12mm;
    }
    .report .report-table-half-row {
      height: 25px;
    }
    .report .report-table-min-row {
      height: 2px;
    }
    .report .report-table-bigrow {
      height: 175px;
      vertical-align: top;
    }

    .report .underline {
      display: inline-block;

      border-bottom-width: 1px;
      border-bottom-style: solid;
      border-bottom-color: black;
    }
    .report td span.underline {
      display: inline;
    }
    .report table.listTable {
      width: 163mm;
      font-family: 宋体;
      border-style:solid;
      border-width:2px;
      border-color:black;
      vertical-align: middle;
      font-style: normal;
      text-align: center;
    }
    .report table.listTable td:not(.clazz-name):not(.underline) {
      padding-left: 2px;
      padding-right: 2px;
      border-style:solid;
      border-width:1px;
      border-color:black;
      word-break: break-all;
    }
    .report table.listTable td table.report-detail {
      width: 100%;
      border-width: 0px;
    }
    .report table.listTable td table.report-detail tr:first-child {
      ;
    }
    .report table.listTable td table.report-detail tr:first-child > td {
      border-width: 0px;
    }
    .report table.listTable td table.report-detail td {
      border-left-width: 0px;
      border-bottom-width: 0px;
    }

    .report .report-foot {
      position: absolute;
      bottom: 0px;
      right: 20px;
    }
    .report .report-foot > .report-foot-row {
      ;
    }
    .report .report-foot > .report-foot-row > .report-foot-row-td {
      display: inline-block;
    }
    .report .report-foot > .report-foot-row > .report-foot-row-td.report-foot-row-left {
      width: 115px;
      text-align: start;
    }
    .report .report-foot > .report-foot-row > .report-foot-row-td.report-foot-row-right {
      width: 131px;
    }
  </style>
[/@]
  [@b.toolbar title="考场情况记录表"]
    bar.addPrint();
    bar.addClose();
  [/@]
  <div class="report">
  [#assign top_ul_style = "width: calc((163mm - 71mm) / 2);"/]
  [#list examRooms?sort_by(["room", "name"]) as examRoom]
    [#list examRoom.activities?sort_by(["clazz", "course", "code"]) as activity]
    <div class="report-top"><span class="underline" style="${top_ul_style}"><br></span><span>${activity.clazz.project.school.name}<span class="underline" style="${top_ul_style}"><br></span></div>
    <div class="report-header">考场情况记录表</div>
    <table class="listTable" align="center">
      <tr class="report-table-row">
        <td style="width: 20mm">开课院系</td>
        <td style="width: 34.4mm">${examRoom.teachDepart.name}</td>
        <td style="width: 22mm">学年学期</td>
        <td style="width: 42.88mm;">${examRoom.semester.schoolYear}${examRoom.semester.name}</td>
        <td style="width: 21.9mm">考试日期<br>和时间</td>
        <td style="font-size: 10pt">${activity.examOn?string("yyyy.MM.dd")}<br>${activity.beginAt}-${activity.endAt}</td>
      </tr>
      <tr class="report-table-row">
        <td>课程代码</td>
        <td>${activity.clazz.course.code}</td>
        <td>课程名称</td>
        <td>${activity.clazz.course.name}</td>
        <td>应到人数</td>
        <td>${courseExamTakers.get(examRoom).get(activity.clazz.course)?size}</td>
      </tr>
      <tr class="report-table-row">
        <td>考试地点</td>
        <td>${examRoom.room.name}</td>
        <td><span style="letter-spacing: 3px">教学</span>班</td>
        <td class="clazz-name">${activity.clazz.clazzName}</td>
        <td>实到人数</td>
        <td></td>
      </tr>
      <tr class="report-table-min-row">
        <td colspan="6"></td>
      </tr>
      <tr class="report-table-row">
        <td colspan="6">考试纪律情况</td>
      </tr>
      <tr style="height: 122mm;">
        [#assign examTakers={}]
        [#list examRoom.examTakers as et]
          [#if et.activity.id=activity.id]
          [#if et.examStatus.id != Normal && et.examStatus.id != Absent]
           [#assign examTakers=examTakers +{et.examStatus.name: ([et]+examTakers[et.examStatus.name]![])}]
          [/#if]
         [/#if]
        [/#list]
        <td colspan="6" style="position:relative;vertical-align: top">
          <div>考场记录<br>（如有违纪物证，请随附本表之后）</div>
          <div style="padding-left: 3px;text-align: left">
           [#list examTakers?keys as k]
           ${k}名单：[#list examTakers[k] as et]${et.std.name}(${et.std.code})[#if et_has_next],&nbsp;[/#if][/#list]
           <br>
           [/#list]
                    缺考名单：</div>
          <div class="report-foot">
            <div class="report-foot-row">
              <div class="report-foot-row-td report-foot-row-left">监考人签名：</div>
              <div class="report-foot-row-td report-foot-row-right"></div>
            </div>
            <div class="report-foot-row">
              <div class="report-foot-row-td report-foot-row-left"></div>
              <div class="report-foot-row-td report-foot-row-right"><span>20</span><span style="width: 25px;display: inline-block;"></span><span>年</span><span style="width: 25px;display: inline-block;"></span><span>月</span><span style="width: 25px;display: inline-block;"></span><span>日</span></div>
            </div>
          </div>
        </td>
      </tr>
      <tr style="height: 65mm">
        <td colspan="6" style="position:relative;text-align: start;vertical-align: top">
          <div>院系意见</div>
          <div class="report-foot">
            <div class="report-foot-row">
              <div class="report-foot-row-td report-foot-row-left">考务负责人签名：</div>
              <div class="report-foot-row-td report-foot-row-right"></div>
            </div>
            <div class="report-foot-row">
              <div class="report-foot-row-td report-foot-row-left"></div>
              <div class="report-foot-row-td report-foot-row-right"><span>20</span><span style="width: 25px;display: inline-block;"></span><span>年</span><span style="width: 25px;display: inline-block;"></span><span>月</span><span style="width: 25px;display: inline-block;"></span><span>日</span></div>
            </div>
          </div>
        </td>
      </tr>
    </table>
      [#if activity_has_next || examRoom_has_next]
    <div style='PAGE-BREAK-AFTER: always'></div>
      [/#if]
    [/#list]
  [/#list]
  </div>
  <script>
    $(function() {
      function resetFontSize(wordbox, maxHeight) {
        wordbox.each(function () {
          //console.log({ "value": $(this).text(), "height": $(this).height(), "maxHeight": maxHeight });
          if ($(this).height() <= maxHeight) {
            $(this).removeAttr("class");
          }
        });
      };

      $(document).ready(function() {
        resetFontSize($(".clazz-name"), 20);
      });
    })
  </script>
[@b.foot/]
