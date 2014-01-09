xquery version "1.0-ml";

module namespace maps="http://nwalsh.com/ns/photomap";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/";
declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare option xdmp:mapping "false";

declare function maps:head-elements(
) as element()*
{
  (<style type="text/css"
          xmlns="http://www.w3.org/1999/xhtml">v\:* {{ behavior:url(#default#VML); }}</style>,
   <script type="text/javascript"
           src="http://maps.google.com/maps/api/js?sensor=false"
           xmlns="http://www.w3.org/1999/xhtml">
   </script>,
   <script type="text/javascript" src="/js/mapping-google.js"
           xmlns="http://www.w3.org/1999/xhtml">
   </script>)

};

declare function maps:map-body(
  $user as xs:string,
  $photos as element()+
) as element()*
{
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
                         }});
     </script>)
};
