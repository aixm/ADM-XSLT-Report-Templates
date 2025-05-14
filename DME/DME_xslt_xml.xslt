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
	
	<xsl:output method="xml" indent="yes"/>
	
	<xsl:strip-space elements="*"/>
	
	<xsl:template match="/">
		
		<SdoReportResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="SdoReportMgmt.xsd" origin="SDO" version="4.1">
			<SdoReportResult>
				
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
					
					<Record>
						<xsl:if test="string-length($DME_UUID) gt 0">
							<mid><xsl:value-of select="$DME_UUID"/></mid>
						</xsl:if>
						<xsl:if test="string-length($DME_designator) gt 0">
							<codeId><xsl:value-of select="$DME_designator"/></codeId>
						</xsl:if>
						<xsl:if test="string-length($DME_name) gt 0">
							<txtName><xsl:value-of select="$DME_name"/></txtName>
						</xsl:if>
						<xsl:if test="string-length($ResponsibleState) gt 0">
							<Org>
								<txtName><xsl:value-of select="$ResponsibleState"/></txtName>
							</Org>
						</xsl:if>
						<xsl:if test="string-length($DME_latitude_DMS) gt 0">
							<geoLat><xsl:value-of select="$DME_latitude_DMS"/></geoLat>
						</xsl:if>
						<xsl:if test="string-length($DME_longitude_DMS) gt 0">
							<geoLong><xsl:value-of select="$DME_longitude_DMS"/></geoLong>
						</xsl:if>
						<xsl:if test="string-length($collocated_VOR_designator) gt 0">
							<Vor>
								<codeId><xsl:value-of select="$collocated_VOR_designator"/></codeId>
							</Vor>
						</xsl:if>
						<xsl:if test="string-length($DME_channel) gt 0">
							<codeChannel><xsl:value-of select="$DME_channel"/></codeChannel>
						</xsl:if>
						<xsl:if test="string-length($DME_virtual_freq) gt 0">
							<valGhostFreq><xsl:value-of select="$DME_virtual_freq"/></valGhostFreq>
						</xsl:if>
						<xsl:if test="string-length($DME_virtual_freq_uom) gt 0">
							<uomGhostFreq><xsl:value-of select="$DME_virtual_freq_uom"/></uomGhostFreq>
						</xsl:if>
						<xsl:if test="string-length($DME_datum) gt 0">
							<codeDatum><xsl:value-of select="$DME_datum"/></codeDatum>
						</xsl:if>
						<xsl:if test="string-length($OperationalHours) gt 0">
							<codeWorkHr><xsl:value-of select="$OperationalHours"/></codeWorkHr>
						</xsl:if>
						<xsl:if test="string-length($DME_effective_date) gt 0">
							<dtWef><xsl:value-of select="$DME_effective_date"/></dtWef>
						</xsl:if>
						<xsl:if test="string-length($originator) gt 0">
							<OrgCre>
								<txtName><xsl:value-of select="$originator"/></txtName>
							</OrgCre>
						</xsl:if>
					</Record>
					
				</xsl:for-each>
				
			</SdoReportResult>
		</SdoReportResponse>
		
	</xsl:template>
	
</xsl:transform>