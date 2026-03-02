BeforeAll {
    # Import the built module
    Import-Module "$PSScriptRoot\..\dist\PSConfigResolver\PSConfigResolver.psd1" -Force
}

Describe "Get-ExpandedConfig" {
    BeforeAll {
        $script:TempConfigTestRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("PSConfigResolver-Tests-" + [guid]::NewGuid().Guid)
        New-Item -ItemType Directory -Path $script:TempConfigTestRoot -Force | Out-Null
    }

    AfterAll {
        if (Test-Path -LiteralPath $script:TempConfigTestRoot) {
            Remove-Item -LiteralPath $script:TempConfigTestRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Parameter Validation" {
        It "should reject non-existent files" {
            { Get-ExpandedConfig -ConfigFilePath "C:\NonExistent\file.json" -ErrorAction Stop } | Should -Throw
        }
        
        It "should reject files without .json or .xml extension" {
            $tempFile = New-TemporaryFile -ErrorAction SilentlyContinue
            if ($tempFile) {
                { Get-ExpandedConfig -ConfigFilePath $tempFile.FullName -ErrorAction Stop } | Should -Throw
                Remove-Item -Path $tempFile.FullName -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    Context "JSON File Processing" {
        It "should read and expand JSON configuration" {
            $config = Get-ExpandedConfig -ConfigFilePath "$PSScriptRoot\..\samples\sample.json"
            $config | Should -Not -BeNullOrEmpty
            $config.AppName | Should -Be "PSConfigResolver"
        }
        
        It "should expand environment variables in nested JSON objects" {
            $config = Get-ExpandedConfig -ConfigFilePath "$PSScriptRoot\..\samples\sample.json"
            $config.Paths.WindowsDirectory | Should -Match "^[A-Za-z]:\\"
            $config.Paths.UserProfile | Should -Be $env:USERPROFILE
        }
        
        It "should expand environment variables in JSON arrays" {
            $config = Get-ExpandedConfig -ConfigFilePath "$PSScriptRoot\..\samples\sample.json"
            $config.Services[1].QueuePath | Should -Match "^[A-Za-z]:\\"
        }

        It "should preserve unexpanded variables in nested JSON values" {
            $config = Get-ExpandedConfig -ConfigFilePath "$PSScriptRoot\..\samples\sample.json"
            $config.Services[0].ApiKey | Should -Match "^%.*%$"
        }

        It "should preserve non-string value types in JSON" {
            $config = Get-ExpandedConfig -ConfigFilePath "$PSScriptRoot\..\samples\sample.json"
            $config.Features.RetryCount | Should -BeOfType [long]
            $config.Features.RetryCount | Should -Be 3
            $config.Features.EnableTelemetry | Should -BeOfType [bool]
            $config.Features.EnableTelemetry | Should -Be $true
        }
    }
    
    Context "XML File Processing" {
        It "should read and expand XML configuration" {
            $config = Get-ExpandedConfig -ConfigFilePath "$PSScriptRoot\..\samples\sample.xml"
            $config | Should -Not -BeNullOrEmpty
            $config -is [xml] | Should -Be $true
        }
    }

        Context "Error Handling" {
                It "should throw for invalid JSON content" {
                        $invalidJsonPath = Join-Path -Path $script:TempConfigTestRoot -ChildPath "invalid.json"
                        Set-Content -Path $invalidJsonPath -Value '{ "Name": "app" "Port": 8080 }' -Encoding utf8

                        { Get-ExpandedConfig -ConfigFilePath $invalidJsonPath -ErrorAction Stop } | Should -Throw
                }

                It "should throw for invalid XML content" {
                        $invalidXmlPath = Join-Path -Path $script:TempConfigTestRoot -ChildPath "invalid.xml"
                        Set-Content -Path $invalidXmlPath -Value '<Config><Name>Broken</Config>' -Encoding utf8

                        { Get-ExpandedConfig -ConfigFilePath $invalidXmlPath -ErrorAction Stop } | Should -Throw
                }

                It "should throw for empty JSON files" {
                        $emptyJsonPath = Join-Path -Path $script:TempConfigTestRoot -ChildPath "empty.json"
                        Set-Content -Path $emptyJsonPath -Value '' -Encoding utf8

                        { Get-ExpandedConfig -ConfigFilePath $emptyJsonPath -ErrorAction Stop } | Should -Throw
                }
        }

        Context "JSON Edge Cases" {
                It "should expand deep nested JSON and preserve null and primitive values" {
                        $deepJsonPath = Join-Path -Path $script:TempConfigTestRoot -ChildPath "deep-nested.json"
                        @'
{
    "Application": {
        "Nodes": [
            {
                "Path": "%TEMP%/node-a"
            },
            {
                "Flag": true,
                "Retries": 5,
                "Optional": null,
                "Inner": {
                    "Profile": "%USERPROFILE%"
                }
            }
        ]
    }
}

Describe "Export-ExpandedConfig" {
    BeforeAll {
        $script:TempExportTestRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("PSConfigResolver-ExportTests-" + [guid]::NewGuid().Guid)
        New-Item -ItemType Directory -Path $script:TempExportTestRoot -Force | Out-Null
    }

    AfterAll {
        if (Test-Path -LiteralPath $script:TempExportTestRoot) {
            Remove-Item -LiteralPath $script:TempExportTestRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "exports JSON config to file" {
        $outputPath = Join-Path -Path $script:TempExportTestRoot -ChildPath "exported.json"
        $config = [pscustomobject]@{
            AppName = 'PSConfigResolver'
            Value   = 'Test'
        }

        { Export-ExpandedConfig -ConfigObject $config -OutputPath $outputPath -Force -ErrorAction Stop } | Should -Not -Throw
        Test-Path -LiteralPath $outputPath | Should -Be $true
    }

    It "warns when built-in sensitive pattern is detected" {
        $outputPath = Join-Path -Path $script:TempExportTestRoot -ChildPath "sensitive.json"
        $config = [pscustomobject]@{
            Username = 'demo'
            Password = 'P@ssw0rd!'
        }

        Export-ExpandedConfig -ConfigObject $config -OutputPath $outputPath -WarningVariable warnings
        ($warnings -join "`n") | Should -Match "potentially sensitive data"
    }

    It "continues with built-in detection when -UsePSSecretScanner is set but scanner is unavailable" {
        $outputPath = Join-Path -Path $script:TempExportTestRoot -ChildPath "scanner-fallback.json"
        $config = [pscustomobject]@{
            api_key = 'test-key'
        }

        Mock -CommandName Get-Command -MockWith { $null } -ParameterFilter { $Name -in @('Find-SecretMatch', 'Find-Secret', 'Find-PSSecret') }

        { Export-ExpandedConfig -ConfigObject $config -OutputPath $outputPath -UsePSSecretScanner -Force -ErrorAction Stop } | Should -Not -Throw
        Test-Path -LiteralPath $outputPath | Should -Be $true
    }
}
'@ | Set-Content -Path $deepJsonPath -Encoding utf8

                        $config = Get-ExpandedConfig -ConfigFilePath $deepJsonPath

                        $config.Application.Nodes[0].Path | Should -Match "^[A-Za-z]:\\"
                        $config.Application.Nodes[1].Inner.Profile | Should -Be $env:USERPROFILE
                        $config.Application.Nodes[1].Flag | Should -BeOfType [bool]
                        $config.Application.Nodes[1].Flag | Should -Be $true
                        $config.Application.Nodes[1].Retries | Should -BeOfType [long]
                        $config.Application.Nodes[1].Retries | Should -Be 5
                        $config.Application.Nodes[1].Optional | Should -Be $null
                }
        }
    
    Context "Test Parameter" {
        It "should accept -Test switch" {
            { Get-ExpandedConfig -ConfigFilePath "$PSScriptRoot\..\samples\sample.json" -Test } | Should -Not -Throw
        }
        
        It "should return config even with -Test parameter" {
            $config = Get-ExpandedConfig -ConfigFilePath "$PSScriptRoot\..\samples\sample.json" -Test
            $config | Should -Not -BeNullOrEmpty
        }

        It "should report nested path for unexpanded variables" {
            $null = Get-ExpandedConfig -ConfigFilePath "$PSScriptRoot\..\samples\sample.json" -Test -WarningVariable warnings
            ($warnings -join "`n") | Should -Match "Services\[0\]\.ApiKey"
        }
    }
    
    Context "Pipeline Support" {
        It "should accept ConfigFilePath via pipeline" {
            $config = "$PSScriptRoot\..\samples\sample.json" | Get-ExpandedConfig
            $config | Should -Not -BeNullOrEmpty
        }
    }
}

