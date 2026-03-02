# PSConfigResolver

A PowerShell module for reading configuration files (JSON and XML) and expanding environment variables within them.

## Overview

This module provides a simple yet powerful way to work with configuration files that contain environment variable references. It automatically detects the file type and expands variables using PowerShell's built-in mechanisms. The module follows PowerShell best practices and includes comprehensive testing.

## Quick Start Guide

Get up and running in just a few steps:

### Prerequisites

- PowerShell 5.0 or later
- Windows environment
- A JSON or XML configuration file

### Installation

1. Clone or download the repository:
```powershell
git clone https://github.com/mattman-ps/PSConfigResolver.git
cd PSConfigResolver
```

2. Import the module:
```powershell
Import-Module .\dist\PSConfigResolver
```

Or load the function directly:
```powershell
. .\src\public\Get-ExpandedConfig.ps1
```

### First Usage - 30 Seconds

1. Create a simple configuration file (e.g., `config.json`):
```json
{
    "AppName": "MyApp",
    "LogPath": "%TEMP%\MyApp\logs",
    "DataPath": "%USERPROFILE%\AppData\MyApp\data"
}
```

2. Load and expand it:
```powershell
$config = Get-ExpandedConfig -ConfigFilePath ".\config.json"
```

3. Access the values:
```powershell
Write-Host "App: $($config.AppName)"
Write-Host "Logs: $($config.LogPath)"
Write-Host "Data: $($config.DataPath)"
```

**Output:**
```
App: MyApp
Logs: C:\Users\username\AppData\Local\Temp\MyApp\logs
Data: C:\Users\username\AppData\MyApp\data
```

### Validate Configuration

View detailed expansion results with the `-Test` parameter:
```powershell
Get-ExpandedConfig -ConfigFilePath ".\config.json" -Test
```

### More Examples

**Working with XML:**
```powershell
$xmlConfig = Get-ExpandedConfig -ConfigFilePath ".\config.xml"
```

**Pipeline Support:**
```powershell
".\config.json" | Get-ExpandedConfig | Select-Object AppName, LogPath
```

**Batch Processing:**
```powershell
Get-ChildItem -Path ".\configs" -Filter "*.json" |
    ForEach-Object { Get-ExpandedConfig -ConfigFilePath $_.FullName }
```

### What's Next?

- See [Usage Examples](#usage-examples) for more detailed scenarios
- Read [Configuration File Formats](#configuration-file-formats) to understand supported formats
- Check [Best Practices](#best-practices) for production use
- Review [Troubleshooting](#troubleshooting) if you encounter issues

## Functions

### Get-ExpandedConfig (Public)

Reads a JSON or XML configuration file and expands all environment variables found within it.

**Syntax:**
```powershell
Get-ExpandedConfig -ConfigFilePath <string> [-Test]
```

**Parameters:**
- `-ConfigFilePath` (Required): Path to the JSON or XML configuration file
- `-Test` (Optional): Display a detailed test report showing expansion results

**Returns:** Parsed configuration object (PSObject for JSON, XML object for XML)

**Example Output:**
```none
AppName          Environment Paths                             Logging
-------          ----------- -----                             -------
PSConfigResolver Development @{UserProfile=...; Cache=...}    @{Level=Information; FilePath=...}
```

### Expand-JsonConfig (Private)

Expands environment variables in a parsed JSON configuration object.

**Usage:** Called internally by `Get-ExpandedConfig`

**Parameters:**
- `-ConfigObject` (Required): A parsed JSON object

**Returns:** PSObject with expanded environment variables

### Expand-XmlConfig (Private)

Expands environment variables in raw XML content and returns a parsed XML object.

**Usage:** Called internally by `Get-ExpandedConfig`

**Parameters:**
- `-XmlString` (Required): Raw XML content as a string

**Returns:** [xml] object with expanded environment variables

### Test-JsonConfigExpansion (Private)

Generates a detailed test report for JSON configuration expansion.

**Usage:** Called internally by `Get-ExpandedConfig -Test`

### Test-XmlConfigExpansion (Private)

Generates a detailed test report for XML configuration expansion.

**Usage:** Called internally by `Get-ExpandedConfig -Test`

## Usage Examples

### Basic Usage - JSON File

```powershell
# Load the function
. '.\src\public\Get-ExpandedConfig.ps1'

# Read and expand JSON configuration
$config = Get-ExpandedConfig -ConfigFilePath ".\samples\sample.json"

# Access the expanded values
Write-Host "App: $($config.AppName)"
Write-Host "User Profile: $($config.Paths.UserProfile)"
Write-Host "Worker Queue: $($config.Services[1].QueuePath)"
```

### Basic Usage - XML File

```powershell
# Load the function
. '.\src\public\Get-ExpandedConfig.ps1'

# Read and expand XML configuration
$config = Get-ExpandedConfig -ConfigFilePath ".\samples\sample.xml"

# Access the expanded values
Write-Host "App Name: $($config.Config.Application.Name)"
Write-Host "Logs Path: $($config.Config.Paths.Logs)"
```

### Using the Test Parameter

```powershell
# Display detailed expansion results
$config = Get-ExpandedConfig -ConfigFilePath ".\samples\sample.json" -Test
```

**Output:**
```
=== Environment Variable Expansion Test Results ===
File: .\samples\sample.json

✓ SUCCESS - AppName
✓ SUCCESS - Paths.UserProfile
✓ SUCCESS - Paths.WindowsDirectory
✓ SUCCESS - Logging.FilePath
✗ FAILED - Services[0].ApiKey
    Original:  %DUMMY_VAR%
    Expanded:  %DUMMY_VAR%

Summary: 11 successful, 1 failed
```

### Pipeline Support

```powershell
# Pass the file path via pipeline
".\samples\sample.json" | Get-ExpandedConfig

# Chain with other commands
".\samples\sample.json" | Get-ExpandedConfig | Select-Object AppName, Environment
```

### Multiple Files

```powershell
# Process multiple configuration files
$files = @(".\samples\sample.json", ".\samples\sample.xml")
$configs = $files | Get-ExpandedConfig

# Or with test results
$files | ForEach-Object {
    Write-Host "Processing: $_"
    Get-ExpandedConfig -ConfigFilePath $_ -Test
}
```

## Configuration File Formats

### JSON Format

```json
{
    "AppName": "PSConfigResolver",
    "Environment": "Development",
    "Paths": {
        "UserProfile": "%USERPROFILE%",
        "WindowsDirectory": "%SystemRoot%",
        "Cache": "%TEMP%/PSConfigResolver/cache"
    },
    "Services": [
        {
            "Name": "Api",
            "ApiKey": "%DUMMY_VAR%"
        },
        {
            "Name": "Worker",
            "QueuePath": "%TEMP%/queues/jobs"
        }
    ],
    "Features": {
        "RetryCount": 3,
        "EnableTelemetry": true
    }
}
```

**Supported:** Environment variables in string values are expanded recursively (including nested objects and arrays)

### XML Format

```xml
<?xml version="1.0"?>
<Config>
    <Application>
        <Name>PSConfigResolver</Name>
        <Environment>Development</Environment>
    </Application>
    <Paths>
        <UserProfile>%USERPROFILE%</UserProfile>
        <Logs>%LOCALAPPDATA%/PSConfigResolver/logs</Logs>
    </Paths>
    <Legacy>
        <ApiKey>%DUMMY_VAR%</ApiKey>
    </Legacy>
</Config>
```

**Supported:** Environment variables anywhere in the XML content will be expanded

## Environment Variable Expansion

The module uses PowerShell's `[System.Environment]::ExpandEnvironmentVariables()` method to expand variables.  For more information on supported variables, see the official documentation at [Microsoft](https://learn.microsoft.com/en-us/dotnet/api/system.environment.expandenvironmentvariables?view=net-10.0)

**Supported Format:** `%VARIABLE_NAME%`

**Examples:**
- `%USERPROFILE%` → `C:\Users\username`
- `%WINDIR%` → `C:\Windows`
- `%APPDATA%` → `C:\Users\username\AppData\Roaming`
- `%TEMP%` → `C:\Users\username\AppData\Local\Temp`

**Unexpanded Variables:** Variables that don't exist in the environment will remain as-is (e.g., `%DUMMY_VAR%` stays `%DUMMY_VAR%`)

## Testing

The module includes a comprehensive Pester test suite.

### Run Tests

```powershell
# Run all tests
Invoke-Pester -Path ".\tests\ExpandConfig.tests.ps1"

# Run with detailed output
Invoke-Pester -Path ".\tests\ExpandConfig.tests.ps1" -Output Detailed

# Run specific test
Invoke-Pester -Path ".\tests\ExpandConfig.tests.ps1" -Container @{
    Filter = @{ Name = "Get-ExpandedConfig" }
}
```

### Test Coverage

- **Parameter Validation:** Required parameters, file existence, file extension validation
- **JSON Processing:** Expansion, variable preservation, pipeline support
- **XML Processing:** Expansion, parsing, variable preservation
- **Test Parameter:** Reporting functionality
- **Edge Cases:** Unexpanded variables, static values, special cases

## Requirements

- PowerShell 5.0 or later
- Windows environment (uses Windows environment variables)
- Pester 5.0 or later (for running tests)

## Installation

For detailed installation and first-time setup, see the [Quick Start Guide](#quick-start-guide) above.

For module-based installation:
```powershell
Import-Module .\dist\PSConfigResolver
```

Or source the function directly:
```powershell
. '.\src\public\Get-ExpandedConfig.ps1'
```

## Error Handling

The module includes validation for:

- **Missing ConfigFilePath:** Required parameter
- **File Not Found:** File must exist
- **Invalid Extension:** Only `.json` and `.xml` files are supported
- **Invalid JSON:** Parsing errors will be raised
- **Invalid XML:** Parsing errors will be raised

### Example Error Handling

```powershell
try {
    $config = Get-ExpandedConfig -ConfigFilePath ".\invalid.txt"
} catch {
    Write-Error "Failed to load configuration: $_"
}
```

## Best Practices

1. **Always validate configuration:**
   ```powershell
   $config = Get-ExpandedConfig -ConfigFilePath ".\config.json" -Test
   ```

2. **Pipeline for batch processing:**
   ```powershell
   Get-ChildItem -Path ".\configs" -Filter "*.json" | 
       Get-ExpandedConfig
   ```

3. **Error handling in production:**
   ```powershell
   try {
       $config = Get-ExpandedConfig -ConfigFilePath $path
   } catch {
       Write-Error "Configuration load failed: $_"
       exit 1
   }
   ```

4. **Check for unexpanded variables:**
   ```powershell
   $config = Get-ExpandedConfig -ConfigFilePath ".\config.json" -Test
   # Review test output for any ✗ FAILED items
   ```

## Troubleshooting

### Configuration won't load
- Verify file path is correct
- Ensure file is valid JSON/XML
- Check file permissions

### Variables not expanding
- Confirm variable names are correct (case-sensitive in some contexts)
- Use format: `%VARIABLE_NAME%`
- Check if environment variable exists: `[Environment]::GetEnvironmentVariable('VARIABLE_NAME')`

### Test failures
- Run with `-Test` parameter to see detailed results
- Check for unexpanded variables in output
- Verify environment variables are set

## License

This module is provided as-is for configuration file management purposes.

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review test output with `-Test` parameter
3. Verify configuration file format
4. Check PowerShell version compatibility
