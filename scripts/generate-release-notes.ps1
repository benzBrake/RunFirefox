param(
    [string]$Tag = '',
    [string]$ChineseChangelogPath = '.\CHANGELOG.md',
    [string]$EnglishChangelogPath = '.\docs\CHANGELOG-en_US.md',
    [string]$OutputPath = '.\release-notes.md',
    [switch]$ValidateOnly,
    [switch]$SkipReleasedSectionValidation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-ChangelogText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [Parameter(Mandatory = $true)]
        [string]$Language,
        [switch]$AllowMissingUnreleased
    )

    $versions = [ordered]@{}
    $unreleased = $null
    $current = $null
    $hasVersionSection = $false

    foreach ($line in @($Content -split '\r?\n')) {
        if ($line -match '^## \[Unreleased\]\s*$') {
            if ($null -ne $unreleased) { throw "$Language changelog contains duplicate [Unreleased] sections." }
            if ($hasVersionSection) { throw "$Language changelog must place [Unreleased] before all version sections." }
            $unreleased = [pscustomobject]@{
                Version = 'Unreleased'
                Date = ''
                Lines = [System.Collections.Generic.List[string]]::new()
            }
            $current = $unreleased
        } elseif ($line -match '^## \[(?<version>\d+\.\d+\.\d+)\] - (?<date>\d{4}-\d{2}-\d{2})\s*$') {
            $version = $Matches.version
            if ($versions.Contains($version)) { throw "$Language changelog contains duplicate version [$version]." }
            $current = [pscustomobject]@{
                Version = $version
                Date = $Matches.date
                Lines = [System.Collections.Generic.List[string]]::new()
            }
            $versions[$version] = $current
            $hasVersionSection = $true
        } elseif ($line -match '^##\s+') {
            if ($line.Trim() -ne '## Historical') {
                throw "$Language changelog contains an invalid level-two heading: $($line.Trim())"
            }
            $current = $null
        } elseif ($null -ne $current) {
            $current.Lines.Add($line)
        }
    }

    if ($null -eq $unreleased -and -not $AllowMissingUnreleased) {
        throw "$Language changelog does not contain a leading [Unreleased] section."
    }
    if ($versions.Count -eq 0) { throw "$Language changelog contains no version sections." }

    if ($null -ne $unreleased) {
        $unreleased.Lines = ($unreleased.Lines -join "`n").Trim()
    }
    $previousVersion = $null
    foreach ($item in $versions.GetEnumerator()) {
        $item.Value.Lines = ($item.Value.Lines -join "`n").Trim()
        if ([string]::IsNullOrWhiteSpace($item.Value.Lines)) {
            throw "$Language changelog section [$($item.Key)] is empty."
        }

        $parsedVersion = [version]$item.Key
        if ($null -ne $previousVersion -and $parsedVersion -ge $previousVersion) {
            throw "$Language changelog versions must be ordered from newest to oldest."
        }
        $previousVersion = $parsedVersion

        $releaseDate = [datetime]::ParseExact($item.Value.Date, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
        foreach ($entryLine in @($item.Value.Lines -split "`n")) {
            if ($entryLine -notmatch '^-\s+(?<date>\d{4}\.\d{2}\.\d{2})\s+') { continue }
            $entryDate = [datetime]::ParseExact($Matches.date, 'yyyy.MM.dd', [Globalization.CultureInfo]::InvariantCulture)
            if ($entryDate -gt $releaseDate) {
                throw "$Language changelog entry dated $($Matches.date) is newer than section [$($item.Key)] dated $($item.Value.Date). Add it to [Unreleased]."
            }
        }
    }

    return [pscustomobject]@{
        Unreleased = $unreleased
        Versions = $versions
    }
}

function Read-ChangelogFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Language
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Language changelog does not exist: $Path"
    }
    return Read-ChangelogText -Content (Get-Content -LiteralPath $Path -Raw) -Language $Language
}

function Assert-MatchingChangelogs {
    param($Chinese, $English)

    if (($Chinese.Versions.Keys -join "`n") -ne ($English.Versions.Keys -join "`n")) {
        throw 'Chinese and English changelog versions or ordering do not match.'
    }
    foreach ($version in $Chinese.Versions.Keys) {
        if ($Chinese.Versions[$version].Date -ne $English.Versions[$version].Date) {
            throw "Changelog dates do not match for [$version]."
        }
    }

    $zhUnreleasedEmpty = [string]::IsNullOrWhiteSpace($Chinese.Unreleased.Lines)
    $enUnreleasedEmpty = [string]::IsNullOrWhiteSpace($English.Unreleased.Lines)
    if ($zhUnreleasedEmpty -ne $enUnreleasedEmpty) {
        throw 'Chinese and English [Unreleased] sections must both be empty or both contain entries.'
    }
    if (-not $zhUnreleasedEmpty) {
        $zhCount = @($Chinese.Unreleased.Lines -split "`n" | Where-Object { $_ -match '^-\s+' }).Count
        $enCount = @($English.Unreleased.Lines -split "`n" | Where-Object { $_ -match '^-\s+' }).Count
        if ($zhCount -ne $enCount) {
            throw "Chinese and English [Unreleased] entry counts do not match ($zhCount vs $enCount)."
        }
    }
}

function Get-GitFileAtRef {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Ref,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $content = @(& git show "${Ref}:$RelativePath" 2>$null)
    if ($LASTEXITCODE -ne 0) { return $null }
    return ($content -join "`n")
}

function Get-BaselineSection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TagName,
        [Parameter(Mandatory = $true)]
        [string]$Version,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,
        [Parameter(Mandatory = $true)]
        [string]$Language
    )

    $tagContent = Get-GitFileAtRef -Ref $TagName -RelativePath $RelativePath
    if ($null -ne $tagContent) {
        $snapshot = Read-ChangelogText -Content $tagContent -Language $Language -AllowMissingUnreleased
        if ($snapshot.Versions.Contains($Version)) { return $snapshot.Versions[$Version] }
    }

    $commits = @(& git rev-list --reverse "$TagName..HEAD" -- $RelativePath 2>$null)
    if ($LASTEXITCODE -ne 0) { throw "Unable to inspect Git history for $RelativePath after $TagName." }
    foreach ($commit in $commits) {
        $content = Get-GitFileAtRef -Ref $commit -RelativePath $RelativePath
        if ($null -eq $content) { continue }
        try {
            $snapshot = Read-ChangelogText -Content $content -Language $Language -AllowMissingUnreleased
            if ($snapshot.Versions.Contains($Version)) { return $snapshot.Versions[$Version] }
        } catch {
            continue
        }
    }

    throw "Unable to find a changelog baseline for [$Version] in $RelativePath."
}

function Assert-ReleasedSectionsUnchanged {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Language,
        [Parameter(Mandatory = $true)]
        $Changelog
    )

    $gitRootOutput = @(& git rev-parse --show-toplevel 2>$null)
    $gitExitCode = $LASTEXITCODE
    $gitRoot = $gitRootOutput | Select-Object -First 1
    if ($gitExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($gitRoot)) {
        throw 'Released changelog validation requires a Git worktree.'
    }

    $fullPath = (Resolve-Path -LiteralPath $Path).Path
    $relativePath = [IO.Path]::GetRelativePath($gitRoot, $fullPath).Replace('\', '/')
    if ($relativePath.StartsWith('../', [StringComparison]::Ordinal) -or $relativePath -eq '..') {
        throw "Changelog path is outside the Git worktree: $Path"
    }

    $reachableTags = @(& git tag --merged HEAD --list 'v*' 2>$null)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to list reachable Git tags.' }
    $tagSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($tagName in $reachableTags) { [void]$tagSet.Add($tagName) }

    foreach ($version in $Changelog.Versions.Keys) {
        $tagName = "v$version"
        if (-not $tagSet.Contains($tagName)) { continue }
        $baseline = Get-BaselineSection -TagName $tagName -Version $version -RelativePath $relativePath -Language $Language
        $current = $Changelog.Versions[$version]
        if ($current.Date -ne $baseline.Date -or $current.Lines -ne $baseline.Lines) {
            throw "$Language changelog section [$version] differs from its released baseline at $tagName. Add new entries to [Unreleased]."
        }
    }
}

$zh = Read-ChangelogFile -Path $ChineseChangelogPath -Language 'Chinese'
$en = Read-ChangelogFile -Path $EnglishChangelogPath -Language 'English'
Assert-MatchingChangelogs -Chinese $zh -English $en

if (-not $SkipReleasedSectionValidation) {
    Assert-ReleasedSectionsUnchanged -Path $ChineseChangelogPath -Language 'Chinese' -Changelog $zh
    Assert-ReleasedSectionsUnchanged -Path $EnglishChangelogPath -Language 'English' -Changelog $en
}

if ($ValidateOnly) {
    $unreleasedCount = @($zh.Unreleased.Lines -split "`n" | Where-Object { $_ -match '^-\s+' }).Count
    Write-Host "Validated $($zh.Versions.Count) matching changelog versions and $unreleasedCount unreleased entries."
    exit 0
}

if ($Tag -notmatch '^v(?<version>\d+\.\d+\.\d+)$') {
    throw 'Tag must match vX.Y.Z unless -ValidateOnly is specified.'
}
$version = $Matches.version
if (-not [string]::IsNullOrWhiteSpace($zh.Unreleased.Lines)) {
    throw "[Unreleased] still contains entries. Move them to [$version] with a release date before creating $Tag."
}
if (-not $zh.Versions.Contains($version)) {
    throw "Chinese changelog does not contain version [$version]. Promote [Unreleased] to that version before creating the tag."
}

$notes = @('## 中文', '', $zh.Versions[$version].Lines, '', '## English', '', $en.Versions[$version].Lines) -join "`n"
$outputFullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
[IO.File]::WriteAllText($outputFullPath, "$notes`n", [Text.UTF8Encoding]::new($false))
Write-Host "Generated release notes for v$version at $OutputPath"
