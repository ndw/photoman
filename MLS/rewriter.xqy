xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace endpoints="http://nwalsh.com/ns/photoends"
       at "/endpoints.xqy";

import module namespace audit="http://nwalsh.com/ns/modules/photoman/audit"
       at "/audit/audit.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

let $uri := xdmp:get-request-url()
return
  if (matches($uri, "/images/ndw/.*\.jpg$"))
  then
    concat("/redirect.xqy?uri=", $uri)
  else
    let $result := rest:rewrite(endpoints:options())
    return
      if (empty($result))
      then
        (xdmp:log(concat("URI Rewrite: ", $uri, " => 404!")),
         xdmp:set-response-code(404, "Not found"),
         audit:http(xdmp:get-request-method(), $uri, 404),
         $uri)
      else
        ( (:xdmp:log(concat("URI Rewrite: ", $uri, " => ", $result)), :)
         audit:http(xdmp:get-request-method(), $uri, 200),
         (: xdmp:log(concat("URI Rewrite: ", $uri, " => ", $result)), :)
         $result)
