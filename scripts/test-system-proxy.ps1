param([string]$AutoItDir = $env:AUTOIT_DIR)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($AutoItDir)) { $AutoItDir = 'C:\Program Files\AutoIt3' }
$root = Split-Path -Parent $PSScriptRoot
$temp = Join-Path ([IO.Path]::GetTempPath()) ('RunFirefox_SystemProxy_' + [guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $temp)
$server = $null
try {
    $tcp = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
    $tcp.Start()
    $port = ([Net.IPEndPoint]$tcp.LocalEndpoint).Port
    $tcp.Stop()
    $prefix = "http://127.0.0.1:$port/"
    $ready = Join-Path $temp 'ready'
    $server = Start-Job -ArgumentList $prefix, $ready -ScriptBlock {
        param($Prefix, $Ready)
        $listener = [Net.HttpListener]::new()
        $listener.Prefixes.Add($Prefix)
        $listener.Start()
        [IO.File]::WriteAllText($Ready, 'ready')
        try {
            while ($true) {
                $pending = $listener.GetContextAsync()
                while (-not $pending.IsCompleted) { Start-Sleep -Milliseconds 20 }
                $context = $pending.GetAwaiter().GetResult()
                $path = $context.Request.Url.AbsolutePath
                if ($path -eq '/start') {
                    $context.Response.StatusCode = 302
                    $context.Response.RedirectLocation = $Prefix + 'payload'
                } elseif ($path -eq '/loop') {
                    $context.Response.StatusCode = 302
                    $context.Response.RedirectLocation = '/loop'
                } elseif ($path -eq '/post307' -or $path -eq '/post302') {
                    $context.Response.StatusCode = if ($path -eq '/post307') { 307 } else { 302 }
                    $context.Response.RedirectLocation = '/echo'
                } elseif ($path -eq '/truncated') {
                    $context.Response.ContentLength64 = 100
                    $context.Response.OutputStream.WriteByte(65)
                    $context.Response.Abort()
                    continue
                } elseif ($path -eq '/payload' -and $context.Request.RawUrl -match '^http') {
                    $context.Response.StatusCode = 403
                } else {
                    $body = 'system-proxy-payload'
                    if ($path -eq '/echo') {
                        $reader = [IO.StreamReader]::new($context.Request.InputStream)
                        $body = $context.Request.HttpMethod + ':' + $reader.ReadToEnd()
                        $reader.Dispose()
                    }
                    $bytes = [Text.Encoding]::UTF8.GetBytes($body)
                    $range = $context.Request.Headers['Range']
                    if ($range -match '^bytes=(\d+)-(\d+)$') {
                        $start = [int]$Matches[1]
                        $end = [Math]::Min([int]$Matches[2], $bytes.Length - 1)
                        $context.Response.StatusCode = 206
                        $context.Response.Headers['Content-Range'] = "bytes $start-$end/$($bytes.Length)"
                        $bytes = [byte[]]$bytes[$start..$end]
                    }
                    $context.Response.ContentLength64 = $bytes.Length
                    $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
                }
                $context.Response.Close()
            }
        } finally { $listener.Stop() }
    }
    for ($wait = 0; $wait -lt 100 -and -not (Test-Path -LiteralPath $ready); $wait++) {
        Start-Sleep -Milliseconds 50
    }
    if (-not (Test-Path -LiteralPath $ready)) { throw 'System proxy test server did not start' }

    # Replace only the Windows configuration boundary; exercise the real curl
    # transport against local HTTP endpoints without changing the user's proxy.
    $module = [IO.File]::ReadAllText((Join-Path $root 'libs\DownloadTools.au3'))
    $module = $module.Replace('Func _DownloadToolsResolveSystemProxy(', 'Func _DownloadToolsResolveWindowsSystemProxy(')
    [IO.File]::WriteAllText((Join-Path $temp 'DownloadTools.au3'), $module, [Text.UTF8Encoding]::new($false))
    $harness = @'
#include "DownloadTools.au3"
Global $ResolutionLog = ""
Func _DownloadToolsResolveSystemProxy($Url, ByRef $Proxy, ByRef $NoProxy)
    $ResolutionLog &= $Url & @LF
    ; The payload endpoint rejects proxy-form requests. The redirected URL
    ; must bypass the dead configured proxy and reach that endpoint directly.
    If StringRight($Url, 6) = "/start" Then
        $Proxy = "http://127.0.0.1:__PORT__"
        Return True
    EndIf
    Return _DownloadToolsParseSystemProxyConfig("127.0.0.1:1", "127.*", $Url, $Proxy, $NoProxy)
EndFunc
Func Assert($Condition, $Name)
    If $Condition Then Return
    ConsoleWrite("FAIL: " & $Name & @CRLF)
    Exit 1
EndFunc
_DownloadToolsConfigure(3, "system")
Local $Entry = "__PREFIX__start", $Output = @ScriptDir & "\result.bin"
Local $Text = _DownloadToolsHttpGetText($Entry)
If $Text <> "system-proxy-payload" Then ConsoleWrite("GET error=" & @error & "; response=" & $Text & "; resolutions=" & $ResolutionLog & @CRLF)
Assert($Text = "system-proxy-payload", "GET follows redirect with a new proxy decision")
Assert(StringInStr($ResolutionLog, "__PREFIX__payload"), "resolver called for redirect target")
Local $Kind = "", $Handle = _DownloadToolsStartUrlToFile($Entry, $Output, $Kind)
Assert($Handle <> 0 And $Kind = "curl", "asynchronous request starts")
While _DownloadToolsCurlRunning($Handle)
    Sleep(20)
WEnd
Assert(FileRead($Output) = "system-proxy-payload", "asynchronous redirect completes")
Assert(_DownloadToolsCurlSegmentedDownload($Entry, $Output, "test", "{Downloaded}/{Total}", 10000), "segmented requests follow redirects")
Assert(FileRead($Output) = "system-proxy-payload", "segmented content matches")
Assert(_DownloadToolsCurlSingleDownload($Entry, $Output, "test", "{Downloaded}/{Total}", "%s", 10000), "single download follows redirects")
Local $Response = _DownloadToolsHttpPostText("__PREFIX__post307", "request-body")
Assert($Response = "POST:request-body", "307 retains POST and body")
$Response = _DownloadToolsHttpPostText("__PREFIX__post302", "request-body")
Assert($Response = "GET:", "302 converts POST to GET")
Local $ExitCode = _DownloadToolsCurlWait(' --max-time 5 --output "' & $Output & '"', "__PREFIX__loop")
Assert($ExitCode <> 0 And Not FileExists($Output), "redirect loop fails and removes output")
$ExitCode = _DownloadToolsCurlWait(' --max-time 5 --output "' & $Output & '"', "__PREFIX__truncated")
Assert($ExitCode <> 0 And Not FileExists($Output), "truncated responses fail and remove output")
$Handle = _DownloadToolsCurlStart(' --output "' & $Output & '"', $Entry)
_DownloadToolsCurlCancel($Handle)
Assert($DT_CurlRequests.Count = 0, "cancellation releases request state")
$Handle = _DownloadToolsCurlStart(' --output "' & $Output & '"', $Entry)
Local $TimedRequest = $DT_CurlRequests.Item($Handle)
$TimedRequest[5] = 1
$DT_CurlRequests.Item($Handle) = $TimedRequest
Sleep(20)
Assert(Not _DownloadToolsCurlRunning($Handle) And @extended = 28, "request deadline stops the redirect chain")
Assert($DT_CurlRequests.Count = 0 And Not FileExists($Output), "deadline cleans up state and output")
_DownloadToolsClose()
ConsoleWrite("System proxy transport tests passed." & @CRLF)
'@
    $harness = $harness.Replace('__PORT__', [string]$port).Replace('__PREFIX__', $prefix)
    $harnessPath = Join-Path $temp 'test.au3'
    [IO.File]::WriteAllText($harnessPath, $harness, [Text.UTF8Encoding]::new($false))
    & (Join-Path $AutoItDir 'Au3Check.exe') -q $harnessPath
    if ($LASTEXITCODE) { throw 'System proxy harness static check failed' }
    foreach ($runner in @('AutoIt3.exe', 'AutoIt3_x64.exe')) {
        & (Join-Path $AutoItDir $runner) /ErrorStdOut $harnessPath | Write-Output
        if ($LASTEXITCODE) { throw "$runner system proxy tests failed" }
    }
} finally {
    if ($server) {
        Stop-Job $server -ErrorAction SilentlyContinue
        Remove-Job $server -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
