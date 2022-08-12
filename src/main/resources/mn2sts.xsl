<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
			xmlns:mml="http://www.w3.org/1998/Math/MathML" 
			xmlns:tbx="urn:iso:std:iso:30042:ed-1" 
			xmlns:xlink="http://www.w3.org/1999/xlink" 
			xmlns:xalan="http://xml.apache.org/xalan" 
			xmlns:java="http://xml.apache.org/xalan/java" 
			xmlns:metanorma-class="xalan://org.metanorma.utils.RegExHelper"
			exclude-result-prefixes="xalan java metanorma-class" 
			version="1.0">

	<xsl:output version="1.0" method="xml" encoding="UTF-8" indent="yes"/>
	
	<xsl:param name="debug">false</xsl:param>
	<xsl:param name="outputformat">NISO</xsl:param>
	
	<xsl:include href="mn2xml.xsl"/>
	
	<xsl:template match="/*" mode="xml">
		<standard xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:tbx="urn:iso:std:iso:30042:ed-1" xmlns:xlink="http://www.w3.org/1999/xlink">
			<xsl:call-template name="insertXMLcontent"/>
		</standard>
	</xsl:template>
	
	<xsl:template match="metanorma-collection" mode="xml" priority="2">
		<standard xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:tbx="urn:iso:std:iso:30042:ed-1" xmlns:xlink="http://www.w3.org/1999/xlink">
		
			<!-- get 'front' from 1st doc-container -->
			<xsl:for-each select="doc-container[1]/*">
				<xsl:call-template name="insertFront"/>
			</xsl:for-each>
			
			<body>
				<sub-part> <!-- Sections for 1st document -->
					<label/>
					<title/>
					<xsl:for-each select="doc-container[1]/*">
						<xsl:call-template name="insertBody"/>
						<xsl:call-template name="insertBack"/>
					</xsl:for-each>
				</sub-part>
				<sub-part>
					<label/>
					<title/>
					<body>
						<!-- Foreword, Introduction sections for 2nd document -->
						<xsl:for-each select="doc-container[2]/*">
							<xsl:apply-templates select="preface" mode="front_preface"/>
						</xsl:for-each>
						<sub-part> <!-- Sections for 2nd document -->
							<label/>
							<title/>
							<xsl:for-each select="doc-container[2]/*">
								<xsl:call-template name="insertBody"/>
								<xsl:call-template name="insertBack"/>
							</xsl:for-each>
						</sub-part>
					</body>
				</sub-part>
			
			</body>
		
		</standard>
	</xsl:template>
	
	<xsl:template match="term">
		<xsl:variable name="current_id">
			<xsl:call-template name="getId"/>
		</xsl:variable>
		
		<xsl:variable name="section">
			<xsl:choose>
				<xsl:when test="normalize-space(name) != '' and  normalize-space(translate(name, '0123456789.', '')) = ''">
					<xsl:value-of select="name"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="@section"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
	
		<term-sec id="sec_{$section}"><!-- id="{$current_id}" -->
					
			<xsl:call-template name="insert_label">
				<xsl:with-param name="label" select="$section"/>
				<xsl:with-param name="isAddition" select="count(title/node()[normalize-space() != ''][1][self::add]) = 1"/>
			</xsl:call-template>
			
			<tbx:termEntry id="{$current_id}">
				<tbx:langSet xml:lang="en">
					<xsl:apply-templates select="node()[not(self::termexample or self::termnote or self::termsource or 
																										self::preferred or self::admitted or self::deprecates or self::domain or 
																										self::term)]"/>
					
					<xsl:apply-templates select="termexample"/>
					
					<xsl:apply-templates select="termnote"/>
					
					<xsl:apply-templates select="termsource"/>
					
					<xsl:apply-templates select="preferred | admitted | deprecates | domain"/>
					
				</tbx:langSet>
			</tbx:termEntry>
			
			<xsl:apply-templates select="term"/>
			
		</term-sec>
	</xsl:template>
	
	<xsl:template match="definition">
		<tbx:definition>
			<xsl:apply-templates />
			<xsl:apply-templates select="following-sibling::ul | following-sibling::ol" mode="definition_list"/>
		</tbx:definition>
	</xsl:template>
	
	<xsl:template match="termexample">
		<tbx:example>
			<xsl:apply-templates />
		</tbx:example>
	</xsl:template>
	
	<xsl:template match="termnote">
		<tbx:note>
			<xsl:apply-templates />
		</tbx:note>
	</xsl:template>
	
	<xsl:template match="termsource">
		<tbx:source>
			<xsl:apply-templates />
		</tbx:source>
	</xsl:template>
	
	
	<xsl:template match="preferred | admitted | deprecates | domain"> <!--  mode="termEntry" -->
		
		<!-- <xsl:variable name="current_id">
			<xsl:call-template name="getId"/>
		</xsl:variable>
		
		<xsl:variable name="id" select="$elements//element[@source_id = $current_id]/@id"/>	 -->
		<!-- <xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable> -->
		<xsl:variable name="number"><xsl:number count="preferred | admitted | deprecates | domain"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:variable name="element_name" select="local-name()"/>
			<xsl:for-each select="ancestor::term[1]">
				<xsl:call-template name="getId"/><xsl:text>-</xsl:text><xsl:value-of select="$number"/>_<xsl:value-of select="$element_name"/>
			</xsl:for-each>
		</xsl:variable>
		
		<tbx:tig>
			<xsl:if test="normalize-space($id) != ''">
				<xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
			</xsl:if>
			<tbx:term><xsl:apply-templates /></tbx:term>
			<tbx:partOfSpeech>
				<xsl:attribute name="value">
					<xsl:choose>
						<xsl:when test=".//grammar/isAdjective = 'true'">adj</xsl:when>
						<xsl:when test=".//grammar/isAdverb = 'true'">adv</xsl:when>
						<xsl:when test=".//grammar/isNoun = 'true'">noun</xsl:when>
						<xsl:when test=".//grammar/isVerb = 'true'">verb</xsl:when>
						<!-- <xsl:when test=".//grammar/isPreposition = 'true'">preposition</xsl:when>--> <!-- not supported in XSD -->
						<!-- <xsl:when test=".//grammar/isParticiple = 'true'">participle</xsl:when> --><!-- not supported in XSD -->
						<xsl:otherwise>noun</xsl:otherwise> <!-- default value -->
					</xsl:choose>
				</xsl:attribute>
			</tbx:partOfSpeech>
			<xsl:variable name="element_name" select="local-name()"/>
			<xsl:variable name="normativeAuthorization">
				<xsl:choose>
					<xsl:when test="$element_name = 'preferred'">preferredTerm</xsl:when>
					<xsl:when test="$element_name = 'admitted'">admittedTerm</xsl:when>
					<xsl:when test="$element_name = 'deprecates'">deprecatedTerm</xsl:when>
				</xsl:choose>
			</xsl:variable>
			<xsl:if test="normalize-space($normativeAuthorization) != ''">
				<xsl:choose>
					<xsl:when test="$organization != 'IEC' and $element_name = 'preferred' and not(following-sibling::admitted or preceding-sibling::admitted or
					following-sibling::deprecates or preceding-sibling::deprecates)"></xsl:when>
					<xsl:otherwise>
						<tbx:normativeAuthorization value="{$normativeAuthorization}"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
			<xsl:if test="@type or letter-symbol or $organization = 'IEC'">
				<xsl:variable name="value">
					<xsl:choose>
						<xsl:when test="letter-symbol">symbol</xsl:when>
						<xsl:when test="$organization = 'IEC' and (@type = 'full' or normalize-space(@type) = '')">fullForm</xsl:when>
						<xsl:when test="@type = 'full'">variant</xsl:when>
						<xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<tbx:termType value="{$value}"/>
			</xsl:if>
			<xsl:apply-templates select="field-of-application" mode="usageNote"/>
		</tbx:tig>
	</xsl:template>
	
	<xsl:template match="field-of-application" priority="2" mode="usageNote">
		<tbx:usageNote><xsl:apply-templates/></tbx:usageNote>
	</xsl:template>
	
	<!-- ===================== -->
	<!-- tbx:entailedTerm -->
	<!-- ===================== -->
	<!-- Conversion from: -->
	<!-- <em>objectives</em> (<xref target="term-objective"><strong>3.8</strong></xref>) -->
	<!-- to: -->
	<!-- <tbx:entailedTerm target="term_3.8">objectives (3.8)</tbx:entailedTerm> -->
	<!-- for em, when next is xref -->
	<xsl:template match="em[following-sibling::node()[1][. = ' ('] and following-sibling::*[1][self::xref]]" priority="2">
		<tbx:entailedTerm target="{following-sibling::*[1]/@target}">
			<xsl:apply-templates />
			<xsl:apply-templates select="following-sibling::*[1]" mode="em_xref"/><!-- get xref -->
		</tbx:entailedTerm>
	</xsl:template>
	
	<!-- for xref, when previous is em -->
	<xsl:template match="xref" mode="em_xref">
		<xsl:text> </xsl:text>
		<!-- preceding-sibling-text='<xsl:value-of select="normalize-space(preceding-sibling::node()[1])"/>' -->
		<xsl:if test="normalize-space(preceding-sibling::node()[1]) ='('">(</xsl:if>
		<xsl:value-of select="normalize-space()"/>
		<xsl:if test="substring(normalize-space(following-sibling::node()[1]),1,1) =')'">)</xsl:if>
		<!-- following-sibling-text='<xsl:value-of select="following-sibling::node()[1]"/>' -->
	</xsl:template>
	
	<xsl:template match="xref[preceding-sibling::node()[1][. = ' ('] and preceding-sibling::*[1][self::em]]" priority="2"/>
	
	<!-- remove '(' between em and xref -->
	<xsl:template match="text()[normalize-space() = '('][preceding-sibling::*[1][self::em] and following-sibling::*[1][self::xref]]"/>
	<!-- remove ')' after em and xref -->
	<xsl:template match="text()[substring(normalize-space(),1,1) = ')'][preceding-sibling::*[1][self::xref] and preceding-sibling::*[2][self::em]]">
		<xsl:value-of select="substring-after(., ')')"/>
	</xsl:template>
	<!-- ===================== -->
	<!-- END tbx:entailedTerm -->
	<!-- ===================== -->
	
</xsl:stylesheet>