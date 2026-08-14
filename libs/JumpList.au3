#include-once

#include <WinAPIMisc.au3>

Global Const $JL_CLSID_DESTINATION_LIST = "{77F10CF0-3DB5-4966-B520-B7C54FD35ED6}"
Global Const $JL_IID_ICUSTOM_DESTINATION_LIST = "{6332DEBF-87B5-4670-90C0-5E57B408A49E}"
Global Const $JL_CLSID_OBJECT_COLLECTION = "{2D3468C1-36A7-43B6-AC24-D3F02FD9607A}"
Global Const $JL_IID_IOBJECT_COLLECTION = "{5632B1A4-E38A-400A-928A-D4CD63230295}"
Global Const $JL_IID_IOBJECT_ARRAY = "{92CA9DCD-5622-4BBA-A805-5E9F541BD8C9}"
Global Const $JL_CLSID_SHELL_LINK = "{00021401-0000-0000-C000-000000000046}"
Global Const $JL_IID_ISHELL_LINK_W = "{000214F9-0000-0000-C000-000000000046}"
Global Const $JL_IID_IPROPERTY_STORE = "{886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99}"

Global Const $JL_TAG_ICUSTOM_DESTINATION_LIST = _
		"SetAppID hresult(wstr);" & _
		"BeginList hresult(dword*;ptr;ptr*);" & _
		"AppendCategory hresult(wstr;ptr);" & _
		"AppendKnownCategory hresult(dword);" & _
		"AddUserTasks hresult(ptr);" & _
		"CommitList hresult();" & _
		"GetRemovedDestinations hresult(ptr;ptr*);" & _
		"DeleteList hresult(wstr);" & _
		"AbortList hresult();"

Global Const $JL_TAG_IOBJECT_ARRAY = _
		"GetCount hresult(dword*);" & _
		"GetAt hresult(dword;ptr;ptr*);"

Global Const $JL_TAG_IOBJECT_COLLECTION = $JL_TAG_IOBJECT_ARRAY & _
		"AddObject hresult(ptr);" & _
		"AddFromArray hresult(ptr);" & _
		"RemoveObjectAt hresult(dword);" & _
		"Clear hresult();"

Global Const $JL_TAG_ISHELL_LINK_W = _
		"GetPath hresult(ptr;int;ptr;dword);" & _
		"GetIDList hresult(ptr*);" & _
		"SetIDList hresult(ptr);" & _
		"GetDescription hresult(ptr;int);" & _
		"SetDescription hresult(wstr);" & _
		"GetWorkingDirectory hresult(ptr;int);" & _
		"SetWorkingDirectory hresult(wstr);" & _
		"GetArguments hresult(ptr;int);" & _
		"SetArguments hresult(wstr);" & _
		"GetHotkey hresult(word*);" & _
		"SetHotkey hresult(word);" & _
		"GetShowCmd hresult(int*);" & _
		"SetShowCmd hresult(int);" & _
		"GetIconLocation hresult(ptr;int;int*);" & _
		"SetIconLocation hresult(wstr;int);" & _
		"SetRelativePath hresult(wstr;dword);" & _
		"Resolve hresult(hwnd;dword);" & _
		"SetPath hresult(wstr);"

Global Const $JL_TAG_IPROPERTY_STORE = _
		"GetCount hresult(dword*);" & _
		"GetAt hresult(dword;ptr);" & _
		"GetValue hresult(ptr;ptr);" & _
		"SetValue hresult(ptr;ptr);" & _
		"Commit hresult();"

Global Const $JL_TAG_PROPERTY_KEY = "struct;ulong Data1;ushort Data2;ushort Data3;byte Data4[8];dword pid;endstruct"
Global Const $JL_TAG_PROP_VARIANT = "ushort vt;ushort reserved1;ushort reserved2;ushort reserved3;ptr value;ptr value2"
Global Const $JL_VT_LPWSTR = 31

; $aTasks and $aDestinations use columns: title, arguments, description, icon index.
Func _JumpListBuild($sAppId, $sLauncherPath, $sWorkingDirectory, $sIconPath, ByRef $aTasks, $iTaskCount, $sCategoryTitle, ByRef $aDestinations, $iDestinationCount)
	If $sAppId = "" Or Not FileExists($sLauncherPath) Then Return SetError(1, 0, False)

	Local $oDestinationList = ObjCreateInterface($JL_CLSID_DESTINATION_LIST, $JL_IID_ICUSTOM_DESTINATION_LIST, $JL_TAG_ICUSTOM_DESTINATION_LIST)
	If Not IsObj($oDestinationList) Then Return SetError(2, 0, False)

	Local $iResult = $oDestinationList.SetAppID($sAppId)
	If Not _JumpListSucceeded($iResult) Then Return SetError(3, $iResult, False)

	Local $tObjectArrayIid = _WinAPI_GUIDFromString($JL_IID_IOBJECT_ARRAY)
	Local $iMaxSlots = 0, $pRemovedItems = 0
	$iResult = $oDestinationList.BeginList($iMaxSlots, DllStructGetPtr($tObjectArrayIid), $pRemovedItems)
	If Not _JumpListSucceeded($iResult) Then Return SetError(4, $iResult, False)

	Local $oRemovedItems = 0, $oRemovedArguments = ObjCreate("Scripting.Dictionary")
	If $pRemovedItems Then
		$oRemovedItems = ObjCreateInterface($pRemovedItems, $JL_IID_IOBJECT_ARRAY, $JL_TAG_IOBJECT_ARRAY)
		_JumpListCollectRemovedArguments($oRemovedItems, $oRemovedArguments)
	EndIf

	Local $oTasks = _JumpListCreateCollection()
	If Not IsObj($oTasks) Then
		$oDestinationList.AbortList()
		Return SetError(5, 0, False)
	EndIf

	Local $i
	For $i = 0 To $iTaskCount - 1
		Local $oTask = _JumpListCreateLink($sLauncherPath, $aTasks[$i][1], $sWorkingDirectory, $aTasks[$i][0], $aTasks[$i][2], $sIconPath, $aTasks[$i][3])
		If IsObj($oTask) Then _JumpListAddObject($oTasks, $oTask)
	Next

	Local $pTaskArray = 0, $oTaskArray = _JumpListQueryObjectArray($oTasks, $pTaskArray)
	If IsObj($oTaskArray) And $pTaskArray Then
		$iResult = $oDestinationList.AddUserTasks($pTaskArray)
		If Not _JumpListSucceeded($iResult) Then
			$oDestinationList.AbortList()
			Return SetError(6, $iResult, False)
		EndIf
	EndIf

	If $iDestinationCount > 0 And $iMaxSlots > 0 Then
		Local $oDestinations = _JumpListCreateCollection()
		If IsObj($oDestinations) Then
			Local $iAdded = 0
			For $i = 0 To $iDestinationCount - 1
				If $iAdded >= $iMaxSlots Then ExitLoop
				If IsObj($oRemovedArguments) And $oRemovedArguments.Exists($aDestinations[$i][1]) Then ContinueLoop

				Local $oDestination = _JumpListCreateLink($sLauncherPath, $aDestinations[$i][1], $sWorkingDirectory, $aDestinations[$i][0], $aDestinations[$i][2], $sIconPath, $aDestinations[$i][3])
				If IsObj($oDestination) And _JumpListAddObject($oDestinations, $oDestination) Then $iAdded += 1
			Next

			If $iAdded > 0 Then
				Local $pDestinationArray = 0, $oDestinationArray = _JumpListQueryObjectArray($oDestinations, $pDestinationArray)
				If IsObj($oDestinationArray) And $pDestinationArray Then
					$iResult = $oDestinationList.AppendCategory($sCategoryTitle, $pDestinationArray)
					If Not _JumpListSucceeded($iResult) Then
						$oDestinationList.AbortList()
						Return SetError(7, $iResult, False)
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

	$iResult = $oDestinationList.CommitList()
	If Not _JumpListSucceeded($iResult) Then
		$oDestinationList.AbortList()
		Return SetError(8, $iResult, False)
	EndIf
	Return True
EndFunc   ;==>_JumpListBuild

Func _JumpListDelete($sAppId)
	If $sAppId = "" Then Return False
	Local $oDestinationList = ObjCreateInterface($JL_CLSID_DESTINATION_LIST, $JL_IID_ICUSTOM_DESTINATION_LIST, $JL_TAG_ICUSTOM_DESTINATION_LIST)
	If Not IsObj($oDestinationList) Then Return False
	Return _JumpListSucceeded($oDestinationList.DeleteList($sAppId))
EndFunc   ;==>_JumpListDelete

Func _JumpListCreateCollection()
	Return ObjCreateInterface($JL_CLSID_OBJECT_COLLECTION, $JL_IID_IOBJECT_COLLECTION, $JL_TAG_IOBJECT_COLLECTION)
EndFunc   ;==>_JumpListCreateCollection

Func _JumpListCreateLink($sPath, $sArguments, $sWorkingDirectory, $sTitle, $sDescription, $sIconPath, $iIconIndex)
	Local $oLink = ObjCreateInterface($JL_CLSID_SHELL_LINK, $JL_IID_ISHELL_LINK_W, $JL_TAG_ISHELL_LINK_W)
	If Not IsObj($oLink) Then Return SetError(1, 0, 0)

	If Not _JumpListSucceeded($oLink.SetPath($sPath)) Then Return SetError(2, 0, 0)
	If Not _JumpListSucceeded($oLink.SetArguments($sArguments)) Then Return SetError(3, 0, 0)
	If Not _JumpListSucceeded($oLink.SetWorkingDirectory($sWorkingDirectory)) Then Return SetError(4, 0, 0)
	$oLink.SetDescription($sDescription)
	$oLink.SetIconLocation($sIconPath, $iIconIndex)
	If Not _JumpListSetTitle($oLink, $sTitle) Then Return SetError(5, 0, 0)

	Return $oLink
EndFunc   ;==>_JumpListCreateLink

Func _JumpListSetTitle(ByRef $oLink, $sTitle)
	Local $tPropertyStoreIid = _WinAPI_GUIDFromString($JL_IID_IPROPERTY_STORE)
	Local $pPropertyStore = 0
	$oLink.QueryInterface($tPropertyStoreIid, $pPropertyStore)
	If Not $pPropertyStore Then Return False

	Local $oPropertyStore = ObjCreateInterface($pPropertyStore, $JL_IID_IPROPERTY_STORE, $JL_TAG_IPROPERTY_STORE)
	If Not IsObj($oPropertyStore) Then Return False

	Local $tTitleKey = _JumpListPropertyKey("{F29F85E0-4FF9-1068-AB91-08002B27B3D9}", 2)
	Local $tTitleValue = DllStructCreate($JL_TAG_PROP_VARIANT)
	DllStructSetData($tTitleValue, "vt", $JL_VT_LPWSTR)
	Local $aDuplicate = DllCall("Shlwapi.dll", "long", "SHStrDupW", "wstr", $sTitle, "ptr", DllStructGetPtr($tTitleValue) + 8)
	If @error Or Not IsArray($aDuplicate) Or $aDuplicate[0] <> 0 Then Return False

	Local $iResult = $oPropertyStore.SetValue(DllStructGetPtr($tTitleKey), DllStructGetPtr($tTitleValue))
	If _JumpListSucceeded($iResult) Then $iResult = $oPropertyStore.Commit()
	DllCall("Ole32.dll", "long", "PropVariantClear", "ptr", DllStructGetPtr($tTitleValue))
	Return _JumpListSucceeded($iResult)
EndFunc   ;==>_JumpListSetTitle

Func _JumpListPropertyKey($sGuid, $iPropertyId)
	Local $tKey = DllStructCreate($JL_TAG_PROPERTY_KEY)
	_WinAPI_GUIDFromStringEx($sGuid, DllStructGetPtr($tKey))
	DllStructSetData($tKey, "pid", $iPropertyId)
	Return $tKey
EndFunc   ;==>_JumpListPropertyKey

Func _JumpListAddObject(ByRef $oCollection, ByRef $oObject)
	Local $tShellLinkIid = _WinAPI_GUIDFromString($JL_IID_ISHELL_LINK_W)
	Local $pObject = 0
	$oObject.QueryInterface($tShellLinkIid, $pObject)
	If Not $pObject Then Return False

	Local $oObjectReference = ObjCreateInterface($pObject, $JL_IID_ISHELL_LINK_W, $JL_TAG_ISHELL_LINK_W)
	Local $iResult = $oCollection.AddObject($pObject)
	$oObjectReference = 0
	Return _JumpListSucceeded($iResult)
EndFunc   ;==>_JumpListAddObject

Func _JumpListQueryObjectArray(ByRef $oCollection, ByRef $pObjectArray)
	Local $tObjectArrayIid = _WinAPI_GUIDFromString($JL_IID_IOBJECT_ARRAY)
	$oCollection.QueryInterface($tObjectArrayIid, $pObjectArray)
	If Not $pObjectArray Then Return 0
	Return ObjCreateInterface($pObjectArray, $JL_IID_IOBJECT_ARRAY, $JL_TAG_IOBJECT_ARRAY)
EndFunc   ;==>_JumpListQueryObjectArray

Func _JumpListCollectRemovedArguments(ByRef $oRemovedItems, ByRef $oRemovedArguments)
	If Not IsObj($oRemovedItems) Or Not IsObj($oRemovedArguments) Then Return

	Local $iCount = 0
	If Not _JumpListSucceeded($oRemovedItems.GetCount($iCount)) Then Return
	Local $tShellLinkIid = _WinAPI_GUIDFromString($JL_IID_ISHELL_LINK_W)
	Local $i
	For $i = 0 To $iCount - 1
		Local $pLink = 0
		If Not _JumpListSucceeded($oRemovedItems.GetAt($i, DllStructGetPtr($tShellLinkIid), $pLink)) Or Not $pLink Then ContinueLoop
		Local $oLink = ObjCreateInterface($pLink, $JL_IID_ISHELL_LINK_W, $JL_TAG_ISHELL_LINK_W)
		If Not IsObj($oLink) Then ContinueLoop

		Local $tArguments = DllStructCreate("wchar[32768]")
		If _JumpListSucceeded($oLink.GetArguments(DllStructGetPtr($tArguments), 32768)) Then
			Local $sArguments = DllStructGetData($tArguments, 1)
			If $sArguments <> "" And Not $oRemovedArguments.Exists($sArguments) Then $oRemovedArguments.Add($sArguments, True)
		EndIf
	Next
EndFunc   ;==>_JumpListCollectRemovedArguments

Func _JumpListSucceeded($iResult)
	Return IsNumber($iResult) And $iResult >= 0
EndFunc   ;==>_JumpListSucceeded
