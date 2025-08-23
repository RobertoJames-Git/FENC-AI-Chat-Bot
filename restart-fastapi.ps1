# Check if port 8000 is in use
$connections = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue

if ($connections) {
    $pids = $connections | Select-Object -ExpandProperty OwningProcess | Sort-Object -Unique

    foreach ($pid in $pids) {
        Write-Host "Stopping process with PID $pid holding port 8000..." -ForegroundColor Yellow
        Stop-Process -Id $pid -Force
    }

    Write-Host "Port 8000 is now free." -ForegroundColor Green
} else {
    Write-Host "Port 8000 is already free." -ForegroundColor Cyan
}

# Start FastAPI server
Write-Host "Starting FastAPI server on port 8000..." -ForegroundColor White
Start-Process "uvicorn" -ArgumentList "main:app", "--reload", "--port", "8000" -NoNewWindow
