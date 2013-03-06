xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace endpoints="http://nwalsh.com/ns/photoends"
       at "/endpoints.xqy";

import module namespace u="http://nwalsh.com/ns/modules/utils"
       at "/utils.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare option xdmp:mapping "false";

let $params := rest:process-request(endpoints:request("/ajax/changeVisibility.xqy"))
let $uri    := map:get($params, "uri")
let $photo  := doc(concat($uri, ".xml"))
let $vis    := map:get($params, "value")
return
  if (u:admin() and ($vis = "public" or $vis = "private") and exists($photo))
  then
    (let $perm := xdmp:permission("weblog-reader", "read")
     for $uri in (xdmp:node-uri($photo))
     return
       if ($vis = "public")
       then xdmp:document-add-permissions(string($uri), $perm)
       else xdmp:document-remove-permissions(string($uri), $perm),
     xdmp:set-response-code(200, "OK"),
     "Ok")
  else
    xdmp:set-response-code(403, "Forbidden")