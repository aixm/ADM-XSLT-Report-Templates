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
  featureTypes: aixm:SignificantPointInAirspace
  includeReferencedFeaturesLevel: 1
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
  
  <xsl:output method="xml" indent="yes"/>
  
  <xsl:strip-space elements="*"/>
  
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
  
  <!-- Pretty-print one XML node as plain text: two-space indentation, one line per element; namespace declarations and gml:id attributes are dropped -->
  <!-- Real characters are used throughout (real '&lt;', real newline, real spaces); the XML serializer escapes &lt; &gt; and &amp; once when the string is written out -->
  <xsl:function name="fcn:format-gml-node" as="xs:string">
    <xsl:param name="node" as="node()"/>
    <xsl:param name="depth" as="xs:integer"/>
    <xsl:variable name="indent" select="string-join(for $i in 1 to $depth return '  ', '')"/>
    <xsl:choose>
      <xsl:when test="$node instance of element()">
        <xsl:variable name="attrs" select="string-join(for $a in $node/@*[name(.) != 'gml:id'] return concat(' ', name($a), '=&quot;', string($a), '&quot;'), '')"/>
        <xsl:variable name="children" select="$node/node()[not(self::text()[normalize-space(.) = ''])]"/>
        <xsl:choose>
          <!-- empty element: self-closing tag -->
          <xsl:when test="empty($children)">
            <xsl:sequence select="concat($indent, '&lt;', name($node), $attrs, '/&gt;')"/>
          </xsl:when>
          <!-- text-only content stays on one line -->
          <xsl:when test="empty($children[not(self::text())])">
            <xsl:sequence select="concat($indent, '&lt;', name($node), $attrs, '&gt;', normalize-space(string($node)), '&lt;/', name($node), '&gt;')"/>
          </xsl:when>
          <!-- child elements each on their own indented line -->
          <xsl:otherwise>
            <xsl:sequence select="string-join((
              concat($indent, '&lt;', name($node), $attrs, '&gt;'),
              for $child in $children return fcn:format-gml-node($child, $depth + 1),
              concat($indent, '&lt;/', name($node), '&gt;')), '&#xA;')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$node instance of comment()">
        <xsl:sequence select="concat($indent, '&lt;!-- ', normalize-space($node), ' --&gt;')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="concat($indent, normalize-space($node))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- Format (beautify) embedded GML/XML content as indented plain text (written with a plain xsl:value-of) -->
  <xsl:function name="fcn:format-gml-xml" as="xs:string">
    <xsl:param name="nodes" as="node()*"/>
    <xsl:sequence select="string-join(for $n in $nodes[not(self::text()[normalize-space(.) = ''])] return fcn:format-gml-node($n, 0), '&#xA;')"/>
  </xsl:function>
  
  <xsl:template match="/">
    
    <xsl:element name="SdoReportResponse" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <xsl:attribute name="created" select="//aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
      <xsl:attribute name="xsi:noNamespaceSchemaLocation" select="'SdoReportMgmt.xsd'"/>
      <xsl:attribute name="origin" select="'SDD'"/>
      <xsl:attribute name="version" select="'4.1'"/>
      <SdoReportResult>
        
        <xsl:for-each select="//aixm:SignificantPointInAirspace">
          
          <!-- Sort the features by the Location/Designator (ascending) of the feature referenced by their valid BASELINE time slice -->
          <xsl:sort order="ascending" select="
            let $ts := fcn:get-valid-timeslice(aixm:timeSlice/aixm:SignificantPointInAirspaceTimeSlice[aixm:interpretation = 'BASELINE']),
            $location-uuid := replace(($ts/aixm:location_fixDesignatedPoint | $ts/aixm:location_navaidSystem | $ts/aixm:location_runwayPoint | $ts/aixm:location_aimingPoint | $ts/aixm:location_airportReferencePoint)/@xlink:href, '^(urn:uuid:|#uuid\.)', ''),
            $location-feature := ($doc-root//aixm:DesignatedPoint | $doc-root//aixm:Navaid | $doc-root//aixm:RunwayCentrelinePoint | $doc-root//aixm:TouchDownLiftOff | $doc-root//aixm:AirportHeliport)[gml:identifier = $location-uuid]
            return string(fcn:get-valid-timeslice($location-feature/aixm:timeSlice/*[aixm:interpretation = 'BASELINE'])/aixm:designator)"/>
          
          <!-- Get all BASELINE time slices for this feature -->
          <xsl:variable name="baseline-timeslice" select="aixm:timeSlice/aixm:SignificantPointInAirspaceTimeSlice[aixm:interpretation = 'BASELINE']"/>
          
          <xsl:for-each select="$baseline-timeslice">
            
            <!-- Sort the timeslices of this feature by sequenceNumber (descending), then by correctionNumber (descending) -->
            <xsl:sort select="aixm:sequenceNumber" data-type="number" order="descending"/>
            <xsl:sort select="aixm:correctionNumber" data-type="number" order="descending"/>
            
            <!-- FeatureIdentifier -->
            <xsl:variable name="SPN_identifier" select="../../gml:identifier"/>
            
            <!-- FeatureLifetimeBegin -->
            <xsl:variable name="SPN_lifetime-begin">
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
            <xsl:variable name="SPN_lifetime-end">
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
            <xsl:variable name="SPN_validity-begin">
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
            <xsl:variable name="SPN_validity-end">
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
            <xsl:variable name="SPN_sequence-number">
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
            <xsl:variable name="SPN_correction-number">
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
            <xsl:variable name="SPN_type">
              <xsl:choose>
                <xsl:when test="not(aixm:type)">
                  <xsl:value-of select="''"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="fcn:insert-value(aixm:type)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            
            <!-- RelativeLocation -->
            <xsl:variable name="SPN_relative-location">
              <xsl:choose>
                <xsl:when test="not(aixm:relativeLocation)">
                  <xsl:value-of select="''"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="fcn:insert-value(aixm:relativeLocation)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            
            <!-- ===== Airspace ===== -->
            <xsl:variable name="SPN_ASE_identifier" select="replace(aixm:containingAirspace/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
            <xsl:variable name="SPN_ASE_valid-ts" as="element()?" select="
              if ($SPN_ASE_identifier != '')
              then fcn:get-valid-timeslice($doc-root//aixm:Airspace[gml:identifier = $SPN_ASE_identifier]/aixm:timeSlice/aixm:AirspaceTimeSlice[aixm:interpretation = 'BASELINE'])
              else ()"/>
            
            <!-- ContainingAirspace/Designator -->
            <xsl:variable name="SPN_ASE_designator">
              <xsl:choose>
                <xsl:when test="not($SPN_ASE_valid-ts/aixm:designator)">
                  <xsl:value-of select="''"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="fcn:insert-value($SPN_ASE_valid-ts/aixm:designator)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            
            <!-- ContainingAirspace/Type -->
            <xsl:variable name="SPN_ASE_type">
              <xsl:choose>
                <xsl:when test="not($SPN_ASE_valid-ts/aixm:type)">
                  <xsl:value-of select="''"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="fcn:insert-value($SPN_ASE_valid-ts/aixm:type)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            
            <!-- ContainingAirspace/Name -->
            <xsl:variable name="SPN_ASE_name">
              <xsl:choose>
                <xsl:when test="not($SPN_ASE_valid-ts/aixm:name)">
                  <xsl:value-of select="''"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="fcn:insert-value($SPN_ASE_valid-ts/aixm:name)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            
            <!-- ===== Location ===== -->
            <xsl:variable name="SPN_location_property" select="aixm:location_fixDesignatedPoint | aixm:location_navaidSystem | aixm:location_position | aixm:location_runwayPoint | aixm:location_aimingPoint | aixm:location_airportReferencePoint"/>
            
            <!-- Location/featureIdentifier -->
            <xsl:variable name="SPN_location_identifier" select="replace($SPN_location_property/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
            
            <xsl:variable name="SPN_location_feature" as="element()?" select="
              if ($SPN_location_identifier != '')
              then ($doc-root//aixm:DesignatedPoint | $doc-root//aixm:Navaid | $doc-root//aixm:RunwayCentrelinePoint | $doc-root//aixm:TouchDownLiftOff | $doc-root//aixm:AirportHeliport)[gml:identifier = $SPN_location_identifier]
              else ()"/>
            
            <xsl:variable name="SPN_location_feature_valid-ts" as="element()?" select="
              if ($SPN_location_feature)
              then fcn:get-valid-timeslice($SPN_location_feature/aixm:timeSlice/*[aixm:interpretation = 'BASELINE'])
              else ()"/>
            
            <!-- Location/Designator -->
            <xsl:variable name="SPN_location_designator">
              <xsl:choose>
                <xsl:when test="not($SPN_location_feature_valid-ts/aixm:designator)">
                  <xsl:value-of select="''"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="fcn:insert-value($SPN_location_feature_valid-ts/aixm:designator)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            
            <!-- Location/Type -->
            <!-- Only Navaid, DesignatedPoint and AirportHeliport have aixm:type; for RunwayCentrelinePoint the equivalent is aixm:role, TouchDownLiftOff has neither -->
            <xsl:variable name="SPN_location_type">
              <xsl:choose>
                <xsl:when test="$SPN_location_feature_valid-ts/aixm:type">
                  <xsl:value-of select="fcn:insert-value($SPN_location_feature_valid-ts/aixm:type)"/>
                </xsl:when>
                <xsl:when test="$SPN_location_feature_valid-ts/aixm:role">
                  <xsl:value-of select="fcn:insert-value($SPN_location_feature_valid-ts/aixm:role)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="''"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            
            <!-- Location/Name -->
            <xsl:variable name="SPN_location_name">
              <xsl:choose>
                <xsl:when test="not($SPN_location_feature_valid-ts/aixm:name)">
                  <xsl:value-of select="''"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="fcn:insert-value($SPN_location_feature_valid-ts/aixm:name)"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            
            <!-- The property carrying the coordinates varies with the feature type: aixm:ARP (AirportHeliport), aixm:aimingPoint (TouchDownLiftOff), aixm:location (DesignatedPoint, Navaid, RunwayCentrelinePoint) -->
            <!-- With aixm:location_position the SignificantPointInAirspace has no referenced feature and carries the geometry itself -->
            <xsl:variable name="SPN_location_geometry" select="$SPN_location_feature_valid-ts/aixm:ARP | $SPN_location_feature_valid-ts/aixm:aimingPoint | $SPN_location_feature_valid-ts/aixm:location | aixm:location_position"/>
            <!-- DesignatedPoint and aixm:location_position carry an aixm:Point, all the other feature types an aixm:ElevatedPoint -->
            <xsl:variable name="SPN_location_point" select="$SPN_location_geometry/aixm:ElevatedPoint | $SPN_location_geometry/aixm:Point"/>
            
            <!-- Location/Datum -->
            <xsl:variable name="SPN_location_datum_raw">
              <xsl:value-of select="
                if ($SPN_location_point/gml:pos/@srsName) then $SPN_location_point/gml:pos/@srsName
                else if ($SPN_location_point/@srsName) then $SPN_location_point/@srsName
                else if ($SPN_location_geometry/ancestor::aixm:*/gml:boundedBy/gml:Envelope/@srsName) then $SPN_location_geometry/ancestor::aixm:*/gml:boundedBy/gml:Envelope/@srsName
                else if ($SPN_location_geometry/root()/*/gml:boundedBy/gml:Envelope/@srsName) then $SPN_location_geometry/root()/*/gml:boundedBy/gml:Envelope/@srsName
                else 'No srsName found!'"/>
            </xsl:variable>
            <xsl:variable name="SPN_location_datum">
              <xsl:value-of select="
                if ($SPN_location_datum_raw != 'No srsName found!') then replace(replace($SPN_location_datum_raw, 'urn:ogc:def:crs:', ''), '::', ':')
                else 'No srsName found!'"/>
            </xsl:variable>
            
            <!-- Location/Latitude -->
            <xsl:variable name="SPN_location_latitude">
              <xsl:choose>
                <xsl:when test="not($SPN_location_geometry)">
                  <xsl:value-of select="''"/>
                </xsl:when>
                <xsl:when test="$SPN_location_geometry/@xsi:nil = 'true'">
                  <xsl:value-of select="fcn:insert-value($SPN_location_geometry)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:variable name="coordinates" select="$SPN_location_point/gml:pos"/>
                  <xsl:choose>
                    <xsl:when test="$SPN_location_datum != 'OGC:1.3:CRS84'">
                      <xsl:value-of  select="number(substring-before($coordinates, ' '))"/>
                    </xsl:when>
                    <xsl:when test="$SPN_location_datum = 'OGC:1.3:CRS84'">
                      <xsl:value-of select="number(substring-after($coordinates, ' '))"/>
                    </xsl:when>
                  </xsl:choose>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            
            <!-- Location/Longitude -->
            <xsl:variable name="SPN_location_longitude">
              <xsl:choose>
                <xsl:when test="not($SPN_location_geometry)">
                  <xsl:value-of select="''"/>
                </xsl:when>
                <xsl:when test="$SPN_location_geometry/@xsi:nil = 'true'">
                  <xsl:value-of select="fcn:insert-value($SPN_location_geometry)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:variable name="coordinates" select="$SPN_location_point/gml:pos"/>
                  <xsl:choose>
                    <xsl:when test="$SPN_location_datum != 'OGC:1.3:CRS84'">
                      <xsl:value-of  select="number(substring-after($coordinates, ' '))"/>
                    </xsl:when>
                    <xsl:when test="$SPN_location_datum = 'OGC:1.3:CRS84'">
                      <xsl:value-of select="number(substring-before($coordinates, ' '))"/>
                    </xsl:when>
                  </xsl:choose>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            
            <!-- Location/GmlXml -->
            <xsl:variable name="SPN_location_gml-xml">
              <xsl:choose>
                <xsl:when test="not($SPN_location_geometry)">
                  <xsl:value-of select="''"/>
                </xsl:when>
                <xsl:when test="$SPN_location_geometry/@xsi:nil = 'true'">
                  <xsl:value-of select="fcn:insert-value($SPN_location_geometry)"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="fcn:format-gml-xml($SPN_location_geometry/node())"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            
            <!-- Location/Class -->
            <xsl:variable name="SPN_location_class">
              <xsl:value-of select="
                if (aixm:location_fixDesignatedPoint) then 'DesignatedPoint'
                else if (aixm:location_navaidSystem) then 'Navaid'
                else if (aixm:location_runwayPoint) then 'RunwayCentrelinePoint'
                else if (aixm:location_aimingPoint) then 'TouchDownLiftOff'
                else if (aixm:location_airportReferencePoint) then 'AirportHeliport'
                else if (aixm:location_position) then 'SignificantPointInAirspace'
                else ''"/>
            </xsl:variable>
            
            <!-- Annotation -->
            <xsl:variable name="SPN_annotation">
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
                          <xsl:value-of select="concat('[', $annotation-index, ']', '(', if (../../aixm:propertyName) then (concat(../../aixm:propertyName, ';')) else '', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', '): ', aixm:note)"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="concat('&#xA;', '[', $annotation-index, ']', '(', if (../../aixm:propertyName) then (concat(../../aixm:propertyName, ';')) else '', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', '): ', aixm:note)"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:for-each>
                  </xsl:for-each>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            
            <!-- EAD-Audit -->
            <xsl:variable name="EAD-Audit" select="aixm:extension/ead-audit:SignificantPointInAirspaceExtension/ead-audit:auditInformation/ead-audit:Audit"/>
            
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
            
            <Record>
              <FEA>
                <IDENTIFIER><xsl:value-of select="$SPN_identifier"/></IDENTIFIER>
                <LIFE>
                  <WEF><xsl:value-of select="$SPN_lifetime-begin"/></WEF>
                  <TIL><xsl:value-of select="$SPN_lifetime-end"/></TIL>
                </LIFE>
              </FEA>
              <TS>
                <VALID>
                  <WEF><xsl:value-of select="$SPN_validity-begin"/></WEF>
                  <TIL><xsl:value-of select="$SPN_validity-end"/></TIL>
                </VALID>
                <xsl:if test="string-length($SPN_sequence-number) gt 0 or string-length($SPN_correction-number) gt 0">
                  <NO>
                    <xsl:if test="string-length($SPN_sequence-number) gt 0">
                      <SEQ><xsl:value-of select="$SPN_sequence-number"/></SEQ>
                    </xsl:if>
                    <xsl:if test="string-length($SPN_correction-number) gt 0">
                      <CORR><xsl:value-of select="$SPN_correction-number"/></CORR>
                    </xsl:if>
                  </NO>
                </xsl:if>
              </TS>
              <xsl:if test="string-length($SPN_type) gt 0">
                <TYPE><xsl:value-of select="$SPN_type"/></TYPE>
              </xsl:if>
              <xsl:if test="string-length($SPN_relative-location) gt 0">
                <REL>
                  <LOC><xsl:value-of select="$SPN_relative-location"/></LOC>
                </REL>
              </xsl:if>
              <xsl:if test="string-length($SPN_ASE_identifier) gt 0">
                <g0FEA>
                  <IDENTIFIER><xsl:value-of select="$SPN_ASE_identifier"/></IDENTIFIER>
                </g0FEA>
                <containingairspace>
                  <xsl:if test="string-length($SPN_ASE_designator) gt 0">
                    <DESG><xsl:value-of select="$SPN_ASE_designator"/></DESG>
                  </xsl:if>
                  <xsl:if test="string-length($SPN_ASE_type) gt 0">
                    <TYPE><xsl:value-of select="$SPN_ASE_type"/></TYPE>
                  </xsl:if>
                  <xsl:if test="string-length($SPN_ASE_name) gt 0">
                    <NAME><xsl:value-of select="$SPN_ASE_name"/></NAME>
                  </xsl:if>
                </containingairspace>
              </xsl:if>
              <loc>
                <sigpnt>
                  <xsl:if test="string-length($SPN_location_identifier) gt 0">
                    <FEA>
                      <IDENTIFIER><xsl:value-of select="$SPN_location_identifier"/></IDENTIFIER>
                    </FEA>
                  </xsl:if>
                  <xsl:if test="string-length($SPN_location_designator) gt 0">
                    <DESG><xsl:value-of select="$SPN_location_designator"/></DESG>
                  </xsl:if>
                  <xsl:if test="string-length($SPN_location_type) gt 0">
                    <TYPE><xsl:value-of select="$SPN_location_type"/></TYPE>
                  </xsl:if>
                  <xsl:if test="string-length($SPN_location_name) gt 0">
                    <NAME><xsl:value-of select="$SPN_location_name"/></NAME>
                  </xsl:if>
                  <xsl:if test="not(empty($SPN_location_point)) or not(empty($SPN_location_geometry))">
                    <SPVX>
                      <LAT>
                        <ORIG><xsl:value-of select="$SPN_location_latitude"/></ORIG>
                      </LAT>
                      <LONG>
                        <ORIG><xsl:value-of select="$SPN_location_longitude"/></ORIG>
                      </LONG>
                    </SPVX>
                    <PNT>
                      <SRS>
                        <NAME><xsl:value-of select="$SPN_location_datum"/></NAME>
                      </SRS>
                    </PNT>
                    <GML>
                      <XML><xsl:value-of select="$SPN_location_gml-xml"/></XML>
                    </GML>
                  </xsl:if>
                  <CLASS><xsl:value-of select="$SPN_location_class"/></CLASS>
                </sigpnt>
              </loc>
              <xsl:if test="string-length($SPN_annotation) gt 0">
                <annotation><xsl:value-of select="$SPN_annotation"/></annotation>
              </xsl:if>
              <xsl:if test="not(empty($EAD-Audit))">
                <TC>
                  <xsl:if test="string-length($created-by) gt 0">
                    <USER>
                      <ID>
                        <CRE><xsl:value-of select="$created-by"/></CRE>
                      </ID>
                    </USER>
                  </xsl:if>
                  <xsl:if test="string-length($creation-date) gt 0">
                    <DT>
                      <CRE><xsl:value-of select="$creation-date"/></CRE>
                    </DT>
                  </xsl:if>
                  <xsl:if test="string-length($created-by-org) gt 0">
                    <ORG>
                      <NAME>
                        <CRE><xsl:value-of select="$created-by-org"/></CRE>
                      </NAME>
                    </ORG>
                  </xsl:if>
                  <xsl:if test="string-length($created-on-behalf-of-user) gt 0 or string-length($created-on-behalf-of-org) gt 0">
                    <BEHALF>
                      <xsl:if test="string-length($created-on-behalf-of-user)">
                        <USER>
                          <ID>
                            <CRE><xsl:value-of select="$created-on-behalf-of-user"/></CRE>
                          </ID>
                        </USER>
                      </xsl:if>
                      <xsl:if test="string-length($created-on-behalf-of-org)">
                        <ORG>
                          <NAME>
                            <CRE><xsl:value-of select="$created-on-behalf-of-org"/></CRE>
                          </NAME>
                        </ORG>
                      </xsl:if>
                    </BEHALF>
                  </xsl:if>
                  <xsl:if test="string-length($reason-for-change) gt 0">
                    <CHANGE>
                      <REASON><xsl:value-of select="$reason-for-change"/></REASON>
                    </CHANGE>
                  </xsl:if>
                  <xsl:if test="string-length($responsible-subsystem) gt 0">
                    <ORIGIN><xsl:value-of select="$responsible-subsystem"/></ORIGIN>
                  </xsl:if>
                </TC>
              </xsl:if>
            </Record>
            
          </xsl:for-each>
          
        </xsl:for-each>
        
      </SdoReportResult>
    </xsl:element>
    
  </xsl:template>
  
</xsl:transform>