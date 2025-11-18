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
	
	<xsl:template match="/">
		
		<SdoReportResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="SdoReportMgmt.xsd" origin="SDO" version="4.1">
			<SdoReportResult>
				
				<xsl:for-each select="//aixm:DesignatedPoint">
					
					<xsl:sort select="(aixm:timeSlice/aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)][aixm:correctionNumber = max(../aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)]/aixm:correctionNumber)])[1]/aixm:designator" order="ascending"/>
					
					<!-- Get all BASELINE time slices for this feature -->
					<xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:DesignatedPointTimeSlice[aixm:interpretation = 'BASELINE']"/>
					<!-- Find the maximum sequenceNumber -->
					<xsl:variable name="max-sequence" select="max($baseline-timeslices/aixm:sequenceNumber)"/>
					<!-- Get time slices with the maximum sequenceNumber, then find max correctionNumber -->
					<xsl:variable name="max-correction" select="max($baseline-timeslices[aixm:sequenceNumber = $max-sequence]/aixm:correctionNumber)"/>
					<!-- Select the latest time slice -->
					<xsl:variable name="latest-timeslice" select="$baseline-timeslices[aixm:sequenceNumber = $max-sequence and aixm:correctionNumber = $max-correction][1]"/>
					
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
							<xsl:variable name="DPN_datum">
								<xsl:value-of select="replace(replace(aixm:location/aixm:Point/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
							</xsl:variable>
							
							<!-- Extract coordinates depending on the coordinate system -->
							<xsl:variable name="coordinates" select="aixm:location/aixm:Point/gml:pos"/>
							<xsl:variable name="latitude_decimal">
								<xsl:choose>
									<xsl:when test="$DPN_datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
										<xsl:value-of  select="number(substring-before($coordinates, ' '))"/>
									</xsl:when>
									<xsl:when test="matches($DPN_datum, '^OGC:.*CRS84$')">
										<xsl:value-of select="number(substring-after($coordinates, ' '))"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							<xsl:variable name="longitude_decimal">
								<xsl:choose>
									<xsl:when test="$DPN_datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
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
							<xsl:variable name="DPN_timeslice" select="concat('BASELINE ', $max-sequence, '.', $max-correction)"/>
							
							<txtRmk><xsl:value-of select="concat('UUID: ', $DPN_uuid)"/><xsl:text>&#xa;</xsl:text><xsl:value-of select="concat('Valid TimeSlice: ', $DPN_timeslice)"/></txtRmk>
							
						</Record>
						
					</xsl:for-each>
					
				</xsl:for-each>
				
			</SdoReportResult>
		</SdoReportResponse>
		
	</xsl:template>
	
</xsl:transform>