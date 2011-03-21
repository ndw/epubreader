xquery version "1.0-ml";

declare variable $url as xs:string := xdmp:get-request-url();

declare variable $baseurl as xs:string
  := if (contains($url,"?")) then substring-before($url, "?") else $url;

declare variable $command as xs:string
  := if (contains($url,"?")) then substring-after($url, "?") else "";

declare variable $root as xs:string := xdmp:modules-root();

declare variable $debug as xs:boolean := false();

let $rewrite
  := if ($baseurl = "/")
     then
       concat("/default.xqy",if ($command = "") then "" else concat("?", $command))
     else
       if ($baseurl = "/favicon.ico")
       then
         concat("/local.xqy?url=/graphics/epubicon.png")
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
                 let $local := concat($root,if (starts-with($url, "/")) then substring($url,1) else $url)
                 let $node := xdmp:document-get($local)
                 return
                   concat("/local.xqy?url=", $url)
               } catch ($e) {
                 concat("/book.xqy?book=", $baseurl,
                        if ($command = "") then "" else concat("&amp;", $command))
               }
return
  (if ($debug) then xdmp:log(concat("epub rewrite ", $url, " to ", $rewrite)) else (),
   $rewrite)
