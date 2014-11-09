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

bool Property notifyOnSkip = False Auto
{Whether or not to display a message when an item is skipped.}

int Property pickUpBehavior = 0 Auto
{How to handle multiple items. 0 = Remember All, 1 = Collapse All, 2 = Remember Each, 3 = Remember Only One.}

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

	Function RememberItems(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
		GoToState("Working")
		if akItemReference == None
			if pickUpBehavior == 0		;Remember the item and how many we picked up as a stack.
				int newCurrentIndex = IncrementCurrentIndex()
				RememberedItems[currentIndex] = akBaseItem
				RememberedQuantities[currentIndex] = aiItemCount
			elseif pickUpBehavior == 1	;Remember as a stack and combine with any other stacks of this item on top of the remembered items stack.
				;placeholder
			elseif pickUpBehavior == 2	;Remember as many individual instances of the item as we can.
				int i = 0
				While i < aiItemCount && i < maxRemembered
					int newCurrentIndex = IncrementCurrentIndex()
					RememberedItems[currentIndex] = akBaseItem
					RememberedQuantities[currentIndex] = 1
					i += 1
				EndWhile
			elseif pickUpBehavior == 3	;Remember only one instance of the item.
				int newCurrentIndex = IncrementCurrentIndex()
				RememberedItems[currentIndex] = akBaseItem
				RememberedQuantities[currentIndex] = 1
			endif
		elseif notifyOnSkip
			Debug.Notification("QuickDrop: " + akBaseItem.GetName() + " not remembered.")
		endif
		GoToState("Ready")
	EndFunction
EndState

State Working
	;Don't listen for keypresses or remember items while not Ready.
EndState

Function RememberItems(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	{Don't attempt to remember additional items while not Ready.}
EndFunction

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

int Function GetNextStackIndex(int index = -1)
	{Get the next stack index from the passed-in index, or from currentIndex if no index is passed.}
	if index == -1
		index = currentIndex
	endif
	index += 1
	if index >= maxRemembered
		return 0
	endif
	return index
EndFunction

int Function GetPreviousStackIndex(int index = -1)
	{Get the previous stack index from the passed-in index, or from currentIndex if no index is passed.}
	if index == -1
		index = currentIndex
	endif
	index -= 1
	if index < 0
		return maxRemembered - 1
	endif
	return index
EndFunction

int Function IncrementCurrentIndex()
	{Increment currentIndex, keeping it within the bounds set by maxRemembered.}
	currentIndex = GetNextStackIndex()
	return currentIndex
EndFunction

int Function DecrementCurrentIndex()
	{Decrement currentIndex, keeping it within the bounds set by maxRemembered.}
	currentIndex = GetPreviousStackIndex()
	return currentIndex
EndFunction

int Function CountRememberedItems()
	{Count the number of remembered item stack slots that are filled.}
	int i = currentIndex
	int iterations = 0
	int rememberedCount = 0

	While RememberedItems[i] != None && iterations < maxRemembered
		rememberedCount += 1
		i = GetPreviousStackIndex(i)
		iterations += 1
	EndWhile

	return rememberedCount
EndFunction

Function SwapIndexToTop(int index)
	{Move the item(s) at index to the top of the stack, pushing down the others.}
	Form itemToTop = RememberedItems[index]
	int quantityToTop = RememberedQuantities[index]

	While index != currentIndex
		int nextIndex = GetNextStackIndex(index)
		RememberedItems[index] = RememberedItems[nextIndex]
		RememberedQuantities[index] = RememberedQuantities[nextIndex]
		index = nextIndex
	EndWhile

	RememberedItems[currentIndex] = itemToTop
	RememberedQuantities[currentIndex] = quantityToTop
EndFunction

Function SwapIndices(int indexOne, int indexTwo)
	{Swap the item(s) at the given indices.}
	Form tempItem = RememberedItems[indexOne]
	RememberedItems[indexOne] = RememberedItems[indexTwo]
	RememberedItems[indexTwo] = tempItem

	int tempQuantity = RememberedQuantities[indexOne]
	RememberedQuantities[indexOne] = RememberedQuantities[indexTwo]
	RememberedQuantities[indexTwo] = tempQuantity
EndFunction

Function AlignAndResizeStack(int newStackSize = -1)
	{Align the stack with the arrays, so that the bottom item on the stack is at the array's 0 index. Optionally re-size the stack.}
	if RememberedItems[currentIndex] == None	;If the stack is empty.
		currentIndex = 9							;Reset currentIndex so the next item remembered is at 0.
	else										;If we have at least one item remembered.
		Form[] newItems = new Form[10]				;Build new, aligned stack arrays.
		int[] newQuantities = new int[10]

		int i = 0
		While i < 10
			newItems[i] = None
			newQuantities[i] = 0
			i += 1
		EndWhile

		if newStackSize < 1	;If no argument was passed, keep the stack the same size.
			newStackSize = maxRemembered
		endif

		int rememberedCount = CountRememberedItems()	;Count the number of items we currently have remembered.
		if rememberedCount >= newStackSize	;If the currently remembered items match or overflow the stack size.
			i = newStackSize - 1			;Then we start our stack at the highest allowed position.
		else								;If the currently remembered items don't fill the new limit.
			i = rememberedCount - 1				;Then we start our stack as high as needed to accomodate all items.
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

		if currentIndex < 0	;Special case: the stack was aligned while it contained 10 items, and so contains no None.
			currentIndex = 9
		endif
	endif
EndFunction

Function AdjustMaxRemembered(int newMaxRemembered)
	{Set a new maxRemembered. Thin wrapper around AlignAndResizeStack.}
	if newMaxRemembered != maxRemembered	;If the size of the stack is actually changing.
		AlignAndResizeStack(newMaxRemembered)
		maxRemembered = newMaxRemembered
	endif
EndFunction
