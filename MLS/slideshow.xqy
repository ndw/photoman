xquery version "1.0-ml";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace endpoints="http://nwalsh.com/ns/photoends"
       at "/endpoints.xqy";

import module namespace maps="http://nwalsh.com/ns/photomap"
       at "/maps-osm.xqy";

import module namespace u="http://nwalsh.com/ns/modules/utils"
       at "utils.xqy";

declare namespace f="http://nwalsh.com/ns/functions";
declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/";
declare namespace ExifIFD="http://ns.exiftool.ca/EXIF/ExifIFD/1.0/";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace html="http://www.w3.org/1999/xhtml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $params := rest:process-request(endpoints:request("/photos.xqy"));

let $user     := map:get($params, "userid")
let $dstart   := map:get($params, "start-date")
let $dend     := map:get($params, "end-date")
let $tags     := map:get($params, "tag")
let $set      := map:get($params, "set")
let $country  := map:get($params, "country")
let $province := map:get($params, "province")
let $city     := map:get($params, "city")
let $xml      := map:get($params, "xml")
let $textq    := map:get($params, "q")

let $sort     := if (empty($set) and exists($tags))
                 then "sort:rdate"
                 else "sort:fdate"

let $q        := u:compose($params, $sort)
let $q        := if ($textq) then concat($textq, " ", $q) else $q
let $search   := search:search($q, $u:search-options)

(: For full-text queries, order by relevance; otherwise by URI ~= date :)
let $photos   := for $photo in $search/search:result
                 return doc($photo/@uri)/*

return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>photos.nwalsh.com: {$user}</title>
      <link rel="stylesheet" type="text/css" href="/css/base.css" />
      <link rel="stylesheet" type="text/css" href="/css/set.css" />
      <link rel="stylesheet" type="text/css" href="/css/slideshow.css" />
      <link rel="icon" href="/favicon.png" type="image/png" />
      <script type="text/javascript" src="/js/dbmodnizr.js"></script>
    </head>
  <body style="background: #617187; margin: 0px; overflow: hidden;">
    <script type="text/javascript" src="/js/jquery-1.7.1.min.js"></script>
    <script type="text/javascript" src="/js/jssor.slider.mini.js"></script>
    <script type="text/javascript" src="/js/slideshow.js"></script>

    <div class="slider1_wrapper2">
      <div class="slider1_wrapper1">
        <div id="slider1_container" class="slider1_container">
          <div u="loading" class="loading">
            <div class="loading_1">
            </div>
            <div class="loading_2">
            </div>
          </div>

          <div u="slides" class="slides1">
            { for $photo in $photos
              let $uri := string($photo/npl:images/npl:large/npl:image)
              return
                <div><img u="image" src="{$uri}" /></div>
            }
          </div>

          <span u="arrowleft" class="al" style="width: 55px; height: 55px; top: 162px; left: 8px;">
          </span>
          <span u="arrowright" class="ar" style="width: 55px; height: 55px; top: 162px; right: 8px">
          </span>
        </div>
      </div>
    </div>
  </body>
  </html>

