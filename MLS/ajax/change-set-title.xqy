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

let $params := rest:process-request(endpoints:request("/ajax/change-set-title.xqy"))
let $uri    := map:get($params, "uri")
let $value  := map:get($params, "value")
let $user   := substring-before($uri, "/")
let $set    := substring-after($uri, "/")
let $perm   := xdmp:permission("weblog-reader", "read")

let $setn   := substring-after($set, "/")
let $uri    := concat("/metadata/", $user, "/sets/", $setn, ".xml")

return
  if (u:admin())
  then
    (if (empty(doc($uri)))
     then
       xdmp:document-insert($uri,
                            <npl:metadata>
                               <npl:title>{$value}</npl:title>
                               <npl:description></npl:description>
                            </npl:metadata>,
                            $perm)
     else
       xdmp:node-replace(doc($uri)/npl:metadata/npl:title, <npl:title>{$value}</npl:title>),
     xdmp:set-response-code(200, "Ok"),
     "Ok")
  else
    xdmp:set-response-code(403, "Forbidden")