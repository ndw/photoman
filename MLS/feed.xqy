xquery version "1.0-ml";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace endpoints="http://nwalsh.com/ns/photoends"
       at "/endpoints.xqy";

import module namespace u="http://nwalsh.com/ns/modules/utils"
       at "utils.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace f="http://nwalsh.com/ns/functions";
declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace IPTC="http://ns.exiftool.ca/IPTC/IPTC/1.0/";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/";
declare namespace IFD0="http://ns.exiftool.ca/EXIF/IFD0/1.0/";
declare namespace composite="http://ns.exiftool.ca/Composite/1.0/";
declare namespace XMP-photoshop="http://ns.exiftool.ca/XMP/XMP-photoshop/1.0/";

declare option xdmp:mapping "false";

declare variable $params := rest:process-request(endpoints:request("/feed.xqy"));
declare variable $user   := map:get($params, "userid");
declare variable $userq  := cts:element-value-query(xs:QName("npl:user"), $user, ("exact"));

declare variable $tagname := xs:QName("npl:tag");
declare variable $datename := xs:QName("npl:date");

declare function f:show-taxonomy(
  $tags as element()+
)
{
  for $tag in $tags
  let $names := $tag//@name/string()
  let $evq   := cts:element-value-query($tagname, $names, ("exact"))
  let $count := xdmp:estimate(cts:search(/rdf:Description, cts:and-query(($evq,$userq))))
  where $count > 0
  order by u:tag-title($user, $tag/@name, false())
  return
    (<dt xmlns="http://www.w3.org/1999/xhtml">
       { if (count($tag/*) > 4)
         then attribute { fn:QName("", "class") } { "ex-closed" }
         else if (count($tag/*) = 0)
              then attribute { fn:QName("", "class") } { "ex-blank" }
              else attribute { fn:QName("", "class") } { "ex-open" }
       }
       <span class="btoggle">{"&#160;"}</span>
       <a class="plain" href="/tags/{$user}/{encode-for-uri($tag/@name)}">
         { u:tag-title($user, $tag/@name) }
       </a>
       { concat(" (", $count, ") ") }
     </dt>,
     if ($tag/*)
     then
       <dd xmlns="http://www.w3.org/1999/xhtml">
         { if (count($tag/*) > 4)
           then attribute { fn:QName("", "class") } { "ex-closed" }
           else ()
         }
         <dl class="taxonomy">
           { f:show-taxonomy($tag/*) }
         </dl>
       </dd>
     else
       ())
};

declare function f:show-sets(
  $sets as element()+
)
{
  for $set in $sets
  let $name := concat($user, "/", $set/@name)
  let $count := search:estimate(
                       search:parse(concat("user:", $user,
                                           " collection:""", $name, """"),
                                           $u:search-options))
  return
    (<dt xmlns="http://www.w3.org/1999/xhtml">
       { if (count($set/*) > 4)
         then attribute { fn:QName("", "class") } { "ex-closed" }
         else if (count($set/*) = 0)
              then attribute { fn:QName("", "class") } { "ex-blank" }
              else attribute { fn:QName("", "class") } { "ex-open" }
       }
       <span class="btoggle">{"&#160;"}</span>
       <a class="plain" href="/sets/{$user}/{$set/@name}">
         { u:set-title($user, $name, false()) }
       </a>
       ({$count})
     </dt>,
     if ($set/*)
     then
       <dd xmlns="http://www.w3.org/1999/xhtml">
         { if (count($set/*) > 4)
           then attribute { fn:QName("", "class") } { "ex-closed" }
           else ()
         }
         <dl>
           { f:show-sets($set/*) }
         </dl>
       </dd>
     else
       ())
};

let $search := search:search(concat("user:""", $user, """ sort:rdate"), $u:search-options)
let $photos := for $result in $search/search:result[1 to 30]
               return doc($result/@uri)/*
return
  <feed xmlns="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:dcterms="http://purl.org/dc/terms/"
        xml:lang="EN-us">
    <title>photos.nwalsh.com</title>
    <subtitle>
      { "Photographs from photos.nwalsh.com." }
    </subtitle>
    <link rel="alternate" type="text/html" href="http://photos.nwalsh.com/users/ndw"/>
    <link rel="self" href="http://photos.nwalsh.com/users/ndw/feed"/>
    <id>http://photos.nwalsh.com/users/ndw/feed</id>

    { let $date := xs:dateTime($photos[1]/npl:datetime)
      return
        <updated>{ adjust-dateTime-to-timezone($date, xs:dayTimeDuration("PT0H")) }</updated>
    }

    <author>
      <name>Norman Walsh</name>
    </author>

    { for $photo in $photos
      let $base := substring-before(xdmp:node-uri($photo), ".xml")
      let $date := xs:dateTime($photo/npl:datetime)
      let $date := adjust-dateTime-to-timezone($date, xs:dayTimeDuration("PT0H"))
      return
        <entry>
          <title>{string($photo/XMP-dc:Title)}</title>
          <link rel="alternate" type="text/html"
                href="http://photos.nwalsh.com{$base}"/>
          <id>http://photos.nwalsh.com{$base}</id>
          <published>{string($date)}</published>
          <updated>{string($date)}</updated>
          { for $tag in $photo/npl:tag
            return
              <dc:subject>{string($tag)}</dc:subject>
          }
          <summary type="xhtml">
            <div xmlns="http://www.w3.org/1999/xhtml">
              <p>{string($photo/XMP-dc:Title)}</p>
            </div>
          </summary>

          <content type="xhtml" xml:base="http://norman.walsh.name{$base}">
            <div xmlns="http://www.w3.org/1999/xhtml">
              <h1>{string($photo/XMP-dc:Title)}</h1>

              { if ($photo/npl:city)
                then
                  <div>Location: {string($photo/npl:city)}</div>
                else
                  ()
              }

              <div class="photo">
                <div class="image">
                  <img class="{u:photo-visibility($photo)}"
                         src="{$photo/npl:images/npl:small/npl:image}"/>
                </div>
              </div>

              <div class="credit">
                <h3>Credits</h3>
                <p>
                  { "Taken by ", u:user-title($photo/npl:user) }
                  { let $date := xs:date($photo/npl:date)
                    where exists($date)
                    return
                      (" on ",
                      format-date($date, "[D01] [MNn,*-3] [Y0001]"))
                  }
                  { if (exists($photo/IFD0:Model))
                    then
                      concat(" with a ", ($photo/IFD0:Model)[1], ".")
                    else
                      "."
                  }
                </p>
              </div>

              <div class="views">
                <div>Viewed {u:views($photo)} times.</div>
              </div>

              { if (count(xdmp:document-get-collections(xdmp:node-uri($photo))) > 0)
                then
                  <div class="sets">
                    <h3>Sets</h3>
                    <ul>
                      { for $set in xdmp:document-get-collections(xdmp:node-uri($photo))
                        return
                          <li>
                            { u:set-title($photo/npl:user, $set, false()) }
                          </li>
                      }
                    </ul>
                  </div>
                else
                  ()
             }

             { if ($photo/npl:tag)
               then
                 <div class="tags">
                   <h3>Tags</h3>
                   <ul>
                     { for $tag in $photo/npl:tag order by $tag
                       return
                         <li id="tag-{$tag}" class="tag {$tag/@class}">
                           {string($tag)}
                         </li>
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
                     { if ($photo/composite:GPSPosition)
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

             <div class="license">
               <p>This work is licensed under a
               <a rel="license" href="http://creativecommons.org/licenses/by-nc/3.0/">Creative
               Commons Attribution-NonCommercial 3.0 Unported License</a>.
               </p>
             </div>
            </div>
          </content>
        </entry>
    }
  </feed>

