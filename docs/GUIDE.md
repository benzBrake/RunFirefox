# 便携版制作指南

现在 `RunFirefox` 的设置界面已经可以直接下载并解压部分浏览器。  
如果你要制作的是 **Firefox、Chrome、Zen、Floorp、Waterfox、Helium、Naver Whale、百分浏览器（Cent Browser）** 便携版，优先使用内置下载会更省事。
像 **LibreWolf** 这类暂未内置下载的浏览器，再按下面的手动方式处理。

## 方式一：在设置里直接下载（适用于已支持的浏览器）

1. 先[下载 RunFirefox](https://github.com/benzBrake/RunFirefox/releases) 并解压出对应的启动器 exe（例如 `RunFirefox.exe`，如果没有适配图标也可以先随便选一个）。
2. 把启动器放到你准备存放便携版浏览器的文件夹里，然后运行它打开设置界面。
3. 在“浏览器”下拉框里选择目标浏览器；主程序路径通常会自动切到默认位置，例如 `.\Firefox\firefox.exe`。
4. 点击“下载浏览器”右侧的蓝色链接，等待下载和解压完成。
5. 下载完成后按提示直接启动，或保存设置后再手动启动即可。

## 方式二：手动制作（以 LibreWolf 为例）

1. 先[下载 RunLibreWolf](https://github.com/benzBrake/RunFirefox/releases) 并解压出 `RunLibreWolf.exe`（如果没有适配图标的，你可以随便选一个）。
2. 下载浏览器安装包，不要使用在线安装包，在线安装包里没有浏览器本体。
   - [Firefox](https://ftp.mozilla.org/pub/firefox/releases/)
   - [Floorp](https://github.com/Floorp-Projects/Floorp/releases/)，**不要选择 `floorp-stub.installer.exe`**
   - [LibreWolf](https://librewolf.net/installation/windows/)
3. 解压浏览器安装包。**LibreWolf** 的安装包不能用 WinRAR 打开，需要用到 **UniExtract2**：[点此下载](https://github.com/Bioruebe/UniExtract2/releases/download/v2.0.0-rc.3/UniExtractRC3.zip)
4. 使用 **UniExtract2** 提取安装包内容。
5. 把解压出来的浏览器文件和 `RunLibreWolf.exe` 放到同一个文件夹下。
6. 运行 `RunLibreWolf.exe` 并配置路径即可。
