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
                    featureTypes: aixm:Navaid
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
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  exclude-result-prefixes="xsl uuid message gts gco xsd gml gss gsr gmd aixm event xlink xs xsi aixm_ds_xslt fcn ead-audit math map">
  
  <xsl:output method="html" indent="yes"/>
  
  <xsl:strip-space elements="*"/>
  
  <xsl:key name="Navaid-by-uuid" match="aixm:Navaid" use="gml:identifier"/>
  
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
  
  <!-- Pretty-print one XML node as escaped HTML: &#160;-based indentation, one line per element; namespace declarations and gml:id attributes are dropped -->
  <xsl:function name="fcn:format-gml-node" as="xs:string">
    <xsl:param name="node" as="node()"/>
    <xsl:param name="depth" as="xs:integer"/>
    <xsl:variable name="indent" select="string-join(for $i in 1 to $depth return '&amp;#160;&amp;#160;&amp;#160;', '')"/>
    <xsl:choose>
      <xsl:when test="$node instance of element()">
        <xsl:variable name="attrs" select="string-join(for $a in $node/@*[name(.) != 'gml:id'] return concat(' ', name($a), '=&quot;', string($a), '&quot;'), '')"/>
        <xsl:variable name="children" select="$node/node()[not(self::text()[normalize-space(.) = ''])]"/>
        <xsl:choose>
          <!-- empty element: self-closing tag -->
          <xsl:when test="empty($children)">
            <xsl:sequence select="concat($indent, '&amp;lt;', name($node), $attrs, '/&amp;gt;')"/>
          </xsl:when>
          <!-- text-only content stays on one line -->
          <xsl:when test="empty($children[not(self::text())])">
            <xsl:sequence select="concat($indent, '&amp;lt;', name($node), $attrs, '&amp;gt;', normalize-space(string($node)), '&amp;lt;/', name($node), '&amp;gt;')"/>
          </xsl:when>
          <!-- child elements each on their own indented line -->
          <xsl:otherwise>
            <xsl:sequence select="string-join((
              concat($indent, '&amp;lt;', name($node), $attrs, '&amp;gt;'),
              for $child in $children return fcn:format-gml-node($child, $depth + 1),
              concat($indent, '&amp;lt;/', name($node), '&amp;gt;')), '&lt;br/&gt;')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$node instance of comment()">
        <xsl:sequence select="concat($indent, '&amp;lt;!-- ', normalize-space($node), ' --&amp;gt;')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="concat($indent, normalize-space($node))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- Format (beautify) embedded GML/XML content as indented escaped HTML (render with disable-output-escaping) -->
  <xsl:function name="fcn:format-gml-xml" as="xs:string">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:sequence select="string-join(for $n in $nodes[not(self::text()[normalize-space(.) = ''])] return fcn:format-gml-node($n, 0), '&lt;br/&gt;')"/>
  </xsl:function>
  
  <xsl:template match="/">
    
    <html xmlns="http://www.w3.org/1999/xhtml">
      
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
        <meta http-equiv="Expires" content="120"/>
        <title>SDD Reporting - SDD Navaid</title>
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
          <center><b>SDD Navaid</b></center>
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
                <td><strong>Type</strong></td>
                <td><strong>Designator</strong></td>
                <td><strong>Name</strong></td>
                <td><strong>FlightChecked</strong></td>
                <td><strong>Purpose</strong></td>
                <td><strong>SignalPerformance</strong></td>
                <td><strong>CourseQuality</strong></td>
                <td><strong>IntegrityLevel</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>featureIdentifier</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Designator</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Name</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>EmissionClass</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Mobile</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>MagneticVariation</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>MagneticVariationAccuracy</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>DateMagneticVariation</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>FlightChecked</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Latitude</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Longitude</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Datum</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Location/GmlXml</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Authority/Type</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Authority/Annotation</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Authority/TheOrganisationAuthority/featureIdentifier</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Authority/TheOrganisationAuthority/Name</strong></td>
                <td><strong>NavaidEquipment/TheNavaidEquipment/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Annotation</strong></td>
                <td><strong>Location/Latitude</strong></td>
                <td><strong>Location/Longitude</strong></td>
                <td><strong>Location/Datum</strong></td>
                <td><strong>Location/GmlXml</strong></td>
                <td><strong>RunwayDirection/featureIdentifier</strong></td>
                <td><strong>RunwayDirection/Designator</strong></td>
                <td><strong>RunwayDirection/UsedRunway/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>featureIdentifier</strong></td>
                <td><strong>RunwayDirection/UsedRunway/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Designator</strong></td>
                <td><strong>RunwayDirection/UsedRunway/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>AssociatedAirportHeliport/featureIdentifier</strong></td>
                <td><strong>RunwayDirection/UsedRunway/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>AssociatedAirportHeliport/Designator</strong></td>
                <td><strong>RunwayDirection/UsedRunway/<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>AssociatedAirportHeliport/Name</strong></td>
                <td><strong>ServedAirport/featureIdentifier</strong></td>
                <td><strong>ServedAirport/Name</strong></td>
                <td><strong>ServedAirport/Designator</strong></td>
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
              
              <!-- Capture document root before iterating through Navaid features -->
              <xsl:variable name="doc-root" select="/" as="document-node()"/>

              <xsl:for-each select="//aixm:Navaid">

                <!-- Sort by EAD-AUDIT:CreatedByOrganisation (first), Type (second), Designator (third), all ascending -->
                <!-- All three keys are Navaid level, so the rows generated for one Navaid stay together -->
                <xsl:sort select="
                  let $NAV_baseline := aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE'],
                  $NAV_valid-ts := fcn:get-valid-timeslice($NAV_baseline)
                  return $NAV_valid-ts/aixm:extension/ead-audit:NavaidExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"
                  data-type="text" order="ascending"/>

                <xsl:sort select="
                  let $NAV_baseline := aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE'],
                  $NAV_valid-ts := fcn:get-valid-timeslice($NAV_baseline)
                  return $NAV_valid-ts/aixm:type"
                  data-type="text" order="ascending"/>

                <xsl:sort select="
                  let $NAV_baseline := aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE'],
                  $NAV_valid-ts := fcn:get-valid-timeslice($NAV_baseline)
                  return $NAV_valid-ts/aixm:designator"
                  data-type="text" order="ascending"/>
                
                <!-- Get all BASELINE time slices for this feature -->
                <xsl:variable name="baseline-timeslice" select="aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE']"/>
                <!-- Select the valid time slice -->
                <xsl:variable name="valid-timeslice" select="fcn:get-valid-timeslice($baseline-timeslice)"/>
                
                <xsl:for-each select="$valid-timeslice">
                  
                  <!-- FeatureIdentifier -->
                  <xsl:variable name="NAV_identifier" select="../../gml:identifier"/>
                  
                  <!-- FeatureLifetimeBegin -->
                  <xsl:variable name="NAV_lifetime-begin">
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
                  <xsl:variable name="NAV_lifetime-end">
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
                  <xsl:variable name="NAV_validity-begin">
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
                  <xsl:variable name="NAV_validity-end">
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
                  <xsl:variable name="NAV_sequence-number">
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
                  <xsl:variable name="NAV_correction-number">
                    <xsl:choose>
                      <xsl:when test="not(aixm:correctionNumber)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:correctionNumber)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- Type -->
                  <xsl:variable name="NAV_type">
                    <xsl:choose>
                      <xsl:when test="not(aixm:type)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:type)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- Designator -->
                  <xsl:variable name="NAV_designator">
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
                  <xsl:variable name="NAV_name">
                    <xsl:choose>
                      <xsl:when test="not(aixm:name)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:name)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- FlightChecked -->
                  <xsl:variable name="NAV_flight-checked">
                    <xsl:choose>
                      <xsl:when test="not(aixm:flightChecked)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:flightChecked)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- Purpose -->
                  <xsl:variable name="NAV_purpose">
                    <xsl:choose>
                      <xsl:when test="not(aixm:purpose)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:purpose)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- SignalPerformance -->
                  <xsl:variable name="NAV_signal-performance">
                    <xsl:choose>
                      <xsl:when test="not(aixm:signalPerformance)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:signalPerformance)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- CourseQuality -->
                  <xsl:variable name="NAV_course-quality">
                    <xsl:choose>
                      <xsl:when test="not(aixm:courseQuality)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:courseQuality)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- IntegrityLevel -->
                  <xsl:variable name="NAV_integrity-level">
                    <xsl:choose>
                      <xsl:when test="not(aixm:integrityLevel)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:integrityLevel)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- ===== One row per NavaidEquipment x Authority x RunwayDirection x ServedAirport ===== -->
                  <!-- max((count(...), 1)) keeps one row for the Navaid even when a collection is empty -->
                  <xsl:variable name="NAV_equipment-components" select="aixm:navaidEquipment/aixm:NavaidComponent"/>
                  <xsl:variable name="NAV_RDN-references" select="aixm:runwayDirection"/>
                  <xsl:variable name="NAV_served-airport-references" select="aixm:servedAirport"/>
                  
                  <xsl:for-each select="1 to max((count($NAV_equipment-components), 1))">
                    <xsl:variable name="NAV_equipment-index" select="." as="xs:integer"/>
                    <xsl:variable name="NAV_equipment-component" select="$NAV_equipment-components[$NAV_equipment-index]"/>
                    
                    <!-- ===== NavaidEquipment ===== -->
                    <xsl:variable name="NAV_equipment_identifier" select="replace($NAV_equipment-component/aixm:theNavaidEquipment/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
                    <xsl:variable name="NAV_equipment_valid-ts" as="element()?" select="
                      if ($NAV_equipment_identifier != '')
                      then fcn:get-valid-timeslice($doc-root//aixm:*[gml:identifier = $NAV_equipment_identifier]/aixm:timeSlice/*[aixm:interpretation = 'BASELINE'])
                      else ()"/>
                    <xsl:variable name="NAV_equipment_authorities" select="$NAV_equipment_valid-ts/aixm:authority/aixm:AuthorityForNavaidEquipment"/>
                    
                    <xsl:for-each select="1 to max((count($NAV_equipment_authorities), 1))">
                      <xsl:variable name="NAV_equipment_authority-index" select="." as="xs:integer"/>
                      <xsl:variable name="NAV_equipment_authority" select="$NAV_equipment_authorities[$NAV_equipment_authority-index]"/>
                      
                      <xsl:for-each select="1 to max((count($NAV_RDN-references), 1))">
                        <xsl:variable name="NAV_RDN-index" select="." as="xs:integer"/>
                        <xsl:variable name="NAV_RDN-reference" select="$NAV_RDN-references[$NAV_RDN-index]"/>
                        
                        <xsl:for-each select="1 to max((count($NAV_served-airport-references), 1))">
                          <xsl:variable name="NAV_served-airport-index" select="." as="xs:integer"/>
                          <xsl:variable name="NAV_served-airport-reference" select="$NAV_served-airport-references[$NAV_served-airport-index]"/>
                          
                          <!-- back to the NavaidTimeSlice as context node for all the properties below -->
                          <xsl:for-each select="$valid-timeslice">
                            
                            <!-- NavaidEquipment/TheNavaidEquipment/Designator -->
                            <xsl:variable name="NAV_equipment_designator">
                              <xsl:choose>
                                <xsl:when test="not($NAV_equipment_valid-ts/aixm:designator)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:insert-value($NAV_equipment_valid-ts/aixm:designator)"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- NavaidEquipment/TheNavaidEquipment/Name -->
                            <xsl:variable name="NAV_equipment_name">
                              <xsl:choose>
                                <xsl:when test="not($NAV_equipment_valid-ts/aixm:name)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:insert-value($NAV_equipment_valid-ts/aixm:name)"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- NavaidEquipment/TheNavaidEquipment/EmissionClass -->
                            <xsl:variable name="NAV_equipment_emission-class">
                              <xsl:choose>
                                <xsl:when test="not($NAV_equipment_valid-ts/aixm:emissionClass)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:insert-value($NAV_equipment_valid-ts/aixm:emissionClass)"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- NavaidEquipment/TheNavaidEquipment/Mobile -->
                            <xsl:variable name="NAV_equipment_mobile">
                              <xsl:choose>
                                <xsl:when test="not($NAV_equipment_valid-ts/aixm:mobile)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:insert-value($NAV_equipment_valid-ts/aixm:mobile)"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- NavaidEquipment/TheNavaidEquipment/MagneticVariation -->
                            <xsl:variable name="NAV_equipment_magnetic-variation">
                              <xsl:choose>
                                <xsl:when test="not($NAV_equipment_valid-ts/aixm:magneticVariation)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:insert-value($NAV_equipment_valid-ts/aixm:magneticVariation)"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- NavaidEquipment/TheNavaidEquipment/MagneticVariationAccuracy -->
                            <xsl:variable name="NAV_equipment_magnetic-variation-accuracy">
                              <xsl:choose>
                                <xsl:when test="not($NAV_equipment_valid-ts/aixm:magneticVariationAccuracy)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:insert-value($NAV_equipment_valid-ts/aixm:magneticVariationAccuracy)"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- NavaidEquipment/TheNavaidEquipment/DateMagneticVariation -->
                            <xsl:variable name="NAV_equipment_date-magnetic-variation">
                              <xsl:choose>
                                <xsl:when test="not($NAV_equipment_valid-ts/aixm:dateMagneticVariation)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:insert-value($NAV_equipment_valid-ts/aixm:dateMagneticVariation)"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- NavaidEquipment/TheNavaidEquipment/FlightChecked -->
                            <xsl:variable name="NAV_equipment_flight-checked">
                              <xsl:choose>
                                <xsl:when test="not($NAV_equipment_valid-ts/aixm:flightChecked)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:insert-value($NAV_equipment_valid-ts/aixm:flightChecked)"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- NavaidEquipment/TheNavaidEquipment/Datum -->
                            <xsl:variable name="NAV_equipment_datum_raw">
                              <xsl:value-of select="
                                if ($NAV_equipment_valid-ts/aixm:location/aixm:ElevatedPoint/gml:pos/@srsName) then $NAV_equipment_valid-ts/aixm:location/aixm:ElevatedPoint/gml:pos/@srsName
                                else if ($NAV_equipment_valid-ts/aixm:location/aixm:ElevatedPoint/@srsName) then $NAV_equipment_valid-ts/aixm:location/aixm:ElevatedPoint/@srsName
                                else if ($NAV_equipment_valid-ts/ancestor::aixm:*/gml:boundedBy/gml:Envelope/@srsName) then $NAV_equipment_valid-ts/ancestor::aixm:*/gml:boundedBy/gml:Envelope/@srsName
                                else if ($NAV_equipment_valid-ts/root()/*/gml:boundedBy/gml:Envelope/@srsName) then $NAV_equipment_valid-ts/root()/*/gml:boundedBy/gml:Envelope/@srsName
                                else 'No srsName found!'"/>
                            </xsl:variable>
                            <xsl:variable name="NAV_equipment_datum">
                              <xsl:value-of select="
                                if ($NAV_equipment_datum_raw != 'No srsName found!') then replace(replace($NAV_equipment_datum_raw, 'urn:ogc:def:crs:', ''), '::', ':')
                                else 'No srsName found!'"/>
                            </xsl:variable>
                            
                            <!-- NavaidEquipment/TheNavaidEquipment/Latitude -->
                            <xsl:variable name="NAV_equipment_latitude">
                              <xsl:choose>
                                <xsl:when test="not($NAV_equipment_valid-ts/aixm:location)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:when test="$NAV_equipment_valid-ts/aixm:location/@xsi:nil = 'true'">
                                  <xsl:value-of select="fcn:insert-value($NAV_equipment_valid-ts/aixm:location)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:variable name="coordinates" select="$NAV_equipment_valid-ts/aixm:location/aixm:ElevatedPoint/gml:pos"/>
                                  <xsl:choose>
                                    <xsl:when test="$NAV_equipment_datum != 'OGC:1.3:CRS84'">
                                      <xsl:value-of  select="number(substring-before($coordinates, ' '))"/>
                                    </xsl:when>
                                    <xsl:when test="$NAV_equipment_datum = 'OGC:1.3:CRS84'">
                                      <xsl:value-of select="number(substring-after($coordinates, ' '))"/>
                                    </xsl:when>
                                  </xsl:choose>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- NavaidEquipment/TheNavaidEquipment/Longitude -->
                            <xsl:variable name="NAV_equipment_longitude">
                              <xsl:choose>
                                <xsl:when test="not($NAV_equipment_valid-ts/aixm:location)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:when test="$NAV_equipment_valid-ts/aixm:location/@xsi:nil = 'true'">
                                  <xsl:value-of select="fcn:insert-value($NAV_equipment_valid-ts/aixm:location)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:variable name="coordinates" select="$NAV_equipment_valid-ts/aixm:location/aixm:ElevatedPoint/gml:pos"/>
                                  <xsl:choose>
                                    <xsl:when test="$NAV_equipment_datum != 'OGC:1.3:CRS84'">
                                      <xsl:value-of  select="number(substring-after($coordinates, ' '))"/>
                                    </xsl:when>
                                    <xsl:when test="$NAV_equipment_datum = 'OGC:1.3:CRS84'">
                                      <xsl:value-of select="number(substring-before($coordinates, ' '))"/>
                                    </xsl:when>
                                  </xsl:choose>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- NavaidEquipment/TheNavaidEquipment/Location/GmlXml -->
                            <xsl:variable name="NAV_equipment_location-xml">
                              <xsl:choose>
                                <xsl:when test="not($NAV_equipment_valid-ts/aixm:location)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:when test="$NAV_equipment_valid-ts/aixm:location/@xsi:nil = 'true'">
                                  <xsl:value-of select="fcn:insert-value($NAV_equipment_valid-ts/aixm:location)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:format-gml-xml($NAV_equipment_valid-ts/aixm:location/node())"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- NavaidEquipment/TheNavaidEquipment/Annotation -->
                            <xsl:variable name="NAV_equipment_annotation">
                              <xsl:choose>
                                <xsl:when test="not($NAV_equipment_valid-ts/aixm:annotation)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:for-each select="$NAV_equipment_valid-ts/aixm:annotation">
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
                            
                            <!-- Location/Datum -->
                            <xsl:variable name="NAV_location_datum_raw">
                              <xsl:value-of select="
                                if (aixm:location/aixm:ElevatedPoint/gml:pos/@srsName) then aixm:location/aixm:ElevatedPoint/gml:pos/@srsName
                                else if (aixm:location/aixm:ElevatedPoint/@srsName) then aixm:location/aixm:ElevatedPoint/@srsName
                                else if (ancestor::aixm:Navaid/gml:boundedBy/gml:Envelope/@srsName) then ancestor::aixm:Navaid/gml:boundedBy/gml:Envelope/@srsName
                                else if (root()/*/gml:boundedBy/gml:Envelope/@srsName) then root()/*/gml:boundedBy/gml:Envelope/@srsName
                                else 'No srsName found!'"/>
                            </xsl:variable>
                            <xsl:variable name="NAV_location_datum">
                              <xsl:value-of select="
                                if ($NAV_location_datum_raw != 'No srsName found!') then replace(replace($NAV_location_datum_raw, 'urn:ogc:def:crs:', ''), '::', ':')
                                else 'No srsName found!'"/>
                            </xsl:variable>
                            
                            <!-- Location/Latitude -->
                            <xsl:variable name="NAV_location_latitude">
                              <xsl:choose>
                                <xsl:when test="not(aixm:location)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:when test="aixm:location/@xsi:nil = 'true'">
                                  <xsl:value-of select="fcn:insert-value(aixm:location)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:variable name="coordinates" select="aixm:location/aixm:ElevatedPoint/gml:pos"/>
                                  <xsl:choose>
                                    <xsl:when test="$NAV_location_datum != 'OGC:1.3:CRS84'">
                                      <xsl:value-of  select="number(substring-before($coordinates, ' '))"/>
                                    </xsl:when>
                                    <xsl:when test="$NAV_location_datum = 'OGC:1.3:CRS84'">
                                      <xsl:value-of select="number(substring-after($coordinates, ' '))"/>
                                    </xsl:when>
                                  </xsl:choose>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- Location/Longitude -->
                            <xsl:variable name="NAV_location_longitude">
                              <xsl:choose>
                                <xsl:when test="not(aixm:location)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:when test="aixm:location/@xsi:nil = 'true'">
                                  <xsl:value-of select="fcn:insert-value(aixm:location)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:variable name="coordinates" select="aixm:location/aixm:ElevatedPoint/gml:pos"/>
                                  <xsl:choose>
                                    <xsl:when test="$NAV_location_datum != 'OGC:1.3:CRS84'">
                                      <xsl:value-of  select="number(substring-after($coordinates, ' '))"/>
                                    </xsl:when>
                                    <xsl:when test="$NAV_location_datum = 'OGC:1.3:CRS84'">
                                      <xsl:value-of select="number(substring-before($coordinates, ' '))"/>
                                    </xsl:when>
                                  </xsl:choose>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- Location/GmlXml -->
                            <xsl:variable name="NAV_location_gml-xml">
                              <xsl:choose>
                                <xsl:when test="not(aixm:location)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:when test="aixm:location/@xsi:nil = 'true'">
                                  <xsl:value-of select="fcn:insert-value(aixm:location)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:format-gml-xml(aixm:location/node())"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- ===== NavaidEquipment -> OrganisationAuthority ===== -->
                            <xsl:variable name="NAV_equipment_ORG_identifier" select="replace($NAV_equipment_authority/aixm:theOrganisationAuthority/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
                            <xsl:variable name="NAV_equipment_ORG_valid-ts" as="element()?" select="
                              if ($NAV_equipment_ORG_identifier != '')
                              then fcn:get-valid-timeslice(//aixm:OrganisationAuthority[gml:identifier = $NAV_equipment_ORG_identifier]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice[aixm:interpretation = 'BASELINE'])
                              else ()"/>
                            
                            <!-- NavaidEquipment/TheNavaidEquipment/Authority/Type -->
                            <xsl:variable name="NAV_equipment_ORG_type">
                              <xsl:choose>
                                <xsl:when test="not($NAV_equipment_authority/aixm:type)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:insert-value($NAV_equipment_authority/aixm:type)"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- NavaidEquipment/TheNavaidEquipment/Authority/Annotation -->
                            <xsl:variable name="NAV_equipment_ORG_annotation">
                              <xsl:choose>
                                <xsl:when test="not($NAV_equipment_authority/aixm:annotation)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:for-each select="$NAV_equipment_authority/aixm:annotation">
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
                            
                            <!-- NavaidEquipment/TheNavaidEquipment/Authority/TheOrganisationAuthority/Name -->
                            <xsl:variable name="NAV_equipment_ORG_name">
                              <xsl:choose>
                                <xsl:when test="not($NAV_equipment_ORG_valid-ts/aixm:name)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:insert-value($NAV_equipment_ORG_valid-ts/aixm:name)"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- ===== Navaid -> RunwayDirection ===== -->
                            <xsl:variable name="NAV_RDN_identifier" select="replace($NAV_RDN-reference/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
                            <xsl:variable name="NAV_RDN_valid-ts" as="element()?" select="
                              if ($NAV_RDN_identifier != '')
                              then fcn:get-valid-timeslice(//aixm:RunwayDirection[gml:identifier = $NAV_RDN_identifier]/aixm:timeSlice/aixm:RunwayDirectionTimeSlice[aixm:interpretation = 'BASELINE'])
                              else ()"/>
                            
                            <!-- RunwayDirection/Designator -->
                            <xsl:variable name="NAV_RDN_designator">
                              <xsl:choose>
                                <xsl:when test="not($NAV_RDN_valid-ts/aixm:designator)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:insert-value($NAV_RDN_valid-ts/aixm:designator)"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- ===== RunwayDirection -> Runway ===== -->
                            <xsl:variable name="NAV_RDN_RWY_identifier" select="replace($NAV_RDN_valid-ts/aixm:usedRunway/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
                            <xsl:variable name="NAV_RDN_RWY_valid-ts" as="element()?" select="
                              if ($NAV_RDN_RWY_identifier != '')
                              then fcn:get-valid-timeslice(//aixm:Runway[gml:identifier = $NAV_RDN_RWY_identifier]/aixm:timeSlice/aixm:RunwayTimeSlice[aixm:interpretation = 'BASELINE'])
                              else ()"/>
                            
                            <!-- RunwayDirection/UsedRunway/Designator -->
                            <xsl:variable name="NAV_RDN_RWY_designator">
                              <xsl:choose>
                                <xsl:when test="not($NAV_RDN_RWY_valid-ts/aixm:designator)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:insert-value($NAV_RDN_RWY_valid-ts/aixm:designator)"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- ===== Runway -> AirportHeliport ===== -->
                            <xsl:variable name="NAV_RDN_RWY_AHP_identifier" select="replace($NAV_RDN_RWY_valid-ts/aixm:associatedAirportHeliport/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
                            <xsl:variable name="NAV_RDN_RWY_AHP_valid-ts" as="element()?" select="
                              if ($NAV_RDN_RWY_AHP_identifier != '')
                              then fcn:get-valid-timeslice(//aixm:AirportHeliport[gml:identifier = $NAV_RDN_RWY_AHP_identifier]/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE'])
                              else ()"/>
                            
                            <!-- RunwayDirection/UsedRunway/AssociatedAirportHeliport/Designator -->
                            <xsl:variable name="NAV_RDN_RWY_AHP_designator">
                              <xsl:choose>
                                <xsl:when test="not($NAV_RDN_RWY_AHP_valid-ts/aixm:designator)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:insert-value($NAV_RDN_RWY_AHP_valid-ts/aixm:designator)"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- RunwayDirection/UsedRunway/AssociatedAirportHeliport/Name -->
                            <xsl:variable name="NAV_RDN_RWY_AHP_name">
                              <xsl:choose>
                                <xsl:when test="not($NAV_RDN_RWY_AHP_valid-ts/aixm:name)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:insert-value($NAV_RDN_RWY_AHP_valid-ts/aixm:name)"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- ===== Navaid -> AirportHeliport ===== -->
                            <xsl:variable name="NAV_served-airport_identifier" select="replace($NAV_served-airport-reference/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
                            <xsl:variable name="NAV_served-airport_AHP_valid-ts" as="element()?" select="
                              if ($NAV_served-airport_identifier != '')
                              then fcn:get-valid-timeslice(//aixm:AirportHeliport[gml:identifier = $NAV_served-airport_identifier]/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE'])
                              else ()"/>
                            
                            <!-- ServedAirport/Name -->
                            <xsl:variable name="NAV_served-airport_name">
                              <xsl:choose>
                                <xsl:when test="not($NAV_served-airport_AHP_valid-ts/aixm:name)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:insert-value($NAV_served-airport_AHP_valid-ts/aixm:name)"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- ServedAirport/Designator -->
                            <xsl:variable name="NAV_served-airport_designator">
                              <xsl:choose>
                                <xsl:when test="not($NAV_served-airport_AHP_valid-ts/aixm:designator)">
                                  <xsl:value-of select="''"/>
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="fcn:insert-value($NAV_served-airport_AHP_valid-ts/aixm:designator)"/>
                                </xsl:otherwise>
                              </xsl:choose>
                            </xsl:variable>
                            
                            <!-- Annotation -->
                            <xsl:variable name="NAV_annotation">
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
                            <xsl:variable name="EAD-Audit" select="aixm:extension/ead-audit:NavaidExtension/ead-audit:auditInformation/ead-audit:Audit"/>
                            
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
                              <td><xsl:value-of select="if (string-length($NAV_identifier) gt 0) then $NAV_identifier else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_lifetime-begin) gt 0) then $NAV_lifetime-begin else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_lifetime-end) gt 0) then $NAV_lifetime-end else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_validity-begin) gt 0) then $NAV_validity-begin else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_validity-end) gt 0) then $NAV_validity-end else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_sequence-number) gt 0) then $NAV_sequence-number else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_correction-number) gt 0) then $NAV_correction-number else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_type) gt 0) then $NAV_type else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_designator) gt 0) then $NAV_designator else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_name) gt 0) then $NAV_name else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_flight-checked) gt 0) then $NAV_flight-checked else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_purpose) gt 0) then $NAV_purpose else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_signal-performance) gt 0) then $NAV_signal-performance else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_course-quality) gt 0) then $NAV_course-quality else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_integrity-level) gt 0) then $NAV_integrity-level else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_equipment_identifier) gt 0) then $NAV_equipment_identifier else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_equipment_designator) gt 0) then $NAV_equipment_designator else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_equipment_name) gt 0) then $NAV_equipment_name else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_equipment_emission-class) gt 0) then $NAV_equipment_emission-class else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_equipment_mobile) gt 0) then $NAV_equipment_mobile else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_equipment_magnetic-variation) gt 0) then $NAV_equipment_magnetic-variation else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_equipment_magnetic-variation-accuracy) gt 0) then $NAV_equipment_magnetic-variation-accuracy else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_equipment_date-magnetic-variation) gt 0) then $NAV_equipment_date-magnetic-variation else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_equipment_flight-checked) gt 0) then $NAV_equipment_flight-checked else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_equipment_latitude) gt 0) then $NAV_equipment_latitude else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_equipment_longitude) gt 0) then $NAV_equipment_longitude else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_equipment_datum) gt 0) then $NAV_equipment_datum else '&#160;'"/></td>
                              <td style="max-width:1000px;white-space:normal;overflow-wrap:break-word"><xsl:choose><xsl:when test="string-length($NAV_equipment_location-xml) gt 0"><xsl:value-of select="$NAV_equipment_location-xml" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
                              <td><xsl:value-of select="if (string-length($NAV_equipment_ORG_type) gt 0) then $NAV_equipment_ORG_type else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_equipment_ORG_annotation) gt 0) then $NAV_equipment_ORG_annotation else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_equipment_ORG_identifier) gt 0) then $NAV_equipment_ORG_identifier else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_equipment_ORG_name) gt 0) then $NAV_equipment_ORG_name else '&#160;'"/></td>
                              <td style="max-width:600px;white-space:normal;overflow-wrap:break-word"><xsl:choose><xsl:when test="string-length($NAV_equipment_annotation) gt 0"><xsl:value-of select="$NAV_equipment_annotation" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
                              <td><xsl:value-of select="if (string-length($NAV_location_latitude) gt 0) then $NAV_location_latitude else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_location_longitude) gt 0) then $NAV_location_longitude else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_location_datum) gt 0) then $NAV_location_datum else '&#160;'"/></td>
                              <td style="max-width:1000px;white-space:normal;overflow-wrap:break-word"><xsl:choose><xsl:when test="string-length($NAV_location_gml-xml) gt 0"><xsl:value-of select="$NAV_location_gml-xml" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
                              <td><xsl:value-of select="if (string-length($NAV_RDN_identifier) gt 0) then $NAV_RDN_identifier else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_RDN_designator) gt 0) then $NAV_RDN_designator else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_RDN_RWY_identifier) gt 0) then $NAV_RDN_RWY_identifier else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_RDN_RWY_designator) gt 0) then $NAV_RDN_RWY_designator else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_RDN_RWY_AHP_identifier) gt 0) then $NAV_RDN_RWY_AHP_identifier else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_RDN_RWY_AHP_designator) gt 0) then $NAV_RDN_RWY_AHP_designator else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_RDN_RWY_AHP_name) gt 0) then $NAV_RDN_RWY_AHP_name else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_served-airport_identifier) gt 0) then $NAV_served-airport_identifier else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_served-airport_name) gt 0) then $NAV_served-airport_name else '&#160;'"/></td>
                              <td><xsl:value-of select="if (string-length($NAV_served-airport_designator) gt 0) then $NAV_served-airport_designator else '&#160;'"/></td>
                              <td style="max-width:600px;white-space:normal;overflow-wrap:break-word"><xsl:choose><xsl:when test="string-length($NAV_annotation) gt 0"><xsl:value-of select="$NAV_annotation" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
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
              <td><font size="-1">EAD-AUDIT:CreatedByOrganisation (first), Type (second), Designator (third)</font></td>
            </tr>
            <tr>
              <td style="text-align:right"><font size="-1">Sorting order: </font></td>
              <td><font size="-1">EAD-AUDIT:CreatedByOrganisation (ascending), Type (ascending), Designator (ascending)</font></td>
            </tr>
          </table>
          
          <p>***&#160;END OF REPORT&#160;***</p>
          
        </div>
        
      </body>
      
    </html>
    
  </xsl:template>
  
</xsl:transform>