param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("weekly", "monthly", "daily")]
    [string]$Type = "weekly"
)

# =============================================================================
# ACU Routing API — Windows PostgreSQL Backup Script
#
# Creates a compressed custom-format backup (.dump) of the routing_db.
# Automatically cleans up old backups based on the type:
#   - daily  : Kept for 14 days
#   - weekly : Kept for 90 days
#   - monthly: Kept for 365 days
#
# Usage (run from Windows Task Scheduler):
#   powershell.exe -ExecutionPolicy Bypass -File .\scripts\backup_db.ps1 -Type weekly
# =============================================================================

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$BackupDir  = Join-Path $ProjectDir "backup"
$EnvFile    = Join-Path $ProjectDir ".env"

if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

# 1. Parse .env file for credentials
if (-not (Test-Path $EnvFile)) {
    Write-Host "[ERROR] .env file not found at $EnvFile" -ForegroundColor Red
    exit 1
}

$envHash = @{}
Get-Content $EnvFile | Where-Object { $_ -match '^\s*([^#\s][^=]+)\s*=\s*(.*)$' } | ForEach-Object {
    $envHash[$matches[1]] = $matches[2]
}

$DB_HOST = if ($envHash["DB_HOST"]) { $envHash["DB_HOST"] } else { "localhost" }
$DB_PORT = if ($envHash["DB_PORT"]) { $envHash["DB_PORT"] } else { "5432" }
$DB_NAME = if ($envHash["DB_NAME"]) { $envHash["DB_NAME"] } else { "routing_db" }
$DB_USER = if ($envHash["DB_USER"]) { $envHash["DB_USER"] } else { "postgres" }
$DB_PASS = $envHash["DB_PASSWORD"]

# 2. Setup pg_dump environment
$env:PGPASSWORD = $DB_PASS
$DateStr  = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$FileName = "${DB_NAME}_${Type}_${DateStr}.dump"
$FilePath = Join-Path $BackupDir $FileName

Write-Host "[$(Get-Date -Format 's')] Starting $Type backup -> $FileName" -ForegroundColor Cyan

# 3. Run pg_dump (Custom format is highly compressed)
try {
    # -F c = Custom format (compressed, suitable for pg_restore)
    & pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -F c -f $FilePath
} catch {
    Write-Host "[ERROR] pg_dump failed. Is PostgreSQL installed and added to PATH?" -ForegroundColor Red
    exit 1
}

if (Test-Path $FilePath) {
    $SizeMB = [math]::Round((Get-Item $FilePath).Length / 1MB, 2)
    Write-Host "[$(Get-Date -Format 's')] Backup complete. Size: ${SizeMB} MB" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Backup file was not created!" -ForegroundColor Red
    exit 1
}

# 4. Smart Cleanup
if ($Type -eq "daily") {
    $KeepDays = 14
} elseif ($Type -eq "weekly") {
    $KeepDays = 90
} else {
    $KeepDays = 360
}

Write-Host "[$(Get-Date -Format 's')] Removing $Type backups older than $KeepDays days..." -ForegroundColor Cyan

$CutoffDate = (Get-Date).AddDays(-$KeepDays)
Get-ChildItem -Path $BackupDir -Filter "${DB_NAME}_${Type}_*.dump" | Where-Object {
    $_.CreationTime -lt $CutoffDate
} | Remove-Item -Force

Write-Host "[$(Get-Date -Format 's')] Cleanup done." -ForegroundColor Green
