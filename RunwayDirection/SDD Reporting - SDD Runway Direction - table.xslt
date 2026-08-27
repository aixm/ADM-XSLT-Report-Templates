<?xml version="1.0" encoding="UTF-8"?>
<!-- ==================================================================== -->
<!-- XSLT script for iNM eEAD -->
<!-- Source: https://github.com/aixm/ADM-XSLT-Report-Templates -->
<!-- Created by: Paul-Adrian LAPUSAN (for EUROCONTROL) -->
<!-- ==================================================================== -->
<!-- 
  Copyright (c) 2026, EUROCONTROL
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
                    featureTypes: aixm:RunwayDirection
  includeReferencedFeaturesLevel: 2
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
  xmlns:fcn="local-function"
  xmlns:ead-audit="http://www.aixm.aero/schema/5.1.1/extensions/EUR/iNM/EAD-Audit"
  exclude-result-prefixes="xsl uuid message gts gco xsd gml gss gsr gmd aixm event xlink xs xsi aixm_ds_xslt fcn ead-audit">
  
  <xsl:output method="html" indent="yes"/>
  
  <xsl:strip-space elements="*"/>
  
  <xsl:key name="AirportHeliport-by-uuid" match="aixm:AirportHeliport" use="gml:identifier"/>
  
  <!-- Global variable to capture document root for use in key() functions -->
  <xsl:variable name="doc-root" select="/"/>
  
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
  
  <!-- Get annotation text preserving line breaks and escaping special HTML characters -->
  <xsl:function name="fcn:get-annotation-text" as="xs:string">
    <xsl:param name="raw_text" as="xs:string"/>
    <!-- First, escape special HTML characters in the raw text before processing -->
    <xsl:variable name="escaped_raw_text" select="replace(replace($raw_text, '&lt;', '&amp;lt;'), '&gt;', '&amp;gt;')"/>
    <xsl:variable name="lines" select="for $line in tokenize($escaped_raw_text, '&#xA;') return normalize-space($line)"/>
    <xsl:variable name="non_empty_lines" select="$lines[string-length(.) gt 0]"/>
    <xsl:value-of select="string-join($non_empty_lines, '&lt;br/&gt;')"/>
  </xsl:function>
  
  <xsl:template match="/">
    
    <html xmlns="http://www.w3.org/1999/xhtml">
      
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <meta http-equiv="Expires" content="120"/>
        <title>SDD Reporting - SDD Runway Direction</title>
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
          <center><b>SDD Runway Direction</b></center>
          <hr/>
        </div>
        
        <div class="table-wrapper">
          <table class="data-table">
            
            <thead>
              <tr>
                <td><strong>FeatureIdentifier</strong></td>
                <td><strong>FeatureLifetimeBegin</strong></td>
                <td><strong>FeatureLifetimeEnd</strong></td>
                <td><strong>ValidityFrom</strong></td>
                <td><strong>ValidityTo</strong></td>
                <td><strong>SequenceNumber</strong></td>
                <td><strong>CorrectionNumber</strong></td>
                <td><strong>Designator</strong></td>
                <td><strong>TrueBearing</strong></td>
                <td><strong>TrueBearingAccuracy</strong></td>
                <td><strong>MagneticBearing</strong></td>
                <td><strong>PatternVFR</strong></td>
                <td><strong>SlopeTDZ</strong></td>
                <td><strong>ElevationTDZ</strong></td>
                <td><strong>ElevationTDZUom</strong></td>
                <td><strong>ElevationTDZAccuracy</strong></td>
                <td><strong>ElevationTDZAccuracyUom</strong></td>
                <td><strong>ApproachMarkingType</strong></td>
                <td><strong>ApproachMarkingCondition</strong></td>
                <td><strong>ClassLightingJAR</strong></td>
                <td><strong>PrecisionApproachGuidance</strong></td>
                <td><strong>UsedRunway/featureIdentifier</strong></td>
                <td><strong>UsedRunway/Designator</strong></td>
                <td><strong>UsedRunway/AssociatedAirportHeliport/featureIdentifier</strong></td>
                <td><strong>UsedRunway/AssociatedAirportHeliport/Designator</strong></td>
                <td><strong>UsedRunway/AssociatedAirportHeliport/Name</strong></td>
                <td><strong>StartingElement/featureIdentifier</strong></td>
                <td><strong>StartingElement/Type</strong></td>
                <td><strong>Annotation</strong></td>
                <td><strong>EAD-AUDIT:CreatedBy</strong></td>
                <td><strong>EAD-AUDIT:CreationDate</strong></td>
                <td><strong>EAD-AUDIT:CreatedByOrganisation</strong></td>
                <td><strong>EAD-AUDIT:CreatedOnBehalfOfUser</strong></td>
                <td><strong>EAD-AUDIT:CreatedOnBehalfOfOrganisation</strong></td>
                <td><strong>EAD-AUDIT:ReasonForChange</strong></td>
                <td><strong>EAD-AUDIT:ResponsibleSubsystem</strong></td>
              </tr>
            </thead>
            
            <tbody>
              
              <xsl:for-each select="//aixm:RunwayDirection">
                
                <!-- Sort by AirportHeliport designator (ascending), then by RunwayDirection designator (ascending), then by RunwayDirection sequenceNumber (descending), then by RunwayDirection correctionNumber (descending) -->
                <xsl:sort select="
                  let $RDN_baseline := aixm:timeSlice/aixm:RunwayDirectionTimeSlice[aixm:interpretation = 'BASELINE'],
                  $RDN_valid-ts := fcn:get-valid-timeslice($RDN_baseline),
                  $RWY_uuid := replace($RDN_valid-ts/aixm:usedRunway/@xlink:href, '^(urn:uuid:|#uuid\.)', ''),
                  $RWY_valid-ts := fcn:get-valid-timeslice($doc-root//aixm:Runway[gml:identifier = $RWY_uuid]/aixm:timeSlice/aixm:RunwayTimeSlice[aixm:interpretation = 'BASELINE']),
                  $AHP_uuid := replace($RWY_valid-ts/aixm:associatedAirportHeliport/@xlink:href, '^(urn:uuid:|#uuid\.)', ''),
                  $AHP := key('AirportHeliport-by-uuid', $AHP_uuid, $doc-root),
                  $AHP_baseline := $AHP/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE'],
                  $AHP_valid-ts := fcn:get-valid-timeslice($AHP_baseline)
                  return $AHP_valid-ts/aixm:designator"
                  data-type="text" order="ascending"/>
                
                <xsl:sort select="
                  let $RDN_baseline := aixm:timeSlice/aixm:RunwayDirectionTimeSlice[aixm:interpretation = 'BASELINE'],
                  $RDN_valid-ts := fcn:get-valid-timeslice($RDN_baseline)
                  return $RDN_valid-ts/aixm:designator"
                  data-type="text" order="ascending"/>
  
                <xsl:sort select="
                  let $RDN_baseline := aixm:timeSlice/aixm:RunwayDirectionTimeSlice[aixm:interpretation = 'BASELINE'],
                  $RDN_valid-ts := fcn:get-valid-timeslice($RDN_baseline)
                  return $RDN_valid-ts/aixm:sequenceNumber"
                  data-type="number" order="descending"/>
  
                <xsl:sort select="
                  let $RDN_baseline := aixm:timeSlice/aixm:RunwayDirectionTimeSlice[aixm:interpretation = 'BASELINE'],
                  $RDN_valid-ts := fcn:get-valid-timeslice($RDN_baseline)
                  return $RDN_valid-ts/aixm:correctionNumber"
                  data-type="number" order="descending"/>
  
                <!-- Get all BASELINE time slices for this feature -->
                <xsl:variable name="baseline-timeslice" select="aixm:timeSlice/aixm:RunwayDirectionTimeSlice[aixm:interpretation = 'BASELINE']"/>
                
                <xsl:for-each select="$baseline-timeslice">

                  <!-- Order the time slices of this feature by SequenceNumber, then CorrectionNumber (both descending) -->
                  <xsl:sort select="aixm:sequenceNumber" data-type="number" order="descending"/>
                  <xsl:sort select="aixm:correctionNumber" data-type="number" order="descending"/>

                  <!-- FeatureIdentifier -->
                  <xsl:variable name="RDN_identifier" select="../../gml:identifier"/>
                  
                  <!-- FeatureLifetimeBegin -->
                  <xsl:variable name="RDN_lifetime-begin">
                    <xsl:choose>
                      <xsl:when test="not(aixm:featureLifetime/gml:TimePeriod/gml:beginPosition)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:format-date(aixm:featureLifetime/gml:TimePeriod/gml:beginPosition)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- FeatureLifetimeEnd -->
                  <xsl:variable name="RDN_lifetime-end">
                    <xsl:choose>
                      <xsl:when test="aixm:featureLifetime/gml:TimePeriod/gml:endPosition/@indeterminatePosition = 'unknown'">
                        <xsl:value-of select="'31-DEC-9999'"/>
                      </xsl:when>
                      <xsl:when test="not(aixm:featureLifetime/gml:TimePeriod/gml:endPosition/@indeterminatePosition) and aixm:featureLifetime/gml:TimePeriod/gml:endPosition">
                        <xsl:value-of select="fcn:format-date(aixm:featureLifetime/gml:TimePeriod/gml:endPosition)"/>
                      </xsl:when>
                      <xsl:when test="not(aixm:featureLifetime/gml:TimePeriod/gml:endPosition)">
                        <xsl:value-of select="fcn:format-date(aixm:featureLifetime/gml:TimePeriod/gml:endPosition)"/>
                      </xsl:when>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- ValidityFrom -->
                  <xsl:variable name="RDN_validity-begin">
                    <xsl:choose>
                      <xsl:when test="not(gml:validTime/gml:TimePeriod/gml:beginPosition)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:format-date(gml:validTime/gml:TimePeriod/gml:beginPosition)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- ValidityTo -->
                  <xsl:variable name="RDN_validity-end">
                    <xsl:choose>
                      <xsl:when test="gml:validTime/gml:TimePeriod/gml:endPosition/@indeterminatePosition = 'unknown'">
                        <xsl:value-of select="'31-DEC-9999'"/>
                      </xsl:when>
                      <xsl:when test="not(gml:validTime/gml:TimePeriod/gml:endPosition/@indeterminatePosition) and gml:validTime/gml:TimePeriod/gml:endPosition">
                        <xsl:value-of select="fcn:format-date(gml:validTime/gml:TimePeriod/gml:endPosition)"/>
                      </xsl:when>
                      <xsl:when test="not(gml:validTime/gml:TimePeriod/gml:endPosition)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- SequenceNumber -->
                  <xsl:variable name="RDN_sequence-number">
                    <xsl:choose>
                      <xsl:when test="not(aixm:sequenceNumber)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:sequenceNumber)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- CorrectionNumber -->
                  <xsl:variable name="RDN_correction-number">
                    <xsl:choose>
                      <xsl:when test="not(aixm:correctionNumber)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:correctionNumber)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- Designator -->
                  <xsl:variable name="RDN_designator">
                    <xsl:choose>
                      <xsl:when test="not(aixm:designator)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:designator)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- TrueBearing -->
                  <xsl:variable name="RDN_true-bearing">
                    <xsl:choose>
                      <xsl:when test="not(aixm:trueBearing)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:trueBearing)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- TrueBearingAccuracy -->
                  <xsl:variable name="RDN_true-bearing-accuracy">
                    <xsl:choose>
                      <xsl:when test="not(aixm:trueBearingAccuracy)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:trueBearingAccuracy)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- MagneticBearing -->
                  <xsl:variable name="RDN_magnetic-bearing">
                    <xsl:choose>
                      <xsl:when test="not(aixm:magneticBearing)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:magneticBearing)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- PatternVFR -->
                  <xsl:variable name="RDN_pattern-VFR">
                    <xsl:choose>
                      <xsl:when test="not(aixm:patternVFR)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:patternVFR)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- SlopeTDZ -->
                  <xsl:variable name="RDN_slope-TDZ">
                    <xsl:choose>
                      <xsl:when test="not(aixm:slopeTDZ)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:slopeTDZ)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- ElevationTDZ -->
                  <xsl:variable name="RDN_elevation-TDZ">
                    <xsl:choose>
                      <xsl:when test="not(aixm:elevationTDZ)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:elevationTDZ)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- ElevationTDZUom -->
                  <xsl:variable name="RDN_elevation-TDZ-uom" select="aixm:elevationTDZ/@uom"/>
                  
                  <!-- ElevationTDZAccuracy -->
                  <xsl:variable name="RDN_elevation-TDZ-accuracy">
                    <xsl:choose>
                      <xsl:when test="not(aixm:elevationTDZAccuracy)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:elevationTDZAccuracy)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- ElevationTDZAccuracyUom -->
                  <xsl:variable name="RDN_elevation-TDZ-accuracy-uom" select="aixm:elevationTDZAccuracy/@uom"/>
                  
                  <!-- ApproachMarkingType -->
                  <xsl:variable name="RDN_approach-marking-type">
                    <xsl:choose>
                      <xsl:when test="not(aixm:approachMarkingType)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:approachMarkingType)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- ApproachMarkingCondition -->
                  <xsl:variable name="RDN_approach-marking-condition">
                    <xsl:choose>
                      <xsl:when test="not(aixm:approachMarkingCondition)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:approachMarkingCondition)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- ClassLightingJAR -->
                  <xsl:variable name="RDN_class-lighting-JAR">
                    <xsl:choose>
                      <xsl:when test="not(aixm:classLightingJAR)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:classLightingJAR)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- PrecisionApproachGuidance -->
                  <xsl:variable name="RDN_precision-approach-guidance">
                    <xsl:choose>
                      <xsl:when test="not(aixm:precisionApproachGuidance)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:precisionApproachGuidance)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- ===== Runway ===== -->
                  <xsl:variable name="RDN_RWY_identifier" select="replace(aixm:usedRunway/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
                  <xsl:variable name="RDN_RWY_valid-ts" as="element()?" select="
                    if ($RDN_RWY_identifier != '')
                    then fcn:get-valid-timeslice($doc-root//aixm:Runway[gml:identifier = $RDN_RWY_identifier]/aixm:timeSlice/aixm:RunwayTimeSlice[aixm:interpretation = 'BASELINE'])
                    else ()"/>
                  
                  <!-- UsedRunway/Designator -->
                  <xsl:variable name="RDN_RWY_designator">
                    <xsl:choose>
                      <xsl:when test="not($RDN_RWY_valid-ts/aixm:designator)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value($RDN_RWY_valid-ts/aixm:designator)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- ===== AirportHeliport ===== -->
                  <xsl:variable name="RDN_RWY_AHP_identifier" select="replace($RDN_RWY_valid-ts/aixm:associatedAirportHeliport/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
                  <xsl:variable name="RDN_RWY_AHP_valid-ts" as="element()?" select="
                    if ($RDN_RWY_AHP_identifier != '')
                    then fcn:get-valid-timeslice($doc-root//aixm:AirportHeliport[gml:identifier = $RDN_RWY_AHP_identifier]/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE'])
                    else ()"/>
                  
                  <!-- UsedRunway/AssociatedAirportHeliport/Designator -->
                  <xsl:variable name="RDN_RWY_AHP_designator">
                    <xsl:choose>
                      <xsl:when test="not($RDN_RWY_AHP_valid-ts/aixm:designator)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value($RDN_RWY_AHP_valid-ts/aixm:designator)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- UsedRunway/AssociatedAirportHeliport/Name -->
                  <xsl:variable name="RDN_RWY_AHP_name">
                    <xsl:choose>
                      <xsl:when test="not($RDN_RWY_AHP_valid-ts/aixm:name)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value($RDN_RWY_AHP_valid-ts/aixm:name)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- ===== RunwayElement ===== -->
                  <xsl:variable name="RDN_starting-element_identifier" select="replace(aixm:startingElement/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
                  <xsl:variable name="RDN_starting-element_valid-ts" as="element()?" select="
                    if ($RDN_starting-element_identifier != '')
                    then fcn:get-valid-timeslice($doc-root//aixm:RunwayElement[gml:identifier = $RDN_starting-element_identifier]/aixm:timeSlice/aixm:RunwayElementTimeSlice[aixm:interpretation = 'BASELINE'])
                    else ()"/>
                  
                  <!-- StartingElement/Type -->
                  <xsl:variable name="RDN_starting-element_type">
                    <xsl:choose>
                      <xsl:when test="not($RDN_starting-element_valid-ts/aixm:type)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value($RDN_starting-element_valid-ts/aixm:type)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- Annotation -->
                  <xsl:variable name="RDN_annotation">
                    <xsl:choose>
                      <xsl:when test="not(aixm:annotation)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:for-each select="aixm:annotation">
                          <xsl:variable name="annotation-index" select="position()"/>
                          <xsl:for-each select="aixm:Note/aixm:translatedNote/aixm:LinguisticNote">
                            <xsl:choose>
                              <xsl:when test="$annotation-index = 1 and position() = 1">
                                <xsl:value-of select="concat('[', $annotation-index, ']', '(', if (../../aixm:propertyName) then (concat(../../aixm:propertyName, ';')) else '', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', '): ', fcn:get-annotation-text(aixm:note))"/>
                              </xsl:when>
                              <xsl:otherwise>
                                <xsl:value-of select="concat('&lt;br/&gt;', '[', $annotation-index, ']', '(', if (../../aixm:propertyName) then (concat(../../aixm:propertyName, ';')) else '', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', '): ', fcn:get-annotation-text(aixm:note))"/>
                              </xsl:otherwise>
                            </xsl:choose>
                          </xsl:for-each>
                        </xsl:for-each>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- EAD-Audit -->
                  <xsl:variable name="EAD-Audit" select="aixm:extension/ead-audit:RunwayDirectionExtension/ead-audit:auditInformation/ead-audit:Audit"/>
                  
                  <!-- EAD-AUDIT:CreatedBy -->
                  <xsl:variable name="created-by">
                    <xsl:choose>
                      <xsl:when test="not($EAD-Audit/ead-audit:createdBy)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:createdBy)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- EAD-AUDIT:CreationDate -->
                  <xsl:variable name="creation-date">
                    <xsl:choose>
                      <xsl:when test="not($EAD-Audit/ead-audit:creationDate)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:format-date($EAD-Audit/ead-audit:creationDate)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- EAD-AUDIT:CreatedByOrganisation -->
                  <xsl:variable name="created-by-org">
                    <xsl:choose>
                      <xsl:when test="not($EAD-Audit/ead-audit:createdByOrg)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:createdByOrg)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- EAD-AUDIT:CreatedOnBehalfOfUser -->
                  <xsl:variable name="created-on-behalf-of-user">
                    <xsl:choose>
                      <xsl:when test="not($EAD-Audit/ead-audit:createdOnBehalfOfUser)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:createdOnBehalfOfUser)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- EAD-AUDIT:CreatedOnBehalfOfOrganisation -->
                  <xsl:variable name="created-on-behalf-of-org">
                    <xsl:choose>
                      <xsl:when test="not($EAD-Audit/ead-audit:createdOnBehalfOfOrg)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:createdOnBehalfOfOrg)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- EAD-AUDIT:ReasonForChange -->
                  <xsl:variable name="reason-for-change">
                    <xsl:choose>
                      <xsl:when test="not($EAD-Audit/ead-audit:reasonForChange)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:reasonForChange)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- EAD-AUDIT:ResponsibleSubsystem -->
                  <xsl:variable name="responsible-subsystem">
                    <xsl:choose>
                      <xsl:when test="not($EAD-Audit/ead-audit:responsibleSubsystem)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:responsibleSubsystem)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <tr style="white-space:nowrap;vertical-align:top">
                    <td><xsl:value-of select="if (string-length($RDN_identifier) gt 0) then $RDN_identifier else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_lifetime-begin) gt 0) then $RDN_lifetime-begin else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_lifetime-end) gt 0) then $RDN_lifetime-end else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_validity-begin) gt 0) then $RDN_validity-begin else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_validity-end) gt 0) then $RDN_validity-end else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_sequence-number) gt 0) then $RDN_sequence-number else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_correction-number) gt 0) then $RDN_correction-number else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_designator) gt 0) then $RDN_designator else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_true-bearing) gt 0) then $RDN_true-bearing else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_true-bearing-accuracy) gt 0) then $RDN_true-bearing-accuracy else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_magnetic-bearing) gt 0) then $RDN_magnetic-bearing else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_pattern-VFR) gt 0) then $RDN_pattern-VFR else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_slope-TDZ) gt 0) then $RDN_slope-TDZ else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_elevation-TDZ) gt 0) then $RDN_elevation-TDZ else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_elevation-TDZ-uom) gt 0) then $RDN_elevation-TDZ-uom else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_elevation-TDZ-accuracy) gt 0) then $RDN_elevation-TDZ-accuracy else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_elevation-TDZ-accuracy-uom) gt 0) then $RDN_elevation-TDZ-accuracy-uom else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_approach-marking-type) gt 0) then $RDN_approach-marking-type else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_approach-marking-condition) gt 0) then $RDN_approach-marking-condition else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_class-lighting-JAR) gt 0) then $RDN_class-lighting-JAR else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_precision-approach-guidance) gt 0) then $RDN_precision-approach-guidance else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_RWY_identifier) gt 0) then $RDN_RWY_identifier else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_RWY_designator) gt 0) then $RDN_RWY_designator else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_RWY_AHP_identifier) gt 0) then $RDN_RWY_AHP_identifier else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_RWY_AHP_designator) gt 0) then $RDN_RWY_AHP_designator else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_RWY_AHP_name) gt 0) then $RDN_RWY_AHP_name else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_starting-element_identifier) gt 0) then $RDN_starting-element_identifier else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RDN_starting-element_type) gt 0) then $RDN_starting-element_type else '&#160;'"/></td>
                    <td style="max-width:600px;white-space:normal;overflow-wrap:break-word" xml:space="preserve"><xsl:choose><xsl:when test="string-length($RDN_annotation) gt 0"><xsl:value-of select="$RDN_annotation" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
                    <td><xsl:value-of select="if (string-length($created-by) gt 0) then $created-by else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($creation-date) gt 0) then $creation-date else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($created-by-org) gt 0) then $created-by-org else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($created-on-behalf-of-user) gt 0) then $created-on-behalf-of-user else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($created-on-behalf-of-org) gt 0) then $created-on-behalf-of-org else '&#160;'"/></td>
                    <td style="max-width:600px;white-space:normal;overflow-wrap:break-word"><xsl:value-of select="if (string-length($reason-for-change) gt 0) then $reason-for-change else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($responsible-subsystem) gt 0) then $responsible-subsystem else '&#160;'"/></td>
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
              <td><font size="-1">AirportHeliport/Designator (first), RunwayDirection (second), SequenceNumber (third), CorrectionNumber (fourth)</font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">Sorting order: </font></td>
              <td><font size="-1">AirportHeliport/Designator (ascending), RunwayDirection (ascending), SequenceNumber (descending), CorrectionNumber (descending)</font></td>
            </tr>
          </table>
          
          <p>***&#160;END OF REPORT&#160;***</p>
          
        </div>
        
      </body>
      
    </html>
    
  </xsl:template>
  
</xsl:transform>