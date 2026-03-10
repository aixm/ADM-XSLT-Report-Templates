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
                    featureTypes: aixm:Navaid aixm:OrganisationAuthority
  includeReferencedFeaturesLevel: 1
               featureOccurrence: aixm:Navaid.aixm:type EQUALS 'DME'
                                  OR aixm:Navaid.aixm:type EQUALS 'ILS_DME'
                                  OR aixm:Navaid.aixm:type EQUALS 'MLS_DME'
                                  OR aixm:Navaid.aixm:type EQUALS 'VOR_DME'
                                  OR aixm:Navaid.aixm:type EQUALS 'NDB_DME'
                                  OR aixm:Navaid.aixm:type EQUALS 'LOC_DME'
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
  
  <!-- Format latitude coordinate -->
  <xsl:function name="fcn:format-latitude" as="xs:string">
    <xsl:param name="lat_decimal" as="xs:double"/>
    <xsl:param name="coord_type" as="xs:string"/>
    <xsl:param name="decimal_places" as="xs:integer"/>
    <xsl:choose>
      <xsl:when test="$coord_type = 'DEC'">
        <!-- Decimal degrees format -->
        <xsl:variable name="format-string" select="concat('0.', string-join(for $i in 1 to $decimal_places return '0', ''))"/>
        <xsl:value-of select="concat(
          format-number(abs($lat_decimal), $format-string),
          if ($lat_decimal ge 0) then 'N' else 'S')"/>
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
        <xsl:value-of select="concat(
          format-number(abs($lon_decimal), $format-string),
          if ($lon_decimal ge 0) then 'E' else 'W')"/>
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
              <xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and (not(aixm:timeInterval/@nilReason) or aixm:timeInterval/@nilReason='inapplicable')) and not(aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HX') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HO') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'NOTAM') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HOL') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SS') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SR') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'MON') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'TUE') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'WED') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'THU') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'FRI') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SAT') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SUN')]]) and aixm:operationalStatus = 'OPERATIONAL'">
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
                      <xsl:if test="position() != last()"><xsl:text> | </xsl:text></xsl:if>
                    </xsl:for-each-group>
                    <!-- Add line break between day groups -->
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
  
  <!-- Recursively find STATE organization from an organization UUID -->
  <xsl:function name="fcn:find-state-org" as="element()?">
    <xsl:param name="org-uuid" as="xs:string"/>
    <xsl:param name="visited-uuids" as="xs:string*"/>
    <xsl:param name="root" as="document-node()"/>
    <!-- Try to find a STATE -->
    <xsl:variable name="state-result" select="fcn:find-state-recursive($org-uuid, $visited-uuids, $root)"/>
    <xsl:choose>
      <xsl:when test="$state-result">
        <!-- Found a STATE, return it -->
        <xsl:sequence select="$state-result"/>
      </xsl:when>
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
        <xsl:variable name="org-valid-ts" select="fcn:get-valid-timeslice($org-baseline-ts)"/>
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
  
  <xsl:template match="/">
    
    <html xmlns="http://www.w3.org/1999/xhtml">
      
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <meta http-equiv="Expires" content="120"/>
        <title>SDO Reporting - DME</title>
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
            width: 100%;
          }
          .data-table td {
            padding: 4px 8px;
            border-left: 1px solid #dbdbdb;
            border-right: 1px solid #dbdbdb;
          }
          /* Sticky header row */
          .data-table thead td {
            position: sticky;
            top: 0;
            z-index: 1;
            background-color: #ddd;
            white-space: nowrap;
          }
          /* Odd data rows */
          .data-table tbody tr:nth-child(odd) {
            background-color: #f5f5f5;
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
          <center><b>DME</b></center>
          <hr/>
        </div>
        
        <div class="table-wrapper">
          <table class="data-table">
            
            <thead>
              <tr>
                <td><strong>Master gUID</strong></td>
                <td><strong>DME<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Valid TimeSlice</strong></td>
                <td><strong>Identification</strong></td>
                <td><strong>Name</strong></td>
                <td><strong>Responsible State</strong></td>
                <td><strong>Responsible State<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Valid TimeSlice</strong></td>
                <td><strong>Latitude</strong></td>
                <td><strong>Longitude</strong></td>
                <td><strong>Collocated VOR<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Identification</strong></td>
                <td><strong>Collocated VOR<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Valid TimeSlice</strong></td>
                <td><strong>Channel</strong></td>
                <td><strong>Frequency of virtual<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>VHF facility</strong></td>
                <td><strong>UOM</strong></td>
                <td><strong>Datum</strong></td>
                <td><strong>Working hours</strong></td>
                <td><strong>Effective date</strong></td>
                <td><strong>Originator</strong></td>
              </tr>
            </thead>
            
            <tbody>
              
              <xsl:for-each select="//aixm:DME">
                
                <xsl:sort select="(aixm:timeSlice/aixm:DMETimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:DMETimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)][aixm:correctionNumber = max(../aixm:DMETimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:DMETimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)]/aixm:correctionNumber)])[1]/aixm:designator" order="ascending"/>
                <!-- Get all BASELINE time slices for this feature -->
                <xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:DMETimeSlice[aixm:interpretation = 'BASELINE']"/>
                <!-- Select the valid time slice -->
                <xsl:variable name="valid-timeslice" select="fcn:get-valid-timeslice($baseline-timeslices)"/>
                
                <xsl:for-each select="$valid-timeslice">
                  
                  <!-- Master gUID -->
                  <xsl:variable name="DME_UUID" select="../../gml:identifier"/>
                  
                  <!-- DME - Valid TimeSlice -->
                  <xsl:variable name="DME_timeslice" select="fcn:format-timeslice-info(.)"/>
                  
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
                  <!-- Try each organization authority link until a STATE is found -->
                  <xsl:variable name="state-org-ts" as="element()?">
                    <xsl:iterate select="aixm:authority/aixm:AuthorityForNavaidEquipment/aixm:theOrganisationAuthority/@xlink:href">
                      <xsl:param name="found-state" as="element()?" select="()"/>
                      <xsl:choose>
                        <xsl:when test="$found-state">
                          <!-- Already found a STATE, stop iteration -->
                          <xsl:break select="$found-state"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:variable name="OrgAuth_UUID" select="replace(., '^(urn:uuid:|#uuid\.)', '')"/>
                          <!-- Recursively find the STATE organization -->
                          <xsl:variable name="state-result" select="fcn:find-state-org($OrgAuth_UUID, (), root())"/>
                          <xsl:choose>
                            <xsl:when test="$state-result">
                              <!-- Found a STATE, stop iteration -->
                              <xsl:break select="$state-result"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <!-- Continue to next organization authority link -->
                              <xsl:next-iteration>
                                <xsl:with-param name="found-state" select="()"/>
                              </xsl:next-iteration>
                            </xsl:otherwise>
                          </xsl:choose>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:iterate>
                  </xsl:variable>
                  <xsl:variable name="ResponsibleState">
                    <xsl:if test="$state-org-ts">
                      <xsl:value-of select="$state-org-ts/aixm:name"/>
                    </xsl:if>
                  </xsl:variable>
  
                  <!-- Responsible State - Valid TimeSlice -->
                  <xsl:variable name="ResponsibleState_timeslice">
                    <xsl:if test="$state-org-ts">
                      <xsl:value-of select="fcn:format-timeslice-info($state-org-ts)"/>
                    </xsl:if>
                  </xsl:variable>
                  
                  <!-- Coordinates -->
                  
                  <!-- Select the type of coordinates: 'DMS' or 'DEC' -->
                  <xsl:variable name="coordinates_type" select="'DMS'"/>
                  
                  <!-- Select the number of decimals -->
                  <xsl:variable name="coordinates_decimal_number" select="2"/>
                  
                  <!-- Datum -->
                  <xsl:variable name="DME_datum" select="replace(replace(aixm:location/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
                  
                  <xsl:variable name="lat-long-datums" select="
                    ('EPSG:4326','EPSG:4258','EPSG:4322','EPSG:4230',
                    'EPSG:4668','EPSG:4312','EPSG:4215','EPSG:4801',
                    'EPSG:4149','EPSG:4326','EPSG:4275','EPSG:4746',
                    'EPSG:4121','EPSG:4658','EPSG:4299','EPSG:4806',
                    'EPSG:4277','EPSG:4207','EPSG:4274','EPSG:4740',
                    'EPSG:4313','EPSG:4124','EPSG:4267','EPSG:4269')"/>
                  
                  <!-- Extract coordinates depending on the coordinate system -->
                  <xsl:variable name="coordinates" select="aixm:location/aixm:ElevatedPoint/gml:pos"/>
                  <xsl:variable name="latitude_decimal">
                    <xsl:choose>
                      <xsl:when test="$DME_datum = $lat-long-datums">
                        <xsl:value-of  select="number(substring-before($coordinates, ' '))"/>
                      </xsl:when>
                      <xsl:when test="matches($DME_datum, '^OGC:.*CRS84$')">
                        <xsl:value-of select="number(substring-after($coordinates, ' '))"/>
                      </xsl:when>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="longitude_decimal">
                    <xsl:choose>
                      <xsl:when test="$DME_datum = $lat-long-datums">
                        <xsl:value-of  select="number(substring-after($coordinates, ' '))"/>
                      </xsl:when>
                      <xsl:when test="matches($DME_datum, '^OGC:.*CRS84$')">
                        <xsl:value-of select="number(substring-before($coordinates, ' '))"/>
                      </xsl:when>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="DME_lat">
                    <xsl:if test="string-length($latitude_decimal) gt 0">
                      <xsl:value-of select="fcn:format-latitude($latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
                    </xsl:if>
                  </xsl:variable>
                  <xsl:variable name="DME_long">
                    <xsl:if test="string-length($longitude_decimal) gt 0">
                      <xsl:value-of select="fcn:format-longitude($longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
                    </xsl:if>
                  </xsl:variable>
                  
                  <!-- Collocated VOR - Identification -->
                  <!-- Find the Navaid with type='VOR_DME' that references this DME -->
                  <xsl:variable name="collocated_VOR_UUID">
                    <xsl:for-each select="//aixm:Navaid[.//aixm:type = 'VOR_DME' and .//aixm:navaidEquipment/aixm:NavaidComponent/aixm:theNavaidEquipment/@xlink:href = concat('urn:uuid:', $DME_UUID)]">
                      <xsl:variable name="navaid-baseline-ts" select="aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE']"/>
                      <xsl:variable name="navaid-valid-ts" select="fcn:get-valid-timeslice($navaid-baseline-ts)"/>
                      <!-- Find the specific xlink:href that references an aixm:VOR -->
                      <xsl:for-each select="$navaid-valid-ts/aixm:navaidEquipment">
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
                  <xsl:variable name="VOR-valid-ts" select="fcn:get-valid-timeslice($VOR-baseline-ts)"/>
                  <xsl:variable name="collocated_VOR_designator">
                    <xsl:choose>
                      <xsl:when test="not($VOR-valid-ts/aixm:designator)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value($VOR-valid-ts/aixm:designator)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- Collocated VOR - Valid TimeSlice -->
                  <xsl:variable name="collocated_VOR_timeslice">
                    <xsl:choose>
                      <xsl:when test="$collocated_VOR_designator != ''">
                        <xsl:value-of select="fcn:format-timeslice-info($VOR-valid-ts)"/>
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
                        <xsl:variable name="navaid-valid-ts" select="fcn:get-valid-timeslice($navaid-baseline-ts)"/>
                        <xsl:choose>
                          <!-- If Navaid has at least one availability (excluding xsi:nil='true') -->
                          <xsl:when test="$navaid-valid-ts/aixm:availability[not(@xsi:nil='true')]">
                            <xsl:value-of select="concat('(from Navaid)&lt;br/&gt;', fcn:format-working-hours($navaid-valid-ts/aixm:availability/aixm:NavaidOperationalStatus))"/>
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
                  <xsl:variable name="DME_effective_date">
                    <xsl:if test="gml:validTime/gml:TimePeriod/gml:beginPosition">
                      <xsl:value-of select="fcn:format-date(gml:validTime/gml:TimePeriod/gml:beginPosition)"/>
                    </xsl:if>
                  </xsl:variable>
                  
                  <!-- Originator -->
                  <xsl:variable name="originator" select="
                    if(aixm:extension/ead-audit:DMEExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg)
                    then aixm:extension/ead-audit:DMEExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg
                    else ''"/>
                  
                  <tr style="white-space:nowrap;vertical-align:top;">
                    <td><xsl:value-of select="if (string-length($DME_UUID) gt 0) then $DME_UUID else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($DME_timeslice) gt 0) then $DME_timeslice else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($DME_designator) gt 0) then $DME_designator else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($DME_name) gt 0) then $DME_name else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($ResponsibleState) gt 0) then $ResponsibleState else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($ResponsibleState_timeslice) gt 0) then $ResponsibleState_timeslice else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($DME_lat) gt 0) then $DME_lat else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($DME_long) gt 0) then $DME_long else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($collocated_VOR_designator) gt 0) then $collocated_VOR_designator else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($collocated_VOR_timeslice) gt 0) then $collocated_VOR_timeslice else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($DME_channel) gt 0) then $DME_channel else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($DME_virtual_freq) gt 0) then $DME_virtual_freq else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($DME_virtual_freq_uom) gt 0) then $DME_virtual_freq_uom else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($DME_datum) gt 0) then $DME_datum else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($DME_working_hours) gt 0) then $DME_working_hours else '&#160;'" disable-output-escaping="yes"/></td>
                    <td><xsl:value-of select="if (string-length($DME_effective_date) gt 3) then $DME_effective_date else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($originator) gt 0) then $originator else '&#160;'"/></td>
                  </tr>
                  
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