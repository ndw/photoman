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

declare variable $tax := doc("/etc/ndw/taxonomy.xml")/*;

declare function f:classify(
  $tags as xs:string*
) as element(npl:tag)*
{
  let $alltags := for $tag in $tags
                  let $places := $tax//*[@name = $tag]
                  return
                    if (empty($places))
                    then
                      $tag
                    else
                      ($tag,
                       for $place in $places
                       for $ttag in $place/ancestor::*
                       where $ttag/@name != "taxonomy"
                       return
                         $ttag/@name)
  return
    for $tag in distinct-values($alltags)
    return
      if ($tags = $tag)
      then
        <npl:tag>{$tag}</npl:tag>
      else
        <npl:tag class="tax">{$tag}</npl:tag>
};

declare function f:patch(
  $photo as element(rdf:Description)
) as empty-sequence()
{
  let $tags := $photo/npl:tag
  let $tagstr := for $tag in $tags
                 where not($tag/@class = "tax")
                 return string($tag)
  let $newtags := f:classify($tagstr)
  where count($tags) != count($newtags)
  return
    (for $tag in $tags return xdmp:node-delete($tag),
     for $tag in $newtags return xdmp:node-insert-before($photo/npl:images, $tag))
};

(: This will eventually blow up when there are too many documents :)
(: I'll worry about that later. :)

if (u:admin())
then
  for $doc in /rdf:Description
  return
    (concat("Patched ", xdmp:node-uri($doc)),
     f:patch($doc))
else
  xdmp:set-response-code(403, "Forbidden")