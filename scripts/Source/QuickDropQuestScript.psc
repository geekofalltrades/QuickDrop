Scriptname QuickDropQuestScript extends Quest
{QuickDrop main script.}

Actor Property PlayerRef Auto
{Player reference.}

Form[] Property RememberedItems Auto
{Remembered items, stored on the quest.}

int[] Property RememberedQuantities Auto
{The quantity of the corresponding RememberedItem remembered.}

Message Property QuickDropNoItemsRemembered Auto
{Message displayed when no more items are remembered.}

Message Property QuickDropAllItemsDropped Auto
{Message displayed when all items are dropped.}

Message Property QuickDropAllItemsKept Auto
{Message displayed when all items are kept.}

;User input.
int Property dropHotkey = -1 Auto
int Property showHotkey = -1 Auto
int Property keepHotkey = -1 Auto
int Property dropAllHotkey = -1 Auto
int Property keepAllHotkey = -1 Auto
int Property maxRemembered = 5 Auto
bool Property notifyOnDrop = False Auto
bool Property notifyOnKeep = False Auto

;Remember the index of the current item.
;Start it at 9 so that the first call to IncrementCurrentIndex sets it back to 0.
int Property currentIndex = 9 Auto
{The index in RememberedItems of the last item picked up.}

Auto State Ready
	Event OnKeyDown(int KeyCode)
		{Map key presses to their respective hotkey actions.}
		if !Utility.IsInMenuMode()	;Try to disable hotkeys when menus are open.
			GoToState("Working")
			if KeyCode == dropHotkey
				HandleDropHotkey()
			elseif KeyCode == showHotkey
				HandleShowHotkey()
			elseif KeyCode == keepHotkey
				HandleKeepHotkey()
			elseif KeyCode == dropAllHotkey
				HandleDropAllHotkey()
			elseif KeyCode == keepAllHotkey
				HandleKeepAllHotkey()
			endif
			GoToState("Ready")
		endif
	EndEvent
EndState

State Working
	Event OnKeyDown(int KeyCode)
		{Don't listen for additional keypresses while working.}
	EndEvent
EndState

Event OnInit()
	{Perform script setup.}
	RememberedItems = new Form[10]
	RememberedQuantities = new int[10]
	int i = 0
	While i < 10
		RememberedItems[i] = None
		RememberedQuantities[i] = 0
		i += 1
	EndWhile
EndEvent

Function HandleDropHotkey()
	{Drop the current item and move to the next.}
	if RememberedItems[currentIndex] != None
		if notifyOnDrop
			Debug.Notification("QuickDrop: " + RememberedItems[currentIndex].GetName() + " (" + RememberedQuantities[currentIndex] + ") dropped.")
		endif
		PlayerRef.DropObject(RememberedItems[currentIndex], RememberedQuantities[currentIndex])
		RememberedItems[currentIndex] = None
		DecrementCurrentIndex()
	else
		QuickDropNoItemsRemembered.Show()
	endif
EndFunction

Function HandleShowHotkey()
	{Display the current item.}
	if RememberedItems[currentIndex] != None
		Debug.Notification("QuickDrop: Current: " + RememberedItems[currentIndex].GetName() + " (" + RememberedQuantities[currentIndex] + ").")
	else
		QuickDropNoItemsRemembered.Show()
	endif
EndFunction

Function HandleKeepHotkey()
	{Keep the current item and move to the next.}
	if RememberedItems[currentIndex] != None
		if notifyOnKeep
			Debug.Notification("QuickDrop: " + RememberedItems[currentIndex].GetName() + " (" + RememberedQuantities[currentIndex] + ") kept.")
		endif
		RememberedItems[currentIndex] = None
		DecrementCurrentIndex()
	else
		QuickDropNoItemsRemembered.Show()
	endif
EndFunction

Function HandleDropAllHotkey()
	{Drop all remembered items.}
	if RememberedItems[currentIndex] != None
		if notifyOnDrop
			QuickDropAllItemsDropped.Show()
		endif
		int i = 0
		While i < 10
			if RememberedItems[i] != None
				PlayerRef.DropObject(RememberedItems[i], RememberedQuantities[i])
				RememberedItems[i] = None
			endif
			i += 1
		EndWhile
		currentIndex = 9	;Reset to 9 so the next call to IncrementCurrentIndex returns 0.
	else
		QuickDropNoItemsRemembered.Show()
	endif
EndFunction

Function HandleKeepAllHotkey()
	{Drop all remembered items.}
	if RememberedItems[currentIndex] != None
		if notifyOnKeep
			QuickDropAllItemsKept.Show()
		endif
		int i = 0
		While i < 10
			RememberedItems[i] = None
			i += 1
		EndWhile
		currentIndex = 9	;Reset to 9 so the next call to IncrementCurrentIndex returns 0.
	else
		QuickDropNoItemsRemembered.Show()
	endif
EndFunction

int Function IncrementCurrentIndex()
	{Increment currentIndex, keeping it within the bounds set by maxRemembered.}
	currentIndex += 1
	if currentIndex >= maxRemembered
		currentIndex = 0
	endif
	return currentIndex
EndFunction

int Function DecrementCurrentIndex()
	{Decrement currentIndex, keeping it within the bounds set by maxRemembered.}
	currentIndex -= 1
	if currentIndex < 0
		currentIndex = maxRemembered - 1
	endif
	return currentIndex
EndFunction

Function AdjustMaxRemembered(int newMaxRemembered)
	{Aligns the remembered item stack with the beginning of the arrays and sets a new maxRemembered.}
	if RememberedItems[currentIndex] != None	;If we have at least one item remembered.
		Form[] newItems = new Form[10]
		int[] newQuantities = new int[10]

		int i = 0	;Initialize our new remembered items arrays.
		While i < 10
			newItems[i] = None
			newQuantities[i] = 0
			i += 1
		EndWhile

		i = 0
		int rememberedCount = 0	;Count the number of items we currently have remembered.
		While i < 10
			if RememberedItems[i] != None
				rememberedCount += 1
			endif
			i += 1
		EndWhile

		if rememberedCount >= newMaxRemembered	;If the currently remembered items match or overflow the new limit.
			i = newMaxRemembered - 1				;Then we start our stack at the highest allowed position.
		else							;If the currently remembered items don't fill the new limit.
			i = rememberedCount - 1			;Then we start our stack at the position matching the last element remembered.
		endif

		While i >= 0
			newItems[i] = RememberedItems[currentIndex]
			newQuantities[i] = RememberedQuantities[currentIndex]
			DecrementCurrentIndex()
			i -= 1
		EndWhile

		RememberedItems = newItems
		RememberedQuantities = newQuantities
		currentIndex = RememberedItems.Find(None) - 1
	else	;If no items are remembered.
		currentIndex = 9	;Reset to 9 so the next call to IncrementCurrentIndex returns 0.
	endif
	maxRemembered = newMaxRemembered
EndFunction