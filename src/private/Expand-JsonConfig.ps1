function Expand-JsonConfig {
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
        function Expand-JsonValue {
            param(
                [Parameter(Mandatory = $false)]
                $Value
            )

            if ($null -eq $Value) {
                return $null
            }

            if ($Value -is [string]) {
                return Expand-VariablesRecursively -InputString $Value
            }

            if ($Value -is [PSCustomObject]) {
                $Value.PSObject.Properties | ForEach-Object {
                    $_.Value = Expand-JsonValue -Value $_.Value
                }
                return $Value
            }

            if ($Value -is [System.Collections.IDictionary]) {
                foreach ($key in @($Value.Keys)) {
                    $Value[$key] = Expand-JsonValue -Value $Value[$key]
                }
                return $Value
            }

            if ($Value -is [System.Collections.IList]) {
                for ($i = 0; $i -lt $Value.Count; $i++) {
                    $Value[$i] = Expand-JsonValue -Value $Value[$i]
                }
                return $Value
            }

            return $Value
        }

        return Expand-JsonValue -Value $ConfigObject
    }
}
