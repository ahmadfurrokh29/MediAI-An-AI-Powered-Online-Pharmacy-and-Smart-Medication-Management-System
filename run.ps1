# MediAI — Start backend + Flutter app together
# Usage:  .\run.ps1
# Requirements: Python + Flutter on PATH, .env configured in backend/

$ProjectRoot = $PSScriptRoot
$BackendDir  = Join-Path $ProjectRoot "backend"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  MediAI Launcher" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# ── 1. Check if backend is already running ───────────────────────────────────
Write-Host "`n[1/2] Checking backend..." -ForegroundColor Yellow

$alreadyUp = $false
try {
    $r = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
    if ($r.StatusCode -eq 200) { $alreadyUp = $true }
} catch {}

if ($alreadyUp) {
    Write-Host "[OK] Backend already running on port 8000 — skipping startup." -ForegroundColor Green
} else {
    # Kill anything that might be squatting on 8000 silently
    $existing = netstat -ano | Select-String ":8000 " | Select-String "LISTENING"
    if ($existing) {
        $pid8000 = ($existing -split '\s+')[-1]
        Write-Host "[!] Port 8000 in use by PID $pid8000 — killing it..." -ForegroundColor Yellow
        Stop-Process -Id $pid8000 -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
    }

    Write-Host "[  ] Starting FastAPI backend on port 8000..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-Command",
        "cd '$BackendDir'; Write-Host 'MediAI Backend' -ForegroundColor Cyan; python -m uvicorn main:app --host 0.0.0.0 --port 8000"
    ) -WindowStyle Normal

    # ── 2. Wait up to 90 seconds (RAG model load can be slow on cold start) ──
    Write-Host "[  ] Waiting for backend to be ready (up to 90s)..." -ForegroundColor Gray
    $ready = $false
    for ($i = 1; $i -le 90; $i++) {
        Start-Sleep -Seconds 1
        Write-Host -NoNewline "`r[  ] Waiting... ${i}s / 90s" -ForegroundColor Gray
        try {
            $r = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
            if ($r.StatusCode -eq 200) { $ready = $true; break }
        } catch {}
    }
    Write-Host ""

    if (-not $ready) {
        Write-Host "[!] Backend did not start in 90s. Check the backend window for errors." -ForegroundColor Red
        Write-Host "    Common causes:" -ForegroundColor Red
        Write-Host "      - Python or pip packages not installed (run: pip install -r requirements.txt)" -ForegroundColor Red
        Write-Host "      - Missing .env file with API keys" -ForegroundColor Red
        Write-Host "      - Windows Firewall blocking port 8000" -ForegroundColor Red
        exit 1
    }
    Write-Host "[OK] Backend is up!" -ForegroundColor Green
}

# ── 3. Launch Flutter app ────────────────────────────────────────────────────
Write-Host "`n[2/2] Launching Flutter app..." -ForegroundColor Yellow
Set-Location $ProjectRoot
flutter run
