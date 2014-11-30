Scriptname QuickDropMenuScript extends SKI_ConfigBase
{QuickDrop MCM menu script.}

QuickDropQuestScript Property QuickDropQuest Auto
{The main quest script.}

QuickDropPlayerRememberScript Property RememberScript Auto
{The player script responsible for OnItemAdded.}

QuickDropPlayerCrosshairScript Property CrosshairScript Auto
{The player script responsible for tracking OnCrosshairRefChanged events.}

int[] stackToggleIDs
bool[] selected

Event OnConfigInit()
	{Perform menu setup.}
	Pages = new string[4]
	Pages[0] = "Stack"
	Pages[1] = "General Settings"
	Pages[2] = "Pickup/Drop"
	Pages[3] = "Replace"
EndEvent

Event OnPageReset(string page)
	{Draw the menu.}
	SetCursorFillMode(TOP_TO_BOTTOM)
	if page == "Stack"
		DrawStackPage()
	elseif page == "General Settings"
		DrawGeneralSettingsPage()
	elseif page == "Pickup/Drop"
		DrawPickupDropPage()
	elseif page == "Replace"
		DrawReplacePage()
	endif
EndEvent

Function DrawStackPage()
	{Draw the "Stack" settings page.}
	AddHeaderOption("Selection")
	AddTextOptionST("StackInvertSelection", "Invert Selection", "")
	AddTextOptionST("StackSelectAll", "Select All", "")
	AddTextOptionST("StackSelectNone", "Select None", "")
	AddHeaderOption("Options")
	AddTextOptionST("StackDropSelected", "Drop Selected", "", OPTION_FLAG_DISABLED)
	AddTextOptionST("StackKeepSelected", "Keep Selected", "", OPTION_FLAG_DISABLED)
	AddTextOptionST("StackMoveUp", "Move Up", "", OPTION_FLAG_DISABLED)
	AddTextOptionST("StackMoveDown", "Move Down", "", OPTION_FLAG_DISABLED)
	AddTextOptionST("StackSwapSelected", "Swap", "", OPTION_FLAG_DISABLED)
	AddTextOptionST("StackCombineUp", "Combine Up", "", OPTION_FLAG_DISABLED)
	AddTextOptionST("StackCombineDown", "Combine Down", "", OPTION_FLAG_DISABLED)

	stackToggleIDs = new int[10]
	selected = new bool[10]
	int i = 0
	While i < stackToggleIDs.Length
		stackToggleIDs[i] = -1
		selected[i] = False
		i += 1
	EndWhile

	SetCursorPosition(1)
	AddHeaderOption("Current Remembered Items")
	int iterations = 0
	i = QuickDropQuest.currentIndex
	While QuickDropQuest.RememberedItems[i] != None && iterations < QuickDropQuest.maxRemembered
		;Note that ids are stored AT THEIR CORRESPONDING STACK INDEX, not starting from index 0 - this lets us use Find() to synchronize the option with its stack slot.
		stackToggleIDs[i] = AddToggleOption(QuickDropQuest.RememberedItems[i].GetName() + " (" + QuickDropQuest.RememberedQuantities[i] + ")", selected[i])
		i = QuickDropQuest.GetPreviousStackIndex(i)
		iterations += 1
	EndWhile
EndFunction

Function DrawGeneralSettingsPage()
	{Draw the "Advanced" settings page.}
	AddHeaderOption("Hotkeys")
	AddKeymapOptionST("ToggleRememberingHotkey", "Toggle Remembering", QuickDropQuest.toggleRememberingHotkey)
	AddKeymapOptionST("ShowHotkey", "Show Current Item", QuickDropQuest.showHotkey)
	AddKeymapOptionST("DropHotkey", "Drop Current Item", QuickDropQuest.dropHotkey)
	AddKeymapOptionST("KeepHotkey", "Keep Current Item", QuickDropQuest.keepHotkey)
	AddKeymapOptionST("DropAllHotkey", "Drop All Items", QuickDropQuest.dropAllHotkey)
	AddKeymapOptionST("KeepAllHotkey", "Keep All Items", QuickDropQuest.keepAllHotkey)
	SetCursorPosition(1)
	AddHeaderOption("Settings")
	AddSliderOptionST("MaxRemembered", "Items Remembered", QuickDropQuest.maxRemembered, "{0}")
	AddTextOptionST("ForgetOnRemoved", "When Items Removed", ForgetOnRemovedBoolToString(QuickDropQuest.forgetOnRemoved))
	AddTextOptionST("ToggleRemembering", "Toggle Remembering", ToggleRememberingStateToString())
EndFunction

Function DrawPickupDropPage()
	{Draw the "Pickup/Drop" settings page.}
	AddHeaderOption("Remembering Picked Up Items")
	AddToggleOptionST("PickUpBehaviorRememberAll", "Remember Number Picked Up", QuickDropQuest.pickUpBehavior == 0)
	AddSliderOptionST("PickUpBehaviorRememberAllModifier", "    Max Per Slot", QuickDropQuest.PickUpBehaviorModifier[0])
	AddToggleOptionST("PickUpBehaviorCollapseAll", "Remember to One Stack Slot", QuickDropQuest.pickUpBehavior == 1)
	AddSliderOptionST("PickUpBehaviorCollapseAllModifier", "    Max In Combined Slot", QuickDropQuest.PickUpBehaviorModifier[1])
	AddToggleOptionST("PickUpBehaviorRememberEach", "Remember Each Individually", QuickDropQuest.pickUpBehavior == 2)
	AddSliderOptionST("PickUpBehaviorRememberEachModifier", "    Max To Remember", QuickDropQuest.PickUpBehaviorModifier[2])
	AddToggleOptionST("PickUpBehaviorRememberSome", "Remember Only Some Picked Up", QuickDropQuest.pickUpBehavior == 3)
	AddSliderOptionST("PickUpBehaviorRememberSomeModifier", "    Max To Remember", QuickDropQuest.PickUpBehaviorModifier[3])
	AddEmptyOption()
	AddHeaderOption("Persistent Items")
	AddToggleOptionST("RememberPersistentItems", "Remember Persistent Items", QuickDropQuest.rememberPersistent)
	SetCursorPosition(1)
	AddHeaderOption("Notifications")
	AddToggleOptionST("NotifyOnDrop", "Item Dropped", QuickDropQuest.notifyOnDrop)
	AddToggleOptionST("NotifyOnKeep", "Item Kept", QuickDropQuest.notifyOnKeep)
	AddToggleOptionST("NotifyOnPersistent", "Persistent Items", QuickDropQuest.notifyOnPersistent)
EndFunction

Function DrawReplacePage()
	AddHeaderOption("Replace Items in Containers")
	AddToggleOptionST("ReplaceInContainer", "Replace in Container", QuickDropQuest.replaceInContainer)
	AddSliderOptionST("ReplaceInContainerDistance", "Replace in Container Distance", QuickDropQuest.replaceInContainerDistance, "{0}")
	AddToggleOptionST("ReplaceInContainerDropOnFail", "Drop if Can't Replace in Container", QuickDropQuest.replaceInContainerDropOnFail)
	AddToggleOptionST("RememberContainer", "Always Remember Containers", QuickDropQuest.rememberContainer)
	AddEmptyOption()
	AddHeaderOption("Replace Items in World")
	AddToggleOptionST("ReplaceInWorld", "Replace in World", QuickDropQuest.replaceInWorld)
	AddSliderOptionST("ReplaceInWorldDistance", "Replace in World Distance", QuickDropQuest.replaceInWorldDistance, "{0}")
	AddToggleOptionST("ReplaceInWorldDropOnFail", "Drop if Can't Replace in World", QuickDropQuest.replaceInWorldDropOnFail)
	AddToggleOptionST("RememberWorldLocation", "Always Remember World Locations", QuickDropQuest.rememberWorldLocation)
	SetCursorPosition(1)
	AddHeaderOption("Notifications")
	AddToggleOptionST("NotifyOnReplaceInContainer", "Item Replaced in Container", QuickDropQuest.notifyOnReplaceInContainer)
	AddToggleOptionST("NotifyOnFailToReplaceInContainer", "Failed to Replace In Container", QuickDropQuest.notifyOnFailToReplaceInContainer)
	AddToggleOptionST("NotifyOnReplaceInWorld", "Item Replaced in World", QuickDropQuest.notifyOnReplaceInWorld)
	AddToggleOptionST("NotifyOnFailToReplaceInWorld", "Failed to Replace In World", QuickDropQuest.notifyOnFailToReplaceInWorld)
EndFunction

Event OnConfigClose()
	{When the menu is closed, rebind the hotkeys and clean out any persistent state data.}
	UnregisterForAllKeys()
	RegisterForKey(QuickDropQuest.toggleRememberingHotkey)
	RegisterForKey(QuickDropQuest.showHotkey)
	RegisterForKey(QuickDropQuest.dropHotkey)
	RegisterForKey(QuickDropQuest.keepHotkey)
	RegisterForKey(QuickDropQuest.dropAllHotkey)
	RegisterForKey(QuickDropQuest.keepAllHotkey)

	stackToggleIDs = None
	selected = None
EndEvent

Function SetStackSelectionOptions(int flag, bool noUpdate = False)
	{Set the flag on the stack selection options. We want them off while we're working so our state is frozen.}
	int i = 0
	While i < stackToggleIDs.Length
		if stackToggleIDs[i] >= 0
			SetOptionFlags(stackToggleIDs[i], flag, True)
		endif
		i += 1
	EndWhile
	SetOptionFlagsST(flag, True, "StackInvertSelection")
	SetOptionFlagsST(flag, True, "StackSelectAll")
	SetOptionFlagsST(flag, noUpdate, "StackSelectNone")
EndFunction

Function DisableStackManipulationOptions()
	{Disable all stack manipulation options. We want them off while we're working so our state is frozen.}
	SetOptionFlagsST(OPTION_FLAG_DISABLED, True, "StackDropSelected")
	SetOptionFlagsST(OPTION_FLAG_DISABLED, True, "StackKeepSelected")
	SetOptionFlagsST(OPTION_FLAG_DISABLED, True, "StackMoveUp")
	SetOptionFlagsST(OPTION_FLAG_DISABLED, True, "StackMoveDown")
	SetOptionFlagsST(OPTION_FLAG_DISABLED, True, "StackSwapSelected")
	SetOptionFlagsST(OPTION_FLAG_DISABLED, True, "StackCombineUp")
	SetOptionFlagsST(OPTION_FLAG_DISABLED, True, "StackCombineDown")
EndFunction

Function UpdateStackOptions()
	{Update the stack options after a stack slot has been selected or unselected.}
	SetStackSelectionOptions(OPTION_FLAG_DISABLED, True)	;Disable all options so users can't mess with the state while we're working.
	DisableStackManipulationOptions()						;Don't update the page, though; this can cause an annoying flash.

	int numSelected = 0
	int i = selected.Find(True)
	While i >= 0
		numSelected += 1
		i = selected.Find(True, i + 1)
	EndWhile

	if numSelected > 0
		SetOptionFlagsST(OPTION_FLAG_NONE, True, "StackDropSelected")
		SetOptionFlagsST(OPTION_FLAG_NONE, True, "StackKeepSelected")
	endif

	if numSelected == 1
		SetOptionFlagsST(OPTION_FLAG_NONE, True, "StackMoveUp")
		SetOptionFlagsST(OPTION_FLAG_NONE, True, "StackMoveDown")
	endif

	if numSelected == 2
		SetOptionFlagsST(OPTION_FLAG_NONE, True, "StackSwapSelected")
	endif

	if numSelected > 1
		i = selected.Find(True)
		Form selectedItem = QuickDropQuest.RememberedItems[i]
		bool same = True

		;Do-While structure.
		i = selected.Find(True, i + 1)
		While i >= 0 && same
			if QuickDropQuest.RememberedItems[i] != selectedItem
				same = False
			endif
			i = selected.Find(True, i + 1)
		EndWhile

		if same
			SetOptionFlagsST(OPTION_FLAG_NONE, True, "StackCombineUp")
			SetOptionFlagsST(OPTION_FLAG_NONE, True, "StackCombineDown")
		endif
	endif

	SetStackSelectionOptions(OPTION_FLAG_NONE)	;Re-enable stack selection options and refresh the page.
EndFunction

Event OnOptionSelect(int option)
	{Old-style select for handling selection of rows in the stack menu.}
	int index = stackToggleIDs.Find(option)
	if index >= 0
		selected[index] = !selected[index]
		SetToggleOptionValue(option, selected[index], True)
		UpdateStackOptions()
	endif
EndEvent

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
	if KeyCode == QuickDropQuest.toggleRememberingHotkey
		return "Toggle Remembering"
	elseif KeyCode == QuickDropQuest.showHotkey
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
		SetInfoText("Attempt to drop or replace the current remembered item and proceed to the next.")
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
		SetInfoText("Attempt to drop or replace all remembered items.")
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
		SetInfoText("Remember items with persistent references. This option allows QuickDrop to remember and drop quest items\nand some other items that might not normally be remembered. Use carefully - dropping quest items might break\nquest progression. Also consider setting the \"Persistent Items\" notification.")
	EndEvent
EndState

Function PickUpBehaviorOnSelect(int option)
	QuickDropQuest.AdjustPickUpBehavior(option)
	SetToggleOptionValueST(option == 0, True, "PickUpBehaviorRememberAll")
	SetToggleOptionValueST(option == 1, True, "PickUpBehaviorCollapseAll")
	SetToggleOptionValueST(option == 2, True, "PickUpBehaviorRememberEach")
	SetToggleOptionValueST(option == 3, False, "PickUpBehaviorRememberSome")
EndFunction

Function PickUpBehaviorOnDefault()
	{Reset the PickUpBehavior option group to its defaults.}
	QuickDropQuest.AdjustPickUpBehavior(0)
	SetToggleOptionValueST(True, True, "PickUpBehaviorRememberAll")
	SetToggleOptionValueST(False, True, "PickUpBehaviorCollapseAll")
	SetToggleOptionValueST(False, True, "PickUpBehaviorRememberEach")
	SetToggleOptionValueST(False, False, "PickUpBehaviorRememberSome")
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

State PickUpBehaviorRememberAllModifier
	Event OnSliderOpenST()
		SetSliderDialogDefaultValue(0.0)
		SetSliderDialogRange(0.0, 100.0)
		SetSliderDialogStartValue(QuickDropQuest.pickUpBehaviorModifier[0])
		SetSliderDialogInterval(1.0)
	EndEvent

	Event OnSliderAcceptST(float value)
		QuickDropQuest.pickUpBehaviorModifier[0] = value as int
		SetSliderOptionValueST(value, "{0}")
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.pickUpBehaviorModifier[0] = 0
		SetSliderOptionValueSt(0.0, "{0}")
	EndEvent

	Event OnHighlightST()
		SetInfoText("The maximum number of items to remember in one stack slot. 0 means no limit.\nItems beyond these overflow into a new stack slot.\n")
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

State PickUpBehaviorCollapseAllModifier
	Event OnSliderOpenST()
		SetSliderDialogDefaultValue(0.0)
		SetSliderDialogRange(0.0, 100.0)
		SetSliderDialogStartValue(QuickDropQuest.pickUpBehaviorModifier[1])
		SetSliderDialogInterval(1.0)
	EndEvent

	Event OnSliderAcceptST(float value)
		QuickDropQuest.pickUpBehaviorModifier[1] = value as int
		SetSliderOptionValueST(value, "{0}")
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.pickUpBehaviorModifier[1] = 0
		SetSliderOptionValueSt(0.0, "{0}")
	EndEvent

	Event OnHighlightST()
		SetInfoText("The maximum number of items to remember in the combined stack slot. 0 means no limit.\nItems beyond these are not remembered.")
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

State PickUpBehaviorRememberEachModifier
	Event OnSliderOpenST()
		SetSliderDialogDefaultValue(0.0)
		SetSliderDialogRange(0.0, 100.0)
		SetSliderDialogStartValue(QuickDropQuest.pickUpBehaviorModifier[2])
		SetSliderDialogInterval(1.0)
	EndEvent

	Event OnSliderAcceptST(float value)
		QuickDropQuest.pickUpBehaviorModifier[2] = value as int
		SetSliderOptionValueST(value, "{0}")
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.pickUpBehaviorModifier[2] = 0
		SetSliderOptionValueSt(0.0, "{0}")
	EndEvent

	Event OnHighlightST()
		SetInfoText("The maximum number of items to remember individually. 0 means no limit.")
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

State PickUpBehaviorRememberSomeModifier
	Event OnSliderOpenST()
		SetSliderDialogDefaultValue(1.0)
		SetSliderDialogRange(1.0, 100.0)
		SetSliderDialogStartValue(QuickDropQuest.pickUpBehaviorModifier[3])
		SetSliderDialogInterval(1.0)
	EndEvent

	Event OnSliderAcceptST(float value)
		QuickDropQuest.pickUpBehaviorModifier[3] = value as int
		SetSliderOptionValueST(value, "{0}")
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.pickUpBehaviorModifier[3] = 1
		SetSliderOptionValueSt(1.0, "{0}")
	EndEvent

	Event OnHighlightST()
		SetInfoText("The maximum number of items to remember in one stack slot.\nItems beyond these are not remembered.")
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

State ReplaceInContainerDistance
	Event OnSliderOpenST()
		SetSliderDialogStartValue(QuickDropQuest.replaceInContainerDistance)
		SetSliderDialogDefaultValue(250.0)
		SetSliderDialogRange(0.0, 5000.0)
		SetSliderDialogInterval(50.0)
	EndEvent

	Event OnSliderAcceptST(float value)
		QuickDropQuest.replaceInContainerDistance = value as int
		SetSliderOptionValueST(value, "{0}")
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.replaceInContainerDistance = 250
		SetSliderOptionValueSt(250.0, "{0}")
	EndEvent

	Event OnHighlightST()
		SetInfoText("The maximum distance from which you can replace items in their original containers.\n0 means from any distance.")
	EndEvent
EndState

State ReplaceInContainerDropOnFail
	Event OnSelectST()
		QuickDropQuest.replaceInContainerDropOnFail = !QuickDropQuest.replaceInContainerDropOnFail
		SetToggleOptionValueST(QuickDropQuest.replaceInContainerDropOnFail)
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.replaceInContainerDropOnFail = True
		SetToggleOptionValueST(True)
	EndEvent

	Event OnHighlightST()
		SetInfoText("If the current item(s) can't be replaced in their containers, drop them instead.")
	EndEvent
EndState

State RememberContainer
	Event OnSelectST()
		QuickDropQuest.rememberContainer = !QuickDropQuest.rememberContainer
		SetToggleOptionValueST(QuickDropQuest.rememberContainer)
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.rememberContainer = True
		SetToggleOptionValueST(True)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Always remember the container item(s) came from, even if \"Replace In Container\" is disabled.\nThis allows you to replace items in containers even if \"Replace In Container\" wasn't enabled when you picked them up.\nThis makes containers into persistent references, which causes some script/savegame bloat.")
	EndEvent
EndState

State ReplaceInWorld
	Event OnSelectST()
		QuickDropQuest.ToggleReplaceInWorld()
		SetToggleOptionValueST(QuickDropQuest.replaceInWorld)
	EndEvent

	Event OnDefaultST()
		if QuickDropQuest.replaceInWorld
			QuickDropQuest.ToggleReplaceInWorld()
		endif
		SetToggleOptionValueST(False)
	EndEvent

	Event OnHighlightST()
		SetInfoText("If the item(s) dropped came from the world, replace them at their original location.\nThis creates persistent references, which causes some script/savegame bloat.")
	EndEvent
EndState

State ReplaceInWorldDistance
	Event OnSliderOpenST()
		SetSliderDialogStartValue(QuickDropQuest.replaceInWorldDistance)
		SetSliderDialogDefaultValue(250.0)
		SetSliderDialogRange(0.0, 5000.0)
		SetSliderDialogInterval(50.0)
	EndEvent

	Event OnSliderAcceptST(float value)
		QuickDropQuest.replaceInWorldDistance = value as int
		SetSliderOptionValueST(value, "{0}")
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.replaceInWorldDistance = 250
		SetSliderOptionValueSt(250.0, "{0}")
	EndEvent

	Event OnHighlightST()
		SetInfoText("The maximum distance from which you can replace items in their original world locations.\n0 means from any distance.")
	EndEvent
EndState

State ReplaceInWorldDropOnFail
	Event OnSelectST()
		QuickDropQuest.replaceInWorldDropOnFail = !QuickDropQuest.replaceInWorldDropOnFail
		SetToggleOptionValueST(QuickDropQuest.replaceInWorldDropOnFail)
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.replaceInWorldDropOnFail = True
		SetToggleOptionValueST(True)
	EndEvent

	Event OnHighlightST()
		SetInfoText("If the current item(s) can't be replaced in their original world locations, drop them instead.")
	EndEvent
EndState

State RememberWorldLocation
	Event OnSelectST()
		QuickDropQuest.ToggleRememberWorldLocation()
		SetToggleOptionValueST(QuickDropQuest.rememberWorldLocation)
	EndEvent

	Event OnDefaultST()
		if !QuickDropQuest.rememberWorldLocation
			QuickDropQuest.ToggleRememberWorldLocation()
		endif
		SetToggleOptionValueST(True)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Always remember the world location item(s) came from, even if \"Replace In World\" is disabled.\nThis allows you to replace items in the world even if \"Replace In World\" wasn't enabled when you picked them up.\nThis creates persistent references, which causes some script/savegame bloat.")
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
		SetInfoText("Display a message when the current item(s) are replaced in their original container.")
	EndEvent
EndState

State NotifyOnFailToReplaceInContainer
	Event OnSelectST()
		QuickDropQuest.notifyOnFailToReplaceInContainer = !QuickDropQuest.notifyOnFailToReplaceInContainer
		SetToggleOptionValueST(QuickDropQuest.notifyOnFailToReplaceInContainer)
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.notifyOnFailToReplaceInContainer = False
		SetToggleOptionValueST(False)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Display a message when the current item(s) can't be replaced in their original container.")
	EndEvent
EndState

State NotifyOnReplaceInWorld
	Event OnSelectST()
		QuickDropQuest.notifyOnReplaceInWorld = !QuickDropQuest.notifyOnReplaceInWorld
		SetToggleOptionValueST(QuickDropQuest.notifyOnReplaceInWorld)
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.notifyOnReplaceInWorld = False
		SetToggleOptionValueST(False)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Display a message when the current item(s) are replaced in their original world location.")
	EndEvent
EndState

State NotifyOnFailToReplaceInWorld
	Event OnSelectST()
		QuickDropQuest.notifyOnFailToReplaceInWorld = !QuickDropQuest.notifyOnFailToReplaceInWorld
		SetToggleOptionValueST(QuickDropQuest.notifyOnFailToReplaceInWorld)
	EndEvent

	Event OnDefaultST()
		QuickDropQuest.notifyOnFailToReplaceInWorld = False
		SetToggleOptionValueST(False)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Display a message when the current item(s) can't be replaced in their original world location.")
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