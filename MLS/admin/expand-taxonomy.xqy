xquery version "1.0-ml";

import module namespace u="http://nwalsh.com/ns/modules/utils"
       at "/utils.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace f="http://nwalsh.com/ns/functions";
declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare option xdmp:mapping "false";

declare variable $permissions := (xdmp:permission("weblog-reader", "read"),
                                  xdmp:permission("weblog-editor", "update"));

declare variable $user   := "ndw";
declare variable $userq  := cts:element-value-query(xs:QName("npl:user"), $user);
declare variable $tagname := xs:QName("npl:tag");

declare function f:tax(
  $tax as element()
) as element()
{
  let $evq   := cts:element-value-query($tagname, $tax/@name, ("exact"))
  let $count := xdmp:estimate(cts:search(/rdf:Description, cts:and-query(($evq,$userq))))
  return
    <tag name="{$tax/@name}" count="{$count}">
      { $tax/@class}
      { for $subtax in $tax/*
        return
          f:tax($subtax)
      }
    </tag>
};

if (u:admin())
then
  let $taxonomy := xdmp:document-get("/MarkLogic/photoman/etc/taxonomy.xml")/*
  let $tags     := cts:element-values($tagname, (),
                       ("collation=http://marklogic.com/collation/codepoint"), $userq)
  let $unclassified := for $tag in $tags
                       where not($taxonomy//*[@name = $tag])
                       return
                         $tag
  let $unclassified := for $tag in distinct-values($unclassified)
                       return
                         element { fn:QName("","tag") }
                                 { (attribute { fn:QName("", "name") } { $tag },
                                    attribute { fn:QName("", "class") } { "unclassified" }) }
  return
    <tag name="taxonomy">
      { for $tax in ($taxonomy/*[not(@class = 'unclassified')], $unclassified)
        return
          f:tax($tax)
      }
    </tag>
else
  xdmp:set-response-code(403, "Forbidden")