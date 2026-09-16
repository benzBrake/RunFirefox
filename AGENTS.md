# RunFirefox 项目约定

## 1. 适用范围与优先级

- 本文件适用于项目内所有开发、测试、构建和文档变更。
- 如果存在 `AGENTS.local.md`，先遵循其中的本地环境和用户偏好约定。
- 修改前先检查 `git status`，保留用户已有改动，不覆盖无关文件。
- 默认文件编码为 UTF-8，无 BOM；默认换行符为 LF。
- `.bat`、`.cmd` 使用 GBK 编码和 CRLF 换行。
- `.reg` 使用 UTF-16LE 编码和 CRLF 换行。

## 2. 项目结构

- `RunFirefox.au3`：主 AutoIt 源文件。
- `libs/*.au3`：AutoIt 功能模块。
- `Lang.ini`：内置多语言文本源文件。
- `LangCustom.ini`：用户自定义语言模板，不是生成文件。
- `libs/LangData.au3`：由 `Lang.ini` 生成的内嵌语言数据。
- `icons/`：构建使用的浏览器图标。
- `scripts/`：构建、测试、资源处理和发布辅助脚本。
- `.github/workflows/build.yml`：CI、Nightly 和 Release 构建流程。
- `README.md`、`docs/`：项目说明、使用指南和英文文档。
- `CHANGELOG.md`、`docs/CHANGELOG-en_US.md`：中英文更新日志。

## 3. AutoIt 开发约定

- 保持现有 AutoIt 3.3.14.x 兼容性。
- 公共功能优先放入对应的 `libs/*.au3`，避免继续扩大 `RunFirefox.au3`。
- 修改下载、浏览器版本检测、更新或安装逻辑时，优先复用现有模块。
- 注意同时兼容 x86 和 x64 构建；除非功能明确不支持，否则不要依赖启动器自身位数判断浏览器架构。
- 不要手工修改构建生成的 EXE 文件。
- `RunFirefox.au3` 中的文件版本号和 `$AppVersion` 必须保持一致。

## 4. 下载与网络请求

- 所有 HTTP GET/POST、版本元数据读取、浏览器安装包下载、自动更新和 Chrome++ 补丁下载，必须通过 `libs/DownloadTools.au3` 提供的统一函数。
- 业务模块不得直接调用 `InetGet`、`InetRead`，也不得拼接或执行 `curl` 命令。
- URL 分类、镜像顺序、代理配置、超时和失败回退统一由下载工具处理。
- 代理模式下应遵循下载工具的直连策略，不要在业务模块中自行追加镜像。
- 新增或调整下载源时，同时更新相应测试脚本。

## 5. 多语言文本

- 所有用户可见文本优先使用 `_t("Key", "默认文本")`，不要在界面、菜单、弹窗或提示中直接写死单一语言。
- 新增或修改 `_t` key 时，必须同步更新 `Lang.ini` 的所有语言 section。
- 修改 `Lang.ini` 后必须运行：

  ```powershell
  pwsh -File .\scripts\update-langdata.ps1
  ```

- 不要手工编辑 `libs/LangData.au3`。
- `LangCustom.ini` 是运行时覆盖模板；新增语言或新增 key 时，应同步维护其中的示例 section。
- 各语言中的占位符必须保持一致，例如 `{AppName}`、`{Version}`、`%s`、`%i` 和 `\n`。
- 新增语言至少应包含 `LangTitle`、`LangSupportAuthor` 和 `LangSupportUrl`，语言代码优先使用 Firefox/Mozilla 可识别的格式。
- 提交前检查代码中的 `_t` key 是否在所有 `Lang.ini` section 中存在。

## 6. 测试与验证

修改后根据影响范围运行相关测试。常用命令包括：

```powershell
pwsh -File .\scripts\test-download-routing.ps1
pwsh -File .\scripts\test-generate-release-notes.ps1
pwsh -File .\scripts\test-network-settings.ps1
pwsh -File .\scripts\test-opera-download.ps1
pwsh -File .\scripts\test-vivaldi-download.ps1
pwsh -File .\scripts\test-whale-download.ps1
pwsh -File .\scripts\test-bundled-chrome-plus.ps1
pwsh -File .\scripts\generate-release-notes.ps1 -ValidateOnly
```

- 需要 AutoIt 的测试默认使用 `C:\Program Files\AutoIt3`。
- 修改语言、下载、版本检测或发布脚本时，不要只做静态检查，应运行对应测试。
- 提交前确认没有生成临时 harness、测试输出、`.part` 文件或未跟踪构建产物。

## 7. 构建约定

- 构建前确保 `libs/LangData.au3` 已由最新的 `Lang.ini` 生成。
- 本地构建使用 AutoIt3Wrapper，并同时验证 x86/x64 输出。
- CI 在推送到 `master` 或 Pull Request 时执行验证和 Nightly 构建。
- Release 仅由符合 `vX.Y.Z` 格式的 Git tag 触发。
- Release workflow 会校验 Git tag 版本、`RunFirefox.au3` 中的文件版本号、`$AppVersion`、中英文 changelog 和 Release 产物。

## 8. Changelog 与发布

- 所有未发布的用户可感知变更写入两个 changelog 顶部的 `[Unreleased]`：
  - `CHANGELOG.md`
  - `docs/CHANGELOG-en_US.md`
- 中英文 changelog 的版本、日期和条目数量应保持同步。
- 创建 tag 前：
  1. 将 `[Unreleased]` 条目迁移到新的版本段；
  2. 保留空的 `[Unreleased]` 标题；
  3. 更新 `RunFirefox.au3` 的文件版本号和 `$AppVersion`；
  4. 运行 changelog 验证脚本。
- 准备提交前运行：

  ```powershell
  pwsh -File .\scripts\release-advisor.ps1 -PendingSubject "<commit subject>"
  ```

- 如果输出 `Should release: yes`，在提交说明中提示建议创建对应的新 tag。
- 除非用户明确要求，不自动创建或推送 tag。
- 提交信息优先使用英文 Conventional Commits 格式，例如 `feat:`、`fix:`、`docs:`、`chore:`。

## 9. 文档同步

- 用户可见功能、配置、下载行为或语言行为发生变化时，同步检查 `README.md`、`docs/README-en_US.md`、`docs/GUIDE.md` 和中英文 changelog。
- 不要在文档中写入本地代理地址、个人路径或临时测试信息。

## 10. 安全与变更边界

- 不提交 API 密钥、代理认证信息或其他凭据。
- 不使用危险的递归删除、强制覆盖或破坏性 Git 操作，除非用户明确要求。
- 不修改与当前任务无关的用户文件或已有改动。
