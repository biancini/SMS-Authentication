<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template match="/services">
		<xsl:value-of select="header"/>

		<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US" lang="en-US">
			<head>
				<title>
					Web Services on <xsl:value-of select="@host"/>
				</title>
				<link href="../style.css" rel="stylesheet" type="text/css"/>
				<link rel="alternate" type="text/xml" href="../{@name}/disco.xml"/>
			</head>
			<body style="margin: 0px">
				<table width="100%" height="100%" cellspacing="0">
					<tr height="25">
						<td width="140" align="center" valign="top" class="redCol">
							<i>WEB SERVICES ON<br/><xsl:value-of select="@host"/></i>
						</td>
						<td width="10" />
						<td />
					</tr>
					<tr>
						<td width="140" align="center" valign="bottom" class="redCol">
		                                        <img src="../images/LogoReti.gif" border="0" alt="WebServices"/>
                		                </td>
						<td width="10" />
						<td valign="top">
		                                        <ul>
								<xsl:for-each select="webservices/service">
									<xsl:sort select="@name"/>
	                			                        <li><b><xsl:value-of select="@name"/></b><br/>
									<i><xsl:value-of select="description"/></i><br/>
									( <a href="webservice.pl?ws={@name}">Documentation</a> | <a href="../{@name}/disco.xml">Reference</a> )<br/><br/>
									</li>
								</xsl:for-each>
                                        		</ul>
		                                </td>
					</tr>
				</table>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>

