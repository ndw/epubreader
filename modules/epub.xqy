xquery version "1.0-ml";

(: Assumptions:

   1. $EPUBDIR occurs in the path of each epub and what follows is /bookid/
      followed by the components of the book

   2. The toc.ncx file is in the root of the content.
:)

module namespace epub = "http://marklogic.com/modules/epub";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace container="urn:oasis:names:tc:opendocument:xmlns:container";
declare namespace package="http://www.idpf.org/2007/opf";
declare namespace ncx="http://www.daisy.org/z3986/2005/ncx/";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace ml="http://marklogic.com/ns/meta";
declare namespace zip="xdmp:zip";

declare variable $epub-collection := "http://marklogic.com/collection/epub";
declare variable $epub-infrastructure := "http://marklogic.com/collection/epub/infrastructure";
declare variable $epub-content := "http://marklogic.com/collection/epub/content";
declare variable $epub-book := "http://marklogic.com/collection/epub/book";

(: We assume all ebooks have a root of $EPUBDIR, even if that's under
   some other directory
:)
declare variable $EPUBDIR := "/epub/";

declare function epub:epub-zip($epub as node()) as xs:boolean {
  try {
    let $manifest := xdmp:zip-manifest($epub)
    return
      (string($manifest/zip:part[1]) = "mimetype")
      and $manifest/zip:part[. = "META-INF/container.xml"]
  } catch ($e) {
    false()
  }
};

declare function epub:id($epuburi as xs:string) as xs:string {
  let $s1 := if (contains($epuburi, $EPUBDIR))
             then substring-after($epuburi, $EPUBDIR)
             else $epuburi
  return
    if (contains($s1, "/"))
    then substring-before($s1, "/")
    else $s1
};

declare function epub:rootpath($epuburi as xs:string) as xs:string {
  let $id := epub:id($epuburi)
  let $slashedid := concat("/", $id, "/")
  return
    concat(substring-before($epuburi, $slashedid), $slashedid)
};

declare function epub:container($epuburi as xs:string) as element(container:container)? {
  let $curi := concat(epub:rootpath($epuburi), "META-INF/container.xml")
  return
    doc($curi)/container:container
};

declare function epub:content-root($epuburi as xs:string) as xs:string {
  let $container := epub:container($epuburi)
  let $rootpart  := $container/container:rootfiles/container:rootfile[1]
  return
    resolve-uri($rootpart/@full-path, epub:rootpath($epuburi))
};

declare function epub:package($epuburi as xs:string) as element(package:package)? {
  let $puri := epub:content-root($epuburi)
  return
    doc($puri)/package:package
};

declare function epub:toc($epuburi as xs:string) as element(ncx:ncx)? {
  let $package := epub:package($epuburi)
  let $tocs := $package/package:manifest/package:item[@media-type = "application/x-dtbncx+xml"]
  let $baseuri := epub:content-root($epuburi)
  let $tocuri  := resolve-uri($tocs[1]/@href, $baseuri)
  let $ncx := doc($tocuri)/ncx:ncx
  return
    <ncx:ncx xml:base='{base-uri($ncx)}'>
      { $ncx/@* }
      { $ncx/node() }
    </ncx:ncx>
};

declare function epub:coveruri($epuburi as xs:string) as xs:string? {
  let $package := epub:package($epuburi)
  let $meta    := $package/package:metadata
  let $coverid := string($meta/package:meta[@name='cover']/@content)
  let $baseuri := epub:content-root($epuburi)
  return
    if ($coverid != "")
    then
      resolve-uri($package/package:manifest/package:item[@id=$coverid]/@href, $baseuri)
    else
      "/graphics/nocover.jpg"
};

declare function epub:_partinfo($epuburi as xs:string, $point as element(ncx:navPoint)) {
 (<epub:playOrder>{string($point/@playOrder)}</epub:playOrder>,
  <epub:label>{string($point/ncx:navLabel/ncx:text)}</epub:label>,
  <epub:content>{resolve-uri($point/ncx:content/@src, base-uri($point))}</epub:content>)
};

declare function epub:partinfo($epuburi as xs:string) as element(epub:partinfo) {
  (: Assume that the toc.ncx is at the root of the tree... :)
  let $toc     := epub:toc($epuburi)
  let $tocpath := replace(base-uri($toc), "^(.*/)[^/]+$", "$1")
  let $page    := substring-after($epuburi, $tocpath)
  let $expoint := $toc//ncx:navPoint[ncx:content/@src = $page]
  let $axpoint := ($toc//ncx:navPoint[substring-before(ncx:content/@src,'#') = $page])[1]
  let $point   := ($expoint, $axpoint)[1]
  return
    epub:partinfo($epuburi, xs:integer($point/@playOrder))
};

declare function epub:prevpart($point as element(ncx:navPoint))
        as element(ncx:navPoint)?
{
  let $prevOrder := xs:integer($point/@playOrder) - 1
  let $src := string($point/ncx:content/@src)
  let $base := if (contains($src,"#")) then substring-before($src,"#") else $src
  let $prev := root($point)//ncx:navPoint[@playOrder = $prevOrder]
  return
    if (not(empty($prev)) and starts-with($prev/ncx:content/@src, $base))
    then
      epub:prevpart($prev)
    else
      $prev
};

declare function epub:nextpart($point as element(ncx:navPoint))
        as element(ncx:navPoint)?
{
  let $nextOrder := xs:integer($point/@playOrder) + 1
  let $src := string($point/ncx:content/@src)
  let $base := if (contains($src,"#")) then substring-before($src,"#") else $src
  let $next := root($point)//ncx:navPoint[@playOrder = $nextOrder]
  return
    if (not(empty($next)) and starts-with($next/ncx:content/@src, $base))
    then
      epub:nextpart($next)
    else
      $next
};

declare function epub:partinfo($epuburi as xs:string, $order as xs:integer)
        as element(epub:partinfo)
{
  let $toc   := epub:toc($epuburi)
  let $point := $toc//ncx:navPoint[@playOrder = $order]
  let $prev  := epub:prevpart($point)
  let $next  := epub:nextpart($point)
  let $parent:= $point/parent::ncx:navPoint
  return
    <epub:partinfo>
      <epub:maxParts>{count($toc//ncx:navPoint[@playOrder])}</epub:maxParts>
      { epub:_partinfo($epuburi, $point) }
      { if ($prev) then <epub:prev> { epub:_partinfo($epuburi, $prev) } </epub:prev> else () }
      { if ($next) then <epub:next> { epub:_partinfo($epuburi, $next) } </epub:next> else () }
      { if ($parent) then <epub:parent> { epub:_partinfo($epuburi, $parent) } </epub:parent> else () }
    </epub:partinfo>
};

declare function epub:load($epub as node()) as xs:string* {
  let $manifest  := xdmp:zip-manifest($epub)
  let $container := xdmp:zip-get($epub, 'META-INF/container.xml')
  let $rootpart  := $container/container:container/container:rootfiles/container:rootfile[1]
  let $contents  := xdmp:zip-get($epub, $rootpart/@full-path,
                                 <options xmlns="xdmp:zip-get">
                                   <format>xml</format>
                                 </options>)
  let $subjects  := $contents/package:package/package:metadata/dc:subject
  let $package   := <package:package>
                     { $contents/package:package/namespace::* }
                     { $contents/package:package/@* }
                     <package:metadata>
                       <ml:rating>0</ml:rating>
                       <ml:tags>
                         { for $subj in $subjects
                           let $ch := if (contains($subj, '/')) then "/" else ","
                           for $tok in tokenize($subj, $ch)
                           return <ml:tag>{normalize-space($tok)}</ml:tag>
                         }
                       </ml:tags>
                       { $contents/package:package/package:metadata/* }
                     </package:metadata>
                     { $contents/package:package/*[not(self::package:metadata)] }
                   </package:package>
  let $uniq-id  := string($package/@unique-identifier)
  let $uid      := string(($package//*[@id = $uniq-id])[1])
  let $dir      := if (starts-with($uid,'urn:isbn:'))
                   then substring-after($uid,'urn:isbn:')
                   else
                     if (starts-with($uid,'urn:uuid:'))
                     then substring-after($uid,'urn:uuid:')
                     else xdmp:integer-to-hex(xdmp:hash64($uid))
  let $book-collection := concat("http://marklogic.com/collection/epub/", $dir)

  let $map := map:map()

  (: insert the container.xml :)
  let $dbname := concat("/epub/", $dir, "/META-INF/container.xml")
  let $db     := xdmp:document-insert($dbname, $container, (),
                                      ($epub-collection, $epub-infrastructure, $book-collection))
  let $put := map:put($map, $dbname, 1)

  (: insert the package :)
  let $dbname := concat("/epub/", $dir, "/", $rootpart/@full-path)
  let $db      := xdmp:document-insert($dbname, $package, (),
                                       ($epub-collection, $epub-infrastructure, $book-collection))
  let $put := map:put($map, $dbname, 1)

  let $oebpsroot := resolve-uri($rootpart/@full-path, concat('/epub/', $dir, '/'))

  (: insert the contents :)
  let $unzipped
    := for $part in $package/package:manifest/package:item
       let $zipname := resolve-uri($part/@href, $rootpart/@full-path)
       let $dbname  := resolve-uri($part/@href, $oebpsroot)
       let $type    := if (ends-with($part/@media-type,'/xml')
                           or ends-with($part/@media-type,'+xml'))
                       then
                         "xml"
                       else
                         if (starts-with($part/@media-type, "text/"))
                         then "text"
                         else "binary"

       let $doc     := try {
                         xdmp:zip-get($epub, $zipname,
                                      <options xmlns="xdmp:zip-get">
                                        <format>{$type}</format>
                                      </options>)
                       } catch ($e1) {
                         try {
                           xdmp:zip-get($epub, xdmp:url-decode($zipname),
                                      <options xmlns="xdmp:zip-get">
                                        <format>{$type}</format>
                                      </options>)
                         } catch ($e2) {
                           xdmp:tidy(
                             xdmp:zip-get($epub, $zipname,
                                          <options xmlns="xdmp:zip-get">
                                            <format>text</format>
                                          </options>))[2]
                         }
                       }

       let $db      := if (empty(map:get($map, $dbname)))
                       then
                         if ($doc/*:html)
                         then
                           xdmp:document-insert($dbname, $doc, (),
                                                ($epub-collection, $epub-content, $book-collection))
                         else
                           xdmp:document-insert($dbname, $doc, (),
                                                ($epub-collection, $epub-infrastructure, $book-collection))
                       else
                         xdmp:log(concat("Ignoring attempt to insert duplicate: ", $dbname))
       return
         map:put($map, $dbname, 1)
  return
    map:keys($map)
};
