  [@b.card class="card-primary card-outline"]
    [@b.card_header]
      <h3 class="card-title"><i class="fa-solid fa-chalkboard-user"></i> 任课教师<span class="badge badge-primary">${clazz.teachers?size}</span></h3>
    [/@]
    [@b.card_body]
    <div>
      [#list clazz.teachers as teacher]
      <div>
      <table style="width:100%">
        <tr>
          <td width="60px"><img width="60px" style="border-radius: 50%;" src="${avatarUrls.get(teacher.id)}" class="user-image"></td>
          <td>
         [#if teacher.staff.homepage??]
         <a href="${teacher.staff.homepage}" target="_blank"> ${teacher.name} ${(teacher.staff.title.name)!}</a>
         [#else]
         ${teacher.name} ${(teacher.staff.title.name)!}
         [/#if]
         </td>
       </tr>
      </table>
      </div>
      [/#list]
    </div>
    [/@]
  [/@]
