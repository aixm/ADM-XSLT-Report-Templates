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
       featureTypes: aixm:DesignatedPoint
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
  
  <xsl:output method="xml" indent="yes"/>
  
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
  
  <xsl:template match="/">
    
    <xsl:element name="SdoReportResponse" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <xsl:attribute name="created" select="//aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
      <xsl:attribute name="xsi:noNamespaceSchemaLocation" select="'SdoReportMgmt.xsd'"/>
      <xsl:attribute name="origin" select="'SDO'"/>
      <xsl:attribute name="version" select="'4.1'"/>
      <SdoReportResult>
        
        <xsl:for-each select="//aixm:DesignatedPoint">
          
          <xsl:sort select="(aixm:timeSlice/aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)][aixm:correctionNumber = max(../aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)]/aixm:correctionNumber)])[1]/aixm:designator" order="ascending"/>
          
          <!-- Get all BASELINE time slices for this feature -->
          <xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE']"/>
          <!-- Select the latest time slice -->
          <xsl:variable name="latest-timeslice" select="fcn:get-valid-timeslice($baseline-timeslices)"/>
          
          <xsl:for-each select="$latest-timeslice">
            
            <Record>
              
              <!-- Designator -->
              <xsl:choose>
                <xsl:when test="not(aixm:designator)">
                  <codeId><xsl:value-of select="''"/></codeId>
                </xsl:when>
                <xsl:otherwise>
                  <codeId><xsl:value-of select="fcn:insert-value(aixm:designator)"/></codeId>
                </xsl:otherwise>
              </xsl:choose>
              
              <!-- Coordinates -->
              
              <!-- Select the type of coordinates: 'DMS' or 'DEC' -->
              <xsl:variable name="coordinates_type" select="'DMS'"/>
              
              <!-- Select the number of decimals -->
              <xsl:variable name="coordinates_decimal_number" select="2"/>
              
              <!-- Datum -->
              <xsl:variable name="DPN_datum" select="replace(replace(aixm:location/aixm:Point/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
              
              <xsl:variable name="lat-long-datums" select="
                ('EPSG:4326','EPSG:4258','EPSG:4322','EPSG:4230',
                'EPSG:4668','EPSG:4312','EPSG:4215','EPSG:4801',
                'EPSG:4149','EPSG:4326','EPSG:4275','EPSG:4746',
                'EPSG:4121','EPSG:4658','EPSG:4299','EPSG:4806',
                'EPSG:4277','EPSG:4207','EPSG:4274','EPSG:4740',
                'EPSG:4313','EPSG:4124','EPSG:4267','EPSG:4269')"/>
              
              <!-- Extract coordinates depending on the coordinate system -->
              <xsl:variable name="coordinates" select="aixm:location/aixm:Point/gml:pos"/>
              <xsl:variable name="latitude_decimal">
                <xsl:choose>
                  <xsl:when test="$DPN_datum = $lat-long-datums">
                    <xsl:value-of  select="number(substring-before($coordinates, ' '))"/>
                  </xsl:when>
                  <xsl:when test="matches($DPN_datum, '^OGC:.*CRS84$')">
                    <xsl:value-of select="number(substring-after($coordinates, ' '))"/>
                  </xsl:when>
                </xsl:choose>
              </xsl:variable>
              <xsl:variable name="longitude_decimal">
                <xsl:choose>
                  <xsl:when test="$DPN_datum = $lat-long-datums">
                    <xsl:value-of  select="number(substring-after($coordinates, ' '))"/>
                  </xsl:when>
                  <xsl:when test="matches($DPN_datum, '^OGC:.*CRS84$')">
                    <xsl:value-of select="number(substring-before($coordinates, ' '))"/>
                  </xsl:when>
                </xsl:choose>
              </xsl:variable>
              <xsl:if test="string-length($latitude_decimal) gt 0">
                <geoLat><xsl:value-of select="fcn:format-latitude($latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/></geoLat>
              </xsl:if>
              <xsl:if test="string-length($longitude_decimal) gt 0">
                <geoLong><xsl:value-of select="fcn:format-longitude($longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/></geoLong>
              </xsl:if>
              
              <!-- Type -->
              <xsl:choose>
                <xsl:when test="not(aixm:type)">
                  <codeType><xsl:value-of select="''"/></codeType>
                </xsl:when>
                <xsl:otherwise>
                  <codeType><xsl:value-of select="fcn:insert-value(aixm:type)"/></codeType>
                </xsl:otherwise>
              </xsl:choose>
              
              <!-- Originator -->
              <OrgCre>
                <txtName><xsl:value-of select="aixm:extension/ead-audit:DesignatedPointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/></txtName>
              </OrgCre>
              
              <!-- UUID -->
              <xsl:variable name="DPN_uuid" select="../../gml:identifier"/>
              
              <!-- Valid TimeSlice -->
              <xsl:variable name="DPN_timeslice" select="fcn:format-timeslice-info(.)"/>
              
              <txtRmk><xsl:value-of select="concat('UUID: ', $DPN_uuid)"/><xsl:text>&#xa;</xsl:text><xsl:value-of select="concat('Valid TimeSlice: ', $DPN_timeslice)"/></txtRmk>
              
            </Record>
            
          </xsl:for-each>
          
        </xsl:for-each>
        
      </SdoReportResult>
    </xsl:element>
    
  </xsl:template>
  
</xsl:transform>