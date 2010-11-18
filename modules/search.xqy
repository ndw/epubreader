xquery version "1.0-ml";

module namespace booksearch="http://marklogic.com/modules/epub/search";

import module namespace search="http://marklogic.com/appservices/search"
       at "/MarkLogic/appservices/search/search.xqy";

import module namespace epub="http://marklogic.com/modules/epub"
       at "/modules/epub.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace package="http://www.idpf.org/2007/opf";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace ml="http://marklogic.com/ns/meta";

declare variable $OPTIONS :=
  <options xmlns="http://marklogic.com/appservices/search">
    <constraint name="creator">
      <range collation="http://marklogic.com/collation/" type="xs:string">
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
        <element ns="http://purl.org/dc/elements/1.1/" name="creator"/>
      </range>
    </constraint>
    <constraint name="date">
      <range collation="http://marklogic.com/collation/" type="xs:string">
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
        <element ns="http://purl.org/dc/elements/1.1/" name="date"/>
      </range>
    </constraint>
    <constraint name="identifier">
      <range collation="http://marklogic.com/collation/" type="xs:string">
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
        <element ns="http://purl.org/dc/elements/1.1/" name="identifier"/>
      </range>
    </constraint>
    <constraint name="publisher">
      <range collation="http://marklogic.com/collation/" type="xs:string">
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
        <element ns="http://purl.org/dc/elements/1.1/" name="publisher"/>
      </range>
    </constraint>
    <constraint name="rating">
      <range collation="http://marklogic.com/collation/" type="xs:string">
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
        <element ns="http://marklogic.com/ns/meta" name="rating"/>
      </range>
    </constraint>
    <constraint name="subject">
      <range collation="http://marklogic.com/collation/" type="xs:string">
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
        <element ns="http://purl.org/dc/elements/1.1/" name="subject"/>
      </range>
    </constraint>
    <constraint name="tag">
      <range collation="http://marklogic.com/collation/" type="xs:string">
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
        <element ns="http://marklogic.com/ns/meta" name="tag"/>
      </range>
    </constraint>
    <constraint name="title">
      <range collation="http://marklogic.com/collation/" type="xs:string">
        <facet-option>frequency-order</facet-option>
        <facet-option>descending</facet-option>
        <facet-option>limit=10</facet-option>
        <element ns="http://purl.org/dc/elements/1.1/" name="title"/>
      </range>
    </constraint>

    <constraint name="id">
      <collection prefix="http://marklogic.com/collection/epub/"/>
    </constraint>

    <page-length>50</page-length>
  </options>;

declare function booksearch:books(
  $expr as xs:string,
  $bookids as xs:string*)
as element(search:response)
{
  let $ids
    := for $book in $bookids
       return
         concat("id:", $book)

  let $textopt := concat(" AND (", string-join($ids, " OR "), ")")

  return
    search:search(concat($expr,$textopt), $OPTIONS)
};

declare function booksearch:search-results(
  $page-header as element()*,
  $results as element(search:response))
as element()
{
  <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>Search results</title>
      <link rel="stylesheet" type="text/css" href="/style/library.css" />
      <script type="text/javascript" language="javascript" src="script/jquery-1.4.2.min.js">
      </script>
      <script type="text/javascript" src="script/library.js">
      </script>
    </head>
    <body>
      { $page-header }
      <hr/>
      <p>
        { let $count := xs:int($results/@page-length)
          let $total := xs:int($results/@total)
          return
            if ($total = 0)
            then "No documents match."
            else if ($total > $count)
                 then concat("Displaying ", $count, " of ", $total, " results.")
                 else concat("Displaying all ", $count, " results.")
        }
      </p>

      <dl>
        { for $result in $results/search:result
          let $uri  := string($result/@uri)
          let $doc  := doc($uri)
          let $book := epub:package($uri)
          return
            (<dt><a href="{epub:rootpath($uri)}">{string($book/package:metadata/dc:title)}</a>,
                 <a href="{$uri}">{string($doc/html/head/title)}</a></dt>,
             <dd>
               { for $snippet
                     in $result/search:snippet/search:match
                 return
                   <p>
                     { for $node in $snippet/node()
                       return
                         if ($node/self::search:highlight)
                         then
                           <b>{string($node)}</b>
                         else
                           string($node)
                     }
                   </p>
               }
             </dd>)
        }
      </dl>
    </body>
  </html>
};
