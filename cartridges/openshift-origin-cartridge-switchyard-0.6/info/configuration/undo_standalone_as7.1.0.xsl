<?xml version="1.0" encoding="UTF-8"?>
<!--
  ~ JBoss, Home of Professional Open Source.
  ~ Copyright 2011, Red Hat, Inc., and individual contributors
  ~ as indicated by the @author tags. See the copyright.txt file in the
  ~ distribution for a full listing of individual contributors.
  ~
  ~ This is free software; you can redistribute it and/or modify it
  ~ under the terms of the GNU Lesser General Public License as
  ~ published by the Free Software Foundation; either version 2.1 of
  ~ the License, or (at your option) any later version.
  ~
  ~ This software is distributed in the hope that it will be useful,
  ~ but WITHOUT ANY WARRANTY; without even the implied warranty of
  ~ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  ~ Lesser General Public License for more details.
  ~
  ~ You should have received a copy of the GNU Lesser General Public
  ~ License along with this software; if not, write to the Free
  ~ Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
  ~ 02110-1301 USA, or see the FSF site: http://www.fsf.org.
  -->
  <xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:xdt="http://www.w3.org/2005/xpath-datatypes"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:as="urn:jboss:domain:1.1"
    xmlns:sy="urn:jboss:domain:switchyard:1.0"
    xmlns:ds="urn:jboss:domain:datasources:1.0"
    xmlns:security="urn:jboss:domain:security:1.1"
    exclude-result-prefixes="xs xsl xsi fn xdt as">

	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>

	<xsl:template match="node()|@*">
     		<xsl:copy>
        		<xsl:apply-templates select="node()|@*"/>
     		</xsl:copy>
   	</xsl:template>

   	<xsl:template match="as:extension[@module='org.switchyard']"/>
   	
   	<xsl:template match="ds:datasource[@pool-name='jbpmDS']"/>
   	
   	<xsl:template match="security:security-domain[@name='bpel-console']"/>

    <xsl:template match="sy:subsystem"/>

</xsl:stylesheet>