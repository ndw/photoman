xquery version "1.0-ml";

module namespace maps="http://nwalsh.com/ns/photomap";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/";
declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace gpx="http://www.topografix.com/GPX/1/1";

declare option xdmp:mapping "false";

declare function maps:head-elements(
) as element()*
{
  (<link rel="stylesheet" href="http://cdn.leafletjs.com/leaflet-0.7.1/leaflet.css"
         xmlns="http://www.w3.org/1999/xhtml" />,
   <script type="text/javascript"
           src="http://cdn.leafletjs.com/leaflet-0.7.1/leaflet.js"
           xmlns="http://www.w3.org/1999/xhtml">
   </script>,
   <script type="text/javascript" src="/js/mapping-osm.js"
           xmlns="http://www.w3.org/1999/xhtml">
   </script>)
};

declare function maps:map-body(
  $user as xs:string,
  $photos as element()+
) as element()*
{
  let $stamps  := for $f in $photos/npl:datetime return xs:dateTime($f)
  let $dtstart := xs:dateTime(string(min($stamps)) || "Z")
  let $dtend   := xs:dateTime(string(max($stamps)) || "Z")

  let $_dts    := xs:QName("npl:dtstart")
  let $_dte    := xs:QName("npl:dtend")

  (: contains start :)
  let $q1s     := cts:element-range-query($_dts, "<=", $dtstart)
  let $q1e     := cts:element-range-query($_dte, ">=", $dtstart)

  (: contains end :)
  let $q2s     := cts:element-range-query($_dts, "<=", $dtend)
  let $q2e     := cts:element-range-query($_dte, ">=", $dtend)

  (: wholly contains :)
  let $q3s     := cts:element-range-query($_dts, ">=", $dtstart)
  let $q3e     := cts:element-range-query($_dte, "<=", $dtend)

  let $dq      := cts:directory-query("/tracks/" || $user || "/", "infinity")

  let $q       := cts:and-query(
                     ($dq, cts:or-query(
                              (cts:and-query(($q1s, $q1e)),
                               cts:and-query(($q2s, $q2e)),
                               cts:and-query(($q3s, $q3e))))))

  let $tracks  := cts:search(collection("/gpx/trk"), $q)/*

  let $pts := for $photo in $photos
              return concat('{"lat": ', $photo/geo:lat,
                            ',"lng": ', $photo/geo:long,
                            ',"title": "', $photo/XMP-dc:Title, '"',
                            ',"uri": "', $photo/@rdf:about, '"',
                            ',"square": "', $photo/npl:images/npl:square/npl:image, '"',
                            '}')
  return
    (<div id="map" xmlns="http://www.w3.org/1999/xhtml"></div>,
     <script type="text/javascript" xmlns="http://www.w3.org/1999/xhtml">
       $(document).ready(function() {{
                           showMapGroup([{string-join($pts,",")}]);
                           { for $trk in $tracks
                             let $pts := for $pt in $trk/gpx:trkseg/gpx:trkpt
                                         return
                                           concat('{"lat": ', $pt/@lat,
                                                  ',"lng": ', $pt/@lon, '}')
                             return
                               concat("showTrack([", string-join($pts,","), "]);")
                           }
                         }});
     </script>)
};

declare function maps:track(
  $tracks as element(gpx:trk)*
)
{
  let $polylines := for $trk in $tracks
                    let $pts := for $pt in $trk/gpx:trkseg/gpx:trkpt
                                return
                                  concat('{"lat": ', $pt/@lat,
                                         ',"lng": ', $pt/@lon, '}')
                    return
                      concat("[", string-join($pts,","), "]")
  return
    (<div id="map" class="trackmap" xmlns="http://www.w3.org/1999/xhtml"></div>,
     <script type="text/javascript" xmlns="http://www.w3.org/1999/xhtml">
       $(document).ready(function() {{
                           setupMap();
                           { for $trk in $tracks
                             let $pts := for $pt in $trk/gpx:trkseg/gpx:trkpt
                                         return
                                           concat('{"lat": ', $pt/@lat,
                                                  ',"lng": ', $pt/@lon, '}')
                             return
                               concat("showTrack([", string-join($pts,","), "]);")
                           }
                         }});
   </script>)
};
