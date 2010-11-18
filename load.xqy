xquery version "1.0-ml";

import module namespace epub="http://marklogic.com/modules/epub" at "/modules/epub.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace zip="xdmp:zip";

declare variable $type := xdmp:get-request-header('Content-Type');
declare variable $epub := xdmp:get-request-body("binary");

if (epub:epub-zip($epub))
then
  let $uris := epub:load($epub)
  return
    concat("Loaded ", count($uris), " pages.")
else
  "Error: posted file does not appear to be a DRM-free EPUB file."
