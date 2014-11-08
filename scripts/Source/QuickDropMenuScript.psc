Scriptname QuickDropMenuScript extends SKI_ConfigBase
{QuickDrop MCM menu script.}

QuickDropQuestScript Property QuickDropQuest Auto
{The main quest script.}

Event OnConfigInit()
	{Perform menu setup.}
	Pages = new string[2]
	Pages[0] = "Basic"
	Pages[1] = "Advanced"
EndEvent

Event OnPageReset(string page)
	{Draw the menu.}
	SetCursorFillMode(TOP_TO_BOTTOM)
	if page == "Basic"
		DrawBasicPage()
	elseif page == "Advanced"
		DrawAdvancedPage()
	endif
EndEvent

Function DrawBasicPage()
	{Draw the "Basic" settings page.}
	AddHeaderOption("Hotkeys")
	AddKeymapOptionST("ShowHotkey", "Show Current Item", QuickDropQuest.showHotkey)
	AddKeymapOptionST("DropHotkey", "Drop Current Item", QuickDropQuest.dropHotkey)
	AddKeymapOptionST("KeepHotkey", "Keep Current Item", QuickDropQuest.keepHotkey)
	AddKeymapOptionST("DropAllHotkey", "Drop All Items", QuickDropQuest.dropAllHotkey)
	AddKeymapOptionST("KeepAllHotkey", "Keep All Items", QuickDropQuest.keepAllHotkey)
	DrawRememberedItems()
EndFunction

Function DrawAdvancedPage()
	{Draw the "Advanced" settings page.}
	AddHeaderOption("General")
	AddSliderOptionST("MaxRemembered", "Items Remembered", QuickDropQuest.maxRemembered, "{0}")
	AddEmptyOption()
	AddHeaderOption("On Item(s) Picked Up")
	AddToggleOptionST("PickUpBehaviorRememberAll", "Remember Number Picked Up", QuickDropQuest.pickUpBehavior == 0)
	AddToggleOptionST("PickUpBehaviorCollapseAll", "Remember to One Stack Slot", QuickDropQuest.pickUpBehavior == 1)
	AddToggleOptionST("PickUpBehaviorRememberEach", "Remember Each Individually", QuickDropQuest.pickUpBehavior == 2)
	AddToggleOptionST("PickUpBehaviorRememberSome", "Remember Only Some Picked Up", QuickDropQuest.pickUpBehavior == 3)
	SetCursorPosition(1)
	AddHeaderOption("Notifications")
	AddToggleOptionST("NotifyOnSkip", "Show Message for Skipped Items", QuickDropQuest.notifyOnSkip)
	AddToggleOptionST("NotifyOnDrop", "Show Message when Item Dropped", QuickDropQuest.notifyOnDrop)
	AddToggleOptionST("NotifyOnKeep", "Show Message when Item Kept", QuickDropQuest.notifyOnKeep)
EndFunction

Function DrawRememberedItems()
	SetCursorPosition(1)
	AddHeaderOption("Current Remembered Items")
	int i = 0
	int currentIndex = QuickDropQuest.currentIndex
	While i < QuickDropQuest.maxRemembered
		if QuickDropQuest.RememberedItems[QuickDropQuest.currentIndex] != None
			AddTextOption(QuickDropQuest.RememberedItems[QuickDropQuest.currentIndex].GetName() + " (" + QuickDropQuest.RememberedQuantities[QuickDropQuest.currentIndex] + ")", "")
		else
			AddEmptyOption()
		endif
		QuickDropQuest.DecrementCurrentIndex()
		i += 1
	EndWhile

	QuickDropQuest.currentIndex = currentIndex

	While i < 10
		AddEmptyOption()
		i += 1
	EndWhile
EndFunction

bool Function CheckKeyConflict(string conflictControl, string conflictName)
	{Check for OnKeyMapChange key conflicts and get user input.}
	if conflictControl != ""
		string msg = ""
		if conflictName != ""
			msg = "This key is already mapped to " + conflictControl + " from " + conflictName +".\nAre you sure you want to continue?"
		else
			msg = "This key is already mapped to " + conflictControl + " from Skyrim.\nAre you sure you want to continue?"
		endif
		return ShowMessage(msg, true, "Yes", "No")
	endif
	return true
EndFunction

string Function GetCustomControl(int KeyCode)
	if KeyCode == QuickDropQuest.showHotkey
		return "Show Current Item"
	elseif KeyCode == QuickDropQuest.dropHotKey
		return "Drop Current Item"
	elseif KeyCode == QuickDropQuest.keepHotKey
		return "Keep Current Item"
	elseif KeyCode == QuickDropQuest.dropAllHotkey
		return "Drop All Items"
	elseif KeyCode == QuickDropQuest.keepAllHotkey
		return "Keep All Items"
	endif
	return ""
EndFunction

string Function QuantityIntToString(int quantityInt)
	if quantityInt == 0
		return "Remember All"
	elseif quantityInt == 1
		return "Collapse All"
	elseif quantityInt == 2
		return "Remember Each"
	elseif quantityInt == 3
		return "Remember One"
	endif
	return "ERROR - Please Report"
EndFunction

Event OnConfigClose()
	{When the menu is closed, rebind the hotkeys.}
	UnregisterForAllKeys()
	RegisterForKey(QuickDropQuest.showHotkey)
	RegisterForKey(QuickDropQuest.dropHotkey)
	RegisterForKey(QuickDropQuest.keepHotkey)
	RegisterForKey(QuickDropQuest.dropAllHotkey)
	RegisterForKey(QuickDropQuest.keepAllHotkey)
EndEvent

State ShowHotkey
	Event OnKeyMapChangeST(int keyCode, string conflictControl, string conflictName)
		if CheckKeyConflict(conflictControl, conflictName)
			QuickDropQuest.showHotkey = keyCode
			SetKeymapOptionValueST(keyCode)
		endif
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.showHotkey = -1
		SetKeymapOptionValueST(-1)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Display the name of the current remembered item.")
	EndEvent
EndState

State DropHotKey
	Event OnKeyMapChangeST(int keyCode, string conflictControl, string conflictName)
		if CheckKeyConflict(conflictControl, conflictName)
			QuickDropQuest.dropHotkey = keyCode
			SetKeymapOptionValueST(keyCode)
		endif
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.dropHotkey = -1
		SetKeymapOptionValueST(-1)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Drop the current remembered item and proceed to the next.")
	EndEvent
EndState

State KeepHotKey
	Event OnKeyMapChangeST(int keyCode, string conflictControl, string conflictName)
		if CheckKeyConflict(conflictControl, conflictName)
			QuickDropQuest.keepHotkey = keyCode
			SetKeymapOptionValueST(keyCode)
		endif
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.keepHotkey = -1
		SetKeymapOptionValueST(-1)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Keep the current remembered item and proceed to the next.")
	EndEvent
EndState

State DropAllHotkey
	Event OnKeyMapChangeST(int keyCode, string conflictControl, string conflictName)
		if CheckKeyConflict(conflictControl, conflictName)
			QuickDropQuest.dropAllHotkey = keyCode
			SetKeymapOptionValueST(keyCode)
		endif
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.dropAllHotkey = -1
		SetKeymapOptionValueST(-1)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Drop all remembered items.")
	EndEvent
EndState

State KeepAllHotkey
	Event OnKeyMapChangeST(int keyCode, string conflictControl, string conflictName)
		if CheckKeyConflict(conflictControl, conflictName)
			QuickDropQuest.keepAllHotkey = keyCode
			SetKeymapOptionValueST(keyCode)
		endif
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.keepAllHotkey = -1
		SetKeymapOptionValueST(-1)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Keep all remembered items.")
	EndEvent
EndState

State MaxRemembered
	Event OnSliderOpenST()
		SetSliderDialogStartValue(QuickDropQuest.maxRemembered)
		SetSliderDialogDefaultValue(5.0)
		SetSliderDialogRange(1.0, 10.0)
		SetSliderDialogInterval(1.0)
	EndEvent

	Event OnSliderAcceptST(float value)
		QuickDropQuest.AdjustMaxRemembered(value as int)
		ForcePageReset()
		SetSliderOptionValueST(value, "{0}")
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.AdjustMaxRemembered(5)
		ForcePageReset()
		SetSliderOptionValueSt(5.0, "{0}")
	EndEvent

	Event OnHighlightST()
		SetInfoText("Number of items to remember.\nThese form a stack of remembered items, with most recently picked up items on top.")
	EndEvent
EndState

Function PickUpBehaviorOnSelect(int option)
	QuickDropQuest.pickUpBehavior = option
	SetToggleOptionValueST(option == 0, true, "PickUpBehaviorRememberAll")
	SetToggleOptionValueST(option == 1, true, "PickUpBehaviorCollapseAll")
	SetToggleOptionValueST(option == 2, true, "PickUpBehaviorRememberEach")
	SetToggleOptionValueST(option == 3, false, "PickUpBehaviorRememberSome")
EndFunction

Function PickUpBehaviorOnDefault()
	{Reset the PickUpBehavior option group to its defaults.}
	QuickDropQuest.pickUpBehavior = 0
	SetToggleOptionValueST(true, true, "PickUpBehaviorRememberAll")
	SetToggleOptionValueST(false, true, "PickUpBehaviorCollapseAll")
	SetToggleOptionValueST(false, true, "PickUpBehaviorRememberEach")
	SetToggleOptionValueST(false, false, "PickUpBehaviorRememberSome")
EndFunction

State PickUpBehaviorRememberAll
	Event OnSelectST()
		PickUpBehaviorOnSelect(0)
	EndEvent

	Event OnDefaultST()
		PickUpBehaviorOnDefault()
	EndEvent

	Event OnHighlightST()
		SetInfoText("When item(s) are picked up, remember the item and the quantity picked up in one stack slot.\nItem(s) of the same type picked up separately occupy their own stack slots.")
	EndEvent
EndState

State PickUpBehaviorCollapseAll
	Event OnSelectST()
		PickUpBehaviorOnSelect(1)
	EndEvent

	Event OnDefaultST()
		PickUpBehaviorOnDefault()
	EndEvent

	Event OnHighlightST()
		SetInfoText("When item(s) are picked up, remember the item and the quantity picked up in one stack slot.\nItem(s) of the same type picked up separately are added to the same stack slot.\nThis shared stack slot is moved to the top of the stack whenever it's added to.")
	EndEvent
EndState

State PickUpBehaviorRememberEach
	Event OnSelectST()
		PickUpBehaviorOnSelect(2)
	EndEvent

	Event OnDefaultST()
		PickUpBehaviorOnDefault()
	EndEvent

	Event OnHighlightST()
		SetInfoText("When item(s) are picked up, remember each one individually.\nOnly as many are remembered as will fit in your remembered items stack.")
	EndEvent
EndState

State PickUpBehaviorRememberSome
	Event OnSelectST()
		PickUpBehaviorOnSelect(3)
	EndEvent

	Event OnDefaultST()
		PickUpBehaviorOnDefault()
	EndEvent

	Event OnHighlightST()
		SetInfoText("When item(s) are picked up, remember only some in one stack slot.\nThe rest go into your inventory without being remembered.")
	EndEvent
EndState

State NotifyOnSkip
	Event OnSelectST()
		QuickDropQuest.notifyOnSkip = !QuickDropQuest.notifyOnSkip
		SetToggleOptionValueST(QuickDropQuest.notifyOnSkip)
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.notifyOnSkip = False
		SetToggleOptionValueST(False)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Display a message when an item picked up has not been remembered.\nSome types of items - for example, quest items - are not remembered by QuickDrop.")
	EndEvent
EndState

State NotifyOnDrop
	Event OnSelectST()
		QuickDropQuest.notifyOnDrop = !QuickDropQuest.notifyOnDrop
		SetToggleOptionValueST(QuickDropQuest.notifyOnDrop)
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.notifyOnDrop = False
		SetToggleOptionValueST(False)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Display a message when the current item is dropped.")
	EndEvent
EndState

State NotifyOnKeep
	Event OnSelectST()
		QuickDropQuest.notifyOnKeep = !QuickDropQuest.notifyOnKeep
		SetToggleOptionValueST(QuickDropQuest.notifyOnKeep)
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.notifyOnKeep = False
		SetToggleOptionValueST(False)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Display a message when the current item is kept.")
	EndEvent
EndState