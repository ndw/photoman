xquery version "1.0-ml";

module namespace ua="http://nwalsh.com/ns/modules/photoman/amped";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare function ua:update-views(
  $photo as element(rdf:Description)
) as empty-sequence()
{
  let $date  := substring(string(current-date()), 1, 10)
  let $vdate := $photo/npl:views/npl:view[@date=$date]
  let $vtot  := $photo/npl:views/npl:total
  let $total := if (empty($vtot)) then 1 else xs:integer($vtot) + 1
  let $today := if (empty($vdate)) then 1 else xs:integer($vdate) + 1
  return
    if (empty($photo/npl:views))
    then
      xdmp:node-insert-after($photo/npl:user,
                             <npl:views>
                               <npl:total>{$total}</npl:total>
                               <npl:view date="{$date}">{$today}</npl:view>
                             </npl:views>)
    else
      if (exists($vdate))
      then
        (xdmp:node-replace($vtot, <npl:total>{$total}</npl:total>),
         xdmp:node-replace($vdate, <npl:view date="{$date}">{$today}</npl:view>))
      else
        (: Be careful to avoid conflicting updates :)
        let $newviews := <npl:views>
                           <npl:total>{$total}</npl:total>
                           { $photo/npl:views/npl:view }
                           <npl:view date="{$date}">{$today}</npl:view>
                         </npl:views>
        return
          xdmp:node-replace($photo/npl:views, $newviews)
};
