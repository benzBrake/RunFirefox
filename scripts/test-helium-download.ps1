param([string]$AutoItDir = $env:AUTOIT_DIR)

if ([string]::IsNullOrWhiteSpace($AutoItDir)) {
    $AutoItDir = 'C:\Program Files\AutoIt3'
}

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$harness = Join-Path $root ('.helium-test-' + [guid]::NewGuid().ToString('N') + '.au3')
$tests = @'
Global $TestFailures = 0
Local $ArchiveJson = '{"name":"Helium","version":"0.17.0.1","source":"https://github.com/imputnet/helium-windows/releases/tag/0.17.0.1","files":[{"filename":"helium_0.17.0.1_x64-windows.zip","url":"https://github.com/imputnet/helium-windows/releases/download/0.17.0.1/helium_0.17.0.1_x64-windows.zip"}]}'

Local $MetadataUrls = _BrowserDownloadGetHeliumVersionUrls()
TestAssert(UBound($MetadataUrls) = 3, "Helium metadata fallback count")
TestAssert($MetadataUrls[0] = $HeliumArchiveRawUrl, "BrowserArchive metadata first")
TestAssert($MetadataUrls[1] = $HeliumLatestReleaseUrl, "GitHub release page second")
TestAssert($MetadataUrls[2] = $HeliumLatestReleaseApiUrl, "GitHub release API last")

_BrowserDownloadConfigure("test", "zh-CN", "", "https://cdn.jsdelivr.net/gh/")
_DownloadToolsConfigure(1, "direct", "", 0, "zh-CN")
Local $DirectArchiveRoutes = _DownloadToolsBuildUrlCandidates($MetadataUrls[0])
TestAssert(UBound($DirectArchiveRoutes) = 2, "direct BrowserArchive route count")
TestAssert($DirectArchiveRoutes[0] = "https://cdn.jsdmirror.com/gh/benzBrake/BrowserArchive@main/data/helium.json", "direct BrowserArchive uses jsd first")
TestAssert($DirectArchiveRoutes[1] = $HeliumArchiveRawUrl, "direct BrowserArchive falls back to GitHub raw")

_DownloadToolsConfigure(1, "http", "127.0.0.1", 8080, "zh-CN")
Local $ProxyArchiveRoutes = _DownloadToolsBuildUrlCandidates($MetadataUrls[0])
TestAssert(UBound($ProxyArchiveRoutes) = 1 And $ProxyArchiveRoutes[0] = $HeliumArchiveRawUrl, "explicit proxy uses BrowserArchive raw URL")
Local $ProxyMetadataUrls = _BrowserDownloadGetHeliumVersionUrls()
TestAssert(UBound($ProxyMetadataUrls) = 3 And $ProxyMetadataUrls[0] = $HeliumArchiveRawUrl, "explicit proxy preserves metadata priority")

TestAssert(_BrowserDownloadCacheHeliumReleaseInfo($ArchiveJson), "BrowserArchive JSON parses")
TestAssert(_BrowserDownloadGetLatestHeliumVersion() = "0.17.0.1", "BrowserArchive version")
TestAssert($HeliumReleaseTag = "0.17.0.1", "BrowserArchive version becomes release tag")
Local $ExpectedDownloadUrl = "https://github.com/imputnet/helium-windows/releases/download/0.17.0.1/helium_0.17.0.1_x64-windows.zip"
TestAssert(_BrowserDownloadBuildHeliumDownloadUrl("release", "win64") = $ExpectedDownloadUrl, "BrowserArchive version builds official x64 ZIP URL")

TestAssert(_BrowserDownloadCacheHeliumReleaseInfo('{"tag_name":"v0.17.0.2"}'), "GitHub API tag parses")
TestAssert(_BrowserDownloadGetLatestHeliumVersion() = "0.17.0.2", "GitHub API version")
TestAssert(_BrowserDownloadCacheHeliumReleaseInfo('<a href="/imputnet/helium-windows/releases/tag/0.17.0.3">release</a>'), "GitHub release page tag parses")
TestAssert(_BrowserDownloadGetLatestHeliumVersion() = "0.17.0.3", "GitHub release page version")

TestAssert(Not _BrowserDownloadCacheHeliumReleaseInfo('{"name":"Helium","source":"https://github.com/imputnet/helium-windows/releases/tag/9.9.9.9"}'), "BrowserArchive JSON without version is rejected")
TestAssert(Not _BrowserDownloadCacheHeliumReleaseInfo('{"name":"Helium","version":"latest","source":"https://github.com/imputnet/helium-windows/releases/tag/9.9.9.9"}'), "malformed BrowserArchive version is rejected")
TestAssert(Not _BrowserDownloadCacheHeliumReleaseInfo('{invalid json'), "malformed JSON is rejected")

ConsoleWrite("Failures: " & $TestFailures & @CRLF)
Exit $TestFailures

Func TestAssert($Condition, $Name)
    If $Condition Then Return
    $TestFailures += 1
    ConsoleWrite("FAIL: " & $Name & @CRLF)
EndFunc
'@

try {
    $source = [IO.File]::ReadAllText((Join-Path $root 'RunFirefox.au3'))
    $source = $source.Replace('#include "libs\LangData.au3"', 'Global Const $g_sLangDataIni = ""')
    $marker = 'If Not @AutoItX64 Then ; 32-bit Autoit'
    if (-not $source.Contains($marker)) { throw 'Test insertion point missing' }
    $source = $source.Replace($marker, $tests + "`n" + $marker)
    [IO.File]::WriteAllText($harness, $source, [Text.UTF8Encoding]::new($false))
    Push-Location $root
    try {
        & (Join-Path $AutoItDir 'Au3Check.exe') -q $harness
        if ($LASTEXITCODE) { throw 'Harness static check failed' }
        foreach ($runnerName in @('AutoIt3.exe', 'AutoIt3_x64.exe')) {
            & (Join-Path $AutoItDir $runnerName) /ErrorStdOut $harness | Write-Output
            if ($LASTEXITCODE) { throw "$runnerName tests failed" }
        }
        Write-Output 'Helium download tests passed.'
    }
    finally { Pop-Location }
}
finally { Remove-Item -LiteralPath $harness -Force -ErrorAction SilentlyContinue }
