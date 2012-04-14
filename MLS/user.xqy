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
declare namespace XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/";

declare option xdmp:mapping "false";

declare variable $params := rest:process-request(endpoints:request("/user.xqy"));
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
return
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>photos.nwalsh.com: {$user}</title>
    <link rel="stylesheet" type="text/css" href="/css/base.css" />
    <link rel="stylesheet" type="text/css" href="/css/user.css" />
    <link rel="icon" href="/favicon.png" type="image/png" />
    <link rel="alternate" type="application/atom+xml" title="Atom feed"
          href="http://photos.nwalsh.com/users/{$user}/feed" />
    <script type="text/javascript" src="/js/dbmodnizr.js"></script>
    <script type="text/javascript" src="/js/jquery-1.7.1.min.js"></script>
    <script type="text/javascript" src="/js/functions.js"></script>
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
      <h1>{u:user-title($user, u:admin())}
      ({search:estimate(search:parse(concat("user:",$user), $u:search-options))}
      photos)
      </h1>

      <div id="searchbox">
        <form action="/images/{$user}" method="get">
          <label for="q">Search</label>: <input type="input" name="q" size="30" width="128"/>
          <input type="submit" value="Go"/>
        </form>
      </div>

      { if (exists(u:user-description($user)))
        then
          <div class="abstract">
            { u:user-description($user) }
          </div>
        else
          ()
      }

    </div>
    <div class="content">
    <table width="100%" border="0">
      <tr>
        <td valign="top" width="25%" rowspan="2">
          <h3>Sets</h3>
          <dl>
            { let $setxml := doc(concat("/etc/", $user, "/sets.xml"))
              let $sets   := for $set in $setxml//@name return concat($user,"/", $set)
              let $newsets := for $set in cts:collections((), (), $userq)
                              where not($set = $sets)
                              return
                                $set
              return
                (for $set in $newsets
                 let $count := search:estimate(
                                 search:parse(concat("user:", $user,
                                                     " collection:""", $set, """"),
                                              $u:search-options))
                 return
                   <dt>
                     <a class="plain" href="/sets/{$user}/{$set}">
                       { u:set-title($user, $set, false()) }
                     </a>
                     ({$count})
                   </dt>,
                 f:show-sets($setxml/*/*))
            }
          </dl>
        </td>

        { let $taxonomy := doc(concat("/etc/", $user, "/taxonomy.xml"))/*
          let $tags := cts:element-values($tagname, (), ("collation=http://marklogic.com/collation/codepoint"), $userq)
          return
            if (empty($tags))
            then
              <td width="25%" rowspan="2">&#160;</td>
            else
              <td valign="top" width="25%" rowspan="2">
                <h3>Tags</h3>
                <dl class="taxonomy">
                  { f:show-taxonomy($taxonomy/*) }
                </dl>
              </td>
        }

        <td valign="top" width="25%">
          <h3>Locations</h3>
          { u:show-locations($params, $search,
                             $search/search:facet[@name='location']/search:facet-value/@name)
          }
        </td>

        <td valign="top" width="25%">
          <h3>Dates</h3>
          <dl>
            { let $dates   := cts:element-values($datename, (), (), $userq)
              (: Ignore 1970, those are the unrecorded ones :)
              let $first   := if (year-from-date($dates[1]) = 1970)
                              then year-from-date($dates[2])
                              else year-from-date($dates[1])
              let $last    := year-from-date($dates[last()])
              for $year in ($first to $last)
              order by $year descending
              return
                (let $first := xs:date(concat($year,"-01-01"))
                 let $last  := xs:date(concat($year,"-12-31"))
                 let $q     := concat("((date GE ",$first,") AND (date LE ",$last,"))")
                 let $count := search:estimate(search:parse($q, $u:search-options))
                 return
                   <dt>
                     <a href="/dates/{$user}/{$year}" class="plain">{$year}</a>
                     ({$count})
                   </dt>,
                 <dd>
                   <dl>
                     { for $month in (1 to 12)
                       let $first := xs:date(concat($year,"-",
                                                    if ($month < 10) then "0" else "",
                                                    $month,"-","01"))
                       let $last  := $first
                                     + xs:yearMonthDuration("P1M")
                                     - xs:dayTimeDuration("P1D")
                       let $q     := concat("((date GE ",$first,") AND (date LE ",$last,"))")
                       let $count := search:estimate(search:parse($q, $u:search-options))
                       where $count != 0
                       order by $month descending
                       return
                         <dt>
                           <a href="/dates/{$user}/{substring(string($first),1,7)}"
                              class="plain">
                             {format-date($first,"[MNn]")}
                           </a>
                           ({$count})
                         </dt>
                     }
                   </dl>
                 </dd>)
            }
          </dl>
        </td>
        <td valign="top" width="70" rowspan="2">
          <h3>Recent</h3>
          { for $result in $search/search:result[1 to 40]
            let $photo := doc($result/@uri)/*
            return
              (<a href="{$photo/@rdf:about}">
                <img src="{$photo/npl:images/npl:square/npl:image}" alt="[T]"
                     class="{if (u:photo-visibility($photo) = 'private')
                             then 'uthumb private' else 'uthumb'}"
                     title="{$photo/XMP-dc:Title}"/>
              </a>,
              <br/>)
          }
          { "..." }
        </td>

      </tr>

      <tr>
        <td colspan="2" valign="top">
          <h3 style="margin-top: 1em;">Popular</h3>
          <table>
            <tr>
              { for $value in $search/search:facet[@name="total"]/search:facet-value[1 to 5]
                let $docs := cts:search(/rdf:Description,
                                 cts:element-value-query(xs:QName("npl:total"), string($value)))
                for $doc in $docs
                return
                  <td align="center">
                    <a href="{$doc/@rdf:about}">
                      <img src="{$doc/npl:images/npl:square/npl:image}" alt="[T]"/>
                    </a>
                    <br/>
                    ({$value})
                  </td>
              }
            </tr>
          </table>
        </td>
      </tr>
    </table>
    </div>
  </body>
</html>
