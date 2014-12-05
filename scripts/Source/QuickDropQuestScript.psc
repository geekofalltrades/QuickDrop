Scriptname QuickDropQuestScript extends Quest
{QuickDrop main script.}

QuickDropPlayerForgetScript Property ForgetScript Auto
{The player script responsible for handling OnItemRemoved.}

QuickDropPlayerRememberScript Property RememberScript Auto
{The player script responsible for handling OnItemAdded.}

QuickDropPlayerCrosshairScript Property CrosshairScript Auto
{The player script responsible for tracking OnCrosshairRefChanged events.}

QuickDropStackScript Property Stack Auto
{The QuickDrop stack.}

Actor Property PlayerRef Auto
{Player reference.}

Static Property XMarker Auto
{An XMarker, for use in marking world replace locations.}

ObjectReference Property locationXMarker Auto
{The currently persisted XMarker. This marker moves to every item the player focuses on, and is "committed" to RememberedLocations on item pick up, if appropriate.}

Message Property QuickDropNoItemsRemembered Auto
{Message displayed when no more items are remembered.}

Message Property QuickDropAllItemsDropped Auto
{Message displayed when all items are dropped.}

Message Property QuickDropSomeItemsNotDropped Auto
{Message displayed when the Drop All Hotkey fails to drop some items.}

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

bool Property forgetOnRemoved = True Auto
{How to forget items when removed separately. True = Forget first, False = Forget last.}
;Forget first means treat any items removed from the inventory as the most recent ones picked up. They're removed from the remembered
;items stack from the top down, even if there are enough left in the inventory to remember.
;Forget last means treat any items removed from the inventory as the least recent ones picked up. They're removed from the remembered
;items stack from the bottom up, starting only when there aren't enough left in the inventory to remember.

bool Property rememberPersistent = False Auto
{Whether or not to remember (and therefore be able to drop) items with persistent references, like quest items.}

bool Property notifyOnPersistent = False Auto
{Whether or not to display a message when an item is skipped.}

bool Property notifyOnDrop = False Auto
{Whether or not to display a notification when an item is dropped.}

bool Property notifyOnReplaceInContainer = True Auto
{Whether or not to display a notification when an item is replaced in its original container.}

bool Property notifyOnFailToReplaceInContainer = False Auto
{Whether or not to display a notification when an item can't be replaced in its original container.}

bool Property notifyOnReplaceInWorld = False Auto
{Whether or not to display a notification when an item is replaced in its original world location.}

bool Property notifyOnFailToReplaceInWorld = False Auto
{Whether or not to display a notification when an item can't be replaced in its original world location.}

bool Property notifyOnKeep = True Auto
{Whether or not to display a notification when an item is kept.}

int Property pickUpBehavior = 0 Auto
{How to handle multiple items. 0 = Remember All, 1 = Collapse All, 2 = Remember Each, 3 = Remember Some.}

int[] Property pickUpBehaviorModifier Auto
{Modifier for pickUpBehavior. Contains one value for each of the four possible pickUpBehavior settings.}
;The modifier for 0 (Remember All) tells QuickDrop how many items to put in one stack before overflowing into a new stack.
;The modifier for 1 (Collapse All) tells QuickDrop how many items to put in the shared stack slot, maximum.
;The modifier for 2 (Remember Each) tells QuickDrop how many items to remember individually, maximum.
;The modifier for 3 (Remember Some) tells QuickDrop how many items to remember in one slot before putting the rest into inventory.

bool Property replaceInContainer = False Auto
{Whether or not to replace items in their original containers.}

int Property replaceInContainerDistance = 250 Auto
{The distance at which you're allowed to replace items in containers.}

bool Property replaceInContainerDropOnFail = True Auto
{Whether or not to drop an item if it can't be replaced in its container.}

bool Property rememberContainer = True Auto
{Whether or not to remember containers items come from. Implied by replaceInContainer.}

bool Property replaceInWorld = False Auto
{Whether or not to replace items in their original world locations.}

int Property replaceInWorldDistance = 250 Auto
{The distance at which you're allowed to replace items at their world locations.}

bool Property replaceInWorldDropOnFail = True Auto
{Whether or not to drop an item if it can't be replaced in its world location.}

bool Property rememberWorldLocation = True Auto
{Whether or not to remember items' world locations. Implied by replaceInWorld.}

Event OnInit()
	{Perform script setup.}
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
				Debug.Notification("QuickDrop: Remembered persistent " + akBaseItem.GetName() + ".")
			endif

		elseif notifyOnPersistent
			Debug.Notification("QuickDrop: Persistent " + akBaseItem.GetName() + " not remembered.")
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
		GoToState("Working")
		Stack.SetSize(newMaxRemembered)
		GoToState("Ready")
	EndFunction

	Function AdjustPickUpBehavior(int newPickUpBehavior)
		{Set a new pickUpBehavior. Perform necessary maintenance.}
		if newPickUpBehavior != pickUpBehavior	;If pickUpBehavior is actually changing.
			GoToState("Working")

			if newPickUpBehavior == 1	;If we're changing to Remember to One Stack Slot.
				Stack.RecordDuplicates()	;Record duplicate items so we can collapse them on next pickup.
			elseif pickUpBehavior == 1	;If we're changing from Remember to One Stack Slot.
				Stack.ClearDuplicates()		;Forget duplicate items, if any.
			endif

			pickUpBehavior = newPickUpBehavior

			GoToState("Ready")
		endif
	EndFunction

	Function ToggleReplaceInWorld()
		{Toggle replaceInWorld and put the crosshair script in the appropriate state.}
		GoToState("Working")

		replaceInWorld = !replaceInWorld

		if replaceInWorld || rememberWorldLocation
			CrosshairScript.GoToState("Enabled")
		else
			CrosshairScript.GoToState("Disabled")
		endif

		GoToState("Ready")
	EndFunction

	Function ToggleRememberWorldLocation()
		{Toggle rememberWorldLocation and put the crosshair script in the appropriate state.}
		GoToState("Working")

		rememberWorldLocation = !rememberWorldLocation

		if replaceInWorld || rememberWorldLocation
			CrosshairScript.GoToState("Enabled")
		else
			CrosshairScript.GoToState("Disabled")
		endif

		GoToState("Ready")
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

Function ToggleReplaceInWorld()
	{Don't toggle replaceInWorld while not Ready.}
EndFunction

Function ToggleRememberWorldLocation()
	{Don't toggle rememberWorldLocation while not Ready.}
EndFunction

Function HandleDropHotkey()
	{Drop the current item and move to the next.}
	if !Stack.Empty()
		ForgetScript.GoToState("Disabled")	;Don't receive an OnItemRemoved when this item is dropped.

		if replaceInContainer && Stack.RememberedLocations[Stack.top] != None && Stack.RememberedLocations[Stack.top].GetBaseObject() != XMarker	;We're replacing items in containers and have a container to replace to.
			if CanReplaceInContainer()
				if notifyOnReplaceInContainer
					Debug.Notification("QuickDrop: " + Stack.RememberedItems[Stack.top].GetName() + " (" + Stack.RememberedQuantities[Stack.top] + ") replaced in container.")
				endif

				PlayerRef.RemoveItem(Stack.RememberedItems[Stack.top], Stack.RememberedQuantities[Stack.top], True, Stack.RememberedLocations[Stack.top])
				RemoveIndexFromStack()

			else
				if notifyOnFailToReplaceInContainer
					Debug.Notification("QuickDrop: " + Stack.RememberedItems[Stack.top].GetName() + " (" + Stack.RememberedQuantities[Stack.top] + ") could not be replaced in container.")
				endif

				if replaceInContainerDropOnFail
					if notifyOnDrop
						Debug.Notification("QuickDrop: " + Stack.RememberedItems[Stack.top].GetName() + " (" + Stack.RememberedQuantities[Stack.top] + ") dropped.")
					endif

					PlayerRef.DropObject(Stack.RememberedItems[Stack.top], Stack.RememberedQuantities[Stack.top])
					RemoveIndexFromStack()
				endif
			endif

		elseif replaceInWorld && Stack.RememberedLocations[Stack.top] != None && Stack.RememberedLocations[Stack.top].GetBaseObject() == XMarker	;We're replacing items in the world and have an XMarker to replace to.
			if CanReplaceInWorld()
				if notifyOnReplaceInWorld
					Debug.Notification("QuickDrop: " + Stack.RememberedItems[Stack.top].GetName() + " (" + Stack.RememberedQuantities[Stack.top] + ") replaced in world.")
				endif

				PlayerRef.DropObject(Stack.RememberedItems[Stack.top], Stack.RememberedQuantities[Stack.top]).MoveTo(Stack.RememberedLocations[Stack.top])
				RemoveIndexFromStack()

			else
				if notifyOnFailToReplaceInWorld
					Debug.Notification("QuickDrop: " + Stack.RememberedItems[Stack.top].GetName() + " (" + Stack.RememberedQuantities[Stack.top] + ") could not be replaced in world.")
				endif

				if replaceInWorldDropOnFail
					if notifyOnDrop
						Debug.Notification("QuickDrop: " + Stack.RememberedItems[Stack.top].GetName() + " (" + Stack.RememberedQuantities[Stack.top] + ") dropped.")
					endif

					PlayerRef.DropObject(Stack.RememberedItems[Stack.top], Stack.RememberedQuantities[Stack.top])
					RemoveIndexFromStack()
				endif
			endif

		else	;We're not replacing items or don't have a place to replace this item to.
			if notifyOnDrop
				Debug.Notification("QuickDrop: " + Stack.RememberedItems[Stack.top].GetName() + " (" + Stack.RememberedQuantities[Stack.top] + ") dropped.")
			endif

			PlayerRef.DropObject(Stack.RememberedItems[Stack.top], Stack.RememberedQuantities[Stack.top])
			RemoveIndexFromStack()

		endif

		ForgetScript.GoToState("Enabled")

	else
		QuickDropNoItemsRemembered.Show()
	endif
EndFunction

Function HandleShowHotkey()
	{Display the current item.}
	if Stack.RememberedItems[Stack.top] != None
		Debug.Notification("QuickDrop: Current: " + Stack.RememberedItems[Stack.top].GetName() + " (" + Stack.RememberedQuantities[Stack.top] + ").")
	else
		QuickDropNoItemsRemembered.Show()
	endif
EndFunction

Function HandleKeepHotkey()
	{Keep the current item and move to the next.}
	if Stack.RememberedItems[Stack.top] != None
		if notifyOnKeep
			Debug.Notification("QuickDrop: " + Stack.RememberedItems[Stack.top].GetName() + " (" + Stack.RememberedQuantities[Stack.top] + ") kept.")
		endif

		RemoveIndexFromStack(currentIndex)
	else
		QuickDropNoItemsRemembered.Show()
	endif
EndFunction

Function HandleDropAllHotkey()
	{Drop/replace all remembered items. Operates as if we're attempting a drop/replace on each individual item.}
	if Stack.RememberedItems[Stack.top] != None
		ForgetScript.GoToState("Disabled")	;Don't receive OnItemRemoved when these items are dropped.

		int notify = 0	;What type of notification to display for this action.
		int i = currentIndex
		int iterations = 0
		int terminate = CountRememberedItems()	;Stop after this many iterations.

		While iterations < terminate
			if replaceInContainer && RememberedLocations[i] != None	&& RememberedLocations[i].GetBaseObject() != XMarker ;We're replacing items in containers and have a container to replace to.
				if CanReplaceInContainer()
					if notifyOnReplaceInContainer && notify < 2
						notify = 1
					endif

					PlayerRef.RemoveItem(RememberedItems[i], RememberedQuantities[i], True, RememberedLocations[i])
					RemoveIndexFromStack(i)

				else
					if replaceInContainerDropOnFail
						if notifyOnDrop && notify < 2
							notify = 1
						endif

						PlayerRef.DropObject(RememberedItems[i], RememberedQuantities[i])
						RemoveIndexFromStack(i)

					elseif notifyOnFailToReplaceInContainer	;Special-case notification: some items couldn't be dropped/replaced.
						notify = 2

					endif
				endif

			elseif replaceInWorld && RememberedLocations[i] != None && RememberedLocations[i].GetBaseObject() == XMarker	;We're replacing items in the world and have an XMarker to replace to.
				if CanReplaceInWorld()
					if notifyOnReplaceInWorld && notify < 2
						notify = 1
					endif

					PlayerRef.DropObject(RememberedItems[i], RememberedQuantities[i]).MoveTo(RememberedLocations[i])
					RemoveIndexFromStack()

				else
					if replaceInWorldDropOnFail
						if notifyOnDrop && notify < 2
							notify = 1
						endif

						PlayerRef.DropObject(RememberedItems[i], RememberedQuantities[i])
						RemoveIndexFromStack()

					elseif notifyOnFailToReplaceInWorld	;Special-case notification: some items couldn't be dropped/replaced.
						notify = 2

					endif
				endif

			else	;We're not replacing items or don't have a place to replace this item to.
				if notifyOnDrop && notify < 2
					notify = 1
				endif

				PlayerRef.DropObject(RememberedItems[i], RememberedQuantities[i])
				RemoveIndexFromStack(i)

			endif

			i = GetPreviousStackIndex(i)
			iterations += 1
		EndWhile

		ForgetScript.GoToState("Enabled")

		if notify == 1
			QuickDropAllItemsDropped.Show()
		elseif notify == 2
			QuickDropSomeItemsNotDropped.Show()
		endif

		if Stack.RememberedItems[Stack.top] == None	;If we succeeded in clearing the entire stack.
			currentIndex = RememberedItems.Length - 1	;Reset to last index so the next call to IncrementCurrentIndex returns 0.
		endif

	else
		QuickDropNoItemsRemembered.Show()

	endif
EndFunction

Function HandleKeepAllHotkey()
	{Keep all remembered items.}
	if Stack.RememberedItems[Stack.top] != None
		if notifyOnKeep
			QuickDropAllItemsKept.Show()
		endif

		While Stack.RememberedItems[Stack.top] != None
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
			Stack.RememberedQuantities[Stack.top] = Stack.RememberedQuantities[Stack.top] + RememberedQuantities[indices[i]]
			RemoveIndexFromStack(indices[i])
			i += 1
		EndWhile

		Stack.RememberedLocations[Stack.top] = None	;Clear any replacement data, as it's no longer valid.

		if pickUpBehaviorModifier[1] && Stack.RememberedQuantities[Stack.top] > pickUpBehaviorModifier[1]	;If we have more remembered than we're allowed, forget some.
			Stack.RememberedQuantities[Stack.top] = pickUpBehaviorModifier[1]
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
		if !pickUpBehaviorModifier[1] || Stack.RememberedQuantities[Stack.top] + quantityToRemember <= pickUpBehaviorModifier[1]
			Stack.RememberedQuantities[Stack.top] = Stack.RememberedQuantities[Stack.top] + quantityToRemember
		else
			Stack.RememberedQuantities[Stack.top] = pickUpBehaviorModifier[1]
		endif
		Stack.RememberedLocations[Stack.top] = None	;Clear any replacement data, as it's no longer valid.
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
	Stack.Push(itemToRemember, quantityToRemember, GetLocationRef(containerToRemember))
EndFunction

ObjectReference Function GetLocationRef(ObjectReference containerRef)
	{Return the appropriate world location or container reference to remember, if either.}
	if containerRef != None && (rememberContainer || replaceInContainer)	;If we have a container and are remembering containers.
		return containerRef

	elseif containerRef == None && (rememberWorldLocation || replaceInWorld)	;If we don't have a container and are remembering world locations.
		ObjectReference toReturn = locationXMarker
		locationXMarker = None	;Clear our reference to locationXMarker, so that a new XMarker is created on next CrosshairRefChange.
		return toReturn

	endif

	return None	;Otherwise, don't remember any location data.
EndFunction

bool Function CanReplaceInContainer(int index = -1)
	{Determines whether the item at index can currently be replaced in its container.}
	if index < 0
		index = currentIndex
	endif

	if RememberedLocations[index] != None && RememberedLocations[index].GetBaseObject() != XMarker && (!replaceInContainerDistance || PlayerRef.GetDistance(RememberedLocations[index]) <= replaceInContainerDistance)
		return True
	endif

	return False
EndFunction

bool Function CanReplaceInWorld(int index = -1)
	{Determines whether the item at index can currently be replaced in its original world location.}
	if index < 0
		index = currentIndex
	endif

	if RememberedLocations[index] != None && RememberedLocations[index].GetBaseObject() == XMarker && (!replaceInWorldDistance || PlayerRef.GetDistance(RememberedLocations[index]) <= replaceInWorldDistance)
		return True
	endif

	return False
EndFunction
