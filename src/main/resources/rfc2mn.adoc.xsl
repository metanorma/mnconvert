<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet version="1.0"

	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:date="http://exslt.org/dates-and-times"
	xmlns:str="http://exslt.org/strings"
	xmlns:exsl="http://exslt.org/common"
	xmlns:l="urn:local"
	xmlns:xalan="http://xml.apache.org/xalan" 
	xmlns:svg="http://www.w3.org/2000/svg"
	xmlns:mml="http://www.w3.org/1998/Math/MathML" 
	xmlns:java="http://xml.apache.org/xalan/java" 
	xmlns:java_char="http://xml.apache.org/xalan/java/java.lang.Character" 
	exclude-result-prefixes="xsl date str exsl l java java_char">

	<!-- Metanorma-IETF: https://www.metanorma.com/author/ietf/topics/markup-v2/, https://www.metanorma.com/author/ietf/topics/markup/ -->

	<xsl:output method="text" encoding="utf-8" />
	<xsl:strip-space elements="*" />
	<xsl:preserve-space elements="t li reference" />

	<!-- if value = final, cref are omitted -->
	<xsl:param name="draft">nonfinal</xsl:param>

	
	<xsl:variable name="isDraft">
		<xsl:if test="starts-with(/rfc/@docName, 'draft-')">true</xsl:if>
	</xsl:variable>

	<xsl:variable name="linearizedXML">
		<xsl:apply-templates mode="linearize"/>
	</xsl:variable>

	<xsl:template match="/">
		<xsl:apply-templates select="xalan:nodeset($linearizedXML)/*"/>
	</xsl:template>

	<xsl:template match="rfc">
		<!-- document preamble: -->
		<!-- Header -->
		<xsl:apply-templates select="front/title" mode="header"/>
		<!-- document attributes -->
		<!-- https://www.metanorma.com/author/ietf/ref/document-attributes-v2/ -->
		<xsl:text>:doctype: </xsl:text><xsl:call-template name="getDocType"/><xsl:text>&#xa;</xsl:text>
		<xsl:text>:abbrev: </xsl:text><xsl:value-of select="front/title/@abbrev"/><xsl:text>&#xa;</xsl:text>		
		<xsl:text>:name: </xsl:text><xsl:call-template name="getName"/><xsl:text>&#xa;</xsl:text>
		<xsl:call-template name="getStatus"/> <!-- :status: -->
		<xsl:call-template name="getIntendedSeries"/> <!-- :intended-series: -->
		<xsl:call-template name="getSubmissionType"/> <!-- :submission-type: -->
		<xsl:text>:ipr: </xsl:text><xsl:value-of select="@ipr"/><xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="@iprExtract"/> <!-- :ipr-extract: -->
		<xsl:apply-templates select="@obsoletes"/> <!-- :obsoletes: -->
		<xsl:apply-templates select="@updates"/> <!-- :updates: -->
		
		<xsl:apply-templates select="link[@rel = 'item']/@href"/> <!-- :included-in: -->
		<xsl:apply-templates select="link[@rel = 'describedby']/@href"/> <!-- :described-by: -->		
		<xsl:apply-templates select="link[@rel = 'convertedFrom']/@href"/> <!-- :derived-from: -->
		<xsl:apply-templates select="link[@rel = 'alternate']/@href"/> <!-- :instance: -->
		
		<xsl:apply-templates select="front/date" mode="header"/> <!-- :revdate: -->
		<xsl:call-template name="getArea"/> <!-- :area: -->
		<xsl:call-template name="getWorkgroup"/> <!-- :workgroup: -->
		<xsl:call-template name="getKeyword"/> <!-- :keyword: -->
		<xsl:apply-templates select="@xml:lang"/> <!-- :xml-lang: -->
		<xsl:apply-templates select="@consensus"/> <!-- :consensus: -->
		<xsl:apply-templates select="@indexInclude"/> <!-- :index-include: -->
		<xsl:apply-templates select="@sortRefs"/> <!-- :sort-refs: -->
		<xsl:apply-templates select="@symRefs"/> <!-- :sym-refs: -->
		<xsl:apply-templates select="@tocInclude"/> <!-- :toc-include: -->
		<xsl:apply-templates select="@tocDepth"/> <!-- :toc-depth: -->
		<xsl:apply-templates select="front/author[1]/organization/@showOnFrontPage"/> <!-- :show-on-front-page: -->
		
		<xsl:call-template name="getAuthor"/> <!-- :fullname: :forename_initials: :initials: :lastname: :surname: :role: :organization: :affiliation: :organization_abbrev: :affiliation_abbrev: :email: :fax: :uri: :contributor-uri: :phone: :street: :city: :region: :country: :code:-->
		
		<!-- processing instructions  -->
		<!-- see https://www.metanorma.com/author/ietf/ref/document-attributes-v2/#processing-instructions-for-xml2rfc -->
		<xsl:call-template name="getProcessingInstructions"/> <!-- :artworkdelimiter: :artworklines: :authorship: :autobreaks: :background: :comments: :compact: ...  -->
		
		
		
		<!-- Preamble -->
		<xsl:apply-templates select="front"/>
		
		<!-- Sections and Subsections -->
		<xsl:apply-templates select="middle"/>
		
		<xsl:apply-templates select="back"/>
		
		<!-- Introduction -->
		
	</xsl:template>

	<!-- ================ -->
	<!-- Header -->
	<!-- ================ -->
	<xsl:template match="front/title" mode="header">
		<xsl:text>= </xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template name="getDocType">
		<xsl:choose>
			<xsl:when test="$isDraft = 'true'">internet-draft</xsl:when>
			<xsl:otherwise>rfc</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	

	<xsl:template name="getName">
		<xsl:choose>
			<xsl:when test="$isDraft = 'true'">  <!-- internet-draft -->
				<xsl:choose>
					<xsl:when test="@docName"><xsl:value-of select="@docName"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="front/seriesInfo/@value"/></xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose> <!-- rfc -->
					<xsl:when test="@number"><xsl:value-of select="@number"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="front/seriesInfo/@value"/></xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>

	<xsl:template name="getStatus">
		<xsl:variable name="category">
			<xsl:choose>
				<xsl:when test="@category">
					<xsl:choose>
						<xsl:when test="@category = 'std'">standard</xsl:when>
						<xsl:when test="@category = 'info'">informational</xsl:when>
						<xsl:when test="@category = 'exp'">experimental</xsl:when>
						<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="front/seriesInfo[1]/@status">
					<xsl:value-of select="front/seriesInfo[1]/@status"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="normalize-space($category) != ''">
			<xsl:text>:status: </xsl:text><xsl:value-of select="$category"/><xsl:text>&#xa;</xsl:text> <!-- synonym :docstage: -->
		</xsl:if>
	</xsl:template>

	<!-- intended-series: -->
	<xsl:template name="getIntendedSeries">
		<!-- <xsl:choose>
			<xsl:when test="$isDraft = 'true'">
				<xsl:choose>
					<xsl:when test="@category = 'std'">standard</xsl:when>
					<xsl:when test="@category = 'info'">informational</xsl:when>
					<xsl:when test="@category = 'exp'">experimental</xsl:when>
					<xsl:otherwise><xsl:value-of select="@category"/></xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise> RFC
				<xsl:choose>
					<xsl:when test="@category = 'info'">informational</xsl:when>
					<xsl:when test="@category = 'exp'">exp</xsl:when>
					<xsl:when test="@category = 'bcp'">bcp <xsl:value-of select="@number"/></xsl:when>
					<xsl:when test="@category = 'fyi'">fyi <xsl:value-of select="@number"/></xsl:when>
					<xsl:when test="@category = 'std'">full-standard <xsl:value-of select="@number"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="@category"/></xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose> -->
		
		<xsl:variable name="intended-series">
			<xsl:choose>
				<xsl:when test="@category = 'std'">standard</xsl:when>
				<xsl:when test="@category = 'info'">informational</xsl:when>
				<xsl:when test="@category = 'exp'">experimental</xsl:when>
				<xsl:when test="@category"><xsl:value-of select="@category"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="front/seriesInfo[2]/@status"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="normalize-space($intended-series) != ''">
			<xsl:text>:intended-series: </xsl:text><xsl:value-of select="$intended-series"/><xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template name="getSubmissionType">
		<xsl:variable name="submissionType">
			<xsl:choose>
				<xsl:when test="@submissionType"><xsl:value-of select="@submissionType"/></xsl:when>
				<xsl:otherwise><xsl:value-of select="front/seriesInfo/@stream"/></xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="normalize-space($submissionType) != ''">
			<xsl:text>:submission-type: </xsl:text><xsl:value-of select="@submissionType"/><xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	

	<xsl:template match="rfc/@iprExtract">
		<xsl:if test=". != ''">
			<xsl:text>:ipr-extract: </xsl:text><xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="rfc/@obsoletes">
		<xsl:if test=". != ''">
			<xsl:text>:obsoletes: </xsl:text><xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="rfc/@updates">
		<xsl:if test=". != ''">
			<xsl:text>:updates: </xsl:text><xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="rfc/link[@rel = 'item']/@href">
		<xsl:if test=". != ''">
			<xsl:text>:included-in: </xsl:text><xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="rfc/link[@rel = 'describedby']/@href">
		<xsl:if test=". != ''">
			<xsl:text>:described-by: </xsl:text><xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="rfc/link[@rel = 'convertedFrom']/@href">
		<xsl:if test=". != ''">
			<xsl:text>:derived-from: </xsl:text><xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="rfc/link[@rel = 'alternate']/@href">
		<xsl:if test=". != ''">
			<xsl:text>:instance: </xsl:text><xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	

	<xsl:template match="rfc/front/date" mode="header">
		<xsl:text>:revdate: </xsl:text>
		<xsl:variable name="day">
			<xsl:choose>
				<xsl:when test="string-length(@day) = 0">
						<xsl:value-of select="'01'" />
				</xsl:when>
				<xsl:when test="string-length(@day) = 1">
						<xsl:value-of select="'0'" />
						<xsl:value-of select="@day" />
				</xsl:when>
				<xsl:otherwise>
						<xsl:value-of select="@day" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="month">
			<xsl:choose>
				<xsl:when test="@month = 'January'">01</xsl:when>
				<xsl:when test="@month = 'February'">02</xsl:when>
				<xsl:when test="@month = 'March'">03</xsl:when>
				<xsl:when test="@month = 'April'">04</xsl:when>
				<xsl:when test="@month = 'May'">05</xsl:when>
				<xsl:when test="@month = 'June'">06</xsl:when>
				<xsl:when test="@month = 'July'">07</xsl:when>
				<xsl:when test="@month = 'August'">08</xsl:when>
				<xsl:when test="@month = 'September'">09</xsl:when>
				<xsl:when test="@month = 'October'">10</xsl:when>
				<xsl:when test="@month = 'November'">11</xsl:when>
				<xsl:when test="@month = 'December'">12</xsl:when>
				<xsl:otherwise>01</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="@year"/>-<xsl:value-of select="$month"/>-<xsl:value-of select="$day"/>
		<xsl:text>T00:00:00Z</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template name="getArea">
		<xsl:variable name="areas">
			<xsl:call-template name="commafy">
				<xsl:with-param name="nodes" select="/rfc/front/area" />
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="$areas != ''">
			<xsl:text>:area: </xsl:text>
			<xsl:value-of select="$areas"/>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="getWorkgroup">
		<xsl:variable name="workgroups">
			<xsl:call-template name="commafy">
				<xsl:with-param name="nodes" select="/rfc/front/workgroup" />
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="$workgroups != ''">
			<xsl:text>:workgroup: </xsl:text>
			<xsl:value-of select="$workgroups"/>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="getKeyword">
		<xsl:variable name="keywords">
			<xsl:call-template name="commafy">
				<xsl:with-param name="nodes" select="/rfc/front/keyword" />
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="$keywords != ''">
			<xsl:text>:keyword: </xsl:text>
			<xsl:value-of select="$keywords"/>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="@xml:lang">
		<xsl:text>:xml-lang: </xsl:text><xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template match="@consensus">
		<xsl:text>:consensus: </xsl:text>
		<xsl:choose>
			<xsl:when test=". = 'yes' or . = 'true'">true</xsl:when>
			<xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<!-- V3 attributes -->
	<xsl:template match="@indexInclude">
		<xsl:text>:index-include: </xsl:text><xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="@sortRefs">
		<xsl:text>:sort-refs: </xsl:text><xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template match="@symRefs">
		<xsl:text>:sym-refs: </xsl:text><xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template match="@tocInclude">
		<xsl:text>:toc-include: </xsl:text><xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template match="@tocDepth">
		<xsl:text>:toc-depth: </xsl:text><xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="/rfc/front/author/organization/@showOnFrontPage">
		<xsl:text>:show-on-front-page: </xsl:text><xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<!-- End of V3 attributes -->

	<xsl:template name="getAuthor">
		<xsl:for-each select="/rfc/front/author">
			<xsl:call-template name="processAuthor"/>
		</xsl:for-each>
		<xsl:variable name="front_authors">
			<xsl:for-each select="/rfc/front/author">
				<xsl:copy-of select="."/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="back_authors">
			<section>
				<xsl:for-each select="/rfc/back/section/author">
					<xsl:if test="not(xalan:nodeset($front_authors)//author[. = current()/. and @fullname = current()/@fullname])"><!-- if there is new author in annex -->
						<xsl:copy-of select="."/>
					</xsl:if>
				</xsl:for-each>
			</section>
		</xsl:variable>
		<xsl:variable name="count_front_authors" select="count(/rfc/front/author)"/>

		<xsl:for-each select="xalan:nodeset($back_authors)//author">
			<xsl:variable name="pos" select="position() + $count_front_authors"/>
			<xsl:call-template name="processAuthor">
				<xsl:with-param name="pos" select="$pos"/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="processAuthor">
		<xsl:param name="pos" select="0"/>
		<xsl:variable name="sfx">
			<xsl:choose>
				<xsl:when test="$pos != 0">_<xsl:value-of select="$pos"/></xsl:when>
				<xsl:when test="position() &gt; 1">_<xsl:value-of select="position()"/></xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:apply-templates select="@fullname">
			<xsl:with-param name="sfx" select="$sfx"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="@initials">
			<xsl:with-param name="sfx" select="$sfx"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="@surname">
			<xsl:with-param name="sfx" select="$sfx"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="@role">
			<xsl:with-param name="sfx" select="$sfx"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="organization">
			<xsl:with-param name="sfx" select="$sfx"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="address">
			<xsl:with-param name="sfx" select="$sfx"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="/rfc/front/author/@fullname | section/author/@fullname">
		<xsl:param name="sfx"/>
		<xsl:text>:fullname</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="/rfc/front/author/@initials | section/author/@initials">
		<xsl:param name="sfx"/>
		<!-- <xsl:text>:forename_initials</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text> --> <!-- V2 -->
		<xsl:text>:initials</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="/rfc/front/author/@surname | section/author/@surname">
		<xsl:param name="sfx"/>
		<!-- <xsl:text>:lastname</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text> --> <!-- V2 -->
		<xsl:text>:surname</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="/rfc/front/author/@role | section/author/@role">
		<xsl:param name="sfx"/>
		<xsl:if test=". != 'author'">
			<xsl:text>:role</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text>
			<xsl:value-of select="."/>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="/rfc/front/author/organization | section/author/organization">
		<xsl:param name="sfx"/>
		<!-- <xsl:text>:organization</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text> --> <!-- V2 -->
		<xsl:text>:affiliation</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="@abbrev">
			<xsl:with-param name="sfx" select="$sfx"/>
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="/rfc/front/author/organization/@abbrev | section/author/organization/@abbrev">
		<xsl:param name="sfx"/>
		<!-- <xsl:text>:organization_abbrev</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text> --> <!-- V2 -->
		<xsl:text>:affiliation_abbrev</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template match="/rfc/front/author/address | section/author/address">
		<xsl:param name="sfx"/>	
		<xsl:apply-templates select="email">
			<xsl:with-param name="sfx" select="$sfx"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="facsimile">
			<xsl:with-param name="sfx" select="$sfx"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="uri">
			<xsl:with-param name="sfx" select="$sfx"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="phone">
			<xsl:with-param name="sfx" select="$sfx"/>
		</xsl:apply-templates>
		<xsl:apply-templates select="postal">
			<xsl:with-param name="sfx" select="$sfx"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template match="/rfc/front/author/address/email | section/author/address/email">
		<xsl:param name="sfx"/>
		<xsl:text>:email</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="/rfc/front/author/address/facsimile | section/author/address/facsimile">
		<xsl:param name="sfx"/>
		<xsl:text>:fax</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="/rfc/front/author/address/uri | section/author/address/uri">
		<xsl:param name="sfx"/>
		<!-- <xsl:text>:uri</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text> --> <!-- V2 -->
		<xsl:text>:contributor-uri</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	<xsl:template match="/rfc/front/author/address/phone | section/author/address/phone">
		<xsl:param name="sfx"/>
		<xsl:text>:phone</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template match="/rfc/front/author/address/postal | section/author/address/postal">
		<xsl:param name="sfx"/>	
		<xsl:variable name="postal">
			<xsl:apply-templates select="street[1]">
				<xsl:with-param name="sfx" select="$sfx"/>
			</xsl:apply-templates>
			<xsl:apply-templates select="city[1]">
				<xsl:with-param name="sfx" select="$sfx"/>
			</xsl:apply-templates>
			<xsl:apply-templates select="cityarea[1]">
				<xsl:with-param name="sfx" select="$sfx"/>
			</xsl:apply-templates>
			<xsl:apply-templates select="region[1]">
				<xsl:with-param name="sfx" select="$sfx"/>
			</xsl:apply-templates>
			<xsl:apply-templates select="country[1]">
				<xsl:with-param name="sfx" select="$sfx"/>
			</xsl:apply-templates>
			<xsl:apply-templates select="extaddr[1]">
				<xsl:with-param name="sfx" select="$sfx"/>
			</xsl:apply-templates>
			<xsl:apply-templates select="pobox[1]">
				<xsl:with-param name="sfx" select="$sfx"/>
			</xsl:apply-templates>
			<xsl:apply-templates select="sortingcode[1]">
				<xsl:with-param name="sfx" select="$sfx"/>
			</xsl:apply-templates>
			<xsl:apply-templates select="code[1]">
				<xsl:with-param name="sfx" select="$sfx"/>
			</xsl:apply-templates>
			<xsl:apply-templates select="postalLine[1]">
				<xsl:with-param name="sfx" select="$sfx"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:for-each select="xalan:nodeset($postal)/item[normalize-space(text()) != '']">
			<xsl:if test="position() = 1"><xsl:text>:address</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text></xsl:if>
			<xsl:value-of select="." />
			<xsl:if test="position() != last()"> + \</xsl:if>
			<xsl:text>&#xa;</xsl:text>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="/rfc/front/author/address/postal/street | section/author/address/postal/street">
		<xsl:param name="sfx"/>	
		<!-- <xsl:text>:street</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text> --> <!-- V2 -->
		<item>
			<xsl:for-each select="ancestor::postal/street[normalize-space(text()) != '']">
				<xsl:apply-templates/>
				<xsl:if test="position() != last()">\ </xsl:if>
			</xsl:for-each>
		</item>
		<!-- <xsl:text>&#xa;</xsl:text> -->
	</xsl:template>

	<xsl:template match="/rfc/front/author/address/postal/city | section/author/address/postal/city">
		<xsl:param name="sfx"/>	
		<!-- <xsl:text>:city</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text> --> <!-- V2 -->
		<item>
			<xsl:for-each select="ancestor::postal/city[normalize-space(text()) != '']">
				<xsl:apply-templates/>
				<xsl:if test="position() != last()">\ </xsl:if>
			</xsl:for-each>
		</item>
		<!-- <xsl:text>&#xa;</xsl:text> -->
	</xsl:template>
	
	<xsl:template match="/rfc/front/author/address/postal/cityarea | section/author/address/postal/cityarea"> <!-- V3 -->
		<xsl:param name="sfx"/>	
		<item>
			<xsl:for-each select="ancestor::postal/cityarea[normalize-space(text()) != '']">
				<xsl:apply-templates/>
				<xsl:if test="position() != last()">\ </xsl:if>
			</xsl:for-each>
		</item>
	</xsl:template>
	
	<xsl:template match="/rfc/front/author/address/postal/region | section/author/address/postal/region">
		<xsl:param name="sfx"/>	
		<!-- <xsl:text>:region</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text> --> <!-- V2 -->
		<item>
			<xsl:for-each select="ancestor::postal/region[normalize-space(text()) != '']">
				<xsl:apply-templates/>
				<xsl:if test="position() != last()">\ </xsl:if>
			</xsl:for-each>
		</item>
		<!-- <xsl:text>&#xa;</xsl:text> -->
	</xsl:template>
	
	<xsl:template match="/rfc/front/author/address/postal/country | section/author/address/postal/country">
		<xsl:param name="sfx"/>	
		<!-- <xsl:text>:country</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text> --> <!-- V2 -->
		<item>
			<xsl:for-each select="ancestor::postal/country[normalize-space(text()) != '']">
				<xsl:apply-templates/>
				<xsl:if test="position() != last()">\ </xsl:if>
			</xsl:for-each>
		</item>
		<!-- <xsl:text>&#xa;</xsl:text> -->
	</xsl:template>
	
	<xsl:template match="/rfc/front/author/address/postal/extaddr | section/address/postal/extaddr"> <!-- V3 -->
		<xsl:param name="sfx"/>	
		<item>
			<xsl:for-each select="ancestor::postal/extaddr[normalize-space(text()) != '']">
				<xsl:apply-templates/>
				<xsl:if test="position() != last()">\ </xsl:if>
			</xsl:for-each>
		</item>
	</xsl:template>

	<xsl:template match="/rfc/front/author/address/postal/pobox | section/author/address/postal/pobox"> <!-- V3 -->
		<xsl:param name="sfx"/>	
		<item>
			<xsl:for-each select="ancestor::postal/pobox[normalize-space(text()) != '']">
				<xsl:apply-templates/>
				<xsl:if test="position() != last()">\ </xsl:if>
			</xsl:for-each>
		</item>
	</xsl:template>

	<xsl:template match="/rfc/front/author/address/postal/sortingcode | section/author/address/postal/sortingcode"> <!-- V3 -->
		<xsl:param name="sfx"/>	
		<item>
			<xsl:for-each select="ancestor::postal/sortingcode[normalize-space(text()) != '']">
				<xsl:apply-templates/>
				<xsl:if test="position() != last()">\ </xsl:if>
			</xsl:for-each>
		</item>
	</xsl:template>
	
	<xsl:template match="/rfc/front/author/address/postal/code | section/author/address/postal/code">
		<xsl:param name="sfx"/>	
		<!-- <xsl:text>:code</xsl:text><xsl:value-of select="$sfx"/><xsl:text>: </xsl:text> --> <!-- V2 -->
		<item>
			<xsl:for-each select="ancestor::postal/code[normalize-space(text()) != '']">
				<xsl:apply-templates/>
				<xsl:if test="position() != last()">\ </xsl:if>
			</xsl:for-each>
		</item>
		<!-- <xsl:text>&#xa;</xsl:text> -->
	</xsl:template>
	
	<xsl:template match="/rfc/front/author/address/postal/postalLine | section/author/address/postal/postalLine">
		<xsl:param name="sfx"/>	
		<item>
			<xsl:for-each select="ancestor::postal/postalLine[normalize-space(text()) != '']">
				<xsl:apply-templates/>
				<xsl:if test="position() != last()">\ </xsl:if>
			</xsl:for-each>
		</item>		
	</xsl:template>

	<xsl:template name="getProcessingInstructions">
		<xsl:for-each select="/processing-instruction()[name() = 'rfc']">
			<xsl:variable name="key" select="normalize-space(substring-before(., '='))"/>
			<xsl:variable name="value" select="normalize-space(translate(substring-after(., '='), '&quot;', ''))"/>
			<xsl:text>:</xsl:text>
			<xsl:choose>
				<xsl:when test="$key = 'sortrefs'">sort-refs</xsl:when>
				<xsl:when test="$key = 'symrefs'">sym-refs</xsl:when>
				<xsl:when test="$key = 'toc'">toc-include</xsl:when>
				<xsl:when test="$key = 'tocdepth'">toc-depth</xsl:when>				
				<xsl:otherwise><xsl:value-of select="$key"/></xsl:otherwise> <!-- artworkdelimiter, artworklines, authorship, autobreaks, background, colonspace, comments, compact, docmapping, editing, emoticonic, footer, header, include, inline, iprnotified, linkmailto, linefile, needLines, notedraftinprogress, private, refparent, rfcedstyle, rfcprocack, slides, strict, subcompact, text-list-symbols, tocappendix, tocindent, tocnarrow, tocompact, topblock, typeout, useobject -->
			</xsl:choose>
			<xsl:text>: </xsl:text>
			<xsl:value-of select="$value"/>
			<xsl:text>&#xa;</xsl:text>
		</xsl:for-each>
	</xsl:template>
	<!-- ================ -->
	<!-- END of Header -->
	<!-- ================ -->

	<!-- ================ -->
	<!-- Preamble -->
	<!-- ================ -->
	<!-- already handled above, so discard -->
	<xsl:template match="/rfc/front/title"/> 
	<xsl:template match="/rfc/front/author"/> 
	<xsl:template match="/rfc/front/area" />
	<xsl:template match="/rfc/front/workgroup" />
	<xsl:template match="/rfc/front/keyword" />
	
	<xsl:template match="/rfc/front/abstract">
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="@*"/>
		<xsl:text>[abstract]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>== Abstract</xsl:text>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="/rfc/front/note">
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>[NOTE</xsl:text>
		<xsl:for-each select="@removeInRFC">
			<xsl:text>,</xsl:text>
			<xsl:apply-templates select="."/>
		</xsl:for-each>
		<xsl:text>]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="@title" mode="title"/>
		<xsl:apply-templates select="name" mode="title"/>
		<xsl:text>===</xsl:text>
		<xsl:apply-templates />
		<xsl:text>===</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template match="/rfc/front/note/@title" mode="title">
		<xsl:text>.</xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="/rfc/front/note/name" mode="title">
		<xsl:text>.</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="/rfc/front/note/name"/>
	
	<!-- ================ -->
	<!-- END of Preamble -->
	<!-- ================ -->
	
	<!-- ================ -->
	<!-- Middle (Sections and Subsections) and Appendixes -->
	<!-- ================ -->

	<xsl:template match="section">
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="@anchor"/>
		
		<xsl:variable name="section_settings">
			<xsl:for-each select="@removeInRFC | @toc | @numbered">
				<xsl:apply-templates select="."/>
				<xsl:if test="position() != last()">,</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="ancestor::*[local-name() = 'back'] or $section_settings != ''">
			<xsl:text>[</xsl:text>
		</xsl:if>
		<xsl:if test="ancestor::*[local-name() = 'back']">
			<xsl:text>appendix</xsl:text>
		</xsl:if>
		<xsl:if test="$section_settings != ''">
			<xsl:if test="ancestor::*[local-name() = 'back']">,</xsl:if>
			<xsl:value-of select="$section_settings"/>
		</xsl:if>
		<xsl:if test="ancestor::*[local-name() = 'back'] or $section_settings != ''">
			<xsl:text>]&#xa;</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="@title" mode="title"/>
		<xsl:apply-templates select="name" mode="title"/>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="section/@anchor">
		<xsl:choose>
			<xsl:when test=". = 'introduction'"><xsl:text>[#</xsl:text><xsl:value-of select="."/><xsl:text>]</xsl:text></xsl:when>
			<xsl:otherwise><xsl:text>[[</xsl:text><xsl:value-of select="."/><xsl:text>]]</xsl:text></xsl:otherwise>
		</xsl:choose>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template match="section/@title" mode="title">
		<xsl:variable name="level" select="count(ancestor::section) + 1"/>
		<xsl:value-of select="str:padding($level, '=')"/>
		<xsl:text> </xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	<xsl:template match="section/name" mode="title">
		<xsl:variable name="level" select="count(ancestor::section) + 1"/>
		<xsl:value-of select="str:padding($level, '=')"/>
		<xsl:text> </xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	<xsl:template match="section/name"/>

	<xsl:template match="section/@toc">
		<xsl:text>toc=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="section/@numbered">
		<xsl:text>numbered=</xsl:text><xsl:value-of select="."/>
	</xsl:template>

	<xsl:template match="section[count(*) = count(name) + count(author)]" priority="2"/>

	<!-- ================ -->
	<!-- END Middle (Sections and Subsections) -->
	<!-- ================ -->

	<!-- ================ -->
	<!-- References -->
	<!-- ================ -->
	
	<xsl:template match="references[references]" priority="3">
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="references" priority="2">
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>[bibliography]&#xa;</xsl:text>
		<xsl:apply-templates select="@title" mode="title"/>
		<xsl:apply-templates select="name" mode="title"/>
		<xsl:if test="not(@title) and not(name)"><xsl:text>== References&#xa;</xsl:text></xsl:if>
		<xsl:apply-templates select="referencegroup"/>
		<xsl:text>++++</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="node()[not(local-name() = 'referencegroup')]"/>
		<xsl:text>++++</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="references/@title" mode="title">
		<xsl:text>== </xsl:text><xsl:value-of select="."/><xsl:text>&#xa;</xsl:text>
	</xsl:template>
	<xsl:template match="references/name" mode="title">
		<xsl:text>== </xsl:text><xsl:apply-templates /><xsl:text>&#xa;</xsl:text>
	</xsl:template>
	<xsl:template match="references/name" priority="2"/>
	
	<xsl:template match="references//*">
		<xsl:text>&lt;</xsl:text>
		<xsl:value-of select="name()"/>
		<xsl:apply-templates select="@*"/>
		<xsl:text>&gt;</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&lt;/</xsl:text>
		<xsl:value-of select="name()"/>
		<xsl:text>&gt;&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="references//*/@*">
		<xsl:text> </xsl:text>
		<xsl:value-of select="name()"/>
		<xsl:text>="</xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>"</xsl:text>
	</xsl:template>
	
	<xsl:template match="references//text()"><xsl:value-of select="." /></xsl:template>
	
	<xsl:template match="references/referencegroup">
		<xsl:apply-templates select="@anchor"/>
		<xsl:text>[%bibitem]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>== {blank}</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>link: </xsl:text>
		<xsl:value-of select="@target"/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="referencegroup/@anchor" priority="2">
		<xsl:text>[[</xsl:text><xsl:value-of select="."/><xsl:text>]]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="referencegroup/reference">
		<xsl:text>relation::&#xa;</xsl:text>
		<xsl:text>relation.type:: includes&#xa;</xsl:text>
		<xsl:text>relation.bibitem.docid.type:: IETF&#xa;</xsl:text>
		<xsl:text>relation.bibitem.docid.id:: </xsl:text>
		<xsl:value-of select="@anchor"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<!-- ================ -->
	<!-- END References -->
	<!-- ================ -->

	<!-- ================ -->
	<!-- Common elements processing -->
	<!-- ================ -->
	
	<xsl:template match="text()">
		<xsl:variable name="firstchar" select="substring(., 1,1)"/>
		<xsl:variable name="lastchar" select="substring(., string-length(.),1)"/>
		<xsl:variable name="normalized_text" select="normalize-space(.)"/>
		<xsl:if test="preceding-sibling::* and ($firstchar = ' ' or $firstchar = '&#xa;' or $firstchar = '&#xd;') and $normalized_text != ''"><xsl:text> </xsl:text></xsl:if>
		<!-- <xsl:value-of select="$normalized_text"/> -->
		<xsl:value-of select="java:org.metanorma.utils.RegExHelper.escapeFormattingCommands($normalized_text)"/>
		<xsl:if test="preceding-sibling::* and following-sibling::* and $normalized_text = '' and not($normalized_text = .)"><xsl:text> </xsl:text></xsl:if>
		<xsl:if test="following-sibling::* and ($lastchar = ' ' or $lastchar = '&#xa;' or $lastchar = '&#xd;') and $normalized_text != ''"><xsl:text> </xsl:text></xsl:if>
	</xsl:template>
	
	
	<xsl:template match="t">
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="@anchor"/>
		<xsl:variable name="t_settings">
			<xsl:for-each select="@keepWithNext  | @keepWithPrevious">
				<xsl:apply-templates select="."/>
				<xsl:if test="position() != last()">,</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="$t_settings != ''">
			<xsl:text>[</xsl:text><xsl:value-of select="$t_settings"/><xsl:text>]&#xa;</xsl:text>
		</xsl:if>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<!-- V3 attributes -->
	<xsl:template match="t/@keepWithNext">
		<xsl:text>keep-with-next=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	<xsl:template match="t/@keepWithPrevious">
		<xsl:text>keep-with-previous=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	<!-- italic -->
	<xsl:template match="spanx[not(@style)] | spanx[@style = 'emph'] | em">
		<xsl:text>_</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>_</xsl:text>
	</xsl:template>
	<xsl:template match="spanx2[not(@style)] | spanx2[@style = 'emph'] | em2">
		<xsl:text>__</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>__</xsl:text>
	</xsl:template>
	
	<!-- bold -->
	<xsl:template match="spanx[@style = 'strong'] | strong">
		<xsl:text>*</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>*</xsl:text>
	</xsl:template>
	<xsl:template match="spanx2[@style = 'strong'] | strong2">
		<xsl:text>**</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>**</xsl:text>
	</xsl:template>
	
	<!-- monospaced -->
	<xsl:template match="spanx[@style = 'verb'] | tt">
		<xsl:text>`</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>`</xsl:text>
	</xsl:template>
	<xsl:template match="spanx2[@style = 'verb'] | tt2">
		<xsl:text>``</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>``</xsl:text>
	</xsl:template>
	
	<!-- subscript -->
	<xsl:template match="sub">
		<xsl:text>~</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>~</xsl:text>
	</xsl:template>
	<xsl:template match="sub2">
		<xsl:text>~~</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>~~</xsl:text>
	</xsl:template>

	<!-- superscript -->
	<xsl:template match="sup">
		<xsl:text>^</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>^</xsl:text>
	</xsl:template>
	<xsl:template match="sup2">
		<xsl:text>^^</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>^^</xsl:text>
	</xsl:template>	
	
	<xsl:template match="bcp14">
		<xsl:text>[bcp14]#</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>#</xsl:text>
	</xsl:template>
	<xsl:template match="bcp142">
		<xsl:text>[bcp14]#</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>#</xsl:text>
	</xsl:template>
	
	<xsl:template match="br">
		<xsl:text> +&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="figure" name="figure">
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="@anchor"/>
		
		<xsl:apply-templates select="artwork/@name"/>
		
		<xsl:variable name="isFigureWrapper">
			<xsl:if test="@title or name or @suppress-title or preamble or postamble">true</xsl:if>
		</xsl:variable>
		
		<xsl:if test="$isFigureWrapper = 'true'">
		
			<xsl:variable name="figure_settings">
				<xsl:for-each select="artwork/@align | artwork/@alt | @suppress-title">
					<xsl:apply-templates select="."/>
					<xsl:if test="position() != last()">,</xsl:if>
				</xsl:for-each>
			</xsl:variable>
			<xsl:if test="$figure_settings != ''">
				<xsl:text>[</xsl:text><xsl:value-of select="$figure_settings"/><xsl:text>]&#xa;</xsl:text>
			</xsl:if>
		
			<!-- <xsl:if test="@suppress-title or artwork/@align or artwork/@alt">
				<xsl:text>[</xsl:text>
				<xsl:for-each select="artwork/@align | artwork/@alt | @suppress-title">
					<xsl:apply-templates select="."/>
					<xsl:if test="position() != last()">,</xsl:if>
				</xsl:for-each>
				<xsl:text>]</xsl:text>
				<xsl:text>&#xa;</xsl:text>
			</xsl:if> -->
			<xsl:apply-templates select="@title" mode="title"/>
			<xsl:apply-templates select="name" mode="title"/>
			<xsl:if test="count(artwork/node()) = 0">
				<xsl:text>====</xsl:text>
				<xsl:text>&#xa;</xsl:text>
			</xsl:if>
			<xsl:apply-templates select="preamble"/>
		</xsl:if>
		
		<xsl:apply-templates select="artset | artwork | sourcecode"/>
		
		<xsl:if test="normalize-space(artwork/text()) = '' and artwork/@src and not(sourcecode)">
			<xsl:text>image::</xsl:text><xsl:value-of select="artwork/@src"/>
			<xsl:if test="artwork/@alt">
				<xsl:text>[</xsl:text><xsl:value-of select="artwork/@alt"/><xsl:text>]</xsl:text>
				<xsl:text>&#xa;</xsl:text>
			</xsl:if>
		</xsl:if>
		
		<xsl:if test="$isFigureWrapper = 'true'">
			<xsl:apply-templates select="postamble"/>
			<xsl:if test="count(artwork/node()) = 0">
				<xsl:text>====</xsl:text>
				<xsl:text>&#xa;</xsl:text>
			</xsl:if>
		</xsl:if>
	</xsl:template>
		
	<xsl:template match="figure/@title" mode="title">
		<xsl:text>.</xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	<xsl:template match="figure/name" mode="title">
		<xsl:text>.</xsl:text><xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	<xsl:template match="figure/name"/>
	
	<xsl:template match="figure/@suppress-title">
		<xsl:text>suppress-title=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="figure/@type">
		<xsl:text>type=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="artset">
		<xsl:apply-templates select="@anchor"/>
		<xsl:apply-templates select="artwork"/>
	</xsl:template>
	
	<xsl:template match="artwork">
		<!-- <xsl:apply-templates select="@name"/> -->
		<xsl:variable name="artwork_type">figure</xsl:variable>
			<!-- <xsl:choose>
				<xsl:when test="2 = 3">figure</xsl:when>
				<xsl:otherwise>sourcecode</xsl:otherwise>
			</xsl:choose>
		</xsl:variable> -->
		
		<xsl:apply-templates select="@anchor"/>
		
		<xsl:choose>
			<xsl:when test="$artwork_type = 'sourcecode'">
				<xsl:text>[source</xsl:text>
				<xsl:if test="@type">,<xsl:value-of select="@type"/></xsl:if>
				<xsl:if test="@src">,<xsl:apply-templates select="@src"/></xsl:if>
				<xsl:if test="@align">,<xsl:apply-templates select="@align"/></xsl:if>
				<xsl:if test="@alt">,<xsl:apply-templates select="@alt"/></xsl:if>			
				<xsl:text>]</xsl:text>
				<xsl:text>&#xa;</xsl:text>
				<xsl:if test="count(node()) != 0">
					<xsl:text>----</xsl:text>
					<xsl:choose>
						<xsl:when test="@type = 'svg' and svg:svg">
							<xsl:apply-templates mode="svg"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates />
						</xsl:otherwise>
					</xsl:choose>
					<xsl:text>----</xsl:text>
					<xsl:if test="following-sibling::artwork">
						<xsl:text>&#xa;</xsl:text>
					</xsl:if>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="@align | @alt | ../@type | @type">
					<xsl:if test="position() = 1">[</xsl:if>
					<xsl:apply-templates select="."/>
					<xsl:if test="position() != last()">,</xsl:if>
					<xsl:if test="position() = last()">]&#xa;</xsl:if>
				</xsl:for-each>
				<xsl:if test="count(node()) != 0">
					<xsl:text>....</xsl:text>
					<xsl:choose>
						<xsl:when test="@type = 'svg' and svg:svg">
							<xsl:apply-templates mode="svg"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates />
						</xsl:otherwise>
					</xsl:choose>
					<xsl:text>....</xsl:text>
					<xsl:if test="following-sibling::artwork">
						<xsl:text>&#xa;</xsl:text>
					</xsl:if>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>

		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<!-- =================== -->
	<!-- artwork /svg processing -->
	<!-- =================== -->
	<xsl:template match="artwork/svg:svg" mode="svg" priority="2">
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&lt;svg xmlns="http://www.w3.org/2000/svg"</xsl:text>
		<xsl:apply-templates select="@*" mode="svg"/>
		<xsl:text>&gt;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates mode="svg"/>
		<xsl:text>&lt;/svg&gt;&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="artwork//*" mode="svg">
		<xsl:text>&lt;</xsl:text>
		<xsl:value-of select="name()"/>
		<xsl:apply-templates select="@*" mode="svg"/>
		<xsl:text>&gt;</xsl:text>
		<xsl:apply-templates mode="svg"/>
		<xsl:text>&lt;/</xsl:text>
		<xsl:value-of select="name()"/>
		<xsl:text>&gt;&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="artwork//*/@*" mode="svg">
		<xsl:text> </xsl:text>
		<xsl:value-of select="name()"/>
		<xsl:text>="</xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>"</xsl:text>
	</xsl:template>
	
	<xsl:template match="artwork//text()" mode="svg"><xsl:value-of select="." /></xsl:template>
	<!-- =================== -->
	<!-- END of artwork /svg processing -->
	<!-- =================== -->
	
	
	<xsl:template match="artwork/@name">
		<xsl:if test=". != ''">
			<xsl:text>.</xsl:text><xsl:value-of select="."/>
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	
	
	<xsl:template match="artwork/@src">
		<xsl:text>src=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="artwork/@align">
		<xsl:text>align=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="artwork/@alt">
		<xsl:text>alt=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="artwork/text() | sourcecode/text()">
		<xsl:variable name="firstchar" select="substring(., 1,1)"/>
		<xsl:variable name="lastchar" select="substring(., string-length(.),1)"/>
		<xsl:if test="$firstchar != '&#x0d;' and $firstchar != '&#x0a;'">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		<xsl:value-of select="."/>
		<xsl:if test="$lastchar != '&#x0d;' and $lastchar != '&#x0a;'">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="preamble">
		<xsl:apply-templates />
		<xsl:text>&#xa;&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="postamble">
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="t[parent::list]/@anchor">
		<xsl:text>[[</xsl:text><xsl:value-of select="."/><xsl:text>]] </xsl:text>
	</xsl:template>
	
	<xsl:template match="comment()">
		<xsl:variable name="firstchar" select="substring(., 1,1)"/>
		<xsl:variable name="lastchar" select="substring(., string-length(.),1)"/>
		<xsl:if test="$firstchar != '&#x0d;' and $firstchar != '&#x0a;'">
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
		
		<xsl:text>[comment]#</xsl:text><xsl:value-of select="."/><xsl:text># </xsl:text>
		
		<xsl:if test="$lastchar != '&#x0d;' and $lastchar != '&#x0a;'">
			<xsl:text>&#xa;&#xa;</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="crefV2">
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>NOTE: </xsl:text><xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="@anchor"/>
		<xsl:text>[NOTE</xsl:text><xsl:apply-templates select="@source"/><xsl:text>]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>====</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>====</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="crefV2/@source">
		<xsl:text>,source=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="cref">
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="@anchor"/>
		<xsl:variable name="cref_settings">
			<xsl:for-each select="@source | @display">
				<xsl:apply-templates select="."/>
				<xsl:if test="position() != last()">,</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="$cref_settings != ''">
			<xsl:text>[</xsl:text><xsl:value-of select="$cref_settings"/><xsl:text>]&#xa;</xsl:text>
		</xsl:if>
		<xsl:apply-templates select="name" mode="title"/>
		<xsl:text>****</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>****</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	<xsl:template match="cref/@source">
		<xsl:text>reviewer="</xsl:text><xsl:value-of select="."/><xsl:text>"</xsl:text>
	</xsl:template>
	<xsl:template match="cref/@display">
		<xsl:text>display=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	<xsl:template match="cref/name" />
	<xsl:template match="cref/name" mode="title">
		<xsl:text>.</xsl:text><xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="iref[@item]">
		<xsl:if test="@subitem">(</xsl:if>
		<xsl:text>((</xsl:text>
		<xsl:if test="@primary = 'true'">primary:</xsl:if>
		<xsl:value-of select="@item"/>
		<xsl:if test="@subitem">
			<xsl:text>, </xsl:text><xsl:value-of select="@subitem"/>
		</xsl:if>
		<xsl:text>))</xsl:text>
		<xsl:if test="@subitem">)</xsl:if>
	</xsl:template>

	<xsl:template match="xref">
		<xsl:text>&lt;&lt;</xsl:text>
		<xsl:value-of select="@target"/>
		<xsl:variable name="displayreference_to" select="/rfc/back/displayreference[@target = current()/@target]/@to"/>
		<xsl:choose>
			<xsl:when test="@format">
				<xsl:text>,format=</xsl:text><xsl:value-of select="@format"/>
				<xsl:choose>
					<xsl:when test="normalize-space(.) != ''">
						<xsl:text>: </xsl:text><xsl:value-of select="."/>
					</xsl:when>
					<xsl:when test="normalize-space($displayreference_to) != ''">
						<xsl:text>: </xsl:text><xsl:value-of select="$displayreference_to"/>
					</xsl:when>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="normalize-space(.) != ''">
				<xsl:text>,</xsl:text><xsl:value-of select="."/>
			</xsl:when>
			<xsl:when test="normalize-space($displayreference_to) != ''">
				<xsl:text>,</xsl:text><xsl:value-of select="$displayreference_to"/>
			</xsl:when>
		</xsl:choose>
		<xsl:text>&gt;&gt;</xsl:text>
	</xsl:template>

	<xsl:template match="eref">
		<xsl:text> </xsl:text>
		<xsl:if test="@brackets = 'angle'"><xsl:text>&amp;lt;</xsl:text></xsl:if>
		<xsl:value-of select="@target"/>
		<xsl:if test="normalize-space(.) != ''">
			<xsl:text>[</xsl:text><xsl:value-of select="."/><xsl:text>]</xsl:text>
		</xsl:if>
		<xsl:if test="@brackets = 'angle'"><xsl:text>&amp;gt;</xsl:text></xsl:if>
	</xsl:template>

	<xsl:template match="vspace">
		<xsl:variable name="break" select="' +&#xa;'"/>
		<xsl:variable name="counter">
			<xsl:choose>
				<xsl:when test="@blankLines"><xsl:value-of select="@blankLines + 1"/></xsl:when>
				<xsl:otherwise>1</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:call-template name="repeat">
			<xsl:with-param name="char" select="$break"/>
			<xsl:with-param name="count" select="$counter"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="@anchor">
		<xsl:text>[[</xsl:text><xsl:value-of select="."/><xsl:text>]]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<!-- ================ -->
	<!-- END Common elements processing -->
	<!-- ================ -->

	<!-- ================ -->
	<!-- List processing -->
	<!-- ================ -->

	<xsl:template match="list">
		<xsl:variable name="list_level" select="count(ancestor::list)" />
		<xsl:if test="$list_level &gt; 0">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if>
		
		<xsl:variable name="list_settings">
			<xsl:for-each select="@counter | @hangIndent | @style">
				<xsl:apply-templates select="."/>
				<xsl:if test="position() != last()">,</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="$list_settings != ''">
			<xsl:text>[</xsl:text><xsl:value-of select="$list_settings"/><xsl:text>]&#xa;</xsl:text>
		</xsl:if>
		
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template match="list/@counter">
		<xsl:text>counter=</xsl:text><xsl:value-of select="."/>
	</xsl:template>

	<xsl:template match="list/@hangIndent">
		<xsl:text>hang-indent=</xsl:text><xsl:value-of select="."/>
	</xsl:template>

	<xsl:template match="list/@style">
		<xsl:choose>
			<xsl:when test=". = 'empty'">empty=true</xsl:when>
			<xsl:when test=". = 'letters'">loweralpha</xsl:when>
			<xsl:when test=". = 'numbers'">arabic</xsl:when>
			<xsl:when test=". = 'hanging'"><!--skip, processed in list/t--></xsl:when>
			<xsl:when test="starts-with(., 'format ')">format=<xsl:value-of select="substring-after(., 'format ')"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="list/t">
		<xsl:choose>
			<!-- definition list -->
			<xsl:when test="parent::list/@style='hanging'">
				<xsl:value-of select="@hangText"/><xsl:text>::</xsl:text>
				<!-- <xsl:text>&#xa;</xsl:text> -->
				<xsl:apply-templates select="@anchor"/>
				<xsl:apply-templates />
				<xsl:text>&#xa;&#xa;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="listitem_label">
					<xsl:choose>
						<xsl:when test="contains('format |letters|numbers|arabic|loweralpha|upperralpha|lowerroman|upperroman', parent::list/@style)">.</xsl:when>
						<xsl:when test="starts-with(parent::list/@style , 'format')">.</xsl:when>
						<xsl:when test="parent::list/@style = 'symbols'">*</xsl:when>
						<xsl:otherwise>*</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="list_level" select="count(ancestor::list)" />
				<xsl:value-of select="str:padding($list_level, $listitem_label)"/>
				<xsl:text> </xsl:text>
				<xsl:apply-templates select="@anchor"/>
				<xsl:apply-templates />
				<xsl:text>&#xa;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- =================== -->
	<!-- V3 List processing -->
	<!-- =================== -->
	<xsl:template match="ul">
		<!-- <xsl:variable name="list_level" select="count(ancestor::list) + count(ancestor::ul) + count(ancestor::ol)" />
		<xsl:if test="$list_level = 0">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if> -->
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="@anchor"/>
		<xsl:variable name="ul_settings">
			<xsl:for-each select="@empty | @spacing | @bare">
				<xsl:variable name="item"><xsl:apply-templates select="."/></xsl:variable>
				<xsl:if test="normalize-space($item) != ''">
					<xsl:value-of select="$item"/>
					<xsl:if test="position() != last()">,</xsl:if>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="$ul_settings != ''">
			<xsl:text>[</xsl:text><xsl:value-of select="$ul_settings"/><xsl:text>]&#xa;</xsl:text>
		</xsl:if>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="ul/@empty">
		<xsl:text>nobullet=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="ul/@spacing">
		<xsl:text>spacing=</xsl:text><xsl:value-of select="."/>
	</xsl:template>

	<xsl:template match="ul/@bare">
		<xsl:if test="not(../@empty)">
			<xsl:text>nobullet=</xsl:text><xsl:value-of select="."/>
		</xsl:if>
	</xsl:template>
	
	
	<xsl:template match="ol">
		<!-- <xsl:variable name="list_level" select="count(ancestor::list) + count(ancestor::ul) + count(ancestor::ol)" />
		<xsl:if test="$list_level = 0">
			<xsl:text>&#xa;</xsl:text>
		</xsl:if> -->
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="@anchor"/>
		<xsl:variable name="ol_settings">
			<xsl:for-each select="@spacing | @start | @group | @type">
				<xsl:apply-templates select="."/>
				<xsl:if test="position() != last()">,</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="$ol_settings != ''">
			<xsl:text>[</xsl:text><xsl:value-of select="$ol_settings"/><xsl:text>]&#xa;</xsl:text>
		</xsl:if>
		<xsl:apply-templates />
	</xsl:template>

	<xsl:template match="ol/@spacing">
		<xsl:text>spacing=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="ol/@start">
		<xsl:text>start=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="ol/@group">
		<xsl:text>group=</xsl:text><xsl:value-of select="."/>
	</xsl:template>

	<xsl:template match="ol/@type">
		<xsl:text>format=</xsl:text>
		<xsl:choose>
			<xsl:when test=". = 'arabic' or . = 'loweralpha' or . = 'upperralpha' or . = 'lowerroman' or . = 'upperroman'"><xsl:value-of select="."/></xsl:when>
			<xsl:when test=". = 'a'">loweralpha</xsl:when>
			<xsl:when test=". = 'A'">upperralpha</xsl:when>
			<xsl:when test=". = '1'">arabic</xsl:when>
			<xsl:when test=". = 'i'">lowerroman</xsl:when>
			<xsl:when test=". = 'I'">upperroman</xsl:when>
			<xsl:when test="contains(., '%')">List #<xsl:value-of select="."/></xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="li">
		<xsl:variable name="listitem_label">
			<xsl:choose>
				<xsl:when test="parent::ol">.</xsl:when>
				<xsl:when test="parent::ul">*</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="list_level" select="count(ancestor::list | ancestor::ul | ancestor::ol)" />
		<xsl:value-of select="str:padding($list_level, $listitem_label)"/>
		<xsl:text> </xsl:text>
		<xsl:apply-templates select="@anchor"/>
		<xsl:apply-templates />
		<xsl:choose>
			<xsl:when test="ul or ol"></xsl:when>
			<xsl:otherwise>
				<xsl:text>&#xa;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	<xsl:template match="li/t">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="li/text()">
		<xsl:choose>
			<xsl:when test=". = '&#xd;' or . = '&#xa;' or . = '&#xd;&#xa;'"></xsl:when>
			<xsl:otherwise>
				<xsl:variable name="text" select="normalize-space(.)"/>
				<xsl:value-of select="$text"/>
				<xsl:if test="$text = ''"> </xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="dl">
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="@anchor"/>
		<xsl:variable name="dl_settings">
			<xsl:for-each select="@hanging | @newline | @spacing | @indent">
				<xsl:apply-templates select="."/>
				<xsl:if test="position() != last()">,</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="$dl_settings != ''">
			<xsl:text>[</xsl:text><xsl:value-of select="$dl_settings"/><xsl:text>]&#xa;</xsl:text>
		</xsl:if>
		<xsl:apply-templates />
	</xsl:template>

	<xsl:template match="dl/@hanging | dl/@newline">
		<xsl:text>newline=</xsl:text><xsl:value-of select="."/>
	</xsl:template>

	<xsl:template match="dl/@spacing">
		<xsl:text>spacing=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="dl/@indent">
		<xsl:text>indent=</xsl:text><xsl:value-of select="."/>
	</xsl:template>

	<xsl:template match="dt">
		<xsl:apply-templates select="@anchor"/>
		<xsl:apply-templates />
		<xsl:text>:: </xsl:text>
	</xsl:template>

	<xsl:template match="dt/@anchor">
		<xsl:text>[[</xsl:text><xsl:value-of select="."/><xsl:text>]] </xsl:text>
	</xsl:template>

	<xsl:template match="dd">
		<xsl:apply-templates select="@anchor"/>
		<xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template match="dd/@anchor">
		<xsl:text>[[</xsl:text><xsl:value-of select="."/><xsl:text>]]</xsl:text>
	</xsl:template>

	<!-- =================== -->
	<!-- End V3 List processing -->
	<!-- =================== -->

	<!-- ================ -->
	<!-- End of List processing -->
	<!-- ================ -->

	<!-- ================ -->
	<!-- Table processing -->
	<!-- ================ -->
	
	<xsl:template match="texttable">
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="@anchor"/>
		<xsl:apply-templates select="preamble"/>
		<xsl:variable name="table_settings">
			<xsl:for-each select="@suppress-title | @align | @style">
				<xsl:apply-templates select="."/>
				<xsl:if test="position() != last()">,</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="$table_settings != ''">
			<xsl:text>[</xsl:text><xsl:value-of select="$table_settings"/><xsl:text>]&#xa;</xsl:text>
		</xsl:if>
		
		<xsl:apply-templates select="@title" mode="title"/>
		<xsl:apply-templates select="name" mode="title"/>
		<xsl:text>|===</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="ttcol" mode="table_header"/>
		<xsl:apply-templates select="ttcol" mode="columns_align"/>
		<xsl:apply-templates select="c">
			<xsl:with-param name="colcount" select="count(ttcol)"/>
		</xsl:apply-templates>
		<xsl:text>|===</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="postamble"/>
	</xsl:template>
	
	
	<xsl:template match="texttable/@suppress-title">
		<xsl:text>suppress-title=</xsl:text><xsl:value-of select="."/>
	</xsl:template>

	<xsl:template match="texttable/@align">
		<xsl:text>align=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="texttable/@style">
		<xsl:text>grid=</xsl:text>
		<xsl:choose>
			<xsl:when test=". = 'all'">all</xsl:when>
			<xsl:when test=". = 'full'">cols</xsl:when>
			<xsl:when test=". = 'none'">none</xsl:when>
			<xsl:when test=". = 'headers'">rows</xsl:when>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="texttable/@title" mode="title">
		<xsl:text>.</xsl:text><xsl:value-of select="."/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	<xsl:template match="texttable/name" mode="title">
		<xsl:text>.</xsl:text><xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	<xsl:template match="texttable/name"/>
	
	<xsl:template match="texttable/ttcol" mode="table_header">
		<xsl:text>|</xsl:text>
		<xsl:apply-templates/>
		<xsl:if test="position() = last()"><xsl:text>&#xa;</xsl:text></xsl:if>
	</xsl:template>
	
	<xsl:template match="texttable/ttcol" mode="columns_align">
		<xsl:text>|</xsl:text>
		<xsl:choose>
				<xsl:when test="@align = 'left'">:---</xsl:when>
				<xsl:when test="@align = 'center'">:--:</xsl:when>
				<xsl:when test="@align = 'right'">---:</xsl:when>
				<xsl:otherwise>----</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="position() = last()"><xsl:text>&#xa;&#xa;</xsl:text></xsl:if>
	</xsl:template>
	
	<xsl:template match="texttable/c">
		<xsl:param name="colcount"/>
		<xsl:text>|</xsl:text>
		<xsl:apply-templates />
		<xsl:if test="position() mod $colcount = 0">
			<xsl:text>&#xA;</xsl:text>
		</xsl:if>
		<xsl:if test="position() = last()"><xsl:text>&#xA;</xsl:text></xsl:if>
	</xsl:template>
	
	<!-- ================ -->
	<!-- End of Table processing -->
	<!-- ================ -->

	<!-- ================ -->
	<!-- V3 Elements processing -->
	<!-- ================ -->
	
	<xsl:template match="@pn"/>
		
	<xsl:template match="note/@removeInRFC">
		<xsl:text>remove-in-rfc=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
		
	<xsl:template match="@removeInRFC">
		<xsl:text>removeInRFC=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	
	<!-- ================ -->
	<!-- sourcecode processing -->
	<!-- ================ -->
	<xsl:template match="sourcecode">
		<xsl:text>&#xa;</xsl:text>
		<xsl:text>[source</xsl:text>
		<xsl:variable name="sourcecode_settings">
			<xsl:for-each select="@name | @src | @type | @removeInRFC | @markers">
				<xsl:text>,</xsl:text>
				<xsl:apply-templates select="."/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="$sourcecode_settings != ''">
			<xsl:value-of select="$sourcecode_settings"/>
		</xsl:if>
		<xsl:text>]&#xa;</xsl:text>
		
		<xsl:text>----</xsl:text>
		<xsl:apply-templates />
		<xsl:text>----</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
		
	<xsl:template match="sourcecode/@name">
		<xsl:text>filename=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="sourcecode/@src">
		<xsl:text>src=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="sourcecode/@type">
		<xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="sourcecode/@markers">
		<xsl:text>markers=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	<!-- ================ -->
	<!-- End of sourcecode processing -->
	<!-- ================ -->
	
	<!-- ================ -->
	<!-- Aside note processing -->
	<!-- ================ -->
	<xsl:template match="aside">
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="@anchor"/>
		<xsl:text>NOTE: </xsl:text>
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="aside/t">
		<xsl:if test="position() &gt; 1"><xsl:text>&#xa;</xsl:text></xsl:if>
		<xsl:apply-templates/>
	</xsl:template>
	<!-- ================ -->
	<!-- End of Aside note processing -->
	<!-- ================ -->
	
	
	<!-- ================ -->
	<!-- V3 table processing -->
	<!-- ================ -->
	<xsl:template match="table">
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="@anchor"/>
		<xsl:apply-templates select="name" mode="title"/>
		<xsl:apply-templates select="@align"/>
		<xsl:text>|===</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		
		<xsl:apply-templates/>
		
		<xsl:text>|===</xsl:text>
		<xsl:text>&#xa;</xsl:text>
		
	</xsl:template>

	<xsl:template match="table/@align">
		<xsl:text>[align=</xsl:text><xsl:value-of select="."/><xsl:text>]</xsl:text>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>

	<xsl:template match="table/name" mode="title">
		<xsl:text>.</xsl:text><xsl:apply-templates />
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	<xsl:template match="table/name"/>
	
	<xsl:template match="table/thead">
		<xsl:apply-templates/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="table/thead/tr | table/tfoot/tr" priority="2">
		<xsl:apply-templates/>
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates mode="align"/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="table//tr">
		<xsl:apply-templates/>
		<xsl:text>&#xa;</xsl:text>
	</xsl:template>
	
	<xsl:template match="table//td | table//th">
		<xsl:call-template name="spanProcessing"/>		
		<xsl:if test="local-name() = 'th' and position() = 1">h</xsl:if>
		<xsl:if test="list or ol or ul or dl or count(t) &gt; 1">a</xsl:if>
		<xsl:text>|</xsl:text>
		<xsl:if test="position() &gt; 1"><xsl:text> </xsl:text></xsl:if>
		<xsl:apply-templates select="@anchor"/>
		<xsl:apply-templates/>
		<xsl:if test="position() != last()"><xsl:text> </xsl:text></xsl:if>
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
	</xsl:template>
	
	<xsl:template match="table//td | table//th" mode="align">
		<xsl:text>|</xsl:text>
		<xsl:if test="position() &gt; 1"><xsl:text> </xsl:text></xsl:if>
		<xsl:choose>
			<xsl:when test="@align = 'left'">:---</xsl:when>
			<xsl:when test="@align = 'center'">:--:</xsl:when>
			<xsl:when test="@align = 'right'">---:</xsl:when>
			<xsl:otherwise>----</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="position() != last()"><xsl:text> </xsl:text></xsl:if>
	</xsl:template>
	
	
	
	<xsl:template match="table//td/@anchor | table//th/@anchor">
		<xsl:text>[[</xsl:text><xsl:value-of select="."/><xsl:text>]] </xsl:text>
	</xsl:template>
	
	<xsl:template match="table/tfoot">
		<xsl:text>&#xa;&#xa;</xsl:text>
		<xsl:apply-templates/>
	</xsl:template>
	
	<!-- ================ -->
	<!-- End of V3 table processing -->
	<!-- ================ -->
	
	<!-- ================ -->
	<!-- blockquote processing -->
	<!-- ================ -->
	<xsl:template match="blockquote">
		<xsl:text>&#xa;</xsl:text>
		<xsl:apply-templates select="@anchor"/>
		<xsl:text>[quote</xsl:text>
		<xsl:for-each select="@quotedFrom | @cite">
			<xsl:text>,</xsl:text>
			<xsl:apply-templates select="."/>
		</xsl:for-each>
		<xsl:text>]</xsl:text>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="blockquote/@quotedFrom">
		<xsl:text>attribution=</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="blockquote/@cite">
		<xsl:value-of select="."/>
	</xsl:template>
	
	<!-- ================ -->
	<!-- End of blockquote processing -->
	<!-- ================ -->
	
	
	<!-- ================ -->
	<!-- relref processing -->
	<!-- ================ -->
	<xsl:template match="relref">
		<xsl:text>&lt;&lt;</xsl:text>
		<xsl:value-of select="@target"/>
		
		<xsl:variable name="relative">
			<xsl:apply-templates select="@relative"/>
		</xsl:variable>
		<xsl:value-of select="$relative"/>
		
		<xsl:variable name="displayFormat" select="@displayFormat"/>
		<xsl:variable name="section" select="@section"/>
		
		<xsl:variable name="relref_settings">
			<xsl:choose>
				<xsl:when test="normalize-space($relative) = ''">
					<xsl:value-of select="@displayFormat"/>
					<xsl:if test="@displayFormat and @section">,</xsl:if>
					<xsl:value-of select="@section"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="@section"/>
					<xsl:if test="@displayFormat and @section"><xsl:text> </xsl:text></xsl:if>
					<xsl:value-of select="@displayFormat"/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="normalize-space(.) != ''">
				<xsl:text>: </xsl:text><xsl:apply-templates /> <!-- : text -->
			</xsl:if>
		</xsl:variable>
		
		<xsl:if test="normalize-space($relref_settings) != ''">
			<xsl:text>,</xsl:text><xsl:value-of select="$relref_settings"/>
		</xsl:if>
		<xsl:text>&gt;&gt;</xsl:text>
	</xsl:template>
	
	<xsl:template match="relref/@relative">
		<xsl:text>#</xsl:text><xsl:value-of select="."/>
	</xsl:template>
	
	
	<!-- ================ -->
	<!-- End of relref processing -->
	<!-- ================ -->
	
	<xsl:template match="contact[not(parent::section)]">
		<xsl:apply-templates select="@*"/>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="contact[not(parent::section)]/@*">
		<xsl:value-of select="."/>
	</xsl:template>
	
	<!-- ================ -->
	<!-- V3 End of Elements processing -->
	<!-- ================ -->


	<xsl:template name="commafy">
		<xsl:param name="nodes" />		
		<xsl:for-each select="$nodes">
			<!-- <xsl:text>"</xsl:text> -->
			<xsl:value-of select="normalize-space(.)" />
			<!-- <xsl:text>"</xsl:text> -->
			<xsl:if test="position() != last()">, </xsl:if>
		</xsl:for-each>
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

	<!-- ======================== -->
	<!-- XML Linearization -->
	<!-- ======================== -->
	<xsl:template match="@*|node()" mode="linearize">
		<xsl:copy>
				<xsl:apply-templates select="@*|node()" mode="linearize"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="text()[not(parent::figure or parent::artset or parent::artwork or parent::texttable or parent::sourcecode or parent::code or parent::mml:* or
	parent::strong or parent::em or parent::spanx or parent::sub or parent::sup or parent::bcp14 or parent::tt)]" mode="linearize">
		<xsl:choose>
			<xsl:when test="contains(., '&#xa;')">
				<xsl:variable name="text_" select="translate(., '&#xa;&#x9;', '  ')"/>
				<xsl:variable name="text" select="java:replaceAll(java:java.lang.String.new($text_),' +',' ')"/>
				<xsl:if test="normalize-space($text) != ''">
					<xsl:call-template name="trimSpaces">
						<xsl:with-param name="text" select="$text"/>
					</xsl:call-template>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<!-- <xsl:value-of select="."/> -->
				<xsl:call-template name="trimSpaces"/>
			</xsl:otherwise>
		</xsl:choose>		
	</xsl:template>
	
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

		<xsl:value-of select="$text_righttrim"/>
	</xsl:template>
	
	<xsl:template match="strong | em | spanx | sub |  sup | bcp14 | tt" mode="linearize">
		<xsl:call-template name="processUnconstrainedFormatting"/>
	</xsl:template>
	
	<xsl:template name="processUnconstrainedFormatting">
		<xsl:variable name="unconstrained_formatting"><xsl:call-template name="is_unconstrained_formatting"/></xsl:variable>
		<xsl:choose>
			<xsl:when test="$unconstrained_formatting = 'true'">
				<!-- create element b2, i2, sup2, etc. -->
				<xsl:element name="{local-name()}2">
					<xsl:apply-templates select="@*" mode="linearize"/>
					<xsl:apply-templates  mode="linearize"/>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<!-- copy 'as is' -->
				<xsl:copy-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- https://docs.asciidoctor.org/asciidoc/latest/text/ -->
	<!-- Unconstrained formatting pair -->
	<xsl:template name="is_unconstrained_formatting">
	
		<xsl:variable name="prev_text" select="preceding-sibling::node()[1]"/>
		<xsl:variable name="prev_char" select="substring($prev_text, string-length($prev_text))"/>
		
		<xsl:variable name="next_text" select="following-sibling::node()[1]"/>
		<xsl:variable name="next_char" select="substring($next_text, 1, 1)"/>
		
		<xsl:variable name="text" select="."/>
		<xsl:variable name="first_char" select="substring($text, 1, 1)"/>
		<xsl:variable name="last_char" select="substring($text, string-length($text))"/>
		
		<xsl:choose>
			<!--  a blank space does not precede the text to format -->
			<xsl:when test="$prev_char != '' and $prev_char != ' '">true</xsl:when>
			
			<!-- a blank space or punctuation mark (, ; " . ? or !) does not directly follow the text -->
			<xsl:when test="$next_char != '' and $next_char != ' ' and 
													$next_char != ',' and $next_char != ';' and $next_char != '&quot;' and $next_char != '.' and $next_char != '?' and $next_char != '!'">true</xsl:when>
													
			<!-- text does not start or end with a word character -->
			<xsl:when test="java_char:isLetter($first_char) != 'true' or java_char:isLetter($last_char) != 'true'">true</xsl:when>
			
			<xsl:otherwise>false</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- ======================== -->
	<!-- End XML Linearization -->
	<!-- ======================== -->
	

</xsl:stylesheet>
