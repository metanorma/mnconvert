<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
		xmlns:mml="http://www.w3.org/1998/Math/MathML" 
		xmlns:tbx="urn:iso:std:iso:30042:ed-1" 
		xmlns:xlink="http://www.w3.org/1999/xlink" 
		xmlns:xalan="http://xml.apache.org/xalan" 
		xmlns:java="http://xml.apache.org/xalan/java" 
		xmlns:java_char="http://xml.apache.org/xalan/java/java.lang.Character" 
		xmlns:redirect="http://xml.apache.org/xalan/redirect"
		exclude-result-prefixes="mml tbx xlink xalan java java_char" 
		extension-element-prefixes="redirect"
		version="1.0">

	<xsl:output method="text" encoding="UTF-8"/>
	
	<xsl:param name="split-bibdata">false</xsl:param>
	
	<xsl:param name="debug">false</xsl:param>

	<xsl:param name="docfile_name">document</xsl:param> <!-- Example: iso-tc154-8601-1-en , or document -->
	<xsl:param name="docfile_ext">adoc</xsl:param> <!-- adoc -->
	
	<xsl:param name="pathSeparator" select="'/'"/>
	
	<xsl:param name="outpath"/>
	
	<xsl:param name="imagesdir" select="'images'"/>
	
	<!-- false --> <!-- true, for new features -->
	<xsl:variable name="demomode">
		<xsl:choose>
			<xsl:when test="/standard/front/iso-meta/doc-ident/proj-id = '59752'">true</xsl:when>
			<xsl:when test="/standard/front/iso-meta/doc-ident/proj-id = '36786'">true</xsl:when>
			<xsl:when test="/standard/front/iso-meta/doc-ident/proj-id = '69315'">true</xsl:when>
			<xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
	</xsl:variable> 
	
	<xsl:variable name="one_document_" select="count(//standard/front/*[contains(local-name(), '-meta')]) = 1"/>
	<xsl:variable name="one_document" select="normalize-space($one_document_)"/>
	
	<xsl:variable name="language" select="//standard/front/*/doc-ident/language"/>
	
	<xsl:variable name="organization">
		<xsl:choose>
			<xsl:when test="/standard/front/nat-meta/std-ident/originator = 'PAS'">PAS</xsl:when>
			<xsl:when test="/standard/front/nat-meta/@originator = 'BSI' or /standard/front/iso-meta/secretariat = 'BSI'">BSI</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="/standard/front/*/doc-ident/sdo"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:variable name="path_" select="concat('body', $pathSeparator, 'body-#lang.adoc[]')"/>
			
	<xsl:variable name="path" select="java:replaceAll(java:java.lang.String.new($path_),'#lang',$language)"/>
	
	<xsl:variable name="sdo">
		<xsl:choose>
			<xsl:when test="normalize-space(//standard/front/*/doc-ident/sdo) != ''">
				<xsl:value-of  select="java:toLowerCase(java:java.lang.String.new(//standard/front/*/doc-ident/sdo))"/>
			</xsl:when>
			<xsl:otherwise>iso</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:variable name="taskCopyImagesFilename" select="concat($outpath, '/task.copyImages.adoc')"/>
	
	<!-- prepare assosiative array - id and index term -->
	<xsl:variable name="index_">
		<xsl:for-each select="//sec[@id = 'ind']//xref">
			<reference rid="{@rid}">
				<xsl:for-each select="ancestor::list-item/p">
					<xsl:for-each select="node()[not(preceding-sibling::xref) and not(self::xref)]">
						<xsl:choose>
							<xsl:when test="self::text() and position() = last()">
								<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.), ',(\s|\h)*$', '')"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:copy-of select="."/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
					<xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
				</xsl:for-each>
			</reference>
		</xsl:for-each>
		<xsl:for-each select="//sec[@id = 'ind']//p[italic/text() = 'see' or italic/text() = 'see also']">
			<reference type="{italic/text()}">
				<xsl:if test="italic/text() = 'see also'">
					<xsl:attribute name="type">also</xsl:attribute>
				</xsl:if>
				<xsl:attribute name="term">
					<xsl:for-each select="italic/following-sibling::node()">
						<xsl:copy-of select="."/>
					</xsl:for-each>
				</xsl:attribute>
				<xsl:for-each select="ancestor::list-item/p">
					<xsl:for-each select="node()[not(preceding-sibling::xref or preceding-sibling::italic) and not(self::xref or self::italic)]">
						<xsl:choose>
							<xsl:when test="self::text() and position() = last()">
								<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.), ',*(\s|\h)*$', '')"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:copy-of select="."/>
							</xsl:otherwise>
						</xsl:choose>
						<xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
					</xsl:for-each>
				</xsl:for-each>
			</reference>
			<xsl:text>&#xa;</xsl:text>
		</xsl:for-each>
		<xsl:for-each select="//sec[@sec-type = 'index']//bold">
			<term><xsl:apply-templates/></term>
		</xsl:for-each>
	</xsl:variable>
	<xsl:variable name="index" select="xalan:nodeset($index_)"/>
	
	
	<xsl:variable name="linearized_xml">
		<xsl:apply-templates select="/" mode="linearize"/>
	</xsl:variable>
	
	<xsl:variable name="remove_word_clause_xml">
		<xsl:apply-templates select="xalan:nodeset($linearized_xml)" mode="remove_word_clause"/>
	</xsl:variable>

	<xsl:variable name="unconstrained_formatting_xml">
		<xsl:apply-templates select="xalan:nodeset($remove_word_clause_xml)" mode="unconstrained_formatting"/>
	</xsl:variable>

	<xsl:variable name="ref_fix">
		<xsl:apply-templates select="xalan:nodeset($unconstrained_formatting_xml)" mode="ref_fix"/>
	</xsl:variable>
	
	<xsl:variable name="updated_xml" select="xalan:nodeset($ref_fix)"/>
	
	<xsl:variable name="regex_refid_replacement" select="'( |&#xA0;|:|\+|/|\-|\(|\)|–|‑)'"/>
	
	<xsl:variable name="refs_">
		<xsl:for-each select="$updated_xml//ref">
			<xsl:copy>
				<xsl:copy-of select="@*"/>
			</xsl:copy>
		</xsl:for-each>
	</xsl:variable>
		
	<xsl:variable name="refs" select="xalan:nodeset($refs_)"/>
	
	<xsl:template match="/">
	
		<!-- <redirect:write file="{$outpath}/{$docfile_name}.linearized.xml">
			<xsl:copy-of select="$linearized_xml"/>
		</redirect:write>
		<xsl:message>Linearized xml saved.</xsl:message> -->
  
		<xsl:for-each select="$updated_xml">
	
			<xsl:choose>
				<xsl:when test=".//sub-part"> <!-- multiple documents in one xml -->
					<xsl:variable name="xml">
						<xsl:copy-of select="."/>
					</xsl:variable>
					
					<!-- create separate document for each  sub-part -->
					<xsl:variable name="documents">
						<xsl:for-each select="standard/body/sub-part">
						
							<xsl:variable name="number"><xsl:number/></xsl:variable>
							
							<xsl:apply-templates select="xalan:nodeset($xml)" mode="sub-part">
								<xsl:with-param name="doc-number" select="number($number)"/>
							</xsl:apply-templates>
							
						</xsl:for-each>
					</xsl:variable>
					
					<!-- process each document separately -->
					<xsl:for-each select="xalan:nodeset($documents)/*"> 
						<xsl:apply-templates select="."/>
					</xsl:for-each>
					
					<!-- create document.yml file -->
					<redirect:write file="{$outpath}/{$docfile_name}.yml">
						<xsl:call-template name="insertCollectionData">
							<xsl:with-param name="documents" select="$documents"/>
						</xsl:call-template>
					</redirect:write>
					
					<redirect:open file="{$taskCopyImagesFilename}"/>
					<xsl:call-template name="insertTaskImageList"/>
					
					<xsl:for-each select="xalan:nodeset($documents)/*">
						<xsl:if test="$organization = 'PAS'">
							<redirect:write file="{$taskCopyImagesFilename}">
								<xsl:text>copyimage::</xsl:text><xsl:call-template name="getCoverPageImage"/><xsl:text>&#xa;</xsl:text>
							</redirect:write>
						</xsl:if>
					</xsl:for-each>
					<redirect:close file="{$taskCopyImagesFilename}"/>
					
				</xsl:when>
				<xsl:otherwise><!-- no sub-part elements -->
					<xsl:apply-templates />
					<xsl:call-template name="insertTaskImageList"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="adoption">
		<xsl:variable name="docfile"><xsl:call-template name="getDocFilename"/></xsl:variable>
		<redirect:open file="{$outpath}/{$docfile}"/>
		<xsl:apply-templates />
		<redirect:close file="{$outpath}/{$docfile}"/>
	</xsl:template>
	
	<xsl:template match="standard">
		<xsl:variable name="docfile"><xsl:call-template name="getDocFilename"/></xsl:variable>
		<redirect:open file="{$outpath}/{$docfile}"/>
		<xsl:apply-templates />
		<redirect:close file="{$outpath}/{$docfile}"/>
	</xsl:template>
	
	
	<!-- <xsl:template match="adoption/text() | adoption-front/text()"/> -->
	
	<!-- <xsl:template match="/*"> -->
	<xsl:template match="//standard/front | //adoption/adoption-front">
	
		<xsl:variable name="docfile"><xsl:call-template name="getDocFilename"/></xsl:variable>
	
		<xsl:choose>
			<xsl:when test="$demomode = 'false'">
				<redirect:write file="{$outpath}/{$docfile}">
					<!-- index=<xsl:copy-of select="$index"/> -->
					<!-- nat-meta -> iso-meta -> reg-meta -> std-meta -->
					<xsl:for-each select="nat-meta">
						<xsl:call-template name="xxx-meta">
							<xsl:with-param name="include_iso_meta">true</xsl:with-param>
							<xsl:with-param name="include_reg_meta">true</xsl:with-param>
							<xsl:with-param name="include_std_meta">true</xsl:with-param>
						</xsl:call-template>
					</xsl:for-each>
					
					<xsl:if test="not(nat-meta)">
						<xsl:for-each select="iso-meta">
							<xsl:call-template name="xxx-meta">
								<xsl:with-param name="include_reg_meta">true</xsl:with-param>
								<xsl:with-param name="include_std_meta">true</xsl:with-param>
							</xsl:call-template>
						</xsl:for-each>
					
						<xsl:if test="not(iso-meta)">
							<xsl:for-each select="reg-meta">
								<xsl:call-template name="xxx-meta">
									<xsl:with-param name="include_std_meta">true</xsl:with-param>
								</xsl:call-template>
							</xsl:for-each>
							
							<xsl:if test="not(reg-meta)">
								<xsl:for-each select="std-meta">
									<xsl:call-template name="xxx-meta"/>
								</xsl:for-each>
							</xsl:if>
						</xsl:if>
					</xsl:if>
					
					<xsl:call-template name="insertCommonAttributes"/>
					
				</redirect:write>
			</xsl:when>
			<xsl:otherwise> <!-- demo mode -->
				
				<xsl:for-each select="*[contains(local-name(), '-meta')]">
					<xsl:variable name="docfile_bib">
						<xsl:choose>
							<xsl:when test="$one_document = 'true'"><xsl:value-of select="$docfile"/></xsl:when>
							<xsl:otherwise>
								<xsl:call-template name="getMetaBibFilename"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
				
					<redirect:write file="{$outpath}/{$docfile_bib}">
						<!-- <xsl:text>DEBUG name=</xsl:text><xsl:value-of select="local-name()"/><xsl:text>&#xa;</xsl:text> -->
						<xsl:call-template name="xxx-meta" />
						
						
						<xsl:if test="$one_document = 'true'">
							<xsl:call-template name="insertCommonAttributes"/>
						</xsl:if>
						
						<xsl:if test="$one_document = 'false'">
							
							<!-- ========================= -->
							<!-- nat-meta processing -->
							<!-- ========================= -->
							<xsl:if test="local-name() = 'nat-meta'">
								
								<xsl:if test="not(../reg-meta) and not(../iso-meta)">
									<xsl:call-template name="insertCommonAttributes"/>
								</xsl:if>
								
								<xsl:text>&#xa;&#xa;</xsl:text>
								
								<xsl:apply-templates select="ancestor::front/sec[contains(@id, '_nat') or title = 'National foreword']"/>
								
								<xsl:variable name="embed_file_">
									<xsl:choose>
										<xsl:when test="../reg-meta">
											<xsl:for-each select="../reg-meta"> <!-- set context to reg-meta -->
												<xsl:call-template name="getMetaBibFilename"/>
											</xsl:for-each>
										</xsl:when>
										<xsl:when test="../iso-meta">
											<xsl:for-each select="../iso-meta"> <!-- set context to iso-meta -->
												<xsl:call-template name="getMetaBibFilename"/>
											</xsl:for-each>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								
								<xsl:call-template name="insertEmbedFile">
									<xsl:with-param name="embed_file"  select="normalize-space($embed_file_)"/>
								</xsl:call-template>
								
							</xsl:if>
							<!-- ========================= -->
							<!-- END nat-meta processing -->
							<!-- ========================= -->
							
							<!-- ========================= -->
							<!-- reg-meta processing --> <!-- European -->
							<!-- ========================= -->
							<xsl:if test="local-name() = 'reg-meta'">
								
								<xsl:if test="not(../iso-meta)">
									<xsl:call-template name="insertCommonAttributes"/>
								</xsl:if>
								
								<xsl:text>&#xa;&#xa;</xsl:text>
								
								<xsl:apply-templates select="ancestor::front/sec[contains(@id, '_euro') or title = 'European foreword']"/>
								
								<xsl:variable name="embed_file_">
									<xsl:choose>
										<xsl:when test="../iso-meta">
											<xsl:for-each select="../iso-meta"> <!-- set context to iso-meta -->
												<xsl:call-template name="getMetaBibFilename"/>
											</xsl:for-each>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								
								<xsl:for-each select="ancestor::standard//app[starts-with(@id, 'sec_Z')]">
									<xsl:variable name="annex_label_" select="translate(label, ' &#xa0;', '--')" />
									<xsl:variable name="annex_label" select="java:toLowerCase(java:java.lang.String.new($annex_label_))" />
									<xsl:variable name="sectionsFolder"><xsl:call-template name="getSectionsFolder"/></xsl:variable>
									
									<xsl:text>include::</xsl:text><xsl:value-of select="$sectionsFolder"/><xsl:text>/</xsl:text><xsl:value-of select="$annex_label"/><xsl:text>.adoc[]</xsl:text>
									<xsl:text>&#xa;&#xa;</xsl:text>

								</xsl:for-each>
								
								<xsl:call-template name="insertEmbedFile">
									<xsl:with-param name="embed_file"  select="normalize-space($embed_file_)"/>
								</xsl:call-template>
								
							</xsl:if>
							<!-- ========================= -->
							<!-- END reg-meta processing -->
							<!-- ========================= -->
							
							<!-- ========================= -->
							<!-- iso-meta processing -->
							<!-- ========================= -->
							<xsl:if test="local-name() = 'iso-meta'">
								
								<xsl:call-template name="insertCommonAttributes"/>
								
								<xsl:text>&#xa;&#xa;</xsl:text>
								
								<xsl:apply-templates select="ancestor::front/sec[not(contains(@id, '_nat') or title = 'National foreword' or contains(@id, '_euro') or title = 'European foreword')]"/>
								
								<xsl:text>&#xa;&#xa;</xsl:text>
								
							</xsl:if>
							
							<!-- ========================= -->
							<!-- END iso-meta processing -->
							<!-- ========================= -->

						</xsl:if>
												
					</redirect:write>
					
				</xsl:for-each>
					
			</xsl:otherwise>
		</xsl:choose>
	
		
		

		<xsl:if test="$split-bibdata != 'true'">
			
			<!-- if in front there are another elements, except xxx-meta -->
			<xsl:for-each select="*[local-name() != 'iso-meta' and local-name() != 'nat-meta' and local-name() != 'reg-meta' and local-name() != 'std-meta']">
				<xsl:variable name="number_"><xsl:number /></xsl:variable>
				<xsl:variable name="number" select="format-number($number_, '00')"/>
				<xsl:variable name="section_name">
					<xsl:value-of select="@sec-type"/>
					<xsl:if test="not(@sec-type)"><xsl:value-of select="@id"/></xsl:if>
				</xsl:variable>
				<xsl:variable name="sectionsFolder"><xsl:call-template name="getSectionsFolder"/></xsl:variable>
				<xsl:variable name="filename">
					<xsl:value-of select="$sectionsFolder"/><xsl:text>/00-</xsl:text><xsl:value-of select="$number"/>-<xsl:value-of select="$section_name"/><xsl:text>.</xsl:text><xsl:value-of select="$docfile_ext"/>
				</xsl:variable>
				
				<xsl:choose>
					<xsl:when test="$demomode = 'true' and $one_document = 'false' and ((contains(@id, '_nat') or title = 'National foreword'))"/> <!-- skip National Foreword and another National clause-->
					<xsl:when test="$demomode = 'true' and $one_document = 'false' and ((contains(@id, '_euro') or title = 'European foreword'))"/> <!-- skip European Foreword and another European clauses -->
					<xsl:when test="$demomode = 'true' and $one_document = 'false' and (not(contains(@id, '_nat') or title = 'National foreword' or contains(@id, '_euro') or title = 'European foreword'))"/> <!-- skip Foreword and another clauses -->
					<xsl:otherwise>
						<redirect:write file="{$outpath}/{$filename}">
							<xsl:text>&#xa;</xsl:text>
							<xsl:if test="title = 'National foreword' or title = 'European foreword'">
								<xsl:text>[.preface]</xsl:text>
								<xsl:text>&#xa;</xsl:text>
							</xsl:if>
							<xsl:apply-templates select="."/>
						</redirect:write>
						<redirect:write file="{$outpath}/{$docfile}">
							<xsl:text>include::</xsl:text><xsl:value-of select="$filename"/><xsl:text>[]</xsl:text>
							<xsl:text>&#xa;&#xa;</xsl:text>
						</redirect:write>
					</xsl:otherwise>
				</xsl:choose>
				
			</xsl:for-each>
			
			<!-- <xsl:apply-templates select="/standard/body"/>			
			<xsl:apply-templates select="/standard/back"/> -->
		</xsl:if>
		
	</xsl:template>
	
	<xsl:template name="insertCommonAttributes">
		<xsl:text>:mn-document-class: </xsl:text><xsl:value-of select="$sdo"/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>:mn-output-extensions: xml,html</xsl:text> <!-- ,doc,html_alt -->
		<xsl:text>&#xa;</xsl:text>
		
		<xsl:text>:local-cache-only:</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>:data-uri-image:</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		
		<xsl:text>:imagesdir: </xsl:text><xsl:value-of select="$imagesdir"/>
		<xsl:text>&#xa;</xsl:text>
		
		<!-- The :docfile: attribute is no longer used -->
		<!-- <xsl:if test="normalize-space($docfile) != ''">
			<xsl:text>:docfile: </xsl:text><xsl:value-of select="$docfile"/>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if> -->
		
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template name="getMetaBibFilename">
		<xsl:variable name="name1" select="java:replaceAll(java:java.lang.String.new(std-ref[@type = 'undated']), '(\s|\h)', '-')"/>
		<xsl:value-of select="java:toLowerCase(java:java.lang.String.new($name1))"/><xsl:text>.</xsl:text><xsl:value-of select="$docfile_ext"/>
	</xsl:template>
	
	<xsl:template name="insertEmbedFile">
		<xsl:param name="embed_file"/>
		<xsl:if test="$embed_file != ''">
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>embed::</xsl:text><xsl:value-of select="$embed_file"/><xsl:text>[]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="xxx-meta">
		<xsl:param name="include_iso_meta">false</xsl:param>
		<xsl:param name="include_reg_meta">false</xsl:param>
		<xsl:param name="include_std_meta">false</xsl:param>
		<xsl:param name="originator"/>
		
		<!-- = ISO 8601-1 -->
		<xsl:apply-templates select="std-ident"/> <!-- * -> iso-meta -->
		<!-- :docnumber: 8601 -->
		<xsl:apply-templates select="std-ident/doc-number"/>		
		<!-- :partnumber: 1 -->
		<xsl:apply-templates select="std-ident/part-number"/>		
		<!-- :edition: 1 -->
		<xsl:apply-templates select="std-ident/edition"/>		
		<!-- :copyright-year: 2019 -->
		<xsl:apply-templates select="permissions/copyright-year"/>
		
		
		<!-- :published-date: -->
		<xsl:apply-templates select="pub-date"/>
		
		<!-- :date: release 2020-01-01 -->
		<xsl:apply-templates select="release-date"/>
		
		
		<!-- :language: en -->
		<xsl:apply-templates select="doc-ident/language"/>
		<!-- :title-intro-en: Date and time
		:title-main-en: Representations for information interchange
		:title-part-en: Basic rules
		:title-intro-fr: Date et l'heure
		:title-main-fr: Représentations pour l'échange d'information
		:title-part-fr: Règles de base -->
		<xsl:apply-templates select="title-wrap"/>		
		<!-- :doctype: international-standard -->
		<xsl:variable name="doctype">
			<xsl:apply-templates select="std-ident/doc-type"/>		
		</xsl:variable>
		<xsl:text>:doctype: </xsl:text><xsl:value-of select="$doctype"/>
		<xsl:text>&#xa;</xsl:text>
		
		<!-- :docstage: 60
		:docsubstage: 60 -->		
		<xsl:apply-templates select="doc-ident/release-version"/>
		
		<xsl:if test="ics">
			<xsl:text>:library-ics: </xsl:text>
			<xsl:for-each select="ics">
				<xsl:value-of select="."/><xsl:if test="position() != last()">,</xsl:if>
			</xsl:for-each>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		
		<xsl:apply-templates select="custom-meta-group/custom-meta[meta-name = 'ISBN']/meta-value"/>
		
		<xsl:choose>
			<xsl:when test="$organization = 'BSI' or $organization = 'PAS'">
				<xsl:variable name="data">
					<xsl:for-each select="comm-ref[normalize-space() != '']">
						<item>Committee reference <xsl:value-of select="."/></item> <!-- Example: Committee reference DEF/1 -->
					</xsl:for-each>
					<xsl:if test="std-xref[@type='isPublishedFormatOf']">
						<item>
							<xsl:text>Draft for comment </xsl:text>
							<xsl:for-each select="std-xref[@type='isPublishedFormatOf']">
								<xsl:value-of select="std-ref"/><!-- Example: Draft for comment 20/30387670 DC -->
								<xsl:if test="position() != last()">,</xsl:if>
							</xsl:for-each>
					</item>
					</xsl:if>
				</xsl:variable>
				<!-- Example: :bsi-related: Committee reference DEF/1; Draft for comment 20/30387670 DC -->
				<xsl:if test="xalan:nodeset($data)//item">
					<xsl:text>:bsi-related: </xsl:text>
					<xsl:for-each select="xalan:nodeset($data)//item">
						<xsl:value-of select="."/>
						<xsl:if test="position() != last()">; </xsl:if>
					</xsl:for-each>
					<xsl:text>&#xa;</xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
					<!-- 
					:technical-committee-type: TC
					:technical-committee-number: 154
					:technical-committee: Processes, data elements and documents in commerce, industry and administration
					:workgroup-type: WG
					:workgroup-number: 5
					:workgroup: Representation of dates and times -->		
					<xsl:apply-templates select="comm-ref"/>
			</xsl:otherwise>
		</xsl:choose>
		
		<!-- :secretariat: SAC -->
		<xsl:apply-templates select="secretariat"/>
		
		<!-- relation bibitem -->
		<xsl:if test="$include_iso_meta = 'true'">
			<xsl:for-each select="ancestor::front/iso-meta">
				<!-- https://github.com/metanorma/sts2mn/issues/31 -->
				<!-- <xsl:call-template name="xxx-meta"/> --> <!-- process iso-meta -->
				<xsl:apply-templates select="std-ident" mode="adopted-from"/>
			</xsl:for-each>
		</xsl:if>
		
		<xsl:if test="$include_reg_meta = 'true'">
			<xsl:for-each select="ancestor::front/reg-meta">
				<!-- https://github.com/metanorma/sts2mn/issues/31 -->
				<!-- <xsl:call-template name="xxx-meta"> --> <!-- process reg-meta -->
				<xsl:apply-templates select="std-ident" mode="adopted-from"/>
			</xsl:for-each>
		</xsl:if>
		
		<xsl:if test="$include_std_meta = 'true'">
			<xsl:for-each select="ancestor::front/std-meta">
				<!-- https://github.com/metanorma/sts2mn/issues/31 -->
				<!-- <xsl:call-template name="xxx-meta"> --> <!-- process reg-meta -->
				<xsl:apply-templates select="std-ident" mode="adopted-from"/>
			</xsl:for-each>
		</xsl:if>
		
		<xsl:if test="$doctype = 'publicly-available-specification'"> <!-- PAS -->
			<xsl:text>:coverpage-image: </xsl:text>
			<xsl:value-of select="$imagesdir"/>
			<xsl:text>/</xsl:text>
			<xsl:call-template name="getCoverPageImage"/>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>

	</xsl:template>
	
	<xsl:template name="getCoverPageImage">
		<xsl:variable name="doc-number" select="ancestor-or-self::standard/@doc-number" />
		<xsl:text>coverpage</xsl:text>
		<xsl:if test="$doc-number != ''">.<xsl:value-of select="$doc-number"/></xsl:if>
		<xsl:text>.png</xsl:text>
	</xsl:template>
	
	<xsl:template match="//standard/body">
		<xsl:if test="$split-bibdata != 'true'">
			<!-- <xsl:apply-templates select="../back/fn-group" mode="footnotes"/> -->
			<xsl:apply-templates />
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="//standard/back">
		<xsl:if test="$split-bibdata != 'true'">		
			<xsl:apply-templates select="*[not(local-name() = 'ref-list' and @content-type = 'bibl')]" />
			<xsl:apply-templates select="ref-list[@content-type = 'bibl']" />
		</xsl:if>
	</xsl:template>
	
	
	<xsl:template match="std-ident[ancestor::front or ancestor::adoption-front]">
		<xsl:text>= </xsl:text>
		<xsl:value-of select="originator"/>
		<xsl:text> </xsl:text>
		<xsl:variable name="docnumber">
			<xsl:call-template name="getDocNumber">
				<xsl:with-param name="value" select="doc-number"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:value-of select="$docnumber"/>
		
		<xsl:if test="part-number != '' and not(contains($docnumber, concat('-', part-number)))">
			<xsl:text>-</xsl:text>
			<xsl:value-of select="part-number"/>
		</xsl:if>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="std-ident[ancestor::front or ancestor::adoption-front]/doc-number[normalize-space(.) != '']">
		<xsl:text>:docnumber: </xsl:text><xsl:call-template name="getDocNumber"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template name="getDocNumber">
		<xsl:param name="value" select="."/>
		<xsl:variable name="copyright-year">
			<xsl:call-template name="getCopyrightYear">
				<xsl:with-param name="value" select="ancestor::*[self::front or self::adoption-front]//permissions/copyright-year"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="regex_copyright-year" select="concat('(:', $copyright-year, ')?')"/>
		<xsl:variable name="part" select="../part-number"/>
		<xsl:variable name="regex_part" select="concat('(-', $part, ')?')"/>
		
		<!-- remove part and copyright-year from end of docnumber -->
		<!-- <xsl:value-of select="java:replaceAll(java:java.lang.String.new($value), concat(':', $copyright-year, '$'), '')"/>  -->
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new($value), concat($regex_part, $regex_copyright-year, '$'), '')"/> 
	</xsl:template>
	
	
	<xsl:template match="std-ident[ancestor::front or ancestor::adoption-front]/part-number[normalize-space(.) != '']">		
		<xsl:text>:partnumber: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>		
	</xsl:template>
	
	<!-- in some documents part-number is empty, but there is 'Part N' in title-wrap/compl -->
	<xsl:template match="std-ident[ancestor::front or ancestor::adoption-front]/part-number[normalize-space(.) = '']">
		<xsl:variable name="complTitle" select="ancestor::*[contains(local-name(), '-meta')]/title-wrap/compl"/>
		<xsl:variable name="partNumberFromComplTitle" select="normalize-space(java:replaceAll(java:java.lang.String.new($complTitle),'^Part(\s|\h)+(\d*).*','$2'))"/>
		<xsl:if test="$partNumberFromComplTitle != '' and translate($partNumberFromComplTitle, '0123456789', '') = ''">
			<xsl:text>:partnumber: </xsl:text><xsl:value-of select="$partNumberFromComplTitle"/>
			<xsl:text>&#xa;</xsl:text>		
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="std-ident[ancestor::front or ancestor::adoption-front]/edition[normalize-space(.) != '']">
		<xsl:text>:edition: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="std-ident" mode="adopted-from">
		<xsl:text>:adopted-from: </xsl:text>
		<xsl:value-of select="originator"/>
		<xsl:text> </xsl:text>
		<xsl:value-of select="doc-number"/>
		<xsl:if test="part-number != ''">
			<xsl:text>-</xsl:text>
			<xsl:value-of select="part-number"/>
		</xsl:if>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="permissions[ancestor::front or ancestor::adoption-front]/copyright-year[normalize-space(.) != '']">
		<xsl:text>:copyright-year: </xsl:text><xsl:call-template name="getCopyrightYear"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template name="getCopyrightYear">
		<xsl:param name="value" select="."/>
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new($value), '^©(\s|\h)*', '')"/> <!-- remove copyright sign -->
	</xsl:template>
	
	<xsl:template match="pub-date[ancestor::front or ancestor::adoption-front]">
		<xsl:if test="normalize-space() != ''">
			<xsl:text>:published-date: </xsl:text><xsl:value-of select="."/>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="release-date[ancestor::front or ancestor::adoption-front]">
		<xsl:if test="normalize-space() != ''">
			<xsl:text>:date: release </xsl:text><xsl:value-of select="."/>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="doc-ident[ancestor::front or ancestor::adoption-front]/language[normalize-space(.) != '']">
		<xsl:text>:language: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="title-wrap[ancestor::front or ancestor::adoption-front]/text()"/>
	<xsl:template match="title-wrap[ancestor::front or ancestor::adoption-front]">	
		<xsl:choose>
			<xsl:when test="$organization = 'BSI' or $organization = 'PAS'">
				
				<!-- priority: get intro and compl from separate field -->
				<xsl:variable name="titles">
					<xsl:apply-templates select="intro[normalize-space() != '']" mode="bibdata"/>
					<xsl:apply-templates select="compl[normalize-space() != '']" mode="bibdata"/>
					<xsl:apply-templates select="main[normalize-space() != '']" mode="bibdata"/>
					<xsl:if test="normalize-space(main) = ''">
						<xsl:apply-templates select="full[normalize-space() != '']" mode="bibdata_title_full"/>
					</xsl:if>
				</xsl:variable>

				<xsl:variable name="title_components">
					<xsl:copy-of select="xalan:nodeset($titles)/*[@type='title-intro'][1]"/>
					<xsl:copy-of select="xalan:nodeset($titles)/*[@type='title-main'][1]"/>
					<xsl:copy-of select="xalan:nodeset($titles)/*[@type='title-part'][1]"/>
				</xsl:variable>
				
				<xsl:variable name="lang" select="@xml:lang"/>
				<xsl:for-each select="xalan:nodeset($title_components)/*">
					<xsl:text>:</xsl:text><xsl:value-of select="@type"/><xsl:text>-</xsl:text><xsl:value-of select="$lang"/><xsl:text>: </xsl:text><xsl:value-of select="."/>
					<xsl:text>&#xa;</xsl:text>
				</xsl:for-each>
				
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates>
					<xsl:with-param name="lang" select="@xml:lang"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template match="title-wrap/full | title-wrap/main" mode="bibdata_title_full">
	
		<!-- <xsl:variable name="title" select="translate(., '-–', '——')"/> -->
		<!-- replace dash, en dash to em dash -->
		<xsl:variable name="title" select="java:replaceAll(java:java.lang.String.new(.), '( - |–)', '—')"/>
		
		<xsl:variable name="parts_">
			<xsl:call-template name="split">
				<xsl:with-param name="pText" select="$title"/>
				<xsl:with-param name="sep" select="'—'"/>
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:variable name="parts" select="xalan:nodeset($parts_)"/>
		
		<xsl:variable name="lang" select="../@xml:lang"/>
		
		<xsl:if test="count($parts/*) &gt; 0">
			<title language="{$lang}" format="text/plain" type="title-main">
				<xsl:for-each select="$parts/*">
					<xsl:apply-templates mode="bibdata"/>
					<xsl:if test="position() != last()"> — </xsl:if>
				</xsl:for-each>
			</title>
		</xsl:if>
		
	</xsl:template>
	
	<xsl:template match="title-wrap/intro" mode="bibdata">
		<title language="{../@xml:lang}" format="text/plain" type="title-intro">
			<xsl:apply-templates mode="bibdata"/>
		</title>
	</xsl:template>
	
	<xsl:template match="title-wrap/main" mode="bibdata">
		<title language="{../@xml:lang}" format="text/plain" type="title-main">
			<xsl:apply-templates mode="bibdata"/>
		</title>
	</xsl:template>
	
	<xsl:template match="title-wrap/compl" mode="bibdata">
		<title language="{../@xml:lang}" format="text/plain" type="title-part">
			<xsl:apply-templates mode="bibdata"/>
		</title>
	</xsl:template>
	
	<xsl:template match="title-wrap/compl/node()[1][self::text()]" mode="bibdata">
		<!-- strip 'Part N:' -->
		<xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new(.), '^Part(\s|\h)*(\d)+:(.+)$', '$3'))"/>
	</xsl:template>
	
	<xsl:template match="title-wrap[ancestor::front or ancestor::adoption-front]/intro[normalize-space(.) != '']">
		<xsl:param name="lang"/>
		<xsl:text>:title-intro-</xsl:text><xsl:value-of select="$lang"/><xsl:text>: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	<xsl:template match="title-wrap[ancestor::front or ancestor::adoption-front]/main[normalize-space(.) != '']">
		<xsl:param name="lang"/>
		
		<xsl:variable name="title_items">
			<xsl:call-template name="split">
				<xsl:with-param name="pText" select="."/>
				<xsl:with-param name="sep" select="'—'"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="count(xalan:nodeset($title_items)//item) &gt; 1">
				<xsl:for-each select="xalan:nodeset($title_items)//item">
					<xsl:choose>
						<xsl:when test="position() = 1">
							<xsl:text>:title-intro-</xsl:text><xsl:value-of select="$lang"/><xsl:text>: </xsl:text><xsl:value-of select="normalize-space(translate(., '&#xA0;', ' '))"/>
						</xsl:when>
						<xsl:when test="position() = 2">
							<xsl:text>:title-main-</xsl:text><xsl:value-of select="$lang"/><xsl:text>: </xsl:text><xsl:value-of select="normalize-space(translate(., '&#xA0;', ' '))"/>
						</xsl:when>
						<xsl:when test="position() = 3">
							<xsl:text>:title-part-</xsl:text><xsl:value-of select="$lang"/><xsl:text>: </xsl:text><xsl:value-of select="normalize-space(translate(., '&#xA0;', ' '))"/>
						</xsl:when>
					</xsl:choose>
					<xsl:text>&#xa;</xsl:text>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>:title-main-</xsl:text><xsl:value-of select="$lang"/><xsl:text>: </xsl:text><xsl:value-of select="."/>
				<xsl:text>&#xa;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>	
	</xsl:template>
	
	<xsl:template match="title-wrap[ancestor::front or ancestor::adoption-front]/compl[normalize-space(.) != '']">
		<xsl:param name="lang"/>
		<xsl:text>:title-part-</xsl:text><xsl:value-of select="$lang"/><xsl:text>: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	
	
	<xsl:template match="title-wrap[ancestor::front or ancestor::adoption-front]/full[normalize-space(.) != '']">
		<xsl:text></xsl:text>
	</xsl:template>
	
	
	<xsl:template match="std-ident[ancestor::front or ancestor::adoption-front]/doc-type[normalize-space(.) != '']">
		<xsl:variable name="value" select="java:toLowerCase(java:java.lang.String.new(.))"/>
		<!-- https://www.niso-sts.org/TagLibrary/niso-sts-TL-1-0-html/element/doc-type.html -->
		<xsl:choose>
			<xsl:when test="$organization = 'BSI' or $organization = 'PAS'">
				<xsl:variable name="originator" select=" normalize-space(ancestor::std-ident/originator)"/>
				<xsl:choose>
					<xsl:when test="starts-with($originator, 'BS') and $value = 'standard'">standard</xsl:when>
					<xsl:when test="starts-with($originator, 'PAS') and ($value = 'publicly available specification' or $value = 'standard')">publicly-available-specification</xsl:when>
					<xsl:when test="starts-with($originator, 'PD') and $value = 'published document'">published-document</xsl:when>
					<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$value = 'is'">international-standard</xsl:when>
			<xsl:when test="$value = 'r'">recommendation</xsl:when>
			<xsl:when test="$value = 'spec'">spec</xsl:when>
			 <xsl:otherwise>
				<xsl:value-of select="$value"/>
			 </xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="doc-ident[ancestor::front or ancestor::adoption-front]/release-version[normalize-space(.) != '']">
		<!-- https://www.niso-sts.org/TagLibrary/niso-sts-TL-1-0-html/element/release-version.html -->
		<!-- Possible values: WD, CD, DIS, FDIS, IS -->
		<xsl:variable name="value" select="java:toUpperCase(java:java.lang.String.new(.))"/>
		<xsl:variable name="doctype" select="java:toLowerCase(java:java.lang.String.new(../../std-ident/doc-type))"/>
		<xsl:choose>
			<xsl:when test="$value = 'WD'">
				<xsl:text>:docstage: 20</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>:docsubstage: 00</xsl:text>
			</xsl:when>
			<xsl:when test="$value = 'CD'">
				<xsl:text>:docstage: 30</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>:docsubstage: 00</xsl:text>
			</xsl:when>
			<xsl:when test="$value = 'DIS'">
				<xsl:text>:docstage: 40</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>:docsubstage: 00</xsl:text>
			</xsl:when>
			<xsl:when test="$value = 'FDIS'">
				<xsl:text>:docstage: 50</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>:docsubstage: 00</xsl:text>
			</xsl:when>
			<xsl:when test="$value = 'IS'">
				<xsl:text>:docstage: 60</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>:docsubstage: 60</xsl:text>
			</xsl:when>
			<xsl:when test="$doctype = 'standard'">
				<xsl:text>:docstage: 60</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>:docsubstage: 60</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>:docstage: </xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>:docsubstage: </xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="comm-ref[ancestor::front or ancestor::adoption-front]">
		<xsl:choose>
			<xsl:when test="contains('TC ', .) or contains('SC ', .) or contains('WG ', .)">
				<xsl:variable name="comm-ref">
					<xsl:call-template name="split">
						<xsl:with-param name="pText" select="."/>
					</xsl:call-template>
				</xsl:variable>			
				<xsl:value-of select="count(xalan:nodeset($comm-ref)/*)"/>
				<xsl:for-each select="xalan:nodeset($comm-ref)/*">				
					<xsl:choose>
						<xsl:when test="starts-with(., 'TC ')">
							<xsl:text>:technical-committee-type: TC</xsl:text>
							<xsl:text>&#xa;</xsl:text>
							<xsl:text>:technical-committee-number: </xsl:text>					
							<xsl:value-of select="normalize-space(substring-after(., ' '))"/>
							<xsl:text>&#xa;</xsl:text>
							<!-- <xsl:text>:technical-committee: </xsl:text>
							<xsl:text>&#xa;</xsl:text> -->
						</xsl:when>
						<xsl:when test="starts-with(., 'SC ')">
							<xsl:text>:subcommittee-type: SC</xsl:text>
							<xsl:text>&#xa;</xsl:text>
							<xsl:text>:subcommittee-number: </xsl:text>
							<xsl:value-of select="normalize-space(substring-after(., ' '))"/>
							<xsl:text>&#xa;</xsl:text>
							<!-- <xsl:text>:subcommittee: </xsl:text>				
							<xsl:text>&#xa;</xsl:text> -->
						</xsl:when>
						<xsl:when test="starts-with(., 'WG ')">					
							<xsl:text>:workgroup-type: WG</xsl:text>
							<xsl:text>&#xa;</xsl:text>
							<xsl:text>:workgroup-number: </xsl:text>
							<xsl:value-of select="normalize-space(substring-after(., ' '))"/>
							<xsl:text>&#xa;</xsl:text>
							<!-- <xsl:text>:workgroup: </xsl:text>
							<xsl:text>&#xa;</xsl:text> -->
						</xsl:when>
					</xsl:choose>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>:technical-committee-code: </xsl:text><xsl:value-of select="."/>
				<xsl:text>&#xa;</xsl:text>
				<xsl:variable name="tc_name">
					<xsl:choose>
						<xsl:when test="starts-with(., 'DEF/')">Defence standardization</xsl:when>
						<xsl:otherwise></xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:if test="normalize-space($tc_name) != ''">
					<xsl:text>:technical-committee-name: </xsl:text><xsl:value-of select="$tc_name"/>
					<xsl:text>&#xa;</xsl:text>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	<xsl:template match="secretariat[ancestor::front or ancestor::adoption-front][normalize-space(.) != '']">
		<xsl:text>:secretariat: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="custom-meta-group/custom-meta[meta-name = 'ISBN']/meta-value">
		<xsl:text>:isbn: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<!-- =========== -->
	<!-- end bibdata (standard/front) -->
	<!-- =========== -->
	
	<xsl:template match="front/notes" priority="2">
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>[.preface,type="front_notes"]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>== {blank}</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="front/sec[@sec-type = 'publication_info']" priority="2">
		<!-- process only Amendments/corrigenda table, because other data implemented in metanorma gem -->
		<xsl:if test="*[@content-type = 'ace-table']">
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>[.preface,type=corrigenda]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>== </xsl:text><xsl:apply-templates select="*[@content-type = 'ace-table']/caption/title[1]" mode="corrigenda_title"/>
			<xsl:text>&#xa;</xsl:text>
			<xsl:apply-templates select="*[@content-type = 'ace-table']"/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="front/sec[@sec-type = 'publication_info']//*[@content-type = 'ace-table']/caption/title[1]" priority="2"/>
	<xsl:template match="*[@content-type = 'ace-table']/caption/title[1]" mode="corrigenda_title">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="front/sec[@sec-type = 'intro']" priority="2"> <!-- don't need to add [[introduction]] in annex, example <sec id="sec_A.1" sec-type="intro">  -->
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>[[introduction]]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="body/sec[@sec-type = 'intro']" priority="2">
		<xsl:variable name="sectionsFolder"><xsl:call-template name="getSectionsFolder"/></xsl:variable>
		<redirect:write file="{$outpath}/{$sectionsFolder}/00-introduction.adoc">
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>[[introduction]]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:apply-templates />
		</redirect:write>
		<xsl:variable name="docfile"><xsl:call-template name="getDocFilename"/></xsl:variable>
		<xsl:variable name="sectionsFolder"><xsl:call-template name="getSectionsFolder"/></xsl:variable>
		<redirect:write file="{$outpath}/{$docfile}">
			<xsl:text>include::</xsl:text><xsl:value-of select="$sectionsFolder"/><xsl:text>/00-introduction.adoc[]</xsl:text>
			<xsl:text>&#xa;&#xa;</xsl:text>
		</redirect:write>
	</xsl:template>
	
	<xsl:template match="body/sec[@sec-type = 'scope'] | front/sec[@sec-type = 'scope']" priority="2">
		<xsl:variable name="sectionsFolder"><xsl:call-template name="getSectionsFolder"/></xsl:variable>
		<redirect:write file="{$outpath}/{$sectionsFolder}/01-scope.adoc">
			<xsl:text>&#xa;</xsl:text>
			<xsl:call-template name="setId"/>
			<xsl:apply-templates />
		</redirect:write>
		<xsl:variable name="docfile"><xsl:call-template name="getDocFilename"/></xsl:variable>
		<xsl:variable name="sectionsFolder"><xsl:call-template name="getSectionsFolder"/></xsl:variable>
		<redirect:write file="{$outpath}/{$docfile}">
			<xsl:text>include::</xsl:text><xsl:value-of select="$sectionsFolder"/><xsl:text>/01-scope.adoc[]</xsl:text>
			<xsl:text>&#xa;&#xa;</xsl:text>
		</redirect:write>
	</xsl:template>
	
	<!-- ======================== -->
	<!-- Normative references -->
	<!-- ======================== -->
	<xsl:template match="body/sec[@sec-type = 'norm-refs'] | front/sec[@sec-type = 'norm-refs']" priority="2">
		<xsl:variable name="sectionsFolder"><xsl:call-template name="getSectionsFolder"/></xsl:variable>
		<redirect:write file="{$outpath}/{$sectionsFolder}/02-normrefs.adoc">
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>[bibliography]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:call-template name="setId"/>
			<xsl:apply-templates />
		</redirect:write>
		<xsl:variable name="docfile"><xsl:call-template name="getDocFilename"/></xsl:variable>
		<redirect:write file="{$outpath}/{$docfile}">
			<xsl:text>include::</xsl:text><xsl:value-of select="$sectionsFolder"/><xsl:text>/02-normrefs.adoc[]</xsl:text>
			<xsl:text>&#xa;&#xa;</xsl:text>
		</redirect:write>
	</xsl:template>
	
	<!-- Text before references -->
	<xsl:template match="sec[@sec-type = 'norm-refs']/p" priority="2">
		<xsl:if test="not(preceding-sibling::*[1][self::p])"> <!-- first p in norm-refs -->
			<xsl:text>[NOTE,type=boilerplate]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>--</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		<xsl:call-template name="p"/>
		<xsl:if test="not(following-sibling::*[1][self::p])"> <!-- last p in norm-refs -->
			<xsl:call-template name="addIndexTerms"/>
			<xsl:text>--</xsl:text>
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	<!-- ======================== -->
	<!-- END Normative references -->
	<!-- ======================== -->
	
	<!-- ======================== -->
	<!-- Terms and definitions -->
	<!-- ======================== -->
	<!-- first element in Terms and definitions section -->
	<xsl:template match="sec[@sec-type = 'terms']/title | sec[@sec-type = 'terms']//sec/title" priority="2">
	
		<xsl:call-template name="title"/>
	
		<xsl:if test="ancestor::sec[java:toLowerCase(java:java.lang.String.new(title)) = 'terms and definitions']">
			<xsl:text>[.boilerplate]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:variable name="level">
				<xsl:call-template name="getLevel">
					<xsl:with-param name="addon">1</xsl:with-param>
				</xsl:call-template>
			</xsl:variable>
			<xsl:value-of select="$level"/>
			<xsl:choose>
				<!-- if there isn't paragraph after title -->
				<!-- https://www.metanorma.org/author/topics/document-format/section-terms/#overriding-predefined-text -->
				<xsl:when test="following-sibling::*[1][self::term-sec] or following-sibling::*[1][self::sec]">
					<xsl:text> {blank}</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text> My predefined text</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	<!-- ======================== -->
	<!-- END Terms and definitions -->
	<!-- ======================== -->
	
	
	<xsl:template match="body/sec">
		<xsl:variable name="sec_number_" select="format-number(label, '00')" />
		<xsl:variable name="sec_number">
			<xsl:choose>
				<!-- Example: Section 3 -->
				<xsl:when test="$sec_number_ = 'NaN'">
					<xsl:choose>
						<xsl:when test="label">
							<xsl:value-of select="java:toLowerCase(java:java.lang.String.new(normalize-space(translate(label, ',&#x200b;&#xa0; ','___'))))"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="@id"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise><xsl:value-of select="$sec_number_"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="title" select="normalize-space(translate(title, ',&#x200b;&#xa0;‑','    '))"/> <!-- get first word -->
		<xsl:variable name="sec_title_">
			<xsl:choose>
				<xsl:when test="contains($title, ' ')"><xsl:value-of select="substring-before($title,' ')"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="$title"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="sec_title" select="java:toLowerCase(java:java.lang.String.new($sec_title_))"/>
		<xsl:variable name="sectionsFolder"><xsl:call-template name="getSectionsFolder"/></xsl:variable>
		<redirect:write file="{$outpath}/{$sectionsFolder}/{$sec_number}-{$sec_title}.adoc">
			<xsl:text>&#xa;</xsl:text>
			<xsl:call-template name="setIdOrType"/>
			<xsl:apply-templates />
		</redirect:write>
		<xsl:variable name="docfile"><xsl:call-template name="getDocFilename"/></xsl:variable>
		<redirect:write file="{$outpath}/{$docfile}">
			<xsl:text>include::</xsl:text><xsl:value-of select="$sectionsFolder"/><xsl:text>/</xsl:text><xsl:value-of select="$sec_number"/>-<xsl:value-of select="$sec_title"/><xsl:text>.adoc[]</xsl:text>
			<xsl:text>&#xa;&#xa;</xsl:text>
		</redirect:write>
	</xsl:template>
	
	<xsl:template match="sec">
		<xsl:call-template name="setIdOrType"/>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="sec/text() | list-item/text() | list/text()">
		<xsl:value-of select="normalize-space(.)"/>
	</xsl:template>
	
	<!-- put index terms with 'see', 'see also' -->
	<xsl:template match="sec[@sec-type = 'index'] | back/sec[@id = 'ind']" priority="2">
		<xsl:if test="$index//reference[@type]">
			<xsl:variable name="sectionsFolder"><xsl:call-template name="getSectionsFolder"/></xsl:variable>
			<redirect:write file="{$outpath}/{$sectionsFolder}/index-see-terms.adoc">
				<xsl:for-each select="$index//reference[@type]">
					<xsl:variable name="mainterm">
						<xsl:apply-templates/>
					</xsl:variable>
					<xsl:if test="normalize-space($mainterm) != ''">
						<xsl:variable name="type" select="@type"/>
						
						<!-- split list of terms into separate term -->
						<xsl:variable name="term_parts">
							<xsl:call-template name="split">
								<xsl:with-param name="pText" select="@term"/>
								<xsl:with-param name="sep" select="','"/>
							</xsl:call-template>
						</xsl:variable>
						
						<!-- create index: entry for each term -->
						<xsl:for-each select="xalan:nodeset($term_parts)//item">
							<xsl:text>index:</xsl:text>
							<xsl:value-of select="$type"/> <!-- see or also -->
							<xsl:text>[</xsl:text>
								<xsl:copy-of select="$mainterm"/><xsl:text>,</xsl:text><xsl:value-of select="."/>
							<xsl:text>]&#xa;</xsl:text>
						</xsl:for-each>
					</xsl:if>
				</xsl:for-each>
			</redirect:write>
			<xsl:variable name="docfile"><xsl:call-template name="getDocFilename"/></xsl:variable>
			<redirect:write file="{$outpath}/{$docfile}">
				<xsl:text>include::</xsl:text><xsl:value-of select="$sectionsFolder"/><xsl:text>/index-see-terms.adoc[]</xsl:text>
				<xsl:text>&#xa;&#xa;</xsl:text>
			</redirect:write>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="term-sec">
		<!-- [[ ]] -->
		<!-- <xsl:call-template name="setId"/>
		<xsl:text>&#xa;</xsl:text>		 -->

		<xsl:variable name="level">
			<xsl:call-template name="getLevelFromLabel"/>
		</xsl:variable>
		<!-- <xsl:text>level=</xsl:text><xsl:value-of select="$level"/><xsl:text>&#xa;</xsl:text> -->
		<xsl:variable name="level_next_term">
			<xsl:for-each select="following-sibling::*[1][self::term-sec]">
				<xsl:call-template name="getLevelFromLabel"/>
			</xsl:for-each>
		</xsl:variable>
		<!-- <xsl:text>level_next_term=</xsl:text><xsl:value-of select="$level_next_term"/><xsl:text>&#xa;</xsl:text> -->
		
		<!-- According to systematic order documentation (https://www.metanorma.org/author/iso/topics/markup/#systematic-order), non-terminal subclauses must be preceded by [.term] in order to get proper results. -->
		<xsl:variable name="isThereNestedTerm" select="term-sec or $level_next_term &gt; $level"/>
		<xsl:if test="normalize-space($isThereNestedTerm) = 'true'"> <!-- if there is nested term-sec -->
			<xsl:text>[.term]&#xa;</xsl:text>
		</xsl:if>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="tbx:termEntry">
		<xsl:variable name="level">
			<xsl:call-template name="getLevel"/>
		</xsl:variable>
		<xsl:value-of select="$level"/><xsl:text> </xsl:text>
		<!-- <xsl:call-template name="setId"/> --><!-- [[ ]] -->
		<xsl:apply-templates select=".//tbx:term" mode="term"/>	
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="title" name="title">
		<xsl:choose>
			<xsl:when test="parent::sec/@sec-type = 'foreword'">
				<xsl:text>== </xsl:text>
				<xsl:apply-templates />
				<xsl:call-template name="addIndexTerms"/>
				<xsl:text>&#xa;&#xa;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="calculated_level">
					<xsl:choose>
						<xsl:when test="parent::sec/@sec_depth"><xsl:value-of select="parent::sec/@sec_depth"/></xsl:when>
						<xsl:otherwise>0</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="level">
					<xsl:call-template name="getLevel">
						<xsl:with-param name="calculated_level" select="$calculated_level"/>
					</xsl:call-template>
				</xsl:variable>				
				<xsl:value-of select="$level"/>
				<xsl:text> </xsl:text><xsl:apply-templates />
				<xsl:if test="not(ancestor::sec[@sec-type = 'norm-refs'])">
					<xsl:call-template name="addIndexTerms"/>
				</xsl:if>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>&#xa;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	<xsl:template match="tbx:term"/>
	<xsl:template match="tbx:term" mode="term">
		<xsl:choose>
			<xsl:when test="position() = 1">
				<xsl:apply-templates />
				<xsl:for-each select="ancestor::tbx:termEntry">
					<xsl:call-template name="addIndexTerms"/>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>&#xa;</xsl:text>
				<xsl:choose>
					<xsl:when test="../tbx:normativeAuthorization/@value = 'admittedTerm'">alt</xsl:when>
					<xsl:when test="../tbx:normativeAuthorization/@value = 'deprecatedTerm'">deprecated</xsl:when>
					<xsl:otherwise>alt</xsl:otherwise>
				</xsl:choose>
				<xsl:text>:[</xsl:text>
				<xsl:apply-templates />
				<xsl:text>]</xsl:text>
			</xsl:otherwise>			
		</xsl:choose>
		<xsl:apply-templates select="../tbx:termType" mode="term"/>
	</xsl:template>
	
	<xsl:template match="tbx:termType" mode="term">
		<xsl:text>&#xa;&#xa;</xsl:text>
		<xsl:text>[%metadata]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>type:: </xsl:text>
		<xsl:choose>
			<xsl:when test="@value = 'variant'">full</xsl:when>
			<xsl:otherwise><xsl:value-of select="@value"/></xsl:otherwise> <!-- Example: abbreviation -->
		</xsl:choose>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="tbx:term/text()">
		<xsl:variable name="term_text" select="normalize-space(.)"/>
		<xsl:choose>
			<xsl:when test="$index//term[. = $term_text]">
				<xsl:text>((</xsl:text><xsl:value-of select="$term_text"/><xsl:text>))</xsl:text>
				<xsl:if test="following-sibling::node()"><xsl:text> </xsl:text></xsl:if>
			</xsl:when>
			<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template match="tbx:langSet">
		<xsl:apply-templates />
	</xsl:template>
	<xsl:template match="tbx:langSet/text()"/>
	<!-- <xsl:template match="text()[. = '&#xa;']"/> -->
	
	<xsl:template match="tbx:definition">
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="tbx:tig"/>
	
	<xsl:template match="label"/>
	
	<xsl:template match="p" name="p">
		<xsl:if test="ancestor::non-normative-example and not(preceding-sibling::p) and normalize-space(preceding-sibling::node()[1]) != '' and not(preceding-sibling::*[1][self::label])"><xsl:text>&#xa;&#xa;</xsl:text></xsl:if>
		
		<xsl:variable name="isFirstPinCommentary" select="starts-with(normalize-space(), 'COMMENTARY ON') and 
		(starts-with(normalize-space(.//italic/text()), 'COMMENTARY ON') or starts-with(normalize-space(.//italic2/text()), 'COMMENTARY ON'))"/>
		<xsl:choose>
			<xsl:when test="$isFirstPinCommentary = 'true'"> <!-- COMMENTARY ON -->
				<xsl:text>[NOTE,type=commentary</xsl:text>
				<!-- determine commentary target -->
				<xsl:variable name="commentary_target">
					<xsl:choose>
						<xsl:when test=".//xref"><xsl:value-of select=".//xref/@rid"/></xsl:when>
						<xsl:otherwise>
							<xsl:variable name="text_target" select=".//*[contains(local-name(),'bold')]"/>
							<xsl:if test="ancestor::*[@id and label][1]/label = $text_target">
								<xsl:value-of select="ancestor::*[@id and label][1]/@id"/>
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:if test="normalize-space($commentary_target) != ''">,target=<xsl:value-of select="$commentary_target"/></xsl:if>
				<xsl:text>]</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>====</xsl:text>
				<xsl:text>&#xa;</xsl:text>
			</xsl:when>
			<xsl:otherwise> <!-- usual paragraph -->
				<xsl:apply-templates />
				<xsl:text>&#xa;</xsl:text>
				<xsl:variable name="isLastPinCommentary" select="preceding-sibling::p[starts-with(normalize-space(), 'COMMENTARY ON') and 
							(starts-with(normalize-space(.//italic/text()), 'COMMENTARY ON') or starts-with(normalize-space(.//italic2/text()), 'COMMENTARY ON'))] and
							*[1][self::italic or self::italic2] and normalize-space(translate(./text(),'&#xa0;.','  ')) = '' and
							not(following-sibling::p[*[1][self::italic or self::italic2] and normalize-space(translate(./text(),'&#xa0;.','  ')) = ''])"/>
				<xsl:if test="$isLastPinCommentary = 'true'">
					<xsl:text>====</xsl:text>
					<xsl:text>&#xa;&#xa;</xsl:text>
				</xsl:if>
				<xsl:choose>
					<!-- if p in list-item and this p is first element (except label), next element is not another nested list, and there are another elements, or last p -->
					<xsl:when test="parent::list-item and 
					count(parent::list-item/*[not(self::label)]) &gt; 1 and
					((count(preceding-sibling::*[not(self::label)]) = 0 and following-sibling::*[1][not(self::list)]) 
					or not(following-sibling::*[not(self::list)]))"></xsl:when>
					<xsl:when test="parent::list-item and not(../following-sibling::*) and count(ancestor::list-item) &gt; 1"></xsl:when>
					<xsl:when test="parent::list-item and following-sibling::*[1][self::non-normative-note]"><xsl:text>&#xa;</xsl:text></xsl:when>
					<xsl:when test="ancestor::list-item and not(following-sibling::p) and following-sibling::non-normative-note"></xsl:when>
					<xsl:when test="ancestor::non-normative-note and not(following-sibling::p)"></xsl:when>
					<xsl:when test="ancestor::non-normative-example and not(following-sibling::p)"></xsl:when>
					<xsl:when test="not(following-sibling::p) and ancestor::list/following-sibling::non-normative-note"></xsl:when>
					<xsl:when test="ancestor::sec[@sec-type = 'norm-refs'] and not(following-sibling::*[1][self::p])"></xsl:when>
					<xsl:otherwise><xsl:text>&#xa;</xsl:text></xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
		
		<!-- insert Multi-paragraph footnotes after paragraph -->
		<xsl:for-each select=".//xref[@ref-type='fn']">
			<xsl:for-each select="//fn[@id = current()/@rid]">
				<xsl:call-template name="insertMultiParagraphFootnote" />
			</xsl:for-each>
		</xsl:for-each>
		
	</xsl:template>
		
	<xsl:template match="tbx:entailedTerm">
	
		<xsl:variable name="space_before"><xsl:if test="local-name(preceding-sibling::node()[1]) != ''"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		<xsl:variable name="space_after"><xsl:if test="local-name(following-sibling::node()[1]) != ''"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		<xsl:value-of select="$space_before"/>
	
		<xsl:variable name="target" select="substring-after(@target, 'term_')"/>
		<xsl:variable name="term">
			<xsl:choose>
				<xsl:when test="contains(., concat('(', $target, ')'))"> <!-- example: concept entry (3.5) -->
					<xsl:value-of select="normalize-space(substring-before(., concat('(', $target, ')')))"/>
				</xsl:when>
				<xsl:when test="contains(., concat(' ', $target, ')'))"> <!-- example: vocational competence (see 3.26) -->
					<xsl:value-of select="normalize-space(substring-before(., '('))"/>
				</xsl:when>
				<xsl:when test="translate(., '01234567890.', '') = ''"></xsl:when><!-- if digits and dot only, example 3.13 -->
				<xsl:otherwise>
					<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="term_real" select="normalize-space(//*[@id = current()/@target]//tbx:term[1])"/>
		
		<xsl:call-template name="insertTermReference">
			<xsl:with-param name="term" select="$term_real"/>
			<xsl:with-param name="rendering" select="$term"/>
		</xsl:call-template>

		<xsl:value-of select="$space_after"/>
		
	</xsl:template>
	
	<!-- old: term:[term] -->
	<!-- old: term:[term,rendering] -->
	<!-- {{term}} -->
	<!-- {{term,rendering}} -->
	<xsl:template name="insertTermReference">
		<xsl:param name="term"/>
		<xsl:param name="rendering"/>
		<xsl:param name="options"/> <!-- Example: {{process,*3.21*,options="noref,noital,linkmention"}} -->
		<!-- <xsl:text>term:[</xsl:text>
		<xsl:text>]</xsl:text> -->
		<xsl:text>{{</xsl:text>
		<xsl:value-of select="$term"/>
		<xsl:if test="$rendering != '' and $rendering != $term">
			<xsl:text>,</xsl:text><xsl:value-of select="$rendering"/>
		</xsl:if>
		<xsl:if test="$options != ''">
			<xsl:text>,options="</xsl:text><xsl:value-of select="$options"/><xsl:text>"</xsl:text>
		</xsl:if>
		<xsl:text>}}</xsl:text>
	</xsl:template>
	
	<xsl:template match="tbx:note" name="tbx_note">
		<xsl:variable name="isMultipleNodes" select="count(*[not(self::bold) and not(self::bold2) and 
		not(self::italic) and not(self::italic2) and 
		not(self::sup) and not(self::sup2) and 
		not(self::sub) and not(self::sub2) and
		not(self::std) and not(self::std-ref) and
		not(self::ext-link) and
		not(self::xref) and not(self::named-content) and not(local-name() = 'entailedTerm')]) &gt;= 1"/>
		<xsl:choose>
			<xsl:when test="$isMultipleNodes = 'true'">
				<xsl:text>[NOTE]</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>====</xsl:text>
				<xsl:text>&#xa;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>NOTE: </xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:variable name="note_content"><xsl:apply-templates/></xsl:variable>
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new($note_content), '(\r\n|\n|\r)+$', '')"/>
		<xsl:text>&#xa;</xsl:text>
		
		<xsl:if test="$isMultipleNodes = 'true'">
			<xsl:text>====</xsl:text>
		</xsl:if>
		
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<!-- <xsl:template match="non-normative-note[ancestor::list-item]" priority="3">
		<xsl:if test="not(preceding-sibling::*[1][self::list or self::non-normative-note])">
			<xsl:text>+</xsl:text>
		</xsl:if>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>- -</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>NOTE: </xsl:text>
		<xsl:apply-templates/>
		<xsl:text>- -</xsl:text>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template> -->
	
	<xsl:template match="non-normative-note[count(*[not(local-name() = 'label')]) &gt; 1]" priority="2">
		<xsl:text>[NOTE]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>====</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:variable name="note_content"><xsl:apply-templates/></xsl:variable>
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new($note_content), '(\r\n|\n|\r)+$', '')"/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>====</xsl:text>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="non-normative-note">
		<xsl:text>NOTE: </xsl:text>
		<xsl:apply-templates/>
		<xsl:choose>
			<xsl:when test="parent::list-item and preceding-sibling::*[1][not(self::label)] and not(following-sibling::*)"></xsl:when>
			<xsl:otherwise><xsl:text>&#xa;</xsl:text></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<!-- empty 
		<std>
			<std-ref/>
		</std>
	-->
	<xsl:template match="std[normalize-space() = '']">
		<xsl:text> </xsl:text>
	</xsl:template>
	
	<!-- Example:
		<std std-id="ISO 12345:2011" type="dated">
			<std-ref>ISO 12345:2011</std-ref>
		</std>
	-->
	<xsl:template match="std">
	
		<xsl:variable name="space_before"><xsl:if test="local-name(preceding-sibling::node()[1]) != ''"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		<xsl:variable name="space_after"><xsl:if test="local-name(following-sibling::node()[1]) != ''"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		<xsl:value-of select="$space_before"/>
		
		<xsl:if test="italic[std-ref]">_</xsl:if>
		<xsl:if test="italic2[std-ref]">__</xsl:if>
		<xsl:if test="bold[std-ref]">*</xsl:if>
		<xsl:if test="bold2[std-ref]">**</xsl:if>
		
		<xsl:text>&lt;&lt;</xsl:text>
		<xsl:call-template name="insertStd" />
		<xsl:text>&gt;&gt;</xsl:text>
		
		<xsl:if test="italic[std-ref]">_</xsl:if>
		<xsl:if test="italic2[std-ref]">__</xsl:if>
		<xsl:if test="bold[std-ref]">*</xsl:if>
		<xsl:if test="bold2[std-ref]">**</xsl:if>
		
		<xsl:value-of select="$space_after"/>
	</xsl:template>
	
	<xsl:template name="insertStd">
		
		<xsl:variable name="clause" select="substring-after(@std-id, ':clause:')"/>
		<xsl:variable name="locality">
			<xsl:choose>
				<xsl:when test="$clause != '' and translate(substring($clause, 1, 1), '0123456789', '') = ''"><locality>clause=<xsl:value-of select="$clause"/></locality></xsl:when>
				<xsl:when test="$clause != ''"><locality>annex=<xsl:value-of select="$clause"/></locality></xsl:when>
				<xsl:when test="not(@std-id) or $clause = ''">
					<!-- get text -->
					<xsl:variable name="std_text_">
						<xsl:choose>
							<xsl:when test=".//std-ref">
								<xsl:variable name="text">
									<xsl:for-each select=".//std-ref/following-sibling::node()">
										<xsl:value-of select="translate(., '&#xa0;', ' ')"/>
									</xsl:for-each>
								</xsl:variable>
								<xsl:value-of select="normalize-space(translate($text, '&#xa0;', ' '))"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="normalize-space(translate(., '&#xa0;', ' '))"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- DEBUG: std_text_='<xsl:value-of select="$std_text_"/>' -->
					
					<!-- remove leading comma -->
					<xsl:variable name="std_text" select="normalize-space(java:replaceAll(java:java.lang.String.new($std_text_),'^:?—?,?(.*)$','$1'))"/>
					<!-- replace ' to ' to '-' -->
					<xsl:variable name="std_text1" select="java:replaceAll(java:java.lang.String.new($std_text),' to [cC]lause ','-')"/>
					<xsl:variable name="std_text2" select="java:replaceAll(java:java.lang.String.new($std_text1),' to [aA]nnex ','-')"/>
					<xsl:variable name="std_text3" select="java:replaceAll(java:java.lang.String.new($std_text2),' to [tT]able ','-')"/>
					<xsl:variable name="std_text4" select="java:replaceAll(java:java.lang.String.new($std_text3),' to [sS]ection ','-')"/>
					<xsl:variable name="std_text5" select="java:replaceAll(java:java.lang.String.new($std_text4),' to ','-')"/>
					
					<!-- replace ' and|or Xxxxx ' to 'xxxxx' -->
					<xsl:variable name="std_text6" select="java:replaceAll(java:java.lang.String.new($std_text5),'( and | or )[cC]lause',',clause')"/>
					<xsl:variable name="std_text7" select="java:replaceAll(java:java.lang.String.new($std_text6),'( and | or )[aA]nnex',',annex')"/>
					<xsl:variable name="std_text8" select="java:replaceAll(java:java.lang.String.new($std_text7),'( and | or )[tT]able',',table')"/>
					<xsl:variable name="std_text9" select="java:replaceAll(java:java.lang.String.new($std_text8),'( and | or )[sS]ection',',section')"/>
					
					<!-- replace  'Xxxxx' to 'xxxxx' -->
					<xsl:variable name="std_text10" select="java:replaceAll(java:java.lang.String.new($std_text9),'[aA]nnexes','annex')"/>
					<xsl:variable name="std_text11" select="java:replaceAll(java:java.lang.String.new($std_text10),'[aA]nnex','annex')"/>
					<xsl:variable name="std_text12" select="java:replaceAll(java:java.lang.String.new($std_text11),'[tT]able','table')"/>
					<xsl:variable name="std_text13" select="java:replaceAll(java:java.lang.String.new($std_text12),'[cC]lause','clause')"/>
					<xsl:variable name="std_text14" select="java:replaceAll(java:java.lang.String.new($std_text13),'[sS]ection','section')"/>
					
					<xsl:variable name="std_text_lc_" select="$std_text14"/>
					
					<xsl:variable name="std_text_lc">
						<xsl:choose>
							<xsl:when test="starts-with($std_text_lc_, 'annex')">
								<xsl:value-of select="java:replaceAll(java:java.lang.String.new($std_text_lc_),' and | or ',',annex ')"/>
							</xsl:when>
							<xsl:when test="starts-with($std_text_lc_, 'table')">
								<xsl:value-of select="java:replaceAll(java:java.lang.String.new($std_text_lc_),' and | or ',',table ')"/>
							</xsl:when>
							<xsl:when test="starts-with($std_text_lc_, 'clause')">
								<xsl:value-of select="java:replaceAll(java:java.lang.String.new($std_text_lc_),' and | or ',',clause ')"/>
							</xsl:when>
							<xsl:when test="starts-with($std_text_lc_, 'section')">
								<xsl:value-of select="java:replaceAll(java:java.lang.String.new($std_text_lc_),' and | or ',',section ')"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$std_text_lc_"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- DEBUG:std_text_lc='<xsl:value-of select="$std_text_lc"/>' -->
					<xsl:choose>
						<!-- <xsl:when test="contains($std_text_lc, 'clause') or contains($std_text_lc, 'annex') or contains($std_text_lc, 'table') or contains($std_text_lc, 'section')"> -->
						<xsl:when test="starts-with($std_text_lc, 'clause') or starts-with($std_text_lc, 'annex') or starts-with($std_text_lc, 'table') or starts-with($std_text_lc, 'section')">
							<!-- <xsl:text>,</xsl:text> -->
							<xsl:variable name="pairs" select="translate($std_text_lc, ' ', '=')"/>
							<locality><xsl:value-of select="$pairs"/></locality>
							<!-- <xsl:value-of select="java:toLowerCase(java:java.lang.String.new(substring-before($pair, '=')))"/>
							<xsl:text>=</xsl:text>
							<xsl:variable name="localityDestination" select="substring-after($pair, '=')"/>
							<xsl:value-of select="$localityDestination"/> -->
						</xsl:when>
						<xsl:when test="contains($std_text_lc, 'clause') or contains($std_text_lc, 'annex') or contains($std_text_lc, 'table') or contains($std_text_lc, 'section')">
							<!-- <xsl:text>,</xsl:text> -->
							<xsl:variable name="pairs" select="translate($std_text_lc, ' ', '=')"/>
							<xsl:choose>
								<xsl:when test="translate(substring($pairs, 1, 1), '0123456789', '') = ''"><locality>clause=<xsl:value-of select="$pairs"/></locality></xsl:when>
								<xsl:otherwise><locality>annex=<xsl:value-of select="$pairs"/></locality></xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:when test="contains($std_text_lc, 'definition')">
							<xsl:variable name="pairs" select="translate($std_text_lc, ' ', '=')"/>
							<locality>locality:<xsl:value-of select="$pairs"/></locality>
						</xsl:when>
						<xsl:when test="not(.//std-ref)"></xsl:when> <!-- <std std-id="ISO 13485:2016" type="dated">ISO 13485:2016</std> -->
						<xsl:otherwise>
							<xsl:variable name="parts">
								<xsl:call-template name="split">
									<xsl:with-param name="pText" select="$std_text_lc"/>
									<xsl:with-param name="sep" select="' '"/>
								</xsl:call-template>
							</xsl:variable>
							<xsl:for-each select="xalan:nodeset($parts)//item">
								<xsl:variable name="item_text" select="java:replaceAll(java:java.lang.String.new(.),'^(.*?),?$','$1')"/> <!-- remove trailing comma -->
								<xsl:choose>
									<xsl:when test="normalize-space($item_text) = ''"><!-- skip --></xsl:when>
									<xsl:when test="translate(substring($item_text, 1, 1), '0123456789', '') = ''"><locality>clause=<xsl:value-of select="$item_text"/></locality></xsl:when>
									<xsl:when test="$item_text = 'and' or $item_text = ',' or $item_text = ':—'"><!-- skip --></xsl:when>
									<xsl:when test="contains($item_text, 'series') or contains($item_text, '(all') or contains($item_text, 'parts')"><not_locality><xsl:value-of select="$item_text"/></not_locality></xsl:when>
									<xsl:otherwise><locality>annex=<xsl:value-of select="java:toUpperCase(java:java.lang.String.new($item_text))"/></locality></xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="reference">
			<xsl:call-template name="getReference">
				<xsl:with-param name="stdid" select="current()/@stdid"/>
				<xsl:with-param name="locality" select="$locality"/>
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:choose>
			<!-- <xsl:when test="xalan:nodeset($ref_by_stdid)/*"> --> <!-- if references in References found, then put id of those reference -->
			<xsl:when test="$reference != ''"> <!-- if references in References found, then put id of those reference -->
				<!-- <xsl:value-of select="xalan:nodeset($ref_by_stdid)/@id"/> -->
				<xsl:value-of select="$reference"/>
				<!-- <xsl:value-of select="$locality"/> -->
			</xsl:when>
			<xsl:otherwise> <!-- put id of current std -->
				<xsl:text>hidden_bibitem_</xsl:text>
				<xsl:value-of select="@stdid"/>
				<!-- <xsl:value-of select="$locality"/> -->
				<xsl:for-each select="xalan:nodeset($locality)/locality">
					<xsl:text>,</xsl:text><xsl:value-of select="."/>
				</xsl:for-each>
				<!-- if there isn't in References, then display name -->
				<xsl:variable name="std-ref_text" select=".//std-ref/text()"/>
				<xsl:if test="normalize-space($std-ref_text) != ''">
					<xsl:text>,</xsl:text><xsl:value-of select="$std-ref_text"/>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	
	<xsl:template name="getReference">
		<xsl:param name="stdid"/>
		<xsl:param name="locality"/>
		<!-- @stdid and @stdid_option attributes were added in linearize.xsl -->
		<xsl:variable name="ref_" select="$updated_xml//ref[@stdid = $stdid or @stdid_option = $stdid or @id = $stdid]"/>
		<xsl:variable name="ref" select="xalan:nodeset($ref_)"/>
		<xsl:variable name="ref_by_stdid" select="normalize-space($ref/@id)"/> <!-- find ref by id -->
		<xsl:value-of select="$ref_by_stdid"/>
		<xsl:if test="$ref_by_stdid != ''">
			<!-- <xsl:value-of select="$locality"/> -->
			<xsl:variable name="locality_" select="xalan:nodeset($locality)"/>
			<xsl:for-each select="$locality_/locality">
				<xsl:text>,</xsl:text><xsl:value-of select="."/>
			</xsl:for-each>
			<xsl:if test="$ref/@addTextToReference = 'true' or $locality_/not_locality">
				<xsl:text>,</xsl:text>
				<xsl:value-of select=".//std-ref/text()"/>
				<xsl:for-each select="$locality_/not_locality">
					<xsl:text> </xsl:text><xsl:value-of select="."/>
				</xsl:for-each>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="std-id-group"/>
	
	<!-- <xsl:template match="std[not(ancestor::ref)]/text()">
		<xsl:variable name="text" select="normalize-space(translate(.,'&#xA0;', ' '))"/>
		<xsl:choose>
			<xsl:when test="starts-with($text, ',')">
				<xsl:call-template name="getUpdatedRef">
					<xsl:with-param name="text" select="$text"/>
				</xsl:call-template>				
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template> -->
	
	<xsl:template match="ref//std-ref"> <!-- sec[@sec-type = 'norm-refs'] -->
		<xsl:apply-templates />
	</xsl:template>
	
	
	<!-- ================= -->
	<!-- tbx:source processing -->
	<!-- ================= -->
	<xsl:template match="tbx:source">
		<xsl:text>[.source]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&lt;&lt;</xsl:text>
			<xsl:variable name="result_parts_">
				<xsl:apply-templates />
			</xsl:variable>
			
			<xsl:variable name="result_parts">
				<xsl:for-each select="xalan:nodeset($result_parts_)/node()[1]">
					<item>
						<xsl:variable name="reference">
							<xsl:call-template name="getReference">
								<xsl:with-param name="stdid" select="normalize-space(.)"/>
							</xsl:call-template>
						</xsl:variable>
						<!-- reference=<xsl:value-of select="$reference"/><xsl:text>&#xa;</xsl:text> -->
						<xsl:if test="normalize-space($reference) = ''">hidden_bibitem_</xsl:if><xsl:value-of select="."/>
					</item>
				</xsl:for-each>
				<xsl:for-each select="xalan:nodeset($result_parts_)/*[self::locality or self::localityContinue]">
					<xsl:copy>
						<!-- <xsl:value-of select="."/> -->
						<!-- remove comma at end -->
						<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),',$','')"/>
					</xsl:copy>
				</xsl:for-each>
				<xsl:for-each select="xalan:nodeset($result_parts_)/node()[position() &gt; 1 and not(self::locality or self::localityContinue)]">
					<item>
						<xsl:value-of select="."/>
					</item>
				</xsl:for-each>
			</xsl:variable>
			<xsl:for-each select="xalan:nodeset($result_parts)/node()[normalize-space() != '']">
				<xsl:value-of select="."/>
				<xsl:if test="position() != last()">
					<xsl:choose>
						<xsl:when test="following-sibling::*[1][self::localityContinue]"></xsl:when>
						<xsl:otherwise>,</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</xsl:for-each>
			
		<xsl:text>&gt;&gt;</xsl:text>
		
		<xsl:variable name="isModified" select="contains(normalize-space(.), ' modified')"/>
		<xsl:if test="$isModified = 'true'">
			<xsl:text>,</xsl:text>
			<xsl:value-of select="java:replaceAll(java:java.lang.String.new(substring-after(normalize-space(.), ' modified')), '^(\s|\h)*(-|–)?(\s|\h)*','')"/>
		</xsl:if>
		
		<xsl:text>&#xa;&#xa;</xsl:text>
		
	</xsl:template>

	
	<xsl:template match="tbx:source/text()" priority="3">
	
		<xsl:variable name="isFirstText" select="not(preceding-sibling::node())"/>
	
		<xsl:variable name="modified_text">, modified</xsl:variable>
		
		<!-- remove modified text -->
		<xsl:variable name="text">
			<xsl:choose>
				<xsl:when test="contains(., $modified_text)">
					<xsl:value-of select="substring-before(., $modified_text)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="source_parts_">
			<xsl:call-template name="split">
				<xsl:with-param name="pText" select="$text"/>
				<xsl:with-param name="sep" select="','"/>
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:variable name="source_parts" select="xalan:nodeset($source_parts_)"/>
		
		<xsl:variable name="xref_bibr_rid" select="following-sibling::xref[@ref-type='bibr']/@rid"/>
		
		<xsl:variable name="is_next_xref_bibr" select="normalize-space(following-sibling::*[1][self::xref[@ref-type='bibr']] and 1 = 1)"/>
		<xsl:variable name="is_prev_xref_bibr" select="normalize-space(preceding-sibling::*[1][self::xref[@ref-type='bibr']] and 1 = 1)"/>
		
		<xsl:variable name="result_parts_">
			<xsl:for-each select="$source_parts//item">
				<xsl:variable name="item_text">
					<xsl:choose>
						<!-- remove [ before xref -->
						<xsl:when test="position() = last() and $is_next_xref_bibr = 'true' and substring(., string-length(.)) = '['">
							<xsl:value-of select="substring(., 1, string-length(.) - 1)"/>
						</xsl:when>
						<!-- remove ] after xref -->
						<xsl:when test="position() = 1 and $is_prev_xref_bibr = 'true' and starts-with(., ']')">
							<xsl:value-of select="substring(., 2)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="."/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$isFirstText = 'true' and position() = 1">
						
						<xsl:choose>
							<!-- get xref/@rid (reference to bibliography) as reference, if exists -->
							<xsl:when test="normalize-space($xref_bibr_rid) != ''">
								<item><xsl:value-of select="$xref_bibr_rid"/></item>
								<!-- <xsl:text>,</xsl:text> -->
								<item><xsl:value-of select="$item_text"/></item>
							</xsl:when>
							<xsl:otherwise>
								<!-- <xsl:variable name="first_text" select="$source_parts/item[1]"/> -->
								<xsl:call-template name="getStdRef">
									<xsl:with-param name="text" select="$item_text"/>
								</xsl:call-template>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="java:org.metanorma.utils.RegExHelper.matches('^(Clause(\s|\h)+)[0-9]+(\.[0-9]+)*$', normalize-space($item_text)) = 'true'"> <!-- Example: Clause 4 -->
								<locality>
									<xsl:value-of select="java:toLowerCase(java:java.lang.String.new($item_text))"/>
								</locality>
							</xsl:when>
							<xsl:when test="java:org.metanorma.utils.RegExHelper.matches('^(Box(\s|\h)+)[0-9]+$', normalize-space($item_text)) = 'true'"> <!-- Example: Box 8 -->
								<locality>
									<xsl:text>locality:box=</xsl:text><xsl:value-of select="java:replaceAll(java:java.lang.String.new($item_text),'^(Box(\s|\h)+)([0-9]+)$','$3')"/>
								</locality>
							</xsl:when>
							<xsl:when test="java:org.metanorma.utils.RegExHelper.matches('^[0-9]+(\.[0-9]+)*$', normalize-space($item_text)) = 'true'"> <!-- Example: 3.23 or 3.2.4 -->
								<locality>
									<xsl:text>clause </xsl:text><xsl:value-of select="$item_text"/>
								</locality>
							</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="$item_text = 'definition'">
										<locality>
											<xsl:text>locality:</xsl:text>
											<xsl:value-of select="$item_text"/>
										</locality>
									</xsl:when>
									<xsl:otherwise>
										<item>
											<xsl:value-of select="$item_text"/>
										</item>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		
		<xsl:copy-of select="$result_parts_"/>
	</xsl:template>
	

	<xsl:template match="tbx:source/std" priority="2">
		<xsl:call-template name="insertStd"/>
	</xsl:template>
	
	
	<xsl:template match="tbx:source/bold | tbx:source/bold2" priority="2">
		<xsl:choose>
			<xsl:when test="contains(preceding-sibling::node(), 'definition')">
				<localityContinue>
					<xsl:text>=</xsl:text>
					<xsl:apply-templates />
				</localityContinue>
			</xsl:when>
			<xsl:otherwise>
				<locality>
					<xsl:text>clause </xsl:text>
					<xsl:apply-templates />
				</locality>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="tbx:source/bold/xref[@ref-type = 'sec'] | tbx:source/bold2/xref[@ref-type = 'sec']" priority="2">
		<xsl:apply-templates />
	</xsl:template>
	<xsl:template match="tbx:source/xref[@ref-type = 'bibr']" priority="2" />
		
	<xsl:template match="tbx:source/xref[@ref-type = 'fn']" priority="3">
		<!-- to do -->
		<!-- <xsl:apply-templates /> -->
	</xsl:template>
	
	<xsl:template match="tbx:source/text()[last()]" name="source_text_modified" priority="2">
	</xsl:template>
	
	<xsl:template match="tbx:source/text()" mode="source_text_modified">
		<xsl:call-template name="source_text_modified"/>
	</xsl:template>
	
	
	<xsl:template match="@*|node()" mode="tbx_source_simplify">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="tbx_source_simplify"/>		
		</xsl:copy>
	</xsl:template>

	<xsl:template match="text()" priority="2" mode="tbx_source_simplify"> <!-- [starts-with(., ', modified') or starts-with(., ' modified')] -->
		<xsl:choose>
			<xsl:when test="contains(., ', modified')"><xsl:value-of select="substring-before(., ', modified')"/></xsl:when>
			<xsl:when test="contains(., 'modified')"><xsl:value-of select="substring-before(., 'modified')"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="xref[@ref-type = 'bibr']" mode="tbx_source_simplify"/>
	<!-- ================= -->
	<!-- END tbx:source processing -->
	<!-- ================= -->
	
	<!-- ================= -->
	<!-- List processing -->
	<!-- ================= -->
	<xsl:template match="list">
		<xsl:if test="not(parent::list-item) and not(parent::non-normative-note and preceding-sibling::p)">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		<xsl:text>&#xa;</xsl:text>
		<xsl:variable name="list-type">
			<xsl:apply-templates select="@list-type"/>
		</xsl:variable>
		
		<!-- https://www.metanorma.org/author/topics/document-format/text/#ordered-lists: 
		commented due: The start attribute for ordered lists is only allowed by certain Metanorma flavors, such as BIPM.
		-->
		<!-- <xsl:variable name="start">
			<xsl:call-template name="getListStartValue"/>
		</xsl:variable>
		<xsl:if test="$start != '' and $start != '1'">
			<xsl:text>[start=</xsl:text><xsl:value-of select="$start"/><xsl:text>]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if> -->
		
		<xsl:apply-templates/>
		
		<!-- <xsl:if test="not(parent::list-item)"> -->
		<xsl:choose>
			<xsl:when test="following-sibling::*[1][not(self::list)] and parent::list-item"></xsl:when> <!-- no need to insert new line, because '+ new line' will be inserted -->
			<xsl:otherwise>
				<xsl:text>&#xa;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
			
		<!-- </xsl:if> -->
	</xsl:template>
	
	<xsl:template match="list/@list-type">
		<xsl:variable name="first_label" select="translate(..//label[1], ').', '')"/>
		<xsl:variable name="listtype">
			<xsl:choose>
				<xsl:when test=". = 'alpha-lower'"></xsl:when> <!-- loweralpha --> <!-- https://github.com/metanorma/sts2mn/issues/22: on list don't need to be specified because it is default MN-BSI style -->
				<xsl:when test=". = 'alpha-upper'">upperalpha</xsl:when>
				<xsl:when test=". = 'roman-lower'">lowerroman</xsl:when>
				<xsl:when test=". = 'roman-upper'">upperroman</xsl:when>
				<xsl:when test=". = 'arabic'">arabic</xsl:when>
				<xsl:when test="$first_label != '' and translate($first_label, '1234567890', '') = ''">arabic</xsl:when>
				<xsl:when test="$first_label != '' and translate($first_label, 'ixvcm', '') = ''">lowerroman</xsl:when>
				<xsl:when test="$first_label != '' and translate($first_label, 'IXVCM', '') = ''">upperroman</xsl:when>
				<xsl:when test="$first_label != '' and translate($first_label, 'abcdefghijklmnopqrstuvwxyz', '') = ''"></xsl:when> <!-- loweralpha -->
				<xsl:when test="$first_label != '' and translate($first_label, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', '') = ''">upperalpha</xsl:when>
				<xsl:otherwise></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- <xsl:if test="$listtype != ''">		
			<xsl:text>[</xsl:text>
			<xsl:value-of select="$listtype"/>
			<xsl:text>]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if> -->
	</xsl:template>
	
	<xsl:template name="getListStartValue">
		<xsl:variable name="first_label" select="translate(.//label[1], ').', '')"/>
		<xsl:variable name="type">
			<xsl:choose>
				<xsl:when test="$first_label != '' and translate($first_label, '1234567890', '') = ''">arabic</xsl:when>
				<xsl:when test="@list-type = 'alpha-lower'">alphabet</xsl:when>
				<xsl:when test="@list-type = 'alpha-upper'">alphabet_upper</xsl:when>
				<xsl:when test="@list-type = 'roman-lower'">roman</xsl:when>
				<xsl:when test="@list-type = 'roman-upper'">roman_upper</xsl:when>
				<xsl:when test="@list-type = 'arabic'">arabic</xsl:when>
				<xsl:when test="$first_label != '' and translate($first_label, 'ixvcm', '') = ''">roman</xsl:when>
				<xsl:when test="$first_label != '' and translate($first_label, 'IXVCM', '') = ''">roman_upper</xsl:when>
				<xsl:when test="$first_label != '' and translate($first_label, 'abcdefghijklmnopqrstuvwxyz', '') = ''">alphabet</xsl:when>
				<xsl:when test="$first_label != '' and translate($first_label, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', '') = ''">alphabet_upper</xsl:when>
				<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="start">
			<xsl:choose>
				<xsl:when test="$type = 'arabic' and $first_label != '1'"><xsl:value-of select="$first_label"/></xsl:when>
				<xsl:when test="normalize-space($first_label) != '' and (($type = 'roman' and $first_label != 'i') or
						($type = 'roman_upper' and $first_label != 'I') or 
						($type = 'alphabet' and $first_label != 'a') or
						($type = 'alphabet_upper' and $first_label != 'A'))">
						<xsl:value-of select="java:org.metanorma.utils.Util.getListStartValue($type, $first_label)"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="normalize-space($start)"/>
	</xsl:template>
	
	
	<xsl:template match="list/list-item">
		<xsl:variable name="list_item_label">
			<xsl:choose>
				<xsl:when test="ancestor::list[1]/@list-type = 'bullet' or 
								ancestor::list[1]/@list-type = 'dash' or
								ancestor::list[1]/@list-type = 'simple'">				
					<xsl:call-template name="getLevelListItem">
						<xsl:with-param name="list-label">*</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>				
					<xsl:call-template name="getLevelListItem">
						<xsl:with-param name="list-label">.</xsl:with-param>
					</xsl:call-template>				
				</xsl:otherwise>
			</xsl:choose>
			<xsl:text> </xsl:text>
		</xsl:variable>
		<xsl:variable name="list_item_content"><xsl:apply-templates mode="list_item"/></xsl:variable>
		<xsl:if test="normalize-space($list_item_content) != ''">
			<xsl:if test="not(count(*) = 1 and list)">
				<xsl:value-of select="$list_item_label"/>
			</xsl:if>
			<xsl:value-of select="$list_item_content"/>
		</xsl:if>
	</xsl:template>
	
	
	<xsl:template match="list-item/text() | list-item/list | list-item/label" mode="list_item" priority="2">
		<xsl:apply-templates select="."/> <!-- continue process the element inslde list-item-->
	</xsl:template>
	
	<!-- https://docs.asciidoctor.org/asciidoc/latest/lists/continuation/ -->
	<xsl:template match="list-item/*" mode="list_item">
		
		<!-- opening continuation -->
		
		<!-- second element in list-item -->
		<xsl:variable name="opening_condition1" select="count(preceding-sibling::*[not(self::label) and not(self::list)]) = 1 and
							not(preceding-sibling::*[1][self::list])"/>
		
		<!-- if preceding element is list, then  move up one level of nesting -->
		<xsl:variable name="opening_condition2" select="preceding-sibling::*[1][self::list] and 1 = 1"/> <!-- for boolean type -->
		
		<xsl:if test="$opening_condition1 = 'true' or $opening_condition2 = 'true'">
			<xsl:text>+</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>--</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		
		<xsl:text></xsl:text>
		<xsl:apply-templates select="."/> <!-- continue process the element inslde list-item-->
		<xsl:text></xsl:text>
		<!-- closing continuation -->
		
		<!-- if there isn't next elements, or next element is nestel list -->
		<xsl:variable name="closing_condition1" select="count(preceding-sibling::*[1][not(self::label) and not(self::list)]) = 1 and 
					count(parent::list-item/*[not(self::label) and not(self::list)]) &gt; 1 and
					(not(following-sibling::*) or following-sibling::*[1][self::list])"/>
					
		<!-- p between two lists, or latest after nested list -->
		<xsl:variable name="closing_condition2" select="preceding-sibling::*[1][self::list] and (following-sibling::*[1][self::list] or not(following-sibling::*))"/>
		
		
		<xsl:if test="$closing_condition1 = 'true' or $closing_condition2 = 'true'">
			<!-- closing -->
			<xsl:text>--</xsl:text>
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
		
		
	</xsl:template>
	<!-- ================= -->
	<!-- END List processing -->
	<!-- ================= -->
	
	
	<xsl:template match="tbx:example | non-normative-example">
		<!-- <xsl:text>[example]</xsl:text> -->
		<xsl:if test="preceding-sibling::node()[1][self::text()]">
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
		<xsl:call-template name="setId"/>
		<xsl:text>====</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates />
		<xsl:if test="local-name() = 'example'">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		<xsl:text>====</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<!-- <xsl:if test="local-name() = 'example'">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if> -->
	</xsl:template>
	
	
	<xsl:template match="title/break" priority="2">
		<xsl:text>+++&lt;br/&gt;+++</xsl:text>
	</xsl:template>
	
	<xsl:template match="break">
		<xsl:text> +</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template match="bold">
		<xsl:if test="parent::*[local-name() = 'td' or local-name() = 'th'] and not(preceding-sibling::node())"><xsl:text> </xsl:text></xsl:if>
		<xsl:text>*</xsl:text><xsl:apply-templates /><xsl:text>*</xsl:text>
	</xsl:template>
	
	<xsl:template match="bold2">
		<xsl:if test="parent::*[local-name() = 'td' or local-name() = 'th'] and not(preceding-sibling::node())"><xsl:text> </xsl:text></xsl:if>
		<xsl:text>**</xsl:text><xsl:apply-templates /><xsl:text>**</xsl:text>
	</xsl:template>
	
	<xsl:template match="italic | italic2">
		<xsl:choose>
			<!-- if italic in paragraph that relates to COMMENTARY -->
			<xsl:when test="parent::p[*[1][self::italic or self::italic2] and normalize-space(translate(./text(),'&#xa0;.','  ')) = ''] and 
			parent::p/preceding-sibling::p[starts-with(normalize-space(), 'COMMENTARY ON') and 
							(starts-with(normalize-space(.//italic/text()), 'COMMENTARY ON') or starts-with(normalize-space(.//italic2/text()), 'COMMENTARY ON'))]">
				<!-- no italic -->
				<xsl:apply-templates />
			</xsl:when>
			<!-- if italic in list-item that relates to COMMENTARY -->
			<xsl:when test="ancestor::list/preceding-sibling::p[starts-with(normalize-space(), 'COMMENTARY ON') and 
							(starts-with(normalize-space(.//italic/text()), 'COMMENTARY ON') or starts-with(normalize-space(.//italic2/text()), 'COMMENTARY ON'))]">
				<!-- no italic -->
				<xsl:apply-templates />
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="self::italic2"><xsl:text>_</xsl:text></xsl:if>
				<xsl:text>_</xsl:text><xsl:apply-templates /><xsl:text>_</xsl:text>
				<xsl:if test="self::italic2"><xsl:text>_</xsl:text></xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'italic' or local-name() = 'italic2'][parent::p[*[1][self::italic or self::italic2] and normalize-space(translate(./text(),'&#xa0;.','  ')) = ''] and 
			parent::p/preceding-sibling::p[starts-with(normalize-space(), 'COMMENTARY ON') and 
							(starts-with(normalize-space(.//italic/text()), 'COMMENTARY ON') or starts-with(normalize-space(.//italic2/text()), 'COMMENTARY ON'))]]/text()[1]">
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),'^[a-z]\)(\s|\h)+','. ')"/>
	</xsl:template>
	
	<!-- <xsl:template match="std/italic | std/bold | std/italic2 | std/bold2 | non-normative-note//italic[count(parent::*) = 1] | non-normative-note//italic2[count(parent::*) = 1]" priority="2"> -->
	<xsl:template match="std/italic | std/bold | std/italic2 | std/bold2 | non-normative-note//italic[count(parent::*/node()) = 1] | non-normative-note//italic2[count(parent::*/node()) = 1] |
			tbx:note//italic[count(parent::*/node()) = 1] | tbx:note//italic2[count(parent::*/node()) = 1] " priority="2">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="underline">
		<xsl:text>[underline]#</xsl:text><xsl:apply-templates /><xsl:text>#</xsl:text>
	</xsl:template>
	
	<xsl:template match="sub">
		<xsl:text>~</xsl:text><xsl:apply-templates /><xsl:text>~</xsl:text>
	</xsl:template>
	
	<!-- <xsl:template match="sub2">
		<xsl:text>~~</xsl:text><xsl:apply-templates /><xsl:text>~~</xsl:text>
	</xsl:template> -->
	
	<xsl:template match="sup">
		<xsl:text>^</xsl:text><xsl:apply-templates /><xsl:text>^</xsl:text>
	</xsl:template>
	
	<!-- <xsl:template match="sup2">
		<xsl:text>^^</xsl:text><xsl:apply-templates /><xsl:text>^^</xsl:text>
	</xsl:template> -->
	
	<xsl:template match="monospace">
		<xsl:text>`</xsl:text><xsl:apply-templates /><xsl:text>`</xsl:text>
	</xsl:template>
	
	<xsl:template match="monospace2">
		<xsl:text>``</xsl:text><xsl:apply-templates /><xsl:text>``</xsl:text>
	</xsl:template>
	
	<xsl:template match="sc">
		<xsl:variable name="prev_text" select="preceding-sibling::node()[self::text()]"/>
		<xsl:variable name="prev_text_last_char" select="substring($prev_text, string-length($prev_text))"/>
		<xsl:choose>
			<xsl:when test="java:org.metanorma.utils.RegExHelper.matches('\w', $prev_text_last_char) = 'true'">
				<xsl:text>+++&lt;smallcap&gt;+++</xsl:text>
				<xsl:apply-templates />
				<xsl:text>+++&lt;/smallcap&gt;+++</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>[smallcap]#</xsl:text>
				<xsl:apply-templates />
				<xsl:text>#</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="ext-link">
		
		<xsl:choose>
			<xsl:when test="$organization = 'BSI' or $organization = 'PAS'">
				<xsl:value-of select="translate(@xlink:href, '&#x2011;', '-')"/> <!-- non-breaking hyphen minus -->
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="@xlink:href"/>
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:text>[</xsl:text><xsl:apply-templates /><xsl:text>]</xsl:text>
	</xsl:template>
	
	<!-- <xsl:template match="ext-link/@xlink:href">
		<xsl:text>[</xsl:text><xsl:value-of select="."/><xsl:text>]</xsl:text>
	</xsl:template> -->
	
	<xsl:template match="xref">
		<xsl:variable name="rid_" select="@rid"/>
		<xsl:variable name="rid_tmp">
			<xsl:if test="//array[@id = $rid_]">array_</xsl:if>
			<xsl:value-of select="$rid_"/>
		</xsl:variable>
		<xsl:variable name="rid" select="normalize-space($rid_tmp)"/>
		<xsl:choose>
			<xsl:when test="@ref-type = 'fn' or @ref-type = 'table-fn'">
				<!-- find <fn id="$rid" -->
				<xsl:variable name="addspace" select="count(following-sibling::node()[1][self::bold or self::bold2 or self::italic or self::italic2 or self::sup or self::sup2 or self::sub or self::sub2]) != 0"/> <!-- [starts-with(text(), ' ')] -->
				<xsl:choose>
					<xsl:when test="//fn[@id = current()/@rid]/ancestor::table-wrap-foot">
						<xsl:apply-templates select="//fn[@id = current()/@rid]"/>
						<xsl:if test="$addspace = 'true'"><xsl:text> </xsl:text></xsl:if>
					</xsl:when>
					<!-- in fn in fn-group -->
					<xsl:when test="//fn[@id = current()/@rid]/ancestor::fn-group">
						<xsl:apply-templates select="//fn[@id = current()/@rid]"/>
						<xsl:if test="$addspace = 'true'"><xsl:text> </xsl:text></xsl:if>
						<!-- <xsl:text>{</xsl:text>
						<xsl:value-of select="@rid"/>
						<xsl:text>}</xsl:text> -->
					</xsl:when>
					<xsl:otherwise>
						<!-- fn will be processed after xref -->
						<!-- no need to process right now -->
						<!-- <xsl:apply-templates select="//fn[@id = current()/@rid]"/> -->
					</xsl:otherwise>
				</xsl:choose>				
			</xsl:when>
			<!-- <xsl:when test="@ref-type = 'fn' and ancestor::td">
				<xsl:choose>
					<xsl:when test="//fn[@id = current()/@rid]/ancestor::fn-group">
						<xsl:text>{</xsl:text>
						<xsl:value-of select="@rid"/>
						<xsl:text>}</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text> footnote:</xsl:text>
						<xsl:value-of select="@rid"/>
						<xsl:text>[]</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="@ref-type = 'fn' and ancestor::def-item">
				<xsl:text> footnote:</xsl:text>
				<xsl:value-of select="@rid"/>
				<xsl:text>[]</xsl:text>
			</xsl:when>
			<xsl:when test="@ref-type = 'fn'"/> -->
			<xsl:when test="@ref-type = 'other'">
				<xsl:text>&lt;</xsl:text><xsl:value-of select="."/><xsl:text>&gt;</xsl:text>
			</xsl:when>
			<xsl:when test="@ref-type = 'sec' and local-name(//*[@id = current()/@rid]) = 'term-sec'"> <!-- <xref ref-type="sec" rid="sec_3.21"> link to term clause -->
				<xsl:variable name="term_name" select="//*[@id = current()/@rid]//tbx:term[1]"/>
				
				<!-- <xsl:variable name="term_name" select="java:toLowerCase(java:java.lang.String.new(translate($term_name_, ' ', '-')_))"/>				 -->
				<!-- <xsl:text>&lt;&lt;</xsl:text>term-<xsl:value-of select="$term_name"/><xsl:text>&gt;&gt;</xsl:text> -->
				<!-- <xsl:text>term:[</xsl:text><xsl:value-of select="$term_name"/><xsl:text>]</xsl:text> -->
				<xsl:variable name="rendering"><xsl:apply-templates /></xsl:variable>
				
				<!-- Example: {{process,*3.21*,options="noref,noital,linkmention"}} -->
				<xsl:call-template name="insertTermReference">
					<xsl:with-param name="term" select="$term_name"/>
					<xsl:with-param name="rendering" select="$rendering"/>
					<xsl:with-param name="options" select="'noref,noital,linkmention'"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise> <!-- example: ref-type="sec" "table" "app" -->
				<xsl:text>&lt;&lt;</xsl:text><xsl:value-of select="$rid"/><xsl:text>&gt;&gt;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="sup[xref[@ref-type='fn' or @ref-type='table-fn']]">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="fn-group"/><!-- fn from fn-group  moved to after the text -->
	
	<!-- Multi-paragraph footnote -->
	<xsl:template match="fn[count(p) &gt; 1]" priority="2">
		<xsl:text> footnoteblock:[</xsl:text>
		<xsl:value-of select="@id"/>
		<xsl:text>]</xsl:text>
	</xsl:template>
	
	<xsl:template match="fn">
		<xsl:text> footnote:[</xsl:text>
			<xsl:apply-templates />
		<xsl:text>]</xsl:text>
	</xsl:template>
	
	<xsl:template match="fn/p">
		<xsl:if test="preceding-sibling::p"><xsl:text>&#xa;&#xa;</xsl:text></xsl:if> <!-- for multi-paragraph footnotes -->
		<xsl:apply-templates />
	</xsl:template>

	<!-- process as Note -->
	<!-- Example:
	<table-wrap-foot>
		<fn><p>NOTE   ...</p></fn>
	</table-wrap-foot>
	-->
	<xsl:template match="fn[not(@reference) and not(@id)]" priority="2">
		<xsl:call-template name="tbx_note"/>
	</xsl:template>

	<xsl:template match="fn[not(@reference) and not(@id)]/p/text()" priority="2">
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.), '^NOTE(\s|\h)+', '')"/>
	</xsl:template>
	
	<xsl:template name="insertMultiParagraphFootnote">
		<xsl:if test="count(p) &gt; 1">
			<xsl:text>[[</xsl:text><xsl:value-of select="@id"/><xsl:text>]]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>[NOTE]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>--</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:apply-templates />
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>--</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="uri">
		<xsl:choose>
			<xsl:when test="count(node()) = 1"><xsl:value-of select="."/></xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates />
				<xsl:text>[</xsl:text>
				<xsl:value-of select="."/>
				<xsl:text>]</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="mixed-citation">		
		<xsl:text> </xsl:text><xsl:apply-templates/>
	</xsl:template>
		
	<!-- =============== -->
	<!-- Definitions list (dl) -->
	<!-- =============== -->
	<xsl:template match="array">
		<xsl:text>&#xa;</xsl:text>
		<xsl:if test="ancestor::list-item and preceding-sibling::*[not(label)]">
			<xsl:text>+</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>--</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="count(table/col) + count(table/colgroup/col) = 2 and $organization != 'BSI' and $organization != 'PAS'">
				<xsl:if test="@content-type = 'figure-index' and label">*<xsl:value-of select="label"/>*&#xa;&#xa;</xsl:if>
				<xsl:apply-templates mode="dl"/>
			</xsl:when>
			<!-- description of math symbols marked up as definitions list -->
			<xsl:when test="count(table/col) + count(table/colgroup/col) = 2 and 
			(@content-type = 'fig-index' or @content-type = 'figure-index') and 
			preceding-sibling::*[1][starts-with(text(), 'where')] and
			preceding-sibling::*[2][self::disp-formula]">
				<xsl:apply-templates mode="dl"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates />
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="ancestor::list-item and preceding-sibling::*[not(label)]">
			<xsl:text>--</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<!-- description of math symbols marked up as definitions list -->
	<xsl:template match="table-wrap[@content-type = 'formula-index' and
									count(table/col) + count(table/colgroup/col) = 2 and
									preceding-sibling::*[1][starts-with(text(), 'where')] and
									preceding-sibling::*[2][self::disp-formula]]" priority="2">
		<xsl:apply-templates mode="dl"/>
	</xsl:template>
	
	<xsl:template match="@*|node()" mode="dl">		
		<xsl:apply-templates select="@*|node()" mode="dl"/>		
	</xsl:template>
	<xsl:template match="table" mode="dl">
		<xsl:apply-templates mode="dl"/>
	</xsl:template>	
	<xsl:template match="col" mode="dl"/>
	<xsl:template match="tbody" mode="dl">
		<xsl:apply-templates mode="dl"/>
	</xsl:template>
	
	<xsl:template match="tr" mode="dl">
		<xsl:variable name="td_1">
			<xsl:apply-templates select="td[1]" mode="dl"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="string-length($td_1) != 0">
				<xsl:apply-templates select="td[1]" mode="dl"/>
				<xsl:text>:: </xsl:text>		
				<!-- <xsl:text>&#xa;</xsl:text> -->
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>+</xsl:text>
				<xsl:text>&#xa; </xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:apply-templates select="td[2]" mode="dl"/>
		<xsl:text>&#xa;</xsl:text>
		
		<xsl:if test="count(following-sibling::tr[1]/td[1]//node()) &gt; 0 or position() = last()">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		<!-- count=<xsl:value-of select="count(following-sibling::tr/td[1]//node())"/> -->
		<!-- <xsl:if test="following-sibling::tr/td[1]/* != 0">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if> -->
	</xsl:template>
	
	<xsl:template match="td" mode="dl">
		<xsl:apply-templates />
	</xsl:template>

	<!-- =============== -->
	<!-- End Definitions list (dl) -->
	<!-- =============== -->
	
	<!-- =============== -->
	<!-- Table -->
	<!-- =============== -->
	<xsl:template match="table-wrap">
		<xsl:if test="preceding-sibling::node()[1][self::text()]"><xsl:text>&#xa;</xsl:text></xsl:if> <!-- if previous node is text, example: environment and requirements.<table-wrap id="tab_e" -->
		<xsl:apply-templates select="@orientation"/>
		<xsl:if test="not(@orientation)">
			<xsl:apply-templates select="table/@width" mode="orientation"/>
		</xsl:if>
		<xsl:call-template name="setId"/>
		<xsl:if test="not(label)">[%unnumbered]&#xa;</xsl:if>
		<xsl:apply-templates select="table-wrap-foot/fn-group" mode="footnotes"/>
		<xsl:apply-templates />
		
		<!-- insert Multi-paragraph footnotes after table -->
		<xsl:for-each select=".//xref[@ref-type='table-fn']">
			<xsl:for-each select="//fn[@id = current()/@rid]">
				<xsl:call-template name="insertMultiParagraphFootnote" />
			</xsl:for-each>
		</xsl:for-each>
		
		<xsl:apply-templates select="@orientation" mode="after_table"/>
		<xsl:if test="not(@orientation)">
			<xsl:apply-templates select="table/@width" mode="after_table"/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="table-wrap/@orientation">
		<xsl:call-template name="setPageOrientation">
			<xsl:with-param name="orientation" select="."/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="table/@width" mode="orientation">
		<xsl:if test=". &gt;= 700">
			<xsl:call-template name="setPageOrientation">
				<xsl:with-param name="orientation" select="'landscape'"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="table-wrap/@orientation" mode="after_table">
		<xsl:call-template name="setPageOrientation"/>
	</xsl:template>
	
	<xsl:template match="table/@width" mode="after_table">
		<xsl:if test=". &gt;= 700">
			<xsl:call-template name="setPageOrientation"/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="setPageOrientation">
		<xsl:param name="orientation">portrait</xsl:param>
		<xsl:text>&#xa;&#xa;</xsl:text>
		<xsl:text>[%</xsl:text><xsl:value-of select="$orientation"/><xsl:text>]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&lt;&lt;&lt;</xsl:text>
		<xsl:text>&#xa;&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="table-wrap/caption/title">
		<xsl:text>.</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>		
	</xsl:template>
	
	<xsl:template match="table">
		<xsl:if test="parent::array">
			<xsl:if test="parent::array/@id">
				<xsl:text>[[array_</xsl:text><xsl:value-of select="parent::array/@id"/><xsl:text>]]&#xa;</xsl:text>
			</xsl:if>
			<xsl:text>[%unnumbered]&#xa;</xsl:text>
		</xsl:if>
		
		<xsl:if test="(parent::array/@content-type = 'fig-index' or parent::array/@content-type = 'figure-index') and parent::array/label">
			<xsl:text>.</xsl:text>
			<xsl:value-of select="parent::array/label"/>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		
		<xsl:if test="parent::table-wrap and preceding-sibling::table"> <!-- if there are  few table inside table-wrap -->
			<xsl:variable name="id" select="parent::table-wrap/@id"/>
			<xsl:variable name="counter" select="count(preceding-sibling::table) + 1"/>
			<xsl:text>[[</xsl:text><xsl:value-of select="concat($id, '_', $counter)"/><xsl:text>]]</xsl:text>
			<xsl:text>&#xa;</xsl:text>		
		</xsl:if>
		
		<xsl:call-template name="insertTableProperties"/>
		
		<xsl:text>|===</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="tfoot" mode="footer"/>
		
		<xsl:variable name="cols-count">
			<xsl:choose>
				<xsl:when test="colgroup/col or col">
					<xsl:value-of select="count(colgroup/col) + count(col)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="simple-table">
						<xsl:call-template  name="getSimpleTable"/>
					</xsl:variable>
					<xsl:value-of select="count(xalan:nodeset($simple-table)//tr[1]/td)"/>				
				</xsl:otherwise>				
			</xsl:choose>
		</xsl:variable>
		
		<xsl:apply-templates select="../table-wrap-foot" mode="footer">
			<xsl:with-param name="cols-count" select="$cols-count"/>
		</xsl:apply-templates>
		<xsl:text>|===</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<!-- move notes outside table -->
		<xsl:apply-templates select="../table-wrap-foot/non-normative-note" />
		
	</xsl:template>
	
	<xsl:template match="table/@width" mode="table_header">
		<xsl:text>,width=</xsl:text><xsl:value-of select="."/>
		<xsl:if test="not(contains(., '%')) and not(contains(., 'px'))">px</xsl:if>
	</xsl:template>
  
	<xsl:template name="insertTableProperties">
		<xsl:text>[</xsl:text>
		<xsl:text>cols="</xsl:text>
		<xsl:variable name="cols-count">
			<xsl:choose>
				<xsl:when test="colgroup/col or col">
					<xsl:value-of select="count(colgroup/col) + count(col)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="simple-table">
						<xsl:call-template  name="getSimpleTable"/>
					</xsl:variable>
					<xsl:value-of select="count(xalan:nodeset($simple-table)//tr[1]/td)"/>				
				</xsl:otherwise>				
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$cols-count = 1">1</xsl:when> <!-- cols="1" -->
			<xsl:when test="colgroup/col or col">				
				<xsl:for-each select="colgroup/col | col">
					<xsl:variable name="width" select="translate(@width, '%cm', '')"/>
					<xsl:variable name="width_number" select="number($width)"/>
					<xsl:choose>
						<xsl:when test="normalize-space($width_number) != 'NaN'">
							<xsl:value-of select="round($width_number * 100)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$width"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:if test="position() != last()">,</xsl:if>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="cols">
					<xsl:call-template name="repeat">
						<xsl:with-param name="char" select="'1,'"/>
						<xsl:with-param name="count" select="$cols-count"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:value-of select="substring($cols,1,string-length($cols)-1)"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>"</xsl:text>
		
		<!-- <xsl:if test="thead">
			<xsl:text>,</xsl:text>
		</xsl:if> -->
		<xsl:variable name="options">
			<xsl:if test="thead">
				<option>header</option>
			</xsl:if>
			<xsl:if test="ancestor::table-wrap/table-wrap-foot[count(*[local-name() != 'fn-group' and local-name() != 'fn' and local-name() != 'non-normative-note']) != 0]">
				<option>footer</option>
			</xsl:if>
			<xsl:if test="ancestor::table-wrap/@content-type = 'ace-table' or 
					(ancestor::table-wrap and preceding-sibling::*[1][self::table]) or
					(parent::array/@content-type = 'fig-index' or parent::array/@content-type = 'figure-index')">
				<option>unnumbered</option>
			</xsl:if>
		</xsl:variable>
		<xsl:if test="count(xalan:nodeset($options)/option) != 0">
			<xsl:text>,</xsl:text>
			<xsl:text>options="</xsl:text>
				<xsl:for-each select="xalan:nodeset($options)/option">
					<xsl:value-of select="."/>
					<xsl:if test="position() != last()">,</xsl:if>
				</xsl:for-each>
			<xsl:text>"</xsl:text>
			<xsl:if test="count(thead/tr) &gt; 1">
				<xsl:text>,headerrows=</xsl:text>
				<xsl:value-of select="count(thead/tr)"/>
			</xsl:if>
		</xsl:if>
		<!-- <xsl:if test="thead">
			<xsl:text>options="header"</xsl:text>
		</xsl:if> -->
		<xsl:apply-templates select="@width" mode="table_header"/>
		<xsl:text>]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		
	</xsl:template>
	
	<xsl:template match="col"/>
	
	<xsl:template match="thead">
		<xsl:apply-templates />
		<!-- <xsl:text>&#xa;</xsl:text> -->
	</xsl:template>
	
	<xsl:template match="tfoot"/>
	<xsl:template match="tfoot" mode="footer">		
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="tbody">
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="tr">
		<!-- <xsl:if test="position() != 1">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if> -->
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="th">
		<xsl:call-template name="spanProcessing"/>
		<xsl:call-template name="alignmentProcessing"/>
		<xsl:call-template name="complexFormatProcessing"/>
		<xsl:text>|</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="td">
		<xsl:call-template name="spanProcessing"/>		
		<xsl:call-template name="alignmentProcessing"/>
		<xsl:call-template name="complexFormatProcessing"/>
		<xsl:text>|</xsl:text>
		<xsl:choose>
			<xsl:when test="position() = last() and normalize-space() = '' and not(*)"></xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates />
			</xsl:otherwise>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="position() = last() and ../following-sibling::tr">
				<xsl:text>&#xa;</xsl:text>
			</xsl:when>
			<xsl:when test="position() = last()">
				<xsl:text></xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text> </xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	<xsl:template name="spanProcessing">		
		<xsl:if test="@colspan &gt; 1 or @rowspan &gt; 1">
			<xsl:choose>
				<xsl:when test="@colspan &gt; 1 and @rowspan &gt; 1">
					<xsl:value-of select="@colspan"/><xsl:text>.</xsl:text><xsl:value-of select="@rowspan"/>
				</xsl:when>
				<xsl:when test="@colspan &gt; 1">
					<xsl:value-of select="@colspan"/>
				</xsl:when>
				<xsl:when test="@rowspan &gt; 1">
					<xsl:text>.</xsl:text><xsl:value-of select="@rowspan"/>
				</xsl:when>
			</xsl:choose>			
			<xsl:text>+</xsl:text>
		</xsl:if>
		<xsl:if test="list or def-list">a</xsl:if>
	</xsl:template>
	
	<xsl:template name="alignmentProcessing">
		<xsl:if test="(@align and @align != 'left') or (@valign and @valign != 'top')">
			
			<xsl:variable name="align">
				<xsl:call-template name="getAlignFormat"/>
			</xsl:variable>
			
			<xsl:variable name="valign">
				<xsl:call-template name="getVAlignFormat"/>
			</xsl:variable>
			
			<xsl:value-of select="$align"/>
			<xsl:value-of select="$valign"/>
			
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="complexFormatProcessing">
		<xsl:if test=".//graphic or .//inline-graphic">a</xsl:if> <!-- AsciiDoc prefix before table cell -->
	</xsl:template>
	
	<xsl:template name="getAlignFormat">
		<xsl:choose>
			<xsl:when test="@align = 'center'">^</xsl:when>
			<xsl:when test="@align = 'right'">&gt;</xsl:when>
			<!-- <xsl:otherwise>&lt;</xsl:otherwise> --><!-- left -->
		</xsl:choose>
	</xsl:template>
	<xsl:template name="getVAlignFormat">
		<xsl:choose>
			<xsl:when test="@valign = 'middle'">.^</xsl:when>
			<xsl:when test="@valign = 'bottom'">.&gt;</xsl:when>
			<!-- <xsl:otherwise>&lt;</xsl:otherwise> --> <!-- top -->
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="td/p | th/p">
		<xsl:if test="preceding-sibling::* or normalize-space(preceding-sibling::node()[1]) != ''">
			<xsl:text> +</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		<xsl:apply-templates/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="table-wrap-foot"/>
	
	<xsl:template match="table-wrap-foot" mode="footer">		
		<xsl:param name="cols-count"/>
		
		<xsl:variable name="table_footer">
			<xsl:apply-templates select="*[not(self::fn[@id] or self::non-normative-note)]"/> <!-- except fn[@id] and non-normative-note -->
		</xsl:variable>
		
		<xsl:if test="normalize-space($table_footer) != ''">
			<xsl:value-of select="$cols-count"/><xsl:text>+a|</xsl:text>		
			<xsl:value-of select="$table_footer"/>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="table-wrap-foot/fn[@id]" mode="footer"/>
	
	<xsl:template match="table-wrap-foot/fn-group"/>
	<xsl:template match="back/fn-group"/>
	
	<xsl:template match="fn-group" mode="footnotes">
		<xsl:apply-templates/>	
		<xsl:text>&#xa;</xsl:text>		
	</xsl:template>
	
	<!-- <xsl:template match="fn-group">
		<xsl:apply-templates/>	
		<xsl:text>&#xa;</xsl:text>		
	</xsl:template> -->
	
	<!-- <xsl:template match="fn-group/fn">
		<xsl:text>:</xsl:text>
		<xsl:value-of select="@id"/>
		<xsl:text>: footnote:[</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template> -->
	
	<xsl:template match="fn-group/fn/label"/>
	
	<xsl:template match="fn-group/fn/p">
		<xsl:if test="preceding-sibling::p"><xsl:text>&#xa;&#xa;</xsl:text></xsl:if> <!-- for multi-paragraph footnotes -->
		<xsl:apply-templates />
	</xsl:template>
	
	<!-- <xsl:template match="fn-group">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="fn-group/fn">
		<xsl:apply-templates />
		<xsl:if test="position() != last()">
			<xsl:text> +</xsl:text>
		</xsl:if>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="fn-group/fn/label">
		<xsl:value-of select="."/><xsl:text>| </xsl:text>
	</xsl:template>	
	 -->
	<!-- =============== -->
	<!-- END Table -->
	<!-- =============== -->
	
	<!-- ============================ -->
	<!-- Annex -->
	<!-- ============================ -->
	<xsl:template match="app">
		<xsl:variable name="annex_label_" select="translate(label, ' &#xa0;', '--')" />
		<xsl:variable name="annex_label" select="java:toLowerCase(java:java.lang.String.new($annex_label_))" />
		<xsl:variable name="sectionsFolder"><xsl:call-template name="getSectionsFolder"/></xsl:variable>
		<redirect:write file="{$outpath}/{$sectionsFolder}/{$annex_label}.adoc">
			<xsl:text>&#xa;</xsl:text>
			<xsl:call-template name="setId"/>
			<xsl:text>[appendix</xsl:text>
			<xsl:apply-templates select="annex-type" mode="annex"/>		
			<xsl:text>]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:apply-templates />
		</redirect:write>
		
		<xsl:choose>
			<xsl:when test="$demomode = 'true' and $one_document = 'false' and starts-with(@id, 'sec_Z')"/> <!-- include:: created in national doc -->
			<xsl:otherwise>
				<xsl:variable name="docfile"><xsl:call-template name="getDocFilename"/></xsl:variable>
				<redirect:write file="{$outpath}/{$docfile}">
					<xsl:text>include::</xsl:text><xsl:value-of select="$sectionsFolder"/><xsl:text>/</xsl:text><xsl:value-of select="$annex_label"/><xsl:text>.adoc[]</xsl:text>
					<xsl:text>&#xa;&#xa;</xsl:text>
				</redirect:write>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>
	
	<xsl:template match="app/annex-type"/>
	<xsl:template match="app/annex-type" mode="annex">
		<xsl:variable name="obligation" select="java:toLowerCase(java:java.lang.String.new(translate(., '()','')))"/>
		<xsl:choose>
			<xsl:when test="$obligation = 'normative'"></xsl:when><!-- default value in adoc -->
			<xsl:otherwise><xsl:text>,obligation=</xsl:text><xsl:value-of select="$obligation"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- ============================ -->
	<!-- END Annex -->
	<!-- ============================ -->
	
	<!-- ============================ -->
	<!-- References -->
	<!-- ============================ -->
	<xsl:template match="ref-list[@content-type = 'bibl']" priority="2">
		<xsl:variable name="sectionsFolder"><xsl:call-template name="getSectionsFolder"/></xsl:variable>
		<redirect:write file="{$outpath}/{$sectionsFolder}/99-bibliography.adoc">
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>[bibliography]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:apply-templates />
			
			<!-- ===================== -->
			<!-- insert hidden bibitem -->
			<!-- ===================== -->
			<xsl:variable name="hidden_bibitems">
				<xsl:for-each select="$updated_xml//std[not(parent::ref)][@stdid != '']">
					<xsl:variable name="reference">
						<xsl:call-template name="getReference">
							<xsl:with-param name="stdid" select="@stdid"/>
						</xsl:call-template>
					</xsl:variable>
					<!-- reference=<xsl:value-of select="$reference"/><xsl:text>&#xa;</xsl:text> -->
					<xsl:if test="normalize-space($reference) = ''">
						<item id="{@stdid}">
							<xsl:text>* [[[hidden_bibitem_</xsl:text>
							<xsl:value-of select="@stdid"/>
							<xsl:text>,</xsl:text><xsl:value-of select=".//std-ref/text()"/>
							<xsl:text>]]]</xsl:text>
						</item>
					</xsl:if>
				</xsl:for-each>
			</xsl:variable>
			<xsl:for-each select="xalan:nodeset($hidden_bibitems)//item">
				<xsl:if test="not(preceding-sibling::item[@id = current()/@id])"> <!-- unique bibitems -->
					<xsl:value-of select="."/>
					<xsl:text>&#xa;</xsl:text>
					<xsl:text>&#xa;</xsl:text>
				</xsl:if>
			</xsl:for-each>
			<!-- ===================== -->
			<!-- END insert hidden bibitem -->
			<!-- ===================== -->
			
		</redirect:write>
		<xsl:variable name="docfile"><xsl:call-template name="getDocFilename"/></xsl:variable>
		<redirect:write file="{$outpath}/{$docfile}">
			<xsl:text>include::</xsl:text><xsl:value-of select="$sectionsFolder"/><xsl:text>/99-bibliography.adoc[]</xsl:text>
			<xsl:text>&#xa;&#xa;</xsl:text>
		</redirect:write>
	</xsl:template>
	
	<!-- ignore p in Bibliography with text start with 'For dated references, only the edition cited applies'-->
	<!-- This boilerplate text will be added by metanorma -->
	<xsl:template match="ref-list[@content-type = 'bibl']//p[starts-with(normalize-space(), 'For dated references, only the edition cited applies')]" priority="2"/>
	<xsl:template match="ref-list[@content-type = 'bibl']//title[starts-with(normalize-space(), 'For dated references, only the edition cited applies')]" priority="2"/>
	
	<xsl:template match="ref-list"> <!-- sub-section for Bibliography -->
		<!-- <xsl:if test="@content-type = 'bibl' or parent::ref-list/@content-type = 'bibl'"> -->
		<xsl:if test="title">
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>[bibliography]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<!-- <xsl:text>[%unnumbered]</xsl:text>
			<xsl:text>&#xa;</xsl:text> -->
		</xsl:if>
		
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="ref-list/title/bold | ref-list/title/bold2">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="ref">
		<xsl:variable name="unique"><!-- skip repeating references -->
			<xsl:choose>
				<xsl:when test="@id and preceding-sibling::ref[@id = current()/@id]">false</xsl:when>
				<xsl:when test="std/@std-id and preceding-sibling::ref[std/@std-id = current()/std/@std-id]">false</xsl:when>
				<xsl:when test="std/std-ref and preceding-sibling::ref[std/std-ref = current()/std/std-ref]">false</xsl:when>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="reference">
			
			<xsl:if test="@id or std/@std-id or std/std-ref">
				<xsl:text>[[[</xsl:text>
				<xsl:value-of select="@id"/>
				<xsl:if test="not(@id)">
					<xsl:variable name="id_normalized">
						<xsl:call-template name="getNormalizedId">
							<xsl:with-param name="id" select="std/@std-id"/>
						</xsl:call-template>
					</xsl:variable>
					<xsl:value-of select="$id_normalized"/>
					
					<xsl:if test="normalize-space($id_normalized) = ''">
						
						<xsl:variable name="std_ref">
							<xsl:call-template name="getNormalizedId">
								<xsl:with-param name="id" select="std/std-ref"/>
							</xsl:call-template>
						</xsl:variable>
						
						<xsl:value-of select="$std_ref"/>
					</xsl:if>
				</xsl:if>
				
				<xsl:variable name="referenceTitle">
				
					<xsl:variable name="std-ref">
						<xsl:variable name="std-ref_">
							<xsl:apply-templates select="std/std-ref" mode="references"/>
						</xsl:variable>
						<!-- https://github.com/metanorma/mnconvert/issues/40 -->
						<!-- <xsl:if test="starts-with($std-ref_, 'EN ')">BS </xsl:if> -->
						<xsl:value-of select="$std-ref_"/>
					</xsl:variable>
					
					<xsl:variable name="mixed-citation">
						<xsl:apply-templates select="mixed-citation/std" mode="references"/>
					</xsl:variable>
					<xsl:variable name="label">
						<xsl:apply-templates select="label" mode="references"/>
					</xsl:variable>
					
					<xsl:if test="(normalize-space($std-ref) != '' or normalize-space($mixed-citation) != '') and normalize-space($label) != ''">
						<xsl:text>(</xsl:text>
					</xsl:if>
					<xsl:value-of select="$label"/>
					<xsl:if test="(normalize-space($std-ref) != '' or normalize-space($mixed-citation) != '') and normalize-space($label) != ''">
						<xsl:text>)</xsl:text>
					</xsl:if>
					<xsl:value-of select="$std-ref"/>
					<xsl:value-of select="$mixed-citation"/>
					
				</xsl:variable>
				
				<xsl:if test="$referenceTitle != ''">
					<xsl:text>,</xsl:text>
					<xsl:value-of select="translate($referenceTitle, '&#x2011;', '-')"/> <!-- non-breaking hyphen minus -->
				</xsl:if>
				
				<xsl:text>]]]</xsl:text>
			</xsl:if>
			
			<!-- Bibliography items without id -->
			<!-- Example: Further Reading -->
			<xsl:if test="not(@id or std/@std-id or std/std-ref)">
				<xsl:variable name="preceding_title" select="java:toLowerCase(java:java.lang.String.new(translate(preceding-sibling::title[1]/text(), ' ', '_')))"/>
				<xsl:if test="normalize-space($preceding_title) != ''">
					<xsl:text>[[[</xsl:text>
					<xsl:value-of select="$preceding_title"/>_<xsl:number/>
					<xsl:text>]]]</xsl:text>
				</xsl:if>
			</xsl:if>
			
			<xsl:apply-templates/>
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:variable>
		<xsl:if test="normalize-space($reference) != ''">
			<!-- comment repeated references -->
			<xsl:if test="normalize-space($unique) = 'false'">// </xsl:if>
			<xsl:text>* </xsl:text>
			<xsl:value-of select="$reference"/>
		</xsl:if>
		
		<xsl:if test="normalize-space($unique) = 'false'">
			<xsl:message>WARNING: Repeated reference - <xsl:copy-of select="."/></xsl:message>
		</xsl:if>
		
		<xsl:variable name="std-ref">
			<xsl:variable name="std-ref_">
				<xsl:apply-templates select="std/std-ref" mode="references"/>
			</xsl:variable>
			<xsl:value-of select="translate($std-ref_, '&#x2011;', '-')"/>
		</xsl:variable>
		<xsl:if test="count($refs/ref[normalize-space(@referenceText) != '' and @referenceText = normalize-space($std-ref)]) &gt; 1">
			<xsl:message>WARNING: Repeated reference - <xsl:copy-of select="."/></xsl:message>
		</xsl:if>
		
	</xsl:template>
	
	<xsl:template match="ref/std">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="ref/label" mode="references">
		<!-- <xsl:text>, </xsl:text> -->
		<xsl:variable name="label" select="translate(., '[]', '')"/>
		<xsl:choose>
			<xsl:when test="$label = '—'"></xsl:when>
			<xsl:otherwise><xsl:value-of select="$label"/></xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	<xsl:template match="ref/std/std-ref"/>
	<xsl:template match="ref/std/std-ref" mode="references">
		<!-- <xsl:text>,</xsl:text> -->
		<xsl:apply-templates mode="references"/>
	</xsl:template>
	<xsl:template match="ref/std/std-ref/text()" mode="references">
		<xsl:variable name="text" select="translate(translate(.,'[]',''), '&#xA0;', ' ')"/>
		<!-- <xsl:variable name="isDated">
			<xsl:choose>
				<xsl:when test="string-length($text) - string-length(translate($text, ':', '')) = 1">true</xsl:when>
				<xsl:otherwise>false</xsl:otherwise>
			</xsl:choose>
		</xsl:variable> -->
		<xsl:value-of select="$text"/>
		<!-- <xsl:text>(</xsl:text>
		<xsl:choose>
			<xsl:when test="$isDated = 'true'">
				<xsl:value-of select="substring-before($text, ':')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$text"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>)</xsl:text> <xsl:value-of select="$text"/> -->
	</xsl:template>
	
	<xsl:template match="ref/mixed-citation/std"/>
	<xsl:template match="ref/mixed-citation/std" mode="references">
		<!-- <xsl:text>,</xsl:text> -->
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="ref/std//title">
		<xsl:text>_</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>_</xsl:text>
	</xsl:template>
	
	<xsl:template match="ref/std//title/text()">
		<xsl:value-of select="translate(., '&#xA0;', ' ')"/>
	</xsl:template>
	<!-- ============================ -->
	<!-- References -->
	<!-- ============================ -->
	
	
	
	<!-- ============================ -->
	<!-- Figure -->
	<!-- ============================ -->
	<!-- in STS XML there are two figure's group structure: fig-group/fig* and fig/graphic[title]* (in BSI documents) -->
	<xsl:template match="fig-group | fig[graphic[caption]] | fig[count(graphic) &gt;= 2]">
		<xsl:call-template name="setId"/>
		<xsl:apply-templates select="caption/title" mode="fig-group-title"/>
		<xsl:text>====</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<!-- <xsl:apply-templates/> -->
		<xsl:apply-templates select="*[not(self::array or self::non-normative-note)]"/>
		<xsl:text>====</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="*[self::array or self::non-normative-note]"/>
	</xsl:template>
	
	<xsl:template match="fig[graphic[caption] or count(graphic) &gt;= 2]/caption/title" priority="2"/>
	<xsl:template match="fig-group/caption/title"/>
	<xsl:template match="fig-group/caption/title | fig/caption/title" mode="fig-group-title">
		<xsl:text>.</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="fig">
		<xsl:if test="not(parent::fig-group)">
			<xsl:if test="parent::tbx:note"><xsl:text> +&#xa;</xsl:text></xsl:if>
			<xsl:call-template name="setId"/>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="not(graphic) and array"> <!-- Case for https://github.com/metanorma/mnconvert/issues/87 -->
				<xsl:apply-templates select="*[not(self::array)]"/>
				<xsl:apply-templates select="array" mode="fig_array"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:if test="(parent::fig-group and position() != last()) or not(parent::fig-group)">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="fig/label" priority="2">
		<xsl:variable name="number" select="normalize-space(substring-after(., '&#xa0;'))"/>
		<xsl:if test="substring($number, 1, 1) = '0'"> <!-- example: Figure 0.1 -->
			<xsl:text>[number=</xsl:text><xsl:value-of select="$number"/><xsl:text>]&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="fig/caption/title">
		<xsl:text>.</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	
	<xsl:template match="graphic | inline-graphic" name="graphic">
		<xsl:apply-templates select="caption/title" mode="graphic-title"/>
		<xsl:if test="not(caption/title) and not(ancestor::fig) and not(ancestor::table)">
			<xsl:text>[%unnumbered]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		<xsl:text>image::</xsl:text>
		<xsl:if test="not(processing-instruction('isoimg-id'))">
			<xsl:variable name="image_link" select="@xlink:href"/>
			<xsl:value-of select="$image_link"/>
			<xsl:choose>
				<xsl:when test="contains($image_link, 'base64,')"/>
				<xsl:when test="not(contains($image_link, '.png')) and not(contains($image_link, '.jpg')) and not(contains($image_link, '.bmp'))">
					<xsl:text>.png</xsl:text>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
		<xsl:apply-templates select="processing-instruction('isoimg-id')" mode="pi_isoimg-id"/>
		<xsl:apply-templates />
		<xsl:if test="not(alt-text)">[]</xsl:if>
		<xsl:text>&#xa;</xsl:text>
		<xsl:if test="following-sibling::node()">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="graphic/caption" />
	<xsl:template match="graphic/caption/title" mode="graphic-title">
		<xsl:text>.</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="graphic/processing-instruction('isoimg-id')" />
	<xsl:template match="graphic/processing-instruction('isoimg-id')" mode="pi_isoimg-id">
		<xsl:variable name="image_link" select="."/>
		<xsl:choose>
			<xsl:when test="contains($image_link, '.eps')">
				<xsl:value-of select="substring-before($image_link, '.eps')"/><xsl:text>.png</xsl:text>
			</xsl:when>
			<xsl:when test="contains($image_link, '.EPS')">
				<xsl:value-of select="substring-before($image_link, '.EPS')"/><xsl:text>.png</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$image_link"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>	

	<xsl:template match="alt-text">
		<xsl:text>[</xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>]</xsl:text>
	</xsl:template>
	
	<xsl:template match="fig/array[count(table/col) + count(table/colgroup/col) = 1 and .//graphic]" priority="2">
		<xsl:apply-templates mode="ignore_array"/>
	</xsl:template>
	
	<xsl:template match="@*|node()" mode="ignore_array">
		<xsl:apply-templates select="@*|node()" mode="ignore_array"/>
	</xsl:template>
	
	<xsl:template match="td|th" mode="ignore_array">
		<xsl:variable name="text">
			<xsl:apply-templates/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="contains($text, 'image::')"><xsl:value-of select="$text"/></xsl:when>
			<xsl:otherwise>
				<xsl:if test="java:replaceAll(java:java.lang.String.new($text),'(\s|\h)','') != ''">
					<xsl:value-of select="$text"/>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template match="fig/array" mode="fig_array" priority="2">
		<xsl:variable name="MAX_ROW">99999</xsl:variable>
		<!-- table row number with 'Key' -->
		<xsl:variable name="row_key_" select="count(.//tr[normalize-space(td) = 'Key']/preceding-sibling::tr)" />
		<xsl:variable name="row_key">
			<xsl:choose>
				<xsl:when test="$row_key_ = '0'"><xsl:value-of select="$MAX_ROW"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="$row_key_ + 1"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- <xsl:text>row_key=</xsl:text><xsl:value-of select="$row_key"/><xsl:text>&#xa;</xsl:text> -->
		
		<xsl:variable name="images">
			<xsl:for-each select=".//tr[position() &lt; $row_key]">
				<xsl:if test=".//graphic">
					<xsl:if test="not(following-sibling::tr[1]//graphic) and position() != last() and not(following-sibling::tr[1]//non-normative-note)">
						<xsl:text>.</xsl:text><xsl:apply-templates select="following-sibling::tr[1]" mode="fig_array"/>
					</xsl:if>
					<xsl:apply-templates select="." mode="fig_array"/>
				</xsl:if>
				<xsl:if test=".//non-normative-note">
					<xsl:apply-templates mode="fig_array"/>
				</xsl:if>
				<!-- <xsl:text>&#xa;</xsl:text> -->
			</xsl:for-each>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="starts-with($images, '.')"> <!-- there is image's title -->
				<xsl:text>====</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:value-of select="$images"/>
				<xsl:text>====</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>&#xa;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$images"/>
			</xsl:otherwise>
		</xsl:choose>
		
		
		<xsl:if test="$row_key != $MAX_ROW"> <!-- if there is table with 'Key' -->
			<!-- <xsl:text>&#xa;</xsl:text> -->
			<xsl:if test="@id">
				<xsl:text>[[array_</xsl:text><xsl:value-of select="@id"/><xsl:text>]]&#xa;</xsl:text>
			</xsl:if>
			<xsl:text>[%unnumbered]&#xa;</xsl:text>
			<xsl:for-each select="table"> <!-- change context to 'table' -->
				<xsl:call-template name="insertTableProperties"/>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>|===</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:for-each select=".//tr[position() &gt;= $row_key]">
					<xsl:apply-templates select="."/>
				</xsl:for-each>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>|===</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>&#xa;</xsl:text>
			</xsl:for-each>
		</xsl:if>
		
	</xsl:template>
	
	<xsl:template match="tr" mode="fig_array" priority="2">
		<xsl:apply-templates mode="fig_array"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="td" mode="fig_array" priority="2">
		<xsl:apply-templates mode="fig_array"/>
	</xsl:template>
	
	<xsl:template match="*" mode="fig_array">
		<xsl:apply-templates select="."/>
	</xsl:template>
	
	<xsl:template match="td/text()[1]" mode="fig_array">
		<!-- Example: 'a) Common fire relay' to 'Common fire relay' -->
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),$regexListItemLabel, '$6')"/> <!-- get last group from regexListItemLabel, i.e. list item text without label-->
	</xsl:template>
	
	<!-- ============================ -->
	<!-- END Figure -->
	<!-- ============================ -->


	<xsl:template match="object-id">
		<xsl:choose>
			<xsl:when test="@pub-id-type = 'publisher-id'">
				<xsl:text>[</xsl:text>
					<xsl:apply-templates />
				<xsl:text>]</xsl:text>
			</xsl:when>
			<xsl:otherwise></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="disp-quote">
		<xsl:text>[quote, </xsl:text><xsl:value-of select="related-object"/><xsl:text>]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>_____</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>_____</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="disp-quote/p">
		<xsl:apply-templates />		
	</xsl:template>
	
	<xsl:template match="disp-quote/related-object"/>
		
	<xsl:template match="code | preformat">
		<xsl:text>[source</xsl:text>
		<xsl:text>%unnumbered</xsl:text> <!-- otherwise source block gets numbered as a figure -->
		<xsl:if test="@language">,<xsl:value-of select="@language"/></xsl:if>
		<xsl:text>]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>--</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>--</xsl:text>
		<xsl:text>&#xa;</xsl:text>		
		<xsl:if test="not(following-sibling::*)"><xsl:text>&#xa;</xsl:text></xsl:if>
	</xsl:template>
	
	<xsl:template match="element-citation">
		<xsl:text>&#xa;</xsl:text>		
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="annotation">
		<xsl:variable name="id" select="@id"/>
		<xsl:variable name="num" select="//*[@rid = $id]/text()"/>
		<xsl:text>&lt;</xsl:text><xsl:value-of select="$num"/><xsl:text>&gt; </xsl:text>
		<xsl:apply-templates />
	</xsl:template>
	<xsl:template match="annotation/p">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="inline-formula">		
		<xsl:text>stem:[</xsl:text>
		<xsl:variable name="math"><xsl:apply-templates /></xsl:variable>
		<!-- <xsl:variable name="math01" select="java:replaceAll(java:java.lang.String.new($math),'\]','\]')"/> -->
		<xsl:value-of select="$math"/>
		<xsl:text>]</xsl:text>		
	</xsl:template>
	
	<xsl:template match="disp-formula">
		<!-- <xsl:text>stem:[</xsl:text> -->
		<xsl:text>[stem]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>++++</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:variable name="math"><xsl:apply-templates /></xsl:variable>
		<!-- <xsl:variable name="math01" select="java:replaceAll(java:java.lang.String.new($math),']','\\]')"/> -->
		<xsl:value-of select="$math"/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>++++</xsl:text>
		<!-- <xsl:text>]</xsl:text> -->
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<!-- MathML -->
	<!-- https://www.metanorma.com/blog/2019-05-29-latex-math-stem/ -->
	<xsl:template match="mml:*">
		<!-- <xsl:text>a+b</xsl:text> -->
		<xsl:text>&lt;</xsl:text>
		<xsl:value-of select="local-name()"/>
		<xsl:if test="local-name() = 'math'">
			<xsl:text> xmlns="http://www.w3.org/1998/Math/MathML"</xsl:text>
		</xsl:if>
		<xsl:for-each select="@*">
			<xsl:text> </xsl:text>
			<xsl:value-of select="local-name()"/>
			<xsl:text>="</xsl:text>
			<xsl:value-of select="."/>
			<xsl:text>"</xsl:text>
		</xsl:for-each>
		<xsl:text>&gt;</xsl:text>		
		<xsl:apply-templates />		
		<xsl:text>&lt;/</xsl:text>
		<xsl:value-of select="local-name()"/>
		<xsl:text>&gt;</xsl:text>
	</xsl:template>
	
	<!-- =============== -->
	<!-- Definitions list (dl) -->
	<!-- =============== -->
	<xsl:template match="def-list">
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="def-list/title">
		<xsl:text>*</xsl:text><xsl:apply-templates /><xsl:text>*</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="def-item">
		<xsl:call-template name="setId">
			<xsl:with-param name="newline">false</xsl:with-param>
		</xsl:call-template>
		<xsl:apply-templates />		
	</xsl:template>
	
	<xsl:template match="def-item/term">
		<xsl:apply-templates/>
		<xsl:if test="count(node()) = 0"><xsl:text> </xsl:text></xsl:if>
		<xsl:text>:: </xsl:text>
		<!-- <xsl:text>&#xa;</xsl:text> -->
	</xsl:template>
	
	<xsl:template match="def-item/def">
		<xsl:apply-templates/>
	</xsl:template>
	<!-- =============== -->
	<!-- End Definitions list (dl) -->
	<!-- =============== -->
	
	<xsl:template match="named-content[@content-type = 'ace-tag'][contains(@specific-use, '_start') or contains(@specific-use, '_end')]" priority="2"><!-- start/end tag for corrections -->
	
		<xsl:variable name="space_before"><xsl:if test="local-name(preceding-sibling::node()[1]) != ''"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		<xsl:variable name="space_after"><xsl:if test="local-name(following-sibling::node()[1]) != ''"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		<xsl:value-of select="$space_before"/>
		<!--Example: add:[ace-tag_label_C1_start] -->
		<!-- <xsl:text>add:[</xsl:text><xsl:value-of select="@content-type"/><xsl:text>_label_</xsl:text><xsl:value-of select="@specific-use"/><xsl:text>]</xsl:text> -->
		<xsl:text>add:[]</xsl:text>
		<xsl:value-of select="$space_after"/>
	</xsl:template>
	
	<xsl:template match="named-content[@content-type = 'abbrev']" priority="2">
		<xsl:variable name="space_before"><xsl:if test="local-name(preceding-sibling::node()[1]) != ''"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		<xsl:variable name="space_after"><xsl:if test="local-name(following-sibling::node()[1]) != ''"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		<xsl:value-of select="$space_before"/>
		
		<xsl:variable name="target">
			<xsl:choose>
				<xsl:when test="translate(@xlink:href, '#', '') = ''"> <!-- empty xlink:href -->
					<xsl:value-of select="translate(normalize-space(), ' ()', '---')"/>
				</xsl:when>
				<xsl:when test="starts-with(@xlink:href, '#')">
					<xsl:value-of select="substring-after(@xlink:href, '#')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="@xlink:href"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:text>&lt;&lt;</xsl:text>
		<xsl:value-of select="$target"/>
		<xsl:if test="normalize-space() != ''">
			<xsl:text>,</xsl:text><xsl:apply-templates/>
		</xsl:if>
		<xsl:text>&gt;&gt;</xsl:text>
		
		<xsl:value-of select="$space_after"/>
	</xsl:template>
	
	<!-- reference to the term -->
	<xsl:template match="named-content">

		<xsl:variable name="space_before"><xsl:if test="local-name(preceding-sibling::node()[1]) != ''"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		<xsl:variable name="space_after"><xsl:if test="local-name(following-sibling::node()[1]) != ''"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		<xsl:value-of select="$space_before"/>
		
		<xsl:variable name="target">
			<xsl:choose>
				<xsl:when test="translate(@xlink:href, '#', '') = ''"> <!-- empty xlink:href -->
					<xsl:value-of select="translate(normalize-space(), ' ()', '---')"/>
				</xsl:when>
				<xsl:when test="starts-with(@xlink:href, '#')">
					<xsl:value-of select="substring-after(@xlink:href, '#')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="@xlink:href"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="@content-type = 'term' and (local-name(//*[@id = $target]) = 'term-sec' or local-name(//*[@id = $target]) = 'termEntry')">
				<xsl:variable name="term_real" select="//*[@id = $target]//tbx:term[1]"/>
				<!-- <xsl:variable name="term_name" select="java:toLowerCase(java:java.lang.String.new(translate($term_name_, ' ', '-')))"/> -->
				<!-- <xsl:text>term-</xsl:text><xsl:value-of select="$term_name"/>,<xsl:value-of select="."/> -->
				
				<xsl:variable name="value" select="."/>
				
				<xsl:call-template name="insertTermReference">
					<xsl:with-param name="term" select="$term_real"/>
					<xsl:with-param name="rendering" select="$value"/>
				</xsl:call-template>
				
			</xsl:when>
			<xsl:otherwise>
				
				<xsl:variable name="value">
					<xsl:apply-templates/>
				</xsl:variable>
				
				<xsl:call-template name="insertTermReference">
					<xsl:with-param name="term" select="$target"/>
					<xsl:with-param name="rendering" select="$value"/>
				</xsl:call-template>
				
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:value-of select="$space_after"/>
	</xsl:template>
	
	<xsl:template name="split">
		<xsl:param name="pText" select="."/>
		<xsl:param name="sep" select="'/'"/>
		<xsl:if test="string-length($pText) &gt; 0">
			<item>
				<xsl:variable name="value" select="substring-before(concat($pText, $sep), $sep)"/>
				<xsl:value-of select="normalize-space(translate($value, '&#xA0;', ' '))"/>
			</item>
			<xsl:call-template name="split">
				<xsl:with-param name="pText" select="substring-after($pText, $sep)"/>
				<xsl:with-param name="sep" select="$sep"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="getLevel">
		<xsl:param name="addon">0</xsl:param>
		<xsl:param name="calculated_level">0</xsl:param>
		
		<xsl:variable name="level_total" select="count(ancestor::*)"/>
		
		<xsl:variable name="level_standard" select="count(ancestor::standard/ancestor::*)"/>
		
		<xsl:variable name="label" select="normalize-space(preceding-sibling::*[1][self::label])"/>
		
		<xsl:variable name="level_">
			<xsl:choose>
				<xsl:when test="$calculated_level != 0">
					<xsl:value-of select="$calculated_level"/>
				</xsl:when>
				<xsl:when test="$label != ''">
					<!-- level from the element 'label' - count '.' -->
					<xsl:call-template name="getLevelFromLabel">
						<xsl:with-param name="label" select="$label"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="ancestor::app-group">
					<xsl:value-of select="$level_total - $level_standard - 2"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$level_total - $level_standard - 1"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="level_max" select="5"/>
		<xsl:variable name="level">
			<xsl:choose>
				<xsl:when test="$level_ &lt;= $level_max">
					<xsl:value-of select="$level_"/>
				</xsl:when>
				<xsl:otherwise><xsl:value-of select="$level_max"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$level_ &gt; $level_max">
			<xsl:text>[level=</xsl:text>
			<xsl:value-of select="$level_"/>
			<xsl:text>]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		<xsl:call-template name="repeat">
			<xsl:with-param name="count" select="$level + $addon"/>
		</xsl:call-template>
		
	</xsl:template>
	
	<!-- level from the element 'label' - count '.' -->
	<xsl:template name="getLevelFromLabel">
		<xsl:param name="label" select="label"/>
		<xsl:value-of  select="string-length($label) - string-length(translate($label, '.', '')) + 2"/>
	</xsl:template>
	
	<xsl:template name="getLevelListItem">
		<xsl:param name="list-label" select="'*'"/>
		<xsl:variable name="level" select="count(ancestor-or-self::list)"/>		
		<xsl:call-template name="repeat">
			<xsl:with-param name="char" select="$list-label"/>
			<xsl:with-param name="count" select="$level"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template name="repeat">
		<xsl:param name="char" select="'='"/>
		<xsl:param name="count" />
		<xsl:if test="$count &gt; 0">
			<xsl:value-of select="$char" />
				<xsl:call-template name="repeat">
					<xsl:with-param name="char" select="$char" />
					<xsl:with-param name="count" select="$count - 1" />
				</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
	
		<!-- Table normalization (colspan,rowspan processing for adding TDs) for column width calculation -->
	<xsl:template name="getSimpleTable">
		<xsl:variable name="simple-table">
		
			<!-- Step 1. colspan processing -->
			<xsl:variable name="simple-table-colspan">
				<tbody>
					<xsl:apply-templates mode="simple-table-colspan"/>
				</tbody>
			</xsl:variable>
			
			<!-- Step 2. rowspan processing -->
			<xsl:variable name="simple-table-rowspan">
				<xsl:apply-templates select="xalan:nodeset($simple-table-colspan)" mode="simple-table-rowspan"/>
			</xsl:variable>
			
			<xsl:copy-of select="xalan:nodeset($simple-table-rowspan)"/>
					
			<!-- <xsl:choose>
				<xsl:when test="current()//*[local-name()='th'][@colspan] or current()//*[local-name()='td'][@colspan] ">
					
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="current()"/>
				</xsl:otherwise>
			</xsl:choose> -->
		</xsl:variable>
		<xsl:copy-of select="$simple-table"/>
	</xsl:template>
		
	<!-- ===================== -->
	<!-- 1. mode "simple-table-colspan" 
			1.1. remove thead, tbody, fn
			1.2. rename th -> td
			1.3. repeating N td with colspan=N
			1.4. remove namespace
			1.5. remove @colspan attribute
			1.6. add @divide attribute for divide text width in further processing 
	-->
	<!-- ===================== -->	
	<xsl:template match="*[local-name()='thead'] | *[local-name()='tbody']" mode="simple-table-colspan">
		<xsl:apply-templates mode="simple-table-colspan"/>
	</xsl:template>
	<xsl:template match="*[local-name()='fn']" mode="simple-table-colspan"/>
	
	<xsl:template match="*[local-name()='th'] | *[local-name()='td']" mode="simple-table-colspan">
		<xsl:choose>
			<xsl:when test="@colspan">
				<xsl:variable name="td">
					<xsl:element name="td">
						<xsl:attribute name="divide"><xsl:value-of select="@colspan"/></xsl:attribute>
						<xsl:apply-templates select="@*" mode="simple-table-colspan"/>
						<xsl:apply-templates mode="simple-table-colspan"/>
					</xsl:element>
				</xsl:variable>
				<xsl:call-template name="repeatNode">
					<xsl:with-param name="count" select="@colspan"/>
					<xsl:with-param name="node" select="$td"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="td">
					<xsl:apply-templates select="@*" mode="simple-table-colspan"/>
					<xsl:apply-templates mode="simple-table-colspan"/>
				</xsl:element>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="@colspan" mode="simple-table-colspan"/>
	
	<xsl:template match="*[local-name()='tr']" mode="simple-table-colspan">
		<xsl:element name="tr">
			<xsl:apply-templates select="@*" mode="simple-table-colspan"/>
			<xsl:apply-templates mode="simple-table-colspan"/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="@*|node()" mode="simple-table-colspan">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="simple-table-colspan"/>
		</xsl:copy>
	</xsl:template>
	
	<!-- repeat node 'count' times -->
	<xsl:template name="repeatNode">
		<xsl:param name="count"/>
		<xsl:param name="node"/>
		
		<xsl:if test="$count &gt; 0">
			<xsl:call-template name="repeatNode">
				<xsl:with-param name="count" select="$count - 1"/>
				<xsl:with-param name="node" select="$node"/>
			</xsl:call-template>
			<xsl:copy-of select="$node"/>
		</xsl:if>
	</xsl:template>
	<!-- End mode simple-table-colspan  -->
	<!-- ===================== -->
	<!-- ===================== -->
	
	<!-- ===================== -->
	<!-- 2. mode "simple-table-rowspan" 
	Row span processing, more information http://andrewjwelch.com/code/xslt/table/table-normalization.html	-->
	<!-- ===================== -->		
	<xsl:template match="@*|node()" mode="simple-table-rowspan">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="simple-table-rowspan"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="tbody" mode="simple-table-rowspan">
		<xsl:copy>
				<xsl:copy-of select="tr[1]" />
				<xsl:apply-templates select="tr[2]" mode="simple-table-rowspan">
						<xsl:with-param name="previousRow" select="tr[1]" />
				</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="tr" mode="simple-table-rowspan">
		<xsl:param name="previousRow"/>
		<xsl:variable name="currentRow" select="." />
	
		<xsl:variable name="normalizedTDs">
				<xsl:for-each select="xalan:nodeset($previousRow)//td">
						<xsl:choose>
								<xsl:when test="@rowspan &gt; 1">
										<xsl:copy>
												<xsl:attribute name="rowspan">
														<xsl:value-of select="@rowspan - 1" />
												</xsl:attribute>
												<xsl:copy-of select="@*[not(name() = 'rowspan')]" />
												<xsl:copy-of select="node()" />
										</xsl:copy>
								</xsl:when>
								<xsl:otherwise>
										<xsl:copy-of select="$currentRow/td[1 + count(current()/preceding-sibling::td[not(@rowspan) or (@rowspan = 1)])]" />
								</xsl:otherwise>
						</xsl:choose>
				</xsl:for-each>
		</xsl:variable>

		<xsl:variable name="newRow">
				<xsl:copy>
						<xsl:copy-of select="$currentRow/@*" />
						<xsl:copy-of select="xalan:nodeset($normalizedTDs)" />
				</xsl:copy>
		</xsl:variable>
		<xsl:copy-of select="$newRow" />

		<xsl:apply-templates select="following-sibling::tr[1]" mode="simple-table-rowspan">
				<xsl:with-param name="previousRow" select="$newRow" />
		</xsl:apply-templates>
	</xsl:template>
	<!-- End mode simple-table-rowspan  -->
	<!-- ===================== -->	
	<!-- ===================== -->	
	
	<xsl:template name="getStdRef">
		<xsl:param name="text" select="."/>
		<!-- <xsl:variable name="std-ref" select="java:replaceAll(java:java.lang.String.new($text),'- -','—')"/> -->
		<xsl:variable name="std-ref">
			<xsl:call-template name="getNormalizedId">
				<xsl:with-param name="id" select="$text"/>
			</xsl:call-template>
		</xsl:variable>
		
		<!-- refs=<xsl:for-each select="xalan:nodeset($refs)//ref">
			stdid_option=<xsl:value-of select="@stdid_option"/><xsl:text>&#xa;</xsl:text>
		</xsl:for-each> -->
		
		<!-- std-ref=<xsl:value-of select="$std-ref"/><xsl:text>&#xa;</xsl:text> -->
		<!-- <xsl:variable name="ref1" select="//ref[std/std-ref = $std-ref]/@id"/> -->
		<xsl:variable name="ref1_" select="$refs//ref[@stdid_option = $std-ref]"/>				
		<xsl:variable name="ref1" select="xalan:nodeset($ref1_)"/>				
		<!-- ref1=<xsl:value-of select="$ref1"/><xsl:text>&#xa;</xsl:text> -->
		<!-- <xsl:variable name="ref2" select="//ref[starts-with(std/std-ref, concat($std-ref, ' '))]/@id"/> -->
		<xsl:variable name="ref2_" select="$refs//ref[starts-with(@stdid_option, concat($std-ref, ' '))]"/>
		<xsl:variable name="ref2" select="xalan:nodeset($ref2_)"/>
		<!-- ref2=<xsl:value-of select="$ref2"/><xsl:text>&#xa;</xsl:text> -->
		
		<xsl:variable name="ref3_" select="$refs//ref[@stdid_option = $std-ref]/@stdid_option"/>				
		<xsl:variable name="ref3" select="xalan:nodeset($ref3_)"/>				
		
		<xsl:choose>
			<xsl:when test="$ref1/@id != ''">
				<item><xsl:value-of select="$ref1/@id"/></item>
				
				<xsl:if test="$ref1/@addTextToReference = 'true'">
					<!-- if reference to standard and bibitem is numbered, for example: [1] -->
					<!-- <xsl:text>,</xsl:text> -->
					<item><xsl:value-of select="$text"/></item>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$ref2/@id != ''">
				<item><xsl:value-of select="$ref2/@id"/></item>
				
				<xsl:if test="$ref2/@addTextToReference = 'true'">
					<!-- if reference to standard and bibitem is numbered, for example: [1] -->
					<!-- <xsl:text>,</xsl:text> -->
					<item><xsl:value-of select="$text"/></item>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$ref3/@stdid_option != ''">
				<item><xsl:value-of select="$ref3/@stdid_option"/></item>
				
				<xsl:if test="$ref3/@addTextToReference = 'true'">
					<!-- if reference to standard and bibitem is numbered, for example: [1] -->
					<!-- <xsl:text>,</xsl:text> -->
					<item><xsl:value-of select="$text"/></item>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="$std-ref != $text">
					<item>
						<xsl:value-of select="$std-ref"/>
					</item><!-- , -->
				</xsl:if>
				<item><xsl:value-of select="$text"/></item>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="getUpdatedRef">
		<xsl:param name="text"/>
		<xsl:variable name="text_items">
			<xsl:call-template name="split">
				<xsl:with-param name="pText" select="$text"/>
				<xsl:with-param name="sep" select="' '"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="updated_ref">
			<xsl:for-each select="xalan:nodeset($text_items)//item">
				<xsl:variable name="item" select="java:toLowerCase(java:java.lang.String.new(.))"/>
				<xsl:choose>
					<xsl:when test=". = ','">
						<xsl:value-of select="."/>
					</xsl:when>
					<xsl:when test="$item = 'clause' or $item = 'table' or $item = 'annex' or $item = 'section'">
						<xsl:value-of select="$item"/><xsl:text>=</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text> </xsl:text><xsl:value-of select="."/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new($updated_ref),'= ','='))"/>
	</xsl:template>
	
	<xsl:template name="setId">
		<xsl:param name="newline">true</xsl:param>
		<xsl:if test="normalize-space(@id) != ''">
			<xsl:text>[[</xsl:text><xsl:value-of select="@id"/><xsl:text>]]</xsl:text>
			<xsl:if test="$newline = 'true'">
				<xsl:text>&#xa;</xsl:text>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="setIdOrType">
		<xsl:choose>
			<xsl:when test="parent::front">
				<xsl:if test="not(@sec-type = 'foreword')">
					<xsl:text>[.preface</xsl:text>
					<xsl:choose>
						<xsl:when test="@sec-type = 'amendment'">
							<xsl:text>,type=corrigenda</xsl:text>
						</xsl:when>
						<xsl:when test="@sec-type">
							<xsl:text>,type=</xsl:text><xsl:value-of select="@sec-type"/>
						</xsl:when>
					</xsl:choose>
					<xsl:text>]</xsl:text>
					<xsl:text>&#xa;</xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:when test="ancestor::front and @sec-type">
				<xsl:text>[type=</xsl:text><xsl:value-of select="@sec-type"/>
				<xsl:text>]</xsl:text>
					<xsl:text>&#xa;</xsl:text>
			</xsl:when>
		</xsl:choose>
		
		<xsl:if test="normalize-space(@id) != '' or @sec-type">
			<xsl:text>[[</xsl:text>
				<xsl:choose>
					<xsl:when test="normalize-space(@id) != ''">
						<xsl:value-of select="@id"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="@sec-type"/>
					</xsl:otherwise>
				</xsl:choose>
			<xsl:text>]]</xsl:text>
		</xsl:if>
		<xsl:if test="not(title) and label">
			<xsl:text>&#xa;</xsl:text>
			<xsl:choose>
				<xsl:when test="label = 'Foreword' or label = 'Introduction'">
				<xsl:text>== </xsl:text><xsl:value-of select="label"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="level">
						<xsl:call-template name="getLevel">
							<xsl:with-param name="addon">1</xsl:with-param>
						</xsl:call-template>
					</xsl:variable>
					<xsl:value-of select="$level"/>
					<xsl:text> {blank}</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template name="insertTaskImageList"> 
		<xsl:variable name="imageList">
			<xsl:for-each select="//graphic | //inline-graphic">
				<xsl:variable name="image"><xsl:call-template name="graphic" /></xsl:variable>
				<xsl:if test="not(contains($image, 'base64,'))">
					<image><xsl:value-of select="$image"/></image>
				</xsl:if>
			</xsl:for-each>
			
			<xsl:if test="$organization = 'PAS'">
				<image>image::<xsl:call-template name="getCoverPageImage"/><xsl:text>&#xa;</xsl:text></image>
				<image>image::toc_image.png<xsl:text>&#xa;</xsl:text></image>
			</xsl:if>
		</xsl:variable>
		
		<xsl:if test="xalan:nodeset($imageList)//image">
			<redirect:write file="{$taskCopyImagesFilename}"> <!-- this list will be processed and deleted in java program -->
				<xsl:for-each select="xalan:nodeset($imageList)//image">
					<!-- <xsl:text>copy</xsl:text><xsl:value-of select="."/> -->
					<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),'image::','copyimage::')"/>
				</xsl:for-each>
			</redirect:write>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="/" mode="sub-part">
		<xsl:param name="doc-number"/>
		<xsl:apply-templates select="@*|node()" mode="sub-part">
			<xsl:with-param name="doc-number" select="$doc-number"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<!-- add doc-number attribute, will be used in output filename -->
	<xsl:template match="standard" mode="sub-part">
		<xsl:param name="doc-number"/>
		<xsl:copy>
				<xsl:apply-templates select="@*" mode="sub-part"/>
				<xsl:attribute name="doc-number"><xsl:value-of select="$doc-number"/></xsl:attribute>
				<xsl:apply-templates select="node()" mode="sub-part">
					<xsl:with-param name="doc-number" select="$doc-number"/>
				</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="@*|node()" mode="sub-part">
		<xsl:param name="doc-number"/>
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="sub-part">
					<xsl:with-param name="doc-number" select="$doc-number"/>
				</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="front" mode="sub-part">
		<xsl:param name="doc-number"/>
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="sub-part">
				<xsl:with-param name="doc-number" select="$doc-number"/>
			</xsl:apply-templates>
			
			<!-- copy data from standard/body/sub-part[number][sub-part] into front-->
			<xsl:apply-templates select="ancestor::standard/body/sub-part[$doc-number][body/sub-part]" mode="sub-part-front">
				<xsl:with-param name="doc-number" select="$doc-number"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="@*|node()" mode="sub-part-front">
		<xsl:param name="doc-number"/>
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="sub-part-front">
					<xsl:with-param name="doc-number" select="$doc-number"/>
				</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="standard/body/sub-part | standard/body/sub-part/body" mode="sub-part-front">
		<xsl:apply-templates mode="sub-part-front" />
	</xsl:template>
	
	<xsl:template match="standard/body/sub-part/body/sub-part" mode="sub-part-front"/>
	<xsl:template match="standard/body/sub-part/label[normalize-space() = ''] | standard/body/sub-part/title[normalize-space() = '']" mode="sub-part-front"/>
	
	<xsl:template match="body/graphic" priority="2" mode="sub-part-front"/>
	
	<xsl:template match="front/sec" mode="sub-part">
		<xsl:param name="doc-number"/>
		<!-- doc-number=<xsl:value-of select="$doc-number"/> -->
		<xsl:if test="$doc-number = 1">
			<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="sub-part">
					<xsl:with-param name="doc-number" select="$doc-number"/>
				</xsl:apply-templates>
			</xsl:copy>
		</xsl:if>
	</xsl:template>
	
	<!-- remove element body (but not content!), which contains sub-part inside -->
	<xsl:template match="standard/body[sub-part] | standard/body/sub-part/body[sub-part]" mode="sub-part">
		<xsl:param name="doc-number"/>
		<xsl:apply-templates select="@*|node()" mode="sub-part">
			<xsl:with-param name="doc-number" select="$doc-number"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="standard/body/sub-part" mode="sub-part">
		<xsl:param name="doc-number"/>
		<xsl:variable name="current-number"><xsl:number/></xsl:variable>
		<!-- current-number=<xsl:value-of select="$current-number"/> -->
		<xsl:if test="$doc-number = $current-number">
			
			<xsl:apply-templates select="@*|node()" mode="sub-part">
				<xsl:with-param name="doc-number" select="$doc-number"/>
			</xsl:apply-templates>
			
		</xsl:if>
	</xsl:template>
	
	<!-- these elements was moved in sub-part-front templates -->
	<xsl:template match="standard/body/sub-part/body[sub-part]/*[local-name() != 'sub-part']" mode="sub-part"/>
	
	<xsl:template match="standard/body/sub-part/body/sub-part" mode="sub-part">
		<xsl:apply-templates select="@*|node()" mode="sub-part" />
	</xsl:template>
	
	<xsl:template match="standard/body/sub-part/label[normalize-space() = ''] | 
										standard/body/sub-part/title[normalize-space() = ''] |
										standard/body/sub-part/body/sub-part/label[normalize-space() = ''] | 
										standard/body/sub-part/body/sub-part/title[normalize-space() = '']" mode="sub-part"/>
	
	
	<xsl:template match="processing-instruction()[contains(., 'Page_Break')] | processing-instruction()[contains(., 'Page-Break')]">
		<xsl:if test="not(ancestor::table)"> <!-- Conversion gap: <?Para Page_Break?> between table's rows https://github.com/metanorma/mn-samples-bsi/issues/47 -->
			<xsl:text>&#xa;&#xa;</xsl:text>
			<xsl:text>&lt;&lt;&lt;</xsl:text>
			<xsl:text>&#xa;&#xa;&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="addIndexTerms">
		<xsl:variable name="id" select="../@id"/>
		<xsl:for-each select="$index//reference[@rid = $id]">
			<xsl:text>(((</xsl:text>
				<xsl:apply-templates />
			<xsl:text>)))</xsl:text>
			<xsl:if test="position() = last()"><xsl:text>&#xa;</xsl:text></xsl:if>
		</xsl:for-each>
	</xsl:template>
	
	
	<xsl:template name="getDocFilename">
		<xsl:choose>
			<xsl:when test="$demomode = 'true' and $one_document = 'false'">
				<!-- iso-meta - reg-meta - nat-meta -->
				<xsl:variable name="docfile_name_from_meta_">
					<xsl:choose>
						<xsl:when test="ancestor-or-self::standard/front/iso-meta">
							<xsl:for-each select="ancestor-or-self::standard/front/iso-meta"> <!-- set context to iso-meta -->
								<xsl:call-template name="getMetaBibFilename"/>
							</xsl:for-each>
						</xsl:when>
						<xsl:when test="ancestor-or-self::standard/front/reg-meta">
							<xsl:for-each select="ancestor-or-self::standard/front/reg-meta"> <!-- set context to iso-meta -->
								<xsl:call-template name="getMetaBibFilename"/>
							</xsl:for-each>
						</xsl:when>
						<xsl:when test="ancestor-or-self::standard/front/nat-meta"><xsl:value-of select="concat($docfile_name, '.', $docfile_ext)"/></xsl:when>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="docfile_name_from_meta" select="normalize-space($docfile_name_from_meta_)"/>
				<xsl:value-of select="$docfile_name_from_meta"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="doc-number" select="ancestor-or-self::standard/@doc-number" />
				<xsl:variable name="sfx"><xsl:if test="$doc-number != ''">.<xsl:value-of select="$doc-number"/></xsl:if></xsl:variable>
				<xsl:value-of select="concat($docfile_name, $sfx, '.', $docfile_ext)"/> <!-- Example: iso-tc154-8601-1-en.adoc , or document.adoc -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="getDocFilename2">
		<xsl:variable name="doc-number" select="ancestor-or-self::standard/@doc-number" />
		<xsl:variable name="sfx"><xsl:if test="$doc-number != ''">.<xsl:value-of select="$doc-number"/></xsl:if></xsl:variable>
		<xsl:value-of select="concat($docfile_name, $sfx, '.', $docfile_ext)"/> <!-- Example: iso-tc154-8601-1-en.adoc , or document.adoc -->
	</xsl:template>
	
	<xsl:template name="getSectionsFolder">
		
		<xsl:variable name="doc-number" select="ancestor-or-self::standard/@doc-number" />
		<xsl:variable name="sfx"><xsl:if test="$doc-number != ''">.<xsl:value-of select="$doc-number"/></xsl:if></xsl:variable>
		<xsl:value-of select="concat('sections', $sfx)"/>
	</xsl:template>
	
	<xsl:template name="insertCollectionData">
		<xsl:param name="documents"/>
		<xsl:text>directives:&#xa;</xsl:text>
		<xsl:text>  - documents-inline&#xa;</xsl:text>
		<xsl:text>bibdata:&#xa;</xsl:text>
		<xsl:text>  type: collection&#xa;</xsl:text>
		<xsl:text>  docid:&#xa;</xsl:text>
		<xsl:text>    type: bsi&#xa;</xsl:text>
		<xsl:text>    id: bsidocs&#xa;</xsl:text>
		<xsl:text>manifest:&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>  docref:&#xa;</xsl:text>
		<xsl:for-each select="xalan:nodeset($documents)/*">
			<xsl:text>    - fileref: </xsl:text><xsl:value-of select="$docfile_name"/>.<xsl:value-of select="@doc-number"/><xsl:text>.xml&#xa;</xsl:text>
			<xsl:text>      identifier: bsidocs-</xsl:text><xsl:value-of select="@doc-number"/><xsl:text>&#xa;</xsl:text>
		</xsl:for-each>
		<xsl:text>prefatory-content:&#xa;</xsl:text>
		<xsl:text>|&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>final-content:&#xa;</xsl:text>
		<xsl:text>|&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<!-- generate normalized form for id  (std-id, std-ref, etc.) -->
	<xsl:template name="getNormalizedId">
		<xsl:param name="id"/>
		<!-- <xsl:variable name="id_normalized1" select="translate($id, ' &#xA0;:+/', '_____')"/> --> <!-- replace space, non-break space, colon, plus, slash to _ -->
		<xsl:variable name="id_normalized1" select="java:replaceAll(java:java.lang.String.new($id), $regex_refid_replacement, '_')"/> <!-- replace space, non-break space, colon, plus, slash to _ -->
		
		<xsl:variable name="id_normalized2" select="translate($id_normalized1, '&#x2011;', '-')"/> <!-- replace non-breaking hyphen minus to simple minus-->
		<xsl:variable name="first_char" select="substring(id_normalized2,1,1)"/>
		<xsl:if test="$first_char != '' and translate($first_char, '0123456789', '') = ''">_</xsl:if> <!-- if first char is digit, then add _ -->
		<xsl:value-of select="$id_normalized2"/>
	</xsl:template>

	<!-- ========================================= -->
	<!-- XML Linearization -->
	<!-- ========================================= -->
	<xsl:template match="@*|node()" mode="linearize">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="linearize"/>
		</xsl:copy>
	</xsl:template>
	
	<!-- remove redundant spaces -->
	<xsl:template match="text()[not(parent::code) and not(parent::preformat) and not(parent::mml:*)]" mode="linearize">
		<xsl:choose>
		
			<xsl:when test="parent::standard or parent::body or parent::sec or parent::term-sec or parent::tbx:termEntry or parent::back or parent::app-group or parent::app or parent::ref-list or parent::ref or parent::fig or parent::caption or parent::table-wrap or parent::tr or parent::thead or parent::colgroup or parent::table or parent::tbody or parent::fn or parent::non-normative-note or parent::non-normative-example or parent::array or parent::list-item or parent::list or parent::boxed-text">
				<xsl:value-of select="normalize-space()"/> <!-- tab to space -->
			</xsl:when>
			
			<xsl:when test="parent::td and preceding-sibling::*[1][self::p or self::non-normative-note or self::list] and 
			following-sibling::*[1][self::p or self::non-normative-note or self::list] and 
			normalize-space() = ''"></xsl:when>
			
			<xsl:otherwise>
				<xsl:variable name="str">
					<xsl:choose>
						<xsl:when test="contains(., '&#xa;') or contains(., '&#x9;')">
							<!-- replace line breaks to space -->
							<xsl:variable name="text_" select="translate(., '&#xa;&#x9;', '  ')"/>
							<!-- replace space sequence to one space -->
							<xsl:variable name="text" select="java:replaceAll(java:java.lang.String.new($text_),' +',' ')"/>
							<xsl:if test="normalize-space($text) != ''">
								<!-- <xsl:if test="parent::p">parent::p</xsl:if>
								<xsl:if test="(not(preceding-sibling::*) or preceding-sibling::*[1][self::break])">(not(preceding-sibling::*) or preceding-sibling::*[1][self::break])</xsl:if>
								<xsl:if test="starts-with($text, ' ')">starts-with($text, ' ')</xsl:if> -->
								<xsl:choose>
									<xsl:when test="(parent::p or parent::tbx:note) and (not(preceding-sibling::*) or preceding-sibling::*[1][self::break]) and starts-with($text, ' ')"> <!-- remove space at start of line -->
										<xsl:value-of select="substring($text, 2)"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$text"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="."/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<!-- Escape "(c)", "(C)", "(r)", "(R)" text to avoid render copyright symbol -->
				<xsl:variable name="str01" select="java:replaceAll(java:java.lang.String.new($str),'\(R\)','(&#x200c;R)')"/>
				<xsl:variable name="str02" select="java:replaceAll(java:java.lang.String.new($str01),'\(r\)','(&#x200c;r)')"/>
				<xsl:variable name="str03" select="java:replaceAll(java:java.lang.String.new($str02),'\(TM\)','(&#x200c;TM)')"/>
				<xsl:variable name="str04" select="java:replaceAll(java:java.lang.String.new($str03),'\(tm\)','(&#x200c;tm)')"/>
				<xsl:variable name="str05" select="java:replaceAll(java:java.lang.String.new($str04),'\(C\)','(&#x200c;C)')"/>
				<xsl:variable name="str10" select="java:replaceAll(java:java.lang.String.new($str05),'\(c\)','(&#x200c;c)')"/>
				
				<xsl:variable name="str20">
				
					<!-- string ends with [ -->
					<xsl:variable name="isEndsWithOpeningBracket" select="java:endsWith(java:java.lang.String.new($str10),'[') and following-sibling::node()[1][self::xref][@ref-type = 'bibr'] and not(parent::tbx:source) and starts-with(following-sibling::node()[2],']')"/>
					<!-- string starts with ] -->
					<xsl:variable name="isStartsWithClosingBracket" select="starts-with($str10,']') and preceding-sibling::node()[1][self::xref][@ref-type = 'bibr'] and not(parent::tbx:source) and java:endsWith(java:java.lang.String.new(preceding-sibling::node()[2]),'[')"/>
					
					<xsl:choose>
					
						<!-- Remove square brackets around cross-reference (xref with ref-type="bibr") to the bibliography -->
						<!-- Employment Rights Act 1996 [<xref ref-type="bibr" rid="ref_4">1</xref>].</p> -->
						<!-- string starts with ] or/and ends with [ -->
						<xsl:when test="$isEndsWithOpeningBracket = 'true' or $isStartsWithClosingBracket = 'true'">
							<xsl:variable name="s1">
								<xsl:choose>
									<xsl:when test="$isEndsWithOpeningBracket = 'true'">
										<xsl:value-of select="java:replaceAll(java:java.lang.String.new($str10),'\[$','')"/> <!-- '$' means end of string -->
									</xsl:when>
									<xsl:otherwise><xsl:value-of select="$str10"/></xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<xsl:variable name="s2">
								<xsl:choose>
									<xsl:when test="$isStartsWithClosingBracket = 'true'">
										<xsl:value-of select="java:replaceAll(java:java.lang.String.new($s1),'^\]','')"/> <!-- '^' means begin of string -->
									</xsl:when>
									<xsl:otherwise><xsl:value-of select="$s1"/></xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<xsl:value-of select="$s2"/>
						</xsl:when>
						
						<xsl:otherwise>
							<xsl:value-of select="$str10"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				
				<!-- remove leading spaces in the paragraph -->
				<xsl:variable name="str30">
					<xsl:choose>
						<xsl:when test="parent::p and not(preceding-sibling::node()) and starts-with($str20, ' ')">
							<xsl:value-of select="java:replaceAll(java:java.lang.String.new($str20),'^\s+','')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$str20"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				
				<xsl:variable name="str40">
					<xsl:choose>
						<xsl:when test="ancestor::td and contains($str30, '|')">
							<xsl:value-of select="java:replaceAll(java:java.lang.String.new($str30),'\|','\\|')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$str30"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				
				<xsl:value-of select="$str40"/>
			</xsl:otherwise>
			
		</xsl:choose>		
	</xsl:template>
	
	<!-- transform p with section number to sec and title -->
	<xsl:template match="sec/p[java:org.metanorma.utils.RegExHelper.matches('^[0-9]+((\.[0-9]+)+((\s|\h).*)?)?$', normalize-space(.)) = 'true'][local-name(node()[1]) != 'xref']" mode="linearize">
	
		<xsl:variable name="title_without_bold">
			<xsl:apply-templates mode="title_without_bold"/>
		</xsl:variable>
	
		<xsl:variable name="title_first_component" select="xalan:nodeset($title_without_bold)/node()[1]"/>
		<xsl:variable name="label">
			<xsl:choose>
				<xsl:when test="contains($title_first_component, ' ')">
					<xsl:value-of select="substring-before($title_first_component, ' ')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="normalize-space($title_first_component)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
	
		<xsl:variable name="title">
			<xsl:for-each select="xalan:nodeset($title_without_bold)/node()">
				<xsl:choose>
					<xsl:when test="position() = 1">
						<xsl:value-of select="substring-after(., ' ')"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="."/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
	
		<sec>
			<xsl:attribute name="sec_depth">
				<xsl:value-of select="string-length($label) - string-length(translate($label, '.', '')) + 2"/>
			</xsl:attribute>
			<label>
				<!-- to process these cases:
				*0.3   Common principles of relationship management*
				*0.3.1   The life cycle framework*
				-->
				<xsl:value-of select="$label"/>
			</label>
			<xsl:if test="normalize-space(xalan:nodeset($title)) != ''">
				<title>
					<xsl:copy-of select="$title"/>
				</title>	
			</xsl:if>
		</sec>
	</xsl:template>
	
	<xsl:template match="@*|node()" mode="title_without_bold">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="title_without_bold"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="bold" mode="title_without_bold">
		<xsl:apply-templates mode="title_without_bold"/>
	</xsl:template>
	<xsl:template match="text()" mode="title_without_bold">
		<xsl:call-template name="trimSpaces">
			<xsl:with-param name="text" select="translate(., '&#xa0;&#x9;', '  ')"/> <!-- replace nbsp and tab to space -->
		</xsl:call-template>
	</xsl:template>

	<xsl:variable name="title_text_regex" select="'^([0-9]+(\.[0-9]+)*)(\s|\h)+(.*)$'"/>
	<!-- remove digits from title: 0  Introduction -> Introduction -->
	<xsl:template match="sec[not(label)]/title/node()[1][java:org.metanorma.utils.RegExHelper.matches($title_text_regex, normalize-space(.)) = 'true']">
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),$title_text_regex,'$4')"/>
	</xsl:template>
	
	<!-- convert array (without label) / table with two td in a row, and td starts with EXAMPLE in first td to non-normative-example -->
	<xsl:template match="array[not(label)][table[count(.//td) div count(.//tr) = 2][starts-with(.//tr[1]/td[1], 'EXAMPLE')]]" mode="linearize">
		<non-normative-example>
			<xsl:if test="@id">
				<xsl:attribute name="id">
					<xsl:text>array_</xsl:text><xsl:value-of select="@id"/>
				</xsl:attribute>
			</xsl:if>
			<label><xsl:apply-templates select="table//tr[1]/td[1]" mode="linearize_array_example"/></label>
			<p><xsl:apply-templates select="table//tr[1]/td[2]" mode="linearize_array_example"/></p>
			<xsl:for-each select="table//tr[position() &gt; 1]/td[normalize-space(translate(., '&#xa0;', '')) != '']">
				<p><xsl:apply-templates select="." mode="linearize_array_example"/></p>
			</xsl:for-each>
		</non-normative-example>
	</xsl:template>
	<xsl:template match="td" mode="linearize_array_example">
		<xsl:apply-templates mode="linearize"/>
	</xsl:template>
	
	<!-- remove empty italic/bold -->
	<xsl:template match="italic[not(node())]" mode="linearize"/>
	<xsl:template match="bold[not(node())]" mode="linearize"/>
	<xsl:template match="sup[not(node())]" mode="linearize"/>
	<xsl:template match="sub[not(node())]" mode="linearize"/>
	
	<!-- ================== -->
	<!-- convert array in sec with the title 'Abbreviated terms' to def-list -->
	<!-- ================== -->
	<xsl:template match="array[not(label)][parent::sec/title = 'Abbreviated terms'][table[count(.//td) div count(.//tr) = 2]]" mode="linearize">
		<def-list list-type="abbreviations">
			<xsl:apply-templates mode="linearize_array_deflist"/>
		</def-list>
	</xsl:template>
	
	<xsl:template match="text()" mode="linearize_array_deflist" priority="2">
		<xsl:apply-templates select="." mode="linearize"/>
	</xsl:template>
	
	<xsl:template match="@*|node()" mode="linearize_array_deflist">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="linearize_array_deflist"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="table | tbody | td" mode="linearize_array_deflist">
		<xsl:apply-templates mode="linearize_array_deflist"/>
	</xsl:template>
	
	<xsl:template match="colgroup" mode="linearize_array_deflist"/>
	
	<xsl:template match="tr" mode="linearize_array_deflist">
		<def-item>
			<term><xsl:apply-templates select="td[1]" mode="linearize_array_deflist"/></term>
			<def><p><xsl:apply-templates select="td[2]" mode="linearize_array_deflist"/></p></def>
		</def-item>
	</xsl:template>
	<!-- ================== -->
	<!-- END: convert array in sec with the title 'Abbreviated terms' to def-list -->
	<!-- ================== -->
	
	<!-- Move "Table #n —" from table-wrap/caption to table-wrap/label -->
	<xsl:variable name="regexTableN" select="'^Table((\s|\h)[0-9]+)*(\s|\h)—(\s|\h)'"/>
	<xsl:template match="table-wrap[not(label)][java:replaceAll(java:java.lang.String.new(caption/title),$regexTableN,'') != caption/title]" mode="linearize">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<label><xsl:value-of select="substring-before(caption/title, '—')"/></label>
			<!-- <label><xsl:value-of select="java:replaceAll(java:java.lang.String.new(caption/title),$regexTableN,'')"/></label> -->
			<xsl:apply-templates mode="linearize"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="table-wrap[not(label)][java:replaceAll(java:java.lang.String.new(caption/title),$regexTableN,'') != caption/title]/caption/title/node()[1]" mode="linearize" priority="3">
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),$regexTableN,'')"/>
	</xsl:template>
	
	<!-- ======================================= -->
	<!-- move list item label from p into the element label. -->
	<!-- ======================================= -->
	<xsl:variable name="regexListItemLabel" select="'^((([0-9]|[a-z]|[A-Z])+(\)|\.))(\s|\h)+)(.*)'"/>
	<!-- find list-item without label, and with first text matches regex -->
	<xsl:template match="list-item[not(label)][.//node()[self::text()][normalize-space() != ''][1][java:org.metanorma.utils.RegExHelper.matches($regexListItemLabel, normalize-space(.)) = 'true']]" mode="linearize">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<label><xsl:value-of select="java:replaceAll(java:java.lang.String.new(.//node()[self::text()][normalize-space() != ''][1]), $regexListItemLabel, '$2')"/></label>
			<xsl:apply-templates mode="linearize_listitem"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="list-item[not(label)]//node()[self::text()][normalize-space() != ''][1]" mode="linearize_listitem" priority="3">
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),$regexListItemLabel, '$6')"/> <!-- get last group from regexListItemLabel, i.e. list item text without label-->
	</xsl:template>
	
	<xsl:template match="@*|node()" mode="linearize_listitem">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="linearize_listitem"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="text()" mode="linearize_listitem" priority="2">
		<xsl:apply-templates select="." mode="linearize"/>
	</xsl:template>
	<!-- ======================================= -->
	<!-- END: move list item label from p into the element label.-->
	<!-- ======================================= -->
	
	<!-- remove break from tbx:term -->
	<xsl:template match="tbx:term/break" mode="linearize">
		<xsl:if test="preceding-sibling::node()"><xsl:text> </xsl:text></xsl:if>
	</xsl:template>
	
	<!-- Removing <sup>)</sup> and <sup>) </sup> from table footnotes -->
	<xsl:template match="sup[normalize-space() = ')'][preceding-sibling::node()[1][self::xref][@ref-type = 'table-fn']]" mode="linearize"/>
	<xsl:template match="bold[preceding-sibling::node()[1][self::xref][@ref-type = 'table-fn']]/sup[normalize-space() = ')']" mode="linearize"/>
	<xsl:template match="bold[preceding-sibling::node()[1][self::xref][@ref-type = 'table-fn']][sup[normalize-space() = ')'] and normalize-space() = ')']" mode="linearize"/>
	<!-- Removing <sup>)</sup> immediately after <fn></fn>  -->
	<xsl:template match="sup[normalize-space() = ')'][preceding-sibling::node()[1][self::fn]]" mode="linearize"/>
	
	<xsl:template match="tbx:source[italic and count(node()) = 1]" mode="linearize">
		<tbx:note><xsl:apply-templates mode="linearize"/></tbx:note>
	</xsl:template>
	<!-- ========================================= -->
	<!-- END XML Linearization -->
	<!-- ========================================= -->
	
	<!-- ========================================= -->
	<!-- Remove Clause before xref pointed to 1st level clause  -->
	<!-- ========================================= -->
	<xsl:template match="@*|node()" mode="remove_word_clause">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="remove_word_clause"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="text()[following-sibling::*[1][self::xref]]" mode="remove_word_clause">
		<xsl:variable name="xref_rid" select="following-sibling::*[1][self::xref]/@rid"/>
		<xsl:variable name="is_clause_1stlevel_depth" select="count(//*[@id = $xref_rid]/parent::*[self::body or self::back]) &gt; 0"/>
		<xsl:variable name="clause_text_regex">Clause $</xsl:variable><!-- string ends on 'Clause ' -->
		<xsl:choose>
			<xsl:when test="$is_clause_1stlevel_depth = 'true'">
				<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),$clause_text_regex,'')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- ========================================= -->
	<!-- END Remove Clause before xref pointed to 1st level clause -->
	<!-- ========================================= -->
	
	<!-- ========================================= -->
	<!-- unconstrained formatting (https://docs.asciidoctor.org/asciidoc/latest/text/#unconstrained) -->
	<!-- ========================================= -->
	<xsl:template match="@*|node()" mode="unconstrained_formatting">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="unconstrained_formatting"/>
		</xsl:copy>
	</xsl:template>
	
	<!-- https://github.com/asciidoctor/asciidoctor/issues/2010#issuecomment-276583709 -->
	<!-- disabled for sub | sup | -->
	
	<xsl:template match="bold | italic | monospace" mode="unconstrained_formatting">
		<xsl:variable name="unconstrained_formatting"><xsl:call-template name="is_unconstrained_formatting"/></xsl:variable>
		<xsl:variable name="element_name_addon"><xsl:if test="$unconstrained_formatting = 'true'">2</xsl:if></xsl:variable>
		
		<xsl:element name="{local-name()}{$element_name_addon}">
			<xsl:apply-templates select="@*" mode="unconstrained_formatting"/>
			<xsl:apply-templates mode="unconstrained_formatting"/>
		</xsl:element>
	</xsl:template>
	
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
			<!-- bold text inside italic -->
			<xsl:when test="self::bold and parent::italic">true</xsl:when>
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
	<!-- ========================================= -->
	<!-- END unconstrained formatting  -->
	<!-- ========================================= -->
	
	<!-- ========================================= -->
	<!-- References fixing -->
	<!-- ========================================= -->
	<xsl:template match="@*|node()" mode="ref_fix">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="ref_fix"/>
		</xsl:copy>
	</xsl:template>
	
	<!-- Add @stdid (and @stdid_option) to ref for reference mechanism between <std std-id="..."></std> and <ref></ref> -->
	<xsl:template match="ref" mode="ref_fix">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="ref_fix"/>
			
			<xsl:variable name="std-id">
				<xsl:call-template name="getNormalizedId">
					<xsl:with-param name="id" select="std/@std-id"/>
				</xsl:call-template>
			</xsl:variable>
			
			<xsl:variable name="std-ref">
				<xsl:call-template name="getNormalizedId">
					<!-- <xsl:with-param name="id" select="normalize-space(std/std-ref)"/> -->
					<xsl:with-param name="id" select="normalize-space(concat(std/std-ref, std/italic/std-ref, std/bold/std-ref, std/italic2/std-ref, std/bold2/std-ref))"/>
				</xsl:call-template>
			</xsl:variable>
			
			<xsl:variable name="stdid">
				<xsl:choose>
					<!-- Example:
					<ref>
						<std std-id="iso:std:iso:44001:ed-1:en" type="dated">
							<std-ref>ISO 44001:2017
							</std-ref>, <title>...</title>
						</std>
					</ref> -->
					<xsl:when test="normalize-space($std-id) != ''">
						<xsl:value-of select="normalize-space($std-id)"/>
					</xsl:when>
					<!-- Example:
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
			
			
			<xsl:attribute name="addTextToReference">
				<xsl:value-of select="normalize-space(@content-type = 'standard' and starts-with(label, '['))"/>
			</xsl:attribute>
			
			<xsl:variable name="referenceText">
				<xsl:variable name="std-ref_">
					<xsl:apply-templates select="std/std-ref | std/italic/std-ref | std/bold/std-ref | std/italic2/std-ref | std/bold2/std-ref" mode="references"/>
				</xsl:variable>
				<xsl:value-of select="translate($std-ref_, '&#x2011;', '-')"/>
			</xsl:variable>
			<xsl:attribute name="referenceText">
				<xsl:value-of select="$referenceText"/>
			</xsl:attribute>
			
			<xsl:apply-templates select="node()" mode="ref_fix"/>
		</xsl:copy>
	</xsl:template>

	<!-- Add stdid to std for reference mechanism between <std std-id="..."></std> and <ref></ref> -->
	<xsl:template match="std[not(parent::ref)]" mode="ref_fix">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="ref_fix"/>
			<xsl:attribute name="stdid">
				<xsl:choose>
					<!-- if there is attribute @std-id -->
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
					<!-- if there is nested std-ref -->
					<xsl:when test="normalize-space(.//std-ref) != ''">
						<xsl:call-template name="getNormalizedId">
							<xsl:with-param name="id" select="normalize-space(.//std-ref)"/>
						</xsl:call-template>
					</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates select="node()" mode="ref_fix"/>
		</xsl:copy>
	</xsl:template>
	<!-- ========================================= -->
	<!-- END References fixing -->
	<!-- ========================================= -->
	
	<xsl:template name="trimSpaces">
		<xsl:param name="text" select="."/>
		
		<xsl:variable name="text_lefttrim">
			<xsl:choose>
				<xsl:when test="not(preceding-sibling::*) and not(preceding-sibling::comment())">
					<xsl:value-of select="java:replaceAll(java:java.lang.String.new($text),'^\s+','')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$text"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		
		<xsl:variable name="text_righttrim">
			<xsl:choose>
				<xsl:when test="not(following-sibling::*) and not(following-sibling::comment())">
					<xsl:value-of select="java:replaceAll(java:java.lang.String.new($text_lefttrim),'\s+$','')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$text_lefttrim"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<!-- replace two or more spaces into one space -->
		<xsl:variable name="text" select="java:replaceAll(java:java.lang.String.new($text_righttrim),'\s{2,}',' ')"/>
		
		<xsl:value-of select="$text"/>
	</xsl:template>
	
</xsl:stylesheet>