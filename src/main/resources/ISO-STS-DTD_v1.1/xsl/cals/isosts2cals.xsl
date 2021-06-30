<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:import href="lib/xhtml2cals.xsl"/>

    <xsl:template match="/*">
        <xsl:copy>
            <xsl:namespace name="oasis" select="'-//OASIS//DTD XML Exchange Table Model 19990315//EN'"/>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="processing-instruction() | comment()">
        <xsl:copy/>
    </xsl:template>

    <xsl:template match="table">
        <xsl:apply-templates select="." mode="xhtml2cals"/>
    </xsl:template>

</xsl:stylesheet>