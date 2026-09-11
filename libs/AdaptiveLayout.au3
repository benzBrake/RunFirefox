; #current header comments =====================================================
; 声明式自适应布局库：按文案像素宽度流式排布控件
; 字母语言（英语/西班牙语等）文案远长于中文，固定坐标会导致标签重叠、控件截断；
; 本库用 GDI 实测文本宽度（取 GUI 控件字体，而非窗口默认字体），
; 控件从左到右依次排布，一行放不下自动换行，分组框高度随内容伸缩。
; 用法：
;   _ALInit($hGui) 后，用 _ALIt() 构造条目数组，再调用 _ALFlow() 排布；
;   _ALFlow 返回内容高度，ids 数组与条目一一对应（GAP/NEWLINE 为 0）。
; ==============================================================================
#include-once
#include <GUIConstantsEx.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>

Global Enum $AL_LABEL, $AL_COMBO, $AL_EDIT, $AL_CHECK, $AL_BUTTON, $AL_LINK, $AL_GAP, $AL_NEWLINE

Global $__AL_hGui = 0
Global $__AL_hFont = 0

; 设置测量所用窗口（每次创建设置窗口后调用一次，重置字体缓存）
Func _ALInit($hGui)
	$__AL_hGui = $hGui
	$__AL_hFont = 0
EndFunc   ;==>_ALInit

; 构造一个布局条目
Func _ALIt($iType, $v1 = Default, $v2 = Default, $v3 = Default)
	Local $a[4] = [$iType, $v1, $v2, $v3]
	Return $a
EndFunc   ;==>_ALIt

; 实测文本像素宽度（与 GUI 控件字体一致；GAP/NEWLINE 等空文本返回 0）
Func _ALMeasure($sText)
	If $sText = "" Then Return 0
	If Not $__AL_hFont Then
		; 必须取“控件”字体（受 GUISetFont 影响），GUI 窗口自身的字体是系统默认字体
		Local $idMeasureLabel = GUICtrlCreateLabel("", -100, -100, 10, 10)
		Local $aRet = DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", GUICtrlGetHandle($idMeasureLabel), "uint", 0x0031, "wparam", 0, "lparam", 0)
		$__AL_hFont = $aRet[0]
		GUICtrlDelete($idMeasureLabel)
	EndIf
	Local $aDC = DllCall("user32.dll", "handle", "GetDC", "hwnd", $__AL_hGui)
	If @error Then Return StringLen($sText) * 7
	Local $hDC = $aDC[0]
	Local $aOld = DllCall("gdi32.dll", "handle", "SelectObject", "handle", $hDC, "handle", $__AL_hFont)
	Local $tSIZE = DllStructCreate("long cx;long cy")
	Local $aW = DllCall("gdi32.dll", "int", "GetTextExtentPoint32W", "handle", $hDC, "wstr", $sText, "int", StringLen($sText), "struct*", $tSIZE)
	DllCall("gdi32.dll", "handle", "SelectObject", "handle", $hDC, "handle", $aOld[0])
	DllCall("user32.dll", "int", "ReleaseDC", "hwnd", $__AL_hGui, "handle", $hDC)
	If @error Or Not $aW[0] Then Return StringLen($sText) * 7 ; 测量失败时粗略兜底
	Return $tSIZE.cx
EndFunc   ;==>_ALMeasure

; 流式排布：从左到右，超出右边界自动换行（标签与其紧随的下拉/输入框不允许拆开）
; 返回内容占用高度；$aIds 与 $items 等长（GAP/NEWLINE 位置为 0）
; $iFirstRowEnd（可选）：返回首行内容的右端 x 坐标，供行尾右对齐控件用
Func _ALFlow(ByRef $items, $iLeft, $iTop, $iRight, ByRef $aIds, ByRef $iFirstRowEnd)
	Local $x = $iLeft, $y = $iTop
	Local $iRowH = 26, $iGap = 8, $iLabelGap = 4
	Local $iRow1End = -1
	Dim $aIds[UBound($items)]
	For $i = 0 To UBound($items) - 1
		Local $it = $items[$i]
		Switch $it[0]
			Case $AL_NEWLINE
				If $iRow1End = -1 Then $iRow1End = $x
				$x = $iLeft
				$y += $iRowH + 2
				ContinueLoop
			Case $AL_GAP
				$x += $it[1]
				ContinueLoop
		EndSwitch
		Local $sText = $it[1], $iW = 0, $id = 0
		Switch $it[0]
			Case $AL_LABEL, $AL_LINK
				$iW = _ALMeasure($sText)
			Case $AL_CHECK
				$iW = _ALMeasure($sText) + 20
			Case $AL_COMBO, $AL_EDIT, $AL_BUTTON
				If $it[0] = $AL_BUTTON And $it[2] = Default Then
					$iW = _ALMeasure($sText) + 20
				Else
					$iW = $it[2]
				EndIf
		EndSwitch
		Local $bLabelPair = False
		If $it[0] = $AL_LABEL Then
			If $i + 1 < UBound($items) Then
				Local $nxt0 = $items[$i + 1]
				If $nxt0[0] >= $AL_COMBO Then
					If $nxt0[0] <= $AL_EDIT Then $bLabelPair = True
				EndIf
			EndIf
		EndIf
		If $bLabelPair Then
			Local $nx = $items[$i + 1]
			If $x + $iW + $iLabelGap + $nx[2] > $iRight Then
				If $iRow1End = -1 Then $iRow1End = $x
				$x = $iLeft
				$y += $iRowH + 2
			EndIf
		ElseIf $x + $iW > $iRight And $x > $iLeft Then
			If $iRow1End = -1 Then $iRow1End = $x
			$x = $iLeft
			$y += $iRowH + 2
		EndIf
		Switch $it[0]
			Case $AL_LABEL
				$id = GUICtrlCreateLabel($sText, $x, $y + 5, $iW + 2, 17)
			Case $AL_LINK
				$id = GUICtrlCreateLabel($sText, $x, $y + 5, $iW + 12, 17)
				GUICtrlSetColor(-1, 0x0000FF)
			Case $AL_CHECK
				$id = GUICtrlCreateCheckbox($sText, $x, $y + 2, $iW + 4, 20)
			Case $AL_COMBO
				$id = GUICtrlCreateCombo("", $x, $y, $iW, 24, $CBS_DROPDOWNLIST)
				If $it[3] <> Default And $it[3] <> "" Then GUICtrlSetData(-1, $it[3], StringLeft($it[3], StringInStr($it[3] & "|", "|") - 1))
			Case $AL_EDIT
				$id = GUICtrlCreateEdit($sText, $x, $y + 1, $iW, 22, $ES_AUTOHSCROLL)
			Case $AL_BUTTON
				$id = GUICtrlCreateButton($sText, $x, $y + 1, $iW, 24)
		EndSwitch
		$x += $iW + (($it[0] = $AL_LABEL) ? $iLabelGap : $iGap)
		$aIds[$i] = $id
	Next
	If $iRow1End = -1 Then $iRow1End = $x
	$iFirstRowEnd = $iRow1End
	Return $y + $iRowH - $iTop
EndFunc   ;==>_ALFlow

; 长文案复选框：超宽时两行自动换行，返回控件 id（$iRowY 为该行顶部）
Func _ALCreateWrapCheckbox($sText, $iLeft, $iTop, $iWidth)
	Local $iH = 20
	If _ALMeasure($sText) + 20 > $iWidth Then $iH = 34
	Return GUICtrlCreateCheckbox($sText, $iLeft, $iTop, $iWidth, $iH, BitOR($BS_AUTOCHECKBOX, $BS_MULTILINE))
EndFunc   ;==>_ALCreateWrapCheckbox
