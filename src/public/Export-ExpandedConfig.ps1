function Export-ExpandedConfig {
    <#
    .SYNOPSIS
        Exports an expanded configuration to a JSON or XML file.
    
    .DESCRIPTION
        Exports an expanded configuration object to a file. Detects potentially
        sensitive data (API keys, passwords, secrets) and displays a warning
        before exporting. Use -Force to skip the warning.
    
    .PARAMETER ConfigObject
        The configuration object to export (can be PSObject for JSON or XML element)
    
    .PARAMETER OutputPath
        Path where the expanded configuration will be saved
    
    .PARAMETER Format
        Output format: 'Json' or 'Xml'. Auto-detected from OutputPath extension if not specified.
    
    .PARAMETER Force
        Skip sensitive data warning and export without confirmation

    .PARAMETER UsePSSecretScanner
        Use PSSecretScanner (if installed) to detect sensitive data before export.
        Falls back to built-in pattern checks when the module is unavailable.
    
    .OUTPUTS
        None. Creates file at OutputPath.
    
    .EXAMPLE
        $config = Get-ExpandedConfig -ConfigFilePath ".\config.json"
        Export-ExpandedConfig -ConfigObject $config -OutputPath ".\exported.json"
    
    .EXAMPLE
        Export-ExpandedConfig -ConfigObject $config -OutputPath ".\exported.json" -Force

    .EXAMPLE
        Export-ExpandedConfig -ConfigObject $config -OutputPath ".\exported.json" -UsePSSecretScanner
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Object]$ConfigObject,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Json', 'Xml')]
        [string]$Format,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$UsePSSecretScanner
    )
    
    process {
        try {
            # Determine format from OutputPath if not specified
            if (-not $Format) {
                $extension = [System.IO.Path]::GetExtension($OutputPath).ToLower()
                switch ($extension) {
                    '.json' { $Format = 'Json' }
                    '.xml' { $Format = 'Xml' }
                    default {
                        throw "Could not determine format from extension '$extension'. Specify -Format parameter."
                    }
                }
            }
            
            # Convert to string for sensitive data detection
            $configString = if ($Format -eq 'Json') {
                $ConfigObject | ConvertTo-Json -Depth 10
            }
            else {
                $ConfigObject.OuterXml
            }
            
            $sensitivePatterns = @(
                @{ Pattern = 'apikey|api_key'; Name = 'API Key' }
                @{ Pattern = 'password|passwd|pwd'; Name = 'Password' }
                @{ Pattern = 'secret|secret_key'; Name = 'Secret' }
                @{ Pattern = 'token|auth.*token'; Name = 'Token' }
                @{ Pattern = 'credential|auth'; Name = 'Credential' }
                @{ Pattern = 'key|private.*key'; Name = 'Private Key' }
            )

            $foundSensitive = @()
            foreach ($patternObj in $sensitivePatterns) {
                if ($configString -match $patternObj.Pattern) {
                    $foundSensitive += $patternObj.Name
                }
            }

            if ($UsePSSecretScanner) {
                $scannerCommand = $null
                foreach ($candidate in @('Find-SecretMatch', 'Find-Secret', 'Find-PSSecret')) {
                    $scannerCommand = Get-Command -Name $candidate -ErrorAction SilentlyContinue
                    if ($scannerCommand) {
                        break
                    }
                }

                if ($scannerCommand) {
                    $tempScanFile = [System.IO.Path]::GetTempFileName()
                    try {
                        Set-Content -LiteralPath $tempScanFile -Value $configString -Encoding UTF8
                        $commandParameters = @{}
                        if ($scannerCommand.Parameters.ContainsKey('Path')) {
                            $commandParameters.Path = $tempScanFile
                        }
                        elseif ($scannerCommand.Parameters.ContainsKey('LiteralPath')) {
                            $commandParameters.LiteralPath = $tempScanFile
                        }
                        elseif ($scannerCommand.Parameters.ContainsKey('FilePath')) {
                            $commandParameters.FilePath = $tempScanFile
                        }

                        if ($commandParameters.Count -eq 0) {
                            Write-Warning "PSSecretScanner command '$($scannerCommand.Name)' does not expose a supported path parameter."
                        }
                        else {
                            $scanResults = & $scannerCommand @commandParameters
                            if ($scanResults) {
                                $foundSensitive += 'PSSecretScanner Findings'
                            }
                        }
                    }
                    catch {
                        Write-Warning "PSSecretScanner scan failed: $($_.Exception.Message)"
                    }
                    finally {
                        if (Test-Path -LiteralPath $tempScanFile) {
                            Remove-Item -LiteralPath $tempScanFile -Force -ErrorAction SilentlyContinue
                        }
                    }
                }
                else {
                    Write-Warning "-UsePSSecretScanner was specified, but no PSSecretScanner command was found. Run: Install-Module PSSecretScanner"
                }
            }
            
            # Warn about sensitive data
            if ($foundSensitive.Count -gt 0 -and -not $Force) {
                $sensitiveList = $foundSensitive | Select-Object -Unique
                Write-Warning "Configuration contains potentially sensitive data: $($sensitiveList -join ', ')"
                Write-Warning "Exporting this configuration may expose sensitive information."
                
                if (-not $PSCmdlet.ShouldProcess($OutputPath, "Export configuration with sensitive data")) {
                    Write-Verbose "Export cancelled by user"
                    return
                }
            }
            
            # Create output directory if it doesn't exist
            $outputDir = Split-Path -Parent $OutputPath
            if (-not (Test-Path -LiteralPath $outputDir)) {
                New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
            }
            
            # Export the configuration
            if ($Format -eq 'Json') {
                $configString | Out-File -LiteralPath $OutputPath -Encoding UTF8 -Force
            }
            else {
                $configString | Out-File -LiteralPath $OutputPath -Encoding UTF8 -Force
            }
            
            Write-Verbose "Configuration exported to: $OutputPath"
            
            if ($foundSensitive.Count -gt 0 -and -not $Force) {
                Write-Warning "Sensitive data has been exported to: $OutputPath"
                Write-Warning "Ensure this file is stored securely."
            }
        }
        catch {
            Write-Error "Failed to export configuration: $_"
            throw
        }
    }
}
