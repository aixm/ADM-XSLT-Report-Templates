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
	                  featureTypes: aixm:DesignatedPoint aixm:Airspace
	includeReferencedFeaturesLevel: 3
	             featureOccurrence: aixm:Airspace.aixm:type EQUALS 'FIR'
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
	xmlns:saxon="http://saxon.sf.net/"
	exclude-result-prefixes="xsl uuid message gts gco xsd gml gss gsr gmd aixm event xlink xs xsi aixm_ds_xslt ead-audit fcn math map saxon">
	
	<xsl:output method="html" indent="yes" saxon:line-length="999999"/>
	
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
	
	<!-- Function to extract all polygon coordinates from a geometry including referenced GeoBorders -->
	<xsl:function name="fcn:get-all-polygon-coords" as="xs:double*">
		<xsl:param name="airspace-volume" as="element()?"/>
		<xsl:param name="root" as="document-node()"/>
		<xsl:variable name="coords" as="xs:double*">
			<!-- Process curveMember elements in their actual document order to maintain polygon sequence -->
			<xsl:for-each select="$airspace-volume//gml:Ring/gml:curveMember">
				<xsl:choose>
					<!-- Handle xlink reference to GeoBorder FIRST (check before checking for posList) -->
					<xsl:when test="@xlink:href and starts-with(@xlink:href, 'urn:uuid:')">
						<xsl:variable name="uuid" select="substring-after(@xlink:href, 'urn:uuid:')"/>
						<!-- Get the GeoBorder and find its latest BASELINE timeslice -->
						<xsl:variable name="geoborder" select="$root//aixm:GeoBorder[gml:identifier = $uuid]"/>
						<xsl:variable name="gb-baseline-ts" select="$geoborder/aixm:timeSlice/aixm:GeoBorderTimeSlice[aixm:interpretation = 'BASELINE']"/>
						<xsl:variable name="gb-max-seq" select="max($gb-baseline-ts/aixm:sequenceNumber)"/>
						<xsl:variable name="gb-max-corr" select="max($gb-baseline-ts[aixm:sequenceNumber = $gb-max-seq]/aixm:correctionNumber)"/>
						<xsl:variable name="gb-latest-ts" select="$gb-baseline-ts[aixm:sequenceNumber = $gb-max-seq and aixm:correctionNumber = $gb-max-corr][1]"/>
						<!-- Extract coordinates from the latest timeslice only, preserving segment order -->
						<xsl:for-each select="$gb-latest-ts/aixm:border//gml:posList">
							<xsl:sequence select="for $coord in tokenize(normalize-space(.), '\s+') return xs:double($coord)"/>
						</xsl:for-each>
					</xsl:when>
					<!-- Handle direct coordinates (including both GeodesicString and LineStringSegment) -->
					<xsl:when test=".//gml:posList">
						<!-- Process all posList elements in this curveMember in order -->
						<xsl:for-each select=".//gml:posList">
							<xsl:sequence select="for $coord in tokenize(normalize-space(.), '\s+') return xs:double($coord)"/>
						</xsl:for-each>
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<!-- Remove consecutive duplicate coordinate pairs (degenerate edges) -->
		<xsl:variable name="epsilon" select="0.000001" as="xs:double"/>
		<xsl:variable name="deduplicated" as="xs:double*">
			<xsl:for-each select="1 to count($coords) div 2">
				<xsl:variable name="idx" select=". * 2 - 1"/>
				<xsl:variable name="lat" select="$coords[$idx]"/>
				<xsl:variable name="lon" select="$coords[$idx + 1]"/>
				<!-- Only include this point if it's different from the previous point -->
				<xsl:if test=". = 1 or abs($lat - $coords[$idx - 2]) ge $epsilon or abs($lon - $coords[$idx - 1]) ge $epsilon">
					<xsl:sequence select="$lat"/>
					<xsl:sequence select="$lon"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:sequence select="$deduplicated"/>
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
	
	<!-- Function to get the latest BASELINE timeslice for an Airspace -->
	<xsl:function name="fcn:get-latest-airspace-timeslice" as="element()?">
		<xsl:param name="airspace" as="element()?"/>
		<xsl:variable name="baseline-timeslices" select="$airspace/aixm:timeSlice/aixm:AirspaceTimeSlice[aixm:interpretation = 'BASELINE']"/>
		<xsl:variable name="max-sequence" select="max($baseline-timeslices/aixm:sequenceNumber)"/>
		<xsl:variable name="max-correction" select="max($baseline-timeslices[aixm:sequenceNumber = $max-sequence]/aixm:correctionNumber)"/>
		<xsl:sequence select="$baseline-timeslices[aixm:sequenceNumber = $max-sequence and aixm:correctionNumber = $max-correction][1]"/>
	</xsl:function>
	
	<!-- Function to find the FIR containing a given point -->
	<xsl:function name="fcn:find-containing-fir" as="map(xs:string, xs:string)?">
		<xsl:param name="lat" as="xs:double"/>
		<xsl:param name="lon" as="xs:double"/>
		<xsl:param name="root" as="document-node()"/>
		<!-- Get all FIR and FIR_P Airspaces -->
		<xsl:variable name="fir-airspaces" select="$root//aixm:Airspace[aixm:timeSlice/aixm:AirspaceTimeSlice[aixm:type = ('FIR', 'FIR_P')]]"/>
		<xsl:variable name="containing-airspaces" as="element()*">
			<xsl:for-each select="$fir-airspaces">
				<xsl:variable name="airspace" select="."/>
				<xsl:variable name="latest-ts" select="fcn:get-latest-airspace-timeslice($airspace)"/>
				<xsl:if test="$latest-ts">
					<!-- Get geometry - handle both direct geometry and contributorAirspace references -->
					<xsl:variable name="geom-components" select="$latest-ts/aixm:geometryComponent/aixm:AirspaceGeometryComponent"/>
					<xsl:for-each select="$geom-components">
						<xsl:variable name="airspace-volume" select="aixm:theAirspaceVolume/aixm:AirspaceVolume"/>
						<xsl:choose>
							<!-- Direct geometry -->
							<xsl:when test="$airspace-volume/aixm:horizontalProjection">
								<xsl:variable name="coords" select="fcn:get-all-polygon-coords($airspace-volume/aixm:horizontalProjection, $root)"/>
								<xsl:if test="count($coords) ge 6 and fcn:point-in-polygon($lat, $lon, $coords)">
									<xsl:sequence select="$airspace"/>
								</xsl:if>
							</xsl:when>
							<!-- Reference to another airspace (FIR composed of FIR_P) -->
							<xsl:when test="$airspace-volume/aixm:contributorAirspace">
								<xsl:for-each select="$airspace-volume/aixm:contributorAirspace/aixm:AirspaceVolumeDependency">
									<xsl:variable name="ref-uuid" select="substring-after(aixm:theAirspace/@xlink:href, 'urn:uuid:')"/>
									<xsl:variable name="ref-airspace" select="$root//aixm:Airspace[gml:identifier = $ref-uuid]"/>
									<xsl:variable name="ref-latest-ts" select="fcn:get-latest-airspace-timeslice($ref-airspace)"/>
									<xsl:if test="$ref-latest-ts">
										<xsl:variable name="ref-volume" select="$ref-latest-ts/aixm:geometryComponent/aixm:AirspaceGeometryComponent/aixm:theAirspaceVolume/aixm:AirspaceVolume"/>
										<xsl:variable name="ref-coords" select="fcn:get-all-polygon-coords($ref-volume/aixm:horizontalProjection, $root)"/>
										<xsl:if test="count($ref-coords) ge 6 and fcn:point-in-polygon($lat, $lon, $ref-coords)">
											<xsl:sequence select="$ref-airspace"/>
										</xsl:if>
									</xsl:if>
								</xsl:for-each>
							</xsl:when>
						</xsl:choose>
					</xsl:for-each>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<!-- Process the first containing airspace found (prefer FIR over FIR_P) -->
		<xsl:variable name="containing-airspace" select="
			if (exists($containing-airspaces)) then
			(($containing-airspaces[fcn:get-latest-airspace-timeslice(.)/aixm:type = 'FIR'])[1],
			$containing-airspaces[1])[1]
			else ()
			"/>
		<xsl:if test="$containing-airspace">
			<xsl:variable name="airspace-ts" select="fcn:get-latest-airspace-timeslice($containing-airspace)"/>
			<xsl:variable name="airspace-type" select="$airspace-ts/aixm:type"/>
			<xsl:choose>
				<!-- If it's a FIR_P, find the parent FIR -->
				<xsl:when test="$airspace-type = 'FIR_P'">
					<xsl:variable name="fir-p-uuid" select="$containing-airspace/gml:identifier"/>
					<!-- Find FIR that references this FIR_P -->
					<xsl:variable name="parent-fir" select="($root//aixm:Airspace[aixm:timeSlice/aixm:AirspaceTimeSlice[aixm:type = 'FIR' and aixm:geometryComponent/aixm:AirspaceGeometryComponent/aixm:theAirspaceVolume/aixm:AirspaceVolume/aixm:contributorAirspace/aixm:AirspaceVolumeDependency/aixm:theAirspace/@xlink:href = concat('urn:uuid:', $fir-p-uuid)]])[1]"/>
					<xsl:if test="$parent-fir">
						<xsl:variable name="parent-ts" select="fcn:get-latest-airspace-timeslice($parent-fir)"/>
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
						'designator': string($airspace-ts/aixm:designator),
						'sequenceNumber': string($airspace-ts/aixm:sequenceNumber),
						'correctionNumber': string($airspace-ts/aixm:correctionNumber)
						}"/>
				</xsl:when>
			</xsl:choose>
		</xsl:if>
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
				<mark>DISCLAIMER</mark> For some features the XSLT transformation might not successfully identify the <i>FIR - Coded identifier</i>
				<hr/>
				
				<table border="0" style="white-space:nowrap">
					<tbody>
						
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
							<td><strong>TLOF centre Aerodrome / Heliport - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>TLOF centre Aerodrome / Heliport - ICAO Code</strong></td>
						</tr>
						<tr>
							<td><strong>TLOF centre - Designator</strong></td>
						</tr>
						<tr>
							<td><strong>Associated Aerodrome / Heliport - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>Associated Aerodrome / Heliport - ICAO Code</strong></td>
						</tr>
						<tr>
							<td><strong>ARP Aerodrome / Heliport - Latitude</strong></td>
						</tr>
						<tr>
							<td><strong>ARP Aerodrome / Heliport - Longitude</strong></td>
						</tr>
						<tr>
							<td><strong>RWY centre line Aerodrome / Heliport - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>RWY centre line Aerodrome / Heliport - ICAO Code</strong></td>
						</tr>
						<tr>
							<td><strong>RWY centre line - Designator</strong></td>
						</tr>
						<tr>
							<td><strong>RWY centre line - Latitude</strong></td>
						</tr>
						<tr>
							<td><strong>RWY centre line - Longitude</strong></td>
						</tr>
						<tr>
							<td><strong>FATO centre line Aerodrome / Heliport - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>FATO centre line Aerodrome / Heliport - ICAO Code</strong></td>
						</tr>
						<tr>
							<td><strong>FATO centre line TLOF - Designator</strong></td>
						</tr>
						<tr>
							<td><strong>Final approach and take-off area [FATO] - Designator</strong></td>
						</tr>
						<tr>
							<td><strong>FATO centre line - Latitude</strong></td>
						</tr>
						<tr>
							<td><strong>FATO centre line - Longitude</strong></td>
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
							<td><strong>Cyclic redundancy check</strong></td>
						</tr>
						<tr>
							<td><strong>Type</strong></td>
						</tr>
						<tr>
							<td><strong>Name</strong></td>
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
							<td><strong>DesignatedPoint - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>FIR - Coded identifier</strong></td>
						</tr>
						<tr>
							<td><strong>FIR - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>Originator</strong></td>
						</tr>
						<tr>
							<td>&#160;</td>
						</tr>
						<tr>
							<td>&#160;</td>
						</tr>
						
						<!-- Capture document root before iterating through DesignatedPoints -->
						<xsl:variable name="doc-root" select="/" as="document-node()"/>

						<xsl:for-each select="//aixm:DesignatedPoint">
							
							<xsl:sort select="(aixm:timeSlice/aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)][aixm:correctionNumber = max(../aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)]/aixm:correctionNumber)])[1]/aixm:designator" order="ascending"/>
							
							<!-- Get all BASELINE time slices for this DesignatedPoint -->
							<xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE']"/>
							<!-- Find the maximum sequenceNumber -->
							<xsl:variable name="max-sequence" select="max($baseline-timeslices/aixm:sequenceNumber)"/>
							<!-- Get time slices with the maximum sequenceNumber, then find max correctionNumber -->
							<xsl:variable name="max-correction" select="max($baseline-timeslices[aixm:sequenceNumber = $max-sequence]/aixm:correctionNumber)"/>
							<!-- Select the latest time slice -->
							<xsl:variable name="latest-timeslice" select="$baseline-timeslices[aixm:sequenceNumber = $max-sequence and aixm:correctionNumber = $max-correction][1]"/>
							
							<xsl:for-each select="$latest-timeslice">
								
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
								
								<!-- Latitude and Longitude -->
								
								<!-- Select the type of coordinates: 'DMS' or 'DEC' -->
								<xsl:variable name="coordinates_type" select="'DMS'"/>
								
								<!-- Select the number of decimals -->
								<xsl:variable name="coordinates_decimal_number" select="2"/>
								
								<xsl:variable name="DPN_coordinates" select="aixm:location/aixm:Point/gml:pos"/>
								<xsl:variable name="DPN_latitude_decimal" select="number(substring-before($DPN_coordinates, ' '))"/>
								<xsl:variable name="DPN_longitude_decimal" select="number(substring-after($DPN_coordinates, ' '))"/>
								<xsl:variable name="DPN_latitude">
									<xsl:value-of select="fcn:format-latitude($DPN_latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
								</xsl:variable>
								<xsl:variable name="DPN_longitude">
									<xsl:value-of select="fcn:format-longitude($DPN_longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
								</xsl:variable>
								
								<!-- TLOF -->
								<xsl:variable name="TLOF_UUID" select="if (aixm:aimingPoint/@xlink:href) then replace(aixm:aimingPoint/@xlink:href, '^(urn:uuid:|#uuid\.)', '') else ''"/>
								<xsl:variable name="TLOF-baseline-ts" select="//aixm:TouchDownLiftOff[gml:identifier = $TLOF_UUID]/aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="TLOF-max-seq" select="max($TLOF-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="TLOF-max-corr" select="max($TLOF-baseline-ts[aixm:sequenceNumber = $TLOF-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="TLOF-latest-ts" select="$TLOF-baseline-ts[aixm:sequenceNumber = $TLOF-max-seq and aixm:correctionNumber = $TLOF-max-corr][1]"/>
								<xsl:variable name="TLOF_AHP_UUID">
									<xsl:if test="$TLOF-latest-ts/aixm:associatedAirportHeliport/@xlink:href">
										<xsl:value-of select="replace($TLOF-latest-ts/aixm:associatedAirportHeliport/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
									</xsl:if>
								</xsl:variable>
								<!-- TLOF centre - Designator -->
								<xsl:variable name="TLOF_designator">
									<xsl:choose>
										<xsl:when test="not($TLOF-latest-ts/aixm:designator)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($TLOF-latest-ts/aixm:designator)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<!-- AHP containing the TLOF -->
								<!-- Get the latest BASELINE TimeSlice for this AHP -->
								<xsl:variable name="TLOF-AHP-baseline-ts" select="//aixm:AirportHeliport[gml:identifier = $TLOF_AHP_UUID]/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="TLOF-AHP-max-seq" select="max($TLOF-AHP-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="TLOF-AHP-max-corr" select="max($TLOF-AHP-baseline-ts[aixm:sequenceNumber = $TLOF-AHP-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="TLOF-AHP-latest-ts" select="$TLOF-AHP-baseline-ts[aixm:sequenceNumber = $TLOF-AHP-max-seq and aixm:correctionNumber = $TLOF-AHP-max-corr][1]"/>
								<!-- TLOF centre Aerodrome / Heliport - Identification -->
								<xsl:variable name="TLOF_AHP_designator">
									<xsl:choose>
										<xsl:when test="not($TLOF-AHP-latest-ts/aixm:designator)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($TLOF-AHP-latest-ts/aixm:designator)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<!-- TLOF centre Aerodrome / Heliport - ICAO Code -->
								<xsl:variable name="TLOF_AHP_ICAO_code">
									<xsl:choose>
										<xsl:when test="not($TLOF-AHP-latest-ts/aixm:locationIndicatorICAO)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($TLOF-AHP-latest-ts/aixm:locationIndicatorICAO)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Associated Aerodrome / Heliport -->
								<xsl:variable name="DPN_AHP_UUID" select="if (aixm:airportHeliport/@xlink:href) then replace(aixm:airportHeliport/@xlink:href, '^(urn:uuid:|#uuid\.)', '') else ''"/>
								<xsl:variable name="DPN-AHP-baseline-ts" select="//aixm:AirportHeliport[gml:identifier = $DPN_AHP_UUID]/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="DPN-AHP-max-seq" select="max($DPN-AHP-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="DPN-AHP-max-corr" select="max($DPN-AHP-baseline-ts[aixm:sequenceNumber = $DPN-AHP-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="DPN-AHP-latest-ts" select="$DPN-AHP-baseline-ts[aixm:sequenceNumber = $DPN-AHP-max-seq and aixm:correctionNumber = $DPN-AHP-max-corr][1]"/>
								<!-- Associated Aerodrome / Heliport - Identification -->
								<xsl:variable name="DPN_AHP_designator">
									<xsl:choose>
										<xsl:when test="not($DPN-AHP-latest-ts/aixm:designator)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($DPN-AHP-latest-ts/aixm:designator)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<!-- Associated Aerodrome / Heliport - ICAO Code -->
								<xsl:variable name="DPN_AHP_ICAO_code">
									<xsl:choose>
										<xsl:when test="not($DPN-AHP-latest-ts/aixm:locationIndicatorICAO)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($DPN-AHP-latest-ts/aixm:locationIndicatorICAO)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<!-- AHP coordinates -->
								<xsl:variable name="DPN_AHP_coordinates" select="$DPN-AHP-latest-ts/aixm:ARP/aixm:ElevatedPoint/gml:pos"/>
								<xsl:variable name="DPN_AHP_latitude_decimal" select="number(substring-before($DPN_AHP_coordinates, ' '))"/>
								<xsl:variable name="DPN_AHP_longitude_decimal" select="number(substring-after($DPN_AHP_coordinates, ' '))"/>
								<!-- ARP Aerodrome / Heliport - Latitude -->
								<xsl:variable name="DPN_AHP_ARP_lat" select="if ($DPN-AHP-latest-ts/aixm:ARP/aixm:ElevatedPoint/gml:pos) then fcn:format-latitude($DPN_AHP_latitude_decimal, $coordinates_type, $coordinates_decimal_number) else ''"/>
								<!-- ARP Aerodrome / Heliport - Longitude -->
								<xsl:variable name="DPN_AHP_ARP_long" select="if ($DPN-AHP-latest-ts/aixm:ARP/aixm:ElevatedPoint/gml:pos) then fcn:format-longitude($DPN_AHP_longitude_decimal, $coordinates_type, $coordinates_decimal_number) else ''"/>
								
								<!-- RWY/FATO -->
								<xsl:variable name="RCP_UUID" select="replace(aixm:runwayPoint/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<!-- Get the RunwayCentrelinePoint feature from the DesignatedPoint -->
								<xsl:variable name="RCP-baseline-ts" select="//aixm:RunwayCentrelinePoint[gml:identifier = $RCP_UUID]/aixm:timeSlice/aixm:RunwayCentrelinePointTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="RCP-max-seq" select="max($RCP-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="RCP-max-corr" select="max($RCP-baseline-ts[aixm:sequenceNumber = $RCP-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="RCP-latest-ts" select="$RCP-baseline-ts[aixm:sequenceNumber = $RCP-max-seq and aixm:correctionNumber = $RCP-max-corr][1]"/>
								<!-- Get the RunwayDirection feature for the RunwayCentrelinePoint -->
								<xsl:variable name="RDN_UUID" select="replace($RCP-latest-ts/aixm:onRunway/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<xsl:variable name="RDN-baseline-ts" select="//aixm:RunwayDirection[gml:identifier = $RDN_UUID]/aixm:timeSlice/aixm:RunwayDirectionTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="RDN-max-seq" select="max($RDN-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="RDN-max-corr" select="max($RDN-baseline-ts[aixm:sequenceNumber = $RDN-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="RDN-latest-ts" select="$RDN-baseline-ts[aixm:sequenceNumber = $RDN-max-seq and aixm:correctionNumber = $RDN-max-corr][1]"/>
								<!-- Get the Runway feature for the RunwayDirection -->
								<xsl:variable name="RWY_UUID" select="replace($RDN-latest-ts/aixm:usedRunway/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<xsl:variable name="RWY-baseline-ts" select="//aixm:Runway[gml:identifier = $RWY_UUID]/aixm:timeSlice/aixm:RunwayTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="RWY-max-seq" select="max($RWY-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="RWY-max-corr" select="max($RWY-baseline-ts[aixm:sequenceNumber = $RWY-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="RWY-latest-ts" select="$RWY-baseline-ts[aixm:sequenceNumber = $RWY-max-seq and aixm:correctionNumber = $RWY-max-corr][1]"/>
								<!-- AirportHeliport associated with Runway -->
								<xsl:variable name="RWY_AHP_UUID" select="if ($RWY-latest-ts/aixm:associatedAirportHeliport/@xlink:href) then replace($RWY-latest-ts/aixm:associatedAirportHeliport/@xlink:href, '^(urn:uuid:|#uuid\.)', '') else ''"/>
								<xsl:variable name="RWY-AHP-baseline-ts" select="//aixm:AirportHeliport[gml:identifier = $RWY_AHP_UUID]/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="RWY-AHP-max-seq" select="max($RWY-AHP-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="RWY-AHP-max-corr" select="max($RWY-AHP-baseline-ts[aixm:sequenceNumber = $RWY-AHP-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="RWY-AHP-latest-ts" select="$RWY-AHP-baseline-ts[aixm:sequenceNumber = $RWY-AHP-max-seq and aixm:correctionNumber = $RWY-AHP-max-corr][1]"/>
																
								<!-- RWY -->
								<!-- RWY centre line Aerodrome / Heliport - Identification -->
								<xsl:variable name="RWY_AHP_designator">
									<xsl:if test="$RWY-latest-ts/aixm:type = 'RWY'">
										<xsl:choose>
											<xsl:when test="not($RWY-AHP-latest-ts/aixm:designator)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($RWY-AHP-latest-ts/aixm:designator)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								<!-- RWY centre line Aerodrome / Heliport - ICAO Code -->
								<xsl:variable name="RWY_AHP_ICAO_code">
									<xsl:if test="$RWY-latest-ts/aixm:type = 'RWY'">
										<xsl:choose>
											<xsl:when test="not($RWY-AHP-latest-ts/aixm:locationIndicatorICAO)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($RWY-AHP-latest-ts/aixm:locationIndicatorICAO)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								<!-- RWY centre line - Designator -->
								<xsl:variable name="RWY_designator">
									<xsl:if test="$RWY-latest-ts/aixm:type = 'RWY'">
										<xsl:choose>
											<xsl:when test="not($RWY-latest-ts/aixm:designator)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($RWY-latest-ts/aixm:designator)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								<!-- RWY RCP coordinates -->
								<xsl:variable name="RWY_RCP_coordinates" select="$RCP-latest-ts/aixm:location/aixm:ElevatedPoint/gml:pos"/>
								<xsl:variable name="RWY_RCP_latitude_decimal" select="number(substring-before($RWY_RCP_coordinates, ' '))"/>
								<xsl:variable name="RWY_RCP_longitude_decimal" select="number(substring-after($RWY_RCP_coordinates, ' '))"/>
								<!-- RWY centre line - Latitude -->
								<xsl:variable name="RWY_RCP_lat">
									<xsl:if test="$RWY-latest-ts/aixm:type = 'RWY'">
										<xsl:value-of select="if ($RWY_RCP_coordinates) then fcn:format-latitude($RWY_RCP_latitude_decimal, $coordinates_type, $coordinates_decimal_number) else ''"/>
									</xsl:if>
								</xsl:variable>
								<!-- RWY centre line - Longitude -->
								<xsl:variable name="RWY_RCP_long">
									<xsl:if test="$RWY-latest-ts/aixm:type = 'RWY'">
										<xsl:value-of select="if ($RWY_RCP_coordinates) then fcn:format-latitude($RWY_RCP_longitude_decimal, $coordinates_type, $coordinates_decimal_number) else ''"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- FATO -->
								<!-- FATO centre line Aerodrome / Heliport - Identification -->
								<xsl:variable name="FATO_AHP_designator">
									<xsl:if test="$RWY-latest-ts/aixm:type = 'FATO'">
										<xsl:choose>
											<xsl:when test="not($RWY-AHP-latest-ts/aixm:designator)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($RWY-AHP-latest-ts/aixm:designator)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								<!-- FATO centre line Aerodrome / Heliport - ICAO Code -->
								<xsl:variable name="FATO_AHP_ICAO_code">
									<xsl:if test="$RWY-latest-ts/aixm:type = 'FATO'">
										<xsl:choose>
											<xsl:when test="not($RWY-AHP-latest-ts/aixm:locationIndicatorICAO)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($RWY-AHP-latest-ts/aixm:locationIndicatorICAO)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								<!-- FATO centre line TLOF - Designator -->
								<xsl:variable name="FATO_TLOF_designator">
									<xsl:if test="$RWY-latest-ts/aixm:type = 'FATO'">
										<!-- Find all TouchDownLiftOff features that point to this FATO -->
										<xsl:variable name="TLOF-for-FATO-baseline-ts" select="//aixm:TouchDownLiftOff/aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice[aixm:interpretation = 'BASELINE'][replace(aixm:approachTakeOffArea/@xlink:href, '^(urn:uuid:|#uuid\.)', '') = $RWY_UUID]"/>
										<xsl:variable name="TLOF-for-FATO-max-seq" select="max($TLOF-for-FATO-baseline-ts/aixm:sequenceNumber)"/>
										<xsl:variable name="TLOF-for-FATO-max-corr" select="max($TLOF-for-FATO-baseline-ts[aixm:sequenceNumber = $TLOF-for-FATO-max-seq]/aixm:correctionNumber)"/>
										<xsl:variable name="TLOF-for-FATO-latest-ts" select="$TLOF-for-FATO-baseline-ts[aixm:sequenceNumber = $TLOF-for-FATO-max-seq and aixm:correctionNumber = $TLOF-for-FATO-max-corr][1]"/>
										<xsl:choose>
											<xsl:when test="not($TLOF-for-FATO-latest-ts/aixm:designator)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($TLOF-for-FATO-latest-ts/aixm:designator)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								<!-- Final approach and take-off area [FATO] - Designator -->
								<xsl:variable name="FATO_designator">
									<xsl:if test="$RWY-latest-ts/aixm:type = 'FATO'">
										<xsl:choose>
											<xsl:when test="not($RWY-latest-ts/aixm:designator)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($RWY-latest-ts/aixm:designator)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								<!-- FATO RCP coordinates -->
								<xsl:variable name="FATO_RCP_coordinates" select="$RCP-latest-ts/aixm:location/aixm:ElevatedPoint/gml:pos"/>
								<xsl:variable name="FATO_RCP_latitude_decimal" select="number(substring-before($RWY_RCP_coordinates, ' '))"/>
								<xsl:variable name="FATO_RCP_longitude_decimal" select="number(substring-after($RWY_RCP_coordinates, ' '))"/>
								<!-- FATO centre line - Latitude -->
								<xsl:variable name="FATO_RCP_lat">
									<xsl:if test="$RWY-latest-ts/aixm:type = 'FATO'">
										<xsl:value-of select="if ($FATO_RCP_coordinates) then fcn:format-latitude($FATO_RCP_latitude_decimal, $coordinates_type, $coordinates_decimal_number) else ''"/>
									</xsl:if>
								</xsl:variable>
								<!-- FATO centre line - Longitude -->
								<xsl:variable name="FATO_RCP_long">
									<xsl:if test="$RWY-latest-ts/aixm:type = 'FATO'">
										<xsl:value-of select="if ($FATO_RCP_coordinates) then fcn:format-latitude($FATO_RCP_longitude_decimal, $coordinates_type, $coordinates_decimal_number) else ''"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Datum -->
								<xsl:variable name="DPN_datum">
									<xsl:if test="aixm:location/aixm:Point/@srsName">
										<xsl:value-of select="concat(substring(aixm:location/aixm:Point/@srsName, 17,5), substring(aixm:location/aixm:Point/@srsName, 23,4))"/>
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
									<xsl:variable name="dataset_creation_date" select="../../../../aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
									<xsl:if test="string-length($dataset_creation_date) gt 0">
										<xsl:value-of select="concat('Current time: ', $dataset_creation_date)"/>
									</xsl:if>
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
										<xsl:when test="aixm:location/aixm:Point/gml:pos">
											<xsl:variable name="DPN-coords" select="aixm:location/aixm:Point/gml:pos"/>
											<xsl:variable name="DPN-lat" select="xs:double(substring-before($DPN-coords, ' '))"/>
											<xsl:variable name="DPN-lon" select="xs:double(substring-after($DPN-coords, ' '))"/>
											<xsl:sequence select="fcn:find-containing-fir($DPN-lat, $DPN-lon, $doc-root)"/>
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
								
								<tr>
									<td><xsl:value-of select="if (string-length($DPN_designator) gt 0) then $DPN_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($DPN_latitude) gt 0) then $DPN_latitude else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($DPN_longitude) gt 0) then $DPN_longitude else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($TLOF_AHP_designator) gt 0) then $TLOF_AHP_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($TLOF_AHP_ICAO_code) gt 0) then $TLOF_AHP_ICAO_code else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($TLOF_designator) gt 0) then $TLOF_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($DPN_AHP_designator) gt 0) then $DPN_AHP_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($DPN_AHP_ICAO_code) gt 0) then $DPN_AHP_ICAO_code else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($DPN_AHP_ARP_lat) gt 0) then $DPN_AHP_ARP_lat else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($DPN_AHP_ARP_long) gt 0) then $DPN_AHP_ARP_long else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RWY_AHP_designator) gt 0) then $RWY_AHP_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RWY_AHP_ICAO_code) gt 0) then $RWY_AHP_ICAO_code else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RWY_designator) gt 0) then $RWY_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RWY_RCP_lat) gt 0) then $RWY_RCP_lat else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RWY_RCP_long) gt 0) then $RWY_RCP_long else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($FATO_AHP_designator) gt 0) then $FATO_AHP_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($FATO_AHP_ICAO_code) gt 0) then $FATO_AHP_ICAO_code else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($FATO_TLOF_designator) gt 0) then $FATO_TLOF_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($FATO_designator) gt 0) then $FATO_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($FATO_RCP_lat) gt 0) then $FATO_RCP_lat else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($FATO_RCP_long) gt 0) then $FATO_RCP_long else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($DPN_datum) gt 0) then $DPN_datum else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($DPN_geo_accuracy) gt 0) then $DPN_geo_accuracy else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($DPN_geo_acc_uom) gt 0) then $DPN_geo_acc_uom else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($DPN_CRC) gt 0) then $DPN_CRC else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($DPN_type) gt 0) then $DPN_type else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($DPN_name) gt 0) then $DPN_name else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($DPN_remarks) gt 0) then $DPN_remarks else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($commit_date) gt 0) then $commit_date else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($DPN_UUID) gt 0) then $DPN_UUID else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($DPN_timeslice) gt 0) then $DPN_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($FIR_designator) gt 0) then $FIR_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($FIR_timeslice) gt 0) then $FIR_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($originator) gt 0) then $originator else '&#160;'"/></td>
								</tr>
								<tr>
									<td>&#160;</td>
								</tr>
								<tr>
									<td>&#160;</td>
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
					<tr>
						<td><font size="-1">featureTypes: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($feat_types) gt 0) then $feat_types else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">excludedProperties: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($exc_properties) gt 0) then $exc_properties else '&#160;'"/></font></td>
					</tr>
					<tr>
						<td><font size="-1">includeReferencedFeaturesLevel: </font></td>
						<td><font size="-1"><xsl:value-of select="if (string-length($referenced_feat_level) gt 0) then $referenced_feat_level else '&#160;'"/></font></td>
					</tr>
					<tr>
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
					<tr>
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
						<td><font size="-1"><xsl:value-of select="if (string-length($arc_to_polygon) gt 0) then $data_type else '&#160;'"/></font></td>
					</tr>
				</table>
				
				<p></p>
				<table>
					<tr>
						<td><font size="-1">Sorting by: </font></td>
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