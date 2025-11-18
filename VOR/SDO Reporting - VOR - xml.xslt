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
                    featureTypes: aixm:Navaid aixm:OrganisationAuthority aixm:InformationService
  includeReferencedFeaturesLevel: 2
               featureOccurrence: aixm:Navaid.aixm:type EQUALS 'VOR' OR aixm:Navaid.aixm:type EQUALS 'VOR_DME' OR aixm:Navaid.aixm:type EQUALS 'VORTAC'
               permanentBaseline: true
                       dataScope: ReleasedData
                     AIXMversion: 5.1.1
  include indirect reference from Service
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

	<xsl:function name="fcn:get-last-word" as="xs:string">
		<xsl:param name="text" as="xs:string"/>
		<xsl:variable name="words" select="tokenize(normalize-space($text), '\s+')"/>
		<xsl:sequence select="$words[last()]"/>
	</xsl:function>

	<xsl:function name="fcn:get-date" as="xs:string">
		<xsl:param name="text" as="xs:string"/>
		<xsl:variable name="date-time" select="$text"/>
		<xsl:variable name="day" select="substring($date-time, 9, 2)"/>
		<xsl:variable name="month" select="substring($date-time, 6, 2)"/>
		<xsl:variable name="month" select="if($month = '01') then 'JAN' else if ($month = '02') then 'FEB' else if ($month = '03') then 'MAR' else    if ($month = '04') then 'APR' else if ($month = '05') then 'MAY' else if ($month = '06') then 'JUN' else if ($month = '07') then 'JUL' else    if ($month = '08') then 'AUG' else if ($month = '09') then 'SEP' else if ($month = '10') then 'OCT' else if ($month = '11') then 'NOV' else if ($month = '12') then 'DEC' else ''"/>
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
				<xsl:value-of select="concat(format-number($degrees, '00'), format-number($minutes, '00'), format-number($seconds, $format-string), if ($lat_decimal ge 0) then 'N' else 'S')"/>
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
				<xsl:value-of select="concat(format-number($degrees, '000'), format-number($minutes, '00'), format-number($seconds, $format-string), if ($lon_decimal ge 0) then 'E' else 'W')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="string($lon_decimal)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- Recursively find STATE organization from an organization UUID -->
	<xsl:function name="fcn:find-state-org" as="element()?">
		<xsl:param name="org-uuid" as="xs:string"/>
		<xsl:param name="visited-uuids" as="xs:string*"/>
		<xsl:param name="root" as="document-node()"/>
		<!-- Prevent infinite loops by checking if we've already visited this UUID -->
		<xsl:if test="not($org-uuid = $visited-uuids) and string-length($org-uuid) gt 0">
			<!-- Get the organization feature -->
			<xsl:variable name="org-feature" select="$root//aixm:OrganisationAuthority[gml:identifier = $org-uuid]"/>
			<xsl:if test="$org-feature">
				<!-- Get the valid baseline timeslice -->
				<xsl:variable name="org-baseline-ts" select="$org-feature/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice[aixm:interpretation = 'BASELINE']"/>
				<xsl:variable name="org-max-seq" select="max($org-baseline-ts/aixm:sequenceNumber)"/>
				<xsl:variable name="org-max-corr" select="max($org-baseline-ts[aixm:sequenceNumber = $org-max-seq]/aixm:correctionNumber)"/>
				<xsl:variable name="org-valid-ts" select="$org-baseline-ts[aixm:sequenceNumber = $org-max-seq and aixm:correctionNumber = $org-max-corr][1]"/>
				<xsl:choose>
					<!-- If this organization is a STATE, return it -->
					<xsl:when test="$org-valid-ts/aixm:type = 'STATE'">
						<xsl:sequence select="$org-valid-ts"/>
					</xsl:when>
					<!-- Otherwise, check if it has a related organization -->
					<xsl:when test="$org-valid-ts/aixm:relatedOrganisationAuthority/aixm:OrganisationAuthorityAssociation/aixm:theOrganisationAuthority/@xlink:href">
						<xsl:variable name="related-uuid" select="replace($org-valid-ts/aixm:relatedOrganisationAuthority/aixm:OrganisationAuthorityAssociation/aixm:theOrganisationAuthority/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
						<!-- Recursively search the related organization -->
						<xsl:sequence select="fcn:find-state-org($related-uuid, ($visited-uuids, $org-uuid), $root)"/>
					</xsl:when>
				</xsl:choose>
			</xsl:if>
		</xsl:if>
	</xsl:function>

	<!-- Function to format working hours -->
	<xsl:function name="fcn:format-working-hours" as="xs:string">
		<xsl:param name="availability-elements" as="element()*"/>
		<xsl:variable name="result">
			<xsl:choose>
				<!-- if there is at least one availability element -->
				<xsl:when test="count($availability-elements) ge 1">
					<xsl:for-each select="$availability-elements">
						<xsl:choose>
							<!-- insert 'H24' if there is an availability with operationalStatus='OPERATIONAL' and no Timesheet -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and (not(aixm:timeInterval/@nilReason) or aixm:timeInterval/@nilReason='inapplicable')) and not(aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HX') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HO') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'NOTAM') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'HOL') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SS') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SR') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'MON') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'TUE') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'WED') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'THU') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'FRI') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SAT') or contains(aixm:note[not(@lang) or @lang=('en','eng')], 'SUN')]]) and aixm:operationalStatus = 'OPERATIONAL'">
								<xsl:value-of select="'H24'"/>
							</xsl:when>
							<!-- insert 'H24' if there is an availability with operationalStatus='OPERATIONAL' and a continuous service 24/7 Timesheet -->
							<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and (not(aixm:dayTil) or aixm:dayTil/@xsi:nil='true' or aixm:dayTil='ANY') and aixm:startTime='00:00' and aixm:endTime=('00:00','23:59','24:00') and (aixm:daylightSavingAdjust=('NO','YES') or aixm:daylightSavingAdjust/@xsi:nil='true' or not(aixm:daylightSavingAdjust)) and ((aixm:startDate='01-01' and aixm:endDate='31-12') or ((not(aixm:startDate) or aixm:startDate/@xsi:nil='true') and (not(aixm:endDate) or aixm:endDate/@xsi:nil='true'))) and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
								<xsl:value-of select="'H24'"/>
							</xsl:when>
							<!-- insert 'HJ' if there is an availability with operationalStatus='OPERATIONAL' and a sunrise to sunset Timesheet -->
							<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SR' and aixm:endEvent='SS' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@xsi:nil='true') and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
								<xsl:value-of select="'HJ'"/>
							</xsl:when>
							<!-- insert 'HN' if there is an availability with operationalStatus='OPERATIONAL' and a sunset to sunrise Timesheet -->
							<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SS' and aixm:endEvent='SR' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@xsi:nil='true') and aixm:excluded='NO'] and aixm:operationalStatus = 'OPERATIONAL'">
								<xsl:value-of select="'HN'"/>
							</xsl:when>
							<!-- insert 'HX' if there is an availability with operationalStatus='OPERATIONAL', no Timesheet and corresponding note -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'HX')] and aixm:operationalStatus = 'OPERATIONAL'">
								<xsl:value-of select="'HX'"/>
							</xsl:when>
							<!-- insert 'HO' if there is an availability with operationalStatus='OPERATIONAL', no Timesheet and corresponding note -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'HO')] and aixm:operationalStatus = 'OPERATIONAL'">
								<xsl:value-of select="'HO'"/>
							</xsl:when>
							<!-- insert 'NOTAM' if there is an availability with operationalStatus='OPERATIONAL', no Timesheet and corresponding note -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'notam') and not(contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'outside'))]">
								<xsl:value-of select="'NOTAM'"/>
							</xsl:when>
							<!-- insert 'U/S' if there is an availability with operationalStatus='UNSERVICEABLE' and no Timesheet -->
							<xsl:when test="((not(aixm:timeInterval) or aixm:timeInterval/@xsi:nil='true') and not(aixm:timeInterval/@nilReason)) and aixm:operationalStatus = 'UNSERVICEABLE'">
								<xsl:value-of select="'OTHER'"/>
							</xsl:when>
							<!-- insert nil reason if provided -->
							<xsl:when test="aixm:timeInterval/@xsi:nil='true' and aixm:timeInterval/@nilReason and not(aixm:timeInterval/@nilReason='inapplicable')">
								<xsl:value-of select="'OTHER'"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="'TIMSH'"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:sequence select="string($result)"/>
	</xsl:function>

	<!-- Get annotation text escaping special HTML characters -->
	<xsl:function name="fcn:get-annotation-text" as="xs:string">
		<xsl:param name="raw_text" as="xs:string"/>
		<!-- First, escape special HTML characters in the raw text before processing -->
		<xsl:variable name="escaped_raw_text" select="replace(replace($raw_text, '&lt;', '&amp;lt;'), '&gt;', '&amp;gt;')"/>
		<xsl:variable name="lines" select="for $line in tokenize($escaped_raw_text, '&#xA;') return normalize-space($line)"/>
		<xsl:variable name="non_empty_lines" select="$lines[string-length(.) gt 0]"/>
		<xsl:value-of select="string-join($non_empty_lines, '&#10;')"/>
	</xsl:function>

	<!-- Translate CodeDayType values -->
	<xsl:function name="fcn:translate-code-day" as="xs:string">
		<xsl:param name="code_day" as="xs:string"/>
		<xsl:choose>
			<xsl:when test="$code_day = 'WORK_DAY'">WD</xsl:when>
			<xsl:when test="$code_day = 'BEF_WORK_DAY'">PWD</xsl:when>
			<xsl:when test="$code_day = 'AFT_WORK_DAY'">AWD</xsl:when>
			<xsl:when test="$code_day = 'HOL'">LH</xsl:when>
			<xsl:when test="$code_day = 'BEF_HOL'">PLH</xsl:when>
			<xsl:when test="$code_day = 'AFT_HOL'">ALH</xsl:when>
			<xsl:otherwise><xsl:value-of select="$code_day"/></xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- Check if CodeDayType should be skipped -->
	<xsl:function name="fcn:should-skip-code-day" as="xs:boolean">
		<xsl:param name="code_day" as="xs:string"/>
		<xsl:sequence select="$code_day = 'BUSY_FRI' or starts-with($code_day, 'OTHER')"/>
	</xsl:function>

	<!-- Translate event interpretation -->
	<xsl:function name="fcn:translate-event-interpretation" as="xs:string">
		<xsl:param name="interpretation" as="xs:string"/>
		<xsl:choose>
			<xsl:when test="$interpretation = 'EARLIEST'">E</xsl:when>
			<xsl:when test="$interpretation = 'LATEST'">L</xsl:when>
			<xsl:otherwise><xsl:value-of select="$interpretation"/></xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<xsl:template match="/">
		
		<xsl:element name="SdoReportResponse" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<xsl:attribute name="created" select="//aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
			<xsl:attribute name="xsi:noNamespaceSchemaLocation" select="'SdoReportMgmt.xsd'"/>
			<xsl:attribute name="origin" select="'SDO'"/>
			<xsl:attribute name="version" select="'4.1'"/>
			<SdoReportResult>
				
				<xsl:for-each select="//aixm:VOR">

					<xsl:sort select="(aixm:timeSlice/aixm:VORTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:VORTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)][aixm:correctionNumber = max(../aixm:VORTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:VORTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)]/aixm:correctionNumber)])[1]/aixm:designator" order="ascending"/>
					<!-- Get all BASELINE time slices for this feature -->
					<xsl:variable name="baseline-timeslices" select="aixm:timeSlice/aixm:VORTimeSlice[aixm:interpretation = 'BASELINE']"/>
					<!-- Find the maximum sequenceNumber -->
					<xsl:variable name="max-sequence" select="max($baseline-timeslices/aixm:sequenceNumber)"/>
					<!-- Get time slices with the maximum sequenceNumber, then find max correctionNumber -->
					<xsl:variable name="max-correction" select="max($baseline-timeslices[aixm:sequenceNumber = $max-sequence]/aixm:correctionNumber)"/>
					<!-- Select the valid time slice -->
					<xsl:variable name="valid-timeslice" select="$baseline-timeslices[aixm:sequenceNumber = $max-sequence and aixm:correctionNumber = $max-correction][1]"/>
		
					<xsl:for-each select="$valid-timeslice">
		
						<!-- Internal UID (master) -->
						<xsl:variable name="VOR_UUID" select="../../gml:identifier"/>
		
						<!-- VOR - Valid TimeSlice -->
						<xsl:variable name="VOR_timeslice" select="concat('BASELINE ', $max-sequence, '.', $max-correction)"/>
		
						<!-- Identification -->
						<xsl:variable name="VOR_designator" select="aixm:designator"/>
		
						<!-- VOR Coordinates -->
		
						<!-- Select the type of coordinates: 'DMS' or 'DEC' -->
						<xsl:variable name="coordinates_type" select="'DMS'"/>
		
						<!-- Select the number of decimals -->
						<xsl:variable name="coordinates_decimal_number" select="2"/>
		
						<!-- VOR Datum -->
						<xsl:variable name="VOR_datum">
							<xsl:value-of select="replace(replace(aixm:location/aixm:ElevatedPoint/@srsName, 'urn:ogc:def:crs:', ''), '::', ':')"/>
						</xsl:variable>
						
						<!-- Extract coordinates depending on the coordinate system -->
						<xsl:variable name="VOR_coordinates" select="aixm:location/aixm:ElevatedPoint/gml:pos"/>
						<xsl:variable name="VOR_latitude_decimal">
							<xsl:choose>
								<xsl:when test="$VOR_datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
									<xsl:value-of  select="number(substring-before($VOR_coordinates, ' '))"/>
								</xsl:when>
								<xsl:when test="matches($VOR_datum, '^OGC:.*CRS84$')">
									<xsl:value-of select="number(substring-after($VOR_coordinates, ' '))"/>
								</xsl:when>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="VOR_longitude_decimal">
							<xsl:choose>
								<xsl:when test="$VOR_datum = ('EPSG:4326','EPSG:4269','EPSG:4258')">
									<xsl:value-of  select="number(substring-after($VOR_coordinates, ' '))"/>
								</xsl:when>
								<xsl:when test="matches($VOR_datum, '^OGC:.*CRS84$')">
									<xsl:value-of select="number(substring-before($VOR_coordinates, ' '))"/>
								</xsl:when>
							</xsl:choose>
						</xsl:variable>
						<xsl:variable name="VOR_lat">
							<xsl:if test="string-length($VOR_latitude_decimal) gt 0">
								<xsl:value-of select="fcn:format-latitude($VOR_latitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
							</xsl:if>
						</xsl:variable>
						<xsl:variable name="VOR_long">
							<xsl:if test="string-length($VOR_longitude_decimal) gt 0">
								<xsl:value-of select="fcn:format-longitude($VOR_longitude_decimal, $coordinates_type, $coordinates_decimal_number)"/>
							</xsl:if>
						</xsl:variable>

						<!-- Name -->
						<xsl:variable name="VOR_name" select="aixm:name"/>
		
						<!-- Type -->
						<xsl:variable name="VOR_type" select="aixm:type"/>
		
						<!-- Frequency -->
						<xsl:variable name="VOR_frequency" select="aixm:frequency"/>
		
						<!-- Unit of measurement [frequency] -->
						<xsl:variable name="VOR_frequency_uom" select="aixm:frequency/@uom"/>
		
						<!-- North reference -->
						<xsl:variable name="VOR_north_reference" select="aixm:zeroBearingDirection"/>
		
						<!-- Station declination -->
						<xsl:variable name="VOR_station_declination" select="aixm:declination"/>
		
						<!-- Magnetic variation -->
						<xsl:variable name="VOR_magnetic_variation" select="aixm:magneticVariation"/>
		
						<!-- Magnetic variation date -->
						<xsl:variable name="VOR_magnetic_variation_date" select="aixm:dateMagneticVariation"/>
		
						<!-- Emission -->
						<xsl:variable name="VOR_emission" select="aixm:emissionClass"/>
		
						<!-- Geographical accuracy -->
						<xsl:variable name="VOR_geographical_accuracy" select="aixm:location/aixm:ElevatedPoint/aixm:horizontalAccuracy"/>
		
						<!-- Unit of measurement [geographical accuracy] -->
						<xsl:variable name="VOR_geographical_accuracy_uom" select="aixm:horizontalAccuracy/@uom"/>
		
						<!-- Elevation -->
						<xsl:variable name="VOR_elevation" select="aixm:location/aixm:ElevatedPoint/aixm:elevation"/>
		
						<!-- Elevation accuracy -->
						<xsl:variable name="VOR_elevation_accuracy" select="aixm:location/aixm:ElevatedPoint/aixm:verticalAccuracy"/>
		
						<!-- Geoid undulation -->
						<xsl:variable name="VOR_geoid_undulation" select="aixm:location/aixm:ElevatedPoint/aixm:geoidUndulation"/>
		
						<!-- Unit of measurement [vertical distance] -->
						<xsl:variable name="VOR_vertical_distance_uom">
							<xsl:choose>
								<xsl:when test="aixm:location/aixm:ElevatedPoint/aixm:elevation/@uom">
									<xsl:value-of select="aixm:location/aixm:ElevatedPoint/aixm:elevation/@uom"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:choose>
										<xsl:when test="aixm:location/aixm:ElevatedPoint/aixm:verticalAccuracy/@uom">
											<xsl:value-of select="aixm:location/aixm:ElevatedPoint/aixm:verticalAccuracy/@uom"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:choose>
												<xsl:when test="aixm:location/aixm:ElevatedPoint/aixm:geoidUndulation/@uom">
													<xsl:value-of select="aixm:location/aixm:ElevatedPoint/aixm:geoidUndulation/@uom"/>
												</xsl:when>
											</xsl:choose>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
		
						<!-- Cyclic redundancy check -->
						<xsl:variable name="VOR_CRC">
							<xsl:if test="aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note[not(@lang) or @lang=('en','eng')], 'CRC:')]/aixm:note">
								<xsl:value-of select="fcn:get-last-word(aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note[not(@lang) or @lang=('en','eng')], 'CRC:')]/aixm:note[not(@lang) or @lang=('en','eng')])"/>
							</xsl:if>
						</xsl:variable>
		
						<!-- Vertical Datum -->
						<xsl:variable name="VOR_vertical_datum" select="aixm:location/aixm:ElevatedPoint/aixm:verticalDatum"/>
		
						<!-- Working hours -->
						<xsl:variable name="VOR_working_hours">
							<xsl:choose>
								<!-- Check if VOR has at least one availability (excluding xsi:nil='true') -->
								<xsl:when test="aixm:availability[not(@xsi:nil='true')]">
									<xsl:value-of select="fcn:format-working-hours(aixm:availability/aixm:NavaidOperationalStatus)"/>
								</xsl:when>
								<!-- Check if corresponding Navaid has at least one availability (excluding xsi:nil='true') -->
								<xsl:otherwise>
									<!-- Find the Navaid that references this VOR -->
									<xsl:variable name="navaid-with-VOR" select="//aixm:Navaid[.//aixm:navaidEquipment/aixm:NavaidComponent/aixm:theNavaidEquipment/@xlink:href = concat('urn:uuid:', $VOR_UUID)]"/>
									<xsl:variable name="navaid-baseline-ts" select="$navaid-with-VOR/aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE']"/>
									<xsl:variable name="navaid-max-seq" select="max($navaid-baseline-ts/aixm:sequenceNumber)"/>
									<xsl:variable name="navaid-max-corr" select="max($navaid-baseline-ts[aixm:sequenceNumber = $navaid-max-seq]/aixm:correctionNumber)"/>
									<xsl:variable name="navaid-valid-ts" select="$navaid-baseline-ts[aixm:sequenceNumber = $navaid-max-seq and aixm:correctionNumber = $navaid-max-corr][1]"/>
									<xsl:choose>
										<!-- If Navaid has at least one availability (excluding xsi:nil='true') -->
										<xsl:when test="$navaid-valid-ts/aixm:availability[not(@xsi:nil='true')]">
											<xsl:value-of select="fcn:format-working-hours($navaid-valid-ts/aixm:availability/aixm:NavaidOperationalStatus)"/>
										</xsl:when>
										<!-- If both VOR and Navaid have no availability (or only with xsi:nil='true'), check if VOR has xsi:nil='true' -->
										<xsl:otherwise>
											<!-- do nothing -->
										</xsl:otherwise>
									</xsl:choose>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:variable>
		
						<!-- Remark to working hours -->
						<xsl:variable name="VOR_working_hours_remarks">
							<!-- Collect timesheet warnings first -->
							<xsl:variable name="timesheet_warnings">
								<!-- Get timesheets from VOR, or from parent Navaid if VOR has none -->
								<xsl:variable name="timesheets" select="if (count(aixm:availability/aixm:NavaidOperationalStatus/aixm:timeInterval/aixm:Timesheet) gt 0) then aixm:availability/aixm:NavaidOperationalStatus/aixm:timeInterval/aixm:Timesheet else //aixm:Navaid[.//aixm:navaidEquipment/aixm:NavaidComponent/aixm:theNavaidEquipment/@xlink:href = concat('urn:uuid:', $VOR_UUID)]/aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)][aixm:correctionNumber = max(../aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)]/aixm:correctionNumber)][1]/aixm:availability/aixm:NavaidOperationalStatus/aixm:timeInterval/aixm:Timesheet"/>
								<xsl:for-each select="$timesheets">
									<xsl:variable name="warnings_for_this_sheet">
										<!-- Check for BUSY_FRI or OTHER CodeDayType -->
										<xsl:if test="fcn:should-skip-code-day(string(aixm:day))">
											<xsl:value-of select="concat('Found Timesheet with day value equal to ', aixm:day, '&#10;')"/>
										</xsl:if>
										<xsl:if test="aixm:dayTil and fcn:should-skip-code-day(string(aixm:dayTil))">
											<xsl:value-of select="concat('Timesheet contains CodeDayType with dayTil value equal to ', aixm:dayTil, '&#10;')"/>
										</xsl:if>
										<!-- Check for non-MIN uom in time relative events -->
										<xsl:if test="aixm:startTimeRelativeEvent and aixm:startTimeRelativeEvent/@uom and aixm:startTimeRelativeEvent/@uom != 'MIN'">
											<xsl:text>Found Timesheet with startTimeRelativeEvent uom not equal to 'MIN'&#10;</xsl:text>
										</xsl:if>
										<xsl:if test="aixm:endTimeRelativeEvent and aixm:endTimeRelativeEvent/@uom and aixm:endTimeRelativeEvent/@uom != 'MIN'">
											<xsl:text>Found Timesheet with endTimeRelativeEvent uom not equal to 'MIN'&#10;</xsl:text>
										</xsl:if>
										<!-- Check for timeReference other than UTC -->
										<xsl:if test="aixm:timeReference and not(aixm:timeReference/@xsi:nil='true') and aixm:timeReference != 'UTC'">
											<xsl:text>Found Timesheet with timeReference value other than 'UTC'&#10;</xsl:text>
										</xsl:if>
										<!-- Check for excluded = YES -->
										<xsl:if test="aixm:excluded and not(aixm:excluded/@xsi:nil='true') and aixm:excluded = 'YES'">
											<xsl:text>Found Timesheet with excluded value equal to 'YES'&#10;</xsl:text>
										</xsl:if>
									</xsl:variable>
									<xsl:value-of select="$warnings_for_this_sheet"/>
								</xsl:for-each>
							</xsl:variable>
							<!-- Remove trailing line break if any -->
							<xsl:variable name="trimmed_warnings" select="if (ends-with($timesheet_warnings, '&#10;')) then substring($timesheet_warnings, 1, string-length($timesheet_warnings) - 1) else $timesheet_warnings"/>
							<!-- Output warnings first if any -->
							<xsl:if test="string-length($trimmed_warnings) gt 0">
								<xsl:value-of select="$trimmed_warnings"/>
							</xsl:if>
							<!-- Then add annotation notes -->
							<xsl:for-each select=".//aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']/aixm:translatedNote/aixm:LinguisticNote">
								<xsl:choose>
									<xsl:when test="position() = 1 and string-length($trimmed_warnings) = 0">
										<xsl:value-of select="concat('(', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', ') ', fcn:get-annotation-text(aixm:note))"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="concat('&#10;(', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', ') ', fcn:get-annotation-text(aixm:note))"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>
						</xsl:variable>

						<!-- Remarks -->
						<xsl:variable name="VOR_remarks">
							<xsl:variable name="dataset_creation_date" select="//aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
							<xsl:if test="string-length($dataset_creation_date) gt 0">
								<xsl:value-of select="concat('Current time: ', $dataset_creation_date)"/>
							</xsl:if>
							<xsl:for-each select="aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote">
								<xsl:if test="((../../aixm:propertyName and (not(../../aixm:propertyName/@xsi:nil='true') or not(../../aixm:propertyName/@xsi:nil))) or not(../../aixm:propertyName)) and not(contains(aixm:note, 'CRC:'))">
									<xsl:choose>
										<xsl:when test="string-length($dataset_creation_date) = 0">
											<xsl:value-of select="concat('(', if (../../aixm:propertyName) then (concat(../../aixm:propertyName, ';')) else '', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', ') ', fcn:get-annotation-text(aixm:note))"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="concat('&#10;', '(', if (../../aixm:propertyName) then (concat(../../aixm:propertyName, ';')) else '', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', ') ', fcn:get-annotation-text(aixm:note))"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:if>
							</xsl:for-each>
						</xsl:variable>
		
						<!-- Effective date -->
						<xsl:variable name="day" select="substring(gml:validTime/gml:TimePeriod/gml:beginPosition, 9, 2)"/>
						<xsl:variable name="month" select="substring(gml:validTime/gml:TimePeriod/gml:beginPosition, 6, 2)"/>
						<xsl:variable name="month" select="if($month = '01') then 'JAN' else if ($month = '02') then 'FEB' else if ($month = '03') then 'MAR' else if ($month = '04') then 'APR' else if ($month = '05') then 'MAY' else if ($month = '06') then 'JUN' else if ($month = '07') then 'JUL' else if ($month = '08') then 'AUG' else if ($month = '09') then 'SEP' else if ($month = '10') then 'OCT' else if ($month = '11') then 'NOV' else if ($month = '12') then 'DEC' else ''"/>
						<xsl:variable name="year" select="substring(gml:validTime/gml:TimePeriod/gml:beginPosition, 1, 4)"/>
						<xsl:variable name="VOR_effective_date" select="concat($day, '-', $month, '-', $year)"/>
		
						<!-- Committed on -->
						<xsl:variable name="VOR_commit_date">
							<xsl:if test="aixm:extension/ead-audit:VORExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate">
								<xsl:value-of select="fcn:get-date(aixm:extension/ead-audit:VORExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)"/>
							</xsl:if>
						</xsl:variable>
		
						<!-- Originator -->
						<xsl:variable name="originator" select="aixm:extension/ead-audit:VORExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
		
						<Record>
							<xsl:if test="string-length($VOR_designator) gt 0">
								<codeId><xsl:value-of select="$VOR_designator"/></codeId>
							</xsl:if>
							<xsl:if test="string-length($VOR_lat) gt 0">
								<geoLat><xsl:value-of select="$VOR_lat"/></geoLat>
							</xsl:if>
							<xsl:if test="string-length($VOR_long) gt 0">
								<geoLong><xsl:value-of select="$VOR_long"/></geoLong>
							</xsl:if>
							<!-- Create individual <Org> element for each responsible authority -->
							<xsl:for-each select="aixm:authority/aixm:AuthorityForNavaidEquipment">
								<xsl:variable name="OrgAuth_UUID" select="replace(aixm:theOrganisationAuthority/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<xsl:variable name="org-baseline-ts" select="//aixm:OrganisationAuthority[gml:identifier = $OrgAuth_UUID]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="org-max-seq" select="max($org-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="org-max-corr" select="max($org-baseline-ts[aixm:sequenceNumber = $org-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="org-valid-ts" select="$org-baseline-ts[aixm:sequenceNumber = $org-max-seq and aixm:correctionNumber = $org-max-corr][1]"/>
								<xsl:if test="$org-valid-ts">
									<Org>
										<txtName><xsl:value-of select="$org-valid-ts/aixm:name"/></txtName>
										<txtRmk>
											<xsl:text>Role: </xsl:text>
											<xsl:value-of select="aixm:type"/>
											<xsl:text>&#10;Valid TimeSlice: BASELINE </xsl:text>
											<xsl:value-of select="concat($org-max-seq, '.', $org-max-corr)"/>
										</txtRmk>
									</Org>
								</xsl:if>
							</xsl:for-each>
							<!-- Add Service information for each InformationService -->
							<xsl:variable name="info_services" select="//aixm:InformationService[.//aixm:navaidBroadcast/@xlink:href = concat('urn:uuid:', $VOR_UUID)]"/>
							<xsl:for-each select="$info_services">
								<!-- Get the valid BASELINE time slice for this InformationService -->
								<xsl:variable name="info-baseline-ts" select="aixm:timeSlice/aixm:InformationServiceTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="info-max-seq" select="max($info-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="info-max-corr" select="max($info-baseline-ts[aixm:sequenceNumber = $info-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="info-valid-ts" select="$info-baseline-ts[aixm:sequenceNumber = $info-max-seq and aixm:correctionNumber = $info-max-corr][1]"/>
								<!-- Get the service provider UUID -->
								<xsl:variable name="service-provider-uuid" select="replace($info-valid-ts/aixm:serviceProvider/@xlink:href, '^(urn:uuid:|#uuid\.)', '')"/>
								<!-- Get the service provider Unit -->
								<xsl:variable name="provider-baseline-ts" select="//aixm:Unit[gml:identifier = $service-provider-uuid]/aixm:timeSlice/aixm:UnitTimeSlice[aixm:interpretation = 'BASELINE']"/>
								<xsl:variable name="provider-max-seq" select="max($provider-baseline-ts/aixm:sequenceNumber)"/>
								<xsl:variable name="provider-max-corr" select="max($provider-baseline-ts[aixm:sequenceNumber = $provider-max-seq]/aixm:correctionNumber)"/>
								<xsl:variable name="provider-valid-ts" select="$provider-baseline-ts[aixm:sequenceNumber = $provider-max-seq and aixm:correctionNumber = $provider-max-corr][1]"/>
								<xsl:if test="$provider-valid-ts and $info-valid-ts">
									<Ser>
										<Uni>
											<txtName><xsl:value-of select="$provider-valid-ts/aixm:name"/></txtName>
										</Uni>
										<!-- Service type with underscore replaced by hyphen -->
										<codeType>
											<xsl:value-of select="translate($info-valid-ts/aixm:type, '_', '-')"/>
										</codeType>
										<!-- noSeq: 1 for PRIMARY, 2 for SECONDARY, empty for others -->
										<noSeq>
											<xsl:choose>
												<xsl:when test="$info-valid-ts/aixm:rank = 'PRIMARY'">1</xsl:when>
												<xsl:when test="$info-valid-ts/aixm:rank = 'SECONDARY'">2</xsl:when>
												<xsl:otherwise></xsl:otherwise>
											</xsl:choose>
										</noSeq>
										<!-- txtRmk with Unit timeslice, Service timeslice, and rank if not PRIMARY/SECONDARY -->
										<txtRmk>
											<xsl:text>Unit - Valid TimeSlice: BASELINE </xsl:text>
											<xsl:value-of select="concat($provider-max-seq, '.', $provider-max-corr)"/>
											<xsl:text>&#10;Service - Valid TimeSlice: BASELINE </xsl:text>
											<xsl:value-of select="concat($info-max-seq, '.', $info-max-corr)"/>
											<xsl:if test="$info-valid-ts/aixm:rank and $info-valid-ts/aixm:rank != 'PRIMARY' and $info-valid-ts/aixm:rank != 'SECONDARY'">
												<xsl:text>&#10;noSeq='</xsl:text>
												<xsl:value-of select="$info-valid-ts/aixm:rank"/>
												<xsl:text>'</xsl:text>
											</xsl:if>
										</txtRmk>
									</Ser>
								</xsl:if>
							</xsl:for-each>
							<xsl:if test="string-length($VOR_name) gt 0">
								<txtName><xsl:value-of select="$VOR_name"/></txtName>
							</xsl:if>
							<xsl:if test="string-length($VOR_type) gt 0">
								<codeType><xsl:value-of select="$VOR_type"/></codeType>
							</xsl:if>
							<xsl:if test="string-length($VOR_frequency) gt 0">
								<valFreq><xsl:value-of select="$VOR_frequency"/></valFreq>
							</xsl:if>
							<xsl:if test="string-length($VOR_frequency_uom) gt 0">
								<uomFreq><xsl:value-of select="$VOR_frequency_uom"/></uomFreq>
							</xsl:if>
							<xsl:if test="string-length($VOR_north_reference) gt 0">
								<codeTypeNorth><xsl:value-of select="$VOR_north_reference"/></codeTypeNorth>
							</xsl:if>
							<xsl:if test="string-length($VOR_station_declination) gt 0">
								<valDeclination><xsl:value-of select="$VOR_station_declination"/></valDeclination>
							</xsl:if>
							<xsl:if test="string-length($VOR_magnetic_variation) gt 0">
								<valMagVar><xsl:value-of select="$VOR_magnetic_variation"/></valMagVar>
							</xsl:if>
							<xsl:if test="string-length($VOR_magnetic_variation_date) gt 0">
								<dateMagVar><xsl:value-of select="$VOR_magnetic_variation_date"/></dateMagVar>
							</xsl:if>
							<xsl:if test="string-length($VOR_emission) gt 0">
								<codeEm><xsl:value-of select="$VOR_emission"/></codeEm>
							</xsl:if>
							<xsl:if test="string-length($VOR_datum) gt 0">
								<codeDatum><xsl:value-of select="$VOR_datum"/></codeDatum>
							</xsl:if>
							<xsl:if test="string-length($VOR_geographical_accuracy) gt 0">
								<valGeoAccuracy><xsl:value-of select="$VOR_geographical_accuracy"/></valGeoAccuracy>
							</xsl:if>
							<xsl:if test="string-length($VOR_geographical_accuracy_uom) gt 0">
								<uomGeoAccuracy><xsl:value-of select="$VOR_geographical_accuracy_uom"/></uomGeoAccuracy>
							</xsl:if>
							<xsl:if test="string-length($VOR_elevation) gt 0">
								<valElev><xsl:value-of select="$VOR_elevation"/></valElev>
							</xsl:if>
							<xsl:if test="string-length($VOR_elevation_accuracy) gt 0">
								<valElevAccuracy><xsl:value-of select="$VOR_elevation_accuracy"/></valElevAccuracy>
							</xsl:if>
							<xsl:if test="string-length($VOR_geoid_undulation) gt 0">
								<valGeoidUndulation><xsl:value-of select="$VOR_geoid_undulation"/></valGeoidUndulation>
							</xsl:if>
							<xsl:if test="string-length($VOR_vertical_distance_uom) gt 0">
								<uomDistVer><xsl:value-of select="$VOR_vertical_distance_uom"/></uomDistVer>
							</xsl:if>
							<xsl:if test="string-length($VOR_CRC) gt 0">
								<valCrc><xsl:value-of select="$VOR_CRC"/></valCrc>
							</xsl:if>
							<xsl:if test="string-length($VOR_vertical_datum) gt 0">
								<txtVerDatum><xsl:value-of select="$VOR_vertical_datum"/></txtVerDatum>
							</xsl:if>
							<xsl:if test="string-length($VOR_working_hours) gt 0">
								<codeWorkHr><xsl:value-of select="$VOR_working_hours"/></codeWorkHr>
							</xsl:if>
							<xsl:if test="string-length($VOR_working_hours_remarks) gt 0">
								<txtRmkWorkHr><xsl:value-of select="$VOR_working_hours_remarks"/></txtRmkWorkHr>
							</xsl:if>
							<!-- Add Timsh elements if VOR_working_hours is 'TIMSH' -->
							<xsl:if test="$VOR_working_hours = 'TIMSH'">
								<!-- Get timesheets from VOR, or from parent Navaid if VOR has none -->
								<xsl:variable name="timesheets_for_output" select="if (count(aixm:availability/aixm:NavaidOperationalStatus/aixm:timeInterval/aixm:Timesheet) gt 0) then aixm:availability/aixm:NavaidOperationalStatus/aixm:timeInterval/aixm:Timesheet else //aixm:Navaid[.//aixm:navaidEquipment/aixm:NavaidComponent/aixm:theNavaidEquipment/@xlink:href = concat('urn:uuid:', $VOR_UUID)]/aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)][aixm:correctionNumber = max(../aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE'][aixm:sequenceNumber = max(../aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE']/aixm:sequenceNumber)]/aixm:correctionNumber)][1]/aixm:availability/aixm:NavaidOperationalStatus/aixm:timeInterval/aixm:Timesheet"/>
								<xsl:for-each select="$timesheets_for_output">
									<!-- Skip timesheets with BUSY_FRI or OTHER CodeDayType -->
									<xsl:variable name="skip_day" select="fcn:should-skip-code-day(string(aixm:day))"/>
									<xsl:variable name="skip_day_til" select="aixm:dayTil and fcn:should-skip-code-day(string(aixm:dayTil))"/>
									<!-- Skip if startTimeRelativeEvent or endTimeRelativeEvent has non-MIN uom -->
									<xsl:variable name="skip_start_time_rel" select="aixm:startTimeRelativeEvent and aixm:startTimeRelativeEvent/@uom and aixm:startTimeRelativeEvent/@uom != 'MIN'"/>
									<xsl:variable name="skip_end_time_rel" select="aixm:endTimeRelativeEvent and aixm:endTimeRelativeEvent/@uom and aixm:endTimeRelativeEvent/@uom != 'MIN'"/>
									<!-- Skip if timeReference is not UTC -->
									<xsl:variable name="skip_time_ref" select="aixm:timeReference and not(aixm:timeReference/@xsi:nil='true') and aixm:timeReference != 'UTC'"/>
									<!-- Skip if excluded = YES -->
									<xsl:variable name="skip_excluded" select="aixm:excluded and not(aixm:excluded/@xsi:nil='true') and aixm:excluded = 'YES'"/>
									<xsl:if test="not($skip_day or $skip_day_til or $skip_start_time_rel or $skip_end_time_rel or $skip_time_ref or $skip_excluded)">
										<Timsh>
											<!-- codeTimeRef -->
											<xsl:if test="aixm:timeReference and not(aixm:timeReference/@xsi:nil='true')">
												<codeTimeRef>
													<xsl:choose>
														<xsl:when test="aixm:timeReference = 'UTC' and aixm:daylightSavingAdjust = 'YES'">UTCW</xsl:when>
														<xsl:when test="aixm:timeReference = 'UTC'">UTC</xsl:when>
														<xsl:otherwise><xsl:value-of select="aixm:timeReference"/></xsl:otherwise>
													</xsl:choose>
												</codeTimeRef>
											</xsl:if>
											<!-- dateValidWef -->
											<xsl:if test="aixm:startDate and not(aixm:startDate/@xsi:nil='true')">
												<dateValidWef><xsl:value-of select="aixm:startDate"/></dateValidWef>
											</xsl:if>
											<!-- dateValidTil -->
											<xsl:if test="aixm:endDate and not(aixm:endDate/@xsi:nil='true')">
												<dateValidTil><xsl:value-of select="aixm:endDate"/></dateValidTil>
											</xsl:if>
											<!-- codeDay -->
											<xsl:if test="aixm:day and not(aixm:day/@xsi:nil='true')">
												<codeDay><xsl:value-of select="fcn:translate-code-day(string(aixm:day))"/></codeDay>
											</xsl:if>
											<!-- codeDayTil -->
											<xsl:if test="aixm:dayTil and not(aixm:dayTil/@xsi:nil='true')">
												<codeDayTil><xsl:value-of select="fcn:translate-code-day(string(aixm:dayTil))"/></codeDayTil>
											</xsl:if>
											<!-- timeWef -->
											<xsl:if test="aixm:startTime and not(aixm:startTime/@xsi:nil='true')">
												<timeWef><xsl:value-of select="aixm:startTime"/></timeWef>
											</xsl:if>
											<!-- codeEventWef -->
											<xsl:if test="aixm:startEvent and not(aixm:startEvent/@xsi:nil='true')">
												<codeEventWef><xsl:value-of select="aixm:startEvent"/></codeEventWef>
											</xsl:if>
											<!-- timeRelEventWef -->
											<xsl:if test="aixm:startTimeRelativeEvent and not(aixm:startTimeRelativeEvent/@xsi:nil='true')">
												<timeRelEventWef><xsl:value-of select="aixm:startTimeRelativeEvent"/></timeRelEventWef>
											</xsl:if>
											<!-- codeCombWef -->
											<xsl:if test="aixm:startEventInterpretation and not(aixm:startEventInterpretation/@xsi:nil='true')">
												<codeCombWef><xsl:value-of select="fcn:translate-event-interpretation(string(aixm:startEventInterpretation))"/></codeCombWef>
											</xsl:if>
											<!-- timeTil -->
											<xsl:if test="aixm:endTime and not(aixm:endTime/@xsi:nil='true')">
												<timeTil><xsl:value-of select="aixm:endTime"/></timeTil>
											</xsl:if>
											<!-- codeEventTil -->
											<xsl:if test="aixm:endEvent and not(aixm:endEvent/@xsi:nil='true')">
												<codeEventTil><xsl:value-of select="aixm:endEvent"/></codeEventTil>
											</xsl:if>
											<!-- timeRelEventTil -->
											<xsl:if test="aixm:endTimeRelativeEvent and not(aixm:endTimeRelativeEvent/@xsi:nil='true')">
												<timeRelEventTil><xsl:value-of select="aixm:endTimeRelativeEvent"/></timeRelEventTil>
											</xsl:if>
											<!-- codeCombTil -->
											<xsl:if test="aixm:endEventInterpretation and not(aixm:endEventInterpretation/@xsi:nil='true')">
												<codeCombTil><xsl:value-of select="fcn:translate-event-interpretation(string(aixm:endEventInterpretation))"/></codeCombTil>
											</xsl:if>
										</Timsh>
									</xsl:if>
								</xsl:for-each>
							</xsl:if>
							<xsl:if test="string-length($VOR_effective_date) gt 0">
								<dtWef><xsl:value-of select="$VOR_effective_date"/></dtWef>
							</xsl:if>
							<xsl:if test="string-length($VOR_commit_date) gt 0">
								<dtCom><xsl:value-of select="$VOR_commit_date"/></dtCom>
							</xsl:if>
							<xsl:if test="string-length($VOR_UUID) gt 0">
								<mid><xsl:value-of select="$VOR_UUID"/></mid>
							</xsl:if>
							<xsl:if test="string-length($originator) gt 0">
								<OrgCre>
									<txtName><xsl:value-of select="$originator"/></txtName>
								</OrgCre>
							</xsl:if>
							<xsl:if test="string-length($VOR_remarks) gt 0">
								<txtRmk><xsl:value-of select="$VOR_remarks"/></txtRmk>
							</xsl:if>
						</Record>
		
					</xsl:for-each>
		
				</xsl:for-each>
				
			</SdoReportResult>
		</xsl:element>

	</xsl:template>

</xsl:transform>