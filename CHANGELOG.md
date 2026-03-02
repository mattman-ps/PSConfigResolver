# Changelog

All notable changes to PSConfigResolver will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Support for additional configuration formats (YAML, TOML, INI)
- Recursive environment variable expansion
- Configuration caching for improved performance
- Configuration validation with JSON Schema
- Backup and export utilities
- Enhanced logging capabilities

## [0.0.1] - 2026-03-01

### Added
- Initial release of PSConfigResolver module
- `Get-ExpandedConfig` function to read and expand configuration files
  - Support for JSON configuration files
  - Support for XML configuration files
  - Automatic file type detection based on extension
  - Optional test report parameter for validation (`-Test` switch)
- Environment variable expansion using PowerShell's built-in `ExpandEnvironmentVariables` method
- `Expand-JsonConfig` private function for JSON configuration expansion
- `Expand-XmlConfig` private function for XML configuration expansion
- `Test-JsonConfigExpansion` private function for JSON test reporting
- `Test-XmlConfigExpansion` private function for XML test reporting
- Comprehensive Pester test suite covering:
  - Parameter validation
  - JSON file processing
  - XML file processing
  - Error handling
  - Environment variable expansion in nested objects and arrays
- Sample configuration files (JSON and XML) for demonstration
- Full inline documentation with examples
- MIT License

### Features
- Automatic detection of JSON and XML configuration files
- Recursive expansion of environment variables throughout configuration objects
- Detailed test reports showing expansion results with success/failure indicators
- Input validation for file paths and extensions
- Support for nested configuration objects and arrays

