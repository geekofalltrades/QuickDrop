Scriptname QuickDropMenuScript extends SKI_ConfigBase
{QuickDrop MCM menu script.}

QuickDropQuestScript Property QuickDropQuest Auto
{The main quest script.}

QuickDropPlayerRememberScript Property RememberScript Auto
{The player script responsible for OnItemAdded.}

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
	AddKeymapOptionST("ToggleRememberingHotkey", "Toggle Remembering", QuickDropQuest.toggleRememberingHotkey)
	DrawRememberedItems()
EndFunction

Function DrawAdvancedPage()
	{Draw the "Advanced" settings page.}
	AddHeaderOption("Settings")
	AddSliderOptionST("MaxRemembered", "Items Remembered", QuickDropQuest.maxRemembered, "{0}")
	AddTextOptionST("ForgetOnRemoved", "When Items Removed", ForgetOnRemovedBoolToString(QuickDropQuest.forgetOnRemoved))
	AddTextOptionST("ToggleRemembering", "Toggle Remembering", ToggleRememberingStateToString())
	AddToggleOptionST("RememberPersistentItems", "Remember Persistent Items", QuickDropQuest.rememberPersistent)
	AddEmptyOption()
	AddHeaderOption("Notifications")
	AddToggleOptionST("NotifyOnPersistent", "Persistent Items", QuickDropQuest.notifyOnPersistent)
	AddToggleOptionST("NotifyOnDrop", "Item Dropped", QuickDropQuest.notifyOnDrop)
	AddToggleOptionST("NotifyOnReplaceInContainer", "Item Replaced in Container", QuickDropQuest.notifyOnReplaceInContainer)
	AddToggleOptionST("NotifyOnKeep", "Item Kept", QuickDropQuest.notifyOnKeep)
	SetCursorPosition(1)
	AddHeaderOption("On Item(s) Picked Up")
	AddToggleOptionST("PickUpBehaviorRememberAll", "Remember Number Picked Up", QuickDropQuest.pickUpBehavior == 0)
	AddToggleOptionST("PickUpBehaviorCollapseAll", "Remember to One Stack Slot", QuickDropQuest.pickUpBehavior == 1)
	AddToggleOptionST("PickUpBehaviorRememberEach", "Remember Each Individually", QuickDropQuest.pickUpBehavior == 2)
	AddToggleOptionST("PickUpBehaviorRememberSome", "Remember Only Some Picked Up", QuickDropQuest.pickUpBehavior == 3)
	AddSliderOptionST("PickUpBehaviorModifier", "Modifier (Hover for Details)", QuickDropQuest.PickUpBehaviorModifier[QuickDropQuest.pickUpBehavior])
	AddEmptyOption()
	AddHeaderOption("On Item(s) Dropped")
	AddToggleOptionST("ReplaceInContainer", "Replace in Original Container", QuickDropQuest.replaceInContainer)
	AddToggleOptionST("RememberContainer", "Always Remember Containers", QuickDropQuest.rememberContainer)
EndFunction

Function DrawRememberedItems()
	SetCursorPosition(1)
	AddHeaderOption("Current Remembered Items")
	int i = 0
	int currentIndex = QuickDropQuest.currentIndex
	While i < QuickDropQuest.maxRemembered
		if QuickDropQuest.RememberedItems[currentIndex] != None
			AddTextOption(QuickDropQuest.RememberedItems[currentIndex].GetName() + " (" + QuickDropQuest.RememberedQuantities[currentIndex] + ")", "")
		else
			AddEmptyOption()
		endif
		currentIndex = QuickDropQuest.GetPreviousStackIndex(currentIndex)
		i += 1
	EndWhile

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
		return ShowMessage(msg, True, "Yes", "No")
	endif
	return True
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
	elseif KeyCode == QuickDropQuest.toggleRememberingHotkey
		return "Toggle Remembering"
	endif
	return ""
EndFunction

Event OnConfigClose()
	{When the menu is closed, rebind the hotkeys.}
	UnregisterForAllKeys()
	RegisterForKey(QuickDropQuest.showHotkey)
	RegisterForKey(QuickDropQuest.dropHotkey)
	RegisterForKey(QuickDropQuest.keepHotkey)
	RegisterForKey(QuickDropQuest.dropAllHotkey)
	RegisterForKey(QuickDropQuest.keepAllHotkey)
	RegisterForKey(QuickDropQuest.toggleRememberingHotkey)
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

State ToggleRememberingHotkey
	Event OnKeyMapChangeST(int keyCode, string conflictControl, string conflictName)
		if CheckKeyConflict(conflictControl, conflictName)
			QuickDropQuest.toggleRememberingHotkey = keyCode
			SetKeymapOptionValueST(keyCode)
		endif
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.toggleRememberingHotkey = -1
		SetKeymapOptionValueST(-1)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Toggle item remembering on and off. (Currently " + ToggleRememberingStateToString() + ".)\nWhen on, QuickDrop remembers new items as they're added to your inventory.\nWhen off, QuickDrop does not remember new items.")
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

string Function ForgetOnRemovedBoolToString(bool value)
	if value
		return "Forget First"
	else
		return "Forget Last"
	endif
EndFunction

State ForgetOnRemoved
	Event OnSelectST()
		QuickDropQuest.forgetOnRemoved = !QuickDropQuest.forgetOnRemoved
		SetTextOptionValueST(ForgetOnRemovedBoolToString(QuickDropQuest.forgetOnRemoved))
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.forgetOnRemoved = True
		SetTextOptionValueST(ForgetOnRemovedBoolToString(True))
	EndEvent

	Event OnHighlightST()
		SetInfoText("How to forget items in your stack when they're removed from your inventory outside of QuickDrop.\nForget First: Items are forgotten top-down as soon as they're removed, even if you have enough left to remember.\nForget Last: Items are forgotten bottom-up only once you don't have enough left to remember.")
	EndEvent
EndState

string Function ToggleRememberingStateToString()
	if RememberScript.GetState() == "Enabled"
		return "ON"
	else
		return "OFF"
	endif
EndFunction

State ToggleRemembering
	Event OnSelectST()
		if RememberScript.GetState() == "Enabled"
			RememberScript.GoToState("Disabled")
		else
			RememberScript.GoToState("Enabled")
		endif
		SetTextOptionValueST(ToggleRememberingStateToString())
	EndEvent

	Event OnDefaultST()
		RememberScript.GoToState("Enabled")
		SetTextOptionValueST(ToggleRememberingStateToString())
	EndEvent

	Event OnHighlightST()
		SetInfoText("While on, QuickDrop will remember new items that are added to your inventory.\nTurn off to freeze your stack of remembered items.\nCan be toggled in-game with the \"Toggle Remembering\" hotkey.")
	EndEvent
EndState

State RememberPersistentItems
	Event OnSelectST()
		QuickDropQuest.rememberPersistent = !QuickDropQuest.rememberPersistent
		SetToggleOptionValueST(QuickDropQuest.rememberPersistent)
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.rememberPersistent = False
		SetToggleOptionValueST(False)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Remember items with persistent references. This option allows QuickDrop to remember and drop quest items\nand some other items that might not normally be remembered. Use carefully - dropping quest items might break\nquest progression. Also consider setting \"Show Message for Persistent Items.\"")
	EndEvent
EndState

Function PickUpBehaviorOnSelect(int option)
	QuickDropQuest.AdjustPickUpBehavior(option)
	SetToggleOptionValueST(option == 0, True, "PickUpBehaviorRememberAll")
	SetToggleOptionValueST(option == 1, True, "PickUpBehaviorCollapseAll")
	SetToggleOptionValueST(option == 2, True, "PickUpBehaviorRememberEach")
	SetToggleOptionValueST(option == 3, True, "PickUpBehaviorRememberSome")
	SetSliderOptionValueSt(QuickDropQuest.pickUpBehaviorModifier[option], "{0}", False, "PickUpBehaviorModifier")
EndFunction

Function PickUpBehaviorOnDefault()
	{Reset the PickUpBehavior option group to its defaults.}
	QuickDropQuest.AdjustPickUpBehavior(0)
	SetToggleOptionValueST(true, True, "PickUpBehaviorRememberAll")
	SetToggleOptionValueST(false, True, "PickUpBehaviorCollapseAll")
	SetToggleOptionValueST(false, True, "PickUpBehaviorRememberEach")
	SetToggleOptionValueST(false, True, "PickUpBehaviorRememberSome")
	SetSliderOptionValueSt(QuickDropQuest.pickUpBehaviorModifier[0], "{0}", False, "PickUpBehaviorModifier")
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

State PickUpBehaviorModifier
	Event OnSliderOpenST()
		if QuickDropQuest.pickUpBehavior == 3
			SetSliderDialogDefaultValue(1.0)
			SetSliderDialogRange(1.0, 100.0)
		else
			SetSliderDialogDefaultValue(0.0)
			SetSliderDialogRange(0.0, 100.0)
		endif
		SetSliderDialogStartValue(QuickDropQuest.pickUpBehaviorModifier[QuickDropQuest.pickUpBehavior])
		SetSliderDialogInterval(1.0)
	EndEvent

	Event OnSliderAcceptST(float value)
		QuickDropQuest.pickUpBehaviorModifier[QuickDropQuest.pickUpBehavior] = value as int
		SetSliderOptionValueST(value, "{0}")
	EndEvent

	Event OnDefaultST()
		if QuickDropQuest.pickUpBehavior == 3
			QuickDropQuest.pickUpBehaviorModifier[3] = 1
			SetSliderOptionValueSt(1.0, "{0}")
		else
			QuickDropQuest.pickUpBehaviorModifier[QuickDropQuest.pickUpBehavior] = 0
			SetSliderOptionValueSt(0.0, "{0}")
		endif
	EndEvent

	Event OnHighlightST()
		if QuickDropQuest.pickUpBehavior == 0
			SetInfoText("The maximum number of items to remember in one stack slot. 0 means no limit.\nItems beyond these overflow into a new stack slot.\n")
		elseif QuickDropQuest.pickUpBehavior == 1
			SetInfoText("The maximum number of items to remember in the combined stack slot. 0 means no limit.\nItems beyond these are not remembered.")
		elseif QuickDropQuest.pickUpBehavior == 2
			SetInfoText("The maximum number of items to remember individually. 0 means no limit.")
		elseif QuickDropQuest.pickUpBehavior == 3
			SetInfoText("The maximum number of items to remember in one stack slot.\nItems beyond these are not remembered.")
		endif
	EndEvent
EndState

State ReplaceInContainer
	Event OnSelectST()
		QuickDropQuest.replaceInContainer = !QuickDropQuest.replaceInContainer
		SetToggleOptionValueST(QuickDropQuest.replaceInContainer)
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.replaceInContainer = False
		SetToggleOptionValueST(False)
	EndEvent

	Event OnHighlightST()
		SetInfoText("If the item(s) dropped came from a container, replace them in that container.\nThis makes containers into persistent references, which causes some script/savegame bloat.")
	EndEvent
EndState

State RememberContainer
	Event OnSelectST()
		QuickDropQuest.rememberContainer = !QuickDropQuest.rememberContainer
		SetToggleOptionValueST(QuickDropQuest.rememberContainer)
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.rememberContainer = False
		SetToggleOptionValueST(False)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Always remember the container item(s) came from, even if \"Replace In Container\" is disabled.\nThis allows you to replace items in containers even if \"Replace In Container\" wasn't enabled when you picked them up.\nThis makes containers into persistent references, which causes some script/savegame bloat.")
	EndEvent
EndState

State NotifyOnPersistent
	Event OnSelectST()
		QuickDropQuest.notifyOnPersistent = !QuickDropQuest.notifyOnPersistent
		SetToggleOptionValueST(QuickDropQuest.notifyOnPersistent)
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.notifyOnPersistent = False
		SetToggleOptionValueST(False)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Display a message when an item picked up has a persistent reference.\nPersistence is a property of certain significant items, notably quest items.\nDropping these items with QuickDrop may break quest progression.")
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

State NotifyOnReplaceInContainer
	Event OnSelectST()
		QuickDropQuest.notifyOnReplaceInContainer = !QuickDropQuest.notifyOnReplaceInContainer
		SetToggleOptionValueST(QuickDropQuest.notifyOnReplaceInContainer)
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.notifyOnReplaceInContainer = True
		SetToggleOptionValueST(True)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Display a message when the current item is replaced in its original container.")
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