# 便携版制作指南

现在 `RunFirefox` 的设置界面已经可以直接下载并解压支持的浏览器。
如果你要制作的是 **Firefox、Chrome、Ungoogled Chromium、迅雷浏览器、涡轮浏览器（Turbo Browser）、Zen、Floorp、Waterfox、LibreWolf、Helium、Naver Whale、百分浏览器（Cent Browser）、Vivaldi、Opera、Brave** 便携版，优先使用内置下载会更省事。

## 方式一：在设置里直接下载（适用于已支持的浏览器）

1. 先[下载 RunFirefox](https://github.com/benzBrake/RunFirefox/releases) 并解压出对应的启动器 exe（例如 `RunFirefox.exe`，如果没有适配图标也可以先随便选一个）。
2. 把启动器放到你准备存放便携版浏览器的文件夹里，然后运行它打开设置界面。
3. 在“浏览器”下拉框里选择目标浏览器；主程序路径通常会自动切到默认位置，例如 `.\Firefox\firefox.exe`。
4. 点击“下载浏览器”右侧的蓝色链接，等待下载和解压完成。
5. 下载完成后按提示直接启动，或保存设置后再手动启动即可。

LibreWolf 会固定下载官网提供的 Windows x64 portable ZIP；即使压缩包是“版本目录\LibreWolf”双层结构，启动器也会自动提取其中的 `LibreWolf` 程序目录。

涡轮浏览器会优先从国内官网下载 Windows x64 绿色版 7z，下载失败时再尝试 GitHub 镜像和官方 Release 地址；涡轮浏览器不启用 Chrome++ 补丁。

迅雷浏览器会从迅雷官网解析当前 Windows x64 安装包地址并下载；官网解析失败时可打开官网手动下载。

Opera 会从官方 FTP 读取所选渠道（stable/beta/dev）的最新版本并下载 Windows x64 离线安装包自动解压；FTP 解析失败时可打开官网手动下载。

## 方式二：手动制作（适用于未内置下载的浏览器）

1. 下载对应的 RunFirefox 启动器并放入目标浏览器目录。
2. 从浏览器官网下载完整安装包或便携压缩包，不要使用只负责联网下载的在线安装器。
3. 解压浏览器文件后，在启动器设置中手动选择浏览器主程序。
