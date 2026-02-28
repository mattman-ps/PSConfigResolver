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
        $expansionResults = @()
        
        # Compare original and expanded values
        $ConfigObject.PSObject.Properties | ForEach-Object {
            $propertyName = $_.Name
            $originalValue = $_.Value
            $expandedValue = $ExpandedObject.$propertyName
            
            $unexpanded = $expandedValue -match '%\w+%'
            $result = @{
                PropertyName = $propertyName
                OriginalValue = $originalValue
                ExpandedValue = $expandedValue
                Success = -not $unexpanded
            }
            $expansionResults += $result
            
            if ($unexpanded) {
                Write-Warning "Unexpanded variables found in $propertyName : $expandedValue"
            }
        }
        
        # Display test results
        Write-Host "`n=== Environment Variable Expansion Test Results ===" -ForegroundColor Cyan
        Write-Host "File: $ConfigFilePath`n" -ForegroundColor Gray
        
        $successCount = ($expansionResults | Where-Object { $_.Success }).Count
        $failureCount = ($expansionResults | Where-Object { -not $_.Success }).Count
        
        foreach ($result in $expansionResults) {
            $statusColor = if ($result.Success) { "Green" } else { "Red" }
            $status = if ($result.Success) { "✓ SUCCESS" } else { "✗ FAILED" }
            
            Write-Host "$status - $($result.PropertyName)" -ForegroundColor $statusColor
            if (-not $result.Success) {
                Write-Host "  Original:  $($result.OriginalValue)" -ForegroundColor Yellow
                Write-Host "  Expanded:  $($result.ExpandedValue)" -ForegroundColor Yellow
            }
        }
        
        Write-Host "`nSummary: $successCount successful, $failureCount failed" -ForegroundColor Cyan
        Write-Host ""
    }
}
