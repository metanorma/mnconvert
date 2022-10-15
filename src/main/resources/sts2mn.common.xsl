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

	<!-- ================= -->
	<!-- std model processing -->
	<!-- ================= -->
		
		
	<!-- build related refs model:
			Committee reference ...
			Draft for comment ...
	-->
	<xsl:template name="build_sts_related_refs">
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
	</xsl:template>
	

	
	<!-- build std model:
			reference - link to bibliography item
			referenceText - text for displaying (if it's difference from bibliography item text)
			locality - example: clause=2.5
			not_locality - after locality text
	-->
	<xsl:template name="build_sts_model_std">
	
		<xsl:variable name="std-ref" select=".//std-ref"/>
	
		<xsl:variable name="clause_from_std-id">
			<xsl:choose>
				<xsl:when test="std-id"> <!-- for IEC -->
					 <xsl:value-of select="substring-after(substring-after(std-id, '#'), '-')"/>
				</xsl:when>
				<xsl:otherwise> <!-- Example: iso:std:iso:13485:ed-2:en:clause:7 -->
					<xsl:value-of select="substring-after(@std-id, ':clause:')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="locality">
			<xsl:choose>
			
				<xsl:when test="$clause_from_std-id != ''"> <!-- if locality set in @std-id -->
					<locality>
						<xsl:choose>
							<xsl:when test="translate(substring($clause_from_std-id, 1, 1), '0123456789', '') = ''">clause=</xsl:when>
							<xsl:otherwise>annex=</xsl:otherwise>
						</xsl:choose>
						<xsl:value-of select="$clause_from_std-id"/>
					</locality>
				</xsl:when>
				
				<xsl:when test="not(@std-id) or $clause_from_std-id = ''">
					<!-- get text -->
					<xsl:variable name="std_text_">
						<xsl:choose>
							<xsl:when test=".//std-ref">
								<xsl:variable name="text">
									<xsl:for-each select=".//std-ref/preceding-sibling::node()">
										<xsl:variable name="preceding_text1" select="java:replaceAll(java:java.lang.String.new(.),'(\s|\h)(of|to)(\s|\h)?$','')"/>
										<!-- remove ' in ' from  '2.15 and in 6.4 of'  -->
										<xsl:variable name="preceding_text2" select="java:replaceAll(java:java.lang.String.new($preceding_text1),' and in ',' and ')"/>
										<xsl:value-of select="translate($preceding_text2, '&#xa0;', ' ')"/>
									</xsl:for-each>
									<xsl:for-each select=".//std-ref/following-sibling::node()[not(self::xref and @ref-type='bibr' and starts-with(., '['))]">
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
					
					<!-- remove leading ':', '—', comma -->
					<xsl:variable name="std_text" select="normalize-space(java:replaceAll(java:java.lang.String.new($std_text_),'^:?—?,?(.*)$','$1'))"/>
					<!-- replace ' to ' to '-' -->
					<!-- <xsl:variable name="std_text1" select="java:replaceAll(java:java.lang.String.new($std_text),' to [cC]lause ','-')"/>
					<xsl:variable name="std_text2" select="java:replaceAll(java:java.lang.String.new($std_text1),' to [aA]nnex ','-')"/>
					<xsl:variable name="std_text3" select="java:replaceAll(java:java.lang.String.new($std_text2),' to [tT]able ','-')"/>
					<xsl:variable name="std_text4" select="java:replaceAll(java:java.lang.String.new($std_text3),' to [sS]ection ','-')"/>
					<xsl:variable name="std_text5" select="java:replaceAll(java:java.lang.String.new($std_text4),' to ','-')"/> -->
					
					<!-- replace ' and|or Xxxxx ' to 'xxxxx' -->
					<!-- <xsl:variable name="std_text6" select="java:replaceAll(java:java.lang.String.new($std_text5),'( and | or )[cC]lause',',clause')"/>
					<xsl:variable name="std_text7" select="java:replaceAll(java:java.lang.String.new($std_text6),'( and | or )[aA]nnex',',annex')"/>
					<xsl:variable name="std_text8" select="java:replaceAll(java:java.lang.String.new($std_text7),'( and | or )[tT]able',',table')"/>
					<xsl:variable name="std_text9" select="java:replaceAll(java:java.lang.String.new($std_text8),'( and | or )[sS]ection',',section')"/> -->
					
					<!-- <xsl:variable name="std_text9" select="$std_text5"/> -->
					<xsl:variable name="std_text9" select="$std_text"/>
					
					<!-- replace  'Xxxxx' to 'xxxxx' -->
					<xsl:variable name="std_text10" select="java:replaceAll(java:java.lang.String.new($std_text9),'[aA]nnexes','annex')"/>
					<xsl:variable name="std_text11" select="java:replaceAll(java:java.lang.String.new($std_text10),'[aA]nnex','annex')"/>
					<xsl:variable name="std_text12" select="java:replaceAll(java:java.lang.String.new($std_text11),'[tT]able','table')"/>
					<xsl:variable name="std_text13" select="java:replaceAll(java:java.lang.String.new($std_text12),'[cC]lauses','clause')"/>
					<xsl:variable name="std_text14" select="java:replaceAll(java:java.lang.String.new($std_text13),'[cC]lause','clause')"/>
					<xsl:variable name="std_text15" select="java:replaceAll(java:java.lang.String.new($std_text14),'[sS]ection','section')"/>
					
					<xsl:variable name="std_text_lc_" select="$std_text15"/>
					
					<!-- <xsl:if test="$std_text_lc_ != '' and normalize-space($debug) = 'true'">
						<xsl:message>DEBUG: std_text_lc_=<xsl:value-of select="$std_text_lc_"/>&#xa;</xsl:message>
					</xsl:if> -->
					
					<xsl:variable name="std_text_lc">
						<xsl:choose>
							<xsl:when test="starts-with($std_text_lc_, 'annex')">
								<xsl:value-of select="java:replaceAll(java:java.lang.String.new($std_text_lc_),'( and | or | to )(?!annex)','$1 annex ')"/> <!-- annex X and Y.Z' to 'annex X and annex Y.Z'  -->
							</xsl:when>
							<xsl:when test="starts-with($std_text_lc_, 'table')">
								<xsl:value-of select="java:replaceAll(java:java.lang.String.new($std_text_lc_),'( and | or | to )(?!table)','$1 table ')"/> <!-- table X and Y.Z' to 'table X and table Y.Z'  -->
							</xsl:when>
							<xsl:when test="starts-with($std_text_lc_, 'clause')">
								<xsl:value-of select="java:replaceAll(java:java.lang.String.new($std_text_lc_),'( and | or | to )(?!clause)','$1 clause ')"/> <!-- clause X and Y.Z' to 'clause X and clause Y.Z'  -->
							</xsl:when>
							<xsl:when test="starts-with($std_text_lc_, 'section')">
								<xsl:value-of select="java:replaceAll(java:java.lang.String.new($std_text_lc_),'( and | or | to )(?!section)','$1 section ')"/> <!-- section X and Y.Z' to 'section X and section Y.Z'  -->
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$std_text_lc_"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<xsl:variable name="std_text_lc_with_conjunctions_">
						<xsl:call-template name="addLocalityStructure">
							<xsl:with-param name="std_text" select="$std_text_lc"/>
							<xsl:with-param name="std_ref" select="$std-ref"/>
						</xsl:call-template>
					</xsl:variable>
					<xsl:variable name="std_text_lc_with_conjunctions" select="xalan:nodeset($std_text_lc_with_conjunctions_)"/>
					
					<!-- <xsl:message>count std_text_lc_with_conjunctions/*=<xsl:value-of select="count($std_text_lc_with_conjunctions/*)"/></xsl:message>
					<xsl:if test="$std_text_lc != ''">
						<xsl:message>DEBUG: std_text_lc=<xsl:value-of select="$std_text_lc"/></xsl:message>
					</xsl:if>
					<xsl:for-each select="$std_text_lc_with_conjunctions/*">
						<xsl:message>DEBUG: <xsl:value-of select="local-name()"/>=<xsl:value-of select="."/></xsl:message>
					</xsl:for-each> -->
					
					<!-- <xsl:if test="normalize-space($debug) = 'true'">
						<xsl:message>
							<xsl:text>DEBUG: &#xa;</xsl:text>
							<xsl:for-each select="$std_text_lc_with_conjunctions/node()">
								<xsl:choose>
									<xsl:when test="self::text()">
										<xsl:text>text:</xsl:text><xsl:value-of select="."/>
										<xsl:text>&#xa;</xsl:text>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="local-name()"/>:<xsl:value-of select="."/>
										<xsl:text>&#xa;</xsl:text>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>
						</xsl:message>
					</xsl:if> -->
					
					<xsl:choose>
						<!-- <xsl:when test="contains($std_text_lc, 'clause') or contains($std_text_lc, 'annex') or contains($std_text_lc, 'table') or contains($std_text_lc, 'section')"> -->
						<!-- <xsl:when test="starts-with($std_text_lc, 'clause') or starts-with($std_text_lc, 'annex') or starts-with($std_text_lc, 'table') or starts-with($std_text_lc, 'section')"> -->
						<xsl:when test="$std_text_lc_with_conjunctions/*[1][self::locality]"> <!-- if first element is 'clause', 'annex', 'table' or 'section' -->
							<!-- <xsl:text>,</xsl:text> -->
							<!-- <xsl:variable name="pairs" select="translate($std_text_lc, ' ', '=')"/>
							<locality><xsl:value-of select="$pairs"/></locality> -->
							
							<!-- <xsl:for-each select="$std_text_lc_with_conjunctions/node()">
								<xsl:choose>
									<xsl:when test="self::text()">
										<xsl:variable name="pairs" select="translate(., ' ', '=')"/>
										<locality><xsl:value-of select="$pairs"/></locality>
									</xsl:when>
									<xsl:otherwise>
										<xsl:copy-of select="."/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:for-each> -->
							
							<xsl:copy-of select="$std_text_lc_with_conjunctions"/>
							
							<!-- <xsl:value-of select="java:toLowerCase(java:java.lang.String.new(substring-before($pair, '=')))"/>
							<xsl:text>=</xsl:text>
							<xsl:variable name="localityDestination" select="substring-after($pair, '=')"/>
							<xsl:value-of select="$localityDestination"/> -->
						</xsl:when>
						<!-- <xsl:when test="contains($std_text_lc, 'clause') or contains($std_text_lc, 'annex') or contains($std_text_lc, 'table') or contains($std_text_lc, 'section')"> -->
						<xsl:when test="$std_text_lc_with_conjunctions/*[self::locality]"> <!-- if there is 'clause', 'annex', 'table' or 'section', but not first -->
							<!-- <xsl:text>,</xsl:text> -->
							<!-- <xsl:variable name="pairs" select="translate($std_text_lc, ' ', '=')"/>
							<xsl:choose>
								<xsl:when test="translate(substring($pairs, 1, 1), '0123456789', '') = ''"><locality>clause=<xsl:value-of select="$pairs"/></locality></xsl:when>
								<xsl:otherwise><locality>annex=<xsl:value-of select="$pairs"/></locality></xsl:otherwise>
							</xsl:choose> -->
							
							<xsl:for-each select="$std_text_lc_with_conjunctions/*">
								<xsl:choose>
									<xsl:when test="self::localityValue and not(preceding-sibling::*[1][self::locality])">
										<xsl:variable name="pairs" select="translate(., ' ', '=')"/>
										<xsl:choose>
											<xsl:when test="translate(substring($pairs, 1, 1), '0123456789', '') = ''">
												<locality>clause</locality>
											</xsl:when>
											<xsl:otherwise>
												<locality>annex</locality>
											</xsl:otherwise>
										</xsl:choose>
										<xsl:copy-of select="."/> <!-- localityValue -->
									</xsl:when>
									<xsl:otherwise>
										<xsl:copy-of select="."/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>
							
						</xsl:when>
						<xsl:when test="contains($std_text_lc, 'definition')">
							<xsl:variable name="pairs" select="translate($std_text_lc, ' ', '=')"/>
							<locality>locality:<xsl:value-of select="$pairs"/></locality>
						</xsl:when>
						<xsl:when test="not(.//std-ref)"></xsl:when> <!-- <std std-id="ISO 13485:2016" type="dated">ISO 13485:2016</std> -->
						<xsl:otherwise>
						
							<!-- SKIP -->
							<xsl:variable name="parts">
								<!-- <xsl:call-template name="split">
									<xsl:with-param name="pText" select="$std_text_lc"/>
									<xsl:with-param name="sep" select="' '"/>
								</xsl:call-template> -->
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
							<!-- END SKIP -->
							
							<xsl:for-each select="$std_text_lc_with_conjunctions/*">
								<xsl:choose>
									<xsl:when test="self::localityValue">
										<xsl:variable name="pairs" select="translate(., ' ', '=')"/>
										<xsl:choose>
											<xsl:when test="translate(substring($pairs, 1, 1), '0123456789', '') = ''">
												<locality>clause</locality>
											</xsl:when>
											<xsl:when test="substring($pairs, 1, 1) = 'R'">
												<locality droploc="true">locality:requirement</locality>
											</xsl:when>
											<xsl:otherwise>
												<locality>annex</locality>
											</xsl:otherwise>
										</xsl:choose>
										<xsl:copy-of select="."/> <!-- localityValue -->
									</xsl:when>
									<xsl:when test="self::referenceText and normalize-space(.) !=''"> <!-- if there is not locality text -->
										<!-- <referenceText><xsl:value-of select="$std-ref"/><xsl:text> </xsl:text><xsl:value-of select="."/></referenceText> -->
										<xsl:copy-of select="."/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:copy-of select="."/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>
							
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		
		<!-- <xsl:message>DEBUG locality:</xsl:message>
		<xsl:for-each select="xalan:nodeset($locality)/*">
			<xsl:message><xsl:value-of select="local-name()"/>=<xsl:value-of select="."/></xsl:message>
		</xsl:for-each> -->
		<!--
		<xsl:message>DEBUG: std-id=<xsl:value-of select="std-id"/></xsl:message>
		<xsl:message>DEBUG: $std-id=<xsl:value-of select="java:replaceAll(java:java.lang.String.new(std-id), '(#.*)?$','')"/></xsl:message>
		-->
		
		<xsl:variable name="reference">
			<xsl:choose>
				<xsl:when test="std/std-id"> <!-- for IEC -->
					<xsl:variable name="std-id" select="java:replaceAll(java:java.lang.String.new(std-id), '(#.*)?$','')"/>
					<xsl:call-template name="getReference_std">
						<xsl:with-param name="std-id" select="$std-id"/>
						<xsl:with-param name="locality" select="$locality"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="getReference_std">
						<xsl:with-param name="std-id" select="current()/@std-id"/>
						<xsl:with-param name="std-id2" select="current()/@std-id2"/>
						<xsl:with-param name="std-id3" select="current()/@std-id3"/>
						<xsl:with-param name="locality" select="$locality"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
			
		</xsl:variable>
			
		<xsl:variable name="model">
			<xsl:choose>
				<!-- <xsl:when test="xalan:nodeset($ref_by_stdid)/*"> --> <!-- if references in References found, then put id of those reference -->
				<xsl:when test="normalize-space($reference) != ''"> <!-- if references in References found, then put id of those reference -->
					<!-- <xsl:value-of select="xalan:nodeset($ref_by_stdid)/@id"/> -->
					<!-- <xsl:value-of select="$reference"/> -->
					<xsl:copy-of select="$reference"/>
					<!-- <xsl:value-of select="$locality"/> -->
				</xsl:when>
				<xsl:otherwise> <!-- put id of current std -->
					<xsl:choose>
						<xsl:when test="normalize-space(@std-id2) != '' or normalize-space(@std-id3) != ''">
							<reference hidden="true">
								<xsl:value-of select="@std-id2"/>
								<xsl:if test="normalize-space(@std-id2) = ''">
									<xsl:value-of select="@std-id3"/>
								</xsl:if>
							</reference>
							<!-- if there isn't in References, then display name -->
							<xsl:variable name="std-ref_text" select=".//std-ref/text()"/>
							<xsl:if test="normalize-space($std-ref_text) != ''">
								<referenceText><xsl:value-of select="$std-ref_text"/></referenceText>
							</xsl:if>
						</xsl:when>
						<xsl:otherwise>
							<xsl:call-template name="getStdRef">
								<xsl:with-param name="text" select=".//std-ref"/>
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
					
					<!-- <xsl:value-of select="$locality"/> -->
					<!-- <xsl:for-each select="xalan:nodeset($locality)/locality">
						<xsl:text>,</xsl:text><xsl:value-of select="."/>
					</xsl:for-each> -->
					<xsl:copy-of select="$locality"/>
					
				</xsl:otherwise>
			</xsl:choose>
	
		</xsl:variable>
	
		<!-- cleaning model -->
		<xsl:for-each select="xalan:nodeset($model)/*">
			<xsl:choose>
				<xsl:when test="self::referenceText and normalize-space() = ''"><!-- remove empty referenceText --></xsl:when>
				<xsl:when test="self::referenceText and preceding-sibling::referenceText/text() = current()/text()"><!-- remove repeated referenceText --></xsl:when>
				<xsl:when test="self::referenceText and following-sibling::referenceText[normalize-space() != ''][contains(text(), current()/text()) and not(text() = current()/text())]"><!-- remove referenceText, if next referenceText contains more information --></xsl:when>
				<!-- copy as-is -->
				<xsl:when test="self::referenceText">
					<referenceText><xsl:value-of select="translate(., '&#xA0;&#x2011;', ' -')"/></referenceText>
				</xsl:when>
				<xsl:otherwise><xsl:copy-of select="."/></xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	
	</xsl:template>

	<xsl:template name="getReference_std">
		<xsl:param name="std-id"/>
		<xsl:param name="std-id2"/>
		<xsl:param name="std-id3"/>
		<xsl:param name="locality"/>
		<!-- @id2, @id3 and @id4 attributes were added in linearize.xsl -->
		<xsl:variable name="ref_" select="$updated_xml//ref[($std-id != '' and (@id = $std-id or @id2 = $std-id or @id3 = $std-id or @id4 = $std-id)) or
													($std-id2 != '' and (@id = $std-id2 or @id2 = $std-id2 or @id3 = $std-id2 or @id4 = $std-id2)) or
													($std-id3 != '' and (@id = $std-id3 or @id2 = $std-id3 or @id3 = $std-id3 or @id4 = $std-id3))]"/>
		<xsl:variable name="ref" select="xalan:nodeset($ref_)"/>
		<xsl:variable name="ref_by_stdid" select="normalize-space($ref/@id)"/> <!-- find ref by id -->
		<reference><xsl:value-of select="$ref_by_stdid"/></reference>
		<xsl:if test="$ref_by_stdid != ''">
			<!-- <xsl:value-of select="$locality"/> -->
			<!-- <xsl:variable name="locality_" select="xalan:nodeset($locality)"/>
			<xsl:for-each select="$locality_/locality">
				<xsl:text>,</xsl:text><xsl:value-of select="."/>
			</xsl:for-each> -->
			<xsl:copy-of select="$locality"/> <!-- *[self::locality] -->
			<xsl:if test="$ref/@addTextToReference = 'true' or xalan:nodeset($locality)/not_locality or $OUTPUT_FORMAT = 'xml'">
				<!-- <xsl:text>,</xsl:text> -->
				<referenceText>
					<xsl:value-of select=".//std-ref/text()"/>
					<!-- <xsl:for-each select="$locality_/not_locality">
						<xsl:text> </xsl:text><xsl:value-of select="."/>
					</xsl:for-each> -->
				</referenceText>
			</xsl:if>
		</xsl:if>
	</xsl:template>

	<!-- special case <std>...</std></std-ref><xref ref-type="bibr" ...><sup>[...]</sup></xref> -->
	<xsl:template match="std[not(ancestor::ref)]/xref[@ref-type='bibr'][starts-with(sup,'[')]"/>
								
	<xsl:template name="addLocalityStructure">
		<xsl:param name="std_text"/>
		<xsl:param name="std_ref"/>
		<!-- <xsl:message>DEBUG: std_text=<xsl:value-of select="$std_text"/></xsl:message>
			<xsl:message>std_ref=<xsl:value-of select="$std_ref"/></xsl:message> -->
		
		<!-- case: 'series' inside of std-ref:
			<std>
				<std-ref>ISO 10667 series</std-ref>
			</std>
		-->
		<xsl:if test="(contains(normalize-space($std_ref), 'series') or contains(normalize-space($std_ref), 'parts'))"> <!-- if there is not locality text -->
			<referenceText><xsl:value-of select="$std_ref"/></referenceText>
		</xsl:if>
		<xsl:choose>
			<!-- case - 'all parts' outside of std-ref:
				<std std-id="BS EN ISO 14064" type="undated">
						<std-ref>BS EN ISO 14064<?doi https://doi.org/10.3403/BSENISO14064?>
						</std-ref> (all parts)</std>
			-->
			<xsl:when test="(contains($std_text, 'series') or contains($std_text, 'parts'))"> <!-- if there is not locality text -->
				<referenceText><xsl:value-of select="$std_ref"/><xsl:text> </xsl:text><xsl:value-of select="$std_text"/></referenceText>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="parts_">
					<xsl:call-template name="split">
						<xsl:with-param name="pText" select="$std_text"/>
						<xsl:with-param name="sep" select="' '"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:variable name="parts" select="xalan:nodeset($parts_)"/>
				<xsl:for-each select="$parts/item">
					<xsl:choose>
						<xsl:when test="normalize-space() = 'clause' or normalize-space() = 'annex' or normalize-space() = 'table' or normalize-space() = 'section'">
							<xsl:if test="following-sibling::*[2] = 'to'">
								<localityConj>from</localityConj>
							</xsl:if>
							<locality><xsl:value-of select="normalize-space()"/></locality>
						</xsl:when>
						<xsl:when test="normalize-space() = 'and' or normalize-space() = 'or' or normalize-space() = 'to'">
							<localityConj><xsl:value-of select="."/></localityConj>
						</xsl:when>
						<xsl:when test="normalize-space() != ''">
							<localityValue><xsl:value-of select="translate(.,',','')"/></localityValue> <!-- remove comma -->
						</xsl:when>
					</xsl:choose>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- ================= -->
	<!-- END std model processing -->
	<!-- ================= -->

	<!-- ================= -->
	<!-- IEEE sts model processing -->
	<!-- ================= -->
	<xsl:template name="build_ieee_model_std">
		<xsl:variable name="isHidden">
			<xsl:if test="parent::mixed-citation and not(parent::mixed-citation/following-sibling::*[1][self::xref[@ref-type = 'bibr']])">true</xsl:if>
		</xsl:variable>
		<xsl:variable name="id" select="translate(pub-id,' ','_')"/>
		<reference>
			<xsl:if test="$isHidden = 'true'">	
				<xsl:attribute name="isHidden">true</xsl:attribute>
				<xsl:text>hidden_</xsl:text>
			</xsl:if>
			<xsl:value-of select="$id"/>
		</reference>
		<xsl:if test="$isHidden = 'true'">
			<xsl:variable name="referenceText">
				<xsl:apply-templates />
			</xsl:variable>
			<referenceText><xsl:value-of select="normalize-space($referenceText)"/></referenceText>
		</xsl:if>
	</xsl:template>
	<!-- ================= -->
	<!-- END IEEE sts model processing -->
	<!-- ================= -->

	<!-- ================= -->
	<!-- tbx:source model processing -->
	<!-- ================= -->
	
	<!-- build term's source model:
			reference - link to bibliography item
			referenceText - text for displaying (if it's difference from bibliography item text)
			locality - example: clause 2.5
			localityContinue - uses when locality number placed in another element than locality, for example, '=2.5'
		-->
	<xsl:variable name="regex_adapted_from_text">^.*Adapted from:?[\s|\h](.*)$</xsl:variable>
	<xsl:variable name="regex_modified_from_text">^.*Modified from:?[\s|\h](.*)$</xsl:variable>
	<xsl:variable name="regex_quoted_from_text">^.*Quoted from:?[\s|\h](.*)$</xsl:variable>
	
	<xsl:variable name="source_text">SOURCE:</xsl:variable>
	 
	<xsl:template name="build_sts_model_term_source">
		<xsl:variable name="model">
			<xsl:apply-templates />
			<xsl:variable name="isModified" select="contains(normalize-space(.), ' modified') or .//node()[starts-with(., 'modified')]"/>
			<xsl:if test="$isModified = 'true'">
				<modified>
					<xsl:text>,</xsl:text>
					<xsl:value-of select="java:replaceAll(java:java.lang.String.new(substring-after(normalize-space(.), 'modified')), '^(\s|\h)*(-|–|—)?(\s|\h)*','')"/> <!-- ' modified' -->
				</modified>
			</xsl:if>
			<xsl:if test="java:org.metanorma.utils.RegExHelper.matches($regex_adapted_from_text, normalize-space(.)) = 'true'">
				<adapted/>
			</xsl:if>
			<xsl:if test="java:org.metanorma.utils.RegExHelper.matches($regex_modified_from_text, normalize-space(.)) = 'true'">
				<!-- <modified_from/> -->
				<modified>
					<xsl:text>,</xsl:text>
				</modified>
			</xsl:if>
			<xsl:if test="java:org.metanorma.utils.RegExHelper.matches($regex_quoted_from_text, normalize-space(.)) = 'true'">
				<quoted/>
			</xsl:if>
		</xsl:variable>
		
		
		
		<!-- cleaning model -->
		<xsl:for-each select="xalan:nodeset($model)/*">
			<xsl:choose>
				<xsl:when test="self::referenceText and normalize-space() = ''"><!-- remove empty referenceText --></xsl:when>
				<xsl:when test="self::referenceText and (preceding-sibling::referenceText/text() = current()/text() or preceding-sibling::referenceTextInBibliography/text() = current()/text())"><!-- remove repeated referenceText --></xsl:when>
				<xsl:when test="(self::referenceText or self::referenceTextInBibliography) and following-sibling::referenceText[normalize-space() != ''][contains(text(), current()/text()) and not(text() = current()/text())]"><!-- remove referenceText, if next referenceText contains more information --></xsl:when>
				<xsl:when test="self::referenceText">
					<referenceText><xsl:value-of select="translate(., '&#xA0;&#x2011;', ' -')"/></referenceText>
				</xsl:when>
				<!-- copy as-is -->
				<xsl:otherwise><xsl:copy-of select="."/></xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		
	</xsl:template>
	
	
	<xsl:template match="tbx:source/text()" priority="3">
		
		<xsl:variable name="isFirstText" select="not(preceding-sibling::node())"/>
	
		<!-- <xsl:variable name="modified_text">, modified</xsl:variable> -->
		<xsl:variable name="modified_text_regex">^(.*),?(\s|\h)?modified(.*)$</xsl:variable>
		
		<!-- remove 'Adapted from:' or 'Adapted from' text -->
		<!-- remove 'Quoted from:' or 'Quoted from' text -->
		<!-- remove 'Modified from:' or 'Modified from' text -->
		<xsl:variable name="text_">
			<xsl:choose>
				<xsl:when test="$isFirstText = 'true' and starts-with(., $source_text)">
					<xsl:value-of select="normalize-space(substring-after(., $source_text))"/>
				</xsl:when>
				<!-- <xsl:when test="contains(., concat($adapted_from_text, ':'))">
					<xsl:value-of select="normalize-space(substring-after(., concat($adapted_from_text, ':')))"/>
				</xsl:when>
				<xsl:when test="contains(., $adapted_from_text)">
					<xsl:value-of select="normalize-space(substring-after(., $adapted_from_text))"/>
				</xsl:when>
				<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise> -->
				<xsl:otherwise>
					<xsl:variable name="text1" select="java:replaceAll(java:java.lang.String.new(.), $regex_adapted_from_text, '$1')"/> <!-- without 'Adapted from' -->
					<xsl:variable name="text2" select="java:replaceAll(java:java.lang.String.new($text1), $regex_modified_from_text, '$1')"/> <!-- without 'Modified from' -->
					<xsl:variable name="text3" select="java:replaceAll(java:java.lang.String.new($text2), $regex_quoted_from_text, '$1')"/> <!-- without 'Quoted from' -->
					<xsl:value-of select="$text3"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<!-- remove modified text -->
		<xsl:variable name="text">
			<xsl:choose>
				<!-- <xsl:when test="contains($text_, $modified_text) or contains(preceding-sibling::text(), $modified_text)">
					<xsl:value-of select="substring-before($text_, $modified_text)"/>
				</xsl:when> -->
				<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($modified_text_regex, $text_) = 'true' or
					java:org.metanorma.utils.RegExHelper.matches($modified_text_regex, preceding-sibling::text()) = 'true'">
					<xsl:value-of select="java:replaceAll(java:java.lang.String.new($text_), $modified_text_regex, '$1')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$text_"/>
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
								<!-- <item><xsl:value-of select="$xref_bibr_rid"/></item> -->
								<reference><xsl:value-of select="$xref_bibr_rid"/></reference>
								<!-- <xsl:text>,</xsl:text> -->
								<!-- <item><xsl:value-of select="$item_text"/></item> -->
								<referenceText><xsl:value-of select="$item_text"/></referenceText>
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
						<xsl:variable name="regex_clause">^(Clause(\s|\h)+)[0-9]+(\.[0-9]+)*$</xsl:variable>
						<xsl:variable name="regex_definition">^(definition(\s|\h)+)([0-9]+(\.[0-9]+)*)*$</xsl:variable>
						<xsl:variable name="regex_box">^(Box(\s|\h)+)([0-9]+)$</xsl:variable>
						<xsl:variable name="item_text_normalized" select="normalize-space($item_text)"/>
						<xsl:choose>
							<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($regex_clause, $item_text_normalized) = 'true'"> <!-- Example: Clause 4 -->
								<locality>
									<xsl:value-of select="java:toLowerCase(java:java.lang.String.new($item_text))"/>
								</locality>
							</xsl:when>
							<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($regex_definition, $item_text_normalized) = 'true'"> <!-- Example: definition 3.1 -->
								<locality>
									<xsl:text>locality:definition=</xsl:text><xsl:value-of select="java:replaceAll(java:java.lang.String.new($item_text),$regex_definition,'$3')"/>
								</locality>
							</xsl:when>
							<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($regex_box, $item_text_normalized) = 'true'"> <!-- Example: Box 8 -->
								<locality>
									<xsl:text>locality:box=</xsl:text><xsl:value-of select="java:replaceAll(java:java.lang.String.new($item_text),$regex_box,'$3')"/>
								</locality>
							</xsl:when>
							<xsl:when test="java:org.metanorma.utils.RegExHelper.matches('^[0-9]+(\.[0-9]+)*$', $item_text_normalized) = 'true'"> <!-- Example: 3.23 or 3.2.4 -->
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
										<referenceText>
											<xsl:value-of select="$item_text"/>
										</referenceText>
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
		<!-- <xsl:call-template name="insertStd"/> -->
		<xsl:call-template name="build_sts_model_std"/>
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
	
	<xsl:template match="tbx:source/fn" priority="3">
		<referenceText><xsl:call-template name="fn"/></referenceText>
	</xsl:template>
	
	<!-- Examples: ISO number, BS EN number, EN ISO number -->
	<xsl:variable name="start_standard_regex">^((CN|IEC|(IEC/[A-Z]{2,3})|IETF|BCP|ISO|(ISO/[A-Z]{2,3})|ITU|NIST|OGC|CC|OMG|UN|W3C|IEEE|IHO|BIPM|ECMA|CIE|BS|BSI|BS(\s|\h)OHSAS|PAS|PD|CEN|(CEN/[A-Z]{2,3})|CEN/CENELEC|EN|IANA|3GPP|OASIS|IEV)(\s|\h))+((Guide|TR|TC)(\s|\h))?\d.*</xsl:variable>
	
	<xsl:template name="getStdRef">
		<xsl:param name="text" select="."/>
		<!-- <xsl:variable name="std-ref" select="java:replaceAll(java:java.lang.String.new($text),'- -','—')"/> -->
		<!-- <xsl:message>DEBUG: getStdRef text=<xsl:value-of select="$text"/></xsl:message> -->
		<xsl:variable name="std-ref">
			<xsl:call-template name="getNormalizedId">
				<xsl:with-param name="id" select="$text"/>
			</xsl:call-template>
		</xsl:variable>
		
		<!-- refs=<xsl:for-each select="xalan:nodeset($refs)//ref">
			id3=<xsl:value-of select="@id3"/><xsl:text>&#xa;</xsl:text>
		</xsl:for-each> -->
		
		<!-- std-ref=<xsl:value-of select="$std-ref"/><xsl:text>&#xa;</xsl:text> -->
		<!-- <xsl:variable name="ref1" select="//ref[std/std-ref = $std-ref]/@id"/> -->
		<xsl:variable name="ref1_" select="$refs//ref[@id3 = $std-ref]"/>				
		<xsl:variable name="ref1" select="xalan:nodeset($ref1_)"/>
		<!-- ref1=<xsl:value-of select="$ref1"/><xsl:text>&#xa;</xsl:text> -->
		<!-- <xsl:variable name="ref2" select="//ref[starts-with(std/std-ref, concat($std-ref, ' '))]/@id"/> -->
		<xsl:variable name="ref2_" select="$refs//ref[starts-with(@id3, concat($std-ref, ' '))]"/>
		<xsl:variable name="ref2" select="xalan:nodeset($ref2_)"/>
		<!-- ref2=<xsl:value-of select="$ref2"/><xsl:text>&#xa;</xsl:text> -->
		
		<xsl:variable name="ref3_" select="$refs//ref[@id3 = $std-ref]"/> <!-- /@id3 -->
		<xsl:variable name="ref3" select="xalan:nodeset($ref3_)"/>				
		
		<!-- find by referenceText, example: GHTF/SG1/N055:2009 -->
		<!-- <xsl:variable name="ref4_" select="$refs//ref[@referenceText = $text]"/> -->
		<xsl:variable name="ref4_" select="$refs//ref[@id5 = $std-ref]"/>
		<xsl:variable name="ref4" select="xalan:nodeset($ref4_)"/>
		
		<xsl:choose>
			<xsl:when test="$ref1/@id != ''">
				<reference><xsl:value-of select="$ref1/@id"/></reference>
				
				<xsl:if test="$ref1/@addTextToReference = 'true' or $OUTPUT_FORMAT = 'xml'">
					<!-- if reference to standard and bibitem is numbered, for example: [1] -->
					<!-- <xsl:text>,</xsl:text> -->
					<referenceText><xsl:value-of select="$text"/></referenceText>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$ref2/@id != ''">
				<reference><xsl:value-of select="$ref2/@id"/></reference>
				
				<xsl:if test="$ref2/@addTextToReference = 'true' or $OUTPUT_FORMAT = 'xml'">
					<!-- if reference to standard and bibitem is numbered, for example: [1] -->
					<!-- <xsl:text>,</xsl:text> -->
					<referenceText><xsl:value-of select="$text"/></referenceText>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$ref3/@id3 != ''">
				<reference><xsl:value-of select="$ref3/@id3"/></reference>
				
				<xsl:if test="$ref3/@addTextToReference = 'true' or $OUTPUT_FORMAT = 'xml'">
					<!-- if reference to standard and bibitem is numbered, for example: [1] -->
					<!-- <xsl:text>,</xsl:text> -->
					<referenceText><xsl:value-of select="$text"/></referenceText>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$ref4/@id != ''">
				<reference><xsl:value-of select="$ref4/@id"/></reference>
				
				<xsl:if test="$ref4/@addTextToReference = 'true' or $OUTPUT_FORMAT = 'xml'">
					<referenceText><xsl:value-of select="$text"/></referenceText>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<reference hidden="true">
					<xsl:value-of select="$std-ref"/>
				</reference>
				<referenceTextInBibliography><xsl:value-of select="$text"/></referenceTextInBibliography>
				<xsl:if test="$OUTPUT_FORMAT = 'xml' or 
					java:org.metanorma.utils.RegExHelper.matches($start_standard_regex, normalize-space($text)) = 'false'"> <!-- don't put reference text if it is reference to the standard -->
					<referenceText><xsl:value-of select="$text"/></referenceText>
				</xsl:if>
				
				<!-- <xsl:choose>
					<xsl:when test="$std-ref != $text">
						<reference hidden="true">
							<xsl:value-of select="$std-ref"/>
						</reference>
						<referenceTextInBibliography><xsl:value-of select="$text"/></referenceTextInBibliography>
						<xsl:if test="$OUTPUT_FORMAT = 'xml'">
							<referenceText><xsl:value-of select="$text"/></referenceText>
						</xsl:if>
					</xsl:when>
					<xsl:otherwise>
						<reference hidden="true"><xsl:value-of select="$text"/></reference>
						<xsl:if test="$OUTPUT_FORMAT = 'xml'">
							<referenceText><xsl:value-of select="$text"/></referenceText>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose> -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- ================= -->
	<!-- END tbx:source model processing -->
	<!-- ================= -->
	
	<xsl:variable name="regex_refid_replacement" select="'( |&#xA0;|:|\+|/|\-|\(|\)|–|‑)'"/>
	<!-- generate normalized form for id  (std-id, std-ref, etc.) -->
	<xsl:template name="getNormalizedId">
		<xsl:param name="id"/>
		<!-- <xsl:variable name="id_normalized1" select="translate($id, ' &#xA0;:+/', '_____')"/> --> <!-- replace space, non-break space, colon, plus, slash to _ -->
		<xsl:variable name="id_normalized1" select="java:replaceAll(java:java.lang.String.new($id), $regex_refid_replacement, '_')"/> <!-- replace space, non-break space, colon, plus, slash to _ -->
		
		<xsl:variable name="id_normalized2" select="translate($id_normalized1, '&#x2011;', '-')"/> <!-- replace non-breaking hyphen minus to simple minus-->
		<xsl:variable name="first_char" select="substring(id_normalized2,1,1)"/>
		<xsl:if test="$first_char != '' and translate($first_char, '0123456789', '') = ''">_</xsl:if> <!-- if first char is digit, then add _ -->
		<xsl:value-of select="normalize-space($id_normalized2)"/>
	</xsl:template>
	
	<!-- ========================================= -->
	<!-- References fixing -->
	<!-- ========================================= -->
	<xsl:template match="@*|node()" mode="ref_fix">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="ref_fix"/>
		</xsl:copy>
	</xsl:template>
	
	
	<!-- Add @stdid (and @id3) to ref for reference mechanism between <std std-id="..."></std> and <ref></ref> -->
	<xsl:template match="ref | list[@list-content = 'normative-references']/list-item/p" mode="ref_fix">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="ref_fix"/>
			
			<xsl:variable name="std-id">
				<xsl:choose>
					<xsl:when test="std/std-id"> <!-- for IEC -->
						<xsl:call-template name="getNormalizedId">
							<xsl:with-param name="id" select="std/std-id"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<!-- Example:
							<ref>
								<std std-id="iso:std:iso:44001:ed-1:en" type="dated">
									<std-ref>ISO 44001:2017
									</std-ref>, <title>...</title>
								</std>
							</ref> -->
						<xsl:call-template name="getNormalizedId">
							<xsl:with-param name="id" select="std/@std-id"/>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			 
			<xsl:variable name="std-ref">
				<!-- Example:
					<ref>
						<std>
							<std-ref>BS ISO 44001:2017</std-ref>, <title>...</title>
						</std>
					</ref> -->
				<xsl:call-template name="getNormalizedId">
					<xsl:with-param name="id" select="normalize-space(concat(std/std-ref, std/italic/std-ref, std/bold/std-ref, std/italic2/std-ref, std/bold2/std-ref))"/>
				</xsl:call-template>
			</xsl:variable>
			
			<xsl:variable name="id2_">
				<xsl:choose>
					<xsl:when test="$std-id != ''">
						<xsl:value-of select="$std-id"/>
					</xsl:when>
					<xsl:when test="$std-ref != ''">
						<xsl:value-of select="$std-ref"/>
					</xsl:when>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="id2" select="normalize-space($id2_)"/>
			
			<xsl:if test="$id2 != ''">
				<xsl:attribute name="id2"><xsl:value-of select="$id2"/></xsl:attribute>
				<xsl:if test="not(@id)"><!-- create attribute id for ref, if not exists -->
					<xsl:attribute name="id"><xsl:value-of select="$id2"/></xsl:attribute>
				</xsl:if>
			</xsl:if>
			
			<xsl:if test="$std-ref != ''">
				<xsl:attribute name="id3"> <!-- create attribute for std with std-ref only -->
					<xsl:value-of select="$std-ref"/>
				</xsl:attribute>
			</xsl:if>
			
			<xsl:if test="mixed-citation/@id">
				<xsl:attribute name="id4">
					<xsl:value-of select="mixed-citation/@id"/>
				</xsl:attribute>
			</xsl:if>
			
			
			<xsl:variable name="referenceText_">
				<xsl:variable name="std-ref_text">
					<xsl:apply-templates select="std/std-ref | std/italic/std-ref | std/bold/std-ref | std/italic2/std-ref | std/bold2/std-ref" mode="references"/>
				</xsl:variable>
				<xsl:value-of select="$std-ref_text"/>
				<xsl:if test="normalize-space($std-ref_text) = ''">
					<xsl:choose>
						<xsl:when test="$inputformat = 'STS'">
							<xsl:variable name="mixed-citation_first_text_" select="normalize-space(translate((mixed-citation//text()[normalize-space()!=''])[1], '&#xA0;&#x2011;', ' -'))"/>
							<xsl:variable name="mixed-citation_first_text">
								<xsl:choose>
									<xsl:when test="contains($mixed-citation_first_text_, ',')"><xsl:value-of select="normalize-space(substring-before($mixed-citation_first_text_,','))"/></xsl:when>
									<xsl:otherwise><xsl:value-of select="$mixed-citation_first_text_"/></xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- check if mixed-citatiot contains standard like reference,
							Example: GHTF/SG1/N055:2009 -->
							
							<!-- if first text in mixed-citation ends ends with :year OR
							starts with ISO|IEC... and count of digits more 2 -->
							<xsl:if test="java:org.metanorma.utils.RegExHelper.matches('.*\d+:\d{4}$', $mixed-citation_first_text) = 'true' or 
								(java:org.metanorma.utils.RegExHelper.matches($start_standard_regex, $mixed-citation_first_text) = 'true' and 
									java:org.metanorma.utils.RegExHelper.matches('.*\d{2,}.*', $mixed-citation_first_text) = 'true'
								)">
								<xsl:value-of select="$mixed-citation_first_text"/>
							</xsl:if>
						</xsl:when>
						<xsl:otherwise> <!-- IEEE -->
							<xsl:apply-templates select="mixed-citation" mode="IEEE"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</xsl:variable>
			<xsl:variable name="referenceText" select="normalize-space($referenceText_)"/>
			
			<xsl:attribute name="referenceText">
				<xsl:value-of select="normalize-space($referenceText_)"/>
			</xsl:attribute>
			
			<xsl:variable name="content-type">
				<xsl:choose>
					<xsl:when test="(not(@content-type) or @content-type = 'standard') and
							$referenceText != '' and java:org.metanorma.utils.RegExHelper.matches($start_standard_regex, $referenceText) = 'false' and $inputformat = 'STS'">standard_other</xsl:when>
					<xsl:when test="@content-type"><xsl:value-of select="@content-type"/></xsl:when>
					<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($start_standard_regex, $referenceText) = 'true'">standard</xsl:when>
				</xsl:choose>
			</xsl:variable>
			
			<xsl:if test="$content-type != ''">
				<xsl:attribute name="content-type"><xsl:value-of select="$content-type"/></xsl:attribute>
			</xsl:if>
			
			<xsl:attribute name="addTextToReference">
				<xsl:value-of select="normalize-space(($content-type = 'standard' or $content-type = 'standard_other') and starts-with(label, '['))"/>
			</xsl:attribute>
			
			<xsl:attribute name="id5">
				<xsl:call-template name="getNormalizedId">
					<xsl:with-param name="id" select="$referenceText"/>
				</xsl:call-template>
			</xsl:attribute>
			
			<xsl:attribute name="id6">
				<xsl:variable name="preceding_title" select="java:toLowerCase(java:java.lang.String.new(translate(preceding-sibling::title[1]/text(), ' ', '_')))"/>
				<xsl:choose>
					<xsl:when test="normalize-space($preceding_title) != ''">
						<xsl:value-of select="java:replaceAll(java:java.lang.String.new($preceding_title),'_{2,}','_')"/>_<xsl:number/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>bibliography_</xsl:text>
						<xsl:choose>
							<xsl:when test="parent::list-item"><xsl:number count="list-item"/></xsl:when>
							<xsl:otherwise><xsl:number/></xsl:otherwise> <!-- ref -->
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			
			<!-- extract number from '[1]', '[N1]', '1)' , remove non-digit chars except N -->
			<xsl:variable name="label_number" select="normalize-space(java:replaceAll(java:java.lang.String.new(label),'[^\dN]',''))"/> 
			
			<xsl:if test="$label_number != ''">
				<xsl:attribute name="label_number">
					<xsl:value-of select="$label_number"/>
				</xsl:attribute>
			</xsl:if>

			<xsl:apply-templates select="node()" mode="ref_fix"/>
		</xsl:copy>
	</xsl:template>

	<!-- Add stdid to std for reference mechanism between <std std-id="..."></std> and <ref></ref> -->
	<xsl:template match="std[not(parent::ref)]" mode="ref_fix">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="ref_fix"/>
			
			<xsl:if test="normalize-space(@std-id) != ''"> <!-- if there is attribute @std-id -->
				<xsl:attribute name="std-id2">
					<xsl:variable name="std_id">
						<xsl:choose>
							<xsl:when test="contains(@std-id, ':clause:')"><xsl:value-of select="substring-before(@std-id, ':clause:')"/></xsl:when>
							<xsl:otherwise><xsl:value-of select="@std-id"/></xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:call-template name="getNormalizedId">
						<xsl:with-param name="id" select="$std_id"/>
					</xsl:call-template>
				</xsl:attribute>
			</xsl:if>
			
			<xsl:if test="normalize-space(.//std-ref) != ''"> <!-- if there is nested std-ref -->
				<xsl:attribute name="std-id3">
					<xsl:variable name="std_ref_text_" select="normalize-space(.//std-ref)"/>
					<xsl:variable name="std_ref_text" select="normalize-space(java:replaceAll(java:java.lang.String.new($std_ref_text_),'(,.*)?$',''))"/> <!-- remove comma at end -->
					<xsl:call-template name="getNormalizedId">
						<xsl:with-param name="id" select="normalize-space($std_ref_text)"/>
					</xsl:call-template>
				</xsl:attribute>
			</xsl:if>
			
			<xsl:apply-templates select="node()" mode="ref_fix"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="std[not(parent::ref)]/std-ref/text()[last()]" mode="ref_fix">
		<xsl:choose>
			<xsl:when test="contains(., ',')"> <!-- for IEC, comma in std-ref - locality -->
				<xsl:value-of select="substring-before(., ',')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="std[not(parent::ref)]/std-ref" mode="ref_fix" priority="2">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<!-- <xsl:copy-of select="."/> --> <!-- copy as-is -->
			<xsl:apply-templates mode="ref_fix"/>
		</xsl:copy>
		<!-- move comma outside std-ref --> <!-- for IEC -->
		<xsl:if test="contains(text()[last()], ',')"> <!-- for IEC, comma in std-ref - locality -->
			<xsl:text>,</xsl:text><xsl:value-of select="substring-after(text()[last()], ',')"/>
		</xsl:if>
	</xsl:template>
	
	<!-- special case -->
	<!-- Example: PAS 91:2013 Construction prequalification questionnaires -->
	<xsl:template match="tbx:source/text()[1]" mode="ref_fix">
		<xsl:choose>
			<xsl:when test="not(contains(., ',')) and
			java:org.metanorma.utils.RegExHelper.matches('^.*(\s|\h)\d+:\d{4}(\s|\h).*$', .) = 'true'">
				<!-- <xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),'^(.*(\s|\h)\d+:\d{4})((\s|\h).*)$','$1,$1 $3')"/> -->
				
				<xsl:variable name="part1" select="java:replaceAll(java:java.lang.String.new(.),'^(.*(\s|\h)\d+:\d{4})((\s|\h).*)$','$1')"/>
				
				<xsl:variable name="part1_text1" select="java:replaceAll(java:java.lang.String.new($part1), $regex_adapted_from_text, '$1')"/> <!-- without 'Adapted from' -->
				<xsl:variable name="part1_text2" select="java:replaceAll(java:java.lang.String.new($part1_text1), $regex_modified_from_text, '$1')"/> <!-- without 'Modified from' -->
				<xsl:variable name="part1_text3" select="java:replaceAll(java:java.lang.String.new($part1_text2), $regex_quoted_from_text, '$1')"/> <!-- without 'Quoted from' -->
				
				<xsl:variable name="part2" select="$part1_text3"/>
				
				<xsl:variable name="part3" select="java:replaceAll(java:java.lang.String.new(.),'^(.*(\s|\h)\d+:\d{4})((\s|\h).*)$','$3')"/>
				
				<xsl:value-of select="concat($part1, ',', $part2, ' ', $part3)"/>
				
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- ========================================= -->
	<!-- END References fixing -->
	<!-- ========================================= -->
	
	<xsl:template match="ref/std/std-ref" mode="references">
		<xsl:apply-templates mode="references"/>
	</xsl:template>
	
	<xsl:template match="ref/std/std-ref/text()" mode="references">
		<!-- remove [ and ] -->
		<!-- replace non-breaking space to space -->
		<!-- replace non-breaking hyphen minus to minus -->
		<xsl:value-of select="translate(translate(.,'[]',''), '&#xA0;&#x2011;', ' -')"/>
	</xsl:template>
	
	<!-- =============================== -->
	<!-- Relations (std-xref processing) -->
	<!-- =============================== -->
	<xsl:template name="getRelations">
		<xsl:for-each select="std-xref[normalize-space() != '']">
			<relation>
				<xsl:attribute name="type">
					<xsl:choose>
						<xsl:when test="java:toLowerCase(java:java.lang.String.new(@type)) = 'revises'">revises</xsl:when>
						<xsl:when test="java:toLowerCase(java:java.lang.String.new(@type)) = 'replaces'">replaces</xsl:when>
						<xsl:when test="java:toLowerCase(java:java.lang.String.new(@type)) = 'amends'">amends</xsl:when>
						<xsl:when test="java:toLowerCase(java:java.lang.String.new(@type)) = 'corrects'">corrects</xsl:when>
						<xsl:when test="@type = 'informativelyReferencedBy'">informatively-cited-in</xsl:when>
						<xsl:when test="@type = 'informativelyReferences'">informatively-cites</xsl:when>
						<xsl:when test="@type = 'normativelyReferencedBy'">normatively-cited-in</xsl:when>
						<xsl:when test="@type = 'normativelyReferences'">normatively-cites</xsl:when>
						<xsl:when test="@type = 'isIdenticalNationalStandardOf'">identical-adopted-from</xsl:when>
						<xsl:when test="@type = 'isModifiedNationalStandardOf'">modified-adopted-from</xsl:when>
						<xsl:when test="@type = 'isProgressionOf'">successor-of</xsl:when>
						<xsl:when test="@type = 'isPublishedFormatOf'">manifestation-of</xsl:when>
						<xsl:when test="@type = 'relatedDirective'">related-directive</xsl:when>
						<xsl:when test="@type = 'relatedMandate'">related-mandate</xsl:when>
						<xsl:when test="@type = 'commentOn'">annotation-of</xsl:when>
						<xsl:when test="java:toLowerCase(java:java.lang.String.new(@type)) = 'supersedes'">supersedes</xsl:when>
						<xsl:when test="@type = ''">related</xsl:when> <!-- (empty value) -->
						<xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				<xsl:value-of select="normalize-space(translate(std-ref, '&#xA0;&#x2011;', ' -'))"/>
			</relation>
		</xsl:for-each>
	</xsl:template>
	<!-- =============================== -->
	<!-- END Relations (std-xref processing) -->
	<!-- =============================== -->
	
	
	<!-- build fig model:
			title_main - figure's name
			caption/title - nested figure's name
			graphic - figure's filename
			key - table's key
			non-normative-note - figure's note(s)
	-->
	<xsl:template name="build_sts_model_fig">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:copy-of select=".//*/@orientation"/>
			<xsl:apply-templates mode="model_fig"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="@*|node()" mode="model_fig">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="model_fig"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="fig/caption" mode="model_fig"> <!-- remove 'caption' element, but not nested elements -->
		<xsl:apply-templates mode="model_fig"/>
	</xsl:template>
	
	<xsl:template match="fig/caption/title" mode="model_fig">
		<title_main>
			<xsl:apply-templates mode="model_fig"/>
		</title_main>
	</xsl:template>
	
	<xsl:template match="fig/caption/p" mode="model_fig">
		<xsl:choose>
			<xsl:when test="$inputformat = 'IEEE'">
				<title_main>
					<xsl:apply-templates mode="model_fig"/>
				</title_main>
			</xsl:when>
			<xsl:otherwise>
				<non-normative-note><xsl:apply-templates mode="model_fig"/></non-normative-note>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	<xsl:template match="fig/*[self::table-wrap or self::array][count(table/col) + count(table/colgroup/col) = 1 and .//graphic]" mode="model_fig">
		<xsl:apply-templates mode="model_fig"/>
	</xsl:template>
	
	
	<xsl:template match="fig/*[self::table-wrap or self::array][count(table/col) + count(table/colgroup/col) = 1 and .//graphic]/caption" mode="model_fig">
		<non-normative-note>
			<p>
				<xsl:apply-templates mode="model_fig"/>
			</p>
		</non-normative-note>
	</xsl:template>
	
	<xsl:template match="fig/p[preceding-sibling::*[not(self::p)][1][self::graphic]]" mode="model_fig" priority="2">
		<graphic_text>
			<xsl:copy>
				<xsl:copy-of select="@*"/>
				<xsl:apply-templates mode="model_fig"/>
			</xsl:copy>
		</graphic_text>
	</xsl:template>
	
	<xsl:template match="fig/p" mode="model_fig">
		<non-normative-note>
			<xsl:copy>
				<xsl:copy-of select="@*"/>
				<xsl:apply-templates mode="model_fig"/>
			</xsl:copy>
		</non-normative-note>
	</xsl:template>
	
	<xsl:template match="fig/*[self::table-wrap or self::array][count(table/col) + count(table/colgroup/col) = 1 and .//graphic]/table" mode="model_fig">
		<xsl:apply-templates mode="ignore_table"/>
	</xsl:template>
	
	<!-- figure's key -->
	<xsl:template match="fig/array[@content-type = 'figure-index' or @content-type = 'fig-index']" mode="model_fig">
		<key label="{label}">
			<xsl:apply-templates mode="model_fig"/>
		</key>
	</xsl:template>
	
	<xsl:template match="fig/array/@orientation" mode="model_fig"/>
	
	<xsl:template match="fig/table-wrap[@content-type = 'figure-index' or @content-type = 'fig-index']" mode="model_fig">
		<!-- <key label="{caption/title}"> -->
			<xsl:copy>
				<xsl:copy-of select="@*"/>
				<xsl:apply-templates mode="model_fig"/>
			</xsl:copy>
		<!-- </key> -->
	</xsl:template>
	
	<xsl:template match="fig/table-wrap/@orientation" mode="model_fig"/>
	
	<!-- Special case: table with image and key -->
	<xsl:template match="fig[not(graphic) and array and not(table-wrap)]/array" mode="model_fig">
		<xsl:apply-templates select="../*[not(self::array or self::caption or self::label)]" mode="model_fig"/>
		<xsl:apply-templates select="." mode="fig_array"/>
	</xsl:template>
	
	<!-- ============= -->
	<!-- mode: ignore_table -->
	<!-- ============= -->
	<xsl:template match="@*|node()" mode="ignore_table">
		<xsl:apply-templates select="@*|node()" mode="ignore_table"/>
	</xsl:template>
	
	<xsl:template match="tr[.//graphic]" mode="ignore_table">
		<xsl:copy-of select=".//graphic"/>
	</xsl:template>
	
	<xsl:template match="tr[not(.//graphic)]" mode="ignore_table">
		<title><xsl:apply-templates select="td/node()" mode="model_fig"/></title>
	</xsl:template>
	
	<xsl:template match="td/text()[1]" mode="model_fig">
		<!-- Example: 'a) Common fire relay' to 'Common fire relay' -->
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),$regexListItemLabel, '$6')"/> <!-- get last group from regexListItemLabel, i.e. list item text without label-->
	</xsl:template>
	
	<!-- ============= -->
	<!-- END mode: ignore_table -->
	<!-- ============= -->
	
	
	<!-- ============= -->
	<!-- mode: fig_array -->
	<!-- ============= -->
	<xsl:template match="fig/array" mode="fig_array" priority="2">
		<xsl:variable name="MAX_ROW">99999</xsl:variable>
		<!-- table's row number with 'Key' -->
		<xsl:variable name="row_key_" select="count(.//tr[normalize-space(td) = 'Key']/preceding-sibling::tr)" />
		<xsl:variable name="row_key">
			<xsl:choose>
				<xsl:when test="$row_key_ = '0'"><xsl:value-of select="$MAX_ROW"/></xsl:when> <!-- no Key -->
				<xsl:otherwise><xsl:value-of select="$row_key_ + 1"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<!-- <xsl:text>&#xa;row-key=</xsl:text><xsl:value-of select="$row_key"/><xsl:text>&#xa;</xsl:text> -->
		
		<xsl:for-each select=".//tr[position() &lt; $row_key]">
			<xsl:if test=".//graphic">
				<xsl:if test="not(following-sibling::tr[1]//graphic) and position() != last() and not(following-sibling::tr[1]//non-normative-note)">
					<title>
						<xsl:apply-templates select="following-sibling::tr[1]" mode="fig_array"/>
					</title>
				</xsl:if>
				<xsl:apply-templates select="." mode="fig_array"/>
			</xsl:if>
			<xsl:if test=".//non-normative-note">
				<xsl:apply-templates mode="fig_array"/>
			</xsl:if>
		</xsl:for-each>
		
		
		<xsl:if test="$row_key != $MAX_ROW"> <!-- if there is table with 'Key' -->
			<key>
				<xsl:copy>
					<xsl:copy-of select="@*"/>
					<xsl:apply-templates select="table" mode="copy_table">
						<xsl:with-param name="rownum" select="$row_key"/>
					</xsl:apply-templates>
					<xsl:for-each select="table2"> <!-- change context to 'table' -->
						<xsl:copy>
							<xsl:copy-of select="@*"/>
								<xsl:for-each select=".//tr[position() &gt;= $row_key]">
									<xsl:apply-templates select="." mode="model_fig"/>
								</xsl:for-each>
						</xsl:copy>
					</xsl:for-each>
				</xsl:copy>
			</key>
		</xsl:if>
		
	</xsl:template>
	
	<xsl:template match="tr" mode="fig_array" priority="2">
		<xsl:apply-templates mode="fig_array"/>
	</xsl:template>
	
	<xsl:template match="td" mode="fig_array" priority="2">
		<xsl:apply-templates mode="fig_array"/>
	</xsl:template>
	
	<xsl:template match="*" mode="fig_array">
		<xsl:apply-templates select="." mode="model_fig"/>
	</xsl:template>
	
	<xsl:template match="td/text()[1]" mode="fig_array">
		<!-- Example: 'a) Common fire relay' to 'Common fire relay' -->
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),$regexListItemLabel, '$6')"/> <!-- get last group from regexListItemLabel, i.e. list item text without label-->
	</xsl:template>
	<!-- ============= -->
	<!-- END mode: fig_array -->
	<!-- ============= -->
	
	
	<!-- ================= -->
	<!-- copy table rows after specified row -->
	<!-- ================= -->
	<xsl:template match="@*|node()" mode="copy_table">
		<xsl:param name="rownum"/>
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="copy_table">
				<xsl:with-param name="rownum" select="$rownum"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="tr" mode="copy_table">
		<xsl:param name="rownum"/>
		<xsl:variable name="rownum_curr"><xsl:number/></xsl:variable>
		<xsl:if test="$rownum_curr &gt;= $rownum">
			<xsl:copy-of select="."/>
		</xsl:if>
	</xsl:template>
	
	<!-- ================= -->
	<!-- END: copy table rows after specified row -->
	<!-- ================= -->
	
	<!-- sts model graphic:
		caption/title
		@filename
		@unnumbered = 'true'
		alt-text
	-->
	<xsl:template name="build_sts_model_graphic">
		<xsl:param name="copymode">false</xsl:param>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:if test="not(caption/title) and not(parent::fig)"> <!--  and not(ancestor::table) -->
				<xsl:attribute name="unnumbered">true</xsl:attribute>
			</xsl:if>
			<xsl:attribute name="filename">
				
				<!-- Example: <graphic xlink:href="fig_A.2"><?isoimg-id 14812_ed1figA2.EPS?></graphic> -->
				
				<xsl:if test="@xlink:href and not(processing-instruction('isoimg-id')) or (@xlink:href and $organization = 'ISO')">
					<xsl:variable name="image_link" select="@xlink:href"/>
					<xsl:choose>
						<xsl:when test="contains($image_link, 'base64,')">
							<xsl:value-of select="$image_link"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:if test="$copymode = 'false' and $OUTPUT_FORMAT = 'xml'"><xsl:value-of select="$imagesdir"/><xsl:text>/</xsl:text></xsl:if>
							<xsl:value-of select="$image_link"/>
							<xsl:if test="not(contains($image_link, '.png')) and not(contains($image_link, '.jpg')) and not(contains($image_link, '.bmp')) and not(contains($image_link, '.tif'))">
								<xsl:text>.png</xsl:text>
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
				
				<xsl:if test="not(@xlink:href and $organization = 'ISO')">
					<xsl:apply-templates select="processing-instruction('isoimg-id')" mode="pi_isoimg-id">
						<xsl:with-param name="copymode" select="$copymode"/>
					</xsl:apply-templates>
				</xsl:if>
				
			</xsl:attribute>
			
			<xsl:apply-templates mode="model_graphic"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="@*|node()" mode="model_graphic">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="model_graphic"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="*[self::graphic or self::inline-graphic]/processing-instruction('isoimg-id')" mode="model_graphic"/>
	<xsl:template match="*[self::graphic or self::inline-graphic]/processing-instruction('isoimg-id')" mode="pi_isoimg-id">
		<xsl:param name="copymode">false</xsl:param>
		<xsl:variable name="image_link" select="."/>
		<xsl:if test="$copymode = 'false' and $OUTPUT_FORMAT = 'xml'"><xsl:value-of select="$imagesdir"/><xsl:text>/</xsl:text></xsl:if>
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
	
	<!-- end build_sts_model_graphic -->
	
	<!-- ======================== -->
	<!-- end  build_sts_model_fig -->
	<!-- ======================== -->
	
	
	<xsl:variable name="regexSectionTitle" select="'^Section(\s|\h)+[0-9]+(:|\-|\.)*(\s|\h)*(.*)$'"/>
	<xsl:variable name="regexSectionLabel" select="'^Section(\s|\h)+[0-9]+$'"/>
	
	<xsl:variable name="regex_term_domain">(?s)^(&lt;(.*)&gt;)?(\s|\h)*(.*)$</xsl:variable> <!-- (?s)  for single line. Dot matches newline characters -->
	
	<xsl:template name="getStyleColor">
		<xsl:variable name="value" select="normalize-space(substring-after(., 'color:'))"/>
		<xsl:choose>
			<xsl:when test="contains($value, ';')"><xsl:value-of select="substring-before($value, ';')"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
		</xsl:choose>
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
	
	<xsl:template name="getInsDel">
		<xsl:choose>
			<xsl:when test="@style = 'addition' or @style-type = 'addition' or contains(@style-type, 'addition') or @specific-use = 'insert'">add</xsl:when>
			<xsl:when test="@style = 'deletion' or @style-type = 'deletion' or contains(@style-type, 'deletion') or @specific-use = 'delete'">del</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="getAlignment_style-type">
		<xsl:if test="@style-type">
		
			<xsl:variable name="style-type_">
				<xsl:call-template name="split">
					<xsl:with-param name="pText" select="@style-type"/>
					<xsl:with-param name="sep" select="';'"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="style-type" select="xalan:nodeset($style-type_)"/>
			
			<xsl:variable name="align" select="$style-type/item[starts-with(., 'align-')]"/>
			<xsl:value-of select="substring-after($align, 'align-')"/>
		</xsl:if>
	</xsl:template>
	
</xsl:stylesheet>