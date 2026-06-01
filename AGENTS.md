# 约定
如果 `AGENTS.local.md` 文件存在，请优先遵循该文件中的约定。

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

当前仓库的自动构建逻辑仍然是“先打 `v*` tag，再由 workflow 回写版本号并编译 release”。
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

tag 之前更新 README.md / README-en_US.md 中的更新日志
