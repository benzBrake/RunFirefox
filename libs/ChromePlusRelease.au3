#include-once
#include "JSON.au3"
#include "DownloadTools.au3"

Global Const $ChromePlusReleaseBaseUrl = "https://github.com/Bush2021/chrome_plus/releases"
Global Const $ChromePlusManifestUrl = $ChromePlusReleaseBaseUrl & "/latest/download/update.json"
Global $ChromePlusReleaseInfoLoaded = False, $ChromePlusReleaseTag = "", $ChromePlusArchiveSize = 0, $ChromePlusArchiveSha256 = ""

Func IsValidChromePlusReleaseInfo($Version, $Size, $Sha256)
	Return IsString($Version) And StringRegExp($Version, "\A[0-9]+\.[0-9]+\.[0-9]+\z") And _
			IsInt($Size) And $Size > 0 And IsString($Sha256) And StringRegExp($Sha256, "(?i)\A[0-9a-f]{64}\z")
EndFunc

Func ParseChromePlusManifest($Text, ByRef $Version, ByRef $Size, ByRef $Sha256)
	Local $Manifest = Json_Decode($Text)
	If @error Or Not Json_IsObject($Manifest) Then Return False
	Local $ManifestVersion = Json_ObjGet($Manifest, "version")
	Local $ManifestSize = Json_ObjGet($Manifest, "size")
	Local $ManifestSha256 = Json_ObjGet($Manifest, "sha256")
	If Not IsValidChromePlusReleaseInfo($ManifestVersion, $ManifestSize, $ManifestSha256) Then Return False
	$Version = $ManifestVersion
	$Size = $ManifestSize
	$Sha256 = StringLower($ManifestSha256)
	Return True
EndFunc

Func SetChromePlusReleaseInfo($Version, $Size, $Sha256)
	$ChromePlusReleaseTag = $Version
	$ChromePlusArchiveSize = $Size
	$ChromePlusArchiveSha256 = StringLower($Sha256)
	$ChromePlusReleaseInfoLoaded = True
EndFunc

Func GetChromePlusReleaseInfo(ByRef $Version, ByRef $Size, ByRef $Sha256, ByRef $InstallLog)
	If $ChromePlusReleaseInfoLoaded Then
		$Version = $ChromePlusReleaseTag
		$Size = $ChromePlusArchiveSize
		$Sha256 = $ChromePlusArchiveSha256
		$InstallLog &= "Using cached official release info." & @CRLF
		Return True
	EndIf

	Local $Diagnostic = ""
	Local $Manifest = _DownloadToolsHttpGetTextDiagnostic($ChromePlusManifestUrl, "RunFirefox/" & $AppVersion, "application/json", $Diagnostic)
	$InstallLog &= $Diagnostic & @CRLF
	If Not ParseChromePlusManifest($Manifest, $Version, $Size, $Sha256) Then
		$InstallLog &= "Official update.json is missing or invalid." & @CRLF
		Return False
	EndIf
	SetChromePlusReleaseInfo($Version, $Size, $Sha256)
	Return True
EndFunc

Func WriteChromePlusReleaseInfoFile($OutputFile)
	FileDelete($OutputFile)
	Local $Version = "", $Size = 0, $Sha256 = "", $InstallLog = ""
	If Not GetChromePlusReleaseInfo($Version, $Size, $Sha256, $InstallLog) Then Return
	If Not IniWrite($OutputFile, "ChromePlus", "ReleaseTag", $Version) Then Return
	If Not IniWrite($OutputFile, "ChromePlus", "Size", $Size) Then Return
	If Not IniWrite($OutputFile, "ChromePlus", "Sha256", $Sha256) Then Return
	IniWrite($OutputFile, "ChromePlus", "Success", 1)
EndFunc

Func LoadChromePlusReleaseInfoFile($OutputFile)
	If IniRead($OutputFile, "ChromePlus", "Success", "0") <> "1" Then Return False
	Local $Version = IniRead($OutputFile, "ChromePlus", "ReleaseTag", "")
	Local $SizeText = IniRead($OutputFile, "ChromePlus", "Size", "")
	Local $Sha256 = IniRead($OutputFile, "ChromePlus", "Sha256", "")
	If Not StringRegExp($SizeText, "\A[0-9]+\z") Then Return False
	Local $Size = Int($SizeText, 2)
	If Not IsValidChromePlusReleaseInfo($Version, $Size, $Sha256) Then Return False
	SetChromePlusReleaseInfo($Version, $Size, $Sha256)
	Return True
EndFunc

Func BuildChromePlusArchiveUrlFromTag($Version)
	Return $ChromePlusReleaseBaseUrl & "/download/" & $Version & "/Chrome%2B%2B_v" & $Version & "_x86_x64_arm64.7z"
EndFunc

Func ChromePlusArchiveMatchesManifest($Path, $Size, $Sha256)
	Return FileExists($Path) And FileGetSize($Path) = $Size And _DownloadToolsFileMatchesSha256($Path, $Sha256)
EndFunc
