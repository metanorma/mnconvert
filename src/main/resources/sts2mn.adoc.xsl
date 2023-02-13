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
	
	<xsl:param name="self_testing">false</xsl:param> <!-- true false -->
	
	<xsl:key name="ids" match="*" use="@id"/> 
	
	<xsl:variable name="inputformat">
		<xsl:choose>
			<xsl:when test="/standards-document">IEEE</xsl:when>
			<xsl:otherwise>STS</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:variable name="OUTPUT_FORMAT">adoc</xsl:variable> <!-- don't change it -->
	
	<!-- false --> <!-- true, for new features -->
	<!-- <xsl:variable name="demomode">
		<xsl:choose>
			<xsl:when test="/standard/front/iso-meta/doc-ident/proj-id = '59752'">true</xsl:when>
			<xsl:when test="/standard/front/iso-meta/doc-ident/proj-id = '36786'">true</xsl:when>
			<xsl:when test="/standard/front/iso-meta/doc-ident/proj-id = '69315'">true</xsl:when> -->
			<!-- <xsl:when test="/standard/front/iso-meta/doc-ident/proj-id = '62726'">true</xsl:when>
			<xsl:when test="/standard/front/iso-meta/doc-ident/proj-id = '72800'">true</xsl:when>
			<xsl:when test="/standard/front/iso-meta/doc-ident/proj-id = '74716'">true</xsl:when>
			<xsl:when test="/standard/front/iso-meta/doc-ident/proj-id = '68221'">true</xsl:when>
			<xsl:when test="/standard/front/reg-meta/doc-ident/proj-id = '33079'">true</xsl:when> -->
			<!-- <xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>  -->
	
	<xsl:variable name="one_document_" select="count(//standard/front/*[contains(local-name(), '-meta')]) = 1 or //standards-document"/>
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
			<xsl:when test="//standards-document">ieee</xsl:when>
			<xsl:otherwise>iso</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:variable name="taskCopyImagesFilename" select="concat($outpath, '/task.copyImages.adoc')"/>
	
	<!-- prepare assosiative array - id and index term -->
	<xsl:variable name="index_">
		<xsl:for-each select="//sec[@id = 'ind' or @id = 'sec_ind']//xref">
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
		<xsl:for-each select="//sec[@id = 'ind' or @id = 'sec_ind']//p[italic/text() = 'see' or italic/text() = 'see also']">
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
	
	<xsl:variable name="refs_">
		<xsl:if test="$self_testing = 'false'">
			<xsl:for-each select="$updated_xml//ref">
				<xsl:copy>
					<xsl:copy-of select="@*"/>
				</xsl:copy>
			</xsl:for-each>
		</xsl:if>
	</xsl:variable>
	<xsl:variable name="refs" select="xalan:nodeset($refs_)"/>
	
	<xsl:template match="/">
	
		<xsl:choose>
			<xsl:when test="$self_testing = 'true'">
				<xsl:call-template name="self_testing"/>
			</xsl:when>
			<xsl:otherwise>
			
				<!-- <redirect:write file="{$outpath}/{$docfile_name}.linearized.xml">
					<xsl:apply-templates select="xalan:nodeset($linearized_xml)" mode="print_as_xml"/>
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
							
							<xsl:if test="not($split-bibdata = 'true')">
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
							</xsl:if>
							
						</xsl:when>
						<xsl:otherwise><!-- no sub-part elements -->
							<xsl:apply-templates />
							
							<xsl:if test="not($split-bibdata = 'true')">
								<xsl:call-template name="insertTaskImageList"/>
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="adoption">
		<xsl:variable name="docfile"><xsl:call-template name="getDocFilename"/></xsl:variable>
		<redirect:open file="{$outpath}/{$docfile}"/>
		<xsl:apply-templates />
		<redirect:close file="{$outpath}/{$docfile}"/>
	</xsl:template>
	
	<xsl:template match="standard | standards-document">
		<xsl:variable name="docfile"><xsl:call-template name="getDocFilename"/></xsl:variable>
		<redirect:open file="{$outpath}/{$docfile}"/>
		<xsl:apply-templates />
		<redirect:close file="{$outpath}/{$docfile}"/>
	</xsl:template>
	
	
	<!-- <xsl:template match="adoption/text() | adoption-front/text()"/> -->
	
	<!-- <xsl:template match="/*"> -->
	<xsl:template match="//standard/front | //adoption/adoption-front | //standards-document/front">
	
		<xsl:variable name="docfile"><xsl:call-template name="getDocFilename"/></xsl:variable>
	
		<!-- <xsl:choose>
			<xsl:when test="$demomode = 'false'">
				<redirect:write file="{$outpath}/{$docfile}"> -->
					<!-- nat-meta -> iso-meta -> reg-meta -> std-meta -->
					<!-- <xsl:for-each select="nat-meta">
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
			<xsl:otherwise> --> <!-- demo mode -->
				
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
								
								<!-- <xsl:if test="not(../reg-meta) and not(../iso-meta)"> -->
									<xsl:call-template name="insertCommonAttributes"/>
								<!-- </xsl:if> -->
								
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
								
								<!-- <xsl:if test="not(../iso-meta)"> -->
									<xsl:call-template name="insertCommonAttributes"/>
								<!-- </xsl:if> -->
								
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
					
			<!-- </xsl:otherwise>
		</xsl:choose> -->
	
		
		

		<xsl:if test="$split-bibdata != 'true'">
			
			
			<xsl:if test="$inputformat = 'IEEE'">
				
				<xsl:variable name="contrib-groups_">
					<xsl:for-each select="std-meta/contrib-group">
						<xsl:copy-of select="."/>
					</xsl:for-each>
				</xsl:variable>
				<xsl:variable name="contrib-groups" select="xalan:nodeset($contrib-groups_)"/>
				
				<xsl:for-each select="sec[.//participants-sec]">
					<xsl:variable name="sectionsFolder"><xsl:call-template name="getSectionsFolder"/></xsl:variable>
					<!-- Participants lists -->
					<xsl:variable name="filename">
						<!-- 00-participants.adoc  -->
						<xsl:value-of select="$sectionsFolder"/><xsl:text>/00-participants</xsl:text><xsl:text>.</xsl:text><xsl:value-of select="$docfile_ext"/>
					</xsl:variable>
				
					<redirect:write file="{$outpath}/{$filename}">
						<!-- https://www.metanorma.org/author/ieee/topics/markup/#participants -->
						<xsl:apply-templates select="." mode="participants">
							<xsl:with-param name="contrib-groups" select="$contrib-groups"/>
						</xsl:apply-templates>
					</redirect:write>
				
					<redirect:write file="{$outpath}/{$docfile}">
						<xsl:text>include::</xsl:text><xsl:value-of select="$filename"/><xsl:text>[]</xsl:text>
						<xsl:text>&#xa;&#xa;</xsl:text>
					</redirect:write>
				
				</xsl:for-each>
				
				
				<xsl:for-each select="std-meta/abstract">
					<xsl:variable name="sectionsFolder"><xsl:call-template name="getSectionsFolder"/></xsl:variable>
					<xsl:variable name="section_name" select="local-name()"/>
					<xsl:variable name="filename">
						<xsl:value-of select="$sectionsFolder"/><xsl:text>/00-</xsl:text>
						<xsl:value-of select="$section_name"/><xsl:text>.</xsl:text><xsl:value-of select="$docfile_ext"/>
					</xsl:variable>
					
					<redirect:write file="{$outpath}/{$filename}">
						<xsl:text>&#xa;</xsl:text>
						<xsl:text>[abstract]</xsl:text>
						<xsl:text>&#xa;</xsl:text>
						<xsl:text>== Abstract</xsl:text>
						<xsl:text>&#xa;</xsl:text>
						<xsl:text>&#xa;</xsl:text>
						<xsl:apply-templates select="."/>
					</redirect:write>
					<redirect:write file="{$outpath}/{$docfile}">
						<xsl:text>include::</xsl:text><xsl:value-of select="$filename"/><xsl:text>[]</xsl:text>
						<xsl:text>&#xa;&#xa;</xsl:text>
					</redirect:write>
				</xsl:for-each>
			</xsl:if>
			
			<!-- if in front there are another elements, except xxx-meta -->
			<xsl:for-each select="*[local-name() != 'iso-meta' and local-name() != 'nat-meta' and local-name() != 'reg-meta' and local-name() != 'std-meta'] | ancestor::standards-document/back/ack[title = 'Acknowledgements']">
				<xsl:variable name="number_"><xsl:number /></xsl:variable>
				<xsl:variable name="number" select="format-number($number_, '00')"/>
				<xsl:variable name="section_name">
					<xsl:value-of select="@sec-type"/>
					<xsl:if test="not(@sec-type)">
						<xsl:choose>
							<xsl:when test="$inputformat = 'IEEE' and title = 'Introduction'">introduction</xsl:when>
							<xsl:otherwise><xsl:value-of select="@id"/></xsl:otherwise>
						</xsl:choose>
					</xsl:if>
					<xsl:if test="not(@sec-type) and not(@id)"><xsl:value-of select="local-name()"/></xsl:if>
				</xsl:variable>
				<xsl:variable name="sectionsFolder"><xsl:call-template name="getSectionsFolder"/></xsl:variable>
				<xsl:variable name="filename">
					<xsl:value-of select="$sectionsFolder"/><xsl:text>/00-</xsl:text>
					<xsl:if test="$inputformat = 'STS'">
						<xsl:value-of select="$number"/><xsl:text>-</xsl:text>
					</xsl:if>
					<xsl:value-of select="$section_name"/><xsl:text>.</xsl:text><xsl:value-of select="$docfile_ext"/>
				</xsl:variable>
				
				<xsl:choose>
					<xsl:when test="$one_document = 'false' and ((contains(@id, '_nat') or title = 'National foreword'))"/> <!-- skip National Foreword and another National clause--> <!-- $demomode = 'true' and  -->
					<xsl:when test="$one_document = 'false' and ((contains(@id, '_euro') or title = 'European foreword'))"/> <!-- skip European Foreword and another European clauses --> <!-- $demomode = 'true' and  -->
					<xsl:when test="$one_document = 'false' and (not(contains(@id, '_nat') or title = 'National foreword' or contains(@id, '_euro') or title = 'European foreword'))"/> <!-- skip Foreword and another clauses --> <!-- $demomode = 'true' and  -->
					<xsl:otherwise>
						<xsl:variable name="section_text"><xsl:apply-templates select="."/></xsl:variable>
						<xsl:if test="normalize-space($section_text) != ''">
							<redirect:write file="{$outpath}/{$filename}">
								<xsl:text>&#xa;</xsl:text>
								<xsl:if test="title = 'National foreword' or title = 'European foreword'">
									<xsl:text>[.preface]</xsl:text>
									<xsl:text>&#xa;</xsl:text>
								</xsl:if>
								<xsl:value-of select="$section_text"/>
							</redirect:write>
							<redirect:write file="{$outpath}/{$docfile}">
								<xsl:text>include::</xsl:text><xsl:value-of select="$filename"/><xsl:text>[]</xsl:text>
								<xsl:text>&#xa;&#xa;</xsl:text>
							</redirect:write>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
				
			</xsl:for-each>
			
			<!-- <xsl:apply-templates select="/standard/body"/>			
			<xsl:apply-templates select="/standard/back"/> -->
		</xsl:if>
		
	</xsl:template> <!--END: front -->
	
	<xsl:template name="insertCommonAttributes">
		<xsl:text>:mn-document-class: </xsl:text><xsl:value-of select="$sdo"/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:variable name="mn_output_extensions">
			<xsl:choose>
				<xsl:when test="$organization = 'BSI' or $organization = 'PAS'">xml,html,pdf,rxl</xsl:when>
				<xsl:otherwise>xml,html,doc,pdf,rxl</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:text>:mn-output-extensions: </xsl:text><xsl:value-of select="$mn_output_extensions"/> <!-- ,doc,html_alt -->
		<xsl:text>&#xa;</xsl:text>
		
		<xsl:text>:local-cache-only:</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>:data-uri-image: false</xsl:text>
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
		<xsl:variable name="std-ref_undated" select="normalize-space(std-ref[@type = 'undated'])"/>
		<xsl:variable name="name1" select="java:replaceAll(java:java.lang.String.new($std-ref_undated), '(\s|\h|/|‑)', '-')"/>
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
		
		<!-- = Title -->
		<xsl:apply-templates select="std-title-group/std-main-title"/>
		
		<!-- = ISO 8601-1 -->
		<xsl:apply-templates select="std-ident"/> <!-- * -> iso-meta -->
		<!-- :docnumber: 8601 -->
		<xsl:apply-templates select="std-ident/doc-number"/>
		<xsl:apply-templates select="std-designation[@content-type = 'full']" mode="docnumber"/>
		
		<!-- :docstatus: active -->
		<xsl:apply-templates select="/*/@article-status"/>
		
		<!-- :publisher: ISO;IEC -->
		<xsl:apply-templates select="std-ident/originator"/>
		<!-- :partnumber: 1 -->
		<xsl:apply-templates select="std-ident/part-number"/>		
		<!-- :edition: 1 -->
		<xsl:apply-templates select="std-ident/edition"/>		
		<!-- :draft: 2 -->
		<xsl:apply-templates select="std-ident/version"/>
		<!-- :copyright-year: 2019 -->
		<xsl:apply-templates select="permissions/copyright-year"/>
		
		<xsl:apply-templates select="permissions/copyright-holder/@copyright-owner[. != 'IEEE']"/>
		
		
		<xsl:variable name="dates_model_">
			<!-- :published-date: -->
			<xsl:apply-templates select="pub-date"/>
			<!-- :issued-date: -->
			<xsl:apply-templates select="approval/approval-date"/>
			<!-- :date: reaffirm -->
			<xsl:apply-templates select="reaffirm-date"/>
			<!-- :date: release 2020-01-01 -->
			<xsl:apply-templates select="release-date"/>
		</xsl:variable>
		<xsl:variable name="dates_model" select="xalan:nodeset($dates_model_)"/>
		<xsl:for-each select="$dates_model/*[not(self::date)]">
			<xsl:text>:</xsl:text><xsl:value-of select="local-name()"/><xsl:text>: </xsl:text><xsl:value-of select="."/>
			<xsl:text>&#xa;</xsl:text>
		</xsl:for-each>
		<!--  arbitrary date(s) -->
		<xsl:for-each select="$dates_model/date">
			<xsl:text>:date</xsl:text>
			<xsl:if test="position() &gt; 1">_<xsl:value-of select="position()"/></xsl:if>
			<xsl:text>: </xsl:text>
			<xsl:value-of select="@type"/>
			<xsl:text> </xsl:text>
			<xsl:value-of select="."/>
			<xsl:text>&#xa;</xsl:text>
		</xsl:for-each>
		
		
		<!-- :updates: -->
		<!-- :semantic-metadata-related-article-edition: -->
		<xsl:apply-templates select="std-title-group/alt-title/related-article"/>
		
		<!-- :uri: www.... -->
		<xsl:apply-templates select="self-uri"/>
		
		<!-- :language: en -->
		<xsl:apply-templates select="doc-ident/language"/>
		<xsl:if test="$inputformat = 'IEEE'">
			<xsl:text>:language: en</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		<!-- :title-intro-en: Date and time
		:title-main-en: Representations for information interchange
		:title-part-en: Basic rules
		:title-intro-fr: Date et l'heure
		:title-main-fr: Représentations pour l'échange d'information
		:title-part-fr: Règles de base -->
		<xsl:apply-templates select="title-wrap"/>
		<!-- <xsl:apply-templates select="std-title-group"/> -->
		
		<!-- :doctype: international-standard -->
		<xsl:variable name="doctype">
			<xsl:apply-templates select="std-ident/doc-type"/> <!--  |  ancestor::standards-document/@content-type -->
		</xsl:variable>
		<xsl:variable name="doctype2">
			<xsl:apply-templates select="std-title-group/std-main-title" mode="doctype"/>
		</xsl:variable>
		<xsl:text>:doctype: </xsl:text>
			<xsl:choose>
				<xsl:when test="$doctype = 'TR' or $doctype = 'tr'">technical-report</xsl:when>
				<xsl:when test="$doctype = 'TC' or $doctype = 'tc'">technical-corrigendum</xsl:when>
				<xsl:when test="$doctype = 'TS' or $doctype = 'ts'">technical-specification</xsl:when>
				<xsl:when test="$doctype = 'AMD' or $doctype = 'amd'">amendment</xsl:when>
				<xsl:when test="$doctype = 'DIR' or $doctype = 'dir'">directive</xsl:when>
				<xsl:when test="$doctype = 'IS' or $doctype = 'is'">international-standard</xsl:when>
				<xsl:when test="normalize-space($doctype) != ''"><xsl:value-of select="$doctype"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="$doctype2"/></xsl:otherwise>
			</xsl:choose>
		<xsl:text>&#xa;</xsl:text>
		
		<!-- :docstage: 60
		:docsubstage: 60 -->		
		<xsl:apply-templates select="doc-ident/release-version"/>
		
		<xsl:apply-templates select="/*/@std-status" mode="IEEE"/>
		
		<xsl:if test="ics[normalize-space() != '']">
			<xsl:text>:library-ics: </xsl:text>
			<xsl:for-each select="ics[normalize-space() != '']">
				<xsl:choose>
					<xsl:when test="ics-code"><xsl:value-of select="ics-code"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
				</xsl:choose>
				<xsl:if test="position() != last()">,</xsl:if>
			</xsl:for-each>
			<xsl:text>&#xa;</xsl:text>
			<!-- <xsl:if test="ics/ics-desc">
				<xsl:text>:semantic-metadata-ics-desc: </xsl:text>
				<xsl:for-each select="ics[normalize-space() != '']">
					<xsl:value-of select="ics-desc"/>
					<xsl:if test="position() != last()">,</xsl:if>
				</xsl:for-each>
				<xsl:text>&#xa;</xsl:text>
			</xsl:if> -->
		</xsl:if>
		
		<xsl:apply-templates select="custom-meta-group/custom-meta[meta-name = 'ISBN']/meta-value"/>
		
		<xsl:apply-templates select="custom-meta-group/custom-meta[meta-name = 'TOC Heading Level']/meta-value"/>
		
		<xsl:choose>
			<xsl:when test="$organization = 'BSI' or $organization = 'PAS'">
				
				<xsl:variable name="model_related_refs">
					<xsl:call-template name="build_sts_related_refs"/>
				</xsl:variable>
				
				<!-- Example: :bsi-related: Committee reference DEF/1; Draft for comment 20/30387670 DC -->
				<xsl:for-each select="xalan:nodeset($model_related_refs)//item">
					<xsl:if test="position() = 1">
						<xsl:text>:bsi-related: </xsl:text>
					</xsl:if>
					<xsl:value-of select="normalize-space(.)"/>
					<xsl:if test="position() != last()">; </xsl:if>
					<xsl:if test="position() = last()"><xsl:text>&#xa;</xsl:text></xsl:if>
				</xsl:for-each>
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
		
		<!-- :committee: -->
		<!-- :society: -->
		<xsl:apply-templates select="std-sponsor"/>
		
		<!-- :semantic-metadata-partner-secretariat: -->
		<xsl:apply-templates select="partner" />
		
		<!-- :keywords: -->
		<xsl:apply-templates select="kwd-group"/>
		
		<!-- :semantic-metadata-std-id-doi: -->
		<xsl:apply-templates select="std-id"/>
		
		<!-- ==================== -->
		<!-- std-xref processing  -->
		<!-- ==================== -->
		<xsl:variable name="relations_">
			<xsl:call-template name="getRelations"/>
		</xsl:variable>
		<xsl:variable name="relations" select="xalan:nodeset($relations_)"/>
		<xsl:for-each select="$relations/relation">
			<xsl:variable name="curr_type" select="@type"/>
			<xsl:if test="not(preceding-sibling::relation[@type = $curr_type])">
				<!-- select unique relation type -->
				<!-- EXAMPLE: `:informatively-cited-in: ISO 639;IEC 60050-112;W3C XML,Extensible Markup Language (XML)` -->
				<xsl:text>:</xsl:text>
				<xsl:value-of select="$curr_type"/>
				<xsl:text>: </xsl:text>
				<xsl:value-of select="."/>
				<!-- iteration on next relations with the same type -->
				<xsl:for-each select="following-sibling::relation[@type = $curr_type]">
					<xsl:text>;</xsl:text>
					<xsl:value-of select="."/>
				</xsl:for-each>
				<xsl:text>&#xa;</xsl:text>
			</xsl:if>
		</xsl:for-each>
		<!-- ==================== -->
		<!-- END: std-xref processing  -->
		<!-- ==================== -->
		
		
		<!-- :presentation-metadata-color-list-label: #009fe3 -->
		<xsl:apply-templates select="(//list-item[not(ancestor::non-normative-note)][1]/label/styled-content/@style[contains(., 'color:')])[1]" mode="presentation-metadata"/>
		
		<!-- :semantic-metadata-proj-id: 72028 -->
		<xsl:apply-templates select="doc-ident/proj-id"/>
		
		<!-- :semantic-metadata-suppl-type: RV -->
		<xsl:apply-templates select="std-ident/suppl-type"/>
		<!-- :semantic-metadata-suppl-number: 1 -->
		<xsl:apply-templates select="std-ident/suppl-number"/>
		<!-- :semantic-metadata-suppl-version: 2 -->
		<xsl:apply-templates select="std-ident/suppl-version"/>
		
		<!-- :semantic-metadata-dor: 2019-10-27 -->
		<!-- :semantic-metadata-dow: 2020-07-31 -->
		<!-- :semantic-metadata-dop: 2020-07-31 -->
		<!-- :semantic-metadata-doa: 2020-04-30 -->
		<xsl:apply-templates select="meta-date"/>
		
		<!-- :semantic-metadata-wi-number: 00279004 -->
		<xsl:apply-templates select="wi-number"/>
		
		<!-- :semantic-metadata-release-version-id: 29938632 -->
		<xsl:apply-templates select="release-version-id"/>
		
		<!-- :semantic-metadata-page-count: 39 -->
		<xsl:apply-templates select="page-count"/>
		
		<!-- :semantic-metadata-upi: 000000000030044270 -->
		<!-- :semantic-metadata-price-ref-pages: 39 -->
		<!-- :semantic-metadata-published-logo: ISO/IEC -->
		<!-- :semantic-metadata-generation-date: 2019-01-10 08:12:18 -->
		<!-- :semantic-metadata-originator-identifier: 062726 -->
		<!-- :semantic-metadata-colour-print: yes -->
		<!-- :semantic-metadata-conversion-version: eXtyles3716 -->
		<!-- :semantic-metadata-conversion-date: 2020-01-21 -->
		<!-- :semantic-metadata-perinorm-id: 000000000030314082 -->
		<!-- :semantic-metadata-version-history: Incorporating corrigendum January 2014, Incorporating corrigendum October 2014 -->
		<!-- :semantic-metadata-wi-number: 00389013 -->
		<!-- :semantic-metadata-release-version-id: 30878015 -->
		<!-- :semantic-metadata-metadata-update: 2017-03-08 11:17:37 -->
		<!-- :semantic-metadata-international: ISO 56003:2019(eqv) -->
		<!-- :semantic-metadata-isoviennaagreement: (E): ISO-lead -->
		<xsl:apply-templates select="custom-meta-group/custom-meta[not(meta-name = 'ISBN' or meta-name = 'TOC Heading Level')]"/>
		
		<!-- :semantic-metadata-copyright-statement:  All rights of exploitation in any form and ... -->
		<xsl:apply-templates select="permissions/copyright-statement"/>
		
		<!-- :semantic-metadata-xplore-article-id: 6457401 -->
		<xsl:apply-templates select="xplore-article-id"/>
		
		<!-- :semantic-metadata-xplore-issue: ... -->
		<xsl:apply-templates select="xplore-issued"/>
		
		<!-- :semantic-metadata-xplore-pub-id: ... -->
		<xsl:apply-templates select="xplore-pub-id"/>
		
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

		<!-- :stdid-pdf: -->
		<xsl:apply-templates select="product-num[@publication-format = 'online']"/>
		<!-- :stdid-print: -->
		<xsl:apply-templates select="product-num[@publication-format = 'print']"/>
		<!-- :isbn-pdf: -->
		<xsl:apply-templates select="isbn[@publication-format = 'online']"/>
		<!-- :isbn-print: -->
		<xsl:apply-templates select="isbn[@publication-format = 'print']"/>

		<!-- :semantic-metadata-open-access: -->
		<xsl:apply-templates select="ancestor::standards-document/@open-access"/>
		<!-- :semantic-metadata-revision: -->
		<!-- <xsl:apply-templates select="ancestor::standards-document/@revision"/> -->
		
		<!-- :semantic-metadata-collab-type-logo: -->
		<!-- :semantic-metadata-collab: -->
		<!-- :semantic-metadata-collab-type-accredited-by: -->
		<xsl:apply-templates select="contrib-group[.//collab-alternatives and not(contrib/@contrib-type='member')]"/>
		
		<!-- :semantic-metadata-funding-source-institution:
			:semantic-metadata-funding-source-institution-id:
			:semantic-metadata-award-group-id:
			:semantic-metadata-funding-statement
		-->
		<xsl:apply-templates select="funding-group"/>


		<!-- :working-group: -->
		<xsl:apply-templates select="(../sec/participants-sec/p[contains(text(), ' Working Group ') or contains(text(), ' subcommittee ')])[1]" mode="front_ieee"/>
		<!-- :balloting-group: -->
		<xsl:apply-templates select="(../sec/participants-sec/p[contains(text(), ' balloting group ') or contains(text(), ' individual balloting ')])[1]" mode="front_ieee"/>
		
	</xsl:template>
	
	<xsl:template match="std-title-group/std-main-title" mode="doctype">
		<!-- <xsl:text>:title-main: </xsl:text> -->
		<xsl:variable name="title"><xsl:apply-templates /></xsl:variable>
		<xsl:variable name="doctype" select="normalize-space(java:replaceAll(java:java.lang.String.new($title),$regex_ieee_title,'$1'))"/>
		<!-- Standard to standard
			Guide to guide
			Recommended Practice to recommended-practice
		-->
		<xsl:value-of select="java:toLowerCase(translate($doctype,'-',' '))"/>
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
		<xsl:variable name="adoc_title">
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
		</xsl:variable>
		<xsl:value-of select="normalize-space($adoc_title)"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="std-ident[ancestor::front or ancestor::adoption-front]/doc-number[normalize-space(.) != '']">
		<xsl:text>:docnumber: </xsl:text><xsl:call-template name="getDocNumber"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="std-ident[ancestor::front or ancestor::adoption-front]/originator[normalize-space(.) != '']">
		<xsl:if test="contains(., '/')">
			<xsl:text>:publisher: </xsl:text><xsl:value-of select="translate(., '/', ';')"/>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
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
	
	<xsl:template match="std-ident[ancestor::front or ancestor::adoption-front]/version[normalize-space(.) != '']">
		<xsl:text>:draft: </xsl:text><xsl:value-of select="."/>
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
	
	<xsl:template match="copyright-holder/@copyright-owner">
		<xsl:text>:copyright-holder: </xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template name="getCopyrightYear">
		<xsl:param name="value" select="."/>
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new($value), '^©(\s|\h)*', '')"/> <!-- remove copyright sign -->
	</xsl:template>
	
	<xsl:template match="pub-date[ancestor::front or ancestor::adoption-front]">
		<xsl:variable name="date">
			<xsl:choose>
				<xsl:when test="normalize-space(@iso-8601-date) != ''"><xsl:value-of select="@iso-8601-date"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="normalize-space(.)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="normalize-space($date) != ''">
			<xsl:choose>
				<xsl:when test="$inputformat = 'IEEE'">
					<xsl:choose>
						<xsl:when test="@date-type = 'published'">
							<!-- <xsl:text>:published-date: </xsl:text> -->
							<published-date><xsl:value-of select="$date"/></published-date>
						</xsl:when>
						<xsl:otherwise>
							<!-- <xsl:text>:date: </xsl:text><xsl:value-of select="@date-type"/><xsl:text> </xsl:text> -->
							<date type="{@date-type}"><xsl:value-of select="$date"/></date>
						</xsl:otherwise>
					</xsl:choose>
					<!-- <xsl:value-of select="$date"/>
					<xsl:text>&#xa;</xsl:text> -->
				</xsl:when>
				<xsl:otherwise>
					<!-- <xsl:text>:published-date: </xsl:text><xsl:value-of select="$date"/>
					<xsl:text>&#xa;</xsl:text> -->
					<published-date><xsl:value-of select="$date"/></published-date>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="release-date[ancestor::front or ancestor::adoption-front]">
		<xsl:if test="normalize-space() != ''">
			<!-- <xsl:text>:date: release </xsl:text><xsl:value-of select="."/>
			<xsl:text>&#xa;</xsl:text> -->
			<date type="release"><xsl:value-of select="."/></date>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="self-uri">
		<xsl:text>:</xsl:text>
		<xsl:if test="@content-type">
			<xsl:value-of select="@content-type"/><xsl:text>-</xsl:text>
		</xsl:if>
		<xsl:text>uri: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
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
					<xsl:text>:</xsl:text><xsl:value-of select="@type"/><xsl:text>-</xsl:text><xsl:value-of select="$lang"/><xsl:text>: </xsl:text><xsl:value-of select="normalize-space(.)"/>
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
				<xsl:text>:docstage:</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>:docsubstage:</xsl:text>
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
	
	<xsl:template match="custom-meta-group/custom-meta[meta-name = 'TOC Heading Level']/meta-value">
		<xsl:text>:toclevels: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="custom-meta-group/custom-meta[not(meta-name = 'ISBN' or meta-name = 'TOC Heading Level')]">
		<xsl:if test="not(preceding-sibling::custom-meta[meta-name = current()/meta-name])">
			<xsl:text>:semantic-metadata-</xsl:text><xsl:value-of select="translate(java:toLowerCase(java:java.lang.String.new(meta-name)), ' ', '-')"/><xsl:text>: </xsl:text><xsl:value-of select="normalize-space(meta-value)"/>
			<xsl:for-each select="following-sibling::custom-meta[meta-name = current()/meta-name]">
			<xsl:text>, </xsl:text>
			<xsl:if test="contains(meta-value, ',')">"</xsl:if>
			<xsl:value-of select="meta-value"/>
			<xsl:if test="contains(meta-value, ',')">"</xsl:if>
			</xsl:for-each>
		</xsl:if>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	
	<xsl:template match="list-item[not(ancestor::non-normative-note)]/label/styled-content/@style" mode="presentation-metadata">
		<xsl:variable name="value"><xsl:call-template name="getStyleColor"/></xsl:variable>
		<xsl:if test="$value != ''">
			<xsl:text>:presentation-metadata-color-list-label: </xsl:text><xsl:value-of select="$value"/>
		</xsl:if>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="doc-ident/proj-id[normalize-space() != '']">
		<xsl:text>:semantic-metadata-proj-id: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="std-ident/suppl-type[normalize-space() != '']">
		<xsl:text>:semantic-metadata-suppl-type: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="std-ident/suppl-number[normalize-space() != '']">
		<xsl:text>:semantic-metadata-suppl-number: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="std-ident/suppl-version[normalize-space() != '']">
		<xsl:text>:semantic-metadata-suppl-version: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="meta-date[normalize-space(@type) != '']">
		<xsl:text>:semantic-metadata-</xsl:text><xsl:value-of select="java:toLowerCase(java:java.lang.String.new(@type))"/><xsl:text>: </xsl:text><xsl:value-of select="normalize-space(.)"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="wi-number[normalize-space() != '']">
		<xsl:text>:semantic-metadata-wi-number: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="release-version-id[normalize-space() != '']">
		<xsl:text>:semantic-metadata-release-version-id: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="page-count[normalize-space(@count) != '']">
		<xsl:text>:semantic-metadata-page-count: </xsl:text><xsl:value-of select="@count"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="permissions/copyright-statement">
		<xsl:choose>
			<xsl:when test="$inputformat = 'IEEE'"><!-- skip --></xsl:when>
			<xsl:otherwise>
				<xsl:text>:semantic-metadata-copyright-statement: </xsl:text><xsl:value-of select="normalize-space(.)"/>
				<xsl:text>&#xa;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="xplore-article-id[normalize-space() != '']">
		<xsl:text>:semantic-metadata-xplore-article-id: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="xplore-issue[normalize-space() != '']">
		<xsl:text>:semantic-metadata-xplore-issue: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="xplore-pub-id[normalize-space() != '']">
		<xsl:text>:semantic-metadata-xplore-pub-id: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>	
	
	<!-- <xsl:variable name="regex_ieee_number">^.*?(\d+)-(\d+)$</xsl:variable> -->
	<xsl:variable name="regex_ieee_number">^IEEE Std (.*)-(\d+)$</xsl:variable>
	<xsl:template match="std-designation[@content-type = 'full']" mode="docnumber">
		<xsl:text>:docnumber: </xsl:text><xsl:value-of select="java:replaceAll(java:java.lang.String.new(.), $regex_ieee_number, '$1')"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="@article-status">
		<xsl:text>:docstatus: </xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="product-num[@publication-format = 'online']">
		<xsl:text>:stdid-pdf: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="product-num[@publication-format = 'print']">
		<xsl:text>:stdid-print: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="isbn[@publication-format = 'online']">
		<xsl:text>:isbn-pdf: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="isbn[@publication-format = 'print']">
		<xsl:text>:isbn-print: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="std-title-group">
		<!-- <xsl:apply-templates select="std-main-title"/> -->
	</xsl:template>
	
	<xsl:variable name="regex_ieee_title">^IEEE (Standard|Guide|Recommended Practice) for (.*)</xsl:variable>
	<xsl:template match="std-title-group/std-main-title">
		<!-- <xsl:text>:title-main: </xsl:text> -->
		<xsl:variable name="title"><xsl:apply-templates /></xsl:variable>
		<xsl:text>= </xsl:text><xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new($title),$regex_ieee_title,'$2'))"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="std-sponsor">
		<xsl:apply-templates select="committee"/>
		<xsl:apply-templates select="society"/>
	</xsl:template>
	
	<xsl:variable name="regex_society">^IEEE (.*)</xsl:variable>
	<xsl:template match="std-sponsor/committee">
		<xsl:variable name="committee_" select="normalize-space(.)"/>
		<xsl:variable name="committee">
			<xsl:choose>
				<xsl:when test="contains($committee_,' Society') and contains($committee_,' of the ')">
					<xsl:value-of select="substring-before($committee_,' of the ')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$committee_"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:text>:committee: </xsl:text><xsl:value-of select="$committee"/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:variable name="society">
			<xsl:if test="contains($committee_,' Society') and contains($committee_,' of the ')">
				<xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new(substring-after($committee_,' of the ')),$regex_society,'$1'))"/>
			</xsl:if>
		</xsl:variable>
		<xsl:if test="normalize-space($society)">
			<xsl:text>:society: </xsl:text><xsl:value-of select="$society"/>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="std-sponsor/society">
		<xsl:text>:society: </xsl:text><xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new(.),$regex_society,'$1'))"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="approval/approval-date">
		<xsl:variable name="date" select="normalize-space(@iso-8601-date)"/>
		<xsl:if test="$date != ''">
			<xsl:choose>
				<xsl:when test="@date-type = 'approved'">
					<!-- <xsl:text>:issued-date: </xsl:text> -->
					<issued-date><xsl:value-of select="$date"/></issued-date>
				</xsl:when>
				<xsl:otherwise>
					<!-- <xsl:text>:date: </xsl:text><xsl:value-of select="@date-type"/><xsl:text> </xsl:text> -->
					<date type="{@date-type}"><xsl:value-of select="$date"/></date>
				</xsl:otherwise>
			</xsl:choose>
			<!-- <xsl:value-of select="$date"/>
			<xsl:text>&#xa;</xsl:text> -->
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="reaffirm-date">
		<xsl:variable name="date" select="normalize-space(@iso-8601-date)"/>
		<xsl:if test="$date != ''">
			<!-- <xsl:text>:date: reaffirm </xsl:text><xsl:value-of select="$date"/>
			<xsl:text>&#xa;</xsl:text> -->
			<date type="reaffirm"><xsl:value-of select="$date"/></date>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="alt-title/related-article[@related-article-type = 'revision-of']">
		<xsl:text>:updates: </xsl:text><xsl:value-of select="std"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="alt-title/related-article[@related-article-type = 'edition']">
		<xsl:text>:semantic-metadata-related-article-edition: </xsl:text><xsl:value-of select="edition"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="partner/*">
		<!-- Example: :semantic-metadata-partner-secretariat: -->
		<xsl:text>:semantic-metadata-partner-</xsl:text><xsl:value-of select="local-name()"/><xsl:text>: </xsl:text>
		<xsl:text>"</xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>"</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="kwd-group">
		<xsl:choose>
			<xsl:when test="$inputformat = 'STS' or @kwd-group-type = 'AuthorFree'">
				<xsl:text>:keywords: </xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>:semantic-metadata-keywords-</xsl:text><xsl:value-of select="@kwd-group-type"/><xsl:text>: </xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:apply-templates/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="kwd-group/kwd">
		<xsl:value-of select="."/>
		<xsl:if test="following-sibling::*"><xsl:text>, </xsl:text></xsl:if>
	</xsl:template>
	
	<xsl:template match="std-meta/std-id[@std-id-type][normalize-space() != '']">
		<xsl:text>:semantic-metadata-std-id-</xsl:text><xsl:value-of select="@std-id-type"/><xsl:text>: </xsl:text>
		<xsl:apply-templates/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="contrib-group[.//collab-alternatives and not(contrib/@contrib-type='member')]" priority="2">
		<xsl:apply-templates mode="collab-alternatives"/>
	</xsl:template>
	
	<xsl:template match="contrib" mode="collab-alternatives">
		<xsl:apply-templates mode="collab-alternatives"/>
	</xsl:template>
	
	<xsl:template match="collab[@collab-type = 'logo']" mode="collab-alternatives">
		<xsl:text>:semantic-metadata-collab-type-logo: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="collab[not(@collab-type)]" mode="collab-alternatives">
		<xsl:text>:semantic-metadata-collab: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="collab[@collab-type = 'accredited-by']" mode="collab-alternatives">
		<xsl:text>:semantic-metadata-collab-type-accredited-by: </xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<!-- https://www.metanorma.org/author/ieee/topics/markup/#participants -->
	<xsl:template match="sec[.//participants-sec]" mode="participants">
		<xsl:param name="contrib-groups"/>
		<xsl:text>== Participants</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates>
			<xsl:with-param name="contrib-groups" select="$contrib-groups"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="sec[.//participants-sec]//*" priority="2">
		<xsl:param name="contrib-groups"/>
		<xsl:apply-templates>
			<xsl:with-param name="contrib-groups" select="$contrib-groups"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="sec[.//participants-sec]/title" priority="3"/>
	
	<xsl:template match="sec/participants-sec" priority="3">
		<xsl:param name="contrib-groups"/>
		<xsl:apply-templates>
			<xsl:with-param name="contrib-groups" select="$contrib-groups"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="sec/participants-sec[position() &gt; 1]/p" priority="3">
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="sec/participants-sec[1]/p" priority="3"> <!-- [contains(., ' Working Group ')] -->
		<xsl:param name="contrib-groups"/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>=== Working group</xsl:text>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="sec/participants-sec/p[contains(., ' balloting group ') or contains(., ' balloting committee ')]" priority="3">
		<xsl:param name="contrib-groups"/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>=== Balloting group</xsl:text>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="sec/participants-sec[position() &gt; 2]/p[contains(., ' Standards Board ')]" priority="3">
		<xsl:param name="contrib-groups"/>
		<xsl:choose>
			<xsl:when test="not(../preceding-sibling::participants-sec[count(preceding-sibling::participants-sec) &gt;= 2]/p[contains(normalize-space(.), ' Standards Board ')])">
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>=== Standards board</xsl:text>
				<xsl:text>&#xa;&#xa;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates />
				<xsl:text>&#xa;&#xa;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- <xsl:template match="sec/participants-sec/p" priority="3">
		<xsl:apply-templates/>
	</xsl:template> -->
	
	<xsl:template match="sec[.//participants-sec]//xref[@ref-type = 'contrib']" priority="3">
		<xsl:param name="contrib-groups"/>
		
		<xsl:variable name="contrib-group" select="$contrib-groups//contrib[@id = current()/@rid]"/>
		
		<xsl:variable name="isMemberOnly" select="normalize-space(count($contrib-groups//contrib[@id = current()/@rid]/preceding-sibling::contrib[@contrib-type!='member']) = 0)"/>
		
		<!-- <xsl:text>&#xa;DEBUG:&#xa;</xsl:text><xsl:apply-templates select="$contrib-group" mode="print_as_xml"/><xsl:text>&#xa;</xsl:text> -->
	
		<xsl:choose>
			<xsl:when test="($contrib-group/role or $contrib-group/collab-alternatives) and not($contrib-group/@emeritus='yes')">
				<xsl:text>item::</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				
				<xsl:if test="$contrib-group/name-alternatives">
					<xsl:text>name::: </xsl:text>
					<xsl:for-each select="$contrib-group/name-alternatives/string-name/*">
						<xsl:apply-templates/>
						<xsl:if test="position() != last()"><xsl:text> </xsl:text></xsl:if>
					</xsl:for-each>
					<xsl:text>&#xa;</xsl:text>
				</xsl:if>
				
				<xsl:if test="$contrib-group/collab-alternatives">
					<xsl:text>company::: </xsl:text>
					<xsl:for-each select="$contrib-group/collab-alternatives/collab">
						<xsl:apply-templates/>
						<xsl:if test="position() != last()"><xsl:text> </xsl:text></xsl:if>
					</xsl:for-each>
					<xsl:text>&#xa;</xsl:text>
				</xsl:if>
				
				<xsl:if test="$contrib-group/role">
					<xsl:text>role::: </xsl:text>
					<xsl:apply-templates select="$contrib-group/role"/>
					<xsl:text>&#xa;</xsl:text>
				</xsl:if>
			</xsl:when>
			
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="$isMemberOnly = 'true'">
						<xsl:text>* </xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>item:: </xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			
				<xsl:for-each select="$contrib-group/name-alternatives/string-name/* | $contrib-group/collab-alternatives/collab">
					<xsl:apply-templates/>
					<xsl:if test="position() != last()"><xsl:text> </xsl:text></xsl:if>
				</xsl:for-each>
				<xsl:if test="$contrib-group/@emeritus='yes'">*</xsl:if>
				<xsl:text>&#xa;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="ancestor::list-item and not(ancestor::list-item/following-sibling::list-item)">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="sec/participants-sec/p[contains(., ' Working Group ')]" mode="front_ieee">
		<xsl:text>:working-group: </xsl:text>
		<xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new(.),'^.* the (.+) Working Group .*$','$1'))"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="sec/participants-sec/p[contains(., ' subcommittee ')]" mode="front_ieee">
		<xsl:text>:working-group: </xsl:text>
		<xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new(.),'^.* the (.+) subcommittee .*$','$1'))"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="sec/participants-sec/p[contains(., ' balloting group ')]" mode="front_ieee">
		<xsl:text>:balloting-group: </xsl:text>
		<xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new(.),'^.* entity (.+) balloting group .*$','$1'))"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="sec/participants-sec/p[contains(., ' individual balloting ')]" mode="front_ieee">
		<xsl:text>:balloting-group: </xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>:balloting-group-type: individual</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="standards-document/@open-access">
		<xsl:text>:semantic-metadata-open-access: </xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<!-- <xsl:template match="standards-document/@revision">
		<xsl:text>:semantic-metadata-revision: </xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template> -->
	
	<xsl:template match="funding-group/award-group/funding-source/institution-wrap/institution">
		<xsl:text>:semantic-metadata-funding-source-institution: </xsl:text>
		<xsl:apply-templates/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="funding-group/award-group/funding-source/institution-wrap/institution-id">
		<xsl:text>:semantic-metadata-funding-source-institution-id: </xsl:text>
		<xsl:apply-templates/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="funding-group/award-group/award-id">
		<xsl:text>:semantic-metadata-award-group-id: </xsl:text>
		<xsl:apply-templates/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="funding-group/funding-statement">
		<xsl:text>:semantic-metadata-funding-statement: </xsl:text>
		<xsl:apply-templates/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="@std-status" mode="IEEE">
		<xsl:if test="$inputformat = 'IEEE'">
			<xsl:variable name="docstage">
				<xsl:choose>
					<xsl:when test=". = 'approved-draft' or . = 'unapproved-draft'">draft</xsl:when>
					<xsl:when test=". = 'inactive-superseded'">superseded</xsl:when>
					<xsl:when test=". = 'inactive-withdrawn'">withdrawn</xsl:when>
				</xsl:choose>
			</xsl:variable>
			<xsl:if test="normalize-space($docstage) != ''">
				<xsl:text>:docstage: </xsl:text><xsl:value-of select="$docstage"/>
				<xsl:text>&#xa;</xsl:text>
			</xsl:if>
		</xsl:if>
	</xsl:template>
		
	<!-- =========== -->
	<!-- end bibdata (standard/front) -->
	<!-- =========== -->
	
	<xsl:template match="front/notes" priority="2">
		<xsl:choose>
			<xsl:when test="$inputformat = 'IEEE'"><!-- skip --></xsl:when>
			<xsl:otherwise>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>[.preface,type="front_notes"]</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>== {blank}</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:apply-templates />
			</xsl:otherwise>
		</xsl:choose>
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
	
	<xsl:template match="front/sec[participants-sec]"/> <!-- skip -->
	
	<xsl:template match="front/sec[title = 'Notice to users']" priority="2">
		<xsl:choose>
			<xsl:when test="$inputformat = 'IEEE'"><!-- skip --></xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
		
	
	<xsl:template match="front/ack | back/ack[title = 'Acknowledgements']">
		<xsl:call-template name="setId"/>
		<xsl:text>[.preface</xsl:text>
		<xsl:if test="$inputformat = 'STS' or ancestor::back">
			<xsl:text>,heading=acknowledgements</xsl:text>
		</xsl:if>
		<xsl:text>]</xsl:text>
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
	
	<xsl:template match="body[count(*) = 1]/sec[@sec-type = 'scope']" priority="3">
		<xsl:variable name="docfile"><xsl:call-template name="getDocFilename"/></xsl:variable>
		<redirect:write file="{$outpath}/{$docfile}">
			<xsl:text>&#xa;</xsl:text>
			<xsl:call-template name="setId"/>
			<xsl:apply-templates />
		</redirect:write>
	</xsl:template>
	
	<!-- ======================== -->
	<!-- Normative references -->
	<!-- ======================== -->
	<xsl:template match="body/sec[@sec-type = 'norm-refs'] | front/sec[@sec-type = 'norm-refs'] | body/sec[title = 'Normative references' or list/@list-content = 'normative-references']" priority="2">
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
	<xsl:template match="sec[@sec-type = 'norm-refs' or title = 'Normative references' or list/@list-content = 'normative-references']/p" priority="2">
	
		<xsl:variable name="p_text">
			<xsl:if test="not(preceding-sibling::*[1][self::p]) and not(following-sibling::*[1][self::p])"> <!-- only one p in norm-refs -->
				<xsl:call-template name="p"/>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="no_norm_refs" select="normalize-space(starts-with(normalize-space($p_text), 'There are no normative references'))"/> <!-- true if 'p' starts with 'There are no ...'-->
		
		<xsl:if test="not(preceding-sibling::*[1][self::p]) and $no_norm_refs = 'false'"> <!-- first p in norm-refs -->
			<xsl:text>[NOTE,type=boilerplate]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>--</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		<xsl:if test="$no_norm_refs = 'false'">
			<xsl:call-template name="p"/>
		</xsl:if>
		<xsl:if test="not(following-sibling::*[1][self::p]) and $no_norm_refs = 'false'"> <!-- last p in norm-refs -->
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
	<xsl:template match="sec[@sec-type = 'terms']/title | sec[@sec-type = 'terms']//sec/title | sec[.//std-def-list]/title" priority="2">
	
		<xsl:choose>
			<xsl:when test="$inputformat = 'IEEE' and ../../self::body and . != 'Definitions'">
				<xsl:variable name="level">
					<xsl:call-template name="getLevel"/>
				</xsl:variable>				
				<xsl:value-of select="$level"/>
				<xsl:text> </xsl:text>
				<!-- From:https://www.metanorma.org/author/topics/document-format/section-terms/#clause-title
					It is recommended to use the "Terms and definitions" title for the clause heading regardless of the content contained — Metanorma will automatically render the correct clause title. -->
				<xsl:text>Terms and definitions</xsl:text> 
				<xsl:text>&#xa;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="title"/>
			</xsl:otherwise>
		</xsl:choose>
	
		
		<xsl:if test="ancestor::sec[java:toLowerCase(java:java.lang.String.new(title)) = 'terms and definitions'] or ancestor::sec[java:toLowerCase(java:java.lang.String.new(title)) = 'definitions'][.//std-def-list]">
			<xsl:if test="not(following-sibling::*[1][self::term-sec] or following-sibling::*[1][self::sec])"> <!-- if there are elements after title -->
				<xsl:text>[.boilerplate]</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:variable name="level">
					<xsl:call-template name="getLevel">
						<xsl:with-param name="addon">1</xsl:with-param>
					</xsl:call-template>
				</xsl:variable>
				<xsl:value-of select="$level"/>
				<!-- <xsl:choose> -->
					<!-- if there isn't paragraph after title -->
					<!-- https://www.metanorma.org/author/topics/document-format/section-terms/#overriding-predefined-text -->
					<!--<xsl:when test="following-sibling::*[1][self::term-sec] or following-sibling::*[1][self::sec]">
						<xsl:text> {blank}</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text> My predefined text</xsl:text>
					</xsl:otherwise>
				</xsl:choose> -->
				<xsl:text> My predefined text</xsl:text>
				<xsl:text>&#xa;</xsl:text>
			</xsl:if>
		</xsl:if>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="std-def-list | std-def-list/std-def-list-item">
		<xsl:apply-templates />
	</xsl:template>
	
	<!-- term -->
	<xsl:template match="std-def-list-item[x]/term">
		<xsl:variable name="level">
			<xsl:for-each select="ancestor::std-def-list-item[1]">
				<xsl:call-template name="getLevel"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="$level"/><xsl:text> </xsl:text>
		<xsl:variable name="term"><xsl:apply-templates /></xsl:variable>
		<xsl:variable name="regex_term_preferred">^([^\(]*)\((.+)\)$</xsl:variable>
		<xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new($term),$regex_term_preferred,'$1'))"/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:variable name="preferred" select="normalize-space(java:replaceAll(java:java.lang.String.new($term),$regex_term_preferred,'$2'))"/>
		<xsl:if test="$preferred != '' and $preferred != $term">
			<xsl:text>preferred:[</xsl:text><xsl:value-of select="$preferred"/><xsl:text>]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="std-def-list-item/x[normalize-space() = ':']"/>
	
	<xsl:template match="std-def-list-item[x]/def">
		<xsl:apply-templates />	
	</xsl:template>
	
	<!-- definition list item -->
	<xsl:template match="std-def-list-item[not(x)]/term">
		<xsl:apply-templates />
		<xsl:text>:: </xsl:text>
	</xsl:template>
	
	<xsl:template match="std-def-list-item[not(x)]/def">
		<xsl:apply-templates />
		<xsl:apply-templates select="../editing-instruction">
			<xsl:with-param name="process">true</xsl:with-param>
		</xsl:apply-templates>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="std-def-list-item[not(x)]/editing-instruction" priority="2">
		<xsl:param name="process">false</xsl:param>
		<xsl:if test="$process = 'true'">
			<xsl:text>&#xa;+&#xa;</xsl:text>
			<xsl:call-template name="editing-instruction"/>
		</xsl:if>
	</xsl:template>
	<xsl:template match="std-def-list-item[not(x)]/editing-instruction/p" priority="2">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="std-def-list-item[not(x)]/def/p" priority="2">
		<xsl:apply-templates />
	</xsl:template>
	
	<!-- ======================== -->
	<!-- END Terms and definitions -->
	<!-- ======================== -->
	
	
	<xsl:template match="body/sec | body[count(*) = 1]/sec[@sec-type = 'scope']/sec">
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
	<xsl:template match="sec[@sec-type = 'index'] | back/sec[@id = 'ind' or @id = 'sec_ind']" priority="2">
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
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="tbx:langSet">
		<xsl:for-each select="ancestor::tbx:termEntry[1]">
			<xsl:variable name="level">
				<xsl:call-template name="getLevel"/>
			</xsl:variable>
			<xsl:value-of select="$level"/><xsl:text> </xsl:text>
		</xsl:for-each>
		
		<xsl:apply-templates select=".//tbx:term" mode="term"/>	
		<xsl:apply-templates select=".//tbx:usageNote" mode="term"/>	
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		
		<xsl:apply-templates />

	</xsl:template>
	
	<xsl:template match="tbx:langSet/text()"/>
	<!-- <xsl:template match="text()[. = '&#xa;']"/> -->
	
	<xsl:template match="tbx:langSet/@xml:lang">
		<xsl:if test=". != $language"> <!-- if lang is different than document main language, for instance 'fr' for 'en' document -->
			<!-- Example:
				[%metadata]
				language:: fre
			-->
			<xsl:text>language:: </xsl:text>
			<xsl:value-of select="."/>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="title" name="title">
		<xsl:variable name="ace_tag">
			<xsl:apply-templates select="preceding-sibling::label/node()[1][self::named-content[@content-type = 'ace-tag']]"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="parent::sec/@sec-type = 'foreword'">
				<xsl:text>== </xsl:text>
				
				<xsl:variable name="title_text">
					<xsl:value-of select="$ace_tag"/>
					<xsl:apply-templates />
					<xsl:call-template name="addIndexTerms"/>
				</xsl:variable>
				<xsl:value-of select="$title_text"/>
				<xsl:if test="$title_text = ''">
					<xsl:text>{blank}</xsl:text>
				</xsl:if>
				
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
				<xsl:text> </xsl:text>
				
				<xsl:variable name="title_text">
					<xsl:value-of select="$ace_tag"/>
					<xsl:variable name="title_text_">
						<xsl:apply-templates />
					</xsl:variable>
					<xsl:value-of select="normalize-space($title_text_)"/>
					<xsl:if test="not(ancestor::sec[@sec-type = 'norm-refs'])">
						<xsl:call-template name="addIndexTerms"/>
					</xsl:if>
				</xsl:variable>
				<xsl:value-of select="$title_text"/>
				<xsl:if test="$title_text = ''">
					<xsl:text>{blank}</xsl:text>
				</xsl:if>
				
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>&#xa;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	<!-- remove Section ... from start of title -->
	<xsl:template match="title/node()[1][self::text()][java:org.metanorma.utils.RegExHelper.matches($regexSectionTitle, normalize-space()) = 'true']">
		<xsl:choose>
			<xsl:when test="parent::*[not(label) and not(@sec-type) and not(ancestor::*[@sec-type]) and not(title = 'Index')]">
				<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),$regexSectionTitle,'$4')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
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
					<xsl:when test="not(bold) and ancestor::sec[parent::body]//tbx:term[bold]">preferred</xsl:when> <!-- special case for https://github.com/metanorma/metanorma-iso/issues/765: when there is a term in bold -->
					<xsl:otherwise>alt</xsl:otherwise>
				</xsl:choose>
				<xsl:text>:[</xsl:text>
				<xsl:apply-templates />
				<xsl:text>]</xsl:text>
			</xsl:otherwise>			
		</xsl:choose>
		
		<xsl:variable name="metadata">
			<xsl:apply-templates select="ancestor::tbx:langSet/@xml:lang"/>
			<xsl:apply-templates select="../tbx:termType" mode="term"/>
			<xsl:apply-templates select="../tbx:partOfSpeech" mode="term"/>
		</xsl:variable>
		<xsl:if test="normalize-space($metadata) != ''">
			<xsl:text>&#xa;&#xa;</xsl:text>
			<xsl:text>[%metadata]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:value-of select="$metadata"/>
		</xsl:if>
		
		<xsl:apply-templates select="ancestor::tbx:langSet/tbx:subjectField" mode="term"/>
		
	</xsl:template>
	
	<xsl:template match="tbx:term[count(node()) = 1]/bold" priority="2">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="tbx:subjectField"/>
	<xsl:template match="tbx:subjectField" mode="term">
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>domain:[</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>]</xsl:text>
	</xsl:template>
	
	<xsl:template match="tbx:termType" mode="term">
		<xsl:choose>
			<xsl:when test="@value = 'acronym'">
				<xsl:text>abbreviation-type:: </xsl:text><xsl:value-of select="@value"/>
			</xsl:when>
			<xsl:when test="@value = 'symbol'">
				<xsl:text>letter-symbol:: true</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>type:: </xsl:text>
					<xsl:choose>
						<xsl:when test="@value = 'fullForm'">
							<xsl:text>full</xsl:text>
						</xsl:when>
						<!-- <xsl:when test="@value = 'formula'">
						<xsl:when test="@value = 'equation'"> -->
						<xsl:when test="@value = 'variant'">full</xsl:when>
						<xsl:otherwise><xsl:value-of select="@value"/></xsl:otherwise> <!-- Example: abbreviation -->
					</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="tbx:partOfSpeech" mode="term">
		<xsl:text>grammar::</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:choose>
			<xsl:when test="@value = 'noun'">isNoun</xsl:when>
			<xsl:when test="@value = 'verb'">isVerb</xsl:when>
			<xsl:when test="@value = 'adj'">isAdjective</xsl:when>
			<xsl:when test="@value = 'adv'">isAdverb</xsl:when>
			<xsl:otherwise>is<xsl:value-of select="@value"/></xsl:otherwise>
		</xsl:choose>
		<xsl:text>::: true</xsl:text>
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
	
	
	<xsl:template match="tbx:definition">
		<xsl:variable name="text">
			<xsl:apply-templates />
		</xsl:variable>
		
		<xsl:variable name="domain" select="normalize-space(java:replaceAll(java:java.lang.String.new($text), $regex_term_domain, '$2'))"/>
		<xsl:variable name="definition" select="java:replaceAll(java:java.lang.String.new($text), $regex_term_domain, '$4')"/>
		
		<xsl:if test="$domain != ''">
			<xsl:text>domain:[</xsl:text>
			<xsl:value-of select="$domain"/>
			<xsl:text>]</xsl:text>
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
		
		<xsl:value-of select="$definition"/>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<!-- =============== -->
	<!-- tbx:see  -->
	<!-- =============== -->
	<xsl:template match="tbx:see">
		<xsl:text>NOTE: </xsl:text>
		<xsl:variable name="lang" select="ancestor::tbx:langSet/@xml:lang"/>
		<xsl:choose>
			<xsl:when test="$lang = 'en' or $lang = ''">See</xsl:when>
			<xsl:when test="$lang = 'fr'">Voir</xsl:when>
			<xsl:when test="$lang = 'ru'">См.</xsl:when>
		</xsl:choose>
		<xsl:text> </xsl:text>
		<xsl:apply-templates select="@target"/>
		<xsl:apply-templates />
		
		<xsl:choose>
			<xsl:when test="$lang = 'en' or $lang = ''"> for more information.</xsl:when>
			<xsl:when test="$lang = 'fr'"> pour plus d'informations.</xsl:when>
			<xsl:when test="$lang = 'ru'"> для дополнительной информации.</xsl:when>
		</xsl:choose>
		
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	<xsl:template match="tbx:see/@target">
		<xsl:text>&lt;&lt;</xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>&gt;&gt;</xsl:text>
	</xsl:template>
	<!-- =============== -->
	<!-- END: tbx:see  -->
	<!-- =============== -->
	
	<xsl:template match="tbx:tig"/>
	
	<xsl:template match="tbx:usageNote"/>
	<xsl:template match="tbx:usageNote" mode="term">
		<xsl:text>&#xa;&#xa;</xsl:text>
		<xsl:text>[%metadata]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>field-of-application:: </xsl:text>
		<xsl:apply-templates/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="label"/>
	
	<xsl:variable name="commentary_on">COMMENTARY ON</xsl:variable>
	
	<xsl:template match="p" name="p">
		<xsl:if test="ancestor::non-normative-example and not(preceding-sibling::p) and normalize-space(preceding-sibling::node()[1]) != '' and not(preceding-sibling::*[1][self::label])"><xsl:text>&#xa;&#xa;</xsl:text></xsl:if>
		
		<xsl:variable name="isFirstPinCommentary" select="starts-with(normalize-space(), $commentary_on) and 
		(starts-with(normalize-space(.//italic/text()), $commentary_on) or starts-with(normalize-space(.//italic2/text()), $commentary_on))"/>
		<xsl:choose>
			<xsl:when test="$isFirstPinCommentary = 'true'"> <!-- COMMENTARY ON -->
				<xsl:text>[NOTE,type=commentary</xsl:text>
				<!-- determine commentary target -->
				<xsl:variable name="commentary_target">
					<xsl:choose>
						<xsl:when test=".//xref"><xsl:value-of select=".//xref/@rid"/></xsl:when>
						<xsl:otherwise>
							<!-- <xsl:variable name="text_target" select=".//*[contains(local-name(),'bold')]"/>
							<xsl:if test="ancestor::*[@id and label][1]/label = $text_target">
								<xsl:value-of select="ancestor::*[@id and label][1]/@id"/>
							</xsl:if> -->
							<xsl:value-of select="parent::*/@id"/>
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
				<xsl:variable name="p_text">
					<xsl:apply-templates />
				</xsl:variable>
				<xsl:if test="@specific-use = 'indent' and not(ancestor::list)">
					<xsl:if test="substring($p_text, 1, 2) != '. ' and substring($p_text, 1, 2) != '* '"> <!-- if it is not a list --> 
						<xsl:text>[align=indent]</xsl:text>
						<xsl:text>&#xa;</xsl:text>
					</xsl:if>
				</xsl:if>
				
				<xsl:variable name="operator">
					<xsl:call-template name="getInsDel"/>
				</xsl:variable>
				
				<xsl:variable name="align">
					<xsl:call-template name="getAlignment_style-type"/>
				</xsl:variable>
				<xsl:if test="$align != ''">
					<xsl:text>[align=</xsl:text><xsl:value-of select="$align"/><xsl:text>]</xsl:text>
					<xsl:text>&#xa;</xsl:text>
				</xsl:if>
				
				
				<!-- <xsl:if test="not(parent::fig)">
					<xsl:if test="@style-type = 'align-center'">
						<xsl:text>[align=center]</xsl:text>
							<xsl:text>&#xa;</xsl:text>
					</xsl:if>
				</xsl:if> -->
				<!-- <xsl:if test="count(node()[normalize-space() != '']) = 1 and styled-content[@style='text-alignment: center']">
					<xsl:text>[align=center]</xsl:text>
						<xsl:text>&#xa;</xsl:text>
				</xsl:if> -->
				
				<xsl:if test="not($inputformat = 'IEEE' and contains($p_text,'Bibliographical references are') and parent::app and following-sibling::ref-list)">
					<xsl:value-of select="$operator"/><xsl:if test="$operator != ''"><xsl:text>:[</xsl:text></xsl:if>
					
					<!-- <xsl:value-of select="$p_text"/> -->
					<!-- remove space at the end if paragraph (occurs due pretty-print view in the source XML) -->
					<xsl:value-of select="java:replaceAll(java:java.lang.String.new($p_text),' $','')"/>
					
					<xsl:if test="$operator != ''"><xsl:text>]</xsl:text></xsl:if>
					
					<xsl:text>&#xa;</xsl:text>
					<xsl:variable name="isLastPinCommentary" select="preceding-sibling::p[starts-with(normalize-space(), $commentary_on) and 
								(starts-with(normalize-space(.//italic/text()), $commentary_on) or starts-with(normalize-space(.//italic2/text()), $commentary_on))] and
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
				</xsl:if>
				
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
		<xsl:variable name="target" select="@target"/>
		<xsl:variable name="space_before"><xsl:if test="local-name(preceding-sibling::node()[1]) != ''"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		<xsl:variable name="following_first_char" select="substring(following-sibling::node()[1],1,1)"/>
		
		<xsl:variable name="space_after"><xsl:if test="local-name(following-sibling::node()[1]) != '' and not($following_first_char = '.' or 
		$following_first_char = ',')"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		<xsl:value-of select="$space_before"/>
	
		<xsl:variable name="target_number" select="substring-after($target, 'term_')"/>
		<xsl:variable name="term">
			<xsl:choose>
				<xsl:when test="contains(., concat('(', $target_number, ')'))"> <!-- example: concept entry (3.5) -->
					<xsl:value-of select="normalize-space(substring-before(., concat('(', $target_number, ')')))"/>
				</xsl:when>
				<xsl:when test="contains(., concat(' ', $target_number, ')'))"> <!-- example: vocational competence (see 3.26) -->
					<xsl:value-of select="normalize-space(substring-before(., '('))"/>
				</xsl:when>
				<xsl:when test="translate(., '01234567890.', '') = ''"></xsl:when><!-- if digits and dot only, example 3.13 -->
				<xsl:otherwise>
					<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- <xsl:variable name="term_real" select="normalize-space(//*[@id = current()/@target]//tbx:term[1])"/> -->
		<!-- <xsl:variable name="term_real" select="normalize-space(key('ids', current()/@target)//tbx:term[1])"/> -->
		
		<xsl:variable name="term_real">
			<xsl:for-each select="$updated_xml"> <!-- change context -->
				<xsl:value-of select="normalize-space(key('ids', $target)//tbx:term[1])"/>
			</xsl:for-each>
		</xsl:variable>

		<xsl:call-template name="insertTermReference">
			<xsl:with-param name="term" select="$term_real"/>
			<xsl:with-param name="rendering" select="$term"/>
		</xsl:call-template>

		<xsl:value-of select="$space_after"/>

	</xsl:template>
	
	<xsl:template match="tbx:entailedTerm[@xtarget]">
		<!-- Example: {{<<bibliographic-anchor>>,term}} -->
		<xsl:text>{{&lt;&lt;</xsl:text>
		<xsl:value-of select="@xtarget"/>
		<xsl:text>&gt;&gt;,</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>}}</xsl:text>
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
	
	<xsl:template match="non-normative-note[count(*[not(local-name() = 'label')]) &gt; 1 or @content-type = 'warning' or @content-type = 'important' or @content-type = 'caution']" priority="2">
		<xsl:choose>
			<xsl:when test="@content-type = 'warning' or @content-type = 'important' or @content-type = 'caution'">
				<xsl:text>[</xsl:text><xsl:value-of select="java:toUpperCase(java:java.lang.String.new(@content-type))"/><xsl:text>]</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>[NOTE]</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
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
		<!-- move ace-tag from start of label into start of note body -->
		<xsl:apply-templates select="label/node()[1][self::named-content[@content-type = 'ace-tag']]"/>
		<xsl:apply-templates/>
		<xsl:choose>
			<xsl:when test="parent::list-item and preceding-sibling::*[1][not(self::label)] and not(following-sibling::*)"></xsl:when>
			<xsl:otherwise><xsl:text>&#xa;</xsl:text></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="editing-instruction" name="editing-instruction">
		<xsl:text>EDITOR: </xsl:text>
		<xsl:apply-templates/>
		<xsl:text>&#xa;</xsl:text>
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
	<xsl:template match="std" name="std">
	
		<xsl:variable name="space_before"><xsl:if test="local-name(preceding-sibling::node()[1]) != ''"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		<xsl:variable name="space_after"><xsl:if test="local-name(following-sibling::node()[1]) != ''"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		<xsl:value-of select="$space_before"/>
		
		<xsl:if test="italic[std-ref]">_</xsl:if>
		<xsl:if test="italic2[std-ref]">__</xsl:if>
		<xsl:if test="bold[std-ref]">*</xsl:if>
		<xsl:if test="bold2[std-ref]">**</xsl:if>
		
		<xsl:variable name="model_std_">
			<xsl:choose>
				<xsl:when test="$inputformat = 'IEEE'">
					<xsl:call-template name="build_ieee_model_std"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="build_sts_model_std"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="model_std" select="xalan:nodeset($model_std_)"/>
		
		<!-- <xsl:text>&#xa;DEBUG&#xa;</xsl:text>
		<xsl:for-each select="@*">
			<xsl:text>@</xsl:text><xsl:value-of select="local-name()"/><xsl:text>=</xsl:text><xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
		</xsl:for-each>
		<xsl:apply-templates select="$model_std" mode="print_as_xml"/>
		<xsl:text>&#xa;</xsl:text> -->
		
		
		<xsl:variable name="localities">
			<!-- put locality (-ies) -->
			<xsl:for-each select="$model_std/*[self::locality or self::localityValue or self::localityConj][normalize-space() != '']">
				<xsl:variable name="node_position" select="position()"/>
				<xsl:choose>
					<xsl:when test="self::localityValue">
						<xsl:text>=</xsl:text>
						<xsl:value-of select="."/>
					</xsl:when>
					<xsl:when test="self::localityConj">
						<xsl:choose>
							<xsl:when test="$node_position = 1"><xsl:text>,</xsl:text></xsl:when>
							<xsl:otherwise><xsl:text>;</xsl:text></xsl:otherwise>
						</xsl:choose>
						<xsl:value-of select="."/>
						<xsl:text>!</xsl:text>
					</xsl:when>
					<xsl:otherwise> <!-- locality -->
						<xsl:variable name="locality" select="."/>
						<xsl:variable name="count_current_locality" select="count(../locality[. = $locality])"/>
						
						<!-- As with cross-references, more than two references combined by `and` should be marked up
								with semicolons, e.g. `<<ref1,clause=3.2;clause=4.7;clause=4.9;clause=9>>` or
								`<<ref1,clause=3.2;and!clause=4.7;and!clause=4.9;and!clause=9>>`. -->
						<xsl:choose>
							<xsl:when test="$node_position != 1 and $count_current_locality &gt; 2 and following-sibling::localityConj">
								<xsl:text>;</xsl:text>
								<xsl:value-of select="following-sibling::localityConj[1]"/>
								<xsl:text>!</xsl:text>
							</xsl:when>
							<xsl:when test="not(preceding-sibling::*[1][self::localityConj])">
								<xsl:text>,</xsl:text>
							</xsl:when>
						</xsl:choose>
						<!-- <xsl:if test="following-sibling::localityConj[1][. = 'to']">
							<xsl:text>from!</xsl:text>
						</xsl:if> -->
						<xsl:if test="@droploc = 'true'">droploc%</xsl:if>
						<xsl:value-of select="$locality"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		
		<!-- $referenceText='<xsl:value-of select="$referenceText"/>' -->
		
		<!-- <xsl:choose>
			<xsl:when test="$model_std/reference/@hidden = 'true' and java:org.metanorma.utils.RegExHelper.matches($start_standard_regex, $referenceText) = 'true'">
				<xsl:text>std-link:[</xsl:text>
					<xsl:value-of select="$referenceText"/>
					<xsl:for-each select="$model_std/not_locality">
						<xsl:text> </xsl:text><xsl:value-of select="."/>
					</xsl:for-each>
					<xsl:value-of select="$localities"/>
				<xsl:text>]</xsl:text>
			</xsl:when>
			
			<xsl:otherwise> -->
				<xsl:text>&lt;&lt;</xsl:text>
				
					<!-- put reference -->
					<xsl:value-of select="java:replaceAll(java:java.lang.String.new($model_std/reference),'_{2,}','_')"/>
					
					<xsl:value-of select="$localities"/>
					
					
					<xsl:if test="normalize-space($localities) = ''"> <!-- omit reference text if there is locality, otherwise reference text override localities  -->
						
						<!-- reference's text -->
						<xsl:variable name="referenceText_">
							<xsl:for-each select="$model_std/referenceText">
								<xsl:if test="position() != 1">
									<xsl:text>,</xsl:text>
								</xsl:if>
								<xsl:value-of select="."/>
							</xsl:for-each>
						</xsl:variable>
						<xsl:variable name="referenceText" select="translate($referenceText_, '&#xA0;‑', ' -')"/>
						
						<!-- find reference in Bibliography/Normative References section -->
						<xsl:variable name="ref_by_id_" select="$refs//ref[@id = $model_std/reference or 
											@id2 = $model_std/reference or @id3 = $model_std/reference or @id4 = $model_std/reference or @id5 = $model_std/reference]"/>
						<xsl:variable name="ref_by_id" select="xalan:nodeset($ref_by_id_)"/>
						
						<!-- reference's text from Bibliography/Normative References section -->
						<xsl:variable name="refs_referenceText" select="$ref_by_id/@referenceText"/> <!-- note: @referenceText was added at ref_fix step -->
						
						<!-- note: @label_number was added on ref_fix step -->
						<xsl:if test="$model_std/not_locality or 
							($refs_referenceText != '' and not($refs_referenceText = $referenceText)) or
							java:org.metanorma.utils.RegExHelper.matches($start_standard_regex, normalize-space($referenceText)) = 'false' or
							((contains($referenceText, 'series') or contains($referenceText, 'parts')) and not($model_std/locality)) or
							$ref_by_id/@label_number or 
							$model_std/reference/@isHidden = 'true'">
							 
							 <!-- java:org.metanorma.utils.RegExHelper.matches($start_standard_regex, normalize-space($referenceText)) = 'false' or -->
							 
							<xsl:if test="$referenceText != ''">
								<xsl:text>,</xsl:text>
								<xsl:value-of select="$referenceText"/>
							</xsl:if>
							
							<xsl:for-each select="$model_std/not_locality">
								<xsl:text> </xsl:text><xsl:value-of select="."/>
							</xsl:for-each>
							
						</xsl:if>
						
					</xsl:if>
			
				<xsl:text>&gt;&gt;</xsl:text>
			<!-- </xsl:otherwise>
		</xsl:choose> -->
		
		
		<xsl:if test="italic[std-ref]">_</xsl:if>
		<xsl:if test="italic2[std-ref]">__</xsl:if>
		<xsl:if test="bold[std-ref]">*</xsl:if>
		<xsl:if test="bold2[std-ref]">**</xsl:if>
		
		<!-- add Digital Object Identifier link -->
		<xsl:if test=".//processing-instruction('doi')">
			<xsl:call-template name="insertPI">
				<xsl:with-param name="name">doi</xsl:with-param>
				<xsl:with-param name="value" select=".//processing-instruction('doi')"/>
			</xsl:call-template>
		</xsl:if>
		
		<xsl:value-of select="$space_after"/>
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
	
	<xsl:template match="std/std-organization">
		<xsl:apply-templates/>
		<xsl:if test="not(starts-with(following-sibling::node()[1],' '))"/><xsl:text> </xsl:text>
	</xsl:template>
	
	<xsl:template match="ref//std-ref"> <!-- sec[@sec-type = 'norm-refs'] -->
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="ref/std/std-id"/> <!-- for IEC -->
	
	
	<!-- ================= -->
	<!-- tbx:source processing -->
	<!-- ================= -->
	<xsl:template match="tbx:source">
	
		<xsl:variable name="model_term_source_">
			<xsl:call-template name="build_sts_model_term_source"/>
		</xsl:variable>
		<xsl:variable name="model_term_source" select="xalan:nodeset($model_term_source_)"/>
	
		<!-- <xsl:for-each select="$model_term_source/*">
			<xsl:value-of select="local-name()"/>=<xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
			<xsl:for-each select="@*">
				<xsl:text>@</xsl:text><xsl:value-of select="local-name()"/>=<xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
			</xsl:for-each>
		</xsl:for-each> -->
	
		<xsl:text>[.source</xsl:text>
		<xsl:choose>
			<xsl:when test="$model_term_source/adapted">%adapted</xsl:when>
			<!-- <xsl:when test="$model_term_source/modified_from">%modified</xsl:when> -->
			<xsl:when test="$model_term_source/quoted">%quoted</xsl:when>
		</xsl:choose>
		<xsl:text>]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		
		<xsl:variable name="isHidden" select="normalize-space($model_term_source/reference/@hidden = 'true')"/>
		
		<xsl:text>&lt;&lt;</xsl:text>
			
			<!-- put reference -->
			<xsl:variable name="term_source_reference" select="$model_term_source/reference"/>
			<xsl:variable name="reference">
				<xsl:call-template name="getReference_std">
					<xsl:with-param name="std-id" select="normalize-space($term_source_reference)"/>
				</xsl:call-template>
			</xsl:variable>
			<!-- <xsl:if test="normalize-space($reference) = ''">hidden_bibitem_</xsl:if> -->
			<xsl:value-of select="java:replaceAll(java:java.lang.String.new($term_source_reference),'_{2,}','_')"/>
			
			<!-- put locality (-ies) -->
			<xsl:variable name="localities">
				<xsl:for-each select="$model_term_source/*[self::locality or self::localityContinue][normalize-space() != '']">
					<xsl:if test="self::locality"><xsl:text>,</xsl:text></xsl:if>
					<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),',$','')"/> <!-- remove comma at end -->
				</xsl:for-each>
			</xsl:variable>
			<xsl:value-of select="$localities"/>
			
			<xsl:if test="normalize-space($localities) = ''">
				<!-- put reference text -->
				<xsl:variable name="referenceText">
					<xsl:for-each select="$model_term_source/referenceText"> <!-- [normalize-space() != ''] -->
						<xsl:if test="not(preceding-sibling::referenceText/text() = current()/text())">
							<xsl:if test="not(starts-with(normalize-space(.), 'footnote:'))">
								<xsl:text>,</xsl:text>
								<xsl:value-of select="."/>
							</xsl:if>
						</xsl:if>
					</xsl:for-each>
				</xsl:variable>
				
				<!-- <xsl:message>$refs//ref=<xsl:value-of select="$refs//ref[@id = $term_source_reference or @id3 = $term_source_reference]/@referenceText"/></xsl:message>
				<xsl:message>referenceText=<xsl:value-of select="substring($referenceText,2)"/></xsl:message> -->
				
				<!-- if reference text is different than reference title in the Bibliography -->
				<xsl:variable name="ref_by_id_" select="$refs//ref[@id = $term_source_reference or 
							@id2 = $term_source_reference or @id3 = $term_source_reference or @id4 = $term_source_reference or @id5 = $term_source_reference]"/>
				<xsl:variable name="ref_by_id" select="xalan:nodeset($ref_by_id_)"/>
				
				<!-- after comma -->
				<!-- <xsl:variable name="referenceText_after_comma" select="substring($referenceText,2)"/> -->
				<xsl:variable name="referenceText_after_comma" select="java:replaceAll(java:java.lang.String.new($referenceText),'^,?(.*)$','$1')"/>
				
				<xsl:if test="(not($ref_by_id/@referenceText = $referenceText_after_comma)) or
					java:org.metanorma.utils.RegExHelper.matches($start_standard_regex, normalize-space($referenceText_after_comma)) = 'false' or
					$ref_by_id/@label_number">
					<xsl:value-of select="$referenceText"/>
				</xsl:if>
			</xsl:if>
			
		<xsl:text>&gt;&gt;</xsl:text>
		
		<!-- put modified text (or just indication, i.e. comma ',') -->
		<xsl:for-each select="$model_term_source/modified">
			<xsl:value-of select="."/>
		</xsl:for-each>
		
		<xsl:text>&#xa;&#xa;</xsl:text>
		
	</xsl:template>
	
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
			<xsl:apply-templates select="@list-type">
				<xsl:with-param name="force">true</xsl:with-param>
			</xsl:apply-templates>
		</xsl:variable>
		
		<!-- https://www.metanorma.org/author/topics/document-format/text/#ordered-lists: 
		commented due: The start attribute for ordered lists is only allowed by certain Metanorma flavors, such as BIPM.
		-->
		<xsl:variable name="start">
			<xsl:call-template name="getListStartValue"/>
		</xsl:variable>
		<xsl:if test="$start != '' and $start != '1' and preceding-sibling::*[1][self::p]">
			<!-- <xsl:text>[start=</xsl:text><xsl:value-of select="$start"/><xsl:text>]</xsl:text> -->
			<xsl:call-template name="insertPI">
				<xsl:with-param name="name">list-start</xsl:with-param>
				<xsl:with-param name="value" select="$start"/>
			</xsl:call-template>
			<xsl:call-template name="insertPI">
				<xsl:with-param name="name">list-type</xsl:with-param>
				<xsl:with-param name="value" select="$list-type"/>
			</xsl:call-template>
			<!-- <xsl:text>+++&lt;?list_start </xsl:text><xsl:value-of select="$start"/><xsl:text>?&gt;&lt;?list_type </xsl:text><xsl:value-of select="$list-type"/><xsl:text>?&gt;+++</xsl:text> -->
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
		<xsl:if test="$list-type = 'simple'">
			<xsl:call-template name="insertPI">
				<xsl:with-param name="name">list-type</xsl:with-param>
				<xsl:with-param name="value" select="$list-type"/>
			</xsl:call-template>
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
		
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
		<xsl:param name="force">false</xsl:param>
		<xsl:variable name="first_label" select="translate(..//label[1], ').', '')"/>
		<xsl:variable name="listtype">
			<xsl:choose>
				<xsl:when test="$force = 'true' and . = 'simple'">simple</xsl:when>
				<xsl:when test="$force = 'true' and . = 'alpha-lower'">loweralpha</xsl:when>
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
		<xsl:if test="$force = 'true' and $listtype != ''">
			<xsl:value-of select="$listtype"/>
		</xsl:if>
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
	
	<!-- special case -->
	<xsl:template match="break[preceding-sibling::node()[1][self::styled-content[@style='text-alignment: center']]] | 
						break[following-sibling::node()[1][self::styled-content[@style='text-alignment: center']]]">
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="break">
		<xsl:text> +</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template match="bold | bold2">
		<xsl:if test="parent::*[local-name() = 'td' or local-name() = 'th'] and not(preceding-sibling::node())"><xsl:text> </xsl:text></xsl:if>
		
		<xsl:variable name="text"><xsl:apply-templates /></xsl:variable>
		
		<!-- move internal spaces from bold to around it -->
		<xsl:variable name="text_preceding" select="preceding-sibling::node()[1]"/>
		<xsl:if test="starts-with($text, ' ') and not(java:endsWith(java:java.lang.String.new($text_preceding),' ')) and $text_preceding != ''"><xsl:text> </xsl:text></xsl:if>
		
		<xsl:if test="self::bold2"><xsl:text>*</xsl:text></xsl:if>
		<xsl:text>*</xsl:text><xsl:value-of select="normalize-space($text)"/><xsl:text>*</xsl:text>
		<xsl:if test="self::bold2"><xsl:text>*</xsl:text></xsl:if>
		
		<!-- move internal spaces from italic to around it -->
		<xsl:variable name="text_following" select="following-sibling::node()[1]"/>
		<xsl:if test="java:endsWith(java:java.lang.String.new($text),' ') and not(starts-with($text_following, ' ')) and $text_following != ''"><xsl:text> </xsl:text></xsl:if>
	</xsl:template>
	
	<xsl:template match="italic | italic2">
		<xsl:choose>
			<!-- if italic in paragraph that relates to COMMENTARY -->
			<xsl:when test="parent::p[*[1][self::italic or self::italic2] and normalize-space(translate(./text(),'&#xa0;.','  ')) = ''] and 
			parent::p/preceding-sibling::p[starts-with(normalize-space(), $commentary_on) and 
							(starts-with(normalize-space(.//italic/text()), $commentary_on) or starts-with(normalize-space(.//italic2/text()), $commentary_on))]">
				<!-- no italic -->
				<xsl:apply-templates />
			</xsl:when>
			<!-- if italic in list-item that relates to COMMENTARY -->
			<xsl:when test="ancestor::list/preceding-sibling::p[starts-with(normalize-space(), $commentary_on) and 
							(starts-with(normalize-space(.//italic/text()), $commentary_on) or starts-with(normalize-space(.//italic2/text()), $commentary_on))]">
				<!-- no italic -->
				<xsl:apply-templates />
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="text"><xsl:apply-templates /></xsl:variable>
				<xsl:choose>
					<xsl:when test="$text = '.'"><xsl:value-of select="$text"/></xsl:when>
					<xsl:otherwise>
						<!-- move internal spaces from italic to around it -->
						<xsl:variable name="text_preceding" select="preceding-sibling::node()[1]"/>
						<xsl:if test="starts-with($text, ' ') and not(java:endsWith(java:java.lang.String.new($text_preceding),' '))"><xsl:text> </xsl:text></xsl:if>
						
						<xsl:if test="self::italic2"><xsl:text>_</xsl:text></xsl:if>
						<xsl:text>_</xsl:text><xsl:value-of select="normalize-space($text)"/><xsl:text>_</xsl:text>
						<xsl:if test="self::italic2"><xsl:text>_</xsl:text></xsl:if>
						
						<!-- move internal spaces from italic to around it -->
						<xsl:variable name="text_following" select="following-sibling::node()[1]"/>
						<xsl:if test="java:endsWith(java:java.lang.String.new($text),' ') and not(starts-with($text_following, ' '))"><xsl:text> </xsl:text></xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'italic' or local-name() = 'italic2'][parent::p[*[1][self::italic or self::italic2] and normalize-space(translate(./text(),'&#xa0;.','  ')) = ''] and 
			parent::p/preceding-sibling::p[starts-with(normalize-space(), $commentary_on) and 
							(starts-with(normalize-space(.//italic/text()), $commentary_on) or starts-with(normalize-space(.//italic2/text()), $commentary_on))]]/text()[1]">
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
		
		<xsl:variable name="unconstrained_hash"><xsl:if test="java:org.metanorma.utils.RegExHelper.matches('\w', $prev_text_last_char) = 'true'">#</xsl:if></xsl:variable>
		<xsl:text>[smallcap]#</xsl:text>
		<xsl:value-of select="$unconstrained_hash"/>
		<xsl:apply-templates />
		<xsl:value-of select="$unconstrained_hash"/>
		<xsl:text>#</xsl:text>
		
		<!-- <xsl:choose>
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
		</xsl:choose> -->
	</xsl:template>
	
	<xsl:template match="ext-link | supplementary-material">
		
		<xsl:choose>
			<xsl:when test="$organization = 'BSI' or $organization = 'PAS'">
				<xsl:value-of select="translate(@xlink:href, '&#x2011;', '-')"/> <!-- non-breaking hyphen minus -->
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="self::supplementary-material"><xsl:text>file://</xsl:text></xsl:if>
				<xsl:value-of select="@xlink:href"/>
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:text>[</xsl:text><xsl:apply-templates /><xsl:text>]</xsl:text>
	</xsl:template>
	
	<xsl:template match="supplementary-material/p">
		<xsl:apply-templates />
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
		
		<xsl:variable name="isTerm">
			<xsl:for-each select="$updated_xml"> <!-- change context -->
				<xsl:value-of select="local-name(key('ids', $rid_)) = 'term-sec'"/>
			</xsl:for-each>
		</xsl:variable>
		
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
					<xsl:when test="@ref-type = 'fn' and ancestor::code"> <!-- xref in 'code' -->
						<xsl:text>{{{</xsl:text>
						<xsl:for-each select="ancestor::code/following-sibling::fn[@id = current()/@rid]">
							<xsl:call-template name="fn"/>
						</xsl:for-each>
						<xsl:text>}}}</xsl:text>
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
			<!-- <xsl:when test="@ref-type = 'sec' and local-name(//*[@id = current()/@rid]) = 'term-sec'"> -->
			<!-- <xsl:when test="@ref-type = 'sec' and local-name(key('ids', current()/@rid)) = 'term-sec'"> --> <!-- <xref ref-type="sec" rid="sec_3.21"> link to term clause -->
			<xsl:when test="@ref-type = 'sec' and normalize-space($isTerm) = 'true'"> <!-- <xref ref-type="sec" rid="sec_3.21"> link to term clause -->
				<!-- <xsl:variable name="term_name" select="//*[@id = current()/@rid]//tbx:term[1]"/> -->
				<!-- <xsl:variable name="term_name" select="key('ids', current()/@rid)//tbx:term[1]"/> -->
				<xsl:variable name="term_name">
					<xsl:for-each select="$updated_xml">
						<xsl:value-of select="key('ids', $rid_)//tbx:term[1]"/>
					</xsl:for-each>
				</xsl:variable>
				
				
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
			<xsl:when test="@ref-type = 'app' and ( 
				(java:org.metanorma.utils.RegExHelper.matches('^Annex.*$', normalize-space(.)) = 'true' and
				java:org.metanorma.utils.RegExHelper.matches('^Annex(\s|\h)+.{1}$', normalize-space(.)) = 'false') or
				string-length(normalize-space(.)) = 1)"> <!-- if text isn't `Annex X`, i.e. 'Annexes A', or 'C' -->
				<xsl:text>&lt;&lt;</xsl:text><xsl:value-of select="$rid"/>,<xsl:value-of select="."/><xsl:text>&gt;&gt;</xsl:text>
			</xsl:when>
			<xsl:otherwise> <!-- example: ref-type="sec" "table" "app" -->
				<xsl:text>&lt;&lt;</xsl:text><xsl:value-of select="$rid"/><xsl:text>&gt;&gt;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="sup[xref[@ref-type='fn' or @ref-type='table-fn']]">
		<xsl:apply-templates />
	</xsl:template>
	
	<!-- command in 'sup' after/before xref <sup><xref ref-type="fn" rid="fn3">3</xref>, <xref ref-type="fn" rid="fn4">4</xref>, <xref ref-type="fn" rid="fn5">5</xref></sup> -->
	<xsl:template match="sup[xref[@ref-type='fn' or @ref-type='table-fn']]/text()[normalize-space() = ',']"/>
	
	<xsl:template match="fn-group"/><!-- fn from fn-group  moved to after the text -->
	
	<!-- Multi-paragraph footnote -->
	<xsl:template match="fn[count(p) &gt; 1]" priority="2">
		<xsl:text> footnoteblock:[</xsl:text>
		<xsl:value-of select="@id"/>
		<xsl:text>]</xsl:text>
	</xsl:template>
	
	<!-- special case: fn after 'code' with 'xref' -->
	<xsl:template match="fn[preceding-sibling::*[1][self::code][xref[@ref-type = 'fn']]]" priority="2"/>
	
	<xsl:template match="fn" name="fn">
		<xsl:if test="preceding-sibling::node()[normalize-space() != ''][1][self::fn] and not(parent::fn-group)">
			<!-- add comma between footnotes sequence -->
			<xsl:text>,</xsl:text>
		</xsl:if>
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
		<xsl:if test="$inputformat = 'IEEE' and (ancestor::ref-list or ancestor::list[@list-content = 'normative-references'])"><xsl:text>, </xsl:text></xsl:if>
		<xsl:if test="preceding-sibling::node()">
			<xsl:text> </xsl:text>
		</xsl:if>
		<xsl:apply-templates/>
	</xsl:template>
		
	<xsl:template match="mixed-citation" mode="IEEE">
		<!-- <xsl:if test="@publication-type = 'standard'">
			<xsl:for-each select="std/std-organization | std/pub-id">
				<xsl:apply-templates />
				<xsl:if test="position() != last()"><xsl:text> </xsl:text></xsl:if>
			</xsl:for-each>
		</xsl:if> -->
		<xsl:choose>
			<xsl:when test="std/source">
				<!-- get elements before source -->
				<xsl:for-each select="std/source/preceding-sibling::node()">
					<xsl:if test="not(position() = last() and normalize-space(translate(.,'&#x2122;',' ')) = ',')">
						<xsl:value-of select="."/>
						<!-- <xsl:apply-templates /> -->
					</xsl:if>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="std"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="mixed-citation[std and not(ancestor::ref) and not(ancestor::list[@list-content = 'normative-references'])][following-sibling::*[1][self::xref[@ref-type = 'bibr']]]">
		<xsl:choose>
			<xsl:when test="$inputformat = 'IEEE'">
				<!-- link will be added in the following xref -->
				<!-- <xsl:text>&lt;&lt;</xsl:text>
				<xsl:value-of select="following-sibling::*[1][self::xref[@ref-type = 'bibr']]/@rid"/>
				<xsl:text>&gt;&gt;</xsl:text> -->
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!--Example: publication-type="report" -->
	<xsl:template match="mixed-citation/@publication-type">
		<!-- available types see in '<define name="BibItemType" combine="choice">' https://github.com/metanorma/metanorma-ieee/blob/main/lib/metanorma/ieee/biblio.rng -->
		<xsl:text>span:type[</xsl:text>
			<xsl:choose>
				<xsl:when test=". = 'government'">misc</xsl:when>
				<xsl:when test=". = 'confpaper'">misc</xsl:when>
				<xsl:when test=". = 'periodical'">misc</xsl:when>
				<xsl:when test=". = 'report'">techreport</xsl:when>
				<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
			</xsl:choose>
		<xsl:text>]</xsl:text>
	</xsl:template>
	
	<!-- Example: <article-title>&#x201c;Sound Barrier Walls for Transformers,&#x201d; AIEE Committee	Report</article-title> -->
	<xsl:template match="mixed-citation/article-title | mixed-citation[@publication-type != 'standard']/source | mixed-citation/conf-name">
		<!-- <xsl:text>span:title[</xsl:text><xsl:apply-templates/><xsl:text>]</xsl:text> -->
		<xsl:text>_</xsl:text><xsl:apply-templates /><xsl:text>_</xsl:text>
	</xsl:template>
	
	<!-- Example: <publisher-name>Pacific Gas &amp; Electric Company</publisher-name> -->
	<!-- <xsl:template match="mixed-citation/publisher-name">
		<xsl:text>span:publisher[</xsl:text><xsl:apply-templates/><xsl:text>]</xsl:text>
	</xsl:template> -->
	
	<!-- Example: <publisher-loc>Pittsburgh, PA</publisher-loc> -->
	<!-- <xsl:template match="mixed-citation/publisher-loc">
		<xsl:text>span:pubplace[</xsl:text><xsl:apply-templates/><xsl:text>]</xsl:text>
	</xsl:template> -->
	
	<!-- Example: <year>1993</year> -->
	<!-- <xsl:template match="mixed-citation/year">
		<xsl:text>span:pubyear[</xsl:text><xsl:apply-templates/><xsl:text>]</xsl:text>
	</xsl:template> -->
	
	<!-- Example: <fpage>60</fpage> <lpage>175</lpage> -->
	<!-- <xsl:template match="mixed-citation/fpage">
		<xsl:text>span:pages[</xsl:text><xsl:value-of select="."/><xsl:apply-templates select="following-sibling::*[1][self::lpage]" mode="lpage"/><xsl:text>]</xsl:text>
	</xsl:template>
	<xsl:template match="mixed-citation/lpage" />
	<xsl:template match="mixed-citation/lpage" mode="lpage">
		<xsl:text>-</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	<xsl:template match="mixed-citation/text()[preceding-sibling::*[1][self::fpage] and following-sibling::*[1][self::lpage]]"/> -->
	
	<!-- Example:
	<person-group person-group-type="author">
		<string-name>
		<surname>Pedersen</surname>, <given-names>R. S.</given-names>
		</string-name>
		</person-group>
	-->
	<!-- <xsl:template match="mixed-citation//surname">
		<xsl:variable name="type_" select="ancestor::person-group/@person-group-type"/>
		<xsl:variable name="type">
			<xsl:if test="$type_ != '' and $type_ != 'author'">.<xsl:value-of select="$type_"/></xsl:if>
		</xsl:variable>
		<xsl:text>span:surname</xsl:text><xsl:value-of select="$type"/><xsl:text>[</xsl:text><xsl:apply-templates/><xsl:text>]</xsl:text>
	</xsl:template>
	<xsl:template match="mixed-citation//given-names">
		<xsl:variable name="type_" select="ancestor::person-group/@person-group-type"/>
		<xsl:variable name="type">
			<xsl:if test="$type_ != '' and $type_ != 'author'">.<xsl:value-of select="$type_"/></xsl:if>
		</xsl:variable>
		<xsl:text>span:givenname</xsl:text><xsl:value-of select="$type"/><xsl:text>[</xsl:text><xsl:apply-templates/><xsl:text>]</xsl:text>
	</xsl:template> -->
	
	<!-- Example: <pub-id specific-use="repno">GET 2500</pub-id> -->
	<!-- <xsl:template match="mixed-citation[@publication-type != 'standard']/pub-id">
		<xsl:variable name="type_" select="@specific-use"/>
		<xsl:variable name="type">
			<xsl:if test="$type_ != ''">.<xsl:value-of select="$type_"/></xsl:if>
		</xsl:variable>
		<xsl:text>span:docid</xsl:text><xsl:value-of select="$type"/><xsl:text>[</xsl:text><xsl:apply-templates/><xsl:text>]</xsl:text>
	</xsl:template> -->
	
	<!-- <xsl:template match="mixed-citation/uri">
		<xsl:text>span:uri[</xsl:text><xsl:apply-templates/><xsl:text>]</xsl:text>
	</xsl:template> -->
	
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
			<xsl:when test="count(table/col) + count(table/colgroup/col) = 2 and $organization != 'BSI' and $organization != 'PAS' and $organization != 'IEC' and $organization != 'ISO'"> <!-- if two columns array/table -->
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
		<xsl:if test="@content-type = 'norm-refs'">
			<xsl:call-template name="insertPI">
				<xsl:with-param name="name">content-type</xsl:with-param>
				<xsl:with-param name="value" select="'norm-refs'"/>
			</xsl:call-template>
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
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
		<xsl:if test=". &gt;= 700 and not(ancestor::fig)">
			<xsl:call-template name="setPageOrientation">
				<xsl:with-param name="orientation" select="'landscape'"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="table-wrap/@orientation" mode="after_table">
		<xsl:call-template name="setPageOrientation"/>
	</xsl:template>
	
	<xsl:template match="table/@width" mode="after_table">
		<xsl:if test=". &gt;= 700 and not(ancestor::fig)">
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
		
		<xsl:if test="parent::array/@id">
			<xsl:text>[[array_</xsl:text><xsl:value-of select="parent::array/@id"/><xsl:text>]]&#xa;</xsl:text>
		</xsl:if>
		
		<xsl:choose>
			<xsl:when test="parent::table-wrap and not(parent::table-wrap/label) and not(preceding-sibling::*[1][self::table])"><!-- no need to put [%unnumbered] here, see template for table-wrap--></xsl:when>
			<xsl:when test="ancestor::table-wrap/@content-type = 'ace-table' or 
					(ancestor::table-wrap and preceding-sibling::*[1][self::table]) or
					(parent::array/@content-type = 'fig-index' or parent::array/@content-type = 'figure-index') or
					parent::array">
				<xsl:text>[%unnumbered]&#xa;</xsl:text>
			</xsl:when>
		</xsl:choose>
		
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
		
		<xsl:call-template name="insertTableSeparator"/>
		
		<xsl:text>===</xsl:text>
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
		<xsl:call-template name="insertTableSeparator"/>
		<xsl:text>===</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<!-- move notes outside table -->
		<xsl:apply-templates select="../table-wrap-foot/non-normative-note" />
		
	</xsl:template>
	
	<xsl:template name="insertTableSeparator">
		<xsl:choose>
			<xsl:when test="ancestor::table"><xsl:text>!</xsl:text></xsl:when> <!-- for nesting tables -->
			<xsl:otherwise><xsl:text>|</xsl:text></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="insertCellSeparator">
		<xsl:choose>
			<xsl:when test="count(ancestor::table) &gt; 1"><xsl:text>!</xsl:text></xsl:when> <!-- for nesting tables -->
			<xsl:otherwise><xsl:text>|</xsl:text></xsl:otherwise>
		</xsl:choose>
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
			<xsl:when test="colgroup/col[@width or @align] or col[@width or @align]">
				<xsl:for-each select="colgroup/col | col">
					<xsl:call-template name="alignmentProcessing"/>
					<xsl:variable name="width" select="translate(@width, '%cm', '')"/>
					<xsl:variable name="width_number" select="number($width)"/>
					<xsl:choose>
						<xsl:when test="normalize-space($width_number) != 'NaN'">
							<xsl:value-of select="round($width_number * 100)"/>
						</xsl:when>
						<xsl:when test="$width != ''">
							<xsl:value-of select="$width"/>
						</xsl:when>
						<xsl:otherwise>1</xsl:otherwise>
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
			<xsl:if test="ancestor::table-wrap/table-wrap-foot[count(*[local-name() != 'fn-group' and local-name() != 'fn' and local-name() != 'non-normative-note']) != 0] or tfoot">
				<option>footer</option>
			</xsl:if>
			<!-- <xsl:if test="ancestor::table-wrap/@content-type = 'ace-table' or 
					(ancestor::table-wrap and preceding-sibling::*[1][self::table]) or
					(parent::array/@content-type = 'fig-index' or parent::array/@content-type = 'figure-index')">
				<option>unnumbered</option>
			</xsl:if> -->
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
		<xsl:text>&#xa;</xsl:text>
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
		<xsl:call-template name="insertCellSeparator"/>
		<xsl:call-template name="alignmentProcessingP"/>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="td">
		<xsl:call-template name="spanProcessing"/>		
		<xsl:call-template name="alignmentProcessing"/>
		<xsl:call-template name="complexFormatProcessing"/>
		<xsl:call-template name="insertCellSeparator"/>
		<xsl:call-template name="alignmentProcessingP"/>
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
		<!-- <xsl:if test="list or def-list">a</xsl:if> -->
	</xsl:template>
	
	<xsl:template name="alignmentProcessing">
		
		<xsl:variable name="defaultAlignment"><xsl:if test="$inputformat = 'STS'">left</xsl:if></xsl:variable>
		<xsl:variable name="defaultVAlignment"><xsl:if test="$inputformat = 'STS'">top</xsl:if></xsl:variable>
		
		<xsl:variable name="align_style-type">
			<xsl:for-each select="p[1]">
				<xsl:call-template name="getAlignment_style-type"/>
			</xsl:for-each>
		</xsl:variable>
		
		<xsl:variable name="valign_style-type">
			<xsl:for-each select="p[1]">
				<xsl:call-template name="getAlignment_style-type">
					<xsl:with-param name="prefix">valign-</xsl:with-param>
				</xsl:call-template>
			</xsl:for-each>
		</xsl:variable>
		
		<xsl:if test="(@align and @align != $defaultAlignment) or (@valign and @valign != $defaultVAlignment) or 
						($align_style-type != '' and $align_style-type != $defaultAlignment) or ($valign_style-type != '' and $valign_style-type != $defaultVAlignment)">
			
			<xsl:variable name="align">
				<xsl:call-template name="getAlignFormat">
					<xsl:with-param name="align_style-type" select="$align_style-type"/>
				</xsl:call-template>
			</xsl:variable>
			
			<xsl:variable name="valign">
				<xsl:call-template name="getVAlignFormat">
					<xsl:with-param name="valign_style-type" select="$valign_style-type"/>
				</xsl:call-template>
			</xsl:variable>
			
			<xsl:value-of select="$align"/>
			<xsl:value-of select="$valign"/>
			
		</xsl:if>
	</xsl:template>
	
	<!-- special case: set justified alignment for child 'p' -->
	<xsl:template name="alignmentProcessingP">
		<xsl:if test="@align = 'justify'">
			<xsl:text>[align=justified]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="complexFormatProcessing">
		<xsl:if test=".//graphic or .//inline-graphic or .//list or .//def-list or
			.//named-content[@content-type = 'ace-tag'][contains(@specific-use, '_start') or contains(@specific-use, '_end')] or
			.//styled-content[@style = 'addition' or @style-type = 'addition'] or
			.//styled-content[@style = 'text-alignment: center'] or
			@align = 'justify'">a</xsl:if> <!-- AsciiDoc prefix before table cell -->
	</xsl:template>
	
	<xsl:template name="getAlignFormat">
		<xsl:param name="align_style-type"/>
		<xsl:choose>
			<xsl:when test="@align = 'center' or $align_style-type = 'center'">^</xsl:when>
			<xsl:when test="@align = 'right' or $align_style-type = 'right'">&gt;</xsl:when>
			<xsl:when test="@align = 'left' and $inputformat = 'IEEE'">&lt;</xsl:when>
			<!-- <xsl:otherwise>&lt;</xsl:otherwise> --> <!-- left -->
		</xsl:choose>
	</xsl:template>
	<xsl:template name="getVAlignFormat">
		<xsl:param name="valign_style-type"/>
		<xsl:choose>
			<xsl:when test="@valign = 'middle' or $valign_style-type = 'middle'">.^</xsl:when>
			<xsl:when test="@valign = 'bottom' or $valign_style-type = 'bottom'">.&gt;</xsl:when>
			<xsl:when test="@valign = 'top' and $inputformat = 'IEEE'">.&lt;</xsl:when>
			<!-- <xsl:otherwise>.&lt;</xsl:otherwise> --> <!-- top -->
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
			<xsl:if test="not($inputformat = 'IEEE' and ref-list)"><!-- special case for IEEE, ref-list inside app -->
				<xsl:call-template name="setId"/>
			</xsl:if>
			<xsl:text>[appendix</xsl:text>
			<xsl:apply-templates select="annex-type" mode="annex"/>		
			<xsl:text>]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:apply-templates />
		</redirect:write>
		
		<xsl:choose>
			<xsl:when test="$one_document = 'false' and starts-with(@id, 'sec_Z')"/> <!-- include:: created in national doc --> <!-- $demomode = 'true' and  -->
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
	<xsl:variable name="regex_add_bsi_prefix">^(PAS(\s|\h))</xsl:variable>
	<xsl:variable name="regex_add_bsi_prefix_result">BSI $1</xsl:variable>
	
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
			
				<xsl:if test="1 = 1"> <!-- skip -->
				<!-- std reference iteration -->
				<xsl:for-each select="$updated_xml//std[not(parent::ref)][normalize-space(@std-id) != '' or normalize-space(@std-id2) != '' or normalize-space(@std-id3) != '']">
					<xsl:variable name="std-id" select="normalize-space(@std-id)"/>
					<xsl:variable name="std-id2" select="normalize-space(@std-id2)"/>
					<xsl:variable name="std-id3" select="normalize-space(@std-id3)"/>
					
					<xsl:variable name="reference_by_std-id">
						<xsl:if test="$std-id != ''">
							<xsl:value-of select="$refs//ref[@id = $std-id or @id2 = $std-id or @id3 = $std-id or @id4 = $std-id or @id5 = $std-id]/@id"/>
						</xsl:if>
					</xsl:variable>
					
					<xsl:variable name="reference_by_std-id2">
						<xsl:if test="$std-id2 != ''">
							<xsl:value-of select="$refs//ref[@id = $std-id2 or @id2 = $std-id2 or @id3 = $std-id2 or @id4 = $std-id2 or @id5 = $std-id2]/@id"/>
						</xsl:if>
					</xsl:variable>
					
					<xsl:variable name="reference_by_std-id3">
						<xsl:if test="$std-id3 != ''">
							<xsl:value-of select="$refs//ref[@id = $std-id3 or @id2 = $std-id3 or @id3 = $std-id3 or @id4 = $std-id3 or @id5 = $std-id3]/@id"/>
						</xsl:if>
					</xsl:variable>
					
					<!-- <xsl:variable name="reference" select="$refs//ref[($std-id2 != '' and (@id2 = $std-id2 or @id3 = $std-id2 or @id4 = $std-id2 or @id = $std-id2)) or
					($std-id3 != '' and (@id2 = $std-id3 or @id3 = $std-id3 or @id4 = $std-id3 or @id = $std-id3))]/@id" /> -->
					
					<xsl:if test="normalize-space($reference_by_std-id) = '' and normalize-space($reference_by_std-id2) = '' and normalize-space($reference_by_std-id3) = ''">
					
						<item>
							<xsl:variable name="id">
								<xsl:value-of select="$std-id2"/>
								<xsl:if test="$std-id2 = ''">
									<xsl:value-of select="$std-id3"/>
								</xsl:if>
							</xsl:variable>
							<xsl:attribute name="id">
								<xsl:value-of select="$id"/>
							</xsl:attribute>
							<xsl:text>* [[[</xsl:text>
							<xsl:value-of select="java:replaceAll(java:java.lang.String.new($id),'_{2,}','_')"/>
							<xsl:text>,hidden(</xsl:text>
							
							<xsl:variable name="ref_text">
								<xsl:choose>
									<xsl:when test="contains(normalize-space(), 'series') or contains(normalize-space(), 'parts')">
										<xsl:value-of select="translate(normalize-space(), '&#xA0;‑–', ' --')"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="translate(.//std-ref/text(), '&#xA0;‑–', ' --')"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- add BSI prefix for PAS -->
							<xsl:value-of select="java:replaceAll(java:java.lang.String.new($ref_text), $regex_add_bsi_prefix, $regex_add_bsi_prefix_result)"/>
							
							
							<xsl:text>)]]]</xsl:text>
						</item>
					</xsl:if>
				</xsl:for-each>
				<!-- END std reference iteration -->
				</xsl:if>
				
				<!-- term source iteration -->
				<xsl:for-each select="$updated_xml//tbx:source">
					<xsl:variable name="model_term_source_">
						<xsl:call-template name="build_sts_model_term_source"/>
					</xsl:variable>
					<xsl:variable name="model_term_source" select="xalan:nodeset($model_term_source_)"/>
					<xsl:variable name="term_source_reference" select="$model_term_source/reference"/>
					<!-- <xsl:if test="starts-with($term_source_reference, 'hidden_bibitem_')"> -->
					<xsl:if test="$model_term_source/reference/@hidden = 'true'">
						<item id="{$term_source_reference}">
							<xsl:text>* [[[</xsl:text>
							<xsl:value-of select="java:replaceAll(java:java.lang.String.new($term_source_reference),'_{2,}','_')"/>
							<xsl:text>,hidden(</xsl:text>
							
							<xsl:variable name="hidden">
								<!-- put reference text -->
								
								<xsl:variable name="referenceText">
									<xsl:for-each select="$model_term_source/referenceTextInBibliography[normalize-space() != ''][1]">	
										<xsl:value-of select="."/>
									</xsl:for-each>
									<xsl:if test="not($model_term_source/referenceTextInBibliography[normalize-space() != ''])">
										<xsl:for-each select="$model_term_source/referenceText[normalize-space() != '']">
											<xsl:value-of select="."/>
										</xsl:for-each>
									</xsl:if>
								</xsl:variable>
								
								<xsl:choose>
									<xsl:when test="$model_term_source/referenceText[normalize-space() != ''] != $model_term_source/referenceTextInBibliography[normalize-space() != ''][1]">
										<!-- Example: * [[[ref,hidden((ISO 9000:2005 footnote:[Superseded by ISO 9000:2015.])ISO 9000:2005)]]] -->
										<xsl:text>(</xsl:text>
											<xsl:for-each select="$model_term_source/referenceTextInBibliography[normalize-space() != ''][1]">	
												<xsl:value-of select="."/>
											</xsl:for-each>
											<xsl:for-each select="$model_term_source/referenceText[normalize-space() != '']">
												<xsl:value-of select="."/>
											</xsl:for-each>
										<xsl:text>)</xsl:text>
									</xsl:when>
									<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($start_standard_regex, normalize-space($referenceText)) = 'false'">
										<!-- Example: * [[[Oxford_English_Dictionary,hidden((Oxford English Dictionary)Oxford English Dictionary)]]] -->
										<xsl:text>(</xsl:text>
											<xsl:value-of select="$referenceText"/>
										<xsl:text>)</xsl:text>
									</xsl:when>
								</xsl:choose>
								
								<!-- <xsl:value-of select="$referenceText"/> -->
								<xsl:value-of select="java:replaceAll(java:java.lang.String.new($referenceText), $regex_add_bsi_prefix, $regex_add_bsi_prefix_result)"/>
								
							</xsl:variable>
							
							<xsl:value-of select="translate($hidden, '&#xA0;‑–', ' --')"/>
							
							<xsl:text>)]]]</xsl:text>
						</item>
					</xsl:if>
				</xsl:for-each>
				<!-- END term source iteration -->
				
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
			
			<!-- output [%bibitem] at the end of bibliography -->
			<xsl:apply-templates select="node()[@content-type = 'standard_other']">
				<xsl:with-param name="skip_standard_other">false</xsl:with-param>
			</xsl:apply-templates>
			
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
		
		<xsl:if test="$inputformat = 'IEEE' and ancestor::app">
			<!-- special case with additional [bibliography] in annex --> 
			<xsl:text>[[</xsl:text>
			<xsl:value-of select="ancestor::app/@id"/>
			<xsl:text>]]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>[bibliography]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>=</xsl:text>
			<xsl:apply-templates select="ancestor::app/title"/>
		</xsl:if>
		
		<xsl:apply-templates/>
		
		
		<xsl:if test="$inputformat = 'IEEE' and ancestor::app">
			<!-- put hidden items -->
			<xsl:variable name="hidden_bibitems">
				<xsl:for-each select="//mixed-citation[not(ancestor::list-item[@list-content='normative-references']) and not(ancestor::ref-list)][not(following-sibling::*[1][self::xref/@ref-type = 'bibr'])]/std">
					<xsl:variable name="std_model_">
						<xsl:call-template name="build_ieee_model_std"/>
					</xsl:variable>
					<xsl:variable name="std_model" select="xalan:nodeset($std_model_)"/>
					<xsl:if test="normalize-space($std_model/referenceText) != ''">
						<item>
							<xsl:attribute name="id"><xsl:value-of select="$std_model/reference"/></xsl:attribute>
							<xsl:text>* [[[</xsl:text>
							<xsl:value-of select="$std_model/reference"/>
							<xsl:text>,hidden(</xsl:text>
							<xsl:value-of select="$std_model/referenceText"/>
							<xsl:text>)]]]</xsl:text>
						</item>
					</xsl:if>
				</xsl:for-each>
			</xsl:variable>
			<xsl:for-each select="xalan:nodeset($hidden_bibitems)//item">
				<xsl:if test="not(preceding-sibling::item[@id = current()/@id])"> <!-- unique only -->
					<xsl:value-of select="."/>
					<xsl:text>&#xa;&#xa;</xsl:text>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
		
		<!-- output [%bibitem] at the end of bibliography -->
		<xsl:apply-templates select="node()[@content-type = 'standard_other']">
			<xsl:with-param name="skip_standard_other">false</xsl:with-param>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="ref-list/title/bold | ref-list/title/bold2">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="ref | list[@list-content = 'normative-references']/list-item/p">
		<xsl:param name="skip_standard_other">true</xsl:param>
		<xsl:variable name="unique"><!-- skip repeating references -->
			<xsl:choose>
				<xsl:when test="@id and preceding-sibling::ref[@id = current()/@id]">false</xsl:when>
				<xsl:when test="std/@std-id and preceding-sibling::ref[std/@std-id = current()/std/@std-id]">false</xsl:when>
				<xsl:when test="std/std-ref and preceding-sibling::ref[std/std-ref = current()/std/std-ref]">false</xsl:when>
			</xsl:choose>
		</xsl:variable>
		
		<!-- DEBUG:<xsl:apply-templates select="." mode="print_as_xml"/> -->
		
		<!-- <xsl:variable name="isAsciiBibFormat" select="normalize-space(@referenceText != '' and
				java:org.metanorma.utils.RegExHelper.matches($start_standard_regex, @referenceText) = 'false')"/> -->
		
		<xsl:variable name="reference">
				
			<xsl:variable name="ids">
				<item><xsl:value-of select="@id"/></item>
				<item><xsl:value-of select="@id2"/></item>
				<item><xsl:value-of select="@id3"/></item>
				<item><xsl:value-of select="@id4"/></item>
				<item><xsl:value-of select="@id5"/></item>
				<item><xsl:value-of select="@id6"/></item>
			</xsl:variable>
			<xsl:variable name="id" select="xalan:nodeset($ids)/item[normalize-space()!=''][1]"/>
			
			<xsl:choose>
				<xsl:when test="@content-type = 'standard_other' and $skip_standard_other = 'true'"><!-- standard_other references will be inserted last --></xsl:when>
				<xsl:when test="@content-type = 'standard_other'"> <!-- add on 'ref_fix' step, for non ISO, IEC, ... standards, example: GHTF_SG1_N055_2009 -->
					<!-- bibitem extended format:
					https://www.metanorma.org/author/topics/document-format/bibliography/#entering-entries-using-asciibib
					https://www.relaton.org/specs/asciibib/
					-->
					<xsl:text>[[</xsl:text><xsl:value-of select="$id"/><xsl:text>]]&#xa;</xsl:text>
					<xsl:text>[%bibitem]&#xa;</xsl:text>
					
					<!-- <xsl:text>=== </xsl:text> -->
					<xsl:for-each select="ancestor::*[title][1]/title">
						<xsl:variable name="level">
							<xsl:call-template name="getLevel">
								<xsl:with-param name="addon">1</xsl:with-param>
							</xsl:call-template>
						</xsl:variable>
						<xsl:value-of select="$level"/><xsl:text> </xsl:text>
					</xsl:for-each>
					<xsl:variable name="isThereFootnoteAfterNumber" select="normalize-space(*/node()[normalize-space() != ''][2][self::xref and @ref-type='fn'] and
					*/node()[normalize-space() != ''][3][self::fn])"/>
					
					<xsl:variable name="title">
						<xsl:choose>
							<xsl:when test="$isThereFootnoteAfterNumber = 'true'">
								<xsl:apply-templates select="*/node()[normalize-space() != ''][3][self::fn]/following-sibling::node()"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:apply-templates/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<!-- remove comma at start -->
					<xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new($title),'^(\s|\h)*,',''))"/>
					<xsl:text>&#xa;</xsl:text>
					<xsl:text>docid::&#xa;</xsl:text>
					<xsl:text>id::: </xsl:text>
					<!-- add BSI prefix for PAS -->
					<xsl:value-of select="java:replaceAll(java:java.lang.String.new(@referenceText), $regex_add_bsi_prefix, $regex_add_bsi_prefix_result)"/>
					<xsl:text>&#xa;</xsl:text> <!-- note: @referenceText was added at ref_fix step -->
					<xsl:text>type:: standard&#xa;</xsl:text>
					<xsl:if test="$isThereFootnoteAfterNumber = 'true'">
						<xsl:text>biblionote:: &#xa;</xsl:text>
						<xsl:text>type::: Unpublished-Status&#xa;</xsl:text>
						<xsl:text>content::: </xsl:text>
						<xsl:apply-templates select="*/node()[normalize-space() != ''][3][self::fn]/node()"/>
						<xsl:text>&#xa;</xsl:text>
					</xsl:if>

				</xsl:when>
				<xsl:otherwise>

					<xsl:if test="$id != ''">
			
						<xsl:text>[[[</xsl:text>
						
						<xsl:value-of select="$id"/>
						
						<xsl:variable name="referenceText">
							
							<xsl:if test="not($inputformat = 'IEEE' and mixed-citation/@publication-type = 'standard')">
								<!-- note: @referenceText and @label_number added at ref_fix step -->
								<xsl:if test="@label_number != '' and @referenceText != ''">
									<xsl:text>(</xsl:text>
								</xsl:if>
								<xsl:value-of select="@label_number"/>
								<xsl:if test="@label_number != '' and @referenceText != ''">
									<xsl:text>)</xsl:text>
								</xsl:if>
							</xsl:if>
							<!-- <xsl:value-of select="@referenceText"/> -->
							<!-- add BSI prefix for PAS -->
							<xsl:value-of select="java:replaceAll(java:java.lang.String.new(@referenceText), $regex_add_bsi_prefix, $regex_add_bsi_prefix_result)"/>
							
						</xsl:variable>
						
						
						<xsl:if test="$referenceText != ''">
							<xsl:text>,</xsl:text>
							
							<xsl:if test=".//named-content[@content-type='ace-tag']">
								<xsl:text>path:(hyperlink,</xsl:text>
							</xsl:if>
							
							<xsl:choose>
								<xsl:when test="$inputformat = 'IEEE'">
									<xsl:variable name="text" select="java:replaceAll(java:java.lang.String.new($referenceText), '(\s|\h)Std(\s|\h)', ' ')"/> <!-- remove ' Std ' -->
									<xsl:value-of select="translate($text,'™','')"/> <!-- remove trademark sign -->
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$referenceText"/>
								</xsl:otherwise>
							</xsl:choose>
							
							
							<xsl:if test=".//named-content[@content-type='ace-tag']">
								<xsl:text>)</xsl:text>
							</xsl:if>
						</xsl:if>
						
						<xsl:text>]]]</xsl:text>
					
					</xsl:if>
				
					<xsl:variable name="reference_desc">
						<xsl:apply-templates/>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="$inputformat = 'IEEE'">
							<xsl:value-of select="normalize-space($reference_desc)"/>
						</xsl:when>
						<xsl:otherwise>
						
							<xsl:variable name="operator">
								<xsl:call-template name="getInsDel"/>
							</xsl:variable>
							<xsl:if test="$operator != ''">
								<xsl:text> </xsl:text><xsl:value-of select="$operator"/><xsl:text>:[</xsl:text>
							</xsl:if>
						
							<xsl:value-of select="$reference_desc"/>
							
							<xsl:if test="$operator != ''">
								<xsl:text>]</xsl:text>
							</xsl:if>
							
						</xsl:otherwise>
					</xsl:choose>
					
				</xsl:otherwise>
			</xsl:choose>
		
		</xsl:variable>
		
		<xsl:if test="normalize-space($reference) != ''">
			<!-- comment repeated references -->
			<xsl:if test="normalize-space($unique) = 'false'">// </xsl:if>
			<xsl:if test="not(@content-type and @content-type = 'standard_other')">* </xsl:if>
			<!-- <xsl:value-of select="$reference"/> -->
			<xsl:choose>
				<xsl:when test="normalize-space($unique) = 'false'">
					<!-- add comment // before each line in the $reference -->
					<xsl:value-of select="java:replaceAll(java:java.lang.String.new($reference),'&#xa;','&#xa;// ')"/> 
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$reference"/>
				</xsl:otherwise>
			</xsl:choose>
			
			<xsl:apply-templates select="mixed-citation/@publication-type[. != 'standard']"/>
			
			<xsl:text>&#xa;&#xa;</xsl:text>
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
	
	<!-- <xsl:template match="ref/label" mode="references">
		<xsl:variable name="label" select="translate(., '[]', '')"/>
		<xsl:choose>
			<xsl:when test="$label = '—'"></xsl:when>
			<xsl:otherwise><xsl:value-of select="$label"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template> -->
	
	<xsl:template match="ref/std/std-ref"/>
	
	<xsl:template match="ref/mixed-citation/std | list[@list-content = 'normative-references']/list-item//mixed-citation/std">
		<xsl:choose>
			<xsl:when test="$inputformat = 'IEEE'">
				<xsl:apply-templates />
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="std"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="ref/mixed-citation/std" mode="references">
		<!-- <xsl:text>,</xsl:text> -->
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="ref/std//title">
		<xsl:if test="not(contains(preceding-sibling::node()[1], ','))"> <!-- no comma before title in IEC -->
			<xsl:text>, </xsl:text>
		</xsl:if>
		<xsl:text>_</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>_</xsl:text>
	</xsl:template>
	
	<xsl:template match="ref/std//title/text()">
		<xsl:value-of select="translate(., '&#xA0;', ' ')"/>
	</xsl:template>
  
	<!-- Special case: empty references -->
	<!-- Example: <ref>
            <mixed-citation> </mixed-citation>
          </ref>
	-->
	<xsl:template match="ref[normalize-space(translate(., '&#xa0;', ' ')) = '']" priority="2"/>
	
	<!-- Special case:
		<ref>
			<mixed-citation publication-type="other" id="ref_1">
				<bold>Standards references</bold>
			</mixed-citation>
		</ref>
	-->
	<xsl:template match="ref[normalize-space(mixed-citation) = 'Standards references' or normalize-space(mixed-citation) = 'Other publications' or 
											normalize-space(mixed-citation) = 'Standards publications']">
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>[bibliography]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:for-each select="mixed-citation[1]">
			<xsl:call-template name="setId"/> <!-- Example: [[ref_2]] -->
		</xsl:for-each>
		
		<xsl:for-each select="ancestor::sec[1]">
			<xsl:variable name="level">
				<xsl:call-template name="getLevel">
					<xsl:with-param name="addon">1</xsl:with-param>
				</xsl:call-template>
			</xsl:variable>
			<xsl:value-of select="$level"/><xsl:text> </xsl:text>
		</xsl:for-each>
		<xsl:value-of select="normalize-space(mixed-citation)"/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<!-- Special case:
		<ref>
			<mixed-citation publication-type="book" id="ref_47">[N1]     Text ... </mixed-citation>
		</ref>
		converts to:
		* [[[ref_47,(N1)]]], Text ... 
	-->
	<xsl:variable name="regexNormRefsNumber">^(\[N\d+\])(\s|\h)+(.*)</xsl:variable>
	<xsl:template match="ref[count(*) = 1 and mixed-citation and java:org.metanorma.utils.RegExHelper.matches($regexNormRefsNumber, normalize-space()) = 'true']">
		<xsl:text>* [[[</xsl:text>
		<xsl:value-of select="mixed-citation/@id"/>
		<xsl:text>,(</xsl:text>
		<xsl:value-of select="translate(java:replaceAll(java:java.lang.String.new(.),$regexNormRefsNumber,'$1'),'[]','')"/>
		<xsl:text>)]]], </xsl:text>
		<xsl:apply-templates select="mixed-citation"/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="ref[count(*) = 1 and mixed-citation and java:org.metanorma.utils.RegExHelper.matches($regexNormRefsNumber, normalize-space()) = 'true']/mixed-citation//text()[1]">
		<!-- remove [N2] ... from start of mixed-citation -->
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),$regexNormRefsNumber,'$3')"/>
	</xsl:template>
	
	
	<xsl:template match="list[@list-content = 'normative-references']">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="list[@list-content = 'normative-references']/list-item">
		<xsl:apply-templates />
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<!-- ============================ -->
	<!-- References -->
	<!-- ============================ -->
	
	
	
	<!-- ============================ -->
	<!-- Figure -->
	<!-- ============================ -->
	
	<xsl:template match="fig" priority="3">
	
		<xsl:variable name="fig_">
			<xsl:call-template name="build_sts_model_fig"/>
		</xsl:variable>
		<xsl:variable name="fig" select="xalan:nodeset($fig_)"/>
		
		<!-- Example figure model:
			<fig id="fig_7">
				<label>Figure 7</label>
				<title_main>Figure title example</title_main>
				<graphic type="simple" href="30357099_Fig07a"> 
					<label>a)</label> 
					<caption><title>Sub-figure a) title</title></caption>
				</graphic>
				<graphic_text>Sub-figure a) descriptive text.</graphic_text>
				<graphic type="simple" href="30357099_Fig07b"> 
					<label>b)</label> 
					<caption><title>Sub-figure b) title </title></caption>
				</graphic>
				<graphic_text>Sub-figure b) descriptive text.</graphic_text>
		-->
		
		<!-- <xsl:text>&#xa;DEBUG&#xa;</xsl:text>
		<xsl:apply-templates select="$fig" mode="print_as_xml"/>
		<xsl:text>&#xa;</xsl:text> -->
		
		<xsl:if test="parent::tbx:note">
			<xsl:text> +&#xa;</xsl:text>
		</xsl:if>
		
		<xsl:apply-templates select="$fig/fig/@orientation"/>
		
		<!-- Example: [[fig_1]] -->
		<xsl:call-template name="setId"/>

		<xsl:apply-templates select="$fig/fig/label"/>
		
		<xsl:variable name="isDescriptiveText" select="normalize-space(count($fig/fig/graphic_text) &gt; 0)"/>
		
		<xsl:if test="$isDescriptiveText = 'true'"> <!-- if there is descriptive text for figure, then add 'figure role' -->
			<xsl:text>[.figure]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>

		<xsl:choose>
			<xsl:when test="count($fig/fig/graphic) &gt; 1 or count($fig/fig/title_main) + count($fig/fig/graphic//title) &gt; 1">
				
				<!-- Example: . Figure title -->
				<xsl:apply-templates select="$fig/fig/title_main" />
				
				<!-- <xsl:apply-templates select="$fig/fig/title[1]" /> -->
			
				<xsl:text>====</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				
				<xsl:variable name="title_before_graphic" select="normalize-space($fig/fig/graphic[1][preceding-sibling::title] and 1 = 1)"/>
				<xsl:for-each select="$fig/fig/graphic">
					<xsl:if test="$title_before_graphic = 'true'">
						<xsl:apply-templates select="preceding-sibling::title[1]"/>
					</xsl:if>
					<xsl:if test="$title_before_graphic = 'false'">
						<xsl:apply-templates select="following-sibling::title[1]"/>
					</xsl:if>
					<xsl:apply-templates select="."/>
					
					<!-- descriptive text for figure -->
					<xsl:variable name="curr_id" select="generate-id()"/>
					<xsl:apply-templates select="following-sibling::graphic_text[preceding-sibling::graphic[1][generate-id() = $curr_id]]"/> <!--  -->
				</xsl:for-each>

				<xsl:text>====</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>&#xa;</xsl:text>
			</xsl:when>
			
			<xsl:otherwise>
				<!-- Example: . Figure title -->
				<xsl:apply-templates select="$fig/fig/title_main" />
				
				<xsl:if test="$isDescriptiveText = 'true'">
					<xsl:text>====</xsl:text>
					<xsl:text>&#xa;</xsl:text>
				</xsl:if>
				
				<xsl:apply-templates select="$fig/fig/graphic"/>
				<xsl:apply-templates select="$fig/fig/graphic_text"/>
				
				<xsl:if test="$isDescriptiveText = 'true'">
					<xsl:text>====</xsl:text>
					<xsl:text>&#xa;</xsl:text>
				</xsl:if>
				
				<xsl:text>&#xa;</xsl:text>
				<!-- <xsl:text>&#xa;</xsl:text> -->
			</xsl:otherwise>
		</xsl:choose>
		
		<!-- process another elements (key, note, ... ) -->
		<xsl:apply-templates select="$fig/fig/*[not(self::label or self::title or self::title_main or self::graphic or self::graphic_text)]"/>
		
		<xsl:apply-templates select="$fig/fig/@orientation" mode="after_fig"/>
		
	</xsl:template>
	
	<!-- ==================== -->
	<!-- figure model processing -->
	<!-- ==================== -->
	<xsl:template match="fig/title | fig/title_main"> <!-- in xml: fig/caption/title -->
		<xsl:text>.</xsl:text>
		<xsl:apply-templates />
		<xsl:for-each select="ancestor::fig[1]/p/named-content[@content-type='ace-tag']"> <!-- move ace-tag at the end of figure's title -->
			<xsl:call-template name="ace-tag"/>
		</xsl:for-each>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="fig/label" priority="2">
		<xsl:variable name="number" select="normalize-space(substring-after(., '&#xa0;'))"/>
		<xsl:if test="substring($number, 1, 1) = '0'"> <!-- example: Figure 0.1 -->
			<xsl:text>[number=</xsl:text><xsl:value-of select="$number"/><xsl:text>]&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="fig/key">
		<xsl:if test="table">
			<xsl:text>[%unnumbered]&#xa;</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="@label"/>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="fig/key/@label">
		<xsl:text>.</xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="fig/@orientation">
		<xsl:call-template name="setPageOrientation">
			<xsl:with-param name="orientation" select="."/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="fig/@orientation" mode="after_fig">
		<xsl:call-template name="setPageOrientation"/>
	</xsl:template>
	
	<!-- ==================== -->
	<!-- END figure model processing -->
	<!-- ==================== -->
	
	
	<!-- in STS XML there are two figure's group structure: fig-group/fig* and 
					fig/graphic[title]* (in BSI documents), for latter see template match="fig" -->
	<xsl:template match="fig-group">
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
	
	<xsl:template match="fig-group/caption/title"/>
	<xsl:template match="fig-group/caption/title" mode="fig-group-title">
		<xsl:text>.</xsl:text>
		<xsl:apply-templates />
		<xsl:for-each select="ancestor::fig[1]/p/named-content[@content-type='ace-tag']"> <!-- move ace-tag at the end of figure's title -->
			<xsl:call-template name="ace-tag"/>
		</xsl:for-each>
		<xsl:text>&#xa;</xsl:text>
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
	
	<!-- ================================== -->
	<!-- graphic, inline-graphic processing -->
	<!-- ================================== -->
	<xsl:template match="graphic | inline-graphic" name="graphic">
	
		<xsl:variable name="graphic_">
			<xsl:call-template name="build_sts_model_graphic"/>
		</xsl:variable>
		<xsl:variable name="graphic" select="xalan:nodeset($graphic_)"/>
	
		<xsl:apply-templates select="$graphic/*[self::graphic or self::inline-graphic]/caption/title" />
		<xsl:apply-templates select="$graphic/*[self::graphic or self::inline-graphic]/@unnumbered" />
		<xsl:apply-templates select="$graphic/*[self::graphic or self::inline-graphic]/@filename" />
		
		<xsl:apply-templates select="$graphic/*[self::graphic or self::inline-graphic]/node()[not(self::caption)]"/>
		<xsl:if test="not($graphic/*[self::graphic or self::inline-graphic]/alt-text)">[]</xsl:if>
		<xsl:text>&#xa;</xsl:text>
		
		<xsl:if test="following-sibling::node()">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="*[self::graphic or self::inline-graphic]/text()[normalize-space()='']"/>
	
	<xsl:template match="*[self::graphic or self::inline-graphic]/caption/title">
		<xsl:text>.</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<!-- graphic model attribute @unnumbered-->
	<xsl:template match="*[self::graphic or self::inline-graphic]/@unnumbered">
		<xsl:if test=". = 'true'">
			<xsl:text>[%unnumbered]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<!-- graphic model attribute @filename-->
	<xsl:template match="*[self::graphic or self::inline-graphic]/@filename">
		<xsl:text>image::</xsl:text><xsl:value-of select="."/>
	</xsl:template>

	<xsl:template match="alt-text">
		<xsl:text>[</xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>]</xsl:text>
	</xsl:template>
	
	<!-- Image of the table -->
	<xsl:template match="table-wrap/graphic" priority="2"/>
	
	<!-- ================================== -->
	<!-- graphic, inline-graphic processing -->
	<!-- ================================== -->
	
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
		<xsl:if test="preceding-sibling::node()[1][self::text()] or not(preceding-sibling::p)">
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
		<xsl:text>[source</xsl:text>
		<xsl:text>%unnumbered</xsl:text> <!-- otherwise source block gets numbered as a figure -->
		<xsl:apply-templates select="@language"/>
		<xsl:apply-templates select="@code-type"/>
		<xsl:apply-templates select="@preformat-type"/>
		<xsl:if test="$inputformat = 'IEEE' and contains(preceding-sibling::*[1],'EXPRESS')">
			<xsl:text>,EXPRESS</xsl:text>
		</xsl:if>
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
	
	<xsl:template match="code/@language | code/@code-type | preformat/@preformat-type">
		<xsl:text>,</xsl:text><xsl:value-of select="."/>
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
		<xsl:choose>
			<xsl:when test="tex-math">
				<xsl:text>latexmath</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>stem</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>:[</xsl:text>
		<xsl:variable name="math"><xsl:apply-templates /></xsl:variable>
		<!-- <xsl:variable name="math01" select="java:replaceAll(java:java.lang.String.new($math),'\]','\]')"/> -->
		<xsl:value-of select="$math"/>
		<xsl:text>]</xsl:text>		
	</xsl:template>
	
	<xsl:template match="disp-formula">
	
		<xsl:choose>
			<xsl:when test="$inputformat = 'IEEE' and ancestor::def"> <!-- process as inline-formula -->
				<xsl:text>&#xa;+&#xa;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<!-- <xsl:text>stem:[</xsl:text> -->
				<xsl:if test="local-name(preceding-sibling::node()[normalize-space() != ''][1]) != 'p'">
					<xsl:text>&#xa;&#xa;</xsl:text>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>	
			
		<xsl:call-template name="setId"/>
		
		<xsl:if test="$inputformat = 'IEEE' and tex-math and not(contains(tex-math,'\tag{'))">
			<xsl:text>[%unnumbered]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		<xsl:choose>
			<xsl:when test="tex-math">
				<xsl:text>[latexmath]</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>[stem]</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		
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
		
		<xsl:apply-templates select="variable-list">
			<xsl:with-param name="process">true</xsl:with-param>
		</xsl:apply-templates>
		
	</xsl:template>
	<xsl:template match="disp-formula/text()[normalize-space()='']"/>
	
	<!-- Special case: the word 'Equation' outside of xref
		Example: Equation <xref ref-type="disp-formula" rid="deqn1">(1)</xref>
	-->
	<xsl:variable name="regexEquationXref">(.*)Equation $</xsl:variable>
	<xsl:template match="text()[following-sibling::node()[1][self::xref and @ref-type='disp-formula']]" priority="2">
		<xsl:choose>
			<xsl:when test="$inputformat = 'IEEE' and java:org.metanorma.utils.RegExHelper.matches($regexEquationXref, .) = 'true'">
				<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),$regexEquationXref,'$1')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
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
	
	<!-- remove spaces between mathml tags -->
	<xsl:template match="mml:*[*]/text()[. = ' ']"/>
	
	<!-- =============== -->
	<!-- Definitions list (dl) -->
	<!-- =============== -->
	<xsl:template match="def-list">
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="def-head">
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="variable-list">
		<xsl:param name="process">false</xsl:param>
		<xsl:if test="$process = 'true'">
			<xsl:apply-templates />
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="variable-list/p">
		<xsl:text>&#xa;&#xa;</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="def-list/title">
		<xsl:text>*</xsl:text><xsl:apply-templates /><xsl:text>*</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="def-item | var-item">
		<xsl:call-template name="setId">
			<xsl:with-param name="newline">false</xsl:with-param>
		</xsl:call-template>
		<xsl:apply-templates />		
	</xsl:template>
	
	<xsl:template match="def-item/term | var-item/term">
		<xsl:apply-templates/>
		<xsl:if test="count(node()) = 0"><xsl:text> </xsl:text></xsl:if>
		<xsl:apply-templates select="following-sibling::*[self::x] | following-sibling::*[self::def]/x">
			<xsl:with-param name="process">true</xsl:with-param>
		</xsl:apply-templates>
		<xsl:text>:: </xsl:text>
		<!-- <xsl:text>&#xa;</xsl:text> -->
	</xsl:template>
	
	<xsl:template match="def-item/x | def-item/def/x | var-item/x">
		<xsl:param name="process">false</xsl:param>
		<xsl:if test="$process = 'true'">
			<xsl:choose>
				<xsl:when test=". = ':'">&amp;#58;</xsl:when> <!-- otherwise we get ::: -->
				<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="def-item/def | var-item/def">
		<xsl:apply-templates/>
	</xsl:template>
	
	<!-- =============== -->
	<!-- End Definitions list (dl) -->
	<!-- =============== -->
	<xsl:template match="fig/p/named-content[@content-type = 'ace-tag']" priority="3"/>
	<xsl:template match="named-content[@content-type = 'ace-tag'][contains(@specific-use, '_start') or contains(@specific-use, '_end')]" priority="2" name="ace-tag"><!-- start/end tag for corrections -->
		<xsl:variable name="preceding-sibling_local-name" select="local-name(preceding-sibling::node()[1])"/>
		<xsl:variable name="following-sibling_local-name" select="local-name(following-sibling::node()[1])"/>
		<xsl:variable name="space_before"><xsl:if test="($preceding-sibling_local-name != '' and $preceding-sibling_local-name != 'break' and $preceding-sibling_local-name != 'list') or parent::std"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		<xsl:variable name="space_after"><xsl:if test="$following-sibling_local-name != '' and $following-sibling_local-name != 'break' and $following-sibling_local-name != 'list'"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		<xsl:value-of select="$space_before"/>
		<!--Example: add:[ace-tag_label_C1_start] -->
		<xsl:text>add:[</xsl:text><xsl:value-of select="@content-type"/><xsl:text>_</xsl:text><xsl:value-of select="@specific-use"/><xsl:text>]</xsl:text>
		<!-- <xsl:text>add:[]</xsl:text> -->
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
		
		<xsl:variable name="isTerm">
			<xsl:for-each select="$updated_xml"> <!-- change context -->
				<xsl:value-of select="local-name(key('ids', $target)) = 'term-sec' or local-name(key('ids', $target)) = 'termEntry'"/>
			</xsl:for-each>
		</xsl:variable>
		
		<xsl:choose>
			<!-- <xsl:when test="@content-type = 'term' and (local-name(//*[@id = $target]) = 'term-sec' or local-name(//*[@id = $target]) = 'termEntry')"> -->
			<!-- <xsl:when test="@content-type = 'term' and (local-name(key('ids', $target)) = 'term-sec' or local-name(key('ids', $target)) = 'termEntry')"> -->
			<xsl:when test="@content-type = 'term' and normalize-space($isTerm) = 'true'">
				<!-- <xsl:variable name="term_real" select="//*[@id = $target]//tbx:term[1]"/> -->
				<!-- <xsl:variable name="term_real" select="key('ids', $target)//tbx:term[1]"/> -->
				<xsl:variable name="term_real">
					<xsl:for-each select="$updated_xml"> <!-- change context -->
						 <xsl:value-of select="key('ids', $target)//tbx:term[1]"/>
					</xsl:for-each>
				</xsl:variable>
				
				<!-- <xsl:variable name="term_name" select="java:toLowerCase(java:java.lang.String.new(translate($term_name_, ' ', '-')))"/> -->
				<!-- <xsl:text>term-</xsl:text><xsl:value-of select="$term_name"/>,<xsl:value-of select="."/> -->
				
				<xsl:variable name="value" select="."/>
				
				<xsl:variable name="options">
					<xsl:if test="ancestor::*[@sec-type='terms'] and ancestor::term-sec">
						<xsl:text>noref,noital</xsl:text>
					</xsl:if>
				</xsl:variable>
				
				<xsl:call-template name="insertTermReference">
					<xsl:with-param name="term" select="$term_real"/>
					<xsl:with-param name="rendering" select="$value"/>
					<xsl:with-param name="options" select="$options"/>
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
	
	<xsl:template match="boxed-text">
		<xsl:choose>
			<xsl:when test="$inputformat = 'IEEE' and ancestor::front and ancestor::sec[title = 'Introduction']"><!-- skip --></xsl:when>
			<xsl:otherwise>
				<xsl:text>[[boxed-text_</xsl:text><xsl:number level="any"/><xsl:text>]]</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>[%unnumbered]</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>|===</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:apply-templates />
				<xsl:text>|===</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>&#xa;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="styled-content[@style = 'addition' or @style-type = 'addition' or contains(@style-type, 'addition') or @specific-use = 'insert' or
											@style = 'deletion' or @style-type = 'deletion' or contains(@style-type, 'deletion') or @specific-use = 'delete']">
											
		<xsl:variable name="preceding-sibling_local-name" select="local-name(preceding-sibling::node()[1])"/>
		<xsl:variable name="following-sibling_local-name" select="local-name(following-sibling::node()[1])"/>
		<xsl:variable name="space_before"><xsl:if test="($preceding-sibling_local-name != '' and $preceding-sibling_local-name != 'break' and $preceding-sibling_local-name != 'list') or parent::std"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		<xsl:variable name="space_after"><xsl:if test="$following-sibling_local-name != '' and $following-sibling_local-name != 'break' and $following-sibling_local-name != 'list'"><xsl:text> </xsl:text></xsl:if></xsl:variable>
		
		<xsl:variable name="operator">
			<xsl:call-template name="getInsDel"/>
		</xsl:variable>
		
		<xsl:value-of select="$space_before"/>
		<xsl:value-of select="$operator"/><xsl:text>:[</xsl:text><xsl:apply-templates/><xsl:text>]</xsl:text>
		<xsl:value-of select="$space_after"/>
	</xsl:template>
	
	<xsl:template match="styled-content[@style='text-alignment: center' or @style-type = 'align-center']">
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>[align=center]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="styled-content[@style='font-weight: italic; font-family: Times New Roman']">
		<xsl:text>stem:[</xsl:text><xsl:apply-templates /><xsl:text>]</xsl:text>
	</xsl:template>
	
	<xsl:template match="styled-content[@style='color']">
		<xsl:text>[css color:</xsl:text>
		<xsl:value-of select="@style-type"/>
		<xsl:text>]#</xsl:text>
		<xsl:apply-templates />
		<xsl:text>#</xsl:text>
	</xsl:template>
	
	<xsl:template name="getLevel">
		<xsl:param name="addon">0</xsl:param>
		<xsl:param name="calculated_level">0</xsl:param>
		
		<xsl:variable name="level_">
			<xsl:choose>
				<xsl:when test="$calculated_level != 0">
					<xsl:value-of select="$calculated_level"/>
				</xsl:when>
				<xsl:otherwise>
				
					<xsl:variable name="level_total" select="count(ancestor::*)"/>
		
					<xsl:variable name="level_standard" select="count(ancestor::standard/ancestor::*) + count(ancestor::standards-document/ancestor::*)"/>
					
					<xsl:variable name="label" select="normalize-space(preceding-sibling::*[1][self::label])"/>
				
					<xsl:choose>
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
					
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<!-- <xsl:variable name="level_">
			<xsl:choose>
				<xsl:when test="ancestor::sec[position() &gt; 1][java:org.metanorma.utils.RegExHelper.matches($regexSectionTitle, normalize-space(title)) = 'true' or
																			java:org.metanorma.utils.RegExHelper.matches($regexSectionLabel, normalize-space(label)) = 'true']">
					<xsl:value-of select="$level__"/>
				</xsl:when>
				<xsl:otherwise><xsl:value-of select="$level__"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable> -->
		
		
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
		<!-- remove last '.' -->
		<xsl:variable name="label_" select="normalize-space(java:replaceAll(java:java.lang.String.new($label),'^(.+).$','$1'))"/>
		<xsl:value-of select="string-length($label_) - string-length(translate($label_, '.', '')) + 2"/>
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
				
				<xsl:if test="@sec-type = 'foreword' and (contains(@id, '_nat') or contains(@id, '_euro')) and not(title = 'Foreword')">
					<xsl:text>[.preface]</xsl:text>
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
		
		<xsl:if test="title and not(label) and not(@sec-type) and not(ancestor::*[@sec-type]) and not(title = 'Index') and $inputformat = 'STS'"> <!--  and count(*) = count(title) + count(sec) -->
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>[discrete</xsl:text>
				<xsl:if test="java:org.metanorma.utils.RegExHelper.matches($regexSectionTitle, normalize-space(title)) = 'true'">
					<!-- section -->
					<xsl:text>%section</xsl:text>
				</xsl:if>
			<xsl:text>]</xsl:text>
		</xsl:if>
		
		<xsl:if test="title and java:org.metanorma.utils.RegExHelper.matches($regexSectionLabel, normalize-space(label)) = 'true'
			and not(@sec-type) and not(ancestor::*[@sec-type]) and not(title = 'Index')">
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>[discrete%section]</xsl:text>
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
							<xsl:with-param name="addon">
								<xsl:choose>
									<xsl:when test="parent::*[title and not(label) and not(@sec-type) and not(ancestor::*[@sec-type]) and not(title = 'Index')]">0</xsl:when><!-- parent sec has descrete title --> <!--  and count(*) = count(title) + count(sec) -->
									<xsl:otherwise>1</xsl:otherwise>
								</xsl:choose>
							</xsl:with-param>
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
		<xsl:if test="ancestor::table">
			<xsl:text>&#xa;&#xa;</xsl:text>
			<xsl:text>+++&lt;pagebreak/&gt;+++</xsl:text>
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
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
			<xsl:when test="$one_document = 'false'"> <!-- $demomode = 'true' and  -->
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
	
	<!-- ========================================= -->
	<!-- XML Linearization -->
	<!-- ========================================= -->
	<xsl:template match="@*|node()" mode="linearize">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="linearize"/>
		</xsl:copy>
	</xsl:template>
	
	<!-- remove redundant spaces -->
	<xsl:template match="text()[not(parent::code) and not(ancestor::preformat) and not(parent::mml:*)]" mode="linearize">
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
					<!-- Case 1:  [61]
								[<xref ref-type="bibr" rid="biblref_61">61</xref>]
							Case 2: [61,62]
								[<xref ref-type="bibr" rid="biblref_61">61</xref>,<xref ref-type="bibr" rid="biblref_62">62</xref>] 
					-->
					<xsl:variable name="isEndsWithOpeningBracket" select="java:endsWith(java:java.lang.String.new($str10),'[') and following-sibling::node()[1][self::xref][@ref-type = 'bibr'] and not(parent::tbx:source) and 
					(starts-with(following-sibling::node()[2],']') or  (following-sibling::node()[2] = ',' and following-sibling::node()[3][self::xref][@ref-type = 'bibr']))"/>
					<!-- string starts with ] -->
					<xsl:variable name="isStartsWithClosingBracket" select="starts-with($str10,']') and preceding-sibling::node()[1][self::xref][@ref-type = 'bibr'] and not(parent::tbx:source) and 
					(java:endsWith(java:java.lang.String.new(preceding-sibling::node()[2]),'[') or (preceding-sibling::node()[2] = ',' and preceding-sibling::node()[3][self::xref][@ref-type = 'bibr']))"/>
					
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
	<xsl:template match="sec/p[java:org.metanorma.utils.RegExHelper.matches('^[0-9]+((\.[0-9]+)+((\s|\h).*)?)?$', normalize-space(.)) = 'true'][local-name(node()[1]) != 'xref'][*[local-name() = 'bold']]" mode="linearize">
		<xsl:choose>
			<xsl:when test="$organization = 'BSI'">
			
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
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy>
					<xsl:apply-templates select="@*|node()" mode="linearize"/>
				</xsl:copy>
			</xsl:otherwise>
		</xsl:choose>
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
	
	<xsl:template match="styled-content[@style = 'font-family:Courier,monospace']" mode="linearize">
		<xsl:choose>
			<xsl:when test="parent::preformat"><xsl:apply-templates mode="linearize"/></xsl:when>
			<xsl:otherwise><monospace><xsl:apply-templates mode="linearize"/></monospace></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
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
	
	<!-- special case:, 
		... social bond (</italic>
	<tbx:entailedTerm target="term_2.18">
		<italic>2.18</italic>
	</tbx:entailedTerm>
	-->
	<!-- remove termname + '(' before entailedTerm with term's number only -->
	<!-- and -->
	<!-- remove ')' after entailedTerm with term's number only -->
	<xsl:template match="node()[following-sibling::node()[1][self::tbx:entailedTerm][translate(., '01234567890.', '') = '']]/text() |
	
	node()[preceding-sibling::node()[1][self::tbx:entailedTerm][translate(., '01234567890.', '') = '']]/text()" mode="linearize">
		<xsl:variable name="preceding_entailedTerm_target" select="../preceding-sibling::node()[1][self::tbx:entailedTerm]/@target"/>
		<xsl:variable name="preceding_term_name" select="normalize-space(key('ids', $preceding_entailedTerm_target)//tbx:term[1])"/>
		
		<xsl:variable name="text">
			<xsl:choose>
				<xsl:when test="$preceding_term_name != '' and java:endsWith(java:java.lang.String.new(normalize-space(../preceding-sibling::node()[2])), concat($preceding_term_name,' ('))"> <!-- and java:org.metanorma.utils.RegExHelper.matches(concat($term_name,' \($'), ../preceding-sibling::node()[2]/text()) = 'true' -->
					<!-- remove ')' after entailedTerm with term's number only -->
					<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.), '^\)','')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="following_entailedTerm_target" select="../following-sibling::node()[1][self::tbx:entailedTerm]/@target"/>
		<xsl:variable name="following_term_name" select="normalize-space(key('ids', $following_entailedTerm_target)//tbx:term[1])"/>
		<xsl:choose>
			<xsl:when test="$following_term_name != ''">
				<!-- remove termname + '(' before entailedTerm with term's number only -->
				<xsl:value-of select="java:replaceAll(java:java.lang.String.new($text), concat($following_term_name,' \($'),'')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$text"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- end special case -->
	
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
	
	<!-- Remove 'Clause ' from text with '... Clause ' and next element 'xref' -->
	<!-- Example: some text Clause <xref ...  -->
	<xsl:template match="text()[contains(., 'Clause ')][following-sibling::*[1][self::xref]]" mode="remove_word_clause">
		<xsl:if test="normalize-space($debug) = 'true'">
			<xsl:message>text: <xsl:number level="any"/></xsl:message>
		</xsl:if>
		<xsl:variable name="xref_rid" select="following-sibling::*[1][self::xref]/@rid"/>
		<!-- <xsl:variable name="is_clause_1stlevel_depth" select="count(//*[@id = $xref_rid]/parent::*[self::body or self::back]) &gt; 0"/> -->
		<xsl:variable name="is_clause_1stlevel_depth" select="count(key('ids', $xref_rid)/parent::*[self::body or self::back]) &gt; 0"/>
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
	
	<!-- add XML processing instruction -->
	<xsl:template name="insertPI">
		<xsl:param name="name"/>
		<xsl:param name="value"/>
		<xsl:text>+++&lt;?</xsl:text><xsl:value-of select="$name"/><xsl:text> </xsl:text><xsl:value-of select="$value"/><xsl:text>?&gt;+++</xsl:text>
	</xsl:template>
	
	<!-- =============== -->
	<!-- self-testing -->
	<!-- =============== -->
	<xsl:template name="self_testing">
		<xsl:call-template name="self_testing_std"/>
		<xsl:call-template name="self_testing_termsource"/>
	</xsl:template>
	
	<xsl:template name="self_testing_std">
		<xsl:variable name="data">
			<item>
				<source>
					<std>
						<std-ref>EN 12973:2020<?doi https://doi.org/10.3403/30314082?></std-ref>
					</std>
				</source>
				<destination>
					<xsl:text>&lt;&lt;EN_12973_2020,EN 12973:2020&gt;&gt;</xsl:text>
				</destination>
			</item>
			
			<item>
				<source>
					<std std-id="BS EN 12973:2000" type="dated">
						<std-ref>BS EN 12973:2000<?doi https://doi.org/10.3403/01921654?>
						</std-ref>
					</std>
				</source>
				<destination>&lt;&lt;BS_EN_12973_2000&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>CEN/TS 16555‑1<?doi https://doi.org/10.3403/PDCENTS16555?>
						</std-ref>
					</std>
				</source>
				<destination>&lt;&lt;CEN_TS_16555_1,CEN/TS 16555‑1&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>1.2 of<std-ref>EN ISO 13485:2012</std-ref>
					</std>
				</source>
				<destination>&lt;&lt;EN_ISO_13485_2012,clause=1.2,EN ISO 13485:2012&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std std-id="iso:std:iso:13485:ed-1:en" type="dated">
						<std-ref>ISO 13485:1996</std-ref>
					</std>
				</source>
				<destination>&lt;&lt;ISO_13485_1996&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>Clause 1 of<std-ref>EN ISO 13485:2012</std-ref>
					</std>
				</source>
				<destination>&lt;&lt;EN_ISO_13485_2012,clause=1,EN ISO 13485:2012&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std std-id="iso:std:iso:13485:ed-1:en" type="dated">
						<std-ref>ISO 13485:2003/Cor.1:2009</std-ref>
					</std>
				</source>
				<destination>&lt;&lt;ISO_13485_2003_Cor.1_2009&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std std-id="EN ISO 13485">7.3.7 of <std-ref>EN ISO 13485</std-ref>
					</std>
				</source>
				<destination>&lt;&lt;EN_ISO_13485,clause=7.3.7,EN ISO 13485&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>IEC 60601-1:2005</std-ref>, definition 3.4</std>
				</source>
				<destination>&lt;&lt;IEC_60601_1_2005,locality:definition=3.4&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>ISO 18113-1</std-ref>:—, definition 3.29</std>
				</source>
				<destination>&lt;&lt;ISO_18113_1,locality:definition=3.29&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>IEC 62366</std-ref>:—, Annexes B and D.1.3</std>
				</source>
				<destination>&lt;&lt;IEC_62366,annex=B;and!annex=D.1.3&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std std-id="iso:std:iso:13485:ed-2:en:clause:7" type="dated">Clause 7 of<std-ref>ISO 13485:2003</std-ref>
					</std>
				</source>
				<destination>&lt;&lt;ISO_13485_2003,clause=7&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std std-id="iso:std:iso:13485:ed-2:en:clause:8.2" type="dated">8.2 of<std-ref>ISO 13485:2003</std-ref>
					</std>
				</source>
				<destination>&lt;&lt;ISO_13485_2003,clause=8.2&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std std-id="iso:std:iso:14155:-1:ed-1:en:clause:A" type="dated">Annex A of<std-ref>ISO 14155-1:2003</std-ref>
					</std>
				</source>
				<destination>&lt;&lt;ISO_14155_1_2003,annex=A&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>ISO 13485:2003</std-ref>
						<xref ref-type="bibr" rid="biblref_8">
							<sup>[8]</sup>
						</xref>, 7.3.4</std>
				</source>
				<destination>&lt;&lt;ISO_13485_2003,clause=7.3.4&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>IEC 60300-3-9:1995</std-ref>
						<xref ref-type="bibr" rid="biblref_21">
							<sup>[21]</sup>
						</xref>, A.5</std>
				</source>
				<destination>&lt;&lt;IEC_60300_3_9_1995,annex=A.5&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>Clause 1 of<std-ref>EN ISO 14971:2012</std-ref>
					</std>
				</source>
				<destination>&lt;&lt;EN_ISO_14971_2012,clause=1,EN ISO 14971:2012&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std std-id="93/42/EEC" type="dated">
						<std-ref>93/42/EEC</std-ref>
					</std>
				</source>
				<destination>&lt;&lt;93_42_EEC,93/42/EEC&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>6.2 of<std-ref>ISO 14971</std-ref>
					</std>
				</source>
				<destination>&lt;&lt;ISO_14971,clause=6.2&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>2.15 and in 6.4 of<std-ref>ISO 14971</std-ref>
					</std>
				</source>
				<destination>&lt;&lt;ISO_14971,clause=2.15;and!clause=6.4&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>D.8 of<std-ref>ISO 14971</std-ref>
					</std>
				</source>
				<destination>&lt;&lt;ISO_14971,annex=D.8&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>ISO Guide 73:2009</std-ref>, 3.5.1.3</std>
				</source>
				<destination>&lt;&lt;ISO_Guide_73_2009,clause=3.5.1.3&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std std-id="iso:std:iso:guide:73:ed-1:en:clause:3.6.1.3" type="dated">
						<std-ref>ISO Guide 73:2009</std-ref>, 3.6.1.3</std>
				</source>
				<destination>&lt;&lt;ISO_Guide_73_2009,clause=3.6.1.3&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std std-id="iso:std:iso:ts:9002:ed-1:en:clause:4" type="dated">
						<std-ref>ISO/TS 9002:2016<?doi https://doi.org/10.3403/30330644?>
						</std-ref>, Clause 4</std>
				</source>
				<destination>&lt;&lt;ISO_TS_9002_2016,clause=4,ISO/TS 9002:2016&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std std-id="iso:std:iso:44001:ed-1:en:clause:F" type="dated">
						<std-ref>ISO 44001:2017<?doi https://doi.org/10.3403/30353016?>
						</std-ref>, Annex F</std>
				</source>
				<destination>&lt;&lt;ISO_44001_2017,annex=F&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std std-id="iso:std:iso:44001:ed-1:en:clause:3.10" type="dated">
						<std-ref>ISO 44001:2017<?doi https://doi.org/10.3403/30353016?>
						</std-ref>, 3.10</std>
				</source>
				<destination>&lt;&lt;ISO_44001_2017,clause=3.10&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>ISO 44001:2017<?doi https://doi.org/10.3403/30353016?>
						</std-ref>8.2.7 and 8.3.5</std>
				</source>
				<destination>&lt;&lt;ISO_44001_2017,clause=8.2.7;and!clause=8.3.5&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>ISO 10667 series</std-ref>
					</std>
				</source>
				<destination>&lt;&lt;ISO_10667_series,ISO 10667 series&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std><std-ref>ISO 10667 series</std-ref>, Annex A</std>
				</source>
				<destination>&lt;&lt;ISO_10667_series,annex=A,ISO 10667 series&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>Clauses 1 to 9 of <std-ref type="undated">PAS 2030<?doi https://doi.org/10.3403/30248249U?></std-ref></std>
				</source>
				<!-- <destination>&lt;&lt;PAS_2030,from!clause=1;to!clause=9,PAS 2030&gt;&gt;</destination> -->
				<destination>&lt;&lt;PAS_2030,from!clause=1;to!clause=9&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS 5839‑1:2013<?doi https://doi.org/10.3403/30260279?>
						</std-ref>, <bold>22.3</bold>, <bold>22.5</bold>, <bold>22.7</bold> and <bold>22.9</bold>
					</std>
				</source>
				<destination>&lt;&lt;BS_5839_1_2013;and!clause=22.3;and!clause=22.5;and!clause=22.7;and!clause=22.9&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std std-id="BS EN ISO 14064" type="undated">
						<std-ref>BS EN ISO 14064<?doi https://doi.org/10.3403/BSENISO14064?>
						</std-ref> (all parts)</std>
				</source>
				<destination>&lt;&lt;BS_EN_ISO_14064,BS EN ISO 14064 (all parts)&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std std-id="BS 8900" type="undated">
						<std-ref>BS&#x00A0;8900</std-ref> (series)</std>
				</source>
				<destination>&lt;&lt;BS_8900,BS&#x00A0;8900 (series)&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>ANSI/AAMI ST79</std-ref>
					</std>
				</source>
				<!-- <destination>&lt;&lt;ANSI_AAMI_ST79,ANSI/AAMI ST79&gt;&gt;</destination> -->
				<destination>&lt;&lt;ANSI_AAMI_ST79&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std std-id="iso:std:iso:11137:en" type="undated">
						<std-ref>ISO 11137 (all parts)</std-ref>
					</std>
				</source>
				<destination>&lt;&lt;ISO_11137__all_parts_,ISO 11137 (all parts)&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>JIS P-8144</std-ref>
					</std>
				</source>
				<!-- <destination>&lt;&lt;JIS_P_8144,JIS P-8144&gt;&gt;</destination> -->
				<destination>&lt;&lt;JIS_P_8144,JIS P-8144&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std std-id="iso:std:iso-iec:27001:en:clause:A" type="undated">Annex A of<std-ref>ISO/IEC 27001<?doi https://doi.org/10.3403/30126472U?>
						</std-ref>
					</std>
				</source>
				<!-- <destination>&lt;&lt;ISO_IEC_27001,annex=A,ISO/IEC 27001&gt;&gt;</destination> -->
				<destination>&lt;&lt;ISO_IEC_27001,annex=A&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std std-id="iso:std:iso-iec:27002:ed-2:en:clause:18.1.4" type="dated">18.1.4 of<std-ref>ISO/IEC 27002:2013<?doi https://doi.org/10.3403/30186138?>
						</std-ref>
					</std>
				</source>
				<!-- <destination>&lt;&lt;ISO_IEC_27002_2013,clause=18.1.4,ISO/IEC 27002:2013&gt;&gt;</destination> -->
				<destination>&lt;&lt;ISO_IEC_27002_2013,clause=18.1.4&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS 5839‑1:2013<?doi https://doi.org/10.3403/30260279?>
						</std-ref>, <bold>29.2</bold>
					</std>
				</source>
				<destination>&lt;&lt;BS_5839_1_2013,clause=29.2&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS 9999:2017<?doi https://doi.org/10.3403/30314118?>
						</std-ref>, Clause <bold>4</bold>
					</std>
				</source>
				<destination>&lt;&lt;BS_9999_2017,clause=4&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS 9999:2017<?doi https://doi.org/10.3403/30314118?>
						</std-ref>,<bold>8.3.2</bold>
					</std>
				</source>
				<destination>&lt;&lt;BS_9999_2017,clause=8.3.2&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS 9999:2017<?doi https://doi.org/10.3403/30314118?>
						</std-ref>, Section <bold>9</bold>
					</std>
				</source>
				<destination>&lt;&lt;BS_9999_2017,section=9&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS 9999:2017<?doi https://doi.org/10.3403/30314118?>
						</std-ref>, Table 4</std>
				</source>
				<destination>&lt;&lt;BS_9999_2017,table=4&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS 9999:2017<?doi https://doi.org/10.3403/30314118?>
						</std-ref>,<bold>6.5</bold>
					</std>
				</source>
				<destination>&lt;&lt;BS_9999_2017,clause=6.5&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS 9999:2017<?doi https://doi.org/10.3403/30314118?>
						</std-ref>, Clause <bold>15</bold> to Clause <bold>17</bold>
					</std>
				</source>
				<destination>&lt;&lt;BS_9999_2017,from!clause=15;to!clause=17&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS 9999:2017<?doi https://doi.org/10.3403/30314118?>
						</std-ref>,<bold>16.6.1</bold> and Table 12</std>
				</source>
				<destination>&lt;&lt;BS_9999_2017,clause=16.6.1;and!table=12&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS 9990:2015<?doi https://doi.org/10.3403/30301828?>
						</std-ref>,<bold>4.1.1</bold>
					</std>
				</source>
				<destination>&lt;&lt;BS_9990_2015,clause=4.1.1&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS EN 45545‑2:2013+A1</std-ref>, R7</std>
				</source>
				<destination>&lt;&lt;BS_EN_45545_2_2013_A1,droploc%locality:requirement=R7&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS 9999:2017<?doi https://doi.org/10.3403/30314118?>
						</std-ref>, Table 23 or Table 24</std>
				</source>
				<destination>&lt;&lt;BS_9999_2017,table=23;or!table=24&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS 9999:2017<?doi https://doi.org/10.3403/30314118?>
						</std-ref>, Table 4 and <bold>6.5</bold>
					</std>
				</source>
				<destination>&lt;&lt;BS_9999_2017,table=4;and!table=6.5&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS ISO 44001:2017</std-ref>, Table C1</std>
				</source>
				<destination>&lt;&lt;BS_ISO_44001_2017,table=C1&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS ISO 44001</std-ref>, Clause 4 to Clause 10</std>
				</source>
				<destination>&lt;&lt;BS_ISO_44001,from!clause=4;to!clause=10&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS EN 206:2013+A1:2016</std-ref>, <bold>5.2.5.2.3</bold>
					</std>
				</source>
				<destination>&lt;&lt;BS_EN_206_2013_A1_2016,clause=5.2.5.2.3&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS 8500‑1:2015+A2:2019</std-ref>,<bold>A.8.1</bold>
					</std>
				</source>
				<destination>&lt;&lt;BS_8500_1_2015_A2_2019,annex=A.8.1&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS EN 206:2013+A1:2016</std-ref>, <bold>8.1</bold> and <bold>8.2.1.2</bold>
					</std>
				</source>
				<destination>&lt;&lt;BS_EN_206_2013_A1_2016,clause=8.1;and!clause=8.2.1.2&gt;&gt;</destination>
			</item>
			
			<item>
				<source>
					<std std-id="BS 5482-1" type="undated">
						<bold>
							<std-ref>BS 5482‑1<?doi https://doi.org/10.3403/01017825U?>
							</std-ref>
						</bold>
					</std>
				</source>
				<destination>*&lt;&lt;BS_5482_1&gt;&gt;*</destination>
			</item>
			
			<item>
				<source>
					<std std-id="BS EN 806-1" type="undated">
						<bold>
							<std-ref>BS EN 806‑1</std-ref>
						</bold>
					</std>
				</source>
				<destination>*&lt;&lt;BS_EN_806_1&gt;&gt;*</destination>
			</item>
			
			<item>
				<source>
					<std>
						<std-ref>BS EN ISO 19011:2018<?doi https://doi.org/10.3403/30354835?>
						</std-ref>,<bold>3.3</bold> and <bold>3.2</bold>
					</std>
				</source>
				<destination>&lt;&lt;BS_EN_ISO_19011_2018,clause=3.3;and!clause=3.2&gt;&gt;</destination>
			</item>
			
		</xsl:variable>
		
		<xsl:for-each select="xalan:nodeset($data)//item">
			<xsl:variable name="result">
				<xsl:apply-templates select="source"/>
			</xsl:variable>
			<xsl:call-template name="print_difference">
				<xsl:with-param name="result" select="$result"/>
				<xsl:with-param name="destination" select="destination"/>
			</xsl:call-template>
		</xsl:for-each>
		
	</xsl:template>
	
	<xsl:template name="self_testing_termsource">

		<xsl:variable name="data">
			<item>
				<source>
					<tbx:source>Waste Framework Directive [<xref rid="biblref_1" ref-type="bibr">1</xref>]</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<xsl:text>&lt;&lt;biblref_1,Waste Framework Directive &gt;&gt;</xsl:text>
				</destination>
			</item>
			
			<item>
				<source>
					<tbx:source>ISO 15270, modified</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_ISO_15270,ISO 15270&gt;&gt;,</xsl:text> -->
					<xsl:text>&lt;&lt;ISO_15270&gt;&gt;,</xsl:text> <!-- ,ISO 15270 -->
				</destination>
			</item>
			
			<item>
				<source>
					<tbx:source>BS EN ISO 14001:2004,<bold>
					<xref rid="sec_3.6" ref-type="sec">3.6</xref>
					</bold>, modified</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_BS_EN_ISO_14001_2004,clause 3.6,BS EN ISO 14001:2004&gt;&gt;,</xsl:text> -->
					<xsl:text>&lt;&lt;BS_EN_ISO_14001_2004,clause 3.6&gt;&gt;,</xsl:text> <!-- ,BS EN ISO 14001:2004 -->
				</destination>
			</item>
			
			<item>
				<source>
					<tbx:source>BS EN ISO 14001:2004,<bold>
							<xref rid="sec_3.7" ref-type="sec">3.7</xref>
						</bold>
					</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_BS_EN_ISO_14001_2004,clause 3.7,BS EN ISO 14001:2004&gt;&gt;</xsl:text> -->
					<xsl:text>&lt;&lt;BS_EN_ISO_14001_2004,clause 3.7&gt;&gt;</xsl:text> <!-- ,BS EN ISO 14001:2004 -->
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>BS 8888:2008</tbx:source></source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_BS_8888_2008,BS 8888:2008&gt;&gt;</xsl:text> -->
					<xsl:text>&lt;&lt;BS_8888_2008&gt;&gt;</xsl:text> <!-- ,BS 8888:2008 -->
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>ISO 9000:2005,<bold>3.4.1</bold>, modified</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_ISO_9000_2005,clause 3.4.1,ISO 9000:2005&gt;&gt;,</xsl:text> -->
					<xsl:text>&lt;&lt;ISO_9000_2005,clause 3.4.1&gt;&gt;,</xsl:text> <!-- ,ISO 9000:2005 -->
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>PAS 91:2013 Construction prequalification questionnaires</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_PAS_91_2013_Construction_prequalification_questionnaires,PAS 91:2013 Construction prequalification questionnaires&gt;&gt;</xsl:text> -->
					<xsl:text>&lt;&lt;PAS_91_2013_Construction_prequalification_questionnaires,PAS 91:2013 Construction prequalification questionnaires&gt;&gt;</xsl:text>
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>Quoted from PD 25222:2011 Business continuity management – Guidance on supply chain continuity</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source%quoted]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_Quoted_from_PD_25222_2011_Business_continuity_management___Guidance_on_supply_chain_continuity,Quoted from PD 25222:2011 Business continuity management – Guidance on supply chain continuity&gt;&gt;</xsl:text> -->
					<xsl:text>&lt;&lt;PD_25222_2011_Business_continuity_management_Guidance_on_supply_chain_continuity&gt;&gt;</xsl:text>
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>BS ISO 10007:2003,<bold>3.6</bold></tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_BS_ISO_10007_2003,clause 3.6,BS ISO 10007:2003&gt;&gt;</xsl:text> -->
					<xsl:text>&lt;&lt;BS_ISO_10007_2003,clause 3.6&gt;&gt;</xsl:text> <!-- ,BS ISO 10007:2003 -->
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>BS EN 1900:1998,<bold>3.3.1</bold>, modified</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_BS_EN_1900_1998,clause 3.3.1,BS EN 1900:1998&gt;&gt;,</xsl:text> -->
					<xsl:text>&lt;&lt;BS_EN_1900_1998,clause 3.3.1&gt;&gt;,</xsl:text> <!-- ,BS EN 1900:1998 -->
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>ISO 16642:2017, 3.22, modified – new terms “concept entry” and “entry” added, synonym “TE” deleted, preferred term now is “concept entry” instead of “terminological entry”, Note 1 to entry deleted.</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_ISO_16642_2017,clause 3.22,ISO 16642:2017&gt;&gt;,new terms “concept entry” and “entry” added, synonym “TE” deleted, preferred term now is “concept entry” instead of “terminological entry”, Note 1 to entry deleted.</xsl:text> -->
					<xsl:text>&lt;&lt;ISO_16642_2017,clause 3.22&gt;&gt;,new terms “concept entry” and “entry” added, synonym “TE” deleted, preferred term now is “concept entry” instead of “terminological entry”, Note 1 to entry deleted.</xsl:text> <!-- ,ISO 16642:2017 -->
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>CEN/CENELEC Internal Regulations, Part 2:2015, definition<bold>2.14</bold>[<xref rid="biblref_1" ref-type="bibr">1</xref>]</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;biblref_1,locality:definition=2.14,CEN/CENELEC Internal Regulations,Part 2:2015&gt;&gt;</xsl:text> -->
					<xsl:text>&lt;&lt;biblref_1,locality:definition=2.14&gt;&gt;</xsl:text>
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>BS EN ISO 9000:2005, definition<bold>3.6.1</bold>, modified</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_BS_EN_ISO_9000_2005,locality:definition=3.6.1,BS EN ISO 9000:2005&gt;&gt;,</xsl:text> -->
					<xsl:text>&lt;&lt;BS_EN_ISO_9000_2005,locality:definition=3.6.1&gt;&gt;,</xsl:text> <!-- ,BS EN ISO 9000:2005 -->
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>ISO/IEC Guide 2:2004, definition<bold>1.7</bold>[<xref rid="biblref_2" ref-type="bibr">2</xref>]</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;biblref_2,locality:definition=1.7,ISO/IEC Guide 2:2004&gt;&gt;</xsl:text> -->
					<xsl:text>&lt;&lt;biblref_2,locality:definition=1.7&gt;&gt;</xsl:text>
				</destination>
			</item>

			<item>
				<source><tbx:source>BS ISO 26000:2010, definition<bold>2.2</bold></tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_BS_ISO_26000_2010,locality:definition=2.2,BS ISO 26000:2010&gt;&gt;</xsl:text> -->
					<xsl:text>&lt;&lt;BS_ISO_26000_2010,locality:definition=2.2&gt;&gt;</xsl:text> <!-- ,BS ISO 26000:2010 -->
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>ISO 9000:2015, 3.6.15, modified by using the term “entity” instead of “object” and by replacing Notes 1 and 2 to entry with the new Notes 1 to 4 to entry.</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_ISO_9000_2015,clause 3.6.15,ISO 9000:2015&gt;&gt;,by using the term “entity” instead of “object” and by replacing Notes 1 and 2 to entry with the new Notes 1 to 4 to entry.</xsl:text> -->
					<xsl:text>&lt;&lt;ISO_9000_2015,clause 3.6.15&gt;&gt;,by using the term “entity” instead of “object” and by replacing Notes 1 and 2 to entry with the new Notes 1 to 4 to entry.</xsl:text> <!-- ,ISO 9000:2015 -->
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>ISO 9000:2015, 3.5.1</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_ISO_9000_2015,clause 3.5.1,ISO 9000:2015&gt;&gt;</xsl:text> -->
					<xsl:text>&lt;&lt;ISO_9000_2015,clause 3.5.1&gt;&gt;</xsl:text> <!-- ,ISO 9000:2015 -->
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>Oxford English Dictionary, modified</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_Oxford_English_Dictionary,Oxford English Dictionary&gt;&gt;,</xsl:text> -->
					<xsl:text>&lt;&lt;Oxford_English_Dictionary,Oxford English Dictionary&gt;&gt;,</xsl:text>
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>
						<std>
							<std-ref>BS 5839‑1:2013<?doi https://doi.org/10.3403/00862786U?>
							</std-ref>
						</std>, <bold>3.12</bold>
					</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_BS_5839_1_2013,clause 3.12,BS 5839‑1:2013&gt;&gt;</xsl:text> -->
					<xsl:text>&lt;&lt;BS_5839_1_2013,clause 3.12&gt;&gt;</xsl:text> <!-- ,BS 5839‑1:2013 -->
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>BS 9999:2017,<bold>3.91</bold>, modified – note added</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_BS_9999_2017,clause 3.91,BS 9999:2017&gt;&gt;,note added</xsl:text> -->
					<xsl:text>&lt;&lt;BS_9999_2017,clause 3.91&gt;&gt;,note added</xsl:text> <!-- ,BS 9999:2017 -->
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>GHTF/SG1/N055:2009, 5.2</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_GHTF_SG1_N055_2009,clause 5.2,GHTF/SG1/N055:2009&gt;&gt;</xsl:text> -->
					<!-- <xsl:text>&lt;&lt;GHTF_SG1_N055_2009,clause 5.2,GHTF/SG1/N055:2009&gt;&gt;</xsl:text> -->
					<xsl:text>&lt;&lt;GHTF_SG1_N055_2009,clause 5.2&gt;&gt;</xsl:text>
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>GHTF/SG5/N4:2010, Clause 4</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_GHTF_SG5_N4_2010,clause 4,GHTF/SG5/N4:2010&gt;&gt;</xsl:text> -->
					<!-- <xsl:text>&lt;&lt;GHTF_SG5_N4_2010,clause 4,GHTF/SG5/N4:2010&gt;&gt;</xsl:text> -->
					<xsl:text>&lt;&lt;GHTF_SG5_N4_2010,clause 4&gt;&gt;</xsl:text>
				</destination>
			</item>

			<item>
				<source>
					<tbx:source>ISO 9000:2005<xref ref-type="fn" rid="fn_2">
						<sup>2</sup>
					</xref>
					<fn id="fn_2">
						<label>2</label>
						<p>Superseded by ISO 9000:2015.</p>
					</fn>, 3.4.2, modified</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_ISO_9000_2005,clause 3.4.2,ISO 9000:2005, footnote:[Superseded by ISO 9000:2015.]&gt;&gt;,</xsl:text> -->
					<xsl:text>&lt;&lt;ISO_9000_2005,clause 3.4.2&gt;&gt;,</xsl:text> <!-- ISO_9000_2005,clause 3.4.2,ISO 9000:2005 footnote:[Superseded by ISO 9000:2015.] -->
				</destination>
			</item>
			
			<!-- for IEC format -->
			<item>
				<source>	
					<tbx:source>
						<std>
						<std-id std-id-link-type="urn" std-id-type="dated">urn:iec:std:iec:62391-1:2015-10:::#con-3.8</std-id>
						<std-ref>IEC 62391–1:2015</std-ref>, 3.8
						</std>, modified<italic>–</italic>"capacitor" has been replaced by "supercapacitor" and the note has been omitted.</tbx:source>
				</source>
					<destination>
						<xsl:text>[.source]&#xa;</xsl:text>
						<!-- <xsl:text>&lt;&lt;hidden_bibitem_IEC_62391_1_2015,clause=3.8,IEC 62391–1:2015&gt;&gt;,"capacitor" has been replaced by "supercapacitor" and the note has been omitted.</xsl:text> -->
						<xsl:text>&lt;&lt;IEC_62391_1_2015,clause=3.8&gt;&gt;,"capacitor" has been replaced by "supercapacitor" and the note has been omitted.</xsl:text> <!-- ,IEC 62391–1:2015 -->
					</destination>
			</item>
			
			<item>
				<source>
					<tbx:source>
						<std>
						<std-id std-id-link-type="urn" std-id-type="dated">urn:iec:std:iec:62899-101:2019-10:::#con-3.133</std-id>
						<std-ref>IEC 62899–101:2019</std-ref>, 3.133
						</std>
					</tbx:source>
				</source>
				<destination>
					<xsl:text>[.source]&#xa;</xsl:text>
					<!-- <xsl:text>&lt;&lt;hidden_bibitem_IEC_62899_101_2019,clause=3.133,IEC 62899–101:2019&gt;&gt;</xsl:text> -->
					<xsl:text>&lt;&lt;IEC_62899_101_2019,clause=3.133&gt;&gt;</xsl:text> <!-- ,IEC 62899–101:2019 -->
				</destination>
			</item>
			
		</xsl:variable>
	
		<xsl:for-each select="xalan:nodeset($data)//item">
			<xsl:variable name="result">
				<xsl:apply-templates select="source"/>
			</xsl:variable>
			<xsl:call-template name="print_difference">
				<xsl:with-param name="result" select="$result"/>
				<xsl:with-param name="destination" select="destination"/>
			</xsl:call-template>
		</xsl:for-each>
	
	</xsl:template>
	
	<xsl:template name="print_difference">
		<xsl:param name="result"/>
		<xsl:param name="destination"/>
		<xsl:if test="normalize-space($result) != normalize-space(destination)">
			<xsl:message>There is difference between result and expected result:</xsl:message>
			<xsl:message>Result: <xsl:value-of select="normalize-space($result)"/></xsl:message>
			<xsl:message>Expected: <xsl:value-of select="normalize-space($destination)"/></xsl:message>
		</xsl:if>
	</xsl:template>
	
	<!-- =============== -->
	<!-- END self-testing -->
	<!-- =============== -->
	
	<xsl:include href="sts2mn.common.xsl"/>
	
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
		<xsl:text>&gt;</xsl:text>
		<xsl:apply-templates mode="print_as_xml"/>
		<xsl:text>&lt;/</xsl:text>
		<xsl:value-of select="local-name()"/>
		<xsl:text>&gt;</xsl:text>
	</xsl:template>
	
</xsl:stylesheet>