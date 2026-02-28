function Get-ExpandedConfig {
    <#
    .SYNOPSIS
        Reads a JSON or XML configuration file and expands environment variables.
    
    .DESCRIPTION
        Reads a JSON or XML configuration file and expands any environment variables 
        found in the content. The file type is automatically detected based on the 
        file extension (.json or .xml). Returns the configuration object with 
        all environment variables expanded.
    
    .PARAMETER ConfigFilePath
        The path to the JSON or XML configuration file.
    
    .PARAMETER Test
        When specified, displays a test report showing which environment variables 
        were successfully expanded and which ones could not be expanded.
    
    .EXAMPLE
        $config = Get-ExpandedConfig -ConfigFilePath ".\sample.json"
        
    .EXAMPLE
        $config = Get-ExpandedConfig -ConfigFilePath ".\sample.xml" -Test
        
    .EXAMPLE
        Get-ExpandedConfig -ConfigFilePath "C:\Config\settings.json" -Test
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (-not (Test-Path -LiteralPath $_ -PathType Leaf)) {
                throw "File '$_' does not exist."
            }
            $extension = [System.IO.Path]::GetExtension($_).ToLower()
            if ($extension -notin @('.json', '.xml')) {
                throw "File '$_' must have a .json or .xml extension."
            }
            return $true
        })]
        [string]$ConfigFilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Test
    )
    
    process {
        # Determine file type based on extension
        $extension = [System.IO.Path]::GetExtension($ConfigFilePath).ToLower()
        
        switch ($extension) {
            '.json' {
                # Read and parse the JSON file
                $originalConfig = Get-Content -LiteralPath $ConfigFilePath -Raw | ConvertFrom-Json
                
                # Expand environment variables using private function
                $config = Expand-JsonConfig -ConfigObject $originalConfig
                
                # Run test if requested
                if ($Test) {
                    Test-JsonConfigExpansion -ConfigFilePath $ConfigFilePath -ConfigObject $originalConfig -ExpandedObject $config
                }
            }
            
            '.xml' {
                # Read the XML file content as a single string
                $xmlString = Get-Content -LiteralPath $ConfigFilePath -Raw
                
                # Expand environment variables using private function
                $config = Expand-XmlConfig -XmlString $xmlString
                
                # Run test if requested
                if ($Test) {
                    $expandedString = [System.Environment]::ExpandEnvironmentVariables($xmlString)
                    Test-XmlConfigExpansion -ConfigFilePath $ConfigFilePath -OriginalString $xmlString -ExpandedString $expandedString
                }
            }
        }
        
        # Return the configuration object
        return $config
    }
}
