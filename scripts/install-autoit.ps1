Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$installers = @(
    @{
        Url = 'https://www.autoitscript.com/files/autoit3/autoit-v3-setup.exe'
        FileName = 'autoit-v3-setup.exe'
        Arguments = @('/S')
    },
    @{
        Url = 'https://www.autoitscript.com/autoit3/scite/download/SciTE4AutoIt3.exe'
        FileName = 'SciTE4AutoIt3.exe'
        Arguments = @('/S')
    }
)

foreach ($installer in $installers) {
    $installerPath = Join-Path $env:RUNNER_TEMP $installer.FileName
    Invoke-WebRequest -Uri $installer.Url -OutFile $installerPath

    $process = Start-Process `
        -FilePath $installerPath `
        -ArgumentList ([string[]]$installer.Arguments) `
        -Wait `
        -PassThru

    if ($process.ExitCode -ne 0) {
        throw "$($installer.FileName) failed with exit code $($process.ExitCode)."
    }
}

$candidateDirs = @(
    (Join-Path ${env:ProgramFiles} 'AutoIt3'),
    (Join-Path ${env:ProgramFiles(x86)} 'AutoIt3')
)
$autoItDir = $candidateDirs |
    Where-Object { Test-Path -LiteralPath (Join-Path $_ 'AutoIt3.exe') } |
    Select-Object -First 1

if (-not $autoItDir) {
    $searched = $candidateDirs -join ', '
    throw "AutoIt3.exe was not found. Searched: $searched"
}

$stripperZip = Join-Path $env:RUNNER_TEMP 'Au3Stripper.zip'
Invoke-WebRequest `
    -Uri 'https://www.autoitscript.com/autoit3/scite/download/Au3Stripper.zip' `
    -OutFile $stripperZip

$stripperDir = Join-Path $autoItDir 'SciTE\au3Stripper'
Remove-Item -LiteralPath $stripperDir -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive -LiteralPath $stripperZip -DestinationPath $stripperDir -Force

$autoItPath = Join-Path $autoItDir 'AutoIt3.exe'
$wrapperPath = Join-Path $autoItDir 'SciTE\AutoIt3Wrapper\AutoIt3Wrapper.au3'

if (-not (Test-Path -LiteralPath $autoItPath)) {
    throw "AutoIt3.exe was not found at $autoItPath"
}

if (-not (Test-Path -LiteralPath $wrapperPath)) {
    throw "AutoIt3Wrapper.au3 was not found at $wrapperPath"
}

"AutoIt installed at $autoItDir"
"AUTOIT_DIR=$autoItDir" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
$autoItDir | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
