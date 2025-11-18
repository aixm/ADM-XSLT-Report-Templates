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
       featureTypes: aixm:AirportHeliport
  permanentBaseline: true
          dataScope: ReleasedData
        AIXMversion: 5.1.1
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
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	exclude-result-prefixes="xsl uuid message gts gco xsd gml gss gsr gmd aixm event xlink xs xsi aixm_ds_xslt ead-audit fcn map">

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
	
	<!-- Get annotation text escaping special HTML characters -->
	<xsl:function name="fcn:get-annotation-text" as="xs:string">
		<xsl:param name="raw_text" as="xs:string"/>
		<!-- First, escape special HTML characters in the raw text before processing -->
		<xsl:variable name="escaped_raw_text" select="replace(replace($raw_text, '&lt;', '&amp;lt;'), '&gt;', '&amp;gt;')"/>
		<xsl:variable name="lines" select="for $line in tokenize($escaped_raw_text, '&#xA;') return normalize-space($line)"/>
		<xsl:variable name="non_empty_lines" select="$lines[string-length(.) gt 0]"/>
		<xsl:value-of select="string-join($non_empty_lines, ' ')"/>
	</xsl:function>

	<!-- Function to transform AIXM property values to display text -->
	<xsl:function name="fcn:transform-value" as="xs:string">
		<xsl:param name="value" as="xs:string"/>
		<xsl:param name="property-name" as="xs:string"/>
		<xsl:choose>
			<!-- Handle empty values -->
			<xsl:when test="string-length($value) = 0">
				<xsl:value-of select="''"/>
			</xsl:when>
			<!-- Handle OTHER values -->
			<xsl:when test="starts-with($value, 'OTHER:')">
				<xsl:value-of select="substring-after($value, 'OTHER:')"/>
			</xsl:when>
			<xsl:when test="$value = 'OTHER'">
				<xsl:value-of select="'OTHER'"/>
			</xsl:when>
			<!-- Transform specific property values for FLIGHT -->
			<xsl:when test="$property-name = 'rule'">
				<xsl:choose>
					<xsl:when test="$value = 'ALL'">IV</xsl:when>
					<xsl:when test="$value = 'IFR'">I</xsl:when>
					<xsl:when test="$value = 'VFR'">V</xsl:when>
					<xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$property-name = 'flight-type'">
				<xsl:choose>
					<xsl:when test="$value = 'ALL'">ANY</xsl:when>
					<xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$property-name = 'status'">
				<xsl:choose>
					<xsl:when test="$value = 'EMERGENCY'">EMERG</xsl:when>
					<xsl:when test="$value = 'ALL'">ANY</xsl:when>
					<xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$property-name = 'military'">
				<xsl:choose>
					<xsl:when test="$value = 'ALL'">ANY</xsl:when>
					<xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$property-name = 'origin'">
				<xsl:choose>
					<xsl:when test="$value = 'ALL'">ANY</xsl:when>
					<xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$property-name = 'purpose'">
				<xsl:choose>
					<xsl:when test="$value = 'SCHEDULED'">S</xsl:when>
					<xsl:when test="$value = 'NON_SCHEDULED'">NS</xsl:when>
					<xsl:when test="$value = 'PRIVATE'">P</xsl:when>
					<xsl:when test="$value = 'AIR_TRAINING'">TRG</xsl:when>
					<xsl:when test="$value = 'AIR_WORK'">WORK</xsl:when>
					<xsl:when test="$value = 'PARTICIPANT'">PARTICIPANT</xsl:when>
					<xsl:when test="$value = 'ALL'">ANY</xsl:when>
					<xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<!-- Transform specific property values for AIRCRAFT -->
			<xsl:when test="$property-name = 'engine'">
				<xsl:choose>
					<xsl:when test="$value = 'JET'">J</xsl:when>
					<xsl:when test="$value = 'PISTON'">P</xsl:when>
					<xsl:when test="$value = 'TURBOPROP'">T</xsl:when>
					<xsl:when test="$value = 'ELECTRIC'">E</xsl:when>
					<xsl:when test="$value = 'ALL'">ANY</xsl:when>
					<xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="$property-name = 'aircraft-type'">
				<xsl:choose>
					<xsl:when test="$value = 'LANDPLANE'">L</xsl:when>
					<xsl:when test="$value = 'SEAPLANE'">S</xsl:when>
					<xsl:when test="$value = 'AMPHIBIAN'">A</xsl:when>
					<xsl:when test="$value = 'HELICOPTER'">H</xsl:when>
					<xsl:when test="$value = 'GYROCOPTER'">G</xsl:when>
					<xsl:when test="$value = 'TILT_WING'">T</xsl:when>
					<xsl:when test="$value = 'STOL'">R</xsl:when>
					<xsl:when test="$value = 'GLIDER'">E</xsl:when>
					<xsl:when test="$value = 'HANGGLIDER'">N</xsl:when>
					<xsl:when test="$value = 'PARAGLIDER'">P</xsl:when>
					<xsl:when test="$value = 'ULTRA_LIGHT'">U</xsl:when>
					<xsl:when test="$value = 'BALLOON'">B</xsl:when>
					<xsl:when test="$value = 'UAV'">D</xsl:when>
					<xsl:when test="$value = 'ALL'">ANY</xsl:when>
					<xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<!-- Transform specific property values for EventInterpretation -->
			<xsl:when test="$property-name = 'event-interpretation'">
				<xsl:choose>
					<xsl:when test="$value = 'EARLIEST'">E</xsl:when>
					<xsl:when test="$value = 'LATEST'">L</xsl:when>
				</xsl:choose>
			</xsl:when>
			<!-- Default: return value as-is -->
			<xsl:otherwise>
				<xsl:value-of select="$value"/>
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
								<xsl:value-of select="'TIMSH'"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:sequence select="string($result)"/>
	</xsl:function>

	<!-- Recursive template to process ConditionCombination and generate rows for timeIntervals -->
	<xsl:template name="process-condition">
		<xsl:param name="condition" as="element()"/>
		<xsl:param name="usage-element" as="element()"/>
		<xsl:param name="condition-level" as="xs:string"/>
		<xsl:param name="airport-vars" as="map(xs:string, xs:string)"/>

		<!-- Get aircraft and flight data at this condition level -->
		<xsl:variable name="aircraft-data" select="$condition/aixm:aircraft/aixm:AircraftCharacteristic"/>
		<xsl:variable name="flight-data" select="$condition/aixm:flight/aixm:FlightCharacteristic"/>

		<!-- Count aircraft and flights -->
		<xsl:variable name="aircraft-count" select="count($aircraft-data)"/>
		<xsl:variable name="flight-count" select="count($flight-data)"/>

		<!-- Generate rows for timeIntervals at this level -->
		<xsl:for-each select="$condition/aixm:timeInterval/aixm:Timesheet">
			<xsl:variable name="current-timesheet" select="."/>

			<xsl:choose>
				<!-- Case 1: Exactly one aircraft and one flight - place on same row -->
				<xsl:when test="$aircraft-count = 1 and $flight-count = 1">
					<xsl:call-template name="generate-row">
						<xsl:with-param name="timesheet" select="$current-timesheet"/>
						<xsl:with-param name="usage-element" select="$usage-element"/>
						<xsl:with-param name="condition-element" select="$condition"/>
						<xsl:with-param name="condition-level" select="$condition-level"/>
						<xsl:with-param name="airport-vars" select="$airport-vars"/>
						<xsl:with-param name="aircraft-index" select="1"/>
						<xsl:with-param name="flight-index" select="1"/>
						<xsl:with-param name="aircraft-data" select="$aircraft-data"/>
						<xsl:with-param name="flight-data" select="$flight-data"/>
					</xsl:call-template>
				</xsl:when>

				<!-- Case 2: Multiple aircraft and/or multiple flights - place each on separate rows -->
				<xsl:otherwise>
					<!-- Generate rows for all aircraft -->
					<xsl:for-each select="1 to $aircraft-count">
						<xsl:variable name="aircraft-index" select="."/>
						<xsl:call-template name="generate-row">
							<xsl:with-param name="timesheet" select="$current-timesheet"/>
							<xsl:with-param name="usage-element" select="$usage-element"/>
							<xsl:with-param name="condition-element" select="$condition"/>
							<xsl:with-param name="condition-level" select="$condition-level"/>
							<xsl:with-param name="airport-vars" select="$airport-vars"/>
							<xsl:with-param name="aircraft-index" select="$aircraft-index"/>
							<xsl:with-param name="flight-index" select="0"/>
							<xsl:with-param name="aircraft-data" select="$aircraft-data"/>
							<xsl:with-param name="flight-data" select="$flight-data"/>
						</xsl:call-template>
					</xsl:for-each>

					<!-- Generate rows for all flights -->
					<xsl:for-each select="1 to $flight-count">
						<xsl:variable name="flight-index" select="."/>
						<xsl:call-template name="generate-row">
							<xsl:with-param name="timesheet" select="$current-timesheet"/>
							<xsl:with-param name="usage-element" select="$usage-element"/>
							<xsl:with-param name="condition-element" select="$condition"/>
							<xsl:with-param name="condition-level" select="$condition-level"/>
							<xsl:with-param name="airport-vars" select="$airport-vars"/>
							<xsl:with-param name="aircraft-index" select="0"/>
							<xsl:with-param name="flight-index" select="$flight-index"/>
							<xsl:with-param name="aircraft-data" select="$aircraft-data"/>
							<xsl:with-param name="flight-data" select="$flight-data"/>
						</xsl:call-template>
					</xsl:for-each>

					<!-- If no aircraft and no flights, generate one empty row -->
					<xsl:if test="$aircraft-count = 0 and $flight-count = 0">
						<xsl:call-template name="generate-row">
							<xsl:with-param name="timesheet" select="$current-timesheet"/>
							<xsl:with-param name="usage-element" select="$usage-element"/>
							<xsl:with-param name="condition-element" select="$condition"/>
							<xsl:with-param name="condition-level" select="$condition-level"/>
							<xsl:with-param name="airport-vars" select="$airport-vars"/>
							<xsl:with-param name="aircraft-index" select="0"/>
							<xsl:with-param name="flight-index" select="0"/>
							<xsl:with-param name="aircraft-data" select="$aircraft-data"/>
							<xsl:with-param name="flight-data" select="$flight-data"/>
						</xsl:call-template>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>

		<!-- Process subConditions recursively -->
		<xsl:for-each select="$condition/aixm:subCondition/aixm:ConditionCombination">
			<xsl:variable name="subcondition-index" select="position()"/>
			<xsl:call-template name="process-condition">
				<xsl:with-param name="condition" select="."/>
				<xsl:with-param name="usage-element" select="$usage-element"/>
				<xsl:with-param name="condition-level" select="concat($condition-level, '.', $subcondition-index)"/>
				<xsl:with-param name="airport-vars" select="$airport-vars"/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>

	<!-- Template to generate a single table row -->
	<xsl:template name="generate-row">
		<xsl:param name="timesheet" as="element()"/>
		<xsl:param name="usage-element" as="element()"/>
		<xsl:param name="condition-element" as="element()"/>
		<xsl:param name="condition-level" as="xs:string"/>
		<xsl:param name="airport-vars" as="map(xs:string, xs:string)"/>
		<xsl:param name="aircraft-index" as="xs:integer"/>
		<xsl:param name="flight-index" as="xs:integer"/>
		<xsl:param name="aircraft-data" as="element()*"/>
		<xsl:param name="flight-data" as="element()*"/>

		<!-- Detect working hours code for this timesheet -->
		<xsl:variable name="working-hours-code">
			<xsl:variable name="temp-availability">
				<aixm:AirportHeliportAvailability xmlns:aixm="http://www.aixm.aero/schema/5.1.1">
					<aixm:operationalStatus>NORMAL</aixm:operationalStatus>
					<aixm:timeInterval>
						<xsl:copy-of select="$timesheet"/>
					</aixm:timeInterval>
					<xsl:copy-of select="$condition-element/aixm:annotation"/>
				</aixm:AirportHeliportAvailability>
			</xsl:variable>
			<xsl:value-of select="fcn:format-working-hours($temp-availability/aixm:AirportHeliportAvailability)"/>
		</xsl:variable>

		<!-- Extract same-level annotations for this timesheet -->
		<xsl:variable name="timesheet-remarks">
			<xsl:for-each select="$condition-element/aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']/aixm:translatedNote/aixm:LinguisticNote">
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

		<!-- Extract timesheet data -->
		<xsl:variable name="time-reference">
			<xsl:choose>
				<xsl:when test="not($timesheet/aixm:timeReference)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:insert-value($timesheet/aixm:timeReference)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="daylight-saving">
			<xsl:choose>
				<xsl:when test="not($timesheet/aixm:daylightSavingAdjust)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:insert-value($timesheet/aixm:daylightSavingAdjust)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="start-date-yearly">
			<xsl:choose>
				<xsl:when test="not($timesheet/aixm:startDate)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:insert-value($timesheet/aixm:startDate)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="end-date-yearly">
			<xsl:choose>
				<xsl:when test="not($timesheet/aixm:endDate)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:insert-value($timesheet/aixm:endDate)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="day-start">
			<xsl:choose>
				<xsl:when test="not($timesheet/aixm:day)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:insert-value($timesheet/aixm:day)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="day-end">
			<xsl:choose>
				<xsl:when test="not($timesheet/aixm:dayTil)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:insert-value($timesheet/aixm:dayTil)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="start-time">
			<xsl:choose>
				<xsl:when test="not($timesheet/aixm:startTime)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:insert-value($timesheet/aixm:startTime)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="start-event">
			<xsl:choose>
				<xsl:when test="not($timesheet/aixm:startEvent)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:insert-value($timesheet/aixm:startEvent)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="start-relative">
			<xsl:choose>
				<xsl:when test="not($timesheet/aixm:startTimeRelativeEvent)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:when test="$timesheet/aixm:startTimeRelativeEvent/@xsi:nil='true'">
					<xsl:choose>
						<xsl:when test="$timesheet/aixm:startTimeRelativeEvent/@nilReason">
							<xsl:value-of select="concat('NIL:', $timesheet/aixm:startTimeRelativeEvent/@nilReason)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'NIL'"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat($timesheet/aixm:startTimeRelativeEvent, ' ', $timesheet/aixm:startTimeRelativeEvent/@uom)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="start-interpretation">
			<xsl:choose>
				<xsl:when test="not($timesheet/aixm:startEventInterpretation)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:when test="$timesheet/aixm:startEventInterpretation/@xsi:nil='true'">
					<xsl:value-of select="fcn:insert-value($timesheet/aixm:startEventInterpretation)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:transform-value(string($timesheet/aixm:startEventInterpretation), 'event-interpretation')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="end-time">
			<xsl:choose>
				<xsl:when test="not($timesheet/aixm:endTime)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:insert-value($timesheet/aixm:endTime)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="end-event">
			<xsl:choose>
				<xsl:when test="not($timesheet/aixm:endEvent)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:insert-value($timesheet/aixm:endEvent)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="end-relative">
			<xsl:choose>
				<xsl:when test="not($timesheet/aixm:endTimeRelativeEvent)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:when test="$timesheet/aixm:endTimeRelativeEvent/@xsi:nil='true'">
					<xsl:choose>
						<xsl:when test="$timesheet/aixm:endTimeRelativeEvent/@nilReason">
							<xsl:value-of select="concat('NIL:', $timesheet/aixm:endTimeRelativeEvent/@nilReason)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'NIL'"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat($timesheet/aixm:endTimeRelativeEvent, ' ', $timesheet/aixm:endTimeRelativeEvent/@uom)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="end-interpretation">
			<xsl:choose>
				<xsl:when test="not($timesheet/aixm:endEventInterpretation)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:when test="$timesheet/aixm:endEventInterpretation/@xsi:nil='true'">
					<xsl:value-of select="fcn:insert-value($timesheet/aixm:endEventInterpretation)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:transform-value(string($timesheet/aixm:endEventInterpretation), 'event-interpretation')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<!-- Logical Operator -->
		<xsl:variable name="logical-operator">
			<xsl:choose>
				<xsl:when test="not($condition-element/aixm:logicalOperator)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:insert-value($condition-element/aixm:logicalOperator)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<!-- Get the specific aircraft and flight for this row -->
		<xsl:variable name="current-aircraft" select="if ($aircraft-index le count($aircraft-data)) then $aircraft-data[$aircraft-index] else ()"/>
		<xsl:variable name="current-flight" select="if ($flight-index le count($flight-data)) then $flight-data[$flight-index] else ()"/>

		<!-- Extract aircraft info for current aixm:aircraft -->
		<xsl:variable name="aircraft-equipment">
			<xsl:if test="$current-aircraft">
				<xsl:variable name="equip-list" as="xs:string*">
					<xsl:choose>
						<xsl:when test="not($current-aircraft/aixm:navigationEquipment)">
							<xsl:sequence select="string('nil')"/>
						</xsl:when>
						<xsl:when test="$current-aircraft/aixm:navigationEquipment/@xsi:nil='true'">
							<xsl:sequence select="fcn:insert-value($current-aircraft/aixm:navigationEquipment)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:sequence select="string($current-aircraft/aixm:navigationEquipment)"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:choose>
						<xsl:when test="not($current-aircraft/aixm:navigationSpecification)">
							<xsl:sequence select="string('nil')"/>
						</xsl:when>
						<xsl:when test="$current-aircraft/aixm:navigationSpecification/@xsi:nil='true'">
							<xsl:sequence select="fcn:insert-value($current-aircraft/aixm:navigationSpecification)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:sequence select="string($current-aircraft/aixm:navigationSpecification)"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:choose>
						<xsl:when test="not($current-aircraft/aixm:verticalSeparationCapability)">
							<xsl:sequence select="string('nil')"/>
						</xsl:when>
						<xsl:when test="$current-aircraft/aixm:verticalSeparationCapability/@xsi:nil='true'">
							<xsl:sequence select="fcn:insert-value($current-aircraft/aixm:verticalSeparationCapability)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:sequence select="string($current-aircraft/aixm:verticalSeparationCapability)"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:choose>
						<xsl:when test="not($current-aircraft/aixm:antiCollisionAndSeparationEquipment)">
							<xsl:sequence select="string('nil')"/>
						</xsl:when>
						<xsl:when test="$current-aircraft/aixm:antiCollisionAndSeparationEquipment/@xsi:nil='true'">
							<xsl:sequence select="fcn:insert-value($current-aircraft/aixm:antiCollisionAndSeparationEquipment)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:sequence select="string($current-aircraft/aixm:antiCollisionAndSeparationEquipment)"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:choose>
						<xsl:when test="not($current-aircraft/aixm:communicationEquipment)">
							<xsl:sequence select="string('nil')"/>
						</xsl:when>
						<xsl:when test="$current-aircraft/aixm:communicationEquipment/@xsi:nil='true'">
							<xsl:sequence select="fcn:insert-value($current-aircraft/aixm:communicationEquipment)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:sequence select="string($current-aircraft/aixm:communicationEquipment)"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:choose>
						<xsl:when test="not($current-aircraft/aixm:surveillanceEquipment)">
							<xsl:sequence select="string('nil')"/>
						</xsl:when>
						<xsl:when test="$current-aircraft/aixm:surveillanceEquipment/@xsi:nil='true'">
							<xsl:sequence select="fcn:insert-value($current-aircraft/aixm:surveillanceEquipment)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:sequence select="string($current-aircraft/aixm:surveillanceEquipment)"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:choose>
						<xsl:when test="not($current-aircraft/aixm:aircraftLandingCategory)">
							<xsl:sequence select="string('nil')"/>
						</xsl:when>
						<xsl:when test="$current-aircraft/aixm:aircraftLandingCategory/@xsi:nil='true'">
							<xsl:sequence select="fcn:insert-value($current-aircraft/aixm:aircraftLandingCategory)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:sequence select="string($current-aircraft/aixm:aircraftLandingCategory)"/>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:choose>
						<xsl:when test="not($current-aircraft/aixm:wakeTurbulence)">
							<xsl:sequence select="string('nil')"/>
						</xsl:when>
						<xsl:when test="$current-aircraft/aixm:wakeTurbulence/@xsi:nil='true'">
							<xsl:sequence select="fcn:insert-value($current-aircraft/aixm:wakeTurbulence)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:sequence select="string($current-aircraft/aixm:wakeTurbulence)"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:value-of select="string-join($equip-list, ' | ')"/>
			</xsl:if>
		</xsl:variable>

		<xsl:variable name="aircraft-type">
			<xsl:choose>
				<xsl:when test="not($current-aircraft/aixm:type)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:when test="$current-aircraft/aixm:type/@xsi:nil='true'">
					<xsl:value-of select="fcn:insert-value($current-aircraft/aixm:type)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:transform-value(string($current-aircraft/aixm:type), 'aircraft-type')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="aircraft-engine">
			<xsl:choose>
				<xsl:when test="not($current-aircraft/aixm:engine)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:when test="$current-aircraft/aixm:engine/@xsi:nil='true'">
					<xsl:value-of select="fcn:insert-value($current-aircraft/aixm:engine)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:transform-value(string($current-aircraft/aixm:engine), 'engine')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="aircraft-number-engines">
			<xsl:choose>
				<xsl:when test="not($current-aircraft/aixm:numberEngine)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:when test="$current-aircraft/aixm:numberEngine/@xsi:nil='true'">
					<xsl:value-of select="fcn:insert-value($current-aircraft/aixm:numberEngine)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:transform-value(string($current-aircraft/aixm:numberEngine), '')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="aircraft-icao-type">
			<xsl:choose>
				<xsl:when test="not($current-aircraft/aixm:typeAircraftICAO)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:when test="$current-aircraft/aixm:typeAircraftICAO/@xsi:nil='true'">
					<xsl:value-of select="fcn:insert-value($current-aircraft/aixm:typeAircraftICAO)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:transform-value(string($current-aircraft/aixm:typeAircraftICAO), '')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<!-- Extract flight info for current aixm:flight -->
		<xsl:variable name="flight-type">
			<xsl:choose>
				<xsl:when test="not($current-flight/aixm:type)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:when test="$current-flight/aixm:type/@xsi:nil='true'">
					<xsl:value-of select="fcn:insert-value($current-flight/aixm:type)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:transform-value(string($current-flight/aixm:type), 'flight-type')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="flight-rule">
			<xsl:choose>
				<xsl:when test="not($current-flight/aixm:rule)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:when test="$current-flight/aixm:rule/@xsi:nil='true'">
					<xsl:value-of select="fcn:insert-value($current-flight/aixm:rule)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:transform-value(string($current-flight/aixm:rule), 'rule')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="flight-status">
			<xsl:choose>
				<xsl:when test="not($current-flight/aixm:status)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:when test="$current-flight/aixm:status/@xsi:nil='true'">
					<xsl:value-of select="fcn:insert-value($current-flight/aixm:status)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:transform-value(string($current-flight/aixm:status), 'status')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="flight-military">
			<xsl:choose>
				<xsl:when test="not($current-flight/aixm:military)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:when test="$current-flight/aixm:military/@xsi:nil='true'">
					<xsl:value-of select="fcn:insert-value($current-flight/aixm:military)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:transform-value(string($current-flight/aixm:military), 'military')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="flight-origin">
			<xsl:choose>
				<xsl:when test="not($current-flight/aixm:origin)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:when test="$current-flight/aixm:origin/@xsi:nil='true'">
					<xsl:value-of select="fcn:insert-value($current-flight/aixm:origin)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:transform-value(string($current-flight/aixm:origin), 'origin')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="flight-purpose">
			<xsl:choose>
				<xsl:when test="not($current-flight/aixm:purpose)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:when test="$current-flight/aixm:purpose/@xsi:nil='true'">
					<xsl:value-of select="fcn:insert-value($current-flight/aixm:purpose)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:transform-value(string($current-flight/aixm:purpose), 'purpose')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<!-- Limitation Code -->
		<xsl:variable name="limitation-code">
			<xsl:choose>
				<xsl:when test="not($usage-element/aixm:type)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:insert-value($usage-element/aixm:type)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<!-- Prior Permission -->
		<xsl:variable name="prior-permission">
			<xsl:choose>
				<xsl:when test="not($usage-element/aixm:priorPermission)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:when test="$usage-element/aixm:priorPermission/@xsi:nil='true'">
					<xsl:choose>
						<xsl:when test="$usage-element/aixm:priorPermission/@nilReason">
							<xsl:value-of select="concat('NIL:', $usage-element/aixm:priorPermission/@nilReason)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="'NIL'"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat($usage-element/aixm:priorPermission, ' ', $usage-element/aixm:priorPermission/@uom)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<!-- Operation -->
		<xsl:variable name="operation">
			<xsl:choose>
				<xsl:when test="not($usage-element/aixm:operation)">
					<xsl:value-of select="''"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="fcn:insert-value($usage-element/aixm:operation)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<tr>
			<td><xsl:value-of select="if (string-length(map:get($airport-vars, 'designator')) != 0) then map:get($airport-vars, 'designator') else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length(map:get($airport-vars, 'icao')) != 0) then map:get($airport-vars, 'icao') else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($limitation-code) != 0) then $limitation-code else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($working-hours-code) != 0) then $working-hours-code else '&#160;'" disable-output-escaping="yes"/></td>
		</tr>
		<tr>
			<td xml:space="preserve"><xsl:value-of select="if (string-length($timesheet-remarks) != 0) then $timesheet-remarks else '&#160;'" disable-output-escaping="yes"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($condition-level) != 0) then $condition-level else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($prior-permission) != 0) then $prior-permission else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($operation) != 0) then $operation else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($logical-operator) != 0) then $logical-operator else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($time-reference) != 0) then $time-reference else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($daylight-saving) != 0) then $daylight-saving else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($start-date-yearly) != 0) then $start-date-yearly else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($end-date-yearly) != 0) then $end-date-yearly else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($day-start) != 0) then $day-start else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($day-end) != 0) then $day-end else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($start-time) != 0) then $start-time else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($start-event) != 0) then $start-event else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($start-relative) != 0) then $start-relative else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($start-interpretation) != 0) then $start-interpretation else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($end-time) != 0) then $end-time else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($end-event) != 0) then $end-event else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($end-relative) != 0) then $end-relative else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($end-interpretation) != 0) then $end-interpretation else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($flight-type) != 0) then $flight-type else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($flight-rule) != 0) then $flight-rule else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($flight-status) != 0) then $flight-status else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($flight-military) != 0) then $flight-military else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($flight-origin) != 0) then $flight-origin else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($flight-purpose) != 0) then $flight-purpose else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($aircraft-equipment) != 0) then $aircraft-equipment else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($aircraft-type) != 0) then $aircraft-type else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($aircraft-engine) != 0) then $aircraft-engine else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($aircraft-number-engines) != 0) then $aircraft-number-engines else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length($aircraft-icao-type) != 0) then $aircraft-icao-type else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length(map:get($airport-vars, 'effective-date')) gt 4) then map:get($airport-vars, 'effective-date') else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length(map:get($airport-vars, 'commit-date')) gt 4) then map:get($airport-vars, 'commit-date') else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length(map:get($airport-vars, 'uuid')) != 0) then map:get($airport-vars, 'uuid') else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length(map:get($airport-vars, 'valid_timeslice')) != 0) then map:get($airport-vars, 'valid_timeslice') else '&#160;'"/></td>
		</tr>
		<tr>
			<td><xsl:value-of select="if (string-length(map:get($airport-vars, 'originator')) != 0) then map:get($airport-vars, 'originator') else '&#160;'"/></td>
		</tr>
		<tr>
			<td>&#160;</td>
		</tr>
		<tr>
			<td>&#160;</td>
		</tr>
	</xsl:template>

	<xsl:template match="/">

		<html xmlns="http://www.w3.org/1999/xhtml">

			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
				<meta http-equiv="Expires" content="120"/>
				<title>SDO Reporting - AD / HP usage - Complete - Version</title>
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
					<b>AD / HP usage - Complete - Version</b>
				</center>
				<hr/>

				<table border="0"  style="white-space:nowrap">
					<tbody>

						<tr>
							<td><strong>Aerodrome / Heliport - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>Aerodrome / Heliport - ICAO Code</strong></td>
						</tr>
						<tr>
							<td><strong>Limitation Code</strong></td>
						</tr>
						<tr>
							<td><strong>Working hours</strong></td>
						</tr>
						<tr>
							<td><strong>Remark to working hours</strong></td>
						</tr>
						<tr>
							<td><strong>Condition Combination</strong></td>
						</tr>
						<tr>
							<td><strong>Prior Permission</strong></td>
						</tr>
						<tr>
							<td><strong>Operation</strong></td>
						</tr>
						<tr>
							<td><strong>Logical Operator</strong></td>
						</tr>
						<tr>
							<td><strong>Time reference system</strong></td>
						</tr>
						<tr>
							<td><strong>Daylight saving adjust</strong></td>
						</tr>
						<tr>
							<td><strong>Yearly start date </strong></td>
						</tr>
						<tr>
							<td><strong>Yearly end date</strong></td>
						</tr>
						<tr>
							<td><strong>Affected day or start of affected period</strong></td>
						</tr>
						<tr>
							<td><strong>End of affected period</strong></td>
						</tr>
						<tr>
							<td><strong>Start - Time</strong></td>
						</tr>
						<tr>
							<td><strong>Start - Event</strong></td>
						</tr>
						<tr>
							<td><strong>Start - Relative to event</strong></td>
						</tr>
						<tr>
							<td><strong>Start - Interpretation</strong></td>
						</tr>
						<tr>
							<td><strong>End - Time</strong></td>
						</tr>
						<tr>
							<td><strong>End - Event</strong></td>
						</tr>
						<tr>
							<td><strong>End - Relative to event</strong></td>
						</tr>
						<tr>
							<td><strong>End - Interpretation</strong></td>
						</tr>
						<tr>
							<td><strong>Flight Class - Type</strong></td>
						</tr>
						<tr>
							<td><strong>Flight Class - Rule</strong></td>
						</tr>
						<tr>
							<td><strong>Flight Class - Status</strong></td>
						</tr>
						<tr>
							<td><strong>Flight Class - Military</strong></td>
						</tr>
						<tr>
							<td><strong>Flight Class - Origin</strong></td>
						</tr>
						<tr>
							<td><strong>Flight Class - Purpose</strong></td>
						</tr>
						<tr>
							<td><strong>Aircraft Class - Equipment and certification</strong></td>
						</tr>
						<tr>
							<td><strong>Aircraft Class - Type</strong></td>
						</tr>
						<tr>
							<td><strong>Aircraft Class - Engine Type</strong></td>
						</tr>
						<tr>
							<td><strong>Aircraft Class - Number of engines</strong></td>
						</tr>
						<tr>
							<td><strong>Aircraft Class - ICAO aircraft type designator</strong></td>
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
							<td><strong>Valid TimeSlice</strong></td>
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

						<!-- Process each AirportHeliport feature -->
						<xsl:for-each select="//aixm:AirportHeliport">
							<xsl:sort select="(aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)][aixm:correctionNumber = max(../aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)]/aixm:correctionNumber)])[1]/aixm:designator" order="ascending"/>

							<!-- Get all BASELINE timeslices -->
							<xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']"/>
							<!-- Find the maximum sequenceNumber -->
							<xsl:variable name="max-sequence" select="max($baseline-timeslices/aixm:sequenceNumber)"/>
							<!-- Get timeslices with the maximum sequenceNumber, then find max correctionNumber -->
							<xsl:variable name="max-correction" select="max($baseline-timeslices[aixm:sequenceNumber = $max-sequence]/aixm:correctionNumber)"/>
							<!-- Select the valid timeslice -->
							<xsl:variable name="valid-timeslice" select="$baseline-timeslices[aixm:sequenceNumber = $max-sequence and aixm:correctionNumber = $max-correction][1]"/>

							<xsl:for-each select="$valid-timeslice">

								<xsl:sort select="aixm:designator" data-type="text" order="ascending"/>

								<!-- Aerodrome / Heliport - Identification -->
								<xsl:variable name="airport-designator">
									<xsl:choose>
										<xsl:when test="not(aixm:designator)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:designator)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Aerodrome / Heliport - ICAO Code -->
								<xsl:variable name="airport-designator-icao">
									<xsl:choose>
										<xsl:when test="not(aixm:locationIndicatorICAO)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:locationIndicatorICAO)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Working hours -->
								<xsl:variable name="working-hours">
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
								<xsl:variable name="working-hours-remarks">
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
								
								<!-- Internal UID (master) -->
								<xsl:variable name="airport-uuid" select="../../gml:identifier"/>
								
								<!-- Valid TimeSlice -->
								<xsl:variable name="airport_timeslice" select="concat('BASELINE ', $max-sequence, '.', $max-correction)"/>

								<!-- Effective date -->
								<xsl:variable name="effective-day" select="substring(gml:validTime/gml:TimePeriod/gml:beginPosition, 9, 2)"/>
								<xsl:variable name="effective-month" select="substring(gml:validTime/gml:TimePeriod/gml:beginPosition, 6, 2)"/>
								<xsl:variable name="effective-month-text" select="if($effective-month = '01') then 'JAN' else if ($effective-month = '02') then 'FEB' else if ($effective-month = '03') then 'MAR' else
									if ($effective-month = '04') then 'APR' else if ($effective-month = '05') then 'MAY' else if ($effective-month = '06') then 'JUN' else if ($effective-month = '07') then 'JUL' else
									if ($effective-month = '08') then 'AUG' else if ($effective-month = '09') then 'SEP' else if ($effective-month = '10') then 'OCT' else if ($effective-month = '11') then 'NOV' else 'DEC'"/>
								<xsl:variable name="effective-year" select="substring(gml:validTime/gml:TimePeriod/gml:beginPosition, 1, 4)"/>
								<xsl:variable name="effective-date" select="concat($effective-day, '-', $effective-month-text, '-', $effective-year)"/>

								<!-- Committed on -->
								<xsl:variable name="commit-day" select="substring(aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate, 9, 2)"/>
								<xsl:variable name="commit-month" select="substring(aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate, 6, 2)"/>
								<xsl:variable name="commit-month-text" select="if($commit-month = '01') then 'JAN' else if ($commit-month = '02') then 'FEB' else if ($commit-month = '03') then 'MAR' else
									if ($commit-month = '04') then 'APR' else if ($commit-month = '05') then 'MAY' else if ($commit-month = '06') then 'JUN' else if ($commit-month = '07') then 'JUL' else
									if ($commit-month = '08') then 'AUG' else if ($commit-month = '09') then 'SEP' else if ($commit-month = '10') then 'OCT' else if ($commit-month = '11') then 'NOV' else if ($commit-month = '12') then 'DEC' else ''"/>
								<xsl:variable name="commit-year" select="substring(aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate, 1, 4)"/>
								<xsl:variable name="commit-date" select="concat($commit-day, '-', $commit-month-text, '-', $commit-year)"/>

								<!-- Originator -->
								<xsl:variable name="originator" select="if (aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg) then aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg else ''"/>

								<!-- Process each availability -->
								<xsl:for-each select="aixm:availability/aixm:AirportHeliportAvailability">

									<!-- Create a map of airport-level variables -->
									<xsl:variable name="airport-vars" select="map{
										'designator': string($airport-designator),
										'icao': string($airport-designator-icao),
										'uuid': string($airport-uuid),
										'valid_timeslice': string($airport_timeslice),
										'effective-date': string($effective-date),
										'commit-date': string($commit-date),
										'originator': string($originator),
										'working-hours': string($working-hours),
										'working-hours-remarks': string($working-hours-remarks)
									}"/>

									<!-- Process top-level timesheets (outside ConditionCombination) -->
									<xsl:for-each select="aixm:timeInterval/aixm:Timesheet">
										<xsl:call-template name="generate-row">
											<xsl:with-param name="timesheet" select="."/>
											<xsl:with-param name="usage-element" select="../.."/>
											<xsl:with-param name="condition-element" select="../.."/>
											<xsl:with-param name="condition-level" select="''"/>
											<xsl:with-param name="airport-vars" select="$airport-vars"/>
											<xsl:with-param name="aircraft-index" select="0"/>
											<xsl:with-param name="flight-index" select="0"/>
											<xsl:with-param name="aircraft-data" select="()"/>
											<xsl:with-param name="flight-data" select="()"/>
										</xsl:call-template>
									</xsl:for-each>

									<!-- Process each usage -->
									<xsl:for-each select="aixm:usage/aixm:AirportHeliportUsage">
										<xsl:variable name="usage-index" select="position()"/>

										<!-- Process the selection/ConditionCombination -->
										<xsl:for-each select="aixm:selection/aixm:ConditionCombination">
											<xsl:call-template name="process-condition">
												<xsl:with-param name="condition" select="."/>
												<xsl:with-param name="usage-element" select="parent::aixm:selection/parent::aixm:AirportHeliportUsage"/>
												<xsl:with-param name="condition-level" select="string($usage-index)"/>
												<xsl:with-param name="airport-vars" select="$airport-vars"/>
											</xsl:call-template>
										</xsl:for-each>
									</xsl:for-each>

								</xsl:for-each>

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
