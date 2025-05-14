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
	featureTypes: aixm:AirportHeliport
	permanentBaseline: true
	AIXMversion: 5.1.1
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
	exclude-result-prefixes="xsl uuid message gts gco xsd gml gss gsr gmd aixm event xlink xs xsi aixm_ds_xslt ead-audit">
	
	<xsl:output method="html" indent="yes"/>
	
	<xsl:strip-space elements="*"/>
	
	<xsl:template match="/">
		
		<html xmlns="http://www.w3.org/1999/xhtml">
			
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
				<meta http-equiv="Expires" content="120"/>
				<title>SDO Reporting - AD / HP usage - Complete - Version</title>
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
					<b>AD / HP usage - Complete - Version</b>
				</center>
				<hr/>
				
				<table border="0">
					<tbody>
						
						<tr style="white-space:nowrap">
							<td><strong>Aerodrome / Heliport - Identification</strong></td>
						</tr>
						<tr>
							<td><strong>Aerodrome / Heliport - ICAO Code</strong></td>
						</tr>
						<tr>
							<td><strong>Limitation Code</strong></td>
						</tr>
						<tr>
							<td><strong>Working hours</strong></td>
						</tr>
						<tr>
							<td><strong>Remark to working hours</strong></td>
						</tr>
						<tr>
							<td><strong>Time referencesystem</strong></td>
						</tr>
						<tr>
							<td><strong>Daylight savingadjust</strong></td>
						</tr>
						<tr>
							<td><strong>Yearly start date </strong></td>
						</tr>
						<tr>
							<td><strong>Yearly end date</strong></td>
						</tr>
						<tr>
							<td><strong>Affected day or startof affected period</strong></td>
						</tr>
						<tr>
							<td><strong>End of affected period</strong></td>
						</tr>
						<tr>
							<td><strong>Start - Time</strong></td>
						</tr>
						<tr>
							<td><strong>Start - Event</strong></td>
						</tr>
						<tr>
							<td><strong>Start - Relative to event</strong></td>
						</tr>
						<tr>
							<td><strong>Start - Interpretation</strong></td>
						</tr>
						<tr>
							<td><strong>End - Time</strong></td>
						</tr>
						<tr>
							<td><strong>End - Event</strong></td>
						</tr>
						<tr>
							<td><strong>End - Relative to event</strong></td>
						</tr>
						<tr>
							<td><strong>End - Interpretation</strong></td>
						</tr>
						<tr>
							<td><strong>Flight Class - Type</strong></td>
						</tr>
						<tr>
							<td><strong>Flight Class - Rule</strong></td>
						</tr>
						<tr>
							<td><strong>Flight Class - Status</strong></td>
						</tr>
						<tr>
							<td><strong>Flight Class - Military</strong></td>
						</tr>
						<tr>
							<td><strong>Flight Class - Origin</strong></td>
						</tr>
						<tr>
							<td><strong>Flight Class - Purpose</strong></td>
						</tr>
						<tr>
							<td><strong>Aircraft Class - Equipment and certification</strong></td>
						</tr>
						<tr>
							<td><strong>Aircraft Class - Type</strong></td>
						</tr>
						<tr>
							<td><strong>Aircraft Class - Engine Type</strong></td>
						</tr>
						<tr>
							<td><strong>Aircraft Class - Number of engines</strong></td>
						</tr>
						<tr>
							<td><strong>Aircraft Class - ICAO aircraft type designator</strong></td>
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
						
						<xsl:for-each select="//aixm:AirportHeliport/aixm:timeSlice/aixm:AirportHeliportTimeSlice[aixm:interpretation = 'BASELINE']">
							
							<xsl:sort select="aixm:designator" data-type="text" order="ascending"/>
							
							<!-- Aerodrome / Heliport - Identification and ICAO Code -->
							<xsl:variable name="AirportDesignator" select="aixm:designator"/>
							<xsl:variable name="AirportICAOcode" select="aixm:locationIndicatorICAO"/>
							
							<!-- Aerodrome / Heliport - UUID -->
							<xsl:variable name="AirportUUID" select="../../gml:identifier"/>
							
							<!-- Effective date -->
							<xsl:variable name="EffectiveDate_day" select="substring(gml:validTime/gml:TimePeriod/gml:beginPosition, 9, 2)"/>
							<xsl:variable name="EffectiveDate_month" select="substring(gml:validTime/gml:TimePeriod/gml:beginPosition, 6, 2)"/>
							<xsl:variable name="EffectiveDate_month" select="if($EffectiveDate_month = '01') then 'JAN' else if ($EffectiveDate_month = '02') then 'FEB' else if ($EffectiveDate_month = '03') then 'MAR' else 
								if ($EffectiveDate_month = '04') then 'APR' else if ($EffectiveDate_month = '05') then 'MAY' else if ($EffectiveDate_month = '06') then 'JUN' else if ($EffectiveDate_month = '07') then 'JUL' else 
								if ($EffectiveDate_month = '08') then 'AUG' else if ($EffectiveDate_month = '09') then 'SEP' else if ($EffectiveDate_month = '10') then 'OCT' else if ($EffectiveDate_month = '11') then 'NOV' else 'DEC'"/>
							<xsl:variable name="EffectiveDate_year" select="substring(gml:validTime/gml:TimePeriod/gml:beginPosition, 1, 4)"/>
							<xsl:variable name="EffectiveDate" select="concat($EffectiveDate_day, '-', $EffectiveDate_month, '-', $EffectiveDate_year)"/>
							
							<!-- Committed on -->
							<xsl:variable name="Commit_day" select="substring(aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate, 9, 2)"/>
							<xsl:variable name="Commit_month" select="substring(aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate, 6, 2)"/>
							<xsl:variable name="Commit_month" select="if($Commit_month = '01') then 'JAN' else if ($Commit_month = '02') then 'FEB' else if ($Commit_month = '03') then 'MAR' else 
								if ($Commit_month = '04') then 'APR' else if ($Commit_month = '05') then 'MAY' else if ($Commit_month = '06') then 'JUN' else if ($Commit_month = '07') then 'JUL' else 
								if ($Commit_month = '08') then 'AUG' else if ($Commit_month = '09') then 'SEP' else if ($Commit_month = '10') then 'OCT' else if ($Commit_month = '11') then 'NOV' else if ($Commit_month = '12') then 'DEC' else ''"/>
							<xsl:variable name="Commit_year" select="substring(aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate, 1, 4)"/>
							<xsl:variable name="Commit_date" select="concat($Commit_day, '-', $Commit_month, '-', $Commit_year)"/>
							
							<!-- Originator -->
							<xsl:variable name="Originator" select="aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
							
							<!-- Working hours: H24, HX, HO, NOTAM, if there is an aixm:availability property with aixm:operationalStatus='NORMAL' and no aixm:Timesheet -->
							<xsl:for-each select="aixm:availability/aixm:AirportHeliportAvailability[not(aixm:timeInterval/aixm:Timesheet) and aixm:operationalStatus = 'NORMAL']">
								<xsl:variable name="TimeRemarks">
									<xsl:choose>
										<xsl:when test="count(aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']) = 1">
											<xsl:for-each select="aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']">
												<xsl:for-each select="aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]">
													<xsl:value-of select="concat('(', ../../../aixm:purpose, ') ', .)"/>
												</xsl:for-each>
											</xsl:for-each>
										</xsl:when>
										<xsl:when test="count(aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']) gt 1">
											<xsl:for-each select="aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']">
												<xsl:choose>
													<xsl:when test="position() = 1">
														<xsl:value-of select="concat('(', aixm:purpose, ') ', aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')])"/>
													</xsl:when>
													<xsl:otherwise>
														<xsl:value-of select="concat('.&lt;br/&gt;(', aixm:purpose, ') ', aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')])"/>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:for-each>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								<xsl:variable name="WorkingHours">
									<xsl:choose>
										<xsl:when test="not(aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:translatedNote/aixm:LinguisticNote[contains(aixm:note, 'HX') or contains(aixm:note, 'HO') or contains(aixm:note, 'NOTAM') or contains(aixm:note, 'HOL') or contains(aixm:note, 'SS') or contains(aixm:note, 'SR') or contains(aixm:note, 'MON') or contains(aixm:note, 'TUE') or contains(aixm:note, 'WED') or contains(aixm:note, 'THU') or contains(aixm:note, 'FRI') or contains(aixm:note, 'SAT') or contains(aixm:note, 'SUN')]])">
											<xsl:value-of select="'H24'"/>
										</xsl:when>
										<xsl:when test="aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'HX')]">
											<xsl:value-of select="'HX'"/>
										</xsl:when>
										<xsl:when test="aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'HO') and not(contains(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], 'HOL'))]">
											<xsl:value-of select="'HO'"/>
										</xsl:when>
										<xsl:when test="aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'notam') and not(contains(lower-case(aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')]), 'outside'))]">
											<xsl:value-of select="'NOTAM'"/>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								<!-- Logical operators OR or NONE -->
								<xsl:for-each select="aixm:usage/aixm:AirportHeliportUsage[aixm:selection/aixm:ConditionCombination/aixm:logicalOperator=('OR', 'NONE')]">
									<!-- Limitation Code -->
									<xsl:variable name="LimitationCode" select="aixm:type"/>
									<!-- Generate a new table row for each AircraftCharacteristic -->
									<xsl:for-each select="aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic">
										<xsl:variable name="AircraftEquipment">
											<xsl:if test="aixm:navigationEquipment">
												<xsl:value-of select="aixm:navigationEquipment"/>
											</xsl:if>
											<xsl:if test="aixm:antiCollisionAndSeparationEquipment">
												<xsl:choose>
													<xsl:when test="not(aixm:navigationEquipment)">
														<xsl:value-of select="aixm:antiCollisionAndSeparationEquipment"/>
													</xsl:when>
													<xsl:otherwise>
														<xsl:value-of select="concat(', ', aixm:antiCollisionAndSeparationEquipment)"/>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:if>
											<xsl:if test="aixm:communicationEquipment">
												<xsl:choose>
													<xsl:when test="not(aixm:antiCollisionAndSeparationEquipment) and not(aixm:navigationEquipment)">
														<xsl:value-of select="aixm:communicationEquipment"/>
													</xsl:when>
													<xsl:otherwise>
														<xsl:value-of select="concat(', ', aixm:communicationEquipment)"/>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:if>
											<xsl:if test="aixm:surveillanceEquipment">
												<xsl:choose>
													<xsl:when test="not(aixm:antiCollisionAndSeparationEquipment) and not(aixm:navigationEquipment) and not(aixm:communicationEquipment)">
														<xsl:value-of select="aixm:surveillanceEquipment"/>
													</xsl:when>
													<xsl:otherwise>
														<xsl:value-of select="concat(', ', aixm:surveillanceEquipment)"/>
													</xsl:otherwise>
												</xsl:choose>
											</xsl:if>
										</xsl:variable>
										<tr style="white-space:nowrap;vertical-align:top;">
											<td><xsl:value-of select="if (string-length($AirportDesignator) != 0) then $AirportDesignator else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (string-length($AirportICAOcode) != 0) then $AirportICAOcode else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (string-length($LimitationCode) != 0) then $LimitationCode else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (string-length($WorkingHours) != 0) then $WorkingHours else '&#160;'"/></td>
										</tr>
										<tr>
											<td style="white-space:normal;min-width:500px"><xsl:value-of select="if (string-length($TimeRemarks) != 0) then $TimeRemarks else '&#160;'" disable-output-escaping="yes"/></td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (string-length($AircraftEquipment) != 0) then $AircraftEquipment else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (aixm:type) then aixm:type else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (aixm:engine) then aixm:engine else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (aixm:numberEngine) then aixm:numberEngine else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (aixm:typeAircraftICAO) then aixm:typeAircraftICAO else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (string-length($EffectiveDate) gt 4) then $EffectiveDate else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (string-length($Commit_date) gt 4) then $Commit_date else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (string-length($AirportUUID) != 0) then $AirportUUID else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (string-length($Originator) != 0) then $Originator else '&#160;'"/></td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
									</xsl:for-each>
									<!-- Generate a new table row for each FlightCharacteristic -->
									<xsl:for-each select="aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic">
										<tr style="white-space:nowrap;vertical-align:top;">
											<td><xsl:value-of select="if (string-length($AirportDesignator) != 0) then $AirportDesignator else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (string-length($AirportICAOcode) != 0) then $AirportICAOcode else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (string-length($LimitationCode) != 0) then $LimitationCode else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (string-length($WorkingHours) != 0) then $WorkingHours else '&#160;'"/></td>
										</tr>
										<tr>
											<td style="white-space:normal;min-width:500px"><xsl:value-of select="if (string-length($TimeRemarks) != 0) then $TimeRemarks else '&#160;'" disable-output-escaping="yes"/></td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (aixm:type) then aixm:type else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (aixm:rule) then aixm:rule else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (aixm:status) then aixm:status else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (aixm:military) then aixm:military else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (aixm:origin) then aixm:origin else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (aixm:purpose) then aixm:purpose else '&#160;'"/></td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (string-length($EffectiveDate) gt 4) then $EffectiveDate else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (string-length($Commit_date) gt 4) then $Commit_date else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (string-length($AirportUUID) != 0) then $AirportUUID else '&#160;'"/></td>
										</tr>
										<tr>
											<td><xsl:value-of select="if (string-length($Originator) != 0) then $Originator else '&#160;'"/></td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
										<tr>
											<td>&#160;</td>
										</tr>
									</xsl:for-each>
								</xsl:for-each>
								<!-- Locigal operator AND -->
								<xsl:for-each select="aixm:usage/aixm:AirportHeliportUsage[aixm:selection/aixm:ConditionCombination/aixm:logicalOperator='AND']">
									<!-- Limitation Code -->
									<xsl:variable name="LimitationCode" select="aixm:type"/>
									<tr style="white-space:nowrap;vertical-align:top;">
										<td><xsl:value-of select="if (string-length($AirportDesignator) != 0) then $AirportDesignator else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($AirportICAOcode) != 0) then $AirportICAOcode else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($LimitationCode) != 0) then $LimitationCode else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($WorkingHours) != 0) then $WorkingHours else '&#160;'"/></td>
									</tr>
									<tr>
										<td style="white-space:normal;min-width:500px"><xsl:value-of select="if (string-length($TimeRemarks) != 0) then $TimeRemarks else '&#160;'" disable-output-escaping="yes"/></td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:type) then aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:type else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:rule) then aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:rule else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:status) then aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:status else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:military) then aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:military else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:origin) then aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:origin else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:purpose) then aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:purpose else '&#160;'"/></td>
									</tr>
									<xsl:variable name="AircraftEquipment">
										<xsl:if test="aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:navigationEquipment">
											<xsl:value-of select="aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:navigationEquipment"/>
										</xsl:if>
										<xsl:if test="aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:antiCollisionAndSeparationEquipment">
											<xsl:choose>
												<xsl:when test="not(aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:navigationEquipment)">
													<xsl:value-of select="aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:antiCollisionAndSeparationEquipment"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="concat(', ', aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:antiCollisionAndSeparationEquipment)"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:if>
										<xsl:if test="aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:communicationEquipment">
											<xsl:choose>
												<xsl:when test="not(aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:antiCollisionAndSeparationEquipment) and not(aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:navigationEquipment)">
													<xsl:value-of select="aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:communicationEquipment"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="concat(', ', aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:communicationEquipment)"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:if>
										<xsl:if test="aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:surveillanceEquipment">
											<xsl:choose>
												<xsl:when test="not(aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:antiCollisionAndSeparationEquipment) and not(aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:navigationEquipment) and not(aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:communicationEquipment)">
													<xsl:value-of select="aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:surveillanceEquipment"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="concat(', ', aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:surveillanceEquipment)"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:if>
									</xsl:variable>
									<tr>
										<td><xsl:value-of select="if (string-length($AircraftEquipment) != 0) then $AircraftEquipment else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:type) then aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:type else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:engine) then aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:engine else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:numberEngine) then aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:numberEngine else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:typeAircraftICAO) then aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:typeAircraftICAO else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($EffectiveDate) gt 4) then $EffectiveDate else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($Commit_date) gt 4) then $Commit_date else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($AirportUUID) != 0) then $AirportUUID else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($Originator) != 0) then $Originator else '&#160;'"/></td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
								</xsl:for-each>
								<!-- No AircraftCharacteristic or FlightCharacteristic -->
								<xsl:if test="not(aixm:selection)">
									<tr style="white-space:nowrap;vertical-align:top;">
										<td><xsl:value-of select="if (string-length($AirportDesignator) != 0) then $AirportDesignator else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($AirportICAOcode) != 0) then $AirportICAOcode else '&#160;'"/></td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($WorkingHours) != 0) then $WorkingHours else '&#160;'"/></td>
									</tr>
									<tr>
										<td style="white-space:normal;min-width:500px"><xsl:value-of select="if (string-length($TimeRemarks) != 0) then $TimeRemarks else '&#160;'" disable-output-escaping="yes"/></td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($EffectiveDate) gt 4) then $EffectiveDate else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($Commit_date) gt 4) then $Commit_date else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($AirportUUID) != 0) then $AirportUUID else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($Originator) != 0) then $Originator else '&#160;'"/></td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
								</xsl:if>
							</xsl:for-each>
							
							<!-- Working hours: H24, HJ, HN, or other; if there is an aixm:availability property with aixm:operationalStatus='NORMAL' and at least one aixm:Timesheet -->
							<xsl:for-each select="aixm:availability/aixm:AirportHeliportAvailability[aixm:timeInterval/aixm:Timesheet and aixm:operationalStatus = 'NORMAL']">
								<xsl:variable name="WorkingHours">
									<xsl:choose>
										<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and (aixm:dayTil='ANY' or not(aixm:dayTil)) and aixm:startTime='00:00' and (aixm:endTime='00:00' or aixm:endTime='24:00') and not(aixm:startEvent) and not(aixm:endEvent) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO']">
											<xsl:value-of select="'H24'"/>
										</xsl:when>
										<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SR' and aixm:endEvent='SS' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO']">
											<xsl:value-of select="'HJ'"/>
										</xsl:when>
										<xsl:when test="aixm:timeInterval/aixm:Timesheet[aixm:timeReference='UTC' and aixm:day='ANY' and aixm:startEvent='SS' and aixm:endEvent='SR' and not(aixm:startTime) and not(aixm:endTime) and (aixm:daylightSavingAdjust='NO' or aixm:daylightSavingAdjust/@nilReason='inapplicable') and aixm:excluded='NO']">
											<xsl:value-of select="'HN'"/>
										</xsl:when>
									</xsl:choose>
								</xsl:variable>
								<xsl:for-each select="aixm:timeInterval/aixm:Timesheet">
									<xsl:variable name="TimeRemarks">
										<xsl:choose>
											<xsl:when test="count(../../aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']) = 1">
												<xsl:for-each select="../../aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']">
													<xsl:value-of select="concat('(', aixm:purpose, ') ', aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')])"/>
												</xsl:for-each>
											</xsl:when>
											<xsl:when test="count(../../aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']) gt 1">
												<xsl:for-each select="../../aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']">
													<xsl:choose>
														<xsl:when test="position() = 1">
															<xsl:value-of select="concat('(', aixm:purpose, ') ', aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')])"/>
														</xsl:when>
														<xsl:otherwise>
															<xsl:value-of select="concat('.&lt;br/&gt;(', aixm:purpose, ') ', aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')], ', ')"/>
														</xsl:otherwise>
													</xsl:choose>
												</xsl:for-each>
											</xsl:when>
										</xsl:choose>
									</xsl:variable>
									<xsl:variable name="TimeReference" select="aixm:timeReference"/>
									<xsl:variable name="DaylightSaving" select="aixm:daylightSavingAdjust"/>
									<xsl:variable name="YearlyStartDate" select="aixm:startDate"/>
									<xsl:variable name="YearlyEndDate" select="aixm:endDate"/>
									<xsl:variable name="DayStart" select="aixm:day"/>
									<xsl:variable name="DayEnd" select="aixm:dayTil"/>
									<xsl:variable name="StartTime" select="aixm:startTime"/>
									<xsl:variable name="EndTime" select="aixm:endTime"/>
									<xsl:variable name="StartEvent" select="aixm:startEvent"/>
									<xsl:variable name="EndEvent" select="aixm:endEvent"/>
									<xsl:variable name="RelativeToEventStart" select="if (number(aixm:startTimeRelativeEvent) gt 0) then if (contains(aixm:startTimeRelativeEvent, '+')) then aixm:startTimeRelativeEvent else concat('+', aixm:startTimeRelativeEvent) else aixm:startTimeRelativeEvent"/>
									<xsl:variable name="RelativeToEventStartUOM" select="aixm:startTimeRelativeEvent/@uom"/>
									<xsl:variable name="RelativeToEventEnd" select="if (number(aixm:endTimeRelativeEvent) gt 0) then if (contains(aixm:endTimeRelativeEvent, '+')) then aixm:endTimeRelativeEvent else concat('+', aixm:endTimeRelativeEvent) else aixm:endTimeRelativeEvent"/>
									<xsl:variable name="RelativeToEventEndUOM" select="aixm:endTimeRelativeEvent/@uom"/>
									<xsl:variable name="InterpretationStart" select="aixm:startEventInterpretation"/>
									<xsl:variable name="InterpretationEnd" select="aixm:endEventInterpretation"/>
									<xsl:for-each select="../../aixm:usage/aixm:AirportHeliportUsage">
										<!-- Limitation Code -->
										<xsl:variable name="LimitationCode" select="aixm:type"/>
										<!-- Logical operator OR or NONE -->
										<xsl:for-each select="aixm:selection/aixm:ConditionCombination[aixm:logicalOperator=('OR', 'NONE')]">
											<!-- Generate a new table row for each Timesheet and each AircraftCharacteristic -->
											<xsl:for-each select="aixm:aircraft/aixm:AircraftCharacteristic">
												<xsl:variable name="AircraftEquipment">
													<xsl:if test="aixm:navigationEquipment">
														<xsl:value-of select="aixm:navigationEquipment"/>
													</xsl:if>
													<xsl:if test="aixm:antiCollisionAndSeparationEquipment">
														<xsl:choose>
															<xsl:when test="not(aixm:navigationEquipment)">
																<xsl:value-of select="aixm:antiCollisionAndSeparationEquipment"/>
															</xsl:when>
															<xsl:otherwise>
																<xsl:value-of select="concat(', ', aixm:antiCollisionAndSeparationEquipment)"/>
															</xsl:otherwise>
														</xsl:choose>
													</xsl:if>
													<xsl:if test="aixm:communicationEquipment">
														<xsl:choose>
															<xsl:when test="not(aixm:antiCollisionAndSeparationEquipment) and not(aixm:navigationEquipment)">
																<xsl:value-of select="aixm:communicationEquipment"/>
															</xsl:when>
															<xsl:otherwise>
																<xsl:value-of select="concat(', ', aixm:communicationEquipment)"/>
															</xsl:otherwise>
														</xsl:choose>
													</xsl:if>
													<xsl:if test="aixm:surveillanceEquipment">
														<xsl:choose>
															<xsl:when test="not(aixm:antiCollisionAndSeparationEquipment) and not(aixm:navigationEquipment) and not(aixm:communicationEquipment)">
																<xsl:value-of select="aixm:surveillanceEquipment"/>
															</xsl:when>
															<xsl:otherwise>
																<xsl:value-of select="concat(', ', aixm:surveillanceEquipment)"/>
															</xsl:otherwise>
														</xsl:choose>
													</xsl:if>
												</xsl:variable>
												<tr style="white-space:nowrap;vertical-align:top;">
													<td><xsl:value-of select="if (string-length($AirportDesignator) != 0) then $AirportDesignator else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($AirportICAOcode) != 0) then $AirportICAOcode else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($LimitationCode) != 0) then $LimitationCode else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($WorkingHours) != 0) then $WorkingHours else '&#160;'"/></td>
												</tr>
												<tr>
													<td style="white-space:normal;min-width:500px"><xsl:value-of select="if (string-length($TimeRemarks) != 0) then $TimeRemarks else '&#160;'" disable-output-escaping="yes"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($TimeReference) != 0) then $TimeReference else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($DaylightSaving) != 0) then $DaylightSaving else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($YearlyStartDate) != 0) then $YearlyStartDate else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($YearlyEndDate) != 0) then $YearlyEndDate else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($DayStart) != 0) then $DayStart else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($DayEnd) != 0) then $DayEnd else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($StartTime) != 0) then $StartTime else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($StartEvent) != 0) then $StartEvent else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($RelativeToEventStart) != 0) then concat($RelativeToEventStart, ' ',$RelativeToEventStartUOM) else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($InterpretationStart) != 0) then $InterpretationStart else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($EndTime) != 0) then $EndTime else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($EndEvent) != 0) then $EndEvent else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($RelativeToEventEnd) != 0) then concat($RelativeToEventEnd, ' ',$RelativeToEventEndUOM) else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($InterpretationEnd) != 0) then $InterpretationEnd else '&#160;'"/></td>
												</tr>
												<tr>
													<td>&#160;</td>
												</tr>
												<tr>
													<td>&#160;</td>
												</tr>
												<tr>
													<td>&#160;</td>
												</tr>
												<tr>
													<td>&#160;</td>
												</tr>
												<tr>
													<td>&#160;</td>
												</tr>
												<tr>
													<td>&#160;</td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($AircraftEquipment) != 0) then $AircraftEquipment else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (aixm:type) then aixm:type else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (aixm:engine) then aixm:engine else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (aixm:numberEngine) then aixm:numberEngine else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (aixm:typeAircraftICAO) then aixm:typeAircraftICAO else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($EffectiveDate) gt 4) then $EffectiveDate else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($Commit_date) gt 4) then $Commit_date else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($AirportUUID) != 0) then $AirportUUID else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($Originator) != 0) then $Originator else '&#160;'"/></td>
												</tr>
												<tr>
													<td>&#160;</td>
												</tr>
												<tr>
													<td>&#160;</td>
												</tr>
											</xsl:for-each>
											<!-- Generate a new table row for each Timesheet and each FlightCharacteristic -->
											<xsl:for-each select="aixm:flight/aixm:FlightCharacteristic">
												<tr style="white-space:nowrap;vertical-align:top;">
													<td><xsl:value-of select="if (string-length($AirportDesignator) != 0) then $AirportDesignator else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($AirportICAOcode) != 0) then $AirportICAOcode else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($LimitationCode) != 0) then $LimitationCode else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($WorkingHours) != 0) then $WorkingHours else '&#160;'"/></td>
												</tr>
												<tr>
													<td style="white-space:normal;min-width:500px"><xsl:value-of select="if (string-length($TimeRemarks) != 0) then $TimeRemarks else '&#160;'" disable-output-escaping="yes"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($TimeReference) != 0) then $TimeReference else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($DaylightSaving) != 0) then $DaylightSaving else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($YearlyStartDate) != 0) then $YearlyStartDate else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($YearlyEndDate) != 0) then $YearlyEndDate else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($DayStart) != 0) then $DayStart else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($DayEnd) != 0) then $DayEnd else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($StartTime) != 0) then $StartTime else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($StartEvent) != 0) then $StartEvent else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($RelativeToEventStart) != 0) then concat($RelativeToEventStart, ' ',$RelativeToEventStartUOM) else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($InterpretationStart) != 0) then $InterpretationStart else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($EndTime) != 0) then $EndTime else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($EndEvent) != 0) then $EndEvent else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($RelativeToEventEnd) != 0) then concat($RelativeToEventEnd, ' ',$RelativeToEventEndUOM) else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($InterpretationEnd) != 0) then $InterpretationEnd else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (aixm:type) then aixm:type else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (aixm:rule) then aixm:rule else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (aixm:status) then aixm:status else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (aixm:military) then aixm:military else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (aixm:origin) then aixm:origin else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (aixm:purpose) then aixm:purpose else '&#160;'"/></td>
												</tr>
												<tr>
													<td>&#160;</td>
												</tr>
												<tr>
													<td>&#160;</td>
												</tr>
												<tr>
													<td>&#160;</td>
												</tr>
												<tr>
													<td>&#160;</td>
												</tr>
												<tr>
													<td>&#160;</td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($EffectiveDate) gt 4) then $EffectiveDate else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($Commit_date) gt 4) then $Commit_date else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($AirportUUID) != 0) then $AirportUUID else '&#160;'"/></td>
												</tr>
												<tr>
													<td><xsl:value-of select="if (string-length($Originator) != 0) then $Originator else '&#160;'"/></td>
												</tr>
												<tr>
													<td>&#160;</td>
												</tr>
												<tr>
													<td>&#160;</td>
												</tr>
											</xsl:for-each>
										</xsl:for-each>
										<!-- Logical operator AND -->
										<xsl:for-each select="aixm:selection/aixm:ConditionCombination[aixm:logicalOperator='AND']">
											<!-- Limitation Code -->
											<xsl:variable name="LimitationCode" select="../../aixm:type"/>
											<tr style="white-space:nowrap;vertical-align:top;">
												<td><xsl:value-of select="if (string-length($AirportDesignator) != 0) then $AirportDesignator else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($AirportICAOcode) != 0) then $AirportICAOcode else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($LimitationCode) != 0) then $LimitationCode else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($WorkingHours) != 0) then $WorkingHours else '&#160;'"/></td>
											</tr>
											<tr>
												<td style="white-space:normal;min-width:500px"><xsl:value-of select="if (string-length($TimeRemarks) != 0) then $TimeRemarks else '&#160;'" disable-output-escaping="yes"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($TimeReference) != 0) then $TimeReference else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($DaylightSaving) != 0) then $DaylightSaving else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($YearlyStartDate) != 0) then $YearlyStartDate else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($YearlyEndDate) != 0) then $YearlyEndDate else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($DayStart) != 0) then $DayStart else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($DayEnd) != 0) then $DayEnd else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($StartTime) != 0) then $StartTime else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($StartEvent) != 0) then $StartEvent else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($RelativeToEventStart) != 0) then concat($RelativeToEventStart, ' ',$RelativeToEventStartUOM) else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($InterpretationStart) != 0) then $InterpretationStart else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($EndTime) != 0) then $EndTime else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($EndEvent) != 0) then $EndEvent else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($RelativeToEventEnd) != 0) then concat($RelativeToEventEnd, ' ',$RelativeToEventEndUOM) else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($InterpretationEnd) != 0) then $InterpretationEnd else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (aixm:flight/aixm:FlightCharacteristic/aixm:type) then aixm:flight/aixm:FlightCharacteristic/aixm:type else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (aixm:flight/aixm:FlightCharacteristic/aixm:rule) then aixm:flight/aixm:FlightCharacteristic/aixm:rule else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (aixm:flight/aixm:FlightCharacteristic/aixm:status) then aixm:flight/aixm:FlightCharacteristic/aixm:status else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (aixm:flight/aixm:FlightCharacteristic/aixm:military) then aixm:flight/aixm:FlightCharacteristic/aixm:military else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (aixm:flight/aixm:FlightCharacteristic/aixm:origin) then aixm:flight/aixm:FlightCharacteristic/aixm:origin else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (aixm:flight/aixm:FlightCharacteristic/aixm:purpose) then aixm:flight/aixm:FlightCharacteristic/aixm:purpose else '&#160;'"/></td>
											</tr>
											<xsl:variable name="AircraftEquipment">
												<xsl:if test="aixm:aircraft/aixm:AircraftCharacteristic/aixm:navigationEquipment">
													<xsl:value-of select="aixm:aircraft/aixm:AircraftCharacteristic/aixm:navigationEquipment"/>
												</xsl:if>
												<xsl:if test="aixm:aircraft/aixm:AircraftCharacteristic/aixm:antiCollisionAndSeparationEquipment">
													<xsl:choose>
														<xsl:when test="not(aixm:aircraft/aixm:AircraftCharacteristic/aixm:navigationEquipment)">
															<xsl:value-of select="aixm:aircraft/aixm:AircraftCharacteristic/aixm:antiCollisionAndSeparationEquipment"/>
														</xsl:when>
														<xsl:otherwise>
															<xsl:value-of select="concat(', ', aixm:aircraft/aixm:AircraftCharacteristic/aixm:antiCollisionAndSeparationEquipment)"/>
														</xsl:otherwise>
													</xsl:choose>
												</xsl:if>
												<xsl:if test="aixm:aircraft/aixm:AircraftCharacteristic/aixm:communicationEquipment">
													<xsl:choose>
														<xsl:when test="not(aixm:aircraft/aixm:AircraftCharacteristic/aixm:antiCollisionAndSeparationEquipment) and not(aixm:aircraft/aixm:AircraftCharacteristic/aixm:navigationEquipment)">
															<xsl:value-of select="aixm:aircraft/aixm:AircraftCharacteristic/aixm:communicationEquipment"/>
														</xsl:when>
														<xsl:otherwise>
															<xsl:value-of select="concat(', ', aixm:aircraft/aixm:AircraftCharacteristic/aixm:communicationEquipment)"/>
														</xsl:otherwise>
													</xsl:choose>
												</xsl:if>
												<xsl:if test="aixm:aircraft/aixm:AircraftCharacteristic/aixm:surveillanceEquipment">
													<xsl:choose>
														<xsl:when test="not(aixm:aircraft/aixm:AircraftCharacteristic/aixm:antiCollisionAndSeparationEquipment) and not(aixm:aircraft/aixm:AircraftCharacteristic/aixm:navigationEquipment) and not(aixm:aircraft/aixm:AircraftCharacteristic/aixm:communicationEquipment)">
															<xsl:value-of select="aixm:aircraft/aixm:AircraftCharacteristic/aixm:surveillanceEquipment"/>
														</xsl:when>
														<xsl:otherwise>
															<xsl:value-of select="concat(', ', aixm:aircraft/aixm:AircraftCharacteristic/aixm:surveillanceEquipment)"/>
														</xsl:otherwise>
													</xsl:choose>
												</xsl:if>
											</xsl:variable>
											<tr>
												<td><xsl:value-of select="if (string-length($AircraftEquipment) != 0) then $AircraftEquipment else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (aixm:aircraft/aixm:AircraftCharacteristic/aixm:type) then aixm:aircraft/aixm:AircraftCharacteristic/aixm:type else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (aixm:aircraft/aixm:AircraftCharacteristic/aixm:engine) then aixm:aircraft/aixm:AircraftCharacteristic/aixm:engine else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (aixm:aircraft/aixm:AircraftCharacteristic/aixm:numberEngine) then aixm:aircraft/aixm:AircraftCharacteristic/aixm:numberEngine else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (aixm:aircraft/aixm:AircraftCharacteristic/aixm:typeAircraftICAO) then aixm:aircraft/aixm:AircraftCharacteristic/aixm:typeAircraftICAO else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($EffectiveDate) gt 4) then $EffectiveDate else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($Commit_date) gt 4) then $Commit_date else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($AirportUUID) != 0) then $AirportUUID else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($Originator) != 0) then $Originator else '&#160;'"/></td>
											</tr>
										</xsl:for-each>
										<!-- No AircraftCharacteristic or FlightCharacteristic -->
										<xsl:if test="not(aixm:selection)">
											<tr style="white-space:nowrap;vertical-align:top;">
												<td><xsl:value-of select="if (string-length($AirportDesignator) != 0) then $AirportDesignator else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($AirportICAOcode) != 0) then $AirportICAOcode else '&#160;'"/></td>
											</tr>
											<tr>
												<td>&#160;</td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($WorkingHours) != 0) then $WorkingHours else '&#160;'"/></td>
											</tr>
											<tr>
												<td style="white-space:normal;min-width:500px"><xsl:value-of select="if (string-length($TimeRemarks) != 0) then $TimeRemarks else '&#160;'" disable-output-escaping="yes"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($TimeReference) != 0) then $TimeReference else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($DaylightSaving) != 0) then $DaylightSaving else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($YearlyStartDate) != 0) then $YearlyStartDate else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($YearlyEndDate) != 0) then $YearlyEndDate else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($DayStart) != 0) then $DayStart else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($DayEnd) != 0) then $DayEnd else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($StartTime) != 0) then $StartTime else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($StartEvent) != 0) then $StartEvent else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($RelativeToEventStart) != 0) then concat($RelativeToEventStart, ' ',$RelativeToEventStartUOM) else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($InterpretationStart) != 0) then $InterpretationStart else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($EndTime) != 0) then $EndTime else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($EndEvent) != 0) then $EndEvent else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($RelativeToEventEnd) != 0) then concat($RelativeToEventEnd, ' ',$RelativeToEventEndUOM) else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($InterpretationEnd) != 0) then $InterpretationEnd else '&#160;'"/></td>
											</tr>
											<tr>
												<td>&#160;</td>
											</tr>
											<tr>
												<td>&#160;</td>
											</tr>
											<tr>
												<td>&#160;</td>
											</tr>
											<tr>
												<td>&#160;</td>
											</tr>
											<tr>
												<td>&#160;</td>
											</tr>
											<tr>
												<td>&#160;</td>
											</tr>
											<tr>
												<td>&#160;</td>
											</tr>
											<tr>
												<td>&#160;</td>
											</tr>
											<tr>
												<td>&#160;</td>
											</tr>
											<tr>
												<td>&#160;</td>
											</tr>
											<tr>
												<td>&#160;</td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($EffectiveDate) gt 4) then $EffectiveDate else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($Commit_date) gt 4) then $Commit_date else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($AirportUUID) != 0) then $AirportUUID else '&#160;'"/></td>
											</tr>
											<tr>
												<td><xsl:value-of select="if (string-length($Originator) != 0) then $Originator else '&#160;'"/></td>
											</tr>
											<tr>
												<td>&#160;</td>
											</tr>
											<tr>
												<td>&#160;</td>
											</tr>
										</xsl:if>
									</xsl:for-each>
								</xsl:for-each>
							</xsl:for-each>
							
							<!-- AD / HP closed -->
							<xsl:if test="aixm:availability/aixm:AirportHeliportAvailability[not(aixm:timeInterval/aixm:Timesheet) and aixm:operationalStatus = 'CLOSED'] and not(aixm:availability/aixm:AirportHeliportAvailability[aixm:operationalStatus = ('NORMAL','LIMITED')])">
								<xsl:for-each select="aixm:availability/aixm:AirportHeliportAvailability[not(aixm:timeInterval/aixm:Timesheet) and aixm:operationalStatus = 'CLOSED']">
									<xsl:variable name="TimeRemarks">
										<xsl:choose>
											<xsl:when test="count(aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']) = 1">
												<xsl:for-each select="aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']">
													<xsl:value-of select="concat('(', aixm:purpose, ') ', aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')])"/>
												</xsl:for-each>
											</xsl:when>
											<xsl:when test="count(aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']) gt 1">
												<xsl:for-each select="aixm:annotation/aixm:Note[aixm:propertyName='timeInterval']">
													<xsl:choose>
														<xsl:when test="position() = 1">
															<xsl:value-of select="concat('(', aixm:purpose, ') ', aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')])"/>
														</xsl:when>
														<xsl:otherwise>
															<xsl:value-of select="concat('.&lt;br/&gt;(', aixm:purpose, ') ', aixm:translatedNote/aixm:LinguisticNote/aixm:note[not(@lang) or @lang=('en','eng')])"/>
														</xsl:otherwise>
													</xsl:choose>
												</xsl:for-each>
											</xsl:when>
										</xsl:choose>
									</xsl:variable>
									<tr style="white-space:nowrap;vertical-align:top;">
										<td><xsl:value-of select="if (string-length($AirportDesignator) != 0) then $AirportDesignator else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($AirportICAOcode) != 0) then $AirportICAOcode else '&#160;'"/></td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td><xsl:value-of select="'CLSD'"/></td>
									</tr>
									<tr>
										<td style="white-space:normal;min-width:500px"><xsl:value-of select="if (string-length($TimeRemarks) != 0) then $TimeRemarks else '&#160;'" disable-output-escaping="yes"/></td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($EffectiveDate) gt 4) then $EffectiveDate else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($Commit_date) gt 4) then $Commit_date else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($AirportUUID) != 0) then $AirportUUID else '&#160;'"/></td>
									</tr>
									<tr>
										<td><xsl:value-of select="if (string-length($Originator) != 0) then $Originator else '&#160;'"/></td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
									<tr>
										<td>&#160;</td>
									</tr>
								</xsl:for-each>
							</xsl:if>
							
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
						<td><font size="-1">Sorting by: </font></td>
						<td><font size="-1">Aerodrome / Heliport - Identification</font></td>
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