#include-once
#include <GUIConstantsEx.au3>
#include <ProgressConstants.au3>
#include <WindowsConstants.au3>

Global $DT_hProgress = 0, $DT_idStatus = 0, $DT_idDetail = 0, $DT_idBar = 0, $DT_idCancel = 0
Global $DT_Cancelled = False, $DT_CanCancel = False, $DT_PreviousGuiMode = -1
Global $DT_ProgressMarquee = False
Global $DT_CurlPath = "", $DT_CurlDetected = False
Global $DT_DownloadThreads = 3, $DT_ProxyType = "direct", $DT_ProxyServer = "", $DT_ProxyPort = 0

Func _DownloadToolsConfigure($DownloadThreads = 3, $ProxyType = "direct", $ProxyServer = "", $ProxyPort = 0)
	$DT_DownloadThreads = Int($DownloadThreads)
	If $DT_DownloadThreads < 1 Or $DT_DownloadThreads > 10 Then $DT_DownloadThreads = 3
	$DT_ProxyType = StringLower(StringStripWS($ProxyType, 3))
	If $DT_ProxyType <> "http" And $DT_ProxyType <> "socks5" Then $DT_ProxyType = "direct"
	$DT_ProxyServer = StringStripWS($ProxyServer, 3)
	$DT_ProxyPort = Int($ProxyPort)
	If $DT_ProxyType = "direct" Then HttpSetProxy(1)
EndFunc   ;==>Configure

Func _DownloadToolsFindCurl()
	If $DT_CurlDetected Then Return $DT_CurlPath
	$DT_CurlDetected = True
	Local $Candidates[3] = [@SystemDir & "\curl.exe", @WindowsDir & "\Sysnative\curl.exe", @ScriptDir & "\curl.exe"]
	For $Candidate In $Candidates
		If FileExists($Candidate) Then
			$DT_CurlPath = $Candidate
			ExitLoop
		EndIf
	Next
	If $DT_CurlPath = "" Then
		For $Directory In StringSplit(EnvGet("PATH"), ";", 2)
			$Directory = StringStripWS($Directory, 3)
			If StringLeft($Directory, 1) = '"' And StringRight($Directory, 1) = '"' Then $Directory = StringMid($Directory, 2, StringLen($Directory) - 2)
			If FileExists($Directory & "\curl.exe") Then
				$DT_CurlPath = $Directory & "\curl.exe"
				ExitLoop
			EndIf
		Next
	EndIf
	Return $DT_CurlPath
EndFunc   ;==>FindCurl

Func _DownloadToolsHasCurl()
	Return _DownloadToolsFindCurl() <> ""
EndFunc   ;==>HasCurl

Func _DownloadToolsUsesProxy()
	Return $DT_ProxyType <> "direct"
EndFunc   ;==>UsesProxy

Func _DownloadToolsCurlArgs()
	Local $Args = ' --location --fail --silent --show-error --connect-timeout 15'
	If $DT_ProxyType = "direct" Then $Args &= ' --noproxy "*"'
	If $DT_ProxyType = "http" Then $Args &= ' --proxy "http://' & $DT_ProxyServer & ':' & $DT_ProxyPort & '"'
	If $DT_ProxyType = "socks5" Then $Args &= ' --socks5-hostname "' & $DT_ProxyServer & ':' & $DT_ProxyPort & '"'
	Return $Args
EndFunc   ;==>CurlArgs

Func _DownloadToolsCurlCommand($ExtraArgs, $Url)
	Return '"' & _DownloadToolsFindCurl() & '"' & _DownloadToolsCurlArgs() & $ExtraArgs & ' "' & StringReplace($Url, '"', '') & '"'
EndFunc   ;==>CurlCommand

Func _DownloadToolsHttpComError($oError)
EndFunc

Func _DownloadToolsHttpGetTextDiagnostic($Url, $UserAgent, $Accept, ByRef $Diagnostic, $Referer = "")
	$Diagnostic = "GET " & $Url & @CRLF
	If _DownloadToolsHasCurl() Then
		Local $OutputFile = @TempDir & "\RunFirefox_CurlText_" & @AutoItPID & "_" & Random(1000, 999999, 1) & ".tmp"
		Local $ExtraArgs = ' --max-time 60 --output "' & $OutputFile & '"'
		If $UserAgent <> "" Then $ExtraArgs &= ' --user-agent "' & StringReplace($UserAgent, '"', '') & '"'
		If $Accept <> "" Then $ExtraArgs &= ' --header "Accept: ' & StringReplace($Accept, '"', '') & '"'
		If $Referer <> "" Then $ExtraArgs &= ' --referer "' & StringReplace($Referer, '"', '') & '"'
		Local $ExitCode = RunWait(_DownloadToolsCurlCommand($ExtraArgs, $Url), @TempDir, @SW_HIDE)
		Local $ResponseText = FileRead($OutputFile)
		FileDelete($OutputFile)
		$Diagnostic &= "curl exit code: " & $ExitCode & @CRLF
		$Diagnostic &= "Response length: " & StringLen($ResponseText) & @CRLF
		If $ExitCode <> 0 Then Return SetError(2, $ExitCode, "")
		Return $ResponseText
	EndIf
	If _DownloadToolsUsesProxy() Then
		$Diagnostic &= "curl.exe is required for proxy connections." & @CRLF
		Return SetError(4, 0, "")
	EndIf
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
	Local $Diagnostic = ""
	If _DownloadToolsHasCurl() Or _DownloadToolsUsesProxy() Then Return _DownloadToolsHttpGetTextDiagnostic($Url, $UserAgent, $Accept, $Diagnostic)
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

Func _DownloadToolsHttpPostText($Url, $Body, $UserAgent = "", $ContentType = "application/octet-stream")
	If _DownloadToolsHasCurl() Then
		Local $Token = @AutoItPID & "_" & Random(1000, 999999, 1)
		Local $RequestFile = @TempDir & "\RunFirefox_CurlPostRequest_" & $Token & ".tmp"
		Local $OutputFile = @TempDir & "\RunFirefox_CurlPostResponse_" & $Token & ".tmp"
		Local $RequestHandle = FileOpen($RequestFile, 2 + 256)
		If $RequestHandle = -1 Then Return SetError(1, 0, "")
		FileWrite($RequestHandle, $Body)
		FileClose($RequestHandle)
		Local $ExtraArgs = ' --max-time 60 --request POST --header "Content-Type: ' & StringReplace($ContentType, '"', '') & '" --data-binary "@' & $RequestFile & '" --output "' & $OutputFile & '"'
		If $UserAgent <> "" Then $ExtraArgs &= ' --user-agent "' & StringReplace($UserAgent, '"', '') & '"'
		Local $ExitCode = RunWait(_DownloadToolsCurlCommand($ExtraArgs, $Url), @TempDir, @SW_HIDE)
		Local $ResponseText = FileRead($OutputFile)
		FileDelete($RequestFile)
		FileDelete($OutputFile)
		If $ExitCode <> 0 Then Return SetError(2, $ExitCode, "")
		Return $ResponseText
	EndIf
	If _DownloadToolsUsesProxy() Then Return SetError(3, 0, "")
	Return SetError(4, 0, "")
EndFunc   ;==>HttpPostText

Func _DownloadToolsReadUrl($Url)
	If _DownloadToolsHasCurl() Then
		Local $OutputFile = @TempDir & "\RunFirefox_CurlRead_" & @AutoItPID & "_" & Random(1000, 999999, 1) & ".tmp"
		Local $ExitCode = RunWait(_DownloadToolsCurlCommand(' --max-time 60 --output "' & $OutputFile & '"', $Url), @TempDir, @SW_HIDE)
		If $ExitCode <> 0 Then
			FileDelete($OutputFile)
			Return SetError(1, $ExitCode, Binary(""))
		EndIf
		Local $FileHandle = FileOpen($OutputFile, 16)
		Local $Data = FileRead($FileHandle)
		FileClose($FileHandle)
		FileDelete($OutputFile)
		Return $Data
	EndIf
	If _DownloadToolsUsesProxy() Then Return SetError(2, 0, Binary(""))
	Return InetRead($Url, 1)
EndFunc   ;==>ReadUrl

Func _DownloadToolsStartUrlToFile($Url, $Destination, ByRef $Kind)
	FileDelete($Destination)
	If _DownloadToolsHasCurl() Then
		$Kind = "curl"
		Return Run(_DownloadToolsCurlCommand(' --max-time 60 --output "' & $Destination & '"', $Url), @TempDir, @SW_HIDE)
	EndIf
	If _DownloadToolsUsesProxy() Then Return SetError(1, 0, 0)
	$Kind = "inet"
	Return InetGet($Url, $Destination, 1, 1)
EndFunc   ;==>StartUrlToFile

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
	If Not $DT_ProgressMarquee Then GUICtrlSetData($DT_idBar, $Percent)
EndFunc   ;==>UpdateDownloadProgress

Func _DownloadToolsSetDownloadProgressMarquee($Enabled)
	If Not $DT_hProgress Or $DT_ProgressMarquee = $Enabled Then Return
	$DT_ProgressMarquee = $Enabled
	If $Enabled Then
		GUICtrlSetStyle($DT_idBar, $PBS_MARQUEE)
		GUICtrlSendMsg($DT_idBar, $PBM_SETMARQUEE, 1, 35)
	Else
		GUICtrlSendMsg($DT_idBar, $PBM_SETMARQUEE, 0, 0)
		GUICtrlSetStyle($DT_idBar, 0)
		GUICtrlSetData($DT_idBar, 0)
	EndIf
EndFunc   ;==>SetDownloadProgressMarquee

Func _DownloadToolsSetDownloadProgressBusy($StatusText, $DetailText)
	If Not $DT_hProgress Then Return
	$DT_CanCancel = 0
	GUICtrlSetState($DT_idCancel, $GUI_DISABLE)
	_DownloadToolsSetDownloadProgressMarquee(False)
	_DownloadToolsUpdateDownloadProgress($StatusText, $DetailText, 100)
EndFunc   ;==>SetDownloadProgressBusy

Func _DownloadToolsCloseDownloadProgress()
	If Not $DT_hProgress Then Return
	GUIDelete($DT_hProgress)
	$DT_hProgress = 0
	$DT_ProgressMarquee = False
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

Func _DownloadToolsCurlProbeRange($Url, ByRef $TotalBytes)
	$TotalBytes = 0
	If Not _DownloadToolsHasCurl() Then Return False
	Local $Token = @AutoItPID & "_" & Random(1000, 999999, 1)
	Local $HeaderFile = @TempDir & "\RunFirefox_CurlHeaders_" & $Token & ".tmp"
	Local $ProbeFile = @TempDir & "\RunFirefox_CurlProbe_" & $Token & ".tmp"
	Local $Args = ' --max-time 30 --range 0-0 --dump-header "' & $HeaderFile & '" --output "' & $ProbeFile & '"'
	Local $ExitCode = RunWait(_DownloadToolsCurlCommand($Args, $Url), @TempDir, @SW_HIDE)
	Local $Headers = FileRead($HeaderFile)
	FileDelete($HeaderFile)
	FileDelete($ProbeFile)
	If $ExitCode <> 0 Or Not StringRegExp($Headers, "(?im)^HTTP/[^\r\n]+\s206(?:\s|$)") Then Return False
	Local $Matches = StringRegExp($Headers, "(?im)^Content-Range:\s*bytes\s+\d+-\d+/(\d+)\s*$", 3)
	If @error Or UBound($Matches) = 0 Then Return False
	$TotalBytes = Number($Matches[UBound($Matches) - 1])
	Return $TotalBytes > 1
EndFunc   ;==>CurlProbeRange

Func _DownloadToolsStopProcesses(ByRef $Processes)
	For $i = 0 To UBound($Processes) - 1
		If $Processes[$i] And ProcessExists($Processes[$i]) Then ProcessClose($Processes[$i])
	Next
EndFunc   ;==>StopProcesses

Func _DownloadToolsDeleteParts(ByRef $Parts)
	For $Part In $Parts
		If $Part <> "" Then FileDelete($Part)
	Next
EndFunc   ;==>DeleteParts

Func _DownloadToolsMergeParts(ByRef $Parts, $Destination)
	Local $Output = FileOpen($Destination, 18)
	If $Output = -1 Then Return False
	For $Part In $Parts
		Local $Input = FileOpen($Part, 16)
		If $Input = -1 Then
			FileClose($Output)
			Return False
		EndIf
		While True
			Local $Chunk = FileRead($Input, 1048576)
			If @error Or BinaryLen($Chunk) = 0 Then ExitLoop
			FileWrite($Output, $Chunk)
		WEnd
		FileClose($Input)
	Next
	FileClose($Output)
	Return True
EndFunc   ;==>MergeParts

Func _DownloadToolsCurlSegmentedDownload($Url, $Destination, $StatusText, $KnownProgressTemplate, $TimeoutMs)
	Local $TotalBytes = 0
	If $DT_DownloadThreads <= 1 Or Not _DownloadToolsCurlProbeRange($Url, $TotalBytes) Then Return SetError(1, 0, False)
	Local $ThreadCount = $DT_DownloadThreads
	If $TotalBytes < $ThreadCount Then $ThreadCount = Int($TotalBytes)
	Local $Processes[$ThreadCount], $Parts[$ThreadCount], $Expected[$ThreadCount]
	Local $SegmentSize = Ceiling($TotalBytes / $ThreadCount)
	For $i = 0 To $ThreadCount - 1
		Local $StartByte = $i * $SegmentSize
		Local $EndByte = $StartByte + $SegmentSize - 1
		If $EndByte >= $TotalBytes Then $EndByte = $TotalBytes - 1
		$Expected[$i] = $EndByte - $StartByte + 1
		$Parts[$i] = $Destination & ".part" & $i
		FileDelete($Parts[$i])
		Local $Args = ' --range ' & $StartByte & '-' & $EndByte & ' --output "' & $Parts[$i] & '"'
		$Processes[$i] = Run(_DownloadToolsCurlCommand($Args, $Url), @TempDir, @SW_HIDE)
		If @error Or Not $Processes[$i] Then
			_DownloadToolsStopProcesses($Processes)
			_DownloadToolsDeleteParts($Parts)
			Return SetError(2, 0, False)
		EndIf
	Next

	Local $Timer = TimerInit(), $Running, $DownloadedBytes, $DetailText, $Percent
	Do
		$Running = False
		$DownloadedBytes = 0
		For $i = 0 To $ThreadCount - 1
			If ProcessExists($Processes[$i]) Then $Running = True
			If FileExists($Parts[$i]) Then $DownloadedBytes += FileGetSize($Parts[$i])
		Next
		If $DownloadedBytes > $TotalBytes Then $DownloadedBytes = $TotalBytes
		$Percent = Int($DownloadedBytes * 100 / $TotalBytes)
		$DetailText = StringReplace($KnownProgressTemplate, "{Downloaded}", _DownloadToolsFormatBytes($DownloadedBytes))
		$DetailText = StringReplace($DetailText, "{Total}", _DownloadToolsFormatBytes($TotalBytes))
		_DownloadToolsUpdateDownloadProgress($StatusText, $DetailText, $Percent)
		_DownloadToolsPumpDownloadProgressEvents()
		If _DownloadToolsIsDownloadProgressCancelled() Or TimerDiff($Timer) >= $TimeoutMs Then
			_DownloadToolsStopProcesses($Processes)
			_DownloadToolsDeleteParts($Parts)
			Return SetError(3, 0, False)
		EndIf
		If $Running Then Sleep(200)
	Until Not $Running

	For $i = 0 To $ThreadCount - 1
		If Not FileExists($Parts[$i]) Or FileGetSize($Parts[$i]) <> $Expected[$i] Then
			_DownloadToolsDeleteParts($Parts)
			Return SetError(4, 0, False)
		EndIf
	Next
	FileDelete($Destination)
	Local $Merged = _DownloadToolsMergeParts($Parts, $Destination)
	_DownloadToolsDeleteParts($Parts)
	If Not $Merged Or Not FileExists($Destination) Or FileGetSize($Destination) <> $TotalBytes Then
		FileDelete($Destination)
		Return SetError(5, 0, False)
	EndIf
	Return True
EndFunc   ;==>CurlSegmentedDownload

Func _DownloadToolsCurlSingleDownload($Url, $Destination, $StatusText, $KnownProgressTemplate, $UnknownProgressTemplate, $TimeoutMs)
	FileDelete($Destination)
	Local $Process = Run(_DownloadToolsCurlCommand(' --output "' & $Destination & '"', $Url), @TempDir, @SW_HIDE)
	If @error Or Not $Process Then Return False
	Local $Timer = TimerInit(), $DownloadedBytes, $DetailText
	While ProcessExists($Process)
		$DownloadedBytes = 0
		If FileExists($Destination) Then $DownloadedBytes = FileGetSize($Destination)
		$DetailText = StringReplace($UnknownProgressTemplate, "%s", _DownloadToolsFormatBytes($DownloadedBytes))
		_DownloadToolsUpdateDownloadProgress($StatusText, $DetailText, Mod(Int($DownloadedBytes / 65536), 100))
		_DownloadToolsPumpDownloadProgressEvents()
		If _DownloadToolsIsDownloadProgressCancelled() Or TimerDiff($Timer) >= $TimeoutMs Then
			ProcessClose($Process)
			FileDelete($Destination)
			Return False
		EndIf
		Sleep(200)
	WEnd
	Return FileExists($Destination) And FileGetSize($Destination) > 0
EndFunc   ;==>CurlSingleDownload

Func _DownloadToolsDownloadUrls($Urls, $Destination, $StatusText, $KnownProgressTemplate, $UnknownProgressTemplate, ByRef $TriedUrls, $TimeoutMs = 600000)
	$TriedUrls = ""
	If Not IsArray($Urls) Or UBound($Urls) = 0 Then Return SetError(1, 0, False)

	Local $i, $Url, $hDownload, $DownloadedBytes, $TotalBytes, $Percent, $DetailText, $DownloadSuccessful = False, $Timer
	For $i = 0 To UBound($Urls) - 1
		$Url = $Urls[$i]
		If $TriedUrls <> "" Then $TriedUrls &= @CRLF
		$TriedUrls &= $Url
		FileDelete($Destination)
		_DownloadToolsUpdateDownloadProgress($StatusText, $Url, 0)
		If _DownloadToolsHasCurl() Then
			_DownloadToolsSetDownloadProgressMarquee(True)
			If $DT_DownloadThreads > 1 And _DownloadToolsCurlSegmentedDownload($Url, $Destination, $StatusText, $KnownProgressTemplate, $TimeoutMs) Then Return True
			If _DownloadToolsIsDownloadProgressCancelled() Then Return SetError(2, 0, False)
			If _DownloadToolsCurlSingleDownload($Url, $Destination, $StatusText, $KnownProgressTemplate, $UnknownProgressTemplate, $TimeoutMs) Then Return True
			If _DownloadToolsIsDownloadProgressCancelled() Then Return SetError(2, 0, False)
			ContinueLoop
		EndIf
		_DownloadToolsSetDownloadProgressMarquee(False)
		If _DownloadToolsUsesProxy() Then Return SetError(4, 0, False)
		$hDownload = InetGet($Url, $Destination, 19, 1)
		If @error Or $hDownload = 0 Then ContinueLoop
		$Timer = TimerInit()

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
			; An unreachable source must not stall the whole download flow, so a
			; single URL never keeps the loop busy beyond the overall timeout.
			If TimerDiff($Timer) >= $TimeoutMs Then ExitLoop
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
