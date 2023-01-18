<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
			xmlns:mml="http://www.w3.org/1998/Math/MathML" 
			xmlns:tbx="urn:iso:std:iso:30042:ed-1" 
			xmlns:xlink="http://www.w3.org/1999/xlink" 
			xmlns:xalan="http://xml.apache.org/xalan" 
			xmlns:java="http://xml.apache.org/xalan/java" 
			xmlns:redirect="http://xml.apache.org/xalan/redirect"
			xmlns:metanorma-class="xalan://org.metanorma.utils.RegExHelper"
			exclude-result-prefixes="xalan java metanorma-class" 
			extension-element-prefixes="redirect"
			version="1.0">

	<xsl:variable name="metanorma_type" select="java:toUpperCase(java:java.lang.String.new(substring-before(local-name(//*[contains(local-name(), '-standard')]), '-')))"/> <!-- ISO, IEC, ... -->

	<!-- ===================== -->
	<!-- remove namespace -->
	<!-- for simplify templates: use '<xsl:template match="element">' instead of '<xsl:template match="*[local-name() = 'element']"> -->
	<!-- ===================== -->
	<xsl:variable name="xml_step1_">
		<xsl:apply-templates mode="remove_namespace"/>
	</xsl:variable>
	<xsl:variable name="xml_step1" select="xalan:nodeset($xml_step1_)"/>
	
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
	<!-- ===================== -->
	<!-- END remove namespace -->
	<!-- ===================== -->
	
	<xsl:variable name="xml_">
		<xsl:apply-templates select="$xml_step1" mode="add_attributes"/>
	</xsl:variable>
	
	<!-- ===================== -->
	<!-- add attributes -->
	<!-- ===================== -->
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
		
		<xsl:variable name="name" select="local-name()"/>
		
		<xsl:variable name="ancestor">
			<xsl:choose>
				<xsl:when test="ancestor::sections">sections</xsl:when>
				<xsl:when test="ancestor::annex">annex</xsl:when>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="sectionNum_">
		
			<xsl:choose>
			
				<!-- Introduction in sections -->
				<xsl:when test="parent::sections and self::clause and @type='intro'">0</xsl:when>
				
				<!-- Scope -->
				<xsl:when test="parent::sections and self::clause and (@type='scope' or @type='overview' or title = 'Overview')">1</xsl:when>
				
				<!-- Normative References -->
				<xsl:when test="ancestor:: bibliography and self::references and @normative='true'">
					<xsl:value-of select="count(ancestor::*[contains(local-name(), '-standard')]/sections/clause[@type='scope' or @type='overview' or title = 'Overview']) + 1"/>
				</xsl:when>
				
				<!-- Terms and definitions -->
				<xsl:when test="parent::sections and (
												self::terms or 
												(self::clause and .//terms) or 
												self::definitions or 
												(self::clause and ..//definitions))">
					<xsl:variable name="num" select="count(preceding-sibling::*) + 1"/>
					<xsl:variable name="section_number" select="count(ancestor::*[contains(local-name(), '-standard')]//bibliography/references[@normative='true']) + $num"/>
					<xsl:value-of select="$section_number"/>
				</xsl:when>
				
				<!-- Another main sections -->
				<xsl:when test="parent::sections">
					<xsl:variable name="num" select="count(preceding-sibling::*) + 1"/>
					<xsl:value-of select="count(ancestor::*[contains(local-name(), '-standard')]//bibliography/references[@normative='true']) + $num"/>
				</xsl:when>
				
				<xsl:when test="$sectionNum"><xsl:value-of select="$sectionNum"/></xsl:when>
				<xsl:otherwise>
					<xsl:number count="*"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
	
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="add_attributes"/>
			
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
								
				<xsl:variable name="section">
					<xsl:choose>
						<xsl:when test="normalize-space(title/tab[1]/preceding-sibling::node()) != ''">
							<!-- presentation xml data -->
							<xsl:value-of select="title/tab[1]/preceding-sibling::node()"/>
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
						<xsl:when test="(self::table or self::requirement or self::figure) and contains(name, '&#8212; ') and $isSemanticXML = 'false'"> <!-- if table's or figure's name contains number -->
							<xsl:variable name="_name" select="substring-before(name, '&#8212; ')"/>
							<xsl:value-of select="substring-after(translate(normalize-space(translate($_name, '&#xa0;', ' ')), ' ', '&#xa0;'), '&#xa0;')"/>
						</xsl:when>
						<xsl:when test="(self::table or self::requirement or self::figure) and not(ancestor::sections or ancestor::annex or ancestor::preface)" />
						<xsl:otherwise>
							<xsl:variable name="section_">
								<xsl:call-template name="getSection">
									<xsl:with-param name="sectionNum" select="$sectionNum_"/>
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


			<xsl:apply-templates select="node()" mode="add_attributes">
				<xsl:with-param name="sectionNum" select="$sectionNum_"/>
			</xsl:apply-templates>
		</xsl:copy>
		
	</xsl:template>
	
	<!-- ===================== -->
	<!-- END add attributes -->
	<!-- ===================== -->

	
	<xsl:variable name="xml" select="xalan:nodeset($xml_)"/>
	
	<xsl:variable name="format" select="normalize-space($outputformat)"/>
	
	<xsl:variable name="organization_abbreviation">
		<xsl:choose>
			<xsl:when test="$xml_step1/metanorma-collection">
				<xsl:for-each select="$xml_step1/metanorma-collection/doc-container[1]/*/bibdata/copyright/owner/organization/abbreviation">
					<xsl:value-of select="."/>
					<xsl:if test="position() != last()">,</xsl:if>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="$xml_step1/*/bibdata/copyright/owner/organization/abbreviation">
					<xsl:value-of select="."/>
					<xsl:if test="position() != last()">,</xsl:if>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:variable name="organization_name">
		<xsl:choose>
			<xsl:when test="$xml_step1/metanorma-collection">
				<xsl:value-of select="$xml_step1/metanorma-collection/doc-container[1]/*/bibdata/copyright/owner/organization/name"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$xml_step1/*/bibdata/copyright/owner/organization/name"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:variable name="publisher_abbreviation">
		<xsl:choose>
			<xsl:when test="$xml_step1/metanorma-collection">
				<xsl:for-each select="$xml_step1/metanorma-collection/doc-container[1]/*/bibdata/contributor[role[@type='publisher']]/organization/abbreviation">
					<xsl:value-of select="."/>
					<xsl:if test="position() != last()">,</xsl:if>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="$xml_step1/*/bibdata/contributor[role[@type='publisher']]/organization/abbreviation">
					<xsl:value-of select="."/>
					<xsl:if test="position() != last()">,</xsl:if>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:variable name="organization">
		<xsl:choose>
			<xsl:when test="contains($organization_abbreviation,'BSI') or $organization_name = 'The British Standards Institution' or $organization_name = 'British Standards Institution'">BSI</xsl:when>
			<xsl:when test="contains($organization_abbreviation,'ISO')">ISO</xsl:when>
			<xsl:when test="contains($organization_abbreviation,'IEC')">IEC</xsl:when>
			<xsl:when test="$organization_abbreviation = 'IEEE' or $publisher_abbreviation = 'IEEE'">IEEE</xsl:when>
			<xsl:when test="$organization_abbreviation != ''"><xsl:value-of select="$organization_abbreviation"/></xsl:when>
			<xsl:when test="$organization_name != ''"><xsl:value-of select="$organization_name"/></xsl:when>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:variable name="nat_meta_only">
		<xsl:if test="not($xml/*/bibdata/relation[@type = 'adopted-from']) and $organization = 'BSI'">true</xsl:if>
	</xsl:variable>
	
	<xsl:variable name="isSemanticXML_" select="//*[contains(local-name(), '-standard')]/@type = 'semantic'"/>
	<xsl:variable name="isSemanticXML" select="normalize-space($isSemanticXML_)"/>
	
	<!-- ====================================================================== -->
	<!-- array 'elements' stores section's numbers -->
	<!-- semantic metanorma xml doesn't contain section's number and displayorder attribute, therefore we need to calculate section's numbers -->
	<!-- ====================================================================== -->
	<xsl:variable name="elements_">
		<elements>
		
			<xsl:for-each select="$xml/* | $xml/metanorma-collection/*/*">
			
				<xsl:apply-templates select="preface/*" mode="elements"/>
				
				<xsl:apply-templates select="sections/*" mode="elements"/>
					
				<xsl:apply-templates select="bibliography//references" mode="elements"/>
				
				<xsl:apply-templates select="annex" mode="elements"/>
				
				<xsl:apply-templates select=".//appendix" mode="elements"/>
				
			</xsl:for-each>
			
		</elements>
	</xsl:variable>

	<xsl:template match="text()" mode="elements"/>
	
	<xsl:template match="*" mode="elements">
		
		<xsl:variable name="name" select="local-name()"/>

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
								$name = 'requirement' or
								$name = 'dl' or
								$name = 'dt' or
								$name = 'ol' or
								$name = 'ul' or
								$name = 'li' or
								$name = 'example' or
								$name = 'figure' or 
								$name = 'image' or
								$name = 'formula' or
								$name = 'stem' or
								$name = 'section-title' or
								($name = 'p' and @type = 'section-title')">
					
			<xsl:variable name="source_id">			
				<xsl:call-template name="getId"/>
			</xsl:variable>
			
			<xsl:variable name="id" select="$source_id"/>
			
			<xsl:variable name="section" select="@section"/> <!-- added on the step 'add_attributes' -->
			<xsl:variable name="section_prefix" select="@section_prefix"/> <!-- added on the step 'add_attributes' -->
			
			<xsl:variable name="parent">
				<xsl:choose>
				
					<xsl:when test="($metanorma_type = 'IEC' or $metanorma_type = 'ISO') and $name='dt' and 
								(ancestor::dl/preceding-sibling::*[1][self::title][contains(normalize-space(), 'Abbrev')] or 
								(starts-with(@id, 'abb-') or starts-with(@id, 'abb_')))">dt-abb</xsl:when>
					<xsl:when test="ancestor::annex and not($name = 'figure' or $name = 'table' or $name = 'annex' or $name = 'fn' or $name = 'formula')">annex</xsl:when>
					<xsl:when test="$name = 'bookmark'"><xsl:value-of select="local-name(ancestor::*[@id][1])"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="$name"/></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			
			<xsl:variable name="section_bolded" select="($name = 'clause' or $name = 'terms' or
			$name = 'section-title' or ($name = 'p' and @type = 'section-title')) and $section != '' and $outputformat != 'IEEE'"/>
			
			<xsl:variable name="wrapper" select="$name"/>
			
			<xsl:variable name="parent_id">
				<xsl:if test="$name = 'bookmark'"><xsl:value-of select="ancestor::*[@id][1]/@id"/></xsl:if>
			</xsl:variable>
			
			<xsl:variable name="type">
				<xsl:choose>
					<xsl:when test="$name = 'section-title' or ($name = 'p' and @type = 'section-title')">section-title</xsl:when>
					<xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			
			<xsl:choose>
				<xsl:when test="$name = 'terms'">
					<terms id="{@id}">
						<element source_id="{$source_id}" id="{$id}" section="{$section}" section_prefix="{$section_prefix}" section_bolded="{$section_bolded}" parent="{$parent}"/>
						<xsl:apply-templates mode="elements"/>
					</terms>
				</xsl:when>
				<xsl:otherwise>
					<xsl:element name="{$wrapper}">
						<element source_id="{$source_id}" id="{$id}" section="{$section}" section_prefix="{$section_prefix}" section_bolded="{$section_bolded}" parent="{$parent}" parent_id="{normalize-space($parent_id)}" type="{$type}"/>
					</xsl:element>
				</xsl:otherwise>
			</xsl:choose>
			
		</xsl:if>
		
		<xsl:if test="$name != 'terms'">
			<xsl:apply-templates mode="elements"/>
		</xsl:if>
	</xsl:template>
		
	<xsl:template name="getId">
		<xsl:choose>
			<xsl:when test="@id"><xsl:value-of select="translate(@id,'()', '__')"/></xsl:when> <!-- replace '(' and ')' for valid id -->
			<xsl:otherwise>
				<xsl:value-of select="generate-id(.)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="getSection">
		<xsl:param name="sectionNum"/>
		<xsl:variable name="level">
			<xsl:call-template name="getLevel"/>
		</xsl:variable>		
		<xsl:variable name="section">
			<xsl:choose>
				<xsl:when test="self::dl"><xsl:number format="a" level="any"/></xsl:when>
				<xsl:when test="self::formula[not(unnumbered='true')] and ancestor::sections"><xsl:number format="(1)" level="any" count="formula[not(@unnumbered = 'true')]"/></xsl:when>
				<xsl:when test="self::formula[not(unnumbered='true')] and ancestor::annex">
					<xsl:variable name="root_element_id" select="generate-id(ancestor::annex)"/>
					<xsl:number format="A" level="any" count="annex"/>
					<xsl:text>.</xsl:text>
					<xsl:number format="1" level="any" count="formula[ancestor::*[generate-id() = $root_element_id] and not(@unnumbered = 'true')]"/>
				</xsl:when>
				<!-- <xsl:when test="self::bibitem and ancestor::references[@normative='true']">norm_ref_<xsl:number/></xsl:when> -->
				<xsl:when test="self::bibitem and ancestor::references[@normative='true']"><xsl:number/></xsl:when>
				<xsl:when test="self::bibitem and parent::references[not(@normative='true')]"><xsl:number level="any" count="bibitem[parent::references[not(@normative='true')]]"/></xsl:when>
				<!-- <xsl:when test="self::bibitem">ref_<xsl:number/></xsl:when> -->
				<xsl:when test="self::bibitem"><xsl:number/></xsl:when>
				<xsl:when test="ancestor::bibliography">
					<xsl:value-of select="$sectionNum"/>
				</xsl:when>
				<xsl:when test="self::annex">
					<xsl:number format="A" level="any" count="annex"/>
				</xsl:when>
				<xsl:when test="(self::table[not(ancestor::metanorma-extension)] or self::requirement[not(ancestor::requirement)] or self::figure) and not(ancestor::annex)">
					<xsl:variable name="root_element_id" select="generate-id(ancestor::*[contains(local-name(), '-standard')])"/> <!-- prevent global numbering for metanorma-collection -->
					<xsl:choose>
						<xsl:when test="self::table or self::requirement">
							<xsl:variable name="table_number_">
								<xsl:number format="1" level="any" count="*[self::table or self::requirement][ancestor::*[generate-id() = $root_element_id] and not(ancestor::annex or ancestor::metanorma-extension or ancestor::requirement) and not(@unnumbered = 'true')]"/>
							</xsl:variable>
							<xsl:variable name="table_number" select="normalize-space($table_number_)"/>
							<xsl:if test="$table_number != '0'"><xsl:value-of select="$table_number"/></xsl:if>
						</xsl:when>
						<xsl:when test="self::figure">
							<xsl:variable name="figure_number_">
								<xsl:number format="1" level="any" count="figure[ancestor::*[generate-id() = $root_element_id] and not(ancestor::annex) and not(@unnumbered = 'true')]"/>
							</xsl:variable>
							<xsl:variable name="figure_number" select="normalize-space($figure_number_)"/>
							<xsl:if test="$figure_number != '0'"><xsl:value-of select="$figure_number"/></xsl:if>
							</xsl:when>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="(self::p and @type = 'section-title') or self::section-title">
					<xsl:number format="1" level="any" count="p[@type = 'section-title'] | section-title"/>
				</xsl:when>
				<xsl:when test="ancestor::sections">
					<!-- 1, 2, 3, 4, ... from main section (not annex, bibliography, ...) -->
					<xsl:choose>
						<!-- <xsl:when test="self::table"><xsl:number format="1" level="any" count="table[ancestor::sections or ancestor::introduction]"/></xsl:when>
						<xsl:when test="self::figure"><xsl:number format="1" level="any" count="figure[ancestor::sections or ancestor::introduction]"/></xsl:when> -->
						<xsl:when test="$level = 1">
							<xsl:value-of select="$sectionNum"/>
						</xsl:when>
						<xsl:when test="$level &gt;= 2">
							<xsl:variable name="num">
								<xsl:number format=".1" level="multiple" count="clause/clause | 
																																										clause/terms | 
																																										terms/term | 
																																										clause/term |  
																																										term/term |  
																																										terms/clause |
																																										terms/definitions |
																																										definitions/clause |
																																										clause/definitions |
																																										definitions/definitions"/>
							</xsl:variable>
							<xsl:variable name="addon">
								<xsl:choose>
									<xsl:when test="self::preferred or self::admitted or self::deprecates or self::domain">
										<xsl:number format="-1" count="preferred | admitted | deprecates | domain"/>
									</xsl:when>
									<xsl:otherwise></xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<xsl:value-of select="concat($sectionNum, $num, $addon)"/>
							
						</xsl:when>
						<xsl:otherwise></xsl:otherwise>
					</xsl:choose>
				</xsl:when>				
				<xsl:when test="ancestor::annex">
					<xsl:variable name="annexid" select="normalize-space(/*/bibdata/ext/structuredidentifier/annexid)"/>
					<xsl:variable name="curr_annexid" select="ancestor::annex/@id"/>							
					<xsl:choose>
						<xsl:when test="self::table or self::requirement[not(ancestor::requirement)]">
							<xsl:number format="A" count="annex"/>
							<xsl:number format=".1" level="any" count="*[self::table or self::requirement][ancestor::annex/@id = $curr_annexid and not(ancestor::metanorma-extension or ancestor::requirement)]"/>
						</xsl:when>						
						<xsl:when test="self::figure">
							<xsl:number format="A" count="annex"/>
							<xsl:number format=".1" level="any" count="figure[not(parent::figure)][ancestor::annex/@id = $curr_annexid]"/>
							<xsl:number format="-1" count="figure[parent::figure][ancestor::annex/@id = $curr_annexid]"/>
						</xsl:when>
						<xsl:when test="$level = 1">							
							<xsl:choose>
								<xsl:when test="count(//annex) = 1 and $annexid != ''">
									<xsl:value-of select="$annexid"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:number format="A" level="any" count="annex"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>							
							<xsl:choose>
								<xsl:when test="count(//annex) = 1 and $annexid != ''">
									<xsl:value-of select="$annexid"/><xsl:number format=".1" level="multiple" count="clause"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:number format="A.1" level="multiple" count="annex | clause"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="ancestor::preface"> <!-- if preface and there is clause(s) -->
					<xsl:choose>
						<xsl:when test="$level = 1 and  ..//clause">0</xsl:when>
						<xsl:when test="$level &gt;= 2">
							<xsl:variable name="num">
								<xsl:number format=".1" level="multiple" count="clause"/>
							</xsl:variable>
							<xsl:value-of select="concat('0', $num)"/>
						</xsl:when>
						<xsl:otherwise></xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="$section"/>
	</xsl:template>
	
	<!-- elements is using in the template for 'xref' -->
	<xsl:variable name="elements" select="xalan:nodeset($elements_)"/>
	<!-- ====================================================================== -->
	<!-- END array 'elements' -->
	<!-- ====================================================================== -->
	
	
	<xsl:template match="@*|node()">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="*">
		<xsl:element name="{local-name()}">
			<xsl:apply-templates select="@*|node()"/>
		</xsl:element>
	</xsl:template>
	
	<!-- root element, for example: iso-standard -->
	<xsl:template match="/*">
		<xsl:variable name="startTime" select="java:getTime(java:java.util.Date.new())"/>
		
		<!-- <redirect:write file="test.xml">
			<xsl:copy-of select="$xml"/>
		</redirect:write> -->
		
		<xsl:apply-templates select="$xml" mode="xml"/>
    
		<xsl:variable name="endTime" select="java:getTime(java:java.util.Date.new())"/>
		<xsl:if test="normalize-space($debug) = 'true'">
			<xsl:message>DEBUG: processing time <xsl:value-of select="$endTime - $startTime"/> msec.</xsl:message>
		</xsl:if>
	</xsl:template>
	
	
	<xsl:template name="insertXMLcontent">
		<!-- <debug><xsl:copy-of select="$xml"/></debug> -->
			
		<xsl:variable name="xmlContent_">
			<xsl:call-template name="insertFront"/>
			<xsl:call-template name="insertBody"/>
		</xsl:variable>
		<xsl:variable name="xmlContent" select="xalan:nodeset($xmlContent_)"/>
		
		<xsl:variable name="existsSections" select="normalize-space(count($xmlContent//*[@sec-type = 'section-title']) &gt; 0)"/>
		<xsl:choose>
			<xsl:when test="$existsSections = 'true'">
				<!-- <test1>
					<xsl:value-of select="count($xmlContent//*[@sec-type = 'section-title'])"/>
					<xsl:for-each select="$xmlContent//*[@sec-type = 'section-title']">
						<item><xsl:value-of select="."/></item>
					</xsl:for-each>
				</test1> -->
				
				<xsl:variable name="xmlContent_step1">
					<xsl:apply-templates select="$xmlContent" mode="section-title_step1" />
				</xsl:variable>
				
				<xsl:variable name="xmlContent_step2">
					<xsl:apply-templates select="xalan:nodeset($xmlContent_step1)" mode="section-title_step2" />
				</xsl:variable>
				
				<xsl:copy-of select="$xmlContent_step2"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$xmlContent"/>
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:call-template name="insertBack"/>
		
		<xsl:if test="normalize-space($debug) = 'true'">
			<xsl:text disable-output-escaping="yes">&lt;!-- </xsl:text>
			<xsl:value-of select="count($elements//element)"/>
			<xsl:copy-of select="$elements"/>
			<xsl:text disable-output-escaping="yes">--&gt;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<!-- ======= -->
	<!-- step 1 -->
	<!-- ======= -->
	<xsl:template match="@*|node()" mode="section-title_step1">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="section-title_step1"/>
		</xsl:copy>
	</xsl:template>
	
	<!-- Examples:
	<sec sec-type="section-title" id="section_1">
		<title>Section 1: General</title>
		</sec> -->
	
	<!-- remove section title if it positioned as last sec -->
	<!-- it will be moved to upper element before following sec -->
	<xsl:template match="sec[@sec-type = 'section-title'][not(following-sibling::sec)]" mode="section-title_step1"/>
	
	<!-- remove all elements (non-normative-note, p, etc.) after section-title as last sec -->
	<!-- these elements will be moved to upper element before following sec -->
	<xsl:template match="*[preceding-sibling::sec[@sec-type = 'section-title'][not(following-sibling::sec)]]" mode="section-title_step1"/>
	
	<xsl:template match="sec[(preceding-sibling::sec[1]//sec)[last()][@sec-type = 'section-title']]" mode="section-title_step1">
		<xsl:for-each select="(preceding-sibling::sec[1]//sec)[last()][@sec-type = 'section-title']"> <!-- copy section-title from end of the previous sec -->
			<xsl:copy-of select="."/>
			<xsl:copy-of select="following-sibling::*"/>
		</xsl:for-each>
		
		<xsl:copy-of select="."/>
	</xsl:template>
	<!-- ======= -->
	<!-- End step 1 -->
	<!-- ======= -->
	
	
	<!-- ======= -->
	<!-- step 2 -->
	<!-- ======= -->
	<xsl:template match="@*|node()" mode="section-title_step2">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="section-title_step2"/>
		</xsl:copy>
	</xsl:template>
	
	<!-- move sec inside sec with type 'section-title' -->
	<xsl:template match="sec[@sec-type = 'section-title']" mode="section-title_step2" priority="2">
		<xsl:copy>
			<xsl:copy-of select="@id"/>
			<xsl:copy-of select="node()"/>
			<xsl:for-each select="following-sibling::*[preceding-sibling::sec[@sec-type = 'section-title'][1][@id = current()/@id]][not(@sec-type = 'section-title')]">
				<xsl:copy-of select="." />
			</xsl:for-each>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="*[not(@sec-type = 'section-title') and preceding-sibling::sec[@sec-type = 'section-title']]" mode="section-title_step2"/>
	<!-- ======= -->
	<!-- End step 2 -->
	<!-- ======= -->
	
	<!-- ================================ -->
	<!-- metanorma collection processing -->
	<!-- ================================ -->
	
	<!--
	<metanorma-collection ..>
			<doc-container id="...">
			</doc-container>
			<doc-container id="...">
			</doc-container>
	</metanorma-collection>
	
	to
	
	<standard>
		<front>
			<nat-meta> </nat-meta> bibdata for 1st document
			<sec>Foreword, Introduction ....</sec>  for 1st document
		</front>
		<body>
			<sub-part>
				<body></body><back></back> Sections for 1st document
			</sub-part>
			<sub-part>
				<body>
					<sec id="sec_sp-Foreword">....</sec> Foreword, Introduction sections for 2nd document
					<sec id="sec_sp-Introduction">...</sec>
					<sub-part>
						Sections for 2nd document
						<body>Scope..... </body>
						<back>...</back>
					</sub-part>
				</body>
			</sub-part>
		</body>
	</standard>
	-->
	
	
	<!-- skip processing -->
	<xsl:template match="coverimages"/>
	<!-- ================================ -->
	<!-- END: metanorma collection processing -->
	<!-- ================================ -->
	
	<xsl:template name="insertFront">
		<front>
			<xsl:for-each select="bibdata/relation[@type = 'adopted-from']">
			
				<xsl:variable name="element_name">
					<xsl:variable name="adopted_from_abbreviation" select="bibitem/contributor[role/@type='publisher']/organization/abbreviation" />
					<xsl:choose>
						<!-- If //bibdata//relation[@type = 'adopted-from']/bibitem/contributor[role/@type = 'publisher']/organization[abbreviation = 'xxx'] exists, where xxx = ISO or IEC, -->
						<xsl:when test="$adopted_from_abbreviation = 'ISO' or $adopted_from_abbreviation = 'IEC'">iso-meta</xsl:when>
						<!-- If //bibdata//relation[@type = 'adopted-from']/bibitem/contributor[role/@type = 'publisher']/organization[abbreviation = 'xxx'] exists, where xxx = CEN or CENELEC, -->
						<xsl:when test="$adopted_from_abbreviation = 'CEN' or $adopted_from_abbreviation = 'CENELEC'">reg-meta</xsl:when>
						<xsl:otherwise>std-meta</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				
				<xsl:apply-templates select="bibitem" mode="front">
					<xsl:with-param name="element_name" select="$element_name"/>
				</xsl:apply-templates>
			</xsl:for-each>

			<xsl:variable name="element_name">
				<xsl:choose>
					<!-- If //bibdata/relation[@type = 'adopted-from'] exists -->
					<xsl:when test="bibdata/relation[@type = 'adopted-from']">nat-meta</xsl:when>
					<xsl:when test="$organization = 'BSI'">nat-meta</xsl:when>
					<xsl:when test="($metanorma_type = 'IEC' or $metanorma_type = 'ISO') and $format = 'NISO'">std-meta</xsl:when>
					<xsl:when test="$outputformat = 'IEEE'">std-meta</xsl:when>
					<xsl:otherwise>iso-meta</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			
			<xsl:choose>
				<xsl:when test="$outputformat = 'IEEE'">
					<xsl:apply-templates select="bibdata" mode="front_ieee">
						<xsl:with-param name="element_name" select="$element_name"/>
					</xsl:apply-templates>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="bibdata" mode="front">
						<xsl:with-param name="element_name" select="$element_name"/>
					</xsl:apply-templates>
				</xsl:otherwise>
			</xsl:choose>
			
			<xsl:apply-templates select="preface/clause[@type = 'front_notes']" mode="front_notes"/>
			
			<xsl:if test="$organization = 'BSI'">
				<xsl:call-template name="insert_publication_info"/>
			</xsl:if>
			
			<xsl:apply-templates select="preface" mode="front_preface"/>
			
		</front>
	</xsl:template>
	
	
	<xsl:template name="insertBody">
		<xsl:if test="sections or bibliography[.//references[@normative='true']]">
			<body>
				<xsl:if test="$nat_meta_only = 'true'"> <!-- $organization = 'BSI' -->
					<xsl:apply-templates select="preface/*[@type = 'section-title' or local-name() = 'section-title'][following-sibling::*[not(self::p or self::note)][1][self::introduction]]" mode="front_preface"/>
					<xsl:apply-templates select="preface/introduction" mode="front_preface"> <!-- [0] -->
						<xsl:with-param name="skipIntroduction">false</xsl:with-param>
					</xsl:apply-templates>
				</xsl:if>
				
				<!-- Introduction in sections -->
				<xsl:apply-templates select="sections/clause[@type='intro']"/> <!-- [0] -->
			
				<!-- Scope -->
				<xsl:apply-templates select="sections/clause[@type='scope' or @type = 'overview' or title = 'Overview']"/> <!-- [1] -->
				
				<!-- Normative References -->
				<xsl:apply-templates select="bibliography/references[@normative='true'] | bibliography/clause[references[@normative='true']]"/>
				
				<!-- Terms and definitions -->
				<xsl:apply-templates select="sections/terms | 
																								sections/clause[.//terms] |
																								sections/definitions | 
																								sections/clause[.//definitions]" />		
						<!-- Another main sections -->
				<xsl:apply-templates select="sections/*[local-name() != 'terms' and 
																																																local-name() != 'definitions' and 
																																																not(@type='intro') and
																																																not(@type='scope') and
																																																not(@type='overview') and
																																																not(title = 'Overview') and
																																																not(self::clause and .//terms) and
																																																not(self::clause and .//definitions)]" />
			</body>	
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="insertBack">
		<xsl:if test="annex or bibliography/references or indexsect or .//index">
			<back>
				<xsl:if test="$outputformat = 'IEEE'">
					<xsl:apply-templates select="preface/acknowledgements" mode="front_preface">
						<xsl:with-param name="process">true</xsl:with-param>
					</xsl:apply-templates>
				</xsl:if>
			
				<xsl:if test="annex">
					<app-group>
						<xsl:apply-templates select="annex" mode="back"/>
					</app-group>
				</xsl:if>
				<xsl:apply-templates select="bibliography/references[not(@normative='true')] | bibliography/clause[references[not(@normative='true')]]" mode="back"/>
				<xsl:call-template name="insertIndex"/>
			</back>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="bibdata"/>
	<xsl:template match="preface"/>
	<xsl:template match="annex"/>
	<xsl:template match="bibliography"/>
	
	<!-- ================================== -->
	<!-- Publishing and copyright information block -->
	<!-- ================================== -->
	<xsl:template name="insert_publication_info">
		<sec id="sec_pub_info_nat" sec-type="publication_info">
			<xsl:variable name="data">
				<xsl:apply-templates select="boilerplate/copyright-statement/*" mode="publication_info"/>
			</xsl:variable>
			<xsl:if test="not(xalan:nodeset($data)/label)">
				<label/>
			</xsl:if>
			<xsl:copy-of select="$data"/>
			<xsl:apply-templates select="bibdata/docidentifier[@type = 'ISBN']" mode="publication_info"/>
			
			<xsl:if test="bibdata/ext/ics">
				<p><xsl:text>ICS </xsl:text>
					<xsl:for-each select="bibdata/ext/ics">
						<xsl:sort />
						<xsl:value-of select="normalize-space()"/>
						<xsl:if test="position() != last()">; </xsl:if>
					</xsl:for-each>
				</p>
			</xsl:if>
			
			<xsl:apply-templates select="preface/clause[@type = 'related-refs']"  mode="publication_info"/>
			
			<xsl:apply-templates select="preface/clause[@type = 'corrigenda']"  mode="publication_info"/>
			
		</sec>
	</xsl:template>
	
	<xsl:template match="title" mode="publication_info">
		<xsl:call-template name="title"/>
	</xsl:template>
	
	<xsl:template match="p" mode="publication_info">
		<xsl:call-template name="p"/>
	</xsl:template>
	
	<xsl:template match="bibdata/docidentifier[@type = 'ISBN']" mode="publication_info">
		<p>ISBN <xsl:apply-templates /></p>
	</xsl:template>
	
	<xsl:template match="preface/clause[@type = 'front_notes']" mode="front_notes">
		<notes>
			<xsl:apply-templates />
		</notes>
	</xsl:template>
	<xsl:template match="preface/clause[@type = 'front_notes']" priority="2" mode="front_preface"/>
	
	<xsl:template match="preface/clause[@type = 'related-refs']" priority="2" mode="front_preface"/>
	<xsl:template match="preface/clause[@type = 'related-refs']"  mode="publication_info">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="preface/clause[@type = 'corrigenda']" priority="2" mode="front_preface"/>
	<xsl:template match="preface/clause[@type = 'corrigenda']"  mode="publication_info">
		<sec>
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates />
		</sec>
	</xsl:template>
	<!-- ================================== -->
	<!-- END Publishing and copyright information block -->
	<!-- ================================== -->
	
	<xsl:variable name="draft_comment_text">Draft for comment</xsl:variable>
	<xsl:variable name="committee_ref_text">Committee reference</xsl:variable>
	
	<xsl:template match="bibdata | bibdata/relation[@type = 'adopted-from']/bibitem" mode="front">
		<xsl:param name="element_name"/>
		
		<!-- <iso-meta> -->
		<xsl:element name="{$element_name}">
			<xsl:if test="$element_name != 'iso-meta' and $element_name != 'std-meta'">
				<xsl:attribute name="originator">
					<xsl:variable name="abbrev">
						<xsl:for-each select="contributor[role/@type='publisher']/organization/abbreviation">
							<xsl:value-of select="."/>
							<xsl:if test="position() != last()">/</xsl:if>
						</xsl:for-each>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="starts-with($abbrev, 'BS')">BSI</xsl:when>
						<xsl:when test="starts-with($abbrev, 'CEN')">CEN</xsl:when>
						<xsl:otherwise><xsl:value-of select="$abbrev"/></xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
			</xsl:if>
			
			<xsl:variable name="bibdata"><xsl:copy-of select="."/></xsl:variable>
			
			<!-- get unique languages from element title -->
			<xsl:variable name="languages">
				<xsl:for-each select="title">
					<xsl:if test="not(preceding-sibling::*/@language = current()/@language)">
						<item language="{@language}"/>
					</xsl:if>
				</xsl:for-each>
			</xsl:variable>
			
			<!-- <xsl:for-each select="*[local-name() = 'title'][generate-id(.)=generate-id(key('klang',@language)[1])]"> -->
			<xsl:for-each select="xalan:nodeset($languages)/*">
				<title-wrap xml:lang="{@language}">
				
					<xsl:variable name="titles-components">
						<xsl:variable name="title-intro">
							 <!-- <xsl:apply-templates select="/*/*[local-name() = 'bibdata']/*[local-name() = 'title'][@language = current()/@language and @type = 'title-intro']" mode="front"/> -->
							 <xsl:apply-templates select="xalan:nodeset($bibdata)/*/title[@language = current()/@language and @type = 'title-intro']" mode="front"/>
						</xsl:variable>
						
						<xsl:variable name="title-main">					
							<!-- <xsl:apply-templates select="/*/*[local-name() = 'bibdata']/*[local-name() = 'title'][@language = current()/@language and @type = 'title-main']" mode="front"/> -->
							<xsl:apply-templates select="xalan:nodeset($bibdata)/*/title[@language = current()/@language and @type = 'title-main']" mode="front"/>
						</xsl:variable>
						
						<xsl:choose>
							<xsl:when test="normalize-space($title-main) = '' and normalize-space($title-intro) != ''">
								<main>
									<xsl:copy-of select="$title-intro"/>
								</main>
							</xsl:when>
							<xsl:otherwise>
								<intro><xsl:copy-of select="$title-intro"/></intro>
								<main><xsl:copy-of select="$title-main"/></main>
							</xsl:otherwise>
						</xsl:choose>
						
						<xsl:variable name="title-amd">
							<!-- <xsl:apply-templates select="/*/*[local-name() = 'bibdata']/*[local-name() = 'title'][@language = current()/@language and @type = 'title-amd']" mode="front"/> -->
							<xsl:apply-templates select="xalan:nodeset($bibdata)/*/title[@language = current()/@language and @type = 'title-amd']" mode="front"/>
						</xsl:variable>
						
						<xsl:variable name="title-part">
							<!-- <xsl:apply-templates select="/*/*[local-name() = 'bibdata']/*[local-name() = 'title'][@language = current()/@language and @type = 'title-part']" mode="front"/> -->
							<xsl:apply-templates select="xalan:nodeset($bibdata)/*/title[@language = current()/@language and @type = 'title-part']" mode="front"/>
						</xsl:variable>
						
						<xsl:variable name="part">
							<!-- <xsl:apply-templates select="/*/*[local-name() = 'bibdata']/*[local-name() = 'ext']/*[local-name() = 'structuredidentifier']/*[local-name() = 'project-number']/@part" mode="front"/> -->
							<xsl:apply-templates select="xalan:nodeset($bibdata)/*/ext/structuredidentifier/project-number/@part" mode="front"/>
						</xsl:variable>
						<part>
							<xsl:if test="self::compl and $part != ''">
								<xsl:choose>
									<xsl:when test="current()/@language = 'en'"><xsl:text>Part </xsl:text></xsl:when>
									<xsl:when test="current()/@language = 'fr'"><xsl:text>Partie </xsl:text></xsl:when>
								</xsl:choose>
								<xsl:value-of select="$part"/>
								<xsl:choose>
									<xsl:when test="normalize-space($title-part) = ''">
										<xsl:text>. </xsl:text>
									</xsl:when>
									<xsl:otherwise>
										<xsl:text>: </xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</part>
						
						<!-- <xsl:if test="normalize-space($title-part) != ''"> -->
						<compl>
							<xsl:copy-of select="$title-part"/>
							<xsl:if test="normalize-space($title-amd) != ''">
								<xsl:if test="normalize-space($title-part) != ''">
									<xsl:text> — </xsl:text>
								</xsl:if>
								<xsl:copy-of select="$title-amd"/>
							</xsl:if>
						</compl>
						<!-- </xsl:if> -->
						
						
					</xsl:variable>
				
					
					<xsl:for-each select="xalan:nodeset($titles-components)/*[normalize-space() != '' and not(self::part)]">
						<xsl:copy-of select="."/>
					</xsl:for-each>

					<xsl:variable name="full-title">
						<!-- <xsl:if test="normalize-space($title-intro) != ''">
							<xsl:copy-of select="$title-intro"/>
							<xsl:text> — </xsl:text>
						</xsl:if> -->
						
						<xsl:for-each select="xalan:nodeset($titles-components)/*[normalize-space() != '']">
							<xsl:value-of select="."/>
							<xsl:if test="normalize-space() != '' and position() != last()">
								<xsl:text> — </xsl:text>
							</xsl:if>
						</xsl:for-each>
						
						<!-- <xsl:copy-of select="$title-main"/>
						<xsl:if test="normalize-space($title-part) != ''">
							<xsl:if test="$part != ''">
								<xsl:text> — </xsl:text>
									<xsl:choose>
										<xsl:when test="current()/@language = 'en'"><xsl:text>Part </xsl:text></xsl:when>
										<xsl:when test="current()/@language = 'fr'"><xsl:text>Partie </xsl:text></xsl:when>
									</xsl:choose>
									<xsl:value-of select="$part"/>
									<xsl:text>: </xsl:text>															
							</xsl:if>
							<xsl:if test="normalize-space($title-part) = ''">. </xsl:if>
							<xsl:copy-of select="$title-part"/>
						</xsl:if>
						<xsl:if test="normalize-space($title-amd) != ''">
							<xsl:copy-of select="$title-amd"/>
						</xsl:if> -->
						
					</xsl:variable>
					<full><xsl:copy-of select="$full-title"/></full>
					
					
				</title-wrap>
			</xsl:for-each>
			
			<!-- <part-number> -->
			<xsl:variable name="part_number">
				<xsl:apply-templates select="ext/structuredidentifier/partnumber | ext/structuredidentifier/project-number/@part" mode="front"/>
			</xsl:variable>
			
			<xsl:if test="$element_name = 'std-meta'">
				<proj-id>
					<xsl:if test="$metanorma_type = 'IEC'">
						<xsl:text>iec:proj:</xsl:text>
					</xsl:if>
					<xsl:apply-templates select="ext/structuredidentifier/project-number" mode="front"/>
					<xsl:if test="normalize-space($part_number) != ''">:<xsl:value-of select="$part_number"/></xsl:if>
				</proj-id>
				<release-version>
					<xsl:apply-templates select="ext/doctype" mode="front"/>
				</release-version>
			</xsl:if>
			
			<xsl:if test="$element_name != 'std-meta'">
				<doc-ident>
					<sdo>
						<xsl:for-each select="contributor[role/@type='author']/organization/abbreviation">
							<xsl:apply-templates select="." mode="front"/>
							<xsl:if test="position() != last()">/</xsl:if>
						</xsl:for-each>
					</sdo>
					<proj-id>
						<!-- <xsl:apply-templates select="ext/structuredidentifier/project-number" mode="front"/> -->
						<xsl:apply-templates select="../metanorma-extension/semantic-metadata/proj-id" mode="front"/>
					</proj-id>
					<language>
						<xsl:apply-templates select="language" mode="front"/>
					</language>
					<release-version>
						<xsl:apply-templates select="status/stage[1]/@abbreviation" mode="front"/>
					</release-version>
					<xsl:if test="$element_name = 'iso-meta'">
						<xsl:call-template name="generateURN"/>
					</xsl:if>
				</doc-ident>
			</xsl:if>
			
			<std-ident>
				<originator>
					<xsl:for-each select="contributor[role/@type='publisher']/organization/abbreviation">
						<xsl:apply-templates select="." mode="front">
							<xsl:with-param name="short">true</xsl:with-param>
						</xsl:apply-templates>
						<xsl:if test="position() != last()">/</xsl:if>
					</xsl:for-each>
				</originator>
				<doc-type>
					<xsl:apply-templates select="ext/doctype" mode="front"/>
				</doc-type>
				
				<xsl:apply-templates select="ext/subdoctype" mode="front"/>
				
				<xsl:variable name="docnumber">
					<xsl:apply-templates select="docnumber" mode="front"/>
				</xsl:variable>
				<doc-number>					
					<xsl:value-of select="$docnumber"/>
				</doc-number>
				
				<xsl:if test="normalize-space($part_number) != ''">
					<part-number>
						<xsl:value-of select="$part_number"/>
					</part-number>
				</xsl:if>
				
				<edition>
					<xsl:apply-templates select="edition" mode="front"/>
				</edition>
				
				<xsl:variable name="revision_date">
					<xsl:apply-templates select="version/revision-date" mode="front"/>
				</xsl:variable>
				<version>
					<xsl:value-of select="$revision_date"/>
					<xsl:if test="normalize-space($revision_date) = ''">
						<xsl:apply-templates select="version/draft" mode="front"/>
					</xsl:if>
				</version>
				
				<xsl:if test="contains($organization_abbreviation, 'IEC')">
					<std-id-group>
						<std-id originator="IEC" std-id-link-type="urn" std-id-type="dated">
							<!-- urn:iec:std:iec:62830-8:2021-10::: -->
							<xsl:text>urn:iec:std:iec:</xsl:text>
							<xsl:value-of select="$docnumber"/>
							<xsl:if test="normalize-space($part_number) != ''">-<xsl:value-of select="$part_number"/></xsl:if>
							<xsl:if test="normalize-space($revision_date) != ''">:<xsl:value-of select="substring($revision_date,1,7)"/></xsl:if>
							<xsl:text>:::</xsl:text>
						</std-id>
					</std-id-group>
					
					<xsl:if test="docidentifier[@type = 'ISBN']">
						<isbn><xsl:value-of select="docidentifier[@type = 'ISBN']"/></isbn>
					</xsl:if>

				</xsl:if>
				
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/suppl-type" mode="front"/>
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/suppl-number" mode="front"/>
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/suppl-version" mode="front"/>
				
			</std-ident>
			
			<xsl:if test="contains($organization_abbreviation, 'IEC')">
				<std-org>
					<std-org-abbrev>
						<xsl:for-each select="copyright/owner/organization/abbreviation">
							<xsl:value-of select="."/>
							<xsl:if test="position() != last()">/</xsl:if>
						</xsl:for-each>
					</std-org-abbrev>
				</std-org>
			</xsl:if>

			<content-language>
				<xsl:apply-templates select="language" mode="front"/>
			</content-language>
			
			<xsl:variable name="docidentifier">
				<xsl:apply-templates select="docidentifier[1]" mode="front"/>
			</xsl:variable>
			
			<xsl:variable name="docidentifier_type">
				<xsl:call-template name="setDatedUndatedType">
					<xsl:with-param name="value" select="$docidentifier"/>
				</xsl:call-template>
			</xsl:variable>
			<!-- <docidentifier><xsl:value-of select="$docidentifier"/></docidentifier>
			<docidentifier_type><xsl:value-of select="$docidentifier_type"/></docidentifier_type> -->
			<xsl:choose>
				<xsl:when test="$docidentifier_type = 'dated'">
					<std-ref type="dated">
						<xsl:value-of select="$docidentifier"/>
					</std-ref>
					<std-ref type="undated">
						<xsl:value-of select="substring-before($docidentifier, ':')"/>
					</std-ref>
				</xsl:when>
				<xsl:otherwise> <!-- undated -->
					<std-ref type="dated">
						<xsl:value-of select="$docidentifier"/>
						<xsl:variable name="revision_date">
							<xsl:apply-templates select="version/revision-date" mode="front"/>
						</xsl:variable>
						<xsl:text>:</xsl:text><xsl:value-of select="substring($revision_date,1,4)"/>
					</std-ref>
					<std-ref type="undated">
						<xsl:value-of select="$docidentifier"/>
					</std-ref>
				</xsl:otherwise>
			</xsl:choose>
			
			<xsl:variable name="doc_ref">
				<xsl:choose>
					<xsl:when test="docidentifier[@type='iso-reference' or @type = 'BS']">
						<xsl:apply-templates select="docidentifier[@type='iso-reference' or @type = 'BS'][last()]" mode="front"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="docidentifier[@type='iso-with-lang']" mode="front"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:if test="normalize-space($doc_ref) != ''">
				<doc-ref>
					<xsl:value-of select="$doc_ref"/>
				</doc-ref>
			</xsl:if>
			
			<xsl:if test="$organization = 'BSI'">
				<xsl:for-each select="date[not(@type='release')][normalize-space(on) != '']">
					<xsl:apply-templates select="on" mode="front"/>
				</xsl:for-each>
			</xsl:if>
			
			<!-- <release-date> -->
			<xsl:variable name="release-date_">
				<dates>
					<xsl:apply-templates select="date[@type='release']/on" mode="front"/>
				</dates>
			</xsl:variable>
			<xsl:variable name="release-date" select="xalan:nodeset($release-date_)"/>
			
			<xsl:choose>				
				<xsl:when test="$format = 'NISO'">
					<xsl:copy-of select="$release-date/dates/*"/>
				</xsl:when>
				<xsl:otherwise><!-- get last date for ISO format (allows only one release-date  -->
					<xsl:choose>
						<xsl:when test="count($release-date/dates/*) &gt; 1">
							<xsl:copy-of select="$release-date/dates/*[last()]"/>
						</xsl:when>
						<xsl:otherwise>
							<!-- mandatory element for ISO -->
							<release-date />
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
			
			<xsl:if test="$metanorma_type = 'ISO' or $metanorma_type = 'IEC'">
				<xsl:for-each select="date[not(@type='release')][normalize-space(on) != '']">
					<!-- example: <meta-date type="stability-date">2024-12-31</meta-date> -->
					<meta-date>
						<xsl:copy-of select="@type"/>
						<xsl:value-of select="on"/>
					</meta-date>
				</xsl:for-each>
			</xsl:if>
			
			<!-- 
			<meta-date type="DOR">
			<meta-date type="DOW">
			<meta-date type="DOP">
			<meta-date type="DOA"> -->
			<xsl:apply-templates select="../metanorma-extension/semantic-metadata/dor" mode="front"/>
			<xsl:apply-templates select="../metanorma-extension/semantic-metadata/dow" mode="front"/>
			<xsl:apply-templates select="../metanorma-extension/semantic-metadata/dop" mode="front"/>
			<xsl:apply-templates select="../metanorma-extension/semantic-metadata/doa" mode="front"/>
			<xsl:apply-templates select="../metanorma-extension/semantic-metadata/vote-start" mode="front"/>
			<xsl:apply-templates select="../metanorma-extension/semantic-metadata/vote-end" mode="front"/>
			
			<!-- <wi-number> -->
			<xsl:apply-templates select="../metanorma-extension/semantic-metadata/wi-number" mode="front"/>
			
			<xsl:variable name="related_comm_ref" select="relation[@type='related']/bibitem/docidentifier"/>
			<xsl:variable name="related_comm_ref_text">Committee reference</xsl:variable>
			<comm-ref>
				<xsl:choose>
					<xsl:when test="$organization = 'BSI' and starts-with($related_comm_ref, $related_comm_ref_text)">
						<xsl:value-of select="normalize-space(substring-after($related_comm_ref, $related_comm_ref_text))"/>
					</xsl:when>
					<xsl:when test="ext/editorialgroup/@identifier">
						<xsl:value-of select="@identifier"/>
					</xsl:when>
					<xsl:when test="ext/editorialgroup/technical-committee and not(
						ext/editorialgroup/subcommittee and 
						ext/editorialgroup/workgroup )">
						<xsl:value-of select="ext/editorialgroup/technical-committee/@number"/>
					</xsl:when>
					<xsl:otherwise>

						<xsl:choose>
							<xsl:when test="ext/editorialgroup/agency">
								<xsl:for-each select="ext/editorialgroup/agency">
									<xsl:value-of select="."/>
									<xsl:if test="position() != last()">/</xsl:if>
								</xsl:for-each>
								<xsl:text> </xsl:text>
							</xsl:when>
							<xsl:otherwise>
								<xsl:variable name="abbreviation">
									<xsl:for-each select="copyright/owner/organization/abbreviation">
									<xsl:apply-templates select="." mode="front"/>
										<xsl:if test="position() != last()">/</xsl:if>
									</xsl:for-each>
								</xsl:variable>
								
								<xsl:if test="$abbreviation != $organization">
									<xsl:value-of select="$abbreviation"/>
									<xsl:if test="$organization != 'ISO'">
										<xsl:text>/</xsl:text>
									</xsl:if>
									<xsl:if test="$organization = 'ISO'">
										<xsl:text> </xsl:text>
									</xsl:if>
								</xsl:if>
								
							</xsl:otherwise>
						</xsl:choose>
							
						
						
						<xsl:variable name="editorialgroup">
							<item><xsl:apply-templates select="ext/editorialgroup/technical-committee" mode="front"/></item>
							<item><xsl:apply-templates select="ext/editorialgroup/subcommittee" mode="front"/></item>
							<xsl:if test="$organization != 'ISO'"> <!-- should only be the "committee level" -->
								<item><xsl:apply-templates select="ext/editorialgroup/workgroup" mode="front"/></item> 
							</xsl:if>
						</xsl:variable>
						<xsl:for-each select="xalan:nodeset($editorialgroup)/item[normalize-space() != '']">
							<xsl:value-of select="."/>
							<xsl:if test="following-sibling::*[normalize-space() != '']">
								<xsl:text>/</xsl:text>
							</xsl:if>
						</xsl:for-each>
					</xsl:otherwise>
				</xsl:choose>
				
<!-- 				<xsl:value-of select="concat(
										'/', *[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'technical-committee']/@type, ' ',
										*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'technical-committee']/@number)"/>
 -->				
			</comm-ref>
			
			<xsl:variable name="secretariat">
				<xsl:apply-templates select="ext/editorialgroup/secretariat" mode="front"/>
			</xsl:variable>
			<xsl:if test="normalize-space($secretariat) != '' or $organization = 'BSI'">
				<secretariat>
					<xsl:value-of select="$secretariat"/>
				</secretariat>
			</xsl:if>
			<!-- <ics> -->
			<xsl:apply-templates select="ext/ics/code" mode="front"/>
			
			
			<xsl:apply-templates select="../metanorma-extension/semantic-metadata/page-count" mode="front"/>
			
			
			
			<!-- std-xref -->
			<!-- ignoring all instances of .//relation[@type = 'adopted-from']/bibitem -->
			<xsl:apply-templates select="relation[@type != 'adopted-from' and not(@type = 'related' and (starts-with(bibitem/docidentifier, $draft_comment_text) or starts-with(bibitem/docidentifier, $committee_ref_text)))]" mode="front" /><!-- adopted-from -> to standalone xxx-meta , related -> comm-ref  -->
			
			<xsl:apply-templates select="relation[@type = 'related'][starts-with(bibitem/docidentifier, $draft_comment_text)]" mode="front" />
			
			<!-- <release-version-id> -->
			<xsl:apply-templates select="../metanorma-extension/semantic-metadata/release-version-id" mode="front"/>
			
			<!-- <metanorma_type><xsl:value-of select="$metanorma_type"/></metanorma_type> -->
			<xsl:choose>
				<xsl:when test="$metanorma_type = 'IEC'">
					
					<xsl:for-each select="copyright">
						<xsl:variable name="pos" select="position()"/>
						
						<permissions>
							<copyright-statement>
								<xsl:apply-templates select="/*/boilerplate/copyright-statement[$pos]/clause/*[1]/node()"/>
							</copyright-statement>
							<copyright-year>
								<xsl:apply-templates select="from" mode="front"/>
							</copyright-year>
							<copyright-holder>
								<xsl:apply-templates select="owner/organization/abbreviation" mode="front"/>
							</copyright-holder>
							
							<xsl:for-each select="/*/boilerplate/copyright-statement[$pos]">
								<license>
									<license-p><xsl:apply-templates select="clause/p[@id = 'boilerplate-message' or not(starts-with(@id, 'boilerplate-'))]/node()"/></license-p>
									<xsl:if test="clause/p[@id = 'boilerplate-name' or @id = 'boilerplate-address']">
										<license-p>
											<address>
												<addr-line>
													<xsl:for-each select="clause/p[@id = 'boilerplate-name' or @id = 'boilerplate-address']">
														<xsl:apply-templates />
														<xsl:if test="position() != last()">, </xsl:if>
													</xsl:for-each>
												</addr-line>
											</address>
										</license-p>
									</xsl:if>
								</license>
							</xsl:for-each>
						</permissions>
					</xsl:for-each>
				
					<!-- <xsl:call-template name="put_copyright_year"/>
					<xsl:call-template name="put_copyright_holder"/>
					<xsl:if test="/*/boilerplate/copyright-statement/clause/p">
						<license>
							<license-p><xsl:apply-templates select="/*/boilerplate/copyright-statement/clause/p[@id = 'boilerplate-message' or not(starts-with(@id, 'boilerplate-'))]/node()"/></license-p>
							<xsl:if test="/*/boilerplate/copyright-statement/clause/p[@id = 'boilerplate-name' or @id = 'boilerplate-address']">
								<license-p>
									<address>
										<addr-line>
											<xsl:for-each select="/*/boilerplate/copyright-statement/clause/p[@id = 'boilerplate-name' or @id = 'boilerplate-address']">
												<xsl:apply-templates />
												<xsl:if test="position() != last()">, </xsl:if>
											</xsl:for-each>
										</addr-line>
									</address>
								</license-p>
							</xsl:if>
						</license>
					</xsl:if> -->
				</xsl:when>
				<xsl:when test="$metanorma_type = 'ISO'">
					<permissions>
						<copyright-statement>All rights reserved</copyright-statement>
						<xsl:call-template name="put_copyright_year"/>
						<xsl:call-template name="put_copyright_holder"/>
					</permissions>
				</xsl:when>
				<xsl:when test="$organization = 'BSI'">
					<permissions>
						<xsl:apply-templates select="../metanorma-extension/semantic-metadata/copyright-statement"/>
						<xsl:call-template name="put_copyright_year"/>
						<xsl:call-template name="put_copyright_holder">
							<xsl:with-param name="from">name</xsl:with-param>
						</xsl:call-template>
					</permissions>
				</xsl:when>
				
				<xsl:otherwise> <!-- not IEC, ISO and not BSI -->
					<permissions>
						<!-- <copyright-statement>All rights reserved</copyright-statement> -->
						<xsl:apply-templates select="/*/boilerplate/copyright-statement"/>
						<xsl:call-template name="put_copyright_year"/>
						<xsl:call-template name="put_copyright_holder"/>
						
						<xsl:apply-templates select="/*/boilerplate/legal-statement"/>
						<xsl:apply-templates select="/*/boilerplate/license-statement"/>
					</permissions>
				</xsl:otherwise>
			</xsl:choose>
			
			<xsl:for-each select="uri">
				<self-uri xlink:type="simple" xmlns:xlink="http://www.w3.org/1999/xlink">
					<xsl:if test="@type">
						<xsl:attribute name="content-type"><xsl:value-of select="@type"/></xsl:attribute>
					</xsl:if>
					<xsl:value-of select="."/>
				</self-uri>
			</xsl:for-each>
			
			<xsl:apply-templates select="/*/preface/abstract" mode="front_abstract"/>
			
			<xsl:variable name="custom-meta-group_">
				<xsl:choose>
					<xsl:when test="$metanorma_type = 'IEC'">
						<xsl:apply-templates select="ext/price-code" mode="custom_meta"/>
					</xsl:when>
					<xsl:when test="$organization = 'BSI'">
						<xsl:apply-templates select="docidentifier[@type = 'ISBN']" mode="custom_meta"/>
					</xsl:when>
					<xsl:otherwise> <!-- non IEC, BSI -->
						<xsl:if test="docidentifier[@type = 'ISBN'] or
											ext/horizontal or
											status/stage or 
											status/substage">
							<xsl:apply-templates select="docidentifier[@type = 'ISBN']" mode="custom_meta"/>
							<xsl:apply-templates select="ext/horizontal" mode="custom_meta"/>
							<xsl:apply-templates select="status/stage" mode="custom_meta"/>
							<xsl:apply-templates select="status/substage" mode="custom_meta"/>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
				
				<xsl:choose>
					<xsl:when test="../metanorma-extension/presentation-metadata[name = 'HTML TOC Heading Levels']"><xsl:apply-templates select="../metanorma-extension/presentation-metadata[name = 'HTML TOC Heading Levels']" mode="custom_meta"/></xsl:when>
					<xsl:when test="../metanorma-extension/presentation-metadata[name = 'DOC TOC Heading Levels']"><xsl:apply-templates select="../metanorma-extension/presentation-metadata[name = 'DOC TOC Heading Levels']" mode="custom_meta"/></xsl:when>
					<xsl:when test="../metanorma-extension/presentation-metadata[name = 'TOC Heading Levels']"><xsl:apply-templates select="../metanorma-extension/presentation-metadata[name = 'TOC Heading Levels']" mode="custom_meta"/></xsl:when>
				</xsl:choose>
				
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/upi" mode="custom_meta"/>
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/price-ref-pages" mode="custom_meta"/>
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/published-logo" mode="custom_meta"/>
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/generation-date" mode="custom_meta"/>
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/originator-identifier" mode="custom_meta"/>
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/colour-print" mode="custom_meta"/>
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/conversion-version" mode="custom_meta"/>
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/conversion-date" mode="custom_meta"/>
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/perinorm-id" mode="custom_meta"/>
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/version-history" mode="custom_meta"/>
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/wi-number" mode="custom_meta"/>
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/release-version-id" mode="custom_meta"/>
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/metadata-update" mode="custom_meta"/>
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/international" mode="custom_meta"/>
				<xsl:apply-templates select="../metanorma-extension/semantic-metadata/isoviennaagreement" mode="custom_meta"/>

			</xsl:variable>
			<xsl:variable name="custom-meta-group" select="xalan:nodeset($custom-meta-group_)"/>
			
			<xsl:if test="$custom-meta-group/custom-meta">
				<custom-meta-group>
					<xsl:copy-of select="$custom-meta-group"/>
				</custom-meta-group>
			</xsl:if>
			
			<xsl:if test="self::bibdata">
				<!-- check non-processed elements in bibdata -->
				<xsl:variable name="front_check">
					<xsl:apply-templates mode="front_check"/>
					<xsl:apply-templates select="../metanorma-extension" mode="front_check"/>
				</xsl:variable>

				<xsl:if test="normalize-space($front_check) != '' or count(xalan:nodeset($front_check)/*) &gt; 0">
					<xsl:text>WARNING! There are unprocessed elements in bibdata:&#xa;</xsl:text>
					<xsl:text>===================================&#xa;</xsl:text>
					<xsl:apply-templates select="xalan:nodeset($front_check)" mode="display_check"/>
					<xsl:text>&#xa;===================================&#xa;</xsl:text>
				</xsl:if>
			</xsl:if>
		<!-- </iso-meta> </nat-meta> </std-meta> --> 
		</xsl:element>
	</xsl:template> <!-- bibdata mode="front" -->
	
	<xsl:template match="keyword">
		<xsl:param name="process">false</xsl:param>
		<xsl:if test="$process = 'true'">
			<kwd-group kwd-group-type="AuthorFree">
				<xsl:for-each select=". | following-sibling::keyword">
					<kwd><xsl:value-of select="."/></kwd>
				</xsl:for-each>
			</kwd-group>
		</xsl:if>
	</xsl:template>
	
	<xsl:variable name="trademark">&#x2122;</xsl:variable>
	
	
	<xsl:template match="semantic-metadata/copyright-statement">
		<copyright-statement><xsl:apply-templates/></copyright-statement>
	</xsl:template>
	<xsl:template name="put_copyright_year">
		<copyright-year>
			<xsl:apply-templates select="copyright[1]/from" mode="front"/>
		</copyright-year>
	</xsl:template>
	<xsl:template name="put_copyright_holder">
		<xsl:param name="from"/>
		<copyright-holder>
			<xsl:choose>
				<xsl:when test="$from = 'name'">
					<xsl:for-each select="copyright/owner/organization/name">
						<xsl:apply-templates select="." mode="front"/>
						<xsl:if test="position() != last()">/</xsl:if>
					</xsl:for-each>
				</xsl:when>
				<xsl:when test="copyright/owner/organization/abbreviation">
					<xsl:for-each select="copyright/owner/organization/abbreviation">
						<xsl:apply-templates select="." mode="front"/>
						<xsl:if test="position() != last()">/</xsl:if>
					</xsl:for-each>
				</xsl:when>
				<xsl:otherwise>
					<xsl:for-each select="copyright/owner/organization/name">
						<xsl:apply-templates select="." mode="front"/>
						<xsl:if test="position() != last()">/</xsl:if>
					</xsl:for-each>
				</xsl:otherwise>
			</xsl:choose>
		</copyright-holder>
	</xsl:template>
	
	
	
	<xsl:template match="@*|node()" mode="display_check">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="display_check"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="text()"  mode="display_check">
		<xsl:value-of select="normalize-space(.)"/>
	</xsl:template>
	
	<xsl:template match="@*" mode="front">
		<xsl:value-of select="."/>
	</xsl:template>	
	<xsl:template match="text()" mode="front">
		<xsl:value-of select="."/>
	</xsl:template>
	<xsl:template match="*" mode="front">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="ext/editorialgroup/technical-committee |
																ext/editorialgroup/subcommittee |
																ext/editorialgroup/workgroup" mode="front">
		<xsl:if test="normalize-space(@type) != '' or normalize-space(@number) != ''">
			<xsl:choose>
				<xsl:when test="normalize-space(@type) != ''">
					<xsl:value-of select="@type"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="self::technical-committee">TC</xsl:when>
						<xsl:when test="self::subcommittee">SC</xsl:when>
						<xsl:when test="self::workgroup">WG</xsl:when>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="normalize-space(@number) != ''">
				<xsl:value-of select="concat(' ', @number)"/>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	
	
	<xsl:template match="bibdata/date/on | bibitem/date/on" mode="front">
		<xsl:choose>
			<xsl:when test="../@type = 'release'">
				<release-date>
					<xsl:value-of select="."/>
				</release-date>
			</xsl:when>
			<xsl:when test="../@type = 'published'"> <!-- position() = 1 and  and ../following-sibling::date/@type = 'published'  -->
				<pub-date>
					<xsl:if test="$organization = 'BSI'">
						<xsl:attribute name="pub-type">PUBL</xsl:attribute>
					</xsl:if>
					<xsl:value-of select="."/>
				</pub-date>
			</xsl:when>
			<xsl:otherwise>
				<release-date>
					<!-- <xsl:if test="parent::*/@type">
						<xsl:attribute name="date-type">
							<xsl:value-of select="parent::*/@type"/>
						</xsl:attribute>
					</xsl:if> -->
					<xsl:value-of select="."/>
				</release-date>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	
	<xsl:template match="ext/ics/code" mode="front">
		<ics><xsl:apply-templates mode="front"/></ics>
	</xsl:template>

	<xsl:template match="ext/doctype" mode="front">
		<xsl:variable name="value" select="normalize-space()"/>
		<xsl:choose>
			<xsl:when test="$value = 'international-standard'">IS</xsl:when>
			<xsl:when test="$organization = 'BSI'">
				<xsl:call-template name="capitalize">
					<xsl:with-param name="str" select="$value"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="ext/subdoctype" mode="front">
		<xsl:text disable-output-escaping="yes">&lt;!--</xsl:text>
			<xsl:copy-of select="."/>
		<xsl:text disable-output-escaping="yes">--&gt;</xsl:text>
	</xsl:template>
	
	<xsl:template match="*[self::bibdata or self::bibitem]/relation" mode="front">
		<xsl:variable name="value" select="bibitem/docidentifier"/>
		
		<xsl:choose>
			<xsl:when test="@type = 'related' and starts-with($value, $draft_comment_text)">
				<!--
					<relation type="related">
						<bibitem>
						<title> </title>
						<docidentifier>Draft for comment 20/30387670 DC</docidentifier>
						</bibitem>
						</relation>
					-->
					<!--
					<std-xref type="isPublishedFormatOf">
						<std-ref type="undated">20/30387670 DC</std-ref>
					</std-xref>
					-->
					<std-xref type="isPublishedFormatOf">
						<std-ref>
							<xsl:attribute name="type">
								<xsl:call-template name="setDatedUndatedType">
									<xsl:with-param name="value" select="$value"/>
								</xsl:call-template>
							</xsl:attribute>
							<xsl:value-of select="normalize-space(substring-after($value, $draft_comment_text))"/>
						</std-ref>
					</std-xref>
			</xsl:when>
			<xsl:otherwise>			
				<!--
				<relation xmlns="https://www.metanorma.org/ns/iso" type="informativelyReferences">
					<bibitem>BS EN ISO 19011:2018</bibitem>
				</relation>
				-->
				<!--
				<std-xref type="informativelyReferences">
					<std-ref type="dated">BS EN ISO 19011:2018</std-ref>
				</std-xref>
				-->
				<std-xref>
					<xsl:attribute name="type">
						<xsl:choose>
							<xsl:when test="@type = 'updates' and description = 'revises'">revises</xsl:when>
							<xsl:when test="@type = 'obsoletes' and description = 'replaces'">replaces</xsl:when>
							<xsl:when test="@type = 'updates' and description = 'amends'">amends</xsl:when>
							<xsl:when test="@type = 'updates' and description = 'corrects'">corrects</xsl:when>
							<xsl:when test="@type = 'isCitedIn' and description = 'informatively cited in'">informativelyReferencedBy</xsl:when>
							<xsl:when test="@type = 'cites' and description = 'informatively cites'">informativelyReferences</xsl:when>
							<xsl:when test="@type = 'isCitedIn' and description = 'normatively cited in'">normativelyReferencedBy</xsl:when>
							<xsl:when test="@type = 'cites' and description = 'normatively cites'">normativelyReferences</xsl:when>
							<xsl:when test="@type = 'adoptedFrom' and description = 'identical adopted from'">isIdenticalNationalStandardOf</xsl:when>
							<xsl:when test="@type = 'adoptedFrom' and description = 'modified adopted from'">isModifiedNationalStandardOf</xsl:when>
							<xsl:when test="@type = 'successorOf'">isProgressionOf</xsl:when>
							<xsl:when test="@type = 'manifestationOf'">isPublishedFormatOf</xsl:when>
							<xsl:when test="@type = 'related' and bibitem/ext/doctype = 'directive' and description = 'related directive'">relatedDirective</xsl:when>
							<xsl:when test="@type = 'related' and bibitem/ext/doctype = 'mandate' and description = 'related mandate'">relatedMandate</xsl:when>
							<xsl:when test="@type = 'obsoletes' and description = 'supersedes'">supersedes</xsl:when>
							<xsl:when test="@type = 'related'"></xsl:when>
							<xsl:when test="@type = 'annotationOf'">commentOn</xsl:when>
							<xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:apply-templates mode="front"/>
				</std-xref>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="*[self::bibdata or self::bibitem]/relation[@type != 'adopted-from']/text()[normalize-space() = '']" mode="front"/>
	
	<xsl:template match="*[self::bibdata or self::bibitem]/relation[@type != 'adopted-from']/bibitem" mode="front">
		<std-ref>
			<xsl:copy-of select="@*[not(local-name() = 'section' or local-name() = 'section_prefix' or local-name() = 'schema-version')]"/>
			<xsl:attribute name="type">
				<xsl:call-template name="setDatedUndatedType">
					<xsl:with-param name="value" select="docidentifier"/>
				</xsl:call-template>
			</xsl:attribute>
			<xsl:variable name="text">
				<xsl:apply-templates mode="front"/>
			</xsl:variable>
			<xsl:value-of select="normalize-space($text)"/>
		</std-ref>
	</xsl:template>
	
	<xsl:template match="*[self::bibdata or self::bibitem]/relation[@type != 'adopted-from']/bibitem/title[. = '--']" mode="front"/>
	<xsl:template match="*[self::bibdata or self::bibitem]/relation[@type != 'adopted-from']/description" mode="front"/>
	<xsl:template match="*[self::bibdata or self::bibitem]/relation[@type != 'adopted-from']/bibitem/ext" mode="front"/>
	
	<xsl:template match="contributor/organization/abbreviation" mode="front">
		<xsl:param name="short">false</xsl:param>
		<xsl:choose>
			<xsl:when test=". = 'BSI' and $short = 'true'">BS</xsl:when>
			<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- =============== -->
	<!-- custom-meta -->
	<!-- =============== -->
	<xsl:template match="docidentifier[@type = 'ISBN']" mode="custom_meta">
		<custom-meta>
			<meta-name>ISBN</meta-name>
			<meta-value><xsl:value-of select="."/></meta-value>
		</custom-meta>
	</xsl:template>
	
	<xsl:template match="ext/horizontal" mode="custom_meta">
		<custom-meta>
			<meta-name>horizontal</meta-name>
			<meta-value><xsl:value-of select="."/></meta-value>
		</custom-meta>
	</xsl:template>
	
	<xsl:template match="status/stage | status/substage" mode="custom_meta">
		<custom-meta>
			<meta-name><xsl:value-of select="local-name()"/></meta-name>
			<meta-value><xsl:value-of select="."/></meta-value>
		</custom-meta>
		<xsl:if test="@abbreviation">
			<custom-meta>
				<meta-name><xsl:value-of select="local-name()"/>_abbreviation</meta-name>
				<meta-value><xsl:value-of select="@abbreviation"/></meta-value>
			</custom-meta>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="ext/price-code" mode="custom_meta">
		<custom-meta>
			<meta-name>price code</meta-name>
			<meta-value>iec:<xsl:value-of select="."/></meta-value>
		</custom-meta>
	</xsl:template>
	
	<xsl:template match="metanorma-extension/presentation-metadata[name = 'TOC Heading Levels'] |
						metanorma-extension/presentation-metadata[name = 'HTML TOC Heading Levels'] |
						metanorma-extension/presentation-metadata[name = 'DOC TOC Heading Levels']" mode="custom_meta">
		<custom-meta>
			<meta-name>TOC Heading Level</meta-name>
			<meta-value><xsl:value-of select="value"/></meta-value>
		</custom-meta>
	</xsl:template>
	
	<xsl:template match="metanorma-extension/semantic-metadata/proj-id" mode="front">
		<xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="metanorma-extension/semantic-metadata/suppl-type" mode="front">
		<suppl-type>
			<xsl:value-of select="."/>
		</suppl-type>
	</xsl:template>
	
	<xsl:template match="metanorma-extension/semantic-metadata/suppl-number" mode="front">
		<suppl-number>
			<xsl:value-of select="."/>
		</suppl-number>
	</xsl:template>
	
	<xsl:template match="metanorma-extension/semantic-metadata/suppl-version" mode="front">
		<suppl-version>
			<xsl:value-of select="."/>
		</suppl-version>
	</xsl:template>
	
	<xsl:template match="metanorma-extension/semantic-metadata/*[local-name() = 'dor' or local-name() = 'dow' or local-name() = 'dop' or local-name() = 'doa']" mode="front">
		<meta-date type="{java:toUpperCase(java:java.lang.String.new(local-name()))}"><xsl:value-of select="."/></meta-date>
	</xsl:template>
	<xsl:template match="metanorma-extension/semantic-metadata/*[local-name() = 'vote-start' or local-name() = 'vote-end']" mode="front">
		<meta-date type="{local-name()}"><xsl:value-of select="."/></meta-date>
	</xsl:template>
	
	<xsl:template match="metanorma-extension/semantic-metadata/wi-number" mode="front">
		<wi-number>
			<xsl:value-of select="."/>
		</wi-number>
	</xsl:template>
	
	<xsl:template match="metanorma-extension/semantic-metadata/release-version-id" mode="front">
		<release-version-id>
			<xsl:value-of select="."/>
		</release-version-id>
	</xsl:template>
	
	<xsl:template match="metanorma-extension/semantic-metadata/page-count" mode="front">
		<page-count count="{.}" />
	</xsl:template>
	
	<xsl:template match="metanorma-extension/semantic-metadata/upi" mode="custom_meta">
		<custom-meta>
			<meta-name>UPI</meta-name>
			<meta-value><xsl:value-of select="."/></meta-value>
		</custom-meta>
	</xsl:template>
	
	<xsl:template match="metanorma-extension/semantic-metadata/*[local-name() = 'price-ref-pages' or local-name() = 'published-logo' or 
	local-name() = 'generation-date' or local-name()='colour-print' or local-name()='version-history' or local-name() = 'wi-number' or 
	local-name() = 'release-version-id' or local-name() = 'metadata-update' or local-name() = 'international']" mode="custom_meta">
		<custom-meta>
			<meta-name><xsl:value-of select="local-name()"/></meta-name>
			<meta-value><xsl:value-of select="."/></meta-value>
		</custom-meta>
	</xsl:template>
	
	<xsl:template match="metanorma-extension/semantic-metadata/originator-identifier" mode="custom_meta">
		<custom-meta>
			<meta-name>Originator Identifier</meta-name>
			<meta-value><xsl:value-of select="."/></meta-value>
		</custom-meta>
	</xsl:template>
	
	<xsl:template match="metanorma-extension/semantic-metadata/conversion-version" mode="custom_meta">
		<custom-meta>
			<meta-name>conversion version</meta-name>
			<meta-value><xsl:value-of select="."/></meta-value>
		</custom-meta>
	</xsl:template>
	
	<xsl:template match="metanorma-extension/semantic-metadata/conversion-date" mode="custom_meta">
		<custom-meta>
			<meta-name>conversion date</meta-name>
			<meta-value><xsl:value-of select="."/></meta-value>
		</custom-meta>
	</xsl:template>
	
	<xsl:template match="metanorma-extension/semantic-metadata/perinorm-id" mode="custom_meta">
		<custom-meta>
			<meta-name>Perinorm ID</meta-name>
			<meta-value><xsl:value-of select="."/></meta-value>
		</custom-meta>
	</xsl:template>
	
	<xsl:template match="metanorma-extension/semantic-metadata/isoviennaagreement" mode="custom_meta">
		<custom-meta>
			<meta-name>ISOViennaAgreement</meta-name>
			<meta-value><xsl:value-of select="."/></meta-value>
		</custom-meta>
	</xsl:template>
	
	<!-- =============== -->
	<!-- END custom-meta -->
	<!-- =============== -->
	

	<!-- skip processed ^ attributes  and stop -->
	<xsl:template match="bibdata/ext/structuredidentifier/project-number/@part |
																status/stage/@abbreviation |
																ext/editorialgroup/technical-committee/@type |
																ext/editorialgroup/technical-committee/@number" 
																mode="front_check"/>
	
	<!-- skip processed ^ elements and stop -->
	<xsl:template match="bibdata/title[@type = 'title-intro'] |
																bibdata/title[@type = 'title-main'] |
																bibdata/title[@type = 'title-part'] |
																bibdata/title[@type = 'main'] |
																bibdata/title[@type = 'title-amd'] |
																contributor[role/@type='author']/organization/abbreviation |																
																contributor[role/@type='author']/organization/name |
																ext/structuredidentifier/project-number |
																language |
																script |
																contributor[role/@type='publisher']/organization/abbreviation |																
																contributor[role/@type='publisher']/organization/name |
																status/stage |
																status/substage |
																ext/doctype |
																ext/subdoctype |
																ext/updates-document-type |
																docnumber |
																ext/structuredidentifier/partnumber |
																edition |
																version|
																version/revision-date |
																version/draft |
																language |
																docidentifier |
																docidentifier[@type='iso-with-lang'] |
																bibdata/date |
																bibdata/copyright/owner/organization/abbreviation |
																bibdata/copyright/owner/organization/name |
																ext/editorialgroup/secretariat |
																ext/stagename|
																ext/ics/code | 
																ext/ics/text | 
																copyright/from |
																ext/structuredidentifier |
																ext/editorialgroup/agency |
																ext/editorialgroup/technical-committee |
																ext/editorialgroup/subcommittee |
																ext/editorialgroup/workgroup |
																ext/approvalgroup |
																bibdata/relation |
																bibdata/relation/bibitem |
																bibdata/relation/description |
																coverimages |
																ext/horizontal |
																ext/price-code |
																bibdata/uri |
																metanorma-extension/semantic-metadata/proj-id |
																metanorma-extension/semantic-metadata/suppl-type |
																metanorma-extension/semantic-metadata/suppl-number |
																metanorma-extension/semantic-metadata/suppl-version |
																metanorma-extension/semantic-metadata/dor |
																metanorma-extension/semantic-metadata/dow |
																metanorma-extension/semantic-metadata/dop |
																metanorma-extension/semantic-metadata/doa |
																metanorma-extension/semantic-metadata/vote-start |
																metanorma-extension/semantic-metadata/vote-end |
																metanorma-extension/semantic-metadata/wi-number |
																metanorma-extension/semantic-metadata/release-version-id |
																metanorma-extension/semantic-metadata/page-count |
																metanorma-extension/semantic-metadata/upi |
																metanorma-extension/semantic-metadata/price-ref-pages |
																metanorma-extension/semantic-metadata/published-logo |
																metanorma-extension/semantic-metadata/generation-date |
																metanorma-extension/semantic-metadata/originator-identifier |
																metanorma-extension/semantic-metadata/colour-print |
																metanorma-extension/semantic-metadata/conversion-version |
																metanorma-extension/semantic-metadata/conversion-date |
																metanorma-extension/semantic-metadata/perinorm-id |
																metanorma-extension/semantic-metadata/version-history |
																metanorma-extension/semantic-metadata/metadata-update |
																metanorma-extension/semantic-metadata/international |
																metanorma-extension/semantic-metadata/isoviennaagreement |
																metanorma-extension/semantic-metadata/copyright-statement |
																metanorma-extension/semantic-metadata/color-preface-background |
																metanorma-extension/presentation-metadata/* |
																metanorma-extension/table[@id = '_misccontainer_anchor_aliases']"
																mode="front_check"/>

	<!-- skip processed structure and deep down -->
	<xsl:template match="contributor[role/@type='author'] |
																contributor/role[@type='author'] |
																contributor[role/@type='author']/organization | 
																contributor[role/@type='publisher'] |
																contributor/role[@type='publisher'] |
																contributor[role/@type='publisher']/organization |
																bibdata/status |
																bibdata/relation |
																bibdata/copyright |
																bibdata/copyright/owner |
																bibdata/copyright/owner/organization |
																ext/editorialgroup |
																ext/ics |
																ext |
																metanorma-extension |
																semantic-metadata |
																presentation-metadata
																" mode="front_check">
		<xsl:apply-templates mode="front_check"/>
	</xsl:template>
	
	<xsl:template match="@*|node()" mode="front_check">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="front_check"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="text()" mode="front_check">
		<xsl:value-of select="."/>
	</xsl:template>
	
	
	<xsl:template match="boilerplate/copyright-statement">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="boilerplate/copyright-statement/clause" priority="1">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="boilerplate/copyright-statement//title"  priority="1">
		<copyright-statement>
			<xsl:apply-templates/>
		</copyright-statement>
	</xsl:template>
	<xsl:template match="boilerplate/copyright-statement//p"  priority="1">
		<xsl:variable name="id" select="normalize-space(@id)"/>
		<xsl:if test="$id != 'boilerplate-year' or $organization != 'BSI'">
			<copyright-statement>
				<xsl:if test="$format = 'NISO'">
					<xsl:copy-of select="@id"/>
				</xsl:if>
				<xsl:apply-templates/>
			</copyright-statement>
		</xsl:if>
	</xsl:template>
	<xsl:template match="boilerplate/copyright-statement//p//br"  priority="1">
		<xsl:choose>
			<xsl:when test="$metanorma_type = 'IEC'"><xsl:text>, </xsl:text></xsl:when>
			<xsl:otherwise><xsl:value-of select="'&#x2028;'"/><!-- linebreak --></xsl:otherwise>
		</xsl:choose>
	</xsl:template>	
	<xsl:template match="boilerplate/copyright-statement//p//text()"  priority="1">
		<xsl:value-of select="normalize-space()"/>
	</xsl:template>
		
	<xsl:template match="boilerplate/legal-statement">
		<xsl:if test="$metanorma_type = 'IEC'">
			<!-- in foreword -->
			<xsl:apply-templates/>
		</xsl:if>
		<xsl:if test="$metanorma_type != 'IEC'">
			<license specific-use="legal">
				<xsl:for-each select="clause[1]/title">
					<xsl:attribute name="xlink:title">
						<xsl:value-of select="."/>
					</xsl:attribute>
				</xsl:for-each>
				<xsl:apply-templates/>
			</license>
		</xsl:if>
	</xsl:template>
	<xsl:template match="boilerplate/legal-statement/text()[normalize-space() = '']"/>  <!-- linearization -->
	<xsl:template match="boilerplate/legal-statement/clause/title" priority="1"/>
	<xsl:template match="boilerplate/legal-statement/clause/text()[normalize-space() = '']"/>  <!-- linearization -->
	<xsl:template match="boilerplate/legal-statement/clause" priority="1">
		<xsl:if test="$metanorma_type = 'IEC'">
			<!-- in foreword -->
			<xsl:apply-templates/>
		</xsl:if>
		<xsl:if test="$metanorma_type != 'IEC'">
			<license-p>
				<xsl:if test="$format = 'NISO'">
					<xsl:attribute name="id">
						<xsl:call-template name="getId"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:apply-templates/>
			</license-p>
		</xsl:if>
	</xsl:template>	
	
	<xsl:template match="boilerplate/license-statement">
		<license>
			<xsl:for-each select="clause[1]/title">
				<xsl:attribute name="xlink:title">
					<xsl:value-of select="."/>
				</xsl:attribute>
			</xsl:for-each>
			<xsl:apply-templates/>
		</license>	
	</xsl:template>
	<xsl:template match="boilerplate/license-statement/clause/title" priority="1"/>
	<xsl:template match="boilerplate/license-statement/clause" priority="1">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="boilerplate/license-statement//p" priority="1">
		<license-p>
			<xsl:if test="$format = 'NISO'">
				<xsl:attribute name="id">
					<xsl:value-of select="@id"/>					
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
		</license-p>
	</xsl:template>
	
	<xsl:template match="preface/abstract" priority="2" mode="front_preface"/>
	<xsl:template match="preface/abstract" mode="front_abstract">
		<xsl:copy>
			<xsl:copy-of select="@*[not(local-name() = 'section' or local-name() = 'section_prefix')]"/>
			<xsl:apply-templates />
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="preface/acknowledgements" mode="front_preface" priority="2">
		<xsl:call-template name="preface_node"/> <!-- see below -->
	</xsl:template>
	
	<xsl:template match="preface/*[not(self::abstract or @type = 'section-title' or self::section-title)]" mode="front_preface" name="preface_node">
		<xsl:param name="skipIntroduction">true</xsl:param>
		<xsl:variable name="name" select="local-name()"/>
		<xsl:variable name="title">
			<xsl:apply-templates select="title"/>
		</xsl:variable>
		<xsl:variable name="title_text" select="normalize-space(java:toLowerCase(java:java.lang.String.new($title)))"/>
		<xsl:choose>
			<!-- For BSI, Introduction section placed in body -->
			<xsl:when test="$skipIntroduction = 'true' and $name = 'introduction' and $nat_meta_only = 'true'"></xsl:when> <!-- $organization = 'BSI' -->
			<xsl:otherwise>
				<xsl:variable name="sec_type">
					<xsl:choose>
						<xsl:when test="@type"><xsl:value-of select="@type"/></xsl:when>
						<xsl:when test="$name = 'introduction' or
														$title_text = 'introduction' or
														$title_text = 'introducción' or
														$title_text = 'введение'">intro</xsl:when>
						<xsl:when test="$name = 'foreword' or 
														$title_text = 'foreword' or
														$title_text = 'avant-propos' or
														$title_text = 'prólogo' or
														$title_text = 'prólogo de la versión en español' or
														$title_text = 'предисловие'">foreword</xsl:when>
						<!-- <xsl:when test="not(preceding-sibling::*) and $name != 'foreword'">titlepage</xsl:when> -->
						<xsl:otherwise>sec_<xsl:value-of select="$name"/></xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				
				<sec>
					<xsl:attribute name="id">
						<xsl:choose>
							<xsl:when test="@id"><xsl:value-of select="@id"/></xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$sec_type"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					
					<xsl:if test="$outputformat != 'IEEE'">
						<xsl:attribute name="sec-type"><xsl:value-of select="$sec_type"/></xsl:attribute>
					
						<xsl:variable name="section" select="normalize-space(@section)"/>
						<xsl:if test="$section != ''">
							<xsl:call-template name="insert_label">
								<xsl:with-param name="label" select="@section"/>
								<xsl:with-param name="isAddition" select="count(title/node()[normalize-space() != ''][1][self::add]) = 1"/>
							</xsl:call-template>
						</xsl:if>
					</xsl:if>
					
					<!-- <xsl:apply-templates select="title"/> -->
					<xsl:copy-of select="$title"/>
					
					<xsl:if test="$metanorma_type = 'IEC' and $name = 'foreword'">
						<!-- put legal-statement in Foreword -->
						<xsl:apply-templates select="/*/boilerplate/legal-statement"/>
					</xsl:if>
					
					<xsl:apply-templates select="node()[not(self::title)]"/>
					
				</sec>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="preface//*[@type = 'section-title' or local-name() = 'section-title']" mode="front_preface">
		<xsl:apply-templates select="." mode="section-title"/>
	</xsl:template>
	
	<xsl:variable name="annex_not_integral_part_text">(This annex does not form an integral part </xsl:variable>
  
	<xsl:template match="annex" mode="back">
		
		<xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable>
		
		<app>
			<xsl:if test="not($outputformat = 'IEEE' and starts-with(@id,'_'))">
				<xsl:attribute name="id">
					<xsl:value-of select="$id"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="$outputformat = 'IEEE' and references">
				<xsl:copy-of select="references/@id"/>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="$outputformat = 'IEEE'">
					<xsl:attribute name="normative">no</xsl:attribute>
					<xsl:if test="normalize-space(@obligation) != ''">
						<xsl:attribute name="normative">
							<xsl:choose>
								<xsl:when test="@obligation  = 'informative'">no</xsl:when>
								<xsl:otherwise>yes</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
					</xsl:if>
				</xsl:when>
				
				<xsl:when test="$metanorma_type = 'IEC' or $metanorma_type = 'ISO' or $organization = 'BSI'">
					<xsl:choose>
						<!-- title contains '(This annex does not form an integral part of this Recommendation | International Standard)' -->
						<xsl:when test="title//text()[contains(., $annex_not_integral_part_text)]"><!-- no indication of "informative" or "normative" in --></xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="$metanorma_type = 'IEC'">
									<xsl:attribute name="content-type">
										<xsl:choose>
											<xsl:when test="@obligation  = 'informative'">informative</xsl:when>
											<xsl:when test="@obligation  = 'normative'">normative</xsl:when>
											<xsl:otherwise>normative</xsl:otherwise>
										</xsl:choose>
									</xsl:attribute>
								</xsl:when>
								<xsl:when test="$metanorma_type = 'ISO' or $organization = 'BSI'">
									<xsl:attribute name="content-type">
										<xsl:choose>
											<xsl:when test="@obligation  = 'informative'">inform-annex</xsl:when>
											<xsl:when test="@obligation  = 'normative'">normative-annex</xsl:when>
											<xsl:otherwise>normative-annex</xsl:otherwise>
										</xsl:choose>
									</xsl:attribute>
								</xsl:when>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				
				<xsl:otherwise>
				
					<xsl:attribute name="content-type">inform-annex</xsl:attribute>
					<xsl:if test="normalize-space(@obligation) != ''">
						<xsl:attribute name="content-type">
							<xsl:choose>
								<xsl:when test="@obligation  = 'informative'">inform-annex</xsl:when>
								<xsl:otherwise><xsl:value-of select="@obligation"/></xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:call-template name="addSectionAttribute"/>
			
			<label>
				<xsl:choose>
					<xsl:when test="ancestor::amend/autonumber[@type = 'annex']">
						<xsl:value-of select="ancestor::amend/autonumber[@type = 'annex']/text()"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="@section_prefix"/><xsl:value-of select="@section"/>
					</xsl:otherwise>
				</xsl:choose>
			</label>
			<xsl:choose>
				<xsl:when test="$outputformat = 'IEEE'">
					<annex-type>
						<xsl:text>(</xsl:text>
						<xsl:value-of select="@obligation"/>
						<xsl:if test="normalize-space(@obligation) = ''">
							<xsl:text>informative</xsl:text>
						</xsl:if>
						<xsl:text>)</xsl:text>
					</annex-type>
				</xsl:when>
				<xsl:when test="$metanorma_type = 'ISO'">
					<annex-type>
						<xsl:text>(</xsl:text>
						<xsl:value-of select="@obligation"/>
						<xsl:if test="normalize-space(@obligation) = ''">
							<xsl:text>normative</xsl:text>
						</xsl:if>
						<xsl:text>)</xsl:text>
					</annex-type>
				</xsl:when>
				<xsl:when test="$metanorma_type = 'IEC'"><!-- no need <annex-type> --></xsl:when>
				<xsl:otherwise>
					<xsl:if test="normalize-space(@obligation) != ''">
						<annex-type>(<xsl:value-of select="@obligation"/>)</annex-type>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
			
			<xsl:apply-templates />
			
		</app>
	</xsl:template>
	
	
	<xsl:template match="bibliography/references[not(@normative='true')]" mode="back">
		<ref-list content-type="bibl">
			<xsl:attribute name="id">
				<xsl:text>sec_bibl</xsl:text>
				<xsl:if test="count(//references[not(@normative='true')]) &gt; 1">
					<xsl:number format="_1" count="references[not(@normative='true')]"/>
				</xsl:if>
			</xsl:attribute>
			<xsl:copy-of select="@id"/>
			<!-- <xsl:apply-templates select="*[local-name() = 'title'][1]" mode="back"/> -->
			
			<xsl:apply-templates/>
			
			<!-- <xsl:choose>
				<xsl:when test="*[local-name() = 'title'][2]">
					<ref-list>
						<xsl:apply-templates select="*[local-name() = 'title'][2]" mode="back"/>
						<xsl:apply-templates/>
					</ref-list>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates/>
				</xsl:otherwise>
			</xsl:choose> -->
		</ref-list>
	</xsl:template>
	
	<xsl:template match="annex/references[not(@normative='true')]">
		<xsl:apply-templates select="p"/> <!-- put p before ref-list in app/ref-list structure -->
		<ref-list>
			<xsl:apply-templates select="*[not(self::p or self::title)]"/>
		</ref-list>
	</xsl:template>
	
	<!-- <xsl:template match="*[local-name() = 'bibliography']/*[local-name() = 'references'][not(@normative='true')]/*[local-name() = 'title']" priority="2"/>
	<xsl:template match="*[local-name() = 'bibliography']/*[local-name() = 'references'][not(@normative='true')]/*[local-name() = 'title']" mode="back">
		<title><xsl:apply-templates /></title>
	</xsl:template> -->
	
	<xsl:template match="bibliography/references[not(@normative='true')]/title">
		<title><xsl:apply-templates /></title>
	</xsl:template>
	
	<xsl:template match="bibliography/clause[references[not(@normative='true')]]" mode="back">
		<ref-list content-type="bibl">
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates/>
		</ref-list>
	</xsl:template>
	
	<xsl:template match="bibliography/clause/references[not(@normative='true')]">
		<ref-list>
			<xsl:choose>
				<xsl:when test="$metanorma_type = 'IEC' or $metanorma_type = 'ISO'">
					<xsl:attribute name="content-type">bibl</xsl:attribute>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="@id"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:apply-templates/>
		</ref-list>
	</xsl:template>
	
	
	<xsl:template match="bibitem[starts-with(@id, 'hidden_bibitem_')] | bibitem[@hidden = 'true']" priority="3"/>
	
	<xsl:template match="bibitem[1][ancestor::references[@normative='true']]" priority="2">
		<xsl:choose>
			<xsl:when test="$outputformat = 'IEEE'">
				<list>
					<xsl:attribute name="list-content">normative-references</xsl:attribute>
					<xsl:attribute name="list-type">simple</xsl:attribute>
					<xsl:for-each select="../bibitem">
						<xsl:call-template name="bibitem_norm_ref_IEEE"/>
					</xsl:for-each>
				</list>
			</xsl:when>
			<xsl:otherwise>
				<ref-list content-type="norm-refs">
					<xsl:for-each select="../bibitem">
						<xsl:call-template name="bibitem"/>
					</xsl:for-each>
				</ref-list>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="bibitem[position() &gt; 1][ancestor::references[@normative='true']]" priority="2"/>
	
	<xsl:variable name="count_non_normative_references" select="count($xml//references[not(@normative='true')])"/>
	
	<xsl:template match="bibitem" name="bibitem">
		<!-- <xsl:variable name="current_id">
			<xsl:call-template name="getId"/>
		</xsl:variable>
		<xsl:variable name="id" select="$elements//element[@source_id = $current_id]/@id"/> -->
		<xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable>
		<ref>
			<xsl:if test="normalize-space(@type) != ''">
				<xsl:attribute name="content-type">
					<xsl:value-of select="@type"/>
				</xsl:attribute>
			</xsl:if>
			
			<!-- <xsl:attribute name="id"><xsl:value-of select="$id"/>
				<xsl:if test="$count_non_normative_references &gt; 1">
					<xsl:number format="_1" count="*[local-name() = 'references'][not(@normative='true')]"/>
				</xsl:if>
			</xsl:attribute> -->
			<xsl:copy-of select="@id"/>
			
			<xsl:call-template name="addSectionAttribute"/>
			
			<xsl:apply-templates select="docidentifier[@type = 'metanorma']" mode="docidentifier_metanorma"/>
			<xsl:if test="not(docidentifier[@type='metanorma'])">
				<!-- <label><xsl:number format="[1]"/></label> --> <!-- see docidentifier @type="metanorma" -->
			</xsl:if>
						
			<xsl:choose>
				<xsl:when test="count(*) = 2 and docidentifier[@type='metanorma'] and title">
					<xsl:apply-templates select="docidentifier"/>
					<xsl:apply-templates select="title" mode="mixed_citation"/>
				</xsl:when>
				<xsl:when test="(@type = 'standard' or @type = 'international-standard' or docnumber or fetched) and $outputformat != 'IEEE'">
					<std>
						<xsl:variable name="urn" select="docidentifier[@type = 'URN']"/>
						<xsl:variable name="docidentifier_URN" select="$bibitems_URN/bibitem[@id = $id]/urn"/>
						
						<!-- Example of resulted xml: <std-id std-id-link-type="urn" std-id-type="undated">urn:iec:std:iec:62391-1::::</std-id>
						  <std-ref>IEC&#160;62391&#8211;1</std-ref> -->
						
						<xsl:if test="$metanorma_type = 'IEC'">
							<xsl:variable name="docidentifier" select="docidentifier[not(@type = 'metanorma' or @type = 'metanorma-ordinal' or @type = 'URN')][1]"/>
							<std-id>
								<xsl:attribute name="std-id-link-type">
									<xsl:choose>
										<xsl:when test="$docidentifier_URN != ''">urn</xsl:when>
										<xsl:otherwise>internal-pub-id</xsl:otherwise>
									</xsl:choose>
								</xsl:attribute>
								<xsl:attribute name="std-id-type">
									<xsl:variable name="value">
										<xsl:choose>
											<xsl:when test="$docidentifier_URN != ''"><xsl:value-of select="$docidentifier_URN"/></xsl:when>
											<xsl:otherwise><xsl:value-of select="$docidentifier"/></xsl:otherwise>
										</xsl:choose>
									</xsl:variable>
									<xsl:call-template name="setDatedUndatedType">
										<xsl:with-param name="value" select="$value"/>
									</xsl:call-template>
								</xsl:attribute>
								<xsl:choose>
									<xsl:when test="$docidentifier_URN != ''">
										<xsl:value-of select="$docidentifier_URN"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$docidentifier"/>
									</xsl:otherwise>
								</xsl:choose>
							</std-id>
						</xsl:if>
						
						<xsl:if test="$metanorma_type != 'IEC'">
							<xsl:choose>
								<xsl:when test="$docidentifier_URN != ''">
									<xsl:attribute name="std-id">
										<xsl:value-of select="$docidentifier_URN"/>
									</xsl:attribute>
								</xsl:when>
								<xsl:when test="normalize-space($urn) != ''">
									<xsl:attribute name="std-id"><xsl:value-of select="$urn"/></xsl:attribute>
								</xsl:when>
							</xsl:choose>
							
							<xsl:if test="eref/@citeas">
								<xsl:attribute name="type">
									<xsl:call-template name="setDatedUndatedType">
										<xsl:with-param name="value" select="eref/@citeas"/>
									</xsl:call-template>
								</xsl:attribute>
							</xsl:if>
						</xsl:if>
						
						<xsl:if test="docidentifier[not(@type = 'metanorma' or @type = 'metanorma-ordinal' or @type = 'URN')]">
							<std-ref><xsl:value-of select="docidentifier[not(@type = 'metanorma' or @type = 'metanorma-ordinal' or @type = 'URN')]"/></std-ref>
						</xsl:if>
						
						<xsl:choose>
							<xsl:when test="note or title[(@type = 'main' and @language = 'en') or not(@type and @language)] or formattedref">
								<xsl:apply-templates select="note"/>				
								<xsl:apply-templates select="title[(@type = 'main' and @language = 'en') or not(@type and @language)]"/>				
								<xsl:apply-templates select="formattedref"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:apply-templates />
							</xsl:otherwise>
						</xsl:choose>
					</std>
				</xsl:when>
				<xsl:when test="$outputformat = 'IEEE'">
					<!-- <xsl:choose>
						<xsl:when test="@type = 'standard'">
							<xsl:apply-templates select="." mode="IEEE"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates select="formattedref" mode="IEEE"/>
							<xsl:apply-templates select="formattedref/node()[self::fn or self::xref]"/>
						</xsl:otherwise>
					</xsl:choose> -->
					<xsl:choose>
						<xsl:when test="@type and @type != 'standard'">
							<xsl:apply-templates select="." mode="IEEE_non_standard"/>
						</xsl:when>
						<xsl:when test="formattedref">
							<xsl:apply-templates select="formattedref" mode="IEEE"/>
							<xsl:apply-templates select="formattedref/node()[self::fn or self::xref]"/>
						</xsl:when>
						<!-- <xsl:when test="$bibitem_URN/@type = 'standard'">
							<xsl:apply-templates select="." mode="IEEE"/>
						</xsl:when> -->
						<xsl:otherwise>
							<xsl:apply-templates select="." mode="IEEE"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise> <!-- reference to non-standard (article, book, etc. ) -->
					<mixed-citation>
						<xsl:apply-templates />
					</mixed-citation>
				</xsl:otherwise>
			</xsl:choose>
			
		</ref>

	</xsl:template>
	
	<xsl:template name="bibitem_norm_ref_IEEE">
		<xsl:variable name="bibitem_URN_" select="$bibitems_URN/bibitem[@id = current()/@id]"/>
		<xsl:variable name="bibitem_URN" select="xalan:nodeset($bibitem_URN_)"/>
		<list-item>
			<xsl:copy-of select="@id"/>
			<p>
				<xsl:choose>
					<xsl:when test="formattedref">
						<xsl:apply-templates select="formattedref" mode="IEEE"/>
						<xsl:apply-templates select="formattedref/node()[self::fn or self::xref]"/>
					</xsl:when>
					<!-- <xsl:when test="$bibitem_URN/@type = 'standard'">
						<xsl:apply-templates select="." mode="IEEE"/>
					</xsl:when> -->
					<xsl:otherwise>
						<xsl:apply-templates select="." mode="IEEE"/>
					</xsl:otherwise>
				</xsl:choose>
			</p>
		</list-item>
	</xsl:template>
	
	
	<xsl:template match="bibitem/formattedref" mode="IEEE">
		<xsl:variable name="curr_id" select="../@id"/>
		<xsl:variable name="bibitem_URN_" select="$bibitems_URN/bibitem[@id = $curr_id]"/>
		<xsl:variable name="bibitem_URN" select="xalan:nodeset($bibitem_URN_)"/>
		<mixed-citation publication-format="print">
			<xsl:choose>
				<xsl:when test="$bibitem_URN/@type = 'standard'">
					<xsl:attribute name="publication-type">standard</xsl:attribute>
					<xsl:call-template name="insert_std_IEEE">
						<xsl:with-param name="bibitem_URN" select="$bibitem_URN"/>
						<xsl:with-param name="is_bibitem" select="'true'"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise> <!-- non-standard -->
					<source>
						<xsl:apply-templates select="node()[not(self::xref or self::fn or self::text()[preceding-sibling::*[1][self::fn]])]"/>
					</source>
				</xsl:otherwise>
			</xsl:choose>
		</mixed-citation>
	</xsl:template>
	
	<xsl:template match="bibitem" mode="IEEE">
		<mixed-citation publication-format="print" publication-type="standard">
			<std>
				<xsl:variable name="docidentifier" select="docidentifier[@primary='true']"/>
				<xsl:variable name="organization">
					<xsl:call-template name="get_organization">
						<xsl:with-param name="docidentifier" select="$docidentifier"/>
					</xsl:call-template>
				</xsl:variable>
				
				<xsl:variable name="pub-id_full" select="normalize-space(substring-after($docidentifier, $organization))"/> <!-- docidentifier[@type = 'IEEE' and @scope = 'trademark'] -->
				<xsl:variable name="pub-id" select="java:replaceAll(java:java.lang.String.new($pub-id_full),$regex_pub-id-year,'$1')"/> <!-- number without year -->
				<xsl:variable name="year" select="java:replaceAll(java:java.lang.String.new($pub-id_full),$regex_pub-id-year,'$2')"/>
				
				<std-organization><xsl:value-of select="$organization"/></std-organization> Std	
				<pub-id><xsl:value-of select="$pub-id"/></pub-id>
				<xsl:value-of select="$trademark"/>
				<xsl:if test="$year != '' and $year != $pub-id">-<year><xsl:value-of select="$year"/></year></xsl:if>
				<source specific-use="IEEE"><xsl:apply-templates select="title/node()"/></source>
			</std>.
		</mixed-citation>
	</xsl:template>
	
	<xsl:template match="references/bibitem/*[self::docidentifier or self::docnumber or self::date or self::contributor or self::edition or self::language or self::script or self::copyright or self::relation]" priority="2">
		<xsl:text disable-output-escaping="yes">&lt;!--</xsl:text>
			<xsl:copy-of select="."/>
		<xsl:text disable-output-escaping="yes">--&gt;</xsl:text>
	</xsl:template>
	
	<xsl:template match="bibitem/title" priority="2">	
		<xsl:if test="$metanorma_type != 'IEC'">
			<xsl:text>, </xsl:text>
		</xsl:if>
		<title><xsl:apply-templates/></title>
	</xsl:template>
	
	<xsl:template match="bibitem/title" mode="mixed_citation">
		<mixed-citation><xsl:apply-templates/></mixed-citation>
	</xsl:template>
	
	<xsl:template match="bibitem[not(@type = 'standard' or @type = 'international-standard') and not(docnumber)]/formattedref" priority="2">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="bibitem[not(@type = 'standard' or @type = 'international-standard') and not(docnumber)]/text()[normalize-space() = '']" priority="2"/> <!-- linearization -->
	<xsl:template match="bibitem/formattedref">
		<title><xsl:apply-templates/></title>
	</xsl:template>
	
	<xsl:template match="bibitem/docidentifier[@type = 'metanorma']" mode="docidentifier_metanorma">
		<label><xsl:apply-templates /></label>
	</xsl:template>
	
	<xsl:template match="bibitem/docidentifier[@type = 'metanorma']" priority="3"/>
	<xsl:template match="bibitem/docidentifier[@type = 'metanorma-ordinal']" priority="3"/>
	<xsl:template match="bibitem/docidentifier[@type = 'URN']" priority="3"/>
	
	<xsl:template match="formattedref/em" priority="2">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="bibitem/eref" priority="2">
		<xsl:variable name="reference" select="@bibitemid"/>
		<xsl:variable name="docidentifier_URN" select="//bibitem[@id = $reference]/docidentifier[@type = 'URN']"/>
		<xsl:if test="$docidentifier_URN != ''">
			<xsl:attribute name="std-id">
				<xsl:value-of select="$docidentifier_URN"/>
			</xsl:attribute>
		</xsl:if>
		<std-ref><xsl:value-of select="java:replaceAll(java:java.lang.String.new(@citeas),'--','—')"/></std-ref>
		<xsl:apply-templates select="localityStack"/>
		<xsl:apply-templates />
	</xsl:template>
	
	<!-- 'bibitem/note' converts to 'ref//fn' -->
	<xsl:template match="bibitem/note" priority="2">
		<xsl:variable name="number">
			<xsl:number level="any" count="bibitem/note"/>
		</xsl:variable>
		
		<xsl:variable name="xref_fn">
			<!-- 'footnote' is special wrapper for further processing in mode="footnotes_fix" -->
			<footnote id="{generate-id()}">
				<xref ref-type="fn" rid="fn_{$number}">
					<sup><xsl:value-of select="$number"/></sup>
				</xref>
				<fn id="fn_{$number}">
					<label>
						<sup><xsl:value-of select="$number"/></sup>
					</label>
					<xsl:choose>
						<xsl:when test="p">
							<xsl:apply-templates/>
						</xsl:when>
						<xsl:otherwise>
							<p><xsl:apply-templates/></p>
						</xsl:otherwise>
					</xsl:choose>
				</fn>
			</footnote>
		</xsl:variable>

		<xsl:copy-of select="$xref_fn"/>
		
	</xsl:template>
	
	<xsl:template match="bibitem/fetched"/>
	
	<xsl:template match="bibitem/uri/@type">
		<xsl:attribute name="content-type"><xsl:value-of select="."/></xsl:attribute>
	</xsl:template>

	
	<xsl:template match="fn" priority="2">
		<xsl:variable name="number" select="@reference"/>
		<xsl:variable name="number_id">
			<xsl:value-of select="$number"/>_<xsl:number level="any" count="fn"/>
		</xsl:variable>
		<xsl:variable name="sfx">
			<xsl:if test="ancestor::table"><xsl:value-of select="ancestor::table[1]/@id"/>_</xsl:if>
		</xsl:variable>
		<xsl:variable name="xref_fn">
			<!-- 'footnote' is special wrapper for further processing in mode="footnotes_fix" -->
			<footnote id="{generate-id()}">
				<xref ref-type="fn" rid="fn_{$number_id}"> <!-- {$sfx} rid="fn_{$number}" -->
					<sup><xsl:value-of select="$number"/><xsl:if test="$outputformat != 'IEEE'">)</xsl:if></sup>
				</xref>
				<fn id="fn_{$number_id}"> <!-- {$sfx} -->
					<label>
						<sup><xsl:value-of select="$number"/><xsl:if test="$outputformat != 'IEEE'">)</xsl:if></sup>
					</label>
					<xsl:apply-templates/>
				</fn>
			</footnote>
		</xsl:variable>
		
		<xsl:choose>		
			<xsl:when test="preceding-sibling::*[1][self::image]">
				<!-- enclose in 'p' -->
				<p>
					<xsl:copy-of select="$xref_fn"/>
				</p>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$xref_fn"/>
			</xsl:otherwise>
		</xsl:choose>		
		
	</xsl:template>
	
	
	<xsl:template match="fn/text()" priority="2">
		<xsl:if test="normalize-space(.) != ''">
			<p><xsl:value-of select="."/></p>
		</xsl:if>
	</xsl:template>
	
	
	<xsl:template match="clause | 
																references[@normative='true'] | 
																terms |
																definitions">
		<xsl:param name="processFloatingTitle">false</xsl:param>
		<xsl:if test="normalize-space($debug) = 'true'">
			<xsl:message>DEBUG: <xsl:value-of select="local-name()"/><xsl:text> processing </xsl:text>
				<xsl:choose>
					<xsl:when test="local-name() = 'clause'">
						<xsl:number level="any" count="clause"/>
					</xsl:when>
					<xsl:when test="local-name() = 'references'">
						<xsl:number level="any" count="references"/>
					</xsl:when>
					<xsl:when test="local-name() = 'terms'">
						<xsl:number level="any" count="terms"/>
					</xsl:when>
					<xsl:when test="local-name() = 'definitions'">
						<xsl:number level="any" count="definitions"/>
					</xsl:when>
				</xsl:choose>
			</xsl:message>
		</xsl:if>
	
		<xsl:variable name="title">
			<xsl:apply-templates select="title"/>
		</xsl:variable>
		<xsl:variable name="title_text" select="normalize-space(java:toLowerCase(java:java.lang.String.new($title)))"/>
	
		<xsl:variable name="sec_type">
			<xsl:choose>
				<xsl:when test="@type='scope' or
									$title_text = 'scope' or
									$title_text = &quot;omaine d&apos;applicatione&quot; or
									$title_text = 'objeto y campo de aplicación' or
									$title_text = 'область применения'">scope</xsl:when>
				<xsl:when test="@type='intro' or
												$title_text = 'introduction' or
												$title_text = 'introducción' or
												$title_text = 'введение'">intro</xsl:when>
				<xsl:when test="@normative='true' or
									$title_text = 'normative references' or
									$title_text = 'références normatives' or
									$title_text = 'referencias normativas' or
									$title_text = 'нормативные ссылки'">norm-refs</xsl:when>
				<xsl:when test="@id = 'tda' or @id = 'terms' or self::terms or (contains(title[1], 'Terms') and not(ancestor::clause)) or
									$title_text = 'terms and definitions' or
									starts-with($title_text, 'terms, definitions') or
									$title_text = 'termes et definitions' or 
									starts-with($title_text, 'termes, définitions') or
									$title_text = 'тérminos y definiciones' or
									$title_text = 'термины и определения'">terms</xsl:when>
				<xsl:when test="ancestor::foreword"><xsl:value-of select="@type"/></xsl:when>
				<xsl:otherwise><!-- <xsl:value-of select="@id"/> --></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
	
		<xsl:variable name="current_id">
			<xsl:call-template name="getId"/>
		</xsl:variable>
		
		<xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable>
		
		<xsl:variable name="section" select="@section"/>
		
		<xsl:choose>
			<xsl:when test="$processFloatingTitle = 'false' and preceding-sibling::p[1][@type = 'floating-title']"><!-- skip processing, see template for 'p' --></xsl:when> <!--  or @type = 'section-title' -->
			<xsl:otherwise>
				<sec id="{$id}">
					<xsl:call-template name="addSectionAttribute"/>
					<xsl:if test="normalize-space($sec_type) != ''">
						<xsl:if test="$outputformat != 'IEEE'">
							<xsl:attribute name="sec-type">
								<xsl:value-of select="$sec_type"/>
							</xsl:attribute>
						</xsl:if>
					</xsl:if>
					<xsl:choose>
						<xsl:when test="ancestor::foreword"></xsl:when>
						<xsl:otherwise>
						
							<xsl:call-template name="insert_label">
								<xsl:with-param name="label" select="$section"/>
								<xsl:with-param name="isAddition" select="count(title/node()[normalize-space() != ''][1][self::add]) = 1"/>
								<xsl:with-param name="isEmptyLabel" select="@empty_label"/>
							</xsl:call-template>
						
						</xsl:otherwise>
					</xsl:choose>
					
					<!-- <xsl:apply-templates select="title"/> -->
					<xsl:copy-of select="$title"/>
					
					<xsl:if test="@change">
						<editing-instruction>
							<p>
								<italic>
									<xsl:choose>
										<xsl:when test="@change = 'add'">Addition</xsl:when>
										<xsl:when test="@change = 'modify'">Replacement</xsl:when>
										<xsl:when test="@change = 'delete'">Deletion</xsl:when>
										<xsl:otherwise><xsl:value-of select="@change"/></xsl:otherwise>
									</xsl:choose>
								<xsl:text>:</xsl:text>
								</italic>
							</p>
						</editing-instruction>
					</xsl:if>
					
					<xsl:apply-templates select="node()[not(self::title)]"/>
					
				</sec>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>


	<xsl:template match="term/text()">
		<xsl:value-of select="normalize-space()"/>
	</xsl:template>

	
	<xsl:template match="term/ul | term/ol" />
	<xsl:template match="term/ul" mode="definition_list">
		<xsl:call-template name="ul"/>
	</xsl:template>
	<xsl:template match="term/ol" mode="definition_list">
		<xsl:call-template name="ol"/>
	</xsl:template>

	<xsl:template match="verbaldefinition | verbal-definition | nonverbalrepresentation | non-verbal-representation">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="letter-symbol">
		<xsl:apply-templates />
	</xsl:template>

	<xsl:template match="definition/text()[1] |
																termexample/text()[1] | 
																termnote/text()[1] |
																termsource/text()[1] |
																modification/text()[1] |
																dd/text()[1] |
																formattedref/text()[1]">
		<xsl:value-of select="normalize-space()"/>
	</xsl:template>
	
	<xsl:template match="termnote"> <!--  mode="termEntry" -->
		<xsl:choose>
			<xsl:when test="$outputformat = 'IEEE'">
				 <xsl:call-template name="note"/>
			</xsl:when>
			<xsl:otherwise>
				
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- remove '[SOURCE:'   and ']' -->
	<xsl:template match="termsource/text()[starts-with(., '[SOURCE: ')]">
		<xsl:value-of select="substring-after(., '[SOURCE: ')"/>
	</xsl:template>
	<xsl:template match="termsource/text()[last()][normalize-space() = ']']"/>
	
	<xsl:template match="origin">
		<xsl:choose>
			<xsl:when test="$bibitems_URN/bibitem[@id = current()/@bibitemid][@type = 'standard'  or @type = 'international-standard']">
				<xsl:call-template name="eref"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="xref"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:variable name="regex_locality">^(locality:)?(.*)$</xsl:variable>
	<xsl:template match="localityStack">
		<xsl:text>, </xsl:text>
		<xsl:for-each select="locality">
			<xsl:variable name="type_" select="java:replaceAll(java:java.lang.String.new(@type),$regex_locality,'$2')"/>
			<xsl:variable name="type">
				<xsl:call-template name="capitalize">
					<xsl:with-param name="str" select="$type_"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:if test="$type != ''">
				<xsl:value-of select="$type"/>
				<xsl:text> </xsl:text>
			</xsl:if>
			<xsl:value-of select="referenceFrom"/>
			<xsl:if test="position() != last()">; </xsl:if>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="modification">
		<xsl:text>, modified</xsl:text>
		<xsl:variable name="modification_text">
			<xsl:apply-templates />
		</xsl:variable>
		<xsl:if test="normalize-space($modification_text) != ''">
			<xsl:text> — </xsl:text>
			<xsl:copy-of select="$modification_text"/>
		</xsl:if>
	</xsl:template>
	<xsl:template match="modification/text()[normalize-space() = '']"/> <!-- linearization -->
	
	<!-- <xsl:template match="*[local-name() = 'termexample'] | *[local-name() = 'termnote'] | *[local-name() = 'termsource']"/> -->
	
	<!-- temporary solution for https://github.com/metanorma/iso-10303-2/issues/44 -->
	<xsl:template match="clause/domain | clause/termsource" priority="2">
		<xsl:text disable-output-escaping="yes">&lt;!--</xsl:text>
			<xsl:copy-of select="."/>
		<xsl:text disable-output-escaping="yes">--&gt;</xsl:text>
	</xsl:template>
	

	
	<xsl:template match="grammar | grammar/* | grammar/*/text() | expression | expression/name | letter-symbol | letter-symbol/name" priority="2">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="*[self::expression or self::letter-symbol or self::preferred or self::admitted or self::deprecates or self::domain]/text()[normalize-space() = ''] | expression/name/text()[normalize-space() = '']" priority="2"/>
	
	<xsl:template match="field-of-application" priority="2"/>
	
	
	<xsl:template match="p" name="p">
		<!-- <xsl:if test="$debug = 'true'">
			<xsl:message>DEBUG: p processing <xsl:number level="any" count="*[local-name() = 'p']"/></xsl:message>
		</xsl:if> -->
		<xsl:variable name="paragraph_">
			<xsl:variable name="parent_name" select="local-name(..)"/>
			<xsl:choose>
				<!-- <xsl:when test="parent::*[local-name() = 'termexample'] or 
															parent::*[local-name() = 'definition']  or 
															parent::*[local-name() = 'termnote'] or 
															parent::*[local-name() = 'modification'] or
															parent::*[local-name() = 'dd']">
					<xsl:apply-templates />
				</xsl:when> -->
				<xsl:when test="$parent_name = 'termexample' or 
															$parent_name = 'definition'  or 
															$parent_name = 'verbaldefinition'  or 
															$parent_name = 'verbal-definition'  or 
															$parent_name = 'termnote' or 
															$parent_name = 'modification' or
															$parent_name = 'dd'">
					<xsl:if test="preceding-sibling::*[1][self::p]"><break /></xsl:if>
					<xsl:apply-templates />
				</xsl:when>
				<xsl:when test="@type = 'floating-title'">
					<!-- create parent element with floating title, for nested clauses (sec) -->
					<sec>
						<xsl:copy-of select="@id"/>
						<title><xsl:apply-templates /></title>
						<xsl:apply-templates select="following-sibling::*[preceding-sibling::p[1][@type = 'floating-title']]">
							<xsl:with-param name="processFloatingTitle">true</xsl:with-param>
						</xsl:apply-templates>
					</sec>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="parent::li and (ancestor::note or ancestor::termnote) and $color-title != ''"> <!-- for PAS, list item text in the note -->
							<p>
								<italic>
									<styled-content style="color:{$color-title};">
										<xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
										<xsl:apply-templates />
									</styled-content>
								</italic>
							</p>
						</xsl:when>
						<xsl:otherwise>
							<p>
								<xsl:if test="not($organization = 'BSI' or $metanorma_type = 'ISO')">
									<xsl:copy-of select="@id"/>
								</xsl:if>
								<xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
								<xsl:apply-templates />
							</p>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="paragraph" select="xalan:nodeset($paragraph_)"/>
		<xsl:choose>
			<xsl:when test="($metanorma_type = 'IEC' or $metanorma_type = 'ISO') and $paragraph/p/list"> <!-- move list(s) outside of p -->
				<xsl:for-each select="$paragraph/p/list">
					<xsl:variable name="curr_list_id" select="generate-id()"/>
					<p>
						<xsl:copy-of select="../@*"/>
						<xsl:copy-of select="preceding-sibling::node()[not(self::list) and following-sibling::list[1][generate-id() = $curr_list_id]]"/>
					</p>
					<xsl:copy-of select="."/>
					<xsl:if test="not(following-sibling::list) and following-sibling::node()[normalize-space() != '']"> <!-- current list is last and there are next elements in paragraph -->
						<p>
							<xsl:copy-of select="../@*"/>
							<xsl:copy-of select="following-sibling::node()"/>
						</p>
					</xsl:if>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$paragraph"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="sections//*[@type = 'section-title' or local-name() = 'section-title']" priority="2">
		<xsl:apply-templates select="." mode="section-title"/>
	</xsl:template>
	
	<!-- Examples:
	 in semantic metanorma xml: <section-title id="section_1" depth="1" type="floating-title">General</section-title>
	 in presentation metanorma xml: <p id="section_1" depth="1" type="section-title" displayorder="3">Section 1<tab/>General</p> -->
	<xsl:template match="*[@type = 'section-title' or local-name() = 'section-title']" mode="section-title">
		<sec sec-type="section-title">
			<xsl:copy-of select="@id"/>
			<title>
				<xsl:if test="$isSemanticXML = 'true'">
					<!-- Example: Section 2: -->
					<xsl:value-of select="@section_prefix"/>
					<xsl:value-of select="@section"/>
					<xsl:text>: </xsl:text>
				</xsl:if>
				<xsl:apply-templates />
			</title>
		</sec>
	</xsl:template>
	
	
	<xsl:template match="p/@align[. = 'indent']" priority="2">
		<xsl:attribute name="specific-use"><xsl:value-of select="."/></xsl:attribute>
	</xsl:template>
	
	<xsl:template match="p/@align[. = 'left']" priority="2"/>
	
	<xsl:template match="p/@align">
		<xsl:choose>
			<xsl:when test=". = 'center'">
				<xsl:attribute name="style-type">align-center</xsl:attribute>
			</xsl:when>
			<xsl:when test=". = 'right'">
				<xsl:attribute name="style-type">align-right</xsl:attribute>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="*[self::p or self::ul or self::ol]/@id">
		<xsl:variable name="p_id" select="."/>
		<xsl:choose>
			<xsl:when test="starts-with($p_id, '_') and not(//*[@target = $p_id])"></xsl:when> <!-- remove @id generated by Metanorma -->
			<xsl:otherwise>
				<xsl:attribute name="id"><xsl:value-of select="."/></xsl:attribute>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template match="ul" name="ul">
		<xsl:param name="skip">true</xsl:param>
		
		<xsl:variable name="process">
			<xsl:choose>
				<xsl:when test="$outputformat = 'IEEE' and $skip = 'true' and preceding-sibling::*[1][self::p] and normalize-space(java:endsWith(java:java.lang.String.new(normalize-space(preceding-sibling::*[1][self::p])),'.')) = 'false' and not(ancestor::li)">false</xsl:when> <!-- preceding-sibling::*[1][self::p] -->
				<xsl:otherwise>true</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:if test="$process = 'true'">
			<list> 
				<xsl:choose>
					<xsl:when test="$outputformat = 'IEEE'">
						<xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="@*"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:variable name="processing_instruction_type" select="normalize-space(preceding-sibling::*[1]/processing-instruction('list-type'))"/>
				<xsl:variable name="list-type">
					<xsl:choose>
							<xsl:when test="normalize-space($processing_instruction_type) = 'simple'">simple</xsl:when>
							<xsl:when test="normalize-space(@type) = ''">bullet</xsl:when> <!-- even when <label>—</label> ! -->
							<xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
						</xsl:choose>
				</xsl:variable>
				<xsl:attribute name="list-type">
					<xsl:value-of select="$list-type"/>
				</xsl:attribute>
				<xsl:apply-templates>
					<xsl:with-param name="list-type" select="$list-type"/>
				</xsl:apply-templates>
			</list>
			<xsl:for-each select="note">
				<xsl:call-template name="note"/>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	<xsl:template match="ul/@type"/>
	
	<xsl:template match="ol" name="ol">
		<xsl:param name="skip">true</xsl:param>
		
		<xsl:variable name="process">
			<xsl:choose>
				<xsl:when test="$outputformat = 'IEEE' and $skip = 'true' and preceding-sibling::*[1][self::p] and normalize-space(java:endsWith(java:java.lang.String.new(normalize-space(preceding-sibling::*[1][self::p])),'.')) = 'false' and not(ancestor::li)">false</xsl:when>
				<xsl:otherwise>true</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:if test="$process = 'true'">
			<list>
				<xsl:choose>
					<xsl:when test="$outputformat = 'IEEE'">
						<xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="@*"/>
					</xsl:otherwise>
				</xsl:choose>
				
				<!-- Example: <?list-type loweralpha?> -->
				<xsl:variable name="processing_instruction_type" select="normalize-space(preceding-sibling::*[1]/processing-instruction('list-type'))"/>
				
				<xsl:variable name="type">
					<xsl:choose>
						<xsl:when test="normalize-space($processing_instruction_type) != ''"><xsl:value-of select="$processing_instruction_type"/></xsl:when>
						<xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				
				<xsl:variable name="list-type">
					<xsl:choose>
						<!-- <xsl:when test="@type = 'arabic'">alpha-lower</xsl:when> -->
						<!-- <xsl:when test="$type = 'arabic' and $organization = 'IEEE'">ordered</xsl:when> -->
						<xsl:when test="$type = 'arabic' and not($metanorma_type = 'IEC')">order</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="$metanorma_type = 'IEC' and normalize-space($type) = ''">arabic</xsl:when>
								<xsl:when test="normalize-space($type) = ''">alpha-lower</xsl:when>
								<xsl:when test="$type = 'alphabet'">alpha-lower</xsl:when>
								<xsl:when test="$type = 'alphabet_upper'">alpha-upper</xsl:when>
								<xsl:when test="$type = 'roman'">roman-lower</xsl:when>
								<xsl:when test="$type = 'roman_upper'">roman-upper</xsl:when>
								<xsl:when test="$type = 'arabic'">arabic</xsl:when>
								<xsl:otherwise><xsl:value-of select="$type"/></xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:attribute name="list-type">
					<xsl:choose>
						<xsl:when test="$outputformat = 'IEEE'">ordered</xsl:when>
						<xsl:otherwise><xsl:value-of select="$list-type"/></xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				<xsl:apply-templates>
					<xsl:with-param name="list-type" select="$list-type"/>
				</xsl:apply-templates>
			</list>
			<xsl:for-each select="note">
				<xsl:call-template name="note"/>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	<xsl:template match="ol/@type"/>
	<xsl:template match="ol/@start"/>
	<xsl:template match="ol/text()[normalize-space() = '']"/> <!-- linearization -->

	<xsl:template match="ul/note | ol/note" priority="2"/>
	
	
	<xsl:variable name="color-title" select="//*[local-name() = 'presentation-metadata']/*[local-name() = 'color-title']"/>
	<xsl:variable name="color-list-label" select="//*[local-name() = 'presentation-metadata']/*[local-name() = 'color-list-label']"/>
	
	<xsl:template match="li">
		<xsl:param name="list-type"/>
		<xsl:variable name="isNotePAS" select="(ancestor::note or ancestor::termnote) and $color-title != ''"/>
		<list-item>
			<!-- <xsl:if test="@id">
				<xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
			</xsl:if> -->
			<xsl:copy-of select="@id"/>
			<xsl:choose>
				<xsl:when test="local-name(..) = 'ul' and ancestor::indexsect"><!-- no label for index item --></xsl:when>
				<xsl:when test="local-name(..) = 'ul' and (../@type = 'bullet' or normalize-space(../@type) = '')">
					<xsl:choose>
						<xsl:when test="$metanorma_type = 'ISO'">
							<label>—</label>
						</xsl:when>
						<xsl:when test="$list-type = 'simple'"></xsl:when>
						<xsl:otherwise>
							<xsl:call-template name="insert_label">
								<xsl:with-param name="label">•</xsl:with-param>
								<xsl:with-param name="color" select="$color-list-label"/>
								<xsl:with-param name="isNotePAS" select="$isNotePAS"/>
								<xsl:with-param name="colorNote" select="$color-title"/>
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="local-name(..) = 'ul' and ../@type != 'simple'">
					<xsl:call-template name="insert_label">
						<xsl:with-param name="label">—</xsl:with-param>
						<xsl:with-param name="color" select="$color-list-label"/>
						<xsl:with-param name="isNotePAS" select="$isNotePAS"/>
						<xsl:with-param name="colorNote" select="$color-title"/>
					</xsl:call-template>
					<!-- <label>—</label> -->
				</xsl:when>
				
				<xsl:when test="local-name(..) = 'ol'">
					<!-- <xsl:variable name="type" select="parent::*/@type"/> -->
					<xsl:variable name="type" select="$list-type"/>
					
					<!-- Example: <?list-start 2?> -->
					<xsl:variable name="processing_instruction_start" select="normalize-space(parent::*/preceding-sibling::*[1]/processing-instruction('list-start'))"/>
					
					<xsl:variable name="start_value">
						<xsl:choose>
							<xsl:when test="normalize-space(parent::*/@start) != ''">
								<xsl:value-of select="number(parent::*/@start) - 1"/><!-- if start="3" then start_value=2 + xsl:number(1) = 3 -->
							</xsl:when>
							<xsl:when test="$processing_instruction_start != ''">
								<xsl:value-of select="number($processing_instruction_start) - 1"/><!-- if start="3" then start_value=2 + xsl:number(1) = 3 -->
							</xsl:when>
							<xsl:otherwise>0</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="curr_value">
						<xsl:number/>
					</xsl:variable>
					
					<xsl:variable name="list-item-label">
						<xsl:choose>
							<xsl:when test="$type = 'order' and not($metanorma_type = 'IEC')">
								<xsl:number value="$start_value + $curr_value" format="1)"/>
							</xsl:when>
							<xsl:when test="$type = 'arabic'">
								<xsl:number value="$start_value + $curr_value" format="1)"/>
							</xsl:when>
							<!-- <xsl:when test="$type = 'alphabet'"> -->
							<xsl:when test="$type = 'alpha-lower'">
								<xsl:number value="$start_value + $curr_value" format="a)" lang="en"/>
							</xsl:when>
							<!-- <xsl:when test="$type = 'alphabet_upper'"> -->
							<xsl:when test="$type = 'alpha-upper'">
								<xsl:number value="$start_value + $curr_value" format="A)" lang="en"/>
							</xsl:when>
							<!-- <xsl:when test="$type = 'roman'"> -->
							<xsl:when test="$type = 'roman-lower'">
								<xsl:number value="$start_value + $curr_value" format="i)" lang="en"/>
							</xsl:when>
							<!-- <xsl:when test="$type = 'roman_upper'"> -->
							<xsl:when test="$type = 'roman-upper'">
								<xsl:number value="$start_value + $curr_value" format="I)" lang="en"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:number value="$start_value + $curr_value" format="a)" lang="en"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<xsl:call-template name="insert_label">
						<xsl:with-param name="label" select="$list-item-label"/>
						<xsl:with-param name="isAddition" select="count(*[1]/node()[normalize-space() != ''][1][self::add]) = 1"/>
						<xsl:with-param name="color" select="$color-list-label"/>
						<xsl:with-param name="isNotePAS" select="(ancestor::note or ancestor::termnote) and $color-title != ''"/>
						<xsl:with-param name="colorNote" select="$color-title"/>
					</xsl:call-template>
			
				</xsl:when>
			</xsl:choose>
			
			<xsl:choose>
				<xsl:when test="ancestor::indexsect and not(p)">
					<p><xsl:apply-templates /></p>
				</xsl:when>
				<xsl:otherwise><xsl:apply-templates /></xsl:otherwise>
			</xsl:choose>
			
		</list-item>
	</xsl:template>
	
	<xsl:template match="example">
		<xsl:variable name="ancestor_clause_id" select="ancestor::clause[1]/@id"/>
		<xsl:variable name="ancestor_table_id" select="ancestor::table[1]/@id"/>
		<non-normative-example>
			<xsl:copy-of select="@id"/>
			<label>
				<xsl:text>EXAMPLE</xsl:text>
				<xsl:choose>
					<xsl:when test="ancestor::amend/autonumber[@type = 'example']">
						<xsl:text> </xsl:text><xsl:value-of select="ancestor::amend/autonumber[@type = 'example']/text()"/>
					</xsl:when>
					<xsl:when test="count(ancestor::table[1]//example) &gt; 1">
							<xsl:text>&#xA0;</xsl:text><xsl:number level="any" count="example[ancestor::table[@id = $ancestor_table_id]]"/>
						</xsl:when>
					<xsl:when test="count(ancestor::clause[1]//example) &gt; 1">
						<xsl:text> </xsl:text><xsl:number level="any" count="example[ancestor::clause[@id = $ancestor_clause_id]]"/>
					</xsl:when>
				</xsl:choose>
			</label>
			<xsl:apply-templates/>
		</non-normative-example>
	</xsl:template>
	
	
	
	<xsl:template match="note" name="note">
		<!-- <xsl:if test="$debug = 'true'">
			<xsl:message>DEBUG: note processing <xsl:number level="any" count="*[local-name() = 'note']"/></xsl:message>
		</xsl:if> -->
		<xsl:variable name="ancestor_clause_id" select="ancestor::clause[1]/@id"/>
		<xsl:variable name="ancestor_table_id" select="ancestor::table[1]/@id"/>
		<non-normative-note>
			<xsl:if test="not(name)"> <!-- in semantic metanorma xml there isn't element '<name>NOTE 1</name> -->
				<label>
					<xsl:text>NOTE</xsl:text>
					<xsl:choose>
						<xsl:when test="ancestor::amend/autonumber[@type = 'note']">
							<xsl:text>&#xA0;</xsl:text><xsl:value-of select="ancestor::amend/autonumber[@type = 'note']/text()"/>
						</xsl:when>
						<xsl:when test="count(ancestor::table[1]//note) &gt; 1">
							<xsl:text>&#xA0;</xsl:text><xsl:number level="any" count="note[ancestor::table[@id = $ancestor_table_id]]"/>
						</xsl:when>
						<xsl:when test="count(ancestor::clause[1]//note) &gt; 1">
							<xsl:text>&#xA0;</xsl:text><xsl:number level="any" count="note[ancestor::clause[@id = $ancestor_clause_id]]"/>
						</xsl:when>
					</xsl:choose>
				</label>
			</xsl:if>
			<xsl:apply-templates/>
		</non-normative-note>
	</xsl:template>
	
	<xsl:template match="note/name" priority="2">
		<label><xsl:apply-templates /></label>
	</xsl:template>
	
	<xsl:variable name="start_standard_regex">^((CN|IEC|(IEC/[A-Z]{2,3})|IETF|BCP|ISO|(ISO/[A-Z]{2,3})|ITU|NIST|OGC|CC|OMG|UN|W3C|IEEE|IEEE Std|IHO|BIPM|ECMA|CIE|BS|BSI|BS(\s|\h)OHSAS|PAS|CEN|(CEN/[A-Z]{2,3})|CEN/CENELEC|EN|IANA|3GPP|OASIS|IEV)(\s|\h))+((Guide|TR|TC)(\s|\h))?\d.*</xsl:variable>
	<xsl:variable name="start_standard_regex_IEEE">^(IEEE)(\s|\h)(Std(\s|\h))?(.*)</xsl:variable>
	<xsl:variable name="regex_pub-id-year">^(.*)[\s|\h]?[-|:][\s|\h]?(\d{4})$</xsl:variable>
	<xsl:variable name="bibitems_URN_">
		<xsl:for-each select="$xml//bibitem[docidentifier]"> <!-- [@type = 'URN'] -->
			<bibitem>
				<xsl:copy-of select="@id"/>
				<xsl:copy-of select="@type"/>
				<xsl:copy-of select="@hidden"/>
				<xsl:variable name="urn_" select="docidentifier[@type = 'URN']"/>
				<!-- remove URN urn: at start -->
				<xsl:variable name="urn__" select="java:replaceAll(java:java.lang.String.new($urn_),'^(URN )?(urn:)?','')"/>
				<!-- remove :stage-xx.yy -->
				<xsl:variable name="urn" select="java:replaceAll(java:java.lang.String.new($urn__),':stage-\d+\.\d+','')"/>
				<!-- remove :ed-z -->
				<!-- <xsl:variable name="urn" select="java:replaceAll(java:java.lang.String.new($urn___),':ed-\d+','')"/> -->
				
				<xsl:variable name="docidentifier">
					<xsl:value-of select="docidentifier[not(@type = 'metanorma' or @type = 'metanorma-ordinal')][1]"/>
					<!-- <xsl:if test="starts-with(@id, 'hidden_bibitem_')"> -->
					<xsl:if test="@hidden = 'true' and $outputformat != 'IEEE'">
						<xsl:text> </xsl:text>
						<xsl:value-of select="translate(docnumber, '&#xa0;&#8209;', ' -')"/>
					</xsl:if>
				</xsl:variable>
				
				<!-- Examples: ISO number, BS EN number, EN ISO number -->
				<xsl:if test="java:org.metanorma.utils.RegExHelper.matches($start_standard_regex, normalize-space($docidentifier)) = 'true' or java:org.metanorma.utils.RegExHelper.matches($start_standard_regex_IEEE, normalize-space($docidentifier)) = 'true'">
					<xsl:if test="not(@type)">
						<xsl:attribute name="type">standard</xsl:attribute>
					</xsl:if>
					<xsl:attribute name="organization">
						<xsl:call-template name="get_organization">
							<xsl:with-param name="docidentifier" select="$docidentifier"/>
						</xsl:call-template>
					</xsl:attribute>
				</xsl:if>
				
				<urn><xsl:value-of select="$urn"/></urn>
				<docidentifier>
					<xsl:value-of select="$docidentifier"/>
				</docidentifier>
				
				<xsl:if test="$outputformat = 'IEEE'">
					<xsl:copy-of select="formattedref"/>
				</xsl:if>
			</bibitem>
		</xsl:for-each>
	</xsl:variable>
	<xsl:variable name="bibitems_URN" select="xalan:nodeset($bibitems_URN_)"/>
	
	<xsl:template name="get_organization">
		<xsl:param name="docidentifier"/>
		<xsl:choose>
			<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($start_standard_regex_IEEE, normalize-space($docidentifier)) = 'true'">
				<xsl:value-of select="java:replaceAll(java:java.lang.String.new(normalize-space($docidentifier)),$start_standard_regex_IEEE,'$1')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="java:replaceAll(java:java.lang.String.new(normalize-space($docidentifier)),$start_standard_regex,'$2')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- ======================-->
	<!-- eref processing -->
	<!-- ===================== -->
	<xsl:template match="eref" name="eref">
	
		<xsl:variable name="model_eref_">
			<xsl:call-template name="build_metanorma_model_eref"/>
		</xsl:variable>
		<xsl:variable name="model_eref" select="xalan:nodeset($model_eref_)"/>
	
		<xsl:variable name="bibitem_URN_" select="$bibitems_URN/bibitem[@id = current()/@bibitemid]"/>
		<xsl:variable name="bibitem_URN" select="xalan:nodeset($bibitem_URN_)"/>
	
		<xsl:variable name="docidentifier_URN" select="normalize-space($bibitem_URN/urn)"/>
		
		<xsl:variable name="docidentifier" select="normalize-space($bibitem_URN/docidentifier)"/>
		<!-- bibitems_URN=<xsl:copy-of select="$bibitems_URN"/> -->
		<xsl:variable name="value">
			<xsl:choose>
				<xsl:when test="$docidentifier_URN != ''"><xsl:value-of select="$docidentifier_URN"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="@citeas"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
	
		<xsl:if test="$metanorma_type = 'IEC'">
			
			<!-- Example of resulted xml:
			<std>
				<std-id std-id-link-type="urn" std-id-type="dated">urn:iec:std:iec:62391-1:2015-10:::#con-3.8</std-id>
				<std-ref>IEC 62391–1:2015, 3.8</std-ref>
			</std>
			-->
			
			<!-- <bibitems_URN><xsl:copy-of select="$bibitems_URN"/></bibitems_URN> -->
			
			<xsl:variable name="model_eref_locality">
				<xsl:for-each select="$model_eref/locality">
					<xsl:text>, </xsl:text>
					<xsl:choose>
						<xsl:when test="@type = 'clause'"></xsl:when>
						<xsl:otherwise>
							<xsl:variable name="type" select="java:replaceAll(java:java.lang.String.new(@type),$regex_locality,'$2')"/>
							<xsl:call-template name="capitalize">
								<xsl:with-param name="str" select="$type"/>
							</xsl:call-template>
							<xsl:text> </xsl:text>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:value-of select="."/>
				</xsl:for-each>
			</xsl:variable>
			
			<xsl:choose>
				<xsl:when test="self::eref and not($bibitem_URN/@hidden = 'true')">
					<!-- References to items in the bibliography are coded with <xref>. -->
					<xref ref-type="bibr" rid="{@bibitemid}">
						<xsl:value-of select="$model_eref/referenceText"/>
						<xsl:value-of select="$model_eref_locality"/>
					</xref>
				</xsl:when>
				
				<xsl:otherwise>
					<std>
						<std-id>
							<xsl:attribute name="std-id-link-type">
								<xsl:choose>
									<xsl:when test="$docidentifier_URN != ''">urn</xsl:when>
									<xsl:otherwise>internal-pub-id</xsl:otherwise>
								</xsl:choose>
							</xsl:attribute>
							<xsl:attribute name="std-id-type">
								<xsl:call-template name="setDatedUndatedType">
									<xsl:with-param name="value" select="$value"/>
								</xsl:call-template>
							</xsl:attribute>
							<xsl:choose>
								<xsl:when test="$docidentifier_URN != ''">
									<xsl:value-of select="$docidentifier_URN"/>
									<xsl:for-each select="localityStack/locality[1]">
										<xsl:text>#</xsl:text>
										<xsl:choose>
											<xsl:when test="@type = 'clause'">sec</xsl:when>
											<xsl:when test="@type = 'annex'">anx</xsl:when>
											<xsl:otherwise><xsl:value-of select="substring(@type,1,3)"/></xsl:otherwise>
										</xsl:choose>
										<xsl:text>-</xsl:text>
										<xsl:value-of select="referenceFrom"/>
									</xsl:for-each>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$model_eref/reference"/>
								</xsl:otherwise>
							</xsl:choose>
							
						</std-id>
						<std-ref>
							<xsl:value-of select="$model_eref/referenceText"/>
							
							<xsl:value-of select="$model_eref_locality"/>
							
						</std-ref>
					</std>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if> <!-- eref for $organization = 'IEC' -->
	
		<xsl:if test="$organization = 'BSI'">
			<!-- <xsl:copy-of select="$model_eref"/> -->
			<std>
				<xsl:attribute name="type">
					<xsl:call-template name="setDatedUndatedType">
						<xsl:with-param name="value" select="$value"/>
					</xsl:call-template>
				</xsl:attribute>
				<xsl:attribute name="std-id">
					<xsl:choose>
						<xsl:when test="$docidentifier_URN != ''">
							<xsl:value-of select="$docidentifier_URN"/>
							<!-- add localities -->
							<xsl:for-each select="localityStack/locality">
								<xsl:choose>
									<xsl:when test="@type = 'annex' or @type = 'clause'">:clause:<xsl:value-of select="referenceFrom"/></xsl:when>
									<!-- table
									locality:definition -->
								</xsl:choose>
							</xsl:for-each>
						</xsl:when>
						<xsl:when test="$docidentifier != ''">
							<xsl:value-of select="$docidentifier"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$model_eref/reference"/>
							<!-- <xsl:choose>
								<xsl:when test="starts-with($model_eref/reference, 'hidden_bibitem_')">
									<xsl:value-of select="substring-after($model_eref/reference, 'hidden_bibitem_')"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$model_eref/reference"/>
								</xsl:otherwise>
							</xsl:choose> -->
						</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				<std-ref>
					<xsl:choose>
						<xsl:when test="$organization = 'BSI'">
							<xsl:variable name="text_" select="translate($model_eref/referenceText, ' ', '&#xA0;')"/> <!-- replace space to non-break space -->
							<xsl:value-of select="java:replaceAll(java:java.lang.String.new($text_),',(\s|\h)*$', '')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$model_eref/referenceText"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:copy-of select="following-sibling::node()[1][self::processing-instruction('doi')]"/>
				</std-ref>
				
				<xsl:if test="$model_eref/locality">
					<xsl:text>, </xsl:text>
					<xsl:for-each select="$model_eref/locality">
						<xsl:if test="@type != ''">
							<xsl:choose>
								<xsl:when test="@type = 'clause'">
									<xsl:if test="not(contains(., '.'))"> Clause </xsl:if>
								</xsl:when>
								<xsl:when test="@type = 'annex'">
									<xsl:if test="not(contains(., '.'))"> Annex </xsl:if>
								</xsl:when>
								<xsl:when test="@type = 'section'">
									<xsl:if test="not(contains(., '.'))"> Section </xsl:if>
								</xsl:when>
								<xsl:otherwise>
									<xsl:variable name="type" select="java:replaceAll(java:java.lang.String.new(@type),$regex_locality,'$2')"/>
									<xsl:if test="not(contains(., '.'))"> <xsl:value-of select="$type"/> </xsl:if>
								</xsl:otherwise>
							</xsl:choose>
							<bold><xsl:value-of select="."/></bold>
						</xsl:if>
						
						<xsl:if test="following-sibling::locality[normalize-space() != '']">
							<xsl:choose>
								<xsl:when test="@connective != '' and @connective != 'from' and following-sibling::locality[normalize-space() != '']"><xsl:text> </xsl:text><xsl:value-of select="@connective"/><xsl:text> </xsl:text></xsl:when>
								<xsl:when test="count(following-sibling::locality[normalize-space() != '']) &gt; 1"><xsl:text>, </xsl:text></xsl:when>
								<!-- <xsl:when test="count(following-sibling::locality[normalize-space() != '']) = 1"><xsl:text> and </xsl:text></xsl:when> -->
							</xsl:choose>
						</xsl:if>
					</xsl:for-each>
				</xsl:if>
				<!-- <xsl:apply-templates select="localityStack"/> -->
			</std>
			
			<xsl:variable name="citeas_" select="java:replaceAll(java:java.lang.String.new(@citeas),'--','—')"/>
			<xsl:variable name="citeas">
				<xsl:choose>
					<!-- if citeas enclosed in [ ], then remove it -->
					<xsl:when test="starts-with($citeas_, '[') and substring($citeas_, string-length($citeas_)) = ']'">
						<xsl:value-of select="substring($citeas_, 2, string-length($citeas_) - 2)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$citeas_"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			
		</xsl:if> <!-- eref for $organization = 'BSI' -->
		
		<xsl:if test="$outputformat = 'IEEE'">
			<xsl:if test="$bibitem_URN/@type = 'standard'">
				<mixed-citation>
					<!-- <debug><xsl:copy-of select="$bibitem_URN"/></debug> -->
					<xsl:call-template name="insert_std_IEEE">
						<xsl:with-param name="bibitem_URN" select="$bibitem_URN"/>
					</xsl:call-template>
				</mixed-citation>
			</xsl:if>
			<xsl:if test="not($bibitem_URN/@hidden = 'true')">
				<xref>
					<xsl:attribute name="ref-type">bibr</xsl:attribute>
					<xsl:attribute name="rid"><xsl:value-of select="@bibitemid"/></xsl:attribute>
					<xsl:value-of select="@citeas"/>
				</xref>
			</xsl:if>
		</xsl:if>
		
		<xsl:if test="$metanorma_type != 'IEC' and $organization != 'BSI' and $outputformat != 'IEEE'">
	
			<xsl:variable name="citeas_" select="java:replaceAll(java:java.lang.String.new(@citeas),'--','—')"/>
			<xsl:variable name="citeas">
				<xsl:choose>
					<!-- if citeas enclosed in [ ], then remove it -->
					<xsl:when test="starts-with($citeas_, '[') and substring($citeas_, string-length($citeas_)) = ']'">
						<xsl:value-of select="substring($citeas_, 2, string-length($citeas_) - 2)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$citeas_"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			
			<xsl:choose>
				<xsl:when test="self::eref and not($bibitem_URN/@hidden = 'true')">
					<!-- References to items in the bibliography are coded with <xref>. -->
					<xref ref-type="bibr" rid="{@bibitemid}">
						<xsl:value-of select="$citeas"/>
						<xsl:apply-templates select="localityStack"/>
					</xref>
				</xsl:when>
				<xsl:otherwise>
					<std>
						<xsl:attribute name="type">
							<xsl:call-template name="setDatedUndatedType">
								<xsl:with-param name="value" select="$citeas"/>
							</xsl:call-template>
						</xsl:attribute>
						<xsl:variable name="reference" select="@bibitemid"/>
						
						<xsl:attribute name="std-id">
							<xsl:choose>
								<xsl:when test="$docidentifier_URN != ''">
									<xsl:value-of select="$docidentifier_URN"/>
									<!-- add localities -->
									<xsl:for-each select="localityStack/locality">
										<xsl:choose>
											<xsl:when test="@type = 'annex' or @type = 'clause'">:clause:<xsl:value-of select="referenceFrom"/></xsl:when>
											<!-- table
											locality:definition -->
										</xsl:choose>
									</xsl:for-each>
								</xsl:when>
								<xsl:when test="$docidentifier != ''">
									<xsl:value-of select="$docidentifier"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$reference"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
						
						<std-ref>
							<xsl:value-of select="$citeas"/>
						</std-ref>
						<xsl:apply-templates select="localityStack"/>
					</std>
				</xsl:otherwise>
			</xsl:choose>
			
			
		</xsl:if>
		
	</xsl:template>
	
	<xsl:template name="insert_std_IEEE">
		<xsl:param name="bibitem_URN"/>
		<xsl:param name="is_bibitem">false</xsl:param>
		
		<!-- From xref:
		<mixed-citation>
			<std>
				<xsl:variable name="pub-id"><xsl:apply-templates /></xsl:variable>
				<xsl:variable name="regex_pub-id">^(\w*)(\s|\h)(.*)</xsl:variable>
				<std-organization><xsl:value-of select="java:replaceAll(java:java.lang.String.new($pub-id),$regex_pub-id,'$1')"/></std-organization>
				<pub-id pub-id-type="std-designation"><xsl:value-of select="java:replaceAll(java:java.lang.String.new($pub-id),$regex_pub-id,'$3')"/></pub-id>
			</std>
		</mixed-citation> -->
		
		<std>
			<xsl:variable name="organization" select="java:replaceAll(java:java.lang.String.new($bibitem_URN/@organization),' Std','')" />
			<std-organization><xsl:value-of select="$organization"/></std-organization>
			<!-- <xsl:if test="$is_bibitem = 'true'"> -->
			<xsl:text> Std </xsl:text>
			<!-- </xsl:if> -->
			
			<xsl:variable name="pub-id_full" select="normalize-space(java:replaceAll(java:java.lang.String.new($bibitem_URN/docidentifier),concat($bibitem_URN/@organization,'([\s|\h]Std[\s|\h])?([^,™]*).*'),'$2'))"/>
			<xsl:variable name="pub-id" select="java:replaceAll(java:java.lang.String.new($pub-id_full),$regex_pub-id-year,'$1')"/> <!-- number without year -->
			<xsl:variable name="year" select="java:replaceAll(java:java.lang.String.new($pub-id_full),$regex_pub-id-year,'$2')"/>
			
			<pub-id pub-id-type="std-designation">
				<!-- <xsl:if test="$is_bibitem = 'false'">
					<xsl:text>Std </xsl:text>
				</xsl:if> -->
				<!-- <xsl:value-of select="normalize-space(substring-after($bibitem_URN/docidentifier, $bibitem_URN/@organization))"/> -->
			 <!--  <bibitem_URN_docidentifier><xsl:value-of select="$bibitem_URN/docidentifier"/></bibitem_URN_docidentifier>
				<regex><xsl:value-of select="concat($bibitem_URN/@organization,'([\s|\h]Std[\s|\h])?([^,]*)™?.*'),'$2')"/></regex> -->
				<xsl:value-of select="$pub-id"/>
			</pub-id><xsl:value-of select="$trademark"/>
			<xsl:if test="$year != '' and $year != $pub-id">-<year><xsl:value-of select="$year"/></year></xsl:if>
			<xsl:if test="$is_bibitem = 'true'">
				<source specific-use="IEEE">
					<!-- <xsl:if test="$bibitem_URN/@type = 'standard'">
						<xsl:attribute name="specific-use">IEEE</xsl:attribute>
					</xsl:if> -->
					<xsl:variable name="nodes">
						<xsl:apply-templates select="node()[not(self::xref or self::fn or self::text()[preceding-sibling::*[1][self::fn]])]"/>
					</xsl:variable>
					<xsl:for-each select="xalan:nodeset($nodes)/node()">
						<xsl:choose>
							<xsl:when test="position() = 1 and self::text() and contains(., ',')">
								<xsl:value-of select="substring-after(., ', ')"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:copy-of select="."/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</source>
			</xsl:if>
		</std>
	</xsl:template>
	
  <xsl:template match="processing-instruction('doi')"/>
  
	<!-- build eref model:
		reference - link to bibliography item
		referenceText - text for displaying (if it's difference from bibliography item text)
		locality - example: clause 2.5 -->
	<xsl:template name="build_metanorma_model_eref"> <!-- eref context -->
		<!-- Example: <eref type="inline" bibitemid="ISO6322-2" citeas="ISO 6322-2"/> -->
		<!-- Semantic xml example: 
		<eref type="inline" bibitemid="ISO7301" citeas="ISO 7301:2011">
			<localityStack>
				<locality type="table">
					<referenceFrom>1</referenceFrom>
				</locality>
			</localityStack>
		</eref> -->
		<!-- Presentation xml example: 
		<eref type="inline" bibitemid="ISO7301" citeas="ISO 7301:2011">
			<localityStack>
				<locality type="table">
					<referenceFrom>1</referenceFrom>
				</locality>
			</localityStack>ISO 7301:2011, Table 1</eref> -->
			
		<!-- Semantic xml example:
		<eref type="inline" bibitemid="ISO24333" citeas="ISO 24333:2009">
			<localityStack>
				<locality type="clause">
					<referenceFrom>5</referenceFrom>
				</locality>
			</localityStack>
		</eref> -->
		<!-- Presentation xml example: 
		<eref type="inline" bibitemid="ISO24333" citeas="ISO 24333:2009">
			<localityStack>
				<locality type="clause">
					<referenceFrom>5</referenceFrom>
				</locality>
			</localityStack>ISO 24333:2009, Clause 5</eref> -->

		<!-- Semantic xml example:		
		<eref type="inline" bibitemid="ISO20483" citeas="ISO 20483:2013">
			<localityStack>
				<locality type="annex">
					<referenceFrom>C</referenceFrom>
				</locality>
			</localityStack>
		</eref> -->
		<!-- Presentation xml example:
		<eref type="inline" bibitemid="ISO20483" citeas="ISO 20483:2013">
			<localityStack>
				<locality type="annex">
					<referenceFrom>C</referenceFrom>
				</locality>
			</localityStack>ISO 20483:2013, Annex C</eref> -->
			
		<!-- Example with 'and' 
			<localityStack connective="and">
				<locality type="clause">
					<referenceFrom>3.3</referenceFrom>
				</locality>
			</localityStack>
			<localityStack connective="and">
				<locality type="clause">
					<referenceFrom>3.2</referenceFrom>
				</locality>
			</localityStack>
		-->
			
		
		<reference><xsl:value-of select="@bibitemid"/></reference>
		<referenceText>
			<xsl:choose>
				<xsl:when test="count(node()[not(self::localityStack)]) &gt; 0"><xsl:apply-templates select="node()[not(self::localityStack)][1]"/></xsl:when> <!-- for presentation xml -->
				<xsl:otherwise> <!-- for semantic xml - build string with localities -->
					<xsl:value-of select="@citeas"/>
				</xsl:otherwise>
			</xsl:choose>
		</referenceText>
		<xsl:for-each select="localityStack/locality">
			<locality>
				<xsl:copy-of select="@type"/>
				<xsl:copy-of select="../@connective"/>
				<xsl:value-of select="referenceFrom"/>
			</locality>
		</xsl:for-each>
		
	</xsl:template>
	<!-- ======================-->
	<!-- END eref processing -->
	<!-- ===================== -->
	
	
	<xsl:template match="link">
		<xsl:choose>
		
			<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'IEC'">
				<!-- Metanorma XML examples:
					<link target="https://www.iso.org/obp"/>
					<link target="mailto:gehf@vacheequipment.fic"/>
					<link target="http://www.iso.org/directives">www.iso.org/directives</link>
					<link target="http://standards.iso.org/iso/10303/tech/step_titles.htm">ISO website</link>
				-->
				<xsl:variable name="link_text" select="normalize-space()"/>
				<xsl:variable name="isIncompleteURL" select="normalize-space(not(starts-with(@target, 'http:') or starts-with(@target, 'https:') or starts-with(@target, 'ftp:') or starts-with(@target, 'mailto:')))"/> <!-- true or false -->
				<xsl:choose>
					<xsl:when test="$isIncompleteURL = 'true' or ($link_text != '' and $link_text != @target)"> <!-- Incomplete URLs or display text hides the actual link -->
						<xsl:choose>
							<xsl:when test="starts-with(@target, 'file://')">
								<supplementary-material>
									<xsl:attribute name="xlink:href">
										<xsl:value-of select="substring-after(@target, 'file://')"/>
									</xsl:attribute>
									<p><xsl:apply-templates /></p>
								</supplementary-material>
							</xsl:when>
							<xsl:otherwise>
								<ext-link>
									<xsl:attribute name="xlink:href">
										<xsl:value-of select="@target"/>
									</xsl:attribute>
									<xsl:apply-templates />
								</ext-link>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<!-- <uri>http://my.url</uri> -->
						<uri><xsl:value-of select="@target"/></uri>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when> <!-- ISO, IEC -->
		
			<xsl:when test="normalize-space() = '' or $metanorma_type = 'IEC'">
				<uri><xsl:value-of select="@target"/></uri>
			</xsl:when>
			<xsl:otherwise>
				<ext-link>
					<xsl:choose>
						<xsl:when test="$metanorma_type = 'ISO'">
							<xsl:attribute name="ext-link-type">uri</xsl:attribute>
						</xsl:when>
						<xsl:otherwise>
							<xsl:attribute name="xlink:type">simple</xsl:attribute>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:attribute name="xlink:href">
						<xsl:value-of select="@target"/>
					</xsl:attribute>
					<xsl:apply-templates />
				</ext-link>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="preferred/strong">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="strong">
		<bold><xsl:apply-templates /></bold>
	</xsl:template>

	<xsl:template match="sup[stem]">
		<xsl:apply-templates />
	</xsl:template>

	<xsl:template match="pre">
		<preformat><xsl:apply-templates /></preformat>
	</xsl:template>

	<xsl:template match="span">
		<xsl:variable name="styles__">
			<xsl:call-template name="split">
				<xsl:with-param name="pText" select="concat(@style,';')"/>
				<xsl:with-param name="sep" select="';'"/>
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:variable name="quot">"</xsl:variable>
		<xsl:variable name="styles_">
			<xsl:for-each select="xalan:nodeset($styles__)/item">
				<xsl:variable name="key" select="normalize-space(substring-before(., ':'))"/>
				<xsl:variable name="value" select="normalize-space(substring-after(translate(.,$quot,''), ':'))"/>
				<xsl:if test="$key = 'font-family' or $key = 'color'">
					<style name="{$key}"><xsl:value-of select="$value"/></style>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="styles" select="xalan:nodeset($styles_)"/>
		<xsl:choose>
			<xsl:when test="$styles/style">
				<!-- Example: <styled-content style="color" style-type="red">color text</styled-content> -->
				<xsl:call-template name="insertStyledContent">
					<xsl:with-param name="node">
						<xsl:apply-templates />
					</xsl:with-param>
					<xsl:with-param name="styles" select="$styles"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- insert nested <styled-content ...><styled-content ...> node </styled-content></styled-content> -->
	<xsl:template name="insertStyledContent">
		<xsl:param name="node"/>
		<xsl:param name="styles"/>
		<xsl:param name="pos" select="1"/>
		<xsl:for-each select="$styles/style[$pos]">
			<styled-content>
				<!-- Example: <styled-content style="color" style-type="red">color text</styled-content> -->
				<xsl:attribute name="style"><xsl:value-of select="@name"/></xsl:attribute>
				<xsl:attribute name="style-type"><xsl:value-of select="."/></xsl:attribute>
				<xsl:choose>
					<xsl:when test="($pos + 1) &gt; count(xalan:nodeset($styles)/style)"> <!-- last style -->
						<xsl:copy-of select="$node"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="insertStyledContent">
							<xsl:with-param name="node" select="$node"/>
							<xsl:with-param name="styles" select="$styles"/>
							<xsl:with-param name="pos" select="$pos + 1"/>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</styled-content>
		</xsl:for-each>
		
	</xsl:template>

	
	<xsl:template match="em">
		<italic><xsl:apply-templates /></italic>
	</xsl:template>

	<xsl:template match="strong/br">
		<xsl:text disable-output-escaping="yes">&lt;/bold&gt;</xsl:text>
		<break/>
		<xsl:text disable-output-escaping="yes">&lt;bold&gt;</xsl:text>
	</xsl:template>

	<xsl:template match="br">
		<break/>
	</xsl:template>
	
	<xsl:template match="th[strong][br[parent::strong]]/node()[1][self::text()]">
		<xsl:text disable-output-escaping="yes">&lt;bold&gt;</xsl:text>
		<xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="th[strong]/br[parent::strong]" priority="2">
		<xsl:text disable-output-escaping="yes">&lt;/bold&gt;</xsl:text>
		<break/>
		<xsl:text disable-output-escaping="yes">&lt;bold&gt;</xsl:text>
	</xsl:template>
	
	<xsl:template match="xref[normalize-space() != '' and string-length(normalize-space()) = string-length(translate(normalize-space(), '0123456789', '')) and not(contains(normalize-space(), 'Annex'))]" priority="2">
		<named-content>
			<xsl:attribute name="content-type">
				<xsl:choose>
					<xsl:when test="starts-with(@target, 'abbrev')">abbrev</xsl:when>
					<xsl:otherwise>term</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:attribute name="xlink:href">#<xsl:value-of select="@target"/></xsl:attribute>
			<xsl:apply-templates />
		</named-content>
	</xsl:template>
	
	<xsl:template match="xref" name="xref">
		<xsl:if test="normalize-space($debug) = 'true'">
			<xsl:message>DEBUG: Start xref <xsl:number level="any"/></xsl:message>
		</xsl:if>
		<xsl:variable name="element_xref_" select="$elements//element[@source_id = current()/@target or @source_id = current()/@bibitemid]"/>
		<xsl:variable name="element_xref" select="xalan:nodeset($element_xref_)"/>
		
		<xsl:variable name="section" select="$element_xref/@section"/>
		<xsl:variable name="section_prefix" select="$element_xref/@section_prefix"/>
		<xsl:variable name="section_bolded" select="$element_xref/@section_bolded"/>
		<xsl:variable name="parent_id" select="$element_xref/@parent_id"/>
		<xsl:variable name="type" select="$element_xref/@type"/>
		
		<xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable>
		
		<xsl:variable name="parent" select="$element_xref/@parent"/>
		<xsl:variable name="ref_type">
			<xsl:choose>
        <xsl:when test="$parent = 'figure'">fig</xsl:when>
				<xsl:when test="$parent = 'table'">table</xsl:when>
				<xsl:when test="$parent = 'annex'">app</xsl:when>
				<xsl:when test="$parent = 'fn'">fn</xsl:when>
				<xsl:when test="$parent = 'bibitem'">bibr</xsl:when>
				<xsl:when test="$parent = 'formula'">disp-formula</xsl:when>
				<xsl:when test="$parent = 'ul' or $parent = 'ol' or $parent = 'li'">list</xsl:when>
				<xsl:when test="$parent = 'term' and $metanorma_type = 'IEC'">other</xsl:when>
				<xsl:when test="$parent = 'dt-abb'">other</xsl:when>
				<xsl:otherwise>sec</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- parent=<xsl:value-of select="$parent"/> -->
		<xsl:if test="not($element_xref)">
			<xsl:message>WARNING: There is no ID/IDREF binding for IDREF '<xsl:value-of select="@target"/>'.</xsl:message>
		</xsl:if>
		
		<xref> <!-- ref-type="{$ref_type}" rid="{$id}" --> <!-- replaced by xsl:attribute name=... for save ordering -->
			<xsl:attribute name="ref-type">
				<xsl:value-of select="$ref_type"/>
			</xsl:attribute>
			<xsl:attribute name="rid">
				<xsl:choose>
					<xsl:when test="$parent_id != ''"><xsl:value-of select="$parent_id"/></xsl:when>
					<xsl:when test="@bibitemid != ''"><xsl:value-of select="@bibitemid"/></xsl:when> <!-- from origin -->
					<xsl:otherwise><xsl:value-of select="@target"/></xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
				<!-- <xsl:choose>
					<xsl:when test="normalize-space($id) = ''"><xsl:value-of select="@target"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="$id"/></xsl:otherwise>
				</xsl:choose>
			</xsl:attribute> -->
			<xsl:choose>
				<xsl:when test="$isSemanticXML = 'true'"> <!-- semantic xml -->
					<xsl:variable name="text_">
						<xsl:value-of select="$section_prefix"/>
						<xsl:choose>
							<xsl:when test="$section_bolded = 'true' and not(ancestor::td or ancestor::th)">
								<bold><xsl:value-of select="translate($section, '&#xA0;', ' ')"/></bold>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="translate($section, '&#xA0;', ' ')"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="text">
						<xsl:copy-of select="$text_"/>
						<xsl:if test="normalize-space($text_) = ''"><!-- in case of term -->
							<xsl:value-of select="$elements//element[@id = current()/@target]/@section"/>
						</xsl:if>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="self::origin">
							<xsl:value-of select="@citeas"/>
							<xsl:apply-templates/>
						</xsl:when>
						<xsl:when test="./*">
							<xsl:apply-templates mode="internalFormat">
								<xsl:with-param name="text" select="$text"/>
							</xsl:apply-templates>
						</xsl:when>
						<xsl:when test="normalize-space($text) != ''">
							<xsl:copy-of select="$text"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates select="node()[not(local-name() = 'stem')]"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise> <!-- presentation xml -->
					<xsl:apply-templates select="node()[not(local-name() = 'stem')]"/>
				</xsl:otherwise>
			</xsl:choose>
		</xref>
		
		<xsl:apply-templates select="stem"/> <!-- put inline-formula outside xref -->
	</xsl:template>
	
  <xsl:template match="strong | em | *" mode="internalFormat">
    <xsl:param name="text"/>
    <xsl:variable name="element">
      <xsl:choose>
        <xsl:when test="self::strong">bold</xsl:when>
        <xsl:when test="self::em">italic</xsl:when>
        <xsl:otherwise><xsl:value-of select="local-name()"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$element}">
      <xsl:choose>
        <xsl:when test="./*">
          <xsl:apply-templates  mode="internalFormat">
            <xsl:with-param name="text" select="$text"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$text"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>
  
	<!-- ============== -->
	<!-- boxed-text -->
	<!-- ============== -->
	<xsl:template match="table[starts-with(@id, 'boxed-text_') and @unnumbered = 'true']" priority="2">
		<boxed-text>
			<xsl:apply-templates />
		</boxed-text>
	</xsl:template>
	<xsl:template match="*[self::tbody or self::tr][ancestor::table[starts-with(@id, 'boxed-text_') and @unnumbered = 'true']]" priority="2">
		<xsl:apply-templates />
	</xsl:template>
	<xsl:template match="td[ancestor::table[starts-with(@id, 'boxed-text_') and @unnumbered = 'true']]" priority="2">
		<xsl:choose>
			<xsl:when test="not(p)">
				<p><xsl:apply-templates/></p>
			</xsl:when>
			<xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- ============== -->
	<!-- END boxed-text -->
	<!-- ============== -->
	
	<!-- need to be tested (find original NISO) -->
	<xsl:template match="callout">
		<xref ref-type="other" rid="{@target}">
			<xsl:apply-templates/>
		</xref>
	</xsl:template>
	
	<!-- https://github.com/metanorma/mn2sts/issues/8 -->
	<xsl:template match="admonition">
		<xsl:choose>
			<xsl:when test="@type = 'editorial' and ($metanorma_type = 'IEC' or $metanorma_type = 'ISO') and $format = 'NISO'">
			
				<editing-instruction>
					<xsl:apply-templates/>
				</editing-instruction>
				
			</xsl:when>
			<xsl:otherwise>
			
				<non-normative-note>
					<xsl:copy-of select="@id"/>
					<xsl:if test="$metanorma_type = 'IEC' or $metanorma_type = 'ISO'">
						<xsl:if test="@type = 'warning' or @type = 'important' or @type = 'caution'">
							<xsl:attribute name="content-type"><xsl:value-of select="@type"/></xsl:attribute>
						</xsl:if>
					</xsl:if>
					<label><xsl:value-of select="java:toUpperCase(java:java.lang.String.new(@type))"/></label>
					<xsl:apply-templates />
				</non-normative-note>
				
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<!-- https://github.com/metanorma/mn2sts/issues/9 -->
	<xsl:template match="quote">
		<disp-quote id="{@id}">
			<xsl:apply-templates select="p"/>
			<xsl:if test="source or author">
				<related-object>
					<xsl:apply-templates select="author" mode="disp-quote"/>
					<xsl:if test="source and author">, </xsl:if>
					<xsl:apply-templates select="source" mode="disp-quote"/>
				</related-object>
			</xsl:if>
		</disp-quote>
	</xsl:template>	
	<xsl:template match="quote/source"/>
	<xsl:template match="quote/author"/>
	
	<xsl:template match="quote/author" mode="disp-quote">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="quote/source" mode="disp-quote">
		<xsl:value-of select="@citeas"/>
		<xsl:apply-templates mode="disp-quote"/>
	</xsl:template>
	
	<xsl:template match="localityStack" mode="disp-quote">		
		<xsl:for-each select="locality">
			<xsl:if test="position() = 1"><xsl:text>, </xsl:text></xsl:if>
			<xsl:apply-templates select="." mode="disp-quote"/>
			<xsl:if test="position() != last()"><xsl:text>; </xsl:text></xsl:if>
		</xsl:for-each>	
	</xsl:template>
	
	<xsl:template match="locality"  mode="disp-quote">
		<xsl:choose>
			<xsl:when test="@type ='clause'">Clause </xsl:when>
			<xsl:when test="@type ='annex'">Annex </xsl:when>
			<xsl:otherwise>
				<xsl:variable name="type" select="java:replaceAll(java:java.lang.String.new(@type),$regex_locality,'$2')"/>
				<xsl:value-of select="$type"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:value-of select="referenceFrom"/>
	</xsl:template>
	

	<!-- https://github.com/metanorma/mn2sts/issues/10 -->
	<xsl:template match="appendix">
		<sec id="{@id}" sec-type="appendix">
			
			<xsl:variable name="section" select="normalize-space(@section)"/>
			
			<xsl:if test="$section != ''">
			
				<xsl:call-template name="insert_label">
					<xsl:with-param name="label" select="$section"/>
					<xsl:with-param name="isAddition" select="count(title/node()[normalize-space() != ''][1][self::add]) = 1"/>
				</xsl:call-template>
				
			</xsl:if>
			
			<xsl:apply-templates/>
		</sec>
	</xsl:template>
	
	<xsl:template match="annotation">
		<element-citation>			
			<xsl:if test="$format = 'ISO'">
				<xsl:attribute name="id">
					<xsl:value-of select="@id"/>					
				</xsl:attribute>				
			</xsl:if>			
			<annotation>
				<xsl:if test="$format = 'NISO'">
					<xsl:attribute name="id">
						<xsl:value-of select="@id"/>					
					</xsl:attribute>
				</xsl:if>
				<xsl:apply-templates/>
			</annotation>
		</element-citation>
	</xsl:template>
	
	<xsl:template match="concept">
		<xsl:choose>
			<xsl:when test="$metanorma_type = 'IEC' or $metanorma_type = 'ISO'">
				<!-- for ISO or IEC -->
				<xsl:choose>
					<xsl:when test="ancestor::terms and ancestor::definition">
						<!-- Cross-references between terminological entries or terms within the Terms and definitions clause can be tagged as <tbx:entailedTerm>. This element should only be used in child elements of <tbx:termEntry>. -->
						<tbx:entailedTerm target="{xref/@target}">
							<xsl:choose>
								<xsl:when test="renderterm">
									<xsl:value-of select="renderterm"/>
									
									<xsl:variable name="xref_target" select="xref/@target"/>
									<xsl:variable name="element_xref_" select="$elements//element[@source_id = $xref_target]"/>
									<xsl:variable name="element_xref" select="xalan:nodeset($element_xref_)"/>
									<xsl:variable name="section" select="$element_xref/@section"/>
									<xsl:text> (</xsl:text><xsl:value-of select="$section"/><xsl:text>)</xsl:text>
									
								</xsl:when>
								<xsl:otherwise>
									<xsl:attribute name="target"><xsl:value-of select=".//tt[2]"/></xsl:attribute>
									<xsl:value-of select=".//tt[1]"/>
								</xsl:otherwise>
							</xsl:choose>
						</tbx:entailedTerm>
					</xsl:when>
					<xsl:otherwise>
						<!-- Outside the terms and definitions section, references to terms contained within the document should be made using the id in the terminological entry. -->
						<xref>
							<xsl:attribute name="ref-type">
								<xsl:if test="$metanorma_type = 'IEC'">other</xsl:if>
								<xsl:if test="$metanorma_type = 'ISO'">sec</xsl:if>
							</xsl:attribute>
							<xsl:attribute name="rid"><xsl:value-of select="xref/@target"/></xsl:attribute>
							<xsl:choose>
								<xsl:when test="renderterm"><xsl:value-of select="renderterm"/></xsl:when>
								<xsl:otherwise>
									<xsl:attribute name="rid"><xsl:value-of select=".//tt[2]"/></xsl:attribute>
									<xsl:value-of select=".//tt[1]"/>
								</xsl:otherwise>
							</xsl:choose>
						</xref>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<!-- for BSI -->
				<named-content content-type="term" xlink:href="#{xref/@target}">
					<xsl:choose>
						<xsl:when test="renderterm"><xsl:value-of select="renderterm"/></xsl:when>
						<xsl:otherwise>
							<xsl:attribute name="xlink:href">#<xsl:value-of select=".//tt[2]"/></xsl:attribute>
							<xsl:value-of select=".//tt[1]"/>
						</xsl:otherwise>
					</xsl:choose>
				</named-content>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="li/table" priority="2">
		<p>
			<xsl:call-template name="table"/>
		</p>
	</xsl:template>
	
	<xsl:template match="table" name="table"> <!-- [*[local-name() = 'name']] -->
		<xsl:param name="skip">true</xsl:param>
		
		<xsl:variable name="process">
			<xsl:choose>
				<xsl:when test="$outputformat = 'IEEE' and $skip = 'true' and preceding-sibling::*[1][self::p] and normalize-space(java:endsWith(java:java.lang.String.new(normalize-space(preceding-sibling::*[1][self::p])),'.')) = 'false'">false</xsl:when>
				<xsl:otherwise>true</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:if test="$process = 'true'">
	
			<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
			
			<xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable>
			
			<xsl:variable name="isInformalTable" select="normalize-space(not(name))"/> <!-- not(label) and not(caption) -->
			
			<xsl:variable name="wrap-element">
				<xsl:choose>
					<xsl:when test="($metanorma_type = 'IEC' or $metanorma_type = 'ISO') and ($isInformalTable = 'true' or starts-with(@id, 'array_'))">array</xsl:when> <!-- 6.4: An informal table does not have a caption (label and title) and is captured as a <table> in <array>. -->
					<xsl:when test="ancestor::figure">array</xsl:when>
					<xsl:otherwise>table-wrap</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			
			<xsl:element name="{$wrap-element}">
			<!-- <table-wrap id="{$id}"> --> <!-- position="float" -->
				<xsl:if test="not($outputformat = 'IEEE' and starts-with(@id,'_'))">
					<xsl:attribute name="id">
						<xsl:value-of select="$id"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:variable name="orientation" select="normalize-space(preceding-sibling::*[1][self::pagebreak]/@orientation)"/>
				<xsl:if test="$orientation = 'landscape'">
					<xsl:attribute name="orientation"><xsl:value-of select="$orientation"/></xsl:attribute>
				</xsl:if>
				
				<xsl:variable name="isKeyTable" select="normalize-space(preceding-sibling::*[1][self::figure] and (name/text() = 'Key' or name/text() = 'Table &#160;&#8212; Key'))"/>
				
				<xsl:variable name="isWhereTable" select="normalize-space(preceding-sibling::*[1][self::stem] or (preceding-sibling::*[1][self::p][text() = 'where:'] and preceding-sibling::*[2][self::stem]))"/>
				
				<xsl:if test="$wrap-element = 'table-wrap'">
					<xsl:if test="ancestor::preface">
						<xsl:choose>
							<xsl:when test="starts-with(preceding-sibling::*[self::title]/text(), 'Amendments')">
								<xsl:attribute name="content-type">ace-table</xsl:attribute>
							</xsl:when>
							<xsl:when test="$isInformalTable = 'true'">
								<xsl:attribute name="content-type">informal-table</xsl:attribute>
							</xsl:when>
						</xsl:choose>
					</xsl:if>
					<xsl:if test="not(ancestor::preface and starts-with(preceding-sibling::*[self::title]/text(), 'Amendments'))">
						<xsl:attribute name="position">
							<xsl:choose>
								<xsl:when test="$outputformat = 'IEEE'">anchor</xsl:when>
								<xsl:otherwise>float</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
					</xsl:if>
					<!-- https://github.com/metanorma/mn-samples-bsi/issues/39 -->
					<!-- <xsl:if test="starts-with(title/text(), 'Relationship between') or starts-with(title/text(), 'Correspondence between')">
						norm-refs
					</xsl:if> -->
					<xsl:if test="$isWhereTable = 'true'">
						<xsl:attribute name="content-type">formula-index</xsl:attribute>
					</xsl:if>
					<xsl:if test="$isKeyTable = 'true'">
						<xsl:attribute name="content-type">fig-index</xsl:attribute>
					</xsl:if>
					<xsl:variable name="processing_instruction_content_type" select="normalize-space(preceding-sibling::*[1]/processing-instruction('content-type'))"/>
					<xsl:if test="$processing_instruction_content_type != ''">
						<xsl:attribute name="content-type"><xsl:value-of select="$processing_instruction_content_type"/></xsl:attribute>
					</xsl:if>
					
					<xsl:call-template name="addSectionAttribute"/>
					
					<!-- for requirements -->
					<xsl:if test="@type">
						<xsl:attribute name="content-type"><xsl:value-of select="@type"/></xsl:attribute>
					</xsl:if>
					<xsl:if test="@class">
						<xsl:attribute name="specific-use"><xsl:value-of select="@class"/></xsl:attribute>
					</xsl:if>
					
				</xsl:if>
				<xsl:variable name="label">
					<xsl:choose>
						<xsl:when test="ancestor::amend/autonumber[@type = 'table']">
							<xsl:value-of select="ancestor::amend/autonumber[@type = 'table']/text()"/>
						</xsl:when>
						<xsl:when test="ancestor::figure"></xsl:when>
						<xsl:when test="$isKeyTable = 'true'">Key</xsl:when>
						<xsl:when test="@unnumbered = 'true'"></xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="@section_prefix"/><xsl:value-of select="@section"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:if test="normalize-space($label) != ''">
					<label>
						<xsl:value-of select="$label"/>
					</label>
				</xsl:if>
				<xsl:if test="$isKeyTable = 'false' and $isWhereTable = 'false'">
					<xsl:apply-templates select="name" mode="table"/>
				</xsl:if>
				<table>
					<xsl:copy-of select="@*[not(local-name() = 'id' or local-name() = 'unnumbered' or local-name() = 'section' or local-name() = 'section_prefix' or local-name() = 'width' or local-name() = 'class' or local-name() = 'type')]"/>
					<xsl:if test="$outputformat = 'IEEE'">
					 <xsl:attribute name="cellpadding">5</xsl:attribute>
					 <xsl:attribute name="frame">box</xsl:attribute>
					 <xsl:attribute name="rules">all</xsl:attribute>
					</xsl:if>
					<xsl:apply-templates select="@width"/>
					
					<xsl:apply-templates select="colgroup" mode="table"/>
					<xsl:apply-templates select="thead" mode="table"/>
					<xsl:apply-templates select="tfoot" mode="table"/>
					<xsl:apply-templates select="tbody" mode="table"/>
					<xsl:if test="not(tbody)">
						<xsl:call-template name="addEmpty_tbody"/>
					</xsl:if>
					<xsl:apply-templates />
				</table>
				
				<!-- <table-wrap>
				<table></table>
				<table></table>
				</table-wrap> -->
				<xsl:apply-templates select="following-sibling::*[1][self::table]" mode="table_wrap_multiple"/>
				
				<!-- move notes outside table -->
				<xsl:if test="note and $wrap-element != 'array'">
					<table-wrap-foot>
						<xsl:call-template name="insertTableFootNote"/>
					</table-wrap-foot>
				</xsl:if>
			<!-- </table-wrap> -->
			</xsl:element>
			
			<xsl:if test="note and $wrap-element = 'array'">
				<xsl:call-template name="insertTableFootNote"/>
			</xsl:if>
			
		</xsl:if>
	</xsl:template>

	<xsl:template name="insertTableFootNote">
		<xsl:choose>
			<xsl:when test="$outputformat = 'IEEE'">
				<p>
					<xsl:for-each select="note">
						<xsl:call-template name="note"/>
					</xsl:for-each>
				</p>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="note">
					<xsl:call-template name="note"/>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="addEmpty_tbody">
		<xsl:variable name="col_count">
			<xsl:choose>
				<xsl:when test="colgroup">
					<xsl:value-of select="count(colgroup//col)"/>
				</xsl:when>
				<xsl:when test="thead">
					<xsl:variable name="cols">
						<xsl:for-each select="thead/tr[1]/*">
							<col>
								<xsl:choose>
									<xsl:when test="@colspan"><xsl:value-of select="@colspan"/></xsl:when>
									<xsl:otherwise>1</xsl:otherwise>
								</xsl:choose>
							</col>
						</xsl:for-each>
					</xsl:variable>
					<xsl:value-of select="sum(xalan:nodeset($cols)/col)"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<tbody>
			<tr>
				<xsl:call-template name="addEmpty_td">
					<xsl:with-param name="count" select="$col_count"/>
				</xsl:call-template>
			</tr>
		</tbody>
	</xsl:template>
	<xsl:template name="addEmpty_td">
		<xsl:param name="count"/>
		<xsl:if test="$count &gt; 0">
			<td valign="top" align="left"> </td>
			<xsl:call-template name="addEmpty_td">
				<xsl:with-param name="count" select="$count - 1"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<!-- ========================================= -->
	<!-- <table-wrap>
	<table></table>
	<table></table>
	</table-wrap> -->
	<!-- ========================================= -->
	<xsl:template match="table[preceding-sibling::*[1][self::table]]" priority="2">
		<xsl:variable name="first_table_id" select="preceding-sibling::table[not(preceding-sibling::table)][1]/@id"/>
		<xsl:if test="not(starts-with(@id, concat($first_table_id, '_')))">
			<xsl:call-template name="table"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="table" mode="table_wrap_multiple">
		<xsl:variable name="first_table_id" select="preceding-sibling::table[not(preceding-sibling::table)][1]/@id"/>

		<xsl:if test="starts-with(@id, concat($first_table_id, '_'))">
			<table>
				<xsl:copy-of select="@*[not(local-name() = 'id' or local-name() = 'unnumbered' or local-name() = 'section' or local-name() = 'section_prefix' or local-name() = 'width')]"/>
				<xsl:apply-templates select="@width"/>
				
				<xsl:apply-templates select="colgroup" mode="table"/>
				<xsl:apply-templates select="thead" mode="table"/>
				<xsl:apply-templates select="tfoot" mode="table"/>
				<xsl:apply-templates select="tbody" mode="table"/>
				<xsl:apply-templates />
			</table>
			<xsl:apply-templates select="following-sibling::*[1][self::table]" mode="table_wrap_multiple"/>
		</xsl:if>
	</xsl:template>
	<!-- ========================================= -->
	<!-- END -->
	<!-- <table-wrap>
	<table></table>
	<table></table>
	</table-wrap> -->
	<!-- ========================================= -->
	
	<xsl:template match="table/@width">
		<xsl:choose>
			<xsl:when test="$metanorma_type = 'IEC'"><!-- no absolute number of pixels is indicated for table width. --></xsl:when>
			<xsl:otherwise>
				<xsl:attribute name="width">
					<xsl:choose>
						<xsl:when test="contains(., 'px')">
							<xsl:value-of select="substring-before(., 'px')"/>
						</xsl:when>
						<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="table/note" priority="2"/>
	
	<xsl:template match="name"/>
	<xsl:template match="name" mode="table">
		<caption>
			<title>
				<xsl:apply-templates/>
			</title>
		</caption>
	</xsl:template>
	
	<xsl:template match="colgroup | thead | tfoot | tbody"/>
	
	<xsl:template match="colgroup" mode="table">
		<xsl:choose>
			<xsl:when test="$metanorma_type = 'ISO'">
				<!-- skip creation of element colgroup, just copy nested col -->
				<xsl:apply-templates />
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="{local-name()}">
					<xsl:copy-of select="@*"/>
					<xsl:apply-templates />
				</xsl:element>	
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="colgroup/col">
		<xsl:choose>
			<xsl:when test="$outputformat = 'IEEE'">
				<xsl:copy></xsl:copy>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="thead | tfoot | tbody" mode="table">
		<xsl:element name="{local-name()}">
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates />
		</xsl:element>	
	</xsl:template>
	
	<xsl:template match="td | th">
		<xsl:element name="{local-name()}"> <!-- <th> <td> -->
			<xsl:choose>
				<xsl:when test="$outputformat = 'IEEE' and p/@align[. = 'justified']">
					<xsl:attribute name="align">justify</xsl:attribute>
				</xsl:when>
				<xsl:when test="$outputformat = 'IEEE' and @align='left' and @valign='top'">
					<xsl:apply-templates select="@*[local-name() != 'align' and local-name() != 'valign']"/>
					<xsl:if test="@colspan">
						<xsl:apply-templates select="@align"/>
					</xsl:if>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="@*"/>
				</xsl:otherwise>
			</xsl:choose>
			
			<xsl:choose>
				<xsl:when test="local-name() = 'th' and $metanorma_type = 'ISO' and not(node()[normalize-space != ''][1] != 'strong')">
					<!-- For ISO only - enclose table cells text in bold  -->
					<xsl:variable name="th_text_">
						<xsl:apply-templates />
					</xsl:variable>
					<xsl:variable name="th_text" select="xalan:nodeset($th_text_)"/>
					
					<xsl:choose>
						<xsl:when test="$th_text/break">
							<xsl:for-each select="$th_text/break">
								<xsl:variable name="curr_id" select="generate-id()"/>
								<xsl:choose>
									<xsl:when test="not(preceding-sibling::break)">
										<bold>
											<xsl:copy-of select="preceding-sibling::node()[following-sibling::break[1][generate-id() = $curr_id]]"/>
										</bold>
										<break/>
									</xsl:when>
									<xsl:when test="preceding-sibling::break">
										<bold>
											<xsl:copy-of select="preceding-sibling::break/following-sibling::node()[following-sibling::break[1][generate-id() = $curr_id]]"/>
										</bold>
										<break/>
									</xsl:when>
								</xsl:choose>
								<xsl:if test="not(following-sibling::break)">
									<bold>
										<xsl:copy-of select="following-sibling::node()"/>
									</bold>
								</xsl:if>
							</xsl:for-each>
						</xsl:when>
						<xsl:otherwise>
							<bold>
								<xsl:copy-of select="$th_text"/>
							</bold>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				
				<xsl:otherwise>
					<xsl:apply-templates />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
	</xsl:template>
	
	
	<!-- =============================== -->
	<!-- Definitions list processing -->
	<!-- =============================== -->
	<xsl:template match="dl">
		<xsl:param name="skip">true</xsl:param>
		<xsl:choose>
			<xsl:when test="preceding-sibling::*[1][self::figure] or preceding-sibling::*[1][self::stem]">
				<xsl:call-template name="create_array"/>
			</xsl:when>
			<xsl:when test="$metanorma_type = 'ISO' and @key = 'true'">
				<table-wrap content-type="fig-index">
					<xsl:if test="not(starts-with(@id,'_'))">
						<xsl:copy-of select="@id"/>
					</xsl:if>
					<caption><title>Key</title></caption>
					<table>
						<tbody>
							<xsl:apply-templates>
								<xsl:with-param name="add_default_attributes">false</xsl:with-param>
							</xsl:apply-templates>
						</tbody>
					</table>
				</table-wrap>
			</xsl:when>
			<xsl:otherwise>
				<def-list>
					<xsl:if test="not(starts-with(@id,'_'))">
						<xsl:copy-of select="@id"/>
					</xsl:if>
					
					<xsl:if test="$metanorma_type = 'IEC' and @key = 'true'">
						<xsl:attribute name="list-content">figure</xsl:attribute>
					</xsl:if>
					
					<xsl:if test="preceding-sibling::*[1][self::title][contains(normalize-space(), 'Abbrev')] or 
					(($metanorma_type = 'IEC' or $metanorma_type = 'ISO') and (dt[starts-with(@id, 'abb-')] or dt[starts-with(@id, 'abb_')]))">
						<xsl:attribute name="list-type">
							<xsl:choose>
								<xsl:when test="$metanorma_type = 'IEC' or $metanorma_type = 'ISO'">abbreviation</xsl:when>
								<xsl:otherwise>abbreviations</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
					</xsl:if>
					
					<xsl:if test="$metanorma_type = 'IEC' and @key = 'true'">
						<label>Key</label>
					</xsl:if>
					
					<xsl:apply-templates select="node()[not(self::note)]" mode="dl"/>
				</def-list>
				<!-- move notes outside dl -->
				<xsl:for-each select="note">
					<xsl:call-template name="note"/>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="create_array">
		<!-- <xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable> -->
		<xsl:if test="preceding-sibling::*[1][self::stem] and not(ancestor::formula)">
			<p>where:</p>
		</xsl:if>
		<array> <!-- id="{$id}" -->
			<xsl:copy-of select="@id"/>
			<xsl:if test="preceding-sibling::*[1][self::figure]">
				<xsl:attribute name="content-type">figure-index</xsl:attribute>
			</xsl:if>
			<xsl:if test="preceding-sibling::*[1][self::stem]">
				<xsl:attribute name="content-type">formula-index</xsl:attribute>
			</xsl:if>
			<xsl:if test="@key = 'true'">
				<label>Key</label>
			</xsl:if>
			<table>
				<tbody>
					<xsl:apply-templates />
				</tbody>
			</table>
		</array>
		<!-- move notes outside table -->
		<xsl:for-each select="note">
			<xsl:call-template name="note"/>
		</xsl:for-each>
	</xsl:template>
		
	<xsl:template match="dl/note" priority="2"/>
		
	<xsl:template match="dt">
		<xsl:param name="add_default_attributes">true</xsl:param>
		<tr>
			<td>
				<xsl:if test="$add_default_attributes = 'true'">
					<xsl:attribute name="align">left</xsl:attribute>
					<xsl:attribute name="scope">row</xsl:attribute>
					<xsl:attribute name="valign">top</xsl:attribute>
				</xsl:if>
				<xsl:apply-templates/>
			</td>
			<xsl:apply-templates select="following-sibling::dd[1]" mode="array">
				<xsl:with-param name="add_default_attributes" select="$add_default_attributes"/>
			</xsl:apply-templates>
		</tr>
	</xsl:template>
	
	<xsl:template match="dd"/>
	<xsl:template match="dd" mode="array">
		<xsl:param name="add_default_attributes">true</xsl:param>
		<td>
			<xsl:if test="$add_default_attributes = 'true'">
				<xsl:attribute name="align">left</xsl:attribute>
				<xsl:attribute name="valign">top</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
		</td>
	</xsl:template>
	
	<xsl:template match="dt" mode="dl">
		<def-item>
			<xsl:copy-of select="@id"/>
			<term>
				<xsl:apply-templates />
			</term>
			<def>
				<xsl:apply-templates select="following-sibling::dd[1]" mode="dd"/>
			</def>
		</def-item>
	</xsl:template>
	
	<xsl:template match="dd" mode="dl"/>
	<xsl:template match="dd" mode="dd">
		<p>
			<xsl:copy-of select="p[1]/@id"/>
			
			<xsl:apply-templates />
		</p>
	</xsl:template>
	
	
	<!-- =============================== -->
	<!-- END Definitions list processing -->
	<!-- =============================== -->
	
	<xsl:template match="figure[figure]" priority="1">
		
		<xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable>
		
		<xsl:variable name="element_name">
			<xsl:choose>
				<xsl:when test="$organization = 'BSI'">fig</xsl:when>
				<xsl:otherwise>fig-group</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:element name="{$element_name}">
			<xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
			<xsl:if test="$element_name = 'fig-group'">
				<xsl:attribute name="content-type">figures</xsl:attribute>
			</xsl:if>
			<xsl:call-template name="addSectionAttribute"/>
			
			<label><xsl:value-of select="@section"/></label>
			<xsl:apply-templates />
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="li/figure" priority="2">
		<p>
			<xsl:call-template name="figure"/>
		</p>
	</xsl:template>
	
	<xsl:template match="figure" name="figure">
		
		<xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable>
		
		<xsl:choose>
			<xsl:when test="$organization = 'BSI' and parent::figure">
				<graphic xlink:href="{image/@src}">
					<xsl:apply-templates select="*[not(self::image)]"/>
				</graphic>
			</xsl:when>
			<xsl:otherwise>	
				<fig id="{$id}">
					<xsl:if test="$outputformat != 'IEEE'">
						<xsl:attribute name="fig-type">figure</xsl:attribute>
					</xsl:if>
					<xsl:if test="$outputformat = 'IEEE'">
						<xsl:attribute name="position">anchor</xsl:attribute>
					</xsl:if>
					<xsl:call-template name="addSectionAttribute"/>
					
					<label>
						<xsl:choose>
							<xsl:when test="ancestor::amend/autonumber[@type = 'figure']">
								<xsl:value-of select="ancestor::amend/autonumber[@type = 'figure']/text()"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="@section_prefix"/><xsl:value-of select="@section"/>
							</xsl:otherwise>
						</xsl:choose>
					</label>
					<xsl:apply-templates />
				</fig>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template match="figure/name" priority="2">
		<xsl:variable name="label" select="substring-before(node()[1][self::text()], '&#xa0;')"/>
		<xsl:if test="../parent::figure and $organization = 'BSI' and normalize-space($label) != ''">
			<label><xsl:value-of select="$label"/></label>
		</xsl:if>
		<caption>
			<xsl:choose>
				<xsl:when test="$outputformat = 'IEEE'">
					<p>
						<xsl:apply-templates/>
					</p>
				</xsl:when>
				<xsl:otherwise>
					<title>
						<xsl:apply-templates/>
					</title>
				</xsl:otherwise>
			</xsl:choose>
		</caption>
	</xsl:template>
	
	<xsl:template match="*[self::table or self::figure]/name/node()[1][self::text()]" priority="2">
		<xsl:choose>
			<xsl:when test="$isSemanticXML = 'true'"><xsl:value-of select="."/></xsl:when> <!-- there isn't 'Table N — ' in the Metanorma semantic XML -->
			<xsl:when test="contains(., '—')">
				<xsl:value-of select="normalize-space(substring-after(., '—'))"/>
			</xsl:when>
			<xsl:when test="../parent::figure and contains(., '&#xa0;')"><!-- move text like 'a)' to label, see above -->
				<xsl:value-of select="normalize-space(substring-after(., '&#xa0;'))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="figure/image">
		<!--<xsl:variable name="current_id">
			<xsl:call-template name="getId"/>
		</xsl:variable>
		 <xsl:variable name="id" select="$elements//element[@source_id = $current_id]/@id"/> -->
		<!-- <xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable> -->
		<!-- NISO STS TagLibrary: https://www.niso-sts.org/TagLibrary/niso-sts-TL-1-0-html/element/graphic.html -->
		<graphic xlink:href="{@id}"> <!-- id="{$id}"  xlink:href="{$id}"-->
			<xsl:if test="$outputformat != 'IEEE'">
				<xsl:copy-of select="@id"/>
			</xsl:if>
			<!-- <xsl:copy-of select="@mimetype"/> -->
			<xsl:choose>
				<xsl:when test="$outputformat = 'IEEE'">
					<xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="@*"/>
				</xsl:otherwise>
			</xsl:choose>
			<!-- https://github.com/metanorma/mn-samples-bsi/issues/25 -->
			<!-- <xsl:processing-instruction name="isoimg-id">
				<xsl:value-of select="@src"/>
			</xsl:processing-instruction> -->
			
		</graphic>
	</xsl:template>
	
  <xsl:template match="image[not(parent::figure)]">
    <graphic>
			<xsl:choose>
				<xsl:when test="$outputformat = 'IEEE'">
					<xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="@*"/>
				</xsl:otherwise>
			</xsl:choose>
		</graphic>
  </xsl:template>
  
	<xsl:template match="image/@src">
		<xsl:attribute name="xlink:href">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:template>
	
	<xsl:template match="image/@mimetype">
		<xsl:if test="$outputformat != 'IEEE'">
			<xsl:copy-of select="."/>
		</xsl:if>
	</xsl:template> <!-- created image processing -->
	<xsl:template match="image/@alt">
		<xsl:element name="alt-text">
			<xsl:value-of select="."/>
		</xsl:element>
	</xsl:template>
	<xsl:template match="image/@height"/>	
	<xsl:template match="image/@width"/>	
	
	
	<xsl:template match="*[local-name() = 'svg']">
		<xsl:variable name="svg_string">
			<xsl:apply-templates select="." mode="print_as_xml"/>
		</xsl:variable>
		<xsl:variable name="svg_string_base64" select="java:org.metanorma.utils.Base64Helper.encodeBase64($svg_string)"/>
		<graphic xlink:href="data:image/svg+xml;base64,{$svg_string_base64}" mimetype="image/svg+xml"/>
	</xsl:template>
	
	<xsl:template match="formula">
		<xsl:param name="skip">true</xsl:param>
		
		<xsl:variable name="process">
			<xsl:choose>
				<xsl:when test="$outputformat = 'IEEE' and $skip = 'true' and normalize-space(java:endsWith(java:java.lang.String.new(normalize-space(preceding-sibling::*[1][self::p])),':')) = 'true'">false</xsl:when>
				<xsl:otherwise>true</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:if test="$process = 'true'">
		
			<xsl:if test="parent::th[strong]">
				<xsl:text disable-output-escaping="yes">&lt;/bold&gt;</xsl:text>
			</xsl:if>
		
			<xsl:variable name="id"><xsl:if test="stem and not(starts-with(@id,'_'))"><xsl:value-of select="@id"/></xsl:if></xsl:variable>
			
			<xsl:variable name="disp-formula">
				<disp-formula>
					<xsl:if test="$id != ''">
						<xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
					</xsl:if>
					<xsl:call-template name="addSectionAttribute"/>
					<xsl:apply-templates />
				</disp-formula>
			</xsl:variable>
			
			<xsl:choose>
				<xsl:when test="$outputformat = 'IEEE' and normalize-space(java:endsWith(java:java.lang.String.new(normalize-space(preceding-sibling::*[1][self::p])),':')) = 'false' and not(parent::dd)"> <!-- and not(parent::p) -->
					<p>
						<xsl:copy-of select="$disp-formula"/>
					</p>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="$disp-formula"/>
				</xsl:otherwise>
			</xsl:choose>
			
			<xsl:if test="parent::th[strong]">
				<xsl:text disable-output-escaping="yes">&lt;bold&gt;</xsl:text>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="formula/stem" priority="2">
		
		<xsl:if test="$isSemanticXML = 'true' and not(name)">
			<xsl:variable name="formula_id" select="../@id"/>
			<xsl:variable name="section" select="normalize-space(../@section)"/>
			<xsl:if test="$section != '' and not(../@unnumbered=  'true') and not($outputformat = 'IEEE')">
				<label><xsl:value-of select="$section"/></label>
			</xsl:if>
		</xsl:if>
		
		<xsl:apply-templates />
	</xsl:template>
	
	
	<!-- special case: <stem type="MathML"><math xmlns="http://www.w3.org/1998/Math/MathML"><mi>R</mi></math>< ! - - R - - > </stem><sub>1</sub> -->
	<xsl:template match="stem[count(mml:math/*) = 1 and mml:math/mml:mi and following-sibling::node()[normalize-space() != ''][1][self::sub or self::sup]]">
		<styled-content style="font-weight: italic; font-family: Times New Roman"><xsl:value-of select="mml:math/mml:mi"/></styled-content>
	</xsl:template>
	
	
	<xsl:template match="stem">
		<inline-formula>
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates />
		</inline-formula>
	</xsl:template>
	
	<xsl:template match="mml:*">
		<xsl:element name="mml:{local-name()}">		
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="asciimath[following-sibling::latexmath or preceding-sibling::latexmath or following-sibling::mml:math or preceding-sibling::mml:math]"/>
	
	<!-- if there latexmath, then ignore mathml -->
	<xsl:template match="mml:math[following-sibling::latexmath or preceding-sibling::latexmath]"/>
	
	<xsl:template match="latexmath">
		<xsl:variable name="latex"><xsl:apply-templates/></xsl:variable>
		<tex-math notation="LaTeX">
			<xsl:choose>
				<xsl:when test="starts-with(normalize-space($latex),'\[')"><xsl:value-of select="$latex"/></xsl:when>
				<xsl:otherwise><xsl:text>$</xsl:text><xsl:value-of select="$latex"/><xsl:text>$</xsl:text></xsl:otherwise>
			</xsl:choose>
		</tex-math>
	</xsl:template>
	
	<xsl:template match="tt | identifier[not(ancestor::requirement)]">
		<monospace>
			<xsl:apply-templates/>
		</monospace>
	</xsl:template>
	
	<xsl:template match="smallcap">
		<sc>
			<xsl:apply-templates/>
		</sc>
	</xsl:template>
	
	<xsl:template match="review">
		<xsl:if test="($metanorma_type = 'IEC' or $metanorma_type = 'ISO') and $format = 'NISO'">
			<editing-instruction specific-use="review">
				<xsl:apply-templates/>
			</editing-instruction>
		</xsl:if>
	</xsl:template>

	<xsl:template match="sourcecode">
		<xsl:param name="skip">true</xsl:param>
		
		<xsl:variable name="process">
			<xsl:choose>
				<xsl:when test="$outputformat = 'IEEE' and $skip = 'true' and preceding-sibling::*[1][self::p] and normalize-space(java:endsWith(java:java.lang.String.new(normalize-space(preceding-sibling::*[1][self::p])),'.')) = 'false'">false</xsl:when>
				<xsl:otherwise>true</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:if test="$process = 'true'">
	
			<xsl:choose>
				<xsl:when test="$format = 'NISO' and $outputformat != 'IEEE'">
					<code>
						<xsl:apply-templates select="@*"/>
						<xsl:apply-templates/>
					</code>
				</xsl:when>
				<!-- ISO -->
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="$outputformat = 'IEEE' and normalize-space(@lang) != ''">
							<code>
								<xsl:if test="@lang != 'EXPRESS'">
									<xsl:attribute name="code-type"><xsl:value-of select="@lang"/></xsl:attribute>
								</xsl:if>
								<xsl:attribute name="position">anchor</xsl:attribute>
								<xsl:attribute name="xml:space">preserve</xsl:attribute>
								<xsl:apply-templates/>
							</code>
						</xsl:when>
						<xsl:otherwise>
							<preformat>
								<xsl:if test="@lang">
									<xsl:attribute name="preformat-type">
										<xsl:value-of select="@lang"/>
									</xsl:attribute>
								</xsl:if>
								<xsl:apply-templates/>
							</preformat>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="sourcecode/@lang">
		<xsl:attribute name="language">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:template>
	
	<xsl:template match="sourcecode/@unnumbered"/>
	
	<xsl:template match="title" name="title">
		<xsl:choose>
			<xsl:when test="not(tab) and normalize-space(translate(., '0123456789.', '')) = ''"><!-- put number in label, see above --></xsl:when>
			
			 <!-- amendment title with section number and title : 5.5.1, fourth paragraph -->
			<xsl:when test="not(tab) and following-sibling::amend and normalize-space(translate(substring-before(., ','), '0123456789.', '')) = '' and contains (node()[1], ',')">
			<!-- put number in label, see above -->
				<title>
					<xsl:for-each select="node()">
						<xsl:choose>
							<xsl:when test="position() = 1">
								<xsl:value-of select="substring-after(., ',')"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:apply-templates/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</title>
			</xsl:when>
			
			<xsl:otherwise>
				<title>
					<xsl:choose>
						<xsl:when test="tab">
							<xsl:apply-templates select="tab[1]/following-sibling::node()"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates />
						</xsl:otherwise>
					</xsl:choose>
				</title>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="title/@depth"/>
	<xsl:template match="tab">
		<xsl:if test="parent::*[self::p and @type = 'section-title' or local-name() = 'section-title']"><xsl:text>: </xsl:text></xsl:if> <!-- replace 'tab' to ': ' for 'Section x' -->
	</xsl:template>
	
	<!-- special case -->
	<xsl:variable name="annex_integral_part_text">(This annex forms an integral part of this </xsl:variable>
	<xsl:template match="annex/title//text()[contains(., $annex_integral_part_text)]">
		<xsl:value-of select="substring-before(., $annex_integral_part_text)"/>
		<styled-content style-type="normal">
			<xsl:value-of select="$annex_integral_part_text"/>
			<xsl:value-of select="substring-before(substring-after(., $annex_integral_part_text), ')')"/>
			<xsl:text>)</xsl:text>
		</styled-content>
		<xsl:value-of select="substring-after(substring-after(., $annex_integral_part_text), ')')"/>
	</xsl:template>
	
	
	<!-- ========================= -->
	<!-- Amendment -->
	<!-- ========================= -->
	<xsl:template match="amend">
		<!-- <p id="{@id}"> -->
			<xsl:apply-templates />
		<!-- </p> -->
	</xsl:template>
	
	<xsl:template match="amend/description">
		<xsl:choose>
			<xsl:when test="$format = 'NISO'">
				<editing-instruction>
					<xsl:if test="parent::amend/@id">
						<xsl:attribute name="id">
							<xsl:value-of select="parent::amend/@id"/>
							<xsl:variable name="pos"><xsl:number/></xsl:variable>
							<xsl:if test="number($pos) &gt; 1">_<xsl:value-of select="$pos"/></xsl:if>
						</xsl:attribute>
					</xsl:if>
					<xsl:if test="../@change">
						<xsl:attribute name="content-type">
							<xsl:value-of select="../@change"/>
						</xsl:attribute>
					</xsl:if>
					<xsl:apply-templates />
				</editing-instruction>	
			</xsl:when>
			<!-- ISO -->
			<xsl:otherwise>
				<xsl:apply-templates />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="amend/description/p">
		<xsl:choose>
			<xsl:when test="$format = 'NISO'">
				<xsl:call-template name="p"/>
			</xsl:when>
			<xsl:otherwise>
				<p id="{@id}">
					<xsl:if test="ancestor::amend/@change">
						<xsl:attribute name="content-type">
							<xsl:value-of select="ancestor::amend/@change"/>
						</xsl:attribute>
					</xsl:if>
					<xsl:apply-templates />
				</p>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="amend/newcontent">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="amend/autonumber"/>
	<!-- ========================= -->
	<!-- END: Amendment -->
	<!-- ========================= -->
	
	
	<xsl:template match="comment()[starts-with(., 'STS: ')]">
		<xsl:value-of disable-output-escaping="yes" select="substring-after(., 'STS: ')"/>
	</xsl:template>

	<xsl:template match="bookmark">
		<xsl:apply-templates/>
	</xsl:template>
	
	<!-- =================== -->
	<!-- Index processing    -->
	<!-- =================== -->
	<xsl:template name="insertIndex">
		<xsl:apply-templates select="indexsect"/>
		<xsl:if test=".//index">
			<xsl:choose>
				<xsl:when test="$format = 'NISO' and not($organization = 'BSI')">
					<index>
						<index-title-group>
							<title>INDEX</title>
						</index-title-group>
						
						<xsl:variable name="index_entries_">
							<xsl:for-each select=".//index">
								<xsl:sort select="primary"/>
								<xsl:apply-templates select="primary">
									<xsl:with-param name="mode">NISO</xsl:with-param>
								</xsl:apply-templates>
							</xsl:for-each>
						</xsl:variable>
						<xsl:variable name="index_entries" select="xalan:nodeset($index_entries_)"/>
						
						<xsl:variable name="index_letters">
							<xsl:for-each select="$index_entries/*">
								<xsl:variable name="letter" select="@letter"/>
								<xsl:if test="not(preceding-sibling::*[@letter = $letter])">
									<letter><xsl:value-of select="$letter"/></letter>
								</xsl:if>
							</xsl:for-each>
						</xsl:variable>
						
						<xsl:for-each select="xalan:nodeset($index_letters)/*">
							<xsl:variable name="letter" select="."/>
							<index-div>
								<index-title-group>
									<title><xsl:value-of select="$letter"/></title>
								</index-title-group>
								<xsl:for-each select="$index_entries/*[@letter = $letter]">
									<xsl:copy>
										<xsl:copy-of select="@*[local-name() != 'letter']"/>
										<xsl:if test="$metanorma_type = 'IEC'">
											<xsl:attribute name="id">df-<xsl:number /></xsl:attribute>
										</xsl:if>
										<xsl:copy-of select="node()"/>
										<xsl:if test="$metanorma_type = 'IEC'">
											<see-entry>df <xsl:number /></see-entry>
										</xsl:if>
									</xsl:copy>
								</xsl:for-each>
							</index-div>
						</xsl:for-each>
						
					</index>
				</xsl:when>
				<xsl:otherwise>
					<sec sec-type="index">
						<title>Index</title>
						<list list-type="simple">
							<!-- Example:
								<list-item>
									<p>abstentions, <xref ref-type="sec" rid="sec_7.7">7.7</xref>
									</p>
								</list-item>
							-->
							<xsl:for-each select=".//index">
								<xsl:sort select="primary"/>
								<xsl:apply-templates select="." mode="index_item"/>
							</xsl:for-each>
						</list>
					</sec>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="index"/> <!-- process in 'insertIndex' -->
	<xsl:template match="index" mode="index_item">
		<xsl:param name="mode"/>
		<xsl:choose>
			<xsl:when test="$mode = 'NISO'">
				<xsl:apply-templates select="primary">
					<xsl:with-param name="mode">NISO</xsl:with-param>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<list-item>
					<p>
						<xsl:apply-templates select="primary"/>
					</p>
					<xsl:apply-templates select="secondary"/>
				</list-item>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="index/primary">
		<xsl:param name="mode"/>
		<xsl:call-template name="insert_index_reference">
			<xsl:with-param name="mode"><xsl:value-of select="$mode"/></xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="index/secondary">
		<list list-type="simple">
			<list-item>
				<p>
					<xsl:call-template name="insert_index_reference"/>
				</p>
				<xsl:apply-templates select="../tertiary"/>
			</list-item>
		</list>
	</xsl:template>
	
	<xsl:template match="index/tertiary">
		<list list-type="simple">
			<list-item>
				<p>
					<xsl:call-template name="insert_index_reference"/>
				</p>
			</list-item>
		</list>
	</xsl:template>
	
	<xsl:template name="insert_index_reference">
		<xsl:param name="mode"/>
		<xsl:variable name="element_target_" select="ancestor::*[self::clause or self::term or self::definitions or self::terms][@id and @section][1]"/>
		<xsl:variable name="element_target" select="xalan:nodeset($element_target_)"/>
		<xsl:choose>
			<xsl:when test="$mode = 'NISO'">
				<index-entry>
					<xsl:variable name="term">
						<term>
							<xsl:apply-templates />
						</term>
					</xsl:variable>
					<xsl:if test="self::primary">
						<xsl:attribute name="letter"><xsl:value-of select="java:toUpperCase(java:java.lang.String.new(substring(normalize-space($term),1,1)))"/></xsl:attribute>
					</xsl:if>
					<xsl:copy-of select="$term"/>
					<xsl:choose>
						<xsl:when test="$metanorma_type = 'IEC'">
							<see-entry><xsl:value-of select="$element_target/@section"/></see-entry>
						</xsl:when>
						<xsl:otherwise>
							<nav-pointer-group>
								<nav-pointer specific-use="section" rid="{$element_target/@id}"/>
								<nav-pointer specific-use="section"><xsl:value-of select="$element_target/@section"/></nav-pointer>
							</nav-pointer-group>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:if test="self::primary">
						<xsl:for-each select="../secondary">
							<xsl:call-template name="insert_index_reference">
								<xsl:with-param name="mode">NISO</xsl:with-param>
							</xsl:call-template>
						</xsl:for-each>
					</xsl:if>
					<xsl:if test="self::secondary">
						<xsl:for-each select="../tertiary">
							<xsl:call-template name="insert_index_reference">
								<xsl:with-param name="mode">NISO</xsl:with-param>
							</xsl:call-template>
						</xsl:for-each>
					</xsl:if>
				</index-entry>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates /><xsl:text>, </xsl:text>
				<xref ref-type="sec" rid="{$element_target/@id}"><xsl:value-of select="$element_target/@section"/></xref>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="indexsect">
		<sec sec-type="index">
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates />
		</sec>
	</xsl:template>
	<!-- =================== -->
	<!-- End: Index processing -->
	<!-- =================== -->
	
	<!-- these attribute added on 'add_attributes' step -->
	<xsl:template match="@section | @section_prefix"/> 
	
	<xsl:template match="pagebreak">
		<xsl:choose>
			<xsl:when test="@orientation = 'landscape' and following-sibling::*[1][self::table]"></xsl:when> <!-- attribute orientation will be added in table-wrap element -->
			<xsl:when test="@orientation = 'portrait' and preceding-sibling::*[1][self::table] and preceding-sibling::*[2][self::pagebreak]"></xsl:when> <!-- attribute orientation  added in table-wrap element -->
			<xsl:otherwise>
				<xsl:processing-instruction name="Para">
					<xsl:text>Page_Break</xsl:text>
				</xsl:processing-instruction>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="add[not(contains(., 'ace-tag'))]">
		<styled-content>
			<xsl:choose>
				<xsl:when test="$metanorma_type = 'IEC'">
					<xsl:attribute name="specific-use">insert</xsl:attribute>
				</xsl:when>
				<xsl:when test="$metanorma_type = 'ISO'">
					<xsl:attribute name="style-type">addition</xsl:attribute>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="ancestor::table">
							<xsl:attribute name="style-type">addition</xsl:attribute>
						</xsl:when>
						<xsl:otherwise>
							<xsl:attribute name="style">addition</xsl:attribute>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:apply-templates/>
		</styled-content>
	</xsl:template>
	
	<xsl:template match="del[not(contains(., 'ace-tag'))]">
		<styled-content>
			<xsl:choose>
				<xsl:when test="$metanorma_type = 'IEC'">
					<xsl:attribute name="specific-use">delete</xsl:attribute>
				</xsl:when>
				<xsl:when test="$metanorma_type = 'ISO'">
					<xsl:attribute name="style-type">deletion</xsl:attribute>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="ancestor::table">
							<xsl:attribute name="style-type">deletion</xsl:attribute>
						</xsl:when>
						<xsl:otherwise>
							<xsl:attribute name="style">deletion</xsl:attribute>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:apply-templates/>
		</styled-content>
	</xsl:template>

	<!-- ======================= -->
	<!-- requirement processing  -->
	<!-- ======================= -->
	<xsl:include href="mn2xml_req.xsl"/>
	<!-- ======================= -->
	<!-- END: requirement processing -->
	<!-- ======================= -->

	<xsl:template name="insert_label">
		<xsl:param name="label"/>
		<xsl:param name="isAddition">false</xsl:param>
		<xsl:param name="color"/>
		<xsl:param name="isNotePAS">false</xsl:param>
		<xsl:param name="colorNote"/>
		<xsl:param name="isEmptyLabel"/>
		
		<label>
			<xsl:choose>
				<xsl:when test="$isEmptyLabel = 'true'"><!-- empty label for amendment without title --></xsl:when>
				<xsl:when test="$isNotePAS = 'true'">
					<italic>
						<styled-content style="color:{$colorNote};">
							<xsl:value-of select="$label"/>
						</styled-content>
					</italic>
				</xsl:when>
				<xsl:when test="$isAddition = 'true' or $color != ''">
					<styled-content>
						<xsl:variable name="styles_">
							<xsl:if test="$isAddition = 'true' and not(ancestor::table)">
								<style>addition</style>
							</xsl:if>
							<xsl:if test="$color != ''">
								<style>color:<xsl:value-of select="$color"/></style>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="styles" select="xalan:nodeset($styles_)"/>
						<xsl:variable name="styles_type_">
							<xsl:if test="$isAddition = 'true' and ancestor::table">
								<style-type>addition</style-type>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="styles_type" select="xalan:nodeset($styles_type_)"/>
						<xsl:if test="count($styles/style) != 0">
							<xsl:attribute name="style">
								<xsl:for-each select="$styles/style">
									<xsl:value-of select="."/><xsl:if test="not(. = 'addition')"><xsl:text>;</xsl:text></xsl:if>
								</xsl:for-each>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="count($styles_type/style-type) != 0">
							<xsl:attribute name="style-type">
								<xsl:for-each select="$styles_type/style-type">
									<xsl:value-of select="."/>
									<xsl:if test="position() != last()">;</xsl:if>
								</xsl:for-each>
							</xsl:attribute>
						</xsl:if>
						
						<xsl:value-of select="$label"/>
					</styled-content>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$label"/>
					<!-- <xsl:copy-of select="@*"/> -->
					<xsl:if test="$outputformat = 'IEEE'">
						<xsl:if test="not(contains($label,'.') or contains($label,')') ) and not(parent::ul)"> <!-- add dot for 1st level label only -->
							<xsl:text>.</xsl:text>
						</xsl:if>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</label>
	</xsl:template>
	
	
	<xsl:template name="generateURN">
		<xsl:param name="sdo">ISO</xsl:param>
		<xsl:variable name="items_">
			<xsl:choose>
				<xsl:when test="$sdo = 'ISO'">
					<item>iso:std</item>
					<!-- publisher(s) -->
					<item>
						<xsl:for-each select="contributor[role/@type = 'author']/organization/abbreviation">
							<xsl:value-of select="java:toLowerCase(java:java.lang.String.new(.))"/>
							<xsl:if test="position() != last()">-</xsl:if>
						</xsl:for-each>
					</item>
					<!-- non 'is' doctype -->
					<item>
						<xsl:variable name="doctype" select="java:toLowerCase(java:java.lang.String.new(ext/doctype))"/>
						<xsl:choose>
							<xsl:when test="$doctype = 'is' or $doctype = 'international-standard'"></xsl:when>
							<xsl:when test="$doctype = 'technical-report'">tr</xsl:when>
							<xsl:when test="$doctype = 'technical-corrigendum'">tc</xsl:when>
							<xsl:when test="$doctype = 'technical-specification'">ts</xsl:when>
							<xsl:when test="$doctype = 'amendment'">amd</xsl:when>
							<xsl:when test="$doctype = 'directive'">dir</xsl:when>
							<xsl:otherwise><xsl:value-of select="$doctype"/></xsl:otherwise>
						</xsl:choose>
					</item>
					<!-- docnumber -->
					<item><xsl:value-of select="docnumber"/></item>
					<!-- part number -->
					<item>
						<xsl:variable name="part_number" select="ext/structuredidentifier/partnumber | ext/structuredidentifier/project-number/@part"/>
						<xsl:if test="normalize-space($part_number) != ''">-<xsl:value-of select="$part_number"/></xsl:if>
					</item>
					<!-- edition -->
					<item>ed-<xsl:value-of select="edition"/></item>
					<!-- version -->
					<item>v1</item> <!-- To do: https://github.com/metanorma/mn-samples-bsi/issues/22 -->
					<!-- language -->
					<item><xsl:value-of select="language"/></item>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="items" select="xalan:nodeset($items_)"/>
		<xsl:if test="count($items/item[normalize-space() != '']) &gt; 0">
			<urn>
				<xsl:for-each select="$items/item[normalize-space() != '']">
					<xsl:value-of select="normalize-space(.)"/>
					<xsl:if test="position() != last()">:</xsl:if>
				</xsl:for-each>
			</urn>
		</xsl:if>
	</xsl:template>

	<xsl:template name="getLevel">
		<xsl:variable name="level_total" select="count(ancestor::*)"/>
		<xsl:variable name="level">
			<xsl:choose>
				<xsl:when test="ancestor::preface">
					<xsl:value-of select="$level_total - 1"/>
				</xsl:when>
				<xsl:when test="ancestor::sections">
					<xsl:value-of select="$level_total - 1"/>
				</xsl:when>
				<xsl:when test="ancestor::bibliography">
					<xsl:value-of select="$level_total - 1"/>
				</xsl:when>
				<xsl:when test="local-name(ancestor::*[1]) = 'annex'">2</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$level_total"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="$level"/>
	</xsl:template>
	
	<xsl:template name="capitalize">
		<xsl:param name="str" />
		<xsl:value-of select="java:toUpperCase(java:java.lang.String.new(substring($str, 1, 1)))"/>
		<xsl:value-of select="substring($str, 2)"/>		
	</xsl:template>

	<xsl:template name="setDatedUndatedType">
		<xsl:param name="value"/>
		<xsl:choose>
			<!-- <xsl:when test="substring($value, string-length($value) - 4, 1) = ':' and translate(substring($value, string-length($value) - 3), '0123456789', '') = ''">dated</xsl:when> -->
			<xsl:when test="java:org.metanorma.utils.RegExHelper.matches('^.*\d:\d{4}($|\D+.*$)', $value) = 'true'">dated</xsl:when> <!-- . -->
			<xsl:otherwise>undated</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- split string by separator -->
	<xsl:template name="split">
		<xsl:param name="pText" select="."/>
		<xsl:param name="sep" select="','"/>
		<xsl:param name="normalize-space" select="'true'"/>
		<xsl:param name="keep_sep" select="'false'"/>
		<xsl:if test="string-length($pText) >0">
			<item>
				<xsl:choose>
					<xsl:when test="$normalize-space = 'true'">
						<xsl:value-of select="normalize-space(substring-before(concat($pText, $sep), $sep))"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="substring-before(concat($pText, $sep), $sep)"/>
					</xsl:otherwise>
				</xsl:choose>
			</item>
			<xsl:if test="$keep_sep = 'true' and contains($pText, $sep)"><item><xsl:value-of select="$sep"/></item></xsl:if>
			<xsl:call-template name="split">
				<xsl:with-param name="pText" select="substring-after($pText, $sep)"/>
				<xsl:with-param name="sep" select="$sep"/>
				<xsl:with-param name="normalize-space" select="$normalize-space"/>
				<xsl:with-param name="keep_sep" select="$keep_sep"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template> <!-- split -->
	
	<xsl:template name="addSectionAttribute">
		<xsl:if test="($metanorma_type = 'IEC' or $metanorma_type = 'ISO') and $outputformat != 'IEEE'">
			<xsl:copy-of select="@section"/>
		</xsl:if>
	</xsl:template>
	
	
	<xsl:template match="@*|node()" mode="footnotes_update">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="footnotes_update" />
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="footnote" mode="footnotes_update">
		<xsl:apply-templates mode="footnotes_update"/>
	</xsl:template>
	
	<xsl:template match="*" mode="print_as_xml">
		<xsl:text>&#xa;&lt;</xsl:text>
		<xsl:value-of select="local-name()"/>
		<xsl:for-each select="@*">
			<xsl:text> </xsl:text>
			<xsl:value-of select="local-name()"/>
			<xsl:text>="</xsl:text>
			<xsl:value-of select="."/>
			<xsl:text>"</xsl:text>
		</xsl:for-each>
		
		<xsl:for-each select="namespace::*">
			<xsl:text> xmlns</xsl:text>
			<xsl:variable name="xmlns_name" select="local-name()"/>
			<xsl:if test="$xmlns_name != ''">:<xsl:value-of select="$xmlns_name"/></xsl:if>
			<xsl:text>="</xsl:text>
			<xsl:value-of select="."/>
			<xsl:text>"</xsl:text>
		</xsl:for-each>
		
		<xsl:text>&gt;</xsl:text>
		<xsl:apply-templates mode="print_as_xml"/>
		<xsl:text>&lt;/</xsl:text>
		<xsl:value-of select="local-name()"/>
		<xsl:text>&gt;</xsl:text>
	</xsl:template>
	
</xsl:stylesheet>