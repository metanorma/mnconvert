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
	
	<!-- build std model:
			reference - link to bibliography item
			referenceText - text for displaying (if it's difference from bibliography item text)
			locality - example: clause=2.5
			not_locality - after locality text
	-->
	<xsl:template name="build_sts_model_std">
	
		<xsl:variable name="clause">
			<xsl:choose>
				<xsl:when test="std-id"> <!-- for IEC -->
					 <xsl:value-of select="substring-after(substring-after(std-id, '#'), '-')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="substring-after(@std-id, ':clause:')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
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
		
		<!--
		<xsl:message>DEBUG: std-id=<xsl:value-of select="std-id"/></xsl:message>
		<xsl:message>DEBUG: $std-id=<xsl:value-of select="java:replaceAll(java:java.lang.String.new(std-id), '(#.*)?$','')"/></xsl:message>
		-->
		
		<xsl:variable name="reference">
			<xsl:choose>
				<xsl:when test="std/std-id"> <!-- for IEC -->
					<xsl:variable name="std-id" select="java:replaceAll(java:java.lang.String.new(std-id), '(#.*)?$','')"/>
					<xsl:call-template name="getReference_std">
						<xsl:with-param name="stdid" select="$std-id"/>
						<xsl:with-param name="locality" select="$locality"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="getReference_std">
						<xsl:with-param name="stdid" select="current()/@stdid"/>
						<xsl:with-param name="locality" select="$locality"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
			
		</xsl:variable>
		
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
					<xsl:when test="@stdid">
						<reference hidden="true">
							<!-- <xsl:text>hidden_bibitem_</xsl:text> -->
							<xsl:value-of select="@stdid"/><xsl:text></xsl:text>
						</reference>
						<!-- if there isn't in References, then display name -->
						<xsl:variable name="std-ref_text" select=".//std-ref/text()"/>
						<xsl:if test="normalize-space($std-ref_text) != ''">
							<!-- <xsl:text>,</xsl:text><xsl:value-of select="$std-ref_text"/> -->
							<referenceText><xsl:value-of select="$std-ref_text"/></referenceText>
						</xsl:if>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="getStdRef">
							<xsl:with-param name="text" select="std-ref"/>
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
	
	</xsl:template>

	<xsl:template name="getReference_std">
		<xsl:param name="stdid"/>
		<xsl:param name="locality"/>
		<!-- @stdid and @stdid_option attributes were added in linearize.xsl -->
		<xsl:variable name="ref_" select="$updated_xml//ref[@stdid = $stdid or @stdid_option = $stdid or @id = $stdid]"/>
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

	<!-- ================= -->
	<!-- END std model processing -->
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
	<xsl:template name="build_sts_model_term_source">
		<xsl:apply-templates />
		<xsl:variable name="isModified" select="contains(normalize-space(.), ' modified')"/>
		<xsl:if test="$isModified = 'true'">
			<modified>
				<xsl:text>,</xsl:text>
				<xsl:value-of select="java:replaceAll(java:java.lang.String.new(substring-after(normalize-space(.), ' modified')), '^(\s|\h)*(-|–)?(\s|\h)*','')"/>
			</modified>
		</xsl:if>
	</xsl:template>
	
	
	<xsl:template match="tbx:source/text()" priority="3">
	
		<xsl:variable name="isFirstText" select="not(preceding-sibling::node())"/>
	
		<xsl:variable name="modified_text">, modified</xsl:variable>
		
		<!-- remove modified text -->
		<xsl:variable name="text">
			<xsl:choose>
				<xsl:when test="contains(., $modified_text) or contains(preceding-sibling::text(), $modified_text)">
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
			<xsl:when test="$ref3/@stdid_option != ''">
				<reference><xsl:value-of select="$ref3/@stdid_option"/></reference>
				
				<xsl:if test="$ref3/@addTextToReference = 'true' or $OUTPUT_FORMAT = 'xml'">
					<!-- if reference to standard and bibitem is numbered, for example: [1] -->
					<!-- <xsl:text>,</xsl:text> -->
					<referenceText><xsl:value-of select="$text"/></referenceText>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="$std-ref != $text">
						<reference hidden="true">
							<!-- <xsl:text>hidden_bibitem_</xsl:text> -->
							<xsl:value-of select="$std-ref"/>
						</reference><!-- , -->
						<referenceText><xsl:value-of select="$text"/></referenceText>
					</xsl:when>
					<xsl:otherwise>
						<!-- <xsl:text>hidden_bibitem_</xsl:text> -->
						<reference hidden="true"><xsl:value-of select="$text"/></reference>
						<xsl:if test="$OUTPUT_FORMAT = 'xml'">
							<referenceText><xsl:value-of select="$text"/></referenceText>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
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
		<xsl:value-of select="$id_normalized2"/>
	</xsl:template>
	
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
				<xsl:choose>
					<xsl:when test="std/std-id"> <!-- for IEC -->
						<xsl:call-template name="getNormalizedId">
							<xsl:with-param name="id" select="std/std-id"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="getNormalizedId">
							<xsl:with-param name="id" select="std/@std-id"/>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
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
						<xsl:variable name="std_ref_text_" select="normalize-space(.//std-ref)"/>
						<xsl:variable name="std_ref_text" select="normalize-space(java:replaceAll(java:java.lang.String.new($std_ref_text_),'(,.*)?$',''))"/> <!-- remove comma at end -->
						<xsl:call-template name="getNormalizedId">
							<!-- <xsl:with-param name="id" select="normalize-space(.//std-ref)"/> -->
							<xsl:with-param name="id" select="normalize-space($std_ref_text)"/>
						</xsl:call-template>
					</xsl:when>
				</xsl:choose>
			</xsl:attribute>
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
	<!-- ========================================= -->
	<!-- END References fixing -->
	<!-- ========================================= -->
	
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
				<xsl:value-of select="normalize-space(std-ref)"/>
			</relation>
		</xsl:for-each>
	</xsl:template>
	<!-- =============================== -->
	<!-- END Relations (std-xref processing) -->
	<!-- =============================== -->
	
	<xsl:variable name="regexSectionTitle" select="'^Section(\s|\h)+[0-9]+(:|\-|\.)*(\s|\h)*(.*)$'"/>
	<xsl:variable name="regexSectionLabel" select="'^Section(\s|\h)+[0-9]+$'"/>
	
</xsl:stylesheet>