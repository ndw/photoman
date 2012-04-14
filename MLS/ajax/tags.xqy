xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace endpoints="http://nwalsh.com/ns/photoends"
       at "/endpoints.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare option xdmp:mapping "false";

let $params := rest:process-request(endpoints:request("/ajax/tags.xqy"))
let $user   := map:get($params, "userid")
let $userq  := cts:element-value-query(xs:QName("npl:user"), $user)
let $tags   := cts:element-values(xs:QName("npl:tag"), (), (), $userq)
return
  (xdmp:set-response-content-type("application/json"),
   concat("[",
          string-join(for $tag in $tags return concat('"', $tag, '"'), ","),
          "]"))
