<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
		exclude-result-prefixes="xs"
                version="2.0">

<xsl:output method="text" encoding="utf-8"/>

<xsl:template match="photos">
  <xsl:variable name="photos" select="."/>
  <xsl:variable name="set-ids"
                select="distinct-values(photo/contexts/set/@id)"/>

  <xsl:variable name="sets" as="element()+">
    <xsl:for-each select="$set-ids">
      <xsl:variable name="id" select="."/>
      <xsl:sequence select="($photos/photo/contexts/set[@id = $id])[1]"/>
    </xsl:for-each>
  </xsl:variable>

  <xsl:variable name="set-names" as="xs:string*">
    <xsl:for-each select="$sets">
      <xsl:value-of select="translate(
                               translate(lower-case(@title), ' /', '--'),
                               ',;:''`',
                               '')"/>
    </xsl:for-each>
  </xsl:variable>

  <xsl:if test="count($set-ids) != count($set-names)">
    <xsl:message terminate="yes">Duplicate titles?</xsl:message>
  </xsl:if>

  <xsl:text># not in any set&#10;</xsl:text>
  <xsl:text> </xsl:text>
  <xsl:apply-templates select="$photos/photo[not(contexts/set)]"/>
  <xsl:text>&#10;</xsl:text>

  <xsl:for-each select="$sets">
    <xsl:variable name="id" select="@id"/>
    <xsl:variable name="set" select="translate(
                                       translate(lower-case(@title), ' /', '--'),
                                       ',;:''`',
                                       '')"/>
    <xsl:text>-c </xsl:text>
    <xsl:value-of select="$set"/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="$photos/photo[contexts/set[@id = $id]]"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:for-each>
</xsl:template>

<xsl:template match="photo">
  <xsl:variable name="date" select="string(dates/@taken)"/>
  <xsl:variable name="path" select="translate(substring-before($date, ' '), '-', '/')"/>
  <xsl:variable name="fn" select="@id"/>
  <xsl:value-of select="concat($path, '/', $fn, '.jpg')"/>
  <xsl:text> </xsl:text>
</xsl:template>

</xsl:stylesheet>
