xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace endpoints="http://nwalsh.com/ns/photoends"
       at "/endpoints.xqy";

import module namespace u="http://nwalsh.com/ns/modules/utils"
       at "utils.xqy";

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

let $params   := rest:process-request(endpoints:request("/photo.xqy"))
let $uri      := map:get($params, "uri")
let $xml      := map:get($params, "xml")

let $xml      := if (ends-with($uri, ".xml")) then "rdf" else $xml
let $uri      := if (ends-with($uri, ".xml")) then $uri else concat($uri, ".xml")

let $size     := map:get($params, "size")
let $set      := map:get($params, "set")
let $tags     := map:get($params, "tag")
let $user     := map:get($params, "userid")
let $country  := map:get($params, "country")
let $province := map:get($params, "province")
let $city     := map:get($params, "city")
let $photo    := doc($uri)/*
let $lat      := $photo/geo:lat
let $lng      := $photo/geo:long
let $blackout := u:blackout($user, $photo/geo:lat, $photo/geo:long)
return
  if (not($xml))
  then
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>photos.nwalsh.com</title>
        <link rel="stylesheet" type="text/css" href="/css/base.css" />
        <link rel="stylesheet" type="text/css" href="/css/photo.css" />
        { if ($size = "large")
          then
            <link rel="stylesheet" type="text/css" href="/css/large-photo.css" />
          else
            ()
        }
        <link rel="icon" href="/favicon.png" type="image/png" />
        <script type="text/javascript" src="/js/dbmodnizr.js"></script>
        <script type="text/javascript" src="/js/jquery-1.7.1.min.js"></script>

        { if (exists($lat) and (u:admin() or not($blackout)))
          then
            (<style type="text/css">v\:* {{ behavior:url(#default#VML); }}</style>,
             <script type="text/javascript"
                     src="http://maps.google.com/maps/api/js?sensor=false">
             </script>,
             <script type="text/javascript" src="/js/mapping.js"></script>)
           else
             ()
        }
        { if (u:admin())
          then
            <script type="text/javascript" src="/js/actions.js"></script>
          else
            ()
        }
      </head>
      <body>
        <div class="header">
          <div class="breadcrumbs">
            <a href="/">photos.nwalsh.com</a>
            { " | " }
            <a href="/users/{$user}">{$user}</a>
          </div>

          <h1>
            {
              let $title := string($photo/XMP-dc:Title)
              return
                if (u:admin())
                then
                  (<input xmlns="http://www.w3.org/1999/xhtml"
                          type="hidden" id="photo-title-uri" value="{xdmp:node-uri($photo)}"/>,
                   <span xmlns="http://www.w3.org/1999/xhtml" id="photo-title"
                         class="editable">
                     { $title }
                   </span>)
                else
                  $title
            }
          </h1>

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
          <div class="photo">
            <div class="image">
              { if ($size = "large")
                then
                  <img class="{u:photo-visibility($photo)}"
                       src="{$photo/npl:images/npl:large/npl:image}"/>
                else
                  <a href="{$photo/@rdf:about}/large{
                    if (exists($set)) then concat('?set=',$set) else ''}">
                    <img class="{u:photo-visibility($photo)}"
                         src="{$photo/npl:images/npl:small/npl:image}"/>
                  </a>
              }
            </div>
          </div>
          <div class="sidebar">
            <div class="credit">
              <h3>Credits</h3>
              <p>
                { "Taken by ", u:user-title($photo/npl:user) }
                { let $date := xs:date($photo/npl:date)
                  where exists($date)
                  return
                    (" on ",
                     <a href="/dates/{$photo/npl:user}/{$date}" class="date" title="{$date}">
                       { format-date($date, "[D01] [MNn,*-3] [Y0001]") }
                     </a>)
                }
                { if (exists($photo/IFD0:Model))
                  then
                    concat(" with a ", $photo/IFD0:Model[1], ".")
                  else
                    "."
                }
              </p>
            </div>

{(:
            <div class="views">
              <div>Viewed {u:views($photo)} times.</div>
            </div>
:)}

            { if (u:admin())
              then
                let $visibility := u:photo-visibility($photo)
                return
                  <div class="visible">
                    <h3>Visibility</h3>
                    <form>
                      <input type="hidden" id="uri" name="uri" value="{$photo/@rdf:about}"/>
                      <select name="visible" id="visible">
                        <option value="public">
                          { if ($visibility = "public")
                            then attribute { fn:QName("","selected") } { "selected" }
                            else ()
                          }
                          { "Public" }
                        </option>
                        <option value="friends">Friends</option>
                        <option value="family">Family</option>
                        <option value="private">
                          { if ($visibility = "private")
                            then attribute { fn:QName("","selected") } { "selected" }
                            else ()
                          }
                          { "Private" }
                        </option>
                      </select>
                    </form>
                  </div>
              else
                ()
            }

            { if (exists($set))
              then
                let $query  := cts:collection-query($set)
                let $images := for $photo in cts:search(/rdf:Description, $query)
                               order by $photo/ExifIFD:CreateDate
                               return string($photo/@rdf:about)
                let $index  := index-of($images, string($photo/@rdf:about))
                return
                  <div class="otherphotos">
                    <h3>
                      { "Other photos in " }
                      <a href="{u:patch-uri2($params, (), (), false())}">
                        { u:set-title($user, $set) }
                      </a>
                    </h3>
                    { for $pos in ($index - 2 to $index + 2)
                      return
                        if ($pos < 1 or empty($images[$pos]))
                        then
                          <img src="/blank-square.gif" alt="No photo"/>
                        else
                          let $uri   := $images[$pos]
                          let $photo := doc(concat($uri, ".xml"))/*
                          return
                            <a href="{$uri}?set={$set}">
                              <img class="square {u:photo-visibility($photo)}"
                                   src="{$photo/npl:images/npl:square/npl:image}"/>
                            </a>
                    }
                  </div>
              else
                ()
            }

            { if (u:admin()
                  or exists($lat)
                  or exists($photo/npl:city)
                  or exists($photo/npl:country))
              then
                <div class="geo">
                  <h3>
                    { "Location" }
                    { if (exists($lat) and u:admin())
                      then
                        (" ", <a href="/ajax/del-geo?uri={xdmp:node-uri($photo)}">X</a>)
                      else
                        ()
                    }
                    { if (u:admin() and $blackout)
                      then " (blacked out)"
                      else ""
                    }
                  </h3>
                  { if (exists($lat) and (u:admin() or not($blackout)))
                    then
                      <div id="map">
                      </div>
                    else
                      ()
                  }
                  { if (u:admin())
                    then
                      let $parts := tokenize($photo/npl:location, '\|')
                      return
                        <form action="/ajax/set-location" method="post">
                          <input type="hidden" name="uri" value="{xdmp:node-uri($photo)}"/>
                          <input name="city" value="{$parts[3]}"
                                 placeholder="city" size="16"/>,
                          <input name="province" value="{$parts[2]}"
                                 placeholder="state/province" size="16"/>,
                          <input name="country" value="{$parts[1]}"
                                 placeholder="ctry" size="2"/>
                          <input type="submit" value="Set"/>
                        </form>
                    else
                      <div>
                        { string(($photo/npl:city, $photo/npl:province, $photo/npl:country)[1]) }
                      </div>
                  }
                </div>
              else
                ()
            }

            { if (count(xdmp:document-get-collections(xdmp:node-uri($photo))) > 0)
              then
                <div class="sets">
                  <h3>Sets</h3>
                  <ul>
                    { for $set in xdmp:document-get-collections(xdmp:node-uri($photo))
                      return
                        <li>
                          <a href="/sets/{$set}">
                            { u:set-title($photo/npl:user, $set, false()) }
                          </a>
                        </li>
                    }
                  </ul>
                </div>
              else
                ()
            }

            { if ($photo/npl:tag or u:admin())
              then
                <div class="tags">
                  <h3>Tags</h3>
                  <ul>
                    { for $tag in $photo/npl:tag order by $tag
                      return
                        <li id="tag-{$tag}" class="tag {$tag/@class}">
                          <a href="{u:patch-uri2($params, 'tag', $tag, true())}">
                            {string($tag)}
                          </a>
                          { if (u:admin() and not($tag/@class = 'tax'))
                            then
                              ("&#160;", <a class="deltag" href="#">&#x2717;</a>)
                            else
                              ()
                          }
                        </li>
                    }
                    { if (u:admin())
                      then
                        <li>
                          <input type="hidden" id="add-tag-uri" value="{xdmp:node-uri($photo)}"/>
                          <span id="add-tag" class="editable">
                            <i>add tag</i>
                          </span>
                        </li>
                      else
                        ()
                    }
                  </ul>
                </div>
              else
                ()
            }

            { if (exists($photo/composite:ShutterSpeed))
              then
                <div class="exif">
                  <h3>EXIF</h3>
                  <ul>
                    <li>{string($photo/IFD0:Model)}</li>
                    { if ($photo/composite:LensID)
                      then
                        <li>
                          { string($photo/composite:LensID) }
                        </li>
                      else
                        ()
                    }
                    <li>
                      { string($photo/composite:FocalLength35efl) }
                    </li>
                    <li>
                      { concat($photo/composite:ShutterSpeed,
                               "s at f/",
                               $photo/composite:Aperture)
                      }
                    </li>
                    { if ($photo/composite:DOF)
                      then
                        <li>
                          { concat("Depth of field: ",
                                   $photo/composite:DOF)
                          }
                        </li>
                      else
                        ()
                    }
                    { if ($photo/composite:GPSPosition and $photo/geo:lat
                          and (u:admin() or not($blackout)))
                      then
                        <li>
                          { concat("GPS: ",
                                   $photo/composite:GPSPosition)
                          }
                        </li>
                      else
                        ()
                    }
                  </ul>
                </div>
              else
                ()
            }

            { if ($size = "large")
              then
                <div class="license-large">
                  <h3>License</h3>
                  <p>
                    This work is licensed under a
                    <a rel="license" href="http://creativecommons.org/licenses/by-nc/3.0/">Creative
                    Commons Attribution-NonCommercial 3.0 Unported License</a>.
                  </p>
                  <p>To negotiate other terms or for prints, please contact
                     <a href="mailto:ndw@nwalsh.com">Norm</a> for details.</p>
                </div>
              else
                <div class="license">
                  <p>
                    This work is licensed under a
                    <a rel="license" href="http://creativecommons.org/licenses/by-nc/3.0/">Creative
                    Commons Attribution-NonCommercial 3.0 Unported License</a>.
                  </p>
                </div>
            }

{(:
            { if (u:admin())
              then
                <div>
                  <h3>Stats</h3>
                  { let $uri := substring-before($uri, ".xml")
                    return
                      xdmp:invoke("/stats.xqy",
                         (QName("","uri"), $uri),
                         <options xmlns="xdmp:eval">
                           <database>{xdmp:database("photoman-audit")}</database>
                         </options>)
                  }
                </div>
              else
                ()
            }
:)}

          </div>
        </div>

        { if (exists($lat) and (u:admin() or not($blackout)))
          then
            <script type="text/javascript">
  $(document).ready(function() {{
      showMapGroup([{{"lat": {xs:float($lat)},
                      "lng": {xs:float($lng)},
                      "title": "{string($photo/XMP-dc:Title)}",
                      "square": "{string($photo/npl:images/npl:square/npl:image)}"}}])
  }});
            </script>
          else
            ()
        }
      </body>
    </html>
  else
    if ($xml = "docbook")
    then
      <article xmlns="http://docbook.org/ns/docbook">
        <title>Images in DocBook</title>
        <figure role="photo">
          <title>{string($photo/XMP-dc:Title)}</title>
          <mediaobject>
            <imageobject>
              <imagedata fileref="http://photos.nwalsh.com{$photo/npl:images/npl:small/npl:image}"
                         width="{$photo/npl:images/npl:small/npl:width}"/>
            </imageobject>
          </mediaobject>
        </figure>
      </article>
    else
      $photo
