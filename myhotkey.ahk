CoordMode "Mouse", "Screen"
FileEncoding "UTF-8"
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

isPreventAway := 0
registeredWindows := Map()
registeredWindows.CaseSense := "Off"
registeredWindows.Default := ""
sizePosKeyType := Map()
sizePosKeyType.CaseSense := "Off"
sizePosKeyType.Default := 1
winSizePosData := Map()
winSizePosData.CaseSense := "Off"
winSizePosData.Default := ""
resolutionList := Array()

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
	if currentConfigGroup = "[ResolutionChange]"
	{
		resolutionList.Push(Trim(line))
		continue
	}	
	arr := StrSplit(line, "=")
	if arr.Length != 2
		continue	
	if currentConfigGroup = "[PreventAway]"
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
	else if currentConfigGroup = "[SizePosKeyType]"
	{
		keyType := Trim(arr[2])
		if keyType != 1 and keyType != 2 and keyType != 3
			continue
		sizePosKeyType.Set(Trim(arr[1]), keyType)
	}
}

settingFileName := "winSizePos.dat"
if FileExist(settingFileName)
{
	Loop Read, settingFileName
	{
		arr := StrSplit(A_LoopReadLine, "/")
		if arr.Length != 3
			continue
		procName := Trim(arr[1])
		keyType := sizePosKeyType.Get(procName)
		arr2 := StrSplit(arr[2], ",")
		if not ((keyType = 3 and arr2.Length = 4) or (keyType = 2 and arr2.Length = 3) or (keyType = 1 and arr2.Length = 2))
			continue		
		value := winSizePosData.Get(procName)
		if value == ""
		{
			newMap := Map()
			newMap.CaseSense := "Off"
			newMap.Default := ""
			newMap.Set(Trim(arr[2]), Trim(arr[3]))
			winSizePosData.Set(procName, newMap)
		}
		else
			value.Set(Trim(arr[2]), Trim(arr[3]))
	}
}

if isPreventAway > 0
{
	PreventAway()
	{
		if A_TimeIdle >= 60000
		{
			MouseMove 1, 1,, "R"
			MouseMove -1, -1,, "R"
		}
	}
	SetTimer PreventAway, 90000
}
;FileAppend "done`n", A_Desktop "\log.txt"
return

<!#Left UP:: WindowSizeAndMove(registeredWindows, 1)
<!#Right UP:: WindowSizeAndMove(registeredWindows, 2)
<!#Up UP:: WindowSizeAndMove(registeredWindows, 3)
<!#Down UP:: WindowSizeAndMove(registeredWindows, 4)
<!#PgUp UP:: WindowSizeAndMove(registeredWindows, 5)
<!#PgDn UP:: WindowSizeAndMove(registeredWindows, 6)

<!#Ins UP:: AddWinsSizePos()
<!#Del UP:: RemoveWinsSizePos()
<!#Home UP:: SetWinsSizePos()
<!#End UP:: ShowWndInfo()

#HotIf resolutionList.Length >= 2
<!#NumpadAdd:: ChangeResolution(0)
#HotIf resolutionList.Length >= 2
<!#NumpadSub:: ChangeResolution(1)

<!#NumpadMult:: DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 1)

NumpadDiv:: MouseClick "X1"
NumpadMult:: MouseClick "X2"
NumpadAdd:: WinBringUp()
NumpadSub:: Send "^w"

#1:: MouseClick "X1"
#2:: MouseClick "X2"
#Tab:: WinBringUp()

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

SaveWinSizePosData()
{
	global settingFileName
	try
		FileObj := FileOpen(settingFileName, "w")
	catch as Err
	{
		MsgBox "Can't open '" settingFileName "' for writing." . "`n`n" Type(Err) ": " Err.Message
		return
	}
	global winSizePosData
	For key, value in winSizePosData
		For key2, value2 in value
			FileObj.Write(key "/" key2 "/" value2 "`n")
	FileObj.Close()
}

AddWinsSizePos()
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
	
	hMon := DllCall("MonitorFromRect", "Ptr", rect, "Int", 2) ; PRIMARY:1, NEAREST:2
	mon := Buffer(40)
	NumPut("Int", 40, mon)
	DllCall("GetMonitorInfo", "Int", hMon, "Ptr", mon)
	monLeft := NumGet(mon, 4, "int")
	monTop := NumGet(mon, 8, "int")
	monRight := NumGet(mon, 12, "int")
	monBottom := NumGet(mon, 16, "int")
	monSize := (monRight - monLeft) "," (monBottom - monTop)
	winSize := (winLeft - monLeft) "," (winTop - monTop) "," (winRight - winLeft) "," (winBottom - winTop)
	procName := WinGetProcessName()
	procName := Trim(procName)
	key := ""
	Switch sizePosKeyType.Get(procName)
	{
	case 1:
		key := monSize
	case 2:
		key := Trim(WinGetClass()) "," monSize
	case 3:
		key := Trim(WinGetClass()) "," Trim(WinGetTitle()) "," monSize
	}

	global winSizePosData
	value := winSizePosData.Get(procName)
	if value == ""
	{
		newMap := Map()
		newMap.CaseSense := "Off"
		newMap.Default := ""
		newMap.Set(key, winSize)
		winSizePosData.Set(procName, newMap)
	}
	else 
	{
		value2 := value.Get(key)
		if value2 = winSize
			return
		value.Set(key, winSize)
	}
	SaveWinSizePosData()
}

RemoveWinsSizePos()
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
	
	hMon := DllCall("MonitorFromRect", "Ptr", rect, "Int", 2) ; PRIMARY:1, NEAREST:2
	mon := Buffer(40)
	NumPut("Int", 40, mon)
	DllCall("GetMonitorInfo", "Int", hMon, "Ptr", mon)
	monLeft := NumGet(mon, 4, "int")
	monTop := NumGet(mon, 8, "int")
	monRight := NumGet(mon, 12, "int")
	monBottom := NumGet(mon, 16, "int")
	monSize := (monRight - monLeft) "," (monBottom - monTop)
	procName := WinGetProcessName()
	procName := Trim(procName)
	key := ""
	Switch sizePosKeyType.Get(procName)
	{
	case 1:
		key := monSize
	case 2:
		key := Trim(WinGetClass()) "," monSize
	case 3:
		key := Trim(WinGetClass()) "," Trim(WinGetTitle()) "," monSize
	}

	global winSizePosData
	value := winSizePosData.Get(procName)
	if value == ""
		return
	value2 := value.Get(key)
	if value2 == ""
		return
	value.Delete(key)
	if value.Count = 0
		winSizePosData.Delete(procName)
	SaveWinSizePosData()
}

SetWinsSizePos()
{
	global winSizePosData
	if winSizePosData.Count == 0
		return	
	id := WinGetList(,,"Program Manager")
	Loop id.Length
	{
		this_id := id[A_Index]
		this_procName := WinGetProcessName("ahk_id" this_id)
		value := winSizePosData.Get(this_procName)
		if value == ""
			continue
				
		rect := Buffer(16)
		bResult := DllCall("GetWindowRect", "Ptr", this_id, "Ptr", rect)
		if bResult == 0
			continue
		winLeft := NumGet(rect, 0, "int")
		winTop := NumGet(rect, 4, "int")
		winRight := NumGet(rect, 8, "int")
		winBottom := NumGet(rect, 12, "int")	
		
		hMon := DllCall("MonitorFromRect", "Ptr", rect, "Int", 2) ; PRIMARY:1, NEAREST:2
		mon := Buffer(40)
		NumPut("Int", 40, mon)
		DllCall("GetMonitorInfo", "Int", hMon, "Ptr", mon)
		monLeft := NumGet(mon, 4, "int")
		monTop := NumGet(mon, 8, "int")
		monRight := NumGet(mon, 12, "int")
		monBottom := NumGet(mon, 16, "int")
		monSize := (monRight - monLeft) "," (monBottom - monTop)
		key := ""
		Switch sizePosKeyType.Get(this_procName)
		{
		case 1:
			key := monSize
		case 2:
			key := Trim(WinGetClass("ahk_id" this_id)) "," monSize
		case 3:
			key := Trim(WinGetClass("ahk_id" this_id)) "," Trim(WinGetTitle("ahk_id" this_id)) "," monSize
		}
		value2 := value.Get(key)
		if value2 = ""
			continue
		arr := StrSplit(value2, ",")
		if arr.Length != 4
			continue
		if (winLeft - monLeft) != arr[1] or (winTop - monTop) != arr[2] or (winRight - winLeft) != arr[3] or (winBottom - winTop) != arr[4]
			WinMove(monLeft + arr[1], monTop + arr[2], arr[3], arr[4], "ahk_id" this_id)		
	}
}

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

	hMon := DllCall("MonitorFromRect", "Ptr", rect, "Int", 2) ; PRIMARY:1, NEAREST:2
	mon := Buffer(40)
	NumPut("Int", 40, mon)
	DllCall("GetMonitorInfo", "Int", hMon, "Ptr", mon)
	monLeft := NumGet(mon, 20, "int")
	monTop := NumGet(mon, 24, "int")
	monRight := NumGet(mon, 28, "int")
	monBottom := NumGet(mon, 32, "int")
	procName := WinGetProcessName()
	procName := Trim(procName)
	className := WinGetClass()
	className := Trim(className)
	winTitle := WinGetTitle()
	winTitle := Trim(winTitle)
	
	MsgBox "ProcName:" procName "`nClass:" className "`nTitle:" winTitle "`nWinPos:(" winLeft "," winTop ")`nWinSize(" (winRight - winLeft) "," (winBottom - winTop) ")`nMonSize:(" (monRight - monLeft) "," (monBottom - monTop) ")"
}

ChangeResolution(x)
{
	deviceMode := Buffer(156, 0)
	NumPut("UInt",156, deviceMode,36) 
	DllCall( "EnumDisplaySettingsA", "UInt",0, "UInt",-1, "Ptr",deviceMode )
	curW := NumGet(deviceMode, 108, "UInt")
	curH := NumGet(deviceMode, 112, "UInt")
	NumPut("UInt",0x180000, deviceMode,40) 
	prevW := 0
	prevH := 0
	nextOK := false
	global resolutionList
	For i, line in resolutionList
	{
		arr := StrSplit(line, ",")
		if arr.Length != 2
			continue
		if (not isInteger(Trim(arr[1]))) or (not isInteger(Trim(arr[2])))
			continue
		lineW := Trim(arr[1])
		lineH := Trim(arr[2])
		if nextOK
		{
			NumPut("UInt",lineW, deviceMode,108)
			NumPut("UInt",lineH, deviceMode,112)
			DllCall( "ChangeDisplaySettingsA", "Ptr",deviceMode, "UInt",0 )			
			Sleep 1000
			Reload
			return
			
		}
		if curW = lineW and curH = lineH
		{
			if x = 0
			{
				nextOK := true
				continue
			}
			if prevW = 0 or prevH = 0
				return
			NumPut("UInt",prevW, deviceMode,108)
			NumPut("UInt",prevH, deviceMode,112)
			DllCall( "ChangeDisplaySettingsA", "Ptr",deviceMode, "UInt",0 )			
			Sleep 1000
			Reload
			return
			
		}
		prevW := lineW
		prevH := lineH
	}
}

WinBringUp()
{
	posX := 0
	posY := 0
	hWnd := 0
	MouseGetPos &posX, &posY, &hWnd
	if WinActive("ahk_id" hWnd)
	{
		WinMoveBottom("ahk_id" hWnd)
		MouseGetPos &posX, &posY, &hWnd
	}
	WinActivate("ahk_id" hWnd)
	WinMoveTop("ahk_id" hWnd)
}
