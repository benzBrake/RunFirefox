#include-once
#include "DownloadTools.au3"

Global Const $UPGRADE_DEFAULT_GITHUB_JSDELIVR_MIRROR_CHINA = "https://cdn.jsdmirror.com/gh"
Global Const $UPGRADE_DEFAULT_GITHUB_JSDELIVR_MIRROR_GLOBAL = "https://gcore.jsdelivr.net/gh"
; This endpoint accepts a complete upstream URL and is not limited to GitHub.
Global Const $UPGRADE_DEFAULT_URL_PROXY = $DT_DEFAULT_GENERIC_URL_PROXY
; Keep the old name for settings and callers that still describe it as a GitHub mirror.
Global Const $UPGRADE_DEFAULT_GITHUB_DIRECT_MIRROR = "https://v6.gh-proxy.org/"
; Dedicated proxy for GitHub API requests (for example, gh.llkk.cc).
Global Const $UPGRADE_DEFAULT_GITHUB_API_MIRROR = "https://gh.dpik.top/"

; Swallow WinHttp COM failures raised by mirror probes.  A mirror being
; unavailable must never surface an AutoIt error dialog to the user.
Func _UpgradeHttpComError($oError)
    Return
EndFunc

; Probe GitHub mirror candidates with a short HEAD request and move the
; fastest reachable endpoint to the front.  Failure is deliberately ignored
; so the existing fallback order remains available when a probe is blocked.
Func _UpgradePrioritizeGithubUrls(ByRef $aUrls, $iTimeoutMs = 1800)
    ; Candidate ordering is deterministic and handled by DownloadTools.
    Return
EndFunc

Func _UpgradeIsChineseLanguage($sLanguage = "")
    Return StringLower(StringReplace(StringStripWS($sLanguage, 3), "_", "-")) = "zh-cn"
EndFunc

Func _UpgradeGetDefaultGithubMirror($sLanguage = "")
    Return _UpgradeGetDefaultGithubJsDelivrMirror($sLanguage)
EndFunc

Func _UpgradeGetDefaultGithubJsDelivrMirror($sLanguage = "")
    If Not _UpgradeIsChineseLanguage($sLanguage) Then Return $UPGRADE_DEFAULT_GITHUB_JSDELIVR_MIRROR_GLOBAL
    Return $UPGRADE_DEFAULT_GITHUB_JSDELIVR_MIRROR_CHINA
EndFunc

Func _UpgradeGetGithubJsDelivrMirrors($sConfiguredMirror = "", $sLanguage = "")
    Local $aMirrors[1], $iCount = 0, $sConfigured = _UpgradeNormalizeMirrorAddress($sConfiguredMirror)
    If _UpgradeIsChineseLanguage($sLanguage) Then
        ; Simplified Chinese always uses the domestic jsDelivr mirror.
        _UpgradeAddUrl($aMirrors, $iCount, "https://cdn.jsdmirror.com/gh/")
    ElseIf _UpgradeIsJsDelivrGithubMirror($sConfigured) Then
        ; Other locales only use an explicitly configured mirror.
        _UpgradeAddUrl($aMirrors, $iCount, $sConfigured)
    EndIf
    ReDim $aMirrors[$iCount]
    Return $aMirrors
EndFunc

Func _UpgradeGetDefaultGithubDirectMirror()
    Return $UPGRADE_DEFAULT_GITHUB_DIRECT_MIRROR
EndFunc

; The built-in GitHub API proxy is intended for Simplified Chinese users only.
; Keep the setting itself empty unless the user explicitly configures it.
Func _UpgradeGetDefaultGithubApiMirror($sLanguage = "")
	If StringLower($sLanguage) = "zh-cn" Then Return $UPGRADE_DEFAULT_GITHUB_API_MIRROR
	Return ""
EndFunc

Func _UpgradeGetDefaultUrlProxy()
    Return $UPGRADE_DEFAULT_URL_PROXY
EndFunc

Func _UpgradeNormalizeMirrorAddress($sMirrorAddress)
    $sMirrorAddress = StringStripWS($sMirrorAddress, 3)
    If $sMirrorAddress = "" Then Return ""
    If StringRight($sMirrorAddress, 1) <> "/" Then $sMirrorAddress &= "/"
    Return $sMirrorAddress
EndFunc

Func _UpgradeIsJsDelivrGithubMirror($sMirrorAddress)
    $sMirrorAddress = StringLower($sMirrorAddress)
    Return StringInStr($sMirrorAddress, "jsdelivr.net/gh") Or StringInStr($sMirrorAddress, "jsdmirror.com/gh")
EndFunc

Func _UpgradeBuildGithubPageUrl($sGithubUrl, $sMirrorAddress)
    ; URL routing is applied by DownloadTools at request time so failure can
    ; fall back to the original upstream URL.
    Return $sGithubUrl
EndFunc

Func _UpgradeAddUrl(ByRef $aUrls, ByRef $iCount, $sUrl)
    If $sUrl = "" Then Return
    For $i = 0 To $iCount - 1
        If $aUrls[$i] = $sUrl Then Return
    Next
    ReDim $aUrls[$iCount + 1]
    $aUrls[$iCount] = $sUrl
    $iCount = $iCount + 1
EndFunc

Func _UpgradeBuildGithubDirectUrls($sGithubUrl, $sDirectMirror)
    Return _DownloadToolsBuildUrlCandidatesForConfig($sGithubUrl, $DT_Language, $sDirectMirror, "", "")
EndFunc

; Build a proxy-first chain for any absolute upstream URL. GitHub-only fallback
; mirrors are intentionally excluded because they may reject non-GitHub hosts.
Func _UpgradeBuildUrlProxyUrls($sUrl, $sConfiguredProxy = "")
    Return _DownloadToolsBuildUrlCandidatesForConfig($sUrl, $DT_Language, "", "", "", $sConfiguredProxy)
EndFunc

; Build GitHub API request URLs with a dedicated API proxy first, then the
; configured/default direct mirror and finally the official endpoint.
Func _UpgradeBuildGithubApiUrls($sGithubUrl, $sApiMirror = "", $sDirectMirror = $UPGRADE_DEFAULT_GITHUB_DIRECT_MIRROR)
    Return _DownloadToolsBuildUrlCandidatesForConfig($sGithubUrl, $DT_Language, $sDirectMirror, "", $sApiMirror)
EndFunc

Func _UpgradeBuildGithubReleaseDownloadUrls($sGithubUrl, $sDirectMirror, $sJsDelivrMirror = "")
    Return _DownloadToolsBuildUrlCandidatesForConfig($sGithubUrl, $DT_Language, $sDirectMirror, $sJsDelivrMirror, "")
EndFunc

Func RemoveHTMLTags($str)
    ;~ 使用正则表达式删除HTML标签
    Return StringRegExpReplace($str, '<[^>]*>', '')
EndFunc

Func GetLatestReleaseVersion($sRepositoryName, $sDirectMirror = $UPGRADE_DEFAULT_GITHUB_DIRECT_MIRROR, $sJsDelivrMirror = "")
    If _UpgradeIsJsDelivrGithubMirror($sDirectMirror) And $sJsDelivrMirror = "" Then
        $sJsDelivrMirror = $sDirectMirror
        $sDirectMirror = ""
    EndIf

    If _UpgradeIsJsDelivrGithubMirror($sJsDelivrMirror) Then
        Local $sJsDelivrVersion = GetLatestReleaseVersionByJsDelivr($sRepositoryName, $sJsDelivrMirror, $sDirectMirror)
        If $sJsDelivrVersion Then Return $sJsDelivrVersion
    EndIf

    ;~ 构建 GitHub releases 页面的 URL
    Local $sURL = _UpgradeBuildGithubPageUrl("https://github.com/" & $sRepositoryName & "/releases/", $sDirectMirror)
    ;~ 从 URL 获取页面内容
	Local $sPageContent = BinaryToString(_DownloadToolsReadUrl($sURL))

    If @error Then
;~ 		TrayTip("", StringFormat(_t("GetReleaseTagFailed", "获取更新信息失败！")))
		If $sJsDelivrMirror <> "" Then Return GetLatestReleaseVersionByJsDelivr($sRepositoryName, $sJsDelivrMirror, $sDirectMirror)
		Return ""
    EndIf

    ;~ 使用正则表达式提取版本号
    Local $aMatches = StringRegExp($sPageContent, '/' & $sRepositoryName & '/releases/tag/(v\d+\.\d+\.\d+)', 3)

    If @error Then
;~         TrayTip("", StringFormat(_t("GetReleaseTagFailed", "获取更新信息失败！"))) ''
		If $sJsDelivrMirror <> "" Then Return GetLatestReleaseVersionByJsDelivr($sRepositoryName, $sJsDelivrMirror, $sDirectMirror)
		Return ""
    EndIf

    ;~ 获取最新版本号
    Local $sLatestVersion = $aMatches[0]

    Return $sLatestVersion
EndFunc

Func GetLatestReleaseVersionByJsDelivr($sRepositoryName, $sConfiguredMirror = "", $sDirectMirror = "")
    ; jsDelivr release metadata is served only by the official data API.
    Local $sURL = "https://data.jsdelivr.com/v1/package/gh/" & $sRepositoryName
    Local $sPageContent = BinaryToString(_DownloadToolsReadUrl($sURL), 4)
    If @error Then Return ''
    Local $aMatches = StringRegExp($sPageContent, '"versions"\s*:\s*\[\s*"v?(\d+\.\d+\.\d+)"', 1)
    If Not @error Then Return "v" & $aMatches[0]
    Return ''
EndFunc

Func GetReleaseNotesByVersion($sRepositoryName, $version, $sMirrorAddress = $UPGRADE_DEFAULT_GITHUB_DIRECT_MIRROR)
    If _UpgradeIsJsDelivrGithubMirror($sMirrorAddress) Then Return ''

    ;~ 构建指定版本的 GitHub releases 页面的 URL
    Local $sURL = _UpgradeBuildGithubPageUrl("https://github.com/" & $sRepositoryName & "/releases/tag/" & $version, $sMirrorAddress)

    ;~ 从 URL 获取页面内容
	Local $sPageContent = BinaryToString(_DownloadToolsReadUrl($sURL), 4)

    If @error Then
        Return ''
    EndIf

    ;~ 定义开始和结束标记以提取发布说明部分
    Local $sStartTag = '"markdown-body my-3">'
    Local $sEndTag = '<div data-view-component="true" class="Box-footer">'

    ;~ 查找开始和结束标记的位置
    Local $iStartPos = StringInStr($sPageContent, $sStartTag)
    Local $iEndPos = StringInStr($sPageContent, $sEndTag, 0, -1)

    If $iStartPos = 0 Or $iEndPos = 0 Then
        Return ''
    EndIf

    ;~ 提取发布说明部分
    Local $sReleaseNotes = StringMid($sPageContent, $iStartPos, $iEndPos - $iStartPos)

    ;~ 移除 class="markdown-body my-3">
    $sReleaseNotes = StringReplace($sReleaseNotes, '"markdown-body my-3">', "")

    ;~ 调用 RemoveHTMLTags 函数以删除HTML标签
    $sReleaseNotes = RemoveHTMLTags($sReleaseNotes)

    Return $sReleaseNotes
EndFunc
