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

<!-- for successful transformation, the XML file must contain the following features: aixm:Airspace -->

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
	exclude-result-prefixes="xsl uuid message gts gco xsd gml gss gsr gmd aixm event xlink xs xsi aixm_ds_xslt ead-audit">
	
	<xsl:output method="html" indent="yes"/>
	
	<xsl:strip-space elements="*"/>
	
	<xsl:template match="/">
		
		<html xmlns="http://www.w3.org/1999/xhtml">
			
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
				<meta http-equiv="Expires" content="120"/>
				<title>SDO Reporting - Airspaces of all types with lower and upper limits</title>
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
					<b>Airspaces of all types with lower and upper limits</b>
				</center>
				<hr/>
				
				<table width="100%" border="0">
					<tbody>
						
						<tr>
							<td>
								<strong>Type</strong>
							</td>
						</tr>
						<tr>
							<td>
								<strong>Coded identifier</strong>
							</td>
						</tr>
						<tr>
							<td>
								<strong>Name</strong>
							</td>
						</tr>
						<tr>
							<td>
								<strong>Location indicator [ICAO doc. 7910]</strong>
							</td>
						</tr>
						<tr>
							<td>
								<strong>Reference for upper limit</strong>
							</td>
						</tr>
						<tr>
							<td>
								<strong>Upper limit</strong>
							</td>
						</tr>
						<tr>
							<td>
								<strong>Unit of measurement [upper limit]</strong>
							</td>
						</tr>
						<tr>
							<td>
								<strong>Reference for lower limit</strong>
							</td>
						</tr>
						<tr>
							<td>
								<strong>Lower limit</strong>
							</td>
						</tr>
						<tr>
							<td>
								<strong>Unit of measurement [lower limit]</strong>
							</td>
						</tr>
						<tr>
							<td>
								<strong>Originator</strong>
							</td>
						</tr>
						<tr>
							<td>&#160;</td>
						</tr>
						<tr>
							<td>&#160;</td>
						</tr>
						
						<xsl:for-each select="//aixm:AirspaceTimeSlice">
							
							<xsl:sort select=".//aixm:designator" data-type="text" order="ascending"/>
							
							<!-- Type -->
							<tr>
								<td><xsl:value-of select="if (aixm:type) then aixm:type else '&#160;'"/></td>
							</tr>
							
							<!-- Coded identifier -->
							<tr>
								<td><xsl:value-of select="if (aixm:designator) then aixm:designator else '&#160;'"/></td>
							</tr>
							
							<!-- Name -->
							<tr>
								<td><xsl:value-of select="if (aixm:name) then aixm:name else '&#160;'"/></td>
							</tr>
							
							<!-- Location indicator [ICAO doc. 7910] -->
							<tr>
								<td><xsl:value-of select="if (aixm:designatorICAO = 'YES') then aixm:designator else '&#160;'"/></td>
							</tr>
							
							<xsl:variable name="AirspaceVolume" select="aixm:geometryComponent/aixm:AirspaceGeometryComponent/aixm:theAirspaceVolume/aixm:AirspaceVolume"/>
							
							<!-- Reference for upper limit -->
							<tr>
								<td><xsl:value-of select="if ($AirspaceVolume/aixm:upperLimitReference) then $AirspaceVolume/aixm:upperLimitReference else '&#160;'"/></td>
							</tr>
							
							<!-- Upper limit -->
							<tr>
								<td><xsl:value-of select="if ($AirspaceVolume/aixm:upperLimit) then $AirspaceVolume/aixm:upperLimit else '&#160;'"/></td>
							</tr>
							
							<!-- Unit of measurement [upper limit] -->
							<tr>
								<td><xsl:value-of select="if ($AirspaceVolume/aixm:upperLimit/@uom) then $AirspaceVolume/aixm:upperLimit/@uom else '&#160;'"/></td>
							</tr>
							
							<!-- Reference for lower limit -->
							<tr>
								<td><xsl:value-of select="if ($AirspaceVolume/aixm:lowerLimitReference) then $AirspaceVolume/aixm:lowerLimitReference else '&#160;'"/></td>
							</tr>
							
							<!-- Lower limit -->
							<tr>
								<td><xsl:value-of select="if ($AirspaceVolume/aixm:lowerLimit) then $AirspaceVolume/aixm:lowerLimit else '&#160;'"/></td>
							</tr>
							
							<!-- Unit of measurement [lower limit] -->
							<tr>
								<td><xsl:value-of select="if ($AirspaceVolume/aixm:lowerLimit/@uom) then $AirspaceVolume/aixm:lowerLimit/@uom else '&#160;'"/></td>
							</tr>
							
							<!-- Originator -->
							<tr>
								<td><xsl:value-of select="aixm:extension/ead-audit:AirspaceExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/></td>
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
				
			</body>
			
		</html>
		
	</xsl:template>
	
</xsl:transform>