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
        [string]$ExpandedString
    )
    
    process {
        # Check for unexpanded variables
        $unexpanded = $ExpandedString -match '%\w+%'
        
        $status = if ($unexpanded) { "✗ FAILED" } else { "✓ SUCCESS" }
        
        # Display test results
        Write-Output "`n=== Environment Variable Expansion Test Results ==="
        Write-Output "File: $ConfigFilePath`n"
        Write-Output "$status - XML Content"
        
        if ($unexpanded) {
            Write-Warning "Unexpanded variables found in XML content"
            Write-Output "  Unexpanded pattern found"
        }
        
        Write-Output ""
        Write-Verbose "Summary: $(if ($unexpanded) { '1 failed' } else { '1 successful, 0 failed' })"
    }
}
