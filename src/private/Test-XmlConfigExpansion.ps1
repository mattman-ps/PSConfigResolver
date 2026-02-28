function Test-XmlConfigExpansion {
    <#
    .SYNOPSIS
        Tests environment variable expansion in XML content.
    
    .DESCRIPTION
        Analyzes XML content and reports if all environment variables
        were successfully expanded.
    
    .PARAMETER ConfigFilePath
        The path to the XML file being tested.
    
    .PARAMETER OriginalString
        The original (unexpanded) XML content.
    
    .PARAMETER ExpandedString
        The expanded XML content.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigFilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$OriginalString,
        
        [Parameter(Mandatory = $true)]
        [string]$ExpandedString
    )
    
    process {
        # Check for unexpanded variables
        $unexpanded = $ExpandedString -match '%\w+%'
        
        $status = if ($unexpanded) { "✗ FAILED" } else { "✓ SUCCESS" }
        $statusColor = if ($unexpanded) { "Red" } else { "Green" }
        
        # Display test results
        Write-Host "`n=== Environment Variable Expansion Test Results ===" -ForegroundColor Cyan
        Write-Host "File: $ConfigFilePath`n" -ForegroundColor Gray
        Write-Host "$status - XML Content" -ForegroundColor $statusColor
        
        if ($unexpanded) {
            Write-Warning "Unexpanded variables found in XML content"
            Write-Host "  Unexpanded pattern found" -ForegroundColor Yellow
        }
        
        Write-Host "`nSummary: " -ForegroundColor Cyan -NoNewline
        if ($unexpanded) {
            Write-Host "1 failed" -ForegroundColor Cyan
        } else {
            Write-Host "1 successful, 0 failed" -ForegroundColor Cyan
        }
        Write-Host ""
    }
}
