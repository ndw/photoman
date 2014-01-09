xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace endpoints="http://nwalsh.com/ns/photoends"
       at "/endpoints.xqy";

(: N.B. This module only works with OSM right now :)
import module namespace maps="http://nwalsh.com/ns/photomap"
       at "/maps-osm.xqy";

import module namespace u="http://nwalsh.com/ns/modules/utils"
       at "utils.xqy";

declare namespace gpx="http://www.topografix.com/GPX/1/1";
declare namespace f="http://nwalsh.com/ns/functions";
declare namespace npl="http://nwalsh.com/ns/photolib";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

let $params   := rest:process-request(endpoints:request("/track.xqy"))
let $user     := map:get($params, "userid")
let $date     := map:get($params, "date")

let $dq       := cts:directory-query("/tracks/" || $user || "/", "infinity")
let $tracks   := cts:search(collection("/gpx/trk"), $dq)/gpx:trk[npl:date = $date]

return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>photos.nwalsh.com</title>
      <link rel="stylesheet" type="text/css" href="/css/base.css" />
      <link rel="stylesheet" type="text/css" href="/css/track.css" />
      <link rel="icon" href="/favicon.png" type="image/png" />
      <script type="text/javascript" src="/js/dbmodnizr.js"></script>
      <script type="text/javascript" src="/js/jquery-1.7.1.min.js"></script>
      { maps:head-elements() }
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
        <h1>Track on {$date}</h1>
      </div>
      <div class="content">
        { maps:track($tracks) }
      </div>
    </body>
  </html>
