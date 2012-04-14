xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace endpoints="http://nwalsh.com/ns/photoends"
       at "/endpoints.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

let $params := rest:process-request(endpoints:request("/serve.xqy"))
let $uri    := map:get($params, "uri")
let $fn     := concat("/Volumes/Data/MarkLogic/photoman", $uri)
return
  xdmp:document-get($fn)
