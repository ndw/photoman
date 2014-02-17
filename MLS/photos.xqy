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

declare function f:patch-uri(
  $name as xs:string,
  $value as xs:string
) as xs:string
{
  u:patch-uri2($params, $name, $value, false())
};

declare function f:patch-uri(
  $name as xs:string,
  $value as xs:string,
  $repeat as xs:boolean
) as xs:string
{
  u:patch-uri2($params, $name, $value, $repeat)
};

declare private function f:loclink(
  $search as element(search:response),
  $params as map:map,
  $country as xs:string,
  $state as xs:string?,
  $city as xs:string?
) as element(html:span)
{
  let $seq := (if ($city = "") then () else $city,
               if ($state = "") then () else $state,
               if ($country = "") then () else $country)
  let $key := string-join($seq, ", ")
  let $facet := if (exists($city) and $city != "")
                then $search/search:facet[@name='city']/search:facet-value[@name=$key]
                else if (exists($state) and $state != "")
                     then $search/search:facet[@name='province']/search:facet-value[@name=$key]
                     else $search/search:facet[@name='country']/search:facet-value[@name=$key]
  let $uri := if ($city = "" or empty($city))
              then
                if ($state = "" or empty($state))
                then
                  f:patch-uri("country", $key)
                else
                  f:patch-uri("province", $key)
              else
                f:patch-uri("city", $key)

  let $chk := if ($city = "" or empty($city))
              then
                if ($state = "" or empty($state))
                then
                  $key = map:get($params, "country")
                else
                  $key = map:get($params, "province")
              else
                $key = map:get($params, "city")

  return
    if ($state = "" and empty($city))
    then
      <span xmlns="http://www.w3.org/1999/xhtml"></span>
    else
      <span xmlns="http://www.w3.org/1999/xhtml">
        <a href="{$uri}" class="plain">
          { $seq[1] }
        </a>
        ({string($facet/@count)})
        { if ($chk)
          then " &#x2714;"
          else ""
        }
      </span>
};

declare function f:page-navigation(
  $search as element(search:response)
)
{
  let $start  := xs:integer($search/@start)
  let $plen   := xs:integer($search/@page-length)
  let $total  := xs:integer($search/@total)
  let $page   := (($start - 1) idiv $plen) + 1
  let $tpages := floor(($total + $plen - 1) div $plen)

  let $over1  := min((3, $tpages)) + 1 >= max((1, $page - 2))
  let $over2  := min(($page + 2, $tpages)) + 1 >= max((1, $tpages - 2))

  let $range1 := if ($over1) then () else (1 to min((3, $tpages)))
  let $range2 := if ($over1)
                 then (1 to min(($page + 2, $tpages)))
                 else (max((1, $page - 2)) to min(($page + 2, $tpages)))
  let $sep1   := if ($over1) then () else "…"

  let $range3 := if ($over2)
                 then ($range2[1] to $tpages)
                 else (max((1, $tpages - 2)) to $tpages)

  let $range2 := if ($over2) then () else $range2
  let $sep2   := if ($over2) then () else "…"

  let $pages  := ($range1, $sep1, $range2, $sep2, $range3)
  (: let $trace  := xdmp:log($search) :)
  return
    (<div xmlns="http://www.w3.org/1999/xhtml" class="navigation">
       {
         if ($total = 1)
         then "One photo"
         else concat("Photos ", $start, " to ", min(($total, $start + $plen - 1)),
                     " of ", $total)
       }
       <br/>
       { if ($total > $plen)
         then
           ("Pages: ",
            for $pg at $index in $pages
            return
              (if ($index > 1) then ", " else "",
               if (string($pg) = "…")
               then
                 $pg
               else
                 if ($pg = $page)
                 then
                   <span>{ $pg }</span>
                 else
                   <a href="{f:patch-uri('page', string($pg))}" class="plain">
                     { $pg }
                   </a>))
           else
             ()
       }
     </div>)
};

let $user     := map:get($params, "userid")
let $dstart   := map:get($params, "start-date")
let $dend     := map:get($params, "end-date")
let $page     := map:get($params, "page")
let $tags     := map:get($params, "tag")
let $set      := map:get($params, "set")
let $country  := map:get($params, "country")
let $province := map:get($params, "province")
let $city     := map:get($params, "city")
let $xml      := map:get($params, "xml")
let $textq    := map:get($params, "q")
let $q        := u:compose($params)
let $q        := if ($textq) then concat($textq, " ", $q) else $q
let $agent    := xdmp:get-request-header("User-Agent", "")
let $trace    := if (contains($agent, "Googlebot")) then ()
                 else xdmp:log(concat("photos q: ", $q, " (", $agent, ")"))
let $start    := (($page - 1) * $u:photos-per-page) + 1
let $search   := search:search($q, $u:search-options,$start)

(: For full-text queries, order by relevance; otherwise by URI ~= date :)
let $photos   := if (empty($textq))
                 then
                   for $photo in $search/search:result
                   order by $photo/@uri
                   return doc($photo/@uri)/*
                 else
                   for $photo in $search/search:result
                   return doc($photo/@uri)/*

return
  if (not($xml))
  then
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>photos.nwalsh.com: {$user}</title>
        <link rel="stylesheet" type="text/css" href="/css/base.css" />
        <link rel="stylesheet" type="text/css" href="/css/set.css" />
        <link rel="icon" href="/favicon.png" type="image/png" />
        <script type="text/javascript" src="/js/dbmodnizr.js"></script>
        <script type="text/javascript" src="/js/jquery-1.7.1.min.js"></script>
        { maps:head-elements() }
        { if (u:admin())
          then
            <script type="text/javascript" src="/js/actions.js"></script>
          else
            ()
        }
      </head>
      <body>
        <div class="header">
          { u:breadcrumbs($user) }
          <h1>
            { if (exists($set))
              then
                u:set-title($user, concat($user, "/", $set), u:admin())
              else
                if ($textq)
                then
                  $textq
                else
                  "Images"
            }
          </h1>

          { if (exists($set))
            then
              u:set-description($user, $set)
            else
              ()
          }

          { if (exists($tags))
            then
              <div>Tagged:
                { if (count($tags) = 1)
                  then
                    u:tag-title($user, $tags, u:admin())
                  else
                    string-join(for $tag in $tags return u:tag-title($user, $tag), ", ")
                }
              </div>
            else
              ()
          }

          { if (exists($country) or exists($province) or exists($city))
            then
              <div>Location:
                { ($city, $province, $country)[1] }
              </div>
            else
              ()
          }
        </div>
        <div class="content">
          <div class="photos">
            { u:show-photos($params, $photos, (), ()) }
            { f:page-navigation($search) }
          </div>
          <div class="sidebar">
            { f:page-navigation($search),

                 let $geo := for $photo in $photos[geo:lat]
                             where u:admin() or not(u:blackout($photo/npl:user,
                                                               $photo/geo:lat, $photo/geo:long))
                             return
                               $photo
                 let $locations := $search/search:facet[@name='location']/search:facet-value
                 where $geo or $locations
                 return
                   <div xmlns="http://www.w3.org/1999/xhtml" class="geo">
                     <h3>Locations</h3>
                     { if ($geo)
                       then
                         maps:map-body($user, $geo)
                       else
                         ()
                     }
                     { if ($locations)
                       then
                         u:show-locations($params, $search, $locations/@name)
                       else
                         ()
                     }
                   </div>,

                 let $sets := $search/search:facet[@name='collection']/search:facet-value
                 let $set-sets := map:get($params, "set")
                 where exists($sets)
                 return
                   <div xmlns="http://www.w3.org/1999/xhtml" class="sets">
                     <h3>Sets</h3>
                     <ul>
                       { for $set in $sets
                         return
                           <li>
                             <a href="/sets/{$set}"
                                class="plain">
                               { u:set-title($user, $set/@name, false()) }
                             </a>
                             ({string($set/@count)})
                             { if ($set/@name = $set-sets)
                               then " &#x2714;"
                               else ""
                             }
                           </li>
                       }
                     </ul>
                   </div>,

                   if (exists($search/search:facet[@name='tag']/search:facet-value))
                   then
                     <div xmlns="http://www.w3.org/1999/xhtml" class="tags">
                       <h3>Tags</h3>
                       { u:show-tags($params,
                                     $search/search:facet[@name='tag']/search:facet-value) }
                     </div>
                   else
                     (),

                  if ($search/search:facet[@name='date']/search:facet-value)
                  then
                    let $sdate  := xs:date($search/search:facet[@name='date']/search:facet-value[1]/@name)
                    let $edate  := xs:date($search/search:facet[@name='date']/search:facet-value[last()]/@name)
                    let $sfirst := xs:date(concat(substring(string($sdate), 1, 7), "-01"))
                    let $efirst := xs:date(concat(substring(string($edate), 1, 7), "-01"))
                    let $next   := $sfirst + xs:yearMonthDuration("P1M")
                    let $nexty  := $sfirst + xs:yearMonthDuration("P1Y")
                    return
                      <div xmlns="http://www.w3.org/1999/xhtml" class="tags">
                        <h3>Dates</h3>
                        { if ($sfirst = $efirst)
                          then u:oneMonth($params, $search, $sfirst)
                          else if ($next = $efirst)
                               then u:twoMonths($params, $search, $sfirst, $efirst)
                               else if ($nexty > $efirst)
                                    then u:oneYear($search, $sfirst, $edate)
                                    else u:severalYears($search, $sfirst, $efirst)
                        }
                      </div>
                  else
                    ()
            }
          </div>
        </div>
        <script src="/js/flexie.min.js" type="text/javascript"></script>
      </body>
    </html>
  else
    <article xmlns="http://docbook.org/ns/docbook">
      <title>Images in DocBook</title>
      { for $photo in $photos
        return
          <figure role="photo">
            <title>{string($photo/XMP-dc:Title)}</title>
            <mediaobject>
              <imageobject>
                <imagedata fileref="http://photos.nwalsh.com{$photo/npl:images/npl:small/npl:image}"
                           width="{$photo/npl:images/npl:small/npl:width}"/>
              </imageobject>
            </mediaobject>
          </figure>
      }
    </article>
