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

declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/";
declare namespace npl="http://nwalsh.com/ns/photolib";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

let $search   := search:search("recent:30-days", $u:search-options)
return
  <feed xmlns="http://www.w3.org/2005/Atom" xml:lang="EN-us"
        xmlns:aex="http://nwalsh.com/ns/atom/extension">
    <title>Recent photographs</title>
    <link rel="alternate" type="text/html" href="http://photos.nwalsh.com/"/>
    <link rel="self" href="http://photos.nwalsh.com/atom.xqy"/>
    <id>http://photos.nwalsh.com/atom</id>
    <updated>{current-dateTime()}</updated>
    <author>
      <name>Norman Walsh</name>
    </author>
    { for $result in $search/search:result
      let $photo := doc($result/@uri)/*
      let $uri   := substring-before(xdmp:node-uri($photo), ".xml")
      let $path  := replace($uri, "^(.*/)[^/]+", "$1")
      let $name  := replace($uri, "^.*/([^/]+)", "$1")
      let $uri   := concat("http://photos.nwalsh.com", $uri)
      let $title := string($photo/XMP-dc:Title)
      order by $photo/npl:datetime descending
      return
        <entry>
          <title>{$title}</title>
          <link rel="alternate" type="text/html" href="{$uri}"/>
          <id>{$uri}</id>
          {(: Z is a lie :)}
          { let $dt := xs:dateTime($photo/npl:datetime)
            let $dz := adjust-dateTime-to-timezone($dt, xs:dayTimeDuration("PT0H"))
            return
              (<published>{string($dz)}</published>,
               <updated>{string($dz)}</updated>)
          }
          <aex:kind>photos.nwalsh.com photo</aex:kind>
          <summary type="xhtml">
            <div xmlns="http://www.w3.org/1999/xhtml">
              <img src="{$photo/npl:images/npl:thumb/npl:image}"
                   class="thumbnail" alt="{$title}"/>
              { $title }
            </div>
          </summary>
        </entry>
    }
  </feed>

