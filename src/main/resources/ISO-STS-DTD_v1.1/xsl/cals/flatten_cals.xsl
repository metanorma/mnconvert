<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:oasis="-//OASIS//DTD XML Exchange Table Model 19990315//EN" version="2.0"
    exclude-result-prefixes="oasis">
    <xsl:output indent="yes"/>
    <xsl:template match="/">
        <tables>
            <xsl:apply-templates/>
        </tables>
    </xsl:template>
    <xsl:template match="oasis:*" priority="2">
        <xsl:element name="{local-name(.)}">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="*">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="text()"> </xsl:template>
</xsl:stylesheet>
