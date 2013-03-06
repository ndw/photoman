xquery version "1.0-ml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace audit="http://nwalsh.com/ns/modules/photoman/audit";

declare option xdmp:mapping "false";

declare variable $uri as xs:string external;

declare variable $r200 := cts:element-value-query(xs:QName("audit:code"), "200", ("exact"));

let $sign     := if(starts-with(string(implicit-timezone()), "-")) then "-" else "+"
let $hours    := abs(hours-from-duration(implicit-timezone()))
let $midnight := xs:dateTime(concat(substring(string(current-date()), 1, 10), "T00:00:00",
                                    $sign, if ($hours >= 10) then "" else "0",
                                    $hours, ":00"))

let $dtstarts := for $day in (0 to 6)
                 return $midnight - ($day * xs:dayTimeDuration("P1D"))

let $dcount :=
  for $dtstart in reverse($dtstarts)
  let $dtend := $dtstart + xs:dayTimeDuration("P1D")
  let $dtsq  := cts:element-range-query(xs:QName("audit:datetime"), ">=", $dtstart)
  let $dteq  := cts:element-range-query(xs:QName("audit:datetime"), "<", $dtend)
  let $uriq  := cts:element-value-query(xs:QName("audit:uri"), $uri)
  return
    sum(for $audit in cts:search(/audit:log,
                                 cts:and-query(($dtsq, $dteq, $uriq)))
        let $_ := xdmp:log(xdmp:node-uri($audit))
        let $_ := xdmp:log(count($audit/audit:http))
        return
          count($audit/audit:http[audit:code = "200" and audit:uri = $uri]))

let $daylbl := string-join(for $day in $dtstarts
                           let $name := format-dateTime($day, "[FNn,*-3]")
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

return
<div xmlns="http://www.w3.org/1999/xhtml">
<img src="{$dgraphuri}" width="200" height="100" alt="Hits/day" />

{(:
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
:)}
</div>

