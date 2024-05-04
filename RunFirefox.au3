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
#AutoIt3Wrapper_Res_Fileversion=2.7.9.0
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
#include <FileConstants.au3>
#include <Array.au3>
#include "libs\_String.au3"
#include "libs\AppUserModelId.au3"
#include "libs\Polices.au3"
#include "libs\ScriptingDictionary.au3"
#include "libs\UpgradeHelper.au3"

Opt("GUIOnEventMode", 1)
Opt("WinTitleMatchMode", 4)

Global Const $CustomArch = "RunFirefox"
Global Const $AppVersion = "2.7.9"
Global $FirstRun, $FirefoxExe, $FirefoxDir
Global $TaskBarDir = @AppDataDir & "\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
Global $AppPID, $TaskBarLastChange
Global $AllowBrowserUpdate, $CheckAppUpdate, $AppUpdateLastCheck, $RunInBackground, $FirefoxPath, $ProfileDir
Global $CustomPluginsDir, $CustomCacheDir, $CacheSize, $CacheSizeSmart, $CheckDefaultBrowser, $Params
Global $ExApp, $ExAppAutoExit, $ExApp2

Global $DefaultProfDir, $hSettings, $hFirefoxPath, $hProfileDir, $hlanguage
Global $hCopyProfile, $hCustomPluginsDir, $hGetPluginsDir
Global $hCustomCacheDir, $hGetCacheDir, $hCacheSize, $hCacheSizeSmart
Global $hParams, $hStatus, $SettingsOK
Global $hAllowBrowserUpdate, $hCheckAppUpdate, $hRunInBackground, $hChannel, $hDownloadFirefox32, $hDownloadFirefox64, $FirefoxURL
Global $hExApp, $hExAppAutoExit, $hExApp2
Global $aExApp, $aExApp2, $aExAppPID[2]

Global $hEvent, $ClientKey, $FileAsso, $URLAsso
Global $aREG[7][3] = [[$HKEY_CURRENT_USER, 'Software\Clients\StartMenuInternet'], _
		[$HKEY_LOCAL_MACHINE, 'Software\Clients\StartMenuInternet'], _
		[$HKEY_CLASSES_ROOT, 'ftp'], _
		[$HKEY_CLASSES_ROOT, 'http'], _
		[$HKEY_CLASSES_ROOT, 'https'], _
		[$HKEY_CLASSES_ROOT, ''], _ ; FirefoxHTML
		[$HKEY_CLASSES_ROOT, '']] ; FirefoxURL

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
	IniWrite($inifile, "Settings", "AppVersion", $AppVersion)
	IniWrite($inifile, "Settings", "CheckAppUpdate", 1)
	IniWrite($inifile, "Settings", "AppUpdateLastCheck", "2015/01/01 00:00:00")
	IniWrite($inifile, "Settings", "RunInBackground", 1)
	IniWrite($inifile, "Settings", "AllowBrowserUpdate", 1)
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
	IniWrite($inifile, "Settings", "LastPlatformDir", "")
	IniWrite($inifile, "Settings", "LastProfileDir", "")
	IniWrite($inifile, "Settings", "GithubMirror", "https://github.mfzy.ru")
EndIf

$CheckAppUpdate = IniRead($inifile, "Settings", "CheckAppUpdate", 1) * 1
$AppUpdateLastCheck = IniRead($inifile, "Settings", "AppUpdateLastCheck", "")
If Not $AppUpdateLastCheck Then
	$AppUpdateLastCheck = "2015/01/01 00:00:00"
EndIf
$AllowBrowserUpdate = IniRead($inifile, "Settings", "AllowBrowserUpdate", 1) * 1
$RunInBackground = IniRead($inifile, "Settings", "RunInBackground", 1) * 1
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
$LastPlatformDir = IniRead($inifile, "Settings", "LastPlatformDir", 1)
$LastProfileDir = IniRead($inifile, "Settings", "LastProfileDir", "")
$LANGUAGE = IniRead($inifile, "Settings", "Language", "zh-CN")
$GithubMirror = IniRead($inifile, "Settings", "GithubMirror", "https://ghmirror.pp.ua")
If Not $LANGUAGE Then
	$LANGUAGE = 'zh-CN'
EndIf
$LANG_FILE = _GetLangFile()
$LANGUAGES = _GetLanguages()

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

;~ 创建禁止检查默认浏览器策略，使用 RunFirefox 后检测默认浏览器结果不准确
UpdatePolices($FirefoxDir, "DontCheckDefaultBrowser", true)

;~ 创建禁用自动更新策略
UpdatePolices($FirefoxDir, "DisableAppUpdate", $AllowBrowserUpdate == 0)

If IsAdmin() And $cmdline[0] = 1 And $cmdline[1] = "-SetDefaultGlobal" Then
	CheckDefaultBrowser($FirefoxPath)
	Exit
EndIf

;~ 插件目录
If $CustomPluginsDir <> "" Then
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

FileDelete($FirefoxDir & "\defaults\pref\runfirefox.js")
Local $FirefoxIsRunning = ProfileInUse($ProfileDir)
If Not $FirefoxIsRunning Then
	Local $config = CheckPrefs()
	If $config Then
		FileWrite($FirefoxDir & "\defaults\pref\runfirefox.js", $config)
	EndIf
EndIf

;~ Fix Addons not Found
If $LastPlatformDir <> "" Or $LastProfileDir <> "" Then
	If $LastPlatformDir <> $FirefoxDir Or $LastProfileDir <> $ProfileDir Then
		UpdateAddonStarup()
		UpdateExtensionsJson()
	EndIf
EndIf

;~ Start Firefox
$AppPID = Run($FirefoxPath & ' -profile "' & $ProfileDir & '" ' & $Params, $FirefoxDir)

FileChangeDir(@ScriptDir)
CreateSettingsShortcut(@ScriptDir & "\" & $ScriptNameWithOutSuffix & ".vbs")

If $FirefoxIsRunning Then
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

WinWait("[REGEXPCLASS:(?i)MozillaWindowClass;REGEXPTITLE:(?i)Firefox]", "", 15)
$hWnd_browser = GethWndbyPID($AppPID, "MozillaWindowClass")

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
	For $i = 0 To UBound($aREG) - 1
		If $aREG[$i][1] Then
			$aREG[$i][2] = _WinAPI_RegOpenKey($aREG[$i][0], $aREG[$i][1], $KEY_NOTIFY)
			If $aREG[$i][2] Then
				_WinAPI_RegNotifyChangeKeyValue($aREG[$i][2], $REG_NOTIFY_CHANGE_LAST_SET, 1, 1, $hEvent)
			EndIf
		EndIf
	Next
EndIf
OnAutoItExitRegister("OnExit")

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
		; check other chrome instance
		$AppPID = AppIsRunning($FirefoxPath)
		If Not $AppPID Then
			ExitLoop
		EndIf
		$AppIsRunning = 1
		$hWnd_browser = GethWndbyPID($AppPID, "MozillaWindowClass")
	EndIf

	If $TaskBarLastChange Then
		CheckPinnedPrograms($FirefoxPath)
	EndIf

	If $hEvent And Not _WinAPI_WaitForSingleObject($hEvent, 0) Then
		; MsgBox(0, "", "Reg changed!")
		Sleep(500)
		CheckDefaultBrowser($FirefoxPath)
		For $i = 0 To UBound($aREG) - 1
			If $aREG[$i][2] Then
				_WinAPI_RegNotifyChangeKeyValue($aREG[$i][2], $REG_NOTIFY_CHANGE_LAST_SET, 1, 1, $hEvent)
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


Func OnExit()
	If $hEvent Then
		_WinAPI_CloseHandle($hEvent)
		For $i = 0 To UBound($aREG) - 1
			_WinAPI_RegCloseKey($aREG[$i][2])
		Next
	EndIf
	IniWrite($inifile, "Settings", "LastPlatformDir", $FirefoxDir)
	IniWrite($inifile, "Settings", "LastProfileDir", $ProfileDir)
EndFunc   ;==>OnExit


;~ 查检 RunFirefox更新
Func CheckAppUpdate()
	Local $AppUpdateLastCheck, $repo = 'benzBrake/RunFirefox', $latestVersion, $releaseNotes, $downloadUrl, $MirrorAddress = $GithubMirror
	if Not _StringEndsWith($MirrorAddress, "/") Then
		$MirrorAddress = $MirrorAddress & "/"
	EndIf
	$AppUpdateLastCheck = _NowCalc()
	IniWrite($inifile, "Settings", "AppUpdateLastCheck", $AppUpdateLastCheck)

	HttpSetProxy(0) ; Use IE defaults for proxy
	$latestVersion = GetLatestReleaseVersion($repo, $MirrorAddress);
	;~ 获取的版本号不对则返回
	If Not _StringStartsWith($latestVersion, 'v') Then Return
	;~ 去除版本号开头的 v
	$latestVersion = StringTrimLeft($latestVersion, 1)
	;~ 比较版本号，如果版本号相同则返回
	If VersionCompare($latestVersion, $AppVersion) <= 0 Then Return
	;~ 获取更新日志
	$releaseNotes = GetReleaseNotesByVersion($repo, "v" & $latestVersion, $MirrorAddress);

	$UpdateAvailable = _t("UpdateAvailable", "{AppName} {Version} 已发布，更新内容：\n\n\n{Notes}\n是否自动更新？")
	$UpdateAvailable = StringReplace($UpdateAvailable, "{AppName}", $CustomArch)
	$UpdateAvailable = StringReplace($UpdateAvailable, "{Version}", $latestVersion)
	$UpdateAvailable = StringReplace($UpdateAvailable, "{Notes}", $releaseNotes)
	$msg = MsgBox(68, $CustomArch, $UpdateAvailable);
	If $msg <> 6 Then Return

	;~ 拼接下载链接
	$archStr = '';
	If @AutoItX64 Then
		$archStr &= "_x64"
	EndIf
	$downloadUrl = $MirrorAddress & 'https://github.com/' & $repo & '/releases/download/v' & $latestVersion & '/' & $CustomArch & '_' & $latestVersion & $archStr &'.zip'
	ConsoleWrite($downloadUrl)

	Local $temp = @ScriptDir & "\RunFirefox_temp"
	$file = $temp & "\RunFirefox.zip"
	If Not FileExists($temp) Then DirCreate($temp)
	Opt("TrayAutoPause", 0)
	Opt("TrayMenuMode", 3) ; Default tray menu items (Script Paused/Exit) will not be shown.
	TraySetState(1)
	TraySetClick(8)
	TraySetToolTip($CustomArch)
	Local $hCancelAppUpdate = TrayCreateItem(_t("CancelAppUpdate", "取消更新..."))
	TrayTip("", _t("StartToDownloadApp", "开始下载 {AppName}"), 10, 1)
	Local $hDownload = InetGet($downloadUrl, $file, 19, 1)
	Local $DownloadSuccessful, $DownloadCancelled, $UpdateSuccessful, $error
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
EndFunc   ;==>CheckAppUpdate


Func DeleteCfgFiles()
	FileDelete($FirefoxDir & "\defaults\pref\runfirefox.js")
	FileDelete($FirefoxDir & "\runfirefox.cfg")
EndFunc   ;==>DeleteCfgFiles

Func CheckPrefs()
	Local $var, $cfg
	Local $prefs = FileRead($ProfileDir & "\prefs.js")

	If Not StringRegExp($prefs, '(?i)(?m)^\Quser_pref("browser.shell.checkDefaultBrowser",\E *\Qfalse);\E') Then
		$cfg &= 'pref("browser.shell.checkDefaultBrowser", false);' & @CRLF
	EndIf

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
						$AppUserModelId = AppIdFromRegistry()
						If Not $AppUserModelId Then
							; helper.exe writes AppUserModelIDs to SOFTWARE\Mozilla\Firefox\TaskBarIDs
							Local $pid = Run($FirefoxDir & "\uninstall\helper.exe /UpdateShortcutAppUserModelIds")
							ProcessWaitClose($pid, 5)
							$AppUserModelId = AppIdFromRegistry()
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
		If Not $aREG[5 + $i][1] Then
			$aREG[5 + $i][1] = $aAsso[$i] ; for reg notification
			$aREG[5 + $i][2] = _WinAPI_RegOpenKey($aREG[5 + $i][0], $aREG[5 + $i][1], $KEY_NOTIFY)
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
EndFunc   ;==>CheckDefaultBrowser

Func UpdateAddonStarup()
	Local $mozlz4Exe, $addonStarup, $addonStarupLz4

	; Extract mozlz4
	If @OSArch = "X86" Then
		$mozlz4Exe = @ScriptDir & "\" & "mozlz4-win32.exe"
		FileInstall("mozlz4-win32.exe", $mozlz4Exe)
	Else
		$mozlz4Exe = @ScriptDir & "\" & "mozlz4-win64.exe"
		FileInstall("mozlz4-win32.exe", $mozlz4Exe)
	EndIf

	$addonStarupLz4 = $ProfileDir & "\" & "addonStartup.json.lz4";
	$addonStarup = $ProfileDir & "\" & "addonStartup.json";

	; Extract addonStartup.json.lz4
	If FileExists($addonStarupLz4) Then
		FileDelete($addonStarup);
		RunWait($mozlz4Exe & ' ' & $addonStarupLz4 & ' ' & $addonStarup, @ScriptDir, @SW_HIDE);
	EndIf

	If FileExists($addonStarup) Then
		Local $fileOpen, $fileContent, $matches
		$fileOpen = FileOpen($addonStarup, $FO_READ)
		If $fileOpen <> -1 Then
			$fileContent = FileRead($fileOpen)
			FileClose($fileOpen)
			$fileContent = ReplaceJarPath($fileContent)
			$fileOpen = FileOpen($addonStarup, $FO_OVERWRITE)
			If $fileOpen <> -1 Then
				FileWrite($fileOpen, $fileContent)
				FileClose($fileOpen)
				RunWait($mozlz4Exe & ' -z ' & $addonStarup & ' ' & $addonStarupLz4, @ScriptDir, @SW_HIDE);
			EndIf
		EndIf
		FileDelete($addonStarup)
	EndIf

	FileDelete(@ScriptDir & "\" & "mozlz4-win32.exe")
	FileDelete(@ScriptDir & "\" & "mozlz4-win64.exe")
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
	$DefaultProfDir = IniRead(@AppDataDir & '\Mozilla\Firefox\profiles.ini', 'Profile0', 'Path', '') ; 读取Firefox原版配置文件夹路径
	If $DefaultProfDir <> "" Then
		$DefaultProfDir = StringReplace($DefaultProfDir, "/", "\")
		$DefaultProfDir = @AppDataDir & '\Mozilla\Firefox\' & $DefaultProfDir
	EndIf

	Opt("ExpandEnvStrings", 0)
	$hSettings = GUICreate(_t("AppTitle", "{AppName} - 打造自己的 Firefox 便携版"), 500, 490)
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
	GUICtrlCreateTab(5, 50, 490, 390)
	GUICtrlCreateTabItem(_t("General", "常规"))

	GUICtrlCreateGroup(_t("BrowserFiles", "浏览器程序文件"), 10, 80, 480, 120)
	GUICtrlCreateLabel(_t("FirefoxPath", "Firefox 路径"), 20, 100, 120, 20)
	$hFirefoxPath = GUICtrlCreateEdit($FirefoxPath, 140, 95, 270, 20, $ES_AUTOHSCROLL)
	GUICtrlSetTip(-1, _t("BrowserExecutablePath", "浏览器主程序路径"))
	GUICtrlSetOnEvent(-1, "OnFirefoxPathChange")
	GUICtrlCreateButton(_t("Browse", "浏览"), 420, 95, 60, 20)
	GUICtrlSetTip(-1, _t("ChoosePortableBrowser", "选择便携版浏览器\n主程序（firefox.exe）"))
	GUICtrlSetOnEvent(-1, "GetFirefoxPath")

	GUICtrlCreateLabel(_t("UpdateChannel", "更新通道"), 20, 130, 120, 20)
	$hChannel = GUICtrlCreateCombo("", 140, 125, 150, 20, $CBS_DROPDOWNLIST)
	GUICtrlSetData($hChannel, "esr|release|beta|aurora|nightly|default", "release")
	GUICtrlSetOnEvent(-1, "ChangeChannel")

	$hAllowBrowserUpdate = GUICtrlCreateCheckbox(_t("BrowserAutoUpdate", " 自动更新"),310, 125, -1, 20)
	If $AllowBrowserUpdate Then
		GUICtrlSetState(-1, $GUI_CHECKED)
	EndIf

;~ 	$hDownloadFirefox = GUICtrlCreateLabel("去下载 " & GUICtrlRead($hChannel), 300, 130, 180, 20)
;~ 	GUICtrlSetCursor(-1, 0)
;~ 	GUICtrlSetColor(-1, 0x0000FF)
;~ 	GUICtrlSetTip(-1, "去下载 Firefox")
;~ 	GUICtrlSetOnEvent(-1, "DownloadFirefox")

	;https://product-details.mozilla.org/1.0/firefox_versions.json 将来实现自动更新

	GUICtrlCreateLabel(_t("DownloadFirefox", "下载 Firefox："), 20, 160, 120, 20)
	$hDownloadFirefox32 = GUICtrlCreateLabel(_t("DownloadFirefoxX64", "%s 32位", "release"), 140, 160, 140, 20)
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetColor(-1, 0x0000FF)
	GUICtrlSetOnEvent(-1, "DownloadFirefox")

	$hDownloadFirefox64 = GUICtrlCreateLabel(_t("DownloadFirefoxX64", "%s 32位", "release"), 280, 160, 140, 20)
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetColor(-1, 0x0000FF)
	If @OSArch <> "X86" Then
		GUICtrlSetOnEvent(-1, "DownloadFirefox")
	EndIf

	GUICtrlCreateGroup(_t("ProfileFiles", "浏览器用户数据文件"), 10, 210, 480, 80)
	GUICtrlCreateLabel(_t("ProfileDirectory", "配置文件夹"), 20, 230, 120, 20)
	$hProfileDir = GUICtrlCreateEdit($ProfileDir, 140, 225, 270, 20, $ES_AUTOHSCROLL)
	GUICtrlSetTip(-1, _t("ProfileDirectoryTooltip", "浏览器配置文件夹"))
	GUICtrlCreateButton(_t("Browse", "浏览"), 420, 225, 60, 20)
	GUICtrlSetTip(-1, _t("ChooseProfileDirectory", "指定浏览器配置文件夹"))
	GUICtrlSetOnEvent(-1, "GetProfileDir")
	$hCopyProfile = GUICtrlCreateCheckbox(_t("ExtractProfileFromSystem", " 从系统中提取 Firefox 配置文件"), 30, 250, -1, 20)

	GUICtrlCreateGroup(_t("RunFirefoxOptions", "{AppName} 设置"), 10, 300, 480, 120)
	GUICtrlCreateLabel(_t("UILanguage", "显示语言/Language"), 20, 320, 120, 20)
	$hlanguage = GUICtrlCreateCombo("", 140, 315, 100, 20, $CBS_DROPDOWNLIST)
	$sLang = '简体中文'
	If _ItemExists($LANGUAGES, $LANGUAGE) Then
		$sLang = _Item($LANGUAGES, $LANGUAGE)
	EndIf
	$sLangEnum = _ArrayToString(_GetItems($LANGUAGES))
	GUICtrlSetData(-1, $sLangEnum, $slang)
	GUICtrlSetOnEvent(-1, "ChangeLanguage")

	$hCheckAppUpdate = GUICtrlCreateCheckbox(_t("NoticeMeWhenNewVersionPublished", " {AppName} 发布新版时通知我"), 20, 350)
	If $CheckAppUpdate Then
		GUICtrlSetState(-1, $GUI_CHECKED)
	EndIf
	$hRunInBackground = GUICtrlCreateCheckbox(_t("KeepRunFirefoxRunning", " {AppName} 在后台运行直至浏览器退出"), 20, 380)
	GUICtrlSetOnEvent(-1, "RunInBackground")
	If $RunInBackground Then
		GUICtrlSetState($hRunInBackground, $GUI_CHECKED)
	EndIf

	; 高级
	GUICtrlCreateTabItem(_t("Advanced", "高级"))
	GUICtrlCreateLabel(_t("PluginsDirectory", "插件目录"), 20, 90, 120, 20)
	$hCustomPluginsDir = GUICtrlCreateEdit($CustomPluginsDir, 140, 85, 270, 20, $ES_AUTOHSCROLL)
	GUICtrlSetTip(-1, _t("PluginsDirectoryToolTip", "浏览器插件目录\n空白=默认位置"))
	$hGetPluginsDir = GUICtrlCreateButton(_t("Browse", "浏览"), 420, 85, 60, 20)
	GUICtrlSetTip(-1, _t("SpecifyPluginsDirectory", "指定浏览器插件目录"))
	GUICtrlSetOnEvent(-1, "GetPluginsDir")

	GUICtrlCreateLabel(_t("CacheDirectory", "缓存位置"), 20, 130, 120, 20)
	$hCustomCacheDir = GUICtrlCreateEdit($CustomCacheDir, 140, 125, 270, 20, $ES_AUTOHSCROLL)
	GUICtrlSetTip(-1, _t("CacheDirectoryTooltip", "浏览器缓存位置\n空白=默认位置"))
	$hGetCacheDir = GUICtrlCreateButton(_t("Browse", "浏览"), 420, 125, 60, 20)
	GUICtrlSetTip(-1, _t("SpecifyCacheDirectory", "指定浏览器缓存位置"))
	GUICtrlSetOnEvent(-1, "GetCacheDir")

	GUICtrlCreateLabel(_t("CacheSize", "缓存大小"), 20, 170, 120, 20)
	$hCacheSize = GUICtrlCreateEdit($CacheSize, 140, 165, 60, 20, BitOR($ES_NUMBER, $ES_AUTOHSCROLL))
	GUICtrlSetTip(-1, _t("CacheSizeTooltip", "缓存大小\n空白=默认大小"))
	GUICtrlCreateLabel("MB", 215, 170, 35, 20)
	$hCacheSizeSmart = GUICtrlCreateCheckbox(_t("CacheSizeControl", " 自动控制缓存大小"), 250, 165, -1, 20)
	If $CacheSizeSmart Then GUICtrlSetState(-1, $GUI_CHECKED)

	GUICtrlCreateLabel(_t("CommandLineArguments", "命令行参数"), 20, 325, -1, 20)
	$hParams = GUICtrlCreateEdit("", 20, 345, 460, 70, BitOR($ES_WANTRETURN, $WS_VSCROLL, $ES_AUTOVSCROLL))
	If $Params <> "" Then
		GUICtrlSetData(-1, StringReplace($Params, " -", @CRLF & "-"))
	EndIf
	GUICtrlSetTip(-1, _t("CommandLineArgumentsTooltip", "Firefox 命令行参数，每行写一个参数。\n支持%TEMP%等环境变量，\n另外，%APP%代表 RunFirefox 所在目录"))

	; 外部程序
	GUICtrlCreateTabItem(_t("ExternalPrograms", "外部程序"))
	GUICtrlCreateLabel(_t("RunOnBrowserStart", "#浏览器启动时运行"), 20, 90, -1, 20)
	$hExAppAutoExit = GUICtrlCreateCheckbox(_t("AutoCloseAfterBrowserExit", " #浏览器退出后自动关闭"), 240, 85, -1, 20)
	If $ExAppAutoExit = 1 Then
		GUICtrlSetState($hExAppAutoExit, $GUI_CHECKED)
	EndIf
	$hExApp = GUICtrlCreateEdit("", 20, 110, 410, 50, BitOR($ES_WANTRETURN, $WS_VSCROLL, $ES_AUTOVSCROLL))
	If $ExApp <> "" Then
		GUICtrlSetData(-1, StringReplace($ExApp, "||", @CRLF) & @CRLF)
	EndIf
	GUICtrlSetTip(-1, _t("RunOnBrowserStartTooltip", "浏览器启动时运行的外部程序，支持批处理、vbs文件等\n如需启动参数，可添加在程序路径之后"))
	GUICtrlCreateButton(_t("Add", "添加"), 440, 110, 40, 20)
	GUICtrlSetTip(-1, _t("SelectExtraApp", "选择外部程序"))
	GUICtrlSetOnEvent(-1, "AddExApp")

	GUICtrlCreateLabel(_t("RunAfterBrowserExit", "#浏览器退出后运行"), 20, 190, -1, 20)
	$hExApp2 = GUICtrlCreateEdit("", 20, 210, 410, 50, BitOR($ES_WANTRETURN, $WS_VSCROLL, $ES_AUTOVSCROLL))
	If $ExApp2 <> "" Then
		GUICtrlSetData(-1, StringReplace($ExApp2, "||", @CRLF) & @CRLF)
	EndIf
	GUICtrlSetTip(-1, _t("RunAfterBrowserExitTooltip", "浏览器退出后运行的外部程序，支持批处理、vbs文件等\n如需启动参数，可添加在程序路径之后"))
	GUICtrlCreateButton(_t("Add", "添加"), 440, 210, 40, 20)
	GUICtrlSetTip(-1, _t("SelectExtraApp", "选择外部程序"))
	GUICtrlSetOnEvent(-1, "AddExApp2")

	GUICtrlCreateTabItem("")
	GUICtrlCreateButton(_t("CheckForUpdateManually", "检查更新"), 80, 440, 130, 20)
	GUICtrlSetTip(-1, _t("ConfirmTooltip", "立即更新 {AppName}"))
	GUICtrlSetOnEvent(-1, "CheckAppUpdate")
	GUICtrlCreateTabItem("")
	GUICtrlCreateButton(_t("Confirm", "确定"), 235, 440, 70, 20)
	GUICtrlSetTip(-1, _t("ConfirmTooltip", "保存设置并启动浏览器"))
	GUICtrlSetOnEvent(-1, "SettingsOK")
	GUICtrlSetState(-1, $GUI_FOCUS)
	GUICtrlCreateButton(_t("Cancel", "取消"), 330, 440, 70, 20)
	GUICtrlSetTip(-1, _t("CancelTooltip", "不保存设置并退出"))
	GUICtrlSetOnEvent(-1, "ExitApp")
	GUICtrlCreateButton(_t("Apply", "应用"), 425, 440, 70, 20)
	GUICtrlSetTip(-1, _t("ApplyTooltip", "保存设置"))
	GUICtrlSetOnEvent(-1, "SettingsApply")
	$hStatus = _GUICtrlStatusBar_Create($hSettings, -1, _t("DoublieClickToOpenSettingsWindow", '双击软件目录下的 "%s.vbs" 文件可调出此窗口', $ScriptNameWithOutSuffix))
	Opt("ExpandEnvStrings", 1)

;~ 复制配置文件选项有效/无效
	If FileExists($DefaultProfDir) Then
		GUICtrlSetState($hCopyProfile, $GUI_ENABLE)
		If $FirstRun And Not FileExists($ProfileDir & "\prefs.js") Then GUICtrlSetState($hCopyProfile, $GUI_CHECKED)
	Else
		GUICtrlSetState($hCopyProfile, $GUI_DISABLE)
	EndIf

	OnFirefoxPathChange()

	GUISetState(@SW_SHOW)
	While Not $SettingsOK
		Sleep(100)
	WEnd
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

Func OnFirefoxPathChange()
	ShowCurrentChannel()
	ChangeChannel()
EndFunc   ;==>OnFirefoxPathChange

Func ChangeChannel()
	Local $Channel = GUICtrlRead($hChannel)
	If $Channel = "default" Then $Channel = "release"
	GUICtrlSetData($hDownloadFirefox32, _t("DownloadFirefoxX86", "%s 32位", $Channel))
	GUICtrlSetData($hDownloadFirefox64, _t("DownloadFirefoxX64", "%s 64位", $Channel))
EndFunc   ;==>ChangeChannel

Func ShowCurrentChannel()
	Local $path = GUICtrlRead($hFirefoxPath)
	If Not FileExists($path) Then Return
	Local $ChannelPath = StringRegExpReplace($path, "\\?[^\\]+$", "") & "\defaults\pref\channel-prefs.js"
	Local $var = FileRead($ChannelPath)
	Local $match = StringRegExp($var, '(?i)(?m)^\Qpref("app.update.channel",\E *"(.*)\Q");\E', 1)
	If @error Then Return
	$Channel = $match[0]
	_GUICtrlComboBox_SelectString($hChannel, $Channel)
EndFunc   ;==>ShowCurrentChannel

Func DownloadFirefox()
	Local $os

	If @GUI_CtrlId = $hDownloadFirefox32 Then
		$os = "win"
	Else
		$os = "win64"
	EndIf

	Local $ChannelString = GUICtrlRead($hChannel)
	Local $Channel = StringRegExpReplace($ChannelString, " *-.*", "")

	; http://ftp.mozilla.org/pub/firefox/
	If $Channel = "release" Or $Channel = "default" Then
		$FirefoxURL = "https://download.mozilla.org/?product=firefox-latest&os=" & $os & "&lang=zh-CN"
	ElseIf $Channel = "beta" Then
		$FirefoxURL = "https://download.mozilla.org/?product=firefox-beta-latest&os=" & $os & "&lang=zh-CN"
	ElseIf $Channel = "esr" Then
		$FirefoxURL = "https://download.mozilla.org/?product=firefox-esr-latest&os=" & $os & "&lang=zh-CN"
	ElseIf $Channel = "aurora" Then
		$FirefoxURL = "https://download.mozilla.org/?product=firefox-aurora-latest-l10n&os=" & $os & "&lang=zh-CN"
	Else ;If $Channel = "nightly" Then
		$FirefoxURL = "https://download.mozilla.org/?product=firefox-nightly-latest&os=" & $os & "&lang=zh-CN"
	EndIf

	ClipPut($FirefoxURL)
	Local $msg = MsgBox(65, "RunFirefox", _t("ManuallyDownloadMessage", '请下载 Firefox 安装包，用 WinRAR、7z 等解压软件打开安装包，\n将其中的 core 文件夹提取出来，即得到 Firefox 便携版所需的程序文件。\n\n下载地址已复制到剪贴板，点击"确定"将在浏览器中打开下载页面。'), 0, $hSettings)
	If $msg = 1 Then
		ShellExecute($FirefoxURL)
	EndIf
EndFunc   ;==>DownloadFirefox

Func RunInBackground()
	If GUICtrlRead($hRunInBackground) = $GUI_CHECKED Then
		Return
	EndIf
	Local $msg = MsgBox(36 + 256, "RunFirefox", '允许 RunFirefox 在后台运行可以带来更好的用户体验。若取消此选项，请注意以下几点：\n\n 1. 将浏览器锁定到任务栏或设为默认浏览器后，需再运行一次 RunFirefox 才能生效；\n2. RunFirefox 设置界面中带“#”符号的功能/选项将不会执行，包括浏览器退出后关闭外部程序、运行外部程序等。\n\n确定要取消此选项吗？', 0, $hSettings)
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

	If GUICtrlRead($hAllowBrowserUpdate) = $GUI_CHECKED Then
		$AllowBrowserUpdate = 1
	Else
		$AllowBrowserUpdate = 0
	EndIf
	$ProfileDir = RelativePath(GUICtrlRead($hProfileDir))
	$CustomPluginsDir = RelativePath(GUICtrlRead($hCustomPluginsDir))
	$CustomCacheDir = RelativePath(GUICtrlRead($hCustomCacheDir))
	$CacheSize = GUICtrlRead($hCacheSize)
	If GUICtrlRead($hCacheSizeSmart) = $GUI_CHECKED Then
		$CacheSizeSmart = 1
	Else
		$CacheSizeSmart = 0
	EndIf
	$var = GUICtrlRead($hParams)
	$var = StringStripWS($var, 3)
	$Params = StringReplace($var, @CRLF, " ") ; 换行符换成空格
	If GUICtrlRead($hCheckAppUpdate) = $GUI_CHECKED Then
		$CheckAppUpdate = 1
	Else
		$CheckAppUpdate = 0
	EndIf
	If GUICtrlRead($hRunInBackground) = $GUI_CHECKED Then
		$RunInBackground = 1
	Else
		$RunInBackground = 0
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
	IniWrite($inifile, "Settings", "FirefoxPath", $FirefoxPath)
	IniWrite($inifile, "Settings", "ProfileDir", $ProfileDir)
	IniWrite($inifile, "Settings", "CustomPluginsDir", $CustomPluginsDir)
	IniWrite($inifile, "Settings", "CustomCacheDir", $CustomCacheDir)
	IniWrite($inifile, "Settings", "CacheSize", $CacheSize)
	IniWrite($inifile, "Settings", "CacheSizeSmart", $CacheSizeSmart)
	IniWrite($inifile, "Settings", "Params", $Params)
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

	Local $ChannelString = GUICtrlRead($hChannel)
	Local $Channel = StringRegExpReplace($ChannelString, " -.*", "")
	Local $ChannelPath = StringRegExpReplace($FirefoxPath, "\\?[^\\]+$", "") & "\defaults\pref\channel-prefs.js"
	Local $var = FileRead($ChannelPath)
	If Not StringInStr($var, 'pref("app.update.channel", "' & $Channel & '");') Then
		FileDelete($ChannelPath)
		FileWrite($ChannelPath, '// Changed by RunFirefox' & @CRLF & 'pref("app.update.channel", "' & $Channel & '");' & @CRLF)
	EndIf

	;profiles dir
	If $ProfileDir = "" Then
		MsgBox(16, "RunFirefox", _t("PleaseProfileFolder", "请设置配置文件夹！"), 0, $hSettings)
		GUICtrlSetState($hProfileDir, $GUI_FOCUS)
		Return SetError(2)
	ElseIf Not FileExists($ProfileDir) Then
		DirCreate($ProfileDir)
	EndIf

	; 提取Firefox原版配置文件
	If GUICtrlRead($hCopyProfile) = $GUI_CHECKED Then
		While ProfileInUse($ProfileDir)
			$msg = MsgBox(49, "RunFirefox", _t("CannotExtratProfileFromSystem", "浏览器正运行，无法提取配置文件！\n请关闭 Firefox 后继续。"), 0, $hSettings)
			If $msg <> 1 Then ExitLoop
		WEnd
		If $msg = 1 Then
			SplashTextOn("RunFirefox", _t("ExtractingProfile", "正在提取配置文件，请稍候 ..."), 300, 100)
			Local $var = DirCopy($DefaultProfDir, $ProfileDir, 1)
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
	If $CustomPluginsDir <> "" And Not FileExists($CustomPluginsDir) Then
		DirCreate($CustomPluginsDir)
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
	Local $path = FileOpenDialog(_t("ChooseFirefoxExecutable", "选择浏览器主程序（firefox.exe）"), @ScriptDir, _t("ExecutableFile", "可执行文件(*.exe)"), 1 + 2, "firefox.exe", $hSettings)
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

; #FUNCTION# ;===============================================================================
; Name...........: SplitPath
; Description ...: 路径分割
; Syntax.........: SplitPath($path, ByRef $dir, ByRef $file, [...$spliter])
;                  $path - 路径
;                  $dir - 目录
;                  $file - 文件名
; Return values .: Success -
;                  Failure -
; Author ........: 甲壳虫
; Mode ..........: Ryan
;============================================================================================
Func SplitPath($path, ByRef $dir, ByRef $file, $spliter = "\")
	Local $pos = StringInStr($path, $spliter, 0, -1)
	If $pos = 0 Then
		$dir = "."
		$file = $path
	Else
		$dir = StringLeft($path, $pos - 1)
		$file = StringMid($path, $pos + 1)
	EndIf
EndFunc   ;==>SplitPath

;~ 绝对路径转成相对于脚本目录的相对路径，
;~ 如 .\dir1\dir2 或 ..\dir2
Func RelativePath($path)
	If $path = "" Then Return $path
	If StringLeft($path, 1) = "%" Then Return $path
	If Not StringInStr($path, ":") And StringLeft($path, 2) <> "\\" Then Return $path
	If StringLeft(@ScriptDir, 3) <> StringLeft($path, 3) Then Return $path ; different driver
	If StringRight($path, 1) <> "\" Then $path &= "\"
	Local $r = '.\'
	Local $pos, $dir = @ScriptDir & "\"
	While 1
		$path = StringReplace($path, $dir, $r)
		If @extended Then ExitLoop
		$pos = StringInStr($dir, "\", 0, -2)
		If $pos = 0 Then ExitLoop
		$dir = StringLeft($dir, $pos)
		If StringLeft($r, 2) = '.\' Then
			$r = '..\'
		Else
			$r = '..\' & $r
		EndIf
	WEnd
	If StringRight($path, 1) = "\" Then $path = StringTrimRight($path, 1)
	Return $path
EndFunc   ;==>RelativePath

;~ 相对于脚本目录的相对路径转换成绝对路径，输出结果结尾没有 “\”。
Func FullPath($path)
	If $path = "" Then Return $path
	If StringLeft($path, 1) = "%" Then Return $path
	If StringInStr($path, ":\") Or StringLeft($path, 2) = "\\" Then Return $path
	If StringRight($path, 1) <> "\" Then $path &= "\"
	Local $dir = @ScriptDir
	If StringLeft($path, 2) = ".\" Then
		$path = StringReplace($path, '.', $dir, 1)
	ElseIf StringLeft($path, 3) <> "..\" Then
		$path = $dir & "\" & $path
	Else
		Local $i, $n, $pos
		$path = StringReplace($path, "..\", "")
		$n = @extended
		For $i = 1 To $n
			$pos = StringInStr($dir, "\", 0, -1)
			If $pos = 0 Then ExitLoop
			$dir = StringLeft($dir, $pos - 1)
		Next
		$path = $dir & "\" & $path
	EndIf
	If StringRight($path, 1) = "\" Then $path = StringTrimRight($path, 1)
	Return $path
EndFunc   ;==>FullPath

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
Func _GetLangFile()
	Local $filePath = @ScriptDir & "\" & "Lang.ini"
	Local $fileCustomPath = @ScriptDir & "\" & "LangCustom.ini"
	FileInstall("Lang.ini", $filePath, 1)
	If FileExists($fileCustomPath) Then
		$filePath = $fileCustomPath
	EndIf
	Return $filePath
EndFunc   ;==>_GetLangFile

; 获取语言支持
Func _GetLanguages()
	Local $LDic = _InitDictionary()
	If $LANG_FILE Then
		Local $langs = IniReadSectionNames($LANG_FILE)
		If Not @error Then
			For $i = 1 To $langs[0] ; 第一个参数存放长度
				local $title = IniRead($LANG_FILE, $langs[$i], "LangTitle", $langs[$i])
				_AddItem($LDic, $langs[$i], $title)
			Next
		EndIf
	EndIf
	If _ItemExists($LDic, "zh-CN") = False Then
		_AddItem($LDic, "zh-CN", "简体中文");
	EndIf
	Return $LDic
EndFunc

; 获取翻译文本
Func _t($key, $defaultString, $replaceString = "")
	local $str = $defaultString;
	If $LANG_FILE Then
		If $LANGUAGE <> "zh-CN" Then
			$str = IniRead($LANG_FILE, $LANGUAGE, $key, $defaultString);
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