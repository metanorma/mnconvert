<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:oasis="-//OASIS//DTD XML Exchange Table Model 19990315//EN"
    exclude-result-prefixes="oasis">
    <!-- oasis elements: create a new element with the same name, but no namespace -->
    <xsl:template match="oasis:*" priority="1">
        <xsl:element name="{local-name()}">
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="*">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- attributes, commments, processing instructions, text: copy as is -->
    <xsl:template match="@*|comment()|processing-instruction()|text()">
        <xsl:copy-of select="."/>
    </xsl:template>
</xsl:stylesheet>
