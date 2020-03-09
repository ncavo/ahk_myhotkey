StringCaseSense, Off
CoordMode, Mouse, Screen

FileDelete myhotkey.log

wheelScrollEmul = 0
wheelSpeedMultiplier = 1
preventAway = 0

registeredWindows := []
currentConfigGroup = "[]"
Loop, Read, myhotkey.ini
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
		if Trim(arr[1]) = "on"
		{
			wheelScrollEmul := Trim(arr[2])
		}
	}
	else if (currentConfigGroup = "[PreventAway]")
	{
		arr := StrSplit(line, "=")
		if Trim(arr[1]) = "on"
		{
			preventAway := Trim(arr[2])
		}
	}	
	else if (currentConfigGroup = "[WindowProcessRegister]")
	{
		arr := StrSplit(line, "=")
		if arr.Length() = 2
		registeredWindows.Push(line)
	}
}
if (preventAway > 0) 
{
	SetTimer, PreventAway, 90000
}
return

PreventAway:
if (A_TimeIdle >= 60000) 
{
	MouseMove, 1, 1,, R
	MouseMove, -1, -1,, R
}
return

XButton1::
if (wheelScrollEmul > 0)
{
	MouseClick, WD,,,1
	wheelSpeedMultiplier = 1
	SetTimer, OnTimerX1, 50
}
return

XButton1 Up::
if (wheelScrollEmul > 0)
{
	SetTimer, OnTimerX1, Off
}
return

OnTimerX1:
wheelSpeedMultiplier += 1
MouseClick, WD,,,(wheelSpeedMultiplier / 4) + 1
return

XButton2::
if (wheelScrollEmul > 0)
{
	MouseClick, WU,,,1
	wheelSpeedMultiplier = 1
	SetTimer, OnTimerX2, 50
}
return

XButton2 Up::
if (wheelScrollEmul > 0)
{
	SetTimer, OnTimerX2, Off
}
return

OnTimerX2:
wheelSpeedMultiplier += 1
MouseClick, WU,,,(wheelSpeedMultiplier / 4) + 1
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

<!#Home UP::
ShowWndInfo()
return

<!#End UP::
Test()
return

ShowWndInfo()
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
	
	WinGet, procName, ProcessName
	procName := Trim(procName)
	WinGetTitle, winTitle
	winTitle := Trim(winTitle)
	
	hMon := DllCall("MonitorFromRect", "int", 0, "int", 1) ; PRIMARY:1, NEAREST:2
	VarSetCapacity(mon, 40)
	NumPut(40, mon, 0, "int")
	DllCall("GetMonitorInfo", "int", hMon, "ptr", &mon)
	monLeft := NumGet(mon, 20, "int")
	monTop := NumGet(mon, 24, "int")
	monRight := NumGet(mon, 28, "int")
	monBottom := NumGet(mon, 32, "int")
	monWidth := monRight - monLeft
	monHeight := monBottom - monTop
	
	MsgBox % "ProcName:" . procName . "`nTitle:" .  winTitle . "`nMonSize:(" . monWidth . "," . monHeight . ")`nWinPos:(" . winLeft . "," . winTop . ")`nWinSize(" . winWidth . "," . winHeight . ")"
}

Test()
{
	hMon := DllCall("MonitorFromRect", "int", 0, "int", 1) ; PRIMARY:1, NEAREST:2
	VarSetCapacity(mon, 40)
	NumPut(40, mon, 0, "int")
	DllCall("GetMonitorInfo", "int", hMon, "ptr", &mon)
	monLeft := NumGet(mon, 20, "int")
	monTop := NumGet(mon, 24, "int")
	monRight := NumGet(mon, 28, "int")
	monBottom := NumGet(mon, 32, "int")
	monWidth := monRight - monLeft
	monHeight := monBottom - monTop
	settingFileName = winPosSizeFor%monWidth%x%monHeight%.ini
	IfNotExist, %settingFileName%
	{
		MsgBox % "No setting file(" . settingFileName . ")"
		return
	}
	winPosSizeData := []
	Loop, Read, winPosSizeFor%monWidth%x%monHeight%.ini
	{
		arr := StrSplit(A_LoopReadLine, ";")
		line := Trim(arr[1])
		if InStr(line,",",,,3) = 0
			continue
		winPosSizeData.Push(line)
	}
	WinGet, id, List,,, Program Manager
	Loop, %id%
	{
		this_id := id%A_Index%
		WinGet, this_process, ProcessName, ahk_id %this_id%
		WinGetTitle, this_title, ahk_id %this_id%
		for i, line in winPosSizeData
		{
			j := 1
			arr := StrSplit(line, ",")
			activating := false
			arr[j] := Trim(arr[j])
			if arr[j] = "A"
			{
				activating := true
				j := j + 1
			}
			arr[j] := Trim(arr[j])
			if arr[j] = "" or InStr(this_process, arr[j]) = 0
				continue
			j := j + 1
			arr[j] := Trim(arr[j])
			exact := false
			if arr[j] = "E"
			{
				exact := true
				j := j + 1
				arr[j] := Trim(arr[j])
			}
			if exact
			{
				if Trim(this_title) <> arr[j]
					continue
			}
			else
			{
				if arr[j] <> "" and InStr(this_title, arr[j]) = 0
					continue
			}			
			j := j + 1
			x := Trim(arr[j])
			j := j + 1
			y := Trim(arr[j])
			j := j + 1
			w := Trim(arr[j])
			j := j + 1
			h := Trim(arr[j])
			j := j + 1
			if IsNotPosInt(x) or IsNotPosInt(y)
			{
				MsgBox % "Wrong line format " . line
				winPosSizeData.Delete(i)
				break
			}
			if IsNotPosInt(w) or IsNotPosInt(h)
				WinMove, ahk_id %this_id%,, x, y
			else
				WinMove, ahk_id %this_id%,, x, y, w, h			
			if activating
				WinActivate, ahk_id %this_id%
		}		
	}
	return	
}

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
	hMon := DllCall("MonitorFromRect", "ptr", &rect, "int", 2) ; PRIMARY:1, NEAREST:2
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
		d := gap / 8
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
		d := gap / 8
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

IsNotPosInt(x)
{
	if x is not integer
		return true
	if x < 0
		return true
	return false
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