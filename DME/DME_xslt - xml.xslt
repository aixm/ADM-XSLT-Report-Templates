<?xml version="1.0" encoding="UTF-8"?>
<!-- ==================================================================== -->
<!-- XSLT script for iNM eEAD -->
<!-- source: https://github.com/aixm/ADM-XSLT-Report-Templates -->
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
				
				<xsl:for-each select="//aixm:DME">
					<Record>
						
						<!-- Master gUID -->
						<xsl:variable name="DME_UUID" select="gml:identifier"/>
						<xsl:if test="not(empty($DME_UUID))">
							<mid><xsl:value-of select="$DME_UUID"/></mid>
						</xsl:if>
						
						<!-- Identification -->
						<xsl:variable name="identification" select=".//aixm:designator"/>
						<xsl:if test="not(empty($identification))">
							<codeId><xsl:value-of select="$identification"/></codeId>
						</xsl:if>
						
						<!-- Name -->
						<xsl:variable name="name" select=".//aixm:name"/>
						<xsl:if test="not(empty($name))">
							<txtName><xsl:value-of select="$name"/></txtName>
						</xsl:if>
						
						<!-- Responsible State -->
						<xsl:variable name="OrgAuthUUID" select="aixm:timeSlice/aixm:DMETimeSlice/aixm:authority/aixm:AuthorityForNavaidEquipment/aixm:theOrganisationAuthority/@xlink:href"/>
						<xsl:variable name="ResponsibleStateUUID" select="//aixm:OrganisationAuthority[gml:identifier = substring-after($OrgAuthUUID, 'urn:uuid:')]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice/aixm:relatedOrganisationAuthority/aixm:OrganisationAuthorityAssociation/aixm:theOrganisationAuthority/@xlink:href"/>
						<xsl:variable name="ResponsibleState" select="//aixm:OrganisationAuthority[gml:identifier = substring-after($ResponsibleStateUUID, 'urn:uuid:')]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice/aixm:name"/>
						<xsl:if test="not(empty($ResponsibleState))">
							<Org>
								<txtName><xsl:value-of select="$ResponsibleState"/></txtName>
							</Org>
						</xsl:if>
						
						<!-- Getting the coordinates -->
						<xsl:variable name="coordinates" select=".//aixm:location/aixm:ElevatedPoint/gml:pos"/> <!-- example: '8.12494892 7.28059844' -->
						<xsl:variable name="latitude" select="number(substring-before($coordinates, ' '))"/> <!-- 8.12494892 -->
						<xsl:variable name="longitude" select="number(substring-after($coordinates, ' '))"/> <!-- 7.28059844 -->
						
						<!-- Conversion of latitude from decimal degrees to Degrees Minutes Seconds -->
						<xsl:variable name="lat_whole" select="string(floor(abs($latitude)))"/> 																																										<!-- degrees of latitude whole part: (8.12494892) = 8 -->
						<xsl:variable name="lat_frac" select="string(abs($latitude) - floor(abs($latitude)))"/> 																																		<!-- degrees of latitude fractionary part: 8.12494892 - 8 = 0.12494892 -->
						<xsl:variable name="lat_deg" select="if (string-length($lat_whole) = 1) then concat('0', $lat_whole) else $lat_whole"/> 																		<!-- degrees of latitude: 08 (prefixing one '0' if necessary) -->
						<xsl:variable name="lat_min_whole" select="floor(number($lat_frac) * 60)"/> 																																								<!-- minutes of latitude: 7 (whole part of 0.12494892*60 = 7.4969352) -->
						<xsl:variable name="lat_min_frac" select="number($lat_frac) * 60 - $lat_min_whole"/> 																																			 <!-- fractionary part of minutes of latitude: 7.4969352 - 7 = 0.4969352 -->
						<xsl:variable name="lat_min" select="if (string-length(string($lat_min_whole)) = 1) then concat('0', string($lat_min_whole)) else string($lat_min_whole)"/> <!-- minutes of latitude: 07 (prefixing one '0' if necessary) -->
						<xsl:variable name="lat_sec" select="format-number($lat_min_frac * 60, '0.00')"/> 																																					<!-- seconds of latitude: 0.4969352 * 60 = 29.82 (formatted with two decimals)-->
						<xsl:variable name="lat_sec" select="if (string-length(string($lat_sec)) = 1) then concat('0', string($lat_sec)) else string($lat_sec)"/> 									<!-- seconds of latitude: 29.82 (prefixing one '0' if necessary)-->
						<xsl:variable name="lat_DMS" select="concat($lat_deg, $lat_min, $lat_sec, if ($latitude ge 0) then 'N' else 'S')"/> 																				<!-- suffixing 'N' for positive latitude or 'S' for negative latitude -->
						<xsl:if test="not(empty($lat_DMS))">
							<geoLat><xsl:value-of select="$lat_DMS"/></geoLat>																																																				<!-- result: 080729.82N -->
						</xsl:if>
						
						<!-- Conversion of longitude from decimal degrees to Degrees Minutes Seconds (similar procedure as for latitude) -->
						<xsl:variable name="long_whole" select="string(floor(abs($longitude)))"/>
						<xsl:variable name="long_frac" select="string(abs($longitude) - floor(abs($longitude)))"/>
						<xsl:variable name="long_deg" select="if (string-length($long_whole) != 3) then (if (string-length($long_whole) = 1) then concat('00', $long_whole) else concat('0', $long_whole)) else $long_whole"/>
						<xsl:variable name="long_min_whole" select="floor(number($long_frac) * 60)"/>
						<xsl:variable name="long_min_frac" select="number($long_frac) * 60 - $long_min_whole"/>
						<xsl:variable name="long_min" select="if (string-length(string($long_min_whole)) = 1) then concat('0', string($long_min_whole)) else string($long_min_whole)"/>
						<xsl:variable name="long_sec" select="format-number($long_min_frac * 60, '0.00')"/>
						<xsl:variable name="long_sec" select="if (string-length(string($long_sec)) = 1) then concat('0', string($long_sec)) else string($long_sec)"/>
						<xsl:variable name="long_DMS" select="concat($long_deg, $long_min, $long_sec, if ($longitude ge 0) then 'E' else 'W')"/>
						<xsl:if test="not(empty($long_DMS))">
							<geoLong><xsl:value-of select="$long_DMS"/></geoLong>
						</xsl:if>
						
						<!-- Collocated VOR identification -->
						<!-- Finding the Navaid feature with type='VOR_DME' that references this DME -->
						<xsl:for-each select="//aixm:NavaidTimeSlice[aixm:type = 'VOR_DME' and aixm:navaidEquipment/aixm:NavaidComponent/aixm:theNavaidEquipment/@xlink:href = concat('urn:uuid:', $DME_UUID)]">
							<!-- Finding the xlink:href in the Navaid feature that references the VOR and extracting its name -->
							<xsl:for-each select="aixm:navaidEquipment">
								<xsl:variable name="Xlink_UUID" select="substring-after(aixm:NavaidComponent/aixm:theNavaidEquipment/@xlink:href, 'urn:uuid:')"/>
								<xsl:variable name="VOR_UUID" select="substring-after(aixm:NavaidComponent/aixm:theNavaidEquipment/@xlink:href[$Xlink_UUID = //aixm:VOR/gml:identifier], 'urn:uuid:')"/>
								<xsl:variable name="VOR_name" select="//aixm:VOR[gml:identifier = $VOR_UUID]/aixm:timeSlice/aixm:VORTimeSlice/aixm:designator"/>
								<xsl:if test="not(empty($VOR_name))">
									<Vor>
										<codeId><xsl:value-of select="$VOR_name"/></codeId>
									</Vor>
								</xsl:if>
							</xsl:for-each>
						</xsl:for-each>
						
						<!-- Channel -->
						<xsl:variable name="channel" select=".//aixm:channel"/>
						<xsl:if test="not(empty($channel))">
							<codeChannel><xsl:value-of select="$channel"/></codeChannel>
						</xsl:if>
						
						<!-- Frequency of virtual VHF facility -->
						<xsl:variable name="GhostFreq" select=".//aixm:ghostFrequency"/>
						<xsl:if test="not(empty($GhostFreq))">
							<valGhostFreq><xsl:value-of select="$GhostFreq"/></valGhostFreq>
						</xsl:if>
						
						<!-- UOM -->
						<xsl:variable name="uomGhostFreq" select=".//aixm:ghostFrequency/@uom"/>
						<xsl:if test="not(empty($uomGhostFreq))">
							<uomGhostFreq><xsl:value-of select="$uomGhostFreq"/></uomGhostFreq>
						</xsl:if>
						
						<!-- Datum -->
						<xsl:variable name="datum" select="concat(substring(.//aixm:ElevatedPoint/@srsName, 17,5), substring(.//aixm:ElevatedPoint/@srsName, 23,4))"/>
						<xsl:if test="not(empty($datum))">
							<codeDatum><xsl:value-of select="$datum"/></codeDatum>
						</xsl:if>
						
						<!-- Working hours -->
						<xsl:variable name="OperationalHours">
							<xsl:for-each select=".//aixm:availability/aixm:NavaidOperationalStatus">
								<xsl:choose>
									<!-- insert 'H24' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL' and no aixm:Timesheet -->
									<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and not(aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:purpose='DESCRIPTION' and aixm:translatedNote/aixm:LinguisticNote[aixm:note='HX (no specific working hours)' or aixm:note='HO (service available to meet operational requests)' or aixm:note='activity periods to be published by NOTAM']]) and aixm:operationalStatus = 'OPERATIONAL'">
										<xsl:value-of select="'H24'"/>
									</xsl:when>
									<!-- insert 'H24' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL' and a continuous service 24/7 aixm:Timesheet -->
									<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:dayTil='ANY' and aixm:startTime='00:00' and (aixm:endTime='00:00' or aixm:endTime='24:00') and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
										<xsl:value-of select="'H24'"/>
									</xsl:when>
									<!-- insert 'HJ' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL' and a sunrise to sunset aixm:Timesheet -->
									<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SR' and aixm:endEvent='SS' and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
										<xsl:value-of select="'HJ'"/>
									</xsl:when>
									<!-- insert 'HN' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL' and a sunset to sunrise aixm:Timesheet -->
									<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SS' and aixm:endEvent='SR' and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
										<xsl:value-of select="'HN'"/>
									</xsl:when>
									<!-- insert 'HX' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL', no aixm:Timesheet and corresponding note -->
									<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:purpose='DESCRIPTION' and aixm:translatedNote/aixm:LinguisticNote/aixm:note='HX (no specific working hours)'] and aixm:operationalStatus = 'OPERATIONAL'">
										<xsl:value-of select="'HX'"/>
									</xsl:when>
									<!-- insert 'HO' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL', no aixm:Timesheet and corresponding note -->
									<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:purpose='DESCRIPTION' and aixm:translatedNote/aixm:LinguisticNote/aixm:note='HO (service available to meet operational requests)'] and aixm:operationalStatus = 'OPERATIONAL'">
										<xsl:value-of select="'HO'"/>
									</xsl:when>
									<!-- insert 'NOTAM' if there is an aixm:availability property with aixm:operationalStatus='OPERATIONAL', no aixm:Timesheet and corresponding note -->
									<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:purpose='DESCRIPTION' and aixm:translatedNote/aixm:LinguisticNote/aixm:note='activity periods to be published by NOTAM'] and aixm:operationalStatus = 'OPERATIONAL'">
										<xsl:value-of select="'NOTAM'"/>
									</xsl:when>
									<!-- insert 'U/S' if there is an aixm:availability property with aixm:operationalStatus='UNSERVICEABLE' and no aixm:Timesheet -->
									<xsl:when test="not(aixm:timeInterval/aixm:Timesheet) and aixm:operationalStatus = 'UNSERVICEABLE'">
										<xsl:value-of select="'U/S'"/>
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
												<xsl:value-of select="concat($start_time, '-', $end_time, $DST_time)"/>
												<xsl:if test="position() != last()">, </xsl:if>
											</xsl:if>
											<!-- aixm:daylightSavingAdjust='NO' or not present insert only time interval -->
											<xsl:if test="(aixm:daylightSavingAdjust = 'NO' or not(aixm:daylightSavingAdjust))">
												<xsl:value-of select="concat($start_time, '-', $end_time)"/>
												<xsl:if test="position() != last()"><xsl:text> </xsl:text></xsl:if>
											</xsl:if>
										</xsl:for-each>
										<!-- for days of the week schedules -->
										<xsl:for-each-group select="aixm:timeInterval/aixm:Timesheet[aixm:day = ('MON','TUE','WED','THU','FRI','SAT','SUN') and not(aixm:startEvent) and not(aixm:endEvent)]" group-by="concat(aixm:day, '-', aixm:dayTil)">
											<dayInterval days="{current-grouping-key()}">
												<xsl:value-of select="concat(aixm:day, '-', aixm:dayTil, ' ')" />
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
												<xsl:if test="position() != last()">, </xsl:if>
											</dayInterval>
										</xsl:for-each-group>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>
						</xsl:variable>
						<xsl:if test="$OperationalHours != ''">
							<codeWorkHr><xsl:value-of select="$OperationalHours"/></codeWorkHr>
						</xsl:if>
						
						<!-- Effective date (formatted as dd-MMM-yyyy)-->
						<xsl:variable name="day" select="substring(.//gml:validTime/gml:TimePeriod/gml:beginPosition, 9, 2)"/>
						<xsl:variable name="month" select="substring(.//gml:validTime/gml:TimePeriod/gml:beginPosition, 6, 2)"/>
						<xsl:variable name="month" select="if($month = '01') then 'JAN' else if ($month = '02') then 'FEB' else if ($month = '03') then 'MAR' else 
							if ($month = '04') then 'APR' else if ($month = '05') then 'MAY' else if ($month = '06') then 'JUN' else if ($month = '07') then 'JUL' else 
							if ($month = '08') then 'AUG' else if ($month = '09') then 'SEP' else if ($month = '10') then 'OCT' else if ($month = '11') then 'NOV' else 'DEC'"/>
						<xsl:variable name="year" select="substring(.//gml:validTime/gml:TimePeriod/gml:beginPosition, 1, 4)"/>
						<xsl:if test="not(empty($day)) and not(empty($month)) and not(empty($year))">
							<dtWef><xsl:value-of select="concat($day, '-', $month, '-', $year)"/></dtWef>
						</xsl:if>
						
						<!-- Originator -->
						<xsl:variable name="originator" select=".//aixm:extension/ead-audit:DMEExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
						<xsl:if test="not(empty($originator))">
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