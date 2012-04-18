xquery version "1.0-ml";

import module namespace admin="http://marklogic.com/xdmp/admin"
       at "/MarkLogic/admin.xqy";

import module namespace sec="http://marklogic.com/xdmp/security"
       at "/MarkLogic/security.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace f="http://nwalsh.com/ns/functions";
declare namespace npl="http://nwalsh.com/ns/photolib";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare option xdmp:mapping "false";

declare variable $FOREST-NAME := "photoman";
declare variable $DATABASE-NAME := "photoman";

declare variable $ROOT-DIRECTORY := "/MarkLogic/photoman/MLS";
declare variable $APPSERVER-NAME := "photoman";
declare variable $APPSERVER-PORT := 7070;
declare variable $ADMIN-APPSERVER-NAME := "photoman-admin";
declare variable $ADMIN-APPSERVER-PORT := 7071;

declare variable $WEBLOG-UPDATE := "weblog-update";
declare variable $WEBLOG-READER := "weblog-reader";
declare variable $WEBLOG-EDITOR := "weblog-editor";

declare variable $npl := "http://nwalsh.com/ns/photolib";
declare variable $rdf := "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare function f:create-db($config as element(configuration),
                             $dbname as xs:string,
                             $fname as xs:string)
        as element(configuration)
{
  let $config := admin:forest-create($config, $fname, xdmp:host(), ())
  let $config := admin:database-create($config, $dbname,
                                       xdmp:database("Security"),
                                       xdmp:database("Schemas"))
  let $save   := admin:save-configuration($config)
  return
    admin:database-attach-forest($config,
                                 xdmp:database($dbname), xdmp:forest($fname))
};

declare function f:er-index($config as element(configuration),
                            $dbid as xs:unsignedLong,
                            $ns as xs:string,
                            $name as xs:string,
                            $type as xs:string,
                            $collation as xs:string)
        as element(configuration)
{
  let $rangespec
    :=  admin:database-range-element-index(
              $type, $ns, $name, $collation, false())
  return
    admin:database-add-range-element-index($config, $dbid, $rangespec)
};

let $config     := admin:get-configuration()
let $groupid    := xdmp:group()

(: ====================================================================== :)

(: Create the photoman database :)
let $config  := f:create-db($config, $DATABASE-NAME, $FOREST-NAME)
let $photodb := xdmp:database($DATABASE-NAME)

let $config := admin:database-set-uri-lexicon($config, $photodb, true())
let $config := admin:database-set-collection-lexicon($config, $photodb, true())
let $config := admin:database-set-directory-creation($config, $photodb, "manual")

(: Setup geospatial index :)
let $geoidx := admin:database-geospatial-element-pair-index(
                 "http://www.w3.org/1999/02/22-rdf-syntax-ns#", "Description",
                 "http://www.w3.org/2003/01/geo/wgs84_pos#", "lat",
                 "http://www.w3.org/2003/01/geo/wgs84_pos#", "long",
                 "wgs84", false())
let $config := admin:database-add-geospatial-element-pair-index($config, $photodb, $geoidx)

(: Setup the npl:view/@date index :)
let $index  := admin:database-range-element-attribute-index(
                 "date", $npl, "view", "", "date", "", false())
let $config := admin:database-add-range-element-attribute-index($config, $photodb, $index)

(: Setup the rdf:Description/@about index :)
let $index  := admin:database-range-element-attribute-index(
                 "string", $rdf, "Description", $rdf, "about",
                 "http://marklogic.com/collation/codepoint", false())
let $config := admin:database-add-range-element-attribute-index($config, $photodb, $index)

(: Setup the npl:* indexes :)
let $config := f:er-index($config, $photodb, $npl, "user", "string",
                          "http://marklogic.com/collation/")
let $config := f:er-index($config, $photodb, $npl, "country", "string",
                          "http://marklogic.com/collation/")
let $config := f:er-index($config, $photodb, $npl, "province", "string",
                          "http://marklogic.com/collation/")
let $config := f:er-index($config, $photodb, $npl, "city", "string",
                          "http://marklogic.com/collation/")
let $config := f:er-index($config, $photodb, $npl, "location", "string",
                          "http://marklogic.com/collation/")
let $config := f:er-index($config, $photodb, $npl, "tag", "string",
                          "http://marklogic.com/collation/codepoint")
let $config := f:er-index($config, $photodb, $npl, "datetime", "dateTime", "")
let $config := f:er-index($config, $photodb, $npl, "date", "date", "")
let $config := f:er-index($config, $photodb, $npl, "total", "int", "")
let $config := f:er-index($config, $photodb, $npl, "upload-timestamp", "unsignedLong", "")

(: Create the weblog-reader role :)
let $query := concat('xquery version "1.0-ml";

               import module namespace sec="http://marklogic.com/xdmp/security"
                             at "/MarkLogic/security.xqy";

               sec:create-role("', $WEBLOG-READER, '", "Weblog reader", (), (), ())')
let $opts  := <options xmlns="xdmp:eval">
                <database>{xdmp:security-database()}</database>
	      </options>
let $wlrd  := xdmp:eval($query, (), $opts)

(: Add the xdmp:value priv to the weblog-reader role; works around
   a bug in the search:search api. :)
let $query := concat('xquery version "1.0-ml";

               import module namespace sec="http://marklogic.com/xdmp/security"
                             at "/MarkLogic/security.xqy";

               sec:privilege-add-roles("http://marklogic.com/xdmp/privileges/xdmp-value", "execute", "', $WEBLOG-READER, '")')
let $opts  := <options xmlns="xdmp:eval">
                <database>{xdmp:security-database()}</database>
	      </options>
let $_     := xdmp:eval($query, (), $opts)

(: Create the weblog-editor role :)
let $query := concat('xquery version "1.0-ml";

               import module namespace sec="http://marklogic.com/xdmp/security"
                             at "/MarkLogic/security.xqy";

               sec:create-role("', $WEBLOG-EDITOR, '", "Weblog editor", ("', $WEBLOG-READER, '"), (), ())')
let $opts  := <options xmlns="xdmp:eval">
                <database>{xdmp:security-database()}</database>
	      </options>
let $wled  := xdmp:eval($query, (), $opts)

(: Create the weblog-reader user :)
let $query := concat('xquery version "1.0-ml";

               import module namespace sec="http://marklogic.com/xdmp/security"
                             at "/MarkLogic/security.xqy";

               let $wrp := xdmp:permission("', $WEBLOG-READER, '", "read")

               return
                 sec:create-user("', $WEBLOG-READER, '", "Weblog reader", string(xdmp:random()),
                                 ("', $WEBLOG-READER, '"), ($wrp),
                                 ())')
let $opts  := <options xmlns="xdmp:eval">
                <database>{xdmp:security-database()}</database>
	      </options>
let $user  := xdmp:eval($query, (), $opts)

(: Who's admin? :)
let $query := 'xquery version "1.0-ml";

               import module namespace sec="http://marklogic.com/xdmp/security" 
                             at "/MarkLogic/security.xqy";

               sec:uid-for-name("admin")'
let $opts  := <options xmlns="xdmp:eval">
                <database>{xdmp:security-database()}</database>
	      </options>
let $admin := xdmp:eval($query, (), $opts)

(: Create the weblog-editor and weblog-reader privileges :)
let $query := concat('xquery version "1.0-ml";

               import module namespace sec="http://marklogic.com/xdmp/security"
                             at "/MarkLogic/security.xqy";

               sec:create-privilege("', $WEBLOG-UPDATE, '", "http://norman.walsh.name/ns/priv/weblog-update", "execute", "', $WEBLOG-EDITOR, '")')
let $opts  := <options xmlns="xdmp:eval">
                <database>{xdmp:security-database()}</database>
	      </options>
let $wlup  := xdmp:eval($query, (), $opts)

(: Setup the photoman appserver :)
let $config := admin:http-server-create($config, $groupid, $APPSERVER-NAME,
                                        $ROOT-DIRECTORY, $APPSERVER-PORT, 0, $photodb)
let $photoapp := admin:appserver-get-id($config, $groupid, $APPSERVER-NAME)
let $config := admin:appserver-set-url-rewriter($config, $photoapp, "/rewriter.xqy")
let $config := admin:appserver-set-authentication($config, $photoapp, "application-level")
let $config := admin:appserver-set-default-user($config, $photoapp, $user)

(: Setup the photoman-admin appserver :)
let $config := admin:http-server-create($config, $groupid, $ADMIN-APPSERVER-NAME,
                                        $ROOT-DIRECTORY, $ADMIN-APPSERVER-PORT, 0, $photodb)
let $photoapp := admin:appserver-get-id($config, $groupid, $ADMIN-APPSERVER-NAME)
let $config := admin:appserver-set-url-rewriter($config, $photoapp, "/rewriter.xqy")
let $config := admin:appserver-set-authentication($config, $photoapp, "application-level")
let $config := admin:appserver-set-default-user($config, $photoapp, $admin)

let $save   := admin:save-configuration($config)

return
  concat($DATABASE-NAME, " setup complete.")

