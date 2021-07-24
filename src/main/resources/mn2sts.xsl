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
	
	<!-- <xsl:key name="klang" match="*[local-name() = 'bibdata']/*[local-name() = 'title']" use="@language"/> -->

	<xsl:param name="debug">false</xsl:param>
	<xsl:param name="outputformat">NISO</xsl:param>
	
	<xsl:variable name="format" select="normalize-space($outputformat)"/>
	
	<xsl:variable name="change_id">true</xsl:variable>
		
	<xsl:variable name="organization_abbreviation" select="/*/*[local-name() = 'bibdata']/*[local-name() = 'copyright']/*[local-name() = 'owner']/*[local-name() = 'organization']/*[local-name() = 'abbreviation']"/>
	<xsl:variable name="organization_name" select="/*/*[local-name() = 'bibdata']/*[local-name() = 'copyright']/*[local-name() = 'owner']/*[local-name() = 'organization']/*[local-name() = 'name']"/>
	
	<xsl:variable name="organization">
		<xsl:choose>
			<xsl:when test="$organization_abbreviation = 'BSI' or $organization_name = 'The British Standards Institution' or $organization_name = 'British Standards Institution'">BSI</xsl:when>
			<xsl:when test="$organization_abbreviation != ''"><xsl:value-of select="$organization_abbreviation"/></xsl:when>
			<xsl:when test="$organization_name != ''"><xsl:value-of select="$organization_name"/></xsl:when>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:variable name="nat_meta_only">
		<xsl:if test="not(/*/*[local-name() = 'bibdata']/*[local-name() = 'relation'][@type = 'adopted-from']) and $organization = 'BSI'">true</xsl:if>
	</xsl:variable>
	
	<!-- ====================================================================== -->
	<!-- ====================================================================== -->
	<xsl:variable name="elements_">
		<elements>
			<xsl:apply-templates select="/*/*[local-name() = 'preface']/*" mode="elements"/>
      
      <!-- Introduction in sections -->
      <xsl:apply-templates select="/*/*[local-name() = 'sections']/*[local-name() = 'clause'][@type='intro']" mode="elements"> <!-- [0] -->
				<xsl:with-param name="sectionNum" select="'0'"/>
			</xsl:apply-templates>
      
			<!-- Scope -->
			<xsl:apply-templates select="/*/*[local-name() = 'sections']/*[local-name() = 'clause'][@type='scope']" mode="elements"> <!-- [1] -->
				<xsl:with-param name="sectionNum" select="'1'"/>
			</xsl:apply-templates>
			
			<!-- Normative References -->
			<xsl:apply-templates select="/*/*[local-name() = 'bibliography']/*[local-name() = 'references'][@normative='true']" mode="elements"> <!-- [@id = '_normative_references'] -->
				<xsl:with-param name="sectionNum" select="count(/*/*[local-name() = 'sections']/*[local-name() = 'clause'][@type='scope']) + 1"/>
			</xsl:apply-templates>
			
      <!-- Terms and definitions -->
		<xsl:apply-templates select="/*/*[local-name()='sections']/*[local-name()='terms'] | 
																						/*/*[local-name()='sections']/*[local-name()='clause'][.//*[local-name()='terms']] |
																						/*/*[local-name()='sections']/*[local-name()='definitions'] | 
																						/*/*[local-name()='sections']/*[local-name()='clause'][.//*[local-name()='definitions']]" mode="elements">
			<xsl:with-param name="sectionNumSkew" select="'1'"/>
		</xsl:apply-templates>
				<!-- Another main sections -->
		<xsl:apply-templates select="/*/*[local-name()='sections']/*[local-name() != 'terms' and 
																																														local-name() != 'definitions' and 
																																														not(@type='intro') and
																																														not(@type='scope') and
																																														not(local-name() = 'clause' and .//*[local-name()='terms']) and
																																														not(local-name() = 'clause' and .//*[local-name()='definitions'])]" mode="elements" />

					
			<!-- Other main sections: Terms, etc... -->					
			<!-- <xsl:apply-templates select="/*/*[local-name() = 'sections']/*[not(@type='scope') and not(@type='intro')]" mode="elements">
				<xsl:with-param name="sectionNumSkew" select="'1'"/>
			</xsl:apply-templates> -->
			
			<xsl:apply-templates select="/*/*[local-name() = 'annex']" mode="elements"/>
			
			<xsl:apply-templates select="//*[local-name() = 'appendix']" mode="elements"/>
			
			<xsl:apply-templates select="/*/*[local-name() = 'bibliography']/*[local-name() = 'references'][not(@normative='true')]" mode="elements"/>
			
		</elements>
	</xsl:variable>

	<xsl:template match="text()" mode="elements"/>
	
	<xsl:template match="*" mode="elements">
		<xsl:param name="sectionNum"/>
		<xsl:param name="sectionNumSkew" select="0"/>
		<xsl:variable name="sectionNum_">
			<xsl:choose>
				<xsl:when test="$sectionNum"><xsl:value-of select="$sectionNum"/></xsl:when>
				<xsl:when test="$sectionNumSkew != 0">
					<xsl:variable name="number"><xsl:number count="*"/></xsl:variable>
					<xsl:value-of select="$number + $sectionNumSkew"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:number count="*"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
	
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
								$name = 'em' or
								$name = 'table' or
								$name = 'dl' or
								$name = 'ol' or
								$name = 'ul' or
								$name = 'li' or
								$name = 'figure' or 
								$name = 'image' or
								$name = 'formula' or
								$name = 'stem'">
								
			<xsl:variable name="section_">
				<xsl:call-template name="getSection">
					<xsl:with-param name="sectionNum" select="$sectionNum_"/>
				</xsl:call-template>
			</xsl:variable>
			
			<xsl:variable name="source_id">			
				<xsl:call-template name="getId"/>
			</xsl:variable>
			
			<xsl:variable name="id" select="$source_id"/>
				<!--<xsl:choose>
					<xsl:when test="$organization = 'BSI' and @id"><xsl:value-of select="@id"/></xsl:when>
					<xsl:when test="$change_id = 'false'"><xsl:value-of select="$source_id"/></xsl:when>
					<xsl:when test="$name = 'li'"><xsl:value-of select="$source_id"/></xsl:when>
					<xsl:otherwise>
						<xsl:choose>							
							<xsl:when test="$name = 'clause' or 
																			($name = 'references' and @normative='true') or 
																			$name = 'annex' or
																			$name = 'terms' or
																			$name = 'term' or 
																			$name = 'definitions' or 
																			$name = 'ul' or 
																			$name = 'ol'">sec_</xsl:when>
							<xsl:when test="$name = 'fn'">fn_</xsl:when>
							<xsl:when test="$name = 'preferred' or 
																			$name = 'admitted' or 
																			$name = 'deprecates' or
																			$name = 'domain'">term_</xsl:when>				
							<xsl:when test="$name = 'dl' or $name = 'table'">tab_</xsl:when>
							<xsl:when test="$name = 'figure' or $name = 'image'">fig_</xsl:when>
							<xsl:when test="$name = 'formula'">formula_</xsl:when>
						</xsl:choose>
						<xsl:value-of select="$section_"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>-->
			
			<xsl:variable name="section">
				<xsl:choose>
					<xsl:when test="normalize-space(*[local-name() = 'title']/*[local-name() = 'tab'][1]/preceding-sibling::node()) != ''">
						<!-- presentation xml data -->
						<xsl:value-of select="*[local-name() = 'title']/*[local-name() = 'tab'][1]/preceding-sibling::node()"/>
					</xsl:when>
					<xsl:when test="local-name() = 'term' and normalize-space(*[local-name() = 'name']) != '' and  normalize-space(translate(*[local-name() = 'name'], '0123456789.', '')) = ''">
						<xsl:value-of select="*[local-name() = 'name']"/>
					</xsl:when>
					<xsl:when test="*[local-name() = 'title'] and not(*[local-name() = 'title']/*[local-name() = 'tab']) and normalize-space(translate(*[local-name() = 'title'], '0123456789.', '')) = ''">
						<xsl:value-of select="*[local-name() = 'title']"/>
					</xsl:when>
					<xsl:when test="(local-name() = 'table' or local-name() = 'figure') and contains(*[local-name() = 'name'], '&#8212; ')">
						<xsl:variable name="_name" select="substring-before(*[local-name() = 'name'], '&#8212; ')"/>
						<xsl:value-of select="translate(normalize-space(translate($_name, '&#xa0;', ' ')), ' ', '&#xa0;')"/>
					</xsl:when>
					<xsl:when test="(local-name() = 'table' or local-name() = 'figure') and not(contains(*[local-name() = 'name'], '&#8212; '))"/>
					<xsl:when test="$section_ = '0' and not(@type='intro')"></xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="$name = 'annex'">Annex&#xA0;<xsl:value-of select="$section_"/></xsl:when>
							<xsl:when test="$name = 'table'">Table&#xA0;<xsl:value-of select="$section_"/></xsl:when>
							<xsl:when test="$name = 'figure'">Figure&#xA0;<xsl:value-of select="$section_"/></xsl:when>
							<xsl:otherwise><xsl:value-of select="$section_"/></xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>				
			</xsl:variable>
			
			<xsl:variable name="parent">
				<xsl:choose>
					<xsl:when test="ancestor::*[local-name() = 'annex'] and not($name = 'figure' or $name = 'table' or $name = 'annex' or $name = 'fn')">annex</xsl:when>
					<xsl:otherwise><xsl:value-of select="$name"/></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			
			<element source_id="{$source_id}" id="{$id}" section="{$section}" parent="{$parent}"/>
			<xsl:if test="$debug = 'true'">
				<!-- <xsl:message><xsl:value-of select="$source_id"/></xsl:message> -->
			</xsl:if>
		</xsl:if>
		
		<xsl:apply-templates mode="elements">
			<xsl:with-param name="sectionNum" select="$sectionNum_"/>
		</xsl:apply-templates>
	</xsl:template>
		
	<xsl:template name="getId">
		<!-- <xsl:variable name="name" select="local-name()"/> -->
		<xsl:choose>
			<xsl:when test="@id"><xsl:value-of select="translate(@id,'()', '__')"/></xsl:when> <!-- replace '(' and ')' for valid id -->
			<xsl:otherwise>
				<xsl:value-of select="generate-id(.)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:variable name="elements" select="xalan:nodeset($elements_)"/>
	<!-- ====================================================================== -->
	<!-- ====================================================================== -->
	
	
	<xsl:template match="@*|node()">
		<xsl:param name="sectionNum"/>
		<xsl:param name="sectionNumSkew"/>
		<xsl:copy>
				<xsl:apply-templates select="@*|node()">
					<xsl:with-param name="sectionNum" select="$sectionNum"/>
					<xsl:with-param name="sectionNumSkew" select="$sectionNumSkew"/>
				</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="*">
		<xsl:param name="sectionNum"/>
		<xsl:param name="sectionNumSkew"/>
		<xsl:element name="{local-name()}">
			<xsl:apply-templates select="@*|node()">
				<xsl:with-param name="sectionNum" select="$sectionNum"/>
				<xsl:with-param name="sectionNumSkew" select="$sectionNumSkew"/>
			</xsl:apply-templates>
		</xsl:element>
	</xsl:template>
	
	<!-- root element, for example: iso-standard -->
	<xsl:template match="/*">
		
		<standard xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:tbx="urn:iso:std:iso:30042:ed-1" xmlns:xlink="http://www.w3.org/1999/xlink">
			
			<front>
				<xsl:for-each select="*[local-name() = 'bibdata']/*[local-name() = 'relation'][@type = 'adopted-from']">
				
					<xsl:variable name="element_name">
						<xsl:variable name="adopted_from_abbreviation" select="*[local-name() = 'bibitem']/*[local-name() = 'contributor'][*[local-name() = 'role']/@type='publisher']/*[local-name() = 'organization']/*[local-name() = 'abbreviation']" />
						<xsl:choose>
							<!-- If //bibdata//relation[@type = 'adopted-from']/bibitem/contributor[role/@type = 'publisher']/organization[abbreviation = 'xxx'] exists, where xxx = ISO or IEC, -->
							<xsl:when test="$adopted_from_abbreviation = 'ISO' or $adopted_from_abbreviation = 'IEC'">iso-meta</xsl:when>
							<!-- If //bibdata//relation[@type = 'adopted-from']/bibitem/contributor[role/@type = 'publisher']/organization[abbreviation = 'xxx'] exists, where xxx = CEN or CENELEC, -->
							<xsl:when test="$adopted_from_abbreviation = 'CEN' or $adopted_from_abbreviation = 'CENELEC'">reg-meta</xsl:when>
							<xsl:otherwise>std-meta</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<xsl:apply-templates select="*[local-name() = 'bibitem']" mode="front">
						<xsl:with-param name="element_name" select="$element_name"/>
					</xsl:apply-templates>
				</xsl:for-each>

				<xsl:variable name="element_name">
					<xsl:choose>
						<!-- If //bibdata/relation[@type = 'adopted-from'] exists -->
						<xsl:when test="*[local-name() = 'bibdata']/*[local-name() = 'relation'][@type = 'adopted-from']">nat-meta</xsl:when>
						<xsl:when test="$organization = 'BSI'">nat-meta</xsl:when>
						<xsl:otherwise>iso-meta</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				
				<xsl:apply-templates select="*[local-name() = 'bibdata']" mode="front">
					<xsl:with-param name="element_name" select="$element_name"/>
				</xsl:apply-templates>
				
				<xsl:call-template name="insert_publication_info"/>
				
				<xsl:apply-templates select="*[local-name() = 'preface']" mode="front_preface"/>
			</front>
			
			
			<xsl:if test="*[local-name() = 'sections'] or *[local-name() = 'bibliography']/*[local-name() = 'references'][@normative='true']">
				<body>
					<xsl:if test="$nat_meta_only = 'true'"> <!-- $organization = 'BSI' -->
						<xsl:apply-templates select="*[local-name() = 'preface']/*[local-name() = 'introduction']" mode="front_preface"> <!-- [0] -->
							<xsl:with-param name="skipIntroduction">false</xsl:with-param>
						</xsl:apply-templates>
					</xsl:if>
					
          <!-- Introduction in sections -->
          <xsl:apply-templates select="*[local-name() = 'sections']/*[local-name() = 'clause'][@type='intro']"> <!-- [0] -->
            <xsl:with-param name="sectionNum" select="'0'"/>
          </xsl:apply-templates>
          
        
					<!-- Scope -->
					<xsl:apply-templates select="*[local-name() = 'sections']/*[local-name() = 'clause'][@type='scope']"> <!-- [1] -->
						<xsl:with-param name="sectionNum" select="'1'"/>
					</xsl:apply-templates>
					
					<!-- Normative References -->
					<xsl:apply-templates select="*[local-name() = 'bibliography']/*[local-name() = 'references'][@normative='true']"> <!-- [@id = '_normative_references'] -->
						<xsl:with-param name="sectionNum" select="count(*[local-name() = 'sections']/*[local-name() = 'clause'][@type='scope']) + 1"/>
					</xsl:apply-templates>
					
          <!-- Terms and definitions -->
          <xsl:apply-templates select="*[local-name()='sections']/*[local-name()='terms'] | 
                                                  *[local-name()='sections']/*[local-name()='clause'][.//*[local-name()='terms']] |
                                                  *[local-name()='sections']/*[local-name()='definitions'] | 
                                                  *[local-name()='sections']/*[local-name()='clause'][.//*[local-name()='definitions']]" />		
              <!-- Another main sections -->
          <xsl:apply-templates select="*[local-name()='sections']/*[local-name() != 'terms' and 
                                                                                                  local-name() != 'definitions' and 
                                                                                                  not(@type='intro') and
                                                                                                  not(@type='scope') and
                                                                                                  not(local-name() = 'clause' and .//*[local-name()='terms']) and
                                                                                                  not(local-name() = 'clause' and .//*[local-name()='definitions'])]" />
          
					<!-- Other main sections: Terms, etc... -->					
					<!-- <xsl:apply-templates select="*[local-name() = 'sections']/*[not(@type='scope') and not(@type='intro')]">
						<xsl:with-param name="sectionNumSkew" select="'1'"/>
					</xsl:apply-templates> -->
					
				</body>	
			</xsl:if>
						
			<xsl:if test="*[local-name() = 'annex'] or *[local-name() = 'bibliography']/*[local-name() = 'references']">
				<back>
					<xsl:if test="*[local-name() = 'annex']">
						<app-group>
							<xsl:apply-templates select="*[local-name() = 'annex']" mode="back"/>
						</app-group>
					</xsl:if>
					<xsl:apply-templates select="*[local-name() = 'bibliography']/*[local-name() = 'references'][not(@normative='true')] | *[local-name() = 'bibliography']/*[local-name() = 'clause'][*[local-name() = 'references'][not(@normative='true')]]" mode="back"/>
					<xsl:apply-templates select="*[local-name() = 'indexsect']"/>
				</back>
			</xsl:if>
			<xsl:if test="$debug = 'true'">
				<xsl:text disable-output-escaping="yes">&lt;!-- </xsl:text>
				<xsl:value-of select="count($elements//element)"/>
				<!-- <xsl:copy-of select="xalan:nodeset($elements)"/> -->
				<xsl:copy-of select="$elements"/>
				<xsl:text disable-output-escaping="yes">--&gt;</xsl:text>
			</xsl:if>
		</standard>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'bibdata']"/>
	<xsl:template match="*[local-name() = 'preface']"/>
	<xsl:template match="*[local-name() = 'annex']"/>
	<xsl:template match="*[local-name() = 'bibliography']"/>
	
	<!-- ================================== -->
	<!-- Publishing and copyright information block -->
	<!-- ================================== -->
	<xsl:template name="insert_publication_info">
			<sec id="sec_pub_info_nat" sec-type="publication_info">
				<xsl:apply-templates select="*[local-name() = 'boilerplate']/*[local-name() = 'copyright-statement']/*" mode="publication_info"/>
				<xsl:apply-templates select="*[local-name() = 'bibdata']/*[local-name() = 'docidentifier'][@type = 'ISBN']" mode="publication_info"/>
				
				<xsl:if test="*[local-name() = 'bibdata']/*[local-name() = 'ext']/*[local-name() = 'ics']">
					<p><xsl:text>ICS </xsl:text>
						<xsl:for-each select="*[local-name() = 'bibdata']/*[local-name() = 'ext']/*[local-name() = 'ics']">
							<xsl:sort />
							<xsl:value-of select="normalize-space()"/>
							<xsl:if test="position() != last()">; </xsl:if>
						</xsl:for-each>
					</p>
				</xsl:if>
				
				<xsl:apply-templates select="*[local-name() = 'preface']/*[local-name() = 'clause'][@type = 'related-refs']"  mode="publication_info"/>
				
				<xsl:apply-templates select="*[local-name() = 'preface']/*[local-name() = 'clause'][@type = 'corrigenda']"  mode="publication_info"/>
				
			</sec>
		</xsl:template>
	
	<xsl:template match="*[local-name() = 'title']" mode="publication_info">
		<xsl:call-template name="title"/>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'p']" mode="publication_info">
		<xsl:call-template name="p"/>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'bibdata']/*[local-name() = 'docidentifier'][@type = 'ISBN']" mode="publication_info">
		<p>ISBN <xsl:apply-templates /></p>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'preface']/*[local-name() = 'clause'][@type = 'related-refs']" priority="2" mode="front_preface"/>
	<xsl:template match="*[local-name() = 'preface']/*[local-name() = 'clause'][@type = 'related-refs']"  mode="publication_info">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'preface']/*[local-name() = 'clause'][@type = 'corrigenda']" priority="2" mode="front_preface"/>
	<xsl:template match="*[local-name() = 'preface']/*[local-name() = 'clause'][@type = 'corrigenda']"  mode="publication_info">
		<sec>
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates />
		</sec>
	</xsl:template>
	<!-- ================================== -->
	<!-- END Publishing and copyright information block -->
	<!-- ================================== -->
	
	<xsl:template match="*[local-name() = 'bibdata'] | *[local-name() = 'bibdata']/*[local-name() = 'relation'][@type = 'adopted-from']/*[local-name() = 'bibitem']" mode="front">
		<xsl:param name="element_name"/>
		
		<!-- <iso-meta> -->
		<xsl:element name="{$element_name}">
			<xsl:if test="$element_name != 'iso-meta'">
				<xsl:attribute name="originator">
					<xsl:variable name="abbrev" select="*[local-name() = 'contributor'][*[local-name() = 'role']/@type='publisher']/*[local-name() = 'organization']/*[local-name() = 'abbreviation']"/>
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
				<xsl:for-each select="*[local-name() = 'title']">
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
							 <xsl:apply-templates select="xalan:nodeset($bibdata)/*/*[local-name() = 'title'][@language = current()/@language and @type = 'title-intro']" mode="front"/>
						</xsl:variable>
						
						<xsl:variable name="title-main">					
							<!-- <xsl:apply-templates select="/*/*[local-name() = 'bibdata']/*[local-name() = 'title'][@language = current()/@language and @type = 'title-main']" mode="front"/> -->
							<xsl:apply-templates select="xalan:nodeset($bibdata)/*/*[local-name() = 'title'][@language = current()/@language and @type = 'title-main']" mode="front"/>
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
							<xsl:apply-templates select="xalan:nodeset($bibdata)/*/*[local-name() = 'title'][@language = current()/@language and @type = 'title-amd']" mode="front"/>
						</xsl:variable>
						
						<xsl:variable name="title-part">
							<!-- <xsl:apply-templates select="/*/*[local-name() = 'bibdata']/*[local-name() = 'title'][@language = current()/@language and @type = 'title-part']" mode="front"/> -->
							<xsl:apply-templates select="xalan:nodeset($bibdata)/*/*[local-name() = 'title'][@language = current()/@language and @type = 'title-part']" mode="front"/>
						</xsl:variable>
						
						<xsl:variable name="part">
							<!-- <xsl:apply-templates select="/*/*[local-name() = 'bibdata']/*[local-name() = 'ext']/*[local-name() = 'structuredidentifier']/*[local-name() = 'project-number']/@part" mode="front"/> -->
							<xsl:apply-templates select="xalan:nodeset($bibdata)/*/*[local-name() = 'ext']/*[local-name() = 'structuredidentifier']/*[local-name() = 'project-number']/@part" mode="front"/>
						</xsl:variable>
						<part>
							<xsl:if test="local-name() = 'compl' and $part != ''">
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
				
					
					<xsl:for-each select="xalan:nodeset($titles-components)/*[normalize-space() != '' and not(local-name() = 'part')]">
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
			
			<doc-ident>
				<sdo>
					<xsl:apply-templates select="*[local-name() = 'contributor'][*[local-name() = 'role']/@type='author']/*[local-name() = 'organization']/*[local-name() = 'abbreviation']" mode="front"/>
				</sdo>
				<proj-id>
					<xsl:apply-templates select="*[local-name() = 'ext']/*[local-name() = 'structuredidentifier']/*[local-name() = 'project-number']" mode="front"/>
				</proj-id>
				<language>
					<xsl:apply-templates select="*[local-name() = 'language']" mode="front"/>
					</language>
				<release-version>
					<xsl:apply-templates select="*[local-name() = 'status']/*[local-name() = 'stage']/@abbreviation" mode="front"/>
				</release-version>
			</doc-ident>
			
			<std-ident>
				<originator>
					<xsl:apply-templates select="*[local-name() = 'contributor'][*[local-name() = 'role']/@type='publisher']/*[local-name() = 'organization']/*[local-name() = 'abbreviation']" mode="front"/>
				</originator>
				<doc-type>
					<xsl:apply-templates select="*[local-name() = 'ext']/*[local-name() = 'doctype']" mode="front"/>
				</doc-type>
				
				<xsl:apply-templates select="*[local-name() = 'ext']/*[local-name() = 'subdoctype']" mode="front"/>
				
				<doc-number>					
					<xsl:apply-templates select="*[local-name() = 'docnumber']" mode="front"/>
				</doc-number>
				
				<!-- <part-number> -->
				<xsl:variable name="part_number">
					<xsl:apply-templates select="*[local-name() = 'ext']/*[local-name() = 'structuredidentifier']/*[local-name() = 'partnumber'] | *[local-name() = 'ext']/*[local-name() = 'structuredidentifier']/*[local-name() = 'project-number']/@part" mode="front"/>
				</xsl:variable>
				<xsl:if test="normalize-space($part_number) != ''">
					<part-number>
						<xsl:value-of select="$part_number"/>
					</part-number>
				</xsl:if>
				
				<edition>
					<xsl:apply-templates select="*[local-name() = 'edition']" mode="front"/>
				</edition>
				<version>
					<xsl:apply-templates select="*[local-name() = 'version']/*[local-name() = 'revision-date']" mode="front"/>
				</version>
			</std-ident>
			
			<content-language>
				<xsl:apply-templates select="*[local-name() = 'language']" mode="front"/>
			</content-language>
			<std-ref type="dated">
				<xsl:apply-templates select="*[local-name() = 'docidentifier'][1]" mode="front"/>
			</std-ref>
			<std-ref type="undated">
				<xsl:value-of select="substring-before(*[local-name() = 'docidentifier'], ':')"/>
			</std-ref>
			<doc-ref>
				<xsl:choose>
					<xsl:when test="*[local-name() = 'docidentifier'][@type='iso-reference']">
						<xsl:apply-templates select="*[local-name() = 'docidentifier'][@type='iso-reference'][last()]" mode="front"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="*[local-name() = 'docidentifier'][@type='iso-with-lang']" mode="front"/>
					</xsl:otherwise>
				</xsl:choose>
			</doc-ref>
			
			<!-- <release-date> -->
			<xsl:variable name="release-date">
				<dates>
					<xsl:apply-templates select="*[local-name() = 'date'][@type='release']/*[local-name() = 'on']" mode="front"/>
				</dates>
			</xsl:variable>
			
			<xsl:choose>				
				<xsl:when test="$format = 'NISO'">
					<xsl:copy-of select="xalan:nodeset($release-date)/dates/*"/>
				</xsl:when>
				<xsl:otherwise><!-- get last date for ISO format (allows only one release-date  -->
					<xsl:choose>
						<xsl:when test="count(xalan:nodeset($release-date)/dates/*) &gt; 1">
							<xsl:copy-of select="xalan:nodeset($release-date)/dates/*[last()]"/>
						</xsl:when>
						<xsl:otherwise>
							<!-- mandatory element for ISO -->
							<release-date />
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
			
			<xsl:variable name="related_comm_ref" select="*[local-name() = 'relation'][@type='related']/*[local-name() = 'bibitem']/*[local-name() = 'docidentifier']"/>
			<xsl:variable name="related_comm_ref_text">Committee reference</xsl:variable>
			<comm-ref>
				<xsl:choose>
					<xsl:when test="$organization = 'BSI' and starts-with($related_comm_ref, $related_comm_ref_text)">
						<xsl:value-of select="normalize-space(substring-after($related_comm_ref, $related_comm_ref_text))"/>
					</xsl:when>
					<xsl:when test="*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'technical-committee'] and not(
						*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'subcommittee'] and 
						*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'workgroup'] )">
						<xsl:value-of select="*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'technical-committee']/@number"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="*[local-name() = 'copyright']/*[local-name() = 'owner']/*[local-name() = 'organization']/*[local-name() = 'abbreviation']" mode="front"/>
						<xsl:apply-templates select="*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'technical-committee']" mode="front"/>
						<xsl:apply-templates select="*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'subcommittee']" mode="front"/>
						<xsl:apply-templates select="*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'workgroup']" mode="front"/>
					</xsl:otherwise>
				</xsl:choose>
				
<!-- 				<xsl:value-of select="concat(
										'/', *[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'technical-committee']/@type, ' ',
										*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'technical-committee']/@number)"/>
 -->				
			</comm-ref>
			<secretariat>
				<xsl:apply-templates select="*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'secretariat']" mode="front"/>
			</secretariat>				
			<!-- <ics> -->
			<xsl:apply-templates select="*[local-name() = 'ext']/*[local-name() = 'ics']/*[local-name() = 'code']" mode="front"/>
			
			<!-- std-xref -->
			<!-- ignoring all instances of .//relation[@type = 'adopted-from']/bibitem -->
			<xsl:apply-templates select="*[local-name() = 'relation'][@type != 'adopted-from' and @type != 'related']" mode="front" /><!-- adopted-from -> to standalone xxx-meta , related -> comm-ref  -->
			
			<xsl:apply-templates select="*[local-name() = 'relation'][@type = 'related'][starts-with(*[local-name() = 'bibitem']/*[local-name() = 'docidentifier'], 'Draft for comment')]" mode="front" />
			
			
			<permissions>
				<!-- <copyright-statement>All rights reserved</copyright-statement> -->
				<xsl:apply-templates select="/*/*[local-name() = 'boilerplate']/*[local-name() = 'copyright-statement']"/>
				<copyright-year>
					<xsl:apply-templates select="*[local-name() = 'copyright']/*[local-name() = 'from']" mode="front"/>
				</copyright-year>
				<copyright-holder>
					<xsl:choose>
						<xsl:when test="*[local-name() = 'copyright']/*[local-name() = 'owner']/*[local-name() = 'organization']/*[local-name() = 'abbreviation']">
							<xsl:apply-templates select="*[local-name() = 'copyright']/*[local-name() = 'owner']/*[local-name() = 'organization']/*[local-name() = 'abbreviation']" mode="front"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates select="*[local-name() = 'copyright']/*[local-name() = 'owner']/*[local-name() = 'organization']/*[local-name() = 'name']" mode="front"/>
						</xsl:otherwise>
					</xsl:choose>
					
				</copyright-holder>
				<xsl:apply-templates select="/*/*[local-name() = 'boilerplate']/*[local-name() = 'legal-statement']"/>
				<xsl:apply-templates select="/*/*[local-name() = 'boilerplate']/*[local-name() = 'license-statement']"/>
			</permissions>
			
			<xsl:if test="*[local-name() = 'docidentifier'][@type = 'ISBN']">
				<custom-meta-group>
					<custom-meta>
						<meta-name>ISBN</meta-name>
						<meta-value><xsl:value-of select="*[local-name() = 'docidentifier'][@type = 'ISBN']"/></meta-value>
					</custom-meta>
				</custom-meta-group>
			</xsl:if>
			
			<xsl:if test="local-name() = 'bibdata'">
				<!-- check non-processed elements in bibdata -->
				<xsl:variable name="front_check">
					<xsl:apply-templates mode="front_check"/>
				</xsl:variable>

				<xsl:if test="normalize-space($front_check) != '' or count(xalan:nodeset($front_check)/*) &gt; 0">
					<xsl:text>WARNING! There are unprocessed elements in bibdata:&#xa;</xsl:text>
					<xsl:text>===================================&#xa;</xsl:text>
					<xsl:apply-templates select="xalan:nodeset($front_check)" mode="display_check"/>
					<xsl:text>&#xa;===================================&#xa;</xsl:text>
				</xsl:if>
			</xsl:if>
		<!-- </iso-meta> -->
		</xsl:element>
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
	
	<xsl:template match="*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'technical-committee'] |
																*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'subcommittee'] |
																*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'workgroup']" mode="front">
		<xsl:if test="normalize-space(@type) != '' or normalize-space(@number) != ''">
			<xsl:text>/</xsl:text>
			<xsl:choose>
				<xsl:when test="normalize-space(@type) != ''">
					<xsl:value-of select="@type"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="local-name() = 'technical-committee'">TC</xsl:when>
						<xsl:when test="local-name() = 'subcommittee'">SC</xsl:when>
						<xsl:when test="local-name() = 'workgroup'">WG</xsl:when>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="normalize-space(@number) != ''">
				<xsl:value-of select="concat(' ', @number)"/>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	
	
	<xsl:template match="*[local-name() = 'bibdata']/*[local-name() = 'date']/*[local-name() = 'on'] | *[local-name() = 'bibitem']/*[local-name() = 'date']/*[local-name() = 'on']" mode="front">
		<xsl:choose>
			<xsl:when test="../@type = 'release'">
				<release-date>
					<xsl:value-of select="."/>
				</release-date>
			</xsl:when>
			<xsl:when test="position() = 1 and ../@type = 'published' and ../following-sibling::*[local-name() = 'date']/@type = 'published' ">
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

	
	<xsl:template match="*[local-name() = 'ext']/*[local-name() = 'ics']/*[local-name() = 'code']" mode="front">
		<ics><xsl:apply-templates mode="front"/></ics>
	</xsl:template>

	<xsl:template match="*[local-name() = 'ext']/*[local-name() = 'doctype']" mode="front">
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

	<xsl:template match="*[local-name() = 'ext']/*[local-name() = 'subdoctype']" mode="front">
		<xsl:text disable-output-escaping="yes">&lt;!--</xsl:text>
			<xsl:copy-of select="."/>
		<xsl:text disable-output-escaping="yes">--&gt;</xsl:text>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'bibdata' or local-name() = 'bibitem']/*[local-name() = 'relation']" mode="front">
		<xsl:variable name="value" select="*[local-name() = 'bibitem']/*[local-name() = 'docidentifier']"/>
		<xsl:variable name="draft_comment_text">Draft for comment</xsl:variable>
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
					<xsl:copy-of select="@*"/>
					<xsl:apply-templates mode="front"/>
				</std-xref>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	
	<xsl:template match="*[local-name() = 'bibdata' or local-name() = 'bibitem']/*[local-name() = 'relation'][@type != 'adopted-from']/*[local-name() = 'bibitem']" mode="front">
		<std-ref>
			<xsl:copy-of select="@*"/>
			<xsl:attribute name="type">
				<xsl:call-template name="setDatedUndatedType">
					<xsl:with-param name="value" select="."/>
				</xsl:call-template>
			</xsl:attribute>
			<xsl:apply-templates mode="front"/>
		</std-ref>
	</xsl:template>
	

	<!-- skip processed ^ attributes  and stop -->
	<xsl:template match="*[local-name() = 'bibdata']/*[local-name() = 'ext']/*[local-name() = 'structuredidentifier']/*[local-name() = 'project-number']/@part |
																*[local-name() = 'status']/*[local-name() = 'stage']/@abbreviation |
																*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'technical-committee']/@type |
																*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'technical-committee']/@number" 
																mode="front_check"/>
	
	<!-- skip processed ^ elements and stop -->
	<xsl:template match="*[local-name() = 'bibdata']/*[local-name() = 'title'][@type = 'title-intro'] |
																*[local-name() = 'bibdata']/*[local-name() = 'title'][@type = 'title-main'] |
																*[local-name() = 'bibdata']/*[local-name() = 'title'][@type = 'title-part'] |
																*[local-name() = 'bibdata']/*[local-name() = 'title'][@type = 'main'] |
																*[local-name() = 'bibdata']/*[local-name() = 'title'][@type = 'title-amd'] |
																*[local-name() = 'contributor'][*[local-name() = 'role']/@type='author']/*[local-name() = 'organization']/*[local-name() = 'abbreviation'] |																
																*[local-name() = 'contributor'][*[local-name() = 'role']/@type='author']/*[local-name() = 'organization']/*[local-name() = 'name'] |
																*[local-name() = 'ext']/*[local-name() = 'structuredidentifier']/*[local-name() = 'project-number'] |
																*[local-name() = 'language'] |
																*[local-name() = 'script'] |
																*[local-name() = 'contributor'][*[local-name() = 'role']/@type='publisher']/*[local-name() = 'organization']/*[local-name() = 'abbreviation'] |																
																*[local-name() = 'contributor'][*[local-name() = 'role']/@type='publisher']/*[local-name() = 'organization']/*[local-name() = 'name'] |
																*[local-name() = 'status']/*[local-name() = 'stage'] |
																*[local-name() = 'status']/*[local-name() = 'substage'] |
																*[local-name() = 'ext']/*[local-name() = 'doctype'] |
																*[local-name() = 'ext']/*[local-name() = 'subdoctype'] |
																*[local-name() = 'ext']/*[local-name() = 'updates-document-type'] |
																*[local-name() = 'docnumber'] |
																*[local-name() = 'ext']/*[local-name() = 'structuredidentifier']/*[local-name() = 'partnumber'] |
																*[local-name() = 'edition'] |
																*[local-name() = 'version']|
																*[local-name() = 'version']/*[local-name() = 'revision-date'] |
																*[local-name() = 'language'] |
																*[local-name() = 'docidentifier'] |
																*[local-name() = 'docidentifier'][@type='iso-with-lang'] |
																*[local-name() = 'bibdata']/*[local-name() = 'date'] |
																*[local-name() = 'bibdata']/*[local-name() = 'copyright']/*[local-name() = 'owner']/*[local-name() = 'organization']/*[local-name() = 'abbreviation'] |
																*[local-name() = 'bibdata']/*[local-name() = 'copyright']/*[local-name() = 'owner']/*[local-name() = 'organization']/*[local-name() = 'name'] |
																*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'secretariat'] |
																*[local-name() = 'ext']/*[local-name() = 'stagename']|
																*[local-name() = 'ext']/*[local-name() = 'ics']/*[local-name() = 'code'] | 
																*[local-name() = 'copyright']/*[local-name() = 'from'] |
																*[local-name() = 'ext']/*[local-name() = 'structuredidentifier'] |
																*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'technical-committee'] |
																*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'subcommittee'] |
																*[local-name() = 'ext']/*[local-name() = 'editorialgroup']/*[local-name() = 'workgroup'] |
																*[local-name() = 'bibdata']/*[local-name() = 'relation'] |
																*[local-name() = 'bibdata']/*[local-name() = 'relation']/*[local-name() = 'bibitem']"
																mode="front_check"/>

	<!-- skip processed structure and deep down -->
	<xsl:template match="*[local-name() = 'contributor'][*[local-name() = 'role']/@type='author'] |
																*[local-name() = 'contributor']/*[local-name() = 'role'][@type='author'] |
																*[local-name() = 'contributor'][*[local-name() = 'role']/@type='author']/*[local-name() = 'organization'] | 
																*[local-name() = 'contributor'][*[local-name() = 'role']/@type='publisher'] |
																*[local-name() = 'contributor']/*[local-name() = 'role'][@type='publisher'] |
																*[local-name() = 'contributor'][*[local-name() = 'role']/@type='publisher']/*[local-name() = 'organization'] |
																*[local-name() = 'bibdata']/*[local-name() = 'status'] |
																*[local-name() = 'bibdata']/*[local-name() = 'relation'] |
																*[local-name() = 'bibdata']/*[local-name() = 'copyright'] |
																*[local-name() = 'bibdata']/*[local-name() = 'copyright']/*[local-name() = 'owner'] |
																*[local-name() = 'bibdata']/*[local-name() = 'copyright']/*[local-name() = 'owner']/*[local-name() = 'organization'] |
																*[local-name() = 'ext']/*[local-name() = 'editorialgroup'] |
																*[local-name() = 'ext']/*[local-name() = 'ics'] |
																*[local-name() = 'ext']
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
	
	<xsl:template match="*[local-name() = 'boilerplate']/*[local-name() = 'copyright-statement']">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="*[local-name() = 'boilerplate']/*[local-name() = 'copyright-statement']/*[local-name() = 'clause']" priority="1">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="*[local-name() = 'boilerplate']/*[local-name() = 'copyright-statement']//*[local-name() = 'title']"  priority="1">
		<copyright-statement>
			<xsl:apply-templates/>
		</copyright-statement>
	</xsl:template>
	<xsl:template match="*[local-name() = 'boilerplate']/*[local-name() = 'copyright-statement']//*[local-name() = 'p']"  priority="1">
		<xsl:variable name="id" select="normalize-space(@id)"/>
		<xsl:if test="$id != 'boilerplate-year'">
			<copyright-statement>
				<xsl:apply-templates/>
			</copyright-statement>
		</xsl:if>
	</xsl:template>
	<xsl:template match="*[local-name() = 'boilerplate']/*[local-name() = 'copyright-statement']//*[local-name() = 'p']//*[local-name() = 'br']"  priority="1">
		<xsl:value-of select="'&#x2028;'"/><!-- linebreak -->
	</xsl:template>	
		
	<xsl:template match="*[local-name() = 'boilerplate']/*[local-name() = 'legal-statement']">
		<license specific-use="legal">
			<xsl:for-each select="*[local-name() = 'clause'][1]/*[local-name() = 'title']">
				<xsl:attribute name="xlink:title">
					<xsl:value-of select="."/>
				</xsl:attribute>
			</xsl:for-each>
			<xsl:apply-templates/>
		</license>	
	</xsl:template>
	<xsl:template match="*[local-name() = 'boilerplate']/*[local-name() = 'legal-statement']/*[local-name() = 'clause']/*[local-name() = 'title']" priority="1"/>
	<xsl:template match="*[local-name() = 'boilerplate']/*[local-name() = 'legal-statement']/*[local-name() = 'clause']" priority="1">
		<license-p>
			<xsl:if test="$format = 'NISO'">
				<xsl:attribute name="id">
					<xsl:call-template name="getId"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
		</license-p>
	</xsl:template>	
	
	<xsl:template match="*[local-name() = 'boilerplate']/*[local-name() = 'license-statement']">
		<license>
			<xsl:for-each select="*[local-name() = 'clause'][1]/*[local-name() = 'title']">
				<xsl:attribute name="xlink:title">
					<xsl:value-of select="."/>
				</xsl:attribute>
			</xsl:for-each>
			<xsl:apply-templates/>
		</license>	
	</xsl:template>
	<xsl:template match="*[local-name() = 'boilerplate']/*[local-name() = 'license-statement']/*[local-name() = 'clause']/*[local-name() = 'title']" priority="1"/>
	<xsl:template match="*[local-name() = 'boilerplate']/*[local-name() = 'license-statement']/*[local-name() = 'clause']" priority="1">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="*[local-name() = 'boilerplate']/*[local-name() = 'license-statement']//*[local-name() = 'p']" priority="1">
		<license-p>
			<xsl:if test="$format = 'NISO'">
				<xsl:attribute name="id">
					<xsl:value-of select="@id"/>					
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
		</license-p>
	</xsl:template>
	
	
	<xsl:template match="*[local-name() = 'preface']/*" mode="front_preface">
		<xsl:param name="skipIntroduction">true</xsl:param>
		<xsl:variable name="name" select="local-name()"/>
		<xsl:choose>
			<!-- For BSI, Introduction section placed in body -->
			<xsl:when test="$skipIntroduction = 'true' and $name = 'introduction' and $nat_meta_only = 'true'"></xsl:when> <!-- $organization = 'BSI' -->
			<xsl:otherwise>
				<xsl:variable name="sec_type">
					<xsl:choose>
						<xsl:when test="$name = 'introduction'">intro</xsl:when>
						<xsl:when test="$name = 'foreword'">foreword</xsl:when>
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
					<xsl:attribute name="sec-type"><xsl:value-of select="$sec_type"/></xsl:attribute>
					
					<xsl:variable name="section" select="$elements//element[@source_id = current()/@id]/@section"/>
					<xsl:if test="$section != ''">
						<label><xsl:value-of select="$section"/></label>
					</xsl:if>

					<xsl:apply-templates />
				</sec>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template match="*[local-name() = 'annex']" mode="back">
		<xsl:variable name="current_id">
			<xsl:call-template name="getId"/>
		</xsl:variable>
		<!-- <xsl:variable name="id" select="xalan:nodeset($elements)//element[@source_id = $current_id]/@id"/> -->
		<xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable>
		<xsl:variable name="section" select="$elements//element[@source_id = $current_id]/@section"/>
		<app id="{$id}" content-type="inform-annex">
			<xsl:if test="normalize-space(@obligation) != ''">
				<xsl:attribute name="content-type">
					<xsl:choose>
						<xsl:when test="@obligation  = 'informative'">inform-annex</xsl:when>
						<xsl:otherwise><xsl:value-of select="@obligation"/></xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="$organization = 'BSI' and normalize-space(@obligation) = ''">
				<xsl:attribute name="content-type">norm-annex</xsl:attribute>
			</xsl:if>
			<label>
				<xsl:choose>
					<xsl:when test="ancestor::*[local-name() = 'amend']/*[local-name() = 'autonumber'][@type = 'annex']">
						<xsl:value-of select="ancestor::*[local-name() = 'amend']/*[local-name() = 'autonumber'][@type = 'annex']/text()"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$section"/>
					</xsl:otherwise>
				</xsl:choose>
			</label>
			<xsl:if test="normalize-space(@obligation) != ''">
				<annex-type>(<xsl:value-of select="@obligation"/>)</annex-type>
			</xsl:if>
			<xsl:apply-templates />
		</app>
	</xsl:template>
	
	
	<xsl:template match="*[local-name() = 'bibliography']/*[local-name() = 'references'][not(@normative='true')]" mode="back">
		<ref-list content-type="bibl">
			<xsl:attribute name="id">
				<xsl:text>sec_bibl</xsl:text>
				<xsl:if test="count(//*[local-name() = 'references'][not(@normative='true')]) &gt; 1">
					<xsl:number format="_1" count="*[local-name() = 'references'][not(@normative='true')]"/>
				</xsl:if>
			</xsl:attribute>
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
	
	<!-- <xsl:template match="*[local-name() = 'bibliography']/*[local-name() = 'references'][not(@normative='true')]/*[local-name() = 'title']" priority="2"/>
	<xsl:template match="*[local-name() = 'bibliography']/*[local-name() = 'references'][not(@normative='true')]/*[local-name() = 'title']" mode="back">
		<title><xsl:apply-templates /></title>
	</xsl:template> -->
	
	<xsl:template match="*[local-name() = 'bibliography']/*[local-name() = 'references'][not(@normative='true')]/*[local-name() = 'title']">
		<title><xsl:apply-templates /></title>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'bibliography']/*[local-name() = 'clause'][*[local-name() = 'references'][not(@normative='true')]]" mode="back">
		<ref-list content-type="bibl">
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates/>
		</ref-list>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'bibliography']/*[local-name() = 'clause']/*[local-name() = 'references'][not(@normative='true')]">
		<ref-list>
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates/>
		</ref-list>
	</xsl:template>
	
	
	<xsl:template match="*[local-name() = 'bibitem'][1][ancestor::*[local-name() = 'references'][@normative='true']]" priority="2">
		<ref-list content-type="norm-refs">
			<xsl:for-each select="../*[local-name() = 'bibitem']">
				<xsl:call-template name="bibitem"/>
			</xsl:for-each>
		</ref-list>
	</xsl:template>
	<xsl:template match="*[local-name() = 'bibitem'][position() &gt; 1][ancestor::*[local-name() = 'references'][@normative='true']]" priority="2"/>
	
	<xsl:variable name="count_non_normative_references" select="count(//*[local-name() = 'references'][not(@normative='true')])"/>
	
	<xsl:template match="*[local-name() = 'bibitem']" name="bibitem">
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
			
			<xsl:apply-templates select="*[local-name() = 'docidentifier'][@type = 'metanorma']" mode="docidentifier_metanorma"/>
			<xsl:if test="not(*[local-name() = 'docidentifier'][@type='metanorma'])">
				<!-- <label><xsl:number format="[1]"/></label> --> <!-- see docidentifier @type="metanorma" -->
			</xsl:if>
						
			<xsl:choose>
				<xsl:when test="count(*) = 2 and *[local-name() = 'docidentifier'][@type='metanorma'] and *[local-name() = 'title']">
					<xsl:apply-templates select="*[local-name() = 'docidentifier']"/>
					<xsl:apply-templates select="*[local-name() = 'title']" mode="mixed_citation"/>
				</xsl:when>
				<xsl:otherwise>
					<std>
						<xsl:variable name="urn" select="*[local-name() = 'docidentifier'][@type = 'URN']"/>
						<xsl:if test="normalize-space($urn) != ''">
							<xsl:attribute name="std-id"><xsl:value-of select="$urn"/></xsl:attribute>
						</xsl:if>
						<xsl:if test="*[local-name() = 'eref']/@citeas">
							<xsl:attribute name="type">
								<xsl:call-template name="setDatedUndatedType">
									<xsl:with-param name="value" select="*[local-name() = 'eref']/@citeas"/>
								</xsl:call-template>
							</xsl:attribute>
						</xsl:if>
						
						
						<xsl:if test="*[local-name() = 'docidentifier'][not(@type = 'metanorma' or @type = 'URN')]">
							<std-ref><xsl:value-of select="*[local-name() = 'docidentifier'][not(@type = 'metanorma' or @type = 'URN')]"/></std-ref>
						</xsl:if>
						
						<xsl:choose>
							<xsl:when test="*[local-name() = 'note'] or *[local-name() = 'title'][(@type = 'main' and @language = 'en') or not(@type and @language)] or *[local-name() = 'formattedref']">
								<xsl:apply-templates select="*[local-name() = 'note']"/>				
								<xsl:apply-templates select="*[local-name() = 'title'][(@type = 'main' and @language = 'en') or not(@type and @language)]"/>				
								<xsl:apply-templates select="*[local-name() = 'formattedref']"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:apply-templates />
							</xsl:otherwise>
						</xsl:choose>
					</std>
				</xsl:otherwise>
			</xsl:choose>
			
			
			
		</ref>
		
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'references']/*[local-name() = 'bibitem']/*[local-name() = 'docidentifier' or local-name() = 'docnumber' or local-name() = 'date' or local-name() = 'contributor']" priority="2">
		<xsl:text disable-output-escaping="yes">&lt;!--</xsl:text>
			<xsl:copy-of select="."/>
		<xsl:text disable-output-escaping="yes">--&gt;</xsl:text>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'bibitem']/*[local-name() = 'title']" priority="2">
		<xsl:text>, </xsl:text>
		<title><xsl:apply-templates/></title>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'bibitem']/*[local-name() = 'title']" mode="mixed_citation">
		<mixed-citation><xsl:apply-templates/></mixed-citation>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'bibitem']/*[local-name() = 'formattedref']">
		<title><xsl:apply-templates/></title>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'bibitem']/*[local-name() = 'docidentifier'][@type = 'metanorma']" mode="docidentifier_metanorma">
		<label><xsl:apply-templates /></label>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'bibitem']/*[local-name() = 'docidentifier'][@type = 'metanorma']" priority="3"/>
	<xsl:template match="*[local-name() = 'bibitem']/*[local-name() = 'docidentifier'][@type = 'URN']" priority="3"/>
	
	<xsl:template match="*[local-name() = 'formattedref']/*[local-name() = 'em']" priority="2">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'bibitem']/*[local-name() = 'eref']" priority="2">
		<xsl:variable name="reference" select="@bibitemid"/>
		<xsl:variable name="docidentifier_URN" select="//*[local-name() = 'bibitem'][@id = $reference]/*[local-name() = 'docidentifier'][@type = 'URN']"/>
		<xsl:if test="$docidentifier_URN != ''">
			<xsl:attribute name="std-id">
				<xsl:value-of select="$docidentifier_URN"/>
			</xsl:attribute>
		</xsl:if>
		<std-ref><xsl:value-of select="java:replaceAll(java:java.lang.String.new(@citeas),'--','—')"/></std-ref>
		<xsl:apply-templates select="*[local-name() = 'localityStack']"/>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'bibitem']/*[local-name() = 'note']" priority="2">
		<xsl:variable name="number">
			<xsl:number level="any" count="*[local-name() = 'bibitem']/*[local-name() = 'note']"/>
		</xsl:variable>
		
		<xsl:variable name="xref_fn">
			<xref ref-type="fn" rid="fn_{$number}">
				<sup><xsl:value-of select="$number"/></sup>
			</xref>
			<fn id="fn_{$number}">
				<label>
					<sup><xsl:value-of select="$number"/></sup>
				</label>
				<p><xsl:apply-templates/></p>
			</fn>
		</xsl:variable>

		<xsl:copy-of select="$xref_fn"/>
		
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'fn'] " priority="2">
		<xsl:variable name="number" select="@reference"/>
		<xsl:variable name="number_id">
			<xsl:value-of select="$number"/>_<xsl:number level="any" count="*[local-name() = 'fn']"/>
		</xsl:variable>
		<xsl:variable name="sfx">
			<xsl:if test="ancestor::*[local-name() = 'table']"><xsl:value-of select="ancestor::*[local-name() = 'table'][1]/@id"/>_</xsl:if>
		</xsl:variable>
		<xsl:variable name="xref_fn">
			<xref ref-type="fn" rid="fn_{$number_id}"> <!-- {$sfx} rid="fn_{$number}" -->
				<sup><xsl:value-of select="$number"/>)</sup>
			</xref>
			<fn id="fn_{$number_id}"> <!-- {$sfx} -->
				<label>
					<sup><xsl:value-of select="$number"/>)</sup>
				</label>
				<xsl:apply-templates/>
			</fn>
		</xsl:variable>
		
		<xsl:choose>		
			<xsl:when test="preceding-sibling::*[1][local-name() = 'image']">
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
	
	
	<xsl:template match="*[local-name() = 'fn']/text()" priority="2">
		<xsl:if test="normalize-space(.) != ''">
			<p><xsl:value-of select="."/></p>
		</xsl:if>
	</xsl:template>
	
	
	<xsl:template match="*[local-name() = 'clause'] | 
																*[local-name() = 'references'][@normative='true'] | 
																*[local-name() = 'terms'] |
																*[local-name() = 'definitions']">
		<xsl:param name="sectionNum"/>
		<xsl:param name="sectionNumSkew" select="0"/>
		<xsl:if test="$debug = 'true'">
			<xsl:message>DEBUG: clause processing <xsl:number level="any" count="*[local-name() = 'clause']"/></xsl:message>
		</xsl:if>
		<xsl:variable name="sectionNum_">
			<xsl:choose>
				<xsl:when test="$sectionNum"><xsl:value-of select="$sectionNum"/></xsl:when>
				<xsl:when test="$sectionNumSkew != 0">
					<xsl:variable name="number"><xsl:number count="*"/></xsl:variable>
					<xsl:value-of select="$number + $sectionNumSkew"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:number count="*"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
	
		<xsl:variable name="sec_type">
			<xsl:choose>
				<xsl:when test="@type='scope'">scope</xsl:when>
				<xsl:when test="@type='intro'">intro</xsl:when>
				<xsl:when test="@normative='true'">norm-refs</xsl:when>
				<xsl:when test="@id = 'tda' or @id = 'terms' or local-name() = 'terms' or (contains(*[local-name() = 'title'][1], 'Terms') and not(ancestor::*[local-name() = 'clause']))">terms</xsl:when>
				<xsl:when test="ancestor::*[local-name() = 'foreword']"><xsl:value-of select="@type"/></xsl:when>
				<xsl:otherwise><!-- <xsl:value-of select="@id"/> --></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
	
		<xsl:variable name="current_id">
			<xsl:call-template name="getId"/>
		</xsl:variable>
		
		<!-- <xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="ancestor::*[local-name() = 'foreword']">
					<xsl:value-of select="@id"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$elements//element[@source_id = $current_id]/@id"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable> -->
		<xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable>
		<xsl:variable name="section" select="$elements//element[@source_id = $current_id]/@section"/>
		
		<sec id="{$id}">
			<xsl:if test="normalize-space($sec_type) != ''">
				<xsl:attribute name="sec-type">
					<xsl:value-of select="$sec_type"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="ancestor::*[local-name() = 'foreword']"></xsl:when>
				<xsl:otherwise><label><xsl:value-of select="$section"/></label>			</xsl:otherwise>
			</xsl:choose>
			
			<xsl:apply-templates>
				<xsl:with-param name="sectionNum" select="$sectionNum_"/>
			</xsl:apply-templates>
		</sec>
	</xsl:template>


	<xsl:template match="*[local-name() = 'term']">
		<xsl:param name="sectionNum"/>
		<xsl:variable name="current_id">
			<xsl:call-template name="getId"/>
		</xsl:variable>
		<!-- <xsl:variable name="section" select="$elements//element[@source_id = $current_id]/@section"/> -->
		<!-- <xsl:variable name="id" select="$elements//element[@source_id = $current_id]/@id"/> -->
		
		<!-- <xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable> -->
		
		<xsl:variable name="section">
			<xsl:choose>
				<xsl:when test="normalize-space(*[local-name() = 'name']) != '' and  normalize-space(translate(*[local-name() = 'name'], '0123456789.', '')) = ''">
					<xsl:value-of select="*[local-name() = 'name']"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$elements//element[@source_id = $current_id]/@section"/>
					<!-- <xsl:value-of select="$sectionNum"/> -->
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<term-sec id="sec_{$section}"><!-- id="{$current_id}" -->
			<label><xsl:value-of select="$section"/></label>
			<tbx:termEntry id="{$current_id}">
				<tbx:langSet xml:lang="en">
					<xsl:apply-templates select="node()[not(local-name() = 'termexample' or local-name() = 'termnote' or local-name() = 'termsource' or 
																										local-name() = 'preferred' or local-name() = 'admitted' or local-name() = 'deprecates' or local-name() = 'domain')]">
						<xsl:with-param name="sectionNum" select="$sectionNum"/>
					</xsl:apply-templates>
					<xsl:apply-templates select="*[local-name() = 'termexample']"><!--  mode="termEntry"> -->
						<xsl:with-param name="sectionNum" select="$sectionNum"/>
					</xsl:apply-templates>
					<xsl:apply-templates select="*[local-name() = 'termnote']"> <!--  mode="termEntry" -->
						<xsl:with-param name="sectionNum" select="$sectionNum"/>
					</xsl:apply-templates>
					<xsl:apply-templates select="*[local-name() = 'termsource']"> <!--  mode="termEntry" -->
						<xsl:with-param name="sectionNum" select="$sectionNum"/>
					</xsl:apply-templates>
					
					<xsl:apply-templates select="*[local-name() = 'preferred'] | *[local-name() = 'admitted'] | *[local-name() = 'deprecates'] | *[local-name() = 'domain']"> <!--  mode="termEntry" -->
						<xsl:with-param name="sectionNum" select="$sectionNum"/>
					</xsl:apply-templates>
					
				</tbx:langSet>
			</tbx:termEntry>
		</term-sec>
	</xsl:template>	

	<xsl:template match="*[local-name() = 'term']/text()">
		<xsl:value-of select="normalize-space()"/>
	</xsl:template>

	<xsl:template match="*[local-name() = 'definition']">
		<tbx:definition>
			<xsl:apply-templates />
		</tbx:definition>
	</xsl:template>

	<xsl:template match="*[local-name() = 'termexample']"> <!--  mode="termEntry" -->
		<tbx:example>
			<xsl:apply-templates />
		</tbx:example>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'definition']/text()[1] |
																*[local-name() = 'termexample']/text()[1] | 
																*[local-name() = 'termnote']/text()[1] |
																*[local-name() = 'termsource']/text()[1] |
																*[local-name() = 'modification']/text()[1] |
																*[local-name() = 'dd']/text()[1] |
																*[local-name() = 'formattedref']/text()[1]">
		<xsl:value-of select="normalize-space()"/>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'termnote']"> <!--  mode="termEntry" -->
		<tbx:note>
			<xsl:apply-templates />
		</tbx:note>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'termsource']"> <!--  mode="termEntry" -->
		<!-- <xsl:if test="$debug = 'true'">
			<xsl:message>DEBUG: termsource processing <xsl:value-of select="parent::*/*[local-name() = 'name']"/></xsl:message>
		</xsl:if> -->
		<tbx:source>
			<xsl:value-of select="*[local-name() = 'origin']/@citeas"/>
			<xsl:apply-templates select="*[local-name() = 'origin']/*[local-name() = 'localityStack']"/>
			<xsl:apply-templates select="*[local-name() = 'modification']"/>
		</tbx:source>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'localityStack']">
		<xsl:text>, </xsl:text>
		<xsl:for-each select="*[local-name() = 'locality']">
			<xsl:variable name="type">
				<xsl:call-template name="capitalize">
					<xsl:with-param name="str" select="@type"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:if test="$type != ''">
				<xsl:value-of select="$type"/>
				<xsl:text> </xsl:text>
			</xsl:if>
			<xsl:value-of select="*[local-name() = 'referenceFrom']"/>
			<xsl:if test="position() != last()">; </xsl:if>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'modification']">
		<xsl:text>, modified — </xsl:text>
		<xsl:apply-templates />
	</xsl:template>
	
	
	<!-- <xsl:template match="*[local-name() = 'termexample'] | *[local-name() = 'termnote'] | *[local-name() = 'termsource']"/> -->
	
	<!-- temporary solution for https://github.com/metanorma/iso-10303-2/issues/44 -->
	<xsl:template match="*[local-name() = 'clause']/*[local-name() = 'domain'] | *[local-name() = 'clause']/*[local-name() = 'termsource']" priority="2">
		<xsl:text disable-output-escaping="yes">&lt;!--</xsl:text>
			<xsl:copy-of select="."/>
		<xsl:text disable-output-escaping="yes">--&gt;</xsl:text>
	</xsl:template>
	
	<!-- <xsl:template match="*[local-name() = 'preferred'] | *[local-name() = 'admitted'] | *[local-name() = 'deprecates'] | *[local-name() = 'domain']"/> -->
	<xsl:template match="*[local-name() = 'preferred'] | *[local-name() = 'admitted'] | *[local-name() = 'deprecates'] | *[local-name() = 'domain']"> <!--  mode="termEntry" -->
		<xsl:param name="sectionNum"/>
		
		<!-- <xsl:variable name="current_id">
			<xsl:call-template name="getId"/>
		</xsl:variable>
		
		<xsl:variable name="id" select="$elements//element[@source_id = $current_id]/@id"/>	 -->
		<!-- <xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable> -->
		<xsl:variable name="number"><xsl:number count="*[local-name() = 'preferred'] | *[local-name() = 'admitted'] | *[local-name() = 'deprecates'] | *[local-name() = 'domain']"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:for-each select="ancestor::*[local-name() = 'term'][1]">
				<xsl:call-template name="getId"/><xsl:text>-</xsl:text><xsl:value-of select="$number"/>
			</xsl:for-each>
		</xsl:variable>
		
		<tbx:tig id="{$id}">
			<tbx:term><xsl:apply-templates /></tbx:term>
			<tbx:partOfSpeech value="noun"/>
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
					<xsl:when test="$element_name = 'preferred' and not(following-sibling::*[local-name() = 'admitted'] or preceding-sibling::*[local-name() = 'admitted'] or
					following-sibling::*[local-name() = 'deprecates'] or preceding-sibling::*[local-name() = 'deprecates'])"></xsl:when>
					<xsl:otherwise>
						<tbx:normativeAuthorization value="{$normativeAuthorization}"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
		</tbx:tig>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'p']" name="p">
		<!-- <xsl:if test="$debug = 'true'">
			<xsl:message>DEBUG: p processing <xsl:number level="any" count="*[local-name() = 'p']"/></xsl:message>
		</xsl:if> -->
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
														$parent_name = 'termnote' or 
														$parent_name = 'modification' or
														$parent_name = 'dd'">
				<xsl:apply-templates />
			</xsl:when>
			<xsl:otherwise>
				<p>
					<xsl:if test="$organization != 'BSI'">
						<xsl:copy-of select="@id"/>
					</xsl:if>
					<xsl:apply-templates select="@*"/>
					<xsl:apply-templates />
				</p>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'p']/@align"/>
	
	<xsl:template match="*[local-name() = 'p' or local-name() = 'ul' or local-name() = 'ol']/@id">
		<xsl:variable name="p_id" select="."/>
		<xsl:choose>
			<xsl:when test="$organization = 'BSI' and starts-with($p_id, '_') and not(//*[@target = $p_id])"></xsl:when> <!-- remove @id -->
			<xsl:otherwise>
				<xsl:attribute name="id"><xsl:value-of select="."/></xsl:attribute>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template match="*[local-name() = 'ul']">
		<list> 
			<xsl:apply-templates select="@*"/>
			<xsl:attribute name="list-type">
				<xsl:choose>
						<xsl:when test="normalize-space(@type) = ''">bullet</xsl:when> <!-- even when <label>—</label> ! -->
						<xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
					</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates />
		</list>
		<xsl:for-each select="*[local-name() = 'note']">
			<xsl:call-template name="note"/>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="*[local-name() = 'ul']/@type"/>
	
	<xsl:template match="*[local-name() = 'ol']">
		<list>
			<xsl:apply-templates select="@*"/>
			<xsl:attribute name="list-type">
				<xsl:choose>
					<!-- <xsl:when test="@type = 'arabic'">alpha-lower</xsl:when> -->
					<xsl:when test="@type = 'arabic'">order</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="normalize-space(@type) = ''">alpha-lower</xsl:when>
							<xsl:when test="@type = 'alphabet'">alpha-lower</xsl:when>
							<xsl:when test="@type = 'alphabet_upper'">alpha-upper</xsl:when>
							<xsl:when test="@type = 'roman'">roman-lower</xsl:when>
							<xsl:when test="@type = 'roman_upper'">roman-upper</xsl:when>
							<xsl:when test="@type = 'arabic'">arabic</xsl:when>
							<xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates />
		</list>
		<xsl:for-each select="*[local-name() = 'note']">
			<xsl:call-template name="note"/>
		</xsl:for-each>
	</xsl:template>
	<xsl:template match="*[local-name() = 'ol']/@type"/>
	<xsl:template match="*[local-name() = 'ol']/@start"/>

	<xsl:template match="*[local-name() = 'ul']/*[local-name() = 'note'] | *[local-name() = 'ol']/*[local-name() = 'note']" priority="2"/>
	
	<xsl:template match="*[local-name() = 'li']">
		<list-item>
			<!-- <xsl:if test="@id">
				<xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
			</xsl:if> -->
			<xsl:copy-of select="@id"/>
			<xsl:choose>
				<xsl:when test="local-name(..) = 'ul' and (../@type = 'bullet' or normalize-space(../@type) = '')"><label>•</label></xsl:when>
				<xsl:when test="local-name(..) = 'ul' and ../@type != 'simple'"><label>—</label></xsl:when>
				
				<xsl:when test="local-name(..) = 'ol'">
					<xsl:variable name="type" select="parent::*/@type"/>
					<xsl:variable name="start_value">
						<xsl:choose>
							<xsl:when test="normalize-space(parent::*/@start) != ''">
								<xsl:value-of select="number(parent::*/@start) - 1"/><!-- if start="3" then start_value=2 + xsl:number(1) = 3 -->
							</xsl:when>
							<xsl:otherwise>0</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="curr_value">
						<xsl:number/>
					</xsl:variable>
					
					<xsl:choose>
						<xsl:when test="$type = 'arabic'">
							<label><xsl:number value="$start_value + $curr_value" format="1)"/></label>
						</xsl:when>
						<xsl:when test="$type = 'alphabet'">
							<label><xsl:number value="$start_value + $curr_value" format="a)" lang="en"/></label>
						</xsl:when>
						<xsl:when test="$type = 'alphabet_upper'">
							<label><xsl:number value="$start_value + $curr_value" format="A)" lang="en"/></label>
						</xsl:when>
						<xsl:when test="$type = 'roman'">
							<label><xsl:number value="$start_value + $curr_value" format="i)" lang="en"/></label>
						</xsl:when>
						<xsl:when test="$type = 'roman_upper'">
							<label><xsl:number value="$start_value + $curr_value" format="I)" lang="en"/></label>
						</xsl:when>
						<xsl:otherwise>
							<label><xsl:number value="$start_value + $curr_value" format="a)" lang="en"/></label>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
			</xsl:choose>
			<xsl:apply-templates />
		</list-item>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'example']">
		<xsl:variable name="clause_id" select="ancestor::*[local-name() = 'clause'][1]/@id"/>		
		<non-normative-example>
			<label>
				<xsl:text>EXAMPLE</xsl:text>
				<xsl:if test="ancestor::*[local-name() = 'amend']/*[local-name() = 'autonumber'][@type = 'example']">
					<xsl:text> </xsl:text><xsl:value-of select="ancestor::*[local-name() = 'amend']/*[local-name() = 'autonumber'][@type = 'example']/text()"/>
				</xsl:if>
				<xsl:if test="count(ancestor::*[local-name() = 'clause'][1]//*[local-name() = 'example']) &gt; 1">
					<xsl:text> </xsl:text><xsl:number level="any" count="*[local-name() = 'example'][ancestor::*[local-name() = 'clause'][@id = $clause_id]]"/>
				</xsl:if>
			</label>
			<xsl:apply-templates/>
		</non-normative-example>
	</xsl:template>
	
	
	
	<xsl:template match="*[local-name() = 'note']" name="note">
		<!-- <xsl:if test="$debug = 'true'">
			<xsl:message>DEBUG: note processing <xsl:number level="any" count="*[local-name() = 'note']"/></xsl:message>
		</xsl:if> -->
		<xsl:variable name="clause_id" select="ancestor::*[local-name() = 'clause'][1]/@id"/>		
		<non-normative-note>
			<xsl:if test="not(*[local-name() = 'name'])">
				<label>
					<xsl:text>NOTE</xsl:text>
					<xsl:if test="ancestor::*[local-name() = 'amend']/*[local-name() = 'autonumber'][@type = 'note']">
						<xsl:text>&#xA0;</xsl:text><xsl:value-of select="ancestor::*[local-name() = 'amend']/*[local-name() = 'autonumber'][@type = 'note']/text()"/>
					</xsl:if>
					<xsl:if test="count(ancestor::*[local-name() = 'clause'][1]//*[local-name() = 'note']) &gt; 1">
						<xsl:text>&#xA0;</xsl:text><xsl:number level="any" count="*[local-name() = 'note'][ancestor::*[local-name() = 'clause'][@id = $clause_id]]"/>
					</xsl:if>
				</label>
			</xsl:if>
			<xsl:apply-templates/>
		</non-normative-note>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'note']/*[local-name() = 'name']" priority="2">
		<label><xsl:apply-templates /></label>
	</xsl:template>
	
	<xsl:variable name="bibitems_URN_">
		<xsl:for-each select="//*[local-name() = 'bibitem'][*[local-name() = 'docidentifier'][@type = 'URN']]">
			<bibitem>
				<xsl:copy-of select="@id"/>
				<urn><xsl:value-of select="*[local-name() = 'docidentifier'][@type = 'URN']"/></urn>
			</bibitem>
		</xsl:for-each>
	</xsl:variable>
	<xsl:variable name="bibitems_URN" select="xalan:nodeset($bibitems_URN_)"/>
		
	<xsl:template match="*[local-name() = 'eref']">
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
		<std>
			<xsl:attribute name="type">
				<xsl:call-template name="setDatedUndatedType">
					<xsl:with-param name="value" select="$citeas"/>
				</xsl:call-template>
			</xsl:attribute>
			<xsl:variable name="reference" select="@bibitemid"/>
			<!-- <xsl:variable name="docidentifier_URN" select="//*[local-name() = 'bibitem'][@id = $reference]/*[local-name() = 'docidentifier'][@type = 'URN']"/> -->
			<xsl:variable name="docidentifier_URN" select="$bibitems_URN/bibitem[@id = $reference]/urn"/>
			<xsl:attribute name="std-id">
				<xsl:choose>
					<xsl:when test="$docidentifier_URN != ''">
						<xsl:value-of select="$docidentifier_URN"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$reference"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
      
			<std-ref>
				
				<xsl:choose>
					<xsl:when test="$organization = 'BSI'">
						<xsl:value-of select="translate($citeas, ' ', '&#xA0;')"/><!-- replace space to non-break space -->
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$citeas"/>
					</xsl:otherwise>
				</xsl:choose>
				
			</std-ref>
			<xsl:apply-templates select="*[local-name() = 'localityStack']"/>
		</std>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'link']">
    <xsl:choose>
      <xsl:when test="normalize-space() = ''">
        <uri><xsl:value-of select="@target"/></uri>
      </xsl:when>
      <xsl:otherwise>
        <ext-link xlink:type="simple">
          <xsl:attribute name="xlink:href">
            <xsl:value-of select="@target"/>
          </xsl:attribute>
          <xsl:apply-templates />
        </ext-link>
      </xsl:otherwise>
    </xsl:choose>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'strong']">
		<bold><xsl:apply-templates /></bold>
	</xsl:template>

	<xsl:template match="*[local-name() = 'sup'][*[local-name() = 'stem']]">
		<xsl:apply-templates />
	</xsl:template>

	<!-- <xsl:template match="*[local-name() = 'definition']//*[local-name() = 'em']" priority="2"> -->
	
	<!-- ===================== -->
	<!-- tbx:entailedTerm -->
	<!-- ===================== -->
	<!-- Conversion from: -->
	<!-- <em>objectives</em> (<xref target="term-objective"><strong>3.8</strong></xref>) -->
	<!-- to: -->
	<!-- <tbx:entailedTerm target="term_3.8">objectives (3.8)</tbx:entailedTerm> -->
	<!-- for em, when next is xref -->
	<xsl:template match="*[local-name() = 'em'][following-sibling::node()[1][. = ' ('] and following-sibling::*[1][local-name() = 'xref']]" priority="2">
		<tbx:entailedTerm target="{following-sibling::*[1]/@target}">
			<xsl:apply-templates />
			<xsl:apply-templates select="following-sibling::*[1]" mode="em_xref"/><!-- get xref -->
		</tbx:entailedTerm>
	</xsl:template>
	
	<!-- for xref, when previous is em -->
	<xsl:template match="*[local-name() = 'xref']" mode="em_xref">
		<xsl:text> </xsl:text>
		<!-- preceding-sibling-text='<xsl:value-of select="normalize-space(preceding-sibling::node()[1])"/>' -->
		<xsl:if test="normalize-space(preceding-sibling::node()[1]) ='('">(</xsl:if>
		<xsl:value-of select="normalize-space()"/>
		<xsl:if test="substring(normalize-space(following-sibling::node()[1]),1,1) =')'">)</xsl:if>
		<!-- following-sibling-text='<xsl:value-of select="following-sibling::node()[1]"/>' -->
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'xref'][preceding-sibling::node()[1][. = ' ('] and preceding-sibling::*[1][local-name() = 'em']]" priority="2"/>
	
	<!-- remove '(' between em and xref -->
	<xsl:template match="text()[normalize-space() = '('][preceding-sibling::*[1][local-name() = 'em'] and following-sibling::*[1][local-name() = 'xref']]"/>
	<!-- remove ')' after em and xref -->
	<xsl:template match="text()[substring(normalize-space(),1,1) = ')'][preceding-sibling::*[1][local-name() = 'xref'] and preceding-sibling::*[2][local-name() = 'em']]">
		<xsl:value-of select="substring-after(., ')')"/>
	</xsl:template>
	<!-- ===================== -->
	<!-- END tbx:entailedTerm -->
	<!-- ===================== -->
	
	<xsl:template match="*[local-name() = 'em']">
		<italic><xsl:apply-templates /></italic>
	</xsl:template>

	<xsl:template match="*[local-name() = 'br']">
		<break/>
	</xsl:template>
	
	
	<xsl:template match="*[local-name() = 'th'][*[local-name() = 'strong']][*[local-name() = 'br'][parent::*[local-name() = 'strong']]]/node()[1][self::text()]">
		<xsl:text disable-output-escaping="yes">&lt;bold&gt;</xsl:text>
		<xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'th'][*[local-name() = 'strong']]/*[local-name() = 'br'][parent::*[local-name() = 'strong']]">
		<xsl:text disable-output-escaping="yes">&lt;/bold&gt;</xsl:text>
		<break/>
		<xsl:text disable-output-escaping="yes">&lt;bold&gt;</xsl:text>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'xref'][normalize-space() != '' and string-length(normalize-space()) = string-length(translate(normalize-space(), '0123456789', '')) and not(contains(normalize-space(), 'Annex'))]" priority="2">
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
	
	<xsl:template match="*[local-name() = 'xref']">
		<xsl:variable name="section" select="$elements//element[@source_id = current()/@target]/@section"/>
		<!-- <xsl:variable name="id" select="$elements//element[@source_id = current()/@target]/@id"/> -->
		<xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable>
		
		<xsl:variable name="parent" select="$elements//element[@source_id = current()/@target]/@parent"/>
		<xsl:variable name="ref_type">
			<xsl:choose>
        <xsl:when test="$parent = 'figure'">fig</xsl:when>
				<xsl:when test="$parent = 'table'">table</xsl:when>
				<xsl:when test="$parent = 'annex'">app</xsl:when>
				<xsl:when test="$parent = 'fn'">fn</xsl:when>
				<xsl:when test="$parent = 'bibitem'">bibr</xsl:when>
				<xsl:otherwise>sec</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- parent=<xsl:value-of select="$parent"/> -->
		<xref> <!-- ref-type="{$ref_type}" rid="{$id}" --> <!-- replaced by xsl:attribute name=... for save ordering -->
      <xsl:attribute name="ref-type">
        <xsl:value-of select="$ref_type"/>
      </xsl:attribute>
      <xsl:attribute name="rid"><xsl:value-of select="@target"/></xsl:attribute>
				<!-- <xsl:choose>
					<xsl:when test="normalize-space($id) = ''"><xsl:value-of select="@target"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="$id"/></xsl:otherwise>
				</xsl:choose>
      </xsl:attribute> -->
      
      <xsl:variable name="text_">
        <xsl:value-of select="translate($section, '&#xA0;', ' ')"/>
      </xsl:variable>
      <xsl:variable name="text">
        <xsl:value-of select="normalize-space($text_)"/>
        <xsl:if test="normalize-space($text_) = ''"><!-- in case of term -->
          <xsl:value-of select="$elements//element[@id = current()/@target]/@section"/>
        </xsl:if>
      </xsl:variable>
      <!-- <xsl:choose>
        <xsl:when test="./*">
          <xsl:apply-templates mode="internalFormat">
            <xsl:with-param name="text" select="$text"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$text"/>
        </xsl:otherwise>
      </xsl:choose> -->
			<xsl:apply-templates />
		</xref>
	</xsl:template>
	
  <xsl:template match="*[local-name() = 'strong'] | *[local-name() = 'em'] | *" mode="internalFormat">
    <xsl:param name="text"/>
    <xsl:variable name="element">
      <xsl:choose>
        <xsl:when test="local-name() = 'strong'">bold</xsl:when>
        <xsl:when test="local-name() = 'em'">italic</xsl:when>
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
  
  
	<!-- need to be tested (find original NISO) -->
	<xsl:template match="*[local-name() = 'callout']">
		<xref ref-type="other" rid="{@target}">
			<xsl:apply-templates/>
		</xref>
	</xsl:template>
	
	<!-- https://github.com/metanorma/mn2sts/issues/8 -->
	<xsl:template match="*[local-name() = 'admonition']">
		<non-normative-note id="{@id}">
			<label><xsl:value-of select="java:toUpperCase(java:java.lang.String.new(@type))"/></label>
			<xsl:apply-templates />
		</non-normative-note>
	</xsl:template>
	
	
	<!-- https://github.com/metanorma/mn2sts/issues/9 -->
	<xsl:template match="*[local-name() = 'quote']">
		<disp-quote id="{@id}">
			<xsl:apply-templates select="*[local-name() = 'p']"/>
			<xsl:if test="*[local-name() = 'source'] or *[local-name() = 'author']">
				<related-object>
					<xsl:apply-templates select="*[local-name() = 'author']" mode="disp-quote"/>
					<xsl:if test="*[local-name() = 'source'] and *[local-name() = 'author']">, </xsl:if>
					<xsl:apply-templates select="*[local-name() = 'source']" mode="disp-quote"/>
				</related-object>
			</xsl:if>
		</disp-quote>
	</xsl:template>	
	<xsl:template match="*[local-name() = 'quote']/*[local-name() = 'source']"/>
	<xsl:template match="*[local-name() = 'quote']/*[local-name() = 'author']"/>
	
	<xsl:template match="*[local-name() = 'quote']/*[local-name() = 'author']" mode="disp-quote">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'quote']/*[local-name() = 'source']" mode="disp-quote">
		<xsl:value-of select="@citeas"/>
		<xsl:apply-templates mode="disp-quote"/>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'localityStack']" mode="disp-quote">		
		<xsl:for-each select="*[local-name()='locality']">
			<xsl:if test="position() = 1"><xsl:text>, </xsl:text></xsl:if>
			<xsl:apply-templates select="." mode="disp-quote"/>
			<xsl:if test="position() != last()"><xsl:text>; </xsl:text></xsl:if>
		</xsl:for-each>	
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'locality']"  mode="disp-quote">
		<xsl:choose>
			<xsl:when test="@type ='clause'">Clause </xsl:when>
			<xsl:when test="@type ='annex'">Annex </xsl:when>
			<xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
		</xsl:choose>
		<xsl:value-of select="*[local-name() = 'referenceFrom']"/>
	</xsl:template>
	

	<!-- https://github.com/metanorma/mn2sts/issues/10 -->
	<xsl:template match="*[local-name() = 'appendix']">
		<sec id="{@id}" sec-type="appendix">
			<xsl:variable name="current_id" select="@id"/>
			<xsl:variable name="section" select="$elements//element[@source_id = $current_id]/@section"/>
			<xsl:if test="$section != ''">
				<label><xsl:value-of select="$section"/></label>
			</xsl:if>
			<xsl:apply-templates/>
		</sec>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'annotation']">
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
	
	
	
	<xsl:template match="*[local-name() = 'table']"> <!-- [*[local-name() = 'name']] -->
		<xsl:variable name="number"><xsl:number level="any"/></xsl:variable>
		<xsl:variable name="current_id">
			<xsl:call-template name="getId"/>
		</xsl:variable>
		<!-- <xsl:variable name="id" select="$elements//element[@source_id = $current_id]/@id"/> -->
		<xsl:variable name="section" select="$elements//element[@source_id = $current_id]/@section"/>
    <xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable>
    <xsl:variable name="wrap-element">
      <xsl:choose>
        <xsl:when test="ancestor::*[local-name() = 'figure']">array</xsl:when>
        <xsl:otherwise>table-wrap</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:element name="{$wrap-element}">
		<!-- <table-wrap id="{$id}"> --> <!-- position="float" -->
      <xsl:attribute name="id">
        <xsl:value-of select="$id"/>
      </xsl:attribute>
			<xsl:variable name="orientation" select="normalize-space(preceding-sibling::*[1][local-name() = 'pagebreak']/@orientation)"/>
			<xsl:if test="$orientation = 'landscape'">
				<xsl:attribute name="orientation"><xsl:value-of select="$orientation"/></xsl:attribute>
			</xsl:if>
			<xsl:variable name="label">
				<xsl:choose>
					<xsl:when test="ancestor::*[local-name() = 'amend']/*[local-name() = 'autonumber'][@type = 'table']">
						<xsl:value-of select="ancestor::*[local-name() = 'amend']/*[local-name() = 'autonumber'][@type = 'table']/text()"/>
					</xsl:when>
          <xsl:when test="ancestor::*[local-name() = 'figure']"></xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$section"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:if test="normalize-space($label) != ''">
				<label>
					<xsl:value-of select="$label"/>
				</label>
			</xsl:if>
			<xsl:apply-templates select="*[local-name() = 'name']" mode="table"/>				
			<table>
				<xsl:copy-of select="@*[not(local-name() = 'id')]"/>
				<!-- <xsl:attribute name="width">
					<xsl:choose>
						<xsl:when test="@width"><xsl:value-of select="@width"/></xsl:when>
						<xsl:otherwise>100%</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute> -->
				<xsl:apply-templates select="*[local-name() = 'colgroup']" mode="table"/>
				<xsl:apply-templates select="*[local-name() = 'thead']" mode="table"/>
				<xsl:apply-templates select="*[local-name() = 'tfoot']" mode="table"/>
				<xsl:apply-templates select="*[local-name() = 'tbody']" mode="table"/>
				<xsl:apply-templates />
			</table>
			
			<!-- move notes outside table -->
			<xsl:if test="*[local-name() = 'note']">
				<table-wrap-foot>
					<xsl:for-each select="*[local-name() = 'note']">
						<xsl:call-template name="note"/>
					</xsl:for-each>
				</table-wrap-foot>
			</xsl:if>
		<!-- </table-wrap> -->
    </xsl:element>
		
	</xsl:template>

	
	
	<xsl:template match="*[local-name() = 'table']/*[local-name() = 'note']" priority="2"/>
	
	<xsl:template match="*[local-name() = 'name']"/>
	<xsl:template match="*[local-name() = 'name']" mode="table">
		<caption>
			<title>
				<xsl:apply-templates/>
			</title>
		</caption>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'colgroup'] | *[local-name() = 'thead'] | *[local-name() = 'tfoot'] | *[local-name() = 'tbody']"/>
	<xsl:template match="*[local-name() = 'colgroup'] | *[local-name() = 'thead'] | *[local-name() = 'tfoot'] | *[local-name() = 'tbody']" mode="table">
		<xsl:element name="{local-name()}">
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates />
		</xsl:element>	
	</xsl:template>
	
	
	<xsl:template match="*[local-name() = 'th']">
		<th>
			<xsl:apply-templates select="@*"/>
			<!-- <bold> -->
				<xsl:apply-templates />
			<!-- </bold> -->
		</th>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'dl']">
		<!-- <xsl:variable name="current_id">
			<xsl:call-template name="getId"/>
		</xsl:variable>
		<xsl:variable name="id" select="$elements//element[@source_id = $current_id]/@id"/> -->
		<xsl:choose>
			<xsl:when test="preceding-sibling::*[1][local-name() = 'figure']">
				<xsl:call-template name="create_array"/>
			</xsl:when>
			<xsl:otherwise>
				<p>
					<xsl:call-template name="create_array"/>
				</p>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>

	<xsl:template name="create_array">
		<!-- <xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable> -->
		<array> <!-- id="{$id}" -->
			<xsl:copy-of select="@id"/>
			<xsl:if test="preceding-sibling::*[1][local-name() = 'figure']">
				<xsl:attribute name="content-type">figure-index</xsl:attribute>
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
		<xsl:for-each select="*[local-name() = 'note']">
			<xsl:call-template name="note"/>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'dl']/*[local-name() = 'note']" priority="2"/>
	
	
	<xsl:template match="*[local-name() = 'dt']">
		<tr>
			<td align="left" scope="row" valign="top"><xsl:apply-templates/></td>
			<xsl:apply-templates select="following-sibling::*[local-name() = 'dd'][1]" mode="array"/>
			
		</tr>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'dd']"/>
	<xsl:template match="*[local-name() = 'dd']" mode="array">
		<td align="left" valign="top"><xsl:apply-templates/></td>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'figure'][*[local-name() = 'figure']]" priority="1">
		<xsl:variable name="current_id">
			<xsl:call-template name="getId"/>
		</xsl:variable>
		<!-- <xsl:variable name="id" select="$elements//element[@source_id = $current_id]/@id"/> -->
		<xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable>
		<xsl:variable name="section" select="$elements//element[@source_id = $current_id]/@section"/>
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
			<label><xsl:value-of select="$section"/></label>
			<xsl:apply-templates />
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'figure']">
		<xsl:variable name="current_id">
			<xsl:call-template name="getId"/>
		</xsl:variable>
		<!-- <xsl:variable name="id" select="$elements//element[@source_id = $current_id]/@id"/> -->
		<xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable>
		<xsl:variable name="section" select="$elements//element[@source_id = $current_id]/@section"/>
		
		<xsl:choose>
			<xsl:when test="$organization = 'BSI' and parent::*[local-name() = 'figure']">
				<graphic xlink:href="{*[local-name() = 'image']/@src}">
					<xsl:apply-templates select="*[not(local-name() = 'image')]"/>
				</graphic>
			</xsl:when>
			<xsl:otherwise>	
				<fig id="{$id}" fig-type="figure">
					<label>
						<xsl:choose>
							<xsl:when test="ancestor::*[local-name() = 'amend']/*[local-name() = 'autonumber'][@type = 'figure']">
								<xsl:value-of select="ancestor::*[local-name() = 'amend']/*[local-name() = 'autonumber'][@type = 'figure']/text()"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$section"/>
							</xsl:otherwise>
						</xsl:choose>
					</label>
					<xsl:apply-templates />
				</fig>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template match="*[local-name() = 'figure']/*[local-name() = 'name']" priority="2">
		<xsl:variable name="label" select="substring-before(node()[1][self::text()], '&#xa0;')"/>
		<xsl:if test="../parent::*[local-name() = 'figure'] and $organization = 'BSI' and normalize-space($label) != ''">
			<label><xsl:value-of select="$label"/></label>
		</xsl:if>
		<caption>
			<title>
				<xsl:apply-templates/>
			</title>
		</caption>
	</xsl:template>
	
	<xsl:template match="*[local-name()='table' or local-name()='figure']/*[local-name() = 'name']/node()[1][self::text()]" priority="2">
		<xsl:choose>
			<xsl:when test="contains(., '—')">
				<xsl:value-of select="normalize-space(substring-after(., '—'))"/>
			</xsl:when>
			<xsl:when test="../parent::*[local-name() = 'figure'] and contains(., '&#xa0;')"><!-- move text like 'a)' to label, see above -->
				<xsl:value-of select="normalize-space(substring-after(., '&#xa0;'))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'figure']/*[local-name() = 'image']">
		<!--<xsl:variable name="current_id">
			<xsl:call-template name="getId"/>
		</xsl:variable>
		 <xsl:variable name="id" select="$elements//element[@source_id = $current_id]/@id"/> -->
		<!-- <xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable> -->
		<!-- NISO STS TagLibrary: https://www.niso-sts.org/TagLibrary/niso-sts-TL-1-0-html/element/graphic.html -->
		<graphic xlink:href="{@id}"> <!-- id="{$id}"  xlink:href="{$id}"-->
			<xsl:copy-of select="@id"/>
			<!-- <xsl:copy-of select="@mimetype"/> -->
			<xsl:apply-templates select="@*"/>
			<!-- <xsl:processing-instruction name="isoimg-id">
				<xsl:value-of select="@src"/>
			</xsl:processing-instruction> -->
			
		</graphic>
	</xsl:template>
	
  <xsl:template match="*[local-name() = 'image'][not(parent::*[local-name() = 'figure'])]">
    <graphic>
			<xsl:apply-templates select="@*"/>
		</graphic>
  </xsl:template>
  
	<xsl:template match="*[local-name() = 'image']/@src">
		<xsl:attribute name="xlink:href">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'image']/@mimetype">
		<xsl:copy-of select="."/>
	</xsl:template> <!-- created image processing -->
	<xsl:template match="*[local-name() = 'image']/@alt">
		<xsl:element name="alt-text">
			<xsl:value-of select="."/>
		</xsl:element>
	</xsl:template>
	<xsl:template match="*[local-name() = 'image']/@height"/>	
	<xsl:template match="*[local-name() = 'image']/@width"/>	
	
	
	<xsl:template match="*[local-name() = 'formula']">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'stem']">
		<xsl:if test="parent::*[local-name() = 'th'][*[local-name() = 'strong']]">
			<xsl:text disable-output-escaping="yes">&lt;/bold&gt;</xsl:text>
		</xsl:if>
		<disp-formula>
			<xsl:if test="parent::*[local-name() = 'formula']">
				<xsl:variable name="current_id" select="../@id"/>		
				<!-- <xsl:variable name="id" select="$elements//element[@source_id = $current_id]/@id"/> -->
				<xsl:variable name="id"><xsl:value-of select="$current_id"/></xsl:variable><!-- <xsl:call-template name="getId"/> -->
				<xsl:attribute name="id">
					<xsl:value-of select="$id"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates />
		</disp-formula>
		<xsl:if test="parent::*[local-name() = 'th'][*[local-name() = 'strong']]">
			<xsl:text disable-output-escaping="yes">&lt;bold&gt;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="mml:*">
		<xsl:element name="mml:{local-name()}">		
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'tt']">
		<monospace>
			<xsl:apply-templates/>
		</monospace>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'smallcap']">
		<sc>
			<xsl:apply-templates/>
		</sc>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'review']"/>

	<xsl:template match="*[local-name() = 'sourcecode']">
		<xsl:choose>
			<xsl:when test="$format = 'NISO'">
				<code>
					<xsl:apply-templates select="@*"/>
					<xsl:apply-templates/>
				</code>
			</xsl:when>
			<!-- ISO -->
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
	</xsl:template>
		
	<xsl:template match="*[local-name() = 'sourcecode']/@lang">
		<xsl:attribute name="language">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'title']" name="title">
		<xsl:choose>
			<xsl:when test="not(*[local-name() = 'tab']) and normalize-space(translate(., '0123456789.', '')) = ''"><!-- put number in label, see above --></xsl:when>
			<xsl:otherwise>
				<title>
					<xsl:choose>
						<xsl:when test="*[local-name() = 'tab']">
							<xsl:apply-templates select="*[local-name() = 'tab'][1]/following-sibling::node()"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates />
						</xsl:otherwise>
					</xsl:choose>
				</title>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'title']/@depth"/>
	<xsl:template match="*[local-name() = 'tab']"/>
	
	<xsl:template match="*[local-name() = 'amend']">
		<!-- <p id="{@id}"> -->
			<xsl:apply-templates />
		<!-- </p> -->
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'amend']/*[local-name() = 'description']">
		<xsl:choose>
			<xsl:when test="$format = 'NISO'">
				<editing-instruction>
					<xsl:if test="parent::*[local-name() = 'amend']/@id">
						<xsl:attribute name="id">
							<xsl:value-of select="parent::*[local-name() = 'amend']/@id"/>
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
	
	<xsl:template match="*[local-name() = 'amend']/*[local-name() = 'description']/*[local-name() = 'p']">
		<xsl:choose>
			<xsl:when test="$format = 'NISO'">
				<xsl:call-template name="p"/>
			</xsl:when>
			<xsl:otherwise>
				<p id="{@id}">
					<xsl:if test="ancestor::*[local-name() = 'amend']/@change">
						<xsl:attribute name="content-type">
							<xsl:value-of select="ancestor::*[local-name() = 'amend']/@change"/>
						</xsl:attribute>
					</xsl:if>
					<xsl:apply-templates />
				</p>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'amend']/*[local-name() = 'newcontent']">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'amend']/*[local-name() = 'autonumber']"/>
	
	<xsl:template match="comment()[starts-with(., 'STS: ')]">
		<xsl:value-of disable-output-escaping="yes" select="substring-after(., 'STS: ')"/>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'indexsect']">
		<sec sec-type="index">
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates/>
		</sec>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'pagebreak']">
		<xsl:choose>
			<xsl:when test="@orientation = 'landscape' and following-sibling::*[1][local-name() = 'table']"></xsl:when> <!-- attribute orientation will be added in table-wrap element -->
			<xsl:when test="@orientation = 'portrait' and preceding-sibling::*[1][local-name() = 'table'] and preceding-sibling::*[2][local-name() = 'pagebreak']"></xsl:when> <!-- attribute orientation  added in table-wrap element -->
			<xsl:otherwise>
				<xsl:processing-instruction name="Para">
					<xsl:text>Page_Break</xsl:text>
				</xsl:processing-instruction>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	
	<xsl:template name="getLevel">
		<xsl:variable name="level_total" select="count(ancestor::*)"/>
		<xsl:variable name="level">
			<xsl:choose>
				<xsl:when test="ancestor::*[local-name() = 'preface']">
					<xsl:value-of select="$level_total - 1"/>
				</xsl:when>
				<xsl:when test="ancestor::*[local-name() = 'sections']">
					<xsl:value-of select="$level_total - 1"/>
				</xsl:when>
				<xsl:when test="ancestor::*[local-name() = 'bibliography']">
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
	
	<xsl:template name="getSection">
		<xsl:param name="sectionNum"/>
		<xsl:variable name="level">
			<xsl:call-template name="getLevel"/>
		</xsl:variable>		
		<xsl:variable name="section">
			<xsl:choose>
				<xsl:when test="local-name() = 'dl'"><xsl:number format="a" level="any"/></xsl:when>
				<xsl:when test="local-name() = 'bibitem' and ancestor::*[local-name() = 'references'][@normative='true']">norm_ref_<xsl:number/></xsl:when>
				<xsl:when test="local-name() = 'bibitem'">ref_<xsl:number/></xsl:when>
				<xsl:when test="ancestor::*[local-name() = 'bibliography']">
					<xsl:value-of select="$sectionNum"/>
				</xsl:when>
				<xsl:when test="local-name() = 'annex'">
					<xsl:number format="A" level="any" count="*[local-name() = 'annex']"/>
				</xsl:when>
				<xsl:when test="ancestor::*[local-name() = 'sections']">
					<!-- 1, 2, 3, 4, ... from main section (not annex, bibliography, ...) -->
					<xsl:choose>
						<xsl:when test="local-name() = 'table'"><xsl:number format="1" level="any" count="*[local-name() = 'sections']//*[local-name() = 'table']"/></xsl:when>
						<xsl:when test="local-name() = 'figure'"><xsl:number format="1" level="any" count="*[local-name() = 'sections']//*[local-name() = 'figure']"/></xsl:when>
						<xsl:when test="$level = 1">
							<xsl:value-of select="$sectionNum"/>
						</xsl:when>
						<xsl:when test="$level &gt;= 2">
							<xsl:variable name="num">
								<xsl:number format=".1" level="multiple" count="*[local-name() = 'clause']/*[local-name() = 'clause'] | 
																																										*[local-name() = 'clause']/*[local-name() = 'terms'] | 
																																										*[local-name() = 'terms']/*[local-name() = 'term'] | 
																																										*[local-name() = 'clause']/*[local-name() = 'term'] |  
																																										*[local-name() = 'terms']/*[local-name() = 'clause'] |
																																										*[local-name() = 'terms']/*[local-name() = 'definitions'] |
																																										*[local-name() = 'definitions']/*[local-name() = 'clause'] |
																																										*[local-name() = 'clause']/*[local-name() = 'definitions'] |
																																										*[local-name() = 'definitions']/*[local-name() = 'definitions']"/>
							</xsl:variable>
							<xsl:variable name="addon">
								<xsl:choose>
									<xsl:when test="local-name() = 'preferred' or local-name() = 'admitted' or local-name() = 'deprecates' or local-name() = 'domain'">
										<xsl:number format="-1" count="*[local-name() = 'preferred'] | *[local-name() = 'admitted'] | *[local-name() = 'deprecates'] | *[local-name() = 'domain']"/>
									</xsl:when>
									<xsl:otherwise></xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<xsl:value-of select="concat($sectionNum, $num, $addon)"/>
							
						</xsl:when>
						<xsl:otherwise></xsl:otherwise>
					</xsl:choose>
				</xsl:when>				
				<xsl:when test="ancestor::*[local-name() = 'annex']">
					<xsl:variable name="annexid" select="normalize-space(/*/*[local-name() = 'bibdata']/*[local-name() = 'ext']/*[local-name() = 'structuredidentifier']/*[local-name() = 'annexid'])"/>
					<xsl:choose>
						<xsl:when test="local-name() = 'table'">
							<xsl:variable name="curr_annexid" select="ancestor::*[local-name() = 'annex']/@id"/>							
							<xsl:number format="A" count="*[local-name() = 'annex']"/>
							<xsl:number format=".1" level="any" count="*[local-name() = 'table'][ancestor::*[local-name() = 'annex']/@id = $curr_annexid]"/>
						</xsl:when>						
						<xsl:when test="local-name() = 'figure'">
							<xsl:number format="A.1-1" level="multiple" count="*[local-name() = 'annex'] | *[local-name() = 'figure']"/>
						</xsl:when>
						<xsl:when test="$level = 1">							
							<xsl:choose>
								<xsl:when test="count(//*[local-name() = 'annex']) = 1 and $annexid != ''">
									<xsl:value-of select="$annexid"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:number format="A" level="any" count="*[local-name() = 'annex']"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>							
							<xsl:choose>
								<xsl:when test="count(//*[local-name() = 'annex']) = 1 and $annexid != ''">
									<xsl:value-of select="$annexid"/><xsl:number format=".1" level="multiple" count="*[local-name() = 'clause']"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:number format="A.1" level="multiple" count="*[local-name() = 'annex'] | *[local-name() = 'clause']"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="ancestor::*[local-name() = 'preface']"> <!-- if preface and there is clause(s) -->
					<xsl:choose>
						<xsl:when test="$level = 1 and  ..//*[local-name() = 'clause']">0</xsl:when>
						<xsl:when test="$level &gt;= 2">
							<xsl:variable name="num">
								<xsl:number format=".1" level="multiple" count="*[local-name() = 'clause']"/>
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
	
	<xsl:template name="capitalize">
		<xsl:param name="str" />
		<xsl:value-of select="java:toUpperCase(java:java.lang.String.new(substring($str, 1, 1)))"/>
		<xsl:value-of select="substring($str, 2)"/>		
	</xsl:template>

	<xsl:template name="setDatedUndatedType">
		<xsl:param name="value"/>
		<xsl:choose>
			<xsl:when test="substring($value, string-length($value) - 4, 1) = ':' and translate(substring($value, string-length($value) - 3), '0123456789', '') = ''">dated</xsl:when>
			<xsl:when test="java:org.metanorma.utils.RegExHelper.matches('^.*:\d{4}\D.*$', $value) = 'true'">dated</xsl:when>
			<xsl:otherwise>undated</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
</xsl:stylesheet>