xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace endpoints="http://nwalsh.com/ns/photoends"
       at "/endpoints.xqy";

import module namespace u="http://nwalsh.com/ns/modules/utils"
       at "utils.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace gpx="http://www.topografix.com/GPX/1/1";
declare namespace gpx10="http://www.topografix.com/GPX/1/0";
declare namespace f="http://nwalsh.com/ns/functions";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare option xdmp:mapping "false";

declare variable $permissions := (xdmp:permission("weblog-reader", "read"),
                                  xdmp:permission("weblog-editor", "update"));

declare variable $params := rest:process-request(endpoints:request("/upload-track.xqy"));

declare function local:upload(
  $trks as element(gpx:trk)+
)
{
  for $trk in $trks
  (: xs:dateTime just for validity checking :)
  let $dtstart := string(xs:dateTime($trk/gpx:trkseg[1]/gpx:trkpt[1]/gpx:time))
  let $dtend   := string(xs:dateTime($trk/gpx:trkseg[last()]/gpx:trkpt[last()]/gpx:time))
  let $lats    := for $lat in $trk/gpx:trkseg/gpx:trkpt/@lat return xs:float($lat)
  let $lngs    := for $lon in $trk/gpx:trkseg/gpx:trkpt/@lon return xs:float($lon)
  let $date    := substring($dtstart, 1, 10)
  let $uri     := "/tracks/ndw/"
                  || replace($dtstart,":","-") || "_" || replace($dtend,":","-")
                  || ".xml"
  let $xml     := <trk xmlns="http://www.topografix.com/GPX/1/1"
                       xmlns:npl="http://nwalsh.com/ns/photolib">
                    <npl:date>{$date}</npl:date>
                    <npl:dtstart>{$dtstart}</npl:dtstart>
                    <npl:dtend>{$dtend}</npl:dtend>
                    <npl:minlat>{min($lats)}</npl:minlat>
                    <npl:minlng>{min($lngs)}</npl:minlng>
                    <npl:maxlat>{max($lats)}</npl:maxlat>
                    <npl:maxlng>{max($lngs)}</npl:maxlng>
                    { $trk/* }
                  </trk>
  return
    xdmp:document-insert($uri, $xml, $permissions, "/gpx/trk")
};

declare function local:cleanup(
  $trks as element(gpx:trk)+
) as element(gpx:trk)*
{
  for $trk in $trks
  return
    <trk xmlns="http://www.topografix.com/GPX/1/1">
      { $trk/*[not(self::gpx:trkseg)] }
      { for $seg in $trk/gpx:trkseg[gpx:trkpt]
        return
          <trkseg xmlns="http://www.topografix.com/GPX/1/1">
            { local:remove-duplicates($seg/gpx:trkpt) }
          </trkseg>
      }
    </trk>
};

declare function local:remove-duplicates(
  $pts as element(gpx:trkpt)+
) as element(gpx:trkpt)+
{
  $pts[1],
  for $pt in (2 to count($pts))
  where not(local:same-point($pts[$pt - 1], $pts[$pt]))
  return
    $pts[$pt]
};

declare function local:same-point(
  $pt1 as element(gpx:trkpt),
  $pt2 as element(gpx:trkpt)
) as xs:boolean
{
  (string($pt1/@lat) = string($pt2/@lat)
   and string($pt1/@lon) = string($pt2/@lon))
};

declare function local:convert(
  $body as element(gpx10:gpx)
) as element(gpx:gpx)
{
  xdmp:xslt-invoke("/gpx10to11.xsl", document { $body })/*
};

if (not(u:admin()))
then
  xdmp:set-response-code(401, "Denied")
else
  let $body  := xdmp:get-request-body("xml")
  let $gpx   := if ($body/gpx10:gpx)
                then local:convert($body/gpx10:gpx)
                else $body/gpx:gpx
  let $clean := local:cleanup($gpx/gpx:trk[gpx:trkseg/gpx:trkpt])
  return
    local:upload($clean)
