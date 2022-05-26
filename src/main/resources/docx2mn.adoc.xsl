<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
					xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
					xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
					xmlns:rels="http://schemas.openxmlformats.org/package/2006/relationships"
					xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
					xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"
					xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
					xmlns:mml="http://www.w3.org/1998/Math/MathML" 
					xmlns:xlink="http://www.w3.org/1999/xlink" 
					xmlns:xalan="http://xml.apache.org/xalan" 
					xmlns:java="http://xml.apache.org/xalan/java" 
					xmlns:redirect="http://xml.apache.org/xalan/redirect"
					xmlns:metanorma-class-util="xalan://org.metanorma.utils.Util"
					exclude-result-prefixes="xalan mml xlink java metanorma-class-util"
					extension-element-prefixes="redirect"
					version="1.0">
					
	<xsl:output method="text" encoding="UTF-8"/>
	
	<xsl:param name="debug">false</xsl:param>
	
	<xsl:param name="docfile_name">document</xsl:param> <!-- Example: iso-tc154-8601-1-en , or document -->
	
	<xsl:param name="docfile_ext">adoc</xsl:param>
	
	
	<xsl:param name="pathSeparator" select="'/'"/>
	
	<xsl:param name="outpath"/>

	<xsl:param name="imagesdir" select="'images'"/>
	
	<!-- input xml file 'word\_rels\document.xml.rels' -->
	<!-- xml with relationships -->
	<xsl:param name="rels_file"/>
	<!-- or Nodes (programmatically called from mn2convert) -->
	<xsl:param name="rels"/>

	<xsl:variable name="em_dash">—</xsl:variable>
	<xsl:variable name="en_dash">–</xsl:variable>
	
	<xsl:variable name="docfile" select="concat($outpath,$pathSeparator,$docfile_name, '.', $docfile_ext)"/>
	<xsl:variable name="sectionsFolder">sections</xsl:variable>
	
	<xsl:variable name="rels_xml_">
		<xsl:choose>
			<xsl:when test="$rels_file != ''">
				<xsl:copy-of select="document($rels_file)"/> 
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$rels"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="rels_xml" select="xalan:nodeset($rels_xml_)"/>

	<!-- .docx zip content:
	
		./word/document.xml - document body (entry point for this template)
		
	-->
	

	<xsl:template match="/">
		<!-- DEBUG
		<xsl:variable name="env">
			<xsl:copy-of select="xalan:checkEnvironment()"/>
		</xsl:variable>
		<xsl:apply-templates select="xalan:nodeset($env)" mode="print_as_xml"/> -->
		
		<xsl:variable name="xml_update1">
			<xsl:apply-templates mode="update1"/>
		</xsl:variable>
		
		<xsl:variable name="xml_update2">
			<xsl:apply-templates select="xalan:nodeset($xml_update1)" mode="update2"/>
		</xsl:variable>
		
		<!-- <xsl:apply-templates select="xalan:nodeset($xml_update2)" mode="print_as_xml"/> -->
		
		<redirect:open file="{$docfile}"/>
		
		<xsl:apply-templates select="xalan:nodeset($xml_update2)/node()"/>
		
		<redirect:close file="{$docfile}"/>
		
	</xsl:template>
	
	
	<!-- ==================================== -->
	<!-- XML update 1 -->
	<!-- ==================================== -->
	<xsl:template match="@*|node()" mode="update1">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="update1"/>
		</xsl:copy>
	</xsl:template>
	
	<!-- XML cleaning -->
	<!-- remove deleted text on the cover page -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzCover']/w:del" mode="update1"/>
	
	<!-- remove deleted items in the Normative References and Bibliography -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'BiblioEntry0' or w:pPr/w:pStyle/@w:val = 'RefNorm']/w:del" mode="update1"/>
	
	<!-- remove deleted 'obligation' for Annex -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'ANNEX']/w:del[contains(., 'normative') or contains(., 'informative')]" mode="update1"/>
	
	<!-- remove Standard title before Scope -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzSTDTitle']" mode="update1"/>
	
	<!-- END XML cleaning -->
	
	<!-- add tag <startsection/> -->
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'ForewordTitle' or @w:val = 'IntroTitle']]" mode="update1">
		<startsection id="{generate-id()}"/>
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="update1"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'Heading1' or @w:val = 'BiblioTitle']]" mode="update1">
		<startsection id="{generate-id()}"/>
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="update1"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'ANNEX']" mode="update1">
		<startsection id="{generate-id()}"/>
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="update1"/>
		</xsl:copy>
	</xsl:template>
	<!-- ==================================== -->
	<!-- END XML update 1 -->
	<!-- ==================================== -->
	
	
	<!-- ==================================== -->
	<!-- XML update 2 -->
	<!-- ==================================== -->
	<xsl:template match="@*|node()" mode="update2">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="update2"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="startsection" mode="update2">
		<xsl:variable name="curr_id" select="@id"/>
		<section>
			<xsl:copy-of select="following-sibling::*[preceding-sibling::startsection[1][@id = $curr_id]][not(self::startsection)]"/>
		</section>
	</xsl:template>
	
	<xsl:template match="node()[not(self::startsection)][preceding-sibling::startsection]" mode="update2"/>
	
	<!-- ==================================== -->
	<!-- END XML update 2 -->
	<!-- ==================================== -->
	
	<!-- output each section into a separate file -->
	<xsl:template match="section">
	
		<xsl:variable name="section_name">
			<xsl:choose>
				<xsl:when test="w:p[w:pPr/w:pStyle[@w:val = 'ForewordTitle']]">00-foreword</xsl:when>
				<xsl:when test="w:p[w:pPr/w:pStyle[@w:val = 'IntroTitle']]">00-introduction</xsl:when>
				<xsl:when test="w:p[w:pPr/w:pStyle[@w:val = 'BiblioTitle']]">99-bibliography</xsl:when>
				<xsl:when test="w:p[w:pPr/w:pStyle[@w:val = 'Heading1']]">
					<xsl:variable name="section_number_" select="count(preceding-sibling::section[not(w:p[w:pPr/w:pStyle[@w:val = 'ForewordTitle' or @w:val = 'IntroTitle']])]) + 1"/>
					<xsl:variable name="section_number" select="format-number($section_number_, '00')"/>
					<xsl:variable name="first_text_" select="java:replaceAll(java:java.lang.String.new(normalize-space(w:p[1])),'^\d*(.*)','$1')"/> <!-- remove digits at start -->
					<xsl:variable name="first_text">
						<xsl:choose>
							<xsl:when test="$first_text_ = 'Normative references'">normref</xsl:when>
							<xsl:when test="contains($first_text_, ' ')"><xsl:value-of select="substring-before($first_text_, ' ')"/></xsl:when>
							<xsl:otherwise><xsl:value-of select="$first_text_"/></xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:value-of select="concat($section_number,'_',java:toLowerCase(java:java.lang.String.new($first_text)))"/>
				</xsl:when>
				<xsl:when test="w:p[w:pPr/w:pStyle[@w:val = 'ANNEX']]">
					<!-- <xsl:variable name="first_text_" select="java:toLowerCase(java:java.lang.String.new(normalize-space((.//*[self::w:r or self::w:ins])[1])))"/>
					<xsl:variable name="annex_letter" select="translate(substring-after($first_text_, ' '),' ','')"/>
					<xsl:variable name="first_text" select="translate($first_text_, ' ', '_')"/>
					<xsl:value-of select="concat('a',$annex_letter,'-',$first_text)"/> -->
					
					<!-- Annex letter generation -->
					<xsl:variable name="alphabet" select="'abcdefghijklmnopqrstuvwxyz'"/>
					<xsl:variable name="annex_number" select="count(preceding-sibling::section/w:p[w:pPr/w:pStyle[@w:val = 'ANNEX']]) + 1"/>
					<xsl:variable name="addon" select="format-number($annex_number div 26,'0')"/>
					<xsl:variable name="addon_letter" select="substring($alphabet, $addon, 1)"/>
					<xsl:variable name="annex_letter" select="concat($addon_letter, substring($alphabet, $annex_number mod 26, 1))"/>
					
					<xsl:value-of select="concat('a',$annex_letter,'-annex-',$annex_letter)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="normalize-space(w:p[1])"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
	
		<redirect:write file="{$docfile}">
			<xsl:text>include::</xsl:text><xsl:value-of select="concat($sectionsFolder,'/',$section_name,'.adoc')"/><xsl:text>[]</xsl:text>
			<xsl:text>&#xa;&#xa;</xsl:text>
		</redirect:write>
		
		<xsl:variable name="filename" select="concat($sectionsFolder,$pathSeparator,$section_name,'.adoc')"/>
		
		<redirect:write file="{concat($outpath,$pathSeparator,$filename)}">
			<xsl:apply-templates />
		</redirect:write>
	
	</xsl:template>
	<!-- end 'section' -->
	
	<xsl:template match="w:p">
		<xsl:apply-templates/>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	
	<xsl:template match="w:pPr">
		<xsl:apply-templates/>
	</xsl:template>
	
	<!-- Processing for styles
		ForewordTitle
		IntroTitle
		Heading1
		Heading2
		Heading3
		Heading4
		Heading5
		Heading6
		Heading7
		TermNum
		Terms
		Note
		Example
		Source
		Tabletitle
		Tablebody0
		zzCopyright
		zzContents
		TOCx
		zzCover
		ListContinue
		ListNumber
		Figurenote
		zzSTDTitle
		FigureTitle
		AnnexFigureTitle
		AltTerms
		DeprecatedTerms
		Definition
		Formula
		tabletitle
	-->
	
	
	
	<!-- ============================= -->
	<!-- 1st level section's titles processing -->
	<!-- ============================= -->
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'ForewordTitle' or @w:val = 'IntroTitle']]">
		<xsl:text>== </xsl:text>
		<xsl:apply-templates/>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	<!-- ============================= -->
	<!-- END 1st level section's titles processing -->
	<!-- ============================= -->
	
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'Heading1' or @w:val = 'Heading2' or @w:val = 'Heading3' or @w:val = 'Heading4' or @w:val = 'Heading5' or @w:val = 'Heading6' or @w:val = 'Heading7' or @w:val = 'BiblioTitle']]">
	
		<xsl:variable name="text">
			<xsl:apply-templates/>
		</xsl:variable>
	
		<xsl:if test="$text = 'Normative references' or w:pPr/w:pStyle/@w:val = 'BiblioTitle'">
			<xsl:text>[bibliography]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		
		<xsl:variable name="level_" select="substring-after(w:pPr/w:pStyle/@w:val, 'Heading')"/>
		
		<xsl:variable name="level">
			<xsl:choose>
				<xsl:when test="$level_ = ''">1</xsl:when>
				<xsl:otherwise><xsl:value-of select="number($level_)"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="$level &lt;= 5">
				<xsl:call-template name="repeat">
					<xsl:with-param name="count" select="$level + 1"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise> <!-- more 5 -->
				<!-- [level=n] -->
				<xsl:text>[level=</xsl:text><xsl:value-of select="$level"/><xsl:text>]</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:call-template name="repeat">
					<xsl:with-param name="count" select="6"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:text> </xsl:text>
		
		<xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new(normalize-space($text)),'^(\d(\.\d)*)*(.*)','$3'))"/> <!-- remove digits (or digit(.digit)+) at start -->
		
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>

	<!-- ============================= -->
	<!-- Cover page data processing -->
	<!-- ============================= -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzCover'][1]" priority="2">
		<!-- parsing strings -->
		
		<!-- Example: Reference number of working document: 17301 -->
		<xsl:variable name="regex_docnumber">^Reference number of working document:(\s|\h)*(.*)</xsl:variable>
		
		<!-- Example: Date: 2016-05-01 -->
		<xsl:variable name="regex_revdate">^Date:(\s|\h)*(.*)</xsl:variable> <!-- \d{4}-\d{2}-\d{2}$ -->
		
		<!-- Example: Committee identification: ISO/TC 34/SC 4  -->
		<xsl:variable name="regex_committee">^Committee identification:(\s|\h)*(.*)</xsl:variable>
		<xsl:variable name="regex_iso_tc">^ISO(/IEC)?(\s|\h|/)+(.*)</xsl:variable>
		
		<!-- Example: Secretariat: SAC  -->
		<xsl:variable name="regex_secretariat">^Secretariat:(\s|\h)*(.*)</xsl:variable>
		
		
		<xsl:variable name="regex_iso_tc2">^ISO(/IEC)?(\s|\h|/)+(TC(\s|\h)+\d+/WG(\s|\h)+\d+)$</xsl:variable>
		
		<xsl:variable name="regex_tc_keyvalue">^(.+)(\s|\h)+(.+)$</xsl:variable>
		<xsl:variable name="regex_iso_number">^ISO(/IEC)?(\s|\h)+(\d+.*)</xsl:variable>
		
		
		<xsl:variable name="bibdata_items_">
			<xsl:for-each select="//w:p[w:pPr/w:pStyle/@w:val = 'zzCover']">
				<xsl:variable name="text">
					<xsl:apply-templates select=".//w:t"/> <!--  | w:ins/w:r/w:t -->
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($regex_docnumber, normalize-space(.)) = 'true'">
						<item name="docnumber"><xsl:value-of select="java:replaceAll(java:java.lang.String.new($text),$regex_docnumber,'$2')"/></item>
					</xsl:when>
					<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($regex_revdate, normalize-space(.)) = 'true'">
						<item name="revdate"><xsl:value-of select="java:replaceAll(java:java.lang.String.new($text),$regex_revdate,'$2')"/></item>
					</xsl:when>
					<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($regex_committee, normalize-space(.)) = 'true'">
						
						<xsl:variable name="tc" select="java:replaceAll(java:java.lang.String.new(.),$regex_iso_tc,'$3')"/>
						<!-- tc=<xsl:value-of select="$tc"/> -->
						<xsl:variable name="tc_parts">
							<xsl:call-template name="split">
								<xsl:with-param name="pText" select="$tc"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:variable name="tc_components">
							<xsl:for-each select="xalan:nodeset($tc_parts)//item">
								<item name="tc">
									<xsl:attribute name="key">
										<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),$regex_tc_keyvalue,'$1')"/>
									</xsl:attribute>
									<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),$regex_tc_keyvalue,'$3')"/>
								</item>
							</xsl:for-each>
						</xsl:variable>
						<xsl:for-each select="xalan:nodeset($tc_components)//item">
							<xsl:choose>
								<xsl:when test="@key = 'TC'">
									<item name="technical-committee-number"><xsl:value-of select="."/></item>
								</xsl:when>
								<xsl:when test="@key = 'SC'">
									<item name="subcommittee-number"><xsl:value-of select="."/></item>
								</xsl:when>
								<xsl:when test="@key = 'WG'">
									<item name="workgroup-type">WG</item>
									<item name="workgroup-number"><xsl:value-of select="."/></item>
								</xsl:when>
							</xsl:choose>
						</xsl:for-each>
						
						<!-- <item name="committee">
							<xsl:value-of select="java:replaceAll(java:java.lang.String.new($text),$regex_committee,'$2')"/>
						</item> -->
					</xsl:when>
					<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($regex_secretariat, normalize-space(.)) = 'true'">
						<item name="secretariat"><xsl:value-of select="java:replaceAll(java:java.lang.String.new($text),$regex_secretariat,'$2')"/></item>
					</xsl:when>
					
					<xsl:when test="starts-with(., 'Reference number of project')"><!-- skip --></xsl:when>
					
					<!-- <xsl:when test="java:org.metanorma.utils.RegExHelper.matches($regex_iso_tc2, normalize-space(.)) = 'true'">
						<xsl:variable name="tc" select="java:replaceAll(java:java.lang.String.new($text),$regex_iso_tc,'$2')"/>
						<xsl:variable name="tc_components">
							<xsl:call-template name="split">
								<xsl:with-param name="pText" select="$tc"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:for-each select="xalan:nodeset($tc_components)//item">
							<item name="tc">
								<xsl:attribute name="key">
									<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),$regex_tc_keyvalue,'$1')"/>
								</xsl:attribute>
								<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),$regex_tc_keyvalue,'$3')"/>
							</item>
						</xsl:for-each>
					</xsl:when> -->
					<!-- <xsl:when test="java:org.metanorma.utils.RegExHelper.matches($regex_iso_number, normalize-space(.)) = 'true'">
						<item name="docnumber"><xsl:value-of select="java:replaceAll(java:java.lang.String.new($text),$regex_iso_number,'$3')"/></item>
					</xsl:when> -->
					
					<xsl:otherwise>
						<xsl:if test="normalize-space($text) != ''">
							<xsl:variable name="lang">
								<xsl:choose>
									<xsl:when test="translate($text,'éàèùâêîôûç','') != $text">fr</xsl:when>
									<xsl:otherwise>en</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<xsl:variable name="title_parts">
								<xsl:call-template name="split">
									<xsl:with-param name="pText" select="$text"/>
									<xsl:with-param name="sep" select="'—'"/>
								</xsl:call-template>
							</xsl:variable>
							
							<xsl:for-each select="xalan:nodeset($title_parts)//item">
								<xsl:choose>
									<xsl:when test="position() = 1">
										<item name="title-intro-{$lang}"><xsl:value-of select="."/></item>
									</xsl:when>
									<xsl:when test="position() = 2">
										<item name="title-main-{$lang}"><xsl:value-of select="."/></item>
									</xsl:when>
									<xsl:when test="position() = 3">
										<item name="title-part-{$lang}">
											<xsl:variable name="regex_title_part">(Part|Partie)(\s|\h)+(\d)+:(.*)</xsl:variable>
											<xsl:attribute name="number">
												<xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new(.), $regex_title_part, '$3'))"/>
											</xsl:attribute>
											<xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new(.), $regex_title_part, '$4'))"/>
										</item>
									</xsl:when>
									<xsl:otherwise> <!-- for any case -->
										<item name="title-main-{$lang}"><xsl:value-of select="."/></item>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>
							
							
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="bibdata_items" select="xalan:nodeset($bibdata_items_)"/>
		
		<redirect:write file="{$docfile}">
			
			<!-- DEBUG:
			<xsl:apply-templates select="$bibdata_items" mode="print_as_xml"/> -->
		
			<xsl:for-each select="$bibdata_items/item">

				<xsl:text>:</xsl:text><xsl:value-of select="@name"/><xsl:text>: </xsl:text>
				<xsl:value-of select="normalize-space(.)"/>
				<xsl:text>&#xa;</xsl:text>
				
				<xsl:if test="@name = 'docnumber'">
					<xsl:variable name="part_number" select="../item[starts-with(@name,'title-part-')]/@number"/>
					<xsl:if test="$part_number != ''">
						<xsl:text>:partnumber: </xsl:text>
						<xsl:value-of select="$part_number"/>
						<xsl:text>&#xa;</xsl:text>
					</xsl:if>
				</xsl:if>
				
				<xsl:if test="@name = 'revdate'">
					<xsl:text>:copyright-year: </xsl:text><xsl:value-of select="substring(.,1,4)"/>
					<xsl:text>&#xa;</xsl:text>
				</xsl:if>
				
			</xsl:for-each>
			
			<xsl:text>:mn-document-class: iso</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>:mn-output-extensions: xml,html,doc,pdf,rxl</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>:local-cache-only:</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>:data-uri-image:</xsl:text>
			<xsl:text>&#xa;</xsl:text>
			<xsl:text>:imagesdir: images</xsl:text>
			<xsl:text>&#xa;&#xa;</xsl:text>
		
		</redirect:write>
		
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzCover']"/>
	
	<!-- ============================= -->
	<!-- END Cover page data processing -->
	<!-- ============================= -->
	
	<!-- ============================= -->
	<!-- Ignore processing -->
	<!-- ============================= -->
	
	<!-- no need to output term's num (example '3.1') -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'TermNum']"/>
	
	<!-- skip copyright information text -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzCopyright']"/>
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzAddress']"/>
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzaddress']"/>
	
	<!-- skip 'Contents' title -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzContents']"/>
	
	
	<!-- skip ToC items text -->
	<xsl:template match="w:p[starts-with(w:pPr/w:pStyle/@w:val, 'TOC')]"/>
	
	
	<!-- ============================= -->
	<!-- END Ignore processing -->
	<!-- ============================= -->
	
	
	<!-- ============================= -->
	<!-- Terms processing -->
	<!-- ============================= -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'Terms']">
	
		<!-- determine level -->
		<xsl:variable name="term_num" select="ancestor::w:p[1]/preceding-sibling::w:p[w:pPr/w:pStyle/@w:val = 'TermNum']/w:r/w:t"/>
		<xsl:variable name="term_num_level" select="string-length($term_num) - string-length(translate($term_num, '.', ''))"/>
		<xsl:variable name="level">
			<xsl:choose>
				<xsl:when test="$term_num_level = 0">3</xsl:when>
				<xsl:otherwise><xsl:value-of select="$term_num_level + 2"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<!-- output: === -->
		<xsl:call-template name="repeat">
			<xsl:with-param name="count" select="$level"/>
		</xsl:call-template>
		<xsl:text> </xsl:text>
		
		<xsl:apply-templates/>
		
		<xsl:text>&#xa;</xsl:text>
		<xsl:if test="following-sibling::w:p[1][not(w:pPr/w:pStyle/@w:val = 'AltTerms' or w:pPr/w:pStyle/@w:val = 'DeprecatedTerms')]">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'AltTerms']">
		<xsl:text>alt:[</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:if test="following-sibling::w:p[1][not(w:pPr/w:pStyle/@w:val = 'AltTerms' or w:pPr/w:pStyle/@w:val = 'DeprecatedTerms')]">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'DeprecatedTerms']">
		<xsl:variable name="text">
			<xsl:apply-templates/>
		</xsl:variable>
		<xsl:text>deprecated:[</xsl:text>
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new($text),'^DEPRECATED:(\s|\h)+(.*)','$2')"/>
		<xsl:text>]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:if test="following-sibling::w:p[1][not(w:pPr/w:pStyle/@w:val = 'AltTerms' or w:pPr/w:pStyle/@w:val = 'DeprecatedTerms')]">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'Definition']">
		<xsl:variable name="text">
			<xsl:apply-templates />
		</xsl:variable>
		
		<xsl:variable name="regex_domain">^(&lt;(.*)&gt;)?(\s|\h)*(.*)</xsl:variable>
		
		<xsl:variable name="domain" select="normalize-space(java:replaceAll(java:java.lang.String.new($text), $regex_domain, '$2'))"/>
		
		<xsl:variable name="definition" select="java:replaceAll(java:java.lang.String.new($text), $regex_domain, '$4')"/>
		
		<xsl:if test="$domain != ''">
			<xsl:text>domain:[</xsl:text>
			<xsl:value-of select="$domain"/>
			<xsl:text>]</xsl:text>
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
		
		<xsl:value-of select="$definition"/>
		
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<!-- ============================= -->
	<!-- END Terms processing -->
	<!-- ============================= -->
	
	
	
	<!-- ============================= -->
	<!-- Note processing -->
	<!-- ============================= -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'note']"> <!--  or w:pPr/w:pStyle/@w:val = 'Figurenote' -->
		<xsl:text>NOTE: </xsl:text>
		<xsl:variable name="text">
			<xsl:apply-templates/>
		</xsl:variable>
		<xsl:variable name="note1" select="java:replaceAll(java:java.lang.String.new($text),'^Note(\s|\h)+(\d+)? to entry:(\s|\h)+(.*)','$4')"/>
		<xsl:variable name="note2" select="java:replaceAll(java:java.lang.String.new($note1),'^NOTE(\s|\h)+(\d+(\s|\h)+)?(.*)','$4')"/>
		
		<xsl:value-of select="$note2"/>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	<!-- ============================= -->
	<!-- End Note processing -->
	<!-- ============================= -->
	
	<!-- ============================= -->
	<!-- Example processing -->
	<!-- ============================= -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'Example']">
		<xsl:text>====</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:variable name="text">
			<xsl:apply-templates/>
		</xsl:variable>
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new($text),'^EXAMPLE(\s|\h)+(\d+(\s|\h)+)?(.*)','$4')"/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>====</xsl:text>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	<!-- ============================= -->
	<!-- End Example processing -->
	<!-- ============================= -->
	
	
	<!-- ============================= -->
	<!-- Term's source processing -->
	<!-- ============================= -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'Source']">
		<xsl:text>[.source]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&lt;&lt;</xsl:text>
		<xsl:variable name="source">
			<xsl:apply-templates/>
		</xsl:variable>
		<xsl:value-of select="normalize-space($source)"/>
		<xsl:if test="not(contains($source, '&gt;&gt;'))">
			<xsl:text>&gt;&gt;</xsl:text>
		</xsl:if>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<!-- <xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'Source']/w:r/w:t[text() = '[SOURCE: ']" priority="2"/> -->
	
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'Source']/w:r/w:t">
		<xsl:variable name="source_text_1" select="java:replaceAll(java:java.lang.String.new(.),'^\[SOURCE:(\s|\h)+(.*)','$2')"/>
		<xsl:variable name="source_text_2" select="java:replaceAll(java:java.lang.String.new($source_text_1),'(.*)\]$','$1')"/>
		<!-- Example: ISO 19103:2015, 4.27, modified — Examples and notes to entry have been added. -->
		<xsl:variable name="source_text_3" select="java:replaceAll(java:java.lang.String.new($source_text_2),', modified — ','&gt;&gt;, ')"/> 
		<xsl:value-of select="$source_text_3"/>
	</xsl:template>
	
	<!-- ============================= -->
	<!-- END Term's source processing -->
	<!-- ============================= -->
	
	
	<!-- ============================= -->
	<!-- Table processing -->
	<!-- ============================= -->
	
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'Tabletitle' or w:pPr/w:pStyle/@w:val = 'tabletitle' or w:pPr/w:pStyle/@w:val = 'AnnexTableTitle']">
		<xsl:text>.</xsl:text>
		
		<xsl:variable name="title">
			<xsl:apply-templates/>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="contains($title, $em_dash)">
				<xsl:value-of select="normalize-space(substring-after($title, $em_dash))"/>
			</xsl:when>
			<xsl:when test="contains($title, $en_dash)">
				<xsl:value-of select="normalize-space(substring-after($title, $en_dash))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$title"/>
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="w:tbl">
	
		<!-- Step 1: convert docx table to HTML-like table -->
		<xsl:variable name="table_">
			<table>
				<xsl:apply-templates/>
			</table>
		</xsl:variable>
		<xsl:variable name="table" select="xalan:nodeset($table_)"/>
		
		<!-- DEBUG=<xsl:apply-templates select="$table" mode="print_as_xml"/> -->
		
		<!-- process HTML-like table -->
		<xsl:choose>
			<!-- no border, paragraph is 'dl' item and columns count = 2 -->
			<xsl:when test="count($table//td[@border = '1']) = 0 and $table//p/@dl = 'true' and count($table/table/colgroup/col) = 2">
				<xsl:apply-templates select="$table/node()" mode="dl"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- DEBUG=<xsl:apply-templates select="$table" mode="print_as_xml"/> -->
				<xsl:apply-templates select="$table/node()" />
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	<!-- ===================== -->
	<!-- create HTML-like table -->
	<!-- ===================== -->
	<xsl:template match="w:tblGrid">
		<colgroup>
			<xsl:apply-templates/>
		</colgroup>
	</xsl:template>
	
	<xsl:template match="w:gridCol">
		<col><xsl:value-of select="@w:w"/></col>
	</xsl:template>
	
	<xsl:template match="w:tr">
		<tr>
			<xsl:apply-templates/>
		</tr>
	</xsl:template>
	
	<xsl:template match="w:tc">
		<td>
			<xsl:if test="w:tcPr/w:tcBorders">
				<xsl:attribute name="border">1</xsl:attribute>
			</xsl:if>
			<xsl:if test="w:tcPr/w:gridSpan">
				<xsl:attribute name="colspan"><xsl:value-of select="w:tcPr/w:gridSpan/@w:val"/></xsl:attribute>
			</xsl:if>
			
			<xsl:if test="w:tcPr/w:vMerge/@w:val = 'restart'">
				<xsl:variable name="curr_row_number" select="count(ancestor::w:tr[1]/preceding-sibling::w:tr) + 1"/>
				<xsl:variable name="next_restart_row_number_" select="count(ancestor::w:tr[1]/following-sibling::w:tr[w:tc/w:tcPr/w:vMerge/@w:val = 'restart']/preceding-sibling::w:tr) + 1"/>
				<xsl:variable name="next_restart_row_number">
					<xsl:choose>
						<xsl:when test="$next_restart_row_number_ = '1'">
							<xsl:value-of select="count(ancestor::w:tr[1]/following-sibling::w:tr/preceding-sibling::w:tr) + 2"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$next_restart_row_number_"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				
				<xsl:attribute name="curr_row_number"><xsl:value-of select="$curr_row_number"/></xsl:attribute>
				<xsl:attribute name="next_restart_row_number"><xsl:value-of select="$next_restart_row_number"/></xsl:attribute>
				<xsl:attribute name="rowspan"><xsl:value-of select="$next_restart_row_number - $curr_row_number"/></xsl:attribute>
			</xsl:if>
			
			<xsl:apply-templates/>
		</td>
	</xsl:template>
	
	<xsl:template match="w:tc/w:p">
		<p>
			<xsl:if test="w:pPr/w:pStyle/@w:val = 'Tablebody0'">
				<!-- definition list item -->
				<xsl:attribute name="dl">true</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
		</p>
	</xsl:template>
	<!-- ===================== -->
	<!-- END create HTML-like table -->
	<!-- ===================== -->
	
	
	<xsl:template match="table">
		
		<xsl:call-template name="insertTableProperties"/>
		
		<xsl:call-template name="insertTableSeparator"/>
		
		<xsl:text>===</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		
		<xsl:apply-templates />
		
		<xsl:text>&#xa;</xsl:text>
		
		<xsl:call-template name="insertTableSeparator"/>
		<xsl:text>===</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		
	</xsl:template>
	
	<xsl:template name="insertTableProperties">
		<xsl:text>[</xsl:text>
		<xsl:text>cols="</xsl:text>
		<xsl:variable name="cols-count" select="count(colgroup/col)"/>
		<xsl:choose>
			<xsl:when test="$cols-count = 1">1</xsl:when> <!-- cols="1" -->
			<xsl:otherwise>
				<xsl:for-each select="colgroup/col">
					<xsl:value-of select="."/>
					<xsl:if test="position() != last()">,</xsl:if>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>"</xsl:text>
		
		<xsl:text>]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
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
	
	<xsl:template match="col"/>
	
	<xsl:template match="tr">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="td">
		<xsl:call-template name="spanProcessing"/>		
		<xsl:call-template name="alignmentProcessing"/>
		<xsl:call-template name="complexFormatProcessing"/>
		<xsl:call-template name="insertCellSeparator"/>
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
		<xsl:if test=".//graphic or .//inline-graphic or .//list or .//def-list or
			.//named-content[@content-type = 'ace-tag'][contains(@specific-use, '_start') or contains(@specific-use, '_end')] or
			.//styled-content[@style = 'addition' or @style-type = 'addition'] or
			.//styled-content[@style = 'text-alignment: center']">a</xsl:if> <!-- AsciiDoc prefix before table cell -->
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
		<!-- <xsl:text>&#xa;</xsl:text> -->
	</xsl:template>
	
	<!-- ============================= -->
	<!-- END Table processing -->
	<!-- ============================= -->
	
	<!-- ============================= -->
	<!-- Definition list processing -->
	<!-- ============================= -->
	<xsl:template match="/" mode="dl">
		<xsl:apply-templates mode="dl"/>
	</xsl:template>
	
	<xsl:template match="table" mode="dl">
		<xsl:apply-templates select="tr" mode="dl"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="tr" mode="dl">
		<xsl:apply-templates select="td[1]" mode="dl"/>
		<xsl:text>:: </xsl:text>
		<xsl:apply-templates select="td[2]" mode="dl"/>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="td" mode="dl">
		<xsl:apply-templates mode="dl"/>
	</xsl:template>
	
	<xsl:template match="td/p" mode="dl">
		<xsl:apply-templates />
	</xsl:template>
	<!-- ============================= -->
	<!-- END Definition list processing -->
	<!-- ============================= -->
		
	
	<!-- ============================= -->
	<!-- lists processing -->
	<!-- ============================= -->
	
	<!-- Unordered list (ul) -->
	<xsl:template match="w:p[starts-with(w:pPr/w:pStyle/@w:val, 'ListContinue')]">
		<xsl:variable name="level_" select="java:replaceAll(java:java.lang.String.new(w:pPr/w:pStyle/@w:val),'ListContinue(.*)','$1')"/>
		<xsl:variable name="level">
			<xsl:choose>
				<xsl:when test="$level_ = ''">1</xsl:when>
				<xsl:otherwise><xsl:value-of select="$level_"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="text">
			<xsl:apply-templates/>
		</xsl:variable>
		
		<xsl:variable name="listitem_label">
			<xsl:choose>
				<xsl:when test="(.//*[self::w:t or self::w:delText or self::w:insText])[1] = $em_dash">.</xsl:when> <!-- unordered list (ul) -->
				<xsl:otherwise>*</xsl:otherwise> <!-- ordered list (ol) -->
			</xsl:choose>
		</xsl:variable>
		
		<xsl:if test="normalize-space($text) != ''">
			<!-- <xsl:text>DEBUG level=</xsl:text><xsl:value-of select="$level"/><xsl:text>&#xa;</xsl:text> -->
			
			<xsl:call-template name="repeat">
				<xsl:with-param name="char" select="'.'"/>
				<xsl:with-param name="count" select="$level"/>
			</xsl:call-template>
			<!-- <xsl:text> </xsl:text> -->
			
			<xsl:value-of select="$text"/>
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
	</xsl:template> <!-- ul -->
	

	<!-- Ordered list (ol) -->
	<xsl:template match="w:p[starts-with(w:pPr/w:pStyle/@w:val, 'ListNumber')]">
		<xsl:variable name="level_" select="java:replaceAll(java:java.lang.String.new(w:pPr/w:pStyle/@w:val),'ListNumber(.*)','$1')"/>
		<xsl:variable name="level">
			<xsl:choose>
				<xsl:when test="$level_ = ''">1</xsl:when>
				<xsl:otherwise><xsl:value-of select="$level_"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="text">
			<xsl:apply-templates/>
		</xsl:variable>
		
		<xsl:if test="normalize-space($text) != ''">
			<!-- <xsl:text>DEBUG level=</xsl:text><xsl:value-of select="$level"/><xsl:text>&#xa;</xsl:text> -->
			<xsl:call-template name="repeat">
				<xsl:with-param name="char" select="'*'"/>
				<xsl:with-param name="count" select="$level"/>
			</xsl:call-template>
			<!-- <xsl:text> </xsl:text> -->
			
			<xsl:value-of select="$text"/>
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
	</xsl:template> <!-- ol -->
	
	<!-- text in list: list item label or body -->
	<xsl:template match="w:p[starts-with(w:pPr/w:pStyle/@w:val, 'ListContinue') or starts-with(w:pPr/w:pStyle/@w:val, 'ListNumber')]//*[self::w:t or self::w:delText or self::w:insText]">
		<xsl:choose>
			<xsl:when test="ancestor::w:r/following-sibling::w:r[1][w:tab]"><!-- skip list item label --></xsl:when>
			<xsl:otherwise>
				<!-- process list item body -->
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
		
	<!-- ============================= -->
	<!-- END lists processing -->
	<!-- ============================= -->
		
	<!-- ============================= -->
	<!-- Figure processing -->
	<!-- ============================= -->
	
	<xsl:template match="w:p[w:r/w:drawing]">
		
		<xsl:apply-templates select="following-sibling::w:p[w:pPr/w:pStyle/@w:val = 'FigureTitle' or w:pPr/w:pStyle/@w:val = 'AnnexFigureTitle'][1]">
			<xsl:with-param name="process">true</xsl:with-param>
		</xsl:apply-templates>
		
		<xsl:apply-templates />
		
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	
	
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'FigureTitle' or w:pPr/w:pStyle/@w:val = 'AnnexFigureTitle']">
		<xsl:param name="process">false</xsl:param>
		<xsl:if test="$process = 'true'">
			<xsl:text>.</xsl:text>
			<xsl:variable name="title">
				<xsl:apply-templates />
			</xsl:variable>
			<!-- remove 'Figure N —' -->
			<xsl:choose>
				<xsl:when test="contains($title, $em_dash)">
					<xsl:value-of select="normalize-space(substring-after($title, $em_dash))"/>
				</xsl:when>
				<xsl:when test="contains($title, $en_dash)">
					<xsl:value-of select="normalize-space(substring-after($title, $en_dash))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$title"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="pic:blipFill/a:blip">
		<!-- Example: r:embed="rId205" -->
		<xsl:variable name="rId" select="@r:embed"/>
		<!-- Example: <Relationship Id="rId205" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image1.png"/> -->
		<xsl:variable name="target" select="$rels_xml//rels:Relationship[@Id = $rId]/@Target"/>
		
		<xsl:variable name="filename" select="java:replaceAll(java:java.lang.String.new($target),'.*/(.*)$','$1')"/>
		<xsl:text>image::</xsl:text><xsl:value-of select="$filename"/><xsl:text>[]</xsl:text>
		<xsl:text>&#xa;&#xa;</xsl:text>
		
	</xsl:template>
		
	<!-- ============================= -->
	<!-- END Figure processing -->
	<!-- ============================= -->
	
	<!-- ============================= -->
	<!-- Formula processing -->
	<!-- ============================= -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'Formula']/m:oMath">
		
		<!-- last 'w:r' is formula number -->
		<!-- Example:
		<w:r>
			<w:rPr>
				<w:lang w:eastAsia="en-US"/>
			</w:rPr>
			<w:tab/>
			<w:t>(A.1)</w:t>
		</w:r>
		-->
		<xsl:variable name="numbered" select="normalize-space(../w:r[last()] != '' and translate(../w:r[last()],'().0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ','') = '')"/>
		
		<xsl:text>[stem</xsl:text>
		<xsl:if test="$numbered = 'false'">
			<xsl:text>%unnumbered</xsl:text>
		</xsl:if>
		<xsl:text>]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>++++</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:variable name="text">
			<xsl:apply-templates />
		</xsl:variable>
		<xsl:value-of select="$text"/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>++++</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'Formula']/w:r[last()]">
		<!-- if number for formula -->
		<xsl:variable name="numbered" select="normalize-space(. != '' and translate(.,'().0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ','') = '')"/>
		<xsl:if test="$numbered = 'false'">
			<xsl:apply-templates />
		</xsl:if>
	</xsl:template>
	
	<!-- inlined math -->
	<xsl:template match="m:oMath[not(ancestor::w:p[w:pPr/w:pStyle/@w:val = 'Formula'])]">
	
		<xsl:variable name="text">
			<xsl:apply-templates />
		</xsl:variable>
		<xsl:text>stem:[</xsl:text>
		<xsl:value-of select="$text"/>
		<xsl:text>]</xsl:text>
		
		<!-- add space after stem -->
		<xsl:if test="java:org.metanorma.utils.RegExHelper.matches('.*(\s|\h)$', $text) = 'true'"><xsl:text> </xsl:text></xsl:if>
		
	</xsl:template>
	
	<xsl:template match="m:oMathPara">
		<xsl:choose>
			<xsl:when test="ancestor::w:tc">
				<xsl:if test="preceding-sibling::*[not(self::w:pPr)]">
					<xsl:text> +</xsl:text>
					<xsl:text>&#xa;</xsl:text>
				</xsl:if>
				<xsl:apply-templates/>
				<xsl:if test="following-sibling::*">
					<xsl:text> +</xsl:text>
					<xsl:text>&#xa;</xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>&#xa;</xsl:text>
				<xsl:apply-templates/>
				<xsl:text>&#xa;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- ============================= -->
	<!-- END Formula processing -->
	<!-- ============================= -->
	
	<!-- ============================= -->
	<!-- Bibliography entry processing -->
	<!-- ============================= -->
	
	<!-- style RefNorm is using for Normative References,
		style BiblioEntry0 is using for bibliography -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'BiblioEntry0' or w:pPr/w:pStyle/@w:val = 'RefNorm']">
		
		<xsl:variable name="bib_style" select="w:pPr/w:pStyle/@w:val"/>
		
		<!-- Example: * [[[ISO712,ISO 712]]], _Cereals and cereal products - Determination of moisture content - Reference method_ -->
		
		<xsl:variable name="bibitem_">
			<xsl:apply-templates />
		</xsl:variable>
		<xsl:variable name="bibitem" select="xalan:nodeset($bibitem_)"/>
		
		<!-- DEBUG:
		<xsl:apply-templates select="xalan:nodeset($bibitem_)" mode="print_as_xml"/>
		<xsl:text>&#xa;</xsl:text> -->
		
		
		<xsl:if test="normalize-space($bibitem) != ''">
			<xsl:text>* </xsl:text>
			
			<xsl:choose>
				<xsl:when test="$bibitem/stdpublisher or $bibitem/stddocNumber"> <!-- if 'standard' bibitem -->
					
					<xsl:variable name="id_">
						<xsl:for-each select="$bibitem/node()[not(local-name() = 'bibnumber' or local-name() = 'stddocTitle')]">
							<xsl:value-of select="translate(.,'&#xa0;[],',' ')"/> <!-- replace a0 to space, remove [, ] and comman -->
						</xsl:for-each>
					</xsl:variable>
					<xsl:variable name="id" select="translate(normalize-space($id_),':/ ','___')"/> <!-- replace :,/ and space to underscore _ -->
				
					<xsl:variable name="reference_text">
						<xsl:for-each select="$bibitem/node()[not(local-name() = 'bibnumber' or local-name() = 'stddocTitle')]">
							<xsl:choose>
								<xsl:when test="normalize-space() = '[' or normalize-space() = ']' or normalize-space() = ','"><!-- skip --></xsl:when>
								<xsl:otherwise><xsl:value-of select="translate(.,'&#xa0;', ' ')"/></xsl:otherwise>
							</xsl:choose>
						</xsl:for-each>
					</xsl:variable>
				
					<xsl:text>[[[</xsl:text>
						<xsl:value-of select="$id"/>
						<xsl:text>,</xsl:text>
						<xsl:value-of select="$reference_text"/>
					<xsl:text>]]]</xsl:text>
					<xsl:for-each select="$bibitem/stddocTitle[1]"> <!-- standard's title -->
						<xsl:text>, </xsl:text>
						<xsl:value-of select="."/>
						<xsl:for-each select="following-sibling::node()">
							<xsl:value-of select="."/>
						</xsl:for-each>
					</xsl:for-each>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>[[[</xsl:text>
						<xsl:choose>
							<xsl:when test="$bib_style = 'BiblioEntry0'"><xsl:text>bibref</xsl:text></xsl:when>
							<xsl:otherwise>ref</xsl:otherwise>
						</xsl:choose>
						
						<xsl:choose>
							<xsl:when test="$bibitem/bibnumber">
								<xsl:value-of select="$bibitem/bibnumber"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="$bib_style = 'BiblioEntry0'">
										<xsl:number count="w:p[w:pPr/w:pStyle/@w:val = 'BiblioEntry0']"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:number count="w:p[w:pPr/w:pStyle/@w:val = 'RefNorm']"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					<xsl:text>]]], </xsl:text>
					<xsl:variable name="text">
						<xsl:for-each select="$bibitem/node()[not(self::bibnumber)]">
							<xsl:value-of select="."/>
						</xsl:for-each>
					</xsl:variable>
					<!-- remove [] at start -->
					<xsl:value-of select="java:replaceAll(java:java.lang.String.new($text),'^\[\](\s|\h)*(.*)$','$2')"/>
				</xsl:otherwise>
			</xsl:choose>
			
		
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'BiblioEntry0' or w:pPr/w:pStyle/@w:val = 'RefNorm']//w:r[w:rPr/w:rStyle]/*[self::w:t or self::w:insText or self::w:delText]">
		<xsl:variable name="style" select="ancestor::w:r[1]/w:rPr/w:rStyle/@w:val"/>
		<xsl:element name="{$style}">
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<!-- ============================= -->
	<!-- END Bibliography entry processing -->
	<!-- ============================= -->
	
	
	<!-- ============================= -->
	<!-- Annex processing -->
	<!-- ============================= -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'ANNEX']">
		<!-- [[AnnexA]] -->
		<!-- Example [appendix,obligation=normative] -->
		
		<!-- <xsl:variable name="id" select="translate((.//w:t)[1],' ','')"/> -->
		<xsl:variable name="id" select="translate(w:bookmarkStart/@w:name,' ','')"/>
		<xsl:text>[[</xsl:text>
		<xsl:value-of select="$id"/>
		<xsl:text>]]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		
		<xsl:variable name="obligation_">
			<xsl:choose>
				<xsl:when test=".//w:t[translate(text(), '()','') = 'normative']">normative</xsl:when>
				<xsl:when test=".//w:t[translate(text(), '()','') = 'informative']">informative</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="obligation">
			<xsl:if test="normalize-space($obligation_) != ''">
				<xsl:text>,obligation=</xsl:text><xsl:value-of select="$obligation_"/>
			</xsl:if>
		</xsl:variable>
		
		<xsl:text>[appendix</xsl:text><xsl:value-of select="$obligation"/><xsl:text>]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		
		<xsl:text>== </xsl:text>
		<xsl:apply-templates select="(.//w:t)[position() &gt; 2]"/>
		
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		
	</xsl:template>
	
	
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'a2' or @w:val = 'a3' or @w:val = 'a4' or @w:val = 'a5' or @w:val = 'a6']]">
		<xsl:variable name="level" select="substring-after(w:pPr/w:pStyle/@w:val, 'a')"/>
	
		<xsl:call-template name="repeat">
			<xsl:with-param name="count" select="$level + 1"/>
		</xsl:call-template>
		<xsl:text> </xsl:text>
		
		<xsl:apply-templates/>
		
		<xsl:text>&#xa;&#xa;</xsl:text>
	
	</xsl:template>
	
	
	<!-- ============================= -->
	<!-- END Annex processing -->
	<!-- ============================= -->
	
	
	<xsl:template match="w:t">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="w:tab[not(parent::w:tabs)]">
		<xsl:text> </xsl:text>
	</xsl:template>
	
	<xsl:template match="w:noBreakHyphen">
		<xsl:text>-</xsl:text>
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