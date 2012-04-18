xquery version "1.0-ml";

module namespace audit="http://nwalsh.com/ns/modules/photoman/audit";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $ip := if (xdmp:get-request-header("X-Real-IP", ()))
                        then xdmp:get-request-header("X-Real-IP")
                        else xdmp:get-request-client-address();

declare function audit:_audit($node as element()) as empty-sequence() {
  xdmp:invoke("/audit/add.xqy",
              (xs:QName("node"), $node),
              <options xmlns="xdmp:eval">
                <database>{xdmp:database("photoman-audit")}</database>
              </options>)
};

declare function audit:http($verb as xs:string, $uri as xs:string, $code as xs:decimal?)
as empty-sequence()
{
  audit:http($verb, $uri, $code, ())
};

declare function audit:http($verb as xs:string,
                            $uri as xs:string,
                            $code as xs:decimal?,
                            $errors as element(error:error)*)
as empty-sequence()
{
  let $referrer    := xdmp:get-request-header("Referer", ())
  let $after-slash := substring($uri, 2)
  let $dir         := if (contains($after-slash, "/"))
                      then substring-before($after-slash, "/")
                      else $after-slash
  let $filename    := replace($uri, "^.*/([^/]+)$", "$1")
  let $ext         := if (contains($filename, "."))
                      then replace($filename, "^.*\.([^\.]+)$", "$1")
                      else ""

  let $message
    := <http xmlns="http://nwalsh.com/ns/modules/photoman/audit">
         { if (empty($code)) then () else <code>{$code}</code> }
         <verb>{$verb}</verb>
         <uri>{$uri}</uri>
         <dir>{$dir}</dir>
         <filename>{$filename}</filename>
         <ext>{$ext}</ext>
         { if (empty($errors)) then () else <errors>{$errors}</errors> }
         <datetime>{current-dateTime()}</datetime>
         <ip>{$ip}</ip>
         <agent>{xdmp:get-request-header("User-Agent")}</agent>
         { if (empty($referrer)) then () else <referrer>{$referrer}</referrer> }
       </http>
  return
    audit:_audit($message)
};
