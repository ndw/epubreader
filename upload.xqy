xquery version "1.0-ml";

import module namespace epub="http://marklogic.com/modules/epub" at "/modules/epub.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare variable $epub := xdmp:get-request-field("epubfile");

if (empty($epub))
then
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Upload your EPUB file</title>
      <link rel="icon" href="/graphics/epubicon.png" type="image/png" />
    </head>
    <body>
      <p>Use this form to upload EPUB files.</p>
      <form action="/upload.xqy" method="post" enctype="multipart/form-data">
        <p>EPUB file: <input type="file" name="epubfile" size="40"/></p>
        <p><input type="submit" value="Upload"/></p>
      </form>
    </body>
  </html>
else
  if (epub:epub-zip($epub))
  then
    let $uris := epub:load($epub)
    return
      concat("Loaded ", count($uris), " pages.")
  else
    "Error: posted file does not appear to be a DRM-free EPUB file."
