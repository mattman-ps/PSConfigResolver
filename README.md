# PSConfigResolver

A PowerShell module for reading configuration files (JSON and XML) and expanding environment variables within them.

## Overview

This module provides a simple yet powerful way to work with configuration files that contain environment variable references. It automatically detects the file type and expands variables using PowerShell's built-in mechanisms. The module follows PowerShell best practices and includes comprehensive testing.

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
```
Name  UserPath               WinDir     OldUserName
----  --------               ------     -----------
mattman-ps C:\Users\mattman-ps/.config C:\windows %DUMMY_VAR%
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
$config = Get-ExpandedConfig -ConfigFilePath ".\sample\sample.json"

# Access the expanded values
Write-Host "User Path: $($config.UserPath)"
Write-Host "Windows Directory: $($config.WinDir)"
```

### Basic Usage - XML File

```powershell
# Load the function
. '.\src\public\Get-ExpandedConfig.ps1'

# Read and expand XML configuration
$config = Get-ExpandedConfig -ConfigFilePath ".\sample\sample.xml"

# Access the expanded values
Write-Host "User Path: $($config.Config.UserPath)"
Write-Host "Windows Directory: $($config.Config.WinDir)"
```

### Using the Test Parameter

```powershell
# Display detailed expansion results
$config = Get-ExpandedConfig -ConfigFilePath ".\sample\sample.json" -Test
```

**Output:**
```
=== Environment Variable Expansion Test Results ===
File: .\sample\sample.json

✓ SUCCESS - Name
✓ SUCCESS - UserPath
✓ SUCCESS - WinDir
✗ FAILED - OldUserName
  Original:  %DUMMY_VAR%
  Expanded:  %DUMMY_VAR%

Summary: 3 successful, 1 failed
```

### Pipeline Support

```powershell
# Pass the file path via pipeline
".\sample\sample.json" | Get-ExpandedConfig

# Chain with other commands
".\sample\sample.json" | Get-ExpandedConfig | Select-Object Name, UserPath
```

### Multiple Files

```powershell
# Process multiple configuration files
$files = @(".\sample\sample.json", ".\sample\sample.xml")
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
  "Name": "mattman-ps",
  "UserPath": "%USERPROFILE%/.config",
  "WinDir": "%WINDIR%",
  "OldUserName": "%DUMMY_VAR%"
}
```

**Supported:** Environment variables in property values will be expanded

### XML Format

```xml
<?xml version="1.0"?>
<Config>
  <Name>mattman-ps</Name>
  <UserPath>%USERPROFILE%/.config</UserPath>
  <WinDir>%WINDIR%</WinDir>
  <OldUserName>%DUMMY_VAR%</OldUserName>
</Config>
```

**Supported:** Environment variables anywhere in the XML content will be expanded

## Environment Variable Expansion

The module uses PowerShell's `[System.Environment]::ExpandEnvironmentVariables()` method to expand variables.

**Supported Format:** `%VARIABLE_NAME%`

**Examples:**
- `%USERPROFILE%` → `C:\Users\username`
- `%WINDIR%` → `C:\Windows`
- `%APPDATA%` → `C:\Users\username\AppData\Roaming`
- `%TEMP%` → `C:\Users\username\AppData\Local\Temp`

**Unexpanded Variables:** Variables that don't exist in the environment will remain as-is (e.g., `%DUMMY_VAR%` stays `%DUMMY_VAR%`)

## Testing

The module includes a comprehensive Pester test suite with 14 test cases.

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

1. Clone or download the repository
2. Load the main function:
```powershell
. '.\src\public\Get-ExpandedConfig.ps1'
```

3. Or add to your profile for automatic loading:
```powershell
# Add to your PowerShell profile
. 'C:\path\to\ExpandEnvVariables\src\public\Get-ExpandedConfig.ps1'
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
