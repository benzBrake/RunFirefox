#include-once
#include <File.au3>

Global $idChromePlusCurrentCaption = 0, $idChromePlusLatestCaption = 0
Global $ChromePlusBundledDir = ""
OnAutoItExitRegister("CleanupBundledChromePlus")

Func CleanupBundledChromePlus()
	If $ChromePlusBundledDir <> "" Then DirRemove($ChromePlusBundledDir, 1)
EndFunc

Func UsesBundledChromePlus($BrowserPath)
	Local $BrowserType = DetectBrowserTypeFromPath($BrowserPath)
	Return $BrowserType = $BrowserBrave Or $BrowserType = $BrowserWhale
EndFunc

; Read Machine directly: GetBinaryTypeW cannot distinguish ARM64 from AMD64.
Func GetChromePlusPEArch($Path)
	Local $File = FileOpen($Path, 16)
	If $File = -1 Then Return ""
	Local $Data = FileRead($File)
	FileClose($File)
	If BinaryLen($Data) < 64 Or BinaryMid($Data, 1, 2) <> Binary("0x4D5A") Then Return ""
	Local $Offset = DllStructCreate("byte[4]")
	DllStructSetData($Offset, 1, BinaryMid($Data, 61, 4))
	Local $Number = DllStructCreate("dword", DllStructGetPtr($Offset))
	Local $PE = DllStructGetData($Number, 1)
	If $PE < 64 Or $PE > BinaryLen($Data) - 24 Then Return ""
	If BinaryMid($Data, $PE + 1, 4) <> Binary("0x50450000") Then Return ""
	Switch String(BinaryMid($Data, $PE + 5, 2))
		Case "0x4C01"
			Return "x86"
		Case "0x6486"
			Return "x64"
		Case "0x64AA"
			Return "arm64"
	EndSwitch
	Return ""
EndFunc

Func PrepareBundledChromePlus($Arch)
	If $Arch <> "x86" And $Arch <> "x64" Then Return ""
	Local $Path = @ScriptDir & "\libs\chrome_plus\version-" & $Arch & ".dll"
	If @Compiled Then
		If $ChromePlusBundledDir = "" Then $ChromePlusBundledDir = _TempFile(@TempDir, "RunFirefox_ChromePlus_" & @AutoItPID & "_", "")
		If Not FileExists($ChromePlusBundledDir) And Not DirCreate($ChromePlusBundledDir) Then Return ""
		$Path = $ChromePlusBundledDir & "\version-" & $Arch & ".dll"
		If Not FileExists($Path) Then
			If $Arch = "x86" Then
				If Not FileInstall("libs\chrome_plus\version-x86.dll", $Path, 1) Then Return ""
			Else
				If Not FileInstall("libs\chrome_plus\version-x64.dll", $Path, 1) Then Return ""
			EndIf
		EndIf
	EndIf
	If GetChromePlusPEArch($Path) <> $Arch Then Return ""
	Return $Path
EndFunc

Func PrepareBundledChromePlusConfig()
	Local $Path = @ScriptDir & "\libs\chrome_plus\chrome++.ini"
	If @Compiled Then
		If $ChromePlusBundledDir = "" Then $ChromePlusBundledDir = _TempFile(@TempDir, "RunFirefox_ChromePlus_" & @AutoItPID & "_", "")
		If Not FileExists($ChromePlusBundledDir) And Not DirCreate($ChromePlusBundledDir) Then Return ""
		$Path = $ChromePlusBundledDir & "\chrome++.ini"
		If Not FileExists($Path) Then
			If Not FileInstall("libs\chrome_plus\chrome++.ini", $Path, 1) Then Return ""
		EndIf
	EndIf
	If Not FileExists($Path) Then Return ""
	Return $Path
EndFunc

Func ChromePlusFilesMatch($First, $Second)
	If $First = "" Or $Second = "" Or Not FileExists($First) Or Not FileExists($Second) Then Return False
	Local $Hash = _Crypt_HashFile($First, $CALG_SHA_256)
	If @error Then Return False
	Local $OtherHash = _Crypt_HashFile($Second, $CALG_SHA_256)
	If @error Then Return False
	Return $Hash = $OtherHash
EndFunc

Func IsBundledChromePlusInstalled($BrowserPath)
	Return ChromePlusFilesMatch(GetChromePlusPatchPath($BrowserPath), PrepareBundledChromePlus(GetChromePlusPEArch($BrowserPath)))
EndFunc

Func UpdateBundledChromePlusLabels()
	Local $BrowserPath = GetCurrentSettingsBrowserPath()
	If Not UsesBundledChromePlus($BrowserPath) Then Return False
	Local $Source = PrepareBundledChromePlus(GetChromePlusPEArch($BrowserPath))
	Local $Version = "-", $Current = GetChromePlusInstalledVersion($BrowserPath)
	If $Source <> "" Then $Version = ReadExecutableVersionField($Source, "ProductVersion")
	If $Version = "" Then $Version = "-"
	If $Current = "" Then $Current = "-"
	GUICtrlSetData($idChromePlusCurrentCaption, _t("ChromePlusInstalledVersion", "已安装版本："))
	GUICtrlSetData($idChromePlusLatestCaption, _t("ChromePlusBundledVersion", "内置版本："))
	GUICtrlSetData($idChromePlusCurrentVersion, $Current)
	GUICtrlSetData($idChromePlusLatestVersion, $Version)
	GUICtrlSetData($idChromePlusHint, _t("ChromePlusBundledHint", "内置自编译版 Chrome++（Brave / Whale），按浏览器架构离线安装。"))
	Local $Label = _t("InstallBundledChromePlus", "安装内置 Chrome++")
	If IsChromePlusPatchInstalled($BrowserPath) Then $Label = _t("ReplaceBundledChromePlus", "替换为内置 Chrome++")
	GUICtrlSetData($idChromePlusDownloadPatch, $Label)
	GUICtrlSetState($idChromePlusDownloadPatch, $GUI_SHOW)
	Local $State = $GUI_DISABLE
	If FileExists($BrowserPath) And Not IsBundledChromePlusInstalled($BrowserPath) Then $State = $GUI_ENABLE
	GUICtrlSetState($idChromePlusDownloadPatch, $State)
	Return True
EndFunc

Func InstallBundledChromePlus($BrowserPath)
	Local $Arch = GetChromePlusPEArch($BrowserPath)
	Local $Source = "", $ConfigSource = "", $ErrorMessage = "", $Target = GetChromePlusPatchPath($BrowserPath)
	Local $Log = "Chrome++ bundled install" & @CRLF & "Browser: " & $BrowserPath & @CRLF & "Architecture: " & $Arch & @CRLF
	If $Arch <> "x86" And $Arch <> "x64" Then
		$ErrorMessage = _t("ChromePlusBundledUnsupportedArch", "内置 Chrome++ 仅支持 x86/x64，无法识别或不支持当前浏览器架构。")
	Else
		$Source = PrepareBundledChromePlus($Arch)
		$ConfigSource = PrepareBundledChromePlusConfig()
		$Log &= "Source: " & $Source & @CRLF & "Config source: " & $ConfigSource & @CRLF & "Target: " & $Target & @CRLF
		If $Source = "" Or $ConfigSource = "" Then
			$ErrorMessage = _t("ChromePlusBundledResourceFailed", "内置 Chrome++ DLL 缺失、提取失败或架构不匹配。")
		ElseIf $Target = "" Or Not FileCopy($Source, $Target, 9) Then
			$ErrorMessage = _t("FailToExtractChromePlusPatch", "解压或安装 Chrome++ 补丁失败。")
		ElseIf Not ChromePlusFilesMatch($Source, $Target) Then
			$ErrorMessage = _t("ChromePlusBundledResourceFailed", "内置 Chrome++ DLL 缺失、提取失败或架构不匹配。")
		ElseIf Not InstallChromePlusConfig($ConfigSource, GetChromePlusConfigPath($BrowserPath)) Then
			$ErrorMessage = _t("ChromePlusTabsSaveFailed", "保存 Chrome++ 标签页设置失败：\n%s", GetChromePlusConfigPath($BrowserPath))
		EndIf
	EndIf
	If $ErrorMessage <> "" Then
		ShowChromePlusPatchInstallFailedDialog($ErrorMessage, WriteChromePlusInstallLog($Log & "Error: " & $ErrorMessage))
		Return False
	EndIf
	If $hStatus Then _GUICtrlStatusBar_SetText($hStatus, _t("ChromePlusPatchInstalled", "Chrome++ 补丁已安装。"))
	Return True
EndFunc
