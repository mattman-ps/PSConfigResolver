BeforeAll {
    # Import the main function
    . "$PSScriptRoot\..\src\public\Get-ExpandedConfig.ps1"
    . "$PSScriptRoot\..\src\private\Expand-JsonConfig.ps1"
    . "$PSScriptRoot\..\src\private\Expand-XmlConfig.ps1"
}

Describe "Get-ExpandedConfig" {
    Context "Parameter Validation" {
        It "should require ConfigFilePath parameter" {
            { Get-ExpandedConfig -ErrorAction Stop } | Should -Throw
        }
        
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
            $config = Get-ExpandedConfig -ConfigFilePath "$PSScriptRoot\..\sample\sample.json"
            $config | Should -Not -BeNullOrEmpty
            $config.Name | Should -Be "mattman-ps"
        }
        
        It "should expand environment variables in JSON" {
            $config = Get-ExpandedConfig -ConfigFilePath "$PSScriptRoot\..\sample\sample.json"
            $config.WinDir | Should -Match "^[A-Za-z]:\\"
        }
        
        It "should preserve unexpanded variables in JSON" {
            $config = Get-ExpandedConfig -ConfigFilePath "$PSScriptRoot\..\sample\sample.json"
            $config.OldUserName | Should -Match "^%.*%$"
        }
    }
    
    Context "XML File Processing" {
        It "should read and expand XML configuration" {
            $config = Get-ExpandedConfig -ConfigFilePath "$PSScriptRoot\..\sample\sample.xml"
            $config | Should -Not -BeNullOrEmpty
            $config -is [xml] | Should -Be $true
        }
    }
    
    Context "Test Parameter" {
        It "should accept -Test switch" {
            { Get-ExpandedConfig -ConfigFilePath "$PSScriptRoot\..\sample\sample.json" -Test } | Should -Not -Throw
        }
        
        It "should return config even with -Test parameter" {
            $config = Get-ExpandedConfig -ConfigFilePath "$PSScriptRoot\..\sample\sample.json" -Test
            $config | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Pipeline Support" {
        It "should accept ConfigFilePath via pipeline" {
            $config = "$PSScriptRoot\..\sample\sample.json" | Get-ExpandedConfig
            $config | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Expand-JsonConfig" {
    Context "JSON Expansion" {
        It "should expand environment variables" {
            $testConfig = [PSCustomObject]@{
                TestWin = "%WINDIR%"
            }
            
            $expanded = Expand-JsonConfig -ConfigObject $testConfig
            $expanded.TestWin | Should -Match "^[A-Za-z]:\\"
        }
        
        It "should handle already expanded values" {
            $testConfig = [PSCustomObject]@{
                StaticValue = "C:\fixed\path"
            }
            
            $expanded = Expand-JsonConfig -ConfigObject $testConfig
            $expanded.StaticValue | Should -Be "C:\fixed\path"
        }
        
        It "should preserve unexpanded variables" {
            $testConfig = [PSCustomObject]@{
                UndefinedVar = "%UNDEFINED_VAR%"
            }
            
            $expanded = Expand-JsonConfig -ConfigObject $testConfig
            $expanded.UndefinedVar | Should -Be "%UNDEFINED_VAR%"
        }
    }
}

Describe "Expand-XmlConfig" {
    Context "XML Expansion" {
        It "should expand environment variables in XML" {
            $xmlString = @"
<?xml version="1.0"?>
<Config>
    <WinDir>%WINDIR%</WinDir>
</Config>
"@
            
            $expanded = Expand-XmlConfig -XmlString $xmlString
            $expanded.Config.WinDir | Should -Match "^[A-Za-z]:\\"
        }
        
        It "should return XML object" {
            $xmlString = '<Config><Test>value</Test></Config>'
            $result = Expand-XmlConfig -XmlString $xmlString
            $result -is [xml] | Should -Be $true
        }
        
        It "should preserve unexpanded variables in XML" {
            $xmlString = '<Config><Undefined>%UNDEFINED_VAR%</Undefined></Config>'
            $expanded = Expand-XmlConfig -XmlString $xmlString
            $expanded.Config.Undefined | Should -Be "%UNDEFINED_VAR%"
        }
    }
}

