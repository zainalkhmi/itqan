# ==============================================================================
# Itqan Mobile App - Production Release Build Automation (Windows PowerShell)
# Builds:
#   1. Android App Bundle (AAB) for Google Play Store upload
#   2. Universal and Split Release APKs for direct testing & distribution
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "  🕌 ITQAN - Production Release Build Generator" -ForegroundColor Yellow
Write-Host "========================================================`n" -ForegroundColor Cyan

$AppDir = Join-Path $PSScriptRoot "..\app"
Set-Location $AppDir

# 1. Clean and get dependencies
Write-Host "📦 Resolving Flutter dependencies..." -ForegroundColor Green
flutter pub get

# 2. Build Android App Bundle (.aab)
Write-Host "`n🚀 Building Google Play Android App Bundle (AAB)..." -ForegroundColor Green
flutter build appbundle --release

$AabPath = Join-Path $AppDir "build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $AabPath) {
    $AabSize = (Get-Item $AabPath).Length / 1MB
    Write-Host "✅ AAB Build Succeeded: $AabPath ($([math]::Round($AabSize, 2)) MB)" -ForegroundColor Green
} else {
    Write-Host "⚠️ AAB output not found at standard path." -ForegroundColor Yellow
}

# 3. Build Split Release APKs
Write-Host "`n📱 Building Release APKs (split-per-abi)..." -ForegroundColor Green
flutter build apk --release --split-per-abi

$ApkDir = Join-Path $AppDir "build\app\outputs\flutter-apk"
if (Test-Path $ApkDir) {
    Write-Host "`n✅ Release APKs generated at: $ApkDir" -ForegroundColor Green
    Get-ChildItem -Path $ApkDir -Filter "*release*.apk" | ForEach-Object {
        $size = $_.Length / 1MB
        Write-Host "   - $($_.Name) ($([math]::Round($size, 2)) MB)" -ForegroundColor Cyan
    }
}

Write-Host "`n🎉 Production release builds completed successfully!" -ForegroundColor Yellow

