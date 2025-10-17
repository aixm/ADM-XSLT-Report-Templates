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
										featureTypes: aixm:DME aixm:Navaid
	includeReferencedFeaturesLevel: 2
							 permanentBaseline: true
											 dataScope: ReleasedData
										 AIXMversion: 5.1.1
-->

<!--
	Coordinates formatting:
	======================
	Latitude and Longitude coordinates format is by default Degrees Minutes Seconds with two decimals for Seconds.
	The number of decimals can be selected by changing the value of 'coordinates_decimal_number' to the desired number of decimals.
	The format of coordinates displayed can be chosen between DMS or Decimal Degrees by changing the value of 'coordinates_type' to 'DMS' or 'DEC'.
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
	xmlns:fcn="local-function"
	xmlns:ead-audit="http://www.aixm.aero/schema/5.1.1/extensions/EUR/iNM/EAD-Audit"
	exclude-result-prefixes="xsl uuid message gts gco xsd gml gss gsr gmd aixm event xlink xs xsi aixm_ds_xslt fcn ead-audit">
	
	<xsl:output method="xml" indent="yes"/>
	
	<xsl:strip-space elements="*"/>
	
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
	
	<!-- Format latitude coordinate -->
	<xsl:function name="fcn:format-latitude" as="xs:string">
		<xsl:param name="lat_decimal" as="xs:double"/>
		<xsl:param name="coord_type" as="xs:string"/>
		<xsl:param name="decimal_places" as="xs:integer"/>
		<xsl:choose>
			<xsl:when test="$coord_type = 'DEC'">
				<!-- Decimal degrees format -->
				<xsl:variable name="format-string" select="concat('0.', string-join(for $i in 1 to $decimal_places return '0', ''))"/>
				<xsl:value-of select="format-number($lat_decimal, $format-string)"/>
			</xsl:when>
			<xsl:when test="$coord_type = 'DMS'">
				<!-- Degrees Minutes Seconds format -->
				<xsl:variable name="abs_lat" select="abs($lat_decimal)"/>
				<xsl:variable name="degrees" select="floor($abs_lat)"/>
				<xsl:variable name="minutes_decimal" select="($abs_lat - $degrees) * 60"/>
				<xsl:variable name="minutes" select="floor($minutes_decimal)"/>
				<xsl:variable name="seconds" select="($minutes_decimal - $minutes) * 60"/>
				<xsl:variable name="format-string" select="concat('00.', string-join(for $i in 1 to $decimal_places return '0', ''))"/>
				<xsl:value-of select="concat(
					format-number($degrees, '00'),
					format-number($minutes, '00'),
					format-number($seconds, $format-string),
					if ($lat_decimal ge 0) then 'N' else 'S')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="string($lat_decimal)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- Format longitude coordinate -->
	<xsl:function name="fcn:format-longitude" as="xs:string">
		<xsl:param name="lon_decimal" as="xs:double"/>
		<xsl:param name="coord_type" as="xs:string"/>
		<xsl:param name="decimal_places" as="xs:integer"/>
		<xsl:choose>
			<xsl:when test="$coord_type = 'DEC'">
				<!-- Decimal degrees format -->
				<xsl:variable name="format-string" select="concat('0.', string-join(for $i in 1 to $decimal_places return '0', ''))"/>
				<xsl:value-of select="format-number($lon_decimal, $format-string)"/>
			</xsl:when>
			<xsl:when test="$coord_type = 'DMS'">
				<!-- Degrees Minutes Seconds format: dddmmss.ssP -->
				<xsl:variable name="abs_lon" select="abs($lon_decimal)"/>
				<xsl:variable name="degrees" select="floor($abs_lon)"/>
				<xsl:variable name="minutes_decimal" select="($abs_lon - $degrees) * 60"/>
				<xsl:variable name="minutes" select="floor($minutes_decimal)"/>
				<xsl:variable name="seconds" select="($minutes_decimal - $minutes) * 60"/>
				<xsl:variable name="format-string" select="concat('00.', string-join(for $i in 1 to $decimal_places return '0', ''))"/>
				<xsl:value-of select="concat(
					format-number($degrees, '000'),
					format-number($minutes, '00'),
					format-number($seconds, $format-string),
					if ($lon_decimal ge 0) then 'E' else 'W')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="string($lon_decimal)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- Function to format working hours -->
	<xsl:function name="fcn:format-working-hours" as="xs:string">
		<xsl:param name="availability-elements" as="element()*"/>
		<xsl:variable name="result">
			<xsl:choose>
				<!-- if there is at least one availability element -->
				<xsl:when test="count($availability-elements) ge 1">
					<xsl:for-each select="$availability-elements">
						<xsl:choose>
							<!-- insert 'H24' if there is an availability with operationalStatus='OPERATIONAL' and no Timesheet -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and not(aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HX') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HO') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'NOTAM') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HOL') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SS') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SR') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'MON') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'TUE') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'WED') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'THU') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'FRI') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SAT') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SUN')]]) and aixm:operationalStatus = 'OPERATIONAL'">
								<xsl:value-of select="'H24'"/>
							</xsl:when>
							<!-- insert 'H24' if there is an availability with operationalStatus='OPERATIONAL' and a continuous service 24/7 Timesheet -->
							<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and (not(aixm:dayTil) or aixm:dayTil/@xsi:nil='true' or aixm:dayTil='ANY') and aixm:startTime='00:00' and aixm:endTime=('00:00','23:59','24:00') and (aixm:daylightSavingAdjust=('NO','YES') or aixm:daylightSavingAdjust/@xsi:nil='true' or not(aixm:daylightSavingAdjust)) and ((aixm:startDate='01-01' and aixm:endDate='31-12') or ((not(aixm:startDate) or aixm:startDate/@xsi:nil='true') and (not(aixm:endDate) or aixm:endDate/@xsi:nil='true'))) and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
								<xsl:value-of select="'H24'"/>
							</xsl:when>
							<!-- insert 'HJ' if there is an availability with operationalStatus='OPERATIONAL' and a sunrise to sunset Timesheet -->
							<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SR' and aixm:endEvent='SS' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@xsi:nil='true') and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
								<xsl:value-of select="'HJ'"/>
							</xsl:when>
							<!-- insert 'HN' if there is an availability with operationalStatus='OPERATIONAL' and a sunset to sunrise Timesheet -->
							<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SS' and aixm:endEvent='SR' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@xsi:nil='true') and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
								<xsl:value-of select="'HN'"/>
							</xsl:when>
							<!-- insert 'HX' if there is an availability with operationalStatus='OPERATIONAL', no Timesheet and corresponding note -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'HX')] and aixm:operationalStatus = 'OPERATIONAL'">
								<xsl:value-of select="'HX'"/>
							</xsl:when>
							<!-- insert 'HO' if there is an availability with operationalStatus='OPERATIONAL', no Timesheet and corresponding note -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'HO')] and aixm:operationalStatus = 'OPERATIONAL'">
								<xsl:value-of select="'HO'"/>
							</xsl:when>
							<!-- insert 'NOTAM' if there is an availability with operationalStatus='OPERATIONAL', no Timesheet and corresponding note -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'notam') and not(contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'outside'))]">
								<xsl:value-of select="'NOTAM'"/>
							</xsl:when>
							<!-- insert 'U/S' if there is an availability with operationalStatus='UNSERVICEABLE' and no Timesheet -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and aixm:operationalStatus = 'UNSERVICEABLE'">
								<xsl:value-of select="'U/S'"/>
							</xsl:when>
							<!-- insert nil reason if provided -->
							<xsl:when test="aixm:timeInterval/@xsi:nil='true' and aixm:timeInterval/@nilReason">
								<xsl:value-of select="concat('NIL:', aixm:timeInterval/@nilReason)"/>
							</xsl:when>
							<xsl:otherwise>
								<!-- for days of the week special days schedules  -->
								<xsl:for-each-group select="aixm:timeInterval/aixm:Timesheet[aixm:day = ('ANY','MON','TUE','WED','THU','FRI','SAT','SUN','WORK_DAY','BEF_WORK_DAY','AFT_WORK_DAY','HOL','BEF_HOL','AFT_HOL','BUSY_FRI')]" group-by="if (aixm:dayTil and (not(aixm:dayTil/@xsi:nil) or aixm:dayTil/@xsi:nil!='true')) then concat(aixm:day, '-', aixm:dayTil) else aixm:day">
									<dayInterval days="{current-grouping-key()}">
										<xsl:variable name="day" select="if (aixm:day = 'ANY') then 'ANY_DAY' else aixm:day"/>
										<xsl:variable name="day_til" select="if (aixm:dayTil = 'ANY') then 'ANY_DAY' else aixm:dayTil"/>
										<xsl:variable name="day_group" select="if (aixm:dayTil and (not(aixm:dayTil/@xsi:nil) or aixm:dayTil/@xsi:nil!='true')) then if (aixm:dayTil = aixm:day) then $day else concat($day, '-', $day_til) else $day"/>
										<xsl:value-of select="if (aixm:excluded and (not(aixm:excluded/@xsi:nil) or aixm:excluded/@xsi:nil!='true') and aixm:excluded = 'NO') then concat($day_group, ' ') else concat('exc ', $day_group, ' ')"/>
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
												if (aixm:startDate and ((not(aixm:startDate/@xsi:nil) or aixm:startDate/@xsi:nil!='true')) and (aixm:endDate and (not(aixm:endDate/@xsi:nil) or aixm:endDate/@xsi:nil!='true'))) then concat($start_date, '-', $end_date, ' ') else '',
												if (not(aixm:startTime/@xsi:nil) or aixm:startTime/@xsi:nil!='true') then $start_time else '',
												if (aixm:daylightSavingAdjust = 'YES' and (aixm:startEvent and ((not(aixm:startEvent/@xsi:nil) or aixm:startEvent/@xsi:nil!='true')) or (aixm:endEvent and (not(aixm:endEvent/@xsi:nil) or aixm:endEvent/@xsi:nil!='true'))) and (aixm:startTime and (not(aixm:startTime/@xsi:nil) or aixm:startTime/@xsi:nil!='true'))) then concat('(', $start_time_DST, ')') else '',
												if (aixm:startEvent and (not(aixm:startEvent/@xsi:nil) or aixm:startEvent/@xsi:nil!='true')) then if (aixm:startTime and (not(aixm:startTime/@xsi:nil) or aixm:startTime/@xsi:nil!='true')) then concat('/',aixm:startEvent) else aixm:startEvent else '',
												if ((aixm:startEvent and (not(aixm:startEvent/@xsi:nil) or aixm:startEvent/@xsi:nil!='true')) and (aixm:startTimeRelativeEvent and (not(aixm:startTimeRelativeEvent/@xsi:nil) or aixm:startTimeRelativeEvent/@xsi:nil!='true'))) then if (contains(aixm:startTimeRelativeEvent, '+')) then concat('plus', substring-after(aixm:startTimeRelativeEvent, '+'), aixm:startTimeRelativeEvent/@uom) else if (number(aixm:startTimeRelativeEvent) ge 0) then concat('plus', aixm:startTimeRelativeEvent, aixm:startTimeRelativeEvent/@uom) else concat('minus', substring-after(aixm:startTimeRelativeEvent, '-'), aixm:startTimeRelativeEvent/@uom) else '',
												if (aixm:startEventInterpretation and (not(aixm:startEventInterpretation/@xsi:nil) or aixm:startEventInterpretation/@xsi:nil!='true')) then concat('(', aixm:startEventInterpretation, ')') else '',
												'-',
												if (aixm:endTime and (not(aixm:endTime/@xsi:nil) or aixm:endTime/@xsi:nil!='true')) then $end_time else '',
												if (aixm:daylightSavingAdjust = 'YES' and (aixm:startEvent and ((not(aixm:startEvent/@xsi:nil) or aixm:startEvent/@xsi:nil!='true')) or (aixm:endEvent and (not(aixm:endEvent/@xsi:nil) or aixm:endEvent/@xsi:nil!='true'))) and (aixm:endTime and (not(aixm:endTime/@xsi:nil) or aixm:endTime/@xsi:nil!='true'))) then concat('(', $end_time_DST, ')') else '',
												if (aixm:endEvent and (not(aixm:endEvent/@xsi:nil) or aixm:endEvent/@xsi:nil!='true')) then if (aixm:endTime and (not(aixm:endTime/@xsi:nil) or aixm:endTime/@xsi:nil!='true')) then concat('/',aixm:endEvent) else aixm:endEvent else '',
												if ((aixm:endEvent and (not(aixm:endEvent/@xsi:nil) or aixm:endEvent/@xsi:nil!='true')) and (aixm:endTimeRelativeEvent and (not(aixm:endTimeRelativeEvent/@xsi:nil) or aixm:endTimeRelativeEvent/@xsi:nil!='true'))) then if (contains(aixm:endTimeRelativeEvent, '+')) then concat('plus', substring-after(aixm:endTimeRelativeEvent, '+'), aixm:endTimeRelativeEvent/@uom) else if (number(aixm:endTimeRelativeEvent) ge 0) then concat('plus', aixm:endTimeRelativeEvent, aixm:endTimeRelativeEvent/@uom) else concat('minus', substring-after(aixm:endTimeRelativeEvent, '-'), aixm:endTimeRelativeEvent/@uom) else '',
												if (aixm:startEvent and (not(aixm:startEvent) and not(aixm:endEvent)) and aixm:daylightSavingAdjust = 'YES') then concat(' (', $start_time_DST, '-', $end_time_DST, ')') else '')"/>
											<xsl:if test="position() != last()"><xsl:text> </xsl:text></xsl:if>
										</xsl:for-each>
										<xsl:if test="position() != last()"><xsl:text>&#10;</xsl:text></xsl:if>
									</dayInterval>
								</xsl:for-each-group>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:sequence select="string($result)"/>
	</xsl:function>
	
	<xsl:template match="/">
		
		<SdoReportResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="SdoReportMgmt.xsd" origin="SDO" version="4.1">
			<SdoReportResult>
				
				<xsl:for-each select="//aixm:DME">
					
					<xsl:sort select="(aixm:timeSlice/aixm:DMETimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:DMETimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)][aixm:correctionNumber = max(../aixm:DMETimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:DMETimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)]/aixm:correctionNumber)])[1]/aixm:designator" order="ascending"/>
					<!-- Get all BASELINE time slices for this feature -->
					<xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:DMETimeSlice[aixm:interpretation = 'BASELINE']"/>
					<!-- Find the maximum sequenceNumber -->
					<xsl:variable name="max-sequence" select="max($baseline-timeslices/aixm:sequenceNumber)"/>
					<!-- Get time slices with the maximum sequenceNumber, then find max correctionNumber -->
					<xsl:variable name="max-correction" select="max($baseline-timeslices[aixm:sequenceNumber = $max-sequence]/aixm:correctionNumber)"/>
					<!-- Select the latest time slice -->
					<xsl:variable name="latest-timeslice" select="$baseline-timeslices[aixm:sequenceNumber = $max-sequence and aixm:correctionNumber = $max-correction][1]"/>
					
					<xsl:for-each select="$latest-timeslice">
						
						<!-- Master gUID -->
						<xsl:variable name="DME_UUID" select="../../gml:identifier"/>
						
						<!-- DME - Valid TimeSlice -->
						<xsl:variable name="DME_timeslice" select="concat('BASELINE ', $max-sequence, '.', $max-correction)"/>
						
						<!-- Identification -->
						<xsl:variable name="DME_designator">
							<xsl:choose>
								<xsl:when test="not(aixm:designator)">
									<xsl:value-of select="''"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="fcn:insert-value(aixm:designator)"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						
						<!-- Name -->
						<xsl:variable name="DME_name">
							<xsl:choose>
								<xsl:when test="not(aixm:name)">
									<xsl:value-of select="''"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="fcn:insert-value(aixm:name)"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						
						<!-- Responsible State -->
						<xsl:variable name="OrgAuth_UUID" select="replace(aixm:authority/aixm:AuthorityForNavaidEquipment/aixm:theOrganisationAuthority/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
						<xsl:variable name="org-baseline-ts" select="//aixm:OrganisationAuthority[gml:identifier = $OrgAuth_UUID]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice[aixm:interpretation = 'BASELINE']"/>
						<xsl:variable name="org-max-seq" select="max($org-baseline-ts/aixm:sequenceNumber)"/>
						<xsl:variable name="org-max-corr" select="max($org-baseline-ts[aixm:sequenceNumber = $org-max-seq]/aixm:correctionNumber)"/>
						<xsl:variable name="org-latest-ts" select="$org-baseline-ts[aixm:sequenceNumber = $org-max-seq and aixm:correctionNumber = $org-max-corr][1]"/>
						<xsl:variable name="OwnerOrg_UUID" select="replace($org-latest-ts/aixm:relatedOrganisationAuthority/aixm:OrganisationAuthorityAssociation/aixm:theOrganisationAuthority/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
						<xsl:variable name="owner-baseline-ts" select="//aixm:OrganisationAuthority[gml:identifier = $OwnerOrg_UUID]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice[aixm:interpretation = 'BASELINE']"/>
						<xsl:variable name="owner-max-seq" select="max($owner-baseline-ts/aixm:sequenceNumber)"/>
						<xsl:variable name="owner-max-corr" select="max($owner-baseline-ts[aixm:sequenceNumber = $owner-max-seq]/aixm:correctionNumber)"/>
						<xsl:variable name="owner-latest-ts" select="$owner-baseline-ts[aixm:sequenceNumber = $owner-max-seq and aixm:correctionNumber = $owner-max-corr][1]"/>
						<xsl:variable name="ResponsibleState">
							<xsl:choose>
								<xsl:when test="$org-latest-ts/aixm:type = 'STATE'">
									<xsl:value-of select="$org-latest-ts/aixm:name"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$owner-latest-ts/aixm:name"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						
						<!-- Responsible State - Valid TimeSlice -->
						<xsl:variable name="ResponsibleState_timeslice">
							<xsl:choose>
								<xsl:when test="$ResponsibleState">
									<xsl:choose>
										<xsl:when test="$org-latest-ts/aixm:type = 'STATE'">
											<xsl:value-of select="concat('BASELINE ', $org-max-seq, '.', $org-max-corr)"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="concat('BASELINE ', $owner-max-seq, '.', $owner-max-corr)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="''"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						
						<!-- Coordinates -->
						
						<!-- Select the type of coordinates: 'DMS' or 'DEC' -->
						<xsl:variable name="coordinates_type" select="'DMS'"/>
						
						<!-- Select the number of decimals -->
						<xsl:variable name="coordinates_decimal_number" select="2"/>
						
						<xsl:variable name="coordinates" select="aixm:location/aixm:ElevatedPoint/gml:pos"/>
						<xsl:variable name="latitude_decimal" select="number(substring-before($coordinates, ' '))"/>
						<xsl:variable name="longitude_decimal" select="number(substring-after($coordinates, ' '))"/>
						<xsl:variable name="DME_lat">
							<xsl:value-of select="fcn:format-latitude($latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
						</xsl:variable>
						<xsl:variable name="DME_long">
							<xsl:value-of select="fcn:format-longitude($longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
						</xsl:variable>
						
						<!-- Collocated VOR - Identification -->
						<!-- Find the Navaid with type='VOR_DME' that references this DME -->
						<xsl:variable name="collocated_VOR_UUID">
							<xsl:for-each select="//aixm:Navaid[.//aixm:type = 'VOR_DME' and .//aixm:navaidEquipment/aixm:NavaidComponent/aixm:theNavaidEquipment/@xlink:href = concat('urn:uuid:', $DME_UUID)]">
								<xsl:variable name="navaid-baseline-ts" select="aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="navaid-max-seq" select="max($navaid-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="navaid-max-corr" select="max($navaid-baseline-ts[aixm:sequenceNumber = $navaid-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="navaid-latest-ts" select="$navaid-baseline-ts[aixm:sequenceNumber = $navaid-max-seq and aixm:correctionNumber = $navaid-max-corr][1]"/>
								<!-- Find the specific xlink:href that references an aixm:VOR -->
								<xsl:for-each select="$navaid-latest-ts/aixm:navaidEquipment">
									<xsl:variable name="Xlink_UUID" select="replace(aixm:NavaidComponent/aixm:theNavaidEquipment/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
									<xsl:if test="//aixm:VOR[gml:identifier = $Xlink_UUID]">
										<xsl:value-of select="$Xlink_UUID"/>
									</xsl:if>
								</xsl:for-each>
							</xsl:for-each>
						</xsl:variable>
						<!-- Get the valid TimeSLice of the VOR and its designator -->
						<xsl:variable name="VOR-feature" select="//aixm:VOR[gml:identifier = $collocated_VOR_UUID]"/>
						<xsl:variable name="VOR-baseline-ts" select="$VOR-feature/aixm:timeSlice/aixm:VORTimeSlice[aixm:interpretation = 'BASELINE']"/>
						<xsl:variable name="VOR-max-seq" select="max($VOR-baseline-ts/aixm:sequenceNumber)"/>
						<xsl:variable name="VOR-max-corr" select="max($VOR-baseline-ts[aixm:sequenceNumber = $VOR-max-seq]/aixm:correctionNumber)"/>
						<xsl:variable name="VOR-latest-ts" select="$VOR-baseline-ts[aixm:sequenceNumber = $VOR-max-seq and aixm:correctionNumber = $VOR-max-corr][1]"/>
						<xsl:variable name="collocated_VOR_designator">
							<xsl:choose>
								<xsl:when test="not($VOR-latest-ts/aixm:designator)">
									<xsl:value-of select="''"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="fcn:insert-value($VOR-latest-ts/aixm:designator)"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						
						<!-- Collocated VOR - Valid TimeSlice -->
						<xsl:variable name="collocated_VOR_timeslice">
							<xsl:choose>
								<xsl:when test="$collocated_VOR_designator != ''">
									<xsl:value-of select="concat('BASELINE ', $VOR-max-seq, '.', $VOR-max-corr)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="''"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						
						<!-- Channel -->
						<xsl:variable name="DME_channel">
							<xsl:choose>
								<xsl:when test="not(aixm:channel)">
									<xsl:value-of select="''"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="fcn:insert-value(aixm:channel)"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						
						<!-- Frequency of virtual VHF facility -->
						<xsl:variable name="DME_virtual_freq">
							<xsl:choose>
								<xsl:when test="not(aixm:ghostFrequency)">
									<xsl:value-of select="''"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="fcn:insert-value(aixm:ghostFrequency)"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
						
						<!-- UOM -->
						<xsl:variable name="DME_virtual_freq_uom" select="aixm:ghostFrequency/@uom"/>
						
						<!-- Datum -->
						<xsl:variable name="DME_datum" select="concat(substring(aixm:location/aixm:ElevatedPoint/@srsName, 17,5), substring(aixm:location/aixm:ElevatedPoint/@srsName, 23,4))"/>
						
						<!-- Working hours -->
						<xsl:variable name="DME_working_hours">
							<xsl:choose>
								<!-- Check if DME has at least one availability (excluding xsi:nil='true') -->
								<xsl:when test="aixm:availability[not(@xsi:nil='true')]">
									<xsl:value-of select="fcn:format-working-hours(aixm:availability/aixm:NavaidOperationalStatus)"/>
								</xsl:when>
								<!-- Check if corresponding Navaid has at least one availability (excluding xsi:nil='true') -->
								<xsl:otherwise>
									<!-- Find the Navaid that references this DME -->
									<xsl:variable name="navaid-with-dme" select="//aixm:Navaid[.//aixm:navaidEquipment/aixm:NavaidComponent/aixm:theNavaidEquipment/@xlink:href = concat('urn:uuid:', $DME_UUID)]"/>
									<xsl:variable name="navaid-baseline-ts" select="$navaid-with-dme/aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE']"/>
									<xsl:variable name="navaid-max-seq" select="max($navaid-baseline-ts/aixm:sequenceNumber)"/>
									<xsl:variable name="navaid-max-corr" select="max($navaid-baseline-ts[aixm:sequenceNumber = $navaid-max-seq]/aixm:correctionNumber)"/>
									<xsl:variable name="navaid-latest-ts" select="$navaid-baseline-ts[aixm:sequenceNumber = $navaid-max-seq and aixm:correctionNumber = $navaid-max-corr][1]"/>
									<xsl:choose>
										<!-- If Navaid has at least one availability (excluding xsi:nil='true') -->
										<xsl:when test="$navaid-latest-ts/aixm:availability[not(@xsi:nil='true')]">
											<xsl:value-of select="concat('(from Navaid)&#10;', fcn:format-working-hours($navaid-latest-ts/aixm:availability/aixm:NavaidOperationalStatus))"/>
										</xsl:when>
										<!-- If both DME and Navaid have no availability (or only with xsi:nil='true'), check if DME has xsi:nil='true' -->
										<xsl:otherwise>
											<xsl:choose>
												<xsl:when test="aixm:availability[@xsi:nil='true']">
													<xsl:value-of select="fcn:insert-value(aixm:availability)"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="''"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:otherwise>
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
									<txtRmk><xsl:value-of select="concat('Valid TimeSlice: ', $ResponsibleState_timeslice)"/></txtRmk>
								</Org>
							</xsl:if>
							<xsl:if test="string-length($DME_lat) gt 0">
								<geoLat><xsl:value-of select="$DME_lat"/></geoLat>
							</xsl:if>
							<xsl:if test="string-length($DME_long) gt 0">
								<geoLong><xsl:value-of select="$DME_long"/></geoLong>
							</xsl:if>
							<xsl:if test="string-length($collocated_VOR_designator) gt 0">
								<Vor>
									<codeId><xsl:value-of select="$collocated_VOR_designator"/></codeId>
									<txtRmk><xsl:value-of select="concat('Valid TimeSlice: ', $collocated_VOR_timeslice)"/></txtRmk>
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
							<xsl:if test="string-length($DME_working_hours) gt 0">
								<codeWorkHr><xsl:value-of select="$DME_working_hours"/></codeWorkHr>
							</xsl:if>
							<xsl:if test="string-length($DME_effective_date) gt 0">
								<dtWef><xsl:value-of select="$DME_effective_date"/></dtWef>
							</xsl:if>
							<xsl:if test="string-length($originator) gt 0">
								<OrgCre>
									<txtName><xsl:value-of select="$originator"/></txtName>
								</OrgCre>
							</xsl:if>
							<xsl:if test="string-length($DME_timeslice) gt 0">
								<txtRmk><xsl:value-of select="concat('DME - Valid TimeSlice', $DME_timeslice)"/></txtRmk>
							</xsl:if>
						</Record>
						
					</xsl:for-each>
					
				</xsl:for-each>
				
			</SdoReportResult>
		</SdoReportResponse>
		
	</xsl:template>
	
</xsl:transform>