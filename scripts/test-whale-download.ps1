param([string]$AutoItDir = $env:AUTOIT_DIR)

if ([string]::IsNullOrWhiteSpace($AutoItDir)) {
    $AutoItDir = 'C:\Program Files\AutoIt3'
}

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$harness = Join-Path $root ('.whale-test-' + [guid]::NewGuid().ToString('N') + '.au3')
$tests = @'
Global $TestFailures = 0
Local $ArchiveX86Url = "https://archive.org/download/whale-archive-4.39.410.14/WhaleSetupX86.exe"
Local $ArchiveX64Url = "https://archive.org/download/whale-archive-4.39.410.14/WhaleSetupX64.exe"
Local $ArchiveJson = '{"name":"Naver Whale","version":"4.39.410.14","files":{"x86":{"filename":"WhaleSetupX86.exe","sha256":"unused","url":"' & $ArchiveX86Url & '"},"x64":{"filename":"WhaleSetupX64.exe","sha256":"unused","url":"' & $ArchiveX64Url & '"}}}'

Local $BitnessGui = GUICreate("Whale bitness test", 200, 100)
$idBrowserBitness = GUICtrlCreateCombo("", 0, 0, 180, 24)
UpdateBrowserBitnessControl($BrowserWhale)
TestAssert(GUICtrlRead($idBrowserBitness) = "x64", "Whale bitness defaults to x64")
_GUICtrlComboBox_SelectString($idBrowserBitness, "x86")
UpdateBrowserBitnessControl($BrowserWhale)
TestAssert(GUICtrlRead($idBrowserBitness) = "x86", "Whale bitness preserves x86 selection")
TestAssert(BitAND(GUICtrlGetState($idBrowserBitness), $GUI_ENABLE) <> 0, "Whale bitness selector enabled")
UpdateBrowserBitnessControl($BrowserFirefox)
TestAssert(GUICtrlRead($idBrowserBitness) = "x64", "unsupported browser resets bitness")
TestAssert(BitAND(GUICtrlGetState($idBrowserBitness), $GUI_DISABLE) <> 0, "unsupported browser bitness disabled")
GUIDelete($BitnessGui)
$idBrowserBitness = 0

_BrowserDownloadConfigure("test", "zh-CN", "", "https://cdn.jsdelivr.net/gh/")
_DownloadToolsConfigure(1, "direct", "", 0, "zh-CN")
Local $MetadataUrls = _BrowserDownloadGetWhaleVersionUrls()
TestAssert(UBound($MetadataUrls) = 3, "direct metadata fallback count")
TestAssert($MetadataUrls[0] = "https://cdn.jsdmirror.com/gh/benzBrake/BrowserArchive@main/data/whale.json", "China jsd metadata first")
TestAssert($MetadataUrls[1] = $WhaleArchiveRawUrl, "GitHub raw metadata fallback")
TestAssert($MetadataUrls[2] = $WhaleLatestVersionUrl, "legacy Naver metadata last")

$BD_LoadHandle = 1
$BD_LoadBrowserType = $BrowserWhale
$BD_LoadChannel = "release"
$BD_LoadOs = "win32"
TestAssert(_BrowserDownloadIsVersionLoadActive($BrowserWhale, "release", "win32"), "x86 request matches active load")
TestAssert(Not _BrowserDownloadIsVersionLoadActive($BrowserWhale, "release", "win64"), "x64 request stays isolated from x86 load")
$BD_LoadHandle = 0

_DownloadToolsConfigure(1, "http", "127.0.0.1", 8080, "zh-CN")
Local $ProxyMetadataUrls = _BrowserDownloadGetWhaleVersionUrls()
TestAssert(UBound($ProxyMetadataUrls) = 2, "proxy metadata fallback count")
TestAssert($ProxyMetadataUrls[0] = $WhaleArchiveRawUrl, "proxy uses GitHub raw first")
TestAssert($ProxyMetadataUrls[1] = $WhaleLatestVersionUrl, "proxy retains legacy Naver fallback")

TestAssert(_BrowserDownloadCacheWhaleReleaseInfo($ArchiveJson), "BrowserArchive JSON parses")
TestAssert(_BrowserDownloadGetLatestWhaleVersion() = "4.39.410.14", "BrowserArchive version")
TestAssert($WhaleDownloadX86Url = $ArchiveX86Url, "BrowserArchive x86 URL")
TestAssert($WhaleDownloadX64Url = $ArchiveX64Url, "BrowserArchive x64 URL")
_DownloadToolsConfigure(1, "direct", "", 0, "zh-CN")
Local $DownloadX86Urls = _BrowserDownloadBuildUrls($BrowserWhale, "release", "win32")
TestAssert(UBound($DownloadX86Urls) = 4, "Whale x86 download fallback count")
TestAssert($DownloadX86Urls[0] = $UPGRADE_DEFAULT_URL_PROXY & $ArchiveX86Url, "generic proxy x86 archive download first")
TestAssert($DownloadX86Urls[1] = $DT_FALLBACK_GENERIC_URL_PROXY & $ArchiveX86Url, "fallback generic proxy x86 archive download second")
TestAssert($DownloadX86Urls[2] = $ArchiveX86Url, "versioned x86 archive fallback third")
TestAssert($DownloadX86Urls[3] = $WhaleStandaloneX86Url, "Naver x86 installer fallback last")
Local $DownloadX64Urls = _BrowserDownloadBuildUrls($BrowserWhale, "release", "win64")
TestAssert(UBound($DownloadX64Urls) = 4, "Whale x64 download fallback count")
TestAssert($DownloadX64Urls[0] = $UPGRADE_DEFAULT_URL_PROXY & $ArchiveX64Url, "generic proxy x64 archive download first")
TestAssert($DownloadX64Urls[1] = $DT_FALLBACK_GENERIC_URL_PROXY & $ArchiveX64Url, "fallback generic proxy x64 archive download second")
TestAssert($DownloadX64Urls[2] = $ArchiveX64Url, "versioned x64 archive fallback third")
TestAssert($DownloadX64Urls[3] = $WhaleStandaloneX64Url, "Naver x64 installer fallback last")
_DownloadToolsConfigure(1, "http", "127.0.0.1", 8080, "zh-CN")
Local $ProxyDownloadUrls = _BrowserDownloadBuildUrls($BrowserWhale, "release", "win64")
TestAssert(UBound($ProxyDownloadUrls) = 2, "explicit proxy Whale download fallback count")
TestAssert($ProxyDownloadUrls[0] = $ArchiveX64Url And $ProxyDownloadUrls[1] = $WhaleStandaloneX64Url, "explicit proxy bypasses generic URL proxy")

TestAssert(Not _BrowserDownloadCacheWhaleReleaseInfo('{"version":"bad","files":{"x86":{"url":"' & $ArchiveX86Url & '"},"x64":{"url":"' & $ArchiveX64Url & '"}}}'), "malformed version rejected")
TestAssert(Not _BrowserDownloadCacheWhaleReleaseInfo('{"version":"4.40.0.0","files":{"x64":{"url":"https://archive.org/download/whale-archive-4.40.0.0/WhaleSetupX64.exe"}}}'), "missing x86 file rejected")
TestAssert(Not _BrowserDownloadCacheWhaleReleaseInfo('{invalid json'), "malformed JSON rejected")
TestAssert(_BrowserDownloadGetLatestWhaleVersion() = "4.39.410.14", "invalid refresh preserves version")
TestAssert($WhaleDownloadX86Url = $ArchiveX86Url, "invalid refresh preserves x86 download URL")
TestAssert($WhaleDownloadX64Url = $ArchiveX64Url, "invalid refresh preserves x64 download URL")

TestAssert(_BrowserDownloadCacheWhaleReleaseInfo('{"@version":"4.40.0.0"}'), "legacy Naver response parses")
TestAssert(_BrowserDownloadGetLatestWhaleVersion() = "4.40.0.0", "legacy Naver version")
TestAssert($WhaleDownloadX86Url = "" And $WhaleDownloadX64Url = "", "legacy response clears versioned URLs")
Local $FallbackX86Urls = _BrowserDownloadBuildUrls($BrowserWhale, "release", "win32")
TestAssert(UBound($FallbackX86Urls) = 1 And $FallbackX86Urls[0] = $WhaleStandaloneX86Url, "legacy metadata uses Naver x86 installer only")
Local $FallbackX64Urls = _BrowserDownloadBuildUrls($BrowserWhale, "release", "win64")
TestAssert(UBound($FallbackX64Urls) = 1 And $FallbackX64Urls[0] = $WhaleStandaloneX64Url, "legacy metadata uses Naver x64 installer only")
TestAssert(Not IsArray(_BrowserDownloadBuildUrls($BrowserWhale, "release", "arm64")), "unsupported architecture rejected")

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
        Write-Output 'Whale download tests passed.'
    }
    finally { Pop-Location }
}
finally { Remove-Item -LiteralPath $harness -Force -ErrorAction SilentlyContinue }
