#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Runs PSScriptAnalyzer against the module code.

.DESCRIPTION
    Invokes PSScriptAnalyzer to perform static code analysis on the PowerShell
    module code. Uses the .PSScriptAnalyzerSettings.psd1 configuration file.

.PARAMETER Path
    Path to analyze. Defaults to 'src'.

.PARAMETER ReportPath
    Optional path to save the analysis report as XML. If not specified, results
    are displayed in the console.

.PARAMETER ExitOnError
    If specified, the script will exit with code 1 if any issues are found.

.EXAMPLE
    .\Invoke-Analysis.ps1

.EXAMPLE
    .\Invoke-Analysis.ps1 -Path src -ReportPath results/analysis.xml

.EXAMPLE
    .\Invoke-Analysis.ps1 -ExitOnError
#>
param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({
        if (-not (Test-Path -LiteralPath $_)) {
            throw "Path '$_' does not exist."
        }
        return $true
    })]
    [string]$Path = 'src',

    [Parameter(Mandatory = $false)]
    [string]$ReportPath,

    [Parameter(Mandatory = $false)]
    [switch]$ExitOnError
)

# Ensure PSScriptAnalyzer is installed
if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
    Write-Host "Installing PSScriptAnalyzer..." -ForegroundColor Yellow
    Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck -AllowClobber -Scope CurrentUser -Confirm:$false
}

# Import PSScriptAnalyzer
Import-Module PSScriptAnalyzer -Force

# Get configuration file path
$configPath = Join-Path -Path $PSScriptRoot -ChildPath '.PSScriptAnalyzerSettings.psd1'

if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Error "Configuration file not found at $configPath"
    exit 1
}

Write-Host "Running PSScriptAnalyzer..." -ForegroundColor Cyan
Write-Host "Path: $Path" -ForegroundColor Gray
Write-Host "Config: $configPath" -ForegroundColor Gray

# Run analysis
$analysisParams = @{
    Path       = $Path
    Settings   = $configPath
    Recurse    = $true
    ErrorAction = 'Continue'
}

$results = Invoke-ScriptAnalyzer @analysisParams

# Display results
if ($results) {
    Write-Host "`nAnalysis Results:" -ForegroundColor Yellow
    Write-Host ("=" * 80)

    $results | Group-Object -Property RuleName | ForEach-Object {
        Write-Host "`n[$($_.Group[0].Severity)] $($_.Name)" -ForegroundColor $(
            if ($_.Group[0].Severity -eq 'Error') { 'Red' }
            elseif ($_.Group[0].Severity -eq 'Warning') { 'Yellow' }
            else { 'Cyan' }
        )

        $_.Group | ForEach-Object {
            Write-Host "  File: $($_.ScriptPath):$($_.Line)" -ForegroundColor Gray
            Write-Host "  Issue: $($_.Message)" -ForegroundColor Gray
        }
    }

    Write-Host "`n" + ("=" * 80)
    Write-Host "Total Issues Found: $($results.Count)" -ForegroundColor Yellow

    # Save report if requested
    if ($ReportPath) {
        $reportDir = Split-Path -Parent $ReportPath
        if (-not (Test-Path -LiteralPath $reportDir)) {
            New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
        }

        $results | Export-Clixml -Path $ReportPath -Encoding UTF8
        Write-Host "Report saved to: $ReportPath" -ForegroundColor Green
    }

    # Exit with error code if requested
    if ($ExitOnError) {
        exit 1
    }
}
else {
    Write-Host "✓ No issues found!" -ForegroundColor Green
    exit 0
}
