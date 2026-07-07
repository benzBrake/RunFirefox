#include-once
#include <FileConstants.au3>
#include "ScriptingDictionary.au3"

Func GetTextFileEncodingMode($Path)
	If Not FileExists($Path) Then Return BitOR($FO_OVERWRITE, $FO_UTF8)

	Local $hFile = FileOpen($Path, $FO_BINARY)
	If $hFile = -1 Then Return BitOR($FO_OVERWRITE, $FO_UTF8)

	Local $Binary = FileRead($hFile)
	FileClose($hFile)

	Local $Header3 = Hex(BinaryMid($Binary, 1, 3))
	Local $Header2 = StringLeft($Header3, 4)
	If $Header3 = "EFBBBF" Then Return BitOR($FO_OVERWRITE, $FO_UTF8)
	If $Header2 = "FFFE" Or $Header2 = "FEFF" Then Return BitOR($FO_OVERWRITE, $FO_UNICODE)

	Local $Utf8Text = BinaryToString($Binary, $SB_UTF8)
	If StringToBinary($Utf8Text, $SB_UTF8) = $Binary Then Return BitOR($FO_OVERWRITE, $FO_UTF8_NOBOM)

	Return BitOR($FO_OVERWRITE, $FO_ANSI)
EndFunc   ;==>GetTextFileEncodingMode

Func ReadTextFileAuto($Path)
	If Not FileExists($Path) Then Return SetError(1, 0, "")

	Local $hFile = FileOpen($Path, $FO_BINARY)
	If $hFile = -1 Then Return SetError(2, 0, "")

	Local $Binary = FileRead($hFile)
	FileClose($hFile)

	Local $Header3 = Hex(BinaryMid($Binary, 1, 3))
	Local $Header2 = StringLeft($Header3, 4)
	If $Header3 = "EFBBBF" Then Return BinaryToString($Binary, $SB_UTF8)
	If $Header2 = "FFFE" Then Return BinaryToString($Binary, $SB_UTF16LE)
	If $Header2 = "FEFF" Then Return BinaryToString($Binary, $SB_UTF16BE)

	Local $Utf8Text = BinaryToString($Binary, $SB_UTF8)
	If StringToBinary($Utf8Text, $SB_UTF8) = $Binary Then Return $Utf8Text

	Return BinaryToString($Binary, $SB_ANSI)
EndFunc   ;==>ReadTextFileAuto

Func WriteTextFileAuto($Path, $Content)
	Local $Mode = GetTextFileEncodingMode($Path)
	Local $hFile = FileOpen($Path, $Mode)
	If $hFile = -1 Then Return False

	Local $Written = FileWrite($hFile, $Content)
	FileClose($hFile)
	Return $Written > 0
EndFunc   ;==>WriteTextFileAuto

Func ReadIniTextValue($ConfigPath, $SectionName, $Key, $Default)
	Local $Content = ReadTextFileAuto($ConfigPath)
	If @error Then Return $Default

	$Content = StringReplace($Content, @CRLF, @LF)
	$Content = StringReplace($Content, @CR, @LF)

	Local $Lines = StringSplit($Content, @LF, 1)
	Local $SectionHeader = "[" & StringLower($SectionName) & "]"
	Local $InSection = False

	For $i = 1 To $Lines[0]
		Local $Line = $Lines[$i]
		Local $Trimmed = StringLower(StringStripWS($Line, 3))

		If StringLeft($Trimmed, 1) = "[" And StringRight($Trimmed, 1) = "]" Then
			If $InSection Then ExitLoop
			$InSection = ($Trimmed = $SectionHeader)
			ContinueLoop
		EndIf

		If Not $InSection Then ContinueLoop
		If StringRegExp($Line, '^\s*' & $Key & '\s*=') Then
			Return StringRegExpReplace($Line, '^\s*' & $Key & '\s*=\s*', "")
		EndIf
	Next

	Return $Default
EndFunc   ;==>ReadIniTextValue

Func WriteIniTextValue($ConfigPath, $SectionName, $Key, $Value)
	Local $Content = ReadTextFileAuto($ConfigPath)
	If @error Then Return False

	$Content = StringReplace($Content, @CRLF, @LF)
	$Content = StringReplace($Content, @CR, @LF)

	Local $Lines = StringSplit($Content, @LF, 1)
	Local $SectionHeader = "[" & StringLower($SectionName) & "]"
	Local $Output = ""
	Local $InSection = False
	Local $SectionFound = False
	Local $KeyWritten = False

	For $i = 1 To $Lines[0]
		Local $Line = $Lines[$i]
		Local $Trimmed = StringLower(StringStripWS($Line, 3))
		Local $IsSection = StringLeft($Trimmed, 1) = "[" And StringRight($Trimmed, 1) = "]"

		If $IsSection Then
			If $InSection And Not $KeyWritten Then
				$Output &= $Key & "=" & $Value & @CRLF
				$KeyWritten = True
			EndIf

			$InSection = ($Trimmed = $SectionHeader)
			If $InSection Then $SectionFound = True
			$Output &= $Line & @CRLF
			ContinueLoop
		EndIf

		If $InSection And StringRegExp($Line, '^\s*' & $Key & '\s*=') Then
			If Not $KeyWritten Then
				$Output &= $Key & "=" & $Value & @CRLF
				$KeyWritten = True
			EndIf
			ContinueLoop
		EndIf

		$Output &= $Line & @CRLF
	Next

	If $InSection And Not $KeyWritten Then
		$Output &= $Key & "=" & $Value & @CRLF
		$KeyWritten = True
	EndIf

	If Not $SectionFound Then
		If $Output <> "" And StringRight($Output, 2) <> @CRLF Then $Output &= @CRLF
		$Output &= "[" & $SectionName & "]" & @CRLF & $Key & "=" & $Value & @CRLF
	EndIf

	Return WriteTextFileAuto($ConfigPath, $Output)
EndFunc   ;==>WriteIniTextValue

Func LoadIniDictionaryFromTextFile($Path)
	Local $Data = _InitDictionary()
	If $Path = "" Or Not FileExists($Path) Then Return $Data

	Local $Content = ReadTextFileAuto($Path)
	If @error Then Return $Data

	$Content = StringRegExpReplace($Content, "^\x{FEFF}+", "")
	$Content = StringReplace($Content, @CRLF, @LF)
	$Content = StringReplace($Content, @CR, @LF)

	Local $Lines = StringSplit($Content, @LF, 1)
	Local $CurrentSection = ""

	For $i = 1 To $Lines[0]
		Local $Line = StringRegExpReplace($Lines[$i], "^\x{FEFF}+", "")
		Local $Trimmed = StringStripWS($Line, 3)
		If $Trimmed = "" Or StringLeft($Trimmed, 1) = ";" Then ContinueLoop

		Local $SectionMatch = StringRegExp($Trimmed, '^\[([^\]]+)\]$', 1)
		If Not @error Then
			$CurrentSection = $SectionMatch[0]
			If Not _ItemExists($Data, $CurrentSection) Then _AddItem($Data, $CurrentSection, _InitDictionary())
			ContinueLoop
		EndIf

		If $CurrentSection = "" Then ContinueLoop

		Local $KeyValue = StringRegExp($Line, '^\s*([^=;\s][^=]*)=(.*)$', 1)
		If @error Then ContinueLoop

		Local $SectionData = _Item($Data, $CurrentSection)
		Local $Key = StringStripWS($KeyValue[0], 3)
		Local $Value = $KeyValue[1]
		If _ItemExists($SectionData, $Key) Then
			_ChangeItem($SectionData, $Key, $Value)
		Else
			_AddItem($SectionData, $Key, $Value)
		EndIf
	Next

	Return $Data
EndFunc   ;==>LoadIniDictionaryFromTextFile

Func ReadIniCacheValue($Data, $SectionName, $Key, $Default = "")
	If Not IsObj($Data) Or Not _ItemExists($Data, $SectionName) Then Return $Default

	Local $SectionData = _Item($Data, $SectionName)
	If Not IsObj($SectionData) Or Not _ItemExists($SectionData, $Key) Then Return $Default
	Return _Item($SectionData, $Key)
EndFunc   ;==>ReadIniCacheValue
