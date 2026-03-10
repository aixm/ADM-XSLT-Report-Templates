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
  includeReferencedFeaturesLevel: 2
               featureOccurrence: aixm:Navaid.aixm:type EQUALS 'VOR' OR aixm:Navaid.aixm:type EQUALS 'VOR_DME' OR aixm:Navaid.aixm:type EQUALS 'VORTAC'
               permanentBaseline: true
                       dataScope: ReleasedData
                     AIXMversion: 5.1.1
              indirectReferences: aixm:Navaid references (aixm:InformationService)
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
  
  <xsl:function name="fcn:get-last-word" as="xs:string">
    <xsl:param name="text" as="xs:string"/>
    <xsl:variable name="words" select="tokenize(normalize-space($text), '\s+')"/>
    <xsl:sequence select="$words[last()]"/>
  </xsl:function>
  
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

  <!-- Recursively find STATE organization from an organization UUID -->
  <xsl:function name="fcn:find-state-org" as="element()?">
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
          <!-- Otherwise, check if it has a related organization -->
          <xsl:when test="$org-valid-ts/aixm:relatedOrganisationAuthority/aixm:OrganisationAuthorityAssociation/aixm:theOrganisationAuthority/@xlink:href">
            <xsl:variable name="related-uuid" select="replace($org-valid-ts/aixm:relatedOrganisationAuthority/aixm:OrganisationAuthorityAssociation/aixm:theOrganisationAuthority/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
            <!-- Recursively search the related organization -->
            <xsl:sequence select="fcn:find-state-org($related-uuid, ($visited-uuids, $org-uuid), $root)"/>
          </xsl:when>
        </xsl:choose>
      </xsl:if>
    </xsl:if>
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
                    <xsl:if test="position() != last()"><xsl:text> </xsl:text></xsl:if>
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
  
  <!-- Get annotation text escaping special HTML characters -->
  <xsl:function name="fcn:get-annotation-text" as="xs:string">
    <xsl:param name="raw_text" as="xs:string"/>
    <!-- First, escape special HTML characters in the raw text before processing -->
    <xsl:variable name="escaped_raw_text" select="replace(replace($raw_text, '&lt;', '&amp;lt;'), '&gt;', '&amp;gt;')"/>
    <xsl:variable name="lines" select="for $line in tokenize($escaped_raw_text, '&#xA;') return normalize-space($line)"/>
    <xsl:variable name="non_empty_lines" select="$lines[string-length(.) gt 0]"/>
    <xsl:value-of select="string-join($non_empty_lines, ' ')"/>
  </xsl:function>
  
  <xsl:template match="/">
    
    <html xmlns="http://www.w3.org/1999/xhtml">
      
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <meta http-equiv="Expires" content="120"/>
        <title>SDO Reporting - VOR</title>
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
            width: 100vw;
          }
          .data-table td {
            padding: 4px 8px;
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
          <center><b>VOR</b></center>
          <hr/>
        </div>
        
        <div class="table-wrapper">
          <table  class="data-table">
          
            <thead>
              <tr>
                <td><strong>Identification</strong></td>
              </tr>
              <tr>
                <td><strong>Latitude</strong></td>
              </tr>
              <tr>
                <td><strong>Longitude</strong></td>
              </tr>
              <tr>
                <td><strong>Responsible organisaton or authority - Role</strong></td>
              </tr>
              <tr>
                <td><strong>Responsible organisaton or authority - Name</strong></td>
              </tr>
              <tr>
                <td><strong>Responsible organisaton or authority - Sequence number</strong></td>
              </tr>
              <tr>
                <td><strong>Responsible organisaton or authority - Valid TimeSlice</strong></td>
              </tr>
              <tr>
                <td><strong>Unit providing broadcast service - Name</strong></td>
              </tr>
              <tr>
                <td><strong>Broadcast service - Type</strong></td>
              </tr>
              <tr>
                <td><strong>Broadcast service - Valid TimeSlice</strong></td>
              </tr>
              <tr>
                <td><strong>Name</strong></td>
              </tr>
              <tr>
                <td><strong>Type</strong></td>
              </tr>
              <tr>
                <td><strong>Frequency</strong></td>
              </tr>
              <tr>
                <td><strong>Unit of measurement [frequency]</strong></td>
              </tr>
              <tr>
                <td><strong>North reference</strong></td>
              </tr>
              <tr>
                <td><strong>Station declination</strong></td>
              </tr>
              <tr>
                <td><strong>Magnetic variation</strong></td>
              </tr>
              <tr>
                <td><strong>Magnetic variation date</strong></td>
              </tr>
              <tr>
                <td><strong>Emission</strong></td>
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
                <td><strong>Working hours</strong></td>
              </tr>
              <tr>
                <td><strong>Remark to working hours</strong></td>
              </tr>
              <tr>
                <td><strong>Remarks</strong></td>
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
                <td><strong>Originator</strong></td>
              </tr>
              <tr>
                <td style="background-color: #f5f5f5;">&#160;</td>
              </tr>
            </thead>
            
            <tbody>
              
              <xsl:for-each select="//aixm:VOR">
                
                <xsl:sort select="(aixm:timeSlice/aixm:VORTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:VORTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)][aixm:correctionNumber = max(../aixm:VORTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:VORTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)]/aixm:correctionNumber)])[1]/aixm:designator" order="ascending"/>
                <!-- Get all BASELINE time slices for this feature -->
                <xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:VORTimeSlice[aixm:interpretation = 'BASELINE']"/>
                <!-- Select the valid time slice -->
                <xsl:variable name="valid-timeslice" select="fcn:get-valid-timeslice($baseline-timeslices)"/>
                
                <xsl:for-each select="$valid-timeslice">
                  
                  <!-- Internal UID (master) -->
                  <xsl:variable name="VOR_UUID" select="../../gml:identifier"/>
                  
                  <!-- VOR - Valid TimeSlice -->
                  <xsl:variable name="VOR_timeslice" select="fcn:format-timeslice-info(.)"/>
                  
                  <!-- Identification -->
                  <xsl:variable name="VOR_designator">
                    <xsl:choose>
                      <xsl:when test="not(aixm:designator)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:designator)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- VOR Coordinates -->
                  
                  <!-- Select the type of coordinates: 'DMS' or 'DEC' -->
                  <xsl:variable name="coordinates_type" select="'DMS'"/>
                  
                  <!-- Select the number of decimals -->
                  <xsl:variable name="coordinates_decimal_number" select="2"/>
                  
                  <!-- VOR Datum -->
                  <xsl:variable name="VOR_datum">
                    <xsl:value-of select="replace(replace(aixm:location/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
                  </xsl:variable>
                  
                  <xsl:variable name="lat-long-datums" select="
                    ('EPSG:4326','EPSG:4258','EPSG:4322','EPSG:4230',
                    'EPSG:4668','EPSG:4312','EPSG:4215','EPSG:4801',
                    'EPSG:4149','EPSG:4326','EPSG:4275','EPSG:4746',
                    'EPSG:4121','EPSG:4658','EPSG:4299','EPSG:4806',
                    'EPSG:4277','EPSG:4207','EPSG:4274','EPSG:4740',
                    'EPSG:4313','EPSG:4124','EPSG:4267','EPSG:4269')"/>
                  
                  <!-- Extract coordinates depending on the coordinate system -->
                  <xsl:variable name="VOR_coordinates" select="aixm:location/aixm:ElevatedPoint/gml:pos"/>
                  <xsl:variable name="VOR_latitude_decimal">
                    <xsl:choose>
                      <xsl:when test="$VOR_datum = $lat-long-datums">
                        <xsl:value-of  select="number(substring-before($VOR_coordinates, ' '))"/>
                      </xsl:when>
                      <xsl:when test="matches($VOR_datum, '^OGC:.*CRS84$')">
                        <xsl:value-of select="number(substring-after($VOR_coordinates, ' '))"/>
                      </xsl:when>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="VOR_longitude_decimal">
                    <xsl:choose>
                      <xsl:when test="$VOR_datum = $lat-long-datums">
                        <xsl:value-of  select="number(substring-after($VOR_coordinates, ' '))"/>
                      </xsl:when>
                      <xsl:when test="matches($VOR_datum, '^OGC:.*CRS84$')">
                        <xsl:value-of select="number(substring-before($VOR_coordinates, ' '))"/>
                      </xsl:when>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="VOR_lat">
                    <xsl:if test="string-length($VOR_latitude_decimal) gt 0">
                      <xsl:value-of select="fcn:format-latitude($VOR_latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
                    </xsl:if>
                  </xsl:variable>
                  <xsl:variable name="VOR_long">
                    <xsl:if test="string-length($VOR_longitude_decimal) gt 0">
                      <xsl:value-of select="fcn:format-longitude($VOR_longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
                    </xsl:if>
                  </xsl:variable>
                  
                  <!-- Responsible organisaton or authority - Role -->
                  <xsl:variable name="ResponsibleOrgAuth_role">
                    <xsl:for-each select="aixm:authority/aixm:AuthorityForNavaidEquipment">
                      <xsl:if test="aixm:type">
                        <xsl:value-of select="fcn:insert-value(aixm:type)"/>
                        <xsl:if test="position() != last()">
                          <xsl:text> | </xsl:text>
                        </xsl:if>
                      </xsl:if>
                    </xsl:for-each>
                  </xsl:variable>
  
                  <!-- Responsible organisaton or authority - Name -->
                  <xsl:variable name="ResponsibleOrgAuth_name">
                    <xsl:for-each select="aixm:authority/aixm:AuthorityForNavaidEquipment">
                      <xsl:variable name="OrgAuth_UUID" select="replace(aixm:theOrganisationAuthority/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
                      <xsl:variable name="org-baseline-ts" select="//aixm:OrganisationAuthority[gml:identifier = $OrgAuth_UUID]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice[aixm:interpretation = 'BASELINE']"/>
                      <xsl:variable name="org-valid-ts" select="fcn:get-valid-timeslice($org-baseline-ts)"/>
                      <xsl:if test="$org-valid-ts">
                        <xsl:value-of select="$org-valid-ts/aixm:name"/>
                        <xsl:if test="position() != last()">
                          <xsl:text> | </xsl:text>
                        </xsl:if>
                      </xsl:if>
                    </xsl:for-each>
                  </xsl:variable>
  
                  <!-- Responsible organisaton or authority - Valid TimeSlice -->
                  <xsl:variable name="ResponsibleOrgAuth_timeslice">
                    <xsl:for-each select="aixm:authority/aixm:AuthorityForNavaidEquipment">
                      <xsl:variable name="OrgAuth_UUID" select="replace(aixm:theOrganisationAuthority/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
                      <xsl:variable name="org-baseline-ts" select="//aixm:OrganisationAuthority[gml:identifier = $OrgAuth_UUID]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice[aixm:interpretation = 'BASELINE']"/>
                      <xsl:variable name="org-valid-ts" select="fcn:get-valid-timeslice($org-baseline-ts)"/>
                      <xsl:if test="$org-valid-ts">
                        <xsl:value-of select="fcn:format-timeslice-info($org-valid-ts)"/>
                        <xsl:if test="position() != last()">
                          <xsl:text> | </xsl:text>
                        </xsl:if>
                      </xsl:if>
                    </xsl:for-each>
                  </xsl:variable>
                  
                  <!-- Unit providing broadcast service - Name -->
                  <xsl:variable name="VOR_unit">
                    <xsl:variable name="info_services" select="//aixm:InformationService[.//aixm:navaidBroadcast/@xlink:href = concat('urn:uuid:', $VOR_UUID)]"/>
                    <xsl:for-each select="$info_services">
                      <!-- Get the valid BASELINE time slice for this InformationService -->
                      <xsl:variable name="info-baseline-ts" select="aixm:timeSlice/aixm:InformationServiceTimeSlice[aixm:interpretation = 'BASELINE']"/>
                      <xsl:variable name="info-valid-ts" select="fcn:get-valid-timeslice($info-baseline-ts)"/>
                      <!-- Get the service provider UUID -->
                      <xsl:variable name="service-provider-uuid" select="replace($info-valid-ts/aixm:serviceProvider/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
                      <!-- Get the service provider OrganisationAuthority -->
                      <xsl:variable name="provider-baseline-ts" select="//aixm:Unit[gml:identifier = $service-provider-uuid]/aixm:timeSlice/aixm:UnitTimeSlice[aixm:interpretation = 'BASELINE']"/>
                      <xsl:variable name="provider-valid-ts" select="fcn:get-valid-timeslice($provider-baseline-ts)"/>
                      <xsl:if test="$provider-valid-ts">
                        <xsl:value-of select="$provider-valid-ts/aixm:name"/>
                        <xsl:if test="position() != last()">
                          <xsl:text> | </xsl:text>
                        </xsl:if>
                      </xsl:if>
                    </xsl:for-each>
                  </xsl:variable>
  
                  <!-- Broadcast service - Type -->
                  <xsl:variable name="VOR_service_type">
                    <xsl:variable name="info_services" select="//aixm:InformationService[.//aixm:navaidBroadcast/@xlink:href = concat('urn:uuid:', $VOR_UUID)]"/>
                    <xsl:for-each select="$info_services">
                      <!-- Get the valid BASELINE time slice for this InformationService -->
                      <xsl:variable name="info-baseline-ts" select="aixm:timeSlice/aixm:InformationServiceTimeSlice[aixm:interpretation = 'BASELINE']"/>
                      <xsl:variable name="info-valid-ts" select="fcn:get-valid-timeslice($info-baseline-ts)"/>
                      <xsl:if test="$info-valid-ts/aixm:type">
                        <xsl:value-of select="fcn:insert-value($info-valid-ts/aixm:type)"/>
                        <xsl:if test="position() != last()">
                          <xsl:text> | </xsl:text>
                        </xsl:if>
                      </xsl:if>
                    </xsl:for-each>
                  </xsl:variable>
                  
                  <!-- Broadcast service - Rank -->
                  <xsl:variable name="VOR_service_rank">
                    <xsl:variable name="info_services" select="//aixm:InformationService[.//aixm:navaidBroadcast/@xlink:href = concat('urn:uuid:', $VOR_UUID)]"/>
                    <xsl:for-each select="$info_services">
                      <!-- Get the valid BASELINE time slice for this InformationService -->
                      <xsl:variable name="info-baseline-ts" select="aixm:timeSlice/aixm:InformationServiceTimeSlice[aixm:interpretation = 'BASELINE']"/>
                      <xsl:variable name="info-valid-ts" select="fcn:get-valid-timeslice($info-baseline-ts)"/>
                      <xsl:if test="$info-valid-ts/aixm:rank">
                        <xsl:value-of select="fcn:insert-value($info-valid-ts/aixm:rank)"/>
                        <xsl:if test="position() != last()">
                          <xsl:text> | </xsl:text>
                        </xsl:if>
                      </xsl:if>
                    </xsl:for-each>
                  </xsl:variable>
  
                  <!-- Broadcast service - Valid TimeSlice -->
                  <xsl:variable name="VOR_service-ts">
                    <xsl:variable name="info_services" select="//aixm:InformationService[.//aixm:navaidBroadcast/@xlink:href = concat('urn:uuid:', $VOR_UUID)]"/>
                    <xsl:for-each select="$info_services">
                      <!-- Get the valid BASELINE time slice for this InformationService -->
                      <xsl:variable name="info-baseline-ts" select="aixm:timeSlice/aixm:InformationServiceTimeSlice[aixm:interpretation = 'BASELINE']"/>
                      <xsl:variable name="info-valid-ts" select="fcn:get-valid-timeslice($info-baseline-ts)"/>
                      <xsl:value-of select="fcn:format-timeslice-info($info-valid-ts)"/>
                      <xsl:if test="position() != last()">
                        <xsl:text> | </xsl:text>
                      </xsl:if>
                    </xsl:for-each>
                  </xsl:variable>
                  
                  <!-- Name -->
                  <xsl:variable name="VOR_name">
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
                  <xsl:variable name="VOR_type">
                    <xsl:choose>
                      <xsl:when test="not(aixm:type)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:type)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- Frequency -->
                  <xsl:variable name="VOR_frequency">
                    <xsl:choose>
                      <xsl:when test="not(aixm:frequency)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:frequency)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- Unit of measurement [frequency] -->
                  <xsl:variable name="VOR_frequency_uom" select="aixm:frequency/@uom"/>
                  
                  <!-- North reference -->
                  <xsl:variable name="VOR_north_reference">
                    <xsl:choose>
                      <xsl:when test="not(aixm:zeroBearingDirection)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:zeroBearingDirection)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- Station declination -->
                  <xsl:variable name="VOR_station_declination">
                    <xsl:choose>
                      <xsl:when test="not(aixm:declination)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:declination)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- Magnetic variation -->
                  <xsl:variable name="VOR_magnetic_variation">
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
                  <xsl:variable name="VOR_magnetic_variation_date">
                    <xsl:choose>
                      <xsl:when test="not(aixm:dateMagneticVariation)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:dateMagneticVariation)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
  
                  <!-- Emission -->
                  <xsl:variable name="VOR_emission">
                    <xsl:choose>
                      <xsl:when test="not(aixm:emissionClass)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:emissionClass)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- Geographical accuracy -->
                  <xsl:variable name="VOR_geographical_accuracy">
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
                  <xsl:variable name="VOR_geographical_accuracy_uom" select="aixm:horizontalAccuracy/@uom"/>
                  
                  <!-- Elevation -->
                  <xsl:variable name="VOR_elevation">
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
                  <xsl:variable name="VOR_elevation_accuracy">
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
                  <xsl:variable name="VOR_geoid_undulation">
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
                  <xsl:variable name="VOR_vertical_distance_uom">
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
                  <xsl:variable name="VOR_CRC">
                    <xsl:if test="aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note[not(@lang) or @lang=('en','eng')], 'CRC:')]/aixm:note">
                      <xsl:value-of select="fcn:get-last-word(aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note[not(@lang) or @lang=('en','eng')], 'CRC:')]/aixm:note[not(@lang) or @lang=('en','eng')])"/>
                    </xsl:if>
                  </xsl:variable>
                  
                  <!-- Vertical Datum -->
                  <xsl:variable name="VOR_vertical_datum">
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
                  <xsl:variable name="VOR_working_hours">
                    <xsl:choose>
                      <!-- Check if VOR has at least one availability (excluding xsi:nil='true') -->
                      <xsl:when test="aixm:availability[not(@xsi:nil='true')]">
                        <xsl:value-of select="fcn:format-working-hours(aixm:availability/aixm:NavaidOperationalStatus)"/>
                      </xsl:when>
                      <!-- Check if corresponding Navaid has at least one availability (excluding xsi:nil='true') -->
                      <xsl:otherwise>
                        <!-- Find the Navaid that references this VOR -->
                        <xsl:variable name="navaid-with-VOR" select="//aixm:Navaid[.//aixm:navaidEquipment/aixm:NavaidComponent/aixm:theNavaidEquipment/@xlink:href = concat('urn:uuid:', $VOR_UUID)]"/>
                        <xsl:variable name="navaid-baseline-ts" select="$navaid-with-VOR/aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE']"/>
                        <xsl:variable name="navaid-valid-ts" select="fcn:get-valid-timeslice($navaid-baseline-ts)"/>
                        <xsl:choose>
                          <!-- If Navaid has at least one availability (excluding xsi:nil='true') -->
                          <xsl:when test="$navaid-valid-ts/aixm:availability[not(@xsi:nil='true')]">
                            <xsl:value-of select="fcn:format-working-hours($navaid-valid-ts/aixm:availability/aixm:NavaidOperationalStatus)"/>
                          </xsl:when>
                          <!-- If both VOR and Navaid have no availability (or only with xsi:nil='true'), check if VOR has xsi:nil='true' -->
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
                  <xsl:variable name="VOR_working_hours_remarks">
                    <xsl:for-each select=".//aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']/aixm:translatedNote/aixm:LinguisticNote">
                      <xsl:choose>
                        <xsl:when test="position() = 1">
                          <xsl:value-of select="concat('(', string-join((../../aixm:purpose, aixm:note/@lang), ';'), ') ', fcn:get-annotation-text(aixm:note))"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="concat(' | ', '(', string-join((../../aixm:purpose, aixm:note/@lang), ';'), ') ', fcn:get-annotation-text(aixm:note))"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:for-each>
                  </xsl:variable>
                  
                  <!-- Remarks -->
                  <xsl:variable name="VOR_remarks">
                    <xsl:variable name="dataset_creation_date" select="//aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
                    <xsl:if test="string-length($dataset_creation_date) gt 0">
                      <xsl:value-of select="concat('Current time: ', $dataset_creation_date)"/>
                    </xsl:if>
                    <xsl:for-each select="aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[
                      ((../../aixm:propertyName and (not(../../aixm:propertyName/@xsi:nil='true') or not(../../aixm:propertyName/@xsi:nil))) or not(../../aixm:propertyName)) and
                      not(contains(aixm:note, 'CRC:'))]">
                      <xsl:choose>
                        <xsl:when test="position() = 1 and string-length($dataset_creation_date) = 0">
                          <xsl:value-of select="concat('(', string-join((../../aixm:propertyName, ../../aixm:purpose, aixm:note/@lang), ';'), ') ', fcn:get-annotation-text(aixm:note))"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="concat(' | ', '(', string-join((../../aixm:propertyName, ../../aixm:purpose, aixm:note/@lang), ';'), ') ', fcn:get-annotation-text(aixm:note))"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:for-each>
                  </xsl:variable>
                  
                  <!-- Effective date -->
                  <xsl:variable name="VOR_effective_date">
                    <xsl:if test="gml:validTime/gml:TimePeriod/gml:beginPosition">
                      <xsl:value-of select="fcn:format-date(gml:validTime/gml:TimePeriod/gml:beginPosition)"/>
                    </xsl:if>
                  </xsl:variable>
                  
                  <!-- Committed on -->
                  <xsl:variable name="VOR_commit_date">
                    <xsl:if test="aixm:extension/ead-audit:VORExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate">
                      <xsl:value-of select="fcn:format-date(aixm:extension/ead-audit:VORExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)"/>
                    </xsl:if>
                  </xsl:variable>
                  
                  <!-- Originator -->
                  <xsl:variable name="originator" select="
                    if(aixm:extension/ead-audit:VORExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg)
                    then aixm:extension/ead-audit:VORExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg
                    else ''"/>
                  
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_designator) gt 0) then $VOR_designator else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_lat) gt 0) then $VOR_lat else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_long) gt 0) then $VOR_long else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($ResponsibleOrgAuth_role) gt 0) then $ResponsibleOrgAuth_role else '&#160;'" disable-output-escaping="yes"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($ResponsibleOrgAuth_name) gt 0) then $ResponsibleOrgAuth_name else '&#160;'" disable-output-escaping="yes"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($ResponsibleOrgAuth_timeslice) gt 0) then $ResponsibleOrgAuth_timeslice else '&#160;'" disable-output-escaping="yes"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_unit) gt 0) then $VOR_unit else '&#160;'" disable-output-escaping="yes"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_service_type) gt 0) then $VOR_service_type else '&#160;'" disable-output-escaping="yes"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_service_rank) gt 0) then $VOR_service_rank else '&#160;'" disable-output-escaping="yes"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_service-ts) gt 0) then $VOR_service-ts else '&#160;'" disable-output-escaping="yes"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_name) gt 0) then $VOR_name else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_type) gt 0) then $VOR_type else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_frequency) gt 0) then $VOR_frequency else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_frequency_uom) gt 0) then $VOR_frequency_uom else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_north_reference) gt 0) then $VOR_north_reference else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_station_declination) gt 0) then $VOR_station_declination else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_magnetic_variation) gt 0) then $VOR_magnetic_variation else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_magnetic_variation_date) gt 0) then $VOR_magnetic_variation_date else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_emission) gt 0) then $VOR_emission else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_datum) gt 0) then $VOR_datum else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_geographical_accuracy) gt 0) then $VOR_geographical_accuracy else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_geographical_accuracy_uom) gt 0) then $VOR_geographical_accuracy_uom else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_elevation) gt 0) then $VOR_elevation else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_elevation_accuracy) gt 0) then $VOR_elevation_accuracy else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_geoid_undulation) gt 0) then $VOR_geoid_undulation else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_vertical_distance_uom) gt 0) then $VOR_vertical_distance_uom else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_CRC) gt 0) then $VOR_CRC else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_vertical_datum) gt 0) then $VOR_vertical_datum else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_working_hours) gt 0) then $VOR_working_hours else '&#160;'" disable-output-escaping="yes"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_working_hours_remarks) gt 0) then $VOR_working_hours_remarks else '&#160;'" disable-output-escaping="yes"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_remarks) gt 0) then $VOR_remarks else '&#160;'" disable-output-escaping="yes"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_effective_date) gt 3) then $VOR_effective_date else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_commit_date) gt 3) then $VOR_commit_date else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($VOR_UUID) gt 3) then $VOR_UUID else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td><xsl:value-of select="if (string-length($originator) gt 0) then $originator else '&#160;'"/></td>
                  </tr>
                  <tr>
                    <td style="background-color: #f5f5f5;">&#160;</td>
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