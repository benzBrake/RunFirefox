param([string]$AutoItDir = $env:AUTOIT_DIR)

if ([string]::IsNullOrWhiteSpace($AutoItDir)) {
    $AutoItDir = 'C:\Program Files\AutoIt3'
}

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$temp = Join-Path ([IO.Path]::GetTempPath()) ('RunFirefox-BundledTests-' + [guid]::NewGuid().ToString('N'))
$harness = Join-Path $root ('.bundled-test-' + [guid]::NewGuid().ToString('N') + '.au3')
$tests = @'
#include <String.au3>
Global $TestFailures = 0, $TestError = ""
Global $TestDir = $CmdLine[1]
EnvSet("APP", $TestDir & "\expanded-app")
Opt("ExpandEnvStrings", 1)
Global $ChromePlusAppPlaceholder = Chr(37) & "app" & Chr(37)
$ProfileDir = $TestDir & "\profile"
$CustomCacheDir = ""
$BrowserType = $BrowserBrave
$hSettings = GUICreate("Bundled tests", 500, 450)
$idBrowserPath = GUICtrlCreateInput("", 0, 0)
$idUtf8Title = GUICtrlCreateInput("", 0, 0)
$idChromePlusCurrentCaption = GUICtrlCreateLabel("", 0, 20)
$idChromePlusLatestCaption = GUICtrlCreateLabel("", 0, 40)
$idChromePlusCurrentVersion = GUICtrlCreateLabel("", 0, 60)
$idChromePlusLatestVersion = GUICtrlCreateLabel("", 0, 80)
$idChromePlusHint = GUICtrlCreateLabel("", 0, 100)
$idChromePlusDownloadPatch = GUICtrlCreateButton("", 0, 120)
Local $OriginalBrowserPath = $BrowserPath, $OriginalBrowserDirectory = $BrowserDirectory
Local $ChildEnvOutput = $TestDir & "\child-env.txt"
$BrowserPath = @ComSpec
$BrowserDirectory = $TestDir
Local $ChildPID = RunBrowserProcess('/d /c "if defined APP (echo inherited) else (echo clean)>' & $ChildEnvOutput & '"')
ProcessWaitClose($ChildPID, 5)
TestAssert(StringStripWS(FileRead($ChildEnvOutput), 3) = "clean", "browser child does not inherit RunFirefox APP")
TestAssert(EnvGet("APP") = $TestDir & "\expanded-app", "browser launch restores RunFirefox APP")
FileDelete($ChildEnvOutput)
$BrowserPath = $OriginalBrowserPath
$BrowserDirectory = $OriginalBrowserDirectory
Local $Utf8Fixture = $TestDir & "\utf8-no-bom.ini"
Local $Utf8FixtureFile = FileOpen($Utf8Fixture, BitOR($FO_OVERWRITE, $FO_BINARY))
; Keep a Chrome++ %app% placeholder in the fixture. With ExpandEnvStrings enabled,
; encoding detection must compare the original bytes without expanding it.
FileWrite($Utf8FixtureFile, Binary("0x5B67656E6572616C5D0D0A646174615F6469723D25617070255C2E2E5C70726F66696C65730D0A5B746162735D0D0A6E65775F7461625F64697361626C655F6E616D653D2261626F75743A626C616E6B222C22E696B0E5BBBAE6A087E7ADBE220D0A"))
FileClose($Utf8FixtureFile)
Local $ExpectedUtf8Title = Chr(34) & "about:blank" & Chr(34) & "," & Chr(34) & ChrW(0x65B0) & ChrW(0x5EFA) & ChrW(0x6807) & ChrW(0x7B7E) & Chr(34)
TestAssert(GetTextFileEncodingMode($Utf8Fixture) = BitOR($FO_OVERWRITE, $FO_UTF8_NOBOM), "UTF-8 no-BOM detection ignores app placeholder expansion")
Local $ReadUtf8Title = ReadIniTextValue($Utf8Fixture, "tabs", "new_tab_disable_name", "")
TestAssert($ReadUtf8Title = $ExpectedUtf8Title, "UTF-8 no-BOM bytes decode to Unicode code points")
Local $ExpansionWasRestoredAfterRead = Opt("ExpandEnvStrings", 0) = 1
Opt("ExpandEnvStrings", 1)
TestAssert($ExpansionWasRestoredAfterRead, "UTF-8 text read restores environment expansion")
GUICtrlSetData($idUtf8Title, $ReadUtf8Title)
TestAssert(GUICtrlRead($idUtf8Title) = $ExpectedUtf8Title, "UTF-8 title survives GUI control assignment")
TestAssert('"about:blank","新建标签"' = $ExpectedUtf8Title, "UTF-8 source literal compiles to Unicode code points")
Local $ReleaseConfigSource = $TestDir & "\release-chrome++.ini"
Local $ReleaseConfigTarget = $TestDir & "\release-target\chrome++.ini"
DirCreate($TestDir & "\release-target")
FileWrite($ReleaseConfigSource, "; Upstream release configuration" & @CRLF & "[general]" & @CRLF & "data_dir=none" & @CRLF & "cache_dir=none" & @CRLF & "[tabs]" & @CRLF & "right_click_close=0")
TestAssert(InstallChromePlusConfig($ReleaseConfigSource, $ReleaseConfigTarget), "install release config template")
TestAssert(StringInStr(FileRead($ReleaseConfigTarget), "; Upstream release configuration") > 0, "release config comments installed")
TestAssert(IniRead($ReleaseConfigTarget, "general", "data_dir", "") <> "none", "release config receives portable profile path")
For $TestArch In StringSplit("x86|x64", "|", 2)
    Local $Source = PrepareBundledChromePlus($TestArch)
    Local $ExpectedBundledVersion = ReadExecutableVersionField($Source, "ProductVersion")
    TestAssert($Source <> "", "resource " & $TestArch)
    TestAssert(GetChromePlusPEArch($Source) = $TestArch, "PE " & $TestArch)
    For $TestBrowser In StringSplit("brave|whale", "|", 2)
        Local $Dir = $TestDir & "\" & $TestBrowser & "-" & $TestArch
        DirCreate($Dir)
        Local $Browser = $Dir & "\" & $TestBrowser & ".exe"
        FileCopy($Source, $Browser, 9)
        GUICtrlSetData($idBrowserPath, $Browser)
        TestAssert(UsesBundledChromePlus($Browser), "route " & $TestBrowser)
        TestAssert(InstallChromePlusPatchInteractive($Browser, "arm64"), "install using actual PE architecture")
        TestAssert(IsBundledChromePlusInstalled($Browser), "installed hash")
        TestAssert(GetChromePlusInstalledVersion($Browser) = $ExpectedBundledVersion, "raw version")
        TestAssert(IsChromePlusHoverTabSupported($Browser), "hover capability")
        TestAssert(IniRead($Dir & "\chrome++.ini", "tabs", "right_click_close", "") = "0", "bundled config defaults")
        Local $ExpansionWasRestored = Opt("ExpandEnvStrings", 0) = 1
        Local $ManagedConfig = FileRead($Dir & "\chrome++.ini")
        TestAssert(StringInStr($ManagedConfig, "; This file is the configuration file of Chrome++") > 0, "bundled config comments installed")
        TestAssert(StringInStr($ManagedConfig, "BraveSoftware\Update") > 0, "bundled config variant installed")
        TestAssert(StringLeft($ManagedConfig, StringLen("; Managed by RunFirefox for Chrome++")) <> "; Managed by RunFirefox for Chrome++", "compact managed config not generated")
        Local $ManagedPlaceholderPreserved = StringInStr($ManagedConfig, "data_dir=" & $ChromePlusAppPlaceholder & "\") > 0
        Local $ManagedPlaceholderExpanded = StringInStr($ManagedConfig, $TestDir & "\expanded-app") > 0
        Opt("ExpandEnvStrings", 1)
        TestAssert($ManagedPlaceholderPreserved, "managed config preserves Chrome++ app placeholder")
        TestAssert(Not $ManagedPlaceholderExpanded, "managed config does not expand RunFirefox APP")
        TestAssert($ExpansionWasRestored, "managed config restores environment expansion")
        Local $Utf8Title = '"about:blank","新建标签"'
        TestAssert(WriteIniTextValue($Dir & "\chrome++.ini", "tabs", "new_tab_disable_name", $Utf8Title), "UTF-8 title write")
        TestAssert(ReadIniTextValue($Dir & "\chrome++.ini", "tabs", "new_tab_disable_name", "") = $Utf8Title, "UTF-8 title round trip")
        FileDelete($Dir & "\chrome++.ini")
        FileWrite($Dir & "\chrome++.ini", "; Managed by RunFirefox for Chrome++" & @CRLF & "[tabs]" & @CRLF & "right_click_close=1")
        TestAssert(InstallChromePlusPatchInteractive($Browser), "replace legacy managed config")
        Local $MigratedConfig = FileRead($Dir & "\chrome++.ini")
        TestAssert(StringInStr($MigratedConfig, "; This file is the configuration file of Chrome++") > 0, "legacy managed config migrated to bundled template")
        TestAssert(IniRead($Dir & "\chrome++.ini", "tabs", "right_click_close", "") = "0", "migrated config uses bundled defaults")
        UpdateChromePlusVersionLabels()
        BeginChromePlusVersionLoad()
        TestAssert($ChromePlusVersionLoadHandle = 0, "no upstream process")
        TestAssert(GUICtrlRead($idChromePlusLatestVersion) = $ExpectedBundledVersion, "bundled version label")
        TestAssert(BitAND(GUICtrlGetState($idChromePlusDownloadPatch), $GUI_DISABLE) <> 0, "identical disabled")
        FileWrite($Dir & "\version.dll", "different build")
        TestAssert(Not IsBundledChromePlusInstalled($Browser), "same version different bytes")
        TestAssert(Not IsChromePlusHoverTabSupported($Browser), "unrecognized alpha has no capability override")
        UpdateChromePlusVersionLabels()
        TestAssert(BitAND(GUICtrlGetState($idChromePlusDownloadPatch), $GUI_ENABLE) <> 0, "replacement enabled")
        FileDelete($Dir & "\chrome++.ini")
        FileWrite($Dir & "\chrome++.ini", "[tabs]" & @LF & "right_click_close=0" & @LF & "custom=retained")
        TestAssert(WriteChromePlusPortablePaths($Dir & "\chrome++.ini"), "update portable paths")
        $ExpansionWasRestored = Opt("ExpandEnvStrings", 0) = 1
        Local $UpdatedConfig = FileRead($Dir & "\chrome++.ini")
        Local $UpdatedPlaceholderPreserved = StringInStr($UpdatedConfig, "data_dir=" & $ChromePlusAppPlaceholder & "\") > 0
        Opt("ExpandEnvStrings", 1)
        TestAssert($UpdatedPlaceholderPreserved, "updated config preserves Chrome++ app placeholder")
        TestAssert($ExpansionWasRestored, "portable path update restores environment expansion")
        TestAssert(InstallChromePlusPatchInteractive($Browser), "replace")
        TestAssert(IniRead($Dir & "\chrome++.ini", "tabs", "custom", "") = "retained", "custom config retained")
        Local $Lock = DllCall("kernel32.dll", "handle", "CreateFileW", "wstr", $Dir & "\version.dll", "dword", 0x80000000, "dword", 0, "ptr", 0, "dword", 3, "dword", 0, "ptr", 0)
        TestAssert($Lock[0] <> Ptr(-1), "lock fixture")
        $TestError = ""
        TestAssert(Not InstallChromePlusPatchInteractive($Browser), "locked DLL fails")
        TestAssert($TestError <> "", "failure diagnostic")
        DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $Lock[0])
    Next
Next
Local $Unsupported = $TestDir & "\brave.exe"
FileWrite($Unsupported, Binary("0x4D5A" & _StringRepeat("00", 58) & "40000000" & "5045000064AA" & _StringRepeat("00", 18)))
TestAssert(GetChromePlusPEArch($Unsupported) = "arm64", "ARM64 detection")
TestAssert(Not InstallChromePlusPatchInteractive($Unsupported), "ARM64 rejected")
FileDelete($Unsupported)
FileWrite($Unsupported, "invalid executable")
TestAssert(GetChromePlusPEArch($Unsupported) = "", "unknown PE")
TestAssert(Not InstallChromePlusPatchInteractive($Unsupported), "unknown rejected")
TestAssert(PrepareBundledChromePlus("arm64") = "", "no ARM64 resource")
TestAssert(Not UsesBundledChromePlus($TestDir & "\chrome.exe"), "upstream route")
GUICtrlSetData($idBrowserPath, $TestDir & "\brave-x64\brave.exe")
$ChromePlusReleaseInfoLoaded = True
$ChromePlusReleaseTag = "v99.0.0"
UpdateChromePlusVersionLabels()
TestAssert(GUICtrlRead($idChromePlusLatestVersion) = ReadExecutableVersionField(PrepareBundledChromePlus("x64"), "ProductVersion"), "upstream cache cannot override bundled label")
GUICtrlSetData($idBrowserPath, $TestDir & "\chrome.exe")
$BrowserType = $BrowserChrome
UpdateChromePlusVersionLabels()
TestAssert(GUICtrlRead($idChromePlusLatestVersion) = "99.0.0", "switch back to upstream")
If @Compiled Then
    Local $Cached = PrepareBundledChromePlus("x64")
    FileCopy(PrepareBundledChromePlus("x86"), $Cached, 9)
    TestAssert(PrepareBundledChromePlus("x64") = "", "incorrect extracted architecture rejected")
    FileDelete($Cached)
    TestAssert(PrepareBundledChromePlus("x64") <> "", "missing extracted resource restored")
EndIf
GUIDelete($hSettings)
ConsoleWrite("Failures: " & $TestFailures & @CRLF)
Exit $TestFailures

Func TestAssert($Condition, $Name)
    If $Condition Then Return
    $TestFailures += 1
    ConsoleWrite("FAIL: " & $Name & @CRLF)
EndFunc
'@

try {
    New-Item -ItemType Directory -Path $temp | Out-Null
    $source = [IO.File]::ReadAllText((Join-Path $root 'RunFirefox.au3'))
    # The generated language string is large enough to overflow Au3Check's parser stack;
    # these tests exercise fallback texts only, so omit it from the temporary harness.
    $source = $source.Replace('#include "libs\LangData.au3"', 'Global Const $g_sLangDataIni = ""')
    $source = $source.Replace('Global Const $ChromePlusCacheRoot = @TempDir & "\RunFirefox_ChromePlus"', 'Global Const $ChromePlusCacheRoot = "' + $temp + '\logs"')
    $marker = 'If Not @AutoItX64 Then ; 32-bit Autoit'
    if (-not $source.Contains($marker)) { throw 'Test insertion point missing' }
    $source = $source.Replace($marker, $tests + "`n" + $marker)
    $source = [regex]::Replace($source, '(?ms)^Func ShowChromePlusPatchInstallFailedDialog\([^\r\n]*\).*?^EndFunc[^\r\n]*', "Func ShowChromePlusPatchInstallFailedDialog(`$ErrorMessage, `$LogPath)`n`$TestError = `$ErrorMessage`nEndFunc")
    [IO.File]::WriteAllText($harness, $source, [Text.UTF8Encoding]::new($false))
    Push-Location $root
    try {
        & (Join-Path $AutoItDir 'Au3Check.exe') -q $harness
        if ($LASTEXITCODE) { throw 'Harness static check failed' }
        foreach ($arch in @('x86', 'x64')) {
            $runner = Join-Path $AutoItDir $(if ($arch -eq 'x86') { 'AutoIt3.exe' } else { 'AutoIt3_x64.exe' })
            $fixture = Join-Path $temp "source-$arch"
            New-Item -ItemType Directory -Path $fixture | Out-Null
            & $runner /ErrorStdOut $harness $fixture | Write-Output
            if ($LASTEXITCODE) { throw "Source $arch tests failed" }
            $exe = Join-Path $temp "test-$arch.exe"
            $compiler = Join-Path $AutoItDir 'Aut2Exe\Aut2exe.exe'
            $process = Start-Process -FilePath $compiler -ArgumentList @('/in', ('"' + $harness + '"'), '/out', ('"' + $exe + '"'), "/$arch", '/console') -WindowStyle Hidden -PassThru -Wait
            if ($process.ExitCode -or -not (Test-Path $exe)) { throw "Compile $arch failed" }
            $fixture = Join-Path $temp "compiled-$arch"
            New-Item -ItemType Directory -Path $fixture | Out-Null
            & $exe $fixture | Write-Output
            if ($LASTEXITCODE) { throw "Compiled $arch tests failed" }
            Write-Output "$arch source and compiled tests passed"
        }
    } finally { Pop-Location }
} finally {
    Remove-Item -LiteralPath $harness -Force -ErrorAction SilentlyContinue
    if ((Split-Path $temp -Parent) -eq [IO.Path]::GetTempPath().TrimEnd('\')) {
        Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
    }
}
