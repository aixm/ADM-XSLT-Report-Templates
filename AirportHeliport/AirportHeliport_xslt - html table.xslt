<?xml version="1.0" encoding="UTF-8"?>
<!-- ==================================================================== -->
<!-- XSLT script for iNM eEAD -->
<!-- source: https://github.com/aixm/ADM-XSLT-Report-Templates -->
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
				<title>SDO Reporting - AD / HP including FIR - Complete - Version</title>
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
					<b>AD / HP including FIR - Complete - Version</b>
				</center>
				<hr/>
				
				<table width="250%" border="1" style="border:1px solid black;border-collapse:collapse;">
					<tbody>
						
						<tr>
							<td colspan="2">
								<strong>Aerodrome / Heliport</strong>
							</td>
							<td rowspan="2">
								<strong>Limitation Code</strong>
							</td>
							<td rowspan="2">
								<strong>Working hours</strong>
							</td>
							<td rowspan="2">
								<strong>Remark to working hours</strong>
							</td>
							<td rowspan="2">
								<strong>Time reference system</strong>
							</td>
							<td rowspan="2">
								<strong>Yearly start date</strong>
							</td>
							<td rowspan="2">
								<strong>Yearly end date</strong>
							</td>
							<td rowspan="2">
								<strong>Affected day or start of affected period</strong>
							</td>
							<td rowspan="2">
								<strong>End of affected period</strong>
							</td>
							<td colspan="4">
								<strong>Start</strong>
							</td>
							<td colspan="4">
								<strong>End</strong>
							</td>
							<td colspan="6">
								<strong>Flight Class</strong>
							</td>
							<td colspan="5">
								<strong>Aircraft Class</strong>
							</td>
							<td rowspan="2">
								<strong>Effective date</strong>
							</td>
							<td rowspan="2">
								<strong>Committed on</strong>
							</td>
							<td rowspan="2">
								<strong>Internal UID (master)</strong>
							</td>
							<td rowspan="2">
								<strong>Originator</strong>
							</td>
						</tr>
						<tr>
							<td><strong>Identification</strong></td>
							<td><strong>ICAO Code</strong></td>
							<td><strong>Time</strong></td>
							<td><strong>Event</strong></td>
							<td><strong>Relative to event</strong></td>
							<td><strong>Interpretation</strong></td>
							<td><strong>Time</strong></td>
							<td><strong>Event</strong></td>
							<td><strong>Relative to event</strong></td>
							<td><strong>Interpretation</strong></td>
							<td><strong>Type</strong></td>
							<td><strong>Rule</strong></td>
							<td><strong>Status</strong></td>
							<td><strong>Military</strong></td>
							<td><strong>Origin</strong></td>
							<td><strong>Purpose</strong></td>
							<td><strong>Equipment and certification</strong></td>
							<td><strong>Type</strong></td>
							<td><strong>Engine Type</strong></td>
							<td><strong>Number of engines</strong></td>
							<td><strong>ICAO aircraft type designator</strong></td>
						</tr>
						
						<xsl:for-each select="//aixm:AirportHeliport">
							
							<!-- Aerodrome / Heliport - Identification and ICAO Code -->
							<xsl:variable name="AirportDesignator" select="aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:designator"/>
							<xsl:variable name="AirportICAOcode" select="aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:locationIndicatorICAO"/>
							
							<!-- Aerodrome / Heliport - UUID -->
							<xsl:variable name="AirportUUID" select="gml:identifier"/>
							
							<!-- Effective date -->
							<xsl:variable name="EffectiveDate_day" select="substring(aixm:timeSlice/aixm:AirportHeliportTimeSlice/gml:validTime/gml:TimePeriod/gml:beginPosition, 9, 2)"/>
							<xsl:variable name="EffectiveDate_month" select="substring(aixm:timeSlice/aixm:AirportHeliportTimeSlice/gml:validTime/gml:TimePeriod/gml:beginPosition, 6, 2)"/>
							<xsl:variable name="EffectiveDate_month" select="if($EffectiveDate_month = '01') then 'JAN' else if ($EffectiveDate_month = '02') then 'FEB' else if ($EffectiveDate_month = '03') then 'MAR' else 
								if ($EffectiveDate_month = '04') then 'APR' else if ($EffectiveDate_month = '05') then 'MAY' else if ($EffectiveDate_month = '06') then 'JUN' else if ($EffectiveDate_month = '07') then 'JUL' else 
								if ($EffectiveDate_month = '08') then 'AUG' else if ($EffectiveDate_month = '09') then 'SEP' else if ($EffectiveDate_month = '10') then 'OCT' else if ($EffectiveDate_month = '11') then 'NOV' else 'DEC'"/>
							<xsl:variable name="EffectiveDate_year" select="substring(aixm:timeSlice/aixm:AirportHeliportTimeSlice/gml:validTime/gml:TimePeriod/gml:beginPosition, 1, 4)"/>
							<xsl:variable name="EffectiveDate" select="concat($EffectiveDate_day, '-', $EffectiveDate_month, '-', $EffectiveDate_year)"/>
							
							<!-- Committed on -->
							<xsl:variable name="Commit_day" select="substring(aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate, 9, 2)"/>
							<xsl:variable name="Commit_month" select="substring(aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate, 6, 2)"/>
							<xsl:variable name="Commit_month" select="if($Commit_month = '01') then 'JAN' else if ($Commit_month = '02') then 'FEB' else if ($Commit_month = '03') then 'MAR' else 
								if ($Commit_month = '04') then 'APR' else if ($Commit_month = '05') then 'MAY' else if ($Commit_month = '06') then 'JUN' else if ($Commit_month = '07') then 'JUL' else 
								if ($Commit_month = '08') then 'AUG' else if ($Commit_month = '09') then 'SEP' else if ($Commit_month = '10') then 'OCT' else if ($Commit_month = '11') then 'NOV' else if ($Commit_month = '12') then 'DEC' else ''"/>
							<xsl:variable name="Commit_year" select="substring(aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:creationDate, 1, 4)"/>
							<xsl:variable name="Commit_date" select="concat($Commit_day, '-', $Commit_month, '-', $Commit_year)"/>
							
							<!-- Originator -->
							<xsl:variable name="Originator" select="aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:extension/ead-audit:AirportHeliportExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
							
							<!-- Working hours: H24, HX, HO, NOTAM, if there is an aixm:availability property with aixm:operationalStatus='NORMAL' and no aixm:Timesheet -->
							<xsl:for-each select="aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:availability/aixm:AirportHeliportAvailability[not(aixm:timeInterval/aixm:Timesheet) and aixm:operationalStatus = 'NORMAL']">
								<xsl:variable name="TimeRemarks" select="aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:purpose=('REMARK', 'DESCRIPTION', 'WARNING')]/aixm:translatedNote/aixm:LinguisticNote/aixm:note"/>
								<xsl:variable name="WorkingHours">
									<xsl:choose>
										<xsl:when test="not(aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:translatedNote/aixm:LinguisticNote[aixm:note='HX (no specific working hours)' or aixm:note='HO (service available to meet operational requests)' or aixm:note='activity periods to be published by NOTAM']])">
											<xsl:value-of select="'H24'"/>
										</xsl:when>
										<xsl:when test="aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:translatedNote/aixm:LinguisticNote/aixm:note='HX (no specific working hours)']">
											<xsl:value-of select="'HX'"/>
										</xsl:when>
										<xsl:when test="aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:translatedNote/aixm:LinguisticNote/aixm:note='HO (service available to meet operational requests)']">
											<xsl:value-of select="'HO'"/>
										</xsl:when>
										<xsl:when test="aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:translatedNote/aixm:LinguisticNote/aixm:note='activity periods to be published by NOTAM']">
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
												<xsl:value-of select="concat(' ', aixm:antiCollisionAndSeparationEquipment)"/>
											</xsl:if>
											<xsl:if test="aixm:communicationEquipment">
												<xsl:value-of select="concat(' ', aixm:communicationEquipment)"/>
											</xsl:if>
											<xsl:if test="aixm:surveillanceEquipment">
												<xsl:value-of select="concat(' ', aixm:surveillanceEquipment)"/>
											</xsl:if>
										</xsl:variable>
										<tr>
											<td><xsl:value-of select="if (string-length($AirportDesignator) != 0) then $AirportDesignator else '&#160;'"/></td>
											<td><xsl:value-of select="if (string-length($AirportICAOcode) != 0) then $AirportICAOcode else '&#160;'"/></td>
											<td><xsl:value-of select="if (string-length($LimitationCode) != 0) then $LimitationCode else '&#160;'"/></td>
											<td><xsl:value-of select="if (string-length($WorkingHours) != 0) then $WorkingHours else '&#160;'"/></td>
											<td><xsl:value-of select="if (string-length($TimeRemarks) != 0) then $TimeRemarks else '&#160;'"/></td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td><xsl:value-of select="if (string-length($AircraftEquipment) != 0) then $AircraftEquipment else '&#160;'"/></td>
											<td><xsl:value-of select="if (aixm:type) then aixm:type else '&#160;'"/></td>
											<td><xsl:value-of select="if (aixm:engine) then aixm:engine else '&#160;'"/></td>
											<td><xsl:value-of select="if (aixm:numberEngine) then aixm:numberEngine else '&#160;'"/></td>
											<td><xsl:value-of select="if (aixm:typeAircraftICAO) then aixm:typeAircraftICAO else '&#160;'"/></td>
											<td><xsl:value-of select="if (string-length($EffectiveDate) gt 4) then $EffectiveDate else '&#160;'"/></td>
											<td><xsl:value-of select="if (string-length($Commit_date) gt 4) then $Commit_date else '&#160;'"/></td>
											<td><xsl:value-of select="if (string-length($AirportUUID) != 0) then $AirportUUID else '&#160;'"/></td>
											<td><xsl:value-of select="if (string-length($Originator) != 0) then $Originator else '&#160;'"/></td>
										</tr>
									</xsl:for-each>
									<!-- Generate a new table row for each FlightCharacteristic -->
									<xsl:for-each select="aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic">
										<tr>
											<td><xsl:value-of select="if (string-length($AirportDesignator) != 0) then $AirportDesignator else '&#160;'"/></td>
											<td><xsl:value-of select="if (string-length($AirportICAOcode) != 0) then $AirportICAOcode else '&#160;'"/></td>
											<td><xsl:value-of select="if (string-length($LimitationCode) != 0) then $LimitationCode else '&#160;'"/></td>
											<td><xsl:value-of select="if (string-length($WorkingHours) != 0) then $WorkingHours else '&#160;'"/></td>
											<td><xsl:value-of select="if (string-length($TimeRemarks) != 0) then $TimeRemarks else '&#160;'"/></td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td><xsl:value-of select="if (aixm:type) then aixm:type else '&#160;'"/></td>
											<td><xsl:value-of select="if (aixm:rule) then aixm:rule else '&#160;'"/></td>
											<td><xsl:value-of select="if (aixm:status) then aixm:status else '&#160;'"/></td>
											<td><xsl:value-of select="if (aixm:military) then aixm:military else '&#160;'"/></td>
											<td><xsl:value-of select="if (aixm:origin) then aixm:origin else '&#160;'"/></td>
											<td><xsl:value-of select="if (aixm:purpose) then aixm:purpose else '&#160;'"/></td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td>&#160;</td>
											<td><xsl:value-of select="if (string-length($EffectiveDate) gt 4) then $EffectiveDate else '&#160;'"/></td>
											<td><xsl:value-of select="if (string-length($Commit_date) gt 4) then $Commit_date else '&#160;'"/></td>
											<td><xsl:value-of select="if (string-length($AirportUUID) != 0) then $AirportUUID else '&#160;'"/></td>
											<td><xsl:value-of select="if (string-length($Originator) != 0) then $Originator else '&#160;'"/></td>
										</tr>
									</xsl:for-each>
								</xsl:for-each>
								<!-- Locigal operator AND -->
								<xsl:for-each select="aixm:usage/aixm:AirportHeliportUsage[aixm:selection/aixm:ConditionCombination/aixm:logicalOperator='AND']">
									<!-- Limitation Code -->
									<xsl:variable name="LimitationCode" select="aixm:type"/>
									<tr>
										<td><xsl:value-of select="if (string-length($AirportDesignator) != 0) then $AirportDesignator else '&#160;'"/></td>
										<td><xsl:value-of select="if (string-length($AirportICAOcode) != 0) then $AirportICAOcode else '&#160;'"/></td>
										<td><xsl:value-of select="if (string-length($LimitationCode) != 0) then $LimitationCode else '&#160;'"/></td>
										<td><xsl:value-of select="if (string-length($WorkingHours) != 0) then $WorkingHours else '&#160;'"/></td>
										<td><xsl:value-of select="if (string-length($TimeRemarks) != 0) then $TimeRemarks else '&#160;'"/></td>
										<td>&#160;</td>
										<td>&#160;</td>
										<td>&#160;</td>
										<td>&#160;</td>
										<td>&#160;</td>
										<td>&#160;</td>
										<td>&#160;</td>
										<td>&#160;</td>
										<td>&#160;</td>
										<td>&#160;</td>
										<td>&#160;</td>
										<td>&#160;</td>
										<td>&#160;</td>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:type) then aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:type else '&#160;'"/></td>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:rule) then aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:rule else '&#160;'"/></td>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:status) then aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:status else '&#160;'"/></td>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:military) then aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:military else '&#160;'"/></td>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:origin) then aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:origin else '&#160;'"/></td>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:purpose) then aixm:selection/aixm:ConditionCombination/aixm:flight/aixm:FlightCharacteristic/aixm:purpose else '&#160;'"/></td>
										<xsl:variable name="AircraftEquipment">
											<xsl:if test="aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:navigationEquipment">
												<xsl:value-of select="aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:navigationEquipment"/>
											</xsl:if>
											<xsl:if test="aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:antiCollisionAndSeparationEquipment">
												<xsl:value-of select="concat(' ', aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:antiCollisionAndSeparationEquipment)"/>
											</xsl:if>
											<xsl:if test="aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:communicationEquipment">
												<xsl:value-of select="concat(' ', aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:communicationEquipment)"/>
											</xsl:if>
											<xsl:if test="aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:surveillanceEquipment">
												<xsl:value-of select="concat(' ', aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:surveillanceEquipment)"/>
											</xsl:if>
										</xsl:variable>
										<td><xsl:value-of select="if (string-length($AircraftEquipment) != 0) then $AircraftEquipment else '&#160;'"/></td>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:type) then aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:type else '&#160;'"/></td>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:engine) then aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:engine else '&#160;'"/></td>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:numberEngine) then aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:numberEngine else '&#160;'"/></td>
										<td><xsl:value-of select="if (aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:typeAircraftICAO) then aixm:selection/aixm:ConditionCombination/aixm:aircraft/aixm:AircraftCharacteristic/aixm:typeAircraftICAO else '&#160;'"/></td>
										<td><xsl:value-of select="if (string-length($EffectiveDate) gt 4) then $EffectiveDate else '&#160;'"/></td>
										<td><xsl:value-of select="if (string-length($Commit_date) gt 4) then $Commit_date else '&#160;'"/></td>
										<td><xsl:value-of select="if (string-length($AirportUUID) != 0) then $AirportUUID else '&#160;'"/></td>
										<td><xsl:value-of select="if (string-length($Originator) != 0) then $Originator else '&#160;'"/></td>
									</tr>
								</xsl:for-each>
							</xsl:for-each>
							
							<!-- Working hours: H24, HJ, HN, or other; if there is an aixm:availability property with aixm:operationalStatus='NORMAL' and at least one aixm:Timesheet -->
							<xsl:for-each select="aixm:timeSlice/aixm:AirportHeliportTimeSlice/aixm:availability/aixm:AirportHeliportAvailability[aixm:timeInterval/aixm:Timesheet and aixm:operationalStatus = 'NORMAL']">
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
									<xsl:variable name="TimeRemarks" select="../../aixm:annotation/aixm:Note[aixm:propertyName='timeInterval' and aixm:purpose=('REMARK', 'DESCRIPTION', 'WARNING')]/aixm:translatedNote/aixm:LinguisticNote/aixm:note"/>
									<xsl:variable name="TimeReference" select="aixm:timeReference"/>
									<xsl:variable name="YearlyStartDate" select="aixm:startDate"/>
									<xsl:variable name="YearlyEndDate" select="aixm:endDate"/>
									<xsl:variable name="DayStart" select="aixm:day"/>
									<xsl:variable name="DayEnd" select="aixm:dayTil"/>
									<xsl:variable name="StartTime" select="aixm:startTime"/>
									<xsl:variable name="EndTime" select="aixm:endTime"/>
									<xsl:variable name="StartEvent" select="aixm:startEvent"/>
									<xsl:variable name="EndEvent" select="aixm:endEvent"/>
									<xsl:variable name="RelativeToEventStart" select="if (number(aixm:startTimeRelativeEvent) gt 0) then concat('+', aixm:startTimeRelativeEvent) else aixm:startTimeRelativeEvent"/>
									<xsl:variable name="RelativeToEventStartUOM" select="aixm:startTimeRelativeEvent/@uom"/>
									<xsl:variable name="RelativeToEventEnd" select="if (number(aixm:endTimeRelativeEvent) gt 0) then concat('+', aixm:endTimeRelativeEvent) else aixm:endTimeRelativeEvent"/>
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
														<xsl:value-of select="concat(' ', aixm:antiCollisionAndSeparationEquipment)"/>
													</xsl:if>
													<xsl:if test="aixm:communicationEquipment">
														<xsl:value-of select="concat(' ', aixm:communicationEquipment)"/>
													</xsl:if>
													<xsl:if test="aixm:surveillanceEquipment">
														<xsl:value-of select="concat(' ', aixm:surveillanceEquipment)"/>
													</xsl:if>
												</xsl:variable>
												<tr>
													<td><xsl:value-of select="if (string-length($AirportDesignator) != 0) then $AirportDesignator else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($AirportICAOcode) != 0) then $AirportICAOcode else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($LimitationCode) != 0) then $LimitationCode else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($WorkingHours) != 0) then $WorkingHours else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($TimeRemarks) != 0) then $TimeRemarks else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($TimeReference) != 0) then $TimeReference else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($YearlyStartDate) != 0) then $YearlyStartDate else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($YearlyEndDate) != 0) then $YearlyEndDate else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($DayStart) != 0) then $DayStart else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($DayEnd) != 0) then $DayEnd else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($StartTime) != 0) then $StartTime else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($StartEvent) != 0) then $StartEvent else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($RelativeToEventStart) != 0) then concat($RelativeToEventStart, ' ',$RelativeToEventStartUOM) else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($InterpretationStart) != 0) then $InterpretationStart else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($EndTime) != 0) then $EndTime else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($EndEvent) != 0) then $EndEvent else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($RelativeToEventEnd) != 0) then concat($RelativeToEventEnd, ' ',$RelativeToEventEndUOM) else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($InterpretationEnd) != 0) then $InterpretationEnd else '&#160;'"/></td>
													<td>&#160;</td>
													<td>&#160;</td>
													<td>&#160;</td>
													<td>&#160;</td>
													<td>&#160;</td>
													<td>&#160;</td>
													<td><xsl:value-of select="if (string-length($AircraftEquipment) != 0) then $AircraftEquipment else '&#160;'"/></td>
													<td><xsl:value-of select="if (aixm:type) then aixm:type else '&#160;'"/></td>
													<td><xsl:value-of select="if (aixm:engine) then aixm:engine else '&#160;'"/></td>
													<td><xsl:value-of select="if (aixm:numberEngine) then aixm:numberEngine else '&#160;'"/></td>
													<td><xsl:value-of select="if (aixm:typeAircraftICAO) then aixm:typeAircraftICAO else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($EffectiveDate) gt 4) then $EffectiveDate else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($Commit_date) gt 4) then $Commit_date else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($AirportUUID) != 0) then $AirportUUID else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($Originator) != 0) then $Originator else '&#160;'"/></td>
												</tr>
											</xsl:for-each>
											<!-- Generate a new table row for each Timesheet and each FlightCharacteristic -->
											<xsl:for-each select="aixm:flight/aixm:FlightCharacteristic">
												<tr>
													<td><xsl:value-of select="if (string-length($AirportDesignator) != 0) then $AirportDesignator else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($AirportICAOcode) != 0) then $AirportICAOcode else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($LimitationCode) != 0) then $LimitationCode else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($WorkingHours) != 0) then $WorkingHours else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($TimeRemarks) != 0) then $TimeRemarks else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($TimeReference) != 0) then $TimeReference else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($YearlyStartDate) != 0) then $YearlyStartDate else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($YearlyEndDate) != 0) then $YearlyEndDate else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($DayStart) != 0) then $DayStart else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($DayEnd) != 0) then $DayEnd else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($StartTime) != 0) then $StartTime else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($StartEvent) != 0) then $StartEvent else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($RelativeToEventStart) != 0) then concat($RelativeToEventStart, ' ',$RelativeToEventStartUOM) else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($InterpretationStart) != 0) then $InterpretationStart else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($EndTime) != 0) then $EndTime else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($EndEvent) != 0) then $EndEvent else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($RelativeToEventEnd) != 0) then concat($RelativeToEventEnd, ' ',$RelativeToEventEndUOM) else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($InterpretationEnd) != 0) then $InterpretationEnd else '&#160;'"/></td>
													<td><xsl:value-of select="if (aixm:type) then aixm:type else '&#160;'"/></td>
													<td><xsl:value-of select="if (aixm:rule) then aixm:rule else '&#160;'"/></td>
													<td><xsl:value-of select="if (aixm:status) then aixm:status else '&#160;'"/></td>
													<td><xsl:value-of select="if (aixm:military) then aixm:military else '&#160;'"/></td>
													<td><xsl:value-of select="if (aixm:origin) then aixm:origin else '&#160;'"/></td>
													<td><xsl:value-of select="if (aixm:purpose) then aixm:purpose else '&#160;'"/></td>
													<td>&#160;</td>
													<td>&#160;</td>
													<td>&#160;</td>
													<td>&#160;</td>
													<td>&#160;</td>
													<td><xsl:value-of select="if (string-length($EffectiveDate) gt 4) then $EffectiveDate else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($Commit_date) gt 4) then $Commit_date else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($AirportUUID) != 0) then $AirportUUID else '&#160;'"/></td>
													<td><xsl:value-of select="if (string-length($Originator) != 0) then $Originator else '&#160;'"/></td>
												</tr>
											</xsl:for-each>
										</xsl:for-each>
										<!-- Logical operator AND -->
										<xsl:for-each select="aixm:selection/aixm:ConditionCombination[aixm:logicalOperator='AND']">
											<!-- Limitation Code -->
											<xsl:variable name="LimitationCode" select="../../aixm:type"/>
											<tr>
												<td><xsl:value-of select="if (string-length($AirportDesignator) != 0) then $AirportDesignator else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($AirportICAOcode) != 0) then $AirportICAOcode else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($LimitationCode) != 0) then $LimitationCode else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($WorkingHours) != 0) then $WorkingHours else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($TimeRemarks) != 0) then $TimeRemarks else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($TimeReference) != 0) then $TimeReference else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($YearlyStartDate) != 0) then $YearlyStartDate else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($YearlyEndDate) != 0) then $YearlyEndDate else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($DayStart) != 0) then $DayStart else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($DayEnd) != 0) then $DayEnd else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($StartTime) != 0) then $StartTime else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($StartEvent) != 0) then $StartEvent else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($RelativeToEventStart) != 0) then concat($RelativeToEventStart, ' ',$RelativeToEventStartUOM) else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($InterpretationStart) != 0) then $InterpretationStart else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($EndTime) != 0) then $EndTime else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($EndEvent) != 0) then $EndEvent else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($RelativeToEventEnd) != 0) then concat($RelativeToEventEnd, ' ',$RelativeToEventEndUOM) else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($InterpretationEnd) != 0) then $InterpretationEnd else '&#160;'"/></td>
												<td><xsl:value-of select="if (aixm:flight/aixm:FlightCharacteristic/aixm:type) then aixm:flight/aixm:FlightCharacteristic/aixm:type else '&#160;'"/></td>
												<td><xsl:value-of select="if (aixm:flight/aixm:FlightCharacteristic/aixm:rule) then aixm:flight/aixm:FlightCharacteristic/aixm:rule else '&#160;'"/></td>
												<td><xsl:value-of select="if (aixm:flight/aixm:FlightCharacteristic/aixm:status) then aixm:flight/aixm:FlightCharacteristic/aixm:status else '&#160;'"/></td>
												<td><xsl:value-of select="if (aixm:flight/aixm:FlightCharacteristic/aixm:military) then aixm:flight/aixm:FlightCharacteristic/aixm:military else '&#160;'"/></td>
												<td><xsl:value-of select="if (aixm:flight/aixm:FlightCharacteristic/aixm:origin) then aixm:flight/aixm:FlightCharacteristic/aixm:origin else '&#160;'"/></td>
												<td><xsl:value-of select="if (aixm:flight/aixm:FlightCharacteristic/aixm:purpose) then aixm:flight/aixm:FlightCharacteristic/aixm:purpose else '&#160;'"/></td>
												<xsl:variable name="AircraftEquipment">
													<xsl:if test="aixm:aircraft/aixm:AircraftCharacteristic/aixm:navigationEquipment">
														<xsl:value-of select="aixm:aircraft/aixm:AircraftCharacteristic/aixm:navigationEquipment"/>
													</xsl:if>
													<xsl:if test="aixm:aircraft/aixm:AircraftCharacteristic/aixm:antiCollisionAndSeparationEquipment">
														<xsl:value-of select="concat(' ', aixm:aircraft/aixm:AircraftCharacteristic/aixm:antiCollisionAndSeparationEquipment)"/>
													</xsl:if>
													<xsl:if test="aixm:aircraft/aixm:AircraftCharacteristic/aixm:communicationEquipment">
														<xsl:value-of select="concat(' ', aixm:aircraft/aixm:AircraftCharacteristic/aixm:communicationEquipment)"/>
													</xsl:if>
													<xsl:if test="aixm:aircraft/aixm:AircraftCharacteristic/aixm:surveillanceEquipment">
														<xsl:value-of select="concat(' ', aixm:aircraft/aixm:AircraftCharacteristic/aixm:surveillanceEquipment)"/>
													</xsl:if>
												</xsl:variable>
												<td><xsl:value-of select="if (string-length($AircraftEquipment) != 0) then $AircraftEquipment else '&#160;'"/></td>
												<td><xsl:value-of select="if (aixm:aircraft/aixm:AircraftCharacteristic/aixm:type) then aixm:aircraft/aixm:AircraftCharacteristic/aixm:type else '&#160;'"/></td>
												<td><xsl:value-of select="if (aixm:aircraft/aixm:AircraftCharacteristic/aixm:engine) then aixm:aircraft/aixm:AircraftCharacteristic/aixm:engine else '&#160;'"/></td>
												<td><xsl:value-of select="if (aixm:aircraft/aixm:AircraftCharacteristic/aixm:numberEngine) then aixm:aircraft/aixm:AircraftCharacteristic/aixm:numberEngine else '&#160;'"/></td>
												<td><xsl:value-of select="if (aixm:aircraft/aixm:AircraftCharacteristic/aixm:typeAircraftICAO) then aixm:aircraft/aixm:AircraftCharacteristic/aixm:typeAircraftICAO else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($EffectiveDate) gt 4) then $EffectiveDate else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($Commit_date) gt 4) then $Commit_date else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($AirportUUID) != 0) then $AirportUUID else '&#160;'"/></td>
												<td><xsl:value-of select="if (string-length($Originator) != 0) then $Originator else '&#160;'"/></td>
											</tr>
										</xsl:for-each>
									</xsl:for-each>
								</xsl:for-each>
							</xsl:for-each>
							
						</xsl:for-each>
						
					</tbody>
				</table>
				
			</body>
			
		</html>
		
	</xsl:template>
	
</xsl:transform>