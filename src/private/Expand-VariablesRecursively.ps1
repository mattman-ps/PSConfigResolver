function Expand-VariablesRecursively {
    <#
    .SYNOPSIS
        Recursively expands environment variables in a string.
    
    .DESCRIPTION
        Performs recursive expansion of environment variables. Continues expanding
        until no more variables are found, allowing for nested variable references
        like %TEMP%\%APP_NAME%\config.
    
    .PARAMETER InputString
        The string containing environment variable references to expand.
    
    .PARAMETER MaxIterations
        Maximum number of expansion iterations to prevent infinite loops.
        Default: 10
    
    .OUTPUTS
        String with all environment variables expanded recursively.
    
    .EXAMPLE
        $result = Expand-VariablesRecursively -InputString "%TEMP%\%APP_NAME%"
        # If TEMP=C:\Temp and APP_NAME=MyApp, returns: C:\Temp\MyApp
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputString,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxIterations = 10
    )
    
    process {
        $currentValue = $InputString
        $previousValue = $null
        $iteration = 0
        
        # Pattern to match environment variables
        $pattern = '%[A-Za-z_][A-Za-z0-9_]*%'
        
        while (($currentValue -ne $previousValue) -and ($iteration -lt $MaxIterations)) {
            $previousValue = $currentValue
            $currentValue = [System.Environment]::ExpandEnvironmentVariables($currentValue)
            $iteration++
            
            # Check if there are still variables to expand
            if (-not ($currentValue -match $pattern)) {
                break
            }
        }
        
        return $currentValue
    }
}
