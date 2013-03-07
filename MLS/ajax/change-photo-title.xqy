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
declare namespace XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/";

declare option xdmp:mapping "false";

let $params := rest:process-request(endpoints:request("/ajax/change-photo-title.xqy"))
let $uri    := map:get($params, "uri")
let $value  := map:get($params, "value")
let $xml    := doc($uri)/rdf:Description
return
  if (u:admin() and exists($xml))
  then
    (if ($xml/XMP-dc:Title)
     then
       xdmp:node-replace($xml/XMP-dc:Title, <XMP-dc:Title>{$value}</XMP-dc:Title>)
     else
       xdmp:node-insert-child($xml, <XMP-dc:Title>{$value}</XMP-dc:Title>),
     xdmp:set-response-code(200, "Ok"),
     "Ok")
  else
    xdmp:set-response-code(403, "Forbidden")