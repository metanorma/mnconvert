<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
					xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
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


	<!-- .docx zip content:
	
		./word/document.xml - document body (entry point for this template)
		
	-->
	

	<xsl:template match="/">
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
	
	<xsl:template match="w:p[w:pPr/w:pStyle[@w:val = 'Heading1' or @w:val = 'Heading2' or @w:val = 'Heading3' or @w:val = 'Heading4' or @w:val = 'Heading5' or @w:val = 'Heading6']]">
		<xsl:variable name="level" select="number(substring-after(w:pPr/w:pStyle/@w:val, 'Heading'))"/>
		<xsl:call-template name="repeat">
			<xsl:with-param name="count" select="$level + 1"/>
		</xsl:call-template>
		<xsl:text> </xsl:text>
		
		<xsl:apply-templates/>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	
	
	<!-- no need to output term's num (example '3.1') -->
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'TermNum']"/>
	
	
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
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'Note']">
		<xsl:text>NOTE: </xsl:text>
		<xsl:apply-templates/>
		
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'Note']/w:r/w:t">
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),'^Note(\s|\h)+\d+ to entry:(\s|\h)+(.*)','$3')"/>
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
		<xsl:apply-templates/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>====</xsl:text>
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'Example']/w:r/w:t[text() = 'EXAMPLE']" priority="2"/>
	
	<xsl:template match="w:p[w:pPr/w:pStyle/@w:val = 'Example']/w:r/w:t">
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),'^EXAMPLE(\s|\h)+(\d)*(\s|\h)+(.*)','$4')"/>
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
	<xsl:template match="w:tbl">
		<xsl:variable name="table_">
			<table>
				<xsl:apply-templates/>
			</table>
		</xsl:variable>
		<xsl:variable name="table" select="xalan:nodeset($table_)"/>
		
		<!-- DEBUG=<xsl:apply-templates select="$table" mode="print_as_xml"/> -->
		
		<xsl:choose>
			<!-- no border, paragraph is 'dl' item and columns count = 2 -->
			<xsl:when test="count($table//td[@border = '1']) = 0 and $table//p/@dl = 'true' and count($table/table/colgroup/col) = 2">
				<xsl:apply-templates select="$table/node()" mode="dl"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="$table/node()" />
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
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
		
	
	<xsl:template match="w:t">
		<xsl:apply-templates />
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