#include-once

Global Const $SQLITE_NATIVE_OPEN_READONLY = 0x00000001
Global Const $SQLITE_NATIVE_ROW = 100
Global Const $SQLITE_NATIVE_DONE = 101

Func _SqliteNativeOpenReadOnly($hSqlite, $sDatabasePath)
	Local $bDatabasePath = StringToBinary($sDatabasePath, 4)
	Local $tDatabasePath = DllStructCreate("byte[" & BinaryLen($bDatabasePath) + 1 & "]")
	DllStructSetData($tDatabasePath, 1, $bDatabasePath)

	Local $aOpen = DllCall($hSqlite, _SqliteNativeCallType("int"), "sqlite3_open_v2", _
			"struct*", $tDatabasePath, "ptr*", 0, "int", $SQLITE_NATIVE_OPEN_READONLY, "ptr", 0)
	If @error Or Not IsArray($aOpen) Then Return SetError(1, 0, 0)
	If $aOpen[0] <> 0 Then
		If $aOpen[2] Then DllCall($hSqlite, _SqliteNativeCallType("int"), "sqlite3_close", "ptr", $aOpen[2])
		Return SetError(2, $aOpen[0], 0)
	EndIf
	Return $aOpen[2]
EndFunc   ;==>_SqliteNativeOpenReadOnly

Func _SqliteNativeColumnText($hSqlite, $hStatement, $iColumn)
	Local $aText = DllCall($hSqlite, _SqliteNativeCallType("ptr"), "sqlite3_column_text16", "ptr", $hStatement, "int", $iColumn)
	If @error Or Not IsArray($aText) Or Not $aText[0] Then Return ""
	Local $aBytes = DllCall($hSqlite, _SqliteNativeCallType("int"), "sqlite3_column_bytes16", "ptr", $hStatement, "int", $iColumn)
	If @error Or Not IsArray($aBytes) Or $aBytes[0] <= 0 Then Return ""

	Local $tText = DllStructCreate("wchar[" & Int($aBytes[0] / 2) + 1 & "]", $aText[0])
	Return DllStructGetData($tText, 1)
EndFunc   ;==>_SqliteNativeColumnText

Func _SqliteNativeCallType($sReturnType)
	If @AutoItX64 Then $sReturnType &= ":cdecl"
	Return $sReturnType
EndFunc   ;==>_SqliteNativeCallType
