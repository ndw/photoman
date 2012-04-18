xquery version "1.0-ml";

declare namespace audit="http://nwalsh.com/ns/modules/photoman/audit";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $node external;

declare variable $perms := (xdmp:permission("weblog-reader", "read"),
                            xdmp:permission("weblog-reader", "update"),
                            xdmp:permission("weblog-editor", "read"),
                            xdmp:permission("weblog-editor", "update"));

declare function local:should-be-logged($uri as xs:string) as xs:boolean {
  not(
    (starts-with($uri, "/graphics/")
     or starts-with($uri, "/fonts/")
     or starts-with($uri, "/local/")
     or ends-with($uri,".js")
     or ends-with($uri,".css"))
  )
};

if (local:should-be-logged($node/audit:uri))
then
  let $docuri := format-dateTime(current-dateTime(), "/audit/[Y0001]-[M01]-[D01]/[H01].xml")
  let $lock   := xdmp:lock-for-update($docuri)
  let $doc    := doc($docuri)
  return
    if (empty($doc))
    then
       xdmp:document-insert($docuri, <audit:log>{ $node }</audit:log>, $perms,
                            "http://nwalsh.com/ns/collections/audit")
    else
       xdmp:node-insert-child($doc/*, $node)
else
  ( (: Nevermind :) )
