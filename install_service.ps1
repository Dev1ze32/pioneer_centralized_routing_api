# =============================================================
# ACU Routing API — Windows Service Installer
# =============================================================
#
# This script registers waitress_server.py as a Windows Service
# using NSSM (Non-Sucking Service Manager).
#
# The service will:
#   - Start automatically when the server boots
#   - Restart automatically if it crashes
#   - Run in the background (no terminal window needed)
#   - Write logs to the "logs" folder inside this project
#
# Requirements:
#   - Run this script as Administrator
#   - Python must be installed on this machine
#   - Run: pip install -r requirements.txt  (inside your venv first)
#   - NSSM will be downloaded automatically if not found
#
# Usage:
#   Right-click install_service.ps1 → Run as Administrator
#   OR in an elevated PowerShell:
#       .\install_service.ps1
#
# To remove the service later:
#       .\uninstall_service.ps1
# =============================================================

# ── Configuration — edit these if your paths differ ──────────
$ServiceName    = "ACURoutingAPI"
$ServiceDisplay = "ACU Routing API"
$ServiceDesc    = "ACU Routing API (Waitress/Flask) — auto-restarts on failure"

# Detect the folder where this script lives, then go up one level to the project root
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir

# Find python.exe — prefer the venv inside the project folder
$VenvPython     = Join-Path $ProjectDir "venv\Scripts\python.exe"
$SystemPython   = (Get-Command python -ErrorAction SilentlyContinue).Source

if (Test-Path $VenvPython) {
    $PythonExe = $VenvPython
    Write-Host "[OK] Using venv Python: $PythonExe" -ForegroundColor Green
} elseif ($SystemPython) {
    $PythonExe = $SystemPython
    Write-Host "[WARN] venv not found. Using system Python: $PythonExe" -ForegroundColor Yellow
    Write-Host "       It is recommended to create a venv first:" -ForegroundColor Yellow
    Write-Host "       python -m venv venv && venv\Scripts\pip install -r requirements.txt" -ForegroundColor Yellow
} else {
    Write-Host "[ERROR] Python not found. Install Python 3.12+ and try again." -ForegroundColor Red
    exit 1
}

$ServerScript   = Join-Path $ProjectDir "server.py"
$LogDir         = Join-Path $ProjectDir "logs"
$NSSMPath       = Join-Path $ProjectDir "nssm\nssm.exe"

# ── Check Administrator ───────────────────────────────────────
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Please run this script as Administrator." -ForegroundColor Red
    Write-Host "        Right-click the script and choose 'Run as Administrator'." -ForegroundColor Red
    pause
    exit 1
}

# ── Create logs directory ────────────────────────────────────
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
    Write-Host "[OK] Created logs directory: $LogDir" -ForegroundColor Green
}

# ── Download NSSM if not present ────────────────────────────
if (-not (Test-Path $NSSMPath)) {
    Write-Host "[INFO] NSSM not found. Downloading..." -ForegroundColor Cyan
    $NSSMDir  = Join-Path $ProjectDir "nssm"
    $NSSMZip  = Join-Path $ProjectDir "nssm.zip"

    New-Item -ItemType Directory -Path $NSSMDir -Force | Out-Null

    try {
        Invoke-WebRequest -Uri "https://nssm.cc/release/nssm-2.24.zip" -OutFile $NSSMZip -UseBasicParsing
        Expand-Archive -Path $NSSMZip -DestinationPath $ProjectDir -Force

        # NSSM extracts to nssm-2.24\win64\nssm.exe (64-bit)
        $Extracted = Join-Path $ProjectDir "nssm-2.24\win64\nssm.exe"
        Copy-Item $Extracted $NSSMPath -Force
        Remove-Item $NSSMZip -Force
        Remove-Item (Join-Path $ProjectDir "nssm-2.24") -Recurse -Force
        Write-Host "[OK] NSSM downloaded and ready." -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to download NSSM: $_" -ForegroundColor Red
        Write-Host "        Download manually from https://nssm.cc/download" -ForegroundColor Red
        Write-Host "        Place nssm.exe in: $NSSMDir" -ForegroundColor Red
        pause
        exit 1
    }
}

# ── Remove existing service if it already exists ─────────────
$Existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($Existing) {
    Write-Host "[INFO] Existing service found. Removing it first..." -ForegroundColor Yellow
    & $NSSMPath stop $ServiceName | Out-Null
    & $NSSMPath remove $ServiceName confirm | Out-Null
    Start-Sleep -Seconds 2
}

# ── Install the service ──────────────────────────────────────
Write-Host "[INFO] Installing Windows Service '$ServiceName'..." -ForegroundColor Cyan

& $NSSMPath install $ServiceName $PythonExe $ServerScript

# ── Configure service settings ───────────────────────────────
# Working directory (so .env is found correctly)
& $NSSMPath set $ServiceName AppDirectory $ProjectDir

# Display name and description
& $NSSMPath set $ServiceName DisplayName $ServiceDisplay
& $NSSMPath set $ServiceName Description $ServiceDesc

# Start type: automatic (starts on boot)
& $NSSMPath set $ServiceName Start SERVICE_AUTO_START

# Restart on failure — wait 5s before restart, up to unlimited restarts
& $NSSMPath set $ServiceName AppRestartDelay 5000
& $NSSMPath set $ServiceName AppThrottle 10000

# Log stdout and stderr to files (new log file each day)
& $NSSMPath set $ServiceName AppStdout (Join-Path $LogDir "api_stdout.log")
& $NSSMPath set $ServiceName AppStderr (Join-Path $LogDir "api_stderr.log")
& $NSSMPath set $ServiceName AppRotateFiles 1
& $NSSMPath set $ServiceName AppRotateBytes 10485760   # rotate at 10 MB

# ── Start the service now ────────────────────────────────────
Write-Host "[INFO] Starting service..." -ForegroundColor Cyan
& $NSSMPath start $ServiceName
Start-Sleep -Seconds 3

# ── Verify ───────────────────────────────────────────────────
$Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($Service -and $Service.Status -eq "Running") {
    Write-Host "" 
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " SUCCESS! ACU Routing API is now running as a Windows Service" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Service name : $ServiceName"
    Write-Host "  Status       : $($Service.Status)"
    Write-Host "  Logs folder  : $LogDir"
    Write-Host ""
    Write-Host "  The service will automatically:"
    Write-Host "    - Start when the server boots"
    Write-Host "    - Restart if it crashes (after 5 seconds)"
    Write-Host ""
    Write-Host "  Useful commands (run as Administrator):"
    Write-Host "    Start  : Start-Service $ServiceName"
    Write-Host "    Stop   : Stop-Service $ServiceName"
    Write-Host "    Restart: Restart-Service $ServiceName"
    Write-Host "    Status : Get-Service $ServiceName"
    Write-Host ""
    Write-Host "  To remove the service: .\uninstall_service.ps1"
    Write-Host ""
} else {
    Write-Host "[ERROR] Service did not start correctly." -ForegroundColor Red
    Write-Host "        Check the logs at: $LogDir" -ForegroundColor Red
    Write-Host "        Or run: & '$NSSMPath' status $ServiceName" -ForegroundColor Red
}

pause
