<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="2.0">

<xsl:output method="xml" encoding="utf-8" indent="yes"
	    omit-xml-declaration="yes"/>

<xsl:template match="tag">
  <xsl:variable name="this" select="."/>
  <xsl:variable name="subtags" select="distinct-values(tag/@name)"/>

  <tag name="{@name}">
    <xsl:for-each select="$subtags">
      <xsl:sort select="." order="ascending"/>
      <xsl:variable name="name" select="."/>
      <xsl:apply-templates select="($this/tag[@name = $name])[1]"/>
    </xsl:for-each>
  </tag>
</xsl:template>

</xsl:stylesheet>
