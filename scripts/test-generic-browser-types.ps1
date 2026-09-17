param([string]$AutoItDir = 'C:\Program Files\AutoIt3')

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$harness = Join-Path $root ('.generic-browser-types-test-' + [guid]::NewGuid().ToString('N') + '.au3')
$tests = @'
Global $TestFailures = 0

TestEqual(NormalizeBrowserType("other-firefox"), $BrowserOtherFirefox, "normalize other Firefox")
TestEqual(NormalizeBrowserType("Other Chromium"), $BrowserOtherChromium, "normalize other Chromium alias")
TestEqual(NormalizeBrowserType("unknown legacy value"), $BrowserFirefox, "unknown legacy type remains Firefox compatible")

TestEqual(DetectBrowserTypeFromIdentity("C:\Firefox\firefox.exe", "firefox.exe", "Firefox Mozilla Corporation"), $BrowserFirefox, "official Firefox identity")
TestEqual(DetectBrowserTypeFromIdentity("C:\Chrome\chrome.exe", "chrome.exe", "Google Chrome Google LLC"), $BrowserChrome, "official Chrome identity")
TestEqual(DetectBrowserTypeFromIdentity("C:\Portable\Firefox\firefox.exe", "firefox.exe", ""), $BrowserFirefox, "official Firefox default path before download")
TestEqual(DetectBrowserTypeFromIdentity("C:\Portable\Chrome\chrome.exe", "chrome.exe", ""), $BrowserChrome, "official Chrome default path before download")
TestEqual(DetectBrowserTypeFromIdentity("C:\Brave\brave.exe", "brave.exe", "Brave Browser"), $BrowserBrave, "known Chromium fork")
TestEqual(DetectBrowserTypeFromIdentity("C:\Edge\msedge.exe", "msedge.exe", "Microsoft Edge Microsoft Corporation"), $BrowserOtherChromium, "Edge is generic Chromium")
TestEqual(DetectBrowserTypeFromIdentity("C:\Chromium\chrome.exe", "chrome.exe", "Chromium Authors"), $BrowserOtherChromium, "unknown Chromium identity")
TestEqual(DetectBrowserTypeFromIdentity("C:\Mercury\mercury.exe", "mercury.exe", "Mercury Firefox Browser"), $BrowserOtherFirefox, "unknown Firefox fork identity")
TestEqual(DetectBrowserTypeFromIdentity("C:\Portable\FirefoxFork\firefox.exe", "firefox.exe", ""), $BrowserOtherFirefox, "other Firefox default path")
TestEqual(DetectBrowserTypeFromIdentity("C:\Unknown\browser.exe", "browser.exe", "Example Browser"), "", "unknown executable is not reclassified")

TestAssert(IsMozillaBrowser($BrowserOtherFirefox), "other Firefox uses Mozilla behavior")
TestAssert(IsChromeBrowser($BrowserOtherChromium), "other Chromium uses Chromium behavior")
TestAssert(IsBrowserUpdateControlSupported($BrowserOtherFirefox), "other Firefox keeps self-update control")
TestAssert(Not ShouldManageMozillaUpdateChannel($BrowserOtherFirefox), "other Firefox preserves native update channel")
TestAssert(Not IsBrowserUpdateControlSupported($BrowserOtherChromium), "other Chromium has no managed update control")
TestAssert(Not _BrowserAutoUpdateIsSupported($BrowserOtherFirefox), "other Firefox has no managed updater")
TestAssert(Not _BrowserAutoUpdateIsSupported($BrowserOtherChromium), "other Chromium has no managed updater")

TestEqual(GetBrowserTypeByLabel(GetBrowserTypeLabel($BrowserOtherFirefox)), $BrowserOtherFirefox, "other Firefox label round trip")
TestEqual(GetBrowserTypeByLabel(GetBrowserTypeLabel($BrowserOtherChromium)), $BrowserOtherChromium, "other Chromium label round trip")
TestEqual(GetBrowserExecutableName($BrowserOtherFirefox), "firefox.exe", "other Firefox executable")
TestEqual(GetBrowserExecutableName($BrowserOtherChromium), "chrome.exe", "other Chromium executable")
TestEqual(GetDefaultBrowserPath($BrowserOtherFirefox), ".\FirefoxFork\firefox.exe", "other Firefox default path")
TestEqual(GetDefaultBrowserPath($BrowserOtherChromium), ".\Chromium\chrome.exe", "other Chromium default path")

$ProfileDir = "C:\Portable\Profile"
$CustomCacheDir = "C:\Portable\Cache"
$CacheSize = 64
$ChromiumDebugPortEnabled = 1
$ChromiumDebugPort = 9222
$BrowserPath = "C:\Portable\Chromium\chrome.exe"
Local $ChromiumParams = BuildBrowserLaunchParams($BrowserOtherChromium)
TestAssert(StringInStr($ChromiumParams, '--user-data-dir="C:\Portable\Profile"'), "other Chromium portable profile parameter")
TestAssert(StringInStr($ChromiumParams, '--disk-cache-dir="C:\Portable\Cache"'), "other Chromium cache parameter")
TestAssert(StringInStr($ChromiumParams, "--disk-cache-size=67108864"), "other Chromium cache size parameter")
TestAssert(StringInStr($ChromiumParams, "--remote-debugging-port=9222"), "other Chromium CDP parameter")
TestAssert(StringInStr(BuildBrowserLaunchParams($BrowserOtherFirefox), '-profile "C:\Portable\Profile"'), "other Firefox profile parameter")

TestAssert(Not _BrowserDownloadIsSupported($BrowserOtherFirefox), "other Firefox built-in download disabled")
TestAssert(Not _BrowserDownloadIsSupported($BrowserOtherChromium), "other Chromium built-in download disabled")
TestEqual(_BrowserDownloadNormalizeChannel($BrowserOtherFirefox, "release"), "default", "other Firefox channel is unmanaged")
TestEqual(_BrowserDownloadNormalizeChannel($BrowserOtherChromium, "stable"), "default", "other Chromium channel is unmanaged")
TestEqual(_BrowserDownloadGetLatestVersion($BrowserOtherFirefox, "default"), "", "other Firefox latest version unavailable")
TestAssert(Not _BrowserDownloadIsVersionCached($BrowserOtherChromium, "default"), "other Chromium version is never cached")
TestAssert(Not _BrowserDownloadStartVersionLoad($BrowserOtherChromium, "default"), "other Chromium version load does not start")
TestAssert(Not IsArray(_BrowserDownloadBuildUrls($BrowserOtherFirefox, "default", "win64")), "other Firefox has no download URLs")
TestAssert(Not IsArray(_BrowserDownloadBuildUrls($BrowserOtherChromium, "default", "win64")), "other Chromium has no download URLs")
TestEqual(_BrowserDownloadGetPageUrl($BrowserOtherChromium, "default"), "", "other Chromium has no download page fallback")
TestEqual(GetSystemMozillaProfileDir($BrowserOtherFirefox), "", "other Firefox does not guess a system profile")
TestEqual(GetSystemChromiumUserDataDir($BrowserOtherChromium), "", "other Chromium does not guess a system profile")

ConsoleWrite("Failures: " & $TestFailures & @CRLF)
Exit $TestFailures

Func TestAssert($Condition, $Name)
    If $Condition Then Return
    $TestFailures += 1
    ConsoleWrite("FAIL: " & $Name & @CRLF)
EndFunc

Func TestEqual($Actual, $Expected, $Name)
    TestAssert($Actual = $Expected, $Name & " (actual=" & $Actual & ", expected=" & $Expected & ")")
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
        Write-Output 'Generic browser type tests passed.'
    }
    finally { Pop-Location }
}
finally { Remove-Item -LiteralPath $harness -Force -ErrorAction SilentlyContinue }
