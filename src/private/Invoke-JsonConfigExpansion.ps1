function Invoke-JsonConfigExpansion {
    <#
    .SYNOPSIS
        Expands environment variables in a JSON configuration object.
    
    .DESCRIPTION
        Takes a parsed JSON object and expands all environment variables 
        found in the property values.
    
    .PARAMETER ConfigObject
        The parsed JSON configuration object.
    
    .OUTPUTS
        PSObject with expanded environment variables.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$ConfigObject
    )
    
    process {
        # Expand environment variables in each property value
        $ConfigObject.PSObject.Properties | ForEach-Object {
            $_.Value = [System.Environment]::ExpandEnvironmentVariables($_.Value)
        }
        
        return $ConfigObject
    }
}
