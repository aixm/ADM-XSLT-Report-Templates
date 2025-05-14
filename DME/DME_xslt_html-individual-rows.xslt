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
	featureTypes:	aixm:DME aixm:Navaid
	includeReferencedFeaturesLevel:	"2"
	permanentBaseline:	true
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
	exclude-result-prefixes="xsl uuid message gts gco xsd gml gss gsr gmd aixm event xlink xs xsi aixm_ds_xslt ead-audit">
	
	<xsl:output method="html" indent="yes"/>
	
	<xsl:strip-space elements="*"/>
	
	<xsl:template match="/">
		
		<html xmlns="http://www.w3.org/1999/xhtml">
			
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
				<meta http-equiv="Expires" content="120"/>
				<title>SDO Reporting - DME</title>
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
					<b>DME</b>
				</center>
				<hr/>
				
				<table border="0">
					<tbody>
						
						<tr>
							<td><strong>Master gUID</strong></td>
						</tr>
						<tr>
							<td><strong>Identification</strong></td>
						</tr>
						<tr>
							<td><strong>Name</strong></td>
						</tr>
						<tr>
							<td><strong>Responsible State</strong></td>
						</tr>
						<tr>
							<td><strong>Latitude</strong></td>
						</tr>
						<tr>
							<td><strong>Longitude</strong></td>
						</tr>
						<tr>
							<td><strong>Collocated VOR - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>Channel</strong></td>
						</tr>
						<tr>
							<td><strong>Frequency of virtual VHF facility</strong></td>
						</tr>
						<tr>
							<td><strong>UOM</strong></td>
						</tr>
						<tr>
							<td><strong>Datum</strong></td>
						</tr>
						<tr>
							<td><strong>Working hours</strong></td>
						</tr>
						<tr>
							<td><strong>Effective date</strong></td>
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
						
						<xsl:for-each select="//aixm:DME/aixm:timeSlice/aixm:DMETimeSlice[aixm:interpretation = 'BASELINE']">
							
							<xsl:sort select="aixm:designator" data-type="text" order="ascending"/>
							
							<!-- Master gUID -->
							<xsl:variable name="DME_UUID" select="../../gml:identifier"/>
							
							<!-- Identification -->
							<xsl:variable name="DME_designator" select="aixm:designator"/>
							
							<!-- Name -->
							<xsl:variable name="DME_name" select="aixm:name"/>
							
							<!-- Responsible State -->
							<xsl:variable name="OrgAuthUUID" select="aixm:authority/aixm:AuthorityForNavaidEquipment/aixm:theOrganisationAuthority/@xlink:href"/>
							<xsl:variable name="ResponsibleState">
								<xsl:choose>
									<xsl:when test="//aixm:OrganisationAuthority[gml:identifier = substring-after($OrgAuthUUID, 'urn:uuid:')]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice/aixm:type = 'STATE'">
										<xsl:value-of select="//aixm:OrganisationAuthority[gml:identifier = substring-after($OrgAuthUUID, 'urn:uuid:')]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice[aixm:type = 'STATE']/aixm:name"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:variable name="ResponsibleStateUUID" select="//aixm:OrganisationAuthority[gml:identifier = substring-after($OrgAuthUUID, 'urn:uuid:')]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice/aixm:relatedOrganisationAuthority/aixm:OrganisationAuthorityAssociation/aixm:theOrganisationAuthority/@xlink:href"/>
										<xsl:value-of select="//aixm:OrganisationAuthority[gml:identifier = substring-after($ResponsibleStateUUID, 'urn:uuid:')]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice/aixm:name"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							
							<!-- get the coordinates of the DME navaid equipment-->
							<xsl:variable name="coordinates" select="aixm:location/aixm:ElevatedPoint/gml:pos"/>
							
							<!-- Latitude -->
							<xsl:variable name="latitude" select="number(substring-before($coordinates, ' '))"/>
							<xsl:variable name="lat_whole" select="string(floor(abs($latitude)))"/>
							<xsl:variable name="lat_frac" select="string(abs($latitude) - floor(abs($latitude)))"/>
							<xsl:variable name="lat_deg" select="if (string-length($lat_whole) = 1) then concat('0', $lat_whole) else $lat_whole"/>
							<xsl:variable name="lat_min_whole" select="floor(number($lat_frac) * 60)"/>
							<xsl:variable name="lat_min_frac" select="number($lat_frac) * 60 - $lat_min_whole"/>
							<xsl:variable name="lat_min" select="if (string-length(string($lat_min_whole)) = 1) then concat('0', string($lat_min_whole)) else string($lat_min_whole)"/>
							<xsl:variable name="lat_sec" select="format-number($lat_min_frac * 60, '0.00')"/>
							<xsl:variable name="lat_sec" select="if (string-length(string(floor(number($lat_sec)))) = 1) then concat('0', string($lat_sec)) else string($lat_sec)"/>
							<xsl:variable name="DME_latitude_DMS" select="concat($lat_deg, $lat_min, $lat_sec, if ($latitude ge 0) then 'N' else 'S')"/>
							
							<!-- Longitude -->
							<xsl:variable name="longitude" select="number(substring-after($coordinates, ' '))"/>
							<xsl:variable name="long_whole" select="string(floor(abs($longitude)))"/>
							<xsl:variable name="long_frac" select="string(abs($longitude) - floor(abs($longitude)))"/>
							<xsl:variable name="long_deg" select="if (string-length($long_whole) != 3) then (if (string-length($long_whole) = 1) then concat('00', $long_whole) else concat('0', $long_whole)) else $long_whole"/>
							<xsl:variable name="long_min_whole" select="floor(number($long_frac) * 60)"/>
							<xsl:variable name="long_min_frac" select="number($long_frac) * 60 - $long_min_whole"/>
							<xsl:variable name="long_min" select="if (string-length(string($long_min_whole)) = 1) then concat('0', string($long_min_whole)) else string($long_min_whole)"/>
							<xsl:variable name="long_sec" select="format-number($long_min_frac * 60, '0.00')"/>
							<xsl:variable name="long_sec" select="if (string-length(string(floor(number($long_sec)))) = 1) then concat('0', string($long_sec)) else string($long_sec)"/>
							<xsl:variable name="DME_longitude_DMS" select="concat($long_deg, $long_min, $long_sec, if ($longitude ge 0) then 'E' else 'W')"/>
							
							<!-- Collocated VOR - Identification -->
							<!-- Find the Navaid with type='VOR_DME' that references this DME -->
							<xsl:variable name="collocated_VOR_designator">
								<xsl:for-each select="//aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE' and aixm:type = 'VOR_DME' and aixm:navaidEquipment/aixm:NavaidComponent/aixm:theNavaidEquipment/@xlink:href = concat('urn:uuid:', $DME_UUID)]">
									<!-- Find the specific xlink:href that references an aixm:VOR -->
									<xsl:for-each select="aixm:navaidEquipment">
										<xsl:variable name="Xlink_UUID" select="substring-after(aixm:NavaidComponent/aixm:theNavaidEquipment/@xlink:href, 'urn:uuid:')"/>
										<xsl:variable name="VOR_UUID" select="substring-after(aixm:NavaidComponent/aixm:theNavaidEquipment/@xlink:href[$Xlink_UUID = //aixm:VOR/gml:identifier], 'urn:uuid:')"/>
										<xsl:value-of select="//aixm:VOR[gml:identifier = $VOR_UUID]/aixm:timeSlice/aixm:VORTimeSlice/aixm:designator"/>
									</xsl:for-each>
								</xsl:for-each>
							</xsl:variable>
							
							<!-- Channel -->
							<xsl:variable name="DME_channel" select="aixm:channel"/>
							
							<!-- Frequency of virtual VHF facility -->
							<xsl:variable name="DME_virtual_freq" select="aixm:ghostFrequency"/>
							
							<!-- UOM -->
							<xsl:variable name="DME_virtual_freq_uom" select="aixm:ghostFrequency/@uom"/>
							
							<!-- Datum -->
							<xsl:variable name="DME_datum" select="concat(substring(aixm:location/aixm:ElevatedPoint/@srsName, 17,5), substring(aixm:location/aixm:ElevatedPoint/@srsName, 23,4))"/>
							
							<!-- Working hours -->
							<xsl:variable name="OperationalHours">
								<xsl:choose>
									<!-- if DME has at least one aixm:availability -->
									<xsl:when test="count(aixm:availability) ge 1">
										<xsl:for-each select="aixm:availability/aixm:NavaidOperationalStatus">
											<xsl:choose>
												<!-- insert 'H24' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL' and no aixm:Timesheet -->
												<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and not(aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:translatedNote/aixm:LinguisticNote/aixm:note[(not(@lang) or @lang=('en','eng')) and (contains(., 'HX') or contains(., 'HO') or contains(lower-case(.), 'notam') or contains(., 'HOL') or contains(., 'SS') or contains(., 'SR') or contains(., 'MON') or contains(., 'TUE') or contains(., 'WED') or contains(., 'THU') or contains(., 'FRI') or contains(., 'SAT') or contains(., 'SUN'))]]) and aixm:operationalStatus = 'OPERATIONAL'">
													<xsl:value-of select="'H24'"/>
												</xsl:when>
												<!-- insert 'H24' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL' and a continuous service 24/7 aixm:Timesheet -->
												<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and (not(aixm:dayTil) or aixm:dayTil='ANY') and aixm:startTime='00:00' and (aixm:endTime='00:00' or aixm:endTime='24:00') and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
													<xsl:value-of select="'H24'"/>
												</xsl:when>
												<!-- insert 'HJ' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL' and a sunrise to sunset aixm:Timesheet -->
												<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SR' and aixm:endEvent='SS' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
													<xsl:value-of select="'HJ'"/>
												</xsl:when>
												<!-- insert 'HN' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL' and a sunset to sunrise aixm:Timesheet -->
												<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SS' and aixm:endEvent='SR' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
													<xsl:value-of select="'HN'"/>
												</xsl:when>
												<!-- insert 'HX' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL', no aixm:Timesheet and corresponding note -->
												<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'HX')] and aixm:operationalStatus = 'OPERATIONAL'">
													<xsl:value-of select="'HX'"/>
												</xsl:when>
												<!-- insert 'HO' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL', no aixm:Timesheet and corresponding note -->
												<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'HO')]">
													<xsl:value-of select="'HO'"/>
												</xsl:when>
												<!-- insert 'NOTAM' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL', no aixm:Timesheet and corresponding note -->
												<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'notam') and not(contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'outside'))]">
													<xsl:value-of select="'NOTAM'"/>
												</xsl:when>
												<!-- insert 'U/S' if there is an aixm:availability property with aixm:operationalStatus='UNSERVICEABLE' and no aixm:Timesheet -->
												<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and aixm:operationalStatus = 'UNSERVICEABLE'">
													<xsl:value-of select="'U/S'"/>
												</xsl:when>
												<xsl:otherwise>
													<!-- for daily schedules other than H24 -->
													<xsl:for-each-group select="aixm:timeInterval/aixm:Timesheet[aixm:day = ('ANY','MON','TUE','WED','THU','FRI','SAT','SUN','WORK_DAY','BEF_WORK_DAY','AFT_WORK_DAY','HOL','BEF_HOL','AFT_HOL','BUSY_FRI')]" group-by="if (aixm:dayTil) then concat(aixm:day, '-', aixm:dayTil) else aixm:day">
														<dayInterval days="{current-grouping-key()}">
															<xsl:variable name="day" select="if (aixm:day = 'ANY') then 'ANY_DAY' else aixm:day"/>
															<xsl:variable name="day_til" select="if (aixm:dayTil = 'ANY') then 'ANY_DAY' else aixm:dayTil"/>
															<xsl:variable name="day_group" select="if (aixm:dayTil) then if (aixm:dayTil = aixm:day) then $day else concat($day, '-', $day_til) else $day"/>
															<xsl:value-of select="if (aixm:excluded and aixm:excluded = 'NO') then concat($day_group, ' ') else concat('exc ', $day_group, ' ')"/>
															<xsl:for-each select="current-group()">
																<xsl:variable name="start_date" select="if (aixm:startDate != 'SDLST' and aixm:startDate != 'EDLST') then concat(substring(aixm:startDate,1,2), '/', substring(aixm:startDate,4,2)) else aixm:startDate"/>
																<xsl:variable name="end_date" select="if (aixm:endDate != 'SDLST' and aixm:endDate != 'EDLST') then concat(substring(aixm:endDate,1,2), '/', substring(aixm:endDate,4,2)) else aixm:endDate"/>
																<xsl:variable name="start_time" select="concat(substring(aixm:startTime, 1, 2), substring(aixm:startTime, 4, 2))"/>
																<xsl:variable name="end_time" select="concat(substring(aixm:endTime, 1, 2), substring(aixm:endTime, 4, 2))"/>
																<xsl:variable name="start_time_DST">
																	<xsl:value-of select="concat(if (number(substring($start_time, 1, 2)) gt 0) then format-number(number(substring($start_time, 1, 2)) - 1, '00') else 23, substring($start_time, 3, 2))"/>
																</xsl:variable>
																<xsl:variable name="end_time_DST">
																	<xsl:value-of select="concat(if (number(substring($end_time, 1, 2)) gt 0) then format-number(number(substring($end_time, 1, 2)) - 1, '00') else 23, substring($end_time, 3, 2))"/>
																</xsl:variable>
																<xsl:value-of select="concat(
																	if (aixm:startDate and aixm:endDate) then concat($start_date, '-', $end_date, ' ') else '',
																	if (aixm:startTime) then $start_time else '',
																	if (aixm:daylightSavingAdjust = 'YES' and (aixm:startEvent or aixm:endEvent) and aixm:startTime) then concat('(', $start_time_DST, ')') else '',
																	if (aixm:startEvent) then if (aixm:startTime) then concat('/',aixm:startEvent) else aixm:startEvent else '',
																	if (aixm:startEvent and aixm:startTimeRelativeEvent) then if (contains(aixm:startTimeRelativeEvent, '+')) then concat('plus', substring-after(aixm:startTimeRelativeEvent, '+')) else if (number(aixm:startTimeRelativeEvent) ge 0) then concat('plus', aixm:startTimeRelativeEvent) else concat('minus', substring-after(aixm:startTimeRelativeEvent, '-')) else '',
																	if (aixm:startEvent and aixm:startTimeRelativeEvent and aixm:startTimeRelativeEvent/@uom) then aixm:startTimeRelativeEvent/@uom else '',
																	if (aixm:startEventInterpretation) then concat('(', aixm:startEventInterpretation, ')') else '',
																	'-',
																	if (aixm:endTime) then $end_time else '',
																	if (aixm:daylightSavingAdjust = 'YES' and (aixm:startEvent or aixm:endEvent) and aixm:endTime) then concat('(', $end_time_DST, ')') else '',
																	if (aixm:endEvent) then if (aixm:endTime) then concat('/',aixm:endEvent) else aixm:endEvent else '',
																	if (aixm:endEvent and aixm:endTimeRelativeEvent) then if (contains(aixm:endTimeRelativeEvent, '+')) then concat('plus', substring-after(aixm:endTimeRelativeEvent, '+')) else if (number(aixm:endTimeRelativeEvent) ge 0) then concat('plus', aixm:endTimeRelativeEvent) else concat('minus', substring-after(aixm:endTimeRelativeEvent, '-')) else '',
																	if (aixm:endEvent and aixm:endTimeRelativeEvent and aixm:endTimeRelativeEvent/@uom) then aixm:endTimeRelativeEvent/@uom else '',
																	if (aixm:endEventInterpretation) then concat('(', aixm:endEventInterpretation, ')') else '',
																	if (not(aixm:startEvent) and not(aixm:endEvent) and aixm:daylightSavingAdjust = 'YES') then concat(' (', $start_time_DST, '-', $end_time_DST, ')') else '')"/>
																<xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
															</xsl:for-each>
															<xsl:if test="position() != last()"><xsl:text>; </xsl:text></xsl:if>
														</dayInterval>
													</xsl:for-each-group>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:for-each>
									</xsl:when>
									<!-- if DME does not have any aixm:availability, look at aixm:Navaid -->
									<xsl:when test="count(aixm:availability) = 0">
										<xsl:for-each select="//aixm:Navaid/aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE' and contains(aixm:type, 'DME') and aixm:navaidEquipment/aixm:NavaidComponent/aixm:theNavaidEquipment/@xlink:href = concat('urn:uuid:', $DME_UUID)]">
											<xsl:for-each select="aixm:availability/aixm:NavaidOperationalStatus">
												<xsl:choose>
													<!-- insert 'H24' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL' and no aixm:Timesheet -->
													<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and not(aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:translatedNote/aixm:LinguisticNote/aixm:note[(not(@lang) or @lang=('en','eng')) and (contains(., 'HX') or contains(., 'HO') or contains(lower-case(.), 'notam') or contains(., 'HOL') or contains(., 'SS') or contains(., 'SR') or contains(., 'MON') or contains(., 'TUE') or contains(., 'WED') or contains(., 'THU') or contains(., 'FRI') or contains(., 'SAT') or contains(., 'SUN'))]]) and aixm:operationalStatus = 'OPERATIONAL'">
														<xsl:value-of select="'H24'"/>
													</xsl:when>
													<!-- insert 'H24' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL' and a continuous service 24/7 aixm:Timesheet -->
													<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and (not(aixm:dayTil) or aixm:dayTil='ANY') and aixm:startTime='00:00' and (aixm:endTime='00:00' or aixm:endTime='24:00') and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
														<xsl:value-of select="'H24'"/>
													</xsl:when>
													<!-- insert 'HJ' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL' and a sunrise to sunset aixm:Timesheet -->
													<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SR' and aixm:endEvent='SS' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
														<xsl:value-of select="'HJ'"/>
													</xsl:when>
													<!-- insert 'HN' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL' and a sunset to sunrise aixm:Timesheet -->
													<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SS' and aixm:endEvent='SR' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
														<xsl:value-of select="'HN'"/>
													</xsl:when>
													<!-- insert 'HX' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL', no aixm:Timesheet and corresponding note -->
													<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'HX')] and aixm:operationalStatus = 'OPERATIONAL'">
														<xsl:value-of select="'HX'"/>
													</xsl:when>
													<!-- insert 'HO' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL', no aixm:Timesheet and corresponding note -->
													<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'HO')]">
														<xsl:value-of select="'HO'"/>
													</xsl:when>
													<!-- insert 'NOTAM' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL', no aixm:Timesheet and corresponding note -->
													<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'notam') and not(contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'outside'))]">
														<xsl:value-of select="'NOTAM'"/>
													</xsl:when>
													<!-- insert 'U/S' if there is an aixm:availability property with aixm:operationalStatus='UNSERVICEABLE' and no aixm:Timesheet -->
													<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and aixm:operationalStatus = 'UNSERVICEABLE'">
														<xsl:value-of select="'U/S'"/>
													</xsl:when>
													<xsl:otherwise>
														<!-- for daily schedules other than H24 -->
														<xsl:for-each-group select="aixm:timeInterval/aixm:Timesheet[aixm:day = ('ANY','MON','TUE','WED','THU','FRI','SAT','SUN','WORK_DAY','BEF_WORK_DAY','AFT_WORK_DAY','HOL','BEF_HOL','AFT_HOL','BUSY_FRI')]" group-by="if (aixm:dayTil) then concat(aixm:day, '-', aixm:dayTil) else aixm:day">
															<dayInterval days="{current-grouping-key()}">
																<xsl:variable name="day" select="if (aixm:day = 'ANY') then 'ANY_DAY' else aixm:day"/>
																<xsl:variable name="day_til" select="if (aixm:dayTil = 'ANY') then 'ANY_DAY' else aixm:dayTil"/>
																<xsl:variable name="day_group" select="if (aixm:dayTil) then if (aixm:dayTil = aixm:day) then $day else concat($day, '-', $day_til) else $day"/>
																<xsl:value-of select="if (aixm:excluded and aixm:excluded = 'NO') then concat($day_group, ' ') else concat('exc ', $day_group, ' ')"/>
																<xsl:for-each select="current-group()">
																	<xsl:variable name="start_date" select="if (aixm:startDate != 'SDLST' and aixm:startDate != 'EDLST') then concat(substring(aixm:startDate,1,2), '/', substring(aixm:startDate,4,2)) else aixm:startDate"/>
																	<xsl:variable name="end_date" select="if (aixm:endDate != 'SDLST' and aixm:endDate != 'EDLST') then concat(substring(aixm:endDate,1,2), '/', substring(aixm:endDate,4,2)) else aixm:endDate"/>
																	<xsl:variable name="start_time" select="concat(substring(aixm:startTime, 1, 2), substring(aixm:startTime, 4, 2))"/>
																	<xsl:variable name="end_time" select="concat(substring(aixm:endTime, 1, 2), substring(aixm:endTime, 4, 2))"/>
																	<xsl:variable name="start_time_DST">
																		<xsl:value-of select="concat(if (number(substring($start_time, 1, 2)) gt 0) then format-number(number(substring($start_time, 1, 2)) - 1, '00') else 23, substring($start_time, 3, 2))"/>
																	</xsl:variable>
																	<xsl:variable name="end_time_DST">
																		<xsl:value-of select="concat(if (number(substring($end_time, 1, 2)) gt 0) then format-number(number(substring($end_time, 1, 2)) - 1, '00') else 23, substring($end_time, 3, 2))"/>
																	</xsl:variable>
																	<xsl:value-of select="concat(
																		if (aixm:startDate and aixm:endDate) then concat($start_date, '-', $end_date, ' ') else '',
																		if (aixm:startTime) then $start_time else '',
																		if (aixm:daylightSavingAdjust = 'YES' and (aixm:startEvent or aixm:endEvent) and aixm:startTime) then concat('(', $start_time_DST, ')') else '',
																		if (aixm:startEvent) then if (aixm:startTime) then concat('/',aixm:startEvent) else aixm:startEvent else '',
																		if (aixm:startEvent and aixm:startTimeRelativeEvent) then if (contains(aixm:startTimeRelativeEvent, '+')) then concat('plus', substring-after(aixm:startTimeRelativeEvent, '+')) else if (number(aixm:startTimeRelativeEvent) ge 0) then concat('plus', aixm:startTimeRelativeEvent) else concat('minus', substring-after(aixm:startTimeRelativeEvent, '-')) else '',
																		if (aixm:startEvent and aixm:startTimeRelativeEvent and aixm:startTimeRelativeEvent/@uom) then aixm:startTimeRelativeEvent/@uom else '',
																		if (aixm:startEventInterpretation) then concat('(', aixm:startEventInterpretation, ')') else '',
																		'-',
																		if (aixm:endTime) then $end_time else '',
																		if (aixm:daylightSavingAdjust = 'YES' and (aixm:startEvent or aixm:endEvent) and aixm:endTime) then concat('(', $end_time_DST, ')') else '',
																		if (aixm:endEvent) then if (aixm:endTime) then concat('/',aixm:endEvent) else aixm:endEvent else '',
																		if (aixm:endEvent and aixm:endTimeRelativeEvent) then if (contains(aixm:endTimeRelativeEvent, '+')) then concat('plus', substring-after(aixm:endTimeRelativeEvent, '+')) else if (number(aixm:endTimeRelativeEvent) ge 0) then concat('plus', aixm:endTimeRelativeEvent) else concat('minus', substring-after(aixm:endTimeRelativeEvent, '-')) else '',
																		if (aixm:endEvent and aixm:endTimeRelativeEvent and aixm:endTimeRelativeEvent/@uom) then aixm:endTimeRelativeEvent/@uom else '',
																		if (aixm:endEventInterpretation) then concat('(', aixm:endEventInterpretation, ')') else '',
																		if (not(aixm:startEvent) and not(aixm:endEvent) and aixm:daylightSavingAdjust = 'YES') then concat(' (', $start_time_DST, '-', $end_time_DST, ')') else '')"/>
																	<xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
																</xsl:for-each>
																<xsl:if test="position() != last()"><xsl:text>; </xsl:text></xsl:if>
															</dayInterval>
														</xsl:for-each-group>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:for-each>
										</xsl:for-each>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- Effective date -->
							<xsl:variable name="day" select="substring(gml:validTime/gml:TimePeriod/gml:beginPosition, 9, 2)"/>
							<xsl:variable name="month" select="substring(gml:validTime/gml:TimePeriod/gml:beginPosition, 6, 2)"/>
							<xsl:variable name="month" select="if($month = '01') then 'JAN' else if ($month = '02') then 'FEB' else if ($month = '03') then 'MAR' else 
								if ($month = '04') then 'APR' else if ($month = '05') then 'MAY' else if ($month = '06') then 'JUN' else if ($month = '07') then 'JUL' else 
								if ($month = '08') then 'AUG' else if ($month = '09') then 'SEP' else if ($month = '10') then 'OCT' else if ($month = '11') then 'NOV' else if ($month = '12') then 'DEC' else ''"/>
							<xsl:variable name="year" select="substring(gml:validTime/gml:TimePeriod/gml:beginPosition, 1, 4)"/>
							<xsl:variable name="DME_effective_date" select="concat($day, '-', $month, '-', $year)"/>
							
							<!-- Originator -->
							<xsl:variable name="originator" select="aixm:extension/ead-audit:DMEExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
							
							<tr>
								<td><xsl:value-of select="if (string-length($DME_UUID) gt 0) then $DME_UUID else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DME_designator) gt 0) then $DME_designator else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DME_name) gt 0) then $DME_name else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($ResponsibleState) gt 0) then $ResponsibleState else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DME_latitude_DMS) gt 0) then $DME_latitude_DMS else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DME_longitude_DMS) gt 0) then $DME_longitude_DMS else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($collocated_VOR_designator) gt 0) then $collocated_VOR_designator else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DME_channel) gt 0) then $DME_channel else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DME_virtual_freq) gt 0) then $DME_virtual_freq else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DME_virtual_freq_uom) gt 0) then $DME_virtual_freq_uom else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DME_datum) gt 0) then $DME_datum else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($OperationalHours) gt 0) then $OperationalHours else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($DME_effective_date) gt 3) then $DME_effective_date else '&#160;'"/></td>
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
						<td><font size="-1">Sorting by: </font></td>
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