Func RemoveHTMLTags($str)
    ;~ 使用正则表达式删除HTML标签
    Return StringRegExpReplace($str, '<[^>]*>', '')
EndFunc

Func GetLatestReleaseVersion($sRepositoryName, $sMirrorAddress = "https://ghproxy.com/")
    ;~ 构建 GitHub releases 页面的 URL
    Local $sURL = $sMirrorAddress & "https://github.com/" & $sRepositoryName & "/releases/"
    ;~ 从 URL 获取页面内容
    Local $sPageContent = BinaryToString(InetRead($sURL, 1))

    If @error Then
;~ 		TrayTip("", StringFormat(_t("GetReleaseTagFailed", "获取更新信息失败！")))
        Return ''
    EndIf

    ;~ 使用正则表达式提取版本号
    Local $aMatches = StringRegExp($sPageContent, '/' & $sRepositoryName & '/releases/tag/(v\d+\.\d+\.\d+)', 3)

    If @error Then
;~         TrayTip("", StringFormat(_t("GetReleaseTagFailed", "获取更新信息失败！"))) ''
        Return ''
    EndIf

    ;~ 获取最新版本号
    Local $sLatestVersion = $aMatches[0]

    Return $sLatestVersion
EndFunc

Func GetReleaseNotesByVersion($sRepositoryName, $version, $sMirrorAddress = "https://ghproxy.com/")
    ;~ 构建指定版本的 GitHub releases 页面的 URL
    Local $sURL = $sMirrorAddress & "https://github.com/" & $sRepositoryName & "/releases/tag/" & $version

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
        MsgBox(16, "Error", "Failed to find release notes")
        Return
    EndIf

    ;~ 提取发布说明部分
    Local $sReleaseNotes = StringMid($sPageContent, $iStartPos, $iEndPos - $iStartPos)

    ;~ 移除 class="markdown-body my-3">
    $sReleaseNotes = StringReplace($sReleaseNotes, '"markdown-body my-3">', "")

    ;~ 调用 RemoveHTMLTags 函数以删除HTML标签
    $sReleaseNotes = RemoveHTMLTags($sReleaseNotes)

    Return $sReleaseNotes
EndFunc

