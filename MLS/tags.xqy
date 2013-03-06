xquery version "1.0-ml";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

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
declare namespace html="http://www.w3.org/1999/xhtml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $params := rest:process-request(endpoints:request("/tags.xqy"));

let $user     := map:get($params, "userid")
return
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>photos.nwalsh.com: {$user}/tags</title>
      <link rel="stylesheet" type="text/css" href="/css/base.css" />
      <link rel="stylesheet" type="text/css" href="/css/set.css" />
      <link rel="icon" href="/favicon.png" type="image/png" />
      <style type="text/css">v\:* {{ behavior:url(#default#VML); }}</style>
      <script type="text/javascript" src="/js/dbmodnizr.js"></script>
      <script type="text/javascript" src="/js/jquery-1.7.1.min.js"></script>
      <script type="text/javascript" src="/js/mapping.js"></script>
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
        <h1>{$user} tags</h1>

        <table border="0">
        <tr>
        <td valign="top">
        <dl>
          { let $tag := xs:QName("npl:tag")
            let $opt := ("collation=http://marklogic.com/collation/en/S1/T0020/AS/MO")
            for $word in cts:element-values($tag, (), $opt)
            let $count := count(cts:search(collection(),
                                        cts:element-value-query($tag, $word, "exact")))
            return
              <dt>
                <a href="/tags/{$user}/{$word}">
                  {$word}
                </a>
                ({$count})
              </dt>
          }
        </dl>
        </td>
        <td>
        <dl>
          { let $tag := xs:QName("npl:tag")
            let $opt := ("collation=http://marklogic.com/collation/en/S1/T0020/AS/MO")
            for $word in cts:element-values($tag, (), $opt)
            let $count := count(cts:search(collection(),
                                        cts:element-value-query($tag, $word, "exact")))
            order by $count descending
            return
              <dt>
                <a href="/tags/{$user}/{$word}">
                  {$word}
                </a>
                ({$count})
              </dt>
          }
        </dl>
        </td>
        </tr>
        </table>
      </div>
      <script src="/js/flexie.min.js" type="text/javascript"></script>
    </body>
  </html>
