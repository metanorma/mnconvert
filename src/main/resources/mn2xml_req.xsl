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
						<xsl:when test="ancestor::annex">
							<xsl:variable name="root_element_id" select="generate-id(ancestor::annex)"/>
							<xsl:number format="A" level="any" count="annex"/>
							<xsl:text>.</xsl:text>
							<xsl:choose>
								<xsl:when test="@type = 'class'"><xsl:number format="1" count="requirement[ancestor::*[generate-id() = $root_element_id]][not(ancestor::requirement)][@type = 'class']" level="any"/></xsl:when>
								<xsl:otherwise><xsl:number format="1" count="requirement[ancestor::*[generate-id() = $root_element_id]][not(ancestor::requirement)][not(@type = 'class')]" level="any"/></xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise> <!-- for requirements in sections -->
							<xsl:choose>
								<xsl:when test="@type = 'class'"><xsl:number count="requirement[not(ancestor::requirement)][@type = 'class']" level="any"/></xsl:when>
								<xsl:otherwise><xsl:number count="requirement[not(ancestor::requirement)][not(@type = 'class')]" level="any"/></xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				
				<xsl:attribute name="title_prefix">
					<xsl:for-each select="title">
						<xsl:call-template name="getTitlePrefix"/>
					</xsl:for-each>
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
		<!-- <table-wrap>
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
		</table-wrap> -->
		
		<xsl:variable name="id" select="@id"/>
		
		<!-- process table from presentation XML -->
		<xsl:apply-templates select="$xml_presentation_catalog//*[@id = $id]"/>
		
	</xsl:template>
	
	
	<!-- from mn-requirements\lib\metanorma\modspec\xrefs.rb :
	def req_class_paths
	[
		{ klass: "permissionclass",
			label: @labels["modspec"]["permissionclass"],
			xpath: "permission[@type = 'class']" },
			
		{ klass: "requirementclass",
			label: @labels["modspec"]["requirementclass"],
			xpath: "requirement[@type = 'class']" },
			
		{ klass: "recommendationclass",
			label: @labels["modspec"]["recommendationclass"],
			xpath: "recommendation[@type = 'class']" },
			
		{ klass: "permissiontest",
			label: @labels["modspec"]["conformancetest"],
			xpath: "permission[@type = 'verification']" },
			
		{ klass: "recommendationtest",
			label: @labels["modspec"]["conformancetest"],
			xpath: "recommendation[@type = 'verification']" },
			
		{ klass: "requirementtest",
			label: @labels["modspec"]["conformancetest"],
			xpath: "requirement[@type = 'verification']" },
			
		{ klass: "abstracttest",
			label: @labels["modspec"]["abstracttest"],
			xpath: "permission[@type = 'abstracttest']" },
			
		{ klass: "abstracttest",
			label: @labels["modspec"]["abstracttest"],
			xpath: "requirement[@type = 'abstracttest']" },
			
		{ klass: "abstracttest",
			label: @labels["modspec"]["abstracttest"],
			xpath: "recommendation[@type = 'abstracttest']" },
			
		{ klass: "conformanceclass",
			label: @labels["modspec"]["conformanceclass"],
			xpath: "permission[@type = 'conformanceclass']" },
			
		{ klass: "conformanceclass",
			label: @labels["modspec"]["conformanceclass"],
			xpath: "requirement[@type = 'conformanceclass']" },
			
		{ klass: "conformanceclass",
			label: @labels["modspec"]["conformanceclass"],
			xpath: "recommendation[@type = 'conformanceclass']" },
			
		{ klass: "permission",
			label: @labels["default"]["permission"],
			xpath: "permission[not(@type = 'verification' or @type = 'class' " \
						 "or @type = 'abstracttest' or @type = 'conformanceclass')]" },
						 
		{ klass: "recommendation",
			label: @labels["default"]["recommendation"],
			xpath: "recommendation[not(@type = 'verification' or " \
						 "@type = 'class' or @type = 'abstracttest' or " \
						 "@type = 'conformanceclass')]" },
						 
		{ klass: "requirement",
			label: @labels["default"]["requirement"],
			xpath: "requirement[not(@type = 'verification' or @type = 'class' " \
						 "or @type = 'abstracttest' or @type = 'conformanceclass')]" },
	]
	end -->

	
	<xsl:template match="permission/title | requirement/title | recommendation/title">
		<title>
			<xsl:call-template name="getTitlePrefix"/>
			
			<xsl:variable name="id" select="../@id"/>
			<xsl:value-of select="$requirements/requirement[@id = $id]/@num" />
			<xsl:text>: </xsl:text>
			<xsl:apply-templates />
		</title>
	</xsl:template>
	
	<xsl:template name="getTitlePrefix">
		<xsl:variable name="prefix">
			<xsl:choose>
				<xsl:when test="parent::permission and ../@type = 'class'">
					<xsl:call-template name="getRequirementLabel">
						<xsl:with-param name="node" select="'modspec'"/>
						<xsl:with-param name="label" select="'permissionclass'"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="parent::requirement and ../@type = 'class'">
					<xsl:call-template name="getRequirementLabel">
						<xsl:with-param name="node" select="'modspec'"/>
						<xsl:with-param name="label" select="'requirementclass'"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="parent::recommendation and ../@type = 'class'">
					<xsl:call-template name="getRequirementLabel">
						<xsl:with-param name="node" select="'modspec'"/>
						<xsl:with-param name="label" select="'recommendationclass'"/>
					</xsl:call-template>
				</xsl:when>
				
				<xsl:when test="../@type = 'verification'">
					<xsl:call-template name="getRequirementLabel">
						<xsl:with-param name="node" select="'modspec'"/>
						<xsl:with-param name="label" select="'conformancetest'"/>
					</xsl:call-template>
				</xsl:when>
				
				<xsl:when test="../@type = 'abstracttest'">
					<xsl:call-template name="getRequirementLabel">
						<xsl:with-param name="node" select="'modspec'"/>
						<xsl:with-param name="label" select="'abstracttest'"/>
					</xsl:call-template>
				</xsl:when>
				
				<xsl:when test="../@type = 'conformanceclass'">
					<xsl:call-template name="getRequirementLabel">
						<xsl:with-param name="node" select="'modspec'"/>
						<xsl:with-param name="label" select="'conformanceclass'"/>
					</xsl:call-template>
				</xsl:when>
				
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="parent::permission">
							<xsl:call-template name="getRequirementLabel">
								<xsl:with-param name="label" select="'permission'"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:when test="parent::recommendation">
							<xsl:call-template name="getRequirementLabel">
								<xsl:with-param name="label" select="'recommendation'"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:when test="parent::requirement">
							<xsl:call-template name="getRequirementLabel">
								<xsl:with-param name="label" select="'requirement'"/>
							</xsl:call-template>
						</xsl:when>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="normalize-space($prefix)"/>
		<xsl:text> </xsl:text>
	</xsl:template>
	
	
	<xsl:template match="requirement[not(ancestor::requirement)]/*[not(self::title)]">
		<xsl:variable name="requirement_type" select="../@type"/>
		<tr>
			<th>
				<xsl:variable name="th">
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
						
						<xsl:when test="self::component and @class != ''">
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
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$metanorma_type = 'ISO'">
						<bold><xsl:copy-of select="$th"/></bold>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="$th"/>
					</xsl:otherwise>
				</xsl:choose>
			</th>
			<td>
				<xsl:choose>
					<xsl:when test="self::identifier">
						<monospace><xsl:apply-templates /></monospace>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates />
					</xsl:otherwise>
				</xsl:choose>
			</td>
		</tr>
		
		
		<xsl:variable name="xref_array">
			<xsl:variable name="identifier" select="normalize-space(../identifier)"/>
			<xsl:for-each select="$requirements/requirement[requirement[normalize-space(identifier) = $identifier]]">
			
				<xsl:call-template name="insert_xref">
					<xsl:with-param name="rid" select="@id"/>
					<xsl:with-param name="type" select="@type"/>
					<xsl:with-param name="num" select="@num"/>
					<xsl:with-param name="title_prefix" select="@title_prefix"/>
					<xsl:with-param name="title" select="title"/>
				</xsl:call-template>

				<xsl:if test="position() != last()">
					<break/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<!-- <xref_array><xsl:copy-of select="$xref_array"/></xref_array> -->
		<xsl:if test="normalize-space($xref_array) != '' and (self::subject or (self::identifier and not(../subject))) and (normalize-space(../@type) = '' or normalize-space(../@type) = 'verification')">
			<tr>
				<xsl:variable name="th">
					<xsl:call-template name="getRequirementLabel">
						<xsl:with-param name="node" select="'modspec'"/>
						<xsl:with-param name="label" select="'included_in'"/>
					</xsl:call-template>
				</xsl:variable>
				<th>
					<xsl:choose>
						<xsl:when test="$metanorma_type = 'ISO'">
							<bold><xsl:value-of select="$th"/></bold>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$th"/>
						</xsl:otherwise>
					</xsl:choose>
				</th>
				<td>
					<xsl:copy-of select="$xref_array"/>
				</td>
			</tr>
		</xsl:if>
		
	</xsl:template>
	
	<xsl:template match="requirement/classification">
		<tr>
			<th>
				<xsl:apply-templates select="*[1]/node()"/>
			</th>
			<td>
				<xsl:apply-templates select="*[2]/node()"/>
			</td>
		</tr>
	</xsl:template>
	
	<!-- first requirement/requirement -->
	<xsl:template match="requirement/requirement[not(preceding-sibling::requirement)]">
		<tr>
			<xsl:variable name="th">Provisions</xsl:variable>
			<th>
				<xsl:choose>
					<xsl:when test="$metanorma_type = 'ISO'">
						<bold><xsl:value-of select="$th"/></bold>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$th"/>
					</xsl:otherwise>
				</xsl:choose>
			</th>
			<td>
				<!--
				<xref target="r-identifier-1-1">Requirement 1: Method for constructing identifiers defined</xref>
				<br />
				...
				-->
				<xsl:apply-templates/>
				<xsl:apply-templates select="following-sibling::requirement">
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
		
		<xsl:call-template name="insert_xref">
			<xsl:with-param name="rid" select="$requirement/@id"/>
			<xsl:with-param name="type" select="$requirement/@type"/>
			<xsl:with-param name="num" select="$requirement/@num"/>
			<xsl:with-param name="title_prefix" select="$requirement/@title_prefix"/>
			<xsl:with-param name="title" select="$requirement/title"/>
		</xsl:call-template>

	</xsl:template>
	
	<!-- first requirement/inherit -->
	<xsl:template match="requirement/inherit[not(preceding-sibling::inherit)]">
		<tr>
			<xsl:variable name="th">
				<xsl:call-template name="getRequirementLabel">
					<xsl:with-param name="node" select="'modspec'"/>
					<xsl:with-param name="label" select="'dependency'"/>
				</xsl:call-template>
			</xsl:variable>
			<th>
				<xsl:choose>
					<xsl:when test="$metanorma_type = 'ISO'">
						<bold><xsl:value-of select="$th"/></bold>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$th"/>
					</xsl:otherwise>
				</xsl:choose>
			</th>
			<td>
				<!--
				<xref target="r-identifier-1-1">Requirement 1: Method for constructing identifiers defined</xref>
				<br />
				...
				-->
				<xsl:apply-templates select="." mode="inherit"/>
				<xsl:apply-templates select="following-sibling::inherit">
					<xsl:with-param name="process">true</xsl:with-param>
				</xsl:apply-templates>
			</td>
		</tr>
	</xsl:template>
	
	<xsl:template match="requirement/inherit[preceding-sibling::inherit]">
		<xsl:param name="process">false</xsl:param>
		<xsl:if test="$process = 'true'">
			<break/>
			<xsl:apply-templates select="." mode="inherit"/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="requirement/inherit" mode="inherit">
		<xsl:variable name="identifier" select="normalize-space(.)"/>
		<xsl:variable name="requirement_" select="$requirements/requirement[normalize-space(identifier) = $identifier]"/>
		<xsl:variable name="requirement" select="xalan:nodeset($requirement_)"/>
		
		<xsl:call-template name="insert_xref">
			<xsl:with-param name="rid" select="$requirement/@id"/>
			<xsl:with-param name="type" select="$requirement/@type"/>
			<xsl:with-param name="num" select="$requirement/@num"/>
			<xsl:with-param name="title_prefix" select="$requirement/@title_prefix"/>
			<xsl:with-param name="title" select="$requirement/title"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template name="insert_xref">
		<xsl:param name="rid"/>
		<xsl:param name="type"/>
		<xsl:param name="num"/>
		<xsl:param name="title_prefix"/>
		<xsl:param name="title"/>
		
		<xref rid="{$rid}" ref-type="table">
			<xsl:value-of select="$title_prefix"/>
			<!-- <xsl:choose>
				<xsl:when test="$type = 'class'">
					<xsl:call-template name="getRequirementLabel">
						<xsl:with-param name="node" select="'modspec'"/>
						<xsl:with-param name="label" select="'requirementclass'"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="getRequirementLabel">
						<xsl:with-param name="label" select="'requirement'"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:text> </xsl:text> -->
			<xsl:value-of select="$num"/>: <xsl:value-of select="$title"/></xref>
	</xsl:template>
	
	<!-- ======================= -->
	<!-- END: requirement processing -->
	<!-- ======================= -->

	
</xsl:stylesheet>