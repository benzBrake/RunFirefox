#include-once

Global Const $FIREFOX_PLACES_SQLITE_OPEN_READONLY = 0x00000001
Global Const $FIREFOX_PLACES_SQLITE_ROW = 100
Global Const $FIREFOX_PLACES_SQLITE_DONE = 101

Func _FirefoxPlacesGetFrequent($sProfileDirectory, $iLimit, ByRef $aRows)
	Local $sDatabasePath = $sProfileDirectory & "\places.sqlite"
	$iLimit = Int($iLimit)
	If Not FileExists($sDatabasePath) Or $iLimit < 1 Then Return SetError(1, 0, 0)

	; Windows supplies the correct winsqlite3.dll architecture through @SystemDir.
	; It is available on Windows 10 and later; fixed Jump List tasks still work without it.
	Local $sSqliteLibraryPath = @SystemDir & "\winsqlite3.dll"
	If Not FileExists($sSqliteLibraryPath) Then Return SetError(2, 0, 0)
	Local $hSqlite = DllOpen($sSqliteLibraryPath)
	If $hSqlite = -1 Then Return SetError(2, 0, 0)

	Local $hDatabase = _FirefoxPlacesSqliteOpenReadOnly($hSqlite, $sDatabasePath)
	If Not $hDatabase Then
		Local $iOpenError = @error, $iOpenResult = @extended
		DllClose($hSqlite)
		Return SetError(3 + $iOpenError, $iOpenResult, 0)
	EndIf

	DllCall($hSqlite, _FirefoxPlacesSqliteCallType("int"), "sqlite3_busy_timeout", "ptr", $hDatabase, "int", 1000)
	Local $sSql = "SELECT IFNULL(p.title, p.url), p.url " & _
			"FROM moz_places p " & _
			"WHERE p.hidden = 0 " & _
			"AND (p.url LIKE 'http://%' OR p.url LIKE 'https://%') " & _
			"AND EXISTS (SELECT 1 FROM moz_historyvisits v " & _
			"WHERE v.place_id = p.id AND v.visit_type NOT IN (0, 4, 8) LIMIT 1) " & _
			"ORDER BY p.visit_count DESC, p.last_visit_date DESC " & _
			"LIMIT " & $iLimit

	Local $aPrepare = DllCall($hSqlite, _FirefoxPlacesSqliteCallType("int"), "sqlite3_prepare16_v2", _
			"ptr", $hDatabase, "wstr", $sSql, "int", -1, "ptr*", 0, "ptr*", 0)
	If @error Or Not IsArray($aPrepare) Or $aPrepare[0] <> 0 Or Not $aPrepare[4] Then
		Local $iPrepareResult = 0
		If IsArray($aPrepare) Then $iPrepareResult = $aPrepare[0]
		DllCall($hSqlite, _FirefoxPlacesSqliteCallType("int"), "sqlite3_close", "ptr", $hDatabase)
		DllClose($hSqlite)
		Return SetError(6, $iPrepareResult, 0)
	EndIf

	Local $hStatement = $aPrepare[4], $iRowCount = 0, $iStepResult
	Local $aResult[$iLimit + 1][2]
	$aResult[0][0] = "title"
	$aResult[0][1] = "url"
	While $iRowCount < $iLimit
		Local $aStep = DllCall($hSqlite, _FirefoxPlacesSqliteCallType("int"), "sqlite3_step", "ptr", $hStatement)
		If @error Or Not IsArray($aStep) Then
			$iStepResult = -1
			ExitLoop
		EndIf
		$iStepResult = $aStep[0]
		If $iStepResult = $FIREFOX_PLACES_SQLITE_DONE Then ExitLoop
		If $iStepResult <> $FIREFOX_PLACES_SQLITE_ROW Then ExitLoop

		$iRowCount += 1
		$aResult[$iRowCount][0] = _FirefoxPlacesSqliteColumnText($hSqlite, $hStatement, 0)
		$aResult[$iRowCount][1] = _FirefoxPlacesSqliteColumnText($hSqlite, $hStatement, 1)
	WEnd

	DllCall($hSqlite, _FirefoxPlacesSqliteCallType("int"), "sqlite3_finalize", "ptr", $hStatement)
	DllCall($hSqlite, _FirefoxPlacesSqliteCallType("int"), "sqlite3_close", "ptr", $hDatabase)
	DllClose($hSqlite)
	If $iStepResult <> $FIREFOX_PLACES_SQLITE_DONE And $iStepResult <> $FIREFOX_PLACES_SQLITE_ROW Then Return SetError(5, $iStepResult, 0)

	ReDim $aResult[$iRowCount + 1][2]
	$aRows = $aResult
	Return $iRowCount
EndFunc   ;==>_FirefoxPlacesGetFrequent

Func _FirefoxPlacesSqliteOpenReadOnly($hSqlite, $sDatabasePath)
	Local $bDatabasePath = StringToBinary($sDatabasePath, 4)
	Local $tDatabasePath = DllStructCreate("byte[" & BinaryLen($bDatabasePath) + 1 & "]")
	DllStructSetData($tDatabasePath, 1, $bDatabasePath)

	Local $aOpen = DllCall($hSqlite, _FirefoxPlacesSqliteCallType("int"), "sqlite3_open_v2", _
			"struct*", $tDatabasePath, "ptr*", 0, "int", $FIREFOX_PLACES_SQLITE_OPEN_READONLY, "ptr", 0)
	If @error Or Not IsArray($aOpen) Then Return SetError(1, 0, 0)
	If $aOpen[0] <> 0 Then
		If $aOpen[2] Then DllCall($hSqlite, _FirefoxPlacesSqliteCallType("int"), "sqlite3_close", "ptr", $aOpen[2])
		Return SetError(2, $aOpen[0], 0)
	EndIf
	Return $aOpen[2]
EndFunc   ;==>_FirefoxPlacesSqliteOpenReadOnly

Func _FirefoxPlacesSqliteColumnText($hSqlite, $hStatement, $iColumn)
	Local $aText = DllCall($hSqlite, _FirefoxPlacesSqliteCallType("ptr"), "sqlite3_column_text16", "ptr", $hStatement, "int", $iColumn)
	If @error Or Not IsArray($aText) Or Not $aText[0] Then Return ""
	Local $aBytes = DllCall($hSqlite, _FirefoxPlacesSqliteCallType("int"), "sqlite3_column_bytes16", "ptr", $hStatement, "int", $iColumn)
	If @error Or Not IsArray($aBytes) Or $aBytes[0] <= 0 Then Return ""

	Local $tText = DllStructCreate("wchar[" & Int($aBytes[0] / 2) + 1 & "]", $aText[0])
	Return DllStructGetData($tText, 1)
EndFunc   ;==>_FirefoxPlacesSqliteColumnText

Func _FirefoxPlacesSqliteCallType($sReturnType)
	If @AutoItX64 Then $sReturnType &= ":cdecl"
	Return $sReturnType
EndFunc   ;==>_FirefoxPlacesSqliteCallType
