# RunFirefox

[English Version](docs/README-en_US.md)

[![Stable](https://img.shields.io/github/v/release/benzBrake/RunFirefox?style=for-the-badge&label=%E7%A8%B3%E5%AE%9A%E7%89%88%E4%B8%8B%E8%BD%BD&color=2ea44f)](https://github.com/benzBrake/RunFirefox/releases/latest)
[![Beta](https://img.shields.io/badge/%E6%B5%8B%E8%AF%95%E7%89%88-nightly.link-orange?style=for-the-badge&logo=githubactions&logoColor=white)](https://nightly.link/benzBrake/RunFirefox/workflows/build/master)
[![Downloads](https://img.shields.io/github/downloads/benzBrake/RunFirefox/total?style=for-the-badge&label=%E7%B4%AF%E8%AE%A1%E4%B8%8B%E8%BD%BD)](https://github.com/benzBrake/RunFirefox/releases)

从 MyFirefox 修改而来，是 Firefox 的便携版引导器

1. 自定义Firefox浏览器程序文件、数据文件夹、缓存文件夹的位置等。
2. 制作Firefox便携版，可设为默认浏览器（与安装版一样，在浏览器设置里设置即可）。
3. 支持浏览器启动/退出时运行外部程序。
4. 支持锁定到任务栏后点击启动（打开浏览器后在任务栏右键锁定即可）

**[点此查看如何制作便携版？](docs/GUIDE.md)**

### 最近更新

2026.07.10 支持在设置界面选择 Vivaldi，并从官网解析、下载、解压 Windows x64 Stable 安装包；Vivaldi 不启用 Chrome++ 补丁

2026.07.10 支持在设置界面选择百分浏览器（Cent Browser），并从官网解析、下载、解压 Windows x64 便携版；百分浏览器不启用 Chrome++ 补丁

2026.07.10 Naver Whale 启动时会根据 RunFirefox 语言为简体/繁体中文追加 `--lang=zh-CN` 或 `--lang=zh-TW`，绕过 Whale 中文界面不生效的问题，改善中文用户体验

2026.07.10 支持在设置界面选择 Naver Whale，并在线下载、解压 Whale Windows x64 独立安装包

2026.07.07 优化 Chrome++ 新标签页禁用设置说明，明确安装补丁后相关选项会立即启用

2026.07.07 Chrome++ 设置页新增当前版本与最新版本检查，已安装补丁时可直接更新到新版

2026.07.06 辅助设置新增 Bosskey，可用键盘快捷键隐藏/还原浏览器，并可选择隐藏后显示托盘图标

2026.07.06 调整高级设置页布局，使缓存设置与 Chromium 设置区域和其他标签页保持一致的顶部间距

2026.07.06 高级设置新增缓存设置分组，可集中配置缓存目录与相关选项

2026.07.06 Chromium 设置新增 Google API 管理，可导入构建时注入的 API key、仅隐藏缺失 API 提示，或清理相关环境变量

2026.07.06 浏览器更新检查改为可配置频率，支持每次启动、每小时、每天、每周或从不检查，并显示当前版本、最新版本、位数与下载入口

2026.07.06 提取系统配置文件支持所有浏览器类型，并优化设置窗口布局、按钮高度与“辅助”标签页命名

2026.07.05 程序自身更新检查改为后台异步执行，避免启动时阻塞主流程

2026.07.05 浏览器类型识别优先读取可执行文件元数据，并在 README 增加稳定版、测试版与累计下载徽章

2026.07.04 更新便携版制作指南，说明可在设置界面直接下载部分浏览器，LibreWolf 等未内置下载的浏览器仍可按手动方式制作

2026.07.03 支持在设置界面选择 Helium，并在线下载、解压 Helium Windows x64 ZIP 包；Helium 作为 Chrome 系浏览器兼容 Chrome++ 补丁安装与设置页

2026.07.03 Chrome++ 设置页在未检测到补丁时增加“下载并安装 Chrome++”按钮，可直接安装到当前 Chrome 系浏览器目录

2026.07.03 Chrome++ 补丁安装失败时保留诊断日志，并在错误窗口提供查看日志按钮

2026.07.03 Chrome++ 补丁读取 GitHub 发布信息失败时，回退到 GitCode 镜像 tags 接口获取最新版本号

2026.07.02 支持在设置界面选择 Waterfox，并在线下载、解压 Waterfox Windows 64 位安装包

2026.07.02 支持在设置界面选择 Floorp，并在线下载、解压 Floorp Windows 64 位安装包

2026.07.02 新增 Firefox Developer Edition 与 Nightly 图标构建资源

2026.06.22 修复 Firefox / Mozilla 系浏览器开启自启动后留下的开机启动项，会在启动前后清理相关注册表项并移除配置文件中的开机启动偏好

2026.06.22 新增 Chrome 图标构建资源，并调整发布流程：tag 发布前需先更新版本号与更新日志，发布工作流会校验版本一致性后再构建

2026.06.04 优化多语言配置读取，启动时缓存 `Lang.ini`，减少界面与翻译文本的重复磁盘访问

2026.06.04 新增独立的 Chrome++ 设置页，可直接修改 `chrome++.ini` 的 `[tabs]` 相关选项；仅在当前浏览器为 Chrome 且已安装 Chrome++ 补丁时启用

2026.06.04 Chrome 缺少补丁时改为提示是否安装 Bush2021/chrome_plus，并显示异步下载/安装进度；如需完全自定义，可自行修改 `chrome++.ini`

2026.06.03 支持在设置界面在线下载并解压 Chrome

2026.06.01 支持在设置界面自动下载并解压 Firefox，下载过程显示置顶进度窗口

2026.06.01 新增繁体中文，支持按系统语言自动选择界面语言，并补全多语言缺失项

2026.06.01 重构 Firefox 下载与 GitHub 镜像逻辑，支持动态获取版本信息和 jsDelivr 回退

2026.06.01 修正 Firefox Developer Edition 更新通道，兼容 Zotero 数据路径处理

2026.05.27 移除 mozlz4 外部 exe，改为内置纯 AU3 解压、替换并压回 addonStartup 缓存

2025.03.30 支持增加图标后自动构建对应图标的 RunFirefox

2024.03.24 修复缓存设置失效的问题

2023.10.24 移除旧版本的更新地址，修复一直以来各种更新问题，支持设置 GitHub Mirror 选项

2023.04.15 新增浏览器自动更新开关

2023.04.12 支持多语言

2022.12.16 修复64位被更新为32位的问题

2022.12.08 检测到没有移位后不再处理扩展路径，优化冷启动速度

2022.11.14 尝试修复移位后扩展图标丢失，新增 FireDoge 和 Floorp 图标自动构建

2022.10.18 尝试增加扩展路径自动更新的功能（防止移位后扩展失效）

### 如何自定义图标构建

1. 克隆此项目
2. `icons`目录删除`Firefox.ico`以外的文件
3. 添加你想用于构建的图标，然后提交到 Github
4. 打 tag 后，push 到 GitHub 后会自动构建

### 如何下载

右边 Latest，如果你视力不好，按 Ctrl + F 在此页面查找文本 Latest

测试版下载链接：https://nightly.link/benzBrake/RunFirefox/workflows/build/master

### 感谢

甲壳虫 https://github.com/cnjackchen/

Justin Wong https://github.com/jusw85
