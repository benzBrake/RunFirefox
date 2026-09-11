# Changelog

## [Unreleased]

- Labels on the Advanced tab (plugins directory, cache directory, cache size) now wrap onto two lines when the current language's text is too wide, the "automatically control cache size" checkbox wraps as well, and the CDP enable hint sizes its height from the measured text width (up to three lines), growing the Chromium settings group and pushing the command-line arguments area down, so alphabetic languages are no longer clipped.
- Reworked the General tab of the settings window into an adaptive layout: controls flow according to the measured width of the current language's texts and wrap automatically, so alphabetic languages (English, Spanish, etc.) no longer suffer overlapping labels or covered version numbers; "Browser" now sits on its own row with a wider combo, the "Download now" button is right-aligned at the end of the architecture row, latest/current versions split the row in half, long checkboxes wrap onto two lines, and the language/run options group gained a "RunFirefox Settings" title; Waterfox now shows the short "unavailable" hint directly in the local version value instead of a separate hint row.
- Added a `LangCustom.ini` custom-language template to the repo (with a complete Spanish `[es-ES]` example); copying it next to the exe overrides built-in texts or adds new languages, and the README now documents custom languages.
- Language data is now embedded in the executable: default translations are compiled from `Lang.ini` (via `scripts/update-langdata.ps1` into `libs/LangData.au3`), so `Lang.ini` is no longer extracted next to the exe; a user-provided `LangCustom.ini` is merged on top of the embedded data key by key.
- Added an overall timeout (10 minutes per URL) to the auto-update download wait so an unreachable source can no longer stall the flow, and the update-package failure dialog now lists the download URLs attempted to help diagnose network issues.
- Added a RunFirefox-managed browser auto update (Chrome official portable, extended to Brave and Naver Whale): the latest version is checked silently according to the update frequency, and after confirmation the update package is downloaded into a local staging directory (atomic .part write verified by extraction) and applied automatically on the next RunFirefox launch while the browser is not running, Firefox style; Chrome++ config and patch files survive the merge overwrite. The "Auto update" checkbox and the "Check browser update" frequency options are now enabled for Chrome, and the configured update channel is persisted for the background check; Brave's local version is normalized before comparing with the remote tag.
- Compacted the Chrome++ tab options and added a "suppress the false out-of-date upgrade prompt" checkbox mapped to chrome++.ini suppress_false_upgrade_notification; it defaults to on for newly created managed configs (fresh Chrome++ installs) while existing configs stay unchanged. The settings window is taller accordingly, the "Extra matched titles" field moved below the new-tab options, the upgrade-prompt option moved to the bottom, and help texts are now fully visible.
- Chromium-based browsers without Chrome++ now get --disable-features=OutdatedBuildDetector appended automatically at launch, deduplicated against automatic and custom command-line arguments, with --disable-features values merged so user-disabled features are preserved.
- Clarified that Chrome++ installation is optional and highlighted features such as right-clicking to close tabs and opening bookmarks in new tabs.
- Added optional offline installation of bundled custom Chrome++ for Brave and Whale, selected by browser x86/x64 architecture. The tab retains its settings, displays the bundled version, and offers replacement based on file contents.
- Split browser version lookup, URL construction, and installer extraction into browser-download and shared download-tool libraries while preserving existing sources, mirror fallback, and UI behavior.

## [2.8.17] - 2026-09-10

- 2026.09.09 Added Xunlei Browser to the settings screen with official-site parsing and Windows x64 installer download.
- 2026.09.08 Added Ungoogled Chromium download support and x64/x86/arm64 architecture selection
- 2026.09.04 Naver Whale now reads the latest version from its official endpoint and compares it with the local version
- 2026.08.30 Taskbar pins for Chromium-based browsers now follow the current browser EXE icon
- 2026.08.29 Added frequent sites, browser launch tasks, and a Launcher settings entry to Jump Lists for Chromium-based browsers
- 2026.08.29 Added a custom CDP debugging port toggle and port setting for Chromium-based browsers, with conflict detection against CDP arguments in custom command-line parameters

## [2.8.16] - 2026-08-29

- 2026.08.29 Added Launcher settings to the end of the Firefox-based browser Jump List for direct access to the RunFirefox settings window
- 2026.08.28 RunFirefox now disables its Bosskey when Turbo Browser or Cent Browser is detected, avoiding conflicts with the browsers' built-in Bosskey
- 2026.08.28 Added Brave Windows x64 portable download and extraction with GitHub mirror fallback, plus a matching Brave launcher icon
- 2026.08.27 After a version check failure, browsers with a verified fallback can still be downloaded while the others can open their official download page; added fallbacks for Waterfox, Turbo, Helium, Vivaldi, and Chrome Stable/Beta/Dev
- 2026.08.27 Added Turbo Browser to the settings screen with online download and extraction of the official Windows x64 portable package and a matching launcher icon; Turbo does not enable the Chrome++ patch
- 2026.08.26 RunFirefox now takes over regular-window shortcuts created by Firefox-based browsers in the current user's Start menu, preserving the portable configuration when they are launched
- 2026.08.26 Added online download support for the LibreWolf Windows x64 portable ZIP and automatic handling of its nested directory layout

## [2.8.15] - 2026-08-25

- 2026.08.25 Hardened JSON encoding depth limits and Chrome++ patch handling, prompting for patch installation only after browser download and fixing related policy container handling
- 2026.08.25 Added browser EXE/DLL icon extraction and ICO compression tools, and optimized the bundled browser icon resources
- 2026.08.20 After installing the Chrome++ patch, RunFirefox now writes the profile and cache locations to `chrome++.ini` using portable paths relative to `chrome.exe`, avoiding command-line directory switches that bypass Chrome++ portable handling

## [2.8.14] - 2026-08-19

- 2026.08.19 Improved Firefox 154 taskbar icon compatibility by preserving and synchronizing Firefox shortcut IconLocation and AUMID during takeover, with safer handling of invalid shortcuts

## [2.8.13] - 2026-08-15

- 2026.08.15 Fixed the Firefox Jump List ownership policy not being persisted, preventing Firefox from replacing the portable taskbar menu with native tasks after profile cleanup
- 2026.08.14 RunFirefox now owns the Firefox taskbar Jump List, so new tabs, windows, private windows, and frequent sites all open through the launcher with the configured portable profile
- 2026.07.15 Added Chrome++ 1.18.0 hover-to-activate tab and activation-delay settings

## [2.8.12] - 2026-07-10

- 2026.07.10 Nightly builds now provide separate RunFirefox and RunChrome downloads
- 2026.07.10 Added Vivaldi to the settings screen with official-site Windows x64 Stable download and extraction; Vivaldi does not enable the Chrome++ patch
- 2026.07.10 Added Cent Browser to the settings screen with official-site Windows x64 portable download and extraction; Cent Browser does not enable the Chrome++ patch
- 2026.07.10 Naver Whale now appends `--lang=zh-CN` or `--lang=zh-TW` based on the RunFirefox language, working around Whale's Chinese UI issue to improve the experience for Chinese users
- 2026.07.10 Added Naver Whale to the settings screen with online download and extraction for the Windows x64 standalone installer

## [2.8.11] - 2026-07-07

- 2026.07.07 Improved the Chrome++ new-tab disable setting text to clarify that related options become available immediately after the patch is installed
- 2026.07.07 The Chrome++ settings tab now checks the installed and latest patch versions, and can update an installed patch directly

## [2.8.10] - 2026-07-06

- 2026.07.06 Added Bosskey to Utilities settings, allowing a keyboard shortcut to hide/restore the browser with an optional tray icon while hidden
- 2026.07.06 Adjusted the Advanced settings layout so the cache and Chromium settings areas use the same top spacing as the other tabs
- 2026.07.06 Added a cache settings group to Advanced settings for configuring the cache folder and related options in one place
- 2026.07.06 Added Google API management to Chromium settings, allowing build-injected API keys to be imported, the missing-API warning to be hidden, or related environment variables to be cleared
- 2026.07.06 Browser update checks are now configurable, with startup, hourly, daily, weekly, and never options, plus current version, latest version, bitness, and download controls
- 2026.07.06 System profile extraction now supports all browser types, and the settings dialog layout, button height, and Utilities tab naming were refined
- 2026.07.05 App update checks now run asynchronously in the background so startup is not blocked
- 2026.07.05 Browser type detection now prefers executable metadata, and the README now includes stable, beta, and total download badges

## [2.8.9] - 2026-07-04

- 2026.07.04 Updated the portable guide to explain that some browsers can now be downloaded directly from the settings screen, while browsers without built-in download support such as LibreWolf still use the manual steps
- 2026.07.03 Added Helium to the settings screen with online download and extraction for the Windows x64 ZIP package; Helium is treated as a Chromium-based browser for Chrome++ patch installation and settings
- 2026.07.03 Added a "Download and install Chrome++" button to the Chrome++ settings tab when the patch is missing, allowing direct installation into the current Chromium-based browser directory
- 2026.07.03 Chrome++ patch installation failures now keep a diagnostic log and provide a view-log button in the error dialog
- 2026.07.03 Chrome++ patch release lookup now falls back to the GitCode mirror tags API when GitHub release information cannot be reached
- 2026.07.02 Added Waterfox to the settings screen with online download and extraction for the Windows x64 installer

## [2.8.8] - 2026-07-02

- 2026.07.02 Added Floorp to the settings screen with online download and extraction for the Windows x64 installer
- 2026.07.02 Added Firefox Developer Edition and Nightly icon build assets
- 2026.06.22 Fixed leftover Windows startup entries after enabling launch-on-login in Firefox / Mozilla-based browsers; RunFirefox now cleans the related registry entries before and after launch and removes the profile startup preference

## [2.8.7] - 2026-06-22

- 2026.06.22 Added the Chrome icon build asset and tightened the release flow: update the version and changelog before tagging, then let the release workflow verify version consistency before building

## [2.8.6] - 2026-06-04

- 2026.06.04 Optimized localization config loading by caching `Lang.ini` at startup, reducing repeated disk reads for UI and translation text
- 2026.06.04 Added a dedicated Chrome++ settings tab for editing `chrome++.ini` `[tabs]` options directly; it is enabled only when the current browser is Chrome and the Chrome++ patch is installed
- 2026.06.04 When Chrome is missing the Bush2021/chrome_plus patch, RunFirefox now asks whether to install it and shows asynchronous download/install progress; edit `chrome++.ini` yourself if you want full custom control
- 2026.06.03 Added online Chrome download and extraction from the settings screen
- 2026.06.01 Added automatic Firefox download and extraction from the settings screen with an always-on-top progress window

## [2.8.5] - 2026-06-01

- 2026.06.01 Added Traditional Chinese, automatic UI language detection, and missing localization entries
- 2026.06.01 Refactored Firefox download and GitHub mirror logic with dynamic version lookup and jsDelivr fallback
- 2026.06.01 Fixed the Firefox Developer Edition update channel and improved Zotero data path compatibility
- 2026.05.27 Removed the external mozlz4 executables and replaced them with a built-in pure AutoIt flow that decompresses, rewrites, and recompresses the addonStartup cache
- 2025.03.30 Added automatic builds for newly added launcher icons
- 2024.03.24 Fixed cache settings not taking effect

## [2.8.0] - 2023-10-24

- 2023.10.24 Removed the legacy update URL, fixed long-standing update issues, and added a GitHub Mirror setting

## [2.7.9] - 2023-10-05

- 2023.04.15 Added browser auto-update switch
- 2023.04.12 Added support for multiple languages

## [2.7.4] - 2022-12-16

- 2022.12.16 Fixed an issue where the 64-bit version was updated to the 32-bit version
- 2022.12.08 If there is no shifting, the extension path will no longer be processed, optimizing the cold start speed

## [2.7.1] - 2022-11-14

- 2022.11.14 Attempted to fix the issue of missing extension icons after shifting, added automatic construction of FireDoge and Floorp icons

## [2.6.8] - 2022-10-18

- 2022.10.18 Attempted to add automatic extension path update functionality (to prevent extensions from becoming invalid after shifting)
