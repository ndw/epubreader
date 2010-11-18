<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ncx="http://www.daisy.org/z3986/2005/ncx/"
                xmlns:xdmp="http://marklogic.com/xdmp"
                exclude-result-prefixes="ncx xdmp"
                version="2.0">

<xsl:output method="xhtml" encoding="utf-8" indent="no"
	    omit-xml-declaration="yes"/>

<xsl:strip-space elements="*"/>

<xsl:template match="/">
  <xsl:apply-templates select="ncx:ncx/ncx:navMap"/>
</xsl:template>

<xsl:template match="ncx:ncx">
  <xsl:apply-templates select="ncx:navMap"/>
</xsl:template>

<xsl:template match="ncx:navMap">
  <dl>
    <xsl:apply-templates select="ncx:navPoint"/>
  </dl>
</xsl:template>

<xsl:template match="ncx:navPoint">
  <dt>
    <xsl:choose>
      <xsl:when test="ncx:content">
        <a href="{resolve-uri(ncx:content[1]/@src, base-uri(.))}">
          <xsl:value-of select="ncx:navLabel[1]/ncx:text"/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="ncx:navLabel[1]/ncx:text"/>
      </xsl:otherwise>
    </xsl:choose>
  </dt>
  <xsl:if test="ncx:navPoint">
    <dd>
      <dl>
        <xsl:apply-templates select="ncx:navPoint"/>
      </dl>
    </dd>
  </xsl:if>
</xsl:template>

<xsl:template match="*">
  <xsl:copy>
    <xsl:copy-of select="@*"/>
    <xsl:apply-templates/>
  </xsl:copy>
</xsl:template>

<xsl:template match="comment()|processing-instruction()|text()">
  <xsl:copy/>
</xsl:template>

</xsl:stylesheet>
