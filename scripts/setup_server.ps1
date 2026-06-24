# =============================================================
# ACU Routing API — Full Server Setup Orchestrator
# =============================================================
#
# This script automates the complete setup of the API on a new
# Windows Server. It will:
# 1. Ask for database and admin credentials
# 2. Create the .env file automatically
# 3. Create the Python virtual environment and install dependencies
# 4. Create the routing_db database in PostgreSQL
# 5. Initialize the database tables and create the first admin user
# 6. Install the Windows Service to run the API in the background
#
# Requirements:
#   - Python 3.12+ must be installed
#   - PostgreSQL must be installed (running on localhost:5432)
#   - Run as Administrator!
# =============================================================

# ── Check Administrator ───────────────────────────────────────
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Please run this script as Administrator." -ForegroundColor Red
    Write-Host "        Right-click the script and choose 'Run as Administrator'." -ForegroundColor Red
    pause
    exit 1
}

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
Set-Location $ProjectDir

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host " ACU Routing API Setup Wizard" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Check Python ──────────────────────────────────────────
$SystemPython = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $SystemPython) {
    Write-Host "[ERROR] Python is not installed or not in PATH." -ForegroundColor Red
    Write-Host "        Please install Python 3.12+ and try again." -ForegroundColor Red
    pause
    exit 1
}
Write-Host "[OK] Found Python: $SystemPython" -ForegroundColor Green

# ── 2. Collect Credentials ───────────────────────────────────
Write-Host ""
Write-Host "--- Database Setup ---" -ForegroundColor Cyan
$DBPassword = Read-Host "Enter the password for the local 'postgres' user"

Write-Host ""
Write-Host "--- API Admin Account Setup ---" -ForegroundColor Cyan
Write-Host "This account will be created automatically so you can log into the website."
$AdminUser = Read-Host "Enter a username for the Admin account"
$AdminPass = Read-Host "Enter a password for the Admin account (min 8 chars)"

# Generate a random JWT secret
$JWTSecret = -join ((33..126) | Get-Random -Count 64 | % {[char]$_})

# ── 3. Create .env File ──────────────────────────────────────
Write-Host ""
Write-Host "Creating .env configuration file..." -ForegroundColor Cyan

$EnvPath = Join-Path $ProjectDir ".env"
$EnvContent = @"
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=routing_db
DB_USER=postgres
DB_PASSWORD=$DBPassword

# Authentication
JWT_SECRET_KEY=$JWTSecret
JWT_ACCESS_TOKEN_EXPIRES_HOURS=24

# Initial Admin User (used only during first run)
INITIAL_ADMIN_USERNAME=$AdminUser
INITIAL_ADMIN_PASSWORD=$AdminPass

# Connection pool
DB_POOL_SIZE=64
DB_MAX_OVERFLOW=10
DB_POOL_TIMEOUT=10
DB_POOL_RECYCLE=1800
DB_CONNECT_TIMEOUT=5
DB_STATEMENT_TIMEOUT_MS=30000

# Rate limiting
RATE_LIMIT_LOGIN=10/minute
RATE_LIMIT_REGISTER=5/minute
RATE_LIMIT_DEFAULT=300/minute

# Waitress (Production server)
WAITRESS_THREADS=64
WAITRESS_PORT=8080
"@

Set-Content -Path $EnvPath -Value $EnvContent -Encoding UTF8
Write-Host "[OK] .env file created." -ForegroundColor Green

# ── 4. Virtual Environment & Dependencies ────────────────────
Write-Host ""
Write-Host "Setting up Python virtual environment (venv)..." -ForegroundColor Cyan
if (-not (Test-Path "venv")) {
    & python -m venv venv
}

$VenvPython = Join-Path $ProjectDir "venv\Scripts\python.exe"
$VenvPip    = Join-Path $ProjectDir "venv\Scripts\pip.exe"

Write-Host "Installing dependencies... (this may take a minute)" -ForegroundColor Cyan
& $VenvPip install -r requirements.txt | Out-Null
Write-Host "[OK] Dependencies installed." -ForegroundColor Green

# ── 5. Database Initialization ───────────────────────────────
Write-Host ""
Write-Host "Creating the PostgreSQL database if it doesn't exist..." -ForegroundColor Cyan
& $VenvPython "scripts\init_db.py" $DBPassword
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create or connect to the database. Check your password and ensure Postgres is running." -ForegroundColor Red
    pause
    exit 1
}

Write-Host "Creating database tables and seeding the Admin user..." -ForegroundColor Cyan
# Running create_app() will trigger the DB init and admin seed automatically via app.py
& $VenvPython -c "from app import create_app; create_app()"
Write-Host "[OK] Database is fully initialized." -ForegroundColor Green

# ── 6. Install Windows Service ───────────────────────────────
Write-Host ""
Write-Host "Registering API as a background Windows Service..." -ForegroundColor Cyan

$InstallScript = Join-Path $ProjectDir "services\install_service.ps1"
& powershell -ExecutionPolicy Bypass -File $InstallScript

Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
Write-Host " SETUP COMPLETE! " -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "The ACU Routing API is now running in the background."
Write-Host "You can access it at: http://localhost:8080/docs/"
Write-Host ""
pause
