<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <xsl:output 
        method="html"
        indent="yes" />
    
    <!-- key to get station info from id -->
    <xsl:key name="stations" match="/metro/stations/station" use="@station_id"/>
    <!-- key to get line info from id -->
    <xsl:key name="lines" match="metro/metro_lines/line" use="@service_id"/>
    
    <xsl:variable name="doc" as="node()" select="/"/>
    
    <xsl:variable name="y_offset" as="xsd:integer" select="250"/>
    <xsl:variable name="x_offset" as="xsd:integer" select="70"/>
    
    <!-- start of the doc -->
    <xsl:template match="/">
        <svg>
            <xsl:attribute name="width" select="$x_offset*50"/>
            <xsl:attribute name="height" select="$y_offset*25"/>
            <xsl:apply-templates select="//line"/>
        </svg>
    </xsl:template>
    
    <xsl:template match="//line">
        
        <xsl:variable name="y_start" as="xsd:integer">
            <xsl:choose>
                <xsl:when test="short_name = '3B'">
                    <xsl:value-of select="15*$y_offset"/> 
                </xsl:when>
                <xsl:when test="short_name = '7B'">
                    <xsl:value-of select="16*$y_offset"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="number(short_name)*$y_offset"/>
                </xsl:otherwise>
            </xsl:choose> 
        </xsl:variable>
        
        <text>
            <xsl:attribute name="text-anchor" select="'start'"/>
            <xsl:attribute name="font-size" select="10"/>
            <xsl:attribute name="transform" select="concat('translate(', $x_offset, ',', $y_start+(-120) , ') rotate(0)')"/>
            <xsl:value-of select="concat('Ligne: ', short_name, ' - ', long_name_first, ' -- ', long_name_last)"/>
        </text>
        
        <xsl:for-each select="stops/*">
            <xsl:if test="name() = 'station'">
                <xsl:apply-templates select=".">
                    <xsl:with-param name="y_start" select="$y_start"/>
                    <xsl:with-param name="position" select="position()"/>
                </xsl:apply-templates>   
            </xsl:if>
            <xsl:if test="name() = 'fork'">
                <xsl:for-each select="left/station">
                    <xsl:apply-templates select=".">
                        <xsl:with-param name="y_start" select="$y_start+(-$x_offset)"/>
                        <xsl:with-param name="position" select="position() + ancestor::fork/preceding-sibling::*[1]/@stop_sequence"/>
                    </xsl:apply-templates>       
                </xsl:for-each>
                <xsl:for-each select="right/station">
                    <xsl:apply-templates select=".">
                        <xsl:with-param name="y_start" select="$y_start+$x_offset"/>
                        <xsl:with-param name="position" select="position() + ancestor::fork/preceding-sibling::*[1]/@stop_sequence"/>
                    </xsl:apply-templates>
                </xsl:for-each>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="station">
        <xsl:param name="y_start"/>
        <xsl:param name="x_start" select="$x_offset"/>
        <xsl:param name="position"/>
        <xsl:variable name="station_id" as="xsd:string" select="@station_id"/>
        
        <text>
            <xsl:attribute name="text-anchor" select="'start'"/>
            <xsl:attribute name="font-size" select="10"/>
            <xsl:attribute name="transform" select="concat('translate(', $x_start*$position, ',', $y_start+(-10) , ') rotate(-45)')"/>
            <xsl:value-of select="key('stations', $station_id)/station_name"/>
        </text>
        
        <circle>
            <xsl:attribute name="cx" select="$x_start * $position"/>
            <xsl:attribute name="cy" select="$y_start"/>
            <xsl:attribute name="stroke" select="'black'"/>
            <xsl:attribute name="r" select="5"/> 
            <xsl:choose>
                <xsl:when test="@links">
                    <xsl:attribute name="fill" select="'blue'"/>
                    <xsl:attribute name="stroke_width" select="4"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:attribute name="fill" select="'white'"/>
                    <xsl:attribute name="stroke_width" select="2"/>
                </xsl:otherwise>
            </xsl:choose>
        </circle>
        
        <xsl:variable name="line_start" as="xsd:integer">
            <xsl:choose>
                <xsl:when test="ancestor::left and (not(preceding-sibling::*))">
                    <xsl:value-of select="$y_start+$x_offset"/>
                </xsl:when>
                <xsl:when test="ancestor::right and (not(preceding-sibling::*))">
                    <xsl:value-of select="$y_start+(-$x_offset)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$y_start"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:if test="$position > 1">
            <line>
                <xsl:attribute name="x1" select="$x_start * ($position - 1) + 5"/>
                <xsl:attribute name="y1" select="$line_start"/>
                <xsl:attribute name="x2" select="$x_start * $position - 5"/>
                <xsl:attribute name="y2" select="$y_start"/>
                <xsl:attribute name="stroke" select="'green'"/>
                <xsl:attribute name="stroke_width" select="4"/>
            </line> 
        </xsl:if>
        <!-- Links: other lines this stations connects to -->
        <xsl:if test="@links">
            <xsl:variable name="links" as="xsd:string*">
                <xsl:sequence select="tokenize(@links, ' ')"/>
            </xsl:variable>
            
            <xsl:iterate select="$links">
                <xsl:variable name="offset" as="xsd:integer" select="$y_start + 10  + (20* (position() - 1))"/>
                <line>
                    <xsl:attribute name="x1" select="$x_start * $position"/>
                    <xsl:attribute name="y1" select="$offset + 7"/>
                    <xsl:attribute name="x2" select="$x_start * $position"/>
                    <xsl:attribute name="y2" select="$offset +(-7)"/>
                    <xsl:attribute name="stroke" select="'red'"/>
                    <xsl:attribute name="stroke_width" select="3"/>
                </line>
                
                <circle>
                    <xsl:attribute name="cx" select="$x_start * $position"/>
                    <xsl:attribute name="cy" select="$offset + 10"/>
                    <xsl:attribute name="stroke" select="'red'"/>
                    <xsl:attribute name="fill" select="'red'"/>
                    <xsl:attribute name="r" select="7"/> 
                </circle>
                
                <text>
                    <xsl:attribute name="x" select="($x_start * $position) - 2"/>
                    <xsl:attribute name="y" select="$offset + 12"/>
                    <xsl:attribute name="base-alignment" select="'middle'"/>
                    <!-- <xsl:attribute name="stroke" select="'white'"/>
                         <xsl:attribute name="stroke-width" select="'1px'"/> -->
                    <xsl:attribute name="font-size" select="'8px'"/>
                    <xsl:value-of select="key('lines', ., $doc)/short_name"/>   
                </text>
            </xsl:iterate>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>