xquery version "1.0-ml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace audit="http://nwalsh.com/ns/modules/photoman/audit";
declare namespace db="http://docbook.org/ns/docbook";
declare namespace html="http://www.w3.org/1999/xhtml";

declare option xdmp:mapping "false";

declare variable $uri as xs:string external;

let $hour      := current-dateTime()
                  - xs:dayTimeDuration(concat("PT", minutes-from-dateTime(current-dateTime()), "M"))
                  - xs:dayTimeDuration(concat("PT", seconds-from-dateTime(current-dateTime()), "S"))
let $midnight  := $hour
                  - xs:dayTimeDuration(concat("PT", hours-from-dateTime(current-dateTime()), "H"))

let $endofhour := $hour + xs:dayTimeDuration("PT60M")
let $endofday  := $midnight + xs:dayTimeDuration("PT24H")

let $last7d  := for $count in reverse((0 to 7))
                let $dur := xs:dayTimeDuration(concat("P", $count, "D"))
                return
                  $endofday - $dur

let $q-200  := cts:element-value-query(xs:QName("audit:code"), "200", ("exact"))
let $q-uri  := if ($uri = "/")
               then ()
               else cts:element-value-query(xs:QName("audit:uri"), $uri, ("exact"))

let $irrdir := cts:or-query(for $dir in ("css", "local", "js", "graphics",
                                         "popular.xqy", "favicon.ico",
                                         "atom", "rss", "cgi-bin", "knows")
                            return
                              cts:element-value-query(xs:QName("audit:dir"), $dir))
let $irrext := cts:or-query(for $ext in ("atom")
                            return
                              cts:element-value-query(xs:QName("audit:ext"), $ext))

let $irrelevant := cts:or-query(($irrdir, $irrext))

let $dcount := for $day in (1 to 7)
               let $q-s := cts:element-range-query(xs:QName("audit:datetime"), ">=", $last7d[$day])
               let $q-e := cts:element-range-query(xs:QName("audit:datetime"), "<=", $last7d[$day+1])
               let $relevant := cts:and-query(($q-200, $q-uri, $q-s, $q-e))
               return
                 xdmp:estimate(cts:search(//audit:http,
                                          cts:and-not-query($relevant, $irrelevant)))

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

let $last24h := for $count in reverse((0 to 24))
                let $dur := xs:dayTimeDuration(concat("PT", $count, "H"))
                return
                  $endofhour - $dur

let $hcount := for $hour in (1 to 24)
               let $q-s := cts:element-range-query(xs:QName("audit:datetime"), ">=", $last24h[$hour])
               let $q-e := cts:element-range-query(xs:QName("audit:datetime"), "<=", $last24h[$hour+1])
               let $relevant := cts:and-query(($q-200, $q-uri, $q-s, $q-e))
               return
                 xdmp:estimate(cts:search(//audit:http,
                                          cts:and-not-query($relevant, $irrelevant)))

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
</div>

