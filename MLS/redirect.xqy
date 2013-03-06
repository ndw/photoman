xquery version "1.0-ml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

(:
http://photos.nwalsh.com/images/ndw/square/2013/01/31/IMG_20130131_113551.jpg
http://photos.nwalsh.com/images/ndw/thumb/2013/01/31/IMG_20130131_113551.jpg
http://photos.nwalsh.com/images/ndw/small/2013/01/31/IMG_20130131_113551.jpg
http://photos.nwalsh.com/images/ndw/large/2013/01/31/IMG_20130131_113551.jpg
:)

let $sizes := map:map()
let $_     := map:put($sizes, "square", "64")
let $_     := map:put($sizes, "thumb", "150")
let $_     := map:put($sizes, "small", "500")
(: large isn't in sizes because it isn't in a subdirectory :)

let $uri   := xdmp:get-request-field("uri")
let $paths := tokenize($uri, "/")
let $count := count($paths)
let $size  := $paths[4]
let $fn    := $paths[$count]
let $paths := (subsequence($paths, 1, 3), subsequence($paths, 5, $count - 5))

let $newpath := if (empty(map:get($sizes, $size)))
                then
                  string-join(($paths, $fn), "/")
                else
                  string-join(($paths, map:get($sizes, $size), $fn), "/")

return
  xdmp:redirect-response(concat("http://images.nwalsh.com", $newpath))
