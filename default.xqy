xquery version "1.0-ml";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

import module namespace booksearch="http://marklogic.com/modules/epub/search"
       at "/modules/search.xqy";

import module namespace epub="http://marklogic.com/modules/epub"
       at "/modules/epub.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace f="http://marklogic.com/ns/functions";
declare namespace zip="xdmp:zip";
declare namespace container="urn:oasis:names:tc:opendocument:xmlns:container";
declare namespace package="http://www.idpf.org/2007/opf";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace ml="http://marklogic.com/ns/meta";
declare namespace prop="http://marklogic.com/xdmp/property";

declare variable $epub-collection := "http://marklogic.com/collection/epub";
declare variable $books-per-row := 5;

declare variable $COOKIES as element(cookie)* :=
  for $c in tokenize(xdmp:get-request-header("cookie"), ";\s*")[. ne '']
  return element cookie {
    let $toks := tokenize($c, "=")
    return (
      attribute key { xdmp:url-decode($toks[1]) },
      attribute value { xdmp:url-decode($toks[2]) }
    )
  };

declare variable $epub-cookie := $COOKIES[@key='epub-cookie']/@value/string();
declare variable $epub-def  := tokenize($epub-cookie, ",");
declare variable $display   := f:field-value("display", $epub-def[1], "shelf");
declare variable $publisher := f:field-value("publisher", $epub-def[2], "all");
declare variable $author    := f:field-value("author", $epub-def[3], "all");
declare variable $tag       := f:field-value("tag", $epub-def[4], "any");
declare variable $rating    := f:field-value("rating", $epub-def[5], "any");
declare variable $orderby   := f:field-value("orderby", $epub-def[6], "pubdate");
declare variable $search    := f:field-value("search", $epub-def[7], "");

declare option xdmp:output "method=html";

declare function f:field-value($field as xs:string,
                               $cookie as xs:string?,
                               $defdef as xs:string)
as xs:string
{
  let $default := if (empty($cookie)) then $defdef else $cookie
  return
  if (xdmp:get-request-field($field))
  then
    xdmp:get-request-field($field)
  else
    $default
};

declare function f:shelf($books as element(package:package)*) {
  let $rows  := floor((count($books) + $books-per-row - 1) div $books-per-row)
  return
  <table border="0" cellpadding="15" xmlns="http://www.w3.org/1999/xhtml">
    { for $row in (0 to $rows - 1)
      return
        <tr>
          { for $col in (1 to $books-per-row)
            let $idx := ($row * $books-per-row) + $col
            let $book := $books[$idx]
            let $meta := $book/package:metadata
            let $title := string($meta/dc:title)

            let $abstext := replace($meta/dc:description, "\\n", " ")
            let $abstract
              := if (contains($abstext, "<"))
                 then xdmp:unquote(concat('<div>', $abstext, '</div>'))
                 else <div>{$abstext}</div>

            let $cover := epub:coveruri(base-uri($book))
            let $root := epub:rootpath(base-uri($book))
            let $id := $root
            return
              if (empty($book))
              then
                <td>&#160;</td>
              else
                <td valign="bottom">
                  <div class="cover">
                    { if ($cover = '/graphics/nocover.jpg')
                      then
                        <div class="title">{$title}</div>
                      else
                        ()
                    }
                    <a href="{$id}">
                      <img width="150" border="0"
                           src="{$cover}"
                           title="{$title}: {$abstract}"/>
                    </a>
                  </div>
                </td>
          }
        </tr>
    }
  </table>
};

declare function f:order-by($book as element(package:package)) {
  if ($orderby = 'pubdate')
  then
    ($book/package:metadata/dc:date)[1]
  else if ($orderby = 'update')
       then
         xdmp:document-get-properties(xdmp:node-uri($book), xs:QName("prop:last-modified"))
       else
         ($book/package:metadata/dc:title)[1]
};

declare function f:list($books as element(package:package)*) {
  for $book at $index in $books
  let $meta := $book/package:metadata
  let $title := string($meta/dc:title)

  let $abstext := replace($meta/dc:description, "\\n", " ")
  let $abstract := try { xdmp:unquote(concat('<div>', $abstext, '</div>')) }
                   catch ($e) { <div>{ $abstext }</div> }

  let $cover := epub:coveruri(base-uri($book))
  let $root := epub:rootpath(base-uri($book))
  let $id := $root

  order by f:order-by($book) descending
  return
    <div class="blbook {if ($index mod 2 = 0) then 'odd' else 'even'}">
      <img height="125" border="0" class="blcover"
           src="{$cover}" align="right" alt="Cover"/>
      <div class="title">
        <a href="{$id}">{$title}</a>
      </div>
      { $abstract }
      <br clear="right"/>
    </div>
};

declare function f:form(
  $display as xs:string,
  $publisher as xs:string,
  $author as xs:string,
  $tag as xs:string,
  $rating as xs:string)
{
  <form id="subset" action="/" method="get" xmlns="http://www.w3.org/1999/xhtml">
    <p>
      <select id="display" name="display">
        <option value="list">
          { if ($display = "list") then attribute { "selected" } { "selected" } else () }
          { "List" }
        </option>
        <option value="shelf">
          { if ($display = "shelf") then attribute { "selected" } { "selected" } else () }
          { "Shelf" }
        </option>
      </select>
      { " of " }
      <select id="publisher" name="publisher">
        <option value="all">
          { if ($publisher = "all") then attribute { "selected" } { "selected" } else () }
          { "all" }
        </option>
        { for $pub in cts:element-values(xs:QName("dc:publisher"))
          return
            <option value="{$pub}">
              { if ($publisher = $pub)
                then attribute { "selected" } { "selected" }
                else ()
              }
              {$pub}
            </option>
        }
      </select>
      { " books by " }
      <select id="author" name="author">
        <option value="all">
          { if ($author = "all") then attribute { "selected" } { "selected" } else () }
          { "any author" }
        </option>
        { for $auth in cts:element-values(xs:QName("dc:creator"))
          return
            <option value="{$auth}">
              { if ($author = $auth) then attribute { "selected" } { "selected" } else () }
              { if (string-length($auth) > 24)
                then concat(substring($auth, 1, 21), "...")
                else $auth
              }
            </option>
         }
      </select>
      { " ordered by " }
      <select id="orderby" name="orderby">
        <option value="title">
          { if ($orderby = "title") then attribute { "selected" } { "selected" } else () }
          { "Title" }
        </option>
        <option value="pubdate">
          { if ($orderby = "pubdate") then attribute { "selected" } { "selected" } else () }
          { "Publication date" }
        </option>
        <option value="update">
          { if ($orderby = "update") then attribute { "selected" } { "selected" } else () }
          { "Last updated" }
        </option>
      </select>
    </p>
    <p>
      { "Tagged " }
      <select id="tag" name="tag">
        <option value="any">
          { if ($tag = "any") then attribute { "selected" } { "selected" } else () }
          { "any" }
        </option>
        { for $t in cts:element-values(xs:QName("ml:tag"))
          return
            <option value="{$t}">
              { if ($tag = $t) then attribute { "selected" } { "selected" } else () }
              { if (string-length($t) > 16)
                then concat(substring($t, 1, 13), "...")
                else $t
              }
            </option>
        }
      </select>
      { " with a rating of " }
      <select id="rating" name="rating">
        <option value="any">
          { if ($rating = "any") then attribute { "selected" } { "selected" } else () }
          { "☆" }
        </option>
        { for $r in ("1","2","3","4","5")
          return
            <option value="{$r}">
              { if ($rating = $r) then attribute { "selected" } { "selected" } else () }
              { concat($r, " ☆") }
            </option>
        }
      </select>
      { ", or search: " }
      <input type="text" id="search" name="search" size="25" value="{$search}"/>
    </p>
  </form>
};

declare function f:search-results($results as element(search:response)) {
  let $header := f:form($display, $publisher, $author, $tag, $rating)
  return
    booksearch:search-results($header, $results)
};

let $q-publisher := if ($publisher = "all")
                    then ()
                    else cts:element-value-query(xs:QName("dc:publisher"), $publisher)

let $q-author := if ($author = "all")
                 then ()
                 else cts:element-value-query(xs:QName("dc:creator"), $author)

let $q-tag    := if ($tag = "any")
                 then ()
                 else cts:element-value-query(xs:QName("ml:tag"), $tag)

let $q-rating := if ($rating = "any")
                 then ()
                 else cts:element-range-query(xs:QName("ml:rating"), ">=", $rating)

let $queries  := ($q-publisher, $q-author, $q-tag, $q-rating)
let $query    := if (empty($queries))
                 then ()
                 else cts:and-query($queries)

let $matching-books
  := if (empty($query))
     then collection($epub-collection)/package:package
     else
       cts:search(collection($epub-collection)/package:package, $query)

let $books
  := for $book in $matching-books
     order by $book/package:metadata/dc:title
     return
       $book

(: deal with cookies :)
let $cookie-name  := "epub-cookie"
(: search is intentionally excluded, because it doesn't default well :)
let $cookie-value
  := string-join(($display,$publisher,$author,$tag,$rating,$orderby), ",")
let $cookie-param := ";path=/;port=8300"
let $set-cookie   := concat($cookie-name,"=",$cookie-value,$cookie-param)
return
  (xdmp:add-response-header("Set-Cookie", $set-cookie),
  if ($search != "")
  then
    let $ids
      := for $book in $books
         return
           epub:id(xdmp:node-uri($book))
    let $results := booksearch:books($search, $ids)
    return
      f:search-results($results)
  else
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>Library</title>
        <link rel="stylesheet" type="text/css" href="/style/library.css" />
        <script type="text/javascript" language="javascript" src="script/jquery-1.4.2.min.js">
        </script>
        <script type="text/javascript" src="script/library.js">
        </script>
        <link rel="icon" href="/graphics/epubicon.png" type="image/png" />
      </head>
      <body>
        { f:form($display, $publisher, $author, $tag, $rating) }
        <hr/>

        { if ($display = 'shelf')
          then
            f:shelf(for $book in $books
                    order by f:order-by($book) descending
                    return $book)
          else
            f:list($books)
        }
      </body>
    </html>)
