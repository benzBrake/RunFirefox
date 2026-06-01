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

tag 之前更新 README.md / README-en_US.md 中的更新日志
