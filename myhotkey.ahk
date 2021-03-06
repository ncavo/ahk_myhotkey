CoordMode "Mouse", "Screen"
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
wheelScrollEmul := 0
wheelSpeedMultiplier := 1
isPreventAway := 0
registeredWindows := Map()
registeredWindows.CaseSense := "Off"
registeredWindows.Default := ""
currentConfigGroup := "[]"
Loop Read "myhotkey.ini"
{
	arr := StrSplit(A_LoopReadLine, ";")
	if arr.Length < 1
		continue
	line := Trim(arr[1])
	if (SubStr(line, 1, 1) == "[") and (SubStr(line, -1) == "]")
	{
		currentConfigGroup := line
		continue
	}
	arr := StrSplit(line, "=")
	if arr.Length != 2
		continue	
	if currentConfigGroup = "[WheelScrollEmulator]"
	{
		if Trim(arr[1]) = "on"
			wheelScrollEmul := Trim(arr[2])
	}
	else if currentConfigGroup = "[PreventAway]"
	{
		if Trim(arr[1]) = "on"
			isPreventAway := Trim(arr[2])
	}	
	else if currentConfigGroup = "[WindowProcessRegister]"
	{
		procName := Trim(arr[1])
		value := registeredWindows.Get(procName)
		if value == ""
			registeredWindows.Set(procName, Array(Trim(arr[2])))
		else
			value.Push(Trim(arr[2]))
	}
}
winPosSizeData := Map()
winPosSizeData.CaseSense := "Off"
winPosSizeData.Default := ""
hMon := DllCall("MonitorFromRect", "Int", 0, "Int", 1) ; PRIMARY:1, NEAREST:2
mon := Buffer(40)
NumPut("Int", 40, mon)
DllCall("GetMonitorInfo", "Int", hMon, "Ptr", mon)
pMonLeft := NumGet(mon, 20, "int")
pMonTop := NumGet(mon, 24, "int")
pMonRight := NumGet(mon, 28, "int")
pMonBottom := NumGet(mon, 32, "int")
pMonWidth := pMonRight - pMonLeft
pMonHeight := pMonBottom - pMonTop
settingFileName := "winPosSizeFor" pMonWidth "x" pMonHeight ".ini"
if FileExist(settingFileName)
{
	Loop Read, settingFileName
	{
		arr := StrSplit(A_LoopReadLine, ";")
		if arr.Length < 1
			continue
		line := Trim(arr[1])
		arr := StrSplit(line, ",")
		if arr.Length < 4
			continue
		procName := Trim(arr[1])
		value := winPosSizeData.Get(procName)
		if value == ""
			winPosSizeData.Set(procName, Array(line))
		else
			value.Push(line)
	}
}
if isPreventAway > 0
{
	SetTimer PreventAway, 90000
}
return

PreventAway()
{
	if A_TimeIdle >= 60000
	{
		MouseMove 1, 1,, "R"
		MouseMove -1, -1,, "R"
	}
}

OnTimerX1()
{
	wheelSpeedMultiplier += 1
	MouseClick "WD",,,(wheelSpeedMultiplier / 4) + 1
}

XButton1::
{
	if wheelScrollEmul > 0
	{
		MouseClick "WD",,,1
		wheelSpeedMultiplier := 1
		SetTimer OnTimerX1, 50
	}
}

XButton1 Up::
{
	if wheelScrollEmul > 0
	{
		SetTimer OnTimerX1, 0
	}
}

OnTimerX2()
{
	wheelSpeedMultiplier += 1
	MouseClick "WU",,,(wheelSpeedMultiplier / 4) + 1
}

XButton2::
{
	if wheelScrollEmul > 0
	{
		MouseClick "WU",,,1
		wheelSpeedMultiplier := 1
		SetTimer OnTimerX2, 50
	}
}

XButton2 Up::
{
	if wheelScrollEmul > 0
	{
		SetTimer OnTimerX2, 0
	}
}

<!#Left UP:: WindowSizeAndMove(registeredWindows, 1)
<!#Right UP:: WindowSizeAndMove(registeredWindows, 2)
<!#Up UP:: WindowSizeAndMove(registeredWindows, 3)
<!#Down UP:: WindowSizeAndMove(registeredWindows, 4)
<!#PgUp UP:: WindowSizeAndMove(registeredWindows, 5)
<!#PgDn UP:: WindowSizeAndMove(registeredWindows, 6)
<!#Home UP:: ShowWndInfo()
<!#End UP:: SetWinsSizePos()

ShowWndInfo()
{
	hWnd := WinExist("A")
	rect := Buffer(16)
	bResult := DllCall("GetWindowRect", "Ptr", hWnd, "Ptr", rect)
	if bResult == 0
	{
		MsgBox "GetWindowRect failed: " . DllCall("GetLastError")
		return
	}
	winLeft := NumGet(rect, 0, "int")
	winTop := NumGet(rect, 4, "int")
	winRight := NumGet(rect, 8, "int")
	winBottom := NumGet(rect, 12, "int")	
	winWidth := winRight - winLeft
	winHeight := winBottom - winTop
	
	procName := WinGetProcessName()
	procName := Trim(procName)
	winTitle := WinGetTitle()
	winTitle := Trim(winTitle)
	
	MsgBox "ProcName:" procName "`nTitle:" winTitle "`nMonSize:(" pMonWidth "," pMonHeight ")`nWinPos:(" winLeft "," winTop ")`nWinSize(" winWidth "," winHeight ")"
}

SetWinsSizePos()
{
	if winPosSizeData.Count == 0
	{
		MsgBox "No setting file or no value(" settingFileName ")"
		return	
	}
	id := WinGetList(,,"Program Manager")
	Loop id.Length
	{
		this_id := id[A_Index]
		this_procName := WinGetProcessName("ahk_id" this_id)
		this_title := WinGetTitle("ahk_id" this_id)
		value := winPosSizeData.Get(this_procName)
		if value == ""
			continue
		For i, line in value
		{
			arr := StrSplit(line, ",")
			if arr.Length < 4 
				continue
			activating := false
			j := 1
			elem := Trim(arr[++j])
			if arr[j] = "A"
			{
				activating := true
				elem := Trim(arr[++j])
			}
			exact := false
			if elem = "E"
			{
				exact := true
				elem := Trim(arr[++j])
			}
			if exact
			{
				if Trim(this_title) != elem
					continue
			}
			else
			{
				if elem != "" and InStr(this_title, elem) == 0
					continue
			}
			if j + 2 > arr.Length
				continue
			x := Trim(arr[++j])
			y := Trim(arr[++j])
			if IsNotPosInt(x) or IsNotPosInt(y)
				continue
			if j + 2 > arr.Length
			{
				WinMove(x, y,,, "ahk_id" this_id)
				if activating
					WinActivate("ahk_id" this_id)
				break
			}
			w := Trim(arr[++j])
			h := Trim(arr[++j])
			if IsNotPosInt(w) or IsNotPosInt(h)
				WinMove(x, y,,, "ahk_id" this_id)
			else
				WinMove(x, y, w, h, "ahk_id" this_id)
			if activating
				WinActivate("ahk_id" this_id)
			break
		}		
	}
}

WindowSizeAndMove(registeredWindows, keyNum)
{
	hWnd := WinExist("A")
	rect := Buffer(16)
	bResult := DllCall("GetWindowRect", "Ptr", hWnd, "Ptr", rect)	
	if bResult == 0
	{
		MsgBox "GetWindowRect failed: " DllCall("GetLastError")
		return
	}
	winLeft := NumGet(rect, 0, "int")
	winTop := NumGet(rect, 4, "int")
	winRight := NumGet(rect, 8, "int")
	winBottom := NumGet(rect, 12, "int")	
	winWidth := winRight - winLeft
	winHeight := winBottom - winTop
	hMon := DllCall("MonitorFromRect", "Ptr", rect, "Int", 2) ; PRIMARY:1, NEAREST:2
	mon := Buffer(40)
	NumPut("Int", 40, mon)
	DllCall("GetMonitorInfo", "Int", hMon, "Ptr", mon)
	monLeft := NumGet(mon, 20, "int")
	monTop := NumGet(mon, 24, "int")
	monRight := NumGet(mon, 28, "int")
	monBottom := NumGet(mon, 32, "int")
	monWidth := monRight - monLeft
	monHeight := monBottom - monTop
	procName := WinGetProcessName()
	procName := Trim(procName)
	
	if keyNum == 1
	{
		gap := (monRight - monLeft) - (winRight - winLeft)
		if gap <= 0
			return
		d := gap / 8
		pos := monLeft + gap
		While(monLeft < pos - 1)
		{
			if pos + 3 < winLeft
			{
				WinMove pos,winTop
				return
			}		
			pos -= d
		}
		WinMove monLeft,winTop
		return
	}
	else if keyNum == 2
	{
		gap := (monRight - monLeft) - (winRight - winLeft)
		if gap <= 0
			return
		d := gap / 8
		pos := monLeft
		While(pos + 1 < monLeft + gap)
		{
			if winLeft + 3 < pos
			{
				WinMove pos,winTop
				return
			}
			pos += d
		}
		WinMove monLeft + gap,winTop
		return
	}
	else if keyNum == 3
	{
		gap := (monBottom - monTop) - (winBottom - winTop)
		if gap <= 0
			return
		d := gap / 4
		pos := monTop + gap
		While(monTop < pos - 1)
		{
			if pos + 3 < winTop
			{
				WinMove winLeft,pos
				return
			}
			pos -= d
		}
		WinMove winLeft,monTop
		return
	}
	else if keyNum == 4
	{
		gap := (monBottom - monTop) - (winBottom - winTop)
		if gap <= 0
			return
		d := gap / 4
		pos := monTop
		While(pos + 1 < monTop + gap)
		{
			if winTop + 3 < pos
			{
				WinMove winLeft,pos
				return
			}
			pos += d
		}
		WinMove winLeft,monTop + gap
		return		
	}
	
	value := registeredWindows.Get(procName)
	if value == ""
	{
		MsgBox "Not registered window: " procName " mon(" monWidth "," monHeight ") win(" winWidth "," winHeight "," Round(winWidth * 100 // (monRight - monLeft),0) "%," Round(winHeight * 100 // (monBottom - monTop),0) "%)"
		return
	}
	targetSizeWidth := 0
	targetSizeHeight := 0
	targetPos := Position(0, 0)
	found := 0
	For i, line in value
	{
		width := 0
		height := 0
		posXStr := ""
		posYStr := ""
		arr := StrSplit(line, ",")
		if arr.Length == 2
		{
			width := GetWindowSizeWithParam(Trim(arr[1]), monRight - monLeft)
			height := GetWindowSizeWithParam(Trim(arr[2]), monBottom - monTop)
		}
		else
		{
			if (arr.Length != 4) and (arr.Length != 6)
				continue
			if (monWidth != Trim(arr[1])) or (monHeight != Trim(arr[2]))
				continue		
			width := GetWindowSizeWithParam(Trim(arr[3]), monRight - monLeft)
			height := GetWindowSizeWithParam(Trim(arr[4]), monBottom - monTop)
			if arr.Length == 6
			{
				posXStr := Trim(arr[5])
				posYStr := Trim(arr[6])
			}
		}
		if (width < 100) or (width > monRight - monLeft) or (height < 100) or (height > monBottom - monTop)
			continue
		if found == 0
		{
			if (winWidth - 1 <= width) and (winWidth + 1 >= width) and (winHeight - 1 <= height) and (winHeight + 1 >= height)
			{
				found := 1
				if (targetSizeWidth != 0) and (keyNum = 5)
				{
					WinMove targetPos.x,targetPos.y,targetSizeWidth,targetSizeHeight
					return
				}
			}
			else if (targetSizeWidth = 0) or (keyNum = 5)
			{
				targetSizeWidth := width
				targetSizeHeight := height
				targetPos := GetWindowPostWithParam(posXStr, posYStr, targetSizeWidth, targetSizeHeight, winLeft, winTop, winRight, winBottom, monLeft, monTop, monRight, monBottom)
			}
		}
		else
		{
			targetSizeWidth := width
			targetSizeHeight := height
			targetPos := GetWindowPostWithParam(posXStr, posYStr, targetSizeWidth, targetSizeHeight, winLeft, winTop, winRight, winBottom, monLeft, monTop, monRight, monBottom)
			if keyNum == 6
			{
				WinMove targetPos.x,targetPos.y,targetSizeWidth,targetSizeHeight
				return
			}			
		}
		targetPos_x := targetPos.x
		targetPos_y := targetPos.y
	}
	if targetSizeWidth != 0
	{
		WinMove targetPos.x,targetPos.y,targetSizeWidth,targetSizeHeight
	}
}

GetWindowSizeWithParam(param, size)
{
	if SubStr(param, -1) == "%"
	{
		percent := SubStr(param, 1, StrLen(param) - 1)
		if (percent > 0) and (percent <= 100)
		{
			return size * percent // 100
		}
	}
	else if SubStr(param, 1, 1) == "-"
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
	targetPos := Position(0, 0)
	if (posXStr != "") and (posYStr != "")
	{
		targetPos.x := GetWindowSizeWithParam(posXStr, monRight - monLeft - targetSizeWidth) + monLeft
		targetPos.y := GetWindowSizeWithParam(posYStr, monBottom - monTop - targetSizeHeight) + monTop
		return targetPos
	}
	
	winWidth := winRight - winLeft
	winHeight := winBottom - winTop
	winCenterPos := Position(winLeft + (winWidth / 2), winTop + (winHeight / 2))
	monWidth := monRight - monLeft
	monHeight := monBottom - monTop
	monCenterPos := Position(monLeft + (monWidth / 2), monTop + (monHeight / 2))

	newLeft := 0
	newTop := 0
	newRight := 0
	newBottom := 0
	
	newLeft := winLeft
	newTop := winTop
	newRight := winLeft + targetSizeWidth
	newBottom := winTop + targetSizeHeight
	if newRight > monRight
	{
		newLeft -= newRight - monRight
		newRight := monRight
	}
	if newBottom > monBottom
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
	if not isInteger(x)
		return true
	if x < 0
		return true
	return false
}