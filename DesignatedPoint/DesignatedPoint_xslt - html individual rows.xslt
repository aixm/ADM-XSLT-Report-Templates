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
	
	<xsl:output method="html" indent="yes"/>
	
	<xsl:strip-space elements="*"/>
	
	<xsl:template match="/">
		
		<html xmlns="http://www.w3.org/1999/xhtml">
			
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
				<meta http-equiv="Expires" content="120"/>
				<title>SDO Reporting - Designated Point</title>
			</head>
			
			<body>
				<table>
					<tbody>
						<tr>
							<td width="1%"><img src="./DPN-single-per-row_files/logo.jpg" alt="AIS"/></td>
							<td width="99%">
								<center>
									<h2>AERONAUTICAL INFORMATION SERVICES</h2>
								</center>
							</td>
						</tr>
					</tbody>
				</table>
				<hr/>
				<center><b>Designated Point</b></center>
				<hr/>
				<table width="100%" border="0">
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
							<td><strong>Type</strong></td>
						</tr>
						<tr>
							<td><strong>Originator</strong></td>
						</tr>
						<tr>
							<td><br/></td>
						</tr>
						<xsl:for-each select="//aixm:DesignatedPointTimeSlice">
							<tr>
								<td><xsl:value-of select="aixm:designator"/></td>
							</tr>
								<xsl:variable name="coordinates" select="aixm:location/aixm:Point/gml:pos"/>
								<xsl:variable name="latitude" select="number(substring-before($coordinates, ' '))"/>
								<xsl:variable name="longitude" select="number(substring-after($coordinates, ' '))"/>
							<tr>
								<td><xsl:value-of select="concat(abs($latitude), if ($latitude >=0) then 'N' else 'S')"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="concat(abs($longitude), if ($longitude >=0) then 'N' else 'S')"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="aixm:type"/></td>
							</tr>
							<tr>
								<td><xsl:value-of select="aixm:extension/ead-audit:DesignatedPointExtension/ead-audit:auditInformation/ead-audit:Audit/ead-audit:createdByOrg"/></td>
							</tr>
							<tr>
								<td><br/></td>
							</tr>
						</xsl:for-each>
					</tbody>
				</table>
			</body>
			
		</html>
		
	</xsl:template>
	
</xsl:transform>