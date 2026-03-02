#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build automation script for PSConfigResolver module.

.DESCRIPTION
    Automates the complete build pipeline including:
    - Module building
    - Code analysis (PSScriptAnalyzer)
    - Testing (Pester)
    - Packaging

.PARAMETER Task
    The build task to execute. Options: Build, Test, Analyze, Package, All, Clean
    Default: All

.PARAMETER Configuration
    Build configuration. Options: Debug, Release. Default: Release

.PARAMETER OutputPath
    Path for build output. Default: ./dist

.PARAMETER Verbose
    Enable verbose output.

.PARAMETER SkipTest
    Skip running tests.

.PARAMETER SkipAnalysis
    Skip running code analysis.

.PARAMETER ExitOnError
    Exit with code 1 if any step fails.

.EXAMPLE
    .\build.ps1 -Task Build
    Builds the module only.

.EXAMPLE
    .\build.ps1 -Task All -Configuration Release
    Runs complete build pipeline in Release mode.

.EXAMPLE
    .\build.ps1 -Task Clean
    Removes all build artifacts.

.EXAMPLE
    .\build.ps1 -SkipTest -ExitOnError
    Runs full build skipping tests and exits on any error.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateSet('Build', 'Test', 'Analyze', 'Package', 'All', 'Clean')]
    [string]$Task = 'All',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = './dist',

    [Parameter(Mandatory = $false)]
    [switch]$SkipTest,

    [Parameter(Mandatory = $false)]
    [switch]$SkipAnalysis,

    [Parameter(Mandatory = $false)]
    [switch]$ExitOnError
)

# Set strict error handling
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Global state
$script:BuildSuccess = $true
$script:StartTime = Get-Date
$script:ProjectRoot = $PSScriptRoot
$script:ProjectName = 'PSConfigResolver'

<#
.SYNOPSIS
    Write status message with formatting.
#>
function Write-BuildLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'HH:mm:ss'
    $color = @{
        Info    = 'Cyan'
        Success = 'Green'
        Warning = 'Yellow'
        Error   = 'Red'
    }[$Level]

    $prefix = @{
        Info    = '[INFO]'
        Success = '[✓]'
        Warning = '[!]'
        Error   = '[✗]'
    }[$Level]

    Write-Host "$timestamp $prefix $Message" -ForegroundColor $color
}

<#
.SYNOPSIS
    Check if required modules are installed.
#>
function Test-RequiredModules {
    Write-BuildLog "Checking required modules..." -Level Info

    $requiredModules = @(
        'ModuleTools',
        'Pester',
        'PSScriptAnalyzer'
    )

    foreach ($module in $requiredModules) {
        if (-not (Get-Module -Name $module -ListAvailable)) {
            Write-BuildLog "Installing $module..." -Level Warning
            Install-Module -Name $module -Force -SkipPublisherCheck -Scope CurrentUser -ErrorAction Stop
        }
    }

    Write-BuildLog "All required modules available" -Level Success
}

<#
.SYNOPSIS
    Clean build artifacts.
#>
function Invoke-Clean {
    Write-BuildLog "Cleaning build artifacts..." -Level Info

    try {
        if (Test-Path -LiteralPath $OutputPath) {
            Remove-Item -LiteralPath $OutputPath -Recurse -Force
            Write-BuildLog "Removed: $OutputPath" -Level Success
        }

        # Clean other artifacts
        $artifactPaths = @(
            'results/analysis.xml',
            'results/test-results.xml',
            'results/'
        )

        foreach ($path in $artifactPaths) {
            $fullPath = Join-Path -Path $ProjectRoot -ChildPath $path
            if (Test-Path -LiteralPath $fullPath) {
                Remove-Item -LiteralPath $fullPath -Recurse -Force
                Write-BuildLog "Removed: $path" -Level Success
            }
        }

        Write-BuildLog "Clean complete" -Level Success
    }
    catch {
        Write-BuildLog "Clean failed: $_" -Level Error
        $script:BuildSuccess = $false
        if ($ExitOnError) { exit 1 }
    }
}

<#
.SYNOPSIS
    Build the module.
#>
function Invoke-Build {
    Write-BuildLog "Building module..." -Level Info

    try {
        # Import ModuleTools
        Import-Module ModuleTools -Force

        # Run build
        $buildParams = @{
            Verbose = $VerbosePreference -eq 'Continue'
        }

        Invoke-MTBuild @buildParams
        Write-BuildLog "Module build successful" -Level Success
    }
    catch {
        Write-BuildLog "Build failed: $_" -Level Error
        $script:BuildSuccess = $false
        if ($ExitOnError) { exit 1 }
    }
}

<#
.SYNOPSIS
    Run code analysis.
#>
function Invoke-StaticAnalysis {
    if ($SkipAnalysis) {
        Write-BuildLog "Code analysis skipped (per user request)" -Level Warning
        return
    }

    Write-BuildLog "Running code analysis..." -Level Info

    try {
        # Create results directory
        $resultsPath = Join-Path -Path $ProjectRoot -ChildPath 'results'
        if (-not (Test-Path -LiteralPath $resultsPath)) {
            New-Item -ItemType Directory -Path $resultsPath -Force | Out-Null
        }

        $reportPath = Join-Path -Path $resultsPath -ChildPath 'analysis.xml'

        # Run analysis
        & "$ProjectRoot\Invoke-Analysis.ps1" -Path 'src' -ReportPath $reportPath

        Write-BuildLog "Code analysis complete. Report: $reportPath" -Level Success
    }
    catch {
        Write-BuildLog "Code analysis failed: $_" -Level Warning
        # Don't fail build on analysis issues
    }
}

<#
.SYNOPSIS
    Run Pester tests.
#>
function Invoke-Tests {
    if ($SkipTest) {
        Write-BuildLog "Tests skipped (per user request)" -Level Warning
        return
    }

    Write-BuildLog "Running tests..." -Level Info

    try {
        # Import Pester
        Import-Module Pester -Force

        # Create results directory
        $resultsPath = Join-Path -Path $ProjectRoot -ChildPath 'results'
        if (-not (Test-Path -LiteralPath $resultsPath)) {
            New-Item -ItemType Directory -Path $resultsPath -Force | Out-Null
        }

        # Configure Pester
        $pesterConfig = New-PesterConfiguration
        $pesterConfig.Run.Path = 'tests'
        $pesterConfig.Run.Exit = $false
        $pesterConfig.CodeCoverage.Enabled = $false
        $pesterConfig.Output.Verbosity = 'Detailed'
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputPath = Join-Path -Path $resultsPath -ChildPath 'test-results.xml'

        # Run tests
        $testResults = Invoke-Pester -Configuration $pesterConfig

        # Check results
        if ($testResults.FailedCount -gt 0) {
            Write-BuildLog "Tests failed: $($testResults.FailedCount) failures" -Level Error
            $script:BuildSuccess = $false
            if ($ExitOnError) { exit 1 }
        }
        else {
            Write-BuildLog "All tests passed ($($testResults.PassedCount) tests)" -Level Success
        }
    }
    catch {
        Write-BuildLog "Test execution failed: $_" -Level Error
        $script:BuildSuccess = $false
        if ($ExitOnError) { exit 1 }
    }
}

<#
.SYNOPSIS
    Package the built module.
#>
function Invoke-Package {
    Write-BuildLog "Packaging module..." -Level Info

    try {
        $modulePath = Join-Path -Path $OutputPath -ChildPath $ProjectName
        
        if (-not (Test-Path -LiteralPath $modulePath)) {
            Write-BuildLog "Module path not found: $modulePath" -Level Error
            $script:BuildSuccess = $false
            if ($ExitOnError) { exit 1 }
            return
        }

        # Get module version from manifest
        $manifestPath = Join-Path -Path $modulePath -ChildPath "$ProjectName.psd1"
        $manifest = Import-PowerShellDataFile -Path $manifestPath
        $version = $manifest.ModuleVersion

        # Create package directory
        $packagePath = Join-Path -Path $OutputPath -ChildPath "packages"
        if (-not (Test-Path -LiteralPath $packagePath)) {
            New-Item -ItemType Directory -Path $packagePath -Force | Out-Null
        }

        # Create package archive
        $packageName = "$ProjectName-$version.zip"
        $packageFile = Join-Path -Path $packagePath -ChildPath $packageName

        if (Test-Path -LiteralPath $packageFile) {
            Remove-Item -LiteralPath $packageFile -Force
        }

        # Compress module
        Compress-Archive -Path $modulePath -DestinationPath $packageFile -Force

        Write-BuildLog "Package created: $packageFile" -Level Success
    }
    catch {
        Write-BuildLog "Packaging failed: $_" -Level Error
        $script:BuildSuccess = $false
        if ($ExitOnError) { exit 1 }
    }
}

<#
.SYNOPSIS
    Print build summary.
#>
function Write-BuildSummary {
    $duration = ((Get-Date) - $script:StartTime).TotalSeconds

    Write-Host "`n"
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host "BUILD SUMMARY" -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Cyan

    Write-BuildLog "Configuration: $Configuration" -Level Info
    Write-BuildLog "Task: $Task" -Level Info
    Write-BuildLog "Duration: $([math]::Round($duration, 2))s" -Level Info

    if ($script:BuildSuccess) {
        Write-BuildLog "Build Status: SUCCESS" -Level Success
        Write-Host ("=" * 80) -ForegroundColor Green
        return 0
    }
    else {
        Write-BuildLog "Build Status: FAILED" -Level Error
        Write-Host ("=" * 80) -ForegroundColor Red
        return 1
    }
}

# ============================================================================
# Main Build Logic
# ============================================================================

try {
    Write-Host ""
    Write-BuildLog "$ProjectName Build Automation Script" -Level Info
    Write-BuildLog "Task: $Task | Configuration: $Configuration" -Level Info
    Write-Host ""

    # Check required modules
    Test-RequiredModules

    # Execute tasks
    switch ($Task) {
        'Clean' {
            Invoke-Clean
        }
        'Build' {
            Invoke-Build
        }
        'Analyze' {
            Invoke-StaticAnalysis
        }
        'Test' {
            Invoke-Tests
        }
        'Package' {
            if (-not (Test-Path -LiteralPath $OutputPath)) {
                Write-BuildLog "Build artifacts not found. Running Build task first..." -Level Warning
                Invoke-Build
            }
            Invoke-Package
        }
        'All' {
            Invoke-Build
            Invoke-StaticAnalysis
            Invoke-Tests
            Invoke-Package
        }
    }

    # Write summary and exit
    $exitCode = Write-BuildSummary
    exit $exitCode
}
catch {
    Write-BuildLog "Unexpected error: $_" -Level Error
    Write-BuildLog "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
}
