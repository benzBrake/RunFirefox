# RunFirefox

[![Stable](https://img.shields.io/github/v/release/benzBrake/RunFirefox?style=for-the-badge&label=Stable%20Download&color=2ea44f)](https://github.com/benzBrake/RunFirefox/releases/latest)
[![Beta](https://img.shields.io/badge/Beta-nightly.link-orange?style=for-the-badge&logo=githubactions&logoColor=white)](https://nightly.link/benzBrake/RunFirefox/workflows/build/master)
[![Downloads](https://img.shields.io/github/downloads/benzBrake/RunFirefox/total?style=for-the-badge&label=Downloads)](https://github.com/benzBrake/RunFirefox/releases)

Evolved from MyFirefox, RunFirefox is a portable browser launcher for Gecko and Chromium-based browsers.

Features:
1. Customize the locations of browser program files, user data, and cache folders.
2. Create portable versions of supported browsers and set them as the default browser through their settings.
3. Support for running external programs when the browser starts or exits.
4. Support for launching the browser by clicking on the taskbar icon (right-click and select "Pin to taskbar" after opening the browser).
5. Jump Lists for Gecko and Chromium-based browsers include frequent sites, browser launch tasks, and a launcher settings entry.

**[View the full changelog](CHANGELOG-en_US.md)**

### Chrome++ for Brave / Whale

The Chrome++ tab retains optional installation and tab settings. Brave and Whale use bundled custom DLLs, installed offline according to the browser EXE's x86/x64 architecture regardless of launcher bitness; ARM64 is unsupported. The tab shows installed and bundled versions and allows manual replacement when files differ, without checking upstream updates. Installation uses RunFirefox defaults and preserves custom configurations; `libs/chrome_plus/chrome++.ini` is a reference only.

### Extracting an icon from a browser EXE

Drop a browser EXE or DLL onto `scripts\extract-exe-icon.cmd` to create a same-named ICO in the current directory. The tool copies the original multi-size icon resources directly, without resizing or re-encoding the image frames.

Browser executables often contain separate icon groups for the main program, private mode, preview channels, and file associations. List the available groups first, then select the one to extract:

```powershell
pwsh -File .\scripts\extract-exe-icon.ps1 -ExePath "C:\Path\browser.exe" -List
pwsh -File .\scripts\extract-exe-icon.ps1 -ExePath "C:\Path\browser.exe" -Group IDR_MAINFRAME -OutputPath .\icons\Browser.ico
```

Without `-Group`, the first icon group is extracted. Add `-Force` explicitly to replace an existing output file.

If an extracted ICO is large because it contains an uncompressed 256x256 DIB frame, drop it onto `scripts\compress-ico.cmd`. The tool converts only 256x256 DIB frames to smaller PNG frames, leaves the compatibility-sized frames unchanged, and writes `name.compressed.ico` beside the source without overwriting it.

You can also specify the output path from the command line:

```powershell
pwsh -File .\scripts\compress-ico.ps1 -Paths .\icons\Whale.ico -OutputPath .\icons\Whale.compressed.ico
```

### How to download

Click on the "Latest" button on the right. If you have trouble finding it, press Ctrl+F and search for the text "Latest" on this page.

Beta builds: https://nightly.link/benzBrake/RunFirefox/workflows/build/master

### Thanks to

cnjackchen: https://github.com/cnjackchen/

Justin Wong: https://github.com/jusw85
