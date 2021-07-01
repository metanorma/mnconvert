<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
		xmlns:mml="http://www.w3.org/1998/Math/MathML" 
		xmlns:tbx="urn:iso:std:iso:30042:ed-1" 
		xmlns:xlink="http://www.w3.org/1999/xlink" 
		xmlns:xalan="http://xml.apache.org/xalan" 
		xmlns:java="http://xml.apache.org/xalan/java" 
		xmlns:java_char="http://xml.apache.org/xalan/java/java.lang.Character" 
		exclude-result-prefixes="mml tbx xlink xalan java" 
		version="1.0">

	<xsl:preserve-space elements="code mml:*"/>
	
	<xsl:output method="xml" encoding="UTF-8" indent="no"/>
	
	<xsl:template match="@*|node()">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="text()[not(parent::code) and not(parent::preformat) and not(parent::mml:*)]">
		<xsl:choose>
			<xsl:when test="parent::standard or parent::body or parent::sec or parent::term-sec or parent::tbx:termEntry or parent::back or parent::app-group or parent::app or parent::ref-list or parent::fig or parent::caption or parent::table-wrap or parent::tr or parent::thead or parent::colgroup or parent::table or parent::tbody or parent::fn or parent::non-normative-note or parent::array">
				<xsl:value-of select="normalize-space()"/>
			</xsl:when>
			<xsl:when test="contains(., '&#xa;')">
				<xsl:variable name="text_" select="translate(., '&#xa;', ' ')"/>
				<xsl:variable name="text" select="java:replaceAll(java:java.lang.String.new($text_),' +',' ')"/>
				<xsl:if test="normalize-space($text) != ''">
					<xsl:value-of select="$text"/>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>		
	</xsl:template>

	
	<!-- Add @stdid (and @stdid_option) to ref for reference mechanism between <std std-id="..."></std> and <ref></ref> -->
	<xsl:template match="ref">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			
			<xsl:variable name="std-id">
				<xsl:call-template name="getNormalizedId">
					<xsl:with-param name="id" select="std/@std-id"/>
				</xsl:call-template>
			</xsl:variable>
			
			<xsl:variable name="std-ref">
				<xsl:call-template name="getNormalizedId">
					<xsl:with-param name="id" select="normalize-space(std/std-ref)"/>
				</xsl:call-template>
			</xsl:variable>
			
			<xsl:variable name="stdid">
				<xsl:choose>
					<!--
					<ref>
						<std std-id="iso:std:iso:44001:ed-1:en" type="dated">
							<std-ref>ISO 44001:2017
							</std-ref>, <title>...</title>
						</std>
					</ref> -->
					<xsl:when test="normalize-space($std-id) != ''">
						<xsl:value-of select="normalize-space($std-id)"/>
					</xsl:when>
					<!-- 
					<ref>
						<std>
							<std-ref>BS ISO 44001:2017</std-ref>, <title>...</title>
						</std>
					</ref> -->
					<xsl:when test="normalize-space($std-ref) != ''">
						<xsl:value-of select="normalize-space($std-ref)"/>
					</xsl:when>
				</xsl:choose>
			</xsl:variable>
			
			<xsl:if test="normalize-space($stdid) != ''">
				<xsl:attribute name="stdid"><xsl:value-of select="$stdid"/></xsl:attribute>
				<xsl:if test="not(@id)"><!-- create attribute id for ref, if not exists -->
					<xsl:attribute name="id"><xsl:value-of select="$stdid"/></xsl:attribute>
				</xsl:if>
			</xsl:if>
			
			<xsl:if test="normalize-space($std-ref) != ''">
				<xsl:attribute name="stdid_option"> <!-- create attribute for std with std-ref only -->
					<xsl:value-of select="normalize-space($std-ref)"/>
				</xsl:attribute>
			</xsl:if>
			
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>

	<!-- Add stdid to std for reference mechanism between <std std-id="..."></std> and <ref></ref> -->
	<xsl:template match="std[not(parent::ref)]">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:attribute name="stdid">
				<xsl:choose>
					<xsl:when test="normalize-space(@std-id) != ''">
						<xsl:variable name="std_id">
							<xsl:choose>
								<xsl:when test="contains(@std-id, ':clause:')"><xsl:value-of select="substring-before(@std-id, ':clause:')"/></xsl:when>
								<xsl:otherwise><xsl:value-of select="@std-id"/></xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						<xsl:call-template name="getNormalizedId">
							<xsl:with-param name="id" select="$std_id"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:when test="normalize-space(.//std-ref) != ''">
						<xsl:call-template name="getNormalizedId">
							<xsl:with-param name="id" select="normalize-space(.//std-ref)"/>
						</xsl:call-template>
					</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates select="node()"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="bold | italic | sub | sup | monospace">
		<xsl:call-template name="processUnconstrainedFormatting"/>
	</xsl:template>
	
	<xsl:template name="processUnconstrainedFormatting">
		<xsl:variable name="unconstrained_formatting"><xsl:call-template name="is_unconstrained_formatting"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$unconstrained_formatting = 'true'">
				<!-- create element bold2, italic2, sup2, etc. -->
				<xsl:element name="{local-name()}2">
					<xsl:apply-templates select="@*"/>
					<xsl:apply-templates />
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<!-- copy 'as is' -->
				<xsl:copy-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- https://docs.asciidoctor.org/asciidoc/latest/text/ -->
	<!-- Unconstrained formatting pair -->
	<xsl:template name="is_unconstrained_formatting">
	
		<xsl:variable name="prev_text" select="preceding-sibling::node()[1]"/>
		<xsl:variable name="prev_char" select="substring($prev_text, string-length($prev_text))"/>
		
		<xsl:variable name="next_text" select="following-sibling::node()[1]"/>
		<xsl:variable name="next_char" select="substring($next_text, 1, 1)"/>
		
		<xsl:variable name="next_node" select="local-name(following-sibling::node()[1])"/>
		
		<xsl:variable name="prev_node_is_formatting" select="local-name($prev_text) != '' and contains('bold | italic | sub | sup | monospace', local-name($prev_text))"/>
		<xsl:variable name="next_node_is_formatting" select="local-name($next_text) != '' and contains('bold | italic | sub | sup | monospace', local-name($next_text))"/>

		<xsl:variable name="text" select="."/>
		<xsl:variable name="first_char" select="substring($text, 1, 1)"/>
		<xsl:variable name="last_char" select="substring($text, string-length($text))"/>
		
		<xsl:choose>
			<!--  a blank space does not precede the text to format -->
			<xsl:when test="$prev_char != '' and $prev_char != ' '">true</xsl:when>
			
			<!-- a blank space or punctuation mark (, ; " . ? or !) does not directly follow the text -->
			<xsl:when test="$next_char != '' and $next_char != ' ' and 
													$next_char != ',' and $next_char != ';' and $next_char != '&quot;' and $next_char != '.' and $next_char != '?' and $next_char != '!' and $next_node != 'p'">true</xsl:when>
													
			<!-- text does not start or end with a word character -->
			<xsl:when test="(java_char:isLetter($first_char) != 'true' and java_char:isDigit($first_char) != 'true') or (java_char:isLetter($last_char) != 'true' and java_char:isDigit($last_char) != 'true')">true</xsl:when>
			
			<!-- previous or next node is formatting -->
			<xsl:when test="$prev_node_is_formatting = 'true' or $next_node_is_formatting = 'true'">true</xsl:when>
			
			<xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	
	<xsl:template match="origin/@bibitemid">
		<xsl:call-template name="getNormalizedId">
			<xsl:with-param name="id" select="."/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="getNormalizedId">
		<xsl:param name="id"/>
		<xsl:variable name="id_normalized1" select="translate($id, ' &#xA0;:', '___')"/> <!-- replace space, non-break space, colon to _ -->
		<xsl:variable name="id_normalized2" select="translate($id_normalized1, '&#x2011;', '-')"/> <!-- non-breaking hyphen minus -->
		<xsl:variable name="first_char" select="substring(id_normalized2,1,1)"/>
		<xsl:if test="$first_char != '' and translate($first_char, '0123456789', '') = ''">_</xsl:if>
		<xsl:value-of select="$id_normalized2"/>
	</xsl:template>

</xsl:stylesheet>