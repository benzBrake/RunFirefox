#include-once

#include "FirefoxPlaces.au3"

; Read Chromium's most visited HTTPS/HTTP URLs from the default profile.
Func _ChromiumHistoryGetFrequent($sUserDataDirectory, $iLimit, ByRef $aRows)
	Local $sDatabasePath = $sUserDataDirectory & "\Default\History"
	$iLimit = Int($iLimit)
	If Not FileExists($sDatabasePath) Or $iLimit < 1 Then Return SetError(1, 0, 0)

	Local $sSqliteLibraryPath = @SystemDir & "\winsqlite3.dll"
	If Not FileExists($sSqliteLibraryPath) Then Return SetError(2, 0, 0)
	Local $hSqlite = DllOpen($sSqliteLibraryPath)
	If $hSqlite = -1 Then Return SetError(2, 0, 0)

	Local $hDatabase = _FirefoxPlacesSqliteOpenReadOnly($hSqlite, $sDatabasePath)
	If Not $hDatabase Then
		DllClose($hSqlite)
		Return SetError(3, 0, 0)
	EndIf
	DllCall($hSqlite, _FirefoxPlacesSqliteCallType("int"), "sqlite3_busy_timeout", "ptr", $hDatabase, "int", 1000)

	Local $sSql = "SELECT IFNULL(title, url), url FROM urls " & _
			"WHERE hidden = 0 AND (url LIKE 'http://%' OR url LIKE 'https://%') " & _
			"AND visit_count > 0 ORDER BY visit_count DESC, last_visit_time DESC LIMIT " & $iLimit
	Local $aPrepare = DllCall($hSqlite, _FirefoxPlacesSqliteCallType("int"), "sqlite3_prepare16_v2", _
			"ptr", $hDatabase, "wstr", $sSql, "int", -1, "ptr*", 0, "ptr*", 0)
	If @error Or Not IsArray($aPrepare) Or $aPrepare[0] <> 0 Or Not $aPrepare[4] Then
		DllCall($hSqlite, _FirefoxPlacesSqliteCallType("int"), "sqlite3_close", "ptr", $hDatabase)
		DllClose($hSqlite)
		Return SetError(4, 0, 0)
	EndIf

	Local $hStatement = $aPrepare[4], $iRowCount = 0, $iStepResult = 0
	Local $aResult[$iLimit + 1][2]
	While $iRowCount < $iLimit
		Local $aStep = DllCall($hSqlite, _FirefoxPlacesSqliteCallType("int"), "sqlite3_step", "ptr", $hStatement)
		If @error Or Not IsArray($aStep) Then ExitLoop
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
	$aResult[0][0] = "title"
	$aResult[0][1] = "url"
	$aRows = $aResult
	Return $iRowCount
EndFunc   ;==>_ChromiumHistoryGetFrequent
