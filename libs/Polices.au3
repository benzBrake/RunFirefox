#include "JSON.au3"
#include <Array.au3>
#include <FileConstants.au3>

Func UpdatePolices($FirefoxDir, $key, $value)
    Local $policiesFolder = $FirefoxDir & "\distribution"
    Local $policiesFile = $policiesFolder & "\policies.json"
    Local $FileContent, $JSONObj, $DisableObj

    ;~ 如果文件夹不存在则创建
    If Not FileExists($policiesFolder) Then
        DirCreate($policiesFolder)
    EndIf

    If Not FileExists($policiesFile) Then
        ;~ 如果文件不存在，创建默认策略对象
        $JSONObj = CreateDefaultPolicesObj()
    Else
        ;~ 如果文件存在，读取文件内容
        $FileContent = FileRead($policiesFile)
        $JSONObj = Json_Decode($FileContent)
        If Not Json_IsObject($JSONObj) Then
            ;~ 文件内容不是对象，创建默认策略对象
            $JSONObj = CreateDefaultPolicesObj()
        EndIf
    EndIf

    ;~ 更新或删除JSON对象
    If $value = "" Then
        ;~ 如果值为空，删除属性
        DeleteJsonObj($JSONObj, $key)
    Else
        ;~ 否则更新属性
        UpdateJsonObj($JSONObj, $key, $value)
    EndIf

    ;~ 格式化 JSON 字符串
    $FileContent = Json_Encode_Pretty($JSONObj, $JSON_PRETTY_PRINT, @TAB, "," & @CRLF, "," & @CRLF, ": ")

    ; 将 "true" 替换为 true，"false" 替换为 false
    $FileContent = StringReplace($FileContent, '"true"', 'true')
    $FileContent = StringReplace($FileContent, '"false"', 'false')

    ; 写入文件
    Local $hFile = FileOpen($policiesFile, $FO_CREATEPATH + $FO_OVERWRITE)
    If $hFile <> -1 Then
        FileWrite($hFile, $FileContent)
        FileClose($hFile)
    EndIf
EndFunc

;~ 创建默认 Polices 对象
Func CreateDefaultPolicesObj()
    $JSONObj = Json_ObjCreate()
    $DisableObj = Json_ObjCreate()
    Json_ObjPut($DisableObj, "DisableAppUpdate", true)
    Json_ObjPut($DisableObj, "DontCheckDefaultBrowser", true)
    Json_ObjPut($JSONObj, "policies", $DisableObj)
    Return $JSONObj
EndFunc

Func GetItemFromJsonObj($JSONObj, $key)
    Local $obj
    If Not Json_ObjExists($JSONObj, $key) Then
        $obj = Json_ObjCreate()
    Else
        $obj = Json_ObjGet($JSONObj, $key)
    EndIf
    Return $obj
EndFunc

;~ 修改属性值
Func UpdateJsonObj($JSONObj, $key, $value)
    $PolicesObj = GetItemFromJsonObj($JSONObj, "policies")
    Json_ObjPut($PolicesObj, $key, $value)
EndFunc

;~ 删除属性
Func DeleteJsonObj($JSONObj, $key)
    $PolicesObj = GetItemFromJsonObj($JSONObj, "policies")
    If Json_ObjExists($PolicesObj, $key) Then
        Json_ObjDelete($PolicesObj, $key)
    EndIf
EndFunc