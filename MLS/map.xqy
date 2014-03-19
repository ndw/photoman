xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace endpoints="http://nwalsh.com/ns/photoends"
       at "/endpoints.xqy";

import module namespace u="http://nwalsh.com/ns/modules/utils"
       at "utils.xqy";

import module namespace maps="http://nwalsh.com/ns/photomap"
       at "/maps-osm.xqy";

declare namespace f="http://nwalsh.com/ns/functions";
declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/";
declare namespace ExifIFD="http://ns.exiftool.ca/EXIF/ExifIFD/1.0/";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace IFD0="http://ns.exiftool.ca/EXIF/IFD0/1.0/";
declare namespace composite="http://ns.exiftool.ca/Composite/1.0/";
declare namespace XMP-photoshop="http://ns.exiftool.ca/XMP/XMP-photoshop/1.0/";
declare namespace IPTC="http://ns.exiftool.ca/IPTC/IPTC/1.0/";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

let $params   := rest:process-request(endpoints:request("/map.xqy"))
let $user     := map:get($params, "userid")
let $lat      := map:get($params, "lat")
let $lng      := map:get($params, "lng")
let $res      := map:get($params, "res")

return
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>photos.nwalsh.com</title>
        <link rel="stylesheet" type="text/css" href="/css/base.css" />
        <link rel="stylesheet" type="text/css" href="/css/photo.css" />
        <link rel="icon" href="/favicon.png" type="image/png" />
        <script type="text/javascript" src="/js/dbmodnizr.js"></script>
        <script type="text/javascript" src="/js/jquery-1.7.1.min.js"></script>

        { maps:head-elements() }

        <style type="text/css">#map {{ width: 100%; height: 100% }}</style>
        <meta name="viewport" content="width=device-width,initial-scale=1"/>
        <link rel="stylesheet" type="text/css" href="/css/pure-min.css" />
      </head>

      <body>
        <div class="header">
          <div class="breadcrumbs">
            <a href="/">photos.nwalsh.com</a>
            { " | " }
            <a href="/users/{$user}">{$user}</a>
          </div>
        </div>

        {
          let $center := cts:point($lat, $lng)
          let $circle := cts:circle(3, $center)
          let $query  := cts:element-pair-geospatial-query(
                            xs:QName("rdf:Description"),
                            xs:QName("geo:lat"),
                            xs:QName("geo:long"),
                            $circle)
          let $geo    := cts:search(/rdf:Description, $query)
          return
            maps:map-body($user, $geo)
        }
      </body>
    </html>
