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
	featureTypes:	aixm:Navaid aixm:Airspace
	includeReferencedFeaturesLevel:	"1"
	permanentBaseline:	true
	dataScope:	ReleasedData
	AIXMversion:	5.1.1
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
	
	<xsl:function name="fcn:get-lat-DMS" as="xs:string">
		<xsl:param name="input" as="xs:double"/>
		<xsl:variable name="lat_decimal_degrees" select="$input"/>
		<xsl:variable name="lat_whole" select="string(floor(abs($lat_decimal_degrees)))"/>
		<xsl:variable name="lat_frac" select="string(abs($lat_decimal_degrees) - floor(abs($lat_decimal_degrees)))"/>
		<xsl:variable name="lat_deg" select="if (string-length($lat_whole) = 1) then concat('0', $lat_whole) else $lat_whole"/>
		<xsl:variable name="lat_min_whole" select="floor(number($lat_frac) * 60)"/>
		<xsl:variable name="lat_min_frac" select="number($lat_frac) * 60 - $lat_min_whole"/>
		<xsl:variable name="lat_min" select="if (string-length(string($lat_min_whole)) = 1) then concat('0', string($lat_min_whole)) else string($lat_min_whole)"/>
		<xsl:variable name="lat_sec" select="format-number($lat_min_frac * 60, '0.00')"/>
		<xsl:variable name="lat_sec" select="if (string-length(string(floor(number($lat_sec)))) = 1) then concat('0', string($lat_sec)) else string($lat_sec)"/>
		<xsl:value-of select="concat($lat_deg, $lat_min, $lat_sec, if ($lat_decimal_degrees ge 0) then 'N' else 'S')"/>
	</xsl:function>
	
	<xsl:function name="fcn:get-long-DMS" as="xs:string">
		<xsl:param name="input" as="xs:double"/>
		<xsl:variable name="long_decimal_degrees" select="$input"/>
		<xsl:variable name="long_whole" select="string(floor(abs($long_decimal_degrees)))"/>
		<xsl:variable name="long_frac" select="string(abs($long_decimal_degrees) - floor(abs($long_decimal_degrees)))"/>
		<xsl:variable name="long_deg" select="if (string-length($long_whole) != 3) then (if (string-length($long_whole) = 1) then concat('00', $long_whole) else concat('0', $long_whole)) else $long_whole"/>
		<xsl:variable name="long_min_whole" select="floor(number($long_frac) * 60)"/>
		<xsl:variable name="long_min_frac" select="number($long_frac) * 60 - $long_min_whole"/>
		<xsl:variable name="long_min" select="if (string-length(string($long_min_whole)) = 1) then concat('0', string($long_min_whole)) else string($long_min_whole)"/>
		<xsl:variable name="long_sec" select="format-number($long_min_frac * 60, '0.00')"/>
		<xsl:variable name="long_sec" select="if (string-length(string(floor(number($long_sec)))) = 1) then concat('0', string($long_sec)) else string($long_sec)"/>
		<xsl:value-of select="concat($long_deg, $long_min, $long_sec, if ($long_decimal_degrees ge 0) then 'E' else 'W')"/>
	</xsl:function>
	
	<xsl:template match="/">
		
		<html xmlns="http://www.w3.org/1999/xhtml">
			
			<head>
				<meta http-equiv="Expires" content="120" />
				<title>SDO Reporting - Navaid with FIR</title>
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
					<b>Navaid with FIR</b>
				</center>
				<hr/>
				
				<table border="0">
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
							<td><strong>Responsible organisaton or authority - Name</strong></td>
						</tr>
						<tr>
							<td><strong>Name</strong></td>
						</tr>
						<tr>
							<td><strong>Type</strong></td>
						</tr>
						<tr>
							<td><strong>Navaid Type</strong></td>
						</tr>
						<tr>
							<td><strong>Frequency</strong></td>
						</tr>
						<tr>
							<td><strong>Unit of measurement [frequency]</strong></td>
						</tr>
						<tr>
							<td><strong>North reference</strong></td>
						</tr>
						<tr>
							<td><strong>Station declination</strong></td>
						</tr>
						<tr>
							<td><strong>Magnetic variation</strong></td>
						</tr>
						<tr>
							<td><strong>Magnetic variation date</strong></td>
						</tr>
						<tr>
							<td><strong>Emission</strong></td>
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
							<td><strong>Elevation</strong></td>
						</tr>
						<tr>
							<td><strong>Elevation accuracy</strong></td>
						</tr>
						<tr>
							<td><strong>Geoid undulation</strong></td>
						</tr>
						<tr>
							<td><strong>Unit of measurement [vertical distance]</strong></td>
						</tr>
						<tr>
							<td><strong>Cyclic redundancy check</strong></td>
						</tr>
						<tr>
							<td><strong>Vertical Datum</strong></td>
						</tr>
						<tr>
							<td><strong>Working hours</strong></td>
						</tr>
						<tr>
							<td><strong>Remark to working hours</strong></td>
						</tr>
						<tr>
							<td><strong>Remarks</strong></td>
						</tr>
						<tr>
							<td><strong>Collocated DME - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>Collocated DME - Latitude</strong></td>
						</tr>
						<tr>
							<td><strong>Collocated DME - Longitude</strong></td>
						</tr>
						<tr>
							<td><strong>Collocated TACAN - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>Collocated TACAN - Latitude</strong></td>
						</tr>
						<tr>
							<td><strong>Collocated TACAN - Longitude</strong></td>
						</tr>
						<tr>
							<td><strong>Channel</strong></td>
						</tr>
						<tr>
							<td><strong>Frequency of virtual VHF facility</strong></td>
						</tr>
						<tr>
							<td><strong>Unit of measurement [frequency of virtual VHF facility]</strong></td>
						</tr>
						<tr>
							<td><strong>Value of displacement</strong></td>
						</tr>
						<tr>
							<td><strong>Unit of measurement [displacement]</strong></td>
						</tr>
						<tr>
							<td><strong>Classification</strong></td>
						</tr>
						<tr>
							<td><strong>Position</strong></td>
						</tr>
						<tr>
							<td><strong>FIR - Coded identifier</strong></td>
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
							<td><strong>Originator</strong></td>
						</tr>
						<tr>
							<td>&#160;</td>
						</tr>
						<tr>
							<td>&#160;</td>
						</tr>
						
						<xsl:for-each select="//aixm:Navaid/aixm:timeSlice/aixm:NavaidTimeSlice[aixm:interpretation = 'BASELINE' and aixm:type = ('VOR','DME','NDB','TACAN','VORTAC','VOR_DME','NDB_DME','NDB_MKR','DF','SDF')]">
							
							<xsl:sort select="aixm:type" order="ascending"/>
							<xsl:sort select="aixm:designator" order="ascending"/>
							
							
							<!-- get all navaid equipment for each navaid -->
							
							<xsl:variable name="VOR_equipment_uuid">
								<xsl:if test="aixm:type = ('VOR','VOR_DME','VORTAC')">
									<xsl:for-each select="aixm:navaidEquipment/aixm:NavaidComponent">
										<xsl:variable name="navaid_equipment_uuid" select="substring-after(aixm:theNavaidEquipment/@xlink:href, 'urn:uuid:')"/>
										<xsl:if test="//aixm:VOR[gml:identifier = $navaid_equipment_uuid and aixm:timeSlice/aixm:VORTimeSlice/aixm:interpretation = 'BASELINE']">
											<xsl:value-of select="//aixm:VOR[gml:identifier = $navaid_equipment_uuid and aixm:timeSlice/aixm:VORTimeSlice/aixm:interpretation = 'BASELINE']/gml:identifier"/>
										</xsl:if>
									</xsl:for-each>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="VOR_equipment" select="if (aixm:type = ('VOR','VOR_DME','VORTAC')) then //aixm:VOR[gml:identifier = $VOR_equipment_uuid]/aixm:timeSlice/aixm:VORTimeSlice[aixm:interpretation = 'BASELINE'] else ''"/>
							
							<xsl:variable name="DME_equipment_uuid">
								<xsl:if test="aixm:type = ('DME','VOR_DME','NDB_DME')">
									<xsl:for-each select="aixm:navaidEquipment/aixm:NavaidComponent">
										<xsl:variable name="navaid_equipment_uuid" select="substring-after(aixm:theNavaidEquipment/@xlink:href, 'urn:uuid:')"/>
										<xsl:if test="//aixm:DME[gml:identifier = $navaid_equipment_uuid and aixm:timeSlice/aixm:DMETimeSlice/aixm:interpretation = 'BASELINE']">
											<xsl:value-of select="//aixm:DME[gml:identifier = $navaid_equipment_uuid and aixm:timeSlice/aixm:DMETimeSlice/aixm:interpretation = 'BASELINE']/gml:identifier"/>
										</xsl:if>
									</xsl:for-each>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="DME_equipment" select="if (aixm:type = ('DME','VOR_DME','NDB_DME')) then //aixm:DME[gml:identifier = $DME_equipment_uuid]/aixm:timeSlice/aixm:DMETimeSlice[aixm:interpretation = 'BASELINE'] else ''"/>
							
							<xsl:variable name="TACAN_equipment_uuid">
								<xsl:if test="aixm:type = ('TACAN','VORTAC')">
									<xsl:for-each select="aixm:navaidEquipment/aixm:NavaidComponent">
										<xsl:variable name="navaid_equipment_uuid" select="substring-after(aixm:theNavaidEquipment/@xlink:href, 'urn:uuid:')"/>
										<xsl:if test="//aixm:TACAN[gml:identifier = $navaid_equipment_uuid and aixm:timeSlice/aixm:TACANTimeSlice/aixm:interpretation = 'BASELINE']">
											<xsl:value-of select="//aixm:TACAN[gml:identifier = $navaid_equipment_uuid and aixm:timeSlice/aixm:TACANTimeSlice/aixm:interpretation = 'BASELINE']/gml:identifier"/>
										</xsl:if>
									</xsl:for-each>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="TACAN_equipment" select="if (aixm:type = ('TACAN','VORTAC')) then //aixm:TACAN[gml:identifier = $TACAN_equipment_uuid]/aixm:timeSlice/aixm:TACANTimeSlice[aixm:interpretation = 'BASELINE'] else ''"/>
							
							<xsl:variable name="NDB_equipment_uuid">
								<xsl:if test="aixm:type = ('NDB','NDB_DME','NDB_MKR')">
									<xsl:for-each select="aixm:navaidEquipment/aixm:NavaidComponent">
										<xsl:variable name="navaid_equipment_uuid" select="substring-after(aixm:theNavaidEquipment/@xlink:href, 'urn:uuid:')"/>
										<xsl:if test="//aixm:NDB[gml:identifier = $navaid_equipment_uuid and aixm:timeSlice/aixm:NDBTimeSlice/aixm:interpretation = 'BASELINE']">
											<xsl:value-of select="//aixm:NDB[gml:identifier = $navaid_equipment_uuid and aixm:timeSlice/aixm:NDBTimeSlice/aixm:interpretation = 'BASELINE']/gml:identifier"/>
										</xsl:if>
									</xsl:for-each>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="NDB_equipment" select="if (aixm:type = ('NDB','NDB_DME','NDB_MKR')) then //aixm:NDB[gml:identifier = $NDB_equipment_uuid]/aixm:timeSlice/aixm:NDBTimeSlice[aixm:interpretation = 'BASELINE'] else ''"/>
							
							<xsl:variable name="DF_equipment_uuid">
								<xsl:if test="aixm:type = 'DF'">
									<xsl:for-each select="aixm:navaidEquipment/aixm:NavaidComponent">
										<xsl:variable name="navaid_equipment_uuid" select="substring-after(aixm:theNavaidEquipment/@xlink:href, 'urn:uuid:')"/>
										<xsl:if test="//aixm:DirectionFinder[gml:identifier = $navaid_equipment_uuid and aixm:timeSlice/aixm:DirectionFinderTimeSlice/aixm:interpretation = 'BASELINE']">
											<xsl:value-of select="//aixm:DirectionFinder[gml:identifier = $navaid_equipment_uuid and aixm:timeSlice/aixm:DirectionFinderTimeSlice/aixm:interpretation = 'BASELINE']/gml:identifier"/>
										</xsl:if>
									</xsl:for-each>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="DF_equipment" select="if (aixm:type = 'DF') then //aixm:DirectionFinder[gml:identifier = $DF_equipment_uuid]/aixm:timeSlice/aixm:DirectionFinderTimeSlice[aixm:interpretation = 'BASELINE'] else ''"/>
							
							<xsl:variable name="SDF_equipment_uuid">
								<xsl:if test="aixm:type = 'SDF'">
									<xsl:for-each select="aixm:navaidEquipment/aixm:NavaidComponent">
										<xsl:variable name="navaid_equipment_uuid" select="substring-after(aixm:theNavaidEquipment/@xlink:href, 'urn:uuid:')"/>
										<xsl:if test="//aixm:SDF[gml:identifier = $navaid_equipment_uuid and aixm:timeSlice/aixm:SDFTimeSlice/aixm:interpretation = 'BASELINE']">
											<xsl:value-of select="//aixm:SDF[gml:identifier = $navaid_equipment_uuid and aixm:timeSlice/aixm:SDFTimeSlice/aixm:interpretation = 'BASELINE']/gml:identifier"/>
										</xsl:if>
									</xsl:for-each>
								</xsl:if>
							</xsl:variable>
							<xsl:variable name="SDF_equipment" select="if (aixm:type = 'SDF') then //aixm:SDF[gml:identifier = $SDF_equipment_uuid]/aixm:timeSlice/aixm:SDFTimeSlice[aixm:interpretation = 'BASELINE'] else ''"/>
							
							<!-- Identification -->
							<xsl:variable name="Navaid_designator">
								<xsl:value-of select="aixm:designator"/>
							</xsl:variable>
							
							<!-- Latitude --> <!-- taken from the Navaid feature -->
							<xsl:variable name="Navaid_latitude">
								<xsl:if test="aixm:location/aixm:ElevatedPoint/gml:pos">
									<xsl:value-of select="fcn:get-lat-DMS(number(substring-before(aixm:location/*/gml:pos, ' ')))"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Longitude --> <!-- taken from the Navaid feature -->
							<xsl:variable name="Navaid_longitude">
								<xsl:if test="aixm:location/aixm:ElevatedPoint/gml:pos">
									<xsl:value-of select="fcn:get-long-DMS(number(substring-after(aixm:location/*/gml:pos, ' ')))"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Responsible organisaton or authority - Name --> <!-- taken from the NavaidEquipment feature -->
							<xsl:variable name="Navaid_resp_org">
								<xsl:variable name="Navaid_equipment" select="substring-after(aixm:navaidEquipment[1]/aixm:NavaidComponent/aixm:theNavaidEquipment/@xlink:href, 'urn:uuid:')"/>
								<xsl:variable name="Resp_org_uuid" select="substring-after(//message:hasMember/*[gml:identifier = $Navaid_equipment]/aixm:timeSlice/*[aixm:interpretation = 'BASELINE']/aixm:authority/aixm:AuthorityForNavaidEquipment/aixm:theOrganisationAuthority/@xlink:href, 'urn:uuid:')"/>
								<xsl:value-of select="//aixm:OrganisationAuthority[gml:identifier = $Resp_org_uuid]/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice[aixm:interpretation = 'BASELINE']/aixm:name"/>
							</xsl:variable>
							
							<!-- Name --> <!-- taken from the Navaid feature -->
							<xsl:variable name="Navaid_name">
								<xsl:value-of select="aixm:name"/>
							</xsl:variable>
							
							<!-- Type --> <!-- for VOR equipment only -->
							<xsl:variable name="Navaid_VOR_type">
								<xsl:if test="aixm:type = ('VOR','VOR_DME','VORTAC')">
									<xsl:value-of select="$VOR_equipment/aixm:type"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Navaid Type --> <!-- taken from the Navaid feature -->
							<xsl:variable name="Navaid_navaid_type">
								<xsl:value-of select="aixm:type"/>
							</xsl:variable>
							
							<!-- Frequency --> <!-- for VOR, NDB, DF and SDF equipment types -->
							<xsl:variable name="Navaid_frequency">
								<xsl:choose>
									<xsl:when test="aixm:type = ('VOR','VOR_DME','VORTAC')">
										<xsl:value-of select="$VOR_equipment/aixm:frequency"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('NDB','NDB_DME','NDB_MKR')">
										<xsl:value-of select="$NDB_equipment/aixm:frequency"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('DF')">
										<xsl:value-of select="$DF_equipment/aixm:frequency"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('SDF')">
										<xsl:value-of select="$SDF_equipment/aixm:frequency"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- Unit of measurement [frequency] --> <!-- for VOR, NDB, DF and SDF equipment types -->
							<xsl:variable name="Navaid_freq_uom">
								<xsl:choose>
									<xsl:when test="aixm:type = ('VOR','VOR_DME','VORTAC')">
										<xsl:value-of select="$VOR_equipment/aixm:frequency/@uom"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('NDB','NDB_DME','NDB_MKR')">
										<xsl:value-of select="$NDB_equipment/aixm:frequency/@uom"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('DF')">
										<xsl:value-of select="$DF_equipment/aixm:frequency/@uom"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('SDF')">
										<xsl:value-of select="$SDF_equipment/aixm:frequency/@uom"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- North reference --> <!-- for VOR equipment only -->
							<xsl:variable name="Navaid_north_ref">
								<xsl:if test="aixm:type = ('VOR','VOR_DME','VORTAC')">
									<xsl:value-of select="$VOR_equipment/aixm:zeroBearingDirection"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Station declination --> <!-- for VOR equipment only -->
							<xsl:variable name="Navaid_station_declination">
								<xsl:if test="aixm:type = ('VOR','VOR_DME','VORTAC')">
									<xsl:value-of select="$VOR_equipment/aixm:declination"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Magnetic variation --> <!-- for all equipment types -->
							<xsl:variable name="Navaid_mag_var">
								<xsl:choose>
									<xsl:when test="aixm:type = ('VOR','VOR_DME','VORTAC')">
										<xsl:value-of select="$VOR_equipment/aixm:magneticVariation"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('NDB','NDB_DME','NDB_MKR')">
										<xsl:value-of select="$NDB_equipment/aixm:magneticVariation"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('TACAN')">
										<xsl:value-of select="$TACAN_equipment/aixm:magneticVariation"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('DME')">
										<xsl:value-of select="$DME_equipment/aixm:magneticVariation"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('DF')">
										<xsl:value-of select="$DF_equipment/aixm:magneticVariation"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('SDF')">
										<xsl:value-of select="$SDF_equipment/aixm:magneticVariation"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- Magnetic variation date --> <!-- for all equipment types -->
							<xsl:variable name="Navaid_mag_var_date">
								<xsl:choose>
									<xsl:when test="aixm:type = ('VOR','VOR_DME','VORTAC')">
										<xsl:value-of select="$VOR_equipment/aixm:dateMagneticVariation"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('NDB','NDB_DME','NDB_MKR')">
										<xsl:value-of select="$NDB_equipment/aixm:dateMagneticVariation"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('TACAN')">
										<xsl:value-of select="$TACAN_equipment/aixm:dateMagneticVariation"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('DME')">
										<xsl:value-of select="$DME_equipment/aixm:dateMagneticVariation"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('DF')">
										<xsl:value-of select="$DF_equipment/aixm:dateMagneticVariation"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('SDF')">
										<xsl:value-of select="$SDF_equipment/aixm:dateMagneticVariation"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- Emission --> <!-- for all equipment types -->
							<xsl:variable name="Navaid_emission">
								<xsl:choose>
									<xsl:when test="aixm:type = ('VOR','VOR_DME','VORTAC')">
										<xsl:value-of select="$VOR_equipment/aixm:emissionClass"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('NDB','NDB_DME','NDB_MKR')">
										<xsl:value-of select="$NDB_equipment/aixm:emissionClass"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('TACAN')">
										<xsl:value-of select="$TACAN_equipment/aixm:emissionClass"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('DME')">
										<xsl:value-of select="$DME_equipment/aixm:emissionClass"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('DF')">
										<xsl:value-of select="$DF_equipment/aixm:emissionClass"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('SDF')">
										<xsl:value-of select="$SDF_equipment/aixm:emissionClass"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- Datum --> <!-- taken from the Navaid feature -->
							<xsl:variable name="Navaid_datum">
								<xsl:value-of select="concat(substring(aixm:location/*/@srsName, 17,5), substring(aixm:location/*/@srsName, 23,4))"/>
							</xsl:variable>
							
							<!-- Geographical accuracy --> <!-- taken from the Navaid feature -->
							<xsl:variable name="Navaid_geo_accuracy">
								<xsl:value-of select="aixm:location/*/aixm:horizontalAccuracy"/>
							</xsl:variable>
							
							<!-- Unit of measurement [geographical accuracy] --> <!-- taken from the Navaid feature -->
							<xsl:variable name="Navaid_geo_accuracy_uom">
								<xsl:value-of select="aixm:location/*/aixm:horizontalAccuracy/@uom"/>
							</xsl:variable>
							
							<!-- Elevation --> <!-- taken from the Navaid feature -->
							<xsl:variable name="Navaid_elevation">
								<xsl:value-of select="aixm:location/aixm:ElevatedPoint/aixm:elevation"/>
							</xsl:variable>
							
							<!-- Elevation accuracy --> <!-- taken from the Navaid feature -->
							<xsl:variable name="Navaid_elevation_accuracy">
								<xsl:value-of select="aixm:location/aixm:ElevatedPoint/aixm:verticalAccuracy"/>
							</xsl:variable>
							
							<!-- Geoid undulation --> <!-- taken from the Navaid feature -->
							<xsl:variable name="Navaid_geoid_undulation">
								<xsl:value-of select="aixm:location/aixm:ElevatedPoint/aixm:geoidUndulation"/>
							</xsl:variable>
							
							<!-- Unit of measurement [vertical distance] --> <!-- taken from the Navaid feature -->
							<xsl:variable name="Navaid_vertical_dist_uom">
								<xsl:value-of select="aixm:location/aixm:ElevatedPoint/aixm:elevation/@uom"/>
							</xsl:variable>
							
							<!-- Cyclic redundancy check --> <!-- taken from the Navaid feature -->
							<xsl:variable name="Navaid_CRC">
								<xsl:variable name="CRC_note" select=".//aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote/aixm:note[(not(@lang) or @lang=('en','eng')) and contains(., 'CRC:')]"/>
								<xsl:if test="string-length($CRC_note) gt 0">
									<xsl:value-of select="fcn:get-last-word($CRC_note)"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Vertical Datum --> <!-- taken from the Navaid feature -->
							<xsl:variable name="Navaid_vertical_datum">
								<xsl:value-of select="aixm:location/aixm:ElevatedPoint/aixm:verticalDatum"/>
							</xsl:variable>
							
							<!-- Working hours -->
							<xsl:variable name="Navaid_working_hours">
								<!-- work in progress -->
							</xsl:variable>
							
							<!-- Remark to working hours -->
							<xsl:variable name="Navaid_working_hours_remarks">
								<!-- work in progress -->
							</xsl:variable>
							
							<!-- Remarks -->
							<xsl:variable name="Navaid_remarks">
								<xsl:variable name="dataset_creation_date" select="//aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
								<xsl:if test="string-length($dataset_creation_date) gt 0">
									<xsl:value-of select="concat('Current time: ', $dataset_creation_date)"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Collocated DME - Identification -->
							<xsl:variable name="Navaid_DME_designator">
								<xsl:if test="aixm:type = ('VOR_DME','NDB_DME')">
									<xsl:value-of select="$DME_equipment/aixm:designator"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Collocated DME - Latitude -->
							<xsl:variable name="Navaid_DME_lat">
								<xsl:if test="aixm:type = ('VOR_DME','NDB_DME')">
									<xsl:value-of select="fcn:get-lat-DMS(number(substring-before($DME_equipment/aixm:location/*/gml:pos, ' ')))"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Collocated DME - Longitude -->
							<xsl:variable name="Navaid_DME_long">
								<xsl:if test="aixm:type = ('VOR_DME','NDB_DME')">
									<xsl:value-of select="fcn:get-long-DMS(number(substring-after($DME_equipment/aixm:location/*/gml:pos, ' ')))"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Collocated TACAN - Identification -->
							<xsl:variable name="Navaid_TACAN_designator">
								<xsl:if test="aixm:type = 'VORTAC'">
									<xsl:value-of select="$TACAN_equipment/aixm:designator"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Collocated TACAN - Latitude -->
							<xsl:variable name="Navaid_TACAN_lat">
								<xsl:if test="aixm:type = 'VORTAC'">
									<xsl:value-of select="fcn:get-lat-DMS(number(substring-before($TACAN_equipment/aixm:location/*/gml:pos, ' ')))"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Collocated TACAN - Longitude -->
							<xsl:variable name="Navaid_TACAN_long">
								<xsl:if test="aixm:type = 'VORTAC'">
									<xsl:value-of select="fcn:get-long-DMS(number(substring-after($TACAN_equipment/aixm:location/*/gml:pos, ' ')))"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Channel --> <!-- taken from DME or TACAN NavaidEquipment -->
							<xsl:variable name="Navaid_channel">
								<xsl:choose>
									<xsl:when test="aixm:type = ('DME','VOR_DME','NDB_DME')">
										<xsl:value-of select="$DME_equipment/aixm:channel"/>
									</xsl:when>
									<xsl:when test="aixm:type = ('TACAN','VORTAC')">
										<xsl:value-of select="$TACAN_equipment/aixm:channel"/>
									</xsl:when>
								</xsl:choose>
							</xsl:variable>
							
							<!-- Frequency of virtual VHF facility --> <!-- taken from DME NavaidEquipment -->
							<xsl:variable name="Navaid_VHF_facility_freq">
								<xsl:if test="aixm:type = ('DME','VOR_DME','NDB_DME')">
									<xsl:value-of select="$DME_equipment/aixm:ghostFrequency"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Unit of measurement [frequency of virtual VHF facility] --> <!-- taken from DME NavaidEquipment -->
							<xsl:variable name="Navaid_VHF_facility_freq_uom">
								<xsl:if test="aixm:type = ('DME','VOR_DME','NDB_DME')">
									<xsl:value-of select="$DME_equipment/aixm:ghostFrequency/@uom"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Value of displacement --> <!-- taken from DME NavaidEquipment -->
							<xsl:variable name="Navaid_displacement">
								<xsl:if test="aixm:type = ('DME','VOR_DME','NDB_DME')">
									<xsl:value-of select="$DME_equipment/aixm:displace"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Unit of measurement [displacement] --> <!-- taken from DME NavaidEquipment -->
							<xsl:variable name="Navaid_displacement_uom">
								<xsl:if test="aixm:type = ('DME','VOR_DME','NDB_DME')">
									<xsl:value-of select="$DME_equipment/aixm:displace/@uom"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Classification --> <!-- taken from NDB NavaidEquipment -->
							<xsl:variable name="Navaid_classification">
								<xsl:if test="aixm:type = ('NDB','NDB_DME')">
									<xsl:choose>
										<xsl:when test="$NDB_equipment/aixm:class = 'ENR'">
											<xsl:value-of select="'En-route'"/>
										</xsl:when>
										<xsl:when test="$NDB_equipment/aixm:class = 'L'">
											<xsl:value-of select="'Locator'"/>
										</xsl:when>
										<xsl:when test="$NDB_equipment/aixm:class = 'MAR'">
											<xsl:value-of select="'Marine beacon'"/>
										</xsl:when>
										<xsl:when test="contains($NDB_equipment/aixm:class, 'OTHER')">
											<xsl:value-of select="$NDB_equipment/aixm:class"/>
										</xsl:when>
									</xsl:choose>
								</xsl:if>
							</xsl:variable>
							
							<!-- Position --> <!-- taken from NDB NavaidEquipment -->
							<xsl:variable name="Navaid_position">
								<xsl:if test="aixm:type = ('NDB','NDB_DME')">
									<xsl:value-of select="aixm:navaidEquipment/aixm:NavaidComponent[substring-after(aixm:theNavaidEquipment/@xlink:href, 'urn:uuid:') = $NDB_equipment_uuid]/aixm:markerPosition"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- FIR Coded identifier -->
							<xsl:variable name="Navaid_FIR">
								<xsl:if test="count(//aixm:AirspaceTimeSlice[aixm:type = 'FIR']) = 1">
									<xsl:value-of select="//aixm:AirspaceTimeSlice[aixm:type = 'FIR']/aixm:designator"/>
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
								<xsl:if test="aixm:extension/ead-audit:NavaidExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate">
									<xsl:value-of select="fcn:get-date(aixm:extension/ead-audit:NavaidExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate)"/>
								</xsl:if>
							</xsl:variable>
							
							<!-- Internal UID (master) -->
							<xsl:variable name="Navaid_UUID" select="../../gml:identifier"/>
							
							<!-- Originator -->
							<xsl:variable name="originator">
								<xsl:value-of select="aixm:extension/ead-audit:NavaidExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
							</xsl:variable>
							
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_designator) gt 0) then $Navaid_designator else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_latitude) gt 0) then $Navaid_latitude else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_longitude) gt 0) then $Navaid_longitude else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_resp_org) gt 0) then $Navaid_resp_org else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_name) gt 0) then $Navaid_name else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_VOR_type) gt 0) then $Navaid_VOR_type else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_navaid_type) gt 0) then $Navaid_navaid_type else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_frequency) gt 0) then $Navaid_frequency else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_freq_uom) gt 0) then $Navaid_freq_uom else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_north_ref) gt 0) then $Navaid_north_ref else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_station_declination) gt 0) then $Navaid_station_declination else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_mag_var) gt 0) then $Navaid_mag_var else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_mag_var_date) gt 0) then $Navaid_mag_var_date else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_emission) gt 0) then $Navaid_emission else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_datum) gt 0) then $Navaid_datum else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_geo_accuracy) gt 0) then $Navaid_geo_accuracy else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_geo_accuracy_uom) gt 0) then $Navaid_geo_accuracy_uom else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_elevation) gt 0) then $Navaid_elevation else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_elevation_accuracy) gt 0) then $Navaid_elevation_accuracy else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_geoid_undulation) gt 0) then $Navaid_geoid_undulation else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_vertical_dist_uom) gt 0) then $Navaid_vertical_dist_uom else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_CRC) gt 0) then $Navaid_CRC else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_vertical_datum) gt 0) then $Navaid_vertical_datum else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_working_hours) gt 0) then $Navaid_working_hours else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_working_hours_remarks) gt 0) then $Navaid_working_hours_remarks else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_remarks) gt 0) then $Navaid_remarks else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_DME_designator) gt 0) then $Navaid_DME_designator else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_DME_lat) gt 0) then $Navaid_DME_lat else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_DME_long) gt 0) then $Navaid_DME_long else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_TACAN_designator) gt 0) then $Navaid_TACAN_designator else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_TACAN_lat) gt 0) then $Navaid_TACAN_lat else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_TACAN_long) gt 0) then $Navaid_TACAN_long else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_channel) gt 0) then $Navaid_channel else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_VHF_facility_freq) gt 0) then $Navaid_VHF_facility_freq else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_VHF_facility_freq_uom) gt 0) then $Navaid_VHF_facility_freq_uom else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_displacement) gt 0) then $Navaid_displacement else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_displacement_uom) gt 0) then $Navaid_displacement_uom else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_classification) gt 0) then $Navaid_classification else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_position) gt 0) then $Navaid_position else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_FIR) gt 0) then $Navaid_FIR else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($effective_date) gt 0) then $effective_date else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($commit_date) gt 0) then $commit_date else '&#160;'"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="if (string-length($Navaid_UUID) gt 0) then $Navaid_UUID else '&#160;'"/></td>
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
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'dataType: '), ',')"/>
				</xsl:variable>
				
				<!-- CustomizationAirspaceCircleArcToPolygon -->
				<xsl:variable name="arc_to_polygon">
					<xsl:value-of select="substring-before(substring-after($rule_parameters, 'CustomizationAirspaceCircleArcToPolygon: '), ',')"/>
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
						<td><font size="-1">Sorting by:</font></td>
						<td><font size="-1">Navaid Type (first) / Identification (second)</font></td>
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