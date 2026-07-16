#include-once

Global Const $UPGRADE_DEFAULT_GITHUB_JSDELIVR_MIRROR_CHINA = "https://cdn.jsdmirror.com/gh"
Global Const $UPGRADE_DEFAULT_GITHUB_JSDELIVR_MIRROR_GLOBAL = "https://gocre.jsdelivr.net/gh"
Global Const $UPGRADE_DEFAULT_GITHUB_DIRECT_MIRROR = "https://box.w0x7ce.eu/proxy/"
Global Const $UPGRADE_FALLBACK_GITHUB_DIRECT_MIRRORS = "https://gh-proxy.org/|https://gh.llkk.cc/|https://ghproxy.net/"

Func _UpgradeIsChineseLanguage($sLanguage = "")
    If StringRegExp($sLanguage, "(?i)^zh") Then Return True
    Return StringRegExp(@OSLang, "^(0804|0404|0C04|1004|1404)$")
EndFunc

Func _UpgradeGetDefaultGithubMirror($sLanguage = "")
    Return _UpgradeGetDefaultGithubJsDelivrMirror($sLanguage)
EndFunc

Func _UpgradeGetDefaultGithubJsDelivrMirror($sLanguage = "")
    If _UpgradeIsChineseLanguage($sLanguage) Then Return $UPGRADE_DEFAULT_GITHUB_JSDELIVR_MIRROR_CHINA
    Return $UPGRADE_DEFAULT_GITHUB_JSDELIVR_MIRROR_GLOBAL
EndFunc

Func _UpgradeGetDefaultGithubDirectMirror()
    Return $UPGRADE_DEFAULT_GITHUB_DIRECT_MIRROR
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
    $sMirrorAddress = _UpgradeNormalizeMirrorAddress($sMirrorAddress)
    If $sMirrorAddress = "" Or _UpgradeIsJsDelivrGithubMirror($sMirrorAddress) Then Return $sGithubUrl
    Return $sMirrorAddress & $sGithubUrl
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
    Local $aUrls[1], $iCount = 0
    $sDirectMirror = _UpgradeNormalizeMirrorAddress($sDirectMirror)
    If $sDirectMirror <> "" And Not _UpgradeIsJsDelivrGithubMirror($sDirectMirror) Then _UpgradeAddUrl($aUrls, $iCount, $sDirectMirror & $sGithubUrl)
    Local $aFallbackMirrors = StringSplit($UPGRADE_FALLBACK_GITHUB_DIRECT_MIRRORS, "|", 2)
    For $i = 0 To UBound($aFallbackMirrors) - 1
        Local $sFallbackMirror = _UpgradeNormalizeMirrorAddress($aFallbackMirrors[$i])
        If $sFallbackMirror <> "" Then _UpgradeAddUrl($aUrls, $iCount, $sFallbackMirror & $sGithubUrl)
    Next
    _UpgradeAddUrl($aUrls, $iCount, $sGithubUrl)
    ReDim $aUrls[$iCount]
    Return $aUrls
EndFunc

Func _UpgradeBuildGithubReleaseDownloadUrls($sGithubUrl, $sDirectMirror, $sJsDelivrMirror = "")
    $sDirectMirror = _UpgradeNormalizeMirrorAddress($sDirectMirror)
    $sJsDelivrMirror = _UpgradeNormalizeMirrorAddress($sJsDelivrMirror)
    If _UpgradeIsJsDelivrGithubMirror($sDirectMirror) Then
        $sJsDelivrMirror = $sDirectMirror
        $sDirectMirror = ""
    EndIf
    ; jsDelivr-style /gh mirrors repository files; release assets need a direct GitHub URL mirror.
    Return _UpgradeBuildGithubDirectUrls($sGithubUrl, $sDirectMirror)
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
        Local $sJsDelivrVersion = GetLatestReleaseVersionByJsDelivr($sRepositoryName)
        If $sJsDelivrVersion Then Return $sJsDelivrVersion
    EndIf

    ;~ 构建 GitHub releases 页面的 URL
    Local $sURL = _UpgradeBuildGithubPageUrl("https://github.com/" & $sRepositoryName & "/releases/", $sDirectMirror)
    ;~ 从 URL 获取页面内容
    Local $sPageContent = BinaryToString(InetRead($sURL, 1))

    If @error Then
;~ 		TrayTip("", StringFormat(_t("GetReleaseTagFailed", "获取更新信息失败！")))
        Return GetLatestReleaseVersionByJsDelivr($sRepositoryName)
    EndIf

    ;~ 使用正则表达式提取版本号
    Local $aMatches = StringRegExp($sPageContent, '/' & $sRepositoryName & '/releases/tag/(v\d+\.\d+\.\d+)', 3)

    If @error Then
;~         TrayTip("", StringFormat(_t("GetReleaseTagFailed", "获取更新信息失败！"))) ''
        Return GetLatestReleaseVersionByJsDelivr($sRepositoryName)
    EndIf

    ;~ 获取最新版本号
    Local $sLatestVersion = $aMatches[0]

    Return $sLatestVersion
EndFunc

Func GetLatestReleaseVersionByJsDelivr($sRepositoryName)
    Local $sURL = "https://data.jsdelivr.com/v1/package/gh/" & $sRepositoryName
    Local $sPageContent = BinaryToString(InetRead($sURL, 1), 4)
    If @error Then Return ''

    Local $aMatches = StringRegExp($sPageContent, '"versions"\s*:\s*\[\s*"v?(\d+\.\d+\.\d+)"', 1)
    If @error Then Return ''

    Return "v" & $aMatches[0]
EndFunc

Func GetReleaseNotesByVersion($sRepositoryName, $version, $sMirrorAddress = $UPGRADE_DEFAULT_GITHUB_DIRECT_MIRROR)
    If _UpgradeIsJsDelivrGithubMirror($sMirrorAddress) Then Return ''

    ;~ 构建指定版本的 GitHub releases 页面的 URL
    Local $sURL = _UpgradeBuildGithubPageUrl("https://github.com/" & $sRepositoryName & "/releases/tag/" & $version, $sMirrorAddress)

    ;~ 从 URL 获取页面内容
    Local $sPageContent = BinaryToString(InetRead($sURL, 1), 4)

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
