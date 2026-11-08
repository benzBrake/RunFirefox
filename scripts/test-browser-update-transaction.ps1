param([string]$AutoItDir = $env:AUTOIT_DIR)
if ([string]::IsNullOrWhiteSpace($AutoItDir)) { $AutoItDir = 'C:\Program Files\AutoIt3' }
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$harness = Join-Path $root ('.browser-transaction-test-' + [guid]::NewGuid().ToString('N') + '.au3')
$temp = Join-Path ([IO.Path]::GetTempPath()) ('RunFirefoxTransaction-' + [guid]::NewGuid().ToString('N'))
$utf8 = [Text.UTF8Encoding]::new($false)
$children = [Collections.Generic.List[Diagnostics.Process]]::new()

function Assert($condition, $message) { if (-not $condition) { throw $message } }
function Fixture($name, [bool]$existing = $true) {
    $dir = Join-Path $temp $name
    [IO.Directory]::CreateDirectory("$dir\source") | Out-Null
    [IO.File]::WriteAllText("$dir\source\browser.exe", 'new', $utf8)
    if ($existing) {
        [IO.Directory]::CreateDirectory("$dir\App") | Out-Null
        [IO.File]::WriteAllText("$dir\App\browser.exe", 'old', $utf8)
        [IO.File]::WriteAllText("$dir\App\obsolete", 'obsolete', $utf8)
        [IO.File]::WriteAllText("$dir\App\chrome++.ini", 'custom', $utf8)
        [IO.File]::WriteAllText("$dir\App\version.dll", 'custom-dll', $utf8)
    }
    return $dir
}
function StartChild($mode, $dir, $point = '') {
    $args = @('/ErrorStdOut', ('"' + $harness + '"'), $mode, ('"' + $dir + '"'), $point)
    $p = Start-Process -FilePath $script:runner -ArgumentList $args -WindowStyle Hidden -PassThru -RedirectStandardOutput "$dir\$mode-$point.out" -RedirectStandardError "$dir\$mode-$point.err"
    $children.Add($p)
    return $p
}
function RunChild($mode, $dir) {
    $p = StartChild $mode $dir
    Assert ($p.WaitForExit(30000)) "Child timeout: $mode $dir"
    $p.Refresh()
    return $p.ExitCode
}
function CrashAt($dir, $point, $mode = 'replace') {
    $p = StartChild $mode $dir $point
    $timer = [Diagnostics.Stopwatch]::StartNew()
    while (-not (Test-Path -LiteralPath "$dir\ready")) {
        if ($p.HasExited) { throw "Child exited before $point : $(Get-Content "$dir\$mode-$point.err" -Raw)" }
        if ($timer.ElapsedMilliseconds -gt 30000) { throw "Checkpoint timeout: $point" }
        Start-Sleep -Milliseconds 30
    }
    Stop-Process -Id $p.Id -Force
    $p.WaitForExit()
}
function AssertRecovered($dir, [bool]$committed, [bool]$existing = $true) {
    Assert ((RunChild 'recover' $dir) -eq 0) "Recovery failed: $dir"
    Assert ((RunChild 'recover' $dir) -eq 0) "Repeated recovery failed: $dir"
    if ($committed -or $existing) {
        $expected = if ($committed) { 'new' } else { 'old' }
        Assert ([IO.File]::ReadAllText("$dir\App\browser.exe") -eq $expected) "Wrong recovered version: $dir"
    } else { Assert (-not (Test-Path "$dir\App")) "New target was not rolled back: $dir" }
    Assert (-not (Test-Path "$dir\App.RunFirefoxUpdate.ini")) "Journal not removed: $dir"
    Assert (@(Get-ChildItem -LiteralPath $dir -Filter 'App.RunFirefoxNew_*').Count -eq 0) 'New tree left behind'
    Assert (@(Get-ChildItem -LiteralPath $dir -Filter 'App.RunFirefoxOld_*').Count -eq 0) 'Old tree left behind'
}

try {
    [IO.Directory]::CreateDirectory($temp) | Out-Null
    $module = [IO.File]::ReadAllText("$root\libs\BrowserAutoUpdate.au3").Replace("`r`n", "`n")
    # Instrument only the disposable harness: production has no crash/test switches.
    $points = [ordered]@{
        'journal' = 'Local $Ready = DirCopy($SourceDir, $New, 0)'
        'copied' = 'Local $ManagedFiles[2] = ["chrome++.ini", "version.dll"]'
        'old-moved' = 'If $Ready Then $Ready = _BrowserAutoUpdateMove($New, $TargetDir)'
        'new-moved' = 'If $Ready Then $Ready = _BrowserAutoUpdateWriteTransaction($TargetDir, $Id, $HadTarget, True)'
        'committed' = "If Not `$Ready Then`n"
        'cleaned' = 'If Not _BrowserAutoUpdateDeleteFile($Journal & ".tmp") Or Not _BrowserAutoUpdateDeleteFile($Journal) Then'
    }
    foreach ($entry in $points.GetEnumerator()) {
        Assert ($module.Contains($entry.Value)) "Instrumentation point missing: $($entry.Key)"
        $module = $module.Replace($entry.Value, ('TxCheckpoint("' + $entry.Key + '")' + "`n" + $entry.Value))
    }
    $module = $module.Replace('If Not _BrowserAutoUpdateRemoveTree($New) Then', "TxCheckpoint(`"rollback-restored`")`nIf Not _BrowserAutoUpdateRemoveTree(`$New) Then")
    $module = $module.Replace('If Not _BrowserAutoUpdateMove($Old, $TargetDir) Then', "TxCheckpoint(`"rollback-moved`")`nIf Not _BrowserAutoUpdateMove(`$Old, `$TargetDir) Then")
    $dispatch = @'
Global $TxMode = $CmdLine[1], $TxRoot = $CmdLine[2], $TxPoint = ""
If $CmdLine[0] > 2 Then $TxPoint = $CmdLine[3]
Local $TxName = "App"
If StringInStr($TxMode, "unicode") Then $TxName = "便携 App"
Local $TxResult = False, $TxError = 0
Switch $TxMode
    Case "replace", "replace-unicode"
        $TxResult = _BrowserAutoUpdateReplaceBrowserDirectory($TxRoot & "\source", $TxRoot & "\" & $TxName)
        $TxError = @error
    Case "recover", "recover-unicode"
        $TxResult = _BrowserAutoUpdateRecover($TxRoot & "\" & $TxName)
        $TxError = @error
    Case "startup"
        TxStartup()
        Exit 0
    Case "manual"
        _BrowserDownloadDownloadAndExtract("", $TxRoot & "\App", "win64", "stable", $BrowserChrome)
        $TxError = @error
    Case "pending"
        _BrowserAutoUpdateConfigure($TxRoot & "\cache")
        _BrowserAutoUpdateApplyPending($TxRoot & "\App\browser.exe", $BrowserChrome)
        $TxError = @error
    Case "interactive"
        $BrowserPath = $TxRoot & "\App\browser.exe"
        _BrowserAutoUpdateConfigure($TxRoot & "\cache")
        BrowserAutoUpdateApplyPendingInteractive()
        Exit 9
    Case "lock"
        Local $TxLock = _BrowserAutoUpdateTransactionLock($TxRoot & "\App")
        If @error Then Exit 9
        FileWrite($TxRoot & "\ready", "locked")
        While 1
            Sleep(50)
        WEnd
EndSwitch
If $TxResult Then Exit 0
If $TxError = 0 Then $TxError = 9
Exit $TxError

Func TxCheckpoint($Point)
    If $TxPoint <> $Point Then Return
    FileWrite($TxRoot & "\ready", $Point)
    While 1
        Sleep(50)
    WEnd
EndFunc
'@
    $source = [IO.File]::ReadAllText("$root\RunFirefox.au3").Replace('#include "libs\BrowserAutoUpdate.au3"', $module.Replace('#include "DownloadTools.au3"', '#include "libs\DownloadTools.au3"'))
    $source = $source.Replace('If $Result <> "" Then MsgBox(16, $AppName, _t("BrowserUpdateApplyFailed", "应用浏览器更新失败：\n%s", $Result))', 'If $Result <> "" Then FileWrite($TxRoot & "\stopped", $Result)')
    $startup = [regex]::Match($source, '(?s); Recover before a missing browser EXE.*?\nEndIf').Value
    Assert ($startup.Length -gt 0) 'Startup recovery block missing'
    $startup = $startup.Replace('MsgBox(16, $AppName, _BrowserAutoUpdateTransactionMessage($RecoveryDir))', 'FileWrite($TxRoot & "\stopped", "stopped")')
    $dispatch += "`nFunc TxStartup()`n`$BrowserPath = `$TxRoot & `"\App\browser.exe`"`n$startup`nIf Not FileExists(`$BrowserPath) Then FileWrite(`$TxRoot & `"\settings`", `"settings`")`nEndFunc`n"
    $marker = 'If Not @AutoItX64 Then ; 32-bit Autoit'
    Assert ($source.Contains($marker)) 'Dispatch point missing'
    $source = $source.Replace($marker, $dispatch + "`n" + $marker)
    [IO.File]::WriteAllText($harness, $source, $utf8)
    & "$AutoItDir\Au3Check.exe" -q $harness
    if ($LASTEXITCODE) { throw 'Harness static check failed' }
    foreach ($arch in @('x86', 'x64')) {
        $script:runner = Join-Path $AutoItDir $(if ($arch -eq 'x86') { 'AutoIt3.exe' } else { 'AutoIt3_x64.exe' })
        $dir = Fixture "$arch-normal"
        Assert ((RunChild 'replace' $dir) -eq 0) 'Normal replacement failed'
        Assert ([IO.File]::ReadAllText("$dir\App\chrome++.ini") -eq 'custom') 'INI not preserved'
        Assert ([IO.File]::ReadAllText("$dir\App\version.dll") -eq 'custom-dll') 'DLL not preserved'
        Assert (-not (Test-Path "$dir\App\obsolete")) 'Obsolete file survived'
        AssertRecovered $dir $true
        foreach ($existing in @($true, $false)) {
            foreach ($point in $points.Keys) {
                $dir = Fixture "$arch-$existing-$point" $existing
                CrashAt $dir $point
                AssertRecovered $dir ($point -in @('committed', 'cleaned')) $existing
            }
        }
        foreach ($point in @('rollback-moved', 'rollback-restored')) {
            $dir = Fixture "$arch-recovery-interrupted-$point"
            CrashAt $dir 'new-moved'
            [IO.File]::Delete("$dir\ready")
            CrashAt $dir $point 'recover'
            AssertRecovered $dir $false
        }
        $dir = Fixture "$arch-部分复制"
        CrashAt $dir 'copied'
        $new = Get-ChildItem -LiteralPath $dir -Filter 'App.RunFirefoxNew_*' -Directory
        [IO.File]::Delete("$($new.FullName)\browser.exe")
        AssertRecovered $dir $false

        $dir = Fixture "$arch-move-portable"
        CrashAt $dir 'new-moved'
        $relocated = "$dir-relocated"
        Move-Item -LiteralPath $dir -Destination $relocated
        AssertRecovered $relocated $false

        $dir = Fixture "$arch-unicode"
        Rename-Item -LiteralPath "$dir\App" -NewName '便携 App'
        CrashAt $dir 'new-moved' 'replace-unicode'
        Assert ((RunChild 'recover-unicode' $dir) -eq 0) 'Unicode target recovery failed'
        Assert ([IO.File]::ReadAllText("$dir\便携 App\browser.exe") -eq 'old') 'Unicode old browser not restored'

        $dir = Fixture "$arch-startup"
        CrashAt $dir 'old-moved'
        Assert (-not (Test-Path "$dir\App\browser.exe")) 'Missing EXE fixture not created'
        Assert ((RunChild 'startup' $dir) -eq 0) 'Startup recovery failed'
        Assert (-not (Test-Path "$dir\settings")) 'Interrupted update mistaken for first install'
        Assert ([IO.File]::ReadAllText("$dir\App\browser.exe") -eq 'old') 'Startup did not restore browser'
        [IO.File]::WriteAllText("$dir\App.RunFirefoxUpdate.ini", 'corrupt', $utf8)
        Assert ((RunChild 'startup' $dir) -eq 1) 'Startup did not stop on recovery failure'
        Assert (Test-Path "$dir\stopped") 'Startup failure was not reported'
        [IO.Directory]::CreateDirectory("$dir\cache") | Out-Null
        [IO.File]::WriteAllText("$dir\cache\package.7z", 'keep', $utf8)
        Assert ((RunChild 'manual' $dir) -eq 7) 'Manual download did not stop before network/file operations'
        Assert ((RunChild 'pending' $dir) -eq 7) 'Pending update did not stop before staging cleanup'
        Assert ((RunChild 'interactive' $dir) -eq 1) 'Interactive update failure did not stop launch'
        Assert ([IO.File]::ReadAllText("$dir\cache\package.7z") -eq 'keep') 'Pending recovery failure lost package'
        $dir = Fixture "$arch-lock"
        $p = StartChild 'lock' $dir
        $timer = [Diagnostics.Stopwatch]::StartNew()
        while (-not (Test-Path "$dir\ready")) {
            Assert (-not $p.HasExited -and $timer.ElapsedMilliseconds -lt 30000) 'Lock child failed'
            Start-Sleep -Milliseconds 30
        }
        Assert ((RunChild 'recover' $dir) -eq 2) 'Lock conflict not rejected'
        Assert ((RunChild 'replace' $dir) -eq 2) 'Concurrent replacement not rejected'
        Stop-Process -Id $p.Id -Force
        $p.WaitForExit()
        Assert ((RunChild 'replace' $dir) -eq 0) 'OS did not release lock on exit'

        $dir = Fixture "$arch-cleanup-locked"
        CrashAt $dir 'committed'
        $old = Get-ChildItem -LiteralPath $dir -Filter 'App.RunFirefoxOld_*' -Directory
        $held = [IO.File]::Open("$($old.FullName)\browser.exe", 'Open', 'Read', 'None')
        try { Assert ((RunChild 'recover' $dir) -eq 3) 'Cleanup failure not distinguished' }
        finally { $held.Dispose() }
        Assert (Test-Path "$dir\App.RunFirefoxUpdate.ini") 'Cleanup failure lost journal'
        AssertRecovered $dir $true

        $dir = Fixture "$arch-transient"
        CrashAt $dir 'committed'
        $old = Get-ChildItem -LiteralPath $dir -Filter 'App.RunFirefoxOld_*' -Directory
        $held = [IO.File]::Open("$($old.FullName)\browser.exe", 'Open', 'Read', 'None')
        try {
            $p = StartChild 'recover' $dir
            Start-Sleep -Milliseconds 700
        } finally { $held.Dispose() }
        Assert ($p.WaitForExit(30000)) 'Transient retry timeout'
        $p.Refresh()
        Assert ($p.ExitCode -eq 0) 'Transient lock was not retried'
        AssertRecovered $dir $true

        $dir = Fixture "$arch-running"
        # The preservation fixture is deliberately not a PE DLL. Remove it
        # before executing a real Windows program, which may import version.dll.
        Remove-Item -LiteralPath "$dir\App\version.dll"
        Copy-Item -LiteralPath "$AutoItDir\AutoIt3_x64.exe" -Destination "$dir\App\browser.exe" -Force
        [IO.File]::WriteAllText("$dir\wait.au3", "FileWrite(@ScriptDir & `"\running`", `"ready`")`nWhile 1`nSleep(50)`nWEnd", $utf8)
        $p = Start-Process -FilePath "$dir\App\browser.exe" -ArgumentList ('"' + "$dir\wait.au3" + '"') -WindowStyle Hidden -PassThru
        $children.Add($p)
        $timer = [Diagnostics.Stopwatch]::StartNew()
        while (-not (Test-Path "$dir\running")) {
            Assert (-not $p.HasExited -and $timer.ElapsedMilliseconds -lt 10000) 'Running browser fixture failed to execute'
            Start-Sleep -Milliseconds 30
        }
        Assert ((RunChild 'replace' $dir) -eq 2) 'Running browser was not protected'
        Assert (-not (Test-Path "$dir\App.RunFirefoxUpdate.ini")) 'Running browser created transaction'
        Stop-Process -Id $p.Id -Force
        $p.WaitForExit()
        Assert ((RunChild 'replace' $dir) -eq 0) 'Replacement did not resume after browser exit'

        foreach ($bad in @('corrupt', 'traversal', 'absolute', 'mismatch', 'state')) {
            $dir = Fixture "$arch-bad-$bad"
            CrashAt $dir 'copied'
            $journal = "$dir\App.RunFirefoxUpdate.ini"
            $text = [IO.File]::ReadAllText($journal)
            switch ($bad) {
                'corrupt' { $text = 'not an INI transaction' }
                'traversal' { $text = $text.Replace('Target=App', 'Target=..\outside') }
                'absolute' { $text = $text.Replace('Target=App', "Target=$temp\outside") }
                'mismatch' { $text = $text.Replace('Target=App', 'Target=Other') }
                'state' { $text = $text.Replace('Committed=0', 'Committed=1') }
            }
            [IO.File]::WriteAllText($journal, $text, $utf8)
            Assert ((RunChild 'recover' $dir) -ne 0) "Unsafe journal accepted: $bad"
            Assert ([IO.File]::ReadAllText("$dir\App\browser.exe") -eq 'old') 'Unsafe recovery modified target'
            Assert (Test-Path $journal) 'Unsafe recovery removed journal'
        }
        # NTFS junctions require no elevation. A tree outside the transaction is sacred.
        $dir = Fixture "$arch-junction"
        CrashAt $dir 'copied'
        $new = Get-ChildItem -LiteralPath $dir -Filter 'App.RunFirefoxNew_*' -Directory
        [IO.Directory]::CreateDirectory("$dir\outside") | Out-Null
        [IO.File]::WriteAllText("$dir\outside\sentinel", 'keep', $utf8)
        New-Item -ItemType Junction -Path "$($new.FullName)\link" -Target "$dir\outside" | Out-Null
        Assert ((RunChild 'recover' $dir) -eq 2) 'Reparse tree accepted'
        Assert ([IO.File]::ReadAllText("$dir\outside\sentinel") -eq 'keep') 'Outside tree modified'
        [IO.Directory]::Delete("$($new.FullName)\link")
        AssertRecovered $dir $false
        Write-Output "$arch transaction crash/recovery tests passed."
    }
    $main = [IO.File]::ReadAllText("$root\RunFirefox.au3")
    Assert ($main.IndexOf('SplitPath(_BrowserAutoUpdateCanonical(FullPath($BrowserPath)), $RecoveryDir') -lt $main.IndexOf(';~ 第一个启动参数')) 'Recovery must precede missing-browser settings'
    Assert ($main.Contains('If $ApplyError = 7 Then Exit 1')) 'Pending transaction must stop browser launch'
    Assert ($main.IndexOf('--check-app-update') -lt $main.IndexOf('Local $RecoveryDir')) 'Helper dispatch must precede recovery'
    Write-Output 'Browser transaction tests passed.'
} finally {
    foreach ($p in $children) { if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue; $p.WaitForExit() } }
    Remove-Item -LiteralPath $harness -Force -ErrorAction SilentlyContinue
    $resolvedTemp = [IO.Path]::GetFullPath($temp)
    if ((Split-Path $resolvedTemp -Parent) -eq [IO.Path]::GetTempPath().TrimEnd('\') -and (Split-Path $resolvedTemp -Leaf).StartsWith('RunFirefoxTransaction-')) {
        Remove-Item -LiteralPath $resolvedTemp -Recurse -Force -ErrorAction SilentlyContinue
    }
}
