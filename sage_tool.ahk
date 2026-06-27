#Requires AutoHotkey v2.0
#SingleInstance force

WINDOW_WIDTH := 265
WINDOW_HEIGHT := 355
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

myGui.SetFont("s8")

;==== First Button
btn1 := myGui.AddButton("w60 h30 Section", "Tab Data")
btn1.OnEvent("Click", (*) => pasteClipboard("{tab}"))
text1 := myGui.AddText("yp w180 r2", "paste clipboard with [Tab]s inbetween each value")

;==== Second Button
btn2 := myGui.AddButton("xs w60 h30 Section", "Down Data")
btn2.OnEvent("Click", (*) => pasteClipboard("{down}"))
text1 := myGui.AddText("yp w180 r2", "paste clipboard with [Down Key]s inbetween each value")



myGui.SetFont("s8")
myBtn := myGui.AddButton("x190 y100 w65 h35 Section", "Read Clipboard")
myBtn.OnEvent("Click", printClipboard)

myGui.SetFont("s12")
myGui.AddText("x5 ys+15 Section", "Clipboard contents:")

myGui.SetFont("s10")
editBox := myGui.AddEdit("xs+0 ys+28 Multi ReadOnly VScroll HScroll w250 h200", "")
editBox.Opt("BackgroundBFDBFE")

myGui.OnEvent("Close", (*) => ExitApp())
myGui.Show(Format("w{1} h{2} x{3} y{4}", WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_X, WINDOW_Y))

;==============================================================================
;=============================== EVENTS & KEYS ================================
;==============================================================================

OnClipboardChange clipChanged
myGui.OnEvent("Size", onWindowResized)

;==============================================================================
;================================= FUNCTIONS ==================================
;==============================================================================

clipChanged(DataType) {
	if (DataType != 1) {
		editBox.value := ""
		return
	}
	printClipboard()
}

onWindowResized(guiObject, eventInfo, width, height) {
	editBox.GetPos(&x, &y)
	editBox.Move(x, y, width - x - 20, height - y - 10)
}

printClipboard(*) {
	clip_1 := RegExReplace(A_Clipboard, "[ ,$]", "")
	clip_2 := RegExReplace(clip_1, "(`r`n)[`r`n]+", "${1}")
	editBox.Value := clip_2
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