param([string]$AutoItDir = $env:AUTOIT_DIR)

if ([string]::IsNullOrWhiteSpace($AutoItDir)) {
    $AutoItDir = 'C:\Program Files\AutoIt3'
}

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$harness = Join-Path $root ('.brave-test-' + [guid]::NewGuid().ToString('N') + '.au3')
$tests = @'
Global $TestFailures = 0
Local $StableVersion = "1.95.101", $BetaVersion = "1.96.53", $NightlyVersion = "1.97.31"
Local $StableUrl = "https://github.com/brave/brave-browser/releases/download/v" & $StableVersion & "/brave-v" & $StableVersion & "-win32-x64.zip"
Local $BetaUrl = "https://github.com/brave/brave-browser/releases/download/v" & $BetaVersion & "/brave-v" & $BetaVersion & "-win32-x64.zip"
Local $NightlyUrl = "https://github.com/brave/brave-browser/releases/download/v" & $NightlyVersion & "/brave-v" & $NightlyVersion & "-win32-x64.zip"
Local $ArchiveJson = '{"schema_version":2,"channels":{' & _
        '"stable":{"version":"' & $StableVersion & '","packages":{"x64":{"zip":{"filename":"brave-v' & $StableVersion & '-win32-x64.zip","url":"' & $StableUrl & '"}}}},' & _
        '"beta":{"version":"' & $BetaVersion & '","packages":{"x64":{"zip":{"filename":"brave-v' & $BetaVersion & '-win32-x64.zip","url":"' & $BetaUrl & '"}}}},' & _
        '"nightly":{"version":"' & $NightlyVersion & '","packages":{"x64":{"zip":{"filename":"brave-v' & $NightlyVersion & '-win32-x64.zip","url":"' & $NightlyUrl & '"}}}}}}'

TestAssert(_BrowserDownloadNormalizeBraveChannel("stable") = "release", "stable maps to release")
TestAssert(_BrowserDownloadNormalizeBraveChannel("default") = "release", "default maps to release")
TestAssert(_BrowserDownloadNormalizeBraveChannel("beta") = "beta", "beta remains beta")
TestAssert(_BrowserDownloadNormalizeBraveChannel("nightly") = "nightly", "nightly remains nightly")
TestAssert(_BrowserDownloadNormalizeChannel($BrowserBrave, "nightly") = "nightly", "shared normalization preserves nightly channel")

_BrowserDownloadConfigure("test", "zh-CN", "", "")
_DownloadToolsConfigure(1, "direct", "", 0, "zh-CN")
Local $MetadataUrls = _BrowserDownloadGetBraveVersionUrls("beta", "win64")
TestAssert(UBound($MetadataUrls) = 2, "metadata source count")
TestAssert($MetadataUrls[0] = $BraveArchiveRawUrl, "BrowserArchive metadata first")
TestAssert($MetadataUrls[1] = $BraveVersionDataOfficialUrl, "official metadata second")
Local $DirectArchiveRoutes = _DownloadToolsBuildUrlCandidates($BraveArchiveRawUrl)
TestAssert(UBound($DirectArchiveRoutes) = 2, "direct BrowserArchive route count")
TestAssert($DirectArchiveRoutes[0] = "https://cdn.jsdmirror.com/gh/benzBrake/BrowserArchive@main/data/brave.json", "direct BrowserArchive uses jsd first")
TestAssert($DirectArchiveRoutes[1] = $BraveArchiveRawUrl, "direct BrowserArchive falls back to GitHub")

_DownloadToolsConfigure(1, "http", "127.0.0.1", 8080, "zh-CN")
Local $ProxyArchiveRoutes = _DownloadToolsBuildUrlCandidates($BraveArchiveRawUrl)
TestAssert(UBound($ProxyArchiveRoutes) = 1 And $ProxyArchiveRoutes[0] = $BraveArchiveRawUrl, "explicit proxy bypasses metadata mirrors")

TestAssert(_BrowserDownloadCacheBraveReleaseInfo($ArchiveJson, "release"), "BrowserArchive stable parses")
TestAssert(_BrowserDownloadGetLatestBraveVersion("release") = $StableVersion, "BrowserArchive stable version")
TestAssert(_BrowserDownloadGetLatestBraveVersion("stable") = $StableVersion, "stable alias reads release cache")
TestAssert($BraveDownloadUrl = $StableUrl And $BraveReleaseChannel = "release", "BrowserArchive stable ZIP")
TestAssert(_BrowserDownloadIsVersionCached($BrowserBrave, "stable"), "stable alias finds release cache")

TestAssert(_BrowserDownloadCacheBraveReleaseInfo($ArchiveJson, "beta"), "BrowserArchive beta parses")
TestAssert(_BrowserDownloadGetLatestBraveVersion("beta") = $BetaVersion, "BrowserArchive beta version")
TestAssert($BraveDownloadUrl = $BetaUrl And $BraveReleaseChannel = "beta", "BrowserArchive beta ZIP")

TestAssert(_BrowserDownloadCacheBraveReleaseInfo($ArchiveJson, "nightly"), "BrowserArchive nightly parses")
TestAssert(_BrowserDownloadGetLatestBraveVersion("nightly") = $NightlyVersion, "BrowserArchive nightly version")
TestAssert($BraveDownloadUrl = $NightlyUrl And $BraveReleaseChannel = "nightly", "BrowserArchive nightly ZIP")

_DownloadToolsConfigure(1, "direct", "", 0, "zh-CN")
Local $DownloadUrls = _BrowserDownloadBuildUrls($BrowserBrave, "nightly", "win64")
TestAssert(IsArray($DownloadUrls) And UBound($DownloadUrls) >= 2, "Brave ZIP uses GitHub download fallback chain")
TestAssert($DownloadUrls[UBound($DownloadUrls) - 1] = $NightlyUrl, "Brave ZIP falls back to official GitHub URL")
TestAssert(Not IsArray(_BrowserDownloadBuildUrls($BrowserBrave, "nightly", "win32")), "unsupported Brave architecture rejected")

Local $OfficialBetaVersion = "1.96.54"
Local $OfficialBetaUrl = "https://github.com/brave/brave-browser/releases/download/v" & $OfficialBetaVersion & "/brave-v" & $OfficialBetaVersion & "-win32-x64.zip"
Local $OfficialJson = '{"' & $OfficialBetaVersion & '":{"tag":"v' & $OfficialBetaVersion & '","channel":"beta","github":{"assets":[{"name":"brave-v' & $OfficialBetaVersion & '-win32-x64.zip","download_url":"' & $OfficialBetaUrl & '"}]}}}'
TestAssert(_BrowserDownloadCacheBraveReleaseInfo($OfficialJson, "beta"), "official brave-versions JSON parses")
TestAssert(_BrowserDownloadGetLatestBraveVersion("beta") = $OfficialBetaVersion, "official beta version")
TestAssert($BraveDownloadUrl = $OfficialBetaUrl, "official beta ZIP")
TestAssert(Not _BrowserDownloadCacheBraveReleaseInfo($OfficialJson, "nightly"), "official metadata does not cross-fallback channels")

Local $GithubVersion = "1.95.102"
Local $GithubUrl = "https://github.com/brave/brave-browser/releases/download/v" & $GithubVersion & "/brave-v" & $GithubVersion & "-win32-x64.zip"
Local $GithubJson = '{"tag_name":"v' & $GithubVersion & '","assets":[{"browser_download_url":"' & $GithubUrl & '"}]}'
TestAssert(Not _BrowserDownloadCacheBraveReleaseInfo($GithubJson, "beta"), "GitHub latest API rejected for beta")
TestAssert(Not _BrowserDownloadCacheBraveReleaseInfo($GithubJson, "nightly"), "GitHub latest API rejected for nightly")
TestAssert(_BrowserDownloadCacheBraveReleaseInfo($GithubJson, "release"), "GitHub latest API accepted for release")
TestAssert(_BrowserDownloadGetLatestBraveVersion("release") = $GithubVersion, "GitHub latest release version")
TestAssert($BraveDownloadUrl = $GithubUrl, "GitHub latest release ZIP")

TestAssert(Not _BrowserDownloadCacheBraveReleaseInfo('{invalid json', "release"), "malformed JSON rejected")
TestAssert(Not _BrowserDownloadCacheBraveReleaseInfo('{"channels":{"stable":{"version":"bad","packages":{"x64":{"zip":{"filename":"brave-vbad-win32-x64.zip","url":"https://github.com/brave/brave-browser/releases/download/vbad/brave-vbad-win32-x64.zip"}}}}}}', "release"), "malformed BrowserArchive version rejected")
TestAssert(Not _BrowserDownloadCacheBraveReleaseInfo('{"channels":{"stable":{"version":"1.95.103","packages":{"x64":{"zip":{"filename":"BraveBrowserStandaloneSetup.exe","url":"https://example.com/BraveBrowserStandaloneSetup.exe"}}}}}}', "release"), "non-portable BrowserArchive asset rejected")
TestAssert(Not _BrowserDownloadCacheBraveReleaseInfo('{"channels":{"stable":{"version":"1.95.103","packages":{"x64":{"zip":{"filename":"brave-v1.95.103-win32-x64.zip","url":"https://github.com/brave/brave-browser/releases/download/v1.95.999/brave-v1.95.103-win32-x64.zip"}}}}}}', "release"), "mismatched BrowserArchive URL rejected")

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
        Write-Output 'Brave download tests passed.'
    }
    finally { Pop-Location }
}
finally { Remove-Item -LiteralPath $harness -Force -ErrorAction SilentlyContinue }
