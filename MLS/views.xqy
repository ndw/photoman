xquery version "1.0-ml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace audit="http://nwalsh.com/ns/modules/photoman/audit";

declare option xdmp:mapping "false";

declare variable $uri as xs:string external;

(: /images/ndw/2007/11/23/2057445143.xml :)
(: /images/ndw/small/2007/11/23/2057445143.jpg :)

let $parts    := tokenize($uri, "/") (: ("", "images", "user", "rest", "of", "it.xml") :)
let $iparts   := ($parts[position() < 4], "small", $parts[position() > 3])
let $photouri := string-join($iparts, "/")
let $photouri := concat(substring($photouri, 1, string-length($photouri) - 4), ".jpg")
let $search   := cts:element-value-query(xs:QName("audit:uri"), $photouri)
return
  (: Warning: this may eventually become expensive... :)
  count(cts:search(/audit:log/audit:http, $search))
