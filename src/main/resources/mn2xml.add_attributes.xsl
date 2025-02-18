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
		add attributes:
		- section (for instance, 2, B.5.2)
		- section_prefix (Annex, Table, Figure, Section, Clause, Equation
	===================== -->
	<xsl:template match="@*|node()" mode="add_attributes">
		<xsl:param name="sectionNum"/>
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="add_attributes">
				<xsl:with-param name="sectionNum" select="$sectionNum"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="*" mode="add_attributes" priority="2">
		<xsl:param name="sectionNum"/>
		
		<xsl:variable name="sectionNum_">
			<xsl:call-template name="calculateSectionNum">
				<xsl:with-param name="sectionNum" select="$sectionNum"/>
			</xsl:call-template>
		</xsl:variable>
	
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="add_attributes"/>
			
			<xsl:call-template name="addAttributes">
				<xsl:with-param name="sectionNum" select="$sectionNum_"/>
			</xsl:call-template>
			
			<xsl:apply-templates select="node()" mode="add_attributes">
				<xsl:with-param name="sectionNum" select="$sectionNum_"/>
			</xsl:apply-templates>
		</xsl:copy>
		
	</xsl:template>
	
	<xsl:template name="calculateSectionNum">
		<xsl:param name="sectionNum"/>
		<xsl:choose>
			<xsl:when test="ancestor::foreword">foreword</xsl:when>
		
			<!-- Introduction in sections -->
			<xsl:when test="parent::sections and self::clause and @type='intro'">0</xsl:when>
			
			<!-- Scope -->
			<xsl:when test="parent::sections and self::clause and (@type='scope' or @type='overview' or title = 'Overview')">1</xsl:when>
			
			<!-- Normative References -->
			<xsl:when test="ancestor::bibliography and self::references and @normative='true'">
				<xsl:value-of select="count(ancestor::*[contains(local-name(), '-standard') or self::metanorma]/sections/clause[@type='scope' or @type='overview' or title = 'Overview']) + 1"/>
			</xsl:when>
			
			<!-- Terms and definitions -->
			<xsl:when test="parent::sections and (
											self::terms or 
											(self::clause and .//terms) or 
											self::definitions or 
											(self::clause and ..//definitions))">
				<xsl:variable name="num" select="count(preceding-sibling::*) + 1"/>
				<xsl:variable name="section_number" select="count(ancestor::*[contains(local-name(), '-standard') or self::metanorma]//bibliography/references[@normative='true']) + $num"/>
				<xsl:value-of select="$section_number"/>
			</xsl:when>
			
			<!-- Another main sections -->
			<xsl:when test="parent::sections">
				<xsl:variable name="num" select="count(preceding-sibling::*) + 1"/>
				<xsl:value-of select="count(ancestor::*[contains(local-name(), '-standard') or self::metanorma]//bibliography/references[@normative='true']) + $num"/>
			</xsl:when>
			
			<xsl:when test="$sectionNum"><xsl:value-of select="$sectionNum"/></xsl:when>
			<xsl:otherwise>
				<xsl:number count="*"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- add attributes section_prefix, section and empty_label -->
	<xsl:template name="addAttributes">
		<xsl:param name="sectionNum"/>
		
		<xsl:variable name="name" select="local-name()"/>
		
		<xsl:variable name="ancestor">
			<xsl:choose>
				<xsl:when test="ancestor::sections">sections</xsl:when>
				<xsl:when test="ancestor::annex">annex</xsl:when>
			</xsl:choose>
		</xsl:variable>
		
		<!-- additional attributes -->
		<xsl:if test="$name = 'annex' or
							$name = 'appendix' or
							$name = 'bibitem' or
							$name = 'clause' or
							$name = 'introduction' or
							$name = 'references' or
							$name = 'terms' or
							$name = 'definitions' or
							$name = 'term' or
							$name = 'preferred' or
							$name = 'admitted' or
							$name = 'deprecates' or
							$name = 'domain' or
							$name = 'bookmark' or
							$name = 'em' or
							$name = 'table' or
							($name = 'requirement' and not(ancestor::requirement)) or
							$name = 'dl' or
							$name = 'ol' or
							$name = 'ul' or
							$name = 'li' or
							$name = 'figure' or 
							$name = 'image' or
							$name = 'formula' or
							$name = 'stem' or
							$name = 'section-title' or
							($name = 'p' and @type = 'section-title')">
							
			<xsl:variable name="section_with_prefix_">
				<xsl:if test="$isSemanticXML = 'false' or @presentation = 'true'"> <!-- for presentation XML -->
					<xsl:choose>
						<xsl:when test="(self::table or self::requirement or self::figure) and contains(name, '&#8212; ')"> <!-- if table's or figure's name contains number -->
							<xsl:variable name="_name" select="substring-before(name, '&#8212; ')"/>
							<!-- Example: Table&#xa0;5 -->
							<xsl:value-of select="translate(normalize-space(translate($_name, '&#xa0;', ' ')), ' ', '&#xa0;')"/>
						</xsl:when>
						<xsl:when test="self::annex and title/br"> <!-- Example: <title><strong>Annex A</strong><br/> ... -->
							<xsl:value-of select="translate(title/br/preceding-sibling::node(), ' ', '&#xa0;')"/>
						</xsl:when>
						<xsl:when test="self::annex and contains(title, '&#8212; ')">
							<xsl:variable name="_title" select="substring-before(title, '&#8212; ')"/>
							<xsl:value-of select="translate(normalize-space(translate($_title, '&#xa0;', ' ')), ' ', '&#xa0;')"/>
						</xsl:when>
					</xsl:choose>
				</xsl:if>
			</xsl:variable>
			<xsl:variable name="section_with_prefix" select="normalize-space($section_with_prefix_)"/>
			
			<!-- <xsl:attribute name="section_with_prefix">
				<xsl:value-of select="$section_with_prefix"/>
			</xsl:attribute> -->
			
			<xsl:variable name="section">
				<xsl:choose>
					<xsl:when test="$section_with_prefix != ''"><xsl:value-of select="substring-after($section_with_prefix, '&#xa0;')"/></xsl:when>
					<xsl:when test="normalize-space(title/tab[1]/preceding-sibling::node()) != ''">
						<!-- presentation xml data -->
						<xsl:value-of select="title/tab[1]/preceding-sibling::node()"/>
					</xsl:when>
					<xsl:when test="@presentation = 'true' and @inline-header = 'true' and title and not(title/tab)"> <!-- example: <title>B.5.2</title> -->
						<xsl:value-of select="title"/>
					</xsl:when>
					<xsl:when test="self::term and normalize-space(name) != '' and  normalize-space(translate(name, '0123456789.', '')) = ''"> <!-- if term's name contains digits and dots only, for instance, '3.2' -->
						<xsl:value-of select="name"/>
					</xsl:when>
					<xsl:when test="title and not(title/tab) and normalize-space(translate(title, '0123456789.', '')) = ''"> <!-- if title contains digits and dots only, for example '4.1.3' -->
						<xsl:value-of select="title"/>
					</xsl:when>
					 <!-- amendment title with section number and title : 5.5.1, fourth paragraph -->
					<xsl:when test="amend and title and not(title/tab) and normalize-space(translate(substring-before(title, ','), '0123456789.', '')) = '' and contains (title/node()[1], ',')">
						<xsl:for-each select="title/node()[1]">
							<xsl:value-of select="substring-before(., ',')"/>
						</xsl:for-each>
					</xsl:when>
					<xsl:when test="(self::table or self::requirement or self::figure) and contains(name, '&#8212; ') and ($isSemanticXML = 'false' or @presentation = 'true')"> <!-- if table's or figure's name contains number -->
						<xsl:variable name="_name" select="substring-before(name, '&#8212; ')"/>
						<!-- <xsl:value-of select="substring-after(translate(normalize-space(translate($_name, '&#xa0;', ' ')), ' ', '&#xa0;'), '&#xa0;')"/> -->
						<xsl:value-of select="translate(normalize-space(translate($_name, '&#xa0;', ' ')), ' ', '&#xa0;')"/>
					</xsl:when>
					<xsl:when test="(self::table or self::requirement or self::figure) and not(ancestor::sections or ancestor::annex or ancestor::preface)" />
					<xsl:otherwise>
						<xsl:variable name="section_">
							<xsl:call-template name="getSection">
								<xsl:with-param name="sectionNum" select="$sectionNum"/>
							</xsl:call-template>
						</xsl:variable>
						
						<xsl:choose>
							<xsl:when test="(self::table or self::requirement or self::figure) and $section_ = ''"/>
							<xsl:when test="$section_ = '0' and not(@type='intro')" />
							<xsl:otherwise>
								<!-- <xsl:choose>
									<xsl:when test="$name = 'annex'">Annex&#xA0;<xsl:value-of select="$section_"/></xsl:when>
									<xsl:when test="$name = 'table'">Table&#xA0;<xsl:value-of select="$section_"/></xsl:when>
									<xsl:when test="$name = 'figure'">Figure&#xA0;<xsl:value-of select="$section_"/></xsl:when>
									<xsl:otherwise><xsl:value-of select="$section_"/></xsl:otherwise>
								</xsl:choose> -->
								<xsl:value-of select="$section_"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>				
			</xsl:variable>
			
			<xsl:attribute name="section"><xsl:value-of select="$section"/></xsl:attribute>
			
			<xsl:variable name="section_prefix">
				<xsl:choose>
					<xsl:when test="$section_with_prefix != ''"><xsl:value-of select="substring-before($section_with_prefix, '&#xa0;')"/>&#xA0;</xsl:when>
					<xsl:when test="$name = 'annex'">Annex&#xA0;</xsl:when>
					<xsl:when test="$name = 'table' or $name = 'requirement'">Table&#xA0;</xsl:when>
					<xsl:when test="$name = 'figure'">Figure&#xA0;</xsl:when>
					<xsl:when test="($name = 'clause' or $name = 'terms' or ($name = 'references' and @normative='true')) and $section != '' and not(contains($section, '.'))">Clause </xsl:when> <!-- first level clause -->
					<xsl:when test="$name = 'section-title' or ($name = 'p' and @type = 'section-title')">Section </xsl:when>
					<xsl:when test="$name = 'formula' and ($metanorma_type = 'IEC' or $metanorma_type = 'IEEE')">Equation </xsl:when>
				</xsl:choose>
			</xsl:variable>
			
			<xsl:attribute name="section_prefix"><xsl:value-of select="$section_prefix"/></xsl:attribute>
			
			<xsl:if test="amend and not(title)">
				<xsl:attribute name="empty_label">true</xsl:attribute>
			</xsl:if>
			
		</xsl:if>
	</xsl:template>
	<!-- ===================== -->
	<!-- END add attributes -->
	<!-- ===================== -->
	
</xsl:stylesheet>