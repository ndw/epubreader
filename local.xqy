xquery version "1.0-ml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare variable $url as xs:string := xdmp:get-request-field("url");

declare variable $root as xs:string := xdmp:modules-root();

xdmp:document-get(concat($root,if (starts-with($url, "/")) then substring($url,1) else $url))
