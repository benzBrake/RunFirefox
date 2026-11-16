param([string]$AutoItDir = $env:AUTOIT_DIR)

if ([string]::IsNullOrWhiteSpace($AutoItDir)) {
    $AutoItDir = 'C:\Program Files\AutoIt3'
}

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$harness = Join-Path $root ('.command-line-settings-test-' + [guid]::NewGuid().ToString('N') + '.au3')
$source = [IO.File]::ReadAllText((Join-Path $root 'RunFirefox.au3'))
function Get-SourceBlock([string]$Start, [string]$End) {
    $first = $source.IndexOf($Start, [StringComparison]::Ordinal)
    $last = $source.IndexOf($End, $first, [StringComparison]::Ordinal)
    if ($first -lt 0 -or $last -le $first) { throw "Test source block missing: $Start" }
    $source.Substring($first, $last - $first)
}

$tests = @'
Global $TestFailures = 0
$inifile = @TempDir & "\runfirefox-params-" & @AutoItPID & ".ini"
$LANGUAGE = "zh-CN"
$Params = "--remote-debugging-port=9333 --custom-option"
IniWrite($inifile, "Settings", "Params", $Params)
ReadTestSettings()
TestAssert($ParamsEnabled = 1, "legacy configuration defaults to enabled")
For $Enabled = 0 To 1
    For $Browser In StringSplit("firefox|chrome", "|", 2)
        $BrowserType = $Browser
        $ParamsEnabled = $Enabled
        Local $Args[1] = [0]
        Local $Expected = ""
        If $Enabled Then $Expected = $Params
        TestAssert(LaunchTestParams($Args) == $Expected, "custom arguments follow switch")
        Local $External[3] = [2, "https://example.test/a b", "--external"]
        TestAssert(LaunchTestParams($External) == ($Expected & ' "https://example.test/a b" "--external"'), "external arguments remain quoted and forwarded")
        Local $Url[3] = [2, "--jump-url", "https://example.test/a b"]
        TestAssert(LaunchTestParams($Url) == ($Expected & ' "https://example.test/a b"'), "Jump List URL remains forwarded")
        Local $Actions = StringSplit("new-tab|new-window|private-window", "|", 2)
        Local $FirefoxActions[3] = [" -new-tab about:blank", " -new-window about:blank", " -private-window"]
        Local $ChromeActions[3] = [" about:blank", " --new-window about:blank", " --incognito"]
        For $i = 0 To 2
            Local $Action[4] = [3, "--jump-action", $Actions[$i], "--external"]
            Local $Suffix = $FirefoxActions[$i]
            If $Browser = "chrome" Then $Suffix = $ChromeActions[$i]
            TestAssert(LaunchTestParams($Action) == ($Expected & $Suffix & ' "--external"'), "Jump List action remains forwarded")
        Next
        TestAssert($Params == "--remote-debugging-port=9333 --custom-option", "launch does not mutate saved custom arguments")
        $ProfileDir = "test-profile"
        $BrowserPath = "nonexistent-browser.exe"
        $ChromiumDebugPortEnabled = 1
        $ChromiumDebugPort = 9222
        $FirefoxDebugPortEnabled = 1
        $FirefoxDebugPort = 9222
        Local $Base = BuildBrowserLaunchParams($Browser)
        TestAssert(StringInStr($Base, "test-profile") > 0 And StringInStr($Base, "--remote-debugging-port=9222") > 0, "generated portable and debugging arguments remain active")
        TestAssert(CdpTestConflict() = $Enabled, "CDP conflict only checks enabled custom arguments")
        TestAssert(FirefoxTestConflict() = $Enabled, "Firefox conflict only checks enabled custom arguments")
    Next
Next

$LANG_DATA = LoadLangData()
For $TestLanguage In StringSplit("zh-CN|en-US|zh-TW|es-ES", "|", 2)
$LANGUAGE = $TestLanguage
$hSettings = GUICreate("Command line settings test", 500, 580)
_ALInit($hSettings)
Local $iBrowserDebugHelpH = 28
$ParamsEnabled = 1
__GUI__
Local $CaptionPos = ControlGetPos($hSettings, "", $idCommandLineCaption)
Local $SwitchPos = ControlGetPos($hSettings, "", $idParamsEnabled)
TestAssert($SwitchPos[0] >= $CaptionPos[0] + $CaptionPos[2] And $SwitchPos[0] + $SwitchPos[2] <= 480, "localized switch fits beside caption: " & $TestLanguage)
TestAssert(ReadIniCacheValue($LANG_DATA, $TestLanguage, "EnableCommandLineArguments", "missing") <> "missing" Or $TestLanguage = "zh-CN", "localized checkbox caption exists")
TestAssert(ReadIniCacheValue($LANG_DATA, $TestLanguage, "EnableCommandLineArgumentsTooltip", "missing") <> "missing" Or $TestLanguage = "zh-CN", "localized checkbox tooltip exists")
TestAssert(GUICtrlRead($idParamsEnabled) = $GUI_CHECKED, "checkbox initially checked")
TestAssert(BitAND(GUICtrlGetState($idParams), $GUI_ENABLE) <> 0, "editor initially enabled")
GUICtrlSetState($idParamsEnabled, $GUI_UNCHECKED)
RefreshCommandLineArgumentsState()
TestAssert(BitAND(GUICtrlGetState($idParams), $GUI_DISABLE) <> 0, "editor disabled when switch off")
Local $var
__SAVE_READ__
__SAVE_WRITE__
$Params = ""
$ParamsEnabled = 1
ReadTestSettings()
TestAssert($ParamsEnabled = 0 And StringInStr($Params, "--custom-option") > 0, "disabled setting and text survive save and reload: " & $ParamsEnabled & "; " & $Params)
GUICtrlSetState($idParamsEnabled, $GUI_CHECKED)
RefreshCommandLineArgumentsState()
__SAVE_READ__
__SAVE_WRITE__
ReadTestSettings()
TestAssert($ParamsEnabled = 1 And StringInStr($Params, "--custom-option") > 0, "re-enabling restores saved arguments: " & $ParamsEnabled & "; " & $Params)
GUIDelete($hSettings)
Next
FileDelete($inifile)
ConsoleWrite("Command line settings failures: " & $TestFailures & @CRLF)
Exit $TestFailures

Func TestAssert($Condition, $Name)
    If $Condition Then Return
    $TestFailures += 1
    ConsoleWrite("FAIL: " & $Name & @CRLF)
EndFunc
Func ReadTestSettings()
__READ__
EndFunc
Func LaunchTestParams(ByRef $Arguments)
__LAUNCH__
    Return $EffectiveParams
EndFunc
Func CdpTestConflict()
    Return __CDP__
EndFunc
Func FirefoxTestConflict()
    Return __FIREFOX__
EndFunc
'@

$tests = $tests.Replace('__GUI__', (Get-SourceBlock 'Local $sCommandLineCaption = ' "`n`t; 网络"))
$tests = $tests.Replace('__READ__', (Get-SourceBlock '$Params = IniRead(' '$ChromiumDebugPortEnabled = IniRead('))
$tests = $tests.Replace('__LAUNCH__', (Get-SourceBlock 'Local $EffectiveParams = ' 'Local $BrowserIsRunning = ').Replace('$cmdline', '$Arguments'))
$tests = $tests.Replace('__SAVE_READ__', (Get-SourceBlock '$var = GUICtrlRead($idParams)' 'If GUICtrlRead($idChromiumDebugPortEnabled)'))
$tests = $tests.Replace('__SAVE_WRITE__', (Get-SourceBlock 'IniWrite($inifile, "Settings", "Params", $Params)' 'IniWrite($inifile, "Settings", "ChromiumDebugPortEnabled",'))
foreach ($pair in @(@('__CDP__', 'HasCustomCdpParameter'), @('__FIREFOX__', 'HasCustomFirefoxRemoteParameter'))) {
    $condition = [regex]::Match($source, '(?m)^\s*If (.+\b' + $pair[1] + '\(\$Params\)) Then').Groups[1].Value
    if (-not $condition) { throw "Missing conflict condition: $($pair[1])" }
    $tests = $tests.Replace($pair[0], $condition)
}
$marker = 'If Not @AutoItX64 Then ; 32-bit Autoit'
if (-not $source.Contains($marker)) { throw 'Test insertion point missing' }
try {
    [IO.File]::WriteAllText($harness, $source.Replace($marker, $tests + "`n" + $marker), [Text.UTF8Encoding]::new($false))
    & (Join-Path $AutoItDir 'Au3Check.exe') -q $harness
    if ($LASTEXITCODE) { throw 'Harness static check failed' }
    foreach ($runner in @('AutoIt3.exe', 'AutoIt3_x64.exe')) {
        & (Join-Path $AutoItDir $runner) /ErrorStdOut $harness | Write-Output
        if ($LASTEXITCODE) { throw "$runner command line settings tests failed" }
    }
}
finally {
    Remove-Item -LiteralPath $harness -Force -ErrorAction SilentlyContinue
}
