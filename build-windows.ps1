$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "=== Pulse: сборка установщика Windows ===" -ForegroundColor Cyan
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw "Не найден Node.js. Установите Node.js LTS с https://nodejs.org/ и перезапустите PowerShell." }
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { throw "Не найден npm. Переустановите Node.js с npm." }

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
New-Item -ItemType Directory -Force -Path (Join-Path $root "bin") | Out-Null

$api = "https://api.github.com/repos/SagerNet/sing-box/releases/latest"
Write-Host "Получаю официальный релиз sing-box..."
$release = Invoke-RestMethod -Uri $api -Headers @{ "User-Agent" = "Pulse-Browser-Build" }
$asset = $release.assets | Where-Object { $_.name -match 'windows-amd64.*\.zip$' } | Select-Object -First 1
if (-not $asset) { throw "В последнем релизе sing-box не найден ZIP для Windows amd64. Загрузите официальный sing-box.exe вручную в папку bin." }

$tmp = Join-Path $env:TEMP ("pulse-singbox-" + [guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$archive = Join-Path $tmp $asset.name
Write-Host "Загружаю $($asset.name)..."
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $archive
Expand-Archive -Path $archive -DestinationPath $tmp -Force
$exe = Get-ChildItem -Path $tmp -Filter "sing-box.exe" -Recurse | Select-Object -First 1
if (-not $exe) { throw "В архиве не найден sing-box.exe." }
Copy-Item $exe.FullName (Join-Path $root "bin\sing-box.exe") -Force

Write-Host "Устанавливаю зависимости npm..."
npm install
if ($LASTEXITCODE -ne 0) { throw "npm install завершился с ошибкой." }

Write-Host "Собираю установщик Pulse..."
npm run dist
if ($LASTEXITCODE -ne 0) { throw "Сборка electron-builder завершилась с ошибкой." }

Write-Host "`nГотово. Файл установщика находится в папке dist." -ForegroundColor Green
Get-ChildItem (Join-Path $root "dist") -Filter "Pulse-Setup-*.exe" | Format-Table Name,Length,LastWriteTime
