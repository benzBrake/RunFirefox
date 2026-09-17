#include-once
#include "DownloadTools.au3"
#include "JSON.au3"
#include "UpgradeHelper.au3"

Global $BD_AppVersion = "", $BD_Locale = "", $BD_GithubDirectMirror = "", $BD_GithubJsDelivrMirror = ""
Global $BD_LoadHandle = 0, $BD_LoadFile = "", $BD_LoadBrowserType = "", $BD_LoadChannel = "", $BD_LoadOs = "", $BD_LoadKind = "", $BD_LoadBraveUrls = 0, $BD_LoadBraveIndex = 0, $BD_LoadVivaldiUrls = 0, $BD_LoadVivaldiIndex = 0, $BD_LoadOperaUrls = 0, $BD_LoadOperaIndex = 0, $BD_LoadWhaleUrls = 0, $BD_LoadWhaleIndex = 0
Global $BD_LoadHeliumUrls = 0, $BD_LoadHeliumIndex = 0
Global Const $FirefoxVersionUrl = "https://product-details.mozilla.org/1.0/firefox_versions.json"
Global Const $ChromeUpdateUrl = "https://tools.google.com/service/update2"
Global Const $ChromeUpdateUserAgent = "Google Update/1.3.32.7;winhttp;cup-ecdsa"
Global Const $ZenUpdateBaseUrl = "https://updates.zen-browser.app/updates/browser/WINNT_x86_64-msvc-x64"
Global Const $FloorpRepo = "Floorp-Projects/Floorp"
Global Const $FloorpLatestReleaseUrl = "https://github.com/" & $FloorpRepo & "/releases/latest"
Global Const $FloorpWindowsX64Asset = "floorp-windows-x86_64.installer.exe"
Global Const $WaterfoxRepo = "BrowserWorks/Waterfox"
Global Const $WaterfoxLatestReleaseApiUrl = "https://api.github.com/repos/" & $WaterfoxRepo & "/releases/latest"
Global Const $WaterfoxDownloadPageUrl = "https://www.waterfox.com/download/"
Global Const $LibreWolfLatestReleaseApiUrl = "https://librewolf.dev/api/v1/repos/librewolf/bsys6/releases/latest"
Global Const $LibreWolfDownloadPageUrl = "https://librewolf.net/installation/windows/"
Global Const $TurboRepo = "tbrowser/Turbo-Browser"
Global Const $TurboDownloadInfoUrl = "https://tbrowser.cn/update/update.js"
Global Const $TurboLatestReleaseApiUrl = "https://api.github.com/repos/" & $TurboRepo & "/releases/latest"
Global Const $HeliumRepo = "imputnet/helium-windows"
Global Const $HeliumArchiveRawUrl = "https://raw.githubusercontent.com/benzBrake/BrowserArchive/refs/heads/main/data/helium.json"
Global Const $HeliumLatestReleaseUrl = "https://github.com/" & $HeliumRepo & "/releases/latest"
Global Const $HeliumLatestReleaseApiUrl = "https://api.github.com/repos/" & $HeliumRepo & "/releases/latest"
Global Const $WhaleStandaloneX86Url = "https://installer-whale.pstatic.net/downloads/sa_installers/WhaleSetupX86.exe"
Global Const $WhaleStandaloneX64Url = "https://installer-whale.pstatic.net/downloads/sa_installers/WhaleSetupX64.exe"
Global Const $WhaleLatestVersionUrl = "https://cv.whale.naver.com/version/latest_version"
Global Const $WhaleArchiveRepo = "benzBrake/BrowserArchive"
Global Const $WhaleArchiveDataPath = "data/whale.json"
Global Const $WhaleArchiveRawUrl = "https://github.com/" & $WhaleArchiveRepo & "/raw/refs/heads/main/" & $WhaleArchiveDataPath
Global Const $CentBrowserDownloadPageUrl = "https://www.centbrowser.com/"
Global Const $VivaldiDownloadPageUrl = "https://vivaldi.com/download/"
Global Const $VivaldiArchiveRepo = "benzBrake/BrowserArchive"
Global Const $VivaldiArchiveDataPath = "data/vivaldi.json"
Global Const $VivaldiArchiveRawUrl = "https://github.com/" & $VivaldiArchiveRepo & "/raw/refs/heads/main/" & $VivaldiArchiveDataPath
Global Const $VivaldiUpdateOfficialBaseUrl = "https://update.vivaldi.com/update/1.0/"
Global Const $VivaldiDownloadOfficialBaseUrl = "https://downloads.vivaldi.com/"
Global Const $OperaArchiveRawUrl = "https://raw.githubusercontent.com/benzBrake/BrowserArchive/refs/heads/main/data/opera.json"
Global Const $OperaVersionApiOfficialBaseUrl = "https://autoupdate.geo.opera.com/api/verify?"
Global Const $OperaVersionApiQueryVersion = "0.0.0.0"
Global Const $OperaDesktopFtpBaseUrl = "https://get.opera.com/ftp/pub/"
Global Const $OperaDownloadPageUrl = "https://www.opera.com/download"
Global Const $CocCocArchiveRawUrl = "https://raw.githubusercontent.com/benzBrake/BrowserArchive/refs/heads/main/data/coccoc.json"
Global Const $BraveRepo = "brave/brave-browser"
Global Const $BraveLatestReleaseApiUrl = "https://api.github.com/repos/" & $BraveRepo & "/releases/latest"
Global Const $BraveArchiveRepo = "benzBrake/BrowserArchive"
Global Const $BraveArchiveDataPath = "data/brave.json"
Global Const $BraveArchiveRawUrl = "https://github.com/" & $BraveArchiveRepo & "/raw/refs/heads/main/" & $BraveArchiveDataPath
Global Const $UngoogledChromiumRepo = "ungoogled-software/ungoogled-chromium-windows"
Global Const $UngoogledChromiumGitCodeTagsUrl = "https://gitcode.com/gh_mirrors/un/ungoogled-chromium-windows/tags"
Global Const $UngoogledChromiumLatestReleaseApiUrl = "https://api.github.com/repos/" & $UngoogledChromiumRepo & "/releases/latest"
Global Const $BraveVersionDataOfficialBaseUrl = "https://versions.brave.com/latest/"
Global Const $BraveVersionDataOfficialUrl = $BraveVersionDataOfficialBaseUrl & "brave-versions.json"
Global Const $XunleiBrowserDownloadPageUrl = "https://x.xunlei.com/"
Global Const $XunleiVersionDataUrl = "https://static-x.xunlei.com/x-xunlei-com/production/_nuxt/qrcanvas-vue.esm.8cc019a3.js"
Global Const $ChromeStableStandaloneX64Url = "https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe"
Global Const $ChromeBetaStandaloneX64Url = "https://dl.google.com/chrome/install/beta/ChromeBetaStandaloneSetup64.exe"
Global Const $ChromeDevStandaloneX64Url = "https://dl.google.com/chrome/install/dev/ChromeDevStandaloneSetup64.exe"
Global Const $ChromeCanaryDownloadPageUrl = "https://www.google.com/chrome/canary/"

Global $FirefoxVersionsObj = 0
Global $ZenReleaseUpdateXml = "", $ZenTwilightUpdateXml = ""
Global $FloorpReleaseInfoLoaded = False, $FloorpReleaseTag = ""
Global $WaterfoxReleaseInfoLoaded = False, $WaterfoxReleaseVersion = ""
Global $LibreWolfReleaseInfoLoaded = False, $LibreWolfReleaseVersion = "", $LibreWolfDownloadUrl = ""
Global $TurboReleaseInfoLoaded = False, $TurboReleaseVersion = "", $TurboAssetName = "", $TurboDownloadUrl = "", $TurboGithubDownloadUrl = ""
Global $HeliumReleaseInfoLoaded = False, $HeliumReleaseTag = ""
Global $CentReleaseInfoLoaded = False, $CentReleaseVersion = "", $CentDownloadUrl = ""
Global $VivaldiStableReleaseInfoLoaded = False, $VivaldiStableReleaseVersion = "", $VivaldiStableDownloadUrl = ""
Global $VivaldiSnapshotReleaseInfoLoaded = False, $VivaldiSnapshotReleaseVersion = "", $VivaldiSnapshotDownloadUrl = ""
Global $OperaStableInfoLoaded = False, $OperaStableVersion = "", $OperaDevInfoLoaded = False, $OperaDevVersion = ""
Global $CocCocReleaseInfoLoaded = False, $CocCocReleaseVersion = "", $CocCocDownloadFilename = "", $CocCocDownloadUrl = "", $CocCocDownloadSha256 = ""
Global $WhaleReleaseInfoLoaded = False, $WhaleReleaseVersion = "", $WhaleDownloadX86Url = "", $WhaleDownloadX64Url = ""
Global $BraveReleaseInfoLoaded = False, $BraveReleaseTag = "", $BraveDownloadUrl = "", $BraveReleaseChannel = ""
Global $XunleiReleaseInfoLoaded = False, $XunleiDownloadUrl = ""
Global $UngoogledChromiumReleaseInfoLoaded = False, $UngoogledChromiumReleaseTag = ""
Global $ChromeStableVersion = "", $ChromeStableDownloadUrl = "", $ChromeBetaVersion = "", $ChromeBetaDownloadUrl = "", $ChromeDevVersion = "", $ChromeDevDownloadUrl = "", $ChromeCanaryVersion = "", $ChromeCanaryDownloadUrl = ""
Func _BrowserDownloadConfigure($AppVersion, $Locale, $GithubDirectMirror, $GithubJsDelivrMirror)
    $BD_AppVersion = $AppVersion
    $BD_Locale = $Locale
	$BD_GithubDirectMirror = $GithubDirectMirror
	$BD_GithubJsDelivrMirror = $GithubJsDelivrMirror
	_DownloadToolsSetRouting($Locale, $GithubDirectMirror, $GithubJsDelivrMirror, $DT_GithubApiMirror)
EndFunc

Func _BrowserDownloadIsSupported($BrowserType)
	Local $Normalized = NormalizeBrowserType($BrowserType)
	Return $Normalized <> $BrowserOtherFirefox And $Normalized <> $BrowserOtherChromium
EndFunc

Func _BrowserDownloadGetLatestVersion($BrowserType, $Channel)
	$BrowserType = NormalizeBrowserType($BrowserType)
	If Not _BrowserDownloadIsSupported($BrowserType) Then Return ""
	$Channel = _BrowserDownloadNormalizeChannel($BrowserType, $Channel)

	If $BrowserType = $BrowserZen Then Return _BrowserDownloadGetLatestZenVersion($Channel)
	If $BrowserType = $BrowserFloorp Then Return _BrowserDownloadGetLatestFloorpVersion()
	If $BrowserType = $BrowserWaterfox Then Return _BrowserDownloadGetLatestWaterfoxVersion()
	If $BrowserType = $BrowserLibreWolf Then Return _BrowserDownloadGetLatestLibreWolfVersion()
	If $BrowserType = $BrowserTurbo Then Return _BrowserDownloadGetLatestTurboVersion()
	If $BrowserType = $BrowserHelium Then Return _BrowserDownloadGetLatestHeliumVersion()
	If $BrowserType = $BrowserCent Then Return _BrowserDownloadGetLatestCentVersion()
	If $BrowserType = $BrowserVivaldi Then Return _BrowserDownloadGetLatestVivaldiVersion($Channel)
	If $BrowserType = $BrowserCocCoc Then Return _BrowserDownloadGetLatestCocCocVersion()
	If $BrowserType = $BrowserWhale Then Return _BrowserDownloadGetLatestWhaleVersion()
	If $BrowserType = $BrowserBrave Then Return _BrowserDownloadGetLatestBraveVersion($Channel)
	If $BrowserType = $BrowserXunlei Then Return ""
	If $BrowserType = $BrowserUngoogledChromium Then Return _BrowserDownloadGetLatestUngoogledChromiumVersion()
	If $BrowserType = $BrowserOpera Then Return _BrowserDownloadGetLatestOperaVersion($Channel)
	If IsChromeBrowser($BrowserType) Then Return _BrowserDownloadGetChromeVersionCache($Channel)
	Return _BrowserDownloadGetLatestFirefoxVersion($Channel)
EndFunc

Func _BrowserDownloadIsVersionCached($BrowserType, $Channel, $Os = "win64")
	$BrowserType = NormalizeBrowserType($BrowserType)
	If Not _BrowserDownloadIsSupported($BrowserType) Then Return False
	$Channel = _BrowserDownloadNormalizeChannel($BrowserType, $Channel)
	If $BrowserType = $BrowserTurbo Then Return $TurboReleaseInfoLoaded
	If $BrowserType = $BrowserHelium Then Return $HeliumReleaseInfoLoaded
	If $BrowserType = $BrowserCent Then Return $CentReleaseInfoLoaded
	If $BrowserType = $BrowserVivaldi Then Return _BrowserDownloadIsVivaldiInfoLoaded($Channel)
	If $BrowserType = $BrowserCocCoc Then Return $Os = "win64" And $CocCocReleaseInfoLoaded
	If $BrowserType = $BrowserWhale Then Return $WhaleReleaseInfoLoaded
	If $BrowserType = $BrowserBrave Then Return $BraveReleaseInfoLoaded And StringLower($BraveReleaseChannel) = _BrowserDownloadNormalizeBraveChannel($Channel)
	If $BrowserType = $BrowserXunlei Then Return $XunleiReleaseInfoLoaded
	If $BrowserType = $BrowserUngoogledChromium Then Return $UngoogledChromiumReleaseInfoLoaded
	If $BrowserType = $BrowserOpera Then Return _BrowserDownloadIsOperaInfoLoaded($Channel)
	If $BrowserType = $BrowserZen Then Return _BrowserDownloadGetZenUpdateXmlCache($Channel) <> ""
	If $BrowserType = $BrowserFloorp Then Return $FloorpReleaseInfoLoaded
	If $BrowserType = $BrowserWaterfox Then Return $WaterfoxReleaseInfoLoaded
	If $BrowserType = $BrowserLibreWolf Then Return $LibreWolfReleaseInfoLoaded
	If IsChromeBrowser($BrowserType) Then Return _BrowserDownloadGetChromeVersionCache($Channel) <> ""
	Return IsObj($FirefoxVersionsObj)
EndFunc

Func _BrowserDownloadHasFallback($BrowserType, $Channel)
	If Not _BrowserDownloadIsSupported($BrowserType) Then Return False
	Switch NormalizeBrowserType($BrowserType)
		Case $BrowserFirefox, $BrowserZen, $BrowserFloorp, $BrowserWaterfox, $BrowserTurbo, $BrowserHelium, $BrowserWhale, $BrowserVivaldi, $BrowserOpera, $BrowserCocCoc, $BrowserBrave, $BrowserXunlei, $BrowserUngoogledChromium
			Return True
		Case $BrowserChrome
			Return _BrowserDownloadNormalizeChromeChannel($Channel) <> "canary"
	EndSwitch
	Return False
EndFunc

Func _BrowserDownloadGetPageUrl($BrowserType, $Channel)
	If Not _BrowserDownloadIsSupported($BrowserType) Then Return ""
	Switch NormalizeBrowserType($BrowserType)
		Case $BrowserLibreWolf
			Return $LibreWolfDownloadPageUrl
		Case $BrowserCent
			Return $CentBrowserDownloadPageUrl
		Case $BrowserOpera
			Return $OperaDownloadPageUrl
		Case $BrowserXunlei
			Return $XunleiBrowserDownloadPageUrl
		Case $BrowserChrome
			If _BrowserDownloadNormalizeChromeChannel($Channel) = "canary" Then Return $ChromeCanaryDownloadPageUrl
	EndSwitch
	Return ""
EndFunc

Func _BrowserDownloadIsVersionLoadActive($BrowserType, $Channel, $Os = "win64")
	$BrowserType = NormalizeBrowserType($BrowserType)
	If Not _BrowserDownloadIsSupported($BrowserType) Then Return False
	If $BrowserType = $BrowserCocCoc And $Os <> "win64" Then Return False
	$Channel = _BrowserDownloadNormalizeChannel($BrowserType, $Channel)
	Return $BD_LoadHandle <> 0 And $BD_LoadBrowserType = $BrowserType And $BD_LoadChannel = $Channel And $BD_LoadOs = $Os
EndFunc

Func _BrowserDownloadStartVersionUrl($Url)
	Return _DownloadToolsStartUrlToFile($Url, $BD_LoadFile, $BD_LoadKind)
EndFunc

Func _BrowserDownloadStartVersionLoad($BrowserType, $Channel, $Os = "win64")
	$BrowserType = NormalizeBrowserType($BrowserType)
	If Not _BrowserDownloadIsSupported($BrowserType) Then Return False
	If $BrowserType = $BrowserCocCoc And $Os <> "win64" Then Return False
	$Channel = _BrowserDownloadNormalizeChannel($BrowserType, $Channel)
	If _BrowserDownloadIsVersionLoadActive($BrowserType, $Channel, $Os) Then Return True
	_BrowserDownloadCancelVersionLoad()

	$BD_LoadBrowserType = $BrowserType
	$BD_LoadChannel = $Channel
	$BD_LoadOs = $Os
	$BD_LoadFile = @TempDir & "\\RunFirefox_BrowserVersion_" & @AutoItPID & ".tmp"
	FileDelete($BD_LoadFile)

	If $BrowserType = $BrowserTurbo Then
		$BD_LoadHandle = _BrowserDownloadStartVersionUrl($TurboDownloadInfoUrl)
	ElseIf $BrowserType = $BrowserHelium Then
		$BD_LoadHeliumUrls = _BrowserDownloadGetHeliumVersionUrls()
		$BD_LoadHeliumIndex = 0
		While $BD_LoadHeliumIndex < UBound($BD_LoadHeliumUrls) And Not $BD_LoadHandle
			$BD_LoadHandle = _BrowserDownloadStartVersionUrl($BD_LoadHeliumUrls[$BD_LoadHeliumIndex])
			If Not $BD_LoadHandle Then $BD_LoadHeliumIndex += 1
		WEnd
	ElseIf $BrowserType = $BrowserCent Then
		$BD_LoadHandle = _BrowserDownloadStartVersionUrl($CentBrowserDownloadPageUrl)
	ElseIf $BrowserType = $BrowserVivaldi Then
		$BD_LoadVivaldiUrls = _BrowserDownloadGetVivaldiUpdateUrls($Channel)
		$BD_LoadVivaldiIndex = 0
		While $BD_LoadVivaldiIndex < UBound($BD_LoadVivaldiUrls) And Not $BD_LoadHandle
			$BD_LoadHandle = _BrowserDownloadStartVersionUrl($BD_LoadVivaldiUrls[$BD_LoadVivaldiIndex])
			If Not $BD_LoadHandle Then $BD_LoadVivaldiIndex += 1
		WEnd
	ElseIf $BrowserType = $BrowserCocCoc Then
		$BD_LoadHandle = _BrowserDownloadStartVersionUrl($CocCocArchiveRawUrl)
	ElseIf $BrowserType = $BrowserWhale Then
		$BD_LoadWhaleUrls = _BrowserDownloadGetWhaleVersionUrls()
		$BD_LoadWhaleIndex = 0
		While $BD_LoadWhaleIndex < UBound($BD_LoadWhaleUrls) And Not $BD_LoadHandle
			$BD_LoadHandle = _BrowserDownloadStartVersionUrl($BD_LoadWhaleUrls[$BD_LoadWhaleIndex])
			If Not $BD_LoadHandle Then $BD_LoadWhaleIndex += 1
		WEnd
	ElseIf $BrowserType = $BrowserBrave Then
		Local $BraveVersionUrls = _BrowserDownloadGetBraveVersionUrls($Channel, $Os)
		$BD_LoadBraveUrls = $BraveVersionUrls
		$BD_LoadBraveIndex = 0
		$BD_LoadHandle = _BrowserDownloadStartVersionUrl($BD_LoadBraveUrls[$BD_LoadBraveIndex])
	ElseIf $BrowserType = $BrowserXunlei Then
		$BD_LoadHandle = _BrowserDownloadStartVersionUrl($XunleiVersionDataUrl)
	ElseIf $BrowserType = $BrowserUngoogledChromium Then
		Local $UngoogledVersionUrl = $UngoogledChromiumGitCodeTagsUrl
		If _DownloadToolsUsesProxy() Then $UngoogledVersionUrl = $UngoogledChromiumLatestReleaseApiUrl
		$BD_LoadHandle = _BrowserDownloadStartVersionUrl($UngoogledVersionUrl)
	ElseIf $BrowserType = $BrowserOpera Then
		Local $OperaUrls = _BrowserDownloadGetOperaVersionUrls($Channel)
		$BD_LoadOperaUrls = $OperaUrls
		$BD_LoadOperaIndex = 0
		While $BD_LoadOperaIndex < UBound($BD_LoadOperaUrls) And Not $BD_LoadHandle
			$BD_LoadHandle = _BrowserDownloadStartVersionUrl($BD_LoadOperaUrls[$BD_LoadOperaIndex])
			If Not $BD_LoadHandle Then $BD_LoadOperaIndex += 1
		WEnd
	ElseIf IsChromeBrowser($BrowserType) Then
		$BD_LoadKind = "chrome"
		$BD_LoadHandle = _BrowserDownloadStartChromeVersionLoadProcess($Channel, $Os, $BD_LoadFile)
	Else
		Local $Url = $FirefoxVersionUrl
		If $BrowserType = $BrowserZen Then $Url = $ZenUpdateBaseUrl & "/" & _BrowserDownloadGetZenUpdateChannel($Channel) & "/update.xml"
		If $BrowserType = $BrowserFloorp Then $Url = $FloorpLatestReleaseUrl
		If $BrowserType = $BrowserWaterfox Then $Url = $WaterfoxDownloadPageUrl
		If $BrowserType = $BrowserLibreWolf Then $Url = $LibreWolfLatestReleaseApiUrl
		$BD_LoadHandle = _BrowserDownloadStartVersionUrl($Url)
	EndIf

	If $BD_LoadHandle Then Return True
	_BrowserDownloadClearVersionLoad()
	Return False
EndFunc

Func _BrowserDownloadPollVersionLoad(ByRef $BrowserType, ByRef $Channel)
	$BrowserType = ""
	$Channel = ""
	If Not $BD_LoadHandle Then Return -1

	If $BD_LoadKind = "chrome" Then
		If ProcessExists($BD_LoadHandle) Then Return 0
		$BrowserType = $BD_LoadBrowserType
		$Channel = $BD_LoadChannel
		Local $ChromeLoaded = _BrowserDownloadLoadChromeUpdateInfoFile($Channel, $BD_LoadFile)
		_BrowserDownloadClearVersionLoad()
		If $ChromeLoaded Then Return 1
		Return -1
	EndIf

	If $BD_LoadKind = "curl" Then
		If ProcessExists($BD_LoadHandle) Then Return 0
	ElseIf Not InetGetInfo($BD_LoadHandle, 2) Then
		Return 0
	EndIf
	Local $DownloadSuccessful = FileExists($BD_LoadFile) And FileGetSize($BD_LoadFile) > 0
	If $BD_LoadKind = "inet" Then $DownloadSuccessful = InetGetInfo($BD_LoadHandle, 3)
	$BrowserType = $BD_LoadBrowserType
	$Channel = $BD_LoadChannel
	If $BD_LoadKind = "inet" Then InetClose($BD_LoadHandle)
	$BD_LoadHandle = 0
	If Not $DownloadSuccessful Then
		Local $RoutedHandle = _DownloadToolsAdvanceUrlToFile($BD_LoadKind)
		If $RoutedHandle Then
			$BD_LoadHandle = $RoutedHandle
			Return 0
		EndIf
	EndIf
	If Not $DownloadSuccessful And $BrowserType = $BrowserBrave And IsArray($BD_LoadBraveUrls) And $BD_LoadBraveIndex + 1 < UBound($BD_LoadBraveUrls) Then
		$BD_LoadBraveIndex += 1
		$BD_LoadHandle = _BrowserDownloadStartVersionUrl($BD_LoadBraveUrls[$BD_LoadBraveIndex])
		If $BD_LoadHandle Then Return 0
	EndIf

	Local $Loaded = False
	If $DownloadSuccessful Then
		Local $Content = FileRead($BD_LoadFile)
		If $Content <> "" Then
			If $BrowserType = $BrowserZen Then
				_BrowserDownloadSetZenUpdateXml($Channel, $Content)
				$Loaded = True
			ElseIf $BrowserType = $BrowserFloorp Then
				$Loaded = _BrowserDownloadCacheFloorpReleaseInfo($Content)
			ElseIf $BrowserType = $BrowserWaterfox Then
				$Loaded = _BrowserDownloadCacheWaterfoxReleaseInfo($Content)
			ElseIf $BrowserType = $BrowserLibreWolf Then
				$Loaded = _BrowserDownloadCacheLibreWolfReleaseInfo($Content)
			ElseIf $BrowserType = $BrowserTurbo Then
				$Loaded = _BrowserDownloadCacheTurboReleaseInfo($Content)
			ElseIf $BrowserType = $BrowserHelium Then
				$Loaded = _BrowserDownloadCacheHeliumReleaseInfo($Content)
			ElseIf $BrowserType = $BrowserCent Then
				$Loaded = _BrowserDownloadCacheCentReleaseInfo($Content)
			ElseIf $BrowserType = $BrowserVivaldi Then
				$Loaded = _BrowserDownloadCacheVivaldiReleaseInfo($Channel, $Content)
			ElseIf $BrowserType = $BrowserCocCoc Then
				$Loaded = _BrowserDownloadCacheCocCocReleaseInfo($Content)
			ElseIf $BrowserType = $BrowserWhale Then
				$Loaded = _BrowserDownloadCacheWhaleReleaseInfo($Content)
			ElseIf $BrowserType = $BrowserBrave Then
				$Loaded = _BrowserDownloadCacheBraveReleaseInfo($Content, $Channel)
			ElseIf $BrowserType = $BrowserXunlei Then
				$Loaded = _BrowserDownloadCacheXunleiReleaseInfo($Content)
			ElseIf $BrowserType = $BrowserUngoogledChromium Then
				$Loaded = _BrowserDownloadCacheUngoogledChromiumReleaseInfo($Content)
			ElseIf $BrowserType = $BrowserOpera Then
				$Loaded = _BrowserDownloadCacheOperaReleaseInfo($Channel, $Content)
			Else
				$Loaded = _BrowserDownloadCacheFirefoxVersions($Content)
			EndIf
		EndIf
	EndIf
	If Not $Loaded And $BrowserType = $BrowserLibreWolf Then $Loaded = _BrowserDownloadGetLibreWolfReleasePage()
	If Not $Loaded And $BrowserType = $BrowserTurbo Then $Loaded = _BrowserDownloadGetTurboReleasePage()
	If Not $Loaded And $BrowserType = $BrowserBrave Then $Loaded = _BrowserDownloadGetBraveReleasePage()
	If Not $Loaded And $BrowserType = $BrowserUngoogledChromium Then $Loaded = _BrowserDownloadGetUngoogledChromiumReleaseFallback()
	If Not $Loaded And $BrowserType = $BrowserHelium And IsArray($BD_LoadHeliumUrls) And $BD_LoadHeliumIndex + 1 < UBound($BD_LoadHeliumUrls) Then
		While $BD_LoadHeliumIndex + 1 < UBound($BD_LoadHeliumUrls)
			$BD_LoadHeliumIndex += 1
			FileDelete($BD_LoadFile)
			$BD_LoadHandle = _BrowserDownloadStartVersionUrl($BD_LoadHeliumUrls[$BD_LoadHeliumIndex])
			If $BD_LoadHandle Then Return 0
		WEnd
	EndIf
	If Not $Loaded And $BrowserType = $BrowserWhale And IsArray($BD_LoadWhaleUrls) And $BD_LoadWhaleIndex + 1 < UBound($BD_LoadWhaleUrls) Then
		While $BD_LoadWhaleIndex + 1 < UBound($BD_LoadWhaleUrls)
			$BD_LoadWhaleIndex += 1
			FileDelete($BD_LoadFile)
			$BD_LoadHandle = _BrowserDownloadStartVersionUrl($BD_LoadWhaleUrls[$BD_LoadWhaleIndex])
			If $BD_LoadHandle Then Return 0
		WEnd
	EndIf
	If Not $Loaded And $BrowserType = $BrowserVivaldi And IsArray($BD_LoadVivaldiUrls) And $BD_LoadVivaldiIndex + 1 < UBound($BD_LoadVivaldiUrls) Then
		$BD_LoadVivaldiIndex += 1
		FileDelete($BD_LoadFile)
		$BD_LoadHandle = _BrowserDownloadStartVersionUrl($BD_LoadVivaldiUrls[$BD_LoadVivaldiIndex])
		If $BD_LoadHandle Then Return 0
	EndIf
	If Not $Loaded And $BrowserType = $BrowserOpera And IsArray($BD_LoadOperaUrls) And $BD_LoadOperaIndex + 1 < UBound($BD_LoadOperaUrls) Then
		$BD_LoadOperaIndex += 1
		FileDelete($BD_LoadFile)
		$BD_LoadHandle = _BrowserDownloadStartVersionUrl($BD_LoadOperaUrls[$BD_LoadOperaIndex])
		If $BD_LoadHandle Then Return 0
	EndIf
	_BrowserDownloadClearVersionLoad()
	If $Loaded Then Return 1
	Return -1
EndFunc

Func _BrowserDownloadCancelVersionLoad()
	If $BD_LoadHandle Then
		If $BD_LoadKind = "chrome" Or $BD_LoadKind = "curl" Then
			If ProcessExists($BD_LoadHandle) Then ProcessClose($BD_LoadHandle)
		Else
			InetClose($BD_LoadHandle)
		EndIf
	EndIf
	_BrowserDownloadClearVersionLoad()
EndFunc

Func _BrowserDownloadClearVersionLoad()
	If $BD_LoadFile <> "" Then FileDelete($BD_LoadFile)
	$BD_LoadHandle = 0
	$BD_LoadFile = ""
	$BD_LoadBrowserType = ""
	$BD_LoadChannel = ""
	$BD_LoadOs = ""
	$BD_LoadKind = ""
	$BD_LoadBraveUrls = 0
	$BD_LoadBraveIndex = 0
	$BD_LoadVivaldiUrls = 0
	$BD_LoadVivaldiIndex = 0
	$BD_LoadOperaUrls = 0
	$BD_LoadOperaIndex = 0
	$BD_LoadWhaleUrls = 0
	$BD_LoadWhaleIndex = 0
	$BD_LoadHeliumUrls = 0
	$BD_LoadHeliumIndex = 0
EndFunc

Func _BrowserDownloadGetGithubLatestReleaseApi($ApiUrl)
	Local $Urls = _UpgradeBuildGithubApiUrls($ApiUrl, GetEffectiveGithubApiMirror(), $BD_GithubDirectMirror)
	For $i = 0 To UBound($Urls) - 1
		Local $Content = _DownloadToolsHttpGetText($Urls[$i], "RunFirefox/" & $BD_AppVersion, "application/vnd.github+json")
		If Not @error And StringRegExp($Content, '(?i)"tag_name"\s*:') Then Return $Content
	Next
	Return SetError(1, 0, "")
EndFunc

Func _BrowserDownloadDecodeXmlAttribute($Value)
	$Value = StringReplace($Value, "&amp;", "&")
	$Value = StringReplace($Value, "&quot;", '"')
	$Value = StringReplace($Value, "&apos;", "'")
	$Value = StringReplace($Value, "&lt;", "<")
	Return StringReplace($Value, "&gt;", ">")
EndFunc

Func _BrowserDownloadSelectChromeDownloadBaseUrl(ByRef $Urls)
	For $i = 0 To UBound($Urls) - 1
		Local $Url = _BrowserDownloadDecodeXmlAttribute($Urls[$i])
		If StringInStr($Url, "https://dl.google.com/") = 1 Then Return $Url
	Next
	For $i = 0 To UBound($Urls) - 1
		Local $Url = _BrowserDownloadDecodeXmlAttribute($Urls[$i])
		If StringLeft($Url, 8) = "https://" Then Return $Url
	Next
	If UBound($Urls) > 0 Then Return _BrowserDownloadDecodeXmlAttribute($Urls[0])
	Return ""
EndFunc

Func _BrowserDownloadGetFirefoxVersions()
	If IsObj($FirefoxVersionsObj) Then Return $FirefoxVersionsObj

	Local $sVersions = BinaryToString(_DownloadToolsReadUrl($FirefoxVersionUrl), 4)
	If @error Or $sVersions = "" Then Return SetError(1, 0, 0)

	If Not _BrowserDownloadCacheFirefoxVersions($sVersions) Then Return SetError(1, 0, 0)
	Return $FirefoxVersionsObj
EndFunc   ;==>GetFirefoxVersions

Func _BrowserDownloadCacheFirefoxVersions($sVersions)
	Local $oVersions = Json_Decode($sVersions)
	If @error Or Not Json_IsObject($oVersions) Then Return SetError(1, 0, 0)

	$FirefoxVersionsObj = $oVersions
	Return True
EndFunc   ;==>CacheFirefoxVersions

Func _BrowserDownloadGetLatestFirefoxVersion($Channel)
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

	Local $oVersions = _BrowserDownloadGetFirefoxVersions()
	If @error Or Not IsObj($oVersions) Then Return ""

	Local $Version = Json_ObjGet($oVersions, $VersionKey)
	If @error Or $Version = "" Then Return ""

	Return $Version
EndFunc   ;==>GetLatestFirefoxVersion

Func _BrowserDownloadGetFirefoxChannelLabel($Channel)
	Local $Version = _BrowserDownloadGetLatestFirefoxVersion($Channel)
	If $Version = "" Then Return $Channel
	Return $Channel & " (" & $Version & ")"
EndFunc   ;==>GetFirefoxChannelLabel

Func _BrowserDownloadGetZenUpdateXml($Channel)
	Local $sCachedUpdateXml = _BrowserDownloadGetZenUpdateXmlCache($Channel)
	If $sCachedUpdateXml <> "" Then Return $sCachedUpdateXml

	$Channel = _BrowserDownloadGetZenUpdateChannel($Channel)
	Local $sUpdateXml = BinaryToString(_DownloadToolsReadUrl($ZenUpdateBaseUrl & "/" & $Channel & "/update.xml"), 4)
	If @error Or $sUpdateXml = "" Then Return SetError(1, 0, "")
	_BrowserDownloadSetZenUpdateXml($Channel, $sUpdateXml)
	Return $sUpdateXml
EndFunc   ;==>GetZenUpdateXml

Func _BrowserDownloadGetZenUpdateXmlCache($Channel)
	$Channel = _BrowserDownloadGetZenUpdateChannel($Channel)
	If $Channel = "twilight" Then Return $ZenTwilightUpdateXml
	Return $ZenReleaseUpdateXml
EndFunc   ;==>GetZenUpdateXmlCache

Func _BrowserDownloadSetZenUpdateXml($Channel, $sUpdateXml)
	$Channel = _BrowserDownloadGetZenUpdateChannel($Channel)
	If $Channel = "twilight" Then
		$ZenTwilightUpdateXml = $sUpdateXml
	Else
		$ZenReleaseUpdateXml = $sUpdateXml
	EndIf
EndFunc   ;==>SetZenUpdateXml

Func _BrowserDownloadGetLatestZenVersion($Channel)
	Local $sUpdateXml = _BrowserDownloadGetZenUpdateXml($Channel)
	If @error Or $sUpdateXml = "" Then Return ""

	Local $match = StringRegExp($sUpdateXml, 'displayVersion="([^"]+)"', 1)
	If @error Then Return ""
	Return $match[0]
EndFunc   ;==>GetLatestZenVersion

Func _BrowserDownloadGetLatestZenReleaseTag($Channel)
	Local $sUpdateXml = _BrowserDownloadGetZenUpdateXml($Channel)
	If @error Or $sUpdateXml = "" Then Return ""

	Local $match = StringRegExp($sUpdateXml, '/releases/download/([^/]+)/', 1)
	If @error Then Return ""
	Return $match[0]
EndFunc   ;==>GetLatestZenReleaseTag

Func _BrowserDownloadGetZenChannelLabel($Channel)
	Local $Version = _BrowserDownloadGetLatestZenVersion($Channel)
	If $Version = "" Then Return $Channel
	Return $Channel & " (" & $Version & ")"
EndFunc   ;==>GetZenChannelLabel

Func _BrowserDownloadGetZenUpdateChannel($Channel)
	If $Channel = "twilight" Then Return "twilight"
	Return "release"
EndFunc   ;==>GetZenUpdateChannel

Func _BrowserDownloadCacheFloorpReleaseInfo($Content)
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

Func _BrowserDownloadGetLatestFloorpVersion()
	If $FloorpReleaseTag = "" Then Return ""
	Return StringRegExpReplace($FloorpReleaseTag, "(?i)^v", "")
EndFunc   ;==>GetLatestFloorpVersion

Func _BrowserDownloadGetFloorpChannelLabel($Channel)
	Local $Version = _BrowserDownloadGetLatestFloorpVersion()
	If $Version = "" Then Return $Channel
	Return $Channel & " (" & $Version & ")"
EndFunc   ;==>GetFloorpChannelLabel

Func _BrowserDownloadGetWaterfoxReleasePage()
	If $WaterfoxReleaseInfoLoaded Then Return True

	Local $Content = BinaryToString(_DownloadToolsReadUrl($WaterfoxDownloadPageUrl), 4)
	If @error Or $Content = "" Then Return SetError(1, 0, False)

	Return _BrowserDownloadCacheWaterfoxReleaseInfo($Content)
EndFunc   ;==>GetWaterfoxReleasePage

Func _BrowserDownloadGetWaterfoxReleaseFallback()
	Local $Content = _BrowserDownloadGetGithubLatestReleaseApi($WaterfoxLatestReleaseApiUrl)
	If $Content = "" Then Return False

	Local $Match = StringRegExp($Content, '(?i)"tag_name"\s*:\s*"v?([0-9][^"\s]+)"', 1)
	If @error Or Not IsArray($Match) Then Return False
	$WaterfoxReleaseVersion = $Match[0]
	$WaterfoxReleaseInfoLoaded = True
	Return True
EndFunc   ;==>GetWaterfoxReleaseFallback

Func _BrowserDownloadCacheWaterfoxReleaseInfo($Content)
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

Func _BrowserDownloadGetLatestWaterfoxVersion()
	If $WaterfoxReleaseVersion = "" Then Return ""
	Return $WaterfoxReleaseVersion
EndFunc   ;==>GetLatestWaterfoxVersion

Func _BrowserDownloadGetLibreWolfReleasePage()
	If $LibreWolfReleaseInfoLoaded Then Return True
	Local $Content = _DownloadToolsHttpGetText($LibreWolfLatestReleaseApiUrl, "Mozilla/5.0", "application/json")
	If @error Or $Content = "" Then Return False
	Return _BrowserDownloadCacheLibreWolfReleaseInfo($Content)
EndFunc   ;==>GetLibreWolfReleasePage

Func _BrowserDownloadCacheLibreWolfReleaseInfo($Content)
	$LibreWolfReleaseInfoLoaded = False
	$LibreWolfReleaseVersion = ""
	$LibreWolfDownloadUrl = ""

	; The official page also lists setup and ARM64 files; accept only the x86_64 portable ZIP.
	Local $Match = StringRegExp($Content, "(?i)https://dl\.librewolf\.net/librewolf/([^/""<>\s]+)/librewolf-([^/""<>\s]+)-windows-x86_64-portable\.zip", 1)
	If @error Or Not IsArray($Match) Then Return False

	$LibreWolfReleaseVersion = $Match[1]
	$LibreWolfDownloadUrl = "https://dl.librewolf.net/librewolf/" & $Match[0] & "/librewolf-" & $Match[1] & "-windows-x86_64-portable.zip"
	$LibreWolfReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheLibreWolfReleaseInfo

Func _BrowserDownloadGetLatestLibreWolfVersion()
	If $LibreWolfReleaseVersion = "" Then Return ""
	Return $LibreWolfReleaseVersion
EndFunc   ;==>GetLatestLibreWolfVersion

Func _BrowserDownloadGetTurboReleasePage()
	If $TurboReleaseInfoLoaded Then Return True
	Local $Content = BinaryToString(_DownloadToolsReadUrl($TurboDownloadInfoUrl), 4)
	If @error Or $Content = "" Then Return False
	Return _BrowserDownloadCacheTurboReleaseInfo($Content)
EndFunc   ;==>GetTurboReleasePage

Func _BrowserDownloadGetTurboReleaseFallback()
	Local $Content = _BrowserDownloadGetGithubLatestReleaseApi($TurboLatestReleaseApiUrl)
	If $Content = "" Then Return False

	Local $VersionMatch = StringRegExp($Content, '(?i)"tag_name"\s*:\s*"v?([0-9]+(?:\.[0-9]+)+)"', 1)
	Local $AssetMatch = StringRegExp($Content, '(?i)"browser_download_url"\s*:\s*"(https://github\.com/' & $TurboRepo & '/releases/download/[^"/]+/(Turbo_([0-9]+(?:\.[0-9]+)+)_portable\.7z))"', 1)
	If @error Or Not IsArray($VersionMatch) Or Not IsArray($AssetMatch) Or $AssetMatch[2] <> $VersionMatch[0] Then Return False

	$TurboReleaseVersion = $VersionMatch[0]
	$TurboAssetName = $AssetMatch[1]
	$TurboDownloadUrl = ""
	$TurboGithubDownloadUrl = $AssetMatch[0]
	$TurboReleaseInfoLoaded = True
	Return True
EndFunc   ;==>GetTurboReleaseFallback

Func _BrowserDownloadCacheTurboReleaseInfo($Content)
	$TurboReleaseInfoLoaded = False
	$TurboReleaseVersion = ""
	$TurboAssetName = ""
	$TurboDownloadUrl = ""
	$TurboGithubDownloadUrl = ""

	Local $VersionMatch = StringRegExp($Content, "(?i)\bver\s*:\s*['""']([0-9]+(?:\.[0-9]+)+)['""']", 1)
	If @error Or Not IsArray($VersionMatch) Then Return False
	Local $PortableMatch = StringRegExp($Content, "(?i)\bportable_url\s*:\s*['""'](https://dl\.tbrowser\.cn/download/(Turbo_([0-9]+(?:\.[0-9]+)+)_portable\.7z))['""']", 1)
	If @error Or Not IsArray($PortableMatch) Or $PortableMatch[2] <> $VersionMatch[0] Then Return False

	$TurboReleaseVersion = $VersionMatch[0]
	$TurboDownloadUrl = $PortableMatch[0]
	$TurboAssetName = $PortableMatch[1]
	$TurboGithubDownloadUrl = "https://github.com/" & $TurboRepo & "/releases/download/" & $TurboReleaseVersion & "/" & $TurboAssetName
	$TurboReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheTurboReleaseInfo

Func _BrowserDownloadGetLatestTurboVersion()
	If $TurboReleaseVersion = "" Then Return ""
	Return $TurboReleaseVersion
EndFunc   ;==>GetLatestTurboVersion

Func _BrowserDownloadGetWaterfoxChannelLabel($Channel)
	Local $Version = _BrowserDownloadGetLatestWaterfoxVersion()
	If $Version = "" Then Return $Channel
	Return $Channel & " (" & $Version & ")"
EndFunc   ;==>GetWaterfoxChannelLabel

Func _BrowserDownloadGetHeliumReleasePage()
	If $HeliumReleaseInfoLoaded Then Return True
	Local $Content = _DownloadToolsHttpGetText($HeliumArchiveRawUrl, "RunFirefox/" & $BD_AppVersion, "application/json")
	If Not @error And $Content <> "" And _BrowserDownloadCacheHeliumReleaseInfo($Content) Then Return True
	$Content = _BrowserDownloadGetGithubLatestReleaseApi($HeliumLatestReleaseApiUrl)
	If $Content = "" Then Return SetError(1, 0, False)
	Return _BrowserDownloadCacheHeliumReleaseInfo($Content)
EndFunc   ;==>GetHeliumReleasePage

Func _BrowserDownloadCacheHeliumReleaseInfo($Content)
	$HeliumReleaseInfoLoaded = False
	$HeliumReleaseTag = ""

	Local $Json = Json_Decode($Content)
	If Not @error And IsObj($Json) Then
		If Json_ObjExists($Json, "version") Then
			Local $Version = Json_ObjGet($Json, "version")
			If Not StringRegExp($Version, '^[0-9]+(?:\.[0-9]+)+$') Then Return False
			$HeliumReleaseTag = $Version
			$HeliumReleaseInfoLoaded = True
			Return True
		EndIf
		Local $ApiTag = Json_ObjGet($Json, "tag_name")
		If @error Or Not StringRegExp($ApiTag, '(?i)^v?[0-9]+(?:\.[0-9]+)+$') Then Return False
		$HeliumReleaseTag = $ApiTag
		$HeliumReleaseInfoLoaded = True
		Return True
	EndIf

	Local $Match = StringRegExp($Content, '(?i)/' & $HeliumRepo & '/releases/tag/(v?[0-9]+(?:\.[0-9]+)+)', 1)
	If @error Or Not IsArray($Match) Then Return False
	$HeliumReleaseTag = $Match[0]
	$HeliumReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheHeliumReleaseInfo

Func _BrowserDownloadGetHeliumVersionUrls()
	Local $Urls[3]
	$Urls[0] = $HeliumArchiveRawUrl
	$Urls[1] = $HeliumLatestReleaseUrl
	$Urls[2] = $HeliumLatestReleaseApiUrl
	Return $Urls
EndFunc   ;==>GetHeliumVersionUrls

Func _BrowserDownloadGetLatestHeliumVersion()
	If $HeliumReleaseTag = "" Then Return ""
	Return StringRegExpReplace($HeliumReleaseTag, "(?i)^v", "")
EndFunc   ;==>GetLatestHeliumVersion

Func _BrowserDownloadGetHeliumChannelLabel($Channel)
	Local $Version = _BrowserDownloadGetLatestHeliumVersion()
	If $Version = "" Then Return $Channel
	Return $Channel & " (" & $Version & ")"
EndFunc   ;==>GetHeliumChannelLabel

Func _BrowserDownloadGetCentReleasePage()
	If $CentReleaseInfoLoaded Then Return True

	Local $Content = BinaryToString(_DownloadToolsReadUrl($CentBrowserDownloadPageUrl), 4)
	If @error Or $Content = "" Then Return SetError(1, 0, False)

	Return _BrowserDownloadCacheCentReleaseInfo($Content)
EndFunc   ;==>GetCentReleasePage

Func _BrowserDownloadCacheCentReleaseInfo($Content)
	$CentReleaseInfoLoaded = False
	$CentReleaseVersion = ""
	$CentDownloadUrl = ""

	Local $Match = StringRegExp($Content, '(?is)href="([^"]*centbrowser_([0-9][0-9.]*)_x64_portable\.exe)"', 1)
	If @error Then $Match = StringRegExp($Content, '(?is)href="([^"]*centbrowser_([0-9][0-9.]*)_x64\.exe)"', 1)
	If @error Then Return False

	$CentDownloadUrl = _BrowserDownloadNormalizeCentDownloadUrl($Match[0])
	$CentReleaseVersion = $Match[1]
	If $CentReleaseVersion = "" Then
		$Match = StringRegExp($Content, '(?is)Version:\s*([0-9][0-9.]*)', 1)
		If Not @error Then $CentReleaseVersion = $Match[0]
	EndIf

	If $CentDownloadUrl = "" Then Return False
	$CentReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheCentReleaseInfo

Func _BrowserDownloadNormalizeCentDownloadUrl($Url)
	$Url = _BrowserDownloadDecodeXmlAttribute(StringStripWS($Url, 3))
	If $Url = "" Then Return ""
	If StringLeft($Url, 2) = "//" Then Return "https:" & $Url
	If StringRegExp($Url, "(?i)^https?://") Then Return $Url
	If StringLeft($Url, 1) = "/" Then Return "https://www.centbrowser.com" & $Url
	Return $CentBrowserDownloadPageUrl & $Url
EndFunc   ;==>NormalizeCentDownloadUrl

Func _BrowserDownloadGetLatestCentVersion()
	If $CentReleaseVersion = "" Then Return ""
	Return $CentReleaseVersion
EndFunc   ;==>GetLatestCentVersion

Func _BrowserDownloadGetCentChannelLabel($Channel)
	Local $Version = _BrowserDownloadGetLatestCentVersion()
	If $Version = "" Then Return $Channel
	Return $Channel & " (" & $Version & ")"
EndFunc   ;==>GetCentChannelLabel

Func _BrowserDownloadNormalizeVivaldiChannel($Channel)
	If StringLower(StringStripWS($Channel, 3)) = "snapshot" Then Return "snapshot"
	Return "stable"
EndFunc   ;==>NormalizeVivaldiChannel

Func _BrowserDownloadGetVivaldiUpdateUrls($Channel)
	Local $Urls[1], $UrlCount = 0
	If Not _DownloadToolsUsesProxy() Then
		Local $JsMirrors = _UpgradeGetGithubJsDelivrMirrors($BD_GithubJsDelivrMirror, $BD_Locale)
		Local $JsPath = $VivaldiArchiveRepo & "@main/" & $VivaldiArchiveDataPath
		For $i = 0 To UBound($JsMirrors) - 1
			_UpgradeAddUrl($Urls, $UrlCount, $JsMirrors[$i] & $JsPath)
		Next
	EndIf
	_UpgradeAddUrl($Urls, $UrlCount, $VivaldiArchiveRawUrl)
	Local $ChannelPath = "public/appcast.x64.xml"
	If _BrowserDownloadNormalizeVivaldiChannel($Channel) = "snapshot" Then $ChannelPath = "win/appcast.x64.xml"
	_UpgradeAddUrl($Urls, $UrlCount, $VivaldiUpdateOfficialBaseUrl & $ChannelPath)
	ReDim $Urls[$UrlCount]
	Return $Urls
EndFunc   ;==>GetVivaldiUpdateUrls

Func _BrowserDownloadIsVivaldiInfoLoaded($Channel)
	If _BrowserDownloadNormalizeVivaldiChannel($Channel) = "snapshot" Then Return $VivaldiSnapshotReleaseInfoLoaded
	Return $VivaldiStableReleaseInfoLoaded
EndFunc   ;==>IsVivaldiInfoLoaded

Func _BrowserDownloadGetVivaldiReleaseInfo($Channel)
	$Channel = _BrowserDownloadNormalizeVivaldiChannel($Channel)
	If _BrowserDownloadIsVivaldiInfoLoaded($Channel) Then Return True

	Local $Urls = _BrowserDownloadGetVivaldiUpdateUrls($Channel)
	For $i = 0 To UBound($Urls) - 1
		Local $Accept = "application/json"
		If $i > 0 Then $Accept = "application/xml"
		Local $Content = _DownloadToolsHttpGetText($Urls[$i], "RunFirefox/" & $BD_AppVersion, $Accept)
		If Not @error And $Content <> "" And _BrowserDownloadCacheVivaldiReleaseInfo($Channel, $Content) Then Return True
	Next
	Return SetError(1, 0, False)
EndFunc   ;==>GetVivaldiReleaseInfo

Func _BrowserDownloadCacheVivaldiReleaseInfo($Channel, $Content)
	$Channel = _BrowserDownloadNormalizeVivaldiChannel($Channel)
	Local $LegacyMatch = StringRegExp($Content, '(?is)<enclosure\b[^>]*\burl="(https://downloads\.vivaldi\.com/((?:stable|stable-auto|snapshot|snapshot-auto)/Vivaldi\.([0-9][0-9.]*)\.x64\.exe))"[^>]*>', 1)
	If IsArray($LegacyMatch) Then
		If $Channel = "snapshot" And StringRegExp($LegacyMatch[1], "(?i)^snapshot(?:-auto)?/") Then
			$VivaldiSnapshotDownloadUrl = $LegacyMatch[0]
			$VivaldiSnapshotReleaseVersion = $LegacyMatch[2]
			$VivaldiSnapshotReleaseInfoLoaded = True
			Return True
		ElseIf $Channel = "stable" And StringRegExp($LegacyMatch[1], "(?i)^stable(?:-auto)?/") Then
			$VivaldiStableDownloadUrl = $LegacyMatch[0]
			$VivaldiStableReleaseVersion = $LegacyMatch[2]
			$VivaldiStableReleaseInfoLoaded = True
			Return True
		EndIf
	EndIf
	Local $Json = Json_Decode($Content)
	If @error Or Not IsObj($Json) Then Return False
	Local $Channels = Json_ObjGet($Json, "channels")
	If @error Or Not IsObj($Channels) Then Return False
	Local $ChannelData = Json_ObjGet($Channels, $Channel)
	If @error Or Not IsObj($ChannelData) Then Return False
	Local $Version = Json_ObjGet($ChannelData, "version")
	Local $Files = Json_ObjGet($ChannelData, "files")
	If @error Or Not IsObj($Files) Then Return False
	Local $X64 = Json_ObjGet($Files, "x64")
	If @error Or Not IsObj($X64) Then Return False
	Local $DownloadUrl = Json_ObjGet($X64, "url")
	If $DownloadUrl = "" Or Not StringRegExp($Version, "^[0-9]+(?:\.[0-9]+)+$") Then Return False
	Local $ChannelPath = "stable(?:-auto)?"
	If $Channel = "snapshot" Then $ChannelPath = "snapshot(?:-auto)?"
	Local $EscapedVersion = StringReplace($Version, ".", "\.")
	If Not StringRegExp($DownloadUrl, "^https://downloads\.vivaldi\.com/" & $ChannelPath & "/Vivaldi\." & $EscapedVersion & "\.x64\.exe$") Then Return False
	If $Channel = "snapshot" Then
		$VivaldiSnapshotDownloadUrl = $DownloadUrl
		$VivaldiSnapshotReleaseVersion = $Version
		$VivaldiSnapshotReleaseInfoLoaded = True
		Return True
	EndIf
	$VivaldiStableDownloadUrl = $DownloadUrl
	$VivaldiStableReleaseVersion = $Version
	$VivaldiStableReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheVivaldiReleaseInfo

Func _BrowserDownloadGetLatestVivaldiVersion($Channel)
	If _BrowserDownloadNormalizeVivaldiChannel($Channel) = "snapshot" Then Return $VivaldiSnapshotReleaseVersion
	Return $VivaldiStableReleaseVersion
EndFunc   ;==>GetLatestVivaldiVersion

Func _BrowserDownloadGetVivaldiDownloadUrl($Channel)
	If _BrowserDownloadNormalizeVivaldiChannel($Channel) = "snapshot" Then Return $VivaldiSnapshotDownloadUrl
	Return $VivaldiStableDownloadUrl
EndFunc   ;==>GetVivaldiDownloadUrl

Func _BrowserDownloadNormalizeOperaChannel($Channel)
	If StringLower($Channel) = "dev" Then Return "dev"
	Return "stable"
EndFunc   ;==>NormalizeOperaChannel

Func _BrowserDownloadGetOperaChannelDir($Channel)
	If _BrowserDownloadNormalizeOperaChannel($Channel) = "dev" Then Return "opera-developer"
	Return "opera"
EndFunc   ;==>GetOperaChannelDir

Func _BrowserDownloadGetOperaListingUrl($Channel)
	Local $Dir = _BrowserDownloadGetOperaChannelDir($Channel)
	If $Dir = "opera" Then Return $OperaDesktopFtpBaseUrl & $Dir & "/desktop/"
	Return $OperaDesktopFtpBaseUrl & $Dir & "/"
EndFunc   ;==>GetOperaListingUrl

Func _BrowserDownloadGetOperaProduct($Channel)
	If _BrowserDownloadNormalizeOperaChannel($Channel) = "dev" Then Return "Opera Developer"
	Return "Opera"
EndFunc   ;==>GetOperaProduct

Func _BrowserDownloadGetOperaVersionUrls($Channel)
	Local $Product = _BrowserDownloadGetOperaProduct($Channel)
	Local $EncodedProduct = StringReplace($Product, " ", "%20")
	Local $Query = "product=" & $EncodedProduct & "&version=" & $OperaVersionApiQueryVersion
	Local $Urls[2]
	$Urls[0] = $OperaArchiveRawUrl
	$Urls[1] = $OperaVersionApiOfficialBaseUrl & $Query
	Return $Urls
EndFunc   ;==>GetOperaVersionUrls

Func _BrowserDownloadIsOperaInfoLoaded($Channel)
	If _BrowserDownloadNormalizeOperaChannel($Channel) = "dev" Then Return $OperaDevInfoLoaded
	Return $OperaStableInfoLoaded
EndFunc   ;==>IsOperaInfoLoaded

Func _BrowserDownloadGetOperaReleasePage($Channel)
	If _BrowserDownloadIsOperaInfoLoaded($Channel) Then Return True
	Local $Urls = _BrowserDownloadGetOperaVersionUrls($Channel)
	For $i = 0 To UBound($Urls) - 1
		Local $Content = _DownloadToolsHttpGetText($Urls[$i], "RunFirefox/" & $BD_AppVersion, "application/json")
		If Not @error And $Content <> "" And _BrowserDownloadCacheOperaReleaseInfo($Channel, $Content) Then Return True
	Next
	Return SetError(1, 0, False)
EndFunc   ;==>GetOperaReleasePage

Func _BrowserDownloadCacheOperaReleaseInfo($Channel, $Content)
	$Channel = _BrowserDownloadNormalizeOperaChannel($Channel)
	Local $Json = Json_Decode($Content)
	If @error Or Not IsObj($Json) Then Return False
	Local $Latest = "", $Products = Json_ObjGet($Json, "products")
	If Not @error And IsObj($Products) Then
		Local $Opera = Json_ObjGet($Products, "opera")
		If Not @error And IsObj($Opera) Then
			Local $Channels = Json_ObjGet($Opera, "channels")
			If Not @error And IsObj($Channels) Then
				Local $ArchiveChannel = "stable"
				If $Channel = "dev" Then $ArchiveChannel = "developer"
				Local $ChannelData = Json_ObjGet($Channels, $ArchiveChannel)
				If Not @error And IsObj($ChannelData) Then
					$Latest = Json_ObjGet($ChannelData, "version")
					If @error Then $Latest = ""
				EndIf
			EndIf
		EndIf
	EndIf
	If $Latest = "" Then
		$Latest = Json_ObjGet($Json, "current_version")
		If @error Then $Latest = ""
	EndIf
	If Not StringRegExp($Latest, '^[0-9]+(?:\.[0-9]+)+$') Then Return False

	If $Channel = "dev" Then
		$OperaDevVersion = $Latest
		$OperaDevInfoLoaded = True
		Return True
	EndIf
	$OperaStableVersion = $Latest
	$OperaStableInfoLoaded = True
	Return True
EndFunc   ;==>CacheOperaReleaseInfo

Func _BrowserDownloadGetLatestOperaVersion($Channel)
	If _BrowserDownloadNormalizeOperaChannel($Channel) = "dev" Then
		If Not $OperaDevInfoLoaded Then Return ""
		Return $OperaDevVersion
	EndIf
	If Not $OperaStableInfoLoaded Then Return ""
	Return $OperaStableVersion
EndFunc   ;==>GetLatestOperaVersion

Func _BrowserDownloadBuildOperaDownloadUrl($Channel, $os)
	If $os <> "win64" Then Return SetError(1, 0, "")
	If Not _BrowserDownloadIsOperaInfoLoaded($Channel) Then
		If Not _BrowserDownloadGetOperaReleasePage($Channel) Then Return SetError(1, 0, "")
	EndIf
	Local $Version = _BrowserDownloadGetLatestOperaVersion($Channel)
	If $Version = "" Then Return SetError(2, 0, "")
	Local $Dir = _BrowserDownloadGetOperaChannelDir($Channel)
	Local $FilePrefix = "Opera_"
	If _BrowserDownloadNormalizeOperaChannel($Channel) = "dev" Then $FilePrefix = "Opera_Developer_"
	Local $Path = $Dir & "/"
	If $Dir = "opera" Then $Path &= "desktop/"
	$Path &= $Version & "/win/" & $FilePrefix & $Version & "_Setup_x64.exe"
	Return $OperaDesktopFtpBaseUrl & $Path
EndFunc   ;==>BuildOperaDownloadUrl

Func _BrowserDownloadCacheWhaleReleaseInfo($Content)
	Local $Version = "", $DownloadX86Url = "", $DownloadX64Url = ""
	Local $Json = Json_Decode($Content)
	If Not @error And IsObj($Json) Then
		$Version = Json_ObjGet($Json, "version")
		If Not @error And StringRegExp($Version, '^[0-9]+(?:\.[0-9]+)+$') Then
			Local $Files = Json_ObjGet($Json, "files")
			If Not @error And IsObj($Files) Then
				Local $X86 = Json_ObjGet($Files, "x86")
				If Not @error And IsObj($X86) Then $DownloadX86Url = Json_ObjGet($X86, "url")
				Local $X64 = Json_ObjGet($Files, "x64")
				If Not @error And IsObj($X64) Then $DownloadX64Url = Json_ObjGet($X64, "url")
			EndIf
		EndIf
		If StringRegExp($DownloadX86Url, '(?i)^https://archive\.org/download/whale-archive-[0-9]+(?:\.[0-9]+)+/WhaleSetupX86\.exe$') _
				And StringInStr($DownloadX86Url, "/whale-archive-" & $Version & "/", 2) _
				And StringRegExp($DownloadX64Url, '(?i)^https://archive\.org/download/whale-archive-[0-9]+(?:\.[0-9]+)+/WhaleSetupX64\.exe$') _
				And StringInStr($DownloadX64Url, "/whale-archive-" & $Version & "/", 2) Then
			$WhaleReleaseVersion = $Version
			$WhaleDownloadX86Url = $DownloadX86Url
			$WhaleDownloadX64Url = $DownloadX64Url
			$WhaleReleaseInfoLoaded = True
			Return True
		EndIf
	EndIf

	; Preserve the legacy Naver endpoint as the final version-only fallback.
	Local $Match = StringRegExp($Content, '(?i)"@version"\s*:\s*"([0-9]+(?:\.[0-9]+)+)"', 1)
	If @error Or Not IsArray($Match) Then Return False
	$Version = StringStripWS($Match[0], 3)
	If $Version = "" Then Return False
	$WhaleReleaseVersion = $Version
	$WhaleDownloadX86Url = ""
	$WhaleDownloadX64Url = ""
	$WhaleReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheWhaleReleaseInfo

Func _BrowserDownloadGetWhaleVersionUrls()
	Local $Urls[1], $UrlCount = 0
	If Not _DownloadToolsUsesProxy() Then
		Local $JsMirrors = _UpgradeGetGithubJsDelivrMirrors($BD_GithubJsDelivrMirror, $BD_Locale)
		Local $JsPath = $WhaleArchiveRepo & "@main/" & $WhaleArchiveDataPath
		For $i = 0 To UBound($JsMirrors) - 1
			_UpgradeAddUrl($Urls, $UrlCount, $JsMirrors[$i] & $JsPath)
		Next
	EndIf
	_UpgradeAddUrl($Urls, $UrlCount, $WhaleArchiveRawUrl)
	_UpgradeAddUrl($Urls, $UrlCount, $WhaleLatestVersionUrl)
	ReDim $Urls[$UrlCount]
	Return $Urls
EndFunc   ;==>GetWhaleVersionUrls

Func _BrowserDownloadGetWhaleReleaseInfo()
	If $WhaleReleaseInfoLoaded Then Return True
	Local $Urls = _BrowserDownloadGetWhaleVersionUrls()
	For $i = 0 To UBound($Urls) - 1
		Local $Content = _DownloadToolsHttpGetText($Urls[$i], "RunFirefox/" & $BD_AppVersion, "application/json")
		If Not @error And $Content <> "" And _BrowserDownloadCacheWhaleReleaseInfo($Content) Then Return True
	Next
	Return SetError(1, 0, False)
EndFunc   ;==>GetWhaleReleaseInfo

Func _BrowserDownloadGetLatestWhaleVersion()
	If $WhaleReleaseVersion = "" Then Return ""
	Return $WhaleReleaseVersion
EndFunc   ;==>GetLatestWhaleVersion

Func _BrowserDownloadCacheCocCocReleaseInfo($Content)
	Local $Json = Json_Decode($Content)
	If @error Or Not IsObj($Json) Then Return False
	Local $Version = Json_ObjGet($Json, "version")
	Local $Files = Json_ObjGet($Json, "files")
	If @error Or Not StringRegExp($Version, '^[0-9]+(?:\.[0-9]+)+$') Or Not IsObj($Files) Then Return False
	Local $X64 = Json_ObjGet($Files, "x64")
	If @error Or Not IsObj($X64) Then Return False
	Local $Filename = Json_ObjGet($X64, "filename")
	Local $Url = Json_ObjGet($X64, "url")
	Local $Sha256 = StringLower(StringStripWS(Json_ObjGet($X64, "sha256"), 3))
	Local $ExpectedFilename = "coccoc-" & $Version & "-win-x64.zip"
	Local $ExpectedUrl = "https://archive.org/download/coccoc-archive-" & $Version & "/" & $ExpectedFilename
	If StringLower($Filename) <> StringLower($ExpectedFilename) Then Return False
	If StringLower($Url) <> StringLower($ExpectedUrl) Then Return False
	If Not StringRegExp($Sha256, "^[0-9a-f]{64}$") Then Return False
	$CocCocReleaseVersion = $Version
	$CocCocDownloadFilename = $Filename
	$CocCocDownloadUrl = $Url
	$CocCocDownloadSha256 = $Sha256
	$CocCocReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheCocCocReleaseInfo

Func _BrowserDownloadGetCocCocReleaseInfo()
	If $CocCocReleaseInfoLoaded Then Return True
	Local $Content = _DownloadToolsHttpGetText($CocCocArchiveRawUrl, "RunFirefox/" & $BD_AppVersion, "application/json")
	If @error Or $Content = "" Then Return SetError(1, 0, False)
	Return _BrowserDownloadCacheCocCocReleaseInfo($Content)
EndFunc   ;==>GetCocCocReleaseInfo

Func _BrowserDownloadGetLatestCocCocVersion()
	If Not $CocCocReleaseInfoLoaded Then Return ""
	Return $CocCocReleaseVersion
EndFunc   ;==>GetLatestCocCocVersion

Func _BrowserDownloadBuildCocCocDownloadUrl($Channel, $os)
	If $os <> "win64" Then Return SetError(1, 0, "")
	If Not _BrowserDownloadGetCocCocReleaseInfo() Then Return SetError(2, 0, "")
	Return $CocCocDownloadUrl
EndFunc   ;==>BuildCocCocDownloadUrl

Func _BrowserDownloadGetExpectedSha256($BrowserType, $Channel = "release", $os = "win64")
	If NormalizeBrowserType($BrowserType) <> $BrowserCocCoc Or $os <> "win64" Then Return ""
	If Not $CocCocReleaseInfoLoaded Then _BrowserDownloadGetCocCocReleaseInfo()
	If Not $CocCocReleaseInfoLoaded Then Return ""
	Return $CocCocDownloadSha256
EndFunc   ;==>GetExpectedSha256

Func _BrowserDownloadCacheXunleiReleaseInfo($Content)
	$XunleiReleaseInfoLoaded = False
	$XunleiDownloadUrl = ""

	; The official homepage exposes the current Windows installer as the pcOnline
	; constant in its Nuxt bundle. Keep the parser restricted to the official CDN.
	Local $Match = StringRegExp($Content, '(?i)(https://down\.sandai\.net/[^"''<>\s]+\.exe)', 1)
	If @error Or Not IsArray($Match) Then
		Local $BaseMatch = StringRegExp($Content, '(?i)(/browser_pc/[^"''<>\s]+\.exe)', 1)
		If @error Or Not IsArray($BaseMatch) Then Return False
		$XunleiDownloadUrl = "https://down.sandai.net" & $BaseMatch[0]
		$XunleiReleaseInfoLoaded = True
		Return True
	EndIf
	If Not StringRegExp($Match[0], '(?i)^https://down\.sandai\.net/(?:browser_pc|thunder11)/[^"''<>\s]+\.exe$') Then Return False
	$XunleiDownloadUrl = _BrowserDownloadDecodeXmlAttribute($Match[0])
	If $XunleiDownloadUrl = "" Then Return False
	$XunleiReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheXunleiReleaseInfo

Func _BrowserDownloadGetLatestXunleiVersion()
	Return ""
EndFunc   ;==>GetLatestXunleiVersion

Func _BrowserDownloadGetBraveReleasePage()
	Local $RequestedChannel = _BrowserDownloadNormalizeBraveChannel($BD_LoadChannel)
	If $BraveReleaseInfoLoaded And $BraveDownloadUrl <> "" And StringLower($BraveReleaseChannel) = StringLower($RequestedChannel) Then Return True
	Local $Content = "", $VersionUrls[2]
	$VersionUrls[0] = $BraveArchiveRawUrl
	$VersionUrls[1] = $BraveVersionDataOfficialUrl
	For $i = 0 To UBound($VersionUrls) - 1
		$Content = _DownloadToolsHttpGetText($VersionUrls[$i], "RunFirefox/" & $BD_AppVersion, "application/json")
		If $Content <> "" And _BrowserDownloadCacheBraveReleaseInfo($Content, $RequestedChannel) Then Return True
	Next
	; The GitHub latest-release API can only provide the release channel.
	If $RequestedChannel <> "release" Then Return SetError(1, 0, False)
	$Content = _BrowserDownloadGetGithubLatestReleaseApi($BraveLatestReleaseApiUrl)
	If $Content = "" Then Return SetError(1, 0, False)
	Return _BrowserDownloadCacheBraveReleaseInfo($Content, $RequestedChannel)
EndFunc   ;==>GetBraveReleasePage

Func _BrowserDownloadNormalizeBraveChannel($Channel)
	$Channel = StringLower(StringStripWS($Channel, 3))
	If $Channel = "stable" Or $Channel = "default" Or $Channel = "" Then Return "release"
	If $Channel = "beta" Or $Channel = "nightly" Then Return $Channel
	Return "release"
EndFunc   ;==>NormalizeBraveChannel

; BrowserArchive is routed through the shared GitHub mirror handling before the official fallback.
Func _BrowserDownloadGetBraveVersionUrls($Channel, $Platform = "win64")
	Local $Urls[2]
	$Urls[0] = $BraveArchiveRawUrl
	$Urls[1] = $BraveVersionDataOfficialUrl
	Return $Urls
EndFunc   ;==>GetBraveVersionUrls

Func _BrowserDownloadGetXunleiReleasePage()
	If $XunleiReleaseInfoLoaded Then Return True
	Local $Content = BinaryToString(_DownloadToolsReadUrl($XunleiVersionDataUrl), 4)
	If @error Or $Content = "" Then Return False
	Return _BrowserDownloadCacheXunleiReleaseInfo($Content)
EndFunc   ;==>GetXunleiReleasePage

Func _BrowserDownloadCacheBraveReleaseInfo($Content, $RequestedChannel = "")
	$BraveReleaseInfoLoaded = False
	$BraveReleaseTag = ""
	$BraveDownloadUrl = ""
	$BraveReleaseChannel = ""
	If $RequestedChannel = "" Then $RequestedChannel = $BD_LoadChannel
	Local $Wanted = _BrowserDownloadNormalizeBraveChannel($RequestedChannel)
	; BrowserArchive stores all Brave channels in one document. Its stable key maps
	; to RunFirefox's release channel.
	Local $Json = Json_Decode($Content)
	If Not @error And IsObj($Json) And Json_ObjExists($Json, "channels") Then
		Local $Channels = Json_ObjGet($Json, "channels")
		Local $ArchiveChannel = $Wanted
		If $ArchiveChannel = "release" Then $ArchiveChannel = "stable"
		If IsObj($Channels) And Json_ObjExists($Channels, $ArchiveChannel) Then
			Local $ChannelData = Json_ObjGet($Channels, $ArchiveChannel)
			If IsObj($ChannelData) Then
				Local $Version = Json_ObjGet($ChannelData, "version")
				Local $Packages = Json_ObjGet($ChannelData, "packages")
				If StringRegExp($Version, '^[0-9]+(?:\.[0-9]+)+$') And IsObj($Packages) Then
					Local $X64 = Json_ObjGet($Packages, "x64")
					If IsObj($X64) Then
						Local $Zip = Json_ObjGet($X64, "zip")
						If IsObj($Zip) Then
							Local $Name = Json_ObjGet($Zip, "filename"), $Url = Json_ObjGet($Zip, "url")
							Local $ExpectedName = "brave-v" & $Version & "-win32-x64.zip"
							Local $ExpectedUrl = "https://github.com/" & $BraveRepo & "/releases/download/v" & $Version & "/" & $ExpectedName
							If StringLower($Name) = StringLower($ExpectedName) And StringLower($Url) = StringLower($ExpectedUrl) Then
								$BraveReleaseTag = "v" & $Version
								$BraveDownloadUrl = $Url
								$BraveReleaseChannel = $Wanted
								$BraveReleaseInfoLoaded = True
								Return True
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
	; GitHub API fallback retains the same official asset naming.
	Local $ApiTag = StringRegExp($Content, '(?i)"tag_name"\s*:\s*"([^"]+)"', 1)
	If Not @error And IsArray($ApiTag) Then
		If $Wanted <> "release" Then Return False
		Local $ApiAsset = StringRegExp($Content, '(?i)"browser_download_url"\s*:\s*"(https://github\.com/' & $BraveRepo & '/releases/download/[^"/]+/brave-v[^"/]+-win32-x64\.zip)"', 1)
		If Not @error And IsArray($ApiAsset) Then
			$BraveReleaseTag = $ApiTag[0]
			$BraveDownloadUrl = $ApiAsset[0]
			$BraveReleaseChannel = "release"
			$BraveReleaseInfoLoaded = True
			Return True
		EndIf
		Return False
	EndIf
	Local $Matches = StringRegExp($Content, '(?is)"tag"\s*:\s*"(v?([0-9]+(?:\.[0-9]+)+))"(?:(?!"tag"\s*:).)*?"channel"\s*:\s*"([^"]+)"(?:(?!"tag"\s*:).)*?"name"\s*:\s*"brave-v\2-win32-x64\.zip"\s*,\s*"download_url"\s*:\s*"(https://github\.com/' & $BraveRepo & '/releases/download/[^"\\]+)"', 3)
	If @error Or Not IsArray($Matches) Then Return False
	Local $BestVersion = "", $BestTag = "", $BestUrl = ""
	For $i = 0 To UBound($Matches) - 1 Step 4
		Local $Tag = $Matches[$i], $Version = $Matches[$i + 1], $Channel = StringLower($Matches[$i + 2]), $Url = $Matches[$i + 3]
		If $Channel <> $Wanted Then ContinueLoop
		If $BestVersion = "" Or VersionCompare($Version, $BestVersion) > 0 Then
			$BestVersion = $Version
			$BestTag = $Tag
			$BestUrl = $Url
		EndIf
	Next
	If $BestUrl = "" Then Return False
	$BraveReleaseTag = $BestTag
	$BraveDownloadUrl = $BestUrl
	$BraveReleaseChannel = $Wanted
	$BraveReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheBraveReleaseInfo

Func _BrowserDownloadGetLatestBraveVersion($Channel = "release")
	If $BraveReleaseTag = "" Or StringLower($BraveReleaseChannel) <> _BrowserDownloadNormalizeBraveChannel($Channel) Then Return ""
	Return StringRegExpReplace($BraveReleaseTag, "(?i)^v", "")
EndFunc   ;==>GetLatestBraveVersion

Func _BrowserDownloadGetUngoogledChromiumReleaseFallback()
	Local $Content = _BrowserDownloadGetGithubLatestReleaseApi($UngoogledChromiumLatestReleaseApiUrl)
	If $Content = "" Then Return False
	Return _BrowserDownloadCacheUngoogledChromiumReleaseInfo($Content)
EndFunc   ;==>GetUngoogledChromiumReleaseFallback

Func _BrowserDownloadCacheUngoogledChromiumReleaseInfo($Content)
	$UngoogledChromiumReleaseInfoLoaded = False
	$UngoogledChromiumReleaseTag = ""
	Local $Match = StringRegExp($Content, '(?i)(?:tag_name|/releases/tag/|/tags/)["=:>/ ]+([0-9]+[.][0-9]+[.][0-9]+[.][0-9]+-[0-9.]+)', 1)
	If @error Then $Match = StringRegExp($Content, '(?i)([0-9]+[.][0-9]+[.][0-9]+[.][0-9]+-[0-9.]+)', 1)
	If @error Or Not IsArray($Match) Then Return False
	$UngoogledChromiumReleaseTag = $Match[0]
	$UngoogledChromiumReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheUngoogledChromiumReleaseInfo

Func _BrowserDownloadGetLatestUngoogledChromiumVersion()
	If $UngoogledChromiumReleaseTag = "" Then Return ""
	Return $UngoogledChromiumReleaseTag
EndFunc   ;==>GetLatestUngoogledChromiumVersion

Func _BrowserDownloadGetVivaldiChannelLabel($Channel)
	$Channel = _BrowserDownloadNormalizeVivaldiChannel($Channel)
	Local $Version = _BrowserDownloadGetLatestVivaldiVersion($Channel)
	If $Version = "" Then Return $Channel
	Return $Channel & " (" & $Version & ")"
EndFunc   ;==>GetVivaldiChannelLabel

Func _BrowserDownloadGetChromeChannelLabel($Channel, $LoadVersion = False)
	$Channel = _BrowserDownloadNormalizeChromeChannel($Channel)
	Local $Version = ""
	If $LoadVersion Then $Version = _BrowserDownloadGetChromeVersionCache($Channel)
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

Func _BrowserDownloadGetLatestFirefoxProduct($Channel)
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

Func _BrowserDownloadGetFirefoxDownloadLanguage()
	Return _BrowserDownloadGetLocale("zh-CN")
EndFunc   ;==>GetFirefoxDownloadLanguage

Func _BrowserDownloadGetLocale($DefaultLocale = "")
	Local $lang = StringReplace($BD_Locale, "_", "-")
	If $lang = "" Then Return $DefaultLocale
	If Not StringRegExp($lang, "^[A-Za-z]{2,3}(-[A-Za-z0-9]+)*$") Then Return $DefaultLocale
	Return $lang
EndFunc   ;==>GetBrowserLocale

Func _BrowserDownloadBuildFirefoxDownloadUrl($Channel, $os)
	Local $Version = ""
	If IsObj($FirefoxVersionsObj) Then $Version = _BrowserDownloadGetLatestFirefoxVersion($Channel)
	Local $lang = _BrowserDownloadGetFirefoxDownloadLanguage()
	If $Version = "" Then
		Return "https://download.mozilla.org/?product=" & _BrowserDownloadGetLatestFirefoxProduct($Channel) & "&os=" & $os & "&lang=" & $lang
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

Func _BrowserDownloadBuildZenDownloadUrl($Channel, $os)
	Local $ReleaseTag = ""
	If _BrowserDownloadGetZenUpdateXmlCache($Channel) <> "" Then $ReleaseTag = _BrowserDownloadGetLatestZenReleaseTag($Channel)
	If $ReleaseTag = "" Then Return "https://github.com/zen-browser/desktop/releases/latest/download/zen.installer.exe"
	Return "https://github.com/zen-browser/desktop/releases/download/" & $ReleaseTag & "/zen.installer.exe"
EndFunc   ;==>BuildZenDownloadUrl

Func _BrowserDownloadBuildFloorpDownloadUrl($Channel, $os)
	If $FloorpReleaseTag = "" Then Return "https://github.com/" & $FloorpRepo & "/releases/latest/download/" & $FloorpWindowsX64Asset
	Return "https://github.com/" & $FloorpRepo & "/releases/download/" & $FloorpReleaseTag & "/" & $FloorpWindowsX64Asset
EndFunc   ;==>BuildFloorpDownloadUrl

Func _BrowserDownloadBuildWaterfoxDownloadUrl($Channel, $os)
	Local $Version = _BrowserDownloadGetLatestWaterfoxVersion()
	If $Version = "" Then
		If Not _BrowserDownloadGetWaterfoxReleasePage() Then
			If Not _BrowserDownloadGetWaterfoxReleaseFallback() Then Return SetError(1, 0, "")
		EndIf
		$Version = _BrowserDownloadGetLatestWaterfoxVersion()
	EndIf
	If $Version = "" Then Return SetError(2, 0, "")
	Return "https://cdn.waterfox.com/waterfox/releases/" & $Version & "/WINNT_x86_64/Waterfox%20Setup%20" & $Version & ".exe"
EndFunc   ;==>BuildWaterfoxDownloadUrl

Func _BrowserDownloadBuildLibreWolfDownloadUrl($Channel, $os)
	If $os <> "win64" Then Return SetError(1, 0, "")
	If $LibreWolfDownloadUrl = "" Then
		If Not _BrowserDownloadGetLibreWolfReleasePage() Then Return SetError(1, 0, "")
	EndIf
	If $LibreWolfDownloadUrl = "" Or Not StringRegExp($LibreWolfDownloadUrl, "(?i)-windows-x86_64-portable\.zip$") Then Return SetError(2, 0, "")
	Return $LibreWolfDownloadUrl
EndFunc   ;==>BuildLibreWolfDownloadUrl

Func _BrowserDownloadBuildTurboDownloadUrl($Channel, $os)
	If $os <> "win64" Then Return SetError(1, 0, "")
	If $TurboDownloadUrl = "" And $TurboGithubDownloadUrl = "" Then
		If Not _BrowserDownloadGetTurboReleasePage() Then
			If Not _BrowserDownloadGetTurboReleaseFallback() Then Return SetError(1, 0, "")
		EndIf
	EndIf
	If StringRegExp($TurboDownloadUrl, "(?i)^https://dl\.tbrowser\.cn/download/Turbo_[0-9.]+_portable\.7z$") Then Return $TurboDownloadUrl
	If StringRegExp($TurboGithubDownloadUrl, "(?i)^https://github\.com/" & $TurboRepo & "/releases/download/[^/]+/Turbo_[0-9.]+_portable\.7z$") Then Return $TurboGithubDownloadUrl
	Return SetError(2, 0, "")
EndFunc   ;==>BuildTurboDownloadUrl

Func _BrowserDownloadBuildHeliumDownloadUrl($Channel, $os)
	Local $Version = _BrowserDownloadGetLatestHeliumVersion()
	If $Version = "" Then
		If Not _BrowserDownloadGetHeliumReleasePage() Then Return SetError(1, 0, "")
		$Version = _BrowserDownloadGetLatestHeliumVersion()
	EndIf
	If $Version = "" Or $HeliumReleaseTag = "" Then Return SetError(2, 0, "")
	Return "https://github.com/" & $HeliumRepo & "/releases/download/" & $HeliumReleaseTag & "/helium_" & $Version & "_x64-windows.zip"
EndFunc   ;==>BuildHeliumDownloadUrl

Func _BrowserDownloadBuildCentDownloadUrl($Channel, $os)
	If $os <> "win64" Then Return SetError(1, 0, "")
	If $CentDownloadUrl = "" Then
		If Not _BrowserDownloadGetCentReleasePage() Then Return SetError(1, 0, "")
	EndIf
	If $CentDownloadUrl = "" Then Return SetError(2, 0, "")
	Return $CentDownloadUrl
EndFunc   ;==>BuildCentDownloadUrl

Func _BrowserDownloadBuildVivaldiDownloadUrl($Channel, $os)
	If $os <> "win64" Then Return SetError(1, 0, "")
	$Channel = _BrowserDownloadNormalizeVivaldiChannel($Channel)
	Local $DownloadUrl = _BrowserDownloadGetVivaldiDownloadUrl($Channel)
	If $DownloadUrl = "" Then
		If Not _BrowserDownloadGetVivaldiReleaseInfo($Channel) Then Return SetError(1, 0, "")
		$DownloadUrl = _BrowserDownloadGetVivaldiDownloadUrl($Channel)
	EndIf
	If $DownloadUrl = "" Then Return SetError(2, 0, "")
	Return $DownloadUrl
EndFunc   ;==>BuildVivaldiDownloadUrl

Func _BrowserDownloadBuildBraveDownloadUrl($Channel, $os)
	If $os <> "win64" Then Return SetError(1, 0, "")
	$Channel = _BrowserDownloadNormalizeBraveChannel($Channel)
	If $BraveDownloadUrl = "" Or StringLower($BraveReleaseChannel) <> $Channel Then
		$BD_LoadChannel = $Channel
		If Not _BrowserDownloadGetBraveReleasePage() Then Return SetError(1, 0, "")
	EndIf
	If Not StringRegExp($BraveDownloadUrl, "(?i)^https://github\.com/" & $BraveRepo & "/releases/download/[^/]+/brave-v[^/]+-win32-x64\.zip$") Then Return SetError(2, 0, "")
	Return $BraveDownloadUrl
EndFunc   ;==>BuildBraveDownloadUrl

Func _BrowserDownloadBuildXunleiDownloadUrl($Channel, $os)
	If $os <> "win64" Then Return SetError(1, 0, "")
	If $XunleiDownloadUrl = "" Then
		If Not _BrowserDownloadGetXunleiReleasePage() Then Return SetError(1, 0, "")
	EndIf
	If Not StringRegExp($XunleiDownloadUrl, '(?i)^https://down\.sandai\.net/(?:browser_pc|thunder11)/[^"''<>\s]+\.exe$') Then Return SetError(2, 0, "")
	Return $XunleiDownloadUrl
EndFunc   ;==>BuildXunleiDownloadUrl

Func _BrowserDownloadBuildUngoogledChromiumDownloadUrl($Channel, $os)
	If Not $UngoogledChromiumReleaseInfoLoaded Then
		If Not _BrowserDownloadGetUngoogledChromiumReleaseFallback() Then Return SetError(1, 0, "")
	EndIf
	If $UngoogledChromiumReleaseTag = "" Then Return SetError(2, 0, "")
	Local $Arch = StringLower(StringStripWS($os, 3))
	If $Arch = "win64" Then $Arch = "x64"
	If $Arch = "win32" Then $Arch = "x86"
	If $Arch <> "x64" And $Arch <> "x86" And $Arch <> "arm64" Then Return SetError(3, 0, "")
	Return "https://github.com/" & $UngoogledChromiumRepo & "/releases/download/" & $UngoogledChromiumReleaseTag & "/ungoogled-chromium_" & $UngoogledChromiumReleaseTag & "_windows_" & $Arch & ".zip"
EndFunc   ;==>BuildUngoogledChromiumDownloadUrl

Func _BrowserDownloadBuildWhaleDownloadUrl($Channel, $os)
	If $os <> "win32" And $os <> "win64" Then Return SetError(1, 0, "")
	If Not $WhaleReleaseInfoLoaded Then _BrowserDownloadGetWhaleReleaseInfo()
	If $os = "win32" Then
		If $WhaleDownloadX86Url <> "" Then Return $WhaleDownloadX86Url
		Return $WhaleStandaloneX86Url
	EndIf
	If $WhaleDownloadX64Url <> "" Then Return $WhaleDownloadX64Url
	Return $WhaleStandaloneX64Url
EndFunc   ;==>BuildWhaleDownloadUrl

Func _BrowserDownloadBuildChromeDownloadUrl($Channel, $os)
	Local $DownloadUrl = _BrowserDownloadGetChromeDownloadUrlCache($Channel)
	If $DownloadUrl <> "" Then Return $DownloadUrl
	If Not _BrowserDownloadLoadChromeUpdateInfo($Channel, $os) Then Return _BrowserDownloadGetChromeStandaloneFallbackUrl($Channel, $os)
	$DownloadUrl = _BrowserDownloadGetChromeDownloadUrlCache($Channel)
	If $DownloadUrl = "" Then Return _BrowserDownloadGetChromeStandaloneFallbackUrl($Channel, $os)
	Return $DownloadUrl
EndFunc   ;==>BuildChromeDownloadUrl

Func _BrowserDownloadGetChromeStandaloneFallbackUrl($Channel, $os)
	If $os <> "win64" Then Return SetError(1, 0, "")
	Switch _BrowserDownloadNormalizeChromeChannel($Channel)
		Case "stable"
			Return $ChromeStableStandaloneX64Url
		Case "beta"
			Return $ChromeBetaStandaloneX64Url
		Case "dev"
			Return $ChromeDevStandaloneX64Url
	EndSwitch
	Return SetError(2, 0, "")
EndFunc   ;==>GetChromeStandaloneFallbackUrl

Func _BrowserDownloadLoadChromeUpdateInfo($Channel, $os)
	$Channel = _BrowserDownloadNormalizeChromeChannel($Channel)
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

	Local $RequestXml = _BrowserDownloadBuildChromeUpdateRequest($AppId, $Ap, $Arch)
	Local $ResponseXml = _BrowserDownloadChromeUpdatePost($RequestXml)
	If @error Or $ResponseXml = "" Then Return False

	Local $Version = StringRegExp($ResponseXml, '(?is)<manifest[^>]+version="([^"]+)"', 1)
	Local $Package = StringRegExp($ResponseXml, '(?is)<package[^>]+name="([^"]+)"', 1)
	Local $Urls = StringRegExp($ResponseXml, '(?is)<url[^>]+codebase="([^"]+)"', 3)
	If @error Or Not IsArray($Version) Or Not IsArray($Package) Or Not IsArray($Urls) Then Return False

	Local $BaseUrl = _BrowserDownloadSelectChromeDownloadBaseUrl($Urls)
	If $BaseUrl = "" Then Return False

	_BrowserDownloadSetChromeUpdateCache($Channel, _BrowserDownloadDecodeXmlAttribute($Version[0]), _BrowserDownloadDecodeXmlAttribute($BaseUrl) & _BrowserDownloadDecodeXmlAttribute($Package[0]))
	Return True
EndFunc   ;==>LoadChromeUpdateInfo

Func _BrowserDownloadStartChromeVersionLoadProcess($Channel, $os, $OutputFile)
	Local $Command = ""
	If @Compiled Then
		$Command = '"' & @AutoItExe & '"'
	Else
		$Command = '"' & @AutoItExe & '" "' & @ScriptFullPath & '"'
	EndIf
	$Command &= ' --load-chrome-version "' & $Channel & '" "' & $os & '" "' & $OutputFile & '"'
	Return Run($Command, @ScriptDir, @SW_HIDE)
EndFunc   ;==>StartChromeVersionLoadProcess

Func _BrowserDownloadWriteChromeUpdateInfoFile($Channel, $os, $OutputFile)
	FileDelete($OutputFile)
	If _BrowserDownloadLoadChromeUpdateInfo($Channel, $os) Then
		IniWrite($OutputFile, "Chrome", "Success", 1)
		IniWrite($OutputFile, "Chrome", "Version", _BrowserDownloadGetChromeVersionCache($Channel))
		IniWrite($OutputFile, "Chrome", "DownloadUrl", _BrowserDownloadGetChromeDownloadUrlCache($Channel))
	Else
		IniWrite($OutputFile, "Chrome", "Success", 0)
	EndIf
EndFunc   ;==>WriteChromeUpdateInfoFile

Func _BrowserDownloadLoadChromeUpdateInfoFile($Channel, $OutputFile)
	If Not FileExists($OutputFile) Then Return False
	If IniRead($OutputFile, "Chrome", "Success", 0) <> 1 Then Return False

	Local $Version = IniRead($OutputFile, "Chrome", "Version", "")
	Local $DownloadUrl = IniRead($OutputFile, "Chrome", "DownloadUrl", "")
	If $Version = "" Or $DownloadUrl = "" Then Return False

	_BrowserDownloadSetChromeUpdateCache($Channel, $Version, $DownloadUrl)
	Return True
EndFunc   ;==>LoadChromeUpdateInfoFile

Func _BrowserDownloadNormalizeChromeChannel($Channel)
	Switch StringLower($Channel)
		Case "beta", "dev", "canary"
			Return StringLower($Channel)
	EndSwitch
	Return "stable"
EndFunc   ;==>NormalizeChromeChannel

Func _BrowserDownloadNormalizeChannel($BrowserType, $Channel)
	$BrowserType = NormalizeBrowserType($BrowserType)
	Switch $BrowserType
		Case $BrowserOtherFirefox, $BrowserOtherChromium
			Return "default"
		Case $BrowserChrome
			Return _BrowserDownloadNormalizeChromeChannel($Channel)
		Case $BrowserBrave
			Return _BrowserDownloadNormalizeBraveChannel($Channel)
		Case $BrowserVivaldi
			Return _BrowserDownloadNormalizeVivaldiChannel($Channel)
		Case $BrowserOpera
			Return _BrowserDownloadNormalizeOperaChannel($Channel)
	EndSwitch
	If StringLower($Channel) = "default" Then Return "release"
	Return StringLower($Channel)
EndFunc   ;==>NormalizeChannel

Func _BrowserDownloadGetChromeVersionCache($Channel)
	Switch _BrowserDownloadNormalizeChromeChannel($Channel)
		Case "beta"
			Return $ChromeBetaVersion
		Case "dev"
			Return $ChromeDevVersion
		Case "canary"
			Return $ChromeCanaryVersion
	EndSwitch
	Return $ChromeStableVersion
EndFunc   ;==>GetChromeVersionCache

Func _BrowserDownloadGetChromeDownloadUrlCache($Channel)
	Switch _BrowserDownloadNormalizeChromeChannel($Channel)
		Case "beta"
			Return $ChromeBetaDownloadUrl
		Case "dev"
			Return $ChromeDevDownloadUrl
		Case "canary"
			Return $ChromeCanaryDownloadUrl
	EndSwitch
	Return $ChromeStableDownloadUrl
EndFunc   ;==>GetChromeDownloadUrlCache

Func _BrowserDownloadSetChromeUpdateCache($Channel, $Version, $DownloadUrl)
	Switch _BrowserDownloadNormalizeChromeChannel($Channel)
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

Func _BrowserDownloadBuildChromeUpdateRequest($AppId, $Ap, $Arch)
	Local $OsVersion = _BrowserDownloadGetChromeOmahaOsVersion()
	Return '<?xml version="1.0" encoding="UTF-8"?><request protocol="3.0" version="1.3.23.9" shell_version="1.3.21.103" ismachine="0" sessionid="{3597644B-2952-4F92-AE55-D315F45F80A5}" installsource="ondemandcheckforupdate" requestid="{CD7523AD-A40D-49F4-AEEF-8C114B804658}" dedup="cr">' & _
			'<hw physmemory="12582912" sse="1" sse2="1" sse3="1" ssse3="1" sse41="1" sse42="1" avx="1"/>' & _
			'<os platform="win" version="' & $OsVersion & '" arch="' & $Arch & '"/>' & _
			'<app appid="' & $AppId & '" version="" nextversion="" ap="' & $Ap & '" lang="' & _BrowserDownloadGetLocale("zh-CN") & '"><updatecheck/></app></request>'
EndFunc   ;==>BuildChromeUpdateRequest

Func _BrowserDownloadGetChromeOmahaOsVersion()
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

Func _BrowserDownloadChromeUpdatePost($RequestXml)
	Return _DownloadToolsHttpPostText($ChromeUpdateUrl, $RequestXml, $ChromeUpdateUserAgent, "application/xml")
EndFunc   ;==>ChromeUpdatePost

Func _BrowserDownloadChromeComError($oError)
	Return
EndFunc   ;==>ChromeComError

Func _BrowserDownloadBuildBrowserDownloadUrl($Value, $Channel, $os)
	If Not _BrowserDownloadIsSupported($Value) Then Return SetError(1, 0, "")
	If NormalizeBrowserType($Value) = $BrowserUngoogledChromium Then Return _BrowserDownloadBuildUngoogledChromiumDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserTurbo Then Return _BrowserDownloadBuildTurboDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserHelium Then Return _BrowserDownloadBuildHeliumDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserWhale Then Return _BrowserDownloadBuildWhaleDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserCent Then Return _BrowserDownloadBuildCentDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserVivaldi Then Return _BrowserDownloadBuildVivaldiDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserCocCoc Then Return _BrowserDownloadBuildCocCocDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserOpera Then Return _BrowserDownloadBuildOperaDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserBrave Then Return _BrowserDownloadBuildBraveDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserXunlei Then Return _BrowserDownloadBuildXunleiDownloadUrl($Channel, $os)
	If IsChromeBrowser($Value) Then Return _BrowserDownloadBuildChromeDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserZen Then Return _BrowserDownloadBuildZenDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserFloorp Then Return _BrowserDownloadBuildFloorpDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserWaterfox Then Return _BrowserDownloadBuildWaterfoxDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserLibreWolf Then Return _BrowserDownloadBuildLibreWolfDownloadUrl($Channel, $os)
	Return _BrowserDownloadBuildFirefoxDownloadUrl($Channel, $os)
EndFunc   ;==>BuildBrowserDownloadUrl

Func _BrowserDownloadBuildUrls($Value, $Channel, $os)
	If Not _BrowserDownloadIsSupported($Value) Then Return SetError(1, 0, 0)
	$Channel = _BrowserDownloadNormalizeChannel($Value, $Channel)
	Local $DownloadUrl = _BrowserDownloadBuildBrowserDownloadUrl($Value, $Channel, $os)
	If @error Or $DownloadUrl = "" Then Return SetError(1, 0, 0)

	If NormalizeBrowserType($Value) = $BrowserTurbo Then
		Local $TurboUrls[1], $TurboUrlCount = 0
		_UpgradeAddUrl($TurboUrls, $TurboUrlCount, $DownloadUrl)
		Local $GithubUrls = _UpgradeBuildGithubReleaseDownloadUrls($TurboGithubDownloadUrl, $BD_GithubDirectMirror, $BD_GithubJsDelivrMirror)
		For $i = 0 To UBound($GithubUrls) - 1
			_UpgradeAddUrl($TurboUrls, $TurboUrlCount, $GithubUrls[$i])
		Next
		ReDim $TurboUrls[$TurboUrlCount]
		Return $TurboUrls
	EndIf

	If NormalizeBrowserType($Value) = $BrowserBrave Then Return _UpgradeBuildGithubReleaseDownloadUrls($DownloadUrl, $BD_GithubDirectMirror, $BD_GithubJsDelivrMirror)
	If NormalizeBrowserType($Value) = $BrowserWhale Then Return _BrowserDownloadBuildWhaleDownloadUrls($DownloadUrl, $os)
	If NormalizeBrowserType($Value) = $BrowserCocCoc Then
		Local $CocCocUrls[1]
		$CocCocUrls[0] = $DownloadUrl
		Return $CocCocUrls
	EndIf
	If NormalizeBrowserType($Value) = $BrowserVivaldi Then Return _BrowserDownloadBuildVivaldiDownloadUrls($DownloadUrl)
	If NormalizeBrowserType($Value) = $BrowserOpera Then Return _BrowserDownloadBuildOperaDownloadUrls($DownloadUrl)
	If NormalizeBrowserType($Value) = $BrowserUngoogledChromium Or NormalizeBrowserType($Value) = $BrowserZen Or NormalizeBrowserType($Value) = $BrowserFloorp Or NormalizeBrowserType($Value) = $BrowserHelium Then Return _UpgradeBuildGithubReleaseDownloadUrls($DownloadUrl, $BD_GithubDirectMirror, $BD_GithubJsDelivrMirror)

	Local $aUrls[1]
	$aUrls[0] = $DownloadUrl
	Return $aUrls
EndFunc   ;==>BuildUrls

Func _BrowserDownloadBuildBraveDownloadUrls($GithubUrl)
	Return _UpgradeBuildGithubReleaseDownloadUrls($GithubUrl, $BD_GithubDirectMirror, $BD_GithubJsDelivrMirror)
EndFunc   ;==>BuildBraveDownloadUrls

Func _BrowserDownloadBuildWhaleDownloadUrls($ArchiveUrl, $os)
	Local $Urls[1], $UrlCount = 0
	If StringRegExp($ArchiveUrl, '(?i)^https://archive\.org/') Then
		Local $ArchiveUrls = _UpgradeBuildUrlProxyUrls($ArchiveUrl, $BD_GithubDirectMirror)
		For $i = 0 To UBound($ArchiveUrls) - 1
			_UpgradeAddUrl($Urls, $UrlCount, $ArchiveUrls[$i])
		Next
	Else
		_UpgradeAddUrl($Urls, $UrlCount, $ArchiveUrl)
	EndIf
	If $os = "win32" Then
		_UpgradeAddUrl($Urls, $UrlCount, $WhaleStandaloneX86Url)
	Else
		_UpgradeAddUrl($Urls, $UrlCount, $WhaleStandaloneX64Url)
	EndIf
	ReDim $Urls[$UrlCount]
	Return $Urls
EndFunc   ;==>BuildWhaleDownloadUrls

Func _BrowserDownloadBuildVivaldiDownloadUrls($OfficialUrl)
	Return _UpgradeBuildUrlProxyUrls($OfficialUrl, $BD_GithubDirectMirror)
EndFunc   ;==>BuildVivaldiDownloadUrls

Func _BrowserDownloadBuildOperaDownloadUrls($OfficialUrl)
	Return _UpgradeBuildUrlProxyUrls($OfficialUrl, $BD_GithubDirectMirror)
EndFunc   ;==>BuildOperaDownloadUrls

Func _BrowserDownloadDownloadAndExtract($aDownloadUrls, $TargetDir, $os, $Channel, $CurrentBrowserType, $Parent = 0)
	Local $TempDir = @TempDir & "\RunFirefox_BrowserDownload"
	If Not IsArray($aDownloadUrls) Or UBound($aDownloadUrls) = 0 Then Return SetError(1, 0, _t("CannotStartBrowserDownload", "无法开始下载浏览器。"))
	Local $DownloadUrl
	$DownloadUrl = $aDownloadUrls[0]
	Local $InstallerExt = _DownloadToolsGetUrlFileExtension($DownloadUrl)
	Local $Installer = $TempDir & "\BrowserSetup_" & NormalizeBrowserType($CurrentBrowserType) & "_" & $Channel & "_" & $os & $InstallerExt
	Local $ExtractDir = $TempDir & "\extract"
	Local $TargetBrowserPath = $TargetDir & "\" & GetBrowserExecutableName($CurrentBrowserType)
	Local $ret, $ExtractLog, $SevenZipExe
	Local $CopiedBrowserFiles = False, $TriedDownloadUrls = ""

	DirRemove($TempDir, 1)
	If Not FileExists($TempDir) Then DirCreate($TempDir)
	If Not FileExists($TempDir) Then Return SetError(1, 0, _t("CannotCreateTempDirectory", "无法创建临时目录。"))
	If Not FileExists($TargetDir) Then DirCreate($TargetDir)
	If Not FileExists($TargetDir) Then Return SetError(2, 0, _t("CannotCreateBrowserDirectory", "无法创建浏览器目标目录。"))

	_DownloadToolsShowDownloadProgress(_t("BrowserDownloadProgressTitle", "正在准备浏览器"), _t("DownloadingBrowser", "正在下载浏览器 ..."), $DownloadUrl, $Parent, _t("Cancel", "取消"))

	_UpgradePrioritizeGithubUrls($aDownloadUrls)
	Local $ExpectedSha256 = _BrowserDownloadGetExpectedSha256($CurrentBrowserType, $Channel, $os)
	Local $DownloadResult = _DownloadToolsDownloadUrls($aDownloadUrls, $Installer, _t("DownloadingBrowser", "正在下载浏览器 ..."), _t("BrowserDownloadProgressKnown", "已下载 {Downloaded} / {Total}"), _t("BrowserDownloadProgressUnknown", "已下载 %s"), $TriedDownloadUrls, 600000, $ExpectedSha256)
	Local $DownloadError = @error
	If $DownloadError = 2 Then
		_DownloadToolsCloseDownloadProgress()
		FileDelete($Installer)
		DirRemove($TempDir, 1)
		Return SetError(4, 0, _t("BrowserDownloadCancelled", "已取消浏览器下载。"))
	EndIf
	If Not $DownloadResult Or Not FileExists($Installer) Then
		_DownloadToolsCloseDownloadProgress()
		If $DownloadError = 5 Then
			Return SetError(5, 0, _BrowserDownloadBuildBrowserDownloadFailureDetail(_t("BrowserPackageHashMismatch", "浏览器压缩包 SHA-256 校验失败。") & @CRLF & @CRLF & _t("BrowserExtractLogKept", "诊断文件已保留在：\n%s", $TempDir), $TriedDownloadUrls, $Installer))
		EndIf
		DirRemove($TempDir, 1)
		Return SetError(5, 0, _BrowserDownloadBuildBrowserDownloadFailureDetail(_t("FailToDownloadBrowserInstaller", "下载浏览器安装包失败。"), $TriedDownloadUrls, $Installer))
	EndIf

	_DownloadToolsSetDownloadProgressBusy(_t("ExtractingBrowser", "正在解压浏览器，请稍候 ..."), _t("ExtractingBrowserDetail", "解压期间请不要关闭 {AppName}。"))
	$ExtractLog = $TempDir & "\extract.log"
	$SevenZipExe = _DownloadToolsPrepareSevenZipTool($TempDir)
	If @error Then
		_DownloadToolsCloseDownloadProgress()
		Return SetError(6, 0, _t("FailToExtractBrowserInstaller", "解压浏览器安装包失败。") & @CRLF & @CRLF & _t("BrowserExtractLogKept", "诊断文件已保留在：\n%s", $TempDir))
	EndIf
	If Not FileExists($ExtractDir) Then DirCreate($ExtractDir)
	$ret = _DownloadToolsRunArchiveExtraction($SevenZipExe, $Installer, $ExtractDir, $ExtractLog, $TempDir)
	_DownloadToolsCloseDownloadProgress()
	If $ret <> 0 Then
		Return SetError(6, $ret, _t("FailToExtractBrowserInstaller", "解压浏览器安装包失败。") & @CRLF & @CRLF & _t("BrowserExtractLogKept", "诊断文件已保留在：\n%s", $TempDir))
	EndIf

	; Xunlei and Coc Coc contain browser-internal archive resources; never
	; treat those files as installer wrappers after the application is unpacked.
	If NormalizeBrowserType($CurrentBrowserType) <> $BrowserXunlei And NormalizeBrowserType($CurrentBrowserType) <> $BrowserCocCoc Then _
		_DownloadToolsExtractNestedBrowserArchives($SevenZipExe, $ExtractDir, $TempDir)
	Local $ExtractedBrowserPath = _BrowserDownloadFindBrowserExecutableForType($ExtractDir, $CurrentBrowserType)
	If $ExtractedBrowserPath Then
		Local $ExtractedBrowserDir, $ExtractedBrowserFile
		SplitPath($ExtractedBrowserPath, $ExtractedBrowserDir, $ExtractedBrowserFile)
		$CopiedBrowserFiles = DirCopy($ExtractedBrowserDir, $TargetDir, 1)
		$TargetBrowserPath = $TargetDir & "\" & $ExtractedBrowserFile
	EndIf

	If Not $CopiedBrowserFiles Or Not FileExists($TargetBrowserPath) Then
		Return SetError(6, 0, _t("FailToExtractBrowserInstaller", "解压浏览器安装包失败。") & @CRLF & @CRLF & _t("BrowserExtractLogKept", "诊断文件已保留在：\n%s", $TempDir))
	EndIf

	FileDelete($Installer)
	DirRemove($TempDir, 1)
	Return $TargetBrowserPath
EndFunc   ;==>DownloadAndExtract

Func _BrowserDownloadBuildBrowserDownloadFailureDetail($BaseMessage, $TriedDownloadUrls, $Installer)
	Local $Detail = $BaseMessage
	If $TriedDownloadUrls <> "" Then
		$Detail &= @CRLF & @CRLF & _t("TriedDownloadUrls", "尝试下载地址：") & @CRLF & $TriedDownloadUrls
	EndIf
	If $Installer <> "" Then
		$Detail &= @CRLF & @CRLF & _t("BrowserInstallerSavePath", "安装包保存路径：") & @CRLF & $Installer
	EndIf
	Return $Detail
EndFunc   ;==>BuildBrowserDownloadFailureDetail

Func _BrowserDownloadBrowserExecutableExistsInDir($Dir, $BrowserTypeValue)
	Local $Candidates = StringSplit(GetBrowserExecutableCandidates($BrowserTypeValue), "|", 2)
	For $i = 0 To UBound($Candidates) - 1
		If FileExists($Dir & "\" & $Candidates[$i]) Then Return True
	Next
	Return False
EndFunc   ;==>BrowserExecutableExistsInDir

Func _BrowserDownloadFindCentBrowserExecutable($Dir)
	Local $Found = _BrowserDownloadFindCentBrowserExecutableWithMarker($Dir)
	If $Found Then Return $Found
	Return _DownloadToolsFindBrowserExecutable($Dir, "chrome.exe")
EndFunc   ;==>FindCentBrowserExecutable

Func _BrowserDownloadFindCentBrowserExecutableWithMarker($Dir, $Depth = 6)
	If FileExists($Dir & "\chrome.exe") And _BrowserDownloadIsCentBrowserExtractDir($Dir) Then Return $Dir & "\chrome.exe"
	If $Depth <= 0 Then Return ""

	Local $hSearch = FileFindFirstFile($Dir & "\*")
	If $hSearch = -1 Then Return ""

	Local $Name, $Path, $Found
	While 1
		$Name = FileFindNextFile($hSearch)
		If @error Then ExitLoop
		$Path = $Dir & "\" & $Name
		If StringInStr(FileGetAttrib($Path), "D") Then
			$Found = _BrowserDownloadFindCentBrowserExecutableWithMarker($Path, $Depth - 1)
			If $Found Then
				FileClose($hSearch)
				Return $Found
			EndIf
		EndIf
	WEnd

	FileClose($hSearch)
	Return ""
EndFunc   ;==>FindCentBrowserExecutableWithMarker

Func _BrowserDownloadIsCentBrowserExtractDir($Dir)
	If FileExists($Dir & "\safemode.bat") Then Return True

	Local $Identity = GetExecutableIdentityText($Dir & "\chrome.exe")
	If StringInStr($Identity, "cent browser") Or StringInStr($Identity, "centbrowser") Then Return True
	Return False
EndFunc   ;==>IsCentBrowserExtractDir

Func _BrowserDownloadFindBrowserExecutableForType($Dir, $BrowserTypeValue)
	If NormalizeBrowserType($BrowserTypeValue) = $BrowserCent Then Return _BrowserDownloadFindCentBrowserExecutable($Dir)

	Local $Candidates = StringSplit(GetBrowserExecutableCandidates($BrowserTypeValue), "|", 2)
	Local $Found
	For $i = 0 To UBound($Candidates) - 1
		$Found = _DownloadToolsFindBrowserExecutable($Dir, $Candidates[$i])
		If $Found Then Return $Found
	Next
	Return ""
EndFunc   ;==>FindBrowserExecutableForType
