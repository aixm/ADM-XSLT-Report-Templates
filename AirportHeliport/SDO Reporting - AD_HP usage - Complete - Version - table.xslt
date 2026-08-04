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
  
  <xsl:output method="html" indent="yes"/>

  <xsl:strip-space elements="*"/>
  
  <xsl:function name="fcn:format-date" as="xs:string">
    <xsl:param name="text" as="xs:string"/>
    <xsl:variable name="date-time" select="$text"/>
    <xsl:variable name="day" select="substring($date-time, 9, 2)"/>
    <xsl:variable name="month" select="substring($date-time, 6, 2)"/>
    <xsl:variable name="month" select="
      if($month = '01') then 'JAN'
      else if ($month = '02') then 'FEB'
      else if ($month = '03') then 'MAR'
      else if ($month = '04') then 'APR'
      else if ($month = '05') then 'MAY'
      else if ($month = '06') then 'JUN'
      else if ($month = '07') then 'JUL'
      else if ($month = '08') then 'AUG'
      else if ($month = '09') then 'SEP'
      else if ($month = '10') then 'OCT'
      else if ($month = '11') then 'NOV'
      else if ($month = '12') then 'DEC'
      else ''"/>
    <xsl:variable name="year" select="substring($date-time, 1, 4)"/>
    <xsl:value-of select="concat($day, '-', $month, '-', $year)"/>
  </xsl:function>
  
  <!-- Function to get the valid BASELINE timeslice for any feature type -->
  <!-- Accepts pre-filtered BASELINE timeslice elements (e.g. AirspaceTimeSlice, DMETimeSlice, VORTimeSlice, etc.) -->
  <!-- Selection order: most recent validTime beginPosition, then highest sequenceNumber, then highest correctionNumber -->
  <xsl:function name="fcn:get-valid-timeslice" as="element()?">
    <xsl:param name="baseline-timeslices" as="element()*"/>
    <!-- Sort by validTime beginPosition (most recent first), then sequenceNumber, then correctionNumber -->
    <xsl:variable name="sorted" as="element()*">
      <xsl:for-each select="$baseline-timeslices">
        <xsl:sort select="gml:validTime/gml:TimePeriod/gml:beginPosition" order="descending"/>
        <xsl:sort select="aixm:sequenceNumber" data-type="number" order="descending"/>
        <xsl:sort select="aixm:correctionNumber" data-type="number" order="descending"/>
        <xsl:sequence select="."/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:sequence select="$sorted[1]"/>
  </xsl:function>
  
  <!-- Format timeslice info as: BASELINE seq.corr | dd-MMM-yyyy to (dd-MMM-yyyy|PERM) -->
  <!-- Core version with string parameters (used by both element and map callers) -->
  <xsl:function name="fcn:format-timeslice-info" as="xs:string">
    <xsl:param name="seq" as="xs:string"/>
    <xsl:param name="corr" as="xs:string"/>
    <xsl:param name="begin-position" as="xs:string"/>
    <xsl:param name="end-position" as="xs:string"/>
    <xsl:param name="end-indeterminate" as="xs:string"/>
    <xsl:variable name="begin-formatted" select="if (string-length($begin-position) gt 0) then concat(fcn:format-date($begin-position), ' ', substring(substring-after($begin-position, 'T'), 1, 5)) else $begin-position"/>
    <xsl:variable name="end-formatted" select="if ($end-indeterminate = 'unknown' and string-length($end-position) = 0) then 'PERM' else if (string-length($end-position) gt 0) then concat(fcn:format-date($end-position), ' ', substring(substring-after($end-position, 'T'), 1, 5)) else $end-position"/>
    <xsl:value-of select="concat('BASELINE ', $seq, '.', $corr, ' | ', $begin-formatted, ' to ', $end-formatted)"/>
  </xsl:function>
  
  <!-- Convenience overload for timeslice elements -->
  <xsl:function name="fcn:format-timeslice-info" as="xs:string">
    <xsl:param name="ts" as="element()?"/>
    <xsl:choose>
      <xsl:when test="$ts">
        <xsl:sequence select="fcn:format-timeslice-info(
          string($ts/aixm:sequenceNumber),
          string($ts/aixm:correctionNumber),
          string($ts/gml:validTime/gml:TimePeriod/gml:beginPosition),
          string($ts/gml:validTime/gml:TimePeriod/gml:endPosition),
          string($ts/gml:validTime/gml:TimePeriod/gml:endPosition/@indeterminatePosition))"/>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="''"/></xsl:otherwise>
    </xsl:choose>
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
  
  <!-- Get annotation text preserving line breaks and escaping special HTML characters -->
  <xsl:function name="fcn:get-annotation-text" as="xs:string">
    <xsl:param name="raw_text" as="xs:string"/>
    <!-- First, escape special HTML characters in the raw text before processing -->
    <xsl:variable name="escaped_raw_text" select="replace(replace($raw_text, '&lt;', '&amp;lt;'), '&gt;', '&amp;gt;')"/>
    <xsl:variable name="lines" select="for $line in tokenize($escaped_raw_text, '&#xA;') return normalize-space($line)"/>
    <xsl:variable name="non_empty_lines" select="$lines[string-length(.) gt 0]"/>
    <xsl:value-of select="string-join($non_empty_lines, '&lt;br/&gt;')"/>
  </xsl:function>

  <!-- Function to determine the working hours code for a single Timesheet -->
  <!-- When no Timesheet is present, the code is derived from the timeInterval annotations / nil reason of the given level element (AirportHeliportAvailability or ConditionCombination) -->
  <xsl:function name="fcn:format-working-hours" as="xs:string">
    <xsl:param name="timesheet" as="element()?"/>
    <xsl:param name="level-element" as="element()?"/>
    <xsl:choose>
      <xsl:when test="$timesheet">
        <xsl:choose>
          <!-- insert 'H24' for a continuous service 24/7 Timesheet -->
          <xsl:when test="$timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and (not(aixm:dayTil) or aixm:dayTil/@xsi:nil='true' or aixm:dayTil='ANY') and aixm:startTime='00:00' and aixm:endTime=('00:00','23:59','24:00') and (aixm:daylightSavingAdjust=('NO','YES') or aixm:daylightSavingAdjust/@xsi:nil='true' or not(aixm:daylightSavingAdjust)) and ((aixm:startDate='01-01' and aixm:endDate='31-12') or ((not(aixm:startDate) or aixm:startDate/@xsi:nil='true') and (not(aixm:endDate) or aixm:endDate/@xsi:nil='true'))) and aixm:excluded='NO']">
            <xsl:value-of select="'H24'"/>
          </xsl:when>
          <!-- insert 'HJ' for a sunrise to sunset Timesheet -->
          <xsl:when test="$timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SR' and aixm:endEvent='SS' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@xsi:nil='true') and aixm:excluded='NO']">
            <xsl:value-of select="'HJ'"/>
          </xsl:when>
          <!-- insert 'HN' for a sunset to sunrise Timesheet -->
          <xsl:when test="$timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SS' and aixm:endEvent='SR' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@xsi:nil='true') and aixm:excluded='NO']">
            <xsl:value-of select="'HN'"/>
          </xsl:when>
          <!-- any other Timesheet: refer the reader to the timesheet columns -->
          <xsl:otherwise>
            <xsl:value-of select="'TIMSH'"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="ti-notes" select="$level-element/aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']/aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]"/>
        <xsl:choose>
          <!-- insert 'HX' if coded in a timeInterval annotation at this level -->
          <xsl:when test="$ti-notes[contains(., 'HX')]">
            <xsl:value-of select="'HX'"/>
          </xsl:when>
          <!-- insert 'HO' if coded in a timeInterval annotation at this level -->
          <xsl:when test="$ti-notes[contains(., 'HO')]">
            <xsl:value-of select="'HO'"/>
          </xsl:when>
          <!-- insert 'NOTAM' if coded in a timeInterval annotation at this level -->
          <xsl:when test="$ti-notes[contains(lower-case(.), 'notam') and not(contains(lower-case(.), 'outside'))]">
            <xsl:value-of select="'NOTAM'"/>
          </xsl:when>
          <!-- insert nil reason if provided -->
          <xsl:when test="$level-element/aixm:timeInterval/@xsi:nil='true' and $level-element/aixm:timeInterval/@nilReason and not($level-element/aixm:timeInterval/@nilReason='inapplicable')">
            <xsl:value-of select="concat('NIL:', $level-element/aixm:timeInterval/@nilReason)"/>
          </xsl:when>
          <!-- insert 'H24' for absence of timeInterval, unless an annotation suggests specific hours -->
          <xsl:when test="not($ti-notes[contains(., 'HOL') or contains(., 'SS') or contains(., 'SR') or contains(., 'MON') or contains(., 'TUE') or contains(., 'WED') or contains(., 'THU') or contains(., 'FRI') or contains(., 'SAT') or contains(., 'SUN')])">
            <xsl:value-of select="'H24'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="''"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
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

    <xsl:variable name="timesheets" select="$condition/aixm:timeInterval/aixm:Timesheet"/>

    <xsl:choose>
      <!-- Generate rows for timeIntervals at this level -->
      <xsl:when test="count($timesheets) ge 1">
        <xsl:for-each select="$timesheets">
          <xsl:call-template name="generate-rows-for-timesheet">
            <xsl:with-param name="timesheet" select="."/>
            <xsl:with-param name="usage-element" select="$usage-element"/>
            <xsl:with-param name="condition-element" select="$condition"/>
            <xsl:with-param name="condition-level" select="$condition-level"/>
            <xsl:with-param name="airport-vars" select="$airport-vars"/>
            <xsl:with-param name="aircraft-data" select="$aircraft-data"/>
            <xsl:with-param name="flight-data" select="$flight-data"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      <!-- No Timesheet at this level: still generate the rows if the level carries usage type, operation, aircraft, flight or annotation-coded working hours -->
      <xsl:when test="$usage-element/aixm:type or $usage-element/aixm:operation or $condition/aixm:aircraft or $condition/aixm:flight or $condition/aixm:annotation/aixm:Note[aixm:propertyName='timeInterval'] or $condition/aixm:timeInterval/@xsi:nil='true'">
        <xsl:call-template name="generate-rows-for-timesheet">
          <xsl:with-param name="timesheet" select="()"/>
          <xsl:with-param name="usage-element" select="$usage-element"/>
          <xsl:with-param name="condition-element" select="$condition"/>
          <xsl:with-param name="condition-level" select="$condition-level"/>
          <xsl:with-param name="airport-vars" select="$airport-vars"/>
          <xsl:with-param name="aircraft-data" select="$aircraft-data"/>
          <xsl:with-param name="flight-data" select="$flight-data"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>

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

  <!-- Template to generate the row(s) for a single Timesheet (or for a level without Timesheet) -->
  <xsl:template name="generate-rows-for-timesheet">
    <xsl:param name="timesheet" as="element()?"/>
    <xsl:param name="usage-element" as="element()"/>
    <xsl:param name="condition-element" as="element()"/>
    <xsl:param name="condition-level" as="xs:string"/>
    <xsl:param name="airport-vars" as="map(xs:string, xs:string)"/>
    <xsl:param name="aircraft-data" as="element()*"/>
    <xsl:param name="flight-data" as="element()*"/>

    <!-- Count aircraft and flights -->
    <xsl:variable name="aircraft-count" select="count($aircraft-data)"/>
    <xsl:variable name="flight-count" select="count($flight-data)"/>

    <xsl:choose>
      <!-- Case 1: Exactly one aircraft and one flight - place on same row -->
      <xsl:when test="$aircraft-count = 1 and $flight-count = 1">
        <xsl:call-template name="generate-row">
          <xsl:with-param name="timesheet" select="$timesheet"/>
          <xsl:with-param name="usage-element" select="$usage-element"/>
          <xsl:with-param name="condition-element" select="$condition-element"/>
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
            <xsl:with-param name="timesheet" select="$timesheet"/>
            <xsl:with-param name="usage-element" select="$usage-element"/>
            <xsl:with-param name="condition-element" select="$condition-element"/>
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
            <xsl:with-param name="timesheet" select="$timesheet"/>
            <xsl:with-param name="usage-element" select="$usage-element"/>
            <xsl:with-param name="condition-element" select="$condition-element"/>
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
            <xsl:with-param name="timesheet" select="$timesheet"/>
            <xsl:with-param name="usage-element" select="$usage-element"/>
            <xsl:with-param name="condition-element" select="$condition-element"/>
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
  </xsl:template>

  <!-- Template to generate a single table row -->
  <xsl:template name="generate-row">
    <xsl:param name="timesheet" as="element()?"/>
    <xsl:param name="usage-element" as="element()"/>
    <xsl:param name="condition-element" as="element()"/>
    <xsl:param name="condition-level" as="xs:string"/>
    <xsl:param name="airport-vars" as="map(xs:string, xs:string)"/>
    <xsl:param name="aircraft-index" as="xs:integer"/>
    <xsl:param name="flight-index" as="xs:integer"/>
    <xsl:param name="aircraft-data" as="element()*"/>
    <xsl:param name="flight-data" as="element()*"/>

    <!-- Detect working hours code for this timesheet / condition level -->
    <xsl:variable name="working-hours-code" select="fcn:format-working-hours($timesheet, $condition-element)"/>

    <!-- Extract same-level annotations for this timesheet -->
    <xsl:variable name="timesheet-remarks">
      <xsl:for-each select="$condition-element/aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']/aixm:translatedNote/aixm:LinguisticNote">
        <xsl:choose>
          <xsl:when test="position() = 1">
            <xsl:value-of select="concat('(', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', ') ', fcn:get-annotation-text(aixm:note))"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat('&lt;br/&gt;(', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', ') ', fcn:get-annotation-text(aixm:note))"/>
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
        <xsl:otherwise>
          <xsl:value-of select="fcn:insert-value($timesheet/aixm:startEventInterpretation)"/>
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
        <xsl:otherwise>
          <xsl:value-of select="fcn:insert-value($timesheet/aixm:endEventInterpretation)"/>
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
    <!-- Each property is inserted only if present in the AIXM encoding (nil values shown as NIL/NIL:reason), prefixed with its label -->
    <xsl:variable name="aircraft-equipment">
      <xsl:if test="$current-aircraft">
        <xsl:variable name="equip-list" as="xs:string*">
          <xsl:if test="$current-aircraft/aixm:navigationEquipment">
            <xsl:sequence select="concat('NAV: ',fcn:insert-value($current-aircraft/aixm:navigationEquipment))"/>
          </xsl:if>
          <xsl:if test="$current-aircraft/aixm:navigationSpecification">
            <xsl:sequence select="concat('NS: ',fcn:insert-value($current-aircraft/aixm:navigationSpecification))"/>
          </xsl:if>
          <xsl:if test="$current-aircraft/aixm:verticalSeparationCapability">
            <xsl:sequence select="concat('VS capability: ',fcn:insert-value($current-aircraft/aixm:verticalSeparationCapability))"/>
          </xsl:if>
          <xsl:if test="$current-aircraft/aixm:antiCollisionAndSeparationEquipment">
            <xsl:sequence select="concat('Anti-Collision: ',fcn:insert-value($current-aircraft/aixm:antiCollisionAndSeparationEquipment))"/>
          </xsl:if>
          <xsl:if test="$current-aircraft/aixm:communicationEquipment">
            <xsl:sequence select="concat('COM: ',fcn:insert-value($current-aircraft/aixm:communicationEquipment))"/>
          </xsl:if>
          <xsl:if test="$current-aircraft/aixm:surveillanceEquipment">
            <xsl:sequence select="concat('SUR: ',fcn:insert-value($current-aircraft/aixm:surveillanceEquipment))"/>
          </xsl:if>
          <xsl:if test="$current-aircraft/aixm:aircraftLandingCategory">
            <xsl:sequence select="concat('CAT: ',fcn:insert-value($current-aircraft/aixm:aircraftLandingCategory))"/>
          </xsl:if>
          <xsl:if test="$current-aircraft/aixm:wakeTurbulence">
            <xsl:sequence select="concat('WTC: ',fcn:insert-value($current-aircraft/aixm:wakeTurbulence))"/>
          </xsl:if>
        </xsl:variable>
        <xsl:value-of select="string-join($equip-list, '&lt;br/&gt;')"/>
      </xsl:if>
    </xsl:variable>

    <xsl:variable name="aircraft-type">
      <xsl:choose>
        <xsl:when test="not($current-aircraft/aixm:type)">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:insert-value($current-aircraft/aixm:type)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="aircraft-engine">
      <xsl:choose>
        <xsl:when test="not($current-aircraft/aixm:engine)">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:insert-value($current-aircraft/aixm:engine)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="aircraft-number-engines">
      <xsl:choose>
        <xsl:when test="not($current-aircraft/aixm:numberEngine)">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:insert-value($current-aircraft/aixm:numberEngine)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="aircraft-icao-type">
      <xsl:choose>
        <xsl:when test="not($current-aircraft/aixm:typeAircraftICAO)">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:insert-value($current-aircraft/aixm:typeAircraftICAO)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Extract flight info for current aixm:flight -->
    <xsl:variable name="flight-type">
      <xsl:choose>
        <xsl:when test="not($current-flight/aixm:type)">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:insert-value($current-flight/aixm:type)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="flight-rule">
      <xsl:choose>
        <xsl:when test="not($current-flight/aixm:rule)">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:insert-value($current-flight/aixm:rule)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="flight-status">
      <xsl:choose>
        <xsl:when test="not($current-flight/aixm:status)">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:insert-value($current-flight/aixm:status)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="flight-military">
      <xsl:choose>
        <xsl:when test="not($current-flight/aixm:military)">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:insert-value($current-flight/aixm:military)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="flight-origin">
      <xsl:choose>
        <xsl:when test="not($current-flight/aixm:origin)">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:insert-value($current-flight/aixm:origin)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="flight-purpose">
      <xsl:choose>
        <xsl:when test="not($current-flight/aixm:purpose)">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:insert-value($current-flight/aixm:purpose)"/>
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

    <tr style="white-space:nowrap;vertical-align:top;">
      <td><xsl:value-of select="if (string-length(map:get($airport-vars, 'designator')) != 0) then map:get($airport-vars, 'designator') else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length(map:get($airport-vars, 'icao')) != 0) then map:get($airport-vars, 'icao') else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($limitation-code) != 0) then $limitation-code else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($working-hours-code) != 0) then $working-hours-code else '&#160;'" disable-output-escaping="yes"/></td>
      <td style="max-width:600px;white-space:normal;overflow-wrap:break-word" xml:space="preserve"><xsl:value-of select="if (string-length($timesheet-remarks) != 0) then $timesheet-remarks else '&#160;'" disable-output-escaping="yes"/></td>
      <td><xsl:value-of select="if (string-length($condition-level) != 0) then $condition-level else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($prior-permission) != 0) then $prior-permission else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($operation) != 0) then $operation else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($logical-operator) != 0) then $logical-operator else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($time-reference) != 0) then $time-reference else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($daylight-saving) != 0) then $daylight-saving else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($start-date-yearly) != 0) then $start-date-yearly else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($end-date-yearly) != 0) then $end-date-yearly else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($day-start) != 0) then $day-start else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($day-end) != 0) then $day-end else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($start-time) != 0) then $start-time else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($start-event) != 0) then $start-event else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($start-relative) != 0) then $start-relative else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($start-interpretation) != 0) then $start-interpretation else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($end-time) != 0) then $end-time else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($end-event) != 0) then $end-event else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($end-relative) != 0) then $end-relative else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($end-interpretation) != 0) then $end-interpretation else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($flight-type) != 0) then $flight-type else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($flight-rule) != 0) then $flight-rule else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($flight-status) != 0) then $flight-status else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($flight-military) != 0) then $flight-military else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($flight-origin) != 0) then $flight-origin else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($flight-purpose) != 0) then $flight-purpose else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($aircraft-equipment) != 0) then $aircraft-equipment else '&#160;'" disable-output-escaping="yes"/></td>
      <td><xsl:value-of select="if (string-length($aircraft-type) != 0) then $aircraft-type else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($aircraft-engine) != 0) then $aircraft-engine else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($aircraft-number-engines) != 0) then $aircraft-number-engines else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length($aircraft-icao-type) != 0) then $aircraft-icao-type else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length(map:get($airport-vars, 'effective-date')) gt 4) then map:get($airport-vars, 'effective-date') else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length(map:get($airport-vars, 'commit-date')) gt 4) then map:get($airport-vars, 'commit-date') else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length(map:get($airport-vars, 'uuid')) != 0) then map:get($airport-vars, 'uuid') else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length(map:get($airport-vars, 'valid_timeslice')) != 0) then map:get($airport-vars, 'valid_timeslice') else '&#160;'"/></td>
      <td><xsl:value-of select="if (string-length(map:get($airport-vars, 'originator')) != 0) then map:get($airport-vars, 'originator') else '&#160;'"/></td>
    </tr>
  </xsl:template>

  <xsl:template match="/">

    <html xmlns="http://www.w3.org/1999/xhtml">

      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <meta http-equiv="Expires" content="120"/>
        <title>SDO Reporting - AD / HP usage - Complete - Version</title>
        <style>
          html, body {
            margin: 0;
            padding: 0;
            height: 100vh;
          }
          body {
            display: flex;
            flex-direction: column;
          }
          /* Title area never scrolls */
          .title-area {
            flex-shrink: 0;
            padding: 0 8px;
          }
          /* Scrollable wrapper for the table */
          .table-wrapper {
            flex: 1;
            overflow: auto;
          }
          /* Main data table */
          .data-table {
            border-collapse: collapse;
            font-family: Times New Roman;
            width: max-content;
            min-width: 100%;
          }
          .data-table td {
            padding: 4px 8px;
          }
          /* Sticky header row */
          .data-table thead td {
            position: sticky;
            top: 0;
            z-index: 1;
            background-color: #ffffff;
            white-space: nowrap;
          }
          /* Highlight row on hover */
          .data-table tbody tr:hover {
            background-color: #d6eeee;
          }
        </style>
      </head>

      <body>
        <div class="title-area">
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
          <center><b>AD / HP usage - Complete - Version</b></center>
          <hr/>
        </div>
        
        <div class="table-wrapper">
          <table class="data-table">
            
            <thead>
              <tr>
                <td><strong>Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Identification</strong></td>
                <td><strong>Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- ICAO Code</strong></td>
                <td><strong>Limitation Code</strong></td>
                <td><strong>Working hours</strong></td>
                <td><strong>Remark to working hours</strong></td>
                <td><strong>Condition Combination</strong></td>
                <td><strong>Prior Permission</strong></td>
                <td><strong>Operation</strong></td>
                <td><strong>Logical Operator</strong></td>
                <td><strong>Time reference<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>system</strong></td>
                <td><strong>Daylight saving<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>adjust</strong></td>
                <td><strong>Yearly start date </strong></td>
                <td><strong>Yearly end date</strong></td>
                <td><strong>Affected day or start<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>of affected period</strong></td>
                <td><strong>End of affected period</strong></td>
                <td><strong>Start<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Time</strong></td>
                <td><strong>Start<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Event</strong></td>
                <td><strong>Start<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Relative to event</strong></td>
                <td><strong>Start<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Interpretation</strong></td>
                <td><strong>End<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Time</strong></td>
                <td><strong>End<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Event</strong></td>
                <td><strong>End<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Relative to event</strong></td>
                <td><strong>End<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Interpretation</strong></td>
                <td><strong>Flight Class<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Type</strong></td>
                <td><strong>Flight Class<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Rule</strong></td>
                <td><strong>Flight Class<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Status</strong></td>
                <td><strong>Flight Class<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Military</strong></td>
                <td><strong>Flight Class<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Origin</strong></td>
                <td><strong>Flight Class<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Purpose</strong></td>
                <td><strong>Aircraft Class<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Equipment and certification</strong></td>
                <td><strong>Aircraft Class<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Type</strong></td>
                <td><strong>Aircraft Class<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Engine Type</strong></td>
                <td><strong>Aircraft Class<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Number of engines</strong></td>
                <td><strong>Aircraft Class<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- ICAO aircraft type designator</strong></td>
                <td><strong>Effective date</strong></td>
                <td><strong>Committed on</strong></td>
                <td><strong>Internal UID (master)</strong></td>
                <td><strong>Valid TimeSlice</strong></td>
                <td><strong>Originator</strong></td>
              </tr>
            </thead>
            
            <tbody>
  
              <!-- Process each AirportHeliport feature -->
              <xsl:for-each select="//aixm:AirportHeliport">
                <xsl:sort select="(aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)][aixm:correctionNumber = max(../aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)]/aixm:correctionNumber)])[1]/aixm:designator" order="ascending"/>
  
                <!-- Get all BASELINE timeslices -->
                <xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']"/>
                <!-- Select the valid timeslice -->
                <xsl:variable name="valid-timeslice" select="fcn:get-valid-timeslice($baseline-timeslices)"/>
  
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
                  
                  <!-- Internal UID (master) -->
                  <xsl:variable name="airport-uuid" select="../../gml:identifier"/>
                  
                  <!-- Valid TimeSlice -->
                  <xsl:variable name="airport_timeslice" select="fcn:format-timeslice-info(.)"/>
  
                  <!-- Effective date -->
                  <xsl:variable name="effective-date">
                    <xsl:if test="gml:validTime/gml:TimePeriod/gml:beginPosition">
                      <xsl:value-of select="fcn:format-date(gml:validTime/gml:TimePeriod/gml:beginPosition)"/>
                    </xsl:if>
                  </xsl:variable>
  
                  <!-- Committed on -->
                  <xsl:variable name="commit-date">
                    <xsl:if test="aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate">
                      <xsl:value-of select="fcn:format-date(aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)"/>
                    </xsl:if>
                  </xsl:variable>
  
                  <!-- Originator -->
                  <xsl:variable name="originator" select="
                    if (aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg) 
                    then aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg 
                    else ''"/>
  
                  <!-- Process each availability -->
                  <xsl:for-each select="aixm:availability/aixm:AirportHeliportAvailability">

                    <!-- Roman numeral identifying the availability in the Condition Combination column, when there are two or more availability objects -->
                    <xsl:variable name="availability-prefix" select="if (last() ge 2) then format-integer(position(), 'I') else ''"/>

                    <!-- Create a map of airport-level variables -->
                    <xsl:variable name="airport-vars" select="map{
                      'designator': string($airport-designator),
                      'icao': string($airport-designator-icao),
                      'uuid': string($airport-uuid),
                      'valid_timeslice': string($airport_timeslice),
                      'effective-date': string($effective-date),
                      'commit-date': string($commit-date),
                      'originator': string($originator)
                    }"/>
  
                    <!-- Process top-level timesheets (outside ConditionCombination) -->
                    <xsl:variable name="availability-timesheets" select="aixm:timeInterval/aixm:Timesheet"/>
                    <xsl:choose>
                      <xsl:when test="count($availability-timesheets) ge 1">
                        <xsl:for-each select="$availability-timesheets">
                          <xsl:call-template name="generate-row">
                            <xsl:with-param name="timesheet" select="."/>
                            <xsl:with-param name="usage-element" select="../.."/>
                            <xsl:with-param name="condition-element" select="../.."/>
                            <xsl:with-param name="condition-level" select="$availability-prefix"/>
                            <xsl:with-param name="airport-vars" select="$airport-vars"/>
                            <xsl:with-param name="aircraft-index" select="0"/>
                            <xsl:with-param name="flight-index" select="0"/>
                            <xsl:with-param name="aircraft-data" select="()"/>
                            <xsl:with-param name="flight-data" select="()"/>
                          </xsl:call-template>
                        </xsl:for-each>
                      </xsl:when>
                      <!-- No Timesheet: generate one row so that H24 (by absence), HX, HO, NOTAM or NIL working hours still appear -->
                      <xsl:otherwise>
                        <xsl:call-template name="generate-row">
                          <xsl:with-param name="timesheet" select="()"/>
                          <xsl:with-param name="usage-element" select="."/>
                          <xsl:with-param name="condition-element" select="."/>
                          <xsl:with-param name="condition-level" select="$availability-prefix"/>
                          <xsl:with-param name="airport-vars" select="$airport-vars"/>
                          <xsl:with-param name="aircraft-index" select="0"/>
                          <xsl:with-param name="flight-index" select="0"/>
                          <xsl:with-param name="aircraft-data" select="()"/>
                          <xsl:with-param name="flight-data" select="()"/>
                        </xsl:call-template>
                      </xsl:otherwise>
                    </xsl:choose>
  
                    <!-- Process each usage -->
                    <xsl:for-each select="aixm:usage/aixm:AirportHeliportUsage">
                      <xsl:variable name="usage-index" select="position()"/>
  
                      <!-- Process the selection/ConditionCombination -->
                      <xsl:for-each select="aixm:selection/aixm:ConditionCombination">
                        <xsl:call-template name="process-condition">
                          <xsl:with-param name="condition" select="."/>
                          <xsl:with-param name="usage-element" select="parent::aixm:selection/parent::aixm:AirportHeliportUsage"/>
                          <xsl:with-param name="condition-level" select="if ($availability-prefix != '') then concat($availability-prefix, '.', $usage-index) else string($usage-index)"/>
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
          <xsl:variable name="rule_uuid" select="replace(substring-before(substring-after($rule_parameters, 'extractionRulesUuid: '), ','), '&quot;', '')"/>
          
          <!-- interestedInDataAt -->
          <xsl:variable name="interest_date" select="replace(substring-before(substring-after($rule_parameters, 'interestedInDataAt: '), ','), '&quot;', '')"/>
          
          <!-- featureTypes -->
          <xsl:variable name="feat_types" select="replace(replace(substring-before(substring-after($rule_parameters, 'featureTypes: '), ','), ' ', '&lt;br/&gt;'), '&quot;', '')"/>
          
          <!-- excludedProperties -->
          <xsl:variable name="exc_properties" select="replace(substring-before(substring-after($rule_parameters, 'excludedProperties: '), ','), '&quot;', '')"/>
          
          <!-- includeReferencedFeaturesLevel -->
          <xsl:variable name="referenced_feat_level" select="replace(substring-before(substring-after($rule_parameters, 'includeReferencedFeaturesLevel: '), ','), '&quot;', '')"/>
          
          <!-- featureOccurrence -->
          <xsl:variable name="feat_occurrence" select="replace(substring-before(substring-after($rule_parameters, 'featureOccurrence: '), ','), '&quot;', '')"/>
          
          <!-- effectiveDateStart -->
          <xsl:variable name="eff_date_start" select="replace(substring-before(substring-after($rule_parameters, 'effectiveDateStart: '), ','), '&quot;', '')"/>
          
          <!-- effectiveDateEnd -->
          <xsl:variable name="eff_date_end" select="replace(substring-before(substring-after($rule_parameters, 'effectiveDateEnd: '), ','), '&quot;', '')"/>
          
          <!-- referencedDataFeature -->
          <xsl:variable name="referenced_data_feat" select="replace(substring-before(substring-after($rule_parameters, 'referencedDataFeature: '), ','), '&quot;', '')"/>
          
          <!-- permanentBaseline -->
          <xsl:variable name="perm_BL" select="replace(substring-before(substring-after($rule_parameters, 'permanentBaseline: '), ','), '&quot;', '')"/>
          
          <!-- permanentPermdelta -->
          <xsl:variable name="perm_PD" select="replace(substring-before(substring-after($rule_parameters, 'permanentPermdelta: '), ','), '&quot;', '')"/>
          
          <!-- temporaryData -->
          <xsl:variable name="temp_data" select="replace(substring-before(substring-after($rule_parameters, 'temporaryData: '), ','), '&quot;', '')"/>
          
          <!-- permanentBaselineForTemporaryData -->
          <xsl:variable name="perm_BS_for_temp_data" select="replace(substring-before(substring-after($rule_parameters, 'permanentBaselineForTemporaryData: '), ','), '&quot;', '')"/>
          
          <!-- spatialFilteringBy -->
          <xsl:variable name="spatial_filtering" select="replace(substring-before(substring-after($rule_parameters, 'spatialFilteringBy: '), ','), '&quot;', '')"/>
          
          <!-- spatialAreaDefinition -->
          <xsl:variable name="spatial_area_definition" select="replace(substring-before(substring-after($rule_parameters, 'spatialAreaDefinition: '), ','), '&quot;', '')"/>
          
          <!-- spatialAreaUUID -->
          <xsl:variable name="spatial_area_uuid" select="replace(replace(substring-before(substring-after($rule_parameters, 'spatialAreaUUID: '), ','), ' ', '&lt;br/&gt;'), '&quot;', '')"/>
          
          <!-- spatialAreaBuffer -->
          <xsl:variable name="spatial_area_buffer" select="replace(substring-before(substring-after($rule_parameters, 'spatialAreaBuffer: '), ','), '&quot;', '')"/>
          
          <!-- spatialOperator -->
          <xsl:variable name="spatial_operator" select="replace(substring-before(substring-after($rule_parameters, 'spatialOperator: '), ','), '&quot;', '')"/>
          
          <!-- spatialValueOperator -->
          <xsl:variable name="spatial_value_operator" select="replace(substring-before(substring-after($rule_parameters, 'spatialValueOperator: '), ','), '&quot;', '')"/>
          
          <!-- dataBranch -->
          <xsl:variable name="data_branch" select="replace(substring-before(substring-after($rule_parameters, 'dataBranch: '), ','), '&quot;', '')"/>
          
          <!-- dataScope -->
          <xsl:variable name="data_scope" select="replace(substring-before(substring-after($rule_parameters, 'dataScope: '), ','), '&quot;', '')"/>
          
          <!-- dataProviderOrganization -->
          <xsl:variable name="data_provider_org" select="replace(substring-before(substring-after($rule_parameters, 'dataProviderOrganization: '), ','), '&quot;', '')"/>
          
          <!-- systemExtension -->
          <xsl:variable name="system_extension" select="replace(substring-before(substring-after($rule_parameters, 'systemExtension: '), ','), '&quot;', '')"/>
          
          <!-- AIXMversion -->
          <xsl:variable name="AIXM_ver" select="replace(substring-before(substring-after($rule_parameters, 'AIXMversion: '), ','), '&quot;', '')"/>
          
          <!-- indirectReferences -->
          <xsl:variable name="indirect_references" select="replace(substring-before(substring-after($rule_parameters, 'indirectReferences: '), ','), '&quot;', '')"/>
          
          <!-- dataType -->
          <xsl:variable name="data_type">
            <xsl:variable name="after_key" select="substring-after($rule_parameters, 'dataType: ')"/>
            <xsl:value-of select="if (contains($after_key, ',')) then replace(substring-before($after_key, ','), '&quot;', '') else $after_key"/>
          </xsl:variable>
          
          <!-- CustomizationAirspaceCircleArcToPolygon -->
          <xsl:variable name="arc_to_polygon">
            <xsl:variable name="after_key" select="substring-after($rule_parameters, 'CustomizationAirspaceCircleArcToPolygon: ')"/>
            <xsl:value-of select="if (contains($after_key, ',')) then replace(substring-before($after_key, ','), '&quot;', '') else $after_key"/>
          </xsl:variable>
          
          <p><b><font size="-1">Extraction rule parameters used for this report:</font></b></p>
          
          <table>
            <tr>
              <td style="text-align:right"><font size="-1">extractionRulesUUID: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($rule_uuid) gt 0) then $rule_uuid else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">interestedInDataAt: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($interest_date) gt 0) then $interest_date else '&#160;'"/></font></td>
            </tr>
            <tr style="vertical-align:top">
              <td style="text-align:right"><font size="-1">featureTypes: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($feat_types) gt 0) then $feat_types else '&#160;'" disable-output-escaping="true"/></font></td>
            </tr>
            <tr style="vertical-align:top">
              <td style="text-align:right"><font size="-1">excludedProperties: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($exc_properties) gt 0) then $exc_properties else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">includeReferencedFeaturesLevel: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($referenced_feat_level) gt 0) then $referenced_feat_level else '&#160;'"/></font></td>
            </tr>
            <tr style="vertical-align:top">
              <td style="text-align:right"><font size="-1">featureOccurrence: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($feat_occurrence) gt 0) then $feat_occurrence else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">effectiveDateStart: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($eff_date_start) gt 0) then $eff_date_start else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">effectiveDateEnd: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($eff_date_end) gt 0) then $eff_date_end else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">referencedDataFeature: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($referenced_data_feat) gt 0) then $referenced_data_feat else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">permanentBaseline: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($perm_BL) gt 0) then $perm_BL else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">permanentPermdelta: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($perm_PD) gt 0) then $perm_PD else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">temporaryData: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($temp_data) gt 0) then $temp_data else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">permanentBaselineForTemporaryData: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($perm_BS_for_temp_data) gt 0) then $perm_BS_for_temp_data else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">spatialFilteringBy: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($spatial_filtering) gt 0) then $spatial_filtering else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">spatialAreaDefinition: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($spatial_area_definition) gt 0) then $spatial_area_definition else '&#160;'"/></font></td>
            </tr>
            <tr style="vertical-align:top">
              <td style="text-align:right"><font size="-1">spatialAreaUUID: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($spatial_area_uuid) gt 0) then $spatial_area_uuid else '&#160;'" disable-output-escaping="true"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">spatialAreaBuffer: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($spatial_area_buffer) gt 0) then $spatial_area_buffer else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">spatialOperator: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($spatial_operator) gt 0) then $spatial_operator else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">spatialValueOperator: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($spatial_value_operator) gt 0) then $spatial_value_operator else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">dataBranch: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($data_branch) gt 0) then $data_branch else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">dataScope: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($data_scope) gt 0) then $data_scope else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">dataProviderOrganization: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($data_provider_org) gt 0) then $data_provider_org else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">systemExtension: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($system_extension) gt 0) then $system_extension else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">AIXMversion: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($AIXM_ver) gt 0) then $AIXM_ver else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">indirectReferences: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($indirect_references) gt 0) then $indirect_references else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">dataType: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($data_type) gt 0) then $data_type else '&#160;'"/></font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">CustomizationAirspaceCircleArcToPolygon: </font></td>
              <td><font size="-1"><xsl:value-of select="if (string-length($arc_to_polygon) gt 0) then $arc_to_polygon else '&#160;'"/></font></td>
            </tr>
          </table>
          
          <p></p>
          <table>
            <tr>
              <td style="text-align:right"><font size="-1">Sorting by column: </font></td>
              <td><font size="-1">Identification</font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">Sorting order: </font></td>
              <td><font size="-1">ascending</font></td>
            </tr>
          </table>
          
          <p>***&#160;END OF REPORT&#160;***</p>
          
        </div>

      </body>

    </html>

  </xsl:template>

</xsl:transform>
