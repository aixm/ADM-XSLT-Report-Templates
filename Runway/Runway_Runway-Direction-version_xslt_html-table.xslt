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
	featureTypes: aixm:RunwayDirection;
	includeReferencedFeaturesLevel: "2"
	permanentBaseline: true
	dataScope: ReleasedData
	AIXMversion: 5.1.1
	indirectReferences: "aixm:RunwayDirection references (aixm:ArrestingGear aixm:RunwayCentrelinePoint aixm:RunwayVisualRange aixm:VisualGlideSlopeIndicator)"
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
				<title>SDO Reporting - RWY Direction version</title>
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
					<b>RWY Direction version</b>
				</center>
				<hr/>
				
				<table border="0" style="border-spacing: 8px 4px">
					<tbody>
						
						<tr style="white-space:nowrap">
							<td><strong>Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Identification</strong></td>
							<td><strong>Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- ICAO Code</strong></td>
							<td><strong>Runway [RWY]<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Designator</strong></td>
							<td><strong>Designator</strong></td>
							<td><strong>Threshold - Latitude</strong></td>
							<td><strong>Threshold - Longitude</strong></td>
							<td><strong>True bearing</strong></td>
							<td><strong>Magnetic bearing</strong></td>
							<td><strong>Elevation of<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>touch down zone</strong></td>
							<td><strong>VASIS Position</strong></td>
							<td><strong>VASIS number<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>of boxes</strong></td>
							<td><strong>Portable VASIS</strong></td>
							<td><strong>Accuracy of the<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>touch down zone elevation</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[touch down zone elevation]</strong></td>
							<td><strong>Taxi time<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>estimation</strong></td>
							<td><strong>Type</strong></td>
							<td><strong>(d)VASIS position description</strong></td>
							<td><strong>Approach slope angle</strong></td>
							<td><strong>Minimun eye height<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>over threshold</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[minimum eye height over threshold]</strong></td>
							<td><strong>Arresting device</strong></td>
							<td><strong>RVR meteorological equipment</strong></td>
							<td><strong>Direction of the<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>VFR flight pattern</strong></td>
							<td><strong>Remarks</strong></td>
							<td><strong>Effective date</strong></td>
							<td><strong>Committed on</strong></td>
							<td><strong>Internal UID (master)</strong></td>
							<td><strong>Originator</strong></td>
						</tr>
						
						<xsl:for-each select="//aixm:Runway/aixm:timeSlice/aixm:RunwayTimeSlice[aixm:type = 'RWY' and aixm:interpretation = 'BASELINE']">
							
							<xsl:sort select="key('AirportHeliport-by-uuid', substring-after(aixm:associatedAirportHeliport/@xlink:href, 'urn:uuid:'))/aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:designator" order="ascending"/>
							
							<xsl:variable name="RWY_UUID">
								<xsl:value-of select="../../gml:identifier"/>
							</xsl:variable>
							
							<!-- Aerodrome / Heliport - Identification -->
							<xsl:variable name="RWY_AHP_designator">
								<xsl:value-of select="key('AirportHeliport-by-uuid', substring-after(aixm:associatedAirportHeliport/@xlink:href, 'urn:uuid:'))/aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:designator"/>
							</xsl:variable>
							
							<!-- Aerodrome / Heliport - ICAO Code -->
							<xsl:variable name="RWY_AHP_ICAO_code">
								<xsl:value-of select="key('AirportHeliport-by-uuid', substring-after(aixm:associatedAirportHeliport/@xlink:href, 'urn:uuid:'))/aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:locationIndicatorICAO"/>
							</xsl:variable>
							
							<!-- Runway [RWY] - Designator -->
							<xsl:variable name="RWY_designator">
								<xsl:value-of select="aixm:designator"/>
							</xsl:variable>
							
							<xsl:for-each select="//aixm:RunwayDirection/aixm:timeSlice/aixm:RunwayDirectionTimeSlice[substring-after(aixm:usedRunway/@xlink:href, 'urn:uuid:') = $RWY_UUID and aixm:interpretation = 'BASELINE']">
								
								<!-- Internal UID (master) -->
								<xsl:variable name="RD_UUID" select="../../gml:identifier"/>
								
								<!-- Designator -->
								<xsl:variable name="RD_designator">
									<xsl:value-of select="aixm:designator"/>
								</xsl:variable>
								
								<!-- Threshold - Latitude -->
								<xsl:variable name="RD_THR_lat">
									<xsl:if test="//aixm:RunwayCentrelinePointTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:onRunway/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:location/aixm:ElevatedPoint/gml:pos">
										<xsl:value-of select="fcn:get-lat-DMS(number(substring-before(//aixm:RunwayCentrelinePointTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:onRunway/@xlink:href, 'urn:uuid:') = $RD_UUID and aixm:role = ('THR','DISTHR')]/aixm:location/aixm:ElevatedPoint/gml:pos[1], ' ')))"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Threshold - Longitude -->
								<xsl:variable name="RD_THR_long">
									<xsl:if test="//aixm:RunwayCentrelinePointTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:onRunway/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:location/aixm:ElevatedPoint/gml:pos">
										<xsl:value-of select="fcn:get-long-DMS(number(substring-after(//aixm:RunwayCentrelinePointTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:onRunway/@xlink:href, 'urn:uuid:') = $RD_UUID and aixm:role = ('THR','DISTHR')]/aixm:location/aixm:ElevatedPoint/gml:pos[1], ' ')))"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- True bearing -->
								<xsl:variable name="RD_THR_true_brg">
									<xsl:value-of select="aixm:trueBearing"/>
								</xsl:variable>
								
								<!-- Magnetic bearing -->
								<xsl:variable name="RD_THR_mag_brg">
									<xsl:value-of select="aixm:magneticBearing"/>
								</xsl:variable>
								
								<!-- Elevation of touch down zone -->
								<xsl:variable name="RD_TDZ_elevation">
									<xsl:value-of select="aixm:elevationTDZ"/>
								</xsl:variable>
								
								<!-- VASIS Position -->
								<xsl:variable name="RD_VASIS_position">
									<xsl:choose>
										<xsl:when test="//aixm:VisualGlideSlopeIndicatorTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:runwayDirection/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:position">
											<xsl:value-of select="//aixm:VisualGlideSlopeIndicatorTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:runwayDirection/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:position"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:for-each select="aixm:annotation/aixm:Note">
												<xsl:if test="contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, 'VASIS position')">
													<xsl:variable name="annotation_text" select="concat(normalize-space(replace(aixm:translatedNote/aixm:LinguisticNote/aixm:note,'(\r\n?|\n)', ' ')), ' ')"/>
													<xsl:value-of select="substring-before(substring-after($annotation_text, 'VASIS position: '), ' ')"/>
												</xsl:if>
											</xsl:for-each>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- VASIS number of boxes -->
								<xsl:variable name="RD_VASIS_nr_box">
									<xsl:value-of select="//aixm:VisualGlideSlopeIndicatorTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:runwayDirection/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:numberBox"/>
								</xsl:variable>
								
								<!-- Portable VASIS -->
								<xsl:variable name="RD_portable_VASIS">
									<xsl:choose>
										<xsl:when test="//aixm:VisualGlideSlopeIndicatorTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:runwayDirection/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:portable">
											<xsl:value-of select="//aixm:VisualGlideSlopeIndicatorTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:runwayDirection/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:portable"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:for-each select="aixm:annotation/aixm:Note">
												<xsl:if test="contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, 'PortableVASIS')">
													<xsl:variable name="annotation_text" select="concat(normalize-space(replace(aixm:translatedNote/aixm:LinguisticNote/aixm:note,'(\r\n?|\n)', ' ')), ' ')"/>
													<xsl:value-of select="substring-before(substring-after($annotation_text, 'PortableVASIS: '), ' ')"/>
												</xsl:if>
											</xsl:for-each>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Accuracy of the touch down zone elevation -->
								<xsl:variable name="RD_TDZ_accuracy">
									<xsl:value-of select="aixm:elevationTDZAccuracy"/>
								</xsl:variable>
								
								<!-- Unit of measurement [touch down zone elevation] -->
								<xsl:variable name="RD_TDZ_accuracy_uom">
									<xsl:value-of select="aixm:elevationTDZ/@uom"/>
								</xsl:variable>
								
								<!-- Taxi time estimation -->
								<xsl:variable name="RD_taxitime_est">
									<!-- ? -->
								</xsl:variable>
								
								<!-- Type -->
								<xsl:variable name="RD_VASIS_type">
									<xsl:choose>
										<xsl:when test="//aixm:VisualGlideSlopeIndicatorTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:runwayDirection/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:type">
											<xsl:value-of select="//aixm:VisualGlideSlopeIndicatorTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:runwayDirection/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:type"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:for-each select="aixm:annotation/aixm:Note">
												<xsl:if test="contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, 'Type of VASIS')">
													<xsl:variable name="annotation_text" select="concat(normalize-space(replace(aixm:translatedNote/aixm:LinguisticNote/aixm:note,'(\r\n?|\n)', ' ')), ' ')"/>
													<xsl:value-of select="substring-before(substring-after($annotation_text, 'Type of VASIS: '), ' ')"/>
												</xsl:if>
											</xsl:for-each>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- (d)VASIS position description -->
								<xsl:variable name="RD_VASIS_position_desc">
									<xsl:value-of select="//aixm:VisualGlideSlopeIndicatorTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:runwayDirection/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:annotation/aixm:Note[aixm:propertyName = 'position']/aixm:translatedNote/aixm:LinguisticNote/aixm:note"/>
								</xsl:variable>
								
								<!-- Approach slope angle -->
								<xsl:variable name="RD_app_slope_ang">
									<xsl:choose>
										<xsl:when test="//aixm:VisualGlideSlopeIndicatorTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:runwayDirection/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:slopeAngle">
											<xsl:value-of select="//aixm:VisualGlideSlopeIndicatorTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:runwayDirection/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:slopeAngle"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:for-each select="aixm:annotation/aixm:Note">
												<xsl:if test="contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, 'Approach slope angle')">
													<xsl:variable name="annotation_text" select="concat(normalize-space(replace(aixm:translatedNote/aixm:LinguisticNote/aixm:note,'(\r\n?|\n)', ' ')), ' ')"/>
													<xsl:value-of select="substring-before(substring-after($annotation_text, 'Approach slope angle: '), ' ')"/>
												</xsl:if>
											</xsl:for-each>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Minimun eye height over threshold -->
								<xsl:variable name="RD_MEH">
									<xsl:choose>
										<xsl:when test="//aixm:VisualGlideSlopeIndicatorTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:runwayDirection/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:minimumEyeHeightOverThreshold">
											<xsl:value-of select="//aixm:VisualGlideSlopeIndicatorTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:runwayDirection/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:minimumEyeHeightOverThreshold"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:for-each select="aixm:annotation/aixm:Note">
												<xsl:if test="contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, 'Minimum eye height over threshold')">
													<xsl:variable name="annotation_text" select="concat(normalize-space(replace(aixm:translatedNote/aixm:LinguisticNote/aixm:note,'(\r\n?|\n)', ' ')), ' ')"/>
													<xsl:value-of select="substring-before(substring-after($annotation_text, 'Minimum eye height over threshold: '), ' ')"/>
												</xsl:if>
											</xsl:for-each>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Unit of measurement [minimum eye height over threshold] -->
								<xsl:variable name="RD_MEH_uom">
									<xsl:choose>
										<xsl:when test="//aixm:VisualGlideSlopeIndicatorTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:runwayDirection/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:minimumEyeHeightOverThreshold/@uom">
											<xsl:value-of select="//aixm:VisualGlideSlopeIndicatorTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:runwayDirection/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:minimumEyeHeightOverThreshold/@uom"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:for-each select="aixm:annotation/aixm:Note">
												<xsl:if test="contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, 'Unit of measurement [minimum eye height over threshold]')">
													<xsl:variable name="annotation_text" select="concat(normalize-space(replace(aixm:translatedNote/aixm:LinguisticNote/aixm:note,'(\r\n?|\n)', ' ')), ' ')"/>
													<xsl:value-of select="substring-before(substring-after($annotation_text, 'Unit of measurement [minimum eye height over threshold]: '), ' ')"/>
												</xsl:if>
											</xsl:for-each>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Arresting device -->
								<xsl:variable name="RD_arresting_device">
									<xsl:value-of select="//aixm:ArrestingGearTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:runwayDirection/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:engageDevice"/>
								</xsl:variable>
								
								<!-- RVR meteorological equipment -->
								<xsl:variable name="RD_RVR_equipment">
									<xsl:choose>
										<xsl:when test="//aixm:RunwayVisualRangeTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:associatedRunwayDirection/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:readingPosition">
											<xsl:iterate select="//aixm:RunwayVisualRangeTimeSlice[aixm:interpretation = 'BASELINE' and substring-after(aixm:associatedRunwayDirection/@xlink:href, 'urn:uuid:') = $RD_UUID]/aixm:readingPosition">
												<xsl:param name="result" select="' '"/>
												<xsl:on-completion>
													<xsl:variable name="result">
														<xsl:sequence select="$result"/>
													</xsl:variable>
													<xsl:value-of select="concat('Installed at', substring($result, 1, string-length($result)-2))"/>
												</xsl:on-completion>
												<xsl:next-iteration>
													<xsl:with-param name="result" select="if (. = 'TDZ') then concat($result, 'touchdown zone, ') else if (. = 'MID') then concat($result, 'centre of runway, ') else if (. = 'TO') then concat($result, 'takeoff point, ') else concat($result, substring-after(., ':'), ', ')"/>
												</xsl:next-iteration>
											</xsl:iterate>
										</xsl:when>
										<xsl:otherwise>
											<xsl:for-each select="aixm:annotation/aixm:Note">
												<xsl:if test="contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note), 'runway visual range')">
													<xsl:value-of select="substring-after(aixm:translatedNote/aixm:LinguisticNote/aixm:note, ':')"/>
												</xsl:if>
											</xsl:for-each>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Direction of the VFR flight pattern -->
								<xsl:variable name="RD_VFR_pattern_direction">
									<xsl:value-of select="aixm:patternVFR"/>
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
									<xsl:if test="aixm:extension/ead-audit:RunwayDirectionExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate">
										<xsl:value-of select="fcn:get-date(aixm:extension/ead-audit:RunwayDirectionExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Originator -->
								<xsl:variable name="originator">
									<xsl:value-of select="aixm:extension/ead-audit:RunwayDirectionExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
								</xsl:variable>
								
								<tr style="white-space:nowrap;vertical-align:top;">
									<td><xsl:value-of select="if (string-length($RWY_AHP_designator) gt 0) then $RWY_AHP_designator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RWY_AHP_ICAO_code) gt 0) then $RWY_AHP_ICAO_code else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RWY_designator) gt 0) then $RWY_designator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_designator) gt 0) then $RD_designator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_THR_lat) gt 0) then $RD_THR_lat else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_THR_long) gt 0) then $RD_THR_long else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_THR_true_brg) gt 0) then $RD_THR_true_brg else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_THR_mag_brg) gt 0) then $RD_THR_mag_brg else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_TDZ_elevation) gt 0) then $RD_TDZ_elevation else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_VASIS_position) gt 0) then $RD_VASIS_position else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_VASIS_nr_box) gt 0) then $RD_VASIS_nr_box else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_portable_VASIS) gt 0) then $RD_portable_VASIS else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_TDZ_accuracy) gt 0) then $RD_TDZ_accuracy else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_TDZ_accuracy_uom) gt 0) then $RD_TDZ_accuracy_uom else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_taxitime_est) gt 0) then $RD_taxitime_est else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_VASIS_type) gt 0) then $RD_VASIS_type else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_VASIS_position_desc) gt 0) then $RD_VASIS_position_desc else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_app_slope_ang) gt 0) then $RD_app_slope_ang else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_MEH) gt 0) then $RD_MEH else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_MEH_uom) gt 0) then $RD_MEH_uom else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_arresting_device) gt 0) then $RD_arresting_device else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_RVR_equipment) gt 0) then $RD_RVR_equipment else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_VFR_pattern_direction) gt 0) then $RD_VFR_pattern_direction else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($remarks) gt 0) then $remarks else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($commit_date) gt 0) then $commit_date else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RD_UUID) gt 0) then $RD_UUID else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($originator) gt 0) then $originator else '&#160;'"/></td>
								</tr>
								
							</xsl:for-each>
							
						</xsl:for-each>
						
					</tbody>
				</table>
				
			</body>
			
		</html>
		
	</xsl:template>
	
</xsl:transform>