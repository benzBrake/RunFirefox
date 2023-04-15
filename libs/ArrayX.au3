;*******************************************************************************
;
;   Function List
;         __ArrayAdd()
;         __ArrayConcatenate()
;         __ArrayDelete()
;         __ArrayFindAll()
;         __ArrayGetBase()
;         __ArrayReplace()
;         __ArrayReverse()
;         __ArraySearch()
;         __ArrayToString()
;         __ArrayUnique()
;         _ArraySortClib()
;
;*******************************************************************************

#include-once

;===============================================================================
; Function Name:    __ArrayAdd()
; Description:      Adds a specified value at the end of an existing array.
; Syntax:           __ArrayAdd($avArray, "Value to add to $avArray")
; Parameter(s):     $avArray - Array to modify
;                             $vValue - Value to add
; Return Value(s):  Success - Returns 1
;                            Failure - Returns 0 and sets @error
; Requirements:      None.
; Author(s):        Jos van der Zande [jdeb at autoitscript dot com]
; Modifications:    Ultima - Code cleanup
;===============================================================================

Func __ArrayAdd(ByRef $avArray, $vValue)
  If Not IsArray($avArray) Then Return SetError(1, 0, 0)
  ReDim $avArray[UBound($avArray) + 1]
  $avArray[UBound($avArray) - 1] = $vValue
  Return 1
EndFunc    ;<===> __ArrayAdd()

;===============================================================================
; Function Name:    __ArrayConcatenate()
; Description:      Concatenate two arrays.
; Syntax:           __ArrayConcatenate(Array to Add to, Array to be added)
; Parameter(s):     $avArrayTarget - The array to concatenate onto
;                   $avArraySource - The array to concatenate from
; Return Value(s):  Success - Returns 1
;                   Failure - Returns 0 and sets @error
;                             [1 = $avArrayTarget is not an array
;                             [2 = $avArraySource is not an array
; Requirements:      None.
; Author(s):        Ultima
; Modifications:
;===============================================================================

Func __ArrayConcatenate(ByRef $avArrayTarget, ByRef $avArraySource)
  If Not IsArray($avArrayTarget) Then Return SetError(1, 0, 0)
  If Not IsArray($avArraySource) Then Return SetError(2, 0, 0)
  Local $iUBoundTarget = UBound($avArrayTarget), $iUBoundSource = UBound($avArraySource)
  ReDim $avArrayTarget[$iUBoundTarget + $iUBoundSource]
  
  For $i = 0 To $iUBoundSource-1
    $avArrayTarget[$iUBoundTarget + $i] = $avArraySource[$i]
  Next
  
  Return 1
EndFunc    ;<===> __ArrayConcatenate()

;===============================================================================
; Function Name:   __ArrayDelete()
; Description:    Deletes the specified element from the given array.
; Syntax:         __ArrayDelete(ByRef $avArray, $iElement)
; Parameter(s):  $avArray  - Array to modify
;                $iElement - Element to delete
; Return Value(s):  Success - New size of the array
;                   Failure - 0, sets @error to:
;                    |1 - $avArray is not an array
;                    |3 - $avArray has too many dimensions (only up to 2D supported)
;                    |(2 - Deprecated error code)
; Author(s):        Cephas <cephas at clergy dot net>
; Modifications:  Jos van der Zande <jdeb at autoitscript dot com> - array passed ByRef, Ultima - 2D arrays supported, reworked function (no longer needs temporary array; faster when deleting from end)
; Notes: If the array has one element left (or one row for 2D arrays), it will be set to "" after _ArrayDelete() is used on it.
;===============================================================================

Func __ArrayDelete(ByRef $avArray, $iElement)
  If Not IsArray($avArray) Then Return SetError(1, 0, 0)
  
  Local $iUBound = UBound($avArray, 1) - 1
  
  If Not $iUBound Then
    $avArray = ""
    Return 0
  EndIf
  
  ; Bounds checking
  If $iElement < 0 Then $iElement = 0
  If $iElement > $iUBound Then $iElement = $iUBound
  
  ; Move items after $iElement up by 1
  Switch UBound($avArray, 0)
    Case 1
      For $i = $iElement To $iUBound - 1
        $avArray[$i] = $avArray[$i + 1]
      Next
      ReDim $avArray[$iUBound]
    Case 2
      Local $iSubMax = UBound($avArray, 2) - 1
      For $i = $iElement To $iUBound - 1
        For $j = 0 To $iSubMax
          $avArray[$i][$j] = $avArray[$i + 1][$j]
        Next
      Next
      ReDim $avArray[$iUBound][$iSubMax + 1]
    Case Else
      Return SetError(3, 0, 0)
  EndSwitch
  
  Return $iUBound
EndFunc   ;<===>__ArrayDelete()

;===============================================================================
; Function Name:    __ArrayFindAll()
; Description:      Uses __ArraySearch() to find all ocurrences of a search query
;                                        between two points in an array.
; Syntax:           __ArrayFindAll($iArray, $iQuery[, $iStart = 0[,  $iEnd = 0[, $iCase = 0[, $iPartial = False]]]])
; Parameter(s):     $iArray - the array to search
;                   $iQuery - the search string
;                   $iStart - the element where the search should start. Usually 0 or 1
;                   $iEnd - the element where the search should stop searching.
;                   $iCase - 1 = case sensitive, 0 = not case sensitive. (default)
;                   $iPartialSearch - True = query must match the whole element.
;                                   - False = Match any portion of the element (default)
; Requirements:      #include <array.au3> and <file.au3>
; Return Value(s):  Success - Returns an array of the element numbers containing the search string
;                   Failure - Sets @Error to 1 and returns the no results message.
; Author(s):        George (GEOSoft) Gedye
; Modifications:
; Notes:            If any of the optional parameters are used then the preceeding parameters must also be used
; Example(s):
;===============================================================================

Func __ArrayFindAll($iArray, $iQuery, $iStart = 0,  $iEnd = 0, $iCase = 0, $iPartial = False)
  Local $Rtn = ''
  If $iEnd = 0 Then $iEnd = Ubound($iArray)-1
  If $iStart = 0 Then $iStart = __ArrayGetBase($iArray)
  
  While 1
    $aSrch = __ArraySearch($iArray, $iQuery, $iStart,  $iEnd, $iCase, $iPartial)
    If $aSrch <> -1 Then
      $Rtn &= $aSrch & '|'
      $iStart = $aSrch + 1
      If $iStart > $iEnd Then ExitLoop
    Else
      ExitLoop
    EndIf
  Wend
  
  If $Rtn <> '' Then
    $Rtn = StringSplit(StringTrimRight($Rtn, 1), '|')
    Return $Rtn
  Else
    Return SetError(1, 1, 'No matches to your query were found')
  EndIf
EndFunc    ;<===> __ArrayFindAll()

;===============================================================================
; Function Name:    __ArrayGetBase()
; Description:      Return the base element of an array (Usually 1 or 0)
; Syntax:           __ArrayGetBase($hArray)
; Parameter(s):     $hArray - The array to check
; Requirements:      None
; Return Value(s):  If element 0 contains the number of elements in the array then returns 1, else returns 0
; Author(s):        George (GEOSoft) Gedye
; Modifications:
; Notes:            This is primarily for use with functions like
;                    __ArraySort() or __ArrayReverse() where you do not want to
;                   perform an operation on the element holding the number of elements.
;===============================================================================

Func __ArrayGetBase($hArray)
  If $hArray[0] == Ubound($hArray)-1 Then Return 1
  Return 0
EndFunc    ;<===> __ArrayGetBase()

;===============================================================================
; Function Name:    __ArrayReplace()
; Description:      Replace a text string in elements of an array so we don't have to check the element at run time.
; Syntax:           __ArrayReplace(byRef $hArray, $iQuery, $iReplace[, $nElement[, $iCount[, $iCase]]])
; Parameter(s):     $hArray - The array to modify
;                   $iQuery - the string to be replaced
;                   $iReplace - the replacement string
;                   $nElement - the number of elements to be checked 0 = all (default)
;                   $iCount - occurences to be replaced in each element 0 = all (default)  **
;                   $iCase - 1 = Case sensitive, 0 = Case insensitive (default)  **
; Requirements:      None
; Return Value(s):  Returns the modified array
; Author(s):        George (GEOSoft) Gedye
; Modifications:
; Notes:            **See the Remarks for StringReplace() in the AutoIt help file.
;===============================================================================

Func __ArrayReplace(byRef $hArray, $iQuery, $iReplace, $nElement = 0, $iCount = 0, $iCase = 0)
  Local $I
  If $nElement = 0 Then $nElement = Ubound($hArray) -1
  
  For $I = __ArrayGetBase($hArray) To $nElement
    $hArray[$I] = StringReplace($hArray[$I],$iQuery, $iReplace, $iCount, $iCase)
  Next
  
  Return $hArray
EndFunc    ;<===> __ArrayReplace()

;===============================================================================
; Function Name:    __ArrayReverse()
; Description:      Reverses the order in which the elements appear in the array.
; Parameter(s):     $avArray - Array to modify
;                   $iStart - [optional] Index of array to start modifying at
;                   $iEnd - [optional] Index of array to stop modifying at
; Return Value(s):  Success - Returns 1
;                            Failure - Returns 0 and sets @error to 1
; Requirements:      None.
; Author(s):        Brian Keene [brian_keene at yahoo dot com]
; Modifications:    Jos van der Zande - Added $iStart parameter and logic
;                   Tylo - Added $iEnd parameter and rewrote it for speed
;                   Ultima - Code cleanup, minor optimization
;===============================================================================

Func __ArrayReverse(ByRef $avArray, $iStart = 0, $iEnd = -1)
  If Not IsArray($avArray) Then Return SetError(1, 0, 0)
  Local $vTmp, $iUBound = UBound($avArray) - 1
  ; Bounds checking
  If $iEnd < $iStart Or $iEnd > $iUBound Then $iEnd = $iUBound
  If $iStart < 0 Or $iStart > $iEnd Then $iStart = 0
  ; Reverse
  
  For $i = $iStart To Int(($iStart + $iEnd - 1)/2)
    $vTmp = $avArray[$i]
    $avArray[$i] = $avArray[$iEnd]
    $avArray[$iEnd] = $vTmp
    $iEnd -= 1
  Next
  
  Return 1
EndFunc    ;<===> __ArrayReverse()

;===============================================================================
; Function Name:    __ArraySearch()
; Description:      Finds an entry within a one-dimensional array.
;                   (Similar to __ArrayBinarySearch() except the array does not need to be sorted.)
; Syntax:           __ArraySearch($avArray, $iFind, $iStart = 0, $iEnd = 0,$iCase=0, $iPartial = False, $iForward = 0)
; Parameter(s): $avArray           = The array to search
;               $iFind = What to search $avArray for
;               $iStart (Optional) = Start array index for search, normally set to 0 or 1. If omitted it is set to 0
;               $iEnd (Optional) = End array index for search. If omitted or set to 0 it is set to Ubound($AvArray)-1
;               $iCase (Optional) = If set to 1 then search is case sensitive
;               $iPartial (Optional) = If set to True then executes a partial search. If omitted it is set to False
;               $iForward (Optional) = If set to 1 then searches backward through the array
;                                      If set to 0 then searches forward (default)
; Requirements:      None
; Return Value(s):  Success - Returns the position of an item in an array.
;                   Failure - Returns an -1 if $iFind is not found and sets @Error
;                             @Error=1 $avArray is not an array
;                             @Error=2 $iStart is greater than UBound($AvArray)-1
;                             @Error=3 $iEnd is greater than UBound($AvArray)-1
;                             @Error=4 $iStart is greater than $iEnd
;                             @Error=6 $iFind was not found in $avArray
; Author(s):        SolidSnake [MetalGX91 at GMail dot com]" - updated by gcriaco [gcriaco at gmail dot com]
; Modifications:    Directional search added (GEOSoft)
; Notes:            This might be slower than __ArrayBinarySearch() but is useful when the array's order can't be altered.
;===============================================================================

Func __ArraySearch(Const ByRef $avArray, $iFind, $iStart = 0, $iEnd = 0, $iCase = 0, $iPartial = False, $iForward = 0)
  Local $iCurrentPos, $iUBound, $iResult, $iStep = 1, $iBegin, $iStop
  If $iCase <> 1 Then $iCase = 0
  If $iForward <> 1 Then $iForward = 0
  If Not IsArray($avArray) Then
    SetError(1)
    Return -1
  EndIf
  $iUBound = UBound($avArray) - 1
  If $iEnd = 0 Then $iEnd = $iUBound
  If $iStart > $iUBound Then
    SetError(2)
    Return -1
  EndIf
  If $iEnd > $iUBound Then
    SetError(3)
    Return -1
  EndIf
  If $iStart > $iEnd Then
    SetError(4)
    Return -1
  EndIf
  If $iForward = 1 Then
    $iBegin = $iEnd
    $iStop = $iStart
    If $iStop = $iUbound Then $iStop = Ubound($avArray) - $iUbound
    $iStep = -1
  Else
    $iBegin = $iStart
    $iStop = $iEnd
    $iStep = 1
  EndIf
  For $iCurrentPos = $iBegin To $iStop Step $iStep
    Select
      Case $iCase = 0
        If $iPartial = False Then
          If $avArray[$iCurrentPos] = $iFind Then
            SetError(0)
            Return $iCurrentPos
          EndIf
        Else
          $iResult = StringInStr($avArray[$iCurrentPos], $iFind, $iCase)
          If $iResult > 0 Then
            SetError(0)
            Return $iCurrentPos
          EndIf
        EndIf
      Case $iCase = 1
        If $iPartial = False Then
          If $avArray[$iCurrentPos] == $iFind Then
            SetError(0)
            Return $iCurrentPos
          EndIf
        Else
          $iResult = StringInStr($avArray[$iCurrentPos], $iFind, $iCase)
          If $iResult > 0 Then
            SetError(0)
            Return $iCurrentPos
          EndIf
        EndIf
    EndSelect
  Next
  SetError(6)
  Return -1
EndFunc    ;<===> __ArraySearch()

;===============================================================================
; Function Name:   __ArrayToString
; Description:    Places the elements of an array into a single string, separated
;                  by the specified delimiter.
; Syntax:        __ArrayToString(Const ByRef $avArray[, $sDelim = "|"[, $iStart = 0[, $iEnd = 0]]])
; Parameter(s):  $avArray - Array to combine
;                $sDelim  - [optional] Delimiter for combined string
;                $iStart  - [optional] Index of array to start combining at
;                $iEnd    - [optional] Index of array to stop combining at
; Return Value(s):  Success - 1
;                   Failure - "", sets @error:
;                     [1 - $avArray is not an array
;                     [2 - $iStart is greater than $iEnd
; Author(s):        Brian Keene <brian_keene at yahoo dot com>, Valik - rewritten
; Modifications:  Ultima - code cleanup
; Notes:
;===============================================================================

Func __ArrayToString(Const ByRef $avArray, $sDelim = "|", $iStart = 0, $iEnd = 0)
  If Not IsArray($avArray) Then Return SetError(1, 0, "")
  Local $sResult, $iUBound = UBound($avArray) - 1
  
  ; Bounds checking
  If $iEnd < 1 Or $iEnd > $iUBound Then $iEnd = $iUBound
  If $iStart < 0 Then $iStart = 0
  If $iStart > $iEnd Then Return SetError(2, 0, "")
  
  ; Combine
  For $i = $iStart To $iEnd
    $sResult &= $avArray[$i] & $sDelim
  Next
  
  Return StringTrimRight($sResult, StringLen($sDelim))
EndFunc   ;<===>__ArrayToString

;===============================================================================
; Function Name:    __ArrayUnique()
; Description:      Returns an array of unique values in an array.
; Syntax:           __ArrayUnique(ByRef $aArray, $vDelim = '', $iBase = 1, $iCase = 1)
; Parameter(s):     $aArray - The array to check
;                   $vDelim - The delimiter to use in the returned string
;                   $iBase - The element to start the search
;                   $iCase - If set to 0 (default) then search is case insensitive
; Requirements:      None
; Return Value(s):  On Success - Returns an array of unique elements only
;                   On Failure - Sets @Error to 1 and returns 0
; Author(s):        SmOke_N, modified by GEOSoft
; Modifications:    Returns a separate array instead of modifying the origional
; Notes:            None
;===============================================================================

Func __ArrayUnique($aArray, $vDelim = '', $iBase = 1, $iCase = 0)
  Local $I, $oArray
  If $iCase <> 1 Then $iCase = 0
  If Not IsArray($aArray) Then Return SetError(1, 0, 0)
  If $vDelim = '' Then $vDelim = Chr(01)
  Local $sHold = ''
  For $I = $iBase To UBound($aArray) - 1
    If Not StringInStr($vDelim & $sHold, $vDelim & $aArray[$I] & $vDelim, $iCase) Then _
        $sHold &= $aArray[$I] & $vDelim
  Next
  If $sHold Then
    $oArray = StringSplit(StringTrimRight($sHold, StringLen($vDelim)), $vDelim)
    Return $oArray
  EndIf
  Return $aArray
EndFunc    ;<===> __ArrayUnique()

;===============================================================================
; Function Name:    _ArraySortClib() v4
; Description:         Sort 1D/2D array using qsort() from C runtime library
; Syntax:
; Parameter(s):      $Array - the array to be sorted, ByRef
;                    $iMode - sort mode, can be one of the following:
;                        0 = numerical, using double precision float compare
;                        1 = string sort, case insensitive (default)
;                        2 = string sort, case sensitive
;                        3 = word sort, case insensitive - compatible with AutoIt's native compare
;                    $fDescend - sort direction. True = descending, False = ascending (default)
;                    $iStart - index of starting element (default 0 = $array[0])
;                    $iEnd - index of ending element (default 0 = Ubound($array)-1)
;                    $iColumn - index of column to sort by (default 0 = first column)
;                    $iStrMax - max string length of each array element to compare (default 4095 chars)
; Requirement(s):    msvcrt.dll (shipped with Windows since Win98 at least), 32-bit version of AutoIt
; Return Value(s):    Success = Returns 1
;                    Failure = Returns 0 and sets error:
;                        @error 1 = invalid array
;                        @error 2 = invalid param
;                        @error 3 = dll error
;                        @error 64 = 64-bit AutoIt unsupported
; Author(s):   Siao
; Modification(s):
;===============================================================================

Func _ArraySortClib(ByRef $Array, $iMode = 1, $fDescend = False, $iStart = 0, $iEnd = 0, $iColumn = 0, $iStrMax = 4095)
  If @AutoItX64 Then Return SetError(64, 0, 0)
  Local $iArrayDims = UBound($Array, 0)
  If @error Or $iArrayDims > 2 Then Return SetError(1, 0, 0)
  Local $iArraySize = UBound($Array, 1), $iColumnMax = UBound($Array, 2)
  If $iArraySize < 2 Then Return SetError(1, 0, 0)
  If $iEnd < 1 Or $iEnd > $iArraySize - 1 Then $iEnd = $iArraySize - 1
  If ($iEnd - $iStart < 2) Then Return SetError(2, 0, 0)
  If $iArrayDims = 2 And ($iColumnMax - $iColumn < 0) Then Return SetError(2, 0, 0)
  If $iStrMax < 1 Then Return SetError(2, 0, 0)
  Local $i, $j, $iCount = $iEnd - $iStart + 1, $fNumeric, $aRet, $sZero = ChrW(0), $sStrCmp, $sBufType = 'byte[', $hDll = DllOpen('msvcrt.dll'), $tSource, $tIndex, $tFloatCmp, $tCmpWrap = DllStructCreate('byte[64]'), $tEnumProc = DllStructCreate('byte[64]')
  If $hDll = -1 Then Return SetError(3, 0, 0)
  ;; initialize compare proc
  Switch $iMode
    Case 0
      $fNumeric = True
      $tFloatCmp = DllStructCreate('byte[36]')
      DllStructSetData($tFloatCmp, 1, '0x8B4C24048B542408DD01DC1ADFE0F6C440750D80E441740433C048C333C040C333C0C3')
      DllStructSetData($tCmpWrap, 1, '0xBA' & Hex(Binary(DllStructGetPtr($tFloatCmp)), 8) & '8B4424088B4C2404FF30FF31FFD283C408C3')
      DllStructSetData($tEnumProc, 1, '0x8B7424048B7C24088B4C240C8B442410893789470483C60883C708404975F1C21000')
    Case 1,2
      $sStrCmp = "_strcmpi" ;case insensitive
      If $iMode = 2 Then $sStrCmp = "strcmp" ;case sensitive
      $aRet = DllCall('kernel32.dll','ptr','GetModuleHandle', 'str','msvcrt.dll')
      $aRet = DllCall('kernel32.dll','ptr','GetProcAddress', 'ptr',$aRet[0], 'str',$sStrCmp)
      If $aRet[0] = 0 Then Return SetError(3, 0, 0*DllClose($hDll))
      DllStructSetData($tCmpWrap, 1, '0xBA' & Hex(Binary($aRet[0]), 8) & '8B4424088B4C2404FF30FF31FFD283C408C3')
      DllStructSetData($tEnumProc, 1, '0x8B7424048B7C24088B4C240C8B542410893789570483C7088A064684C075F9424975EDC21000')
    Case 3
      $sBufType = 'wchar['
      $aRet = DllCall('kernel32.dll','ptr','GetModuleHandle', 'str','kernel32.dll')
      $aRet = DllCall('kernel32.dll','ptr','GetProcAddress', 'ptr',$aRet[0], 'str','CompareStringW')
      If $aRet[0] = 0 Then Return SetError(3, 0, 0*DllClose($hDll))
      DllStructSetData($tCmpWrap, 1, '0xBA' & Hex(Binary($aRet[0]), 8) & '8B4424088B4C24046AFFFF306AFFFF3168010000006800040000FFD283E802C3')
      DllStructSetData($tEnumProc, 1, '0x8B7424048B7C24088B4C240C8B542410893789570483C7080FB70683C60285C075F6424975EAC21000')
    Case Else
      Return SetError(2, 0, 0)
  EndSwitch
  ;; write data to memory
  If $fNumeric Then
    $tSource = DllStructCreate('double[' & $iCount & ']')
    If $iArrayDims = 1 Then
      For $i = 1 To $iCount
        DllStructSetData($tSource, 1, $Array[$iStart + $i - 1], $i)
      Next
    Else
      For $i = 1 To $iCount
        DllStructSetData($tSource, 1, $Array[$iStart + $i - 1][$iColumn], $i)
      Next
    EndIf
  Else
    Local $sMem = ""
    If $iArrayDims = 1 Then
      For $i = $iStart To $iEnd
        $sMem &= StringLeft($Array[$i],$iStrMax) & $sZero
      Next
    Else
      For $i = $iStart To $iEnd
        $sMem &= StringLeft($Array[$i][$iColumn],$iStrMax) & $sZero
      Next
    EndIf
    $tSource = DllStructCreate($sBufType & StringLen($sMem) + 1 & ']')
    DllStructSetData($tSource, 1, $sMem)
    $sMem = ""
  EndIf
  ;; index data
  $tIndex = DllStructCreate('int[' & $iCount * 2 & ']')
  DllCall('user32.dll','uint','CallWindowProc', 'ptr',DllStructGetPtr($tEnumProc), 'ptr',DllStructGetPtr($tSource), 'ptr',DllStructGetPtr($tIndex), 'int',$iCount, 'int',$iStart)
  ;; sort
  DllCall($hDll,'none:cdecl','qsort', 'ptr',DllStructGetPtr($tIndex), 'int',$iCount, 'int',8, 'ptr',DllStructGetPtr($tCmpWrap))
  DllClose($hDll)
  ;; rearrange the array by sorted index
  Local $aTmp = $Array, $iRef
  If $iArrayDims = 1 Then ; 1D
    If $fDescend Then
      For $i = 0 To $iCount - 1
        $iRef = DllStructGetData($tIndex, 1, $i * 2 + 2)
        $Array[$iEnd - $i] = $aTmp[$iRef]
      Next
    Else ; ascending
      For $i = $iStart To $iEnd
        $iRef = DllStructGetData($tIndex, 1, ($i - $iStart) * 2 + 2)
        $Array[$i] = $aTmp[$iRef]
      Next
    EndIf
  Else ; 2D
    If $fDescend Then
      For $i = 0 To $iCount - 1
        $iRef = DllStructGetData($tIndex, 1, $i * 2 + 2)
        For $j = 0 To $iColumnMax - 1
          $Array[$iEnd - $i][$j] = $aTmp[$iRef][$j]
        Next
      Next
    Else ; ascending
      For $i = $iStart To $iEnd
        $iRef = DllStructGetData($tIndex, 1, ($i - $iStart) * 2 + 2)
        For $j = 0 To $iColumnMax - 1
          $Array[$i][$j] = $aTmp[$iRef][$j]
        Next
      Next
    EndIf
  EndIf
  Return 1
EndFunc   ;<==> _ArraySortClib()