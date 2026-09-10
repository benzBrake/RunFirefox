param([string]$AutoItDir = 'C:\Program Files\AutoIt3')

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$temp = Join-Path ([IO.Path]::GetTempPath()) ('RunFirefox-BundledTests-' + [guid]::NewGuid().ToString('N'))
$harness = Join-Path $root ('.bundled-test-' + [guid]::NewGuid().ToString('N') + '.au3')
$tests = @'
#include <String.au3>
Global $TestFailures = 0, $TestError = ""
Global $TestDir = $CmdLine[1]
$ProfileDir = $TestDir & "\profile"
$CustomCacheDir = ""
$BrowserType = $BrowserBrave
$hSettings = GUICreate("Bundled tests", 500, 450)
$idBrowserPath = GUICtrlCreateInput("", 0, 0)
$idChromePlusCurrentCaption = GUICtrlCreateLabel("", 0, 20)
$idChromePlusLatestCaption = GUICtrlCreateLabel("", 0, 40)
$idChromePlusCurrentVersion = GUICtrlCreateLabel("", 0, 60)
$idChromePlusLatestVersion = GUICtrlCreateLabel("", 0, 80)
$idChromePlusHint = GUICtrlCreateLabel("", 0, 100)
$idChromePlusDownloadPatch = GUICtrlCreateButton("", 0, 120)
For $TestArch In StringSplit("x86|x64", "|", 2)
    Local $Source = PrepareBundledChromePlus($TestArch)
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
        TestAssert(GetChromePlusInstalledVersion($Browser) = "alpha-240777f", "raw version")
        TestAssert(IsChromePlusHoverTabSupported($Browser), "hover capability")
        TestAssert(IniRead($Dir & "\chrome++.ini", "tabs", "right_click_close", "") = "1", "launcher defaults")
        UpdateChromePlusVersionLabels()
        BeginChromePlusVersionLoad()
        TestAssert($ChromePlusVersionLoadHandle = 0, "no upstream process")
        TestAssert(GUICtrlRead($idChromePlusLatestVersion) = "alpha-240777f", "bundled version label")
        TestAssert(BitAND(GUICtrlGetState($idChromePlusDownloadPatch), $GUI_DISABLE) <> 0, "identical disabled")
        FileWrite($Dir & "\version.dll", "different build")
        TestAssert(Not IsBundledChromePlusInstalled($Browser), "same version different bytes")
        TestAssert(Not IsChromePlusHoverTabSupported($Browser), "unrecognized alpha has no capability override")
        UpdateChromePlusVersionLabels()
        TestAssert(BitAND(GUICtrlGetState($idChromePlusDownloadPatch), $GUI_ENABLE) <> 0, "replacement enabled")
        FileDelete($Dir & "\chrome++.ini")
        FileWrite($Dir & "\chrome++.ini", "[tabs]" & @LF & "right_click_close=0" & @LF & "custom=retained")
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
TestAssert(GUICtrlRead($idChromePlusLatestVersion) = "alpha-240777f", "upstream cache cannot override bundled label")
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
