Scriptname QuickDropQuestScript extends Quest
{QuickDrop main script.}

QuickDropPlayerForgetScript Property ForgetScript Auto
{The player script responsible for handling OnItemRemoved.}

QuickDropPlayerRememberScript Property RememberScript Auto
{The player script responsible for handling OnItemAdded.}

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

Message Property QuickDropRememberingOn Auto
{Message displayed when remembering is toggled on.}

Message Property QuickDropRememberingOff Auto
{Message displayed when remembering is toggled off.}

int Property dropHotkey = -1 Auto
{Drop the last remembered item(s).}

int Property showHotkey = -1 Auto
{Show the last remembered item(s).}

int Property keepHotkey = -1 Auto
{Keep the last remembered item(s).}

int Property dropAllHotkey = -1 Auto
{Drop all remembered items.}

int Property keepAllHotkey = -1 Auto
{Keep all remembered items.}

int Property toggleRememberingHotkey = -1 Auto
{Toggle remembering.}

int Property maxRemembered = 5 Auto
{The number of items to remember.}

bool Property notifyOnDrop = False Auto
{Whether or not to display a notification when an item is dropped.}

bool Property notifyOnKeep = True Auto
{Whether or not to display a notification when an item is kept.}

bool Property notifyOnSkip = False Auto
{Whether or not to display a message when an item is skipped.}

bool Property rememberPersistent = False Auto
{Whether or not to remember (and therefore be able to drop) items with persistent references, like quest items.}

int Property pickUpBehavior = 0 Auto
{How to handle multiple items. 0 = Remember All, 1 = Collapse All, 2 = Remember Each, 3 = Remember Only One.}

bool Property forgetOnRemoved = True Auto
{How to forget items when removed separately. True = Forget first, False = Forget last.}
;Forget first means treat any items removed from the inventory as the most recent ones picked up. They're removed from the remembered
;items stack from the top down, even if there are enough left in the inventory to remember.
;Forget last means treat any items removed from the inventory as the least recent ones picked up. They're removed from the remembered
;items stack from the bottom up, starting only when there aren't enough left in the inventory to remember.

;Remember the index of the current item.
;Start it at 9 so that the first call to IncrementCurrentIndex sets it back to 0.
int Property currentIndex = 9 Auto
{The index in RememberedItems of the last item picked up.}

FormList Property QuickDropDuplicateItems Auto
{Keep a list of items that are duplicated in the stack for use with Remember to One Stack Slot.}

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
			elseif KeyCode == toggleRememberingHotkey
				HandleToggleRememberingHotkey()
			endif
			GoToState("Ready")
		endif
	EndEvent

	Function RememberItems(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
		GoToState("Working")
		if akItemReference == None
			if pickUpBehavior == 0		;Remember the item and how many we picked up as a stack.
				RememberNewItem(akBaseItem, aiItemCount)

			elseif pickUpBehavior == 1	;Remember as a stack and combine with any other stacks of this item on top of the remembered items stack.
				int existingItemIndex

				if QuickDropDuplicateItems.HasForm(akBaseItem)	;If this type of item currently occupies two or more slots in the stack.
					int[] indices = FindAllInstancesInStack(akBaseItem)	;Get a list of the stack slots occupied by this item.
					SwapIndexToTop(indices[0])	;Swap the first instance of this item to the top of the stack.

					int i = 1
					While i < indices.Length && indices[i] >= 0
						RememberedQuantities[currentIndex] = RememberedQuantities[currentIndex] + RememberedQuantities[indices[i]]
						RemoveIndexFromStack(indices[i])
						i += 1
					EndWhile

					QuickDropDuplicateItems.RemoveAddedForm(akBaseItem)	;Remove this item from the list of duplicates.
					existingItemIndex = currentIndex	;Record that this item is now on the top of the stack.
				else	;If this item occupies one or no slots in the stack.
					existingItemIndex = RememberedItems.Find(akBaseItem)	;Search for this item in the stack.
				endif

				if existingItemIndex < 0	;If we don't already have this item in the stack.
					RememberNewItem(akBaseItem, aiItemCount)	;Add it to the top.
				else						;If we do have this item in the stack somewhere.
					SwapIndexToTop(existingItemIndex)			;Move it to the top and add the number we just picked up.
					RememberedQuantities[currentIndex] = RememberedQuantities[currentIndex] + aiItemCount
				endif

			elseif pickUpBehavior == 2	;Remember as many individual instances of the item as we can.
				int i = 0
				While i < aiItemCount && i < maxRemembered
					RememberNewItem(akBaseItem, 1)
					i += 1
				EndWhile

			elseif pickUpBehavior == 3	;Remember only one instance of the item.
				RememberNewItem(akBaseItem, 1)

			endif

		elseif notifyOnSkip
			Debug.Notification("QuickDrop: " + akBaseItem.GetName() + " not remembered.")
		endif
		GoToState("Ready")
	EndFunction

	Function ForgetItems(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
		GoToState("Working")

		int[] indices = FindAllInstancesInStack(akBaseItem)

		if indices[0] >= 0	;If some of this item are remembered.
			int numToForget = aiItemCount

			if forgetOnRemoved	;If we're forgetting picked-up items first.
				int i = 0	;Start with the top stack index.
				While i < indices.Length && indices[i] >= 0 && numToForget > 0
					if numToForget >= RememberedQuantities[indices[i]]	;If this slot doesn't have enough to satisfy numToForget, or has just enough.
						numToForget -= RememberedQuantities[indices[i]]
						RemoveIndexFromStack(indices[i])	;Remove this slot. It was removed from the top, so remaining indices are still valid.
					elseif numToForget < RememberedQuantities[indices[i]]	;If this slot does have enough to satsify numToForget.
						RememberedQuantities[indices[i]] = RememberedQuantities[indices[i]] - numToForget	;Remove numToForget items from this slot.
						numToForget = 0
					endif
					i += 1
				EndWhile

			else	;If we're forgetting picked-up items last.
				int totalRemembered = 0
				int i = 0
				While i < indices.Length && indices[i] >= 0
					totalRemembered += RememberedQuantities[indices[i]]
					i += 1
				EndWhile

				if PlayerRef.GetItemCount(akBaseItem) < totalRemembered	;If we don't have enough of this item left to remember.
					i -= 1	;Start with the bottom stack index.
					While i >= 0 && numToForget > 0
						if numToForget >= RememberedQuantities[indices[i]]	;If this slot doesn't have enough to satisfy numToForget, or has just enough.
							numToForget -= RememberedQuantities[indices[i]]
							RemoveIndexFromStack(indices[i])	;Remove this slot.
							int j = i - 1	;This slot was removed from the bottom, so adjust our remaining stack indices, because they've all shifted down 1.
							While j >= 0
								indices[j] = GetPreviousStackIndex(indices[j])
								j -= 1
							EndWhile
						elseif numToForget < RememberedQuantities[indices[i]]	;If this slot does have enough to satisfy numToForget.
							RememberedQuantities[indices[i]] = RememberedQuantities[indices[i]] - numToForget	;Remove numToForget items from this slot.
							numToForget = 0
						endif
						i -= 1
					EndWhile
				endif
			endif
		endif
		GoToState("Ready")
	EndFunction

	Function AdjustMaxRemembered(int newMaxRemembered)
		{Set a new maxRemembered. Thin wrapper around AlignAndResizeStack.}
		if newMaxRemembered != maxRemembered	;If the size of the stack is actually changing.
			GoToState("Working")
			AlignAndResizeStack(newMaxRemembered)
			maxRemembered = newMaxRemembered
			GoToState("Ready")
		endif
	EndFunction

	Function AdjustPickUpBehavior(int newPickUpBehavior)
		{Set a new pickUpBehavior. Perform necessary maintenance.}
		if newPickUpBehavior != pickUpBehavior	;If pickUpBehavior is actually changing.
			GoToState("Working")

			if newPickUpBehavior == 1	;If we're changing to Remember to One Stack Slot.
				int i = 0					;Remember all duplicate items so we can collapse them on next pickup.
				While i < RememberedItems.Length - 1	;Search through the second-to-last array index.
					if RememberedItems[i] != None && RememberedItems.Find(RememberedItems[i], i + 1) >= 0 && !QuickDropDuplicateItems.HasForm(RememberedItems[i])
						QuickDropDuplicateItems.AddForm(RememberedItems[i])
					endif
					i += 1
				EndWhile

			elseif pickUpBehavior == 1	;If we're changing from Remember to One Stack Slot.
				QuickDropDuplicateItems.Revert()		;Forget duplicate items, if any.
			endif

			pickUpBehavior = newPickUpBehavior

			GoToState("Ready")
		endif
	EndFunction
EndState

State Working
	;Thread lock when state-altering actions are taking place.
EndState

Function RememberItems(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	{Don't attempt to remember additional items while not Ready.}
EndFunction

Function ForgetItems(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	{Don't attempt to forget additional items while not Ready.}
EndFunction

Function AdjustMaxRemembered(int newMaxRemembered)
	{Don't adjust maxRemembered while not Ready.}
EndFunction

Function AdjustPickUpBehavior(int newPickUpBehavior)
	{Don't adjust pickUpBehavior while not Ready.}
EndFunction

Event OnInit()
	{Perform script setup.}
	RememberedItems = new Form[10]
	RememberedQuantities = new int[10]
	int i = 0
	While i < RememberedItems.Length
		RememberedItems[i] = None
		RememberedQuantities[i] = 0
		i += 1
	EndWhile
EndEvent

Function RememberNewItem(Form itemToRemember, int quantityToRemember)
	{Push a new item and quantity onto the stack.}
	IncrementCurrentIndex()
	RememberedItems[currentIndex] = itemToRemember
	RememberedQuantities[currentIndex] = quantityToRemember
EndFunction

Function HandleDropHotkey()
	{Drop the current item and move to the next.}
	if RememberedItems[currentIndex] != None
		if notifyOnDrop
			Debug.Notification("QuickDrop: " + RememberedItems[currentIndex].GetName() + " (" + RememberedQuantities[currentIndex] + ") dropped.")
		endif
		ForgetScript.GoToState("Disabled")	;Don't receive an OnItemRemoved for this event.
		PlayerRef.DropObject(RememberedItems[currentIndex], RememberedQuantities[currentIndex])
		ForgetScript.GoToState("Enabled")
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
		ForgetScript.GoToState("Disabled")	;Don't receive OnItemRemoved for these event.
		While i < RememberedItems.Length
			if RememberedItems[i] != None
				PlayerRef.DropObject(RememberedItems[i], RememberedQuantities[i])
				RememberedItems[i] = None
			endif
			i += 1
		EndWhile
		ForgetScript.GoToState("Enabled")
		currentIndex = RememberedItems.Length - 1	;Reset to last index so the next call to IncrementCurrentIndex returns 0.
	else
		QuickDropNoItemsRemembered.Show()
	endif
EndFunction

Function HandleKeepAllHotkey()
	{Keep all remembered items.}
	if RememberedItems[currentIndex] != None
		if notifyOnKeep
			QuickDropAllItemsKept.Show()
		endif
		int i = 0
		While i < RememberedItems.Length
			RememberedItems[i] = None
			i += 1
		EndWhile
		currentIndex = RememberedItems.Length - 1	;Reset to last index so the next call to IncrementCurrentIndex returns 0.
	else
		QuickDropNoItemsRemembered.Show()
	endif
EndFunction

Function HandleToggleRememberingHotkey()
	{Enable the remember script and display the appropriate message.}
	if RememberScript.GetState() == "Enabled"
		RememberScript.GoToState("Disabled")
		QuickDropRememberingOff.Show()
	else
		RememberScript.GoToState("Enabled")
		QuickDropRememberingOn.Show()
	endif
EndFunction

int Function GetNextStackIndex(int index = -1)
	{Get the next stack index from the passed-in index, or from currentIndex if no index is passed.}
	if index < 0
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
	if index < 0
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

int[] Function FindAllInstancesInStack(Form searchFor)
	{Starting from currentIndex, find all stack indices occupied by searchFor. Return as an int array populated with indices, terminated by -1 if not full.}
	int[] results = new int[10]
	int resultsIndex = 0

	;Mock a do-while structure.
	if RememberedItems[currentIndex] == searchFor
		results[resultsIndex] = currentIndex
		resultsIndex += 1
	endif

	int i = GetPreviousStackIndex(currentIndex)
	While i != currentIndex && RememberedItems[i] != None
		if RememberedItems[i] == searchFor
			results[resultsIndex] = i
			resultsIndex += 1
		endif
		i = GetPreviousStackIndex(i)
	EndWhile

	if resultsIndex < results.Length	;If we haven't filled the results array.
		results[resultsIndex] = -1		;Terminate it with -1.
	endif

	return results
EndFunction

Function SwapIndexToTop(int index)
	{Move the item(s) at index to the top of the stack, pushing down the others.}
	if index != currentIndex	;No-op if this index is already the top of the stack.
		Form itemToTop = RememberedItems[index]
		int quantityToTop = RememberedQuantities[index]

		RemoveIndexFromStack(index)
		RememberNewItem(itemToTop, quantityToTop)
	endif
EndFunction

Function RemoveIndexFromStack(int index)
	{Remove the item(s) at index from the stack, shifting others down into its place. Doesn't check if index is within stack bounds - make sure to verify this!}
	While index != currentIndex		;Shift stack down, overwriting this index.
		int nextIndex = GetNextStackIndex(index)
		RememberedItems[index] = RememberedItems[nextIndex]
		RememberedQuantities[index] = RememberedQuantities[nextIndex]
		index = nextIndex
	EndWhile
	RememberedItems[currentIndex] = None	;Clear the top item of the stack.
	DecrementCurrentIndex()
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
		currentIndex = RememberedItems.Length - 1	;Reset currentIndex so the next item remembered is at 0.
	else 	;If we have at least one item remembered.
		Form[] newItems = new Form[10]				;Build new, aligned stack arrays.
		int[] newQuantities = new int[10]

		int i = 0
		While i < newItems.Length
			newItems[i] = None
			newQuantities[i] = 0
			i += 1
		EndWhile

		if newStackSize < 1	;If no argument was passed, keep the stack the same size.
			newStackSize = maxRemembered
		endif

		int rememberedCount = CountRememberedItems()	;Count the number of items we currently have remembered.
		if rememberedCount >= newStackSize	;If the currently remembered items match or overflow the stack size.
			i = newStackSize - 1				;Then we start our stack at the highest allowed position.
		else								;If the currently remembered items don't fill the new limit.
			i = rememberedCount - 1				;Then we start our stack as high as needed to accomodate all items.
		endif
		int newCurrentIndex = i

		While i >= 0
			newItems[i] = RememberedItems[currentIndex]
			newQuantities[i] = RememberedQuantities[currentIndex]
			DecrementCurrentIndex()
			i -= 1
		EndWhile

		RememberedItems = newItems
		RememberedQuantities = newQuantities
		currentIndex = newCurrentIndex
	endif
EndFunction
