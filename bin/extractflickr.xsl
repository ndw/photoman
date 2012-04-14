<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="2.0">

<xsl:output method="text" encoding="utf-8"/>

<xsl:param name="set" select="''"/>

<xsl:template match="photos">
  <xsl:choose>
    <xsl:when test="$set = ''">
      <xsl:apply-templates select="photo">
        <xsl:sort select="dates/@taken" order="descending"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates select="photo[contexts/set/@title = $set]"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="photo">
  <xsl:value-of select="substring-after(sizes/size[@label='Original']/@source, 'http://')"/>
  <xsl:text>&#10;</xsl:text>

  <xsl:variable name="date" select="string(dates/@taken)"/>
  <xsl:variable name="path" select="translate(substring-before($date, ' '), '-', '/')"/>
  <xsl:variable name="fn" select="@id"/>
  <xsl:value-of select="concat($path, '/', $fn, '.jpg')"/>
  <xsl:text>&#10;</xsl:text>
  <xsl:value-of select="string(title)"/>
  <xsl:text>&#10;</xsl:text>

  <xsl:for-each select="tags/tag">
    <xsl:value-of select="@raw"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:for-each>

  <xsl:if test="visibility/@ispublic != 1">
    <xsl:text>private&#10;</xsl:text>
  </xsl:if>

  <xsl:text>&#10;</xsl:text>
</xsl:template>

</xsl:stylesheet>
