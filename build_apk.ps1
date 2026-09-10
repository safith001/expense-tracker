# MedExpense Automated Resilient APK Build Pipeline
$ErrorActionPreference = 'Continue'
$zipPath = "$env:USERPROFILE\flutter_sdk.zip"
$flutterBin = 'C:\flutter\bin'
$projectDir = 'c:\Users\MSMSAFITH\Downloads\projects\antigravity\spend tracker\medexpense'

Write-Host '=========================================================='
Write-Host '   MedExpense — Android APK Build Pipeline               '
Write-Host '=========================================================='

# 1. Resilient Download Loop
if (-not (Test-Path "$flutterBin\flutter.bat")) {
    Write-Host "`n[1/4] Downloading Flutter SDK (~855 MB) with auto-resume..."
    
    $downloadSuccess = $false
    $retries = 0
    $maxRetries = 100
    
    while (-not $downloadSuccess -and $retries -lt $maxRetries) {
        $retries++
        Write-Host "Attempt $retries of $maxRetries - Running curl -C - to download/resume..."
        & curl.exe -C - -L --retry 5 --retry-delay 3 'https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.3-stable.zip' -o $zipPath
        
        if ($LASTEXITCODE -eq 0 -and (Test-Path $zipPath) -and (Get-Item $zipPath).Length -gt 850000000) {
            $downloadSuccess = $true
            Write-Host "Download verified and complete! ($([math]::Round((Get-Item $zipPath).Length / 1MB, 1)) MB)"
        } else {
            $currSize = if (Test-Path $zipPath) { [math]::Round((Get-Item $zipPath).Length / 1MB, 1) } else { 0 }
            Write-Host "Connection interrupted or incomplete (Downloaded so far: $currSize MB). Reconnecting in 3 seconds..."
            Start-Sleep -Seconds 3
        }
    }
    
    if (-not $downloadSuccess) {
        Write-Error "Could not complete download after $maxRetries attempts."
        exit 1
    }
    
    # 2. Extract cleanly
    Write-Host "`n[2/4] Extracting Flutter SDK to C:\ via bsdtar..."
    if (Test-Path 'C:\flutter') {
        Remove-Item 'C:\flutter' -Recurse -Force -ErrorAction SilentlyContinue
    }
    & tar.exe -xf $zipPath -C 'C:\'
    
    if (Test-Path "$flutterBin\flutter.bat") {
        Write-Host "Extraction verified successfully!"
        Write-Host "Removing zip archive to free disk space..."
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    } else {
        Write-Error "Extraction failed. C:\flutter\bin\flutter.bat was not found."
        exit 1
    }
} else {
    Write-Host "`n[1/4] Flutter SDK already verified at C:\flutter."
}

# 3. Configure PATH
$env:Path = "$flutterBin;$env:Path"

# 4. Generate platform wrapper files if missing
Set-Location $projectDir
if (-not (Test-Path "$projectDir\android\gradlew.bat")) {
    Write-Host "`n[2/4] Generating Android Gradle wrappers..."
    & "$flutterBin\flutter.bat" create --platforms=android --org com.medexpense .
}

# 5. Dependencies and Static Analysis
Write-Host "`n[3/4] Resolving dependencies with 'flutter pub get'..."
& "$flutterBin\flutter.bat" pub get

Write-Host "`nRunning static analysis..."
& "$flutterBin\flutter.bat" analyze

# 6. Build APK
Write-Host "`n[4/4] Compiling Debug APK with 'flutter build apk --debug'..."
& "$flutterBin\flutter.bat" build apk --debug

$apkPath = "$projectDir\build\app\outputs\flutter-apk\app-debug.apk"
if (Test-Path $apkPath) {
    $apkSize = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
    Write-Host "`n=========================================================="
    Write-Host " SUCCESS! APK Build Complete: $apkSize MB"
    Write-Host " File location: $apkPath"
    Write-Host '=========================================================='
} else {
    Write-Host "`nBuild process finished. Check output above for details."
}
