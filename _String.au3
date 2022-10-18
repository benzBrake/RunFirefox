#include-once

; #FUNCTION# ;===============================================================================
;
; Name...........: _StringStartsWith
; Description ...: Returns whether or not the given string begins with the specified text.
; Syntax.........: _StringStartsWith($sInput, $sSearch, $fCaseSensitive)
; Parameters ....: $sInput - The string to be searched
;				   $sSearch - The text to search for
;				   $fCaseSensitive - Specifies whether the search string should be case sensitive
; Return values .: Success - Returns true
;				   Failure - Returns false and sets @Error:
;				   |0 - No error.
;				   |1 - The search string is longer than the input string.
;				   |2 - The search string or the input string is empty.
; Author ........: Chris Coale (chris95219)
; Modified.......:
; Remarks .......:
; Related .......: _StringEndsWith
; Link ..........;
; Example .......; Yes
;
; ;==========================================================================================
Func _StringStartsWith($sInput, $sSearch, $fCaseSensitive = False)
	$iSearchLen = StringLen($sSearch)
	$iInputLen = StringLen($sInput)
	
	If (($sInput = "") Or ($sSearch = "")) Then
		SetError(2)
		Return False
	EndIf
	
	If ($iSearchLen > $iInputLen) Then
		SetError(1)
		Return False
	EndIf
	
	If ($fCaseSensitive == True) Then
		If (StringMid($sInput, 1, $iSearchLen) == $sSearch) Then
			Return True
		EndIf
	Else
		If (StringMid($sInput, 1, $iSearchLen) = $sSearch) Then
			Return True
		EndIf
	EndIf
	
	SetError(0)
	Return False
EndFunc   ;==>_StringStartsWith


; #FUNCTION# ;===============================================================================
;
; Name...........: _StringEndsWith
; Description ...: Returns whether or not the given string ends with the specified text.
; Syntax.........: _StringEndsWith($sInput, $sSearch, $fCaseSensitive)
; Parameters ....: $sInput - The string to be searched
;				   $sSearch - The text to search for
;				   $fCaseSensitive - Specifies whether the search string should be case sensitive
; Return values .: Success - Returns true
;				   Failure - Returns false and sets @Error:
;				   |0 - No error.
;				   |1 - The search string is longer than the input string.
;				   |2 - The search string or the input string is empty.
; Author ........: Chris Coale (chris95219)
; Modified.......:
; Remarks .......:
; Related .......: _StringStartsWith
; Link ..........;
; Example .......; Yes
;
; ;==========================================================================================
Func _StringEndsWith($sInput, $sSearch, $fCaseSensitive = False)
	$iSearchLen = StringLen($sSearch)
	$iInputLen = StringLen($sInput)
	
	If (($sInput = "") Or ($sSearch = "")) Then
		SetError(2)
		Return False
	EndIf
	
	If ($iSearchLen > $iInputLen) Then
		SetError(1)
		Return False
	EndIf
	
	If ($fCaseSensitive == True) Then
		If (StringMid($sInput, $iInputLen - $iSearchLen + 1, $iSearchLen) == $sSearch) Then
			Return True
		EndIf
	Else
		If (StringMid($sInput, $iInputLen - $iSearchLen + 1, $iSearchLen) = $sSearch) Then
			Return True
		EndIf
	EndIf
	
	SetError(0)
	Return False
EndFunc   ;==>_StringEndsWith