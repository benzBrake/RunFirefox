#include-once
#include "DownloadTools.au3"
#include "JSON.au3"
#include "UpgradeHelper.au3"

Global $BD_AppVersion = "", $BD_Locale = "", $BD_GithubDirectMirror = "", $BD_GithubJsDelivrMirror = ""
Global $BD_LoadHandle = 0, $BD_LoadFile = "", $BD_LoadBrowserType = "", $BD_LoadChannel = "", $BD_LoadKind = "", $BD_LoadBraveUrls = 0, $BD_LoadBraveIndex = 0
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
Global Const $HeliumLatestReleaseUrl = "https://github.com/" & $HeliumRepo & "/releases/latest"
Global Const $HeliumLatestReleaseApiUrl = "https://api.github.com/repos/" & $HeliumRepo & "/releases/latest"
Global Const $WhaleStandaloneX64Url = "https://installer-whale.pstatic.net/downloads/sa_installers/WhaleSetupX64.exe"
Global Const $WhaleLatestVersionUrl = "https://cv.whale.naver.com/version/latest_version"
Global Const $CentBrowserDownloadPageUrl = "https://www.centbrowser.com/"
Global Const $VivaldiDownloadPageUrl = "https://vivaldi.com/download/"
Global Const $VivaldiUpdateX64Url = "https://update.vivaldi.com/update/1.0/public/appcast.x64.xml"
Global Const $OperaDesktopFtpBaseUrl = "https://get.opera.com/ftp/pub"
Global Const $OperaDownloadPageUrl = "https://www.opera.com/download"
Global Const $BraveRepo = "portapps/brave-portable"
Global Const $BraveLatestReleaseApiUrl = "https://api.github.com/repos/" & $BraveRepo & "/releases/latest"
Global Const $UngoogledChromiumRepo = "ungoogled-software/ungoogled-chromium-windows"
Global Const $UngoogledChromiumGitCodeTagsUrl = "https://gitcode.com/gh_mirrors/un/ungoogled-chromium-windows/tags"
Global Const $UngoogledChromiumLatestReleaseApiUrl = "https://api.github.com/repos/" & $UngoogledChromiumRepo & "/releases/latest"
Global Const $BraveVersionDataUrl = "https://data.jsdelivr.com/v1/package/gh/" & $BraveRepo
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
Global $VivaldiReleaseInfoLoaded = False, $VivaldiReleaseVersion = "", $VivaldiDownloadUrl = ""
Global $OperaStableInfoLoaded = False, $OperaStableVersion = "", $OperaBetaInfoLoaded = False, $OperaBetaVersion = "", $OperaDevInfoLoaded = False, $OperaDevVersion = ""
Global $WhaleReleaseInfoLoaded = False, $WhaleReleaseVersion = ""
Global $BraveReleaseInfoLoaded = False, $BraveReleaseTag = "", $BraveDownloadUrl = ""
Global $XunleiReleaseInfoLoaded = False, $XunleiDownloadUrl = ""
Global $UngoogledChromiumReleaseInfoLoaded = False, $UngoogledChromiumReleaseTag = ""
Global $BraveVersionApiUrls = 0, $BraveVersionApiIndex = 0
Global $ChromeStableVersion = "", $ChromeStableDownloadUrl = "", $ChromeBetaVersion = "", $ChromeBetaDownloadUrl = "", $ChromeDevVersion = "", $ChromeDevDownloadUrl = "", $ChromeCanaryVersion = "", $ChromeCanaryDownloadUrl = ""
Func _BrowserDownloadConfigure($AppVersion, $Locale, $GithubDirectMirror, $GithubJsDelivrMirror)
    $BD_AppVersion = $AppVersion
    $BD_Locale = $Locale
	$BD_GithubDirectMirror = $GithubDirectMirror
	$BD_GithubJsDelivrMirror = $GithubJsDelivrMirror
EndFunc

Func _BrowserDownloadGetLatestVersion($BrowserType, $Channel)
	$BrowserType = NormalizeBrowserType($BrowserType)
	If $Channel = "default" Then $Channel = "release"

	If $BrowserType = $BrowserZen Then Return _BrowserDownloadGetLatestZenVersion($Channel)
	If $BrowserType = $BrowserFloorp Then Return _BrowserDownloadGetLatestFloorpVersion()
	If $BrowserType = $BrowserWaterfox Then Return _BrowserDownloadGetLatestWaterfoxVersion()
	If $BrowserType = $BrowserLibreWolf Then Return _BrowserDownloadGetLatestLibreWolfVersion()
	If $BrowserType = $BrowserTurbo Then Return _BrowserDownloadGetLatestTurboVersion()
	If $BrowserType = $BrowserHelium Then Return _BrowserDownloadGetLatestHeliumVersion()
	If $BrowserType = $BrowserCent Then Return _BrowserDownloadGetLatestCentVersion()
	If $BrowserType = $BrowserVivaldi Then Return _BrowserDownloadGetLatestVivaldiVersion()
	If $BrowserType = $BrowserWhale Then Return _BrowserDownloadGetLatestWhaleVersion()
	If $BrowserType = $BrowserBrave Then Return _BrowserDownloadGetLatestBraveVersion()
	If $BrowserType = $BrowserXunlei Then Return ""
	If $BrowserType = $BrowserUngoogledChromium Then Return _BrowserDownloadGetLatestUngoogledChromiumVersion()
	If $BrowserType = $BrowserOpera Then Return _BrowserDownloadGetLatestOperaVersion($Channel)
	If IsChromeBrowser($BrowserType) Then Return _BrowserDownloadGetChromeVersionCache($Channel)
	Return _BrowserDownloadGetLatestFirefoxVersion($Channel)
EndFunc

Func _BrowserDownloadIsVersionCached($BrowserType, $Channel)
	$BrowserType = NormalizeBrowserType($BrowserType)
	If $BrowserType = $BrowserTurbo Then Return $TurboReleaseInfoLoaded
	If $BrowserType = $BrowserHelium Then Return $HeliumReleaseInfoLoaded
	If $BrowserType = $BrowserCent Then Return $CentReleaseInfoLoaded
	If $BrowserType = $BrowserVivaldi Then Return $VivaldiReleaseInfoLoaded
	If $BrowserType = $BrowserWhale Then Return $WhaleReleaseInfoLoaded
	If $BrowserType = $BrowserBrave Then Return $BraveReleaseInfoLoaded
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
	Switch NormalizeBrowserType($BrowserType)
		Case $BrowserFirefox, $BrowserZen, $BrowserFloorp, $BrowserWaterfox, $BrowserTurbo, $BrowserHelium, $BrowserWhale, $BrowserVivaldi, $BrowserBrave, $BrowserXunlei, $BrowserUngoogledChromium
			Return True
		Case $BrowserChrome
			Return _BrowserDownloadNormalizeChromeChannel($Channel) <> "canary"
	EndSwitch
	Return False
EndFunc

Func _BrowserDownloadGetPageUrl($BrowserType, $Channel)
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

Func _BrowserDownloadIsVersionLoadActive($BrowserType, $Channel)
	Return $BD_LoadHandle <> 0 And $BD_LoadBrowserType = NormalizeBrowserType($BrowserType) And $BD_LoadChannel = $Channel
EndFunc

Func _BrowserDownloadStartVersionLoad($BrowserType, $Channel, $Os = "win64")
	$BrowserType = NormalizeBrowserType($BrowserType)
	If $Channel = "default" Then $Channel = "release"
	If _BrowserDownloadIsVersionLoadActive($BrowserType, $Channel) Then Return True
	_BrowserDownloadCancelVersionLoad()

	$BD_LoadBrowserType = $BrowserType
	$BD_LoadChannel = $Channel
	$BD_LoadFile = @TempDir & "\\RunFirefox_BrowserVersion_" & @AutoItPID & ".tmp"
	FileDelete($BD_LoadFile)

	If $BrowserType = $BrowserTurbo Then
		$BD_LoadKind = "inet"
		$BD_LoadHandle = InetGet($TurboDownloadInfoUrl, $BD_LoadFile, 1, 1)
	ElseIf $BrowserType = $BrowserHelium Then
		$BD_LoadKind = "inet"
		$BD_LoadHandle = InetGet($HeliumLatestReleaseUrl, $BD_LoadFile, 1, 1)
	ElseIf $BrowserType = $BrowserCent Then
		$BD_LoadKind = "inet"
		$BD_LoadHandle = InetGet($CentBrowserDownloadPageUrl, $BD_LoadFile, 1, 1)
	ElseIf $BrowserType = $BrowserVivaldi Then
		$BD_LoadKind = "inet"
		$BD_LoadHandle = InetGet($VivaldiDownloadPageUrl, $BD_LoadFile, 1, 1)
	ElseIf $BrowserType = $BrowserWhale Then
		$BD_LoadKind = "inet"
		$BD_LoadHandle = InetGet($WhaleLatestVersionUrl, $BD_LoadFile, 1, 1)
	ElseIf $BrowserType = $BrowserBrave Then
		$BD_LoadKind = "inet"
		$BD_LoadBraveUrls = _UpgradeBuildGithubDirectUrls($BraveLatestReleaseApiUrl, $BD_GithubDirectMirror)
		$BD_LoadBraveIndex = 0
		$BD_LoadHandle = InetGet($BD_LoadBraveUrls[$BD_LoadBraveIndex], $BD_LoadFile, 1, 1)
	ElseIf $BrowserType = $BrowserXunlei Then
		$BD_LoadKind = "inet"
		$BD_LoadHandle = InetGet($XunleiVersionDataUrl, $BD_LoadFile, 1, 1)
	ElseIf $BrowserType = $BrowserUngoogledChromium Then
		$BD_LoadKind = "inet"
		$BD_LoadHandle = InetGet($UngoogledChromiumGitCodeTagsUrl, $BD_LoadFile, 1, 1)
	ElseIf $BrowserType = $BrowserOpera Then
		$BD_LoadKind = "inet"
		$BD_LoadHandle = InetGet(_BrowserDownloadGetOperaListingUrl($Channel), $BD_LoadFile, 1, 1)
	ElseIf IsChromeBrowser($BrowserType) Then
		$BD_LoadKind = "chrome"
		$BD_LoadHandle = _BrowserDownloadStartChromeVersionLoadProcess($Channel, $Os, $BD_LoadFile)
	Else
		Local $Url = $FirefoxVersionUrl
		If $BrowserType = $BrowserZen Then $Url = $ZenUpdateBaseUrl & "/" & _BrowserDownloadGetZenUpdateChannel($Channel) & "/update.xml"
		If $BrowserType = $BrowserFloorp Then $Url = $FloorpLatestReleaseUrl
		If $BrowserType = $BrowserWaterfox Then $Url = $WaterfoxDownloadPageUrl
		If $BrowserType = $BrowserLibreWolf Then $Url = $LibreWolfLatestReleaseApiUrl
		$BD_LoadKind = "inet"
		$BD_LoadHandle = InetGet($Url, $BD_LoadFile, 1, 1)
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

	If Not InetGetInfo($BD_LoadHandle, 2) Then Return 0
	Local $DownloadSuccessful = InetGetInfo($BD_LoadHandle, 3)
	$BrowserType = $BD_LoadBrowserType
	$Channel = $BD_LoadChannel
	InetClose($BD_LoadHandle)
	$BD_LoadHandle = 0
	If Not $DownloadSuccessful And $BrowserType = $BrowserBrave And IsArray($BD_LoadBraveUrls) And $BD_LoadBraveIndex + 1 < UBound($BD_LoadBraveUrls) Then
		$BD_LoadBraveIndex += 1
		$BD_LoadHandle = InetGet($BD_LoadBraveUrls[$BD_LoadBraveIndex], $BD_LoadFile, 1, 1)
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
				$Loaded = _BrowserDownloadCacheVivaldiReleaseInfo($Content)
			ElseIf $BrowserType = $BrowserWhale Then
				$Loaded = _BrowserDownloadCacheWhaleReleaseInfo($Content)
			ElseIf $BrowserType = $BrowserBrave Then
				$Loaded = _BrowserDownloadCacheBraveReleaseInfo($Content)
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
	_BrowserDownloadClearVersionLoad()
	If $Loaded Then Return 1
	Return -1
EndFunc

Func _BrowserDownloadCancelVersionLoad()
	If $BD_LoadHandle Then
		If $BD_LoadKind = "chrome" Then
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
	$BD_LoadKind = ""
	$BD_LoadBraveUrls = 0
	$BD_LoadBraveIndex = 0
EndFunc

Func _BrowserDownloadGetGithubLatestReleaseApi($ApiUrl)
	Local $Urls = _UpgradeBuildGithubDirectUrls($ApiUrl, $BD_GithubDirectMirror)
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

	Local $sVersions = BinaryToString(InetRead($FirefoxVersionUrl, 1), 4)
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
	Local $sUpdateXml = BinaryToString(InetRead($ZenUpdateBaseUrl & "/" & $Channel & "/update.xml", 1), 4)
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

	Local $Content = BinaryToString(InetRead($WaterfoxDownloadPageUrl, 1), 4)
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
	Local $Content = BinaryToString(InetRead($TurboDownloadInfoUrl, 1), 4)
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
	Local $Content = _BrowserDownloadGetGithubLatestReleaseApi($HeliumLatestReleaseApiUrl)
	If $Content = "" Then Return SetError(1, 0, False)
	Return _BrowserDownloadCacheHeliumReleaseInfo($Content)
EndFunc   ;==>GetHeliumReleasePage

Func _BrowserDownloadCacheHeliumReleaseInfo($Content)
	$HeliumReleaseInfoLoaded = False
	$HeliumReleaseTag = ""

	Local $Match = StringRegExp($Content, '(?i)"tag_name"\s*:\s*"([^"]+)"', 1)
	If @error Then $Match = StringRegExp($Content, '(?i)/' & $HeliumRepo & '/releases/tag/([^"#?<>\s]+)', 1)
	If @error Then Return False

	$HeliumReleaseTag = $Match[0]
	$HeliumReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheHeliumReleaseInfo

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

	Local $Content = BinaryToString(InetRead($CentBrowserDownloadPageUrl, 1), 4)
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

Func _BrowserDownloadGetVivaldiReleasePage()
	If $VivaldiReleaseInfoLoaded Then Return True

	Local $Content = BinaryToString(InetRead($VivaldiDownloadPageUrl, 1), 4)
	If @error Or $Content = "" Then Return SetError(1, 0, False)

	Return _BrowserDownloadCacheVivaldiReleaseInfo($Content)
EndFunc   ;==>GetVivaldiReleasePage

Func _BrowserDownloadGetVivaldiReleaseFallback()
	Local $Content = _DownloadToolsHttpGetText($VivaldiUpdateX64Url, "RunFirefox/" & $BD_AppVersion, "application/xml")
	If @error Or $Content = "" Then Return False

	Local $Match = StringRegExp($Content, '(?is)<enclosure[^>]+url="(https://downloads\.vivaldi\.com/(?:stable|stable-auto)/Vivaldi\.([0-9][0-9.]*)\.x64\.exe)"', 1)
	If @error Or Not IsArray($Match) Then Return False
	$VivaldiDownloadUrl = _BrowserDownloadDecodeXmlAttribute($Match[0])
	$VivaldiReleaseVersion = $Match[1]
	$VivaldiReleaseInfoLoaded = True
	Return True
EndFunc   ;==>GetVivaldiReleaseFallback

Func _BrowserDownloadCacheVivaldiReleaseInfo($Content)
	$VivaldiReleaseInfoLoaded = False
	$VivaldiReleaseVersion = ""
	$VivaldiDownloadUrl = ""

	Local $Match = StringRegExp($Content, '(?is)(https?://downloads\.vivaldi\.com/stable/Vivaldi\.([0-9][0-9.]*)\.x64\.exe)', 1)
	If @error Then Return False

	$VivaldiDownloadUrl = _BrowserDownloadDecodeXmlAttribute($Match[0])
	$VivaldiReleaseVersion = $Match[1]
	If $VivaldiDownloadUrl = "" Or $VivaldiReleaseVersion = "" Then Return False

	$VivaldiReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheVivaldiReleaseInfo

Func _BrowserDownloadGetLatestVivaldiVersion()
	If $VivaldiReleaseVersion = "" Then Return ""
	Return $VivaldiReleaseVersion
EndFunc   ;==>GetLatestVivaldiVersion

Func _BrowserDownloadNormalizeOperaChannel($Channel)
	Switch StringLower($Channel)
		Case "beta"
			Return "beta"
		Case "dev"
			Return "dev"
	EndSwitch
	Return "stable"
EndFunc   ;==>NormalizeOperaChannel

Func _BrowserDownloadGetOperaChannelDir($Channel)
	Switch _BrowserDownloadNormalizeOperaChannel($Channel)
		Case "beta"
			Return "opera-beta"
		Case "dev"
			Return "opera-developer"
	EndSwitch
	Return "opera"
EndFunc   ;==>GetOperaChannelDir

Func _BrowserDownloadGetOperaListingUrl($Channel)
	Return $OperaDesktopFtpBaseUrl & "/" & _BrowserDownloadGetOperaChannelDir($Channel) & "/desktop/"
EndFunc   ;==>GetOperaListingUrl

Func _BrowserDownloadIsOperaInfoLoaded($Channel)
	Switch _BrowserDownloadNormalizeOperaChannel($Channel)
		Case "beta"
			Return $OperaBetaInfoLoaded
		Case "dev"
			Return $OperaDevInfoLoaded
	EndSwitch
	Return $OperaStableInfoLoaded
EndFunc   ;==>IsOperaInfoLoaded

Func _BrowserDownloadGetOperaReleasePage($Channel)
	If _BrowserDownloadIsOperaInfoLoaded($Channel) Then Return True
	Local $Content = BinaryToString(InetRead(_BrowserDownloadGetOperaListingUrl($Channel), 1), 4)
	If @error Or $Content = "" Then Return SetError(1, 0, False)
	Return _BrowserDownloadCacheOperaReleaseInfo($Channel, $Content)
EndFunc   ;==>GetOperaReleasePage

Func _BrowserDownloadCacheOperaReleaseInfo($Channel, $Content)
	$Channel = _BrowserDownloadNormalizeOperaChannel($Channel)

	; The FTP listing is sorted lexicographically, so 99.x sorts after 100.x;
	; compare version folders numerically to find the newest release.
	Local $Versions = StringRegExp($Content, '(?i)href="([0-9]+(?:\.[0-9]+)+)/"', 3)
	If @error Or Not IsArray($Versions) Then Return False

	Local $Latest = ""
	For $i = 0 To UBound($Versions) - 1
		If $Latest = "" Or VersionCompare($Versions[$i], $Latest) > 0 Then $Latest = $Versions[$i]
	Next
	If $Latest = "" Then Return False

	Switch $Channel
		Case "beta"
			$OperaBetaVersion = $Latest
			$OperaBetaInfoLoaded = True
		Case "dev"
			$OperaDevVersion = $Latest
			$OperaDevInfoLoaded = True
		Case Else
			$OperaStableVersion = $Latest
			$OperaStableInfoLoaded = True
	EndSwitch
	Return True
EndFunc   ;==>CacheOperaReleaseInfo

Func _BrowserDownloadGetLatestOperaVersion($Channel)
	Switch _BrowserDownloadNormalizeOperaChannel($Channel)
		Case "beta"
			If Not $OperaBetaInfoLoaded Then Return ""
			Return $OperaBetaVersion
		Case "dev"
			If Not $OperaDevInfoLoaded Then Return ""
			Return $OperaDevVersion
	EndSwitch
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
	Return _BrowserDownloadGetOperaListingUrl($Channel) & $Version & "/win/Opera_" & $Version & "_Setup_x64.exe"
EndFunc   ;==>BuildOperaDownloadUrl

Func _BrowserDownloadCacheWhaleReleaseInfo($Content)
	$WhaleReleaseInfoLoaded = False
	$WhaleReleaseVersion = ""

	Local $Match = StringRegExp($Content, '(?i)"@version"\s*:\s*"([0-9]+(?:\.[0-9]+)+)"', 1)
	If @error Or Not IsArray($Match) Then Return False
	$WhaleReleaseVersion = StringStripWS($Match[0], 3)
	If $WhaleReleaseVersion = "" Then Return False
	$WhaleReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheWhaleReleaseInfo

Func _BrowserDownloadGetLatestWhaleVersion()
	If $WhaleReleaseVersion = "" Then Return ""
	Return $WhaleReleaseVersion
EndFunc   ;==>GetLatestWhaleVersion

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
	If $BraveReleaseInfoLoaded Then Return True
	Local $Content = _DownloadToolsHttpGetText($BraveVersionDataUrl, "RunFirefox/" & $BD_AppVersion, "application/json")
	If $Content <> "" And _BrowserDownloadCacheBraveReleaseInfo($Content) Then Return True
	; Keep the API as a last resort; this request itself uses configured GitHub mirrors.
	$Content = _BrowserDownloadGetGithubLatestReleaseApi($BraveLatestReleaseApiUrl)
	If $Content = "" Then Return SetError(1, 0, False)
	Return _BrowserDownloadCacheBraveReleaseInfo($Content)
EndFunc   ;==>GetBraveReleasePage

Func _BrowserDownloadGetXunleiReleasePage()
	If $XunleiReleaseInfoLoaded Then Return True
	Local $Content = BinaryToString(InetRead($XunleiVersionDataUrl, 1), 4)
	If @error Or $Content = "" Then Return False
	Return _BrowserDownloadCacheXunleiReleaseInfo($Content)
EndFunc   ;==>GetXunleiReleasePage

Func _BrowserDownloadCacheBraveReleaseInfo($Content)
	$BraveReleaseInfoLoaded = False
	$BraveReleaseTag = ""
	$BraveDownloadUrl = ""

	Local $TagMatch = StringRegExp($Content, '(?i)"tag_name"\s*:\s*"([^"]+)"', 1)
	If @error Or Not IsArray($TagMatch) Then $TagMatch = StringRegExp($Content, '(?i)"versions"\s*:\s*\[\s*"([^"]+)"', 1)
	If @error Or Not IsArray($TagMatch) Then Return False
	$BraveReleaseTag = $TagMatch[0]
	Local $AssetMatch = StringRegExp($Content, '(?i)"browser_download_url"\s*:\s*"(https://github\.com/' & $BraveRepo & '/releases/download/[^"/]+/brave-portable-win64-[^"]+\.7z)"', 1)
	If Not @error And IsArray($AssetMatch) Then
		$BraveDownloadUrl = $AssetMatch[0]
	Else
		$BraveDownloadUrl = "https://github.com/" & $BraveRepo & "/releases/download/" & $BraveReleaseTag & "/brave-portable-win64-" & $BraveReleaseTag & ".7z"
	EndIf
	$BraveReleaseInfoLoaded = True
	Return True
EndFunc   ;==>CacheBraveReleaseInfo

Func _BrowserDownloadGetLatestBraveVersion()
	If $BraveReleaseTag = "" Then Return ""
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
	Local $Version = _BrowserDownloadGetLatestVivaldiVersion()
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
	If $VivaldiDownloadUrl = "" Then
		If Not _BrowserDownloadGetVivaldiReleasePage() Then
			If Not _BrowserDownloadGetVivaldiReleaseFallback() Then Return SetError(1, 0, "")
		EndIf
	EndIf
	If $VivaldiDownloadUrl = "" Then Return SetError(2, 0, "")
	Return $VivaldiDownloadUrl
EndFunc   ;==>BuildVivaldiDownloadUrl

Func _BrowserDownloadBuildBraveDownloadUrl($Channel, $os)
	If $os <> "win64" Then Return SetError(1, 0, "")
	If $BraveDownloadUrl = "" Then
		If Not _BrowserDownloadGetBraveReleasePage() Then Return SetError(1, 0, "")
	EndIf
	If Not StringRegExp($BraveDownloadUrl, "(?i)^https://github\.com/" & $BraveRepo & "/releases/download/[^/]+/brave-portable-win64-[^/]+\.7z$") Then Return SetError(2, 0, "")
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
	If $os <> "win64" Then Return SetError(1, 0, "")
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
	Local $oError = ObjEvent("AutoIt.Error", "_BrowserDownloadChromeComError")
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

Func _BrowserDownloadChromeComError($oError)
	Return
EndFunc   ;==>ChromeComError

Func _BrowserDownloadBuildBrowserDownloadUrl($Value, $Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserUngoogledChromium Then Return _BrowserDownloadBuildUngoogledChromiumDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserTurbo Then Return _BrowserDownloadBuildTurboDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserHelium Then Return _BrowserDownloadBuildHeliumDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserWhale Then Return _BrowserDownloadBuildWhaleDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserCent Then Return _BrowserDownloadBuildCentDownloadUrl($Channel, $os)
	If NormalizeBrowserType($Value) = $BrowserVivaldi Then Return _BrowserDownloadBuildVivaldiDownloadUrl($Channel, $os)
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

	If NormalizeBrowserType($Value) = $BrowserUngoogledChromium Or NormalizeBrowserType($Value) = $BrowserZen Or NormalizeBrowserType($Value) = $BrowserFloorp Or NormalizeBrowserType($Value) = $BrowserHelium Or NormalizeBrowserType($Value) = $BrowserBrave Then Return _UpgradeBuildGithubReleaseDownloadUrls($DownloadUrl, $BD_GithubDirectMirror, $BD_GithubJsDelivrMirror)

	Local $aUrls[1]
	$aUrls[0] = $DownloadUrl
	Return $aUrls
EndFunc   ;==>BuildUrls

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

	Local $DownloadResult = _DownloadToolsDownloadUrls($aDownloadUrls, $Installer, _t("DownloadingBrowser", "正在下载浏览器 ..."), _t("BrowserDownloadProgressKnown", "已下载 {Downloaded} / {Total}"), _t("BrowserDownloadProgressUnknown", "已下载 %s"), $TriedDownloadUrls)
	If @error = 2 Then
		_DownloadToolsCloseDownloadProgress()
		FileDelete($Installer)
		DirRemove($TempDir, 1)
		Return SetError(4, 0, _t("BrowserDownloadCancelled", "已取消浏览器下载。"))
	EndIf
	If Not $DownloadResult Or Not FileExists($Installer) Then
		_DownloadToolsCloseDownloadProgress()
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

	; Xunlei's payload contains browser-internal ZIP resources (for example
	; Extensions\xblock.zip); never treat those files as installer wrappers.
	If NormalizeBrowserType($CurrentBrowserType) <> $BrowserXunlei Then _
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
