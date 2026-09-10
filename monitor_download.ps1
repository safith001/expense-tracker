$path = "$env:USERPROFILE\flutter_sdk.zip"
$host.ui.RawUI.WindowTitle = "Flutter SDK Download Monitor"
$old = if (Test-Path $path) { [System.IO.FileInfo]::new($path).Length } else { 0 }

while ($true) {
    Start-Sleep -Seconds 1
    if (Test-Path $path) {
        $cur = [System.IO.FileInfo]::new($path).Length
        $diff = $cur - $old
        $spd = [math]::Round($diff / 1024, 1)
        $mb = [math]::Round($cur / 1MB, 1)
        $pct = [math]::Round(($mb / 855) * 100, 1)
        $rem = [math]::Round(855 - $mb, 1)
        $secs = if ($diff -gt 0) { [math]::Round(($rem * 1MB) / $diff) } else { 0 }
        $hr = [math]::Floor($secs / 3600)
        $min = [math]::Floor(($secs % 3600) / 60)
        $time = if ($hr -gt 0) { "${hr} hr ${min} min" } else { "${min} min" }
        $f = [math]::Min(30, [math]::Floor(($pct / 100) * 30))
        $e = [math]::Max(0, 30 - $f)
        $bar = ("#" * $f) + ("-" * $e)
        
        try { Clear-Host } catch {}
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "         Flutter SDK -- Chrome-Style Download Monitor        " -ForegroundColor Yellow
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host " File:      flutter_windows_3.24.3-stable.zip" -ForegroundColor White
        Write-Host " Progress:  $mb MB of 855 MB ($pct%)" -ForegroundColor Green
        Write-Host " Speed:     $spd KB/s" -ForegroundColor Cyan
        Write-Host " Remaining: $time left" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " [$bar] $pct%" -ForegroundColor Green
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host " (Press Ctrl+C to close this window anytime)" -ForegroundColor Gray
        
        if ($cur -ge 855000000) {
            Write-Host "`n [SUCCESS] Download Complete!" -ForegroundColor Green
            break
        }
        $old = $cur
    }
}
