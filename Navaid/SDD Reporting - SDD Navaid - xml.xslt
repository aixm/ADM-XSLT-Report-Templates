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
  
  <xsl:output method="xml" indent="yes"/>
  
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
                      
                      <Record>
                        <FEA>
                          <IDENTIFIER><xsl:value-of select="$NAV_identifier"/></IDENTIFIER>
                          <LIFE>
                            <WEF><xsl:value-of select="$NAV_lifetime-begin"/></WEF>
                            <TIL><xsl:value-of select="$NAV_lifetime-end"/></TIL>
                          </LIFE>
                        </FEA>
                        <TS>
                          <VALID>
                            <WEF><xsl:value-of select="$NAV_validity-begin"/></WEF>
                            <TIL><xsl:value-of select="$NAV_validity-end"/></TIL>
                          </VALID>
                          <xsl:if test="string-length($NAV_sequence-number) gt 0 or string-length($NAV_correction-number) gt 0">
                            <NO>
                              <xsl:if test="string-length($NAV_sequence-number) gt 0">
                                <SEQ><xsl:value-of select="$NAV_sequence-number"/></SEQ>
                              </xsl:if>
                              <xsl:if test="string-length($NAV_correction-number) gt 0">
                                <CORR><xsl:value-of select="$NAV_correction-number"/></CORR>
                              </xsl:if>
                            </NO>
                          </xsl:if>
                        </TS>
                        <xsl:if test="string-length($NAV_type) gt 0">
                          <TYPE><xsl:value-of select="$NAV_type"/></TYPE>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_designator) gt 0">
                          <DESG><xsl:value-of select="$NAV_designator"/></DESG>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_name) gt 0">
                          <NAME><xsl:value-of select="$NAV_name"/></NAME>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_flight-checked) gt 0">
                          <FLT>
                            <CHECKED><xsl:value-of select="$NAV_flight-checked"/></CHECKED>
                          </FLT>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_purpose) gt 0">
                          <PURPOSE><xsl:value-of select="$NAV_purpose"/></PURPOSE>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_signal-performance) gt 0">
                          <SIGNAL>
                            <PERF><xsl:value-of select="$NAV_signal-performance"/></PERF>
                          </SIGNAL>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_course-quality) gt 0">
                          <CRS>
                            <QUALITY><xsl:value-of select="$NAV_course-quality"/></QUALITY>
                          </CRS>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_integrity-level) gt 0">
                          <INTEGRITY>
                            <LVL><xsl:value-of select="$NAV_integrity-level"/></LVL>
                          </INTEGRITY>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_identifier) gt 0">
                          <g18FEA>
                            <IDENTIFIER><xsl:value-of select="$NAV_equipment_identifier"/></IDENTIFIER>
                          </g18FEA>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_designator) gt 0">
                          <g21DESG><xsl:value-of select="$NAV_equipment_designator"/></g21DESG>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_name) gt 0">
                          <g22NAME><xsl:value-of select="$NAV_equipment_name"/></g22NAME>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_emission-class) gt 0">
                          <g23EMISSION>
                            <CLASS><xsl:value-of select="$NAV_equipment_emission-class"/></CLASS>
                          </g23EMISSION>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_mobile) gt 0">
                          <g24MOBILE><xsl:value-of select="$NAV_equipment_mobile"/></g24MOBILE>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_magnetic-variation) gt 0">
                          <g25MAG>
                            <VAR>
                              <ORIG><xsl:value-of select="$NAV_equipment_magnetic-variation"/></ORIG>
                            </VAR>
                          </g25MAG>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_magnetic-variation-accuracy) gt 0">
                          <g26MAG>
                            <VAR>
                              <ACC>
                                <ORIG><xsl:value-of select="$NAV_equipment_magnetic-variation-accuracy"/></ORIG>
                              </ACC>
                            </VAR>
                          </g26MAG>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_date-magnetic-variation) gt 0">
                          <g27DT>
                            <MAG>
                              <VAR><xsl:value-of select="$NAV_equipment_date-magnetic-variation"/></VAR>
                            </MAG>
                          </g27DT>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_flight-checked) gt 0">
                          <g28FLT>
                            <CHECKED><xsl:value-of select="$NAV_equipment_flight-checked"/></CHECKED>
                          </g28FLT>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_latitude) gt 0">
                          <g29SPVX>
                            <LAT>
                              <ORIG><xsl:value-of select="$NAV_equipment_latitude"/></ORIG>
                            </LAT>
                          </g29SPVX>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_longitude) gt 0">
                          <g30SPVX>
                            <LONG>
                              <ORIG><xsl:value-of select="$NAV_equipment_longitude"/></ORIG>
                            </LONG>
                          </g30SPVX>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_datum) gt 0">
                          <g31PNT>
                            <SRS>
                              <NAME><xsl:value-of select="$NAV_equipment_datum"/></NAME>
                            </SRS>
                          </g31PNT>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_location-xml) gt 0">
                          <g32GML>
                            <XML><xsl:value-of select="$NAV_equipment_location-xml"/></XML>
                          </g32GML>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_ORG_type) gt 0">
                          <g33TYPE><xsl:value-of select="$NAV_equipment_ORG_type"/></g33TYPE>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_ORG_annotation) gt 0">
                          <g34annotation><xsl:value-of select="$NAV_equipment_ORG_annotation"/></g34annotation>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_ORG_identifier) gt 0">
                          <g35FEA>
                            <IDENTIFIER><xsl:value-of select="$NAV_equipment_ORG_identifier"/></IDENTIFIER>
                          </g35FEA>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_ORG_name) gt 0">
                          <g38NAME><xsl:value-of select="$NAV_equipment_ORG_name"/></g38NAME>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_equipment_annotation) gt 0">
                          <g39annotation><xsl:value-of select="$NAV_equipment_annotation"/></g39annotation>
                        </xsl:if>
                        <xsl:if test="aixm:location and (not(aixm:location/@xsi:nil) or aixm:location/@xsi:nil != 'true')">
                          <loc>
                            <SPVX>
                              <LAT>
                                <ORIG><xsl:value-of select="$NAV_location_latitude"/></ORIG>
                              </LAT>
                              <LONG>
                                <ORIG><xsl:value-of select="$NAV_location_longitude"/></ORIG>
                              </LONG>
                            </SPVX>
                            <PNT>
                              <SRS>
                                <NAME><xsl:value-of select="$NAV_location_datum"/></NAME>
                              </SRS>
                            </PNT>
                            <GML>
                              <XML><xsl:value-of select="$NAV_location_gml-xml"/></XML>
                            </GML>
                          </loc>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_RDN_identifier) gt 0">
                          <g89FEA>
                            <IDENTIFIER><xsl:value-of select="$NAV_RDN_identifier"/></IDENTIFIER>
                          </g89FEA>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_RDN_designator) gt 0">
                          <g92DESG><xsl:value-of select="$NAV_RDN_designator"/></g92DESG>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_RDN_RWY_identifier) gt 0">
                          <g93FEA>
                            <IDENTIFIER><xsl:value-of select="$NAV_RDN_RWY_identifier"/></IDENTIFIER>
                          </g93FEA>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_RDN_RWY_designator) gt 0">
                          <g96DESG><xsl:value-of select="$NAV_RDN_RWY_designator"/></g96DESG>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_RDN_RWY_AHP_identifier) gt 0">
                          <g97FEA>
                            <IDENTIFIER><xsl:value-of select="$NAV_RDN_RWY_AHP_identifier"/></IDENTIFIER>
                          </g97FEA>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_RDN_RWY_AHP_designator) gt 0">
                          <g100DESG><xsl:value-of select="$NAV_RDN_RWY_AHP_designator"/></g100DESG>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_RDN_RWY_AHP_name) gt 0">
                          <g101NAME><xsl:value-of select="$NAV_RDN_RWY_AHP_name"/></g101NAME>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_served-airport_identifier) gt 0">
                          <g102FEA>
                            <IDENTIFIER><xsl:value-of select="$NAV_served-airport_identifier"/></IDENTIFIER>
                          </g102FEA>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_served-airport_name) gt 0">
                          <g105NAME><xsl:value-of select="$NAV_served-airport_name"/></g105NAME>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_served-airport_designator) gt 0">
                          <g106DESG><xsl:value-of select="$NAV_served-airport_designator"/></g106DESG>
                        </xsl:if>
                        <xsl:if test="string-length($NAV_annotation) gt 0">
                          <annotation><xsl:value-of select="$NAV_annotation"/></annotation>
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
                </xsl:for-each>
              </xsl:for-each>
            </xsl:for-each>
            
          </xsl:for-each>
          
        </xsl:for-each>
        
      </SdoReportResult>
    </xsl:element>
    
  </xsl:template>
  
</xsl:transform>