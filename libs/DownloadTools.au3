#include-once
#include <GUIConstantsEx.au3>
#include <Crypt.au3>
#include <ProgressConstants.au3>
#include <WindowsConstants.au3>

Global $DT_hProgress = 0, $DT_idStatus = 0, $DT_idDetail = 0, $DT_idBar = 0, $DT_idCancel = 0
Global $DT_Cancelled = False, $DT_CanCancel = False, $DT_PreviousGuiMode = -1
Global $DT_ProgressMarquee = False
Global $DT_CurlPath = "", $DT_CurlDetected = False
Global $DT_DownloadThreads = 3, $DT_ProxyType = "direct", $DT_ProxyServer = "", $DT_ProxyPort = 0
Global $DT_WinHttpProxySession = 0, $DT_SystemProxyLastStatus = "not-resolved"
Global $DT_Language = "", $DT_GithubDirectMirror = "", $DT_GithubJsDelivrMirror = "", $DT_GithubApiMirror = ""
Global $DT_AsyncUrls = 0, $DT_AsyncIndex = -1, $DT_AsyncDestination = ""
Global $DT_CurlRequests = ObjCreate("Scripting.Dictionary"), $DT_CurlRequestId = 0

Global Const $DT_DEFAULT_GITHUB_JSDELIVR_MIRROR = "https://cdn.jsdmirror.com/gh/"
Global Const $DT_DEFAULT_GITHUB_DIRECT_MIRROR = "https://v6.gh-proxy.org/"
Global Const $DT_DEFAULT_GITHUB_API_MIRROR = "https://gh.dpik.top/"
Global Const $DT_DEFAULT_GENERIC_URL_PROXY = "https://box.w0x7ce.eu/proxy/"
Global Const $DT_FALLBACK_GENERIC_URL_PROXY = "https://oo6.cc/proxy/"

Func _DownloadToolsConfigure($DownloadThreads = 3, $ProxyType = "direct", $ProxyServer = "", $ProxyPort = 0, $Language = "", $GithubDirectMirror = "", $GithubJsDelivrMirror = "", $GithubApiMirror = "")
	$DT_DownloadThreads = Int($DownloadThreads)
	If $DT_DownloadThreads < 1 Or $DT_DownloadThreads > 10 Then $DT_DownloadThreads = 3
	$DT_ProxyType = StringLower(StringStripWS($ProxyType, 3))
	If $DT_ProxyType <> "http" And $DT_ProxyType <> "socks5" And $DT_ProxyType <> "system" Then $DT_ProxyType = "direct"
	$DT_ProxyServer = StringStripWS($ProxyServer, 3)
	$DT_ProxyPort = Int($ProxyPort)
	_DownloadToolsSetRouting($Language, $GithubDirectMirror, $GithubJsDelivrMirror, $GithubApiMirror)
	If $DT_ProxyType = "direct" Then HttpSetProxy(1)
EndFunc   ;==>Configure

Func _DownloadToolsClose()
	Local $Requests = $DT_CurlRequests.Keys
	For $Request In $Requests
		_DownloadToolsCurlCancel($Request)
	Next
	If $DT_WinHttpProxySession Then
		DllCall("winhttp.dll", "bool", "WinHttpCloseHandle", "ptr", $DT_WinHttpProxySession)
		$DT_WinHttpProxySession = 0
	EndIf
EndFunc   ;==>Close

Func _DownloadToolsSetRouting($Language = "", $GithubDirectMirror = "", $GithubJsDelivrMirror = "", $GithubApiMirror = "")
	$DT_Language = StringLower(StringReplace(StringStripWS($Language, 3), "_", "-"))
	$DT_GithubDirectMirror = _DownloadToolsNormalizeMirror($GithubDirectMirror)
	$DT_GithubJsDelivrMirror = _DownloadToolsNormalizeMirror($GithubJsDelivrMirror)
	$DT_GithubApiMirror = _DownloadToolsNormalizeMirror($GithubApiMirror)
EndFunc   ;==>SetRouting

Func _DownloadToolsNormalizeMirror($Mirror)
	$Mirror = StringStripWS($Mirror, 3)
	If $Mirror = "" Then Return ""
	If StringRight($Mirror, 1) <> "/" Then $Mirror &= "/"
	Return $Mirror
EndFunc   ;==>NormalizeMirror

Func _DownloadToolsIsSimplifiedChinese()
	Return $DT_Language = "zh-cn"
EndFunc   ;==>IsSimplifiedChinese

Func _DownloadToolsAddCandidate(ByRef $Urls, ByRef $Count, $Url)
	If $Url = "" Then Return
	For $i = 0 To $Count - 1
		If $Urls[$i] = $Url Then Return
	Next
	ReDim $Urls[$Count + 1]
	$Urls[$Count] = $Url
	$Count += 1
EndFunc   ;==>AddCandidate

Func _DownloadToolsAddGenericProxyCandidates(ByRef $Urls, ByRef $Count, $Url, $Language, $ConfiguredProxy = "")
	If $Language = "zh-cn" Then
		_DownloadToolsAddCandidate($Urls, $Count, $DT_DEFAULT_GENERIC_URL_PROXY & $Url)
		_DownloadToolsAddCandidate($Urls, $Count, $DT_FALLBACK_GENERIC_URL_PROXY & $Url)
		Return
	EndIf
	$ConfiguredProxy = _DownloadToolsNormalizeMirror($ConfiguredProxy)
	If $ConfiguredProxy <> "" Then _DownloadToolsAddCandidate($Urls, $Count, $ConfiguredProxy & $Url)
EndFunc   ;==>AddGenericProxyCandidates

Func _DownloadToolsIsGithubApiUrl($Url)
	Return StringRegExp($Url, "(?i)^https?://api\.github\.com/")
EndFunc   ;==>IsGithubApiUrl

Func _DownloadToolsIsGithubUrl($Url)
	Return StringRegExp($Url, "(?i)^https?://(?:api\.github\.com|github\.com|raw\.githubusercontent\.com)/")
EndFunc   ;==>IsGithubUrl

Func _DownloadToolsBuildGithubJsMirrorUrl($Url)
	Local $Lower = StringLower($Url), $Path
	If StringRegExp($Lower, "^https?://cdn\.jsdelivr\.net/gh/") Then
		Return StringRegExpReplace($Url, "(?i)^https?://cdn\.jsdelivr\.net/gh/", "https://cdn.jsdmirror.com/gh/")
	EndIf
	If StringRegExp($Lower, "^https?://cdn\.jsdmirror\.com/gh/") Then Return $Url
	If StringRegExp($Lower, "^https?://raw\.githubusercontent\.com/[^/]+/[^/]+/") Then
		$Path = StringRegExpReplace($Url, "(?i)^https?://raw\.githubusercontent\.com/", "")
		Local $Parts = StringSplit($Path, "/", 2)
		If UBound($Parts) >= 3 Then
			Local $Ref = $Parts[2], $Start = 3
			If $Ref = "refs" And UBound($Parts) >= 5 And $Parts[3] = "heads" Then
				$Ref = $Parts[4]
				$Start = 5
			EndIf
			Local $Result = "https://cdn.jsdmirror.com/gh/" & $Parts[0] & "/" & $Parts[1] & "@" & $Ref
			For $i = $Start To UBound($Parts) - 1
				$Result &= "/" & $Parts[$i]
			Next
			Return $Result
		EndIf
	EndIf
	If StringRegExp($Lower, "(?i)^https?://github\.com/[^/]+/[^/]+/raw/") Then
		$Path = StringRegExpReplace($Url, "(?i)^https?://github\.com/", "")
		Local $RawParts = StringSplit($Path, "/", 2)
		If UBound($RawParts) >= 5 And $RawParts[2] = "raw" Then
			Local $RawRef = $RawParts[3], $RawStart = 4
			If $RawParts[3] = "refs" And $RawParts[4] = "heads" And UBound($RawParts) >= 6 Then
				$RawRef = $RawParts[5]
				$RawStart = 6
			EndIf
			Local $RawResult = "https://cdn.jsdmirror.com/gh/" & $RawParts[0] & "/" & $RawParts[1] & "@" & $RawRef
			For $i = $RawStart To UBound($RawParts) - 1
				$RawResult &= "/" & $RawParts[$i]
			Next
			Return $RawResult
		EndIf
	EndIf
	Return ""
EndFunc   ;==>BuildGithubJsMirrorUrl

Func _DownloadToolsIsGenericProxyUrl($Url)
	Return StringRegExp($Url, "(?i)^https?://(?:downloads\.vivaldi\.com|update\.vivaldi\.com|vivaldi\.com|www\.vivaldi\.com|get\.opera\.com|installer-whale\.pstatic\.net|cv\.whale\.naver\.com|archive\.org|versions\.brave\.com|brave\.com|www\.brave\.com|static\.brave\.com)/")
EndFunc   ;==>IsGenericProxyUrl

Func _DownloadToolsIsManagedMirrorUrl($Url)
	Local $Lower = StringLower($Url)
	If $DT_GithubDirectMirror <> "" And StringLeft($Lower, StringLen(StringLower($DT_GithubDirectMirror))) = StringLower($DT_GithubDirectMirror) Then Return True
	If $DT_GithubJsDelivrMirror <> "" And StringLeft($Lower, StringLen(StringLower($DT_GithubJsDelivrMirror))) = StringLower($DT_GithubJsDelivrMirror) Then Return True
	If $DT_GithubApiMirror <> "" And StringLeft($Lower, StringLen(StringLower($DT_GithubApiMirror))) = StringLower($DT_GithubApiMirror) Then Return True
	If StringLeft($Lower, StringLen($DT_DEFAULT_GENERIC_URL_PROXY)) = StringLower($DT_DEFAULT_GENERIC_URL_PROXY) Then Return True
	If StringLeft($Lower, StringLen($DT_FALLBACK_GENERIC_URL_PROXY)) = StringLower($DT_FALLBACK_GENERIC_URL_PROXY) Then Return True
	Return StringInStr($Lower, "cdn.jsdmirror.com/") > 0 Or _
			(StringInStr($Lower, "gcore.jsdelivr.net/") > 0 And StringInStr($Lower, "/gh/") > 0) Or _
			(StringInStr($Lower, "testingcf.jsdelivr.net/") > 0 And StringInStr($Lower, "/gh/") > 0) Or _
			StringInStr($Lower, "gh-proxy") > 0 Or StringInStr($Lower, "ghproxy") > 0 Or _
			StringInStr($Lower, "gh.dpik.top/") > 0
EndFunc   ;==>IsManagedMirrorUrl

Func _DownloadToolsBuildUrlCandidatesForConfig($Url, $Language, $GithubDirectMirror, $GithubJsDelivrMirror, $GithubApiMirror, $GenericProxy = "")
	Local $Urls[1], $Count = 0
	If $Url = "" Then Return SetError(1, 0, 0)
	If _DownloadToolsUsesProxy() Or _DownloadToolsIsManagedMirrorUrl($Url) Then
		_DownloadToolsAddCandidate($Urls, $Count, $Url)
		ReDim $Urls[$Count]
		Return $Urls
	EndIf

	Local $Lang = StringLower(StringReplace(StringStripWS($Language, 3), "_", "-"))
	Local $Direct = _DownloadToolsNormalizeMirror($GithubDirectMirror)
	Local $Jsd = _DownloadToolsNormalizeMirror($GithubJsDelivrMirror)
	Local $Api = _DownloadToolsNormalizeMirror($GithubApiMirror)
	Local $Accelerated = ""
	If _DownloadToolsIsGithubApiUrl($Url) Then
		If $Api = "" And $Lang = "zh-cn" Then $Api = $DT_DEFAULT_GITHUB_API_MIRROR
		If $Api <> "" Then $Accelerated = $Api & $Url
	Else
		Local $JsdUrl = _DownloadToolsBuildGithubJsMirrorUrl($Url)
		If $JsdUrl <> "" And ($Lang = "zh-cn" Or $Jsd <> "") Then
			If $Lang = "zh-cn" Then
				$Accelerated = $JsdUrl
			Else
				If $Jsd = "" Then $Jsd = $DT_DEFAULT_GITHUB_JSDELIVR_MIRROR
				$Accelerated = StringReplace($JsdUrl, "https://cdn.jsdmirror.com/gh/", $Jsd, 1)
			EndIf
		ElseIf _DownloadToolsIsGithubUrl($Url) Then
			If $Direct = "" And $Lang = "zh-cn" Then $Direct = $DT_DEFAULT_GITHUB_DIRECT_MIRROR
			If $Direct <> "" Then $Accelerated = $Direct & $Url
		ElseIf _DownloadToolsIsGenericProxyUrl($Url) And ($Lang = "zh-cn" Or $GenericProxy <> "") Then
			_DownloadToolsAddGenericProxyCandidates($Urls, $Count, $Url, $Lang, $GenericProxy)
		EndIf
	EndIf
	_DownloadToolsAddCandidate($Urls, $Count, $Accelerated)
	_DownloadToolsAddCandidate($Urls, $Count, $Url)
	ReDim $Urls[$Count]
	Return $Urls
EndFunc   ;==>BuildUrlCandidatesForConfig

Func _DownloadToolsBuildUrlCandidates($Url)
	Return _DownloadToolsBuildUrlCandidatesForConfig($Url, $DT_Language, $DT_GithubDirectMirror, $DT_GithubJsDelivrMirror, $DT_GithubApiMirror)
EndFunc   ;==>BuildUrlCandidates

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

Func _DownloadToolsFreeWinHttpString($StringPointer)
	If $StringPointer Then DllCall("kernel32.dll", "ptr", "GlobalFree", "ptr", $StringPointer)
EndFunc   ;==>FreeWinHttpString

Func _DownloadToolsReadWinHttpString($StringPointer)
	If Not $StringPointer Then Return ""
	Local $aLength = DllCall("kernel32.dll", "int", "lstrlenW", "ptr", $StringPointer)
	If @error Or Not IsArray($aLength) Or $aLength[0] < 0 Then Return ""
	Local $tString = DllStructCreate("wchar[" & ($aLength[0] + 1) & "]", $StringPointer)
	If @error Then Return ""
	Return DllStructGetData($tString, 1)
EndFunc   ;==>ReadWinHttpString

Func _DownloadToolsSystemProxySession()
	If $DT_WinHttpProxySession Then Return $DT_WinHttpProxySession
	Local $aOpen = DllCall("winhttp.dll", "ptr", "WinHttpOpen", "wstr", "RunFirefox", "dword", 1, "ptr", 0, "ptr", 0, "dword", 0)
	If @error Or Not IsArray($aOpen) Or Not $aOpen[0] Then Return SetError(1, 0, 0)
	$DT_WinHttpProxySession = $aOpen[0]
	Return $DT_WinHttpProxySession
EndFunc   ;==>SystemProxySession

Func _DownloadToolsSelectSystemProxy($ProxyList, $Url)
	Local $TargetScheme = "http"
	If StringLeft(StringLower($Url), 8) = "https://" Then $TargetScheme = "https"
	Local $Entries = StringSplit($ProxyList, ";", 2), $DefaultProxy = "", $SelectedProxy = "", $HasSchemeEntry = False
	For $Entry In $Entries
		$Entry = StringStripWS($Entry, 3)
		If $Entry = "" Then ContinueLoop
		Local $SchemeMatch = StringRegExp($Entry, "(?i)^(http|https)\s*=\s*(.*)$", 1)
		If IsArray($SchemeMatch) Then
			$HasSchemeEntry = True
			If StringLower($SchemeMatch[0]) = $TargetScheme Then $SelectedProxy = StringStripWS(StringRegExpReplace($Entry, "(?i)^(http|https)\s*=\s*", ""), 3)
			ContinueLoop
		EndIf
		If $DefaultProxy = "" Then $DefaultProxy = $Entry
	Next
	If $SelectedProxy = "" And Not $HasSchemeEntry Then $SelectedProxy = $DefaultProxy
	If $SelectedProxy = "" Then Return ""
	$SelectedProxy = StringRegExpReplace($SelectedProxy, "(?i)^(?:PROXY|HTTP|HTTPS)\s+", "")
	If StringUpper($SelectedProxy) = "DIRECT" Then Return ""
	If StringRegExp($SelectedProxy, "(?i)^(?:SOCKS|SOCKS4|SOCKS5)\s+") Then Return SetError(1, 0, "")
	If StringRegExp($SelectedProxy, '[\s"]') Then Return SetError(1, 0, "")
	; PAC-compatible results can contain alternatives. Match WinHTTP's first-proxy behavior.
	Local $Alternatives = StringSplit($SelectedProxy, ",", 2)
	If UBound($Alternatives) > 0 Then $SelectedProxy = StringStripWS($Alternatives[0], 3)
	If StringLeft(StringLower($SelectedProxy), 7) <> "http://" And StringLeft(StringLower($SelectedProxy), 8) <> "https://" Then $SelectedProxy = "http://" & $SelectedProxy
	Return $SelectedProxy
EndFunc   ;==>SelectSystemProxy

Func _DownloadToolsGetUrlHost($Url)
	Local $Match = StringRegExp($Url, "(?i)^https?://(\[[^\]]+\]|[^/:?#]+)", 1)
	If Not IsArray($Match) Then Return ""
	Return StringLower($Match[0])
EndFunc   ;==>GetUrlHost

Func _DownloadToolsSystemProxyBypassed($Bypass, $Url)
	Local $Host = _DownloadToolsGetUrlHost($Url)
	Local $Rules = StringSplit(StringReplace($Bypass, ";", ","), ",", 2)
	For $Rule In $Rules
		$Rule = StringStripWS($Rule, 3)
		If $Rule = "" Then ContinueLoop
		If StringLower($Rule) = "<local>" Then
			If Not StringInStr($Host, ".") And Not StringInStr($Host, ":") Then Return True
			ContinueLoop
		EndIf
		; Escape regex syntax, retaining Windows' wildcard matching semantics.
		Local $Pattern = StringRegExpReplace($Rule, '([.\\+?\[\](){}^$|])', '\\$1')
		$Pattern = StringReplace($Pattern, "*", ".*")
		If StringRegExp($Host, "(?i)^" & $Pattern & "$") Then Return True
	Next
	Return False
EndFunc   ;==>SystemProxyBypassed

Func _DownloadToolsParseSystemProxyConfig($ProxyList, $BypassList, $Url, ByRef $ProxyUrl, ByRef $NoProxy)
	$ProxyUrl = ""
	$NoProxy = ""
	If Not StringRegExp($Url, "(?i)^https?://") Then Return SetError(1, 0, False)
	Local $Host = _DownloadToolsGetUrlHost($Url)
	If $Host = "" Then Return SetError(1, 0, False)
	If _DownloadToolsSystemProxyBypassed($BypassList, $Url) Then Return SetError(0, 0, False)
	$ProxyUrl = _DownloadToolsSelectSystemProxy($ProxyList, $Url)
	If @error Then Return SetError(1, 0, False)
	If $ProxyUrl = "" Then Return SetError(0, 0, False)
	Return True
EndFunc   ;==>ParseSystemProxyConfig

Func _DownloadToolsResolveSystemProxy($Url, ByRef $ProxyUrl, ByRef $NoProxy)
	$ProxyUrl = ""
	$NoProxy = ""
	$DT_SystemProxyLastStatus = "direct"
	Local $TagIEProxyConfig
	If @AutoItX64 Then
		$TagIEProxyConfig = "align 8;int;ptr;ptr;ptr"
	Else
		$TagIEProxyConfig = "align 4;int;ptr;ptr;ptr"
	EndIf
	Local $tIEProxyConfig = DllStructCreate($TagIEProxyConfig)
	If @error Then
		$DT_SystemProxyLastStatus = "error"
		Return False
	EndIf
	Local $aGetConfig = DllCall("winhttp.dll", "bool", "WinHttpGetIEProxyConfigForCurrentUser", "ptr", DllStructGetPtr($tIEProxyConfig))
	If @error Or Not IsArray($aGetConfig) Or Not $aGetConfig[0] Then
		$DT_SystemProxyLastStatus = "error"
		Return False
	EndIf
	Local $AutoDetect = DllStructGetData($tIEProxyConfig, 1)
	Local $AutoConfigPointer = DllStructGetData($tIEProxyConfig, 2)
	Local $ProxyPointer = DllStructGetData($tIEProxyConfig, 3)
	Local $BypassPointer = DllStructGetData($tIEProxyConfig, 4)
	Local $AutoConfigUrl = _DownloadToolsReadWinHttpString($AutoConfigPointer)
	Local $StaticProxy = _DownloadToolsReadWinHttpString($ProxyPointer)
	Local $StaticBypass = _DownloadToolsReadWinHttpString($BypassPointer)
	Local $HasAutoProxy = ($AutoDetect Or $AutoConfigUrl <> "")
	If $HasAutoProxy Then
		Local $TagAutoProxyOptions, $TagProxyInfo
		If @AutoItX64 Then
			$TagAutoProxyOptions = "align 8;dword;dword;ptr;ptr;dword;bool"
			$TagProxyInfo = "align 8;dword;ptr;ptr"
		Else
			$TagAutoProxyOptions = "align 4;dword;dword;ptr;ptr;dword;bool"
			$TagProxyInfo = "align 4;dword;ptr;ptr"
		EndIf
		Local $tAutoProxyOptions = DllStructCreate($TagAutoProxyOptions), $tProxyInfo = DllStructCreate($TagProxyInfo)
		If Not @error Then
			Local $Flags = 0, $AutoDetectFlags = 0, $tAutoConfigUrl = 0
			If $AutoConfigUrl <> "" Then
				$Flags = BitOR($Flags, 2) ; WINHTTP_AUTOPROXY_CONFIG_URL
				$tAutoConfigUrl = DllStructCreate("wchar[" & StringLen($AutoConfigUrl) + 1 & "]")
				DllStructSetData($tAutoConfigUrl, 1, $AutoConfigUrl)
				DllStructSetData($tAutoProxyOptions, 3, DllStructGetPtr($tAutoConfigUrl))
			EndIf
			If $AutoDetect Then
				$Flags = BitOR($Flags, 1) ; WINHTTP_AUTOPROXY_AUTO_DETECT
				$AutoDetectFlags = 3 ; DHCP and DNS-A discovery
			EndIf
			DllStructSetData($tAutoProxyOptions, 1, $Flags)
			DllStructSetData($tAutoProxyOptions, 2, $AutoDetectFlags)
			DllStructSetData($tAutoProxyOptions, 4, 0)
			DllStructSetData($tAutoProxyOptions, 5, 0)
			DllStructSetData($tAutoProxyOptions, 6, False)
			Local $Session = _DownloadToolsSystemProxySession()
			If $Session Then
				Local $aProxy = DllCall("winhttp.dll", "bool", "WinHttpGetProxyForUrl", "ptr", $Session, "wstr", $Url, "ptr", DllStructGetPtr($tAutoProxyOptions), "ptr", DllStructGetPtr($tProxyInfo))
				If Not @error And IsArray($aProxy) And $aProxy[0] Then
					Local $AccessType = DllStructGetData($tProxyInfo, 1)
					If $AccessType = 3 Then
						Local $ResolvedProxy = _DownloadToolsReadWinHttpString(DllStructGetData($tProxyInfo, 2))
						Local $ResolvedBypass = _DownloadToolsReadWinHttpString(DllStructGetData($tProxyInfo, 3))
						Local $Resolved = _DownloadToolsParseSystemProxyConfig($ResolvedProxy, $ResolvedBypass, $Url, $ProxyUrl, $NoProxy)
						If @error Then
							$DT_SystemProxyLastStatus = "error"
						ElseIf $Resolved Then
							$DT_SystemProxyLastStatus = "proxy"
						EndIf
					ElseIf $AccessType <> 1 Then
						$DT_SystemProxyLastStatus = "error"
					EndIf
					_DownloadToolsFreeWinHttpString(DllStructGetData($tProxyInfo, 2))
					_DownloadToolsFreeWinHttpString(DllStructGetData($tProxyInfo, 3))
				Else
					$DT_SystemProxyLastStatus = "error"
				EndIf
			EndIf
		EndIf
	ElseIf $StaticProxy <> "" Then
		Local $Resolved = _DownloadToolsParseSystemProxyConfig($StaticProxy, $StaticBypass, $Url, $ProxyUrl, $NoProxy)
		If @error Then
			$DT_SystemProxyLastStatus = "error"
		ElseIf $Resolved Then
			$DT_SystemProxyLastStatus = "proxy"
		EndIf
	EndIf
	_DownloadToolsFreeWinHttpString($AutoConfigPointer)
	_DownloadToolsFreeWinHttpString($ProxyPointer)
	_DownloadToolsFreeWinHttpString($BypassPointer)
	Return $ProxyUrl <> ""
EndFunc   ;==>ResolveSystemProxy

Func _DownloadToolsCurlArgs($Url = "")
	Local $Args = ' --fail --silent --show-error --connect-timeout 15'
	If $DT_ProxyType <> "system" Then $Args &= ' --location'
	If $DT_ProxyType = "direct" Then $Args &= ' --noproxy "*"'
	If $DT_ProxyType = "http" Then $Args &= ' --proxy "http://' & $DT_ProxyServer & ':' & $DT_ProxyPort & '"'
	If $DT_ProxyType = "socks5" Then $Args &= ' --socks5-hostname "' & $DT_ProxyServer & ':' & $DT_ProxyPort & '"'
	If $DT_ProxyType = "system" Then
		Local $SystemProxy = "", $NoProxy = ""
		Local $UseSystemProxy = _DownloadToolsResolveSystemProxy($Url, $SystemProxy, $NoProxy)
		If $UseSystemProxy Then
			$Args &= ' --proxy "' & $SystemProxy & '"'
			; Override environment NO_PROXY: Windows has already evaluated bypass rules.
			$Args &= ' --noproxy ""'
		Else
			$Args &= ' --noproxy "*"'
		EndIf
	EndIf
	Return $Args
EndFunc   ;==>CurlArgs

Func _DownloadToolsCurlCommand($ExtraArgs, $Url)
	Return '"' & _DownloadToolsFindCurl() & '"' & _DownloadToolsCurlArgs($Url) & $ExtraArgs & ' "' & StringReplace($Url, '"', '') & '"'
EndFunc   ;==>CurlCommand

; System requests use logical (negative) handles so every redirect can resolve
; its own proxy without blocking asynchronous version checks or cancellation.
Func _DownloadToolsCurlLaunch(ByRef $Request)
	Local $Command = _DownloadToolsCurlCommand($Request[1], $Request[2]) & ' --write-out "\n%{http_code}\n%{redirect_url}"'
	$Request[0] = Run($Command, @TempDir, @SW_HIDE, 2)
	If @error Or Not $Request[0] Then Return False
	Local $Handle = DllCall("kernel32.dll", "handle", "OpenProcess", "dword", 0x100400, "bool", False, "dword", $Request[0])
	If @error Or Not IsArray($Handle) Or Not $Handle[0] Then
		ProcessClose($Request[0])
		Return False
	EndIf
	$Request[6] = $Handle[0]
	Return True
EndFunc   ;==>CurlLaunch

Func _DownloadToolsCurlStart($ExtraArgs, $Url)
	If $DT_ProxyType <> "system" Then Return Run(_DownloadToolsCurlCommand($ExtraArgs, $Url), @TempDir, @SW_HIDE)
	Local $Request[8] = [0, $ExtraArgs, $Url, 0, TimerInit(), 600000, 0, ""]
	Local $MaxTime = StringRegExp($ExtraArgs, ' --max-time (\d+)', 1)
	If IsArray($MaxTime) Then $Request[5] = Number($MaxTime[0]) * 1000
	Local $Output = StringRegExp($ExtraArgs, ' --output "([^"]+)"', 1)
	If IsArray($Output) Then $Request[7] = $Output[0]
	If Not _DownloadToolsCurlLaunch($Request) Then Return SetError(1, 0, 0)
	$DT_CurlRequestId -= 1
	$DT_CurlRequests.Add($DT_CurlRequestId, $Request)
	Return $DT_CurlRequestId
EndFunc   ;==>CurlStart

Func _DownloadToolsCurlCancel($Handle)
	If $Handle >= 0 Then
		If $Handle And ProcessExists($Handle) Then ProcessClose($Handle)
		Return
	EndIf
	If Not $DT_CurlRequests.Exists($Handle) Then Return
	Local $Request = $DT_CurlRequests.Item($Handle)
	; The retained process handle also prevents PID reuse before cleanup.
	Local $Wait = DllCall("kernel32.dll", "dword", "WaitForSingleObject", "handle", $Request[6], "dword", 0)
	If IsArray($Wait) And $Wait[0] = 258 Then ProcessClose($Request[0])
	DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $Request[6])
	If $Request[7] <> "" Then FileDelete($Request[7])
	$DT_CurlRequests.Remove($Handle)
EndFunc   ;==>CurlCancel

Func _DownloadToolsCurlRunning($Handle)
	If $Handle >= 0 Then Return ProcessExists($Handle) <> 0
	If Not $DT_CurlRequests.Exists($Handle) Then Return SetExtended(1, False)
	Local $Request = $DT_CurlRequests.Item($Handle)
	If TimerDiff($Request[4]) >= $Request[5] Then
		_DownloadToolsCurlCancel($Handle)
		Return SetExtended(28, False)
	EndIf
	Local $Wait = DllCall("kernel32.dll", "dword", "WaitForSingleObject", "handle", $Request[6], "dword", 0)
	If IsArray($Wait) And $Wait[0] = 258 Then Return True
	Local $Metadata = StdoutRead($Request[0])
	Local $ProcessExit = DllCall("kernel32.dll", "bool", "GetExitCodeProcess", "handle", $Request[6], "dword*", 0)
	DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $Request[6])
	Local $Result = StringRegExp($Metadata, '(?s)\r?\n(\d{3})\r?\n([^\r\n]*)\r?\n?$', 1), $ExitCode = 1
	If IsArray($Result) And IsArray($ProcessExit) And $ProcessExit[0] And $ProcessExit[2] = 0 Then
		Local $Status = Number($Result[0]), $NextUrl = $Result[1]
		If $Status >= 300 And $Status <= 399 And $NextUrl <> "" Then
			If $Request[3] < 10 And StringRegExp($NextUrl, '(?i)^https?://[^\s"]+$') Then
				; Match curl's POST conversion for 301/302/303; 307/308 retain the body.
				If $Status = 301 Or $Status = 302 Or $Status = 303 Then
					$Request[1] = StringReplace($Request[1], ' --request POST', '')
					$Request[1] = StringRegExpReplace($Request[1], ' --data-binary "[^"]*"', '')
				EndIf
				$Request[2] = $NextUrl
				$Request[3] += 1
				If $Request[7] <> "" Then FileDelete($Request[7])
				If _DownloadToolsCurlLaunch($Request) Then
					$DT_CurlRequests.Item($Handle) = $Request
					Return True
				EndIf
			EndIf
			$ExitCode = 47
		ElseIf $Status >= 200 And $Status < 300 Then
			; curl emits metadata even on a truncated response; verify its exit code below.
			$ExitCode = 0
		EndIf
	EndIf
	If Not IsArray($ProcessExit) Then
		$ExitCode = 1
	ElseIf Not $ProcessExit[0] Then
		$ExitCode = 1
	ElseIf $ProcessExit[2] <> 0 Then
		$ExitCode = $ProcessExit[2]
	EndIf
	$DT_CurlRequests.Remove($Handle)
	If $ExitCode And $Request[7] <> "" Then FileDelete($Request[7])
	Return SetExtended($ExitCode, False)
EndFunc   ;==>CurlRunning

Func _DownloadToolsCurlWait($ExtraArgs, $Url)
	If $DT_ProxyType <> "system" Then Return RunWait(_DownloadToolsCurlCommand($ExtraArgs, $Url), @TempDir, @SW_HIDE)
	Local $Handle = _DownloadToolsCurlStart($ExtraArgs, $Url)
	If Not $Handle Then Return 1
	While _DownloadToolsCurlRunning($Handle)
		Sleep(20)
	WEnd
	Return @extended
EndFunc   ;==>CurlWait

Func _DownloadToolsHttpComError($oError)
EndFunc

Func _DownloadToolsHttpGetTextSingle($Url, $UserAgent, $Accept, ByRef $Diagnostic, $Referer = "")
	If _DownloadToolsHasCurl() Then
		Local $OutputFile = @TempDir & "\RunFirefox_CurlText_" & @AutoItPID & "_" & Random(1000, 999999, 1) & ".tmp"
		Local $ExtraArgs = ' --max-time 60 --output "' & $OutputFile & '"'
		If $UserAgent <> "" Then $ExtraArgs &= ' --user-agent "' & StringReplace($UserAgent, '"', '') & '"'
		If $Accept <> "" Then $ExtraArgs &= ' --header "Accept: ' & StringReplace($Accept, '"', '') & '"'
		If $Referer <> "" Then $ExtraArgs &= ' --referer "' & StringReplace($Referer, '"', '') & '"'
		Local $ExitCode = _DownloadToolsCurlWait($ExtraArgs, $Url)
		Local $ResponseText = FileRead($OutputFile)
		FileDelete($OutputFile)
		$Diagnostic &= $Url & " (curl " & $ExitCode & ", " & StringLen($ResponseText) & " bytes)" & @CRLF
		If $ExitCode <> 0 Then Return SetError(2, $ExitCode, "")
		Return $ResponseText
	EndIf
	If _DownloadToolsUsesProxy() Then Return SetError(4, 0, "")
	Local $oError = ObjEvent("AutoIt.Error", "_DownloadToolsHttpComError")
	Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
	If @error Or Not IsObj($oHTTP) Then Return SetError(1, 0, "")
	$oHTTP.SetTimeouts(5000, 5000, 15000, 30000)
	$oHTTP.Open("GET", $Url, False)
	If $UserAgent <> "" Then $oHTTP.SetRequestHeader("User-Agent", $UserAgent)
	If $Accept <> "" Then $oHTTP.SetRequestHeader("Accept", $Accept)
	If $Referer <> "" Then $oHTTP.SetRequestHeader("Referer", $Referer)
	$oHTTP.Send()
	If @error Then Return SetError(2, 0, "")
	Local $Status = $oHTTP.Status, $ResponseText = $oHTTP.ResponseText
	$Diagnostic &= $Url & " (HTTP " & $Status & ", " & StringLen($ResponseText) & " bytes)" & @CRLF
	If $Status < 200 Or $Status >= 300 Then Return SetError(3, $Status, "")
	Return $ResponseText
EndFunc   ;==>HttpGetTextSingle

Func _DownloadToolsHttpGetTextDiagnostic($Url, $UserAgent, $Accept, ByRef $Diagnostic, $Referer = "")
	$Diagnostic = "GET candidates:" & @CRLF
	Local $Urls = _DownloadToolsBuildUrlCandidates($Url)
	If Not IsArray($Urls) Then Return SetError(1, 0, "")
	For $i = 0 To UBound($Urls) - 1
		Local $Response = _DownloadToolsHttpGetTextSingle($Urls[$i], $UserAgent, $Accept, $Diagnostic, $Referer)
		If Not @error Then Return $Response
	Next
	Return SetError(2, 0, "")
EndFunc   ;==>HttpGetTextDiagnostic

Func _DownloadToolsHttpGetText($Url, $UserAgent = "", $Accept = "")
	Local $Diagnostic = ""
	Return _DownloadToolsHttpGetTextDiagnostic($Url, $UserAgent, $Accept, $Diagnostic)
EndFunc   ;==>HttpGetText

Func _DownloadToolsHttpPostTextSingle($Url, $Body, $UserAgent, $ContentType)
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
		Local $ExitCode = _DownloadToolsCurlWait($ExtraArgs, $Url)
		Local $ResponseText = FileRead($OutputFile)
		FileDelete($RequestFile)
		FileDelete($OutputFile)
		If $ExitCode <> 0 Then Return SetError(2, $ExitCode, "")
		Return $ResponseText
	EndIf
	If _DownloadToolsUsesProxy() Then Return SetError(3, 0, "")
	Local $oError = ObjEvent("AutoIt.Error", "_DownloadToolsHttpComError")
	Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
	If @error Or Not IsObj($oHTTP) Then Return SetError(1, 0, "")
	$oHTTP.SetTimeouts(5000, 5000, 15000, 30000)
	$oHTTP.Open("POST", $Url, False)
	If $UserAgent <> "" Then $oHTTP.SetRequestHeader("User-Agent", $UserAgent)
	$oHTTP.SetRequestHeader("Content-Type", $ContentType)
	$oHTTP.Send($Body)
	If @error Then Return SetError(2, 0, "")
	If $oHTTP.Status < 200 Or $oHTTP.Status >= 300 Then Return SetError(3, $oHTTP.Status, "")
	Return $oHTTP.ResponseText
EndFunc   ;==>HttpPostTextSingle

Func _DownloadToolsHttpPostText($Url, $Body, $UserAgent = "", $ContentType = "application/octet-stream")
	Local $Urls = _DownloadToolsBuildUrlCandidates($Url)
	If Not IsArray($Urls) Then Return SetError(1, 0, "")
	For $i = 0 To UBound($Urls) - 1
		Local $Response = _DownloadToolsHttpPostTextSingle($Urls[$i], $Body, $UserAgent, $ContentType)
		If Not @error Then Return $Response
	Next
	Return SetError(2, 0, "")
EndFunc   ;==>HttpPostText

Func _DownloadToolsReadUrl($Url)
	Local $Urls = _DownloadToolsBuildUrlCandidates($Url)
	If Not IsArray($Urls) Then Return SetError(1, 0, Binary(""))
	For $i = 0 To UBound($Urls) - 1
		If _DownloadToolsHasCurl() Then
			Local $OutputFile = @TempDir & "\RunFirefox_CurlRead_" & @AutoItPID & "_" & Random(1000, 999999, 1) & ".tmp"
			Local $ExitCode = _DownloadToolsCurlWait(' --max-time 60 --output "' & $OutputFile & '"', $Urls[$i])
			If $ExitCode = 0 Then
				Local $FileHandle = FileOpen($OutputFile, 16), $Data = FileRead($FileHandle)
				FileClose($FileHandle)
				FileDelete($OutputFile)
				Return $Data
			EndIf
			FileDelete($OutputFile)
		ElseIf Not _DownloadToolsUsesProxy() Then
			Local $Data = InetRead($Urls[$i], 1)
			If Not @error Then Return $Data
		EndIf
	Next
	Return SetError(2, 0, Binary(""))
EndFunc   ;==>ReadUrl

Func _DownloadToolsStartUrlToFile($Url, $Destination, ByRef $Kind)
	FileDelete($Destination)
	Local $Urls = _DownloadToolsBuildUrlCandidates($Url)
	If Not IsArray($Urls) Or UBound($Urls) = 0 Then Return SetError(1, 0, 0)
	$DT_AsyncUrls = $Urls
	$DT_AsyncIndex = 0
	$DT_AsyncDestination = $Destination
	If _DownloadToolsHasCurl() Then
		$Kind = "curl"
		Return _DownloadToolsCurlStart(' --max-time 60 --output "' & $Destination & '"', $Urls[0])
	EndIf
	If _DownloadToolsUsesProxy() Then Return SetError(1, 0, 0)
	$Kind = "inet"
	Return InetGet($Urls[0], $Destination, 1, 1)
EndFunc   ;==>StartUrlToFile

Func _DownloadToolsAdvanceUrlToFile(ByRef $Kind)
	If Not IsArray($DT_AsyncUrls) Or $DT_AsyncIndex < 0 Or $DT_AsyncIndex + 1 >= UBound($DT_AsyncUrls) Then Return 0
	$DT_AsyncIndex += 1
	FileDelete($DT_AsyncDestination)
	If _DownloadToolsHasCurl() Then
		$Kind = "curl"
		Return _DownloadToolsCurlStart(' --max-time 60 --output "' & $DT_AsyncDestination & '"', $DT_AsyncUrls[$DT_AsyncIndex])
	EndIf
	If _DownloadToolsUsesProxy() Then Return SetError(1, 0, 0)
	$Kind = "inet"
	Return InetGet($DT_AsyncUrls[$DT_AsyncIndex], $DT_AsyncDestination, 1, 1)
EndFunc   ;==>AdvanceUrlToFile

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
	Local $ExitCode = _DownloadToolsCurlWait($Args, $Url)
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
		If $Processes[$i] Then _DownloadToolsCurlCancel($Processes[$i])
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
		$Processes[$i] = _DownloadToolsCurlStart($Args, $Url)
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
			If _DownloadToolsCurlRunning($Processes[$i]) Then $Running = True
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
	Local $Process = _DownloadToolsCurlStart(' --output "' & $Destination & '"', $Url)
	If @error Or Not $Process Then Return False
	Local $Timer = TimerInit(), $DownloadedBytes, $DetailText
	While _DownloadToolsCurlRunning($Process)
		$DownloadedBytes = 0
		If FileExists($Destination) Then $DownloadedBytes = FileGetSize($Destination)
		$DetailText = StringReplace($UnknownProgressTemplate, "%s", _DownloadToolsFormatBytes($DownloadedBytes))
		_DownloadToolsUpdateDownloadProgress($StatusText, $DetailText, Mod(Int($DownloadedBytes / 65536), 100))
		_DownloadToolsPumpDownloadProgressEvents()
		If _DownloadToolsIsDownloadProgressCancelled() Or TimerDiff($Timer) >= $TimeoutMs Then
			_DownloadToolsCurlCancel($Process)
			FileDelete($Destination)
			Return False
		EndIf
		Sleep(200)
	WEnd
	Return FileExists($Destination) And FileGetSize($Destination) > 0
EndFunc   ;==>CurlSingleDownload

Func _DownloadToolsFileMatchesSha256($Path, $ExpectedSha256)
	$ExpectedSha256 = StringLower(StringStripWS($ExpectedSha256, 3))
	If $ExpectedSha256 = "" Then Return True
	If Not StringRegExp($ExpectedSha256, "^[0-9a-f]{64}$") Or Not FileExists($Path) Then Return False
	Local $Actual = StringLower(String(_Crypt_HashFile($Path, $CALG_SHA_256)))
	If @error Then Return False
	$Actual = StringRegExpReplace($Actual, "^0x", "")
	Return $Actual = $ExpectedSha256
EndFunc   ;==>FileMatchesSha256

Func _DownloadToolsDownloadUrls($Urls, $Destination, $StatusText, $KnownProgressTemplate, $UnknownProgressTemplate, ByRef $TriedUrls, $TimeoutMs = 600000, $ExpectedSha256 = "")
	$TriedUrls = ""
	If Not IsArray($Urls) Or UBound($Urls) = 0 Then Return SetError(1, 0, False)

	Local $i, $r, $Url, $RoutedUrls, $hDownload, $DownloadedBytes, $TotalBytes, $Percent, $DetailText, $DownloadSuccessful = False, $Timer
	Local $HashMismatch = False
	Local $Attempted[1], $AttemptedCount = 0, $AlreadyAttempted
	For $i = 0 To UBound($Urls) - 1
		$RoutedUrls = _DownloadToolsBuildUrlCandidates($Urls[$i])
		If Not IsArray($RoutedUrls) Then ContinueLoop
		For $r = 0 To UBound($RoutedUrls) - 1
			$Url = $RoutedUrls[$r]
			$AlreadyAttempted = False
			For $j = 0 To $AttemptedCount - 1
				If $Attempted[$j] = $Url Then
					$AlreadyAttempted = True
					ExitLoop
				EndIf
			Next
			If $AlreadyAttempted Then ContinueLoop
			ReDim $Attempted[$AttemptedCount + 1]
			$Attempted[$AttemptedCount] = $Url
			$AttemptedCount += 1
			If $TriedUrls <> "" Then $TriedUrls &= @CRLF
			$TriedUrls &= $Url
			FileDelete($Destination)
			_DownloadToolsUpdateDownloadProgress($StatusText, $Url, 0)
			If _DownloadToolsHasCurl() Then
				_DownloadToolsSetDownloadProgressMarquee(True)
				If $DT_DownloadThreads > 1 And _DownloadToolsCurlSegmentedDownload($Url, $Destination, $StatusText, $KnownProgressTemplate, $TimeoutMs) Then
					If _DownloadToolsFileMatchesSha256($Destination, $ExpectedSha256) Then Return True
					$HashMismatch = True
					ContinueLoop
				EndIf
				If _DownloadToolsIsDownloadProgressCancelled() Then Return SetError(2, 0, False)
				If _DownloadToolsCurlSingleDownload($Url, $Destination, $StatusText, $KnownProgressTemplate, $UnknownProgressTemplate, $TimeoutMs) Then
					If _DownloadToolsFileMatchesSha256($Destination, $ExpectedSha256) Then Return True
					$HashMismatch = True
				EndIf
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
				If TimerDiff($Timer) >= $TimeoutMs Then ExitLoop
				Sleep(200)
			Until InetGetInfo($hDownload, 2)
			$DownloadSuccessful = InetGetInfo($hDownload, 3)
			InetClose($hDownload)
			If _DownloadToolsIsDownloadProgressCancelled() Then Return SetError(2, 0, False)
			If $DownloadSuccessful And FileExists($Destination) Then
				If _DownloadToolsFileMatchesSha256($Destination, $ExpectedSha256) Then Return True
				$HashMismatch = True
			EndIf
		Next
	Next

	If $HashMismatch Then Return SetError(5, 0, False)
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
