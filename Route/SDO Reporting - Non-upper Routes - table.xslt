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
										featureTypes: aixm:RouteSegment
	includeReferencedFeaturesLevel: 1
							 permanentBaseline: true
											 dataScope: ReleasedData
										 AIXMversion: 5.1.1
-->

<xsl:stylesheet version="3.0" 
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
	xmlns:fcn="local-function"
	xmlns:ead-audit="http://www.aixm.aero/schema/5.1.1/extensions/EUR/iNM/EAD-Audit"
	xmlns:saxon="http://saxon.sf.net/"
	exclude-result-prefixes="xsl uuid message gts gco xsd gml gss gsr gmd aixm event xlink xs xsi aixm_ds_xslt fcn ead-audit saxon">
	
	<xsl:output method="html" indent="yes"  saxon:line-length="999999"/>
	
	<xsl:strip-space elements="*"/>
	
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
	
	<!-- Keys -->
	<xsl:key name="route-by-uuid" match="aixm:Route" use="gml:identifier"/>
	<xsl:key name="point-by-uuid" match="aixm:DesignatedPoint | aixm:Navaid" use="gml:identifier"/>

	<!-- Global variable to capture document root for use in key() functions -->
	<xsl:variable name="doc-root" select="/"/>

	<xsl:template match="/">
		
		<html xmlns="http://www.w3.org/1999/xhtml">
			
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
				<meta http-equiv="Expires" content="120"/>
				<title>SDO Reporting - Non-upper Routes</title>
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
				
				<center><b>Non-upper Routes</b></center>
				<hr/>
				
				<table xmlns="" border="0" style="border-spacing: 8px 4px">
					<tbody>
						
						<tr style="white-space:nowrap">
							<td><strong>Master gUID</strong></td>
							<td><strong>Route Designator</strong></td>
							<td><strong>Area Desig.</strong></td>
							<td><strong>Start identifier</strong></td>
							<td><strong>Type</strong></td>
							<td><strong>End Identifier</strong></td>
							<td><strong>Type</strong></td>
							<td><strong>Upper limit</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[upper limit]</strong></td>
							<td><strong>Reference for<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>upper limit</strong></td>
							<td><strong>Lower limit</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[lower limit]</strong></td>
							<td><strong>Reference for<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>lower limit</strong></td>
							<td><strong>Effective date</strong></td>
							<td><strong>Valid TimeSlice</strong></td>
							<td><strong>Originator</strong></td>
						</tr>
						
						<!-- Group segments by route (which have level = 'LOWER') - using only latest timeslices -->
						<!-- First, group all RouteSegments by identifier to find the valid timeslice for each -->
						<xsl:variable name="latest-segments" as="element()*">
							<xsl:for-each-group select="//aixm:RouteSegment" group-by="gml:identifier">
								<xsl:variable name="baseline-timeslices" select="current-group()/aixm:timeSlice/aixm:RouteSegmentTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="max-sequence" select="max($baseline-timeslices/aixm:sequenceNumber)"/>
								<xsl:variable name="max-correction" select="max($baseline-timeslices[aixm:sequenceNumber = $max-sequence]/aixm:correctionNumber)"/>
								<xsl:variable name="latest-timeslice" select="$baseline-timeslices[aixm:sequenceNumber = $max-sequence and aixm:correctionNumber = $max-correction][1]"/>
								<!-- Only include segments with level = 'LOWER' -->
								<xsl:if test="$latest-timeslice/aixm:level = 'LOWER'">
									<!-- Create a temporary element with the segment and its latest timeslice -->
									<xsl:element name="aixm:RouteSegment" namespace="http://www.aixm.aero/schema/5.1.1">
										<xsl:copy-of select="current-group()[1]/gml:identifier"/>
										<xsl:element name="aixm:timeSlice" namespace="http://www.aixm.aero/schema/5.1.1">
											<xsl:copy-of select="$latest-timeslice"/>
										</xsl:element>
									</xsl:element>
								</xsl:if>
							</xsl:for-each-group>
						</xsl:variable>

						<!-- Now group the segments by route -->
						<xsl:for-each-group select="$latest-segments" group-by="replace(aixm:timeSlice/aixm:RouteSegmentTimeSlice/aixm:routeFormed/@xlink:href, '^(urn:uuid:|#uuid\.)', '')">

							<!-- Natural sort by Route Designator: prefix then numeric -->
							<xsl:sort
								select="
								let $Route := key('route-by-uuid', current-grouping-key(), $doc-root),
								$baseline-timeslices := $Route/aixm:timeSlice/aixm:RouteTimeSlice[aixm:interpretation = 'BASELINE'],
								$max-sequence := max($baseline-timeslices/aixm:sequenceNumber),
								$max-correction := max($baseline-timeslices[aixm:sequenceNumber = $max-sequence]/aixm:correctionNumber),
								$RTS := $baseline-timeslices[aixm:sequenceNumber = $max-sequence and aixm:correctionNumber = $max-correction][1],
								$prefix := concat($RTS/aixm:designatorPrefix, $RTS/aixm:designatorSecondLetter)
								return $prefix"
								data-type="text" order="ascending"/>

							<xsl:sort
								select="
								let $Route := key('route-by-uuid', current-grouping-key(), $doc-root),
								$baseline-timeslices := $Route/aixm:timeSlice/aixm:RouteTimeSlice[aixm:interpretation = 'BASELINE'],
								$max-sequence := max($baseline-timeslices/aixm:sequenceNumber),
								$max-correction := max($baseline-timeslices[aixm:sequenceNumber = $max-sequence]/aixm:correctionNumber),
								$RTS := $baseline-timeslices[aixm:sequenceNumber = $max-sequence and aixm:correctionNumber = $max-correction][1],
								$number := number($RTS/aixm:designatorNumber)
								return $number"
								data-type="number" order="ascending"/>

							<xsl:variable name="Route_uuid" select="current-grouping-key()"/>
							<xsl:variable name="Route" select="key('route-by-uuid', $Route_uuid, $doc-root)"/>
							<!-- Get the latest Route timeslice -->
							<xsl:variable name="route-baseline-timeslices" select="$Route/aixm:timeSlice/aixm:RouteTimeSlice[aixm:interpretation = 'BASELINE']"/>
							<xsl:variable name="route-max-sequence" select="max($route-baseline-timeslices/aixm:sequenceNumber)"/>
							<xsl:variable name="route-max-correction" select="max($route-baseline-timeslices[aixm:sequenceNumber = $route-max-sequence]/aixm:correctionNumber)"/>
							<xsl:variable name="RouteTimeSlice" select="$route-baseline-timeslices[aixm:sequenceNumber = $route-max-sequence and aixm:correctionNumber = $route-max-correction][1]"/>
							<xsl:variable name="Master_gUID" select="$Route/gml:identifier"/>
							<xsl:variable name="RouteDesignator" select="concat($RouteTimeSlice/aixm:designatorPrefix, $RouteTimeSlice/aixm:designatorSecondLetter, $RouteTimeSlice/aixm:designatorNumber)"/>
							<xsl:variable name="RouteAreaDesignator" select="$RouteTimeSlice/aixm:locationDesignator"/>
							<xsl:variable name="EffectiveDate">
								<xsl:variable name="day" select="substring($RouteTimeSlice/gml:validTime/gml:TimePeriod/gml:beginPosition, 9, 2)"/>
								<xsl:variable name="month" select="substring($RouteTimeSlice/gml:validTime/gml:TimePeriod/gml:beginPosition, 6, 2)"/>
								<xsl:variable name="month" select="if($month = '01') then 'JAN' else if ($month = '02') then 'FEB' else if ($month = '03') then 'MAR' else 
									if ($month = '04') then 'APR' else if ($month = '05') then 'MAY' else if ($month = '06') then 'JUN' else if ($month = '07') then 'JUL' else 
									if ($month = '08') then 'AUG' else if ($month = '09') then 'SEP' else if ($month = '10') then 'OCT' else if ($month = '11') then 'NOV' else if ($month = '12') then 'DEC' else ''"/>
								<xsl:variable name="year" select="substring($RouteTimeSlice/gml:validTime/gml:TimePeriod/gml:beginPosition, 1, 4)"/>
								<xsl:value-of select="concat($day, '-', $month, '-', $year)"/>
							</xsl:variable>
							<xsl:variable name="ValidTimeSlice" select="concat('BASELINE ', $route-max-sequence, '.', $route-max-correction)"/>
							<xsl:variable name="Originator" select="$RouteTimeSlice/aixm:extension/ead-audit:RouteExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
							
							<!-- Extract all segments in this route -->
							<xsl:variable name="segments" select="current-group()"/>							
							
							<!-- Find the first segment (its start point is not an end point elsewhere on this route) -->
							<xsl:variable name="start-segment" as="element()*">
								<xsl:iterate select="$segments">
									<xsl:variable name="seg" select="."/>
									<xsl:variable name="RouteSegmentTimeSlice" select="aixm:timeSlice/aixm:RouteSegmentTimeSlice[aixm:interpretation = 'BASELINE']"/>
									<xsl:variable name="start" select="replace($RouteSegmentTimeSlice/aixm:start/*/*/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
									<xsl:variable name="end" select="$segments/aixm:timeSlice/aixm:RouteSegmentTimeSlice[aixm:interpretation = 'BASELINE']/aixm:end/*/*/@xlink:href"/>
									<xsl:if test="not($end[contains(., $start)])">
										<xsl:sequence select="."/>
										<xsl:break/>
									</xsl:if>
								</xsl:iterate>
							</xsl:variable>
							
							<!-- Recursively walk the chain -->
							<xsl:call-template name="output-chain">
								<xsl:with-param name="segment" select="$start-segment"/>
								<xsl:with-param name="segments" select="$segments"/>
								<xsl:with-param name="Master_gUID" select="$Master_gUID"/>
								<xsl:with-param name="RouteDesignator" select="$RouteDesignator"/>
								<xsl:with-param name="RouteAreaDesignator" select="$RouteAreaDesignator"/>
								<xsl:with-param name="EffectiveDate" select="$EffectiveDate"/>
								<xsl:with-param name="ValidTimeSlice" select="$ValidTimeSlice"/>
								<xsl:with-param name="Originator" select="$Originator"/>
							</xsl:call-template>
							
						</xsl:for-each-group>
						
					</tbody>
				</table>
				
				<!-- Extraction rule parameters used for this report -->
				
				<xsl:variable name="rule_parameters" select="//aixm:messageMetadata/gmd:MD_Metadata/gmd:fileIdentifier/gco:CharacterString"/>
				
				<!-- extractionRulesUUID -->
				<xsl:variable name="rule_uuid">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'extractionRulesUuid: '), ',')"/>
				</xsl:variable>
				
				<!-- interestedInDataAt -->
				<xsl:variable name="interest_date">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'interestedInDataAt: '), ',')"/>
				</xsl:variable>
				
				<!-- featureTypes -->
				<xsl:variable name="feat_types">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'featureTypes: '), ',')"/>
				</xsl:variable>
				
				<!-- excludedProperties -->
				<xsl:variable name="exc_properties">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'excludedProperties: '), ',')"/>
				</xsl:variable>
				
				<!-- includeReferencedFeaturesLevel -->
				<xsl:variable name="referenced_feat_level">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'includeReferencedFeaturesLevel: '), ',')"/>
				</xsl:variable>
				
				<!-- featureOccurrence -->
				<xsl:variable name="feat_occurrence">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'featureOccurrence: '), ',')"/>
				</xsl:variable>
				
				<!-- effectiveDateStart -->
				<xsl:variable name="eff_date_start">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'effectiveDateStart: '), ',')"/>
				</xsl:variable>
				
				<!-- effectiveDateEnd -->
				<xsl:variable name="eff_date_end">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'effectiveDateEnd: '), ',')"/>
				</xsl:variable>
				
				<!-- referencedDataFeature -->
				<xsl:variable name="referenced_data_feat">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'referencedDataFeature: '), ',')"/>
				</xsl:variable>
				
				<!-- permanentBaseline -->
				<xsl:variable name="perm_BL">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'permanentBaseline: '), ',')"/>
				</xsl:variable>
				
				<!-- permanentPermdelta -->
				<xsl:variable name="perm_PD">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'permanentPermdelta: '), ',')"/>
				</xsl:variable>
				
				<!-- temporaryData -->
				<xsl:variable name="temp_data">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'temporaryData: '), ',')"/>
				</xsl:variable>
				
				<!-- permanentBaselineForTemporaryData -->
				<xsl:variable name="perm_BS_for_temp_data">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'permanentBaselineForTemporaryData: '), ',')"/>
				</xsl:variable>
				
				<!-- spatialFilteringBy -->
				<xsl:variable name="spatial_filtering">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'spatialFilteringBy: '), ',')"/>
				</xsl:variable>
				
				<!-- spatialAreaUUID -->
				<xsl:variable name="spatial_area_uuid">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'spatialAreaUUID: '), ',')"/>
				</xsl:variable>
				
				<!-- spatialAreaBuffer -->
				<xsl:variable name="spatial_area_buffer">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'spatialAreaBuffer: '), ',')"/>
				</xsl:variable>
				
				<!-- spatialOperator -->
				<xsl:variable name="spatial_operator">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'spatialOperator: '), ',')"/>
				</xsl:variable>
				
				<!-- spatialValueOperator -->
				<xsl:variable name="spatial_value_operator">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'spatialValueOperator: '), ',')"/>
				</xsl:variable>
				
				<!-- dataBranch -->
				<xsl:variable name="data_branch">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'dataBranch: '), ',')"/>
				</xsl:variable>
				
				<!-- dataScope -->
				<xsl:variable name="data_scope">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'dataScope: '), ',')"/>
				</xsl:variable>
				
				<!-- dataProviderOrganization -->
				<xsl:variable name="data_provider_org">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'dataProviderOrganization: '), ',')"/>
				</xsl:variable>
				
				<!-- systemExtension -->
				<xsl:variable name="system_extension">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'systemExtension: '), ',')"/>
				</xsl:variable>
				
				<!-- AIXMversion -->
				<xsl:variable name="AIXM_ver">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'AIXMversion: '), ',')"/>
				</xsl:variable>
				
				<!-- indirectReferences -->
				<xsl:variable name="indirect_references">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'indirectReferences: '), ',')"/>
				</xsl:variable>
				
				<!-- dataType -->
				<xsl:variable name="data_type">
					<xsl:variable name="after_key" select="substring-after($rule_parameters, 'dataType: ')"/>
					<xsl:value-of select="if (contains($after_key, ',')) then substring-before($after_key, ',') else $after_key"/>
				</xsl:variable>
				
				<!-- CustomizationAirspaceCircleArcToPolygon -->
				<xsl:variable name="arc_to_polygon">
					<xsl:variable name="after_key" select="substring-after($rule_parameters, 'CustomizationAirspaceCircleArcToPolygon: ')"/>
					<xsl:value-of select="if (contains($after_key, ',')) then substring-before($after_key, ',') else $after_key"/>
				</xsl:variable>
				
				<p><font size="-1">Extraction rule parameters used for this report:</font></p>
				
				<table>
					<tr>
						<td><font size="-1">extractionRulesUUID: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($rule_uuid) gt 0) then $rule_uuid else '&#160;'"/></font>
						</td>
					</tr>
					<tr>
						<td><font size="-1">interestedInDataAt: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($interest_date) gt 0) then $interest_date else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">featureTypes: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($feat_types) gt 0) then $feat_types else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">excludedProperties: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($exc_properties) gt 0) then $exc_properties else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">includeReferencedFeaturesLevel: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($referenced_feat_level) gt 0) then $referenced_feat_level else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">featureOccurrence: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($feat_occurrence) gt 0) then $feat_occurrence else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">effectiveDateStart: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($eff_date_start) gt 0) then $eff_date_start else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">effectiveDateEnd: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($eff_date_end) gt 0) then $eff_date_end else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">referencedDataFeature: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($referenced_data_feat) gt 0) then $referenced_data_feat else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">permanentBaseline: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($perm_BL) gt 0) then $perm_BL else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">permanentPermdelta: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($perm_PD) gt 0) then $perm_PD else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">temporaryData: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($temp_data) gt 0) then $temp_data else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">permanentBaselineForTemporaryData: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($perm_BS_for_temp_data) gt 0) then $perm_BS_for_temp_data else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">spatialFilteringBy: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($spatial_filtering) gt 0) then $spatial_filtering else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">spatialAreaUUID: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($spatial_area_uuid) gt 0) then $spatial_area_uuid else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">spatialAreaBuffer: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($spatial_area_buffer) gt 0) then $spatial_area_buffer else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">spatialOperator: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($spatial_operator) gt 0) then $spatial_operator else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">spatialValueOperator: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($spatial_value_operator) gt 0) then $spatial_value_operator else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">dataBranch: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($data_branch) gt 0) then $data_branch else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">dataScope: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($data_scope) gt 0) then $data_scope else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">dataProviderOrganization: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($data_provider_org) gt 0) then $data_provider_org else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">systemExtension: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($system_extension) gt 0) then $system_extension else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">AIXMversion: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($AIXM_ver) gt 0) then $AIXM_ver else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">indirectReferences: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($indirect_references) gt 0) then $indirect_references else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">dataType: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($data_type) gt 0) then $data_type else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">CustomizationAirspaceCircleArcToPolygon: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($arc_to_polygon) gt 0) then $data_type else '&#160;'"/></font></td>
					</tr>
				</table>
				
				<p></p>
				<table>
					<tr>
						<td><font size="-1">Sorting by column: </font></td>
						<td><font size="-1">Route Designator</font></td>
					</tr>
					<tr>
						<td><font size="-1">Sorting order: </font></td>
						<td><font size="-1">ascending</font></td>
					</tr>
				</table>
				
				<p>***&#160;END OF REPORT&#160;***</p>
				
			</body>
			
		</html>
		
	</xsl:template>
	
	<!-- Recursive template to walk the chain -->
	<xsl:template name="output-chain">
		<xsl:param name="segment"/>
		<xsl:param name="segments"/>
		<xsl:param name="Master_gUID"/>
		<xsl:param name="RouteDesignator"/>
		<xsl:param name="RouteAreaDesignator"/>
		<xsl:param name="EffectiveDate"/>
		<xsl:param name="ValidTimeSlice"/>
		<xsl:param name="Originator"/>
		
		<xsl:variable name="RouteSegmentTimeSlice" select="$segment/aixm:timeSlice/aixm:RouteSegmentTimeSlice[aixm:interpretation = 'BASELINE']"/>
		<xsl:variable name="start_uuid" select="replace($RouteSegmentTimeSlice/aixm:start/*/*/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
		<xsl:variable name="end_uuid" select="replace($RouteSegmentTimeSlice/aixm:end/*/*/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
		<xsl:variable name="UpperLimit">
			<xsl:choose>
				<xsl:when test="not($RouteSegmentTimeSlice/aixm:upperLimit)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:insert-value($RouteSegmentTimeSlice/aixm:upperLimit)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="UpperLimit_uom" select="$RouteSegmentTimeSlice/aixm:upperLimit/@uom"/>
		<xsl:variable name="UpperLimit_reference">
			<xsl:choose>
				<xsl:when test="not($RouteSegmentTimeSlice/aixm:upperLimitReference)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:insert-value($RouteSegmentTimeSlice/aixm:upperLimitReference)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="LowerLimit">
			<xsl:choose>
				<xsl:when test="not($RouteSegmentTimeSlice/aixm:lowerLimit)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:insert-value($RouteSegmentTimeSlice/aixm:lowerLimit)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="LowerLimit_uom" select="$RouteSegmentTimeSlice/aixm:lowerLimit/@uom"/>
		<xsl:variable name="LowerLimit_reference">
			<xsl:choose>
				<xsl:when test="not($RouteSegmentTimeSlice/aixm:lowerLimitReference)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:insert-value($RouteSegmentTimeSlice/aixm:lowerLimitReference)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<!-- Get the valid timeslice for start point -->
		<xsl:variable name="start_point" select="key('point-by-uuid', $start_uuid, $doc-root)"/>
		<xsl:variable name="start_baseline_timeslices" select="$start_point/aixm:timeSlice/*[aixm:interpretation = 'BASELINE']"/>
		<xsl:variable name="start_max_sequence" select="max($start_baseline_timeslices/aixm:sequenceNumber)"/>
		<xsl:variable name="start_max_correction" select="max($start_baseline_timeslices[aixm:sequenceNumber = $start_max_sequence]/aixm:correctionNumber)"/>
		<xsl:variable name="start_latest_timeslice" select="$start_baseline_timeslices[aixm:sequenceNumber = $start_max_sequence and aixm:correctionNumber = $start_max_correction][1]"/>

		<xsl:variable name="start_designator" select="$start_latest_timeslice/aixm:designator"/>
		<xsl:variable name="start_type">
			<xsl:choose>
				<xsl:when test="$start_latest_timeslice/self::aixm:DesignatedPointTimeSlice/aixm:type">
					<xsl:value-of select="concat('WPT', ' (', $start_latest_timeslice/aixm:type, ')')"/>
				</xsl:when>
				<xsl:when test="$start_latest_timeslice/self::aixm:NavaidTimeSlice/aixm:type">
					<xsl:value-of select="$start_latest_timeslice/aixm:type"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>

		<!-- Get the valid timeslice for end point -->
		<xsl:variable name="end_point" select="key('point-by-uuid', $end_uuid, $doc-root)"/>
		<xsl:variable name="end_baseline_timeslices" select="$end_point/aixm:timeSlice/*[aixm:interpretation = 'BASELINE']"/>
		<xsl:variable name="end_max_sequence" select="max($end_baseline_timeslices/aixm:sequenceNumber)"/>
		<xsl:variable name="end_max_correction" select="max($end_baseline_timeslices[aixm:sequenceNumber = $end_max_sequence]/aixm:correctionNumber)"/>
		<xsl:variable name="end_latest_timeslice" select="$end_baseline_timeslices[aixm:sequenceNumber = $end_max_sequence and aixm:correctionNumber = $end_max_correction][1]"/>

		<xsl:variable name="end_designator" select="$end_latest_timeslice/aixm:designator"/>
		<xsl:variable name="end_type">
			<xsl:choose>
				<xsl:when test="$end_latest_timeslice/self::aixm:DesignatedPointTimeSlice/aixm:type">
					<xsl:value-of select="concat('WPT', ' (', $end_latest_timeslice/aixm:type, ')')"/>
				</xsl:when>
				<xsl:when test="$end_latest_timeslice/self::aixm:NavaidTimeSlice/aixm:type">
					<xsl:value-of select="$end_latest_timeslice/aixm:type"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		
		<tr style="white-space:nowrap">
			<td><xsl:value-of select="if (string-length($Master_gUID) = 0) then '&#160;' else $Master_gUID"/></td>
			<td><xsl:value-of select="if (string-length($RouteDesignator) = 0) then '&#160;' else $RouteDesignator"/></td>
			<td><xsl:value-of select="if (string-length($RouteAreaDesignator) = 0) then '&#160;' else $RouteAreaDesignator"/></td>
			<td><xsl:value-of select="if (string-length($start_designator) = 0) then '&#160;' else $start_designator"/></td>
			<td><xsl:value-of select="if (string-length($start_type) = 0) then '&#160;' else $start_type"/></td>
			<td><xsl:value-of select="if (string-length($end_designator) = 0) then '&#160;' else $end_designator"/></td>
			<td><xsl:value-of select="if (string-length($end_type) = 0) then '&#160;' else $end_type"/></td>
			<td><xsl:value-of select="if (string-length($UpperLimit) = 0) then '&#160;' else $UpperLimit"/></td>
			<td><xsl:value-of select="if (string-length($UpperLimit_uom) = 0) then '&#160;' else $UpperLimit_uom"/></td>
			<td><xsl:value-of select="if (string-length($UpperLimit_reference) = 0) then '&#160;' else $UpperLimit_reference"/></td>
			<td><xsl:value-of select="if (string-length($LowerLimit) = 0) then '&#160;' else $LowerLimit"/></td>
			<td><xsl:value-of select="if (string-length($LowerLimit_uom) = 0) then '&#160;' else $LowerLimit_uom"/></td>
			<td><xsl:value-of select="if (string-length($LowerLimit_reference) = 0) then '&#160;' else $LowerLimit_reference"/></td>
			<td><xsl:value-of select="if (string-length($EffectiveDate) = 2) then '&#160;' else $EffectiveDate"/></td>
			<td><xsl:value-of select="if (string-length($ValidTimeSlice) = 2) then '&#160;' else $ValidTimeSlice"/></td>
			<td><xsl:value-of select="if (string-length($Originator) = 0) then '&#160;' else $Originator"/></td>
		</tr>
		
		<!-- Find next segment whose start = this end -->
		<xsl:variable name="next" select="$segments[aixm:timeSlice/aixm:RouteSegmentTimeSlice[aixm:interpretation = 'BASELINE']/aixm:start/*/*/@xlink:href = concat('urn:uuid:', $end_uuid)][1]"/>
		
		<xsl:if test="$next">
			<xsl:call-template name="output-chain">
				<xsl:with-param name="segment" select="$next"/>
				<xsl:with-param name="segments" select="$segments"/>
				<xsl:with-param name="RouteDesignator" select="$RouteDesignator"/>
				<xsl:with-param name="Master_gUID" select="$Master_gUID"/>
				<xsl:with-param name="RouteAreaDesignator" select="$RouteAreaDesignator"/>
				<xsl:with-param name="EffectiveDate" select="$EffectiveDate"/>
				<xsl:with-param name="ValidTimeSlice" select="$ValidTimeSlice"/>
				<xsl:with-param name="Originator" select="$Originator"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
</xsl:stylesheet>