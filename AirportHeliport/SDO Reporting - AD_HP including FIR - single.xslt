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
                    featureTypes: aixm:AirportHeliport aixm:OrganisationAuthority aixm:Airspace aixm:GeoBorder
  includeReferencedFeaturesLevel: no
               featureOccurrence: aixm:Airspace.aixm:type EQUALS 'FIR' OR aixm:Airspace.aixm:type EQUALS 'FIR_P'
               permanentBaseline: true
                       dataScope: ReleasedData
              spatialFilteringBy: Airspace
                 spatialAreaUUID: *select FIR*
                 spatialOperator: Within
            spatialValueOperator: OR
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
	xmlns:ead-audit="http://www.aixm.aero/schema/5.1.1/extensions/EUR/iNM/EAD-Audit"
	xmlns:fcn="local-function"
	xmlns:math="http://www.w3.org/2005/xpath-functions/math"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:saxon="http://saxon.sf.net/"
	exclude-result-prefixes="xsl uuid message gts gco xsd gml gss gsr gmd aixm event xlink xs xsi aixm_ds_xslt ead-audit fcn math map saxon">
	
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

	<!-- Function to format working hours from AirportHeliportAvailability elements -->
	<xsl:function name="fcn:format-working-hours" as="xs:string">
		<xsl:param name="availability-elements" as="element()*"/>
		<xsl:variable name="result">
			<xsl:choose>
				<!-- if there is at least one availability element -->
				<xsl:when test="count($availability-elements) ge 1">
					<xsl:for-each select="$availability-elements">
						<xsl:choose>
							<!-- insert 'H24' if there is an availability with operationalStatus='NORMAL' and no Timesheet -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and (not(aixm:timeInterval/@nilReason) or aixm:timeInterval/@nilReason='inapplicable')) and not(aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HX') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HO') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'NOTAM') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HOL') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SS') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SR') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'MON') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'TUE') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'WED') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'THU') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'FRI') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SAT') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SUN')]]) and aixm:operationalStatus = 'NORMAL'">
								<xsl:value-of select="'H24'"/>
							</xsl:when>
							<!-- insert 'H24' if there is an availability with operationalStatus='NORMAL' and a continuous service 24/7 Timesheet -->
							<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and (not(aixm:dayTil) or aixm:dayTil/@xsi:nil='true' or aixm:dayTil='ANY') and aixm:startTime='00:00' and aixm:endTime=('00:00','23:59','24:00') and (aixm:daylightSavingAdjust=('NO','YES') or aixm:daylightSavingAdjust/@xsi:nil='true' or not(aixm:daylightSavingAdjust)) and ((aixm:startDate='01-01' and aixm:endDate='31-12') or ((not(aixm:startDate) or aixm:startDate/@xsi:nil='true') and (not(aixm:endDate) or aixm:endDate/@xsi:nil='true'))) and aixm:excluded='NO'] and aixm:operationalStatus = 'NORMAL'">
								<xsl:value-of select="'H24'"/>
							</xsl:when>
							<!-- insert 'HJ' if there is an availability with operationalStatus='NORMAL' and a sunrise to sunset Timesheet -->
							<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SR' and aixm:endEvent='SS' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@xsi:nil='true') and aixm:excluded='NO'] and aixm:operationalStatus = 'NORMAL'">
								<xsl:value-of select="'HJ'"/>
							</xsl:when>
							<!-- insert 'HN' if there is an availability with operationalStatus='NORMAL' and a sunset to sunrise Timesheet -->
							<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SS' and aixm:endEvent='SR' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@xsi:nil='true') and aixm:excluded='NO'] and aixm:operationalStatus = 'NORMAL'">
								<xsl:value-of select="'HN'"/>
							</xsl:when>
							<!-- insert 'HX' if there is an availability with operationalStatus='NORMAL', no Timesheet and corresponding note -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'HX')] and aixm:operationalStatus = 'NORMAL'">
								<xsl:value-of select="'HX'"/>
							</xsl:when>
							<!-- insert 'HO' if there is an availability with operationalStatus='NORMAL', no Timesheet and corresponding note -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'HO')] and aixm:operationalStatus = 'NORMAL'">
								<xsl:value-of select="'HO'"/>
							</xsl:when>
							<!-- insert 'NOTAM' if there is an availability with operationalStatus='NORMAL', no Timesheet and corresponding note -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'notam') and not(contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'outside'))]">
								<xsl:value-of select="'NOTAM'"/>
							</xsl:when>
							<!-- insert 'CLSD' if there is an availability with operationalStatus='CLOSED' and no Timesheet -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and aixm:operationalStatus = 'CLOSED'">
								<xsl:value-of select="'CLSD'"/>
							</xsl:when>
							<!-- insert nil reason if provided -->
							<xsl:when test="aixm:timeInterval/@xsi:nil='true' and aixm:timeInterval/@nilReason and not(aixm:timeInterval/@nilReason='inapplicable')">
								<xsl:value-of select="concat('NIL:', aixm:timeInterval/@nilReason)"/>
							</xsl:when>
							<xsl:otherwise>
								<!-- for days of the week special days schedules  -->
								<!-- First grouping: by excluded/not excluded, then by day/dayTil -->
								<xsl:for-each-group select="aixm:timeInterval/aixm:Timesheet[aixm:day = ('ANY','MON','TUE','WED','THU','FRI','SAT','SUN','WORK_DAY','BEF_WORK_DAY','AFT_WORK_DAY','HOL','BEF_HOL','AFT_HOL','BUSY_FRI')]" group-by="concat(
									if (aixm:excluded = 'YES') then 'EXCLUDED' else 'NOT_EXCLUDED',
									'|',
									if (aixm:dayTil and (not(aixm:dayTil/@xsi:nil) or aixm:dayTil/@xsi:nil!='true')) then concat(aixm:day, '-', aixm:dayTil) else aixm:day)">
									<dayInterval days="{current-grouping-key()}">
										<xsl:variable name="day" select="if (aixm:day = 'ANY') then 'ANY_DAY' else aixm:day"/>
										<xsl:variable name="day_til" select="if (aixm:dayTil = 'ANY') then 'ANY_DAY' else aixm:dayTil"/>
										<xsl:variable name="day_group" select="if (aixm:dayTil and (not(aixm:dayTil/@xsi:nil) or aixm:dayTil/@xsi:nil!='true')) then if (aixm:dayTil = aixm:day) then $day else concat($day, '-', $day_til) else $day"/>
										<xsl:value-of select="if (aixm:excluded = 'NO' or not(aixm:excluded) or aixm:excluded/@xsi:nil='true') then concat($day_group, ' ') else concat('exc ', $day_group, ' ')"/>
										<!-- Second grouping: by startDate/endDate within each day group -->
										<xsl:for-each-group select="current-group()" group-by="
											if (aixm:startDate and ((not(aixm:startDate/@xsi:nil) or aixm:startDate/@xsi:nil!='true')) and (aixm:endDate and (not(aixm:endDate/@xsi:nil) or aixm:endDate/@xsi:nil!='true')))
											then concat(aixm:startDate, '|', aixm:endDate)
											else 'NO_DATE_RANGE'">
											<!-- Output the date range once per group -->
											<xsl:variable name="has_date_range" select="current-grouping-key() != 'NO_DATE_RANGE'"/>
											<xsl:if test="$has_date_range">
												<xsl:variable name="start_date" select="if (aixm:startDate != 'SDLST' and aixm:startDate != 'EDLST') then concat(substring(aixm:startDate,1,2), '/', substring(aixm:startDate,4,2)) else aixm:startDate"/>
												<xsl:variable name="end_date" select="if (aixm:endDate != 'SDLST' and aixm:endDate != 'EDLST') then concat(substring(aixm:endDate,1,2), '/', substring(aixm:endDate,4,2)) else aixm:endDate"/>
												<xsl:value-of select="concat($start_date, '-', $end_date, ' ')"/>
											</xsl:if>
											<!-- Output all time intervals for this date range -->
											<xsl:for-each select="current-group()">
												<xsl:variable name="start_time" select="concat(substring(aixm:startTime, 1, 2), substring(aixm:startTime, 4, 2))"/>
												<xsl:variable name="end_time" select="concat(substring(aixm:endTime, 1, 2), substring(aixm:endTime, 4, 2))"/>
												<xsl:variable name="start_time_DST">
													<xsl:value-of select="concat(if (number(substring($start_time, 1, 2)) gt 0) then format-number(number(substring($start_time, 1, 2)) - 1, '00') else 23, substring($start_time, 3, 2))"/>
												</xsl:variable>
												<xsl:variable name="end_time_DST">
													<xsl:value-of select="concat(if (number(substring($end_time, 1, 2)) gt 0) then format-number(number(substring($end_time, 1, 2)) - 1, '00') else 23, substring($end_time, 3, 2))"/>
												</xsl:variable>
												<xsl:value-of select="concat(
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
													if (aixm:endEventInterpretation and (not(aixm:endEventInterpretation/@xsi:nil) or aixm:endEventInterpretation/@xsi:nil!='true')) then concat('(', aixm:endEventInterpretation, ')') else '',
													if (aixm:startEvent and (not(aixm:startEvent) and not(aixm:endEvent)) and aixm:daylightSavingAdjust = 'YES') then concat(' (', $start_time_DST, '-', $end_time_DST, ')') else '')"/>
												<xsl:if test="position() != last()"><xsl:text> </xsl:text></xsl:if>
											</xsl:for-each>
											<!-- Add separator between date range groups (within the same day group) -->
											<xsl:if test="position() != last()"><xsl:text> ; </xsl:text></xsl:if>
										</xsl:for-each-group>
										<!-- Add line break between day groups -->
										<xsl:if test="position() != last()"><xsl:text> | </xsl:text></xsl:if>
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
	
	<!-- Geodesic interpolation helper functions -->
	<!-- Haversine formula to calculate great circle distance between two points (in degrees) -->
	<xsl:function name="fcn:haversine-distance" as="xs:double">
		<xsl:param name="lat1" as="xs:double"/>
		<xsl:param name="lon1" as="xs:double"/>
		<xsl:param name="lat2" as="xs:double"/>
		<xsl:param name="lon2" as="xs:double"/>
		<xsl:variable name="pi" select="math:pi()"/>
		<xsl:variable name="lat1-rad" select="$lat1 * $pi div 180"/>
		<xsl:variable name="lat2-rad" select="$lat2 * $pi div 180"/>
		<xsl:variable name="dLat" select="($lat2 - $lat1) * $pi div 180"/>
		<xsl:variable name="dLon" select="($lon2 - $lon1) * $pi div 180"/>
		<xsl:variable name="a" select="math:sin($dLat div 2) * math:sin($dLat div 2) +
		                                math:cos($lat1-rad) * math:cos($lat2-rad) *
		                                math:sin($dLon div 2) * math:sin($dLon div 2)"/>
		<xsl:variable name="c" select="2 * math:atan2(math:sqrt($a), math:sqrt(1 - $a))"/>
		<!-- Return angular distance in degrees -->
		<xsl:sequence select="$c * 180 div $pi"/>
	</xsl:function>
	<!-- Interpolate a point along a geodesic between two points -->
	<xsl:function name="fcn:geodesic-interpolate" as="xs:double*">
		<xsl:param name="lat1" as="xs:double"/>
		<xsl:param name="lon1" as="xs:double"/>
		<xsl:param name="lat2" as="xs:double"/>
		<xsl:param name="lon2" as="xs:double"/>
		<xsl:param name="fraction" as="xs:double"/>
		<xsl:variable name="pi" select="math:pi()"/>
		<xsl:variable name="lat1-rad" select="$lat1 * $pi div 180"/>
		<xsl:variable name="lon1-rad" select="$lon1 * $pi div 180"/>
		<xsl:variable name="lat2-rad" select="$lat2 * $pi div 180"/>
		<xsl:variable name="lon2-rad" select="$lon2 * $pi div 180"/>
		<!-- Calculate angular distance -->
		<xsl:variable name="d" select="fcn:haversine-distance($lat1, $lon1, $lat2, $lon2) * $pi div 180"/>
		<!-- Handle very short distances (use linear interpolation) -->
		<xsl:choose>
			<xsl:when test="$d lt 0.00001">
				<xsl:sequence select="$lat1 + $fraction * ($lat2 - $lat1)"/>
				<xsl:sequence select="$lon1 + $fraction * ($lon2 - $lon1)"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- Spherical interpolation (slerp) -->
				<xsl:variable name="a" select="math:sin((1 - $fraction) * $d) div math:sin($d)"/>
				<xsl:variable name="b" select="math:sin($fraction * $d) div math:sin($d)"/>
				<xsl:variable name="x" select="$a * math:cos($lat1-rad) * math:cos($lon1-rad) +
				                               $b * math:cos($lat2-rad) * math:cos($lon2-rad)"/>
				<xsl:variable name="y" select="$a * math:cos($lat1-rad) * math:sin($lon1-rad) +
				                               $b * math:cos($lat2-rad) * math:sin($lon2-rad)"/>
				<xsl:variable name="z" select="$a * math:sin($lat1-rad) + $b * math:sin($lat2-rad)"/>
				<xsl:variable name="lat-result" select="math:atan2($z, math:sqrt($x * $x + $y * $y)) * 180 div $pi"/>
				<xsl:variable name="lon-result" select="math:atan2($y, $x) * 180 div $pi"/>
				<xsl:sequence select="$lat-result"/>
				<xsl:sequence select="$lon-result"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- Densify a geodesic segment by adding intermediate points -->
	<xsl:function name="fcn:densify-geodesic-segment" as="xs:double*">
		<xsl:param name="lat1" as="xs:double"/>
		<xsl:param name="lon1" as="xs:double"/>
		<xsl:param name="lat2" as="xs:double"/>
		<xsl:param name="lon2" as="xs:double"/>
		<xsl:param name="max-segment-degrees" as="xs:double"/>
		<xsl:variable name="distance" select="fcn:haversine-distance($lat1, $lon1, $lat2, $lon2)"/>
		<xsl:variable name="num-segments" select="xs:integer(ceiling($distance div $max-segment-degrees))"/>
		<xsl:choose>
			<xsl:when test="$num-segments le 1">
				<!-- No interpolation needed -->
				<xsl:sequence select="$lat1, $lon1"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- Add first point -->
				<xsl:sequence select="$lat1, $lon1"/>
				<!-- Add intermediate points -->
				<xsl:for-each select="1 to ($num-segments - 1)">
					<xsl:variable name="fraction" select=". div $num-segments"/>
					<xsl:sequence select="fcn:geodesic-interpolate($lat1, $lon1, $lat2, $lon2, $fraction)"/>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- Densify a linear segment by adding intermediate points using linear interpolation -->
	<xsl:function name="fcn:densify-linear-segment" as="xs:double*">
		<xsl:param name="lat1" as="xs:double"/>
		<xsl:param name="lon1" as="xs:double"/>
		<xsl:param name="lat2" as="xs:double"/>
		<xsl:param name="lon2" as="xs:double"/>
		<xsl:param name="max-segment-degrees" as="xs:double"/>
		<!-- Calculate simple Euclidean distance for linear interpolation -->
		<xsl:variable name="dlat" select="abs($lat2 - $lat1)"/>
		<xsl:variable name="dlon" select="abs($lon2 - $lon1)"/>
		<xsl:variable name="distance" select="math:sqrt($dlat * $dlat + $dlon * $dlon)"/>
		<xsl:variable name="num-segments" select="xs:integer(ceiling($distance div $max-segment-degrees))"/>
		<xsl:choose>
			<xsl:when test="$num-segments le 1">
				<!-- No interpolation needed -->
				<xsl:sequence select="$lat1, $lon1"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- Add first point -->
				<xsl:sequence select="$lat1, $lon1"/>
				<!-- Add intermediate points using simple linear interpolation -->
				<xsl:for-each select="1 to ($num-segments - 1)">
					<xsl:variable name="fraction" select=". div $num-segments"/>
					<xsl:sequence select="$lat1 + $fraction * ($lat2 - $lat1)"/>
					<xsl:sequence select="$lon1 + $fraction * ($lon2 - $lon1)"/>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- Find exact matching point in coords, return 1-based index or empty if not found -->
	<xsl:function name="fcn:find-exact-point-index" as="xs:integer?">
		<xsl:param name="target-lat" as="xs:double"/>
		<xsl:param name="target-lon" as="xs:double"/>
		<xsl:param name="coords" as="xs:double*"/>
		<xsl:param name="epsilon" as="xs:double"/>
		<xsl:variable name="num-points" select="count($coords) div 2"/>
		<xsl:variable name="matching-indices" as="xs:integer*">
			<xsl:for-each select="1 to xs:integer($num-points)">
				<xsl:variable name="idx" select=". * 2 - 1"/>
				<xsl:variable name="lat" select="$coords[$idx]"/>
				<xsl:variable name="lon" select="$coords[$idx + 1]"/>
				<xsl:if test="exists($lat) and exists($lon)">
					<xsl:variable name="lat-diff" select="abs($lat - $target-lat)"/>
					<xsl:variable name="lon-diff" select="abs($lon - $target-lon)"/>
					<xsl:if test="$lat-diff le $epsilon and $lon-diff le $epsilon">
						<xsl:sequence select="xs:integer(.)"/>
					</xsl:if>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:sequence select="if (count($matching-indices) gt 0) then $matching-indices[1] else ()"/>
	</xsl:function>

	<!-- Extract segment from coords between two point indices (inclusive) -->
	<xsl:function name="fcn:extract-segment" as="xs:double*">
		<xsl:param name="coords" as="xs:double*"/>
		<xsl:param name="start-index" as="xs:integer"/>
		<xsl:param name="end-index" as="xs:integer"/>
		<xsl:param name="reverse" as="xs:boolean"/>
		<xsl:choose>
			<xsl:when test="$reverse">
				<!-- Extract in reverse order from start-index down to end-index -->
				<xsl:for-each select="reverse($start-index to $end-index)">
					<xsl:variable name="idx" select=". * 2 - 1"/>
					<xsl:sequence select="$coords[$idx], $coords[$idx + 1]"/>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<!-- Extract forward from start-index to end-index -->
				<xsl:for-each select="$start-index to $end-index">
					<xsl:variable name="idx" select=". * 2 - 1"/>
					<xsl:sequence select="$coords[$idx], $coords[$idx + 1]"/>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- Helper function to merge coordinates with global deduplication -->
	<xsl:function name="fcn:merge-coords-deduplicated" as="xs:double*">
		<xsl:param name="accumulated" as="xs:double*"/>
		<xsl:param name="new-coords" as="xs:double*"/>
		<xsl:param name="epsilon" as="xs:double"/>
		<xsl:choose>
			<!-- If accumulated is empty, just return new coords -->
			<xsl:when test="count($accumulated) = 0">
				<xsl:sequence select="$new-coords"/>
			</xsl:when>
			<!-- If new coords is empty, just return accumulated -->
			<xsl:when test="count($new-coords) = 0">
				<xsl:sequence select="$accumulated"/>
			</xsl:when>
			<!-- Check if first point of new-coords matches last point of accumulated -->
			<xsl:otherwise>
				<xsl:variable name="last-lat" select="$accumulated[count($accumulated) - 1]"/>
				<xsl:variable name="last-lon" select="$accumulated[count($accumulated)]"/>
				<xsl:variable name="first-lat" select="$new-coords[1]"/>
				<xsl:variable name="first-lon" select="$new-coords[2]"/>
				<xsl:variable name="lat-diff" select="abs($last-lat - $first-lat)"/>
				<xsl:variable name="lon-diff" select="abs($last-lon - $first-lon)"/>
				<xsl:choose>
					<!-- If they match within epsilon, skip the first point of new-coords -->
					<xsl:when test="$lat-diff le $epsilon and $lon-diff le $epsilon">
						<xsl:sequence select="$accumulated, subsequence($new-coords, 3)"/>
					</xsl:when>
					<!-- Otherwise, concatenate all -->
					<xsl:otherwise>
						<xsl:sequence select="$accumulated, $new-coords"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- Function to extract all polygon coordinates from a geometry including referenced GeoBorders -->
	<xsl:function name="fcn:get-all-polygon-coords" as="xs:double*">
		<xsl:param name="airspace-volume" as="element()?"/>
		<xsl:param name="root" as="document-node()"/>
		<xsl:variable name="epsilon" select="0.01" as="xs:double"/>
		<xsl:variable name="max-segment-degrees" select="1.0" as="xs:double"/>
		<xsl:variable name="all-curve-members" select="$airspace-volume//gml:Ring/gml:curveMember"/>
		<!-- Process curveMember elements sequentially to handle GeoBorder extraction -->
		<xsl:call-template name="process-curve-members-seq">
			<xsl:with-param name="curve-members" select="$all-curve-members"/>
			<xsl:with-param name="position" select="1"/>
			<xsl:with-param name="root" select="$root"/>
			<xsl:with-param name="epsilon" select="$epsilon"/>
			<xsl:with-param name="max-segment-degrees" select="$max-segment-degrees"/>
			<xsl:with-param name="accumulated" select="()"/>
		</xsl:call-template>
	</xsl:function>

	<!-- Recursively process curveMember elements -->
	<xsl:template name="process-curve-members-seq">
		<xsl:param name="curve-members" as="element()*"/>
		<xsl:param name="position" as="xs:integer"/>
		<xsl:param name="root" as="document-node()"/>
		<xsl:param name="epsilon" as="xs:double"/>
		<xsl:param name="max-segment-degrees" as="xs:double"/>
		<xsl:param name="accumulated" as="xs:double*"/>
		<xsl:choose>
			<xsl:when test="$position gt count($curve-members)">
				<xsl:sequence select="$accumulated"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="current" select="$curve-members[$position]"/>
				<xsl:variable name="prev" select="$curve-members[$position - 1]"/>
				<xsl:variable name="next" select="$curve-members[$position + 1]"/>
				<xsl:variable name="new-coords" as="xs:double*">
					<xsl:choose>
						<!-- GeoBorder reference -->
						<xsl:when test="$current/@xlink:href and starts-with($current/@xlink:href, 'urn:uuid:')">
							<xsl:variable name="uuid" select="substring-after($current/@xlink:href, 'urn:uuid:')"/>
							<xsl:variable name="geoborder" select="$root//aixm:GeoBorder[gml:identifier = $uuid]"/>
							<xsl:variable name="gb-baseline-ts" select="$geoborder/aixm:timeSlice/aixm:GeoBorderTimeSlice[aixm:interpretation = 'BASELINE']"/>
							<xsl:variable name="gb-max-seq" select="max($gb-baseline-ts/aixm:sequenceNumber)"/>
							<xsl:variable name="gb-max-corr" select="max($gb-baseline-ts[aixm:sequenceNumber = $gb-max-seq]/aixm:correctionNumber)"/>
							<xsl:variable name="gb-valid-ts" select="$gb-baseline-ts[aixm:sequenceNumber = $gb-max-seq and aixm:correctionNumber = $gb-max-corr][1]"/>
							<!-- Get ALL GeoBorder coordinates (flattened) -->
							<xsl:variable name="gb-all-coords" as="xs:double*">
								<xsl:for-each select="$gb-valid-ts/aixm:border//gml:segments/*">
									<xsl:for-each select=".//gml:posList">
										<xsl:sequence select="for $coord in tokenize(normalize-space(.), '\s+') return xs:double($coord)"/>
									</xsl:for-each>
									<xsl:for-each select=".//gml:pos">
										<xsl:sequence select="for $coord in tokenize(normalize-space(.), '\s+') return xs:double($coord)"/>
									</xsl:for-each>
								</xsl:for-each>
							</xsl:variable>
							<!-- Extract relevant portion -->
							<xsl:call-template name="extract-geoborder-portion">
								<xsl:with-param name="gb-coords" select="$gb-all-coords"/>
								<xsl:with-param name="prev-member" select="$prev"/>
								<xsl:with-param name="next-member" select="$next"/>
								<xsl:with-param name="epsilon" select="$epsilon"/>
								<xsl:with-param name="max-segment-degrees" select="$max-segment-degrees"/>
								<xsl:with-param name="root" select="$root"/>
							</xsl:call-template>
						</xsl:when>
						<!-- Direct coordinates -->
						<xsl:otherwise>
							<xsl:for-each select="$current//gml:segments/*">
								<xsl:variable name="is-geodesic" select="local-name() = 'GeodesicString'"/>
								<xsl:variable name="segment-coords" as="xs:double*">
									<xsl:for-each select=".//gml:posList">
										<xsl:sequence select="for $coord in tokenize(normalize-space(.), '\s+') return xs:double($coord)"/>
									</xsl:for-each>
									<xsl:for-each select=".//gml:pos">
										<xsl:sequence select="for $coord in tokenize(normalize-space(.), '\s+') return xs:double($coord)"/>
									</xsl:for-each>
								</xsl:variable>
								<xsl:call-template name="densify-segment">
									<xsl:with-param name="coords" select="$segment-coords"/>
									<xsl:with-param name="is-geodesic" select="$is-geodesic"/>
									<xsl:with-param name="max-segment-degrees" select="$max-segment-degrees"/>
									<xsl:with-param name="epsilon" select="$epsilon"/>
								</xsl:call-template>
							</xsl:for-each>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<!-- Merge new coordinates with global deduplication -->
				<xsl:variable name="merged-coords" select="fcn:merge-coords-deduplicated($accumulated, $new-coords, $epsilon)"/>
				<xsl:call-template name="process-curve-members-seq">
					<xsl:with-param name="curve-members" select="$curve-members"/>
					<xsl:with-param name="position" select="$position + 1"/>
					<xsl:with-param name="root" select="$root"/>
					<xsl:with-param name="epsilon" select="$epsilon"/>
					<xsl:with-param name="max-segment-degrees" select="$max-segment-degrees"/>
					<xsl:with-param name="accumulated" select="$merged-coords"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- Extract the relevant portion of a GeoBorder based on surrounding coordinates -->
	<xsl:template name="extract-geoborder-portion">
		<xsl:param name="gb-coords" as="xs:double*"/>
		<xsl:param name="prev-member" as="element()?"/>
		<xsl:param name="next-member" as="element()?"/>
		<xsl:param name="epsilon" as="xs:double"/>
		<xsl:param name="max-segment-degrees" as="xs:double"/>
		<xsl:param name="root" as="document-node()"/>
		<!-- Get last coordinate from previous member -->
		<xsl:variable name="prev-coords" as="xs:double*">
			<xsl:if test="$prev-member and not($prev-member/@xlink:href)">
				<xsl:for-each select="$prev-member//gml:segments/*">
					<xsl:for-each select=".//gml:posList">
						<xsl:sequence select="for $c in tokenize(normalize-space(.), '\s+') return xs:double($c)"/>
					</xsl:for-each>
					<xsl:for-each select=".//gml:pos">
						<xsl:sequence select="for $c in tokenize(normalize-space(.), '\s+') return xs:double($c)"/>
					</xsl:for-each>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<!-- Get first coordinate from next member -->
		<xsl:variable name="next-coords" as="xs:double*">
			<xsl:if test="$next-member and not($next-member/@xlink:href)">
				<xsl:for-each select="$next-member//gml:segments/*">
					<xsl:for-each select=".//gml:posList">
						<xsl:sequence select="for $c in tokenize(normalize-space(.), '\s+') return xs:double($c)"/>
					</xsl:for-each>
					<xsl:for-each select=".//gml:pos">
						<xsl:sequence select="for $c in tokenize(normalize-space(.), '\s+') return xs:double($c)"/>
					</xsl:for-each>
				</xsl:for-each>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="start-lat" select="if (count($prev-coords) ge 2) then $prev-coords[count($prev-coords) - 1] else ()" as="xs:double?"/>
		<xsl:variable name="start-lon" select="if (count($prev-coords) ge 2) then $prev-coords[count($prev-coords)] else ()" as="xs:double?"/>
		<xsl:variable name="end-lat" select="if (count($next-coords) ge 2) then $next-coords[1] else ()" as="xs:double?"/>
		<xsl:variable name="end-lon" select="if (count($next-coords) ge 2) then $next-coords[2] else ()" as="xs:double?"/>
		<!-- Try to find coordinates with progressive epsilon increase -->
		<xsl:call-template name="find-with-progressive-epsilon">
			<xsl:with-param name="gb-coords" select="$gb-coords"/>
			<xsl:with-param name="start-lat" select="$start-lat"/>
			<xsl:with-param name="start-lon" select="$start-lon"/>
			<xsl:with-param name="end-lat" select="$end-lat"/>
			<xsl:with-param name="end-lon" select="$end-lon"/>
			<xsl:with-param name="epsilon" select="$epsilon"/>
			<xsl:with-param name="max-epsilon" select="1.0"/>
		</xsl:call-template>
	</xsl:template>

	<!-- Recursive template to find coordinates with progressively increasing epsilon -->
	<xsl:template name="find-with-progressive-epsilon">
		<xsl:param name="gb-coords" as="xs:double*"/>
		<xsl:param name="start-lat" as="xs:double?"/>
		<xsl:param name="start-lon" as="xs:double?"/>
		<xsl:param name="end-lat" as="xs:double?"/>
		<xsl:param name="end-lon" as="xs:double?"/>
		<xsl:param name="epsilon" as="xs:double"/>
		<xsl:param name="max-epsilon" as="xs:double"/>
		<!-- Find start and end in GeoBorder with current epsilon -->
		<xsl:variable name="start-idx" select="if (exists($start-lat)) then fcn:find-exact-point-index($start-lat, $start-lon, $gb-coords, $epsilon) else ()" as="xs:integer?"/>
		<xsl:variable name="end-idx" select="if (exists($end-lat)) then fcn:find-exact-point-index($end-lat, $end-lon, $gb-coords, $epsilon) else ()" as="xs:integer?"/>
		<xsl:choose>
			<!-- Both found: extract between them -->
			<xsl:when test="exists($start-idx) and exists($end-idx)">
				<xsl:choose>
					<xsl:when test="$start-idx lt $end-idx">
						<!-- Forward -->
						<xsl:sequence select="fcn:extract-segment($gb-coords, $start-idx, $end-idx, false())"/>
					</xsl:when>
					<xsl:otherwise>
						<!-- Backward -->
						<xsl:sequence select="fcn:extract-segment($gb-coords, $end-idx, $start-idx, true())"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<!-- Not found: try with increased epsilon -->
			<xsl:when test="$epsilon lt $max-epsilon">
				<xsl:call-template name="find-with-progressive-epsilon">
					<xsl:with-param name="gb-coords" select="$gb-coords"/>
					<xsl:with-param name="start-lat" select="$start-lat"/>
					<xsl:with-param name="start-lon" select="$start-lon"/>
					<xsl:with-param name="end-lat" select="$end-lat"/>
					<xsl:with-param name="end-lon" select="$end-lon"/>
					<xsl:with-param name="epsilon" select="$epsilon + 0.01"/>
					<xsl:with-param name="max-epsilon" select="$max-epsilon"/>
				</xsl:call-template>
			</xsl:when>
			<!-- Max epsilon reached: use all GeoBorder as last resort -->
			<xsl:otherwise>
				<xsl:sequence select="$gb-coords"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- Template to densify a segment with deduplication and appropriate interpolation -->
	<xsl:template name="densify-segment">
		<xsl:param name="coords" as="xs:double*"/>
		<xsl:param name="is-geodesic" as="xs:boolean"/>
		<xsl:param name="max-segment-degrees" as="xs:double"/>
		<xsl:param name="epsilon" as="xs:double"/>
		<!-- First deduplicate consecutive points within this segment -->
		<xsl:variable name="deduplicated" as="xs:double*">
			<xsl:for-each select="1 to count($coords) div 2">
				<xsl:variable name="idx" select=". * 2 - 1"/>
				<xsl:variable name="lat" select="$coords[$idx]"/>
				<xsl:variable name="lon" select="$coords[$idx + 1]"/>
				<!-- Only include if different from previous point -->
				<xsl:if test=". = 1 or abs($lat - $coords[$idx - 2]) ge $epsilon or abs($lon - $coords[$idx - 1]) ge $epsilon">
					<xsl:sequence select="$lat, $lon"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<!-- Now densify with appropriate interpolation -->
		<xsl:for-each select="1 to (count($deduplicated) div 2)">
			<xsl:variable name="idx" select=". * 2 - 1"/>
			<xsl:variable name="lat1" select="$deduplicated[$idx]"/>
			<xsl:variable name="lon1" select="$deduplicated[$idx + 1]"/>
			<xsl:choose>
				<xsl:when test=". lt (count($deduplicated) div 2)">
					<!-- Not the last point - densify segment to next point -->
					<xsl:variable name="lat2" select="$deduplicated[$idx + 2]"/>
					<xsl:variable name="lon2" select="$deduplicated[$idx + 3]"/>
					<xsl:choose>
						<xsl:when test="$is-geodesic">
							<xsl:sequence select="fcn:densify-geodesic-segment($lat1, $lon1, $lat2, $lon2, $max-segment-degrees)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:sequence select="fcn:densify-linear-segment($lat1, $lon1, $lat2, $lon2, $max-segment-degrees)"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<!-- Last point - just add it -->
					<xsl:sequence select="$lat1, $lon1"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
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
	
	<!-- Function to get the valid BASELINE timeslice for an Airspace -->
	<xsl:function name="fcn:get-valid-airspace-timeslice" as="element()?">
		<xsl:param name="airspace" as="element()?"/>
		<xsl:variable name="baseline-timeslices" select="$airspace/aixm:timeSlice/aixm:AirspaceTimeSlice[aixm:interpretation = 'BASELINE']"/>
		<xsl:variable name="max-sequence" select="max($baseline-timeslices/aixm:sequenceNumber)"/>
		<xsl:variable name="max-correction" select="max($baseline-timeslices[aixm:sequenceNumber = $max-sequence]/aixm:correctionNumber)"/>
		<xsl:sequence select="$baseline-timeslices[aixm:sequenceNumber = $max-sequence and aixm:correctionNumber = $max-correction][1]"/>
	</xsl:function>

	<!-- OPTIMIZATION: Pre-build all FIR geometries to avoid repeated construction -->
	<!-- Returns a map where keys are FIR/FIR_P UUIDs and values are maps containing geometry coords and metadata -->
	<xsl:function name="fcn:build-fir-geometry-cache" as="map(xs:string, map(*))">
		<xsl:param name="root" as="document-node()"/>
		<!-- Get all FIR and FIR_P Airspaces -->
		<xsl:variable name="fir-airspaces" select="$root//aixm:Airspace[aixm:timeSlice/aixm:AirspaceTimeSlice[aixm:type = ('FIR', 'FIR_P')]]"/>
		<!-- Build a map of all FIR geometries -->
		<xsl:variable name="geometry-entries" as="map(xs:string, map(*))*">
			<xsl:for-each select="$fir-airspaces">
				<xsl:variable name="airspace" select="."/>
				<xsl:variable name="uuid" select="string(gml:identifier)"/>
				<xsl:variable name="valid-ts" select="fcn:get-valid-airspace-timeslice($airspace)"/>
				<xsl:if test="$valid-ts">
					<xsl:variable name="airspace-type" select="string($valid-ts/aixm:type)"/>
					<xsl:variable name="designator" select="string($valid-ts/aixm:designator)"/>
					<xsl:variable name="seq-num" select="string($valid-ts/aixm:sequenceNumber)"/>
					<xsl:variable name="corr-num" select="string($valid-ts/aixm:correctionNumber)"/>
					<!-- Get geometry - handle both direct geometry and contributorAirspace references -->
					<xsl:variable name="geom-components" select="$valid-ts/aixm:geometryComponent/aixm:AirspaceGeometryComponent"/>
					<!-- Collect all coordinate sequences for this airspace -->
					<xsl:variable name="all-coords" as="array(xs:double*)*">
						<xsl:for-each select="$geom-components">
							<xsl:variable name="airspace-volume" select="aixm:theAirspaceVolume/aixm:AirspaceVolume"/>
							<xsl:choose>
								<!-- Direct geometry -->
								<xsl:when test="$airspace-volume/aixm:horizontalProjection">
									<xsl:variable name="coords" select="fcn:get-all-polygon-coords($airspace-volume/aixm:horizontalProjection, $root)"/>
									<xsl:if test="count($coords) ge 6">
										<xsl:sequence select="[$coords]"/>
									</xsl:if>
								</xsl:when>
								<!-- Reference to another airspace (FIR composed of FIR_P) -->
								<xsl:when test="$airspace-volume/aixm:contributorAirspace">
									<xsl:for-each select="$airspace-volume/aixm:contributorAirspace/aixm:AirspaceVolumeDependency">
										<xsl:variable name="ref-uuid" select="substring-after(aixm:theAirspace/@xlink:href, 'urn:uuid:')"/>
										<xsl:variable name="ref-airspace" select="$root//aixm:Airspace[gml:identifier = $ref-uuid]"/>
										<xsl:variable name="ref-valid-ts" select="fcn:get-valid-airspace-timeslice($ref-airspace)"/>
										<xsl:if test="$ref-valid-ts">
											<xsl:variable name="ref-volume" select="$ref-valid-ts/aixm:geometryComponent/aixm:AirspaceGeometryComponent/aixm:theAirspaceVolume/aixm:AirspaceVolume"/>
											<xsl:variable name="ref-coords" select="fcn:get-all-polygon-coords($ref-volume/aixm:horizontalProjection, $root)"/>
											<xsl:if test="count($ref-coords) ge 6">
												<xsl:sequence select="[$ref-coords]"/>
											</xsl:if>
										</xsl:if>
									</xsl:for-each>
								</xsl:when>
							</xsl:choose>
						</xsl:for-each>
					</xsl:variable>
					<!-- Only create entry if we have valid geometry -->
					<xsl:if test="count($all-coords) gt 0">
						<xsl:sequence select="map{
							$uuid: map{
								'type': $airspace-type,
								'designator': $designator,
								'sequenceNumber': $seq-num,
								'correctionNumber': $corr-num,
								'geometries': $all-coords
							}
						}"/>
					</xsl:if>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<!-- Merge all individual maps into a single map -->
		<xsl:sequence select="map:merge($geometry-entries)"/>
	</xsl:function>

	<!-- OPTIMIZED: Find the FIR containing a given point using pre-built geometry cache -->
	<xsl:function name="fcn:find-containing-fir-optimized" as="map(xs:string, xs:string)?">
		<xsl:param name="lat" as="xs:double"/>
		<xsl:param name="lon" as="xs:double"/>
		<xsl:param name="fir-cache" as="map(xs:string, map(*))"/>
		<xsl:param name="root" as="document-node()"/>
		<!-- Check each FIR in the cache -->
		<xsl:variable name="containing-uuids" as="xs:string*">
			<xsl:for-each select="map:keys($fir-cache)">
				<xsl:variable name="uuid" select="."/>
				<xsl:variable name="fir-data" select="map:get($fir-cache, $uuid)"/>
				<xsl:variable name="geometries" select="map:get($fir-data, 'geometries')"/>
				<!-- Check if point is in any of this FIR's geometries -->
				<xsl:variable name="is-inside" as="xs:boolean">
					<xsl:choose>
						<xsl:when test="count($geometries) = 0">
							<xsl:sequence select="false()"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:variable name="matches" as="xs:boolean*">
								<xsl:for-each select="$geometries">
									<xsl:sequence select="fcn:point-in-polygon($lat, $lon, .)"/>
								</xsl:for-each>
							</xsl:variable>
							<xsl:sequence select="some $m in $matches satisfies $m"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:if test="$is-inside">
					<xsl:sequence select="$uuid"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<!-- Process the first containing airspace found (prefer FIR over FIR_P) -->
		<xsl:variable name="containing-uuid" as="xs:string?">
			<xsl:choose>
				<xsl:when test="count($containing-uuids) = 0">
					<xsl:sequence select="()"/>
				</xsl:when>
				<xsl:otherwise>
					<!-- Prefer FIR over FIR_P -->
					<xsl:variable name="fir-uuids" select="$containing-uuids[map:get(map:get($fir-cache, .), 'type') = 'FIR']"/>
					<xsl:sequence select="if (count($fir-uuids) gt 0) then $fir-uuids[1] else $containing-uuids[1]"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$containing-uuid">
			<xsl:variable name="fir-data" select="map:get($fir-cache, $containing-uuid)"/>
			<xsl:variable name="airspace-type" select="map:get($fir-data, 'type')"/>
			<xsl:choose>
				<!-- If it's a FIR_P, find the parent FIR -->
				<xsl:when test="$airspace-type = 'FIR_P'">
					<!-- Find FIR that references this FIR_P -->
					<xsl:variable name="parent-fir" select="($root//aixm:Airspace[aixm:timeSlice/aixm:AirspaceTimeSlice[aixm:type = 'FIR' and aixm:geometryComponent/aixm:AirspaceGeometryComponent/aixm:theAirspaceVolume/aixm:AirspaceVolume/aixm:contributorAirspace/aixm:AirspaceVolumeDependency/aixm:theAirspace/@xlink:href = concat('urn:uuid:', $containing-uuid)]])[1]"/>
					<xsl:if test="$parent-fir">
						<xsl:variable name="parent-ts" select="fcn:get-valid-airspace-timeslice($parent-fir)"/>
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
						'designator': map:get($fir-data, 'designator'),
						'sequenceNumber': map:get($fir-data, 'sequenceNumber'),
						'correctionNumber': map:get($fir-data, 'correctionNumber')
					}"/>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
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
	
	<!-- Get annotation text escaping special HTML characters -->
	<xsl:function name="fcn:get-annotation-text" as="xs:string">
		<xsl:param name="raw_text" as="xs:string"/>
		<!-- First, escape special HTML characters in the raw text before processing -->
		<xsl:variable name="escaped_raw_text" select="replace(replace($raw_text, '&lt;', '&amp;lt;'), '&gt;', '&amp;gt;')"/>
		<xsl:variable name="lines" select="for $line in tokenize($escaped_raw_text, '&#xA;') return normalize-space($line)"/>
		<xsl:variable name="non_empty_lines" select="$lines[string-length(.) gt 0]"/>
		<xsl:value-of select="string-join($non_empty_lines, ' ')"/>
	</xsl:function>
	
	<!-- Recursively find STATE organization from an organization UUID -->
	<xsl:function name="fcn:find-state-org" as="element()?">
		<xsl:param name="org-uuid" as="xs:string"/>
		<xsl:param name="visited-uuids" as="xs:string*"/>
		<xsl:param name="root" as="document-node()"/>
		<!-- First pass: try to find a STATE -->
		<xsl:variable name="state-result" select="fcn:find-state-recursive($org-uuid, $visited-uuids, $root)"/>
		<xsl:choose>
			<xsl:when test="$state-result">
				<!-- Found a STATE, return it -->
				<xsl:sequence select="$state-result"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- No STATE found, try to find the first INTL_ORG -->
				<xsl:sequence select="fcn:find-intl-org($org-uuid, (), $root)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- Helper function to recursively find a STATE organization -->
	<xsl:function name="fcn:find-state-recursive" as="element()?">
		<xsl:param name="org-uuid" as="xs:string"/>
		<xsl:param name="visited-uuids" as="xs:string*"/>
		<xsl:param name="root" as="document-node()"/>
		<!-- Prevent infinite loops by checking if we've already visited this UUID -->
		<xsl:if test="not($org-uuid = $visited-uuids) and string-length($org-uuid) gt 0">
			<!-- Get the organization feature -->
			<xsl:variable name="org-feature" select="$root//aixm:OrganisationAuthority[gml:identifier = $org-uuid]"/>
			<xsl:if test="$org-feature">
				<!-- Get the valid baseline timeslice -->
				<xsl:variable name="org-baseline-ts" select="$org-feature/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice[aixm:interpretation = 'BASELINE']"/>
				<xsl:variable name="org-max-seq" select="max($org-baseline-ts/aixm:sequenceNumber)"/>
				<xsl:variable name="org-max-corr" select="max($org-baseline-ts[aixm:sequenceNumber = $org-max-seq]/aixm:correctionNumber)"/>
				<xsl:variable name="org-valid-ts" select="$org-baseline-ts[aixm:sequenceNumber = $org-max-seq and aixm:correctionNumber = $org-max-corr][1]"/>
				<xsl:choose>
					<!-- If this organization is a STATE, return it -->
					<xsl:when test="$org-valid-ts/aixm:type = 'STATE'">
						<xsl:sequence select="$org-valid-ts"/>
					</xsl:when>
					<!-- Otherwise, check if it has related organizations -->
					<xsl:when test="$org-valid-ts/aixm:relatedOrganisationAuthority/aixm:OrganisationAuthorityAssociation/aixm:theOrganisationAuthority/@xlink:href">
						<!-- Iterate through all related organizations to find a STATE -->
						<xsl:variable name="state-from-related" as="element()?">
							<xsl:iterate select="$org-valid-ts/aixm:relatedOrganisationAuthority/aixm:OrganisationAuthorityAssociation/aixm:theOrganisationAuthority/@xlink:href">
								<xsl:param name="found-state" as="element()?" select="()"/>
								<xsl:choose>
									<xsl:when test="$found-state">
										<!-- Already found a STATE, stop iteration -->
										<xsl:break select="$found-state"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:variable name="related-uuid" select="replace(., '^(urn:uuid:|#uuid\.)', '')"/>
										<xsl:variable name="state-result" select="fcn:find-state-recursive($related-uuid, ($visited-uuids, $org-uuid), $root)"/>
										<xsl:choose>
											<xsl:when test="$state-result">
												<!-- Found a STATE in this branch -->
												<xsl:break select="$state-result"/>
											</xsl:when>
											<xsl:otherwise>
												<!-- Continue to next related organization -->
												<xsl:next-iteration>
													<xsl:with-param name="found-state" select="()"/>
												</xsl:next-iteration>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:iterate>
						</xsl:variable>
						<xsl:sequence select="$state-from-related"/>
					</xsl:when>
				</xsl:choose>
			</xsl:if>
		</xsl:if>
	</xsl:function>
	
	<!-- Helper function to find the first INTL_ORG organization -->
	<xsl:function name="fcn:find-intl-org" as="element()?">
		<xsl:param name="org-uuid" as="xs:string"/>
		<xsl:param name="visited-uuids" as="xs:string*"/>
		<xsl:param name="root" as="document-node()"/>
		<!-- Prevent infinite loops by checking if we've already visited this UUID -->
		<xsl:if test="not($org-uuid = $visited-uuids) and string-length($org-uuid) gt 0">
			<!-- Get the organization feature -->
			<xsl:variable name="org-feature" select="$root//aixm:OrganisationAuthority[gml:identifier = $org-uuid]"/>
			<xsl:if test="$org-feature">
				<!-- Get the valid baseline timeslice -->
				<xsl:variable name="org-baseline-ts" select="$org-feature/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice[aixm:interpretation = 'BASELINE']"/>
				<xsl:variable name="org-max-seq" select="max($org-baseline-ts/aixm:sequenceNumber)"/>
				<xsl:variable name="org-max-corr" select="max($org-baseline-ts[aixm:sequenceNumber = $org-max-seq]/aixm:correctionNumber)"/>
				<xsl:variable name="org-valid-ts" select="$org-baseline-ts[aixm:sequenceNumber = $org-max-seq and aixm:correctionNumber = $org-max-corr][1]"/>
				<xsl:choose>
					<!-- If this organization is an INTL_ORG, return it -->
					<xsl:when test="$org-valid-ts/aixm:type = 'INTL_ORG'">
						<xsl:sequence select="$org-valid-ts"/>
					</xsl:when>
					<!-- Otherwise, check if it has related organizations -->
					<xsl:when test="$org-valid-ts/aixm:relatedOrganisationAuthority/aixm:OrganisationAuthorityAssociation/aixm:theOrganisationAuthority/@xlink:href">
						<!-- Iterate through all related organizations to find an INTL_ORG -->
						<xsl:variable name="intl-org-from-related" as="element()?">
							<xsl:iterate select="$org-valid-ts/aixm:relatedOrganisationAuthority/aixm:OrganisationAuthorityAssociation/aixm:theOrganisationAuthority/@xlink:href">
								<xsl:param name="found-intl-org" as="element()?" select="()"/>
								<xsl:choose>
									<xsl:when test="$found-intl-org">
										<!-- Already found an INTL_ORG, stop iteration -->
										<xsl:break select="$found-intl-org"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:variable name="related-uuid" select="replace(., '^(urn:uuid:|#uuid\.)', '')"/>
										<xsl:variable name="intl-org-result" select="fcn:find-intl-org($related-uuid, ($visited-uuids, $org-uuid), $root)"/>
										<xsl:choose>
											<xsl:when test="$intl-org-result">
												<!-- Found an INTL_ORG in this branch -->
												<xsl:break select="$intl-org-result"/>
											</xsl:when>
											<xsl:otherwise>
												<!-- Continue to next related organization -->
												<xsl:next-iteration>
													<xsl:with-param name="found-intl-org" select="()"/>
												</xsl:next-iteration>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:iterate>
						</xsl:variable>
						<xsl:sequence select="$intl-org-from-related"/>
					</xsl:when>
				</xsl:choose>
			</xsl:if>
		</xsl:if>
	</xsl:function>
	
	<xsl:template match="/">
		
		<html xmlns="http://www.w3.org/1999/xhtml">
			
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
				<meta http-equiv="Expires" content="120"/>
				<title>SDO Reporting - AD / HP including FIR</title>
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
					<b>AD / HP including FIR</b>
				</center>
				<hr/>
				
				<table border="0" style="white-space:nowrap">
					<tbody>
						
						<tr>
							<td><strong>Identification</strong></td>
						</tr>
						<tr>
							<td><strong>Responsible State or international organisaton - Name</strong></td>
						</tr>
						<tr>
							<td><strong>Responsible State or international organisation - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>Name</strong></td>
						</tr>
						<tr>
							<td><strong>ICAO Code</strong></td>
						</tr>
						<tr>
							<td><strong>IATA Code</strong></td>
						</tr>
						<tr>
							<td><strong>Type</strong></td>
						</tr>
						<tr>
							<td><strong>(d)Operation code</strong></td>
						</tr>
						<tr>
							<td><strong>(d)National traffic</strong></td>
						</tr>
						<tr>
							<td><strong>(d)International traffic</strong></td>
						</tr>
						<tr>
							<td><strong>(d)Scheduled flight</strong></td>
						</tr>
						<tr>
							<td><strong>(d)Non scheduled flight</strong></td>
						</tr>
						<tr>
							<td><strong>(d)Private flight</strong></td>
						</tr>
						<tr>
							<td><strong>(d)Observe VFR</strong></td>
						</tr>
						<tr>
							<td><strong>(d)Observe IFR</strong></td>
						</tr>
						<tr>
							<td><strong>Reference point description</strong></td>
						</tr>
						<tr>
							<td><strong>Latitude</strong></td>
						</tr>
						<tr>
							<td><strong>Longitude</strong></td>
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
							<td><strong>Elevation</strong></td>
						</tr>
						<tr>
							<td><strong>Elevation accuracy</strong></td>
						</tr>
						<tr>
							<td><strong>Geoid undulation</strong></td>
						</tr>
						<tr>
							<td><strong>Unit of measurement [vertical distance]</strong></td>
						</tr>
						<tr>
							<td><strong>Cyclic redundancy check</strong></td>
						</tr>
						<tr>
							<td><strong>Vertical Datum</strong></td>
						</tr>
						<tr>
							<td><strong>Served city</strong></td>
						</tr>
						<tr>
							<td><strong>Site description</strong></td>
						</tr>
						<tr>
							<td><strong>Magnetic variation</strong></td>
						</tr>
						<tr>
							<td><strong>Magnetic variation date</strong></td>
						</tr>
						<tr>
							<td><strong>Annual rate of change of magnetic variation</strong></td>
						</tr>
						<tr>
							<td><strong>Reference temperature</strong></td>
						</tr>
						<tr>
							<td><strong>Unit of measurement [temperature]</strong></td>
						</tr>
						<tr>
							<td><strong>Organisation in charge</strong></td>
						</tr>
						<tr>
							<td><strong>Organisation in charge - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>Altimeter check location description</strong></td>
						</tr>
						<tr>
							<td><strong>Secondary power supply description</strong></td>
						</tr>
						<tr>
							<td><strong>Wind direction indicator description</strong></td>
						</tr>
						<tr>
							<td><strong>Landing direction indicator description</strong></td>
						</tr>
						<tr>
							<td><strong>Transition altitude</strong></td>
						</tr>
						<tr>
							<td><strong>Unit of measurement [transition altitude]</strong></td>
						</tr>
						<tr>
							<td><strong>Working hours</strong></td>
						</tr>
						<tr>
							<td><strong>Remark to working hours</strong></td>
						</tr>
						<tr>
							<td><strong>Remarks</strong></td>
						</tr>
						<tr>
							<td><strong>Committed on</strong></td>
						</tr>
						<tr>
							<td><strong>Internal UID (master)</strong></td>
						</tr>
						<tr>
							<td><strong>AirportHeliport - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>FIR - Coded identifier</strong></td>
						</tr>
						<tr>
							<td><strong>FIR - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>Originator</strong></td>
						</tr>
						<tr>
							<td><strong>Effective date</strong></td>
						</tr>
						<tr>
							<td><strong>System Remark</strong></td>
						</tr>
						<tr>
							<td>&#160;</td>
						</tr>
						<tr>
							<td>&#160;</td>
						</tr>
						
						<!-- Capture document root before iterating through AirportHeliport features -->
						<xsl:variable name="doc-root" select="/" as="document-node()"/>
						
						<!-- OPTIMIZATION: Pre-build all FIR geometries once before processing airports -->
						<!-- This avoids reconstructing geometries N times (once per airport) -->
						<xsl:variable name="fir-geometry-cache" select="fcn:build-fir-geometry-cache($doc-root)" as="map(xs:string, map(*))"/>

						<xsl:for-each select="//aixm:AirportHeliport">
							<xsl:sort select="(aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)][aixm:correctionNumber = max(../aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)]/aixm:correctionNumber)])[1]/aixm:designator" order="ascending"/>
							<!-- Get all BASELINE time slices for this feature -->
							<xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']"/>
							<!-- Find the maximum sequenceNumber -->
							<xsl:variable name="max-sequence" select="max($baseline-timeslices/aixm:sequenceNumber)"/>
							<!-- Get time slices with the maximum sequenceNumber, then find max correctionNumber -->
							<xsl:variable name="max-correction" select="max($baseline-timeslices[aixm:sequenceNumber = $max-sequence]/aixm:correctionNumber)"/>
							<!-- Select the valid time slice -->
							<xsl:variable name="valid-timeslice" select="$baseline-timeslices[aixm:sequenceNumber = $max-sequence and aixm:correctionNumber = $max-correction][1]"/>

							<xsl:for-each select="$valid-timeslice">
							
								<!-- Identification -->
								<xsl:variable name="AHP_designator">
									<xsl:choose>
										<xsl:when test="not(aixm:designator)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:designator)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Organisation in charge -->
								<xsl:variable name="OrgAuth_UUID" select="replace(aixm:responsibleOrganisation/aixm:AirportHeliportResponsibilityOrganisation/aixm:theOrganisationAuthority/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<!-- Get the valid BASELINE time slice for this OrganisationAuthority -->
								<xsl:variable name="org-baseline-ts" select="//aixm:OrganisationAuthority[gml:identifier = $OrgAuth_UUID]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="org-max-seq" select="max($org-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="org-max-corr" select="max($org-baseline-ts[aixm:sequenceNumber = $org-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="org-valid-ts" select="$org-baseline-ts[aixm:sequenceNumber = $org-max-seq and aixm:correctionNumber = $org-max-corr][1]"/>
								<!-- Organisation in charge - Name -->
								<xsl:variable name="OrgInCharge_name">
									<xsl:value-of select="$org-valid-ts/aixm:name"/>
								</xsl:variable>
								<!-- Organisation in charge - Valid TimeSlice -->
								<xsl:variable name="OrgInCharge_timeslice">
									<xsl:value-of select="concat('BASELINE ', $org-max-seq, '.', $org-max-corr)"/>
								</xsl:variable>
								
								<!-- Responsible State or International Organisation -->
								<!-- Recursively find the STATE or INTL_ORG -->
								<xsl:variable name="state-intl-org-ts" select="fcn:find-state-org($OrgAuth_UUID, (), root())"/>
								<!-- Responsible State or International Organisation - Name -->
								<xsl:variable name="ResponsibleStateOrIntlOrg_name">
									<xsl:if test="$state-intl-org-ts">
										<xsl:value-of select="$state-intl-org-ts/aixm:name"/>
									</xsl:if>
								</xsl:variable>
								<!-- Responsible State or International Organisation - Valid TimeSlice -->
								<xsl:variable name="ResponsibleStateOrIntlOrg_timeslice">
									<xsl:if test="$state-intl-org-ts">
										<xsl:value-of select="concat('BASELINE ', $state-intl-org-ts/aixm:sequenceNumber, '.', $state-intl-org-ts/aixm:correctionNumber)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Name -->
								<xsl:variable name="AHP_name">
									<xsl:choose>
										<xsl:when test="not(aixm:name)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:name)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- ICAO Code -->
								<xsl:variable name="AHP_ICAO_code">
									<xsl:choose>
										<xsl:when test="not(aixm:locationIndicatorICAO)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:locationIndicatorICAO)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- IATA Code -->
								<xsl:variable name="AHP_IATA_code">
									<xsl:choose>
										<xsl:when test="not(aixm:designatorIATA)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:designatorIATA)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Type -->
								<xsl:variable name="AHP_type">
									<xsl:choose>
										<xsl:when test="not(aixm:type)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:type)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- (d)Operation code -->
								<xsl:variable name="AHP_control_type">
									<xsl:choose>
										<xsl:when test="not(aixm:controlType)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:controlType)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<xsl:variable name="AHP_normal_usage" select="aixm:availability/aixm:AirportHeliportAvailability[aixm:operationalStatus='NORMAL']/aixm:usage/aixm:AirportHeliportUsage"/>
								
								<!-- (d)National traffic -->
								<xsl:variable name="AHP_nat_traffic">
									<xsl:choose>
										<xsl:when test="count($AHP_normal_usage[aixm:type = ('PERMIT','RESERV','CONDITIONAL','OTHER:EXTENDED') and .//aixm:FlightCharacteristic/aixm:origin = ('NTL','ALL')]) = 0 and count($AHP_normal_usage[aixm:type = ('FORBID') and .//aixm:FlightCharacteristic/aixm:origin = ('NTL','ALL')]) != 0">
											<xsl:value-of select="'Forbidden'"/>
										</xsl:when>
										<xsl:when test="count($AHP_normal_usage[aixm:type = ('PERMIT','RESERV','CONDITIONAL','OTHER:EXTENDED') and .//aixm:FlightCharacteristic/aixm:origin = ('NTL','ALL')]) != 0">
											<xsl:value-of select="'Permitted'"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="'Not specified'"/>
										</xsl:otherwise>
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
										<xsl:otherwise>
											<xsl:value-of select="'Not specified'"/>
										</xsl:otherwise>
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
										<xsl:otherwise>
											<xsl:value-of select="'Not specified'"/>
										</xsl:otherwise>
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
										<xsl:otherwise>
											<xsl:value-of select="'Not specified'"/>
										</xsl:otherwise>
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
										<xsl:otherwise>
											<xsl:value-of select="'Not specified'"/>
										</xsl:otherwise>
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
										<xsl:otherwise>
											<xsl:value-of select="'Not specified'"/>
										</xsl:otherwise>
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
										<xsl:otherwise>
											<xsl:value-of select="'Not specified'"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Reference point description -->
								<xsl:variable name="AHP_ARP_description">
									<xsl:for-each select="aixm:annotation/aixm:Note[aixm:propertyName = ('arp', 'ARP', 'aRP') or contains(lower-case(aixm:translatedNote[1]/aixm:LinguisticNote/aixm:note), 'aerodrome reference point')]">
										<xsl:for-each select="aixm:translatedNote/aixm:LinguisticNote">
											<xsl:choose>
												<xsl:when test="contains(lower-case(aixm:note), 'aerodrome reference point')">
													<xsl:value-of select="concat(if (position() = 1) then '' else ' | ', if (aixm:note/@lang) then (concat('(', aixm:note/@lang), ') ') else '', fcn:get-annotation-text(substring-after(aixm:note, ':')))"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="concat(if (position() = 1) then '' else ' | ', if (aixm:note/@lang) then (concat('(', aixm:note/@lang), ') ') else '', fcn:get-annotation-text(aixm:note))"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:for-each>
									</xsl:for-each>
								</xsl:variable>
								
								<!-- Coordinates -->
								
								<!-- Select the type of coordinates: 'DMS' or 'DEC' -->
								<xsl:variable name="coordinates_type" select="'DMS'"/>
								
								<!-- Select the number of decimals -->
								<xsl:variable name="coordinates_decimal_number" select="2"/>
								
								<!-- Datum -->
								<xsl:variable name="AHP_ARP_datum">
									<xsl:value-of select="replace(replace(aixm:ARP/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
								</xsl:variable>
								
								<!-- Extract coordinates depending on the coordinate system -->
								<xsl:variable name="coordinates" select="aixm:ARP/aixm:ElevatedPoint/gml:pos"/>
								<xsl:variable name="latitude_decimal">
									<xsl:choose>
										<xsl:when test="$AHP_ARP_datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
											<xsl:value-of  select="number(substring-before($coordinates, ' '))"/>
										</xsl:when>
										<xsl:when test="matches($AHP_ARP_datum, '^OGC:.*CRS84$')">
											<xsl:value-of select="number(substring-after($coordinates, ' '))"/>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="longitude_decimal">
									<xsl:choose>
										<xsl:when test="$AHP_ARP_datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
											<xsl:value-of  select="number(substring-after($coordinates, ' '))"/>
										</xsl:when>
										<xsl:when test="matches($AHP_ARP_datum, '^OGC:.*CRS84$')">
											<xsl:value-of select="number(substring-before($coordinates, ' '))"/>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="AHP_ARP_lat">
									<xsl:if test="string-length($latitude_decimal) gt 0">
										<xsl:value-of select="fcn:format-latitude($latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
								</xsl:variable>
								<xsl:variable name="AHP_ARP_long">
									<xsl:if test="string-length($longitude_decimal) gt 0">
										<xsl:value-of select="fcn:format-longitude($longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Geographical accuracy -->
								<xsl:variable name="AHP_ARP_geo_accuracy">
									<xsl:choose>
										<xsl:when test="not(aixm:ARP/aixm:ElevatedPoint/aixm:horizontalAccuracy)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:ARP/aixm:ElevatedPoint/aixm:horizontalAccuracy)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Unit of measurement [geographical accuracy] -->
								<xsl:variable name="AHP_ARP_geo_acc_uom">
									<xsl:value-of select="aixm:ARP/aixm:ElevatedPoint/aixm:horizontalAccuracy/@uom"/>
								</xsl:variable>
								
								<!-- Elevation -->
								<xsl:variable name="AHP_ARP_elevation">
									<xsl:choose>
										<xsl:when test="not(aixm:fieldElevation)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:fieldElevation)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Elevation accuracy -->
								<xsl:variable name="AHP_ARP_elev_acc">
									<xsl:choose>
										<xsl:when test="not(aixm:fieldElevationAccuracy)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:fieldElevationAccuracy)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Geoid undulation -->
								<xsl:variable name="AHP_ARP_geoid_und">
									<xsl:choose>
										<xsl:when test="not(aixm:ARP/aixm:ElevatedPoint/aixm:geoidUndulation)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:ARP/aixm:ElevatedPoint/aixm:geoidUndulation)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Unit of measurement [vertical distance] -->
								<xsl:variable name="AHP_ARP_vert_dist_uom">
									<xsl:choose>
										<xsl:when test="aixm:fieldElevation/@uom">
											<xsl:value-of select="aixm:fieldElevation/@uom"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="aixm:ARP/aixm:ElevatedPoint/aixm:geoidUndulation/@uom"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Cyclic redundancy check -->
								<xsl:variable name="AHP_CRC">
									<xsl:if test="aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note[not(@lang) or @lang=('en','eng')], 'CRC:')]/aixm:note">
										<xsl:value-of select="fcn:get-last-word(aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note[not(@lang) or @lang=('en','eng')], 'CRC:')]/aixm:note[not(@lang) or @lang=('en','eng')])"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Vertical Datum -->
								<xsl:variable name="AHP_vertical_datum">
									<xsl:choose>
										<xsl:when test="not(aixm:verticalDatum)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of  select="fcn:insert-value(aixm:verticalDatum)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Served city -->
								<xsl:variable name="AHP_served_city">
									<xsl:choose>
										<xsl:when test="not(aixm:servedCity)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:when test="aixm:servedCity/@xsi:nil='true'">
											<xsl:choose>
												<xsl:when test="aixm:servedCity/@nilReason">
													<xsl:value-of select="concat('NIL:', aixm:servedCity/@nilReason)"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="'NIL'"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="aixm:servedCity/aixm:City/aixm:name"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Site description -->
								<xsl:variable name="AHP_site_description">
									<xsl:for-each select="aixm:annotation/aixm:Note[aixm:propertyName = ('servedCity') or contains(lower-case(aixm:translatedNote[1]/aixm:LinguisticNote/aixm:note), 'site description')]">
										<xsl:for-each select="aixm:translatedNote/aixm:LinguisticNote">
											<xsl:choose>
												<xsl:when test="contains(lower-case(aixm:note), 'site description')">
													<xsl:value-of select="concat(if (position() = 1) then '' else ' | ', if (aixm:note/@lang) then (concat('(', aixm:note/@lang, ') ')) else '', fcn:get-annotation-text(substring-after(aixm:note, ':')))"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="concat(if (position() = 1) then '' else ' | ', if (aixm:note/@lang) then (concat('(', aixm:note/@lang, ') ')) else '', fcn:get-annotation-text(aixm:note))"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:for-each>
									</xsl:for-each>
								</xsl:variable>
								
								<!-- Magnetic variation -->
								<xsl:variable name="AHP_mag_var">
									<xsl:choose>
										<xsl:when test="not(aixm:magneticVariation)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:magneticVariation)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Magnetic variation date -->
								<xsl:variable name="AHP_mag_var_date">
									<xsl:choose>
										<xsl:when test="not(aixm:dateMagneticVariation)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:dateMagneticVariation)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Annual rate of change of magnetic variation -->
								<xsl:variable name="AHP_mag_var_change">
									<xsl:choose>
										<xsl:when test="not(aixm:magneticVariationChange)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:magneticVariationChange)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Reference temperature -->
								<xsl:variable name="AHP_ref_temp">
									<xsl:choose>
										<xsl:when test="not(aixm:referenceTemperature)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:when test="aixm:referenceTemperature/@xsi:nil='true'">
											<xsl:choose>
												<xsl:when test="aixm:referenceTemperature/@nilReason">
													<xsl:value-of select="concat('NIL:', aixm:referenceTemperature/@nilReason)"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="'NIL'"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>
										<xsl:otherwise>
											<xsl:choose>
												<xsl:when test="number(aixm:referenceTemperature) ge 0">
													<xsl:choose>
														<xsl:when test="contains(aixm:referenceTemperature, '+')">
															<xsl:value-of select="aixm:referenceTemperature"/>
														</xsl:when>
														<xsl:otherwise>
															<xsl:value-of select="concat('+', aixm:referenceTemperature)"/>
														</xsl:otherwise>
													</xsl:choose>
												</xsl:when>
												<xsl:when test="number(aixm:referenceTemperature) lt 0">
													<xsl:value-of select="concat('-', aixm:referenceTemperature)"/>
												</xsl:when>
											</xsl:choose>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Unit of measurement [temperature] -->
								<xsl:variable name="AHP_ref_temp_uom" select="aixm:referenceTemperature/@uom"/>
								
								<!-- Altimeter check location description -->
								<xsl:variable name="AHP_alt_check_loc">
									<xsl:for-each select="aixm:annotation/aixm:Note[aixm:propertyName = ('altimeterCheckLocation') or contains(lower-case(aixm:translatedNote[1]/aixm:LinguisticNote/aixm:note), 'altimeter check location')]">
										<xsl:for-each select="aixm:translatedNote/aixm:LinguisticNote">
											<xsl:choose>
												<xsl:when test="contains(lower-case(aixm:note), 'altimeter check location')">
													<xsl:value-of select="concat(if (position() = 1) then '' else ' | ', if (aixm:note/@lang) then (concat('(', aixm:note/@lang, ') ')) else '', fcn:get-annotation-text(substring-after(aixm:note, ':')))"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="concat(if (position() = 1) then '' else ' | ', if (aixm:note/@lang) then (concat('(', aixm:note/@lang, ') ')) else '', fcn:get-annotation-text(aixm:note))"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:for-each>
									</xsl:for-each>
								</xsl:variable>
								
								<!-- Secondary power supply description -->
								<xsl:variable name="AHP_secondary_power_supply">
									<xsl:for-each select="aixm:annotation/aixm:Note[aixm:propertyName = ('secondaryPowerSupply') or contains(lower-case(aixm:translatedNote[1]/aixm:LinguisticNote/aixm:note), 'secondary power supply')]">
										<xsl:for-each select="aixm:translatedNote/aixm:LinguisticNote">
											<xsl:choose>
												<xsl:when test="contains(lower-case(aixm:note), 'secondary power supply')">
													<xsl:value-of select="concat(if (position() = 1) then '' else ' | ', if (aixm:note/@lang) then (concat('(', aixm:note/@lang, ') ')) else '', fcn:get-annotation-text(substring-after(aixm:note, ':')))"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="concat(if (position() = 1) then '' else ' | ', if (aixm:note/@lang) then (concat('(', aixm:note/@lang, ') ')) else '', fcn:get-annotation-text(aixm:note))"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:for-each>
									</xsl:for-each>
								</xsl:variable>
								
								<!-- Wind direction indicator description -->
								<xsl:variable name="AHP_wind_direction_indicator">
									<xsl:for-each select="aixm:annotation/aixm:Note[aixm:propertyName = ('windDirectionIndicator') or contains(lower-case(aixm:translatedNote[1]/aixm:LinguisticNote/aixm:note), 'wind direction indicator')]">
										<xsl:for-each select="aixm:translatedNote/aixm:LinguisticNote">
											<xsl:choose>
												<xsl:when test="contains(lower-case(aixm:note), 'wind direction indicator')">
													<xsl:value-of select="concat(if (position() = 1) then '' else ' | ', if (aixm:note/@lang) then (concat('(', aixm:note/@lang, ') ')) else '', fcn:get-annotation-text(substring-after(aixm:note, ':')))"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="concat(if (position() = 1) then '' else ' | ', if (aixm:note/@lang) then (concat('(', aixm:note/@lang, ') ')) else '', fcn:get-annotation-text(aixm:note))"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:for-each>
									</xsl:for-each>
								</xsl:variable>
								
								<!-- Landing direction indicator description -->
								<xsl:variable name="AHP_landing_direction_indicator">
									<xsl:for-each select="aixm:annotation/aixm:Note[aixm:propertyName = ('landingDirectionIndicator') or contains(lower-case(aixm:translatedNote[1]/aixm:LinguisticNote/aixm:note), 'landing direction indicator')]">
										<xsl:for-each select="aixm:translatedNote/aixm:LinguisticNote">
											<xsl:choose>
												<xsl:when test="contains(lower-case(aixm:note), 'landing direction indicator')">
													<xsl:value-of select="concat(if (position() = 1) then '' else ' | ', if (aixm:note/@lang) then (concat('(', aixm:note/@lang, ') ')) else '', fcn:get-annotation-text(substring-after(aixm:note, ':')))"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="concat(if (position() = 1) then '' else ' | ', if (aixm:note/@lang) then (concat('(', aixm:note/@lang, ') ')) else '', fcn:get-annotation-text(aixm:note))"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:for-each>
									</xsl:for-each>
								</xsl:variable>
								
								<!-- Transition altitude -->
								<xsl:variable name="AHP_transition_altitude">
									<xsl:choose>
										<xsl:when test="not(aixm:transitionAltitude)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:transitionAltitude)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Unit of measurement [transition altitude] -->
								<xsl:variable name="AHP_transition_alt_uom" select="aixm:transitionAltitude/@uom"/>
								
								<!-- Working hours -->
								<xsl:variable name="AHP_working_hours">
									<xsl:choose>
										<xsl:when test="not(aixm:availability/aixm:AirportHeliportAvailability)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:format-working-hours(aixm:availability/aixm:AirportHeliportAvailability)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Remark to working hours -->
								<xsl:variable name="AHP_working_hours_remarks">
									<xsl:for-each select=".//aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']/aixm:translatedNote/aixm:LinguisticNote">
										<xsl:choose>
											<xsl:when test="position() = 1">
												<xsl:value-of select="concat('(', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', ') ', fcn:get-annotation-text(aixm:note))"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="concat(' | (', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', ') ', fcn:get-annotation-text(aixm:note))"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:for-each>
								</xsl:variable>
								
								<!-- Remarks -->
								<xsl:variable name="AHP_remarks">
									<xsl:variable name="dataset_creation_date" select="//aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
									<xsl:if test="string-length($dataset_creation_date) gt 0">
										<xsl:value-of select="concat('Current time: ', $dataset_creation_date)"/>
									</xsl:if>
									<xsl:for-each select="aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote">
										<xsl:if test="
											((../../aixm:propertyName and (not(../../aixm:propertyName/@xsi:nil='true') or not(../../aixm:propertyName/@xsi:nil)) and ../../aixm:propertyName != ('landingDirectionIndicator','windDirectionIndicator','secondaryPowerSupply','altimeterCheckLocation','servedCity','arp','ARP')) or not(../../aixm:propertyName)) and
											(not(contains(lower-case(aixm:note), 'landing direction indicator')) and
											not(contains(lower-case(aixm:note), 'wind direction indicator')) and
											not(contains(lower-case(aixm:note), 'secondary power supply')) and
											not(contains(lower-case(aixm:note), 'altimeter check location')) and
											not(contains(lower-case(aixm:note), 'site description')) and
											not(contains(lower-case(aixm:note), 'aerodrome reference point')) and
											not(contains(aixm:note, 'CRC:')))">
											<xsl:choose>
												<xsl:when test="string-length($dataset_creation_date) = 0">
													<xsl:value-of select="concat('(', if (../../aixm:propertyName) then (concat(../../aixm:propertyName, ';')) else '', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', ') ', fcn:get-annotation-text(aixm:note))"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="concat(' | ', '(', if (../../aixm:propertyName) then (concat(../../aixm:propertyName, ';')) else '', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', ') ', fcn:get-annotation-text(aixm:note))"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:if>
									</xsl:for-each>
								</xsl:variable>
								
								<!-- Committed on -->
								<xsl:variable name="commit_date">
									<xsl:if test="aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate">
										<xsl:value-of select="fcn:get-date(aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Internal UID (master) -->
								<xsl:variable name="AHP_UUID">
									<xsl:value-of select="../../gml:identifier"/>
								</xsl:variable>
	
								<!-- AirportHeliport - Valid TimeSlice -->
								<xsl:variable name="AHP_timeslice">
									<xsl:value-of select="concat('BASELINE ', $max-sequence, '.', $max-correction)"/>
								</xsl:variable>
								
								<!-- FIR - Coded identifier -->
								<xsl:variable name="FIR_info" as="map(xs:string, xs:string)?">
									<xsl:choose>
										<xsl:when test="string($latitude_decimal) != '' and string($longitude_decimal) != ''">
											<xsl:sequence select="fcn:find-containing-fir-optimized($latitude_decimal, $longitude_decimal, $fir-geometry-cache, $doc-root)"/>
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
								<xsl:variable name="originator">
									<xsl:value-of select="aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
								</xsl:variable>
								
								<!-- Effective date -->
								<xsl:variable name="effective_date">
									<xsl:if test="gml:validTime/gml:TimePeriod/gml:beginPosition">
										<xsl:value-of select="fcn:get-date(gml:validTime/gml:TimePeriod/gml:beginPosition)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- System remark -->
								<xsl:variable name="system_remark" select="'Please obtain current usage data from dedicated report'"/>
								
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_designator) gt 0) then $AHP_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($ResponsibleStateOrIntlOrg_name) gt 0) then $ResponsibleStateOrIntlOrg_name else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($ResponsibleStateOrIntlOrg_timeslice) gt 0) then $ResponsibleStateOrIntlOrg_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_name) gt 0) then $AHP_name else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_ICAO_code) gt 0) then $AHP_ICAO_code else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_IATA_code) gt 0) then $AHP_IATA_code else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_type) gt 0) then $AHP_type else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_control_type) gt 0) then $AHP_control_type else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_nat_traffic) gt 0) then $AHP_nat_traffic else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_intl_traffic) gt 0) then $AHP_intl_traffic else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_scheduled_flight) gt 0) then $AHP_scheduled_flight else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_non_scheduled_flight) gt 0) then $AHP_non_scheduled_flight else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_private_flight) gt 0) then $AHP_private_flight else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_VFR_flight) gt 0) then $AHP_VFR_flight else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_IFR_flight) gt 0) then $AHP_IFR_flight else '&#160;'"/></td>
								</tr>
								<tr>
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($AHP_ARP_description) gt 0"><xsl:value-of select="$AHP_ARP_description" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_ARP_lat) gt 0) then $AHP_ARP_lat else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_ARP_long) gt 0) then $AHP_ARP_long else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_ARP_datum) gt 0) then $AHP_ARP_datum else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_ARP_geo_accuracy) gt 0) then $AHP_ARP_geo_accuracy else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_ARP_geo_acc_uom) gt 0) then $AHP_ARP_geo_acc_uom else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_ARP_elevation) gt 0) then $AHP_ARP_elevation else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_ARP_elev_acc) gt 0) then $AHP_ARP_elev_acc else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_ARP_geoid_und) gt 0) then $AHP_ARP_geoid_und else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_ARP_vert_dist_uom) gt 0) then $AHP_ARP_vert_dist_uom else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_CRC) gt 0) then $AHP_CRC else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_vertical_datum) gt 0) then $AHP_vertical_datum else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_served_city) gt 0) then $AHP_served_city else '&#160;'"/></td>
								</tr>
								<tr>
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($AHP_site_description) gt 0"><xsl:value-of select="$AHP_site_description" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_mag_var) gt 0) then $AHP_mag_var else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_mag_var_date) gt 0) then $AHP_mag_var_date else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_mag_var_change) gt 0) then $AHP_mag_var_change else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_ref_temp) gt 0) then $AHP_ref_temp else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_ref_temp_uom) gt 0) then $AHP_ref_temp_uom else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($OrgInCharge_name) gt 0) then $OrgInCharge_name else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($OrgInCharge_timeslice) gt 0) then $OrgInCharge_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($AHP_alt_check_loc) gt 0"><xsl:value-of select="$AHP_alt_check_loc" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
								</tr>
								<tr>
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($AHP_secondary_power_supply) gt 0"><xsl:value-of select="$AHP_secondary_power_supply" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
								</tr>
								<tr>
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($AHP_wind_direction_indicator) gt 0"><xsl:value-of select="$AHP_wind_direction_indicator" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
								</tr>
								<tr>
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($AHP_landing_direction_indicator) gt 0"><xsl:value-of select="$AHP_landing_direction_indicator" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_transition_altitude) gt 0) then $AHP_transition_altitude else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_transition_alt_uom) gt 0) then $AHP_transition_alt_uom else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_working_hours) gt 0) then $AHP_working_hours else '&#160;'"/></td>
								</tr>
								<tr>
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($AHP_working_hours_remarks) gt 0"><xsl:value-of select="$AHP_working_hours_remarks" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
								</tr>
								<tr>
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($AHP_remarks) gt 0"><xsl:value-of select="$AHP_remarks" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($commit_date) gt 0) then $commit_date else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_UUID) gt 0) then $AHP_UUID else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_timeslice) gt 0) then $AHP_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($FIR_designator) gt 0) then $FIR_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($FIR_timeslice) gt 0) then $FIR_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($originator) gt 0) then $originator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($system_remark) gt 0) then $system_remark else '&#160;'"/></td>
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
					<tr style="vertical-align:top">
						<td><font size="-1">featureTypes: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($feat_types) gt 0) then $feat_types else '&#160;'"/></font></td>
					</tr>
					<tr style="vertical-align:top">
						<td><font size="-1">excludedProperties: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($exc_properties) gt 0) then $exc_properties else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">includeReferencedFeaturesLevel: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($referenced_feat_level) gt 0) then $referenced_feat_level else '&#160;'"/></font></td>
					</tr>
					<tr style="vertical-align:top">
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
					<tr style="vertical-align:top">
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