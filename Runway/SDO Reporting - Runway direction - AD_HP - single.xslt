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
                    featureTypes: aixm:RunwayDirection;
  includeReferencedFeaturesLevel: 2
               permanentBaseline: true
                       dataScope: ReleasedData
                     AIXMversion: 5.1.1
              indirectReferences: aixm:RunwayDirection references (aixm:ArrestingGear aixm:RunwayCentrelinePoint aixm:RunwayVisualRange aixm:VisualGlideSlopeIndicator)
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
	exclude-result-prefixes="xsl uuid message gts gco xsd gml gss gsr gmd aixm event xlink xs xsi aixm_ds_xslt ead-audit fcn math">
	
	<xsl:output method="html" indent="yes"/>
	
	<xsl:strip-space elements="*"/>
	
	<xsl:key name="AirportHeliport-by-uuid" match="aixm:AirportHeliport" use="gml:identifier"/>
	
	<!-- Global variable to capture document root for use in key() functions -->
	<xsl:variable name="doc-root" select="/"/>
	
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
				<title>SDO Reporting - Runway direction - AD / HP</title>
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
					<b>Runway direction - AD / HP</b>
				</center>
				<hr/>
				
				<table border="0" style="white-space:nowrap">
					<tbody>
						
						<tr>
							<td><strong>Aerodrome / Heliport - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>Aerodrome / Heliport - ICAO Code</strong></td>
						</tr>
						<tr>
							<td><strong>Aerodrome / Heliport - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>Runway [RWY] - Designator</strong></td>
						</tr>
						<tr>
							<td><strong>Runway [RWY] - Type</strong></td>
						</tr>
						<tr>
							<td><strong>Runway [RWY] - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>Designator</strong></td>
						</tr>
						<tr>
							<td><strong>Threshold - Latitude</strong></td>
						</tr>
						<tr>
							<td><strong>Threshold - Longitude</strong></td>
						</tr>
						<tr>
							<td><strong>Threshold - Valid TimeSlice [RCP]</strong></td>
						</tr>
						<tr>
							<td><strong>True bearing</strong></td>
						</tr>
						<tr>
							<td><strong>Magnetic bearing</strong></td>
						</tr>
						<tr>
							<td><strong>Elevation of touch down zone</strong></td>
						</tr>
						<tr>
							<td><strong>VASIS Position</strong></td>
						</tr>
						<tr>
							<td><strong>VASIS number of boxes</strong></td>
						</tr>
						<tr>
							<td><strong>Portable VASIS</strong></td>
						</tr>
						<tr>
							<td><strong>Accuracy of the touch down zone elevation</strong></td>
						</tr>
						<tr>
							<td><strong>Unit of measurement [touch down zone elevation]</strong></td>
						</tr>
						<tr>
							<td><strong>Taxi time estimation</strong></td>
						</tr>
						<tr>
							<td><strong>Type</strong></td>
						</tr>
						<tr>
							<td><strong>(d)VASIS position description</strong></td>
						</tr>
						<tr>
							<td><strong>Approach slope angle</strong></td>
						</tr>
						<tr>
							<td><strong>Minimun eye height over threshold</strong></td>
						</tr>
						<tr>
							<td><strong>Unit of measurement [minimum eye height over threshold]</strong></td>
						</tr>
						<tr>
							<td><strong>VASIS - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>Arresting device</strong></td>
						</tr>
						<tr>
							<td><strong>Arresting device - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>RVR meteorological equipment</strong></td>
						</tr>
						<tr>
							<td><strong>RVR - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>Direction of the VFR flight pattern</strong></td>
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
							<td><strong>Valid TimeSlice</strong></td>
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
						
						<xsl:for-each select="//aixm:RunwayDirection">

							<!-- Sort by AirportHeliport designator (using valid timeslice), then by RunwayDirection designator -->
							<xsl:sort select="
								let $rd_baseline := aixm:timeSlice/aixm:RunwayDirectionTimeSlice[aixm:interpretation = 'BASELINE'],
								$rd_max_seq := max($rd_baseline/aixm:sequenceNumber),
								$rd_max_corr := max($rd_baseline[aixm:sequenceNumber = $rd_max_seq]/aixm:correctionNumber),
								$rd_valid := $rd_baseline[aixm:sequenceNumber = $rd_max_seq and aixm:correctionNumber = $rd_max_corr][1],
								$rwy_uuid := replace($rd_valid/aixm:usedRunway/@xlink:href, '^(urn:uuid:|#uuid\.)', ''),
								$rwy := //aixm:Runway[gml:identifier = $rwy_uuid],
								$rwy_baseline := $rwy/aixm:timeSlice/aixm:RunwayTimeSlice[aixm:interpretation = 'BASELINE'],
								$rwy_max_seq := max($rwy_baseline/aixm:sequenceNumber),
								$rwy_max_corr := max($rwy_baseline[aixm:sequenceNumber = $rwy_max_seq]/aixm:correctionNumber),
								$rwy_valid := $rwy_baseline[aixm:sequenceNumber = $rwy_max_seq and aixm:correctionNumber = $rwy_max_corr][1],
								$ahp_uuid := replace($rwy_valid/aixm:associatedAirportHeliport/@xlink:href, '^(urn:uuid:|#uuid\.)', ''),
								$ahp := key('AirportHeliport-by-uuid', $ahp_uuid, $doc-root),
								$ahp_baseline := $ahp/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE'],
								$ahp_max_seq := max($ahp_baseline/aixm:sequenceNumber),
								$ahp_max_corr := max($ahp_baseline[aixm:sequenceNumber = $ahp_max_seq]/aixm:correctionNumber),
								$ahp_valid := $ahp_baseline[aixm:sequenceNumber = $ahp_max_seq and aixm:correctionNumber = $ahp_max_corr][1]
								return $ahp_valid/aixm:designator"
								data-type="text" order="ascending"/>

							<xsl:sort select="
								let $baseline := aixm:timeSlice/aixm:RunwayDirectionTimeSlice[aixm:interpretation = 'BASELINE'],
								$max_seq := max($baseline/aixm:sequenceNumber),
								$max_corr := max($baseline[aixm:sequenceNumber = $max_seq]/aixm:correctionNumber),
								$valid := $baseline[aixm:sequenceNumber = $max_seq and aixm:correctionNumber = $max_corr][1]
								return $valid/aixm:designator"
								data-type="text" order="ascending"/>

							<xsl:variable name="RDN-baseline-timeslices" select="aixm:timeSlice/aixm:RunwayDirectionTimeSlice[aixm:interpretation = 'BASELINE']"/>
							<xsl:variable name="RDN-max-sequence" select="max($RDN-baseline-timeslices/aixm:sequenceNumber)"/>
							<xsl:variable name="RDN-max-correction" select="max($RDN-baseline-timeslices[aixm:sequenceNumber = $RDN-max-sequence]/aixm:correctionNumber)"/>
							<xsl:variable name="RDN-valid-timeslice" select="$RDN-baseline-timeslices[aixm:sequenceNumber = $RDN-max-sequence and aixm:correctionNumber = $RDN-max-correction][1]"/>

							<xsl:for-each select="$RDN-valid-timeslice">
								
								<!-- Internal UID (master) -->
								<xsl:variable name="RDN_UUID" select="../../gml:identifier"/>
								
								<!-- Valid TimeSlice -->
								<xsl:variable name="RDN_timeslice" select="concat('BASELINE ', $RDN-max-sequence, '.', $RDN-max-correction)"/>
								
								<!-- Get Runway information -->
								<xsl:variable name="RWY_UUID" select="replace(aixm:usedRunway/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<xsl:variable name="RWY" select="//aixm:Runway[gml:identifier = $RWY_UUID]"/>
								<xsl:variable name="RWY-baseline" select="$RWY/aixm:timeSlice/aixm:RunwayTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="RWY-max-seq" select="max($RWY-baseline/aixm:sequenceNumber)"/>
								<xsl:variable name="RWY-max-corr" select="max($RWY-baseline[aixm:sequenceNumber = $RWY-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="RWY-valid-ts" select="$RWY-baseline[aixm:sequenceNumber = $RWY-max-seq and aixm:correctionNumber = $RWY-max-corr][1]"/>
								<xsl:variable name="RWY_timeslice" select="concat('BASELINE ', $RWY-max-seq, '.', $RWY-max-corr)"/>
								
								<!-- Get valid AirportHeliport timeslice -->
								<xsl:variable name="AHP_UUID" select="replace($RWY-valid-ts/aixm:associatedAirportHeliport/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<xsl:variable name="AHP" select="key('AirportHeliport-by-uuid', $AHP_UUID, $doc-root)"/>
								<xsl:variable name="AHP-baseline" select="$AHP/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="AHP-max-seq" select="max($AHP-baseline/aixm:sequenceNumber)"/>
								<xsl:variable name="AHP-max-corr" select="max($AHP-baseline[aixm:sequenceNumber = $AHP-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="AHP-valid-ts" select="$AHP-baseline[aixm:sequenceNumber = $AHP-max-seq and aixm:correctionNumber = $AHP-max-corr][1]"/>
								<xsl:variable name="AHP_timeslice" select="concat('BASELINE ', $AHP-max-seq, '.', $AHP-max-corr)"/>
								
								<!-- Aerodrome / Heliport - Identification -->
								<xsl:variable name="AHP_designator">
									<xsl:choose>
										<xsl:when test="not($AHP-valid-ts/aixm:designator)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($AHP-valid-ts/aixm:designator)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Aerodrome / Heliport - ICAO Code -->
								<xsl:variable name="AHP_ICAO_code">
									<xsl:choose>
										<xsl:when test="not($AHP-valid-ts/aixm:locationIndicatorICAO)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($AHP-valid-ts/aixm:locationIndicatorICAO)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Runway Designator -->
								<xsl:variable name="RWY_designator">
									<xsl:choose>
										<xsl:when test="not($RWY-valid-ts/aixm:designator)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($RWY-valid-ts/aixm:designator)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Runway Type -->
								<xsl:variable name="RWY_type">
									<xsl:choose>
										<xsl:when test="not($RWY-valid-ts/aixm:type)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($RWY-valid-ts/aixm:type)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- RunwayDirection Designator -->
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
								
								<!-- Coordinates -->
								
								<!-- Select the type of coordinates: 'DMS' or 'DEC' -->
								<xsl:variable name="coordinates_type" select="'DMS'"/>
								
								<!-- Select the number of decimals -->
								<xsl:variable name="coordinates_decimal_number" select="2"/>
								
								<xsl:variable name="RCP-baseline" select="//aixm:RunwayCentrelinePointTimeSlice[aixm:interpretation = 'BASELINE' and replace(aixm:onRunway/@xlink:href, '^(urn:uuid:|#uuid\.)', '') = $RDN_UUID]"/>
								<xsl:variable name="RCP-max-seq" select="max($RCP-baseline/aixm:sequenceNumber)"/>
								<xsl:variable name="RCP-max-corr" select="max($RCP-baseline[aixm:sequenceNumber = $RCP-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="RCP-valid-ts" select="$RCP-baseline[aixm:sequenceNumber = $RCP-max-seq and aixm:correctionNumber = $RCP-max-corr][1]"/>
								<xsl:variable name="RDN_THR_timeslice">
									<xsl:if test="$RCP-valid-ts">
										<xsl:value-of select="concat('BASELINE ', $RCP-max-seq, '.', $RCP-max-corr)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- RDN THR Datum -->
								<xsl:variable name="RDN_THR_datum">
									<xsl:value-of select="replace(replace($RCP-valid-ts[aixm:role = ('THR','DISTHR')]/aixm:location/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
								</xsl:variable>
								
								<!-- Extract coordinates depending on the coordinate system -->
								<xsl:variable name="RDN_THR_coordinates" select="$RCP-valid-ts[aixm:role = ('THR','DISTHR')]/aixm:location/aixm:ElevatedPoint/gml:pos"/>
								<xsl:variable name="RDN_THR_latitude_decimal">
									<xsl:choose>
										<xsl:when test="$RDN_THR_datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
											<xsl:value-of  select="number(substring-before($RDN_THR_coordinates, ' '))"/>
										</xsl:when>
										<xsl:when test="matches($RDN_THR_datum, '^OGC:.*CRS84$')">
											<xsl:value-of select="number(substring-after($RDN_THR_coordinates, ' '))"/>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="RDN_THR_longitude_decimal">
									<xsl:choose>
										<xsl:when test="$RDN_THR_datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
											<xsl:value-of  select="number(substring-after($RDN_THR_coordinates, ' '))"/>
										</xsl:when>
										<xsl:when test="matches($RDN_THR_datum, '^OGC:.*CRS84$')">
											<xsl:value-of select="number(substring-before($RDN_THR_coordinates, ' '))"/>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="RDN_THR_latitude">
									<xsl:if test="string-length($RDN_THR_latitude_decimal) gt 0">
										<xsl:value-of select="fcn:format-latitude($RDN_THR_latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
								</xsl:variable>
								<xsl:variable name="RDN_THR_longitude">
									<xsl:if test="string-length($RDN_THR_longitude_decimal) gt 0">
										<xsl:value-of select="fcn:format-longitude($RDN_THR_longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- True bearing -->
								<xsl:variable name="RDN_true_brg">
									<xsl:choose>
										<xsl:when test="not(aixm:trueBearing)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:trueBearing)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Magnetic bearing -->
								<xsl:variable name="RDN_mag_brg">
									<xsl:choose>
										<xsl:when test="not(aixm:magneticBearing)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:magneticBearing)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Elevation of touch down zone -->
								<xsl:variable name="RDN_TDZ_elevation">
									<xsl:choose>
										<xsl:when test="not(aixm:elevationTDZ)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:elevationTDZ)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- VASIS -->
								<xsl:variable name="VASIS-baseline" select="//aixm:VisualGlideSlopeIndicatorTimeSlice[aixm:interpretation = 'BASELINE' and replace(aixm:runwayDirection/@xlink:href, '^(urn:uuid:|#uuid\.)', '') = $RDN_UUID]"/>
								<xsl:variable name="VASIS-max-seq" select="max($VASIS-baseline/aixm:sequenceNumber)"/>
								<xsl:variable name="VASIS-max-corr" select="max($VASIS-baseline[aixm:sequenceNumber = $VASIS-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="VASIS-valid-ts" select="$VASIS-baseline[aixm:sequenceNumber = $VASIS-max-seq and aixm:correctionNumber = $VASIS-max-corr][1]"/>
								<xsl:variable name="RDN_VASIS_timeslice">
									<xsl:if test="$VASIS-valid-ts">
										<xsl:value-of select="concat('BASELINE ', $VASIS-max-seq, '.', $VASIS-max-corr)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- VASIS Position -->
								<xsl:variable name="RDN_VASIS_position">
									<xsl:choose>
										<xsl:when test="$VASIS-valid-ts">
											<xsl:choose>
												<xsl:when test="not($VASIS-valid-ts/aixm:position)">
													<xsl:value-of select="''"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="fcn:insert-value($VASIS-valid-ts/aixm:position)"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>
										<xsl:when test="not($VASIS-valid-ts/aixm:position)">
											<xsl:for-each select="aixm:annotation/aixm:Note">
												<xsl:if test="contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'vasis position')">
													<xsl:variable name="annotation_text" select="concat(normalize-space(replace(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')],'(\r\n?|\n)', ' ')), ' ')"/>
													<xsl:variable name="annotation_text_lower" select="lower-case($annotation_text)"/>
													<xsl:variable name="start_pos" select="string-length(substring-before($annotation_text_lower, 'vasis position: ')) + string-length('vasis position: ')"/>
													<xsl:value-of select="substring-before(substring($annotation_text, $start_pos + 1), ' ')"/>
												</xsl:if>
											</xsl:for-each>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								
								<!-- VASIS number of boxes -->
								<xsl:variable name="RDN_VASIS_nr_box">
									<xsl:choose>
										<xsl:when test="not($VASIS-valid-ts/aixm:numberBox)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($VASIS-valid-ts/aixm:numberBox)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Portable VASIS -->
								<xsl:variable name="RDN_portable_VASIS">
									<xsl:choose>
										<xsl:when test="$VASIS-valid-ts">
											<xsl:choose>
												<xsl:when test="not($VASIS-valid-ts/aixm:portable)">
													<xsl:value-of select="''"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="fcn:insert-value($VASIS-valid-ts/aixm:portable)"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>
										<xsl:when test="not($VASIS-valid-ts/aixm:portable)">
											<xsl:for-each select="aixm:annotation/aixm:Note">
												<xsl:if test="contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'portablevasis')">
													<xsl:variable name="annotation_text" select="concat(normalize-space(replace(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')],'(\r\n?|\n)', ' ')), ' ')"/>
													<xsl:variable name="annotation_text_lower" select="lower-case($annotation_text)"/>
													<xsl:variable name="start_pos" select="string-length(substring-before($annotation_text_lower, 'portablevasis: ')) + string-length('portablevasis: ')"/>
													<xsl:value-of select="substring-before(substring($annotation_text, $start_pos + 1), ' ')"/>
												</xsl:if>
											</xsl:for-each>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Accuracy of the touch down zone elevation -->
								<xsl:variable name="RDN_TDZ_accuracy">
									<xsl:choose>
										<xsl:when test="not(aixm:elevationTDZAccuracy)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:elevationTDZAccuracy)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Unit of measurement [touch down zone elevation] -->
								<xsl:variable name="RDN_TDZ_accuracy_uom" select="aixm:elevationTDZ/@uom"/>
								
								<!-- Taxi time estimation -->
								<xsl:variable name="RDN_taxitime_est">
									<!-- ? -->
								</xsl:variable>
								
								<!-- Type -->
								<xsl:variable name="RDN_VASIS_type">
									<xsl:choose>
										<xsl:when test="$VASIS-valid-ts">
											<xsl:choose>
												<xsl:when test="not($VASIS-valid-ts/aixm:type)">
													<xsl:value-of select="''"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="fcn:insert-value($VASIS-valid-ts/aixm:type)"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>
										<xsl:when test="not($VASIS-valid-ts/aixm:type)">
											<xsl:for-each select="aixm:annotation/aixm:Note">
												<xsl:if test="contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'type of vasis')">
													<xsl:variable name="annotation_text" select="concat(normalize-space(replace(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')],'(\r\n?|\n)', ' ')), ' ')"/>
													<xsl:variable name="annotation_text_lower" select="lower-case($annotation_text)"/>
													<xsl:variable name="start_pos" select="string-length(substring-before($annotation_text_lower, 'type of vasis: ')) + string-length('type of vasis: ')"/>
													<xsl:value-of select="substring-before(substring($annotation_text, $start_pos + 1), ' ')"/>
												</xsl:if>
											</xsl:for-each>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								
								<!-- (d)VASIS position description -->
								<xsl:variable name="RDN_VASIS_position_desc">
									<xsl:if test="$VASIS-valid-ts">
										<xsl:for-each select="$VASIS-valid-ts/aixm:annotation/aixm:Note[aixm:propertyName = ('position')]">
											<xsl:for-each select="aixm:translatedNote/aixm:LinguisticNote">
												<xsl:value-of select="concat(if (position() = 1) then '' else ' | ', if (aixm:note/@lang) then (concat('(', aixm:note/@lang, ') ')) else '', fcn:get-annotation-text(substring-after(aixm:note, ':')))"/>
											</xsl:for-each>
										</xsl:for-each>
									</xsl:if>
								</xsl:variable>
								
								<!-- Approach slope angle -->
								<xsl:variable name="RDN_app_slope_ang">
									<xsl:choose>
										<xsl:when test="$VASIS-valid-ts">
											<xsl:choose>
												<xsl:when test="not($VASIS-valid-ts/aixm:slopeAngle)">
													<xsl:value-of select="''"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="fcn:insert-value($VASIS-valid-ts/aixm:slopeAngle)"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>
										<xsl:when test="not($VASIS-valid-ts/aixm:slopeAngle)">
											<xsl:for-each select="aixm:annotation/aixm:Note">
												<xsl:if test="contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'approach slope angle')">
													<xsl:variable name="annotation_text" select="concat(normalize-space(replace(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')],'(\r\n?|\n)', ' ')), ' ')"/>
													<xsl:variable name="annotation_text_lower" select="lower-case($annotation_text)"/>
													<xsl:variable name="start_pos" select="string-length(substring-before($annotation_text_lower, 'approach slope angle: ')) + string-length('approach slope angle: ')"/>
													<xsl:value-of select="substring-before(substring($annotation_text, $start_pos + 1), ' ')"/>
												</xsl:if>
											</xsl:for-each>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Minimun eye height over threshold -->
								<xsl:variable name="RDN_MEH">
									<xsl:choose>
										<xsl:when test="$VASIS-valid-ts">
											<xsl:choose>
												<xsl:when test="not($VASIS-valid-ts/aixm:minimumEyeHeightOverThreshold)">
													<xsl:value-of select="''"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="fcn:insert-value($VASIS-valid-ts/aixm:minimumEyeHeightOverThreshold)"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>
										<xsl:when test="not($VASIS-valid-ts/aixm:minimumEyeHeightOverThreshold)">
											<xsl:for-each select="aixm:annotation/aixm:Note">
												<xsl:if test="contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'minimum eye height over threshold')">
													<xsl:variable name="annotation_text" select="concat(normalize-space(replace(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')],'(\r\n?|\n)', ' ')), ' ')"/>
													<xsl:variable name="annotation_text_lower" select="lower-case($annotation_text)"/>
													<xsl:variable name="start_pos" select="string-length(substring-before($annotation_text_lower, 'minimum eye height over threshold: ')) + string-length('minimum eye height over threshold: ')"/>
													<xsl:value-of select="substring-before(substring($annotation_text, $start_pos + 1), ' ')"/>
												</xsl:if>
											</xsl:for-each>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Unit of measurement [minimum eye height over threshold] -->
								<xsl:variable name="RDN_MEH_uom">
									<xsl:choose>
										<xsl:when test="$VASIS-valid-ts">
											<xsl:value-of select="$VASIS-valid-ts/aixm:minimumEyeHeightOverThreshold/@uom"/>
										</xsl:when>
										<xsl:when test="not($VASIS-valid-ts/aixm:minimumEyeHeightOverThreshold/@uom)">
											<xsl:for-each select="aixm:annotation/aixm:Note">
												<xsl:if test="contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'unit of measurement [minimum eye height over threshold]')">
													<xsl:variable name="annotation_text" select="concat(normalize-space(replace(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')],'(\r\n?|\n)', ' ')), ' ')"/>
													<xsl:variable name="annotation_text_lower" select="lower-case($annotation_text)"/>
													<xsl:variable name="start_pos" select="string-length(substring-before($annotation_text_lower, 'unit of measurement [minimum eye height over threshold]: ')) + string-length('unit of measurement [minimum eye height over threshold]: ')"/>
													<xsl:value-of select="substring-before(substring($annotation_text, $start_pos + 1), ' ')"/>
												</xsl:if>
											</xsl:for-each>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Arresting device -->
								<xsl:variable name="ArrestingGear-baseline" select="//aixm:ArrestingGearTimeSlice[aixm:interpretation = 'BASELINE' and replace(aixm:runwayDirection/@xlink:href, '^(urn:uuid:|#uuid\.)', '') = $RDN_UUID]"/>
								<xsl:variable name="ArrestingGear-max-seq" select="max($ArrestingGear-baseline/aixm:sequenceNumber)"/>
								<xsl:variable name="ArrestingGear-max-corr" select="max($ArrestingGear-baseline[aixm:sequenceNumber = $ArrestingGear-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="ArrestingGear-valid-ts" select="$ArrestingGear-baseline[aixm:sequenceNumber = $ArrestingGear-max-seq and aixm:correctionNumber = $ArrestingGear-max-corr][1]"/>
								<xsl:variable name="RDN_ArrestingGear_timeslice">
									<xsl:if test="$ArrestingGear-valid-ts">
										<xsl:value-of select="concat('BASELINE ', $ArrestingGear-max-seq, '.', $ArrestingGear-max-corr)"/>
									</xsl:if>
								</xsl:variable>
								<xsl:variable name="RDN_ArrestingGear">
									<xsl:choose>
										<xsl:when test="$ArrestingGear-valid-ts">
											<xsl:choose>
												<xsl:when test="not($ArrestingGear-valid-ts/aixm:engageDevice)">
													<xsl:value-of select="''"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="normalize-space(fcn:insert-value($ArrestingGear-valid-ts/aixm:engageDevice))"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:when>
										<xsl:when test="not($ArrestingGear-valid-ts)">
											<xsl:for-each select="aixm:annotation/aixm:Note[contains(lower-case(aixm:translatedNote[1]/aixm:LinguisticNote/aixm:note), 'arresting gear')]">
												<xsl:for-each select="aixm:translatedNote/aixm:LinguisticNote">
													<xsl:choose>
														<xsl:when test="contains(lower-case(aixm:note), 'arresting gear')">
															<xsl:value-of select="concat(if (position() = 1) then '' else ' | ', if (aixm:note/@lang) then (concat('(', aixm:note/@lang, ') ')) else '', fcn:get-annotation-text(substring-after(aixm:note, ':')))"/>
														</xsl:when>
														<xsl:otherwise>
															<xsl:value-of select="concat(if (position() = 1) then '' else ' | ', if (aixm:note/@lang) then (concat('(', aixm:note/@lang, ') ')) else '', fcn:get-annotation-text(aixm:note))"/>
														</xsl:otherwise>
													</xsl:choose>
												</xsl:for-each>
											</xsl:for-each>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								
								<!-- RVR meteorological equipment -->
								<xsl:variable name="RVR-baseline" select="//aixm:RunwayVisualRangeTimeSlice[aixm:interpretation = 'BASELINE' and replace(aixm:associatedRunwayDirection/@xlink:href, '^(urn:uuid:|#uuid\.)', '') = $RDN_UUID]"/>
								<xsl:variable name="RVR-max-seq" select="max($RVR-baseline/aixm:sequenceNumber)"/>
								<xsl:variable name="RVR-max-corr" select="max($RVR-baseline[aixm:sequenceNumber = $RVR-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="RVR-valid-ts" select="$RVR-baseline[aixm:sequenceNumber = $RVR-max-seq and aixm:correctionNumber = $RVR-max-corr]"/>
								<xsl:variable name="RDN_RVR_timeslice">
									<xsl:if test="$RVR-valid-ts">
										<xsl:value-of select="concat('BASELINE ', $RVR-max-seq, '.', $RVR-max-corr)"/>
									</xsl:if>
								</xsl:variable>
								<xsl:variable name="RDN_RVR_equipment">
									<xsl:choose>
										<xsl:when test="$RVR-valid-ts">
											<xsl:iterate select="$RVR-valid-ts/aixm:readingPosition">
												<xsl:param name="result" select="' '"/>
												<xsl:on-completion>
													<xsl:variable name="result">
														<xsl:sequence select="$result"/>
													</xsl:variable>
													<xsl:value-of select="concat('Installed at', substring($result, 1, string-length($result)-2))"/>
												</xsl:on-completion>
												<xsl:next-iteration>
													<xsl:with-param name="result" select="if (. = 'TDZ') then concat($result, 'TDZ, ') else if (. = 'MID') then concat($result, 'MID, ') else if (. = 'TO') then concat($result, 'TO, ') else concat($result, substring-after(., ':'), ', ')"/>
												</xsl:next-iteration>
											</xsl:iterate>
										</xsl:when>
										<xsl:when test="not($RVR-valid-ts)">
											<xsl:for-each select="aixm:annotation/aixm:Note[contains(lower-case(aixm:translatedNote[1]/aixm:LinguisticNote/aixm:note), 'runway visual range')]">
												<xsl:for-each select="aixm:translatedNote/aixm:LinguisticNote">
													<xsl:choose>
														<xsl:when test="contains(lower-case(aixm:note), 'runway visual range')">
															<xsl:value-of select="concat(if (position() = 1) then '' else ' | ', if (aixm:note/@lang) then (concat('(', aixm:note/@lang, ') ')) else '', fcn:get-annotation-text(substring-after(aixm:note, ':')))"/>
														</xsl:when>
														<xsl:otherwise>
															<xsl:value-of select="concat(if (position() = 1) then '' else ' | ', if (aixm:note/@lang) then (concat('(', aixm:note/@lang, ') ')) else '', fcn:get-annotation-text(aixm:note))"/>
														</xsl:otherwise>
													</xsl:choose>
												</xsl:for-each>
											</xsl:for-each>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Direction of the VFR flight pattern -->
								<xsl:variable name="RDN_VFR_pattern_direction">
									<xsl:choose>
										<xsl:when test="not(aixm:patternVFR)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:patternVFR)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Remarks -->
								<xsl:variable name="RDN_remarks">
									<xsl:variable name="dataset_creation_date" select="//aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
									<xsl:if test="string-length($dataset_creation_date) gt 0">
										<xsl:value-of select="concat('Current time: ', $dataset_creation_date)"/>
									</xsl:if>
									<xsl:for-each select="aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[
										((../../aixm:propertyName and (not(../../aixm:propertyName/@xsi:nil='true') or not(../../aixm:propertyName/@xsi:nil))) or not(../../aixm:propertyName)) and
										(not(contains(lower-case(aixm:note), 'vasis position')) and
										not(contains(lower-case(aixm:note), 'portablevasis')) and
										not(contains(lower-case(aixm:note), 'type of vasis')) and
										not(contains(lower-case(aixm:note), 'vasis position')) and
										not(contains(lower-case(aixm:note), 'approach slope angle')) and
										not(contains(lower-case(aixm:note), 'minimum eye height over threshold')) and
										not(contains(lower-case(aixm:note), 'unit of measurement [minimum eye height over threshold]')) and
										not(contains(lower-case(aixm:note), 'arresting gear')) and
										not(contains(lower-case(aixm:note), 'runway visual range')) and
										not(contains(aixm:note, 'CRC:')))]">
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
								
								<!-- Effective date -->
								<xsl:variable name="effective_date">
									<xsl:if test="gml:validTime/gml:TimePeriod/gml:beginPosition">
										<xsl:value-of select="fcn:get-date(gml:validTime/gml:TimePeriod/gml:beginPosition)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Committed on -->
								<xsl:variable name="commit_date">
									<xsl:if test="aixm:extension/ead-audit:RunwayDirectionExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate">
										<xsl:value-of select="fcn:get-date(aixm:extension/ead-audit:RunwayDirectionExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Originator -->
								<xsl:variable name="originator" select="aixm:extension/ead-audit:RunwayDirectionExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
								
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_designator) gt 0) then $AHP_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_ICAO_code) gt 0) then $AHP_ICAO_code else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($AHP_timeslice) gt 0) then $AHP_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RWY_designator) gt 0) then $RWY_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RWY_type) gt 0) then $RWY_type else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RWY_timeslice) gt 0) then $RWY_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_designator) gt 0) then $RDN_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_THR_latitude) gt 0) then $RDN_THR_latitude else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_THR_longitude) gt 0) then $RDN_THR_longitude else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_THR_timeslice) gt 0) then $RDN_THR_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_true_brg) gt 0) then $RDN_true_brg else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_mag_brg) gt 0) then $RDN_mag_brg else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_TDZ_elevation) gt 0) then $RDN_TDZ_elevation else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_VASIS_position) gt 0) then $RDN_VASIS_position else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_VASIS_nr_box) gt 0) then $RDN_VASIS_nr_box else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_portable_VASIS) gt 0) then $RDN_portable_VASIS else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_TDZ_accuracy) gt 0) then $RDN_TDZ_accuracy else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_TDZ_accuracy_uom) gt 0) then $RDN_TDZ_accuracy_uom else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_taxitime_est) gt 0) then $RDN_taxitime_est else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_VASIS_type) gt 0) then $RDN_VASIS_type else '&#160;'"/></td>
								</tr>
								<tr>
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($RDN_VASIS_position_desc) gt 0"><xsl:value-of select="$RDN_VASIS_position_desc" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_app_slope_ang) gt 0) then $RDN_app_slope_ang else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_MEH) gt 0) then $RDN_MEH else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_MEH_uom) gt 0) then $RDN_MEH_uom else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_VASIS_timeslice) gt 0) then $RDN_VASIS_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($RDN_ArrestingGear) gt 0"><xsl:value-of select="$RDN_ArrestingGear" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_ArrestingGear_timeslice) gt 0) then $RDN_ArrestingGear_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($RDN_RVR_equipment) gt 0"><xsl:value-of select="$RDN_RVR_equipment" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_RVR_timeslice) gt 0) then $RDN_RVR_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_VFR_pattern_direction) gt 0) then $RDN_VFR_pattern_direction else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_remarks) gt 0) then $RDN_remarks else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($commit_date) gt 0) then $commit_date else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_UUID) gt 0) then $RDN_UUID else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_timeslice) gt 0) then $RDN_timeslice else '&#160;'"/></td>
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
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'extractionRulesUuid: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- interestedInDataAt -->
				<xsl:variable name="interest_date">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'interestedInDataAt: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- featureTypes -->
				<xsl:variable name="feat_types">
					<xsl:value-of select="replace(replace(substring-before(substring-after($rule_parameters, 'featureTypes: '), ','), ' ', '&lt;br/&gt;'), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- excludedProperties -->
				<xsl:variable name="exc_properties">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'excludedProperties: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- includeReferencedFeaturesLevel -->
				<xsl:variable name="referenced_feat_level">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'includeReferencedFeaturesLevel: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- featureOccurrence -->
				<xsl:variable name="feat_occurrence">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'featureOccurrence: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- effectiveDateStart -->
				<xsl:variable name="eff_date_start">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'effectiveDateStart: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- effectiveDateEnd -->
				<xsl:variable name="eff_date_end">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'effectiveDateEnd: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- referencedDataFeature -->
				<xsl:variable name="referenced_data_feat">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'referencedDataFeature: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- permanentBaseline -->
				<xsl:variable name="perm_BL">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'permanentBaseline: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- permanentPermdelta -->
				<xsl:variable name="perm_PD">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'permanentPermdelta: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- temporaryData -->
				<xsl:variable name="temp_data">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'temporaryData: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- permanentBaselineForTemporaryData -->
				<xsl:variable name="perm_BS_for_temp_data">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'permanentBaselineForTemporaryData: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- spatialFilteringBy -->
				<xsl:variable name="spatial_filtering">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'spatialFilteringBy: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- spatialAreaUUID -->
				<xsl:variable name="spatial_area_uuid">
					<xsl:value-of select="replace(replace(substring-before(substring-after($rule_parameters, 'spatialAreaUUID: '), ','), ' ', '&lt;br/&gt;'), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- spatialAreaBuffer -->
				<xsl:variable name="spatial_area_buffer">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'spatialAreaBuffer: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- spatialOperator -->
				<xsl:variable name="spatial_operator">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'spatialOperator: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- spatialValueOperator -->
				<xsl:variable name="spatial_value_operator">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'spatialValueOperator: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- dataBranch -->
				<xsl:variable name="data_branch">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'dataBranch: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- dataScope -->
				<xsl:variable name="data_scope">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'dataScope: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- dataProviderOrganization -->
				<xsl:variable name="data_provider_org">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'dataProviderOrganization: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- systemExtension -->
				<xsl:variable name="system_extension">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'systemExtension: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- AIXMversion -->
				<xsl:variable name="AIXM_ver">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'AIXMversion: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
				<!-- indirectReferences -->
				<xsl:variable name="indirect_references">
					<xsl:value-of select="replace(substring-before(substring-after($rule_parameters, 'indirectReferences: '), ','), '&quot;', '')"/>
				</xsl:variable>
				
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
						<td><font size="-1">Aerodrome / Heliport - Identification (first),  Designator (second)</font></td>
					</tr>
					<tr>
						<td style="text-align:right"><font size="-1">Sorting order: </font></td>
						<td><font size="-1">ascending</font></td>
					</tr>
				</table>
				
				<p>***&#160;END OF REPORT&#160;***</p>
				
			</body>
			
		</html>
		
	</xsl:template>
	
</xsl:transform>