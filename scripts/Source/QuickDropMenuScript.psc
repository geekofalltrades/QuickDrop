Scriptname QuickDropMenuScript extends SKI_ConfigBase
{QuickDrop MCM menu script.}

QuickDropQuestScript Property QuickDropQuest Auto
{The main quest script.}

QuickDropStackScript Property Stack Auto
{The stack script.}

QuickDropPlayerRememberScript Property RememberScript Auto
{The player script responsible for OnItemAdded.}

QuickDropPlayerCrosshairScript Property CrosshairScript Auto
{The player script responsible for tracking OnCrosshairRefChanged events.}

int[] stackToggleIDs
bool[] selected
int numSelected

string[] yesOrNo

Event OnConfigInit()
	{Perform menu setup.}
	Pages = new string[4]
	Pages[0] = "$Stack"
	Pages[1] = "$General Settings"
	Pages[2] = "$Pickup/Drop"
	Pages[3] = "$Replace"

	yesOrNo = new string[2]
	yesOrNo[0] = "$Yes"
	yesOrNo[1] = "$No"
EndEvent

Event OnPageReset(string page)
	{Draw the menu.}
	if page == ""
		LoadCustomContent("QuickDrop_MCM.dds", 120, 95)
		return
	else
		UnloadCustomContent()
	endif

	SetCursorFillMode(TOP_TO_BOTTOM)
	if page == "$Stack"
		DrawStackPage()
	elseif page == "$General Settings"
		DrawGeneralSettingsPage()
	elseif page == "$Pickup/Drop"
		DrawPickupDropPage()
	elseif page == "$Replace"
		DrawReplacePage()
	endif
EndEvent

Event OnConfigOpen()
	{Allocate arrays for stack selection. They will be kept until the menu is closed.}
	;The ID arrays are initialized on first call to to DrawStackPage.
	;Additionally, new IDs are procured every time a page reset occurs.
	stackToggleIDs = new int[10]

	;The selected array's state persists for the duration of the menu session. It's initialized now.
	selected = new bool[10]
	int i = 0
	While i < selected.Length
		selected[i] = False
		i += 1
	EndWhile

	numSelected = 0
EndEvent

Event OnConfigClose()
	{When the menu is closed, rebind the hotkeys and clean out any persistent state data.}
	UnregisterForAllKeys()
	RegisterForKey(QuickDropQuest.toggleRememberingHotkey)
	RegisterForKey(QuickDropQuest.showHotkey)
	RegisterForKey(QuickDropQuest.dropHotkey)
	RegisterForKey(QuickDropQuest.keepHotkey)
	RegisterForKey(QuickDropQuest.dropAllHotkey)
	RegisterForKey(QuickDropQuest.keepAllHotkey)

	;This is apparently the closest we can get to deallocating these arrays. Papyrus.
	stackToggleIDs = new int[1]
	selected = new bool[1]
EndEvent

Function DrawStackPage()
	{Draw the "Stack" settings page.}
	AddHeaderOption("$Options")
	AddTextOptionST("StackClearLocation", "$Clear Locations From Selection", "", ClearLocationFlag())

	int keepDropFlagValue = KeepDropFlag()
	AddTextOptionST("StackDropSelected", "$Drop Selected", "", keepDropFlagValue)
	AddTextOptionST("StackKeepSelected", "$Keep Selected", "", keepDropFlagValue)

	AddTextOptionST("StackMoveUp", "$Move Up", "", MoveUpFlag())
	AddTextOptionST("StackMoveDown", "$Move Down", "", MoveDownFlag())
	AddTextOptionST("StackSwapSelected", "$Swap", "", SwapFlag())

	int combineFlagValue = CombineFlag()
	AddTextOptionST("StackCombineUp", "$Combine Up", "", combineFlagValue)
	AddTextOptionST("StackCombineDown", "$Combine Down", "", combineFlagValue)
	AddEmptyOption()

	AddHeaderOption("Selection")
	AddTextOptionST("StackInvertSelection", "$Invert Selection", "")
	AddTextOptionST("StackSelectAll", "$Select All", "")
	AddTextOptionST("StackSelectNone", "$Select None", "")

	SetCursorPosition(1)
	AddHeaderOption("$Current Remembered Items")

	int i = 0
	While i < stackToggleIDs.Length
		stackToggleIDs[i] = -1
		i += 1
	EndWhile

	int iterations = 0
	i = Stack.top
	While iterations < Stack.depth
		;Note that ids are stored AT THEIR CORRESPONDING STACK INDEX, not starting from index 0 - this lets us use Find() to synchronize the option with its stack slot.
		stackToggleIDs[i] = AddToggleOption(Stack.items[i].GetName() + " (" + Stack.quantities[i] + ")", selected[i])
		i = Stack.GetPreviousStackIndex(i)
		iterations += 1
	EndWhile
EndFunction

State StackClearLocation
	Event OnSelectST()
		QuickDropQuest.GoToState("Working")
		int i = selected.Find(True)
		While i >= 0
			if Stack.HasWorldLocation(i)
				Stack.locations[i].Delete()
			endif
			Stack.locations[i] = None
			i = selected.Find(True, i + 1)
		EndWhile
		QuickDropQuest.GoToState("Ready")
		UpdateStackOptions()
	EndEvent

	Event OnHighlightST()
		SetInfoText("$STACK_CLEAR_LOCATION_HIGHLIGHT")
	EndEvent
EndState

int[] Function GetSelectedIndices()
	{Return an array of selected indices in top-down stack order. If not full, it is terminated with -1.}
	int index = 0
	int[] selectedIndices = new int[10]

	;Start from the top index and move down the stack to the bottom of the array.
	int i = selected.Rfind(True, Stack.top)
	While i >= 0
		selectedIndices[index] = i
		index += 1
		if i == 0	;Edge case: if Rfind returns 0, then our next Rfind would be from index 0 - 1 = -1 (the end of the array), and we enter an infinite loop.
			i = -1
		else
			i = selected.Rfind(True, i - 1)
		endif
	EndWhile

	;Wrap around to the top of the array and search back down the stack to the current index.
	i = selected.Rfind(True)
	While i > Stack.top
		selectedIndices[index] = i
		index += 1
		i = selected.Rfind(True, i - 1)
	EndWhile

	;If we haven't filled selectedIndices, terminate it with -1.
	if index < selectedIndices.Length
		selectedIndices[index] = -1
	endif

	return selectedIndices
EndFunction

State StackDropSelected
	Event OnSelectST()
		int[] toDrop = GetSelectedIndices()
		QuickDropQuest.GoToState("Working")
		if toDrop.Find(-1) == 1	;If we have only one selected index.
			QuickDropQuest.DropSingleItem(toDrop[0])
		else	;If we have more than one selected index.
			QuickDropQuest.DropMultipleItems(toDrop)
		endif
		QuickDropQuest.GoToState("Ready")
		ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("$STACK_DROP_SELECTED_HIGHLIGHT")
	EndEvent
EndState

State StackKeepSelected
	Event OnSelectST()
		int[] toKeep = GetSelectedIndices()
		QuickDropQuest.GoToState("Working")
		if toKeep.Find(-1) == 1	;If we have only one selected index.
			QuickDropQuest.KeepSingleItem(toKeep[0])
		else	;If we have more than one selected index.
			QuickDropQuest.KeepMultipleItems(toKeep)
		endif
		QuickDropQuest.GoToState("Ready")
		ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("$STACK_KEEP_SELECTED_HIGHLIGHT")
	EndEvent
EndState

Function Swap(int indexOne, int indexTwo)
	{Swap the given indices. Wrapper around Stack.Swap that additionally handles swapping menu selection data.}
	bool tempSelected = selected[indexOne]
	selected[indexOne] = selected[indexTwo]
	selected[indexTwo] = tempSelected

	Stack.Swap(indexOne, indexTwo)
EndFunction

State StackMoveUp
	Event OnSelectST()
		int swapUp = selected.Find(True)
		Swap(swapUp, Stack.GetNextStackIndex(swapUp))
		ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("$STACK_MOVE_UP_HIGHLIGHT")
	EndEvent
EndState

State StackMoveDown
	Event OnSelectST()
		int swapDown = selected.Find(True)
		Swap(swapDown, Stack.GetPreviousStackIndex(swapDown))
		ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("$STACK_MOVE_DOWN_HIGHLIGHT")
	EndEvent
EndState

State StackSwapSelected
	Event OnSelectST()
		int swapOne = selected.Find(True)
		Swap(swapOne, selected.Find(True, swapOne + 1))
		ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("$STACK_SWAP_SELECTED_HIGHLIGHT")
	EndEvent
EndState

Function Remove(int index)
	{Remove the given stack index. Wrapper around Stack.Remove that additionally handles removing menu selection data.}
	int tempIndex = index

	While index != Stack.top
		int nextIndex = Stack.GetNextStackIndex(index)
		selected[index] = selected[nextIndex]
		index = nextIndex
	EndWhile

	Stack.Remove(tempIndex)

	numSelected -= 1
	selected[index] = False
EndFunction

State StackCombineUp
	Event OnSelectST()
		int[] indices = GetSelectedIndices()
		int combineTo = indices[0]
		int i = 1

		While indices[i] >= 0 && i < indices.Length
			Stack.quantities[combineTo] = Stack.quantities[combineTo] + Stack.quantities[indices[i]]
			Remove(indices[i])
			combineTo = Stack.GetPreviousStackIndex(combineTo)	;We just pulled a slot out from the middle of the stack, so adjust our top-most index down.
			i += 1
		EndWhile

		ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("$STACK_COMBINE_UP_HIGHLIGHT")
	EndEvent
EndState

State StackCombineDown
	Event OnSelectST()
		int[] indices = GetSelectedIndices()
		int combineTo
		int i

		i = indices.Find(-1)
		if i < 0
			combineTo = indices[-1]
		else
			combineTo = indices[i - 1]
		endif

		i = 0
		While indices[i] != combineTo
			Stack.quantities[combineTo] = Stack.quantities[combineTo] + Stack.quantities[indices[i]]
			Remove(indices[i])
			i += 1
		EndWhile

		ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("$STACK_COMBINE_DOWN_HIGHLIGHT")
	EndEvent
EndState

State StackInvertSelection
	Event OnSelectST()
		int i = Stack.top
		int iterations = 0
		While iterations < Stack.depth
			selected[i] = !selected[i]
			i = Stack.GetPreviousStackIndex(i)
			iterations += 1
		EndWhile

		numSelected = Stack.depth - numSelected

		UpdateStackOptions()
	EndEvent

	Event OnHighlightST()
		SetInfoText("$STACK_INVERT_SELECTION_HIGHLIGHT")
	EndEvent
EndState

State StackSelectAll
	Event OnSelectST()
		int i = Stack.top
		int iterations = 0
		While iterations < Stack.depth
			selected[i] = True
			i = Stack.GetPreviousStackIndex(i)
			iterations += 1
		EndWhile

		numSelected = Stack.depth

		UpdateStackOptions()
	EndEvent

	Event OnHighlightST()
		SetInfoText("$STACK_SELECT_ALL_HIGHLIGHT")
	EndEvent
EndState

State StackSelectNone
	Event OnSelectST()
		int i = Stack.top
		int iterations = 0
		While iterations < Stack.depth
			selected[i] = False
			i = Stack.GetPreviousStackIndex(i)
			iterations += 1
		EndWhile

		numSelected = 0

		UpdateStackOptions()
	EndEvent

	Event OnHighlightST()
		SetInfoText("$STACK_SELECT_NONE_HIGHLIGHT")
	EndEvent
EndState

int Function ClearLocationFlag()
	{Calculate the current flag value for the clear location option.}
	int i = selected.Find(True)
	While i >= 0
		if Stack.locations[i] != None
			return OPTION_FLAG_NONE
		endif
		i = selected.Find(True, i + 1)
	EndWhile

	return OPTION_FLAG_DISABLED
EndFunction

int Function KeepDropFlag()
	{Calculate the current flag value for the keep/drop options.}
	if numSelected > 0
		return OPTION_FLAG_NONE
	endif

	return OPTION_FLAG_DISABLED
EndFunction

int Function MoveUpFlag()
	{Calculate the current flag value for the Move Up option.}
	if numSelected == 1
		int i = selected.Find(True)
		if i != Stack.top
			return OPTION_FLAG_NONE
		endif
	endif

	return OPTION_FLAG_DISABLED
EndFunction

int Function MoveDownFlag()
	{Calculate the current flag value for the Move Down option.}
	if numSelected == 1
		int i = Stack.GetPreviousStackIndex(selected.Find(True))
		if i != Stack.top && Stack.items[i] != None
			return OPTION_FLAG_NONE
		endif
	endif

	return OPTION_FLAG_DISABLED
EndFunction

int Function SwapFlag()
	{Calculate the current flag value for the Swap option.}
	if numSelected == 2
		return OPTION_FLAG_NONE
	endif

	return OPTION_FLAG_DISABLED
EndFunction

int Function CombineFlag()
	{Calculate the current flag value for the Combine Up and Combine Down options.}
	if numSelected > 1
		int i = selected.Find(True)
		Form selectedItem = Stack.items[i]

		i = selected.Find(True, i + 1)
		While i >= 0
			if Stack.items[i] != selectedItem
				return OPTION_FLAG_DISABLED
			endif
			i = selected.Find(True, i + 1)
		EndWhile

		return OPTION_FLAG_NONE
	endif

	return OPTION_FLAG_DISABLED
EndFunction

Function SetStackSelectionOptions(int flag, bool noUpdate = False)
	{Set the given flag on the stack selection options. When options are enabled, their values are updated. We want these options off while we're working so our state is frozen.}
	int i = 0
	While i < stackToggleIDs.Length && stackToggleIDs[i] >= 0
		SetOptionFlags(stackToggleIDs[i], flag, True)
		if flag == OPTION_FLAG_NONE	;If we're enabling this option.
			SetToggleOptionValue(stackToggleIDs[i], selected[i], True)	;Also refresh the option's value, so that this function refreshes the page.
		endif
		i += 1
	EndWhile
	SetOptionFlagsST(flag, True, "StackInvertSelection")
	SetOptionFlagsST(flag, True, "StackSelectAll")
	SetOptionFlagsST(flag, noUpdate, "StackSelectNone")
EndFunction

Function DisableStackManipulationOptions()
	{Disable all stack manipulation options. We want these options off while we're working so our state is frozen.}
	SetOptionFlagsST(OPTION_FLAG_DISABLED, True, "StackClearLocation")
	SetOptionFlagsST(OPTION_FLAG_DISABLED, True, "StackDropSelected")
	SetOptionFlagsST(OPTION_FLAG_DISABLED, True, "StackKeepSelected")
	SetOptionFlagsST(OPTION_FLAG_DISABLED, True, "StackMoveUp")
	SetOptionFlagsST(OPTION_FLAG_DISABLED, True, "StackMoveDown")
	SetOptionFlagsST(OPTION_FLAG_DISABLED, True, "StackSwapSelected")
	SetOptionFlagsST(OPTION_FLAG_DISABLED, True, "StackCombineUp")
	SetOptionFlagsST(OPTION_FLAG_DISABLED, True, "StackCombineDown")
EndFunction

Function UpdateStackOptions()
	{Update the stack options in bulk. Takes the place of a forced page reset, where one isn't necessary.}
	SetStackSelectionOptions(OPTION_FLAG_DISABLED, True)	;Disable all options so users can't mess with the state while we're working.
	DisableStackManipulationOptions()						;Don't update the page, though; this can cause an annoying flash.

	SetOptionFlagsST(ClearLocationFlag(), True, "StackClearLocation")

	int keepDropFlagValue = KeepDropFlag()
	SetOptionFlagsST(keepDropFlagValue, True, "StackDropSelected")
	SetOptionFlagsST(keepDropFlagValue, True, "StackKeepSelected")

	SetOptionFlagsST(MoveUpFlag(), True, "StackMoveUp")
	SetOptionFlagsST(MoveDownFlag(), True, "StackMoveDown")
	SetOptionFlagsST(SwapFlag(), True, "StackSwapSelected")

	int combineFlagValue = CombineFlag()
	SetOptionFlagsST(combineFlagValue, True, "StackCombineUp")
	SetOptionFlagsST(combineFlagValue, True, "StackCombineDown")

	SetStackSelectionOptions(OPTION_FLAG_NONE)	;Re-enable stack selection options and refresh the page.
EndFunction

Event OnOptionSelect(int option)
	{Old-style select for handling selection of rows in the stack menu.}
	int index = stackToggleIDs.Find(option)
	if index >= 0
		selected[index] = !selected[index]
		SetToggleOptionValue(option, selected[index], True)

		if selected[index]
			numSelected += 1
		else
			numSelected -= 1
		endif

		UpdateStackOptions()
	endif
EndEvent

Event OnOptionHighlight(int option)
	{Old-style highlight for handling highlighting of rows in the stack menu.}
	int index = stackToggleIDs.Find(option)
	if index >= 0
		string msg = Stack.items[index].GetName() + ".\n"

		if Stack.quantities[index] == 1
			msg += "$Single item.\n"
		else
			msg += "$Stack of " + Stack.quantities[index] + " $items.\n"
		endif

		if Stack.HasContainer(index)
			msg += "$From container."
			if QuickDropQuest.CanReplaceInContainer(index)
				msg += " $Can be replaced."
			else
				msg += " $Too far away to replace."
			endif

		elseif Stack.HasWorldLocation(index)
			msg += "$From world."
			if QuickDropQuest.CanReplaceInWorld(index)
				msg += " $Can be replaced."
			else
				msg += " $Too far away to replace."
			endif

		else
			msg += "$No location remembered."
		endif

		SetInfoText(msg)
	endif
EndEvent

Function DrawGeneralSettingsPage()
	{Draw the "General Settings" settings page.}
	AddHeaderOption("$Hotkeys")
	AddKeymapOptionST("ToggleRememberingHotkey", "$Toggle Remembering", QuickDropQuest.toggleRememberingHotkey)
	AddKeymapOptionST("ShowHotkey", "$Show Current Item", QuickDropQuest.showHotkey)
	AddKeymapOptionST("DropHotkey", "$Drop Current Item", QuickDropQuest.dropHotkey)
	AddKeymapOptionST("KeepHotkey", "$Keep Current Item", QuickDropQuest.keepHotkey)
	AddKeymapOptionST("DropAllHotkey", "$Drop All Items", QuickDropQuest.dropAllHotkey)
	AddKeymapOptionST("KeepAllHotkey", "$Keep All Items", QuickDropQuest.keepAllHotkey)
	SetCursorPosition(1)
	AddHeaderOption("$Settings")
	AddSliderOptionST("MaxRemembered", "$Items Remembered", Stack.size, "{0}")
	AddTextOptionST("ForgetOnRemoved", "$When Items Removed", ForgetOnRemovedBoolToString(QuickDropQuest.forgetOnRemoved))
	AddTextOptionST("ToggleRemembering", "$Remember New Items", ToggleRememberingStateToString())
	AddEmptyOption()
	AddHeaderOption("$Commands")
	AddTextOptionST("ClearAllLocations", "$Clear Remembered Location Data", "")
EndFunction

bool Function CheckKeyConflict(string conflictControl, string conflictName)
	{Check for OnKeyMapChange key conflicts and get user input.}
	if conflictControl != ""
		string msg = ""
		if conflictName != ""
			msg = "$This key is already mapped to " + conflictControl + " $from " + conflictName +".\n$Are you sure you want to continue?"
		else
			msg = "$This key is already mapped to " + conflictControl + " $from $Skyrim.\n$Are you sure you want to continue?"
		endif
		return ShowMessage(msg, True, "$Yes", "$No")
	endif
	return True
EndFunction

string Function GetCustomControl(int KeyCode)
	if KeyCode == QuickDropQuest.toggleRememberingHotkey
		return "$Toggle Remembering"
	elseif KeyCode == QuickDropQuest.showHotkey
		return "$Show Current Item"
	elseif KeyCode == QuickDropQuest.dropHotKey
		return "$Drop Current Item"
	elseif KeyCode == QuickDropQuest.keepHotKey
		return "$Keep Current Item"
	elseif KeyCode == QuickDropQuest.dropAllHotkey
		return "$Drop All Items"
	elseif KeyCode == QuickDropQuest.keepAllHotkey
		return "$Keep All Items"
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
		SetInfoText("$TOGGLE_REMEMBERING_HOTKEY_HIGHLIGHT_1 ($Currently " + ToggleRememberingStateToString() ".)$TOGGLE_REMEMBERING_HOTKEY_HIGHLIGHT_2")
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
		SetInfoText("$SHOW_HOTKEY_HIGHLIGHT")
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
		SetInfoText("$DROP_HOTKEY_HIGHLIGHT")
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
		SetInfoText("$KEEP_HOTKEY_HIGHLIGHT")
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
		SetInfoText("$DROP_ALL_HOTKEY_HIGHLIGHT")
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
		SetInfoText("$KEEP_ALL_HOTKEY_HIGHLIGHT")
	EndEvent
EndState

State MaxRemembered
	Event OnSliderOpenST()
		SetSliderDialogStartValue(Stack.size)
		SetSliderDialogDefaultValue(5.0)
		SetSliderDialogRange(1.0, 10.0)
		SetSliderDialogInterval(1.0)
	EndEvent

	Event OnSliderAcceptST(float value)
		Stack.SetSize(value as int)
		SetSliderOptionValueST(value, "{0}")
	EndEvent

	Event OnDefaultST()
		Stack.SetSize(5)
		SetSliderOptionValueSt(5.0, "{0}")
	EndEvent

	Event OnHighlightST()
		SetInfoText("$MAX_REMEMBERED_HIGHLIGHT")
	EndEvent
EndState

string Function ForgetOnRemovedBoolToString(bool value)
	if value
		return "$Forget First"
	else
		return "$Forget Last"
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
		SetInfoText("$FORGET_ON_REMOVED_HIGHLIGHT")
	EndEvent
EndState

string Function ToggleRememberingStateToString()
	if RememberScript.GetState() == "Enabled"
		return "$On"
	else
		return "$Off"
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
		SetInfoText("$TOGGLE_REMEMBERING_HIGHLIGHT")
	EndEvent
EndState

State ClearAllLocations
	Event OnSelectST()
		int i = Stack.top
		int iterations = 0
		While iterations < Stack.depth
			if Stack.HasWorldLocation(i)
				Stack.locations[i].Delete()
			endif
			Stack.locations[i] = None
			i = Stack.GetPreviousStackIndex(i)
			iterations += 1
		EndWhile

		if QuickDropQuest.locationXMarker != None
			QuickDropQuest.locationXMarker.Delete()
		endif
		QuickDropQuest.LocationXMarker = None

		QuickDropQuest.rememberContainer = False
		QuickDropQuest.replaceInContainer = False
		QuickDropQuest.rememberWorldLocation = False
		QuickDropQuest.replaceInWorld = False

		CrosshairScript.GoToState("Disabled")

		SetTextOptionValueST("$Done")
	EndEvent

	Event OnHighlightST()
		SetInfoText("$CLEAR_ALL_LOCATIONS_HIGHLIGHT")
	EndEvent
EndState

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
