# 从 Lang.ini 生成 libs/LangData.au3（内嵌语言数据）
# 用法: pwsh -File .\scripts\update-langdata.ps1
# 修改 Lang.ini 后必须重新运行本脚本，否则编译出的 exe 仍使用旧文案。

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root 'Lang.ini'
$target = Join-Path $root 'libs\LangData.au3'

if (-not (Test-Path $source)) {
    throw "Lang.ini not found: $source"
}

$content = Get-Content -Raw -Encoding UTF8 $source
$content = $content -replace "`r`n", "`n" -replace "`r", "`n"
$content = $content.TrimEnd("`n")

$lines = $content -split "`n"
$parts = foreach ($line in $lines) {
    '"' + ($line -replace '"', '""') + '"'
}

$out = @()
$out += '; 本文件由 scripts/update-langdata.ps1 从 Lang.ini 自动生成，请勿手工编辑。'
$out += '; 修改 Lang.ini 后重新运行该脚本即可同步。'
$out += ''

# AutoIt 3.3.14 overflows its parser stack on one very long concatenation.
$chunkSize = 120
$chunkNames = @()
for ($start = 0; $start -lt $parts.Count; $start += $chunkSize) {
    $end = [Math]::Min($start + $chunkSize - 1, $parts.Count - 1)
    $chunkName = '$g_sLangDataIniPart' + ($chunkNames.Count + 1)
    $chunkNames += $chunkName
    $chunkBody = (@($parts[$start..$end]) -join ' & @CRLF & _' + "`n")
    if ($end -lt $parts.Count - 1) {
        $chunkBody += ' & @CRLF'
    }
    $out += "Global Const $chunkName = _"
    $out += $chunkBody
    $out += ''
}

$out += 'Global Const $g_sLangDataIni = _'
$out += ($chunkNames -join ' & _' + "`n")

$utf8Bom = [System.Text.UTF8Encoding]::new($true)
[System.IO.File]::WriteAllText($target, ($out -join "`n") + "`n", $utf8Bom)

Write-Host "Generated $target from $source ($($lines.Count) lines)"
