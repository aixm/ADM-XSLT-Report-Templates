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
	featureTypes:	aixm:DesignatedPoint aixm:Airspace
	includeReferencedFeaturesLevel:	"3"
	featureOccurrence:	"aixm:Airspace.aixm:type EQUALS 'FIR'"
	permanentBaseline:	true
	spatialFilteringBy:	Airspace
	spatialAreaUUID:	*select FIR airspace*
	spatialOperator:	"Within"
	spatialValueOperator:	"OR"
	dataScope:	ReleasedData
	AIXMversion:	5.1.1
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
				<title>SDO Reporting - Designated Point with FIR</title>
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
					<b>Designated Point with FIR</b>
				</center>
				<hr/>
				
				<table border="0" style="border-spacing: 8px 4px">
					<tbody>
						
						<tr style="white-space:nowrap">
							<td><strong>Identification</strong></td>
							<td><strong>Latitude</strong></td>
							<td><strong>Longitude</strong></td>
							<td><strong>TLOF centre Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Identification</strong></td>
							<td><strong>TLOF centre Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- ICAO Code</strong></td>
							<td><strong>TLOF centre<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Designator</strong></td>
							<td><strong>Associated Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Identification</strong></td>
							<td><strong>Associated Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- ICAO Code</strong></td>
							<td><strong>ARP Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Latitude</strong></td>
							<td><strong>ARP Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Longitude</strong></td>
							<td><strong>RWY centre line Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Identification</strong></td>
							<td><strong>RWY centre line Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- ICAO Code</strong></td>
							<td><strong>RWY centre line<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Designator</strong></td>
							<td><strong>RWY centre line<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Latitude</strong></td>
							<td><strong>RWY centre line<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Longitude</strong></td>
							<td><strong>FATO centre line Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Identification</strong></td>
							<td><strong>FATO centre line Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- ICAO Code</strong></td>
							<td><strong>FATO centre line TLOF<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Designator</strong></td>
							<td><strong>Final approach and take-off area [FATO]<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Designator</strong></td>
							<td><strong>FATO centre line<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Latitude</strong></td>
							<td><strong>FATO centre line<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Longitude</strong></td>
							<td><strong>Datum</strong></td>
							<td><strong>Geographical accuracy</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[geographical accuracy]</strong></td>
							<td><strong>Cyclic redundancy<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>check</strong></td>
							<td><strong>Type</strong></td>
							<td><strong>Name</strong></td>
							<td><strong>Remarks</strong></td>
							<td><strong>Effective date</strong></td>
							<td><strong>Committed on</strong></td>
							<td><strong>Internal UID (master)</strong></td>
							<td><strong>FIR Coded identifier</strong></td>
							<td><strong>Originator</strong></td>
						</tr>
						
						<xsl:for-each select="//aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE']">
							
							<xsl:sort select="aixm:designator" order="ascending"/>
							
							<!-- Identification -->
							<xsl:variable name="DP_designator" select="aixm:designator"/>
							
							<!-- Latitude -->
							<xsl:variable name="DP_lat">
								<xsl:if test="aixm:location/aixm:Point/gml:pos">
									<xsl:value-of select="fcn:get-lat-DMS(number(substring-before(aixm:location/aixm:Point/gml:pos, ' ')))"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Longitude -->
							<xsl:variable name="DP_long">
								<xsl:if test="aixm:location/aixm:Point/gml:pos">
									<xsl:value-of select="fcn:get-long-DMS(number(substring-after(aixm:location/aixm:Point/gml:pos, ' ')))"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- TLOF -->
							<xsl:variable name="DP_aimingPoint_UUID" select="if (aixm:aimingPoint/@xlink:href) then substring-after(aixm:aimingPoint/@xlink:href, 'urn:uuid:') else ''"/>
							<xsl:variable name="TLOF_AHP_link">
								<xsl:if test="//aixm:TouchDownLiftOff/aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice[aixm:interpretation = 'BASELINE']/aixm:associatedAirportHeliport/@xlink:href">
									<xsl:value-of select="substring-after(//aixm:TouchDownLiftOff[gml:identifier = $DP_aimingPoint_UUID]/aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice[aixm:interpretation = 'BASELINE']/aixm:associatedAirportHeliport/@xlink:href, 'urn:uuid:')"/>
								</xsl:if>
							</xsl:variable>
							<!-- TLOF centre Aerodrome / Heliport - Identification -->
							<xsl:variable name="DP_TLOF_AHP_designator">
								<xsl:value-of select="//aixm:AirportHeliport[gml:identifier = $TLOF_AHP_link]/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']/aixm:designator"/>
							</xsl:variable>
							<!-- TLOF centre Aerodrome / Heliport - ICAO Code -->
							<xsl:variable name="DP_TLOF_AHP_ICAO_code">
								<xsl:value-of select="//aixm:AirportHeliport[gml:identifier = $TLOF_AHP_link]/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']/aixm:locationIndicatorICAO"/>
							</xsl:variable>
							<!-- TLOF centre - Designator -->
							<xsl:variable name="DP_TLOF_designator">
								<xsl:value-of select="//aixm:TouchDownLiftOff[gml:identifier = $DP_aimingPoint_UUID]/aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice[aixm:interpretation = 'BASELINE']/aixm:designator"/>
							</xsl:variable>
							
							<!-- Associated Aerodrome / Heliport -->
							<xsl:variable name="DP_airportHeliport_UUID" select="if (aixm:airportHeliport/@xlink:href) then substring-after(aixm:airportHeliport/@xlink:href, 'urn:uuid:') else ''"/>
							<xsl:variable name="DP_AHP_timeSlice" select="//aixm:AirportHeliport[gml:identifier = $DP_airportHeliport_UUID]/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']"/>
							<!-- Associated Aerodrome / Heliport - Identification -->
							<xsl:variable name="DP_AHP_ICAO_designator" select="$DP_AHP_timeSlice/aixm:designator"/>
							<!-- Associated Aerodrome / Heliport - ICAO Code -->
							<xsl:variable name="DP_AHP_ICAO_code" select="$DP_AHP_timeSlice/aixm:locationIndicatorICAO"/>
							<!-- ARP Aerodrome / Heliport - Latitude -->
							<xsl:variable name="DP_AHP_ARP_lat" select="if ($DP_AHP_timeSlice/aixm:ARP/aixm:ElevatedPoint/gml:pos) then fcn:get-lat-DMS(number(substring-before($DP_AHP_timeSlice/aixm:ARP/aixm:ElevatedPoint/gml:pos[1], ' '))) else ''"/>
							<!-- ARP Aerodrome / Heliport - Longitude -->
							<xsl:variable name="DP_AHP_ARP_long" select="if ($DP_AHP_timeSlice/aixm:ARP/aixm:ElevatedPoint/gml:pos) then fcn:get-long-DMS(number(substring-after($DP_AHP_timeSlice/aixm:ARP/aixm:ElevatedPoint/gml:pos[1], ' '))) else ''"/>
							
							<!-- RWY/FATO -->
							<xsl:variable name="DP_runwayPoint_UUID" select="substring-after(aixm:runwayPoint/@xlink:href, 'urn:uuid:')"/>
							<xsl:variable name="DP_RCP_timeSlice" select="//aixm:RunwayCentrelinePoint[gml:identifier = $DP_runwayPoint_UUID]/aixm:timeSlice/aixm:RunwayCentrelinePointTimeSlice[aixm:interpretation = 'BASELINE']"/>
							<xsl:variable name="DP_RWYdir_UUID" select="substring-after($DP_RCP_timeSlice/aixm:onRunway/@xlink:href, 'urn:uuid:')"/>
							<xsl:variable name="DP_RWYdir_timeSlice" select="//aixm:RunwayDirection[gml:identifier = $DP_RWYdir_UUID]/aixm:timeSlice/aixm:RunwayDirectionTimeSlice[aixm:interpretation = 'BASELINE']"/>
							<xsl:variable name="DP_RWY_type" select="//aixm:Runway[gml:identifier = substring-after($DP_RWYdir_timeSlice/aixm:usedRunway/@xlink:href, 'urn:uuid:')]/aixm:timeSlice/aixm:RunwayTimeSlice[aixm:interpretation = 'BASELINE']/aixm:type"/>
							<!-- RWY centre line Aerodrome / Heliport - Identification -->
							<xsl:variable name="DP_RWY_AHP_designator">
								<xsl:if test="$DP_RWY_type = 'RWY'">
									<xsl:value-of select="//aixm:AirportHeliport[gml:identifier = substring-after(//aixm:Runway[gml:identifier = substring-after($DP_RWYdir_timeSlice/aixm:usedRunway/@xlink:href, 'urn:uuid:')]/aixm:timeSlice/aixm:RunwayTimeSlice[aixm:interpretation = 'BASELINE']/aixm:associatedAirportHeliport/@xlink:href, 'urn:uuid:')]/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']/aixm:designator"/>
								</xsl:if>
							</xsl:variable>
							<!-- RWY centre line Aerodrome / Heliport - ICAO Code -->
							<xsl:variable name="DP_RWY_AHP_ICAO_code">
								<xsl:if test="$DP_RWY_type = 'RWY'">
									<xsl:value-of select="//aixm:AirportHeliport[gml:identifier = substring-after(//aixm:Runway[gml:identifier = substring-after($DP_RWYdir_timeSlice/aixm:usedRunway/@xlink:href, 'urn:uuid:')]/aixm:timeSlice/aixm:RunwayTimeSlice[aixm:interpretation = 'BASELINE']/aixm:associatedAirportHeliport/@xlink:href, 'urn:uuid:')]/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']/aixm:locationIndicatorICAO"/>
								</xsl:if>
							</xsl:variable>
							<!-- RWY centre line - Designator -->
							<xsl:variable name="DP_RWY_designator">
								<xsl:if test="$DP_RWY_type = 'RWY'">
									<xsl:value-of select="$DP_RCP_timeSlice/aixm:designator"/>
								</xsl:if>
							</xsl:variable>
							<!-- RWY centre line - Latitude -->
							<xsl:variable name="DP_RWY_RCP_lat">
								<xsl:if test="$DP_RWY_type = 'RWY'">
									<xsl:value-of select="if ($DP_RCP_timeSlice/aixm:location/aixm:ElevatedPoint/gml:pos) then fcn:get-lat-DMS(number(substring-before($DP_RCP_timeSlice/aixm:location/aixm:ElevatedPoint/gml:pos[1], ' '))) else ''"/>
								</xsl:if>
							</xsl:variable>
							<!-- RWY centre line - Longitude -->
							<xsl:variable name="DP_RWY_RCP_long">
								<xsl:if test="$DP_RWY_type = 'RWY'">
									<xsl:value-of select="if ($DP_RCP_timeSlice/aixm:location/aixm:ElevatedPoint/gml:pos) then fcn:get-long-DMS(number(substring-after($DP_RCP_timeSlice/aixm:location/aixm:ElevatedPoint/gml:pos[1], ' '))) else ''"/>
								</xsl:if>
							</xsl:variable>
							<!-- FATO centre line Aerodrome / Heliport - Identification -->
							<xsl:variable name="DP_FATO_AHP_designator">
								<xsl:if test="$DP_RWY_type = 'FATO'">
									<xsl:value-of select="//aixm:AirportHeliport[gml:identifier = substring-after(//aixm:Runway[gml:identifier = substring-after($DP_RWYdir_timeSlice/aixm:usedRunway/@xlink:href, 'urn:uuid:')]/aixm:timeSlice/aixm:RunwayTimeSlice[aixm:interpretation = 'BASELINE']/aixm:associatedAirportHeliport/@xlink:href, 'urn:uuid:')]/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']/aixm:designator"/>
								</xsl:if>
							</xsl:variable>
							<!-- FATO centre line Aerodrome / Heliport - ICAO Code -->
							<xsl:variable name="DP_FATO_AHP_ICAO_code">
								<xsl:if test="$DP_RWY_type = 'FATO'">
									<xsl:value-of select="//aixm:AirportHeliport[gml:identifier = substring-after(//aixm:Runway[gml:identifier = substring-after($DP_RWYdir_timeSlice/aixm:usedRunway/@xlink:href, 'urn:uuid:')]/aixm:timeSlice/aixm:RunwayTimeSlice[aixm:interpretation = 'BASELINE']/aixm:associatedAirportHeliport/@xlink:href, 'urn:uuid:')]/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']/aixm:locationIndicatorICAO"/>
								</xsl:if>
							</xsl:variable>
							<!-- FATO centre line TLOF - Designator -->
							<xsl:variable name="DP_FATO_TLOF_designator">
								<xsl:if test="$DP_RWY_type = 'FATO'">
									<xsl:value-of select="//aixm:TouchDownLiftOff/aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice[substring-after(aixm:approachTakeOffArea/@xlink:href, 'urn:uuid:') = substring-after(//$DP_RWYdir_timeSlice/aixm:usedRunway/@xlink:href, 'urn:uuid:') and aixm:interpretation = 'BASELINE']/aixm:designator"/>
								</xsl:if>
							</xsl:variable>
							<!-- Final approach and take-off area [FATO] - Designator -->
							<xsl:variable name="DP_FATO_designator">
								<xsl:if test="$DP_RWY_type = 'FATO'">
									<xsl:value-of select="$DP_RCP_timeSlice/aixm:designator"/>
								</xsl:if>
							</xsl:variable>
							<!-- FATO centre line - Latitude -->
							<xsl:variable name="DP_FATO_RCP_lat">
								<xsl:if test="$DP_RWY_type = 'FATO'">
									<xsl:value-of select="if ($DP_RCP_timeSlice/aixm:location/aixm:ElevatedPoint/gml:pos) then fcn:get-lat-DMS(number(substring-before($DP_RCP_timeSlice/aixm:location/aixm:ElevatedPoint/gml:pos[1], ' '))) else ''"/>
								</xsl:if>
							</xsl:variable>
							<!-- FATO centre line - Longitude -->
							<xsl:variable name="DP_FATO_RCP_long">
								<xsl:if test="$DP_RWY_type = 'FATO'">
									<xsl:value-of select="if ($DP_RCP_timeSlice/aixm:location/aixm:ElevatedPoint/gml:pos) then fcn:get-long-DMS(number(substring-after($DP_RCP_timeSlice/aixm:location/aixm:ElevatedPoint/gml:pos[1], ' '))) else ''"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Datum -->
							<xsl:variable name="DP_datum">
								<xsl:if test="aixm:location/aixm:Point/@srsName">
									<xsl:value-of select="concat(substring(aixm:location/aixm:Point/@srsName, 17,5), substring(aixm:location/aixm:Point/@srsName, 23,4))"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Geographical accuracy -->
							<xsl:variable name="DP_geo_accuracy">
								<xsl:value-of select="aixm:location/aixm:Point/aixm:horizontalAccuracy"/>
							</xsl:variable>
							
							<!-- Unit of measurement [geographical accuracy] -->
							<xsl:variable name="DP_geo_acc_uom">
								<xsl:value-of select="aixm:location/aixm:Point/aixm:horizontalAccuracy/@uom"/>
							</xsl:variable>
							
							<!-- Cyclic redundancy check -->
							<xsl:variable name="DP_CRC">
								<xsl:if test="aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note, 'CRC:')]/aixm:note[not(@lang) or @lang=('en','eng')]">
									<xsl:value-of select="fcn:get-last-word(aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note, 'CRC:')]/aixm:note[not(@lang) or @lang=('en','eng')])"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Type -->
							<xsl:variable name="DP_type">
								<xsl:value-of select="aixm:type"/>
							</xsl:variable>
							
							<!-- Name -->
							<xsl:variable name="DP_name">
								<xsl:value-of select="aixm:name"/>
							</xsl:variable>
							
							<!-- Remarks -->
							<xsl:variable name="DP_remarks">
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
								<xsl:if test="aixm:extension/ead-audit:DesignatedPointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate">
									<xsl:value-of select="fcn:get-date(aixm:extension/ead-audit:DesignatedPointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Internal UID (master) -->
							<xsl:variable name="DP_UUID">
								<xsl:value-of select="../../gml:identifier"/>
							</xsl:variable>
							
							<!-- FIR - Coded identifier -->
							<xsl:variable name="FIR_designator">
								<xsl:if test="count(//aixm:AirspaceTimeSlice[aixm:type = 'FIR']) = 1">
									<xsl:value-of select="//aixm:AirspaceTimeSlice[aixm:type = 'FIR']/aixm:designator"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Originator -->
							<xsl:variable name="originator">
								<xsl:value-of select="aixm:extension/ead-audit:DesignatedPointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
							</xsl:variable>
							
							<tr style="white-space:nowrap;">
								<td><xsl:value-of select="if (string-length($DP_designator) gt 0) then $DP_designator else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_lat) gt 0) then $DP_lat else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_long) gt 0) then $DP_long else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_TLOF_AHP_designator) gt 0) then $DP_TLOF_AHP_designator else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_TLOF_AHP_ICAO_code) gt 0) then $DP_TLOF_AHP_ICAO_code else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_TLOF_designator) gt 0) then $DP_TLOF_designator else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_AHP_ICAO_designator) gt 0) then $DP_AHP_ICAO_designator else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_AHP_ICAO_code) gt 0) then $DP_AHP_ICAO_code else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_AHP_ARP_lat) gt 0) then $DP_AHP_ARP_lat else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_AHP_ARP_long) gt 0) then $DP_AHP_ARP_long else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_RWY_AHP_designator) gt 0) then $DP_RWY_AHP_designator else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_RWY_AHP_ICAO_code) gt 0) then $DP_RWY_AHP_ICAO_code else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_RWY_designator) gt 0) then $DP_RWY_designator else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_RWY_RCP_lat) gt 0) then $DP_RWY_RCP_lat else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_RWY_RCP_long) gt 0) then $DP_RWY_RCP_long else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_FATO_AHP_designator) gt 0) then $DP_FATO_AHP_designator else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_FATO_AHP_ICAO_code) gt 0) then $DP_FATO_AHP_ICAO_code else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_FATO_TLOF_designator) gt 0) then $DP_FATO_TLOF_designator else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_FATO_designator) gt 0) then $DP_FATO_designator else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_FATO_RCP_lat) gt 0) then $DP_FATO_RCP_lat else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_FATO_RCP_long) gt 0) then $DP_FATO_RCP_long else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_datum) gt 0) then $DP_datum else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_geo_accuracy) gt 0) then $DP_geo_accuracy else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_geo_acc_uom) gt 0) then $DP_geo_acc_uom else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_CRC) gt 0) then $DP_CRC else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_type) gt 0) then $DP_type else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_name) gt 0) then $DP_name else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_remarks) gt 0) then $DP_remarks else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($commit_date) gt 0) then $commit_date else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($DP_UUID) gt 0) then $DP_UUID else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($FIR_designator) gt 0) then $FIR_designator else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($originator) gt 0) then $originator else '&#160;'"/></td>
							</tr>
							
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
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'dataType: '), ',')"/>
				</xsl:variable>
				
				<!-- CustomizationAirspaceCircleArcToPolygon -->
				<xsl:variable name="arc_to_polygon">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'CustomizationAirspaceCircleArcToPolygon: '), ',')"/>
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
						<td><font size="-1">Identification</font></td>
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