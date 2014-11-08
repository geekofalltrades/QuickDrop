Scriptname QuickDropMenuScript extends SKI_ConfigBase
{QuickDrop MCM menu script.}

QuickDropQuestScript Property QuickDropQuest Auto
{The main quest script.}

QuickDropPlayerScript Property QuickDropPlayer Auto
{The player script.}

Event OnPageReset(string page)
	{Draw the menu.}
	SetCursorFillMode(TOP_TO_BOTTOM)
	AddHeaderOption("Hotkeys")
	AddKeymapOptionST("ShowHotkey", "Show Current Item", QuickDropQuest.showHotkey)
	AddKeymapOptionST("DropHotkey", "Drop Current Item", QuickDropQuest.dropHotkey)
	AddKeymapOptionST("KeepHotkey", "Keep Current Item", QuickDropQuest.keepHotkey)
	AddKeymapOptionST("DropAllHotkey", "Drop All Items", QuickDropQuest.dropAllHotkey)
	AddKeymapOptionST("KeepAllHotkey", "Keep All Items", QuickDropQuest.keepAllHotkey)
	AddEmptyOption()
	AddHeaderOption("Settings")
	AddSliderOptionST("MaxRemembered", "Items Remembered", QuickDropQuest.maxRemembered, "{0}")
	AddTextOptionST("QuantityHandling", "Quantity Handling", QuantityIntToString(QuickDropPlayer.quantityHandling))
	AddToggleOptionST("NotifyOnSkip", "Show Message for Skipped Items", QuickDropPlayer.notifyOnSkip)
	AddToggleOptionST("NotifyOnDrop", "Show Message when Item Dropped", QuickDropQuest.notifyOnDrop)
	AddToggleOptionST("NotifyOnKeep", "Show Message when Item Kept", QuickDropQuest.notifyOnKeep)
	DrawRememberedItems()
EndEvent

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
		return "Remember Each"
	elseif quantityInt == 2
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

State QuantityHandling
	Event OnSelectST()
		SetTextOptionValueST(QuantityIntToString(QuickDropPlayer.IncrementQuantityHandling()))
	EndEvent

	Event OnDefaultST()
		QuickDropPlayer.quantityHandling = 0
		SetTextOptionValueST("Remember All")
	EndEvent

	Event OnHighlightST()
		SetInfoText("How to remember multiple items of the same type when picked up at once.\nRemember All: Remember items as a stack. Remember Each: Remember as many individually as possible.\nRemember One: Remember only one of the item picked up.")
	EndEvent
EndState

State NotifyOnSkip
	Event OnSelectST()
		QuickDropPlayer.notifyOnSkip = !QuickDropPlayer.notifyOnSkip
		SetToggleOptionValueST(QuickDropPlayer.notifyOnSkip)
	EndEvent

	Event OnDefaultST()
		QuickDropPlayer.notifyOnSkip = False
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