xquery version "1.0-ml";

import module namespace epub="http://marklogic.com/modules/epub"
       at "/modules/epub.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace load="http://marklogic.com/ns/epub/load";
declare namespace zip="xdmp:zip";
declare namespace container="urn:oasis:names:tc:opendocument:xmlns:container";
declare namespace package="http://www.idpf.org/2007/opf";
declare namespace ncx="http://www.daisy.org/z3986/2005/ncx/";
declare namespace html="http://www.w3.org/1999/xhtml";

declare variable $epub-collection := "http://marklogic.com/collection/epub";

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

let $params    := load:load-params()
let $urlparam  := string($params/load:url)
let $url       := if (contains($urlparam,","))
                  then substring-before($urlparam, ",")
                  else $urlparam
let $command   := if (contains($urlparam,","))
                  then substring-after($urlparam, ",")
                  else ""
let $part      := doc($url)
return
  if (not($part/*:html))
  then
    $part
  else
    if ($command = "raw")
    then
      xdmp:xslt-invoke("/modules/fixlinks.xsl", $part)
    else
      let $headc  := $part/*:html/*:head/*
      let $bodyc  := $part/*:html/*:body/node()
      return
      <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
          { $headc/*:title }
          <script type="text/javascript" language="javascript" src="/script/jquery-1.4.2.min.js">
          </script>
          <script type="text/javascript" src="/script/jquery-ui-1.8.2.custom.min.js">
          </script>
          <link type="text/css" href="/style/ui-lightness/jquery-ui-1.8.2.custom.css"
                rel="stylesheet" />
          <script type="text/javascript" src="/script/part.js">
          </script>
          <link rel="stylesheet" href="/style/part.css"/>
        </head>
        <body>
          <div id="epub-header">
            { let $info  := epub:partinfo($url)
              let $root  := epub:rootpath($url)
              let $toc   := epub:toc($url)
              return
               (<input type="hidden" name="curplay" id="curplay" value="{$info/epub:playOrder}"/>,
                <input type="hidden" name="maxplay" id="maxplay" value="{$info/epub:maxParts}"/>,
                <table border="0" width="100%">
                  <tr>
                    <td width="32%"><a href="/">Library</a></td>
                    <td width="36%" align="center">
                      <span class="booktitle">
                        <a href="{$root}">
                          {string($toc/ncx:docTitle/ncx:text)}
                        </a>
                      </span>
                    </td>
                    <td width="32%">&#160;</td>
                  </tr>
                  <tr>
                    <td align="left">
                      { if ($info/epub:prev)
                        then
                          <span class="parttitle">
                            <a href="{resolve-uri($info/epub:prev/epub:content,$root)}">
                              { string($info/epub:prev/epub:label) }
                            </a>
                          </span>
                        else
                          ()
                      }
                    </td>
                    <td align="center">
                      { if ($info/epub:parent)
                        then
                          <span class="parttitle">
                            <a href="{resolve-uri($info/epub:parent/epub:content,$root)}">
                              { string($info/epub:parent/epub:label) }
                            </a>
                          </span>
                        else
                          ()
                      }
                    </td>
                    <td align="right">
                      { if ($info/epub:next)
                        then
                          <span class="parttitle">
                            <a href="{resolve-uri($info/epub:next/epub:content,$root)}">
                              { string($info/epub:next/epub:label) }
                            </a>
                          </span>
                        else
                          ()
                      }
                    </td>
                  </tr>
                </table>)
            }
          </div>
          <div id="iframe-wrapper"></div>
          <div id="barwrapper" class="barwrapper">
            <div id="progressbar"
                 title="Progress bar; the current page is this far into the book"></div>
          </div>
        </body>
      </html>


