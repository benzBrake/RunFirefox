# 约定
如果 `AGENTS.local.md` 文件存在，请优先遵循该文件中的约定。

## 多语言文本变更
这个项目的界面文本集中维护在 `Lang.ini`，AutoIt 代码通过 `_t("Key", "默认文本")` 读取。
凡是新增语言、增加/修改用户可见文本，必须同步处理多语言，避免只改一种语言。

约定如下：

- 新增用户可见文本时，优先新增或复用 `_t("Key", "默认文本")`，不要在界面、弹窗、提示、菜单等位置直接写死单一语言文本。
- 每新增一个 `_t` key，必须在 `Lang.ini` 的所有语言 section 中补齐同名 key；暂时无法准确翻译时，也要先填入可接受的英文或中文占位译文，不要缺 key。
- 修改已有文案时，要同步检查 `Lang.ini` 所有语言 section 的同名 key，保持含义一致。
- 文案里的占位符必须跨语言保持一致，例如 `{AppName}`、`{Version}`、`%s`、`%i`、`\n`，不能漏删或改名。
- 新增语言时，必须新增完整的语言 section，至少包含 `LangTitle`、`LangSupportAuthor`、`LangSupportUrl`，并补齐当前所有已有翻译 key；语言名优先使用 Firefox/Mozilla 下载链接可识别的语言代码格式，例如 `en-US`、`zh-CN`。
- 如果新增或修改的文本会出现在 README、指南、发布说明或用户说明中，要同步检查 `README.md` 与 `docs/README-en_US.md` 等对应中英文文档。
- 提交前用下面的 PowerShell 片段检查 `_t` key 与 `Lang.ini` section key 是否一致；如果输出缺失项，先补齐再提交：

```powershell
$codeFiles = @('.\RunFirefox.au3') + (Get-ChildItem .\libs -Filter '*.au3' -File | ForEach-Object { $_.FullName })
$code = [string]::Join("`n", ($codeFiles | ForEach-Object {
    Get-Content $_ | Where-Object { $_ -notmatch '^\s*;' }
}))
$codeKeys = [regex]::Matches($code, '_t\("([^"]+)"') |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique

$sections = @{}
$current = $null
foreach ($line in Get-Content .\Lang.ini) {
    if ($line -match '^\s*\[([^\]]+)\]\s*$') {
        $current = $Matches[1]
        $sections[$current] = [System.Collections.Generic.HashSet[string]]::new()
        continue
    }

    if ($current -and $line -match '^\s*([^=;\s][^=]*)=') {
        [void]$sections[$current].Add($Matches[1].Trim())
    }
}

foreach ($section in $sections.Keys) {
    $missing = $codeKeys | Where-Object { -not $sections[$section].Contains($_) }
    if ($missing) {
        Write-Host "[$section] missing:"
        $missing | ForEach-Object { Write-Host "  $_" }
    }
}
```

## AI 提交前检查
在 AI 准备创建 commit 之前，先运行：

```powershell
pwsh -File .\scripts\release-advisor.ps1 -PendingSubject "<commit subject>"
```

约定如下：

- commit message 尽量使用 Conventional Commits 风格，例如 `feat:`、`fix:`、`docs:`、`chore:`。
- 如果脚本输出 `Should release: yes`，AI 需要在提交说明里明确告知“建议补一个新 tag”，并附上建议 tag 名称。
- 如果脚本输出 `Should release: no`，AI 可以正常提交，但不要建议打 tag。
- 除非用户明确要求，否则 AI 不要自动创建或推送 tag。

当前仓库的自动构建逻辑是“先更新版本号和更新日志，再打 `v*` tag，由 workflow 校验版本并编译 release”。
为了让 AI 在 commit 前先判断这次改动是否值得发版，可以运行：

```powershell
pwsh -File .\scripts\release-advisor.ps1 -PendingSubject "feat: 你的提交标题"
```

默认策略是按当前仓库习惯判断：

1. 只要自上个 tag 以来有影响发布内容的改动，就建议递增一个 patch tag。
2. 只有文档、CI、`AGENTS.md`、`.gitignore` 之类改动时，不建议单独打 tag。
3. 如果想按 Conventional Commits 推断 major/minor/patch，可以加 `-VersionStrategy semver`。

例如当前输出如果是：

```text
Should release: yes
Suggested tag: v2.8.5
```

那就表示这次提交后比较适合补一个 `v2.8.5` tag，再交给现有 workflow 去构建 release。

日常开发时，所有尚未发布的用户可感知变更都写入 `CHANGELOG.md` 与 `docs/CHANGELOG-en_US.md` 顶部的 `## [Unreleased]`，不要追加到已经发布的版本段。

tag 之前：

1. 将两个 changelog 的 `Unreleased` 内容同步迁入新的 `## [X.Y.Z] - YYYY-MM-DD` 版本段，并保留空的 `Unreleased` 标题。
2. 更新 RunFirefox.au3 的文件版本号和 `$AppVersion`。
3. 提交上述发版准备改动后再创建 tag；如果 `Unreleased` 仍有内容，release workflow 会拒绝发布。
