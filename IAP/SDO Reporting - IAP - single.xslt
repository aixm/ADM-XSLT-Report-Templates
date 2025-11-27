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
                    featureTypes: aixm:InstrumentApproachProcedure
  includeReferencedFeaturesLevel: 2
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
	
	<xsl:output method="html" indent="yes"/>
	
	<xsl:strip-space elements="*"/>
	
	<xsl:key name="AirportHeliport-by-uuid" match="aixm:AirportHeliport" use="gml:identifier"/>
	
	<!-- Global variable to capture document root for use in key() functions -->
	<xsl:variable name="doc-root" select="/"/>
	
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
	
	<!-- Get annotation text preserving escaping special HTML characters -->
	<xsl:function name="fcn:get-annotation-text" as="xs:string">
		<xsl:param name="raw_text" as="xs:string"/>
		<!-- First, escape special HTML characters in the raw text before processing -->
		<xsl:variable name="escaped_raw_text" select="replace(replace($raw_text, '&lt;', '&amp;lt;'), '&gt;', '&amp;gt;')"/>
		<xsl:variable name="lines" select="for $line in tokenize($escaped_raw_text, '&#xA;') return normalize-space($line)"/>
		<xsl:variable name="non_empty_lines" select="$lines[string-length(.) gt 0]"/>
		<xsl:value-of select="string-join($non_empty_lines, ' ')"/>
	</xsl:function>
	
	<!-- Get latitude on datum -->
	<xsl:function name="fcn:get-latitude" as="xs:string">
		<xsl:param name="datum" as="xs:string"/>
		<xsl:param name="coordinates" as="xs:string"/>
		<xsl:param name="coordinates_type" as="xs:string"/>
		<xsl:param name="coordinates_decimal_number" as="xs:integer"/>
		<xsl:variable name="latitude_decimal">
			<xsl:choose>
				<xsl:when test="$datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
					<xsl:value-of  select="number(substring-before($coordinates, ' '))"/>
				</xsl:when>
				<xsl:when test="matches($datum, '^OGC:.*CRS84$')">
					<xsl:value-of select="number(substring-after($coordinates, ' '))"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="string-length($latitude_decimal) gt 0">
				<xsl:value-of select="fcn:format-latitude($latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="''"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- Get longitude on datum -->
	<xsl:function name="fcn:get-longitude" as="xs:string">
		<xsl:param name="datum" as="xs:string"/>
		<xsl:param name="coordinates" as="xs:string"/>
		<xsl:param name="coordinates_type" as="xs:string"/>
		<xsl:param name="coordinates_decimal_number" as="xs:integer"/>
		<xsl:variable name="longitude_decimal">
			<xsl:choose>
				<xsl:when test="$datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
					<xsl:value-of  select="number(substring-after($coordinates, ' '))"/>
				</xsl:when>
				<xsl:when test="matches($datum, '^OGC:.*CRS84$')">
					<xsl:value-of select="number(substring-before($coordinates, ' '))"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="string-length($longitude_decimal) gt 0">
				<xsl:value-of select="fcn:format-longitude($longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="''"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:template match="/">
		
		<html xmlns="http://www.w3.org/1999/xhtml">
			
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
				<meta http-equiv="Expires" content="120"/>
				<title>SDO Reporting - IAP</title>
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
				
				<center><b>IAP</b></center>
				<hr/>
				
				<table border="0" style="white-space:nowrap">
					<tbody>
						
						<tr>
							<td><strong>Associated Aerodrome / Heliport - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>Associated Aerodrome / Heliport - ICAO Code</strong></td>
						</tr>
						<tr>
							<td><strong>Associated Aerodrome / Heliport - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>Designator</strong></td>
						</tr>
						<tr>
							<td><strong>Aircraft category</strong></td>
						</tr>
						<tr>
							<td><strong>Transition identifier</strong></td>
						</tr>
						<tr>
							<td><strong>Served FATO direction - TLOF Designator</strong></td>
						</tr>
						<tr>
							<td><strong>Final approach and take-off area [FATO] - Designator</strong></td>
						</tr>
						<tr>
							<td><strong>Final approach and take-off area [FATO] - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>Served FATO direction - Designator</strong></td>
						</tr>
						<tr>
							<td><strong>Served FATO direction - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>Served RWY - Designator</strong></td>
						</tr>
						<tr>
							<td><strong>Served RWY - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>Served RWY direction - Designator</strong></td>
						</tr>
						<tr>
							<td><strong>Served RWY direction - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>Served TLOF - Designator</strong></td>
						</tr>
						<tr>
							<td><strong>Served TLOF - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>MSA centre NDB - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>MSA centre NDB - Latitude</strong></td>
						</tr>
						<tr>
							<td><strong>MSA centre NDB - Longitude</strong></td>
						</tr>
						<tr>
							<td><strong>NDB - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>MSA centre VOR - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>MSA centre VOR - Latitude</strong></td>
						</tr>
						<tr>
							<td><strong>MSA centre VOR - Longitude</strong></td>
						</tr>
						<tr>
							<td><strong>VOR - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>MSA centre Significant point - Type</strong></td>
						</tr>
						<tr>
							<td><strong>MSA centre Significant point - Identifier</strong></td>
						</tr>
						<tr>
							<td><strong>MSA centre Significant point - Latitude</strong></td>
						</tr>
						<tr>
							<td><strong>MSA centre Significant point - Longitude</strong></td>
						</tr>
						<tr>
							<td><strong>Significant point - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>SafeAltitudeArea - Valid TimeSlice</strong></td>
						</tr>
						<tr>
							<td><strong>Required navigation performance</strong></td>
						</tr>
						<tr>
							<td><strong>Communication failure description</strong></td>
						</tr>
						<tr>
							<td><strong>Type</strong></td>
						</tr>
						<tr>
							<td><strong>Missed approach procedure description</strong></td>
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
						
						<xsl:for-each select="//aixm:InstrumentApproachProcedure">

							<!-- Sort by AirportHeliport designator (using valid timeslice), then by IAP name -->
							<xsl:sort select="
								let $IAP_baseline := aixm:timeSlice/aixm:InstrumentApproachProcedureTimeSlice[aixm:interpretation = 'BASELINE'],
								$IAP_max-seq := max($IAP_baseline/aixm:sequenceNumber),
								$IAP_max-corr := max($IAP_baseline[aixm:sequenceNumber = $IAP_max-seq]/aixm:correctionNumber),
								$IAP_valid-ts := $IAP_baseline[aixm:sequenceNumber = $IAP_max-seq and aixm:correctionNumber = $IAP_max-corr][1],
								$AHP_uuid := replace($IAP_valid-ts/aixm:airportHeliport/@xlink:href, '^(urn:uuid:|#uuid\.)', ''),
								$AHP := key('AirportHeliport-by-uuid', $AHP_uuid, $doc-root),
								$AHP_baseline := $AHP/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE'],
								$AHP_max-seq := max($AHP_baseline/aixm:sequenceNumber),
								$AHP_max-corr := max($AHP_baseline[aixm:sequenceNumber = $AHP_max-seq]/aixm:correctionNumber),
								$AHP_valid-ts := $AHP_baseline[aixm:sequenceNumber = $AHP_max-seq and aixm:correctionNumber = $AHP_max-corr][1]
								return $AHP_valid-ts/aixm:designator"
								data-type="text" order="ascending"/>

							<xsl:sort select="
								let $IAP_baseline := aixm:timeSlice/aixm:InstrumentApproachProcedureTimeSlice[aixm:interpretation = 'BASELINE'],
								$IAP_max-seq := max($IAP_baseline/aixm:sequenceNumber),
								$IAP_max-corr := max($IAP_baseline[aixm:sequenceNumber = $IAP_max-seq]/aixm:correctionNumber),
								$IAP_valid-ts := $IAP_baseline[aixm:sequenceNumber = $IAP_max-seq and aixm:correctionNumber = $IAP_max-corr][1]
								return $IAP_valid-ts/aixm:name"
								data-type="text" order="ascending"/>

							<!-- Select the type of coordinates: 'DMS' or 'DEC' -->
							<xsl:variable name="coordinates_type" select="'DMS'"/>
							
							<!-- Select the number of decimals -->
							<xsl:variable name="coordinates_decimal_number" select="2"/>

							<!-- Get all BASELINE time slices for this feature -->
							<xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:InstrumentApproachProcedureTimeSlice[aixm:interpretation = 'BASELINE']"/>
							<!-- Find the maximum sequenceNumber -->
							<xsl:variable name="max-sequence" select="max($baseline-timeslices/aixm:sequenceNumber)"/>
							<!-- Get time slices with the maximum sequenceNumber, then find max correctionNumber -->
							<xsl:variable name="max-correction" select="max($baseline-timeslices[aixm:sequenceNumber = $max-sequence]/aixm:correctionNumber)"/>
							<!-- Select the valid time slice -->
							<xsl:variable name="valid-timeslice" select="$baseline-timeslices[aixm:sequenceNumber = $max-sequence and aixm:correctionNumber = $max-correction][1]"/>
							
							<xsl:for-each select="$valid-timeslice">
								
								<!-- Associated AirportHeliport -->
								<xsl:variable name="AHP_UUID" select="replace(aixm:airportHeliport/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<xsl:variable name="AHP" select="key('AirportHeliport-by-uuid', $AHP_UUID, $doc-root)"/>
								<xsl:variable name="AHP_baseline" select="$AHP/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="AHP_max-seq" select="max($AHP_baseline/aixm:sequenceNumber)"/>
								<xsl:variable name="AHP_max-corr" select="max($AHP_baseline[aixm:sequenceNumber = $AHP_max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="AHP_valid-ts" select="$AHP_baseline[aixm:sequenceNumber = $AHP_max-seq and aixm:correctionNumber = $AHP_max-corr][1]"/>
								<xsl:variable name="AHP_timeslice" select="if ($AHP_valid-ts) then concat('BASELINE ', $AHP_max-seq, '.', $AHP_max-corr) else ''"/>
								
								<!-- Associated AirportHeliport - Identification -->
								<xsl:variable name="AHP_designator">
									<xsl:choose>
										<xsl:when test="not($AHP_valid-ts/aixm:designator)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($AHP_valid-ts/aixm:designator)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Associated AirportHeliport - ICAO Code -->
								<xsl:variable name="AHP_ICAO_code">
									<xsl:choose>
										<xsl:when test="not($AHP_valid-ts/aixm:locationIndicatorICAO)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($AHP_valid-ts/aixm:locationIndicatorICAO)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Designator -->
								<xsl:variable name="IAP_designator">
									<xsl:choose>
										<xsl:when test="not(aixm:name)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:name)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Aircraft category -->
								<xsl:variable name="IAP_aircraft_category">
									<xsl:choose>
										<xsl:when test="not(aixm:aircraftCharacteristic)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:when test="aixm:aircraftCharacteristic[1]/@xsi:nil = 'true'">
											<xsl:value-of select="fcn:insert-value(aixm:aircraftCharacteristic)"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="string-join(aixm:aircraftCharacteristic/aixm:AircraftCharacteristic/aixm:aircraftLandingCategory, '')"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Transition identifier -->
								<xsl:variable name="IAP_transition_identifier">
									<xsl:choose>
										<xsl:when test="not(aixm:flightTransition)">
											<xsl:for-each select="aixm:annotation/aixm:Note">
												<xsl:variable name="note_text" select="aixm:translatedNote[1]/aixm:LinguisticNote/aixm:note"/>
												<xsl:if test="contains($note_text, 'codeTransId')">
													<xsl:variable name="after_codeTransId" select="normalize-space(substring-after($note_text, 'codeTransId:'))"/>
													<xsl:value-of select="if (contains($after_codeTransId, ' ')) then substring-before($after_codeTransId, ' ') else $after_codeTransId"/>
												</xsl:if>
											</xsl:for-each>
										</xsl:when>
										<xsl:otherwise>
											<xsl:choose>
												<xsl:when test="count(aixm:flightTransition) = 1">
													<xsl:value-of select="fcn:insert-value(aixm:flightTransition/aixm:ProcedureTransition/aixm:transitionId)"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="string-join(aixm:flightTransition/aixm:ProcedureTransition/aixm:transitionId, ' | ')"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Served RunwayDirection -->
								<xsl:variable name="RDN_UUID" select="replace(aixm:landing/aixm:LandingTakeoffAreaCollection/aixm:runway/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<xsl:variable name="RDN" select="//aixm:RunwayDirection[gml:identifier = $RDN_UUID]"/>
								<xsl:variable name="RDN_baseline" select="$RDN/aixm:timeSlice/aixm:RunwayDirectionTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="RDN_max-seq" select="max($RDN_baseline/aixm:sequenceNumber)"/>
								<xsl:variable name="RDN_max-corr" select="max($RDN_baseline[aixm:sequenceNumber = $RDN_max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="RDN_valid-ts" select="$RDN_baseline[aixm:sequenceNumber = $RDN_max-seq and aixm:correctionNumber = $RDN_max-corr][1]"/>
								<xsl:variable name="RDN_ts" select="if ($RDN_valid-ts) then concat('BASELINE ', $RDN_max-seq, '.', $RDN_max-corr) else ''"/>
								
								<!-- Served Runway -->
								<xsl:variable name="RWY_UUID" select="replace($RDN_valid-ts/aixm:usedRunway/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<xsl:variable name="RWY" select="//aixm:Runway[gml:identifier = $RWY_UUID]"/>
								<xsl:variable name="RWY_baseline" select="$RWY/aixm:timeSlice/aixm:RunwayTimeSlice[aixm:interpretation = 'BASELINE' and aixm:type = 'RWY']"/>
								<xsl:variable name="RWY_max-seq" select="max($RWY_baseline/aixm:sequenceNumber)"/>
								<xsl:variable name="RWY_max-corr" select="max($RWY_baseline[aixm:sequenceNumber = $RWY_max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="RWY_valid-ts" select="$RWY_baseline[aixm:sequenceNumber = $RWY_max-seq and aixm:correctionNumber = $RWY_max-corr][1]"/>
								<xsl:variable name="RWY_ts" select="if ($RWY_valid-ts) then concat('BASELINE ', $RWY_max-seq, '.', $RWY_max-corr) else ''"/>
								
								<!-- Served FATO -->
								<xsl:variable name="FATO_UUID" select="replace($RDN_valid-ts/aixm:usedRunway/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<xsl:variable name="FATO" select="//aixm:Runway[gml:identifier = $FATO_UUID]"/>
								<xsl:variable name="FATO_baseline" select="$FATO/aixm:timeSlice/aixm:RunwayTimeSlice[aixm:interpretation = 'BASELINE' and aixm:type = 'FATO']"/>
								<xsl:variable name="FATO_max-seq" select="max($FATO_baseline/aixm:sequenceNumber)"/>
								<xsl:variable name="FATO_max-corr" select="max($FATO_baseline[aixm:sequenceNumber = $FATO_max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="FATO_valid-ts" select="$FATO_baseline[aixm:sequenceNumber = $FATO_max-seq and aixm:correctionNumber = $FATO_max-corr][1]"/>
								<xsl:variable name="FATO_ts" select="if ($FATO_valid-ts) then concat('BASELINE ', $FATO_max-seq, '.', $FATO_max-corr) else ''"/>
								
								<!-- Served FATO direction - TLOF Designator -->
								<xsl:variable name="FATO_TLOF_designator">
									<xsl:if test="not(empty($FATO_valid-ts))">
										<!-- Find the TLOF that references the FATO -->
										<xsl:variable name="TLOF_for_FATO" select="//aixm:TouchDownLiftOff[aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice[aixm:interpretation = 'BASELINE' and replace(aixm:approachTakeOffArea/@xlink:href, '^(urn:uuid:|#uuid\.)', '') = $FATO_UUID]]"/>
										<xsl:variable name="TLOF_for_FATO_baseline" select="$TLOF_for_FATO/aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice[aixm:interpretation = 'BASELINE']"/>
										<xsl:variable name="TLOF_for_FATO_max-seq" select="max($TLOF_for_FATO_baseline/aixm:sequenceNumber)"/>
										<xsl:variable name="TLOF_for_FATO_max-corr" select="max($TLOF_for_FATO_baseline[aixm:sequenceNumber = $TLOF_for_FATO_max-seq]/aixm:correctionNumber)"/>
										<xsl:variable name="TLOF_for_FATO_valid-ts" select="$TLOF_for_FATO_baseline[aixm:sequenceNumber = $TLOF_for_FATO_max-seq and aixm:correctionNumber = $TLOF_for_FATO_max-corr][1]"/>
										<xsl:if test="not(empty($TLOF_for_FATO_valid-ts))">
											<xsl:choose>
												<xsl:when test="not($TLOF_for_FATO_valid-ts/aixm:designator)">
													<xsl:value-of select="''"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="fcn:insert-value($TLOF_for_FATO_valid-ts/aixm:designator)"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:if>
									</xsl:if>
								</xsl:variable>
								
								<!-- Final approach and take-off area [FATO] - Designator -->
								<xsl:variable name="FATO_designator">
									<xsl:if test="not(empty($FATO_valid-ts))">
										<xsl:choose>
											<xsl:when test="not($FATO_valid-ts/aixm:designator)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($FATO_valid-ts/aixm:designator)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								
								<!-- Final approach and take-off area [FATO] - Valid TimeSlice -->
								<xsl:variable name="FATO_timeslice">
									<xsl:if test="not(empty($FATO_valid-ts))">
										<xsl:value-of select="$FATO_ts"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Served FATO direction - Designator -->
								<xsl:variable name="FATO_direction">
									<xsl:if test="not(empty($FATO_valid-ts))">
										<xsl:choose>
											<xsl:when test="not($RDN_valid-ts/aixm:designator)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($RDN_valid-ts/aixm:designator)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								
								<!-- Served FATO direction - Valid TimeSlice -->
								<xsl:variable name="FATO_direction_timeslice">
									<xsl:if test="not(empty($FATO_valid-ts))">
										<xsl:value-of select="$RDN_ts"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Served RWY - Designator -->
								<xsl:variable name="RWY_designator">
									<xsl:if test="not(empty($RWY_valid-ts))">
										<xsl:choose>
											<xsl:when test="not($RWY_valid-ts/aixm:designator)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($RWY_valid-ts/aixm:designator)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								
								<!-- Served RWY - Valid TimeSlice -->
								<xsl:variable name="RWY_timeslice">
									<xsl:if test="not(empty($RWY_valid-ts))">
										<xsl:value-of select="$RWY_ts"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Served RWY direction - Designator -->
								<xsl:variable name="RDN_designator">
									<xsl:if test="not(empty($RWY_valid-ts))">
										<xsl:choose>
											<xsl:when test="not($RDN_valid-ts/aixm:designator)">
												<xsl:value-of select="''"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="fcn:insert-value($RDN_valid-ts/aixm:designator)"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:if>
								</xsl:variable>
								
								<!-- Served RWY direction - Valid TimeSlice -->
								<xsl:variable name="RDN_timeslice">
									<xsl:if test="not(empty($RWY_valid-ts))">
										<xsl:value-of select="$RDN_ts"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Served TLOF -->
								<xsl:variable name="TLOF_UUID" select="replace(aixm:landing/aixm:LandingTakeoffAreaCollection/aixm:TLOF/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<xsl:variable name="TLOF" select="//aixm:TouchDownLiftOff[gml:identifier = $TLOF_UUID]"/>
								<xsl:variable name="TLOF_baseline" select="$TLOF/aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="TLOF_max-seq" select="max($TLOF_baseline/aixm:sequenceNumber)"/>
								<xsl:variable name="TLOF_max-corr" select="max($TLOF_baseline[aixm:sequenceNumber = $TLOF_max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="TLOF_valid-ts" select="$TLOF_baseline[aixm:sequenceNumber = $TLOF_max-seq and aixm:correctionNumber = $TLOF_max-corr][1]"/>
								<xsl:variable name="TLOF_ts" select="if ($TLOF_valid-ts) then concat('BASELINE ', $TLOF_max-seq, '.', $TLOF_max-corr) else ''"/>
								
								<!-- Served TLOF - Designator -->
								<xsl:variable name="TLOF_designator">
									<xsl:choose>
										<xsl:when test="not($TLOF_valid-ts/aixm:designator)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value($TLOF_valid-ts/aixm:designator)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Served TLOF - Valid TimeSlice -->
								<xsl:variable name="TLOF_timeslice">
									<xsl:if test="not(empty($TLOF_valid-ts))">
										<xsl:value-of select="$TLOF_ts"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- MSA -->
								<xsl:variable name="MSA_UUID" select="replace(aixm:safeAltitude/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<xsl:variable name="MSA" select="//aixm:SafeAltitudeArea[gml:identifier = $MSA_UUID]"/>
								<xsl:variable name="MSA_baseline" select="$MSA/aixm:timeSlice/aixm:SafeAltitudeAreaTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="MSA_max-seq" select="max($MSA_baseline/aixm:sequenceNumber)"/>
								<xsl:variable name="MSA_max-corr" select="max($MSA_baseline[aixm:sequenceNumber = $MSA_max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="MSA_valid-ts" select="$MSA_baseline[aixm:sequenceNumber = $MSA_max-seq and aixm:correctionNumber = $MSA_max-corr][1]"/>
								<xsl:variable name="MSA_timeslice" select="if ($MSA_valid-ts) then concat('BASELINE ', $MSA_max-seq, '.', $MSA_max-corr) else ''"/>
								
								<!-- NDB - not a significant point (providesNavigableLocation='NO') -->
								<xsl:variable name="NDB_navaid_baseline" select="//aixm:Navaid[gml:identifier = replace($MSA_valid-ts/aixm:centrePoint_navaidSystem/@xlink:href, '^(urn:uuid:|#uuid\.)', '') and aixm:timeSlice[1]/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE']/aixm:type = ('NDB','NDB_DME','NDB_MKR')]/aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="NDB_navaid_max-seq" select="max($NDB_navaid_baseline/aixm:sequenceNumber)"/>
								<xsl:variable name="NDB_navaid_max-corr" select="max($NDB_navaid_baseline[aixm:sequenceNumber = $NDB_navaid_max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="NDB_navaid_valid-ts" select="$NDB_navaid_baseline[aixm:sequenceNumber = $NDB_navaid_max-seq and aixm:correctionNumber = $NDB_navaid_max-corr][1]"/>
								<xsl:variable name="NDB_provides_navigable_location">
									<xsl:if test="not($NDB_navaid_valid-ts/aixm:navaidEquipment/aixm:NavaidComponent[aixm:providesNavigableLocation != 'NO'])">
										<xsl:value-of select="'NO'"/>
									</xsl:if>
								</xsl:variable>
								<xsl:variable name="NDB_navaid_timeslice">
									<xsl:choose>
										<xsl:when test="string-length($NDB_provides_navigable_location) gt 0 and $NDB_provides_navigable_location = 'NO' and not(empty($NDB_navaid_max-seq)) and not(empty($NDB_navaid_max-corr))">
											<xsl:value-of select="concat('BASELINE ', $NDB_navaid_max-seq, '.', $NDB_navaid_max-corr)"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="''"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- MSA centre NDB - Identification -->
								<xsl:variable name="MSA_NDB_navaid_designator">
									<xsl:if test="$NDB_provides_navigable_location = 'NO'">
										<xsl:value-of select="$NDB_navaid_valid-ts/aixm:designator"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- MSA centre NDB - Latitude and Longitude -->
								
								<!-- NDB Datum -->
								<xsl:variable name="NDB_navaid_datum">
									<xsl:if test="$NDB_provides_navigable_location = 'NO'">
										<xsl:value-of select="replace(replace($NDB_navaid_valid-ts/aixm:location/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Extract coordinates depending on the coordinate system -->
								<xsl:variable name="NDB_navaid_coordinates">
									<xsl:if test="$NDB_provides_navigable_location = 'NO'">
										<xsl:value-of select="$NDB_navaid_valid-ts/aixm:location/aixm:ElevatedPoint/gml:pos"/>
									</xsl:if>
								</xsl:variable>
								<xsl:variable name="MSA_NDB_navaid_latitude">
									<xsl:if test="$NDB_provides_navigable_location = 'NO' and not(empty($NDB_navaid_coordinates)) and string-length($NDB_navaid_coordinates) gt 0">
										<xsl:value-of select="fcn:get-latitude($NDB_navaid_datum, $NDB_navaid_coordinates, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
								</xsl:variable>
								<xsl:variable name="MSA_NDB_navaid_longitude">
									<xsl:if test="$NDB_provides_navigable_location = 'NO' and not(empty($NDB_navaid_coordinates)) and string-length($NDB_navaid_coordinates) gt 0">
										<xsl:value-of select="fcn:get-longitude($NDB_navaid_datum, $NDB_navaid_coordinates, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- VOR - not a significant point (providesNavigableLocation='NO') -->
								<xsl:variable name="VOR_navaid_baseline" select="//aixm:Navaid[gml:identifier = replace($MSA_valid-ts/aixm:centrePoint_navaidSystem/@xlink:href, '^(urn:uuid:|#uuid\.)', '') and aixm:timeSlice[1]/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE']/aixm:type = ('VOR','VOR_DME','VORTAC')]/aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="VOR_navaid_max-seq" select="max($VOR_navaid_baseline/aixm:sequenceNumber)"/>
								<xsl:variable name="VOR_navaid_max-corr" select="max($VOR_navaid_baseline[aixm:sequenceNumber = $VOR_navaid_max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="VOR_navaid_valid-ts" select="$VOR_navaid_baseline[aixm:sequenceNumber = $VOR_navaid_max-seq and aixm:correctionNumber = $VOR_navaid_max-corr][1]"/>
								<xsl:variable name="VOR_provides_navigable_location">
									<xsl:if test="not($VOR_navaid_valid-ts/aixm:navaidEquipment/aixm:NavaidComponent[aixm:providesNavigableLocation != 'NO'])">
										<xsl:value-of select="'NO'"/>
									</xsl:if>
								</xsl:variable>
								<xsl:variable name="VOR_navaid_timeslice">
									<xsl:if test="string-length($VOR_provides_navigable_location) gt 0 and $VOR_provides_navigable_location = 'NO' and not(empty($VOR_navaid_max-seq)) and not(empty($VOR_navaid_max-corr))">
										<xsl:value-of select="concat('BASELINE ', $VOR_navaid_max-seq, '.', $VOR_navaid_max-corr)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- MSA centre VOR - Identification -->
								<xsl:variable name="MSA_VOR_navaid_designator">
									<xsl:if test="$VOR_provides_navigable_location = 'NO'">
										<xsl:value-of select="$VOR_navaid_valid-ts/aixm:designator"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- MSA centre VOR - Latitude and Longitude -->
								
								<!-- VOR Datum -->
								<xsl:variable name="VOR_navaid_datum">
									<xsl:if test="$VOR_provides_navigable_location = 'NO'">
										<xsl:value-of select="replace(replace($VOR_navaid_valid-ts/aixm:location/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Extract coordinates depending on the coordinate system -->
								<xsl:variable name="VOR_navaid_coordinates">
									<xsl:if test="$VOR_provides_navigable_location = 'NO'">
										<xsl:value-of select="$VOR_navaid_valid-ts/aixm:location/aixm:ElevatedPoint/gml:pos"/>
									</xsl:if>
								</xsl:variable>
								<xsl:variable name="MSA_VOR_navaid_latitude">
									<xsl:if test="$VOR_provides_navigable_location = 'NO' and not(empty($VOR_navaid_coordinates)) and string-length($VOR_navaid_coordinates) gt 0">
										<xsl:value-of select="fcn:get-latitude($VOR_navaid_datum, $VOR_navaid_coordinates, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
								</xsl:variable>
								<xsl:variable name="MSA_VOR_navaid_longitude">
									<xsl:if test="$VOR_provides_navigable_location = 'NO' and not(empty($VOR_navaid_coordinates)) and string-length($VOR_navaid_coordinates) gt 0">
										<xsl:value-of select="fcn:get-longitude($VOR_navaid_datum, $VOR_navaid_coordinates, $coordinates_type, $coordinates_decimal_number)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- MSA centre Significant Point -->
								
								<xsl:variable name="AHP_valid-ts" select="
									if ($MSA_valid-ts/aixm:centrePoint_airportReferencePoint/@xlink:href) then
										let $AHP_UUID := replace($MSA_valid-ts/aixm:centrePoint_airportReferencePoint/@xlink:href, '^(urn:uuid:|#uuid\.)', ''),
											$AHP := //aixm:AirportHeliport[gml:identifier = $AHP_UUID],
											$AHP_baseline := $AHP/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE'],
											$AHP_max-seq := max($AHP_baseline/aixm:sequenceNumber),
											$AHP_max-corr := max($AHP_baseline[aixm:sequenceNumber = $AHP_max-seq]/aixm:correctionNumber)
										return $AHP_baseline[aixm:sequenceNumber = $AHP_max-seq and aixm:correctionNumber = $AHP_max-corr][1]
									else ()
								"/>
								
								<xsl:variable name="TLOF_valid-ts" select="
									if ($MSA_valid-ts/aixm:centrePoint_aimingPoint/@xlink:href) then
										let $TLOF_UUID := replace($MSA_valid-ts/aixm:centrePoint_aimingPoint/@xlink:href, '^(urn:uuid:|#uuid\.)', ''),
											$TLOF := //aixm:TouchDownLiftOff[gml:identifier = $TLOF_UUID],
											$TLOF_baseline := $TLOF/aixm:timeSlice/aixm:TouchDownLiftOffTimeSlice[aixm:interpretation = 'BASELINE'],
											$TLOF_max-seq := max($TLOF_baseline/aixm:sequenceNumber),
											$TLOF_max-corr := max($TLOF_baseline[aixm:sequenceNumber = $TLOF_max-seq]/aixm:correctionNumber)
										return $TLOF_baseline[aixm:sequenceNumber = $TLOF_max-seq and aixm:correctionNumber = $TLOF_max-corr][1]
									else ()
								"/>
								
								<xsl:variable name="RCP_valid-ts" select="
									if ($MSA_valid-ts/aixm:centrePoint_runwayPoint/@xlink:href) then
										let $RCP_UUID := replace($MSA_valid-ts/aixm:centrePoint_runwayPoint/@xlink:href, '^(urn:uuid:|#uuid\.)', ''),
											$RCP := //aixm:RunwayCentrelinePoint[gml:identifier = $RCP_UUID],
											$RCP_baseline := $RCP/aixm:timeSlice/aixm:RunwayCentrelinePointTimeSlice[aixm:interpretation = 'BASELINE'],
											$RCP_max-seq := max($RCP_baseline/aixm:sequenceNumber),
											$RCP_max-corr := max($RCP_baseline[aixm:sequenceNumber = $RCP_max-seq]/aixm:correctionNumber)
										return $RCP_baseline[aixm:sequenceNumber = $RCP_max-seq and aixm:correctionNumber = $RCP_max-corr][1]
									else ()
								"/>
								
								<xsl:variable name="Navaid_valid-ts" select="
									if ($MSA_valid-ts/aixm:centrePoint_navaidSystem/@xlink:href) then
										let $Navaid_UUID := replace($MSA_valid-ts/aixm:centrePoint_navaidSystem/@xlink:href, '^(urn:uuid:|#uuid\.)', ''),
											$Navaid := //aixm:Navaid[gml:identifier = $Navaid_UUID],
											$Navaid_baseline := $Navaid/aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE'],
											$Navaid_max-seq := max($Navaid_baseline/aixm:sequenceNumber),
											$Navaid_max-corr := max($Navaid_baseline[aixm:sequenceNumber = $Navaid_max-seq]/aixm:correctionNumber)
										return $Navaid_baseline[aixm:sequenceNumber = $Navaid_max-seq and aixm:correctionNumber = $Navaid_max-corr][1]
									else ()
								"/>
								
								<xsl:variable name="DPN_valid-ts" select="
									if ($MSA_valid-ts/aixm:centrePoint_fixDesignatedPoint/@xlink:href) then
										let $DPN_UUID := replace($MSA_valid-ts/aixm:centrePoint_fixDesignatedPoint/@xlink:href, '^(urn:uuid:|#uuid\.)', ''),
											$DPN := //aixm:DesignatedPoint[gml:identifier = $DPN_UUID],
											$DPN_baseline := $DPN/aixm:timeSlice/aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE'],
											$DPN_max-seq := max($DPN_baseline/aixm:sequenceNumber),
											$DPN_max-corr := max($DPN_baseline[aixm:sequenceNumber = $DPN_max-seq]/aixm:correctionNumber)
										return $DPN_baseline[aixm:sequenceNumber = $DPN_max-seq and aixm:correctionNumber = $DPN_max-corr][1]
									else ()
								"/>

								<!-- MSA centre Significant Point - Type -->
								<xsl:variable name="MSA_significant_point_type">
									<xsl:choose>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_airportReferencePoint/@xlink:href">ARP</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_aimingPoint/@xlink:href">TLOF</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_runwayPoint/@xlink:href">RCP</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_position">Point</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_navaidSystem/@xlink:href">
											<xsl:variable name="provides_navigable_location">
												<xsl:for-each select="$Navaid_valid-ts/aixm:navaidEquipment/aixm:NavaidComponent">
													<xsl:if test="aixm:providesNavigableLocation = 'YES'">
														<xsl:value-of select="'YES'"/>
													</xsl:if>
												</xsl:for-each>
											</xsl:variable>
											<xsl:if test="$provides_navigable_location = 'YES'">
												<xsl:value-of select="$Navaid_valid-ts/aixm:type"/>
											</xsl:if>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_fixDesignatedPoint/@xlink:href">DPN</xsl:when>
									</xsl:choose>
								</xsl:variable>

								<!-- MSA centre Significant point - Identifier -->
								<xsl:variable name="MSA_significant_point_designator">
									<xsl:choose>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_airportReferencePoint/@xlink:href">
											<xsl:value-of select="$AHP_valid-ts/aixm:designator"/>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_aimingPoint/@xlink:href">
											<xsl:value-of select="$TLOF_valid-ts/aixm:designator"/>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_runwayPoint/@xlink:href">
											<xsl:value-of select="$RCP_valid-ts/aixm:designator"/>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_position">
											<xsl:value-of select="$MSA_valid-ts/aixm:centrePoint_position/aixm:Point/gml:name"/>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_navaidSystem/@xlink:href">
											<xsl:variable name="provides_navigable_location">
												<xsl:for-each select="$Navaid_valid-ts/aixm:navaidEquipment/aixm:NavaidComponent">
													<xsl:if test="aixm:providesNavigableLocation = 'YES'">
														<xsl:value-of select="'YES'"/>
													</xsl:if>
												</xsl:for-each>
											</xsl:variable>
											<xsl:if test="$provides_navigable_location = 'YES'">
												<xsl:value-of select="$Navaid_valid-ts/aixm:designator"/>
											</xsl:if>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_fixDesignatedPoint/@xlink:href">
											<xsl:value-of select="$DPN_valid-ts/aixm:designator"/>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>

								<!-- MSA centre Significant point - Latitude -->
								<xsl:variable name="MSA_significant_point_latitude">
									<xsl:choose>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_airportReferencePoint/@xlink:href">
											<xsl:variable name="ARP_datum" select="replace(replace($AHP_valid-ts/aixm:ARP/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
											<xsl:variable name="ARP_coordinates" select="$AHP_valid-ts/aixm:ARP/aixm:ElevatedPoint/gml:pos"/>
											<xsl:if test="not(empty($ARP_coordinates)) and string-length($ARP_coordinates) gt 0">
												<xsl:value-of select="fcn:get-latitude($ARP_datum, $ARP_coordinates, $coordinates_type, $coordinates_decimal_number)"/>
											</xsl:if>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_aimingPoint/@xlink:href">
											<xsl:variable name="TLOF_datum" select="replace(replace($TLOF_valid-ts/aixm:aimingPoint/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
											<xsl:variable name="TLOF_coordinates" select="$TLOF_valid-ts/aixm:aimingPoint/aixm:ElevatedPoint/gml:pos"/>
											<xsl:if test="not(empty($TLOF_coordinates)) and string-length($TLOF_coordinates) gt 0">
												<xsl:value-of select="fcn:get-latitude($TLOF_datum, $TLOF_coordinates, $coordinates_type, $coordinates_decimal_number)"/>
											</xsl:if>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_runwayPoint/@xlink:href">
											<xsl:variable name="RCP_datum" select="replace(replace($RCP_valid-ts/aixm:location/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
											<xsl:variable name="RCP_coordinates" select="$RCP_valid-ts/aixm:location/aixm:ElevatedPoint/gml:pos"/>
											<xsl:if test="not(empty($RCP_coordinates)) and string-length($RCP_coordinates) gt 0">
												<xsl:value-of select="fcn:get-latitude($RCP_datum, $RCP_coordinates, $coordinates_type, $coordinates_decimal_number)"/>
											</xsl:if>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_position">
											<xsl:variable name="Point_datum" select="replace(replace($MSA_valid-ts/aixm:centrePoint_position/aixm:Point/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
											<xsl:variable name="Point_coordinates" select="$MSA_valid-ts/aixm:centrePoint_position/aixm:Point/gml:pos"/>
											<xsl:if test="not(empty($Point_coordinates)) and string-length($Point_coordinates) gt 0">
												<xsl:value-of select="fcn:get-latitude($Point_datum, $Point_coordinates, $coordinates_type, $coordinates_decimal_number)"/>
											</xsl:if>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_navaidSystem/@xlink:href">
											<xsl:variable name="provides_navigable_location">
												<xsl:for-each select="$Navaid_valid-ts/aixm:navaidEquipment/aixm:NavaidComponent">
													<xsl:if test="aixm:providesNavigableLocation = 'YES'">
														<xsl:value-of select="'YES'"/>
													</xsl:if>
												</xsl:for-each>
											</xsl:variable>
											<xsl:if test="$provides_navigable_location = 'YES'">
												<xsl:variable name="Navaid_datum" select="replace(replace($Navaid_valid-ts/aixm:location/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
												<xsl:variable name="Navaid_coordinates" select="$Navaid_valid-ts/aixm:location/aixm:ElevatedPoint/gml:pos"/>
												<xsl:if test="not(empty($Navaid_coordinates)) and string-length($Navaid_coordinates) gt 0">
													<xsl:value-of select="fcn:get-latitude($Navaid_datum, $Navaid_coordinates, $coordinates_type, $coordinates_decimal_number)"/>
												</xsl:if>
											</xsl:if>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_fixDesignatedPoint/@xlink:href">
											<xsl:variable name="DPN_datum" select="replace(replace($DPN_valid-ts/aixm:location/aixm:Point/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
											<xsl:variable name="DPN_coordinates" select="$DPN_valid-ts/aixm:location/aixm:Point/gml:pos"/>
											<xsl:if test="not(empty($DPN_coordinates)) and string-length($DPN_coordinates) gt 0">
												<xsl:value-of select="fcn:get-latitude($DPN_datum, $DPN_coordinates, $coordinates_type, $coordinates_decimal_number)"/>
											</xsl:if>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>

								<!-- MSA centre Significant point - Longitude -->
								<xsl:variable name="MSA_significant_point_longitude">
									<xsl:choose>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_airportReferencePoint/@xlink:href">
											<xsl:variable name="ARP_datum" select="replace(replace($AHP_valid-ts/aixm:ARP/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
											<xsl:variable name="ARP_coordinates" select="$AHP_valid-ts/aixm:ARP/aixm:ElevatedPoint/gml:pos"/>
											<xsl:if test="not(empty($ARP_coordinates)) and string-length($ARP_coordinates) gt 0">
												<xsl:value-of select="fcn:get-longitude($ARP_datum, $ARP_coordinates, $coordinates_type, $coordinates_decimal_number)"/>
											</xsl:if>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_aimingPoint/@xlink:href">
											<xsl:variable name="TLOF_datum" select="replace(replace($TLOF_valid-ts/aixm:aimingPoint/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
											<xsl:variable name="TLOF_coordinates" select="$TLOF_valid-ts/aixm:aimingPoint/aixm:ElevatedPoint/gml:pos"/>
											<xsl:if test="not(empty($TLOF_coordinates)) and string-length($TLOF_coordinates) gt 0">
												<xsl:value-of select="fcn:get-longitude($TLOF_datum, $TLOF_coordinates, $coordinates_type, $coordinates_decimal_number)"/>
											</xsl:if>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_runwayPoint/@xlink:href">
											<xsl:variable name="RCP_datum" select="replace(replace($RCP_valid-ts/aixm:location/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
											<xsl:variable name="RCP_coordinates" select="$RCP_valid-ts/aixm:location/aixm:ElevatedPoint/gml:pos"/>
											<xsl:if test="not(empty($RCP_coordinates)) and string-length($RCP_coordinates) gt 0">
												<xsl:value-of select="fcn:get-longitude($RCP_datum, $RCP_coordinates, $coordinates_type, $coordinates_decimal_number)"/>
											</xsl:if>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_position">
											<xsl:variable name="Point_datum" select="replace(replace($MSA_valid-ts/aixm:centrePoint_position/aixm:Point/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
											<xsl:variable name="Point_coordinates" select="$MSA_valid-ts/aixm:centrePoint_position/aixm:Point/gml:pos"/>
											<xsl:if test="not(empty($Point_coordinates)) and string-length($Point_coordinates) gt 0">
												<xsl:value-of select="fcn:get-longitude($Point_datum, $Point_coordinates, $coordinates_type, $coordinates_decimal_number)"/>
											</xsl:if>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_navaidSystem/@xlink:href">
											<xsl:variable name="provides_navigable_location">
												<xsl:for-each select="$Navaid_valid-ts/aixm:navaidEquipment/aixm:NavaidComponent">
													<xsl:if test="aixm:providesNavigableLocation = 'YES'">
														<xsl:value-of select="'YES'"/>
													</xsl:if>
												</xsl:for-each>
											</xsl:variable>
											<xsl:if test="$provides_navigable_location = 'YES'">
												<xsl:variable name="Navaid_datum" select="replace(replace($Navaid_valid-ts/aixm:location/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
												<xsl:variable name="Navaid_coordinates" select="$Navaid_valid-ts/aixm:location/aixm:ElevatedPoint/gml:pos"/>
												<xsl:if test="not(empty($Navaid_coordinates)) and string-length($Navaid_coordinates) gt 0">
													<xsl:value-of select="fcn:get-longitude($Navaid_datum, $Navaid_coordinates, $coordinates_type, $coordinates_decimal_number)"/>
												</xsl:if>
											</xsl:if>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_fixDesignatedPoint/@xlink:href">
											<xsl:variable name="DPN_datum" select="replace(replace($DPN_valid-ts/aixm:location/aixm:Point/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
											<xsl:variable name="DPN_coordinates" select="$DPN_valid-ts/aixm:location/aixm:Point/gml:pos"/>
											<xsl:if test="not(empty($DPN_coordinates)) and string-length($DPN_coordinates) gt 0">
												<xsl:value-of select="fcn:get-longitude($DPN_datum, $DPN_coordinates, $coordinates_type, $coordinates_decimal_number)"/>
											</xsl:if>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								
								<xsl:variable name="MSA_significant_point_timeslice">
									<xsl:choose>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_airportReferencePoint/@xlink:href">
											<xsl:value-of select="if ($AHP_valid-ts) then concat('BASELINE ', max($AHP_valid-ts/aixm:sequenceNumber), '.', max($AHP_valid-ts/aixm:correctionNumber)) else ''"/>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_aimingPoint/@xlink:href">
											<xsl:value-of select="if ($TLOF_valid-ts) then concat('BASELINE ', max($TLOF_valid-ts/aixm:sequenceNumber), '.', max($TLOF_valid-ts/aixm:correctionNumber)) else ''"/>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_runwayPoint/@xlink:href">
											<xsl:value-of select="if ($RCP_valid-ts) then concat('BASELINE ', max($RCP_valid-ts/aixm:sequenceNumber), '.', max($RCP_valid-ts/aixm:correctionNumber)) else ''"/>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_position">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_navaidSystem/@xlink:href">
											<xsl:variable name="provides_navigable_location">
												<xsl:for-each select="$Navaid_valid-ts/aixm:navaidEquipment/aixm:NavaidComponent">
													<xsl:if test="aixm:providesNavigableLocation = 'YES'">
														<xsl:value-of select="'YES'"/>
													</xsl:if>
												</xsl:for-each>
											</xsl:variable>
											<xsl:if test="$provides_navigable_location = 'YES'">
												<xsl:value-of select="if ($Navaid_valid-ts) then concat('BASELINE ', max($Navaid_valid-ts/aixm:sequenceNumber), '.', max($Navaid_valid-ts/aixm:correctionNumber)) else ''"/>
											</xsl:if>
										</xsl:when>
										<xsl:when test="$MSA_valid-ts/aixm:centrePoint_fixDesignatedPoint/@xlink:href">
											<xsl:value-of select="if ($DPN_valid-ts) then concat('BASELINE ', max($DPN_valid-ts/aixm:sequenceNumber), '.', max($DPN_valid-ts/aixm:correctionNumber)) else ''"/>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Required navigation performance -->
								<xsl:variable name="IAP_RNP">
									<xsl:variable name="rnp_count" select="count(aixm:annotation/aixm:Note[contains(aixm:translatedNote[1]/aixm:LinguisticNote/aixm:note, 'codeRnp') or contains(aixm:translatedNote[1]/aixm:LinguisticNote/aixm:note, 'requiredNavigationPerformance')])"/>
									<xsl:choose>
										<xsl:when test="$rnp_count gt 1">
											<xsl:value-of select="'See remarks'"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:for-each select="aixm:annotation/aixm:Note">
												<xsl:variable name="note_text" select="aixm:translatedNote[1]/aixm:LinguisticNote/aixm:note"/>
												<xsl:if test="contains($note_text, 'codeRnp')">
													<xsl:variable name="after_codeRnp" select="normalize-space(substring-after($note_text, 'codeRnp:'))"/>
													<xsl:value-of select="if (contains($after_codeRnp, ' ')) then substring-before($after_codeRnp, ' ') else $after_codeRnp"/>
												</xsl:if>
											</xsl:for-each>
											<xsl:for-each select="aixm:annotation/aixm:Note">
												<xsl:variable name="note_text" select="aixm:translatedNote[1]/aixm:LinguisticNote/aixm:note"/>
												<xsl:if test="contains($note_text, 'requiredNavigationPerformance')">
													<xsl:variable name="after_rnp" select="normalize-space(substring-after($note_text, 'requiredNavigationPerformance:'))"/>
													<xsl:value-of select="if (contains($after_rnp, ' ')) then substring-before($after_rnp, ' ') else $after_rnp"/>
												</xsl:if>
											</xsl:for-each>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Communication failure description -->
								<xsl:variable name="IAP_comm_failure">
									<xsl:choose>
										<xsl:when test="not(aixm:communicationFailureInstruction)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:when test="aixm:communicationFailureInstruction/@xsi:nil = 'true'">
											<xsl:value-of select="fcn:insert-value(aixm:communicationFailureInstruction)"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:get-annotation-text(aixm:communicationFailureInstruction)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Type -->
								<xsl:variable name="IAP_type">
									<xsl:choose>
										<xsl:when test="not(aixm:approachType)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="fcn:insert-value(aixm:approachType)"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Missed approach procedure description -->
								<xsl:variable name="IAP_missed_procedure">
									<xsl:choose>
										<xsl:when test="not(aixm:missedInstruction)">
											<xsl:value-of select="''"/>
										</xsl:when>
										<xsl:when test="aixm:missedInstruction/@xsi:nil = 'true'">
											<xsl:value-of select="fcn:insert-value(aixm:missedInstruction)"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:variable name="instruction">
												<xsl:if test="aixm:missedInstruction/aixm:MissedApproachGroup/aixm:instruction">
													<xsl:value-of select="aixm:missedInstruction/aixm:MissedApproachGroup/aixm:instruction"/>
												</xsl:if>
											</xsl:variable>
											<xsl:variable name="alternateClimbInstruction">
												<xsl:if test="aixm:missedInstruction/aixm:MissedApproachGroup/aixm:alternateClimbInstruction">
													<xsl:value-of select="aixm:missedInstruction/aixm:MissedApproachGroup/aixm:alternateClimbInstruction"/>
												</xsl:if>
											</xsl:variable>
											<xsl:variable name="alternateClimbAltitude">
												<xsl:if test="aixm:missedInstruction/aixm:MissedApproachGroup/aixm:alternateClimbAltitude">
													<xsl:value-of select="aixm:missedInstruction/aixm:MissedApproachGroup/aixm:alternateClimbAltitude"/>
												</xsl:if>
											</xsl:variable>
											<xsl:variable name="alternateClimbAltitudeUom">
												<xsl:if test="aixm:missedInstruction/aixm:MissedApproachGroup/aixm:alternateClimbAltitude/@uom">
													<xsl:value-of select="aixm:missedInstruction/aixm:MissedApproachGroup/aixm:alternateClimbAltitude/@uom"/>
												</xsl:if>
											</xsl:variable>
											<xsl:variable name="formattedInstruction" select="if (string-length($instruction) gt 0) then concat('Instruction: ', $instruction) else ''"/>
											<xsl:variable name="formattedAlternateClimbInstruction" select="if (string-length($alternateClimbInstruction) gt 0) then concat('Alternate climb instruction: ', $alternateClimbInstruction) else ''"/>
											<xsl:variable name="formattedAlternateClimbAltitude" select="if (string-length($alternateClimbAltitude) gt 0) then concat('Alternate altitude: ', $alternateClimbAltitude, if (string-length($alternateClimbAltitudeUom) gt 0) then concat(' ', $alternateClimbAltitudeUom) else '') else ''"/>
											<xsl:value-of select="string-join(($formattedInstruction[string-length(.) gt 0], $formattedAlternateClimbInstruction[string-length(.) gt 0], $formattedAlternateClimbAltitude[string-length(.) gt 0]), '&#10;')"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								
								<!-- Remarks -->
								<xsl:variable name="IAP_remarks">
									<xsl:variable name="dataset_creation_date" select="//aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
									<xsl:variable name="rnp_count" select="count(aixm:annotation/aixm:Note[contains(aixm:translatedNote[1]/aixm:LinguisticNote/aixm:note, 'codeRnp') or contains(aixm:translatedNote[1]/aixm:LinguisticNote/aixm:note, 'requiredNavigationPerformance')])"/>
									<xsl:if test="string-length($dataset_creation_date) gt 0">
										<xsl:value-of select="concat('Current time: ', $dataset_creation_date)"/>
									</xsl:if>
									<xsl:for-each select="aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[($rnp_count gt 1 or (not(contains(aixm:note, 'codeRnp')) or not(contains(aixm:note, 'requiredNavigationPerformance'))))]">
										<xsl:choose>
											<xsl:when test="position() = 1 and string-length($dataset_creation_date) = 0">
												<xsl:value-of select="concat('(', if (../../aixm:propertyName) then (concat(../../aixm:propertyName, ';')) else '', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', ') ', fcn:get-annotation-text(aixm:note))"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="concat(' | ', '(', if (../../aixm:propertyName) then (concat(../../aixm:propertyName, ';')) else '', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', ') ', fcn:get-annotation-text(aixm:note))"/>
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
									<xsl:if test="aixm:extension/ead-audit:InstrumentApproachProcedureExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate">
										<xsl:value-of select="fcn:get-date(aixm:extension/ead-audit:InstrumentApproachProcedureExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)"/>
									</xsl:if>
								</xsl:variable>
								
								<!-- Internal UID (master) -->
								<xsl:variable name="IAP_UUID" select="../../gml:identifier"/>
								
								<!-- Valid TimeSlice -->
								<xsl:variable name="IAP_timeslice" select="concat('BASELINE ', $max-sequence, '.', $max-correction)"/>
								
								<!-- Originator -->
								<xsl:variable name="originator" select="aixm:extension/ead-audit:InstrumentApproachProcedureExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
								
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
									<td><xsl:value-of select="if (string-length($IAP_designator) gt 0) then $IAP_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($IAP_aircraft_category) gt 0) then $IAP_aircraft_category else '&#160;'"/></td>
								</tr>
								<tr>
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($IAP_transition_identifier) gt 0"><xsl:value-of select="$IAP_transition_identifier" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($FATO_TLOF_designator) gt 0) then $FATO_TLOF_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($FATO_designator) gt 0) then $FATO_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($FATO_timeslice) gt 0) then $FATO_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($FATO_direction) gt 0) then $FATO_direction else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($FATO_direction_timeslice) gt 0) then $FATO_direction_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RWY_designator) gt 0) then $RWY_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RWY_timeslice) gt 0) then $RWY_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_designator) gt 0) then $RDN_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($RDN_timeslice) gt 0) then $RDN_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($TLOF_designator) gt 0) then $TLOF_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($TLOF_timeslice) gt 0) then $TLOF_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($MSA_NDB_navaid_designator) gt 0) then $MSA_NDB_navaid_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($MSA_NDB_navaid_latitude) gt 0) then $MSA_NDB_navaid_latitude else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($MSA_NDB_navaid_longitude) gt 0) then $MSA_NDB_navaid_longitude else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($NDB_navaid_timeslice) gt 0) then $NDB_navaid_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($MSA_VOR_navaid_designator) gt 0) then $MSA_VOR_navaid_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($MSA_VOR_navaid_latitude) gt 0) then $MSA_VOR_navaid_latitude else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($MSA_VOR_navaid_longitude) gt 0) then $MSA_VOR_navaid_longitude else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($VOR_navaid_timeslice) gt 0) then $VOR_navaid_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($MSA_significant_point_type) gt 0) then $MSA_significant_point_type else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($MSA_significant_point_designator) gt 0) then $MSA_significant_point_designator else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($MSA_significant_point_latitude) gt 0) then $MSA_significant_point_latitude else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($MSA_significant_point_longitude) gt 0) then $MSA_significant_point_longitude else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($MSA_significant_point_timeslice) gt 0) then $MSA_significant_point_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($MSA_timeslice) gt 0) then $MSA_timeslice else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($IAP_RNP) gt 0) then $IAP_RNP else '&#160;'"/></td>
								</tr>
								<tr>
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($IAP_comm_failure) gt 0"><xsl:value-of select="$IAP_comm_failure" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($IAP_type) gt 0) then $IAP_type else '&#160;'"/></td>
								</tr>
								<tr>
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($IAP_missed_procedure) gt 0"><xsl:value-of select="$IAP_missed_procedure" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
								</tr>
								<tr>
									<td xml:space="preserve"><xsl:choose><xsl:when test="string-length($IAP_remarks) gt 0"><xsl:value-of select="$IAP_remarks" disable-output-escaping="yes"/></xsl:when><xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise></xsl:choose></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($commit_date) gt 0) then $commit_date else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($IAP_UUID) gt 0) then $IAP_UUID else '&#160;'"/></td>
								</tr>
								<tr>
									<td><xsl:value-of select="if (string-length($IAP_timeslice) gt 0) then $IAP_timeslice else '&#160;'"/></td>
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