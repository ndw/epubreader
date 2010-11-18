xquery version "1.0-ml";

declare variable $url as xs:string := xdmp:get-request-url();
declare variable $baseurl as xs:string
  := if (contains($url,"?")) then substring-before($url, "?") else $url;
declare variable $command as xs:string
  := if (contains($url,"?")) then substring-after($url, "?") else "";

(:
let $trace := xdmp:log(concat("rewrite $url: ", $url))
let $trace := xdmp:log(concat("rewrite base: ", $baseurl))
:)

let $rewrite
  := if ($baseurl = "/")
     then
       concat("/default.xqy?",$command)
     else
       if (matches($baseurl, "/.*\.xqy$"))
       then
         $url
       else
         if (doc-available($baseurl))
         then
           concat("/part.xqy?url=", $url)
         else
           if (ends-with($url, ",raw"))
           then
             concat("/raw.xqy?url=", substring-before($url, ",raw"))
           else
             try {
               let $local := concat("/MarkLogic/epub", $url)
               let $node := xdmp:document-get($local)
               return
                 concat("/local.xqy?url=", $local)
             } catch ($e) {
               concat("/book.xqy?book=", $baseurl, "&amp;", $command)
             }
return
(:
  (xdmp:log(concat("epub rewrite ", $url, " to ", $rewrite)),
  $rewrite)
:)
  $rewrite

