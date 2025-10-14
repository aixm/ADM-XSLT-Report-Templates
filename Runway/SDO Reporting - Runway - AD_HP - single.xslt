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
	includeReferencedFeaturesLevel: 1
							 featureOccurrence: aixm:Runway.aixm:type EQUALS 'RWY'
							 permanentBaseline: true
										 AIXMversion: 5.1.1
							indirectReferences: aixm:Runway references (aixm:RunwayDirection)
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
	xmlns:saxon="http://saxon.sf.net/"
	exclude-result-prefixes="xsl uuid message gts gco xsd gml gss gsr gmd aixm event xlink xs xsi aixm_ds_xslt ead-audit fcn math saxon">
	
	<xsl:output method="html" indent="yes" saxon:line-length="999999"/>
	
	<xsl:strip-space elements="*"/>
	
	<xsl:key name="AirportHeliport-by-uuid" match="aixm:AirportHeliport" use="gml:identifier"/>

	<!-- Global variable to capture document root for use in key() functions -->
	<xsl:variable name="doc-root" select="/"/>

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
	
	<!-- Get annotation text -->
	<xsl:function name="fcn:get-annotation-text" as="xs:string">
		<xsl:param name="raw_text" as="xs:string"/>
		<xsl:variable name="lines" select="for $line in tokenize($raw_text, '&#xA;') return normalize-space($line)"/>
		<xsl:variable name="non_empty_lines" select="$lines[string-length(.) gt 0]"/>
		<xsl:value-of select="string-join($non_empty_lines, ' ')"/>
	</xsl:function>
	
	<xsl:template match="/">
		
		<html xmlns="http://www.w3.org/1999/xhtml">
			
			<head>
				<meta http-equiv="Expires" content="120" />
				<title>SDO Reporting - Runway - AD / HP</title>
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
					<b>Runway - AD / HP</b>
				</center>
				<hr/>
				
				<table border="0" style="white-space:nowrap">
					<tbody>
						
						<tr>
							<td><strong>Aerodrome / Heliport - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>Aerodrome / Heliport - ICAO Code</strong></td>
						</tr>
						<tr>
							<td><strong>Aerodrome / Heliport - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>Designator</strong></td>
						</tr>
						<tr>
							<td><strong>Type</strong></td>
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
							<td><strong>Valid TimeSlice</strong></td>
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
						
						<xsl:for-each select="//aixm:Runway">

							<!-- Sort by AirportHeliport designator (using valid timeslice), then by Runway designator -->
							<xsl:sort select="
								let $rwy_baseline := aixm:timeSlice/aixm:RunwayTimeSlice[aixm:interpretation = 'BASELINE'],
									$rwy_max_seq := max($rwy_baseline/aixm:sequenceNumber),
									$rwy_max_corr := max($rwy_baseline[aixm:sequenceNumber = $rwy_max_seq]/aixm:correctionNumber),
									$rwy_latest := $rwy_baseline[aixm:sequenceNumber = $rwy_max_seq and aixm:correctionNumber = $rwy_max_corr][1],
									$ahp_uuid := replace($rwy_latest/aixm:associatedAirportHeliport/@xlink:href, '^(urn:uuid:|#uuid\.)', ''),
									$ahp := key('AirportHeliport-by-uuid', $ahp_uuid, $doc-root),
									$ahp_baseline := $ahp/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE'],
									$ahp_max_seq := max($ahp_baseline/aixm:sequenceNumber),
									$ahp_max_corr := max($ahp_baseline[aixm:sequenceNumber = $ahp_max_seq]/aixm:correctionNumber),
									$ahp_latest := $ahp_baseline[aixm:sequenceNumber = $ahp_max_seq and aixm:correctionNumber = $ahp_max_corr][1]
								return $ahp_latest/aixm:designator"
								data-type="text" order="ascending"/>

							<xsl:sort select="
								let $baseline := aixm:timeSlice/aixm:RunwayTimeSlice[aixm:interpretation = 'BASELINE'],
									$max_seq := max($baseline/aixm:sequenceNumber),
									$max_corr := max($baseline[aixm:sequenceNumber = $max_seq]/aixm:correctionNumber),
									$latest := $baseline[aixm:sequenceNumber = $max_seq and aixm:correctionNumber = $max_corr][1]
								return $latest/aixm:designator"
								data-type="text" order="ascending"/>

							<!-- Get all BASELINE time slices for this feature -->
							<xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:RunwayTimeSlice[aixm:interpretation = 'BASELINE']"/>
							<!-- Find the maximum sequenceNumber -->
							<xsl:variable name="max-sequence" select="max($baseline-timeslices/aixm:sequenceNumber)"/>
							<!-- Get time slices with the maximum sequenceNumber, then find max correctionNumber -->
							<xsl:variable name="max-correction" select="max($baseline-timeslices[aixm:sequenceNumber = $max-sequence]/aixm:correctionNumber)"/>
							<!-- Select the latest time slice -->
							<xsl:variable name="latest-timeslice" select="$baseline-timeslices[aixm:sequenceNumber = $max-sequence and aixm:correctionNumber = $max-correction][1]"/>
							
							<xsl:for-each select="$latest-timeslice">
								
								<!-- Internal UID (master) -->
								<xsl:variable name="RWY_UUID" select="../../gml:identifier"/>
								
								<!-- Valid TimeSlice -->
								<xsl:variable name="RWY_timeslice" select="concat('BASELINE ', $max-sequence, '.', $max-correction)"/>

								<!-- Get latest AirportHeliport timeslice -->
								<xsl:variable name="AHP_UUID" select="replace(aixm:associatedAirportHeliport/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<xsl:variable name="AHP" select="key('AirportHeliport-by-uuid', $AHP_UUID, $doc-root)"/>
								<xsl:variable name="AHP_baseline" select="$AHP/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="AHP_max_seq" select="max($AHP_baseline/aixm:sequenceNumber)"/>
								<xsl:variable name="AHP_max_corr" select="max($AHP_baseline[aixm:sequenceNumber = $AHP_max_seq]/aixm:correctionNumber)"/>
								<xsl:variable name="AHP_latest-ts" select="$AHP_baseline[aixm:sequenceNumber = $AHP_max_seq and aixm:correctionNumber = $AHP_max_corr][1]"/>
								<xsl:variable name="AHP_timeslice" select="concat('BASELINE ', $AHP_max_seq, '.', $AHP_max_corr)"/>

								<!-- Aerodrome / Heliport - Identification -->
								<xsl:variable name="AHP_designator">
									<xsl:choose>
										<xsl:when test="not($AHP_latest-ts/aixm:designator)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($AHP_latest-ts/aixm:designator)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>

								<!-- Aerodrome / Heliport - ICAO Code -->
								<xsl:variable name="AHP_ICAO_code">
									<xsl:choose>
										<xsl:when test="not($AHP_latest-ts/aixm:locationIndicatorICAO)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($AHP_latest-ts/aixm:locationIndicatorICAO)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Designator -->
								<xsl:variable name="RWY_designator">
									<xsl:choose>
										<xsl:when test="not(aixm:designator)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:designator)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Type -->
								<xsl:variable name="RWY_type">
									<xsl:choose>
										<xsl:when test="not(aixm:type)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:type)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Length -->
								<xsl:variable name="RWY_length">
									<xsl:choose>
										<xsl:when test="not(aixm:nominalLength)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:nominalLength)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Width -->
								<xsl:variable name="RWY_width">
									<xsl:choose>
										<xsl:when test="not(aixm:nominalWidth)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:nominalWidth)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Unit of measurement [horizontal dimension] -->
								<xsl:variable name="RWY_dimensions_uom" select="aixm:nominalLength/@uom"/>
								
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
									<xsl:choose>
										<xsl:when test="not($RWY_sfc_ch/aixm:composition)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($RWY_sfc_ch/aixm:composition)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Surface preparation method -->
								<xsl:variable name="RWY_sfc_prep_method">
									<xsl:choose>
										<xsl:when test="not($RWY_sfc_ch/aixm:preparation)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($RWY_sfc_ch/aixm:preparation)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Surface condition -->
								<xsl:variable name="RWY_sfc_cond">
									<xsl:choose>
										<xsl:when test="not($RWY_sfc_ch/aixm:surfaceCondition)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($RWY_sfc_ch/aixm:surfaceCondition)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- PCN value -->
								<xsl:variable name="RWY_PCN_val">
									<xsl:choose>
										<xsl:when test="not($RWY_sfc_ch/aixm:classPCN)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($RWY_sfc_ch/aixm:classPCN)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- PCN pavement type -->
								<xsl:variable name="RWY_PCN_pavement_type">
									<xsl:choose>
										<xsl:when test="not($RWY_sfc_ch/aixm:pavementTypePCN)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($RWY_sfc_ch/aixm:pavementTypePCN)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- PCN pavement subgrade -->
								<xsl:variable name="RWY_PCN_pavement_subgrade">
									<xsl:choose>
										<xsl:when test="not($RWY_sfc_ch/aixm:pavementSubgradePCN)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($RWY_sfc_ch/aixm:pavementSubgradePCN)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- PCN max tire pressure code -->
								<xsl:variable name="RWY_PCN_max_tyre_press_code">
									<xsl:choose>
										<xsl:when test="not($RWY_sfc_ch/aixm:maxTyrePressurePCN)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($RWY_sfc_ch/aixm:maxTyrePressurePCN)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- PCN max tire pressure value -->
								<xsl:variable name="RWY_PCN_max_tyre_press_val">
									<xsl:choose>
										<xsl:when test="not($RWY_sfc_ch/aixm:maxTyrePressurePCN)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:when test="$RWY_sfc_ch/aixm:maxTyrePressurePCN/@xsi:nil = 'true'">
											<xsl:value-of select="fcn:insert-value($RWY_sfc_ch/aixm:maxTyrePressurePCN)"/>
										</xsl:when>
										<xsl:otherwise>
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
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- PCN evaluation method -->
								<xsl:variable name="RWY_PCN_eval_method">
									<xsl:choose>
										<xsl:when test="not($RWY_sfc_ch/aixm:evaluationMethodPCN)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($RWY_sfc_ch/aixm:evaluationMethodPCN)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- PCN notes -->
								<xsl:variable name="RWY_PCN_notes">
									<xsl:for-each select="$RWY_sfc_ch/aixm:annotation/aixm:Note[aixm:propertyName = 'classPCN' or contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'txtPcnNote')]">
										<xsl:choose>
											<xsl:when test="contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'txtPcnNote')">
												<xsl:value-of select="substring-after(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], ':')"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:get-annotation-text(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')])"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:for-each>
								</xsl:variable>
								
								<!-- LCN value -->
								<xsl:variable name="RWY_LCN_val">
									<xsl:choose>
										<xsl:when test="not($RWY_sfc_ch/aixm:classLCN)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($RWY_sfc_ch/aixm:classLCN)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- SIWL weight -->
								<xsl:variable name="RWY_SIWL_weight">
									<xsl:choose>
										<xsl:when test="not($RWY_sfc_ch/aixm:weightSIWL)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($RWY_sfc_ch/aixm:weightSIWL)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Unit of measurement [SIWL weight] -->
								<xsl:variable name="RWY_SIWL_weight_uom" select="$RWY_sfc_ch/aixm:weightSIWL/@uom"/>
								
								<!-- SIWL tire pressure -->
								<xsl:variable name="RWY_SIWL_tyre_press">
									<xsl:choose>
										<xsl:when test="not($RWY_sfc_ch/aixm:tyrePressureSIWL)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($RWY_sfc_ch/aixm:tyrePressureSIWL)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Unit of measurement [SIWL tire pressure] -->
								<xsl:variable name="RWY_SIWL_tyre_press_uom" select="$RWY_sfc_ch/aixm:tyrePressureSIWL/@uom"/>
								
								<!-- All Up Wheel Weight -->
								<xsl:variable name="RWY_AUW_weight">
									<xsl:choose>
										<xsl:when test="not($RWY_sfc_ch/aixm:weightAUW)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($RWY_sfc_ch/aixm:weightAUW)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Unit of measurement [AUW weight] -->
								<xsl:variable name="RWY_AUW_weight_uom" select="$RWY_sfc_ch/aixm:weightAUW/@uom"/>
								
								<!-- Physical length of the strip -->
								<xsl:variable name="RWY_strip_length">
									<xsl:choose>
										<xsl:when test="not(aixm:lengthStrip)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:lengthStrip)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Physical width of the strip -->
								<xsl:variable name="RWY_strip_width">
									<xsl:choose>
										<xsl:when test="not(aixm:widthStrip)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:widthStrip)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Longitudinal offset of the strip -->
								<xsl:variable name="RWY_strip_long_offset">
									<xsl:choose>
										<xsl:when test="not(aixm:lengthOffset)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:lengthOffset)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Lateral offset of the strip -->
								<xsl:variable name="RWY_strip_lat_offset">
									<xsl:choose>
										<xsl:when test="not(aixm:widthOffset)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:widthOffset)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Unit of measurement [strip dimension] -->
								<xsl:variable name="RWY_strip_uom" select="aixm:lengthStrip/@uom"/>
								
								<!-- Operational status -->
								<xsl:variable name="RWY_op_status">
									<xsl:variable name="RDN-baseline-timeslices" select="//aixm:RunwayDirectionTimeSlice[aixm:interpretation = 'BASELINE' and replace(aixm:usedRunway/@xlink:href, '^(urn:uuid:|#uuid\.)', '') = $RWY_UUID]"/>
									<xsl:variable name="RDN-max-sequence" select="max($RDN-baseline-timeslices/aixm:sequenceNumber)"/>
									<xsl:variable name="RDN-max-correction" select="max($RDN-baseline-timeslices[aixm:sequenceNumber = $RDN-max-sequence]/aixm:correctionNumber)"/>
									<xsl:variable name="RDN-latest-timeslices" select="$RDN-baseline-timeslices[aixm:sequenceNumber = $RDN-max-sequence and aixm:correctionNumber = $RDN-max-correction]"/>
									<xsl:choose>
										<xsl:when test="count($RDN-latest-timeslices) = count($RDN-latest-timeslices/aixm:availability/aixm:ManoeuvringAreaAvailability[aixm:operationalStatus='NORMAL']) and count($RDN-latest-timeslices/aixm:availability/aixm:ManoeuvringAreaAvailability[aixm:operationalStatus='NORMAL']) gt 0">
											<xsl:value-of select="'Normal'"/>
										</xsl:when>
										<xsl:when test="count($RDN-latest-timeslices) = count($RDN-latest-timeslices/aixm:availability/aixm:ManoeuvringAreaAvailability[aixm:operationalStatus='CLOSED']) and count($RDN-latest-timeslices/aixm:availability/aixm:ManoeuvringAreaAvailability[aixm:operationalStatus='CLOSED']) gt 0">
											<xsl:value-of select="'Closed'"/>
										</xsl:when>
										<xsl:when test="count($RDN-latest-timeslices) gt count($RDN-latest-timeslices/aixm:availability/aixm:ManoeuvringAreaAvailability[aixm:operationalStatus='CLOSED']) and count($RDN-latest-timeslices/aixm:availability/aixm:ManoeuvringAreaAvailability[aixm:operationalStatus='CLOSED']) gt 0">
											<xsl:value-of select="'Limited'"/>
										</xsl:when>
										<xsl:when test="count($RDN-latest-timeslices/aixm:availability/aixm:ManoeuvringAreaAvailability[aixm:operationalStatus='LIMITED']) gt 0">
											<xsl:value-of select="'Limited'"/>
										</xsl:when>
										<xsl:when test="count($RDN-latest-timeslices/aixm:availability) = 0">
											<xsl:value-of select="'No availability data'"/>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Profile description -->
								<xsl:variable name="RWY_profile_description">
									<xsl:for-each select="aixm:annotation/aixm:Note[contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'txtProfile')]">
										<xsl:value-of select="fcn:get-annotation-text(substring-after(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], ':'))"/>
									</xsl:for-each>
								</xsl:variable>

								<!-- Marking -->
								<xsl:variable name="RWY_marking">
									<xsl:for-each select="aixm:annotation/aixm:Note[contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'txtMarking')]">
										<xsl:value-of select="fcn:get-annotation-text(substring-after(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], ':'))"/>
									</xsl:for-each>
								</xsl:variable>
								
								<!-- Remarks -->
								<xsl:variable name="remarks">
									<xsl:variable name="dataset_creation_date" select="//aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
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
								<xsl:variable name="originator" select="aixm:extension/ead-audit:RunwayExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
								
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_designator) gt 0) then $AHP_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_ICAO_code) gt 0) then $AHP_ICAO_code else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_timeslice) gt 0) then $AHP_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RWY_designator) gt 0) then $RWY_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RWY_type) gt 0) then $RWY_type else '&#160;'"/></td>
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
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($RWY_PCN_notes) gt 0"><xsl:value-of select="$RWY_PCN_notes" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
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
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($RWY_profile_description) gt 0"><xsl:value-of select="$RWY_profile_description" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
								</tr>
								<tr>
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($RWY_marking) gt 0"><xsl:value-of select="$RWY_marking" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
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
									<td><xsl:value-of select="if (string-length($RWY_timeslice) gt 0) then $RWY_timeslice else '&#160;'"/></td>
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
							
						</xsl:for-each>
						
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