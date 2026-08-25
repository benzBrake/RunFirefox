[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [Alias('Path')]
    [string]$ExePath,

    [string]$OutputPath,

    [string]$Group,

    [switch]$List,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $ExePath) {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = [System.Windows.Forms.OpenFileDialog]::new()
    $dialog.Title = 'Select an EXE or DLL to extract its icon'
    $dialog.Filter = 'Programs and libraries (*.exe;*.dll)|*.exe;*.dll|All files (*.*)|*.*'
    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        exit 1
    }
    $ExePath = $dialog.FileName
}

$source = Get-Item -LiteralPath $ExePath -ErrorAction Stop
if ($source.PSIsContainer) {
    throw "The source path is a directory: $($source.FullName)"
}

if (-not ('RunFirefox.Tools.PeIconResources' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace RunFirefox.Tools
{
    public sealed class ResourceIdentifier
    {
        public int? Id { get; set; }
        public string Name { get; set; }
        public string Key { get { return Id.HasValue ? Id.Value.ToString() : Name; } }
    }

    public sealed class IconGroupResource
    {
        public ResourceIdentifier Identifier { get; set; }
        public ushort Language { get; set; }
        public byte[] Data { get; set; }
    }

    public static class PeIconResources
    {
        private const uint LoadLibraryAsDataFile = 0x00000002;
        private const uint LoadLibraryAsImageResource = 0x00000020;
        private const int RtIcon = 3;
        private const int RtGroupIcon = 14;

        private delegate bool EnumResourceNameCallback(IntPtr module, IntPtr type, IntPtr name, IntPtr parameter);
        private delegate bool EnumResourceLanguageCallback(IntPtr module, IntPtr type, IntPtr name, ushort language, IntPtr parameter);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr LoadLibraryExW(string fileName, IntPtr file, uint flags);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool FreeLibrary(IntPtr module);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool EnumResourceNamesW(IntPtr module, IntPtr type, EnumResourceNameCallback callback, IntPtr parameter);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool EnumResourceLanguagesW(IntPtr module, IntPtr type, IntPtr name, EnumResourceLanguageCallback callback, IntPtr parameter);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr FindResourceExW(IntPtr module, IntPtr type, IntPtr name, ushort language);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern uint SizeofResource(IntPtr module, IntPtr resource);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern IntPtr LoadResource(IntPtr module, IntPtr resource);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern IntPtr LockResource(IntPtr resourceData);

        public static IconGroupResource[] GetIconGroups(string path)
        {
            IntPtr module = Open(path);
            try
            {
                var names = EnumerateNames(module, RtGroupIcon);
                var groups = new List<IconGroupResource>();
                foreach (ResourceIdentifier name in names)
                {
                    foreach (ushort language in EnumerateLanguages(module, RtGroupIcon, name))
                    {
                        groups.Add(new IconGroupResource
                        {
                            Identifier = name,
                            Language = language,
                            Data = ReadResource(module, RtGroupIcon, name, language)
                        });
                    }
                }
                return groups.ToArray();
            }
            finally
            {
                FreeLibrary(module);
            }
        }

        public static byte[] GetIcon(string path, int id, ushort preferredLanguage)
        {
            IntPtr module = Open(path);
            try
            {
                var name = new ResourceIdentifier { Id = id };
                List<ushort> languages = EnumerateLanguages(module, RtIcon, name);
                if (languages.Count == 0)
                    throw new InvalidOperationException("The icon resource " + id + " has no language variant.");

                ushort selected = languages[0];
                if (languages.Contains(preferredLanguage))
                    selected = preferredLanguage;
                else if (languages.Contains(0))
                    selected = 0;

                return ReadResource(module, RtIcon, name, selected);
            }
            finally
            {
                FreeLibrary(module);
            }
        }

        private static IntPtr Open(string path)
        {
            IntPtr module = LoadLibraryExW(path, IntPtr.Zero, LoadLibraryAsDataFile | LoadLibraryAsImageResource);
            if (module == IntPtr.Zero)
                throw new Win32Exception(Marshal.GetLastWin32Error(), "Unable to read PE resources from " + path);
            return module;
        }

        private static List<ResourceIdentifier> EnumerateNames(IntPtr module, int typeId)
        {
            var names = new List<ResourceIdentifier>();
            EnumResourceNameCallback callback = delegate(IntPtr h, IntPtr type, IntPtr name, IntPtr parameter)
            {
                names.Add(ToIdentifier(name));
                return true;
            };

            if (!EnumResourceNamesW(module, new IntPtr(typeId), callback, IntPtr.Zero))
            {
                int error = Marshal.GetLastWin32Error();
                if (error == 1813)
                    return names;
                throw new Win32Exception(error, "Unable to enumerate icon groups.");
            }
            return names;
        }

        private static List<ushort> EnumerateLanguages(IntPtr module, int typeId, ResourceIdentifier name)
        {
            var languages = new List<ushort>();
            IntPtr namePointer = ToNativeName(name);
            bool allocated = !name.Id.HasValue;
            try
            {
                EnumResourceLanguageCallback callback = delegate(IntPtr h, IntPtr type, IntPtr resourceName, ushort language, IntPtr parameter)
                {
                    languages.Add(language);
                    return true;
                };

                if (!EnumResourceLanguagesW(module, new IntPtr(typeId), namePointer, callback, IntPtr.Zero))
                {
                    int error = Marshal.GetLastWin32Error();
                    if (error != 1815)
                        throw new Win32Exception(error, "Unable to enumerate resource languages for " + name.Key + ".");
                }
            }
            finally
            {
                if (allocated)
                    Marshal.FreeHGlobal(namePointer);
            }
            return languages;
        }

        private static byte[] ReadResource(IntPtr module, int typeId, ResourceIdentifier name, ushort language)
        {
            IntPtr namePointer = ToNativeName(name);
            bool allocated = !name.Id.HasValue;
            try
            {
                IntPtr resource = FindResourceExW(module, new IntPtr(typeId), namePointer, language);
                if (resource == IntPtr.Zero)
                    throw new Win32Exception(Marshal.GetLastWin32Error(), "Unable to find resource " + name.Key + ".");

                uint size = SizeofResource(module, resource);
                IntPtr loaded = LoadResource(module, resource);
                IntPtr data = loaded == IntPtr.Zero ? IntPtr.Zero : LockResource(loaded);
                if (data == IntPtr.Zero || size == 0)
                    throw new Win32Exception(Marshal.GetLastWin32Error(), "Unable to load resource " + name.Key + ".");

                byte[] bytes = new byte[size];
                Marshal.Copy(data, bytes, 0, checked((int)size));
                return bytes;
            }
            finally
            {
                if (allocated)
                    Marshal.FreeHGlobal(namePointer);
            }
        }

        private static ResourceIdentifier ToIdentifier(IntPtr value)
        {
            ulong raw = unchecked((ulong)value.ToInt64());
            if (raw <= 0xFFFF)
                return new ResourceIdentifier { Id = (int)raw };
            return new ResourceIdentifier { Name = Marshal.PtrToStringUni(value) };
        }

        private static IntPtr ToNativeName(ResourceIdentifier name)
        {
            return name.Id.HasValue
                ? new IntPtr(name.Id.Value)
                : Marshal.StringToHGlobalUni(name.Name);
        }
    }
}
'@
}

function Get-IconGroupEntries {
    param([byte[]]$Data)

    if ($Data.Length -lt 6) {
        throw 'The icon group resource is truncated.'
    }

    $reserved = [BitConverter]::ToUInt16($Data, 0)
    $type = [BitConverter]::ToUInt16($Data, 2)
    $count = [BitConverter]::ToUInt16($Data, 4)
    if ($reserved -ne 0 -or $type -ne 1 -or $count -eq 0 -or $Data.Length -lt 6 + (14 * $count)) {
        throw 'The icon group resource has an invalid header.'
    }

    for ($index = 0; $index -lt $count; $index++) {
        $offset = 6 + (14 * $index)
        [pscustomobject]@{
            Index = $index
            WidthByte = $Data[$offset]
            HeightByte = $Data[$offset + 1]
            Width = if ($Data[$offset] -eq 0) { 256 } else { [int]$Data[$offset] }
            Height = if ($Data[$offset + 1] -eq 0) { 256 } else { [int]$Data[$offset + 1] }
            ColorCount = $Data[$offset + 2]
            Reserved = $Data[$offset + 3]
            Planes = [BitConverter]::ToUInt16($Data, $offset + 4)
            BitCount = [BitConverter]::ToUInt16($Data, $offset + 6)
            DeclaredBytes = [BitConverter]::ToUInt32($Data, $offset + 8)
            ResourceId = [BitConverter]::ToUInt16($Data, $offset + 12)
        }
    }
}

function Get-EncodingName {
    param([byte[]]$Data)

    if ($Data.Length -ge 8 -and
        $Data[0] -eq 0x89 -and $Data[1] -eq 0x50 -and $Data[2] -eq 0x4E -and $Data[3] -eq 0x47 -and
        $Data[4] -eq 0x0D -and $Data[5] -eq 0x0A -and $Data[6] -eq 0x1A -and $Data[7] -eq 0x0A) {
        return 'PNG'
    }
    return 'DIB'
}

function Get-AvailableOutputPath {
    param([string]$BasePath)

    if (-not (Test-Path -LiteralPath $BasePath)) {
        return $BasePath
    }

    $directory = [IO.Path]::GetDirectoryName($BasePath)
    $name = [IO.Path]::GetFileNameWithoutExtension($BasePath)
    for ($index = 1; ; $index++) {
        $candidate = Join-Path $directory "$name-$index.ico"
        if (-not (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }
}

$groups = @([RunFirefox.Tools.PeIconResources]::GetIconGroups($source.FullName))
if ($groups.Count -eq 0) {
    throw "No icon group resources were found in $($source.FullName)"
}

$groupDetails = foreach ($item in $groups) {
    $entries = @(Get-IconGroupEntries -Data $item.Data)
    [pscustomobject]@{
        Key = $item.Identifier.Key
        Language = $item.Language
        Frames = $entries.Count
        Sizes = ($entries | ForEach-Object { "$($_.Width)x$($_.Height)" }) -join ', '
        Resource = $item
        Entries = $entries
    }
}

if ($List) {
    $groupDetails | Select-Object Key, Language, Frames, Sizes | Format-Table -AutoSize
    return
}

if ($Group) {
    $matches = @($groupDetails | Where-Object { $_.Key -eq $Group })
    if ($matches.Count -eq 0) {
        throw "Icon group '$Group' was not found. Use -List to view available groups."
    }
    $selected = $matches | Sort-Object @{ Expression = { if ($_.Language -eq 0) { 0 } else { 1 } } }, Language | Select-Object -First 1
}
else {
    $selected = $groupDetails | Sort-Object @{ Expression = { if ($_.Key -match '^\d+$') { 0 } else { 1 } } }, @{ Expression = { if ($_.Key -match '^\d+$') { [int]$_.Key } else { $_.Key } } }, @{ Expression = { if ($_.Language -eq 0) { 0 } else { 1 } } }, Language | Select-Object -First 1
}

$frames = foreach ($entry in $selected.Entries) {
    $data = [RunFirefox.Tools.PeIconResources]::GetIcon($source.FullName, $entry.ResourceId, $selected.Language)
    if ($data.Length -ne $entry.DeclaredBytes) {
        throw "Icon resource $($entry.ResourceId) contains $($data.Length) bytes, but the group declares $($entry.DeclaredBytes)."
    }
    [pscustomobject]@{
        Entry = $entry
        Data = $data
        Encoding = Get-EncodingName -Data $data
    }
}

$frameBytes = ($frames | ForEach-Object { $_.Data.Length } | Measure-Object -Sum).Sum
$icoLength = 6 + (16 * $frames.Count) + $frameBytes
$ico = [byte[]]::new($icoLength)
[BitConverter]::GetBytes([uint16]0).CopyTo($ico, 0)
[BitConverter]::GetBytes([uint16]1).CopyTo($ico, 2)
[BitConverter]::GetBytes([uint16]$frames.Count).CopyTo($ico, 4)
$dataOffset = 6 + (16 * $frames.Count)

for ($index = 0; $index -lt $frames.Count; $index++) {
    $frame = $frames[$index]
    $entryOffset = 6 + (16 * $index)
    $ico[$entryOffset] = $frame.Entry.WidthByte
    $ico[$entryOffset + 1] = $frame.Entry.HeightByte
    $ico[$entryOffset + 2] = $frame.Entry.ColorCount
    $ico[$entryOffset + 3] = $frame.Entry.Reserved
    [BitConverter]::GetBytes([uint16]$frame.Entry.Planes).CopyTo($ico, $entryOffset + 4)
    [BitConverter]::GetBytes([uint16]$frame.Entry.BitCount).CopyTo($ico, $entryOffset + 6)
    [BitConverter]::GetBytes([uint32]$frame.Data.Length).CopyTo($ico, $entryOffset + 8)
    [BitConverter]::GetBytes([uint32]$dataOffset).CopyTo($ico, $entryOffset + 12)
    $frame.Data.CopyTo($ico, $dataOffset)
    $dataOffset += $frame.Data.Length
}

if ($OutputPath) {
    $targetPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
    if ((Test-Path -LiteralPath $targetPath) -and -not $Force) {
        throw "The output file already exists: $targetPath (use -Force to replace it)"
    }
}
else {
    $defaultPath = Join-Path (Get-Location) ($source.BaseName + '.ico')
    $targetPath = Get-AvailableOutputPath -BasePath $defaultPath
}

$targetDirectory = [IO.Path]::GetDirectoryName($targetPath)
if (-not (Test-Path -LiteralPath $targetDirectory)) {
    [void](New-Item -ItemType Directory -Path $targetDirectory)
}

$temporaryPath = Join-Path $targetDirectory ('.' + [IO.Path]::GetFileName($targetPath) + '.' + [Guid]::NewGuid().ToString('N') + '.tmp')
try {
    [IO.File]::WriteAllBytes($temporaryPath, $ico)
    Move-Item -LiteralPath $temporaryPath -Destination $targetPath -Force:$Force
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath -Force
    }
}

Write-Host "Source: $($source.FullName)"
Write-Host "Group:  $($selected.Key) (language $($selected.Language))"
$frames | ForEach-Object {
    Write-Host ("  {0}x{1}, {2}-bit, {3}, {4:N0} bytes" -f $_.Entry.Width, $_.Entry.Height, $_.Entry.BitCount, $_.Encoding, $_.Data.Length)
}
Write-Host "Output: $targetPath ($($ico.Length.ToString('N0')) bytes)"
