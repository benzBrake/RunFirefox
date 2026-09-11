#include-once
#include "DownloadTools.au3"

; Portable browser auto update managed by RunFirefox itself.
; The update package is downloaded to a staging directory first and applied on
; the next RunFirefox launch, before the browser process starts (like Firefox).
Global $BAU_StagingDir = ""

Func _BrowserAutoUpdateConfigure($StagingDir)
	$BAU_StagingDir = $StagingDir
EndFunc

; Only browsers whose latest version + download url can be resolved reliably
; are supported for now. Extend this list to bring more Chromiums on board.
Func _BrowserAutoUpdateIsSupported($BrowserType)
	Local $Normalized = NormalizeBrowserType($BrowserType)
	Return $Normalized = $BrowserChrome Or $Normalized = $BrowserBrave Or $Normalized = $BrowserWhale
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

; Downloads the update package atomically: *.part first, integrity check,
; then rename + metadata. Returns True when the update is staged.
Func _BrowserAutoUpdateStageUpdate($BrowserType, $Channel, $Version, $Urls, ByRef $TriedUrlsOut, $Parent = 0)
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
	Local $DownloadResult = _DownloadToolsDownloadUrls($Urls, $PartPath, _t("DownloadingBrowser", "正在下载浏览器 ..."), _t("BrowserDownloadProgressKnown", "已下载 {Downloaded} / {Total}"), _t("BrowserDownloadProgressUnknown", "已下载 %s"), $TriedUrls)
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
Func _BrowserAutoUpdateApplyPending($BrowserPath, $BrowserType, $Parent = 0)
	Local $Pending = _BrowserAutoUpdateGetPendingUpdate()
	If Not IsArray($Pending) Then Return SetError(1, 0, "")

	Local $LocalVersion = _BrowserAutoUpdateGetLocalVersion($BrowserPath, $BrowserType)
	If Not _BrowserAutoUpdateVersionIsNewer($Pending[0], $LocalVersion) Then
		; Already up to date (or newer); drop the stale package.
		_BrowserAutoUpdateCleanStaging()
		Return SetError(1, 0, "")
	EndIf

	Local $TargetDir = ""
	Local $TargetFile = ""
	SplitPath(FullPath($BrowserPath), $TargetDir, $TargetFile)
	If $TargetDir = "" Or $TargetDir = "." Then $TargetDir = @ScriptDir

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
	If $ExtractResult = 0 Then _DownloadToolsExtractNestedBrowserArchives($SevenZipExe, $ExtractDir, $TempDir)
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
	; DirCopy merges into the existing browser directory so files not shipped
	; with the update (chrome++.ini, version.dll, ...) are preserved.
	If Not DirCopy($ExtractedDir, $TargetDir, 1) Or Not FileExists($TargetDir & "\" & $ExtractedFile) Then
		DirRemove($TempDir, 1)
		_BrowserAutoUpdateCleanStaging()
		Return SetError(6, 0, _t("FailToExtractBrowserInstaller", "解压浏览器安装包失败。"))
	EndIf

	DirRemove($TempDir, 1)
	_BrowserAutoUpdateCleanStaging()
	Return $Pending[0]
EndFunc
