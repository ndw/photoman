xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace endpoints="http://nwalsh.com/ns/photoends"
       at "/endpoints.xqy";

import module namespace u="http://nwalsh.com/ns/modules/utils"
       at "utils.xqy";

declare namespace gpx="http://www.topografix.com/GPX/1/1";
declare namespace f="http://nwalsh.com/ns/functions";
declare namespace npl="http://nwalsh.com/ns/photolib";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

let $params   := rest:process-request(endpoints:request("/tracks.xqy"))
let $user     := map:get($params, "userid")
return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>photos.nwalsh.com</title>
      <link rel="stylesheet" type="text/css" href="/css/base.css" />
      <link rel="stylesheet" type="text/css" href="/css/photo.css" />
      <link rel="icon" href="/favicon.png" type="image/png" />
      <script type="text/javascript" src="/js/dbmodnizr.js"></script>
      <script type="text/javascript" src="/js/jquery-1.7.1.min.js"></script>
      { if (u:admin())
        then
          <script type="text/javascript" src="/js/actions.js"></script>
        else
          ()
      }
    </head>
    <body>
      <div class="header">
        <div class="breadcrumbs">
          <a href="/">photos.nwalsh.com</a>
          { " | " }
          <a href="/users/{$user}">{$user}</a>
        </div>
        <h1>Tracks</h1>
      </div>
      <div class="content">
        <ul>
          { let $dq     := cts:directory-query("/tracks/" || $user || "/", "infinity")
            let $tracks := cts:search(collection("/gpx/trk"), $dq)/*
            for $date in distinct-values($tracks/npl:date)
            order by $date
            return
              <li><a href="/track/{$user}/{$date}">{$date}</a></li>
          }
        </ul>
      </div>
    </body>
  </html>
