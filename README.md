# RunFirefox

[English Version](docs/README-en_US.md)

[![Stable](https://img.shields.io/github/v/release/benzBrake/RunFirefox?style=for-the-badge&label=%E7%A8%B3%E5%AE%9A%E7%89%88%E4%B8%8B%E8%BD%BD&color=2ea44f)](https://github.com/benzBrake/RunFirefox/releases/latest)
[![Beta](https://img.shields.io/badge/%E6%B5%8B%E8%AF%95%E7%89%88-nightly.link-orange?style=for-the-badge&logo=githubactions&logoColor=white)](https://nightly.link/benzBrake/RunFirefox/workflows/build/master)
[![Downloads](https://img.shields.io/github/downloads/benzBrake/RunFirefox/total?style=for-the-badge&label=%E7%B4%AF%E8%AE%A1%E4%B8%8B%E8%BD%BD)](https://github.com/benzBrake/RunFirefox/releases)

RunFirefox 从 MyFirefox 演进而来，是支持 Gecko 与 Chromium 系浏览器的便携版启动器。

1. 自定义浏览器程序文件、用户数据文件夹和缓存文件夹的位置等。
2. 制作支持的浏览器便携版，并可设为默认浏览器（与安装版一样，在浏览器设置里设置即可）。
3. 支持浏览器启动/退出时运行外部程序。
4. 支持锁定到任务栏后点击启动（打开浏览器后在任务栏右键锁定即可）
5. Gecko 与 Chromium 系浏览器的 Jump List 提供常用网站、浏览器启动任务和启动器设置入口。

**[点此查看如何制作便携版？](docs/GUIDE.md)**

**[查看完整更新日志](CHANGELOG.md)**

### Brave / Whale 的 Chrome++

Chrome++ 标签页保留可选安装和标签操作设置。Brave、Whale 使用内置自编译 DLL，按浏览器 EXE 的实际 x86/x64 架构离线安装，与启动器位数无关；不支持 ARM64。页面显示已安装版本和内置版本，文件不一致时可手动替换为内置版，无需查询上游更新。配置沿用 RunFirefox 默认值并保留用户自定义配置，`libs/chrome_plus/chrome++.ini` 仅作参考。

### 如何自定义图标构建

1. 克隆此项目
2. `icons`目录删除`Firefox.ico`以外的文件
3. 添加你想用于构建的图标，然后提交到 Github
4. 打 tag 后，push 到 GitHub 后会自动构建

### 从浏览器 EXE 提取图标

将浏览器的 EXE 或 DLL 拖到 `scripts\extract-exe-icon.cmd` 上，即可在当前目录生成同名 ICO。工具直接复制程序中的原始多尺寸图标资源，不会缩放或重新编码图像帧。

浏览器程序通常包含主程序、隐私模式、测试版和文件关联等多个图标组。可先列出所有图标组，再指定需要提取的组：

```powershell
pwsh -File .\scripts\extract-exe-icon.ps1 -ExePath "C:\Path\browser.exe" -List
pwsh -File .\scripts\extract-exe-icon.ps1 -ExePath "C:\Path\browser.exe" -Group IDR_MAINFRAME -OutputPath .\icons\Browser.ico
```

未指定 `-Group` 时提取第一个图标组。目标文件已存在时需显式添加 `-Force` 才会覆盖。

如果提取出的 ICO 因 256×256 未压缩 DIB 帧而过大，可将 ICO 拖到 `scripts\compress-ico.cmd` 上。工具仅把 256×256 DIB 转成更小的 PNG，小尺寸兼容帧保持不变，并在源文件旁生成 `原名.compressed.ico`，不会覆盖源文件。

也可以通过命令行指定输出路径：

```powershell
pwsh -File .\scripts\compress-ico.ps1 -Paths .\icons\Whale.ico -OutputPath .\icons\Whale.compressed.ico
```

### 如何下载

右边 Latest，如果你视力不好，按 Ctrl + F 在此页面查找文本 Latest

测试版下载链接：https://nightly.link/benzBrake/RunFirefox/workflows/build/master

### 感谢

甲壳虫 https://github.com/cnjackchen/

Justin Wong https://github.com/jusw85
