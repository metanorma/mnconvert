<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:css="http://www.iso.org/ns/css-parser" 
    xmlns:css2cals="http://www.iso.org/ns/css2cals"
    exclude-result-prefixes="css css2cals"
    version="2.0">
    <xsl:output indent="yes" method="xhtml"/>
    <xsl:include href="../lib/xhtml2cals.xsl"/>
    <xsl:variable name="test-cases">
        <test>
            <style>border: solid 1px #123456</style>
            <dbr>true</dbr>
            <sbr>true</sbr>
            <dbb>true</dbb>
            <sbb>true</sbb>
            <colsep>yes</colsep>
            <rowsep>yes</rowsep>
        </test>
        <test>
            <style>border-right: solid 1.0px</style>
            <dbr>true</dbr>
            <sbr>true</sbr>
            <dbb>false</dbb>
            <sbb>false</sbb>
            <colsep>yes</colsep>
            <rowsep>table default</rowsep>
        </test>
        <test>
            <style>border-right-style: solid; border-right-width: 1.0px</style>
            <dbr>true</dbr>
            <sbr>true</sbr>
            <dbb>false</dbb>
            <sbb>false</sbb>
            <colsep>yes</colsep>
            <rowsep>table default</rowsep>
        </test>
        <test>
            <style>border: solid 1px; border-right-width: 0</style>
            <dbr>true</dbr>
            <sbr>false</sbr>
            <dbb>true</dbb>
            <sbb>true</sbb>
            <colsep>no</colsep>
            <rowsep>yes</rowsep>
        </test>
        <test>
            <style>border: solid 1px; border-right-style: none</style>
            <dbr>true</dbr>
            <sbr>false</sbr>
            <dbb>true</dbb>
            <sbb>true</sbb>
            <colsep>no</colsep>
            <rowsep>yes</rowsep>
        </test>
        <test>
            <style>border-bottom: solid 1.0px</style>
            <dbr>false</dbr>
            <sbr>false</sbr>
            <dbb>true</dbb>
            <sbb>true</sbb>
            <colsep>table default</colsep>
            <rowsep>yes</rowsep>
        </test>
        <test>
            <style>border-bottom-style: solid; border-bottom-width: 1.0px</style>
            <dbr>false</dbr>
            <sbr>false</sbr>
            <dbb>true</dbb>
            <sbb>true</sbb>
            <colsep>table default</colsep>
            <rowsep>yes</rowsep>
        </test>
        <test>
            <style>border-right: solid 1px; border-bottom: solid 2px</style>
            <dbr>true</dbr>
            <sbr>true</sbr>
            <dbb>true</dbb>
            <sbb>true</sbb>
            <colsep>yes</colsep>
            <rowsep>yes</rowsep>
        </test>
        <test>
            <style>border: solid 1;border-right: 0px; border-bottom: 0px</style>
            <dbr>true</dbr>
            <sbr>false</sbr>
            <dbb>true</dbb>
            <sbb>false</sbb>
            <colsep>no</colsep>
            <rowsep>no</rowsep>
        </test>
        <test>
            <style>border: 0</style>
            <dbr>true</dbr>
            <sbr>false</sbr>
            <dbb>true</dbb>
            <sbb>false</sbb>
            <colsep>no</colsep>
            <rowsep>no</rowsep>
        </test>
    </xsl:variable>
    <xsl:template match="/">
        <html>
            <head>
                <title>Test cases to convert table CSS to cals settings</title>
            </head>
            <body>
                <h2>Test cases to convert table CSS to cals settings</h2>
                <table cellspacing="10">
                    <thead>
                        <tr>
                            <th>CSS definition</th>
                            <th>Border right defined</th>
                            <th>Border right displayed</th>
                            <th>Border bottom defined</th>
                            <th>Border bottom displayed</th>
                            <th>CALS entry colsep</th>
                            <th>CALS entry rowsep</th>
                        </tr>
                    </thead>
                    <tbody>
                        <xsl:for-each select="$test-cases/test">
                            <xsl:variable name="test-case" select="normalize-space(style)"/>
                            <xsl:variable name="css" select="css:parse(style)"/>
                            <xsl:variable name="res-dbr" select="css2cals:definesBorderRight($css)"/>
                            <xsl:variable name="res-sbr" select="css2cals:showBorderRight($css)"/>
                            <xsl:variable name="res-dbb" select="css2cals:definesBorderBottom($css)"/>
                            <xsl:variable name="res-sbb" select="css2cals:showBorderBottom($css)"/>
                            <xsl:variable name="res-colsep">
                                <xsl:choose>
                                    <xsl:when test="$res-dbr">
                                        <xsl:choose>
                                            <xsl:when test="$res-sbr">
                                                yes
                                            </xsl:when>
                                            <xsl:otherwise>
                                                no
                                            </xsl:otherwise>
                                        </xsl:choose>                        
                                    </xsl:when>
                                    <xsl:otherwise>table default</xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>
                            <xsl:variable name="res-rowsep">
                                <xsl:choose>
                                    <xsl:when test="$res-dbb">
                                        <xsl:choose>
                                            <xsl:when test="$res-sbb">
                                                yes
                                            </xsl:when>
                                            <xsl:otherwise>
                                                no
                                            </xsl:otherwise>
                                        </xsl:choose>                        
                                    </xsl:when>
                                    <xsl:otherwise>table default</xsl:otherwise>
                                </xsl:choose>                                
                            </xsl:variable>
                            <tr>
                                <td>
                                    <xsl:attribute name="style" select="style"/>
                                    <xsl:value-of select="style"/>
                                </td>
                                <td>
                                    <xsl:if test="$res-dbr != dbr">
                                        <xsl:attribute name="style">background-color:
                                            red</xsl:attribute>
                                    </xsl:if>
                                    <xsl:value-of select="$res-dbr"/>
                                </td>
                                <td>
                                    <xsl:if test="$res-sbr != sbr">
                                        <xsl:attribute name="style">background-color:
                                            red</xsl:attribute>
                                    </xsl:if>
                                    <xsl:value-of select="$res-sbr"/>
                                </td>
                                <td>
                                    <xsl:if test="$res-dbb != dbb">
                                        <xsl:attribute name="style">background-color:
                                            red</xsl:attribute>
                                    </xsl:if>
                                    <xsl:value-of select="$res-dbb"/>
                                </td>
                                <td>
                                    <xsl:if test="$res-sbb != sbb">
                                        <xsl:attribute name="style">background-color:
                                            red</xsl:attribute>
                                    </xsl:if>
                                    <xsl:value-of select="$res-sbb"/>
                                </td>
                                <td>
                                    <xsl:if test="normalize-space($res-colsep) != normalize-space(colsep)">
                                        <xsl:attribute name="style">background-color: red</xsl:attribute>
                                        (expected: <xsl:value-of select="colsep"/>)
                                    </xsl:if>
                                    <xsl:value-of select="$res-colsep"/>
                                </td>
                                <td>
                                    <xsl:if test="normalize-space($res-rowsep) != normalize-space(rowsep)">
                                        <xsl:attribute name="style">background-color: red</xsl:attribute>
                                        (expected: <xsl:value-of select="rowsep"/>)
                                    </xsl:if>
                                    <xsl:value-of select="$res-rowsep"/>
                                </td>
                            </tr>
                        </xsl:for-each>
                    </tbody>
                </table>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
