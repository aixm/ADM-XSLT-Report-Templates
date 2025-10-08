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
	featureTypes: aixm:AirportHeliport aixm:Airspace
	includeReferencedFeaturesLevel: 2
	featureOccurrence: aixm:Airspace.aixm:type EQUALS 'FIR' OR aixm:Airspace.aixm:type EQUALS 'FIR_P'
	permanentBaseline: true
	spatialFilteringBy: Airspace
	spatialAreaUUID: *select FIR*
	spatialOperator: "Within"
	spatialValueOperator: "OR"
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

	<!-- Function to extract all polygon coordinates from a geometry including referenced GeoBorders -->
	<xsl:function name="fcn:get-all-polygon-coords" as="xs:double*">
		<xsl:param name="airspace-volume" as="element()?"/>
		<xsl:param name="root" as="document-node()"/>
		<xsl:variable name="coords" as="xs:double*">
			<xsl:for-each select="$airspace-volume//gml:curveMember">
				<xsl:choose>
					<!-- Handle direct coordinates -->
					<xsl:when test=".//gml:posList">
						<xsl:for-each select=".//gml:posList">
							<xsl:sequence select="for $coord in tokenize(normalize-space(.), '\s+') return xs:double($coord)"/>
						</xsl:for-each>
					</xsl:when>
					<!-- Handle xlink reference to GeoBorder -->
					<xsl:when test="@xlink:href and starts-with(@xlink:href, 'urn:uuid:')">
						<xsl:variable name="uuid" select="substring-after(@xlink:href, 'urn:uuid:')"/>
						<xsl:for-each select="$root//aixm:GeoBorder[gml:identifier = $uuid]//aixm:border//gml:posList">
							<xsl:sequence select="for $coord in tokenize(normalize-space(.), '\s+') return xs:double($coord)"/>
						</xsl:for-each>
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<xsl:sequence select="$coords"/>
	</xsl:function>

	<!-- Function to check if a point is inside a polygon using ray-casting algorithm -->
	<xsl:function name="fcn:point-in-polygon" as="xs:boolean">
		<xsl:param name="point-lat" as="xs:double"/>
		<xsl:param name="point-lon" as="xs:double"/>
		<xsl:param name="polygon-coords" as="xs:double*"/>
		<!-- Extract lat/lon pairs from the flat array -->
		<xsl:variable name="num-coords" select="count($polygon-coords)"/>
		<xsl:variable name="num-points" select="$num-coords div 2"/>
		<xsl:choose>
			<xsl:when test="$num-points lt 3">
				<xsl:sequence select="false()"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- Ray-casting algorithm: count intersections with edges -->
				<xsl:variable name="intersections" as="xs:integer">
					<xsl:variable name="counts" as="xs:integer*">
						<xsl:for-each select="1 to xs:integer($num-points)">
							<xsl:variable name="i" select="."/>
							<xsl:variable name="j" select="if ($i = $num-points) then 1 else $i + 1"/>
							<xsl:variable name="lat1" select="$polygon-coords[($i - 1) * 2 + 1]"/>
							<xsl:variable name="lon1" select="$polygon-coords[($i - 1) * 2 + 2]"/>
							<xsl:variable name="lat2" select="$polygon-coords[($j - 1) * 2 + 1]"/>
							<xsl:variable name="lon2" select="$polygon-coords[($j - 1) * 2 + 2]"/>
							<!-- Check if ray from point crosses this edge -->
							<xsl:variable name="crosses" select="
								(($lon1 gt $point-lon) != ($lon2 gt $point-lon)) and
								($point-lat lt ($lat2 - $lat1) * ($point-lon - $lon1) div ($lon2 - $lon1) + $lat1)
							"/>
							<xsl:sequence select="if ($crosses) then 1 else 0"/>
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
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and not(aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HX') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HO') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'NOTAM') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HOL') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SS') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SR') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'MON') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'TUE') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'WED') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'THU') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'FRI') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SAT') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SUN')]]) and aixm:operationalStatus = 'NORMAL'">
								<xsl:value-of select="'H24'"/>
							</xsl:when>
							<!-- insert 'H24' if there is an availability with operationalStatus='NORMAL' and a continuous service 24/7 Timesheet -->
							<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and (not(aixm:dayTil) or aixm:dayTil='ANY') and aixm:startTime='00:00' and (aixm:endTime='00:00' or aixm:endTime='24:00') and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'NORMAL'">
								<xsl:value-of select="'H24'"/>
							</xsl:when>
							<!-- insert 'HJ' if there is an availability with operationalStatus='NORMAL' and a sunrise to sunset Timesheet -->
							<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SR' and aixm:endEvent='SS' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'NORMAL'">
								<xsl:value-of select="'HJ'"/>
							</xsl:when>
							<!-- insert 'HN' if there is an availability with operationalStatus='NORMAL' and a sunset to sunrise Timesheet -->
							<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SS' and aixm:endEvent='SR' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO'] and aixm:operationalStatus = 'NORMAL'">
								<xsl:value-of select="'HN'"/>
							</xsl:when>
							<!-- insert 'HX' if there is an availability with operationalStatus='NORMAL', no Timesheet and corresponding note -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'HX')] and aixm:operationalStatus = 'NORMAL'">
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
							<!-- insert 'CLSD' if there is an availability with operationalStatus='CLOSED' and no Timesheet -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and aixm:operationalStatus = 'CLOSED'">
								<xsl:value-of select="'CLSD'"/>
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
											<xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
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
								<xsl:if test="fcn:point-in-polygon($lat, $lon, $coords)">
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
										<xsl:if test="fcn:point-in-polygon($lat, $lon, $ref-coords)">
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
	
	<xsl:template match="/">
		
		<html xmlns="http://www.w3.org/1999/xhtml">
			
			<head>
				<meta http-equiv="Expires" content="120" />
				<title>SDO Reporting - AD with FIR</title>
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
					<b>AD with FIR</b>
				</center>
				<hr/>
				
				<table border="0" style="border-spacing: 8px 4px">
					<tbody>
						
						<tr style="white-space:nowrap">
							<td><strong>Identification</strong></td>
							<td><strong>Responsible State or international organisation<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Name</strong></td>
							<td><strong>Responsible State or international organisation<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Valid TimeSlice</strong></td>
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
							<td><strong>Organisation in charge<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Name</strong></td>
							<td><strong>Organisation in charge<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Valid TimeSlice</strong></td>
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
							<td><strong>AirportHeliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Valid TimeSlice</strong></td>
							<td><strong>FIR<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Coded identifier</strong></td>
							<td><strong>FIR<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Valid TimeSlice</strong></td>
							<td><strong>Originator</strong></td>
							<td><strong>Effective date</strong></td>
							<td><strong>System Remark</strong></td>
						</tr>

						<xsl:for-each select="//aixm:AirportHeliport">
							<xsl:sort select="(aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)][aixm:correctionNumber = max(../aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)]/aixm:correctionNumber)])[1]/aixm:designator" order="ascending"/>
							<!-- Get all BASELINE time slices for this feature -->
							<xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']"/>
							<!-- Find the maximum sequenceNumber -->
							<xsl:variable name="max-sequence" select="max($baseline-timeslices/aixm:sequenceNumber)"/>
							<!-- Get time slices with the maximum sequenceNumber, then find max correctionNumber -->
							<xsl:variable name="max-correction" select="max($baseline-timeslices[aixm:sequenceNumber = $max-sequence]/aixm:correctionNumber)"/>
							<!-- Select the latest time slice -->
							<xsl:variable name="latest-timeslice" select="$baseline-timeslices[aixm:sequenceNumber = $max-sequence and aixm:correctionNumber = $max-correction][1]"/>

							<xsl:for-each select="$latest-timeslice">
							
								<!-- Identification -->
								<xsl:variable name="AHP_designator" select="aixm:designator"/>
								
								<!-- Organisation in charge -->
								<xsl:variable name="Org_in_charge_UUID" select="substring-after(aixm:responsibleOrganisation/aixm:AirportHeliportResponsibilityOrganisation/aixm:theOrganisationAuthority/@xlink:href, 'urn:uuid:')"/>
	
								<!-- Get the latest BASELINE time slice for this OrganisationAuthority -->
								<xsl:variable name="org-baseline-ts" select="//aixm:OrganisationAuthority[gml:identifier = $Org_in_charge_UUID]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="org-max-seq" select="max($org-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="org-max-corr" select="max($org-baseline-ts[aixm:sequenceNumber = $org-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="org-latest-ts" select="$org-baseline-ts[aixm:sequenceNumber = $org-max-seq and aixm:correctionNumber = $org-max-corr][1]"/>
	
								<xsl:variable name="Org_in_charge_name">
									<xsl:value-of select="$org-latest-ts/aixm:name"/>
								</xsl:variable>
								<xsl:variable name="Org_in_charge_timeslice">
									<xsl:value-of select="concat('BASELINE ', $org-max-seq, '.', $org-max-corr)"/>
								</xsl:variable>
	
								<!-- Responsible State or international organisaton - Name -->
								<xsl:variable name="Owner_organisation_UUID" select="substring-after($org-latest-ts/aixm:relatedOrganisationAuthority/aixm:OrganisationAuthorityAssociation[aixm:type = 'OWNED_BY' and aixm:theOrganisationAuthority/@xlink:href]/aixm:theOrganisationAuthority/@xlink:href[1], 'urn:uuid:')"/>
								<!-- Get the latest BASELINE time slice for the owner OrganisationAuthority -->
								<xsl:variable name="owner-baseline-ts" select="//aixm:OrganisationAuthority[gml:identifier = $Owner_organisation_UUID]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="owner-max-seq" select="max($owner-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="owner-max-corr" select="max($owner-baseline-ts[aixm:sequenceNumber = $owner-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="Resp_state_name">
									<xsl:choose>
										<xsl:when test="$org-latest-ts/aixm:type = 'STATE'">
											<xsl:value-of select="$org-latest-ts/aixm:name"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="$owner-baseline-ts[aixm:sequenceNumber = $owner-max-seq and aixm:correctionNumber = $owner-max-corr][1]/aixm:name"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
									
								<!-- Responsible State or international organisaton - Valid TimeSlice -->
								<xsl:variable name="Resp_state_timeslice">
									<xsl:choose>
										<xsl:when test="$org-latest-ts/aixm:type = 'STATE'">
											<xsl:value-of select="concat('BASELINE ', $org-max-seq, '.', $org-max-corr)"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="concat('BASELINE ', $owner-max-seq, '.', $owner-max-corr)"/>
										</xsl:otherwise>
									</xsl:choose>
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
									<xsl:for-each select="aixm:annotation/aixm:Note[aixm:propertyName = ('arp', 'ARP') or contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'aerodrome reference point')]">
										<xsl:for-each select="aixm:translatedNote/aixm:LinguisticNote/aixm:note">
											<xsl:choose>
												<xsl:when test="contains(lower-case(.[not(@lang) or @lang=('en','eng')]), 'aerodrome reference point description')">
													<xsl:value-of select="substring-after(.[not(@lang) or @lang=('en','eng')], ':')"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="."/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:for-each>
									</xsl:for-each>
								</xsl:variable>
								
								<!-- Latitude -->
								<xsl:variable name="AHP_ARP_lat">
									<xsl:if test="aixm:ARP/aixm:ElevatedPoint/gml:pos">
										<xsl:variable name="latitude" select="number(substring-before(aixm:ARP/aixm:ElevatedPoint/gml:pos, ' '))"/>
										<xsl:variable name="lat_whole" select="string(floor(abs($latitude)))"/>
										<xsl:variable name="lat_frac" select="string(abs($latitude) - floor(abs($latitude)))"/>
										<xsl:variable name="lat_deg" select="if (string-length($lat_whole) = 1) then concat('0', $lat_whole) else $lat_whole"/>
										<xsl:variable name="lat_min_whole" select="floor(number($lat_frac) * 60)"/>
										<xsl:variable name="lat_min_frac" select="number($lat_frac) * 60 - $lat_min_whole"/>
										<xsl:variable name="lat_min" select="if (string-length(string($lat_min_whole)) = 1) then concat('0', string($lat_min_whole)) else string($lat_min_whole)"/>
										<xsl:variable name="lat_sec" select="format-number($lat_min_frac * 60, '0.00')"/>
										<xsl:variable name="lat_sec" select="if (string-length(string(floor(number($lat_sec)))) = 1) then concat('0', string($lat_sec)) else string($lat_sec)"/>
										<xsl:value-of select="concat($lat_deg, $lat_min, $lat_sec, if ($latitude ge 0) then 'N' else 'S')"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Longitude -->
								<xsl:variable name="AHP_ARP_long">
									<xsl:if test="aixm:ARP/aixm:ElevatedPoint/gml:pos">
										<xsl:variable name="longitude" select="number(substring-after(aixm:ARP/aixm:ElevatedPoint/gml:pos, ' '))"/>
										<xsl:variable name="long_whole" select="string(floor(abs($longitude)))"/>
										<xsl:variable name="long_frac" select="string(abs($longitude) - floor(abs($longitude)))"/>
										<xsl:variable name="long_deg" select="if (string-length($long_whole) != 3) then (if (string-length($long_whole) = 1) then concat('00', $long_whole) else concat('0', $long_whole)) else $long_whole"/>
										<xsl:variable name="long_min_whole" select="floor(number($long_frac) * 60)"/>
										<xsl:variable name="long_min_frac" select="number($long_frac) * 60 - $long_min_whole"/>
										<xsl:variable name="long_min" select="if (string-length(string($long_min_whole)) = 1) then concat('0', string($long_min_whole)) else string($long_min_whole)"/>
										<xsl:variable name="long_sec" select="format-number($long_min_frac * 60, '0.00')"/>
										<xsl:variable name="long_sec" select="if (string-length(string(floor(number($long_sec)))) = 1) then concat('0', string($long_sec)) else string($long_sec)"/>
										<xsl:value-of select="concat($long_deg, $long_min, $long_sec, if ($longitude ge 0) then 'E' else 'W')"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Datum -->
								<xsl:variable name="AHP_ARP_datum">
									<xsl:value-of select="concat(substring(aixm:ARP/aixm:ElevatedPoint/@srsName, 17,5), substring(aixm:ARP/aixm:ElevatedPoint/@srsName, 23,4))"/>
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
									<xsl:for-each select="aixm:annotation/aixm:Note[aixm:propertyName = ('servedCity') or contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'site description')]">
										<xsl:for-each select="aixm:translatedNote/aixm:LinguisticNote/aixm:note">
											<xsl:choose>
												<xsl:when test="contains(.[not(@lang) or @lang=('en','eng')], ':')">
													<xsl:value-of select="substring-after(.[not(@lang) or @lang=('en','eng')], ':')"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="."/>
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
									<xsl:for-each select="aixm:annotation/aixm:Note[aixm:propertyName = ('altimeterCheckLocation') or contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'altimeter check location')]">
										<xsl:for-each select="aixm:translatedNote/aixm:LinguisticNote/aixm:note">
											<xsl:choose>
												<xsl:when test="contains(.[not(@lang) or @lang=('en','eng')], ':')">
													<xsl:value-of select="substring-after(.[not(@lang) or @lang=('en','eng')], ':')"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="."/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:for-each>
									</xsl:for-each>
								</xsl:variable>
								
								<!-- Secondary power supply description -->
								<xsl:variable name="AHP_secondary_power_supply">
									<xsl:for-each select="aixm:annotation/aixm:Note[aixm:propertyName = ('secondaryPowerSupply') or contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'secondary power supply')]">
										<xsl:for-each select="aixm:translatedNote/aixm:LinguisticNote/aixm:note">
											<xsl:choose>
												<xsl:when test="contains(.[not(@lang) or @lang=('en','eng')], ':')">
													<xsl:value-of select="substring-after(.[not(@lang) or @lang=('en','eng')], ':')"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="."/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:for-each>
									</xsl:for-each>
								</xsl:variable>
								
								<!-- Wind direction indicator description -->
								<xsl:variable name="AHP_wind_direction_indicator">
									<xsl:for-each select="aixm:annotation/aixm:Note[aixm:propertyName = ('windDirectionIndicator') or contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'wind direction indicator')]">
										<xsl:for-each select="aixm:translatedNote/aixm:LinguisticNote/aixm:note">
											<xsl:choose>
												<xsl:when test="contains(.[not(@lang) or @lang=('en','eng')], ':')">
													<xsl:value-of select="substring-after(.[not(@lang) or @lang=('en','eng')], ':')"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="."/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:for-each>
									</xsl:for-each>
								</xsl:variable>
								
								<!-- Landing direction indicator description -->
								<xsl:variable name="AHP_landing_direction_indicator">
									<xsl:for-each select="aixm:annotation/aixm:Note[aixm:propertyName = ('landingDirectionIndicator') or contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'landing direction indicator')]">
										<xsl:for-each select="aixm:translatedNote/aixm:LinguisticNote/aixm:note">
											<xsl:choose>
												<xsl:when test="contains(.[not(@lang) or @lang=('en','eng')], ':')">
													<xsl:value-of select="substring-after(.[not(@lang) or @lang=('en','eng')], ':')"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="."/>
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
								<xsl:variable name="AHP_remarks">
									<xsl:variable name="dataset_creation_date" select="//aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
									<xsl:if test="string-length($dataset_creation_date) gt 0">
										<xsl:value-of select="concat('Current time: ', $dataset_creation_date)"/>
									</xsl:if>
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
									<xsl:if test="aixm:ARP/aixm:ElevatedPoint/gml:pos">
										<xsl:variable name="arp-coords" select="aixm:ARP/aixm:ElevatedPoint/gml:pos"/>
										<xsl:variable name="arp-lat" select="xs:double(substring-before($arp-coords, ' '))"/>
										<xsl:variable name="arp-lon" select="xs:double(substring-after($arp-coords, ' '))"/>
										<xsl:sequence select="fcn:find-containing-fir($arp-lat, $arp-lon, /)"/>
									</xsl:if>
								</xsl:variable>
	
								<xsl:variable name="FIR_designator">
									<xsl:if test="exists($FIR_info)">
										<xsl:value-of select="$FIR_info?designator"/>
									</xsl:if>
								</xsl:variable>
	
								<!-- FIR - Valid TimeSlice -->
								<xsl:variable name="FIR_timeslice">
									<xsl:if test="exists($FIR_info)">
										<xsl:value-of select="concat('BASELINE ', $FIR_info?sequenceNumber, '.', $FIR_info?correctionNumber)"/>
									</xsl:if>
								</xsl:variable>
								
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
								
								<tr style="white-space:nowrap;vertical-align:top;">
									<td><xsl:value-of select="if (string-length($AHP_designator) gt 0) then $AHP_designator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($Resp_state_name) gt 0) then $Resp_state_name else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($Resp_state_timeslice) gt 0) then $Resp_state_timeslice else '&#160;'"/></td>
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
									<td><xsl:value-of select="if (string-length($Org_in_charge_name) gt 0) then $Org_in_charge_name else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($Org_in_charge_timeslice) gt 0) then $Org_in_charge_timeslice else '&#160;'"/></td>
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
									<td><xsl:value-of select="if (string-length($AHP_timeslice) gt 0) then $AHP_timeslice else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($FIR_designator) gt 0) then $FIR_designator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($FIR_timeslice) gt 0) then $FIR_timeslice else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($originator) gt 0) then $originator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($system_remark) gt 0) then $system_remark else '&#160;'"/></td>
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