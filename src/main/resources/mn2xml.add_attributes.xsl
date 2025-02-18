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
		- section_prefix (Annex, Table, Figure, Section, Clause, Equation)
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
		
	<xsl:variable name="i18n_annex"><xsl:call-template name="getLocalizedString"><xsl:with-param name="key">annex</xsl:with-param></xsl:call-template></xsl:variable>
	<xsl:variable name="i18n_table"><xsl:call-template name="getLocalizedString"><xsl:with-param name="key">table</xsl:with-param></xsl:call-template></xsl:variable>
	<xsl:variable name="i18n_figure"><xsl:call-template name="getLocalizedString"><xsl:with-param name="key">figure</xsl:with-param></xsl:call-template></xsl:variable>
	<xsl:variable name="i18n_clause"><xsl:call-template name="getLocalizedString"><xsl:with-param name="key">clause</xsl:with-param></xsl:call-template></xsl:variable>
	<xsl:variable name="i18n_section"><xsl:call-template name="getLocalizedString"><xsl:with-param name="key">section</xsl:with-param></xsl:call-template></xsl:variable>
	<xsl:variable name="i18n_equation"><xsl:call-template name="getLocalizedString"><xsl:with-param name="key">formula</xsl:with-param></xsl:call-template></xsl:variable>
		
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
			
			<xsl:variable name="section">
				<xsl:choose>
					<!-- Example:
						<fmt-title>
							<span class="fmt-caption-label">
								<strong>
									<span class="fmt-element-name">Annex</span>
									<semx element="autonum" source="sec_A">A</semx>
								</strong>
								<tab/>
								<span class="fmt-obligation">(informative)</span>
							</span>
					-->
					<xsl:when test="fmt-title/span[@class = 'fmt-caption-label']">
						<xsl:variable name="label">
							<xsl:copy-of select="fmt-title/span[@class = 'fmt-caption-label']//node()[@element = 'autonum' or @class = 'fmt-autonum-delim']"/>
						</xsl:variable>
						<xsl:value-of select="normalize-space($label)"/>
					</xsl:when>
					<!-- Example:
						<fmt-name>
							<span class="fmt-caption-label">
								<span class="fmt-element-name">Table</span>
								<semx element="autonum" source="sec_D">D</semx>
								<span class="fmt-autonum-delim">.</span>
								<semx element="autonum" source="tab_D.1">1</semx>
							</span>
							<span class="fmt-caption-delim"> — </span>
							<semx element="name" source="_a12f0b45-8053-4160-9e23-033b66b4d326">Table of requirements</semx>
						</fmt-name>
					-->
					<xsl:when test="fmt-name/span[@class = 'fmt-caption-label']">
						<xsl:variable name="label">
							<xsl:copy-of select="fmt-name/span[@class = 'fmt-caption-label']//node()[@element = 'autonum' or @class = 'fmt-autonum-delim']"/>
						</xsl:variable>
						<xsl:value-of select="normalize-space($label)"/>
					</xsl:when>
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
								<xsl:value-of select="$section_"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			
			<xsl:attribute name="section">
				<xsl:value-of select="$section"/>
			</xsl:attribute>
			
			<xsl:variable name="section_prefix">
				<xsl:choose>
					<xsl:when test="$name = 'annex'"><xsl:value-of select="$i18n_annex"/>&#xA0;</xsl:when> <!-- Annex&#xA0; -->
					<xsl:when test="$name = 'table' or $name = 'requirement'"><xsl:value-of select="$i18n_table"/>&#xA0;</xsl:when> <!-- Table&#xA0; -->
					<xsl:when test="$name = 'figure'"><xsl:value-of select="$i18n_figure"/>&#xA0;</xsl:when> <!-- Figure&#xA0; -->
					<xsl:when test="($name = 'clause' or $name = 'terms' or ($name = 'references' and @normative='true')) and $section != '' and not(contains($section, '.'))"><xsl:value-of select="concat($i18n_clause, ' ')"/></xsl:when> <!-- first level clause --> <!-- Clause -->
					<xsl:when test="$name = 'section-title' or ($name = 'p' and @type = 'section-title')"><xsl:value-of select="$i18n_section"/> </xsl:when> <!-- Section  -->
					<xsl:when test="$name = 'formula' and ($metanorma_type = 'IEC' or $metanorma_type = 'IEEE')"><xsl:value-of select="$i18n_equation"/> </xsl:when> <!-- Equation  -->
				</xsl:choose>
			</xsl:variable>
			
			
			<xsl:attribute name="section_prefix">
				<xsl:choose>
					<!-- Example:
						<fmt-title>
							<span class="fmt-caption-label">
								<strong>
									<span class="fmt-element-name">Annex</span>
									<semx element="autonum" source="sec_A">A</semx>
								</strong>
								<tab/>
								<span class="fmt-obligation">(informative)</span>
							</span>
					-->
					<xsl:when test="fmt-title/span[@class = 'fmt-caption-label']/span[@class = 'fmt-element-name']">
						<xsl:variable name="label">
							<xsl:copy-of select="fmt-title/span[@class = 'fmt-caption-label']/node()[self::text() or self::span[@class = 'fmt-element-name']]"/>
						</xsl:variable>
						<xsl:value-of select="normalize-space($label)"/><xsl:if test="self::annex">&#xA0;</xsl:if>
					</xsl:when>
					<!-- Example:
						<fmt-name>
							<span class="fmt-caption-label">
								<span class="fmt-element-name">Table</span>
								<semx element="autonum" source="sec_D">D</semx>
								<span class="fmt-autonum-delim">.</span>
								<semx element="autonum" source="tab_D.1">1</semx>
							</span>
							<span class="fmt-caption-delim"> — </span>
							<semx element="name" source="_a12f0b45-8053-4160-9e23-033b66b4d326">Table of requirements</semx>
						</fmt-name>
					-->
					<xsl:when test="fmt-name/span[@class = 'fmt-caption-label']/span[@class = 'fmt-element-name']">
						<xsl:variable name="label">
							<xsl:copy-of select="fmt-name/span[@class = 'fmt-caption-label']/node()[self::text() or self::span[@class = 'fmt-element-name']]"/>
						</xsl:variable>
						<xsl:value-of select="normalize-space($label)"/><xsl:if test="self::table or self::figure">&#xA0;</xsl:if>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$section_prefix"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			
			<xsl:if test="amend and not(title)">
				<xsl:attribute name="empty_label">true</xsl:attribute>
			</xsl:if>
			
		</xsl:if>
	</xsl:template>
	<!-- ===================== -->
	<!-- END add attributes -->
	<!-- ===================== -->
	
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
					<xsl:variable name="root_element_id" select="generate-id(ancestor::*[contains(local-name(), '-standard') or self::metanorma])"/> <!-- prevent global numbering for metanorma-collection -->
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
						<xsl:when test="ancestor::foreword">
							<xsl:variable name="num">
								<xsl:number format="_1" level="multiple" count="clause"/>
							</xsl:variable>
							<xsl:value-of select="concat($sectionNum,$num)"/>
						</xsl:when>
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
	
</xsl:stylesheet>