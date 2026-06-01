param(
    [ValidateSet('project', 'semver')]
    [string]$VersionStrategy = 'project',
    [string]$PendingSubject = '',
    [string]$PendingBody = '',
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $output = & git @Arguments 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed."
    }

    return @($output)
}

function Test-IgnoredFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $normalized = $Path -replace '\\', '/'
    return $normalized -match '^(README(?:-en_US)?\.md|AGENTS(?:\.local)?\.md|\.github/|scripts/release-advisor\.ps1$|\.gitignore$)'
}

function Get-BumpWeight {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Bump
    )

    switch ($Bump) {
        'major' { return 3 }
        'minor' { return 2 }
        'patch' { return 1 }
        default { return 0 }
    }
}

function Get-BumpLevel {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Subject,
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Body,
        [Parameter(Mandatory = $true)]
        [bool]$Impactful,
        [Parameter(Mandatory = $true)]
        [string]$Strategy,
        [Parameter(Mandatory = $false)]
        [bool]$IsPending = $false
    )

    if (-not $Impactful) {
        return 'none'
    }

    if ($Strategy -eq 'project') {
        return 'patch'
    }

    if ($Subject -match '^[a-zA-Z]+(?:\([^)]+\))?!:') {
        return 'major'
    }

    if ($Body -match '(?im)^BREAKING CHANGE:') {
        return 'major'
    }

    if ($Subject -match '^feat(?:\([^)]+\))?:') {
        return 'minor'
    }

    if ($Subject -match '^(fix|perf|refactor)(?:\([^)]+\))?:') {
        return 'patch'
    }

    if ($IsPending -and [string]::IsNullOrWhiteSpace($Subject)) {
        return 'patch'
    }

    return 'patch'
}

function Get-NextTag {
    param(
        [string]$LatestTag,
        [string]$Bump
    )

    if ($Bump -eq 'none') {
        return ''
    }

    if (-not $LatestTag) {
        switch ($Bump) {
            'major' { return 'v1.0.0' }
            'minor' { return 'v0.1.0' }
            default { return 'v0.0.1' }
        }
    }

    if ($LatestTag -notmatch '^v(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)$') {
        throw "Unsupported tag format: $LatestTag"
    }

    $major = [int]$Matches.major
    $minor = [int]$Matches.minor
    $patch = [int]$Matches.patch

    switch ($Bump) {
        'major' { return "v$($major + 1).0.0" }
        'minor' { return "v$major.$($minor + 1).0" }
        'patch' { return "v$major.$minor.$($patch + 1)" }
        default { return '' }
    }
}

$allTags = Invoke-Git -Arguments @('tag', '--sort=-version:refname')
$latestTag = ($allTags | Where-Object { $_ -match '^v\d+\.\d+\.\d+$' } | Select-Object -First 1)

$commitRange = if ($latestTag) { "$latestTag..HEAD" } else { 'HEAD' }
$commitShas = Invoke-Git -Arguments @('rev-list', '--reverse', $commitRange)

$commitResults = New-Object System.Collections.Generic.List[object]

foreach ($sha in $commitShas) {
    $subject = ((Invoke-Git -Arguments @('show', '-s', '--format=%s', $sha)) -join "`n").Trim()
    $body = (Invoke-Git -Arguments @('show', '-s', '--format=%b', $sha)) -join "`n"
    $files = Invoke-Git -Arguments @('show', '--pretty=format:', '--name-only', $sha)
    $files = @($files | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $impactful = @($files | Where-Object { -not (Test-IgnoredFile $_) }).Count -gt 0
    $bump = Get-BumpLevel -Subject $subject -Body $body -Impactful $impactful -Strategy $VersionStrategy

    $commitResults.Add([pscustomobject]@{
        sha       = $sha
        shortSha  = $sha.Substring(0, [Math]::Min(7, $sha.Length))
        subject   = $subject
        impactful = $impactful
        bump      = $bump
        files     = $files
        source    = 'commit'
    })
}

$pendingFiles = @(@(
    Invoke-Git -Arguments @('diff', '--cached', '--name-only')
    Invoke-Git -Arguments @('diff', '--name-only')
    Invoke-Git -Arguments @('ls-files', '--others', '--exclude-standard')
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)

if ($pendingFiles.Count -gt 0) {
    $impactful = @($pendingFiles | Where-Object { -not (Test-IgnoredFile $_) }).Count -gt 0
    $bump = Get-BumpLevel -Subject $PendingSubject -Body $PendingBody -Impactful $impactful -Strategy $VersionStrategy -IsPending $true

    $commitResults.Add([pscustomobject]@{
        sha       = 'WORKTREE'
        shortSha  = 'WORKTREE'
        subject   = if ($PendingSubject) { $PendingSubject } else { '(pending changes)' }
        impactful = $impactful
        bump      = $bump
        files     = $pendingFiles
        source    = 'worktree'
    })
}

$impactfulItems = @($commitResults | Where-Object { $_.impactful })
$ignoredItems = @($commitResults | Where-Object { -not $_.impactful })

$recommendedBump = 'none'
foreach ($item in $impactfulItems) {
    if ((Get-BumpWeight $item.bump) -gt (Get-BumpWeight $recommendedBump)) {
        $recommendedBump = $item.bump
    }
}

$shouldRelease = $recommendedBump -ne 'none'
$suggestedTag = if ($shouldRelease) { Get-NextTag -LatestTag $latestTag -Bump $recommendedBump } else { '' }
$releasableFiles = @($impactfulItems | ForEach-Object { $_.files } | Sort-Object -Unique)
$ignoredFiles = @($ignoredItems | ForEach-Object { $_.files } | Sort-Object -Unique)

if (-not $shouldRelease) {
    $reason = '自上个 tag 以来只有文档、CI 或仓库维护类改动，不建议单独打新 tag。'
} elseif ($VersionStrategy -eq 'project') {
    $reason = "发现 $($impactfulItems.Count) 个会影响发布内容的提交或工作区改动，按当前仓库习惯建议递增 patch tag。"
} else {
    $reason = "发现 $($impactfulItems.Count) 个会影响发布内容的提交或工作区改动，按 Conventional Commits 推断建议 bump $recommendedBump。"
}

$result = [pscustomobject]@{
    latestTag            = if ($latestTag) { $latestTag } else { '' }
    strategy             = $VersionStrategy
    commitRange          = $commitRange
    analyzedItemCount    = $commitResults.Count
    impactfulItemCount   = $impactfulItems.Count
    ignoredItemCount     = $ignoredItems.Count
    shouldRelease        = $shouldRelease
    recommendedBump      = $recommendedBump
    suggestedTag         = $suggestedTag
    releasableFiles      = $releasableFiles
    ignoredFiles         = $ignoredFiles
    reason               = $reason
    items                = $commitResults
}

if ($Json) {
    $result | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "Latest tag: $($result.latestTag)"
Write-Host "Strategy: $($result.strategy)"
Write-Host "Should release: $(if ($result.shouldRelease) { 'yes' } else { 'no' })"
if ($result.shouldRelease) {
    Write-Host "Recommended bump: $($result.recommendedBump)"
    Write-Host "Suggested tag: $($result.suggestedTag)"
}
Write-Host "Reason: $($result.reason)"

if ($impactfulItems.Count -gt 0) {
    Write-Host ""
    Write-Host "Release-relevant items:"
    foreach ($item in $impactfulItems) {
        Write-Host "- [$($item.shortSha)] $($item.subject) [$($item.bump)]"
    }
}

if ($ignoredItems.Count -gt 0) {
    Write-Host ""
    Write-Host "Ignored items:"
    foreach ($item in $ignoredItems) {
        Write-Host "- [$($item.shortSha)] $($item.subject)"
    }
}
