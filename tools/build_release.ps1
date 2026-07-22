# Android 正式包快速打包脚本 (PowerShell)
# 使用说明：
# 1. 默认打单架构 arm64 极速包：.\tools\build_release.ps1
# 2. 打全架构分包 APK：.\tools\build_release.ps1 -Split

param (
    [switch]$Split
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 开始构建 Android Release 正式包 " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($Split) {
    Write-Host "[信息] 使用 --split-per-abi 分包模式构建..." -ForegroundColor Yellow
    flutter build apk --release --split-per-abi
} else {
    Write-Host "[信息] 默认使用 arm64-v8a 目标架构极速构建（跳过无关架构 AOT 编译）..." -ForegroundColor Green
    flutter build apk --release --target-platform android-arm64
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host " 构建完成！产物路径: build\app\outputs\flutter-apk\" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host "`n[错误] 打包失败，请检查编译日志。" -ForegroundColor Red
}
