[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [Alias('FullName')]
    [string[]]$Paths,

    [string]$OutputPath,

    [switch]$Force
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    Add-Type -AssemblyName System.Drawing

    function Test-PngFrame {
        param([byte[]]$Data)

        return $Data.Length -ge 8 -and
            $Data[0] -eq 0x89 -and $Data[1] -eq 0x50 -and $Data[2] -eq 0x4E -and $Data[3] -eq 0x47 -and
            $Data[4] -eq 0x0D -and $Data[5] -eq 0x0A -and $Data[6] -eq 0x1A -and $Data[7] -eq 0x0A
    }

    function Convert-DibFrameToPng {
        param(
            [byte[]]$Data,
            [byte]$WidthByte,
            [byte]$HeightByte,
            [byte]$ColorCount,
            [byte]$Reserved,
            [uint16]$Planes,
            [uint16]$BitCount
        )

        $singleIcon = [byte[]]::new(22 + $Data.Length)
        [BitConverter]::GetBytes([uint16]0).CopyTo($singleIcon, 0)
        [BitConverter]::GetBytes([uint16]1).CopyTo($singleIcon, 2)
        [BitConverter]::GetBytes([uint16]1).CopyTo($singleIcon, 4)
        $singleIcon[6] = $WidthByte
        $singleIcon[7] = $HeightByte
        $singleIcon[8] = $ColorCount
        $singleIcon[9] = $Reserved
        [BitConverter]::GetBytes($Planes).CopyTo($singleIcon, 10)
        [BitConverter]::GetBytes($BitCount).CopyTo($singleIcon, 12)
        [BitConverter]::GetBytes([uint32]$Data.Length).CopyTo($singleIcon, 14)
        [BitConverter]::GetBytes([uint32]22).CopyTo($singleIcon, 18)
        $Data.CopyTo($singleIcon, 22)

        $iconStream = [IO.MemoryStream]::new($singleIcon, $false)
        $pngStream = [IO.MemoryStream]::new()
        try {
            $icon = [Drawing.Icon]::new($iconStream)
            try {
                $bitmap = $icon.ToBitmap()
                try {
                    $bitmap.Save($pngStream, [Drawing.Imaging.ImageFormat]::Png)
                    return $pngStream.ToArray()
                }
                finally {
                    $bitmap.Dispose()
                }
            }
            finally {
                $icon.Dispose()
            }
        }
        finally {
            $pngStream.Dispose()
            $iconStream.Dispose()
        }
    }

    function Get-DefaultOutputPath {
        param([IO.FileInfo]$Source)

        return Join-Path $Source.DirectoryName ($Source.BaseName + '.compressed.ico')
    }

    function Compress-IcoFile {
        param(
            [string]$SourcePath,
            [string]$RequestedOutputPath
        )

        $source = Get-Item -LiteralPath $SourcePath -ErrorAction Stop
        if ($source.PSIsContainer -or $source.Extension -ine '.ico') {
            throw "The source must be an ICO file: $($source.FullName)"
        }

        $bytes = [IO.File]::ReadAllBytes($source.FullName)
        if ($bytes.Length -lt 6 -or
            [BitConverter]::ToUInt16($bytes, 0) -ne 0 -or
            [BitConverter]::ToUInt16($bytes, 2) -ne 1) {
            throw "The file does not contain a valid ICO header: $($source.FullName)"
        }

        $count = [BitConverter]::ToUInt16($bytes, 4)
        if ($count -eq 0 -or $bytes.Length -lt 6 + (16 * $count)) {
            throw "The ICO directory is truncated: $($source.FullName)"
        }

        $frames = for ($index = 0; $index -lt $count; $index++) {
            $entryOffset = 6 + (16 * $index)
            $length = [BitConverter]::ToUInt32($bytes, $entryOffset + 8)
            $offset = [BitConverter]::ToUInt32($bytes, $entryOffset + 12)
            if ($length -eq 0 -or $offset -gt $bytes.Length -or $length -gt ($bytes.Length - $offset)) {
                throw "ICO frame $index points outside the file."
            }

            $data = [byte[]]::new($length)
            [Array]::Copy($bytes, $offset, $data, 0, $length)
            $width = if ($bytes[$entryOffset] -eq 0) { 256 } else { [int]$bytes[$entryOffset] }
            $height = if ($bytes[$entryOffset + 1] -eq 0) { 256 } else { [int]$bytes[$entryOffset + 1] }
            $encoding = if (Test-PngFrame -Data $data) { 'PNG' } else { 'DIB' }
            $originalEncoding = $encoding
            $originalLength = $data.Length

            if ($width -eq 256 -and $height -eq 256 -and $encoding -eq 'DIB') {
                $pngData = Convert-DibFrameToPng -Data $data `
                    -WidthByte $bytes[$entryOffset] -HeightByte $bytes[$entryOffset + 1] `
                    -ColorCount $bytes[$entryOffset + 2] -Reserved $bytes[$entryOffset + 3] `
                    -Planes ([BitConverter]::ToUInt16($bytes, $entryOffset + 4)) `
                    -BitCount ([BitConverter]::ToUInt16($bytes, $entryOffset + 6))
                if ($pngData.Length -lt $data.Length) {
                    $data = $pngData
                    $encoding = 'PNG'
                }
            }

            [pscustomobject]@{
                WidthByte = $bytes[$entryOffset]
                HeightByte = $bytes[$entryOffset + 1]
                Width = $width
                Height = $height
                ColorCount = $bytes[$entryOffset + 2]
                Reserved = $bytes[$entryOffset + 3]
                Planes = [BitConverter]::ToUInt16($bytes, $entryOffset + 4)
                BitCount = [BitConverter]::ToUInt16($bytes, $entryOffset + 6)
                OriginalLength = $originalLength
                OriginalEncoding = $originalEncoding
                Data = $data
                Encoding = $encoding
            }
        }

        $targetPath = if ($RequestedOutputPath) {
            $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($RequestedOutputPath)
        }
        else {
            Get-DefaultOutputPath -Source $source
        }

        if ([string]::Equals($source.FullName, $targetPath, [StringComparison]::OrdinalIgnoreCase) -and -not $Force) {
            throw 'Refusing to overwrite the source ICO without -Force.'
        }
        if ((Test-Path -LiteralPath $targetPath) -and -not $Force) {
            throw "The output file already exists: $targetPath (use -Force to replace it)"
        }

        $payloadLength = ($frames | ForEach-Object { $_.Data.Length } | Measure-Object -Sum).Sum
        $output = [byte[]]::new(6 + (16 * $frames.Count) + $payloadLength)
        [BitConverter]::GetBytes([uint16]0).CopyTo($output, 0)
        [BitConverter]::GetBytes([uint16]1).CopyTo($output, 2)
        [BitConverter]::GetBytes([uint16]$frames.Count).CopyTo($output, 4)
        $dataOffset = 6 + (16 * $frames.Count)

        for ($index = 0; $index -lt $frames.Count; $index++) {
            $frame = $frames[$index]
            $entryOffset = 6 + (16 * $index)
            $output[$entryOffset] = $frame.WidthByte
            $output[$entryOffset + 1] = $frame.HeightByte
            $output[$entryOffset + 2] = $frame.ColorCount
            $output[$entryOffset + 3] = $frame.Reserved
            [BitConverter]::GetBytes([uint16]$frame.Planes).CopyTo($output, $entryOffset + 4)
            [BitConverter]::GetBytes([uint16]$frame.BitCount).CopyTo($output, $entryOffset + 6)
            [BitConverter]::GetBytes([uint32]$frame.Data.Length).CopyTo($output, $entryOffset + 8)
            [BitConverter]::GetBytes([uint32]$dataOffset).CopyTo($output, $entryOffset + 12)
            $frame.Data.CopyTo($output, $dataOffset)
            $dataOffset += $frame.Data.Length
        }

        $targetDirectory = [IO.Path]::GetDirectoryName($targetPath)
        if (-not (Test-Path -LiteralPath $targetDirectory)) {
            [void](New-Item -ItemType Directory -Path $targetDirectory)
        }
        $temporaryPath = Join-Path $targetDirectory ('.' + [IO.Path]::GetFileName($targetPath) + '.' + [Guid]::NewGuid().ToString('N') + '.tmp')
        try {
            [IO.File]::WriteAllBytes($temporaryPath, $output)
            Move-Item -LiteralPath $temporaryPath -Destination $targetPath -Force:$Force
        }
        finally {
            if (Test-Path -LiteralPath $temporaryPath) {
                Remove-Item -LiteralPath $temporaryPath -Force
            }
        }

        Write-Host "Source: $($source.FullName) ($($source.Length.ToString('N0')) bytes)"
        $frames | ForEach-Object {
            Write-Host ("  {0}x{1}, {2}-bit, {3} -> {4}, {5:N0} -> {6:N0} bytes" -f $_.Width, $_.Height, $_.BitCount, $_.OriginalEncoding, $_.Encoding, $_.OriginalLength, $_.Data.Length)
        }
        $saved = $source.Length - $output.Length
        $percent = if ($source.Length) { 100 * $saved / $source.Length } else { 0 }
        Write-Host ("Output: {0} ({1:N0} bytes, saved {2:N0} bytes / {3:N1}%)" -f $targetPath, $output.Length, $saved, $percent)
    }
}

end {
    if (-not $Paths -or $Paths.Count -eq 0) {
        Add-Type -AssemblyName System.Windows.Forms
        $dialog = [System.Windows.Forms.OpenFileDialog]::new()
        $dialog.Title = 'Select ICO files to compress'
        $dialog.Filter = 'Icon files (*.ico)|*.ico|All files (*.*)|*.*'
        $dialog.Multiselect = $true
        if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            return
        }
        $Paths = $dialog.FileNames
    }

    if ($OutputPath -and $Paths.Count -ne 1) {
        throw '-OutputPath can only be used with one input file.'
    }

    foreach ($path in $Paths) {
        Compress-IcoFile -SourcePath $path -RequestedOutputPath $OutputPath
    }
}
