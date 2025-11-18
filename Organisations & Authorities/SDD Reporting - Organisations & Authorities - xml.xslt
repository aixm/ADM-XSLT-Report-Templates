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

<!-- for successful transformation, the XML file must contain the following feature: aixm:OrganisationAuthority -->

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
	
	<xsl:output method="xml" indent="yes"/>
	
	<xsl:strip-space elements="*"/>
	
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
	
	<!-- Get annotation text preserving line breaks and escaping special HTML characters -->
	<xsl:function name="fcn:get-annotation-text" as="xs:string">
		<xsl:param name="raw_text" as="xs:string"/>
		<!-- First, escape special HTML characters in the raw text before processing -->
		<xsl:variable name="escaped_raw_text" select="replace(replace($raw_text, '&lt;', '&amp;lt;'), '&gt;', '&amp;gt;')"/>
		<xsl:variable name="lines" select="for $line in tokenize($escaped_raw_text, '&#xA;') return normalize-space($line)"/>
		<xsl:variable name="non_empty_lines" select="$lines[string-length(.) gt 0]"/>
		<xsl:value-of select="string-join($non_empty_lines, '&#10;')"/>
	</xsl:function>
	
	<xsl:template match="/">
		
		<xsl:element name="SdoReportResponse" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<xsl:attribute name="created" select="//aixm:messageMetadata/gmd:MD_Metadata/gmd:identificationInfo/gmd:MD_DataIdentification/gmd:citation/gmd:CI_Citation/gmd:date/gmd:CI_Date/gmd:date/gco:DateTime"/>
			<xsl:attribute name="xsi:noNamespaceSchemaLocation" select="'SdoReportMgmt.xsd'"/>
			<xsl:attribute name="origin" select="'SDD'"/>
			<xsl:attribute name="version" select="'4.1'"/>
			<SdoReportResult>
				
				<xsl:for-each select="//aixm:OrganisationAuthority/aixm:timeSlice/aixm:OrganisationAuthorityTimeSlice">
					
					<xsl:sort select="aixm:name" order="ascending"/>
					<xsl:sort select="aixm:sequenceNumber" order="descending" data-type="number"/>
					<xsl:sort select="aixm:correctionNumber" order="descending" data-type="number"/>
					
					<!-- FeatureIdentifier -->
					<xsl:variable name="identifier" select="../../gml:identifier"/>
					
					<!-- FeatureLifetimeBegin -->
					<xsl:variable name="lifetime-begin">
						<xsl:choose>
							<xsl:when test="not(aixm:featureLifetime/gml:TimePeriod/gml:beginPosition)">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="fcn:get-date(aixm:featureLifetime/gml:TimePeriod/gml:beginPosition)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- FeatureLifetimeEnd -->
					<xsl:variable name="lifetime-end">
						<xsl:choose>
							<xsl:when test="aixm:featureLifetime/gml:TimePeriod/gml:endPosition/@indeterminatePosition = 'unknown'">
								<xsl:value-of select="'31-DEC-9999'"/>
							</xsl:when>
							<xsl:when test="not(aixm:featureLifetime/gml:TimePeriod/gml:endPosition/@indeterminatePosition) and aixm:featureLifetime/gml:TimePeriod/gml:endPosition">
								<xsl:value-of select="fcn:get-date(aixm:featureLifetime/gml:TimePeriod/gml:endPosition)"/>
							</xsl:when>
							<xsl:when test="not(aixm:featureLifetime/gml:TimePeriod/gml:endPosition)">
								<xsl:value-of select="fcn:get-date(aixm:featureLifetime/gml:TimePeriod/gml:endPosition)"/>
							</xsl:when>
						</xsl:choose>
					</xsl:variable>
					
					<!-- ValidityFrom -->
					<xsl:variable name="validity-begin">
						<xsl:choose>
							<xsl:when test="not(gml:validTime/gml:TimePeriod/gml:beginPosition)">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="fcn:get-date(gml:validTime/gml:TimePeriod/gml:beginPosition)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- ValidityTo -->
					<xsl:variable name="validity-end">
						<xsl:choose>
							<xsl:when test="gml:validTime/gml:TimePeriod/gml:endPosition/@indeterminatePosition = 'unknown'">
								<xsl:value-of select="'31-DEC-9999'"/>
							</xsl:when>
							<xsl:when test="not(gml:validTime/gml:TimePeriod/gml:endPosition/@indeterminatePosition) and gml:validTime/gml:TimePeriod/gml:endPosition">
								<xsl:value-of select="fcn:get-date(gml:validTime/gml:TimePeriod/gml:endPosition)"/>
							</xsl:when>
							<xsl:when test="not(gml:validTime/gml:TimePeriod/gml:endPosition)">
								<xsl:value-of select="''"/>
							</xsl:when>
						</xsl:choose>
					</xsl:variable>
					
					<!-- SequenceNumber -->
					<xsl:variable name="sequence-number">
						<xsl:choose>
							<xsl:when test="not(aixm:sequenceNumber)">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="fcn:insert-value(aixm:sequenceNumber)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- CorrectionNumber -->
					<xsl:variable name="correction-number">
						<xsl:choose>
							<xsl:when test="not(aixm:correctionNumber)">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="fcn:insert-value(aixm:correctionNumber)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- Name -->
					<xsl:variable name="name">
						<xsl:choose>
							<xsl:when test="not(aixm:name)">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="fcn:insert-value(aixm:name)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- Designator -->
					<xsl:variable name="designator">
						<xsl:choose>
							<xsl:when test="not(aixm:designator)">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="fcn:insert-value(aixm:designator)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- Type -->
					<xsl:variable name="type">
						<xsl:choose>
							<xsl:when test="not(aixm:type)">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="fcn:insert-value(aixm:type)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- Military -->
					<xsl:variable name="military">
						<xsl:choose>
							<xsl:when test="not(aixm:military)">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="fcn:insert-value(aixm:military)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- Annotation -->
					<xsl:variable name="annotation">
						<xsl:choose>
							<xsl:when test="not(aixm:annotation)">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:variable name="all-notes" select="aixm:annotation/aixm:Note/aixm:translatedNote/aixm:LinguisticNote"/>
								<xsl:for-each select="$all-notes">
									<xsl:variable name="global-index" select="position()"/>
									<xsl:choose>
										<xsl:when test="$global-index = 1">
											<xsl:value-of select="concat('[', $global-index, ']', '(', if (../../aixm:propertyName) then (concat(../../aixm:propertyName, ';')) else '', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', '): ', fcn:get-annotation-text(aixm:note))"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="concat('&#10;', '[', $global-index, ']', '(', if (../../aixm:propertyName) then (concat(../../aixm:propertyName, ';')) else '', ../../aixm:purpose, if (aixm:note/@lang) then (concat(';', aixm:note/@lang)) else '', '): ', fcn:get-annotation-text(aixm:note))"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:for-each>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- EAD-Audit -->
					<xsl:variable name="EAD-Audit" select="aixm:extension/ead-audit:OrganisationAuthorityExtension/ead-audit:auditInformation/ead-audit:Audit"/>
					
					<!-- EAD-AUDIT:CreatedBy -->
					<xsl:variable name="created-by">
						<xsl:choose>
							<xsl:when test="not($EAD-Audit/ead-audit:createdBy)">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:createdBy)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- EAD-AUDIT:CreationDate -->
					<xsl:variable name="creation-date">
						<xsl:choose>
							<xsl:when test="not($EAD-Audit/ead-audit:creationDate)">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="fcn:get-date($EAD-Audit/ead-audit:creationDate)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- EAD-AUDIT:CreatedByOrganisation -->
					<xsl:variable name="created-by-org">
						<xsl:choose>
							<xsl:when test="not($EAD-Audit/ead-audit:createdByOrg)">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:createdByOrg)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- EAD-AUDIT:CreatedOnBehalfOfUser -->
					<xsl:variable name="created-on-behalf-of-user">
						<xsl:choose>
							<xsl:when test="not($EAD-Audit/ead-audit:createdOnBehalfOfUser)">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:createdOnBehalfOfUser)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- EAD-AUDIT:CreatedOnBehalfOfOrganisation -->
					<xsl:variable name="created-on-behalf-of-org">
						<xsl:choose>
							<xsl:when test="not($EAD-Audit/ead-audit:createdOnBehalfOfOrg)">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:createdOnBehalfOfOrg)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- EAD-AUDIT:ReasonForChange -->
					<xsl:variable name="reason-for-change">
						<xsl:choose>
							<xsl:when test="not($EAD-Audit/ead-audit:reasonForChange)">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:reasonForChange)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<!-- EAD-AUDIT:ResponsibleSubsystem -->
					<xsl:variable name="responsible-subsystem">
						<xsl:choose>
							<xsl:when test="not($EAD-Audit/ead-audit:responsibleSubsystem)">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="fcn:insert-value($EAD-Audit/ead-audit:responsibleSubsystem)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<Record>
						<xsl:if test="string-length($identifier) gt 0">
							<FEA>
								<IDENTIFIER><xsl:value-of select="$identifier"/></IDENTIFIER>
								<LIFE>
									<WEF><xsl:value-of select="$lifetime-begin"/></WEF>
									<TIL><xsl:value-of select="$lifetime-end"/></TIL>
								</LIFE>
							</FEA>
						</xsl:if>
						<TS>
							<VALID>
								<WEF><xsl:value-of select="$validity-begin"/></WEF>
								<TIL><xsl:value-of select="$validity-end"/></TIL>
							</VALID>
							<xsl:if test="string-length($sequence-number) gt 0 or string-length($correction-number) gt 0">
								<NO>
									<xsl:if test="string-length($sequence-number) gt 0">
										<SEQ><xsl:value-of select="$sequence-number"/></SEQ>
									</xsl:if>
									<xsl:if test="string-length($correction-number) gt 0">
										<CORR><xsl:value-of select="$correction-number"/></CORR>
									</xsl:if>
								</NO>
							</xsl:if>
						</TS>
						<xsl:if test="string-length($name) gt 0">
							<NAME><xsl:value-of select="$name"/></NAME>
						</xsl:if>
						<xsl:if test="string-length($designator) gt 0">
							<DESG><xsl:value-of select="$designator"/></DESG>
						</xsl:if>
						<xsl:if test="string-length($type) gt 0">
							<TYPE><xsl:value-of select="$type"/></TYPE>
						</xsl:if>
						<xsl:if test="string-length($military) gt 0">
							<MILITARY><xsl:value-of select="$military"/></MILITARY>
						</xsl:if>
						<xsl:if test="string-length($annotation) gt 0">
							<annotation><xsl:value-of select="$annotation"/></annotation>
						</xsl:if>
						<xsl:if test="not(empty($EAD-Audit))">
							<TC>
								<xsl:if test="string-length($created-by) gt 0">
									<USER>
										<ID>
											<CRE><xsl:value-of select="$created-by"/></CRE>
										</ID>
									</USER>
								</xsl:if>
								<xsl:if test="string-length($creation-date) gt 0">
									<DT>
										<CRE><xsl:value-of select="$creation-date"/></CRE>
									</DT>
								</xsl:if>
								<xsl:if test="string-length($created-by-org) gt 0">
									<ORG>
										<NAME>
											<CRE><xsl:value-of select="$created-by-org"/></CRE>
										</NAME>
									</ORG>
								</xsl:if>
								<xsl:if test="string-length($created-on-behalf-of-user) gt 0 or string-length($created-on-behalf-of-org) gt 0">
									<BEHALF>
										<xsl:if test="string-length($created-on-behalf-of-user)">
											<USER>
												<ID>
													<CRE><xsl:value-of select="$created-on-behalf-of-user"/></CRE>
												</ID>
											</USER>
										</xsl:if>
										<xsl:if test="string-length($created-on-behalf-of-org)">
											<ORG>
												<NAME>
													<CRE><xsl:value-of select="$created-on-behalf-of-org"/></CRE>
												</NAME>
											</ORG>
										</xsl:if>
									</BEHALF>
								</xsl:if>
								<xsl:if test="string-length($reason-for-change) gt 0">
									<CHANGE>
										<REASON><xsl:value-of select="$reason-for-change"/></REASON>
									</CHANGE>
								</xsl:if>
								<xsl:if test="string-length($responsible-subsystem) gt 0">
									<ORIGIN><xsl:value-of select="$responsible-subsystem"/></ORIGIN>
								</xsl:if>
							</TC>
						</xsl:if>
					</Record>
					
				</xsl:for-each>
				
			</SdoReportResult>
		</xsl:element>
		
	</xsl:template>
	
</xsl:transform>