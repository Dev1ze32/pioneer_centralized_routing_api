# =============================================================
# ACU Routing API — Windows Service Uninstaller
# =============================================================
#
# This script stops and completely removes the ACU Routing API
# Windows Service. Your application files and data are NOT deleted.
#
# Usage:
#   Right-click uninstall_service.ps1 → Run as Administrator
#   OR in an elevated PowerShell:
#       .\uninstall_service.ps1
# =============================================================

$ServiceName = "ACURoutingAPI"
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir  = Split-Path -Parent $ScriptDir
$NSSMPath    = Join-Path $ProjectDir "nssm\nssm.exe"

# ── Check Administrator ───────────────────────────────────────
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Please run this script as Administrator." -ForegroundColor Red
    pause
    exit 1
}

$Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $Service) {
    Write-Host "[INFO] Service '$ServiceName' is not installed. Nothing to do." -ForegroundColor Yellow
    pause
    exit 0
}

Write-Host "[INFO] Stopping service '$ServiceName'..." -ForegroundColor Cyan
& $NSSMPath stop $ServiceName
Start-Sleep -Seconds 3

Write-Host "[INFO] Removing service '$ServiceName'..." -ForegroundColor Cyan
& $NSSMPath remove $ServiceName confirm
Start-Sleep -Seconds 2

$Removed = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $Removed) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " SUCCESS! ACU Routing API service has been removed."          -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Your application files and database data were NOT deleted."
    Write-Host "  To reinstall, run: .\install_service.ps1"
    Write-Host ""
} else {
    Write-Host "[ERROR] Failed to remove the service." -ForegroundColor Red
    Write-Host "        Try manually: sc.exe delete $ServiceName" -ForegroundColor Red
}

pause
