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
  <tag name="{$tax/@name}">
    { $tax/@class}
    { for $subtax in $tax/*
      return
        f:tax($subtax)
    }
  </tag>
};

if (u:admin())
then
  (let $taxonomy := xdmp:document-get("/MarkLogic/photoman/etc/taxonomy.xml")/*
   let $tags     := cts:element-values($tagname, (), ("collation=http://marklogic.com/collation/codepoint"), $userq)
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
     xdmp:document-insert("/etc/ndw/taxonomy.xml",
        <tag name="taxonomy">
          { for $tax in ($taxonomy/*[not(@class = 'unclassified')], $unclassified)
            return
              f:tax($tax)
          }
        </tag>,
        $permissions, ()),

   let $sets := xdmp:document-get("/MarkLogic/photoman/etc/sets.xml")/*
   return
     xdmp:document-insert("/etc/ndw/sets.xml", $sets, $permissions, ()),

   for $img in ("blank-square.gif", "favicon.png", "blank.gif", "down.gif", "right.gif")
   return
     xdmp:document-insert(concat("/", $img),
          xdmp:document-get(concat("/MarkLogic/photoman/graphics/", $img)),
          $permissions, ()),

   for $css in ("base.css", "large-photo.css", "photo.css", "set.css", "user.css")
   return
     xdmp:document-insert(concat("/css/", $css),
          xdmp:document-get(concat("/MarkLogic/photoman/css/", $css)),
          $permissions, ()),

   for $js in ("actions.js", "dbmodnizr.js", "jquery-1.7.1.min.js", "mapping.js",
               "functions.js", "flexie.min.js")
   return
     xdmp:document-insert(concat("/js/", $js),
          xdmp:document-get(concat("/MarkLogic/photoman/js/", $js)),
          $permissions, ()),
   "Uploaded images, CSS, JavaScript, and taxonomy."
   )
else
  xdmp:set-response-code(403, "Forbidden")