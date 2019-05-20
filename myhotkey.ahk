StringCaseSense, Off
CoordMode, Mouse, Screen

FileDelete myhotkey.log

sens_X = 0
sens_Y = 0
position_count = 2
posX2Arr := []
registeredWindows := []
currentConfigGroup = "[]"
Loop, read, myhotkey.ini
{
	arr := StrSplit(A_LoopReadLine, ";")
	line := Trim(arr[1])
	if SubStr(line, 1, 1) = "[" and SubStr(line, -0) = "]"
	{
		currentConfigGroup := line
	}
	else if (currentConfigGroup = "[WheelScrollEmulator]")
	{
		arr := StrSplit(line, "=")
		if Trim(arr[1]) = "horizontal_sensitivity"
		{
			sens_X := Trim(arr[2])
		}
		else if Trim(arr[1]) = "vertical_sensitivity"
		{
			sens_Y := Trim(arr[2])
		}	
	}
	else if (currentConfigGroup = "[MousePointerJumper]")
	{
		arr := StrSplit(line, "=")
		if Trim(arr[1]) = "position_count"
		{
			position_count := Trim(arr[2])
		}	
	}
	else if (currentConfigGroup = "[WindowProcessRegister]")
	{
		arr := StrSplit(line, "=")
		if arr.Length() = 2
			registeredWindows.Push(line)
	}
}
return

XButton1::
if (sens_X > 0) or (sens_Y > 0)
{
	bIsX1Moved = 0
	VarSetCapacity(click_posX1, 8)
	bResult := DllCall("GetCursorPos", "ptr", &click_posX1)	
	if bResult = 0
	{
		MsgBox % "GetCursorPos failed: " . DllCall("GetLastError")
		return
	}
	click_posX1_X := NumGet(click_posX1, 0, "int")
	click_posX1_Y := NumGet(click_posX1, 4, "int")
	SetTimer, OnTimerX1, 100
}
return

XButton1 Up::
if (sens_X > 0) or (sens_Y > 0)
{
	SetTimer, OnTimerX1, Off
	if bIsX1Moved = 0
		MouseClick, Middle
}
return

OnTimerX1:
VarSetCapacity(move_posX1, 8)
bResult := DllCall("GetCursorPos", "ptr", &move_posX1)	
if bResult = 0
{
	MsgBox % "GetCursorPos failed: " . DllCall("GetLastError")
	return
}
move_posX1_X := NumGet(move_posX1, 0, "int")
move_posX1_Y := NumGet(move_posX1, 4, "int")
DllCall("SetCursorPos", "int", click_posX1_X, "int", click_posX1_Y)
deltaX1_X += move_posX1_X - click_posX1_X
deltaX1_Y += move_posX1_Y - click_posX1_Y
;FileAppend, MouseDelta(%deltaX1_X%`,%deltaX1_Y%) `n, myhotkey.log
if (sens_X > 0)
{
	if deltaX1_X >= %sens_X%
	{
		bIsX1Moved = 1
		c := deltaX1_X // sens_X
		MouseClick, WR,,,c
		deltaX1_X -= c * sens_X
	}
	else if deltaX1_X <= -%sens_X%
	{
		bIsX1Moved = 1
		c := -deltaX1_X // sens_X
		MouseClick, WL,,,c
		deltaX1_X += c * sens_X
	}
}

if (sens_Y > 0)
{
	if deltaX1_Y >= %sens_Y%
	{
		bIsX1Moved = 1
		c := deltaX1_Y // sens_Y
		MouseClick, WD,,,c
		deltaX1_Y -= c * sens_Y
	}
	else if deltaX1_Y <= -%sens_Y%
	{
		bIsX1Moved = 1
		c := -deltaX1_Y // sens_Y
		MouseClick, WU,,,c
		deltaX1_Y += c * sens_Y
	}
}
return

XButton2::
VarSetCapacity(click_posX2, 8)
bResult := DllCall("GetCursorPos", "ptr", &click_posX2)	
if bResult = 0
{
	MsgBox % "GetCursorPos failed: " . DllCall("GetLastError")
	return
}
click_posX2_X1 := NumGet(click_posX2, 0, "int")
click_posX2_Y1 := NumGet(click_posX2, 4, "int")
posX2Arr.Push(click_posX2_X1, click_posX2_Y1)
if (posX2Arr.Length() >= position_count * 2)
{
	click_posX2_X2 := posX2Arr.RemoveAt(1)
	click_posX2_Y2 := posX2Arr.RemoveAt(1)
	DllCall("SetCursorPos", "int", click_posX2_X2, "int", click_posX2_Y1)
	DllCall("SetCursorPos", "int", click_posX2_X2, "int", click_posX2_Y2)
}
return

XButton2 Up::
return

<!#Left UP::
WindowSizeAndMove(registeredWindows, 1)
return

<!#Right UP::
WindowSizeAndMove(registeredWindows, 2)
return

<!#Up UP::
WindowSizeAndMove(registeredWindows, 3)
return

<!#Down UP::
WindowSizeAndMove(registeredWindows, 4)
return

<!#PgUp UP::
WindowSizeAndMove(registeredWindows, 5)
return

<!#PgDn UP::
WindowSizeAndMove(registeredWindows, 6)
return

WindowSizeAndMove(ByRef registeredWindows, ByRef keyNum)
{
	hWnd := WinExist("A")
	VarSetCapacity(rect, 16)
	bResult := DllCall("GetWindowRect", "ptr", hWnd, "ptr", &rect)	
	if bResult = 0
	{
		MsgBox % "GetWindowRect failed: " . DllCall("GetLastError")
		return
	}
	winLeft := NumGet(rect, 0, "int")
	winTop := NumGet(rect, 4, "int")
	winRight := NumGet(rect, 8, "int")
	winBottom := NumGet(rect, 12, "int")	
	winWidth := winRight - winLeft
	winHeight := winBottom - winTop
	hMon := DllCall("MonitorFromRect", "ptr", &rect, "int", 2) ; MONITOR_DEFAULTTONEAREST
	VarSetCapacity(mon, 40)
	NumPut(40, mon, 0, "int")
	DllCall("GetMonitorInfo", "int", hMon, "ptr", &mon)
	monLeft := NumGet(mon, 20, "int")
	monTop := NumGet(mon, 24, "int")
	monRight := NumGet(mon, 28, "int")
	monBottom := NumGet(mon, 32, "int")
	monWidth := monRight - monLeft
	monHeight := monBottom - monTop
	WinGet, procName, ProcessName
	procName := Trim(procName)
	FileAppend, %A_LineNumber%] procName=%procName% keyNum=%keyNum% win(%winLeft%`,%winTop%`,%winWidth%`,%winHeight%) mon(%monLeft%`,%monTop%`,%monWidth%`,%monHeight%)`n, myhotkey.log
	
	if keyNum = 1
	{
		gap := (monRight - monLeft) - (winRight - winLeft)
		if (gap <= 0)
			return
		d := gap / 6
		pos := monLeft + gap
		While(monLeft < pos - 1)
		{
			if (pos + 3 < winLeft)
			{
				WinMove,A,,pos,winTop
				return
			}		
			pos -= d
		}
		WinMove,A,,monLeft,winTop
		return
	}
	else if keyNum = 2
	{
		gap := (monRight - monLeft) - (winRight - winLeft)
		if (gap <= 0)
			return
		d := gap / 6
		pos := monLeft
		While(pos + 1 < monLeft + gap)
		{
			if (winLeft + 3 < pos)
			{
				WinMove,A,,pos,winTop
				return
			}
			pos += d
		}
		WinMove,A,,monLeft + gap,winTop
		return
	}
	else if keyNum = 3
	{
		gap := (monBottom - monTop) - (winBottom - winTop)
		if (gap <= 0)
			return
		d := gap / 4
		pos += monTop + gap
		While(monTop < pos - 1)
		{
			if (pos + 3 < winTop)
			{
				WinMove,A,,winLeft,pos
				return
			}
			pos -= d
		}
		WinMove,A,,winLeft,monTop
		return
	}
	else if keyNum = 4
	{
		gap := (monBottom - monTop) - (winBottom - winTop)
		if (gap <= 0)
			return
		d := gap / 4
		pos := monTop
		While(pos + 1 < monTop + gap)
		{
			if (winTop + 3 < pos)
			{
				WinMove,A,,winLeft,pos
				return
			}
			pos += d
		}
		WinMove,A,,winLeft,monTop + gap
		return		
	}
	
	targetSizeWidth = 0
	targetSizeHeight = 0
	targetPos = new Position(0, 0)
	found = 0
	for i, line in registeredWindows
	{
		arr := StrSplit(line, "=")
		if arr.Length() <> 2
			continue
		if (procName <> Trim(arr[1]))
			continue
		width = 0
		height = 0
		posXStr := ""
		posYStr := ""
		arr := StrSplit(arr[2], ",")
		if (arr.Length() = 2)
		{
			width := GetWindowSizeWithParam(Trim(arr[1]), monRight - monLeft)
			height := GetWindowSizeWithParam(Trim(arr[2]), monBottom - monTop)
		}
		else
		{
			if (arr.Length() <> 4) and (arr.Length() <> 6)
				continue
			if (monWidth <> Trim(arr[1])) or (monHeight<> Trim(arr[2]))
				continue		
			width := GetWindowSizeWithParam(Trim(arr[3]), monRight - monLeft)
			height := GetWindowSizeWithParam(Trim(arr[4]), monBottom - monTop)
			if (arr.Length() = 6)
			{
				posXStr := Trim(arr[5])
				posYStr := Trim(arr[6])
			}
		}
		FileAppend, %A_LineNumber%] size(%width%`,%height%) posStr(%posXStr%`,%posYStr%)`n, myhotkey.log
		if (width < 100) or (width > monRight - monLeft) or (height < 100) or (height > monBottom - monTop)
			continue
		if (found = 0)
		{
			if (winWidth - 1 <= width) and (winWidth + 1 >= width) and (winHeight - 1 <= height) and (winHeight + 1 >= height)
			{
				found = 1
				if (targetSizeWidth <> 0) and (keyNum = 5)
				{
					WinMove,A,,targetPos.x,targetPos.y,targetSizeWidth,targetSizeHeight
					return
				}
			}
			else if (targetSizeWidth = 0) or (keyNum = 5)
			{
				targetSizeWidth = %width%
				targetSizeHeight = %height%				
				targetPos := GetWindowPostWithParam(posXStr, posYStr, targetSizeWidth, targetSizeHeight, winLeft, winTop, winRight, winBottom, monLeft, monTop, monRight, monBottom)
			}
		}
		else
		{
			targetSizeWidth = %width%
			targetSizeHeight = %height%
			targetPos := GetWindowPostWithParam(posXStr, posYStr, targetSizeWidth, targetSizeHeight, winLeft, winTop, winRight, winBottom, monLeft, monTop, monRight, monBottom)
			if keyNum = 6
			{
				WinMove,A,,targetPos.x,targetPos.y,targetSizeWidth,targetSizeHeight
				return
			}			
		}
		targetPos_x := targetPos.x
		targetPos_y := targetPos.y
		FileAppend, %A_LineNumber%] targetSize(%targetSizeWidth%`,%targetSizeHeight%) targetPos(%targetPos_x%`,%targetPos_y%) found=%found%`n, myhotkey.log
	}
	if (targetSizeWidth <> 0)
	{
		WinMove,A,,targetPos.x,targetPos.y,targetSizeWidth,targetSizeHeight
	}
	else if (found = 0)
	{
		MsgBox % "Not registered window: " . procName . " mon(" . monWidth . "," . monHeight . ") win(" . winWidth . "," . winHeight . "," . Round(winWidth * 100 // (monRight - monLeft),0) . "%," . Round(winHeight * 100 // (monBottom - monTop),0) . "%)"
	}
}

GetWindowSizeWithParam(param, size)
{
	if SubStr(param, -0) = "%"
	{
		percent := SubStr(param, 1, StrLen(param) - 1)
		if (percent > 0) and (percent <= 100)
		{
			return size * percent // 100
		}
	}
	else if SubStr(param, 1, 1) = "-"
	{
		minus := SubStr(param, 2, StrLen(param) - 1)
		if (minus >= 0) and (minus <= size)
		{
			return size - minus
		}		
	}
	return param
}

GetWindowPostWithParam(posXStr, posYStr, targetSizeWidth, targetSizeHeight, winLeft, winTop, winRight, winBottom, monLeft, monTop, monRight, monBottom)
{
	targetPos := new Position(0, 0)
	if (posXStr <> "") and (posYStr <> "")
	{
		targetPos.x := GetWindowSizeWithParam(posXStr, monRight - monLeft - targetSizeWidth) + monLeft
		targetPos.y := GetWindowSizeWithParam(posYStr, monBottom - monTop - targetSizeHeight) + monTop
		return targetPos
	}
	
	winWidth := winRight - winLeft
	winHeight := winBottom - winTop
	winCenterPos := new Position(winLeft + (winWidth / 2), winTop + (winHeight / 2))
	monWidth := monRight - monLeft
	monHeight := monBottom - monTop
	monCenterPos := new Position(monLeft + (monWidth / 2), monTop + (monHeight / 2))

	newLeft := 0
	newTop := 0
	newRight := 0
	newBottom := 0
	
	newLeft := winLeft
	newTop := winTop
	newRight := winLeft + targetSizeWidth
	newBottom := winTop + targetSizeHeight
	if(newRight > monRight)
	{
		newLeft -= newRight - monRight
		newRight := monRight
	}
	if(newBottom > monBottom)
	{
		newTop -= newBottom - monBottom
		newBottom := monBottom
	}
	
	targetPos.x := newLeft
	targetPos.y := newTop
	return targetPos
}

class Position
{
	x := 0
	y := 0

	__New(x, y)
	{
		this.x := x
		this.y := y
	}
}