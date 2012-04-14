xquery version "1.0-ml";

import module namespace u="http://nwalsh.com/ns/modules/utils"
       at "utils.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace npl="http://nwalsh.com/ns/photolib";

declare option xdmp:mapping "false";

let $users := cts:element-values(xs:QName("npl:user"))
let $user1 := concat("/users/", $users[1])
return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>photos.nwalsh.com</title>
      <link rel="stylesheet" type="text/css" href="/css/base.css" />
        <link rel="icon" href="/favicon.png" type="image/png" />
        <script type="text/javascript" src="/js/dbmodnizr.js"></script>
        <script type="text/javascript" src="/js/jquery-1.7.1.min.js"></script>
        { if (u:admin())
          then
            <script type="text/javascript" src="/js/actions.js"></script>
          else
            ()
        }
        { if (count($users) = 1)
          then
            <meta http-equiv='refresh' content="0;url={$user1}"/>
          else
            ()
        }
    </head>
    <body>
      <div class="header">
        { u:breadcrumbs(()) }
        <h1>Users</h1>
      </div>
      <div class="content">
        { for $user in $users
          return
            <h2><a href="/users/{$user}">{ u:user-title($user, false()) }</a></h2>
        }

        { if (count($users) = 1)
          then
            <p><i>There's only one user right now, so we'll take you right to them.</i></p>
          else
            ()
        }
      </div>
    </body>
  </html>

