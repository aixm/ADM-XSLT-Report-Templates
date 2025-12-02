<?xml version="1.0" encoding="UTF-8"?>
<!-- ==================================================================== -->
<!-- XSLT script for iNM eEAD -->
<!-- Source: https://github.com/aixm/ADM-XSLT-Report-Templates -->
<!-- Created by: Paul-Adrian LAPUSAN (for EUROCONTROL) -->
<!-- ==================================================================== -->
<!-- 
  Copyright (c) 2025, EUROCONTROL
  =====================================
  All rights reserved.
  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
  * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
  * Neither the names of EUROCONTROL or FAA nor the names of their contributors may be used to endorse or promote products derived from this specification without specific prior written permission.
	
  THIS SPECIFICATION IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  ==========================================
  Editorial note: this license is an instance of the BSD license template as
  provided by the Open Source Initiative:
  http://www.opensource.org/licenses/bsd-license.php
-->

<!-- 
  Extraction Rule parameters required for the transformation to be successful:
  ===========================================================================
       featureTypes: aixm:GeoBorder
  permanentBaseline: true
          dataScope: ReleasedData
        AIXMversion: 5.1.1
-->

<xsl:transform version="3.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:uuid="java.util.UUID"
	xmlns:message="http://www.aixm.aero/schema/5.1.1/message"
	xmlns:gts="http://www.isotc211.org/2005/gts" 
	xmlns:gco="http://www.isotc211.org/2005/gco"
	xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
	xmlns:gml="http://www.opengis.net/gml/3.2"
	xmlns:gss="http://www.isotc211.org/2005/gss" 
	xmlns:aixm="http://www.aixm.aero/schema/5.1.1"
	xmlns:gsr="http://www.isotc211.org/2005/gsr" 
	xmlns:gmd="http://www.isotc211.org/2005/gmd"
	xmlns:event="http://www.aixm.aero/schema/5.1.1/event" 
	xmlns:xlink="http://www.w3.org/1999/xlink"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:aixm_ds_xslt="http://www.aixm.aero/xslt"
	xmlns:ead-audit="http://www.aixm.aero/schema/5.1.1/extensions/EUR/iNM/EAD-Audit"
	xmlns:fcn="local-function"
	xmlns:math="http://www.w3.org/2005/xpath-functions/math"
	exclude-result-prefixes="xsl uuid message gts gco xsd gml gss gsr gmd aixm event xlink xs xsi aixm_ds_xslt ead-audit fcn math">
	
	<xsl:output method="html" indent="yes"/>
	
	<xsl:strip-space elements="*"/>
	
	<xsl:function name="fcn:get-date" as="xs:string">
		<xsl:param name="input" as="xs:string"/>
		<xsl:variable name="date-time" select="$input"/>
		<xsl:variable name="day" select="substring($date-time, 9, 2)"/>
		<xsl:variable name="month" select="substring($date-time, 6, 2)"/>
		<xsl:variable name="month" select="if($month = '01') then 'JAN' else if ($month = '02') then 'FEB' else if ($month = '03') then 'MAR' else 
			if ($month = '04') then 'APR' else if ($month = '05') then 'MAY' else if ($month = '06') then 'JUN' else if ($month = '07') then 'JUL' else 
			if ($month = '08') then 'AUG' else if ($month = '09') then 'SEP' else if ($month = '10') then 'OCT' else if ($month = '11') then 'NOV' else if ($month = '12') then 'DEC' else ''"/>
		<xsl:variable name="year" select="substring($date-time, 1, 4)"/>
		<xsl:value-of select="concat($day, '-', $month, '-', $year)"/>
	</xsl:function>
	
	<!-- Insert value or NIL + nilReason -->
	<xsl:function name="fcn:insert-value" as="xs:string">
		<xsl:param name="feature_property" as="element()"/>
		<xsl:choose>
			<xsl:when test="$feature_property/@xsi:nil='true'">
				<xsl:choose>
					<xsl:when test="$feature_property/@nilReason">
						<xsl:value-of select="concat('NIL:', $feature_property/@nilReason)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="'NIL'"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$feature_property"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- Get annotation text preserving line breaks and escaping special HTML characters -->
	<xsl:function name="fcn:get-annotation-text" as="xs:string">
		<xsl:param name="raw_text" as="xs:string"/>
		<!-- First, escape special HTML characters in the raw text before processing -->
		<xsl:variable name="escaped_raw_text" select="replace(replace($raw_text, '&lt;', '&amp;lt;'), '&gt;', '&amp;gt;')"/>
		<xsl:variable name="lines" select="for $line in tokenize($escaped_raw_text, '&#xA;') return normalize-space($line)"/>
		<xsl:variable name="non_empty_lines" select="$lines[string-length(.) gt 0]"/>
		<xsl:value-of select="string-join($non_empty_lines, '&lt;br/&gt;')"/>
	</xsl:function>
	
	<xsl:template match="/">
		
		<html xmlns="http://www.w3.org/1999/xhtml">
			
			<head>
				<meta http-equiv="Expires" content="120" />
				<title>SDD Reporting - SDD GeoBorder</title>
			</head>
			
			<body>
				
				<table>
					<tbody>
						<tr>
							<td width="1%">
								<img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRsXfeeIugt2q_rvditc-PbmqOMAWkbYHcWwdq_3NuFPbjFXRXpd9DtJnUNt18Rqg6RTXI&amp;usqp=CAU" alt="AIS" width="80px" height="80px"/>
							</td>
							<td width="98%">
								<div style="height: 100%; display: flex; justify-content: center; align-items: center;">
									<h2>AERONAUTICAL INFORMATION SERVICES</h2>
								</div>
							</td>
							<td width="1%">
								<img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRsXfeeIugt2q_rvditc-PbmqOMAWkbYHcWwdq_3NuFPbjFXRXpd9DtJnUNt18Rqg6RTXI&amp;usqp=CAU" alt="AIS" width="80px" height="80px"/>
							</td>
						</tr>
					</tbody>
				</table>
				<hr/>
				
				<center>
					<b>SDD GeoBorder</b>
				</center>
				<hr/>
				
				<table border="0" style="border-spacing: 8px 4px">
					<tbody>
						
						<tr style="white-space:nowrap">
							<td><strong>FeatureIdentifier</strong></td>
							<td><strong>FeatureLifetimeBegin</strong></td>
							<td><strong>FeatureLifetimeEnd</strong></td>
							<td><strong>ValidityFrom</strong></td>
							<td><strong>ValidityTo</strong></td>
							<td><strong>SequenceNumber</strong></td>
							<td><strong>CorrectionNumber</strong></td>
							<td><strong>Name</strong></td>
							<td><strong>Type</strong></td>
							<td><strong>Border/GmlXml</strong></td>
							<td><strong>EAD-AUDIT:CreatedBy</strong></td>
							<td><strong>EAD-AUDIT:CreationDate</strong></td>
							<td><strong>EAD-AUDIT:CreatedByOrganisation</strong></td>
							<td><strong>EAD-AUDIT:CreatedOnBehalfOfUser</strong></td>
							<td><strong>EAD-AUDIT:CreatedOnBehalfOfOrganisation</strong></td>
							<td><strong>EAD-AUDIT:ReasonForChange</strong></td>
							<td><strong>EAD-AUDIT:ResponsibleSubsystem</strong></td>
						</tr>
						
						<xsl:for-each select="//aixm:GeoBorder/aixm:timeSlice/aixm:GeoBorderTimeSlice">
							
							<xsl:sort select="aixm:name" order="ascending"/>
							<xsl:sort select="aixm:sequenceNumber" order="descending" data-type="number"/>
							<xsl:sort select="aixm:correctionNumber" order="descending" data-type="number"/>
							
							<!-- FeatureIdentifier -->
							<xsl:variable name="identifier" select="../../gml:identifier"/>
							
							<!-- FeatureLifetimeBegin -->
							<xsl:variable name="lifetime-begin">
								<xsl:choose>
									<xsl:when test="not(aixm:featureLifetime/gml:TimePeriod/gml:beginPosition)">
										<xsl:value-of select="''"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="fcn:get-date(aixm:featureLifetime/gml:TimePeriod/gml:beginPosition)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- FeatureLifetimeEnd -->
							<xsl:variable name="lifetime-end">
								<xsl:choose>
									<xsl:when test="aixm:featureLifetime/gml:TimePeriod/gml:endPosition/@indeterminatePosition = 'unknown'">
										<xsl:value-of select="'31-DEC-9999'"/>
									</xsl:when>
									<xsl:when test="not(aixm:featureLifetime/gml:TimePeriod/gml:endPosition/@indeterminatePosition) and aixm:featureLifetime/gml:TimePeriod/gml:endPosition">
										<xsl:value-of select="fcn:get-date(aixm:featureLifetime/gml:TimePeriod/gml:endPosition)"/>
									</xsl:when>
									<xsl:when test="not(aixm:featureLifetime/gml:TimePeriod/gml:endPosition)">
										<xsl:value-of select="fcn:get-date(aixm:featureLifetime/gml:TimePeriod/gml:endPosition)"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- ValidityFrom -->
							<xsl:variable name="validity-begin">
								<xsl:choose>
									<xsl:when test="not(gml:validTime/gml:TimePeriod/gml:beginPosition)">
										<xsl:value-of select="''"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="fcn:get-date(gml:validTime/gml:TimePeriod/gml:beginPosition)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- ValidityTo -->
							<xsl:variable name="validity-end">
								<xsl:choose>
									<xsl:when test="gml:validTime/gml:TimePeriod/gml:endPosition/@indeterminatePosition = 'unknown'">
										<xsl:value-of select="'31-DEC-9999'"/>
									</xsl:when>
									<xsl:when test="not(gml:validTime/gml:TimePeriod/gml:endPosition/@indeterminatePosition) and gml:validTime/gml:TimePeriod/gml:endPosition">
										<xsl:value-of select="fcn:get-date(gml:validTime/gml:TimePeriod/gml:endPosition)"/>
									</xsl:when>
									<xsl:when test="not(gml:validTime/gml:TimePeriod/gml:endPosition)">
										<xsl:value-of select="''"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- SequenceNumber -->
							<xsl:variable name="sequence-number">
								<xsl:choose>
									<xsl:when test="not(aixm:sequenceNumber)">
										<xsl:value-of select="''"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="fcn:insert-value(aixm:sequenceNumber)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- CorrectionNumber -->
							<xsl:variable name="correction-number">
								<xsl:choose>
									<xsl:when test="not(aixm:correctionNumber)">
										<xsl:value-of select="''"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="fcn:insert-value(aixm:correctionNumber)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- Name -->
							<xsl:variable name="name">
								<xsl:choose>
									<xsl:when test="not(aixm:name)">
										<xsl:value-of select="''"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="fcn:insert-value(aixm:name)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- Type -->
							<xsl:variable name="type">
								<xsl:choose>
									<xsl:when test="not(aixm:type)">
										<xsl:value-of select="''"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="fcn:insert-value(aixm:type)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- Border/GmlXml -->
							<xsl:variable name="border">
								<xsl:for-each select="aixm:border/node()">
									<xsl:variable name="serialized" select="serialize(., map{'omit-xml-declaration': true(), 'indent': false()})"/>
									<xsl:variable name="no-xmlns" select="replace($serialized, ' xmlns:[^=]+=&quot;[^&quot;]+&quot;', '')"/>
									<xsl:value-of select="replace($no-xmlns, ' gml:id=&quot;[^&quot;]+&quot;', '')"/>
								</xsl:for-each>
							</xsl:variable>
							
							<!-- EAD-Audit -->
							<xsl:variable name="EAD-Audit" select="aixm:extension/ead-audit:GeoBorderExtension/ead-audit:auditInformation/ead-audit:Audit"/>
							
							<!-- EAD-AUDIT:CreatedBy -->
							<xsl:variable name="created-by">
								<xsl:choose>
									<xsl:when test="not($EAD-Audit/ead-audit:createdBy)">
										<xsl:value-of select="''"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:createdBy)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- EAD-AUDIT:CreationDate -->
							<xsl:variable name="creation-date">
								<xsl:choose>
									<xsl:when test="not($EAD-Audit/ead-audit:creationDate)">
										<xsl:value-of select="''"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="fcn:get-date($EAD-Audit/ead-audit:creationDate)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- EAD-AUDIT:CreatedByOrganisation -->
							<xsl:variable name="created-by-org">
								<xsl:choose>
									<xsl:when test="not($EAD-Audit/ead-audit:createdByOrg)">
										<xsl:value-of select="''"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:createdByOrg)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- EAD-AUDIT:CreatedOnBehalfOfUser -->
							<xsl:variable name="created-on-behalf-of-user">
								<xsl:choose>
									<xsl:when test="not($EAD-Audit/ead-audit:createdOnBehalfOfUser)">
										<xsl:value-of select="''"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:createdOnBehalfOfUser)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- EAD-AUDIT:CreatedOnBehalfOfOrganisation -->
							<xsl:variable name="created-on-behalf-of-org">
								<xsl:choose>
									<xsl:when test="not($EAD-Audit/ead-audit:createdOnBehalfOfOrg)">
										<xsl:value-of select="''"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:createdOnBehalfOfOrg)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- EAD-AUDIT:ReasonForChange -->
							<xsl:variable name="reason-for-change">
								<xsl:choose>
									<xsl:when test="not($EAD-Audit/ead-audit:reasonForChange)">
										<xsl:value-of select="''"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:reasonForChange)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- EAD-AUDIT:ResponsibleSubsystem -->
							<xsl:variable name="responsible-subsystem">
								<xsl:choose>
									<xsl:when test="not($EAD-Audit/ead-audit:responsibleSubsystem)">
										<xsl:value-of select="''"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:responsibleSubsystem)"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<tr style="white-space:nowrap;vertical-align:top">
								<td><xsl:value-of select="if (string-length($identifier) gt 0) then $identifier else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($lifetime-begin) gt 0) then $lifetime-begin else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($lifetime-end) gt 0) then $lifetime-end else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($validity-begin) gt 0) then $validity-begin else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($validity-end) gt 0) then $validity-end else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($sequence-number) gt 0) then $sequence-number else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($correction-number) gt 0) then $correction-number else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($name) gt 0) then $name else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($type) gt 0) then $type else '&#160;'"/></td>
								<td style="min-width:2000px;white-space:normal"><xsl:value-of select="if (string-length($border) gt 0) then $border else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($created-by) gt 0) then $created-by else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($creation-date) gt 0) then $creation-date else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($created-by-org) gt 0) then $created-by-org else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($created-on-behalf-of-user) gt 0) then $created-on-behalf-of-user else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($created-on-behalf-of-org) gt 0) then $created-on-behalf-of-org else '&#160;'"/></td>
								<td style="min-width:600px;white-space:normal"><xsl:value-of select="if (string-length($reason-for-change) gt 0) then $reason-for-change else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($responsible-subsystem) gt 0) then $responsible-subsystem else '&#160;'"/></td>
							</tr>
							
						</xsl:for-each>
						
					</tbody>
				</table>
				
				<!-- Extraction rule parameters used for this report -->
				
				<xsl:variable name="rule_parameters" select="//aixm:messageMetadata/gmd:MD_Metadata/gmd:fileIdentifier/gco:CharacterString"/>
				
				<!-- extractionRulesUUID -->
				<xsl:variable name="rule_uuid">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'extractionRulesUuid: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- interestedInDataAt -->
				<xsl:variable name="interest_date">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'interestedInDataAt: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- featureTypes -->
				<xsl:variable name="feat_types">
					<xsl:value-of select="replace(replace(substring-before(substring-after($rule_parameters, 'featureTypes: '), ','), ' ', '&lt;br/&gt;'), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- excludedProperties -->
				<xsl:variable name="exc_properties">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'excludedProperties: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- includeReferencedFeaturesLevel -->
				<xsl:variable name="referenced_feat_level">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'includeReferencedFeaturesLevel: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- featureOccurrence -->
				<xsl:variable name="feat_occurrence">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'featureOccurrence: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- effectiveDateStart -->
				<xsl:variable name="eff_date_start">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'effectiveDateStart: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- effectiveDateEnd -->
				<xsl:variable name="eff_date_end">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'effectiveDateEnd: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- referencedDataFeature -->
				<xsl:variable name="referenced_data_feat">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'referencedDataFeature: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- permanentBaseline -->
				<xsl:variable name="perm_BL">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'permanentBaseline: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- permanentPermdelta -->
				<xsl:variable name="perm_PD">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'permanentPermdelta: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- temporaryData -->
				<xsl:variable name="temp_data">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'temporaryData: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- permanentBaselineForTemporaryData -->
				<xsl:variable name="perm_BS_for_temp_data">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'permanentBaselineForTemporaryData: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- spatialFilteringBy -->
				<xsl:variable name="spatial_filtering">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'spatialFilteringBy: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- spatialAreaUUID -->
				<xsl:variable name="spatial_area_uuid">
					<xsl:value-of select="replace(replace(substring-before(substring-after($rule_parameters, 'spatialAreaUUID: '), ','), ' ', '&lt;br/&gt;'), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- spatialAreaBuffer -->
				<xsl:variable name="spatial_area_buffer">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'spatialAreaBuffer: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- spatialOperator -->
				<xsl:variable name="spatial_operator">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'spatialOperator: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- spatialValueOperator -->
				<xsl:variable name="spatial_value_operator">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'spatialValueOperator: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- dataBranch -->
				<xsl:variable name="data_branch">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'dataBranch: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- dataScope -->
				<xsl:variable name="data_scope">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'dataScope: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- dataProviderOrganization -->
				<xsl:variable name="data_provider_org">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'dataProviderOrganization: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- systemExtension -->
				<xsl:variable name="system_extension">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'systemExtension: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- AIXMversion -->
				<xsl:variable name="AIXM_ver">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'AIXMversion: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- indirectReferences -->
				<xsl:variable name="indirect_references">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'indirectReferences: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- dataType -->
				<xsl:variable name="data_type">
					<xsl:variable name="after_key" select="substring-after($rule_parameters, 'dataType: ')"/>
					<xsl:value-of select="if (contains($after_key, ',')) then replace(substring-before($after_key, ','), '&quot;', '') else $after_key"/>
				</xsl:variable>
				
				<!-- CustomizationAirspaceCircleArcToPolygon -->
				<xsl:variable name="arc_to_polygon">
					<xsl:variable name="after_key" select="substring-after($rule_parameters, 'CustomizationAirspaceCircleArcToPolygon: ')"/>
					<xsl:value-of select="if (contains($after_key, ',')) then replace(substring-before($after_key, ','), '&quot;', '') else $after_key"/>
				</xsl:variable>
				
				<p><b><font size="-1">Extraction rule parameters used for this report:</font></b></p>
				
				<table>
					<tr>
						<td style="text-align:right"><font size="-1">extractionRulesUUID: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($rule_uuid) gt 0) then $rule_uuid else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">interestedInDataAt: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($interest_date) gt 0) then $interest_date else '&#160;'"/></font></td>
					</tr>
					<tr style="vertical-align:top">
						<td style="text-align:right"><font size="-1">featureTypes: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($feat_types) gt 0) then $feat_types else '&#160;'" disable-output-escaping="true"/></font></td>
					</tr>
					<tr style="vertical-align:top">
						<td style="text-align:right"><font size="-1">excludedProperties: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($exc_properties) gt 0) then $exc_properties else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">includeReferencedFeaturesLevel: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($referenced_feat_level) gt 0) then $referenced_feat_level else '&#160;'"/></font></td>
					</tr>
					<tr style="vertical-align:top">
						<td style="text-align:right"><font size="-1">featureOccurrence: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($feat_occurrence) gt 0) then $feat_occurrence else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">effectiveDateStart: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($eff_date_start) gt 0) then $eff_date_start else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">effectiveDateEnd: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($eff_date_end) gt 0) then $eff_date_end else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">referencedDataFeature: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($referenced_data_feat) gt 0) then $referenced_data_feat else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">permanentBaseline: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($perm_BL) gt 0) then $perm_BL else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">permanentPermdelta: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($perm_PD) gt 0) then $perm_PD else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">temporaryData: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($temp_data) gt 0) then $temp_data else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">permanentBaselineForTemporaryData: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($perm_BS_for_temp_data) gt 0) then $perm_BS_for_temp_data else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">spatialFilteringBy: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($spatial_filtering) gt 0) then $spatial_filtering else '&#160;'"/></font></td>
					</tr>
					<tr style="vertical-align:top">
						<td style="text-align:right"><font size="-1">spatialAreaUUID: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($spatial_area_uuid) gt 0) then $spatial_area_uuid else '&#160;'" disable-output-escaping="true"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">spatialAreaBuffer: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($spatial_area_buffer) gt 0) then $spatial_area_buffer else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">spatialOperator: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($spatial_operator) gt 0) then $spatial_operator else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">spatialValueOperator: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($spatial_value_operator) gt 0) then $spatial_value_operator else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">dataBranch: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($data_branch) gt 0) then $data_branch else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">dataScope: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($data_scope) gt 0) then $data_scope else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">dataProviderOrganization: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($data_provider_org) gt 0) then $data_provider_org else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">systemExtension: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($system_extension) gt 0) then $system_extension else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">AIXMversion: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($AIXM_ver) gt 0) then $AIXM_ver else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">indirectReferences: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($indirect_references) gt 0) then $indirect_references else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">dataType: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($data_type) gt 0) then $data_type else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">CustomizationAirspaceCircleArcToPolygon: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($arc_to_polygon) gt 0) then $arc_to_polygon else '&#160;'"/></font></td>
					</tr>
				</table>
				
				<p></p>
				<table>
					<tr>
						<td style="text-align:right"><font size="-1">Sorting by columns: </font></td>
						<td><font size="-1">Name, SequenceNumber, CorrectionNumber</font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">Sorting order: </font></td>
						<td><font size="-1">ascending (Name), descending (SequenceNumber), descending (CorrectionNumber)</font></td>
					</tr>
				</table>
				
				<p>***&#160;END OF REPORT&#160;***</p>
				
			</body>
			
		</html>
		
	</xsl:template>
	
</xsl:transform>