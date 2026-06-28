#Requires AutoHotkey v2.0
#SingleInstance force

WINDOW_WIDTH := 285
WINDOW_HEIGHT := 355
TAB_HEIGHT := 150
WINDOW_X := 0
WINDOW_Y := 0

orderData := [
	{ value: "", name: "Customer No", regex: "cust(omer)?" },
	{ value: "", name: "Inquiry", regex: "Inquiry" },
	{ value: "", name: "Last Shipment", regex: "Last Shipment" },
	{ value: "", name: "Last Invoice", regex: "Last Invoice" },
	{ value: "", name: "Template Code", regex: "Template Code" },
	{ value: "", name: "PO", regex: "p(urchase)?o(rder)?" },
	{ value: "", name: "Order Date", regex: "order ?(date|day)" },
	{ value: "", name: "On Hold", regex: "On Hold" },
	{ value: "", name: "Order Type", regex: "Order Type" },
	{ value: "", name: "From Multiple Quotes", regex: "From Multiple Quotes" },
	{ value: "", name: "Ship-To Location", regex: "ship ?((to)? ?|loc(ation)?)" },
	{ value: "", name: "Location", regex: "[^ship ]loc(ation)?" },
	{ value: "", name: "Delivery By", regex: "del(iver)?y? ?(By)?" },
	{ value: "", name: "Exp. Ship Date", regex: "(exp(ected)? )?ship( )?(date|day|by)?" },
	{ value: "", name: "Calc Tax", regex: "Calc Tax" },
	{ value: "", name: "Ship Via", regex: "(ship )?via" },
	{ value: "", name: "Empty Box", regex: "empty box" },
	{ value: "", name: "Tracking No", regex: "track(ing)?" },
	{ value: "", name: "Description", regex: "desc(ription)?" },
	{ value: "", name: "Reference", regex: "ref(erence)?" },
]

;==============================================================================
;==================================== GUI =====================================
;==============================================================================

myGui := Gui("+0x40000 +E0x08000000 +ToolWindow +AlwaysOnTop +Resize") ; resizable
;WinSetTransparent(230, myGui)
myGui.MarginX := 10
myGui.MarginY := 10
MyGui.SetFont(, "Arial")
myGui.SetFont(, "Verdana")

myTabs := myGui.Add("Tab3", "Choose2 w" . WINDOW_WIDTH - 20 . " h" . TAB_HEIGHT, ["data", "order", "item"])

;================ Tab 1 ================
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
text2 := myGui.AddText("yp w180 r2", "paste clipboard with [DownKey]s inbetween each value")


;================ Tab 2 ================
myTabs.UseTab(2)

myGui.SetFont("s8 bold cBlack")
btn3 := myGui.AddButton("w100 h30 Section", "Enter Order Data")
btn3.OnEvent("Click", onEnterOrderData)
myGui.SetFont("s8 norm cBlue")
text3 := myGui.AddText("yp w150 r2", "testing out entering order data")

progressBar := myGui.AddProgress("xs ys+30 w200 h10")
progressBar.Visible := false

myGui.SetFont("s9 bold c075985")
capturedText := myGui.AddText("xs w200 h100 r4 +Right", "")

;============== Below Tab ==============
myTabs.UseTab()

myGui.SetFont("s6 norm cBlack")
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

	if(myTabs.Value = 2) {
		collectOrderData()
	}
}

collectOrderData(*) {
	copy := editBox.Value
	prefix := "(?i)"
	suffix := "[`t`n: ](?<nr>[^`t`n]+)"

	for index, item in orderData {
		found := RegExMatch(editBox.Value, prefix . item.regex . suffix, &SubPat)
		if(found > 0) {
			item.value := SubPat.nr
		} else {
			item.value := ""
		}
	}

	out := ""
	for index, item in orderData {
		out .= (item.value = "") ? "" : item.name . ": " . item.value . "`n"
	}
	capturedText.value := out
	editBox.value := copy
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

	row_txt := num_rows . ((num_rows > 1) ? " rows" : " row")
	col_txt := num_cols . ((num_cols > 1) ? " cols" : " col")
	statusBar.SetText("  " . row_txt . " x " . col_txt)
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

onEnterOrderData(*) {
	progressBar.Value := 10
	progressBar.Visible := true
	
	for index, item in orderData {
		if GetKeyState("ESC", "P")
			break
		if (item.value != "") {
			Send(item.value)
			Sleep(10)
		}
		if(index != orderData.Length) {
			Send("{tab}")
		}
		Sleep(200)
		if(item.name = "Customer No") {
			sleep(300)
			progressBar.Value := 20
			sleep(300)
			progressBar.value := 30
			sleep(300)
		}
		if(FALSE) {
			Sleep(500)
		}
		progressBar.Value := 30 + 70 * (index / orderData.Length)
	}
	progressBar.Visible := false
}
