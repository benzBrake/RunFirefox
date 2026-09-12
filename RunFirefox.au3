#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icons\Firefox.ico
#AutoIt3Wrapper_Outfile=RunFirefox.exe
#AutoIt3Wrapper_Outfile_x64=RunFirefox_x64.exe
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Comment=Portable Browser Launcher
#AutoIt3Wrapper_Res_Description=Portable Browser Launcher
#AutoIt3Wrapper_Res_Fileversion=2.8.18.0
#AutoIt3Wrapper_Res_LegalCopyright=Ryan <github-benzBrake@woai.ru>
#AutoIt3Wrapper_Res_Language=2052
#AutoIt3Wrapper_Res_requestedExecutionLevel=None
#AutoIt3Wrapper_AU3Check_Parameters=-q
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/sf=1 /sv=1
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------
	AutoIt Version:   3.3.14.2
	Author:           Ryan, 甲壳虫
	Link              https://github.com/benzBrake/RunFirefox
	OldLink:          http://code.taobao.org/p/RunFirefox/wiki/index/
	Script Function:
	自定义浏览器程序和配置文件夹的路径，用来制作便携版浏览器，便携版可设为默认浏览器。
#ce

#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <GuiStatusBar.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ComboConstants.au3>
#include <UpDownConstants.au3>
#include <Date.au3>
#include <TrayConstants.au3>
#include <WinAPIReg.au3>
#include <Security.au3>
#include <WinAPIMisc.au3>
#include <WinAPISys.au3>
#include <WinAPISysWin.au3>
#include <FileConstants.au3>
#include <Array.au3>
#include <Misc.au3>
#include <Crypt.au3>
#include "libs\_String.au3"
#include "libs\AppUserModelId.au3"
#include "libs\JumpList.au3"
#include "libs\FirefoxPlaces.au3"
#include "libs\ChromiumHistory.au3"
#include "libs\Policies.au3"
#include "libs\ScriptingDictionary.au3"
#include "libs\JSON.au3"
#include "libs\UpgradeHelper.au3"
#include "libs\PathUtils.au3"
#include "libs\TextIni.au3"
#include "libs\AdaptiveLayout.au3"
#include "libs\LangData.au3"
#include "libs\MozLz4.au3"

Opt("GUIOnEventMode", 1)
Opt("WinTitleMatchMode", 4)

Global Const $AppName = "RunFirefox"
Global Const $AppVersion = "2.8.18"
Global Const $ChromePlusRepo = "Bush2021/chrome_plus"
Global Const $ChromePlusReleasesApiUrl = "https://api.github.com/repos/" & $ChromePlusRepo & "/releases?per_page=30"
Global Const $ChromePlusJsDelivrVersionsUrl = "https://data.jsdelivr.com/v1/package/gh/" & $ChromePlusRepo
Global Const $ChromePlusGitCodeTagsUrl = "https://gitcode.com/gh_mirrors/ch/chrome_plus/tags"
Global Const $ChromePlusGitCodeTagsApiUrl = "https://web-api.gitcode.com/api/v2/projects/gh_mirrors%2Fch%2Fchrome_plus/repository/tags?order_by=committed&sort=desc&repoId=gh_mirrors%252Fch%252Fchrome_plus&page=1&per_page=10"
Global Const $ChromePlusApiUserAgent = "RunFirefox/" & $AppVersion
Global Const $ChromePlusCacheRoot = @TempDir & "\RunFirefox_ChromePlus"
Global Const $ChromiumGoogleApiKeyEnv = "GOOGLE_API_KEY"
Global Const $ChromiumGoogleClientIdEnv = "GOOGLE_DEFAULT_CLIENT_ID"
Global Const $ChromiumGoogleClientSecretEnv = "GOOGLE_DEFAULT_CLIENT_SECRET"
; These values are populated by the release workflow as per-build obfuscated data.
; Client-side obfuscation only raises extraction cost; it cannot make shipped credentials secret.
Global Const $ChromiumGoogleApiKeyPayload = ""
Global Const $ChromiumGoogleApiKeyMask = ""
Global Const $ChromiumGoogleApiKeyNonce = 0
Global Const $ChromiumGoogleClientIdPayload = ""
Global Const $ChromiumGoogleClientIdMask = ""
Global Const $ChromiumGoogleClientIdNonce = 0
Global Const $ChromiumGoogleClientSecretPayload = ""
Global Const $ChromiumGoogleClientSecretMask = ""
Global Const $ChromiumGoogleClientSecretNonce = 0
Global Const $BrowserFirefox = "firefox"
Global Const $BrowserZen = "zen"
Global Const $BrowserFloorp = "floorp"
Global Const $BrowserWaterfox = "waterfox"
Global Const $BrowserLibreWolf = "librewolf"
Global Const $BrowserChrome = "chrome"
Global Const $BrowserTurbo = "turbo"
Global Const $BrowserHelium = "helium"
Global Const $BrowserWhale = "whale"
Global Const $BrowserCent = "cent"
Global Const $BrowserVivaldi = "vivaldi"
Global Const $BrowserOpera = "opera"
Global Const $BrowserBrave = "brave"
Global Const $BrowserXunlei = "xunlei"
Global Const $BrowserUngoogledChromium = "ungoogled-chromium"
Global $FirstRun = 0, $FirstLaunch = 0, $BrowserExecutableName, $BrowserDirectory, $isZotero = false
Global $TaskBarDir = @AppDataDir & "\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
Global $AppPID, $TaskBarLastChange, $BrowserIconLastChange = 0, $BrowserIconState = ""
Global $JumpListLastRefresh = 0, $JumpListContentSignature = ""
Global $AllowBrowserUpdate, $AppUpdateCheckEnabled, $AppUpdateLastCheck, $BackgroundModeEnabled, $BrowserType, $BrowserPath, $ProfileDir
Global $BrowserUpdateCheckMode, $BrowserUpdateLastCheck, $BrowserUpdateChannel
Global $CustomPluginsDir, $CustomCacheDir, $CacheSize, $CacheSizeSmart, $DefaultBrowserCheckEnabled, $Params
Global $ChromiumDebugPortEnabled, $ChromiumDebugPort
Global $BrowserStartApps, $CloseStartAppsAfterBrowserExit, $BrowserExitApps
Global $BossKeyEnabled, $BossKey, $BossKeyHideToTray, $BossKeyBrowserHidden = 0, $BossKeyTrayVisible = 0
Global $GithubDirectMirror, $GithubJsDelivrMirror
Global $DownloadThreads, $ProxyType, $ProxyServer, $ProxyPort

Global $DefaultProfDir, $hSettings, $idBrowserPath, $idProfileDir, $idLanguage
Global $idCopyProfile, $idCustomPluginsDir, $idGetPluginsDir
Global $idCustomCacheDir, $idGetCacheDir, $idCacheSize, $idCacheSizeSmart
Global $idParams, $hStatus, $SettingsConfirmed
Global $idAllowBrowserUpdate, $idAppUpdateCheckEnabled, $idBackgroundModeEnabled, $idBrowserType, $idChannel, $idBrowserDownloadLink, $BrowserDownloadUrl
Global $idBrowserBitness, $idBrowserUpdateCheckMode, $idCurrentBrowserVersion, $idBrowserDownloadNow
Global $idChromePlusHint, $idChromePlusDownloadPatch, $idChromePlusConfigPath, $idChromePlusCurrentVersion, $idChromePlusLatestVersion, $idChromePlusDoubleClickClose, $idChromePlusRightClickClose, $idChromePlusKeepLastTab
Global $idChromePlusWheelTab, $idChromePlusWheelTabWhenPressRButton, $idChromePlusOpenUrlNewTab, $idChromePlusOpenBookmarkNewTab
Global $idChromePlusHoverTab, $idChromePlusHoverTabDelay, $idChromePlusHoverTabDelayLabel
Global $idChromePlusNewTabDisable, $idChromePlusNewTabDisableName, $idChromePlusNewTabDisableNameLabel
Global $idChromePlusSuppressFalseUpgradeNotification
Global $idChromiumGoogleApiImport, $idChromiumGoogleApiSuppress, $idChromiumGoogleApiClear
Global $idChromiumDebugPortEnabled, $idChromiumDebugPort, $idChromiumDebugPortLabel
Global $idDownloadThreads, $idDownloadThreadsUpDown, $idProxyType, $idProxyServer, $idProxyPort, $idNetworkCurlHint
Global $LANG_DATA, $LANGUAGE, $LANGUAGES
Global $ChromePlusReleaseInfoLoaded = False, $ChromePlusReleaseTag = "", $ChromePlusArchiveUrl = ""
Global $BrowserVersionLoadAnim = 0
Global $ChromePlusVersionLoadHandle = 0, $ChromePlusVersionLoadFile = "", $ChromePlusVersionLoadAnim = 0
Global $AppUpdateCheckHandle = 0, $AppUpdateCheckFile = ""
Global $idBrowserStartApps, $idCloseStartAppsAfterBrowserExit, $idBrowserExitApps
Global $idBossKeyEnabled, $idBossKey, $idBossKeyHideToTray, $BossKeyCaptureValue = "", $BossKeyHotkeyProc = 0, $BossKeyInputWndProc = 0, $BossKeyKeys = 0
Global $aBrowserStartApps, $aBrowserExitApps, $aBrowserStartAppPids[2]
#include "libs\DownloadTools.au3"
#include "libs\BrowserDownload.au3"
#include "libs\BrowserAutoUpdate.au3"
#include "libs\ChromePlusBundled.au3"

Func GetBrowserLocale($DefaultLocale = "")
	Local $Locale = StringReplace($LANGUAGE, "_", "-")
	If $Locale = "" Then Return $DefaultLocale
	If Not StringRegExp($Locale, "^[A-Za-z]{2,3}(-[A-Za-z0-9]+)*$") Then Return $DefaultLocale
	Return $Locale
EndFunc

Global $hEvent, $ClientKey, $FileAsso, $URLAsso, $ChromeProgID
Global $fReg[7][3] = [[$HKEY_CURRENT_USER, 'Software\Clients\StartMenuInternet'], _
		[$HKEY_LOCAL_MACHINE, 'Software\Clients\StartMenuInternet'], _
		[$HKEY_CLASSES_ROOT, 'ftp'], _
		[$HKEY_CLASSES_ROOT, 'http'], _
		[$HKEY_CLASSES_ROOT, 'https'], _
		[$HKEY_CLASSES_ROOT, ''], _ ; FirefoxHTML
		[$HKEY_CLASSES_ROOT, '']] ; FirefoxURL
Global $aChromeFileAsso[6] = [".htm", ".html", ".shtml", ".webp", ".xht", ".xhtml"]
Global $aChromeUrlAsso[13] = ["ftp", "http", "https", "irc", "mailto", "mms", "news", "nntp", "sms", "smsto", "tel", "urn", "webcal"]

; Global Const $KEY_WOW64_32KEY = 0x0200 ; Access a 32-bit key from either a 32-bit or 64-bit application
; Global Const $KEY_WOW64_64KEY = 0x0100 ; Access a 64-bit key from either a 32-bit or 64-bit application

If Not @AutoItX64 Then ; 32-bit Autoit
	$HKLM_Software_32 = "HKLM\SOFTWARE"
	$HKLM_Software_64 = "HKLM64\SOFTWARE"
Else ; 64-bit Autoit
	$HKLM_Software_32 = "HKLM\SOFTWARE\Wow6432Node"
	$HKLM_Software_64 = "HKLM64\SOFTWARE"
EndIf

FileChangeDir(@ScriptDir)
$ScriptNameWithoutSuffix = StringRegExpReplace(@ScriptName, "\.[^.]*$", "")
$inifile = @ScriptDir & "\" & $ScriptNameWithoutSuffix & ".ini"
If Not FileExists($inifile) Then
	$FirstRun = 1
	$FirstLaunch = 1
	IniWrite($inifile, "Settings", "AppVersion", $AppVersion)
	IniWrite($inifile, "Settings", "CheckAppUpdate", 1)
	IniWrite($inifile, "Settings", "AppUpdateLastCheck", "2015/01/01 00:00:00")
	IniWrite($inifile, "Settings", "RunInBackground", 1)
	IniWrite($inifile, "Settings", "AllowBrowserUpdate", 1)
	IniWrite($inifile, "Settings", "BrowserUpdateCheckMode", "startup")
	IniWrite($inifile, "Settings", "BrowserUpdateLastCheck", "2015/01/01 00:00:00")
	IniWrite($inifile, "Settings", "BrowserType", $BrowserFirefox)
	IniWrite($inifile, "Settings", "BrowserPath", ".\Firefox\firefox.exe")
	IniWrite($inifile, "Settings", "ProfileDir", ".\profiles")
	IniWrite($inifile, "Settings", "CustomPluginsDir", "")
	IniWrite($inifile, "Settings", "CustomCacheDir", "")
	IniWrite($inifile, "Settings", "CacheSize", "")
	IniWrite($inifile, "Settings", "CacheSizeSmart", 1)
	IniWrite($inifile, "Settings", "CheckDefaultBrowser", 1)
	IniWrite($inifile, "Settings", "Params", "")
	IniWrite($inifile, "Settings", "ChromiumDebugPortEnabled", 0)
	IniWrite($inifile, "Settings", "ChromiumDebugPort", 9222)
	IniWrite($inifile, "Settings", "ExApp", "")
	IniWrite($inifile, "Settings", "ExAppAutoExit", 1)
	IniWrite($inifile, "Settings", "ExApp2", "")
	IniWrite($inifile, "Settings", "BossKeyEnabled", 0)
	IniWrite($inifile, "Settings", "BossKey", "^`")
	IniWrite($inifile, "Settings", "BossKeyHideToTray", 0)
	IniWrite($inifile, "Settings", "LastPlatformDir", "")
	IniWrite($inifile, "Settings", "LastProfileDir", "")
	IniWrite($inifile, "Settings", "DownloadThreads", 3)
	IniWrite($inifile, "Settings", "ProxyType", "direct")
	IniWrite($inifile, "Settings", "ProxyServer", "")
	IniWrite($inifile, "Settings", "ProxyPort", "")
EndIf

$AppUpdateCheckEnabled = IniRead($inifile, "Settings", "CheckAppUpdate", 1) * 1
$AppUpdateLastCheck = IniRead($inifile, "Settings", "AppUpdateLastCheck", "")
If Not $AppUpdateLastCheck Then
	$AppUpdateLastCheck = "2015/01/01 00:00:00"
EndIf
$AllowBrowserUpdate = IniRead($inifile, "Settings", "AllowBrowserUpdate", 1) * 1
$BrowserUpdateCheckMode = NormalizeBrowserUpdateCheckMode(IniRead($inifile, "Settings", "BrowserUpdateCheckMode", "startup"))
$BrowserUpdateLastCheck = IniRead($inifile, "Settings", "BrowserUpdateLastCheck", "")
If Not $BrowserUpdateLastCheck Then
	$BrowserUpdateLastCheck = "2015/01/01 00:00:00"
EndIf
$BrowserUpdateChannel = _BrowserDownloadNormalizeChromeChannel(IniRead($inifile, "Settings", "BrowserUpdateChannel", "stable"))
$BackgroundModeEnabled = IniRead($inifile, "Settings", "RunInBackground", 1) * 1
$BrowserType = NormalizeBrowserType(IniRead($inifile, "Settings", "BrowserType", $BrowserFirefox))
Local $BrowserPathValue = IniRead($inifile, "Settings", "BrowserPath", "__MISSING__")
If $BrowserPathValue = "__MISSING__" Then
	; Keep reading the legacy key so existing configurations migrate transparently.
	$BrowserPathValue = IniRead($inifile, "Settings", "FirefoxPath", ".\Firefox\firefox.exe")
	IniWrite($inifile, "Settings", "BrowserPath", $BrowserPathValue)
EndIf
$BrowserPath = $BrowserPathValue
$ProfileDir = IniRead($inifile, "Settings", "ProfileDir", ".\profiles")
$CustomPluginsDir = IniRead($inifile, "Settings", "CustomPluginsDir", "")
$CustomCacheDir = IniRead($inifile, "Settings", "CustomCacheDir", "")
$CacheSize = IniRead($inifile, "Settings", "CacheSize", "")
$CacheSizeSmart = IniRead($inifile, "Settings", "CacheSizeSmart", 1) * 1
$DefaultBrowserCheckEnabled = IniRead($inifile, "Settings", "CheckDefaultBrowser", 1) * 1
$Params = IniRead($inifile, "Settings", "Params", "")
$ChromiumDebugPortEnabled = IniRead($inifile, "Settings", "ChromiumDebugPortEnabled", 0) * 1
$ChromiumDebugPort = IniRead($inifile, "Settings", "ChromiumDebugPort", 9222) * 1
If $ChromiumDebugPort < 1 Or $ChromiumDebugPort > 65535 Then $ChromiumDebugPort = 9222
$BrowserStartApps = IniRead($inifile, "Settings", "ExApp", "")
$CloseStartAppsAfterBrowserExit = IniRead($inifile, "Settings", "ExAppAutoExit", 1) * 1
$BrowserExitApps = IniRead($inifile, "Settings", "ExApp2", "")
$BossKeyEnabled = IniRead($inifile, "Settings", "BossKeyEnabled", 0) * 1
$BossKey = IniRead($inifile, "Settings", "BossKey", "^`")
$BossKeyHideToTray = IniRead($inifile, "Settings", "BossKeyHideToTray", 0) * 1
$DownloadThreads = Int(IniRead($inifile, "Settings", "DownloadThreads", 3))
If $DownloadThreads < 1 Or $DownloadThreads > 10 Then $DownloadThreads = 3
$ProxyType = StringLower(IniRead($inifile, "Settings", "ProxyType", "direct"))
If $ProxyType <> "http" And $ProxyType <> "socks5" Then $ProxyType = "direct"
$ProxyServer = IniRead($inifile, "Settings", "ProxyServer", "")
$ProxyPort = Int(IniRead($inifile, "Settings", "ProxyPort", 0))
$LastPlatformDir = IniRead($inifile, "Settings", "LastPlatformDir", "")
$LastProfileDir = IniRead($inifile, "Settings", "LastProfileDir", "")
$LANGUAGE = IniRead($inifile, "Settings", "Language", "")
$LANG_DATA = LoadLangData()
$LANGUAGES = GetLanguages()
If Not $LANGUAGE Then
	$LANGUAGE = GetAutoLanguage()
	IniWrite($inifile, "Settings", "Language", $LANGUAGE)
Else
	$LANGUAGE = GetSupportedLanguage($LANGUAGE, "zh-CN")
EndIf
Local $LegacyGithubMirror = IniRead($inifile, "Settings", "GithubMirror", "")
$GithubDirectMirror = IniRead($inifile, "Settings", "GithubDirectMirror", "")
$GithubJsDelivrMirror = IniRead($inifile, "Settings", "GithubJsDelivrMirror", "")
If $LegacyGithubMirror <> "" Then
	If _UpgradeIsJsDelivrGithubMirror($LegacyGithubMirror) Then
		If $GithubJsDelivrMirror = "" Then $GithubJsDelivrMirror = $LegacyGithubMirror
	Else
		If $GithubDirectMirror = "" Then $GithubDirectMirror = $LegacyGithubMirror
	EndIf
	IniDelete($inifile, "Settings", "GithubMirror")
EndIf
If StringInStr($GithubDirectMirror, "mirror.serv00.net/gh") Then $GithubDirectMirror = ""
If StringInStr($GithubJsDelivrMirror, "mirror.serv00.net/gh") Then $GithubJsDelivrMirror = ""
If $GithubDirectMirror = "" Then $GithubDirectMirror = _UpgradeGetDefaultGithubDirectMirror()
If $GithubJsDelivrMirror = "" Then $GithubJsDelivrMirror = _UpgradeGetDefaultGithubJsDelivrMirror($LANGUAGE)
IniWrite($inifile, "Settings", "GithubDirectMirror", $GithubDirectMirror)
IniWrite($inifile, "Settings", "GithubJsDelivrMirror", $GithubJsDelivrMirror)

_DownloadToolsConfigure($DownloadThreads, $ProxyType, $ProxyServer, $ProxyPort)
_BrowserDownloadConfigure($AppVersion, GetBrowserLocale("zh-CN"), GetEffectiveGithubDirectMirror(), GetEffectiveGithubJsDelivrMirror())
_BrowserAutoUpdateConfigure(@ScriptDir & "\BrowserUpdateCache")

If $CmdLine[0] >= 4 And $CmdLine[1] = "--load-chrome-version" Then
	_BrowserDownloadWriteChromeUpdateInfoFile($CmdLine[2], $CmdLine[3], $CmdLine[4])
	Exit
EndIf

If $CmdLine[0] >= 2 And $CmdLine[1] = "--load-chrome-plus-version" Then
	WriteChromePlusReleaseInfoFile($CmdLine[2])
	Exit
EndIf

If $CmdLine[0] >= 2 And $CmdLine[1] = "--check-app-update" Then
	WriteAppUpdateCheckResultFile($CmdLine[2])
	Exit
EndIf

; 检查是否是首次启动（刚下载，刚更新）
If $AppVersion <> IniRead($inifile, "Settings", "AppVersion", "") Then
	$FirstRun = 1
	IniWrite($inifile, "Settings", "AppVersion", $AppVersion)
EndIf

Opt("ExpandEnvStrings", 1)
EnvSet("APP", @ScriptDir)

;~ 第一个启动参数为“-set”，或第一次运行，Firefox、配置文件夹、插件目录不存在，则显示设置窗口
If ($cmdline[0] = 1 And $cmdline[1] = "-set") Or $FirstRun Or Not FileExists($BrowserPath) Or Not FileExists($ProfileDir) Then
	CreateSettingsShortcut(@ScriptDir & "\" & $ScriptNameWithoutSuffix & ".vbs")
	Settings()
EndIf

;~ 转换成绝对路径
$BrowserPath = FullPath($BrowserPath)
SplitPath($BrowserPath, $BrowserDirectory, $BrowserExecutableName)
$ProfileDir = FullPath($ProfileDir)

If IsMozillaBrowser($BrowserType) And $BrowserExecutableName = "zotero.exe" Then
	$isZotero = True
EndIf

If IsMozillaBrowser($BrowserType) Then
	;~ 创建禁止检查默认浏览器策略，使用 RunFirefox 后检测默认浏览器结果不准确
	UpdatePolicies($BrowserDirectory, "DontCheckDefaultBrowser", true)

	;~ 创建禁用自动更新策略
	UpdatePolicies($BrowserDirectory, "DisableAppUpdate", $AllowBrowserUpdate == 0)

	;~ RunFirefox owns the Jump List so every task can preserve the portable profile.
	UpdateFirefoxPreferencePolicy($BrowserDirectory, "browser.taskbar.lists.enabled", False)
EndIf

If IsAdmin() And $cmdline[0] = 1 And $cmdline[1] = "-SetDefaultGlobal" Then
	EnsureDefaultBrowser($BrowserPath)
	Exit
EndIf

;~ 插件目录
If IsMozillaBrowser($BrowserType) And $CustomPluginsDir <> "" Then
	$CustomPluginsDir = FullPath($CustomPluginsDir)
	EnvSet("MOZ_PLUGIN_PATH", $CustomPluginsDir) ; 设置环境变量
EndIf

;~ Convert Jump List commands to browser arguments before forwarding them.
Local $CommandLineStart = 1
If $cmdline[0] >= 2 And $cmdline[1] = "--jump-action" Then
	Switch $cmdline[2]
		Case "new-tab"
			If IsChromeBrowser($BrowserType) Then
				$Params &= " about:blank"
			Else
				$Params &= " -new-tab about:blank"
			EndIf
		Case "new-window"
			If IsChromeBrowser($BrowserType) Then
				$Params &= " --new-window about:blank"
			Else
				$Params &= " -new-window about:blank"
			EndIf
		Case "private-window"
			If IsChromeBrowser($BrowserType) Then
				$Params &= " --incognito"
			Else
				$Params &= " -private-window"
			EndIf
	EndSwitch
	$CommandLineStart = 3
ElseIf $cmdline[0] >= 2 And $cmdline[1] = "--jump-url" Then
	$Params &= " " & QuoteCommandLineArgument($cmdline[2])
	$CommandLineStart = 3
EndIf

;~ 给带空格的外部参数加上引号。
For $i = $CommandLineStart To $cmdline[0]
	$Params &= " " & QuoteCommandLineArgument($cmdline[$i])
Next

Local $BrowserIsRunning = FindRunningAppPid($BrowserPath)
If IsMozillaBrowser($BrowserType) Then
	DeleteMozillaLaunchOnLoginEntry($BrowserPath)
	SyncMozillaStartMenuShortcuts()
	FileDelete($BrowserDirectory & "\defaults\pref\runfirefox.js")
	$BrowserIsRunning = ProfileInUse($ProfileDir)
	If Not $BrowserIsRunning Then
		Local $config = CheckPrefs()
		If $config Then
			FileWrite($BrowserDirectory & "\defaults\pref\runfirefox.js", $config)
		EndIf
	EndIf
EndIf

;~ Fix Addons not Found
If IsMozillaBrowser($BrowserType) And ($LastPlatformDir <> $BrowserDirectory Or $LastProfileDir <> $ProfileDir) Then
	UpdateAddonStartup()
	UpdateExtensionsJson()
EndIf

;~ Apply staged browser update before the browser process starts
If _BrowserAutoUpdateIsSupported($BrowserType) And Not $BrowserIsRunning Then BrowserAutoUpdateApplyPendingInteractive()

;~ Start browser
$BaseParams = BuildBrowserLaunchParams($BrowserType)
$LaunchParams = $BaseParams & $Params
If NeedsOutdatedBuildDetectorParam() Then $LaunchParams = AppendOutdatedBuildDetectorParam($LaunchParams)
$AppPID = RunBrowserProcess($LaunchParams)
If IsMozillaBrowser($BrowserType) Then WaitAndDeleteMozillaLaunchOnLoginEntry($BrowserPath)

FileChangeDir(@ScriptDir)
CreateSettingsShortcut(@ScriptDir & "\" & $ScriptNameWithoutSuffix & ".vbs")

If $BrowserIsRunning Then
	$exe = StringRegExpReplace(@AutoItExe, ".*\\", "")
	$list = ProcessList($exe)
	For $i = 1 To $list[0][0]
		If $list[$i][1] <> @AutoItPID And GetProcessPath($list[$i][1]) = @AutoItExe Then
			Exit ;exit if another instance of myfirefox is running
		EndIf
	Next
EndIf

; Start external apps
If $BrowserStartApps <> "" Then
	$aBrowserStartApps = StringSplit($BrowserStartApps, "||", 1)
	ReDim $aBrowserStartAppPids[$aBrowserStartApps[0] + 1]
	$aBrowserStartAppPids[0] = $aBrowserStartApps[0]
	For $i = 1 To $aBrowserStartApps[0]
		$match = StringRegExp($aBrowserStartApps[$i], '^"(.*?)" *(.*)', 1)
		If @error Then
			$file = $aBrowserStartApps[$i]
			$args = ""
		Else
			$file = $match[0]
			$args = $match[1]
		EndIf
		$file = FullPath($file)
		$aBrowserStartAppPids[$i] = ProcessExists(StringRegExpReplace($file, '.*\\', ''))
		If Not $aBrowserStartAppPids[$i] And FileExists($file) Then
			$aBrowserStartAppPids[$i] = ShellExecute($file, $args, StringRegExpReplace($file, '\\[^\\]+$', ''))
		EndIf
	Next
EndIf

If $DefaultBrowserCheckEnabled Then
	EnsureDefaultBrowser($BrowserPath)
EndIf

Local $BrowserWindowClass = GetBrowserWindowClass($BrowserType)
WinWait("[REGEXPCLASS:(?i)" & $BrowserWindowClass & "]", "", GetBrowserWindowWait($BrowserType))
$hBrowserWindow = FindVisibleWindowByPid($AppPID, $BrowserWindowClass)

Global $AppUserModelId
If FileExists($TaskBarDir) Then ; win 7+
	$AppUserModelId = _WindowAppId($hBrowserWindow)
	CheckPinnedPrograms($BrowserPath)
	RefreshBrowserJumpList(True)
EndIf

;~ Check myfirefox update
If $AppUpdateCheckEnabled And _DateDiff("h", $AppUpdateLastCheck, _NowCalc()) >= 48 Then
	CheckForAppUpdate()
EndIf

;~ Check portable browser update (RunFirefox-managed, Firefox style)
If $BackgroundModeEnabled And $AllowBrowserUpdate And _BrowserAutoUpdateIsSupported($BrowserType) Then BrowserAutoUpdateCheck()

If Not $BackgroundModeEnabled Then
	Exit
EndIf
; ========================= app ended if not run in background ================================

If $DefaultBrowserCheckEnabled Then ; register REG for notification
	$hEvent = _WinAPI_CreateEvent()
	For $i = 0 To UBound($fReg) - 1
		If $fReg[$i][1] Then
			$fReg[$i][2] = _WinAPI_RegOpenKey($fReg[$i][0], $fReg[$i][1], $KEY_NOTIFY)
			If $fReg[$i][2] Then
				_WinAPI_RegNotifyChangeKeyValue($fReg[$i][2], $REG_NOTIFY_CHANGE_LAST_SET, 1, 1, $hEvent)
			EndIf
		EndIf
	Next
EndIf
OnAutoItExitRegister("OnExit")
RegisterBossKeyHotKey()

ReduceMemory()
AdlibRegister("ReduceMemory", 300000)

; wait for browser exit
$BrowserIsRunning = 0
While 1
	Sleep(500)

	If $hBrowserWindow Then
		$BrowserIsRunning = WinExists($hBrowserWindow)
	Else ; ProcessExists() is resource consuming than WinExists()
		$BrowserIsRunning = ProcessExists($AppPID)
	EndIf

	If Not $BrowserIsRunning Then
		; check other browser instance
		$AppPID = FindRunningAppPid($BrowserPath)
		If Not $AppPID Then
			ExitLoop
		EndIf
		$BrowserIsRunning = 1
		$hBrowserWindow = FindVisibleWindowByPid($AppPID, $BrowserWindowClass)
	EndIf

	If $TaskBarLastChange Then
		CheckPinnedPrograms($BrowserPath)
	EndIf
	RefreshBrowserJumpListIfDue()

	If $hEvent And Not _WinAPI_WaitForSingleObject($hEvent, 0) Then
		; MsgBox(0, "", "Reg changed!")
		Sleep(500)
		EnsureDefaultBrowser($BrowserPath)
		For $i = 0 To UBound($fReg) - 1
			If $fReg[$i][2] Then
				_WinAPI_RegNotifyChangeKeyValue($fReg[$i][2], $REG_NOTIFY_CHANGE_LAST_SET, 1, 1, $hEvent)
			EndIf
		Next
	EndIf
WEnd

RefreshBrowserJumpList(True)

If $CloseStartAppsAfterBrowserExit And $BrowserStartApps <> "" Then
	$cmd = ''
	For $i = 1 To $aBrowserStartAppPids[0]
		If Not $aBrowserStartAppPids[$i] Then ContinueLoop
		$cmd &= ' /PID ' & $aBrowserStartAppPids[$i]
	Next
	If $cmd Then
		$cmd = 'taskkill' & $cmd & ' /T /F'
		Run(@ComSpec & ' /c ' & $cmd, '', @SW_HIDE)
	EndIf
EndIf

; Start external apps
If $BrowserExitApps <> "" Then
	$aBrowserExitApps = StringSplit($BrowserExitApps, "||")
	For $i = 1 To $aBrowserExitApps[0]
		$match = StringRegExp($aBrowserExitApps[$i], '^"(.*?)" *(.*)', 1)
		If @error Then
			$file = $aBrowserExitApps[$i]
			$args = ""
		Else
			$file = $match[0]
			$args = $match[1]
		EndIf
		$file = FullPath($file)
		If Not ProcessExists(StringRegExpReplace($file, '.*\\', '')) Then
			If FileExists($file) Then
				ShellExecute($file, $args, StringRegExpReplace($file, '\\[^\\]+$', ''))
			EndIf
		EndIf
	Next
EndIf

Exit

;~ =================================== 以上为自动执行部分 ===============================

Func FindRunningAppPid($AppPath)
	Local $exe = StringRegExpReplace($AppPath, '.*\\', '')
	Local $list = ProcessList($exe)
	For $i = 1 To $list[0][0]
		If StringInStr(GetProcessPath($list[$i][1]), $AppPath) Then
			Return $list[$i][1]
		EndIf
	Next
	Return 0
EndFunc   ;==>FindRunningAppPid


Func FindVisibleWindowByPid($ProcessId, $WindowClass = "")
	$list = WinList("[REGEXPCLASS:(?i)" & $WindowClass & "]")
	For $i = 1 To $list[0][0]
		If Not BitAND(WinGetState($list[$i][1]), 2) Then ContinueLoop ; ignore hidden windows
		If $ProcessId = WinGetProcess($list[$i][1]) Then
			;ConsoleWrite("--> " & $list[$i][1] & "-" & $list[$i][0] & @CRLF)
			Return $list[$i][1]
		EndIf
	Next
EndFunc   ;==>FindVisibleWindowByPid

Func RegisterBossKeyHotKey()
	If Not IsBossKeySupportedBrowser($BrowserType) Or Not $BossKeyEnabled Or $BossKey = "" Then Return
	HotKeySet($BossKey, "ToggleBrowserBossKey")
EndFunc   ;==>RegisterBossKeyHotKey

Func ToggleBrowserBossKey()
	If $BossKeyBrowserHidden Then
		RestoreBrowserWindows()
	Else
		HideBrowserWindowsByBossKey()
	EndIf
EndFunc   ;==>ToggleBrowserBossKey

Func HideBrowserWindowsByBossKey()
	Local $list = WinList("[REGEXPCLASS:(?i)" & GetBrowserWindowClass($BrowserType) & "; REGEXPTITLE:\S+]")
	Local $Hidden = 0
	For $i = 1 To $list[0][0]
		If Not BitAND(WinGetState($list[$i][1]), 2) Then ContinueLoop
		If Not IsOwnedBrowserWindow($list[$i][1]) Then ContinueLoop
		WinSetState($list[$i][1], "", @SW_HIDE)
		$Hidden = 1
	Next
	If Not $Hidden Then Return

	$BossKeyBrowserHidden = 1
	If $BossKeyHideToTray Then ShowBossKeyTrayIcon()
EndFunc   ;==>HideBrowserWindowsByBossKey

Func RestoreBrowserWindows()
	If Not $BossKeyBrowserHidden And Not $BossKeyTrayVisible Then Return

	Local $list = WinList("[REGEXPCLASS:(?i)" & GetBrowserWindowClass($BrowserType) & "; REGEXPTITLE:\S+]")
	Local $Restored = 0
	For $i = 1 To $list[0][0]
		If BitAND(WinGetState($list[$i][1]), 2) Then ContinueLoop
		If Not IsOwnedBrowserWindow($list[$i][1]) Then ContinueLoop
		WinSetState($list[$i][1], "", @SW_SHOW)
		$Restored = 1
	Next

	If Not $Restored Then Return
	HideBossKeyTrayIcon()
	$BossKeyBrowserHidden = 0
EndFunc   ;==>RestoreBrowserWindows

Func IsOwnedBrowserWindow($hWnd)
	Local $pid = WinGetProcess($hWnd)
	If $pid = $AppPID Then Return True

	Local $ProcPath = GetProcessPath($pid)
	If $ProcPath = "" Then Return False
	Return NormalizePathForCompare($ProcPath) = NormalizePathForCompare($BrowserPath)
EndFunc   ;==>IsOwnedBrowserWindow

Func ShowBossKeyTrayIcon()
	Opt("TrayAutoPause", 0)
	Opt("TrayMenuMode", 3)
	Opt("TrayOnEventMode", 1)
	TraySetIcon($BrowserPath)
	TraySetClick(BitOR($TRAY_CLICK_PRIMARYDOWN, $TRAY_CLICK_PRIMARYUP, $TRAY_DBLCLICK_PRIMARY))
	TraySetOnEvent($TRAY_EVENT_PRIMARYDOWN, "RestoreBrowserWindows")
	TraySetOnEvent($TRAY_EVENT_PRIMARYUP, "RestoreBrowserWindows")
	TraySetOnEvent($TRAY_EVENT_PRIMARYDOUBLE, "RestoreBrowserWindows")
	TraySetToolTip(_t("BossKeyTrayTooltip", "浏览器已隐藏，点击还原"))
	TraySetState(1)
	$BossKeyTrayVisible = 1
EndFunc   ;==>ShowBossKeyTrayIcon

Func HideBossKeyTrayIcon()
	If Not $BossKeyTrayVisible Then Return
	TraySetOnEvent($TRAY_EVENT_PRIMARYDOWN, "")
	TraySetOnEvent($TRAY_EVENT_PRIMARYUP, "")
	TraySetOnEvent($TRAY_EVENT_PRIMARYDOUBLE, "")
	TraySetToolTip("")
	TraySetIcon()
	TraySetState(2)
	Opt("TrayOnEventMode", 0)
	$BossKeyTrayVisible = 0
EndFunc   ;==>HideBossKeyTrayIcon


Func OnExit()
	CancelAppUpdateCheck()
	RestoreBrowserWindows()
	If $hEvent Then
		_WinAPI_CloseHandle($hEvent)
		For $i = 0 To UBound($fReg) - 1
			_WinAPI_RegCloseKey($fReg[$i][2])
		Next
	EndIf
	IniWrite($inifile, "Settings", "LastPlatformDir", $BrowserDirectory)
	IniWrite($inifile, "Settings", "LastProfileDir", $ProfileDir)
EndFunc   ;==>OnExit


;~ 查检 RunFirefox更新
Func CheckForAppUpdate()
	Local $latestVersion, $releaseNotes
	If Not GetAvailableAppUpdate($latestVersion, $releaseNotes) Then Return
	PromptAndApplyAppUpdate($latestVersion, $releaseNotes)
EndFunc   ;==>CheckForAppUpdate

Func GetAvailableAppUpdate(ByRef $latestVersion, ByRef $releaseNotes)
	Local $AppUpdateLastCheck, $repo = 'benzBrake/RunFirefox', $MirrorAddress = GetEffectiveGithubDirectMirror()
	$MirrorAddress = _UpgradeNormalizeMirrorAddress($MirrorAddress)
	$AppUpdateLastCheck = _NowCalc()
	IniWrite($inifile, "Settings", "AppUpdateLastCheck", $AppUpdateLastCheck)

	$latestVersion = GetLatestReleaseVersion($repo, $MirrorAddress, GetEffectiveGithubJsDelivrMirror());
	;~ 获取的版本号不对则返回
	If Not _StringStartsWith($latestVersion, 'v') Then Return False
	;~ 去除版本号开头的 v
	$latestVersion = StringTrimLeft($latestVersion, 1)
	;~ 比较版本号，如果版本号相同则返回
	If VersionCompare($latestVersion, $AppVersion) <= 0 Then Return False
	;~ 获取更新日志
	$releaseNotes = GetReleaseNotesByVersion($repo, "v" & $latestVersion, $MirrorAddress);
	Return True
EndFunc   ;==>GetAvailableAppUpdate

Func PromptAndApplyAppUpdate($latestVersion, $releaseNotes)
	Local $repo = 'benzBrake/RunFirefox', $downloadUrl, $MirrorAddress = GetEffectiveGithubDirectMirror(), $msg, $file, $FileName
	$MirrorAddress = _UpgradeNormalizeMirrorAddress($MirrorAddress)
	$UpdateAvailable = _t("UpdateAvailable", "{AppName} {Version} 已发布，更新内容：\n\n\n{Notes}\n是否自动更新？")
	$UpdateAvailable = StringReplace($UpdateAvailable, "{AppName}", $AppName)
	$UpdateAvailable = StringReplace($UpdateAvailable, "{Version}", $latestVersion)
	$UpdateAvailable = StringReplace($UpdateAvailable, "{Notes}", $releaseNotes)
	If $hSettings Then
		$msg = MsgBox(68, $AppName, $UpdateAvailable, 0, $hSettings)
	Else
		$msg = MsgBox(68, $AppName, $UpdateAvailable)
	EndIf
	If $msg <> 6 Then Return

	;~ 拼接下载链接
	$archStr = '';
	If @AutoItX64 Then
		$archStr &= "_x64"
	EndIf
	Local $downloadFileName = $AppName & '_' & $latestVersion & $archStr & '.zip'
	Local $githubDownloadUrl = 'https://github.com/' & $repo & '/releases/download/v' & $latestVersion & '/' & $downloadFileName
	Local $downloadUrls = _UpgradeBuildGithubReleaseDownloadUrls($githubDownloadUrl, $MirrorAddress, GetEffectiveGithubJsDelivrMirror())

	Local $temp = @ScriptDir & "\RunFirefox_temp"
	$file = $temp & "\RunFirefox.zip"
	If Not FileExists($temp) Then DirCreate($temp)
	Opt("TrayAutoPause", 0)
	Opt("TrayMenuMode", 3) ; Default tray menu items (Script Paused/Exit) will not be shown.
	TraySetState(1)
	TraySetClick(8)
	TraySetToolTip($AppName)
	Local $DownloadSuccessful, $DownloadCancelled, $UpdateSuccessful, $error
	_DownloadToolsShowDownloadProgress(_t("DownloadingAppUpdate", "下载 RunFirefox 更新"), _t("StartToDownloadApp", "开始下载 {AppName}"), "", $hSettings, _t("Cancel", "取消"))
	Local $TriedUpdateUrls = ""
	$DownloadSuccessful = _DownloadToolsDownloadUrls($downloadUrls, $file, _t("StartToDownloadApp", "开始下载 {AppName}"), _t("BrowserDownloadProgressKnown", "已下载 {Downloaded} / {Total}"), _t("BrowserDownloadProgressUnknown", "已下载 %s"), $TriedUpdateUrls)
	$DownloadCancelled = _DownloadToolsIsDownloadProgressCancelled()
	_DownloadToolsCloseDownloadProgress()
	If Not $DownloadCancelled Then
		If $DownloadSuccessful Then
			TrayTip("", _t("ApplyingUpdate", "正在应用 {AppName} 更新"), 10, 1)
			FileSetAttrib($file, "+A")
			_Zip_UnzipAll($file, $temp)
			$FileName = $AppName & ".exe"
			If @AutoItX64 Then
				$FileName = $AppName & "_x64.exe"
			EndIf
			If FileExists($temp & "\" & $FileName) Then
				FileMove(@ScriptFullPath, @ScriptDir & "\" & @ScriptName & ".bak", 9)
				FileMove($temp & "\" & $FileName, @ScriptFullPath, 9)
				FileDelete($file)
				DirCopy($temp, @ScriptDir, 1)
				$UpdateSuccessful = 1
			Else
				$error = _t("FailToDeCompressUpdateFile", "解压更新文件失败。")
			EndIf
		Else
			$error = _t("FailToDownloadUpdateFile", "下载更新文件失败。")
		EndIf
		If $UpdateSuccessful Then
			Local $UpdateSuccessfulMsg = _t("UpdateSuccessConfirm", "{AppName} 已更新至 {Version} ！\n原 {ScriptName} 已备份为 {ScriptNameBak}")
			$UpdateSuccessfulMsg = StringReplace($UpdateSuccessfulMsg, "{Version}", $latestVersion)
			$UpdateSuccessfulMsg = StringReplace($UpdateSuccessfulMsg, "{ScriptNameBak}", @ScriptName & ".bak")
			MsgBox(64, $AppName, $UpdateSuccessfulMsg)
		Else
			Local $UpdateFailedConfirmMsg = _t("UpdateFailedConfirm", "{AppName} 自动更新失败：\n%s\n\n是否去软件发布页手动下载 {AppName}？", $error)
			$msg = MsgBox(20, $AppName, $UpdateFailedConfirmMsg)
			If $msg = 6 Then ; Yes
				ShellExecute("https://github.com/benzBrake/RunFirefox/releases")
			EndIf
		EndIf
	EndIf
	DirRemove($temp, 1)
	TraySetState(2)
EndFunc   ;==>PromptAndApplyAppUpdate

Func WriteAppUpdateCheckResultFile($OutputFile)
	Local $latestVersion = "", $releaseNotes = ""
	FileDelete($OutputFile)
	If GetAvailableAppUpdate($latestVersion, $releaseNotes) Then
		IniWrite($OutputFile, "AppUpdate", "Success", 1)
		IniWrite($OutputFile, "AppUpdate", "HasUpdate", 1)
		IniWrite($OutputFile, "AppUpdate", "Version", $latestVersion)
		IniWrite($OutputFile, "AppUpdate", "Notes", EncodeAppUpdateResultText($releaseNotes))
	Else
		IniWrite($OutputFile, "AppUpdate", "Success", 1)
		IniWrite($OutputFile, "AppUpdate", "HasUpdate", 0)
	EndIf
EndFunc   ;==>WriteAppUpdateCheckResultFile

Func EncodeAppUpdateResultText($Text)
	If $Text = "" Then Return ""
	Return StringTrimLeft(StringToBinary($Text, 4), 2)
EndFunc   ;==>EncodeAppUpdateResultText

Func DecodeAppUpdateResultText($Text)
	If $Text = "" Then Return ""
	Return BinaryToString("0x" & $Text, 4)
EndFunc   ;==>DecodeAppUpdateResultText

Func StartAppUpdateCheckProcess($OutputFile)
	Local $Command = ""
	If @Compiled Then
		$Command = '"' & @AutoItExe & '"'
	Else
		$Command = '"' & @AutoItExe & '" "' & @ScriptFullPath & '"'
	EndIf
	$Command &= ' --check-app-update "' & $OutputFile & '"'
	Return Run($Command, @ScriptDir, @SW_HIDE)
EndFunc   ;==>StartAppUpdateCheckProcess

Func BeginAppUpdateCheck()
	If $AppUpdateCheckHandle Then Return
	If Not $AppUpdateCheckEnabled Then Return
	If _DateDiff("h", $AppUpdateLastCheck, _NowCalc()) < 48 Then Return

	$AppUpdateLastCheck = _NowCalc()
	IniWrite($inifile, "Settings", "AppUpdateLastCheck", $AppUpdateLastCheck)
	$AppUpdateCheckFile = @TempDir & "\RunFirefox_AppUpdate_" & @AutoItPID & ".tmp"
	FileDelete($AppUpdateCheckFile)
	$AppUpdateCheckHandle = StartAppUpdateCheckProcess($AppUpdateCheckFile)
	If Not $AppUpdateCheckHandle Then
		CancelAppUpdateCheck()
		Return
	EndIf
	AdlibRegister("PollAppUpdateCheck", 500)
EndFunc   ;==>BeginAppUpdateCheck

Func CancelAppUpdateCheck()
	AdlibUnRegister("PollAppUpdateCheck")
	If $AppUpdateCheckHandle Then
		If ProcessExists($AppUpdateCheckHandle) Then ProcessClose($AppUpdateCheckHandle)
	EndIf
	If $AppUpdateCheckFile <> "" Then FileDelete($AppUpdateCheckFile)
	$AppUpdateCheckHandle = 0
	$AppUpdateCheckFile = ""
EndFunc   ;==>CancelAppUpdateCheck

Func PollAppUpdateCheck()
	If Not $AppUpdateCheckHandle Then
		CancelAppUpdateCheck()
		Return
	EndIf
	If ProcessExists($AppUpdateCheckHandle) Then Return

	Local $LoadedFile = $AppUpdateCheckFile
	$AppUpdateCheckHandle = 0
	AdlibUnRegister("PollAppUpdateCheck")

	Local $Success = FileExists($LoadedFile) And IniRead($LoadedFile, "AppUpdate", "Success", 0) = 1
	Local $HasUpdate = $Success And IniRead($LoadedFile, "AppUpdate", "HasUpdate", 0) = 1
	Local $latestVersion = IniRead($LoadedFile, "AppUpdate", "Version", "")
	Local $releaseNotes = DecodeAppUpdateResultText(IniRead($LoadedFile, "AppUpdate", "Notes", ""))
	FileDelete($LoadedFile)
	$AppUpdateCheckFile = ""

	If $HasUpdate And $latestVersion <> "" Then PromptAndApplyAppUpdate($latestVersion, $releaseNotes)
EndFunc   ;==>PollAppUpdateCheck


Func DeleteCfgFiles()
	FileDelete($BrowserDirectory & "\defaults\pref\runfirefox.js")
	FileDelete($BrowserDirectory & "\runfirefox.cfg")
EndFunc   ;==>DeleteCfgFiles

Func DeleteMozillaLaunchOnLoginEntry($BrowserPath)
	Local Const $RunKey = "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
	Local Const $StartupApprovedRunKey = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
	Local $ValueIndex = 1, $ValueName, $Command, $Deleted = False

	While 1
		$ValueName = RegEnumVal($RunKey, $ValueIndex)
		If @error Then ExitLoop

		$Command = RegRead($RunKey, $ValueName)
		If CommandTargetsPath($Command, $BrowserPath) Then
			If RegDelete($RunKey, $ValueName) Then
				RegDelete($StartupApprovedRunKey, $ValueName)
				$Deleted = True
				ContinueLoop
			EndIf
		EndIf

		$ValueIndex += 1
	WEnd

	Return $Deleted
EndFunc   ;==>DeleteMozillaLaunchOnLoginEntry

Func WaitAndDeleteMozillaLaunchOnLoginEntry($BrowserPath, $MaxChecks = 10, $IntervalMs = 1000)
	Local $i, $Deleted = False
	For $i = 1 To $MaxChecks
		Sleep($IntervalMs)
		If DeleteMozillaLaunchOnLoginEntry($BrowserPath) Then $Deleted = True
		; Mozilla browsers may create start menu shortcuts during first launch.
		If SyncMozillaStartMenuShortcuts() Then $Deleted = True
	Next

	Return $Deleted
EndFunc   ;==>WaitAndDeleteMozillaLaunchOnLoginEntry

Func SyncMozillaStartMenuShortcuts($ProgramsDir = Default)
	If Not IsMozillaBrowser($BrowserType) Then Return False

	If IsKeyword($ProgramsDir) Then $ProgramsDir = EnvGet("APPDATA") & "\Microsoft\Windows\Start Menu\Programs"
	Local $PrivateBrowsingPath = $BrowserDirectory & "\private_browsing.exe"
	If Not FileExists($ProgramsDir) Or StringStripWS($BrowserPath, 3) = "" Then Return False

	Local $search = FileFindFirstFile($ProgramsDir & "\*.lnk")
	If $search = -1 Then Return False

	Local $Updated = False
	Local $file, $ShellObj, $objShortcut, $path, $arguments, $icon, $shortcut_appid
	Local $path_matches_browser, $path_matches_private
	Local $oError = ObjEvent("AutoIt.Error", "ShortcutComError")
	$ShellObj = ObjCreate("WScript.Shell")
	If Not @error And IsObj($ShellObj) Then
		While 1
			$file = $ProgramsDir & "\" & FileFindNextFile($search)
			If @error Then ExitLoop
			If Not FileExists($file) Then ContinueLoop

			$objShortcut = $ShellObj.CreateShortCut($file)
			If @error Or Not IsObj($objShortcut) Then ContinueLoop
			$path = $objShortcut.TargetPath
			If @error Or StringStripWS($path, 3) = "" Then ContinueLoop

			$path_matches_browser = NormalizePathForCompare($path) = NormalizePathForCompare($BrowserPath)
			$path_matches_private = FileExists($PrivateBrowsingPath) And NormalizePathForCompare($path) = NormalizePathForCompare($PrivateBrowsingPath)
			If Not $path_matches_browser And Not $path_matches_private Then ContinueLoop

			$arguments = $objShortcut.Arguments
			If @error Then $arguments = ""
			$icon = $objShortcut.IconLocation
			If @error Then $icon = ""
			$shortcut_appid = _ShortcutAppId($file)

			; Route vendor shortcuts through RunFirefox while preserving their identity.
			$objShortcut.TargetPath = @ScriptFullPath
			If $path_matches_private Then
				$objShortcut.Arguments = "-private-window"
			Else
				$objShortcut.Arguments = $arguments
			EndIf
			$objShortcut.WorkingDirectory = @ScriptDir
			If StringStripWS($icon, 3) <> "" Then $objShortcut.IconLocation = $icon
			$objShortcut.Save
			If @error Then ContinueLoop
			If $shortcut_appid Then _ShortcutAppId($file, $shortcut_appid)
			$Updated = True
		WEnd
		$objShortcut = ""
		$ShellObj = ""
	EndIf
	FileClose($search)

	Return $Updated
EndFunc   ;==>SyncMozillaStartMenuShortcuts

Func CheckPrefs()
	Local $var, $cfg
	Local $prefs = FileRead($ProfileDir & "\prefs.js")
	Local $BrowserLocale = GetBrowserLocale()

	If $BrowserLocale Then
		If $BrowserType = $BrowserZen Then UpdateProfileLocalePrefs($BrowserLocale, $prefs)
		$cfg &= 'pref("intl.locale.matchOS", false);' & @CRLF
		$cfg &= 'pref("intl.locale.requested", "' & $BrowserLocale & '");' & @CRLF
	EndIf

	If Not StringRegExp($prefs, '(?i)(?m)^\Quser_pref("browser.shell.checkDefaultBrowser",\E *\Qfalse);\E') Then
		$cfg &= 'pref("browser.shell.checkDefaultBrowser", false);' & @CRLF
	EndIf

	ClearLaunchOnLoginProfilePref($prefs)

	$CustomCacheDir = FullPath($CustomCacheDir)
	If $CustomCacheDir = "" Or $CustomCacheDir = $ProfileDir Then ; profile\ is the default chache dir
		If StringInStr($prefs, 'user_pref("browser.cache.disk.parent_directory",') Then
			$cfg &= 'clearPref("browser.cache.disk.parent_directory");' & @CRLF
		EndIf
	Else
		$var = StringReplace($CustomCacheDir, '\', '\\')
		$cfg &= 'pref("browser.cache.disk.parent_directory", "' & $var & '");' & @CRLF
	EndIf

	If $CacheSize = "" Or $CacheSize = 250 Then ; 250 is the default
		If StringInStr($prefs, 'user_pref("browser.cache.disk.capacity",') Then
			$cfg &= 'clearPref("browser.cache.disk.capacity");' & @CRLF
		EndIf
	Else
		$var = $CacheSize * 1024
		$cfg &= 'pref("browser.cache.disk.capacity", ' & $var & ');' & @CRLF
	EndIf

	If $CacheSizeSmart = 1 Then
		$cfg &= 'pref("browser.cache.disk.smart_size.enabled", true);' & @CRLF
	Else
		$cfg &= 'pref("browser.cache.disk.smart_size.enabled", false);' & @CRLF
	EndIf
	If $cfg Then
		$cfg = '//' & @CRLF & $cfg
	EndIf
	$prefs = ''
	Return $cfg
EndFunc   ;==>CheckPrefs

Func ClearLaunchOnLoginProfilePref(ByRef $prefs)
	Local $PrefsPath = $ProfileDir & "\prefs.js"
	If Not FileExists($PrefsPath) Then Return

	Local $NewPrefs = StringRegExpReplace($prefs, '(?i)(?m)^user_pref\("browser\.startup\.windowsLaunchOnLogin\.enabled",.*\);\R?', "")
	If $NewPrefs = $prefs Then Return

	FileDelete($PrefsPath)
	FileWrite($PrefsPath, $NewPrefs)
	$prefs = $NewPrefs
EndFunc   ;==>ClearLaunchOnLoginProfilePref

Func UpdateProfileLocalePrefs($BrowserLocale, ByRef $prefs)
	Local $PrefsPath = $ProfileDir & "\prefs.js"
	If Not FileExists($PrefsPath) Then Return

	Local $NewPrefs = StringRegExpReplace($prefs, '(?i)(?m)^user_pref\("intl\.locale\.(matchOS|requested)",.*\);\R?', "")
	$NewPrefs &= 'user_pref("intl.locale.matchOS", false);' & @CRLF
	$NewPrefs &= 'user_pref("intl.locale.requested", "' & $BrowserLocale & '");' & @CRLF
	If $NewPrefs = $prefs Then Return

	FileDelete($PrefsPath)
	FileWrite($PrefsPath, $NewPrefs)
	$prefs = $NewPrefs
EndFunc   ;==>UpdateProfileLocalePrefs

Func QuoteCommandLineArgument($Value)
	Local $Text = String($Value)
	Local $Quoted = '"', $BackslashCount = 0
	Local $i, $Character
	For $i = 1 To StringLen($Text)
		$Character = StringMid($Text, $i, 1)
		If $Character = "\" Then
			$BackslashCount += 1
		ElseIf $Character = '"' Then
			$Quoted &= RepeatText("\", $BackslashCount * 2 + 1) & '"'
			$BackslashCount = 0
		Else
			If $BackslashCount Then $Quoted &= RepeatText("\", $BackslashCount)
			$BackslashCount = 0
			$Quoted &= $Character
		EndIf
	Next
	If $BackslashCount Then $Quoted &= RepeatText("\", $BackslashCount * 2)
	Return $Quoted & '"'
EndFunc   ;==>QuoteCommandLineArgument

Func RepeatText($Value, $Count)
	Local $Result = "", $i
	For $i = 1 To $Count
		$Result &= $Value
	Next
	Return $Result
EndFunc   ;==>RepeatText

Func RefreshBrowserJumpListIfDue()
	If (Not IsMozillaBrowser($BrowserType) And Not IsChromeBrowser($BrowserType)) Or Not $AppUserModelId Then Return False
	If $JumpListLastRefresh And TimerDiff($JumpListLastRefresh) < 60000 Then Return False
	Return RefreshBrowserJumpList()
EndFunc   ;==>RefreshBrowserJumpListIfDue

Func RefreshBrowserJumpList($Force = False)
	If Not @Compiled Or (Not IsMozillaBrowser($BrowserType) And Not IsChromeBrowser($BrowserType)) Or Not $AppUserModelId Then Return False
	$JumpListLastRefresh = TimerInit()

	Local $aTasks[4][5]
	$aTasks[0][0] = _t("JumpListNewTab", "新建标签页")
	$aTasks[0][1] = "--jump-action new-tab"
	$aTasks[0][2] = $aTasks[0][0]
	$aTasks[0][3] = 3
	$aTasks[1][0] = _t("JumpListNewWindow", "新建窗口")
	$aTasks[1][1] = "--jump-action new-window"
	$aTasks[1][2] = $aTasks[1][0]
	$aTasks[1][3] = 2
	$aTasks[2][0] = _t("JumpListPrivateWindow", "新建隐私窗口")
	$aTasks[2][1] = "--jump-action private-window"
	$aTasks[2][2] = $aTasks[2][0]
	$aTasks[2][3] = 4
	$aTasks[3][0] = _t("JumpListLauncherSettings", "启动器设置")
	$aTasks[3][1] = "-set"
	$aTasks[3][2] = $aTasks[3][0]
	$aTasks[3][3] = -27
	$aTasks[3][4] = @SystemDir & "\imageres.dll"
	If IsChromeBrowser($BrowserType) Then
		$aTasks[0][3] = 0
		$aTasks[1][3] = 0
		$aTasks[2][3] = 0
	EndIf

	Local $aDestinations[1][4], $DestinationCount = 0, $i
	Local $aPlaceRows, $PlaceCount = 0
	If IsChromeBrowser($BrowserType) Then
		$PlaceCount = _ChromiumHistoryGetFrequent($ProfileDir, 10, $aPlaceRows)
	Else
		$PlaceCount = _FirefoxPlacesGetFrequent($ProfileDir, 10, $aPlaceRows)
	EndIf
	If $PlaceCount > 0 And IsArray($aPlaceRows) Then
		ReDim $aDestinations[$PlaceCount][4]
		Local $Title, $Url
		For $i = 1 To $PlaceCount
			$Url = $aPlaceRows[$i][1]
			If $Url = "" Then ContinueLoop
			$Title = StringStripWS(StringReplace(StringReplace($aPlaceRows[$i][0], @CR, " "), @LF, " "), 3)
			If $Title = "" Then $Title = $Url
			If StringLen($Title) > 260 Then $Title = StringLeft($Title, 257) & "..."

			$aDestinations[$DestinationCount][0] = $Title
			$aDestinations[$DestinationCount][1] = "--jump-url " & QuoteCommandLineArgument($Url)
			$aDestinations[$DestinationCount][2] = $Url
			$aDestinations[$DestinationCount][3] = 1
			$DestinationCount += 1
		Next
	EndIf

	Local $Signature = $AppUserModelId & "|" & $ProfileDir
	For $i = 0 To $DestinationCount - 1
		$Signature &= "|" & $aDestinations[$i][0] & "=" & $aDestinations[$i][1]
	Next
	If Not $Force And $Signature = $JumpListContentSignature Then Return True

	Local $Built = _JumpListBuild($AppUserModelId, @ScriptFullPath, @ScriptDir, $BrowserPath, $aTasks, 4, _t("JumpListFrequent", "常用"), $aDestinations, $DestinationCount)
	If $Built Then $JumpListContentSignature = $Signature
	Return $Built
EndFunc   ;==>RefreshBrowserJumpList

; for win7+
; Group different app icons on Taskbar need the same AppUserModelIDs
; http://msdn.microsoft.com/en-us/library/dd378459%28VS.85%29.aspx
Func CheckPinnedPrograms($browser_path)
	If Not FileExists($TaskBarDir) Or StringStripWS($browser_path, 3) = "" Then
		Return
	EndIf
	Local $ftime = FileGetTime($TaskBarDir, 0, 1)
	Local $iconSourcePath = ""
	Local $iconSourceTime = 0
	If IsMozillaBrowser($BrowserType) Then $iconSourcePath = $ProfileDir & "\prefs.js"
	If FileExists($iconSourcePath) Then $iconSourceTime = FileGetTime($iconSourcePath, 0, 1)
	If $ftime = $TaskBarLastChange And $iconSourceTime = $BrowserIconLastChange Then
		Return
	EndIf

	$TaskBarLastChange = $ftime
	$BrowserIconLastChange = $iconSourceTime
	Local $search = FileFindFirstFile($TaskBarDir & "\*.lnk")
	If $search = -1 Then Return
	Local $file, $ShellObj, $objShortcut, $shortcut_appid, $shortcut_icon, $path
	Local $desired_icon, $icon_state, $icon_known, $path_matches_browser, $path_matches_launcher
	Local $oError = ObjEvent("AutoIt.Error", "ShortcutComError")
	$desired_icon = GetBrowserTaskbarIconLocation($browser_path, $icon_state, $icon_known)
	If $icon_state <> "" And $icon_state <> $BrowserIconState Then
		$BrowserIconState = $icon_state
	ElseIf $BrowserIconState = "" And $icon_state <> "" Then
		$BrowserIconState = $icon_state
	EndIf
	$ShellObj = ObjCreate("WScript.Shell")
	If Not @error And IsObj($ShellObj) Then
		While 1
			$file = $TaskBarDir & "\" & FileFindNextFile($search)
			If @error Then ExitLoop
			If Not FileExists($file) Then ContinueLoop
			$objShortcut = $ShellObj.CreateShortCut($file)
			If @error Or Not IsObj($objShortcut) Then ContinueLoop
			$path = $objShortcut.TargetPath
			If @error Or StringStripWS($path, 3) = "" Then ContinueLoop
			$path_matches_browser = NormalizePathForCompare($path) = NormalizePathForCompare($browser_path)
			$path_matches_launcher = NormalizePathForCompare($path) = NormalizePathForCompare(@ScriptFullPath)
			If $path_matches_browser Or $path_matches_launcher Then
				$shortcut_icon = $objShortcut.IconLocation
				If @error Then $shortcut_icon = ""
				If $path_matches_browser Then
					$objShortcut.TargetPath = @ScriptFullPath
					; Keep the browser's icon resource so Windows does not switch to RunFirefox.exe's icon.
					If $icon_known Then
						$objShortcut.IconLocation = $desired_icon
					ElseIf StringStripWS($shortcut_icon, 3) <> "" Then
						$objShortcut.IconLocation = $shortcut_icon
					EndIf
					$objShortcut.Save
					$TaskBarLastChange = FileGetTime($TaskBarDir, 0, 1)
				ElseIf $icon_known And NormalizePathForCompare($shortcut_icon) <> NormalizePathForCompare($desired_icon) Then
					; Keep the redirected pin in sync with the browser icon even though its
					; target is RunFirefox.
					$objShortcut.IconLocation = $desired_icon
					$objShortcut.Save
					$TaskBarLastChange = FileGetTime($TaskBarDir, 0, 1)
				EndIf
				$shortcut_appid = _ShortcutAppId($file)

				If Not $AppUserModelId Then
					;Sleep(3000)
					; usually fails to get firefox's window appid while succeeds on chrome,
					; what's wrong?
					$AppUserModelId = _WindowAppId($hBrowserWindow)
					If Not $AppUserModelId Then
						If IsMozillaBrowser($BrowserType) Then
							$AppUserModelId = AppIdFromRegistry()
							If Not $AppUserModelId Then
								; helper.exe writes AppUserModelIDs to SOFTWARE\Mozilla\Firefox\TaskBarIDs
								Local $pid = Run($BrowserDirectory & "\uninstall\helper.exe /UpdateShortcutAppUserModelIds")
								ProcessWaitClose($pid, 5)
								SyncMozillaStartMenuShortcuts()
								$AppUserModelId = AppIdFromRegistry()
							EndIf
						EndIf

						If Not $AppUserModelId Then
							If $shortcut_appid Then
								$AppUserModelId = $shortcut_appid
							Else ; if no window appid found,set an id for the window
								$AppUserModelId = "RunFirefox." & StringTrimLeft(_WinAPI_HashString(@ScriptFullPath, 0, 16), 2)
							EndIf
						EndIf
						_WindowAppId($hBrowserWindow, $AppUserModelId)
					EndIf
				EndIf
				; Firefox 154 uses the shortcut AppUserModelID to enumerate its taskbar
				; identity. Preserve an existing vendor ID; only populate a missing one.
				If Not $shortcut_appid And $AppUserModelId Then
					_ShortcutAppId($file, $AppUserModelId)
					$TaskBarLastChange = FileGetTime($TaskBarDir, 0, 1)
				EndIf
				ExitLoop
			EndIf
		WEnd
		$objShortcut = ""
		$ShellObj = ""
	EndIf
	FileClose($search)
EndFunc   ;==>CheckPinnedPrograms

Func GetBrowserTaskbarIconLocation($browser_path, ByRef $icon_state, ByRef $icon_known)
	$icon_state = ""
	$icon_known = False
	If IsChromeBrowser($BrowserType) Then
		If Not FileExists($browser_path) Then Return ""
		$icon_state = NormalizePathForCompare($browser_path) & "|0"
		$icon_known = True
		Return $browser_path & ",0"
	EndIf
	If Not IsMozillaBrowser($BrowserType) Then Return ""
	Local $prefsPath = $ProfileDir & "\prefs.js"
	If Not FileExists($prefsPath) Then Return ""
	Local $prefs = FileRead($prefsPath)
	If @error Then Return ""
	Local $matches = StringRegExp($prefs, '(?i)user_pref\("browser\.shell\.customIcon\.id",\s*"([^"]*)"\)', 1)
	If @error Or UBound($matches) = 0 Then
		; A removed preference means Firefox has reverted to its default resource.
		$icon_state = "default"
		$icon_known = True
		Return $browser_path & ",0"
	EndIf

	$icon_state = StringLower($matches[0])
	$icon_known = True
	Switch $icon_state
		Case "retro2004"
			Return $browser_path & ",-1100"
		Case "retro2017"
			Return $browser_path & ",-1101"
		Case "minimal"
			Local $systemTheme = RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "SystemUsesLightTheme")
			If $systemTheme = 1 Then Return $browser_path & ",-1103"
			Return $browser_path & ",-1102"
		Case "pride"
			Return $browser_path & ",-1106"
		Case "kit"
			Return $browser_path & ",-1107"
		Case "pixelated"
			Return $browser_path & ",-1104"
		Case "momo"
			Return $browser_path & ",-1105"
		Case "default"
			Return $browser_path & ",0"
	EndSwitch
	$icon_state = ""
	$icon_known = False
	Return ""
EndFunc   ;==>GetBrowserTaskbarIconLocation

Func ShortcutComError($oError)
	Return
EndFunc   ;==>ShortcutComError

Func AppIdFromRegistry()
	Local $appid
	If @OSArch = "X86" Then
		Local $aRoot[2] = ["HKCU\SOFTWARE", $HKLM_Software_32]
	Else
		Local $aRoot[3] = ["HKCU\SOFTWARE", $HKLM_Software_32, $HKLM_Software_64]
	EndIf
	For $i = 0 To UBound($aRoot) - 1
		$appid = RegRead($aRoot[$i] & "\Mozilla\Firefox\TaskBarIDs", $BrowserDirectory)
		If $appid Then ExitLoop
	Next
	Return $appid
EndFunc   ;==>AppIdFromRegistry

Func CreateSettingsShortcut($fname)
	Local $var = FileRead($fname)
	If $var <> 'CreateObject("shell.application").ShellExecute "' & @ScriptName & '", "-set"' Then
		FileDelete($fname)
		FileWrite($fname, 'CreateObject("shell.application").ShellExecute "' & @ScriptName & '", "-set"')
	EndIf
EndFunc   ;==>CreateSettingsShortcut


Func EnsureDefaultBrowser($BrowserPath)
	If IsChromeBrowser($BrowserType) Then Return CheckChromeDefaultBrowser($BrowserPath)
	Return CheckMozillaDefaultBrowser($BrowserPath)
EndFunc   ;==>EnsureDefaultBrowser

Func CheckMozillaDefaultBrowser($BrowserPath)
	Local $InternetClient, $key, $i, $j, $var, $RegWriteError = 0
	If Not $ClientKey Then
		If @OSArch = "X86" Then
			Local $aRoot[2] = ["HKCU\SOFTWARE", $HKLM_Software_32]
		Else
			Local $aRoot[3] = ["HKCU\SOFTWARE", $HKLM_Software_32, $HKLM_Software_64]
		EndIf
		For $i = 0 To UBound($aRoot) - 1 ; search FIREFOX.EXE in internetclient
			$j = 1
			While 1
				$InternetClient = RegEnumKey($aRoot[$i] & "\Clients\StartMenuInternet", $j)
				If @error <> 0 Then ExitLoop
				$key = $aRoot[$i] & '\Clients\StartMenuInternet\' & $InternetClient
				$var = RegRead($key & '\DefaultIcon', '')
				If StringInStr($var, $BrowserPath) Then
					$ClientKey = $key
					$FileAsso = RegRead($ClientKey & '\Capabilities\FileAssociations', '.html')
					$URLAsso = RegRead($ClientKey & '\Capabilities\URLAssociations', 'http')
					ExitLoop 2
				EndIf
				$j += 1
			WEnd
		Next
	EndIf
	If $ClientKey Then
		$var = RegRead($ClientKey & '\shell\open\command', '')
		If Not StringInStr($var, @ScriptFullPath) Then
			$RegWriteError += Not RegWrite($ClientKey & '\shell\open\command', '', 'REG_SZ', '"' & @ScriptFullPath & '"')
			RegWrite($ClientKey & '\shell\properties\command', '', 'REG_SZ', '"' & @ScriptFullPath & '" -preferences')
			RegWrite($ClientKey & '\shell\safemode\command', '', 'REG_SZ', '"' & @ScriptFullPath & '" -safe-mode')
		EndIf
	EndIf

	If Not $FileAsso Then
		If StringInStr(RegRead('HKCR\FirefoxHTML\DefaultIcon', ''), $BrowserPath) Then
			$FileAsso = "FirefoxHTML"
		EndIf
	EndIf
	If Not $URLAsso Then
		If StringInStr(RegRead('HKCR\FirefoxURL\DefaultIcon', ''), $BrowserPath) Then
			$URLAsso = "FirefoxURL"
		EndIf
	EndIf

	Local $aAsso[2] = [$FileAsso, $URLAsso]
	For $i = 0 To 1
		If Not $aAsso[$i] Then ContinueLoop
		$var = RegRead('HKCR\' & $aAsso[$i] & '\shell\open\command', '')
		If Not StringInStr($var, @ScriptFullPath) Then
			$RegWriteError += Not RegWrite('HKCR\' & $aAsso[$i] & '\shell\open\command', _
					'', 'REG_SZ', '"' & @ScriptFullPath & '" -url "%1"')
			RegDelete('HKCR\' & $aAsso[$i] & '\shell\open\command', 'DelegateExecute')
			RegWrite('HKCR\' & $aAsso[$i] & '\shell\open\ddeexec', '', 'REG_SZ', '')
		EndIf
		If Not $fReg[5 + $i][1] Then
			$fReg[5 + $i][1] = $aAsso[$i] ; for reg notification
			$fReg[5 + $i][2] = _WinAPI_RegOpenKey($fReg[5 + $i][0], $fReg[5 + $i][1], $KEY_NOTIFY)
		EndIf
	Next

	Local $aUrlAsso[3] = ['ftp', 'http', 'https']
	For $i = 0 To 2
		$var = RegRead('HKCR\' & $aUrlAsso[$i] & '\DefaultIcon', '')
		If StringInStr($var, $BrowserPath) Then
			$var = RegRead('HKCR\' & $aUrlAsso[$i] & '\shell\open\command', '')
			If Not StringInStr($var, @ScriptFullPath) Then
				$RegWriteError += Not RegWrite('HKCR\' & $aUrlAsso[$i] & '\shell\open\command', _
						'', 'REG_SZ', '"' & @ScriptFullPath & '" -url "%1"')
				RegDelete('HKCR\' & $aUrlAsso[$i] & '\shell\open\command', 'DelegateExecute')
				RegWrite('HKCR\' & $aUrlAsso[$i] & '\shell\open\ddeexec', '', 'REG_SZ', '')
			EndIf
		EndIf
	Next

	If $RegWriteError And Not _IsUACAdmin() And @extended Then
		If @Compiled Then
			ShellExecute(@ScriptName, "-SetDefaultGlobal", @ScriptDir, "runas")
		Else
			ShellExecute(@AutoItExe, '"' & @ScriptFullPath & '" -SetDefaultGlobal', @ScriptDir, "runas")
		EndIf
	EndIf
EndFunc   ;==>CheckMozillaDefaultBrowser

Func CheckChromeDefaultBrowser($BrowserPath)
	Local $InternetClient, $key, $i, $j, $var, $RegWriteError = 0
	If Not $ClientKey Then
		If @OSArch = "X86" Then
			Local $aRoot[2] = ["HKCU\SOFTWARE", $HKLM_Software_32]
		Else
			Local $aRoot[3] = ["HKCU\SOFTWARE", $HKLM_Software_32, $HKLM_Software_64]
		EndIf
		For $i = 0 To UBound($aRoot) - 1
			$j = 1
			While 1
				$InternetClient = RegEnumKey($aRoot[$i] & "\Clients\StartMenuInternet", $j)
				If @error <> 0 Then ExitLoop
				$key = $aRoot[$i] & '\Clients\StartMenuInternet\' & $InternetClient
				$var = RegRead($key & '\DefaultIcon', '')
				If StringInStr($var, $BrowserPath) Then
					$ClientKey = $key
					$ChromeProgID = RegRead($ClientKey & '\Capabilities\URLAssociations', 'http')
					ExitLoop 2
				EndIf
				$j += 1
			WEnd
		Next
	EndIf

	If $ClientKey Then
		$var = RegRead($ClientKey & '\shell\open\command', '')
		If Not StringInStr($var, @ScriptFullPath) Then
			$RegWriteError += Not RegWrite($ClientKey & '\shell\open\command', '', 'REG_SZ', '"' & @ScriptFullPath & '"')
		EndIf
	EndIf

	If Not $ChromeProgID Then $ChromeProgID = FindChromeProgID($BrowserPath)
	If $ChromeProgID Then
		$var = RegRead('HKCR\' & $ChromeProgID & '\shell\open\command', '')
		If Not StringInStr($var, @ScriptFullPath) Then
			RegWrite('HKCR\' & $ChromeProgID & '\shell\open\ddeexec', '', 'REG_SZ', '')
			RegDelete('HKCR\' & $ChromeProgID & '\shell\open\command', 'DelegateExecute')
			$RegWriteError += Not RegWrite('HKCR\' & $ChromeProgID & '\shell\open\command', '', 'REG_SZ', '"' & @ScriptFullPath & '" -- "%1"')
		EndIf
		If Not $fReg[5][1] Then
			$fReg[5][1] = $ChromeProgID
			$fReg[5][2] = _WinAPI_RegOpenKey($fReg[5][0], $fReg[5][1], $KEY_NOTIFY)
		EndIf
	EndIf

	Local $aUrlAsso[3] = ['ftp', 'http', 'https']
	For $i = 0 To 2
		$var = RegRead('HKCR\' & $aUrlAsso[$i] & '\DefaultIcon', '')
		If StringInStr($var, $BrowserPath) Then
			$var = RegRead('HKCR\' & $aUrlAsso[$i] & '\shell\open\command', '')
			If Not StringInStr($var, @ScriptFullPath) Then
				RegWrite('HKCR\' & $aUrlAsso[$i] & '\shell\open\ddeexec', '', 'REG_SZ', '')
				RegDelete('HKCR\' & $aUrlAsso[$i] & '\shell\open\command', 'DelegateExecute')
				$RegWriteError += Not RegWrite('HKCR\' & $aUrlAsso[$i] & '\shell\open\command', '', 'REG_SZ', '"' & @ScriptFullPath & '" -- "%1"')
			EndIf
		EndIf
	Next

	If $RegWriteError And Not _IsUACAdmin() And @extended Then
		If @Compiled Then
			ShellExecute(@ScriptName, "-SetDefaultGlobal", @ScriptDir, "runas")
		Else
			ShellExecute(@AutoItExe, '"' & @ScriptFullPath & '" -SetDefaultGlobal', @ScriptDir, "runas")
		EndIf
	EndIf
EndFunc   ;==>CheckChromeDefaultBrowser

Func FindChromeProgID($BrowserPath)
	Local $i, $id, $var
	RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts", "")
	If @error <> 1 Then
		For $i = 0 To UBound($aChromeFileAsso) - 1
			$id = RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\" & $aChromeFileAsso[$i] & "\UserChoice", "Progid")
			If $id Then
				$var = RegRead("HKCR\" & $id & "\DefaultIcon", "")
				If StringInStr($var, $BrowserPath) Then Return $id
			EndIf
		Next
	EndIf

	For $i = 0 To UBound($aChromeFileAsso) - 1
		$id = RegRead("HKCR\" & $aChromeFileAsso[$i], "")
		$var = RegRead("HKCR\" & $id & "\DefaultIcon", "")
		If StringInStr($var, $BrowserPath) Then Return $id
	Next

	RegRead("HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations", "")
	If @error <> 1 Then
		For $i = 0 To UBound($aChromeUrlAsso) - 1
			$id = RegRead("HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\" & $aChromeUrlAsso[$i] & "\UserChoice", "Progid")
			If $id Then
				$var = RegRead("HKCR\" & $id & "\DefaultIcon", "")
				If StringInStr($var, $BrowserPath) Then Return $id
			EndIf
		Next
	EndIf

	Return ""
EndFunc   ;==>FindChromeProgID

Func UpdateAddonStartup()
	Local $AddonStartupJsonPath, $AddonStartupLz4Path

	$AddonStartupLz4Path = $ProfileDir & "\addonStartup.json.lz4"
	$AddonStartupJsonPath = $ProfileDir & "\addonStartup.json"

	If FileExists($AddonStartupLz4Path) Then
		Local $fileOpen = FileOpen($AddonStartupLz4Path, $FO_BINARY)
		If $fileOpen <> -1 Then
			Local $packedContent = FileRead($fileOpen)
			FileClose($fileOpen)

			Local $rawContent = _MozLz4_Decompress($packedContent)
			Local $rawContentError = @error
			If $rawContentError = 0 Then
				Local $jsonContent = BinaryToString($rawContent, 4)
				$jsonContent = ReplaceJarPath($jsonContent)
				$packedContent = _MozLz4_Compress(StringToBinary($jsonContent, 4))
				Local $packedContentError = @error
				If $packedContentError = 0 Then
					$fileOpen = FileOpen($AddonStartupLz4Path, $FO_BINARY + $FO_OVERWRITE)
					If $fileOpen <> -1 Then
						FileWrite($fileOpen, $packedContent)
						FileClose($fileOpen)
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

	If FileExists($AddonStartupJsonPath) Then
		FileDelete($AddonStartupJsonPath)
	EndIf
EndFunc   ;==>UpdateAddonStartup

; 替换 jar 文件路径
Func ReplaceJarPath($content)
	Local $matches = StringRegExp($content, 'jar:file[^"]+', $STR_REGEXPARRAYGLOBALMATCH)
	For $i = 0 To UBound($matches) - 1
		; 替换有所文件地址
		Local $prevPath = $matches[$i];
		Local $tempPath = StringReplace($prevPath, "jar:file:///", "")
		$tempPath = StringReplace($tempPath, "!/", "")
		Local $dir, $name, $newPath = ""
		SplitPath($tempPath, $dir, $name, "/")
		If (_StringEndsWith($dir, "/browser/features")) Then
			$newPath = "jar:file:///" & $BrowserDirectory & "/browser/features/" & $name & "!/";
		EndIf
		If (_StringEndsWith($dir, "/extensions")) Then
			$newPath = "jar:file:///" & $ProfileDir & "/extensions/" & $name & "!/";
		EndIf
		If $newPath <> "" Then
			$newPath = StringReplace($newPath, "\", "/")
			$content = StringReplace($content, $prevPath, $newPath)
		EndIf
	Next
	Return $content
EndFunc   ;==>ReplaceJarPath

Func UpdateExtensionsJson()
	Local $extensions
	$extensions = $ProfileDir & "\" & "extensions.json";
	If FileExists($extensions) Then
		Local $fileOpen, $fileContent, $matches
		$fileOpen = FileOpen($extensions, $FO_READ)
		If $fileOpen <> -1 Then
			$fileContent = FileRead($fileOpen)
			FileClose($fileOpen)
			$fileContent = ReplaceLocalPath($fileContent)
			$fileOpen = FileOpen($extensions, $FO_OVERWRITE)
			If $fileOpen <> -1 Then
				FileWrite($fileOpen, $fileContent)
				FileClose($fileOpen)
			EndIf
		EndIf
	EndIf
EndFunc   ;==>UpdateExtensionsJson

Func ReplaceLocalPath($content)
	Local $matches = StringRegExp($content, '"path":"[^"]+', $STR_REGEXPARRAYGLOBALMATCH)
	For $i = 0 To UBound($matches) - 1
		Local $prevPath = $matches[$i];
		$prevPath = StringReplace($prevPath, '"path":"', '')
		$prevPath = StringReplace($prevPath, '\\', '\')
		Local $dir, $name, $newPath = ""
		SplitPath($prevPath, $dir, $name, "\")
		If (_StringEndsWith($dir, "\browser\features")) Then
			$newPath = $BrowserDirectory & "\browser\features\" & $name;
		EndIf
		If (_StringEndsWith($dir, "\extensions")) Then
			$newPath = $ProfileDir & "\extensions\" & $name;
		EndIf
		If $newPath <> "" Then
			$prevPath = StringReplace($prevPath, "\", "\\")
			$newPath = StringReplace($newPath, "\", "\\")
			$content = StringReplace($content, "\\\\", "\\")
			$content = StringReplace($content, $prevPath, $newPath)
		EndIf
	Next
	Return $content
EndFunc   ;==>ReplaceLocalPath

Func GetEffectiveGithubDirectMirror()
	If _DownloadToolsUsesProxy() Then Return ""
	Return $GithubDirectMirror
EndFunc   ;==>GetEffectiveGithubDirectMirror

Func GetEffectiveGithubJsDelivrMirror()
	If _DownloadToolsUsesProxy() Then Return ""
	Return $GithubJsDelivrMirror
EndFunc   ;==>GetEffectiveGithubJsDelivrMirror

Func GetProxyTypeLabel($Value)
	Switch StringLower($Value)
		Case "http"
			Return _t("ProxyTypeHttp", "HTTP 代理")
		Case "socks5"
			Return _t("ProxyTypeSocks5", "SOCKS5 代理")
	EndSwitch
	Return _t("ProxyTypeDirect", "直接连接")
EndFunc   ;==>GetProxyTypeLabel

Func GetProxyTypeComboData()
	Return GetProxyTypeLabel("direct") & "|" & GetProxyTypeLabel("http") & "|" & GetProxyTypeLabel("socks5")
EndFunc   ;==>GetProxyTypeComboData

Func GetSelectedProxyType()
	Local $Label = GUICtrlRead($idProxyType)
	If $Label = GetProxyTypeLabel("http") Then Return "http"
	If $Label = GetProxyTypeLabel("socks5") Then Return "socks5"
	Return "direct"
EndFunc   ;==>GetSelectedProxyType

Func RefreshNetworkControlsState()
	If Not $idProxyType Then Return
	Local $ProxyState = $GUI_DISABLE
	If GetSelectedProxyType() <> "direct" Then $ProxyState = $GUI_ENABLE
	GUICtrlSetState($idProxyServer, $ProxyState)
	GUICtrlSetState($idProxyPort, $ProxyState)
	Local $ThreadState = $GUI_ENABLE
	If Not _DownloadToolsHasCurl() Then
		$ThreadState = $GUI_DISABLE
		GUICtrlSetData($idDownloadThreads, 1)
	EndIf
	GUICtrlSetState($idDownloadThreads, $ThreadState)
	GUICtrlSetState($idDownloadThreadsUpDown, $ThreadState)
EndFunc   ;==>RefreshNetworkControlsState

Func Settings()
	$DefaultProfDir = GetSystemProfileSourceDir($BrowserType, "release")

	Opt("ExpandEnvStrings", 0)
	$hSettings = GUICreate(_t("AppTitle", "{AppName} - 打造自己的便携浏览器"), 500, 580)
	GUISetOnEvent($GUI_EVENT_CLOSE, "ExitApp")
	GUICtrlCreateLabel(_t("AppCopyright", "{AppName} by Ryan <github-benzBrake@woai.ru>"), 5, 10, 490, -1, $SS_CENTER)
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetColor(-1, 0x0000FF)
	GUICtrlSetTip(-1, _t("ClickToOpenPublishPage", "点击打开 {AppName} 主页"))
	GUICtrlSetOnEvent(-1, "Website")
	GUICtrlCreateLabel(_t("AppOriginalCopyright", "原版 by 甲壳虫"), 5, 30, 490, -1, $SS_CENTER)
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetColor(-1, 0x0000FF)
	GUICtrlSetTip(-1, _t("ClickToOpenOriginalPage", "点击打开甲壳虫原版主页"))
	GUICtrlSetOnEvent(-1, "OriginalWebsite")

	;常规（自适应流式布局：按文案实测宽度排布，字母语言长文案自动换行）
	GUICtrlCreateTab(5, 50, 490, 470)
	GUICtrlCreateTabItem(_t("General", "常规"))
	_ALInit($hSettings)

	Local $iContentLeft = 20, $iContentRight = 475, $yGeneral = 80

	Local $grpBrowserFiles = GUICtrlCreateGroup(_t("BrowserFiles", "浏览器程序文件"), 10, $yGeneral, 480, 24)
	Local $aIt1[10]
	$aIt1[0] = _ALIt($AL_LABEL, _t("BrowserPath", "浏览器路径"))
	$aIt1[1] = _ALIt($AL_EDIT, $BrowserPath, 240)
	$aIt1[2] = _ALIt($AL_BUTTON, _t("Browse", "浏览"))
	$aIt1[3] = _ALIt($AL_NEWLINE)
	$aIt1[4] = _ALIt($AL_LABEL, _t("BrowserType", "浏览器"))
	$aIt1[5] = _ALIt($AL_COMBO, "", 150)
	$aIt1[6] = _ALIt($AL_NEWLINE)
	$aIt1[7] = _ALIt($AL_LABEL, _t("UpdateChannel", "更新通道"))
	$aIt1[8] = _ALIt($AL_COMBO, "", 120)
	$aIt1[9] = _ALIt($AL_CHECK, _t("BrowserAutoUpdate", " 自动更新"))
	Local $aId1[0]
	Local $iRow1End = 0
	Local $hGen1 = _ALFlow($aIt1, $iContentLeft, $yGeneral + 18, $iContentRight, $aId1, $iRow1End)

	$idBrowserPath = $aId1[1]
	GUICtrlSetTip($idBrowserPath, _t("BrowserExecutablePath", "浏览器主程序路径"))
	GUICtrlSetOnEvent($idBrowserPath, "OnBrowserPathChange")
	GUICtrlSetTip($aId1[2], _t("ChoosePortableBrowser", "选择便携版浏览器主程序"))
	GUICtrlSetOnEvent($aId1[2], "SelectBrowserExecutable")

	$idBrowserType = $aId1[5]
	GUICtrlSetData($idBrowserType, GetBrowserTypeComboData(), GetBrowserTypeLabel($BrowserType))
	GUICtrlSetOnEvent($idBrowserType, "ChangeBrowserType")

	$idChannel = $aId1[8]
	GUICtrlSetOnEvent($idChannel, "ChangeChannel")

	$idAllowBrowserUpdate = $aId1[9]
	If $AllowBrowserUpdate Then
		GUICtrlSetState($idAllowBrowserUpdate, $GUI_CHECKED)
	EndIf

	Local $aIt1b[5]
	$aIt1b[0] = _ALIt($AL_LABEL, _t("BrowserBitness", "浏览器位数："))
	$aIt1b[1] = _ALIt($AL_COMBO, "", 120)
	$aIt1b[2] = _ALIt($AL_NEWLINE)
	$aIt1b[3] = _ALIt($AL_LABEL, _t("CheckBrowserUpdate", "检查浏览器更新："))
	$aIt1b[4] = _ALIt($AL_COMBO, "", 130)
	Local $aId1b[0]
	Local $yGen1b = $yGeneral + 18 + $hGen1 + 6
	Local $iRow1bEnd = 0
	Local $hGen1b = _ALFlow($aIt1b, $iContentLeft, $yGen1b, $iContentRight, $aId1b, $iRow1bEnd)

	; 立即下载：位数行行尾右对齐（位数行只有位数一组控件，各语言下右端都有空位）
	Local $iDownloadNowW = _ALMeasure(_t("DownloadNow", "立即下载")) + 24
	$idBrowserDownloadNow = GUICtrlCreateButton(_t("DownloadNow", "立即下载"), $iContentRight - $iDownloadNowW, $yGen1b + 1, $iDownloadNowW, 24)
	GUICtrlSetOnEvent($idBrowserDownloadNow, "DownloadBrowser")
	GUICtrlSetState($idBrowserDownloadNow, $GUI_HIDE)

	$idBrowserBitness = $aId1b[1]
	GUICtrlSetData($idBrowserBitness, "x64|x86|arm64", "x64")
	GUICtrlSetState($idBrowserBitness, $GUI_DISABLE)

	$idBrowserUpdateCheckMode = $aId1b[4]
	GUICtrlSetData($idBrowserUpdateCheckMode, GetBrowserUpdateCheckModeComboData(), GetBrowserUpdateCheckModeLabel($BrowserUpdateCheckMode))
	GUICtrlSetOnEvent($idBrowserUpdateCheckMode, "ChangeBrowserUpdateCheckMode")

	; 版本行：最新版本 / 当前版本 各占一半行宽
	Local $iHalfW = Int(($iContentRight - $iContentLeft) / 2)
	Local $yVerRow = $yGen1b + $hGen1b + 2
	Local $sLatestLabel = _t("LatestVersion", "最新版本：")
	Local $iLatestLabelW = _ALMeasure($sLatestLabel)
	GUICtrlCreateLabel($sLatestLabel, $iContentLeft, $yVerRow + 5, $iLatestLabelW + 2, 17)
	$idBrowserDownloadLink = GUICtrlCreateLabel(_t("BrowserDownloadAddress", "下载地址"), $iContentLeft + $iLatestLabelW + 4, $yVerRow + 5, $iHalfW - $iLatestLabelW - 8, 17)
	GUICtrlSetColor($idBrowserDownloadLink, 0x0000FF)
	GUICtrlSetCursor($idBrowserDownloadLink, 0)
	GUICtrlSetOnEvent($idBrowserDownloadLink, "DownloadBrowser")
	Local $sCurrentLabel = _t("CurrentVersion", "当前版本：")
	Local $iCurrentLabelW = _ALMeasure($sCurrentLabel)
	$idCurrentVersionCaption = GUICtrlCreateLabel($sCurrentLabel, $iContentLeft + $iHalfW, $yVerRow + 5, $iCurrentLabelW + 2, 17)
	$idCurrentBrowserVersion = GUICtrlCreateLabel("-", $iContentLeft + $iHalfW + $iCurrentLabelW + 4, $yVerRow + 5, $iHalfW - $iCurrentLabelW - 8, 17)
	Local $hGen1c = $hGen1b + 2 + 28

	GUICtrlSetPos($grpBrowserFiles, 10, $yGeneral, 480, 18 + $hGen1 + 6 + $hGen1c + 12)

	; 浏览器用户数据文件
	Local $yProfile = $yGeneral + 18 + $hGen1 + 6 + $hGen1c + 12 + 10
	Local $grpProfileFiles = GUICtrlCreateGroup(_t("ProfileFiles", "浏览器用户数据文件"), 10, $yProfile, 480, 24)
	Local $aIt2[3]
	$aIt2[0] = _ALIt($AL_LABEL, _t("ProfileDirectory", "配置文件夹"))
	$aIt2[1] = _ALIt($AL_EDIT, $ProfileDir, 240)
	$aIt2[2] = _ALIt($AL_BUTTON, _t("Browse", "浏览"))
	Local $aId2[0]
	Local $iRow2End = 0
	Local $hGen2 = _ALFlow($aIt2, $iContentLeft, $yProfile + 18, $iContentRight, $aId2, $iRow2End)
	$idProfileDir = $aId2[1]
	GUICtrlSetTip($idProfileDir, _t("ProfileDirectoryTooltip", "浏览器配置文件夹"))
	GUICtrlSetTip($aId2[2], _t("ChooseProfileDirectory", "指定浏览器配置文件夹"))
	GUICtrlSetOnEvent($aId2[2], "GetProfileDir")
	Local $yExtract = $yProfile + 18 + $hGen2 + 2
	$idCopyProfile = GUICtrlCreateCheckbox(_t("ExtractProfileFromSystem", " 从系统中提取浏览器配置文件"), $iContentLeft, $yExtract, $iContentRight - $iContentLeft, 20)
	GUICtrlSetPos($grpProfileFiles, 10, $yProfile, 480, 18 + $hGen2 + 2 + 22 + 8)

	; 语言与运行选项
	Local $yLang = $yProfile + 18 + $hGen2 + 2 + 22 + 8 + 10
	Local $grpGeneral = GUICtrlCreateGroup(_t("RunFirefoxSettingsGroup", "RunFirefox 设置"), 10, $yLang, 480, 24)
	Local $aIt3[2]
	$aIt3[0] = _ALIt($AL_LABEL, _t("UILanguage", "显示语言/Language"))
	$aIt3[1] = _ALIt($AL_COMBO, "", 110)
	Local $aId3[0]
	Local $iRow3End = 0
	Local $hGen3 = _ALFlow($aIt3, $iContentLeft, $yLang + 14, $iContentRight, $aId3, $iRow3End)
	$idLanguage = $aId3[1]
	$sLang = '简体中文'
	If _ItemExists($LANGUAGES, $LANGUAGE) Then
		$sLang = _Item($LANGUAGES, $LANGUAGE)
	EndIf
	$sLangEnum = _ArrayToString(_GetItems($LANGUAGES))
	GUICtrlSetData(-1, $sLangEnum, $slang)
	GUICtrlSetOnEvent(-1, "ChangeLanguage")

	Local $yNotify = $yLang + 14 + $hGen3 + 2
	$idAppUpdateCheckEnabled = GUICtrlCreateCheckbox(_t("NoticeMeWhenNewVersionPublished", " {AppName} 发布新版时通知我"), $iContentLeft, $yNotify, $iContentRight - $iContentLeft, 20)
	If $AppUpdateCheckEnabled Then
		GUICtrlSetState($idAppUpdateCheckEnabled, $GUI_CHECKED)
	EndIf
	$idBackgroundModeEnabled = _ALCreateWrapCheckbox(_t("KeepRunFirefoxRunning", " {AppName} 在后台运行直至浏览器退出"), $iContentLeft, $yNotify + 24, $iContentRight - $iContentLeft)
	GUICtrlSetOnEvent($idBackgroundModeEnabled, "OnBackgroundModeChange")
	If $BackgroundModeEnabled Then
		GUICtrlSetState($idBackgroundModeEnabled, $GUI_CHECKED)
	EndIf
	Local $hGen3b = 24 + 20 ; 间距 + 复选框单行高度
	If _ALMeasure(_t("KeepRunFirefoxRunning", " {AppName} 在后台运行直至浏览器退出")) + 20 > $iContentRight - $iContentLeft Then $hGen3b = 24 + 34
	GUICtrlSetPos($grpGeneral, 10, $yLang, 480, 14 + $hGen3 + 2 + $hGen3b + 10)

	; 高级
	GUICtrlCreateTabItem(_t("Advanced", "高级"))
	GUICtrlCreateGroup(_t("CacheSettings", "缓存设置"), 10, 80, 480, 120)
	_ALCreateWrapLabel(_t("PluginsDirectory", "插件目录"), 20, 103, 116)
	$idCustomPluginsDir = GUICtrlCreateEdit($CustomPluginsDir, 140, 103, 270, 20, $ES_AUTOHSCROLL)
	GUICtrlSetTip(-1, _t("PluginsDirectoryTooltip", "浏览器插件目录\n空白=默认位置"))
	$idGetPluginsDir = GUICtrlCreateButton(_t("Browse", "浏览"), 420, 103, 60, 22)
	GUICtrlSetTip(-1, _t("SpecifyPluginsDirectoryTooltip", "选择浏览器插件目录"))
	GUICtrlSetOnEvent(-1, "GetPluginsDir")

	_ALCreateWrapLabel(_t("CacheDirectory", "缓存位置"), 20, 133, 116)
	$idCustomCacheDir = GUICtrlCreateEdit($CustomCacheDir, 140, 133, 270, 20, $ES_AUTOHSCROLL)
	GUICtrlSetTip(-1, _t("CacheDirectoryTooltip", "浏览器缓存位置\n空白=默认位置"))
	$idGetCacheDir = GUICtrlCreateButton(_t("Browse", "浏览"), 420, 133, 60, 22)
	GUICtrlSetTip(-1, _t("SpecifyCacheDirectoryTooltip", "选择浏览器缓存文件夹"))
	GUICtrlSetOnEvent(-1, "GetCacheDir")

	_ALCreateWrapLabel(_t("CacheSize", "缓存大小"), 20, 163, 116)
	$idCacheSize = GUICtrlCreateEdit($CacheSize, 140, 163, 60, 20, BitOR($ES_NUMBER, $ES_AUTOHSCROLL))
	GUICtrlSetTip(-1, _t("CacheSizeTooltip", "缓存大小\n空白=默认大小"))
	GUICtrlCreateLabel("MB", 215, 168, 35, 20)
	$idCacheSizeSmart = _ALCreateWrapCheckbox(_t("CacheSizeControl", " 自动控制缓存大小"), 250, 156, 225)
	If $CacheSizeSmart Then GUICtrlSetState(-1, $GUI_CHECKED)

	; CDP 帮助文案按实测宽度计算行数：字母语言可能需要 3 行
	Local $iCdpHelpH = Ceiling((_ALMeasure(_t("ChromiumDebugPortConflictHelp", "启用后会自动添加 CDP 参数，请勿在下方命令行参数中重复设置调试端口或调试管道。")) + 459) / 460) * 14
	If $iCdpHelpH < 28 Then $iCdpHelpH = 28

	; CDP 帮助文案换三行时，Chromium 设置分组框同步加高
	GUICtrlCreateGroup(_t("ChromiumSettings", "Chromium设置"), 10, 210, 480, 125 + $iCdpHelpH - 28)
	$idChromiumGoogleApiImport = GUICtrlCreateButton(_t("ImportGoogleApi", "导入GoogleAPI"), 20, 233, 140, 22)
	GUICtrlSetOnEvent(-1, "ImportChromiumGoogleApi")
	GUICtrlSetTip(-1, _t("ImportGoogleApiTooltip", "导入GoogleAPI密钥后，Chromium 才能登录 Google 账号"))
	$idChromiumGoogleApiSuppress = GUICtrlCreateButton(_t("SuppressGoogleApiWarning", "清除GoogleAPI提示"), 180, 233, 140, 22)
	GUICtrlSetOnEvent(-1, "SuppressChromiumGoogleApiWarning")
	GUICtrlSetTip(-1, _t("SuppressGoogleApiWarningTooltip", "不导入GoogleAPI密钥，只清除缺少 Google API 密钥提示"))
	$idChromiumGoogleApiClear = GUICtrlCreateButton(_t("ClearGoogleApi", "清除GoogleAPI"), 340, 233, 140, 22)
	GUICtrlSetOnEvent(-1, "ClearChromiumGoogleApi")
	GUICtrlSetTip(-1, _t("ClearGoogleApiTooltip", "缺少GoogleAPI密钥会导致 Chromium 不能登录 Google 账号"))
	$idChromiumDebugPortEnabled = GUICtrlCreateCheckbox(_t("EnableChromiumDebugPort", " 启用自定义 CDP 调试端口"), 20, 268, 230, 20)
	GUICtrlSetOnEvent(-1, "RefreshChromiumDebugPortState")
	If $ChromiumDebugPortEnabled Then GUICtrlSetState(-1, $GUI_CHECKED)
	$idChromiumDebugPortLabel = GUICtrlCreateLabel(_t("ChromiumDebugPort", "端口"), 275, 273, 45, 20)
	$idChromiumDebugPort = GUICtrlCreateInput($ChromiumDebugPort, 325, 268, 80, 20, BitOR($ES_NUMBER, $ES_AUTOHSCROLL))
	GUICtrlSetTip(-1, _t("ChromiumDebugPortTooltip", "CDP 远程调试端口，范围为 1-65535。"))
	GUICtrlCreateLabel(_t("ChromiumDebugPortConflictHelp", "启用后会自动添加 CDP 参数，请勿在下方命令行参数中重复设置调试端口或调试管道。"), 20, 298, 460, $iCdpHelpH)
	GUICtrlSetColor(-1, 0x666666)

	GUICtrlCreateLabel(_t("CommandLineArguments", "命令行参数"), 20, 345 + $iCdpHelpH - 28, -1, 20)
	$idParams = GUICtrlCreateEdit("", 20, 365 + $iCdpHelpH - 28, 460, 50, BitOR($ES_WANTRETURN, $WS_VSCROLL, $ES_AUTOVSCROLL))
	If $Params <> "" Then
		GUICtrlSetData(-1, StringReplace($Params, " -", @CRLF & "-"))
	EndIf
	GUICtrlSetTip(-1, _t("CommandLineArgumentsTooltip", "浏览器命令行参数，每行写一个参数。\n支持 %TEMP% 等环境变量，\n另外，%APP% 代表 RunFirefox 所在目录"))

	; 网络
	GUICtrlCreateTabItem(_t("NetworkTab", "网络"))
	GUICtrlCreateGroup(_t("NetworkSettings", "网络设置"), 10, 80, 480, 180)
	GUICtrlCreateLabel(_t("DownloadThreads", "下载线程数（1-10）："), 20, 108, 160, 20)
	$idDownloadThreads = GUICtrlCreateInput($DownloadThreads, 185, 103, 55, 22, $ES_NUMBER)
	$idDownloadThreadsUpDown = GUICtrlCreateUpdown($idDownloadThreads, $UDS_ALIGNRIGHT)
	GUICtrlSetLimit($idDownloadThreadsUpDown, 10, 1)
	GUICtrlCreateLabel(_t("ProxyType", "代理类型："), 20, 143, 160, 20)
	$idProxyType = GUICtrlCreateCombo("", 185, 138, 150, 24, $CBS_DROPDOWNLIST)
	GUICtrlSetData($idProxyType, GetProxyTypeComboData(), GetProxyTypeLabel($ProxyType))
	GUICtrlSetOnEvent($idProxyType, "RefreshNetworkControlsState")
	GUICtrlCreateLabel(_t("ProxyServer", "代理服务器："), 20, 178, 160, 20)
	$idProxyServer = GUICtrlCreateInput($ProxyServer, 185, 173, 150, 22, $ES_AUTOHSCROLL)
	GUICtrlCreateLabel(_t("ProxyPort", "代理端口："), 355, 178, 70, 20)
	Local $ProxyPortText = ""
	If $ProxyPort > 0 Then $ProxyPortText = $ProxyPort
	$idProxyPort = GUICtrlCreateInput($ProxyPortText, 425, 173, 55, 22, BitOR($ES_NUMBER, $ES_AUTOHSCROLL))
	$idNetworkCurlHint = GUICtrlCreateLabel(_t("CurlRequiredForThreads", "多线程下载需要 curl.exe；未检测到时固定使用单线程。"), 20, 213, 450, 34)
	GUICtrlSetColor($idNetworkCurlHint, 0x666666)
	If _DownloadToolsHasCurl() Then GUICtrlSetState($idNetworkCurlHint, $GUI_HIDE)
	RefreshNetworkControlsState()

	; Chrome++
	GUICtrlCreateTabItem(_t("ChromePlusTab", "Chrome++"))
	$idChromePlusHint = GUICtrlCreateLabel("", 20, 82, 460, 34)
	$idChromePlusConfigFileCaption = _ALCreateWrapLabel(_t("ChromePlusConfigFile", "配置文件"), 20, 117, 115)
	$idChromePlusConfigPath = GUICtrlCreateEdit("", 145, 117, 170, 20, BitOR($ES_AUTOHSCROLL, $ES_READONLY))
	$idChromePlusDownloadPatch = GUICtrlCreateButton(_t("DownloadChromePlusPatch", "下载并安装 Chrome++"), 325, 117, 155, 22)
	GUICtrlSetOnEvent(-1, "DownloadChromePlusPatchFromSettings")

	$idChromePlusCurrentCaption = _ALCreateWrapLabel(_t("CurrentVersion", "当前版本："), 20, 146, 115)
	$idChromePlusCurrentVersion = GUICtrlCreateLabel("-", 145, 146, 170, 20)
	$idChromePlusLatestCaption = _ALCreateWrapLabel(_t("LatestVersion", "最新版本："), 250, 146, 80)
	$idChromePlusLatestVersion = GUICtrlCreateLabel("-", 335, 146, 145, 20)

	$idChromePlusDoubleClickClose = GUICtrlCreateCheckbox(_t("ChromePlusDoubleClickClose", "双击关闭标签页"), 20, 178, 200, 20)
	$idChromePlusRightClickClose = GUICtrlCreateCheckbox(_t("ChromePlusRightClickClose", "右键关闭标签页"), 250, 178, 200, 20)
	$idChromePlusKeepLastTab = GUICtrlCreateCheckbox(_t("ChromePlusKeepLastTab", "保留最后一个标签页"), 20, 202, 200, 20)
	$idChromePlusWheelTab = GUICtrlCreateCheckbox(_t("ChromePlusWheelTab", "滚轮切换标签页"), 250, 202, 200, 20)
	$idChromePlusWheelTabWhenPressRButton = GUICtrlCreateCheckbox(_t("ChromePlusWheelTabWhenPressRButton", "按住右键时滚轮切换标签页"), 20, 226, 220, 20)
	$idChromePlusOpenUrlNewTab = GUICtrlCreateCheckbox(_t("ChromePlusOpenUrlNewTab", "地址栏输入在新标签页打开"), 250, 226, 210, 20)
	$idChromePlusOpenBookmarkNewTab = GUICtrlCreateCheckbox(_t("ChromePlusOpenBookmarkNewTab", "书签在新标签页打开"), 20, 250, 200, 20)
	$idChromePlusNewTabDisable = GUICtrlCreateCheckbox(_t("ChromePlusDisableNewTab", "新标签页时禁用上两项"), 250, 250, 200, 20)
	GUICtrlSetOnEvent($idChromePlusNewTabDisable, "RefreshChromePlusNewTabDisableNameState")
	$idChromePlusHoverTab = GUICtrlCreateCheckbox(_t("ChromePlusHoverTab", "鼠标悬停激活标签页"), 20, 274, 230, 20)
	GUICtrlSetOnEvent($idChromePlusHoverTab, "RefreshChromePlusHoverTabDelayState")
	$idChromePlusHoverTabDelayLabel = GUICtrlCreateLabel(_t("ChromePlusHoverTabDelay", "延迟（毫秒）"), 270, 279, 80, 20)
	$idChromePlusHoverTabDelay = GUICtrlCreateEdit("400", 355, 274, 125, 20, BitOR($ES_NUMBER, $ES_AUTOHSCROLL))
	GUICtrlSetTip($idChromePlusHoverTabDelay, _t("ChromePlusHoverTabDelayTooltip", "鼠标需在标签页上停留多久才会激活，范围为 0-5000 毫秒；无效值会使用 400 毫秒。"))

	$idChromePlusNewTabDisableNameLabel = _ALCreateWrapLabel(_t("ChromePlusDisableNewTabName", "额外匹配标题"), 20, 302, 115)
	$idChromePlusNewTabDisableName = GUICtrlCreateEdit("", 145, 302, 335, 20, $ES_AUTOHSCROLL)
	GUICtrlSetTip($idChromePlusNewTabDisableName, _t("ChromePlusDisableNewTabNameTooltip", '对应 chrome++.ini 的 new_tab_disable_name 原始值；这些标题会被额外视为新标签页。可填写多个标题，并保留英文双引号与逗号，例如 "about:blank","新建标签"'))
	; 新标签页说明按实测宽度计算行数，字母语言需要更多行
	Local $sChromePlusNewTabDisableHelp = _t("ChromePlusNewTabDisableHelp", "说明：勾选后，如果当前标签页被识别为新标签页，Chrome++ 会临时禁用上面的“地址栏输入在新标签页打开”和“书签在新标签页打开”。这样在新标签页里输入地址或打开书签时，会使用当前新标签页，而不会再额外新建标签页。\n“额外匹配标题”用于补充 Chrome++ 的内置识别列表，匹配到这些标题时也按新标签页处理。")
	Local $iChromePlusNewTabHelpH = 0
	For $sHelpLine In StringSplit($sChromePlusNewTabDisableHelp, @CRLF, 3)
		$iChromePlusNewTabHelpH += Ceiling((_ALMeasure($sHelpLine) + 459) / 460) * 14
	Next
	If $iChromePlusNewTabHelpH < 62 Then $iChromePlusNewTabHelpH = 62
	GUICtrlCreateLabel($sChromePlusNewTabDisableHelp, 20, 332, 460, $iChromePlusNewTabHelpH)
	GUICtrlSetColor(-1, 0x666666)

	; 升级提示说明按实测宽度计算行数，并整体上移收紧页尾
	Local $sChromePlusSuppressHelp = _t("ChromePlusSuppressFalseUpgradeNotificationHelp", "便携版浏览器没有更新组件，会被误报无法通过重启消除的“已过期 / 重新启动”提示；仅移除该错误提示，不影响真实更新通知。\n未安装 Chrome++ 的浏览器启动时会自动追加 --disable-features=OutdatedBuildDetector 参数。")
	Local $iChromePlusSuppressHelpH = 0
	For $sHelpLine In StringSplit($sChromePlusSuppressHelp, @CRLF, 3)
		$iChromePlusSuppressHelpH += Ceiling((_ALMeasure($sHelpLine) + 459) / 460) * 14
	Next
	If $iChromePlusSuppressHelpH < 44 Then $iChromePlusSuppressHelpH = 44
	$idChromePlusSuppressFalseUpgradeNotification = GUICtrlCreateCheckbox(_t("ChromePlusSuppressFalseUpgradeNotification", "抑制错误的“已过期”升级提示"), 20, 396 + $iChromePlusNewTabHelpH - 62, 260, 20)
	GUICtrlCreateLabel($sChromePlusSuppressHelp, 20, 418 + $iChromePlusNewTabHelpH - 62, 460, $iChromePlusSuppressHelpH)
	GUICtrlSetColor(-1, 0x666666)

	; 辅助
	GUICtrlCreateTabItem(_t("Auxiliary", "辅助"))
	GUICtrlCreateLabel(_t("RunOnBrowserStart", "浏览器启动时运行"), 20, 90, -1, 20)
	; 自动关闭复选框换行时，下方内容整体下移一行
	Local $iAuxWrapExtra = 0
	If _ALMeasure(_t("AutoCloseAfterBrowserExit", " #浏览器退出后自动关闭")) + 20 > 240 Then $iAuxWrapExtra = 14
	$idCloseStartAppsAfterBrowserExit = _ALCreateWrapCheckbox(_t("AutoCloseAfterBrowserExit", " #浏览器退出后自动关闭"), 240, 85, 240)
	If $CloseStartAppsAfterBrowserExit = 1 Then
		GUICtrlSetState($idCloseStartAppsAfterBrowserExit, $GUI_CHECKED)
	EndIf
	$idBrowserStartApps = GUICtrlCreateEdit("", 20, 110 + $iAuxWrapExtra, 410, 50, BitOR($ES_WANTRETURN, $WS_VSCROLL, $ES_AUTOVSCROLL))
	If $BrowserStartApps <> "" Then
		GUICtrlSetData(-1, StringReplace($BrowserStartApps, "||", @CRLF) & @CRLF)
	EndIf
	GUICtrlSetTip(-1, _t("RunOnBrowserStartTooltip", "浏览器启动时运行的外部程序，支持批处理、vbs文件等\n如需启动参数，可添加在程序路径之后"))
	GUICtrlCreateButton(_t("Add", "添加"), 440, 109 + $iAuxWrapExtra, 40, 22)
	GUICtrlSetTip(-1, _t("SelectExtraApp", "选择外部程序"))
	GUICtrlSetOnEvent(-1, "AddBrowserStartApp")

	GUICtrlCreateLabel(_t("RunAfterBrowserExit", "浏览器退出后运行"), 20, 190 + $iAuxWrapExtra, -1, 20)
	$idBrowserExitApps = GUICtrlCreateEdit("", 20, 210 + $iAuxWrapExtra, 410, 50, BitOR($ES_WANTRETURN, $WS_VSCROLL, $ES_AUTOVSCROLL))
	If $BrowserExitApps <> "" Then
		GUICtrlSetData(-1, StringReplace($BrowserExitApps, "||", @CRLF) & @CRLF)
	EndIf
	GUICtrlSetTip(-1, _t("RunAfterBrowserExitTooltip", "浏览器退出后运行的外部程序，支持批处理、vbs文件等\n如需启动参数，可添加在程序路径之后"))
	GUICtrlCreateButton(_t("Add", "添加"), 440, 209 + $iAuxWrapExtra, 40, 22)
	GUICtrlSetTip(-1, _t("SelectExtraApp", "选择外部程序"))
	GUICtrlSetOnEvent(-1, "AddBrowserExitApp")

	; Bosskey 说明按实测宽度计算行数，托盘复选框换行时整体下移，分组框高度随之伸缩
	Local $sBossKeyHelp = _t("BossKeyDescription", "按快捷键隐藏浏览器；再次按快捷键或点击托盘图标还原。")
	Local $iBossKeyHelpH = 0
	For $sHelpLine In StringSplit($sBossKeyHelp, @CRLF, 3)
		$iBossKeyHelpH += Ceiling((_ALMeasure($sHelpLine) + 459) / 460) * 14
	Next
	If $iBossKeyHelpH < 20 Then $iBossKeyHelpH = 20
	Local $iBossKeyTrayExtra = 0
	If _ALMeasure(_t("BossKeyHideToTray", " 隐藏到系统托盘")) + 20 > 135 Then $iBossKeyTrayExtra = 14
	GUICtrlCreateGroup(_t("BossKeySettings", "Bosskey"), 10, 285 + $iAuxWrapExtra, 480, 67 + $iBossKeyTrayExtra + $iBossKeyHelpH)
	$idBossKeyEnabled = GUICtrlCreateCheckbox(_t("EnableBossKey", " 启用 Bosskey"), 20, 310 + $iAuxWrapExtra, 130, 20)
	GUICtrlSetOnEvent(-1, "RefreshBossKeyControlsState")
	If $BossKeyEnabled Then GUICtrlSetState($idBossKeyEnabled, $GUI_CHECKED)
	GUICtrlCreateLabel(_t("BossKeyHotkey", "快捷键"), 170, 313 + $iAuxWrapExtra, 60, 20)
	$BossKeyCaptureValue = $BossKey
	$idBossKey = GUICtrlCreateInput(BossKeyToDisplay($BossKey), 235, 308 + $iAuxWrapExtra, 100, 20)
	GUICtrlSetTip(-1, _t("BossKeyHotkeyTooltip", "点击后直接按组合键；Backspace 或 Delete 清空"))
	$idBossKeyHideToTray = _ALCreateWrapCheckbox(_t("BossKeyHideToTray", " 隐藏到系统托盘"), 345, 310 + $iAuxWrapExtra, 135)
	If $BossKeyHideToTray Then GUICtrlSetState($idBossKeyHideToTray, $GUI_CHECKED)
	GUICtrlCreateLabel($sBossKeyHelp, 20, 342 + $iAuxWrapExtra + $iBossKeyTrayExtra, 460, $iBossKeyHelpH)
	SetupBossKeyHotkeyCapture()
	RefreshBossKeyControlsState()

	GUICtrlCreateTabItem("")
	GUICtrlCreateButton(_t("Confirm", "确定"), 260, 529, 70, 22)
	GUICtrlSetTip(-1, _t("ConfirmTooltip", "保存设置并启动浏览器"))
	GUICtrlSetOnEvent(-1, "ConfirmSettings")
	GUICtrlSetState(-1, $GUI_FOCUS)
	GUICtrlCreateButton(_t("Cancel", "取消"), 340, 529, 70, 22)
	GUICtrlSetTip(-1, _t("CancelTooltip", "不保存设置并退出"))
	GUICtrlSetOnEvent(-1, "ExitApp")
	GUICtrlCreateButton(_t("Apply", "应用"), 420, 529, 70, 22)
	GUICtrlSetTip(-1, _t("ApplyTooltip", "保存设置"))
	GUICtrlSetOnEvent(-1, "ApplySettings")
	$hStatus = _GUICtrlStatusBar_Create($hSettings, -1, _t("DoublieClickToOpenSettingsWindow", '双击软件目录下的 "%s.vbs" 文件可调出此窗口', $ScriptNameWithoutSuffix))
	Opt("ExpandEnvStrings", 1)

	ApplyDetectedBrowserTypeFromPath()
	UpdateBrowserChannelOptions($BrowserType, "release")
	UpdateBrowserSpecificControls()
	ShowCurrentChannel()
	UpdateCurrentBrowserVersionLabel()
	UpdateBrowserDownloadLabels(False)

	GUISetState(@SW_SHOW)
	BeginAppUpdateCheck()
	If ShouldCheckBrowserVersionNow() Then
		MarkBrowserVersionCheckStarted()
		AdlibRegister("RefreshBrowserVersionLabels", 250)
	EndIf
	While Not $SettingsConfirmed
		Sleep(100)
	WEnd
	AdlibUnRegister("RefreshBrowserVersionLabels")
	CancelAppUpdateCheck()
	CancelBrowserVersionLoad()
	CancelChromePlusVersionLoad()
	CleanupBossKeyHotkeyCapture()
	GUIDelete($hSettings)
EndFunc   ;==>Settings


Func AddBrowserStartApp()
	Local $path
	$path = FileOpenDialog(_t("ChooseExtraApp", "选择浏览器启动时需运行的外部程序"), @ScriptDir, _
			_t("ExtraAppAllFiles", "所有文件 (*.*)"), 1 + 2, "", $hSettings)
	If $path = "" Then Return
	$path = RelativePath($path)
	$BrowserStartApps = GUICtrlRead($idBrowserStartApps) & '"' & $path & '"' & @CRLF
	GUICtrlSetData($idBrowserStartApps, $BrowserStartApps)
EndFunc   ;==>AddBrowserStartApp
Func AddBrowserExitApp()
	Local $path
	$path = FileOpenDialog(_t("ChooseExtraApp", "选择浏览器启动时需运行的外部程序"), @ScriptDir, _
	_t("ExtraAppAllFiles", "所有文件 (*.*)"), 1 + 2, "", $hSettings)
	If $path = "" Then Return
	$path = RelativePath($path)
	$BrowserExitApps = GUICtrlRead($idBrowserExitApps) & '"' & $path & '"' & @CRLF
	GUICtrlSetData($idBrowserExitApps, $BrowserExitApps)
EndFunc   ;==>AddBrowserExitApp

Func SetupBossKeyHotkeyCapture()
	$BossKeyKeys = CreateBossKeyDictionary()
	$BossKeyHotkeyProc = DllCallbackRegister("BossKeyHotkeyInputProc", "lresult", "hwnd;uint;wparam;lparam")
	If @error Then Return
	$BossKeyInputWndProc = _WinAPI_SetWindowLong(GUICtrlGetHandle($idBossKey), $GWL_WNDPROC, DllCallbackGetPtr($BossKeyHotkeyProc))
EndFunc   ;==>SetupBossKeyHotkeyCapture

Func CleanupBossKeyHotkeyCapture()
	If $idBossKey And $BossKeyInputWndProc Then _WinAPI_SetWindowLong(GUICtrlGetHandle($idBossKey), $GWL_WNDPROC, $BossKeyInputWndProc)
	If $BossKeyHotkeyProc Then DllCallbackFree($BossKeyHotkeyProc)
	$BossKeyHotkeyProc = 0
	$BossKeyInputWndProc = 0
	$BossKeyKeys = 0
EndFunc   ;==>CleanupBossKeyHotkeyCapture

Func RefreshBossKeyControlsState()
	If Not $idBossKeyEnabled Then Return
	If Not IsBossKeySupportedBrowser(GetSelectedBrowserType()) Then
		GUICtrlSetState($idBossKeyEnabled, $GUI_UNCHECKED)
		GUICtrlSetState($idBossKeyEnabled, $GUI_DISABLE)
		GUICtrlSetState($idBossKey, $GUI_DISABLE)
		GUICtrlSetState($idBossKeyHideToTray, $GUI_DISABLE)
		Return
	EndIf

	GUICtrlSetState($idBossKeyEnabled, $GUI_ENABLE)
	Local $State = $GUI_DISABLE
	If GUICtrlRead($idBossKeyEnabled) = $GUI_CHECKED Then $State = $GUI_ENABLE
	GUICtrlSetState($idBossKey, $State)
	GUICtrlSetState($idBossKeyHideToTray, $State)
EndFunc   ;==>RefreshBossKeyControlsState

Func RefreshChromiumDebugPortState()
	If Not $idChromiumDebugPortEnabled Then Return
	Local $Enabled = IsChromeBrowser(GetSelectedBrowserType())
	If $Enabled Then
		GUICtrlSetState($idChromiumDebugPortEnabled, $GUI_ENABLE)
	Else
		GUICtrlSetState($idChromiumDebugPortEnabled, $GUI_DISABLE)
	EndIf
	Local $PortState = $GUI_DISABLE
	If $Enabled And GUICtrlRead($idChromiumDebugPortEnabled) = $GUI_CHECKED Then $PortState = $GUI_ENABLE
	GUICtrlSetState($idChromiumDebugPortLabel, $PortState)
	GUICtrlSetState($idChromiumDebugPort, $PortState)
EndFunc   ;==>RefreshChromiumDebugPortState

Func BossKeyHotkeyInputProc($hWnd, $iMsg, $wParam, $lParam)
	Switch $iMsg
		Case $WM_CHAR, $WM_SYSCHAR
			Return 0
		Case $WM_KEYDOWN, $WM_SYSKEYDOWN
			If $wParam = 8 Or $wParam = 46 Then
				$BossKeyCaptureValue = ""
				GUICtrlSetData($idBossKey, "")
				Return 0
			EndIf
			If $wParam = 16 Or $wParam = 17 Or $wParam = 18 Or $wParam = 91 Or $wParam = 92 Then Return 0

			Local $Key = _WinAPI_GetKeyNameText($lParam)
			If $Key = "" Then Return 0
			If StringLen($Key) <= 1 Then
				$Key = StringLower($Key)
			Else
				If IsObj($BossKeyKeys) And $BossKeyKeys.Exists($Key) Then
					$Key = $BossKeyKeys.Item($Key)
				Else
					$Key = StringReplace($Key, " ", "")
				EndIf
				$Key = "{" & $Key & "}"
			EndIf

			Local $DisplayPrefix = ""
			Local $HotkeyPrefix = ""
			If _IsPressed("10") Then
				$DisplayPrefix &= " + Shift"
				$HotkeyPrefix &= "+"
			EndIf
			If _IsPressed("11") Then
				$DisplayPrefix &= " + Ctrl"
				$HotkeyPrefix &= "^"
			EndIf
			If _IsPressed("12") Then
				$DisplayPrefix &= " + Alt"
				$HotkeyPrefix &= "!"
			EndIf
			If _IsPressed("5B") Or _IsPressed("5C") Then
				$DisplayPrefix &= " + Win"
				$HotkeyPrefix &= "#"
			EndIf
			If $DisplayPrefix = "" Then
				$DisplayPrefix = "Ctrl"
				$HotkeyPrefix = "^"
			Else
				$DisplayPrefix = StringTrimLeft($DisplayPrefix, 3)
			EndIf

			$BossKeyCaptureValue = $HotkeyPrefix & $Key
			GUICtrlSetData($idBossKey, $DisplayPrefix & " + " & $Key)
			Return 0
	EndSwitch

	If $BossKeyInputWndProc Then Return _WinAPI_CallWindowProc($BossKeyInputWndProc, $hWnd, $iMsg, $wParam, $lParam)
	Return 0
EndFunc   ;==>BossKeyHotkeyInputProc

Func BossKeyToDisplay($Hotkey)
	Local $Key = StringRegExpReplace($Hotkey, "[!+#^]+", "")
	If $Key = "" Then Return ""

	Local $Prefix = ""
	If StringInStr($Hotkey, "+") Then $Prefix &= " + Shift"
	If StringInStr($Hotkey, "^") Then $Prefix &= " + Ctrl"
	If StringInStr($Hotkey, "!") Then $Prefix &= " + Alt"
	If StringInStr($Hotkey, "#") Then $Prefix &= " + Win"
	If $Prefix = "" Then
		$Prefix = "Ctrl"
	Else
		$Prefix = StringTrimLeft($Prefix, 3)
	EndIf

	Return $Prefix & " + " & $Key
EndFunc   ;==>BossKeyToDisplay

Func CreateBossKeyDictionary()
	Local $Dictionary = ObjCreate("Scripting.Dictionary")
	$Dictionary.Add("Page Up", "PGUP")
	$Dictionary.Add("Page Down", "PGDN")
	$Dictionary.Add("Num Lock", "NUMLOCK")
	$Dictionary.Add("Caps Lock", "CAPSLOCK")
	$Dictionary.Add("Scroll Lock", "SCROLLLOCK")
	For $i = 0 To 9
		$Dictionary.Add("Num " & $i, "NUMPAD" & $i)
	Next
	$Dictionary.Add("Num *", "NUMPADMULT")
	$Dictionary.Add("Num +", "NUMPADADD")
	$Dictionary.Add("Num -", "NUMPADSUB")
	$Dictionary.Add("Num /", "NUMPADDIV")
	Return $Dictionary
EndFunc   ;==>CreateBossKeyDictionary

Func OnBrowserPathChange()
	ApplyDetectedBrowserTypeFromPath()
	ShowCurrentChannel()
	ChangeChannel()
	UpdateCurrentBrowserVersionLabel()
	UpdateBrowserSpecificControls()
EndFunc   ;==>OnBrowserPathChange

Func ApplyDetectedBrowserTypeFromPath()
	If Not $idBrowserType Then Return

	Local $DetectedBrowserType = DetectBrowserTypeFromPath(GUICtrlRead($idBrowserPath))
	If $DetectedBrowserType = "" Then Return
	If NormalizeBrowserType(GetSelectedBrowserType()) = $DetectedBrowserType Then Return

	Local $SelectedChannel = "release"
	If $idChannel Then $SelectedChannel = GUICtrlRead($idChannel)
	$BrowserType = $DetectedBrowserType
	GUICtrlSetData($idBrowserType, GetBrowserTypeComboData(), GetBrowserTypeLabel($DetectedBrowserType))
	If $idChannel Then UpdateBrowserChannelOptions($DetectedBrowserType, $SelectedChannel)
EndFunc   ;==>ApplyDetectedBrowserTypeFromPath

Func ChangeBrowserType()
	Local $NewBrowserType = GetSelectedBrowserType()
	Local $CurrentPath = StringLower(GUICtrlRead($idBrowserPath))
	If $CurrentPath = ".\firefox\firefox.exe" Or $CurrentPath = ".\zenbrowser\zen.exe" Or $CurrentPath = ".\floorp\floorp.exe" Or $CurrentPath = ".\waterfox\waterfox.exe" Or $CurrentPath = ".\librewolf\librewolf.exe" Or $CurrentPath = ".\chrome\chrome.exe" Or $CurrentPath = ".\turbo\turbo.exe" Or $CurrentPath = ".\helium\chrome.exe" Or $CurrentPath = ".\whale\whale.exe" Or $CurrentPath = ".\centbrowser\chrome.exe" Or $CurrentPath = ".\vivaldi\vivaldi.exe" Or $CurrentPath = ".\opera\opera.exe" Or $CurrentPath = ".\xunlei\xlbrowser.exe" Or $CurrentPath = ".\xunlei\xunleibrowser.exe" Or $CurrentPath = ".\ungoogled-chromium\chrome.exe" Then
		GUICtrlSetData($idBrowserPath, GetDefaultBrowserPath($NewBrowserType))
	EndIf
	$BrowserType = $NewBrowserType
	If NormalizeBrowserType($NewBrowserType) = $BrowserUngoogledChromium Then
		GUICtrlSetState($idBrowserBitness, $GUI_ENABLE)
	Else
		GUICtrlSetData($idBrowserBitness, "x64", "x64")
		GUICtrlSetState($idBrowserBitness, $GUI_DISABLE)
	EndIf
	UpdateBrowserChannelOptions($BrowserType, "release")
	UpdateCurrentBrowserVersionLabel()
	UpdateBrowserSpecificControls()
	BeginBrowserVersionLoad()
EndFunc   ;==>ChangeBrowserType

Func ChangeChannel()
	RefreshCopyProfileState()
	BeginBrowserVersionLoad()
EndFunc   ;==>ChangeChannel

Func ChangeBrowserUpdateCheckMode()
	$BrowserUpdateCheckMode = GetSelectedBrowserUpdateCheckMode()
	If $BrowserUpdateCheckMode = "never" Then
		CancelBrowserVersionLoad()
		UpdateBrowserDownloadLabels(False)
		Return
	EndIf
	BeginBrowserVersionLoad()
EndFunc   ;==>ChangeBrowserUpdateCheckMode

Func RefreshBrowserVersionLabels()
	AdlibUnRegister("RefreshBrowserVersionLabels")
	BeginBrowserVersionLoad()
EndFunc   ;==>RefreshBrowserVersionLabels

Func ShouldCheckBrowserVersionNow()
	Local $Mode = NormalizeBrowserUpdateCheckMode($BrowserUpdateCheckMode)
	Switch $Mode
		Case "never"
			Return False
		Case "hourly"
			Return _DateDiff("h", $BrowserUpdateLastCheck, _NowCalc()) >= 1
		Case "daily"
			Return _DateDiff("d", $BrowserUpdateLastCheck, _NowCalc()) >= 1
		Case "weekly"
			Return _DateDiff("d", $BrowserUpdateLastCheck, _NowCalc()) >= 7
	EndSwitch
	Return True
EndFunc   ;==>ShouldCheckBrowserVersionNow

Func MarkBrowserVersionCheckStarted()
	$BrowserUpdateLastCheck = _NowCalc()
	IniWrite($inifile, "Settings", "BrowserUpdateLastCheck", $BrowserUpdateLastCheck)
EndFunc   ;==>MarkBrowserVersionCheckStarted

;~ Apply a staged browser update while the browser is not running (Firefox-style
;~ "update on next launch"). Failures are reported but never block the launch.
Func BrowserAutoUpdateApplyPendingInteractive()
	_BrowserAutoUpdateCleanPartialDownloads()
	Local $Result = _BrowserAutoUpdateApplyPending($BrowserPath, $BrowserType)
	If @error Then
		If $Result <> "" Then MsgBox(16, $AppName, _t("BrowserUpdateApplyFailed", "应用浏览器更新失败：\n%s", $Result))
		Return
	EndIf
	; Success stays silent so applying an update never delays the launch.
EndFunc   ;==>BrowserAutoUpdateApplyPendingInteractive

;~ Background check + confirm + download + stage for RunFirefox-managed updates.
;~ Runs only while RunFirefox stays alive (background mode) so the download is
;~ never killed by the launcher exiting.
Func BrowserAutoUpdateCheck()
	If Not ShouldCheckBrowserVersionNow() Then Return
	MarkBrowserVersionCheckStarted()
	_BrowserAutoUpdateCleanPartialDownloads()

	Local $Pending = _BrowserAutoUpdateGetPendingUpdate()
	Local $LocalVersion = _BrowserAutoUpdateGetLocalVersion($BrowserPath, $BrowserType)
	If IsArray($Pending) Then
		; A staged update is already waiting for the next launch. Drop it only
		; when the installed browser is no longer older (for example a manual
		; download already brought it up to date).
		If Not _BrowserAutoUpdateVersionIsNewer($Pending[0], $LocalVersion) Then _BrowserAutoUpdateCleanStaging()
		Return
	EndIf

	Local $Channel = $BrowserUpdateChannel
	If IsGoogleChromeBrowser($BrowserType) Then $Channel = _BrowserDownloadNormalizeChromeChannel($BrowserUpdateChannel)
	Local $LatestVersion = BrowserAutoUpdateResolveLatestVersion($BrowserType, $Channel)
	If $LatestVersion = "" Then Return

	If Not _BrowserAutoUpdateVersionIsNewer($LatestVersion, _BrowserAutoUpdateGetLocalVersion($BrowserPath, $BrowserType)) Then Return

	Local $UpdateConfirm = _t("BrowserAutoUpdateAvailable", "发现浏览器新版本：%s\n\n是否下载更新？下载完成后将在下次启动浏览器时自动应用。", $LatestVersion)
	If MsgBox(36 + 256, $AppName, $UpdateConfirm) <> 6 Then Return

	Local $Urls = _BrowserDownloadBuildUrls($BrowserType, $Channel, "win64")
	If @error Or Not IsArray($Urls) Or UBound($Urls) = 0 Then Return
	Local $TriedUrls = ""
	Local $Staged = _BrowserAutoUpdateStageUpdate($BrowserType, $Channel, $LatestVersion, $Urls, $TriedUrls)
	If Not $Staged Then
		If @error = 2 Then Return ; user cancelled the download
		Local $StageFailedDetail = _t("BrowserUpdateStageFailed", "浏览器更新包下载失败，下次检查时将重试。")
		If $TriedUrls <> "" Then $StageFailedDetail &= @CRLF & @CRLF & _t("BrowserUpdateStageFailedUrls", "已尝试的下载地址：\n%s", $TriedUrls)
		MsgBox(16, $AppName, $StageFailedDetail)
		Return
	EndIf
	MsgBox(64, $AppName, _t("BrowserUpdateStaged", "更新包已下载完成：%s\n\n下次启动浏览器时将自动应用更新。", $LatestVersion))
EndFunc   ;==>BrowserAutoUpdateCheck

;~ Resolve the latest browser version for auto-update. Chrome uses a dedicated
;~ child process (POST request to Omaha), while Brave/Whale reuse the generic
;~ InetGet-based version loader used by the settings dialog.
Func BrowserAutoUpdateResolveLatestVersion($BrowserType, $Channel)
	If IsGoogleChromeBrowser($BrowserType) Then
		Local $OutputFile = @TempDir & "\RunFirefox_BrowserAutoUpdate_" & @AutoItPID & ".tmp"
		FileDelete($OutputFile)
		Local $VersionPid = _BrowserDownloadStartChromeVersionLoadProcess($Channel, "win64", $OutputFile)
		If Not $VersionPid Then Return ""
		Local $Timer = TimerInit()
		While ProcessExists($VersionPid)
			If TimerDiff($Timer) > 60000 Then
				ProcessClose($VersionPid)
				ExitLoop
			EndIf
			Sleep(200)
		WEnd
		Local $Loaded = _BrowserDownloadLoadChromeUpdateInfoFile($Channel, $OutputFile)
		FileDelete($OutputFile)
		If Not $Loaded Then Return ""
		Return _BrowserDownloadGetChromeVersionCache($Channel)
	EndIf

	If Not _BrowserDownloadStartVersionLoad($BrowserType, $Channel, "win64") Then Return ""
	Local $Timer = TimerInit()
	Local $Result = -1
	While 1
		Local $LoadedBrowserType = "", $LoadedChannel = ""
		$Result = _BrowserDownloadPollVersionLoad($LoadedBrowserType, $LoadedChannel)
		If $Result <> 0 Then ExitLoop
		If TimerDiff($Timer) > 60000 Then
			_BrowserDownloadCancelVersionLoad()
			Return ""
		EndIf
		Sleep(200)
	WEnd
	If $Result <> 1 Then Return ""
	Return _BrowserDownloadGetLatestVersion($BrowserType, $Channel)
EndFunc   ;==>BrowserAutoUpdateResolveLatestVersion

Func UpdateBrowserDownloadLabels($LoadVersion, $Unavailable = False)
	If Not $idBrowserDownloadLink Then Return
	Local $CurrentBrowserType = GetSelectedBrowserType()
	Local $Channel = GUICtrlRead($idChannel)
	If $Channel = "default" Then $Channel = "release"

	Local $LatestVersion = ""
	If $LoadVersion Then $LatestVersion = GetLatestBrowserVersionForSettings($CurrentBrowserType, $Channel)
	If $LatestVersion <> "" Then
		GUICtrlSetData($idBrowserDownloadLink, $LatestVersion)
		UpdateBrowserDownloadNowState()
		Return
	EndIf

	If $Unavailable Then
		GUICtrlSetData($idBrowserDownloadLink, _t("BrowserVersionUnavailable", "获取失败"))
	Else
		GUICtrlSetData($idBrowserDownloadLink, _t("BrowserDownloadAddress", "下载地址"))
	EndIf
	UpdateBrowserDownloadNowState()
EndFunc   ;==>UpdateBrowserDownloadLabels

Func GetLatestBrowserVersionForSettings($CurrentBrowserType, $Channel)
	Return _BrowserDownloadGetLatestVersion($CurrentBrowserType, $Channel)
EndFunc   ;==>GetLatestBrowserVersionForSettings

Func UpdateCurrentBrowserVersionLabel()
	If Not $idCurrentBrowserVersion Then Return

	Local $BrowserPath = GetCurrentSettingsBrowserPath()
	Local $CurrentVersion = ""
	If FileExists($BrowserPath) Then
		If NormalizeBrowserType(GetSelectedBrowserType()) = $BrowserFloorp Then
			; Floorp's executable version is the bundled Gecko version (for example 153.0).
			; The Floorp version is stored in application.ini as "FloorpVersion@GeckoVersion".
			$CurrentVersion = GetFloorpInstalledVersion($BrowserPath)
			If $CurrentVersion = "" Then $CurrentVersion = ReadExecutableVersionField($BrowserPath, "FileVersion")
			If $CurrentVersion = "" Then $CurrentVersion = ReadExecutableVersionField($BrowserPath, "ProductVersion")
		ElseIf NormalizeBrowserType(GetSelectedBrowserType()) = $BrowserZen Then
			$CurrentVersion = ReadExecutableVersionField($BrowserPath, "ProductVersion")
			If $CurrentVersion = "" Then $CurrentVersion = ReadExecutableVersionField($BrowserPath, "FileVersion")
		ElseIf NormalizeBrowserType(GetSelectedBrowserType()) = $BrowserLibreWolf Then
			; LibreWolf keeps its packaging revision in ProductVersion (for example 154.0-2),
			; while FileVersion only contains the underlying Firefox milestone (154.0).
			$CurrentVersion = ReadExecutableVersionField($BrowserPath, "ProductVersion")
			If $CurrentVersion = "" Then $CurrentVersion = GetApplicationIniVersion($BrowserPath)
			If $CurrentVersion = "" Then $CurrentVersion = ReadExecutableVersionField($BrowserPath, "FileVersion")
		ElseIf NormalizeBrowserType(GetSelectedBrowserType()) = $BrowserWaterfox Then
			$CurrentVersion = _t("BrowserVersionUnavailable", "获取失败") ; Waterfox 本地版本号读取不准确，直接复用短提示
		ElseIf NormalizeBrowserType(GetSelectedBrowserType()) = $BrowserBrave Then
			$CurrentVersion = ReadExecutableVersionField($BrowserPath, "ProductVersion")
			If $CurrentVersion = "" Then $CurrentVersion = ReadExecutableVersionField($BrowserPath, "FileVersion")
			$CurrentVersion = NormalizeBraveVersionText($CurrentVersion)
		Else
			$CurrentVersion = ReadExecutableVersionField($BrowserPath, "FileVersion")
			If $CurrentVersion = "" Then $CurrentVersion = ReadExecutableVersionField($BrowserPath, "ProductVersion")
		EndIf
	EndIf
	If $CurrentVersion = "" Then $CurrentVersion = "-"
	GUICtrlSetData($idCurrentBrowserVersion, $CurrentVersion)
	UpdateBrowserDownloadNowState()
EndFunc   ;==>UpdateCurrentBrowserVersionLabel

Func UpdateBrowserDownloadNowState()
	If Not $idBrowserDownloadNow Or Not $idBrowserDownloadLink Or Not $idCurrentBrowserVersion Then Return

	Local $DisplayedLatestVersion = StringStripWS(GUICtrlRead($idBrowserDownloadLink), 3)
	Local $LatestVersion = NormalizeDisplayedVersionForCompare($DisplayedLatestVersion)
	Local $CurrentVersion = NormalizeDisplayedVersionForCompare(GUICtrlRead($idCurrentBrowserVersion))
	Local $CurrentBrowserType = NormalizeBrowserType(GetSelectedBrowserType())
	Local $Channel = GUICtrlRead($idChannel)
	If $CurrentBrowserType = $BrowserBrave Then
		$LatestVersion = NormalizeBraveVersionText($DisplayedLatestVersion)
		$CurrentVersion = NormalizeBraveVersionText(GUICtrlRead($idCurrentBrowserVersion))
	EndIf
	GUICtrlSetData($idBrowserDownloadNow, _t("DownloadNow", "立即下载"))
	If IsDisplayedBrowserVersionUnavailable($DisplayedLatestVersion) Then
		If Not HasBrowserDownloadFallback($CurrentBrowserType, $Channel) Then
			If GetBrowserDownloadPageUrl($CurrentBrowserType, $Channel) = "" Then
				GUICtrlSetState($idBrowserDownloadNow, $GUI_HIDE)
				Return
			EndIf
			GUICtrlSetData($idBrowserDownloadNow, _t("OpenDownloadPage", "打开下载页"))
		EndIf
		GUICtrlSetState($idBrowserDownloadNow, $GUI_SHOW)
	ElseIf $CurrentBrowserType = $BrowserXunlei Then
		; The official endpoint exposes a changing installer URL, not a semantic
		; version field. Keep the direct download action available whenever it loads.
		GUICtrlSetState($idBrowserDownloadNow, $GUI_SHOW)
	ElseIf $LatestVersion <> "" And ($CurrentVersion = "" Or $LatestVersion <> $CurrentVersion) Then
		GUICtrlSetState($idBrowserDownloadNow, $GUI_SHOW)
	Else
		GUICtrlSetState($idBrowserDownloadNow, $GUI_HIDE)
	EndIf
EndFunc   ;==>UpdateBrowserDownloadNowState

Func IsDisplayedBrowserVersionUnavailable($DisplayedVersion)
	Return StringLower(StringStripWS($DisplayedVersion, 3)) = StringLower(_t("BrowserVersionUnavailable", "获取失败"))
EndFunc   ;==>IsDisplayedBrowserVersionUnavailable

Func HasBrowserDownloadFallback($CurrentBrowserType, $Channel)
	Return _BrowserDownloadHasFallback($CurrentBrowserType, $Channel)
EndFunc   ;==>HasBrowserDownloadFallback

Func GetBrowserDownloadPageUrl($CurrentBrowserType, $Channel)
	Return _BrowserDownloadGetPageUrl($CurrentBrowserType, $Channel)
EndFunc   ;==>GetBrowserDownloadPageUrl

Func NormalizeDisplayedVersionForCompare($Version)
	$Version = StringLower(StringStripWS($Version, 3))
	If $Version = "" Or $Version = "-" Then Return ""
	If $Version = StringLower(_t("BrowserDownloadAddress", "下载地址")) Then Return ""
	If $Version = StringLower(_t("BrowserVersionUnavailable", "获取失败")) Then Return ""
	Local $LoadingText = StringReplace(StringLower(_t("BrowserVersionLoading", "正在读取版本 %s")), "%s", "")
	If $LoadingText <> "" And StringInStr($Version, $LoadingText) Then Return ""
	Return StringRegExpReplace($Version, "^[vV]", "")
EndFunc   ;==>NormalizeDisplayedVersionForCompare

Func NormalizeBraveVersionText($Version)
	$Version = StringStripWS($Version, 3)
	If $Version = "" Or $Version = "-" Then Return ""
	$Version = StringRegExpReplace($Version, "^[vV]", "")

	; Brave executable versions include the Chromium major as a leading field
	; (for example 150.1.92.134), while release tags use 1.92.134[-100].
	Local $Match = StringRegExp($Version, "^[0-9]+[.]([0-9]+[.][0-9]+[.][0-9]+)$", 1)
	If Not @error And IsArray($Match) Then Return $Match[0]
	$Match = StringRegExp($Version, "^([0-9]+[.][0-9]+[.][0-9]+)(?:-[0-9]+)?$", 1)
	If Not @error And IsArray($Match) Then Return $Match[0]
	Return $Version
EndFunc   ;==>NormalizeBraveVersionText

Func NormalizeBrowserUpdateCheckMode($Value)
	$Value = StringLower(StringStripWS($Value, 3))
	Switch $Value
		Case "startup", "hourly", "daily", "weekly", "never"
			Return $Value
		Case "hour", "everyhour"
			Return "hourly"
		Case "day", "everyday"
			Return "daily"
		Case "week", "everyweek"
			Return "weekly"
		Case "none", "off"
			Return "never"
	EndSwitch
	Return "startup"
EndFunc   ;==>NormalizeBrowserUpdateCheckMode

Func GetBrowserUpdateCheckModeLabel($Value)
	$Value = NormalizeBrowserUpdateCheckMode($Value)
	Switch $Value
		Case "hourly"
			Return _t("CheckBrowserUpdateHourly", "每小时")
		Case "daily"
			Return _t("CheckBrowserUpdateDaily", "每天")
		Case "weekly"
			Return _t("CheckBrowserUpdateWeekly", "每周")
		Case "never"
			Return _t("CheckBrowserUpdateNever", "从不")
	EndSwitch
	Return _t("CheckBrowserUpdateOnStartup", "每次启动时")
EndFunc   ;==>GetBrowserUpdateCheckModeLabel

Func GetBrowserUpdateCheckModeByLabel($Label)
	If $Label = GetBrowserUpdateCheckModeLabel("hourly") Then Return "hourly"
	If $Label = GetBrowserUpdateCheckModeLabel("daily") Then Return "daily"
	If $Label = GetBrowserUpdateCheckModeLabel("weekly") Then Return "weekly"
	If $Label = GetBrowserUpdateCheckModeLabel("never") Then Return "never"
	Return "startup"
EndFunc   ;==>GetBrowserUpdateCheckModeByLabel

Func GetSelectedBrowserUpdateCheckMode()
	If Not $idBrowserUpdateCheckMode Then Return $BrowserUpdateCheckMode
	Return GetBrowserUpdateCheckModeByLabel(GUICtrlRead($idBrowserUpdateCheckMode))
EndFunc   ;==>GetSelectedBrowserUpdateCheckMode

Func GetBrowserUpdateCheckModeComboData()
	Return GetBrowserUpdateCheckModeLabel("startup") & "|" & GetBrowserUpdateCheckModeLabel("hourly") & "|" & GetBrowserUpdateCheckModeLabel("daily") & "|" & GetBrowserUpdateCheckModeLabel("weekly") & "|" & GetBrowserUpdateCheckModeLabel("never")
EndFunc   ;==>GetBrowserUpdateCheckModeComboData

Func BeginBrowserVersionLoad($CurrentBrowserType = "", $Channel = "")
	If Not $idBrowserDownloadLink Then Return
	If $CurrentBrowserType = "" Then $CurrentBrowserType = GetSelectedBrowserType()
	If $Channel = "" Then $Channel = GUICtrlRead($idChannel)
	If $Channel = "default" Then $Channel = "release"

	If IsBrowserVersionCached($CurrentBrowserType, $Channel) Then
		UpdateBrowserDownloadLabels(True)
		Return
	EndIf

	If _BrowserDownloadIsVersionLoadActive($CurrentBrowserType, $Channel) Then
			UpdateBrowserVersionLoadingLabel()
			Return
	EndIf
	If Not _BrowserDownloadStartVersionLoad($CurrentBrowserType, $Channel, "win64") Then
		If NormalizeBrowserType($CurrentBrowserType) = $BrowserWhale Then
			UpdateBrowserDownloadLabels(False, True)
		Else
			UpdateBrowserDownloadLabels(False)
		EndIf
		Return
	EndIf

	$BrowserVersionLoadAnim = 0
	UpdateBrowserVersionLoadingLabel()
	AdlibRegister("PollBrowserVersionLoad", 250)
EndFunc   ;==>BeginBrowserVersionLoad

Func CancelBrowserVersionLoad()
	AdlibUnRegister("PollBrowserVersionLoad")
	_BrowserDownloadCancelVersionLoad()
EndFunc   ;==>CancelBrowserVersionLoad

Func PollBrowserVersionLoad()
	UpdateBrowserVersionLoadingLabel()
	Local $LoadedBrowserType = "", $LoadedChannel = ""
	Local $Result = _BrowserDownloadPollVersionLoad($LoadedBrowserType, $LoadedChannel)
	If $Result = 0 Then Return
	AdlibUnRegister("PollBrowserVersionLoad")
	CompleteBrowserVersionLoad($LoadedBrowserType, $LoadedChannel, $Result = 1)
EndFunc   ;==>PollBrowserVersionLoad

Func CompleteBrowserVersionLoad($LoadedBrowserType, $LoadedChannel, $Loaded)
	If Not $idBrowserDownloadLink Then Return
	Local $CurrentBrowserType = GetSelectedBrowserType()
	Local $CurrentChannel = GUICtrlRead($idChannel)
	If $CurrentChannel = "default" Then $CurrentChannel = "release"
	If NormalizeBrowserType($CurrentBrowserType) <> $LoadedBrowserType Or $CurrentChannel <> $LoadedChannel Then
		BeginBrowserVersionLoad($CurrentBrowserType, $CurrentChannel)
		Return
	EndIf

	If $Loaded Then
		UpdateBrowserDownloadLabels(True)
	Else
		UpdateBrowserDownloadLabels(False, True)
		If $hStatus Then _GUICtrlStatusBar_SetText($hStatus, _t("BrowserVersionLoadFailed", "读取浏览器版本失败。"))
	EndIf
EndFunc   ;==>CompleteBrowserVersionLoad

Func UpdateBrowserVersionLoadingLabel()
	If Not $idBrowserDownloadLink Then Return
	Local $CurrentBrowserType = GetSelectedBrowserType()
	Local $Spinner = "|"
	Switch Mod($BrowserVersionLoadAnim, 4)
		Case 1
			$Spinner = "/"
		Case 2
			$Spinner = "-"
		Case 3
			$Spinner = "\"
	EndSwitch
	$BrowserVersionLoadAnim += 1
	GUICtrlSetData($idBrowserDownloadLink, _t("BrowserVersionLoading", "正在读取版本 %s", $Spinner))
EndFunc   ;==>UpdateBrowserVersionLoadingLabel

Func IsBrowserVersionCached($CurrentBrowserType, $Channel)
	Return _BrowserDownloadIsVersionCached($CurrentBrowserType, $Channel)
EndFunc   ;==>IsBrowserVersionCached

Func GetSelectedBrowserType()
	If Not $idBrowserType Then Return $BrowserType
	Return GetBrowserTypeByLabel(GUICtrlRead($idBrowserType))
EndFunc   ;==>GetSelectedBrowserType

Func DetectBrowserTypeFromPath($BrowserPath)
	$BrowserPath = StringStripWS($BrowserPath, 3)
	If $BrowserPath = "" Then Return ""

	Local $FullBrowserPath = FullPath($BrowserPath)
	Local $BrowserExe = ""
	Local $BrowserDir = ""
	SplitPath($FullBrowserPath, $BrowserDir, $BrowserExe)

	Local $BrowserExeLower = StringLower($BrowserExe)
	Local $FullBrowserPathLower = StringLower($FullBrowserPath)
	Local $Identity = GetExecutableIdentityText($FullBrowserPath)
	If StringInStr($FullBrowserPathLower, "\ungoogled-chromium\") Or StringInStr($Identity, "ungoogled chromium") Or StringInStr($Identity, "ungoogled-chromium") Then Return $BrowserUngoogledChromium

	If StringInStr($Identity, "helium") Or StringInStr($Identity, "the helium authors") Then Return $BrowserHelium
	If $BrowserExeLower = "turbo.exe" Or StringInStr($Identity, "turbo browser") Then Return $BrowserTurbo
	If $BrowserExeLower = "whale.exe" Or StringInStr($Identity, "naver whale") Or StringInStr($Identity, "whale browser") Then Return $BrowserWhale
	If $BrowserExeLower = "chrome.exe" And (StringInStr($Identity, "cent browser") Or StringInStr($Identity, "centbrowser") Or StringInStr($FullBrowserPathLower, "\centbrowser\")) Then Return $BrowserCent
	If $BrowserExeLower = "vivaldi.exe" Or StringInStr($Identity, "vivaldi") Then Return $BrowserVivaldi
	If $BrowserExeLower = "brave.exe" Or StringInStr($Identity, "brave") Then Return $BrowserBrave
	If $BrowserExeLower = "xunleibrowser.exe" Or $BrowserExeLower = "xlbrowser.exe" Or StringInStr($Identity, "xunlei browser") Or StringInStr($Identity, "迅雷浏览器") Then Return $BrowserXunlei
	If $BrowserExeLower = "zen.exe" Or StringInStr($Identity, "zen browser") Or StringInStr($Identity, "zenbrowser") Then Return $BrowserZen
	If $BrowserExeLower = "floorp.exe" Or StringInStr($Identity, "floorp") Then Return $BrowserFloorp
	If $BrowserExeLower = "waterfox.exe" Or StringInStr($Identity, "waterfox") Then Return $BrowserWaterfox
	If $BrowserExeLower = "librewolf.exe" Or StringInStr($Identity, "librewolf") Then Return $BrowserLibreWolf
	If $BrowserExeLower = "opera.exe" Or StringInStr($Identity, "opera") Then Return $BrowserOpera
	If IsChromiumBrowserIdentity($Identity, $BrowserExeLower) Then Return $BrowserChrome
	If $BrowserExeLower = "firefox.exe" Or StringInStr($Identity, "firefox") Then Return $BrowserFirefox

	Return ""
EndFunc   ;==>DetectBrowserTypeFromPath

Func GetExecutableIdentityText($ExePath)
	Local $Identity = ""
	If Not FileExists($ExePath) Then Return $Identity

	$Identity &= " " & StringLower(ReadExecutableVersionField($ExePath, "ProductName"))
	$Identity &= " " & StringLower(ReadExecutableVersionField($ExePath, "FileDescription"))
	$Identity &= " " & StringLower(ReadExecutableVersionField($ExePath, "CompanyName"))
	$Identity &= " " & StringLower(ReadExecutableVersionField($ExePath, "InternalName"))
	$Identity &= " " & StringLower(ReadExecutableVersionField($ExePath, "OriginalFilename"))
	Return $Identity
EndFunc   ;==>GetExecutableIdentityText

Func ReadExecutableVersionField($ExePath, $FieldName)
	Local $Value = FileGetVersion($ExePath, $FieldName)
	If @error Then Return ""
	Return $Value
EndFunc   ;==>ReadExecutableVersionField

Func GetFloorpInstalledVersion($BrowserPath)
	Local $BrowserDir = ""
	Local $BrowserExe = ""
	SplitPath(FullPath($BrowserPath), $BrowserDir, $BrowserExe)
	If $BrowserDir = "" Then Return ""

	; Portable and installed Floorp builds keep application.ini beside floorp.exe.
	; Accept the browser subdirectory as a fallback for packages with an extra wrapper.
	Local $ApplicationIni = $BrowserDir & Chr(92) & "application.ini"
	If Not FileExists($ApplicationIni) Then $ApplicationIni = $BrowserDir & Chr(92) & "browser" & Chr(92) & "application.ini"
	If Not FileExists($ApplicationIni) Then Return ""

	Local $Version = StringStripWS(IniRead($ApplicationIni, "App", "Version", ""), 3)
	If $Version = "" Then Return ""

	; Current Floorp releases use values such as 12.16.4@153.0. Do not expose
	; the Gecko build number as part of the browser version shown to the user.
	Local $Match = StringRegExp($Version, "^([0-9]+(?:[.][0-9]+){1,3})(?:@.*)?$", 1)
	If @error Or Not IsArray($Match) Then Return ""
	Return $Match[0]
EndFunc   ;==>GetFloorpInstalledVersion

Func GetApplicationIniVersion($BrowserPath)
	Local $BrowserDir = ""
	Local $BrowserExe = ""
	SplitPath(FullPath($BrowserPath), $BrowserDir, $BrowserExe)
	If $BrowserDir = "" Then Return ""

	Local $ApplicationIni = $BrowserDir & Chr(92) & "application.ini"
	If Not FileExists($ApplicationIni) Then $ApplicationIni = $BrowserDir & Chr(92) & "browser" & Chr(92) & "application.ini"
	If Not FileExists($ApplicationIni) Then Return ""
	Return StringStripWS(IniRead($ApplicationIni, "App", "Version", ""), 3)
EndFunc   ;==>GetApplicationIniVersion

Func IsChromiumBrowserIdentity($Identity, $BrowserExeLower)
	If $BrowserExeLower = "chrome.exe" Or $BrowserExeLower = "chromium.exe" Then Return True
	If $BrowserExeLower = "msedge.exe" Or $BrowserExeLower = "brave.exe" Then Return True
	If $BrowserExeLower = "vivaldi.exe" Or $BrowserExeLower = "opera.exe" Then Return True
	If StringInStr($Identity, "google chrome") Or StringInStr($Identity, "chromium") Then Return True
	If StringInStr($Identity, "microsoft edge") Or StringInStr($Identity, "brave") Then Return True
	If StringInStr($Identity, "vivaldi") Or StringInStr($Identity, "opera") Then Return True
	Return False
EndFunc   ;==>IsChromiumBrowserIdentity

Func IsChromeBrowser($Value)
	Local $Normalized = NormalizeBrowserType($Value)
	Return $Normalized = $BrowserChrome Or $Normalized = $BrowserUngoogledChromium Or $Normalized = $BrowserTurbo Or $Normalized = $BrowserHelium Or $Normalized = $BrowserWhale Or $Normalized = $BrowserCent Or $Normalized = $BrowserVivaldi Or $Normalized = $BrowserOpera Or $Normalized = $BrowserBrave Or $Normalized = $BrowserXunlei
EndFunc   ;==>IsChromeBrowser

Func IsGoogleChromeBrowser($Value)
	Return NormalizeBrowserType($Value) = $BrowserChrome
EndFunc   ;==>IsGoogleChromeBrowser

Func IsChromePlusSupportedBrowser($Value)
	Local $Normalized = NormalizeBrowserType($Value)
	Return $Normalized = $BrowserChrome Or $Normalized = $BrowserUngoogledChromium Or $Normalized = $BrowserHelium Or $Normalized = $BrowserBrave Or $Normalized = $BrowserWhale
EndFunc   ;==>IsChromePlusSupportedBrowser

Func IsBossKeySupportedBrowser($Value)
	Local $Normalized = NormalizeBrowserType($Value)
	Return $Normalized <> $BrowserTurbo And $Normalized <> $BrowserCent
EndFunc   ;==>IsBossKeySupportedBrowser

Func IsFloorpBrowser($Value)
	Return NormalizeBrowserType($Value) = $BrowserFloorp
EndFunc   ;==>IsFloorpBrowser

Func IsMozillaBrowser($Value)
	Return Not IsChromeBrowser($Value)
EndFunc   ;==>IsMozillaBrowser

Func NormalizeBrowserType($Value)
	$Value = StringLower(StringStripWS($Value, 3))
	If $Value = $BrowserZen Or $Value = "zenbrowser" Then Return $BrowserZen
	If $Value = $BrowserFloorp Then Return $BrowserFloorp
	If $Value = $BrowserWaterfox Then Return $BrowserWaterfox
	If $Value = $BrowserLibreWolf Then Return $BrowserLibreWolf
	If $Value = $BrowserChrome Or $Value = "google chrome" Then Return $BrowserChrome
	If $Value = $BrowserTurbo Or $Value = "turbo browser" Or $Value = "tbrowser" Or $Value = "涡轮浏览器" Or $Value = "渦輪瀏覽器" Then Return $BrowserTurbo
	If $Value = $BrowserHelium Then Return $BrowserHelium
	If $Value = $BrowserWhale Or $Value = "naver whale" Or $Value = "whalebrowser" Then Return $BrowserWhale
	If $Value = $BrowserCent Or $Value = "cent browser" Or $Value = "centbrowser" Or $Value = "百分浏览器" Or $Value = "百分瀏覽器" Then Return $BrowserCent
	If $Value = $BrowserVivaldi Then Return $BrowserVivaldi
	If $Value = $BrowserOpera Or $Value = "opera browser" Then Return $BrowserOpera
	If $Value = $BrowserBrave Or $Value = "brave browser" Then Return $BrowserBrave
	If $Value = $BrowserXunlei Or $Value = "xunlei browser" Or $Value = "迅雷浏览器" Or $Value = "迅雷瀏覽器" Then Return $BrowserXunlei
	If $Value = $BrowserUngoogledChromium Or $Value = "ungoogled chromium" Or $Value = "ungoogled-chromium" Then Return $BrowserUngoogledChromium
	Return $BrowserFirefox
EndFunc   ;==>NormalizeBrowserType

Func GetBrowserDisplayName($Value)
	If NormalizeBrowserType($Value) = $BrowserChrome Then Return "Chrome"
	If NormalizeBrowserType($Value) = $BrowserTurbo Then Return "Turbo Browser"
	If NormalizeBrowserType($Value) = $BrowserHelium Then Return "Helium"
	If NormalizeBrowserType($Value) = $BrowserWhale Then Return "Naver Whale"
	If NormalizeBrowserType($Value) = $BrowserCent Then Return "Cent Browser"
	If NormalizeBrowserType($Value) = $BrowserVivaldi Then Return "Vivaldi"
	If NormalizeBrowserType($Value) = $BrowserOpera Then Return "Opera"
	If NormalizeBrowserType($Value) = $BrowserBrave Then Return "Brave"
	If NormalizeBrowserType($Value) = $BrowserXunlei Then Return "Xunlei Browser"
	If NormalizeBrowserType($Value) = $BrowserUngoogledChromium Then Return "Ungoogled Chromium"
	If NormalizeBrowserType($Value) = $BrowserZen Then Return "ZenBrowser"
	If NormalizeBrowserType($Value) = $BrowserFloorp Then Return "Floorp"
	If NormalizeBrowserType($Value) = $BrowserWaterfox Then Return "Waterfox"
	If NormalizeBrowserType($Value) = $BrowserLibreWolf Then Return "LibreWolf"
	Return "Firefox"
EndFunc   ;==>GetBrowserDisplayName

Func GetBrowserTypeLabel($Value)
	If NormalizeBrowserType($Value) = $BrowserChrome Then Return _t("BrowserChrome", "Chrome")
	If NormalizeBrowserType($Value) = $BrowserTurbo Then Return _t("BrowserTurbo", "涡轮浏览器")
	If NormalizeBrowserType($Value) = $BrowserHelium Then Return _t("BrowserHelium", "Helium")
	If NormalizeBrowserType($Value) = $BrowserWhale Then Return _t("BrowserWhale", "Naver Whale")
	If NormalizeBrowserType($Value) = $BrowserCent Then Return _t("BrowserCent", "百分浏览器")
	If NormalizeBrowserType($Value) = $BrowserVivaldi Then Return _t("BrowserVivaldi", "Vivaldi")
	If NormalizeBrowserType($Value) = $BrowserOpera Then Return _t("BrowserOpera", "Opera")
	If NormalizeBrowserType($Value) = $BrowserBrave Then Return _t("BrowserBrave", "Brave")
	If NormalizeBrowserType($Value) = $BrowserXunlei Then Return _t("BrowserXunlei", "迅雷浏览器")
	If NormalizeBrowserType($Value) = $BrowserUngoogledChromium Then Return _t("BrowserUngoogledChromium", "Ungoogled Chromium")
	If NormalizeBrowserType($Value) = $BrowserZen Then Return _t("BrowserZen", "ZenBrowser")
	If NormalizeBrowserType($Value) = $BrowserFloorp Then Return _t("BrowserFloorp", "Floorp")
	If NormalizeBrowserType($Value) = $BrowserWaterfox Then Return _t("BrowserWaterfox", "Waterfox")
	If NormalizeBrowserType($Value) = $BrowserLibreWolf Then Return _t("BrowserLibreWolf", "LibreWolf")
	Return _t("BrowserFirefox", "Firefox 原版")
EndFunc   ;==>GetBrowserTypeLabel

Func GetBrowserTypeByLabel($Label)
	If $Label = _t("BrowserChrome", "Chrome") Or StringLower($Label) = "chrome" Or StringLower($Label) = "google chrome" Then Return $BrowserChrome
	If $Label = _t("BrowserTurbo", "涡轮浏览器") Or StringLower($Label) = "turbo" Or StringLower($Label) = "turbo browser" Or StringLower($Label) = "tbrowser" Or $Label = "涡轮浏览器" Or $Label = "渦輪瀏覽器" Then Return $BrowserTurbo
	If $Label = _t("BrowserHelium", "Helium") Or StringLower($Label) = "helium" Then Return $BrowserHelium
	If $Label = _t("BrowserWhale", "Naver Whale") Or StringLower($Label) = "whale" Or StringLower($Label) = "naver whale" Then Return $BrowserWhale
	If $Label = _t("BrowserCent", "百分浏览器") Or StringLower($Label) = "cent" Or StringLower($Label) = "cent browser" Or $Label = "百分浏览器" Or $Label = "百分瀏覽器" Then Return $BrowserCent
	If $Label = _t("BrowserVivaldi", "Vivaldi") Or StringLower($Label) = "vivaldi" Then Return $BrowserVivaldi
	If $Label = _t("BrowserOpera", "Opera") Or StringLower($Label) = "opera" Or StringLower($Label) = "opera browser" Then Return $BrowserOpera
	If $Label = _t("BrowserBrave", "Brave") Or StringLower($Label) = "brave" Then Return $BrowserBrave
	If $Label = _t("BrowserXunlei", "迅雷浏览器") Or StringLower($Label) = "xunlei" Or StringLower($Label) = "xunlei browser" Or $Label = "迅雷浏览器" Or $Label = "迅雷瀏覽器" Then Return $BrowserXunlei
	If $Label = _t("BrowserUngoogledChromium", "Ungoogled Chromium") Or StringLower($Label) = "ungoogled-chromium" Or StringLower($Label) = "ungoogled chromium" Then Return $BrowserUngoogledChromium
	If $Label = _t("BrowserZen", "ZenBrowser") Or StringLower($Label) = "zenbrowser" Then Return $BrowserZen
	If $Label = _t("BrowserFloorp", "Floorp") Or StringLower($Label) = "floorp" Then Return $BrowserFloorp
	If $Label = _t("BrowserWaterfox", "Waterfox") Or StringLower($Label) = "waterfox" Then Return $BrowserWaterfox
	If $Label = _t("BrowserLibreWolf", "LibreWolf") Or StringLower($Label) = "librewolf" Then Return $BrowserLibreWolf
	Return $BrowserFirefox
EndFunc   ;==>GetBrowserTypeByLabel

Func GetBrowserTypeComboData()
	Return _t("BrowserFirefox", "Firefox 原版") & "|" & _t("BrowserZen", "ZenBrowser") & "|" & _t("BrowserFloorp", "Floorp") & "|" & _t("BrowserWaterfox", "Waterfox") & "|" & _t("BrowserLibreWolf", "LibreWolf") & "|" & _t("BrowserChrome", "Chrome") & "|" & _t("BrowserUngoogledChromium", "Ungoogled Chromium") & "|" & _t("BrowserTurbo", "涡轮浏览器") & "|" & _t("BrowserHelium", "Helium") & "|" & _t("BrowserWhale", "Naver Whale") & "|" & _t("BrowserCent", "百分浏览器") & "|" & _t("BrowserVivaldi", "Vivaldi") & "|" & _t("BrowserOpera", "Opera") & "|" & _t("BrowserBrave", "Brave") & "|" & _t("BrowserXunlei", "迅雷浏览器")
EndFunc   ;==>GetBrowserTypeComboData

Func GetBrowserExecutableName($Value)
	If NormalizeBrowserType($Value) = $BrowserChrome Then Return "chrome.exe"
	If NormalizeBrowserType($Value) = $BrowserTurbo Then Return "turbo.exe"
	If NormalizeBrowserType($Value) = $BrowserHelium Then Return "chrome.exe"
	If NormalizeBrowserType($Value) = $BrowserWhale Then Return "whale.exe"
	If NormalizeBrowserType($Value) = $BrowserCent Then Return "chrome.exe"
	If NormalizeBrowserType($Value) = $BrowserVivaldi Then Return "vivaldi.exe"
	If NormalizeBrowserType($Value) = $BrowserOpera Then Return "opera.exe"
	If NormalizeBrowserType($Value) = $BrowserBrave Then Return "brave.exe"
	If NormalizeBrowserType($Value) = $BrowserXunlei Then Return "XunleiBrowser.exe"
	If NormalizeBrowserType($Value) = $BrowserUngoogledChromium Then Return "chrome.exe"
	If NormalizeBrowserType($Value) = $BrowserZen Then Return "zen.exe"
	If NormalizeBrowserType($Value) = $BrowserFloorp Then Return "floorp.exe"
	If NormalizeBrowserType($Value) = $BrowserWaterfox Then Return "waterfox.exe"
	If NormalizeBrowserType($Value) = $BrowserLibreWolf Then Return "librewolf.exe"
	Return "firefox.exe"
EndFunc   ;==>GetBrowserExecutableName

Func GetBrowserExecutableCandidates($Value)
	If NormalizeBrowserType($Value) = $BrowserXunlei Then Return "XunleiBrowser.exe|XLBrowser.exe"
	Return GetBrowserExecutableName($Value)
EndFunc   ;==>GetBrowserExecutableCandidates

Func GetDefaultBrowserPath($Value)
	If NormalizeBrowserType($Value) = $BrowserChrome Then Return ".\Chrome\chrome.exe"
	If NormalizeBrowserType($Value) = $BrowserTurbo Then Return ".\Turbo\turbo.exe"
	If NormalizeBrowserType($Value) = $BrowserHelium Then Return ".\Helium\chrome.exe"
	If NormalizeBrowserType($Value) = $BrowserWhale Then Return ".\Whale\whale.exe"
	If NormalizeBrowserType($Value) = $BrowserCent Then Return ".\CentBrowser\chrome.exe"
	If NormalizeBrowserType($Value) = $BrowserVivaldi Then Return ".\Vivaldi\vivaldi.exe"
	If NormalizeBrowserType($Value) = $BrowserOpera Then Return ".\Opera\opera.exe"
	If NormalizeBrowserType($Value) = $BrowserBrave Then Return ".\Brave\brave.exe"
	If NormalizeBrowserType($Value) = $BrowserXunlei Then Return ".\Xunlei\XunleiBrowser.exe"
	If NormalizeBrowserType($Value) = $BrowserUngoogledChromium Then Return ".\ungoogled-chromium\chrome.exe"
	If NormalizeBrowserType($Value) = $BrowserZen Then Return ".\ZenBrowser\zen.exe"
	If NormalizeBrowserType($Value) = $BrowserFloorp Then Return ".\Floorp\floorp.exe"
	If NormalizeBrowserType($Value) = $BrowserWaterfox Then Return ".\Waterfox\waterfox.exe"
	If NormalizeBrowserType($Value) = $BrowserLibreWolf Then Return ".\LibreWolf\librewolf.exe"
	Return ".\Firefox\firefox.exe"
EndFunc   ;==>GetDefaultBrowserPath

Func BuildBrowserLaunchParams($Value)
	If IsChromeBrowser($Value) Then
		Local $ChromeParams = ""
		Local $UseChromePlusPortablePaths = False
		If IsChromePlusSupportedBrowser($Value) And IsChromePlusPatchInstalled($BrowserPath) Then
			Local $ChromePlusConfigPath = GetChromePlusConfigPath($BrowserPath)
			If $ChromePlusConfigPath <> "" Then
				If FileExists($ChromePlusConfigPath) Or WriteChromePlusManagedConfig($ChromePlusConfigPath) Then _
					$UseChromePlusPortablePaths = WriteChromePlusPortablePaths($ChromePlusConfigPath)
			EndIf
		EndIf
		If Not $UseChromePlusPortablePaths Then
			$ChromeParams = '--user-data-dir="' & $ProfileDir & '"'
			If $CustomCacheDir <> "" Then $ChromeParams &= ' --disk-cache-dir="' & FullPath($CustomCacheDir) & '"'
		EndIf
		If $CacheSize <> "" And $CacheSize > 0 Then
			If $ChromeParams <> "" Then $ChromeParams &= " "
			$ChromeParams &= "--disk-cache-size=" & ($CacheSize * 1024 * 1024)
		EndIf
		Local $WhaleLocale = GetWhaleCommandLineLocale($Value)
		If $WhaleLocale <> "" Then
			If $ChromeParams <> "" Then $ChromeParams &= " "
			$ChromeParams &= "--lang=" & $WhaleLocale
		EndIf
		If $ChromiumDebugPortEnabled And $ChromiumDebugPort >= 1 And $ChromiumDebugPort <= 65535 Then
			If $ChromeParams <> "" Then $ChromeParams &= " "
			$ChromeParams &= "--remote-debugging-port=" & $ChromiumDebugPort
		EndIf
		If $ChromeParams <> "" Then $ChromeParams &= " "
		Return $ChromeParams
	EndIf

	Local $MozillaParams = '-profile "' & $ProfileDir & '" '
	If $isZotero Then
		$MozillaParams &= '-datadir "' & $ProfileDir & '\Library" '
	EndIf
	Return $MozillaParams
EndFunc   ;==>BuildBrowserLaunchParams

Func RunBrowserProcess($LaunchParams)
	; Preserve RunFirefox's %APP% command-line placeholder without leaking the
	; same-named environment variable into Chrome++, where %app% means the
	; directory containing the browser executable.
	Local $ExpandedLaunchParams = StringReplace($LaunchParams, "%APP%", @ScriptDir)
	Local $RunFirefoxApp = EnvGet("APP")
	EnvSet("APP")
	Local $PID = Run('"' & $BrowserPath & '" ' & $ExpandedLaunchParams, $BrowserDirectory)
	EnvSet("APP", $RunFirefoxApp)
	Return $PID
EndFunc   ;==>RunBrowserProcess

Func HasCustomCdpParameter($Value)
	Return StringRegExp($Value, "(?i)(^|\s)--remote-debugging-(?:port(?:=|\s|$)|pipe(?:\s|$))")
EndFunc   ;==>HasCustomCdpParameter

Func NeedsOutdatedBuildDetectorParam()
	If Not IsChromeBrowser($BrowserType) Then Return False
	If IsChromePlusSupportedBrowser($BrowserType) And IsChromePlusPatchInstalled($BrowserPath) Then Return False
	Return True
EndFunc   ;==>NeedsOutdatedBuildDetectorParam

Func AppendOutdatedBuildDetectorParam($Params)
	Local $Result = StringStripWS($Params, 2)
	If StringRegExp($Result, '(?i)--disable-features=[^\s]*\bOutdatedBuildDetector\b') Then Return $Result
	; Chromium 对重复开关只取最后一次的值，携带既有值合并追加，避免覆盖用户已禁用的特性
	Local $Features = StringRegExp($Result, '(?i)--disable-features=([^\s]+)', 3)
	Local $Merged = "OutdatedBuildDetector"
	If Not @error Then $Merged = $Features[UBound($Features) - 1] & ",OutdatedBuildDetector"
	Return $Result & " --disable-features=" & $Merged
EndFunc   ;==>AppendOutdatedBuildDetectorParam

Func GetWhaleCommandLineLocale($Value)
	If NormalizeBrowserType($Value) <> $BrowserWhale Then Return ""

	Local $Locale = StringLower(NormalizeLanguageName(GetBrowserLocale()))
	Switch $Locale
		Case "zh-cn", "zh-hans", "zh-sg"
			Return "zh-CN"
		Case "zh-tw", "zh-hant", "zh-hk", "zh-mo"
			Return "zh-TW"
	EndSwitch
	Return ""
EndFunc   ;==>GetWhaleCommandLineLocale

Func GetBrowserWindowClass($Value)
	If IsChromeBrowser($Value) Then Return "Chrome"
	Return "MozillaWindowClass"
EndFunc   ;==>GetBrowserWindowClass

Func GetBrowserWindowWait($Value)
	If IsChromeBrowser($Value) Then Return 10
	Return 15
EndFunc   ;==>GetBrowserWindowWait

Func UpdateBrowserSpecificControls()
	If Not $idBrowserType Then Return
	Local $IsChrome = IsChromeBrowser(GetSelectedBrowserType())
	If NormalizeBrowserType(GetSelectedBrowserType()) = $BrowserUngoogledChromium Then
		GUICtrlSetState($idBrowserBitness, $GUI_ENABLE)
	Else
		GUICtrlSetData($idBrowserBitness, "x64", "x64")
		GUICtrlSetState($idBrowserBitness, $GUI_DISABLE)
	EndIf
	Local $MozillaState = $GUI_ENABLE
	Local $ChromiumState = $GUI_DISABLE
	If $IsChrome Then $MozillaState = $GUI_DISABLE
	If $IsChrome Then $ChromiumState = $GUI_ENABLE
	; Browser auto update works either through the browser's own updater
	; (Mozilla) or through RunFirefox's managed update (Chrome for now).
	Local $AutoUpdateSupported = IsMozillaBrowser(GetSelectedBrowserType()) Or _BrowserAutoUpdateIsSupported(GetSelectedBrowserType())
	Local $AutoUpdateState = $GUI_ENABLE
	If Not $AutoUpdateSupported Then $AutoUpdateState = $GUI_DISABLE

	GUICtrlSetState($idChannel, $GUI_ENABLE)
	GUICtrlSetState($idAllowBrowserUpdate, $AutoUpdateState)
	GUICtrlSetState($idBrowserUpdateCheckMode, $AutoUpdateState)
	GUICtrlSetState($idBrowserDownloadLink, $GUI_ENABLE)
	GUICtrlSetState($idCustomPluginsDir, $MozillaState)
	GUICtrlSetState($idGetPluginsDir, $MozillaState)
	GUICtrlSetState($idCacheSizeSmart, $MozillaState)
	GUICtrlSetState($idChromiumGoogleApiImport, $ChromiumState)
	GUICtrlSetState($idChromiumGoogleApiSuppress, $ChromiumState)
	GUICtrlSetState($idChromiumGoogleApiClear, $ChromiumState)
	RefreshChromiumDebugPortState()

	If $IsChrome Then
		UpdateBrowserDownloadLabels(False)
	EndIf
	RefreshCopyProfileState()

	RefreshChromePlusTabState()
	RefreshBossKeyControlsState()
EndFunc   ;==>UpdateBrowserSpecificControls

Func GetCurrentSettingsBrowserPath()
	If $idBrowserPath Then Return FullPath(GUICtrlRead($idBrowserPath))
	Return FullPath($BrowserPath)
EndFunc   ;==>GetCurrentSettingsBrowserPath

Func IsChromePlusSupportedExecutable($BrowserExe)
	$BrowserExe = StringLower($BrowserExe)
	Return $BrowserExe = "chrome.exe" Or $BrowserExe = "helium.exe" Or $BrowserExe = "whale.exe" Or $BrowserExe = "brave.exe"
EndFunc   ;==>IsChromePlusSupportedExecutable

Func GetChromePlusConfigPath($BrowserPath)
	If $BrowserPath = "" Then Return ""

	Local $BrowserDir = "", $BrowserExe = ""
	SplitPath(FullPath($BrowserPath), $BrowserDir, $BrowserExe)
	If Not IsChromePlusSupportedExecutable($BrowserExe) Then Return ""
	If $BrowserDir = "" Or $BrowserDir = "." Then $BrowserDir = @ScriptDir
	Return $BrowserDir & "\chrome++.ini"
EndFunc   ;==>GetChromePlusConfigPath

Func SetCheckboxStateByValue($idCtrl, $Value)
	If Number($Value) <> 0 Then
		GUICtrlSetState($idCtrl, $GUI_CHECKED)
	Else
		GUICtrlSetState($idCtrl, $GUI_UNCHECKED)
	EndIf
EndFunc   ;==>SetCheckboxStateByValue

Func GetCheckboxIniValue($idCtrl)
	If GUICtrlRead($idCtrl) = $GUI_CHECKED Then Return "1"
	Return "0"
EndFunc   ;==>GetCheckboxIniValue

Func SetChromePlusTabControlsState($Enabled)
	Local $State = $GUI_DISABLE
	If $Enabled Then $State = $GUI_ENABLE

	GUICtrlSetState($idChromePlusDoubleClickClose, $State)
	GUICtrlSetState($idChromePlusRightClickClose, $State)
	GUICtrlSetState($idChromePlusKeepLastTab, $State)
	GUICtrlSetState($idChromePlusWheelTab, $State)
	GUICtrlSetState($idChromePlusWheelTabWhenPressRButton, $State)
	GUICtrlSetState($idChromePlusOpenUrlNewTab, $State)
	GUICtrlSetState($idChromePlusOpenBookmarkNewTab, $State)
	GUICtrlSetState($idChromePlusNewTabDisable, $State)
	GUICtrlSetState($idChromePlusHoverTab, $State)
	GUICtrlSetState($idChromePlusSuppressFalseUpgradeNotification, $State)
	If Not $Enabled Then
		GUICtrlSetState($idChromePlusHoverTabDelay, $GUI_DISABLE)
		GUICtrlSetState($idChromePlusHoverTabDelayLabel, $GUI_DISABLE)
		GUICtrlSetState($idChromePlusNewTabDisableName, $GUI_DISABLE)
		GUICtrlSetState($idChromePlusNewTabDisableNameLabel, $GUI_DISABLE)
	EndIf
EndFunc   ;==>SetChromePlusTabControlsState

Func LoadChromePlusTabsSettings($ConfigPath)
	SetCheckboxStateByValue($idChromePlusDoubleClickClose, IniRead($ConfigPath, "tabs", "double_click_close", "0"))
	SetCheckboxStateByValue($idChromePlusRightClickClose, IniRead($ConfigPath, "tabs", "right_click_close", "1"))
	SetCheckboxStateByValue($idChromePlusKeepLastTab, IniRead($ConfigPath, "tabs", "keep_last_tab", "1"))
	SetCheckboxStateByValue($idChromePlusWheelTab, IniRead($ConfigPath, "tabs", "wheel_tab", "0"))
	SetCheckboxStateByValue($idChromePlusWheelTabWhenPressRButton, IniRead($ConfigPath, "tabs", "wheel_tab_when_press_rbutton", "0"))
	SetCheckboxStateByValue($idChromePlusOpenUrlNewTab, IniRead($ConfigPath, "tabs", "open_url_new_tab", "0"))
	SetCheckboxStateByValue($idChromePlusOpenBookmarkNewTab, IniRead($ConfigPath, "tabs", "open_bookmark_new_tab", "0"))
	SetCheckboxStateByValue($idChromePlusNewTabDisable, IniRead($ConfigPath, "tabs", "new_tab_disable", "1"))
	SetCheckboxStateByValue($idChromePlusHoverTab, IniRead($ConfigPath, "tabs", "hover_tab", "0"))
	GUICtrlSetData($idChromePlusHoverTabDelay, NormalizeChromePlusHoverTabDelay(IniRead($ConfigPath, "tabs", "hover_tab_delay", "400")))
	GUICtrlSetData($idChromePlusNewTabDisableName, ReadIniTextValue($ConfigPath, "tabs", "new_tab_disable_name", '"about:blank","新建标签"'))
	SetCheckboxStateByValue($idChromePlusSuppressFalseUpgradeNotification, IniRead($ConfigPath, "general", "suppress_false_upgrade_notification", "0"))
	RefreshChromePlusHoverTabDelayState()
	RefreshChromePlusNewTabDisableNameState()
EndFunc   ;==>LoadChromePlusTabsSettings

Func NormalizeChromePlusHoverTabDelay($Value)
	$Value = StringStripWS($Value, 3)
	If Not StringRegExp($Value, "^\d+$") Then Return 400

	Local $Delay = Int($Value)
	If $Delay > 5000 Then Return 400
	Return $Delay
EndFunc   ;==>NormalizeChromePlusHoverTabDelay

Func IsChromePlusHoverTabSupported($BrowserPath)
	If UsesBundledChromePlus($BrowserPath) And IsBundledChromePlusInstalled($BrowserPath) Then Return True
	Local $Version = NormalizeChromePlusVersionText(GetChromePlusInstalledVersion($BrowserPath))
	Return $Version <> "" And VersionCompare($Version, "1.18.0") >= 0
EndFunc   ;==>IsChromePlusHoverTabSupported

Func RefreshChromePlusHoverTabDelayState()
	If Not $idChromePlusHoverTabDelay Then Return

	Local $Version = GetChromePlusInstalledVersion(GetCurrentSettingsBrowserPath())
	Local $FeatureSupported = IsChromePlusHoverTabSupported(GetCurrentSettingsBrowserPath())
	Local $Tooltip = _t("ChromePlusHoverTabDelayTooltip", "鼠标需在标签页上停留多久才会激活，范围为 0-5000 毫秒；无效值会使用 400 毫秒。")
	If Not $FeatureSupported Then
		If $Version = "" Then $Version = _t("BrowserVersionUnavailable", "获取失败")
		$Tooltip = _t("ChromePlusHoverTabVersionRequired", "鼠标悬停激活标签页需要 Chrome++ 1.18.0 或更高版本。当前版本：%s", $Version)
	EndIf
	GUICtrlSetTip($idChromePlusHoverTab, $Tooltip)
	GUICtrlSetTip($idChromePlusHoverTabDelay, $Tooltip)

	Local $State = $GUI_DISABLE
	If $FeatureSupported Then GUICtrlSetState($idChromePlusHoverTab, $GUI_ENABLE)
	If $FeatureSupported And GUICtrlRead($idChromePlusHoverTab) = $GUI_CHECKED Then
		$State = $GUI_ENABLE
	Else
		GUICtrlSetState($idChromePlusHoverTab, $GUI_DISABLE)
	EndIf
	GUICtrlSetState($idChromePlusHoverTabDelay, $State)
	GUICtrlSetState($idChromePlusHoverTabDelayLabel, $State)
EndFunc   ;==>RefreshChromePlusHoverTabDelayState

Func RefreshChromePlusNewTabDisableNameState()
	If Not $idChromePlusNewTabDisableName Then Return

	Local $State = $GUI_DISABLE
	If BitAND(GUICtrlGetState($idChromePlusNewTabDisable), $GUI_ENABLE) = $GUI_ENABLE And GUICtrlRead($idChromePlusNewTabDisable) = $GUI_CHECKED Then
		$State = $GUI_ENABLE
	EndIf
	GUICtrlSetState($idChromePlusNewTabDisableName, $State)
	GUICtrlSetState($idChromePlusNewTabDisableNameLabel, $State)
EndFunc   ;==>RefreshChromePlusNewTabDisableNameState

Func RefreshChromePlusTabState()
	If Not $idChromePlusHint Then Return

	Local $BrowserPath = GetCurrentSettingsBrowserPath()
	Local $SelectedBrowserType = GetSelectedBrowserType()
	Local $IsChromium = IsChromeBrowser($SelectedBrowserType)
	Local $IsChrome = IsChromePlusSupportedBrowser($SelectedBrowserType)
	Local $HasPatch = $IsChrome And IsChromePlusPatchInstalled($BrowserPath)
	Local $CanInstallPatch = $IsChrome And FileExists($BrowserPath) And GetChromePlusConfigPath($BrowserPath) <> ""

	If $HasPatch Then
		GUICtrlSetData($idChromePlusHint, _t("ChromePlusTabsReady", "已检测到 Chrome++ 补丁，以下设置将写入当前目录的 chrome++.ini。"))
		GUICtrlSetData($idChromePlusConfigPath, GetChromePlusConfigPath($BrowserPath))
		GUICtrlSetData($idChromePlusDownloadPatch, _t("UpdateChromePlusPatch", "更新 Chrome++"))
		GUICtrlSetState($idChromePlusDownloadPatch, $GUI_SHOW)
		SetChromePlusTabControlsState(True)
		LoadChromePlusTabsSettings(GetChromePlusConfigPath($BrowserPath))
		UpdateChromePlusVersionLabels()
		BeginChromePlusVersionLoad()
		Return
	EndIf

	If $IsChrome Then
		GUICtrlSetData($idChromePlusHint, _t("ChromePlusTabsPatchMissing", "当前浏览器目录未检测到 Chrome++ 补丁（version.dll），安装后才可修改这些选项。"))
		GUICtrlSetData($idChromePlusConfigPath, GetChromePlusConfigPath($BrowserPath))
		GUICtrlSetData($idChromePlusDownloadPatch, _t("DownloadChromePlusPatch", "下载并安装 Chrome++"))
		GUICtrlSetState($idChromePlusDownloadPatch, $GUI_SHOW)
		If $CanInstallPatch Then
			GUICtrlSetState($idChromePlusDownloadPatch, $GUI_ENABLE)
		Else
			GUICtrlSetState($idChromePlusDownloadPatch, $GUI_DISABLE)
		EndIf
		UpdateChromePlusVersionLabels()
		BeginChromePlusVersionLoad()
	Else
		If $IsChromium Then
			GUICtrlSetData($idChromePlusHint, _t("ChromePlusTabsUnsupportedBrowser", "Chrome++ 暂未兼容当前浏览器。"))
		Else
			GUICtrlSetData($idChromePlusHint, _t("ChromePlusTabsRequireChrome", "当前仅在 Chrome 系浏览器下可配置 Chrome++ 标签页选项。"))
		EndIf
		GUICtrlSetData($idChromePlusConfigPath, "")
		GUICtrlSetState($idChromePlusDownloadPatch, $GUI_HIDE)
		GUICtrlSetState($idChromePlusDownloadPatch, $GUI_DISABLE)
		CancelChromePlusVersionLoad()
		UpdateChromePlusVersionLabels()
	EndIf

	SetChromePlusTabControlsState(False)
	RefreshChromePlusHoverTabDelayState()
	RefreshChromePlusNewTabDisableNameState()
EndFunc   ;==>RefreshChromePlusTabState

Func DownloadChromePlusPatchFromSettings()
	Local $BrowserPath = GetCurrentSettingsBrowserPath()
	If InstallChromePlusPatchInteractive($BrowserPath) Then RefreshChromePlusTabState()
EndFunc   ;==>DownloadChromePlusPatchFromSettings

Func UpdateChromePlusVersionLabels($Unavailable = False)
	If Not $idChromePlusCurrentVersion Or Not $idChromePlusLatestVersion Then Return
	If UpdateBundledChromePlusLabels() Then Return
	GUICtrlSetData($idChromePlusCurrentCaption, _t("CurrentVersion", "当前版本："))
	GUICtrlSetData($idChromePlusLatestCaption, _t("LatestVersion", "最新版本："))

	Local $BrowserPath = GetCurrentSettingsBrowserPath()
	Local $CurrentVersion = ""
	Local $LatestVersion = ""

	If IsChromePlusSupportedBrowser(GetSelectedBrowserType()) Then
		$CurrentVersion = GetChromePlusInstalledVersion($BrowserPath)
		If $ChromePlusReleaseInfoLoaded Then
			$LatestVersion = GetChromePlusVersionFromTag($ChromePlusReleaseTag)
		ElseIf $ChromePlusVersionLoadHandle Then
			$LatestVersion = _t("BrowserVersionLoading", "正在读取版本 %s", GetChromePlusVersionLoadSpinner())
		ElseIf $Unavailable Then
			$LatestVersion = _t("BrowserVersionUnavailable", "获取失败")
		EndIf
	EndIf

	If $CurrentVersion = "" Then $CurrentVersion = "-"
	If $LatestVersion = "" Then $LatestVersion = "-"
	GUICtrlSetData($idChromePlusCurrentVersion, $CurrentVersion)
	GUICtrlSetData($idChromePlusLatestVersion, $LatestVersion)
	UpdateChromePlusDownloadPatchState()
EndFunc   ;==>UpdateChromePlusVersionLabels

Func UpdateChromePlusDownloadPatchState()
	If Not $idChromePlusDownloadPatch Then Return

	Local $BrowserPath = GetCurrentSettingsBrowserPath()
	Local $IsChrome = IsChromePlusSupportedBrowser(GetSelectedBrowserType())
	Local $HasPatch = $IsChrome And IsChromePlusPatchInstalled($BrowserPath)
	Local $CanInstallPatch = $IsChrome And FileExists($BrowserPath) And GetChromePlusConfigPath($BrowserPath) <> ""
	If Not $IsChrome Then
		GUICtrlSetState($idChromePlusDownloadPatch, $GUI_HIDE)
		GUICtrlSetState($idChromePlusDownloadPatch, $GUI_DISABLE)
		Return
	EndIf

	GUICtrlSetState($idChromePlusDownloadPatch, $GUI_SHOW)
	If Not $HasPatch Then
		If $CanInstallPatch Then
			GUICtrlSetState($idChromePlusDownloadPatch, $GUI_ENABLE)
		Else
			GUICtrlSetState($idChromePlusDownloadPatch, $GUI_DISABLE)
		EndIf
		Return
	EndIf

	If Not $CanInstallPatch Then
		GUICtrlSetState($idChromePlusDownloadPatch, $GUI_DISABLE)
		Return
	EndIf

	Local $CurrentVersion = NormalizeChromePlusVersionText(GetChromePlusInstalledVersion($BrowserPath))
	Local $LatestVersion = NormalizeChromePlusVersionText(GetChromePlusVersionFromTag($ChromePlusReleaseTag))
	If $LatestVersion = "" Or $CurrentVersion = "" Or VersionCompare($LatestVersion, $CurrentVersion) > 0 Then
		GUICtrlSetState($idChromePlusDownloadPatch, $GUI_ENABLE)
	Else
		GUICtrlSetState($idChromePlusDownloadPatch, $GUI_DISABLE)
	EndIf
EndFunc   ;==>UpdateChromePlusDownloadPatchState

Func GetChromePlusVersionLoadSpinner()
	Local $Spinner = "|"
	Switch Mod($ChromePlusVersionLoadAnim, 4)
		Case 1
			$Spinner = "/"
		Case 2
			$Spinner = "-"
		Case 3
			$Spinner = "\"
	EndSwitch
	$ChromePlusVersionLoadAnim += 1
	Return $Spinner
EndFunc   ;==>GetChromePlusVersionLoadSpinner

Func BeginChromePlusVersionLoad()
	If Not $idChromePlusLatestVersion Then Return
	If UsesBundledChromePlus(GetCurrentSettingsBrowserPath()) Then
		CancelChromePlusVersionLoad()
		UpdateChromePlusVersionLabels()
		Return
	EndIf
	If Not IsChromePlusSupportedBrowser(GetSelectedBrowserType()) Then Return
	If $ChromePlusReleaseInfoLoaded Then
		UpdateChromePlusVersionLabels()
		Return
	EndIf

	If $ChromePlusVersionLoadHandle Then
		UpdateChromePlusVersionLabels()
		Return
	EndIf

	$ChromePlusVersionLoadFile = @TempDir & "\RunFirefox_ChromePlusVersion_" & @AutoItPID & ".tmp"
	FileDelete($ChromePlusVersionLoadFile)
	$ChromePlusVersionLoadHandle = StartChromePlusVersionLoadProcess($ChromePlusVersionLoadFile)
	If Not $ChromePlusVersionLoadHandle Then
		CancelChromePlusVersionLoad()
		UpdateChromePlusVersionLabels(True)
		Return
	EndIf

	$ChromePlusVersionLoadAnim = 0
	UpdateChromePlusVersionLabels()
	AdlibRegister("PollChromePlusVersionLoad", 250)
EndFunc   ;==>BeginChromePlusVersionLoad

Func StartChromePlusVersionLoadProcess($OutputFile)
	Local $Command = ""
	If @Compiled Then
		$Command = '"' & @AutoItExe & '"'
	Else
		$Command = '"' & @AutoItExe & '" "' & @ScriptFullPath & '"'
	EndIf
	$Command &= ' --load-chrome-plus-version "' & $OutputFile & '"'
	Return Run($Command, @ScriptDir, @SW_HIDE)
EndFunc   ;==>StartChromePlusVersionLoadProcess

Func CancelChromePlusVersionLoad()
	AdlibUnRegister("PollChromePlusVersionLoad")
	If $ChromePlusVersionLoadHandle And ProcessExists($ChromePlusVersionLoadHandle) Then ProcessClose($ChromePlusVersionLoadHandle)
	If $ChromePlusVersionLoadFile <> "" Then FileDelete($ChromePlusVersionLoadFile)
	$ChromePlusVersionLoadHandle = 0
	$ChromePlusVersionLoadFile = ""
EndFunc   ;==>CancelChromePlusVersionLoad

Func PollChromePlusVersionLoad()
	If Not $ChromePlusVersionLoadHandle Then
		CancelChromePlusVersionLoad()
		Return
	EndIf

	UpdateChromePlusVersionLabels()
	If ProcessExists($ChromePlusVersionLoadHandle) Then Return

	Local $LoadedFile = $ChromePlusVersionLoadFile
	$ChromePlusVersionLoadHandle = 0
	AdlibUnRegister("PollChromePlusVersionLoad")

	Local $Loaded = LoadChromePlusReleaseInfoFile($LoadedFile)
	FileDelete($LoadedFile)
	$ChromePlusVersionLoadFile = ""
	UpdateChromePlusVersionLabels(Not $Loaded)
EndFunc   ;==>PollChromePlusVersionLoad

Func WriteChromePlusReleaseInfoFile($OutputFile)
	FileDelete($OutputFile)
	Local $ReleaseTag = "", $ArchiveUrl = "", $InstallLog = ""
	If GetChromePlusReleaseInfo($ReleaseTag, $ArchiveUrl, $InstallLog) Then
		IniWrite($OutputFile, "ChromePlus", "Success", 1)
		IniWrite($OutputFile, "ChromePlus", "ReleaseTag", $ReleaseTag)
		IniWrite($OutputFile, "ChromePlus", "ArchiveUrl", $ArchiveUrl)
	Else
		IniWrite($OutputFile, "ChromePlus", "Success", 0)
	EndIf
EndFunc   ;==>WriteChromePlusReleaseInfoFile

Func LoadChromePlusReleaseInfoFile($OutputFile)
	If Not FileExists($OutputFile) Then Return False
	If IniRead($OutputFile, "ChromePlus", "Success", 0) <> 1 Then Return False

	Local $ReleaseTag = IniRead($OutputFile, "ChromePlus", "ReleaseTag", "")
	Local $ArchiveUrl = IniRead($OutputFile, "ChromePlus", "ArchiveUrl", "")
	If $ReleaseTag = "" Or $ArchiveUrl = "" Then Return False

	SetChromePlusReleaseInfo($ReleaseTag, $ArchiveUrl)
	Return True
EndFunc   ;==>LoadChromePlusReleaseInfoFile

Func SaveChromePlusTabsSettings($BrowserPath)
	Local $ResolvedBrowserPath = FullPath($BrowserPath)
	If Not IsChromePlusSupportedBrowser($BrowserType) Or Not IsChromePlusPatchInstalled($ResolvedBrowserPath) Then Return True

	Local $ConfigPath = GetChromePlusConfigPath($ResolvedBrowserPath)
	If $ConfigPath = "" Then Return True
	If Not FileExists($ConfigPath) And Not WriteChromePlusManagedConfig($ConfigPath) Then Return False
	If Not WriteChromePlusPortablePaths($ConfigPath) Then Return False

	If Not WriteIniTextValue($ConfigPath, "tabs", "double_click_close", GetCheckboxIniValue($idChromePlusDoubleClickClose)) Then Return False
	If Not WriteIniTextValue($ConfigPath, "tabs", "right_click_close", GetCheckboxIniValue($idChromePlusRightClickClose)) Then Return False
	If Not WriteIniTextValue($ConfigPath, "tabs", "keep_last_tab", GetCheckboxIniValue($idChromePlusKeepLastTab)) Then Return False
	If Not WriteIniTextValue($ConfigPath, "tabs", "wheel_tab", GetCheckboxIniValue($idChromePlusWheelTab)) Then Return False
	If Not WriteIniTextValue($ConfigPath, "tabs", "wheel_tab_when_press_rbutton", GetCheckboxIniValue($idChromePlusWheelTabWhenPressRButton)) Then Return False
	If Not WriteIniTextValue($ConfigPath, "tabs", "open_url_new_tab", GetCheckboxIniValue($idChromePlusOpenUrlNewTab)) Then Return False
	If Not WriteIniTextValue($ConfigPath, "tabs", "open_bookmark_new_tab", GetCheckboxIniValue($idChromePlusOpenBookmarkNewTab)) Then Return False
	If Not WriteIniTextValue($ConfigPath, "tabs", "new_tab_disable", GetCheckboxIniValue($idChromePlusNewTabDisable)) Then Return False
	If IsChromePlusHoverTabSupported($ResolvedBrowserPath) Then
		If Not WriteIniTextValue($ConfigPath, "tabs", "hover_tab", GetCheckboxIniValue($idChromePlusHoverTab)) Then Return False
		If Not WriteIniTextValue($ConfigPath, "tabs", "hover_tab_delay", NormalizeChromePlusHoverTabDelay(GUICtrlRead($idChromePlusHoverTabDelay))) Then Return False
	EndIf
	If Not WriteIniTextValue($ConfigPath, "tabs", "new_tab_disable_name", StringStripWS(GUICtrlRead($idChromePlusNewTabDisableName), 3)) Then Return False
	If Not WriteIniTextValue($ConfigPath, "general", "suppress_false_upgrade_notification", GetCheckboxIniValue($idChromePlusSuppressFalseUpgradeNotification)) Then Return False
	Return True
EndFunc   ;==>SaveChromePlusTabsSettings

Func RefreshCopyProfileState()
	If Not $idCopyProfile Then Return
	Local $CurrentBrowserType = GetSelectedBrowserType()
	Local $SelectedChannel = "release"
	If $idChannel Then $SelectedChannel = GUICtrlRead($idChannel)
	$DefaultProfDir = GetSystemProfileSourceDir($CurrentBrowserType, $SelectedChannel)

	Local $SourceMarker = "\prefs.js"
	If IsChromeBrowser($CurrentBrowserType) Then $SourceMarker = "\Local State"
	Local $TargetProfileDir = FullPath($ProfileDir)
	If $idProfileDir Then $TargetProfileDir = FullPath(GUICtrlRead($idProfileDir))

	If $DefaultProfDir <> "" And FileExists($DefaultProfDir & $SourceMarker) Then
		GUICtrlSetState($idCopyProfile, $GUI_ENABLE)
		If $FirstRun And Not FileExists($TargetProfileDir & $SourceMarker) Then GUICtrlSetState($idCopyProfile, $GUI_CHECKED)
	Else
		GUICtrlSetState($idCopyProfile, $GUI_UNCHECKED)
		GUICtrlSetState($idCopyProfile, $GUI_DISABLE)
	EndIf
EndFunc   ;==>RefreshCopyProfileState

Func GetSystemProfileSourceDir($BrowserTypeValue, $Channel = "")
	If IsChromeBrowser($BrowserTypeValue) Then Return GetSystemChromiumUserDataDir($BrowserTypeValue, $Channel)
	Return GetSystemMozillaProfileDir($BrowserTypeValue)
EndFunc   ;==>GetSystemProfileSourceDir

Func GetSystemMozillaProfileDir($BrowserTypeValue)
	Local $ProfilesIni = GetMozillaProfilesIniPath($BrowserTypeValue)
	If $ProfilesIni = "" Then Return ""
	Return ReadDefaultProfileDirFromProfilesIni($ProfilesIni)
EndFunc   ;==>GetSystemMozillaProfileDir

Func GetMozillaProfilesIniPath($BrowserTypeValue)
	Switch NormalizeBrowserType($BrowserTypeValue)
		Case $BrowserZen
			Return @AppDataDir & "\zen\profiles.ini"
		Case $BrowserFloorp
			Return @AppDataDir & "\Floorp\profiles.ini"
		Case $BrowserWaterfox
			Return @AppDataDir & "\Waterfox\profiles.ini"
		Case $BrowserLibreWolf
			Return @AppDataDir & "\LibreWolf\profiles.ini"
	EndSwitch
	Return @AppDataDir & "\Mozilla\Firefox\profiles.ini"
EndFunc   ;==>GetMozillaProfilesIniPath

Func ReadDefaultProfileDirFromProfilesIni($ProfilesIni)
	If Not FileExists($ProfilesIni) Then Return ""

	Local $Sections = IniReadSectionNames($ProfilesIni)
	If @error Then Return ResolveProfilesIniProfilePath($ProfilesIni, IniRead($ProfilesIni, "Profile0", "Path", ""), IniRead($ProfilesIni, "Profile0", "IsRelative", "1"))

	Local $Fallback = "", $SectionName, $ProfilePath, $ResolvedPath
	For $i = 1 To $Sections[0]
		$SectionName = $Sections[$i]
		If Not StringRegExp($SectionName, "(?i)^Profile\d+$") Then ContinueLoop

		$ProfilePath = IniRead($ProfilesIni, $SectionName, "Path", "")
		If $ProfilePath = "" Then ContinueLoop

		$ResolvedPath = ResolveProfilesIniProfilePath($ProfilesIni, $ProfilePath, IniRead($ProfilesIni, $SectionName, "IsRelative", "1"))
		If $Fallback = "" Then $Fallback = $ResolvedPath
		If IniRead($ProfilesIni, $SectionName, "Default", "0") = "1" Then Return $ResolvedPath
	Next
	Return $Fallback
EndFunc   ;==>ReadDefaultProfileDirFromProfilesIni

Func ResolveProfilesIniProfilePath($ProfilesIni, $ProfilePath, $IsRelative)
	If $ProfilePath = "" Then Return ""
	$ProfilePath = StringReplace($ProfilePath, "/", "\")
	If $IsRelative = "0" And StringRegExp($ProfilePath, "^(?i:[a-z]:\\|\\\\)") Then Return $ProfilePath

	Local $ProfilesRoot, $ProfilesFile
	SplitPath($ProfilesIni, $ProfilesRoot, $ProfilesFile)
	Return $ProfilesRoot & "\" & $ProfilePath
EndFunc   ;==>ResolveProfilesIniProfilePath

Func GetSystemChromiumUserDataDir($BrowserTypeValue, $Channel = "")
	Local $Normalized = NormalizeBrowserType($BrowserTypeValue)
	If $Normalized = $BrowserTurbo Then
		If FileExists(@LocalAppDataDir & "\Turbo\User Data\Local State") Then Return @LocalAppDataDir & "\Turbo\User Data"
		If FileExists(@LocalAppDataDir & "\TurboBrowser\User Data\Local State") Then Return @LocalAppDataDir & "\TurboBrowser\User Data"
		If FileExists(@LocalAppDataDir & "\Turbo Browser\User Data\Local State") Then Return @LocalAppDataDir & "\Turbo Browser\User Data"
		If FileExists(@AppDataDir & "\Turbo\User Data\Local State") Then Return @AppDataDir & "\Turbo\User Data"
		Return ""
	EndIf
	If $Normalized = $BrowserHelium Then
		If FileExists(@LocalAppDataDir & "\Helium\User Data\Local State") Then Return @LocalAppDataDir & "\Helium\User Data"
		If FileExists(@LocalAppDataDir & "\The Helium Authors\Helium\User Data\Local State") Then Return @LocalAppDataDir & "\The Helium Authors\Helium\User Data"
		If FileExists(@LocalAppDataDir & "\imputnet\Helium\User Data\Local State") Then Return @LocalAppDataDir & "\imputnet\Helium\User Data"
		If FileExists(@AppDataDir & "\Helium\User Data\Local State") Then Return @AppDataDir & "\Helium\User Data"
		Return ""
	EndIf
	If $Normalized = $BrowserWhale Then
		If FileExists(@LocalAppDataDir & "\Naver\Naver Whale\User Data\Local State") Then Return @LocalAppDataDir & "\Naver\Naver Whale\User Data"
		If FileExists(@LocalAppDataDir & "\Naver\Whale\User Data\Local State") Then Return @LocalAppDataDir & "\Naver\Whale\User Data"
		If FileExists(@AppDataDir & "\Naver\Naver Whale\User Data\Local State") Then Return @AppDataDir & "\Naver\Naver Whale\User Data"
		Return ""
	EndIf
	If $Normalized = $BrowserCent Then
		If FileExists(@LocalAppDataDir & "\CentBrowser\User Data\Local State") Then Return @LocalAppDataDir & "\CentBrowser\User Data"
		If FileExists(@AppDataDir & "\CentBrowser\User Data\Local State") Then Return @AppDataDir & "\CentBrowser\User Data"
		Return ""
	EndIf
	If $Normalized = $BrowserVivaldi Then
		If FileExists(@LocalAppDataDir & "\Vivaldi\User Data\Local State") Then Return @LocalAppDataDir & "\Vivaldi\User Data"
		If FileExists(@AppDataDir & "\Vivaldi\User Data\Local State") Then Return @AppDataDir & "\Vivaldi\User Data"
		Return ""
	EndIf
	If $Normalized = $BrowserOpera Then
		; Opera keeps its default profile directly inside the channel folder,
		; without the Chromium-style "User Data" wrapper.
		Local $OperaProfileDir = "Opera Stable"
		If StringLower($Channel) = "beta" Then $OperaProfileDir = "Opera Beta"
		If StringLower($Channel) = "dev" Then $OperaProfileDir = "Opera Developer"
		If FileExists(@LocalAppDataDir & "\Opera Software\" & $OperaProfileDir & "\Local State") Then Return @LocalAppDataDir & "\Opera Software\" & $OperaProfileDir
		If FileExists(@AppDataDir & "\Opera Software\" & $OperaProfileDir & "\Local State") Then Return @AppDataDir & "\Opera Software\" & $OperaProfileDir
		Return ""
	EndIf
	If $Normalized = $BrowserBrave Then
		If FileExists(@LocalAppDataDir & "\BraveSoftware\Brave-Browser\User Data\Local State") Then Return @LocalAppDataDir & "\BraveSoftware\Brave-Browser\User Data"
		If FileExists(@AppDataDir & "\BraveSoftware\Brave-Browser\User Data\Local State") Then Return @AppDataDir & "\BraveSoftware\Brave-Browser\User Data"
		Return ""
	EndIf

	Local $CurrentBrowserPath = ""
	If $idBrowserPath Then $CurrentBrowserPath = StringLower(GUICtrlRead($idBrowserPath))
	Local $ChannelLower = StringLower($Channel)

	If StringInStr($CurrentBrowserPath, "chromium") Then
		If FileExists(@LocalAppDataDir & "\Chromium\User Data\Local State") Then Return @LocalAppDataDir & "\Chromium\User Data"
		If FileExists(@LocalAppDataDir & "\Google\Chrome\User Data\Local State") Then Return @LocalAppDataDir & "\Google\Chrome\User Data"
		If FileExists(@LocalAppDataDir & "\Google\Chrome SxS\User Data\Local State") Then Return @LocalAppDataDir & "\Google\Chrome SxS\User Data"
		Return ""
	EndIf

	If $ChannelLower = "canary" Then
		If FileExists(@LocalAppDataDir & "\Google\Chrome SxS\User Data\Local State") Then Return @LocalAppDataDir & "\Google\Chrome SxS\User Data"
		If FileExists(@LocalAppDataDir & "\Google\Chrome\User Data\Local State") Then Return @LocalAppDataDir & "\Google\Chrome\User Data"
		If FileExists(@LocalAppDataDir & "\Chromium\User Data\Local State") Then Return @LocalAppDataDir & "\Chromium\User Data"
		Return ""
	EndIf

	If FileExists(@LocalAppDataDir & "\Google\Chrome\User Data\Local State") Then Return @LocalAppDataDir & "\Google\Chrome\User Data"
	If FileExists(@LocalAppDataDir & "\Chromium\User Data\Local State") Then Return @LocalAppDataDir & "\Chromium\User Data"
	If FileExists(@LocalAppDataDir & "\Google\Chrome SxS\User Data\Local State") Then Return @LocalAppDataDir & "\Google\Chrome SxS\User Data"
	Return ""
EndFunc   ;==>GetSystemChromiumUserDataDir

Func ChromiumProfileInUse($UserDataDir)
	Local $LockFile = $UserDataDir & "\lockfile"
	Return FileExists($LockFile) And Not FileDelete($LockFile)
EndFunc   ;==>ChromiumProfileInUse

Func UpdateBrowserChannelOptions($Value, $SelectedChannel)
	Local $Options = "esr|release|beta|dev|nightly"
	Local $DefaultChannel = "release"
	If NormalizeBrowserType($Value) = $BrowserZen Then $Options = "release|twilight"
	If NormalizeBrowserType($Value) = $BrowserFloorp Then $Options = "release"
	If NormalizeBrowserType($Value) = $BrowserWaterfox Then $Options = "release"
	If NormalizeBrowserType($Value) = $BrowserLibreWolf Then $Options = "release"
	If NormalizeBrowserType($Value) = $BrowserTurbo Then $Options = "release"
	If NormalizeBrowserType($Value) = $BrowserHelium Then $Options = "release"
	If NormalizeBrowserType($Value) = $BrowserWhale Then $Options = "release"
	If NormalizeBrowserType($Value) = $BrowserCent Then $Options = "release"
	If NormalizeBrowserType($Value) = $BrowserVivaldi Then $Options = "release"
	If NormalizeBrowserType($Value) = $BrowserOpera Then
		$Options = "stable|beta|dev"
		$DefaultChannel = "stable"
	EndIf
	If NormalizeBrowserType($Value) = $BrowserBrave Then $Options = "release"
	If NormalizeBrowserType($Value) = $BrowserXunlei Then $Options = "release"
	If IsGoogleChromeBrowser($Value) Then
		$Options = "stable|beta|dev|canary"
		$DefaultChannel = "stable"
	EndIf
	If Not StringRegExp("|" & $Options & "|", "(?i)\|" & $SelectedChannel & "\|") Then $SelectedChannel = $DefaultChannel

	_SendMessage(GUICtrlGetHandle($idChannel), $CB_RESETCONTENT)
	GUICtrlSetData($idChannel, $Options, $SelectedChannel)
EndFunc   ;==>UpdateBrowserChannelOptions



Func IsChromePlusPatchInstalled($BrowserPath)
	If Not FileExists($BrowserPath) Then Return False
	If DetectBrowserTypeFromPath($BrowserPath) = $BrowserCent Then Return False

	Local $BrowserDir, $BrowserExe
	SplitPath($BrowserPath, $BrowserDir, $BrowserExe)
	If Not IsChromePlusSupportedExecutable($BrowserExe) Then Return False
	Return FileExists($BrowserDir & "\version.dll")
EndFunc   ;==>IsChromePlusPatchInstalled

Func GetChromePlusPatchPath($BrowserPath)
	If Not FileExists($BrowserPath) Then Return ""
	If DetectBrowserTypeFromPath($BrowserPath) = $BrowserCent Then Return ""

	Local $BrowserDir, $BrowserExe
	SplitPath($BrowserPath, $BrowserDir, $BrowserExe)
	If Not IsChromePlusSupportedExecutable($BrowserExe) Then Return ""
	Return $BrowserDir & "\version.dll"
EndFunc   ;==>GetChromePlusPatchPath

Func GetChromePlusInstalledVersion($BrowserPath)
	Local $PatchPath = GetChromePlusPatchPath($BrowserPath)
	If $PatchPath = "" Or Not FileExists($PatchPath) Then Return ""

	Local $Version = ReadExecutableVersionField($PatchPath, "ProductVersion")
	If $Version = "" Then $Version = ReadExecutableVersionField($PatchPath, "FileVersion")
	If $Version = "" Then
		$Version = FileGetVersion($PatchPath)
		If @error Then $Version = ""
	EndIf
	If UsesBundledChromePlus($BrowserPath) Then Return StringStripWS($Version, 3)
	Return NormalizeChromePlusVersionText($Version)
EndFunc   ;==>GetChromePlusInstalledVersion

Func NormalizeChromePlusVersionText($Version)
	$Version = StringStripWS($Version, 3)
	If $Version = "" Or $Version = "-" Then Return ""
	$Version = StringRegExpReplace($Version, "(?i)^chrome\+\+[_ ]*v?", "")
	$Version = StringRegExpReplace($Version, "^[vV]", "")
	$Version = StringRegExpReplace($Version, "[^0-9.].*$", "")
	Return StringStripWS($Version, 3)
EndFunc   ;==>NormalizeChromePlusVersionText

Func GetChromePlusVersionFromTag($ReleaseTag)
	Return NormalizeChromePlusVersionText($ReleaseTag)
EndFunc   ;==>GetChromePlusVersionFromTag

Func InstallChromePlusPatchInteractive($BrowserPath, $PreferredArch = "")
	If Not FileExists($BrowserPath) Then Return False
	If UsesBundledChromePlus($BrowserPath) Then Return InstallBundledChromePlus($BrowserPath)
	If DetectBrowserTypeFromPath($BrowserPath) = $BrowserCent Then Return False

	Local $BrowserDir, $BrowserExe
	SplitPath($BrowserPath, $BrowserDir, $BrowserExe)
	If Not IsChromePlusSupportedExecutable($BrowserExe) Then Return False

	Local $Arch = ResolveChromePlusArch($PreferredArch, $BrowserPath)
	Local $ReleaseTag = "", $ArchiveUrl = ""
	Local $VersionDir, $ArchivePath, $ExtractDir, $SourceDir, $SevenZipExe, $ExtractLog, $ExtractPid
	Local $ErrorMessage = "", $Success = False
	Local $InstallLog = "Chrome++ patch install log" & @CRLF & _
			"Time: " & _NowCalc() & @CRLF & _
			"Browser path: " & $BrowserPath & @CRLF & _
			"Browser dir: " & $BrowserDir & @CRLF & _
			"Browser exe: " & $BrowserExe & @CRLF & _
			"Preferred arch: " & $PreferredArch & @CRLF & _
			"Resolved arch: " & $Arch & @CRLF & _
			"OS arch: " & @OSArch & @CRLF & _
			"Cache root: " & $ChromePlusCacheRoot & @CRLF & @CRLF

	_DownloadToolsShowDownloadProgress(_t("ChromePlusPatchProgressTitle", "正在准备 Chrome++ 补丁"), _t("PreparingChromePlusPatch", "正在准备 Chrome++ 补丁 ..."), _t("PreparingChromePlusPatchDetail", "正在读取补丁版本信息，请稍候 ..."), $hSettings, _t("Cancel", "取消"))

	If GetChromePlusReleaseInfo($ReleaseTag, $ArchiveUrl, $InstallLog) Then
		$InstallLog &= "Release tag: " & $ReleaseTag & @CRLF
		$InstallLog &= "Archive URL: " & $ArchiveUrl & @CRLF
		$VersionDir = $ChromePlusCacheRoot & "\" & StringRegExpReplace($ReleaseTag, '[\\/:*?"<>|]', "_")
		$ArchivePath = $VersionDir & "\chrome_plus.7z"
		$ExtractDir = $VersionDir & "\extract"
		$SourceDir = $ExtractDir & "\" & $Arch & "\App"
		$InstallLog &= "Version dir: " & $VersionDir & @CRLF
		$InstallLog &= "Archive path: " & $ArchivePath & @CRLF
		$InstallLog &= "Extract dir: " & $ExtractDir & @CRLF
		$InstallLog &= "Source dir: " & $SourceDir & @CRLF & @CRLF
		If Not FileExists($SourceDir & "\version.dll") Then
			If Not FileExists($ChromePlusCacheRoot) Then DirCreate($ChromePlusCacheRoot)
			If Not FileExists($VersionDir) Then DirCreate($VersionDir)

			If Not FileExists($ArchivePath) Then
				If Not DownloadChromePlusArchiveWithProgress($ArchiveUrl, $ArchivePath, $InstallLog) Then
					If _DownloadToolsIsDownloadProgressCancelled() Then
						_DownloadToolsCloseDownloadProgress()
						If $hStatus Then _GUICtrlStatusBar_SetText($hStatus, _t("ChromePlusPatchInstallCancelled", "已取消 Chrome++ 补丁下载。"))
						Return False
					EndIf
					$ErrorMessage = _t("FailToDownloadChromePlusPatch", "下载 Chrome++ 补丁失败。")
				EndIf
			EndIf

			If $ErrorMessage = "" Then
				$SevenZipExe = _DownloadToolsPrepareSevenZipTool($VersionDir)
				If @error Or $SevenZipExe = "" Then
					$ErrorMessage = _t("FailToExtractChromePlusPatch", "解压或安装 Chrome++ 补丁失败。")
				Else
					If FileExists($ExtractDir) Then DirRemove($ExtractDir, 1)
					If Not FileExists($ExtractDir) Then DirCreate($ExtractDir)
					_DownloadToolsSetDownloadProgressBusy(_t("ExtractingChromePlusPatch", "正在安装 Chrome++ 补丁，请稍候 ..."), _t("ExtractingChromePlusPatchDetail", "安装期间请不要关闭 {AppName}。"))
					$ExtractLog = $VersionDir & "\extract.log"
					$InstallLog &= "Extract log: " & $ExtractLog & @CRLF
					$ExtractPid = _DownloadToolsRunArchiveExtraction($SevenZipExe, $ArchivePath, $ExtractDir, $ExtractLog, $VersionDir)
					If $ExtractPid <> 0 Then
						$InstallLog &= "Extractor failed. Return code=" & $ExtractPid & @CRLF
						$ErrorMessage = _t("FailToExtractChromePlusPatch", "解压或安装 Chrome++ 补丁失败。")
					Else
						$InstallLog &= "Extractor process finished." & @CRLF
					EndIf
				EndIf
			EndIf
		EndIf

		If $ErrorMessage = "" And Not FileExists($SourceDir & "\version.dll") Then
			$InstallLog &= "version.dll was not found in source dir." & @CRLF
			$ErrorMessage = _t("FailToExtractChromePlusPatch", "解压或安装 Chrome++ 补丁失败。")
		EndIf
		If $ErrorMessage = "" Then
			Local $CopiedVersionDll = FileCopy($SourceDir & "\version.dll", $BrowserDir & "\version.dll", 9)
			If $CopiedVersionDll = 0 Or Not FileExists($BrowserDir & "\version.dll") Then
				$InstallLog &= "version.dll was not copied to browser dir." & @CRLF
				$ErrorMessage = _t("FailToExtractChromePlusPatch", "解压或安装 Chrome++ 补丁失败。")
			EndIf
		EndIf
		If $ErrorMessage = "" And Not WriteChromePlusManagedConfig($BrowserDir & "\chrome++.ini") Then
			$InstallLog &= "Failed to write chrome++.ini." & @CRLF
			$ErrorMessage = _t("FailToExtractChromePlusPatch", "解压或安装 Chrome++ 补丁失败。")
		EndIf
		If $ErrorMessage = "" Then $Success = True
	Else
		$ErrorMessage = _t("FailToGetChromePlusReleaseInfo", "读取 Chrome++ 发布信息失败。")
	EndIf

	_DownloadToolsCloseDownloadProgress()
	If $Success Then
		If $hStatus Then _GUICtrlStatusBar_SetText($hStatus, _t("ChromePlusPatchInstalled", "Chrome++ 补丁已安装。"))
		Return True
	EndIf

	If $ErrorMessage = "" Then $ErrorMessage = _t("ChromePlusPatchInstallFailed", "Chrome++ 补丁安装失败。")
	$InstallLog &= @CRLF & "Final error: " & $ErrorMessage & @CRLF
	Local $InstallLogPath = WriteChromePlusInstallLog($InstallLog)
	ShowChromePlusPatchInstallFailedDialog($ErrorMessage, $InstallLogPath)
	Return False
EndFunc   ;==>InstallChromePlusPatchInteractive

Func ResolveChromePlusArch($PreferredArch, $BrowserPath)
	Local $Arch = StringLower(StringStripWS($PreferredArch, 3))
	Switch $Arch
		Case "x86", "win32", "32", "i386"
			Return "x86"
		Case "x64", "amd64", "64"
			Return "x64"
		Case "arm64", "aarch64"
			Return "arm64"
	EndSwitch

	$Arch = GetExecutableArch($BrowserPath)
	If $Arch <> "" Then Return $Arch

	If @OSArch = "X86" Then Return "x86"
	Return "x64"
EndFunc   ;==>ResolveChromePlusArch

Func GetExecutableArch($ExePath)
	Local $aCall = DllCall("kernel32.dll", "bool", "GetBinaryTypeW", "wstr", $ExePath, "dword*", 0)
	If @error Or Not IsArray($aCall) Or Not $aCall[0] Then Return ""

	Switch $aCall[2]
		Case 0
			Return "x86"
		Case 6
			Return "x64"
	EndSwitch
	Return ""
EndFunc   ;==>GetExecutableArch

Func DownloadChromePlusArchiveWithProgress($ArchiveUrl, $ArchivePath, ByRef $InstallLog)
	Local $aUrls = _UpgradeBuildGithubReleaseDownloadUrls($ArchiveUrl, GetEffectiveGithubDirectMirror(), GetEffectiveGithubJsDelivrMirror())
	Local $TargetDir, $TargetFile
	SplitPath($ArchivePath, $TargetDir, $TargetFile)
	If Not FileExists($TargetDir) Then DirCreate($TargetDir)

	Local $TriedUrls = ""
	Local $DownloadResult = _DownloadToolsDownloadUrls($aUrls, $ArchivePath, _t("DownloadingChromePlusPatch", "正在下载 Chrome++ 补丁 ..."), _t("BrowserDownloadProgressKnown", "已下载 {Downloaded} / {Total}"), _t("BrowserDownloadProgressUnknown", "已下载 %s"), $TriedUrls)
	If $TriedUrls <> "" Then
		Local $TriedUrlList = StringSplit($TriedUrls, @CRLF, 2)
		For $i = 0 To UBound($TriedUrlList) - 1
			$InstallLog &= "Trying archive URL: " & $TriedUrlList[$i] & @CRLF
		Next
	EndIf
	$InstallLog &= "Download result: " & $DownloadResult & ", file exists: " & FileExists($ArchivePath) & ", size: " & FileGetSize($ArchivePath) & @CRLF
	Return $DownloadResult And FileExists($ArchivePath) And FileGetSize($ArchivePath) > 0
EndFunc   ;==>DownloadChromePlusArchiveWithProgress

Func GetChromePlusReleaseInfo(ByRef $ReleaseTag, ByRef $ArchiveUrl, ByRef $InstallLog)
	Static $CachedReleaseTag = "", $CachedArchiveUrl = ""
	If $ChromePlusReleaseInfoLoaded And $ChromePlusReleaseTag <> "" And $ChromePlusArchiveUrl <> "" Then
		$ReleaseTag = $ChromePlusReleaseTag
		$ArchiveUrl = $ChromePlusArchiveUrl
		$InstallLog &= "Using global cached release info." & @CRLF
		Return True
	EndIf
	If $CachedReleaseTag <> "" And $CachedArchiveUrl <> "" Then
		$ReleaseTag = $CachedReleaseTag
		$ArchiveUrl = $CachedArchiveUrl
		SetChromePlusReleaseInfo($CachedReleaseTag, $CachedArchiveUrl)
		$InstallLog &= "Using cached release info." & @CRLF
		Return True
	EndIf

	Local $HttpDiagnostic = "", $sJson = ""
	Local $ChromePlusApiUrls = _UpgradeBuildGithubDirectUrls($ChromePlusReleasesApiUrl, GetEffectiveGithubDirectMirror())
	For $i = 0 To UBound($ChromePlusApiUrls) - 1
		$sJson = _DownloadToolsHttpGetTextDiagnostic($ChromePlusApiUrls[$i], $ChromePlusApiUserAgent, "application/vnd.github+json", $HttpDiagnostic)
		$InstallLog &= $HttpDiagnostic & @CRLF
		If $sJson <> "" Then ExitLoop
	Next
	If $sJson <> "" Then
		Local $ApiTags = StringRegExp($sJson, '"tag_name"\s*:\s*"([^"]+)"', 3)
		$CachedReleaseTag = GetLatestChromePlusStableTag($ApiTags)
		$InstallLog &= "API parsed tag: " & $CachedReleaseTag & @CRLF
	EndIf

	If $CachedReleaseTag = "" And Not _DownloadToolsUsesProxy() Then
		Local $JsDelivrBinary = _DownloadToolsReadUrl($ChromePlusJsDelivrVersionsUrl)
		Local $JsDelivrError = @error
		Local $JsDelivrJson = BinaryToString($JsDelivrBinary, 4)
		$InstallLog &= "jsDelivr versions InetRead @error: " & $JsDelivrError & ", bytes: " & BinaryLen($JsDelivrBinary) & ", text length: " & StringLen($JsDelivrJson) & @CRLF
		If $JsDelivrJson <> "" Then
			Local $VersionsMatch = StringRegExp($JsDelivrJson, '"versions"\s*:\s*\[([^\]]*)\]', 1)
			If Not @error And IsArray($VersionsMatch) Then
				Local $JsDelivrTags = StringRegExp($VersionsMatch[0], '"(v?\d+\.\d+\.\d+)"', 3)
				$CachedReleaseTag = GetLatestChromePlusStableTag($JsDelivrTags)
			EndIf
			$InstallLog &= "jsDelivr parsed tag: " & $CachedReleaseTag & @CRLF
		EndIf
	EndIf

	If $CachedReleaseTag = "" Then
		Local $LatestPageUrl = _UpgradeBuildGithubPageUrl("https://github.com/" & $ChromePlusRepo & "/releases/latest", GetEffectiveGithubDirectMirror())
		$InstallLog &= "Fallback latest page URL: " & $LatestPageUrl & @CRLF
		Local $LatestPageBinary = _DownloadToolsReadUrl($LatestPageUrl)
		Local $InetReadError = @error
		Local $LatestPage = BinaryToString($LatestPageBinary, 4)
		$InstallLog &= "Fallback InetRead @error: " & $InetReadError & ", bytes: " & BinaryLen($LatestPageBinary) & ", text length: " & StringLen($LatestPage) & @CRLF
		If $LatestPage <> "" Then
			Local $PageTags = StringRegExp($LatestPage, '/' & $ChromePlusRepo & '/releases/tag/([^"?/#<>]+)', 3)
			$CachedReleaseTag = GetLatestChromePlusStableTag($PageTags)
			$InstallLog &= "Fallback parsed tag: " & $CachedReleaseTag & @CRLF
		EndIf

		If Not _DownloadToolsUsesProxy() Then
			Local $GitCodeDiagnostic = ""
			Local $GitCodeJson = _DownloadToolsHttpGetTextDiagnostic($ChromePlusGitCodeTagsApiUrl, $ChromePlusApiUserAgent, "application/json", $GitCodeDiagnostic, $ChromePlusGitCodeTagsUrl)
			$InstallLog &= "GitCode tags fallback page: " & $ChromePlusGitCodeTagsUrl & @CRLF
			$InstallLog &= $GitCodeDiagnostic & @CRLF
			If $GitCodeJson <> "" Then
				Local $GitCodeTags = StringRegExp($GitCodeJson, '"name"\s*:\s*"([^"]+)"', 3)
				Local $GitCodeTag = GetLatestChromePlusStableTag($GitCodeTags)
				If $GitCodeTag <> "" And ($CachedReleaseTag = "" Or VersionCompare(NormalizeChromePlusVersionText($GitCodeTag), NormalizeChromePlusVersionText($CachedReleaseTag)) > 0) Then $CachedReleaseTag = $GitCodeTag
				$InstallLog &= "GitCode parsed tag: " & $CachedReleaseTag & @CRLF
			EndIf
		EndIf
	EndIf

	If $CachedArchiveUrl = "" And $CachedReleaseTag <> "" Then $CachedArchiveUrl = BuildChromePlusArchiveUrlFromTag($CachedReleaseTag)
	If $CachedArchiveUrl <> "" Then $InstallLog &= "Archive URL built from tag: " & $CachedArchiveUrl & @CRLF
	If $CachedReleaseTag = "" Or $CachedArchiveUrl = "" Then Return False

	$ReleaseTag = $CachedReleaseTag
	$ArchiveUrl = $CachedArchiveUrl
	SetChromePlusReleaseInfo($CachedReleaseTag, $CachedArchiveUrl)
	Return True
EndFunc   ;==>GetChromePlusReleaseInfo

Func GetLatestChromePlusStableTag($Tags)
	If Not IsArray($Tags) Then Return ""

	Local $LatestTag = "", $LatestVersion = ""
	For $i = 0 To UBound($Tags) - 1
		Local $Tag = StringStripWS($Tags[$i], 3)
		If Not StringRegExp($Tag, "(?i)^v?\d+\.\d+\.\d+$") Then ContinueLoop

		Local $Version = NormalizeChromePlusVersionText($Tag)
		If $LatestVersion = "" Or VersionCompare($Version, $LatestVersion) > 0 Then
			$LatestTag = $Tag
			$LatestVersion = $Version
		EndIf
	Next
	Return $LatestTag
EndFunc   ;==>GetLatestChromePlusStableTag

Func SetChromePlusReleaseInfo($ReleaseTag, $ArchiveUrl)
	$ChromePlusReleaseInfoLoaded = True
	$ChromePlusReleaseTag = $ReleaseTag
	$ChromePlusArchiveUrl = $ArchiveUrl
EndFunc   ;==>SetChromePlusReleaseInfo

Func BuildChromePlusArchiveUrlFromTag($ReleaseTag)
	Local $Version = StringRegExpReplace($ReleaseTag, "^[vV]", "")
	Return "https://github.com/" & $ChromePlusRepo & "/releases/download/" & $ReleaseTag & "/Chrome%2B%2B_v" & $Version & "_x86_x64_arm64.7z"
EndFunc   ;==>BuildChromePlusArchiveUrlFromTag

Func WriteChromePlusManagedConfig($ConfigPath)
	Local $ManagedHeader = "; Managed by RunFirefox for Chrome++"
	If FileExists($ConfigPath) Then
		Local $Existing = FileRead($ConfigPath)
		If StringLeft($Existing, StringLen($ManagedHeader)) <> $ManagedHeader Then Return True
	EndIf

	FileDelete($ConfigPath)
	Local $PreviousExpandEnvStrings = Opt("ExpandEnvStrings", 0)
	Local $Result = FileWrite($ConfigPath, BuildChromePlusManagedConfig($ConfigPath)) > 0
	Opt("ExpandEnvStrings", $PreviousExpandEnvStrings)
	Return $Result
EndFunc   ;==>WriteChromePlusManagedConfig

Func BuildChromePlusManagedConfig($ConfigPath)
	Return "; Managed by RunFirefox for Chrome++" & @CRLF & _
			"; Remove this header if you want to keep a fully custom chrome++.ini." & @CRLF & _
			"[general]" & @CRLF & _
			"data_dir=" & GetChromePlusPortablePath($ProfileDir, $ConfigPath) & @CRLF & _
			"cache_dir=" & GetChromePlusCachePath($ConfigPath) & @CRLF & _
			"command_line=" & @CRLF & _
			"launch_on_startup=" & @CRLF & _
			"launch_on_exit=" & @CRLF & _
			"boss_key=" & @CRLF & _
			"translate_key=" & @CRLF & _
			"show_password=0" & @CRLF & _
			"win32k=0" & @CRLF & _
			"ignore_policies=0" & @CRLF & _
			"suppress_false_upgrade_notification=1" & @CRLF & _
			@CRLF & _
			"[tabs]" & @CRLF & _
			"double_click_close=0" & @CRLF & _
			"right_click_close=1" & @CRLF & _
			"keep_last_tab=1" & @CRLF & _
			"wheel_tab=0" & @CRLF & _
			"wheel_tab_when_press_rbutton=0" & @CRLF & _
			"hover_tab=0" & @CRLF & _
			"hover_tab_delay=400" & @CRLF & _
			"open_url_new_tab=0" & @CRLF & _
			"open_bookmark_new_tab=0" & @CRLF & _
			"new_tab_disable=1" & @CRLF & _
			'new_tab_disable_name="about:blank","新建标签"' & @CRLF & _
			@CRLF & _
			"[keymapping]" & @CRLF
EndFunc   ;==>BuildChromePlusManagedConfig

Func WriteChromePlusPortablePaths($ConfigPath)
	Local $PreviousExpandEnvStrings = Opt("ExpandEnvStrings", 0)
	Local $Result = WriteIniTextValue($ConfigPath, "general", "data_dir", GetChromePlusPortablePath($ProfileDir, $ConfigPath))
	If $Result Then $Result = WriteIniTextValue($ConfigPath, "general", "cache_dir", GetChromePlusCachePath($ConfigPath))
	Opt("ExpandEnvStrings", $PreviousExpandEnvStrings)
	Return $Result
EndFunc   ;==>WriteChromePlusPortablePaths

Func GetChromePlusCachePath($ConfigPath)
	If $CustomCacheDir = "" Then Return "none"
	Return GetChromePlusPortablePath($CustomCacheDir, $ConfigPath)
EndFunc   ;==>GetChromePlusCachePath

Func GetChromePlusPortablePath($Path, $ConfigPath)
	Local $TargetPath = FullPath($Path)
	Local $BrowserDir, $ConfigFile
	SplitPath($ConfigPath, $BrowserDir, $ConfigFile)
	$BrowserDir = FullPath($BrowserDir)
	If StringRight($TargetPath, 1) = "\" Then $TargetPath = StringTrimRight($TargetPath, 1)
	If StringRight($BrowserDir, 1) = "\" Then $BrowserDir = StringTrimRight($BrowserDir, 1)

	Local $PortablePath = $TargetPath
	If StringLower(StringLeft($TargetPath, 3)) = StringLower(StringLeft($BrowserDir, 3)) Then
		Local $TargetParts = StringSplit($TargetPath, "\", 2)
		Local $BaseParts = StringSplit($BrowserDir, "\", 2)
		Local $i, $CommonCount = 0
		While $CommonCount < UBound($TargetParts) And $CommonCount < UBound($BaseParts)
			If StringLower($TargetParts[$CommonCount]) <> StringLower($BaseParts[$CommonCount]) Then ExitLoop
			$CommonCount += 1
		WEnd

		$PortablePath = "%app%"
		For $i = $CommonCount To UBound($BaseParts) - 1
			$PortablePath &= "\.."
		Next
		For $i = $CommonCount To UBound($TargetParts) - 1
			$PortablePath &= "\" & $TargetParts[$i]
		Next
	EndIf

	If StringInStr($PortablePath, " ") Then Return '"' & $PortablePath & '"'
	Return $PortablePath
EndFunc   ;==>GetChromePlusPortablePath

Func WriteChromePlusInstallLog($Content)
	If Not FileExists($ChromePlusCacheRoot) Then DirCreate($ChromePlusCacheRoot)

	Local $LogPath = $ChromePlusCacheRoot & "\chrome_plus_install.log"
	Local $hFile = FileOpen($LogPath, BitOR($FO_OVERWRITE, $FO_UTF8))
	If $hFile = -1 Then Return ""

	FileWrite($hFile, $Content)
	FileClose($hFile)
	Return $LogPath
EndFunc   ;==>WriteChromePlusInstallLog

Func ShowChromePlusPatchInstallFailedDialog($ErrorMessage, $LogPath)
	Local $Message = _t("ChromePlusPatchInstallFailedDetail", "Chrome++ 补丁安装失败：\n%s", $ErrorMessage)
	If $LogPath <> "" Then $Message &= @CRLF & @CRLF & _t("ChromePlusPatchLogSaved", "诊断日志已保存到：\n%s", $LogPath)

	Local $PreviousGuiMode = Opt("GUIOnEventMode", 0)
	Local $hDialog = GUICreate($AppName, 470, 220, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), -1, $hSettings)
	Local $idMessage = GUICtrlCreateEdit($Message, 15, 15, 440, 135, BitOR($ES_READONLY, $ES_MULTILINE, $WS_VSCROLL))
	Local $idViewLog = GUICtrlCreateButton(_t("ViewLog", "查看日志"), 255, 170, 90, 25)
	Local $idOK = GUICtrlCreateButton(_t("Confirm", "确定"), 365, 170, 90, 25)

	If $LogPath = "" Or Not FileExists($LogPath) Then GUICtrlSetState($idViewLog, $GUI_DISABLE)
	If $hSettings Then GUISetState(@SW_DISABLE, $hSettings)
	GUISetState(@SW_SHOW, $hDialog)

	Local $aMsg
	While 1
		$aMsg = GUIGetMsg(1)
		If IsArray($aMsg) And $aMsg[1] = $hDialog Then
			Switch $aMsg[0]
				Case $GUI_EVENT_CLOSE, $idOK
					ExitLoop
				Case $idViewLog
					If $LogPath <> "" And FileExists($LogPath) Then ShellExecute($LogPath)
			EndSwitch
		EndIf
		Sleep(20)
	WEnd

	GUIDelete($hDialog)
	If $hSettings Then GUISetState(@SW_ENABLE, $hSettings)
	Opt("GUIOnEventMode", $PreviousGuiMode)
EndFunc   ;==>ShowChromePlusPatchInstallFailedDialog





Func ShowCurrentChannel()
	If IsChromeBrowser(GetSelectedBrowserType()) Then Return
	Local $path = GUICtrlRead($idBrowserPath)
	If Not FileExists($path) Then Return
	Local $ChannelPath = StringRegExpReplace($path, "\\?[^\\]+$", "") & "\defaults\pref\channel-prefs.js"
	Local $var = FileRead($ChannelPath)
	Local $match = StringRegExp($var, '(?i)(?m)^\Qpref("app.update.channel",\E *"(.*)\Q");\E', 1)
	If @error Then Return
	$Channel = $match[0]
	If $Channel = "aurora" Then $Channel = "dev"
	_GUICtrlComboBox_SelectString($idChannel, $Channel)
EndFunc   ;==>ShowCurrentChannel

Func DownloadBrowser()
	Local $CurrentBrowserType = GetSelectedBrowserType()
	Local $os = "win64"
	If NormalizeBrowserType($CurrentBrowserType) = $BrowserUngoogledChromium Then
		Local $SelectedArch = StringLower(StringStripWS(GUICtrlRead($idBrowserBitness), 3))
		If $SelectedArch = "x86" Then $os = "win32"
		If $SelectedArch = "arm64" Then $os = "arm64"
	EndIf

	Local $ChannelString = GUICtrlRead($idChannel)
	Local $Channel = StringRegExpReplace($ChannelString, " *-.*", "")
	If IsDisplayedBrowserVersionUnavailable(GUICtrlRead($idBrowserDownloadLink)) And Not HasBrowserDownloadFallback($CurrentBrowserType, $Channel) Then
		Local $DownloadPageUrl = GetBrowserDownloadPageUrl($CurrentBrowserType, $Channel)
		If $DownloadPageUrl <> "" Then ShellExecute($DownloadPageUrl)
		Return
	EndIf

	Local $BrowserDownloadUrls = _BrowserDownloadBuildUrls($CurrentBrowserType, $Channel, $os)
	If @error Or Not IsArray($BrowserDownloadUrls) Or UBound($BrowserDownloadUrls) = 0 Then
		If NormalizeBrowserType($CurrentBrowserType) = $BrowserXunlei Then
			ShellExecute(_BrowserDownloadGetPageUrl($CurrentBrowserType, $Channel))
			Return
		EndIf
		_GUICtrlStatusBar_SetText($hStatus, _t("BrowserVersionLoadFailed", "读取浏览器版本失败。"))
		Return
	EndIf
	$BrowserDownloadUrl = $BrowserDownloadUrls[0]

	Local $TargetBrowserPath = FullPath(GUICtrlRead($idBrowserPath))
	Local $TargetDir, $TargetFile
	SplitPath($TargetBrowserPath, $TargetDir, $TargetFile)
	If $TargetDir = "" Or $TargetDir = "." Then $TargetDir = @ScriptDir

	If _BrowserDownloadBrowserExecutableExistsInDir($TargetDir, $CurrentBrowserType) Or _DownloadToolsIsDirectoryNotEmpty($TargetDir) Then
		Local $ConfirmOverwrite = _t("ConfirmOverwriteBrowserFiles", "目标目录已有浏览器文件或其他文件：\n%s\n\n是否继续下载并覆盖/合并文件？", $TargetDir)
		If MsgBox(36 + 256, $AppName, $ConfirmOverwrite, 0, $hSettings) <> 6 Then Return
	EndIf

	Local $DownloadedBrowserPath = _BrowserDownloadDownloadAndExtract($BrowserDownloadUrls, $TargetDir, $os, $Channel, $CurrentBrowserType, $hSettings)
	If @error Then
		Local $ErrorMessage = _t("BrowserDownloadFailed", "浏览器下载或解压失败：\n%s\n\n请检查网络和目标目录权限后重试。", $DownloadedBrowserPath)
		MsgBox(16, $AppName, $ErrorMessage, 0, $hSettings)
		Return
	EndIf

	$BrowserPath = RelativePath($DownloadedBrowserPath)
	GUICtrlSetData($idBrowserPath, $BrowserPath)
	OnBrowserPathChange()
	If IsChromePlusSupportedBrowser($CurrentBrowserType) And Not IsChromePlusPatchInstalled($DownloadedBrowserPath) Then
		Local $InstallChromePlusConfirm = _t("InstallChromePlusPatchAfterDownloadConfirm", "浏览器已下载并解压完成。\n\nChrome++ 为可选补丁，非必须安装。安装后可提供右键关闭标签页、书签在新标签页打开等功能。\n\n是否下载并安装 Chrome++ 补丁？")
		If UsesBundledChromePlus($DownloadedBrowserPath) Then $InstallChromePlusConfirm = _t("InstallBundledChromePlusConfirm", "浏览器已下载并解压完成。\n\nChrome++ 为可选补丁，可提供右键关闭标签页、书签在新标签页打开等功能。\n\n是否安装内置自编译版 Chrome++？无需联网下载。")
		If MsgBox(36 + 256, $AppName, $InstallChromePlusConfirm, 0, $hSettings) = 6 Then _
			InstallChromePlusPatchInteractive($DownloadedBrowserPath, $os)
	EndIf
	UpdateBrowserSpecificControls()
	_GUICtrlStatusBar_SetText($hStatus, _t("BrowserDownloadSuccess", "浏览器已下载并解压完成。"))
	Local $OpenDownloadedBrowserConfirm = _t("OpenDownloadedBrowserConfirm", "浏览器已下载并解压完成。\n是否马上打开浏览器？")
	If MsgBox(36 + 256, $AppName, $OpenDownloadedBrowserConfirm, 0, $hSettings) = 6 Then ConfirmSettings()
EndFunc   ;==>DownloadBrowser













Func ImportChromiumGoogleApi()
	If Not HasChromiumGoogleApi() Then
		MsgBox(48, "RunFirefox", _t("GoogleApiUnavailable", "当前构建未内置 Google API 密钥。请在 GitHub Actions secrets 中配置后重新构建。"), 0, $hSettings)
		Return
	EndIf
	Local $ApiKey = DecodeChromiumGoogleApiValue($ChromiumGoogleApiKeyPayload, $ChromiumGoogleApiKeyMask, $ChromiumGoogleApiKeyNonce)
	Local $ClientId = DecodeChromiumGoogleApiValue($ChromiumGoogleClientIdPayload, $ChromiumGoogleClientIdMask, $ChromiumGoogleClientIdNonce)
	Local $ClientSecret = DecodeChromiumGoogleApiValue($ChromiumGoogleClientSecretPayload, $ChromiumGoogleClientSecretMask, $ChromiumGoogleClientSecretNonce)
	If SetChromiumGoogleApiEnvironment($ApiKey, $ClientId, $ClientSecret) Then
		MsgBox(0, "RunFirefox", _t("GoogleApiImportSuccess", "导入GoogleAPI密钥成功"), 0, $hSettings)
	Else
		MsgBox(16, "RunFirefox", _t("GoogleApiEnvironmentUpdateFailed", "修改GoogleAPI环境变量失败。"), 0, $hSettings)
	EndIf
EndFunc   ;==>ImportChromiumGoogleApi

Func HasChromiumGoogleApi()
	Return DecodeChromiumGoogleApiValue($ChromiumGoogleApiKeyPayload, $ChromiumGoogleApiKeyMask, $ChromiumGoogleApiKeyNonce) <> "" And _
			DecodeChromiumGoogleApiValue($ChromiumGoogleClientIdPayload, $ChromiumGoogleClientIdMask, $ChromiumGoogleClientIdNonce) <> "" And _
			DecodeChromiumGoogleApiValue($ChromiumGoogleClientSecretPayload, $ChromiumGoogleClientSecretMask, $ChromiumGoogleClientSecretNonce) <> ""
EndFunc   ;==>HasChromiumGoogleApi

Func DecodeChromiumGoogleApiValue($Payload, $Mask, $Nonce)
	If $Payload = "" Or StringLen($Payload) <> StringLen($Mask) Or Mod(StringLen($Payload), 2) <> 0 Then Return ""
	If Not StringRegExp($Payload, "^[0-9A-F]+$") Or Not StringRegExp($Mask, "^[0-9A-F]+$") Then Return ""

	Local $DecodedHex = "0x"
	For $i = 0 To (StringLen($Payload) / 2) - 1
		Local $PayloadByte = Dec("0x" & StringMid($Payload, $i * 2 + 1, 2))
		Local $MaskByte = Dec("0x" & StringMid($Mask, $i * 2 + 1, 2))
		Local $IndexMask = BitAND($i * 149 + $Nonce, 0xFF)
		$DecodedHex &= Hex(BitXOR($PayloadByte, $MaskByte, $IndexMask), 2)
	Next
	Return BinaryToString(Binary($DecodedHex), 4)
EndFunc   ;==>DecodeChromiumGoogleApiValue

Func SuppressChromiumGoogleApiWarning()
	If SetChromiumGoogleApiEnvironment("no", "no", "no") Then
		MsgBox(0, "RunFirefox", _t("GoogleApiWarningSuppressSuccess", "清除GoogleAPI密钥提示成功"), 0, $hSettings)
	Else
		MsgBox(16, "RunFirefox", _t("GoogleApiEnvironmentUpdateFailed", "修改GoogleAPI环境变量失败。"), 0, $hSettings)
	EndIf
EndFunc   ;==>SuppressChromiumGoogleApiWarning

Func ClearChromiumGoogleApi()
	If DeleteChromiumGoogleApiEnvironment() Then
		MsgBox(0, "RunFirefox", _t("GoogleApiClearSuccess", "清除GoogleAPI密钥成功"), 0, $hSettings)
	Else
		MsgBox(16, "RunFirefox", _t("GoogleApiEnvironmentUpdateFailed", "修改GoogleAPI环境变量失败。"), 0, $hSettings)
	EndIf
EndFunc   ;==>ClearChromiumGoogleApi

Func SetChromiumGoogleApiEnvironment($ApiKey, $ClientId, $ClientSecret)
	Local $Result = True
	If Not SetUserEnvironmentValue($ChromiumGoogleApiKeyEnv, $ApiKey) Then $Result = False
	If Not SetUserEnvironmentValue($ChromiumGoogleClientIdEnv, $ClientId) Then $Result = False
	If Not SetUserEnvironmentValue($ChromiumGoogleClientSecretEnv, $ClientSecret) Then $Result = False
	NotifyEnvironmentChanged()
	Return $Result
EndFunc   ;==>SetChromiumGoogleApiEnvironment

Func DeleteChromiumGoogleApiEnvironment()
	Local $Result = True
	If Not DeleteUserEnvironmentValue($ChromiumGoogleApiKeyEnv) Then $Result = False
	If Not DeleteUserEnvironmentValue($ChromiumGoogleClientIdEnv) Then $Result = False
	If Not DeleteUserEnvironmentValue($ChromiumGoogleClientSecretEnv) Then $Result = False
	NotifyEnvironmentChanged()
	Return $Result
EndFunc   ;==>DeleteChromiumGoogleApiEnvironment

Func SetUserEnvironmentValue($Name, $Value)
	EnvSet($Name, $Value)
	Return RegWrite("HKCU\Environment", $Name, "REG_SZ", $Value) <> 0
EndFunc   ;==>SetUserEnvironmentValue

Func DeleteUserEnvironmentValue($Name)
	EnvSet($Name)
	RegDelete("HKCU\Environment", $Name)
	Return RegRead("HKCU\Environment", $Name) = "" And @error
EndFunc   ;==>DeleteUserEnvironmentValue

Func NotifyEnvironmentChanged()
	DllCall("user32.dll", "long_ptr", "SendMessageTimeoutW", "hwnd", 0xFFFF, "uint", 0x001A, "wparam", 0, "wstr", "Environment", "uint", 0x0002, "uint", 5000, "dword_ptr*", 0)
EndFunc   ;==>NotifyEnvironmentChanged

Func OnBackgroundModeChange()
	If GUICtrlRead($idBackgroundModeEnabled) = $GUI_CHECKED Then
		Return
	EndIf
	Local $msg = MsgBox(36 + 256, "RunFirefox", _t("RunInBackgroundMessage", '允许 RunFirefox 在后台运行可以带来更好的用户体验。若取消此选项，请注意以下几点：\n\n 1. 将浏览器锁定到任务栏或设为默认浏览器后，需再运行一次 RunFirefox 才能生效；\n2. RunFirefox 设置界面中带“#”符号的功能/选项将不会执行，包括浏览器退出后关闭外部程序、运行外部程序等。\n\n确定要取消此选项吗？'), 0, $hSettings)
	If $msg <> 6 Then
		GUICtrlSetState($idBackgroundModeEnabled, $GUI_CHECKED)
	EndIf
EndFunc   ;==>OnBackgroundModeChange

;~ 设置界面取消
Func ExitApp()
	Exit
EndFunc   ;==>ExitApp

;~ 设置界面确定按钮
Func ConfirmSettings()
	ApplySettings()
	If @error Then Return
	$SettingsConfirmed = 1
EndFunc   ;==>ConfirmSettings



;~ 设置界面应用按钮
Func ApplySettings()
	Local $msg, $var
	FileChangeDir(@ScriptDir)

	Opt("ExpandEnvStrings", 0)
	$BrowserPath = RelativePath(GUICtrlRead($idBrowserPath))
	ApplyDetectedBrowserTypeFromPath()
	$BrowserType = GetSelectedBrowserType()

	Local $SelectedProxyType = GetSelectedProxyType()
	Local $SelectedProxyServer = StringStripWS(GUICtrlRead($idProxyServer), 3)
	Local $SelectedProxyPortText = StringStripWS(GUICtrlRead($idProxyPort), 3)
	If $SelectedProxyType <> "direct" Then
		If Not _DownloadToolsHasCurl() Then
			MsgBox(16, "RunFirefox", _t("CurlRequiredForProxy", "HTTP 和 SOCKS5 代理需要 curl.exe。请安装 curl，或改用直接连接。"), 0, $hSettings)
			GUICtrlSetState($idProxyType, $GUI_FOCUS)
			Return SetError(1)
		EndIf
		If $SelectedProxyServer = "" Then
			MsgBox(16, "RunFirefox", _t("ProxyServerRequired", "使用代理时必须填写代理服务器。"), 0, $hSettings)
			GUICtrlSetState($idProxyServer, $GUI_FOCUS)
			Return SetError(1)
		EndIf
		If StringRegExp($SelectedProxyServer, '[\s"]') Then
			MsgBox(16, "RunFirefox", _t("ProxyServerInvalid", "代理服务器不能包含空白字符或双引号。"), 0, $hSettings)
			GUICtrlSetState($idProxyServer, $GUI_FOCUS)
			Return SetError(1)
		EndIf
		If Not StringRegExp($SelectedProxyPortText, "^\d+$") Or Number($SelectedProxyPortText) < 1 Or Number($SelectedProxyPortText) > 65535 Then
			MsgBox(16, "RunFirefox", _t("ProxyPortInvalid", "代理端口必须是 1-65535 之间的整数。"), 0, $hSettings)
			GUICtrlSetState($idProxyPort, $GUI_FOCUS)
			Return SetError(1)
		EndIf
	EndIf
	If _DownloadToolsHasCurl() Then
		Local $SelectedThreads = Int(GUICtrlRead($idDownloadThreads))
		If $SelectedThreads < 1 Or $SelectedThreads > 10 Then $SelectedThreads = 3
		$DownloadThreads = $SelectedThreads
	EndIf
	$ProxyType = $SelectedProxyType
	$ProxyServer = $SelectedProxyServer
	$ProxyPort = Int($SelectedProxyPortText)

	If GUICtrlRead($idAllowBrowserUpdate) = $GUI_CHECKED Then
		$AllowBrowserUpdate = 1
	Else
		$AllowBrowserUpdate = 0
	EndIf
	If IsChromeBrowser($BrowserType) And Not _BrowserAutoUpdateIsSupported($BrowserType) Then $AllowBrowserUpdate = 0
	$ProfileDir = RelativePath(GUICtrlRead($idProfileDir))
	$CustomPluginsDir = RelativePath(GUICtrlRead($idCustomPluginsDir))
	$CustomCacheDir = RelativePath(GUICtrlRead($idCustomCacheDir))
	$CacheSize = GUICtrlRead($idCacheSize)
	If GUICtrlRead($idCacheSizeSmart) = $GUI_CHECKED Then
		$CacheSizeSmart = 1
	Else
		$CacheSizeSmart = 0
	EndIf
	If IsChromeBrowser($BrowserType) Then $CacheSizeSmart = 0
	$var = GUICtrlRead($idParams)
	$var = StringStripWS($var, 3)
	$Params = StringReplace($var, @CRLF, " ") ; 换行符换成空格
	If GUICtrlRead($idChromiumDebugPortEnabled) = $GUI_CHECKED Then
		$ChromiumDebugPortEnabled = 1
	Else
		$ChromiumDebugPortEnabled = 0
	EndIf
	Local $DebugPortInput = StringStripWS(GUICtrlRead($idChromiumDebugPort), 3)
	Local $DebugPortValid = StringRegExp($DebugPortInput, "^\d+$") And Number($DebugPortInput) >= 1 And Number($DebugPortInput) <= 65535
	If IsChromeBrowser($BrowserType) And $ChromiumDebugPortEnabled Then
		If Not $DebugPortValid Then
			MsgBox(16, "RunFirefox", _t("ChromiumDebugPortInvalid", "CDP 调试端口必须是 1-65535 之间的整数。"), 0, $hSettings)
			GUICtrlSetState($idChromiumDebugPort, $GUI_FOCUS)
			Return SetError(1)
		EndIf
		If HasCustomCdpParameter($Params) Then
			MsgBox(16, "RunFirefox", _t("ChromiumDebugPortConflict", "自定义 CDP 调试端口设置与命令行参数中的远程调试参数冲突。请关闭此设置，或删除命令行参数中的 --remote-debugging-port / --remote-debugging-pipe。"), 0, $hSettings)
			GUICtrlSetState($idParams, $GUI_FOCUS)
			Return SetError(1)
		EndIf
	EndIf
	If $DebugPortValid Then
		$ChromiumDebugPort = Number($DebugPortInput)
	Else
		$ChromiumDebugPort = 9222
	EndIf
	If GUICtrlRead($idAppUpdateCheckEnabled) = $GUI_CHECKED Then
		$AppUpdateCheckEnabled = 1
	Else
		$AppUpdateCheckEnabled = 0
	EndIf
	$BrowserUpdateCheckMode = GetSelectedBrowserUpdateCheckMode()
	If GUICtrlRead($idBackgroundModeEnabled) = $GUI_CHECKED Then
		$BackgroundModeEnabled = 1
	Else
		$BackgroundModeEnabled = 0
	EndIf
	If IsBossKeySupportedBrowser($BrowserType) And GUICtrlRead($idBossKeyEnabled) = $GUI_CHECKED Then
		$BossKeyEnabled = 1
	Else
		$BossKeyEnabled = 0
	EndIf
	$BossKey = $BossKeyCaptureValue
	If GUICtrlRead($idBossKeyHideToTray) = $GUI_CHECKED Then
		$BossKeyHideToTray = 1
	Else
		$BossKeyHideToTray = 0
	EndIf
	Local $var = GUICtrlRead($idBrowserStartApps)
	$var = StringStripWS($var, 3)
	$var = StringReplace($var, @CRLF, "||")
	$var = StringRegExpReplace($var, "\|+\s*\|+", "\|\|")
	$BrowserStartApps = $var
	If GUICtrlRead($idCloseStartAppsAfterBrowserExit) = $GUI_CHECKED Then
		$CloseStartAppsAfterBrowserExit = 1
	Else
		$CloseStartAppsAfterBrowserExit = 0
	EndIf
	$var = GUICtrlRead($idBrowserExitApps)
	$var = StringStripWS($var, 3)
	$var = StringReplace($var, @CRLF, "||")
	$var = StringRegExpReplace($var, "\|+\s*\|+", "\|\|")
	$BrowserExitApps = $var

	IniWrite($inifile, "Settings", "CheckAppUpdate", $AppUpdateCheckEnabled)
	IniWrite($inifile, "Settings", "RunInBackground", $BackgroundModeEnabled)
	IniWrite($inifile, "Settings", "AllowBrowserUpdate", $AllowBrowserUpdate)
	IniWrite($inifile, "Settings", "BrowserUpdateCheckMode", $BrowserUpdateCheckMode)
	IniWrite($inifile, "Settings", "BrowserUpdateLastCheck", $BrowserUpdateLastCheck)
	IniWrite($inifile, "Settings", "BrowserType", $BrowserType)
	IniWrite($inifile, "Settings", "BrowserPath", $BrowserPath)
	IniWrite($inifile, "Settings", "ProfileDir", $ProfileDir)
	IniWrite($inifile, "Settings", "CustomPluginsDir", $CustomPluginsDir)
	IniWrite($inifile, "Settings", "CustomCacheDir", $CustomCacheDir)
	IniWrite($inifile, "Settings", "CacheSize", $CacheSize)
	IniWrite($inifile, "Settings", "CacheSizeSmart", $CacheSizeSmart)
	IniWrite($inifile, "Settings", "Params", $Params)
	IniWrite($inifile, "Settings", "ChromiumDebugPortEnabled", $ChromiumDebugPortEnabled)
	IniWrite($inifile, "Settings", "ChromiumDebugPort", $ChromiumDebugPort)
	IniWrite($inifile, "Settings", "BossKeyEnabled", $BossKeyEnabled)
	IniWrite($inifile, "Settings", "BossKey", $BossKey)
	IniWrite($inifile, "Settings", "BossKeyHideToTray", $BossKeyHideToTray)
	IniWrite($inifile, "Settings", "DownloadThreads", $DownloadThreads)
	IniWrite($inifile, "Settings", "ProxyType", $ProxyType)
	IniWrite($inifile, "Settings", "ProxyServer", $ProxyServer)
	IniWrite($inifile, "Settings", "ProxyPort", $ProxyPort)
	_DownloadToolsConfigure($DownloadThreads, $ProxyType, $ProxyServer, $ProxyPort)
	_BrowserDownloadConfigure($AppVersion, GetBrowserLocale("zh-CN"), GetEffectiveGithubDirectMirror(), GetEffectiveGithubJsDelivrMirror())
	$var = $BrowserStartApps
	If StringRegExp($var, '^".*"$') Then $var = '"' & $var & '"'
	IniWrite($inifile, "Settings", "ExApp", $var)
	IniWrite($inifile, "Settings", "ExAppAutoExit", $CloseStartAppsAfterBrowserExit)
	$var = $BrowserExitApps
	If StringRegExp($var, '^".*"$') Then $var = '"' & $var & '"'
	IniWrite($inifile, "Settings", "ExApp2", $var)

	Opt("ExpandEnvStrings", 1)

	; Browser path
	If Not FileExists($BrowserPath) Then
		MsgBox(16, "RunFirefox", _t("BrowserPathErrorMessage", "浏览器路径错误，请重新设置。\n\n%s", $BrowserPath), 0, $hSettings)
		GUICtrlSetState($idBrowserPath, $GUI_FOCUS)
		Return SetError(1)
	EndIf

	If IsMozillaBrowser($BrowserType) Then
		Local $ChannelString = GUICtrlRead($idChannel)
		Local $Channel = StringRegExpReplace($ChannelString, " -.*", "")
		Local $UpdateChannel = $Channel
		If $BrowserType = $BrowserZen Then
			$UpdateChannel = _BrowserDownloadGetZenUpdateChannel($Channel)
		ElseIf $UpdateChannel = "dev" Then
			; Firefox Developer Edition still uses aurora as the internal update channel.
			$UpdateChannel = "aurora"
		EndIf
		Local $ChannelPath = StringRegExpReplace($BrowserPath, "\\?[^\\]+$", "") & "\defaults\pref\channel-prefs.js"
		Local $var = FileRead($ChannelPath)
		Local $ChannelPrefs = '// Changed by RunFirefox' & @CRLF & 'pref("app.update.channel", "' & $UpdateChannel & '");' & @CRLF
		If $BrowserType = $BrowserZen Then
			$ChannelPrefs &= 'pref("app.update.url", "https://updates.zen-browser.app/updates/browser/%OS_VERSION%/%CHANNEL%/update.xml");' & @CRLF
		EndIf
		If Not StringInStr($var, 'pref("app.update.channel", "' & $UpdateChannel & '");') Or ($BrowserType = $BrowserZen And Not StringInStr($var, 'https://updates.zen-browser.app/updates/browser/')) Or ($BrowserType <> $BrowserZen And StringInStr($var, 'https://updates.zen-browser.app/updates/browser/')) Then
			FileDelete($ChannelPath)
			FileWrite($ChannelPath, $ChannelPrefs)
		EndIf
	ElseIf IsGoogleChromeBrowser($BrowserType) Then
		; Remember the channel so the startup update check queries the same one.
		Local $ChromeChannelString = GUICtrlRead($idChannel)
		$BrowserUpdateChannel = _BrowserDownloadNormalizeChromeChannel(StringRegExpReplace($ChromeChannelString, " -.*", ""))
		IniWrite($inifile, "Settings", "BrowserUpdateChannel", $BrowserUpdateChannel)
	EndIf

	;profiles dir
	If $ProfileDir = "" Then
		MsgBox(16, "RunFirefox", _t("PleaseProfileFolder", "请设置配置文件夹！"), 0, $hSettings)
		GUICtrlSetState($idProfileDir, $GUI_FOCUS)
		Return SetError(2)
	ElseIf Not FileExists($ProfileDir) Then
		DirCreate($ProfileDir)
	EndIf

	; 提取系统浏览器配置文件
	If GUICtrlRead($idCopyProfile) = $GUI_CHECKED Then
		$DefaultProfDir = GetSystemProfileSourceDir($BrowserType, GUICtrlRead($idChannel))
		Local $ShouldCopyProfile = ($DefaultProfDir <> "")
		While $ShouldCopyProfile
			If IsChromeBrowser($BrowserType) Then
				If Not ChromiumProfileInUse($DefaultProfDir) And Not ChromiumProfileInUse(FullPath($ProfileDir)) Then ExitLoop
			Else
				If Not ProfileInUse($DefaultProfDir) And Not ProfileInUse(FullPath($ProfileDir)) Then ExitLoop
			EndIf
			$msg = MsgBox(49, "RunFirefox", _t("CannotExtratProfileFromSystem", "浏览器正运行，无法提取配置文件！\n请关闭浏览器后继续。"), 0, $hSettings)
			If $msg <> 1 Then $ShouldCopyProfile = False
		WEnd
		If $ShouldCopyProfile Then
			SplashTextOn("RunFirefox", _t("ExtractingProfile", "正在提取配置文件，请稍候 ..."), 300, 100)
			If NormalizePathForCompare($DefaultProfDir) = NormalizePathForCompare(FullPath($ProfileDir)) Then
				$var = True
			Else
				$var = DirCopy($DefaultProfDir, $ProfileDir, 1)
			EndIf
			SplashOff()
			If $var Then
				_GUICtrlStatusBar_SetText($hStatus, _t("ExtractProfileSuccess", "提取配置文件成功！"))
			Else
				_GUICtrlStatusBar_SetText($hStatus, _t("ExtractProfileFailed", "提取配置文件失败！"))
			EndIf
		EndIf
		GUICtrlSetState($idCopyProfile, $GUI_UNCHECKED)
	EndIf

	; plugins dir
	If IsMozillaBrowser($BrowserType) And $CustomPluginsDir <> "" And Not FileExists($CustomPluginsDir) Then
		DirCreate($CustomPluginsDir)
	EndIf

	If Not SaveChromePlusTabsSettings($BrowserPath) Then
		MsgBox(16, "RunFirefox", _t("ChromePlusTabsSaveFailed", "保存 Chrome++ 标签页设置失败：\n%s", GetChromePlusConfigPath($BrowserPath)), 0, $hSettings)
		Return SetError(3)
	EndIf
EndFunc   ;==>ApplySettings

;~ 打开网站
Func Website()
	ShellExecute("https://github.com/benzBrake/RunFirefox")
EndFunc   ;==>Website

;~ 打开原版网站
Func OriginalWebsite()
	ShellExecute("https://github.com/cnjackchen/my-firefox")
EndFunc   ;==>Website

;~ 选择浏览器主程序
Func SelectBrowserExecutable()
	Local $ExecutableName = GetBrowserExecutableName(GetSelectedBrowserType())
	Local $path = FileOpenDialog(_t("ChooseBrowserExecutable", "选择浏览器主程序（%s）", $ExecutableName), @ScriptDir, _t("ExecutableFile", "可执行文件(*.exe)"), 1 + 2, $ExecutableName, $hSettings)
	FileChangeDir(@ScriptDir) ; FileOpenDialog 会改变 @workingdir，将它改回来
	If $path = "" Then Return
	$BrowserPath = RelativePath($path)
	GUICtrlSetData($idBrowserPath, $BrowserPath)
	OnBrowserPathChange()
EndFunc   ;==>SelectBrowserExecutable

;~ 指定配置文件夹
Func GetProfileDir()
	Local $dir = FileSelectFolder(_t("SpecifyProfileDirectory", "指定浏览器配置文件夹"), "", 1 + 4, @ScriptDir, $hSettings)
	FileChangeDir(@ScriptDir)
	If $dir = "" Then Return
	$ProfileDir = RelativePath($dir)
	GUICtrlSetData($idProfileDir, $ProfileDir)
EndFunc   ;==>GetProfileDir

;~ 指定插件目录
Func GetPluginsDir()
	Local $dir = FileSelectFolder(_t("SpecifyPluginsDirectory", "指定浏览器插件目录"), "", 1 + 4, @ScriptDir, $hSettings)
	FileChangeDir(@ScriptDir)
	If $dir = "" Then Return
	$CustomPluginsDir = RelativePath($dir)
	GUICtrlSetData($idCustomPluginsDir, $CustomPluginsDir)
EndFunc   ;==>GetPluginsDir

;~ 指定缓存位置
Func GetCacheDir()
	Local $dir = FileSelectFolder(_t("SpecifyCacheDirectory", "指定浏览器缓存文件夹"), "", 1 + 4, @ScriptDir, $hSettings)
	FileChangeDir(@ScriptDir)
	If $dir = "" Then Return
	$CustomCacheDir = RelativePath($dir)
	GUICtrlSetData($idCustomCacheDir, $CustomCacheDir)
EndFunc   ;==>GetCacheDir

;~ 判断配置文件是否正在使用
;~ 参考：http://kb.mozillazine.org/Profile_in_use
Func ProfileInUse($ProfDir)
	Return FileExists($ProfDir & "\parent.lock") And Not FileDelete($ProfDir & "\parent.lock")
EndFunc   ;==>ProfileInUse

;~ 函数。整理内存
;~ http://www.autoitscript.com/forum/index.php?showtopic=13399&hl=GetCurrentProcessId&st=20
Func ReduceMemory()
	Local $ai_Handle = DllCall("kernel32.dll", 'int', 'OpenProcess', 'int', 0x1f0fff, 'int', False, 'int', @AutoItPID)
	Local $ai_Return = DllCall("psapi.dll", 'int', 'EmptyWorkingSet', 'long', $ai_Handle[0])
	DllCall('kernel32.dll', 'int', 'CloseHandle', 'int', $ai_Handle[0])
	Return $ai_Return[0]
EndFunc   ;==>ReduceMemory

; #FUNCTION# ;===============================================================================
; 参考 http://www.autoitscript.com/forum/topic/63947-read-full-exe-path-of-a-known-windowprogram/
; Name...........: GetProcessPath
; Description ...: 取得进程路径
; Syntax.........: GetProcessPath($ProcessId)
; Parameters ....: $ProcessId - 进程 PID
; Return values .: Success - 完整路径
;                  Failure - set @error
;============================================================================================
Func GetProcessPath($ProcessId = @AutoItPID)
	If @OSArch <> "X86" And Not @AutoItX64 And Not _WinAPI_IsWow64Process($ProcessId) Then ; much slow than dllcall method
		Local $colItems = ""
		Local $objWMIService = ObjGet("winmgmts:\\localhost\root\CIMV2")
		$colItems = $objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE ProcessId = " & $ProcessId, "WQL", _
				0x10 + 0x20)
		If IsObj($colItems) Then
			For $objItem In $colItems
				If $objItem.ExecutablePath Then Return $objItem.ExecutablePath
			Next
		EndIf
		Return ""
	Else
		Local $hProcess = DllCall('kernel32.dll', 'ptr', 'OpenProcess', 'dword', BitOR(0x0400, 0x0010), 'int', 0, 'dword', $ProcessId)
		If (@error) Or (Not $hProcess[0]) Then Return SetError(1, 0, '')
		Local $ret = DllCall(@SystemDir & '\psapi.dll', 'int', 'GetModuleFileNameExW', 'ptr', $hProcess[0], 'ptr', 0, 'wstr', '', 'int', 1024)
		If (@error) Or (Not $ret[0]) Then Return SetError(1, 0, '')
		Return $ret[3]
	EndIf
EndFunc   ;==>GetProcessPath

; #FUNCTION# ====================================================================================================================
; Name...........: _GUICtrlComboBox_SelectString
; Description ...: Searches the ListBox of a ComboBox for an item that begins with the characters in a specified string
; Syntax.........: _GUICtrlComboBox_SelectString($hWnd, $sText[, $iIndex = -1])
; Parameters ....: $hWnd        - Handle to control
;                  $sText       - String that contains the characters for which to search
;                  $iIndex      - Specifies the zero-based index of the item preceding the first item to be searched
; Return values .: Success      - The index of the selected item
;                  Failure      - -1
; Author ........: Gary Frost (gafrost)
; Modified.......:
; Remarks .......: When the search reaches the bottom of the list, it continues from the top of the list back to the
;                  item specified by the wParam parameter.
;+
;                  If $iIndex is ?, the entire list is searched from the beginning.
;                  A string is selected only if the characters from the starting point match the characters in the
;                  prefix string
;+
;                  If a matching item is found, it is selected and copied to the edit control
; Related .......: _GUICtrlComboBox_FindString, _GUICtrlComboBox_FindStringExact, _GUICtrlComboBoxEx_FindStringExact
; Link ..........:
; Example .......: Yes
; ===============================================================================================================================
Func _GUICtrlComboBox_SelectString($hWnd, $sText, $iIndex = -1)
;~ 	If $Debug_CB Then __UDF_ValidateClassName($hWnd, $__COMBOBOXCONSTANT_ClassName)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)

	Return _SendMessage($hWnd, $CB_SELECTSTRING, $iIndex, $sText, 0, "wparam", "wstr")
EndFunc   ;==>_GUICtrlComboBox_SelectString


; #FUNCTION# ====================================================================================================================
; Name ..........: _IsUACAdmin
; Description ...: Determines if process has Admin privileges and whether running under UAC.
; Syntax ........: _IsUACAdmin()
; Parameters ....: None
; Return values .: Success          - 1 - User has full Admin rights (Elevated Admin w/ UAC)
;                  Failure          - 0 - User is not an Admin, sets @extended:
;                                   | 0 - User cannot elevate
;                                   | 1 - User can elevate
; Author ........: Erik Pilsits
; Modified ......:
; Remarks .......: THE GOOD STUFF: returns 0 w/ @extended = 1 > UAC Protected Admin
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _IsUACAdmin()
	If StringRegExp(@OSVersion, "_(XP|2003)") Or RegRead("HKLM64\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System", "EnableLUA") <> 1 Then
		Return SetExtended(0, IsAdmin())
	EndIf

	Local $hToken = _Security__OpenProcessToken(_WinAPI_GetCurrentProcess(), $TOKEN_QUERY)
	Local $tTI = _Security__GetTokenInformation($hToken, $TOKENGROUPS)
	_WinAPI_CloseHandle($hToken)

	Local $pTI = DllStructGetPtr($tTI)
	Local $cbSIDATTR = DllStructGetSize(DllStructCreate("ptr;dword"))
	Local $count = DllStructGetData(DllStructCreate("dword", $pTI), 1)
	Local $pGROUP1 = DllStructGetPtr(DllStructCreate("dword;STRUCT;ptr;dword;ENDSTRUCT", $pTI), 2)
	Local $tGROUP, $sGROUP = ""

	; S-1-5-32-544 > BUILTINAdministrators > $SID_ADMINISTRATORS
	; S-1-16-8192  > Mandatory LabelMedium Mandatory Level (Protected Admin) > $SID_MEDIUM_MANDATORY_LEVEL
	; S-1-16-12288 > Mandatory LabelHigh Mandatory Level (Elevated Admin) > $SID_HIGH_MANDATORY_LEVEL
	; SE_GROUP_USE_FOR_DENY_ONLY = 0x10

	Local $inAdminGrp = False, $denyAdmin = False, $elevatedAdmin = False, $sSID
	For $i = 0 To $count - 1
		$tGROUP = DllStructCreate("ptr;dword", $pGROUP1 + ($cbSIDATTR * $i))
		$sSID = _Security__SidToStringSid(DllStructGetData($tGROUP, 1))
		If StringInStr($sSID, "S-1-5-32-544") Then ; member of Administrators group
			$inAdminGrp = True
			; check for deny attribute
			If (BitAND(DllStructGetData($tGROUP, 2), 0x10) = 0x10) Then $denyAdmin = True
		ElseIf StringInStr($sSID, "S-1-16-12288") Then
			$elevatedAdmin = True
		EndIf
	Next

	If $inAdminGrp Then
		; check elevated
		If $elevatedAdmin Then
			; check deny status
			If $denyAdmin Then
				; protected Admin CANNOT elevate
				Return SetExtended(0, 0)
			Else
				; elevated Admin
				Return SetExtended(1, 1)
			EndIf
		Else
			; protected Admin
			Return SetExtended(1, 0)
		EndIf
	Else
		; not an Admin
		Return SetExtended(0, 0)
	EndIf
EndFunc   ;==>_IsUACAdmin

; Return $v1 - $v1
Func VersionCompare($v1, $v2)
	Local $i, $a1, $a2, $ret = 0
	$a1 = StringSplit($v1, ".", 2)
	$a2 = StringSplit($v2, ".", 2)
	If UBound($a1) > UBound($a2) Then
		ReDim $a2[UBound($a1)]
	Else
		ReDim $a1[UBound($a2)]
	EndIf
	For $i = 0 To UBound($a1) - 1
		$ret = $a1[$i] - $a2[$i]
		If $ret <> 0 Then ExitLoop
	Next
	Return $ret
EndFunc   ;==>VersionCompare


; https://www.autoitscript.com/forum/topic/73425-zipau3-udf-in-pure-autoit/
; https://www.autoitscript.com/forum/topic/116565-zip-udf-zipfldrdll-library/
; #FUNCTION# ====================================================================================================
; Name...........:  _Zip_UnzipAll
; Description....:  Extract all files contained in a ZIP archive
; Syntax.........:  _Zip_UnzipAll($sZipFile, $sDestPath[, $iFlag = 20])
; Parameters.....:  $sZipFile   - Full path to ZIP file
;                   $sDestPath  - Full path to the destination
;                   $iFlag      - [Optional] File copy flags (Default = 4+16)
;                               |   4 - No progress box
;                               |   8 - Rename the file if a file of the same name already exists
;                               |  16 - Respond "Yes to All" for any dialog that is displayed
;                               |  64 - Preserve undo information, if possible
;                               | 256 - Display a progress dialog box but do not show the file names
;                               | 512 - Do not confirm the creation of a new directory if the operation requires one to be created
;                               |1024 - Do not display a user interface if an error occurs
;                               |2048 - Version 4.71. Do not copy the security attributes of the file
;                               |4096 - Only operate in the local directory, don't operate recursively into subdirectories
;                               |8192 - Version 5.0. Do not copy connected files as a group, only copy the specified files
;
; Return values..:  Success     - 1
;                   Failure     - 0 and sets @error
;                               | 1 - zipfldr.dll does not exist
;                               | 2 - Library not installed
;                               | 3 - Not a full path
;                               | 4 - ZIP file does not exist
;                               | 5 - Failed to create destination (if necessary)
;                               | 6 - Failed to extract file(s)
; Author.........:  wraithdu, torels
; Modified.......:
; Remarks........:  Overwriting of destination files is controlled solely by the file copy flags (ie $iFlag = 1 is NOT valid).
; Related........:
; Link...........:
; Example........:
; ===============================================================================================================
Func _Zip_UnzipAll($sZipFile, $sDestPath, $flag = 20)
	If Not FileExists(@SystemDir & "\zipfldr.dll") Then Return SetError(1, 0, 0)
	If Not RegRead("HKCR\CLSID\{E88DCCE0-B7B3-11d1-A9F0-00AA0060FA31}", "") Then Return SetError(2, 0, 0)

	If Not StringInStr($sZipFile, ":\") Then Return SetError(3, 0) ;zip file isn't a full path
	If Not FileExists($sZipFile) Then Return SetError(4, 0, 0) ;no zip file
	If Not FileExists($sDestPath) Then
		DirCreate($sDestPath)
		If @error Then Return SetError(5, 0, 0)
	EndIf

	Local $aArray[1]
	$oApp = ObjCreate("Shell.Application")
	$oNs = $oApp.Namespace($sZipFile)
	$oApp.Namespace($sDestPath).CopyHere($oNs.Items, $flag)

	If FileExists($sDestPath & "\" & $oNs.Items().Item($oNs.Items().Count - 1).Name) Then
		; success... most likely
		; checks for existence of last item from source in destination
		Return 1
	Else
		; failure
		Return SetError(6, 0, 0)
	EndIf
EndFunc   ;==>_Zip_UnzipAll

; 切换自动更新状态
Func ChangeAutoUpdateStatus()

EndFunc

; 语言数据：内嵌 LangData.au3 为基底，exe 目录存在 LangCustom.ini 时按 key 覆盖合并
Func LoadLangData()
	Local $Data = LoadIniDictionaryFromText($g_sLangDataIni)
	Local $fileCustomPath = @ScriptDir & "\LangCustom.ini"
	If FileExists($fileCustomPath) Then
		Local $CustomData = LoadIniDictionaryFromTextFile($fileCustomPath)
		MergeIniDictionary($Data, $CustomData)
	EndIf
	Return $Data
EndFunc   ;==>LoadLangData

Func NormalizeLanguageName($sLanguage)
	$sLanguage = StringStripWS(StringReplace($sLanguage, "_", "-"), 3)
	If $sLanguage = "" Then Return ""

	Local $aParts = StringSplit($sLanguage, "-")
	If @error Or $aParts[0] = 0 Then Return $sLanguage

	Local $sNormalized = StringLower($aParts[1])
	For $i = 2 To $aParts[0]
		$sNormalized &= "-" & StringUpper($aParts[$i])
	Next

	Return $sNormalized
EndFunc   ;==>NormalizeLanguageName

Func GetWindowsLanguageName($sLanguageId)
	$sLanguageId = StringStripWS($sLanguageId, 3)
	If $sLanguageId = "" Then Return ""

	Local $iLCID = Dec($sLanguageId)
	If $iLCID > 0 Then
		Local $tLocale = DllStructCreate("wchar[85]")
		Local $aLocale = DllCall("kernel32.dll", "int", "LCIDToLocaleName", "dword", $iLCID, "ptr", DllStructGetPtr($tLocale), "int", 85, "dword", 0)
		If Not @error And IsArray($aLocale) And $aLocale[0] > 0 Then Return NormalizeLanguageName(DllStructGetData($tLocale, 1))
	EndIf

	Switch StringUpper($sLanguageId)
		Case "0409"
			Return "en-US"
		Case "0804", "1004"
			Return "zh-CN"
		Case "0404", "0C04", "1404"
			Return "zh-TW"
	EndSwitch

	Return ""
EndFunc   ;==>GetWindowsLanguageName

Func GetSupportedLanguage($sLanguage, $sDefaultLanguage = "")
	Local $sNormalizedLanguage = NormalizeLanguageName($sLanguage)
	If $sNormalizedLanguage = "" Or Not IsObj($LANGUAGES) Then Return $sDefaultLanguage

	Local $keys = $LANGUAGES.Keys
	For $i = 0 To UBound($keys) - 1
		If NormalizeLanguageName($keys[$i]) = $sNormalizedLanguage Then Return $keys[$i]
	Next

	Local $iSeparatorPos = StringInStr($sNormalizedLanguage, "-")
	If $iSeparatorPos = 0 Then Return $sDefaultLanguage

	Local $sPrimaryLanguage = StringLeft($sNormalizedLanguage, $iSeparatorPos - 1)
	For $i = 0 To UBound($keys) - 1
		Local $sSupportedLanguage = NormalizeLanguageName($keys[$i])
		If StringLeft($sSupportedLanguage & "-", StringLen($sPrimaryLanguage) + 1) = $sPrimaryLanguage & "-" Then Return $keys[$i]
	Next

	Return $sDefaultLanguage
EndFunc   ;==>GetSupportedLanguage

Func GetAutoLanguage()
	Local $sLanguage = GetSupportedLanguage(GetWindowsLanguageName(@MUILang))
	If $sLanguage Then Return $sLanguage

	$sLanguage = GetSupportedLanguage(GetWindowsLanguageName(@OSLang))
	If $sLanguage Then Return $sLanguage

	Return GetSupportedLanguage("zh-CN", "zh-CN")
EndFunc   ;==>GetAutoLanguage

; 获取语言支持
Func GetLanguages()
	Local $LDic = _InitDictionary()
	If IsObj($LANG_DATA) Then
		Local $langs = $LANG_DATA.Keys
		For $i = 0 To UBound($langs) - 1
			Local $title = ReadIniCacheValue($LANG_DATA, $langs[$i], "LangTitle", $langs[$i])
			_AddItem($LDic, $langs[$i], $title)
		Next
	EndIf
	If _ItemExists($LDic, "zh-CN") = False Then
		_AddItem($LDic, "zh-CN", "简体中文");
	EndIf
	Return $LDic
EndFunc

; 获取翻译文本
Func _t($key, $defaultString, $replaceString = "")
	local $str = $defaultString;
	If IsObj($LANG_DATA) Then
		If $LANGUAGE <> "zh-CN" Then
			$str = ReadIniCacheValue($LANG_DATA, $LANGUAGE, $key, $defaultString)
		Else
			$str = $defaultString
		EndIf
	EndIf
	$str = StringReplace($str, "{AppName}", $AppName)
	$str = StringReplace($str, "{ScriptName}", @ScriptName)
	If ($replaceString <> "") Then
		$str = StringFormat($str, $replaceString)
	EndIf
	Return StringReplace($str, "\n", @CRLF) ; 换行符号处理
EndFunc   ;==>_t

; 更换语言 Thanks MyChrome
Func ChangeLanguage()
	$newLang = SaveLang();
	If $newLang <> $LANGUAGE Then
		$LANGUAGE = $newLang
		MsgBox(64, $AppName, _t("RestartToApplyLanguage", "语言设置将在重启 {AppName} 后生效"))
		GUIDelete($hSettings)
		If @Compiled Then
			ShellExecute(@ScriptName, "-Set", @ScriptDir)
		Else
			ShellExecute(@AutoItExe, '"' & @ScriptFullPath & '" -Set', @ScriptDir)
		EndIf
	EndIf
EndFunc   ;==>ChangeLanguage
; 保存语言
Func SaveLang()
	local $slang = GUICtrlRead($idLanguage), $index = -1, $keys = $LANGUAGES.Keys, $newLang = ""
	For $i = 0 To UBound($keys) - 1
		Local $key = $keys[$i]
		if _Item($LANGUAGES, $key) = $sLang Then
			$index = $i
		EndIf
	Next

	If ($index <> -1) Then
		$newLang = $keys[$index]
		IniWrite($inifile, "Settings", "Language", $newLang)
	EndIf
	Return $newLang
EndFunc   ;==>SaveLang
