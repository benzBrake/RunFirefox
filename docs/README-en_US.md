# RunFirefox

Derived from MyFirefox, this is a portable version launcher for Firefox.

Features:
1. Customizable location for Firefox program files, data folders, and cache folders.
2. Ability to create a portable version of Firefox that can be set as the default browser (just like the installed version, set in the browser settings).
3. Support for running external programs when the browser starts or exits.
4. Support for launching the browser by clicking on the taskbar icon (right-click and select "Pin to taskbar" after opening the browser).

### Latest updates

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

### Thanks to

cnjackchen: https://github.com/cnjackchen/

Justin Wong: https://github.com/jusw85
