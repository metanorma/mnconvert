<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
					xmlns:mml="http://www.w3.org/1998/Math/MathML" 
					xmlns:tbx="urn:iso:std:iso:30042:ed-1" 
					xmlns:xlink="http://www.w3.org/1999/xlink" 
					xmlns:xalan="http://xml.apache.org/xalan" 
					xmlns:java="http://xml.apache.org/xalan/java" 
					xmlns:redirect="http://xml.apache.org/xalan/redirect"
					xmlns:metanorma-class-util="xalan://org.metanorma.utils.Util"
					exclude-result-prefixes="xalan mml tbx xlink java metanorma-class-util"
					extension-element-prefixes="redirect"
					version="1.0">
	<xsl:output version="1.0" method="xml" encoding="UTF-8" indent="yes"/>
	
	<xsl:param name="debug">false</xsl:param>
	
	<xsl:param name="split-bibdata">false</xsl:param>

	<xsl:param name="outpath"/>

	<xsl:param name="imagesdir" select="'images'"/>

	<xsl:param name="typestandard" />
	
	<xsl:param name="semantic">false</xsl:param>
	<xsl:variable name="semantic_" select="normalize-space($semantic)"/>
	
	<xsl:param name="self_testing">false</xsl:param> <!-- true false -->
	
	<xsl:variable name="inputformat">STS</xsl:variable>
	
	<xsl:variable name="OUTPUT_FORMAT">xml</xsl:variable> <!-- don't change it -->
	
	<xsl:variable name="type_xml">
		<xsl:choose>
			<xsl:when test="$semantic_ = 'true'">semantic</xsl:when>
			<xsl:otherwise>presentation</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:variable name="organization">
		<xsl:choose>
			<xsl:when test="/standard/front/nat-meta/@originator = 'BSI' or /standard/front/iso-meta/secretariat = 'BSI'">BSI</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="/standard/front/*/doc-ident/sdo"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable> 

	<xsl:variable name="_typestandard">
		<xsl:choose>
			<xsl:when test="$typestandard = ''">
				<xsl:choose>
					<xsl:when test="$organization = 'BSI'">bsi</xsl:when>
					<xsl:otherwise>iso</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$typestandard"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:variable name="xml_collection_result_namespace">http://metanorma.org</xsl:variable>
	<xsl:variable name="xml_result_namespace">https://www.metanorma.org/ns/<xsl:value-of select="$_typestandard"/></xsl:variable>

	<xsl:variable name="nat_meta_only">
		<xsl:if test="/standard/front/nat-meta and not(/standard/front/iso-meta) and not(/standard/front/reg-meta)">true</xsl:if>
	</xsl:variable>

	<xsl:variable name="ref_fix">
		<xsl:apply-templates select="/" mode="ref_fix"/>
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

	<xsl:template match="/"> <!-- /* -->
	
		<xsl:for-each select="$updated_xml/*">
	
			<xsl:variable name="xml_result_">
				<xsl:choose>
					<xsl:when test="$split-bibdata = 'true'">
						<xsl:apply-templates select="front"/>
					</xsl:when>
					<xsl:otherwise>
						
						<xsl:choose>
							<xsl:when test=".//sub-part"> <!-- multiple documents in one xml -->
								<metanorma-collection>
									<bibdata type="collection">
										<fetched></fetched>
										<docidentifier type="bsi">bsidocs</docidentifier>
									</bibdata>
									<!-- first document -->
									<doc-container id="doc000000000">
										<xsl:element name="{$_typestandard}-standard">
											<xsl:attribute name="type"><xsl:value-of select="$type_xml"/></xsl:attribute>
											<xsl:apply-templates />
											<xsl:if test="body/sub-part[1]/body/sec[@sec-type = 'norm-refs'] or back/ref-list">
												<bibliography>
													<xsl:apply-templates select="body/sub-part[1]/body/sec[@sec-type = 'norm-refs']" mode="bibliography"/>
													<xsl:apply-templates select="body/sub-part[1]/back/ref-list" mode="bibliography"/>
												</bibliography>
											</xsl:if>
											<xsl:apply-templates select="body/sub-part[1]//sec[@sec-type = 'index'] | body/sub-part[1]//back/sec[@id = 'ind' or @id = 'sec_ind']" mode="index"/>
										</xsl:element>
									</doc-container>
									<!-- 2nd, 3rd, ... documents -->
									<xsl:for-each select="body/sub-part[position() &gt; 1]">
										<xsl:variable name="num" select="position()"/>
										<doc-container id="{format-number($num, 'doc000000000')}">
											<xsl:element name="{$_typestandard}-standard">
												<xsl:attribute name="type"><xsl:value-of select="$type_xml"/></xsl:attribute>
												<xsl:if test="body/*[not(self::sub-part)]">
													<preface>
														<xsl:apply-templates select="body/*[not(self::sub-part)]"/>
													</preface>
												</xsl:if>
												<!-- sections -->
												<xsl:apply-templates select="body/sub-part/*"/>
												<xsl:if test=".//body/sec[@sec-type = 'norm-refs'] or back/ref-list">
													<bibliography>
														<xsl:apply-templates select=".//body/sec[@sec-type = 'norm-refs']" mode="bibliography"/>
														<xsl:apply-templates select=".//back/ref-list" mode="bibliography"/>
													</bibliography>
												</xsl:if>
											</xsl:element>
										</doc-container>
									</xsl:for-each>
								</metanorma-collection>
							</xsl:when>
							<xsl:otherwise>
								<xsl:element name="{$_typestandard}-standard">
									<xsl:attribute name="type"><xsl:value-of select="$type_xml"/></xsl:attribute>
									<xsl:apply-templates />
									<xsl:if test="body/sec[@sec-type = 'norm-refs'] or back/ref-list">
										<bibliography>
											<xsl:apply-templates select="body/sec[@sec-type = 'norm-refs']" mode="bibliography"/>
											<xsl:apply-templates select="back/ref-list" mode="bibliography"/>
										</bibliography>
									</xsl:if>
									<xsl:apply-templates select="//sec[@sec-type = 'index'] | //back/sec[@id = 'ind' or @id = 'sec_ind']" mode="index"/>
								</xsl:element>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			
			<xsl:variable name="xml_result_displayorder">
				<xsl:choose>
					<xsl:when test="$type_xml = 'presentation'">
						<xsl:apply-templates select="xalan:nodeset($xml_result_)" mode="displayorder"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="$xml_result_"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			
			<xsl:variable name="xml_result">
				<xsl:apply-templates select="xalan:nodeset($xml_result_displayorder)" mode="setNamespace"/>
			</xsl:variable>
			
			<xsl:copy-of select="$xml_result"/>
			
			
			<!-- ======================= -->
			<!-- non-processed element checking -->
			<!-- ======================= -->
			
			<xsl:variable name="xml_namespace">http://www.w3.org/XML/1998/namespace</xsl:variable>
			<xsl:variable name="mathml_namespace">http://www.w3.org/1998/Math/MathML</xsl:variable>
			<xsl:variable name="unknown_elements">
				<xsl:for-each select="xalan:nodeset($xml_result)//*">
					<xsl:if test="namespace::*[. != $xml_result_namespace and . != $xml_namespace and . != $mathml_namespace and . != $xml_collection_result_namespace]">
						<element namespace="{namespace::*}">
							<xsl:for-each select="ancestor-or-self::*">
								<xsl:value-of select="local-name()"/><xsl:if test="position() != last()">/</xsl:if>
							</xsl:for-each>
						</element>
					</xsl:if>
				</xsl:for-each>
			</xsl:variable>
		
			<xsl:for-each select="xalan:nodeset($unknown_elements)/*">
				<xsl:if test="position() = 1">
					<xsl:text disable-output-escaping="yes">&lt;!-- </xsl:text>
					<xsl:text>&#xa;Non-processed elements found:&#xa;</xsl:text></xsl:if>
				<xsl:if test="not(preceding-sibling::*/text() = current()/text())">
					<xsl:value-of select="normalize-space()"/><xsl:text>&#xa;</xsl:text>
				</xsl:if>
				<xsl:if test="position() = last()">
					<xsl:text disable-output-escaping="yes"> --&gt;</xsl:text>
				</xsl:if>
			</xsl:for-each>
			<!-- ======================= -->
			<!-- ======================= -->
			
			<xsl:if test="not($split-bibdata = 'true')">
				<!-- create task.copyImages.adoc -->
				<xsl:call-template name="insertTaskImageList"/>
			</xsl:if>
		
		</xsl:for-each>
	</xsl:template>

	<!-- ============= -->
	<!-- front -> bib data -->
	<!-- ============= -->
	<xsl:template match="front"> <!-- mode="bibdata" -->
		
		<xsl:for-each select="nat-meta">
			<bibdata type="standard">
					<xsl:call-template name="xxx-meta">
						<xsl:with-param name="include_iso_meta">true</xsl:with-param>
						<xsl:with-param name="include_reg_meta">true</xsl:with-param>
						<xsl:with-param name="include_std_meta">true</xsl:with-param>
					</xsl:call-template>
			</bibdata>
			<xsl:if test="not($split-bibdata = 'true')">
				<xsl:call-template name="processMetadata"/>
			</xsl:if>
		</xsl:for-each>
		
		<xsl:if test="not(nat-meta)">
		
			<xsl:for-each select="iso-meta | std-doc-meta">
				<bibdata type="standard">
						<xsl:call-template name="xxx-meta">
							<xsl:with-param name="include_reg_meta">true</xsl:with-param>
							<xsl:with-param name="include_std_meta">true</xsl:with-param>
						</xsl:call-template>
				</bibdata>
				<xsl:if test="not($split-bibdata = 'true')">
					<xsl:call-template name="processMetadata"/>
				</xsl:if>
			</xsl:for-each>
		
			<xsl:if test="not(iso-meta)">
				<xsl:for-each select="reg-meta">
					<bibdata type="standard">
							<xsl:call-template name="xxx-meta">
								<xsl:with-param name="include_std_meta">true</xsl:with-param>
							</xsl:call-template>
					</bibdata>
					<xsl:if test="not($split-bibdata = 'true')">
						<xsl:call-template name="processMetadata"/>
					</xsl:if>
				</xsl:for-each>
				
				<xsl:if test="not(reg-meta)">
					<xsl:for-each select="std-meta">
						<bibdata type="standard">
								<xsl:call-template name="xxx-meta"/>
						</bibdata>
						<xsl:if test="not($split-bibdata = 'true')">
							<xsl:call-template name="processMetadata"/>
						</xsl:if>
					</xsl:for-each>
				</xsl:if>
			</xsl:if>
		</xsl:if>
		
		<xsl:if test="not ($split-bibdata = 'true')">
			<xsl:if test="/standard/front/iso-meta or /standard/front/std-doc-meta">
				<boilerplate>
					<copyright-statement>
						<clause>
							<xsl:choose>
								<xsl:when test="$organization = 'BSI'">
									<p id="boilerplate-year">© <xsl:value-of select="/standard/front/iso-meta/permissions/copyright-holder"/><xsl:text> </xsl:text><xsl:value-of select="/standard/front/iso-meta/permissions/copyright-year"/></p>
									<p id="boilerplate-message"><xsl:apply-templates select="/standard/front/iso-meta/permissions/copyright-statement/node()" /></p>
								</xsl:when>
								<xsl:otherwise>
									<xsl:for-each select="/standard/front/iso-meta/permissions/copyright-statement | /standard/front/std-doc-meta/permissions/copyright-statement">
										<p>
											<xsl:copy-of select="@id"/>
											<xsl:apply-templates />
										</p>
									</xsl:for-each>
								</xsl:otherwise>
							</xsl:choose>
						<!-- <xsl:if test="/standard/front/nat-meta">
							<clause>
								<p id="boilerplate-year">© <xsl:value-of select="/standard/front/nat-meta/permissions/copyright-holder"/><xsl:text> </xsl:text><xsl:value-of select="/standard/front/nat-meta/permissions/copyright-year"/></p>
								<p id="boilerplate-message"><xsl:apply-templates select="/standard/front/nat-meta/permissions/copyright-statement" mode="bibdata"/></p>
							</clause>
						</xsl:if> -->
						</clause>
					</copyright-statement>
					<xsl:apply-templates select="/standard/front/iso-meta/permissions/license | /standard/front/std-doc-meta/permissions/license" mode="bibdata"/>
				</boilerplate>
			</xsl:if>
			<xsl:if test="sec or notes or */meta-note">
				<preface>
					
					<xsl:if test="$type_xml = 'presentation' and ($organization = 'BSI' or $organization = 'PAS')">
						<xsl:variable name="model_related_refs_">
							<xsl:for-each select="nat-meta">
								<xsl:call-template name="build_sts_related_refs"/>
							</xsl:for-each>
						</xsl:variable>
						<xsl:variable name="model_related_refs" select="xalan:nodeset($model_related_refs_)"/>
						<xsl:if test="$model_related_refs//item">
							<clause type="related-refs">
								<p><xsl:text>The following BSI references relate to the work on this document:</xsl:text>
									<xsl:for-each select="$model_related_refs//item">
										<br/><xsl:value-of select="."/>
									</xsl:for-each>
								</p>
							</clause>
						</xsl:if>
					</xsl:if>
					
					<xsl:apply-templates select="notes" mode="preface"/>
					<xsl:apply-templates select="sec" mode="preface"/>
					<xsl:if test="$nat_meta_only = 'true'"> <!-- move Introduction section from body to preface, if  nat_meta_only -->
						<xsl:apply-templates select="/standard/body/sec[@sec-type = 'intro']" mode="preface"/>
					</xsl:if>
					
					<xsl:apply-templates select="*/meta-note"/>
					
				</preface>
			</xsl:if>
		</xsl:if>
		
		<!-- ========================== -->
		<!-- check non-processed elements in bibdata -->
		<!-- ========================== -->
		<xsl:variable name="bibdata_check">
			<xsl:apply-templates mode="bibdata_check"/>
		</xsl:variable>			
		<xsl:if test="normalize-space($bibdata_check) != '' or count(xalan:nodeset($bibdata_check)/*) &gt; 0">
			<xsl:text>WARNING! There are unprocessed elements in 'front':
			</xsl:text>
			<xsl:apply-templates select="xalan:nodeset($bibdata_check)" mode="display_check"/>
		</xsl:if>
		<!-- ========================== -->
		<!-- ========================== -->
		
	</xsl:template>

	<xsl:template name="xxx-meta">
		<xsl:param name="include_iso_meta">false</xsl:param>
		<xsl:param name="include_reg_meta">false</xsl:param>
		<xsl:param name="include_std_meta">false</xsl:param>
		<xsl:param name="originator"/>
		
		<!-- title @type="main", "title-intro", type="title-main", type="title-part" -->
		<xsl:apply-templates select="title-wrap" mode="bibdata"/>
		
		<xsl:apply-templates select="self-uri" mode="bibdata"/>
		
		<!-- docidentifier @type="iso", "iso-with-lang", "iso-reference" -->
		<xsl:apply-templates select="std-ref[@type='dated']" mode="bibdata"/>	
		<xsl:apply-templates select="doc-ref" mode="bibdata"/>
		<xsl:apply-templates select="std-ident/std-id-group/std-id[@std-id-type='dated']" mode="bibdata"/>	
		
		
		<xsl:apply-templates select="custom-meta-group/custom-meta[meta-name = 'ISBN']/meta-value" mode="bibdata"/>	
		
		<xsl:apply-templates select="std-ident/isbn[@publication-format = 'PDF']" mode="bibdata"/>
		
		<!-- docnumber -->
		<xsl:apply-templates select="std-ident/doc-number" mode="bibdata"/>
		
		<!-- date @type="published"  on -->
		<xsl:apply-templates select="pub-date" mode="bibdata"/>
		<xsl:apply-templates select="release-date" mode="bibdata"/>
		
		<!-- contributor role @type="author" -->
		<xsl:apply-templates select="doc-ident/sdo" mode="bibdata"/>
		
		<!-- contributor role @type="publisher -->
		<xsl:apply-templates select="std-ident/originator" mode="bibdata"/>
		<xsl:if test="not(std-ident/originator)">
			<xsl:apply-templates select="std-org/std-org-abbrev" mode="bibdata">
				<xsl:with-param name="process">true</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
		
		<xsl:apply-templates select="std-org-group" mode="bibdata"/>
		
		<xsl:apply-templates select="authorization" mode="bibdata"/>
		
		<!-- edition -->
		<xsl:apply-templates select="std-ident/edition" mode="bibdata"/>
		
		<!-- version revision-date -->
		<xsl:apply-templates select="std-ident/version" mode="bibdata"/>
		
		<!-- language -->
		<xsl:apply-templates select="content-language" mode="bibdata"/>
		
		<xsl:apply-templates select="abstract" mode="bibdata"/>
		
		<!-- status/stage @abbreviation , substage -->
		<xsl:apply-templates select="release-version | doc-ident/release-version" mode="bibdata"/>
		
		<!-- relation bibitem -->
		<!-- <xsl:apply-templates select="std-xref" mode="bibdata"/> -->
		<!-- ==================== -->
		<!-- std-xref processing  -->
		<!-- ==================== -->
		<xsl:variable name="relations_">
			<xsl:call-template name="getRelations"/>
		</xsl:variable>
		<xsl:variable name="relations" select="xalan:nodeset($relations_)"/>
		<xsl:for-each select="$relations/relation">
			<relation>
				<xsl:attribute name="type">
					<xsl:choose>
						<xsl:when test="@type = 'revises'">updates</xsl:when>
						<xsl:when test="@type = 'replaces'">obsoletes</xsl:when>
						<xsl:when test="@type = 'amends'">updates</xsl:when>
						<xsl:when test="@type = 'corrects'">updates</xsl:when>
						<xsl:when test="@type = 'informatively-cited-in'">isCitedIn</xsl:when>
						<xsl:when test="@type = 'informatively-cites'">cites</xsl:when>
						<xsl:when test="@type = 'normatively-cited-in'">isCitedIn</xsl:when>
						<xsl:when test="@type = 'normatively-cites'">cites</xsl:when>
						<xsl:when test="@type = 'identical-adopted-from'">adoptedFrom</xsl:when>
						<xsl:when test="@type = 'modified-adopted-from'">adoptedFrom</xsl:when>
						<xsl:when test="@type = 'successor-of'">successorOf</xsl:when>
						<xsl:when test="@type = 'manifestation-of'">manifestationOf</xsl:when>
						<xsl:when test="@type = 'related-directive'">related</xsl:when>
						<xsl:when test="@type = 'related-mandate'">related</xsl:when>
						<xsl:when test="@type = 'supersedes'">obsoletes</xsl:when>
						<xsl:when test="@type = 'related'">related</xsl:when>
						<xsl:when test="@type = 'annotation-of'">annotationOf</xsl:when>
					</xsl:choose>
				</xsl:attribute>
				<xsl:variable name="description">
					<xsl:choose>
						<xsl:when test="@type = 'revises'">revises</xsl:when>
						<xsl:when test="@type = 'replaces'">replaces</xsl:when>
						<xsl:when test="@type = 'amends'">amends</xsl:when>
						<xsl:when test="@type = 'corrects'">corrects</xsl:when>
						<xsl:when test="@type = 'informatively-cited-in'">informatively cited in</xsl:when>
						<xsl:when test="@type = 'informatively-cites'">informatively cites</xsl:when>
						<xsl:when test="@type = 'normatively-cited-in'">normatively cited in</xsl:when>
						<xsl:when test="@type = 'normatively-cites'">normatively cites</xsl:when>
						<xsl:when test="@type = 'identical-adopted-from'">identical adopted from</xsl:when>
						<xsl:when test="@type = 'modified-adopted-from'">modified adopted from</xsl:when>
						<xsl:when test="@type = 'successor-of'"></xsl:when>
						<xsl:when test="@type = 'manifestation-of'"></xsl:when>
						<xsl:when test="@type = 'related-directive'">related directive</xsl:when>
						<xsl:when test="@type = 'related-mandate'">related mandate</xsl:when>
						<xsl:when test="@type = 'supersedes'">supersedes</xsl:when>
						<xsl:when test="@type = 'related'"></xsl:when>
						<xsl:when test="@type = 'annotation-of'"></xsl:when>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="ext_doctype">
					<xsl:choose>
						<xsl:when test="@type = 'related-directive'">directive</xsl:when>
						<xsl:when test="@type = 'related-mandate'">mandate</xsl:when>
					</xsl:choose>
				</xsl:variable>
				<xsl:if test="normalize-space($description) != ''">
					<description><xsl:value-of select="$description"/></description>
				</xsl:if>
				<bibitem>
					<title>--</title>
					<docidentifier><xsl:value-of select="."/></docidentifier>
					<xsl:if test="normalize-space($ext_doctype) != ''">
						<ext>
							<doctype><xsl:value-of select="$ext_doctype"/></doctype>
						</ext>
					</xsl:if>
				</bibitem>
			</relation>
		</xsl:for-each>
		<!-- ==================== -->
		<!-- END: std-xref processing  -->
		<!-- ==================== -->
		
		<xsl:if test="$include_iso_meta = 'true'">
			<xsl:for-each select="ancestor::front/iso-meta">
				<relation type="adopted-from">
					<bibitem>
						<xsl:call-template name="xxx-meta"/> <!-- process iso-meta -->
					</bibitem>
					<xsl:call-template name="processMetadata"/>
				</relation>
			</xsl:for-each>
		</xsl:if>
		
		<xsl:if test="$include_reg_meta = 'true'">
			<xsl:for-each select="ancestor::front/reg-meta">
				<relation type="adopted-from">
					<bibitem>
						<xsl:call-template name="xxx-meta"> <!-- process reg-meta -->
							<!-- <xsl:with-param name="originator" select="std-ident/originator"/> -->
						</xsl:call-template>
					</bibitem>
					<xsl:call-template name="processMetadata"/>
				</relation>
			</xsl:for-each>
		</xsl:if>
		
		<!-- <xsl:if test="local-name() != 'reg-meta'">
			<xsl:apply-templates select="ancestor::front/reg-meta" mode="bibdata" />
		</xsl:if> -->
		
		<!-- copyright from, owner/organization/abbreviation -->
		<xsl:apply-templates select="permissions" mode="bibdata"/>
		
		
		<xsl:if test="$organization = 'BSI'">
			<xsl:for-each select="comm-ref">
				<relation type="related">
					<bibitem>
					<title>--</title>
					<docidentifier>Committee reference <xsl:value-of select="."/></docidentifier> <!-- Example: Committee reference DEF/1 -->
					</bibitem>
				</relation>
			</xsl:for-each>
			<xsl:for-each select="std-xref[@type='isPublishedFormatOf']">
				<relation type="related">
					<bibitem>
					<title>--</title>
					<docidentifier>Draft for comment <xsl:value-of select="std-ref"/></docidentifier> <!-- Example: Draft for comment 20/30387670 DC -->
					</bibitem>
				</relation>
			</xsl:for-each>
		</xsl:if>
		
		<xsl:if test="std-ident/doc-type or comm-ref or ics or std-ident or doc-ident/release-version or release-version or secretariat">
			<ext>
				<xsl:apply-templates select="std-ident/doc-type" mode="bibdata"/>
				
				<xsl:apply-templates select="custom-meta-group/custom-meta[meta-name = 'horizontal']" mode="bibdata"/>
				
				<xsl:apply-templates select="comm-ref" mode="bibdata"/>
				
				<xsl:apply-templates select="ics" mode="bibdata"/>			
				
				<!-- project number -->
				<xsl:choose>
					<xsl:when test="normalize-space(proj-id) != ''">
						<xsl:apply-templates select="proj-id" mode="bibdata_project_number"/>
					</xsl:when>
					
					<xsl:when test="normalize-space(doc-ident/proj-id) != '' or normalize-space(std-ident/part-number) != ''">
						<xsl:apply-templates select="doc-ident" mode="bibdata_project_number"/>		
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="std-ident" mode="bibdata"/>		
					</xsl:otherwise>
				</xsl:choose>
				<stagename>
					<xsl:choose>
						<xsl:when test="normalize-space(release-version) != ''">
							<xsl:value-of select="release-version"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="doc-ident/release-version"/>
						</xsl:otherwise>
					</xsl:choose>
				</stagename>
			</ext>
		</xsl:if>
	</xsl:template>

	<xsl:template match="@*|node()" mode="display_check">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="display_check"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="text()"  mode="display_check">
		<xsl:value-of select="normalize-space(.)"/>
	</xsl:template>

	<xsl:template match="@*|node()" mode="bibdata_check">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="bibdata_check"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="text()" mode="bibdata_check">
		<xsl:value-of select="."/>
	</xsl:template>

	
	
	<xsl:template match="iso-meta | nat-meta | reg-meta | std-meta | std-doc-meta | 
																title-wrap" mode="bibdata_check">
		<xsl:apply-templates mode="bibdata_check"/>
	</xsl:template>
	
	
	
	<xsl:template match="title-wrap/intro | title-wrap/intro-title-wrap/intro |
															title-wrap/main | title-wrap/main-title-wrap |
															title-wrap/compl | title-wrap/compl-title-wrap |
															title-wrap/full |
															iso-meta/doc-ref |
															nat-meta/doc-ref |
															reg-meta/doc-ref |
															std-meta/doc-ref |
															std-doc-meta/doc-ref |
															iso-meta/std-ref |
															nat-meta/std-ref |
															reg-meta/std-ref |
															std-meta/std-ref |
															std-doc-meta/std-ref |
															iso-meta/pub-date |
															nat-meta/pub-date |
															reg-meta/pub-date |
															std-meta/pub-date |
															std-doc-meta/pub-date |
															iso-meta/release-date |
															nat-meta/release-date |
															reg-meta/release-date |
															std-meta/release-date |
															std-doc-meta/release-date |
															iso-meta/meta-date |															
															iso-meta/std-ident/doc-number |
															nat-meta/std-ident/doc-number |
															reg-meta/std-ident/doc-number |
															std-meta/std-ident/doc-number |
															std-doc-meta/std-ident/doc-number |
															iso-meta/doc-ident/sdo |
															nat-meta/doc-ident/sdo |
															reg-meta/doc-ident/sdo |
															std-meta/doc-ident/sdo |
															iso-meta/doc-ident/proj-id |
															nat-meta/doc-ident/proj-id |
															reg-meta/doc-ident/proj-id |
															std-meta/doc-ident/proj-id |
															std-meta/proj-id |
															std-doc-meta/proj-id |
															iso-meta/doc-ident/language |
															nat-meta/doc-ident/language |
															reg-meta/doc-ident/language |
															std-meta/doc-ident/language |
															iso-meta/doc-ident/urn |
															iso-meta/std-ident/originator |
															nat-meta/std-ident/originator |
															reg-meta/std-ident/originator |
															std-meta/std-ident/originator |
															std-doc-meta/std-ident/originator |
															iso-meta/std-ident/edition |
															nat-meta/std-ident/edition |
															reg-meta/std-ident/edition |
															std-meta/std-ident/edition |
															std-doc-meta/std-ident/edition |
															iso-meta/std-ident/version |
															nat-meta/std-ident/version |
															reg-meta/std-ident/version |
															std-meta/std-ident/version |
															std-doc-meta/std-ident/version |
															iso-meta/content-language |
															nat-meta/content-language |
															reg-meta/content-language |
															std-meta/content-language |
															std-doc-meta/content-language |
															iso-meta/doc-ident/release-version |
															nat-meta/doc-ident/release-version |
															reg-meta/doc-ident/release-version |
															std-meta/doc-ident/release-version |
															std-meta/release-version |
															iso-meta/permissions/copyright-year |
															nat-meta/permissions/copyright-year |
															reg-meta/permissions/copyright-year |
															std-meta/permissions/copyright-year |
															std-doc-meta/permissions/copyright-year |
															iso-meta/permissions/copyright-holder |
															nat-meta/permissions/copyright-holder |
															reg-meta/permissions/copyright-holder |
															std-meta/permissions/copyright-holder |
															std-doc-meta/permissions/copyright-holder |
															iso-meta/permissions/copyright-statement |
															nat-meta/permissions/copyright-statement |
															reg-meta/permissions/copyright-statement |
															std-meta/permissions/copyright-statement |
															std-doc-meta/permissions/copyright-statement |
															iso-meta/permissions/license |
															std-doc-meta/permissions/license |
															iso-meta/std-ident/doc-type |
															nat-meta/std-ident/doc-type |
															reg-meta/std-ident/doc-type |
															std-meta/std-ident/doc-type |
															std-doc-meta/std-ident/doc-type |
															iso-meta/comm-ref |
															nat-meta/comm-ref |
															reg-meta/comm-ref |
															std-meta/comm-ref |
															std-doc-meta/comm-ref |
															iso-meta/secretariat |
															nat-meta/secretariat |
															reg-meta/secretariat |
															std-meta/secretariat |
															std-doc-meta/secretariat |
															iso-meta/ics |
															nat-meta/ics |
															reg-meta/ics |
															std-meta/ics |
															std-doc-meta/ics |
															iso-meta/std-ident/part-number |
															nat-meta/std-ident/part-number |
															reg-meta/std-ident/part-number |
															std-meta/std-ident/part-number |
															std-doc-meta/std-ident/part-number |
															iso-meta/page-count |
															reg-meta/page-count |
															nat-meta/page-count |
															std-meta/page-count |
															std-doc-meta/page-count |
															iso-meta/std-xref |
															nat-meta/std-xref |
															reg-meta/std-xref |
															std-meta/std-xref |
															std-doc-meta/std-xref |
															reg-meta/meta-date |
															reg-meta/wi-number |
															reg-meta/release-version-id |
															iso-meta/custom-meta-group |
															nat-meta/custom-meta-group |
															reg-meta/custom-meta-group |
															std-meta/custom-meta-group |
															iso-meta/std-ident/suppl-number |
															nat-meta/std-ident/suppl-number |
															reg-meta/std-ident/suppl-number |
															std-meta/std-ident/suppl-number |
															iso-meta/std-ident/suppl-version |
															nat-meta/std-ident/suppl-version |
															reg-meta/std-ident/suppl-version |
															std-meta/std-ident/suppl-version |
															nat-meta/std-ident/suppl-type |
															reg-meta/std-ident/suppl-type |
															std-meta/std-ident/suppl-type |
															nat-meta/self-uri |
															reg-meta/self-uri |
															std-meta/self-uri |
															iso-meta/std-org |
															nat-meta/std-org |
															reg-meta/std-org |
															std-meta/std-org |
															iso-meta/std-org/std-org-abbrev |
															nat-meta/std-org/std-org-abbrev |
															reg-meta/std-org/std-org-abbrev |
															std-meta/std-org/std-org-abbrev |
															*[contains(local-name(), '-meta')]/std-ident/std-id-group |
															*[contains(local-name(), '-meta')]/std-org-group |
															*[contains(local-name(), '-meta')]/meta-note |
															*[contains(local-name(), '-meta')]/abstract |
															*[contains(local-name(), '-meta')]/isbn |
															*[contains(local-name(), '-meta')]/std-ident/isbn |
															*[contains(local-name(), '-meta')]/std-ident/issn |
															*[contains(local-name(), '-meta')]/accrediting-organization |
															*[contains(local-name(), '-meta')]/authorization |
															front/notes |
															front/sec " mode="bibdata_check"/>
	
	
	<xsl:template match="iso-meta/doc-ident | nat-meta/doc-ident | reg-meta/doc-ident | std-meta/doc-ident |
															iso-meta/std-ident | nat-meta/std-ident |  reg-meta/std-ident | std-meta/std-ident | std-doc-meta/std-ident |
															iso-meta/permissions | nat-meta/permissions | reg-meta/permissions | std-meta/permissions | std-doc-meta/permissions" mode="bibdata_check">
		<xsl:apply-templates mode="bibdata_check"/>
	</xsl:template>
	
	<xsl:template match="doc-ident" mode="bibdata">
		<xsl:apply-templates mode="bibdata"/>
	</xsl:template>
	
	
	
	
	
	<xsl:template match="iso-meta/title-wrap | nat-meta/title-wrap | reg-meta/title-wrap | std-meta/title-wrap | std-doc-meta/title-wrap" mode="bibdata">
		<!-- <xsl:variable name="lang" select="@xml:lang"/>
		<title language="{$lang}" format="text/plain" type="main">
			<xsl:apply-templates select="full" mode="bibdata"/>
		</title>
		<title language="{$lang}" format="text/plain" type="title-intro">
			<xsl:apply-templates select="intro" mode="bibdata"/>
		</title>
		<title language="{$lang}" format="text/plain" type="title-main">
			<xsl:apply-templates select="main" mode="bibdata"/>
		</title>
		<title language="{$lang}" format="text/plain" type="title-part">
			<xsl:apply-templates select="compl" mode="bibdata"/>
		</title> -->
		
		<xsl:choose>
			<xsl:when test="$organization = 'BSI'">
				<!-- priority: get intro and compl from separate field -->
				<xsl:variable name="titles">
					<xsl:apply-templates select="intro[normalize-space() != '']" mode="bibdata"/>
					<xsl:apply-templates select="compl[normalize-space() != '']" mode="bibdata"/>
					<xsl:if test="normalize-space(main) = ''">
						<xsl:apply-templates select="full[normalize-space() != '']" mode="bibdata_title_full"/>
					</xsl:if>
					<xsl:if test="normalize-space(intro) = ''">
						<xsl:apply-templates select="main[normalize-space() != '']" mode="bibdata_title_full"/>
					</xsl:if>
					<xsl:if test="normalize-space(intro) != ''">
						<xsl:apply-templates select="main[normalize-space() != '']" mode="bibdata"/>
					</xsl:if>
				</xsl:variable>

				<xsl:variable name="title_components">
					<xsl:copy-of select="xalan:nodeset($titles)/*[@type='title-intro'][1]"/>
					<xsl:copy-of select="xalan:nodeset($titles)/*[@type='title-main'][1]"/>
					<xsl:copy-of select="xalan:nodeset($titles)/*[@type='title-part'][1]"/>
				</xsl:variable>
				
				<xsl:variable name="lang">
					<xsl:call-template name="getLang"/>
				</xsl:variable>
				
				<title language="{$lang}" format="text/plain" type="main">
					<xsl:for-each select="xalan:nodeset($title_components)/*">
						<xsl:apply-templates mode="bibdata"/>
						<xsl:if test="position() != last()"> — </xsl:if>
					</xsl:for-each>
				</title>
				
				<xsl:copy-of select="$title_components"/>
				
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select=".//full[normalize-space() != '']" mode="bibdata"/>
				<xsl:apply-templates select=".//intro[normalize-space() != '']" mode="bibdata"/>
				<xsl:apply-templates select=".//main[normalize-space() != '']" mode="bibdata"/>
				<xsl:apply-templates select=".//compl[normalize-space() != '']" mode="bibdata"/>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>

	
	<xsl:template match="title-wrap/full | title-wrap//main" mode="bibdata_title_full">
	
		<xsl:variable name="title" select="translate(., '–', '—')"/> <!-- replace en dash to em dash -->
		<xsl:variable name="parts">
			<xsl:call-template name="split">
				<xsl:with-param name="pText" select="$title"/>
				<xsl:with-param name="sep" select="'—'"/>
			</xsl:call-template>
		</xsl:variable>
		
		<xsl:variable name="lang">
			<xsl:call-template name="getLang">
				<xsl:with-param name="fromParent">true</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<xsl:for-each select="xalan:nodeset($parts)/*">
			<xsl:if test="position() = 1">
				<title language="{$lang}" format="text/plain" type="title-intro">
					<xsl:apply-templates mode="bibdata"/>
				</title>
			</xsl:if>
			<xsl:if test="position() = 2">
				<title language="{$lang}" format="text/plain" type="title-main">
					<xsl:apply-templates mode="bibdata"/>
				</title>
			</xsl:if>
			<xsl:if test="position() &gt; 2">
				<title language="{$lang}" format="text/plain" type="title-part">
					<xsl:apply-templates mode="bibdata"/>
				</title>
			</xsl:if>
		</xsl:for-each>
		
	</xsl:template>
	
	<xsl:template match="title-wrap/full" mode="bibdata">
		<xsl:variable name="lang">
			<xsl:call-template name="getLang">
				<xsl:with-param name="fromParent">true</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<title language="{$lang}" format="text/plain" type="main">
			<xsl:apply-templates mode="bibdata"/>
		</title>
	</xsl:template>
	
	<xsl:template match="title-wrap//intro" mode="bibdata">
		<xsl:variable name="lang">
			<xsl:call-template name="getLang">
				<xsl:with-param name="fromParent">true</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<title language="{$lang}" format="text/plain" type="title-intro">
			<xsl:apply-templates mode="bibdata"/>
		</title>
	</xsl:template>
	
	<xsl:template match="title-wrap//main" mode="bibdata">
		<xsl:variable name="lang">
			<xsl:call-template name="getLang">
				<xsl:with-param name="fromParent">true</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<title language="{$lang}" format="text/plain" type="title-main">
			<xsl:apply-templates mode="bibdata"/>
		</title>
	</xsl:template>
	
	<xsl:template match="title-wrap//compl" mode="bibdata">
		<xsl:variable name="lang">
			<xsl:call-template name="getLang">
				<xsl:with-param name="fromParent">true</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<title language="{$lang}" format="text/plain" type="title-part">
			<xsl:apply-templates mode="bibdata"/>
		</title>
	</xsl:template>
  
  
	<xsl:template match="iso-meta/std-ref[@type='dated'] | nat-meta/std-ref[@type='dated'] | reg-meta/std-ref[@type='dated'] | std-meta/std-ref[@type='dated'] | std-doc-meta/std-ident//std-id[@std-id-type='dated']" mode="bibdata">
		<docidentifier type="ISO">
			<xsl:apply-templates mode="bibdata"/>
		</docidentifier>
		<xsl:variable name="language_1st_letter" select="normalize-space(substring(//*[contains(local-name(), '-meta')]/doc-ident/language,1,1))"/> <!-- iso-meta -->
		
		<xsl:variable name="language_">
			<xsl:value-of select="$language_1st_letter"/>
			<xsl:if test="$language_1st_letter = ''"><xsl:value-of select="substring(ancestor::*[content-language]/content-language, 1, 1)"/></xsl:if>
		</xsl:variable>
		
		<xsl:variable name="language" select="java:toUpperCase(java:java.lang.String.new($language_))"/>
		<docidentifier type="iso-with-lang">
			<xsl:apply-templates mode="bibdata"/>
			<xsl:text>(</xsl:text><xsl:value-of select="$language"/><xsl:text>)</xsl:text>
		</docidentifier>
		<docidentifier type="iso-reference">
			<xsl:apply-templates mode="bibdata"/>
			<xsl:text>(</xsl:text><xsl:value-of select="$language"/><xsl:text>)</xsl:text>
		</docidentifier>
	</xsl:template>
	
	<xsl:template match="iso-meta/doc-ref | nat-meta/doc-ref | reg-meta/doc-ref | std-meta/doc-ref" mode="bibdata">
		<xsl:variable name="iso_reference">
			<xsl:apply-templates mode="bibdata"/>
		</xsl:variable>
		<xsl:if test="normalize-space($iso_reference) != ''">
			<docidentifier type="iso-reference">
				<xsl:value-of select="normalize-space($iso_reference)"/>
			</docidentifier>
		</xsl:if>
	</xsl:template>

	<xsl:template match="custom-meta-group/custom-meta[meta-name = 'ISBN']/meta-value" mode="bibdata">
		<docidentifier type="ISBN"><xsl:apply-templates mode="bibdata"/></docidentifier>
	</xsl:template>
	
	<xsl:template match="std-ident/isbn[@publication-format = 'PDF']" mode="bibdata">
		<docidentifier type="ISBN"><xsl:apply-templates mode="bibdata"/></docidentifier>
	</xsl:template>
	
	<xsl:template name="processMetadata">
		<xsl:variable name="metanorma-extension">
			<xsl:apply-templates select="custom-meta-group/custom-meta[meta-name = 'TOC Heading Level']/meta-value" mode="bibdata"/>
			<xsl:apply-templates select="(//list-item[not(ancestor::non-normative-note)][1]/label/styled-content/@style[contains(., 'color:')])[1]" mode="bibdata"/>
			<xsl:apply-templates select="doc-ident/proj-id" mode="bibdata"/>
			<xsl:apply-templates select="std-ident/suppl-type" mode="bibdata"/>
			<xsl:apply-templates select="std-ident/suppl-number" mode="bibdata"/>
			<xsl:apply-templates select="std-ident/suppl-version" mode="bibdata"/>
			<xsl:apply-templates select="meta-date" mode="bibdata"/>
			<xsl:apply-templates select="wi-number" mode="bibdata"/>
			<xsl:apply-templates select="release-version-id" mode="bibdata"/>
			<xsl:apply-templates select="page-count" mode="bibdata"/>
			<xsl:apply-templates select="custom-meta-group/custom-meta[not(meta-name = 'TOC Heading Level' or meta-name = 'ISBN' or meta-name = 'horizontal')]" mode="bibdata"/>
			<xsl:apply-templates select="permissions/copyright-statement" mode="bibdata"/>
			<xsl:apply-templates select="std-ident/isbn[@publication-format = 'HTML']" mode="bibdata"/>
			<xsl:apply-templates select="std-ident/issn" mode="bibdata"/>
			<xsl:apply-templates select="accrediting-organization" mode="bibdata"/>
		</xsl:variable>
		<xsl:if test="xalan:nodeset($metanorma-extension)/*">
			<metanorma-extension>
				<xsl:copy-of select="$metanorma-extension"/>
			</metanorma-extension>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="custom-meta-group/custom-meta[meta-name = 'TOC Heading Level']/meta-value" mode="bibdata">
		<presentation-metadata>
			<name>TOC Heading Levels</name>
			<value><xsl:apply-templates mode="bibdata"/></value>
		</presentation-metadata>
	</xsl:template>
	
	
	<!-- :presentation-metadata-color-list-label: #009fe3 -->
	<xsl:template match="list-item[not(ancestor::non-normative-note)]/label/styled-content/@style" mode="bibdata">
		<xsl:variable name="value"><xsl:call-template name="getStyleColor"/></xsl:variable>
		<xsl:if test="$value != ''">
			<presentation-metadata>
				<color-list-label><xsl:value-of select="$value"/></color-list-label>
			</presentation-metadata>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="doc-ident/proj-id[normalize-space() != '']" mode="bibdata">
		<semantic-metadata><proj-id><xsl:apply-templates mode="bibdata"/></proj-id></semantic-metadata>
	</xsl:template>
	
	<xsl:template match="std-ident/suppl-type[normalize-space() != '']" mode="bibdata">
		<semantic-metadata><suppl-type><xsl:apply-templates mode="bibdata"/></suppl-type></semantic-metadata>
	</xsl:template>
	
	<xsl:template match="std-ident/suppl-number[normalize-space() != '']" mode="bibdata">
		<semantic-metadata><suppl-number><xsl:apply-templates mode="bibdata"/></suppl-number></semantic-metadata>
	</xsl:template>
	
	<xsl:template match="std-ident/suppl-version[normalize-space() != '']" mode="bibdata">
		<semantic-metadata><suppl-version><xsl:apply-templates mode="bibdata"/></suppl-version></semantic-metadata>
	</xsl:template>
	
	<xsl:template match="meta-date[normalize-space(@type) != '']" mode="bibdata">
		<semantic-metadata>
			<xsl:element name="{java:toLowerCase(java:java.lang.String.new(@type))}">
				<xsl:apply-templates mode="bibdata"/>
			</xsl:element>
		</semantic-metadata>
	</xsl:template>
	
	<xsl:template match="wi-number[normalize-space() != '']" mode="bibdata">
		<semantic-metadata><wi-number><xsl:apply-templates mode="bibdata"/></wi-number></semantic-metadata>
	</xsl:template>
	
	<xsl:template match="release-version-id[normalize-space() != '']" mode="bibdata">
		<semantic-metadata><release-version-id><xsl:apply-templates mode="bibdata"/></release-version-id></semantic-metadata>
	</xsl:template>
	
	<xsl:template match="page-count[normalize-space(@count) != '']" mode="bibdata">
		<semantic-metadata><page-count><xsl:value-of select="@count"/></page-count></semantic-metadata>
	</xsl:template>
	
	<xsl:template match="permissions/copyright-statement[normalize-space() != '']" mode="bibdata">
		<semantic-metadata><copyright-statement><xsl:apply-templates mode="bibdata"/></copyright-statement></semantic-metadata>
	</xsl:template>
	
	<xsl:template match="custom-meta-group/custom-meta[not(meta-name = 'TOC Heading Level' or meta-name = 'ISBN' or meta-name = 'horizontal')]" mode="bibdata">
		<semantic-metadata>
			<xsl:element name="{translate(java:toLowerCase(java:java.lang.String.new(meta-name)), ' ', '-')}">
				<xsl:apply-templates select="meta-value" mode="bibdata"/>
			</xsl:element>
		</semantic-metadata>
	</xsl:template>
	
	<xsl:template match="isbn[@publication-format = 'HTML']" mode="bibdata">
		<semantic-metadata><isbn-html><xsl:apply-templates mode="bibdata"/></isbn-html></semantic-metadata>
	</xsl:template>
	
	<xsl:template match="issn" mode="bibdata">
		<semantic-metadata><issn><xsl:apply-templates mode="bibdata"/></issn></semantic-metadata>
	</xsl:template>
	
	<xsl:template match="accrediting-organization" mode="bibdata">
		<semantic-metadata><accrediting-organization><xsl:apply-templates mode="bibdata"/></accrediting-organization></semantic-metadata>
	</xsl:template>
	
	<xsl:template match="iso-meta/std-ident/doc-number | nat-meta/std-ident/doc-number | reg-meta/std-ident/doc-number | std-meta/std-ident/doc-number | std-doc-meta/std-ident/doc-number" mode="bibdata">
		<docnumber>
			<xsl:apply-templates mode="bibdata"/>
		</docnumber>
	</xsl:template>
	

	<xsl:template match="iso-meta/pub-date | nat-meta/pub-date | reg-meta/pub-date | std-meta/pub-date | std-doc-meta/pub-date" mode="bibdata">
		<date type="published">
			<on>
				<!-- <xsl:apply-templates mode="bibdata"/> -->
				<xsl:call-template name="getDate"/>
			</on>
		</date>
	</xsl:template>
	
	<xsl:template match="iso-meta/release-date | nat-meta/release-date | reg-meta/release-date | std-meta/release-date | std-doc-meta/release-date" mode="bibdata">
		<date type="release">
			<xsl:if test="@date-type = 'approved' and ancestor::std-doc-meta">
				<xsl:attribute name="type">issued</xsl:attribute>
			</xsl:if>
			<on>
				<!-- <xsl:apply-templates mode="bibdata"/> -->
				<xsl:call-template name="getDate"/>
			</on>
		</date>
	</xsl:template>
			
	<xsl:template name="getDate">
		<xsl:choose>
			<xsl:when test="normalize-space(@iso-8601-date) != ''"><xsl:value-of select="@iso-8601-date"/></xsl:when>
			<xsl:otherwise><xsl:apply-templates mode="bibdata"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="iso-meta/doc-ident/sdo | nat-meta/doc-ident/sdo | reg-meta/doc-ident/sdo | std-meta/doc-ident/sdo" mode="bibdata">
		<contributor>
			<role type="author"/>
			<organization>
				<xsl:variable name="abbreviation">
					<xsl:apply-templates mode="bibdata"/>
				</xsl:variable>
				<xsl:call-template name="organization_name_by_abbreviation">
					<xsl:with-param name="abbreviation" select="$abbreviation"/>
				</xsl:call-template>
				<abbreviation>
					<xsl:value-of select="$abbreviation"/>
				</abbreviation>
			</organization>
		</contributor>
	</xsl:template>
	
	
	<xsl:template match="iso-meta/std-ident/originator | nat-meta/std-ident/originator | reg-meta/std-ident/originator | std-meta/std-ident/originator | std-doc-meta/std-ident/originator" mode="bibdata" name="publisher">
		<contributor>
			<role type="publisher"/>
				<organization>
					<xsl:variable name="abbreviation">
						<xsl:apply-templates mode="bibdata"/>
					</xsl:variable>
					<xsl:call-template name="organization_name_by_abbreviation">
						<xsl:with-param name="abbreviation" select="$abbreviation"/>
					</xsl:call-template>
					<abbreviation>
						<xsl:value-of select="$abbreviation"/>
					</abbreviation>
				</organization>
		</contributor>
	</xsl:template>
	
	<xsl:template match="iso-meta//std-org/std-org-abbrev | nat-meta//std-org/std-org-abbrev | reg-meta//std-org/std-org-abbrev | std-meta//std-org/std-org-abbrev | std-doc-meta//std-org/std-org-abbrev" mode="bibdata">
		<xsl:param name="process">false</xsl:param>
		<xsl:if test="$process = 'true'">
			<xsl:call-template name="publisher"/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="iso-meta/std-org-group | nat-meta/std-org-group | reg-meta/std-org-group | std-meta/std-org-group | std-doc-meta/std-org-group" mode="bibdata">
		<contributor>
			<role>
				<xsl:attribute name="type">
					<xsl:choose>
						<xsl:when test="std-org/@std-org-role = 'developer'">author</xsl:when>
						<xsl:otherwise>author</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
			</role>
			<organization>
					<name><xsl:value-of select="std-org/std-org-abbrev"/></name>
					<xsl:if test="std-org/std-org-loc">
						<address>
							<formattedAddress>
								<xsl:for-each select="std-org/std-org-loc/*">
									<xsl:apply-templates />
									<xsl:if test="position() != last()"><br/></xsl:if>
								</xsl:for-each>
							</formattedAddress>
						</address>
					</xsl:if>
			</organization>
	</contributor>
	</xsl:template>
	
	<xsl:template match="*[contains(local-name(), '-meta')]/authorization" mode="bibdata">
		<contributor>
			<role type="authorizer" />
			<organization>
					<name>
						<xsl:apply-templates mode="bibdata"/>
						<xsl:apply-templates select="@authorize-acronym" mode="bibdata"/>
					</name>
			</organization>
	</contributor>
	</xsl:template>
	
	<xsl:template match="authorization/@authorize-acronym" mode="bibdata">
		<xsl:value-of select="concat(', ', .)"/>
	</xsl:template>
	
	<xsl:template match="*[self::iso-meta or self::nat-meta or self::reg-meta or self::std-meta or self::std-doc-meta]/std-ident/edition[normalize-space() != '']" mode="bibdata">
		<edition>
			<xsl:apply-templates mode="bibdata"/>
		</edition>
	</xsl:template>
	
	<xsl:template match="*[self::iso-meta or self::nat-meta or self::reg-meta or self::std-meta or self::std-doc-meta]/std-ident/version[normalize-space() != '']" mode="bibdata">
		<version>
			<xsl:variable name="version"><xsl:apply-templates mode="bibdata"/></xsl:variable>
			<xsl:choose>
				<xsl:when test="java:org.metanorma.utils.RegExHelper.matches('^[0-9]{4}-[0-9]{2}-[0-9]{2}$', normalize-space(.)) = 'true'">
					<revision-date>
						<xsl:value-of select="$version"/>
					</revision-date>
				</xsl:when>
				<xsl:otherwise>
					<draft>
						<xsl:value-of select="$version"/>
					</draft>
				</xsl:otherwise>
			</xsl:choose>
			
		</version>
	</xsl:template>
	
	<xsl:template match="*[self::iso-meta or self::nat-meta or self::reg-meta or self::std-meta or self::std-doc-meta]/content-language" mode="bibdata">
		<xsl:variable name="language"><xsl:apply-templates mode="bibdata"/></xsl:variable>
		<language>
			<xsl:if test="$type_xml = 'presentation'">
				<xsl:attribute name="current">true</xsl:attribute>
			</xsl:if>
			<xsl:value-of select="$language"/>
		</language>
		<xsl:choose>
			<xsl:when test="$language = 'en'">
				<script>
					<xsl:if test="$type_xml = 'presentation'">
						<xsl:attribute name="current">true</xsl:attribute>
					</xsl:if>
					<xsl:text>Latn</xsl:text>
				</script>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="*[self::iso-meta or self::nat-meta or self::reg-meta or self::std-meta or self::std-doc-meta]/abstract" mode="bibdata">
		<abstract>
			<xsl:apply-templates select="*[not(self::title)]"/>
		</abstract>
	</xsl:template>
	
	<xsl:template match="iso-meta/doc-ident/release-version | nat-meta/doc-ident/release-version | reg-meta/doc-ident/release-version | std-meta/doc-ident/release-version | std-meta/release-version" mode="bibdata">
		<xsl:variable name="value" select="java:toUpperCase(java:java.lang.String.new(.))"/>
		
		<xsl:variable name="custom-meta_stage" select="normalize-space(../../custom-meta-group/custom-meta[meta-name = 'stage']/meta-value)"/>
		<xsl:variable name="custom-meta_stage_abbreviation" select="normalize-space(../../custom-meta-group/custom-meta[meta-name = 'stage_abbreviation']/meta-value)"/>
		<xsl:variable name="stage">
			<xsl:choose>
				<xsl:when test="$custom-meta_stage != ''">
					<xsl:value-of select="$custom-meta_stage"/>
				</xsl:when>
				<xsl:when test="$value = 'WD'">20</xsl:when>
				<xsl:when test="$value = 'CD'">30</xsl:when>
				<xsl:when test="$value = 'DIS'">40</xsl:when>
				<xsl:when test="$value = 'FDIS'">50</xsl:when>
				<xsl:when test="$value = 'IS'">60</xsl:when>
				<xsl:when test="$value = 'PPUB'">60</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="custom-meta_substage" select="normalize-space(../../custom-meta-group/custom-meta[meta-name = 'substage']/meta-value)"/>
		<xsl:variable name="custom-meta_substage_abbreviation" select="normalize-space(../../custom-meta-group/custom-meta[meta-name = 'substage_abbreviation']/meta-value)"/>
		<xsl:variable name="substage">
			<xsl:choose>
				<xsl:when test="$custom-meta_substage != ''">
					<xsl:value-of select="$custom-meta_substage"/>
				</xsl:when>
				<xsl:when test="$value = 'WD' or $value = 'CD' or $value = 'DIS' or $value = 'FDIS'">00</xsl:when>
				<xsl:when test="$value = 'IS'">60</xsl:when>
				<xsl:when test="$value = 'PPUB'">60</xsl:when>
			</xsl:choose>
		</xsl:variable>
		
		<status>
		
			<xsl:variable name="stage_abbreviation">
				<xsl:choose>
					<xsl:when test="$custom-meta_stage_abbreviation != ''">
						<xsl:value-of select="$custom-meta_stage_abbreviation"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates mode="bibdata"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			
			<xsl:if test="$type_xml = 'presentation'">
				<stage language="en">
					<xsl:attribute name="abbreviation">
						<xsl:value-of select="$stage_abbreviation"/>
					</xsl:attribute>
					<xsl:choose>
						<xsl:when test="$stage = '20'">Working draft</xsl:when>
						<xsl:when test="$stage = '30'">Committee draft</xsl:when>
						<xsl:when test="$stage = '40'">Draft international standard</xsl:when>
						<xsl:when test="$stage = '50'">Final draft international standard</xsl:when>
						<xsl:when test="$stage = '60'">International standard</xsl:when>
					</xsl:choose>
				</stage>
			</xsl:if>
			
			<stage>
				<xsl:attribute name="abbreviation">
					<xsl:value-of select="$stage_abbreviation"/>
				</xsl:attribute>
				<xsl:value-of select="$stage"/>
			</stage>
			
			<substage>
				<xsl:attribute name="abbreviation">
					<xsl:choose>
						<xsl:when test="$custom-meta_substage_abbreviation != ''">
							<xsl:value-of select="$custom-meta_substage_abbreviation"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates mode="bibdata"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				<xsl:value-of select="$substage"/>
			</substage>
		</status>		
	</xsl:template>
	
	<xsl:template match="iso-meta/std-xref | nat-meta/std-xref | reg-meta/std-xref | std-meta/std-xref | std-doc-meta/std-xref" mode="bibdata">
		<xsl:choose>
			<xsl:when test="@type = 'isPublishedFormatOf'"></xsl:when> <!-- see <relation type="related"> -->
			<xsl:otherwise>
				<relation type="{@type}">
					<xsl:apply-templates mode="bibdata"/>
				</relation>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="front/reg-meta" mode="bibdata">
		<relation type="adopted-from">
			<xsl:call-template name="xxx-meta"/>
			<xsl:call-template name="processMetadata"/>
		</relation>
	</xsl:template>
	
	<xsl:template match="iso-meta/std-xref/std-ref | nat-meta/std-xref/std-ref | reg-meta/std-xref/std-ref | std-meta/std-xref/std-ref | std-doc-meta/std-xref/std-ref" mode="bibdata">
		<bibitem>
			<xsl:apply-templates mode="bibdata"/>
		</bibitem>
	</xsl:template>
	
	<xsl:template match="iso-meta/permissions | nat-meta/permissions | reg-meta/permissions | std-meta/permissions | std-doc-meta/permissions" mode="bibdata">
		<copyright>
			<xsl:apply-templates select="copyright-year" mode="bibdata"/>
			<xsl:apply-templates select="copyright-holder" mode="bibdata"/>			
		</copyright>
	</xsl:template>
		
	<xsl:template match="iso-meta/permissions/copyright-year | nat-meta/permissions/copyright-year | reg-meta/permissions/copyright-year | std-meta/permissions/copyright-year | std-doc-meta/permissions/copyright-year" mode="bibdata">
		<from>
			<xsl:apply-templates mode="bibdata"/>
		</from>
	</xsl:template>
	
	<xsl:template match="iso-meta/permissions/copyright-holder | nat-meta/permissions/copyright-holder | reg-meta/permissions/copyright-holder | std-meta/permissions/copyright-holder | std-doc-meta/permissions/copyright-holder" mode="bibdata">
		<owner>
				<organization>
					<xsl:choose>
						<xsl:when test="string-length(text()) != string-length(translate(text(),' ',''))">
							<name>
								<xsl:apply-templates mode="bibdata"/>
							</name>
						</xsl:when>
						<xsl:otherwise>
							<xsl:variable name="abbreviation">
								<xsl:apply-templates mode="bibdata"/>
							</xsl:variable>
							<xsl:call-template name="organization_name_by_abbreviation">
								<xsl:with-param name="abbreviation" select="$abbreviation"/>
							</xsl:call-template>
							<abbreviation>
								<xsl:value-of select="$abbreviation"/>
							</abbreviation>
						</xsl:otherwise>
					</xsl:choose>
				</organization>
			</owner>
	</xsl:template>
	

	<xsl:template match="iso-meta/std-ident/doc-type | nat-meta/std-ident/doc-type | reg-meta/std-ident/doc-type | std-meta/std-ident/doc-type | std-doc-meta/std-ident/doc-type" mode="bibdata">
		<xsl:variable name="value" select="java:toLowerCase(java:java.lang.String.new(.))"/>
		<xsl:variable name="originator" select=" normalize-space(ancestor::std-ident/originator)"/>
		<doctype>
			<xsl:choose>
				<xsl:when test="$organization = 'BSI' and (starts-with($originator, 'BS') or starts-with($originator, 'PAS') or starts-with($originator, 'PD'))">
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
					<xsl:value-of select="."/>
				 </xsl:otherwise>
			</xsl:choose>
		</doctype>
	</xsl:template>
	
	<xsl:template match="iso-meta/comm-ref | nat-meta/comm-ref | reg-meta/comm-ref | std-meta/comm-ref | std-doc-meta/comm-ref" mode="bibdata">
		<editorialgroup>
			<xsl:if test="$organization != 'BSI'">
				<xsl:variable name="comm-ref">
					<xsl:call-template name="split">
						<xsl:with-param name="pText" select="."/>
					</xsl:call-template>
				</xsl:variable>			
				
				<xsl:variable name="TC_SC_WG">
					<xsl:for-each select="xalan:nodeset($comm-ref)/*">
						<xsl:choose>
							<xsl:when test="starts-with(., 'TC ')">
								<technical-committee number="{normalize-space(substring-after(., ' '))}" type="TC"></technical-committee>
							</xsl:when>
							<xsl:when test="starts-with(., 'SC ')">
								<subcommittee number="{normalize-space(substring-after(., ' '))}" type="SC"></subcommittee>
							</xsl:when>
							<xsl:when test="starts-with(., 'WG ')">
								<workgroup number="{normalize-space(substring-after(., ' '))}" type="WG"></workgroup>
							</xsl:when>
						</xsl:choose>
					</xsl:for-each>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="xalan:nodeset($TC_SC_WG)/*">
						<xsl:copy-of select="$TC_SC_WG"/>
					</xsl:when>
					<xsl:otherwise>
						<technical-committee number="{.}"></technical-committee>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
			
			<xsl:apply-templates select="../secretariat" mode="bibdata"/>			
		</editorialgroup>
		
	</xsl:template>
	
	<xsl:template match="iso-meta/secretariat | nat-meta/secretariat | reg-meta/secretariat | std-meta/secretariat | std-doc-meta/secretariat" mode="bibdata">
		<secretariat>
			<xsl:apply-templates mode="bibdata"/>
		</secretariat>
	</xsl:template>
	
	<xsl:template match="iso-meta/ics | nat-meta/ics | reg-meta/ics | std-meta/ics | std-doc-meta/ics" mode="bibdata">
		<ics>
			<code>
				<xsl:apply-templates mode="bibdata"/>
			</code>
		</ics>
	</xsl:template>
	
	<xsl:template match="iso-meta/std-ident | nat-meta/std-ident | reg-meta/std-ident | std-meta/std-ident | std-doc-meta/std-ident" mode="bibdata">
		<xsl:if test="$organization != 'BSI'">
			<structuredidentifier>
				<project-number part="{part-number}">
					<xsl:value-of select="originator"/>
					<xsl:text> </xsl:text>
					<xsl:value-of select="doc-number"/>
				</project-number>
			</structuredidentifier>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="iso-meta/doc-ident | nat-meta/doc-ident | reg-meta/doc-ident | std-meta/doc-ident | std-meta/proj-id" mode="bibdata_project_number">
		<structuredidentifier>
			<project-number>
				<xsl:choose>
					<xsl:when test="self::proj-id"><xsl:value-of select="."/></xsl:when>
					<xsl:otherwise><xsl:value-of select="proj-id"/></xsl:otherwise>
				</xsl:choose>
			</project-number>
			<xsl:if test="../std-ident/part-number">
				<partnumber><xsl:value-of select="../std-ident/part-number"/></partnumber>
			</xsl:if>
		</structuredidentifier>		
	</xsl:template>
	
	<xsl:template match="custom-meta-group/custom-meta[meta-name = 'horizontal']" mode="bibdata">
		<horizontal><xsl:value-of select="meta-value"/></horizontal>
	</xsl:template>
	
	<xsl:template match="permissions/license" mode="bibdata">
		<legal-statement>
			<xsl:apply-templates/>
		</legal-statement>
	</xsl:template>
	
	<xsl:template match="self-uri" mode="bibdata">
		<uri>
			<xsl:if test="@content-type">
				<xsl:attribute name="type"><xsl:value-of select="@content-type"/></xsl:attribute>
			</xsl:if>
			<xsl:value-of select="."/>
		</uri>
	</xsl:template>
	
	<xsl:template match="@*" mode="bibdata">
		<xsl:value-of select="."/>
	</xsl:template>	
	<xsl:template match="text()" mode="bibdata">
		<xsl:value-of select="."/>
	</xsl:template>
	<xsl:template match="*" mode="bibdata">
		<xsl:apply-templates />
	</xsl:template>	
	<!-- ============= -->
	<!-- END front -> bib data -->
	<!-- ============= -->


	<xsl:template match="@*|node()">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>	
	
	<!-- <xsl:template match="processing-instruction()"/> -->
	<xsl:template match="processing-instruction('foreward')"/>
	
	<xsl:template match="front/notes" mode="preface">
		<clause type="front_notes" inline-header="false" obligation="informative">
			<xsl:apply-templates />
		</clause>
	</xsl:template>
	
	<xsl:template match="front/sec | body/sec[@sec-type = 'intro']" mode="preface">
		<xsl:variable name="sec_type" select="normalize-space(@sec-type)"/>
		<xsl:variable name="name">
			<xsl:choose>
				<xsl:when test="$sec_type = 'intro'">introduction</xsl:when>
				<!-- <xsl:when test="$sec_type = 'titlepage'">clause</xsl:when> -->
				<xsl:when test="$sec_type = 'foreword'">foreword</xsl:when>
				<xsl:when test="$sec_type = ''">clause</xsl:when>
				<xsl:otherwise>clause</xsl:otherwise>
					<!-- <xsl:value-of select="$sec_type"/>
				</xsl:otherwise> -->
			</xsl:choose>
		</xsl:variable>
		<xsl:element name="{$name}">
			<xsl:copy-of select="@id"/>
			<xsl:if test="ancestor::front and $sec_type != ''">
				<xsl:attribute name="type"><xsl:value-of select="$sec_type"/></xsl:attribute>
			</xsl:if>
			<xsl:apply-templates />
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="*[contains(local-name(), '-meta')]/meta-note">
		<clause type="{@content-type}">
			<xsl:apply-templates />
		</clause>
	</xsl:template>
	
	<xsl:template match="front//sec">
		<clause id="{@id}">
			<xsl:if test="normalize-space(@sec-type) != ''">
				<xsl:attribute name="type"><xsl:value-of select="@sec-type"/></xsl:attribute>
			</xsl:if>
			<xsl:if test="not(title)">
				<xsl:if test="label">
					<xsl:attribute name="inline-header">true</xsl:attribute>
					<xsl:apply-templates select="label" mode="label_name"/>
				</xsl:if>
			</xsl:if>
			<xsl:apply-templates />
		</clause>
	</xsl:template>
	
	<xsl:template match="body">
		<sections>
			<xsl:apply-templates />
		</sections>
	</xsl:template>
	
	
	<xsl:template match="body/sec[@sec-type = 'norm-refs']" priority="2"/> <!-- See Bibliography processing below -->
  
	<xsl:template match="body//sec">
		<xsl:choose>
			<xsl:when test="$nat_meta_only = 'true' and @sec-type = 'intro'"></xsl:when> <!-- introduction added in preface tag, if $nat_meta_only = 'true' -->
			<xsl:when test="title and not(label) and not(@sec-type) and not(ancestor::*[@sec-type]) and not(title = 'Index')">
				<p id="{@id}" type="floating-title">
					<xsl:if test="java:org.metanorma.utils.RegExHelper.matches($regexSectionTitle, normalize-space(title)) = 'true' or java:org.metanorma.utils.RegExHelper.matches($regexSectionLabel, normalize-space(label)) = 'true'">
						<!-- section -->
						<xsl:attribute name="type">section-title</xsl:attribute>
					</xsl:if>
					<xsl:call-template name="addTitleDepth">
						<xsl:with-param name="label" select="sec[1]/label"/>
					</xsl:call-template>
					<xsl:apply-templates select="title/node()"/>
				</p>
				<xsl:apply-templates select="node()[not(self::title)]"/>
			</xsl:when>
			<xsl:otherwise>
				<clause id="{@id}">
					<xsl:choose>
						<xsl:when test="@sec-type = 'scope'">
							<xsl:attribute name="type">scope</xsl:attribute>
						</xsl:when>
						<xsl:when test="@sec-type = 'intro'">
							<xsl:attribute name="type">intro</xsl:attribute>
						</xsl:when>
					</xsl:choose>
					<xsl:if test="not(title)">
						<xsl:if test="label">
							<xsl:attribute name="inline-header">true</xsl:attribute>
							<xsl:apply-templates select="label" mode="label_name"/>
						</xsl:if>
					</xsl:if>
					<xsl:apply-templates />
				</clause>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="addTitleDepth">
		<xsl:param name="label"/>
		<xsl:if test="$type_xml = 'presentation'">
			<xsl:variable name="calculated_level">
				<xsl:value-of select="string-length($label) - string-length(translate($label, '.', '')) + 1"/>
			</xsl:variable>
			<xsl:variable name="level_">
				<xsl:call-template name="getLevel">
					<xsl:with-param name="calculated_level" select="$calculated_level"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="level" select="normalize-space($level_)"/>
			<xsl:if test="$level != '0'">
				<xsl:attribute name="depth"><xsl:value-of select="$level"/></xsl:attribute>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	
	<!-- ======================== -->
	<!-- Terms, definitions -->
	<!-- ======================== -->
	<xsl:template match="body//sec[./term-sec]" priority="2">
		<terms id="{@id}">
			<xsl:apply-templates />
		</terms>
	</xsl:template>
	
	<xsl:template match="body//sec[./array[count(table/col) = 2]]" priority="2">
		<definitions id="{@id}">
			<xsl:apply-templates />
		</definitions>
	</xsl:template>
	
	<xsl:template match="term-sec">
		<xsl:apply-templates />
	</xsl:template>
	<xsl:template match="term-sec/text()[normalize-space() = '']"/> <!-- linearization -->
	
	<xsl:template match="tbx:termEntry">
		<term id="{@id}">
			<xsl:apply-templates select="../label" mode="term_sec_label"/>
			<xsl:apply-templates />
		</term>
	</xsl:template>
	<xsl:template match="tbx:termEntry/text()[normalize-space() = '']"/> <!-- linearization -->
	
	<xsl:template match="term-sec/label" mode="term_sec_label">
		<xsl:if test="$type_xml = 'presentation'">
			<name><xsl:apply-templates /></name>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="tbx:langSet">
		<xsl:apply-templates select="tbx:tig" mode="preferred"/>
		<xsl:apply-templates />
	</xsl:template>
	<xsl:template match="tbx:langSet/text()[normalize-space() = '']"/> <!-- linearization -->
	
	<xsl:template match="tbx:definition">
		<xsl:variable name="initial_text" select="node()[1][self::text()]"/>
		<xsl:variable name="domain" select="normalize-space(java:replaceAll(java:java.lang.String.new($initial_text), $regex_term_domain, '$2'))"/>
		<xsl:if test="$domain != ''">
			<domain><xsl:value-of select="$domain"/></domain>
		</xsl:if>
		
		<definition>
			<xsl:choose>
				<xsl:when test="$type_xml = 'presentation'">
					<p>
						<xsl:apply-templates />
					</p>
				</xsl:when>
				<xsl:otherwise>
					<verbal-definition>
						<p>
							<xsl:apply-templates />
						</p>
					</verbal-definition>
				</xsl:otherwise>
			</xsl:choose>
		</definition>
	</xsl:template>
	
	<!-- initial text in definition -->
	<xsl:template match="tbx:definition/node()[1][self::text()]">
		<xsl:variable name="initial_text" select="."/>
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new($initial_text), $regex_term_domain, '$4')"/>
	</xsl:template>
	
	<xsl:template match="tbx:subjectField">
		<domain><xsl:apply-templates/></domain>
	</xsl:template>
	
	<!-- =============== -->
	<!-- tbx:see  -->
	<!-- =============== -->
	<xsl:template match="tbx:see">
		<termnote>
			<p>
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
			</p>
		</termnote>
	</xsl:template>
	<xsl:template match="tbx:see/@target">
		<xref target="{.}"/>
	</xsl:template>
	<!-- =============== -->
	<!-- END: tbx:see  -->
	<!-- =============== -->
	
	
	<xsl:template match="tbx:entailedTerm">
		<xsl:variable name="target" select="substring-after(@target, 'term_')"/>
		<xsl:choose>
			<xsl:when test="contains(., concat('(', $target, ')'))"> <!-- example: concept entry (3.5) -->
				<em><xsl:value-of select="normalize-space(substring-before(., concat('(', $target, ')')))"/></em>
			</xsl:when>
			<xsl:when test="contains(., concat(' ', $target, ')'))"> <!-- example: vocational competence (see 3.26) -->
				<em><xsl:value-of select="normalize-space(substring-before(., '('))"/></em>
			</xsl:when>
			<xsl:when test="translate(., '01234567890.', '') = ''"></xsl:when><!-- if digits and dot only, example 3.13 -->
			<xsl:otherwise>
				<em><xsl:value-of select="."/></em>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text> (</xsl:text>
		<xref target="{@target}"><xsl:if test="contains(., concat('(', $target, ')')) or contains(., concat(' ', $target, ')'))"><strong><xsl:value-of select="$target"/></strong></xsl:if></xref>
		<xsl:text>)</xsl:text>
	</xsl:template>
	
	<xsl:template match="tbx:entailedTerm[@xtarget]">
		<!-- Example: {{<<bibliographic-anchor>>,term}} -->
		<!-- <concept>
				<refterm>term</refterm>
				<renderterm>term</renderterm>
				<eref bibitemid="bibliographic-anchor" />
			</concept> -->
		<concept>
      <refterm><xsl:apply-templates/></refterm>
      <renderterm><xsl:apply-templates/></renderterm>
      <eref bibitemid="{@xtarget}" />
		</concept>
	</xsl:template>
	
	<xsl:template match="tbx:note">
		<termnote>
			<xsl:if test="$type_xml = 'presentation'">
				<name>
					<xsl:text>NOTE</xsl:text>
					<xsl:if test="count(../tbx:note) &gt; 1"><xsl:text> </xsl:text><xsl:number /></xsl:if>
				</name>
			</xsl:if>
			<p>
				<xsl:apply-templates />
			</p>
		</termnote>
	</xsl:template>
	
	<xsl:template match="tbx:tig"/>
	<xsl:template match="tbx:tig" mode="preferred">
		<xsl:apply-templates />
	</xsl:template>
	<xsl:template match="tbx:tig/text()[normalize-space() = '']"/> <!-- linearization -->
	
	<xsl:template match="tbx:tig/tbx:term">
		<xsl:variable name="element_name">
			<xsl:choose>
				<xsl:when test="../tbx:normativeAuthorization/@value = 'preferredTerm'">preferred</xsl:when>
				<xsl:when test="../tbx:normativeAuthorization/@value = 'admittedTerm'">admitted</xsl:when>
				<xsl:when test="../tbx:normativeAuthorization/@value = 'deprecatedTerm'">deprecates</xsl:when>
				<xsl:when test="not(bold) and ancestor::sec[parent::body]//tbx:term[bold]">preferred</xsl:when>
				<xsl:when test="bold and ancestor::sec[parent::body]//tbx:term[not(bold)]">admitted</xsl:when>
				<xsl:otherwise>preferred</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$type_xml = 'semantic'">
				<xsl:element name="{$element_name}">
				
					<xsl:variable name="element_type_name">
						<xsl:choose>
							<xsl:when test="../tbx:termType/@value = 'symbol'">letter-symbol</xsl:when>
							<xsl:otherwise>expression</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
				
					<xsl:element name="{$element_type_name}">
						<xsl:apply-templates select="ancestor::tbx:langSet/@xml:lang"/>
						<xsl:apply-templates select="../tbx:termType[@value = 'abbreviation' or @value = 'fullForm']" mode="term"/>
						<name>
							<xsl:call-template name="createTermElement"/>
						</name>
						<xsl:apply-templates select="../tbx:termType[@value = 'acronym']" mode="term"/>
						<xsl:apply-templates select="../tbx:partOfSpeech" mode="term"/>
					</xsl:element>
					<!-- Example: <field-of-application>in dependability</field-of-application> -->
					<xsl:apply-templates select="../tbx:usageNote" mode="term"/>
					
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="{$element_name}">
					<xsl:call-template name="createTermElement">
						<xsl:with-param name="element_name" select="$element_name"/>
					</xsl:call-template>
				</xsl:element>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tbx:langSet/@xml:lang">
		<xsl:if test=". != $language"> <!-- if lang is different than document main language, for instance 'fr' for 'en' document -->
			<xsl:attribute name="language">
				<xsl:value-of select="."/>
			</xsl:attribute>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="tbx:term[count(node()) = 1]/bold" priority="2">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template name="createTermElement">
		<xsl:param name="element_name"/>
		<xsl:variable name="termType" select="normalize-space(../tbx:termType/@value)"/>
		<xsl:if test="$termType != ''">
			<!-- <xsl:attribute name="type">
				<xsl:choose>
					<xsl:when test="$termType = 'variant'">full</xsl:when>
					<xsl:otherwise><xsl:value-of select="$termType"/></xsl:otherwise>
				</xsl:choose>
			</xsl:attribute> -->
		</xsl:if>
		<xsl:choose>
			<xsl:when test="$type_xml = 'presentation' and $element_name = 'preferred'">
				<strong><xsl:apply-templates /></strong>
			</xsl:when>
			<xsl:otherwise><xsl:apply-templates /></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="tbx:normativeAuthorization"/>
	
	<xsl:template match="tbx:partOfSpeech"/>
	
	<xsl:template match="tbx:partOfSpeech" mode="term">
		<xsl:variable name="elementName">
			<xsl:choose>
				<xsl:when test="@value = 'noun'">isNoun</xsl:when>
				<xsl:when test="@value = 'verb'">isVerb</xsl:when>
				<xsl:when test="@value = 'adj'">isAdjective</xsl:when>
				<xsl:when test="@value = 'adv'">isAdverb</xsl:when>
				<xsl:otherwise>is<xsl:value-of select="@value"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<grammar>
			<xsl:element name="{$elementName}">true</xsl:element>
		</grammar>
	</xsl:template>
	
	<xsl:template match="tbx:termType"/>
	
	<xsl:template match="tbx:termType[@value = 'abbreviation' or @value = 'fullForm']" mode="term">
		<xsl:attribute name="type">
			<xsl:choose>
				<xsl:when test="@value = 'fullForm'">full</xsl:when>
				<xsl:otherwise><xsl:value-of select="@value"/></xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>
	
	<xsl:template match="tbx:termType[@value = 'acronym']" mode="term">
		<abbreviation-type><xsl:value-of select="@value"/></abbreviation-type>
	</xsl:template>
	
	<xsl:template match="tbx:usageNote"/>
	<xsl:template match="tbx:usageNote" mode="term">
		<field-of-application>
			<xsl:apply-templates/>
		</field-of-application>
	</xsl:template>
	
	<xsl:template match="term-display">
		<term>
			<xsl:copy-of select="@id"/>
			<xsl:if test="not(@id)">
				<xsl:attribute name="id">
					<xsl:variable name="id_tmp" select="java:replaceAll(java:java.lang.String.new(term),'[^a-zA-Z0-9 ]', '_')"/><!-- replace all non word char to underscore -->
					<xsl:text>term-</xsl:text><xsl:value-of select="translate($id_tmp, ' ', '-')"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
		</term>
	</xsl:template>
	
	<xsl:template match="term-display/term">
		<preferred>
			<xsl:choose>
				<xsl:when test="$type_xml = 'presentation'">
					<strong><xsl:apply-templates/></strong>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates/>
				</xsl:otherwise>
			</xsl:choose>
			
		</preferred>
	</xsl:template>
	
	<xsl:template match="term-display/def">
		<definition>
			<xsl:apply-templates/>
		</definition>
	</xsl:template>
	
	<!-- ======================== -->
	<!-- END Terms, definitions -->
	<!-- ======================== -->
	
	<xsl:template match="tbx:example">
		<termexample>
			<xsl:apply-templates />
		</termexample>
	</xsl:template>
	
	<xsl:template match="tbx:source">
	
		<xsl:variable name="model_term_source_">
			<xsl:call-template name="build_sts_model_term_source"/>
		</xsl:variable>
		<!-- <xsl:copy-of select="$model_term_source_"/> -->
		<xsl:variable name="model_term_source" select="xalan:nodeset($model_term_source_)"/>
	
		<termsource>
			<xsl:if test="$model_term_source/modified">
				<xsl:attribute name="status">modified</xsl:attribute>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="$model_term_source/adapted">
					<xsl:attribute name="status">adapted</xsl:attribute>
				</xsl:when>
				<!-- <xsl:when test="$model_term_source/modified_from">
					<xsl:attribute name="status">modified</xsl:attribute>
				</xsl:when> -->
				<xsl:when test="$model_term_source/quoted">
					<xsl:attribute name="status">quoted</xsl:attribute>
				</xsl:when>
			</xsl:choose>
			
			<!-- put reference -->
			<xsl:variable name="term_source_reference" select="$model_term_source/reference"/>
			<xsl:variable name="reference">
				<xsl:call-template name="getReference_std">
					<xsl:with-param name="std-id" select="normalize-space($term_source_reference)"/>
				</xsl:call-template>
			</xsl:variable>
			
			<xsl:text>[SOURCE: </xsl:text>
			
			<xsl:choose>
				<xsl:when test="$model_term_source/adapted">
					<xsl:text>Adapted from: </xsl:text>
				</xsl:when>
				<!-- <xsl:when test="$model_term_source/modified_from">
					<xsl:text>Modified from: </xsl:text>
				</xsl:when> -->
				<xsl:when test="$model_term_source/quoted">
					<xsl:text>Quoted from: </xsl:text>
				</xsl:when>
			</xsl:choose>
			
			<origin bibitemid="{$term_source_reference}" type="inline" citeas="{$model_term_source/referenceText[1]}">
				<!-- put locality (-ies) -->
				<xsl:if test="$model_term_source/*[self::locality or self::localityContinue][normalize-space() != '']">
					<localityStack>
						<xsl:for-each select="$model_term_source/*[self::locality][normalize-space() != '']">
							<locality>
								<xsl:attribute name="type">
									<xsl:value-of select="substring-before(., ' ')"/>
								</xsl:attribute>
								<referenceFrom>
									<xsl:value-of select="substring-after(., ' ')"/>
									<xsl:value-of select="following-sibling::*[1][self::localityContinue]"/>
								</referenceFrom>
							</locality>
						</xsl:for-each>
					</localityStack>
				</xsl:if>
				
				<!-- <xsl:if test="$type_xml = 'presentation'">
					<xsl:for-each select="$model_term_source/referenceText[normalize-space() != '']">
						<xsl:copy-of select="./node()"/>
						<xsl:if test="following-sibling::referenceText[normalize-space() != '']">
							<xsl:text>,</xsl:text>
						</xsl:if>
					</xsl:for-each>
				</xsl:if> -->
				
				<xsl:call-template name="insertLocalities">
					<xsl:with-param name="model" select="$model_term_source"/>
				</xsl:call-template>
				
			</origin>
			<!-- put modified text (or just indication, i.e. comma ',') -->
			<xsl:if test="$model_term_source/modified">
				<modification>
					<xsl:for-each select="$model_term_source/modified">
						<p>
							<xsl:if test="normalize-space() != ','"><xsl:value-of select="."/></xsl:if>
						</p>
					</xsl:for-each>
				</modification>
			</xsl:if>
			
			<xsl:text>]</xsl:text>
			
		</termsource>
	</xsl:template>
	
	<xsl:template match="non-normative-note">
		<xsl:variable name="name">
			<xsl:apply-templates select="label" mode="note_label" />
		</xsl:variable>
		
		<xsl:variable name="name_lc" select="normalize-space(java:toLowerCase(java:java.lang.String.new($name)))"/>
		<xsl:choose>
			<xsl:when test="$name_lc != '' and not(starts-with($name_lc, 'note'))">
				<admonition type="{$name_lc}">
					<xsl:copy-of select="@id"/>
					<xsl:apply-templates />
				</admonition>
			</xsl:when>
			<xsl:otherwise>
				<note>
					<xsl:if test="$type_xml = 'presentation'">
						<xsl:apply-templates select="label" mode="note_label" />
					</xsl:if>
					<xsl:apply-templates />
				</note>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	<xsl:template match="non-normative-note/label" mode="note_label">
		<name><xsl:apply-templates/></name>
	</xsl:template>
	
	<xsl:template match="front/sec//uri | body//uri">
		<link target="{.}"/>
	</xsl:template>
	
	<xsl:template match="ref-list//uri">
		<link target="{.}"/>
	</xsl:template>
	
	<!-- =============== -->
	<!-- Definitions list (dl) -->
	<!-- =============== -->
	<xsl:template match="array">
		<xsl:choose>
			<xsl:when test="count(table/col) + count(table/colgroup/col)  = 2 and $organization != 'BSI'">
				<dl>
					<xsl:copy-of select="@id"/>
					<xsl:if test="label = 'Key'">
						<xsl:attribute name="key">true</xsl:attribute>
					</xsl:if>
					<xsl:apply-templates mode="dl"/>
				</dl>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="@*|node()" mode="dl">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="dl"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="table" mode="dl">
		<xsl:apply-templates mode="dl"/>
	</xsl:template>
	
	<xsl:template match="col" mode="dl"/>
	<xsl:template match="tbody" mode="dl">
		<xsl:apply-templates mode="dl"/>
	</xsl:template>
	
	<xsl:template match="tr" mode="dl">
		<dt>
			<xsl:apply-templates select="td[1]" mode="dl"/>
		</dt>
		<dd>
			<p>
				<xsl:apply-templates select="td[2]" mode="dl"/>
			</p>
		</dd>
	</xsl:template>
	
	<xsl:template match="td" mode="dl">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="label | colgroup" mode="dl"/>
	
	<xsl:template match="def-list">
		<dl>
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates />
		</dl>
	</xsl:template>
	
	<xsl:template match="def-list/def-item">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="def-item/term">
		<dt>
			<xsl:copy-of select="parent::*/@id"/>
			<xsl:apply-templates />
		</dt>
	</xsl:template>
	
	<xsl:template match="def-item/def">
		<dd>
			<xsl:apply-templates />
		</dd>
	</xsl:template>
	<!-- =============== -->
	<!-- End Definitions list (dl) -->
	<!-- =============== -->
	
	
	<!-- ============= -->
	<!-- Table processing -->
	<!-- ============= -->
	<xsl:template match="table">
		<table>
			<xsl:copy-of select="@*"/>
			<xsl:if test="not(@id)">
				<xsl:attribute name="id">
					<xsl:choose>
						<xsl:when test="parent::table-wrap/@id"><xsl:value-of select="parent::table-wrap/@id"/></xsl:when>
						<xsl:when test="parent::array/@id"><xsl:value-of select="parent::array/@id"/></xsl:when>
					</xsl:choose>
				</xsl:attribute>
			</xsl:if>
			
			<xsl:if test="parent::table-wrap and preceding-sibling::table"> <!-- if there are a few table inside table-wrap -->
				<xsl:variable name="id" select="parent::table-wrap/@id"/>
				<xsl:variable name="counter" select="count(preceding-sibling::table) + 1"/>
				<xsl:attribute name="id">
					<xsl:value-of select="concat($id, '_', $counter)"/>
				</xsl:attribute>
				
			</xsl:if>
			
			<xsl:apply-templates select="@width" mode="table_header"/>
			<xsl:apply-templates select="parent::table-wrap/caption/title"/>
			<xsl:apply-templates/>
			<xsl:apply-templates select="parent::table-wrap/table-wrap-foot" mode="table"/>
		</table>
	</xsl:template>
	
	<xsl:template match="table/@width" mode="table_header">
		<xsl:attribute name="width">
			<xsl:value-of select="."/><xsl:if test="not(contains(., '%')) and not(contains(., 'px'))">px</xsl:if>
		</xsl:attribute>
	</xsl:template>
	
	<xsl:template match="table-wrap-foot"/>
	<xsl:template match="table-wrap-foot" mode="table">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="table-wrap">
	
		<xsl:if test="@content-type = 'norm-refs'">
			<p><xsl:processing-instruction name="content-type">norm-refs</xsl:processing-instruction></p>
		</xsl:if>
	
		<xsl:apply-templates select="@orientation"/>
		<!-- <xsl:apply-templates select="@*" /> -->
		<xsl:apply-templates/>
		<xsl:apply-templates select="@orientation" mode="after_table"/>
	</xsl:template>
	
	<xsl:template match="table-wrap/@orientation">
		<pagebreak orientation="{.}"/>
	</xsl:template>
	
	<xsl:template match="table-wrap/@orientation" mode="after_table">
		<pagebreak orientation="portrait"/>
	</xsl:template>
	
	<xsl:template match="table-wrap/caption"/>	
	
	<xsl:template match="table-wrap/caption/title">
		<name>
			<xsl:apply-templates select="ancestor::table-wrap[1]/label" mode="table_label"/>
			<xsl:apply-templates/>
		</name>
	</xsl:template>
	
	<xsl:template match="table-wrap/label" mode="table_label">
		<xsl:if test="$type_xml = 'presentation'">
			<!-- Table 1 - -->
			<xsl:apply-templates/><xsl:text> &#8212; </xsl:text>
		</xsl:if>
	</xsl:template>
	
	<!-- table/col processing -->
	<xsl:template match="col[not(parent::colgroup)][1]" priority="2">
		<colgroup>
			<xsl:element name="{local-name()}">
				<xsl:copy-of select="@*"/>
				<xsl:apply-templates/>
			</xsl:element>
			<xsl:for-each select="following-sibling::col">
				<xsl:element name="{local-name()}">
					<xsl:copy-of select="@*"/>
					<xsl:apply-templates/>
				</xsl:element>
			</xsl:for-each>
		</colgroup>
	</xsl:template>
	<xsl:template match="col[not(parent::colgroup)][position() &gt; 1]" priority="2"/>

	<!-- table/colgroup/col processing -->
	<xsl:template match="col | tbody | thead | th| td | tr | colgroup">
		<xsl:element name="{local-name()}">
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<!-- ============= -->
	<!-- End Table processing -->
	<!-- ============= -->
	
	
	<!-- special case: p with styled-content inside -->
	<xsl:template match="p[count(node()[normalize-space() != '']) = 1 and styled-content[@style='text-alignment: center']]">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="p">
		<xsl:variable name="operator">
			<xsl:call-template name="getInsDel"/>
		</xsl:variable>
		<xsl:element name="{local-name()}">
			<xsl:apply-templates select="@*"/>
			
			<xsl:choose>
				<xsl:when test="$operator != ''">
					<xsl:element name="{$operator}">
						<xsl:apply-templates />
					</xsl:element>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="styled-content[@style='text-alignment: center']">
		<p align="center">
			<xsl:apply-templates />
		</p>
	</xsl:template>
	
	<!-- special case -->
	<xsl:template match="styled-content[@style='font-weight: italic; font-family: Times New Roman']">
		<stem type="MathML">
			<math xmlns="http://www.w3.org/1998/Math/MathML">
				<mi>
					<xsl:apply-templates />
				</mi>
			</math>
		</stem>
	</xsl:template>
	
	<xsl:template match="p/@specific-use">
		<xsl:if test=". = 'indent'">
			<xsl:attribute name="align"><xsl:value-of select="."/></xsl:attribute>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="p/@style-type">
		<xsl:for-each select="ancestor::p[1]">
			<xsl:variable name="align">
				<xsl:call-template name="getAlignment_style-type"/>
			</xsl:variable>
			<xsl:if test="$align != ''">
				<xsl:attribute name="align"><xsl:value-of select="$align"/></xsl:attribute>
			</xsl:if>
			
			<xsl:variable name="valign">
				<xsl:call-template name="getAlignment_style-type">
					<xsl:with-param name="prefix">valign-</xsl:with-param>
				</xsl:call-template>
			</xsl:variable>
			<xsl:if test="$valign != ''">
				<xsl:attribute name="valign"><xsl:value-of select="$valign"/></xsl:attribute>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="table-wrap-foot/p[@content-type = 'Dimension' or @content-type = 'dimension']">
		<note type="units">
			<p>
				<xsl:apply-templates/>
			</p>
		</note>
	 </xsl:template>
	
	<xsl:template match="title">
		<xsl:element name="{local-name()}">
			<xsl:apply-templates select="@*"/>
			<xsl:call-template name="addTitleDepth">
				<xsl:with-param name="label" select="parent::sec/label"/>
			</xsl:call-template>
			<xsl:apply-templates select="parent::sec/label" mode="label"/>
			<xsl:apply-templates />
		</xsl:element>
	</xsl:template>
	
	<xsl:template name="getLevel">
		<xsl:param name="addon">0</xsl:param>
		<xsl:param name="calculated_level">0</xsl:param>
		
		<xsl:variable name="level_total" select="count(ancestor::*)"/>
		
		<xsl:variable name="level_standard" select="count(ancestor::standard/ancestor::*)"/>
		
		<xsl:variable name="label" select="normalize-space(preceding-sibling::*[1][self::label])"/>
		
		<xsl:variable name="level">
			<xsl:choose>
				<xsl:when test="$calculated_level != 0">
					<xsl:value-of select="$calculated_level"/>
				</xsl:when>
				<xsl:when test="ancestor::app-group">
					<xsl:value-of select="$level_total - $level_standard - 2"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$level_total - $level_standard - 1"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:value-of select="$level"/>
	</xsl:template>
	
	<xsl:template match="label" mode="label">
		<xsl:if test="$type_xml = 'presentation'">
			<xsl:apply-templates/><tab/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="label" mode="label_name">
		<title><xsl:apply-templates/></title>
	</xsl:template>
	
	<xsl:template match="ext-link">
		<link target="{@xlink:href}">			
			<xsl:apply-templates />
		</link>
	</xsl:template>
	
	<xsl:template match="supplementary-material">
		<link target="file://{@xlink:href}">			
			<xsl:apply-templates />
		</link>
	</xsl:template>
	<xsl:template match="supplementary-material/p">
		<xsl:apply-templates />
	</xsl:template>
	
	<!-- special case -->
	<xsl:template match="break[preceding-sibling::node()[1][self::styled-content[@style='text-alignment: center']]] | 
						break[following-sibling::node()[1][self::styled-content[@style='text-alignment: center']]]"/>
	
	<xsl:template match="break">
		<br/>
	</xsl:template>
	
	<xsl:template match="bold">
		<strong>
			<xsl:apply-templates />
		</strong>
	</xsl:template>
	
	<xsl:template match="italic">
		<em>
			<xsl:apply-templates />
		</em>
	</xsl:template>
	
	<xsl:template match="underline">
		<underline>
			<xsl:apply-templates />
		</underline>
	</xsl:template>
	
	<xsl:template match="sub">
		<sub>
			<xsl:apply-templates />
		</sub>
	</xsl:template>
	
	<xsl:template match="sup">
		<sup>
			<xsl:apply-templates />
		</sup>
	</xsl:template>
	
	<xsl:template match="monospace | styled-content[@style = 'font-family:Courier,monospace'][not(ancestor::preformat)]">
		<tt>
			<xsl:apply-templates />
		</tt>
	</xsl:template>
	
	<xsl:template match="styled-content[@style = 'font-family:Courier,monospace'][ancestor::preformat]">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="sc">
		<smallcap>
			<xsl:apply-templates />
		</smallcap>
	</xsl:template>
	
	<!-- ===================== -->
	<!-- std processing        -->
	<!-- ===================== -->
	
	<!-- std in Bibliography section -->
	<xsl:template match="std[parent::ref and ancestor::ref-list]" priority="2">
		<xsl:if test="@std-id">
			<docidentifier type="URN"><xsl:value-of select="@std-id"/></docidentifier>
		</xsl:if>
		<eref type="inline" citeas="{std-ref}">
			<xsl:if test="@std-id">
				<xsl:attribute name="bibitemid">
					<xsl:variable name="std-id_normalized" select="translate(@std-id, ' &#xA0;:', '___')"/>
					<xsl:variable name="first_char" select="substring($std-id_normalized,1,1)"/>
					<xsl:if test="translate($first_char, '0123456789', '') = ''">_</xsl:if>
					<xsl:value-of select="$std-id_normalized"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates />
		</eref>
	</xsl:template>
	
	<!-- std in body -->
	<xsl:template match="std" name="std">
		
		<xsl:variable name="model_std_">
			<xsl:call-template name="build_sts_model_std"/>
		</xsl:variable>
		<xsl:variable name="model_std" select="xalan:nodeset($model_std_)"/>
		<!-- <std_model><xsl:copy-of select="$model_std_"/></std_model> -->
		
		<!-- put reference -->
		<eref type="inline" bibitemid="{$model_std/reference}" citeas="{$model_std/referenceText[normalize-space() != ''][1]}">
			<!-- put locality (-ies) -->
			<xsl:if test="$model_std/*[self::locality][normalize-space() != ''] and not(parent::ref and ancestor::ref-list)">
				
				<xsl:for-each select="$model_std/*[self::locality][normalize-space() != '']">
					<localityStack>
						<xsl:variable name="connective_preceding" select="preceding-sibling::localityConj[normalize-space() != ''][1]"/>
						<xsl:variable name="connective_following" select="following-sibling::localityConj[normalize-space() != ''][1]"/>
						<xsl:if test="$connective_following != '' or $connective_preceding != ''">
							<xsl:attribute name="connective">
								<xsl:choose>
									<xsl:when test="$connective_preceding = 'from'"><xsl:value-of select="$connective_preceding"/></xsl:when>
									<xsl:when test="$connective_following != ''"><xsl:value-of select="$connective_following"/></xsl:when>
									<xsl:otherwise><xsl:value-of select="$connective_preceding"/></xsl:otherwise>
								</xsl:choose>
							</xsl:attribute>
						</xsl:if>
						<locality>
							<xsl:attribute name="type">
								<!-- <xsl:value-of select="substring-before(., '=')"/> -->
								<xsl:value-of select="."/>
							</xsl:attribute>
							<referenceFrom>
								<!-- <xsl:value-of select="substring-after(., '=')"/> -->
								<xsl:value-of select="following-sibling::localityValue[normalize-space() != ''][1]"/>
							</referenceFrom>
						</locality>
					</localityStack>
				</xsl:for-each>
			</xsl:if>
			
			<xsl:call-template name="insertLocalities">
				<xsl:with-param name="model" select="$model_std"/>
			</xsl:call-template>
			
			<xsl:apply-templates select=".//processing-instruction()"/>
		</eref>
	</xsl:template>
	
	<xsl:template name="insertLocalities">
		<xsl:param name="model"/>
		<xsl:if test="$type_xml = 'presentation'">
			<!-- put reference text -->
			<xsl:for-each select="$model/referenceText[normalize-space() != '']">
				<xsl:value-of select="."/>
				<xsl:if test="following-sibling::referenceText[normalize-space() != '']">
					<xsl:text>,</xsl:text>
				</xsl:if>
			</xsl:for-each>
			<xsl:for-each select="$model/*[self::locality or self::localityValue or self::localityConj][normalize-space() != '']">
				<xsl:if test="position() = 1"><xsl:text>,</xsl:text></xsl:if>
				<xsl:text> </xsl:text>
				<xsl:choose>
					<xsl:when test="self::localityValue"><strong><xsl:value-of select="."/></strong></xsl:when>
					<xsl:when test="self::locality">
						<xsl:if test="not(contains(following-sibling::*[self::localityValue][1], '.'))"> <!-- 1 A etc., not 3.2 or A.5 -->
							<xsl:choose>
							<xsl:when test=". = 'clause'">Clause </xsl:when>
							<xsl:when test=". = 'annex'">Annex </xsl:when>
							<xsl:when test=". = 'section'">Section </xsl:when>
							<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
						</xsl:choose>
						</xsl:if>
					</xsl:when>
					<xsl:otherwise><xsl:if test=". != 'from'"><xsl:value-of select="."/></xsl:if></xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="std/std-ref">
		<xsl:apply-templates />
	</xsl:template>
	
	<!-- move italic, bold formatting outside std -->
	<xsl:template match="std[italic]" priority="2">
		<em>
			<!-- <eref type="inline" citeas="{italic/std-ref}">
				<xsl:apply-templates />
			</eref> -->
			<xsl:call-template name="std"/>
		</em>
	</xsl:template>
	<xsl:template match="std[bold]" priority="2">
		<strong>
			<!-- <eref type="inline" citeas="{bold/std-ref}">
				<xsl:apply-templates />
			</eref> -->
			<xsl:call-template name="std"/>
		</strong>
	</xsl:template>
	<xsl:template match="std/italic | std/bold" priority="2">
		<xsl:apply-templates />
	</xsl:template>
	<xsl:template match="std/italic/std-ref | std/bold/std-ref"> <!--  priority="2"/> -->
		<xsl:apply-templates />
	</xsl:template>
	<!-- ===================== -->
	<!-- END std processing -->
	<!-- ===================== -->
	
	<xsl:template match="list">
		<xsl:choose>
			<xsl:when test="@list-type = 'bullet' or @list-type = 'simple'">
				<xsl:if test="@list-type = 'simple'">
					<p><xsl:processing-instruction name="list-type">simple</xsl:processing-instruction></p>
				</xsl:if>
				<ul>
					<xsl:apply-templates select="@*"/>
					<xsl:apply-templates />
				</ul>
			</xsl:when>
			<xsl:otherwise>
				<ol>
					<xsl:apply-templates select="@*"/>
					<xsl:apply-templates />
				</ol>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="list/@list-type">
		<xsl:variable name="first_label" select="translate(..//label[1], ').', '')"/>
			
		<xsl:variable name="type">
			<xsl:choose>
				<xsl:when test=". = 'alpha-lower'">alphabet</xsl:when>
				<xsl:when test=". = 'alpha-upper'">alphabet_upper</xsl:when>
				<xsl:when test=". = 'roman-lower'">roman</xsl:when>
				<xsl:when test=". = 'roman-upper'">roman_upper</xsl:when>
				<xsl:when test=". = 'arabic'">arabic</xsl:when>
				<xsl:when test="$first_label != '' and translate($first_label, '1234567890', '') = ''">arabic</xsl:when>
				<xsl:when test="$first_label != '' and translate($first_label, 'ixvcm', '') = ''">roman</xsl:when>
				<xsl:when test="$first_label != '' and translate($first_label, 'IXVCM', '') = ''">roman_upper</xsl:when>
				<xsl:when test="$first_label != '' and translate($first_label, 'abcdefghijklmnopqrstuvwxyz', '') = ''">alphabet</xsl:when>
				<xsl:when test="$first_label != '' and translate($first_label, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', '') = ''">alphabet_upper</xsl:when>
				<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:attribute name="type">
			<xsl:value-of select="$type"/>
		</xsl:attribute>
		
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
		
			<!-- <xsl:choose>
				<xsl:when test="$type = 'arabic' and $first_label != '1'"><xsl:value-of select="$first_label"/></xsl:when>
				<xsl:when test="$type = 'roman' and $first_label != 'i'"><xsl:value-of select="$first_label"/></xsl:when>
				<xsl:when test="$type = 'roman_upper' and $first_label != 'I'"><xsl:value-of select="$first_label"/></xsl:when>
				<xsl:when test="$type = 'alphabet' and $first_label != 'a'"><xsl:value-of select="$first_label"/></xsl:when>
				<xsl:when test="$type = 'alphabet_upper' and $first_label != 'A'"><xsl:value-of select="$first_label"/></xsl:when>
			</xsl:choose> -->
		</xsl:variable>
		<xsl:if test="normalize-space($start) != ''">
			<xsl:attribute name="start">
				<xsl:value-of select="$start"/>
			</xsl:attribute>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="list-item">
		<li>
			<xsl:apply-templates />
		</li>
	</xsl:template>
	
	<xsl:template match="list-item/text()[normalize-space() = '']"/> <!-- linearization -->
	
	<xsl:variable name="regexListItemLabel" select="'^((([0-9]|[a-z]|[A-Z])+(\)|\.))(\s|\h)+)(.*)'"/>
	<xsl:template match="list-item[not(label)]//node()[self::text()][normalize-space() != ''][1]" priority="2">
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),$regexListItemLabel, '$6')"/> <!-- get last group from regexListItemLabel, i.e. list item text without label-->
	</xsl:template>
	
	<xsl:template match="label"/>
	
	<xsl:template match="xref">
		<xsl:choose>
			<xsl:when test="@ref-type = 'fn' and following-sibling::*[self::fn][@id = current()/@rid]"/> <!-- if next element is fn, then no need to do here -->
			<xsl:when test="@ref-type = 'fn'">
				<fn>
					<xsl:attribute name="reference">
							<xsl:value-of select="normalize-space(translate(., ')',''))"/>
						</xsl:attribute>
						<xsl:choose>
							<xsl:when test="ancestor::table-wrap">
								<xsl:apply-templates select="ancestor::table-wrap//fn[@id = current()/@rid]/node()" /> <!-- //fn-group -->
							</xsl:when>
							<xsl:otherwise>
								<xsl:apply-templates select="//fn-group/fn[@id = current()/@rid]/node()" />
							</xsl:otherwise>
						</xsl:choose>
						
				</fn>
			</xsl:when>
			<xsl:when test="@ref-type = 'table-fn'">
				<fn>
					<xsl:attribute name="reference">
							<xsl:value-of select="normalize-space(translate(., ')',''))"/>
						</xsl:attribute>
						<xsl:apply-templates select="ancestor::table-wrap//fn[@id = current()/@rid]/node()" />
				</fn>
			</xsl:when>
			
			<xsl:otherwise>
				<xref target="{@rid}">
					<xsl:if test="$type_xml = 'presentation'">
						<xsl:apply-templates />
					</xsl:if>
				</xref>		
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="sup[xref[@ref-type='fn']]">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="back/fn-group"/>
	
	<xsl:template match="table-wrap-foot/fn"/>
	
	<xsl:template match="fn" name="fn">
		<fn>
			<xsl:attribute name="reference">
				<xsl:value-of select="preceding-sibling::xref[@rid = current()/@id]//text()"/>
			</xsl:attribute>
			<xsl:apply-templates />
		</fn>
	</xsl:template>
	
	<xsl:template match="non-normative-example">
		<example>
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates />
		</example>
	</xsl:template>
	
	<xsl:template match="back">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="app-group">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="app">
		<annex id="{@id}">			
			<xsl:attribute name="obligation">
				<xsl:value-of select="translate(annex-type, '()','')"/>
			</xsl:attribute>
			<xsl:apply-templates />
		</annex>
	</xsl:template>
	
	<xsl:template match="annex-type"/>
	
	<xsl:template match="app//sec">
		<clause id="{@id}">
			<xsl:apply-templates />
		</clause>
	</xsl:template>
	
	<xsl:template match="back/ref-list" priority="2"/> <!-- See Bibliography processing below -->
		
	
	<xsl:template match="ref">
		<xsl:variable name="unique"><!-- skip repeating references -->
			<xsl:choose>
				<xsl:when test="@id and preceding-sibling::ref[@id = current()/@id]">false</xsl:when>
				<xsl:when test="std/@std-id and preceding-sibling::ref[std/@std-id = current()/std/@std-id]">false</xsl:when>
				<xsl:when test="std/std-ref and preceding-sibling::ref[std/std-ref = current()/std/std-ref]">
					<xsl:choose>
						<xsl:when test="std/title and preceding-sibling::ref[std/title = current()/std/title]">false</xsl:when>
						<xsl:when test="not(std/title)">false</xsl:when>
					</xsl:choose>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<!-- unique='<xsl:value-of select="$unique"/>' -->
		<!-- comment repeated references -->
		<xsl:if test="normalize-space($unique) = 'false'"><xsl:text disable-output-escaping="yes">&lt;!--STS: </xsl:text></xsl:if>
		
		<bibitem>
			<xsl:copy-of select="@id"/>
			<xsl:if test="@content-type">
				<xsl:attribute name="type"><xsl:value-of select="@content-type"/></xsl:attribute>
			</xsl:if>
			<xsl:apply-templates />
		</bibitem>
		
		<xsl:if test="normalize-space($unique) = 'false'"><xsl:text disable-output-escaping="yes">--&gt;</xsl:text></xsl:if>
		
		<xsl:if test="normalize-space($unique) = 'false'">
			<xsl:message>WARNING: Repeated reference - <xsl:copy-of select="."/></xsl:message>
		</xsl:if>
		
	</xsl:template>
	
	<xsl:template match="ref-list/ref/label">
		<docidentifier type="metanorma"><xsl:apply-templates /></docidentifier>
	</xsl:template>
	
	<xsl:template match="mixed-citation">
		<title>
			<xsl:apply-templates />
		</title>
	</xsl:template>
	
	<!-- ============================= -->
	<!-- Math formula, equation, etc. -->
	<!-- ============================= -->
	<xsl:template match="disp-formula">
		<formula id="{mml:math/@id}">
			<stem type="MathML">
				<xsl:apply-templates />
			</stem>
		</formula>
	</xsl:template>
	
	<xsl:template match="inline-formula">
		<stem type="MathML">
			<xsl:apply-templates />
		</stem>
	</xsl:template>
	
	<xsl:template match="mml:math">
		<math xmlns="http://www.w3.org/1998/Math/MathML">
			<xsl:apply-templates select="@*"/>
			<xsl:apply-templates />
		</math>
	</xsl:template>
	
	<xsl:template match="mml:math/@id"/>
	
	<xsl:template match="mml:*">
		<xsl:element name="{local-name()}" namespace="http://www.w3.org/1998/Math/MathML">
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates />
		</xsl:element>
	</xsl:template>
	<!-- ============================= -->
	<!-- END Math formula, equation, etc. -->
	<!-- ============================= -->
	
	<xsl:template match="sec[@sec-type = 'index'] | back/sec[@id = 'ind' or @id = 'sec_ind']" priority="2"/>
	<xsl:template match="sec[@sec-type = 'index'] | back/sec[@id = 'ind' or @id = 'sec_ind']" mode="index">
		<indexsect id="{@id}">
			<xsl:apply-templates />
		</indexsect>
	</xsl:template>
	
	<!-- ========================== -->
	<!-- Figures, images, graphic -->
	<!-- ========================== -->
	<xsl:template match="fig">
		<figure id="{@id}">
			<!-- <xsl:apply-templates /> -->
			<xsl:apply-templates select="*[not(self::array or self::non-normative-note)]"/>
		</figure>
		<xsl:apply-templates select="*[self::array or self::non-normative-note]"/>
	</xsl:template>
	
	<xsl:template match="fig/caption">
		<name>
			<xsl:apply-templates select="../label" mode="fig_label"/>
			<xsl:apply-templates />
		</name>
	</xsl:template>
	
	<xsl:template match="fig/label" mode="fig_label">
		<xsl:apply-templates/><xsl:text> &#8212; </xsl:text>
	</xsl:template>
	
	<xsl:template match="fig/caption/title">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="graphic[caption]">
		<figure>
			<xsl:apply-templates />
			<xsl:call-template name="graphic"/>
		</figure>
	</xsl:template>
	
	<xsl:template match="graphic/label">
		<xsl:if test="not(../caption/title)">
			<name><xsl:apply-templates /></name>
		</xsl:if>
	</xsl:template>
	<xsl:template match="graphic/caption">
		<name>
			<xsl:if test="../label"><xsl:value-of select="../label"/>&#160; </xsl:if>
			<xsl:apply-templates />
		</name>
	</xsl:template>
	
	<xsl:template match="graphic/caption/title">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="graphic[preceding-sibling::*[1][self::graphic] or following-sibling::*[1][self::graphic] and parent::fig]">
		<figure>
			<xsl:if test="$type_xml = 'presentation'">
				<name><xsl:number format="a)"/></name>
			</xsl:if>
			<xsl:call-template name="graphic"/>
		</figure>
	</xsl:template>
	
	<xsl:template match="graphic | inline-graphic" name="graphic">
		<xsl:param name="copymode">false</xsl:param>
		
		<xsl:variable name="graphic_">
			<xsl:call-template name="build_sts_model_graphic">
				<xsl:with-param name="copymode" select="$copymode" />
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="graphic" select="xalan:nodeset($graphic_)"/>
		
		<image height="auto" width="auto" src="{$graphic/*[self::graphic or self::inline-graphic]/@filename}">
			<xsl:if test="$graphic/*[self::graphic or self::inline-graphic]/alt-text">
				<xsl:attribute name="alt"><xsl:value-of select="$graphic/*[self::graphic or self::inline-graphic]/alt-text"/></xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select="*[not(local-name() = 'caption') and not(local-name() = 'label')  and not(local-name() = 'alt-text')]">
				<xsl:with-param name="copymode" select="$copymode"/>
			</xsl:apply-templates>
		</image>
	</xsl:template>
	
	<xsl:template match="fig-group">
		<figure id="{@id}">
			<xsl:apply-templates />
		</figure>
	</xsl:template>
	<!-- ========================== -->
	<!-- END Figures, images, graphic -->
	<!-- ========================== -->
	
	
	<xsl:template match="disp-quote">
		<quote>
			<xsl:apply-templates />
		</quote>
	</xsl:template>
	
	<xsl:template match="disp-quote/related-object">
		<source>
			<xsl:apply-templates />
		</source>
	</xsl:template>
	
	<xsl:template match="code">
		<sourcecode lang="{@language}">
			<xsl:apply-templates />
		</sourcecode>
	</xsl:template>
	
	<xsl:template match="element-citation">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="named-content">
		<xsl:variable name="target">
			<xsl:call-template name="get_named_content_target"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$type_xml = 'semantic' and (@content-type = 'term' and (local-name(//*[@id = $target]) = 'term-sec' or local-name(//*[@id = $target]) = 'termEntry'))">
				<xsl:variable name="term_real" select="//*[@id = $target]//tbx:term[1]"/>
				<concept>
					<refterm><xsl:value-of select="$term_real"/></refterm>
					<renderterm><xsl:value-of select="."/></renderterm>
					<xref target="{$target}"/>
				</concept>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="normalize-space($target) != ''">
						<xref>
							<xsl:attribute name="target">
								<xsl:value-of select="$target"/>
							</xsl:attribute>
							<xsl:copy-of select="@content-type"/>
							<xsl:apply-templates />
						</xref>
					</xsl:when>
					<xsl:otherwise>
						<span class="{@content-type}"><xsl:apply-templates /></span>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- Bibliography processing -->
	<xsl:template match="body/sec[@sec-type = 'norm-refs']" mode="bibliography">
		<references id="{@id}" normative="true">
			<xsl:apply-templates />
		</references>
	</xsl:template>
	
	<xsl:template match="body/sec[@sec-type = 'norm-refs']/ref-list">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="back/ref-list[ref-list]" priority="2" mode="bibliography">
		<clause>
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates />
		</clause>
	</xsl:template>
	
	<xsl:template match="back/ref-list" mode="bibliography">
		<references normative="false">
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates />
		</references>
	</xsl:template>
	
	<xsl:template match="back/ref-list/ref-list">
		<references normative="false">
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates />
		</references>
	</xsl:template>
	
	<!-- END Bibliography processing -->
	
	<xsl:template match="processing-instruction('doi')">
		<xsl:copy-of select="."/>
	</xsl:template>
	
	<xsl:template match="preformat">
		<sourcecode>
			<xsl:apply-templates />
		</sourcecode>
	</xsl:template>
	
	<!-- copy element in comment -->
	<xsl:template match="styled-content">
		<!-- copy opening tag with attributes -->
		<xsl:text disable-output-escaping="yes">&lt;!--STS: &lt;</xsl:text><xsl:value-of select="name()"/>
		<xsl:for-each select="@*">
			<xsl:if test="position() = 1"><xsl:text> </xsl:text></xsl:if>
			<xsl:value-of select="local-name()"/>="<xsl:value-of select="."/><xsl:text>"</xsl:text>
		</xsl:for-each>
		
		<xsl:choose>
			<xsl:when test="node()">
				<xsl:text disable-output-escaping="yes">&gt;--&gt;</xsl:text>
				<xsl:text disable-output-escaping="yes"></xsl:text>
				
				<xsl:apply-templates />
				
				<!-- copy closing tag -->
				<xsl:text disable-output-escaping="yes">&lt;!--STS: &lt;/</xsl:text><xsl:value-of select="name()"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text disable-output-escaping="yes">/</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text disable-output-escaping="yes">&gt;--&gt;</xsl:text>
	</xsl:template>
	
	
	<xsl:template match="processing-instruction()[contains(., 'Page_Break')] | processing-instruction()[contains(., 'Page-Break')]">
		<pagebreak />
	</xsl:template>
	
	
	<!-- =========================== -->
	<!-- sub-part processing         -->
	<!-- =========================== -->
	
	<xsl:template match="sub-part">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="body[sub-part]">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="body/sub-part[position() &gt; 1]" priority="2"/> <!-- ignore sub-parts for first document processing -->
	<xsl:template match="sub-part">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="sub-part/title[normalize-space() = '']"/>
	
	<xsl:template match="body/graphic" priority="2"/>
	
	<xsl:template match="sub-part//sec[label = 'Foreword']">
		<foreword>
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates/>
		</foreword>
	</xsl:template>
	
	<xsl:template match="sub-part//sec[label = 'Introduction']">
		<introduction>
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates/>
		</introduction>
	</xsl:template>
	
	<!-- =========================== -->
	<!-- END sub-part processing         -->
	<!-- =========================== -->
	
	<xsl:template match="license-p">
		<clause>
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates/>
		</clause>
	</xsl:template>
	
	<xsl:template match="boxed-text">
		<table unnumbered="true">
			<xsl:attribute name="id">
				<xsl:text>boxed-text_</xsl:text>
				<xsl:number level="any"/>
			</xsl:attribute>
			<tbody>
				<tr>
					<td valign="top" align="left"><xsl:apply-templates/></td>
				</tr>
			</tbody>
		</table>
	</xsl:template>
	
	<xsl:template match="styled-content[@style = 'addition' or @style-type = 'addition']">
		<add><xsl:apply-templates/></add>
	</xsl:template>

	<xsl:template match="styled-content[@style = 'addition' or @style-type = 'addition' or contains(@style-type, 'addition') or @specific-use = 'insert' or
											@style = 'deletion' or @style-type = 'deletion' or contains(@style-type, 'deletion') or @specific-use = 'delete']">
		<xsl:variable name="operator">
			<xsl:call-template name="getInsDel"/>
		</xsl:variable>
		<xsl:element name="{$operator}">
			<xsl:apply-templates />
		</xsl:element>
	</xsl:template>


	<xsl:template name="insertTaskImageList"> 
		<xsl:variable name="imageList">
			<xsl:for-each select="//graphic | //inline-graphic">
				<xsl:variable name="image"><xsl:call-template name="graphic"><xsl:with-param name="copymode">true</xsl:with-param></xsl:call-template></xsl:variable>
				<xsl:if test="not(contains(xalan:nodeset($image)/*/@src, 'base64,'))">
					<image><xsl:value-of select="xalan:nodeset($image)/*/@src"/></image>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="xalan:nodeset($imageList)//*[local-name() = 'image']">
			<redirect:write file="{$outpath}/task.copyImages.adoc"> <!-- this list will be processed and deleted in java program -->
				<xsl:text>&#xa;</xsl:text>
				<xsl:for-each select="xalan:nodeset($imageList)//*[local-name() = 'image']">
					<xsl:text>copyimage::</xsl:text><xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
				</xsl:for-each>
			</redirect:write>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="*[namespace-uri()='']" mode="setNamespace">
		<xsl:variable name="ns">
			<xsl:choose>
				<xsl:when test="ancestor-or-self::*[local-name() = concat($_typestandard, '-standard')]">
					<xsl:value-of select="$xml_result_namespace"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$xml_collection_result_namespace"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:element name="{name()}" namespace="{$ns}">
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates mode="setNamespace"/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="*[namespace-uri()!='']" mode="setNamespace">
		<xsl:copy-of select="."/>
	</xsl:template>
	
	<xsl:template match="processing-instruction()" mode="setNamespace">
		<xsl:copy-of select="."/>
	</xsl:template>
	
	<xsl:template name="organization_name_by_abbreviation">
		<xsl:param name="abbreviation"/>
		<xsl:choose>
			<xsl:when test="$abbreviation = 'IEC'"><name>International Electrotechnical Commission</name></xsl:when>
			<xsl:when test="$abbreviation = 'ISO'"><name>International Organization for Standardization</name></xsl:when>
			<xsl:when test="$abbreviation = 'BSI'"><name>The British Standards Institution</name></xsl:when>
		</xsl:choose>
	</xsl:template>
	
  <!-- ====================== -->
  <!-- add @displayorder      -->
  <!-- ====================== -->
  <xsl:template match="@*|node()" mode="displayorder">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="displayorder"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="preface/*" mode="displayorder">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="displayorder"/>
			<xsl:attribute name="displayorder"><xsl:number count="*[parent::preface]"/></xsl:attribute>
			<xsl:apply-templates select="node()" mode="displayorder"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="sections/*" mode="displayorder">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="displayorder"/>
			<xsl:variable name="count_preface_nodes" select="count(ancestor::*[contains(local-name(), '-standard')]/preface/*)"/>
			<xsl:variable name="count_normative_references_node" select="count(ancestor::*[contains(local-name(), '-standard')]/bibliography/*[@normative='true'])"/>
			<xsl:variable name="number_current_node"><xsl:number count="*[parent::sections]"/></xsl:variable>
			<xsl:attribute name="displayorder">
				<xsl:choose>
					<xsl:when test="@type = 'scope'"><xsl:value-of select="$count_preface_nodes + $number_current_node"/></xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$count_preface_nodes + $count_normative_references_node + $number_current_node"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates select="node()" mode="displayorder"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="annex" mode="displayorder">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="displayorder"/>
			<xsl:variable name="count_preface_nodes" select="count(ancestor::*[contains(local-name(), '-standard')]/preface/*)"/>
			<xsl:variable name="count_normative_references_node" select="count(ancestor::*[contains(local-name(), '-standard')]/bibliography/*[@normative = 'true'])"/>
			<xsl:variable name="count_sections_nodes" select="count(ancestor::*[contains(local-name(), '-standard')]/sections/*)"/>
			<xsl:variable name="number_current_node"><xsl:number count="annex"/></xsl:variable>
			<xsl:attribute name="displayorder">
				<xsl:value-of select="$count_preface_nodes + $count_normative_references_node + $count_sections_nodes + $number_current_node"/>
			</xsl:attribute>
			<xsl:apply-templates select="node()" mode="displayorder"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="bibliography/*[@normative = 'true']" mode="displayorder">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="displayorder"/>
			<xsl:variable name="count_preface_nodes" select="count(ancestor::*[contains(local-name(), '-standard')]/preface/*)"/>
			<xsl:variable name="count_scope_node" select="count(ancestor::*[contains(local-name(), '-standard')]/sections/*[@type = 'scope'])"/>
			<xsl:attribute name="displayorder">
				<xsl:value-of select="$count_preface_nodes + $count_scope_node + 1"/>
			</xsl:attribute>
			<xsl:apply-templates select="node()" mode="displayorder"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="bibliography/*[not(@normative = 'true')]" mode="displayorder">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="displayorder"/>
			<xsl:variable name="count_preface_nodes" select="count(ancestor::*[contains(local-name(), '-standard')]/preface/*)"/>
			<xsl:variable name="count_sections_nodes" select="count(ancestor::*[contains(local-name(), '-standard')]/sections/*)"/>
			<xsl:variable name="count_annex_nodes" select="count(ancestor::*[contains(local-name(), '-standard')]/annex)"/>
			<xsl:variable name="count_normative_references_node" select="count(ancestor::*[contains(local-name(), '-standard')]/bibliography/*[@normative = 'true'])"/>
			<xsl:attribute name="displayorder">
				<xsl:value-of select="$count_preface_nodes + $count_sections_nodes + $count_annex_nodes + $count_normative_references_node + 1"/>
			</xsl:attribute>
			<xsl:apply-templates select="node()" mode="displayorder"/>
		</xsl:copy>
	</xsl:template>
	<!-- ====================== -->
	<!-- END add @displayorder  -->
	<!-- ====================== -->

	<xsl:include href="sts2mn.common.xsl"/>
	
</xsl:stylesheet>