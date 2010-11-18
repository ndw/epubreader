xquery version "1.0-ml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace load="http://marklogic.com/ns/epub/load";
declare namespace package="http://www.idpf.org/2007/opf";
declare namespace container="urn:oasis:names:tc:opendocument:xmlns:container";
declare namespace ncx="http://www.daisy.org/z3986/2005/ncx/";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace ml="http://marklogic.com/ns/meta";

declare function load:load-params() as element(load:params) {
  <load:params>
    { for $i in xdmp:get-request-field-names()
      return
        for $j in xdmp:get-request-field($i)
        return
          if ($i castable as xs:NCName)
          then
            element { xs:QName(concat("load:", $i)) } { $j }
          else
            ()
    }
  </load:params>
};

declare function load:tokenizeTags($tags as xs:string) as xs:string* {
  let $toks := tokenize($tags, ",")
  for $tok in $toks
  return
    normalize-space($tok)
};

declare function load:parseTags($tags as xs:string) {
  for $tok in load:tokenizeTags($tags)
  return
    <ml:tag>{$tok}</ml:tag>
};

declare function load:normalizeTags($tags as xs:string) {
  string-join(load:tokenizeTags($tags), ", ")
};

let $params := load:load-params()
let $action := string($params/load:action)
let $bookid := substring-after($params/load:book, '/epub/')
let $container := doc(concat('/epub/',$bookid,'META-INF/container.xml'))
let $rooturi := string($container/container:container/container:rootfiles/container:rootfile[1]/@full-path)
let $book   := doc(concat('/epub/',$bookid,$rooturi))/package:package
let $meta   := $book/package:metadata
let $rating := string($params/load:rating)
let $tags   := string($params/load:tags)
return
  if ($action = 'rating')
  then
    (if ($meta/ml:rating)
     then
       xdmp:node-replace($meta/ml:rating, <ml:rating>{$rating}</ml:rating>)
     else
       xdmp:node-insert-child($meta, <ml:rating>{$rating}</ml:rating>),
     <rating>{$rating}</rating>)
  else
    if ($action = 'tags')
    then
      (if ($meta/ml:tags)
       then
         xdmp:node-replace($meta/ml:tags, <ml:tags>{load:parseTags($tags)}</ml:tags>)
       else
         xdmp:node-insert-child($meta, <ml:tags>{load:parseTags($tags)}</ml:tags>),
       <tags>{load:normalizeTags($tags)}</tags>)
    else
      <unknown-action>{$action}</unknown-action>
