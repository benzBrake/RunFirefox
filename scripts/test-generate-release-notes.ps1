Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$generator = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'generate-release-notes.ps1')).Path
$testRoot = Join-Path ([IO.Path]::GetTempPath()) "RunFirefox-release-notes-tests-$PID-$([guid]::NewGuid().ToString('N'))"
$utf8NoBom = [Text.UTF8Encoding]::new($false)
$passed = 0

function Write-Utf8File {
    param([string]$Path, [string]$Content)
    $parent = Split-Path -Parent $Path
    if ($parent) { [void](New-Item -ItemType Directory -Path $parent -Force) }
    [IO.File]::WriteAllText($Path, ($Content -replace "`r`n", "`n"), $utf8NoBom)
}

function New-ChangelogText {
    param(
        [string]$Title,
        [AllowEmptyString()]
        [string]$Unreleased,
        [string]$Version = '2.0.0',
        [string]$Released = '- 2026.09.01 Released item'
    )

    return @(
        "# $Title"
        ''
        '## [Unreleased]'
        ''
        $Unreleased
        ''
        "## [$Version] - 2026-09-01"
        ''
        $Released
        ''
    ) -join "`n"
}

function Set-FixtureChangelogs {
    param(
        [string]$Root,
        [AllowEmptyString()]
        [string]$ChineseUnreleased,
        [AllowEmptyString()]
        [string]$EnglishUnreleased,
        [string]$Version = '2.0.0',
        [string]$ChineseReleased = '- 2026.09.01 Released item',
        [string]$EnglishReleased = '- 2026.09.01 Released item'
    )

    Write-Utf8File -Path (Join-Path $Root 'CHANGELOG.md') -Content (New-ChangelogText -Title 'Chinese' -Unreleased $ChineseUnreleased -Version $Version -Released $ChineseReleased)
    Write-Utf8File -Path (Join-Path $Root 'docs/CHANGELOG-en_US.md') -Content (New-ChangelogText -Title 'English' -Unreleased $EnglishUnreleased -Version $Version -Released $EnglishReleased)
}

function Invoke-Generator {
    param(
        [string]$Root,
        [string[]]$Arguments
    )

    Push-Location $Root
    try {
        $outputLines = @(& pwsh -NoProfile -File $generator @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
        return [pscustomobject]@{
            ExitCode = $exitCode
            Output = ($outputLines -join "`n")
        }
    } finally {
        Pop-Location
    }
}

function Assert-Success {
    param([string]$Name, $Result)
    if ($Result.ExitCode -ne 0) { throw "$Name failed unexpectedly:`n$($Result.Output)" }
    $script:passed++
    Write-Host "PASS: $Name"
}

function Assert-FailureContains {
    param([string]$Name, $Result, [string]$Expected)
    if ($Result.ExitCode -eq 0) { throw "$Name succeeded unexpectedly." }
    if (-not $Result.Output.Contains($Expected, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Name did not report '$Expected':`n$($Result.Output)"
    }
    $script:passed++
    Write-Host "PASS: $Name"
}

function Invoke-TestGit {
    param([string]$Root, [string[]]$Arguments)
    $output = @(& git -C $Root @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed:`n$($output -join "`n")" }
}

function Initialize-TestRepository {
    param([string]$Root)
    Invoke-TestGit -Root $Root -Arguments @('init', '--quiet')
    Invoke-TestGit -Root $Root -Arguments @('config', 'user.name', 'Release Notes Test')
    Invoke-TestGit -Root $Root -Arguments @('config', 'user.email', 'release-notes-test@example.invalid')
}

function Commit-TestRepository {
    param([string]$Root, [string]$Message)
    Invoke-TestGit -Root $Root -Arguments @('add', '--all')
    Invoke-TestGit -Root $Root -Arguments @('-c', 'commit.gpgsign=false', 'commit', '--quiet', '-m', $Message)
}

try {
    [void](New-Item -ItemType Directory -Path $testRoot)
    $fixture = Join-Path $testRoot 'fixture'
    [void](New-Item -ItemType Directory -Path $fixture)

    Set-FixtureChangelogs -Root $fixture -ChineseUnreleased "- 2026.09.02 Pending A`n- 2026.09.03 Pending B" -EnglishUnreleased "- 2026.09.02 Pending A`n- 2026.09.03 Pending B"
    Assert-Success -Name 'non-empty Unreleased validates' -Result (Invoke-Generator -Root $fixture -Arguments @('-ValidateOnly', '-SkipReleasedSectionValidation'))

    Set-FixtureChangelogs -Root $fixture -ChineseUnreleased '' -EnglishUnreleased ''
    Assert-Success -Name 'empty Unreleased validates' -Result (Invoke-Generator -Root $fixture -Arguments @('-ValidateOnly', '-SkipReleasedSectionValidation'))

    Set-FixtureChangelogs -Root $fixture -ChineseUnreleased '' -EnglishUnreleased '' -ChineseReleased '- 2026.09.02 Added too late' -EnglishReleased '- 2026.09.02 Added too late'
    Assert-FailureContains -Name 'post-release dated entries are rejected' -Result (Invoke-Generator -Root $fixture -Arguments @('-ValidateOnly', '-SkipReleasedSectionValidation')) -Expected 'is newer than section [2.0.0]'

    $missingUnreleased = "# Chinese`n`n## [2.0.0] - 2026-09-01`n`n- Released`n"
    Write-Utf8File -Path (Join-Path $fixture 'CHANGELOG.md') -Content $missingUnreleased
    Assert-FailureContains -Name 'missing Unreleased is rejected' -Result (Invoke-Generator -Root $fixture -Arguments @('-ValidateOnly', '-SkipReleasedSectionValidation')) -Expected 'does not contain a leading [Unreleased]'

    $misplaced = "# Chinese`n`n## [2.0.0] - 2026-09-01`n`n- Released`n`n## [Unreleased]`n"
    Write-Utf8File -Path (Join-Path $fixture 'CHANGELOG.md') -Content $misplaced
    Assert-FailureContains -Name 'misplaced Unreleased is rejected' -Result (Invoke-Generator -Root $fixture -Arguments @('-ValidateOnly', '-SkipReleasedSectionValidation')) -Expected 'must place [Unreleased] before'

    Set-FixtureChangelogs -Root $fixture -ChineseUnreleased "- Pending A`n- Pending B" -EnglishUnreleased '- Pending A'
    Assert-FailureContains -Name 'bilingual entry count mismatch is rejected' -Result (Invoke-Generator -Root $fixture -Arguments @('-ValidateOnly', '-SkipReleasedSectionValidation')) -Expected 'entry counts do not match'

    Set-FixtureChangelogs -Root $fixture -ChineseUnreleased '- Pending release' -EnglishUnreleased '- Pending release'
    Assert-FailureContains -Name 'tag rejects pending Unreleased entries' -Result (Invoke-Generator -Root $fixture -Arguments @('-Tag', 'v2.0.0', '-SkipReleasedSectionValidation')) -Expected '[Unreleased] still contains entries'

    Set-FixtureChangelogs -Root $fixture -ChineseUnreleased '' -EnglishUnreleased ''
    Assert-Success -Name 'tag generates notes after Unreleased is archived' -Result (Invoke-Generator -Root $fixture -Arguments @('-Tag', 'v2.0.0', '-OutputPath', '.\notes.md', '-SkipReleasedSectionValidation'))
    $notes = Get-Content -LiteralPath (Join-Path $fixture 'notes.md') -Raw
    if ($notes -match 'Unreleased' -or $notes -notmatch '## 中文' -or $notes -notmatch '## English') {
        throw "Generated notes contain the wrong sections:`n$notes"
    }
    $passed++
    Write-Host 'PASS: generated notes contain only the tagged bilingual release'

    Assert-FailureContains -Name 'invalid tag format is rejected' -Result (Invoke-Generator -Root $fixture -Arguments @('-Tag', '2.0.0', '-SkipReleasedSectionValidation')) -Expected 'Tag must match vX.Y.Z'
    Assert-FailureContains -Name 'missing tag version is rejected' -Result (Invoke-Generator -Root $fixture -Arguments @('-Tag', 'v2.0.1', '-SkipReleasedSectionValidation')) -Expected 'does not contain version [2.0.1]'

    $taggedRepo = Join-Path $testRoot 'tagged-repo'
    [void](New-Item -ItemType Directory -Path $taggedRepo)
    Initialize-TestRepository -Root $taggedRepo
    Set-FixtureChangelogs -Root $taggedRepo -ChineseUnreleased '' -EnglishUnreleased '' -Version '1.0.0'
    Commit-TestRepository -Root $taggedRepo -Message 'release 1.0.0'
    Invoke-TestGit -Root $taggedRepo -Arguments @('tag', 'v1.0.0')
    Set-FixtureChangelogs -Root $taggedRepo -ChineseUnreleased '- Pending' -EnglishUnreleased '- Pending' -Version '1.0.0'
    Assert-Success -Name 'released baseline permits Unreleased changes' -Result (Invoke-Generator -Root $taggedRepo -Arguments @('-ValidateOnly'))
    Set-FixtureChangelogs -Root $taggedRepo -ChineseUnreleased '- Pending' -EnglishUnreleased '- Pending' -Version '1.0.0' -ChineseReleased '- Changed old release' -EnglishReleased '- Changed old release'
    Assert-FailureContains -Name 'released baseline rejects old section edits' -Result (Invoke-Generator -Root $taggedRepo -Arguments @('-ValidateOnly')) -Expected 'differs from its released baseline'

    $legacyRepo = Join-Path $testRoot 'legacy-repo'
    [void](New-Item -ItemType Directory -Path $legacyRepo)
    Initialize-TestRepository -Root $legacyRepo
    Write-Utf8File -Path (Join-Path $legacyRepo 'seed.txt') -Content "before changelogs`n"
    Commit-TestRepository -Root $legacyRepo -Message 'release without changelogs'
    Invoke-TestGit -Root $legacyRepo -Arguments @('tag', 'v1.0.0')
    Set-FixtureChangelogs -Root $legacyRepo -ChineseUnreleased '' -EnglishUnreleased '' -Version '1.0.0'
    Commit-TestRepository -Root $legacyRepo -Message 'add changelogs'
    Assert-Success -Name 'legacy tag uses first later changelog as baseline' -Result (Invoke-Generator -Root $legacyRepo -Arguments @('-ValidateOnly'))
    Set-FixtureChangelogs -Root $legacyRepo -ChineseUnreleased '- Pending' -EnglishUnreleased '- Pending' -Version '1.0.0' -ChineseReleased '- Changed legacy release' -EnglishReleased '- Changed legacy release'
    Assert-FailureContains -Name 'legacy baseline rejects old section edits' -Result (Invoke-Generator -Root $legacyRepo -Arguments @('-ValidateOnly')) -Expected 'differs from its released baseline'

    Write-Host "All $passed release note generator tests passed."
} finally {
    if (Test-Path -LiteralPath $testRoot) {
        # Git/antivirus processes on hosted Windows runners can briefly retain
        # files in the temporary repositories after the assertions complete.
        Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
