#Requires AutoHotkey v2.0
#SingleInstance force

debug := false
WINDOW_WIDTH := 285
WINDOW_HEIGHT := 355
TAB_HEIGHT := 150
WINDOW_X := debug ? -600 : 0
WINDOW_Y := debug ? 20 : 0

orderData := [
	{ value: "", time: 20, name: "Customer No", regex: "cust(omer)?" },
	{ value: "", time:  1, name: "Inquiry", regex: "Inquiry" },
	{ value: "", time:  1, name: "Last Shipment", regex: "Last Shipment" },
	{ value: "", time:  1, name: "Last Invoice", regex: "Last Invoice" },
	{ value: "", time:  1, name: "Template Code", regex: "Template Code" },
	{ value: "", time:  1, name: "PO", regex: "p(urchase)?o(rder)?" },
	{ value: "", time:  1, name: "Order Date", regex: "order ?(date|day)" },
	{ value: "", time:  1, name: "On Hold", regex: "On Hold" },
	{ value: "", time:  1, name: "Order Type", regex: "Order Type" },
	{ value: "", time:  1, name: "From Multiple Quotes", regex: "From Multiple Quotes" },
	{ value: "", time:  7, name: "Ship-To Location", regex: "ship ?((to)? ?|loc(ation)?)" },
	{ value: "", time:  1, name: "Location", regex: "[^ship ]loc(ation)?" },
	{ value: "", time:  1, name: "Delivery By", regex: "del(iver)?y? ?(By)?" },
	{ value: "", time:  1, name: "Exp. Ship Date", regex: "(exp(ected)? )?ship( )?(date|day|by)?" },
	{ value: "", time:  1, name: "Calc Tax", regex: "Calc Tax" },
	{ value: "", time:  1, name: "Ship Via", regex: "(ship )?via" },
	{ value: "", time:  1, name: "Empty Box", regex: "empty box" },
	{ value: "", time:  1, name: "Tracking No", regex: "track(ing)?" },
	{ value: "", time:  1, name: "Description", regex: "desc(ription)?" },
	{ value: "", time:  1, name: "Reference", regex: "ref(erence)?" },
]

;==============================================================================
;==================================== GUI =====================================
;==============================================================================

ui := Gui("+0x40000 +E0x08000000 +ToolWindow +AlwaysOnTop +Resize") ; resizable
;WinSetTransparent(230, ui)
ui.MarginX := 10
ui.MarginY := 10
ui.SetFont("s8", "Arial")
ui.SetFont("s8", "Verdana")

default_tab := debug ? 2 : 1
myTabs := ui.Add("Tab3", "Choose" . default_tab . " w" . WINDOW_WIDTH - 20 . " h" . TAB_HEIGHT, ["data", "order", "item", "settings"])

;================================ TAB 1 - DATA ================================
myTabs.UseTab(1)

;==== DATA WITH TABS
btn1 := ui.AddButton("w70 h30 Section", "Tab Data")
btn1.SetFont("bold")
btn1.OnEvent("Click", (*) => pasteClipboard("{tab}"))

text1 := ui.AddText("yp w180 r2", "paste clipboard with [Tab]s inbetween each value")
text1.setFont("s7 cBlue")

;==== DATA WITH DOWN ARROW
btn2 := ui.AddButton("xs w70 h30 Section", "Down Data")
btn2.SetFont("bold")
btn2.OnEvent("Click", (*) => pasteClipboard("{down}"))

text2 := ui.AddText("yp w180 r2", "paste clipboard with [DownKey]s inbetween each value")
text2.setFont("s7 cBlue")


;=============================== TAB 2 - ORDER ================================
myTabs.UseTab(2)

btn3 := ui.AddButton("w100 h30 Section", "Enter Order Data")
btn3.SetFont("bold")
btn3.OnEvent("Click", onEnterOrderData)

text3 := ui.AddText("yp w150 r2", "testing out entering order data")
text3.SetFont("s7 cBlue")

progressBar := ui.AddProgress("xs ys+30 w200 h10 Section")
progressBar.Visible := false

progressText := ui.addText("xs ys+10 w200 h15 Section", "Customer: xxxx")
progressText.SetFont("s8 cBlue", "Consolas")
progressText.Visible := false

capturedText := ui.AddText("xs ys+15 w200 h100 r6 +Right", "")
capturedText.SetFont("s7 c075985", "Consolas")

;================================ TAB 3 - ITEM ================================
myTabs.UseTab(3)


;============================== TAB 4 - SETTINGS ==============================
myTabs.UseTab(4)
ui.AddText("Section", "Delay (ms) :"),
delay := ui.AddEdit("ys w50 h20 Number Limit4", 100),

;=============================== CLIPBOARD AREA ===============================
myTabs.UseTab()

ui.SetFont("s6 norm cBlack")
myBtn := ui.AddButton("x200 y140 w55 h25 Section y" . TAB_HEIGHT + 15, "Read Clipboard")
myBtn.OnEvent("Click", printClipboard)

ui.SetFont("s12")
ui.AddText("x5 yp+5 Section", "Clipboard contents:")

ui.SetFont("s10")
editBox := ui.AddEdit("xs+0 y+0 Multi ReadOnly VScroll HScroll w270 h140", "")
editBox.Opt("BackgroundBFDBFE")

statusBar := ui.AddStatusBar()
statusBar.SetText("")

ui.Show(Format("w{1} h{2} x{3} y{4}", WINDOW_WIDTH, WINDOW_HEIGHT, WINDOW_X, WINDOW_Y))
getStartingClipboard()

;==============================================================================
;=============================== EVENTS & KEYS ================================
;==============================================================================

OnClipboardChange onClipChanged
ui.OnEvent("Size", onWindowResized)
ui.OnEvent("Close", (*) => ExitApp())

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
	progressText.Visible := true
	progressBar.Opt("cBlue")
	startingWinID := WinGetID("A")

	timeSegments := 0
	for i, x in orderData {
		timeSegments += x.time
	}
	tick := 100 / timeSegments

	for index, item in orderData {
		if(WinGetID("A") != startingWinID || GetKeyState("ESC", "P")) {
			progressBar.value := 0
			break
		}
		progressText.value := item.name . ": " . item.value

		if (item.value != "") {
			Send(item.value)
			progressText.SetFont("cBlue")
			Sleep(10)
		} else {
			progressText.SetFont("cGray")
		}
		if(index != orderData.Length) {
			Send("{tab}")
			Loop item.time {
				Sleep(delay.value)
				progressBar.Value += tick
			}
		}
	}
	progressBar.Visible := false
	progressText.Visible := false
}

;==============================================================================
;================================== MISC ======================================
;==============================================================================

$^F12::{
	out := "The window ID is: " . WinGetID("A")
	out .= "`nThe Window Title is: " . WinGetTitle("A")
	if (CaretGetPos(&x, &y)) {
		out .= "`nCaret positions: " . x . ", " . y
	}
	ToolTip(out)
	sleep(1200)
	ToolTip("")
}
