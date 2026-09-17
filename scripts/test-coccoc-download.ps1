param([string]$AutoItDir = $env:AUTOIT_DIR)

if ([string]::IsNullOrWhiteSpace($AutoItDir)) {
    $AutoItDir = 'C:\Program Files\AutoIt3'
}

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$harness = Join-Path $root ('.coccoc-test-' + [guid]::NewGuid().ToString('N') + '.au3')
$tests = @'
Global $TestFailures = 0
Local $Version = "152.0.7977.124"
Local $Filename = "coccoc-" & $Version & "-win-x64.zip"
Local $ArchiveUrl = "https://archive.org/download/coccoc-archive-" & $Version & "/" & $Filename
Local $Sha256 = "1bdfec56f4c30d2f05f882d3fd68d0eca14767a4838f2a7d1473617e9563eb35"
Local $ArchiveJson = '{"name":"Cốc Cốc","version":"' & $Version & '","files":{"x64":{"filename":"' & $Filename & '","sha256":"' & $Sha256 & '","url":"' & $ArchiveUrl & '"}}}'

TestAssert(_BrowserDownloadCacheCocCocReleaseInfo($ArchiveJson), "valid BrowserArchive JSON parses")
TestEqual(_BrowserDownloadGetLatestCocCocVersion(), $Version, "latest version")
TestEqual($CocCocDownloadFilename, $Filename, "ZIP filename")
TestEqual($CocCocDownloadUrl, $ArchiveUrl, "ZIP URL")
TestEqual(_BrowserDownloadGetExpectedSha256($BrowserCocCoc, "release", "win64"), $Sha256, "ZIP SHA-256")

TestAssert(Not _BrowserDownloadCacheCocCocReleaseInfo('{"version":"bad","files":{"x64":{"filename":"' & $Filename & '","sha256":"' & $Sha256 & '","url":"' & $ArchiveUrl & '"}}}'), "invalid version rejected")
TestAssert(Not _BrowserDownloadCacheCocCocReleaseInfo('{"version":"' & $Version & '","files":{}}'), "missing x64 rejected")
TestAssert(Not _BrowserDownloadCacheCocCocReleaseInfo('{"version":"' & $Version & '","files":{"x64":{"filename":"wrong.zip","sha256":"' & $Sha256 & '","url":"' & $ArchiveUrl & '"}}}'), "wrong filename rejected")
TestAssert(Not _BrowserDownloadCacheCocCocReleaseInfo('{"version":"' & $Version & '","files":{"x64":{"filename":"' & $Filename & '","sha256":"' & $Sha256 & '","url":"https://example.com/' & $Filename & '"}}}'), "untrusted URL rejected")
TestAssert(Not _BrowserDownloadCacheCocCocReleaseInfo('{"version":"' & $Version & '","files":{"x64":{"filename":"' & $Filename & '","sha256":"bad","url":"' & $ArchiveUrl & '"}}}'), "invalid SHA-256 rejected")
TestEqual(_BrowserDownloadGetLatestCocCocVersion(), $Version, "invalid refresh preserves valid cache")

_BrowserDownloadConfigure("test", "zh-CN", "", "")
_DownloadToolsConfigure(1, "direct", "", 0, "zh-CN")
Local $MetadataRoutes = _DownloadToolsBuildUrlCandidates($CocCocArchiveRawUrl)
TestAssert(UBound($MetadataRoutes) = 2, "metadata uses one mirrored route and raw fallback")
TestEqual($MetadataRoutes[0], "https://cdn.jsdmirror.com/gh/benzBrake/BrowserArchive@main/data/coccoc.json", "metadata mirror maps the sole source")
TestEqual($MetadataRoutes[1], $CocCocArchiveRawUrl, "metadata raw fallback")
Local $DownloadUrls = _BrowserDownloadBuildUrls($BrowserCocCoc, "release", "win64")
TestAssert(IsArray($DownloadUrls) And UBound($DownloadUrls) = 1, "one logical ZIP source")
TestEqual($DownloadUrls[0], $ArchiveUrl, "ZIP source comes from metadata")
Local $DownloadRoutes = _DownloadToolsBuildUrlCandidates($DownloadUrls[0])
TestAssert(UBound($DownloadRoutes) = 3, "ZIP uses standard acceleration routes")
TestEqual($DownloadRoutes[2], $ArchiveUrl, "ZIP routes fall back to metadata URL")
TestAssert(Not IsArray(_BrowserDownloadBuildUrls($BrowserCocCoc, "release", "win32")), "x86 rejected")
TestAssert(Not IsArray(_BrowserDownloadBuildUrls($BrowserCocCoc, "release", "arm64")), "ARM64 rejected")
TestAssert(Not _BrowserDownloadStartVersionLoad($BrowserCocCoc, "release", "win32"), "x86 version load rejected")
TestAssert(Not _BrowserDownloadIsVersionCached($BrowserCocCoc, "release", "win32"), "x86 cache rejected")

TestEqual(NormalizeBrowserType("Coc Coc"), $BrowserCocCoc, "ASCII alias normalization")
TestEqual(GetBrowserTypeByLabel(GetBrowserTypeLabel($BrowserCocCoc)), $BrowserCocCoc, "localized label round trip")
TestEqual(GetBrowserExecutableName($BrowserCocCoc), "browser.exe", "browser executable")
TestEqual(GetDefaultBrowserPath($BrowserCocCoc), ".\CocCoc\browser.exe", "default path")
TestEqual(DetectBrowserTypeFromIdentity("C:\Portable\CocCoc\browser.exe", "browser.exe", ""), $BrowserCocCoc, "default path detection")
TestEqual(DetectBrowserTypeFromIdentity("C:\Portable\Browser\browser.exe", "browser.exe", "Coc Coc Company Limited"), $BrowserCocCoc, "version identity detection")
TestEqual(DetectBrowserTypeFromIdentity("C:\Portable\Browser\browser.exe", "browser.exe", "CocCoc Browser"), $BrowserCocCoc, "compact version identity detection")
TestAssert(IsChromeBrowser($BrowserCocCoc), "Chromium behavior")
TestAssert(IsChromePlusSupportedBrowser($BrowserCocCoc), "Bush2021 Chrome++ supported")
TestAssert(IsChromePlusSupportedExecutable("browser.exe"), "browser executable supports Chrome++")
TestEqual(GetChromePlusConfigPath("C:\Portable\CocCoc\browser.exe"), "C:\Portable\CocCoc\chrome++.ini", "Chrome++ config path")
TestAssert(_BrowserAutoUpdateIsSupported($BrowserCocCoc), "managed update supported")

Local $ProfileRoot = @TempDir & "\RunFirefox_CocCoc_Profile_" & @AutoItPID
Local $SystemUserData = $ProfileRoot & "\CocCoc\Browser\User Data"
DirCreate($SystemUserData)
FileWrite($SystemUserData & "\Local State", "{}")
TestEqual(GetCocCocSystemUserDataDir($ProfileRoot), $SystemUserData, "system profile directory")
FileDelete($SystemUserData & "\Local State")
TestEqual(GetCocCocSystemUserDataDir($ProfileRoot), "", "system profile requires Local State")
DirRemove($ProfileRoot, 1)

Local $ExtractRoot = @TempDir & "\RunFirefox_CocCoc_Extract_" & @AutoItPID
DirCreate($ExtractRoot & "\CocCoc")
FileWrite($ExtractRoot & "\CocCoc\browser.exe", "test")
TestEqual(_BrowserDownloadFindBrowserExecutableForType($ExtractRoot, $BrowserCocCoc), $ExtractRoot & "\CocCoc\browser.exe", "archive browser layout")
TestEqual(GetChromePlusPatchPath($ExtractRoot & "\CocCoc\browser.exe"), $ExtractRoot & "\CocCoc\version.dll", "Chrome++ patch path")
FileWrite($ExtractRoot & "\CocCoc\version.dll", "test")
TestAssert(IsChromePlusPatchInstalled($ExtractRoot & "\CocCoc\browser.exe"), "Chrome++ installation detected")
DirRemove($ExtractRoot, 1)

Local $Gui = GUICreate("Coc Coc controls", 240, 100)
$idBrowserBitness = GUICtrlCreateCombo("", 0, 0, 100, 24)
$idChannel = GUICtrlCreateCombo("", 0, 30, 100, 24)
UpdateBrowserBitnessControl($BrowserCocCoc)
TestEqual(GUICtrlRead($idBrowserBitness), "x64", "bitness fixed to x64")
TestAssert(BitAND(GUICtrlGetState($idBrowserBitness), $GUI_DISABLE) <> 0, "bitness selector disabled")
UpdateBrowserChannelOptions($BrowserCocCoc, "beta")
TestEqual(GUICtrlRead($idChannel), "release", "channel fixed to release")
GUIDelete($Gui)
$idBrowserBitness = 0
$idChannel = 0

Local $EmptyFile = @TempDir & "\RunFirefox_CocCoc_Empty_" & @AutoItPID & ".tmp"
Local $Handle = FileOpen($EmptyFile, 18)
FileClose($Handle)
TestAssert(_DownloadToolsFileMatchesSha256($EmptyFile, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"), "valid SHA-256 accepted")
TestAssert(Not _DownloadToolsFileMatchesSha256($EmptyFile, $Sha256), "wrong SHA-256 rejected")
FileDelete($EmptyFile)

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
        Write-Output 'Coc Coc download tests passed.'
    }
    finally { Pop-Location }
}
finally { Remove-Item -LiteralPath $harness -Force -ErrorAction SilentlyContinue }
