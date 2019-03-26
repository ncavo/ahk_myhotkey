StringCaseSense, Off
CoordMode, Mouse, Screen

FileDelete myhotkey.log

fX = 0
fY = 0
registeredWindows := []
savedWindowData := []
currentConfigGroup = "[]"
Loop, read, myhotkey.ini
{
	line := Trim(A_LoopReadLine)
	if SubStr(line, 1, 1) = "[" and SubStr(line, -0) = "]"
	{
		currentConfigGroup := line
	}
	else if (currentConfigGroup = "[WheelScrollEmulator]")
	{
		arr := StrSplit(line, "=")
		if Trim(arr[1]) = "fX"
		{
			fX := Trim(arr[2])
		}
		else if Trim(arr[1]) = "fY"
		{
			fY := Trim(arr[2])
		}	
	}
	else if (currentConfigGroup = "[WindowProcessRegister]")
	{
		if SubStr(line, 1, 1) <> ";"
			registeredWindows.Push(line)
	}
}
Loop, read, myhotkey.dat
{
	arr := StrSplit(Trim(A_LoopReadLine), ":")
	if arr.Length() <> 6
		continue
	found = 0
	for i, line in registeredWindows
	{
		if Trim(arr[1]) = Trim(StrSplit(line, "=")[1])
		{
			found = 1
			break
		}
	}
	if found = 1
	{
		savedWindowData.Push(Trim(A_LoopReadLine))
	}
}
return

XButton1::
if (fX > 0) or (fY > 0)
{
	bIsMoved = 0
	MouseGetPos, pX, pY
	SetTimer, OnTimer, 100
}
return

XButton1 Up::
if (fX > 0) or (fY > 0)
{
	SetTimer, OnTimer, Off
	if bIsMoved = 0
		MouseClick, Middle
}
return

OnTimer:
MouseGetPos, nX, nY
MouseMove, pX, pY
dX += nX - pX
dY += nY - pY
;FileAppend, MouseDelta(%dX%`,%dY%) `n, myhotkey.log
if (fX > 0)
{
	if dX >= %fX%
	{
		bIsMoved = 1
		c := dX // fX
		MouseClick, WR,,,c
		dX -= c * fX
	}
	else if dX <= -%fX%
	{
		bIsMoved = 1
		c := -dX // fX
		MouseClick, WL,,,c
		dX += c * fX
	}
}

if (fY > 0)
{
	if dY >= %fY%
	{
		bIsMoved = 1
		c := dY // fY
		MouseClick, WD,,,c
		dY -= c * fY
	}
	else if dY <= -%fY%
	{
		bIsMoved = 1
		c := -dY // fY
		MouseClick, WU,,,c
		dY += c * fY
	}
}
return

<!#Left UP::
WindowSizeAndMove(registeredWindows, savedWindowData, 1)
return

<!#Right UP::
WindowSizeAndMove(registeredWindows, savedWindowData, 2)
return

<!#Up UP::
WindowSizeAndMove(registeredWindows, savedWindowData, 3)
return

<!#Down UP::
WindowSizeAndMove(registeredWindows, savedWindowData, 4)
return

<!#Home UP::
WindowSizeAndMove(registeredWindows, savedWindowData, 5)
return

<!#End UP::
WindowSizeAndMove(registeredWindows, savedWindowData, 6)
return

<!#PgUp UP::
WindowSizeAndMove(registeredWindows, savedWindowData, 7)
return

<!#PgDn UP::
WindowSizeAndMove(registeredWindows, savedWindowData, 8)
return

WindowSizeAndMove(ByRef registeredWindows, ByRef savedWindowData, keyNum)
{
	FileAppend, %A_LineNumber%] WindowSizeAndMove(%keyNum%)`n, myhotkey.log
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
	hMon := DllCall("MonitorFromRect", "ptr", &rect, "int", 2) ; MONITOR_DEFAULTTONEAREST
	VarSetCapacity(mon, 40)
	NumPut(40, mon, 0, "int")
	DllCall("GetMonitorInfo", "int", hMon, "ptr", &mon)
	monLeft := NumGet(mon, 20, "int")
	monTop := NumGet(mon, 24, "int")
	monRight := NumGet(mon, 28, "int")
	monBottom := NumGet(mon, 32, "int")
	
	if keyNum = 1
	{
		gap := (monRight - monLeft) - (winRight - winLeft)
		if (gap <= 0)
			return
		d := gap // 4
		gap += monLeft
		if (gap + 3 < winLeft)
		{
			WinMove,A,,gap,winTop
			return
		}
		gap -= d
		if (gap + 3 < winLeft)
		{
			WinMove,A,,gap,winTop
			return
		}
		gap -= d
		if (gap + 3 < winLeft)
		{
			WinMove,A,,gap,winTop
			return
		}
		gap -= d
		if (gap + 3 < winLeft)
		{
			WinMove,A,,gap,winTop
			return
		}
		WinMove,A,,monLeft,winTop
		return
	}
	else if keyNum = 2
	{
		gap := (monRight - monLeft) - (winRight - winLeft)
		if (gap <= 0)
			return
		d := gap // 4
		gap := monLeft
		if (winLeft + 3 < gap)
		{
			WinMove,A,,gap,winTop
			return
		}
		gap += d
		if (winLeft + 3 < gap)
		{
			WinMove,A,,gap,winTop
			return
		}
		gap += d
		if (winLeft + 3 < gap)
		{
			WinMove,A,,gap,winTop
			return
		}
		gap += d
		if (winLeft + 3 < gap)
		{
			WinMove,A,,gap,winTop
			return
		}
		gap += d
		WinMove,A,,gap,winTop
		return		
	}
	else if keyNum = 3
	{
		gap := (monBottom - monTop) - (winBottom - winTop)
		if (gap <= 0)
			return
		d := gap // 4
		gap += monTop
		if (gap + 3 < winTop)
		{
			WinMove,A,,winLeft,gap
			return
		}
		gap -= d
		if (gap + 3 < winTop)
		{
			WinMove,A,,winLeft,gap
			return
		}
		gap -= d
		if (gap + 3 < winTop)
		{
			WinMove,A,,winLeft,gap
			return
		}
		gap -= d
		if (gap + 3 < winTop)
		{
			WinMove,A,,winLeft,gap
			return
		}
		WinMove,A,,winLeft,monTop
		return
	}
	else if keyNum = 4
	{
		gap := (monBottom - monTop) - (winBottom - winTop)
		if (gap <= 0)
			return
		d := gap // 4
		gap := monTop
		if (winTop + 3 < gap)
		{
			WinMove,A,,winLeft,gap
			return
		}
		gap += d
		if (winTop + 3 < gap)
		{
			WinMove,A,,winLeft,gap
			return
		}
		gap += d
		if (winTop + 3 < gap)
		{
			WinMove,A,,winLeft,gap
			return
		}
		gap += d
		if (winTop + 3 < gap)
		{
			WinMove,A,,winLeft,gap
			return
		}
		gap += d
		WinMove,A,,winLeft,gap
		return		
	}
	
	WinGet, procName, ProcessName
	procName := Trim(procName)
	WinGetClass, className
	className := Trim(className)	
	winWidth := winRight - winLeft
	winHeight := winBottom - winTop
	FileAppend, %A_LineNumber%] procName=%procName% className=%className% winSize(%winWidth%`,%winHeight%)`n, myhotkey.log

	if keyNum = 5
	{
		found = 0
		for i, line in registeredWindows
		{
			arr := StrSplit(line, "=")
			if (procName = Trim(arr[1]))
			{
				found = 1
				break
			}
		}
		if found = 0
		{
			MsgBox % "Not registered window: " . procName . "/" . className
			return
		}
		for i, line in savedWindowData
		{
			arr := StrSplit(line, ":")
			if (procName = Trim(arr[1])) and (className = Trim(arr[2]))
			{
				savedWindowData.RemoveAt(i)
				break
			}
		}
		line := procName . ":" . className . ":" . winLeft - monLeft . ":" . winTop - monTop . ":" . winRight - winLeft . ":" . winBottom - winTop
		savedWindowData.Push(line)
		FileDelete myhotkey.dat
		for i, line in savedWindowData
			FileAppend, %line%`n, myhotkey.dat
		MsgBox Saved
		return
	}
	else if keyNum = 6
	{
		for i, line in savedWindowData
		{
			arr := StrSplit(line, ":")
			if (procName = Trim(arr[1])) and (className = Trim(arr[2]))
			{
				WinMove,A,,monLeft + Trim(arr[3]),monTop + Trim(arr[4]),Trim(arr[5]),Trim(arr[6])
				return
			}
		}
		MsgBox % "Not saved window: " . procName . "/" . className
		return
	}
	
	targetSizeWidth = 0
	targetSizeHeight = 0
	found = 0
	for i, line in registeredWindows
	{
		arr := StrSplit(line, "=")
		if arr.Length() <> 2
			continue
		if (procName <> Trim(arr[1]))
			continue
		arr := StrSplit(arr[2], ",")
		if arr.Length() <> 2
			continue
		temp1 := GetWindowSizeWithParam(Trim(arr[1]), monRight - monLeft)
		temp2 := GetWindowSizeWithParam(Trim(arr[2]), monBottom - monTop)
		FileAppend, %A_LineNumber%] targetSize(%targetSizeWidth%`,%targetSizeHeight%) temp(%temp1%`,%temp2%) found=%found%`n, myhotkey.log
		if (temp1 < 10) or (temp1 > monRight - monLeft) or (temp2 < 10) or (temp2 > monBottom - monTop)
			continue
		if (found = 0)
		{
			if (winWidth = temp1) and (winHeight = temp2)
			{
				found = 1
				if (targetSizeWidth <> 0) and (targetSizeHeight <> 0) and (keyNum = 7)
				{
					WinMove,A,,((monRight - monLeft - targetSizeWidth) // 2) + monLeft,((monBottom - monTop - targetSizeHeight) // 2) + monTop,targetSizeWidth,targetSizeHeight
					return
				}
			}
			else if (targetSizeWidth = 0) and (targetSizeHeight = 0)
			{
				targetSizeWidth = %temp1%
				targetSizeHeight = %temp2%
			}
			else if keyNum = 7
			{
				targetSizeWidth = %temp1%
				targetSizeHeight = %temp2%				
			}
		}
		else
		{
			targetSizeWidth = %temp1%
			targetSizeHeight = %temp2%				
			if keyNum = 8
			{
				WinMove,A,,((monRight - monLeft - targetSizeWidth) // 2) + monLeft,((monBottom - monTop - targetSizeHeight) // 2) + monTop,targetSizeWidth,targetSizeHeight
				return
			}			
		}
	}
	FileAppend, %A_LineNumber%] targetSize(%targetSizeWidth%`,%targetSizeHeight%) found=%found%`n, myhotkey.log
	if (targetSizeWidth <> 0) and (targetSizeHeight <> 0)
	{
		WinMove,A,,((monRight - monLeft - targetSizeWidth) // 2) + monLeft,((monBottom - monTop - targetSizeHeight) // 2) + monTop,targetSizeWidth,targetSizeHeight		
	}
	else if (found = 0)
	{
		MsgBox % "Not registered window: " . procName . " (" . winWidth . "," . winHeight . ") (" . Round(winWidth * 100 // (monRight - monLeft),0) . "%," . Round(winHeight * 100 // (monBottom - monTop),0) . "%)"
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
		if (minus > 0) and (minus < size)
		{
			return size - minus
		}		
	}
	return param
}