[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Paths
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-AutoItStringLiteral {
    param([AllowEmptyString()][string]$Value)

    if ($null -eq $Value) {
        $Value = ''
    }

    $escaped = $Value.Replace('"', '""')
    return '"' + $escaped + '"'
}

function ConvertTo-ObfuscatedValue {
    param([AllowEmptyString()][string]$Value)

    if ($null -eq $Value) {
        $Value = ''
    }

    $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
    if ($plainBytes.Length -eq 0) {
        return @{ Payload = ''; Mask = ''; Nonce = 0 }
    }

    $maskBytes = [byte[]]::new($plainBytes.Length)
    $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $random.GetBytes($maskBytes)
        $nonce = $maskBytes[0]
    }
    finally {
        $random.Dispose()
    }

    $payloadBytes = [byte[]]::new($plainBytes.Length)
    for ($index = 0; $index -lt $plainBytes.Length; $index++) {
        $indexMask = (($index * 149) + $nonce) -band 0xFF
        $payloadBytes[$index] = $plainBytes[$index] -bxor $maskBytes[$index] -bxor $indexMask
    }

    return @{
        Payload = [Convert]::ToHexString($payloadBytes)
        Mask = [Convert]::ToHexString($maskBytes)
        Nonce = $nonce
    }
}

function Set-ChromiumGoogleApiData {
    param([string[]]$SourcePaths)

    $values = @{
        ChromiumGoogleApiKey = $env:CHROMIUM_GOOGLE_API_KEY
        ChromiumGoogleClientId = $env:CHROMIUM_GOOGLE_DEFAULT_CLIENT_ID
        ChromiumGoogleClientSecret = $env:CHROMIUM_GOOGLE_DEFAULT_CLIENT_SECRET
    }

    foreach ($path in $SourcePaths) {
        # Each target gets distinct obfuscated data, even when it shares the same credentials.
        $replacements = @{}
        foreach ($name in $values.Keys) {
            $encoded = ConvertTo-ObfuscatedValue -Value $values[$name]
            $replacements["${name}Payload"] = ConvertTo-AutoItStringLiteral -Value $encoded.Payload
            $replacements["${name}Mask"] = ConvertTo-AutoItStringLiteral -Value $encoded.Mask
            $replacements["${name}Nonce"] = [string]$encoded.Nonce
        }

        $source = Get-Content -LiteralPath $path -Raw
        foreach ($name in $replacements.Keys) {
            $pattern = '(?m)^Global Const \$' + [regex]::Escape($name) + ' = (?:".*"|\d+)\r?$'
            if ($source -notmatch $pattern) {
                throw "Missing Chromium Google API value: $name"
            }

            $line = 'Global Const $' + $name + ' = ' + $replacements[$name]
            $source = [regex]::Replace($source, $pattern, $line)
        }
        Set-Content -LiteralPath $path -Value $source -Encoding utf8
    }
}

Set-ChromiumGoogleApiData -SourcePaths $Paths
