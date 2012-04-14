xquery version "1.0-ml";

module namespace cl="http://nwalsh.com/ns/photolib/cleanup";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace npl="http://nwalsh.com/ns/photolib";

declare option xdmp:mapping "false";

declare variable $user         := "ndw";
declare variable $taxonomy     := doc(concat("/etc/", $user, "/taxonomy.xml"))/*;
declare variable $tagcollation := "collation=http://marklogic.com/collation/codepoint";
declare variable $userq        := cts:element-value-query(xs:QName("npl:user"), $user);

declare function cl:tag-rename(
  $oldtag as xs:string,
  $newtag as xs:string
)
{
  let $newtag := <npl:tag>{$newtag}</npl:tag>
  let $photos := cts:search(/rdf:Description,
                     cts:element-value-query(xs:QName("npl:tag"), $oldtag))
  for $photo in $photos
  let $elem := $photo/npl:tag[. = $oldtag]
  where count($elem) = 1
  return
    (xdmp:node-replace($elem, $newtag),
     concat("Updated ", xdmp:node-uri($photo)))
};

declare function cl:tag-delete(
  $oldtag as xs:string
)
{
  let $photos := cts:search(/rdf:Description,
                     cts:element-value-query(xs:QName("npl:tag"), $oldtag))
  for $photo in $photos
  let $elem := $photo/npl:tag[. = $oldtag]
  where count($elem) = 1
  return
    (xdmp:node-delete($elem),
     concat("Updated ", xdmp:node-uri($photo)))
};

declare function cl:delete-set(
  $set as xs:string
)
{
  let $photos := cts:search(collection($set), cts:and-query(()))
  for $photo in $photos
  return
    (xdmp:document-delete(xdmp:node-uri($photo)),
     concat("Deleted ", xdmp:node-uri($photo)))
};

declare function cl:set-location(
  $photo as element(rdf:Description),
  $country as xs:string?,
  $state as xs:string?,
  $city as xs:string?
)
{
  (for $del in ($photo/npl:location, $photo/npl:country, $photo/npl:province,
                $photo/npl:city)
   return
     xdmp:node-delete($del),

   let $location := concat($country,"|",$state,"|",$city)

   let $state   := if (exists($state))
                   then concat($state,
                               if (exists($country)) then ", " else "",
                               $country)
                   else
                     ()

   let $city    := if (exists($city))
                   then
                     concat($city,
                            if (exists($state)) then ", " else "", $state,
                            if (empty($state) and exists($country))
                            then concat(", ", $country) else "")
                   else
                     ()
   return
     (if (exists($location))
      then xdmp:node-insert-after($photo/npl:images,
                                  <npl:location>{$location}</npl:location>)
      else (),
      if (exists($country))
      then xdmp:node-insert-after($photo/npl:images,
                                  <npl:country>{$country}</npl:country>)
      else (),
      if (exists($state))
      then xdmp:node-insert-after($photo/npl:images,
                                  <npl:province>{$state}</npl:province>)
      else (),
      if (exists($city))
      then xdmp:node-insert-after($photo/npl:images,
                                  <npl:city>{$city}</npl:city>)
      else ()),
    concat("Updated ", xdmp:node-uri($photo)))
};
