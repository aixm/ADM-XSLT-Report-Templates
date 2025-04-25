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
	featureTypes: aixm:Runway;
	includeReferencedFeaturesLevel: "1";
	featureOccurrence (optional): "aixm:Runway.aixm:type EQUALS 'RWY'";
	permanentBaseline: true;
	AIXMversion: 5.1.1;
	indirectReferences: "aixm:Runway references (aixm:RunwayDirection)";
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
	
	<xsl:function name="fcn:get-lat-DMS" as="xs:string">
		<xsl:param name="input" as="xs:double"/>
		<xsl:variable name="lat_decimal_degrees" select="$input"/>
		<xsl:variable name="lat_whole" select="string(floor(abs($lat_decimal_degrees)))"/>
		<xsl:variable name="lat_frac" select="string(abs($lat_decimal_degrees) - floor(abs($lat_decimal_degrees)))"/>
		<xsl:variable name="lat_deg" select="if (string-length($lat_whole) = 1) then concat('0', $lat_whole) else $lat_whole"/>
		<xsl:variable name="lat_min_whole" select="floor(number($lat_frac) * 60)"/>
		<xsl:variable name="lat_min_frac" select="number($lat_frac) * 60 - $lat_min_whole"/>
		<xsl:variable name="lat_min" select="if (string-length(string($lat_min_whole)) = 1) then concat('0', string($lat_min_whole)) else string($lat_min_whole)"/>
		<xsl:variable name="lat_sec" select="format-number($lat_min_frac * 60, '0.00')"/>
		<xsl:variable name="lat_sec" select="if (string-length(string(floor(number($lat_sec)))) = 1) then concat('0', string($lat_sec)) else string($lat_sec)"/>
		<xsl:value-of select="concat($lat_deg, $lat_min, $lat_sec, if ($lat_decimal_degrees ge 0) then 'N' else 'S')"/>
	</xsl:function>
	
	<xsl:function name="fcn:get-long-DMS" as="xs:string">
		<xsl:param name="input" as="xs:double"/>
		<xsl:variable name="long_decimal_degrees" select="$input"/>
		<xsl:variable name="long_whole" select="string(floor(abs($long_decimal_degrees)))"/>
		<xsl:variable name="long_frac" select="string(abs($long_decimal_degrees) - floor(abs($long_decimal_degrees)))"/>
		<xsl:variable name="long_deg" select="if (string-length($long_whole) != 3) then (if (string-length($long_whole) = 1) then concat('00', $long_whole) else concat('0', $long_whole)) else $long_whole"/>
		<xsl:variable name="long_min_whole" select="floor(number($long_frac) * 60)"/>
		<xsl:variable name="long_min_frac" select="number($long_frac) * 60 - $long_min_whole"/>
		<xsl:variable name="long_min" select="if (string-length(string($long_min_whole)) = 1) then concat('0', string($long_min_whole)) else string($long_min_whole)"/>
		<xsl:variable name="long_sec" select="format-number($long_min_frac * 60, '0.00')"/>
		<xsl:variable name="long_sec" select="if (string-length(string(floor(number($long_sec)))) = 1) then concat('0', string($long_sec)) else string($long_sec)"/>
		<xsl:value-of select="concat($long_deg, $long_min, $long_sec, if ($long_decimal_degrees ge 0) then 'E' else 'W')"/>
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
				
				<table border="0">
					<tbody>
						
						<tr>
							<td><strong>Aerodrome / Heliport - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>Aerodrome / Heliport - ICAO Code</strong></td>
						</tr>
						<tr>
							<td><strong>Designator</strong></td>
						</tr>
						<tr>
							<td><strong>Length</strong></td>
						</tr>
						<tr>
							<td><strong>Width</strong></td>
						</tr>
						<tr>
							<td><strong>Unit of measurement [horizontal dimension]</strong></td>
						</tr>
						<tr>
							<td><strong>(d)Surface strength method</strong></td>
						</tr>
						<tr>
							<td><strong>(d)Surface strength</strong></td>
						</tr>
						<tr>
							<td><strong>Surface composition</strong></td>
						</tr>
						<tr>
							<td><strong>Surface preparation method</strong></td>
						</tr>
						<tr>
							<td><strong>Surface condition</strong></td>
						</tr>
						<tr>
							<td><strong>PCN value</strong></td>
						</tr>
						<tr>
							<td><strong>PCN pavement type</strong></td>
						</tr>
						<tr>
							<td><strong>PCN pavement subgrade</strong></td>
						</tr>
						<tr>
							<td><strong>PCN max tire pressure code</strong></td>
						</tr>
						<tr>
							<td><strong>PCN max tire pressure value</strong></td>
						</tr>
						<tr>
							<td><strong>PCN evaluation method</strong></td>
						</tr>
						<tr>
							<td><strong>PCN notes</strong></td>
						</tr>
						<tr>
							<td><strong>LCN value</strong></td>
						</tr>
						<tr>
							<td><strong>SIWL weight</strong></td>
						</tr>
						<tr>
							<td><strong>Unit of measurement [SIWL weight]</strong></td>
						</tr>
						<tr>
							<td><strong>SIWL tire pressure</strong></td>
						</tr>
						<tr>
							<td><strong>Unit of measurement [SIWL tire pressure]</strong></td>
						</tr>
						<tr>
							<td><strong>All Up Wheel Weight</strong></td>
						</tr>
						<tr>
							<td><strong>Unit of measurement [AUW weight]</strong></td>
						</tr>
						<tr>
							<td><strong>Physical length of the strip</strong></td>
						</tr>
						<tr>
							<td><strong>Physical width of the strip</strong></td>
						</tr>
						<tr>
							<td><strong>Longitudinal offset of the strip</strong></td>
						</tr>
						<tr>
							<td><strong>Lateral offset of the strip</strong></td>
						</tr>
						<tr>
							<td><strong>Unit of measurement [strip dimension]</strong></td>
						</tr>
						<tr>
							<td><strong>Operational status</strong></td>
						</tr>
						<tr>
							<td><strong>Profile description</strong></td>
						</tr>
						<tr>
							<td><strong>Marking</strong></td>
						</tr>
						<tr>
							<td><strong>Remarks</strong></td>
						</tr>
						<tr>
							<td><strong>Effective date</strong></td>
						</tr>
						<tr>
							<td><strong>Committed on</strong></td>
						</tr>
						<tr>
							<td><strong>Internal UID (master)</strong></td>
						</tr>
						<tr>
							<td><strong>Originator</strong></td>
						</tr>
						<tr>
							<td>&#160;</td>
						</tr>
						<tr>
							<td>&#160;</td>
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
							
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_AHP_designator) gt 0) then $RWY_AHP_designator else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_AHP_ICAO_code) gt 0) then $RWY_AHP_ICAO_code else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_designator) gt 0) then $RWY_designator else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_length) gt 0) then $RWY_length else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_width) gt 0) then $RWY_width else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_dimensions_uom) gt 0) then $RWY_dimensions_uom else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_sfc_strenght_method) gt 0) then $RWY_sfc_strenght_method else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_sfc_strength) gt 0) then $RWY_sfc_strength else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_sfc_comp) gt 0) then $RWY_sfc_comp else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_sfc_prep_method) gt 0) then $RWY_sfc_prep_method else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_sfc_cond) gt 0) then $RWY_sfc_cond else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_PCN_val) gt 0) then $RWY_PCN_val else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_PCN_pavement_type) gt 0) then $RWY_PCN_pavement_type else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_PCN_pavement_subgrade) gt 0) then $RWY_PCN_pavement_subgrade else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_PCN_max_tyre_press_code) gt 0) then $RWY_PCN_max_tyre_press_code else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_PCN_max_tyre_press_val) gt 0) then $RWY_PCN_max_tyre_press_val else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_PCN_eval_method) gt 0) then $RWY_PCN_eval_method else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_PCN_notes) gt 0) then $RWY_PCN_notes else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_LCN_val) gt 0) then $RWY_LCN_val else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_SIWL_weight) gt 0) then $RWY_SIWL_weight else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_SIWL_weight_uom) gt 0) then $RWY_SIWL_weight_uom else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_SIWL_tyre_press) gt 0) then $RWY_SIWL_tyre_press else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_SIWL_tyre_press_uom) gt 0) then $RWY_SIWL_tyre_press_uom else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_AUW_weight) gt 0) then $RWY_AUW_weight else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_AUW_weight_uom) gt 0) then $RWY_AUW_weight_uom else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_strip_length) gt 0) then $RWY_strip_length else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_strip_width) gt 0) then $RWY_strip_width else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_strip_long_offset) gt 0) then $RWY_strip_long_offset else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_strip_lat_offset) gt 0) then $RWY_strip_lat_offset else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_strip_uom) gt 0) then $RWY_strip_uom else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_op_status) gt 0) then $RWY_op_status else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_profile_description) gt 0) then $RWY_profile_description else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_marking) gt 0) then $RWY_marking else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($remarks) gt 0) then $remarks else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($commit_date) gt 0) then $commit_date else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($RWY_UUID) gt 0) then $RWY_UUID else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($originator) gt 0) then $originator else '&#160;'"/></td>
							</tr>
							<tr>
								<td>&#160;</td>
							</tr>
							<tr>
								<td>&#160;</td>
							</tr>
							
						</xsl:for-each>
						
					</tbody>
				</table>
				
			</body>
			
		</html>
		
	</xsl:template>
	
</xsl:transform>