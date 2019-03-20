<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="2.0"
    xmlns:custom-func="http://www.oxygenxml.com/custom/function"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:dita-ot="http://dita-ot.sourceforge.net/ns/201007/dita-ot"
    exclude-result-prefixes="custom-func xs dita-ot"
  >
  
  <xsl:param name="ditaTempDir"/>
  <xsl:function name="custom-func:getParent" as="xs:string">
    <xsl:param name="sourcePath" as="xs:string"/>
    <xsl:variable name="correctedSourcePath" select="replace($sourcePath, '\\', '/')"/>
    <xsl:value-of select="string-join(tokenize($correctedSourcePath, '/')[position() &lt; last()], '/')"/>
  </xsl:function>
  
  <xsl:function name="custom-func:toURL" as="xs:string">
    <xsl:param name="filepath" as="xs:string"/>
    <xsl:variable name="url" as="xs:string"
      select="if (contains($filepath, '\'))
      then translate($filepath, '\', '/')
      else $filepath
      "
    />
    <xsl:variable name="fileUrl" as="xs:string"
      select="
      if (matches($url, '^[a-zA-Z]:'))
      then concat('file:/', $url)
      else $url
      "
    />
    <xsl:sequence select="$fileUrl"/>
  </xsl:function>
  
  <xsl:function name="custom-func:getAbsolutePath" as="xs:string">
    <xsl:param name="sourcePath" as="xs:string"/>
    <xsl:variable name="pathTokens" select="tokenize($sourcePath, '/')" as="xs:string*"/>
    <xsl:variable name="baseResult" 
      select="string-join(custom-func:makePathAbsolute($pathTokens, ()), '/')" as="xs:string"/>
    <xsl:variable name="baseResult2" 
      select="if (ends-with($baseResult, '/')) 
      then substring($baseResult, 1, string-length($baseResult) -1) 
      else $baseResult" as="xs:string"/>
    <xsl:variable name="result" as="xs:string"
      select="if (starts-with($sourcePath, '/') and not(starts-with($baseResult2, '/')))
      then concat('/', $baseResult2)
      else $baseResult2
      "
    />
    <xsl:value-of select="$result"/>
  </xsl:function>
  
  <xsl:function name="custom-func:getRelativePath" as="xs:string">
    <xsl:param name="source" as="xs:string"/><!-- Path to get relative path *from* -->
    <xsl:param name="target" as="xs:string"/><!-- Path to get relataive path *to* -->
    <xsl:variable name="effectiveSource" as="xs:string"
      select="if (ends-with($source, '/') and string-length($source) > 1) then substring($source, 1, string-length($source) - 1) else $source"
    />
    <xsl:variable name="sourceTokens" select="tokenize((if (starts-with($effectiveSource, '/')) then substring-after($effectiveSource, '/') else $effectiveSource), '/')" as="xs:string*"/>
    <xsl:variable name="targetTokens" select="tokenize((if (starts-with($target, '/')) then substring-after($target, '/') else $target), '/')" as="xs:string*"/>
    <xsl:choose>
      <xsl:when test="(count($sourceTokens) > 0 and count($targetTokens) > 0) and 
        (($sourceTokens[1] != $targetTokens[1]) and 
        (contains($sourceTokens[1], ':') or contains($targetTokens[1], ':')))">
        <!-- Must be absolute URLs with different schemes, cannot be relative, return
        target as is. -->
        <xsl:value-of select="$target"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="resultTokens" 
          select="custom-func:analyzePathTokens($sourceTokens, $targetTokens, ())" as="xs:string*"/>              
        <xsl:variable name="result" select="string-join($resultTokens, '/')" as="xs:string"/>
        <xsl:value-of select="$result"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="custom-func:analyzePathTokens" as="xs:string*">
    <xsl:param name="sourceTokens" as="xs:string*"/>
    <xsl:param name="targetTokens" as="xs:string*"/>
    <xsl:param name="resultTokens" as="xs:string*"/>
    <xsl:choose>
      <xsl:when test="count($sourceTokens) = 0">
        <!-- Append remaining target tokens (if any) to the result -->
        <xsl:sequence select="$resultTokens, $targetTokens"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- Still source tokens, so see if source[1] = target[1] -->
        <xsl:choose>
          <!-- If they are equal, go to the next level in the paths: -->
          <xsl:when test="(count($targetTokens) > 0) and ($sourceTokens[1] = $targetTokens[1])">
            <xsl:sequence select="custom-func:analyzePathTokens($sourceTokens[position() > 1], $targetTokens[position() > 1], $resultTokens)"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- Paths must diverge at this point. Append one ".." for each token
            left in the source: -->
            <xsl:variable name="goUps" as="xs:string*">
              <xsl:for-each select="$sourceTokens">
                <xsl:sequence select="'..'"/>
              </xsl:for-each>
            </xsl:variable>
            <xsl:sequence select="string-join(($resultTokens, $goUps, $targetTokens), '/')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>    
  </xsl:function>
  
  <xsl:function name="custom-func:makePathAbsolute" as="xs:string*">
    <xsl:param name="pathTokens" as="xs:string*"/>
    <xsl:param name="resultTokens" as="xs:string*"/>
    <xsl:sequence select="if (count($pathTokens) = 0)
      then $resultTokens
      else if ($pathTokens[1] = '.')
      then custom-func:makePathAbsolute($pathTokens[position() > 1], $resultTokens)
      else if ($pathTokens[1] = '..')
      then custom-func:makePathAbsolute($pathTokens[position() > 1], $resultTokens[position() &lt; last()])
      else custom-func:makePathAbsolute($pathTokens[position() > 1], ($resultTokens, $pathTokens[1]))
      "/>
  </xsl:function>
  
  <xsl:template match="*[contains(@class, ' topic/image ')][ends-with(@href, '.mml') or ends-with(@href, '.mathml')][not(@scope = 'external')]">
    <xsl:variable name="job" select="document(resolve-uri('.job.xml', custom-func:toURL(concat($ditaTempDir, '/'))))" as="document-node()?"/>
    <xsl:variable name="xmlRelativeToBase" select="custom-func:getRelativePath(custom-func:toURL(concat($ditaTempDir, '/')), base-uri())"/>
    <xsl:variable name="xmlOriginalLocation" select="$job//file[@uri=$xmlRelativeToBase]/@src" as="xs:string"/>
    <xsl:variable name="imageOriginalLocation" select="custom-func:getAbsolutePath(concat(custom-func:getParent($xmlOriginalLocation), '/', @href))"/>
    <xsl:choose>
      <xsl:when test="doc-available($imageOriginalLocation)">
        <xsl:copy-of select="document($imageOriginalLocation)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="*[contains(@class, ' topic/image ')][ends-with(@href, '.svg') and (contains(@outputclass, 'embed'))][not(@scope = 'external')]">
    <object type="image/svg+xml" data="{@href}" xmlns="http://www.w3.org/1999/xhtml">
      <xsl:if test="@scale">
        <xsl:variable name="width" select="@dita-ot:image-width"/>
        <xsl:variable name="height" select="@dita-ot:image-height"/>
        <xsl:if test="not(@width) and not(@height)">
          <xsl:attribute name="height" select="custom-func:scaleDimension($height, @scale)"/>
          <xsl:attribute name="width" select="custom-func:scaleDimension($width, @scale)"/>
        </xsl:if>
      </xsl:if>
    </object>
  </xsl:template>
  
  <xsl:function name="custom-func:scaleDimension" as="xs:string">
    <xsl:param name="dimension"/>
    <xsl:param name="scale"/>
    <xsl:variable name="dimensionNumber">
      <xsl:choose>
        <xsl:when test="custom-func:hasMeasuringUnit($dimension)">
          <xsl:value-of select="substring($dimension, 0, string-length($dimension) - 2)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$dimension"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="dimensionMeasuringUnit">
      <xsl:choose>
        <xsl:when test="custom-func:hasMeasuringUnit($dimension)">
          <xsl:value-of select="substring($dimension, string-length($dimension) - 1)"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="concat(floor((number($dimensionNumber) * number($scale)) div 100), $dimensionMeasuringUnit)"/>
  </xsl:function>
  
  <xsl:function name="custom-func:hasMeasuringUnit" as="xs:boolean">
    <xsl:param name="dimension"/>
    <xsl:value-of select="ends-with($dimension, 'mm') or ends-with($dimension, 'cm') 
      or ends-with($dimension, 'em') or ends-with($dimension, 'ex') or ends-with($dimension, 'px')"/>
  </xsl:function>
</xsl:stylesheet>