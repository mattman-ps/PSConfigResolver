function Backup-Config {
    <#
    .SYNOPSIS
        Creates a backup copy of a configuration file.
    
    .DESCRIPTION
        Creates a timestamped backup copy of a configuration file. Useful for
        preserving original configurations before modifications.
    
    .PARAMETER ConfigFilePath
        Path to the configuration file to backup
    
    .PARAMETER BackupPath
        Directory where backup will be stored. Defaults to same directory as original.
        Backup filename will be: original_name_YYYYMMDD_HHmmss.ext
    
    .OUTPUTS
        PSObject with backup information (OriginalPath, BackupPath, Timestamp)
    
    .EXAMPLE
        Backup-Config -ConfigFilePath ".\config.json"
        
    .EXAMPLE
        Backup-Config -ConfigFilePath ".\config.json" -BackupPath ".\backups"
    
    .EXAMPLE
        $backup = Backup-Config -ConfigFilePath ".\config.json" | Select-Object -ExpandProperty BackupPath
        Write-Host "Backup created at: $backup"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({
            if (-not (Test-Path -LiteralPath $_ -PathType Leaf)) {
                throw "File '$_' does not exist."
            }
            return $true
        })]
        [string]$ConfigFilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$BackupPath
    )
    
    process {
        try {
            # Resolve full paths
            $fullConfigPath = Resolve-Path -LiteralPath $ConfigFilePath | Select-Object -ExpandProperty Path
            
            # Determine backup directory
            if ($BackupPath) {
                if (-not (Test-Path -LiteralPath $BackupPath)) {
                    New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
                }
                $backupDir = Resolve-Path -LiteralPath $BackupPath | Select-Object -ExpandProperty Path
            }
            else {
                $backupDir = Split-Path -Parent $fullConfigPath
            }
            
            # Create timestamped backup filename
            $fileInfo = Get-Item -LiteralPath $fullConfigPath
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileInfo.Name)
            $extension = $fileInfo.Extension
            $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
            $backupFileName = "$baseName`_$timestamp$extension"
            $backupFullPath = Join-Path -Path $backupDir -ChildPath $backupFileName
            
            # Create backup
            Copy-Item -LiteralPath $fullConfigPath -Destination $backupFullPath -Force
            
            Write-Verbose "Configuration backed up to: $backupFullPath"
            
            # Return backup information
            return [PSObject]@{
                OriginalPath = $fullConfigPath
                BackupPath = $backupFullPath
                Timestamp = Get-Date
                FileName = $backupFileName
            }
        }
        catch {
            Write-Error "Failed to backup configuration: $_"
            throw
        }
    }
}
