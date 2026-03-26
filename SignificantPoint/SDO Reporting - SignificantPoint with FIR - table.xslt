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
                    featureTypes: aixm:DesignatedPoint aixm:Navaid
                                  aixm:AngleIndication aixm:DistanceIndication aixm:HoldingPattern aixm:HoldingAssessment aixm:AerialRefuelling aixm:ChangeOverPoint aixm:SignificantPointInAirspace aixm:TerminalArrivalArea aixm:SafeAltitudeArea aixm:NavigationArea aixm:RouteSegment
                                  aixm:Airspace
  includeReferencedFeaturesLevel: 1
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
  xmlns:ead-audit="http://www.aixm.aero/schema/5.1.1/extensions/EUR/iNM/EAD-Audit"
  xmlns:fcn="local-function"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  exclude-result-prefixes="xsl uuid message gts gco xsd gml gss gsr gmd aixm event xlink xs xsi aixm_ds_xslt ead-audit fcn math map">
  
  <xsl:output method="html" indent="yes"/>
  
  <xsl:strip-space elements="*"/>
  
  <xsl:key name="AirportHeliport-by-uuid" match="aixm:AirportHeliport" use="gml:identifier"/>
  
  <xsl:variable name="lat-long-datums" select="
    ('EPSG:4326','EPSG:4258','EPSG:4322','EPSG:4230',
    'EPSG:4668','EPSG:4312','EPSG:4215','EPSG:4801',
    'EPSG:4149','EPSG:4326','EPSG:4275','EPSG:4746',
    'EPSG:4121','EPSG:4658','EPSG:4299','EPSG:4806',
    'EPSG:4277','EPSG:4207','EPSG:4274','EPSG:4740',
    'EPSG:4313','EPSG:4124','EPSG:4267','EPSG:4269')"/>
  
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
    <xsl:param name="input" as="xs:string"/>
    <xsl:variable name="date-time" select="$input"/>
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
  
  <!-- Geodesic interpolation helper functions -->
  <!-- Haversine formula to calculate great circle distance between two points (in degrees) -->
  <xsl:function name="fcn:haversine-distance" as="xs:double">
    <xsl:param name="lat1" as="xs:double"/>
    <xsl:param name="lon1" as="xs:double"/>
    <xsl:param name="lat2" as="xs:double"/>
    <xsl:param name="lon2" as="xs:double"/>
    <xsl:variable name="pi" select="math:pi()"/>
    <xsl:variable name="lat1-rad" select="$lat1 * $pi div 180"/>
    <xsl:variable name="lat2-rad" select="$lat2 * $pi div 180"/>
    <xsl:variable name="dLat" select="($lat2 - $lat1) * $pi div 180"/>
    <xsl:variable name="dLon" select="($lon2 - $lon1) * $pi div 180"/>
    <xsl:variable name="a" select="math:sin($dLat div 2) * math:sin($dLat div 2) +
                                    math:cos($lat1-rad) * math:cos($lat2-rad) *
                                    math:sin($dLon div 2) * math:sin($dLon div 2)"/>
    <xsl:variable name="c" select="2 * math:atan2(math:sqrt($a), math:sqrt(1 - $a))"/>
    <!-- Return angular distance in degrees -->
    <xsl:sequence select="$c * 180 div $pi"/>
  </xsl:function>
  <!-- Interpolate a point along a geodesic between two points -->
  <xsl:function name="fcn:geodesic-interpolate" as="xs:double*">
    <xsl:param name="lat1" as="xs:double"/>
    <xsl:param name="lon1" as="xs:double"/>
    <xsl:param name="lat2" as="xs:double"/>
    <xsl:param name="lon2" as="xs:double"/>
    <xsl:param name="fraction" as="xs:double"/>
    <xsl:variable name="pi" select="math:pi()"/>
    <xsl:variable name="lat1-rad" select="$lat1 * $pi div 180"/>
    <xsl:variable name="lon1-rad" select="$lon1 * $pi div 180"/>
    <xsl:variable name="lat2-rad" select="$lat2 * $pi div 180"/>
    <xsl:variable name="lon2-rad" select="$lon2 * $pi div 180"/>
    <!-- Calculate angular distance -->
    <xsl:variable name="d" select="fcn:haversine-distance($lat1, $lon1, $lat2, $lon2) * $pi div 180"/>
    <!-- Handle very short distances (use linear interpolation) -->
    <xsl:choose>
      <xsl:when test="$d lt 0.00001">
        <xsl:sequence select="$lat1 + $fraction * ($lat2 - $lat1)"/>
        <xsl:sequence select="$lon1 + $fraction * ($lon2 - $lon1)"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- Spherical interpolation (slerp) -->
        <xsl:variable name="a" select="math:sin((1 - $fraction) * $d) div math:sin($d)"/>
        <xsl:variable name="b" select="math:sin($fraction * $d) div math:sin($d)"/>
        <xsl:variable name="x" select="$a * math:cos($lat1-rad) * math:cos($lon1-rad) +
                                       $b * math:cos($lat2-rad) * math:cos($lon2-rad)"/>
        <xsl:variable name="y" select="$a * math:cos($lat1-rad) * math:sin($lon1-rad) +
                                       $b * math:cos($lat2-rad) * math:sin($lon2-rad)"/>
        <xsl:variable name="z" select="$a * math:sin($lat1-rad) + $b * math:sin($lat2-rad)"/>
        <xsl:variable name="lat-result" select="math:atan2($z, math:sqrt($x * $x + $y * $y)) * 180 div $pi"/>
        <xsl:variable name="lon-result" select="math:atan2($y, $x) * 180 div $pi"/>
        <xsl:sequence select="$lat-result"/>
        <xsl:sequence select="$lon-result"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Densify a geodesic segment by adding intermediate points -->
  <xsl:function name="fcn:densify-geodesic-segment" as="xs:double*">
    <xsl:param name="lat1" as="xs:double"/>
    <xsl:param name="lon1" as="xs:double"/>
    <xsl:param name="lat2" as="xs:double"/>
    <xsl:param name="lon2" as="xs:double"/>
    <xsl:param name="max-segment-degrees" as="xs:double"/>
    <xsl:variable name="distance" select="fcn:haversine-distance($lat1, $lon1, $lat2, $lon2)"/>
    <xsl:variable name="num-segments" select="xs:integer(ceiling($distance div $max-segment-degrees))"/>
    <xsl:choose>
      <xsl:when test="$num-segments le 1">
        <!-- No interpolation needed -->
        <xsl:sequence select="$lat1, $lon1"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- Add first point -->
        <xsl:sequence select="$lat1, $lon1"/>
        <!-- Add intermediate points -->
        <xsl:for-each select="1 to ($num-segments - 1)">
          <xsl:variable name="fraction" select=". div $num-segments"/>
          <xsl:sequence select="fcn:geodesic-interpolate($lat1, $lon1, $lat2, $lon2, $fraction)"/>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Densify a linear segment by adding intermediate points using linear interpolation -->
  <!-- Handles antimeridian-crossing edges: normalizes longitude difference to [-180,180] before interpolating -->
  <xsl:function name="fcn:densify-linear-segment" as="xs:double*">
    <xsl:param name="lat1" as="xs:double"/>
    <xsl:param name="lon1" as="xs:double"/>
    <xsl:param name="lat2" as="xs:double"/>
    <xsl:param name="lon2" as="xs:double"/>
    <xsl:param name="max-segment-degrees" as="xs:double"/>
    <!-- Normalize longitude difference to [-180, 180] so interpolation takes the short path -->
    <xsl:variable name="raw-dlon" select="$lon2 - $lon1"/>
    <xsl:variable name="dlon" select="if ($raw-dlon gt 180) then $raw-dlon - 360
      else if ($raw-dlon lt -180) then $raw-dlon + 360
      else $raw-dlon"/>
    <xsl:variable name="dlat" select="abs($lat2 - $lat1)"/>
    <xsl:variable name="abs-dlon" select="abs($dlon)"/>
    <xsl:variable name="distance" select="math:sqrt($dlat * $dlat + $abs-dlon * $abs-dlon)"/>
    <xsl:variable name="num-segments" select="xs:integer(ceiling($distance div $max-segment-degrees))"/>
    <xsl:choose>
      <xsl:when test="$num-segments le 1">
        <!-- No interpolation needed -->
        <xsl:sequence select="$lat1, $lon1"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- Add first point -->
        <xsl:sequence select="$lat1, $lon1"/>
        <!-- Add intermediate points, interpolating along the short path -->
        <xsl:for-each select="1 to ($num-segments - 1)">
          <xsl:variable name="fraction" select=". div $num-segments"/>
          <xsl:variable name="interp-lon" select="$lon1 + $fraction * $dlon"/>
          <!-- Normalize interpolated longitude back to [-180, 180] -->
          <xsl:variable name="norm-lon" select="if ($interp-lon gt 180) then $interp-lon - 360
            else if ($interp-lon lt -180) then $interp-lon + 360
            else $interp-lon"/>
          <xsl:sequence select="$lat1 + $fraction * ($lat2 - $lat1)"/>
          <xsl:sequence select="$norm-lon"/>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Find exact matching point in coords, return 1-based index or empty if not found -->
  <xsl:function name="fcn:find-exact-point-index" as="xs:integer?">
    <xsl:param name="target-lat" as="xs:double"/>
    <xsl:param name="target-lon" as="xs:double"/>
    <xsl:param name="coords" as="xs:double*"/>
    <xsl:param name="epsilon" as="xs:double"/>
    <xsl:variable name="num-points" select="count($coords) div 2"/>
    <xsl:variable name="matching-indices" as="xs:integer*">
      <xsl:for-each select="1 to xs:integer($num-points)">
        <xsl:variable name="idx" select=". * 2 - 1"/>
        <xsl:variable name="lat" select="$coords[$idx]"/>
        <xsl:variable name="lon" select="$coords[$idx + 1]"/>
        <xsl:if test="exists($lat) and exists($lon)">
          <xsl:variable name="lat-diff" select="abs($lat - $target-lat)"/>
          <xsl:variable name="lon-diff" select="abs($lon - $target-lon)"/>
          <xsl:if test="$lat-diff le $epsilon and $lon-diff le $epsilon">
            <xsl:sequence select="xs:integer(.)"/>
          </xsl:if>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <xsl:sequence select="if (count($matching-indices) gt 0) then $matching-indices[1] else ()"/>
  </xsl:function>

  <!-- Extract segment from coords between two point indices (inclusive) -->
  <xsl:function name="fcn:extract-segment" as="xs:double*">
    <xsl:param name="coords" as="xs:double*"/>
    <xsl:param name="start-index" as="xs:integer"/>
    <xsl:param name="end-index" as="xs:integer"/>
    <xsl:param name="reverse" as="xs:boolean"/>
    <xsl:choose>
      <xsl:when test="$reverse">
        <!-- Extract in reverse order from start-index down to end-index -->
        <xsl:for-each select="reverse($start-index to $end-index)">
          <xsl:variable name="idx" select=". * 2 - 1"/>
          <xsl:sequence select="$coords[$idx], $coords[$idx + 1]"/>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <!-- Extract forward from start-index to end-index -->
        <xsl:for-each select="$start-index to $end-index">
          <xsl:variable name="idx" select=". * 2 - 1"/>
          <xsl:sequence select="$coords[$idx], $coords[$idx + 1]"/>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Helper function to merge coordinates with global deduplication -->
  <xsl:function name="fcn:merge-coords-deduplicated" as="xs:double*">
    <xsl:param name="accumulated" as="xs:double*"/>
    <xsl:param name="new-coords" as="xs:double*"/>
    <xsl:param name="epsilon" as="xs:double"/>
    <xsl:choose>
      <!-- If accumulated is empty, just return new coords -->
      <xsl:when test="count($accumulated) = 0">
        <xsl:sequence select="$new-coords"/>
      </xsl:when>
      <!-- If new coords is empty, just return accumulated -->
      <xsl:when test="count($new-coords) = 0">
        <xsl:sequence select="$accumulated"/>
      </xsl:when>
      <!-- Check if first point of new-coords matches last point of accumulated -->
      <xsl:otherwise>
        <xsl:variable name="last-lat" select="$accumulated[count($accumulated) - 1]"/>
        <xsl:variable name="last-lon" select="$accumulated[count($accumulated)]"/>
        <xsl:variable name="first-lat" select="$new-coords[1]"/>
        <xsl:variable name="first-lon" select="$new-coords[2]"/>
        <xsl:variable name="lat-diff" select="abs($last-lat - $first-lat)"/>
        <xsl:variable name="lon-diff" select="abs($last-lon - $first-lon)"/>
        <xsl:choose>
          <!-- If they match within epsilon, skip the first point of new-coords -->
          <xsl:when test="$lat-diff le $epsilon and $lon-diff le $epsilon">
            <xsl:sequence select="$accumulated, subsequence($new-coords, 3)"/>
          </xsl:when>
          <!-- Otherwise, concatenate all -->
          <xsl:otherwise>
            <xsl:sequence select="$accumulated, $new-coords"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Function to extract all polygon coordinates from a geometry including referenced GeoBorders -->
  <xsl:function name="fcn:get-all-polygon-coords" as="xs:double*">
    <xsl:param name="airspace-volume" as="element()?"/>
    <xsl:param name="root" as="document-node()"/>
    <xsl:variable name="epsilon" select="0.01" as="xs:double"/>
    <xsl:variable name="max-segment-degrees" select="1.0" as="xs:double"/>
    <xsl:variable name="all-curve-members" select="$airspace-volume//gml:Ring/gml:curveMember"/>
    <!-- Process curveMember elements sequentially to handle GeoBorder extraction -->
    <xsl:call-template name="process-curve-members-seq">
      <xsl:with-param name="curve-members" select="$all-curve-members"/>
      <xsl:with-param name="position" select="1"/>
      <xsl:with-param name="root" select="$root"/>
      <xsl:with-param name="epsilon" select="$epsilon"/>
      <xsl:with-param name="max-segment-degrees" select="$max-segment-degrees"/>
      <xsl:with-param name="accumulated" select="()"/>
    </xsl:call-template>
  </xsl:function>

  <!-- Recursively process curveMember elements -->
  <xsl:template name="process-curve-members-seq">
    <xsl:param name="curve-members" as="element()*"/>
    <xsl:param name="position" as="xs:integer"/>
    <xsl:param name="root" as="document-node()"/>
    <xsl:param name="epsilon" as="xs:double"/>
    <xsl:param name="max-segment-degrees" as="xs:double"/>
    <xsl:param name="accumulated" as="xs:double*"/>
    <xsl:choose>
      <xsl:when test="$position gt count($curve-members)">
        <xsl:sequence select="$accumulated"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="current" select="$curve-members[$position]"/>
        <xsl:variable name="prev" select="$curve-members[$position - 1]"/>
        <xsl:variable name="next" select="$curve-members[$position + 1]"/>
        <xsl:variable name="new-coords" as="xs:double*">
          <xsl:choose>
            <!-- GeoBorder reference -->
            <xsl:when test="$current/@xlink:href and starts-with($current/@xlink:href, 'urn:uuid:')">
              <xsl:variable name="uuid" select="substring-after($current/@xlink:href, 'urn:uuid:')"/>
              <xsl:variable name="geoborder" select="$root//aixm:GeoBorder[gml:identifier = $uuid]"/>
              <xsl:variable name="gb-baseline-ts" select="$geoborder/aixm:timeSlice/aixm:GeoBorderTimeSlice[aixm:interpretation = 'BASELINE']"/>
              <!-- Select latest valid timeslice: by date, then sequence, then correction -->
              <xsl:variable name="gb-sorted" as="element()*">
                <xsl:for-each select="$gb-baseline-ts">
                  <xsl:sort select="gml:validTime/gml:TimePeriod/gml:beginPosition" order="descending"/>
                  <xsl:sort select="aixm:sequenceNumber" data-type="number" order="descending"/>
                  <xsl:sort select="aixm:correctionNumber" data-type="number" order="descending"/>
                  <xsl:sequence select="."/>
                </xsl:for-each>
              </xsl:variable>
              <xsl:variable name="gb-latest-ts" select="$gb-sorted[1]"/>
              <!-- Get ALL GeoBorder coordinates (flattened) -->
              <xsl:variable name="gb-all-coords" as="xs:double*">
                <xsl:for-each select="$gb-latest-ts/aixm:border//gml:segments/*">
                  <xsl:for-each select=".//gml:posList">
                    <xsl:sequence select="for $coord in tokenize(normalize-space(.), '\s+') return xs:double($coord)"/>
                  </xsl:for-each>
                  <xsl:for-each select=".//gml:pos">
                    <xsl:sequence select="for $coord in tokenize(normalize-space(.), '\s+') return xs:double($coord)"/>
                  </xsl:for-each>
                </xsl:for-each>
              </xsl:variable>
              <!-- Extract relevant portion -->
              <xsl:call-template name="extract-geoborder-portion">
                <xsl:with-param name="gb-coords" select="$gb-all-coords"/>
                <xsl:with-param name="prev-member" select="$prev"/>
                <xsl:with-param name="next-member" select="$next"/>
                <xsl:with-param name="epsilon" select="$epsilon"/>
                <xsl:with-param name="max-segment-degrees" select="$max-segment-degrees"/>
                <xsl:with-param name="root" select="$root"/>
              </xsl:call-template>
            </xsl:when>
            <!-- Direct coordinates -->
            <xsl:otherwise>
              <xsl:for-each select="$current//gml:segments/*">
                <xsl:variable name="is-geodesic" select="local-name() = 'GeodesicString'"/>
                <xsl:variable name="segment-coords" as="xs:double*">
                  <xsl:for-each select=".//gml:posList">
                    <xsl:sequence select="for $coord in tokenize(normalize-space(.), '\s+') return xs:double($coord)"/>
                  </xsl:for-each>
                  <xsl:for-each select=".//gml:pos">
                    <xsl:sequence select="for $coord in tokenize(normalize-space(.), '\s+') return xs:double($coord)"/>
                  </xsl:for-each>
                </xsl:variable>
                <xsl:call-template name="densify-segment">
                  <xsl:with-param name="coords" select="$segment-coords"/>
                  <xsl:with-param name="is-geodesic" select="$is-geodesic"/>
                  <xsl:with-param name="max-segment-degrees" select="$max-segment-degrees"/>
                  <xsl:with-param name="epsilon" select="$epsilon"/>
                </xsl:call-template>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <!-- Merge new coordinates with global deduplication -->
        <xsl:variable name="merged-coords" select="fcn:merge-coords-deduplicated($accumulated, $new-coords, $epsilon)"/>
        <xsl:call-template name="process-curve-members-seq">
          <xsl:with-param name="curve-members" select="$curve-members"/>
          <xsl:with-param name="position" select="$position + 1"/>
          <xsl:with-param name="root" select="$root"/>
          <xsl:with-param name="epsilon" select="$epsilon"/>
          <xsl:with-param name="max-segment-degrees" select="$max-segment-degrees"/>
          <xsl:with-param name="accumulated" select="$merged-coords"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Extract the relevant portion of a GeoBorder based on surrounding coordinates -->
  <xsl:template name="extract-geoborder-portion">
    <xsl:param name="gb-coords" as="xs:double*"/>
    <xsl:param name="prev-member" as="element()?"/>
    <xsl:param name="next-member" as="element()?"/>
    <xsl:param name="epsilon" as="xs:double"/>
    <xsl:param name="max-segment-degrees" as="xs:double"/>
    <xsl:param name="root" as="document-node()"/>
    <!-- Get last coordinate from previous member -->
    <xsl:variable name="prev-coords" as="xs:double*">
      <xsl:if test="$prev-member and not($prev-member/@xlink:href)">
        <xsl:for-each select="$prev-member//gml:segments/*">
          <xsl:for-each select=".//gml:posList">
            <xsl:sequence select="for $c in tokenize(normalize-space(.), '\s+') return xs:double($c)"/>
          </xsl:for-each>
          <xsl:for-each select=".//gml:pos">
            <xsl:sequence select="for $c in tokenize(normalize-space(.), '\s+') return xs:double($c)"/>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:if>
    </xsl:variable>
    <!-- Get first coordinate from next member -->
    <xsl:variable name="next-coords" as="xs:double*">
      <xsl:if test="$next-member and not($next-member/@xlink:href)">
        <xsl:for-each select="$next-member//gml:segments/*">
          <xsl:for-each select=".//gml:posList">
            <xsl:sequence select="for $c in tokenize(normalize-space(.), '\s+') return xs:double($c)"/>
          </xsl:for-each>
          <xsl:for-each select=".//gml:pos">
            <xsl:sequence select="for $c in tokenize(normalize-space(.), '\s+') return xs:double($c)"/>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="start-lat" select="if (count($prev-coords) ge 2) then $prev-coords[count($prev-coords) - 1] else ()" as="xs:double?"/>
    <xsl:variable name="start-lon" select="if (count($prev-coords) ge 2) then $prev-coords[count($prev-coords)] else ()" as="xs:double?"/>
    <xsl:variable name="end-lat" select="if (count($next-coords) ge 2) then $next-coords[1] else ()" as="xs:double?"/>
    <xsl:variable name="end-lon" select="if (count($next-coords) ge 2) then $next-coords[2] else ()" as="xs:double?"/>
    <!-- Try to find coordinates with progressive epsilon increase -->
    <xsl:call-template name="find-with-progressive-epsilon">
      <xsl:with-param name="gb-coords" select="$gb-coords"/>
      <xsl:with-param name="start-lat" select="$start-lat"/>
      <xsl:with-param name="start-lon" select="$start-lon"/>
      <xsl:with-param name="end-lat" select="$end-lat"/>
      <xsl:with-param name="end-lon" select="$end-lon"/>
      <xsl:with-param name="epsilon" select="$epsilon"/>
      <xsl:with-param name="max-epsilon" select="1.0"/>
    </xsl:call-template>
  </xsl:template>

  <!-- Recursive template to find coordinates with progressively increasing epsilon -->
  <xsl:template name="find-with-progressive-epsilon">
    <xsl:param name="gb-coords" as="xs:double*"/>
    <xsl:param name="start-lat" as="xs:double?"/>
    <xsl:param name="start-lon" as="xs:double?"/>
    <xsl:param name="end-lat" as="xs:double?"/>
    <xsl:param name="end-lon" as="xs:double?"/>
    <xsl:param name="epsilon" as="xs:double"/>
    <xsl:param name="max-epsilon" as="xs:double"/>
    <!-- Find start and end in GeoBorder with current epsilon -->
    <xsl:variable name="start-idx" select="if (exists($start-lat)) then fcn:find-exact-point-index($start-lat, $start-lon, $gb-coords, $epsilon) else ()" as="xs:integer?"/>
    <xsl:variable name="end-idx" select="if (exists($end-lat)) then fcn:find-exact-point-index($end-lat, $end-lon, $gb-coords, $epsilon) else ()" as="xs:integer?"/>
    <xsl:choose>
      <!-- Both found: extract between them -->
      <xsl:when test="exists($start-idx) and exists($end-idx)">
        <xsl:choose>
          <xsl:when test="$start-idx lt $end-idx">
            <!-- Forward -->
            <xsl:sequence select="fcn:extract-segment($gb-coords, $start-idx, $end-idx, false())"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- Backward -->
            <xsl:sequence select="fcn:extract-segment($gb-coords, $end-idx, $start-idx, true())"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- Not found: try with increased epsilon -->
      <xsl:when test="$epsilon lt $max-epsilon">
        <xsl:call-template name="find-with-progressive-epsilon">
          <xsl:with-param name="gb-coords" select="$gb-coords"/>
          <xsl:with-param name="start-lat" select="$start-lat"/>
          <xsl:with-param name="start-lon" select="$start-lon"/>
          <xsl:with-param name="end-lat" select="$end-lat"/>
          <xsl:with-param name="end-lon" select="$end-lon"/>
          <xsl:with-param name="epsilon" select="$epsilon + 0.01"/>
          <xsl:with-param name="max-epsilon" select="$max-epsilon"/>
        </xsl:call-template>
      </xsl:when>
      <!-- Max epsilon reached: use all GeoBorder as last resort -->
      <xsl:otherwise>
        <xsl:sequence select="$gb-coords"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Template to densify a segment with deduplication and appropriate interpolation -->
  <xsl:template name="densify-segment">
    <xsl:param name="coords" as="xs:double*"/>
    <xsl:param name="is-geodesic" as="xs:boolean"/>
    <xsl:param name="max-segment-degrees" as="xs:double"/>
    <xsl:param name="epsilon" as="xs:double"/>
    <!-- First deduplicate consecutive points within this segment -->
    <xsl:variable name="deduplicated" as="xs:double*">
      <xsl:for-each select="1 to count($coords) div 2">
        <xsl:variable name="idx" select=". * 2 - 1"/>
        <xsl:variable name="lat" select="$coords[$idx]"/>
        <xsl:variable name="lon" select="$coords[$idx + 1]"/>
        <!-- Only include if different from previous point -->
        <xsl:if test=". = 1 or abs($lat - $coords[$idx - 2]) ge $epsilon or abs($lon - $coords[$idx - 1]) ge $epsilon">
          <xsl:sequence select="$lat, $lon"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <!-- Now densify with appropriate interpolation -->
    <xsl:for-each select="1 to (count($deduplicated) div 2)">
      <xsl:variable name="idx" select=". * 2 - 1"/>
      <xsl:variable name="lat1" select="$deduplicated[$idx]"/>
      <xsl:variable name="lon1" select="$deduplicated[$idx + 1]"/>
      <xsl:choose>
        <xsl:when test=". lt (count($deduplicated) div 2)">
          <!-- Not the last point - densify segment to next point -->
          <xsl:variable name="lat2" select="$deduplicated[$idx + 2]"/>
          <xsl:variable name="lon2" select="$deduplicated[$idx + 3]"/>
          <xsl:choose>
            <xsl:when test="$is-geodesic">
              <xsl:sequence select="fcn:densify-geodesic-segment($lat1, $lon1, $lat2, $lon2, $max-segment-degrees)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="fcn:densify-linear-segment($lat1, $lon1, $lat2, $lon2, $max-segment-degrees)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <!-- Last point - just add it -->
          <xsl:sequence select="$lat1, $lon1"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
  
  <!-- Resolve coordinates from a single AirspaceGeometryComponent (handles both direct geometry and contributorAirspace references) -->
  <!-- Returns a sequence of arrays, each containing a flat lat/lon coordinate sequence for one polygon -->
  <xsl:function name="fcn:resolve-component-coords" as="array(xs:double*)*">
    <xsl:param name="component" as="element()"/>
    <xsl:param name="root" as="document-node()"/>
    <xsl:variable name="airspace-volume" select="$component/aixm:theAirspaceVolume/aixm:AirspaceVolume"/>
    <xsl:choose>
      <!-- Direct geometry -->
      <xsl:when test="$airspace-volume/aixm:horizontalProjection">
        <xsl:variable name="coords" select="fcn:get-all-polygon-coords($airspace-volume/aixm:horizontalProjection, $root)"/>
        <xsl:if test="count($coords) ge 6">
          <xsl:sequence select="[$coords]"/>
        </xsl:if>
      </xsl:when>
      <!-- Reference to another airspace via contributorAirspace -->
      <xsl:when test="$airspace-volume/aixm:contributorAirspace">
        <xsl:for-each select="$airspace-volume/aixm:contributorAirspace/aixm:AirspaceVolumeDependency">
          <xsl:variable name="ref-uuid" select="substring-after(aixm:theAirspace/@xlink:href, 'urn:uuid:')"/>
          <xsl:variable name="ref-airspace" select="$root//aixm:Airspace[gml:identifier = $ref-uuid]"/>
          <xsl:variable name="ref-latest-ts" select="fcn:get-valid-timeslice($ref-airspace/aixm:timeSlice/aixm:AirspaceTimeSlice[aixm:interpretation = 'BASELINE'])"/>
          <xsl:if test="$ref-latest-ts">
            <xsl:variable name="ref-volume" select="$ref-latest-ts/aixm:geometryComponent/aixm:AirspaceGeometryComponent/aixm:theAirspaceVolume/aixm:AirspaceVolume"/>
            <xsl:variable name="ref-coords" select="fcn:get-all-polygon-coords($ref-volume/aixm:horizontalProjection, $root)"/>
            <xsl:if test="count($ref-coords) ge 6">
              <xsl:sequence select="[$ref-coords]"/>
            </xsl:if>
          </xsl:if>
        </xsl:for-each>
      </xsl:when>
    </xsl:choose>
  </xsl:function>

  <!-- Detect if a polygon (flat lat/lon array) crosses the antimeridian (any consecutive longitude jump > 180°) -->
  <xsl:function name="fcn:crosses-antimeridian" as="xs:boolean">
    <xsl:param name="polygon-coords" as="xs:double*"/>
    <xsl:variable name="num-points" select="xs:integer(count($polygon-coords) div 2)"/>
    <xsl:variable name="found-crossing" as="xs:boolean*">
      <xsl:for-each select="1 to ($num-points - 1)">
        <xsl:variable name="i" select="."/>
        <xsl:variable name="lon1" select="subsequence($polygon-coords, $i * 2, 1)"/>
        <xsl:variable name="lon2" select="subsequence($polygon-coords, ($i + 1) * 2, 1)"/>
        <xsl:sequence select="abs($lon2 - $lon1) gt 180"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:sequence select="some $c in $found-crossing satisfies $c"/>
  </xsl:function>

  <!-- Function to check if a point is inside a polygon using ray-casting algorithm -->
  <!-- Uses robust handling for edge cases near polygon boundaries -->
  <xsl:function name="fcn:point-in-polygon" as="xs:boolean">
    <xsl:param name="point-lat" as="xs:double"/>
    <xsl:param name="point-lon" as="xs:double"/>
    <xsl:param name="polygon-coords" as="xs:double*"/>
    <!-- Epsilon for floating-point comparison tolerance (approximately 0.1 meters at equator) -->
    <xsl:variable name="epsilon" select="0.000001" as="xs:double"/>
    <!-- Extract lat/lon pairs from the flat array -->
    <xsl:variable name="num-coords" select="count($polygon-coords)"/>
    <xsl:variable name="num-points" select="$num-coords div 2"/>
    <!-- Detect antimeridian crossing and normalize longitudes to 0-360 range if needed -->
    <xsl:variable name="crosses-am" select="fcn:crosses-antimeridian($polygon-coords)"/>
    <xsl:variable name="norm-coords" as="xs:double*">
      <xsl:choose>
        <xsl:when test="$crosses-am">
          <xsl:for-each select="1 to xs:integer($num-points)">
            <xsl:variable name="idx" select=". * 2 - 1"/>
            <xsl:sequence select="subsequence($polygon-coords, $idx, 1)"/>
            <xsl:variable name="lon" select="subsequence($polygon-coords, $idx + 1, 1)"/>
            <xsl:sequence select="if ($lon lt 0) then $lon + 360 else $lon"/>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$polygon-coords"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="norm-lon" select="if ($crosses-am and $point-lon lt 0) then $point-lon + 360 else $point-lon"/>
    <xsl:choose>
      <xsl:when test="$num-points lt 3">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- Check if polygon is closed (first point = last point) -->
        <xsl:variable name="is-closed" select="abs($norm-coords[1] - $norm-coords[$num-coords - 1]) lt $epsilon and abs($norm-coords[2] - $norm-coords[$num-coords]) lt $epsilon"/>
        <xsl:variable name="actual-num-points" select="if ($is-closed) then $num-points - 1 else $num-points"/>
        <!-- Ray-casting algorithm with improved edge case handling -->
        <xsl:variable name="intersections" as="xs:integer">
          <xsl:variable name="counts" as="xs:integer*">
            <xsl:for-each select="1 to xs:integer($actual-num-points)">
              <xsl:variable name="i" select="."/>
              <xsl:variable name="j" select="if ($i = $actual-num-points) then 1 else $i + 1"/>
              <xsl:variable name="lat-i" select="$norm-coords[($i - 1) * 2 + 1]"/>
              <xsl:variable name="lon-i" select="$norm-coords[($i - 1) * 2 + 2]"/>
              <xsl:variable name="lat-j" select="$norm-coords[($j - 1) * 2 + 1]"/>
              <xsl:variable name="lon-j" select="$norm-coords[($j - 1) * 2 + 2]"/>
              <!-- Standard ray-casting: check if horizontal ray from point intersects edge -->
              <!-- Edge must cross the latitude of the test point -->
              <xsl:variable name="lat-i-above" select="$lat-i gt $point-lat"/>
              <xsl:variable name="lat-j-above" select="$lat-j gt $point-lat"/>
              <xsl:choose>
                <xsl:when test="$lat-i-above != $lat-j-above">
                  <!-- Calculate longitude of intersection with horizontal ray -->
                  <xsl:variable name="intersect-lon" select="($lon-j - $lon-i) * ($point-lat - $lat-i) div ($lat-j - $lat-i) + $lon-i"/>
                  <!-- Count if intersection is to the right of test point (with epsilon tolerance) -->
                  <xsl:sequence select="if ($intersect-lon gt $norm-lon - $epsilon) then 1 else 0"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="0"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </xsl:variable>
          <xsl:sequence select="sum($counts)"/>
        </xsl:variable>
        <!-- Point is inside if number of intersections is odd -->
        <xsl:sequence select="$intersections mod 2 = 1"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- OPTIMIZATION: Pre-build all FIR geometries to avoid repeated construction -->
  <!-- Returns a map where keys are FIR/FIR_P UUIDs and values are maps containing geometry coords and metadata -->
  <xsl:function name="fcn:build-fir-geometry-cache" as="map(xs:string, map(*))">
    <xsl:param name="root" as="document-node()"/>
    <!-- Get all FIR and FIR_P Airspaces -->
    <xsl:variable name="fir-airspaces" select="$root//aixm:Airspace[aixm:timeSlice/aixm:AirspaceTimeSlice[aixm:type = ('FIR', 'FIR_P')]]"/>
    <!-- Build a map of all FIR geometries -->
    <xsl:variable name="geometry-entries" as="map(xs:string, map(*))*">
      <xsl:for-each select="$fir-airspaces">
        <xsl:variable name="airspace" select="."/>
        <xsl:variable name="uuid" select="string(gml:identifier)"/>
        <xsl:variable name="latest-ts" select="fcn:get-valid-timeslice($airspace/aixm:timeSlice/aixm:AirspaceTimeSlice[aixm:interpretation = 'BASELINE'])"/>
        <xsl:if test="$latest-ts">
          <xsl:variable name="airspace-type" select="string($latest-ts/aixm:type)"/>
          <xsl:variable name="designator" select="string($latest-ts/aixm:designator)"/>
          <xsl:variable name="seq-num" select="string($latest-ts/aixm:sequenceNumber)"/>
          <xsl:variable name="corr-num" select="string($latest-ts/aixm:correctionNumber)"/>
          <!-- Get geometry - handle both direct geometry and contributorAirspace references -->
          <!-- Also handle geometry operations: BASE, UNION, SUBTR, INTERS -->
          <xsl:variable name="geom-components" select="$latest-ts/aixm:geometryComponent/aixm:AirspaceGeometryComponent"/>
          <xsl:variable name="has-operations" select="exists($geom-components/aixm:operation)" as="xs:boolean"/>
          <!-- BASE/UNION geometries (or all components if no operations defined) -->
          <xsl:variable name="base-coords" as="array(xs:double*)*">
            <xsl:for-each select="if ($has-operations)
              then $geom-components[not(aixm:operation) or aixm:operation = 'BASE' or aixm:operation = 'UNION']
              else $geom-components">
              <xsl:sequence select="fcn:resolve-component-coords(., $root)"/>
            </xsl:for-each>
          </xsl:variable>
          <!-- SUBTR geometries (only when operations are defined) -->
          <xsl:variable name="subtr-coords" as="array(xs:double*)*">
            <xsl:if test="$has-operations">
              <xsl:for-each select="$geom-components[aixm:operation = 'SUBTR']">
                <xsl:sequence select="fcn:resolve-component-coords(., $root)"/>
              </xsl:for-each>
            </xsl:if>
          </xsl:variable>
          <!-- INTERS geometries (only when operations are defined) -->
          <xsl:variable name="inters-coords" as="array(xs:double*)*">
            <xsl:if test="$has-operations">
              <xsl:for-each select="$geom-components[aixm:operation = 'INTERS']">
                <xsl:sequence select="fcn:resolve-component-coords(., $root)"/>
              </xsl:for-each>
            </xsl:if>
          </xsl:variable>
          <!-- Only create entry if we have valid base geometry -->
          <xsl:if test="count($base-coords) gt 0">
            <xsl:sequence select="map{
              $uuid: map{
                'type': $airspace-type,
                'designator': $designator,
                'sequenceNumber': $seq-num,
                'correctionNumber': $corr-num,
                'beginPosition': string($latest-ts/gml:validTime/gml:TimePeriod/gml:beginPosition),
                'endPosition': string($latest-ts/gml:validTime/gml:TimePeriod/gml:endPosition),
                'endPositionIndeterminate': string($latest-ts/gml:validTime/gml:TimePeriod/gml:endPosition/@indeterminatePosition),
                'valid-ts': fcn:format-timeslice-info($latest-ts),
                'geometries': $base-coords,
                'subtr-geometries': $subtr-coords,
                'inters-geometries': $inters-coords
              }
            }"/>
          </xsl:if>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <!-- Merge all individual maps into a single map -->
    <xsl:sequence select="map:merge($geometry-entries)"/>
  </xsl:function>

  <!-- OPTIMIZED: Find the FIR containing a given point using pre-built geometry cache -->
  <xsl:function name="fcn:find-containing-fir-optimized" as="map(xs:string, xs:string)?">
    <xsl:param name="lat" as="xs:double"/>
    <xsl:param name="lon" as="xs:double"/>
    <xsl:param name="fir-cache" as="map(xs:string, map(*))"/>
    <xsl:param name="root" as="document-node()"/>
    <!-- Check each FIR in the cache -->
    <xsl:variable name="containing-uuids" as="xs:string*">
      <xsl:for-each select="map:keys($fir-cache)">
        <xsl:variable name="uuid" select="."/>
        <xsl:variable name="fir-data" select="map:get($fir-cache, $uuid)"/>
        <xsl:variable name="geometries" select="map:get($fir-data, 'geometries')"/>
        <!-- Check if point is in this FIR, accounting for geometry operations (BASE/UNION/SUBTR/INTERS) -->
        <xsl:variable name="is-inside" as="xs:boolean">
          <xsl:choose>
            <xsl:when test="count($geometries) = 0">
              <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:otherwise>
              <!-- Check if point is in any BASE/UNION geometry -->
              <xsl:variable name="in-base" as="xs:boolean">
                <xsl:variable name="base-matches" as="xs:boolean*">
                  <xsl:for-each select="$geometries">
                    <xsl:sequence select="fcn:point-in-polygon($lat, $lon, .)"/>
                  </xsl:for-each>
                </xsl:variable>
                <xsl:sequence select="some $m in $base-matches satisfies $m"/>
              </xsl:variable>
              <!-- Check if point is in any SUBTR geometry (should be excluded) -->
              <xsl:variable name="subtr-geoms" select="map:get($fir-data, 'subtr-geometries')"/>
              <xsl:variable name="in-subtr" as="xs:boolean">
                <xsl:choose>
                  <xsl:when test="count($subtr-geoms) = 0">
                    <xsl:sequence select="false()"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:variable name="subtr-matches" as="xs:boolean*">
                      <xsl:for-each select="$subtr-geoms">
                        <xsl:sequence select="fcn:point-in-polygon($lat, $lon, .)"/>
                      </xsl:for-each>
                    </xsl:variable>
                    <xsl:sequence select="some $m in $subtr-matches satisfies $m"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <!-- Check INTERS constraint: if INTERS geometries exist, point must be in at least one -->
              <xsl:variable name="inters-geoms" select="map:get($fir-data, 'inters-geometries')"/>
              <xsl:variable name="passes-inters" as="xs:boolean">
                <xsl:choose>
                  <xsl:when test="count($inters-geoms) = 0">
                    <xsl:sequence select="true()"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:variable name="inters-matches" as="xs:boolean*">
                      <xsl:for-each select="$inters-geoms">
                        <xsl:sequence select="fcn:point-in-polygon($lat, $lon, .)"/>
                      </xsl:for-each>
                    </xsl:variable>
                    <xsl:sequence select="some $m in $inters-matches satisfies $m"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <!-- Point is inside if: in base/union AND not in subtr AND passes inters constraint -->
              <xsl:sequence select="$in-base and not($in-subtr) and $passes-inters"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:if test="$is-inside">
          <xsl:sequence select="$uuid"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>
    <!-- Process the first containing airspace found (prefer FIR over FIR_P) -->
    <xsl:variable name="containing-uuid" as="xs:string?">
      <xsl:choose>
        <xsl:when test="count($containing-uuids) = 0">
          <xsl:sequence select="()"/>
        </xsl:when>
        <xsl:otherwise>
          <!-- Prefer FIR over FIR_P -->
          <xsl:variable name="fir-uuids" select="$containing-uuids[map:get(map:get($fir-cache, .), 'type') = 'FIR']"/>
          <xsl:sequence select="if (count($fir-uuids) gt 0) then $fir-uuids[1] else $containing-uuids[1]"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$containing-uuid">
      <xsl:variable name="fir-data" select="map:get($fir-cache, $containing-uuid)"/>
      <xsl:variable name="airspace-type" select="map:get($fir-data, 'type')"/>
      <xsl:choose>
        <!-- If it's a FIR_P, find the parent FIR -->
        <xsl:when test="$airspace-type = 'FIR_P'">
          <!-- Find FIR that references this FIR_P -->
          <xsl:variable name="parent-fir" select="($root//aixm:Airspace[aixm:timeSlice/aixm:AirspaceTimeSlice[aixm:type = 'FIR' and aixm:geometryComponent/aixm:AirspaceGeometryComponent/aixm:theAirspaceVolume/aixm:AirspaceVolume/aixm:contributorAirspace/aixm:AirspaceVolumeDependency/aixm:theAirspace/@xlink:href = concat('urn:uuid:', $containing-uuid)]])[1]"/>
          <xsl:if test="$parent-fir">
            <xsl:variable name="parent-ts" select="fcn:get-valid-timeslice($parent-fir/aixm:timeSlice/aixm:AirspaceTimeSlice[aixm:interpretation = 'BASELINE'])"/>
            <xsl:sequence select="map{
              'designator': string($parent-ts/aixm:designator),
              'sequenceNumber': string($parent-ts/aixm:sequenceNumber),
              'correctionNumber': string($parent-ts/aixm:correctionNumber),
              'beginPosition': string($parent-ts/gml:validTime/gml:TimePeriod/gml:beginPosition),
              'endPosition': string($parent-ts/gml:validTime/gml:TimePeriod/gml:endPosition),
              'endPositionIndeterminate': string($parent-ts/gml:validTime/gml:TimePeriod/gml:endPosition/@indeterminatePosition),
              'valid-ts': fcn:format-timeslice-info($parent-ts)
            }"/>
          </xsl:if>
        </xsl:when>
        <!-- If it's already a FIR, return it -->
        <xsl:when test="$airspace-type = 'FIR'">
          <xsl:sequence select="map{
            'designator': map:get($fir-data, 'designator'),
            'sequenceNumber': map:get($fir-data, 'sequenceNumber'),
            'correctionNumber': map:get($fir-data, 'correctionNumber'),
            'beginPosition': map:get($fir-data, 'beginPosition'),
            'endPosition': map:get($fir-data, 'endPosition'),
            'endPositionIndeterminate': map:get($fir-data, 'endPositionIndeterminate'),
            'valid-ts': map:get($fir-data, 'valid-ts')
          }"/>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
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
  
  <!-- Effectice date -->
  <xsl:function name="fcn:get-effective-date" as="xs:string">
    <xsl:param name="date" as="element()?"/>
    <xsl:if test="not(empty($date))">
      <xsl:value-of select="fcn:format-date($date)"/>
    </xsl:if>
  </xsl:function>
  
  <!-- Committed on -->
  <xsl:function name="fcn:get-commit-date" as="xs:string">
    <xsl:param name="date" as="element()"/>
    <xsl:if test="not(empty($date))">
      <xsl:value-of select="fcn:format-date($date)"/>
    </xsl:if>
  </xsl:function>
  
  <xsl:template match="/">
    
    <html xmlns="http://www.w3.org/1999/xhtml">
      
      <head>
        <meta http-equiv="Expires" content="120" />
        <title>SDO Reporting - Significant point with FIR</title>
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
            width: 100%;
            border-collapse: collapse;
            font-family: Times New Roman;
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
          <center><b>Significant point with FIR</b></center>
          <hr/>
        </div>
        
        <div class="table-wrapper">
          <table class="data-table">
            
            <thead>
              <tr style="white-space:nowrap">
                <td><strong>Type</strong></td>
                <td><strong>Identification</strong></td>
                <td><strong>Latitude</strong></td>
                <td><strong>Longitude</strong></td>
                <td><strong>Name</strong></td>
                <td><strong>Effective date</strong></td>
                <td><strong>Committed on</strong></td>
                <td><strong>Internal UID (master)</strong></td>
                <td><strong>Valid TimeSlice</strong></td>
                <td><strong>FIR Coded<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>identifier</strong></td>
                <td><strong>FIR<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Valid TimeSlice</strong></td>
                <td><strong>Originator</strong></td>
              </tr>
            </thead>
            
            <tbody>
              
              <!-- Capture document root before iterating through AirportHeliport features -->
              <xsl:variable name="doc-root" select="/" as="document-node()"/>
              
              <!-- OPTIMIZATION: Pre-build all FIR geometries once before processing airports -->
              <!-- This avoids reconstructing geometries N times (once per airport) -->
              <xsl:variable name="fir-geometry-cache" select="fcn:build-fir-geometry-cache($doc-root)" as="map(xs:string, map(*))"/>

              <!-- Pre-collect UUIDs referenced as significant points -->
              <xsl:variable name="navaid-system-refs" select="distinct-values(//*[ends-with(local-name(), '_navaidSystem')]/@xlink:href ! substring-after(., 'urn:uuid:'))"/>
              <xsl:variable name="airport-ref-point-refs" select="distinct-values(//*[ends-with(local-name(), '_airportReferencePoint')]/@xlink:href ! substring-after(., 'urn:uuid:'))"/>
              <xsl:variable name="runway-point-refs" select="distinct-values(//*[ends-with(local-name(), '_runwayPoint')]/@xlink:href ! substring-after(., 'urn:uuid:'))"/>
              <xsl:variable name="aiming-point-refs" select="distinct-values(//*[ends-with(local-name(), '_aimingPoint')]/@xlink:href ! substring-after(., 'urn:uuid:'))"/>

              <!-- ***** DesignatedPoint ***** -->
              <xsl:for-each select="//aixm:DesignatedPoint">
                
                <xsl:sort select="fcn:get-valid-timeslice(aixm:timeSlice/aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE'])/aixm:designator" order="ascending"/>
                <!-- Get all BASELINE time slices for this feature -->
                <xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE']"/>
                <!-- Select the valid time slice -->
                <xsl:variable name="valid-timeslice" select="fcn:get-valid-timeslice($baseline-timeslices)"/>
                
                <xsl:for-each select="$valid-timeslice">
                  
                  <!-- Type -->
                  <xsl:variable name="DPN_type" select="'DPN'"/>
                  
                  <!-- Identification -->
                  <xsl:variable name="DPN_identification">
                    <xsl:choose>
                      <xsl:when test="not(aixm:designator)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:designator)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- ===== Coordinates ===== -->
                  <!-- Select the type of coordinates: 'DMS' or 'DEC' -->
                  <xsl:variable name="coordinates_type" select="'DEC'"/>
                  <!-- Select the number of decimals -->
                  <xsl:variable name="coordinates_decimal_number" select="8"/>
                  <!-- Datum -->
                  <xsl:variable name="DPN_datum" select="replace(replace(aixm:location/aixm:Point/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
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
                  <xsl:variable name="DPN_lat">
                    <xsl:if test="string-length($latitude_decimal) gt 0">
                      <xsl:value-of select="fcn:format-latitude($latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
                    </xsl:if>
                  </xsl:variable>
                  <xsl:variable name="DPN_long">
                    <xsl:if test="string-length($longitude_decimal) gt 0">
                      <xsl:value-of select="fcn:format-longitude($longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
                    </xsl:if>
                  </xsl:variable>
                  
                  <!-- Name -->
                  <xsl:variable name="DPN_name">
                    <xsl:choose>
                      <xsl:when test="not(aixm:name)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:name)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- Identifier -->
                  <xsl:variable name="DPN_identifier" select="../../gml:identifier"/>
                  
                  <!-- DesignatedPoint - Valid TimeSlice -->
                  <xsl:variable name="DPN_timeslice" select="fcn:format-timeslice-info(.)"/>
                  
                  <!-- FIR - Coded identifier -->
                  <xsl:variable name="FIR-info" as="map(xs:string, xs:string)?">
                    <xsl:choose>
                      <xsl:when test="string($latitude_decimal) != '' and string($longitude_decimal) != ''">
                        <xsl:sequence select="fcn:find-containing-fir-optimized($latitude_decimal, $longitude_decimal, $fir-geometry-cache, $doc-root)"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:sequence select="()"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="DPN_FIR-designator" select="if (exists($FIR-info) and map:contains($FIR-info, 'designator')) then string($FIR-info?designator) else ''" as="xs:string"/>
                  
                  <!-- FIR - Valid TimeSlice -->
                  <xsl:variable name="FIR_timeslice" select="if (exists($FIR-info) and map:contains($FIR-info, 'valid-ts')) then $FIR-info?valid-ts else ''" as="xs:string"/>
                  
                  <!-- Effective date -->
                  <xsl:variable name="effective_date" select="
                    if (gml:validTime/gml:TimePeriod/gml:beginPosition)
                    then fcn:get-effective-date(gml:validTime/gml:TimePeriod/gml:beginPosition)
                    else ''"/>
                  
                  <!-- Committed on -->
                  <xsl:variable name="commit_date" select="
                    if (aixm:extension/ead-audit:DesignatedPointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)
                    then fcn:format-date(aixm:extension/ead-audit:DesignatedPointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)
                    else ''"/>
                  
                  <!-- Originator -->
                  <xsl:variable name="originator" select="aixm:extension/ead-audit:DesignatedPointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
                  <xsl:variable name="originator" select="
                    if(aixm:extension/ead-audit:DesignatedPointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg)
                    then aixm:extension/ead-audit:DesignatedPointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg
                    else ''"/>
                  
                  <tr>
                    <td><xsl:value-of select="if (string-length($DPN_type) gt 0) then $DPN_type else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($DPN_identification) gt 0) then $DPN_identification else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($DPN_lat) gt 0) then $DPN_lat else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($DPN_long) gt 0) then $DPN_long else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($DPN_name) gt 0) then $DPN_name else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($commit_date) gt 0) then $commit_date else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($DPN_identifier) gt 0) then $DPN_identifier else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($DPN_timeslice) gt 0) then $DPN_timeslice else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($DPN_FIR-designator) gt 0) then $DPN_FIR-designator else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($FIR_timeslice) gt 0) then $FIR_timeslice else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($originator) gt 0) then $originator else '&#160;'"/></td>
                  </tr>
                  
                </xsl:for-each>
                
              </xsl:for-each>
              
              <!-- ***** Navaid (significant points only) ***** -->
              <xsl:for-each select="//aixm:Navaid">

                <xsl:sort select="fcn:get-valid-timeslice(aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE'])/aixm:designator" order="ascending"/>
                <xsl:variable name="navaid-uuid" select="string(gml:identifier)"/>
                <!-- Get all BASELINE time slices for this feature -->
                <xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE']"/>
                <!-- Select the valid time slice -->
                <xsl:variable name="valid-timeslice" select="fcn:get-valid-timeslice($baseline-timeslices)"/>

                <!-- Check if Navaid has navaidEquipment with providesNavigableLocation='YES' -->
                <xsl:variable name="has-navigable-equipment" as="xs:boolean">
                  <xsl:variable name="eq-uuids" as="xs:string*"
                    select="$valid-timeslice/aixm:navaidEquipment/aixm:NavaidComponent/aixm:theNavaidEquipment/@xlink:href ! substring-after(., 'urn:uuid:')"/>
                  <xsl:choose>
                    <xsl:when test="count($eq-uuids) = 0">
                      <xsl:sequence select="false()"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:variable name="navigable-flags" as="xs:boolean*">
                        <xsl:for-each select="$eq-uuids">
                          <xsl:variable name="eq-uuid" select="."/>
                          <xsl:variable name="eq-feature" select="$doc-root//message:hasMember/*[gml:identifier = $eq-uuid]"/>
                          <xsl:variable name="eq-baseline-ts" select="$eq-feature/aixm:timeSlice/*[aixm:interpretation = 'BASELINE']"/>
                          <xsl:variable name="eq-valid-ts" select="fcn:get-valid-timeslice($eq-baseline-ts)"/>
                          <xsl:sequence select="string($eq-valid-ts/aixm:providesNavigableLocation) = 'YES'"/>
                        </xsl:for-each>
                      </xsl:variable>
                      <xsl:sequence select="some $f in $navigable-flags satisfies $f"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>

                <!-- Check if Navaid is referenced by a feature via a property ending in _navaidSystem -->
                <xsl:variable name="is-navaid-system-ref" select="$navaid-uuid = $navaid-system-refs" as="xs:boolean"/>

                <!-- Include only if significant point: has navigable equipment OR referenced as navaidSystem -->
                <xsl:if test="$has-navigable-equipment or $is-navaid-system-ref">
                <xsl:for-each select="$valid-timeslice">
                  
                  <!-- Type -->
                  <xsl:variable name="NAV_type" select="aixm:type"/>
                  
                  <!-- Identification -->
                  <xsl:variable name="NAV_identification">
                    <xsl:choose>
                      <xsl:when test="not(aixm:designator)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:designator)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  
                  <!-- ===== Coordinates ===== -->
                  <!-- Select the type of coordinates: 'DMS' or 'DEC' -->
                  <xsl:variable name="coordinates_type" select="'DEC'"/>
                  <!-- Select the number of decimals -->
                  <xsl:variable name="coordinates_decimal_number" select="8"/>
                  <!-- Datum -->
                  <xsl:variable name="NAV_datum" select="replace(replace(aixm:location/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
                  <!-- Extract coordinates depending on the coordinate system -->
                  <xsl:variable name="coordinates" select="aixm:location/aixm:ElevatedPoint/gml:pos"/>
                  <xsl:variable name="latitude_decimal">
                    <xsl:choose>
                      <xsl:when test="$NAV_datum = $lat-long-datums">
                        <xsl:value-of  select="number(substring-before($coordinates, ' '))"/>
                      </xsl:when>
                      <xsl:when test="matches($NAV_datum, '^OGC:.*CRS84$')">
                        <xsl:value-of select="number(substring-after($coordinates, ' '))"/>
                      </xsl:when>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="longitude_decimal">
                    <xsl:choose>
                      <xsl:when test="$NAV_datum = $lat-long-datums">
                        <xsl:value-of  select="number(substring-after($coordinates, ' '))"/>
                      </xsl:when>
                      <xsl:when test="matches($NAV_datum, '^OGC:.*CRS84$')">
                        <xsl:value-of select="number(substring-before($coordinates, ' '))"/>
                      </xsl:when>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="NAV_lat">
                    <xsl:if test="string-length($latitude_decimal) gt 0">
                      <xsl:value-of select="fcn:format-latitude($latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
                    </xsl:if>
                  </xsl:variable>
                  <xsl:variable name="NAV_long">
                    <xsl:if test="string-length($longitude_decimal) gt 0">
                      <xsl:value-of select="fcn:format-longitude($longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
                    </xsl:if>
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
                  
                  <!-- Identifier -->
                  <xsl:variable name="NAV_identifier" select="../../gml:identifier"/>
                  
                  <!-- Navaid - Valid TimeSlice -->
                  <xsl:variable name="NAV_timeslice" select="fcn:format-timeslice-info(.)"/>
                  
                  <!-- FIR - Coded identifier -->
                  <xsl:variable name="FIR-info" as="map(xs:string, xs:string)?">
                    <xsl:choose>
                      <xsl:when test="string($latitude_decimal) != '' and string($longitude_decimal) != ''">
                        <xsl:sequence select="fcn:find-containing-fir-optimized($latitude_decimal, $longitude_decimal, $fir-geometry-cache, $doc-root)"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:sequence select="()"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="NAV_FIR-designator" select="if (exists($FIR-info) and map:contains($FIR-info, 'designator')) then string($FIR-info?designator) else ''" as="xs:string"/>
                  
                  <!-- FIR - Valid TimeSlice -->
                  <xsl:variable name="FIR_timeslice" select="if (exists($FIR-info) and map:contains($FIR-info, 'valid-ts')) then $FIR-info?valid-ts else ''" as="xs:string"/>
                  
                  <!-- Effective date -->
                  <xsl:variable name="effective_date" select="
                    if (gml:validTime/gml:TimePeriod/gml:beginPosition)
                    then fcn:get-effective-date(gml:validTime/gml:TimePeriod/gml:beginPosition)
                    else ''"/>
                  
                  <!-- Committed on -->
                  <xsl:variable name="commit_date" select="
                    if (aixm:extension/ead-audit:NavaidExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)
                    then fcn:get-commit-date(aixm:extension/ead-audit:NavaidExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)
                    else ''"/>
                  
                  <!-- Originator -->
                  <xsl:variable name="originator" select="aixm:extension/ead-audit:NavaidExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
                  
                  <tr>
                    <td><xsl:value-of select="if (string-length($NAV_type) gt 0) then $NAV_type else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($NAV_identification) gt 0) then $NAV_identification else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($NAV_lat) gt 0) then $NAV_lat else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($NAV_long) gt 0) then $NAV_long else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($NAV_name) gt 0) then $NAV_name else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($commit_date) gt 0) then $commit_date else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($NAV_identifier) gt 0) then $NAV_identifier else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($NAV_timeslice) gt 0) then $NAV_timeslice else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($NAV_FIR-designator) gt 0) then $NAV_FIR-designator else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($FIR_timeslice) gt 0) then $FIR_timeslice else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($originator) gt 0) then $originator else '&#160;'"/></td>
                  </tr>
                  
                </xsl:for-each>
                </xsl:if>

              </xsl:for-each>

              <!-- ***** AirportHeliport (only those referenced by a property ending in _airportReferencePoint) ***** -->
              <xsl:for-each select="//aixm:AirportHeliport[string(gml:identifier) = $airport-ref-point-refs]">

                <xsl:sort select="fcn:get-valid-timeslice(aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE'])/aixm:designator" order="ascending"/>
                <!-- Get all BASELINE time slices for this feature -->
                <xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']"/>
                <!-- Select the valid time slice -->
                <xsl:variable name="valid-timeslice" select="fcn:get-valid-timeslice($baseline-timeslices)"/>

                <xsl:for-each select="$valid-timeslice">

                  <!-- Type -->
                  <xsl:variable name="AHP_type" select="'AD/HP'"/>

                  <!-- Identification -->
                  <xsl:variable name="AHP_identification">
                    <xsl:choose>
                      <xsl:when test="not(aixm:designator)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:designator)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>

                  <!-- ===== Coordinates ===== -->
                  <xsl:variable name="coordinates_type" select="'DEC'"/>
                  <xsl:variable name="coordinates_decimal_number" select="8"/>
                  <xsl:variable name="AHP_datum" select="replace(replace(aixm:ARP/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
                  <xsl:variable name="coordinates" select="aixm:ARP/aixm:ElevatedPoint/gml:pos"/>
                  <xsl:variable name="latitude_decimal">
                    <xsl:choose>
                      <xsl:when test="$AHP_datum = $lat-long-datums">
                        <xsl:value-of select="number(substring-before($coordinates, ' '))"/>
                      </xsl:when>
                      <xsl:when test="matches($AHP_datum, '^OGC:.*CRS84$')">
                        <xsl:value-of select="number(substring-after($coordinates, ' '))"/>
                      </xsl:when>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="longitude_decimal">
                    <xsl:choose>
                      <xsl:when test="$AHP_datum = $lat-long-datums">
                        <xsl:value-of select="number(substring-after($coordinates, ' '))"/>
                      </xsl:when>
                      <xsl:when test="matches($AHP_datum, '^OGC:.*CRS84$')">
                        <xsl:value-of select="number(substring-before($coordinates, ' '))"/>
                      </xsl:when>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="AHP_lat">
                    <xsl:if test="string-length($latitude_decimal) gt 0">
                      <xsl:value-of select="fcn:format-latitude($latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
                    </xsl:if>
                  </xsl:variable>
                  <xsl:variable name="AHP_long">
                    <xsl:if test="string-length($longitude_decimal) gt 0">
                      <xsl:value-of select="fcn:format-longitude($longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
                    </xsl:if>
                  </xsl:variable>

                  <!-- Name -->
                  <xsl:variable name="AHP_name">
                    <xsl:choose>
                      <xsl:when test="not(aixm:name)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:name)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>

                  <!-- Identifier -->
                  <xsl:variable name="AHP_identifier" select="../../gml:identifier"/>
                  
                  <!-- AirportHeliport - Valid TimeSlice -->
                  <xsl:variable name="AHP_timeslice" select="fcn:format-timeslice-info(.)"/>

                  <!-- FIR - Coded identifier -->
                  <xsl:variable name="FIR-info" as="map(xs:string, xs:string)?">
                    <xsl:choose>
                      <xsl:when test="string($latitude_decimal) != '' and string($longitude_decimal) != ''">
                        <xsl:sequence select="fcn:find-containing-fir-optimized($latitude_decimal, $longitude_decimal, $fir-geometry-cache, $doc-root)"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:sequence select="()"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="AHP_FIR-designator" select="if (exists($FIR-info) and map:contains($FIR-info, 'designator')) then string($FIR-info?designator) else ''" as="xs:string"/>

                  <!-- FIR - Valid TimeSlice -->
                  <xsl:variable name="FIR_timeslice" select="if (exists($FIR-info) and map:contains($FIR-info, 'valid-ts')) then $FIR-info?valid-ts else ''" as="xs:string"/>

                  <!-- Effective date -->
                  <xsl:variable name="effective_date" select="
                    if (gml:validTime/gml:TimePeriod/gml:beginPosition)
                    then fcn:get-effective-date(gml:validTime/gml:TimePeriod/gml:beginPosition)
                    else ''"/>

                  <!-- Committed on -->
                  <xsl:variable name="commit_date" select="
                    if (aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)
                    then fcn:format-date(aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)
                    else ''"/>

                  <!-- Originator -->
                  <xsl:variable name="originator" select="
                    if (aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg)
                    then aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg
                    else ''"/>

                  <tr>
                    <td><xsl:value-of select="if (string-length($AHP_type) gt 0) then $AHP_type else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($AHP_identification) gt 0) then $AHP_identification else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($AHP_lat) gt 0) then $AHP_lat else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($AHP_long) gt 0) then $AHP_long else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($AHP_name) gt 0) then $AHP_name else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($commit_date) gt 0) then $commit_date else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($AHP_identifier) gt 0) then $AHP_identifier else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($AHP_timeslice) gt 0) then $AHP_timeslice else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($AHP_FIR-designator) gt 0) then $AHP_FIR-designator else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($FIR_timeslice) gt 0) then $FIR_timeslice else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($originator) gt 0) then $originator else '&#160;'"/></td>
                  </tr>

                </xsl:for-each>

              </xsl:for-each>

              <!-- ***** RunwayCentrelinePoint (only those referenced by a property ending in _runwayPoint) ***** -->
              <xsl:for-each select="//aixm:RunwayCentrelinePoint[string(gml:identifier) = $runway-point-refs]">

                <xsl:sort select="fcn:get-valid-timeslice(aixm:timeSlice/aixm:RunwayCentrelinePointTimeSlice[aixm:interpretation = 'BASELINE'])/aixm:designator" order="ascending"/>
                <!-- Get all BASELINE time slices for this feature -->
                <xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:RunwayCentrelinePointTimeSlice[aixm:interpretation = 'BASELINE']"/>
                <!-- Select the valid time slice -->
                <xsl:variable name="valid-timeslice" select="fcn:get-valid-timeslice($baseline-timeslices)"/>

                <xsl:for-each select="$valid-timeslice">

                  <!-- Type -->
                  <xsl:variable name="RCP_type" select="'RCP'"/>

                  <!-- Identification -->
                  <xsl:variable name="RCP_identification">
                    <xsl:choose>
                      <xsl:when test="not(aixm:designator)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:designator)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>

                  <!-- ===== Coordinates ===== -->
                  <xsl:variable name="coordinates_type" select="'DEC'"/>
                  <xsl:variable name="coordinates_decimal_number" select="8"/>
                  <xsl:variable name="RCP_datum" select="replace(replace(aixm:location/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
                  <xsl:variable name="coordinates" select="aixm:location/aixm:ElevatedPoint/gml:pos"/>
                  <xsl:variable name="latitude_decimal">
                    <xsl:choose>
                      <xsl:when test="$RCP_datum = $lat-long-datums">
                        <xsl:value-of select="number(substring-before($coordinates, ' '))"/>
                      </xsl:when>
                      <xsl:when test="matches($RCP_datum, '^OGC:.*CRS84$')">
                        <xsl:value-of select="number(substring-after($coordinates, ' '))"/>
                      </xsl:when>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="longitude_decimal">
                    <xsl:choose>
                      <xsl:when test="$RCP_datum = $lat-long-datums">
                        <xsl:value-of select="number(substring-after($coordinates, ' '))"/>
                      </xsl:when>
                      <xsl:when test="matches($RCP_datum, '^OGC:.*CRS84$')">
                        <xsl:value-of select="number(substring-before($coordinates, ' '))"/>
                      </xsl:when>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="RCP_lat">
                    <xsl:if test="string-length($latitude_decimal) gt 0">
                      <xsl:value-of select="fcn:format-latitude($latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
                    </xsl:if>
                  </xsl:variable>
                  <xsl:variable name="RCP_long">
                    <xsl:if test="string-length($longitude_decimal) gt 0">
                      <xsl:value-of select="fcn:format-longitude($longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
                    </xsl:if>
                  </xsl:variable>

                  <!-- Name (RCP has no aixm:name) -->
                  <xsl:variable name="RCP_name" select="''"/>

                  <!-- Identifier -->
                  <xsl:variable name="RCP_identifier" select="../../gml:identifier"/>
                  
                  <!-- RunwayCentrelinePoint - Valid TimeSlice -->
                  <xsl:variable name="RCP_timeslice" select="fcn:format-timeslice-info(.)"/>

                  <!-- FIR - Coded identifier -->
                  <xsl:variable name="FIR-info" as="map(xs:string, xs:string)?">
                    <xsl:choose>
                      <xsl:when test="string($latitude_decimal) != '' and string($longitude_decimal) != ''">
                        <xsl:sequence select="fcn:find-containing-fir-optimized($latitude_decimal, $longitude_decimal, $fir-geometry-cache, $doc-root)"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:sequence select="()"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="RCP_FIR-designator" select="if (exists($FIR-info) and map:contains($FIR-info, 'designator')) then string($FIR-info?designator) else ''" as="xs:string"/>

                  <!-- FIR - Valid TimeSlice -->
                  <xsl:variable name="FIR_timeslice" select="if (exists($FIR-info) and map:contains($FIR-info, 'valid-ts')) then $FIR-info?valid-ts else ''" as="xs:string"/>

                  <!-- Effective date -->
                  <xsl:variable name="effective_date" select="
                    if (gml:validTime/gml:TimePeriod/gml:beginPosition)
                    then fcn:get-effective-date(gml:validTime/gml:TimePeriod/gml:beginPosition)
                    else ''"/>

                  <!-- Committed on -->
                  <xsl:variable name="commit_date" select="
                    if (aixm:extension/ead-audit:RunwayCentrelinePointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)
                    then fcn:format-date(aixm:extension/ead-audit:RunwayCentrelinePointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)
                    else ''"/>

                  <!-- Originator -->
                  <xsl:variable name="originator" select="
                    if (aixm:extension/ead-audit:RunwayCentrelinePointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg)
                    then aixm:extension/ead-audit:RunwayCentrelinePointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg
                    else ''"/>

                  <tr>
                    <td><xsl:value-of select="if (string-length($RCP_type) gt 0) then $RCP_type else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RCP_identification) gt 0) then $RCP_identification else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RCP_lat) gt 0) then $RCP_lat else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RCP_long) gt 0) then $RCP_long else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RCP_name) gt 0) then $RCP_name else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($commit_date) gt 0) then $commit_date else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RCP_identifier) gt 0) then $RCP_identifier else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RCP_timeslice) gt 0) then $RCP_timeslice else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($RCP_FIR-designator) gt 0) then $RCP_FIR-designator else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($FIR_timeslice) gt 0) then $FIR_timeslice else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($originator) gt 0) then $originator else '&#160;'"/></td>
                  </tr>

                </xsl:for-each>

              </xsl:for-each>

              <!-- ***** TouchDownLiftOff (only those referenced by a property ending in _aimingPoint) ***** -->
              <xsl:for-each select="//aixm:TouchDownLiftOff[string(gml:identifier) = $aiming-point-refs]">

                <xsl:sort select="fcn:get-valid-timeslice(aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice[aixm:interpretation = 'BASELINE'])/aixm:designator" order="ascending"/>
                <!-- Get all BASELINE time slices for this feature -->
                <xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice[aixm:interpretation = 'BASELINE']"/>
                <!-- Select the valid time slice -->
                <xsl:variable name="valid-timeslice" select="fcn:get-valid-timeslice($baseline-timeslices)"/>

                <xsl:for-each select="$valid-timeslice">

                  <!-- Type -->
                  <xsl:variable name="TLOF_type" select="'TLOF'"/>

                  <!-- Identification -->
                  <xsl:variable name="TLOF_identification">
                    <xsl:choose>
                      <xsl:when test="not(aixm:designator)">
                        <xsl:value-of select="''"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="fcn:insert-value(aixm:designator)"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>

                  <!-- ===== Coordinates ===== -->
                  <xsl:variable name="coordinates_type" select="'DEC'"/>
                  <xsl:variable name="coordinates_decimal_number" select="8"/>
                  <xsl:variable name="TLOF_datum" select="replace(replace(aixm:extent/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
                  <xsl:variable name="coordinates" select="aixm:extent/aixm:ElevatedPoint/gml:pos"/>
                  <xsl:variable name="latitude_decimal">
                    <xsl:choose>
                      <xsl:when test="$TLOF_datum = $lat-long-datums">
                        <xsl:value-of select="number(substring-before($coordinates, ' '))"/>
                      </xsl:when>
                      <xsl:when test="matches($TLOF_datum, '^OGC:.*CRS84$')">
                        <xsl:value-of select="number(substring-after($coordinates, ' '))"/>
                      </xsl:when>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="longitude_decimal">
                    <xsl:choose>
                      <xsl:when test="$TLOF_datum = $lat-long-datums">
                        <xsl:value-of select="number(substring-after($coordinates, ' '))"/>
                      </xsl:when>
                      <xsl:when test="matches($TLOF_datum, '^OGC:.*CRS84$')">
                        <xsl:value-of select="number(substring-before($coordinates, ' '))"/>
                      </xsl:when>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="TLOF_lat">
                    <xsl:if test="string-length($latitude_decimal) gt 0">
                      <xsl:value-of select="fcn:format-latitude($latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
                    </xsl:if>
                  </xsl:variable>
                  <xsl:variable name="TLOF_long">
                    <xsl:if test="string-length($longitude_decimal) gt 0">
                      <xsl:value-of select="fcn:format-longitude($longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
                    </xsl:if>
                  </xsl:variable>

                  <!-- Name (TLOF has no aixm:name) -->
                  <xsl:variable name="TLOF_name" select="''"/>

                  <!-- Identifier -->
                  <xsl:variable name="TLOF_identifier" select="../../gml:identifier"/>
                  
                  <!-- TouchDownLiftOff - Valid TimeSlice -->
                  <xsl:variable name="TLOF_timeslice" select="fcn:format-timeslice-info(.)"/>

                  <!-- FIR - Coded identifier -->
                  <xsl:variable name="FIR-info" as="map(xs:string, xs:string)?">
                    <xsl:choose>
                      <xsl:when test="string($latitude_decimal) != '' and string($longitude_decimal) != ''">
                        <xsl:sequence select="fcn:find-containing-fir-optimized($latitude_decimal, $longitude_decimal, $fir-geometry-cache, $doc-root)"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:sequence select="()"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  <xsl:variable name="TLOF_FIR-designator" select="if (exists($FIR-info) and map:contains($FIR-info, 'designator')) then string($FIR-info?designator) else ''" as="xs:string"/>

                  <!-- FIR - Valid TimeSlice -->
                  <xsl:variable name="FIR_timeslice" select="if (exists($FIR-info) and map:contains($FIR-info, 'valid-ts')) then $FIR-info?valid-ts else ''" as="xs:string"/>

                  <!-- Effective date -->
                  <xsl:variable name="effective_date" select="
                    if (gml:validTime/gml:TimePeriod/gml:beginPosition)
                    then fcn:get-effective-date(gml:validTime/gml:TimePeriod/gml:beginPosition)
                    else ''"/>

                  <!-- Committed on -->
                  <xsl:variable name="commit_date" select="
                    if (aixm:extension/ead-audit:TouchDownLiftOffExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)
                    then fcn:format-date(aixm:extension/ead-audit:TouchDownLiftOffExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)
                    else ''"/>

                  <!-- Originator -->
                  <xsl:variable name="originator" select="
                    if (aixm:extension/ead-audit:TouchDownLiftOffExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg)
                    then aixm:extension/ead-audit:TouchDownLiftOffExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg
                    else ''"/>

                  <tr>
                    <td><xsl:value-of select="if (string-length($TLOF_type) gt 0) then $TLOF_type else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($TLOF_identification) gt 0) then $TLOF_identification else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($TLOF_lat) gt 0) then $TLOF_lat else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($TLOF_long) gt 0) then $TLOF_long else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($TLOF_name) gt 0) then $TLOF_name else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($commit_date) gt 0) then $commit_date else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($TLOF_identifier) gt 0) then $TLOF_identifier else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($TLOF_timeslice) gt 0) then $TLOF_timeslice else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($TLOF_FIR-designator) gt 0) then $TLOF_FIR-designator else '&#160;'"/></td>
                    <td><xsl:value-of select="if (string-length($FIR_timeslice) gt 0) then $FIR_timeslice else '&#160;'"/></td>
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