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
{The currently persisted XMarker. This marker moves to every item the player focuses on, and is "committed" to locations on item pick up, if appropriate.}

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

int Property toggleRememberingHotkey = -1 Auto
{Toggle remembering.}

int Property showHotkey = -1 Auto
{Show the last remembered item(s).}

int Property dropHotkey = -1 Auto
{Drop the last remembered item(s).}

int Property keepHotkey = -1 Auto
{Keep the last remembered item(s).}

int Property dropAllHotkey = -1 Auto
{Drop all remembered items.}

int Property keepAllHotkey = -1 Auto
{Keep all remembered items.}

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

State Working
	;Thread lock when state-altering actions are taking place.
EndState

Function RememberItems(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	{Don't attempt to remember additional items while not Ready.}
EndFunction

Function ForgetItems(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	{Don't attempt to forget additional items while not Ready.}
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

		if rememberPersistent || akItemReference == None
			;Determine what location data, if any, we will remember.
			ObjectReference locationToRemember = None
			if akSourceContainer != None && (rememberContainer || replaceInContainer)	;If we have a container and are remembering containers.
				locationToRemember = akSourceContainer

			elseif akSourceContainer == None && (rememberWorldLocation || replaceInWorld)	;If we don't have a container and are remembering world locations.
				locationToRemember = locationXMarker
				locationXMarker = None	;Clear our reference to locationXMarker, so that a new XMarker is created on next CrosshairRefChange.
			endif

			if pickUpBehavior == 0		;Remember the item and how many we picked up as a stack.
				HandleRememberAll(akBaseItem, aiItemCount, locationToRemember)
			elseif pickUpBehavior == 1	;Remember as a stack and combine with any other stacks of this item on top of the remembered items stack.
				HandleCollapseAll(akBaseItem, aiItemCount, locationToRemember)
			elseif pickUpBehavior == 2	;Remember as many individual instances of the item as we can.
				HandleRememberEach(akBaseItem, aiItemCount, locationToRemember)
			elseif pickUpBehavior == 3	;Remember only some instances of the item.
				HandleRememberSome(akBaseItem, aiItemCount, locationToRemember)
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
		{When items are dropped outside of QuickDrop, forget them from the stack.}
		GoToState("Working")

		if forgetOnRemoved	;If we're forgetting picked-up items first.
			int numToForget = aiItemCount

			int i = Stack.Find(akBaseItem)
			While i >= 0 && numToForget > 0
				if numToForget >= Stack.quantities[i]		;If this slot doesn't have enough to satisfy numToForget, or has just enough.
					numToForget -= Stack.quantities[i]
					Stack.Remove(i)								;Remove this stack slot.
					i = Stack.Find(akBaseItem, Stack.GetPreviousStackIndex(i))	;Search down the stack for the next instance starting from the slot beneath i.

				else 										;If this slot does have enough to satsify numToForget.
					Stack.quantities[i] = Stack.quantities[i] - numToForget	;Remove numToForget items from this slot.
					numToForget = 0
				endif
			EndWhile

		else				;If we're forgetting picked-up items last.
			int totalRemembered = 0
			int i = Stack.Find(akBaseItem)
			While i >= 0
				totalRemembered += Stack.quantities[i]

				i = Stack.GetPreviousStackIndex(i)
				if i != Stack.top	;Only search so long as we haven't reached the bottom of the stack.
					i = Stack.Find(akBaseItem, i)
				else
					i = -1
				endif
			EndWhile

			int numToForget = totalRemembered - PlayerRef.GetItemCount(akBaseItem)

			i = Stack.Rfind(akBaseItem)
			While i >= 0 && numToForget > 0
				if numToForget >= Stack.quantities[i]	;If this slot doesn't have enough to satisfy numToForget, or has just enough.
					numToForget -= Stack.quantities[i]
					Stack.Remove(i)							;Remove this stack slot.
					i = Stack.Rfind(akBaseItem, i)			;Because we're searching up the stack, and a new stack slot has been pulled down into this place, we want to search from i.

				else									;If this slot does have enough to satisfy numToForget.
					Stack.quantities[i] = Stack.quantities[i] - numToForget	;Remove numToForget items from this slot.
					numToForget = 0
				endif
			EndWhile
		endif

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

Function HandleShowHotkey()
	{Display the current item.}
	if Stack.depth
		Debug.Notification("QuickDrop: Current: " + Stack.items[Stack.top].GetName() + " (" + Stack.quantities[Stack.top] + ").")
	else
		QuickDropNoItemsRemembered.Show()
	endif
EndFunction

<<<<<<< HEAD
Function HandleDropHotkey()
	{Drop the current item and move to the next.}
	if Stack.depth
		ForgetScript.GoToState("Disabled")	;Don't receive an OnItemRemoved when this item is dropped.

		if replaceInContainer && Stack.HasContainer()	;We're replacing items in containers and have a container to replace to.
			if CanReplaceInContainer()
				if notifyOnReplaceInContainer
					Debug.Notification("QuickDrop: " + Stack.items[Stack.top].GetName() + " (" + Stack.quantities[Stack.top] + ") replaced in container.")
				endif

				PlayerRef.RemoveItem(Stack.items[Stack.top], Stack.quantities[Stack.top], True, Stack.locations[Stack.top])
				Stack.Pop()

			else
				if notifyOnFailToReplaceInContainer
					Debug.Notification("QuickDrop: " + Stack.items[Stack.top].GetName() + " (" + Stack.quantities[Stack.top] + ") could not be replaced in container.")
				endif

				if replaceInContainerDropOnFail
					if notifyOnDrop
						Debug.Notification("QuickDrop: " + Stack.items[Stack.top].GetName() + " (" + Stack.quantities[Stack.top] + ") dropped.")
					endif

					PlayerRef.DropObject(Stack.items[Stack.top], Stack.quantities[Stack.top])
					Stack.Pop()
				endif
			endif

		elseif replaceInWorld && Stack.HasWorldLocation()	;We're replacing items in the world and have an XMarker to replace to.
			if CanReplaceInWorld()
				if notifyOnReplaceInWorld
					Debug.Notification("QuickDrop: " + Stack.items[Stack.top].GetName() + " (" + Stack.quantities[Stack.top] + ") replaced in world.")
				endif

				PlayerRef.DropObject(Stack.items[Stack.top], Stack.quantities[Stack.top]).MoveTo(Stack.locations[Stack.top])
				Stack.Pop()

			else
				if notifyOnFailToReplaceInWorld
					Debug.Notification("QuickDrop: " + Stack.items[Stack.top].GetName() + " (" + Stack.quantities[Stack.top] + ") could not be replaced in world.")
				endif

				if replaceInWorldDropOnFail
					if notifyOnDrop
						Debug.Notification("QuickDrop: " + Stack.items[Stack.top].GetName() + " (" + Stack.quantities[Stack.top] + ") dropped.")
					endif

					PlayerRef.DropObject(Stack.items[Stack.top], Stack.quantities[Stack.top])
					Stack.Pop()
				endif
			endif

		else	;We're not replacing items or don't have a place to replace this item to.
			if notifyOnDrop
				Debug.Notification("QuickDrop: " + Stack.items[Stack.top].GetName() + " (" + Stack.quantities[Stack.top] + ") dropped.")
			endif

			PlayerRef.DropObject(Stack.items[Stack.top], Stack.quantities[Stack.top])
			Stack.Pop()

		endif

		ForgetScript.GoToState("Enabled")

	else
		QuickDropNoItemsRemembered.Show()
	endif
EndFunction

Function HandleKeepHotkey()
	{Keep the current item and move to the next.}
	if Stack.depth
		if notifyOnKeep
			Debug.Notification("QuickDrop: " + Stack.items[Stack.top].GetName() + " (" + Stack.quantities[Stack.top] + ") kept.")
		endif

		Stack.Pop()
	else
		QuickDropNoItemsRemembered.Show()
	endif
EndFunction

Function HandleDropAllHotkey()
	{Drop/replace all remembered items. Operates as if we're attempting a drop/replace on each individual item.}
	if stack.depth
		ForgetScript.GoToState("Disabled")	;Don't receive OnItemRemoved when these items are dropped.

		int notify = 0	;What type of notification to display for this action.
		int i = Stack.top
		int iterations = 0
		int terminate = Stack.depth	;Stop after this many iterations.

		While iterations < terminate
			if replaceInContainer && Stack.HasContainer(i) ;We're replacing items in containers and have a container to replace to.
				if CanReplaceInContainer()
					if notifyOnReplaceInContainer && notify < 2
						notify = 1
					endif

					PlayerRef.RemoveItem(Stack.items[i], Stack.quantities[i], True, Stack.locations[i])
					Stack.Remove(i)

				else
					if replaceInContainerDropOnFail
						if notifyOnDrop && notify < 2
							notify = 1
						endif

						PlayerRef.DropObject(Stack.items[i], Stack.quantities[i])
						Stack.Remove(i)

					elseif notifyOnFailToReplaceInContainer	;Special-case notification: some items couldn't be dropped/replaced.
						notify = 2

					endif
				endif

			elseif replaceInWorld && Stack.HasWorldLocation(i)	;We're replacing items in the world and have an XMarker to replace to.
				if CanReplaceInWorld()
					if notifyOnReplaceInWorld && notify < 2
						notify = 1
					endif

					PlayerRef.DropObject(Stack.items[i], Stack.quantities[i]).MoveTo(Stack.locations[i])
					Stack.Remove(i)

				else
					if replaceInWorldDropOnFail
						if notifyOnDrop && notify < 2
							notify = 1
						endif

						PlayerRef.DropObject(Stack.items[i], Stack.quantities[i])
						Stack.Remove(i)

					elseif notifyOnFailToReplaceInWorld	;Special-case notification: some items couldn't be dropped/replaced.
						notify = 2

					endif
				endif

			else	;We're not replacing items or don't have a place to replace this item to.
				if notifyOnDrop && notify < 2
					notify = 1
				endif

				PlayerRef.DropObject(Stack.items[i], Stack.quantities[i])
				Stack.Remove(i)

			endif

			iterations += 1
			if indices == None
				i = GetPreviousStackIndex(i)
			else
				i = indices[iterations]
			endif
		EndWhile

		ForgetScript.GoToState("Enabled")

		if notify == 1
			QuickDropAllItemsDropped.Show()
		elseif notify == 2
			QuickDropSomeItemsNotDropped.Show()
		endif

		if !Stack.depth	;If we succeeded in clearing the entire stack.
			Stack.Align()
		endif

	else
		QuickDropNoItemsRemembered.Show()

	endif
EndFunction

Function HandleKeepAllHotkey()
	{Keep all remembered items.}
	if Stack.depth
		if notifyOnKeep
			QuickDropAllItemsKept.Show()
		endif

		While Stack.depth
			Stack.Pop()
		EndWhile

		Stack.Align()

	else
		QuickDropNoItemsRemembered.Show()
	endif
EndFunction

Function HandleRememberAll(Form itemToRemember, int quantityToRemember, ObjectReference locationToRemember)
	{Remember the stack of items picked up to one stack slot, or in multiple stacks according to the modifier.}
	int i = 0

	if pickUpBehaviorModifier[0]
		While quantityToRemember > pickUpBehaviorModifier[0] && i < Stack.size
			Stack.Push(itemToRemember, pickUpBehaviorModifier[0], locationToRemember)
			quantityToRemember -= pickUpBehaviorModifier[0]
			i += 1
		EndWhile
	endif

	if quantityToRemember && i < Stack.size
		Stack.Push(itemToRemember, quantityToRemember, locationToRemember)
	endif
EndFunction

Function HandleCollapseAll(Form itemToRemember, int quantityToRemember, ObjectReference locationToRemember)
	{Remember the stack of items picked up in a combined stack slot of this type, up to the amount allowed by the modifier.}
	int existingItemIndex

	if Stack.HasDuplicate(itemToRemember)	;If this type of item currently occupies two or more slots in the stack.
		int i = Stack.Find(itemToRemember)
		Stack.MoveToTop(i)	;Move the first instance of this item to the top of the stack.

		i = Stack.Find(itemToRemember, Stack.GetPreviousStackIndex(i))
		While i >= 0 && i != Stack.top
			Stack.quantities[Stack.top] = Stack.quantities[Stack.top] + Stack.quantities[i]
			Stack.Remove(i)
			i = Stack.Find(itemToRemember, Stack.GetPreviousStackIndex(i))
		EndWhile

		Stack.locations[Stack.top] = None	;Clear any replacement data, as it's no longer valid.

		if pickUpBehaviorModifier[1] && Stack.quantities[Stack.top] > pickUpBehaviorModifier[1]	;If we have more remembered than we're allowed, forget some.
			Stack.quantities[Stack.top] = pickUpBehaviorModifier[1]
		endif

		Stack.RemoveDuplicate(itemToRemember)	;Remove this item from the list of duplicates.
		existingItemIndex = currentIndex	;Record that this item is now on the top of the stack.

	else	;If this item occupies one or no slots in the stack.
		existingItemIndex = items.Find(itemToRemember)	;Search for this item in the stack.
	endif

	if existingItemIndex < 0	;If we don't already have this item in the stack.
		;Remember replacement data until we combine stack slots, as it will be valid until then.
		if !pickUpBehaviorModifier[1] || quantityToRemember <= pickUpBehaviorModifier[1]
			Stack.Push(itemToRemember, quantityToRemember, locationToRemember)
		else
			Stack.Push(itemToRemember, pickUpBehaviorModifier[1], locationToRemember)
		endif

	else						;If we do have this item in the stack somewhere.
		Stack.MoveToTop(existingItemIndex)			;Move it to the top and add the number we just picked up.
		if !pickUpBehaviorModifier[1] || Stack.quantities[Stack.top] + quantityToRemember <= pickUpBehaviorModifier[1]
			Stack.quantities[Stack.top] = Stack.quantities[Stack.top] + quantityToRemember
		else
			Stack.quantities[Stack.top] = pickUpBehaviorModifier[1]
		endif
		Stack.locations[Stack.top] = None	;Clear any replacement data, as it's no longer valid.
	endif
EndFunction

Function HandleRememberEach(Form itemToRemember, int quantityToRemember, ObjectReference locationToRemember)
	{Remember the items individually, up to the amount allowed by the modifier.}
	if pickUpBehaviorModifier[2] && pickUpBehaviorModifier[2] < quantityToRemember
		quantityToRemember = pickUpBehaviorModifier[2]
	endif

	int i = 0
	While i < quantityToRemember && i < Stack.size
		Stack.Push(itemToRemember, 1, locationToRemember)
		i += 1
	EndWhile
EndFunction

Function HandleRememberSome(Form itemToRemember, int quantityToRemember, ObjectReference locationToRemember)
	{Remember in one stack slot some of these items, as allowed by the modifier.}
	if quantityToRemember > pickUpBehaviorModifier[3]
		Stack.Push(itemToRemember, pickUpBehaviorModifier[3], locationToRemember)
	else
		Stack.Push(itemToRemember, quantityToRemember, locationToRemember)
	endif
EndFunction

bool Function CanReplaceInContainer()
	{Determines whether the top stack item can currently be replaced in its container.}
	if Stack.HasContainer() && (!replaceInContainerDistance || PlayerRef.GetDistance(Stack.locations[Stack.top]) <= replaceInContainerDistance)
		return True
	endif
	return False
EndFunction

bool Function CanReplaceInWorld()
	{Determines whether the top stack item can currently be replaced in its original world location.}
	if Stack.HasWorldLocation() && (!replaceInWorldDistance || PlayerRef.GetDistance(Stack.locations[Stack.top]) <= replaceInWorldDistance)
		return True
	endif
	return False
EndFunction
