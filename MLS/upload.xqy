xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace endpoints="http://nwalsh.com/ns/photoends"
       at "/endpoints.xqy";

import module namespace u="http://nwalsh.com/ns/modules/utils"
       at "utils.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/";
declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace f="http://nwalsh.com/ns/functions";
declare namespace System="http://ns.exiftool.ca/File/System/1.0/";
declare namespace Photoshop="http://ns.exiftool.ca/Photoshop/Photoshop/1.0/";
declare namespace File="http://ns.exiftool.ca/File/1.0/";
declare namespace GPS="http://ns.exiftool.ca/EXIF/GPS/1.0/";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace ExifIFD="http://ns.exiftool.ca/EXIF/ExifIFD/1.0/";
declare namespace IPTC="http://ns.exiftool.ca/IPTC/IPTC/1.0/";

declare option xdmp:mapping "false";

declare variable $tax := doc("/etc/taxonomy.xml")/*;

declare variable $params := rest:process-request(endpoints:request("/upload.xqy"));
declare variable $uri    := map:get($params, "uri");
declare variable $file   := map:get($params, "file");
declare variable $media  := map:get($params, "media");
declare variable $collection := map:get($params, "collection");
declare variable $skip   := map:get($params, "skip");
declare variable $uploadts := map:get($params, "uploadts");
declare variable $format := if (contains($media, "xml")) then "xml" else "binary";
declare variable $body   := xdmp:get-request-body($format);

declare variable $permissions := (xdmp:permission("weblog-reader", "read"),
                                  xdmp:permission("weblog-editor", "update"));

declare function f:gps(
  $rdfD as element(rdf:Description)
) as element()+
{
  let $latsign := if ($rdfD/GPS:GPSLatitudeRef = "North") then 1 else -1
  let $lonsign := if ($rdfD/GPS:GPSLongitudeRef = "East") then 1 else -1
  let $lat     := f:dmstodec(string($rdfD/GPS:GPSLatitude))
  let $lon     := f:dmstodec(string($rdfD/GPS:GPSLongitude))
  return
    (<geo:lat>{$latsign * $lat}</geo:lat>,
     <geo:long>{$lonsign * $lon}</geo:long>)
};

declare function f:dmstodec(
  $dms as xs:string
) as xs:float
{
  let $deg := xs:float(replace($dms, "^(\d+) deg (\d+)' ([\d\.]+)""", "$1"))
  let $min := xs:float(replace($dms, "^(\d+) deg (\d+)' ([\d\.]+)""", "$2"))
  let $sec := xs:float(replace($dms, "^(\d+) deg (\d+)' ([\d\.]+)""", "$3"))
  return
    $deg + ($min div 60.0) + ($sec div 3600.0)
};

declare function f:image-fn(
  $size as xs:string,
  $uri as xs:string
) as xs:string
{
  let $user := substring-before($uri, "/")
  let $rest := substring-after($uri, "/")
  return
    concat("/images/", $user, "/", $size, "/", $rest)
};

declare function f:classify(
  $tags as xs:string*
) as element(npl:tag)*
{
  let $alltags := for $tag in $tags
                  let $places := $tax//*[local-name(.) = $tag]
                  return
                    if (empty($places))
                    then
                      $tag
                    else
                      ($tag,
                       for $place in $places
                       for $ttag in $places//ancestor::*
                       where local-name($ttag) != "taxonomy"
                       return
                         local-name($ttag))
  return
    for $tag in distinct-values($alltags)
    return
      if ($tags = $tag)
      then
        <npl:tag>{$tag}</npl:tag>
      else
        <npl:tag class="tax">{$tag}</npl:tag>
};

if (not(u:admin()))
then
  xdmp:set-response-code(401, "Denied")
else
if (doc-available($uri) and (ends-with($uri, ".jpg") or $skip))
then
  (: not actually quite right :)
  xdmp:set-response-code(302, "Document exists")
else
  let $baseuri     := substring($uri, 1, string-length($uri) - 4)
  return
    if ($format = "binary")
    then
      let $user := substring-before(substring-after($uri, "/images/"), "/")
      let $coll := if (exists($collection)) then concat($user, "/", $collection) else ()
      return
        (xdmp:document-insert($uri, xdmp:external-binary($file), $permissions, $coll),
         concat("Photo ", $baseuri))
    else
      let $fn    := replace($uri, "^/images/(.*)\.xml$", "$1.jpg")
      let $user  := substring-before($fn, "/")
      let $rdfD  := $body/rdf:RDF/rdf:Description
      let $ns    := for $ns in $rdfD/namespace::*
                    where (string($ns) != "http://ns.exiftool.ca/File/System/1.0/"
                           and string($ns) != "http://ns.exiftool.ca/Photoshop/Photoshop/1.0/")
                    return
                      $ns
      let $width  := xs:integer($rdfD/File:ImageWidth)
      let $height := xs:integer($rdfD/File:ImageHeight)
      let $desc := <rdf:Description rdf:about="{$baseuri}"
                                    xmlns:npl="http://nwalsh.com/ns/photolib">
                     { $ns }
                     <npl:user>{$user}</npl:user>

                     { if (exists($rdfD/ExifIFD:DateTimeOriginal))
                       then
                         (: Some cameras, at least some phones, produce duplicate tags.
                            *Ugh* :)
                         let $exifdt := string($rdfD/ExifIFD:DateTimeOriginal[1])
                         let $exifd  := translate(substring-before($exifdt, " "), ":", "-")
                         let $exift  := substring-after($exifdt, " ")
                         return
                           (<npl:date>{ $exifd }</npl:date>,
                            <npl:datetime>{ concat($exifd, "T", $exift) }</npl:datetime>)
                       else
                         ()
                     }

                     { let $tags := if ($rdfD/XMP-dc:Subject/rdf:Bag)
                                    then
                                      for $tag in $rdfD/XMP-dc:Subject/rdf:Bag/rdf:li
                                      return
                                        string($tag)
                                    else if ($rdfD/XMP-dc:Subject)
                                         then string($rdfD/XMP-dc:Subject)
                                         else ()
                       return
                         f:classify($tags)
                     }

                     <npl:images>
                       <npl:small>
                         <npl:image>{f:image-fn("small", $fn)}</npl:image>
                         { let $factor := min((1, 500 div xs:float(max(($width, $height)))))
                           return
                             (<npl:width>{floor($width * $factor)}</npl:width>,
                              <npl:height>{floor($height * $factor)}</npl:height>)
                         }
                       </npl:small>
                       <npl:large>
                         <npl:image>{f:image-fn("large", $fn)}</npl:image>
                         <npl:width>{floor($width)}</npl:width>
                         <npl:height>{floor($height)}</npl:height>
                       </npl:large>
                       <npl:thumb>
                         <npl:image>{f:image-fn("thumb", $fn)}</npl:image>
                         { (: Using xs:decimal in $factor causes DECOVRFLW. WTF? :)
                         let $factor := 150.0 div xs:float($height)
                         return
                           (<npl:width>{floor($width * $factor)}</npl:width>,
                           <npl:height>{floor($height * $factor)}</npl:height>)
                         }
                       </npl:thumb>
                       <npl:square>
                         <npl:image>{f:image-fn("square", $fn)}</npl:image>
                         <npl:width>64</npl:width>
                         <npl:height>64</npl:height>
                       </npl:square>
                     </npl:images>

                     <npl:upload-timestamp>{$uploadts}</npl:upload-timestamp>

                     { if ($rdfD/GPS:GPSLatitude and $rdfD/GPS:GPSLongitude)
                       then
                         f:gps($rdfD)
                       else
                         ()
                     }

                     { let $icountry := upper-case($rdfD/IPTC:Country-PrimaryLocationName)
                       let $istate := $rdfD/IPTC:Province-State
                       let $icity := $rdfD/IPTC:City
                       let $country := $icountry
                       let $state   := if ($istate)
                                       then concat($istate,
                                                   if ($country) then ", " else "",
                                                   $country)
                                       else ""
                       let $city    := if ($icity)
                                       then
                                         concat($icity,
                                                if ($state) then ", " else "", $state,
                                                if (not($state) and $country)
                                                then concat(", ", $country) else "")
                                       else
                                         ()
                       where $icity or $istate or $icountry
                       return
                         (<npl:location>{string($icountry)}|{string($istate)}|{string($icity)}</npl:location>,
                          if ($country)
                          then <npl:country>{$country}</npl:country>
                          else (),
                          if ($state)
                          then <npl:province>{$state}</npl:province>
                          else (),
                          if ($city)
                          then <npl:city>{$city}</npl:city>
                          else ())
                     }

                     { $rdfD/* except ($rdfD/System:* | $rdfD/Photoshop:*) }
                   </rdf:Description>
      let $coll := if (exists($collection)) then concat($user, "/", $collection) else ()
      let $xmlperm := (xdmp:permission("weblog-editor", "update"),
                       if ($desc/npl:tag = "people" or $desc/npl:tag = "private")
                       then ()
                       else xdmp:permission("weblog-reader", "read"))
      return
        (xdmp:document-insert($uri, $desc, $xmlperm, $coll),
         concat("Meta  ", $baseuri))
