<?xml version="1.0" encoding="UTF-8"?>

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
	
	<xsl:output method="xml" indent="yes"/>
	
	<xsl:strip-space elements="*"/>
	
	<xsl:template match="/">
		<SdoReportResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="SdoReportMgmt.xsd" origin="SDO" version="4.1">
			<SdoReportResult>
				<xsl:for-each select="//aixm:DesignatedPointTimeSlice">
					<xsl:element name="Record">
						<xsl:element name="codeId">
							<xsl:value-of select="aixm:designator"/>
						</xsl:element>
						<xsl:variable name="coordinates" select="aixm:location/aixm:Point/gml:pos"/>
						<xsl:variable name="latitude" select="number(substring-before($coordinates, ' '))"/>
						<xsl:variable name="longitude" select="number(substring-after($coordinates, ' '))"/>
						<xsl:element name="geoLat">
							<xsl:value-of select="concat(abs($latitude), if ($latitude >=0) then 'N' else 'S')"/>
						</xsl:element>
						<xsl:element name="geoLong">
							<xsl:value-of select="concat(abs($longitude), if ($longitude >=0) then 'E' else 'W')"/>
						</xsl:element>
						<xsl:element name="codeType">
							<xsl:value-of select="aixm:type"/>
						</xsl:element>
						<xsl:element name="OrgCre">
							<xsl:element name="txtName">
								<xsl:value-of select="aixm:extension/ead-audit:DesignatedPointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/>
							</xsl:element>
						</xsl:element>
					</xsl:element>
				</xsl:for-each>
			</SdoReportResult>
		</SdoReportResponse>
	</xsl:template>
	
</xsl:transform>