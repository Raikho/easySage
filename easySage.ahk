#REQUIRES AutoHotkey v2.0
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
	{ VALUE: "", TIME:  1, name: "Last Shipment", regex: "Last Shipment" },
	{ value: "", time:  1, name: "Last Invoice", regex: "Last Invoice" },
	{ value: "", time:  1, name: "Template Code", regex: "Template Code" },
	{ value: "", time:  1, name: "PO", regex: "p(urchase)?o(rder)?" },
	{ value: "", time:  1, name: "Order Date", regex: "order ?(date|day)" },
	{ value: "", time:  1, name: "On Hold", regex: "On Hold" },
	{ value: "", time:  1, name: "Order Type", regex: "Order Type" },
	{ value: "", time:  1, name: "From Multiple Quotes", regex: "From Multiple Quotes" },
	{ value: "", time:  7, name: "Ship-To Location", regex: "(ship loc|ship to|ship to loc|shipto)" },
	{ value: "", time:  1, name: "Location", regex: "[^ship ]loc(ation)?" },
	{ value: "", time:  1, name: "Delivery By", regex: "del(iver)?y? ?(By)?" },
	{ value: "", time:  1, name: "Exp. Ship Date", regex: "(exp(ected)? )?ship( )?(date|day|by)" },
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

; Switching to settings tab removes the NoActivate setting on the window
myTabs.OnEvent("Change", (t, *) => ui.Opt((t.value = 4 ? "-" : "+") . "E0x08000000"))

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

dataProgress := ui.AddProgress("xs ys+63 w200 h10 Section")
dataProgress.Visible := False

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

ui.AddText("Section", "Delay for data tab (ms):"),
data_delay := ui.AddEdit("ys w60 h20 Number Limit4", 10),
ui.AddUpDown("Range1-999", 30)

ui.AddText("Section xs", "Other Delay (ms):"),
delay := ui.AddEdit("ys w60 h20 Number Limit4", 100),
ui.AddUpDown("Range20-3000", 100)


;=============================== CLIPBOARD AREA ===============================
myTabs.UseTab()

ui.SetFont("s6 norm cBlack")
myBtn := ui.AddButton("x200 y140 w55 h25 Section y" . TAB_HEIGHT + 15, "Read Clipboard")
myBtn.OnEvent("Click", printClipboard)

ui.SetFont("s12")
ui.AddText("x5 yp+5 Section", "Clipboard contents:")


list := ui.Add("ListView", "x10 y195 w265 h133 NoSortHdr Grid ReadOnly Count20 -Hdr -LV0x20", ["", "", "", "", ""])
list.Opt("BackgroundBFDBFE")
list.SetFont("s8")

grid := [[]]
max_rows := 0
max_cols := 0


ui.SetFont("s10")
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
		global grid := [[]]
		statusBar.SetText("")
		return
	}
	printClipboard()
}

onWindowResized(guiObject, eventInfo, width, height) {
	list.GetPos(&x, &y)
	list.Move(x, y, width - x - 10, height - y - 27)
	MyTabs.GetPos(&tx, &ty)
	MyTabs.Move(tx, ty, width - 20)
}

printClipboard(*) {
	clip_1 := RegExReplace(A_Clipboard, "[,$]", "") ; commas, dollar signs
	clip_2 := RegExReplace(clip_1, "(`r`n)[`r`n]+", "${1}") ; replaces double newlines with single
	popualteGrid(clip_2)
	populateList(grid)
	;editBox.Value := clip_2
	;refreshStats()

	if(myTabs.Value = 2) {
		collectOrderData()
	}
}

popualteGrid(clipboard_str) {
	global grid := StrSplit(clipboard_str, "`n", "`r")
	if(StrLen(grid[-1]) = 0) {
		grid.Pop()
	}

	for i, row in grid {
		grid[i] := []
		for j, col in StrSplit(row, "`t") {
			if (col != "") {
				grid[i].Push(col)
			}
		}
	}
	refreshStats()
}

refreshStats(*) {
	global max_rows := grid.Length
	global max_cols := 0
	for i, row in grid {
		cols := row.Length
		max_cols := cols > max_cols ? cols : max_cols
	}
	row_txt := max_rows . ((max_rows > 1) ? " rows" : " row")
	col_txt := max_cols . ((max_cols > 1) ? " cols" : " col")
	statusBar.SetText("  " . row_txt . " x " . col_txt)
}

populateList(arr) {
	list.Opt("-Redraw")
	list.Delete()

	col_count := list.GetCount("Col")

	if (max_cols > col_count) {
		diff := max_cols - col_count
		tooltip("col_count: " . col_count . ", max: " . max_cols . ", diff: ", diff)
		Loop diff {
			list.InsertCol()
		}
	} else if (max_cols < col_count) {
		i := 0
		while (i <= max_cols && col_count - i > 4) {
			list.DeleteCol(col_count - i)
			i++
		}
	}

	for i, row in arr {
		list.Add(, row*)
	}
	list.ModifyCol()
	list.Opt("+Redraw")
}

collectOrderData(*) {
	flat_array := []
	for i, row in grid {
		for j, cell in row {
			flat_array.Push(cell)
		}
	}

	prefix := "(?i)"
	;suffix := "[`t`n: ](?<nr>[^`t`n]+)"
	for i, item in orderData {
		for j, cell in flat_array {
			found := RegExMatch(cell, prefix . item.regex, &subpat)
			if (found > 0 && j < flat_array.Length) {
				next_cell := flat_array[j + 1]
				item.value := next_cell
				continue 2
			}
		}
		item.value := ""

	}

	out := ""
	for i, item in orderData {
		out .= (item.value = "") ? "" : item.name . ": " . item.value . "`n"
	}
	capturedText.value := out
}

getNumGridEntries(*) {
	num_entries := 0
	for i, row in grid
		for j, cell in row
			if (cell != "")
				num_entries++
	return num_entries
}


pasteClipboard(key) {
	dataProgress.Value := 0
	progress := 0
	num_entries := getNumGridEntries()
	if (num_entries == 0) {
		return
	}
	tick := 100 / num_entries
	dataProgress.Opt("c50C878")
	dataProgress.Visible := true

	for i, row in grid {
		for j, cell in row {
			if GetKeyState("ESC", "P") {
				dataProgress.Opt("cRed")
				SetTimer(() => dataProgress.Visible := false, -5000)
				return
			}
			if (cell = "") {
				continue
			}
			send(cell)
			progress += tick / 2
			dataProgress.value := Round(progress)
			Sleep(data_delay.value)

			send (key)
			progress += tick / 2
			dataProgress.value := Round(progress)
			Sleep(data_delay.value)
		}
	}
	dataProgress.Opt("c22FF00")
    SetTimer(() => dataProgress.Visible := false, -5000)
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
