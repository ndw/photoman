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

declare option xdmp:mapping "false";

declare function f:tag-valid(
  $photo as element(),
  $tag as xs:string
) as xs:boolean
{
  if ($photo/npl:tag = $tag)
  then
    false()
  else
    matches($tag, "^\S+$")
};

let $params := rest:process-request(endpoints:request("/ajax/del-tag.xqy"))
let $uri    := map:get($params, "uri")
let $value  := map:get($params, "value")
let $photo  := doc($uri)/*
return
  if (u:admin())
  then
    if (empty($photo/npl:tag[. = $value]))
    then
      xdmp:set-response-code(400, "Invalid tag")
    else
      (xdmp:node-delete($photo/npl:tag[. = $value]),
       xdmp:set-response-code(200, "Ok"),
       "Ok")
  else
    xdmp:set-response-code(403, "Forbidden")