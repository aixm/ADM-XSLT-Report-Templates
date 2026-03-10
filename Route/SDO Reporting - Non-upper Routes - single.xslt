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
                    featureTypes: aixm:RouteSegment
  includeReferencedFeaturesLevel: 1
               permanentBaseline: true
                       dataScope: ReleasedData
                     AIXMversion: 5.1.1
-->

<xsl:stylesheet version="3.0" 
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
  
  <!-- Keys -->
  <xsl:key name="route-by-uuid" match="aixm:Route" use="gml:identifier"/>
  <xsl:key name="point-by-uuid" match="aixm:DesignatedPoint | aixm:Navaid" use="gml:identifier"/>

  <!-- Global variable to capture document root for use in key() functions -->
  <xsl:variable name="doc-root" select="/"/>

  <xsl:template match="/">
    
    <html xmlns="http://www.w3.org/1999/xhtml">
      
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <meta http-equiv="Expires" content="120"/>
        <title>SDO Reporting - Non-upper Routes</title>
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
          <center><b>Non-upper Routes</b></center>
          <hr/>
        </div>
        
        <div class="table-wrapper">
          <table  class="data-table">
          
            <thead>
              <tr>
                <td><strong>Master gUID</strong></td>
              </tr>
              <tr>
                <td><strong>Route Designator</strong></td>
              </tr>
              <tr>
                <td><strong>Area Desig.</strong></td>
              </tr>
              <tr>
                <td><strong>Start identifier</strong></td>
              </tr>
              <tr>
                <td><strong>Type</strong></td>
              </tr>
              <tr>
                <td><strong>End Identifier</strong></td>
              </tr>
              <tr>
                <td><strong>Type</strong></td>
              </tr>
              <tr>
                <td><strong>Upper limit</strong></td>
              </tr>
              <tr>
                <td><strong>Unit of measurement [upper limit]</strong></td>
              </tr>
              <tr>
                <td><strong>Reference for upper limit</strong></td>
              </tr>
              <tr>
                <td><strong>Lower limit</strong></td>
              </tr>
              <tr>
                <td><strong>Unit of measurement [lower limit]</strong></td>
              </tr>
              <tr>
                <td><strong>Reference for lower limit</strong></td>
              </tr>
              <tr>
                <td><strong>Effective date</strong></td>
              </tr>
              <tr>
                <td><strong>Valid TimeSlice - Route</strong></td>
              </tr>
              <tr>
                <td><strong>Valid TimeSlice - RouteSegment</strong></td>
              </tr>
              <tr>
                <td><strong>Originator</strong></td>
              </tr>
              <tr>
                <td style="background-color: #f5f5f5;">&#160;</td>
              </tr>
            </thead>
            
            <tbody>
              
              <!-- Group segments by route (which have level = 'LOWER') - using only valid timeslices -->
              <!-- First, group all RouteSegments by identifier to find the valid timeslice for each -->
              <xsl:variable name="valid-segments" as="element()*">
                <xsl:for-each-group select="//aixm:RouteSegment" group-by="gml:identifier">
                  <xsl:variable name="baseline-timeslices" select="current-group()/aixm:timeSlice/aixm:RouteSegmentTimeSlice[aixm:interpretation = 'BASELINE']"/>
                  <xsl:variable name="valid-timeslice" select="fcn:get-valid-timeslice($baseline-timeslices)"/>
                  <!-- Only include segments with level = 'LOWER' -->
                  <xsl:if test="$valid-timeslice/aixm:level = 'LOWER'">
                    <!-- Create a temporary element with the segment and its valid timeslice -->
                    <xsl:element name="aixm:RouteSegment" namespace="http://www.aixm.aero/schema/5.1.1">
                      <xsl:copy-of select="current-group()[1]/gml:identifier"/>
                      <xsl:element name="aixm:timeSlice" namespace="http://www.aixm.aero/schema/5.1.1">
                        <xsl:copy-of select="$valid-timeslice"/>
                      </xsl:element>
                    </xsl:element>
                  </xsl:if>
                </xsl:for-each-group>
              </xsl:variable>
  
              <!-- Now group the segments by route -->
              <xsl:for-each-group select="$valid-segments" group-by="replace(aixm:timeSlice/aixm:RouteSegmentTimeSlice/aixm:routeFormed/@xlink:href, '^(urn:uuid:|#uuid\.)', '')">
  
                <!-- Natural sort by Route Designator: prefix then numeric -->
                <xsl:sort
                  select="
                  let $Route := key('route-by-uuid', current-grouping-key(), $doc-root),
                  $baseline-timeslices := $Route/aixm:timeSlice/aixm:RouteTimeSlice[aixm:interpretation = 'BASELINE'],
                  $RTS := fcn:get-valid-timeslice($baseline-timeslices),
                  $prefix := concat($RTS/aixm:designatorPrefix, $RTS/aixm:designatorSecondLetter)
                  return $prefix"
                  data-type="text" order="ascending"/>
  
                <xsl:sort
                  select="
                  let $Route := key('route-by-uuid', current-grouping-key(), $doc-root),
                  $baseline-timeslices := $Route/aixm:timeSlice/aixm:RouteTimeSlice[aixm:interpretation = 'BASELINE'],
                  $RTS := fcn:get-valid-timeslice($baseline-timeslices),
                  $number := number($RTS/aixm:designatorNumber)
                  return $number"
                  data-type="number" order="ascending"/>
  
                <xsl:variable name="Route_uuid" select="current-grouping-key()"/>
                <xsl:variable name="Route" select="key('route-by-uuid', $Route_uuid, $doc-root)"/>
                <!-- Get the valid Route timeslice -->
                <xsl:variable name="route-baseline-timeslices" select="$Route/aixm:timeSlice/aixm:RouteTimeSlice[aixm:interpretation = 'BASELINE']"/>
                <xsl:variable name="route-valid-ts" select="fcn:get-valid-timeslice($route-baseline-timeslices)"/>
                <xsl:variable name="Master_gUID" select="$Route/gml:identifier"/>
                <xsl:variable name="route-designator" select="concat($route-valid-ts/aixm:designatorPrefix, $route-valid-ts/aixm:designatorSecondLetter, $route-valid-ts/aixm:designatorNumber)"/>
                <xsl:variable name="route-area-designator" select="$route-valid-ts/aixm:locationDesignator"/>
                <xsl:variable name="effective-date">
                  <xsl:if test="$route-valid-ts/gml:validTime/gml:TimePeriod/gml:beginPosition">
                    <xsl:value-of select="fcn:format-date($route-valid-ts/gml:validTime/gml:TimePeriod/gml:beginPosition)"/>
                  </xsl:if>
                </xsl:variable>
                <xsl:variable name="route-valid-ts-info" select="fcn:format-timeslice-info($route-valid-ts)"/>
                <xsl:variable name="originator" select="$route-valid-ts/aixm:extension/ead-audit:RouteExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
                
                <!-- Extract all segments in this route -->
                <xsl:variable name="segments" select="current-group()"/>              
                
                <!-- Find the first segment (its start point is not an end point elsewhere on this route) -->
                <xsl:variable name="start-segment" as="element()*">
                  <xsl:iterate select="$segments">
                    <xsl:variable name="seg" select="."/>
                    <xsl:variable name="route_segment-ts" select="aixm:timeSlice/aixm:RouteSegmentTimeSlice[aixm:interpretation = 'BASELINE']"/>
                    <xsl:variable name="start" select="replace($route_segment-ts/aixm:start/*/*/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
                    <xsl:variable name="end" select="$segments/aixm:timeSlice/aixm:RouteSegmentTimeSlice[aixm:interpretation = 'BASELINE']/aixm:end/*/*/@xlink:href"/>
                    <xsl:if test="not($end[contains(., $start)])">
                      <xsl:sequence select="."/>
                      <xsl:break/>
                    </xsl:if>
                  </xsl:iterate>
                </xsl:variable>
                
                <!-- Recursively walk the chain -->
                <xsl:call-template name="output-chain">
                  <xsl:with-param name="segment" select="$start-segment"/>
                  <xsl:with-param name="segments" select="$segments"/>
                  <xsl:with-param name="Master_gUID" select="$Master_gUID"/>
                  <xsl:with-param name="route-designator" select="$route-designator"/>
                  <xsl:with-param name="route-area-designator" select="$route-area-designator"/>
                  <xsl:with-param name="effective-date" select="$effective-date"/>
                  <xsl:with-param name="route-valid-ts-info" select="$route-valid-ts-info"/>
                  <xsl:with-param name="originator" select="$originator"/>
                </xsl:call-template>
                
              </xsl:for-each-group>
              
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
              <td><font size="-1">Route Designator</font></td>
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
  
  <!-- Recursive template to walk the chain -->
  <xsl:template name="output-chain">
    <xsl:param name="segment"/>
    <xsl:param name="segments"/>
    <xsl:param name="Master_gUID"/>
    <xsl:param name="route-designator"/>
    <xsl:param name="route-area-designator"/>
    <xsl:param name="effective-date"/>
    <xsl:param name="route-valid-ts-info"/>
    <xsl:param name="originator"/>
    
    <xsl:variable name="route_segment-ts" select="$segment/aixm:timeSlice/aixm:RouteSegmentTimeSlice[aixm:interpretation = 'BASELINE']"/>
    <xsl:variable name="start_uuid" select="replace($route_segment-ts/aixm:start/*/*/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
    <xsl:variable name="end_uuid" select="replace($route_segment-ts/aixm:end/*/*/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
    <xsl:variable name="route-upper-limit">
      <xsl:choose>
        <xsl:when test="not($route_segment-ts/aixm:upperLimit)">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:insert-value($route_segment-ts/aixm:upperLimit)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="route-upper-limit_uom" select="$route_segment-ts/aixm:upperLimit/@uom"/>
    <xsl:variable name="route-upper-limit_reference">
      <xsl:choose>
        <xsl:when test="not($route_segment-ts/aixm:upperLimitReference)">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:insert-value($route_segment-ts/aixm:upperLimitReference)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="route-lower-limit">
      <xsl:choose>
        <xsl:when test="not($route_segment-ts/aixm:lowerLimit)">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:insert-value($route_segment-ts/aixm:lowerLimit)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="route-lower-limit_uom" select="$route_segment-ts/aixm:lowerLimit/@uom"/>
    <xsl:variable name="route-lower-limit_reference">
      <xsl:choose>
        <xsl:when test="not($route_segment-ts/aixm:lowerLimitReference)">
          <xsl:value-of select="''"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="fcn:insert-value($route_segment-ts/aixm:lowerLimitReference)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="route_segment-valid-ts-info" select="fcn:format-timeslice-info($route_segment-ts)"/>

    <!-- Get the valid timeslice for start point -->
    <xsl:variable name="start_point" select="key('point-by-uuid', $start_uuid, $doc-root)"/>
    <xsl:variable name="start_baseline_timeslices" select="$start_point/aixm:timeSlice/*[aixm:interpretation = 'BASELINE']"/>
    <xsl:variable name="start_valid_timeslice" select="fcn:get-valid-timeslice($start_baseline_timeslices)"/>

    <xsl:variable name="start_designator" select="$start_valid_timeslice/aixm:designator"/>
    <xsl:variable name="start_type">
      <xsl:choose>
        <xsl:when test="$start_valid_timeslice/self::aixm:DesignatedPointTimeSlice/aixm:type">
          <xsl:value-of select="concat('WPT', ' (', $start_valid_timeslice/aixm:type, ')')"/>
        </xsl:when>
        <xsl:when test="$start_valid_timeslice/self::aixm:NavaidTimeSlice/aixm:type">
          <xsl:value-of select="$start_valid_timeslice/aixm:type"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>

    <!-- Get the valid timeslice for end point -->
    <xsl:variable name="end_point" select="key('point-by-uuid', $end_uuid, $doc-root)"/>
    <xsl:variable name="end_baseline_timeslices" select="$end_point/aixm:timeSlice/*[aixm:interpretation = 'BASELINE']"/>
    <xsl:variable name="end_valid_timeslice" select="fcn:get-valid-timeslice($end_baseline_timeslices)"/>

    <xsl:variable name="end_designator" select="$end_valid_timeslice/aixm:designator"/>
    <xsl:variable name="end_type">
      <xsl:choose>
        <xsl:when test="$end_valid_timeslice/self::aixm:DesignatedPointTimeSlice/aixm:type">
          <xsl:value-of select="concat('WPT', ' (', $end_valid_timeslice/aixm:type, ')')"/>
        </xsl:when>
        <xsl:when test="$end_valid_timeslice/self::aixm:NavaidTimeSlice/aixm:type">
          <xsl:value-of select="$end_valid_timeslice/aixm:type"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    
    <tr>
      <td><xsl:value-of select="if (string-length($Master_gUID) = 0) then '&#160;' else $Master_gUID"/></td>
    </tr>
    <tr>
      <td><xsl:value-of select="if (string-length($route-designator) = 0) then '&#160;' else $route-designator"/></td>
    </tr>
    <tr>
      <td><xsl:value-of select="if (string-length($route-area-designator) = 0) then '&#160;' else $route-area-designator"/></td>
    </tr>
    <tr>
      <td><xsl:value-of select="if (string-length($start_designator) = 0) then '&#160;' else $start_designator"/></td>
    </tr>
    <tr>
      <td><xsl:value-of select="if (string-length($start_type) = 0) then '&#160;' else $start_type"/></td>
    </tr>
    <tr>
      <td><xsl:value-of select="if (string-length($end_designator) = 0) then '&#160;' else $end_designator"/></td>
    </tr>
    <tr>
      <td><xsl:value-of select="if (string-length($end_type) = 0) then '&#160;' else $end_type"/></td>
    </tr>
    <tr>
      <td><xsl:value-of select="if (string-length($route-upper-limit) = 0) then '&#160;' else $route-upper-limit"/></td>
    </tr>
    <tr>
      <td><xsl:value-of select="if (string-length($route-upper-limit_uom) = 0) then '&#160;' else $route-upper-limit_uom"/></td>
    </tr>
    <tr>
      <td><xsl:value-of select="if (string-length($route-upper-limit_reference) = 0) then '&#160;' else $route-upper-limit_reference"/></td>
    </tr>
    <tr>
      <td><xsl:value-of select="if (string-length($route-lower-limit) = 0) then '&#160;' else $route-lower-limit"/></td>
    </tr>
    <tr>
      <td><xsl:value-of select="if (string-length($route-lower-limit_uom) = 0) then '&#160;' else $route-lower-limit_uom"/></td>
    </tr>
    <tr>
      <td><xsl:value-of select="if (string-length($route-lower-limit_reference) = 0) then '&#160;' else $route-lower-limit_reference"/></td>
    </tr>
    <tr>
      <td><xsl:value-of select="if (string-length($effective-date) = 2) then '&#160;' else $effective-date"/></td>
    </tr>
    <tr>
      <td><xsl:value-of select="if (string-length($route-valid-ts-info) = 2) then '&#160;' else $route-valid-ts-info"/></td>
    </tr>
    <tr>
      <td><xsl:value-of select="if (string-length($route_segment-valid-ts-info) = 2) then '&#160;' else $route_segment-valid-ts-info"/></td>
    </tr>
    <tr>
      <td><xsl:value-of select="if (string-length($originator) = 0) then '&#160;' else $originator"/></td>
    </tr>
    <tr>
      <td style="background-color: #f5f5f5;">&#160;</td>
    </tr>
    
    <!-- Find next segment whose start = this end -->
    <xsl:variable name="next" select="$segments[aixm:timeSlice/aixm:RouteSegmentTimeSlice[aixm:interpretation = 'BASELINE']/aixm:start/*/*/@xlink:href = concat('urn:uuid:', $end_uuid)][1]"/>
    
    <xsl:if test="$next">
      <xsl:call-template name="output-chain">
        <xsl:with-param name="segment" select="$next"/>
        <xsl:with-param name="segments" select="$segments"/>
        <xsl:with-param name="route-designator" select="$route-designator"/>
        <xsl:with-param name="Master_gUID" select="$Master_gUID"/>
        <xsl:with-param name="route-area-designator" select="$route-area-designator"/>
        <xsl:with-param name="effective-date" select="$effective-date"/>
        <xsl:with-param name="route-valid-ts-info" select="$route-valid-ts-info"/>
        <xsl:with-param name="originator" select="$originator"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>