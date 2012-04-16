xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace endpoints="http://nwalsh.com/ns/photoends"
       at "/endpoints.xqy";

import module namespace u="http://nwalsh.com/ns/modules/utils"
       at "/utils.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace f="http://nwalsh.com/ns/functions";
declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";

declare option xdmp:mapping "false";

let $params := rest:process-request(endpoints:request("/ajax/del-geo.xqy"))
let $uri    := map:get($params, "uri")
let $photo  := doc($uri)/*
let $geo    := ($photo/geo:lat, $photo/geo:long)
return
  if (u:admin())
  then
    if (empty($geo))
    then
      xdmp:set-response-code(400, "Invalid geo")
    else
      (for $elem in $geo
       return
         xdmp:node-delete($elem),
       xdmp:set-response-code(200, "Ok"),
      <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>Geo deleted</title>
        <meta http-equiv='refresh'
              content="0;url={substring-before(xdmp:node-uri($photo), '.xml')}"/>
      </head>
      <body>
      <h1>Location upated</h1>
      <p>{xdmp:node-uri($photo)}</p>
      </body>
      </html>)
  else
    xdmp:set-response-code(403, "Forbidden")