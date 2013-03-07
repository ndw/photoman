xquery version "1.0-ml";

module namespace endpoints="http://nwalsh.com/ns/photoends";

import module namespace rest="http://marklogic.com/appservices/rest"
       at "/MarkLogic/appservices/utils/rest.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false";

declare variable $endpoints:ENDPOINTS as element(rest:options)
  := <options xmlns="http://marklogic.com/appservices/rest">
       <request uri="^(/images/([^/]+)/(square|thumb|small|large).*\.jpg)$"
                endpoint="/serve.xqy" user-params="forbid">
         <uri-param name="uri">$1</uri-param>
         <uri-param name="user">$2</uri-param>
       </request>

       <request uri="^(/[^/]+\.gif|/[^/]+\.png)$" endpoint="/serve.xqy" user-params="forbid">
         <uri-param name="uri">$1</uri-param>
       </request>

       <request uri="^(/css/.*\.css|/js/.*\.js|/fonts/.*)$"
                endpoint="/serve.xqy" user-params="forbid">
         <uri-param name="uri">$1</uri-param>
       </request>

       <request uri="^(/css/.*\.css|/js/.*\.js)$" endpoint="/serve.xqy" user-params="forbid">
         <uri-param name="uri">$1</uri-param>
       </request>

       <request uri="^/local(/.*)$"
                endpoint="/local.xqy" user-params="forbid">
         <uri-param name="uri">$1</uri-param>
       </request>

       <request uri="^(/images/([^/]+)/.*)/large$"
                endpoint="/photo.xqy" user-params="forbid">
         <uri-param name="uri">$1</uri-param>
         <uri-param name="size">large</uri-param>
         <uri-param name="userid">$2</uri-param>
         <param name="city" required="false"/>
         <param name="country" required="false"/>
         <param name="end-date" required="false"/>
         <param name="page" as="nonNegativeInteger" default="1"/>
         <param name="province" alias="state" required="false"/>
         <param name="set" required="false"/>
         <param name="start-date" alias="date" required="false"/>
         <param name="tag" required="false" repeatable="true"/>
         <param name="xml" values="rdf|docbook"/>
         <param name="q"/>
       </request>

       <request uri="^(/images/([^/]+)/.*)$"
                endpoint="/photo.xqy" user-params="forbid">
         <uri-param name="uri">$1</uri-param>
         <uri-param name="size">small</uri-param>
         <uri-param name="userid">$2</uri-param>
         <param name="city" required="false"/>
         <param name="country" required="false"/>
         <param name="end-date" required="false"/>
         <param name="page" as="nonNegativeInteger" default="1"/>
         <param name="province" alias="state" required="false"/>
         <param name="set" required="false"/>
         <param name="start-date" alias="date" required="false"/>
         <param name="tag" required="false" repeatable="true"/>
         <param name="xml" values="rdf|docbook"/>
         <param name="q"/>
       </request>

       <request uri="^/users/([^/]+)/feed$" endpoint="/feed.xqy" user-params="forbid">
         <uri-param name="userid">$1</uri-param>
       </request>

       <request uri="^/users/([^/]+)$" endpoint="/user.xqy" user-params="forbid">
         <uri-param name="userid">$1</uri-param>
       </request>

       <request uri="^/images/(.+)$"
                endpoint="/photos.xqy" user-params="forbid">
         <uri-param name="userid">$1</uri-param>
         <param name="city" required="false"/>
         <param name="country" required="false"/>
         <param name="end-date" required="false"/>
         <param name="page" as="nonNegativeInteger" default="1"/>
         <param name="province" alias="state" required="false"/>
         <param name="set" required="false"/>
         <param name="start-date" alias="date" required="false"/>
         <param name="tag" required="false" repeatable="true"/>
         <param name="xml" values="rdf|docbook"/>
         <param name="q"/>
       </request>

       <request uri="^/sets/([^/]+)/(.+)$"
                endpoint="/photos.xqy" user-params="forbid">
         <uri-param name="userid">$1</uri-param>
         <uri-param name="set">$2</uri-param>
         <param name="city" required="false"/>
         <param name="country" required="false"/>
         <param name="end-date" required="false"/>
         <param name="page" as="nonNegativeInteger" default="1"/>
         <param name="province" alias="state" required="false"/>
         <param name="start-date" alias="date" required="false"/>
         <param name="tag" required="false" repeatable="true"/>
         <param name="xml" values="rdf|docbook"/>
       </request>

       <request uri="^/tags/([^/]+)/(.+)$"
                endpoint="/photos.xqy" user-params="forbid">
         <uri-param name="userid">$1</uri-param>
         <uri-param name="tag">$2</uri-param>
         <param name="city" required="false"/>
         <param name="country" required="false"/>
         <param name="end-date" required="false"/>
         <param name="page" as="nonNegativeInteger" default="1"/>
         <param name="province" alias="state" required="false"/>
         <param name="set" required="false"/>
         <param name="start-date" alias="date" required="false"/>
         <param name="xml" values="rdf|docbook"/>
       </request>

       <request uri="^/tags/([^/]+)$"
                endpoint="/tags.xqy" user-params="forbid">
         <uri-param name="userid">$1</uri-param>
       </request>

       <request uri="^/dates/([^/]+)/(\d\d\d\d(-\d\d(-\d\d)?)?)$"
                endpoint="/photos.xqy" user-params="forbid">
         <uri-param name="userid">$1</uri-param>
         <uri-param name="start-date">$2</uri-param>
         <param name="city" required="false"/>
         <param name="country" required="false"/>
         <param name="end-date" required="false"/>
         <param name="page" as="nonNegativeInteger" default="1"/>
         <param name="province" alias="state" required="false"/>
         <param name="set" required="false"/>
         <param name="tag" required="false" repeatable="true"/>
         <param name="xml" values="rdf|docbook"/>
       </request>

       <request uri="^/places/([^/]+)/(.+)/(.+)$"
                endpoint="/photos.xqy" user-params="forbid">
         <uri-param name="userid">$1</uri-param>
         <uri-param name="country">$2</uri-param>
         <uri-param name="city">$3</uri-param>
         <param name="end-date" required="false"/>
         <param name="page" as="nonNegativeInteger" default="1"/>
         <param name="province" alias="state" required="false"/>
         <param name="set" required="false"/>
         <param name="start-date" alias="date" required="false"/>
         <param name="tag" required="false" repeatable="true"/>
         <param name="xml" values="rdf|docbook"/>
       </request>

       <request uri="^/places/([^/]+)/(.+)$"
                endpoint="/photos.xqy" user-params="forbid">
         <uri-param name="userid">$1</uri-param>
         <uri-param name="country">$2</uri-param>
         <param name="city" required="false"/>
         <param name="end-date" required="false"/>
         <param name="page" as="nonNegativeInteger" default="1"/>
         <param name="province" alias="state" required="false"/>
         <param name="set" required="false"/>
         <param name="start-date" alias="date" required="false"/>
         <param name="tag" required="false" repeatable="true"/>
         <param name="xml" values="rdf|docbook"/>
       </request>

       <request uri="^/$" endpoint="/user.xqy" user-params="ignore">
         <param name="userid" default="ndw"/>
       </request>

       <request uri="^/ajax/changeVisibility"
                endpoint="/ajax/changeVisibility.xqy" user-params="forbid">
         <param name="uri" required="true"/>
         <param name="value" values="public|private|friends|family" required="true"/>
       </request>

       <request uri="^/ajax/set-title"
                endpoint="/ajax/change-set-title.xqy" user-params="forbid">
         <param name="uri" required="true"/>
         <param name="value" required="true"/>
       </request>

       <request uri="^/ajax/photo-title"
                endpoint="/ajax/change-photo-title.xqy" user-params="forbid">
         <param name="uri" required="true"/>
         <param name="value" required="true"/>
       </request>

       <request uri="^/ajax/set-user"
                endpoint="/ajax/change-user-title.xqy" user-params="forbid">
         <param name="uri" required="true"/>
         <param name="value" required="true"/>
       </request>

       <request uri="^/ajax/tag-title"
                endpoint="/ajax/change-tag-title.xqy" user-params="forbid">
         <param name="uri" required="true"/>
         <param name="value" required="true"/>
       </request>

       <request uri="^/ajax/add-tag"
                endpoint="/ajax/add-tag.xqy" user-params="forbid">
         <param name="uri" required="true"/>
         <param name="value" required="true"/>
       </request>

       <request uri="^/ajax/del-tag"
                endpoint="/ajax/del-tag.xqy" user-params="forbid">
         <param name="uri" required="true"/>
         <param name="value" required="true"/>
       </request>

       <request uri="^/ajax/tags/(.+)$"
                endpoint="/ajax/tags.xqy" user-params="forbid">
         <uri-param name="userid">$1</uri-param>
       </request>

       <request uri="^/ajax/del-geo"
                endpoint="/ajax/del-geo.xqy" user-params="forbid">
         <param name="uri" required="true"/>
       </request>

       <request uri="^/ajax/set-location"
                endpoint="/ajax/set-location.xqy" user-params="forbid">
         <http method="POST"/>
         <param name="uri" required="true"/>
         <param name="city"/>
         <param name="province"/>
         <param name="country" required="true"/>
       </request>

       <request uri="^/upload.xqy$" endpoint="/upload.xqy" user-params="forbid">
         <http method="POST"/>
         <param name="media" required="true"/>
         <param name="uri" required="true"/>
         <param name="file"/>
         <param name="skip" as="boolean" default="false"/>
         <param name="collection"/>
       </request>
     </options>;

declare private variable $endpoints:ok
  := if (empty(rest:check-options($endpoints:ENDPOINTS)))
     then ()
     else error((), "Bad endpoints");

declare function endpoints:options()
as element(rest:options)
{
  $endpoints:ENDPOINTS
};

declare function endpoints:request(
  $module as xs:string)
as element(rest:request)?
{
  ($endpoints:ENDPOINTS/rest:request[@endpoint = $module])[1]
};
