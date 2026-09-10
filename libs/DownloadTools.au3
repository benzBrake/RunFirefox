#include-once
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

Global $DT_hProgress = 0, $DT_idStatus = 0, $DT_idDetail = 0, $DT_idBar = 0, $DT_idCancel = 0
Global $DT_Cancelled = False, $DT_CanCancel = False, $DT_PreviousGuiMode = -1

Func _DownloadToolsHttpComError($oError)
EndFunc

Func _DownloadToolsHttpGetTextDiagnostic($Url, $UserAgent, $Accept, ByRef $Diagnostic, $Referer = "")
	$Diagnostic = "GET " & $Url & @CRLF
	Local $oError = ObjEvent("AutoIt.Error", "_DownloadToolsHttpComError")
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

Func _DownloadToolsHttpGetText($Url, $UserAgent = "", $Accept = "")
	Local $oError = ObjEvent("AutoIt.Error", "_DownloadToolsHttpComError")
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

Func _DownloadToolsShowDownloadProgress($TitleText, $StatusText, $DetailText, $Parent = 0, $CancelText = "Cancel")
	If $DT_hProgress Then _DownloadToolsCloseDownloadProgress()
	$DT_PreviousGuiMode = Opt("GUIOnEventMode", 0)
	$DT_Cancelled = 0
	$DT_CanCancel = 1
	$DT_hProgress = GUICreate($TitleText, 420, 135, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), -1, $Parent)
	GUISetOnEvent($GUI_EVENT_CLOSE, "_DownloadToolsCancelDownloadProgress")
	$DT_idStatus = GUICtrlCreateLabel($StatusText, 15, 15, 390, 20)
	$DT_idDetail = GUICtrlCreateLabel($DetailText, 15, 42, 390, 36)
	$DT_idBar = GUICtrlCreateProgress(15, 82, 390, 18)
	$DT_idCancel = GUICtrlCreateButton($CancelText, 170, 108, 80, 22)
	GUICtrlSetOnEvent(-1, "_DownloadToolsCancelDownloadProgress")
	GUISetState(@SW_SHOW, $DT_hProgress)
	WinSetOnTop($DT_hProgress, "", 1)
EndFunc   ;==>ShowDownloadProgress

Func _DownloadToolsUpdateDownloadProgress($StatusText, $DetailText, $Percent)
	If Not $DT_hProgress Then Return
	GUICtrlSetData($DT_idStatus, $StatusText)
	GUICtrlSetData($DT_idDetail, $DetailText)
	GUICtrlSetData($DT_idBar, $Percent)
EndFunc   ;==>UpdateDownloadProgress

Func _DownloadToolsSetDownloadProgressBusy($StatusText, $DetailText)
	If Not $DT_hProgress Then Return
	$DT_CanCancel = 0
	GUICtrlSetState($DT_idCancel, $GUI_DISABLE)
	_DownloadToolsUpdateDownloadProgress($StatusText, $DetailText, 100)
EndFunc   ;==>SetDownloadProgressBusy

Func _DownloadToolsCloseDownloadProgress()
	If Not $DT_hProgress Then Return
	GUIDelete($DT_hProgress)
	$DT_hProgress = 0
	$DT_CanCancel = 0
	If $DT_PreviousGuiMode <> -1 Then
		Opt("GUIOnEventMode", $DT_PreviousGuiMode)
		$DT_PreviousGuiMode = -1
	EndIf
EndFunc   ;==>CloseDownloadProgress

Func _DownloadToolsCancelDownloadProgress()
	If $DT_CanCancel Then $DT_Cancelled = 1
EndFunc   ;==>CancelDownloadProgress

Func _DownloadToolsIsDownloadProgressCancelled()
	Return $DT_Cancelled
EndFunc   ;==>IsDownloadProgressCancelled

Func _DownloadToolsPumpDownloadProgressEvents()
	If Not $DT_hProgress Then Return

	Local $aMsg
	Do
		$aMsg = GUIGetMsg(1)
		If Not IsArray($aMsg) Then Return
		If $aMsg[0] = 0 Then Return
		If $DT_CanCancel And $aMsg[1] = $DT_hProgress And ($aMsg[0] = $DT_idCancel Or $aMsg[0] = $GUI_EVENT_CLOSE) Then
			$DT_Cancelled = 1
			Return
		EndIf
	Until False
EndFunc   ;==>PumpDownloadProgressEvents

Func _DownloadToolsDownloadUrls($Urls, $Destination, $StatusText, $KnownProgressTemplate, $UnknownProgressTemplate, ByRef $TriedUrls)
	$TriedUrls = ""
	If Not IsArray($Urls) Or UBound($Urls) = 0 Then Return SetError(1, 0, False)

	Local $i, $Url, $hDownload, $DownloadedBytes, $TotalBytes, $Percent, $DetailText, $DownloadSuccessful = False
	For $i = 0 To UBound($Urls) - 1
		$Url = $Urls[$i]
		If $TriedUrls <> "" Then $TriedUrls &= @CRLF
		$TriedUrls &= $Url
		FileDelete($Destination)
		_DownloadToolsUpdateDownloadProgress($StatusText, $Url, 0)
		$hDownload = InetGet($Url, $Destination, 19, 1)
		If @error Or $hDownload = 0 Then ContinueLoop

		Do
			$DownloadedBytes = InetGetInfo($hDownload, 0)
			$TotalBytes = InetGetInfo($hDownload, 1)
			If $TotalBytes > 0 Then
				$Percent = Int($DownloadedBytes * 100 / $TotalBytes)
				If $Percent > 100 Then $Percent = 100
				$DetailText = StringReplace($KnownProgressTemplate, "{Downloaded}", _DownloadToolsFormatBytes($DownloadedBytes))
				$DetailText = StringReplace($DetailText, "{Total}", _DownloadToolsFormatBytes($TotalBytes))
			Else
				$Percent = Mod(Int($DownloadedBytes / 65536), 100)
				$DetailText = StringReplace($UnknownProgressTemplate, "%s", _DownloadToolsFormatBytes($DownloadedBytes))
			EndIf
			_DownloadToolsUpdateDownloadProgress($StatusText, $DetailText, $Percent)
			_DownloadToolsPumpDownloadProgressEvents()
			If _DownloadToolsIsDownloadProgressCancelled() Then ExitLoop
			Sleep(200)
		Until InetGetInfo($hDownload, 2)

		$DownloadSuccessful = InetGetInfo($hDownload, 3)
		InetClose($hDownload)
		If _DownloadToolsIsDownloadProgressCancelled() Then Return SetError(2, 0, False)
		If $DownloadSuccessful And FileExists($Destination) Then Return True
	Next

	Return SetError(3, 0, False)
EndFunc   ;==>DownloadUrls

Func _DownloadToolsRunArchiveExtraction($SevenZipExe, $Archive, $OutDir, $LogFile, $WorkingDir, $TimeoutMs = 900000, $AppendLog = False)
	Local $Redirect = " > "
	If $AppendLog Then $Redirect = " >> "
	Local $Command = @ComSpec & ' /c ""' & $SevenZipExe & '" x -y -bd -bb1 -o"' & $OutDir & '" "' & $Archive & '"' & $Redirect & '"' & $LogFile & '" 2>&1"'
	Local $Pid = Run($Command, $WorkingDir, @SW_HIDE)
	If @error Or $Pid = 0 Then Return 1

	Local $Timer = TimerInit()
	While ProcessExists($Pid)
		_DownloadToolsPumpDownloadProgressEvents()
		If TimerDiff($Timer) >= $TimeoutMs Then
			ProcessClose($Pid)
			FileWrite($LogFile, @CRLF & "Extraction timed out after " & Int($TimeoutMs / 1000) & " seconds." & @CRLF)
			Return 2
		EndIf
		Sleep(200)
	WEnd
	Return 0
EndFunc   ;==>RunArchiveExtraction

Func _DownloadToolsFormatBytes($Bytes)
	If $Bytes >= 1048576 Then Return Round($Bytes / 1048576, 1) & " MB"
	Return Round($Bytes / 1024) & " KB"
EndFunc   ;==>FormatBytes

Func _DownloadToolsGetUrlFileExtension($Url)
	Local $Path = StringRegExpReplace($Url, "[?#].*$", "")
	If StringRegExp($Path, "(?i)\.msi$") Then Return ".msi"
	If StringRegExp($Path, "(?i)\.zip$") Then Return ".zip"
	If StringRegExp($Path, "(?i)\.7z$") Then Return ".7z"
	Return ".exe"
EndFunc   ;==>GetUrlFileExtension

Func _DownloadToolsPrepareSevenZipTool($TempDir)
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

Func _DownloadToolsIsDirectoryNotEmpty($Dir)
	If Not FileExists($Dir) Then Return False
	Local $hSearch = FileFindFirstFile($Dir & "\*")
	If $hSearch = -1 Then Return False
	FileClose($hSearch)
	Return True
EndFunc   ;==>IsDirectoryNotEmpty

Func _DownloadToolsExtractNestedBrowserArchives($SevenZipExe, $RootDir, $TempDir, $Depth = 2)
	If $Depth <= 0 Then Return

	Local $ArchiveList = _DownloadToolsFindNestedBrowserArchives($RootDir)
	If Not IsArray($ArchiveList) Then Return

	Local $i, $Archive, $OutDir, $LogFile
	For $i = 1 To $ArchiveList[0]
		$Archive = $ArchiveList[$i]
		$OutDir = $RootDir & "\__nested_" & $Depth & "_" & $i
		$LogFile = $TempDir & "\nested_extract.log"
		If Not FileExists($OutDir) Then DirCreate($OutDir)
		_DownloadToolsRunArchiveExtraction($SevenZipExe, $Archive, $OutDir, $LogFile, $TempDir, 900000, True)
		_DownloadToolsExtractNestedBrowserArchives($SevenZipExe, $OutDir, $TempDir, $Depth - 1)
	Next
EndFunc   ;==>ExtractNestedBrowserArchives

Func _DownloadToolsFindNestedBrowserArchives($Dir, $Depth = 4)
	If $Depth <= 0 Then Return 0

	Local $Archives[1] = [0]
	_DownloadToolsCollectNestedBrowserArchives($Dir, $Depth, $Archives)
	If $Archives[0] = 0 Then Return 0
	Return $Archives
EndFunc   ;==>FindNestedBrowserArchives

Func _DownloadToolsCollectNestedBrowserArchives($Dir, $Depth, ByRef $Archives)
	If $Depth <= 0 Then Return
	; Browser payloads commonly contain extension/resource ZIPs. They are not
	; installer wrappers and extracting them can add minutes to a download.
	If StringRegExp($Dir, "(?i)\\(extensions|resources|locales|widevinecdm)(\\|$)") Then Return

	Local $hSearch = FileFindFirstFile($Dir & "\*")
	If $hSearch = -1 Then Return

	Local $Name, $Path, $Attrib
	While 1
		$Name = FileFindNextFile($hSearch)
		If @error Then ExitLoop
		$Path = $Dir & "\" & $Name
		$Attrib = FileGetAttrib($Path)
		If StringInStr($Attrib, "D") Then
			_DownloadToolsCollectNestedBrowserArchives($Path, $Depth - 1, $Archives)
		ElseIf StringRegExp($Name, "(?i)\.(7z|zip)$") Then
			$Archives[0] += 1
			ReDim $Archives[$Archives[0] + 1]
			$Archives[$Archives[0]] = $Path
		EndIf
	WEnd

	FileClose($hSearch)
EndFunc   ;==>CollectNestedBrowserArchives

Func _DownloadToolsFindBrowserExecutable($Dir, $ExecutableName, $Depth = 6)
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
			$Found = _DownloadToolsFindBrowserExecutable($Path, $ExecutableName, $Depth - 1)
			If $Found Then
				FileClose($hSearch)
				Return $Found
			EndIf
		EndIf
	WEnd

	FileClose($hSearch)
	Return ""
EndFunc   ;==>FindBrowserExecutable
