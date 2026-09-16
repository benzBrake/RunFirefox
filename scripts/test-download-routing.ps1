param([string]$AutoItDir = 'C:\Program Files\AutoIt3')

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$harness = Join-Path $root ('.download-routing-test-' + [guid]::NewGuid().ToString('N') + '.au3')
$tests = @'
Global $TestFailures = 0

Func TestAssert($Condition, $Name)
    If $Condition Then Return
    $TestFailures += 1
    ConsoleWrite("FAIL: " & $Name & @CRLF)
EndFunc

Func AssertRoute($Urls, $ExpectedFirst, $ExpectedSecond, $Name)
    TestAssert(IsArray($Urls), $Name & " returns an array")
    If Not IsArray($Urls) Then Return
    TestAssert(UBound($Urls) = 2, $Name & " has one accelerator and one fallback")
    If UBound($Urls) >= 1 Then TestAssert($Urls[0] = $ExpectedFirst, $Name & " accelerator")
    If UBound($Urls) >= 2 Then TestAssert($Urls[1] = $ExpectedSecond, $Name & " original fallback")
EndFunc

Func AssertGenericRoute($Urls, $UpstreamUrl, $Name)
    TestAssert(IsArray($Urls), $Name & " returns an array")
    If Not IsArray($Urls) Then Return
    TestAssert(UBound($Urls) = 3, $Name & " has two accelerators and one fallback")
    If UBound($Urls) >= 1 Then TestAssert($Urls[0] = $DT_DEFAULT_GENERIC_URL_PROXY & $UpstreamUrl, $Name & " primary accelerator")
    If UBound($Urls) >= 2 Then TestAssert($Urls[1] = $DT_FALLBACK_GENERIC_URL_PROXY & $UpstreamUrl, $Name & " fallback accelerator")
    If UBound($Urls) >= 3 Then TestAssert($Urls[2] = $UpstreamUrl, $Name & " original fallback")
EndFunc

_DownloadToolsConfigure(1, "direct", "", 0, "zh-CN", "", "", "")
Local $Url = "https://cdn.jsdelivr.net/gh/benzBrake/BrowserArchive@main/data/whale.json"
AssertRoute(_DownloadToolsBuildUrlCandidates($Url), "https://cdn.jsdmirror.com/gh/benzBrake/BrowserArchive@main/data/whale.json", $Url, "jsDelivr")

$Url = "https://raw.githubusercontent.com/benzBrake/BrowserArchive/main/data/whale.json"
AssertRoute(_DownloadToolsBuildUrlCandidates($Url), "https://cdn.jsdmirror.com/gh/benzBrake/BrowserArchive@main/data/whale.json", $Url, "GitHub raw")

$Url = "https://github.com/benzBrake/BrowserArchive/raw/main/data/whale.json"
AssertRoute(_DownloadToolsBuildUrlCandidates($Url), "https://cdn.jsdmirror.com/gh/benzBrake/BrowserArchive@main/data/whale.json", $Url, "GitHub raw path")

$Url = "https://raw.githubusercontent.com/benzBrake/BrowserArchive/refs/heads/main/data/whale.json"
AssertRoute(_DownloadToolsBuildUrlCandidates($Url), "https://cdn.jsdmirror.com/gh/benzBrake/BrowserArchive@main/data/whale.json", $Url, "GitHub raw refs path")

$Url = "https://github.com/benzBrake/RunFirefox/releases/download/v2.8.18/RunFirefox_2.8.18.zip"
AssertRoute(_DownloadToolsBuildUrlCandidates($Url), "https://v6.gh-proxy.org/" & $Url, $Url, "GitHub release")

$Url = "https://api.github.com/repos/benzBrake/RunFirefox/releases/latest"
AssertRoute(_DownloadToolsBuildUrlCandidates($Url), "https://gh.dpik.top/" & $Url, $Url, "GitHub API")

$Url = "https://downloads.vivaldi.com/stable/Vivaldi.exe"
AssertGenericRoute(_DownloadToolsBuildUrlCandidates($Url), $Url, "Vivaldi generic proxy")
AssertGenericRoute(_DownloadToolsBuildUrlCandidatesForConfig($Url, "zh-CN", "https://custom.example/", "", "", "https://custom.example/"), $Url, "Simplified Chinese generic proxy is built-in")

Local $ManagedGenericProxyUrl = $DT_FALLBACK_GENERIC_URL_PROXY & $Url
Local $ManagedGenericProxyUrls = _DownloadToolsBuildUrlCandidates($ManagedGenericProxyUrl)
TestAssert(UBound($ManagedGenericProxyUrls) = 1 And $ManagedGenericProxyUrls[0] = $ManagedGenericProxyUrl, "managed oo6 URL is not wrapped again")

$Url = "https://versions.brave.com/latest/brave-versions.json"
AssertGenericRoute(_DownloadToolsBuildUrlCandidates($Url), $Url, "Brave generic proxy")

$Url = "https://get.opera.com/ftp/pub/opera/desktop/135.0.5973.150/win/Opera_135.0.5973.150_Setup_x64.exe"
AssertGenericRoute(_DownloadToolsBuildUrlCandidates($Url), $Url, "Opera generic proxy")

$Url = "https://update.vivaldi.com/update/1.0/public/appcast.x64.xml"
AssertGenericRoute(_DownloadToolsBuildUrlCandidates($Url), $Url, "Vivaldi update generic proxy")

$Url = "https://cv.whale.naver.com/version/latest_version"
AssertGenericRoute(_DownloadToolsBuildUrlCandidates($Url), $Url, "Whale version generic proxy")

_DownloadToolsConfigure(1, "direct", "", 0, "en-US", "", "", "")
$Url = "https://github.com/example/project/releases/download/v1.0.0/file.zip"
Local $Urls = _DownloadToolsBuildUrlCandidates($Url)
TestAssert(UBound($Urls) = 1 And $Urls[0] = $Url, "non-Chinese empty configuration is direct")

_DownloadToolsConfigure(1, "direct", "", 0, "en-US", "https://mirror.example/", "", "")
AssertRoute(_DownloadToolsBuildUrlCandidates($Url), "https://mirror.example/" & $Url, $Url, "non-Chinese explicit GitHub mirror")

$Url = "https://downloads.vivaldi.com/stable/Vivaldi.exe"
Local $GenericUrls = _DownloadToolsBuildUrlCandidatesForConfig($Url, "en-US", "", "", "", "https://proxy.example/")
AssertRoute($GenericUrls, "https://proxy.example/" & $Url, $Url, "non-Chinese explicit generic proxy")
Local $DeduplicatedUrls[1], $DeduplicatedUrlCount = 0
_DownloadToolsAddGenericProxyCandidates($DeduplicatedUrls, $DeduplicatedUrlCount, $Url, "en-us", "https://proxy.example/")
_DownloadToolsAddGenericProxyCandidates($DeduplicatedUrls, $DeduplicatedUrlCount, $Url, "en-us", "https://proxy.example/")
TestAssert($DeduplicatedUrlCount = 1 And $DeduplicatedUrls[0] = "https://proxy.example/" & $Url, "duplicate generic proxy candidates are removed")

_DownloadToolsConfigure(1, "http", "127.0.0.1", 8080, "zh-CN", "", "", "")
$Url = "https://github.com/example/project/releases/download/v1.0.0/file.zip"
$Urls = _DownloadToolsBuildUrlCandidates($Url)
TestAssert(UBound($Urls) = 1 And $Urls[0] = $Url, "user proxy bypasses route mirrors")

_DownloadToolsConfigure(1, "direct", "", 0, "en-US", "https://mirror.example/", "", "")
$Urls = _DownloadToolsBuildUrlCandidates($Url)
TestAssert(UBound($Urls) = 2 And $Urls[0] = "https://mirror.example/" & $Url, "routing survives proxy mode changes")

ConsoleWrite("Failures: " & $TestFailures & @CRLF)
Exit $TestFailures
'@

try {
    [IO.File]::WriteAllText($harness, ('#include "libs\DownloadTools.au3"' + [Environment]::NewLine + $tests), [Text.UTF8Encoding]::new($false))
    Push-Location $root
    try {
        & (Join-Path $AutoItDir 'Au3Check.exe') -q $harness
        if ($LASTEXITCODE) { throw 'Harness static check failed' }
        foreach ($runnerName in @('AutoIt3.exe', 'AutoIt3_x64.exe')) {
            & (Join-Path $AutoItDir $runnerName) /ErrorStdOut $harness | Write-Output
            if ($LASTEXITCODE) { throw "$runnerName tests failed" }
        }
        Write-Output 'Download routing tests passed.'
    }
    finally {
        Pop-Location
    }
}
finally {
    Remove-Item -LiteralPath $harness -Force -ErrorAction SilentlyContinue
}
