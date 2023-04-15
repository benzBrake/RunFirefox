#include "JSON.au3"
#include <Array.au3>
#include <FileConstants.au3>
Func UpdatePolices($FirefoxDir, $AllowBrowserUpdate)
	Local $policiesFolder = $FirefoxDir & "\distribution"
	Local $policiesFile = $policiesFolder & "\policies.json"
	Local $FileContent, $JSONObj, $DisableObj
	If $AllowBrowserUpdate = 0 Then
		If Not FileExists($policiesFolder) Then
			DirCreate($policiesFolder)
		EndIf
		If Not FileExists($policiesFile) Then
			; 如果文件不存在，则创建文件并写入策略内容
			$JSONObj = CreatePolicesObj()
		Else
			$FileContent = FileRead($policiesFile)
			$JSONObj = Json_Decode($FileContent)
			If Not Json_IsObject($JSONObj) Then
				$JSONObj = CreatePolicesObj()
			EndIf
		EndIf
		$JSONObj = UpdateJsonObj($JSONObj, Not $AllowBrowserUpdate)
		$FileContent = Json_Encode_Pretty($JSONObj, $JSON_PRETTY_PRINT, @TAB, "," & @CRLF, "," & @CRLF, ": ")
		Local $hFile = FileOpen($policiesFile, $FO_CREATEPATH + $FO_OVERWRITE)
		If $hFile <> -1 Then
			FileWrite($hFile, $FileContent)
			FileClose($hFile)
		EndIf
	Else
		If FileExists($policiesFolder) Then
			If FileExists($policiesFile) Then
				$FileContent = FileRead($policiesFile)
				$JSONObj = Json_Decode($FileContent)
				$JSONObj = UpdateJsonObj($JSONObj, Not $AllowBrowserUpdate)
				$File = FileOpen($policiesFile, 2)
				$FileContent = Json_Encode_Pretty($JSONObj, $JSON_PRETTY_PRINT, @TAB, "," & @CRLF, "," & @CRLF, ": ")
				FileWrite($File, $FileContent)
				FileClose($File)
			EndIf
		EndIf
	EndIf
EndFunc

Func CreatePolicesObj()
	$JSONObj = Json_ObjCreate();
	$DisableObj = Json_ObjCreate();
	Json_ObjPut($DisableObj, "DisableAppUpdate", "true");
	Json_ObjPut($JSONObj, "policies", $DisableObj);
	return $JSONObj
EndFunc

Func GetItemFromJsonObj($JSONObj, $key)
	Local $obj;
	If Not Json_ObjExists($JSONObj, $key) Then
		$obj = Json_ObjCreate();
	Else
		$obj = Json_ObjGet($JSONObj, $key)
	EndIf
	Return $obj
EndFunc

Func UpdateJsonObj($JSONObj, $allowUpdate = False)
	$PolicesObj = GetItemFromJsonObj($JSONObj, "polices");
	Json_ObjDelete($PolicesObj, "DisableAppUpdate")
	Json_ObjPut($PolicesObj, "DisableAppUpdate", $allowUpdate);
	Json_ObjDelete($JSONObj, "policies")
	Json_ObjPut($JSONObj, "policies", $PolicesObj);
	return $JSONObj
EndFunc