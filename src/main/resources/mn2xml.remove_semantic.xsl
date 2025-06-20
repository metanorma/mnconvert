<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
			xmlns:mml="http://www.w3.org/1998/Math/MathML" 
			xmlns:xlink="http://www.w3.org/1999/xlink" 
			xmlns:xalan="http://xml.apache.org/xalan" 
			xmlns:java="http://xml.apache.org/xalan/java" 
			xmlns:redirect="http://xml.apache.org/xalan/redirect"
			xmlns:metanorma-class="xalan://org.metanorma.utils.RegExHelper"
			exclude-result-prefixes="xalan java metanorma-class" 
			extension-element-prefixes="redirect"
			version="1.0">

	<!-- =====================
		remove semx and span elements around the text
	===================== -->
	<xsl:template match="@*|node()" mode="remove_semantic">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="remove_semantic"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="semx[not(@element = 'title')]" mode="remove_semantic">
		<xsl:apply-templates mode="remove_semantic"/>
	</xsl:template>
	
	<xsl:template match="span[@class = 'fmt-caption-label' or 
								@class = 'fmt-autonum-delim' or 
								@class = 'fmt-element-name'  or 
								@class = 'fmt-label-delim']" mode="remove_semantic">
		<xsl:apply-templates mode="remove_semantic"/>
	</xsl:template>
	
		
</xsl:stylesheet>