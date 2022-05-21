<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
					xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
					xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
					xmlns:rels="http://schemas.openxmlformats.org/package/2006/relationships"
					xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
					xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"
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
	
	<xsl:param name="pathSeparator" select="'/'"/>
	
	<xsl:param name="outpath"/>

	<xsl:param name="imagesdir" select="'images'"/>
	
	<!-- input xml file 'word\_rels\document.xml.rels' -->
	<!-- xml with relationships -->
	<xsl:param name="rels"/>
	<xsl:variable name="rels_xml" select="document($rels)"/>


	<!-- .docx zip content:
	
		./word/document.xml - document body (entry point for this template)
		
	-->
	

	<xsl:template match="/">
		<!-- DEBUG
		<xsl:variable name="env">
			<xsl:copy-of select="xalan:checkEnvironment()"/>
		</xsl:variable>
		<xsl:apply-templates select="xalan:nodeset($env)" mode="print_as_xml"/> -->
		<xsl:apply-templates/>
	</xsl:template>
	
	
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
		TermNum
		Terms
		Note
		Example
		Source
		Tabletitle
		Tablebody0
		zzCopyright
		zzContents
		TOC1
		TOC2
		TOC3
		zzCover
		ListContinue
		ListNumber
		Figurenote
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
	
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'Heading1' or @w:val = 'Heading2' or @w:val = 'Heading3' or @w:val = 'Heading4' or @w:val = 'Heading5' or @w:val = 'Heading6' or @w:val = 'BiblioTitle']]">
	
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
		
		<xsl:call-template name="repeat">
			<xsl:with-param name="count" select="$level + 1"/>
		</xsl:call-template>
		<xsl:text> </xsl:text>
		
		<xsl:value-of select="$text"/>
		
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>

	<!-- ============================= -->
	<!-- Cover page data processing -->
	<!-- ============================= -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzCover'][1]" priority="2">
		<!-- parsing strings -->
		<xsl:variable name="regex_iso_tc">^ISO(\s|\h)+(TC(\s|\h)+\d+/WG(\s|\h)+\d+)$</xsl:variable>
		<xsl:variable name="regex_tc_keyvalue">^(.+)(\s|\h)+(.+)$</xsl:variable>
		<xsl:variable name="regex_iso_number">^ISO(/IEC)?(\s|\h)+(\d+.*)</xsl:variable>
		<xsl:variable name="regex_date">^Date:(\s|\h)?(.*)</xsl:variable> <!-- \d{4}-\d{2}-\d{2}$ -->
		
		<xsl:variable name="bibdata_items_">
			<xsl:for-each select="//w:p[w:pPr/w:pStyle/@w:val = 'zzCover']">
				<xsl:variable name="text">
					<xsl:apply-templates select="w:r/w:t | w:ins/w:r/w:t"/>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($regex_iso_tc, normalize-space(.)) = 'true'">
						<xsl:variable name="tc" select="java:replaceAll(java:java.lang.String.new($text),$regex_iso_tc,'$2')"/>
						<xsl:variable name="tc_components">
							<xsl:call-template name="split">
								<xsl:with-param name="pText" select="$tc"/>
							</xsl:call-template>
						</xsl:variable>
						<!-- <xsl:copy-of select="$tc_components"/> -->
						<xsl:for-each select="xalan:nodeset($tc_components)//item">
							<item name="tc">
								<xsl:attribute name="key">
									<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),$regex_tc_keyvalue,'$1')"/>
								</xsl:attribute>
								<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),$regex_tc_keyvalue,'$3')"/>
							</item>
						</xsl:for-each>
					</xsl:when>
					<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($regex_iso_number, normalize-space(.)) = 'true'">
						<item name="docnumber"><xsl:value-of select="java:replaceAll(java:java.lang.String.new($text),$regex_iso_number,'$3')"/></item>
					</xsl:when>
					<xsl:when test="java:org.metanorma.utils.RegExHelper.matches($regex_date, normalize-space(.)) = 'true'">
						<item name="date"><xsl:value-of select="java:replaceAll(java:java.lang.String.new($text),$regex_date,'$2')"/></item>
					</xsl:when>
					<xsl:otherwise>
						<xsl:if test="normalize-space($text) != ''">
							<item name="title-main-en"><xsl:value-of select="$text"/></item>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="bibdata_items" select="xalan:nodeset($bibdata_items_)"/>
		
		<!-- <xsl:apply-templates select="$bibdata_items" mode="print_as_xml"/> -->
		
		<xsl:text>:docnumber: </xsl:text><xsl:value-of select="$bibdata_items//item[@name = 'docnumber']"/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>:date: </xsl:text><xsl:value-of select="$bibdata_items//item[@name = 'date']"/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>:copyright-year: </xsl:text><xsl:value-of select="substring($bibdata_items//item[@name = 'date'],1,4)"/>
		<xsl:text>&#xa;</xsl:text>
		
		<xsl:text>:title-main-en: </xsl:text><xsl:value-of select="$bibdata_items//item[@name = 'title-main-en']"/>
		<xsl:text>&#xa;</xsl:text>
		
		
		<xsl:for-each select="$bibdata_items//item[not(@name = 'docnumber' or @name = 'date' or @name = 'title-main-en')]">
			<xsl:choose>
				<xsl:when test="@name = 'tc' and (@key = 'TC' or @key = 'WG')">
					<xsl:choose>
						<xsl:when test="@key = 'TC'">
							<xsl:text>:technical-committee-number: </xsl:text><xsl:value-of select="."/>
						</xsl:when>
						<xsl:when test="@key = 'WG'">
							<xsl:text>:workgroup-type: WG</xsl:text>
							<xsl:text>&#xa;</xsl:text>
							<xsl:text>:workgroup-number: </xsl:text><xsl:value-of select="."/>
						</xsl:when>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>:</xsl:text><xsl:value-of select="@name"/><xsl:text>: </xsl:text><xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:text>&#xa;</xsl:text>
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
		
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzCover']"/>
	
	<!-- ignore delText in bibdata fields -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzCover']/w:del"/>
	
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
	
	<!-- skip 'Contents' title -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'zzContents']"/>
	
	
	<!-- skip ToC items text -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'TOC1']"/>
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'TOC2']"/>
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'TOC3']"/>
	
	
	<!-- ============================= -->
	<!-- END Ignore processing -->
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
		
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<!-- ============================= -->
	<!-- Note processing -->
	<!-- ============================= -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'Note' or w:pPr/w:pStyle/@w:val = 'Figurenote']">
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
	
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'Tabletitle']">
		<xsl:text>.</xsl:text>
		<xsl:apply-templates/>
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
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'FigureGraphic']">
	
		<xsl:apply-templates select="following-sibling::w:p[w:pPr/w:pStyle/@w:val = 'Figuretitle0'][1]">
			<xsl:with-param name="process">true</xsl:with-param>
		</xsl:apply-templates>
		
		<!--
		<xsl:text>====</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		-->
		
		<xsl:apply-templates />
	
		<!--
		<xsl:text>====</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		-->
		<xsl:text>&#xa;</xsl:text>
	
	</xsl:template>
		
	<xsl:variable name="em_dash">—</xsl:variable>
	<xsl:variable name="en_dash">–</xsl:variable>
	
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'Figuretitle0']">
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
	<!-- Bibliography entry processing -->
	<!-- ============================= -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'BiblioEntry0']">
		
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
						<xsl:text>bibref</xsl:text>
						<xsl:choose>
							<xsl:when test="$bibitem/bibnumber">
								<xsl:value-of select="$bibitem/bibnumber"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:number count="w:p[w:pPr/w:pStyle/@w:val = 'BiblioEntry0']"/>
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
	
	
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'BiblioEntry0']/w:r[w:rPr/w:rStyle]/w:t">
		<xsl:variable name="style" select="ancestor::w:r[1]/w:rPr/w:rStyle/@w:val"/>
		<xsl:element name="{$style}">
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<!-- ============================= -->
	<!-- END Bibliography entry processing -->
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