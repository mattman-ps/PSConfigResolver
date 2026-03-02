function Test-EnvironmentVariables {
    <#
    .SYNOPSIS
        Tests that environment variables referenced in configuration exist.
    
    .DESCRIPTION
        Scans configuration content for environment variable references (matching %VARNAME% pattern)
        and validates whether each referenced variable exists. Warns about undefined variables.
    
    .PARAMETER ConfigContent
        The raw configuration content (string) to scan for environment variable references.
    
    .PARAMETER ConfigFilePath
        Optional path to the configuration file, used in warning messages.
    
    .OUTPUTS
        PSObject with validation results containing:
        - ReferencedVariables: All found environment variable references
        - DefinedVariables: Variables that exist in the environment
        - UndefinedVariables: Variables that do not exist
        - IsValid: Boolean indicating if all variables are defined
    
    .EXAMPLE
        $result = Validate-EnvironmentVariables -ConfigContent $jsonString -ConfigFilePath "config.json"
        if (-not $result.IsValid) {
            Write-Warning "Found undefined variables: $($result.UndefinedVariables -join ', ')"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigContent,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigFilePath
    )
    
    process {
        # Pattern to match environment variables: %VARNAME%
        $pattern = '%([A-Za-z_][A-Za-z0-9_]*)%'
        
        # Find all environment variable references in the content
        $varMatches = [regex]::Matches($ConfigContent, $pattern)
        $referencedVars = @()
        $definedVars = @()
        $undefinedVars = @()
        
        if ($varMatches.Count -gt 0) {
            # Get unique variable names
            $varNames = $varMatches.Groups | Where-Object { $_.Name -eq '1' } | Select-Object -ExpandProperty Value -Unique
            
            foreach ($varName in $varNames) {
                $referencedVars += $varName
                
                # Check if the environment variable exists
                $envValue = [System.Environment]::GetEnvironmentVariable($varName)
                
                if ($null -ne $envValue) {
                    $definedVars += $varName
                }
                else {
                    $undefinedVars += $varName
                    
                    # Warn about undefined variable
                    $warningMessage = "Environment variable '%$varName%' is referenced in configuration but is not defined"
                    if ($ConfigFilePath) {
                        $warningMessage += " (file: $ConfigFilePath)"
                    }
                    Write-Warning $warningMessage
                }
            }
        }
        
        # Return validation results
        return [PSObject]@{
            ReferencedVariables = $referencedVars | Sort-Object -Unique
            DefinedVariables = $definedVars | Sort-Object -Unique
            UndefinedVariables = $undefinedVars | Sort-Object -Unique
            IsValid = $undefinedVars.Count -eq 0
        }
    }
}
