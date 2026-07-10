# RunFirefox

[![Stable](https://img.shields.io/github/v/release/benzBrake/RunFirefox?style=for-the-badge&label=Stable%20Download&color=2ea44f)](https://github.com/benzBrake/RunFirefox/releases/latest)
[![Beta](https://img.shields.io/badge/Beta-nightly.link-orange?style=for-the-badge&logo=githubactions&logoColor=white)](https://nightly.link/benzBrake/RunFirefox/workflows/build/master)
[![Downloads](https://img.shields.io/github/downloads/benzBrake/RunFirefox/total?style=for-the-badge&label=Downloads)](https://github.com/benzBrake/RunFirefox/releases)

Derived from MyFirefox, this is a portable version launcher for Firefox.

Features:
1. Customizable location for Firefox program files, data folders, and cache folders.
2. Ability to create a portable version of Firefox that can be set as the default browser (just like the installed version, set in the browser settings).
3. Support for running external programs when the browser starts or exits.
4. Support for launching the browser by clicking on the taskbar icon (right-click and select "Pin to taskbar" after opening the browser).

### Latest updates

2026.07.10 Added Cent Browser to the settings screen with official-site Windows x64 portable download and extraction; Cent Browser does not enable the Chrome++ patch

2026.07.10 Naver Whale now appends `--lang=zh-CN` or `--lang=zh-TW` based on the RunFirefox language, working around Whale's Chinese UI issue to improve the experience for Chinese users

2026.07.10 Added Naver Whale to the settings screen with online download and extraction for the Windows x64 standalone installer

2026.07.07 Improved the Chrome++ new-tab disable setting text to clarify that related options become available immediately after the patch is installed

2026.07.07 The Chrome++ settings tab now checks the installed and latest patch versions, and can update an installed patch directly

2026.07.06 Added Bosskey to Utilities settings, allowing a keyboard shortcut to hide/restore the browser with an optional tray icon while hidden

2026.07.06 Adjusted the Advanced settings layout so the cache and Chromium settings areas use the same top spacing as the other tabs

2026.07.06 Added a cache settings group to Advanced settings for configuring the cache folder and related options in one place

2026.07.06 Added Google API management to Chromium settings, allowing build-injected API keys to be imported, the missing-API warning to be hidden, or related environment variables to be cleared

2026.07.06 Browser update checks are now configurable, with startup, hourly, daily, weekly, and never options, plus current version, latest version, bitness, and download controls

2026.07.06 System profile extraction now supports all browser types, and the settings dialog layout, button height, and Utilities tab naming were refined

2026.07.05 App update checks now run asynchronously in the background so startup is not blocked

2026.07.05 Browser type detection now prefers executable metadata, and the README now includes stable, beta, and total download badges

2026.07.04 Updated the portable guide to explain that some browsers can now be downloaded directly from the settings screen, while browsers without built-in download support such as LibreWolf still use the manual steps

2026.07.03 Added Helium to the settings screen with online download and extraction for the Windows x64 ZIP package; Helium is treated as a Chromium-based browser for Chrome++ patch installation and settings

2026.07.03 Added a "Download and install Chrome++" button to the Chrome++ settings tab when the patch is missing, allowing direct installation into the current Chromium-based browser directory

2026.07.03 Chrome++ patch installation failures now keep a diagnostic log and provide a view-log button in the error dialog

2026.07.03 Chrome++ patch release lookup now falls back to the GitCode mirror tags API when GitHub release information cannot be reached

2026.07.02 Added Waterfox to the settings screen with online download and extraction for the Windows x64 installer

2026.07.02 Added Floorp to the settings screen with online download and extraction for the Windows x64 installer

2026.07.02 Added Firefox Developer Edition and Nightly icon build assets

2026.06.22 Fixed leftover Windows startup entries after enabling launch-on-login in Firefox / Mozilla-based browsers; RunFirefox now cleans the related registry entries before and after launch and removes the profile startup preference

2026.06.22 Added the Chrome icon build asset and tightened the release flow: update the version and changelog before tagging, then let the release workflow verify version consistency before building

2026.06.04 Optimized localization config loading by caching `Lang.ini` at startup, reducing repeated disk reads for UI and translation text

2026.06.04 Added a dedicated Chrome++ settings tab for editing `chrome++.ini` `[tabs]` options directly; it is enabled only when the current browser is Chrome and the Chrome++ patch is installed

2026.06.04 When Chrome is missing the Bush2021/chrome_plus patch, RunFirefox now asks whether to install it and shows asynchronous download/install progress; edit `chrome++.ini` yourself if you want full custom control

2026.06.03 Added online Chrome download and extraction from the settings screen

2026.06.01 Added automatic Firefox download and extraction from the settings screen with an always-on-top progress window

2026.06.01 Added Traditional Chinese, automatic UI language detection, and missing localization entries

2026.06.01 Refactored Firefox download and GitHub mirror logic with dynamic version lookup and jsDelivr fallback

2026.06.01 Fixed the Firefox Developer Edition update channel and improved Zotero data path compatibility

2026.05.27 Removed the external mozlz4 executables and replaced them with a built-in pure AutoIt flow that decompresses, rewrites, and recompresses the addonStartup cache

2023.04.15 Added browser auto-update switch

2023.04.12 Added support for multiple languages

2022.12.16 Fixed an issue where the 64-bit version was updated to the 32-bit version

2022.12.08 If there is no shifting, the extension path will no longer be processed, optimizing the cold start speed

2022.11.14 Attempted to fix the issue of missing extension icons after shifting, added automatic construction of FireDoge and Floorp icons

2022.10.18 Attempted to add automatic extension path update functionality (to prevent extensions from becoming invalid after shifting)

### How to download

Click on the "Latest" button on the right. If you have trouble finding it, press Ctrl+F and search for the text "Latest" on this page.

Beta builds: https://nightly.link/benzBrake/RunFirefox/workflows/build/master

### Thanks to

cnjackchen: https://github.com/cnjackchen/

Justin Wong: https://github.com/jusw85
