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
            $config.Name | Should -Be $env:USERNAME
        }
        
        It "should expand environment variables in JSON" {
            $config = Get-ExpandedConfig -ConfigFilePath "$PSScriptRoot\..\samples\sample.json"
            $config.WinDir | Should -Match "^[A-Za-z]:\\"
        }
        
        It "should preserve unexpanded variables in JSON" {
            $config = Get-ExpandedConfig -ConfigFilePath "$PSScriptRoot\..\samples\sample.json"
            $config.OldUserName | Should -Match "^%.*%$"
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
    }
    
    Context "Pipeline Support" {
        It "should accept ConfigFilePath via pipeline" {
            $config = "$PSScriptRoot\..\samples\sample.json" | Get-ExpandedConfig
            $config | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Invoke-ReadConfig" {
    Context "Parameter Validation" {
        It "should reject non-existent files" {
            { Invoke-ReadConfig -ConfigFilePath "C:\NonExistent\file.json" -ErrorAction Stop } | Should -Throw
        }
        
        It "should reject files without .json or .xml extension" {
            $tempFile = New-TemporaryFile -ErrorAction SilentlyContinue
            if ($tempFile) {
                { Invoke-ReadConfig -ConfigFilePath $tempFile.FullName -ErrorAction Stop } | Should -Throw
                Remove-Item -Path $tempFile.FullName -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    Context "JSON File Processing" {
        It "should read and expand JSON configuration" {
            $config = Invoke-ReadConfig -ConfigFilePath "$PSScriptRoot\..\samples\sample.json"
            $config | Should -Not -BeNullOrEmpty
            $config.Name | Should -Be $env:USERNAME
        }
        
        It "should expand environment variables in JSON" {
            $config = Invoke-ReadConfig -ConfigFilePath "$PSScriptRoot\..\samples\sample.json"
            $config.WinDir | Should -Match "^[A-Za-z]:\\"
        }
        
        It "should preserve unexpanded variables in JSON" {
            $config = Invoke-ReadConfig -ConfigFilePath "$PSScriptRoot\..\samples\sample.json"
            $config.OldUserName | Should -Match "^%.*%$"
        }
    }
    
    Context "XML File Processing" {
        It "should read and expand XML configuration" {
            $config = Invoke-ReadConfig -ConfigFilePath "$PSScriptRoot\..\samples\sample.xml"
            $config | Should -Not -BeNullOrEmpty
            $config -is [xml] | Should -Be $true
        }
    }
    
    Context "Test Parameter" {
        It "should accept -Test switch" {
            { Invoke-ReadConfig -ConfigFilePath "$PSScriptRoot\..\samples\sample.json" -Test } | Should -Not -Throw
        }
        
        It "should return config even with -Test parameter" {
            $config = Invoke-ReadConfig -ConfigFilePath "$PSScriptRoot\..\samples\sample.json" -Test
            $config | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Pipeline Support" {
        It "should accept ConfigFilePath via pipeline" {
            $config = "$PSScriptRoot\..\samples\sample.json" | Invoke-ReadConfig
            $config | Should -Not -BeNullOrEmpty
        }
    }
}
