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

	<!-- input xml file 'word\comments.xml' -->
	<!-- xml with comments -->
	<xsl:param name="comments_file"/>
	<!-- xml with comments (comments.xml) -->
	<xsl:param name="comments"/>
	
	<!-- input xml file 'word\footnotes.xml' -->
	<!-- xml with footnotes -->
	<xsl:param name="footnotes_file"/>
	<!-- xml with footenotes (footnotes.xml) -->
	<xsl:param name="footnotes"/>
	
	<!-- input xml file 'word\styles.xml' -->
	<!-- xml with styles -->
	<xsl:param name="styles_file"/>
	<!-- xml with styles (styles.xml) -->
	<xsl:param name="styles"/>

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

	<xsl:variable name="comments_xml_">
		<xsl:choose>
			<xsl:when test="$comments_file != ''">
				<xsl:copy-of select="document($comments_file)"/> 
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$comments"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="comments_xml" select="xalan:nodeset($comments_xml_)"/>

	<xsl:variable name="footnotes_xml_">
		<xsl:choose>
			<xsl:when test="$footnotes_file != ''">
				<xsl:copy-of select="document($footnotes_file)"/> 
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$footnotes"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="footnotes_xml" select="xalan:nodeset($footnotes_xml_)"/>
	
	<xsl:variable name="styles_xml_">
		<xsl:choose>
			<xsl:when test="$styles_file != ''">
				<xsl:copy-of select="document($styles_file)"/> 
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$styles"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="styles_xml" select="xalan:nodeset($styles_xml_)"/>

	<xsl:variable name="bookmarks_">
		<xsl:for-each select=".//w:bookmarkStart">
			<bookmark name="{@w:name}" style="{preceding-sibling::w:pPr/w:pStyle/@w:val}"/>
		</xsl:for-each>
	</xsl:variable>
	<xsl:variable name="bookmarks" select="xalan:nodeset($bookmarks_)"/>
	
	<xsl:variable name="hyperlinks_">
		<xsl:for-each select=".//w:hyperlink">
			<hyperlink anchor="{@w:anchor}" style="{$bookmarks/bookmark[@name = current()/@w:anchor]/@style}"/>
		</xsl:for-each>
	</xsl:variable>
	<xsl:variable name="hyperlinks" select="xalan:nodeset($hyperlinks_)"/>

	<!-- <xsl:variable name="anchors_">
		<xsl:for-each select="//@w:anchor">
			
		</xsl:for-each>
	</xsl:variable>
	<xsl:variable name="anchors" select="xalan:nodeset($anchors_)"/> -->

	<xsl:variable name="taskCopyImagesFilename" select="concat($outpath, $pathSeparator, 'task.copyImages.adoc')"/>


	<!-- for OMML to MathML conversion -->
	<xsl:include href="OMML2MML.XSL"/>

	<!-- .docx zip content:
	
		./word/document.xml - document body (entry point for this template)
		./word/_rels/document.xml.rels - relationships
		
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
		
		<redirect:write file="{$docfile}">
			<xsl:call-template name="insertTaskImageList"/>
		</redirect:write>
		
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
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'BiblioEntry0' or @w:val = 'BiblioEntry' or @w:val = 'RefNorm']]/w:del" mode="update1"/>
	
	<!-- remove deleted 'obligation' for Annex -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'ANNEX']/w:del[contains(., 'normative') or contains(., 'informative')]" mode="update1"/>
	
	<!-- remove Standard title before Scope -->
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'zzSTDTitle' or @w:val = 'zzSTDTitle1' or @w:val = 'zzSTDTitle2']]" mode="update1"/>
	
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
	
	<xsl:template match="w:p | p">
	
		<xsl:variable name="text">
			<xsl:apply-templates/>
		</xsl:variable>
		
		<xsl:value-of select="$text"/>
		
		<xsl:if test="normalize-space($text) != ''">
			<xsl:text>&#xa;</xsl:text>
			
			<xsl:if test="following-sibling::*[local-name() = 'p']">
				<xsl:text>&#xa;</xsl:text>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	
	
	<xsl:template match="w:pPr">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="w:jc[@w:val = 'left'][not(ancestor::w:tc)]">
		<xsl:text>[align=left]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
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
		note
		Note
		Noteindent
		Noteindent2
		Notecontinued
		Noteindentcontinued
		Noteindent2continued
		Example
		Exampleindent
		Figureexample
		Examplecontinued
		Exampleindentcontinued
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
		Figuretitle
		Figuretitle0
		AltTerms
		DeprecatedTerms
		Definition
		Formula
		tabletitle
		AdmittedTerm
		Code
		Code-
		Code- -
		BiblioEntry0
		BiblioEntry
		figure
		tablefootnote
		Tableheader
		Tablebody
		TableISO
		FigureGraphic
		BodyTextindent1
		Hyperlink
		ISOCode
		ISOCodebold
		ISOCodeitalic
		addition
		deletion
		dl
		figdl
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
	
		<xsl:call-template name="setId"/>
	
		<xsl:variable name="text">
			<xsl:apply-templates/>
		</xsl:variable>
		
		<xsl:if test="$text = 'Normative references' or
			java:org.metanorma.utils.RegExHelper.matches('^\d+(\s|\h)+Normative references$', normalize-space($text)) = 'true' or 
			w:pPr/w:pStyle/@w:val = 'BiblioTitle'">
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
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzCover'][1] | w:body/w:p[1][normalize-space(w:pPr/w:pStyle/@w:val) = '']" priority="2"> <!-- second template match for ISO simple template -->
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
		
		<xsl:variable name="regex_edition">^(.*)(\s|\h)+edition$</xsl:variable>
		
		<!-- for ISO DIS template -->
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
			</xsl:for-each> <!-- //w:p[w:pPr/w:pStyle/@w:val = 'zzCover'] -->
			
			<!-- for ISO Simple template -->
			<xsl:if test="//w:body/w:p[1][normalize-space(w:pPr/w:pStyle/@w:val) = '']">
				<xsl:for-each select="//w:body/w:p[following-sibling::w:p[w:pPr/w:pStyle/@w:val = 'zzCopyright']]">
					<xsl:variable name="text">
						<xsl:apply-templates select=".//w:t"/> <!--  | w:ins/w:r/w:t -->
					</xsl:variable>
					
					<xsl:choose>
						<xsl:when test="position() = 1">
							<item name="docnumber"><xsl:value-of select="."/></item>
						</xsl:when>
						<xsl:when test="position() = 2">
							<item name="partnumber"><xsl:value-of select="substring-after(., '-')"/></item>
						</xsl:when>
						
						<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($regex_iso_tc, normalize-space($text)) = 'true'">
							<xsl:variable name="tc" select="java:replaceAll(java:java.lang.String.new(.),$regex_iso_tc,'$3')"/>
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
						</xsl:when> <!-- regex_iso_tc -->
						
						<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($regex_secretariat, normalize-space($text)) = 'true'">
							<item name="secretariat"><xsl:value-of select="java:replaceAll(java:java.lang.String.new($text),$regex_secretariat,'$2')"/></item>
						</xsl:when>
						
						<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($regex_edition, normalize-space($text)) = 'true'">
							<xsl:variable name="edition" select="java:replaceAll(java:java.lang.String.new($text),$regex_edition,'$1')"/>
							<item name="edition">
								<xsl:choose>
									<xsl:when test="$edition = 'First'">1</xsl:when>
									<xsl:when test="$edition = 'Second'">2</xsl:when>
									<xsl:when test="$edition = 'Third'">3</xsl:when>
									<xsl:when test="$edition = 'Fourth'">4</xsl:when>
									<xsl:when test="$edition = 'Fifth'">5</xsl:when>
									<xsl:when test="$edition = 'Sixth'">6</xsl:when>
									<xsl:when test="$edition = 'Seventh'">7</xsl:when>
									<xsl:when test="$edition = 'Eighth'">8</xsl:when>
									<xsl:when test="$edition = 'Nineth'">9</xsl:when>
									<xsl:when test="$edition = 'Tenth'">10</xsl:when>
									<!-- to do: word to digit -->
								</xsl:choose>
							</item>
						</xsl:when>
						
						<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($regex_revdate, normalize-space(.)) = 'true'">
							<item name="revdate"><xsl:value-of select="java:replaceAll(java:java.lang.String.new($text),$regex_revdate,'$2')"/></item>
						</xsl:when>
						
						<xsl:otherwise>
							<xsl:apply-templates />
						</xsl:otherwise>
						
					</xsl:choose>
					
				</xsl:for-each> <!-- for ISO Simple template -->
			</xsl:if>
			
		</xsl:variable>
		<xsl:variable name="bibdata_items" select="xalan:nodeset($bibdata_items_)"/>
		
		<redirect:write file="{$docfile}">
			
			<!-- DEBUG:
			<xsl:apply-templates select="$bibdata_items" mode="print_as_xml"/> -->
			
			<xsl:for-each select="$bibdata_items/item">
			
				<xsl:choose>
					<xsl:when test="@name = 'title-intro-en' and preceding-sibling::item[@name = 'title-intro-en']">
						<xsl:text>:title-intro-fr: </xsl:text>
						<xsl:value-of select="normalize-space(.)"/>
						<xsl:text>&#xa;</xsl:text>
					</xsl:when>
					<xsl:when test="@name = 'title-main-en' and preceding-sibling::item[@name = 'title-main-en']">
						<xsl:text>:title-main-fr: </xsl:text>
						<xsl:value-of select="normalize-space(.)"/>
						<xsl:text>&#xa;</xsl:text>
					</xsl:when>
					<xsl:when test="@name = 'title-part-en' and preceding-sibling::item[@name = 'title-part-en']">
						<xsl:text>:title-part-fr: </xsl:text>
						<xsl:value-of select="normalize-space(.)"/>
						<xsl:text>&#xa;</xsl:text>
					</xsl:when>
					
					<xsl:otherwise>			
					
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
					</xsl:otherwise>
				</xsl:choose>
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
		
			<!-- <xsl:apply-templates select="$hyperlinks" mode="print_as_xml"/> -->
		
		</redirect:write>
		
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzCover']"/>
	
	<xsl:template match="w:r[w:rPr/w:rStyle[@w:val = 'title2' or @w:val = 'subtitle'  or @w:val = 'part']]">
		<xsl:variable name="style" select="w:rPr/w:rStyle/@w:val"/>
		<xsl:variable name="title_" select="."/>
		<xsl:variable name="title" select="java:replaceAll(java:java.lang.String.new($title_),' — $','')"/>
		<item>
			
			<xsl:variable name="title_lang">
				<xsl:choose>
					<xsl:when test="translate($title,'éàèùâêîôûç','') != $title">fr</xsl:when>
					<xsl:otherwise>en</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			
			<xsl:attribute name="name">
				<xsl:choose>
					<xsl:when test="$style = 'title2'">title-intro</xsl:when>
					<xsl:when test="$style = 'subtitle'">title-main</xsl:when>
					<xsl:when test="$style = 'part'">title-part</xsl:when>
				</xsl:choose>
				<xsl:text>-</xsl:text><xsl:value-of select="$title_lang"/>
			</xsl:attribute>
			
			<xsl:value-of select="$title"/>
		</item>
	</xsl:template>
	
	<xsl:template match="w:r[w:rPr/w:rStyle[@w:val = 'partlabel']]"/>
	
	
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
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzcopyrighthdr']"/>
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzAddress']"/>
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzaddress']"/>
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzWarningHdr']"/>
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzwarning']"/>
	
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
		<xsl:if test="following-sibling::w:p[1][not(w:pPr/w:pStyle[@w:val = 'AltTerms' or @w:val = 'AdmittedTerm' or @w:val = 'DeprecatedTerms'])]">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'AltTerms' or @w:val = 'AdmittedTerm']]">
		<xsl:text>alt:[</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:if test="following-sibling::w:p[1][not(w:pPr/w:pStyle[@w:val = 'AltTerms' or @w:val = 'AdmittedTerm' or @w:val = 'DeprecatedTerms'])]">
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
		<xsl:if test="following-sibling::w:p[1][not(w:pPr/w:pStyle[@w:val = 'AltTerms' or @w:val = 'AdmittedTerm' or @w:val = 'DeprecatedTerms'])]">
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
	
	<!-- process sequence 'paddy (3.1) from ...' -->
	
	<!-- remove '(':
		<w:r>
				<w:rPr>
					<w:lang w:eastAsia="en-US"/>
				</w:rPr>
				<w:t xml:space="preserve"> (</w:t>
			</w:r>
	-->
	<xsl:template match="w:r[normalize-space(w:t) = '('][preceding-sibling::*[self::w:r/w:rPr/w:i] and following-sibling::*[1][self::w:hyperlink]]"/>
	
	<!-- remove ')' after hyperlink -->
	<xsl:template match="w:r[starts-with(w:t, ')')][preceding-sibling::*[1][self::w:hyperlink] and preceding-sibling::*[2][normalize-space(w:t) = '('] and preceding-sibling::*[3][self::w:r/w:rPr/w:i]]/w:t">
		<xsl:value-of select="substring(., 2)"/>
	</xsl:template>
	
	<!-- enclose term name into 'term:[name]':
		<w:r>
			<w:rPr>
				<w:i/>
				<w:iCs/>
				<w:lang w:eastAsia="en-US"/>
			</w:rPr>
			<w:t>paddy</w:t>
		</w:r>
	-->
	<xsl:template match="w:r[w:rPr/w:i][following-sibling::*[1][self::w:r[normalize-space(w:t) = '(']]]	[following-sibling::*[2][self::w:hyperlink]]">
		<xsl:text>term:[</xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>]</xsl:text>
	</xsl:template>
	
	<!-- remove term's number:
	<w:hyperlink w:anchor="paddy" w:history="1">
				<w:r>
					<w:rPr>
						<w:rStyle w:val="Hyperlink"/>
						<w:lang w:eastAsia="en-US"/>
					</w:rPr>
					<w:t>3.1</w:t>
				</w:r>
			</w:hyperlink>
	-->
	<xsl:template match="w:hyperlink[preceding-sibling::*[1][self::w:r[normalize-space(w:t) = '(']]][preceding-sibling::*[2][self::w:r/w:rPr/w:i]]"/>
		
	
	<!-- ============================= -->
	<!-- END Terms processing -->
	<!-- ============================= -->
	
	
	
	<!-- ============================= -->
	<!-- Note processing -->
	<!-- ============================= -->
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'note' or @w:val = 'note1' or @w:val = 'Note' or @w:val = 'NoteIndent' or @w:val = 'NoteIndent2' or @w:val = 'Figurenote']]" name="note">
	
		
		<xsl:call-template name="setId"/>
		
		<xsl:choose>
			<xsl:when test="following-sibling::w:p[2][w:pPr/w:pStyle[@w:val = 'Notecontinued' or @w:val = 'Noteindentcontinued' or @w:val = 'Noteindent2continued']]">
				<xsl:text>[NOTE]</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>====</xsl:text>
				<xsl:text>&#xa;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>NOTE: </xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:variable name="text">
			<xsl:apply-templates/>
		</xsl:variable>
		<xsl:variable name="note1" select="java:replaceAll(java:java.lang.String.new($text),'^Note(\s|\h)+(\d+)? to entry:(\s|\h)+(.*)','$4')"/>
		<xsl:variable name="note2" select="java:replaceAll(java:java.lang.String.new($note1),'^NOTE(\s|\h)+(\d+(\s|\h)+)?(.*)','$4')"/>
		
		<xsl:value-of select="$note2"/>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'Notecontinued' or @w:val = 'Noteindentcontinued' or @w:val = 'Noteindent2continued']]">
		<xsl:variable name="text">
			<xsl:apply-templates/>
		</xsl:variable>
		<xsl:value-of select="$text"/>
		<xsl:text>====</xsl:text>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	<!-- ============================= -->
	<!-- End Note processing -->
	<!-- ============================= -->
	
	<!-- ============================= -->
	<!-- Example processing -->
	<!-- ============================= -->
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'Example' or @w:val = 'Exampleindent' or @w:val = 'Exampleindent2' or @w:val = 'Exampleindent2' or @w:val = 'Figureexample']]">
	
		<xsl:call-template name="setId"/>
		
		<xsl:variable name="text_">
			<xsl:apply-templates/>
		</xsl:variable>
		<xsl:variable name="text" select="java:replaceAll(java:java.lang.String.new($text_),'^EXAMPLE(\s|\h)+(—(\s|\h)+)?(\d+(\s|\h)+)?(.*)','$6')"/> <!-- remove 'EXAMPLE ' and 'EXAMPLE — ' at start -->
		
		<xsl:choose>
			<xsl:when test="following-sibling::*[1][self::w:p[w:pPr/w:pStyle[@w:val = 'Code']]]">
				<xsl:text>.</xsl:text><xsl:value-of select="$text"/>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>====</xsl:text>
				<xsl:text>&#xa;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>====</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:value-of select="$text"/>
				<xsl:text>&#xa;</xsl:text>
				<xsl:if test="not(following-sibling::w:p[2][w:pPr/w:pStyle[@w:val = 'Examplecontinued' or @w:val = 'Exampleindentcontinued' or @w:val = 'Exampleindent2continued']])">
					<xsl:text>====</xsl:text>
					<xsl:text>&#xa;</xsl:text>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
		
		
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'Examplecontinued' or @w:val = 'Exampleindentcontinued' or @w:val = 'Exampleindent2continued']]">
		<xsl:variable name="text">
			<xsl:apply-templates/>
		</xsl:variable>
		<xsl:value-of select="$text"/>
		<xsl:text>====</xsl:text>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<!-- no need to skip, because there is case when it contains significant title:
			<w:r>
				<w:rPr>
					<w:rStyle w:val="examplelabel"/>
				</w:rPr>
				<w:t>EXAMPLE — Sample Code</w:t>
			</w:r>
	-->
	<!-- <xsl:template match="w:r[w:rPr/w:rStyle/@w:val = 'examplelabel']" /> -->
	
	<!-- ============================= -->
	<!-- End Example processing -->
	<!-- ============================= -->
	
	
	<!-- ============================= -->
	<!-- Term's source processing -->
	<!-- ============================= -->
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'Source']]">
		<xsl:text>[.source]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<!-- <xsl:text>&lt;&lt;</xsl:text> -->
		<xsl:variable name="source">
			<xsl:apply-templates/>
		</xsl:variable>
		<xsl:value-of select="normalize-space($source)"/>
		<!-- <xsl:if test="not(contains($source, '&gt;&gt;'))">
			<xsl:text>&gt;&gt;</xsl:text>
		</xsl:if> -->
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
	
		<!-- first table cell contains id for table -->
		<xsl:for-each select="(following-sibling::w:tbl[1]//w:tc)[1]/w:p[1]">
			<xsl:call-template name="setId"/>
		</xsl:for-each>
		
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
			<xsl:when test="(count($table//td[@border = '1']) = 0 and $table//p/@dl = 'true' and count($table/table/colgroup/col) = 2) or not(w:tblPr/w:tblStyle/@w:val = 'TableISO')"> <!-- style 'TableISO' means table, not definition list -->
				<xsl:apply-templates select="$table/node()" mode="dl"/>
			</xsl:when>
			<xsl:when test="w:tblPr/w:tblStyle/@w:val = 'dl' or w:tblPr/w:tblStyle/@w:val = 'figdl'">
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
		<xsl:choose>
			<xsl:when test="./w:tc//w:rStyle/@w:val = 'tablefootnoteref' and ancestor::w:tbl/preceding-sibling::*[1][self::w:p[w:pPr/w:pStyle/@w:val = 'figure']] and ancestor::w:tbl/preceding-sibling::*[2][self::w:p[w:pPr/w:pStyle/@w:val = 'FigureGraphic']]">
			<!-- skip footnote in the table after Figure -->
			</xsl:when>
			<xsl:otherwise>
				<tr>
					<xsl:if test=".//w:p[w:pPr/w:pStyle/@w:val = 'Tableheader']">
						<xsl:attribute name="header">true</xsl:attribute>
					</xsl:if>
					<xsl:apply-templates/>
				</tr>
			</xsl:otherwise>
		</xsl:choose>
	
	</xsl:template>
	
	<xsl:template match="w:tc[w:tcPr/w:vMerge[not(@w:val = 'restart')]][not(w:p/w:r)]"/>
	
	<xsl:template match="w:tc">
		<td>
			<xsl:if test="w:tcPr/w:tcBorders">
				<xsl:attribute name="border">1</xsl:attribute>
			</xsl:if>
			<xsl:if test="w:tcPr/w:gridSpan">
				<xsl:attribute name="colspan"><xsl:value-of select="w:tcPr/w:gridSpan/@w:val"/></xsl:attribute>
			</xsl:if>
			
			<xsl:attribute name="valign"><xsl:value-of select="w:tcPr/w:vAlign/@w:val"/></xsl:attribute>		
			
			<xsl:if test="w:tcPr/w:vMerge/@w:val = 'restart'">
				<xsl:variable name="curr_row_number" select="count(ancestor::w:tr[1]/preceding-sibling::w:tr) + 1"/>
				<xsl:variable name="next_restart_row_number_" select="count(ancestor::w:tr[1]/following-sibling::w:tr[w:tc/w:tcPr/w:vMerge]/preceding-sibling::w:tr) + 1"/> <!-- /@w:val = 'restart' -->
				<xsl:variable name="next_restart_row_number">
					<xsl:choose>
						<xsl:when test="$next_restart_row_number_ = '1'">
							<xsl:value-of select="count(ancestor::w:tr[1]/following-sibling::w:tr/preceding-sibling::w:tr) + 2"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$next_restart_row_number_ + 1"/>
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
	
	<xsl:template match="w:tc/w:p[w:pPr/w:pStyle[@w:val = 'Note']]">
		<tablenote>
			<xsl:attribute name="id">
				<xsl:call-template name="setId"/>
			</xsl:attribute>
			<xsl:apply-templates />
		</tablenote>
	</xsl:template>
	
	<!-- Example:
		<w:r>	
			<w:rPr>
				<w:rStyle w:val="tablefootnoteref"/>
			</w:rPr>
			<w:t>d</w:t>
		</w:r>
	-->
	<!-- <xsl:template match="w:r[w:rPr/w:rStyle[@w:val = 'tablefootnoteref']]"/> -->
	
	
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'tablefootnote']]">
		<tablefootnotebody>
			<xsl:attribute name="ref">
				<xsl:value-of select="w:r[w:rPr/w:rStyle/@w:val = 'tablefootnoteref']"/>
			</xsl:attribute>
			<xsl:apply-templates />
		</tablefootnotebody>
	</xsl:template>
	<!-- ===================== -->
	<!-- END create HTML-like table -->
	<!-- ===================== -->
	
	
	<xsl:template match="table">
		
		<xsl:call-template name="insertTableProperties"/>
		
		<xsl:call-template name="insertTableSeparator"/>
		
		<xsl:text>===</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		
		<xsl:variable name="table_">
			<xsl:apply-templates />
		</xsl:variable>
		<xsl:variable name="table" select="xalan:nodeset($table_)"/>
		
		<xsl:copy-of select="$table"/>
		
		<xsl:text>&#xa;</xsl:text>
		
		<xsl:call-template name="insertTableSeparator"/>
		<xsl:text>===</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		
		<!-- insert Table's notes -->
		<xsl:apply-templates select=".//tablenote">
			<xsl:with-param name="process">true</xsl:with-param>
		</xsl:apply-templates>
		
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
		
		
		<xsl:variable name="options">
			<xsl:if test=".//tr[@header = 'true']">
				<option>header</option>
			</xsl:if>
			<!-- <xsl:if test="ancestor::table-wrap/table-wrap-foot[count(*[local-name() != 'fn-group' and local-name() != 'fn' and local-name() != 'non-normative-note']) != 0]">
				<option>footer</option>
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
			<xsl:if test="count(.//tr[@header = 'true']) &gt; 1">
				<xsl:text>,headerrows=</xsl:text>
				<xsl:value-of select="count(.//tr[@header = 'true'])"/>
			</xsl:if>
		</xsl:if>
		
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
		<xsl:if test="@header = 'true' and not(following-sibling::tr[@header = 'true'])">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<!-- ignore table's row with note(s) -->
	<xsl:template match="tr[td/tablenote or td/tablefootnotebody]"/>
	
	<xsl:template match="td">
		<xsl:variable name="span">
			<xsl:call-template name="spanProcessing"/>
		</xsl:variable>
		<xsl:value-of select="$span"/>
		<xsl:variable name="alignment">
			<xsl:call-template name="alignmentProcessing"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$span != '' and starts-with($alignment, '.')">
				<xsl:value-of select="substring($alignment,2)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$alignment"/>
			</xsl:otherwise>
		</xsl:choose>
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
		<xsl:if test="(@align and @align != 'left') or (@valign and @valign != 'top' and @valign != '')">
			
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
			<xsl:when test="@valign = 'center'">.^</xsl:when>
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
	
	
	<xsl:template match="tablenote">
		<xsl:param name="process">false</xsl:param>
		<xsl:if test="$process = 'true'">
			<xsl:value-of select="@id"/>
			<xsl:variable name="tablenote">
				<xsl:call-template name="note"/>
			</xsl:variable>
			<xsl:value-of select="$tablenote"/>
		</xsl:if>
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
	<xsl:template match="w:p[starts-with(w:pPr/w:pStyle/@w:val, 'ListContinue') or starts-with(w:pPr/w:pStyle/@w:val, 'MsoListContinue')]">
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
				<xsl:when test="(.//*[self::w:t or self::w:delText or self::w:insText])[1] = $em_dash">*</xsl:when> <!-- unordered list (ul) -->
				<xsl:otherwise>.</xsl:otherwise> <!-- ordered list (ol) -->
			</xsl:choose>
		</xsl:variable>
		
		<xsl:if test="normalize-space($text) != ''">
			<!-- <xsl:text>DEBUG level=</xsl:text><xsl:value-of select="$level"/><xsl:text>&#xa;</xsl:text> -->
			
			<xsl:call-template name="repeat">
				<xsl:with-param name="char" select="$listitem_label"/>
				<xsl:with-param name="count" select="$level"/>
			</xsl:call-template>
			<!-- <xsl:text> </xsl:text> -->
			
			<xsl:value-of select="$text"/>
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
	</xsl:template> <!-- ul -->
	

	<!-- Ordered list (ol) -->
	<xsl:template match="w:p[starts-with(w:pPr/w:pStyle/@w:val, 'ListNumber') or starts-with(w:pPr/w:pStyle/@w:val, 'MsoListNumber')]">
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
				<xsl:with-param name="char" select="'.'"/>
				<xsl:with-param name="count" select="$level"/>
			</xsl:call-template>
			<!-- <xsl:text> </xsl:text> -->
			
			<xsl:value-of select="$text"/>
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
	</xsl:template> <!-- ol -->
	
	<!-- text in list: list item label or body -->
	<xsl:template match="w:p[starts-with(w:pPr/w:pStyle/@w:val, 'ListContinue') or starts-with(w:pPr/w:pStyle/@w:val, 'ListNumber') or starts-with(w:pPr/w:pStyle/@w:val, 'MsoListNumber') or starts-with(w:pPr/w:pStyle/@w:val, 'MsoListContinue')]//*[self::w:t or self::w:delText or self::w:insText]">
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
	
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'figure' or @w:val = 'FigureGraphic']][.//w:drawing]">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="w:p[w:r/w:drawing]">
		<xsl:call-template name="setId"/>
		
		<xsl:variable name="following_nodes_">
			<!-- <xsl:if test="preceding-sibling::*[1][self::w:p[w:pPr/w:pStyle[@w:val = 'FigureTitle' or @w:val = 'Figuretitle' or @w:val = 'Figuretitle0' or @w:val = 'AnnexFigureTitle']]]">
				<non_figure_node/>
			</xsl:if> -->
			<xsl:for-each select="following-sibling::*">
				<xsl:choose>
					<xsl:when test="self::w:p[w:r/w:drawing]">
						<!-- <xsl:copy-of select="."/> -->
					</xsl:when>
					<xsl:when test="self::w:p[w:pPr/w:pStyle[@w:val = 'FigureTitle' or @w:val = 'Figuretitle' or @w:val = 'Figuretitle0' or @w:val = 'AnnexFigureTitle']]">
						<xsl:if test="preceding-sibling::*[1][self::w:p[w:pPr/w:pStyle[@w:val = 'FigureTitle' or @w:val = 'Figuretitle' or @w:val = 'Figuretitle0' or @w:val = 'AnnexFigureTitle'] and w:pPr/w:keepNext]]"> <!-- means last sub-figure title, then next one is table sequence title -->
							<xsl:copy-of select="."/>
						</xsl:if>
					</xsl:when>
					<xsl:when test="self::w:tbl">
						<xsl:apply-templates select="w:tr[w:tc//w:rStyle[@w:val = 'tablefootnoteref']]/w:tc[2]" mode="figure_footnote"/>
					</xsl:when>
					<xsl:otherwise><non_figure_node><!-- <xsl:copy-of select="."/> --></non_figure_node></xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
			<non_figure_node/> <!-- empty node just for point to the end -->
		</xsl:variable>
		<xsl:variable name="following_nodes" select="xalan:nodeset($following_nodes_)"/>
		
		<!-- <xsl:text>&#xa;DEBUG:</xsl:text>
		<xsl:apply-templates select="$following_nodes" mode="print_as_xml"/>
		<xsl:text>&#xa;</xsl:text> -->
		
		<!-- get latest figure name as main title for sub-figures sequence -->
		<xsl:if test="starts-with(normalize-space(following-sibling::w:p[w:pPr/w:pStyle[@w:val = 'FigureTitle' or @w:val = 'Figuretitle' or @w:val = 'Figuretitle0' or @w:val = 'AnnexFigureTitle']][1]),'a)')">
			<xsl:apply-templates select="$following_nodes/non_figure_node[1]/preceding-sibling::*[1][self::w:p[w:pPr/w:pStyle[@w:val = 'FigureTitle' or @w:val = 'Figuretitle' or @w:val = 'Figuretitle0' or @w:val = 'AnnexFigureTitle']]]">
				<xsl:with-param name="process">true</xsl:with-param>
				<xsl:with-param name="maintitle">true</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
		
		<xsl:apply-templates select="following-sibling::w:p[w:pPr/w:pStyle[@w:val = 'FigureTitle' or @w:val = 'Figuretitle' or @w:val = 'Figuretitle0' or @w:val = 'AnnexFigureTitle']][1]">
			<xsl:with-param name="process">true</xsl:with-param>
		</xsl:apply-templates>
		
		<xsl:apply-templates />
		
		<!-- put Figure's footnote -->
		<xsl:apply-templates select="$following_nodes/figure_footnote"/>
		
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="w:tc" mode="figure_footnote">
		<figure_footnote>
			<xsl:text>footnote:[</xsl:text>
			<xsl:apply-templates/>
			<xsl:text>]&#xa;</xsl:text>
		</figure_footnote>
	</xsl:template>
	
	
	
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'FigureTitle' or @w:val = 'Figuretitle' or @w:val = 'Figuretitle0' or @w:val = 'AnnexFigureTitle']]">
		<xsl:param name="process">false</xsl:param>
		<xsl:param name="maintitle">false</xsl:param>
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
					<xsl:value-of select="java:replaceAll(java:java.lang.String.new($title),'^([a-z]\))(\s|\h)+','')"/> <!-- remove 'a) ' from 'a)... Figure title -->
				</xsl:otherwise>
			</xsl:choose>
			<xsl:text>&#xa;</xsl:text>
			
			<xsl:if test="$maintitle = 'true'">
				<xsl:text>====</xsl:text>
				<xsl:text>&#xa;</xsl:text>
			</xsl:if>
		</xsl:if>
		
		<!-- closing ==== for sub-figures -->
		<xsl:if test="preceding-sibling::*[1][self::w:p[w:pPr/w:pStyle[@w:val = 'FigureTitle' or @w:val = 'Figuretitle' or @w:val = 'Figuretitle0' or @w:val = 'AnnexFigureTitle']]]">
			<xsl:text>====</xsl:text>
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
		
	<xsl:template name="insertTaskImageList"> 
		<xsl:variable name="imageList">
			<xsl:for-each select="//pic:blipFill/a:blip">
				<xsl:variable name="rId" select="@r:embed"/>
				<!-- Example: <Relationship Id="rId205" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image1.png"/> -->
				<xsl:variable name="target" select="$rels_xml//rels:Relationship[@Id = $rId]/@Target"/>
				<xsl:variable name="filename" select="java:replaceAll(java:java.lang.String.new($target),'.*/(.*)$','$1')"/>
				<image>image::<xsl:value-of select="$filename"/><xsl:text>&#xa;</xsl:text></image>
			</xsl:for-each>
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
		
	<!-- ============================= -->
	<!-- END Figure processing -->
	<!-- ============================= -->
	
	<!-- ============================= -->
	<!-- Formula processing -->
	<!-- ============================= -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'Formula']/m:oMath">
		
		<xsl:for-each select="ancestor::w:p">
			<xsl:call-template name="setId"/>
		</xsl:for-each>
		
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
		
		<xsl:call-template name="insertMath"/>
		
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>++++</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<!-- insert OMML as MathML or AsciiMath (if OMML is simple like 'R=3%' or 'r') -->
	<xsl:template name="insertMath">
		<xsl:variable name="simpleMath" select="normalize-space(count(*) = count(m:r))"/>
		
		<xsl:choose>
			<xsl:when test="$simpleMath = 'true'"> <!-- insert as AsciiMath -->
				<xsl:variable name="text">
					<xsl:apply-templates />
				</xsl:variable>
				<xsl:value-of select="$text"/>
			</xsl:when>
			<xsl:otherwise> <!-- insert as MathML -->
				<xsl:variable name="math">
					<xsl:apply-templates select="." mode="math"/>
				</xsl:variable>
				<xsl:apply-templates select="xalan:nodeset($math)" mode="print_as_xml"/>
			</xsl:otherwise>
		</xsl:choose>
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
	
		<xsl:if test="preceding-sibling::*[1][self::w:r][normalize-space(w:t/text()) = 'where']">
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
	
		<xsl:text>stem:[</xsl:text>
		
		<xsl:variable name="math">
			<xsl:call-template name="insertMath"/>
		</xsl:variable>
		<xsl:copy-of select="$math"/>
		
		<xsl:text>]</xsl:text>
	
		<xsl:variable name="isWhere" select="normalize-space(preceding-sibling::*[1][self::w:r][normalize-space(w:t/text()) = 'where'] and following-sibling::*[1][self::w:r])"/>
	
		<xsl:if test="not(contains($math,'&lt;math'))"> <!-- for AsciiMath -->
			<xsl:variable name="text" select="."/>
			<!-- add space after stem -->
			<xsl:if test="java:org.metanorma.utils.RegExHelper.matches('.*(\s|\h)$', $text) = 'true' and $isWhere = 'false'"><xsl:text> </xsl:text></xsl:if>
		</xsl:if>
		
		<!-- Example:
			<w:r>
				...
				<w:t xml:space="preserve">where </w:t>
			</w:r>
			<m:oMath>
				...
			</m:oMath>
			<w:r>
				...
				<w:t>is the repeatability limit.</w:t>
			</w:r>
		-->
		<xsl:if test="$isWhere = 'true'">
			<xsl:text>:: </xsl:text>
		</xsl:if>
		
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
			<xsl:when test="ancestor::w:p/w:pPr/w:pStyle/@w:val = 'AdmittedTerm'">
				<xsl:apply-templates/>
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
	<!-- Source code processing -->
	<!-- ============================= -->
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'Code' or @w:val = 'Code-' or @w:val = 'Code--']]">
		<xsl:text>[source]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>--</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>--</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		
		<xsl:if test="preceding-sibling::*[1][self::w:p[w:pPr/w:pStyle[@w:val = 'Example' or @w:val = 'Exampleindent' or @w:val = 'Exampleindent2' or @w:val = 'Exampleindent2' or @w:val = 'Figureexample']]]">
			<xsl:text>====</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'Code' or @w:val = 'Code-' or @w:val = 'Code--']]//w:br" priority="2">
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	<!-- ============================= -->
	<!-- END Source code processing -->
	<!-- ============================= -->
	
	
	<!-- ============================= -->
	<!-- Admonitions and quote processing -->
	<!-- ============================= -->
	
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'BodyTextindent1']]">
		<xsl:variable name="regex_admonition">^(NOTE|IMPORTANT|WARNING|CAUTION)(\s|\h)+—(\s|\h)+(.*)</xsl:variable>
		<xsl:variable name="text">
			<xsl:apply-templates />
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($regex_admonition, $text) = 'true'">
				<xsl:value-of select="java:replaceAll(java:java.lang.String.new($text),$regex_admonition,'$1')"/>
				<xsl:text>: </xsl:text>
				<xsl:value-of select="java:replaceAll(java:java.lang.String.new($text),$regex_admonition,'$4')"/>
			</xsl:when>
			<xsl:otherwise> <!-- quote -->
				<xsl:text>[quote</xsl:text>
				<xsl:apply-templates select="following-sibling::w:p[1][w:pPr/w:pStyle/@w:val = 'quoteattribution']">
					<xsl:with-param name="process">true</xsl:with-param>
				</xsl:apply-templates>
				<xsl:text>]</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>_____</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:value-of select="$text"/>
				<xsl:text>&#xa;</xsl:text>
				<xsl:text>_____</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'quoteattribution']]">
		<xsl:param name="process">false</xsl:param>
		<xsl:if test="$process = 'true'">
			<xsl:variable name="components">
				<xsl:for-each select="*">
					<component><xsl:apply-templates select="."/></component>
				</xsl:for-each>
			</xsl:variable>
			<xsl:for-each select="xalan:nodeset($components)/*">
				<xsl:value-of select="java:replaceAll(java:java.lang.String.new(normalize-space(.)),'^(—(\s|\h))?(.*),$','$3')"/> <!-- Example: '— ISO,' to 'ISO' -->
				<xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	
	<!-- ============================= -->
	<!-- END Admonitions and quote processing -->
	<!-- ============================= -->
	
	
	<!-- ============================= -->
	<!-- Hyperlink processing -->
	<!-- ============================= -->
	<xsl:template match="w:hyperlink">
		<xsl:variable name="style" select="$hyperlinks/hyperlink[@anchor = current()/@w:anchor]/@style"/>
		
		<xsl:variable name="style_parent" select="ancestor::w:p/w:pPr/w:pStyle/@w:val"/>
		
		<!-- From: https://www.baeldung.com/java-email-validation-regex#regular-expression-by-rfc-5322-for-email-validation -->
		<xsl:variable name="regex_email">^[a-zA-Z0-9_!#$%&amp;'*+/=?`{|}~^.-]+@[a-zA-Z0-9.-]+$</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="$style = 'tablefootnote'"> <!-- hyperlink to the footnote -->
				<xsl:text> footnote:[</xsl:text>
					<xsl:apply-templates select="ancestor::w:tbl[1]//w:r[preceding-sibling::w:bookmarkStart[@w:name = current()/@w:anchor]]"/>
				<xsl:text>]</xsl:text>
			</xsl:when>
			<xsl:when test="count(w:r) = 1 and w:r/w:rPr/w:rStyle[
				 @w:val = 'citeapp' or 
				 @w:val = 'citebase' or 
				 @w:val = 'citebib' or 
				 @w:val = 'citebox' or 
				 @w:val = 'citeen' or 
				 @w:val = 'citeeq' or 
				 @w:val = 'citefig' or 
				 @w:val = 'citefn' or 
				 @w:val = 'citesec' or 
				 @w:val = 'citesection' or
				 @w:val = 'citetbl' or
				 @w:val = 'citetfn']"> <!-- hyperlink to Annex, Figure, Clause or Table, etc. -->
				<xsl:text>&lt;&lt;</xsl:text>
				<xsl:value-of select="@w:anchor"/>
				<xsl:text>&gt;&gt;</xsl:text>
			</xsl:when>
			<xsl:when test="count(w:r) = 1 and w:r/w:rPr/w:rStyle[@w:val = 'Hyperlink'] and java:org.metanorma.utils.RegExHelper.matches($regex_email, normalize-space(.)) = 'true'">
				<xsl:text>mailto:</xsl:text>
				<xsl:apply-templates />
				<xsl:text>[]</xsl:text>
			</xsl:when>
			<xsl:when test="w:r[w:rPr/w:rStyle/@w:val = 'stdpublisher'] and w:r[w:rPr/w:rStyle/@w:val = 'stddocNumber']"> <!-- hyperlink to the standard -->
				
				<xsl:variable name="localities">
					<xsl:for-each select="node()[w:rPr/w:rStyle[@w:val = 'citesec' or @w:val = 'citetbl' or @w:val = 'citefig' or @w:val = 'citeapp' or @w:val = 'citebox' or @w:val = 'citeeq' or @w:val = 'citesection']]"> <!-- locality processing -->
						<xsl:variable name="style_locality" select="w:rPr/w:rStyle/@w:val"/>
						<locality>
							<xsl:choose>
								<xsl:when test="$style_locality = 'citesec'">clause</xsl:when>
								<xsl:when test="$style_locality = 'citetbl'">table</xsl:when>
								<xsl:when test="$style_locality = 'citefig'">figure</xsl:when>
								<xsl:when test="$style_locality = 'citeapp'">annex</xsl:when>
								<xsl:when test="$style_locality = 'citebox'">box</xsl:when>
								<xsl:when test="$style_locality = 'citeeq'">equation</xsl:when>
								<xsl:when test="$style_locality = 'citesection'">section</xsl:when>
							</xsl:choose>
							<xsl:text>=</xsl:text>
							<xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new(.),'^(Clause|Table|Figure|Annex|Box|Equation|Section)(.*)$','$2'))"/> <!-- remove Clause, Table, ... at start -->
						</locality>
					</xsl:for-each>
				</xsl:variable>
				
				<!-- Example: <<ISO_12345>> -->
				<xsl:choose>
					<xsl:when test="ancestor::w:p/w:pPr/w:pStyle/@w:val = 'quoteattribution'">
						<xsl:text>"</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>&lt;&lt;</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				
					<xsl:value-of select="@w:anchor"/>
					
					<xsl:if test="not(@w:anchor)">
						<xsl:variable name="id_">
							<xsl:for-each select="node()[not(w:rPr/w:rStyle[@w:val = 'citesec' or @w:val = 'citetbl' or @w:val = 'citefig' or @w:val = 'citeapp' or @w:val = 'citebox' or @w:val = 'citeeq' or @w:val = 'citesection'])]">
								<xsl:value-of select="translate(.,'&#xa0;,',' ')"/> <!-- replace a0 to space, and remove comma -->
							</xsl:for-each>
						</xsl:variable>
						<xsl:variable name="id" select="translate(normalize-space($id_),':/ ','___')"/> <!-- replace :,/ and space to underscore _ -->
						<xsl:value-of select="$id"/>
					</xsl:if>
				
					<xsl:for-each select="xalan:nodeset($localities)//locality">
						<xsl:if test="position() = 1">,</xsl:if>
						<xsl:value-of select="."/>
						<xsl:if test="position() != last()">,</xsl:if>
					</xsl:for-each>
				
				<xsl:choose>
					<xsl:when test="ancestor::w:p/w:pPr/w:pStyle/@w:val = 'quoteattribution'">
						<xsl:text>"</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>&gt;&gt;</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				
			</xsl:when> <!-- end hyperlink to the standard -->
			
			<xsl:when test="w:r/w:rPr/w:rStyle[@w:val = 'stddocNumber' or (@w:val = 'Hyperlink' and ancestor::w:hyperlink/@w:anchor != '')]"> <!-- stddocNumber - hyperlink to non-standard bibliography item -->
				<xsl:text>&lt;&lt;</xsl:text>
				<xsl:value-of select="@w:anchor"/>
				<xsl:if test="w:r/w:rPr/w:rStyle/@w:val = 'Hyperlink'">
					<xsl:variable name="text"><xsl:apply-templates select=".//w:t/text()"/></xsl:variable>
					<xsl:if test="java:org.metanorma.utils.RegExHelper.matches('^\[\d+\]$', normalize-space($text)) = 'false' and
					$style != 'Formula' and $style != ''"> <!-- skip [10], Formula ... -->
						<xsl:text>,</xsl:text><xsl:value-of select="$text"/>
					</xsl:if>
				</xsl:if>
				<xsl:text>&gt;&gt;</xsl:text>
			</xsl:when> <!-- end hyperlink to non-standard bibliography item -->
			
			<xsl:otherwise>
				<xsl:apply-templates />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- Example: HYPERLINK "" \l "figureC-1" -->
	<xsl:template match="w:r/w:instrText">
		<xsl:variable name="text" select="."/>
		<xsl:variable name="quot">"</xsl:variable>
		<xsl:variable name="regex_hyperlink">.*<xsl:value-of select="$quot"/>(.*)<xsl:value-of select="$quot"/></xsl:variable>
		<xsl:variable name="hyperlink" select="normalize-space(java:replaceAll(java:java.lang.String.new($text),$regex_hyperlink,'$1'))"/>
		<xsl:if test="$hyperlink != ''">
			<xsl:text>&lt;&lt;</xsl:text>
			<xsl:value-of select="$hyperlink"/>
			<xsl:text>&gt;&gt;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="w:r[w:rPr/w:rStyle[@w:val = 'citeapp' or @w:val = 'citefig' or @w:val = 'citesec' or @w:val = 'citetbl']][preceding-sibling::w:r[contains(w:instrText,'HYPERLINK')]]"/>
	
	<!-- remove 'a' from footnote body -->
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'tablefootnote']]/w:r[w:rPr/w:rStyle/@w:val = 'tablefootnoteref']"/>
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'tablefootnote']]/w:r/w:tab" priority="2"/>
	
	
	<!-- ============================= -->
	<!-- END Hyperlink processing -->
	<!-- ============================= -->
	
	
	
	<!-- ============================= -->
	<!-- Bibliography entry processing -->
	<!-- ============================= -->
	
	<!-- style RefNorm is using for Normative References,
		style BiblioEntry0 is using for bibliography -->
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'BiblioEntry0' or @w:val = 'BiblioEntry' or @w:val = 'RefNorm']]">
		
		<xsl:variable name="bib_style" select="w:pPr/w:pStyle/@w:val"/>
		
		<!-- Example: * [[[ISO712,ISO 712]]], _Cereals and cereal products - Determination of moisture content - Reference method_ -->
		
		<xsl:variable name="bibitem_">
			<xsl:apply-templates mode="bibitem"/>
		</xsl:variable>
		<xsl:variable name="bibitem" select="xalan:nodeset($bibitem_)"/>
		
		<!-- DEBUG:
		<xsl:apply-templates select="$bibitem" mode="print_as_xml"/>
		<xsl:text>&#xa;</xsl:text> -->
		
		
		<xsl:if test="normalize-space($bibitem) != ''">
			<xsl:text>* </xsl:text>
			
			<xsl:choose>
				<xsl:when test="$bibitem/stdpublisher or $bibitem/stddocNumber"> <!-- if 'standard' bibitem -->
					
					
				
					<xsl:text>[[[</xsl:text>
					
						<xsl:value-of select="$bibitem/id"/>
						
						<xsl:if test="not($bibitem/id)">
							<xsl:variable name="id_">
								<xsl:for-each select="$bibitem/node()[not(local-name() = 'bibnumber' or local-name() = 'stddocTitle' or local-name() = 'FootnoteReference') or following-sibling::*[self::w:tab]]"> <!-- or contains(.,'footnote:[') -->
									<xsl:value-of select="translate(.,'&#xa0;[],',' ')"/> <!-- replace a0 to space, remove [, ] and comman -->
								</xsl:for-each>
							</xsl:variable>
							<xsl:variable name="id" select="translate(normalize-space($id_),':/ ','___')"/> <!-- replace :,/ and space to underscore _ -->
							<xsl:value-of select="java:replaceAll(java:java.lang.String.new($id),'—','--')"/>
						</xsl:if>
						
						<xsl:text>,</xsl:text>
						
						<xsl:variable name="reference_text">
							<xsl:for-each select="$bibitem/node()[not(local-name() = 'id' or local-name() = 'bibnumber' or local-name() = 'stddocTitle' or local-name() = 'FootnoteReference')]"> <!-- contains(.,'footnote:[') -->
								<xsl:choose>
									<xsl:when test="normalize-space() = '[' or normalize-space() = ']' or normalize-space() = ','"><!-- skip --></xsl:when>
									<xsl:otherwise><xsl:value-of select="translate(.,'&#xa0;', ' ')"/></xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>
						</xsl:variable>
						
						<xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new($reference_text),'—','--'))"/> <!-- replace dash to double minus -->
						
					<xsl:text>]]]</xsl:text>
					
					<xsl:value-of select="$bibitem/FootnoteReference"/>
					
					<!-- <xsl:apply-templates select="$bibitem" mode="print_as_xml"/> -->
					
					<xsl:for-each select="$bibitem/stddocTitle[1]"> <!-- standard's title -->
						<xsl:text>, </xsl:text>
						<xsl:value-of select="."/>
						<!-- <xsl:apply-templates /> -->
						<xsl:for-each select="following-sibling::node()">
							<xsl:value-of select="."/>
							<!-- <xsl:apply-templates /> -->
						</xsl:for-each>
					</xsl:for-each>
				</xsl:when> <!-- end 'stardard' item -->
				<xsl:otherwise>
					<xsl:text>[[[</xsl:text>
					
						<xsl:value-of select="$bibitem/id"/>
						
						<xsl:if test="not($bibitem/id)">
							<xsl:choose>
								<xsl:when test="$bib_style = 'BiblioEntry0' or $bib_style = 'BiblioEntry'"><xsl:text>bibref</xsl:text></xsl:when>
								<xsl:otherwise>ref</xsl:otherwise>
							</xsl:choose>
							
							<xsl:choose>
								<xsl:when test="$bibitem/bibnumber">
									<xsl:value-of select="$bibitem/bibnumber"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:choose>
										<xsl:when test="$bib_style = 'BiblioEntry0' or $bib_style = 'BiblioEntry'">
											<xsl:number count="w:p[w:pPr/w:pStyle[@w:val = 'BiblioEntry0' or @w:val = 'BiblioEntry']]"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:number count="w:p[w:pPr/w:pStyle/@w:val = 'RefNorm']"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:if>
					<xsl:text>]]], </xsl:text>
					<xsl:variable name="text">
						<xsl:for-each select="$bibitem/node()[not(self::bibnumber or self::id)]">
							<xsl:value-of select="."/>
						</xsl:for-each>
					</xsl:variable>
					<!-- remove [] at start -->
					<xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new($text),'^\[\](\s|\h)*(.*)$','$2'))"/>
				</xsl:otherwise>
			</xsl:choose>
			
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<!-- skip bibliography number -->
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'BiblioEntry0' or @w:val = 'BiblioEntry' or @w:val = 'RefNorm']]/w:r[1][following-sibling::*[1][w:tab]]" priority="2" mode="bibitem"/>
	
	<xsl:template match="w:bookmarkStart" mode="bibitem">
		<xsl:element name="id">
			<xsl:value-of select="@w:name"/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'BiblioEntry0' or @w:val = 'BiblioEntry' or @w:val = 'RefNorm']]//w:r[not(w:rPr/w:rStyle)]" mode="bibitem">
		<xsl:element name="text">
			<xsl:apply-templates select="."/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'BiblioEntry0' or @w:val = 'BiblioEntry' or @w:val = 'RefNorm']]//w:r[w:rPr/w:rStyle/@w:val = 'FootnoteReference'][w:footnoteReference and not(w:t)]" priority="2" mode="bibitem">
		<xsl:element name="FootnoteReference">
			<xsl:call-template name="footnoteReference"/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'BiblioEntry0' or @w:val = 'BiblioEntry' or @w:val = 'RefNorm']]//w:r[w:rPr/w:rStyle]/*[self::w:t or self::w:insText or self::w:delText]" priority="2" mode="bibitem">
		<xsl:variable name="style_" select="ancestor::w:r[1]/w:rPr/w:rStyle/@w:val"/>
		<xsl:variable name="style">
			<xsl:choose>
				<xsl:when test="normalize-space($style_) = ''">text</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$style_"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:element name="{$style}">
			<xsl:call-template name="t"/>
			<!-- <xsl:apply-templates /> -->
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
		<xsl:call-template name="setId"/>
		
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
	
		<xsl:call-template name="setId"/>
		
		<xsl:variable name="text">
			<xsl:apply-templates/>
		</xsl:variable>
		
		<xsl:if test="java:org.metanorma.utils.RegExHelper.matches('^Appendix(\s|\h)+(\d+)(\s|\h)+.*', normalize-space($text)) = 'true'">
			<xsl:text>[%appendix]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	
		<xsl:variable name="level" select="substring-after(w:pPr/w:pStyle/@w:val, 'a')"/>
	
		<xsl:call-template name="repeat">
			<xsl:with-param name="count" select="$level + 1"/>
		</xsl:call-template>
		<xsl:text> </xsl:text>
		
		
		<xsl:variable name="title1" select="java:replaceAll(java:java.lang.String.new(normalize-space($text)),'^([A-Z](\.\d)+(\s|h)+)(.*)','$4')"/> <!-- remove A.1 at start -->
		
		<xsl:variable name="title2" select="java:replaceAll(java:java.lang.String.new(normalize-space($title1)),'^(Appendix(\s|\h)+(\d)+(\s|h)+)(.*)','$5')"/> <!-- remove Appendix at start -->
		
		<xsl:value-of select="$title2"/>
		
		<xsl:text>&#xa;&#xa;</xsl:text>
	
	</xsl:template>
	
	
	
	
	<!-- ============================= -->
	<!-- END Annex processing -->
	<!-- ============================= -->
	
	<xsl:template name="setId">
		<xsl:variable name="id" select="translate(w:bookmarkStart/@w:name,' ','')"/>
		<xsl:if test="$id != '' and not(starts-with($id, '_'))">
			<xsl:text>[[</xsl:text>
			<xsl:value-of select="$id"/>
			<xsl:text>]]</xsl:text>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="w:t[ancestor::w:p[w:pPr/w:pStyle[@w:val = 'Terms' or @w:val = 'Heading1' or @w:val = 'Heading2' or @w:val = 'Heading3' or @w:val = 'Heading4' or @w:val = 'Heading5' or @w:val = 'Heading6' or @w:val = 'Heading7' or @w:val = 'BiblioTitle']]]" priority="2">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:variable name="text_modified">, modified –</xsl:variable>
	<xsl:template match="w:t[ancestor::w:p[w:pPr/w:pStyle/@w:val = 'Source']][starts-with(., $text_modified)]">
		<xsl:text>, </xsl:text>
		<xsl:variable name="modified_text" select="substring-after(., $text_modified)"/>
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new(normalize-space($modified_text)),'(.*)\]$','$1')"/> <!-- remove ']' at end -->
	</xsl:template>
	
	<xsl:template match="w:t" name="t">
		<xsl:variable name="tags">
			<xsl:if test="not(ancestor::w:p[w:pPr/w:pStyle/@w:val = 'zzCover'])">
				<xsl:apply-templates select="preceding-sibling::w:rPr/w:i | preceding-sibling::w:rPr/w:b | preceding-sibling::w:rPr/w:vertAlign[@w:val = 'subscript'] | 
				preceding-sibling::w:rPr/w:vertAlign[@w:val = 'superscript'] | preceding-sibling::w:rPr/w:u | preceding-sibling::w:rPr/w:smallCaps |
				preceding-sibling::w:rPr/w:rStyle[@w:val = 'stddocTitle']" mode="richtext"/>
			</xsl:if>
		</xsl:variable>
		
		<xsl:call-template name="insertRichText">
			<xsl:with-param name="text">
				<xsl:apply-templates />
			</xsl:with-param>
			<xsl:with-param name="tags" select="$tags"/>
		</xsl:call-template>
		
	</xsl:template>
	
	
	<!-- ============================= -->
	<!-- Rich text processing -->
	<!-- ============================= -->
	<xsl:template match="w:b" mode="richtext">
		<xsl:choose>
			<xsl:when test="ancestor::w:p/w:pPr/w:pStyle/@w:val = 'Tableheader'"><!-- skip bold in the table header --></xsl:when>
			<xsl:otherwise><bold/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="w:i" mode="richtext">
		<italic/>
	</xsl:template>
	
	<xsl:template match="w:vertAlign[@w:val = 'subscript']" mode="richtext">
		<sub/>
	</xsl:template>
	
	<xsl:template match="w:vertAlign[@w:val = 'superscript']" mode="richtext">
		<sup/>
	</xsl:template>
	
	<xsl:template match="w:u" mode="richtext">
		<underline/>
	</xsl:template>
	
	<xsl:template match="w:smallCaps" mode="richtext">
		<smallcaps/>
	</xsl:template>
	
	<xsl:template match="w:rStyle" mode="richtext">
		<xsl:variable name="val" select="@w:val"/>
			<!-- Example: 
			<w:style w:type="character" w:customStyle="1" w:styleId="stddocTitle">
				<w:name w:val="std_docTitle"/>
				<w:rPr>
					<w:rFonts w:ascii="Cambria" w:hAnsi="Cambria" w:hint="default"/>
					<w:i/>
					<w:iCs w:val="0"/>
					<w:bdr w:val="none" w:sz="0" w:space="0" w:color="auto" w:frame="1"/>
					<w:shd w:val="clear" w:color="auto" w:fill="FDE9D9"/>
				</w:rPr>
			</w:style> -->
		<xsl:apply-templates select="$styles//w:style[@w:styleId = $val]/w:rPr" mode="richtext"/>
	</xsl:template>
	
	<xsl:template match="w:r[w:rPr/w:rStyle[@w:val = 'ISOCode']]">
		<xsl:text>`</xsl:text><xsl:apply-templates /><xsl:text>`</xsl:text>
	</xsl:template>
	
	<xsl:template match="w:r[w:rPr/w:rStyle[@w:val = 'ISOCodebold']]">
		<xsl:text>*`</xsl:text><xsl:apply-templates /><xsl:text>`*</xsl:text>
	</xsl:template>
	
	<xsl:template match="w:r[w:rPr/w:rStyle[@w:val = 'ISOCodeitalic']]">
		<xsl:text>_`</xsl:text><xsl:apply-templates /><xsl:text>`_</xsl:text>
	</xsl:template>
	
	<xsl:template match="w:r[w:rPr/w:rStyle[@w:val = 'biburl']]">
		<xsl:apply-templates /><xsl:text>[</xsl:text><xsl:apply-templates/><xsl:text>]</xsl:text>
	</xsl:template>
	
	<xsl:template match="w:r[w:rPr/w:rStyle[@w:val = 'addition']]">
		<xsl:text>add:[</xsl:text><xsl:apply-templates /><xsl:text>]</xsl:text>
	</xsl:template>
	
	<xsl:template match="w:r[w:rPr/w:rStyle[@w:val = 'deletion']]">
		<xsl:text>del:[</xsl:text><xsl:apply-templates /><xsl:text>]</xsl:text>
	</xsl:template>
	
	<xsl:template name="insertRichText">
		<xsl:param name="text"/>
		<xsl:param name="tags"/>
		<xsl:param name="pos">1</xsl:param>
		
		<xsl:variable name="curr_tag" select="normalize-space(local-name(xalan:nodeset($tags)/*[position() = $pos]))"/>
		<!-- <xsl:apply-templates select="xalan:nodeset($tags)" mode="print_as_xml"/>
		curr_tag='<xsl:value-of select="$curr_tag"/>' -->
		<xsl:choose>
			<xsl:when test="$curr_tag != ''">
				<xsl:variable name="adoc_tags">
				<xsl:choose>
					<xsl:when test="$curr_tag = 'bold'">
						<tag>*</tag>
						<tag>*</tag>
					</xsl:when>
					<xsl:when test="$curr_tag = 'italic'">
						<tag>_</tag>
						<tag>_</tag>
					</xsl:when>
					<xsl:when test="$curr_tag = 'sub'">
						<tag>~</tag>
						<tag>~</tag>
					</xsl:when>
					<xsl:when test="$curr_tag = 'sup'">
						<tag>^</tag>
						<tag>^</tag>
					</xsl:when>
					<xsl:when test="$curr_tag = 'underline'">
						<tag>[underline]#</tag>
						<tag>#</tag>
					</xsl:when>
					<xsl:when test="$curr_tag = 'smallcaps'">
						<tag>[smallcap]#</tag>
						<tag>#</tag>
					</xsl:when>
				</xsl:choose>
				</xsl:variable>
				<xsl:value-of select="xalan:nodeset($adoc_tags)/*[1]"/>
					<xsl:call-template name="insertRichText">
						<xsl:with-param name="text" select="$text"/>
						<xsl:with-param name="tsgs" select="$tags"/>
						<xsl:with-param name="pos" select="$pos + 1"/>
					</xsl:call-template>
				<xsl:value-of select="xalan:nodeset($adoc_tags)/*[2]"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$text"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- ============================= -->
	<!-- END Rich text processing -->
	<!-- ============================= -->
	
	<!-- ============================= -->
	<!-- Footnote processing -->
	<!-- ============================= -->
	<!-- Example:
		<w:r>
			<w:rPr>
				<w:rStyle w:val="FootnoteReference"/>
			</w:rPr>
			<w:footnoteReference w:id="1"/>
		</w:r>
	-->
	<xsl:template match="w:r[w:rPr/w:rStyle/@w:val = 'FootnoteReference'][w:footnoteReference and not(w:t)]" name="footnoteReference">
		<xsl:text> footnote:[</xsl:text>
		
		<xsl:variable name="id" select="w:footnoteReference/@w:id" />
		
		<xsl:variable name="footnote_" select="$footnotes_xml//w:footnote[@w:id = $id]"/>
		<xsl:variable name="footnote" select="xalan:nodeset($footnote_)"/>
		<xsl:apply-templates select="$footnote"/>
		
		<xsl:text>]</xsl:text>
	</xsl:template>
	
	<!-- <xsl:template match="w:r[w:rPr/w:rStyle/@w:val = 'FootnoteReference']"/> -->
	
	<xsl:template match="w:footnote/w:p" priority="2">
		<xsl:apply-templates />
	</xsl:template>
	
	<!-- Example:
	<w:r>
		<w:rPr>
			<w:rStyle w:val="FootnoteReference"/>
		</w:rPr>
		<w:t>
	-->
	<xsl:template match="w:r[w:rPr/w:rStyle/@w:val = 'FootnoteReference'][w:t = ')' and not(w:footnoteReference)]"/>
	
	<!-- ============================= -->
	<!-- END Footnote processing -->
	<!-- ============================= -->
	
	<xsl:template match="w:tab[not(parent::w:tabs)][following-sibling::* or ../following-sibling::*]">
		<xsl:text> </xsl:text>
	</xsl:template>
	
	<xsl:template match="w:noBreakHyphen">
		<xsl:text>-</xsl:text>
	</xsl:template>
	
	<xsl:template match="w:br[not(@w:type = 'page')]">
		<xsl:text> +</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<!-- Example:
	<w:r>
		<w:t xml:space="preserve"> </w:t>
	</w:r>
	-->
	<xsl:template match="w:r[w:t and normalize-space(w:t) = ''][not(following-sibling::*)]"/>
	<xsl:template match="w:t[normalize-space() = ''][not(../following-sibling::*)]"/>
	
	
	<xsl:template match="w:commentReference">
	
		<!-- Example:
		[reviewer=ISO,date=2017-01-01,from=foreword,to=foreword]
		****
		A Foreword shall appear in each document. The generic text is shown here. It does not contain requirements, recommendations or permissions.

		For further information on the Foreword, see *ISO/IEC Directives, Part 2, 2016, Clause 12.*
		****
		-->
		
		<xsl:variable name="id" select="@w:id"/>
		
		<xsl:variable name="comment_" select="$comments_xml//w:comment[@w:id = $id]"/>
		<xsl:variable name="comment" select="xalan:nodeset($comment_)"/>
		
		<!--DEBUG&#xa;
		<xsl:apply-templates select="$comment" mode="print_as_xml"/>-->
		
		<xsl:variable name="options">
			<option name="reviewer"><xsl:value-of select="$comment/@w:author"/></option>
			<option name="date"><xsl:value-of select="substring($comment/@w:date,1,10)"/></option>
			<option name="from"><xsl:value-of select="ancestor::w:p/w:commentRangeStart/@w:id"/></option>
			<option name="to"><xsl:value-of select="ancestor::w:p/w:commentRangeEnd/@w:id"/></option>
		</xsl:variable>
		<xsl:for-each select="xalan:nodeset($options)//option[normalize-space() != '']">
			<xsl:if test="position() = 1">
				<xsl:text>[</xsl:text>
			</xsl:if>
			<xsl:value-of select="@name"/>
			<xsl:text>=</xsl:text>
			<xsl:value-of select="."/>
			<xsl:if test="position() != last()">
				<xsl:text>,</xsl:text>
			</xsl:if>
			<xsl:if test="position() = last()">
				<xsl:text>]&#xa;</xsl:text>
			</xsl:if>
		</xsl:for-each>
		
		<xsl:text>****</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="$comment"/>
		<xsl:text>****</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		
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
		<xsl:apply-templates mode="print_as_xml"/>
		<xsl:text>&lt;/</xsl:text>
		<xsl:value-of select="local-name()"/>
		<xsl:text>&gt;</xsl:text>
	</xsl:template>
	
</xsl:stylesheet>