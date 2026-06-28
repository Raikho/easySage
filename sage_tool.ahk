#Requires AutoHotkey v2.0
#SingleInstance force

WINDOW_WIDTH := 285
WINDOW_HEIGHT := 355
TAB_HEIGHT := 150
WINDOW_X := 0
WINDOW_Y := 0

;==============================================================================
;==================================== GUI =====================================
;==============================================================================

myGui := Gui("+0x40000 +E0x08000000 +ToolWindow +AlwaysOnTop +Resize") ; resizable
WinSetTransparent(250, myGui)
myGui.MarginX := 10
myGui.MarginY := 10
MyGui.SetFont(, "Arial")
myGui.SetFont(, "Verdana")

myTabs := myGui.Add("Tab3", "w" . WINDOW_WIDTH - 20 . " h" . TAB_HEIGHT, ["main", ""])
myTabs.UseTab(1)

;==== First Button
myGui.SetFont("s8 bold cBlack")
btn1 := myGui.AddButton("w70 h30 Section", "Tab Data")
btn1.OnEvent("Click", (*) => pasteClipboard("{tab}"))

myGui.SetFont("s8 norm cBlue")
text1 := myGui.AddText("yp w180 r2", "paste clipboard with [Tab]s inbetween each value")

;==== Second Button
myGui.SetFont("s8 bold cBlack")
btn2 := myGui.AddButton("xs w70 h30 Section", "Down Data")
btn2.OnEvent("Click", (*) => pasteClipboard("{down}"))

myGui.SetFont("s7 norm cBlue")
text1 := myGui.AddText("yp w180 r2", "paste clipboard with [DownKey]s inbetween each value")

myTabs.UseTab()


myGui.SetFont("s6 cBlack")
myBtn := myGui.AddButton("x200 y140 w55 h25 Section y" . TAB_HEIGHT + 15, "Read Clipboard")
myBtn.OnEvent("Click", printClipboard)

myGui.SetFont("s12")
myGui.AddText("x5 yp+5 Section", "Clipboard contents:")

myGui.SetFont("s10")
editBox := myGui.AddEdit("xs+0 y+0 Multi ReadOnly VScroll HScroll w270 h140", "")
editBox.Opt("BackgroundBFDBFE")

statusBar := mygui.AddStatusBar()
statusBar.SetText("")

myGui.Show(Format("w{1} h{2} x{3} y{4}", WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_X, WINDOW_Y))
getStartingClipboard()

;==============================================================================
;=============================== EVENTS & KEYS ================================
;==============================================================================

OnClipboardChange onClipChanged
myGui.OnEvent("Size", onWindowResized)
myGui.OnEvent("Close", (*) => ExitApp())

;==============================================================================
;================================= FUNCTIONS ==================================
;==============================================================================

getStartingClipboard(*) {
	if DllCall("IsClipboardFormatAvailable", "uint", 1) {
		printClipboard()
	}
}

onClipChanged(DataType) {
	if (DataType != 1) {
		editBox.value := ""
		statusBar.SetText("")
		return
	}
	printClipboard()
}

onWindowResized(guiObject, eventInfo, width, height) {
	editBox.GetPos(&x, &y)
	editBox.Move(x, y, width - x - 10, height - y - 27)
	MyTabs.GetPos(&tx, &ty)
	MyTabs.Move(tx, ty, width - 20)
}

printClipboard(*) {
	clip_1 := RegExReplace(A_Clipboard, "[ ,$]", "")
	clip_2 := RegExReplace(clip_1, "(`r`n)[`r`n]+", "${1}")
	editBox.Value := clip_2
	refreshStats()
}

refreshStats(*) {
	lines := StrSplit(editBox.value, "`n", "`r")
	IF(StrLen(lines[-1]) = 0) {
		lines.Pop()
	}

	max_tabs := 0
	for index, line in lines {
		RegExReplace(line, "`t",, &num_tabs)
		max_tabs := (num_tabs > max_tabs) ? num_tabs : max_tabs 
	}
	num_rows := lines.Length
	num_cols := max_tabs + 1

	statusBar.SetText("  " . num_rows . " rows x " . num_cols . " cols")
}

pasteClipboard(key) {
	copy := editBox.Value
	arr := StrSplit(editBox.Value, [A_TAB, "`n"])
	for field in arr {
		if GetKeyState("ESC", "P")
			break
		if (field = "")
			continue
		Send(field)
		Sleep(10)
		Send(key)
		Sleep(10)
	}
	editBox.Value := copy
}