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
  includeReferencedFeaturesLevel: 3
               permanentBaseline: true
              spatialFilteringBy: Airspace
                 spatialAreaUUID: *select FIR airspace*
                 spatialOperator: Within
            spatialValueOperator: OR
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
	
	<xsl:strip-space elements="*"/>
	
	<xsl:function name="fcn:get-last-word" as="xs:string">
		<xsl:param name="input" as="xs:string"/>
		<xsl:variable name="words" select="tokenize(normalize-space($input), '\s+')"/>
		<xsl:sequence select="$words[last()]"/>
	</xsl:function>
	
	<xsl:function name="fcn:get-date" as="xs:string">
		<xsl:param name="input" as="xs:string"/>
		<xsl:variable name="date-time" select="$input"/>
		<xsl:variable name="day" select="substring($date-time, 9, 2)"/>
		<xsl:variable name="month" select="substring($date-time, 6, 2)"/>
		<xsl:variable name="month" select="if($month = '01') then 'JAN' else if ($month = '02') then 'FEB' else if ($month = '03') then 'MAR' else 
			if ($month = '04') then 'APR' else if ($month = '05') then 'MAY' else if ($month = '06') then 'JUN' else if ($month = '07') then 'JUL' else 
			if ($month = '08') then 'AUG' else if ($month = '09') then 'SEP' else if ($month = '10') then 'OCT' else if ($month = '11') then 'NOV' else if ($month = '12') then 'DEC' else ''"/>
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
				<xsl:value-of select="format-number($lat_decimal, $format-string)"/>
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
				<xsl:value-of select="format-number($lon_decimal, $format-string)"/>
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
	<xsl:function name="fcn:densify-linear-segment" as="xs:double*">
		<xsl:param name="lat1" as="xs:double"/>
		<xsl:param name="lon1" as="xs:double"/>
		<xsl:param name="lat2" as="xs:double"/>
		<xsl:param name="lon2" as="xs:double"/>
		<xsl:param name="max-segment-degrees" as="xs:double"/>
		<!-- Calculate simple Euclidean distance for linear interpolation -->
		<xsl:variable name="dlat" select="abs($lat2 - $lat1)"/>
		<xsl:variable name="dlon" select="abs($lon2 - $lon1)"/>
		<xsl:variable name="distance" select="math:sqrt($dlat * $dlat + $dlon * $dlon)"/>
		<xsl:variable name="num-segments" select="xs:integer(ceiling($distance div $max-segment-degrees))"/>
		<xsl:choose>
			<xsl:when test="$num-segments le 1">
				<!-- No interpolation needed -->
				<xsl:sequence select="$lat1, $lon1"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- Add first point -->
				<xsl:sequence select="$lat1, $lon1"/>
				<!-- Add intermediate points using simple linear interpolation -->
				<xsl:for-each select="1 to ($num-segments - 1)">
					<xsl:variable name="fraction" select=". div $num-segments"/>
					<xsl:sequence select="$lat1 + $fraction * ($lat2 - $lat1)"/>
					<xsl:sequence select="$lon1 + $fraction * ($lon2 - $lon1)"/>
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
							<xsl:variable name="gb-max-seq" select="max($gb-baseline-ts/aixm:sequenceNumber)"/>
							<xsl:variable name="gb-max-corr" select="max($gb-baseline-ts[aixm:sequenceNumber = $gb-max-seq]/aixm:correctionNumber)"/>
							<xsl:variable name="gb-valid-ts" select="$gb-baseline-ts[aixm:sequenceNumber = $gb-max-seq and aixm:correctionNumber = $gb-max-corr][1]"/>
							<!-- Get ALL GeoBorder coordinates (flattened) -->
							<xsl:variable name="gb-all-coords" as="xs:double*">
								<xsl:for-each select="$gb-valid-ts/aixm:border//gml:segments/*">
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
		<xsl:choose>
			<xsl:when test="$num-points lt 3">
				<xsl:sequence select="false()"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- Check if polygon is closed (first point = last point) -->
				<xsl:variable name="is-closed" select="abs($polygon-coords[1] - $polygon-coords[$num-coords - 1]) lt $epsilon and abs($polygon-coords[2] - $polygon-coords[$num-coords]) lt $epsilon"/>
				<xsl:variable name="actual-num-points" select="if ($is-closed) then $num-points - 1 else $num-points"/>
				<!-- Ray-casting algorithm with improved edge case handling -->
				<xsl:variable name="intersections" as="xs:integer">
					<xsl:variable name="counts" as="xs:integer*">
						<xsl:for-each select="1 to xs:integer($actual-num-points)">
							<xsl:variable name="i" select="."/>
							<xsl:variable name="j" select="if ($i = $actual-num-points) then 1 else $i + 1"/>
							<xsl:variable name="lat-i" select="$polygon-coords[($i - 1) * 2 + 1]"/>
							<xsl:variable name="lon-i" select="$polygon-coords[($i - 1) * 2 + 2]"/>
							<xsl:variable name="lat-j" select="$polygon-coords[($j - 1) * 2 + 1]"/>
							<xsl:variable name="lon-j" select="$polygon-coords[($j - 1) * 2 + 2]"/>
							<!-- Standard ray-casting: check if horizontal ray from point intersects edge -->
							<!-- Edge must cross the latitude of the test point -->
							<xsl:variable name="lat-i-above" select="$lat-i gt $point-lat"/>
							<xsl:variable name="lat-j-above" select="$lat-j gt $point-lat"/>
							<xsl:choose>
								<xsl:when test="$lat-i-above != $lat-j-above">
									<!-- Calculate longitude of intersection with horizontal ray -->
									<xsl:variable name="intersect-lon" select="($lon-j - $lon-i) * ($point-lat - $lat-i) div ($lat-j - $lat-i) + $lon-i"/>
									<!-- Count if intersection is to the right of test point (with epsilon tolerance) -->
									<xsl:sequence select="if ($intersect-lon gt $point-lon - $epsilon) then 1 else 0"/>
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
	
	<!-- Function to get the valid BASELINE timeslice for an Airspace -->
	<xsl:function name="fcn:get-valid-airspace-timeslice" as="element()?">
		<xsl:param name="airspace" as="element()?"/>
		<xsl:variable name="baseline-timeslices" select="$airspace/aixm:timeSlice/aixm:AirspaceTimeSlice[aixm:interpretation = 'BASELINE']"/>
		<xsl:variable name="max-sequence" select="max($baseline-timeslices/aixm:sequenceNumber)"/>
		<xsl:variable name="max-correction" select="max($baseline-timeslices[aixm:sequenceNumber = $max-sequence]/aixm:correctionNumber)"/>
		<xsl:sequence select="$baseline-timeslices[aixm:sequenceNumber = $max-sequence and aixm:correctionNumber = $max-correction][1]"/>
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
				<xsl:variable name="valid-ts" select="fcn:get-valid-airspace-timeslice($airspace)"/>
				<xsl:if test="$valid-ts">
					<xsl:variable name="airspace-type" select="string($valid-ts/aixm:type)"/>
					<xsl:variable name="designator" select="string($valid-ts/aixm:designator)"/>
					<xsl:variable name="seq-num" select="string($valid-ts/aixm:sequenceNumber)"/>
					<xsl:variable name="corr-num" select="string($valid-ts/aixm:correctionNumber)"/>
					<!-- Get geometry - handle both direct geometry and contributorAirspace references -->
					<xsl:variable name="geom-components" select="$valid-ts/aixm:geometryComponent/aixm:AirspaceGeometryComponent"/>
					<!-- Collect all coordinate sequences for this airspace -->
					<xsl:variable name="all-coords" as="array(xs:double*)*">
						<xsl:for-each select="$geom-components">
							<xsl:variable name="airspace-volume" select="aixm:theAirspaceVolume/aixm:AirspaceVolume"/>
							<xsl:choose>
								<!-- Direct geometry -->
								<xsl:when test="$airspace-volume/aixm:horizontalProjection">
									<xsl:variable name="coords" select="fcn:get-all-polygon-coords($airspace-volume/aixm:horizontalProjection, $root)"/>
									<xsl:if test="count($coords) ge 6">
										<xsl:sequence select="[$coords]"/>
									</xsl:if>
								</xsl:when>
								<!-- Reference to another airspace (FIR composed of FIR_P) -->
								<xsl:when test="$airspace-volume/aixm:contributorAirspace">
									<xsl:for-each select="$airspace-volume/aixm:contributorAirspace/aixm:AirspaceVolumeDependency">
										<xsl:variable name="ref-uuid" select="substring-after(aixm:theAirspace/@xlink:href, 'urn:uuid:')"/>
										<xsl:variable name="ref-airspace" select="$root//aixm:Airspace[gml:identifier = $ref-uuid]"/>
										<xsl:variable name="ref-valid-ts" select="fcn:get-valid-airspace-timeslice($ref-airspace)"/>
										<xsl:if test="$ref-valid-ts">
											<xsl:variable name="ref-volume" select="$ref-valid-ts/aixm:geometryComponent/aixm:AirspaceGeometryComponent/aixm:theAirspaceVolume/aixm:AirspaceVolume"/>
											<xsl:variable name="ref-coords" select="fcn:get-all-polygon-coords($ref-volume/aixm:horizontalProjection, $root)"/>
											<xsl:if test="count($ref-coords) ge 6">
												<xsl:sequence select="[$ref-coords]"/>
											</xsl:if>
										</xsl:if>
									</xsl:for-each>
								</xsl:when>
							</xsl:choose>
						</xsl:for-each>
					</xsl:variable>
					<!-- Only create entry if we have valid geometry -->
					<xsl:if test="count($all-coords) gt 0">
						<xsl:sequence select="map{
							$uuid: map{
								'type': $airspace-type,
								'designator': $designator,
								'sequenceNumber': $seq-num,
								'correctionNumber': $corr-num,
								'geometries': $all-coords
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
				<!-- Check if point is in any of this FIR's geometries -->
				<xsl:variable name="is-inside" as="xs:boolean">
					<xsl:choose>
						<xsl:when test="count($geometries) = 0">
							<xsl:sequence select="false()"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:variable name="matches" as="xs:boolean*">
								<xsl:for-each select="$geometries">
									<xsl:sequence select="fcn:point-in-polygon($lat, $lon, .)"/>
								</xsl:for-each>
							</xsl:variable>
							<xsl:sequence select="some $m in $matches satisfies $m"/>
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
						<xsl:variable name="parent-ts" select="fcn:get-valid-airspace-timeslice($parent-fir)"/>
						<xsl:sequence select="map{
							'designator': string($parent-ts/aixm:designator),
							'sequenceNumber': string($parent-ts/aixm:sequenceNumber),
							'correctionNumber': string($parent-ts/aixm:correctionNumber)
						}"/>
					</xsl:if>
				</xsl:when>
				<!-- If it's already a FIR, return it -->
				<xsl:when test="$airspace-type = 'FIR'">
					<xsl:sequence select="map{
						'designator': map:get($fir-data, 'designator'),
						'sequenceNumber': map:get($fir-data, 'sequenceNumber'),
						'correctionNumber': map:get($fir-data, 'correctionNumber')
					}"/>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
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
				<meta http-equiv="Expires" content="120" />
				<title>SDO Reporting - Designated Point with FIR</title>
			</head>
			
			<body>
				
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
				
				<center>
					<b>Designated Point with FIR</b>
				</center>
				<hr/>
				
				<table border="0" style="border-spacing: 8px 4px">
					<tbody>
						
						<tr style="white-space:nowrap">
							<td><strong>Identification</strong></td>
							<td><strong>Latitude</strong></td>
							<td><strong>Longitude</strong></td>
							<td><strong>TLOF centre<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Aerodrome / Heliport - Identification</strong></td>
							<td><strong>TLOF centre<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Aerodrome / Heliport - ICAO Code</strong></td>
							<td><strong>TLOF centre<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Designator</strong></td>
							<td><strong>Associated Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Identification</strong></td>
							<td><strong>Associated Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- ICAO Code</strong></td>
							<td><strong>ARP Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Latitude</strong></td>
							<td><strong>ARP Aerodrome / Heliport<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Longitude</strong></td>
							<td><strong>RWY centre line<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Aerodrome / Heliport - Identification</strong></td>
							<td><strong>RWY centre line<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Aerodrome / Heliport - ICAO Code</strong></td>
							<td><strong>RWY centre line<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Designator</strong></td>
							<td><strong>RWY centre line<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Latitude</strong></td>
							<td><strong>RWY centre line<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Longitude</strong></td>
							<td><strong>FATO centre line<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Aerodrome / Heliport - Identification</strong></td>
							<td><strong>FATO centre line<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>Aerodrome / Heliport - ICAO Code</strong></td>
							<td><strong>FATO centre line<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>TLOF - Designator</strong></td>
							<td><strong>Final approach and take-off area [FATO]<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Designator</strong></td>
							<td><strong>FATO centre line<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Latitude</strong></td>
							<td><strong>FATO centre line<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Longitude</strong></td>
							<td><strong>Datum</strong></td>
							<td><strong>Geographical accuracy</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[geographical accuracy]</strong></td>
							<td><strong>Cyclic redundancy<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>check</strong></td>
							<td><strong>Type</strong></td>
							<td><strong>Name</strong></td>
							<td><strong>Remarks</strong></td>
							<td><strong>Effective date</strong></td>
							<td><strong>Committed on</strong></td>
							<td><strong>Internal UID (master)</strong></td>
							<td><strong>DesignatedPoint<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Valid TimeSlice</strong></td>
							<td><strong>FIR<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Coded identifier</strong></td>
							<td><strong>FIR<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>- Valid TimeSlice</strong></td>
							<td><strong>Originator</strong></td>
						</tr>
						
						<!-- Capture document root before iterating through DesignatedPoints -->
						<xsl:variable name="doc-root" select="/" as="document-node()"/>
						
						<!-- OPTIMIZATION: Pre-build all FIR geometries once before processing airports -->
						<!-- This avoids reconstructing geometries N times (once per airport) -->
						<xsl:variable name="fir-geometry-cache" select="fcn:build-fir-geometry-cache($doc-root)" as="map(xs:string, map(*))"/>

						<xsl:for-each select="//aixm:DesignatedPoint">
							
							<xsl:sort select="(aixm:timeSlice/aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)][aixm:correctionNumber = max(../aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)]/aixm:correctionNumber)])[1]/aixm:designator" order="ascending"/>
							
							<!-- Get all BASELINE time slices for this DesignatedPoint -->
							<xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE']"/>
							<!-- Find the maximum sequenceNumber -->
							<xsl:variable name="max-sequence" select="max($baseline-timeslices/aixm:sequenceNumber)"/>
							<!-- Get time slices with the maximum sequenceNumber, then find max correctionNumber -->
							<xsl:variable name="max-correction" select="max($baseline-timeslices[aixm:sequenceNumber = $max-sequence]/aixm:correctionNumber)"/>
							<!-- Select the valid time slice -->
							<xsl:variable name="valid-timeslice" select="$baseline-timeslices[aixm:sequenceNumber = $max-sequence and aixm:correctionNumber = $max-correction][1]"/>
							
							<xsl:for-each select="$valid-timeslice">
								
								<!-- Identification -->
								<xsl:variable name="DPN_designator">
									<xsl:choose>
										<xsl:when test="not(aixm:designator)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:designator)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Coordinates -->
								
								<!-- Select the type of coordinates: 'DMS' or 'DEC' -->
								<xsl:variable name="coordinates_type" select="'DMS'"/>
								
								<!-- Select the number of decimals -->
								<xsl:variable name="coordinates_decimal_number" select="2"/>
								
								<!-- Datum -->
								<xsl:variable name="DPN_datum">
									<xsl:value-of select="replace(replace(aixm:location/aixm:Point/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
								</xsl:variable>
								
								<!-- Extract coordinates depending on the coordinate system -->
								<xsl:variable name="DPN_coordinates" select="aixm:location/aixm:Point/gml:pos"/>
								<xsl:variable name="DPN_latitude_decimal">
									<xsl:choose>
										<xsl:when test="$DPN_datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
											<xsl:value-of  select="number(substring-before($DPN_coordinates, ' '))"/>
										</xsl:when>
										<xsl:when test="matches($DPN_datum, '^OGC:.*CRS84$')">
											<xsl:value-of select="number(substring-after($DPN_coordinates, ' '))"/>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="DPN_longitude_decimal">
									<xsl:choose>
										<xsl:when test="$DPN_datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
											<xsl:value-of  select="number(substring-after($DPN_coordinates, ' '))"/>
										</xsl:when>
										<xsl:when test="matches($DPN_datum, '^OGC:.*CRS84$')">
											<xsl:value-of select="number(substring-before($DPN_coordinates, ' '))"/>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="DPN_latitude">
									<xsl:if test="string-length($DPN_latitude_decimal) gt 0">
										<xsl:value-of select="fcn:format-latitude($DPN_latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
								</xsl:variable>
								<xsl:variable name="DPN_longitude">
									<xsl:if test="string-length($DPN_longitude_decimal) gt 0">
										<xsl:value-of select="fcn:format-longitude($DPN_longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- TLOF -->
								<xsl:variable name="TLOF_UUID" select="if (aixm:aimingPoint/@xlink:href) then replace(aixm:aimingPoint/@xlink:href, '^(urn:uuid:|#uuid\.)', '') else ''"/>
								<xsl:variable name="TLOF-baseline-ts" select="//aixm:TouchDownLiftOff[gml:identifier = $TLOF_UUID]/aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="TLOF-max-seq" select="max($TLOF-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="TLOF-max-corr" select="max($TLOF-baseline-ts[aixm:sequenceNumber = $TLOF-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="TLOF-valid-ts" select="$TLOF-baseline-ts[aixm:sequenceNumber = $TLOF-max-seq and aixm:correctionNumber = $TLOF-max-corr][1]"/>
								<xsl:variable name="TLOF_AHP_UUID">
									<xsl:if test="$TLOF-valid-ts/aixm:associatedAirportHeliport/@xlink:href">
										<xsl:value-of select="replace($TLOF-valid-ts/aixm:associatedAirportHeliport/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
									</xsl:if>
								</xsl:variable>
								<!-- TLOF centre - Designator -->
								<xsl:variable name="TLOF_designator">
									<xsl:choose>
										<xsl:when test="not($TLOF-valid-ts/aixm:designator)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($TLOF-valid-ts/aixm:designator)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<!-- AHP containing the TLOF -->
								<!-- Get the valid BASELINE TimeSlice for this AHP -->
								<xsl:variable name="TLOF-AHP-baseline-ts" select="//aixm:AirportHeliport[gml:identifier = $TLOF_AHP_UUID]/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="TLOF-AHP-max-seq" select="max($TLOF-AHP-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="TLOF-AHP-max-corr" select="max($TLOF-AHP-baseline-ts[aixm:sequenceNumber = $TLOF-AHP-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="TLOF-AHP-valid-ts" select="$TLOF-AHP-baseline-ts[aixm:sequenceNumber = $TLOF-AHP-max-seq and aixm:correctionNumber = $TLOF-AHP-max-corr][1]"/>
								<!-- TLOF centre Aerodrome / Heliport - Identification -->
								<xsl:variable name="TLOF_AHP_designator">
									<xsl:choose>
										<xsl:when test="not($TLOF-AHP-valid-ts/aixm:designator)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($TLOF-AHP-valid-ts/aixm:designator)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<!-- TLOF centre Aerodrome / Heliport - ICAO Code -->
								<xsl:variable name="TLOF_AHP_ICAO_code">
									<xsl:choose>
										<xsl:when test="not($TLOF-AHP-valid-ts/aixm:locationIndicatorICAO)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($TLOF-AHP-valid-ts/aixm:locationIndicatorICAO)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Associated Aerodrome / Heliport -->
								<xsl:variable name="DPN_AHP_UUID" select="if (aixm:airportHeliport/@xlink:href) then replace(aixm:airportHeliport/@xlink:href, '^(urn:uuid:|#uuid\.)', '') else ''"/>
								<xsl:variable name="DPN-AHP-baseline-ts" select="//aixm:AirportHeliport[gml:identifier = $DPN_AHP_UUID]/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="DPN-AHP-max-seq" select="max($DPN-AHP-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="DPN-AHP-max-corr" select="max($DPN-AHP-baseline-ts[aixm:sequenceNumber = $DPN-AHP-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="DPN-AHP-valid-ts" select="$DPN-AHP-baseline-ts[aixm:sequenceNumber = $DPN-AHP-max-seq and aixm:correctionNumber = $DPN-AHP-max-corr][1]"/>
								<!-- Associated Aerodrome / Heliport - Identification -->
								<xsl:variable name="DPN_AHP_designator">
									<xsl:choose>
										<xsl:when test="not($DPN-AHP-valid-ts/aixm:designator)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($DPN-AHP-valid-ts/aixm:designator)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<!-- Associated Aerodrome / Heliport - ICAO Code -->
								<xsl:variable name="DPN_AHP_ICAO_code">
									<xsl:choose>
										<xsl:when test="not($DPN-AHP-valid-ts/aixm:locationIndicatorICAO)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($DPN-AHP-valid-ts/aixm:locationIndicatorICAO)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<!-- AHP Datum -->
								<xsl:variable name="AHP_datum">
									<xsl:value-of select="replace(replace($DPN-AHP-valid-ts/aixm:ARP/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
								</xsl:variable>
								<!-- AHP coordinates -->
								<xsl:variable name="DPN_AHP_coordinates" select="$DPN-AHP-valid-ts/aixm:ARP/aixm:ElevatedPoint/gml:pos"/>
								<xsl:variable name="DPN_AHP_latitude_decimal">
									<xsl:choose>
										<xsl:when test="$AHP_datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
											<xsl:value-of  select="number(substring-before($DPN_AHP_coordinates, ' '))"/>
										</xsl:when>
										<xsl:when test="matches($AHP_datum, '^OGC:.*CRS84$')">
											<xsl:value-of select="number(substring-after($DPN_AHP_coordinates, ' '))"/>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="DPN_AHP_longitude_decimal">
									<xsl:choose>
										<xsl:when test="$AHP_datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
											<xsl:value-of  select="number(substring-after($DPN_AHP_coordinates, ' '))"/>
										</xsl:when>
										<xsl:when test="matches($AHP_datum, '^OGC:.*CRS84$')">
											<xsl:value-of select="number(substring-before($DPN_AHP_coordinates, ' '))"/>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="DPN_AHP_latitude">
									<xsl:if test="string-length($DPN_AHP_latitude_decimal) gt 0">
										<xsl:value-of select="fcn:format-latitude($DPN_AHP_latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
								</xsl:variable>
								<xsl:variable name="DPN_AHP_longitude">
									<xsl:if test="string-length($DPN_AHP_longitude_decimal) gt 0">
										<xsl:value-of select="fcn:format-longitude($DPN_AHP_longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- RWY/FATO -->
								<xsl:variable name="RCP_UUID" select="replace(aixm:runwayPoint/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<!-- Get the RunwayCentrelinePoint feature from the DesignatedPoint -->
								<xsl:variable name="RCP-baseline-ts" select="//aixm:RunwayCentrelinePoint[gml:identifier = $RCP_UUID]/aixm:timeSlice/aixm:RunwayCentrelinePointTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="RCP-max-seq" select="max($RCP-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="RCP-max-corr" select="max($RCP-baseline-ts[aixm:sequenceNumber = $RCP-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="RCP-valid-ts" select="$RCP-baseline-ts[aixm:sequenceNumber = $RCP-max-seq and aixm:correctionNumber = $RCP-max-corr][1]"/>
								<!-- Get the RunwayDirection feature for the RunwayCentrelinePoint -->
								<xsl:variable name="RDN_UUID" select="replace($RCP-valid-ts/aixm:onRunway/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<xsl:variable name="RDN-baseline-ts" select="//aixm:RunwayDirection[gml:identifier = $RDN_UUID]/aixm:timeSlice/aixm:RunwayDirectionTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="RDN-max-seq" select="max($RDN-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="RDN-max-corr" select="max($RDN-baseline-ts[aixm:sequenceNumber = $RDN-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="RDN-valid-ts" select="$RDN-baseline-ts[aixm:sequenceNumber = $RDN-max-seq and aixm:correctionNumber = $RDN-max-corr][1]"/>
								<!-- Get the Runway feature for the RunwayDirection -->
								<xsl:variable name="RWY_UUID" select="replace($RDN-valid-ts/aixm:usedRunway/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<xsl:variable name="RWY-baseline-ts" select="//aixm:Runway[gml:identifier = $RWY_UUID]/aixm:timeSlice/aixm:RunwayTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="RWY-max-seq" select="max($RWY-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="RWY-max-corr" select="max($RWY-baseline-ts[aixm:sequenceNumber = $RWY-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="RWY-valid-ts" select="$RWY-baseline-ts[aixm:sequenceNumber = $RWY-max-seq and aixm:correctionNumber = $RWY-max-corr][1]"/>
								<!-- AirportHeliport associated with Runway -->
								<xsl:variable name="RWY_AHP_UUID" select="if ($RWY-valid-ts/aixm:associatedAirportHeliport/@xlink:href) then replace($RWY-valid-ts/aixm:associatedAirportHeliport/@xlink:href, '^(urn:uuid:|#uuid\.)', '') else ''"/>
								<xsl:variable name="RWY-AHP-baseline-ts" select="//aixm:AirportHeliport[gml:identifier = $RWY_AHP_UUID]/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="RWY-AHP-max-seq" select="max($RWY-AHP-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="RWY-AHP-max-corr" select="max($RWY-AHP-baseline-ts[aixm:sequenceNumber = $RWY-AHP-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="RWY-AHP-valid-ts" select="$RWY-AHP-baseline-ts[aixm:sequenceNumber = $RWY-AHP-max-seq and aixm:correctionNumber = $RWY-AHP-max-corr][1]"/>
																
								<!-- RWY -->
								<!-- RWY centre line Aerodrome / Heliport - Identification -->
								<xsl:variable name="RWY_AHP_designator">
									<xsl:if test="$RWY-valid-ts/aixm:type = 'RWY'">
										<xsl:choose>
											<xsl:when test="not($RWY-AHP-valid-ts/aixm:designator)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($RWY-AHP-valid-ts/aixm:designator)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								<!-- RWY centre line Aerodrome / Heliport - ICAO Code -->
								<xsl:variable name="RWY_AHP_ICAO_code">
									<xsl:if test="$RWY-valid-ts/aixm:type = 'RWY'">
										<xsl:choose>
											<xsl:when test="not($RWY-AHP-valid-ts/aixm:locationIndicatorICAO)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($RWY-AHP-valid-ts/aixm:locationIndicatorICAO)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								<!-- RWY centre line - Designator -->
								<xsl:variable name="RWY_designator">
									<xsl:if test="$RWY-valid-ts/aixm:type = 'RWY'">
										<xsl:choose>
											<xsl:when test="not($RWY-valid-ts/aixm:designator)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($RWY-valid-ts/aixm:designator)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								<!-- RWY RCP Datum -->
								<xsl:variable name="RWY_RCP_datum">
									<xsl:value-of select="replace(replace($RCP-valid-ts/aixm:location/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
								</xsl:variable>
								<!-- RWY RCP coordinates -->
								<xsl:variable name="RWY_RCP_coordinates" select="$RCP-valid-ts/aixm:location/aixm:ElevatedPoint/gml:pos"/>
								<xsl:variable name="RWY_RCP_latitude_decimal">
									<xsl:choose>
										<xsl:when test="$RWY_RCP_datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
											<xsl:value-of  select="number(substring-before($RWY_RCP_coordinates, ' '))"/>
										</xsl:when>
										<xsl:when test="matches($RWY_RCP_datum, '^OGC:.*CRS84$')">
											<xsl:value-of select="number(substring-after($RWY_RCP_coordinates, ' '))"/>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="RWY_RCP_longitude_decimal">
									<xsl:choose>
										<xsl:when test="$RWY_RCP_datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
											<xsl:value-of  select="number(substring-after($RWY_RCP_coordinates, ' '))"/>
										</xsl:when>
										<xsl:when test="matches($RWY_RCP_datum, '^OGC:.*CRS84$')">
											<xsl:value-of select="number(substring-before($RWY_RCP_coordinates, ' '))"/>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="RWY_RCP_latitude">
									<xsl:if test="string-length($RWY_RCP_latitude_decimal) gt 0 and $RWY-valid-ts/aixm:type = 'RWY'">
										<xsl:value-of select="fcn:format-latitude($RWY_RCP_latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
								</xsl:variable>
								<xsl:variable name="RWY_RCP_longitude">
									<xsl:if test="string-length($RWY_RCP_longitude_decimal) gt 0 and $RWY-valid-ts/aixm:type = 'RWY'">
										<xsl:value-of select="fcn:format-longitude($RWY_RCP_longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- FATO -->
								<!-- FATO centre line Aerodrome / Heliport - Identification -->
								<xsl:variable name="FATO_AHP_designator">
									<xsl:if test="$RWY-valid-ts/aixm:type = 'FATO'">
										<xsl:choose>
											<xsl:when test="not($RWY-AHP-valid-ts/aixm:designator)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($RWY-AHP-valid-ts/aixm:designator)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								<!-- FATO centre line Aerodrome / Heliport - ICAO Code -->
								<xsl:variable name="FATO_AHP_ICAO_code">
									<xsl:if test="$RWY-valid-ts/aixm:type = 'FATO'">
										<xsl:choose>
											<xsl:when test="not($RWY-AHP-valid-ts/aixm:locationIndicatorICAO)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($RWY-AHP-valid-ts/aixm:locationIndicatorICAO)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								<!-- FATO centre line TLOF - Designator -->
								<xsl:variable name="FATO_TLOF_designator">
									<xsl:if test="$RWY-valid-ts/aixm:type = 'FATO'">
										<!-- Find all TouchDownLiftOff features that point to this FATO -->
										<xsl:variable name="TLOF-for-FATO-baseline-ts" select="//aixm:TouchDownLiftOff/aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice[aixm:interpretation = 'BASELINE'][replace(aixm:approachTakeOffArea/@xlink:href, '^(urn:uuid:|#uuid\.)', '') = $RWY_UUID]"/>
										<xsl:variable name="TLOF-for-FATO-max-seq" select="max($TLOF-for-FATO-baseline-ts/aixm:sequenceNumber)"/>
										<xsl:variable name="TLOF-for-FATO-max-corr" select="max($TLOF-for-FATO-baseline-ts[aixm:sequenceNumber = $TLOF-for-FATO-max-seq]/aixm:correctionNumber)"/>
										<xsl:variable name="TLOF-for-FATO-valid-ts" select="$TLOF-for-FATO-baseline-ts[aixm:sequenceNumber = $TLOF-for-FATO-max-seq and aixm:correctionNumber = $TLOF-for-FATO-max-corr][1]"/>
										<xsl:choose>
											<xsl:when test="not($TLOF-for-FATO-valid-ts/aixm:designator)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($TLOF-for-FATO-valid-ts/aixm:designator)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								<!-- Final approach and take-off area [FATO] - Designator -->
								<xsl:variable name="FATO_designator">
									<xsl:if test="$RWY-valid-ts/aixm:type = 'FATO'">
										<xsl:choose>
											<xsl:when test="not($RWY-valid-ts/aixm:designator)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($RWY-valid-ts/aixm:designator)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								<!-- FATO RCP Datum -->
								<xsl:variable name="FATO_RCP_datum">
									<xsl:value-of select="replace(replace($RCP-valid-ts/aixm:location/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
								</xsl:variable>
								<!-- FATO RCP coordinates -->
								<xsl:variable name="FATO_RCP_coordinates" select="$RCP-valid-ts/aixm:location/aixm:ElevatedPoint/gml:pos"/>
								<xsl:variable name="FATO_RCP_latitude_decimal">
									<xsl:choose>
										<xsl:when test="$FATO_RCP_datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
											<xsl:value-of  select="number(substring-before($FATO_RCP_coordinates, ' '))"/>
										</xsl:when>
										<xsl:when test="matches($FATO_RCP_datum, '^OGC:.*CRS84$')">
											<xsl:value-of select="number(substring-after($FATO_RCP_coordinates, ' '))"/>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="FATO_RCP_longitude_decimal">
									<xsl:choose>
										<xsl:when test="$FATO_RCP_datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
											<xsl:value-of  select="number(substring-after($FATO_RCP_coordinates, ' '))"/>
										</xsl:when>
										<xsl:when test="matches($FATO_RCP_datum, '^OGC:.*CRS84$')">
											<xsl:value-of select="number(substring-before($FATO_RCP_coordinates, ' '))"/>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="FATO_RCP_latitude">
									<xsl:if test="string-length($FATO_RCP_latitude_decimal) gt 0 and $RWY-valid-ts/aixm:type = 'FATO'">
										<xsl:value-of select="fcn:format-latitude($FATO_RCP_latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
								</xsl:variable>
								<xsl:variable name="FATO_RCP_longitude">
									<xsl:if test="string-length($FATO_RCP_longitude_decimal) gt 0 and $RWY-valid-ts/aixm:type = 'FATO'">
										<xsl:value-of select="fcn:format-longitude($FATO_RCP_longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Geographical accuracy -->
								<xsl:variable name="DPN_geo_accuracy">
									<xsl:choose>
										<xsl:when test="not(aixm:location/aixm:Point/aixm:horizontalAccuracy)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:location/aixm:Point/aixm:horizontalAccuracy)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Unit of measurement [geographical accuracy] -->
								<xsl:variable name="DPN_geo_acc_uom">
									<xsl:value-of select="aixm:location/aixm:Point/aixm:horizontalAccuracy/@uom"/>
								</xsl:variable>
								
								<!-- Cyclic redundancy check -->
								<xsl:variable name="DPN_CRC">
									<xsl:if test="aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note, 'CRC:')]/aixm:note[not(@lang) or @lang=('en','eng')]">
										<xsl:value-of select="fcn:get-last-word(aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note, 'CRC:')]/aixm:note[not(@lang) or @lang=('en','eng')])"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Type -->
								<xsl:variable name="DPN_type">
									<xsl:choose>
										<xsl:when test="not(aixm:type)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:type)"/>
										</xsl:otherwise>
									</xsl:choose>
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
								
								<!-- Remarks -->
								<xsl:variable name="DPN_remarks">
									<xsl:variable name="dataset_creation_date" select="//aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
									<xsl:if test="string-length($dataset_creation_date) gt 0">
										<xsl:value-of select="concat('Current time: ', $dataset_creation_date)"/>
									</xsl:if>
									<xsl:for-each select="aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote">
										<xsl:if test="
											((../../aixm:propertyName and (not(../../aixm:propertyName/@xsi:nil='true') or not(../../aixm:propertyName/@xsi:nil))) or not(../../aixm:propertyName)) and
											not(contains(aixm:note, 'CRC:'))">
											<xsl:choose>
												<xsl:when test="string-length($dataset_creation_date) = 0">
													<xsl:value-of select="concat('(', if (../../aixm:propertyName) then (concat(../../aixm:propertyName, ';')) else '', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', ') ', fcn:get-annotation-text(aixm:note))"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="concat('&lt;br/&gt;', '(', if (../../aixm:propertyName) then (concat(../../aixm:propertyName, ';')) else '', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', ') ', fcn:get-annotation-text(aixm:note))"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:if>
									</xsl:for-each>
								</xsl:variable>
								
								<!-- Effective date -->
								<xsl:variable name="effective_date">
									<xsl:if test="gml:validTime/gml:TimePeriod/gml:beginPosition">
										<xsl:value-of select="fcn:get-date(gml:validTime/gml:TimePeriod/gml:beginPosition)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Committed on -->
								<xsl:variable name="commit_date">
									<xsl:if test="aixm:extension/ead-audit:DesignatedPointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate">
										<xsl:value-of select="fcn:get-date(aixm:extension/ead-audit:DesignatedPointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Internal UID (master) -->
								<xsl:variable name="DPN_UUID">
									<xsl:value-of select="../../gml:identifier"/>
								</xsl:variable>
								
								<!-- DesignatedPoint - Valid TimeSlice -->
								<xsl:variable name="DPN_timeslice">
									<xsl:value-of select="concat('BASELINE ', $max-sequence, '.', $max-correction)"/>
								</xsl:variable>
								
								<!-- FIR - Coded identifier -->
								<xsl:variable name="FIR_info" as="map(xs:string, xs:string)?">
									<xsl:choose>
										<xsl:when test="string($DPN_latitude_decimal) != '' and string($DPN_longitude_decimal) != ''">
											<xsl:sequence select="fcn:find-containing-fir-optimized($DPN_latitude_decimal, $DPN_longitude_decimal, $fir-geometry-cache, $doc-root)"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:sequence select="()"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="FIR_designator" select="if (exists($FIR_info) and map:contains($FIR_info, 'designator')) then string($FIR_info?designator) else ''" as="xs:string"/>
								
								<!-- FIR - Valid TimeSlice -->
								<xsl:variable name="FIR_timeslice" select="if (exists($FIR_info) and map:contains($FIR_info, 'sequenceNumber')) then concat('BASELINE ', $FIR_info?sequenceNumber, '.', $FIR_info?correctionNumber) else ''" as="xs:string"/>
								
								<!-- Originator -->
								<xsl:variable name="originator">
									<xsl:value-of select="aixm:extension/ead-audit:DesignatedPointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
								</xsl:variable>
								
								<tr style="white-space:nowrap;">
									<td><xsl:value-of select="if (string-length($DPN_designator) gt 0) then $DPN_designator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DPN_latitude) gt 0) then $DPN_latitude else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DPN_longitude) gt 0) then $DPN_longitude else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($TLOF_AHP_designator) gt 0) then $TLOF_AHP_designator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($TLOF_AHP_ICAO_code) gt 0) then $TLOF_AHP_ICAO_code else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($TLOF_designator) gt 0) then $TLOF_designator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DPN_AHP_designator) gt 0) then $DPN_AHP_designator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DPN_AHP_ICAO_code) gt 0) then $DPN_AHP_ICAO_code else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DPN_AHP_latitude) gt 0) then $DPN_AHP_latitude else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DPN_AHP_longitude) gt 0) then $DPN_AHP_longitude else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RWY_AHP_designator) gt 0) then $RWY_AHP_designator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RWY_AHP_ICAO_code) gt 0) then $RWY_AHP_ICAO_code else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RWY_designator) gt 0) then $RWY_designator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RWY_RCP_latitude) gt 0) then $RWY_RCP_latitude else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($RWY_RCP_longitude) gt 0) then $RWY_RCP_longitude else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($FATO_AHP_designator) gt 0) then $FATO_AHP_designator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($FATO_AHP_ICAO_code) gt 0) then $FATO_AHP_ICAO_code else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($FATO_TLOF_designator) gt 0) then $FATO_TLOF_designator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($FATO_designator) gt 0) then $FATO_designator else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($FATO_RCP_latitude) gt 0) then $FATO_RCP_latitude else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($FATO_RCP_longitude) gt 0) then $FATO_RCP_longitude else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DPN_datum) gt 0) then $DPN_datum else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DPN_geo_accuracy) gt 0) then $DPN_geo_accuracy else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DPN_geo_acc_uom) gt 0) then $DPN_geo_acc_uom else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DPN_CRC) gt 0) then $DPN_CRC else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DPN_type) gt 0) then $DPN_type else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DPN_name) gt 0) then $DPN_name else '&#160;'"/></td>
									<td style="min-width:600px;white-space:normal" xml:space="preserve"><xsl:choose><xsl:when test="string-length($DPN_remarks) gt 0"><xsl:value-of select="$DPN_remarks" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
									<td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($commit_date) gt 0) then $commit_date else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DPN_UUID) gt 0) then $DPN_UUID else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($DPN_timeslice) gt 0) then $DPN_timeslice else '&#160;'"/></td>
									<td><xsl:value-of select="if (string-length($FIR_designator) gt 0) then $FIR_designator else '&#160;'"/></td>
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
				<xsl:variable name="rule_uuid">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'extractionRulesUuid: '), ',')"/>
				</xsl:variable>
				
				<!-- interestedInDataAt -->
				<xsl:variable name="interest_date">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'interestedInDataAt: '), ',')"/>
				</xsl:variable>
				
				<!-- featureTypes -->
				<xsl:variable name="feat_types">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'featureTypes: '), ',')"/>
				</xsl:variable>
				
				<!-- excludedProperties -->
				<xsl:variable name="exc_properties">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'excludedProperties: '), ',')"/>
				</xsl:variable>
				
				<!-- includeReferencedFeaturesLevel -->
				<xsl:variable name="referenced_feat_level">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'includeReferencedFeaturesLevel: '), ',')"/>
				</xsl:variable>
				
				<!-- featureOccurrence -->
				<xsl:variable name="feat_occurrence">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'featureOccurrence: '), ',')"/>
				</xsl:variable>
				
				<!-- effectiveDateStart -->
				<xsl:variable name="eff_date_start">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'effectiveDateStart: '), ',')"/>
				</xsl:variable>
				
				<!-- effectiveDateEnd -->
				<xsl:variable name="eff_date_end">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'effectiveDateEnd: '), ',')"/>
				</xsl:variable>
				
				<!-- referencedDataFeature -->
				<xsl:variable name="referenced_data_feat">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'referencedDataFeature: '), ',')"/>
				</xsl:variable>
				
				<!-- permanentBaseline -->
				<xsl:variable name="perm_BL">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'permanentBaseline: '), ',')"/>
				</xsl:variable>
				
				<!-- permanentPermdelta -->
				<xsl:variable name="perm_PD">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'permanentPermdelta: '), ',')"/>
				</xsl:variable>
				
				<!-- temporaryData -->
				<xsl:variable name="temp_data">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'temporaryData: '), ',')"/>
				</xsl:variable>
				
				<!-- permanentBaselineForTemporaryData -->
				<xsl:variable name="perm_BS_for_temp_data">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'permanentBaselineForTemporaryData: '), ',')"/>
				</xsl:variable>
				
				<!-- spatialFilteringBy -->
				<xsl:variable name="spatial_filtering">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'spatialFilteringBy: '), ',')"/>
				</xsl:variable>
				
				<!-- spatialAreaUUID -->
				<xsl:variable name="spatial_area_uuid">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'spatialAreaUUID: '), ',')"/>
				</xsl:variable>
				
				<!-- spatialAreaBuffer -->
				<xsl:variable name="spatial_area_buffer">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'spatialAreaBuffer: '), ',')"/>
				</xsl:variable>
				
				<!-- spatialOperator -->
				<xsl:variable name="spatial_operator">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'spatialOperator: '), ',')"/>
				</xsl:variable>
				
				<!-- spatialValueOperator -->
				<xsl:variable name="spatial_value_operator">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'spatialValueOperator: '), ',')"/>
				</xsl:variable>
				
				<!-- dataBranch -->
				<xsl:variable name="data_branch">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'dataBranch: '), ',')"/>
				</xsl:variable>
				
				<!-- dataScope -->
				<xsl:variable name="data_scope">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'dataScope: '), ',')"/>
				</xsl:variable>
				
				<!-- dataProviderOrganization -->
				<xsl:variable name="data_provider_org">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'dataProviderOrganization: '), ',')"/>
				</xsl:variable>
				
				<!-- systemExtension -->
				<xsl:variable name="system_extension">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'systemExtension: '), ',')"/>
				</xsl:variable>
				
				<!-- AIXMversion -->
				<xsl:variable name="AIXM_ver">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'AIXMversion: '), ',')"/>
				</xsl:variable>
				
				<!-- indirectReferences -->
				<xsl:variable name="indirect_references">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'indirectReferences: '), ',')"/>
				</xsl:variable>
				
				<!-- dataType -->
				<xsl:variable name="data_type">
					<xsl:variable name="after_key" select="substring-after($rule_parameters, 'dataType: ')"/>
					<xsl:value-of select="if (contains($after_key, ',')) then substring-before($after_key, ',') else $after_key"/>
				</xsl:variable>
				
				<!-- CustomizationAirspaceCircleArcToPolygon -->
				<xsl:variable name="arc_to_polygon">
					<xsl:variable name="after_key" select="substring-after($rule_parameters, 'CustomizationAirspaceCircleArcToPolygon: ')"/>
					<xsl:value-of select="if (contains($after_key, ',')) then substring-before($after_key, ',') else $after_key"/>
				</xsl:variable>
				
				<p><font size="-1">Extraction rule parameters used for this report:</font></p>
				
				<table>
					<tr>
						<td><font size="-1">extractionRulesUUID: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($rule_uuid) gt 0) then $rule_uuid else '&#160;'"/></font>
						</td>
					</tr>
					<tr>
						<td><font size="-1">interestedInDataAt: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($interest_date) gt 0) then $interest_date else '&#160;'"/></font></td>
					</tr>
					<tr style="vertical-align:top">
						<td><font size="-1">featureTypes: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($feat_types) gt 0) then $feat_types else '&#160;'"/></font></td>
					</tr>
					<tr style="vertical-align:top">
						<td><font size="-1">excludedProperties: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($exc_properties) gt 0) then $exc_properties else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">includeReferencedFeaturesLevel: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($referenced_feat_level) gt 0) then $referenced_feat_level else '&#160;'"/></font></td>
					</tr>
					<tr style="vertical-align:top">
						<td><font size="-1">featureOccurrence: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($feat_occurrence) gt 0) then $feat_occurrence else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">effectiveDateStart: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($eff_date_start) gt 0) then $eff_date_start else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">effectiveDateEnd: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($eff_date_end) gt 0) then $eff_date_end else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">referencedDataFeature: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($referenced_data_feat) gt 0) then $referenced_data_feat else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">permanentBaseline: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($perm_BL) gt 0) then $perm_BL else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">permanentPermdelta: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($perm_PD) gt 0) then $perm_PD else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">temporaryData: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($temp_data) gt 0) then $temp_data else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">permanentBaselineForTemporaryData: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($perm_BS_for_temp_data) gt 0) then $perm_BS_for_temp_data else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">spatialFilteringBy: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($spatial_filtering) gt 0) then $spatial_filtering else '&#160;'"/></font></td>
					</tr>
					<tr style="vertical-align:top">
						<td><font size="-1">spatialAreaUUID: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($spatial_area_uuid) gt 0) then $spatial_area_uuid else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">spatialAreaBuffer: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($spatial_area_buffer) gt 0) then $spatial_area_buffer else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">spatialOperator: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($spatial_operator) gt 0) then $spatial_operator else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">spatialValueOperator: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($spatial_value_operator) gt 0) then $spatial_value_operator else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">dataBranch: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($data_branch) gt 0) then $data_branch else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">dataScope: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($data_scope) gt 0) then $data_scope else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">dataProviderOrganization: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($data_provider_org) gt 0) then $data_provider_org else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">systemExtension: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($system_extension) gt 0) then $system_extension else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">AIXMversion: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($AIXM_ver) gt 0) then $AIXM_ver else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">indirectReferences: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($indirect_references) gt 0) then $indirect_references else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">dataType: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($data_type) gt 0) then $data_type else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">CustomizationAirspaceCircleArcToPolygon: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($arc_to_polygon) gt 0) then $arc_to_polygon else '&#160;'"/></font></td>
					</tr>
				</table>
				
				<p></p>
				<table>
					<tr>
						<td><font size="-1">Sorting by column: </font></td>
						<td><font size="-1">Identification</font></td>
					</tr>
					<tr>
						<td><font size="-1">Sorting order: </font></td>
						<td><font size="-1">ascending</font></td>
					</tr>
				</table>
				
				<p>***&#160;END OF REPORT&#160;***</p>
				
			</body>
			
		</html>
		
	</xsl:template>
	
</xsl:transform>