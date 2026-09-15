<#
    Chay desktop app native tren Windows (build MSVC that, khong phai web).

    Vi sao can script nay:
      O E: la exFAT -> khong ho tro reparse point, nen Flutter khong tao duoc
      windows/flutter/ephemeral/.plugin_symlinks va build native that bai voi
      ERROR_INVALID_FUNCTION. Script mirror project sang o NTFS (C:) roi chay
      o do. E: van la nguon chinh, C: chi la ban chay.

    Dung:
      .\run-desktop-native.ps1              # dong bo roi chay app
      .\run-desktop-native.ps1 -SyncOnly    # chi dong bo, de bam 'r' hot reload

    ponytail: dong bo thu cong tung lan, khong co file watcher. Hot reload can
    chay -SyncOnly roi bam 'r' trong phien flutter. Nang cap khi thay phien:
    them FileSystemWatcher tu dong sync.
#>
[CmdletBinding()]
param(
    [switch]$SyncOnly,
    [string]$Source,
    [string]$Dest   = 'C:\cs-desktop'
)

$ErrorActionPreference = 'Stop'

# Khong dat default trong param(): chay bang `powershell -File` thi $PSScriptRoot
# rong ben trong param() (quirk Windows PowerShell 5.1), chi co gia tri trong body.
if (-not $Source) { $Source = Join-Path $PSScriptRoot 'crabsensedesktop' }

if (-not (Test-Path (Join-Path $Source 'pubspec.yaml'))) {
    throw "Khong tim thay project desktop tai: $Source"
}

# /MIR xoa file la trong Dest -> chan truong hop tro nham vao thu muc quan trong.
if ((Test-Path $Dest) -and -not (Test-Path (Join-Path $Dest 'pubspec.yaml'))) {
    if (@(Get-ChildItem $Dest -Force -ErrorAction SilentlyContinue).Count -gt 0) {
        throw "Dest '$Dest' da co du lieu khac va se bi /MIR xoa. Kiem tra lai -Dest."
    }
}

Write-Host "=== dong bo $Source -> $Dest ===" -ForegroundColor Cyan
# /XD build .dart_tool: giu lai de incremental build khong phai lam lai tu dau.
# /XD ephemeral: chua .plugin_symlinks - Flutter tu tao lai tren NTFS, dung mirror.
robocopy $Source $Dest /MIR /XD build .dart_tool ephemeral .git /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
$rc = $LASTEXITCODE
if ($rc -ge 8) { throw "robocopy that bai (exit=$rc)" }

# Bat luon neu /XD loai nham thu gi do can thiet.
foreach ($f in 'pubspec.yaml', 'lib\main.dart', '.env') {
    if (-not (Test-Path (Join-Path $Dest $f))) { throw "Dong bo thieu: $f" }
}
Write-Host "  xong (robocopy exit=$rc)" -ForegroundColor Green

if ($SyncOnly) {
    Write-Host ""
    Write-Host "Da dong bo. Bam 'r' trong phien flutter dang chay de hot reload." -ForegroundColor Yellow
    return
}

Push-Location $Dest
try {
    Write-Host ""
    Write-Host "=== flutter run -d windows ===" -ForegroundColor Cyan
    flutter run -d windows
    if ($LASTEXITCODE -ne 0) { throw "flutter run that bai (exit=$LASTEXITCODE)" }
} finally {
    Pop-Location
}
