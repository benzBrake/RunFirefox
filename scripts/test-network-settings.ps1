param(
    [string]$Socks5Host = '',
    [int]$Socks5Port = 0
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$autoIt = 'C:\Program Files\AutoIt3\AutoIt3.exe'
if (-not (Test-Path -LiteralPath $autoIt)) {
    throw "AutoIt3.exe not found: $autoIt"
}

$temp = Join-Path ([IO.Path]::GetTempPath()) ("RunFirefox_NetworkTest_" + [guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $temp)
$payload = Join-Path $temp 'payload.bin'
$download = Join-Path $temp 'download.bin'
$ready = Join-Path $temp 'server-ready'
$sourceBytes = [byte[]]::new(524288)
for ($i = 0; $i -lt $sourceBytes.Length; $i++) {
    $sourceBytes[$i] = $i % 251
}
[IO.File]::WriteAllBytes($payload, $sourceBytes)

$tcp = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
$tcp.Start()
$port = ([Net.IPEndPoint]$tcp.LocalEndpoint).Port
$tcp.Stop()
$prefix = "http://127.0.0.1:$port/"
$server = Start-Job -ArgumentList $prefix, $payload, $ready -ScriptBlock {
    param($Prefix, $Payload, $Ready)
    $bytes = [IO.File]::ReadAllBytes($Payload)
    $listener = [Net.HttpListener]::new()
    $listener.Prefixes.Add($Prefix)
    $listener.Start()
    [IO.File]::WriteAllText($Ready, 'ready')
    try {
        for ($requestIndex = 0; $requestIndex -lt 4; $requestIndex++) {
            $context = $listener.GetContext()
            $range = $context.Request.Headers['Range']
            Write-Output "request[$requestIndex] range=$range"
            if ($range -notmatch '^bytes=(\d+)-(\d+)$') {
                $context.Response.StatusCode = 400
                $context.Response.Close()
                continue
            }
            $start = [int64]$Matches[1]
            $end = [Math]::Min([int64]$Matches[2], $bytes.Length - 1)
            $length = [int]($end - $start + 1)
            $context.Response.StatusCode = 206
            $context.Response.Headers['Accept-Ranges'] = 'bytes'
            $context.Response.Headers['Content-Range'] = "bytes $start-$end/$($bytes.Length)"
            $context.Response.ContentLength64 = $length
            $context.Response.OutputStream.Write($bytes, [int]$start, $length)
            $context.Response.Close()
        }
    }
    finally {
        $listener.Stop()
    }
}
for ($wait = 0; $wait -lt 100 -and -not (Test-Path -LiteralPath $ready); $wait++) {
    Start-Sleep -Milliseconds 50
}
if (-not (Test-Path -LiteralPath $ready)) {
    throw 'Local Range server failed to start'
}

$harness = @'
#include "__DOWNLOAD_TOOLS__"
#include "__UPGRADE_HELPER__"

Func Assert($Condition, $Message)
    If Not $Condition Then
        ConsoleWrite("FAIL: " & $Message & @CRLF)
        Exit 1
    EndIf
EndFunc

_DownloadToolsConfigure(3, "direct", "", 0, "zh-CN")
Assert($DT_DownloadThreads = 3, "thread configuration")
Local $DirectUrls = _UpgradeBuildGithubDirectUrls("https://github.com/example/project", "https://mirror.example/")
Assert(UBound($DirectUrls) > 1, "direct mode retains mirror candidates")
_DownloadToolsConfigure(3, "direct", "", 0, "en-US")
Local $GenericUrls = _UpgradeBuildUrlProxyUrls("https://archive.org/example/file.exe", "https://mirror.example/")
Assert(UBound($GenericUrls) = 2, "generic URL proxy fallback count")
Assert($GenericUrls[0] = "https://mirror.example/https://archive.org/example/file.exe", "configured generic URL proxy first")
Assert($GenericUrls[1] = "https://archive.org/example/file.exe", "generic upstream fallback last")

_DownloadToolsConfigure(3, "http", "127.0.0.1", 8080, "zh-CN")
Local $ProxyUrls = _UpgradeBuildGithubDirectUrls("https://github.com/example/project", "https://mirror.example/")
Assert(UBound($ProxyUrls) = 1 And $ProxyUrls[0] = "https://github.com/example/project", "proxy mode bypasses mirrors")
Local $GenericProxyUrls = _UpgradeBuildUrlProxyUrls("https://archive.org/example/file.exe", "https://mirror.example/")
Assert(UBound($GenericProxyUrls) = 1 And $GenericProxyUrls[0] = "https://archive.org/example/file.exe", "proxy mode bypasses generic URL proxy")

_DownloadToolsConfigure(3, "direct", "", 0, "zh-CN")
Assert(_DownloadToolsHasCurl(), "curl detection")
Local $DownloadResult = _DownloadToolsCurlSegmentedDownload("__URL__", "__DESTINATION__", "test", "{Downloaded}/{Total}", 30000)
If Not $DownloadResult Then ConsoleWrite("segmented @error=" & @error & ", @extended=" & @extended & @CRLF)
Assert($DownloadResult, "segmented download")
If __PROXY_PORT__ > 0 Then
    _DownloadToolsConfigure(3, "socks5", "__PROXY_HOST__", __PROXY_PORT__)
    Local $ProxyResponse = _DownloadToolsHttpGetText("https://api.github.com", "RunFirefox-network-test", "application/json")
    FileWrite("__DIAGNOSTIC__", "error=" & @error & "; response=" & $ProxyResponse)
    Assert(StringInStr($ProxyResponse, '"current_user_url"') > 0, "SOCKS5 proxy request")
EndIf
Exit 0
'@
$harness = $harness.Replace('__DOWNLOAD_TOOLS__', (Join-Path $root 'libs\DownloadTools.au3'))
$harness = $harness.Replace('__UPGRADE_HELPER__', (Join-Path $root 'libs\UpgradeHelper.au3'))
$harness = $harness.Replace('__URL__', ($prefix + 'payload.bin'))
$harness = $harness.Replace('__DESTINATION__', $download)
$harness = $harness.Replace('__PROXY_HOST__', $Socks5Host.Replace('"', ''))
$harness = $harness.Replace('__PROXY_PORT__', [string]$Socks5Port)
$diagnostic = Join-Path $temp 'proxy-diagnostic.txt'
$harness = $harness.Replace('__DIAGNOSTIC__', $diagnostic)
$harnessPath = Join-Path $temp 'network-test.au3'
[IO.File]::WriteAllText($harnessPath, $harness, [Text.UTF8Encoding]::new($false))

try {
    $testProcess = Start-Process -FilePath $autoIt -ArgumentList ('"' + $harnessPath + '"') -Wait -PassThru -WindowStyle Hidden
    if ($testProcess.ExitCode -ne 0) {
        Receive-Job -Job $server -Keep | Write-Host
        if (Test-Path -LiteralPath $diagnostic) { Get-Content -LiteralPath $diagnostic | Write-Host }
        throw "AutoIt network test failed with exit code $($testProcess.ExitCode)"
    }
    Wait-Job -Job $server -Timeout 10 | Out-Null
    if ($server.State -ne 'Completed') {
        throw 'Local Range server did not complete'
    }
    $sourceHash = (Get-FileHash -LiteralPath $payload -Algorithm SHA256).Hash
    $downloadHash = (Get-FileHash -LiteralPath $download -Algorithm SHA256).Hash
    if ($sourceHash -ne $downloadHash) {
        throw 'Merged download hash does not match source payload'
    }
    Write-Host 'Network settings tests passed.'
}
finally {
    Stop-Job -Job $server -ErrorAction SilentlyContinue
    Remove-Job -Job $server -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
