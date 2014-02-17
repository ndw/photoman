xquery version "1.0-ml";

module namespace utils="http://nwalsh.com/ns/modules/utils";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

import module namespace sec="http://marklogic.com/xdmp/security"
       at "/MarkLogic/security.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace XMP-dc="http://ns.exiftool.ca/XMP/XMP-dc/1.0/";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace IPTC="http://ns.exiftool.ca/IPTC/IPTC/1.0/";

declare option xdmp:mapping "false";

declare variable $REALWIDTH := 600;
declare variable $MAXWIDTH := 800;

declare variable $DAYS := ("Sunday", "Monday", "Tuesday", "Wednesday",
                           "Thursday", "Friday", "Saturday");

declare variable $MONTHS := ("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                             "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");

declare variable $utils:photos-per-page := 72;

declare variable $utils:search-options
  := <options xmlns="http://marklogic.com/appservices/search">
       <searchable-expression xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
         { "/rdf:Description" }
       </searchable-expression>
       <search-option>unfiltered</search-option>
       <constraint name="collection">
         <collection prefix=""/>
       </constraint>
       <constraint name="user">
         <value>
           <element ns="http://nwalsh.com/ns/photolib" name="user"/>
         </value>
       </constraint>
       <constraint name="tag">
         <range type="xs:string" facet="true" collation="http://marklogic.com/collation/en/S1/T0020/AS/MO">
           <element ns="http://nwalsh.com/ns/photolib" name="tag"/>
         </range>
       </constraint>
       <constraint name="date">
         <range type="xs:date" facet="true">
           <element ns="http://nwalsh.com/ns/photolib" name="date"/>
         </range>
       </constraint>
       <constraint name="total">
         <range type="xs:int" facet="true">
           <element ns="http://nwalsh.com/ns/photolib" name="total"/>
           <facet-option>descending</facet-option>
         </range>
       </constraint>
       <constraint name="country">
         <range type="xs:string" facet="true">
           <element ns="http://nwalsh.com/ns/photolib" name="country"/>
         </range>
       </constraint>
       <constraint name="province">
         <range type="xs:string" facet="true">
           <element ns="http://nwalsh.com/ns/photolib" name="province"/>
         </range>
       </constraint>
       <constraint name="city">
         <range type="xs:string" facet="true">
           <element ns="http://nwalsh.com/ns/photolib" name="city"/>
         </range>
       </constraint>
       <constraint name="location">
         <range type="xs:string" facet="true">
           <element ns="http://nwalsh.com/ns/photolib" name="location"/>
         </range>
       </constraint>
       <constraint name="geo">
         <geo-elem-pair>
           <heatmap s="-90" n="90" e="180" w="-180" latdivs="360" londivs="360"/>
           <parent ns="http://www.w3.org/1999/02/22-rdf-syntax-ns#" name="Description"/>
           <lat ns="http://www.w3.org/2003/01/geo/wgs84_pos#" name="lat"/>
           <lon ns="http://www.w3.org/2003/01/geo/wgs84_pos#" name="long"/>
         </geo-elem-pair>
       </constraint>
       <constraint name="viewed">
         <range type="xs:date" facet="true">
           <element ns="http://nwalsh.com/ns/photolib" name="view"/>
           <attribute ns="" name="date"/>
           <computed-bucket name="D0" ge="P0D"  lt="P1D" anchor="start-of-day"/>
           <computed-bucket name="D1" ge="-P1D" lt="P0D" anchor="start-of-day"/>
           <computed-bucket name="D2" ge="-P2D" lt="-P1D" anchor="start-of-day"/>
           <computed-bucket name="D3" ge="-P3D" lt="-P2D" anchor="start-of-day"/>
           <computed-bucket name="D4" ge="-P4D" lt="-P3D" anchor="start-of-day"/>
           <computed-bucket name="D5" ge="-P5D" lt="-P4D" anchor="start-of-day"/>
           <computed-bucket name="D6" ge="-P6D" lt="-P5D" anchor="start-of-day"/>
         </range>
       </constraint>
       <operator name="sort">
         <state name="uri">
           <sort-order direction="ascending" type="xs:string"
                       collation="http://marklogic.com/collation/codepoint">
             <attribute ns="http://www.w3.org/1999/02/22-rdf-syntax-ns#" name="about"/>
             <element ns="http://www.w3.org/1999/02/22-rdf-syntax-ns#" name="Description"/>
           </sort-order>
         </state>
         <state name="date">
           <sort-order direction="ascending" type="xs:string"
                       collation="http://marklogic.com/collation/codepoint">
             <element ns="http://ns.exiftool.ca/EXIF/ExifIFD/1.0/" name="CreateDate"/>
           </sort-order>
         </state>
         <state name="rdate">
           <sort-order direction="descending" type="xs:dateTime">
             <element ns="http://nwalsh.com/ns/photolib" name="datetime"/>
           </sort-order>
         </state>
         <state name="uploaded">
           <sort-order direction="descending" type="xs:unsignedLong">
             <element ns="http://nwalsh.com/ns/photolib" name="upload-timestamp"/>
           </sort-order>
         </state>
       </operator>
       <transform-results apply="empty-snippet"/>
       <page-length>{$utils:photos-per-page}</page-length>
     </options>;

declare function utils:admin()
as xs:boolean
{
  xdmp:has-privilege("http://norman.walsh.name/ns/priv/weblog-update", "execute")
};

declare function utils:breadcrumbs(
  $user as xs:string?
) {
  <div xmlns="http://www.w3.org/1999/xhtml"
       class="breadcrumbs">
    <a href="/" class="plain">photos.nwalsh.com</a>
    { if (exists($user))
      then
        (" | ", <a href="/users/{$user}" class="plain">{$user}</a>)
      else
        ()
    }
    <span id="vresult"></span>
  </div>
};

declare function utils:show-tags(
  $params as map:map,
  $tags as element(search:facet-value)+
)
{
  let $user  := map:get($params, "userid")
  let $taxonomy := doc(concat("/etc/", $user, "/taxonomy.xml"))/*
  let $names := for $tag in $tags return string($tag/@name)
  let $tax   := <taxonomy>
                  { utils:filter-taxonomy($taxonomy/*, $names) }
                </taxonomy>
  let $extra := for $name in $names
                where empty($tax//*[@name = $name])
                return
                  <tag name="{$name}"/>

  return
    <dl xmlns="http://www.w3.org/1999/xhtml">
      { for $tag in ($tax/*, $extra)
        order by $tag/@name
        return
          utils:show-tree($params, $tag, $user, $tags, map:get($params, "tag"))
      }
    </dl>
};

declare private function utils:show-tree(
  $params as map:map,
  $tag as element(),
  $user as xs:string,
  $tags as element(search:facet-value)+,
  $set-tags as xs:string*
)
{
  let $value := $tags[@name = $tag/@name]
  return
    (<dt xmlns="http://www.w3.org/1999/xhtml">
       <a href="{utils:patch-uri2($params, 'tag', $tag/@name, true())}" class="plain">
         {utils:tag-title($user, $tag/@name, false())}
       </a>
       ({string($value/@count)})
       { if ($tag/@name = $set-tags)
         then " &#x2714;"
         else ""
       }
     </dt>,
     if ($tag/*)
     then
       <dd xmlns="http://www.w3.org/1999/xhtml">
         <dl>
           { for $tag in $tag/*
             order by $tag/@name
             return
               utils:show-tree($params, $tag, $user, $tags, $set-tags)
           }
         </dl>
       </dd>
     else
       ())
};

declare private function utils:filter-taxonomy(
  $roots as element()*,
  $names as xs:string+
)
{
  for $root in $roots
  where utils:branch-contains($root, $names)
  return
    <tag name="{$root/@name}">
      { utils:filter-taxonomy($root/*, $names) }
    </tag>
};

declare private function utils:branch-contains(
  $root as element(),
  $names as xs:string+
) as xs:boolean
{
  exists($root/descendant-or-self::*[@name = $names])
};

declare function utils:patch-uri2(
  $params as map:map,
  $name as xs:string?,
  $value as xs:string?
) as xs:string
{
  utils:patch-uri2($params, $name, $value, false())
};

declare function utils:patch-uri2(
  $params as map:map,
  $name as xs:string?,
  $value as xs:string?,
  $repeat as xs:boolean
) as xs:string
{
  utils:patch-uri2(concat("/images/", map:get($params, "userid")),
                   $params, $name, $value, $repeat)
};

declare function utils:patch-uri2(
  $base as xs:string,
  $xparams as map:map,
  $name as xs:string?,
  $value as xs:string?,
  $repeat as xs:boolean
) as xs:string
{
  let $params := map:map(<x>{$xparams}</x>/*)
  let $_   := if (empty($name))
              then
                ()
              else
                if (exists(map:get($params, $name)))
                then
                  let $values := map:get($params, $name)
                  let $othervalues := for $v in $values
                                      where string($v) != $value return $v
                  let $newvalue := if ($repeat)
                                   then if (not($value = $othervalues))
                                        then ($othervalues, $value)
                                        else $othervalues
                                   else if ($value = string($values))
                                        then ()
                                        else $value
                  return
                    map:put($params, $name, $newvalue)
                else
                  map:put($params, $name, $value)
  let $opt := for $pname in map:keys($params)
              for $value in map:get($params, $pname)
              where not($pname = ("userid", "page", "xml", "uri", "size")) or $name=$pname
              return
                concat($pname,"=",$value)
  return
    concat($base,
           if (empty($opt)) then "" else "?",
           string-join($opt,"&amp;"))
};

declare function utils:oneMonth(
  $params as map:map,
  $search as element(search:response),
  $dt as xs:date
)
{
  utils:calendar($params, $dt, $search)
};

declare function utils:twoMonths(
  $params as map:map,
  $search as element(search:response),
  $dtfirst as xs:date,
  $dtsecond as xs:date
)
{
  <table xmlns="http://www.w3.org/1999/xhtml"
         border="0">
    <tr>
      <td valign="top">{ utils:calendar($params, $dtfirst, $search) }</td>
      <td>&#160;</td>
      <td valign="top">{ utils:calendar($params, $dtsecond, $search) }</td>
    </tr>
  </table>
};

declare function utils:oneYear(
  $search as element(search:response),
  $dtfirst as xs:date,
  $dtsecond as xs:date
)
{
  let $months  := for $date in $search/search:facet[@name='date']/search:facet-value
                  return xs:date(concat(substring($date/@name, 1, 7), "-01"))
  let $months  := distinct-values($months)

  let $matches := map:map()

  let $_ :=
    for $year in (year-from-date($dtfirst) to year-from-date($dtsecond))
    let $ystr := string($year)
    for $month in (1 to 12)
    let $date   := xs:date(concat($year,
                                  if ($month < 10) then "-0" else "-", $month, "-01"))
    where $date <= $dtsecond and ($date = $months)
    return
      map:put($matches, $ystr, (map:get($matches, $ystr), $date))

  let $facets := $search/search:facet[@name='date']/search:facet-value

  return
    <dl xmlns="http://www.w3.org/1999/xhtml">
      { let $years := for $year in map:keys($matches) order by $year return $year
        for $year at $yindex in $years
        let $counts := for $facet in $facets
                       where starts-with($facet/@name, string($year))
                       return
                         xs:integer($facet/@count)
        return
          (<dt>
             <a href="{utils:patch-uri('date', string($year))}" class="plain">
               {$year}
             </a>
             {concat(" (", sum($counts), ")")}
           </dt>,
           <dd>
             <dl>
               { for $month at $mindex in map:get($matches, $year)
                 let $pfx := substring(string($month), 1, 7)
                 let $counts := for $facet in $facets
                       where starts-with($facet/@name, $pfx)
                       return
                         xs:integer($facet/@count)
                 return
                   (if ($mindex = 1) then "" else ", ",
                    <a href="{utils:patch-uri('date', string(substring(string($month), 1, 7)))}"
                       class="plain">
                      {$MONTHS[month-from-date($month)]}
                    </a>,
                    concat(" (", sum($counts), ")"))
               }
             </dl>
           </dd>)
      }
    </dl>
};

declare function utils:severalYears(
  $search as element(search:response),
  $dtstart as xs:date,
  $dtend as xs:date
)
{
  utils:oneYear($search, $dtstart, $dtend)
};

declare private function utils:calendar(
  $params as map:map,
  $dt as xs:date,
  $search as element(search:response)
)
{
  let $year   := year-from-date($dt)
  let $month  := month-from-date($dt)
  let $first  := $dt
  let $last   := $first + xs:yearMonthDuration("P1M") - xs:dayTimeDuration("P1D")
  let $fdbug  := xs:decimal(format-date($first,'[F1]','en',(),'us')) mod 7
  let $fday   := if ($fdbug=0) then 6 else $fdbug - 1
  let $sunday := $first - xs:dayTimeDuration(concat("P", $fday, "D"))
  return
    <table cellspacing="0" class="calendar">
      <tr>
        <td colspan="7" align="right">
          { format-date($dt, "[MNn] [Y0001]") }
        </td>
      </tr>

      <tr>
        { for $day in $DAYS
          return
            <td align="right">{substring($day, 1, 2)}</td>
        }
      </tr>

      { for $week in (0 to 5)
        let $ofs   := ($week*7)
        let $date  := $sunday + xs:dayTimeDuration(concat("P", $ofs, "D"))
        where $week = 0 or month-from-date($date) = month-from-date($dt)
        return
          <tr>
            { for $day  in (0 to 6)
              let $ofs   := ($week*7) + $day
              let $date  := $sunday + xs:dayTimeDuration(concat("P", $ofs, "D"))
              let $value := $search/search:facet[@name='date']/
                                    search:facet-value[xs:date(@name)=$date]
              let $class := if (empty($value)) then "day0" else "day1"
              return
                <td align="right" class="{$class}">
                  { let $value := $search/search:facet[@name='date']/
                                    search:facet-value[xs:date(@name)=$date]
                    return
                      if (empty($value))
                      then
                        day-from-date($date)
                      else
                        <a href="{utils:patch-uri2($params, 'start-date', string($date))}"
                           title="({$value/@count})">
                          { day-from-date($date) }
                        </a>
                  }
                </td>
            }
          </tr>
      }
    </table>
};

declare private function utils:loclink(
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
                  utils:patch-uri2($params, "country", $key)
                else
                  utils:patch-uri2($params, "province", $key)
              else
                utils:patch-uri2($params, "city", $key)

(:
  let $chk := if ($city = "" or empty($city))
              then
                if ($state = "" or empty($state))
                then
                  $key = map:get($params, "country")
                else
                  $key = map:get($params, "province")
              else
                $key = map:get($params, "city")
:)

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
{(:
        { if ($chk)
          then " &#x2714;"
          else ""
        }
:)}
      </span>
};

declare function utils:photo-visibility(
  $photo as element(rdf:Description)?
) as xs:string?
{
  (: Friends/Family not yet implemented :)
  if (empty($photo))
  then
    ()
  else
    let $public-perm := xdmp:permission("weblog-reader", "read")
    let $perms := xdmp:document-get-permissions(xdmp:node-uri($photo))
    let $public := $perms[sec:capability="read"]/sec:role-id = $public-perm/sec:role-id
    return
      if ($public)
      then "public"
      else "private"
};

declare function utils:blackout(
  $user as xs:string,
  $plat as xs:float?,
  $plong as xs:float?
) as xs:boolean
{
  if (empty($plat) or empty($plong))
  then
    false()
  else
    let $blackouts := doc(concat("/etc/", $user, "/blackouts.xml"))
    let $ploc := cts:point($plat, $plong)
    let $excl := for $loc in $blackouts/blackouts/location
                 let $eloc := cts:point($loc/@lat, $loc/@long)
                 let $dist := cts:distance($ploc, $eloc)
                 where $dist < xs:float($loc/@radius)
                 return
                   $loc
    return
      exists($excl)
};

declare function utils:show-photos(
  $params as map:map,
  $photos as element(rdf:Description)*,
  $set as xs:string?,
  $tag as xs:string?
) as element(html:div)*
{
  <div xmlns="http://www.w3.org/1999/xhtml" class="rows">
    { let $public-perm := xdmp:permission("weblog-reader", "read")
      let $rows := utils:sort($photos)
      for $row in $rows
      let $count  := count($row/npl:photo)
      let $extra  := (4 * $count) + (8 * $count) (: border+margin+padding in CSS :)
      let $factor := ($REALWIDTH - $extra) div $row/@width
      let $heights := for $col in $row/npl:photo
                      let $photo  := doc($col/@uri)/*
                      return
                        xs:integer($photo/npl:images/npl:thumb/npl:height * $factor)
      return
        <div class="row" style="height: {max($heights) + 12}">
          { for $col at $index in $row/npl:photo
            let $photo  := doc($col/@uri)/*
            let $perms  := xdmp:document-get-permissions(xdmp:node-uri($photo))
            let $public := $perms[sec:capability="read"]/sec:role-id = $public-perm/sec:role-id
            let $thumb  := if ($factor > 1 and count($photos) > 1)
                          then string($photo/npl:images/npl:small/npl:image)
                          else string($photo/npl:images/npl:thumb/npl:image)
            let $width  := xs:integer($photo/npl:images/npl:thumb/npl:width * $factor)
            let $width  := if (count($row/npl:photo) = 1) then $width + 2 else $width
            let $blackout := utils:blackout($photo/npl:user, $photo/geo:lat, $photo/geo:long)
            return
              <div>
                <a href="{utils:patch-uri2($photo/@rdf:about, $params, (), (), false())}"
                   class="plain">
                  <img src="{$thumb}" alt="{$photo/XMP-dc:Title}">
                    { if (count($photos) > 1)
                      then
                        attribute { fn:QName("", "width") } { $width }
                      else
                        ()
                    }
                    { attribute { fn:QName("", "class") }
                                { concat("thumb",
                                         if ($photo/geo:lat
                                             and (utils:admin() or not($blackout)))
                                         then " geo" else "",
                                         if ($public) then "" else " private")
                                }
                    }
                  </img>
                </a>
              </div>
          }
        </div>
    }
  </div>
};

declare function utils:sort(
  $photos as element(rdf:Description)*
)
{
  let $indexes := utils:next-row($photos, (), 0)
  let $row     := for $index in $indexes
                  let $width := xs:integer($photos[$index]/npl:images/npl:thumb/npl:width)
                  return
                    <npl:photo width="{$width}" uri="{xdmp:node-uri($photos[$index])}"/>
  let $rest    := for $photo at $index in $photos
                  where not($indexes = $index)
                  return $photo
  return
    (if (empty($row)) then () else <npl:row width="{sum($row/@width)}">{$row}</npl:row>,
     if (empty($rest)) then () else utils:sort($rest))
};

declare function utils:next-row(
  $photos as element(rdf:Description)*,
  $current as xs:integer*,
  $width as xs:integer
)
{
  let $next := utils:find($photos, $current, $MAXWIDTH - $width)
  return
    if (empty($photos))
    then
      $current
    else
      if (empty($current))
      then
        utils:next-row($photos, (1), xs:integer($photos[1]/npl:images/npl:thumb/npl:width))
      else
        if (empty($next))
        then
          $current
        else
          utils:next-row($photos, ($current, $next),
                     $width + xs:integer($photos[$next]/npl:images/npl:thumb/npl:width))
};

declare function utils:find(
  $photos as element(rdf:Description)*,
  $current as xs:integer*,
  $maxw as xs:integer
) as xs:integer?
{
  let $smaller := for $photo at $index in $photos
                  where not($current = $index)
                        and $maxw > xs:integer($photo/npl:images/npl:thumb/npl:width)
                  return
                    $index
  return $smaller[1]
};

declare function utils:views(
  $photo as element(rdf:Description)
) as xs:integer
{
  xdmp:invoke("/views.xqy",
    (QName("","uri"), xdmp:node-uri($photo)),
    <options xmlns="xdmp:eval">
      <database>{xdmp:database("photoman-audit")}</database>
    </options>)
};

declare function utils:set-title(
  $user as xs:string,
  $set as xs:string
)
{
  utils:set-title($user, $set, false())
};

declare function utils:set-title(
  $user as xs:string,
  $set as xs:string,
  $editable as xs:boolean
)
{
  let $setn  := substring-after($set, "/")
  let $uri   := concat("/metadata/", $user, "/sets/", $setn, ".xml")
  let $title := if (empty(doc($uri)))
                then $setn
                else string(doc($uri)/npl:metadata/npl:title)
  return
    if ($editable)
    then
      (<input xmlns="http://www.w3.org/1999/xhtml"
              type="hidden" id="set-title-uri" value="{$user}/{$set}"/>,
       <span xmlns="http://www.w3.org/1999/xhtml" id="set-title">
         { if (utils:admin())
           then attribute { fn:QName("", "class") } { "editable" }
           else ()
         }
         { $title }
       </span>)
    else
      $title
};

declare function utils:tag-title(
  $user as xs:string,
  $tag as xs:string
)
{
  utils:tag-title($user, $tag, false())
};

declare function utils:tag-title(
  $user as xs:string,
  $tag as xs:string,
  $editable as xs:boolean
)
{
  let $uri   := concat("/metadata/", $user, "/tags/", $tag, ".xml")
  let $title := if (empty(doc($uri)))
                then $tag
                else string(doc($uri)/npl:metadata/npl:title)
  return
    if ($editable)
    then
      (<input xmlns="http://www.w3.org/1999/xhtml"
              type="hidden" id="tag-title-uri" value="{$user}/{$tag}"/>,
       <span xmlns="http://www.w3.org/1999/xhtml" id="tag-title">
         { if (utils:admin())
           then attribute { fn:QName("", "class") } { "editable" }
           else ()
         }
         { $title }
       </span>)
    else
      $title
};

declare function utils:user-title(
  $user as xs:string
)
{
  utils:user-title($user, false())
};

declare function utils:user-title(
  $user as xs:string,
  $editable as xs:boolean
)
{
  let $uri   := concat("/metadata/", $user, "/info.xml")
  let $title := if (empty(doc($uri)))
                then $user
                else string(doc($uri)/npl:metadata/npl:title)
  return
    if ($editable)
    then
      (<input xmlns="http://www.w3.org/1999/xhtml"
              type="hidden" id="set-user-uri" value="{$user}"/>,
       <span xmlns="http://www.w3.org/1999/xhtml" id="set-user">
         { if (utils:admin())
           then attribute { fn:QName("", "class") } { "editable" }
           else ()
         }
         { $title }
       </span>)
    else
      $title
};

declare function utils:user-description(
  $user as xs:string
) as xs:string?
{
  let $uri := concat("/metadata/", $user, "/info.xml")
  let $doc := doc($uri)/*
  return
    if (empty($doc/npl:description/node()))
    then
      ()
    else
      string($doc/npl:description/node())
};

declare function utils:set-description(
  $user as xs:string,
  $set as xs:string
)
{
  utils:set-description($user, $set, false())
};

declare function utils:set-description(
  $user as xs:string,
  $set as xs:string,
  $editable as xs:boolean
)
{
  let $uri   := concat("/metadata/", $user, "/sets/", $set, ".xml")
  let $desc  := if (empty(doc($uri)))
                then ()
                else doc($uri)/npl:metadata/npl:description/node()
  where $desc
  return
    <div xmlns="http://www.w3.org/1999/xhtml" id="set-description" class="description">
      { $desc }
    </div>
};

declare private function utils:patch-uri(
  $name as xs:string,
  $value as xs:string
) as xs:string
{
  utils:patch-uri(xdmp:get-original-url(), $name, $value, false())
};

declare private function utils:patch-uri(
  $uri as xs:string,
  $name as xs:string,
  $value as xs:string,
  $repeat as xs:boolean
) as xs:string
{
  let $base   := if (contains($uri, "?")) then substring-before($uri, "?") else $uri
  let $params := if (contains($uri, "?")) then substring-after($uri, "?") else ""

  let $patn   := if ($repeat)
                 then concat("^\s*", $name, "\s*=\s*", $value)
                 else concat("^\s*", $name, "\s*=\s*")
  let $page   := concat("^\s*page=\d+\s*")

  let $found  := for $param in tokenize($params, "\s*&amp;\s*")
                 where matches($param, $patn)
                 return true()

  let $params := for $param in tokenize($params, "\s*&amp;\s*")
                 where not(matches($param, $patn)) and not(matches($param, $page))
                 return $param

  let $params := string-join($params, "&amp;")

  return
    concat($base, "?", $name, "=", $value,
           if ($params = "")
           then ""
           else concat("&amp;", $params))

(:
    if ($found)
    then
      concat($base, "?", $params)
    else
      concat($base, "?", $name, "=", $value,
             if ($params = "")
             then ""
             else concat("&amp;", $params))
:)
};

declare function utils:compose(
  $params as map:map
) as xs:string
{
  let $user     := utils:compose-term("user", map:get($params, "userid"))
  let $taxonomy := doc(concat("/etc/", map:get($params, "userid"), "/taxonomy.xml"))/*
  let $tag      := utils:compose-term("tag", map:get($params, "tag"))

(:
  let $exptag   := for $tag in map:get($params, "tag")
                   let $elem := $taxonomy//*[@name = $tag]
                   return
                     concat ("(",
                             string-join(for $name in $elem//@name
                                         return concat("tag:""", $name, """"), " OR "), ")")

  let $tag      := if (empty($exptag))
                   then ""
                   else if (count($exptag) = 1)
                        then $exptag
                        else concat("(", string-join($exptag, " AND "), ")")
:)

  let $set     := map:get($params, "set")
  let $set     := utils:compose-term("collection",
                                     if (empty($set)) then ()
                                     else concat(map:get($params, "userid"), "/", $set))
  let $country := utils:compose-term("country", map:get($params, "country"))
  let $state   := utils:compose-term("province", map:get($params, "province"))
  let $city    := utils:compose-term("city", map:get($params, "city"))
  let $date    := utils:compose-date-term(map:get($params, "start-date"), map:get($params, "end-date"))
  return
    string-join(($user, $tag, $set, $country, $state, $city, $date, "sort:date"), " ")
};

declare private function utils:compose-term(
  $name as xs:string,
  $value as xs:string*
) as xs:string?
{
  if (empty($value))
  then
    ()
  else
    if (count($value) = 1)
    then
      concat($name, ":""", $value, """")
    else
      concat("(", string-join(for $v in $value return concat($name, ":""", $v, """"),
                              " AND "),
             ")")
};

declare private function utils:compose-date-term(
  $date as xs:string?,
  $edate as xs:string?
) as xs:string?
{
  if (empty($date))
  then
    ()
  else
    let $first
      := if (string-length($date) = 4)
         then xs:date(concat($date,"-01-01"))
         else if (string-length($date) = 7)
              then xs:date(concat($date,"-01"))
              else xs:date($date)
    let $edate := if (empty($edate)) then $date else $edate
    let $last
      := if (string-length($edate) = 4)
         then xs:date(concat($edate,"-12-31"))
         else if (string-length($edate) = 7)
              then
                let $efirst := xs:date(concat($edate, "-01"))
                return
                  $efirst + xs:yearMonthDuration("P1M") - xs:dayTimeDuration("P1D")
              else xs:date($edate)
    return
      concat("((date GE ", substring(string($first), 1, 10),
              ") AND (date LE ", substring(string($last), 1, 10), "))")
};

declare function utils:show-locations(
  $params as map:map,
  $search as element(search:response),
  $locations as xs:string*
)
{
  <dl xmlns="http://www.w3.org/1999/xhtml">
    { for $country in distinct-values(for $location in $locations
                                      return substring-before($location, "|"))
      let $countrystart := concat($country,"|")
      order by $country
      return
        (<dt>
           {utils:loclink($search, $params, $country, (), ())}
         </dt>,
         let $states := distinct-values(for $location in $locations
                                        where starts-with($location, $countrystart)
                                        return
                                          substring-before(substring-after(
                                            $location, "|"), "|"))
         where exists($states)
         return
           <dd>
             <dl>
               { for $state in $states
                 let $statestart := concat($countrystart,$state,"|")
                 order by $state
                 return
                   (<dt>
                      {utils:loclink($search, $params, $country, $state, ())}
                    </dt>,
                    let $cities := distinct-values(for $location in $locations
                                        where starts-with($location, $statestart)
                                        return
                                          substring-after(substring-after(
                                            $location, "|"), "|"))
                    let $cities := for $city in $cities
                                   where $city != ""
                                   return $city
                    where exists($cities)
                    return
                      <dd>
                        <dl>
                          { for $city in $cities
                            order by $city
                            return
                              <dt>
                                {utils:loclink($search, $params, $country, $state, $city)}
                              </dt>
                          }
                        </dl>
                      </dd>)
               }
             </dl>
           </dd>)
    }
  </dl>
};

