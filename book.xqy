xquery version "1.0-ml";

import module namespace booksearch="http://marklogic.com/modules/epub/search"
       at "/modules/search.xqy";

import module namespace epub="http://marklogic.com/modules/epub"
       at "/modules/epub.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace zip="xdmp:zip";
declare namespace container="urn:oasis:names:tc:opendocument:xmlns:container";
declare namespace package="http://www.idpf.org/2007/opf";
declare namespace ncx="http://www.daisy.org/z3986/2005/ncx/";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace ml="http://marklogic.com/ns/meta";

declare variable $epub-collection := "http://marklogic.com/collection/epub";

let $bookparam := xdmp:get-request-field('book')
let $search    := xdmp:get-request-field('search')
let $container := epub:container($bookparam)
let $book      := epub:package($bookparam)

let $meta      := $book/package:metadata
let $cover     := epub:coveruri($bookparam)
let $title     := string($meta/dc:title)

let $abstext := replace($meta/dc:description, "\\n", " ")
let $abstract := try { xdmp:unquote(concat('<div>', $abstext, '</div>')) }
                 catch ($e) { <div>{ $abstext }</div> }

let $uidid     := string($book/@unique-identifier)
let $uid       := string($meta/*[@id=$uidid][1])

return
  if ($search != "")
  then
    let $id := epub:id($bookparam)
    let $results := booksearch:books($search, $id)
    let $header
      := <div xmlns="http://www.w3.org/1999/xhtml">
           <span>Back to </span>
           <a href="{$bookparam}">{$title}</a>
         </div>
    return
      booksearch:search-results($header, $results)
  else
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>{$title}</title>
      <script type="text/javascript" language="javascript" src="/script/jquery-1.4.2.min.js">
      </script>
      <script type="text/javascript" src="/script/epub.js">
      </script>
      <link rel="stylesheet" type="text/css" href="/style/book.css" />
    </head>
    <body>
      <form id="subset" action="{$bookparam}" method="get">
        <table border="0" width="100%">
          <tr>
            <td align="left" width="50%" valign="bottom"><a href="/">Library</a></td>
            <td align="right" valign="bottom">
              <input type="text" id="search" name="search" size="25" value=""/>
            </td>
          </tr>
        </table>
        <hr/>
      </form>
      <table border="0">
        <tr>
          <td valign="top">
            <div class="cover">
              { if ($cover = '/graphics/nocover.jpg')
                then
                  <div class="title">{$title}</div>
                else
                  ()
              }
              <img width="300"
                   src="{$cover}"
                   title="Cover"/>
            </div>
          </td>
          <td valign="top">
            <table border="0">
              <tr>
                <td valign="top">&#160;</td>
                <td valign="top"><span class="title">{$title}</span></td>
              </tr>
              { for $rights in $meta/dc:rights
                return
                  <tr>
                    <td>&#160;</td>
                    <td valign="top">{string($rights)}</td>
                  </tr>
              }
              { for $date at $index in $meta/dc:date
                return
                  <tr>
                    <td valign="top" align="right">
                      { if ($index = 1)
                        then
                          concat("Date", if (count($meta/dc:date) > 1)
                                         then "s:" else ":", "&#160;")
                        else
                          "&#160;"
                      }
                    </td>
                    <td valign="top">{string($date)}</td>
                  </tr>
              }
              { for $creator at $index in $meta/dc:creator
                return
                  <tr>
                    <td valign="top" align="right">
                      { if ($index = 1)
                        then
                          concat("Author", if (count($meta/dc:creator) > 1)
                                           then "s:" else ":", "&#160;")
                        else
                          "&#160;"
                      }
                    </td>
                    <td valign="top">{string($creator)}</td>
                  </tr>
              }
              { for $publ at $index in $meta/dc:publisher
                return
                  <tr>
                    <td valign="top" align="right">
                      { if ($index = 1)
                        then
                          concat("Publisher",
                                 if (count($meta/dc:publisher) > 1)
                                 then "s:" else ":", "&#160;")
                        else
                          "&#160;"
                      }
                    </td>
                    <td valign="top">{string($publ)}</td>
                  </tr>
              }
              <tr>
                <td valign="top" align="right">ID:&#160;</td>
                <td valign="top">{$uid}</td>
              </tr>
              <tr>
                <td valign="top" align="right">Rating:&#160;</td>
                <td valign="top">
                  { let $stars := xs:integer($meta/ml:rating)
                    for $rating in (1 to 5)
                    return
                      <span id="star{$rating}"
                            title="{$rating} star{if ($rating > 1) then 's' else ''}"
                            class="star {if ($stars >= $rating) then 'on' else 'off'}">
                            { "★ " }
                      </span>
                  }
                  <span id="star0"
                        title="no stars"
                        class="star {if ($meta/ml:rating = '0') then 'on' else 'off'}">
                        { "&#x20e0; " }
                  </span>
                </td>
              </tr>
              { for $subj at $index in $meta/dc:subject
                return
                  <tr>
                    <td valign="top" align="right">
                      { if ($index = 1)
                        then
                          concat("Subject",
                                 if (count($meta/dc:subject) > 1) then "s:" else ":", "&#160;")
                        else
                          "&#160;"
                      }
                    </td>
                    <td valign="top">{string($subj)}</td>
                  </tr>
              }
              <tr>
                <td valign="top" align="right">Tags:&#160;</td>
                <td valign="top">
                  { let $tags := for $tag in $meta/ml:tags/ml:tag return string($tag)
                     return
                      <input id="tags" name="tags" type="text" size="60"
                             value="{string-join($tags,', ')}"/>
                  }
                </td>
              </tr>
              <tr>
                <td>&#160;</td>
                <td>{$abstract}</td>
              </tr>
            </table>
          </td>
        </tr>
      </table>

      <hr/>

      { xdmp:xslt-invoke('/modules/ncx2html.xsl', epub:toc($bookparam)) }

    </body>
  </html>
