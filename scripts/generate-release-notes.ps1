param(
    [string]$Tag = '',
    [string]$ChineseChangelogPath = '.\CHANGELOG.md',
    [string]$EnglishChangelogPath = '.\docs\CHANGELOG-en_US.md',
    [string]$OutputPath = '.\release-notes.md',
    [switch]$ValidateOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-Sections([string]$Path, [string]$Language) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "$Language changelog does not exist: $Path" }
    $sections = [ordered]@{}
    $current = $null
    foreach ($line in @(Get-Content -LiteralPath $Path)) {
        if ($line -match '^## \[(?<version>\d+\.\d+\.\d+)\] - (?<date>\d{4}-\d{2}-\d{2})\s*$') {
            $current = $Matches.version
            if ($sections.Contains($current)) { throw "$Language changelog contains duplicate version [$current]." }
            $sections[$current] = [pscustomobject]@{ Date = $Matches.date; Lines = [System.Collections.Generic.List[string]]::new() }
        } elseif ($line -match '^##\s+') {
            if ($line.Trim() -ne '## Historical') { throw "$Language changelog contains an invalid level-two heading: $($line.Trim())" }
            $current = $null
        } elseif ($null -ne $current) { $sections[$current].Lines.Add($line) }
    }
    if ($sections.Count -eq 0) { throw "$Language changelog contains no version sections." }
    foreach ($item in $sections.GetEnumerator()) {
        $text = ($item.Value.Lines -join "`n").Trim()
        if ([string]::IsNullOrWhiteSpace($text)) { throw "$Language changelog section [$($item.Key)] is empty." }
        $item.Value.Lines = $text
    }
    return $sections
}

$zh = Read-Sections $ChineseChangelogPath 'Chinese'
$en = Read-Sections $EnglishChangelogPath 'English'
if (($zh.Keys -join "`n") -ne ($en.Keys -join "`n")) { throw 'Chinese and English changelog versions or ordering do not match.' }
foreach ($version in $zh.Keys) { if ($zh[$version].Date -ne $en[$version].Date) { throw "Changelog dates do not match for [$version]." } }
if ($ValidateOnly) { Write-Host "Validated $($zh.Count) matching changelog versions."; exit 0 }
if ([string]::IsNullOrWhiteSpace($Tag)) { throw 'Tag is required unless -ValidateOnly is specified.' }
$version = $Tag -replace '^v', ''
if (-not $zh.Contains($version)) { throw "Chinese changelog does not contain version [$version]." }
$notes = @('## 中文','',$zh[$version].Lines,'','## English','',$en[$version].Lines) -join "`n"
Set-Content -LiteralPath $OutputPath -Value $notes -Encoding utf8
Write-Host "Generated release notes for v$version at $OutputPath"
