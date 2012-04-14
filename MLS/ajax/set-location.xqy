xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace endpoints="http://nwalsh.com/ns/photoends"
       at "/endpoints.xqy";

import module namespace u="http://nwalsh.com/ns/modules/utils"
       at "/utils.xqy";

import module namespace cl="http://nwalsh.com/ns/photolib/cleanup"
       at "/admin/cleanup.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace f="http://nwalsh.com/ns/functions";
declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare option xdmp:mapping "false";

let $params := rest:process-request(endpoints:request("/ajax/set-location.xqy"))
let $uri    := map:get($params, "uri")
let $city   := map:get($params, "city")
let $state  := map:get($params, "province")
let $country := map:get($params, "country")
let $photo  := doc($uri)/*
return
  if (u:admin())
  then
    let $loc := cl:set-location($photo, $country, $state, $city)
    let $_   := xdmp:set-response-code(200, "Ok")
    return
      <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>Location updated</title>
        <meta http-equiv='refresh'
              content="0;url={substring-before(xdmp:node-uri($photo), '.xml')}"/>
      </head>
      <body>
      <h1>Location upated</h1>
      <p>{xdmp:node-uri($photo)}</p>
      </body>
      </html>
  else
    xdmp:set-response-code(403, "Forbidden")
