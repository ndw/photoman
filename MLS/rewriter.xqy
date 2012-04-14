xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace endpoints="http://nwalsh.com/ns/photoends"
       at "/endpoints.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

let $uri    := xdmp:get-request-url()
let $result := rest:rewrite(endpoints:options())
return
  if (empty($result))
  then
    (xdmp:log(concat("URI Rewrite: ", $uri, " => 404!")),
     xdmp:set-response-code(404, "Not found"),
     $uri)
  else
    ( (:xdmp:log(concat("URI Rewrite: ", $uri, " => ", $result)), :)
    $result)

