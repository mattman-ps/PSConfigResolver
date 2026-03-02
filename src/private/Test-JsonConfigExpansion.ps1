function Test-JsonConfigExpansion {
    <#
    .SYNOPSIS
        Tests environment variable expansion in a JSON configuration object.
    
    .DESCRIPTION
        Analyzes a JSON configuration object and reports which properties
        have successfully expanded variables and which have unexpanded variables.
    
    .PARAMETER ConfigFilePath
        The path to the JSON file being tested.
    
    .PARAMETER ConfigObject
        The original (unexpanded) JSON configuration object.
    
    .PARAMETER ExpandedObject
        The expanded JSON configuration object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigFilePath,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$ConfigObject,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$ExpandedObject
    )
    
    process {
        function Get-JsonStringNodes {
            param(
                [Parameter(Mandatory = $false)]
                $Value,

                [Parameter(Mandatory = $true)]
                [string]$Path
            )

            if ($null -eq $Value) {
                return @()
            }

            if ($Value -is [string]) {
                return , @{
                    Path = $Path
                    Value = $Value
                }
            }

            if ($Value -is [PSCustomObject]) {
                $results = @()
                foreach ($property in $Value.PSObject.Properties) {
                    $childPath = if ($Path -eq '$') { $property.Name } else { "$Path.$($property.Name)" }
                    $results += Get-JsonStringNodes -Value $property.Value -Path $childPath
                }
                return $results
            }

            if ($Value -is [System.Collections.IDictionary]) {
                $results = @()
                foreach ($key in $Value.Keys) {
                    $childPath = if ($Path -eq '$') { [string]$key } else { "$Path.$key" }
                    $results += Get-JsonStringNodes -Value $Value[$key] -Path $childPath
                }
                return $results
            }

            if ($Value -is [System.Collections.IList]) {
                $results = @()
                for ($i = 0; $i -lt $Value.Count; $i++) {
                    $results += Get-JsonStringNodes -Value $Value[$i] -Path "$Path[$i]"
                }
                return $results
            }

            return @()
        }

        $originalStringNodes = Get-JsonStringNodes -Value $ConfigObject -Path '$'
        $expandedStringNodes = Get-JsonStringNodes -Value $ExpandedObject -Path '$'
        $expandedMap = @{}

        foreach ($node in $expandedStringNodes) {
            $expandedMap[$node.Path] = $node.Value
        }

        $expansionResults = @()

        foreach ($node in $originalStringNodes) {
            $containsVariable = $node.Value -match '%\w+%'
            $expandedValue = if ($expandedMap.ContainsKey($node.Path)) { $expandedMap[$node.Path] } else { $null }
            $unexpanded = $containsVariable -and ($expandedValue -match '%\w+%')

            $result = @{
                PropertyName = $node.Path
                OriginalValue = $node.Value
                ExpandedValue = $expandedValue
                Success = -not $unexpanded
                ContainsVariable = $containsVariable
            }
            $expansionResults += $result

            if ($unexpanded) {
                Write-Warning "Unexpanded variables found in $($node.Path) : $expandedValue"
            }
        }
        
        # Display test results
        Write-Output "`n=== Environment Variable Expansion Test Results ==="
        Write-Output "File: $ConfigFilePath`n"
        
        $successCount = @($expansionResults | Where-Object { $_.Success }).Count
        $failureCount = @($expansionResults | Where-Object { -not $_.Success }).Count
        
        foreach ($result in $expansionResults) {
            $status = if ($result.Success) { "✓ SUCCESS" } else { "✗ FAILED" }
            
            Write-Output "$status - $($result.PropertyName)"
            if (-not $result.Success) {
                Write-Output "  Original:  $($result.OriginalValue)"
                Write-Output "  Expanded:  $($result.ExpandedValue)"
            }
        }
        
        Write-Output "`nSummary: $successCount successful, $failureCount failed"
        Write-Output ""
    }
}
