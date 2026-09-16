param([string]$AutoItDir = 'C:\Program Files\AutoIt3')

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$harness = Join-Path $root ('.opera-test-' + [guid]::NewGuid().ToString('N') + '.au3')
$tests = @'
Global $TestFailures = 0

TestAssert(_BrowserDownloadNormalizeOperaChannel("stable") = "stable", "stable channel")
TestAssert(_BrowserDownloadNormalizeOperaChannel("release") = "stable", "release compatibility")
TestAssert(_BrowserDownloadNormalizeOperaChannel("default") = "stable", "default compatibility")
TestAssert(_BrowserDownloadNormalizeOperaChannel("beta") = "stable", "legacy beta migrates to stable")
TestAssert(_BrowserDownloadNormalizeOperaChannel("dev") = "dev", "developer channel")
TestAssert(_BrowserDownloadNormalizeChannel($BrowserOpera, "dev") = "dev", "shared normalization preserves developer channel")
TestAssert(_BrowserDownloadGetOperaChannelDir("stable") = "opera", "stable FTP directory")
TestAssert(_BrowserDownloadGetOperaChannelDir("dev") = "opera-developer", "developer FTP directory")
TestAssert(_BrowserDownloadHasFallback($BrowserOpera, "stable"), "Opera reports download fallback")
TestAssert(_BrowserDownloadGetOperaListingUrl("stable") = "https://get.opera.com/ftp/pub/opera/desktop/", "stable FTP listing URL")
TestAssert(_BrowserDownloadGetOperaListingUrl("dev") = "https://get.opera.com/ftp/pub/opera-developer/", "developer FTP listing URL")

Local $StableApiUrls = _BrowserDownloadGetOperaVersionUrls("stable")
TestAssert(UBound($StableApiUrls) = 2, "stable API fallback count")
TestAssert($StableApiUrls[0] = $OperaArchiveRawUrl, "stable BrowserArchive URL")
TestAssert(StringInStr($StableApiUrls[1], "autoupdate.geo.opera.com/api/verify?product=Opera") > 0, "stable API official URL")
Local $DevApiUrls = _BrowserDownloadGetOperaVersionUrls("dev")
TestAssert($DevApiUrls[0] = $OperaArchiveRawUrl, "developer BrowserArchive URL")
TestAssert(StringInStr($DevApiUrls[1], "product=Opera%20Developer") > 0, "developer API official URL")

_DownloadToolsConfigure(1, "http", "127.0.0.1", 8080, "zh-CN")
Local $ProxyApiUrls = _BrowserDownloadGetOperaVersionUrls("stable")
TestAssert(UBound($ProxyApiUrls) = 2 And $ProxyApiUrls[0] = $OperaArchiveRawUrl And $ProxyApiUrls[1] = $StableApiUrls[1], "proxy retains archive and official metadata fallback")

Local $ArchiveJson = '{"version":"999.0.0.0","products":{"opera":{"channels":{"stable":{"version":"135.0.5973.142"},"developer":{"version":"137.0.6022.0"}}},"opera_gx":{"channels":{"stable":{"version":"888.0.0.0"}}}}}'
TestAssert(_BrowserDownloadCacheOperaReleaseInfo("stable", $ArchiveJson), "stable BrowserArchive JSON parse")
TestAssert(_BrowserDownloadGetLatestOperaVersion("stable") = "135.0.5973.142", "stable BrowserArchive version")
TestAssert(_BrowserDownloadCacheOperaReleaseInfo("dev", $ArchiveJson), "developer BrowserArchive JSON parse")
TestAssert(_BrowserDownloadGetLatestOperaVersion("dev") = "137.0.6022.0", "developer BrowserArchive version")
TestAssert(_BrowserDownloadCacheOperaReleaseInfo("stable", '{"status":"outdated","current_version":"135.0.5973.150"}'), "stable official JSON fallback parse")
TestAssert(_BrowserDownloadGetLatestOperaVersion("stable") = "135.0.5973.150", "stable official current_version")
TestAssert(_BrowserDownloadCacheOperaReleaseInfo("dev", '{"status":"outdated","current_version":"137.0.6022.1"}'), "developer official JSON fallback parse")
TestAssert(_BrowserDownloadGetLatestOperaVersion("dev") = "137.0.6022.1", "developer official current_version")
TestAssert(Not _BrowserDownloadCacheOperaReleaseInfo("stable", '{"status":"ok"}'), "missing version rejected")
TestAssert(Not _BrowserDownloadCacheOperaReleaseInfo("stable", '{"current_version":"not-a-version"}'), "malformed version rejected")
TestAssert(Not _BrowserDownloadCacheOperaReleaseInfo("stable", '{"version":"777.0.0.0","products":{"opera_gx":{"channels":{"stable":{"version":"777.0.0.0"}}}}}'), "Opera GX and top-level versions rejected")
TestAssert(_BrowserDownloadGetLatestOperaVersion("stable") = "135.0.5973.150", "invalid refresh preserves stable cache")

_DownloadToolsConfigure(1, "direct", "", 0, "zh-CN")
Local $StableUrls = _BrowserDownloadBuildUrls($BrowserOpera, "stable", "win64")
TestAssert(UBound($StableUrls) = 3, "stable download fallback count")
TestAssert($StableUrls[0] = $UPGRADE_DEFAULT_URL_PROXY & "https://get.opera.com/ftp/pub/opera/desktop/135.0.5973.150/win/Opera_135.0.5973.150_Setup_x64.exe", "stable generic proxy download URL")
TestAssert($StableUrls[1] = $DT_FALLBACK_GENERIC_URL_PROXY & "https://get.opera.com/ftp/pub/opera/desktop/135.0.5973.150/win/Opera_135.0.5973.150_Setup_x64.exe", "stable fallback generic proxy download URL")
TestAssert($StableUrls[2] = "https://get.opera.com/ftp/pub/opera/desktop/135.0.5973.150/win/Opera_135.0.5973.150_Setup_x64.exe", "stable official download URL")
Local $DevUrls = _BrowserDownloadBuildUrls($BrowserOpera, "dev", "win64")
TestAssert(UBound($DevUrls) = 3, "developer download fallback count")
TestAssert($DevUrls[0] = $UPGRADE_DEFAULT_URL_PROXY & "https://get.opera.com/ftp/pub/opera-developer/137.0.6022.1/win/Opera_Developer_137.0.6022.1_Setup_x64.exe", "developer generic proxy download URL")
TestAssert($DevUrls[1] = $DT_FALLBACK_GENERIC_URL_PROXY & "https://get.opera.com/ftp/pub/opera-developer/137.0.6022.1/win/Opera_Developer_137.0.6022.1_Setup_x64.exe", "developer fallback generic proxy download URL")
TestAssert($DevUrls[2] = "https://get.opera.com/ftp/pub/opera-developer/137.0.6022.1/win/Opera_Developer_137.0.6022.1_Setup_x64.exe", "developer official download URL")

_DownloadToolsConfigure(1, "http", "127.0.0.1", 8080, "zh-CN")
Local $ProxyUrls = _BrowserDownloadBuildUrls($BrowserOpera, "dev", "win64")
TestAssert(UBound($ProxyUrls) = 1 And $ProxyUrls[0] = $DevUrls[2], "proxy uses official download only")

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
        Write-Output 'Opera download tests passed.'
    }
    finally { Pop-Location }
}
finally { Remove-Item -LiteralPath $harness -Force -ErrorAction SilentlyContinue }
