function Invoke-XmlConfigExpansion {
    <#
    .SYNOPSIS
        Expands environment variables in XML content and returns an XML object.
    
    .DESCRIPTION
        Takes raw XML content, expands all environment variables,
        and returns it as a parsed XML object.
    
    .PARAMETER XmlString
        The raw XML content as a string.
    
    .OUTPUTS
        XML object with expanded environment variables.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$XmlString
    )
    
    process {
        # Expand the environment variables in the string
        $expandedString = [System.Environment]::ExpandEnvironmentVariables($XmlString)
        
        # Cast the expanded string as an XML object for easy access
        [xml]$config = $expandedString
        
        return $config
    }
}
