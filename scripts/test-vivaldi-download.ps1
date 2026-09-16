param([string]$AutoItDir = 'C:\Program Files\AutoIt3')

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$harness = Join-Path $root ('.vivaldi-test-' + [guid]::NewGuid().ToString('N') + '.au3')
$tests = @'
Global $TestFailures = 0
Local $StableXml = '{"channels":{"stable":{"version":"8.2.4133.52","files":{"x64":{"url":"https://downloads.vivaldi.com/stable-auto/Vivaldi.8.2.4133.52.x64.exe"}}}}}'
Local $SnapshotXml = '{"channels":{"snapshot":{"version":"8.3.4157.3","files":{"x64":{"url":"https://downloads.vivaldi.com/snapshot-auto/Vivaldi.8.3.4157.3.x64.exe"}}}}}'

TestAssert(_BrowserDownloadNormalizeVivaldiChannel("release") = "stable", "legacy release maps to stable")
TestAssert(_BrowserDownloadNormalizeVivaldiChannel("default") = "stable", "default maps to stable")
TestAssert(_BrowserDownloadNormalizeVivaldiChannel("snapshot") = "snapshot", "snapshot remains snapshot")
TestAssert(_BrowserDownloadNormalizeChannel($BrowserVivaldi, "snapshot") = "snapshot", "shared normalization preserves snapshot channel")
Local $ChannelGui = GUICreate("Vivaldi channel test", 200, 100)
$idChannel = GUICtrlCreateCombo("", 0, 0, 180, 24)
UpdateBrowserChannelOptions($BrowserVivaldi, "release")
TestAssert(GUICtrlRead($idChannel) = "stable", "legacy UI channel migrates to stable")
UpdateBrowserChannelOptions($BrowserVivaldi, "snapshot")
TestAssert(GUICtrlRead($idChannel) = "snapshot", "snapshot UI channel remains selected")
GUIDelete($ChannelGui)

Local $StableUpdateUrls = _BrowserDownloadGetVivaldiUpdateUrls("stable")
TestAssert(UBound($StableUpdateUrls) = 2 And $StableUpdateUrls[0] = $VivaldiArchiveRawUrl And $StableUpdateUrls[1] = "https://update.vivaldi.com/update/1.0/public/appcast.x64.xml", "archive metadata fallback URL")
Local $SnapshotUpdateUrls = _BrowserDownloadGetVivaldiUpdateUrls("snapshot")
TestAssert(UBound($SnapshotUpdateUrls) = 2 And $SnapshotUpdateUrls[0] = $VivaldiArchiveRawUrl And $SnapshotUpdateUrls[1] = "https://update.vivaldi.com/update/1.0/win/appcast.x64.xml", "snapshot archive metadata fallback URL")

TestAssert(_BrowserDownloadCacheVivaldiReleaseInfo("stable", $StableXml), "stable appcast parses")
TestAssert(_BrowserDownloadGetLatestVivaldiVersion("stable") = "8.2.4133.52", "stable version")
TestAssert(_BrowserDownloadGetVivaldiDownloadUrl("stable") = "https://downloads.vivaldi.com/stable-auto/Vivaldi.8.2.4133.52.x64.exe", "stable full installer ignores delta")
TestAssert(_BrowserDownloadCacheVivaldiReleaseInfo("snapshot", $SnapshotXml), "snapshot appcast parses")
TestAssert(_BrowserDownloadGetLatestVivaldiVersion("snapshot") = "8.3.4157.3", "snapshot version")
TestAssert(_BrowserDownloadGetLatestVivaldiVersion("release") = "8.2.4133.52", "channel caches stay isolated")
TestAssert(Not _BrowserDownloadCacheVivaldiReleaseInfo("stable", $SnapshotXml), "stable rejects snapshot package")
TestAssert(Not _BrowserDownloadCacheVivaldiReleaseInfo("stable", '{"channels":{"stable":{"version":"8.2.4133.52","files":{"x64":{"url":"https://example.com/stable-auto/Vivaldi.8.2.4133.52.x64.exe"}}}}}'), "unofficial host rejected")
TestAssert(Not _BrowserDownloadCacheVivaldiReleaseInfo("stable", '{"channels":{"stable":{"version":"8.2.4133.52","files":{"x64":{"url":"https://downloads.vivaldi.com/snapshot-auto/Vivaldi.8.2.4133.52.x64.exe"}}}}}'), "wrong channel path rejected")
TestAssert(Not _BrowserDownloadCacheVivaldiReleaseInfo("stable", '{"channels":{"stable":{"version":"8.2.4133.52","files":{"x64":{"url":"https://downloads.vivaldi.com/stable-auto/Vivaldi.8.2.4133.99.x64.exe"}}}}}'), "mismatched filename version rejected")
TestAssert(Not _BrowserDownloadCacheVivaldiReleaseInfo("stable", '{"channels":{"stable":{"version":"8.2.4133.52","files":{"x86":{"url":"https://downloads.vivaldi.com/stable-auto/Vivaldi.8.2.4133.52.x86.exe"}}}}}'), "missing x64 package rejected")
TestAssert(Not _BrowserDownloadCacheVivaldiReleaseInfo("stable", '{"channels":{"stable":{"version":"latest","files":{"x64":{"url":"https://downloads.vivaldi.com/stable-auto/Vivaldi.latest.x64.exe"}}}}}'), "malformed version rejected")
TestAssert(_BrowserDownloadGetLatestVivaldiVersion("stable") = "8.2.4133.52", "invalid refresh preserves stable cache")

_DownloadToolsConfigure(1, "direct", "", 0)
Local $DownloadUrls = _BrowserDownloadBuildUrls($BrowserVivaldi, "snapshot", "win64")
TestAssert(UBound($DownloadUrls) = 1, "direct download uses official URL")
TestAssert($DownloadUrls[0] = "https://downloads.vivaldi.com/snapshot-auto/Vivaldi.8.3.4157.3.x64.exe", "download official URL")
_DownloadToolsConfigure(1, "http", "127.0.0.1", 8080)
Local $ProxyDownloadUrls = _BrowserDownloadBuildUrls($BrowserVivaldi, "snapshot", "win64")
TestAssert(UBound($ProxyDownloadUrls) = 1 And $ProxyDownloadUrls[0] = $DownloadUrls[0], "proxy uses official URL")

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
        Write-Output 'Vivaldi download tests passed.'
    }
    finally {
        Pop-Location
    }
}
finally {
    Remove-Item -LiteralPath $harness -Force -ErrorAction SilentlyContinue
}
