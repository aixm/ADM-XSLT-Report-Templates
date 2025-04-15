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

<!-- for successful transformation, the XML file must contain the following features: aixm:DesignatedPoint, aixm:AirportHeliport, aixm:TouchDownLiftOff, aixm:Runway, aixm:RunwayCentrelinePoint, aixm:RunwayDirection, aixm:messageMetadata -->

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
				
				<table border="0">
					<tbody>
						
						<tr>
							<td><strong>Identification</strong></td>
						</tr>
						<tr>
							<td><strong>Latitude</strong></td>
						</tr>
						<tr>
							<td><strong>Longitude</strong></td>
						</tr>
						<tr>
							<td><strong>TLOF centre Aerodrome / Heliport - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>TLOF centre Aerodrome / Heliport - ICAO Code</strong></td>
						</tr>
						<tr>
							<td><strong>TLOF centre - Designator</strong></td>
						</tr>
						<tr>
							<td><strong>Associated Aerodrome / Heliport - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>Associated Aerodrome / Heliport - ICAO Code</strong></td>
						</tr>
						<tr>
							<td><strong>ARP Aerodrome / Heliport - Latitude</strong></td>
						</tr>
						<tr>
							<td><strong>ARP Aerodrome / Heliport - Longitude</strong></td>
						</tr>
						<tr>
							<td><strong>RWY centre line Aerodrome / Heliport - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>RWY centre line Aerodrome / Heliport - ICAO Code</strong></td>
						</tr>
						<tr>
							<td><strong>RWY centre line - Designator</strong></td>
						</tr>
						<tr>
							<td><strong>RWY centre line - Latitude</strong></td>
						</tr>
						<tr>
							<td><strong>RWY centre line - Longitude</strong></td>
						</tr>
						<tr>
							<td><strong>FATO centre line Aerodrome / Heliport - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>FATO centre line Aerodrome / Heliport - ICAO Code</strong></td>
						</tr>
						<tr>
							<td><strong>FATO centre line TLOF - Designator</strong></td>
						</tr>
						<tr>
							<td><strong>Final approach and take-off area [FATO] - Designator</strong></td>
						</tr>
						<tr>
							<td><strong>FATO centre line - Latitude</strong></td>
						</tr>
						<tr>
							<td><strong>FATO centre line - Longitude</strong></td>
						</tr>
						<tr>
							<td><strong>Datum</strong></td>
						</tr>
						<tr>
							<td><strong>Geographical accuracy</strong></td>
						</tr>
						<tr>
							<td><strong>Unit of measurement [geographical accuracy]</strong></td>
						</tr>
						<tr>
							<td><strong>Cyclic redundancy check</strong></td>
						</tr>
						<tr>
							<td><strong>Type</strong></td>
						</tr>
						<tr>
							<td><strong>Name</strong></td>
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
							<td><strong>FIR Coded identifier</strong></td>
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
						
						<xsl:for-each select="//aixm:DesignatedPoint">
							
							<xsl:sort select="aixm:timeSlice/aixm:DesignatedPointTimeSlice/aixm:designator" order="ascending"/>
							<xsl:variable name="DP_timeSlice" select="aixm:timeSlice/aixm:DesignatedPointTimeSlice"/>
							
							<!-- Identification -->
							<xsl:variable name="DP_designator" select="$DP_timeSlice/aixm:designator"/>
							
							<!-- Latitude -->
							<xsl:variable name="DP_lat">
								<xsl:if test="$DP_timeSlice/aixm:location/aixm:Point/gml:pos">
									<xsl:value-of select="fcn:get-lat-DMS(number(substring-before($DP_timeSlice/aixm:location/aixm:Point/gml:pos, ' ')))"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Longitude -->
							<xsl:variable name="DP_long">
								<xsl:if test="$DP_timeSlice/aixm:location/aixm:Point/gml:pos">
									<xsl:value-of select="fcn:get-long-DMS(number(substring-after($DP_timeSlice/aixm:location/aixm:Point/gml:pos, ' ')))"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- TLOF -->
							<xsl:variable name="DP_aimingPoint_UUID" select="if ($DP_timeSlice/aixm:aimingPoint/@xlink:href) then substring-after($DP_timeSlice/aixm:aimingPoint/@xlink:href, 'urn:uuid:') else ''"/>
							<xsl:variable name="TLOF_AHP_link">
								<xsl:if test="//aixm:TouchDownLiftOff/aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice/aixm:associatedAirportHeliport/@xlink:href">
									<xsl:value-of select="substring-after(//aixm:TouchDownLiftOff[gml:identifier = $DP_aimingPoint_UUID]/aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice/aixm:associatedAirportHeliport/@xlink:href, 'urn:uuid:')"/>
								</xsl:if>
							</xsl:variable>
							<!-- TLOF centre Aerodrome / Heliport - Identification -->
							<xsl:variable name="DP_TLOF_AHP_designator">
								<xsl:value-of select="//aixm:AirportHeliport[gml:identifier = $TLOF_AHP_link]/aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:designator"/>
							</xsl:variable>
							<!-- TLOF centre Aerodrome / Heliport - ICAO Code -->
							<xsl:variable name="DP_TLOF_AHP_ICAO_code">
								<xsl:value-of select="//aixm:AirportHeliport[gml:identifier = $TLOF_AHP_link]/aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:locationIndicatorICAO"/>
							</xsl:variable>
							<!-- TLOF centre - Designator -->
							<xsl:variable name="DP_TLOF_designator">
								<xsl:value-of select="//aixm:TouchDownLiftOff[gml:identifier = $DP_aimingPoint_UUID]/aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice/aixm:designator"/>
							</xsl:variable>
							
							<!-- Associated Aerodrome / Heliport -->
							<xsl:variable name="DP_airportHeliport_UUID" select="if ($DP_timeSlice/aixm:airportHeliport/@xlink:href) then substring-after($DP_timeSlice/aixm:airportHeliport/@xlink:href, 'urn:uuid:') else ''"/>
							<xsl:variable name="DP_AHP_timeSlice" select="//aixm:AirportHeliport[gml:identifier = $DP_airportHeliport_UUID]/aixm:timeSlice/aixm:AirportHeliportTimeSlice"/>
							<!-- Associated Aerodrome / Heliport - Identification -->
							<xsl:variable name="DP_AHP_ICAO_designator" select="$DP_AHP_timeSlice/aixm:designator"/>
							<!-- Associated Aerodrome / Heliport - ICAO Code -->
							<xsl:variable name="DP_AHP_ICAO_code" select="$DP_AHP_timeSlice/aixm:locationIndicatorICAO"/>
							<!-- ARP Aerodrome / Heliport - Latitude -->
							<xsl:variable name="DP_AHP_ARP_lat" select="if ($DP_AHP_timeSlice/aixm:ARP/aixm:ElevatedPoint/gml:pos) then fcn:get-lat-DMS(number(substring-before($DP_AHP_timeSlice/aixm:ARP/aixm:ElevatedPoint/gml:pos, ' '))) else ''"/>
							<!-- ARP Aerodrome / Heliport - Longitude -->
							<xsl:variable name="DP_AHP_ARP_long" select="if ($DP_AHP_timeSlice/aixm:ARP/aixm:ElevatedPoint/gml:pos) then fcn:get-long-DMS(number(substring-after($DP_AHP_timeSlice/aixm:ARP/aixm:ElevatedPoint/gml:pos, ' '))) else ''"/>
							
							<!-- RWY/FATO -->
							<xsl:variable name="DP_runwayPoint_UUID" select="substring-after($DP_timeSlice/aixm:runwayPoint/@xlink:href, 'urn:uuid:')"/>
							<xsl:variable name="DP_RCP_timeSlice" select="//aixm:RunwayCentrelinePoint[gml:identifier = $DP_runwayPoint_UUID]/aixm:timeSlice/aixm:RunwayCentrelinePointTimeSlice"/>
							<xsl:variable name="DP_RWYdir_UUID" select="substring-after($DP_RCP_timeSlice/aixm:onRunway/@xlink:href, 'urn:uuid:')"/>
							<xsl:variable name="DP_RWYdir_timeSlice" select="//aixm:RunwayDirection[gml:identifier = $DP_RWYdir_UUID]/aixm:timeSlice/aixm:RunwayDirectionTimeSlice"/>
							<xsl:variable name="DP_RWY_type" select="//aixm:Runway[gml:identifier = substring-after($DP_RWYdir_timeSlice/aixm:usedRunway/@xlink:href, 'urn:uuid:')]/*/*/aixm:type"/>
							<!-- RWY centre line Aerodrome / Heliport - Identification -->
							<xsl:variable name="DP_RWY_AHP_designator">
								<xsl:if test="$DP_RWY_type = 'RWY'">
									<xsl:value-of select="//aixm:AirportHeliport[gml:identifier = substring-after(//aixm:Runway[gml:identifier = substring-after($DP_RWYdir_timeSlice/aixm:usedRunway/@xlink:href, 'urn:uuid:')]/*/*/aixm:associatedAirportHeliport/@xlink:href, 'urn:uuid:')]/*/*/aixm:designator"/>
								</xsl:if>
							</xsl:variable>
							<!-- RWY centre line Aerodrome / Heliport - ICAO Code -->
							<xsl:variable name="DP_RWY_AHP_ICAO_code">
								<xsl:if test="$DP_RWY_type = 'RWY'">
									<xsl:value-of select="//aixm:AirportHeliport[gml:identifier = substring-after(//aixm:Runway[gml:identifier = substring-after($DP_RWYdir_timeSlice/aixm:usedRunway/@xlink:href, 'urn:uuid:')]/*/*/aixm:associatedAirportHeliport/@xlink:href, 'urn:uuid:')]/*/*/aixm:locationIndicatorICAO"/>
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
									<xsl:value-of select="fcn:get-lat-DMS(number(substring-before($DP_RCP_timeSlice/aixm:location/aixm:ElevatedPoint/gml:pos, ' ')))"/>
								</xsl:if>
							</xsl:variable>
							<!-- RWY centre line - Longitude -->
							<xsl:variable name="DP_RWY_RCP_long">
								<xsl:if test="$DP_RWY_type = 'RWY'">
									<xsl:value-of select="fcn:get-long-DMS(number(substring-after($DP_RCP_timeSlice/aixm:location/aixm:ElevatedPoint/gml:pos, ' ')))"/>
								</xsl:if>
							</xsl:variable>
							<!-- FATO centre line Aerodrome / Heliport - Identification -->
							<xsl:variable name="DP_FATO_AHP_designator">
								<xsl:if test="$DP_RWY_type = 'FATO'">
									<xsl:value-of select="//aixm:AirportHeliport[gml:identifier = substring-after(//aixm:Runway[gml:identifier = substring-after($DP_RWYdir_timeSlice/aixm:usedRunway/@xlink:href, 'urn:uuid:')]/*/*/aixm:associatedAirportHeliport/@xlink:href, 'urn:uuid:')]/aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:designator"/>
								</xsl:if>
							</xsl:variable>
							<!-- FATO centre line Aerodrome / Heliport - ICAO Code -->
							<xsl:variable name="DP_FATO_AHP_ICAO_code">
								<xsl:if test="$DP_RWY_type = 'FATO'">
									<xsl:value-of select="//aixm:AirportHeliport[gml:identifier = substring-after(//aixm:Runway[gml:identifier = substring-after($DP_RWYdir_timeSlice/aixm:usedRunway/@xlink:href, 'urn:uuid:')]/*/*/aixm:associatedAirportHeliport/@xlink:href, 'urn:uuid:')]/aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:locationIndicatorICAO"/>
								</xsl:if>
							</xsl:variable>
							<!-- FATO centre line TLOF - Designator -->
							<xsl:variable name="DP_FATO_TLOF_designator">
								<xsl:if test="$DP_RWY_type = 'FATO'">
									<xsl:value-of select="//aixm:TouchDownLiftOff/aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice[substring-after(aixm:approachTakeOffArea/@xlink:href, 'urn:uuid:') = substring-after(//$DP_RWYdir_timeSlice/aixm:usedRunway/@xlink:href, 'urn:uuid:')]/aixm:designator"/>
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
									<xsl:value-of select="fcn:get-lat-DMS(number(substring-before($DP_RCP_timeSlice/aixm:location/aixm:ElevatedPoint/gml:pos, ' ')))"/>
								</xsl:if>
							</xsl:variable>
							<!-- FATO centre line - Longitude -->
							<xsl:variable name="DP_FATO_RCP_long">
								<xsl:if test="$DP_RWY_type = 'FATO'">
									<xsl:value-of select="fcn:get-long-DMS(number(substring-after($DP_RCP_timeSlice/aixm:location/aixm:ElevatedPoint/gml:pos, ' ')))"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Datum -->
							<xsl:variable name="DP_datum">
								<xsl:if test="$DP_timeSlice/aixm:location/aixm:Point/@srsName">
									<xsl:value-of select="concat(substring($DP_timeSlice/aixm:location/aixm:Point/@srsName, 17,5), substring($DP_timeSlice/aixm:location/aixm:Point/@srsName, 23,4))"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Geographical accuracy -->
							<xsl:variable name="DP_geo_accuracy">
								<xsl:value-of select="$DP_timeSlice/aixm:location/aixm:Point/aixm:horizontalAccuracy"/>
							</xsl:variable>
							
							<!-- Unit of measurement [geographical accuracy] -->
							<xsl:variable name="DP_geo_acc_uom">
								<xsl:value-of select="$DP_timeSlice/aixm:location/aixm:Point/aixm:horizontalAccuracy/@uom"/>
							</xsl:variable>
							
							<!-- Cyclic redundancy check -->
							<xsl:variable name="DP_CRC">
								<xsl:if test="$DP_timeSlice/aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note, 'CRC:')]/aixm:note">
									<xsl:value-of select="fcn:get-last-word($DP_timeSlice/aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note, 'CRC:')]/aixm:note)"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Type -->
							<xsl:variable name="DP_type">
								<xsl:value-of select="$DP_timeSlice/aixm:type"/>
							</xsl:variable>
							
							<!-- Name -->
							<xsl:variable name="DP_name">
								<xsl:value-of select="$DP_timeSlice/aixm:name"/>
							</xsl:variable>
							
							<!-- Remarks -->
							<xsl:variable name="DP_remarks">
								<xsl:variable name="dataset_creation_date" select="../../aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
								<xsl:if test="string-length($dataset_creation_date) gt 0">
									<xsl:value-of select="concat('Current time: ', $dataset_creation_date)"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Effective date -->
							<xsl:variable name="effective_date">
								<xsl:if test="$DP_timeSlice/gml:validTime/gml:TimePeriod/gml:beginPosition">
									<xsl:value-of select="fcn:get-date($DP_timeSlice/gml:validTime/gml:TimePeriod/gml:beginPosition)"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Committed on -->
							<xsl:variable name="commit_date">
								<xsl:if test="$DP_timeSlice/aixm:extension/ead-audit:DesignatedPointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate">
									<xsl:value-of select="fcn:get-date($DP_timeSlice/aixm:extension/ead-audit:DesignatedPointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Internal UID (master) -->
							<xsl:variable name="DP_UUID">
								<xsl:value-of select="gml:identifier"/>
							</xsl:variable>
							
							<!-- FIR - Coded identifier -->
							<xsl:variable name="FIR_designator">
								
								<!-- work in progress -->
								
							</xsl:variable>
							
							<!-- Originator -->
							<xsl:variable name="originator">
								<xsl:value-of select="$DP_timeSlice/aixm:extension/ead-audit:DesignatedPointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
							</xsl:variable>
							
							<tr>
								<td><xsl:value-of select="if (string-length($DP_designator) gt 0) then $DP_designator else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_lat) gt 0) then $DP_lat else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_long) gt 0) then $DP_long else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_TLOF_AHP_designator) gt 0) then $DP_TLOF_AHP_designator else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_TLOF_AHP_ICAO_code) gt 0) then $DP_TLOF_AHP_ICAO_code else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_TLOF_designator) gt 0) then $DP_TLOF_designator else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_AHP_ICAO_designator) gt 0) then $DP_AHP_ICAO_designator else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_AHP_ICAO_code) gt 0) then $DP_AHP_ICAO_code else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_AHP_ARP_lat) gt 0) then $DP_AHP_ARP_lat else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_AHP_ARP_long) gt 0) then $DP_AHP_ARP_long else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_RWY_AHP_designator) gt 0) then $DP_RWY_AHP_designator else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_RWY_AHP_ICAO_code) gt 0) then $DP_RWY_AHP_ICAO_code else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_RWY_designator) gt 0) then $DP_RWY_designator else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_RWY_RCP_lat) gt 0) then $DP_RWY_RCP_lat else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_RWY_RCP_long) gt 0) then $DP_RWY_RCP_long else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_FATO_AHP_designator) gt 0) then $DP_FATO_AHP_designator else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_FATO_AHP_ICAO_code) gt 0) then $DP_FATO_AHP_ICAO_code else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_FATO_TLOF_designator) gt 0) then $DP_FATO_TLOF_designator else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_FATO_designator) gt 0) then $DP_FATO_designator else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_FATO_RCP_lat) gt 0) then $DP_FATO_RCP_lat else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_FATO_RCP_long) gt 0) then $DP_FATO_RCP_long else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_datum) gt 0) then $DP_datum else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_geo_accuracy) gt 0) then $DP_geo_accuracy else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_geo_acc_uom) gt 0) then $DP_geo_acc_uom else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_CRC) gt 0) then $DP_CRC else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_type) gt 0) then $DP_type else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_name) gt 0) then $DP_name else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_remarks) gt 0) then $DP_remarks else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($commit_date) gt 0) then $commit_date else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DP_UUID) gt 0) then $DP_UUID else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($FIR_designator) gt 0) then $FIR_designator else '&#160;'"/></td>
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