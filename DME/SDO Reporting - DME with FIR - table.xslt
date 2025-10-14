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
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:saxon="http://saxon.sf.net/"
	exclude-result-prefixes="xsl uuid message gts gco xsd gml gss gsr gmd aixm event xlink xs xsi aixm_ds_xslt fcn ead-audit map saxon">
	
	<xsl:output method="html" indent="yes" saxon:line-length="999999"/>
	
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
							<!-- insert 'H24' if there is an availability with operationalStatus='NORMAL' and no Timesheet -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and not(aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HX') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HO') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'NOTAM') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HOL') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SS') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SR') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'MON') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'TUE') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'WED') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'THU') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'FRI') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SAT') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SUN')]]) and aixm:operationalStatus = 'OPERATIONAL'">
								<xsl:value-of select="'H24'"/>
							</xsl:when>
							<!-- insert 'H24' if there is an availability with operationalStatus='NORMAL' and a continuous service 24/7 Timesheet -->
							<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and (not(aixm:dayTil) or aixm:dayTil='ANY') and aixm:startTime='00:00' and (aixm:endTime='00:00' or aixm:endTime='24:00') and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
								<xsl:value-of select="'H24'"/>
							</xsl:when>
							<!-- insert 'HJ' if there is an availability with operationalStatus='NORMAL' and a sunrise to sunset Timesheet -->
							<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SR' and aixm:endEvent='SS' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
								<xsl:value-of select="'HJ'"/>
							</xsl:when>
							<!-- insert 'HN' if there is an availability with operationalStatus='NORMAL' and a sunset to sunrise Timesheet -->
							<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SS' and aixm:endEvent='SR' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
								<xsl:value-of select="'HN'"/>
							</xsl:when>
							<!-- insert 'HX' if there is an availability with operationalStatus='NORMAL', no Timesheet and corresponding note -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'HX')] and aixm:operationalStatus = 'OPERATIONAL'">
								<xsl:value-of select="'HX'"/>
							</xsl:when>
							<!-- insert 'HO' if there is an availability with operationalStatus='NORMAL', no Timesheet and corresponding note -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'HO')]">
								<xsl:value-of select="'HO'"/>
							</xsl:when>
							<!-- insert 'NOTAM' if there is an availability with operationalStatus='NORMAL', no Timesheet and corresponding note -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'notam') and not(contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'outside'))]">
								<xsl:value-of select="'NOTAM'"/>
							</xsl:when>
							<!-- insert 'U/S' if there is an availability with operationalStatus='CLOSED' and no Timesheet -->
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
										<xsl:if test="position() != last()"><xsl:text>&lt;br/&gt;</xsl:text></xsl:if>
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
	
	<!-- Function to extract all polygon coordinates from a geometry including referenced GeoBorders -->
	<xsl:function name="fcn:get-all-polygon-coords" as="xs:double*">
		<xsl:param name="airspace-volume" as="element()?"/>
		<xsl:param name="root" as="document-node()"/>
		<xsl:variable name="coords" as="xs:double*">
			<!-- Process curveMember elements in their actual document order to maintain polygon sequence -->
			<xsl:for-each select="$airspace-volume//gml:Ring/gml:curveMember">
				<xsl:choose>
					<!-- Handle xlink reference to GeoBorder FIRST (check before checking for posList) -->
					<xsl:when test="@xlink:href and starts-with(@xlink:href, 'urn:uuid:')">
						<xsl:variable name="uuid" select="substring-after(@xlink:href, 'urn:uuid:')"/>
						<!-- Get the GeoBorder and find its latest BASELINE timeslice -->
						<xsl:variable name="geoborder" select="$root//aixm:GeoBorder[gml:identifier = $uuid]"/>
						<xsl:variable name="gb-baseline-ts" select="$geoborder/aixm:timeSlice/aixm:GeoBorderTimeSlice[aixm:interpretation = 'BASELINE']"/>
						<xsl:variable name="gb-max-seq" select="max($gb-baseline-ts/aixm:sequenceNumber)"/>
						<xsl:variable name="gb-max-corr" select="max($gb-baseline-ts[aixm:sequenceNumber = $gb-max-seq]/aixm:correctionNumber)"/>
						<xsl:variable name="gb-latest-ts" select="$gb-baseline-ts[aixm:sequenceNumber = $gb-max-seq and aixm:correctionNumber = $gb-max-corr][1]"/>
						<!-- Extract coordinates from the latest timeslice only, preserving segment order -->
						<xsl:for-each select="$gb-latest-ts/aixm:border//gml:posList">
							<xsl:sequence select="for $coord in tokenize(normalize-space(.), '\s+') return xs:double($coord)"/>
						</xsl:for-each>
					</xsl:when>
					<!-- Handle direct coordinates (including both GeodesicString and LineStringSegment) -->
					<xsl:when test=".//gml:posList">
						<!-- Process all posList elements in this curveMember in order -->
						<xsl:for-each select=".//gml:posList">
							<xsl:sequence select="for $coord in tokenize(normalize-space(.), '\s+') return xs:double($coord)"/>
						</xsl:for-each>
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<!-- Remove consecutive duplicate coordinate pairs (degenerate edges) -->
		<xsl:variable name="epsilon" select="0.000001" as="xs:double"/>
		<xsl:variable name="deduplicated" as="xs:double*">
			<xsl:for-each select="1 to count($coords) div 2">
				<xsl:variable name="idx" select=". * 2 - 1"/>
				<xsl:variable name="lat" select="$coords[$idx]"/>
				<xsl:variable name="lon" select="$coords[$idx + 1]"/>
				<!-- Only include this point if it's different from the previous point -->
				<xsl:if test=". = 1 or abs($lat - $coords[$idx - 2]) ge $epsilon or abs($lon - $coords[$idx - 1]) ge $epsilon">
					<xsl:sequence select="$lat"/>
					<xsl:sequence select="$lon"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:sequence select="$deduplicated"/>
	</xsl:function>
	
	<!-- Function to check if a point is inside a polygon using ray-casting algorithm -->
	<!-- Uses robust handling for edge cases near polygon boundaries -->
	<xsl:function name="fcn:point-in-polygon" as="xs:boolean">
		<xsl:param name="point-lat" as="xs:double"/>
		<xsl:param name="point-lon" as="xs:double"/>
		<xsl:param name="polygon-coords" as="xs:double*"/>
		<!-- Epsilon for floating-point comparison tolerance (approximately 0.1 meters at equator) -->
		<xsl:variable name="epsilon" select="0.000001" as="xs:double"/>
		<!-- Extract lat/lon pairs from the flat array -->
		<xsl:variable name="num-coords" select="count($polygon-coords)"/>
		<xsl:variable name="num-points" select="$num-coords div 2"/>
		<xsl:choose>
			<xsl:when test="$num-points lt 3">
				<xsl:sequence select="false()"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- Check if polygon is closed (first point = last point) -->
				<xsl:variable name="is-closed" select="abs($polygon-coords[1] - $polygon-coords[$num-coords - 1]) lt $epsilon and abs($polygon-coords[2] - $polygon-coords[$num-coords]) lt $epsilon"/>
				<xsl:variable name="actual-num-points" select="if ($is-closed) then $num-points - 1 else $num-points"/>
				<!-- Ray-casting algorithm with improved edge case handling -->
				<xsl:variable name="intersections" as="xs:integer">
					<xsl:variable name="counts" as="xs:integer*">
						<xsl:for-each select="1 to xs:integer($actual-num-points)">
							<xsl:variable name="i" select="."/>
							<xsl:variable name="j" select="if ($i = $actual-num-points) then 1 else $i + 1"/>
							<xsl:variable name="lat-i" select="$polygon-coords[($i - 1) * 2 + 1]"/>
							<xsl:variable name="lon-i" select="$polygon-coords[($i - 1) * 2 + 2]"/>
							<xsl:variable name="lat-j" select="$polygon-coords[($j - 1) * 2 + 1]"/>
							<xsl:variable name="lon-j" select="$polygon-coords[($j - 1) * 2 + 2]"/>
							<!-- Standard ray-casting: check if horizontal ray from point intersects edge -->
							<!-- Edge must cross the latitude of the test point -->
							<xsl:variable name="lat-i-above" select="$lat-i gt $point-lat"/>
							<xsl:variable name="lat-j-above" select="$lat-j gt $point-lat"/>
							<xsl:choose>
								<xsl:when test="$lat-i-above != $lat-j-above">
									<!-- Calculate longitude of intersection with horizontal ray -->
									<xsl:variable name="intersect-lon" select="($lon-j - $lon-i) * ($point-lat - $lat-i) div ($lat-j - $lat-i) + $lon-i"/>
									<!-- Count if intersection is to the right of test point (with epsilon tolerance) -->
									<xsl:sequence select="if ($intersect-lon gt $point-lon - $epsilon) then 1 else 0"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:sequence select="0"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:for-each>
					</xsl:variable>
					<xsl:sequence select="sum($counts)"/>
				</xsl:variable>
				<!-- Point is inside if number of intersections is odd -->
				<xsl:sequence select="$intersections mod 2 = 1"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- Function to get the latest BASELINE timeslice for an Airspace -->
	<xsl:function name="fcn:get-latest-airspace-timeslice" as="element()?">
		<xsl:param name="airspace" as="element()?"/>
		<xsl:variable name="baseline-timeslices" select="$airspace/aixm:timeSlice/aixm:AirspaceTimeSlice[aixm:interpretation = 'BASELINE']"/>
		<xsl:variable name="max-sequence" select="max($baseline-timeslices/aixm:sequenceNumber)"/>
		<xsl:variable name="max-correction" select="max($baseline-timeslices[aixm:sequenceNumber = $max-sequence]/aixm:correctionNumber)"/>
		<xsl:sequence select="$baseline-timeslices[aixm:sequenceNumber = $max-sequence and aixm:correctionNumber = $max-correction][1]"/>
	</xsl:function>
	
	<!-- Function to find the FIR containing a given point -->
	<xsl:function name="fcn:find-containing-fir" as="map(xs:string, xs:string)?">
		<xsl:param name="lat" as="xs:double"/>
		<xsl:param name="lon" as="xs:double"/>
		<xsl:param name="root" as="document-node()"/>
		<!-- Get all FIR and FIR_P Airspaces -->
		<xsl:variable name="fir-airspaces" select="$root//aixm:Airspace[aixm:timeSlice/aixm:AirspaceTimeSlice[aixm:type = ('FIR', 'FIR_P')]]"/>
		<xsl:variable name="containing-airspaces" as="element()*">
			<xsl:for-each select="$fir-airspaces">
				<xsl:variable name="airspace" select="."/>
				<xsl:variable name="latest-ts" select="fcn:get-latest-airspace-timeslice($airspace)"/>
				<xsl:if test="$latest-ts">
					<!-- Get geometry - handle both direct geometry and contributorAirspace references -->
					<xsl:variable name="geom-components" select="$latest-ts/aixm:geometryComponent/aixm:AirspaceGeometryComponent"/>
					<xsl:for-each select="$geom-components">
						<xsl:variable name="airspace-volume" select="aixm:theAirspaceVolume/aixm:AirspaceVolume"/>
						<xsl:choose>
							<!-- Direct geometry -->
							<xsl:when test="$airspace-volume/aixm:horizontalProjection">
								<xsl:variable name="coords" select="fcn:get-all-polygon-coords($airspace-volume/aixm:horizontalProjection, $root)"/>
								<xsl:if test="count($coords) ge 6 and fcn:point-in-polygon($lat, $lon, $coords)">
									<xsl:sequence select="$airspace"/>
								</xsl:if>
							</xsl:when>
							<!-- Reference to another airspace (FIR composed of FIR_P) -->
							<xsl:when test="$airspace-volume/aixm:contributorAirspace">
								<xsl:for-each select="$airspace-volume/aixm:contributorAirspace/aixm:AirspaceVolumeDependency">
									<xsl:variable name="ref-uuid" select="substring-after(aixm:theAirspace/@xlink:href, 'urn:uuid:')"/>
									<xsl:variable name="ref-airspace" select="$root//aixm:Airspace[gml:identifier = $ref-uuid]"/>
									<xsl:variable name="ref-latest-ts" select="fcn:get-latest-airspace-timeslice($ref-airspace)"/>
									<xsl:if test="$ref-latest-ts">
										<xsl:variable name="ref-volume" select="$ref-latest-ts/aixm:geometryComponent/aixm:AirspaceGeometryComponent/aixm:theAirspaceVolume/aixm:AirspaceVolume"/>
										<xsl:variable name="ref-coords" select="fcn:get-all-polygon-coords($ref-volume/aixm:horizontalProjection, $root)"/>
										<xsl:if test="count($ref-coords) ge 6 and fcn:point-in-polygon($lat, $lon, $ref-coords)">
											<xsl:sequence select="$ref-airspace"/>
										</xsl:if>
									</xsl:if>
								</xsl:for-each>
							</xsl:when>
						</xsl:choose>
					</xsl:for-each>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<!-- Process the first containing airspace found (prefer FIR over FIR_P) -->
		<xsl:variable name="containing-airspace" select="
			if (exists($containing-airspaces)) then
			(($containing-airspaces[fcn:get-latest-airspace-timeslice(.)/aixm:type = 'FIR'])[1],
			$containing-airspaces[1])[1]
			else ()
			"/>
		<xsl:if test="$containing-airspace">
			<xsl:variable name="airspace-ts" select="fcn:get-latest-airspace-timeslice($containing-airspace)"/>
			<xsl:variable name="airspace-type" select="$airspace-ts/aixm:type"/>
			<xsl:choose>
				<!-- If it's a FIR_P, find the parent FIR -->
				<xsl:when test="$airspace-type = 'FIR_P'">
					<xsl:variable name="fir-p-uuid" select="$containing-airspace/gml:identifier"/>
					<!-- Find FIR that references this FIR_P -->
					<xsl:variable name="parent-fir" select="($root//aixm:Airspace[aixm:timeSlice/aixm:AirspaceTimeSlice[aixm:type = 'FIR' and aixm:geometryComponent/aixm:AirspaceGeometryComponent/aixm:theAirspaceVolume/aixm:AirspaceVolume/aixm:contributorAirspace/aixm:AirspaceVolumeDependency/aixm:theAirspace/@xlink:href = concat('urn:uuid:', $fir-p-uuid)]])[1]"/>
					<xsl:if test="$parent-fir">
						<xsl:variable name="parent-ts" select="fcn:get-latest-airspace-timeslice($parent-fir)"/>
						<xsl:sequence select="map{
							'designator': string($parent-ts/aixm:designator),
							'sequenceNumber': string($parent-ts/aixm:sequenceNumber),
							'correctionNumber': string($parent-ts/aixm:correctionNumber)
							}"/>
					</xsl:if>
				</xsl:when>
				<!-- If it's already a FIR, return it -->
				<xsl:when test="$airspace-type = 'FIR'">
					<xsl:sequence select="map{
						'designator': string($airspace-ts/aixm:designator),
						'sequenceNumber': string($airspace-ts/aixm:sequenceNumber),
						'correctionNumber': string($airspace-ts/aixm:correctionNumber)
						}"/>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
	</xsl:function>
	
	<xsl:template match="/">
		
		<html xmlns="http://www.w3.org/1999/xhtml">
			
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
				<meta http-equiv="Expires" content="120"/>
				<title>SDO Reporting - DME with FIR</title>
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
					<b>DME with FIR</b>
				</center>
				<hr/>
				<mark>DISCLAIMER</mark> For some features the XSLT transformation might not successfully identify the <i>FIR - Coded identifier</i>
				<hr/>
				
				<table border="0" style="border-spacing: 8px 4px">
					<tbody>
						
						<tr style="white-space:nowrap">
							<td><strong>Identification</strong></td>
							<td><strong>Latitude</strong></td>
							<td><strong>Longitude</strong></td>
							<td><strong>Responsible organisaton or authority<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Name</strong></td>
							<td><strong>Responsible organisaton or authority<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Valid TimeSlice</strong></td>
							<td><strong>Collocated VOR<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Identification</strong></td>
							<td><strong>Collocated VOR<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Latitude</strong></td>
							<td><strong>Collocated VOR<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Longitude</strong></td>
							<td><strong>Collocated VOR<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Valid TimeSlice</strong></td>
							<td><strong>Name</strong></td>
							<td><strong>Type</strong></td>
							<td><strong>Channel</strong></td>
							<td><strong>Frequency of virtual<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>VHF facility</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[frequency of virtual VHF facility]</strong></td>
							<td><strong>Value of displacement</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[displacement]</strong></td>
							<td><strong>Emission</strong></td>
							<td><strong>Datum</strong></td>
							<td><strong>Geographical accuracy</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[geographical accuracy]</strong></td>
							<td><strong>Elevation</strong></td>
							<td><strong>Elevation accuracy</strong></td>
							<td><strong>Geoid undulation</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[vertical distance]</strong></td>
							<td><strong>Cyclic redundancy check</strong></td>
							<td><strong>Vertical Datum</strong></td>
							<td><strong>Working hours</strong></td>
							<td><strong>Remark to working hours</strong></td>
							<td><strong>Remarks</strong></td>
							<td><strong>Effective date</strong></td>
							<td><strong>Committed on</strong></td>
							<td><strong>Internal UID (master)</strong></td>
							<td><strong>DME<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Valid TimeSlice</strong></td>
							<td><strong>FIR<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Coded identifier</strong></td>
							<td><strong>FIR<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Valid TimeSlice</strong></td>
							<td><strong>Originator</strong></td>
						</tr>
						
						<!-- Capture document root before iterating through DME features -->
						<xsl:variable name="doc-root" select="/" as="document-node()"/>
						
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
								
								<!-- Internal UID (master) -->
								<xsl:variable name="DME_UUID" select="../../gml:identifier"/>
								
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
								
								<!-- Coordinates -->
								
								<!-- Select the type of coordinates: 'DMS' or 'DEC' -->
								<xsl:variable name="coordinates_type" select="'DMS'"/>
								
								<!-- Select the number of decimals -->
								<xsl:variable name="coordinates_decimal_number" select="0"/>
								
								<xsl:variable name="coordinates" select="aixm:location/aixm:ElevatedPoint/gml:pos"/>
								<xsl:variable name="latitude_decimal" select="number(substring-before($coordinates, ' '))"/>
								<xsl:variable name="longitude_decimal" select="number(substring-after($coordinates, ' '))"/>
								<xsl:variable name="DME_lat">
									<xsl:value-of select="fcn:format-latitude($latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
								</xsl:variable>
								<xsl:variable name="DME_long">
									<xsl:value-of select="fcn:format-longitude($longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
								</xsl:variable>
								
								<!-- Responsible Organisation -->
								<xsl:variable name="OrgAuth_UUID" select="replace(aixm:authority/aixm:AuthorityForNavaidEquipment/aixm:theOrganisationAuthority/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<xsl:variable name="org-baseline-ts" select="//aixm:OrganisationAuthority[gml:identifier = $OrgAuth_UUID]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="org-max-seq" select="max($org-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="org-max-corr" select="max($org-baseline-ts[aixm:sequenceNumber = $org-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="org-latest-ts" select="$org-baseline-ts[aixm:sequenceNumber = $org-max-seq and aixm:correctionNumber = $org-max-corr][1]"/>
								<xsl:variable name="DME_responsible_org">
									<xsl:value-of select="$org-latest-ts/aixm:name"/>
								</xsl:variable>
								<xsl:variable name="DME_responsible_org_timeslice">
									<xsl:value-of select="concat('BASELINE ', $org-max-seq, '.', $org-max-corr)"/>
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
								
								<!-- Collocated VOR - coordinates -->
								<xsl:variable name="coordinates" select="$VOR-latest-ts/aixm:location/aixm:ElevatedPoint/gml:pos"/>
								<xsl:variable name="latitude_decimal">
									<xsl:if test="string-length($coordinates) gt 0">
										<xsl:value-of select="number(substring-before($coordinates, ' '))"/>
									</xsl:if>
								</xsl:variable>
								<xsl:variable name="longitude_decimal">
									<xsl:if test="string-length($coordinates) gt 0">
										<xsl:value-of select="number(substring-after($coordinates, ' '))"/>
									</xsl:if>
								</xsl:variable>
								<xsl:variable name="collocated_VOR_lat">
									<xsl:if test="string-length($coordinates) gt 0">
										<xsl:value-of select="fcn:format-latitude($latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
								</xsl:variable>
								<xsl:variable name="collocated_VOR_long">
									<xsl:if test="string-length($coordinates) gt 0">
										<xsl:value-of select="fcn:format-longitude($longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
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
								
								<!-- Type -->
								<xsl:variable name="DME_type">
									<xsl:choose>
										<xsl:when test="not(aixm:type)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:type)"/>
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
								
								<!-- Unit of measurement [frequency of virtual VHF facility] -->
								<xsl:variable name="DME_virtual_freq_uom" select="aixm:ghostFrequency/@uom"/>
								
								<!-- Value of displacement -->
								<xsl:variable name="DME_displacement">
									<xsl:choose>
										<xsl:when test="not(aixm:displace)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:displace)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Unit of measurement [displacement] -->
								<xsl:variable name="DME_displacement_uom" select="aixm:displace/@uom"/>
								
								<!-- Emission -->
								<xsl:variable name="DME_emission_class">
									<xsl:choose>
										<xsl:when test="not(emissionClass)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(emissionClass)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Datum -->
								<xsl:variable name="DME_datum" select="concat(substring(aixm:location/aixm:ElevatedPoint/@srsName, 17,5), substring(aixm:location/aixm:ElevatedPoint/@srsName, 23,4))"/>
								
								<!-- Geographical accuracy -->
								<xsl:variable name="DME_horizontal_accuracy">
									<xsl:choose>
										<xsl:when test="not(aixm:location/aixm:ElevatedPoint/aixm:horizontalAccuracy)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:location/aixm:ElevatedPoint/aixm:horizontalAccuracy)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Unit of measurement [geographical accuracy] -->
								<xsl:variable name="DME_horizontal_accuracy_uom" select="aixm:location/aixm:ElevatedPoint/aixm:horizontalAccuracy/@uom"/>
								
								<!-- Elevation -->
								<xsl:variable name="DME_elevation">
									<xsl:choose>
										<xsl:when test="not(aixm:location/aixm:ElevatedPoint/aixm:elevation)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:location/aixm:ElevatedPoint/aixm:elevation)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Elevation accuracy -->
								<xsl:variable name="DME_vertical_accuracy">
									<xsl:choose>
										<xsl:when test="not(aixm:location/aixm:ElevatedPoint/aixm:verticalAccuracy)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:location/aixm:ElevatedPoint/aixm:verticalAccuracy)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Geoid undulation -->
								<xsl:variable name="DME_geoid_undulation">
									<xsl:choose>
										<xsl:when test="not(aixm:location/aixm:ElevatedPoint/aixm:geoidUndulation)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:location/aixm:ElevatedPoint/aixm:geoidUndulation)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Unit of measurement [vertical distance] -->
								<xsl:variable name="DME_vertical_distance_uom">
									<xsl:choose>
										<xsl:when test="aixm:location/aixm:ElevatedPoint/aixm:elevation/@uom">
											<xsl:value-of select="aixm:location/aixm:ElevatedPoint/aixm:elevation/@uom"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:choose>
												<xsl:when test="aixm:location/aixm:ElevatedPoint/aixm:verticalAccuracy/@uom">
													<xsl:value-of select="aixm:location/aixm:ElevatedPoint/aixm:verticalAccuracy/@uom"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:choose>
														<xsl:when test="aixm:location/aixm:ElevatedPoint/aixm:geoidUndulation/@uom">
															<xsl:value-of select="aixm:location/aixm:ElevatedPoint/aixm:geoidUndulation/@uom"/>
														</xsl:when>
													</xsl:choose>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Cyclic redundancy check -->
								<xsl:variable name="DME_CRC">
									<xsl:if test="aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note[not(@lang) or @lang=('en','eng')], 'CRC:')]/aixm:note">
										<xsl:value-of select="fcn:get-last-word(aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note[not(@lang) or @lang=('en','eng')], 'CRC:')]/aixm:note[not(@lang) or @lang=('en','eng')])"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Vertical Datum -->
								<xsl:variable name="DME_vertical_datum">
									<xsl:choose>
										<xsl:when test="not(aixm:location/aixm:ElevatedPoint/aixm:verticalDatum)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:location/aixm:ElevatedPoint/aixm:verticalDatum)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
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
													<xsl:value-of select="concat('(from Navaid)&lt;br/&gt;', fcn:format-working-hours($navaid-latest-ts/aixm:availability/aixm:NavaidOperationalStatus))"/>
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
								
								<!-- Remark to working hours -->
								<xsl:variable name="DME_working_hours_remarks">
									<xsl:for-each select=".//aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']">
										<xsl:choose>
											<xsl:when test="position() = 1">
												<xsl:value-of select="concat('(', aixm:purpose, ') ', aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')])"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="concat('&lt;br/&gt;(', aixm:purpose, ') ', aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')])"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:for-each>
								</xsl:variable>
								
								<!-- Remarks -->
								<xsl:variable name="DME_remarks">
									<xsl:variable name="dataset_creation_date" select="//aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
									<xsl:if test="string-length($dataset_creation_date) gt 0">
										<xsl:value-of select="concat('Current time: ', $dataset_creation_date)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Effective date -->
								<xsl:variable name="day" select="substring(gml:validTime/gml:TimePeriod/gml:beginPosition, 9, 2)"/>
								<xsl:variable name="month" select="substring(gml:validTime/gml:TimePeriod/gml:beginPosition, 6, 2)"/>
								<xsl:variable name="month" select="if($month = '01') then 'JAN' else if ($month = '02') then 'FEB' else if ($month = '03') then 'MAR' else 
									if ($month = '04') then 'APR' else if ($month = '05') then 'MAY' else if ($month = '06') then 'JUN' else if ($month = '07') then 'JUL' else 
									if ($month = '08') then 'AUG' else if ($month = '09') then 'SEP' else if ($month = '10') then 'OCT' else if ($month = '11') then 'NOV' else if ($month = '12') then 'DEC' else ''"/>
								<xsl:variable name="year" select="substring(gml:validTime/gml:TimePeriod/gml:beginPosition, 1, 4)"/>
								<xsl:variable name="DME_effective_date" select="concat($day, '-', $month, '-', $year)"/>
								
								<!-- Committed on -->
								<xsl:variable name="DME_commit_date">
									<xsl:if test="aixm:extension/ead-audit:DMEExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate">
										<xsl:value-of select="fcn:get-date(aixm:extension/ead-audit:DMEExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- DME - Valid TimeSlice -->
								<xsl:variable name="DME_timeslice" select="concat('BASELINE ', $max-sequence, '.', $max-correction)"/>
								
								<!-- FIR - Coded identifier -->
								<xsl:variable name="FIR_info" as="map(xs:string, xs:string)?">
									<xsl:choose>
										<xsl:when test="aixm:location/aixm:ElevatedPoint/gml:pos">
											<xsl:variable name="DME-coords" select="aixm:location/aixm:ElevatedPoint/gml:pos"/>
											<xsl:variable name="DME-lat" select="xs:double(substring-before($DME-coords, ' '))"/>
											<xsl:variable name="DME-lon" select="xs:double(substring-after($DME-coords, ' '))"/>
											<xsl:sequence select="fcn:find-containing-fir($DME-lat, $DME-lon, $doc-root)"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:sequence select="()"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="FIR_designator" select="if (exists($FIR_info) and map:contains($FIR_info, 'designator')) then string($FIR_info?designator) else ''" as="xs:string"/>
								
								<!-- FIR - Valid TimeSlice -->
								<xsl:variable name="FIR_timeslice" select="if (exists($FIR_info) and map:contains($FIR_info, 'sequenceNumber')) then concat('BASELINE ', $FIR_info?sequenceNumber, '.', $FIR_info?correctionNumber) else ''" as="xs:string"/>
								
								<!-- Originator -->
								<xsl:variable name="originator" select="aixm:extension/ead-audit:DMEExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
								
								<tr style="white-space:nowrap;vertical-align:top;">
									<td><xsl:value-of select="if (string-length($DME_designator) gt 0) then $DME_designator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_lat) gt 0) then $DME_lat else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_long) gt 0) then $DME_long else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_responsible_org) gt 0) then $DME_responsible_org else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_responsible_org_timeslice) gt 0) then $DME_responsible_org_timeslice else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($collocated_VOR_designator) gt 0) then $collocated_VOR_designator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($collocated_VOR_lat) gt 0) then $collocated_VOR_lat else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($collocated_VOR_long) gt 0) then $collocated_VOR_long else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($collocated_VOR_timeslice) gt 0) then $collocated_VOR_timeslice else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_name) gt 0) then $DME_name else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_type) gt 0) then $DME_type else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_channel) gt 0) then $DME_channel else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_virtual_freq) gt 0) then $DME_virtual_freq else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_virtual_freq_uom) gt 0) then $DME_virtual_freq_uom else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_displacement) gt 0) then $DME_displacement else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_displacement_uom) gt 0) then $DME_displacement_uom else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_emission_class) gt 0) then $DME_emission_class else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_datum) gt 0) then $DME_datum else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_horizontal_accuracy) gt 0) then $DME_horizontal_accuracy else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_horizontal_accuracy_uom) gt 0) then $DME_horizontal_accuracy_uom else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_elevation) gt 0) then $DME_elevation else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_vertical_accuracy) gt 0) then $DME_vertical_accuracy else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_geoid_undulation) gt 0) then $DME_geoid_undulation else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_vertical_distance_uom) gt 0) then $DME_vertical_distance_uom else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_CRC) gt 0) then $DME_CRC else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_vertical_datum) gt 0) then $DME_vertical_datum else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_working_hours) gt 0) then $DME_working_hours else '&#160;'" disable-output-escaping="yes"/></td>
									<td><xsl:value-of select="if (string-length($DME_working_hours_remarks) gt 0) then $DME_working_hours_remarks else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_remarks) gt 0) then $DME_remarks else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_effective_date) gt 3) then $DME_effective_date else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_commit_date) gt 0) then $DME_commit_date else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_UUID) gt 0) then $DME_UUID else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DME_timeslice) gt 0) then $DME_timeslice else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($FIR_designator) gt 0) then $FIR_designator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($FIR_timeslice) gt 0) then $FIR_timeslice else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($originator) gt 0) then $originator else '&#160;'"/></td>
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
						<td><font size="-1"><xsl:value-of select="if (string-length($arc_to_polygon) gt 0) then $arc_to_polygon else '&#160;'"/></font></td>
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