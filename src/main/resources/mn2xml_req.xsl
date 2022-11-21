<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
			xmlns:mml="http://www.w3.org/1998/Math/MathML" 
			xmlns:xlink="http://www.w3.org/1999/xlink" 
			xmlns:xalan="http://xml.apache.org/xalan" 
			xmlns:java="http://xml.apache.org/xalan/java" 
			xmlns:redirect="http://xml.apache.org/xalan/redirect"
			xmlns:metanorma-class="xalan://org.metanorma.utils.RegExHelper"
			exclude-result-prefixes="xalan java metanorma-class" 
			extension-element-prefixes="redirect"
			version="1.0">

	<!-- ======================= -->
	<!-- requirement processing  -->
	<!-- ======================= -->

	<xsl:variable name="requirements_">
		<xsl:for-each select="$xml//requirement[not(ancestor::requirement)]">
			<xsl:copy>
				<xsl:copy-of select="@id"/>
				<xsl:copy-of select="@type"/>
				<xsl:attribute name="num">
					<xsl:choose>
						<xsl:when test="@type = 'class'"><xsl:number count="requirement[not(ancestor::requirement)][@type = 'class']" level="any"/></xsl:when>
						<xsl:otherwise><xsl:number count="requirement[not(ancestor::requirement)][not(@type = 'class')]" level="any"/></xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				<xsl:copy-of select="title"/>
				<xsl:copy-of select="identifier"/>
				
				<xsl:for-each select="requirement">
					<xsl:copy>
						<xsl:copy-of select="identifier"/>
					</xsl:copy>
				</xsl:for-each>
				
			</xsl:copy>
		</xsl:for-each>
	</xsl:variable>
	<xsl:variable name="requirements" select="xalan:nodeset($requirements_)"/>

	<xsl:variable name="requirements_labels_">
		<default>
			requirement: Requirement#
			recommendation: Recommendation#
			permission: Permission#
			obligation: Obligation#
			subject: Subject#
			inherits: Inherits#
		</default>
		<modspec>
			recommendationtest: Recommendation test#
			requirementtest: Requirement test#
			permissiontest: Permission test#
			recommendationclass: Recommendations class#
			requirementclass: Requirements class#
			permissionclass: Permissions class#
			abstracttest: Abstract test#
			conformanceclass: Conformance class#
			conformancetest: Conformance test#
			targettype: Target type#
			target: Target#
			testpurpose: Test purpose#
			testmethod: Test method#
			dependency: Prerequisite#
			indirectdependency: Indirect prerequisite#
			identifier: Identifier#
			included_in: Included in#
			statement: Statement#
			description: Description#
			guidance: Guidance#
			implements: Implements#
			provision: Normative statement#
		</modspec>
	</xsl:variable>
	<xsl:variable name="requirements_labels" select="xalan:nodeset($requirements_labels_)"/>
	<xsl:variable name="requirements_labels_newline">#</xsl:variable>
	<xsl:template name="getRequirementLabel">
		<xsl:param name="node">default</xsl:param>
		<xsl:param name="label"/>
		<xsl:value-of select="substring-before(substring-after($requirements_labels/*[local-name() = $node]/text(), concat($label,':')), $requirements_labels_newline)"/><!--   -->
	</xsl:template>
	
	<xsl:template name="get_recommend_class">
		<xsl:choose>
			<xsl:when test="@type = 'verification' or @type = 'abstracttest'">recommendtest</xsl:when>
			<xsl:when test="@type = 'class' or @type = 'conformanceclass'">recommendclass</xsl:when>
			<xsl:otherwise>recommend</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="requirement">
		<table-wrap>
			<xsl:copy-of select="@id"/>
			<xsl:copy-of select="@section"/>
			<xsl:attribute name="content-type">
				<xsl:call-template name="get_recommend_class"/>
			</xsl:attribute>
			<xsl:attribute name="specific-use">modspec</xsl:attribute>
			<label>
				<xsl:value-of select="@section_prefix"/><xsl:value-of select="@section"/>
			</label>
			<caption>
				<xsl:apply-templates select="title"/>
			</caption>
			<table>
				<tbody>
					<xsl:apply-templates select="node()[not(self::title)]"/>
				</tbody>
			</table>
		</table-wrap>
	</xsl:template>
	
	<xsl:template match="requirement/title">
		<title>
			<xsl:choose>
				<xsl:when test="../@type = 'class'">Requirements class </xsl:when>
				<xsl:otherwise>Requirement </xsl:otherwise>
			</xsl:choose>
			<xsl:number count="requirement[@type = 'class']" level="any"/>
			<xsl:text>: </xsl:text>
			<xsl:apply-templates />
		</title>
	</xsl:template>
	
	<xsl:template match="requirement[not(ancestor::requirement)]/*[not(self::title)]">
		<xsl:variable name="requirement_type" select="../@type"/>
		<tr>
			<th>
				<xsl:choose>
					<xsl:when test="self::subject">
						<xsl:choose>
							<xsl:when test="$requirement_type = 'class'">
								<xsl:call-template name="getRequirementLabel">
									<xsl:with-param name="node" select="'modspec'"/>
									<xsl:with-param name="label" select="'targettype'"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:call-template name="getRequirementLabel">
									<xsl:with-param name="label" select="'subject'"/>
								</xsl:call-template>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when> <!-- end subject -->
					
					<xsl:when test="self::target">
						<xsl:choose>
							<xsl:when test="$requirement_type = 'class'">
								<xsl:call-template name="getRequirementLabel">
									<xsl:with-param name="node" select="'modspec'"/>
									<xsl:with-param name="label" select="'targettype'"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:when test="$requirement_type = 'conformanceclass'">
								<xsl:call-template name="getRequirementLabel">
									<xsl:with-param name="node" select="'modspec'"/>
									<xsl:with-param name="label" select="'requirementclass'"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:when test="$requirement_type = 'verification' or $requirement_type = 'abstracttest'">
								<xsl:call-template name="getRequirementLabel">
									<xsl:with-param name="label" select="'requirement'"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:call-template name="getRequirementLabel">
									<xsl:with-param name="node" select="'modspec'"/>
									<xsl:with-param name="label" select="'target'"/>
								</xsl:call-template>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when> <!-- end target -->
					
					<xsl:when test="self::description">
						<xsl:variable name="recommend_class">
							<xsl:for-each select="..">
								<xsl:call-template name="get_recommend_class"/>
							</xsl:for-each>
						</xsl:variable>
						<xsl:choose>
							<xsl:when test="$recommend_class = 'recommend'">
								<xsl:call-template name="getRequirementLabel">
									<xsl:with-param name="node" select="'modspec'"/>
									<xsl:with-param name="label" select="'statement'"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:call-template name="getRequirementLabel">
									<xsl:with-param name="node" select="'modspec'"/>
									<xsl:with-param name="label" select="'description'"/>
								</xsl:call-template>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					
					<xsl:when test="local-name() = 'component' and @class != ''">
						<xsl:call-template name="capitalize">
							<xsl:with-param name="str" select="@class"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="capitalize">
							<xsl:with-param name="str" select="local-name()"/>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</th>
			<td>
				<xsl:choose>
					<xsl:when test="local-name() = 'identifier'">
						<monospace><xsl:apply-templates /></monospace>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates />
					</xsl:otherwise>
				</xsl:choose>
			</td>
		</tr>
		
		<xsl:if test="local-name() = 'subject' and normalize-space(../@type) != 'class'">
			<tr>
				<th>Included in</th>
				<td>
					<xsl:variable name="identifier" select="../identifier"/>
					
					<xsl:for-each select="$requirements/requirement[normalize-space(requirement/identifier) = $identifier]">
						<xref rid="{@id}" ref-type="table">Requirements class <xsl:value-of select="@num"/>: <xsl:value-of select="title"/></xref>
						<xsl:if test="position() != last()">
							<break/>
						</xsl:if>
					</xsl:for-each>
				</td>
			</tr>
		</xsl:if>
		
	</xsl:template>
	
	<!-- first requirement/requirement -->
	<xsl:template match="requirement/requirement[not(preceding-sibling::requirement)]">
		<tr>
			<th>Provisions</th>
			<td>
				<!--
				<xref target="r-identifier-1-1">Requirement 1: Method for constructing identifiers defined</xref>
				<br />
				...
				-->
				<xsl:apply-templates/>
				<xsl:apply-templates select="following-sibling::*">
					<xsl:with-param name="process">true</xsl:with-param>
				</xsl:apply-templates>
			</td>
		</tr>
	</xsl:template>
	
	
	
	<xsl:template match="requirement/requirement[preceding-sibling::requirement]">
		<xsl:param name="process">false</xsl:param>
		<xsl:if test="$process = 'true'">
			<break/>
			<xsl:apply-templates/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="requirement/requirement/identifier">
		<xsl:variable name="identifier" select="normalize-space(.)"/>
		<xsl:variable name="requirement_" select="$requirements/requirement[normalize-space(identifier) = $identifier]"/>
		<xsl:variable name="requirement" select="xalan:nodeset($requirement_)"/>
		
		<xref rid="{$requirement/@id}" ref-type="table">Requirement <xsl:value-of select="$requirement/@num"/>: <xsl:value-of select="$requirement/title"/></xref>
	</xsl:template>
	
	<!-- ======================= -->
	<!-- END: requirement processing -->
	<!-- ======================= -->

	
</xsl:stylesheet>