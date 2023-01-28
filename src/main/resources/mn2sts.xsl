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
	
	<xsl:param name="debug">false</xsl:param>
	<xsl:param name="outputformat">NISO</xsl:param>
	
	<xsl:key name="element_by_id" match="*" use="@id"/>
	
	<!-- special element 'footnote' is wrapper for xref + fn, will be removed at last step -->
	<xsl:key name="footnotes_in_text_iterator" match="footnote[not(ancestor::table-wrap or ancestor::fig)]" use="'all'"/>
	<xsl:key name="footnotes_in_text" match="footnote[not(ancestor::table-wrap or ancestor::fig)]" use="normalize-space()"/>
	
	<xsl:key name="footnotes_in_table_iterator" match="footnote[ancestor::table-wrap]" use="concat('all_tables_', ancestor::table-wrap/@id)"/>
	
	<xsl:key name="footnotes_in_figure_iterator" match="footnote[ancestor::fig]" use="concat('all_figures_', ancestor::fig/@id)"/>
	
	
	<xsl:include href="mn2xml.xsl"/>
	
	<xsl:template match="/*" mode="xml">
		<xsl:variable name="xml">
			<standard xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:tbx="urn:iso:std:iso:30042:ed-1" xmlns:xlink="http://www.w3.org/1999/xlink">
				<xsl:call-template name="insertXMLcontent"/>
			</standard>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="$metanorma_type = 'IEC' or $metanorma_type = 'ISO' or $metanorma_type = 'BSI'">
				<!-- id generation for IEC and ISO with Guidelines rules -->
				<xsl:variable name="xml_with_id_new">
					<xsl:apply-templates select="xalan:nodeset($xml)" mode="id_generate"/>
				</xsl:variable>
				<xsl:apply-templates select="xalan:nodeset($xml_with_id_new)" mode="id_replace"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$xml"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="metanorma-collection" mode="xml" priority="2">
		<standard xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:tbx="urn:iso:std:iso:30042:ed-1" xmlns:xlink="http://www.w3.org/1999/xlink">
		
			<!-- get 'front' from 1st doc-container -->
			<xsl:for-each select="doc-container[1]/*">
				<xsl:call-template name="insertFront"/>
			</xsl:for-each>
			
			<body>
				<sub-part> <!-- Sections for 1st document -->
					<label/>
					<title/>
					<xsl:for-each select="doc-container[1]/*">
						<xsl:call-template name="insertBody"/>
						<xsl:call-template name="insertBack"/>
					</xsl:for-each>
				</sub-part>
				<sub-part>
					<label/>
					<title/>
					<body>
						<!-- Foreword, Introduction sections for 2nd document -->
						<xsl:for-each select="doc-container[2]/*">
							<xsl:apply-templates select="preface" mode="front_preface"/>
						</xsl:for-each>
						<sub-part> <!-- Sections for 2nd document -->
							<label/>
							<title/>
							<xsl:for-each select="doc-container[2]/*">
								<xsl:call-template name="insertBody"/>
								<xsl:call-template name="insertBack"/>
							</xsl:for-each>
						</sub-part>
					</body>
				</sub-part>
			
			</body>
		
		</standard>
	</xsl:template>
	
	<!-- ================================================== -->
	<!-- id generation for IEC and ISO with Guidelines rules -->
	<!-- ================================================== -->
	<xsl:template match="@*|node()" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="sec[@sec-type = 'foreword']" mode="id_generate">
		<xsl:variable name="title">
			<xsl:apply-templates select="title"/>
		</xsl:variable>
		<xsl:variable name="title_text" select="normalize-space(java:toLowerCase(java:java.lang.String.new($title)))"/>
		<xsl:variable name="title_prev">
			<xsl:apply-templates select="preceding-sibling::sec[@sec-type = 'foreword'][1]/title"/>
		</xsl:variable>
		<xsl:variable name="title_prev_text" select="normalize-space(java:toLowerCase(java:java.lang.String.new($title_prev)))"/>
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			<xsl:attribute name="id_new">
				<xsl:choose>
					<xsl:when test="$metanorma_type = 'IEC'">sec-foreword</xsl:when>
					<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">
						<xsl:choose>
							<xsl:when test="$title_text = 'national foreword'">sec_foreword_nat</xsl:when>
							<xsl:when test="$title_prev_text = 'national foreword'">sec_foreword_euro</xsl:when>
							<xsl:when test="$title_text = 'european foreword to amendment a11'">sec_forewordA11_euro</xsl:when>
							<xsl:otherwise>sec_foreword</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>	
	
	<xsl:template match="sec[@sec-type = 'intro']" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			<xsl:attribute name="id_new">
				<xsl:choose>
					<xsl:when test="$metanorma_type = 'IEC'">sec-introduction</xsl:when>
					<xsl:when test="($metanorma_type = 'ISO' or $metanorma_type = 'BSI') and .//sec">sec_0</xsl:when>
					<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">sec_intro</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<!-- discrepancy in the Guidelines -->
	<xsl:template match="sec[@sec-type = 'scope']" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			<xsl:attribute name="id_new">
				<xsl:choose>
					<xsl:when test="$metanorma_type = 'IEC'">sec-scope</xsl:when>
					<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">sec_scope</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>	
	
	<xsl:template match="sec" mode="id_generate"> <!-- [ancestor::body] -->
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			<xsl:attribute name="id_new">
				<xsl:choose>
					<xsl:when test="$metanorma_type = 'IEC'">sec-<xsl:value-of select="@section"/></xsl:when>
					<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">
						<xsl:choose>
							<xsl:when test="@sec-type = 'publication_info'">sec_pub_info_nat</xsl:when>
							<xsl:when test="@sec-type = 'endorsement'">sec_endorse_euro</xsl:when>
							<xsl:when test="@sec-type = 'foreword' or ancestor::sec[@sec-type = 'publication_info']"><xsl:value-of select="@id"/></xsl:when>
							<xsl:when test="starts-with(normalize-space(), 'This European Standard was approved by')">sec_titlepage_euro</xsl:when>
							<xsl:otherwise>sec_<xsl:value-of select="@section"/></xsl:otherwise>
						</xsl:choose>
					</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="back/ref-list[@content-type = 'bibl']" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			<xsl:attribute name="id_new">
				<xsl:choose>
					<xsl:when test="$metanorma_type = 'IEC'">sec-bibliography</xsl:when>
					<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">sec_bibl</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<!-- Bibliography item -->
	<xsl:template match="back/ref-list[@content-type = 'bibl']//ref" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			<xsl:attribute name="id_new">
				<xsl:choose>
					<xsl:when test="$metanorma_type = 'IEC'">
						<xsl:choose>
							<xsl:when test="label">bib-<xsl:value-of select="translate(label,'[]()','')"/></xsl:when>
							<xsl:otherwise>bib-<xsl:value-of select="@section"/></xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">biblref_<xsl:value-of select="@section"/></xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="back/index | back/sec[@sec-type = 'index']" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			<xsl:attribute name="id_new">
				<xsl:choose>
					<xsl:when test="$metanorma_type = 'IEC'">sec-index</xsl:when>
					<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">sec_index</xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="app" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			<xsl:attribute name="id_new">
				<xsl:choose>
					<xsl:when test="$metanorma_type = 'IEC'">anx-<xsl:value-of select="@section"/></xsl:when>
					<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">sec_<xsl:value-of select="@section"/></xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<!-- Numbered table -->
	<xsl:template match="table-wrap[label]" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			<xsl:attribute name="id_new">
				<xsl:choose>
					<xsl:when test="$metanorma_type = 'IEC'">tab-<xsl:value-of select="@section"/></xsl:when>
					<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">tab_<xsl:value-of select="@section"/></xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<!-- Non-numbered table -->
	<xsl:template match="table-wrap[not(label)] | array" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			
			<xsl:variable name="section_parent" select="normalize-space(ancestor::sec[1]/@section)"/>
			<xsl:variable name="id_parent" select="normalize-space(ancestor::sec[1]/@id)"/>
			
			<xsl:if test="$metanorma_type = 'IEC'"> <!-- and $section_parent != '' -->
				<xsl:attribute name="id_new">
					<!-- Example: tab-informal-5.6-1 -->
					<xsl:text>tab-informal</xsl:text>
					<xsl:if test="$section_parent != ''">
						<xsl:text>-</xsl:text><xsl:value-of select="$section_parent"/>
					</xsl:if>
					<xsl:text>-</xsl:text>
					<xsl:number level="any" count="table-wrap[not(label)][ancestor::sec[1]/@id = $id_parent] | array[ancestor::sec[1]/@id = $id_parent]"/> <!-- number in the section -->
				</xsl:attribute>
			</xsl:if>
			
			<xsl:if test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">
				<xsl:attribute name="id_new">
					<xsl:choose>
						<xsl:when test="@content-type = 'ace-table' and ancestor::sec[@sec-type = 'publication_info']"><xsl:value-of select="@id"/></xsl:when>
						<xsl:when test="not(contains(@content-type , '-index'))"> <!-- no need id for formula-index and figure-index tables -->
							<xsl:text>tab_</xsl:text>
							<xsl:number level="any" format="a" count="array"/>
						</xsl:when>
					</xsl:choose>
				</xsl:attribute>
			</xsl:if>
			
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	
	<!-- Numbered figure -->
	<xsl:template match="fig[label] | fig-group[label]" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			<xsl:attribute name="id_new">
				<xsl:choose>
					<xsl:when test="$metanorma_type = 'IEC'">fig-<xsl:value-of select="@section"/></xsl:when>
					<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">fig_<xsl:value-of select="@section"/></xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="fig[label][count(graphic) &gt; 1]/graphic" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			<xsl:if test="$metanorma_type = 'BSI' or $metanorma_type = 'ISO'">
				<xsl:attribute name="id_new">fig_<xsl:value-of select="ancestor::fig[1]/@section"/>.<xsl:number/></xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<!-- Numbered formula -->
	<xsl:template match="disp-formula[label]" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			<xsl:attribute name="id_new">
				<xsl:choose>
					<xsl:when test="$metanorma_type = 'IEC'">for-<xsl:value-of select="translate(@section,'()','')"/></xsl:when> <!-- (1) to 1 -->
					<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">formula_<xsl:value-of select="@section"/></xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<!-- Formula without number -->
	<xsl:template match="disp-formula[not(label)]" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			
			<xsl:variable name="section_parent" select="normalize-space(ancestor::sec[1]/@section)"/>
			<xsl:variable name="id_parent" select="normalize-space(ancestor::sec[1]/@id)"/>
			
			<xsl:if test="$metanorma_type = 'IEC' and $section_parent != ''">
				<xsl:attribute name="id_new">
					<!-- Example: for-informal-5.6-1 -->
					<xsl:text>for-informal-</xsl:text><xsl:value-of select="$section_parent"/><xsl:text>-</xsl:text>
					<xsl:number level="any" count="disp-formula[not(label)][ancestor::sec[1]/@id = $id_parent]"/> <!-- number in the section -->
				</xsl:attribute>
			</xsl:if>
			
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<!-- Note in text -->
	<xsl:template match="non-normative-note[not(ancestor::table-wrap or ancestor::fig)]" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			
			<xsl:variable name="section_parent" select="normalize-space(ancestor::sec[1]/@section)"/>
			<xsl:variable name="id_parent" select="normalize-space(ancestor::sec[1]/@id)"/>
			
			<xsl:if test="$metanorma_type = 'IEC' and $section_parent != ''">
				<xsl:attribute name="id_new">
					<!-- Example: not-3.5-1 -->
					<xsl:text>not-</xsl:text><xsl:value-of select="$section_parent"/><xsl:text>-</xsl:text>
					<xsl:number level="any" count="non-normative-note[ancestor::sec[1]/@id = $id_parent]"/> <!-- number in the section -->
				</xsl:attribute>
			</xsl:if>
			
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<!-- Note in table -->
	<xsl:template match="non-normative-note[ancestor::table-wrap]" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			
			<xsl:variable name="section_table_parent" select="normalize-space(ancestor::table-wrap[1]/@section)"/>
			<xsl:variable name="id_parent" select="normalize-space(ancestor::table-wrap[1]/@id)"/>
			
			<xsl:if test="$metanorma_type = 'IEC' and $section_table_parent != ''">
				<xsl:attribute name="id_new">
					<!-- Example: tno-3-1 -->
					<xsl:text>tno-</xsl:text><xsl:value-of select="$section_table_parent"/><xsl:text>-</xsl:text>
					<xsl:number level="any" count="non-normative-note[ancestor::table-wrap[1]/@id = $id_parent]"/> <!-- number in the table -->
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<!-- Note in figure -->
	<xsl:template match="non-normative-note[ancestor::fig]" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			
			<xsl:variable name="section_figure_parent" select="normalize-space(ancestor::fig[1]/@section)"/>
			<xsl:variable name="id_parent" select="normalize-space(ancestor::fig[1]/@id)"/>
			
			<xsl:if test="$metanorma_type = 'IEC' and $section_figure_parent != ''">
				<xsl:attribute name="id_new">
					<!-- Example: fno-3-1 -->
					<xsl:text>fno-</xsl:text><xsl:value-of select="$section_figure_parent"/><xsl:text>-</xsl:text>
					<xsl:number level="any" count="non-normative-note[ancestor::fig[1]/@id = $id_parent]"/> <!-- number in the table -->
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	
	<!-- Term section -->
	<xsl:template match="term-sec" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			<xsl:attribute name="id_new">
				<xsl:choose>
					<xsl:when test="$metanorma_type = 'IEC'">con-<xsl:value-of select="@section"/></xsl:when>
					<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">sec_<xsl:value-of select="@section"/></xsl:when>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<!-- Term entry -->
	<xsl:template match="tbx:termEntry" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			
			<xsl:variable name="section_parent" select="normalize-space(ancestor::term-sec[1]/@section)"/>
			<xsl:variable name="id_parent" select="normalize-space(ancestor::term-sec[1]/@id)"/>
			
			<xsl:attribute name="id_new">
				<xsl:choose>
					<xsl:when test="$metanorma_type = 'IEC'"><xsl:text>te-</xsl:text><xsl:value-of select="$section_parent"/></xsl:when> <!-- Example: te-3.1.3 -->
					<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'"><xsl:text>term_</xsl:text><xsl:value-of select="$section_parent"/></xsl:when> <!-- Example: term_3.1 -->
				</xsl:choose>
			</xsl:attribute>
			
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<!-- Term -->
	<xsl:template match="tbx:term" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			
			<xsl:if test="$metanorma_type = 'IEC'">
				<xsl:attribute name="id_new">
					<!-- Example: ter-sound_pressure -->
					<xsl:text>ter-</xsl:text><xsl:value-of select="translate(normalize-space(),' &#xa0;()','__')"/> <!-- 'sound pressure' to 'sound_pressure' -->
				</xsl:attribute>
			</xsl:if>
			
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	
	<!-- Note to entry -->
	<xsl:template match="tbx:note" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			
			<xsl:variable name="section_parent" select="normalize-space(ancestor::term-sec[1]/@section)"/>
			<xsl:variable name="id_parent" select="normalize-space(ancestor::term-sec[1]/@id)"/>
			
			<xsl:if test="$metanorma_type = 'IEC' and $section_parent != ''">
				<xsl:attribute name="id_new">
					<!-- Example: nte-3.1.3-1 -->
					<xsl:text>nte-</xsl:text><xsl:value-of select="$section_parent"/><xsl:text>-</xsl:text>
					<xsl:number level="any" count="tbx:note[ancestor::term-sec[1]/@id = $id_parent]"/> <!-- number in the section -->
				</xsl:attribute>
			</xsl:if>
			
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	
	
	<xsl:template match="mml:math" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			<xsl:if test="$metanorma_type = 'IEC'">
				<xsl:attribute name="id_new">
					<xsl:text>mml-m</xsl:text><xsl:number format="1" level="any"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="p" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			<xsl:if test="$metanorma_type = 'IEC'">
				<xsl:attribute name="id_new">
					<xsl:text>p-</xsl:text><xsl:number format="1" level="any"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="list-item" mode="id_generate">
		<xsl:copy>
			<xsl:apply-templates select="@*" mode="id_generate" />
			
			<xsl:variable name="section_parent" select="normalize-space(ancestor::sec[1]/@section)"/>
			<xsl:variable name="id_parent" select="normalize-space(ancestor::sec[1]/@id)"/>
			
			<xsl:if test="$metanorma_type = 'IEC' and $section_parent != ''">
				<xsl:attribute name="id_new">
					<xsl:text>lis-</xsl:text><xsl:value-of select="$section_parent"/>
					<xsl:for-each select="ancestor::list">
						<xsl:text>-L</xsl:text>
						
						<xsl:choose>
							<xsl:when test="ancestor::list-item"> <!-- if sub-list -->
								<xsl:for-each select="ancestor::list-item[1]">
									<xsl:number format="1"/> <!-- number in the parent list-item -->
								</xsl:for-each>
							</xsl:when>
							<xsl:otherwise>
								<xsl:number level="any" count="list[ancestor::sec[1]/@id = $id_parent]"/> <!-- number in the section -->
							</xsl:otherwise>
						</xsl:choose>
						
					</xsl:for-each>
					<xsl:text>-</xsl:text><xsl:number format="1"/> <!-- item number -->
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates select="node()" mode="id_generate" />
		</xsl:copy>
	</xsl:template>
	
	<!-- ===================================== -->
	<!-- unique fn in text only, and in array (informal table) -->
	<!-- ===================================== -->
	<!-- element 'footnote' is special wrapper for xref and fn -->
	<xsl:template match="footnote[not(ancestor::table-wrap or ancestor::fig)]" mode="id_generate"> <!-- footnotes_update -->
		
		<xsl:variable name="curr_text" select="normalize-space()"/>
		<xsl:variable name="curr_id" select="@id"/>
		
		<!-- get all footnotes in text -->
		<xsl:variable name="footnotes_all_">
			<xsl:for-each select="key('footnotes_in_text_iterator', 'all')">
				<xsl:copy-of select="."/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="footnotes_all" select="xalan:nodeset($footnotes_all_)"/>
		<!-- <footnotes_all><xsl:copy-of select="$footnotes_all"/></footnotes_all> -->
		
		<!-- get unique footnotes in text -->
		<xsl:variable name="footnotes_unique_">
			<xsl:for-each select="$footnotes_all/*[generate-id(.) = generate-id(key('footnotes_in_text', normalize-space())[1])]">
				<xsl:copy>
					<xsl:copy-of select="@*"/>
					<xsl:attribute name="number"><xsl:value-of select="position()"/></xsl:attribute>
					<xsl:copy-of select="node()"/>
				</xsl:copy>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="footnotes_unique" select="xalan:nodeset($footnotes_unique_)"/>
		<!-- <footnotes_unique><xsl:copy-of select="$footnotes_unique"/></footnotes_unique> -->
		
		<xsl:variable name="number_in_footnotes_unique" select="normalize-space($footnotes_unique/footnote[@id = $curr_id]/@number)"/>
		
		<xsl:choose>
			<xsl:when test="$number_in_footnotes_unique != ''"> <!-- if current fn is first occurrence -->
				<xsl:apply-templates select="xref" mode="footnotes_update_in_text">
					<xsl:with-param name="fn_number" select="$number_in_footnotes_unique"/>
				</xsl:apply-templates>
				<xsl:apply-templates select="fn" mode="footnotes_update_in_text">
					<xsl:with-param name="fn_number" select="$number_in_footnotes_unique"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<!-- if current fn is not first occurrence -->
				<!-- find unique footnote by current text -->
				<xsl:variable name="fn_number" select="$footnotes_unique/footnote[normalize-space() = $curr_text]/@number"/>
				<xsl:apply-templates select="xref" mode="footnotes_update_in_text">
					<xsl:with-param name="fn_number" select="$fn_number"/>
				</xsl:apply-templates>
				<!-- no need to put 'fn' -->
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template> <!-- footnote[not(ancestor::table-wrap or ancestor::fig)] -->
	

	<xsl:template match="xref" mode="footnotes_update_in_text">
		<xsl:param name="fn_number"/>
		<xref ref-type="fn">
			<xsl:attribute name="rid">
				<xsl:call-template name="generateFootnoteInText">
					<xsl:with-param name="fn_number" select="$fn_number"/>
				</xsl:call-template>
			</xsl:attribute>
			<xsl:call-template name="insert_fn_label">
				<xsl:with-param name="fn_number" select="$fn_number"/>
			</xsl:call-template>
		</xref>
	</xsl:template>
	
	<xsl:template match="fn" mode="footnotes_update_in_text">
		<xsl:param name="fn_number"/>
		<fn>
			<xsl:attribute name="id">
				<xsl:call-template name="generateFootnoteInText">
					<xsl:with-param name="fn_number" select="$fn_number"/>
				</xsl:call-template>
			</xsl:attribute>
			<label>
				<xsl:call-template name="insert_fn_label">
					<xsl:with-param name="fn_number" select="$fn_number"/>
				</xsl:call-template>
			</label>
			<!-- <xsl:copy-of select="node()[not(self::label)]"/> -->
			<xsl:apply-templates select="node()[not(self::label)]" mode="id_generate" />
		</fn>
	</xsl:template>
	
	<xsl:template name="insert_fn_label">
		<xsl:param name="fn_number"/>
		<xsl:choose>
			<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">
				<sup><xsl:value-of select="$fn_number"/>)</sup>
			</xsl:when>
			<xsl:when test="$metanorma_type = 'IEC'">
				<xsl:value-of select="$fn_number"/>
			</xsl:when>
			<xsl:otherwise>
				<sup><xsl:value-of select="$fn_number"/></sup>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="generateFootnoteInText">
		<xsl:param name="fn_number"/>
		<xsl:choose>
			<xsl:when test="$metanorma_type = 'IEC'">foo-<xsl:value-of select="$fn_number"/></xsl:when>
			<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">
				<xsl:if test="ancestor::array">table-</xsl:if>
				<xsl:text>fn_</xsl:text><xsl:value-of select="$fn_number"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="@id"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- ===================================== -->
	<!-- END: unique fn in text only -->
	<!-- ===================================== -->
	
	
	<!-- ===================================== -->
	<!-- unique fn in table -->
	<!-- ===================================== -->
	<xsl:template match="footnote[ancestor::table-wrap]" mode="id_generate"> <!-- footnotes_update -->
		
		<xsl:variable name="curr_text" select="normalize-space()"/>
		<xsl:variable name="curr_id" select="@id"/>
		
		<xsl:variable name="table_id" select="ancestor::table-wrap/@id"/>
		
		<!-- get all footnotes in text -->
		<xsl:variable name="footnotes_all_">
			<xsl:for-each select="key('footnotes_in_table_iterator', concat('all_tables_', $table_id))">
				<xsl:copy-of select="."/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="footnotes_all" select="xalan:nodeset($footnotes_all_)"/>
		<!-- <footnotes_all><xsl:copy-of select="$footnotes_all"/></footnotes_all> -->
		
		<xsl:variable name="footnotes_unique_">
			<xsl:for-each select="$footnotes_all/*">
				<xsl:variable name="text" select="normalize-space()"/>
				<xsl:if test="not(preceding-sibling::*[normalize-space() = $text])">
					<xsl:copy>
						<xsl:copy-of select="@*"/>
						<xsl:copy-of select="node()"/>
					</xsl:copy>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="footnotes_unique_numbered">
			<xsl:for-each select="xalan:nodeset($footnotes_unique_)/*">
				<xsl:copy>
					<xsl:copy-of select="@*"/>
					<xsl:attribute name="number"><xsl:value-of select="position()"/></xsl:attribute>
					<xsl:copy-of select="node()"/>
				</xsl:copy>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="footnotes_unique" select="xalan:nodeset($footnotes_unique_numbered)"/>
		<!-- <footnotes_unique><xsl:copy-of select="$footnotes_unique"/></footnotes_unique> -->
		
		<xsl:variable name="number_in_footnotes_unique" select="normalize-space($footnotes_unique/footnote[@id = $curr_id]/@number)"/>
		
		<xsl:variable name="table_number" select="ancestor::table-wrap/@section"/>
		
		<xsl:choose>
			<xsl:when test="$number_in_footnotes_unique != ''"> <!-- if current fn is first occurrence -->
				<xsl:apply-templates select="xref" mode="footnotes_update_in_table">
					<xsl:with-param name="table_number" select="$table_number"/>
					<xsl:with-param name="fn_number" select="$number_in_footnotes_unique"/>
				</xsl:apply-templates>
				<xsl:apply-templates select="fn" mode="footnotes_update_in_table">
					<xsl:with-param name="table_number" select="$table_number"/>
					<xsl:with-param name="fn_number" select="$number_in_footnotes_unique"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<!-- if current fn is not first occurrence -->
				<!-- find unique footnote by current text -->
				<xsl:variable name="fn_number" select="$footnotes_unique/footnote[normalize-space() = $curr_text]/@number"/>
				<xsl:apply-templates select="xref" mode="footnotes_update_in_table">
					<xsl:with-param name="table_number" select="$table_number"/>
					<xsl:with-param name="fn_number" select="$fn_number"/>
				</xsl:apply-templates>
				<!-- no need to put 'fn' -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template> <!-- footnote[ancestor::table-wrap] -->
	
	<xsl:template match="xref" mode="footnotes_update_in_table">
		<xsl:param name="table_number"/>
		<xsl:param name="fn_number"/>
		<xref ref-type="fn">
			<xsl:if test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'"> <!-- $metanorma_type = 'IEC' or  -->
				<xsl:attribute name="ref-type">table-fn</xsl:attribute>
			</xsl:if>
			<xsl:attribute name="rid">
				<xsl:call-template name="generateFootnoteInTable">
					<xsl:with-param name="table_number" select="$table_number"/>
					<xsl:with-param name="fn_number" select="$fn_number"/>
				</xsl:call-template>
			</xsl:attribute>
			<xsl:copy-of select="node()"/> <!-- a) b) ... -->
		</xref>
	</xsl:template>
	
	<xsl:template match="fn" mode="footnotes_update_in_table">
		<xsl:param name="table_number"/>
		<xsl:param name="fn_number"/>
		<fn>
			<xsl:attribute name="id">
				<xsl:call-template name="generateFootnoteInTable">
					<xsl:with-param name="table_number" select="$table_number"/>
					<xsl:with-param name="fn_number" select="$fn_number"/>
				</xsl:call-template>
			</xsl:attribute>
			<!-- <xsl:copy-of select="node()"/>  --><!-- a) b) ... -->
			<xsl:apply-templates select="node()" mode="id_generate" />
		</fn>
	</xsl:template>
	
	<xsl:template name="generateFootnoteInTable">
		<xsl:param name="table_number"/>
		<xsl:param name="fn_number"/>
		<xsl:choose>
			<xsl:when test="$metanorma_type = 'IEC'">tfn-<xsl:value-of select="$table_number"/>-<xsl:value-of select="$fn_number"/></xsl:when>
			<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">table-fn_<xsl:value-of select="$table_number"/>.<xsl:value-of select="$fn_number"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="@id"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- ===================================== -->
	<!-- END: unique fn in table -->
	<!-- ===================================== -->
	
	
	<!-- ===================================== -->
	<!-- unique fn in figure -->
	<!-- ===================================== -->
	<xsl:template match="footnote[ancestor::fig]" mode="id_generate"> <!-- footnotes_update --> 
		
		<xsl:variable name="curr_text" select="normalize-space()"/>
		<xsl:variable name="curr_id" select="@id"/>
		
		<xsl:variable name="figure_id" select="ancestor::fig/@id"/>
		
		<!-- get all footnotes in text -->
		<xsl:variable name="footnotes_all_">
			<xsl:for-each select="key('footnotes_in_figure_iterator', concat('all_figures_', $figure_id))">
				<xsl:copy-of select="."/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="footnotes_all" select="xalan:nodeset($footnotes_all_)"/>
		<!-- <footnotes_all><xsl:copy-of select="$footnotes_all"/></footnotes_all> -->
		
		<xsl:variable name="footnotes_unique_">
			<xsl:for-each select="$footnotes_all/*">
				<xsl:variable name="text" select="normalize-space()"/>
				<xsl:if test="not(preceding-sibling::*[normalize-space() = $text])">
					<xsl:copy>
						<xsl:copy-of select="@*"/>
						<xsl:copy-of select="node()"/>
					</xsl:copy>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="footnotes_unique_numbered">
			<xsl:for-each select="xalan:nodeset($footnotes_unique_)/*">
				<xsl:copy>
					<xsl:copy-of select="@*"/>
					<xsl:attribute name="number"><xsl:value-of select="position()"/></xsl:attribute>
					<xsl:copy-of select="node()"/>
				</xsl:copy>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="footnotes_unique" select="xalan:nodeset($footnotes_unique_numbered)"/>
		<!-- <footnotes_unique><xsl:copy-of select="$footnotes_unique"/></footnotes_unique> -->
		
		<xsl:variable name="number_in_footnotes_unique" select="normalize-space($footnotes_unique/footnote[@id = $curr_id]/@number)"/>
		
		<xsl:variable name="figure_number" select="ancestor::fig/@section"/>
		
		<xsl:choose>
			<xsl:when test="$number_in_footnotes_unique != ''"> <!-- if current fn is first occurrence -->
				<xsl:apply-templates select="xref" mode="footnotes_update_in_figure">
					<xsl:with-param name="figure_number" select="$figure_number"/>
					<xsl:with-param name="fn_number" select="$number_in_footnotes_unique"/>
				</xsl:apply-templates>
				<xsl:apply-templates select="fn" mode="footnotes_update_in_figure">
					<xsl:with-param name="figure_number" select="$figure_number"/>
					<xsl:with-param name="fn_number" select="$number_in_footnotes_unique"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<!-- if current fn is not first occurrence -->
				<!-- find unique footnote by current text -->
				<xsl:variable name="fn_number" select="$footnotes_unique/footnote[normalize-space() = $curr_text]/@number"/>
				<xsl:apply-templates select="xref" mode="footnotes_update_in_figure">
					<xsl:with-param name="figure_number" select="$figure_number"/>
					<xsl:with-param name="fn_number" select="$fn_number"/>
				</xsl:apply-templates>
				<!-- no need to put 'fn' -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template> <!-- footnote[ancestor::fig] -->
	
	<xsl:template match="xref" mode="footnotes_update_in_figure">
		<xsl:param name="figure_number"/>
		<xsl:param name="fn_number"/>
		<xref ref-type="fn">
			<xsl:attribute name="rid">
				<xsl:call-template name="generateFootnoteInFigure">
					<xsl:with-param name="figure_number" select="$figure_number"/>
					<xsl:with-param name="fn_number" select="$fn_number"/>
				</xsl:call-template>
			</xsl:attribute>
			<xsl:copy-of select="node()"/> <!-- a) b) ... -->
		</xref>
	</xsl:template>
	
	<xsl:template match="fn" mode="footnotes_update_in_figure">
		<xsl:param name="figure_number"/>
		<xsl:param name="fn_number"/>
		<fn>
			<xsl:attribute name="id">
				<xsl:call-template name="generateFootnoteInFigure">
					<xsl:with-param name="figure_number" select="$figure_number"/>
					<xsl:with-param name="fn_number" select="$fn_number"/>
				</xsl:call-template>
			</xsl:attribute>
			<!-- <xsl:copy-of select="node()"/> --> <!-- a) b) ... -->
			<xsl:apply-templates select="node()" mode="id_generate" />
		</fn>
	</xsl:template>
	
	<xsl:template name="generateFootnoteInFigure">
		<xsl:param name="figure_number"/>
		<xsl:param name="fn_number"/>
		<xsl:choose>
			<xsl:when test="$metanorma_type = 'IEC'">figfn-<xsl:value-of select="$figure_number"/>-<xsl:value-of select="$fn_number"/></xsl:when>
			<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">figure-fn_<xsl:value-of select="$figure_number"/>.<xsl:value-of select="$fn_number"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="@id"/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- ===================================== -->
	<!-- END: unique fn in figure -->
	<!-- ===================================== -->
	
	<!-- ================================================== -->
	<!-- END: id generation for IEC and ISO with Guidelines rules -->
	<!-- ================================================== -->
	
	<!-- ================================== -->
	<!-- id replacement for IEC/ISO ID scheme -->
	<!-- ================================== -->
	<xsl:template match="@*|node()" mode="id_replace">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="id_replace" />
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="*[@id_new]" mode="id_replace" priority="2">
		<xsl:copy>
			<xsl:choose>
				<xsl:when test="normalize-space(@id_new) != ''">
					<xsl:apply-templates select="@*[not(local-name() = 'id_new')]" mode="id_replace"/>
					<xsl:attribute name="id"><xsl:value-of select="@id_new"/></xsl:attribute>
				</xsl:when>
				<xsl:otherwise>
					  <!-- no need create id for 'Key' tables for figures, formulas -->
					<xsl:apply-templates select="@*[not(local-name() = 'id_new' or local-name() = 'id')]" mode="id_replace"/>
				</xsl:otherwise>
			</xsl:choose>
			
			<xsl:apply-templates select="node()" mode="id_replace" />
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="@section[not(parent::element)]" mode="id_replace" priority="2"/> <!-- the tag 'element' is using for debug purposes -->
	
	<!-- xref/@rid, eref/@bibitemid -->
	<xsl:template match="@rid | @bibitemid | @target" mode="id_replace" priority="2">
		<xsl:variable name="reference" select="."/>
		<xsl:variable name="id_new" select="key('element_by_id', $reference)/@id_new"/>
		<xsl:attribute name="{local-name()}">
			<xsl:value-of select="$id_new"/>
			<xsl:if test="normalize-space($id_new) = ''">
				<xsl:value-of select="$reference"/>
			</xsl:if>
		</xsl:attribute>
	</xsl:template>
	
	<!-- named-content/@xlink:href -->
	<!-- Example: <named-content xlink:href="#paddy" -->
	<xsl:template match="named-content/@xlink:href" mode="id_replace" priority="2">
		<xsl:variable name="reference" select="substring-after(.,'#')"/>
		<xsl:variable name="id_new" select="key('element_by_id', $reference)/@id_new"/>
		<xsl:attribute name="xlink:href">
			<xsl:text>#</xsl:text>
			<xsl:value-of select="$id_new"/>
			<xsl:if test="normalize-space($id_new) = ''">
				<xsl:value-of select="$reference"/>
			</xsl:if>
		</xsl:attribute>
	</xsl:template>
	
	
	<!-- remove @id from 'list' and 'p' if starts with '_' -->
	<xsl:template match="*[self::list or self::p or self::non-normative-note]/@id[starts-with(., '_')]" mode="id_replace"/>
	
	<!-- ================================== -->
	<!-- END: id replacement for IEC/ISO ID scheme -->
	<!-- ================================== -->
	
	
	
	
	<xsl:template match="term">
		<xsl:variable name="current_id">
			<xsl:call-template name="getId"/>
		</xsl:variable>
		
		<xsl:variable name="term_presentation_" select="$xml_presentation_catalog//term[@id = current()/@id]"/>
		<xsl:variable name="term_presentation" select="xalan:nodeset($term_presentation_)"/>
		
		<xsl:variable name="section">
			<xsl:choose>
				<xsl:when test="$term_presentation/node()">
					<xsl:value-of select="$term_presentation/@section"/>
				</xsl:when>
				<xsl:when test="normalize-space(name) != '' and  normalize-space(translate(name, '0123456789.', '')) = ''">
					<xsl:value-of select="name"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="@section"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
	
		<term-sec id="sec_{$section}"><!-- id="{$current_id}" -->
			<xsl:call-template name="addSectionAttribute"/>
			
			<xsl:apply-templates select="review"/>
			
			<xsl:call-template name="insert_label">
				<xsl:with-param name="label" select="$section"/>
				<xsl:with-param name="isAddition" select="count(title/node()[normalize-space() != ''][1][self::add]) = 1"/>
			</xsl:call-template>
			
			<tbx:termEntry id="{$current_id}">
				<tbx:langSet>
				
					<xsl:attribute name="xml:lang">
						<xsl:choose>
							<xsl:when test=".//expression/@language">
								<xsl:value-of select=".//expression/@language"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="ancestor::*[contains(local-name(), '-standard')]/bibdata/language"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					
					<xsl:apply-templates select="domain"/>
					
					<xsl:apply-templates select="node()[not(self::termexample or self::termnote or self::termsource or 
																										self::preferred or self::admitted or self::deprecates or self::domain or 
																										self::term or self::review)]"/>
					
					<xsl:apply-templates select="termexample"/>
					
					<xsl:apply-templates select="termnote"/>
					
					<xsl:apply-templates select="termsource"/>
					
					<xsl:apply-templates select="preferred | admitted | deprecates"/>
					
				</tbx:langSet>
			</tbx:termEntry>
			
			<xsl:apply-templates select="term"/>
			
		</term-sec>
	</xsl:template>
	
	<xsl:template match="definition">
		<tbx:definition>
			<xsl:apply-templates />
			<xsl:apply-templates select="following-sibling::ul | following-sibling::ol" mode="definition_list"/>
		</tbx:definition>
	</xsl:template>
	
	<xsl:template match="termexample">
		<tbx:example>
			<xsl:apply-templates />
		</tbx:example>
	</xsl:template>
	
	<xsl:template match="termnote">
		<tbx:note>
			<xsl:apply-templates />
		</tbx:note>
	</xsl:template>
	
	<!-- =============== -->
	<!-- tbx:see generation -->
	<!-- =============== -->
	<xsl:variable name="text_see_prefix_regex">^(See |Voir |См. )(.*)</xsl:variable>
	<xsl:variable name="text_see_suffix_regex">(.*)( for more information.| pour plus d'informations.| для дополнительной информации.)</xsl:variable>
	
	<xsl:template match="termnote[count(*) = 1 and 
			java:org.metanorma.utils.RegExHelper.matches($text_see_prefix_regex, normalize-space()) = 'true' and 
			java:org.metanorma.utils.RegExHelper.matches($text_see_suffix_regex, normalize-space()) = 'true']">
			<!--  and 
			(java:endsWith(java:java.lang.String.new(normalize-space()), $text_see_suffix_en) or java:endsWith(java:java.lang.String.new(normalize-space()), $text_see_suffix_fr)  java:endsWith(java:java.lang.String.new(normalize-space()), $text_see_suffix_ru)) -->
			
		<xsl:variable name="text_see__">
			<tbx:see>
				<xsl:apply-templates />
			</tbx:see>
		</xsl:variable>
		<xsl:variable name="text_see_">
			<xsl:apply-templates select="xalan:nodeset($text_see__)" mode="see"/>
		</xsl:variable>
		<xsl:variable name="text_see" select="xalan:nodeset($text_see_)"/>
		
		<xsl:choose>
			<xsl:when test="count($text_see/*/node()[normalize-space() != '']) = 1 and $text_see/*/xref">
				<!-- Example: <tbx:see target="sec_A"/> -->
				<tbx:see target="{$text_see/*/xref/@rid}"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- Example:  <tbx:see>Figures 1 et 2.</tbx:see> or more complex with text and elements -->
				<xsl:copy-of select="$text_see"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="@*|node()" mode="see">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="see" />
		</xsl:copy>
	</xsl:template>
	
	<!-- last text() in termnote -->
	<xsl:template match="tbx:see/text()[java:org.metanorma.utils.RegExHelper.matches($text_see_suffix_regex, .) = 'true' and not(following-sibling::node())]" mode="see">
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.), $text_see_suffix_regex, '$1')"/>
	</xsl:template>
	
	<!-- first text() in termnote -->
	<xsl:template match="tbx:see/text()[java:org.metanorma.utils.RegExHelper.matches($text_see_prefix_regex, .) = 'true' and not(preceding-sibling::node())]" mode="see">
		<xsl:variable name="text_" select="java:replaceAll(java:java.lang.String.new(.), $text_see_prefix_regex, '$2')"/>
		<xsl:choose>
			<xsl:when test="not(following-sibling::node()) and 
				java:org.metanorma.utils.RegExHelper.matches($text_see_suffix_regex, .) = 'true'">
				<xsl:value-of select="java:replaceAll(java:java.lang.String.new($text_), $text_see_suffix_regex, '$1')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$text_"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- =============== -->
	<!-- END: tbx:see generation -->
	<!-- =============== -->
	
	<xsl:template match="amend//termnote[not(ancestor::term)]">
		<non-normative-note>
			<p>
				<xsl:apply-templates />
			</p>
		</non-normative-note>
	</xsl:template>
	
	<xsl:template match="termsource">
		<tbx:source>
			<xsl:variable name="source">
				<xsl:apply-templates />
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$metanorma_type = 'ISO' or $metanorma_type = 'BSI'">
					<!-- 'std' inside tbx:source should be omitted for ISO. -->
					<xsl:value-of select="$source"/> <!-- just text -->
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="$source"/>
				</xsl:otherwise>
			</xsl:choose>
		</tbx:source>
	</xsl:template>
	
	<xsl:template match="domain">
		<tbx:subjectField>
			<xsl:apply-templates />
		</tbx:subjectField>
	</xsl:template>
	
	<xsl:template match="preferred | admitted | deprecates"> <!--  mode="termEntry" -->
		
		<!-- <xsl:variable name="current_id">
			<xsl:call-template name="getId"/>
		</xsl:variable>
		
		<xsl:variable name="id" select="$elements//element[@source_id = $current_id]/@id"/>	 -->
		<!-- <xsl:variable name="id"><xsl:call-template name="getId"/></xsl:variable> -->
		<xsl:variable name="number"><xsl:number count="preferred | admitted | deprecates"/></xsl:variable>
		<xsl:variable name="id">
			<xsl:variable name="element_name" select="local-name()"/>
			<xsl:for-each select="ancestor::term[1]">
				<xsl:call-template name="getId"/><xsl:text>-</xsl:text><xsl:value-of select="$number"/>_<xsl:value-of select="$element_name"/>
			</xsl:for-each>
		</xsl:variable>
		
		<tbx:tig>
			<xsl:if test="normalize-space($id) != ''">
				<xsl:attribute name="id"><xsl:value-of select="$id"/></xsl:attribute>
			</xsl:if>
			<tbx:term><xsl:apply-templates /></tbx:term>
			<tbx:partOfSpeech>
				<xsl:attribute name="value">
					<xsl:choose>
						<xsl:when test=".//grammar/isAdjective = 'true'">adj</xsl:when>
						<xsl:when test=".//grammar/isAdverb = 'true'">adv</xsl:when>
						<xsl:when test=".//grammar/isNoun = 'true'">noun</xsl:when>
						<xsl:when test=".//grammar/isVerb = 'true'">verb</xsl:when>
						<!-- <xsl:when test=".//grammar/isPreposition = 'true'">preposition</xsl:when>--> <!-- not supported in XSD -->
						<!-- <xsl:when test=".//grammar/isParticiple = 'true'">participle</xsl:when> --><!-- not supported in XSD -->
						<xsl:otherwise>noun</xsl:otherwise> <!-- default value -->
					</xsl:choose>
				</xsl:attribute>
			</tbx:partOfSpeech>
			
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
					<xsl:when test="$metanorma_type != 'IEC' and $element_name = 'preferred' and not(following-sibling::admitted or preceding-sibling::admitted or
					following-sibling::deprecates or preceding-sibling::deprecates)"></xsl:when>
					<xsl:otherwise>
						<tbx:normativeAuthorization value="{$normativeAuthorization}"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
			
			<xsl:variable name="value">
				<xsl:choose>
					<xsl:when test="letter-symbol">symbol</xsl:when>
					<xsl:when test=".//abbreviation-type = 'acronym'">acronym</xsl:when>
					<xsl:when test=".//expression/@type = 'abbreviation'">abbreviation</xsl:when>
					<xsl:when test="($metanorma_type = 'IEC' or $metanorma_type = 'ISO' or $metanorma_type = 'BSI') and .//expression/@type = 'full'">fullForm</xsl:when> <!-- or normalize-space(.//expression/@type) = '') -->
					<xsl:when test="@type = 'full'">variant</xsl:when>
					<xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:if test="normalize-space($value) != ''">
				<tbx:termType value="{$value}"/>
			</xsl:if>
			
			<xsl:apply-templates select="field-of-application" mode="usageNote"/>
		</tbx:tig>
	</xsl:template>
	
	<xsl:template match="field-of-application" priority="2" mode="usageNote">
		<tbx:usageNote><xsl:apply-templates/></tbx:usageNote>
	</xsl:template>
	
	<xsl:template match="abbreviation-type"/>
	<!-- ===================== -->
	<!-- tbx:entailedTerm -->
	<!-- ===================== -->
	<!-- Conversion from: -->
	<!-- <em>objectives</em> (<xref target="term-objective"><strong>3.8</strong></xref>) -->
	<!-- to: -->
	<!-- <tbx:entailedTerm target="term_3.8">objectives (3.8)</tbx:entailedTerm> -->
	<!-- for em, when next is xref -->
	<xsl:template match="em[following-sibling::node()[1][. = ' ('] and following-sibling::*[1][self::xref]]" priority="2">
		<tbx:entailedTerm target="{following-sibling::*[1]/@target}">
			<xsl:apply-templates />
			<xsl:apply-templates select="following-sibling::*[1]" mode="em_xref"/><!-- get xref -->
		</tbx:entailedTerm>
	</xsl:template>
	
	<!-- for xref, when previous is em -->
	<xsl:template match="xref" mode="em_xref">
		<xsl:text> </xsl:text>
		<!-- preceding-sibling-text='<xsl:value-of select="normalize-space(preceding-sibling::node()[1])"/>' -->
		<xsl:if test="normalize-space(preceding-sibling::node()[1]) ='('">(</xsl:if>
		<xsl:value-of select="normalize-space()"/>
		<xsl:if test="$isSemanticXML = 'true'"> <!-- normalize-space() is empty for semantic xml, therefore we need 'calculate' term number -->
			<xsl:variable name="xref_target" select="@target"/>
			<xsl:value-of select="$elements//element[@id = $xref_target]/@section"/>
		</xsl:if>
		<xsl:if test="substring(normalize-space(following-sibling::node()[1]),1,1) =')'">)</xsl:if>
		<!-- following-sibling-text='<xsl:value-of select="following-sibling::node()[1]"/>' -->
	</xsl:template>
	
	<xsl:template match="xref[preceding-sibling::node()[1][. = ' ('] and preceding-sibling::*[1][self::em]]" priority="2"/>
	
	<!-- remove '(' between em and xref -->
	<xsl:template match="text()[normalize-space() = '('][preceding-sibling::*[1][self::em] and following-sibling::*[1][self::xref]]"/>
	<!-- remove ')' after em and xref -->
	<xsl:template match="text()[substring(normalize-space(),1,1) = ')'][preceding-sibling::*[1][self::xref] and preceding-sibling::*[2][self::em]]">
		<xsl:value-of select="substring-after(., ')')"/>
	</xsl:template>
	
	<xsl:template match="concept[eref[@bibitemid]]">
		<tbx:entailedTerm xtarget="{eref/@bibitemid}"><xsl:apply-templates select="renderterm/node()"/></tbx:entailedTerm>
	</xsl:template>
	
	<!-- Cross-references between terminological entries or terms within the Terms and definitions clause can be tagged as <tbx:entailedTerm>. This element should only be used in child elements of <tbx:termEntry>. -->
	<xsl:template name="insert_entailedTerm">
		<tbx:entailedTerm target="{xref/@target}">
			<xsl:choose>
				<xsl:when test="renderterm">
					<xsl:value-of select="renderterm"/>
					
					<xsl:variable name="xref_target" select="xref/@target"/>
					<xsl:variable name="element_xref_" select="$elements//element[@source_id = $xref_target]"/>
					<xsl:variable name="element_xref" select="xalan:nodeset($element_xref_)"/>
					<xsl:variable name="section" select="$element_xref/@section"/>
					<xsl:text> (</xsl:text><xsl:value-of select="$section"/><xsl:text>)</xsl:text>
					
				</xsl:when>
				<xsl:otherwise>
					<xsl:attribute name="target"><xsl:value-of select=".//tt[2]"/></xsl:attribute>
					<xsl:value-of select=".//tt[1]"/>
				</xsl:otherwise>
			</xsl:choose>
		</tbx:entailedTerm>
	</xsl:template>
	
	<!-- ===================== -->
	<!-- END tbx:entailedTerm -->
	<!-- ===================== -->
	
	
</xsl:stylesheet>