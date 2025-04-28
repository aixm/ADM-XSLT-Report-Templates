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
	featureTypes: aixm:Runway
	includeReferencedFeaturesLevel: "1"
	featureOccurrence: "aixm:Runway.aixm:type EQUALS 'RWY'"
	permanentBaseline: true
	AIXMversion: 5.1.1
	indirectReferences: "aixm:Runway references (aixm:RunwayDirection)"
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
	
	<xsl:key name="AirportHeliport-by-uuid" match="aixm:AirportHeliport" use="gml:identifier"/>
	
	<xsl:function name="fcn:get-last-word" as="xs:string">
		<xsl:param name="input" as="xs:string"/>
		<xsl:variable name="words" select="tokenize(normalize-space($input), '\s+')"/>
		<xsl:sequence select="$words[last()]"/>
	</xsl:function>
	
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
	
	<xsl:template match="/">
		
		<html xmlns="http://www.w3.org/1999/xhtml">
			
			<head>
				<meta http-equiv="Expires" content="120" />
				<title>SDO Reporting - RWY version</title>
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
					<b>RWY version</b>
				</center>
				<hr/>
				
				<table border="0" style="border-spacing: 8px 4px">
					<tbody>
						
						<tr style="white-space:nowrap">
							<td><strong>Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Identification</strong></td>
							<td><strong>Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- ICAO Code</strong></td>
							<td><strong>Designator</strong></td>
							<td><strong>Length</strong></td>
							<td><strong>Width</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[horizontal dimension]</strong></td>
							<td><strong>(d)Surface strength method</strong></td>
							<td><strong>(d)Surface strength</strong></td>
							<td><strong>Surface composition</strong></td>
							<td><strong>Surface preparation<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>method</strong></td>
							<td><strong>Surface condition</strong></td>
							<td><strong>PCN value</strong></td>
							<td><strong>PCN pavement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>type</strong></td>
							<td><strong>PCN pavement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>subgrade</strong></td>
							<td><strong>PCN max tire<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>pressure code</strong></td>
							<td><strong>PCN max tire<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>pressure value</strong></td>
							<td><strong>PCN evaluation<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>method</strong></td>
							<td><strong>PCN notes</strong></td>
							<td><strong>LCN value</strong></td>
							<td><strong>SIWL weight</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[SIWL weight]</strong></td>
							<td><strong>SIWL tire pressure</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[SIWL tire pressure]</strong></td>
							<td><strong>All Up Wheel Weight</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[AUW weight]</strong></td>
							<td><strong>Physical length<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>of the strip</strong></td>
							<td><strong>Physical width<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>of the strip</strong></td>
							<td><strong>Longitudinal offset<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>of the strip</strong></td>
							<td><strong>Lateral offset<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>of the strip</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[strip dimension]</strong></td>
							<td><strong>Operational status</strong></td>
							<td><strong>Profile description</strong></td>
							<td><strong>Marking</strong></td>
							<td><strong>Remarks</strong></td>
							<td><strong>Effective date</strong></td>
							<td><strong>Committed on</strong></td>
							<td><strong>Internal UID (master)</strong></td>
							<td><strong>Originator</strong></td>
						</tr>
						
						<xsl:for-each select="//aixm:Runway/aixm:timeSlice/aixm:RunwayTimeSlice[aixm:type = 'RWY' and aixm:interpretation = 'BASELINE']">
							
							<xsl:sort select="key('AirportHeliport-by-uuid', substring-after(aixm:associatedAirportHeliport/@xlink:href, 'urn:uuid:'))/aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:designator" order="ascending"/>
							
							<!-- Internal UID (master) -->
							<xsl:variable name="RWY_UUID" select="../../gml:identifier"/>
							
							<!-- Aerodrome / Heliport - Identification -->
							<xsl:variable name="RWY_AHP_designator">
								<xsl:value-of select="key('AirportHeliport-by-uuid', substring-after(aixm:associatedAirportHeliport/@xlink:href, 'urn:uuid:'))/aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:designator"/>
							</xsl:variable>
							
							<!-- Aerodrome / Heliport - ICAO Code -->
							<xsl:variable name="RWY_AHP_ICAO_code">
								<xsl:value-of select="key('AirportHeliport-by-uuid', substring-after(aixm:associatedAirportHeliport/@xlink:href, 'urn:uuid:'))/aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:locationIndicatorICAO"/>
							</xsl:variable>
							
							<!-- Designator -->
							<xsl:variable name="RWY_designator">
								<xsl:value-of select="aixm:designator"/>
							</xsl:variable>
							
							<!-- Length -->
							<xsl:variable name="RWY_length">
								<xsl:value-of select="aixm:nominalLength"/>
							</xsl:variable>
							
							<!-- Width -->
							<xsl:variable name="RWY_width">
								<xsl:value-of select="aixm:nominalLength"/>
							</xsl:variable>
							
							<!-- Unit of measurement [horizontal dimension] -->
							<xsl:variable name="RWY_dimensions_uom">
								<xsl:value-of select="aixm:nominalLength/@uom"/>
							</xsl:variable>
							
							<xsl:variable name="RWY_sfc_ch" select="aixm:surfaceProperties/aixm:SurfaceCharacteristics"/>
							
							<!-- (d)Surface strength method -->
							<xsl:variable name="RWY_sfc_strenght_method">
								<!-- ? -->
							</xsl:variable>
							
							<!-- (d)Surface strength -->
							<xsl:variable name="RWY_sfc_strength">
								<xsl:if test="$RWY_sfc_ch/aixm:classPCN and $RWY_sfc_ch/aixm:pavementTypePCN=('RIGID', 'FLEXIBLE') and $RWY_sfc_ch/aixm:pavementSubgradePCN=('A', 'B', 'C', 'D') and $RWY_sfc_ch/aixm:maxTyrePressurePCN=('W', 'X', 'Y', 'Z') and $RWY_sfc_ch/aixm:evaluationMethodPCN=('TECH', 'ACFT')">
									<xsl:value-of select="concat($RWY_sfc_ch/aixm:classPCN, '/', substring($RWY_sfc_ch/aixm:pavementTypePCN, 1, 1), '/', $RWY_sfc_ch/aixm:pavementSubgradePCN, '/', $RWY_sfc_ch/aixm:maxTyrePressurePCN, '/', substring($RWY_sfc_ch/aixm:evaluationMethodPCN, 1, 1))"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Surface composition -->
							<xsl:variable name="RWY_sfc_comp">
								<xsl:value-of select="$RWY_sfc_ch/aixm:composition"/>
							</xsl:variable>
							
							<!-- Surface preparation method -->
							<xsl:variable name="RWY_sfc_prep_method">
								<xsl:value-of select="$RWY_sfc_ch/aixm:preparation"/>
							</xsl:variable>
							
							<!-- Surface condition -->
							<xsl:variable name="RWY_sfc_cond">
								<xsl:value-of select="$RWY_sfc_ch/aixm:surfaceCondition"/>
							</xsl:variable>
							
							<!-- PCN value -->
							<xsl:variable name="RWY_PCN_val">
								<xsl:value-of select="$RWY_sfc_ch/aixm:classPCN"/>
							</xsl:variable>
							
							<!-- PCN pavement type -->
							<xsl:variable name="RWY_PCN_pavement_type">
								<xsl:value-of select="$RWY_sfc_ch/aixm:pavementTypePCN"/>
							</xsl:variable>
							
							<!-- PCN pavement subgrade -->
							<xsl:variable name="RWY_PCN_pavement_subgrade">
								<xsl:value-of select="$RWY_sfc_ch/aixm:pavementSubgradePCN"/>
							</xsl:variable>
							
							<!-- PCN max tire pressure code -->
							<xsl:variable name="RWY_PCN_max_tyre_press_code">
								<xsl:value-of select="$RWY_sfc_ch/aixm:maxTyrePressurePCN"/>
							</xsl:variable>
							
							<!-- PCN max tire pressure value -->
							<xsl:variable name="RWY_PCN_max_tyre_press_val">
								<xsl:choose>
									<xsl:when test="$RWY_PCN_max_tyre_press_code = 'W'">
										<xsl:value-of select="'no pressure limit'"/>
									</xsl:when>
									<xsl:when test="$RWY_PCN_max_tyre_press_code = 'X'">
										<xsl:value-of select="'1.5 MPa (217 psi)'"/>
									</xsl:when>
									<xsl:when test="$RWY_PCN_max_tyre_press_code = 'Y'">
										<xsl:value-of select="'1.00 MPa (145 psi)'"/>
									</xsl:when>
									<xsl:when test="$RWY_PCN_max_tyre_press_code = 'Z'">
										<xsl:value-of select="'0.50 MPa (73 psi)'"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- PCN evaluation method -->
							<xsl:variable name="RWY_PCN_eval_method">
								<xsl:value-of select="$RWY_sfc_ch/aixm:evaluationMethodPCN"/>
							</xsl:variable>
							
							<!-- PCN notes -->
							<xsl:variable name="RWY_PCN_notes">
								<xsl:for-each select="$RWY_sfc_ch/aixm:annotation/aixm:Note[aixm:propertyName = 'classPCN' or contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, 'txtPcnNote')]">
									<xsl:choose>
										<xsl:when test="contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, 'txtPcnNote')">
											<xsl:value-of select="substring-after(aixm:translatedNote/aixm:LinguisticNote/aixm:note, ':')"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="aixm:translatedNote/aixm:LinguisticNote/aixm:note"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:for-each>
							</xsl:variable>
							
							<!-- LCN value -->
							<xsl:variable name="RWY_LCN_val">
								<xsl:value-of select="$RWY_sfc_ch/aixm:classLCN"/>
							</xsl:variable>
							
							<!-- SIWL weight -->
							<xsl:variable name="RWY_SIWL_weight">
								<xsl:value-of select="$RWY_sfc_ch/aixm:weightSIWL"/>
							</xsl:variable>
							
							<!-- Unit of measurement [SIWL weight] -->
							<xsl:variable name="RWY_SIWL_weight_uom">
								<xsl:value-of select="$RWY_sfc_ch/aixm:weightSIWL/@uom"/>
							</xsl:variable>
							
							<!-- SIWL tire pressure -->
							<xsl:variable name="RWY_SIWL_tyre_press">
								<xsl:value-of select="$RWY_sfc_ch/aixm:tyrePressureSIWL"/>
							</xsl:variable>
							
							<!-- Unit of measurement [SIWL tire pressure] -->
							<xsl:variable name="RWY_SIWL_tyre_press_uom">
								<xsl:value-of select="$RWY_sfc_ch/aixm:tyrePressureSIWL/@uom"/>
							</xsl:variable>
							
							<!-- All Up Wheel Weight -->
							<xsl:variable name="RWY_AUW_weight">
								<xsl:value-of select="$RWY_sfc_ch/aixm:weightAUW"/>
							</xsl:variable>
							
							<!-- Unit of measurement [AUW weight] -->
							<xsl:variable name="RWY_AUW_weight_uom">
								<xsl:value-of select="$RWY_sfc_ch/aixm:weightAUW/@uom"/>
							</xsl:variable>
							
							<!-- Physical length of the strip -->
							<xsl:variable name="RWY_strip_length">
								<xsl:value-of select="aixm:lengthStrip"/>
							</xsl:variable>
							
							<!-- Physical width of the strip -->
							<xsl:variable name="RWY_strip_width">
								<xsl:value-of select="aixm:widthStrip"/>
							</xsl:variable>
							
							<!-- Longitudinal offset of the strip -->
							<xsl:variable name="RWY_strip_long_offset">
								<xsl:value-of select="aixm:lengthOffset"/>
							</xsl:variable>
							
							<!-- Lateral offset of the strip -->
							<xsl:variable name="RWY_strip_lat_offset">
								<xsl:value-of select="aixm:widthOffset"/>
							</xsl:variable>
							
							<!-- Unit of measurement [strip dimension] -->
							<xsl:variable name="RWY_strip_uom">
								<xsl:value-of select="aixm:lengthStrip/@uom"/>
							</xsl:variable>
							
							<!-- Operational status -->
							<xsl:variable name="RWY_op_status">
								<xsl:variable name="RunwayDirection" select="//aixm:RunwayDirectionTimeSlice[substring-after(aixm:usedRunway/@xlink:href, 'urn:uuid:')=$RWY_UUID]"/>
								<xsl:choose>
									<xsl:when test="count($RunwayDirection) = count($RunwayDirection/aixm:availability/aixm:ManoeuvringAreaAvailability[aixm:operationalStatus='NORMAL']) and count($RunwayDirection/aixm:availability/aixm:ManoeuvringAreaAvailability[aixm:operationalStatus='NORMAL']) gt 0">
										<xsl:value-of select="'Normal'"/>
									</xsl:when>
									<xsl:when test="count($RunwayDirection) = count($RunwayDirection/aixm:availability/aixm:ManoeuvringAreaAvailability[aixm:operationalStatus='CLOSED']) and count($RunwayDirection/aixm:availability/aixm:ManoeuvringAreaAvailability[aixm:operationalStatus='CLOSED']) gt 0">
										<xsl:value-of select="'Closed'"/>
									</xsl:when>
									<xsl:when test="count($RunwayDirection) gt count($RunwayDirection/aixm:availability/aixm:ManoeuvringAreaAvailability[aixm:operationalStatus='CLOSED']) and count($RunwayDirection/aixm:availability/aixm:ManoeuvringAreaAvailability[aixm:operationalStatus='CLOSED']) gt 0">
										<xsl:value-of select="'Limited'"/>
									</xsl:when>
									<xsl:when test="count($RunwayDirection/aixm:availability/aixm:ManoeuvringAreaAvailability[aixm:operationalStatus='LIMITED']) gt 0">
										<xsl:value-of select="'Limited'"/>
									</xsl:when>
									<xsl:when test="count($RunwayDirection/aixm:availability) = 0">
										<xsl:value-of select="'No availability data'"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- Profile description -->
							<xsl:variable name="RWY_profile_description">
								<xsl:for-each select="aixm:annotation/aixm:Note[contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, 'txtProfile')]">
									<xsl:value-of select="substring-after(aixm:translatedNote/aixm:LinguisticNote/aixm:note, ':')"/>
								</xsl:for-each>
							</xsl:variable>
							
							<!-- Marking -->
							<xsl:variable name="RWY_marking">
								<xsl:for-each select="aixm:annotation/aixm:Note[contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, 'txtMarking')]">
									<xsl:value-of select="substring-after(aixm:translatedNote/aixm:LinguisticNote/aixm:note, ':')"/>
								</xsl:for-each>
							</xsl:variable>
							
							<!-- Remarks -->
							<xsl:variable name="remarks">
								<xsl:variable name="dataset_creation_date" select="../../../../aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
								<xsl:if test="string-length($dataset_creation_date) gt 0">
									<xsl:value-of select="concat('Current time: ', $dataset_creation_date)"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Effective date -->
							<xsl:variable name="effective_date">
								<xsl:if test="gml:validTime/gml:TimePeriod/gml:beginPosition">
									<xsl:value-of select="fcn:get-date(gml:validTime/gml:TimePeriod/gml:beginPosition)"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Committed on -->
							<xsl:variable name="commit_date">
								<xsl:if test="aixm:extension/ead-audit:RunwayExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate">
									<xsl:value-of select="fcn:get-date(aixm:extension/ead-audit:RunwayExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Originator -->
							<xsl:variable name="originator">
								<xsl:value-of select="aixm:extension/ead-audit:RunwayExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
							</xsl:variable>
							
							<tr style="white-space:nowrap;vertical-align:top;">
								<td><xsl:value-of select="if (string-length($RWY_AHP_designator) gt 0) then $RWY_AHP_designator else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_AHP_ICAO_code) gt 0) then $RWY_AHP_ICAO_code else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_designator) gt 0) then $RWY_designator else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_length) gt 0) then $RWY_length else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_width) gt 0) then $RWY_width else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_dimensions_uom) gt 0) then $RWY_dimensions_uom else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_sfc_strenght_method) gt 0) then $RWY_sfc_strenght_method else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_sfc_strength) gt 0) then $RWY_sfc_strength else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_sfc_comp) gt 0) then $RWY_sfc_comp else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_sfc_prep_method) gt 0) then $RWY_sfc_prep_method else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_sfc_cond) gt 0) then $RWY_sfc_cond else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_PCN_val) gt 0) then $RWY_PCN_val else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_PCN_pavement_type) gt 0) then $RWY_PCN_pavement_type else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_PCN_pavement_subgrade) gt 0) then $RWY_PCN_pavement_subgrade else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_PCN_max_tyre_press_code) gt 0) then $RWY_PCN_max_tyre_press_code else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_PCN_max_tyre_press_val) gt 0) then $RWY_PCN_max_tyre_press_val else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_PCN_eval_method) gt 0) then $RWY_PCN_eval_method else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_PCN_notes) gt 0) then $RWY_PCN_notes else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_LCN_val) gt 0) then $RWY_LCN_val else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_SIWL_weight) gt 0) then $RWY_SIWL_weight else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_SIWL_weight_uom) gt 0) then $RWY_SIWL_weight_uom else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_SIWL_tyre_press) gt 0) then $RWY_SIWL_tyre_press else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_SIWL_tyre_press_uom) gt 0) then $RWY_SIWL_tyre_press_uom else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_AUW_weight) gt 0) then $RWY_AUW_weight else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_AUW_weight_uom) gt 0) then $RWY_AUW_weight_uom else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_strip_length) gt 0) then $RWY_strip_length else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_strip_width) gt 0) then $RWY_strip_width else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_strip_long_offset) gt 0) then $RWY_strip_long_offset else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_strip_lat_offset) gt 0) then $RWY_strip_lat_offset else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_strip_uom) gt 0) then $RWY_strip_uom else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_op_status) gt 0) then $RWY_op_status else '&#160;'"/></td>
								<td style="white-space:normal;min-width:300px"><xsl:value-of select="if (string-length($RWY_profile_description) gt 0) then $RWY_profile_description else '&#160;'"/></td>
								<td style="white-space:normal;min-width:300px"><xsl:value-of select="if (string-length($RWY_marking) gt 0) then $RWY_marking else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($remarks) gt 0) then $remarks else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($commit_date) gt 0) then $commit_date else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($RWY_UUID) gt 0) then $RWY_UUID else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($originator) gt 0) then $originator else '&#160;'"/></td>
							</tr>
							
						</xsl:for-each>
						
					</tbody>
				</table>
				
				<!-- Extraction rule parameters used for this report -->
				
				<xsl:variable name="rule_parameters" select="//aixm:messageMetadata/gmd:MD_Metadata/gmd:fileIdentifier/gco:CharacterString"/>
				
				<!-- extractionRulesUUID -->
				<xsl:variable name="rule_uuid">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', interestedInDataAt'), 'extractionRulesUuid: ')"/>
				</xsl:variable>
				
				<!-- interestedInDataAt -->
				<xsl:variable name="interest_date">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', featureTypes'), 'interestedInDataAt: ')"/>
				</xsl:variable>
				
				<!-- featureTypes -->
				<xsl:variable name="feat_types">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', excludedProperties'), 'featureTypes: ')"/>
				</xsl:variable>
				
				<!-- excludedProperties -->
				<xsl:variable name="exc_properties">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', includeReferencedFeaturesLevel'), 'excludedProperties: ')"/>
				</xsl:variable>
				
				<!-- includeReferencedFeaturesLevel -->
				<xsl:variable name="referenced_feat_level">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', featureOccurrence'), 'includeReferencedFeaturesLevel: ')"/>
				</xsl:variable>
				
				<!-- featureOccurrence -->
				<xsl:variable name="feat_occurrence">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', effectiveDateStart'), 'featureOccurrence: ')"/>
				</xsl:variable>
				
				<!-- effectiveDateStart -->
				<xsl:variable name="eff_date_start">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', effectiveDateEnd'), 'effectiveDateStart: ')"/>
				</xsl:variable>
				
				<!-- effectiveDateEnd -->
				<xsl:variable name="eff_date_end">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', referencedDataFeature'), 'effectiveDateEnd: ')"/>
				</xsl:variable>
				
				<!-- referencedDataFeature -->
				<xsl:variable name="referenced_data_feat">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', permanentBaseline'), 'referencedDataFeature: ')"/>
				</xsl:variable>
				
				<!-- permanentBaseline -->
				<xsl:variable name="perm_BL">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', permanentPermdelta'), 'permanentBaseline: ')"/>
				</xsl:variable>
				
				<!-- permanentPermdelta -->
				<xsl:variable name="perm_PD">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', temporaryData'), 'permanentPermdelta: ')"/>
				</xsl:variable>
				
				<!-- temporaryData -->
				<xsl:variable name="temp_data">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', permanentBaselineForTemporaryData'), 'temporaryData: ')"/>
				</xsl:variable>
				
				<!-- permanentBaselineForTemporaryData -->
				<xsl:variable name="perm_BS_for_temp_data">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', spatialFilteringBy'), 'permanentBaselineForTemporaryData: ')"/>
				</xsl:variable>
				
				<!-- spatialFilteringBy -->
				<xsl:variable name="spatial_filtering">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', spatialAreaUUID'), 'spatialFilteringBy: ')"/>
				</xsl:variable>
				
				<!-- spatialAreaUUID -->
				<xsl:variable name="spatial_area_uuid">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', spatialAreaBuffer'), 'spatialAreaUUID: ')"/>
				</xsl:variable>
				
				<!-- spatialAreaBuffer -->
				<xsl:variable name="spatial_area_buffer">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', spatialOperator'), 'spatialAreaBuffer: ')"/>
				</xsl:variable>
				
				<!-- spatialOperator -->
				<xsl:variable name="spatial_operator">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', spatialValueOperator'), 'spatialOperator: ')"/>
				</xsl:variable>
				
				<!-- spatialValueOperator -->
				<xsl:variable name="spatial_value_operator">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', dataBranch'), 'spatialValueOperator: ')"/>
				</xsl:variable>
				
				<!-- dataBranch -->
				<xsl:variable name="data_branch">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', dataScope'), 'dataBranch: ')"/>
				</xsl:variable>
				
				<!-- dataScope -->
				<xsl:variable name="data_scope">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', dataProviderOrganization'), 'dataScope: ')"/>
				</xsl:variable>
				
				<!-- dataProviderOrganization -->
				<xsl:variable name="data_provider_org">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', systemExtension'), 'dataProviderOrganization: ')"/>
				</xsl:variable>
				
				<!-- systemExtension -->
				<xsl:variable name="system_extension">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', AIXMversion'), 'systemExtension: ')"/>
				</xsl:variable>
				
				<!-- AIXMversion -->
				<xsl:variable name="AIXM_ver">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', indirectReferences'), 'AIXMversion: ')"/>
				</xsl:variable>
				
				<!-- indirectReferences -->
				<xsl:variable name="indirect_references">
					<xsl:value-of select="substring-after(substring-before($rule_parameters, ', dataType'), 'indirectReferences: ')"/>
				</xsl:variable>
				
				<!-- dataType -->
				<xsl:variable name="data_type">
					<xsl:value-of select="substring-after($rule_parameters, 'dataType: ')"/>
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
				</table>
				
				<p></p>
				<table>
					<tr>
						<td><font size="-1">Sorting by column: </font></td>
						<td><font size="-1">Aerodrome / Heliport - Identification</font></td>
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
	
</xsl:transform>