<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
			xmlns:mml="http://www.w3.org/1998/Math/MathML" 
			xmlns:xlink="http://www.w3.org/1999/xlink" 
			xmlns:xalan="http://xml.apache.org/xalan" 
			xmlns:java="http://xml.apache.org/xalan/java" 
			xmlns:metanorma-class="xalan://org.metanorma.utils.RegExHelper"
			exclude-result-prefixes="xalan java metanorma-class" 
			version="1.0">

	<xsl:output version="1.0" method="xml" encoding="UTF-8" indent="yes"/>
	
	<xsl:param name="debug">false</xsl:param>
	<xsl:param name="outputformat">IEEE</xsl:param>
	
	<xsl:include href="mn2xml.xsl"/>
	
	<xsl:template match="/*" mode="xml">
		
		<standards-document xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:xlink="http://www.w3.org/1999/xlink">
		
			<!-- attributes for the element standards-document -->
			<xsl:variable name="stage" select="bibdata/status/stage"/>
			<xsl:attribute name="article-status">
				<xsl:choose>
					<xsl:when test="$stage = 'active' or $stage = 'draft' or $stage = 'developing'">active</xsl:when>
					<xsl:otherwise>inactive</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			
			<xsl:variable name="doctype" select="bibdata/ext/doctype"/>
			
			<xsl:variable name="subdoctype" select="bibdata/ext/subdoctype[normalize-space(@language) = '']"/> <!-- amendment, corrigendum, erratum -->
			
			<xsl:attribute name="content-type">
				<xsl:choose>
					<xsl:when test="$subdoctype = 'amendment' or $subdoctype = 'corrigendum'"><xsl:value-of select="$subdoctype"/></xsl:when>
					<xsl:when test="$subdoctype = 'erratum'">errata</xsl:when>
					<xsl:when test="$doctype = 'standard' or $doctype = 'guide' or $doctype = 'recommended-practice'"><xsl:value-of select="$doctype"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="$doctype"/></xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			
			<xsl:attribute name="dtd-version">1.7</xsl:attribute>
			
			<xsl:variable name="open-access" select="normalize-space(misc-container/semantic-metadata/open-access)"/>
			<xsl:if test="$open-access != ''">
				<xsl:attribute name="open-access"><xsl:value-of select="$open-access"/></xsl:attribute>
			</xsl:if>
			
			<xsl:attribute name="revision">
				<xsl:choose>
					<xsl:when test="bibdata/relation[@type='updates']">yes</xsl:when>
					<xsl:otherwise>no</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			
			<!-- To do: active-reserved, inactive-reserved, inactive-superseded, inactive-withdrawn -->
			<xsl:attribute name="std-status">
				<xsl:choose>
					<xsl:when test="$stage = 'draft' and date[@type='issued']">approved-draft</xsl:when>
					<xsl:when test="$stage = 'draft'">unapproved-draft</xsl:when>
					<xsl:otherwise>active</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
		
			<xsl:call-template name="insertXMLcontent"/>
		</standards-document>

	</xsl:template>

	<!-- ============= -->
	<!-- IEEE bibdata -->
	<!-- ============= -->
	<xsl:template match="bibdata" mode="front_ieee">
		<xsl:param name="element_name"/>
		
		<!-- <std-meta> -->
		<xsl:element name="{$element_name}">
			
			<xsl:variable name="bibdata"><xsl:copy-of select="."/></xsl:variable> <!-- for using bibdata in another context in 'for-each' iterations -->
			
			<xsl:variable name="std_prefix">IEEE Std </xsl:variable>
			<xsl:variable name="number" select="docidentifier[@type = 'IEEE'][not(@scope)]"/>
			<xsl:variable name="year" select="substring(normalize-space(date[@type = 'issued']),1,4)"/> <!-- approval date -->
			
			<std-id std-id-type="doi"><xsl:value-of select="../misc-container/semantic-metadata/std-id-doi"/></std-id>
			
			<std-designation content-type="full"><xsl:value-of select="concat($std_prefix,$number,'-',$year)"/></std-designation> <!-- Example: IEEE Std 1127-2013 -->
			<std-designation content-type="full-tm"><xsl:value-of select="concat($std_prefix,$number,$trademark,'-',$year)"/></std-designation> <!-- Example: IEEE Std 1127&#x2122;-2013 -->
			<std-designation content-type="std-num"><xsl:value-of select="concat($number,'-',$year)"/></std-designation> <!-- Example: 1127-2013 -->
			<std-designation content-type="std-num-tm"><xsl:value-of select="concat($number,$trademark,'-',$year)"/></std-designation> <!-- Example:  1127&#x2122;-2013-->
			<std-designation content-type="norm"/>
			
			<xplore-article-id><xsl:value-of select="../misc-container/semantic-metadata/xplore-article-id"/></xplore-article-id>
			<xsl:variable name="xplore-issue" select="normalize-space(../misc-container/semantic-metadata/xplore-issue)"/>
			<xsl:if test="$xplore-issue != ''">
				<xplore-issue><xsl:value-of select="$xplore-issue"/></xplore-issue>
			</xsl:if>
			<xplore-pub-id><xsl:value-of select="../misc-container/semantic-metadata/xplore-pub-id"/></xplore-pub-id>
			
			<!-- <product-num publication-format="online"> -->
			<xsl:apply-templates select="docidentifier[@type = 'IEEE' and @scope = 'PDF']" mode="front_ieee"/>
			<!-- <product-num publication-format="print"> -->
			<xsl:apply-templates select="docidentifier[@type = 'IEEE' and @scope = 'print']" mode="front_ieee"/>
			
			<xsl:apply-templates select="ext/ics/code" mode="front_ieee"/>
			
			<xsl:variable name="doctype_str">
				<xsl:call-template name="capitalize">
					<xsl:with-param name="str" select="translate(ext/doctype,'-',' ')"/>
				</xsl:call-template>
			</xsl:variable>
			
			<xsl:variable name="title">
				<xsl:text>IEEE </xsl:text>
				<xsl:value-of select="$doctype_str"/>
				<xsl:text> for </xsl:text>
				<xsl:apply-templates select="title[not(@type='provenance')]/node()"/>
			</xsl:variable>
			
			<std-title-group>
				<std-main-title><xsl:copy-of select="$title"/></std-main-title>
				<std-full-title><xsl:copy-of select="$title"/></std-full-title>
				<xsl:if test="relation[@type = 'updates'] or ../misc-container/semantic-metadata/related-article-edition">
					<alt-title>
						<!-- <related-article related-article-type="revision-of">(Revision of <std>IEEE Std 1127-1998</std>)</related-article> -->
						<xsl:apply-templates select="relation[@type = 'updates']" mode="front_ieee"/>
						<!-- <related-article related-article-type="edition"><edition>2012 Edition</edition></related-article> -->
						<xsl:apply-templates select="../misc-container/semantic-metadata/related-article-edition"/>
					</alt-title>
				</xsl:if>
			</std-title-group>
			
			<xsl:if test="../misc-container/semantic-metadata/collab-type-logo or ../misc-container/semantic-metadata/collab or ../misc-container/semantic-metadata/collab-type-accredited-by">
				<contrib-group>
					<contrib id="contrib-collab1">
						<collab-alternatives>
							<xsl:apply-templates select="../misc-container/semantic-metadata/collab-type-logo"/>
							<xsl:apply-templates select="../misc-container/semantic-metadata/collab"/>
							<xsl:apply-templates select="../misc-container/semantic-metadata/collab-type-accredited-by"/>
						</collab-alternatives>
					</contrib>
				</contrib-group>
			</xsl:if>
			
			<!-- contrib-group -->
			<xsl:apply-templates select="../boilerplate/legal-statement//clause[@id = 'boilerplate-participants' or title = 'Participants']/clause[
					@id = 'boilerplate-participants-wg' or title = 'Working group' or
					@id = 'boilerplate-participants-bg' or title = 'Balloting group' or
					@id = 'boilerplate-participants-sb' or title = 'Standards board']" mode="contrib-group"/>
			
			<!-- <isbn publication-format="online" specific-use="ISBN-13"> -->
			<xsl:apply-templates select="docidentifier[@type = 'ISBN' and @scope = 'PDF']" mode="front_ieee"/>
			<!-- <isbn publication-format="print" specific-use="ISBN-13"> -->
			<xsl:apply-templates select="docidentifier[@type = 'ISBN' and @scope = 'print']" mode="front_ieee"/>
			
			<!-- <publisher> -->
			<xsl:apply-templates select="../boilerplate/feedback-statement/clause[1]/p[1]" mode="front_ieee_publisher"/>
			
			<xsl:if test="ext/editorialgroup/committee or ext/editorialgroup/society">
				<std-sponsor>
					<!-- <xsl:text>Sponsor </xsl:text> -->
					<xsl:variable name="items_">
						<xsl:apply-templates select="ext/editorialgroup/committee" mode="front_ieee"/>
						<xsl:apply-templates select="ext/editorialgroup/society" mode="front_ieee"/>
					</xsl:variable>
					<xsl:variable name="items" select="xalan:nodeset($items_)"/>
					<xsl:for-each select="$items/*[normalize-space() != '']">
						<xsl:copy-of select="."/>
						<xsl:if test="position() != last()">
							<xsl:text> of the </xsl:text>
						</xsl:if>
					</xsl:for-each>
				</std-sponsor>
			</xsl:if>
			
			<xsl:apply-templates select="../misc-container/semantic-metadata/partner-secretariat"/>
			
			<xsl:apply-templates select="date[@type = 'published'][1]" mode="front_ieee"/>
			
			<xsl:apply-templates select="date[@type = 'issued'][1]" mode="front_ieee"/>
			
			<xsl:apply-templates select="date[@type = 'reaffirm'][1]" mode="front_ieee"/>
			
			<!-- <supplementary-material) -->
			<xsl:apply-templates select="../boilerplate/feedback-statement/clause[last()]" mode="front_ieee_supplementary_material"/>
			
			<permissions>
				<xsl:apply-templates select="../boilerplate/feedback-statement/clause[2]" mode="front_ieee_permissions"/>
				<xsl:apply-templates select="copyright/from" mode="front_ieee_permissions"/>
				<xsl:apply-templates select="copyright/owner" mode="front_ieee_permissions"/>
				<xsl:apply-templates select="../boilerplate/feedback-statement/clause[3]" mode="front_ieee_permissions_license"/>
			</permissions>
			
			<xsl:apply-templates select="abstract" mode="front_ieee"/>
			
			<xsl:apply-templates select="../misc-container/semantic-metadata/*[starts-with(local-name(), 'keywords-')]"/>
			<xsl:apply-templates select="keyword[1]">
				<xsl:with-param name="process">true</xsl:with-param>
			</xsl:apply-templates>
			
			<!-- funding-group -->
			<xsl:variable name="funding-group_">
				<xsl:apply-templates select="../misc-container/semantic-metadata/funding-source-institution |
									../misc-container/semantic-metadata/funding-source-institution-id |
									../misc-container/semantic-metadata/award-group-id |
									../misc-container/semantic-metadata/funding-statement"/>
			</xsl:variable>
			<xsl:variable name="funding-group" select="xalan:nodeset($funding-group_)"/>
			<xsl:if test="$funding-group/*">
				<funding-group>
					<xsl:if test="$funding-group/institution or
									$funding-group/institution-id or
									$funding-group/award-id">
						<award-group>
							<xsl:if test="$funding-group/institution or
									$funding-group/institution-id">
								<funding-source>
									<institution-wrap>
										<xsl:copy-of select="$funding-group/institution"/>
										<xsl:copy-of select="$funding-group/institution-id"/>
									</institution-wrap>
								</funding-source>
							</xsl:if>
							<xsl:copy-of select="$funding-group/award-id"/>
						</award-group>
					</xsl:if>
					<xsl:copy-of select="$funding-group/funding-statement"/>
				</funding-group>
			</xsl:if>
			
			<counts>
				<fig-count count="{count(//figure)}"/>
				<table-count count="{count(//table)}"/>
				<equation-count count="{count(//disp-formula)}"/>
				<ref-count count="{count(//xref)}"/>
				<!-- <page-count count="50"/> -->
			</counts>
			
		</xsl:element> <!-- </std-meta> -->
		
		<!-- <notes> -->
		<xsl:apply-templates select="../boilerplate/legal-statement" mode="front_ieee_notes"/>
		<!-- <sec id="participants1"><title>Participants</title> ... -->
		<xsl:apply-templates select="../boilerplate/legal-statement/clause[@id = 'boilerplate-participants']" mode="front_ieee_participants"/>
		
	</xsl:template>
	
	<xsl:template match="docidentifier[@type = 'IEEE' and @scope = 'PDF']" mode="front_ieee">
		<product-num publication-format="online"><xsl:value-of select="."/></product-num>
	</xsl:template>
	
	<xsl:template match="docidentifier[@type = 'IEEE' and @scope = 'print']" mode="front_ieee">
		<product-num publication-format="print"><xsl:value-of select="."/></product-num>
	</xsl:template>
	
	<xsl:template match="docidentifier[@type = 'ISBN' and @scope = 'PDF']" mode="front_ieee">
		<isbn publication-format="online" specific-use="ISBN-13"><xsl:value-of select="."/></isbn>
	</xsl:template>
	
	<xsl:template match="docidentifier[@type = 'ISBN' and @scope = 'print']" mode="front_ieee">
		<isbn publication-format="print" specific-use="ISBN-13"><xsl:value-of select="."/></isbn>
	</xsl:template>
	
	
	<xsl:template match="ics/code" mode="front_ieee">
		<xsl:variable name="pos"><xsl:number/></xsl:variable>
		<ics>
			<ics-code><xsl:value-of select="."/></ics-code>
			<!-- <xsl:apply-templates select="ancestor::bibdata/../misc-container/semantic-metadata[ics-desc][$pos]/ics-desc"/> -->
		</ics>
	</xsl:template>
	
	<xsl:template match="semantic-metadata/ics-desc">
		<ics-desc><xsl:value-of select="."/></ics-desc>
	</xsl:template>
	
	<xsl:template match="relation[@type = 'updates']" mode="front_ieee">
		<related-article related-article-type="revision-of">
			<xsl:text>(Revision of </xsl:text>
			<std><xsl:value-of select="bibitem/docidentifier"/></std>
			<xsl:text>)</xsl:text>
		</related-article>
	</xsl:template>
	
	<xsl:template match="semantic-metadata/related-article-edition">
		<related-article related-article-type="edition">
			<edition><xsl:value-of select="."/></edition>
		</related-article>
	</xsl:template>
	
	<xsl:template match="semantic-metadata/collab-type-logo">
		<collab collab-type="logo"><xsl:value-of select="."/></collab>
	</xsl:template>
	<xsl:template match="semantic-metadata/collab">
		<collab><xsl:value-of select="."/></collab>
	</xsl:template>
	<xsl:template match="semantic-metadata/collab-type-accredited-by">
		<collab collab-type="accredited-by"><xsl:value-of select="."/></collab>
	</xsl:template>
	
	<xsl:template match="semantic-metadata/funding-source-institution">
		<institution><xsl:value-of select="."/></institution>
	</xsl:template>
	<xsl:template match="semantic-metadata/funding-source-institution-id">
		<institution-id institution-id-type="fundref">
			<xsl:value-of select="."/>
		</institution-id>
	</xsl:template>
	<xsl:template match="semantic-metadata/award-group-id">
		<award-id>
			<xsl:value-of select="."/>
		</award-id>
	</xsl:template>
	<xsl:template match="semantic-metadata/funding-statement">
		<xsl:copy-of select="."/>
	</xsl:template>
	
	<xsl:template match="feedback-statement/clause/p" mode="front_ieee_publisher">
		<publisher>
			<publisher-name><xsl:value-of select="normalize-space(br/preceding-sibling::node())"/></publisher-name>
			<publisher-loc><xsl:value-of select="normalize-space(br/following-sibling::node())"/></publisher-loc>
		</publisher>
	</xsl:template>
	
	<xsl:template match="ext/editorialgroup/committee | ext/editorialgroup/society" mode="front_ieee">
		<xsl:copy-of select="."/>
	</xsl:template>
	
	<xsl:template match="semantic-metadata/partner-secretariat">
		<partner>
			<secretariat><xsl:value-of select="."/></secretariat>
		</partner>
	</xsl:template>
	
	<xsl:template match="date[@type = 'published']" mode="front_ieee">
		<pub-date>
			<xsl:attribute name="date-type">published</xsl:attribute>
			<xsl:attribute name="iso-8601-date"><xsl:value-of select="."/></xsl:attribute>
			<xsl:call-template name="dateParts">
				<xsl:with-param name="date" select="."/>
			</xsl:call-template>
		</pub-date>
	</xsl:template>
	
	<xsl:template match="date[@type = 'issued']" mode="front_ieee">
		<approval>
			<approval-date>
			<xsl:attribute name="date-type">approved</xsl:attribute>
			<xsl:attribute name="iso-8601-date"><xsl:value-of select="."/></xsl:attribute>
				<xsl:call-template name="dateParts">
					<xsl:with-param name="date" select="."/>
				</xsl:call-template>
			</approval-date>
			<stds-body>IEEE-SA Standards Board</stds-body>
		</approval>
	</xsl:template>
	
	<xsl:template match="date[@type = 'reaffirm']" mode="front_ieee">
		<reaffirm-date iso-8601-date="{.}">
			<xsl:call-template name="dateParts">
				<xsl:with-param name="date" select="."/>
			</xsl:call-template>
		</reaffirm-date>
	</xsl:template>
	
	<xsl:template name="dateParts">
		<xsl:param name="date"/>
		<xsl:variable name="day" select="substring($date,9,2)"/>
		<xsl:variable name="month" select="substring($date,6,2)"/>
		<xsl:variable name="monthStr">
			<xsl:choose>
				<xsl:when test="$month = '01'">January</xsl:when>
				<xsl:when test="$month = '02'">February</xsl:when>
				<xsl:when test="$month = '03'">March</xsl:when>
				<xsl:when test="$month = '04'">April</xsl:when>
				<xsl:when test="$month = '05'">May</xsl:when>
				<xsl:when test="$month = '06'">June</xsl:when>
				<xsl:when test="$month = '07'">July</xsl:when>
				<xsl:when test="$month = '08'">August</xsl:when>
				<xsl:when test="$month = '09'">September</xsl:when>
				<xsl:when test="$month = '10'">October</xsl:when>
				<xsl:when test="$month = '11'">November</xsl:when>
				<xsl:when test="$month = '12'">December</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="year" select="substring($date,1,4)"/>
		<day><xsl:value-of select="number($day)"/></day> <!-- remove 0 at start -->
		<month><xsl:value-of select="$monthStr"/></month>
		<year><xsl:value-of select="$year"/></year>
	</xsl:template>
	
	<xsl:template match="feedback-statement/clause" mode="front_ieee_supplementary_material">
		<supplementary-material>
			<xsl:apply-templates /> <!-- mode="front_ieee_supplementary_material" -->
		</supplementary-material>
	</xsl:template>
	
	<!-- <xsl:template match="feedback-statement/clause/p" mode="front_ieee_supplementary_material">
		<p><xsl:apply-templates/></p>
	</xsl:template> -->
	
	<xsl:template match="feedback-statement/clause" mode="front_ieee_permissions">
		<copyright-statement>
			<xsl:apply-templates select="p" mode="front_ieee_permissions"/>
		</copyright-statement>
	</xsl:template>
	<xsl:template match="feedback-statement/clause/p" mode="front_ieee_permissions">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="copyright/from" mode="front_ieee_permissions">
		<copyright-year><xsl:value-of select="."/></copyright-year>
	</xsl:template>
	
	<xsl:template match="copyright/owner" mode="front_ieee_permissions">
		<copyright-holder>
			<xsl:attribute name="copyright-owner">
				<xsl:value-of select="organization/abbreviation"/>
				<xsl:if test="not(organization/abbreviation)">
					<xsl:value-of select="organization/name"/>
				</xsl:if>
			</xsl:attribute>
			<xsl:value-of select="ancestor::bibdata/contributor[role[@type = 'publisher']]/organization/abbreviation"/>
		</copyright-holder>
	</xsl:template>
	
	<xsl:template match="feedback-statement/clause" mode="front_ieee_permissions_license">
		<license>
			<xsl:apply-templates mode="front_ieee_permissions_license"/>
		</license>
	</xsl:template>
	<xsl:template match="feedback-statement/clause/p" mode="front_ieee_permissions_license">
		<license-p>
			<xsl:apply-templates/>
		</license-p>
	</xsl:template>
	
	<xsl:template match="abstract" mode="front_ieee">
		<abstract>
			<xsl:attribute name="abstract-type">short</xsl:attribute>
			<xsl:attribute name="complex-abstract">no</xsl:attribute>
			<xsl:apply-templates/>
		</abstract>
	</xsl:template>
	
	<xsl:template match="semantic-metadata/*[starts-with(local-name(), 'keywords-')]">
		<xsl:variable name="current_name" select="local-name()"/>
		<xsl:variable name="kwd_group" select="substring-after(local-name(), 'keywords-')"/>
		<xsl:if test="not(../preceding-sibling::semantic-metadata[*[local-name() = $current_name]])"> <!-- for first in group -->
			<kwd-group kwd-group-type="{java:toUpperCase(java:java.lang.String.new($kwd_group))}">
				<xsl:for-each select=". | ../following-sibling::semantic-metadata[*[local-name() = $current_name]]">
					<kwd><xsl:value-of select="."/></kwd>
				</xsl:for-each>
			</kwd-group>
		</xsl:if>
	</xsl:template>
		
	<xsl:template match="legal-statement" mode="front_ieee_notes">
		<notes>
			<xsl:apply-templates mode="front_ieee_notes"/>
		</notes>
	</xsl:template>
	<xsl:template match="legal-statement//clause[@id = 'boilerplate-participants']" mode="front_ieee_notes" priority="2"/> <!-- will be processed out of <notes> -->
	<xsl:template match="legal-statement//clause" mode="front_ieee_notes">
		<sec>
			<xsl:apply-templates mode="front_ieee_notes"/>
		</sec>
	</xsl:template>
	<xsl:template match="legal-statement//clause/title" mode="front_ieee_notes">
		<xsl:copy>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="legal-statement//clause/p" mode="front_ieee_notes">
		<xsl:copy>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="legal-statement//clause" mode="contrib-group">
		<xsl:apply-templates select="p" mode="contrib-group"/>
	</xsl:template>
	
	<xsl:template match="legal-statement//clause/p" mode="contrib-group">
		<!-- Source (metanorma xml) example: 
			<ul id="_">
				<li>
					<dl id="_">
						<dt>name</dt>
						<dd>Firstname Lastname</dd>
						<dt>role</dt>
						<dd>Chair</dd>
					</dl>
				</li>
				...
		-->
		<xsl:variable name="content-type">
			<xsl:choose>
				<xsl:when test="contains(., ' liaisons') or contains(., ' Liaisons')">
					<xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new(.),'^.* (IEEE(\s|\h|\-)SA Standards Board [l|L]iaisons).*$','$1'))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="normalize-space(java:replaceAll(java:java.lang.String.new(.),'^.* the ((.+)( Working Group | subcommittee | balloting group | Standards Board )).*$','$1'))"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<contrib-group content-type="{$content-type}">
			<xsl:apply-templates select="following::ul[preceding-sibling::p[1][@id = current()/@id]]//dl" mode="contrib"/>
		</contrib-group>
	</xsl:template>
	<xsl:template match="legal-statement//clause/p[@type='emeritus_sign']" mode="contrib-group"/>
	
	<xsl:template match="dl" mode="contrib">
		<!-- Destination IEEE xml example:
			<contrib contrib-type="chair" id="contrib1">
				<name-alternatives>
					<string-name specific-use="display">
						<given-names>Firstname</given-names>
						<surname>Lastname</surname>
					</string-name>
				</name-alternatives>
				<role>Chair</role>
			</contrib>
		-->
		<xsl:variable name="contrib-type" select="dt[. = 'role']/following-sibling::dd[1]"/>
		<xsl:variable name="num"><xsl:number count="dl[ancestor::clause[@id = 'boilerplate-participants' or title = 'Participants']]" level="any"/></xsl:variable>
		<xsl:variable name="name_" select="normalize-space(dt[. = 'name']/following-sibling::dd[1])"/>
		<xsl:variable name="name" select="translate($name_,'*','')"/>
		<xsl:variable name="company_" select="normalize-space(dt[. = 'company']/following-sibling::dd[1])"/>
		<xsl:variable name="company" select="translate($company_,'*','')"/>
		
		<xsl:variable name="isEmeritus" select="normalize-space(java:endsWith(java:java.lang.String.new($name_),'*'))"/>
		<contrib>
			<xsl:attribute name="contrib-type">
				<xsl:variable name="value" select="java:toLowerCase(java:java.lang.String.new(normalize-space(translate($contrib-type,' ','-'))))"/>
				<xsl:choose>
					<xsl:when test="contains($value,',')"><xsl:value-of select="substring-before($value,',')"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
				</xsl:choose>
				<xsl:if test="$isEmeritus = 'true'">-emeritus</xsl:if>
			</xsl:attribute>
			<xsl:if test="$isEmeritus = 'true'">
				<xsl:attribute name="emeritus">yes</xsl:attribute>
			</xsl:if>
			<xsl:attribute name="id">contrib<xsl:value-of select="$num"/></xsl:attribute>
			
			<xsl:if test="$name != ''">
				<name-alternatives>
					<string-name specific-use="display">
						<xsl:variable name="name_regex">^(.*)(\s|\h)(.*)</xsl:variable>
						<given-names><xsl:value-of select="java:replaceAll(java:java.lang.String.new($name),$name_regex,'$1')"/></given-names>
						<surname><xsl:value-of select="java:replaceAll(java:java.lang.String.new($name),$name_regex,'$3')"/></surname>
					</string-name>
				</name-alternatives>
			</xsl:if>
			<xsl:if test="$company != ''">
				<collab-alternatives>
					<collab><xsl:value-of select="$company"/></collab>
				</collab-alternatives>
			</xsl:if>
			
			<xsl:if test="$contrib-type != 'member'">
				<role><xsl:value-of select="$contrib-type"/></role>
			</xsl:if>
			<xsl:if test="$isEmeritus = 'true'">
				<role>Member Emeritus</role>
			</xsl:if>
		</contrib>
	</xsl:template>
	
	
	<!-- [@id = 'boilerplate-participants'] -->
	<xsl:template match="legal-statement/clause" mode="front_ieee_participants">
		<sec>
			<!--  id="participants1" -->
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates mode="front_ieee_participants"/>
		</sec>
	</xsl:template>
	<xsl:template match="legal-statement/clause/title" mode="front_ieee_participants" priority="2">
		<xsl:copy>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="legal-statement/clause/clause" mode="front_ieee_participants">
		<xsl:apply-templates mode="front_ieee_participants"/>
	</xsl:template>
	<xsl:template match="legal-statement//clause/title" mode="front_ieee_participants"/>
	
	<xsl:template match="legal-statement/clause//p[not(@type)]" mode="front_ieee_participants" priority="2">
		<participants-sec>
			<p>
				<xsl:apply-templates mode="front_ieee_participants"/>
			</p>
			<xsl:apply-templates select="following::ul[preceding-sibling::p[1][@id = current()/@id]]" mode="front_ieee_participants">
				<xsl:with-param name="process">true</xsl:with-param>
			</xsl:apply-templates>
		</participants-sec>
	</xsl:template>
	
	<!-- <xsl:template match="legal-statement//clause/p[not(@type)]" mode="front_ieee_participants">
		<xsl:copy>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template> -->
	
	<xsl:template match="legal-statement//clause/ul" mode="front_ieee_participants">
		<xsl:param name="process">false</xsl:param>
		<xsl:if test="$process = 'true'">
			<xsl:if test="li[dl/dt[.='role']/following-sibling::dd[1][. != 'member']]"> <!--  and not(contains(., 'Manager')) -->
				<officers>
					<list list-type="simple">
						<xsl:apply-templates select="li[dl/dt[.='role']/following-sibling::dd[1][. != 'member']]" mode="front_ieee_participants"/> <!--  and not(contains(., 'Manager')) -->
					</list>
				</officers>
			</xsl:if>
			<xsl:if test="li[dl/dt[.='role']/following-sibling::dd[1][. = 'member']]"> <!--  or contains(., 'Manager') -->
				<list list-type="simple">
					<xsl:apply-templates select="li[dl/dt[.='role']/following-sibling::dd[1][. = 'member']]" mode="front_ieee_participants"/> <!--  or contains(., 'Manager') -->
				</list>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="li" mode="front_ieee_participants">
		<xsl:apply-templates mode="front_ieee_participants"/>
	</xsl:template>
	<xsl:template match="dl" mode="front_ieee_participants">
		<xsl:variable name="num"><xsl:number count="dl[ancestor::clause[@id = 'boilerplate-participants' or title = 'Participants']]" level="any"/></xsl:variable>
		<list-item>
			<p>
				<xref>
					<xsl:attribute name="ref-type">contrib</xsl:attribute>
					<xsl:attribute name="rid">contrib<xsl:value-of select="$num"/></xsl:attribute>
				</xref>
			</p>
		</list-item>
	</xsl:template>
	
	<xsl:template match="legal-statement//clause/p[@type]" mode="front_ieee_participants"/>
	
	<!-- ============= -->
	<!-- End IEEE bibdata -->
	<!-- ============= -->
	
	<xsl:template match="preface/clause[starts-with(@id,'front-ack')]" mode="front_preface">
		<ack>
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates />
		</ack>
	</xsl:template>
	
	<xsl:template match="preface/acknowledgements" mode="front_preface" priority="3">
		<xsl:param name="process">false</xsl:param>
		<xsl:if test="$process = 'true'">
			<ack content-type="back-ack1">
				<xsl:copy-of select="@id"/>
				<!-- <xsl:apply-templates select="title"/>
				<xsl:apply-templates select="node()[not(self::title)]"/> -->
				<xsl:apply-templates />
			</ack>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="p">
		<xsl:variable name="parent_name" select="local-name(..)"/>
		
		<xsl:variable name="paragraph_">
			<xsl:choose>
				<xsl:when test="$parent_name = 'termexample' or 
															$parent_name = 'definition'  or 
															$parent_name = 'verbaldefinition'  or 
															$parent_name = 'verbal-definition'  or 
															$parent_name = 'termnote' or 
															$parent_name = 'modification' or
															$parent_name = 'dd'">
					<xsl:choose>
						<xsl:when test="$parent_name = 'definition' or $parent_name = 'termnote' or $parent_name = 'verbaldefinition' or $parent_name = 'verbal-definition'">
							<p>
								<xsl:apply-templates />
							</p>
						</xsl:when>
						<xsl:otherwise>
							<xsl:if test="preceding-sibling::*[1][self::p]"><break /></xsl:if>
							<xsl:apply-templates />
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="$parent_name = 'td' or $parent_name = 'th'">
					<xsl:apply-templates />
				</xsl:when>
				<xsl:otherwise>
					<p>
						<xsl:apply-templates select="@*[not(local-name() = 'id')]"/>
						<xsl:apply-templates />
						
						<!-- if paragraph ends with ':', then move next 'formula' inside 'p' -->
						<xsl:if test="normalize-space(java:endsWith(java:java.lang.String.new(normalize-space()),':')) = 'true'">
							<xsl:apply-templates select="following-sibling::*[1][self::formula]">
								<xsl:with-param name="skip">false</xsl:with-param>
							</xsl:apply-templates>
						</xsl:if>
						
						<!-- if paragraph doesn't end with '.' and next element is 'ol' or 'ul', then move next 'ul' and 'ol' inside 'p' inside current p  -->
						<xsl:if test="normalize-space(java:endsWith(java:java.lang.String.new(normalize-space()),'.')) = 'false' and not(ancestor::li)">
							<xsl:apply-templates select="following-sibling::*[1][self::ul or self::ol or self::sourcecode or self::dl or self::table]">
								<xsl:with-param name="skip">false</xsl:with-param>
							</xsl:apply-templates>
						</xsl:if>
					</p>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="paragraph" select="xalan:nodeset($paragraph_)"/>
		<xsl:choose>
			<xsl:when test="$paragraph/p/break">	<!-- IEEE doesn't support break in the paragraph -->
				<xsl:for-each select="$paragraph/p/break">
				
					<xsl:if test="not(preceding-sibling::break)"> <!-- first break -->
						<p> <!-- first p -->
							<xsl:copy-of select="preceding-sibling::node()"/>
						</p>
					</xsl:if>
					
					<xsl:if test="preceding-sibling::break">
						<p>
							<xsl:copy-of select="preceding-sibling::break[1]/following-sibling::node()[following-sibling::break[1][generate-id() = generate-id(current())]]"/>
						</p>
					</xsl:if>
					
					<xsl:if test="not(following-sibling::break)"> <!-- last break -->
						<p> <!-- last p -->
							<xsl:copy-of select="following-sibling::node()"/>
						</p>
					</xsl:if>
					
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="$paragraph"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
</xsl:stylesheet>