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

<!-- for successful transformation, the XML file must contain the following features: aixm:RouteSegment, aixm:Route, aixm:DesignatedPoint, aixm:Navaid -->

<xsl:stylesheet version="3.0" 
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
	exclude-result-prefixes="xsl uuid message gts gco xsd gml gss gsr gmd aixm event xlink xs xsi aixm_ds_xslt ead-audit">
	
	<xsl:output method="html" indent="yes"/>
	
	<xsl:strip-space elements="*"/>
	
	<!-- Keys -->
	<xsl:key name="route-by-uuid" match="aixm:Route" use="gml:identifier"/>
	<xsl:key name="point-by-uuid" match="aixm:DesignatedPoint | aixm:Navaid" use="gml:identifier"/>
	
	<xsl:template match="/">
		
		<html xmlns="http://www.w3.org/1999/xhtml">
			
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
				<meta http-equiv="Expires" content="120"/>
				<title>SDO Reporting - Non-upper Routes</title>
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
				
				<center><b>Non-upper Routes</b></center>
				<hr/>
				
				<table xmlns="" border="0" style="border-spacing: 8px 4px">
					<tbody>
						
						<tr style="white-space:nowrap">
							<td><strong>Master gUID</strong></td>
							<td><strong>Route Designator</strong></td>
							<td><strong>Area Desig.</strong></td>
							<td><strong>Start identifier</strong></td>
							<td><strong>Type</strong></td>
							<td><strong>End Identifier</strong></td>
							<td><strong>Type</strong></td>
							<td><strong>Upper limit</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[upper limit]</strong></td>
							<td><strong>Reference for<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>upper limit</strong></td>
							<td><strong>Lower limit</strong></td>
							<td><strong>Unit of measurement<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>[lower limit]</strong></td>
							<td><strong>Reference for<xsl:text disable-output-escaping="yes">&lt;br/&gt;</xsl:text>lower limit</strong></td>
							<td><strong>Effective date</strong></td>
							<td><strong>Originator</strong></td>
						</tr>
						
						<!-- Group segments by route (which have level = 'LOWER') -->
						<xsl:for-each-group select="//aixm:RouteSegment[aixm:timeSlice/aixm:RouteSegmentTimeSlice/aixm:level = 'LOWER']" group-by="substring-after(aixm:timeSlice/aixm:RouteSegmentTimeSlice/aixm:routeFormed/@xlink:href, 'urn:uuid:')">
							
							<xsl:variable name="Route_uuid" select="current-grouping-key()"/>
							<xsl:variable name="Route" select="key('route-by-uuid', $Route_uuid)"/>
							<xsl:variable name="RouteTimeSlice" select="$Route/aixm:timeSlice/aixm:RouteTimeSlice"/>
							<xsl:variable name="Master_gUID" select="$Route/gml:identifier"/>
							<xsl:variable name="RouteDesignator" select="concat($RouteTimeSlice/aixm:designatorPrefix, $RouteTimeSlice/aixm:designatorSecondLetter, $RouteTimeSlice/aixm:designatorNumber)"/>
							<xsl:variable name="RouteAreaDesignator" select="$RouteTimeSlice/aixm:locationDesignator"/>
							<xsl:variable name="EffectiveDate">
								<xsl:variable name="day" select="substring($RouteTimeSlice/gml:validTime/gml:TimePeriod/gml:beginPosition, 9, 2)"/>
								<xsl:variable name="month" select="substring($RouteTimeSlice/gml:validTime/gml:TimePeriod/gml:beginPosition, 6, 2)"/>
								<xsl:variable name="month" select="if($month = '01') then 'JAN' else if ($month = '02') then 'FEB' else if ($month = '03') then 'MAR' else 
									if ($month = '04') then 'APR' else if ($month = '05') then 'MAY' else if ($month = '06') then 'JUN' else if ($month = '07') then 'JUL' else 
									if ($month = '08') then 'AUG' else if ($month = '09') then 'SEP' else if ($month = '10') then 'OCT' else if ($month = '11') then 'NOV' else if ($month = '12') then 'DEC' else ''"/>
								<xsl:variable name="year" select="substring($RouteTimeSlice/gml:validTime/gml:TimePeriod/gml:beginPosition, 1, 4)"/>
								<xsl:value-of select="concat($day, '-', $month, '-', $year)"/>
							</xsl:variable>
							<xsl:variable name="Originator" select="$RouteTimeSlice/aixm:extension/ead-audit:RouteExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
							
							<!-- Extract all segments in this route -->
							<xsl:variable name="segments" select="current-group()"/>							
							
							<!-- Find the first segment (its start point is not an end point elsewhere on this route) -->
							<xsl:variable name="start-segment" as="element()*">
								<xsl:iterate select="$segments">
									<xsl:variable name="seg" select="."/>
									<xsl:variable name="RouteSegmentTimeSlice" select="aixm:timeSlice/aixm:RouteSegmentTimeSlice"/>
									<xsl:variable name="start" select="substring-after($RouteSegmentTimeSlice/aixm:start//*/@xlink:href, 'urn:uuid:')"/>
									<xsl:variable name="end" select="$segments/aixm:timeSlice/aixm:RouteSegmentTimeSlice/aixm:end//*/@xlink:href"/>
									<xsl:if test="not($end[contains(., $start)])">
										<xsl:sequence select="."/>
										<xsl:break/>
									</xsl:if>
								</xsl:iterate>
							</xsl:variable>
							
							<!-- Recursively walk the chain -->
							<xsl:call-template name="output-chain">
								<xsl:with-param name="segment" select="$start-segment"/>
								<xsl:with-param name="segments" select="$segments"/>
								<xsl:with-param name="Master_gUID" select="$Master_gUID"/>
								<xsl:with-param name="RouteDesignator" select="$RouteDesignator"/>
								<xsl:with-param name="RouteAreaDesignator" select="$RouteAreaDesignator"/>
								<xsl:with-param name="EffectiveDate" select="$EffectiveDate"/>
								<xsl:with-param name="Originator" select="$Originator"/>
							</xsl:call-template>
							
						</xsl:for-each-group>
						
					</tbody>
				</table>
				
			</body>
			
		</html>
		
	</xsl:template>
	
	<!-- Recursive template to walk the chain -->
	<xsl:template name="output-chain">
		<xsl:param name="segment"/>
		<xsl:param name="segments"/>
		<xsl:param name="Master_gUID"/>
		<xsl:param name="RouteDesignator"/>
		<xsl:param name="RouteAreaDesignator"/>
		<xsl:param name="EffectiveDate"/>
		<xsl:param name="Originator"/>
		
		<xsl:variable name="RouteSegmentTimeSlice" select="$segment/aixm:timeSlice/aixm:RouteSegmentTimeSlice"/>
		<xsl:variable name="start_uuid" select="substring-after($RouteSegmentTimeSlice/aixm:start//*/@xlink:href, 'urn:uuid:')"/>
		<xsl:variable name="end_uuid" select="substring-after($RouteSegmentTimeSlice/aixm:end//*/@xlink:href, 'urn:uuid:')"/>
		<xsl:variable name="UpperLimit" select="$RouteSegmentTimeSlice/aixm:upperLimit"/>
		<xsl:variable name="UpperLimit_uom" select="$RouteSegmentTimeSlice/aixm:upperLimit/@uom"/>
		<xsl:variable name="UpperLimit_reference" select="$RouteSegmentTimeSlice/aixm:upperLimitReference"/>
		<xsl:variable name="LowerLimit" select="$RouteSegmentTimeSlice/aixm:lowerLimit"/>
		<xsl:variable name="LowerLimit_uom" select="$RouteSegmentTimeSlice/aixm:lowerLimit/@uom"/>
		<xsl:variable name="LowerLimit_reference" select="$RouteSegmentTimeSlice/aixm:lowerLimitReference"/>
		
		<xsl:variable name="start_designator" select="key('point-by-uuid', $start_uuid)/aixm:timeSlice/*/aixm:designator"/>
		<xsl:variable name="start_type">
			<xsl:choose>
				<xsl:when test="key('point-by-uuid', $start_uuid)/aixm:timeSlice/aixm:DesignatedPointTimeSlice/aixm:type">
					<xsl:value-of select="concat('WPT', ' (', key('point-by-uuid', $start_uuid)/aixm:timeSlice/aixm:DesignatedPointTimeSlice/aixm:type, ')')"/>
				</xsl:when>
				<xsl:when test="key('point-by-uuid', $start_uuid)/aixm:timeSlice/aixm:NavaidTimeSlice/aixm:type">
					<xsl:value-of select="key('point-by-uuid', $start_uuid)/aixm:timeSlice/aixm:NavaidTimeSlice/aixm:type"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="end_designator" select="key('point-by-uuid', $end_uuid)/aixm:timeSlice/*/aixm:designator"/>
		<xsl:variable name="end_type">
			<xsl:choose>
				<xsl:when test="key('point-by-uuid', $end_uuid)/aixm:timeSlice/aixm:DesignatedPointTimeSlice/aixm:type">
					<xsl:value-of select="concat('WPT', ' (', key('point-by-uuid', $end_uuid)/aixm:timeSlice/aixm:DesignatedPointTimeSlice/aixm:type, ')')"/>
				</xsl:when>
				<xsl:when test="key('point-by-uuid', $end_uuid)/aixm:timeSlice/aixm:NavaidTimeSlice/aixm:type">
					<xsl:value-of select="key('point-by-uuid', $end_uuid)/aixm:timeSlice/aixm:NavaidTimeSlice/aixm:type"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		
		<tr style="white-space:nowrap">
			<td><xsl:value-of select="if (string-length($Master_gUID) = 0) then '&#160;' else $Master_gUID"/></td>
			<td><xsl:value-of select="if (string-length($RouteDesignator) = 0) then '&#160;' else $RouteDesignator"/></td>
			<td><xsl:value-of select="if (string-length($RouteAreaDesignator) = 0) then '&#160;' else $RouteAreaDesignator"/></td>
			<td><xsl:value-of select="if (string-length($start_designator) = 0) then '&#160;' else $start_designator"/></td>
			<td><xsl:value-of select="if (string-length($start_type) = 0) then '&#160;' else $start_type"/></td>
			<td><xsl:value-of select="if (string-length($end_designator) = 0) then '&#160;' else $end_designator"/></td>
			<td><xsl:value-of select="if (string-length($end_type) = 0) then '&#160;' else $end_type"/></td>
			<td><xsl:value-of select="if (string-length($UpperLimit) = 0) then '&#160;' else $UpperLimit"/></td>
			<td><xsl:value-of select="if (string-length($UpperLimit_uom) = 0) then '&#160;' else $UpperLimit_uom"/></td>
			<td><xsl:value-of select="if (string-length($UpperLimit_reference) = 0) then '&#160;' else $UpperLimit_reference"/></td>
			<td><xsl:value-of select="if (string-length($LowerLimit) = 0) then '&#160;' else $LowerLimit"/></td>
			<td><xsl:value-of select="if (string-length($LowerLimit_uom) = 0) then '&#160;' else $LowerLimit_uom"/></td>
			<td><xsl:value-of select="if (string-length($LowerLimit_reference) = 0) then '&#160;' else $LowerLimit_reference"/></td>
			<td><xsl:value-of select="if (string-length($EffectiveDate) = 2) then '&#160;' else $EffectiveDate"/></td>
			<td><xsl:value-of select="if (string-length($Originator) = 0) then '&#160;' else $Originator"/></td>
		</tr>
		
		<!-- Find next segment whose start = this end -->
		<xsl:variable name="next" select="$segments[aixm:timeSlice/aixm:RouteSegmentTimeSlice/aixm:start//*/@xlink:href = concat('urn:uuid:', $end_uuid)][1]"/>
		
		<xsl:if test="$next">
			<xsl:call-template name="output-chain">
				<xsl:with-param name="segment" select="$next"/>
				<xsl:with-param name="segments" select="$segments"/>
				<xsl:with-param name="RouteDesignator" select="$RouteDesignator"/>
				<xsl:with-param name="Master_gUID" select="$Master_gUID"/>
				<xsl:with-param name="RouteAreaDesignator" select="$RouteAreaDesignator"/>
				<xsl:with-param name="EffectiveDate" select="$EffectiveDate"/>
				<xsl:with-param name="Originator" select="$Originator"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	
</xsl:stylesheet>