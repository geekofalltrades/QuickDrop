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

ObjectReference[] Property RememberedContainers Auto
{The container the corresponding item came from, or None if from the world or container not remembered.}

FormList Property QuickDropDuplicateItems Auto
{Keep a list of items that are duplicated in the stack for use with Remember to One Stack Slot.}

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

bool Property notifyOnPersistent = False Auto
{Whether or not to display a message when an item is skipped.}

bool Property rememberPersistent = False Auto
{Whether or not to remember (and therefore be able to drop) items with persistent references, like quest items.}

bool Property replaceInContainer = False Auto
{Whether or not to replace items in their original containers.}

bool Property rememberContainer = False Auto
{Whether or not to remember containers items come from. Implied by replaceInContainer.}

int Property pickUpBehavior = 0 Auto
{How to handle multiple items. 0 = Remember All, 1 = Collapse All, 2 = Remember Each, 3 = Remember Some.}

int[] Property pickUpBehaviorModifier Auto
{Modifier for pickUpBehavior. Contains one value for each of the four possible pickUpBehavior settings.}
;The modifier for 0 (Remember All) tells QuickDrop how many items to put in one stack before overflowing into a new stack.
;The modifier for 1 (Collapse All) tells QuickDrop how many items to put in the shared stack slot, maximum.
;The modifier for 2 (Remember Each) tells QuickDrop how many items to remember individually, maximum.
;The modifier for 3 (Remember Some) tells QuickDrop how many items to remember in one slot before putting the rest into inventory.

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

Event OnInit()
	{Perform script setup.}
	RememberedItems = new Form[10]
	RememberedQuantities = new int[10]
	RememberedContainers = new ObjectReference[10]

	int i = 0
	While i < RememberedItems.Length
		RememberedItems[i] = None
		RememberedQuantities[i] = 0
		RememberedContainers[i] = None
		i += 1
	EndWhile

	pickUpBehaviorModifier = new int[4]
	pickUpBehaviorModifier[0] = 0
	pickUpBehaviorModifier[1] = 0
	pickUpBehaviorModifier[2] = 0
	pickUpBehaviorModifier[3] = 1
EndEvent

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
		if akItemReference == None || rememberPersistent
			if pickUpBehavior == 0		;Remember the item and how many we picked up as a stack.
				HandleRememberAll(akBaseItem, aiItemCount, akSourceContainer)
			elseif pickUpBehavior == 1	;Remember as a stack and combine with any other stacks of this item on top of the remembered items stack.
				HandleCollapseAll(akBaseItem, aiItemCount, akSourceContainer)
			elseif pickUpBehavior == 2	;Remember as many individual instances of the item as we can.
				HandleRememberEach(akBaseItem, aiItemCount, akSourceContainer)
			elseif pickUpBehavior == 3	;Remember only some instances of the item.
				HandleRememberSome(akBaseItem, aiItemCount, akSourceContainer)
			endif

			if notifyOnPersistent && akItemReference != None
				if rememberPersistent
					Debug.Notification("QuickDrop: Remembered persistent " + akBaseItem.GetName() + ".")
				else
					Debug.Notification("QuickDrop: Persistent " + akBaseItem.GetName() + " not remembered.")
				endif
			endif
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

Function HandleDropHotkey()
	{Drop the current item and move to the next.}
	if RememberedItems[currentIndex] != None
		if notifyOnDrop
			Debug.Notification("QuickDrop: " + RememberedItems[currentIndex].GetName() + " (" + RememberedQuantities[currentIndex] + ") dropped.")
		endif

		ForgetScript.GoToState("Disabled")	;Don't receive an OnItemRemoved for this event.
		DropRememberedItem()
		ForgetScript.GoToState("Enabled")

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

		RemoveIndexFromStack(currentIndex)
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

		ForgetScript.GoToState("Disabled")	;Don't receive OnItemRemoved for these events.
		While RememberedItems[currentIndex] != None
			DropRememberedItem()
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

		While RememberedItems[currentIndex] != None
			RemoveIndexFromStack(currentIndex)
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

Function HandleRememberAll(Form itemToRemember, int quantityToRemember, ObjectReference containerToRemember)
	{Remember the stack of items picked up to one stack slot, or in multiple stacks according to the modifier.}
	int i = 0

	if pickUpBehaviorModifier[0]
		While quantityToRemember > pickUpBehaviorModifier[0] && i < maxRemembered
			RememberNewItem(itemToRemember, pickUpBehaviorModifier[0], containerToRemember)
			quantityToRemember -= pickUpBehaviorModifier[0]
			i += 1
		EndWhile
	endif

	if quantityToRemember && i < maxRemembered
		RememberNewItem(itemToRemember, quantityToRemember, containerToRemember)
	endif
EndFunction

Function HandleCollapseAll(Form itemToRemember, int quantityToRemember, ObjectReference containerToRemember)
	{Remember the stack of items picked up in a combined stack slot of this type, up to the amount allowed by the modifier.}
	int existingItemIndex

	if QuickDropDuplicateItems.HasForm(itemToRemember)	;If this type of item currently occupies two or more slots in the stack.
		int[] indices = FindAllInstancesInStack(itemToRemember)	;Get a list of the stack slots occupied by this item.
		SwapIndexToTop(indices[0])	;Swap the first instance of this item to the top of the stack.

		int i = 1
		While i < indices.Length && indices[i] >= 0	;Add all other slots to the first one.
			RememberedQuantities[currentIndex] = RememberedQuantities[currentIndex] + RememberedQuantities[indices[i]]
			RemoveIndexFromStack(indices[i])
			i += 1
		EndWhile

		RememberedContainers[currentIndex] = None	;Clear any replacement data, as it's no longer valid.

		if pickUpBehaviorModifier[1] && RememberedQuantities[currentIndex] > pickUpBehaviorModifier[1]	;If we have more remembered than we're allowed, forget some.
			RememberedQuantities[currentIndex] = pickUpBehaviorModifier[1]
		endif

		QuickDropDuplicateItems.RemoveAddedForm(itemToRemember)	;Remove this item from the list of duplicates.
		existingItemIndex = currentIndex	;Record that this item is now on the top of the stack.
	else	;If this item occupies one or no slots in the stack.
		existingItemIndex = RememberedItems.Find(itemToRemember)	;Search for this item in the stack.
	endif

	if existingItemIndex < 0	;If we don't already have this item in the stack.
		;Remember replacement data until we combine stack slots, as it will be valid until then.
		if !pickUpBehaviorModifier[1] || quantityToRemember <= pickUpBehaviorModifier[1]
			RememberNewItem(itemToRemember, quantityToRemember, containerToRemember)
		else
			RememberNewItem(itemToRemember, pickUpBehaviorModifier[1], containerToRemember)
		endif
	else						;If we do have this item in the stack somewhere.
		SwapIndexToTop(existingItemIndex)			;Move it to the top and add the number we just picked up.
		if !pickUpBehaviorModifier[1] || RememberedQuantities[currentIndex] + quantityToRemember <= pickUpBehaviorModifier[1]
			RememberedQuantities[currentIndex] = RememberedQuantities[currentIndex] + quantityToRemember
		else
			RememberedQuantities[currentIndex] = pickUpBehaviorModifier[1]
		endif
		RememberedContainers[currentIndex] = None	;Clear any replacement data, as it's no longer valid.
	endif
EndFunction

Function HandleRememberEach(Form itemToRemember, int quantityToRemember, ObjectReference containerToRemember)
	{Remember the items individually, up to the amount allowed by the modifier.}
	if pickUpBehaviorModifier[2] && pickUpBehaviorModifier[2] < quantityToRemember
		quantityToRemember = pickUpBehaviorModifier[2]
	endif

	int i = 0
	While i < quantityToRemember && i < maxRemembered
		RememberNewItem(itemToRemember, 1, containerToRemember)
		i += 1
	EndWhile
EndFunction

Function HandleRememberSome(Form itemToRemember, int quantityToRemember, ObjectReference containerToRemember)
	{Remember in one stack some of these items, as allowed by the modifier.}
	RememberNewItem(itemToRemember, pickUpBehaviorModifier[3], containerToRemember)
EndFunction

Function RememberNewItem(Form itemToRemember, int quantityToRemember, ObjectReference containerToRemember)
	{Push a new item onto the stack.}
	IncrementCurrentIndex()
	RememberedItems[currentIndex] = itemToRemember
	RememberedQuantities[currentIndex] = quantityToRemember
	if rememberContainer || replaceInContainer
		RememberedContainers[currentIndex] = containerToRemember
	else
		RememberedContainers[currentIndex] = None
	endif
EndFunction

Function DropRememberedItem(int index = -1)
	{Pop an item off the stack and drop/replace it. Take care to properly manipulate the states of ForgetScript before calling this function.}
	if index == -1
		index = currentIndex
	endif

	if replaceInContainer && RememberedContainers[index] != None
		PlayerRef.RemoveItem(RememberedItems[index], RememberedQuantities[index], True, RememberedContainers[index])
	else
		PlayerRef.DropObject(RememberedItems[index], RememberedQuantities[index])
	endif

	RemoveIndexFromStack(index)
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
		ObjectReference containerToTop = RememberedContainers[index]

		RemoveIndexFromStack(index)
		RememberNewItem(itemToTop, quantityToTop, containerToTop)
	endif
EndFunction

Function RemoveIndexFromStack(int index)
	{Remove the item(s) at index from the stack, shifting others down into its place. Doesn't check if index is within stack bounds - make sure to verify this!}
	While index != currentIndex		;Shift stack down, overwriting this index.
		int nextIndex = GetNextStackIndex(index)
		RememberedItems[index] = RememberedItems[nextIndex]
		RememberedQuantities[index] = RememberedQuantities[nextIndex]
		RememberedContainers[index] = RememberedContainers[nextIndex]
		index = nextIndex
	EndWhile
	RememberedItems[currentIndex] = None	;Clear the top item of the stack.
	RememberedContainers[currentIndex] = None
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

	ObjectReference tempContainer = RememberedContainers[indexOne]
	RememberedContainers[indexOne] = RememberedContainers[indexTwo]
	RememberedContainers[indexTwo] = tempContainer
EndFunction

Function AlignAndResizeStack(int newStackSize = -1)
	{Align the stack with the arrays, so that the bottom item on the stack is at the array's 0 index. Optionally re-size the stack.}
	if RememberedItems[currentIndex] == None	;If the stack is empty.
		currentIndex = RememberedItems.Length - 1	;Reset currentIndex so the next item remembered is at 0.
	else 	;If we have at least one item remembered.
		Form[] newItems = new Form[10]				;Build new, aligned stack arrays.
		int[] newQuantities = new int[10]
		ObjectReference[] newContainers = new ObjectReference[10]

		int i = 0
		While i < newItems.Length
			newItems[i] = None
			newQuantities[i] = 0
			newContainers[i] = None
			i += 1
		EndWhile

		if newStackSize < 1	;If no argument was passed, keep the stack the same size.
			newStackSize = maxRemembered
		endif

		int rememberedCount = CountRememberedItems()	;Count the number of slots we currently have filled.
		if rememberedCount >= newStackSize	;If the currently occupied slots match or overflow the stack size.
			i = newStackSize - 1				;Then we start our stack at the highest allowed position.
		else								;If the currently occupied slots don't fill the new limit.
			i = rememberedCount - 1				;Then we start our stack as high as needed to accomodate all slots.
		endif
		int newCurrentIndex = i

		While i >= 0
			newItems[i] = RememberedItems[currentIndex]
			newQuantities[i] = RememberedQuantities[currentIndex]
			newContainers[i] = RememberedContainers[currentIndex]
			DecrementCurrentIndex()
			i -= 1
		EndWhile

		RememberedItems = newItems
		RememberedQuantities = newQuantities
		RememberedContainers = newContainers
		currentIndex = newCurrentIndex
	endif
EndFunction
