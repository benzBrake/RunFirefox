#include-once
#include "DownloadTools.au3"

; Portable browser auto update managed by RunFirefox itself.
; The update package is downloaded to a staging directory first and applied on
; the next RunFirefox launch, before the browser process starts (like Firefox).
Global $BAU_StagingDir = ""
; Transaction errors: 1 = failed but rolled back, 2 = recovery/busy/unsafe,
; 3 = committed, cleanup still pending, 4 = profile conflict. Never discard a journal on error 2/3.
Global Const $BAU_TX_FAILED = 1, $BAU_TX_PENDING = 2, $BAU_TX_CLEANUP = 3, $BAU_TX_PROFILE = 4

Func _BrowserAutoUpdateTransactionPath($TargetDir)
	Return $TargetDir & ".RunFirefoxUpdate.ini"
EndFunc

Func _BrowserAutoUpdateTransactionMessage($TargetDir)
	Local $Message = _t("BrowserUpdateRecoveryFailed", "浏览器更新事务尚未完成，已停止本次操作。请关闭相关浏览器及占用目录的程序后重试。\n目标目录：{Target}\n事务日志：{Journal}")
	Return StringReplace(StringReplace($Message, "{Target}", $TargetDir), "{Journal}", _BrowserAutoUpdateTransactionPath($TargetDir))
EndFunc

; Canonicalize before comparing paths; FullPath alone does not collapse all '..'.
Func _BrowserAutoUpdateCanonical($Path)
	Local $Result = DllCall("kernel32.dll", "dword", "GetFullPathNameW", "wstr", $Path, "dword", 32768, "wstr", "", "ptr", 0)
	If @error Or $Result[0] = 0 Or $Result[0] >= 32768 Then Return ""
	Return StringRegExpReplace($Result[3], "\\+$", "")
EndFunc

; Resolve aliases such as junctions and short names, even for an uncreated profile.
Func _BrowserAutoUpdatePhysicalPath($Path)
	Local $Tail = ""
	While $Path <> ""
		Local $Open = DllCall("kernel32.dll", "handle", "CreateFileW", "wstr", $Path, "dword", 0, "dword", 7, "ptr", 0, "dword", 3, "dword", 0x02000000, "ptr", 0)
		If @error Then Return ""
		If $Open[0] <> Ptr(-1) Then
			Local $Final = DllCall("kernel32.dll", "dword", "GetFinalPathNameByHandleW", "handle", $Open[0], "wstr", "", "dword", 32768, "dword", 0)
			Local $CallError = @error
			DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $Open[0])
			If $CallError Or $Final[0] = 0 Or $Final[0] >= 32768 Then Return ""
			Return StringRegExpReplace($Final[2], "\\+$", "") & $Tail
		EndIf
		Local $Parent, $Name
		SplitPath($Path, $Parent, $Name)
		If $Name = "" Or $Parent = "." Or $Parent = $Path Then ExitLoop
		$Tail = "\" & $Name & $Tail
		$Path = $Parent
		If StringRegExp($Path, "^[A-Za-z]:$") Then $Path &= "\"
	WEnd
	Return ""
EndFunc

Func _BrowserAutoUpdatePathWithin($TargetDir, $ProfileDir)
	Return $TargetDir <> "" And $ProfileDir <> "" And StringLeft($ProfileDir & "\", StringLen($TargetDir) + 1) = $TargetDir & "\"
EndFunc

Func _BrowserAutoUpdateProfileConflict($TargetDir, $ProfileDir, $OtherProfileDir = "")
	If $OtherProfileDir <> "" And $OtherProfileDir <> $ProfileDir Then
		Local $OtherConflict = _BrowserAutoUpdateProfileConflict($TargetDir, $OtherProfileDir)
		If $OtherConflict <> "" Then Return $OtherConflict
	EndIf
	If $ProfileDir = "" Then Return ""
	$ProfileDir = _BrowserAutoUpdateCanonical(FullPath(StringReplace($ProfileDir, "/", "\")))
	$TargetDir = _BrowserAutoUpdateCanonical($TargetDir)
	If Not _BrowserAutoUpdatePathWithin($TargetDir, $ProfileDir) And _
			Not _BrowserAutoUpdatePathWithin(_BrowserAutoUpdatePhysicalPath($TargetDir), _BrowserAutoUpdatePhysicalPath($ProfileDir)) Then Return ""
	Local $Message = _t("BrowserUpdateProfileInsideTarget", "浏览器配置目录位于目标程序目录内，本次替换已停止。请关闭浏览器，将配置目录移到程序目录之外，并在设置中更新路径后重试。\n程序目录：{Target}\n配置目录：{Profile}")
	Return StringReplace(StringReplace($Message, "{Target}", $TargetDir), "{Profile}", $ProfileDir)
EndFunc

; Reject reparse points anywhere in the path, including parent directories.
Func _BrowserAutoUpdateSafePath($Path)
	Local $Current = $Path
	While $Current <> ""
		Local $Attr = DllCall("kernel32.dll", "dword", "GetFileAttributesW", "wstr", $Current)
		If @error Then Return False
		If $Attr[0] <> 4294967295 And BitAND($Attr[0], 0x400) Then Return False
		Local $Parent = "", $Name = ""
		SplitPath($Current, $Parent, $Name)
		If $Parent = $Current Or $Parent = "." Then ExitLoop
		$Current = $Parent
	WEnd
	Return True
EndFunc

; Check a tree before copying/deleting it, never following junctions or symlinks.
Func _BrowserAutoUpdateSafeTree($Path)
	If Not _BrowserAutoUpdateSafePath($Path) Then Return False
	If Not FileExists($Path) Then Return True
	If Not StringInStr(FileGetAttrib($Path), "D") Then Return False
	Local $Search = FileFindFirstFile($Path & "\*")
	If $Search = -1 Then Return True
	Local $Safe = True
	While 1
		Local $Name = FileFindNextFile($Search)
		If @error Then ExitLoop
		Local $Child = $Path & "\" & $Name
		If Not _BrowserAutoUpdateSafePath($Child) Then
			$Safe = False
			ExitLoop
		EndIf
		If StringInStr(FileGetAttrib($Child), "D") And Not _BrowserAutoUpdateSafeTree($Child) Then
			$Safe = False
			ExitLoop
		EndIf
	WEnd
	FileClose($Search)
	Return $Safe
EndFunc

Func _BrowserAutoUpdateTransactionLock($TargetDir)
	If $TargetDir = "" Or Not _BrowserAutoUpdateSafePath($TargetDir) Then Return SetError($BAU_TX_PENDING, 0, 0)
	Local $Parent = "", $Name = ""
	SplitPath($TargetDir, $Parent, $Name)
	If $Parent = "" Or $Parent = "." Or Not StringRegExp($Name, '^[^<>:"/\\|?*\x00-\x1f]+$') Or StringRegExp($Name, '[ .]$') Then Return SetError($BAU_TX_PENDING, 0, 0)
	Local $Journal = _BrowserAutoUpdateTransactionPath($TargetDir)
	If Not _BrowserAutoUpdateSafePath($Journal) Or Not _BrowserAutoUpdateSafePath($Journal & ".lock") Or Not _BrowserAutoUpdateSafePath($Journal & ".tmp") Then Return SetError($BAU_TX_PENDING, 0, 0)
	Local $Result = DllCall("kernel32.dll", "handle", "CreateFileW", "wstr", $Journal & ".lock", "dword", 0xC0000000, "dword", 0, "ptr", 0, "dword", 4, "dword", 0x80, "ptr", 0)
	If @error Or $Result[0] = Ptr(-1) Then Return SetError($BAU_TX_PENDING, 0, 0)
	Return $Result[0]
EndFunc

Func _BrowserAutoUpdateUnlock($Handle)
	DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $Handle)
EndFunc

; MoveFileEx gives us an OS error for bounded retries. No replace for trees.
Func _BrowserAutoUpdateMove($From, $To, $Flags = 0)
	Local $Timer = TimerInit()
	While 1
		Local $Result = DllCall("kernel32.dll", "bool", "MoveFileExW", "wstr", $From, "wstr", $To, "dword", $Flags)
		If @error Then Return False
		If $Result[0] Then Return True
		Local $Code = DllCall("kernel32.dll", "dword", "GetLastError")
		If @error Then Return False
		If ($Code[0] <> 5 And $Code[0] <> 32 And $Code[0] <> 33) Or TimerDiff($Timer) >= 2000 Then Return False
		Sleep(50)
	WEnd
EndFunc

Func _BrowserAutoUpdateRemoveTree($Path, $ClearReadOnly = False)
	If Not _BrowserAutoUpdateSafeTree($Path) Then Return False
	If Not FileExists($Path) Then Return True
	Local $Search = FileFindFirstFile($Path & "\*")
	If $Search <> -1 Then
		Local $Success = True
		While 1
			Local $Name = FileFindNextFile($Search)
			If @error Then ExitLoop
			Local $Child = $Path & "\" & $Name
			If StringInStr(FileGetAttrib($Child), "D") Then
				$Success = _BrowserAutoUpdateRemoveTree($Child, $ClearReadOnly)
			Else
				$Success = _BrowserAutoUpdateDeleteFile($Child, $ClearReadOnly)
			EndIf
			If Not $Success Then ExitLoop
		WEnd
		FileClose($Search)
		If Not $Success Then Return False
	EndIf
	Local $Timer = TimerInit()
	While 1
		Local $Result = DllCall("kernel32.dll", "bool", "RemoveDirectoryW", "wstr", $Path)
		If @error Then Return False
		If $Result[0] Then Return True
		Local $Code = DllCall("kernel32.dll", "dword", "GetLastError")
		If @error Then Return False
		If ($Code[0] <> 5 And $Code[0] <> 32 And $Code[0] <> 33) Or TimerDiff($Timer) >= 2000 Then Return False
		Sleep(50)
	WEnd
EndFunc

Func _BrowserAutoUpdateDeleteFile($Path, $ClearReadOnly = False)
	If Not _BrowserAutoUpdateSafePath($Path) Then Return False
	If Not FileExists($Path) Then Return True
	Local $Timer = TimerInit()
	While 1
		Local $Result = DllCall("kernel32.dll", "bool", "DeleteFileW", "wstr", $Path)
		If @error Then Return False
		If $Result[0] Then Return True
		Local $Code = DllCall("kernel32.dll", "dword", "GetLastError")
		If @error Then Return False
		If $Code[0] = 5 And $ClearReadOnly Then
			$ClearReadOnly = False
			If _BrowserAutoUpdateClearReadOnlyFile($Path) Then ContinueLoop
		EndIf
		If ($Code[0] <> 5 And $Code[0] <> 32 And $Code[0] <> 33) Or TimerDiff($Timer) >= 2000 Then Return False
		Sleep(50)
	WEnd
EndFunc

Func _BrowserAutoUpdateClearReadOnlyFile($Path)
	If Not _BrowserAutoUpdateSafePath($Path) Then Return False
	Local $Attributes = DllCall("kernel32.dll", "dword", "GetFileAttributesW", "wstr", $Path)
	If @error Or $Attributes[0] = 4294967295 Then Return False
	If BitAND($Attributes[0], 0x410) Or Not BitAND($Attributes[0], 0x1) Then Return False ; reparse point, directory, or writable file
	Local $Writable = BitAND($Attributes[0], BitNOT(0x1))
	If $Writable = 0 Then $Writable = 0x80 ; FILE_ATTRIBUTE_NORMAL
	Local $Result = DllCall("kernel32.dll", "bool", "SetFileAttributesW", "wstr", $Path, "dword", $Writable)
	If @error Then Return False
	Return $Result[0]
EndFunc

Func _BrowserAutoUpdateWriteTransaction($TargetDir, $Id, $HadTarget, $Committed)
	Local $Parent = "", $Name = ""
	SplitPath($TargetDir, $Parent, $Name)
	Local $Journal = _BrowserAutoUpdateTransactionPath($TargetDir)
	Local $Text = "[Transaction]" & @LF & "Format=1" & @LF & "Target=" & $Name & @LF & "Id=" & $Id & @LF & "HadTarget=" & Int($HadTarget) & @LF & "Committed=" & Int($Committed) & @LF
	Local $File = FileOpen($Journal & ".tmp", 2 + 256)
	If $File = -1 Then Return False
	Local $Written = FileWrite($File, $Text)
	Local $Flushed = FileFlush($File)
	FileClose($File)
	If Not $Written Or Not $Flushed Then Return False
	Return _BrowserAutoUpdateMove($Journal & ".tmp", $Journal, 1 + 8)
EndFunc

; Called only under the target lock. Inferring progress from the three paths
; makes recovery idempotent even if a process dies during recovery itself.
Func _BrowserAutoUpdateRecoverLocked($TargetDir, $ProfileDir = "", $OtherProfileDir = "", $TargetFile = "")
	Local $Journal = _BrowserAutoUpdateTransactionPath($TargetDir)
	If Not FileExists($Journal) Then Return True
	Local $Parent = "", $Name = ""
	SplitPath($TargetDir, $Parent, $Name)
	; Parse the complete UTF-8 record rather than Windows' ANSI profile API.
	; Reject duplicate/unknown fields and incomplete records, including truncation.
	If FileGetSize($Journal) > 8192 Then Return SetError($BAU_TX_PENDING, 0, False)
	Local $File = FileOpen($Journal, 256)
	If $File = -1 Then Return SetError($BAU_TX_PENDING, 0, False)
	Local $Text = FileRead($File)
	FileClose($File)
	Local $Record = StringRegExp($Text, '\A\[Transaction\]\nFormat=1\nTarget=([^\n]+)\nId=([0-9]{1,10}_[0-9]{9}_[0-9]{9})\nHadTarget=([01])\nCommitted=([01])\n\z', 1)
	If Not IsArray($Record) Then Return SetError($BAU_TX_PENDING, 0, False)
	If $Record[0] <> $Name Then Return SetError($BAU_TX_PENDING, 0, False)
	Local $Id = $Record[1], $Had = $Record[2], $Committed = $Record[3]
	Local $New = $TargetDir & ".RunFirefoxNew_" & $Id
	Local $Old = $TargetDir & ".RunFirefoxOld_" & $Id
	If Not _BrowserAutoUpdateSafeTree($TargetDir) Or Not _BrowserAutoUpdateSafeTree($New) Or Not _BrowserAutoUpdateSafeTree($Old) Then Return SetError($BAU_TX_PENDING, 0, False)
	If _BrowserAutoUpdateDirectoryRunning($New) Or _BrowserAutoUpdateDirectoryRunning($Old) Then Return SetError($BAU_TX_PENDING, 0, False)
	; A committed launch only cleans sibling paths, even if the new browser is running.
	If ($Committed <> "1" Or $TargetFile = "") And _BrowserAutoUpdateDirectoryRunning($TargetDir) Then Return SetError($BAU_TX_PENDING, 0, False)
	Local $Error = $BAU_TX_PENDING
	If $Committed = "1" Then
		If Not FileExists($TargetDir) Or FileExists($New) Or ($Had = "0" And FileExists($Old)) Then Return SetError($Error, 0, False)
		; An older launcher may have committed a swap with the profile still in $Old.
		If FileExists($Old) And _BrowserAutoUpdateProfileConflict($TargetDir, $ProfileDir, $OtherProfileDir) <> "" Then Return SetError($Error, 0, False)
		If $TargetFile <> "" Then
			Local $TargetAttributes = FileGetAttrib($TargetDir & "\" & $TargetFile)
			If @error Or $TargetAttributes = "" Or StringInStr($TargetAttributes, "D") Then Return SetError($Error, 0, False)
		EndIf
		$Error = $BAU_TX_CLEANUP
		If Not _BrowserAutoUpdateRemoveTree($Old, True) Then Return SetError($Error, 0, False)
	Else
		If $Had = "1" Then
			If FileExists($Old) Then
				If FileExists($TargetDir) Then
					If FileExists($New) Then Return SetError($Error, 0, False)
					If Not _BrowserAutoUpdateMove($TargetDir, $New) Then Return SetError($Error, 0, False)
				EndIf
				If Not _BrowserAutoUpdateMove($Old, $TargetDir) Then Return SetError($Error, 0, False)
			ElseIf Not FileExists($TargetDir) Then
				Return SetError($Error, 0, False)
			EndIf
		Else
			If FileExists($Old) Or (FileExists($TargetDir) And FileExists($New)) Then Return SetError($Error, 0, False)
			If FileExists($TargetDir) And Not _BrowserAutoUpdateMove($TargetDir, $New) Then Return SetError($Error, 0, False)
		EndIf
		If Not _BrowserAutoUpdateRemoveTree($New) Then Return SetError($Error, 0, False)
	EndIf
	If Not _BrowserAutoUpdateDeleteFile($Journal & ".tmp") Or Not _BrowserAutoUpdateDeleteFile($Journal) Then Return SetError($Error, 0, False)
	Return True
EndFunc

Func _BrowserAutoUpdateRecover($TargetDir, $ProfileDir = "", $OtherProfileDir = "", $TargetFile = "")
	$TargetDir = _BrowserAutoUpdateCanonical($TargetDir)
	If $TargetDir = "" Then Return SetError($BAU_TX_PENDING, 0, False)
	; A lock alone also protects a writer before its initial journal is published.
	If Not FileExists(_BrowserAutoUpdateTransactionPath($TargetDir)) And Not FileExists(_BrowserAutoUpdateTransactionPath($TargetDir) & ".lock") Then Return True
	Local $Lock = _BrowserAutoUpdateTransactionLock($TargetDir)
	If @error Then Return SetError($BAU_TX_PENDING, 0, False)
	Local $Result = _BrowserAutoUpdateRecoverLocked($TargetDir, $ProfileDir, $OtherProfileDir, $TargetFile), $Error = @error
	_BrowserAutoUpdateUnlock($Lock)
	Return SetError($Error, 0, $Result)
EndFunc

Func _BrowserAutoUpdateRecoverForLaunch($TargetDir, $TargetFile, $ProfileDir)
	Local $Recovered = _BrowserAutoUpdateRecover($TargetDir, $ProfileDir, "", $TargetFile), $Error = @error
	If $Error = $BAU_TX_CLEANUP And $TargetFile <> "" Then Return SetExtended(1, True)
	Return $Recovered
EndFunc

Func _BrowserAutoUpdateConfigure($StagingDir)
	$BAU_StagingDir = $StagingDir
EndFunc

; Only browsers whose latest version + download url can be resolved reliably
; are supported for now. Extend this list to bring more Chromiums on board.
Func _BrowserAutoUpdateIsSupported($BrowserType)
	Local $Normalized = NormalizeBrowserType($BrowserType)
	Return $Normalized = $BrowserChrome Or $Normalized = $BrowserBrave Or $Normalized = $BrowserWhale Or $Normalized = $BrowserCocCoc
EndFunc

Func _BrowserAutoUpdateGetStagingDir()
	If $BAU_StagingDir = "" Then $BAU_StagingDir = @ScriptDir & "\BrowserUpdateCache"
	Return $BAU_StagingDir
EndFunc

Func _BrowserAutoUpdateGetMetadataPath()
	Return _BrowserAutoUpdateGetStagingDir() & "\update.ini"
EndFunc

; Dot-separated numeric compare so "139.0.2" is never considered newer than "139.0.10".
Func _BrowserAutoUpdateVersionIsNewer($NewVersion, $CurrentVersion)
	$NewVersion = StringRegExpReplace(StringStripWS($NewVersion, 3), "^[vV]", "")
	$CurrentVersion = StringRegExpReplace(StringStripWS($CurrentVersion, 3), "^[vV]", "")
	If $NewVersion = "" Then Return False
	If $CurrentVersion = "" Or $CurrentVersion = "-" Then Return True
	If $NewVersion = $CurrentVersion Then Return False

	Local $NewParts = StringSplit($NewVersion, ".", 2)
	Local $CurrentParts = StringSplit($CurrentVersion, ".", 2)
	Local $Count = UBound($NewParts)
	If UBound($CurrentParts) > $Count Then $Count = UBound($CurrentParts)
	For $i = 0 To $Count - 1
		Local $NewPart = 0, $CurrentPart = 0
		If $i < UBound($NewParts) Then $NewPart = Number(StringRegExpReplace($NewParts[$i], "[^0-9].*$", ""))
		If $i < UBound($CurrentParts) Then $CurrentPart = Number(StringRegExpReplace($CurrentParts[$i], "[^0-9].*$", ""))
		If $NewPart > $CurrentPart Then Return True
		If $NewPart < $CurrentPart Then Return False
	Next
	Return False
EndFunc

Func _BrowserAutoUpdateGetLocalVersion($BrowserPath, $BrowserType = "")
	If Not FileExists($BrowserPath) Then Return ""
	Local $Version = ReadExecutableVersionField($BrowserPath, "FileVersion")
	If $Version = "" Then $Version = ReadExecutableVersionField($BrowserPath, "ProductVersion")
	If NormalizeBrowserType($BrowserType) = $BrowserBrave Then $Version = NormalizeBraveVersionText($Version)
	Return $Version
EndFunc

; Returns an array [Version, Channel, PackagePath] when a complete staged
; update exists, otherwise "" (partial *.part leftovers are ignored).
Func _BrowserAutoUpdateGetPendingUpdate()
	Local $Metadata = _BrowserAutoUpdateGetMetadataPath()
	If Not FileExists($Metadata) Then Return ""
	Local $Version = IniRead($Metadata, "Update", "Version", "")
	Local $Channel = IniRead($Metadata, "Update", "Channel", "stable")
	Local $Package = IniRead($Metadata, "Update", "Package", "")
	If $Version = "" Or $Package = "" Then Return ""
	Local $PackagePath = _BrowserAutoUpdateGetStagingDir() & "\" & $Package
	If Not FileExists($PackagePath) Then Return ""
	Local $Info[3] = [$Version, $Channel, $PackagePath]
	Return $Info
EndFunc

Func _BrowserAutoUpdateCleanStaging()
	DirRemove(_BrowserAutoUpdateGetStagingDir(), 1)
EndFunc

; Drop *.part leftovers from an interrupted download so they are never
; mistaken for a complete update package.
Func _BrowserAutoUpdateCleanPartialDownloads()
	Local $Dir = _BrowserAutoUpdateGetStagingDir()
	If Not FileExists($Dir) Then Return
	Local $hSearch = FileFindFirstFile($Dir & "\*.part")
	If $hSearch = -1 Then Return
	While 1
		Local $Name = FileFindNextFile($hSearch)
		If @error Then ExitLoop
		FileDelete($Dir & "\" & $Name)
	WEnd
	FileClose($hSearch)
EndFunc

; Replace a browser directory with a fully extracted tree. The staging and
; backup directories live beside the target so the rename operations stay on
; the same volume. Only RunFirefox-managed Chrome++ files are carried over.
Func _BrowserAutoUpdateReplaceBrowserDirectory($SourceDir, $TargetDir, $ProfileDir = "", $OtherProfileDir = "")
	$TargetDir = _BrowserAutoUpdateCanonical($TargetDir)
	$SourceDir = _BrowserAutoUpdateCanonical($SourceDir)
	If $TargetDir = "" Or $SourceDir = "" Then Return SetError($BAU_TX_PENDING, 0, False)
	Local $SourcePrefix = StringLower($SourceDir & "\"), $TargetPrefix = StringLower($TargetDir & "\")
	If StringLeft($SourcePrefix, StringLen($TargetPrefix)) = $TargetPrefix Or StringLeft($TargetPrefix, StringLen($SourcePrefix)) = $SourcePrefix Or StringLeft(StringLower(@ScriptDir & "\"), StringLen($TargetPrefix)) = $TargetPrefix Then Return SetError($BAU_TX_PENDING, 0, False)
	Local $Lock = _BrowserAutoUpdateTransactionLock($TargetDir)
	If @error Then Return SetError($BAU_TX_PENDING, 0, False)
	Local $Result = _BrowserAutoUpdateReplaceLocked($SourceDir, $TargetDir, $ProfileDir, $OtherProfileDir), $Error = @error
	_BrowserAutoUpdateUnlock($Lock)
	Return SetError($Error, 0, $Result)
EndFunc

Func _BrowserAutoUpdateReplaceLocked($SourceDir, $TargetDir, $ProfileDir, $OtherProfileDir)
	If _BrowserAutoUpdateProfileConflict($TargetDir, $ProfileDir, $OtherProfileDir) <> "" Then Return SetError($BAU_TX_PROFILE, 0, False)
	If Not _BrowserAutoUpdateRecoverLocked($TargetDir) Then Return SetError(@error, 0, False)
	If _BrowserAutoUpdateDirectoryRunning($TargetDir) Or Not FileExists($SourceDir) Or Not _BrowserAutoUpdateSafeTree($SourceDir) Or Not _BrowserAutoUpdateSafeTree($TargetDir) Then Return SetError($BAU_TX_PENDING, 0, False)
	Local $Id = @AutoItPID & "_" & Random(100000000, 999999999, 1) & "_" & Random(100000000, 999999999, 1)
	Local $New = $TargetDir & ".RunFirefoxNew_" & $Id
	Local $Old = $TargetDir & ".RunFirefoxOld_" & $Id
	If FileExists($New) Or FileExists($Old) Then Return SetError($BAU_TX_FAILED, 0, False)
	Local $HadTarget = FileExists($TargetDir)
	If Not _BrowserAutoUpdateWriteTransaction($TargetDir, $Id, $HadTarget, False) Then Return SetError($BAU_TX_PENDING, 0, False)
	Local $Ready = DirCopy($SourceDir, $New, 0)
	Local $ManagedFiles[2] = ["chrome++.ini", "version.dll"]
	For $i = 0 To UBound($ManagedFiles) - 1
		If $Ready And FileExists($TargetDir & "\" & $ManagedFiles[$i]) Then $Ready = FileCopy($TargetDir & "\" & $ManagedFiles[$i], $New & "\" & $ManagedFiles[$i], 1)
	Next
	If $Ready And $HadTarget Then $Ready = _BrowserAutoUpdateMove($TargetDir, $Old)
	If $Ready Then $Ready = _BrowserAutoUpdateMove($New, $TargetDir)
	If $Ready Then $Ready = _BrowserAutoUpdateWriteTransaction($TargetDir, $Id, $HadTarget, True)
	If Not $Ready Then
		If Not _BrowserAutoUpdateRecoverLocked($TargetDir) Then Return SetError(@error, 0, False)
		Return SetError($BAU_TX_FAILED, 0, False)
	EndIf
	If Not _BrowserAutoUpdateRecoverLocked($TargetDir) Then Return SetError(@error, 0, False)
	Return True
EndFunc

; A directory swap must not race a running browser, including child processes.
Func _BrowserAutoUpdateDirectoryRunning($TargetDir)
	Local $Processes = ProcessList()
	For $i = 1 To $Processes[0][0]
		; Limited query works across x86/x64 and does not need WMI or VM_READ.
		Local $Process = DllCall("kernel32.dll", "handle", "OpenProcess", "dword", 0x1000, "bool", False, "dword", $Processes[$i][1])
		If @error Then ContinueLoop
		If Not $Process[0] Then ContinueLoop
		Local $Image = DllCall("kernel32.dll", "bool", "QueryFullProcessImageNameW", "handle", $Process[0], "dword", 0, "wstr", "", "dword*", 32768)
		Local $QueryError = @error
		DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $Process[0])
		If $QueryError Then ContinueLoop
		If Not $Image[0] Then ContinueLoop
		Local $Path = $Image[3]
		If $Path <> "" And StringLeft(StringLower($Path), StringLen($TargetDir) + 1) = StringLower($TargetDir & "\") Then Return True
	Next
	Return False
EndFunc

; Downloads the update package atomically: *.part first, integrity check,
; then rename + metadata. Returns True when the update is staged.
Func _BrowserAutoUpdateStageUpdate($BrowserType, $Channel, $Version, $Urls, ByRef $TriedUrlsOut, $Parent = 0, $ExpectedSha256 = "")
	If Not IsArray($Urls) Or UBound($Urls) = 0 Then Return SetError(1, 0, False)

	Local $StagingDir = _BrowserAutoUpdateGetStagingDir()
	If Not FileExists($StagingDir) Then DirCreate($StagingDir)
	If Not FileExists($StagingDir) Then Return SetError(1, 0, False)
	_BrowserAutoUpdateCleanPartialDownloads()

	Local $Pending = _BrowserAutoUpdateGetPendingUpdate()
	If IsArray($Pending) And $Pending[0] = $Version Then Return True

	Local $InstallerExt = _DownloadToolsGetUrlFileExtension($Urls[0])
	Local $FinalPackage = "BrowserUpdate_" & NormalizeBrowserType($BrowserType) & "_" & $Channel & $InstallerExt
	Local $PartPackage = $FinalPackage & ".part"
	Local $PartPath = $StagingDir & "\" & $PartPackage

	_DownloadToolsShowDownloadProgress(_t("BrowserDownloadProgressTitle", "正在准备浏览器"), _t("DownloadingBrowser", "正在下载浏览器 ..."), $Urls[0], $Parent, _t("Cancel", "取消"))
	Local $TriedUrls = ""
	Local $DownloadResult = _DownloadToolsDownloadUrls($Urls, $PartPath, _t("DownloadingBrowser", "正在下载浏览器 ..."), _t("BrowserDownloadProgressKnown", "已下载 {Downloaded} / {Total}"), _t("BrowserDownloadProgressUnknown", "已下载 %s"), $TriedUrls, 600000, $ExpectedSha256)
	If @error = 2 Then
		_DownloadToolsCloseDownloadProgress()
		FileDelete($PartPath)
		Return SetError(2, 0, False)
	EndIf
	If Not $DownloadResult Or Not FileExists($PartPath) Then
		$TriedUrlsOut = $TriedUrls
		_DownloadToolsCloseDownloadProgress()
		FileDelete($PartPath)
		Return SetError(3, 0, False)
	EndIf

	; Verify the archive is intact before it is accepted as a staged update;
	; a truncated package must fail here instead of on the next launch.
	Local $TempDir = @TempDir & "\RunFirefox_BrowserUpdateVerify"
	DirRemove($TempDir, 1)
	Local $SevenZipExe = _DownloadToolsPrepareSevenZipTool($TempDir)
	If @error Then
		_DownloadToolsCloseDownloadProgress()
		FileDelete($PartPath)
		DirRemove($TempDir, 1)
		Return SetError(4, 0, False)
	EndIf
	_DownloadToolsSetDownloadProgressBusy(_t("VerifyingBrowserUpdate", "正在校验更新包，请稍候 ..."), _t("ExtractingBrowserDetail", "解压期间请不要关闭 {AppName}。"))
	Local $VerifyLog = $TempDir & "\verify.log"
	Local $VerifyResult = _DownloadToolsRunArchiveExtraction($SevenZipExe, $PartPath, $TempDir & "\check", $VerifyLog, $TempDir, 900000)
	_DownloadToolsCloseDownloadProgress()
	DirRemove($TempDir, 1)
	If $VerifyResult <> 0 Then
		FileDelete($PartPath)
		Return SetError(4, 0, False)
	EndIf

	Local $FinalPath = $StagingDir & "\" & $FinalPackage
	FileDelete($FinalPath)
	If Not FileMove($PartPath, $FinalPath) Then
		FileDelete($PartPath)
		Return SetError(5, 0, False)
	EndIf

	FileDelete(_BrowserAutoUpdateGetMetadataPath())
	IniWrite(_BrowserAutoUpdateGetMetadataPath(), "Update", "Version", $Version)
	IniWrite(_BrowserAutoUpdateGetMetadataPath(), "Update", "Channel", $Channel)
	IniWrite(_BrowserAutoUpdateGetMetadataPath(), "Update", "Package", $FinalPackage)
	Return True
EndFunc

; Applies a staged update over the browser directory. The caller must ensure
; the browser process is not running. Returns the new version on success.
Func _BrowserAutoUpdateApplyPending($BrowserPath, $BrowserType, $Parent = 0, $ProfileDir = "")
	Local $TargetDir = "", $TargetFile = ""
	SplitPath(_BrowserAutoUpdateCanonical(FullPath($BrowserPath)), $TargetDir, $TargetFile)
	If Not _BrowserAutoUpdateRecover($TargetDir, $ProfileDir, "", $TargetFile) Then Return SetError(7, @error, _BrowserAutoUpdateTransactionMessage($TargetDir))
	Local $Pending = _BrowserAutoUpdateGetPendingUpdate()
	If Not IsArray($Pending) Then Return SetError(1, 0, "")

	Local $LocalVersion = _BrowserAutoUpdateGetLocalVersion($BrowserPath, $BrowserType)
	If Not _BrowserAutoUpdateVersionIsNewer($Pending[0], $LocalVersion) Then
		; Already up to date (or newer); drop the stale package.
		_BrowserAutoUpdateCleanStaging()
		Return SetError(1, 0, "")
	EndIf

	If $TargetDir = "" Or $TargetDir = "." Then $TargetDir = @ScriptDir

	Local $ProfileConflict = _BrowserAutoUpdateProfileConflict($TargetDir, $ProfileDir)
	If $ProfileConflict <> "" Then Return SetError(8, 0, $ProfileConflict)

	Local $TempDir = @TempDir & "\RunFirefox_BrowserUpdateApply"
	DirRemove($TempDir, 1)
	If Not FileExists($TempDir) Then DirCreate($TempDir)
	Local $ExtractDir = $TempDir & "\extract"
	If Not FileExists($ExtractDir) Then DirCreate($ExtractDir)

	_DownloadToolsShowDownloadProgress(_t("BrowserUpdateProgressTitle", "正在应用浏览器更新"), _t("BrowserUpdateApplying", "正在应用更新 %s ...", $Pending[0]), $TargetDir, $Parent)
	_DownloadToolsSetDownloadProgressBusy(_t("BrowserUpdateApplying", "正在应用更新 %s ...", $Pending[0]), _t("ExtractingBrowserDetail", "解压期间请不要关闭 {AppName}。"))

	Local $SevenZipExe = _DownloadToolsPrepareSevenZipTool($TempDir)
	If @error Then
		_DownloadToolsCloseDownloadProgress()
		DirRemove($TempDir, 1)
		_BrowserAutoUpdateCleanStaging()
		Return SetError(2, 0, _t("FailToExtractBrowserInstaller", "解压浏览器安装包失败。"))
	EndIf

	Local $ExtractLog = $TempDir & "\extract.log"
	Local $ExtractResult = _DownloadToolsRunArchiveExtraction($SevenZipExe, $Pending[2], $ExtractDir, $ExtractLog, $TempDir)
	If $ExtractResult = 0 And NormalizeBrowserType($BrowserType) <> $BrowserCocCoc Then _DownloadToolsExtractNestedBrowserArchives($SevenZipExe, $ExtractDir, $TempDir)
	_DownloadToolsCloseDownloadProgress()
	If $ExtractResult <> 0 Then
		DirRemove($TempDir, 1)
		_BrowserAutoUpdateCleanStaging()
		Return SetError(3, 0, _t("FailToExtractBrowserInstaller", "解压浏览器安装包失败。"))
	EndIf

	Local $ExtractedBrowserPath = _BrowserDownloadFindBrowserExecutableForType($ExtractDir, $BrowserType)
	If Not $ExtractedBrowserPath Then
		DirRemove($TempDir, 1)
		_BrowserAutoUpdateCleanStaging()
		Return SetError(3, 0, _t("FailToExtractBrowserInstaller", "解压浏览器安装包失败。"))
	EndIf

	Local $ExtractedDir = "", $ExtractedFile = ""
	SplitPath($ExtractedBrowserPath, $ExtractedDir, $ExtractedFile)
	Local $Replaced = _BrowserAutoUpdateReplaceBrowserDirectory($ExtractedDir, $TargetDir, $ProfileDir), $ReplaceError = @error
	If $ReplaceError = $BAU_TX_PROFILE Then
		DirRemove($TempDir, 1)
		Return SetError(8, 0, _BrowserAutoUpdateProfileConflict($TargetDir, $ProfileDir))
	EndIf
	If Not $Replaced Or Not FileExists($TargetDir & "\" & $ExtractedFile) Then
		If $ReplaceError = $BAU_TX_PENDING Or $ReplaceError = $BAU_TX_CLEANUP Then Return SetError(7, $ReplaceError, _BrowserAutoUpdateTransactionMessage($TargetDir))
		DirRemove($TempDir, 1)
		_BrowserAutoUpdateCleanStaging()
		Return SetError(6, 0, _t("FailToExtractBrowserInstaller", "解压浏览器安装包失败。"))
	EndIf

	DirRemove($TempDir, 1)
	_BrowserAutoUpdateCleanStaging()
	Return $Pending[0]
EndFunc
