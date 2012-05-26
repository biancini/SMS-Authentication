<?xml version="1.0" encoding="utf-8"?>
<!--
        XSLT for creating the web pages describing the web-services available on this machine.
             This file was developed by Andrea Biancini on behalf of Reti S.p.A.
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template match="/services">
		<xsl:value-of select="header"/>

		<xsl:for-each select="webservices/service">
		<xsl:if test="@name = &quot;NAMEWS&quot;">
		<xsl:variable name="servicename"><xsl:value-of select="@name"/></xsl:variable>

		<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US" lang="en-US">
			<head>
				<title>Web Service: <xsl:value-of select="@name"/></title>
				<link rel="alternate" type="text/xml" href="../{@name}/disco.xml"/>
				<link href="../style.css" rel="stylesheet" type="text/css"/>
			</head>
			<body style="margin: 0px">
				<table width="100%" height="100%" cellspacing="0">
					<tr height="25">
						<td width="140" align="center" valign="top" class="redCol">
							<i><xsl:value-of select="@name"/></i>
						</td>
						<td width="10" />
						<td />
					</tr>
					<tr>
						<td width="140" align="center" valign="bottom" class="redCol">
		                                        <img src="../images/LogoReti.gif" border="0" alt="WebServices"/>
                		                </td>
						<td width="10"/>
						<td valign="top">
							<xsl:value-of select="description"/>
							<br/><br/><hr width="80%"/><br/>
							Elenco dei metodi disponibili:
							<ul>
								<xsl:for-each select="methods/method">
								<li><b><xsl:value-of select="@name"/></b><br/>
								<xsl:value-of select="description"/><br/>
								( <a href="../{$servicename}/{@name}.req.xml">request</a> | <a href="../{$servicename}/{@name}.res.xml">response</a> )<br/><br/></li>
								</xsl:for-each>
							</ul>
		                                </td>
					</tr>
				</table>
			</body>
		</html>

	</xsl:if>
	</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>

