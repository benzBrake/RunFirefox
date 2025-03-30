# RunFirefox

[English Version](README-en_US.md)

从 MyFirefox 修改而来，是 Firefox 的便携版引导器

1. 自定义Firefox浏览器程序文件、数据文件夹、缓存文件夹的位置等。
2. 制作Firefox便携版，可设为默认浏览器（与安装版一样，在浏览器设置里设置即可）。
3. 支持浏览器启动/退出时运行外部程序。
4. 支持锁定到任务栏后点击启动（打开浏览器后在任务栏右键锁定即可）

### 最近更新

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

### 其他说明

mozlz4-win32.exe 和 mozlz4-win64.exe 来自 [jusw85/mozlz4: Decompress / compress mozlz4 files, with precompiled binaries for Windows and Linux](https://github.com/jusw85/mozlz4)

### 感谢

甲壳虫 https://github.com/cnjackchen/

Justin Wong https://github.com/jusw85
