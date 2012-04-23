xquery version "1.0-ml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace audit="http://nwalsh.com/ns/modules/photoman/audit";

declare option xdmp:mapping "false";

declare variable $uris as element() external;
declare variable $urilist as xs:string+ := for $uri in $uris/* return string($uri);

declare variable $search-options
  := <options xmlns="http://marklogic.com/appservices/search">
       <searchable-expression xmlns:audit="http://nwalsh.com/ns/modules/photoman/audit">
         { "//audit:http" }
       </searchable-expression>
       <search-option>unfiltered</search-option>
       <constraint name="code">
         <value>
           <element ns="http://nwalsh.com/ns/modules/photoman/audit" name="code"/>
         </value>
       </constraint>
       <constraint name="uri">
         <value>
           <element ns="http://nwalsh.com/ns/modules/photoman/audit" name="uri"/>
         </value>
       </constraint>
       <constraint name="byday">
         <range type="xs:dateTime" facet="true">
           <element ns="http://nwalsh.com/ns/modules/photoman/audit" name="datetime"/>
           <computed-bucket name="D7" ge="P0D"  lt="P1D" anchor="start-of-day"/>
           <computed-bucket name="D6" ge="-P1D" lt="P0D" anchor="start-of-day"/>
           <computed-bucket name="D5" ge="-P2D" lt="-P1D" anchor="start-of-day"/>
           <computed-bucket name="D4" ge="-P3D" lt="-P2D" anchor="start-of-day"/>
           <computed-bucket name="D3" ge="-P4D" lt="-P3D" anchor="start-of-day"/>
           <computed-bucket name="D2" ge="-P5D" lt="-P4D" anchor="start-of-day"/>
           <computed-bucket name="D1" ge="-P6D" lt="-P5D" anchor="start-of-day"/>
         </range>
       </constraint>
       <constraint name="byhour">
         <range type="xs:dateTime" facet="true">
           <element ns="http://nwalsh.com/ns/modules/photoman/audit" name="datetime"/>
           <computed-bucket name="H24" ge="-PT1H" lt="PT0H" anchor="now"/>
           <computed-bucket name="H23" ge="-PT2H" lt="-PT1H" anchor="now"/>
           <computed-bucket name="H22" ge="-PT3H" lt="-PT2H" anchor="now"/>
           <computed-bucket name="H21" ge="-PT4H" lt="-PT3H" anchor="now"/>
           <computed-bucket name="H20" ge="-PT5H" lt="-PT4H" anchor="now"/>
           <computed-bucket name="H19" ge="-PT6H" lt="-PT5H" anchor="now"/>
           <computed-bucket name="H18" ge="-PT7H" lt="-PT6H" anchor="now"/>
           <computed-bucket name="H17" ge="-PT8H" lt="-PT7H" anchor="now"/>
           <computed-bucket name="H16" ge="-PT9H" lt="-PT8H" anchor="now"/>
           <computed-bucket name="H15" ge="-PT10H" lt="-PT9H" anchor="now"/>
           <computed-bucket name="H14" ge="-PT11H" lt="-PT10H" anchor="now"/>
           <computed-bucket name="H13" ge="-PT12H" lt="-PT11H" anchor="now"/>
           <computed-bucket name="H12" ge="-PT13H" lt="-PT12H" anchor="now"/>
           <computed-bucket name="H11" ge="-PT14H" lt="-PT13H" anchor="now"/>
           <computed-bucket name="H10" ge="-PT15H" lt="-PT14H" anchor="now"/>
           <computed-bucket name="H9" ge="-PT16H" lt="-PT15H" anchor="now"/>
           <computed-bucket name="H8" ge="-PT17H" lt="-PT16H" anchor="now"/>
           <computed-bucket name="H7" ge="-PT18H" lt="-PT17H" anchor="now"/>
           <computed-bucket name="H6" ge="-PT19H" lt="-PT18H" anchor="now"/>
           <computed-bucket name="H5" ge="-PT20H" lt="-PT19H" anchor="now"/>
           <computed-bucket name="H4" ge="-PT21H" lt="-PT20H" anchor="now"/>
           <computed-bucket name="H3" ge="-PT22H" lt="-PT21H" anchor="now"/>
           <computed-bucket name="H2" ge="-PT23H" lt="-PT22H" anchor="now"/>
           <computed-bucket name="H1" ge="-PT24H" lt="-PT23H" anchor="now"/>
         </range>
       </constraint>
       <constraint name="referrer">
         <range type="xs:string" facet="true">
           <element ns="http://nwalsh.com/ns/modules/photoman/audit" name="referrer"/>
           <facet-option>frequency-order</facet-option>
           <facet-option>limit=20</facet-option>
         </range>
       </constraint>
       <constraint name="agent">
         <range type="xs:string" facet="true">
           <element ns="http://nwalsh.com/ns/modules/photoman/audit" name="agent"/>
           <facet-option>frequency-order</facet-option>
           <facet-option>limit=10</facet-option>
         </range>
       </constraint>
       <transform-results apply="empty-snippet"/>
       <page-length>1</page-length>
     </options>;

let $now       := current-dateTime()
let $curhour   := hours-from-dateTime($now)
let $curmin    := minutes-from-dateTime($now)
let $cursec    := seconds-from-dateTime($now)

let $hour      := current-dateTime()
                  - xs:dayTimeDuration(concat("PT", $curmin, "M", $cursec, "S"))

let $midnight  := $hour
                  - xs:dayTimeDuration(concat("PT", $curhour, "H"))

let $endofhour := $hour + xs:dayTimeDuration("PT60M")
let $endofday  := $midnight + xs:dayTimeDuration("PT24H")

let $last7d  := for $count in reverse((0 to 7))
                let $dur := xs:dayTimeDuration(concat("P", $count, "D"))
                return
                  $endofday - $dur

let $last24h := for $count in reverse((0 to 24))
                let $dur := xs:dayTimeDuration(concat("PT", $count, "H"))
                return
                  $endofhour - $dur

let $results := if (count($urilist) = 1)
                then
                  search:search(concat("uri:""", $urilist, """ code:200"), $search-options)
                else
                  let $suri := for $uri in $urilist
                               return
                                 concat("uri:""", $uri, """")
                  let $srch := concat("(", string-join($suri, " OR "), ") code:200")
                  return
                    search:search($srch, $search-options)

let $byday   := $results/search:facet[@name="byday"]
let $byhour  := $results/search:facet[@name="byhour"]

let $dcount := for $day in (1 to 7)
               let $name := concat("D", $day)
               return (xs:integer($byday/search:facet-value[@name=$name]/@count), 0)[1]

let $daylbl := string-join(for $day in (1 to 7)
                           let $name := format-dateTime($last7d[$day], "[FNn,*-3]")
                           return
                             $name,
                           "|")

let $dgraphuri := string-join(
  (concat("http://chart.apis.google.com/chart?chxl=1:|", $daylbl),
   concat("chxr=0,0,", max($dcount), "|1,0,7"),
   "chxt=y,x",
   "chbh=a",
   "chs=200x100",
   "cht=bvg",
   "chts=617187,12",
   "chf=bg,s,FFFFFF",
   "chxs=0,617187|1,617187",
   "chco=617187",
   concat("chds=0,", max($dcount), ",0,", max($dcount)),
   concat("chd=t1:", string-join(for $num in $dcount return string($num), ",")),
   "chtt=hits%2Fday"), "&amp;")

let $hcount := for $hour in (1 to 24)
               let $name := concat("H", $hour)
               return (xs:integer($byhour/search:facet-value[@name=$name]/@count), 0)[1]

let $hourlbl := string-join(for $pos in (1 to 24)
                            let $hour := hours-from-dateTime($last24h[$pos])
                            return
                              if ($hour = 0) then "mid"
                              else if ($hour = 12) then "noon"
                              else if ($hour = 6) then "6a"
                              else if ($hour = 18) then "6p"
                              else "",
                            "|")

let $hgraphuri := string-join(
  (concat("http://chart.apis.google.com/chart?chxl=1:|", $hourlbl),
   concat("chxr=0,0,", max($hcount), "|1,0,24"),
   "chxt=y,x",
   "chbh=a",
   "chs=200x100",
   "cht=bvg",
   "chts=617187,12",
   "chf=bg,s,FFFFFF",
   "chxs=0,617187|1,617187",
   "chco=617187",
   concat("chds=0,", max($hcount), ",0,", max($hcount)),
   concat("chd=t1:", string-join(for $num in $hcount return string($num), ",")),
   "chtt=hits%2Fhour"), "&amp;")

return
<div xmlns="http://www.w3.org/1999/xhtml">
<img src="{$dgraphuri}" width="200" height="100" alt="Hits/day" />
<br/>
<img src="{$hgraphuri}" width="200" height="100" alt="Hits/hour" />
<h4>Top referrers</h4>
<ul>
{ for $ref in $results/search:facet[@name='referrer']/search:facet-value
  where not(contains($ref/@name, '//microwave:70'))
  return
    <li><a href="{string($ref/@name)}">{string($ref/@name)}</a> ({string($ref/@count)})</li>
}
</ul>
<h4>Top agents</h4>
<ul>
{ for $ref in $results/search:facet[@name='agent']/search:facet-value
  return
    <li>{string($ref/@name)} ({string($ref/@count)})</li>
}
</ul>
</div>

