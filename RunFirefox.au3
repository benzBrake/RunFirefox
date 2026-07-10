#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icons\Firefox.ico
#AutoIt3Wrapper_Outfile=RunFirefox.exe
#AutoIt3Wrapper_Outfile_x64=RunFirefox_x64.exe
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Comment=Firefox Portable
#AutoIt3Wrapper_Res_Description=Firefox Portable
#AutoIt3Wrapper_Res_Fileversion=2.8.11.0
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
	自定义Firefox程序和配置文件夹的路径，用来制作Firefox便携版，便携版可设为默认浏览器。
#ce

#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <EditConstants.au3>
#include <GuiStatusBar.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ComboConstants.au3>
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
#include "libs\_String.au3"
#include "libs\AppUserModelId.au3"
#include "libs\Polices.au3"
#include "libs\ScriptingDictionary.au3"
#include "libs\JSON.au3"
#include "libs\UpgradeHelper.au3"
#include "libs\PathUtils.au3"
#include "libs\TextIni.au3"
#include "libs\MozLz4.au3"

Opt("GUIOnEventMode", 1)
Opt("WinTitleMatchMode", 4)

Global Const $CustomArch = "RunFirefox"
Global Const $AppVersion = "2.8.11"
Global Const $FirefoxVersionUrl = "https://product-details.mozilla.org/1.0/firefox_versions.json"
Global Const $ChromeUpdateUrl = "https://tools.google.com/service/update2"
Global Const $ChromeUpdateUserAgent = "Google Update/1.3.32.7;winhttp;cup-ecdsa"
Global Const $ChromePlusRepo = "Bush2021/chrome_plus"
Global Const $ChromePlusLatestApiUrl = "https://api.github.com/repos/" & $ChromePlusRepo & "/releases/latest"
Global Const $ChromePlusGitCodeTagsUrl = "https://gitcode.com/gh_mirrors/ch/chrome_plus/tags"
Global Const $ChromePlusGitCodeTagsApiUrl = "https://web-api.gitcode.com/api/v2/projects/gh_mirrors%2Fch%2Fchrome_plus/repository/tags?order_by=committed&sort=desc&repoId=gh_mirrors%252Fch%252Fchrome_plus&page=1&per_page=10"
Global Const $ChromePlusApiUserAgent = "RunFirefox/" & $AppVersion
Global Const $ChromePlusCacheRoot = @TempDir & "\RunFirefox_ChromePlus"
Global Const $ChromiumGoogleApiKeyEnv = "GOOGLE_API_KEY"
Global Const $ChromiumGoogleClientIdEnv = "GOOGLE_DEFAULT_CLIENT_ID"
Global Const $ChromiumGoogleClientSecretEnv = "GOOGLE_DEFAULT_CLIENT_SECRET"
Global Const $ChromiumGoogleApiKey = ""
Global Const $ChromiumGoogleClientId = ""
Global Const $ChromiumGoogleClientSecret = ""
Global Const $BrowserFirefox = "firefox"
Global Const $BrowserZen = "zen"
Global Const $BrowserFloorp = "floorp"
Global Const $BrowserWaterfox = "waterfox"
Global Const $BrowserChrome = "chrome"
Global Const $BrowserHelium = "helium"
Global Const $BrowserWhale = "whale"
Global Const $BrowserCent = "cent"
Global Const $BrowserVivaldi = "vivaldi"
Global Const $ZenUpdateBaseUrl = "https://updates.zen-browser.app/updates/browser/WINNT_x86_64-msvc-x64"
Global Const $FloorpRepo = "Floorp-Projects/Floorp"
Global Const $FloorpLatestReleaseUrl = "https://github.com/" & $FloorpRepo & "/releases/latest"
Global Const $FloorpWindowsX64Asset = "floorp-windows-x86_64.installer.exe"
Global Const $WaterfoxDownloadPageUrl = "https://www.waterfox.com/download/"
Global Const $HeliumRepo = "imputnet/helium-windows"
Global Const $HeliumLatestReleaseUrl = "https://github.com/" & $HeliumRepo & "/releases/latest"
Global Const $WhaleStandaloneX64Url = "https://installer-whale.pstatic.net/downloads/sa_installers/WhaleSetupX64.exe"
Global Const $CentBrowserDownloadPageUrl = "https://www.centbrowser.com/"
Global Const $VivaldiDownloadPageUrl = "https://vivaldi.com/download/"
Global $FirstRun = 0, $FirstLaunch = 0, $FirefoxExe, $FirefoxDir, $isZotero = false
Global $TaskBarDir = @AppDataDir & "\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
Global $AppPID, $TaskBarLastChange
Global $AllowBrowserUpdate, $CheckAppUpdate, $AppUpdateLastCheck, $RunInBackground, $BrowserType, $FirefoxPath, $ProfileDir
Global $BrowserUpdateCheckMode, $BrowserUpdateLastCheck
Global $CustomPluginsDir, $CustomCacheDir, $CacheSize, $CacheSizeSmart, $CheckDefaultBrowser, $Params
Global $ExApp, $ExAppAutoExit, $ExApp2
Global $BossKeyEnabled, $BossKey, $BossKeyHideToTray, $BossKeyBrowserHidden = 0, $BossKeyTrayVisible = 0
Global $GithubDirectMirror, $GithubJsDelivrMirror

Global $DefaultProfDir, $hSettings, $hFirefoxPath, $hProfileDir, $hlanguage
Global $hCopyProfile, $hCustomPluginsDir, $hGetPluginsDir
Global $hCustomCacheDir, $hGetCacheDir, $hCacheSize, $hCacheSizeSmart
Global $hParams, $hStatus, $SettingsOK
Global $hAllowBrowserUpdate, $hCheckAppUpdate, $hRunInBackground, $hBrowserType, $hChannel, $hDownloadFirefox64, $FirefoxURL
Global $hBrowserBitness, $hBrowserUpdateCheckMode, $hCurrentBrowserVersion, $hWaterfoxVersionHint, $hBrowserDownloadNow
Global $hChromePlusHint, $hChromePlusDownloadPatch, $hChromePlusConfigPath, $hChromePlusCurrentVersion, $hChromePlusLatestVersion, $hChromePlusDoubleClickClose, $hChromePlusRightClickClose, $hChromePlusKeepLastTab
Global $hChromePlusWheelTab, $hChromePlusWheelTabWhenPressRButton, $hChromePlusOpenUrlNewTab, $hChromePlusOpenBookmarkNewTab
Global $hChromePlusNewTabDisable, $hChromePlusNewTabDisableName, $hChromePlusNewTabDisableNameLabel
Global $hChromiumGoogleApiImport, $hChromiumGoogleApiSuppress, $hChromiumGoogleApiClear
Global $LANG_DATA
Global $FirefoxVersionsObj = 0
Global $ZenReleaseUpdateXml = "", $ZenTwilightUpdateXml = ""
Global $FloorpReleaseInfoLoaded = False, $FloorpReleaseTag = ""
Global $WaterfoxReleaseInfoLoaded = False, $WaterfoxReleaseVersion = ""
Global $HeliumReleaseInfoLoaded = False, $HeliumReleaseTag = ""
Global $CentReleaseInfoLoaded = False, $CentReleaseVersion = "", $CentDownloadUrl = ""
Global $VivaldiReleaseInfoLoaded = False, $VivaldiReleaseVersion = "", $VivaldiDownloadUrl = ""
Global $ChromePlusReleaseInfoLoaded = False, $ChromePlusReleaseTag = "", $ChromePlusArchiveUrl = ""
Global $ChromeStableVersion = "", $ChromeStableDownloadUrl = "", $ChromeBetaVersion = "", $ChromeBetaDownloadUrl = "", $ChromeDevVersion = "", $ChromeDevDownloadUrl = "", $ChromeCanaryVersion = "", $ChromeCanaryDownloadUrl = ""
Global $BrowserVersionLoadHandle = 0, $BrowserVersionLoadFile = "", $BrowserVersionLoadBrowserType = "", $BrowserVersionLoadChannel = "", $BrowserVersionLoadKind = "", $BrowserVersionLoadAnim = 0
Global $ChromePlusVersionLoadHandle = 0, $ChromePlusVersionLoadFile = "", $ChromePlusVersionLoadAnim = 0
Global $AppUpdateCheckHandle = 0, $AppUpdateCheckFile = ""
Global $hDownloadProgress, $hDownloadProgressStatus, $hDownloadProgressDetail, $hDownloadProgressBar, $hDownloadProgressCancel
Global $DownloadProgressCancelled = 0, $DownloadProgressCanCancel = 0
Global $DownloadProgressPreviousGuiMode = -1
Global $hExApp, $hExAppAutoExit, $hExApp2
Global $hBossKeyEnabled, $hBossKey, $hBossKeyHideToTray, $BossKeyCaptureValue = "", $BossKeyHotkeyProc = 0, $BossKeyInputWndProc = 0, $BossKeyKeys = 0
Global $aExApp, $aExApp2, $aExAppPID[2]

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
$ScriptNameWithOutSuffix = StringRegExpReplace(@ScriptName, "\.[^.]*$", "")
$inifile = @ScriptDir & "\" & $ScriptNameWithOutSuffix & ".ini"
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
	IniWrite($inifile, "Settings", "FirefoxPath", ".\Firefox\firefox.exe")
	IniWrite($inifile, "Settings", "ProfileDir", ".\profiles")
	IniWrite($inifile, "Settings", "CustomPluginsDir", "")
	IniWrite($inifile, "Settings", "CustomCacheDir", "")
	IniWrite($inifile, "Settings", "CacheSize", "")
	IniWrite($inifile, "Settings", "CacheSizeSmart", 1)
	IniWrite($inifile, "Settings", "CheckDefaultBrowser", 1)
	IniWrite($inifile, "Settings", "Params", "")
	IniWrite($inifile, "Settings", "ExApp", "")
	IniWrite($inifile, "Settings", "ExAppAutoExit", 1)
	IniWrite($inifile, "Settings", "ExApp2", "")
	IniWrite($inifile, "Settings", "BossKeyEnabled", 0)
	IniWrite($inifile, "Settings", "BossKey", "^`")
	IniWrite($inifile, "Settings", "BossKeyHideToTray", 0)
	IniWrite($inifile, "Settings", "LastPlatformDir", "")
	IniWrite($inifile, "Settings", "LastProfileDir", "")
EndIf

$CheckAppUpdate = IniRead($inifile, "Settings", "CheckAppUpdate", 1) * 1
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
$RunInBackground = IniRead($inifile, "Settings", "RunInBackground", 1) * 1
$BrowserType = NormalizeBrowserType(IniRead($inifile, "Settings", "BrowserType", $BrowserFirefox))
$FirefoxPath = IniRead($inifile, "Settings", "FirefoxPath", ".\Firefox\firefox.exe")
$ProfileDir = IniRead($inifile, "Settings", "ProfileDir", ".\profiles")
$CustomPluginsDir = IniRead($inifile, "Settings", "CustomPluginsDir", "")
$CustomCacheDir = IniRead($inifile, "Settings", "CustomCacheDir", "")
$CacheSize = IniRead($inifile, "Settings", "CacheSize", "")
$CacheSizeSmart = IniRead($inifile, "Settings", "CacheSizeSmart", 1) * 1
$CheckDefaultBrowser = IniRead($inifile, "Settings", "CheckDefaultBrowser", 1) * 1
$Params = IniRead($inifile, "Settings", "Params", "")
$ExApp = IniRead($inifile, "Settings", "ExApp", "")
$ExAppAutoExit = IniRead($inifile, "Settings", "ExAppAutoExit", 1) * 1
$ExApp2 = IniRead($inifile, "Settings", "ExApp2", "")
$BossKeyEnabled = IniRead($inifile, "Settings", "BossKeyEnabled", 0) * 1
$BossKey = IniRead($inifile, "Settings", "BossKey", "^`")
$BossKeyHideToTray = IniRead($inifile, "Settings", "BossKeyHideToTray", 0) * 1
$LastPlatformDir = IniRead($inifile, "Settings", "LastPlatformDir", "")
$LastProfileDir = IniRead($inifile, "Settings", "LastProfileDir", "")
$LANGUAGE = IniRead($inifile, "Settings", "Language", "")
$LANG_FILE = GetLangFile()
$LANG_DATA = LoadIniDictionaryFromTextFile($LANG_FILE)
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

If $CmdLine[0] >= 4 And $CmdLine[1] = "--load-chrome-version" Then
	WriteChromeUpdateInfoFile($CmdLine[2], $CmdLine[3], $CmdLine[4])
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
If ($cmdline[0] = 1 And $cmdline[1] = "-set") Or $FirstRun Or Not FileExists($FirefoxPath) Or Not FileExists($ProfileDir) Then
	CreateSettingsShortcut(@ScriptDir & "\" & $ScriptNameWithOutSuffix & ".vbs")
	Settings()
EndIf

;~ 转换成绝对路径
$FirefoxPath = FullPath($FirefoxPath)
SplitPath($FirefoxPath, $FirefoxDir, $FirefoxExe)
$ProfileDir = FullPath($ProfileDir)

If IsMozillaBrowser($BrowserType) And $FirefoxExe = "zotero.exe" Then
	$isZotero = True
EndIf

If IsMozillaBrowser($BrowserType) Then
	;~ 创建禁止检查默认浏览器策略，使用 RunFirefox 后检测默认浏览器结果不准确
	UpdatePolices($FirefoxDir, "DontCheckDefaultBrowser", true)

	;~ 创建禁用自动更新策略
	UpdatePolices($FirefoxDir, "DisableAppUpdate", $AllowBrowserUpdate == 0)
EndIf

If IsAdmin() And $cmdline[0] = 1 And $cmdline[1] = "-SetDefaultGlobal" Then
	CheckDefaultBrowser($FirefoxPath)
	Exit
EndIf

;~ 插件目录
If IsMozillaBrowser($BrowserType) And $CustomPluginsDir <> "" Then
	$CustomPluginsDir = FullPath($CustomPluginsDir)
	EnvSet("MOZ_PLUGIN_PATH", $CustomPluginsDir) ; 设置环境变量
EndIf

;~ 给带空格的外部参数加上引号。
For $i = 1 To $cmdline[0]
	If StringInStr($cmdline[$i], " ") Then
		$Params &= ' "' & $cmdline[$i] & '"'
	Else
		$Params &= ' ' & $cmdline[$i]
	EndIf
Next

Local $BrowserIsRunning = AppIsRunning($FirefoxPath)
If IsChromePlusSupportedBrowser($BrowserType) And Not $BrowserIsRunning Then MaybeInstallChromePlusPatch($FirefoxPath)
If IsMozillaBrowser($BrowserType) Then
	DeleteMozillaLaunchOnLoginEntry($FirefoxPath)
	DeleteMozillaPrivateBrowsingShortcut()
	FileDelete($FirefoxDir & "\defaults\pref\runfirefox.js")
	$BrowserIsRunning = ProfileInUse($ProfileDir)
	If Not $BrowserIsRunning Then
		Local $config = CheckPrefs()
		If $config Then
			FileWrite($FirefoxDir & "\defaults\pref\runfirefox.js", $config)
		EndIf
	EndIf
EndIf

;~ Fix Addons not Found
If IsMozillaBrowser($BrowserType) And ($LastPlatformDir <> $FirefoxDir Or $LastProfileDir <> $ProfileDir) Then
	UpdateAddonStarup()
	UpdateExtensionsJson()
EndIf

;~ Start browser
$BaseParams = BuildBrowserLaunchParams($BrowserType)
$AppPID = Run('"' & $FirefoxPath & '" ' & $BaseParams & $Params , $FirefoxDir)
If IsMozillaBrowser($BrowserType) Then WaitAndDeleteMozillaLaunchOnLoginEntry($FirefoxPath)

FileChangeDir(@ScriptDir)
CreateSettingsShortcut(@ScriptDir & "\" & $ScriptNameWithOutSuffix & ".vbs")

If $BrowserIsRunning Then
	$exe = StringRegExpReplace(@AutoItExe, ".*\\", "")
	$list = ProcessList($exe)
	For $i = 1 To $list[0][0]
		If $list[$i][1] <> @AutoItPID And GetProcPath($list[$i][1]) = @AutoItExe Then
			Exit ;exit if another instance of myfirefox is running
		EndIf
	Next
EndIf

; Start external apps
If $ExApp <> "" Then
	$aExApp = StringSplit($ExApp, "||", 1)
	ReDim $aExAppPID[$aExApp[0] + 1]
	$aExAppPID[0] = $aExApp[0]
	For $i = 1 To $aExApp[0]
		$match = StringRegExp($aExApp[$i], '^"(.*?)" *(.*)', 1)
		If @error Then
			$file = $aExApp[$i]
			$args = ""
		Else
			$file = $match[0]
			$args = $match[1]
		EndIf
		$file = FullPath($file)
		$aExAppPID[$i] = ProcessExists(StringRegExpReplace($file, '.*\\', ''))
		If Not $aExAppPID[$i] And FileExists($file) Then
			$aExAppPID[$i] = ShellExecute($file, $args, StringRegExpReplace($file, '\\[^\\]+$', ''))
		EndIf
	Next
EndIf

If $CheckDefaultBrowser Then
	CheckDefaultBrowser($FirefoxPath)
EndIf

Local $BrowserWindowClass = GetBrowserWindowClass($BrowserType)
WinWait("[REGEXPCLASS:(?i)" & $BrowserWindowClass & "]", "", GetBrowserWindowWait($BrowserType))
$hWnd_browser = GethWndbyPID($AppPID, $BrowserWindowClass)

Global $AppUserModelId
If FileExists($TaskBarDir) Then ; win 7+
	$AppUserModelId = _WindowAppId($hWnd_browser)
	CheckPinnedPrograms($FirefoxPath)
EndIf

;~ Check myfirefox update
If $CheckAppUpdate And _DateDiff("h", $AppUpdateLastCheck, _NowCalc()) >= 48 Then
	CheckAppUpdate()
EndIf

If Not $RunInBackground Then
	Exit
EndIf
; ========================= app ended if not run in background ================================

If $CheckDefaultBrowser Then ; register REG for notification
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

; wait for firefox exit
$AppIsRunning = 0
While 1
	Sleep(500)

	If $hWnd_browser Then
		$AppIsRunning = WinExists($hWnd_browser)
	Else ; ProcessExists() is resource consuming than WinExists()
		$AppIsRunning = ProcessExists($AppPID)
	EndIf

	If Not $AppIsRunning Then
		; check other browser instance
		$AppPID = AppIsRunning($FirefoxPath)
		If Not $AppPID Then
			ExitLoop
		EndIf
		$AppIsRunning = 1
		$hWnd_browser = GethWndbyPID($AppPID, $BrowserWindowClass)
	EndIf

	If $TaskBarLastChange Then
		CheckPinnedPrograms($FirefoxPath)
	EndIf

	If $hEvent And Not _WinAPI_WaitForSingleObject($hEvent, 0) Then
		; MsgBox(0, "", "Reg changed!")
		Sleep(500)
		CheckDefaultBrowser($FirefoxPath)
		For $i = 0 To UBound($fReg) - 1
			If $fReg[$i][2] Then
				_WinAPI_RegNotifyChangeKeyValue($fReg[$i][2], $REG_NOTIFY_CHANGE_LAST_SET, 1, 1, $hEvent)
			EndIf
		Next
	EndIf
WEnd

If $ExAppAutoExit And $ExApp <> "" Then
	$cmd = ''
	For $i = 1 To $aExAppPID[0]
		If Not $aExAppPID[$i] Then ContinueLoop
		$cmd &= ' /PID ' & $aExAppPID[$i]
	Next
	If $cmd Then
		$cmd = 'taskkill' & $cmd & ' /T /F'
		Run(@ComSpec & ' /c ' & $cmd, '', @SW_HIDE)
	EndIf
EndIf

; Start external apps
If $ExApp2 <> "" Then
	$aExApp2 = StringSplit($ExApp2, "||")
	For $i = 1 To $aExApp2[0]
		$match = StringRegExp($aExApp2[$i], '^"(.*?)" *(.*)', 1)
		If @error Then
			$file = $aExApp2[$i]
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

Func AppIsRunning($AppPath)
	Local $exe = StringRegExpReplace($AppPath, '.*\\', '')
	Local $list = ProcessList($exe)
	For $i = 1 To $list[0][0]
		If StringInStr(GetProcPath($list[$i][1]), $AppPath) Then
			Return $list[$i][1]
		EndIf
	Next
	Return 0
EndFunc   ;==>AppIsRunning


Func GethWndbyPID($pid, $class = "")
	$list = WinList("[REGEXPCLASS:(?i)" & $class & "]")
	For $i = 1 To $list[0][0]
		If Not BitAND(WinGetState($list[$i][1]), 2) Then ContinueLoop ; ignore hidden windows
		If $pid = WinGetProcess($list[$i][1]) Then
			;ConsoleWrite("--> " & $list[$i][1] & "-" & $list[$i][0] & @CRLF)
			Return $list[$i][1]
		EndIf
	Next
EndFunc   ;==>GethWndbyPID

Func RegisterBossKeyHotKey()
	If Not $BossKeyEnabled Or $BossKey = "" Then Return
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

	Local $ProcPath = GetProcPath($pid)
	If $ProcPath = "" Then Return False
	Return NormalizePathForCompare($ProcPath) = NormalizePathForCompare($FirefoxPath)
EndFunc   ;==>IsOwnedBrowserWindow

Func ShowBossKeyTrayIcon()
	Opt("TrayAutoPause", 0)
	Opt("TrayMenuMode", 3)
	Opt("TrayOnEventMode", 1)
	TraySetIcon($FirefoxPath)
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
	IniWrite($inifile, "Settings", "LastPlatformDir", $FirefoxDir)
	IniWrite($inifile, "Settings", "LastProfileDir", $ProfileDir)
EndFunc   ;==>OnExit


;~ 查检 RunFirefox更新
Func CheckAppUpdate()
	Local $latestVersion, $releaseNotes
	If Not GetAvailableAppUpdate($latestVersion, $releaseNotes) Then Return
	PromptAndApplyAppUpdate($latestVersion, $releaseNotes)
EndFunc   ;==>CheckAppUpdate

Func GetAvailableAppUpdate(ByRef $latestVersion, ByRef $releaseNotes)
	Local $AppUpdateLastCheck, $repo = 'benzBrake/RunFirefox', $MirrorAddress = $GithubDirectMirror
	$MirrorAddress = _UpgradeNormalizeMirrorAddress($MirrorAddress)
	$AppUpdateLastCheck = _NowCalc()
	IniWrite($inifile, "Settings", "AppUpdateLastCheck", $AppUpdateLastCheck)

	HttpSetProxy(0) ; Use IE defaults for proxy
	$latestVersion = GetLatestReleaseVersion($repo, $MirrorAddress, $GithubJsDelivrMirror);
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
	Local $repo = 'benzBrake/RunFirefox', $downloadUrl, $MirrorAddress = $GithubDirectMirror, $msg, $file, $FileName
	$MirrorAddress = _UpgradeNormalizeMirrorAddress($MirrorAddress)
	$UpdateAvailable = _t("UpdateAvailable", "{AppName} {Version} 已发布，更新内容：\n\n\n{Notes}\n是否自动更新？")
	$UpdateAvailable = StringReplace($UpdateAvailable, "{AppName}", $CustomArch)
	$UpdateAvailable = StringReplace($UpdateAvailable, "{Version}", $latestVersion)
	$UpdateAvailable = StringReplace($UpdateAvailable, "{Notes}", $releaseNotes)
	If $hSettings Then
		$msg = MsgBox(68, $CustomArch, $UpdateAvailable, 0, $hSettings)
	Else
		$msg = MsgBox(68, $CustomArch, $UpdateAvailable)
	EndIf
	If $msg <> 6 Then Return

	;~ 拼接下载链接
	$archStr = '';
	If @AutoItX64 Then
		$archStr &= "_x64"
	EndIf
	Local $downloadFileName = $CustomArch & '_' & $latestVersion & $archStr & '.zip'
	Local $githubDownloadUrl = 'https://github.com/' & $repo & '/releases/download/v' & $latestVersion & '/' & $downloadFileName
	Local $downloadUrls = _UpgradeBuildGithubReleaseDownloadUrls($githubDownloadUrl, $MirrorAddress, $GithubJsDelivrMirror)

	Local $temp = @ScriptDir & "\RunFirefox_temp"
	$file = $temp & "\RunFirefox.zip"
	If Not FileExists($temp) Then DirCreate($temp)
	Opt("TrayAutoPause", 0)
	Opt("TrayMenuMode", 3) ; Default tray menu items (Script Paused/Exit) will not be shown.
	TraySetState(1)
	TraySetClick(8)
	TraySetToolTip($CustomArch)
	Local $hCancelAppUpdate = TrayCreateItem(_t("CancelAppUpdate", "取消更新..."))
	Local $DownloadSuccessful, $DownloadCancelled, $UpdateSuccessful, $error
	For $i = 0 To UBound($downloadUrls) - 1
		$downloadUrl = $downloadUrls[$i]
		ConsoleWrite($downloadUrl & @CRLF)
		If FileExists($file) Then FileDelete($file)
		TrayTip("", _t("StartToDownloadApp", "开始下载 {AppName}"), 10, 1)
		Local $hDownload = InetGet($downloadUrl, $file, 19, 1)
		Do
			Switch TrayGetMsg()
				Case $TRAY_EVENT_PRIMARYDOWN
					TrayTip("", _t("AppDownloadProgress", "正在下载 {AppName}\n已下载 %i KB", Round(InetGetInfo($hDownload, 0) / 1024)), 5, 1)
				Case $hCancelAppUpdate
					$msg = MsgBox(4 + 32 + 256, $CustomArch,_t("CancelAppUpdateConfirm", "正在下载 {AppName}，确定要取消吗？"))
					If $msg = 6 Then
						$DownloadCancelled = 1
						ExitLoop
					EndIf
			EndSwitch
		Until InetGetInfo($hDownload, 2)
		$DownloadSuccessful = InetGetInfo($hDownload, 3)
		InetClose($hDownload)
		If $DownloadCancelled Or $DownloadSuccessful Then ExitLoop
	Next
	If Not $DownloadCancelled Then
		If $DownloadSuccessful Then
			TrayTip("", _t("ApplyingUpdate", "正在应用 {AppName} 更新"), 10, 1)
			FileSetAttrib($file, "+A")
			_Zip_UnzipAll($file, $temp)
			$FileName = $CustomArch & ".exe"
			If @AutoItX64 Then
				$FileName = $CustomArch & "_x64.exe"
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
			MsgBox(64, $CustomArch, $UpdateSuccessfulMsg)
		Else
			Local $UpdateFailedConfirmMsg = _t("UpdateFailedConfirm", "{AppName} 自动更新失败：\n%s\n\n是否去软件发布页手动下载 {AppName}？", $error)
			$msg = MsgBox(20, $CustomArch, $UpdateFailedConfirmMsg)
			If $msg = 6 Then ; Yes
				ShellExecute("https://github.com/benzBrake/RunFirefox/releases")
			EndIf
		EndIf
	EndIf
	DirRemove($temp, 1)
	TrayItemDelete($hCancelAppUpdate)
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
	If Not $CheckAppUpdate Then Return
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
	FileDelete($FirefoxDir & "\defaults\pref\runfirefox.js")
	FileDelete($FirefoxDir & "\runfirefox.cfg")
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
	Next

	Return $Deleted
EndFunc   ;==>WaitAndDeleteMozillaLaunchOnLoginEntry

Func DeleteMozillaPrivateBrowsingShortcut()
	If Not IsMozillaBrowser($BrowserType) Then Return False

	Local $ProgramsDir = EnvGet("APPDATA") & "\Microsoft\Windows\Start Menu\Programs"
	Local $PrivateBrowsingPath = $FirefoxDir & "\private_browsing.exe"
	If Not FileExists($ProgramsDir) Or Not FileExists($PrivateBrowsingPath) Then Return False

	Local $search = FileFindFirstFile($ProgramsDir & "\*.lnk")
	If $search = -1 Then Return False

	Local $Deleted = False
	Local $file, $ShellObj, $objShortcut, $path
	$ShellObj = ObjCreate("WScript.Shell")
	If Not @error Then
		While 1
			$file = $ProgramsDir & "\" & FileFindNextFile($search)
			If @error Then ExitLoop

			$objShortcut = $ShellObj.CreateShortCut($file)
			$path = $objShortcut.TargetPath
			If NormalizePathForCompare($path) = NormalizePathForCompare($PrivateBrowsingPath) Then
				If FileDelete($file) Then $Deleted = True
			EndIf
		WEnd
		$objShortcut = ""
		$ShellObj = ""
	EndIf
	FileClose($search)

	Return $Deleted
EndFunc   ;==>DeleteMozillaPrivateBrowsingShortcut

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

; for win7+
; Group different app icons on Taskbar need the same AppUserModelIDs
; http://msdn.microsoft.com/en-us/library/dd378459%28VS.85%29.aspx
Func CheckPinnedPrograms($browser_path)
	If Not FileExists($TaskBarDir) Then
		Return
	EndIf
	Local $ftime = FileGetTime($TaskBarDir, 0, 1)
	If $ftime = $TaskBarLastChange Then
		Return
	EndIf

	$TaskBarLastChange = $ftime
	Local $search = FileFindFirstFile($TaskBarDir & "\*.lnk")
	If $search = -1 Then Return
	Local $file, $ShellObj, $objShortcut, $shortcut_appid
	$ShellObj = ObjCreate("WScript.Shell")
	If Not @error Then
		While 1
			$file = $TaskBarDir & "\" & FileFindNextFile($search)
			If @error Then ExitLoop
			$objShortcut = $ShellObj.CreateShortCut($file)
			$path = $objShortcut.TargetPath
			If $path == $browser_path Or $path == @ScriptFullPath Then
				If $path == $browser_path Then
					$objShortcut.TargetPath = @ScriptFullPath
					$objShortcut.Save
					$TaskBarLastChange = FileGetTime($TaskBarDir, 0, 1)
				EndIf
				$shortcut_appid = _ShortcutAppId($file)

				If Not $AppUserModelId Then
					;Sleep(3000)
					; usually fails to get firefox's window appid while succeeds on chrome,
					; what's wrong?
					$AppUserModelId = _WindowAppId($hWnd_browser)
					If Not $AppUserModelId Then
						If IsMozillaBrowser($BrowserType) Then
							$AppUserModelId = AppIdFromRegistry()
							If Not $AppUserModelId Then
								; helper.exe writes AppUserModelIDs to SOFTWARE\Mozilla\Firefox\TaskBarIDs
								Local $pid = Run($FirefoxDir & "\uninstall\helper.exe /UpdateShortcutAppUserModelIds")
								ProcessWaitClose($pid, 5)
								DeleteMozillaPrivateBrowsingShortcut()
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
						_WindowAppId($hWnd_browser, $AppUserModelId)
					EndIf
				EndIf
				If $shortcut_appid <> $AppUserModelId Then
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

Func AppIdFromRegistry()
	Local $appid
	If @OSArch = "X86" Then
		Local $aRoot[2] = ["HKCU\SOFTWARE", $HKLM_Software_32]
	Else
		Local $aRoot[3] = ["HKCU\SOFTWARE", $HKLM_Software_32, $HKLM_Software_64]
	EndIf
	For $i = 0 To UBound($aRoot) - 1
		$appid = RegRead($aRoot[$i] & "\Mozilla\Firefox\TaskBarIDs", $FirefoxDir)
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


Func CheckDefaultBrowser($BrowserPath)
	If IsChromeBrowser($BrowserType) Then Return CheckChromeDefaultBrowser($BrowserPath)
	Return CheckMozillaDefaultBrowser($BrowserPath)
EndFunc   ;==>CheckDefaultBrowser

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

Func UpdateAddonStarup()
	Local $addonStarup, $addonStarupLz4

	$addonStarupLz4 = $ProfileDir & "\" & "addonStartup.json.lz4"
	$addonStarup = $ProfileDir & "\" & "addonStartup.json"

	If FileExists($addonStarupLz4) Then
		Local $fileOpen = FileOpen($addonStarupLz4, $FO_BINARY)
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
					$fileOpen = FileOpen($addonStarupLz4, $FO_BINARY + $FO_OVERWRITE)
					If $fileOpen <> -1 Then
						FileWrite($fileOpen, $packedContent)
						FileClose($fileOpen)
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

	If FileExists($addonStarup) Then
		FileDelete($addonStarup)
	EndIf
EndFunc   ;==>UpdateAddonStarup

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
			$newPath = "jar:file:///" & $FirefoxDir & "/browser/features/" & $name & "!/";
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
			$newPath = $FirefoxDir & "\browser\features\" & $name;
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

Func Settings()
	$DefaultProfDir = GetSystemProfileSourceDir($BrowserType, "release")

	Opt("ExpandEnvStrings", 0)
	$hSettings = GUICreate(_t("AppTitle", "{AppName} - 打造自己的 Firefox 便携版"), 500, 540)
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

	;常规
	GUICtrlCreateTab(5, 50, 490, 430)
	GUICtrlCreateTabItem(_t("General", "常规"))

	GUICtrlCreateGroup(_t("BrowserFiles", "浏览器程序文件"), 10, 80, 480, 180)
	GUICtrlCreateLabel(_t("FirefoxPath", "浏览器路径"), 20, 108, 120, 20)
	$hFirefoxPath = GUICtrlCreateEdit($FirefoxPath, 140, 103, 270, 20, $ES_AUTOHSCROLL)
	GUICtrlSetTip(-1, _t("BrowserExecutablePath", "浏览器主程序路径"))
	GUICtrlSetOnEvent(-1, "OnFirefoxPathChange")
	GUICtrlCreateButton(_t("Browse", "浏览"), 420, 102, 60, 22)
	GUICtrlSetTip(-1, _t("ChoosePortableBrowser", "选择便携版浏览器\n主程序（firefox.exe）"))
	GUICtrlSetOnEvent(-1, "GetFirefoxPath")

	GUICtrlCreateLabel(_t("BrowserType", "浏览器"), 20, 138, 55, 20)
	$hBrowserType = GUICtrlCreateCombo("", 80, 133, 105, 20, $CBS_DROPDOWNLIST)
	GUICtrlSetData($hBrowserType, GetBrowserTypeComboData(), GetBrowserTypeLabel($BrowserType))
	GUICtrlSetOnEvent(-1, "ChangeBrowserType")

	GUICtrlCreateLabel(_t("UpdateChannel", "更新通道"), 200, 138, 70, 20)
	$hChannel = GUICtrlCreateCombo("", 275, 133, 80, 20, $CBS_DROPDOWNLIST)
	GUICtrlSetOnEvent(-1, "ChangeChannel")

	$hAllowBrowserUpdate = GUICtrlCreateCheckbox(_t("BrowserAutoUpdate", " 自动更新"), 365, 133, -1, 20)
	If $AllowBrowserUpdate Then
		GUICtrlSetState(-1, $GUI_CHECKED)
	EndIf

;~ 	$hDownloadFirefox = GUICtrlCreateLabel("去下载 " & GUICtrlRead($hChannel), 300, 130, 180, 20)
;~ 	GUICtrlSetCursor(-1, 0)
;~ 	GUICtrlSetColor(-1, 0x0000FF)
;~ 	GUICtrlSetTip(-1, "去下载 Firefox")
;~ 	GUICtrlSetOnEvent(-1, "DownloadFirefox")

	GUICtrlCreateLabel(_t("BrowserBitness", "浏览器位数："), 20, 168, 120, 20)
	$hBrowserBitness = GUICtrlCreateLabel("x64", 140, 168, 120, 20)

	GUICtrlCreateLabel(_t("LatestVersion", "最新版本："), 280, 168, 80, 20)
	$hDownloadFirefox64 = GUICtrlCreateLabel(_t("BrowserDownloadAddress", "下载地址"), 365, 168, 115, 20)
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetColor(-1, 0x0000FF)
	GUICtrlSetOnEvent(-1, "DownloadFirefox")

	GUICtrlCreateLabel(_t("CheckBrowserUpdate", "检查浏览器更新："), 20, 198, 120, 20)
	$hBrowserUpdateCheckMode = GUICtrlCreateCombo("", 140, 193, 120, 20, $CBS_DROPDOWNLIST)
	GUICtrlSetData($hBrowserUpdateCheckMode, GetBrowserUpdateCheckModeComboData(), GetBrowserUpdateCheckModeLabel($BrowserUpdateCheckMode))
	GUICtrlSetOnEvent(-1, "ChangeBrowserUpdateCheckMode")

	GUICtrlCreateLabel(_t("CurrentVersion", "当前版本："), 280, 198, 80, 20)
	$hCurrentBrowserVersion = GUICtrlCreateLabel("-", 365, 198, 115, 20)
	$hWaterfoxVersionHint = GUICtrlCreateLabel(_t("WaterfoxCurrentVersionUnsupported", "Waterfox 本地版本号读取不准确"), 140, 228, 220, 20)
	GUICtrlSetColor(-1, 0xFF0000)
	GUICtrlSetState($hWaterfoxVersionHint, $GUI_HIDE)
	$hBrowserDownloadNow = GUICtrlCreateButton(_t("DownloadNow", "立即下载"), 365, 224, 90, 22)
	GUICtrlSetOnEvent(-1, "DownloadFirefox")
	GUICtrlSetState($hBrowserDownloadNow, $GUI_HIDE)

	GUICtrlCreateGroup(_t("ProfileFiles", "浏览器用户数据文件"), 10, 270, 480, 90)
	GUICtrlCreateLabel(_t("ProfileDirectory", "配置文件夹"), 20, 300, 120, 20)
	$hProfileDir = GUICtrlCreateEdit($ProfileDir, 140, 295, 270, 20, $ES_AUTOHSCROLL)
	GUICtrlSetTip(-1, _t("ProfileDirectoryTooltip", "浏览器配置文件夹"))
	GUICtrlCreateButton(_t("Browse", "浏览"), 420, 294, 60, 22)
	GUICtrlSetTip(-1, _t("ChooseProfileDirectory", "指定浏览器配置文件夹"))
	GUICtrlSetOnEvent(-1, "GetProfileDir")
	$hCopyProfile = GUICtrlCreateCheckbox(_t("ExtractProfileFromSystem", " 从系统中提取浏览器配置文件"), 20, 328, -1, 20)

	GUICtrlCreateLabel(_t("UILanguage", "显示语言/Language"), 20, 385, 120, 20)
	$hlanguage = GUICtrlCreateCombo("", 140, 380, 100, 20, $CBS_DROPDOWNLIST)
	$sLang = '简体中文'
	If _ItemExists($LANGUAGES, $LANGUAGE) Then
		$sLang = _Item($LANGUAGES, $LANGUAGE)
	EndIf
	$sLangEnum = _ArrayToString(_GetItems($LANGUAGES))
	GUICtrlSetData(-1, $sLangEnum, $slang)
	GUICtrlSetOnEvent(-1, "ChangeLanguage")

	$hCheckAppUpdate = GUICtrlCreateCheckbox(_t("NoticeMeWhenNewVersionPublished", " {AppName} 发布新版时通知我"), 20, 415)
	If $CheckAppUpdate Then
		GUICtrlSetState(-1, $GUI_CHECKED)
	EndIf
	$hRunInBackground = GUICtrlCreateCheckbox(_t("KeepRunFirefoxRunning", " {AppName} 在后台运行直至浏览器退出"), 20, 440)
	GUICtrlSetOnEvent(-1, "RunInBackground")
	If $RunInBackground Then
		GUICtrlSetState($hRunInBackground, $GUI_CHECKED)
	EndIf

	; 高级
	GUICtrlCreateTabItem(_t("Advanced", "高级"))
	GUICtrlCreateGroup(_t("CacheSettings", "缓存设置"), 10, 80, 480, 120)
	GUICtrlCreateLabel(_t("PluginsDirectory", "插件目录"), 20, 108, 120, 20)
	$hCustomPluginsDir = GUICtrlCreateEdit($CustomPluginsDir, 140, 103, 270, 20, $ES_AUTOHSCROLL)
	GUICtrlSetTip(-1, _t("PluginsDirectoryTooltip", "浏览器插件目录\n空白=默认位置"))
	$hGetPluginsDir = GUICtrlCreateButton(_t("Browse", "浏览"), 420, 103, 60, 22)
	GUICtrlSetTip(-1, _t("SpecifyPluginsDirectoryTooltip", "选择浏览器插件目录"))
	GUICtrlSetOnEvent(-1, "GetPluginsDir")

	GUICtrlCreateLabel(_t("CacheDirectory", "缓存位置"), 20, 138, 120, 20)
	$hCustomCacheDir = GUICtrlCreateEdit($CustomCacheDir, 140, 133, 270, 20, $ES_AUTOHSCROLL)
	GUICtrlSetTip(-1, _t("CacheDirectoryTooltip", "浏览器缓存位置\n空白=默认位置"))
	$hGetCacheDir = GUICtrlCreateButton(_t("Browse", "浏览"), 420, 133, 60, 22)
	GUICtrlSetTip(-1, _t("SpecifyCacheDirectoryTooltip", "选择浏览器缓存文件夹"))
	GUICtrlSetOnEvent(-1, "GetCacheDir")

	GUICtrlCreateLabel(_t("CacheSize", "缓存大小"), 20, 168, 120, 20)
	$hCacheSize = GUICtrlCreateEdit($CacheSize, 140, 163, 60, 20, BitOR($ES_NUMBER, $ES_AUTOHSCROLL))
	GUICtrlSetTip(-1, _t("CacheSizeTooltip", "缓存大小\n空白=默认大小"))
	GUICtrlCreateLabel("MB", 215, 168, 35, 20)
	$hCacheSizeSmart = GUICtrlCreateCheckbox(_t("CacheSizeControl", " 自动控制缓存大小"), 250, 163, -1, 20)
	If $CacheSizeSmart Then GUICtrlSetState(-1, $GUI_CHECKED)

	GUICtrlCreateGroup(_t("ChromiumSettings", "Chromium设置"), 10, 210, 480, 55)
	$hChromiumGoogleApiImport = GUICtrlCreateButton(_t("ImportGoogleApi", "导入GoogleAPI"), 20, 233, 140, 22)
	GUICtrlSetOnEvent(-1, "ImportChromiumGoogleApi")
	GUICtrlSetTip(-1, _t("ImportGoogleApiTooltip", "导入GoogleAPI密钥后，Chromium 才能登录 Google 账号"))
	$hChromiumGoogleApiSuppress = GUICtrlCreateButton(_t("SuppressGoogleApiWarning", "清除GoogleAPI提示"), 180, 233, 140, 22)
	GUICtrlSetOnEvent(-1, "SuppressChromiumGoogleApiWarning")
	GUICtrlSetTip(-1, _t("SuppressGoogleApiWarningTooltip", "不导入GoogleAPI密钥，只清除缺少 Google API 密钥提示"))
	$hChromiumGoogleApiClear = GUICtrlCreateButton(_t("ClearGoogleApi", "清除GoogleAPI"), 340, 233, 140, 22)
	GUICtrlSetOnEvent(-1, "ClearChromiumGoogleApi")
	GUICtrlSetTip(-1, _t("ClearGoogleApiTooltip", "缺少GoogleAPI密钥会导致 Chromium 不能登录 Google 账号"))

	GUICtrlCreateLabel(_t("CommandLineArguments", "命令行参数"), 20, 325, -1, 20)
	$hParams = GUICtrlCreateEdit("", 20, 345, 460, 70, BitOR($ES_WANTRETURN, $WS_VSCROLL, $ES_AUTOVSCROLL))
	If $Params <> "" Then
		GUICtrlSetData(-1, StringReplace($Params, " -", @CRLF & "-"))
	EndIf
	GUICtrlSetTip(-1, _t("CommandLineArgumentsTooltip", "Firefox 命令行参数，每行写一个参数。\n支持%TEMP%等环境变量，\n另外，%APP%代表 RunFirefox 所在目录"))

	; Chrome++
	GUICtrlCreateTabItem(_t("ChromePlusTab", "Chrome++"))
	$hChromePlusHint = GUICtrlCreateLabel("", 20, 88, 460, 34)
	GUICtrlCreateLabel(_t("ChromePlusConfigFile", "配置文件"), 20, 128, 115, 20)
	$hChromePlusConfigPath = GUICtrlCreateEdit("", 145, 123, 170, 20, BitOR($ES_AUTOHSCROLL, $ES_READONLY))
	$hChromePlusDownloadPatch = GUICtrlCreateButton(_t("DownloadChromePlusPatch", "下载并安装 Chrome++"), 325, 123, 155, 22)
	GUICtrlSetOnEvent(-1, "DownloadChromePlusPatchFromSettings")

	GUICtrlCreateLabel(_t("CurrentVersion", "当前版本："), 20, 158, 115, 20)
	$hChromePlusCurrentVersion = GUICtrlCreateLabel("-", 145, 158, 170, 20)
	GUICtrlCreateLabel(_t("LatestVersion", "最新版本："), 250, 158, 80, 20)
	$hChromePlusLatestVersion = GUICtrlCreateLabel("-", 335, 158, 145, 20)

	$hChromePlusDoubleClickClose = GUICtrlCreateCheckbox(_t("ChromePlusDoubleClickClose", "双击关闭标签页"), 20, 198, 200, 20)
	$hChromePlusRightClickClose = GUICtrlCreateCheckbox(_t("ChromePlusRightClickClose", "右键关闭标签页"), 250, 198, 200, 20)
	$hChromePlusKeepLastTab = GUICtrlCreateCheckbox(_t("ChromePlusKeepLastTab", "保留最后一个标签页"), 20, 228, 200, 20)
	$hChromePlusWheelTab = GUICtrlCreateCheckbox(_t("ChromePlusWheelTab", "滚轮切换标签页"), 250, 228, 200, 20)
	$hChromePlusWheelTabWhenPressRButton = GUICtrlCreateCheckbox(_t("ChromePlusWheelTabWhenPressRButton", "按住右键时滚轮切换标签页"), 20, 258, 220, 20)
	$hChromePlusOpenUrlNewTab = GUICtrlCreateCheckbox(_t("ChromePlusOpenUrlNewTab", "地址栏输入在新标签页打开"), 250, 258, 210, 20)
	$hChromePlusOpenBookmarkNewTab = GUICtrlCreateCheckbox(_t("ChromePlusOpenBookmarkNewTab", "书签在新标签页打开"), 20, 288, 200, 20)
	$hChromePlusNewTabDisable = GUICtrlCreateCheckbox(_t("ChromePlusDisableNewTab", "新标签页时禁用上两项"), 250, 288, 200, 20)
	GUICtrlSetOnEvent($hChromePlusNewTabDisable, "RefreshChromePlusNewTabDisableNameState")

	$hChromePlusNewTabDisableNameLabel = GUICtrlCreateLabel(_t("ChromePlusDisableNewTabName", "额外匹配标题"), 20, 333, 115, 20)
	$hChromePlusNewTabDisableName = GUICtrlCreateEdit("", 145, 328, 335, 20, $ES_AUTOHSCROLL)
	GUICtrlSetTip($hChromePlusNewTabDisableName, _t("ChromePlusDisableNewTabNameTooltip", '对应 chrome++.ini 的 new_tab_disable_name 原始值；这些标题会被额外视为新标签页。可填写多个标题，并保留英文双引号与逗号，例如 "about:blank","新建标签"'))
	GUICtrlCreateLabel(_t("ChromePlusNewTabDisableHelp", "说明：勾选后，如果当前标签页被识别为新标签页，Chrome++ 会临时禁用上面的“地址栏输入在新标签页打开”和“书签在新标签页打开”。这样在新标签页里输入地址或打开书签时，会使用当前新标签页，而不会再额外新建标签页。\n“额外匹配标题”用于补充 Chrome++ 的内置识别列表，匹配到这些标题时也按新标签页处理。"), 20, 363, 460, 78)
	GUICtrlSetColor(-1, 0x666666)

	; 辅助
	GUICtrlCreateTabItem(_t("Auxiliary", "辅助"))
	GUICtrlCreateLabel(_t("RunOnBrowserStart", "浏览器启动时运行"), 20, 90, -1, 20)
	$hExAppAutoExit = GUICtrlCreateCheckbox(_t("AutoCloseAfterBrowserExit", " #浏览器退出后自动关闭"), 240, 85, -1, 20)
	If $ExAppAutoExit = 1 Then
		GUICtrlSetState($hExAppAutoExit, $GUI_CHECKED)
	EndIf
	$hExApp = GUICtrlCreateEdit("", 20, 110, 410, 50, BitOR($ES_WANTRETURN, $WS_VSCROLL, $ES_AUTOVSCROLL))
	If $ExApp <> "" Then
		GUICtrlSetData(-1, StringReplace($ExApp, "||", @CRLF) & @CRLF)
	EndIf
	GUICtrlSetTip(-1, _t("RunOnBrowserStartTooltip", "浏览器启动时运行的外部程序，支持批处理、vbs文件等\n如需启动参数，可添加在程序路径之后"))
	GUICtrlCreateButton(_t("Add", "添加"), 440, 109, 40, 22)
	GUICtrlSetTip(-1, _t("SelectExtraApp", "选择外部程序"))
	GUICtrlSetOnEvent(-1, "AddExApp")

	GUICtrlCreateLabel(_t("RunAfterBrowserExit", "浏览器退出后运行"), 20, 190, -1, 20)
	$hExApp2 = GUICtrlCreateEdit("", 20, 210, 410, 50, BitOR($ES_WANTRETURN, $WS_VSCROLL, $ES_AUTOVSCROLL))
	If $ExApp2 <> "" Then
		GUICtrlSetData(-1, StringReplace($ExApp2, "||", @CRLF) & @CRLF)
	EndIf
	GUICtrlSetTip(-1, _t("RunAfterBrowserExitTooltip", "浏览器退出后运行的外部程序，支持批处理、vbs文件等\n如需启动参数，可添加在程序路径之后"))
	GUICtrlCreateButton(_t("Add", "添加"), 440, 209, 40, 22)
	GUICtrlSetTip(-1, _t("SelectExtraApp", "选择外部程序"))
	GUICtrlSetOnEvent(-1, "AddExApp2")

	GUICtrlCreateGroup(_t("BossKeySettings", "Bosskey"), 10, 285, 480, 95)
	$hBossKeyEnabled = GUICtrlCreateCheckbox(_t("EnableBossKey", " 启用 Bosskey"), 20, 310, 130, 20)
	GUICtrlSetOnEvent(-1, "RefreshBossKeyControlsState")
	If $BossKeyEnabled Then GUICtrlSetState($hBossKeyEnabled, $GUI_CHECKED)
	GUICtrlCreateLabel(_t("BossKeyHotkey", "快捷键"), 170, 313, 60, 20)
	$BossKeyCaptureValue = $BossKey
	$hBossKey = GUICtrlCreateInput(BossKeyToDisplay($BossKey), 235, 308, 100, 20)
	GUICtrlSetTip(-1, _t("BossKeyHotkeyTooltip", "点击后直接按组合键；Backspace 或 Delete 清空"))
	$hBossKeyHideToTray = GUICtrlCreateCheckbox(_t("BossKeyHideToTray", " 隐藏到系统托盘"), 345, 310, 135, 20)
	If $BossKeyHideToTray Then GUICtrlSetState($hBossKeyHideToTray, $GUI_CHECKED)
	GUICtrlCreateLabel(_t("BossKeyDescription", "按快捷键隐藏浏览器；再次按快捷键或点击托盘图标还原。"), 20, 342, 460, 20)
	SetupBossKeyHotkeyCapture()
	RefreshBossKeyControlsState()

	GUICtrlCreateTabItem("")
	GUICtrlCreateButton(_t("Confirm", "确定"), 260, 489, 70, 22)
	GUICtrlSetTip(-1, _t("ConfirmTooltip", "保存设置并启动浏览器"))
	GUICtrlSetOnEvent(-1, "SettingsOK")
	GUICtrlSetState(-1, $GUI_FOCUS)
	GUICtrlCreateButton(_t("Cancel", "取消"), 340, 489, 70, 22)
	GUICtrlSetTip(-1, _t("CancelTooltip", "不保存设置并退出"))
	GUICtrlSetOnEvent(-1, "ExitApp")
	GUICtrlCreateButton(_t("Apply", "应用"), 420, 489, 70, 22)
	GUICtrlSetTip(-1, _t("ApplyTooltip", "保存设置"))
	GUICtrlSetOnEvent(-1, "SettingsApply")
	$hStatus = _GUICtrlStatusBar_Create($hSettings, -1, _t("DoublieClickToOpenSettingsWindow", '双击软件目录下的 "%s.vbs" 文件可调出此窗口', $ScriptNameWithOutSuffix))
	Opt("ExpandEnvStrings", 1)

	ApplyDetectedBrowserTypeFromPath()
	UpdateBrowserChannelOptions($BrowserType, "release")
	UpdateBrowserSpecificControls()
	ShowCurrentChannel()
	UpdateCurrentBrowserVersionLabel()
	UpdateFirefoxDownloadLabels(False)

	GUISetState(@SW_SHOW)
	BeginAppUpdateCheck()
	If ShouldCheckBrowserVersionNow() Then
		MarkBrowserVersionCheckStarted()
		AdlibRegister("RefreshFirefoxVersionLabels", 250)
	EndIf
	While Not $SettingsOK
		Sleep(100)
	WEnd
	AdlibUnRegister("RefreshFirefoxVersionLabels")
	CancelAppUpdateCheck()
	CancelBrowserVersionLoad()
	CancelChromePlusVersionLoad()
	CleanupBossKeyHotkeyCapture()
	GUIDelete($hSettings)
EndFunc   ;==>Settings


Func AddExApp()
	Local $path
	$path = FileOpenDialog(_t("ChooseExtraApp", "选择浏览器启动时需运行的外部程序"), @ScriptDir, _
			_t("ExtraAppAllFiles", "所有文件 (*.*)"), 1 + 2, "", $hSettings)
	If $path = "" Then Return
	$path = RelativePath($path)
	$ExApp = GUICtrlRead($hExApp) & '"' & $path & '"' & @CRLF
	GUICtrlSetData($hExApp, $ExApp)
EndFunc   ;==>AddExApp
Func AddExApp2()
	Local $path
	$path = FileOpenDialog(_t("ChooseExtraApp", "选择浏览器启动时需运行的外部程序"), @ScriptDir, _
	_t("ExtraAppAllFiles", "所有文件 (*.*)"), 1 + 2, "", $hSettings)
	If $path = "" Then Return
	$path = RelativePath($path)
	$ExApp2 = GUICtrlRead($hExApp2) & '"' & $path & '"' & @CRLF
	GUICtrlSetData($hExApp2, $ExApp2)
EndFunc   ;==>AddExApp2

Func SetupBossKeyHotkeyCapture()
	$BossKeyKeys = CreateBossKeyDictionary()
	$BossKeyHotkeyProc = DllCallbackRegister("BossKeyHotkeyInputProc", "lresult", "hwnd;uint;wparam;lparam")
	If @error Then Return
	$BossKeyInputWndProc = _WinAPI_SetWindowLong(GUICtrlGetHandle($hBossKey), $GWL_WNDPROC, DllCallbackGetPtr($BossKeyHotkeyProc))
EndFunc   ;==>SetupBossKeyHotkeyCapture

Func CleanupBossKeyHotkeyCapture()
	If $hBossKey And $BossKeyInputWndProc Then _WinAPI_SetWindowLong(GUICtrlGetHandle($hBossKey), $GWL_WNDPROC, $BossKeyInputWndProc)
	If $BossKeyHotkeyProc Then DllCallbackFree($BossKeyHotkeyProc)
	$BossKeyHotkeyProc = 0
	$BossKeyInputWndProc = 0
	$BossKeyKeys = 0
EndFunc   ;==>CleanupBossKeyHotkeyCapture

Func RefreshBossKeyControlsState()
	If Not $hBossKeyEnabled Then Return
	Local $State = $GUI_DISABLE
	If GUICtrlRead($hBossKeyEnabled) = $GUI_CHECKED Then $State = $GUI_ENABLE
	GUICtrlSetState($hBossKey, $State)
	GUICtrlSetState($hBossKeyHideToTray, $State)
EndFunc   ;==>RefreshBossKeyControlsState

Func BossKeyHotkeyInputProc($hWnd, $iMsg, $wParam, $lParam)
	Switch $iMsg
		Case $WM_CHAR, $WM_SYSCHAR
			Return 0
		Case $WM_KEYDOWN, $WM_SYSKEYDOWN
			If $wParam = 8 Or $wParam = 46 Then
				$BossKeyCaptureValue = ""
				GUICtrlSetData($hBossKey, "")
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
			GUICtrlSetData($hBossKey, $DisplayPrefix & " + " & $Key)
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

Func OnFirefoxPathChange()
	ApplyDetectedBrowserTypeFromPath()
	ShowCurrentChannel()
	ChangeChannel()
	UpdateCurrentBrowserVersionLabel()
	UpdateBrowserSpecificControls()
EndFunc   ;==>OnFirefoxPathChange

Func ApplyDetectedBrowserTypeFromPath()
	If Not $hBrowserType Then Return

	Local $DetectedBrowserType = DetectBrowserTypeFromPath(GUICtrlRead($hFirefoxPath))
	If $DetectedBrowserType = "" Then Return
	If NormalizeBrowserType(GetSelectedBrowserType()) = $DetectedBrowserType Then Return

	Local $SelectedChannel = "release"
	If $hChannel Then $SelectedChannel = GUICtrlRead($hChannel)
	$BrowserType = $DetectedBrowserType
	GUICtrlSetData($hBrowserType, GetBrowserTypeComboData(), GetBrowserTypeLabel($DetectedBrowserType))
	If $hChannel Then UpdateBrowserChannelOptions($DetectedBrowserType, $SelectedChannel)
EndFunc   ;==>ApplyDetectedBrowserTypeFromPath

Func ChangeBrowserType()
	Local $NewBrowserType = GetSelectedBrowserType()
	Local $CurrentPath = StringLower(GUICtrlRead($hFirefoxPath))
	If $CurrentPath = ".\firefox\firefox.exe" Or $CurrentPath = ".\zenbrowser\zen.exe" Or $CurrentPath = ".\floorp\floorp.exe" Or $CurrentPath = ".\waterfox\waterfox.exe" Or $CurrentPath = ".\chrome\chrome.exe" Or $CurrentPath = ".\helium\chrome.exe" Or $CurrentPath = ".\whale\whale.exe" Or $CurrentPath = ".\centbrowser\chrome.exe" Or $CurrentPath = ".\vivaldi\vivaldi.exe" Then
		GUICtrlSetData($hFirefoxPath, GetDefaultBrowserPath($NewBrowserType))
	EndIf
	$BrowserType = $NewBrowserType
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
		UpdateFirefoxDownloadLabels(False)
		Return
	EndIf
	BeginBrowserVersionLoad()
EndFunc   ;==>ChangeBrowserUpdateCheckMode

Func RefreshFirefoxVersionLabels()
	AdlibUnRegister("RefreshFirefoxVersionLabels")
	BeginBrowserVersionLoad()
EndFunc   ;==>RefreshFirefoxVersionLabels

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

Func UpdateFirefoxDownloadLabels($LoadVersion, $Unavailable = False)
	If Not $hDownloadFirefox64 Then Return
	Local $CurrentBrowserType = GetSelectedBrowserType()
	Local $Channel = GUICtrlRead($hChannel)
	If $Channel = "default" Then $Channel = "release"

	Local $LatestVersion = ""
	If $LoadVersion Then $LatestVersion = GetLatestBrowserVersionForSettings($CurrentBrowserType, $Channel)
	If $LatestVersion <> "" Then
		GUICtrlSetData($hDownloadFirefox64, $LatestVersion)
		UpdateBrowserDownloadNowState()
		Return
	EndIf

	If $Unavailable Then
		GUICtrlSetData($hDownloadFirefox64, _t("BrowserVersionUnavailable", "获取失败"))
	Else
		GUICtrlSetData($hDownloadFirefox64, _t("BrowserDownloadAddress", "下载地址"))
	EndIf
	UpdateBrowserDownloadNowState()
EndFunc   ;==>UpdateFirefoxDownloadLabels

Func GetLatestBrowserVersionForSettings($CurrentBrowserType, $Channel)
	$CurrentBrowserType = NormalizeBrowserType($CurrentBrowserType)
	If $Channel = "default" Then $Channel = "release"

	If $CurrentBrowserType = $BrowserZen Then Return GetLatestZenVersion($Channel)
	If $CurrentBrowserType = $BrowserFloorp Then Return GetLatestFloorpVersion()
	If $CurrentBrowserType = $BrowserWaterfox Then Return GetLatestWaterfoxVersion()
	If $CurrentBrowserType = $BrowserHelium Then Return GetLatestHeliumVersion()
	If $CurrentBrowserType = $BrowserCent Then Return GetLatestCentVersion()
	If $CurrentBrowserType = $BrowserVivaldi Then Return GetLatestVivaldiVersion()
	If IsChromeBrowser($CurrentBrowserType) Then Return GetChromeVersionCache($Channel)
	Return GetLatestFirefoxVersion($Channel)
EndFunc   ;==>GetLatestBrowserVersionForSettings

Func UpdateCurrentBrowserVersionLabel()
	If Not $hCurrentBrowserVersion Then Return

	Local $BrowserPath = GetCurrentSettingsBrowserPath()
	Local $CurrentVersion = ""
	If FileExists($BrowserPath) Then
		If NormalizeBrowserType(GetSelectedBrowserType()) = $BrowserZen Then
			$CurrentVersion = ReadExecutableVersionField($BrowserPath, "ProductVersion")
			If $CurrentVersion = "" Then $CurrentVersion = ReadExecutableVersionField($BrowserPath, "FileVersion")
		ElseIf NormalizeBrowserType(GetSelectedBrowserType()) = $BrowserWaterfox Then
			$CurrentVersion = "-"
		Else
			$CurrentVersion = ReadExecutableVersionField($BrowserPath, "FileVersion")
			If $CurrentVersion = "" Then $CurrentVersion = ReadExecutableVersionField($BrowserPath, "ProductVersion")
		EndIf
	EndIf
	If $CurrentVersion = "" Then $CurrentVersion = "-"
	GUICtrlSetData($hCurrentBrowserVersion, $CurrentVersion)
	UpdateWaterfoxVersionHintState()
	UpdateBrowserDownloadNowState()
EndFunc   ;==>UpdateCurrentBrowserVersionLabel

Func UpdateWaterfoxVersionHintState()
	If Not $hWaterfoxVersionHint Then Return
	If NormalizeBrowserType(GetSelectedBrowserType()) = $BrowserWaterfox Then
		GUICtrlSetState($hWaterfoxVersionHint, $GUI_SHOW)
	Else
		GUICtrlSetState($hWaterfoxVersionHint, $GUI_HIDE)
	EndIf
EndFunc   ;==>UpdateWaterfoxVersionHintState

Func UpdateBrowserDownloadNowState()
	If Not $hBrowserDownloadNow Or Not $hDownloadFirefox64 Or Not $hCurrentBrowserVersion Then Return

	Local $LatestVersion = NormalizeDisplayedVersionForCompare(GUICtrlRead($hDownloadFirefox64))
	Local $CurrentVersion = NormalizeDisplayedVersionForCompare(GUICtrlRead($hCurrentBrowserVersion))
	Local $CurrentBrowserType = NormalizeBrowserType(GetSelectedBrowserType())
	If $CurrentBrowserType = $BrowserWhale Then
		GUICtrlSetState($hBrowserDownloadNow, $GUI_SHOW)
	ElseIf $LatestVersion <> "" And ($CurrentVersion = "" Or $LatestVersion <> $CurrentVersion) Then
		GUICtrlSetState($hBrowserDownloadNow, $GUI_SHOW)
	Else
		GUICtrlSetState($hBrowserDownloadNow, $GUI_HIDE)
	EndIf
EndFunc   ;==>UpdateBrowserDownloadNowState

Func NormalizeDisplayedVersionForCompare($Version)
	$Version = StringLower(StringStripWS($Version, 3))
	If $Version = "" Or $Version = "-" Then Return ""
	If $Version = StringLower(_t("BrowserDownloadAddress", "下载地址")) Then Return ""
	If $Version = StringLower(_t("BrowserVersionUnavailable", "获取失败")) Then Return ""
	Local $LoadingText = StringReplace(StringLower(_t("BrowserVersionLoading", "正在读取版本 %s")), "%s", "")
	If $LoadingText <> "" And StringInStr($Version, $LoadingText) Then Return ""
	Return StringRegExpReplace($Version, "^[vV]", "")
EndFunc   ;==>NormalizeDisplayedVersionForCompare

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
	If Not $hBrowserUpdateCheckMode Then Return $BrowserUpdateCheckMode
	Return GetBrowserUpdateCheckModeByLabel(GUICtrlRead($hBrowserUpdateCheckMode))
EndFunc   ;==>GetSelectedBrowserUpdateCheckMode

Func GetBrowserUpdateCheckModeComboData()
	Return GetBrowserUpdateCheckModeLabel("startup") & "|" & GetBrowserUpdateCheckModeLabel("hourly") & "|" & GetBrowserUpdateCheckModeLabel("daily") & "|" & GetBrowserUpdateCheckModeLabel("weekly") & "|" & GetBrowserUpdateCheckModeLabel("never")
EndFunc   ;==>GetBrowserUpdateCheckModeComboData

Func BeginBrowserVersionLoad($CurrentBrowserType = "", $Channel = "")
	If Not $hDownloadFirefox64 Then Return
	If $CurrentBrowserType = "" Then $CurrentBrowserType = GetSelectedBrowserType()
	If $Channel = "" Then $Channel = GUICtrlRead($hChannel)
	If $Channel = "default" Then $Channel = "release"

	If NormalizeBrowserType($CurrentBrowserType) = $BrowserWhale Then
		CancelBrowserVersionLoad()
		UpdateFirefoxDownloadLabels(False)
		Return
	EndIf

	If IsBrowserVersionCached($CurrentBrowserType, $Channel) Then
		UpdateFirefoxDownloadLabels(True)
		Return
	EndIf

	If $BrowserVersionLoadHandle Then
		If $BrowserVersionLoadBrowserType = NormalizeBrowserType($CurrentBrowserType) And $BrowserVersionLoadChannel = $Channel Then
			UpdateBrowserVersionLoadingLabel()
			Return
		EndIf
		CancelBrowserVersionLoad()
	EndIf

	$BrowserVersionLoadBrowserType = NormalizeBrowserType($CurrentBrowserType)
	$BrowserVersionLoadChannel = $Channel
	$BrowserVersionLoadFile = @TempDir & "\RunFirefox_BrowserVersion_" & @AutoItPID & ".tmp"
	FileDelete($BrowserVersionLoadFile)

	If NormalizeBrowserType($CurrentBrowserType) = $BrowserHelium Then
		$BrowserVersionLoadKind = "inet"
		$BrowserVersionLoadHandle = InetGet($HeliumLatestReleaseUrl, $BrowserVersionLoadFile, 1, 1)
	ElseIf NormalizeBrowserType($CurrentBrowserType) = $BrowserCent Then
		$BrowserVersionLoadKind = "inet"
		$BrowserVersionLoadHandle = InetGet($CentBrowserDownloadPageUrl, $BrowserVersionLoadFile, 1, 1)
	ElseIf NormalizeBrowserType($CurrentBrowserType) = $BrowserVivaldi Then
		$BrowserVersionLoadKind = "inet"
		$BrowserVersionLoadHandle = InetGet($VivaldiDownloadPageUrl, $BrowserVersionLoadFile, 1, 1)
	ElseIf IsChromeBrowser($CurrentBrowserType) Then
		$BrowserVersionLoadKind = "chrome"
		$BrowserVersionLoadHandle = StartChromeVersionLoadProcess($Channel, "win64", $BrowserVersionLoadFile)
	Else
		Local $Url = $FirefoxVersionUrl
		If NormalizeBrowserType($CurrentBrowserType) = $BrowserZen Then $Url = $ZenUpdateBaseUrl & "/" & GetZenUpdateChannel($Channel) & "/update.xml"
		If NormalizeBrowserType($CurrentBrowserType) = $BrowserFloorp Then $Url = $FloorpLatestReleaseUrl
		If NormalizeBrowserType($CurrentBrowserType) = $BrowserWaterfox Then $Url = $WaterfoxDownloadPageUrl
		$BrowserVersionLoadKind = "inet"
		$BrowserVersionLoadHandle = InetGet($Url, $BrowserVersionLoadFile, 1, 1)
	EndIf

	If Not $BrowserVersionLoadHandle Then
		CancelBrowserVersionLoad()
		UpdateFirefoxDownloadLabels(False)
		Return
	EndIf

	$BrowserVersionLoadAnim = 0
	UpdateBrowserVersionLoadingLabel()
	AdlibRegister("PollBrowserVersionLoad", 250)
EndFunc   ;==>BeginBrowserVersionLoad

Func CancelBrowserVersionLoad()
	AdlibUnRegister("PollBrowserVersionLoad")
	If $BrowserVersionLoadHandle Then
		If $BrowserVersionLoadKind = "chrome" Then
			If ProcessExists($BrowserVersionLoadHandle) Then ProcessClose($BrowserVersionLoadHandle)
		Else
			InetClose($BrowserVersionLoadHandle)
		EndIf
	EndIf
	If $BrowserVersionLoadFile <> "" Then FileDelete($BrowserVersionLoadFile)
	$BrowserVersionLoadHandle = 0
	$BrowserVersionLoadFile = ""
	$BrowserVersionLoadBrowserType = ""
	$BrowserVersionLoadChannel = ""
	$BrowserVersionLoadKind = ""
EndFunc   ;==>CancelBrowserVersionLoad

Func PollBrowserVersionLoad()
	If Not $BrowserVersionLoadHandle Then
		CancelBrowserVersionLoad()
		Return
	EndIf

	UpdateBrowserVersionLoadingLabel()
	If $BrowserVersionLoadKind = "chrome" Then
		If ProcessExists($BrowserVersionLoadHandle) Then Return

		Local $LoadedChromeBrowserType = $BrowserVersionLoadBrowserType
		Local $LoadedChromeChannel = $BrowserVersionLoadChannel
		Local $LoadedChromeFile = $BrowserVersionLoadFile
		$BrowserVersionLoadHandle = 0
		AdlibUnRegister("PollBrowserVersionLoad")

		Local $ChromeLoaded = LoadChromeUpdateInfoFile($LoadedChromeChannel, $LoadedChromeFile)
		FileDelete($LoadedChromeFile)
		$BrowserVersionLoadFile = ""
		$BrowserVersionLoadBrowserType = ""
		$BrowserVersionLoadChannel = ""
		$BrowserVersionLoadKind = ""

		CompleteBrowserVersionLoad($LoadedChromeBrowserType, $LoadedChromeChannel, $ChromeLoaded)
		Return
	EndIf

	If Not InetGetInfo($BrowserVersionLoadHandle, 2) Then Return

	Local $DownloadSuccessful = InetGetInfo($BrowserVersionLoadHandle, 3)
	Local $LoadedBrowserType = $BrowserVersionLoadBrowserType
	Local $LoadedChannel = $BrowserVersionLoadChannel
	Local $LoadedFile = $BrowserVersionLoadFile
	InetClose($BrowserVersionLoadHandle)
	$BrowserVersionLoadHandle = 0
	AdlibUnRegister("PollBrowserVersionLoad")

	Local $Loaded = False
	If $DownloadSuccessful Then
		Local $Content = FileRead($LoadedFile)
		If $Content <> "" Then
			If $LoadedBrowserType = $BrowserZen Then
				SetZenUpdateXml($LoadedChannel, $Content)
				$Loaded = True
			ElseIf $LoadedBrowserType = $BrowserFloorp Then
				$Loaded = CacheFloorpReleaseInfo($Content)
			ElseIf $LoadedBrowserType = $BrowserWaterfox Then
				$Loaded = CacheWaterfoxReleaseInfo($Content)
			ElseIf $LoadedBrowserType = $BrowserHelium Then
				$Loaded = CacheHeliumReleaseInfo($Content)
			ElseIf $LoadedBrowserType = $BrowserCent Then
				$Loaded = CacheCentReleaseInfo($Content)
			ElseIf $LoadedBrowserType = $BrowserVivaldi Then
				$Loaded = CacheVivaldiReleaseInfo($Content)
			Else
				$Loaded = CacheFirefoxVersions($Content)
			EndIf
		EndIf
	EndIf
	FileDelete($LoadedFile)
	$BrowserVersionLoadFile = ""
	$BrowserVersionLoadBrowserType = ""
	$BrowserVersionLoadChannel = ""
	$BrowserVersionLoadKind = ""

	CompleteBrowserVersionLoad($LoadedBrowserType, $LoadedChannel, $Loaded)
EndFunc   ;==>PollBrowserVersionLoad

Func CompleteBrowserVersionLoad($LoadedBrowserType, $LoadedChannel, $Loaded)
	If Not $hDownloadFirefox64 Then Return
	Local $CurrentBrowserType = GetSelectedBrowserType()
	Local $CurrentChannel = GUICtrlRead($hChannel)
	If $CurrentChannel = "default" Then $CurrentChannel = "release"
	If NormalizeBrowserType($CurrentBrowserType) <> $LoadedBrowserType Or $CurrentChannel <> $LoadedChannel Then
		BeginBrowserVersionLoad($CurrentBrowserType, $CurrentChannel)
		Return
	EndIf

	If $Loaded Then
		UpdateFirefoxDownloadLabels(True)
	Else
		UpdateFirefoxDownloadLabels(False, True)
		If $hStatus Then _GUICtrlStatusBar_SetText($hStatus, _t("BrowserVersionLoadFailed", "读取浏览器版本失败。"))
	EndIf
EndFunc   ;==>CompleteBrowserVersionLoad

Func UpdateBrowserVersionLoadingLabel()
	If Not $hDownloadFirefox64 Then Return
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
	GUICtrlSetData($hDownloadFirefox64, _t("BrowserVersionLoading", "正在读取版本 %s", $Spinner))
EndFunc   ;==>UpdateBrowserVersionLoadingLabel

Func IsBrowserVersionCached($CurrentBrowserType, $Channel)
	If NormalizeBrowserType($CurrentBrowserType) = $BrowserHelium Then Return $HeliumReleaseInfoLoaded
	If NormalizeBrowserType($CurrentBrowserType) = $BrowserCent Then Return $CentReleaseInfoLoaded
	If NormalizeBrowserType($CurrentBrowserType) = $BrowserVivaldi Then Return $VivaldiReleaseInfoLoaded
	If IsChromeBrowser($CurrentBrowserType) Then Return GetChromeVersionCache($Channel) <> ""
	If NormalizeBrowserType($CurrentBrowserType) = $BrowserZen Then Return GetZenUpdateXmlCache($Channel) <> ""
	If NormalizeBrowserType($CurrentBrowserType) = $BrowserFloorp Then Return $FloorpReleaseInfoLoaded
	If NormalizeBrowserType($CurrentBrowserType) = $BrowserWaterfox Then Return $WaterfoxReleaseInfoLoaded
	Return IsObj($FirefoxVersionsObj)
EndFunc   ;==>IsBrowserVersionCached

Func GetSelectedBrowserType()
	If Not $hBrowserType Then Return $BrowserType
	Return GetBrowserTypeByLabel(GUICtrlRead($hBrowserType))
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

	If StringInStr($Identity, "helium") Or StringInStr($Identity, "the helium authors") Then Return $BrowserHelium
	If $BrowserExeLower = "whale.exe" Or StringInStr($Identity, "naver whale") Or StringInStr($Identity, "whale browser") Then Return $BrowserWhale
	If $BrowserExeLower = "chrome.exe" And (StringInStr($Identity, "cent browser") Or StringInStr($Identity, "centbrowser") Or StringInStr($FullBrowserPathLower, "\centbrowser\")) Then Return $BrowserCent
	If $BrowserExeLower = "vivaldi.exe" Or StringInStr($Identity, "vivaldi") Then Return $BrowserVivaldi
	If $BrowserExeLower = "zen.exe" Or StringInStr($Identity, "zen browser") Or StringInStr($Identity, "zenbrowser") Then Return $BrowserZen
	If $BrowserExeLower = "floorp.exe" Or StringInStr($Identity, "floorp") Then Return $BrowserFloorp
	If $BrowserExeLower = "waterfox.exe" Or StringInStr($Identity, "waterfox") Then Return $BrowserWaterfox
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
	Return $Normalized = $BrowserChrome Or $Normalized = $BrowserHelium Or $Normalized = $BrowserWhale Or $Normalized = $BrowserCent Or $Normalized = $BrowserVivaldi
EndFunc   ;==>IsChromeBrowser

Func IsGoogleChromeBrowser($Value)
	Return NormalizeBrowserType($Value) = $BrowserChrome
EndFunc   ;==>IsGoogleChromeBrowser

Func IsChromePlusSupportedBrowser($Value)
	Local $Normalized = NormalizeBrowserType($Value)
	Return $Normalized = $BrowserChrome Or $Normalized = $BrowserHelium Or $Normalized = $BrowserWhale
EndFunc   ;==>IsChromePlusSupportedBrowser

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
	If $Value = $BrowserChrome Or $Value = "google chrome" Then Return $BrowserChrome
	If $Value = $BrowserHelium Then Return $BrowserHelium
	If $Value = $BrowserWhale Or $Value = "naver whale" Or $Value = "whalebrowser" Then Return $BrowserWhale
	If $Value = $BrowserCent Or $Value = "cent browser" Or $Value = "centbrowser" Or $Value = "百分浏览器" Or $Value = "百分瀏覽器" Then Return $BrowserCent
	If $Value = $BrowserVivaldi Then Return $BrowserVivaldi
	Return $BrowserFirefox
EndFunc   ;==>NormalizeBrowserType

Func GetBrowserDisplayName($Value)
	If NormalizeBrowserType($Value) = $BrowserChrome Then Return "Chrome"
	If NormalizeBrowserType($Value) = $BrowserHelium Then Return "Helium"
	If NormalizeBrowserType($Value) = $BrowserWhale Then Return "Naver Whale"
	If NormalizeBrowserType($Value) = $BrowserCent Then Return "Cent Browser"
	If NormalizeBrowserType($Value) = $BrowserVivaldi Then Return "Vivaldi"
	If NormalizeBrowserType($Value) = $BrowserZen Then Return "ZenBrowser"
	If NormalizeBrowserType($Value) = $BrowserFloorp Then Return "Floorp"
	If NormalizeBrowserType($Value) = $BrowserWaterfox Then Return "Waterfox"
	Return "Firefox"
EndFunc   ;==>GetBrowserDisplayName

Func GetBrowserTypeLabel($Value)
	If NormalizeBrowserType($Value) = $BrowserChrome Then Return _t("BrowserChrome", "Chrome")
	If NormalizeBrowserType($Value) = $BrowserHelium Then Return _t("BrowserHelium", "Helium")
	If NormalizeBrowserType($Value) = $BrowserWhale Then Return _t("BrowserWhale", "Naver Whale")
	If NormalizeBrowserType($Value) = $BrowserCent Then Return _t("BrowserCent", "百分浏览器")
	If NormalizeBrowserType($Value) = $BrowserVivaldi Then Return _t("BrowserVivaldi", "Vivaldi")
	If NormalizeBrowserType($Value) = $BrowserZen Then Return _t("BrowserZen", "ZenBrowser")
	If NormalizeBrowserType($Value) = $BrowserFloorp Then Return _t("BrowserFloorp", "Floorp")
	If NormalizeBrowserType($Value) = $BrowserWaterfox Then Return _t("BrowserWaterfox", "Waterfox")
	Return _t("BrowserFirefox", "Firefox 原版")
EndFunc   ;==>GetBrowserTypeLabel

Func GetBrowserTypeByLabel($Label)
	If $Label = _t("BrowserChrome", "Chrome") Or StringLower($Label) = "chrome" Or StringLower($Label) = "google chrome" Then Return $BrowserChrome
	If $Label = _t("BrowserHelium", "Helium") Or StringLower($Label) = "helium" Then Return $BrowserHelium
	If $Label = _t("BrowserWhale", "Naver Whale") Or StringLower($Label) = "whale" Or StringLower($Label) = "naver whale" Then Return $BrowserWhale
	If $Label = _t("BrowserCent", "百分浏览器") Or StringLower($Label) = "cent" Or StringLower($Label) = "cent browser" Or $Label = "百分浏览器" Or $Label = "百分瀏覽器" Then Return $BrowserCent
	If $Label = _t("BrowserVivaldi", "Vivaldi") Or StringLower($Label) = "vivaldi" Then Return $BrowserVivaldi
	If $Label = _t("BrowserZen", "ZenBrowser") Or StringLower($Label) = "zenbrowser" Then Return $BrowserZen
	If $Label = _t("BrowserFloorp", "Floorp") Or StringLower($Label) = "floorp" Then Return $BrowserFloorp
	If $Label = _t("BrowserWaterfox", "Waterfox") Or StringLower($Label) = "waterfox" Then Return $BrowserWaterfox
	Return $BrowserFirefox
EndFunc   ;==>GetBrowserTypeByLabel

Func GetBrowserTypeComboData()
	Return _t("BrowserFirefox", "Firefox 原版") & "|" & _t("BrowserZen", "ZenBrowser") & "|" & _t("BrowserFloorp", "Floorp") & "|" & _t("BrowserWaterfox", "Waterfox") & "|" & _t("BrowserChrome", "Chrome") & "|" & _t("BrowserHelium", "Helium") & "|" & _t("BrowserWhale", "Naver Whale") & "|" & _t("BrowserCent", "百分浏览器") & "|" & _t("BrowserVivaldi", "Vivaldi")
EndFunc   ;==>GetBrowserTypeComboData

Func GetBrowserExecutableName($Value)
	If NormalizeBrowserType($Value) = $BrowserChrome Then Return "chrome.exe"
	If NormalizeBrowserType($Value) = $BrowserHelium Then Return "chrome.exe"
	If NormalizeBrowserType($Value) = $BrowserWhale Then Return "whale.exe"
	If NormalizeBrowserType($Value) = $BrowserCent Then Return "chrome.exe"
	If NormalizeBrowserType($Value) = $BrowserVivaldi Then Return "vivaldi.exe"
	If NormalizeBrowserType($Value) = $BrowserZen Then Return "zen.exe"
	If NormalizeBrowserType($Value) = $BrowserFloorp Then Return "floorp.exe"
	If NormalizeBrowserType($Value) = $BrowserWaterfox Then Return "waterfox.exe"
	Return "firefox.exe"
EndFunc   ;==>GetBrowserExecutableName

Func GetBrowserExecutableCandidates($Value)
	Return GetBrowserExecutableName($Value)
EndFunc   ;==>GetBrowserExecutableCandidates

Func GetDefaultBrowserPath($Value)
	If NormalizeBrowserType($Value) = $BrowserChrome Then Return ".\Chrome\chrome.exe"
	If NormalizeBrowserType($Value) = $BrowserHelium Then Return ".\Helium\chrome.exe"
	If NormalizeBrowserType($Value) = $BrowserWhale Then Return ".\Whale\whale.exe"
	If NormalizeBrowserType($Value) = $BrowserCent Then Return ".\CentBrowser\chrome.exe"
	If NormalizeBrowserType($Value) = $BrowserVivaldi Then Return ".\Vivaldi\vivaldi.exe"
	If NormalizeBrowserType($Value) = $BrowserZen Then Return ".\ZenBrowser\zen.exe"
	If NormalizeBrowserType($Value) = $BrowserFloorp Then Return ".\Floorp\floorp.exe"
	If NormalizeBrowserType($Value) = $BrowserWaterfox Then Return ".\Waterfox\waterfox.exe"
	Return ".\Firefox\firefox.exe"
EndFunc   ;==>GetDefaultBrowserPath

Func BuildBrowserLaunchParams($Value)
	If IsChromeBrowser($Value) Then
		Local $ChromeParams = '--user-data-dir="' & $ProfileDir & '"'
		If $CustomCacheDir <> "" Then
			$ChromeParams &= ' --disk-cache-dir="' & FullPath($CustomCacheDir) & '"'
		EndIf
		If $CacheSize <> "" And $CacheSize > 0 Then
			$ChromeParams &= " --disk-cache-size=" & ($CacheSize * 1024 * 1024)
		EndIf
		Local $WhaleLocale = GetWhaleCommandLineLocale($Value)
		If $WhaleLocale <> "" Then $ChromeParams &= " --lang=" & $WhaleLocale
		Return $ChromeParams & " "
	EndIf

	Local $MozillaParams = '-profile "' & $ProfileDir & '" '
	If $isZotero Then
		$MozillaParams &= '-datadir "' & $ProfileDir & '\Library" '
	EndIf
	Return $MozillaParams
EndFunc   ;==>BuildBrowserLaunchParams

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
	If Not $hBrowserType Then Return
	Local $IsChrome = IsChromeBrowser(GetSelectedBrowserType())
	Local $MozillaState = $GUI_ENABLE
	If $IsChrome Then $MozillaState = $GUI_DISABLE

	GUICtrlSetState($hChannel, $GUI_ENABLE)
	GUICtrlSetState($hAllowBrowserUpdate, $MozillaState)
	GUICtrlSetState($hDownloadFirefox64, $GUI_ENABLE)
	GUICtrlSetState($hCustomPluginsDir, $MozillaState)
	GUICtrlSetState($hGetPluginsDir, $MozillaState)
	GUICtrlSetState($hCacheSizeSmart, $MozillaState)

	If $IsChrome Then
		UpdateFirefoxDownloadLabels(False)
	EndIf
	RefreshCopyProfileState()

	RefreshChromePlusTabState()
EndFunc   ;==>UpdateBrowserSpecificControls

Func GetCurrentSettingsBrowserPath()
	If $hFirefoxPath Then Return FullPath(GUICtrlRead($hFirefoxPath))
	Return FullPath($FirefoxPath)
EndFunc   ;==>GetCurrentSettingsBrowserPath

Func IsChromePlusSupportedExecutable($BrowserExe)
	$BrowserExe = StringLower($BrowserExe)
	Return $BrowserExe = "chrome.exe" Or $BrowserExe = "helium.exe" Or $BrowserExe = "whale.exe"
EndFunc   ;==>IsChromePlusSupportedExecutable

Func GetChromePlusConfigPath($BrowserPath)
	If $BrowserPath = "" Then Return ""

	Local $BrowserDir = "", $BrowserExe = ""
	SplitPath(FullPath($BrowserPath), $BrowserDir, $BrowserExe)
	If Not IsChromePlusSupportedExecutable($BrowserExe) Then Return ""
	If $BrowserDir = "" Or $BrowserDir = "." Then $BrowserDir = @ScriptDir
	Return $BrowserDir & "\chrome++.ini"
EndFunc   ;==>GetChromePlusConfigPath

Func SetCheckboxStateByValue($hCtrl, $Value)
	If Number($Value) <> 0 Then
		GUICtrlSetState($hCtrl, $GUI_CHECKED)
	Else
		GUICtrlSetState($hCtrl, $GUI_UNCHECKED)
	EndIf
EndFunc   ;==>SetCheckboxStateByValue

Func GetCheckboxIniValue($hCtrl)
	If GUICtrlRead($hCtrl) = $GUI_CHECKED Then Return "1"
	Return "0"
EndFunc   ;==>GetCheckboxIniValue

Func SetChromePlusTabControlsState($Enabled)
	Local $State = $GUI_DISABLE
	If $Enabled Then $State = $GUI_ENABLE

	GUICtrlSetState($hChromePlusDoubleClickClose, $State)
	GUICtrlSetState($hChromePlusRightClickClose, $State)
	GUICtrlSetState($hChromePlusKeepLastTab, $State)
	GUICtrlSetState($hChromePlusWheelTab, $State)
	GUICtrlSetState($hChromePlusWheelTabWhenPressRButton, $State)
	GUICtrlSetState($hChromePlusOpenUrlNewTab, $State)
	GUICtrlSetState($hChromePlusOpenBookmarkNewTab, $State)
	GUICtrlSetState($hChromePlusNewTabDisable, $State)
	If Not $Enabled Then
		GUICtrlSetState($hChromePlusNewTabDisableName, $GUI_DISABLE)
		GUICtrlSetState($hChromePlusNewTabDisableNameLabel, $GUI_DISABLE)
	EndIf
EndFunc   ;==>SetChromePlusTabControlsState

Func LoadChromePlusTabsSettings($ConfigPath)
	SetCheckboxStateByValue($hChromePlusDoubleClickClose, IniRead($ConfigPath, "tabs", "double_click_close", "0"))
	SetCheckboxStateByValue($hChromePlusRightClickClose, IniRead($ConfigPath, "tabs", "right_click_close", "1"))
	SetCheckboxStateByValue($hChromePlusKeepLastTab, IniRead($ConfigPath, "tabs", "keep_last_tab", "1"))
	SetCheckboxStateByValue($hChromePlusWheelTab, IniRead($ConfigPath, "tabs", "wheel_tab", "0"))
	SetCheckboxStateByValue($hChromePlusWheelTabWhenPressRButton, IniRead($ConfigPath, "tabs", "wheel_tab_when_press_rbutton", "0"))
	SetCheckboxStateByValue($hChromePlusOpenUrlNewTab, IniRead($ConfigPath, "tabs", "open_url_new_tab", "0"))
	SetCheckboxStateByValue($hChromePlusOpenBookmarkNewTab, IniRead($ConfigPath, "tabs", "open_bookmark_new_tab", "0"))
	SetCheckboxStateByValue($hChromePlusNewTabDisable, IniRead($ConfigPath, "tabs", "new_tab_disable", "1"))
	GUICtrlSetData($hChromePlusNewTabDisableName, ReadIniTextValue($ConfigPath, "tabs", "new_tab_disable_name", '"about:blank","新建标签"'))
	RefreshChromePlusNewTabDisableNameState()
EndFunc   ;==>LoadChromePlusTabsSettings

Func RefreshChromePlusNewTabDisableNameState()
	If Not $hChromePlusNewTabDisableName Then Return

	Local $State = $GUI_DISABLE
	If BitAND(GUICtrlGetState($hChromePlusNewTabDisable), $GUI_ENABLE) = $GUI_ENABLE And GUICtrlRead($hChromePlusNewTabDisable) = $GUI_CHECKED Then
		$State = $GUI_ENABLE
	EndIf
	GUICtrlSetState($hChromePlusNewTabDisableName, $State)
	GUICtrlSetState($hChromePlusNewTabDisableNameLabel, $State)
EndFunc   ;==>RefreshChromePlusNewTabDisableNameState

Func RefreshChromePlusTabState()
	If Not $hChromePlusHint Then Return

	Local $BrowserPath = GetCurrentSettingsBrowserPath()
	Local $SelectedBrowserType = GetSelectedBrowserType()
	Local $IsChromium = IsChromeBrowser($SelectedBrowserType)
	Local $IsChrome = IsChromePlusSupportedBrowser($SelectedBrowserType)
	Local $HasPatch = $IsChrome And IsChromePlusPatchInstalled($BrowserPath)
	Local $CanInstallPatch = $IsChrome And FileExists($BrowserPath) And GetChromePlusConfigPath($BrowserPath) <> ""

	If $HasPatch Then
		GUICtrlSetData($hChromePlusHint, _t("ChromePlusTabsReady", "已检测到 Chrome++ 补丁，以下设置将写入当前目录的 chrome++.ini [tabs]。"))
		GUICtrlSetData($hChromePlusConfigPath, GetChromePlusConfigPath($BrowserPath))
		GUICtrlSetData($hChromePlusDownloadPatch, _t("UpdateChromePlusPatch", "更新 Chrome++"))
		GUICtrlSetState($hChromePlusDownloadPatch, $GUI_SHOW)
		SetChromePlusTabControlsState(True)
		LoadChromePlusTabsSettings(GetChromePlusConfigPath($BrowserPath))
		UpdateChromePlusVersionLabels()
		BeginChromePlusVersionLoad()
		Return
	EndIf

	If $IsChrome Then
		GUICtrlSetData($hChromePlusHint, _t("ChromePlusTabsPatchMissing", "当前浏览器目录未检测到 Chrome++ 补丁（version.dll），安装后才可修改这些选项。"))
		GUICtrlSetData($hChromePlusConfigPath, GetChromePlusConfigPath($BrowserPath))
		GUICtrlSetData($hChromePlusDownloadPatch, _t("DownloadChromePlusPatch", "下载并安装 Chrome++"))
		GUICtrlSetState($hChromePlusDownloadPatch, $GUI_SHOW)
		If $CanInstallPatch Then
			GUICtrlSetState($hChromePlusDownloadPatch, $GUI_ENABLE)
		Else
			GUICtrlSetState($hChromePlusDownloadPatch, $GUI_DISABLE)
		EndIf
		UpdateChromePlusVersionLabels()
		BeginChromePlusVersionLoad()
	Else
		If $IsChromium Then
			GUICtrlSetData($hChromePlusHint, _t("ChromePlusTabsUnsupportedBrowser", "Chrome++ 暂未兼容当前浏览器。"))
		Else
			GUICtrlSetData($hChromePlusHint, _t("ChromePlusTabsRequireChrome", "当前仅在 Chrome 系浏览器下可配置 Chrome++ 标签页选项。"))
		EndIf
		GUICtrlSetData($hChromePlusConfigPath, "")
		GUICtrlSetState($hChromePlusDownloadPatch, $GUI_HIDE)
		GUICtrlSetState($hChromePlusDownloadPatch, $GUI_DISABLE)
		CancelChromePlusVersionLoad()
		UpdateChromePlusVersionLabels()
	EndIf

	SetChromePlusTabControlsState(False)
	RefreshChromePlusNewTabDisableNameState()
EndFunc   ;==>RefreshChromePlusTabState

Func DownloadChromePlusPatchFromSettings()
	Local $BrowserPath = GetCurrentSettingsBrowserPath()
	If InstallChromePlusPatchInteractive($BrowserPath) Then RefreshChromePlusTabState()
EndFunc   ;==>DownloadChromePlusPatchFromSettings

Func UpdateChromePlusVersionLabels($Unavailable = False)
	If Not $hChromePlusCurrentVersion Or Not $hChromePlusLatestVersion Then Return

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
	GUICtrlSetData($hChromePlusCurrentVersion, $CurrentVersion)
	GUICtrlSetData($hChromePlusLatestVersion, $LatestVersion)
	UpdateChromePlusDownloadPatchState()
EndFunc   ;==>UpdateChromePlusVersionLabels

Func UpdateChromePlusDownloadPatchState()
	If Not $hChromePlusDownloadPatch Then Return

	Local $BrowserPath = GetCurrentSettingsBrowserPath()
	Local $IsChrome = IsChromePlusSupportedBrowser(GetSelectedBrowserType())
	Local $HasPatch = $IsChrome And IsChromePlusPatchInstalled($BrowserPath)
	Local $CanInstallPatch = $IsChrome And FileExists($BrowserPath) And GetChromePlusConfigPath($BrowserPath) <> ""
	If Not $IsChrome Then
		GUICtrlSetState($hChromePlusDownloadPatch, $GUI_HIDE)
		GUICtrlSetState($hChromePlusDownloadPatch, $GUI_DISABLE)
		Return
	EndIf

	GUICtrlSetState($hChromePlusDownloadPatch, $GUI_SHOW)
	If Not $HasPatch Then
		If $CanInstallPatch Then
			GUICtrlSetState($hChromePlusDownloadPatch, $GUI_ENABLE)
		Else
			GUICtrlSetState($hChromePlusDownloadPatch, $GUI_DISABLE)
		EndIf
		Return
	EndIf

	If Not $CanInstallPatch Then
		GUICtrlSetState($hChromePlusDownloadPatch, $GUI_DISABLE)
		Return
	EndIf

	Local $CurrentVersion = NormalizeChromePlusVersionText(GetChromePlusInstalledVersion($BrowserPath))
	Local $LatestVersion = NormalizeChromePlusVersionText(GetChromePlusVersionFromTag($ChromePlusReleaseTag))
	If $LatestVersion = "" Or $CurrentVersion = "" Or VersionCompare($LatestVersion, $CurrentVersion) > 0 Then
		GUICtrlSetState($hChromePlusDownloadPatch, $GUI_ENABLE)
	Else
		GUICtrlSetState($hChromePlusDownloadPatch, $GUI_DISABLE)
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
	If Not $hChromePlusLatestVersion Then Return
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

	If IniWrite($ConfigPath, "tabs", "double_click_close", GetCheckboxIniValue($hChromePlusDoubleClickClose)) = 0 Then Return False
	If IniWrite($ConfigPath, "tabs", "right_click_close", GetCheckboxIniValue($hChromePlusRightClickClose)) = 0 Then Return False
	If IniWrite($ConfigPath, "tabs", "keep_last_tab", GetCheckboxIniValue($hChromePlusKeepLastTab)) = 0 Then Return False
	If IniWrite($ConfigPath, "tabs", "wheel_tab", GetCheckboxIniValue($hChromePlusWheelTab)) = 0 Then Return False
	If IniWrite($ConfigPath, "tabs", "wheel_tab_when_press_rbutton", GetCheckboxIniValue($hChromePlusWheelTabWhenPressRButton)) = 0 Then Return False
	If IniWrite($ConfigPath, "tabs", "open_url_new_tab", GetCheckboxIniValue($hChromePlusOpenUrlNewTab)) = 0 Then Return False
	If IniWrite($ConfigPath, "tabs", "open_bookmark_new_tab", GetCheckboxIniValue($hChromePlusOpenBookmarkNewTab)) = 0 Then Return False
	If IniWrite($ConfigPath, "tabs", "new_tab_disable", GetCheckboxIniValue($hChromePlusNewTabDisable)) = 0 Then Return False
	If Not WriteIniTextValue($ConfigPath, "tabs", "new_tab_disable_name", StringStripWS(GUICtrlRead($hChromePlusNewTabDisableName), 3)) Then Return False
	Return True
EndFunc   ;==>SaveChromePlusTabsSettings

Func RefreshCopyProfileState()
	If Not $hCopyProfile Then Return
	Local $CurrentBrowserType = GetSelectedBrowserType()
	Local $SelectedChannel = "release"
	If $hChannel Then $SelectedChannel = GUICtrlRead($hChannel)
	$DefaultProfDir = GetSystemProfileSourceDir($CurrentBrowserType, $SelectedChannel)

	Local $SourceMarker = "\prefs.js"
	If IsChromeBrowser($CurrentBrowserType) Then $SourceMarker = "\Local State"
	Local $TargetProfileDir = FullPath($ProfileDir)
	If $hProfileDir Then $TargetProfileDir = FullPath(GUICtrlRead($hProfileDir))

	If $DefaultProfDir <> "" And FileExists($DefaultProfDir & $SourceMarker) Then
		GUICtrlSetState($hCopyProfile, $GUI_ENABLE)
		If $FirstRun And Not FileExists($TargetProfileDir & $SourceMarker) Then GUICtrlSetState($hCopyProfile, $GUI_CHECKED)
	Else
		GUICtrlSetState($hCopyProfile, $GUI_UNCHECKED)
		GUICtrlSetState($hCopyProfile, $GUI_DISABLE)
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

	Local $CurrentBrowserPath = ""
	If $hFirefoxPath Then $CurrentBrowserPath = StringLower(GUICtrlRead($hFirefoxPath))
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
	If NormalizeBrowserType($Value) = $BrowserHelium Then $Options = "release"
	If NormalizeBrowserType($Value) = $BrowserWhale Then $Options = "release"
	If NormalizeBrowserType($Value) = $BrowserCent Then $Options = "release"
	If NormalizeBrowserType($Value) = $BrowserVivaldi Then $Options = "release"
	If IsGoogleChromeBrowser($Value) Then
		$Options = "stable|beta|dev|canary"
		$DefaultChannel = "stable"
	EndIf
	If Not StringRegExp("|" & $Options & "|", "(?i)\|" & $SelectedChannel & "\|") Then $SelectedChannel = $DefaultChannel

	_SendMessage(GUICtrlGetHandle($hChannel), $CB_RESETCONTENT)
	GUICtrlSetData($hChannel, $Options, $SelectedChannel)
EndFunc   ;==>UpdateBrowserChannelOptions

Func GetFirefoxVersions()
	If IsObj($FirefoxVersionsObj) Then Return $FirefoxVersionsObj

	Local $sVersions = BinaryToString(InetRead($FirefoxVersionUrl, 1), 4)
	If @error Or $sVersions = "" Then Return SetError(1, 0, 0)

	If Not CacheFirefoxVersions($sVersions) Then Return SetError(1, 0, 0)
	Return $FirefoxVersionsObj
EndFunc   ;==>GetFirefoxVersions

Func CacheFirefoxVersions($sVersions)
	Local $oVersions = Json_Decode($sVersions)
	If @error Or Not Json_IsObject($oVersions) Then Return SetError(1, 0, 0)

	$FirefoxVersionsObj = $oVersions
	Return True
EndFunc   ;==>CacheFirefoxVersions

Func GetLatestFirefoxVersion($Channel)
	Local $VersionKey = "LATEST_FIREFOX_VERSION"

	Switch $Channel
		Case "beta"
			$VersionKey = "LATEST_FIREFOX_DEVEL_VERSION"
		Case "dev"
			$VersionKey = "FIREFOX_DEVEDITION"
		Case "esr"
			$VersionKey = "FIREFOX_ESR"
		Case "nightly"
			$VersionKey = "FIREFOX_NIGHTLY"
	EndSwitch

	Local $oVersions = GetFirefoxVersions()
	If @error Or Not IsObj($oVersions) Then Return ""

	Local $Version = Json_ObjGet($oVersions, $VersionKey)
	If @error Or $Version = "" Then Return ""

	Return $Version
EndFunc   ;==>GetLatestFirefoxVersion

Func GetFirefoxChannelLabel($Channel)
	Local $Version = GetLatestFirefoxVersion($Channel)
	If $Version = "" Then Return $Channel
	Return $Channel & " (" & $Version & ")"
EndFunc   ;==>GetFirefoxChannelLabel

Func GetZenUpdateXml($Channel)
	Local $sCachedUpdateXml = GetZenUpdateXmlCache($Channel)
	If $sCachedUpdateXml <> "" Then Return $sCachedUpdateXml

	$Channel = GetZenUpdateChannel($Channel)
	Local $sUpdateXml = BinaryToString(InetRead($ZenUpdateBaseUrl & "/" & $Channel & "/update.xml", 1), 4)
	If @error Or $sUpdateXml = "" Then Return SetError(1, 0, "")
	SetZenUpdateXml($Channel, $sUpdateXml)
	Return $sUpdateXml
EndFunc   ;==>GetZenUpdateXml

Func GetZenUpdateXmlCache($Channel)
	$Channel = GetZenUpdateChannel($Channel)
	If $Channel = "twilight" Then Return $ZenTwilightUpdateXml
	Return $ZenReleaseUpdateXml
EndFunc   ;==>GetZenUpdateXmlCache

Func SetZenUpdateXml($Channel, $sUpdateXml)
	$Channel = GetZenUpdateChannel($Channel)
	If $Channel = "twilight" Then
		$ZenTwilightUpdateXml = $sUpdateXml
	Else
		$ZenReleaseUpdateXml = $sUpdateXml
	EndIf
EndFunc   ;==>SetZenUpdateXml

Func GetLatestZenVersion($Channel)
	Local $sUpdateXml = GetZenUpdateXml($Channel)
	If @error Or $sUpdateXml = "" Then Return ""

	Local $match = StringRegExp($sUpdateXml, 'displayVersion="([^"]+)"', 1)
	If @error Then Return ""
	Return $match[0]
EndFunc   ;==>GetLatestZenVersion

Func GetLatestZenReleaseTag($Channel)
	Local $sUpdateXml = GetZenUpdateXml($Channel)
	If @error Or $sUpdateXml = "" Then Return ""

	Local $match = StringRegExp($sUpdateXml, '/releases/download/([^/]+)/', 1)
	If @error Then Return ""
	Return $match[0]
EndFunc   ;==>GetLatestZenReleaseTag

Func GetZenChannelLabel($Channel)
	Local $Version = GetLatestZenVersion($Channel)
	If $Version = "" Then Return $Channel
	Return $Channel & " (" & $Version & ")"
EndFunc   ;==>GetZenChannelLabel

Func GetZenUpdateChannel($Channel)
	If $Channel = "twilight" Then Return "twilight"
	Return "release"
EndFunc   ;==>GetZenUpdateChannel

Func CacheFloorpReleaseInfo($Content)
	$FloorpReleaseInfoLoaded = True
	$FloorpReleaseTag = ""

	Local $Match = StringRegExp($Content, '(?i)/' & $FloorpRepo & '/releases/tag/([^"#?<>\s]+)', 1)
	If Not @error Then
		$FloorpReleaseTag = $Match[0]
		Return True
	EndIf

	$Match = StringRegExp($Content, '(?i)Release\s+Floorp\s+([0-9][^<\s]+)', 1)
	If Not @error Then $FloorpReleaseTag = "v" & $Match[0]

	Return True
EndFunc   ;==>CacheFloorpReleaseInfo

Func GetLatestFloorpVersion()
	If $FloorpReleaseTag = "" Then Return ""
	Return StringRegExpReplace($FloorpReleaseTag, "(?i)^v", "")
EndFunc   ;==>GetLatestFloorpVersion

Func GetFloorpChannelLabel($Channel)
	Local $Version = GetLatestFloorpVersion()
	If $Version = "" Then Return $Channel
	Return $Channel & " (" & $Version & ")"
EndFunc   ;==>GetFloorpChannelLabel

Func GetWaterfoxReleasePage()
	If $WaterfoxReleaseInfoLoaded Then Return True

	Local $Content = BinaryToString(InetRead($WaterfoxDownloadPageUrl, 1), 4)
	If @error Or $Content = "" Then Return SetError(1, 0, False)

	Return CacheWaterfoxReleaseInfo($Content)
EndFunc   ;==>GetWaterfoxReleasePage

Func CacheWaterfoxReleaseInfo($Content)
	$WaterfoxReleaseInfoLoaded = False
	$WaterfoxReleaseVersion = ""

	Local $Match = StringRegExp($Content, '(?i)cdn\.waterfox\.com/waterfox/releases/([0-9][^/"#?<>\s]+)/WINNT_x86_64/Waterfox%20Setup%20[^"#?<>\s]+\.exe', 1)
	If @error Then $Match = StringRegExp($Content, '(?i)Waterfox%20Setup%20([0-9][^/"#?<>\s]+)\.exe', 1)
	If @error Then $Match = StringRegExp($Content, '(?i)Waterfox\s+Setup\s+([0-9][^/"#?<>\s]+)\.exe', 1)

	If @error Then Return False
	$WaterfoxReleaseVersion = $Match[0]
	$WaterfoxReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheWaterfoxReleaseInfo

Func GetLatestWaterfoxVersion()
	If $WaterfoxReleaseVersion = "" Then Return ""
	Return $WaterfoxReleaseVersion
EndFunc   ;==>GetLatestWaterfoxVersion

Func GetWaterfoxChannelLabel($Channel)
	Local $Version = GetLatestWaterfoxVersion()
	If $Version = "" Then Return $Channel
	Return $Channel & " (" & $Version & ")"
EndFunc   ;==>GetWaterfoxChannelLabel

Func GetHeliumReleasePage()
	If $HeliumReleaseInfoLoaded Then Return True

	Local $Content = BinaryToString(InetRead($HeliumLatestReleaseUrl, 1), 4)
	If @error Or $Content = "" Then Return SetError(1, 0, False)

	Return CacheHeliumReleaseInfo($Content)
EndFunc   ;==>GetHeliumReleasePage

Func CacheHeliumReleaseInfo($Content)
	$HeliumReleaseInfoLoaded = False
	$HeliumReleaseTag = ""

	Local $Match = StringRegExp($Content, '(?i)"tag_name"\s*:\s*"([^"]+)"', 1)
	If @error Then $Match = StringRegExp($Content, '(?i)/' & $HeliumRepo & '/releases/tag/([^"#?<>\s]+)', 1)
	If @error Then Return False

	$HeliumReleaseTag = $Match[0]
	$HeliumReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheHeliumReleaseInfo

Func GetLatestHeliumVersion()
	If $HeliumReleaseTag = "" Then Return ""
	Return StringRegExpReplace($HeliumReleaseTag, "(?i)^v", "")
EndFunc   ;==>GetLatestHeliumVersion

Func GetHeliumChannelLabel($Channel)
	Local $Version = GetLatestHeliumVersion()
	If $Version = "" Then Return $Channel
	Return $Channel & " (" & $Version & ")"
EndFunc   ;==>GetHeliumChannelLabel

Func GetCentReleasePage()
	If $CentReleaseInfoLoaded Then Return True

	Local $Content = BinaryToString(InetRead($CentBrowserDownloadPageUrl, 1), 4)
	If @error Or $Content = "" Then Return SetError(1, 0, False)

	Return CacheCentReleaseInfo($Content)
EndFunc   ;==>GetCentReleasePage

Func CacheCentReleaseInfo($Content)
	$CentReleaseInfoLoaded = False
	$CentReleaseVersion = ""
	$CentDownloadUrl = ""

	Local $Match = StringRegExp($Content, '(?is)href="([^"]*centbrowser_([0-9][0-9.]*)_x64_portable\.exe)"', 1)
	If @error Then $Match = StringRegExp($Content, '(?is)href="([^"]*centbrowser_([0-9][0-9.]*)_x64\.exe)"', 1)
	If @error Then Return False

	$CentDownloadUrl = NormalizeCentDownloadUrl($Match[0])
	$CentReleaseVersion = $Match[1]
	If $CentReleaseVersion = "" Then
		$Match = StringRegExp($Content, '(?is)Version:\s*([0-9][0-9.]*)', 1)
		If Not @error Then $CentReleaseVersion = $Match[0]
	EndIf

	If $CentDownloadUrl = "" Then Return False
	$CentReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheCentReleaseInfo

Func NormalizeCentDownloadUrl($Url)
	$Url = DecodeXmlAttribute(StringStripWS($Url, 3))
	If $Url = "" Then Return ""
	If StringLeft($Url, 2) = "//" Then Return "https:" & $Url
	If StringRegExp($Url, "(?i)^https?://") Then Return $Url
	If StringLeft($Url, 1) = "/" Then Return "https://www.centbrowser.com" & $Url
	Return $CentBrowserDownloadPageUrl & $Url
EndFunc   ;==>NormalizeCentDownloadUrl

Func GetLatestCentVersion()
	If $CentReleaseVersion = "" Then Return ""
	Return $CentReleaseVersion
EndFunc   ;==>GetLatestCentVersion

Func GetCentChannelLabel($Channel)
	Local $Version = GetLatestCentVersion()
	If $Version = "" Then Return $Channel
	Return $Channel & " (" & $Version & ")"
EndFunc   ;==>GetCentChannelLabel

Func GetVivaldiReleasePage()
	If $VivaldiReleaseInfoLoaded Then Return True

	Local $Content = BinaryToString(InetRead($VivaldiDownloadPageUrl, 1), 4)
	If @error Or $Content = "" Then Return SetError(1, 0, False)

	Return CacheVivaldiReleaseInfo($Content)
EndFunc   ;==>GetVivaldiReleasePage

Func CacheVivaldiReleaseInfo($Content)
	$VivaldiReleaseInfoLoaded = False
	$VivaldiReleaseVersion = ""
	$VivaldiDownloadUrl = ""

	Local $Match = StringRegExp($Content, '(?is)(https?://downloads\.vivaldi\.com/stable/Vivaldi\.([0-9][0-9.]*)\.x64\.exe)', 1)
	If @error Then Return False

	$VivaldiDownloadUrl = DecodeXmlAttribute($Match[0])
	$VivaldiReleaseVersion = $Match[1]
	If $VivaldiDownloadUrl = "" Or $VivaldiReleaseVersion = "" Then Return False

	$VivaldiReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheVivaldiReleaseInfo

Func GetLatestVivaldiVersion()
	If $VivaldiReleaseVersion = "" Then Return ""
	Return $VivaldiReleaseVersion
EndFunc   ;==>GetLatestVivaldiVersion

Func GetVivaldiChannelLabel($Channel)
	Local $Version = GetLatestVivaldiVersion()
	If $Version = "" Then Return $Channel
	Return $Channel & " (" & $Version & ")"
EndFunc   ;==>GetVivaldiChannelLabel

Func GetChromeChannelLabel($Channel, $LoadVersion = False)
	$Channel = NormalizeChromeChannel($Channel)
	Local $Version = ""
	If $LoadVersion Then $Version = GetChromeVersionCache($Channel)
	Switch StringLower($Channel)
		Case "beta"
			If $Version <> "" Then Return "beta (" & $Version & ")"
			Return "beta"
		Case "dev"
			If $Version <> "" Then Return "dev (" & $Version & ")"
			Return "dev"
		Case "canary"
			If $Version <> "" Then Return "canary (" & $Version & ")"
			Return "canary"
	EndSwitch
	If $Version <> "" Then Return "stable (" & $Version & ")"
	Return "stable"
EndFunc   ;==>GetChromeChannelLabel

Func GetLatestFirefoxProduct($Channel)
	Switch $Channel
		Case "release", "default"
			Return "firefox-latest"
		Case "beta"
			Return "firefox-beta-latest"
		Case "esr"
			Return "firefox-esr-latest"
		Case "dev"
			Return "firefox-devedition-latest"
		Case Else ; nightly
			Return "firefox-nightly-latest"
	EndSwitch
EndFunc   ;==>GetLatestFirefoxProduct

Func GetFirefoxDownloadLanguage()
	Return GetBrowserLocale("zh-CN")
EndFunc   ;==>GetFirefoxDownloadLanguage

Func GetBrowserLocale($DefaultLocale = "")
	Local $lang = StringReplace($LANGUAGE, "_", "-")
	If $lang = "" Then Return $DefaultLocale
	If Not StringRegExp($lang, "^[A-Za-z]{2,3}(-[A-Za-z0-9]+)*$") Then Return $DefaultLocale
	Return $lang
EndFunc   ;==>GetBrowserLocale

Func BuildFirefoxDownloadUrl($Channel, $os)
	Local $Version = ""
	If IsObj($FirefoxVersionsObj) Then $Version = GetLatestFirefoxVersion($Channel)
	Local $lang = GetFirefoxDownloadLanguage()
	If $Version = "" Then
		Return "https://download.mozilla.org/?product=" & GetLatestFirefoxProduct($Channel) & "&os=" & $os & "&lang=" & $lang
	EndIf

	If $Channel = "dev" Then
		Return "https://ftp.mozilla.org/pub/devedition/releases/" & $Version & "/" & $os & "/" & $lang & "/Firefox%20Setup%20" & $Version & ".exe"
	EndIf

	If $Channel = "nightly" Then
		Local $nightlyOs = "win32"
		If $os = "win64" Then $nightlyOs = "win64"
		Return "https://ftp.mozilla.org/pub/firefox/nightly/latest-mozilla-central-l10n/firefox-" & $Version & "." & $lang & "." & $nightlyOs & ".installer.exe"
	EndIf

	Return "https://ftp.mozilla.org/pub/firefox/releases/" & $Version & "/" & $os & "/" & $lang & "/Firefox%20Setup%20" & $Version & ".exe"
EndFunc   ;==>BuildFirefoxDownloadUrl

Func BuildZenDownloadUrl($Channel, $os)
	Local $ReleaseTag = ""
	If GetZenUpdateXmlCache($Channel) <> "" Then $ReleaseTag = GetLatestZenReleaseTag($Channel)
	If $ReleaseTag = "" Then Return "https://github.com/zen-browser/desktop/releases/latest/download/zen.installer.exe"
	Return "https://github.com/zen-browser/desktop/releases/download/" & $ReleaseTag & "/zen.installer.exe"
EndFunc   ;==>BuildZenDownloadUrl

Func BuildFloorpDownloadUrl($Channel, $os)
	If $FloorpReleaseTag = "" Then Return "https://github.com/" & $FloorpRepo & "/releases/latest/download/" & $FloorpWindowsX64Asset
	Return "https://github.com/" & $FloorpRepo & "/releases/download/" & $FloorpReleaseTag & "/" & $FloorpWindowsX64Asset
EndFunc   ;==>BuildFloorpDownloadUrl

Func BuildWaterfoxDownloadUrl($Channel, $os)
	Local $Version = GetLatestWaterfoxVersion()
	If $Version = "" Then
		If Not GetWaterfoxReleasePage() Then Return SetError(1, 0, "")
		$Version = GetLatestWaterfoxVersion()
	EndIf
	If $Version = "" Then Return SetError(2, 0, "")
	Return "https://cdn.waterfox.com/waterfox/releases/" & $Version & "/WINNT_x86_64/Waterfox%20Setup%20" & $Version & ".exe"
EndFunc   ;==>BuildWaterfoxDownloadUrl

Func BuildHeliumDownloadUrl($Channel, $os)
	Local $Version = GetLatestHeliumVersion()
	If $Version = "" Then
		If Not GetHeliumReleasePage() Then Return SetError(1, 0, "")
		$Version = GetLatestHeliumVersion()
	EndIf
	If $Version = "" Or $HeliumReleaseTag = "" Then Return SetError(2, 0, "")
	Return "https://github.com/" & $HeliumRepo & "/releases/download/" & $HeliumReleaseTag & "/helium_" & $Version & "_x64-windows.zip"
EndFunc   ;==>BuildHeliumDownloadUrl

Func BuildCentDownloadUrl($Channel, $os)
	If $os <> "win64" Then Return SetError(1, 0, "")
	If $CentDownloadUrl = "" Then
		If Not GetCentReleasePage() Then Return SetError(1, 0, "")
	EndIf
	If $CentDownloadUrl = "" Then Return SetError(2, 0, "")
	Return $CentDownloadUrl
EndFunc   ;==>BuildCentDownloadUrl

Func BuildVivaldiDownloadUrl($Channel, $os)
	If $os <> "win64" Then Return SetError(1, 0, "")
	If $VivaldiDownloadUrl = "" Then
		If Not GetVivaldiReleasePage() Then Return SetError(1, 0, "")
	EndIf
	If $VivaldiDownloadUrl = "" Then Return SetError(2, 0, "")
	Return $VivaldiDownloadUrl
EndFunc   ;==>BuildVivaldiDownloadUrl

Func BuildWhaleDownloadUrl($Channel, $os)
	If $os <> "win64" Then Return SetError(1, 0, "")
	Return $WhaleStandaloneX64Url
EndFunc   ;==>BuildWhaleDownloadUrl

Func BuildChromeDownloadUrl($Channel, $os)
	Local $DownloadUrl = GetChromeDownloadUrlCache($Channel)
	If $DownloadUrl <> "" Then Return $DownloadUrl
	If Not LoadChromeUpdateInfo($Channel, $os) Then Return SetError(1, 0, "")
	$DownloadUrl = GetChromeDownloadUrlCache($Channel)
	If $DownloadUrl = "" Then Return SetError(2, 0, "")
	Return $DownloadUrl
EndFunc   ;==>BuildChromeDownloadUrl

Func LoadChromeUpdateInfo($Channel, $os)
	$Channel = NormalizeChromeChannel($Channel)
	Local $AppId = "{8A69D345-D564-463C-AFF1-A69D9E530F96}"
	Local $Ap = "x64-stable-multi-chrome"
	Local $Arch = "x64"
	If $os <> "win64" Then
		$Ap = ""
		$Arch = "x86"
	EndIf

	Switch StringLower($Channel)
		Case "beta"
			If $Arch = "x86" Then
				$Ap = "1.1-beta"
			Else
				$Ap = "x64-beta-multi-chrome"
			EndIf
		Case "dev"
			If $Arch = "x86" Then
				$Ap = "2.0-dev"
			Else
				$Ap = "x64-dev-statsdef_1"
			EndIf
		Case "canary"
			$AppId = "{4EA16AC7-FD5A-47C3-875B-DBF4A2008C20}"
			If $Arch = "x86" Then
				$Ap = ""
			Else
				$Ap = "x64-canary"
			EndIf
	EndSwitch

	Local $RequestXml = BuildChromeUpdateRequest($AppId, $Ap, $Arch)
	Local $ResponseXml = ChromeUpdatePost($RequestXml)
	If @error Or $ResponseXml = "" Then Return False

	Local $Version = StringRegExp($ResponseXml, '(?is)<manifest[^>]+version="([^"]+)"', 1)
	Local $Package = StringRegExp($ResponseXml, '(?is)<package[^>]+name="([^"]+)"', 1)
	Local $Urls = StringRegExp($ResponseXml, '(?is)<url[^>]+codebase="([^"]+)"', 3)
	If @error Or Not IsArray($Version) Or Not IsArray($Package) Or Not IsArray($Urls) Then Return False

	Local $BaseUrl = SelectChromeDownloadBaseUrl($Urls)
	If $BaseUrl = "" Then Return False

	SetChromeUpdateCache($Channel, DecodeXmlAttribute($Version[0]), DecodeXmlAttribute($BaseUrl) & DecodeXmlAttribute($Package[0]))
	Return True
EndFunc   ;==>LoadChromeUpdateInfo

Func StartChromeVersionLoadProcess($Channel, $os, $OutputFile)
	Local $Command = ""
	If @Compiled Then
		$Command = '"' & @AutoItExe & '"'
	Else
		$Command = '"' & @AutoItExe & '" "' & @ScriptFullPath & '"'
	EndIf
	$Command &= ' --load-chrome-version "' & $Channel & '" "' & $os & '" "' & $OutputFile & '"'
	Return Run($Command, @ScriptDir, @SW_HIDE)
EndFunc   ;==>StartChromeVersionLoadProcess

Func WriteChromeUpdateInfoFile($Channel, $os, $OutputFile)
	FileDelete($OutputFile)
	If LoadChromeUpdateInfo($Channel, $os) Then
		IniWrite($OutputFile, "Chrome", "Success", 1)
		IniWrite($OutputFile, "Chrome", "Version", GetChromeVersionCache($Channel))
		IniWrite($OutputFile, "Chrome", "DownloadUrl", GetChromeDownloadUrlCache($Channel))
	Else
		IniWrite($OutputFile, "Chrome", "Success", 0)
	EndIf
EndFunc   ;==>WriteChromeUpdateInfoFile

Func LoadChromeUpdateInfoFile($Channel, $OutputFile)
	If Not FileExists($OutputFile) Then Return False
	If IniRead($OutputFile, "Chrome", "Success", 0) <> 1 Then Return False

	Local $Version = IniRead($OutputFile, "Chrome", "Version", "")
	Local $DownloadUrl = IniRead($OutputFile, "Chrome", "DownloadUrl", "")
	If $Version = "" Or $DownloadUrl = "" Then Return False

	SetChromeUpdateCache($Channel, $Version, $DownloadUrl)
	Return True
EndFunc   ;==>LoadChromeUpdateInfoFile

Func NormalizeChromeChannel($Channel)
	Switch StringLower($Channel)
		Case "beta", "dev", "canary"
			Return StringLower($Channel)
	EndSwitch
	Return "stable"
EndFunc   ;==>NormalizeChromeChannel

Func GetChromeVersionCache($Channel)
	Switch NormalizeChromeChannel($Channel)
		Case "beta"
			Return $ChromeBetaVersion
		Case "dev"
			Return $ChromeDevVersion
		Case "canary"
			Return $ChromeCanaryVersion
	EndSwitch
	Return $ChromeStableVersion
EndFunc   ;==>GetChromeVersionCache

Func GetChromeDownloadUrlCache($Channel)
	Switch NormalizeChromeChannel($Channel)
		Case "beta"
			Return $ChromeBetaDownloadUrl
		Case "dev"
			Return $ChromeDevDownloadUrl
		Case "canary"
			Return $ChromeCanaryDownloadUrl
	EndSwitch
	Return $ChromeStableDownloadUrl
EndFunc   ;==>GetChromeDownloadUrlCache

Func SetChromeUpdateCache($Channel, $Version, $DownloadUrl)
	Switch NormalizeChromeChannel($Channel)
		Case "beta"
			$ChromeBetaVersion = $Version
			$ChromeBetaDownloadUrl = $DownloadUrl
		Case "dev"
			$ChromeDevVersion = $Version
			$ChromeDevDownloadUrl = $DownloadUrl
		Case "canary"
			$ChromeCanaryVersion = $Version
			$ChromeCanaryDownloadUrl = $DownloadUrl
		Case Else
			$ChromeStableVersion = $Version
			$ChromeStableDownloadUrl = $DownloadUrl
	EndSwitch
EndFunc   ;==>SetChromeUpdateCache

Func BuildChromeUpdateRequest($AppId, $Ap, $Arch)
	Local $OsVersion = GetChromeOmahaOsVersion()
	Return '<?xml version="1.0" encoding="UTF-8"?><request protocol="3.0" version="1.3.23.9" shell_version="1.3.21.103" ismachine="0" sessionid="{3597644B-2952-4F92-AE55-D315F45F80A5}" installsource="ondemandcheckforupdate" requestid="{CD7523AD-A40D-49F4-AEEF-8C114B804658}" dedup="cr">' & _
			'<hw physmemory="12582912" sse="1" sse2="1" sse3="1" ssse3="1" sse41="1" sse42="1" avx="1"/>' & _
			'<os platform="win" version="' & $OsVersion & '" arch="' & $Arch & '"/>' & _
			'<app appid="' & $AppId & '" version="" nextversion="" ap="' & $Ap & '" lang="' & GetBrowserLocale("zh-CN") & '"><updatecheck/></app></request>'
EndFunc   ;==>BuildChromeUpdateRequest

Func GetChromeOmahaOsVersion()
	Switch @OSVersion
		Case "WIN_7"
			Return "6.1.0.0"
		Case "WIN_8"
			Return "6.2.0.0"
		Case "WIN_81"
			Return "6.3.0.0"
	EndSwitch
	Return "10.0.0.0"
EndFunc   ;==>GetChromeOmahaOsVersion

Func ChromeUpdatePost($RequestXml)
	Local $oError = ObjEvent("AutoIt.Error", "ChromeComError")
	Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
	If @error Or Not IsObj($oHTTP) Then Return SetError(1, 0, "")

	$oHTTP.SetTimeouts(5000, 5000, 15000, 30000)
	$oHTTP.Open("POST", $ChromeUpdateUrl, False)
	$oHTTP.SetRequestHeader("User-Agent", $ChromeUpdateUserAgent)
	$oHTTP.SetRequestHeader("Content-Type", "application/xml")
	$oHTTP.Send($RequestXml)
	If @error Then Return SetError(2, 0, "")
	If $oHTTP.Status < 200 Or $oHTTP.Status >= 300 Then Return SetError(3, 0, "")

	Return $oHTTP.ResponseText
EndFunc   ;==>ChromeUpdatePost

Func ChromeComError($oError)
	Return
EndFunc   ;==>ChromeComError

Func MaybeInstallChromePlusPatch($BrowserPath, $PreferredArch = "", $AfterDownload = False)
	If Not FileExists($BrowserPath) Then Return False
	If DetectBrowserTypeFromPath($BrowserPath) = $BrowserCent Then Return False
	If IsChromePlusPatchInstalled($BrowserPath) Then Return True

	Local $ConfirmText
	If $AfterDownload Then
		$ConfirmText = _t("InstallChromePlusPatchAfterDownloadConfirm", "浏览器已下载并解压完成。\n是否同时下载并安装 Chrome++ 补丁？")
	Else
		$ConfirmText = _t("InstallChromePlusPatchConfirm", "检测到当前浏览器目录未安装 Chrome++ 补丁。\n是否现在下载并安装？")
	EndIf

	If MsgBox(36 + 256, $CustomArch, $ConfirmText, 0, $hSettings) <> 6 Then Return False
	Return InstallChromePlusPatchInteractive($BrowserPath, $PreferredArch)
EndFunc   ;==>MaybeInstallChromePlusPatch

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

	ShowDownloadProgress(_t("ChromePlusPatchProgressTitle", "正在准备 Chrome++ 补丁"), _t("PreparingChromePlusPatch", "正在准备 Chrome++ 补丁 ..."), _t("PreparingChromePlusPatchDetail", "正在读取补丁版本信息，请稍候 ..."))

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
					If IsDownloadProgressCancelled() Then
						CloseDownloadProgress()
						If $hStatus Then _GUICtrlStatusBar_SetText($hStatus, _t("ChromePlusPatchInstallCancelled", "已取消 Chrome++ 补丁下载。"))
						Return False
					EndIf
					$ErrorMessage = _t("FailToDownloadChromePlusPatch", "下载 Chrome++ 补丁失败。")
				EndIf
			EndIf

			If $ErrorMessage = "" Then
				$SevenZipExe = PrepareSevenZipTool($VersionDir)
				If @error Or $SevenZipExe = "" Then
					$ErrorMessage = _t("FailToExtractChromePlusPatch", "解压或安装 Chrome++ 补丁失败。")
				Else
					If FileExists($ExtractDir) Then DirRemove($ExtractDir, 1)
					If Not FileExists($ExtractDir) Then DirCreate($ExtractDir)
					SetDownloadProgressBusy(_t("ExtractingChromePlusPatch", "正在安装 Chrome++ 补丁，请稍候 ..."), _t("ExtractingChromePlusPatchDetail", "安装期间请不要关闭 {AppName}。"))
					$ExtractLog = $VersionDir & "\extract.log"
					$InstallLog &= "Extract log: " & $ExtractLog & @CRLF
					$ExtractPid = Run(@ComSpec & ' /c ""' & $SevenZipExe & '" x -y -bd -bb1 -o"' & $ExtractDir & '" "' & $ArchivePath & '" > "' & $ExtractLog & '" 2>&1"', $VersionDir, @SW_HIDE)
					If @error Or Not $ExtractPid Then
						$InstallLog &= "Failed to start extractor. @error=" & @error & @CRLF
						$ErrorMessage = _t("FailToExtractChromePlusPatch", "解压或安装 Chrome++ 补丁失败。")
					Else
						While ProcessExists($ExtractPid)
							Sleep(150)
						WEnd
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

	CloseDownloadProgress()
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
	Local $aUrls = _UpgradeBuildGithubReleaseDownloadUrls($ArchiveUrl, $GithubDirectMirror, $GithubJsDelivrMirror)
	Local $TargetDir, $TargetFile
	SplitPath($ArchivePath, $TargetDir, $TargetFile)
	If Not FileExists($TargetDir) Then DirCreate($TargetDir)

	Local $i, $ret, $hDownload, $DownloadedBytes, $TotalBytes, $Percent, $DetailText
	For $i = 0 To UBound($aUrls) - 1
		$InstallLog &= "Trying archive URL: " & $aUrls[$i] & @CRLF
		FileDelete($ArchivePath)
		$hDownload = InetGet($aUrls[$i], $ArchivePath, 19, 1)
		If @error Or $hDownload = 0 Then
			$InstallLog &= "InetGet failed to start. @error=" & @error & ", handle=" & $hDownload & @CRLF
			ContinueLoop
		EndIf

		Do
			$DownloadedBytes = InetGetInfo($hDownload, 0)
			$TotalBytes = InetGetInfo($hDownload, 1)
			If $TotalBytes > 0 Then
				$Percent = Int($DownloadedBytes * 100 / $TotalBytes)
				If $Percent > 100 Then $Percent = 100
				$DetailText = _t("FirefoxDownloadProgressKnown", "已下载 {Downloaded} / {Total}")
				$DetailText = StringReplace($DetailText, "{Downloaded}", FormatBytes($DownloadedBytes))
				$DetailText = StringReplace($DetailText, "{Total}", FormatBytes($TotalBytes))
			Else
				$Percent = Mod(Int($DownloadedBytes / 65536), 100)
				$DetailText = _t("FirefoxDownloadProgressUnknown", "已下载 %s", FormatBytes($DownloadedBytes))
			EndIf
			UpdateDownloadProgress(_t("DownloadingChromePlusPatch", "正在下载 Chrome++ 补丁 ..."), $DetailText, $Percent)
			PumpDownloadProgressEvents()
			If IsDownloadProgressCancelled() Then ExitLoop
			Sleep(200)
		Until InetGetInfo($hDownload, 2)

		$ret = InetGetInfo($hDownload, 3)
		InetClose($hDownload)
		If IsDownloadProgressCancelled() Then Return False
		$InstallLog &= "Download result: " & $ret & ", file exists: " & FileExists($ArchivePath) & ", size: " & FileGetSize($ArchivePath) & @CRLF
		If $ret And FileExists($ArchivePath) And FileGetSize($ArchivePath) > 0 Then Return True
	Next
	Return False
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

	Local $HttpDiagnostic = ""
	Local $sJson = HttpGetTextDiagnostic($ChromePlusLatestApiUrl, $ChromePlusApiUserAgent, "application/vnd.github+json", $HttpDiagnostic)
	$InstallLog &= $HttpDiagnostic & @CRLF
	If $sJson <> "" Then
		Local $TagMatch = StringRegExp($sJson, '"tag_name"\s*:\s*"([^"]+)"', 1)
		If Not @error And IsArray($TagMatch) Then $CachedReleaseTag = $TagMatch[0]

		Local $UrlMatch = StringRegExp($sJson, '"browser_download_url"\s*:\s*"([^"]*Chrome(?:%2B%2B|\+\+)[^"]*x86_x64_arm64\.7z)"', 1)
		If Not @error And IsArray($UrlMatch) Then $CachedArchiveUrl = StringReplace($UrlMatch[0], '\/', '/')
		$InstallLog &= "API parsed tag: " & $CachedReleaseTag & @CRLF
		$InstallLog &= "API parsed archive URL: " & $CachedArchiveUrl & @CRLF
	EndIf

	If $CachedReleaseTag = "" Then
		Local $LatestPageUrl = _UpgradeBuildGithubPageUrl("https://github.com/" & $ChromePlusRepo & "/releases/latest", $GithubDirectMirror)
		$InstallLog &= "Fallback latest page URL: " & $LatestPageUrl & @CRLF
		Local $LatestPageBinary = InetRead($LatestPageUrl, 1)
		Local $InetReadError = @error
		Local $LatestPage = BinaryToString($LatestPageBinary, 4)
		$InstallLog &= "Fallback InetRead @error: " & $InetReadError & ", bytes: " & BinaryLen($LatestPageBinary) & ", text length: " & StringLen($LatestPage) & @CRLF
		If $LatestPage <> "" Then
			Local $TagMatch = StringRegExp($LatestPage, '/' & $ChromePlusRepo & '/releases/tag/([^"?/#<>]+)', 1)
			If Not @error And IsArray($TagMatch) Then $CachedReleaseTag = $TagMatch[0]
			$InstallLog &= "Fallback parsed tag: " & $CachedReleaseTag & @CRLF
		EndIf
	EndIf

	If $CachedReleaseTag = "" Then
		Local $GitCodeDiagnostic = ""
		Local $GitCodeJson = HttpGetTextDiagnostic($ChromePlusGitCodeTagsApiUrl, $ChromePlusApiUserAgent, "application/json", $GitCodeDiagnostic, $ChromePlusGitCodeTagsUrl)
		$InstallLog &= "GitCode tags fallback page: " & $ChromePlusGitCodeTagsUrl & @CRLF
		$InstallLog &= $GitCodeDiagnostic & @CRLF
		If $GitCodeJson <> "" Then
			Local $GitCodeTagMatch = StringRegExp($GitCodeJson, '"content"\s*:\s*\[\s*\{\s*"name"\s*:\s*"([^"]+)"', 1)
			If Not @error And IsArray($GitCodeTagMatch) Then $CachedReleaseTag = $GitCodeTagMatch[0]
			$InstallLog &= "GitCode parsed tag: " & $CachedReleaseTag & @CRLF
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
	Return FileWrite($ConfigPath, BuildChromePlusManagedConfig()) > 0
EndFunc   ;==>WriteChromePlusManagedConfig

Func BuildChromePlusManagedConfig()
	Return "; Managed by RunFirefox for Chrome++" & @CRLF & _
			"; Remove this header if you want to keep a fully custom chrome++.ini." & @CRLF & _
			"[general]" & @CRLF & _
			"data_dir=none" & @CRLF & _
			"cache_dir=none" & @CRLF & _
			"command_line=" & @CRLF & _
			"launch_on_startup=" & @CRLF & _
			"launch_on_exit=" & @CRLF & _
			"boss_key=" & @CRLF & _
			"translate_key=" & @CRLF & _
			"show_password=0" & @CRLF & _
			"win32k=0" & @CRLF & _
			"ignore_policies=0" & @CRLF & _
			@CRLF & _
			"[tabs]" & @CRLF & _
			"double_click_close=0" & @CRLF & _
			"right_click_close=1" & @CRLF & _
			"keep_last_tab=1" & @CRLF & _
			"wheel_tab=0" & @CRLF & _
			"wheel_tab_when_press_rbutton=0" & @CRLF & _
			"open_url_new_tab=0" & @CRLF & _
			"open_bookmark_new_tab=0" & @CRLF & _
			"new_tab_disable=1" & @CRLF & _
			'new_tab_disable_name="about:blank","新建标签"' & @CRLF & _
			@CRLF & _
			"[keymapping]" & @CRLF
EndFunc   ;==>BuildChromePlusManagedConfig

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
	Local $hDialog = GUICreate($CustomArch, 470, 220, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), -1, $hSettings)
	Local $hMessage = GUICtrlCreateEdit($Message, 15, 15, 440, 135, BitOR($ES_READONLY, $ES_MULTILINE, $WS_VSCROLL))
	Local $hViewLog = GUICtrlCreateButton(_t("ViewLog", "查看日志"), 255, 170, 90, 25)
	Local $hOK = GUICtrlCreateButton(_t("Confirm", "确定"), 365, 170, 90, 25)

	If $LogPath = "" Or Not FileExists($LogPath) Then GUICtrlSetState($hViewLog, $GUI_DISABLE)
	If $hSettings Then GUISetState(@SW_DISABLE, $hSettings)
	GUISetState(@SW_SHOW, $hDialog)

	Local $aMsg
	While 1
		$aMsg = GUIGetMsg(1)
		If IsArray($aMsg) And $aMsg[1] = $hDialog Then
			Switch $aMsg[0]
				Case $GUI_EVENT_CLOSE, $hOK
					ExitLoop
				Case $hViewLog
					If $LogPath <> "" And FileExists($LogPath) Then ShellExecute($LogPath)
			EndSwitch
		EndIf
		Sleep(20)
	WEnd

	GUIDelete($hDialog)
	If $hSettings Then GUISetState(@SW_ENABLE, $hSettings)
	Opt("GUIOnEventMode", $PreviousGuiMode)
EndFunc   ;==>ShowChromePlusPatchInstallFailedDialog

Func HttpGetTextDiagnostic($Url, $UserAgent, $Accept, ByRef $Diagnostic, $Referer = "")
	$Diagnostic = "GET " & $Url & @CRLF
	Local $oError = ObjEvent("AutoIt.Error", "ChromeComError")
	Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
	If @error Or Not IsObj($oHTTP) Then
		$Diagnostic &= "Failed to create WinHttpRequest. @error=" & @error & @CRLF
		Return SetError(1, 0, "")
	EndIf

	$oHTTP.SetTimeouts(5000, 5000, 15000, 30000)
	$oHTTP.Open("GET", $Url, False)
	If $UserAgent <> "" Then $oHTTP.SetRequestHeader("User-Agent", $UserAgent)
	If $Accept <> "" Then $oHTTP.SetRequestHeader("Accept", $Accept)
	If $Referer <> "" Then $oHTTP.SetRequestHeader("Referer", $Referer)
	$oHTTP.Send()
	If @error Then
		$Diagnostic &= "HTTP send failed. @error=" & @error & ", @extended=" & @extended & @CRLF
		Return SetError(2, 0, "")
	EndIf

	Local $Status = $oHTTP.Status
	Local $ResponseText = $oHTTP.ResponseText
	$Diagnostic &= "HTTP status: " & $Status & @CRLF
	$Diagnostic &= "Response length: " & StringLen($ResponseText) & @CRLF
	If $Status < 200 Or $Status >= 300 Then
		$Diagnostic &= "Response preview: " & StringLeft(StringReplace($ResponseText, @CRLF, "\n"), 500) & @CRLF
		Return SetError(3, $Status, "")
	EndIf

	Return $ResponseText
EndFunc   ;==>HttpGetTextDiagnostic

Func HttpGetText($Url, $UserAgent = "", $Accept = "")
	Local $oError = ObjEvent("AutoIt.Error", "ChromeComError")
	Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
	If @error Or Not IsObj($oHTTP) Then Return SetError(1, 0, "")

	$oHTTP.SetTimeouts(5000, 5000, 15000, 30000)
	$oHTTP.Open("GET", $Url, False)
	If $UserAgent <> "" Then $oHTTP.SetRequestHeader("User-Agent", $UserAgent)
	If $Accept <> "" Then $oHTTP.SetRequestHeader("Accept", $Accept)
	$oHTTP.Send()
	If @error Then Return SetError(2, 0, "")
	If $oHTTP.Status < 200 Or $oHTTP.Status >= 300 Then Return SetError(3, 0, "")

	Return $oHTTP.ResponseText
EndFunc   ;==>HttpGetText

Func SelectChromeDownloadBaseUrl(ByRef $Urls)
	Local $i, $Url
	For $i = 0 To UBound($Urls) - 1
		$Url = DecodeXmlAttribute($Urls[$i])
		If StringInStr($Url, "https://dl.google.com/") = 1 Then Return $Url
	Next
	For $i = 0 To UBound($Urls) - 1
		$Url = DecodeXmlAttribute($Urls[$i])
		If StringLeft($Url, 8) = "https://" Then Return $Url
	Next
	If UBound($Urls) > 0 Then Return DecodeXmlAttribute($Urls[0])
	Return ""
EndFunc   ;==>SelectChromeDownloadBaseUrl

Func DecodeXmlAttribute($Value)
	$Value = StringReplace($Value, "&amp;", "&")
	$Value = StringReplace($Value, "&quot;", '"')
	$Value = StringReplace($Value, "&apos;", "'")
	$Value = StringReplace($Value, "&lt;", "<")
	Return StringReplace($Value, "&gt;", ">")
EndFunc   ;==>DecodeXmlAttribute

Func BuildBrowserDownloadUrl($Value, $Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserHelium Then Return BuildHeliumDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserWhale Then Return BuildWhaleDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserCent Then Return BuildCentDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserVivaldi Then Return BuildVivaldiDownloadUrl($Channel, $os)
	If IsChromeBrowser($Value) Then Return BuildChromeDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserZen Then Return BuildZenDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserFloorp Then Return BuildFloorpDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserWaterfox Then Return BuildWaterfoxDownloadUrl($Channel, $os)
	Return BuildFirefoxDownloadUrl($Channel, $os)
EndFunc   ;==>BuildBrowserDownloadUrl

Func BuildBrowserDownloadUrls($Value, $Channel, $os)
	Local $DownloadUrl = BuildBrowserDownloadUrl($Value, $Channel, $os)
	If @error Or $DownloadUrl = "" Then Return SetError(1, 0, 0)

	If NormalizeBrowserType($Value) = $BrowserZen Or NormalizeBrowserType($Value) = $BrowserFloorp Or NormalizeBrowserType($Value) = $BrowserHelium Then Return _UpgradeBuildGithubReleaseDownloadUrls($DownloadUrl, $GithubDirectMirror, $GithubJsDelivrMirror)

	Local $aUrls[1]
	$aUrls[0] = $DownloadUrl
	Return $aUrls
EndFunc   ;==>BuildBrowserDownloadUrls

Func ShowCurrentChannel()
	If IsChromeBrowser(GetSelectedBrowserType()) Then Return
	Local $path = GUICtrlRead($hFirefoxPath)
	If Not FileExists($path) Then Return
	Local $ChannelPath = StringRegExpReplace($path, "\\?[^\\]+$", "") & "\defaults\pref\channel-prefs.js"
	Local $var = FileRead($ChannelPath)
	Local $match = StringRegExp($var, '(?i)(?m)^\Qpref("app.update.channel",\E *"(.*)\Q");\E', 1)
	If @error Then Return
	$Channel = $match[0]
	If $Channel = "aurora" Then $Channel = "dev"
	_GUICtrlComboBox_SelectString($hChannel, $Channel)
EndFunc   ;==>ShowCurrentChannel

Func DownloadFirefox()
	Local $os = "win64"
	Local $CurrentBrowserType = GetSelectedBrowserType()

	Local $ChannelString = GUICtrlRead($hChannel)
	Local $Channel = StringRegExpReplace($ChannelString, " *-.*", "")

	Local $FirefoxURLs = BuildBrowserDownloadUrls($CurrentBrowserType, $Channel, $os)
	If @error Or Not IsArray($FirefoxURLs) Or UBound($FirefoxURLs) = 0 Then
		_GUICtrlStatusBar_SetText($hStatus, _t("BrowserVersionLoadFailed", "读取浏览器版本失败。"))
		Return
	EndIf
	$FirefoxURL = $FirefoxURLs[0]

	Local $TargetFirefoxPath = FullPath(GUICtrlRead($hFirefoxPath))
	Local $TargetDir, $TargetFile
	SplitPath($TargetFirefoxPath, $TargetDir, $TargetFile)
	If $TargetDir = "" Or $TargetDir = "." Then $TargetDir = @ScriptDir

	If BrowserExecutableExistsInDir($TargetDir, $CurrentBrowserType) Or IsDirectoryNotEmpty($TargetDir) Then
		Local $ConfirmOverwrite = _t("ConfirmOverwriteBrowserFiles", "目标目录已有浏览器文件或其他文件：\n%s\n\n是否继续下载并覆盖/合并文件？", $TargetDir)
		If MsgBox(36 + 256, $CustomArch, $ConfirmOverwrite, 0, $hSettings) <> 6 Then Return
	EndIf

	Local $DownloadedFirefoxPath = DownloadAndExtractFirefox($FirefoxURLs, $TargetDir, $os, $Channel, $CurrentBrowserType)
	If @error Then
		Local $ErrorMessage = _t("BrowserDownloadFailed", "浏览器下载或解压失败：\n%s\n\n请检查网络和目标目录权限后重试。", $DownloadedFirefoxPath)
		MsgBox(16, $CustomArch, $ErrorMessage, 0, $hSettings)
		Return
	EndIf

	$FirefoxPath = RelativePath($DownloadedFirefoxPath)
	GUICtrlSetData($hFirefoxPath, $FirefoxPath)
	OnFirefoxPathChange()
	If IsChromePlusSupportedBrowser($CurrentBrowserType) Then MaybeInstallChromePlusPatch($DownloadedFirefoxPath, $os, True)
	UpdateBrowserSpecificControls()
	_GUICtrlStatusBar_SetText($hStatus, _t("BrowserDownloadSuccess", "浏览器已下载并解压完成。"))
	Local $OpenDownloadedBrowserConfirm = _t("OpenDownloadedBrowserConfirm", "浏览器已下载并解压完成。\n是否马上打开浏览器？")
	If MsgBox(36 + 256, $CustomArch, $OpenDownloadedBrowserConfirm, 0, $hSettings) = 6 Then SettingsOK()
EndFunc   ;==>DownloadFirefox

Func DownloadAndExtractFirefox($aDownloadUrls, $TargetDir, $os, $Channel, $CurrentBrowserType)
	Local $TempDir = @TempDir & "\RunFirefox_FirefoxDownload"
	If Not IsArray($aDownloadUrls) Or UBound($aDownloadUrls) = 0 Then Return SetError(1, 0, _t("CannotStartBrowserDownload", "无法开始下载浏览器。"))
	Local $DownloadUrl
	$DownloadUrl = $aDownloadUrls[0]
	Local $InstallerExt = GetUrlFileExtension($DownloadUrl)
	Local $Installer = $TempDir & "\BrowserSetup_" & NormalizeBrowserType($CurrentBrowserType) & "_" & $Channel & "_" & $os & $InstallerExt
	Local $ExtractDir = $TempDir & "\extract"
	Local $TargetFirefoxPath = $TargetDir & "\" & GetBrowserExecutableName($CurrentBrowserType)
	Local $hDownload, $DownloadedBytes, $TotalBytes, $Percent, $DetailText, $ret, $ExtractLog, $SevenZipExe, $i
	Local $CopiedBrowserFiles = False, $DownloadSuccessful = False, $TriedDownloadUrls = ""

	DirRemove($TempDir, 1)
	If Not FileExists($TempDir) Then DirCreate($TempDir)
	If Not FileExists($TempDir) Then Return SetError(1, 0, _t("CannotCreateTempDirectory", "无法创建临时目录。"))
	If Not FileExists($TargetDir) Then DirCreate($TargetDir)
	If Not FileExists($TargetDir) Then Return SetError(2, 0, _t("CannotCreateBrowserDirectory", "无法创建浏览器目标目录。"))

	ShowDownloadProgress(_t("BrowserDownloadProgressTitle", "正在准备浏览器"), _t("DownloadingBrowser", "正在下载浏览器 ..."), $DownloadUrl)

	For $i = 0 To UBound($aDownloadUrls) - 1
		$DownloadUrl = $aDownloadUrls[$i]
		If $TriedDownloadUrls <> "" Then $TriedDownloadUrls &= @CRLF
		$TriedDownloadUrls &= $DownloadUrl
		FileDelete($Installer)
		UpdateDownloadProgress(_t("DownloadingBrowser", "正在下载浏览器 ..."), $DownloadUrl, 0)
		$hDownload = InetGet($DownloadUrl, $Installer, 19, 1)
		If @error Or $hDownload = 0 Then ContinueLoop

		Do
			$DownloadedBytes = InetGetInfo($hDownload, 0)
			$TotalBytes = InetGetInfo($hDownload, 1)
			If $TotalBytes > 0 Then
				$Percent = Int($DownloadedBytes * 100 / $TotalBytes)
				If $Percent > 100 Then $Percent = 100
				$DetailText = _t("FirefoxDownloadProgressKnown", "已下载 {Downloaded} / {Total}")
				$DetailText = StringReplace($DetailText, "{Downloaded}", FormatBytes($DownloadedBytes))
				$DetailText = StringReplace($DetailText, "{Total}", FormatBytes($TotalBytes))
			Else
				$Percent = Mod(Int($DownloadedBytes / 65536), 100)
				$DetailText = _t("FirefoxDownloadProgressUnknown", "已下载 %s", FormatBytes($DownloadedBytes))
			EndIf
			UpdateDownloadProgress(_t("DownloadingBrowser", "正在下载浏览器 ..."), $DetailText, $Percent)
			PumpDownloadProgressEvents()
			If IsDownloadProgressCancelled() Then ExitLoop
			Sleep(200)
		Until InetGetInfo($hDownload, 2)

		$DownloadSuccessful = InetGetInfo($hDownload, 3)
		InetClose($hDownload)
		If IsDownloadProgressCancelled() Then ExitLoop
		If $DownloadSuccessful And FileExists($Installer) Then ExitLoop
	Next

	If IsDownloadProgressCancelled() Then
		CloseDownloadProgress()
		FileDelete($Installer)
		DirRemove($TempDir, 1)
		Return SetError(4, 0, _t("BrowserDownloadCancelled", "已取消浏览器下载。"))
	EndIf
	If Not $DownloadSuccessful Or Not FileExists($Installer) Then
		CloseDownloadProgress()
		DirRemove($TempDir, 1)
		Return SetError(5, 0, BuildBrowserDownloadFailureDetail(_t("FailToDownloadBrowserInstaller", "下载浏览器安装包失败。"), $TriedDownloadUrls, $Installer))
	EndIf

	SetDownloadProgressBusy(_t("ExtractingBrowser", "正在解压浏览器，请稍候 ..."), _t("ExtractingBrowserDetail", "解压期间请不要关闭 {AppName}。"))
	$ExtractLog = $TempDir & "\extract.log"
	$SevenZipExe = PrepareSevenZipTool($TempDir)
	If @error Then
		CloseDownloadProgress()
		Return SetError(6, 0, _t("FailToExtractBrowserInstaller", "解压浏览器安装包失败。") & @CRLF & @CRLF & _t("FirefoxExtractLogKept", "诊断文件已保留在：\n%s", $TempDir))
	EndIf
	If Not FileExists($ExtractDir) Then DirCreate($ExtractDir)
	$ret = RunWait(@ComSpec & ' /c ""' & $SevenZipExe & '" x -y -bd -bb1 -o"' & $ExtractDir & '" "' & $Installer & '" > "' & $ExtractLog & '" 2>&1"', $TempDir, @SW_HIDE)
	CloseDownloadProgress()

	ExtractNestedBrowserArchives($SevenZipExe, $ExtractDir, $TempDir)
	Local $ExtractedFirefoxPath = FindBrowserExecutableForType($ExtractDir, $CurrentBrowserType)
	If $ExtractedFirefoxPath Then
		Local $ExtractedFirefoxDir, $ExtractedFirefoxFile
		SplitPath($ExtractedFirefoxPath, $ExtractedFirefoxDir, $ExtractedFirefoxFile)
		$CopiedBrowserFiles = DirCopy($ExtractedFirefoxDir, $TargetDir, 1)
		$TargetFirefoxPath = $TargetDir & "\" & $ExtractedFirefoxFile
	EndIf

	If Not $CopiedBrowserFiles Or Not FileExists($TargetFirefoxPath) Then
		Return SetError(6, 0, _t("FailToExtractBrowserInstaller", "解压浏览器安装包失败。") & @CRLF & @CRLF & _t("FirefoxExtractLogKept", "诊断文件已保留在：\n%s", $TempDir))
	EndIf

	FileDelete($Installer)
	DirRemove($TempDir, 1)
	Return $TargetFirefoxPath
EndFunc   ;==>DownloadAndExtractFirefox

Func BuildBrowserDownloadFailureDetail($BaseMessage, $TriedDownloadUrls, $Installer)
	Local $Detail = $BaseMessage
	If $TriedDownloadUrls <> "" Then
		$Detail &= @CRLF & @CRLF & _t("TriedDownloadUrls", "尝试下载地址：") & @CRLF & $TriedDownloadUrls
	EndIf
	If $Installer <> "" Then
		$Detail &= @CRLF & @CRLF & _t("BrowserInstallerSavePath", "安装包保存路径：") & @CRLF & $Installer
	EndIf
	Return $Detail
EndFunc   ;==>BuildBrowserDownloadFailureDetail

Func ShowDownloadProgress($TitleText, $StatusText, $DetailText)
	If $hDownloadProgress Then CloseDownloadProgress()
	$DownloadProgressPreviousGuiMode = Opt("GUIOnEventMode", 0)
	$DownloadProgressCancelled = 0
	$DownloadProgressCanCancel = 1
	$hDownloadProgress = GUICreate($TitleText, 420, 135, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), -1, $hSettings)
	GUISetOnEvent($GUI_EVENT_CLOSE, "CancelDownloadProgress")
	$hDownloadProgressStatus = GUICtrlCreateLabel($StatusText, 15, 15, 390, 20)
	$hDownloadProgressDetail = GUICtrlCreateLabel($DetailText, 15, 42, 390, 36)
	$hDownloadProgressBar = GUICtrlCreateProgress(15, 82, 390, 18)
	$hDownloadProgressCancel = GUICtrlCreateButton(_t("Cancel", "取消"), 170, 108, 80, 22)
	GUICtrlSetOnEvent(-1, "CancelDownloadProgress")
	GUISetState(@SW_SHOW, $hDownloadProgress)
	WinSetOnTop($hDownloadProgress, "", 1)
EndFunc   ;==>ShowDownloadProgress

Func UpdateDownloadProgress($StatusText, $DetailText, $Percent)
	If Not $hDownloadProgress Then Return
	GUICtrlSetData($hDownloadProgressStatus, $StatusText)
	GUICtrlSetData($hDownloadProgressDetail, $DetailText)
	GUICtrlSetData($hDownloadProgressBar, $Percent)
EndFunc   ;==>UpdateDownloadProgress

Func SetDownloadProgressBusy($StatusText, $DetailText)
	If Not $hDownloadProgress Then Return
	$DownloadProgressCanCancel = 0
	GUICtrlSetState($hDownloadProgressCancel, $GUI_DISABLE)
	UpdateDownloadProgress($StatusText, $DetailText, 100)
EndFunc   ;==>SetDownloadProgressBusy

Func CloseDownloadProgress()
	If Not $hDownloadProgress Then Return
	GUIDelete($hDownloadProgress)
	$hDownloadProgress = 0
	$DownloadProgressCanCancel = 0
	If $DownloadProgressPreviousGuiMode <> -1 Then
		Opt("GUIOnEventMode", $DownloadProgressPreviousGuiMode)
		$DownloadProgressPreviousGuiMode = -1
	EndIf
EndFunc   ;==>CloseDownloadProgress

Func CancelDownloadProgress()
	If $DownloadProgressCanCancel Then $DownloadProgressCancelled = 1
EndFunc   ;==>CancelDownloadProgress

Func IsDownloadProgressCancelled()
	Return $DownloadProgressCancelled
EndFunc   ;==>IsDownloadProgressCancelled

Func PumpDownloadProgressEvents()
	If Not $hDownloadProgress Or Not $DownloadProgressCanCancel Then Return

	Local $aMsg
	Do
		$aMsg = GUIGetMsg(1)
		If Not IsArray($aMsg) Then Return
		If $aMsg[0] = 0 Then Return
		If $aMsg[1] = $hDownloadProgress And ($aMsg[0] = $hDownloadProgressCancel Or $aMsg[0] = $GUI_EVENT_CLOSE) Then
			$DownloadProgressCancelled = 1
			Return
		EndIf
	Until False
EndFunc   ;==>PumpDownloadProgressEvents

Func FormatBytes($Bytes)
	If $Bytes >= 1048576 Then Return Round($Bytes / 1048576, 1) & " MB"
	Return Round($Bytes / 1024) & " KB"
EndFunc   ;==>FormatBytes

Func GetUrlFileExtension($Url)
	Local $Path = StringRegExpReplace($Url, "[?#].*$", "")
	If StringRegExp($Path, "(?i)\.msi$") Then Return ".msi"
	If StringRegExp($Path, "(?i)\.zip$") Then Return ".zip"
	If StringRegExp($Path, "(?i)\.7z$") Then Return ".7z"
	Return ".exe"
EndFunc   ;==>GetUrlFileExtension

Func PrepareSevenZipTool($TempDir)
	Local $ToolDir = $TempDir & "\7z"
	If Not FileExists($ToolDir) Then DirCreate($ToolDir)
	If @Compiled Then
		FileInstall("libs\7z\7z.exe", $ToolDir & "\7z.exe", 1)
		FileInstall("libs\7z\7z.dll", $ToolDir & "\7z.dll", 1)
	Else
		FileCopy(@ScriptDir & "\libs\7z\7z.exe", $ToolDir & "\7z.exe", 9)
		FileCopy(@ScriptDir & "\libs\7z\7z.dll", $ToolDir & "\7z.dll", 9)
	EndIf
	If Not FileExists($ToolDir & "\7z.exe") Or Not FileExists($ToolDir & "\7z.dll") Then Return SetError(1, 0, "")
	Return $ToolDir & "\7z.exe"
EndFunc   ;==>PrepareSevenZipTool

Func IsDirectoryNotEmpty($Dir)
	If Not FileExists($Dir) Then Return False
	Local $hSearch = FileFindFirstFile($Dir & "\*")
	If $hSearch = -1 Then Return False
	FileClose($hSearch)
	Return True
EndFunc   ;==>IsDirectoryNotEmpty

Func BrowserExecutableExistsInDir($Dir, $BrowserTypeValue)
	Local $Candidates = StringSplit(GetBrowserExecutableCandidates($BrowserTypeValue), "|", 2)
	For $i = 0 To UBound($Candidates) - 1
		If FileExists($Dir & "\" & $Candidates[$i]) Then Return True
	Next
	Return False
EndFunc   ;==>BrowserExecutableExistsInDir

Func ExtractNestedBrowserArchives($SevenZipExe, $RootDir, $TempDir, $Depth = 2)
	If $Depth <= 0 Then Return

	Local $ArchiveList = FindNestedBrowserArchives($RootDir)
	If Not IsArray($ArchiveList) Then Return

	Local $i, $Archive, $OutDir, $LogFile
	For $i = 1 To $ArchiveList[0]
		$Archive = $ArchiveList[$i]
		$OutDir = $RootDir & "\__nested_" & $Depth & "_" & $i
		$LogFile = $TempDir & "\nested_extract.log"
		If Not FileExists($OutDir) Then DirCreate($OutDir)
		RunWait(@ComSpec & ' /c ""' & $SevenZipExe & '" x -y -bd -bb1 -o"' & $OutDir & '" "' & $Archive & '" >> "' & $LogFile & '" 2>&1"', $TempDir, @SW_HIDE)
		ExtractNestedBrowserArchives($SevenZipExe, $OutDir, $TempDir, $Depth - 1)
	Next
EndFunc   ;==>ExtractNestedBrowserArchives

Func FindNestedBrowserArchives($Dir, $Depth = 4)
	If $Depth <= 0 Then Return 0

	Local $Archives[1] = [0]
	CollectNestedBrowserArchives($Dir, $Depth, $Archives)
	If $Archives[0] = 0 Then Return 0
	Return $Archives
EndFunc   ;==>FindNestedBrowserArchives

Func CollectNestedBrowserArchives($Dir, $Depth, ByRef $Archives)
	If $Depth <= 0 Then Return

	Local $hSearch = FileFindFirstFile($Dir & "\*")
	If $hSearch = -1 Then Return

	Local $Name, $Path, $Attrib
	While 1
		$Name = FileFindNextFile($hSearch)
		If @error Then ExitLoop
		$Path = $Dir & "\" & $Name
		$Attrib = FileGetAttrib($Path)
		If StringInStr($Attrib, "D") Then
			CollectNestedBrowserArchives($Path, $Depth - 1, $Archives)
		ElseIf StringRegExp($Name, "(?i)\.(7z|zip)$") Then
			$Archives[0] += 1
			ReDim $Archives[$Archives[0] + 1]
			$Archives[$Archives[0]] = $Path
		EndIf
	WEnd

	FileClose($hSearch)
EndFunc   ;==>CollectNestedBrowserArchives

Func FindBrowserExecutable($Dir, $ExecutableName, $Depth = 6)
	If FileExists($Dir & "\" & $ExecutableName) Then Return $Dir & "\" & $ExecutableName
	If $Depth <= 0 Then Return ""

	Local $hSearch = FileFindFirstFile($Dir & "\*")
	If $hSearch = -1 Then Return ""

	Local $Name, $Path, $Found
	While 1
		$Name = FileFindNextFile($hSearch)
		If @error Then ExitLoop
		$Path = $Dir & "\" & $Name
		If StringInStr(FileGetAttrib($Path), "D") Then
			$Found = FindBrowserExecutable($Path, $ExecutableName, $Depth - 1)
			If $Found Then
				FileClose($hSearch)
				Return $Found
			EndIf
		EndIf
	WEnd

	FileClose($hSearch)
	Return ""
EndFunc   ;==>FindBrowserExecutable

Func FindCentBrowserExecutable($Dir)
	Local $Found = FindCentBrowserExecutableWithMarker($Dir)
	If $Found Then Return $Found
	Return FindBrowserExecutable($Dir, "chrome.exe")
EndFunc   ;==>FindCentBrowserExecutable

Func FindCentBrowserExecutableWithMarker($Dir, $Depth = 6)
	If FileExists($Dir & "\chrome.exe") And IsCentBrowserExtractDir($Dir) Then Return $Dir & "\chrome.exe"
	If $Depth <= 0 Then Return ""

	Local $hSearch = FileFindFirstFile($Dir & "\*")
	If $hSearch = -1 Then Return ""

	Local $Name, $Path, $Found
	While 1
		$Name = FileFindNextFile($hSearch)
		If @error Then ExitLoop
		$Path = $Dir & "\" & $Name
		If StringInStr(FileGetAttrib($Path), "D") Then
			$Found = FindCentBrowserExecutableWithMarker($Path, $Depth - 1)
			If $Found Then
				FileClose($hSearch)
				Return $Found
			EndIf
		EndIf
	WEnd

	FileClose($hSearch)
	Return ""
EndFunc   ;==>FindCentBrowserExecutableWithMarker

Func IsCentBrowserExtractDir($Dir)
	If FileExists($Dir & "\safemode.bat") Then Return True

	Local $Identity = GetExecutableIdentityText($Dir & "\chrome.exe")
	If StringInStr($Identity, "cent browser") Or StringInStr($Identity, "centbrowser") Then Return True
	Return False
EndFunc   ;==>IsCentBrowserExtractDir

Func FindBrowserExecutableForType($Dir, $BrowserTypeValue)
	If NormalizeBrowserType($BrowserTypeValue) = $BrowserCent Then Return FindCentBrowserExecutable($Dir)

	Local $Candidates = StringSplit(GetBrowserExecutableCandidates($BrowserTypeValue), "|", 2)
	Local $Found
	For $i = 0 To UBound($Candidates) - 1
		$Found = FindBrowserExecutable($Dir, $Candidates[$i])
		If $Found Then Return $Found
	Next
	Return ""
EndFunc   ;==>FindBrowserExecutableForType

Func ImportChromiumGoogleApi()
	If Not HasChromiumGoogleApi() Then
		MsgBox(48, "RunFirefox", _t("GoogleApiUnavailable", "当前构建未内置 Google API 密钥。请在 GitHub Actions secrets 中配置后重新构建。"), 0, $hSettings)
		Return
	EndIf
	If SetChromiumGoogleApiEnvironment($ChromiumGoogleApiKey, $ChromiumGoogleClientId, $ChromiumGoogleClientSecret) Then
		MsgBox(0, "RunFirefox", _t("GoogleApiImportSuccess", "导入GoogleAPI密钥成功"), 0, $hSettings)
	Else
		MsgBox(16, "RunFirefox", _t("GoogleApiEnvironmentUpdateFailed", "修改GoogleAPI环境变量失败。"), 0, $hSettings)
	EndIf
EndFunc   ;==>ImportChromiumGoogleApi

Func HasChromiumGoogleApi()
	Return $ChromiumGoogleApiKey <> "" And $ChromiumGoogleClientId <> "" And $ChromiumGoogleClientSecret <> ""
EndFunc   ;==>HasChromiumGoogleApi

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

Func RunInBackground()
	If GUICtrlRead($hRunInBackground) = $GUI_CHECKED Then
		Return
	EndIf
	Local $msg = MsgBox(36 + 256, "RunFirefox", _t("RunInBackgroundMessage", '允许 RunFirefox 在后台运行可以带来更好的用户体验。若取消此选项，请注意以下几点：\n\n 1. 将浏览器锁定到任务栏或设为默认浏览器后，需再运行一次 RunFirefox 才能生效；\n2. RunFirefox 设置界面中带“#”符号的功能/选项将不会执行，包括浏览器退出后关闭外部程序、运行外部程序等。\n\n确定要取消此选项吗？'), 0, $hSettings)
	If $msg <> 6 Then
		GUICtrlSetState($hRunInBackground, $GUI_CHECKED)
	EndIf
EndFunc   ;==>RunInBackground

;~ 设置界面取消
Func ExitApp()
	Exit
EndFunc   ;==>ExitApp

;~ 设置界面确定按钮
Func SettingsOK()
	SettingsApply()
	If @error Then Return
	$SettingsOK = 1
EndFunc   ;==>SettingsOK



;~ 设置界面应用按钮
Func SettingsApply()
	Local $msg, $var
	FileChangeDir(@ScriptDir)

	Opt("ExpandEnvStrings", 0)
	$FirefoxPath = RelativePath(GUICtrlRead($hFirefoxPath))
	ApplyDetectedBrowserTypeFromPath()
	$BrowserType = GetSelectedBrowserType()

	If GUICtrlRead($hAllowBrowserUpdate) = $GUI_CHECKED Then
		$AllowBrowserUpdate = 1
	Else
		$AllowBrowserUpdate = 0
	EndIf
	If IsChromeBrowser($BrowserType) Then $AllowBrowserUpdate = 0
	$ProfileDir = RelativePath(GUICtrlRead($hProfileDir))
	$CustomPluginsDir = RelativePath(GUICtrlRead($hCustomPluginsDir))
	$CustomCacheDir = RelativePath(GUICtrlRead($hCustomCacheDir))
	$CacheSize = GUICtrlRead($hCacheSize)
	If GUICtrlRead($hCacheSizeSmart) = $GUI_CHECKED Then
		$CacheSizeSmart = 1
	Else
		$CacheSizeSmart = 0
	EndIf
	If IsChromeBrowser($BrowserType) Then $CacheSizeSmart = 0
	$var = GUICtrlRead($hParams)
	$var = StringStripWS($var, 3)
	$Params = StringReplace($var, @CRLF, " ") ; 换行符换成空格
	If GUICtrlRead($hCheckAppUpdate) = $GUI_CHECKED Then
		$CheckAppUpdate = 1
	Else
		$CheckAppUpdate = 0
	EndIf
	$BrowserUpdateCheckMode = GetSelectedBrowserUpdateCheckMode()
	If GUICtrlRead($hRunInBackground) = $GUI_CHECKED Then
		$RunInBackground = 1
	Else
		$RunInBackground = 0
	EndIf
	If GUICtrlRead($hBossKeyEnabled) = $GUI_CHECKED Then
		$BossKeyEnabled = 1
	Else
		$BossKeyEnabled = 0
	EndIf
	$BossKey = $BossKeyCaptureValue
	If GUICtrlRead($hBossKeyHideToTray) = $GUI_CHECKED Then
		$BossKeyHideToTray = 1
	Else
		$BossKeyHideToTray = 0
	EndIf
	Local $var = GUICtrlRead($hExApp)
	$var = StringStripWS($var, 3)
	$var = StringReplace($var, @CRLF, "||")
	$var = StringRegExpReplace($var, "\|+\s*\|+", "\|\|")
	$ExApp = $var
	If GUICtrlRead($hExAppAutoExit) = $GUI_CHECKED Then
		$ExAppAutoExit = 1
	Else
		$ExAppAutoExit = 0
	EndIf
	$var = GUICtrlRead($hExApp2)
	$var = StringStripWS($var, 3)
	$var = StringReplace($var, @CRLF, "||")
	$var = StringRegExpReplace($var, "\|+\s*\|+", "\|\|")
	$ExApp2 = $var

	IniWrite($inifile, "Settings", "CheckAppUpdate", $CheckAppUpdate)
	IniWrite($inifile, "Settings", "RunInBackground", $RunInBackground)
	IniWrite($inifile, "Settings", "AllowBrowserUpdate", $AllowBrowserUpdate)
	IniWrite($inifile, "Settings", "BrowserUpdateCheckMode", $BrowserUpdateCheckMode)
	IniWrite($inifile, "Settings", "BrowserUpdateLastCheck", $BrowserUpdateLastCheck)
	IniWrite($inifile, "Settings", "BrowserType", $BrowserType)
	IniWrite($inifile, "Settings", "FirefoxPath", $FirefoxPath)
	IniWrite($inifile, "Settings", "ProfileDir", $ProfileDir)
	IniWrite($inifile, "Settings", "CustomPluginsDir", $CustomPluginsDir)
	IniWrite($inifile, "Settings", "CustomCacheDir", $CustomCacheDir)
	IniWrite($inifile, "Settings", "CacheSize", $CacheSize)
	IniWrite($inifile, "Settings", "CacheSizeSmart", $CacheSizeSmart)
	IniWrite($inifile, "Settings", "Params", $Params)
	IniWrite($inifile, "Settings", "BossKeyEnabled", $BossKeyEnabled)
	IniWrite($inifile, "Settings", "BossKey", $BossKey)
	IniWrite($inifile, "Settings", "BossKeyHideToTray", $BossKeyHideToTray)
	$var = $ExApp
	If StringRegExp($var, '^".*"$') Then $var = '"' & $var & '"'
	IniWrite($inifile, "Settings", "ExApp", $var)
	IniWrite($inifile, "Settings", "ExAppAutoExit", $ExAppAutoExit)
	$var = $ExApp2
	If StringRegExp($var, '^".*"$') Then $var = '"' & $var & '"'
	IniWrite($inifile, "Settings", "ExApp2", $var)

	Opt("ExpandEnvStrings", 1)

	;Firefox path
	If Not FileExists($FirefoxPath) Then
		MsgBox(16, "RunFirefox", _t("FirefoxPathErrorMessage", "Firefox 路径错误，请重新设置。\n\n%s", $FirefoxPath), 0, $hSettings)
		GUICtrlSetState($hFirefoxPath, $GUI_FOCUS)
		Return SetError(1)
	EndIf

	If IsMozillaBrowser($BrowserType) Then
		Local $ChannelString = GUICtrlRead($hChannel)
		Local $Channel = StringRegExpReplace($ChannelString, " -.*", "")
		Local $UpdateChannel = $Channel
		If $BrowserType = $BrowserZen Then
			$UpdateChannel = GetZenUpdateChannel($Channel)
		ElseIf $UpdateChannel = "dev" Then
			; Firefox Developer Edition still uses aurora as the internal update channel.
			$UpdateChannel = "aurora"
		EndIf
		Local $ChannelPath = StringRegExpReplace($FirefoxPath, "\\?[^\\]+$", "") & "\defaults\pref\channel-prefs.js"
		Local $var = FileRead($ChannelPath)
		Local $ChannelPrefs = '// Changed by RunFirefox' & @CRLF & 'pref("app.update.channel", "' & $UpdateChannel & '");' & @CRLF
		If $BrowserType = $BrowserZen Then
			$ChannelPrefs &= 'pref("app.update.url", "https://updates.zen-browser.app/updates/browser/%OS_VERSION%/%CHANNEL%/update.xml");' & @CRLF
		EndIf
		If Not StringInStr($var, 'pref("app.update.channel", "' & $UpdateChannel & '");') Or ($BrowserType = $BrowserZen And Not StringInStr($var, 'https://updates.zen-browser.app/updates/browser/')) Or ($BrowserType <> $BrowserZen And StringInStr($var, 'https://updates.zen-browser.app/updates/browser/')) Then
			FileDelete($ChannelPath)
			FileWrite($ChannelPath, $ChannelPrefs)
		EndIf
	EndIf

	;profiles dir
	If $ProfileDir = "" Then
		MsgBox(16, "RunFirefox", _t("PleaseProfileFolder", "请设置配置文件夹！"), 0, $hSettings)
		GUICtrlSetState($hProfileDir, $GUI_FOCUS)
		Return SetError(2)
	ElseIf Not FileExists($ProfileDir) Then
		DirCreate($ProfileDir)
	EndIf

	; 提取系统浏览器配置文件
	If GUICtrlRead($hCopyProfile) = $GUI_CHECKED Then
		$DefaultProfDir = GetSystemProfileSourceDir($BrowserType, GUICtrlRead($hChannel))
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
		GUICtrlSetState($hCopyProfile, $GUI_UNCHECKED)
	EndIf

	; plugins dir
	If IsMozillaBrowser($BrowserType) And $CustomPluginsDir <> "" And Not FileExists($CustomPluginsDir) Then
		DirCreate($CustomPluginsDir)
	EndIf

	If Not SaveChromePlusTabsSettings($FirefoxPath) Then
		MsgBox(16, "RunFirefox", _t("ChromePlusTabsSaveFailed", "保存 Chrome++ 标签页设置失败：\n%s", GetChromePlusConfigPath($FirefoxPath)), 0, $hSettings)
		Return SetError(3)
	EndIf
EndFunc   ;==>SettingsApply

;~ 打开网站
Func Website()
	ShellExecute("https://github.com/benzBrake/RunFirefox")
EndFunc   ;==>Website

;~ 打开原版网站
Func OriginalWebsite()
	ShellExecute("https://github.com/cnjackchen/my-firefox")
EndFunc   ;==>Website

;~ 查找Firefox主程序
Func GetFirefoxPath()
	Local $ExecutableName = GetBrowserExecutableName(GetSelectedBrowserType())
	Local $path = FileOpenDialog(_t("ChooseBrowserExecutable", "选择浏览器主程序（%s）", $ExecutableName), @ScriptDir, _t("ExecutableFile", "可执行文件(*.exe)"), 1 + 2, $ExecutableName, $hSettings)
	FileChangeDir(@ScriptDir) ; FileOpenDialog 会改变 @workingdir，将它改回来
	If $path = "" Then Return
	$FirefoxPath = RelativePath($path)
	GUICtrlSetData($hFirefoxPath, $FirefoxPath)
	OnFirefoxPathChange()
EndFunc   ;==>GetFirefoxPath

;~ 指定配置文件夹
Func GetProfileDir()
	Local $dir = FileSelectFolder(_t("SpecifyProfileDirectory", "指定 Firefox 配置文件夹"), "", 1 + 4, @ScriptDir, $hSettings)
	FileChangeDir(@ScriptDir)
	If $dir = "" Then Return
	$ProfileDir = RelativePath($dir)
	GUICtrlSetData($hProfileDir, $ProfileDir)
EndFunc   ;==>GetProfileDir

;~ 指定插件目录
Func GetPluginsDir()
	Local $dir = FileSelectFolder(_t("SpecifyPluginsDirectory", "指定 Firefox 插件目录"), "", 1 + 4, @ScriptDir, $hSettings)
	FileChangeDir(@ScriptDir)
	If $dir = "" Then Return
	$CustomPluginsDir = RelativePath($dir)
	GUICtrlSetData($hCustomPluginsDir, $CustomPluginsDir)
EndFunc   ;==>GetPluginsDir

;~ 指定缓存位置
Func GetCacheDir()
	Local $dir = FileSelectFolder(_t("SpecifyCacheDirectory", "指定 Firefox 缓存文件夹"), "", 1 + 4, @ScriptDir, $hSettings)
	FileChangeDir(@ScriptDir)
	If $dir = "" Then Return
	$CustomCacheDir = RelativePath($dir)
	GUICtrlSetData($hCustomCacheDir, $CustomCacheDir)
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
; Name...........: GetProcPath
; Description ...: 取得进程路径
; Syntax.........: GetProcPath($Process_PID)
; Parameters ....: $Process_PID - 进程的 pid
; Return values .: Success - 完整路径
;                  Failure - set @error
;============================================================================================
Func GetProcPath($pid = @AutoItPID)
	If @OSArch <> "X86" And Not @AutoItX64 And Not _WinAPI_IsWow64Process($pid) Then ; much slow than dllcall method
		Local $colItems = ""
		Local $objWMIService = ObjGet("winmgmts:\\localhost\root\CIMV2")
		$colItems = $objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE ProcessId = " & $pid, "WQL", _
				0x10 + 0x20)
		If IsObj($colItems) Then
			For $objItem In $colItems
				If $objItem.ExecutablePath Then Return $objItem.ExecutablePath
			Next
		EndIf
		Return ""
	Else
		Local $hProcess = DllCall('kernel32.dll', 'ptr', 'OpenProcess', 'dword', BitOR(0x0400, 0x0010), 'int', 0, 'dword', $pid)
		If (@error) Or (Not $hProcess[0]) Then Return SetError(1, 0, '')
		Local $ret = DllCall(@SystemDir & '\psapi.dll', 'int', 'GetModuleFileNameExW', 'ptr', $hProcess[0], 'ptr', 0, 'wstr', '', 'int', 1024)
		If (@error) Or (Not $ret[0]) Then Return SetError(1, 0, '')
		Return $ret[3]
	EndIf
EndFunc   ;==>GetProcPath

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

; 语言检测
Func GetLangFile()
	Local $filePath = @ScriptDir & "\" & "Lang.ini"
	Local $fileCustomPath = @ScriptDir & "\" & "LangCustom.ini"
	FileInstall("Lang.ini", $filePath, 1)
	If FileExists($fileCustomPath) Then
		$filePath = $fileCustomPath
	EndIf
	Return $filePath
EndFunc   ;==>GetLangFile

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
	$str = StringReplace($str, "{AppName}", $CustomArch)
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
		MsgBox(64, $CustomArch, _t("RestartToApplyLanguage", "语言设置将在重启 {AppName} 后生效"))
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
	local $slang = GUICtrlRead($hlanguage), $index = -1, $keys = $LANGUAGES.Keys, $newLang = ""
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
