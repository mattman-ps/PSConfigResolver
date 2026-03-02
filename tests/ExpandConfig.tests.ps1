BeforeAll {
    # Import the built module
    Import-Module "$PSScriptRoot\..\dist\PSConfigResolver\PSConfigResolver.psd1" -Force
}

Describe "Get-ExpandedConfig" {
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

