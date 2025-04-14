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

<!-- for successful transformation, the XML file must contain the following features: aixm:AirportHeliport, aixm:OrganisationAuthority, aixm:Airspace, aixm:GeoBorder, aixm:messageMetadata-->

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
		<xsl:param name="text" as="xs:string"/>
		<xsl:variable name="words" select="tokenize(normalize-space($text), '\s+')"/>
		<xsl:sequence select="$words[last()]"/>
	</xsl:function>
	
	<xsl:function name="fcn:get-date" as="xs:string">
		<xsl:param name="text" as="xs:string"/>
		<xsl:variable name="date-time" select="$text"/>
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
				<title>SDO Reporting - AD / HP with FIR</title>
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
					<b>AD / HP with FIR</b>
				</center>
				<hr/>
				
				<table border="0" style="border-spacing: 8px 2px">
					<tbody>
						
						<tr style="white-space:nowrap">
							<td><strong>Identification</strong></td>
							<td><strong>Responsible State or international organisaton<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Name</strong></td>
							<td><strong>Name</strong></td>
							<td><strong>ICAO Code</strong></td>
							<td><strong>IATA Code</strong></td>
							<td><strong>Type</strong></td>
							<td><strong>(d)Operation<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>code</strong></td>
							<td><strong>(d)National<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>traffic</strong></td>
							<td><strong>(d)International<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>traffic</strong></td>
							<td><strong>(d)Scheduled<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>flight</strong></td>
							<td><strong>(d)Non scheduled<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>flight</strong></td>
							<td><strong>(d)Private<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>flight</strong></td>
							<td><strong>(d)Observe<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>VFR</strong></td>
							<td><strong>(d)Observe<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>IFR</strong></td>
							<td><strong>Reference point description</strong></td>
							<td><strong>Latitude</strong></td>
							<td><strong>Longitude</strong></td>
							<td><strong>Datum</strong></td>
							<td><strong>Geographical<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>accuracy</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[geographical accuracy]</strong></td>
							<td><strong>Elevation</strong></td>
							<td><strong>Elevation<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>accuracy</strong></td>
							<td><strong>Geoid<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>undulation</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[vertical distance]</strong></td>
							<td><strong>Cyclic redundancy<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>check</strong></td>
							<td><strong>Vertical Datum</strong></td>
							<td><strong>Served city</strong></td>
							<td><strong>Site description</strong></td>
							<td><strong>Magnetic variation</strong></td>
							<td><strong>Magnetic variation date</strong></td>
							<td><strong>Annual rate of change<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>of magnetic variation</strong></td>
							<td><strong>Reference<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>temperature</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[temperature]</strong></td>
							<td><strong>Organisation in charge</strong></td>
							<td><strong>Altimeter check location description</strong></td>
							<td><strong>Secondary power supply description</strong></td>
							<td><strong>Wind direction indicator description</strong></td>
							<td><strong>Landing direction indicator description</strong></td>
							<td><strong>Transition<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>altitude</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[transition altitude]</strong></td>
							<td><strong>Working hours</strong></td>
							<td><strong>Remark to working hours</strong></td>
							<td><strong>Remarks</strong></td>
							<td><strong>Committed on</strong></td>
							<td><strong>Internal UID (master)</strong></td>
							<td><strong>FIR<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Coded identifier</strong></td>
							<td><strong>Originator</strong></td>
							<td><strong>Effective date</strong></td>
							<td><strong>System Remark</strong></td>
						</tr>
						
						<xsl:for-each select="//aixm:AirportHeliport">
							
							<xsl:sort select="aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:designator" order="ascending"/>
							<xsl:variable name="AHP_timeSlice" select="aixm:timeSlice/aixm:AirportHeliportTimeSlice"/>
							
							<!-- Identification -->
							<xsl:variable name="AHP_designator" select="$AHP_timeSlice/aixm:designator"/>
							
							<!-- Responsible State or international organisaton - Name -->
							<xsl:variable name="Resp_org_state_UUID" select="substring-after($AHP_timeSlice/aixm:responsibleOrganisation/aixm:AirportHeliportResponsibilityOrganisation/aixm:theOrganisationAuthority/@xlink:href, 'urn:uuid:')"/>
							<xsl:variable name="AHP_resp_org_state_name" select="//aixm:OrganisationAuthority[gml:identifier = $Resp_org_state_UUID]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice/aixm:name"/>
							
							<!-- Name -->
							<xsl:variable name="AHP_name" select="$AHP_timeSlice/aixm:name"/>
							
							<!-- ICAO Code -->
							<xsl:variable name="AHP_ICAO_code" select="$AHP_timeSlice/aixm:locationIndicatorICAO"/>
							
							<!-- IATA Code -->
							<xsl:variable name="AHP_IATA_code" select="$AHP_timeSlice/aixm:designatorIATA"/>
							
							<!-- Type -->
							<xsl:variable name="AHP_type" select="$AHP_timeSlice/aixm:type"/>
							
							<!-- (d)Operation code -->
							<xsl:variable name="AHP_control_type" select="$AHP_timeSlice/aixm:controlType"/>
							
							<xsl:variable name="AHP_normal_usage" select="$AHP_timeSlice/aixm:availability/aixm:AirportHeliportAvailability[aixm:operationalStatus='NORMAL']/aixm:usage/aixm:AirportHeliportUsage"/>
							
							<!-- (d)National traffic -->
							<xsl:variable name="AHP_nat_traffic">
								<xsl:choose>
									<xsl:when test="count($AHP_normal_usage[aixm:type = ('PERMIT','RESERV','CONDITIONAL','OTHER:EXTENDED') and .//aixm:FlightCharacteristic/aixm:origin = ('NTL','ALL')]) = 0 and count($AHP_normal_usage[aixm:type = ('FORBID') and .//aixm:FlightCharacteristic/aixm:origin = ('NTL','ALL')]) != 0">
										<xsl:value-of select="'Forbidden'"/>
									</xsl:when>
									<xsl:when test="count($AHP_normal_usage[aixm:type = ('PERMIT','RESERV','CONDITIONAL','OTHER:EXTENDED') and .//aixm:FlightCharacteristic/aixm:origin = ('NTL','ALL')]) != 0">
										<xsl:value-of select="'Permitted'"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- (d)International traffic -->
							<xsl:variable name="AHP_intl_traffic">
								<xsl:choose>
									<xsl:when test="count($AHP_normal_usage[aixm:type = ('PERMIT','RESERV','CONDITIONAL','OTHER:EXTENDED') and .//aixm:FlightCharacteristic/aixm:origin = ('INTL','ALL')]) = 0 and count($AHP_normal_usage[aixm:type = ('FORBID') and .//aixm:FlightCharacteristic/aixm:origin = ('INTL','ALL')]) != 0">
										<xsl:value-of select="'Forbidden'"/>
									</xsl:when>
									<xsl:when test="count($AHP_normal_usage[aixm:type = ('PERMIT','RESERV','CONDITIONAL','OTHER:EXTENDED') and .//aixm:FlightCharacteristic/aixm:origin = ('INTL','ALL')]) != 0">
										<xsl:value-of select="'Permitted'"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- (d)Scheduled flight -->
							<xsl:variable name="AHP_scheduled_flight">
								<xsl:choose>
									<xsl:when test="count($AHP_normal_usage[aixm:type = ('PERMIT','RESERV','CONDITIONAL','OTHER:EXTENDED') and .//aixm:FlightCharacteristic/aixm:purpose = ('SCHEDULED','ALL')]) = 0 and count($AHP_normal_usage[aixm:type = ('FORBID') and .//aixm:FlightCharacteristic/aixm:purpose = ('SCHEDULED','ALL')]) != 0">
										<xsl:value-of select="'Forbidden'"/>
									</xsl:when>
									<xsl:when test="count($AHP_normal_usage[aixm:type = ('PERMIT','RESERV','CONDITIONAL','OTHER:EXTENDED') and .//aixm:FlightCharacteristic/aixm:purpose = ('SCHEDULED','ALL')]) != 0">
										<xsl:value-of select="'Permitted'"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- (d)Non scheduled flight -->
							<xsl:variable name="AHP_non_scheduled_flight">
								<xsl:choose>
									<xsl:when test="count($AHP_normal_usage[aixm:type = ('PERMIT','RESERV','CONDITIONAL','OTHER:EXTENDED') and .//aixm:FlightCharacteristic/aixm:purpose = ('NON_SCHEDULED','ALL')]) = 0 and count($AHP_normal_usage[aixm:type = ('FORBID') and .//aixm:FlightCharacteristic/aixm:purpose = ('NON_SCHEDULED','ALL')]) != 0">
										<xsl:value-of select="'Forbidden'"/>
									</xsl:when>
									<xsl:when test="count($AHP_normal_usage[aixm:type = ('PERMIT','RESERV','CONDITIONAL','OTHER:EXTENDED') and .//aixm:FlightCharacteristic/aixm:purpose = ('NON_SCHEDULED','ALL')]) != 0">
										<xsl:value-of select="'Permitted'"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- (d)Private flight -->
							<xsl:variable name="AHP_private_flight">
								<xsl:choose>
									<xsl:when test="count($AHP_normal_usage[aixm:type = ('PERMIT','RESERV','CONDITIONAL','OTHER:EXTENDED') and .//aixm:FlightCharacteristic/aixm:purpose = ('PRIVATE','ALL')]) = 0 and count($AHP_normal_usage[aixm:type = ('FORBID') and .//aixm:FlightCharacteristic/aixm:purpose = ('PRIVATE','ALL')]) != 0">
										<xsl:value-of select="'Forbidden'"/>
									</xsl:when>
									<xsl:when test="count($AHP_normal_usage[aixm:type = ('PERMIT','RESERV','CONDITIONAL','OTHER:EXTENDED') and .//aixm:FlightCharacteristic/aixm:purpose = ('PRIVATE','ALL')]) != 0">
										<xsl:value-of select="'Permitted'"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- (d)Observe VFR -->
							<xsl:variable name="AHP_VFR_flight">
								<xsl:choose>
									<xsl:when test="count($AHP_normal_usage[aixm:type = ('PERMIT','RESERV','CONDITIONAL','OTHER:EXTENDED') and .//aixm:FlightCharacteristic/aixm:rule = ('VFR','ALL')]) = 0 and count($AHP_normal_usage[aixm:type = ('FORBID') and .//aixm:FlightCharacteristic/aixm:rule = ('VFR','ALL')]) != 0">
										<xsl:value-of select="'Forbidden'"/>
									</xsl:when>
									<xsl:when test="count($AHP_normal_usage[aixm:type = ('PERMIT','RESERV','CONDITIONAL','OTHER:EXTENDED') and .//aixm:FlightCharacteristic/aixm:rule = ('VFR','ALL')]) != 0">
										<xsl:value-of select="'Permitted'"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- (d)Observe IFR -->
							<xsl:variable name="AHP_IFR_flight">
								<xsl:choose>
									<xsl:when test="count($AHP_normal_usage[aixm:type = ('PERMIT','RESERV','CONDITIONAL','OTHER:EXTENDED') and .//aixm:FlightCharacteristic/aixm:rule = ('IFR','ALL')]) = 0 and count($AHP_normal_usage[aixm:type = ('FORBID') and .//aixm:FlightCharacteristic/aixm:rule = ('IFR','ALL')]) != 0">
										<xsl:value-of select="'Forbidden'"/>
									</xsl:when>
									<xsl:when test="count($AHP_normal_usage[aixm:type = ('PERMIT','RESERV','CONDITIONAL','OTHER:EXTENDED') and .//aixm:FlightCharacteristic/aixm:rule = ('IFR','ALL')]) != 0">
										<xsl:value-of select="'Permitted'"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- Reference point description -->
							<xsl:variable name="AHP_ARP_description">
								<xsl:for-each select="$AHP_timeSlice/aixm:annotation/aixm:Note[aixm:propertyName = ('arp', 'ARP') or contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note), 'aerodrome reference point')]">
									<xsl:choose>
										<xsl:when test="contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note), 'aerodrome reference point description')">
											<xsl:value-of select="substring-after(aixm:translatedNote/aixm:LinguisticNote/aixm:note, ':')"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="aixm:translatedNote/aixm:LinguisticNote/aixm:note"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:for-each>
							</xsl:variable>
							
							<!-- Latitude -->
							<xsl:variable name="AHP_ARP_lat">
								<xsl:variable name="latitude" select="number(substring-before($AHP_timeSlice/aixm:ARP/aixm:ElevatedPoint/gml:pos, ' '))"/>
								<xsl:variable name="lat_whole" select="string(floor(abs($latitude)))"/>
								<xsl:variable name="lat_frac" select="string(abs($latitude) - floor(abs($latitude)))"/>
								<xsl:variable name="lat_deg" select="if (string-length($lat_whole) = 1) then concat('0', $lat_whole) else $lat_whole"/>
								<xsl:variable name="lat_min_whole" select="floor(number($lat_frac) * 60)"/>
								<xsl:variable name="lat_min_frac" select="number($lat_frac) * 60 - $lat_min_whole"/>
								<xsl:variable name="lat_min" select="if (string-length(string($lat_min_whole)) = 1) then concat('0', string($lat_min_whole)) else string($lat_min_whole)"/>
								<xsl:variable name="lat_sec" select="format-number($lat_min_frac * 60, '0.00')"/>
								<xsl:variable name="lat_sec" select="if (string-length(string(floor(number($lat_sec)))) = 1) then concat('0', string($lat_sec)) else string($lat_sec)"/>
								<xsl:value-of select="concat($lat_deg, $lat_min, $lat_sec, if ($latitude >= 0) then 'N' else 'S')"/>
							</xsl:variable>
							
							<!-- Longitude -->
							<xsl:variable name="AHP_ARP_long">
								<xsl:variable name="longitude" select="number(substring-after($AHP_timeSlice/aixm:ARP/aixm:ElevatedPoint/gml:pos, ' '))"/>
								<xsl:variable name="long_whole" select="string(floor(abs($longitude)))"/>
								<xsl:variable name="long_frac" select="string(abs($longitude) - floor(abs($longitude)))"/>
								<xsl:variable name="long_deg" select="if (string-length($long_whole) != 3) then (if (string-length($long_whole) = 1) then concat('00', $long_whole) else concat('0', $long_whole)) else $long_whole"/>
								<xsl:variable name="long_min_whole" select="floor(number($long_frac) * 60)"/>
								<xsl:variable name="long_min_frac" select="number($long_frac) * 60 - $long_min_whole"/>
								<xsl:variable name="long_min" select="if (string-length(string($long_min_whole)) = 1) then concat('0', string($long_min_whole)) else string($long_min_whole)"/>
								<xsl:variable name="long_sec" select="format-number($long_min_frac * 60, '0.00')"/>
								<xsl:variable name="long_sec" select="if (string-length(string(floor(number($long_sec)))) = 1) then concat('0', string($long_sec)) else string($long_sec)"/>
								<xsl:value-of select="concat($long_deg, $long_min, $long_sec, if ($longitude >= 0) then 'E' else 'W')"/>
							</xsl:variable>
							
							<!-- Datum -->
							<xsl:variable name="AHP_ARP_datum">
								<xsl:value-of select="concat(substring($AHP_timeSlice/aixm:ARP/aixm:ElevatedPoint/@srsName, 17,5), substring($AHP_timeSlice/aixm:ARP/aixm:ElevatedPoint/@srsName, 23,4))"/>
							</xsl:variable>
							
							<!-- Geographical accuracy -->
							<xsl:variable name="AHP_ARP_geo_accuracy">
								<xsl:value-of select="$AHP_timeSlice/aixm:ARP/aixm:ElevatedPoint/aixm:horizontalAccuracy"/>
							</xsl:variable>
							
							<!-- Unit of measurement [geographical accuracy] -->
							<xsl:variable name="AHP_ARP_geo_acc_uom">
								<xsl:value-of select="$AHP_timeSlice/aixm:ARP/aixm:ElevatedPoint/aixm:horizontalAccuracy/@uom"/>
							</xsl:variable>
							
							<!-- Elevation -->
							<xsl:variable name="AHP_ARP_elevation">
								<xsl:value-of select="$AHP_timeSlice/aixm:fieldElevation"/>
							</xsl:variable>
							
							<!-- Elevation accuracy -->
							<xsl:variable name="AHP_ARP_elev_acc">
								<xsl:value-of select="$AHP_timeSlice/aixm:fieldElevationAccuracy"/>
							</xsl:variable>
							
							<!-- Geoid undulation -->
							<xsl:variable name="AHP_ARP_geoid_und">
								<xsl:value-of select="$AHP_timeSlice/aixm:ARP/aixm:ElevatedPoint/aixm:geoidUndulation"/>
							</xsl:variable>
							
							<!-- Unit of measurement [vertical distance] -->
							<xsl:variable name="AHP_ARP_vert_dist_uom">
								<xsl:choose>
									<xsl:when test="$AHP_timeSlice/aixm:fieldElevation/@uom">
										<xsl:value-of select="$AHP_timeSlice/aixm:fieldElevation/@uom"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$AHP_timeSlice/aixm:ARP/aixm:ElevatedPoint/aixm:geoidUndulation/@uom"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- Cyclic redundancy check -->
							<xsl:variable name="AHP_CRC">
								<xsl:value-of select="fcn:get-last-word($AHP_timeSlice/aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note, 'CRC:')]/aixm:note)"/>
							</xsl:variable>
							
							<!-- Vertical Datum -->
							<xsl:variable name="AHP_vertical_datum">
								<xsl:value-of select="$AHP_timeSlice/aixm:verticalDatum"/>
							</xsl:variable>
							
							<!-- Served city -->
							<xsl:variable name="AHP_served_city">
								<xsl:value-of select="$AHP_timeSlice/aixm:servedCity/aixm:City/aixm:name"/>
							</xsl:variable>
							
							<!-- Site description -->
							<xsl:variable name="AHP_site_description">
								<xsl:for-each select="$AHP_timeSlice/aixm:annotation/aixm:Note[aixm:propertyName = ('servedCity') or contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note), 'site description')]">
									<xsl:choose>
										<xsl:when test="contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, ':')">
											<xsl:value-of select="substring-after(aixm:translatedNote/aixm:LinguisticNote/aixm:note, ':')"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="aixm:translatedNote/aixm:LinguisticNote/aixm:note"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:for-each>
							</xsl:variable>
							
							<!-- Magnetic variation -->
							<xsl:variable name="AHP_mag_var">
								<xsl:value-of select="$AHP_timeSlice/aixm:magneticVariation"/>
							</xsl:variable>
							
							<!-- Magnetic variation date -->
							<xsl:variable name="AHP_mag_var_date">
								<xsl:value-of select="$AHP_timeSlice/aixm:dateMagneticVariation"/>
							</xsl:variable>
							
							<!-- Annual rate of change of magnetic variation -->
							<xsl:variable name="AHP_mag_var_change">
								<xsl:value-of select="$AHP_timeSlice/aixm:magneticVariationChange"/>
							</xsl:variable>
							
							<!-- Reference temperature -->
							<xsl:variable name="AHP_ref_temp">
								<xsl:choose>
									<xsl:when test="number($AHP_timeSlice/aixm:referenceTemperature) ge 0">
										<xsl:value-of select="concat('+', $AHP_timeSlice/aixm:referenceTemperature)"/>
									</xsl:when>
									<xsl:when test="number($AHP_timeSlice/aixm:referenceTemperature) lt 0">
										<xsl:value-of select="concat('-', $AHP_timeSlice/aixm:referenceTemperature)"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- Unit of measurement [temperature] -->
							<xsl:variable name="AHP_ref_temp_uom">
								<xsl:value-of select="$AHP_timeSlice/aixm:referenceTemperature/@uom"/>
							</xsl:variable>
							
							<!-- Organisation in charge -->
							<xsl:variable name="organisation_in_charge">
								<xsl:choose>
									<xsl:when test="//aixm:OrganisationAuthority[gml:identifier = $Resp_org_state_UUID and aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice/aixm:relatedOrganisationAuthority/aixm:OrganisationAuthorityAssociation[aixm:type = 'OWNED_BY' and aixm:theOrganisationAuthority]]">
										<xsl:variable name="Owner_organisation_UUID" select="substring-after(//aixm:OrganisationAuthority[gml:identifier = $Resp_org_state_UUID and aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice/aixm:relatedOrganisationAuthority/aixm:OrganisationAuthorityAssociation[aixm:type = 'OWNED_BY' and aixm:theOrganisationAuthority]]/aixm:theOrganisationAuthority/@xlink:href, 'urn:uuid:')"/>
										<xsl:value-of select="//aixm:OrganisationAuthority[gml:identifier = $Owner_organisation_UUID]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice/aixm:name"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$AHP_resp_org_state_name"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- Altimeter check location description -->
							<xsl:variable name="AHP_alt_check_loc">
								<xsl:for-each select="$AHP_timeSlice/aixm:annotation/aixm:Note[aixm:propertyName = ('altimeterCheckLocation') or contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note), 'altimeter check location')]">
									<xsl:choose>
										<xsl:when test="contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, ':')">
											<xsl:value-of select="substring-after(aixm:translatedNote/aixm:LinguisticNote/aixm:note, ':')"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="aixm:translatedNote/aixm:LinguisticNote/aixm:note"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:for-each>
							</xsl:variable>
							
							<!-- Secondary power supply description -->
							<xsl:variable name="AHP_secondary_power_supply">
								<xsl:for-each select="$AHP_timeSlice/aixm:annotation/aixm:Note[aixm:propertyName = ('secondaryPowerSupply') or contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note), 'secondary power supply')]">
									<xsl:choose>
										<xsl:when test="contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, ':')">
											<xsl:value-of select="substring-after(aixm:translatedNote/aixm:LinguisticNote/aixm:note, ':')"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="aixm:translatedNote/aixm:LinguisticNote/aixm:note"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:for-each>
							</xsl:variable>
							
							<!-- Wind direction indicator description -->
							<xsl:variable name="AHP_wind_direction_indicator">
								<xsl:for-each select="$AHP_timeSlice/aixm:annotation/aixm:Note[aixm:propertyName = ('windDirectionIndicator') or contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note), 'wind direction indicator')]">
									<xsl:choose>
										<xsl:when test="contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, ':')">
											<xsl:value-of select="substring-after(aixm:translatedNote/aixm:LinguisticNote/aixm:note, ':')"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="aixm:translatedNote/aixm:LinguisticNote/aixm:note"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:for-each>
							</xsl:variable>
							
							<!-- Landing direction indicator description -->
							<xsl:variable name="AHP_landing_direction_indicator">
								<xsl:for-each select="$AHP_timeSlice/aixm:annotation/aixm:Note[aixm:propertyName = ('landingDirectionIndicator') or contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note), 'landing direction indicator')]">
									<xsl:choose>
										<xsl:when test="contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, ':')">
											<xsl:value-of select="substring-after(aixm:translatedNote/aixm:LinguisticNote/aixm:note, ':')"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="aixm:translatedNote/aixm:LinguisticNote/aixm:note"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:for-each>
							</xsl:variable>
							
							<!-- Transition altitude -->
							<xsl:variable name="AHP_transition_altitude">
								<xsl:value-of select="$AHP_timeSlice/aixm:transitionAltitude"/>
							</xsl:variable>
							
							<!-- Unit of measurement [transition altitude] -->
							<xsl:variable name="AHP_transition_alt_uom">
								<xsl:value-of select="$AHP_timeSlice/aixm:transitionAltitude/@uom"/>
							</xsl:variable>
							
							<!-- Working hours -->
							<xsl:variable name="AHP_working_hours">
								<xsl:choose>
									<!-- if AHP has at least one aixm:availability -->
									<xsl:when test="count($AHP_timeSlice/aixm:availability) ge 1">
										<xsl:for-each select="$AHP_timeSlice/aixm:availability/aixm:AirportHeliportAvailability">
											<xsl:choose>
												<!-- insert 'H24' if there is an aixm:availability property with aixm:operationalStatus='NORMAL' and no aixm:Timesheet -->
												<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and not(aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note, 'HX') or contains(aixm:note, 'HO') or contains(aixm:note, 'NOTAM') or contains(aixm:note, 'HOL') or contains(aixm:note, 'SS') or contains(aixm:note, 'SR') or contains(aixm:note, 'MON') or contains(aixm:note, 'TUE') or contains(aixm:note, 'WED') or contains(aixm:note, 'THU') or contains(aixm:note, 'FRI') or contains(aixm:note, 'SAT') or contains(aixm:note, 'SUN')]]) and aixm:operationalStatus = 'NORMAL'">
													<xsl:value-of select="'H24'"/>
												</xsl:when>
												<!-- insert 'H24' if there is an aixm:availability property with aixm:operationalStatus='NORMAL' and a continuous service 24/7 aixm:Timesheet -->
												<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and (not(aixm:dayTil) or aixm:dayTil='ANY') and aixm:startTime='00:00' and (aixm:endTime='00:00' or aixm:endTime='24:00') and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'NORMAL'">
													<xsl:value-of select="'H24'"/>
												</xsl:when>
												<!-- insert 'HJ' if there is an aixm:availability property with aixm:operationalStatus='NORMAL' and a sunrise to sunset aixm:Timesheet -->
												<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SR' and aixm:endEvent='SS' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'NORMAL'">
													<xsl:value-of select="'HJ'"/>
												</xsl:when>
												<!-- insert 'HN' if there is an aixm:availability property with aixm:operationalStatus='NORMAL' and a sunset to sunrise aixm:Timesheet -->
												<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SS' and aixm:endEvent='SR' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'NORMAL'">
													<xsl:value-of select="'HN'"/>
												</xsl:when>
												<!-- insert 'HX' if there is an aixm:availability property with aixm:operationalStatus='NORMAL', no aixm:Timesheet and corresponding note -->
												<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, 'HX')] and aixm:operationalStatus = 'NORMAL'">
													<xsl:value-of select="'HX'"/>
												</xsl:when>
												<!-- insert 'HO' if there is an aixm:availability property with aixm:operationalStatus='NORMAL', no aixm:Timesheet and corresponding note -->
												<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, 'HO')]">
													<xsl:value-of select="'HO'"/>
												</xsl:when>
												<!-- insert 'NOTAM' if there is an aixm:availability property with aixm:operationalStatus='NORMAL', no aixm:Timesheet and corresponding note -->
												<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note, 'NOTAM')]">
													<xsl:value-of select="'NOTAM'"/>
												</xsl:when>
												<!-- insert 'CLOSED' if there is an aixm:availability property with aixm:operationalStatus='UNSERVICEABLE' and no aixm:Timesheet -->
												<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and aixm:operationalStatus = 'CLOSED'">
													<xsl:value-of select="'CLSD'"/>
												</xsl:when>
												<xsl:otherwise>
													<!-- for daily schedules other than H24 -->
													<xsl:for-each select="aixm:timeInterval/aixm:Timesheet[aixm:day='ANY' and not(aixm:startEvent) and not(aixm:endEvent)]">
														<xsl:variable name="start_time" select="aixm:startTime"/>
														<xsl:variable name="start_time" select="concat(substring($start_time, 1, 2), substring($start_time, 4, 2))"/>
														<xsl:variable name="end_time" select="aixm:endTime"/>
														<xsl:variable name="end_time" select="concat(substring($end_time, 1, 2), substring($end_time, 4, 2))"/>
														<!-- calculating daylight saving time -->
														<xsl:variable name="start_time_DST">
															<xsl:value-of select="if (number(substring($start_time, 1, 2)) gt 0) then format-number(number(substring($start_time, 1, 2)) - 1, '00') else 23"/>
														</xsl:variable>
														<xsl:variable name="end_time_DST">
															<xsl:value-of select="if (number(substring($end_time, 1, 2)) gt 0) then format-number(number(substring($end_time, 1, 2)) - 1, '00') else 23"/>
														</xsl:variable>
														<xsl:variable name="DST_time" select="concat(' (', $start_time_DST, substring($start_time, 3, 2), '-', $end_time_DST, substring($end_time, 3, 2), ')')" />
														<!-- if aixm:daylightSavingAdjust='YES' insert time interval and daylight saving time interval -->
														<xsl:if test="aixm:daylightSavingAdjust = 'YES'">
															<xsl:value-of select="if (aixm:excluded and aixm:excluded = 'NO') then concat($start_time, '-', $end_time, $DST_time) else concat('exc ' ,$start_time, '-', $end_time, $DST_time)"/>
															<xsl:if test="position() != last()"><xsl:text>&lt;br/&gt;</xsl:text></xsl:if>
														</xsl:if>
														<!-- aixm:daylightSavingAdjust='NO' or not present insert only time interval -->
														<xsl:if test="(aixm:daylightSavingAdjust = 'NO' or not(aixm:daylightSavingAdjust))">
															<xsl:value-of select="if (aixm:excluded and aixm:excluded = 'NO') then concat($start_time, '-', $end_time) else concat('exc ', $start_time, '-', $end_time)"/>
															<xsl:if test="position() != last()"><xsl:text>&lt;br/&gt;</xsl:text></xsl:if>
														</xsl:if>
													</xsl:for-each>
													<!-- for days of the week special days schedules  -->
													<xsl:for-each-group select="aixm:timeInterval/aixm:Timesheet[aixm:day = ('MON','TUE','WED','THU','FRI','SAT','SUN','WORK_DAY','BEF_WORK_DAY','AFT_WORK_DAY','HOL','BEF_HOL','AFT_HOL','BUSY_FRI') and not(aixm:startEvent) and not(aixm:endEvent)]" group-by="if (aixm:dayTil) then concat(aixm:day, '-', aixm:dayTil) else aixm:day">
														<dayInterval days="{current-grouping-key()}">
															<xsl:variable name="day_group" select="if (aixm:dayTil) then concat(aixm:day, '-', aixm:dayTil) else aixm:day"/>
															<xsl:value-of select="if (aixm:excluded and aixm:excluded = 'NO') then concat($day_group, ' ') else concat('exc ', $day_group, ' ')"/>
															<xsl:for-each select="current-group()">
																<xsl:variable name="start_time" select="concat(substring(aixm:startTime, 1, 2), substring(aixm:startTime, 4, 2))"/>
																<xsl:variable name="end_time" select="concat(substring(aixm:endTime, 1, 2), substring(aixm:endTime, 4, 2))"/>
																<xsl:variable name="start_time_DST">
																	<xsl:value-of select="if (number(substring($start_time, 1, 2)) gt 0) then format-number(number(substring($start_time, 1, 2)) - 1, '00') else 23"/>
																</xsl:variable>
																<xsl:variable name="end_time_DST">
																	<xsl:value-of select="if (number(substring($end_time, 1, 2)) gt 0) then format-number(number(substring($end_time, 1, 2)) - 1, '00') else 23"/>
																</xsl:variable>
																<xsl:variable name="DST_time" select="concat(' (', $start_time_DST, substring($start_time, 3, 2), '-', $end_time_DST, substring($end_time, 3, 2), ')')" />
																<xsl:choose>
																	<xsl:when test="aixm:daylightSavingAdjust = 'YES'">
																		<xsl:value-of select="concat($start_time, '-', $end_time, $DST_time)" />
																	</xsl:when>
																	<xsl:otherwise>
																		<xsl:value-of select="concat($start_time, '-', $end_time)" />
																	</xsl:otherwise>
																</xsl:choose>
																<xsl:if test="position() != last()"><xsl:text> </xsl:text></xsl:if>
															</xsl:for-each>
															<xsl:if test="position() != last()"><xsl:text>&lt;br/&gt;</xsl:text></xsl:if>
														</dayInterval>
													</xsl:for-each-group>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:for-each>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- Remark to working hours -->
							<xsl:variable name="AHP_working_hours_remarks">
								<xsl:for-each select=".//aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']">
									<xsl:choose>
										<xsl:when test="position() = 1">
											<xsl:value-of select="concat('(', aixm:purpose, ') ', aixm:translatedNote/aixm:LinguisticNote/aixm:note)"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="concat('&lt;br/&gt;(', aixm:purpose, ') ', aixm:translatedNote/aixm:LinguisticNote/aixm:note)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:for-each>
							</xsl:variable>
							
							<!-- Remarks -->
							<xsl:variable name="AHP_remarks">
								<xsl:variable name="dataset_creation_date" select="../../aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
								<xsl:value-of select="concat('Current time: ', $dataset_creation_date)"/>
							</xsl:variable>
							
							<!-- Committed on -->
							<xsl:variable name="commit_date">
								<xsl:value-of select="fcn:get-date($AHP_timeSlice/aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)"/>
							</xsl:variable>
							
							<!-- Internal UID (master) -->
							<xsl:variable name="AHP_UUID">
								<xsl:value-of select="gml:identifier"/>
							</xsl:variable>
							
							<!-- FIR - Coded identifier -->
							<xsl:variable name="FIR_designator">
								
								<!-- work in progress -->
								
							</xsl:variable>
							
							<!-- Originator -->
							<xsl:variable name="originator">
								<xsl:value-of select="$AHP_timeSlice/aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
							</xsl:variable>
							
							<!-- Effective date -->
							<xsl:variable name="effective_date">
								<xsl:value-of select="fcn:get-date($AHP_timeSlice/gml:validTime/gml:TimePeriod/gml:beginPosition)"/>
							</xsl:variable>
							
							<!-- System remark -->
							<xsl:variable name="system_remark" select="'Please obtain current usage data from dedicated report'"/>
							
							
							<tr style="white-space:nowrap;vertical-align:top;">
								<td><xsl:value-of select="if (string-length($AHP_designator) gt 0) then $AHP_designator else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_resp_org_state_name) gt 0) then $AHP_resp_org_state_name else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_name) gt 0) then $AHP_name else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_ICAO_code) gt 0) then $AHP_ICAO_code else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_IATA_code) gt 0) then $AHP_IATA_code else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_type) gt 0) then $AHP_type else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_control_type) gt 0) then $AHP_control_type else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_nat_traffic) gt 0) then $AHP_nat_traffic else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_intl_traffic) gt 0) then $AHP_intl_traffic else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_scheduled_flight) gt 0) then $AHP_scheduled_flight else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_non_scheduled_flight) gt 0) then $AHP_non_scheduled_flight else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_private_flight) gt 0) then $AHP_private_flight else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_VFR_flight) gt 0) then $AHP_VFR_flight else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_IFR_flight) gt 0) then $AHP_IFR_flight else '&#160;'"/></td>
								<td style="white-space:normal;min-width:300px"><xsl:value-of select="if (string-length($AHP_ARP_description) gt 0) then $AHP_ARP_description else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_ARP_lat) gt 0) then $AHP_ARP_lat else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_ARP_long) gt 0) then $AHP_ARP_long else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_ARP_datum) gt 0) then $AHP_ARP_datum else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_ARP_geo_accuracy) gt 0) then $AHP_ARP_geo_accuracy else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_ARP_geo_acc_uom) gt 0) then $AHP_ARP_geo_acc_uom else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_ARP_elevation) gt 0) then $AHP_ARP_elevation else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_ARP_elev_acc) gt 0) then $AHP_ARP_elev_acc else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_ARP_geoid_und) gt 0) then $AHP_ARP_geoid_und else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_ARP_vert_dist_uom) gt 0) then $AHP_ARP_vert_dist_uom else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_CRC) gt 0) then $AHP_CRC else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_vertical_datum) gt 0) then $AHP_vertical_datum else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_served_city) gt 0) then $AHP_served_city else '&#160;'"/></td>
								<td style="white-space:normal;min-width:300px"><xsl:value-of select="if (string-length($AHP_site_description) gt 0) then $AHP_site_description else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_mag_var) gt 0) then $AHP_mag_var else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_mag_var_date) gt 0) then $AHP_mag_var_date else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_mag_var_change) gt 0) then $AHP_mag_var_change else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_ref_temp) gt 0) then $AHP_ref_temp else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_ref_temp_uom) gt 0) then $AHP_ref_temp_uom else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($organisation_in_charge) gt 0) then $organisation_in_charge else '&#160;'"/></td>
								<td style="white-space:normal;min-width:300px"><xsl:value-of select="if (string-length($AHP_alt_check_loc) gt 0) then $AHP_alt_check_loc else '&#160;'"/></td>
								<td style="white-space:normal;min-width:300px"><xsl:value-of select="if (string-length($AHP_secondary_power_supply) gt 0) then $AHP_secondary_power_supply else '&#160;'"/></td>
								<td style="white-space:normal;min-width:300px"><xsl:value-of select="if (string-length($AHP_wind_direction_indicator) gt 0) then $AHP_wind_direction_indicator else '&#160;'"/></td>
								<td style="white-space:normal;min-width:300px"><xsl:value-of select="if (string-length($AHP_landing_direction_indicator) gt 0) then $AHP_landing_direction_indicator else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_transition_altitude) gt 0) then $AHP_transition_altitude else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_transition_alt_uom) gt 0) then $AHP_transition_alt_uom else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_working_hours) gt 0) then $AHP_working_hours else '&#160;'" disable-output-escaping="yes"/></td>
								<td style="white-space:normal;min-width:500px"><xsl:value-of select="if (string-length($AHP_working_hours_remarks) gt 0) then $AHP_working_hours_remarks else '&#160;'" disable-output-escaping="yes"/></td>
								<td><xsl:value-of select="if (string-length($AHP_remarks) gt 0) then $AHP_remarks else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($commit_date) gt 0) then $commit_date else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($AHP_UUID) gt 0) then $AHP_UUID else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($FIR_designator) gt 0) then $FIR_designator else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($originator) gt 0) then $originator else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
								<td><xsl:value-of select="if (string-length($system_remark) gt 0) then $system_remark else '&#160;'"/></td>
							</tr>
							
						</xsl:for-each>
						
					</tbody>
				</table>
				
			</body>
			
		</html>
		
	</xsl:template>
	
</xsl:transform>