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


	<!-- ===================== -->
	<!-- remove namespace -->
	<!-- for simplify templates: use '<xsl:template match="element">' instead of '<xsl:template match="*[local-name() = 'element']"> -->
	<!-- ===================== -->

	<xsl:template match="*" mode="remove_namespace" priority="2">
		<xsl:element name="{local-name()}">
			<xsl:apply-templates select="@*|node()" mode="remove_namespace"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match="@*|node()" mode="remove_namespace">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="remove_namespace"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="mml:* | *[local-name() = 'svg']" mode="remove_namespace" priority="3">
		<xsl:copy-of select="."/>
	</xsl:template>
	
	
	
	<!-- <xsl:template match="*[local-name() = 'title'][following-sibling::*[1][local-name() = 'fmt-title']] |
											*[local-name() = 'name'][following-sibling::*[1][local-name() = 'fmt-name']] |
											*[local-name() = 'preferred'][ancestor::*[local-name() = 'term'][1]//*[local-name() = 'fmt-preferred']] |
											*[local-name() = 'admitted'][ancestor::*[local-name() = 'term'][1]//*[local-name() = 'fmt-admitted']] |
											*[local-name() = 'deprecates'][ancestor::*[local-name() = 'term'][1]//*[local-name() = 'fmt-deprecates']] |
											*[local-name() = 'related'] |
											*[local-name() = 'definition'][ancestor::*[local-name() = 'term'][1]//*[local-name() = 'fmt-definition']] |
											*[local-name() = 'termsource'][ancestor::*[local-name() = 'term'][1]//*[local-name() = 'fmt-termsource']]" mode="remove_namespace" priority="3"/>
											
	<xsl:template match="*[local-name() = 'fmt-title']//*[local-name() = 'span'] |
											*[local-name() = 'semx'] | 
											*[local-name() = 'fmt-name']//*[local-name() = 'span']" mode="remove_namespace" priority="3">
		<xsl:apply-templates mode="remove_namespace"/>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'fmt-xref-label']" mode="remove_namespace" priority="3"/>
	
	<xsl:template match="*[local-name() = 'fmt-preferred'][*[local-name() = 'p']]" mode="remove_namespace" priority="3">
		<xsl:apply-templates mode="remove_namespace"/>
	</xsl:template>
	<xsl:template match="*[local-name() = 'fmt-preferred'][not(*[local-name() = 'p'])] | *[local-name() = 'fmt-preferred']/*[local-name() = 'p']" mode="remove_namespace" priority="3">
		<xsl:element name="preferred">
			<xsl:apply-templates select="@*|node()" mode="remove_namespace"/>
		</xsl:element>
	</xsl:template>
	
		<xsl:template match="*[local-name() = 'fmt-admitted'][*[local-name() = 'p']]" mode="remove_namespace" priority="3">
			<xsl:apply-templates mode="remove_namespace"/>
		</xsl:template>
		<xsl:template match="*[local-name() = 'fmt-admitted'][not(*[local-name() = 'p'])] | *[local-name() = 'fmt-admitted']/*[local-name() = 'p']" mode="remove_namespace" priority="3">
			<xsl:element name="admitted">
				<xsl:apply-templates select="@*|node()" mode="remove_namespace"/>
			</xsl:element>
		</xsl:template>
	
		<xsl:template match="*[local-name() = 'fmt-deprecates'][*[local-name() = 'p']]" mode="remove_namespace" priority="3">
			<xsl:apply-templates mode="remove_namespace"/>
		</xsl:template>
		<xsl:template match="*[local-name() = 'fmt-deprecates'][not(*[local-name() = 'p'])] | *[local-name() = 'fmt-deprecates']/*[local-name() = 'p']" mode="remove_namespace" priority="3">
			<xsl:element name="deprecates">
				<xsl:apply-templates select="@*|node()" mode="remove_namespace"/>
			</xsl:element>
		</xsl:template>

	<xsl:template match="*[local-name() = 'fmt-title'] |
											*[local-name() = 'fmt-name'] |
											*[local-name() = 'fmt-definition'] |
											*[local-name() = 'fmt-termsource']" mode="remove_namespace" priority="3">
		<xsl:element name="{substring-after(local-name(), 'fmt-')}">
			<xsl:apply-templates select="@*|node()" mode="remove_namespace"/>
		</xsl:element>
	</xsl:template> -->
	
	<xsl:template match="*[local-name() = 'source-highlighter-css']" mode="remove_namespace" priority="3"/>
	
	<!-- ===================== -->
	<!-- END remove namespace -->
	<!-- ===================== -->
	
</xsl:stylesheet>