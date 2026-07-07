#include-once

Func _MozLz4_Decompress($content)
	Local Const $MAGIC = Binary("0x6D6F7A4C7A343000")
	Local $contentLen = BinaryLen($content)
	If $contentLen < 12 Then Return SetError(1, 0, Binary(""))
	If BinaryMid($content, 1, 8) <> $MAGIC Then Return SetError(2, 0, Binary(""))

	Local $uncompressedLen = _MozLz4_ReadUInt32LEFromBinary(BinaryMid($content, 9, 4))
	If $uncompressedLen = 0 Then Return SetError(0, 0, Binary(""))

	Local $block = BinaryMid($content, 13)
	Local $blockLen = BinaryLen($block)
	If $blockLen <= 0 Then Return SetError(3, 0, Binary(""))

	Local $src = DllStructCreate("byte[" & $blockLen & "]")
	Local $dst = DllStructCreate("byte[" & $uncompressedLen & "]")
	DllStructSetData($src, 1, $block)

	Local $srcPos = 0, $dstPos = 0
	Local $srcPtr = DllStructGetPtr($src)
	Local $dstPtr = DllStructGetPtr($dst)

	While $srcPos < $blockLen
		Local $token = _MozLz4_GetByte($src, $srcPos)
		$srcPos += 1

		Local $literalLen = BitShift($token, 4)
		If $literalLen = 15 Then
			While $srcPos < $blockLen
				Local $extraLiteral = _MozLz4_GetByte($src, $srcPos)
				$srcPos += 1
				$literalLen += $extraLiteral
				If $extraLiteral <> 255 Then ExitLoop
			WEnd
		EndIf

		If $srcPos + $literalLen > $blockLen Then Return SetError(4, 0, Binary(""))
		If $dstPos + $literalLen > $uncompressedLen Then Return SetError(5, 0, Binary(""))
		_MozLz4_MoveMemory($dstPtr + $dstPos, $srcPtr + $srcPos, $literalLen)
		$srcPos += $literalLen
		$dstPos += $literalLen

		If $srcPos >= $blockLen Then ExitLoop
		If $srcPos + 2 > $blockLen Then Return SetError(6, 0, Binary(""))

		Local $offset = _MozLz4_ReadUInt16LE($src, $srcPos)
		$srcPos += 2
		If $offset <= 0 Or $offset > $dstPos Then Return SetError(7, 0, Binary(""))

		Local $matchLen = BitAND($token, 0x0F)
		If $matchLen = 15 Then
			While $srcPos < $blockLen
				Local $extraMatch = _MozLz4_GetByte($src, $srcPos)
				$srcPos += 1
				$matchLen += $extraMatch
				If $extraMatch <> 255 Then ExitLoop
			WEnd
		EndIf
		$matchLen += 4

		If $dstPos + $matchLen > $uncompressedLen Then Return SetError(8, 0, Binary(""))
		_MozLz4_MoveMemory($dstPtr + $dstPos, $dstPtr + $dstPos - $offset, $matchLen)
		$dstPos += $matchLen
	WEnd

	If $dstPos <> $uncompressedLen Then Return SetError(9, 0, Binary(""))
	Return SetError(0, 0, BinaryMid(DllStructGetData($dst, 1), 1, $dstPos))
EndFunc   ;==>_MozLz4_Decompress

Func _MozLz4_Compress($content)
	Local Const $MAGIC = Binary("0x6D6F7A4C7A343000")
	Local Const $HASH_SIZE = 16384
	Local $srcLen = BinaryLen($content)
	If $srcLen = 0 Then Return SetError(0, 0, _MozLz4_BuildFile($MAGIC, 0, Binary("")))

	Local $src = DllStructCreate("byte[" & $srcLen & "]")
	DllStructSetData($src, 1, $content)
	Local $srcPtr = DllStructGetPtr($src)

	Local $maxCompressedLen = $srcLen + Int($srcLen / 255) + 17
	Local $out = DllStructCreate("byte[" & $maxCompressedLen & "]")
	Local $outPtr = DllStructGetPtr($out)
	Local $outPos = 0

	Local $hashTable[$HASH_SIZE]
	For $i = 0 To $HASH_SIZE - 1
		$hashTable[$i] = -1
	Next

	Local $anchor = 0
	Local $pos = 0

	While $pos <= $srcLen - 4
		Local $hash = _MozLz4_Hash($src, $pos, $HASH_SIZE)
		Local $ref = $hashTable[$hash]
		$hashTable[$hash] = $pos

		If $ref >= 0 And $pos - $ref <= 0xFFFF And _MozLz4_Match4($src, $ref, $pos) Then
			Local $literalLen = $pos - $anchor
			Local $matchLen = 4
			While $pos + $matchLen < $srcLen And _MozLz4_GetByte($src, $ref + $matchLen) = _MozLz4_GetByte($src, $pos + $matchLen)
				$matchLen += 1
			WEnd

			Local $token = 0
			If $literalLen < 15 Then
				$token = BitOR($token, BitShift($literalLen, -4))
			Else
				$token = BitOR($token, 0xF0)
			EndIf

			Local $matchCodeLen = $matchLen - 4
			If $matchCodeLen < 15 Then
				$token = BitOR($token, $matchCodeLen)
			Else
				$token = BitOR($token, 0x0F)
			EndIf

			_MozLz4_WriteByte($out, $outPos, $token)

			If $literalLen >= 15 Then
				Local $literalExtra = $literalLen - 15
				While $literalExtra >= 255
					_MozLz4_WriteByte($out, $outPos, 255)
					$literalExtra -= 255
				WEnd
				_MozLz4_WriteByte($out, $outPos, $literalExtra)
			EndIf

			_MozLz4_MoveMemory($outPtr + $outPos, $srcPtr + $anchor, $literalLen)
			$outPos += $literalLen

			Local $offset = $pos - $ref
			_MozLz4_WriteByte($out, $outPos, BitAND($offset, 0xFF))
			_MozLz4_WriteByte($out, $outPos, BitAND(BitShift($offset, 8), 0xFF))

			If $matchCodeLen >= 15 Then
				Local $matchExtra = $matchCodeLen - 15
				While $matchExtra >= 255
					_MozLz4_WriteByte($out, $outPos, 255)
					$matchExtra -= 255
				WEnd
				_MozLz4_WriteByte($out, $outPos, $matchExtra)
			EndIf

			Local $matchEnd = $pos + $matchLen
			For $i = $pos + 1 To $matchEnd - 3
				If $i <= $srcLen - 4 Then
					$hashTable[_MozLz4_Hash($src, $i, $HASH_SIZE)] = $i
				EndIf
			Next

			$pos = $matchEnd
			$anchor = $pos
			ContinueLoop
		EndIf

		$pos += 1
	WEnd

	Local $lastLiteralLen = $srcLen - $anchor
	Local $lastToken = 0
	If $lastLiteralLen < 15 Then
		$lastToken = BitShift($lastLiteralLen, -4)
	Else
		$lastToken = 0xF0
	EndIf
	_MozLz4_WriteByte($out, $outPos, $lastToken)

	If $lastLiteralLen >= 15 Then
		Local $lastExtra = $lastLiteralLen - 15
		While $lastExtra >= 255
			_MozLz4_WriteByte($out, $outPos, 255)
			$lastExtra -= 255
		WEnd
		_MozLz4_WriteByte($out, $outPos, $lastExtra)
	EndIf

	_MozLz4_MoveMemory($outPtr + $outPos, $srcPtr + $anchor, $lastLiteralLen)
	$outPos += $lastLiteralLen

	Local $block = BinaryMid(DllStructGetData($out, 1), 1, $outPos)
	Return SetError(0, 0, _MozLz4_BuildFile($MAGIC, $srcLen, $block))
EndFunc   ;==>_MozLz4_Compress

Func _MozLz4_BuildFile($magic, $uncompressedLen, $block)
	Local $blockLen = BinaryLen($block)
	Local $result = DllStructCreate("byte[" & (12 + $blockLen) & "]")
	Local $resultPtr = DllStructGetPtr($result)

	Local $magicBuf = DllStructCreate("byte[8]")
	DllStructSetData($magicBuf, 1, $magic)
	_MozLz4_MoveMemory($resultPtr, DllStructGetPtr($magicBuf), 8)

	_MozLz4_SetByte($result, 8, BitAND($uncompressedLen, 0xFF))
	_MozLz4_SetByte($result, 9, BitAND(BitShift($uncompressedLen, 8), 0xFF))
	_MozLz4_SetByte($result, 10, BitAND(BitShift($uncompressedLen, 16), 0xFF))
	_MozLz4_SetByte($result, 11, BitAND(BitShift($uncompressedLen, 24), 0xFF))

	If $blockLen > 0 Then
		Local $blockBuf = DllStructCreate("byte[" & $blockLen & "]")
		DllStructSetData($blockBuf, 1, $block)
		_MozLz4_MoveMemory($resultPtr + 12, DllStructGetPtr($blockBuf), $blockLen)
	EndIf

	Return SetError(0, 0, BinaryMid(DllStructGetData($result, 1), 1, 12 + $blockLen))
EndFunc   ;==>_MozLz4_BuildFile

Func _MozLz4_GetByte(ByRef $buffer, $index)
	Return DllStructGetData($buffer, 1, $index + 1)
EndFunc   ;==>_MozLz4_GetByte

Func _MozLz4_SetByte(ByRef $buffer, $index, $value)
	DllStructSetData($buffer, 1, BitAND($value, 0xFF), $index + 1)
EndFunc   ;==>_MozLz4_SetByte

Func _MozLz4_WriteByte(ByRef $buffer, ByRef $index, $value)
	DllStructSetData($buffer, 1, BitAND($value, 0xFF), $index + 1)
	$index += 1
EndFunc   ;==>_MozLz4_WriteByte

Func _MozLz4_ReadUInt16LE(ByRef $buffer, $index)
	Return _MozLz4_GetByte($buffer, $index) + _MozLz4_GetByte($buffer, $index + 1) * 256
EndFunc   ;==>_MozLz4_ReadUInt16LE

Func _MozLz4_ReadUInt32LEFromBinary($binaryData)
	Local $buf = DllStructCreate("byte[4]")
	DllStructSetData($buf, 1, $binaryData)
	Return _MozLz4_GetByte($buf, 0) + _MozLz4_GetByte($buf, 1) * 256 + _MozLz4_GetByte($buf, 2) * 65536 + _MozLz4_GetByte($buf, 3) * 16777216
EndFunc   ;==>_MozLz4_ReadUInt32LEFromBinary

Func _MozLz4_MoveMemory($dstPtr, $srcPtr, $length)
	If $length <= 0 Then Return
	DllCall("kernel32.dll", "none", "RtlMoveMemory", "ptr", Ptr($dstPtr), "ptr", Ptr($srcPtr), "ulong_ptr", $length)
EndFunc   ;==>_MozLz4_MoveMemory

Func _MozLz4_Hash(ByRef $buffer, $index, $hashSize)
	Local $b0 = _MozLz4_GetByte($buffer, $index)
	Local $b1 = _MozLz4_GetByte($buffer, $index + 1)
	Local $b2 = _MozLz4_GetByte($buffer, $index + 2)
	Local $b3 = _MozLz4_GetByte($buffer, $index + 3)
	Return Mod($b0 * 251 + $b1 * 509 + $b2 * 1021 + $b3 * 2039, $hashSize)
EndFunc   ;==>_MozLz4_Hash

Func _MozLz4_Match4(ByRef $buffer, $left, $right)
	Return _MozLz4_GetByte($buffer, $left) = _MozLz4_GetByte($buffer, $right) _
			And _MozLz4_GetByte($buffer, $left + 1) = _MozLz4_GetByte($buffer, $right + 1) _
			And _MozLz4_GetByte($buffer, $left + 2) = _MozLz4_GetByte($buffer, $right + 2) _
			And _MozLz4_GetByte($buffer, $left + 3) = _MozLz4_GetByte($buffer, $right + 3)
EndFunc   ;==>_MozLz4_Match4
