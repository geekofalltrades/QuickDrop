Scriptname QuickDropStackScript extends ReferenceAlias
{QuickDrop stack script. This reusable data structure stores a stack of Forms, integer quantities, and ObjectReference locations.}

;Because Papyrus limits us to statically sized arrays, a true stack (of
;unlimited size) is not possible. A stack of limited size that always
;starts at index 0 would be grossly inefficient, because, if the stack
;were full, an array shift of all items would need to be performed every
;time something was pushed. Instead, QuickDrop essentially treats its
;arrays as if they were circular. When the last index in the array is
;reached, the top loops back around to the beginning of the
;array and begins overwriting items from the bottom up. If items are
;popped at the bottom of the array, the stack top loops around to the array
;top and begins popping items from the top down. This stack implementation
;requires careful tracking, but doesn't ever require that the stack array
;be shifted (so long as it is used like a stack, which it often isn't -
;we can, and do, access, move, and remove items that aren't at the top
;of the stack).

;This stack is most easily maintained when all of its items are
;consecutive in the arrays. This does not imply that there can't be empty
;space on either or both sides of the remembered items. If the stack
;loops around and begins overwriting the bottom items in the array,
;then several items are popped off, we can reach a state where there is
;a consecutive block of remembered items in the middle of the arrays, with
;empty space on either side. In order to keep all items in the stack
;consecutive in the arrays, the stack is realigned with the arrays whenever
;its size changes.

Form[] Property RememberedItems Auto
{Remembered items.}

int[] Property RememberedQuantities Auto
{The quantity of the corresponding RememberedItem remembered.}

ObjectReference[] Property RememberedLocations Auto
{The world location or container the corresponding RememberedItem came from, or None if no location data is remembered.}

;Remember the index representing the top of the stack.
;Start it at 9 so that the first call to Push sets it back to 0.
int Property top = 9 Auto
{The index representing the top of the stack.}

int Property size = 5 Auto
{The size of the stack.}

FormList Property DuplicateItems Auto
{A FormList containing items that are duplicated in this stack.}

Static Property XMarker Auto
{An XMarker, of the type used to mark world locations. Needed in this script for comparison operations.}

Event OnInit()
	{Perform script setup.}
	RememberedItems = new Form[10]
	RememberedQuantities = new int[10]
	RememberedLocations = new ObjectReference[10]

	int i = 0
	While i < RememberedItems.Length
		RememberedItems[i] = None
		RememberedQuantities[i] = 0
		RememberedLocations[i] = None
		i += 1
	EndWhile
EndEvent

State Working
	;Disallow access by other threads when state-altering actions are
	;taking place. The following empty prototypes are all state-altering
	;methods of the stack that must be thread-locked.
EndState

Function Push(Form itemToRemember, int quantityToRemember, ObjectReference locationToRemember)
	{Disallow pushing while not Ready.}
EndFunction

Function Pop()
	{Disallow popping while not Ready.}
EndFunction

Function Remove(int index)
	{Disallow removing while not Ready.}
EndFunction

Function SetSize(int newSize)
	{Don't adjust the size of the stack while not Ready.}
EndFunction

Function RecordDuplicates()
	{Don't record duplicate items while not Ready.}
EndFunction

Function ClearDuplicates()
	{Don't clear duplicate items while not Ready.}
EndFunction

Auto State Ready
	;In Ready state, state-altering entry points into the stack are available to callers.

	Function Push(Form itemToRemember, int quantityToRemember, ObjectReference locationToRemember)
		{Push a new item onto the stack.}
		GoToState("Working")

		top = GetNextStackIndex()
		RememberedItems[top] = itemToRemember
		RememberedQuantities[top] = quantityToRemember
		RememberedLocations[top] = locationToRemember

		GoToState("Ready")
	EndFunction

	Function Pop()
		{Pop an item from the stack. The item is not returned.}
		GoToState("Working")

		;If we have world location data stored at the top index.
		if RememberedLocations[index] != None && RememberedLocations[index].GetBaseObject() == XMarker
			RememberedLocations[index].Delete()	;Mark the XMarker for deletion.
		endif

		RememberedItems[top] = None
		RememberedLocations[top] = None
		top = GetPreviousStackIndex()

		GoToState("Ready")
	EndFunction

	Function Remove(int index)
		{Remove an item from the stack. Shift others down into its place. Doesn't check if index is within stack bounds. The item removed is not returned.}
		GoToState("Working")

		;If we have world location data stored at the index being removed.
		if RememberedLocations[index] != None && RememberedLocations[index].GetBaseObject() == XMarker
			RememberedLocations[index].Delete()	;Mark the XMarker for deletion.
		endif

		;Shift stack down, overwriting this index.
		While index != top
			int nextIndex = GetNextStackIndex(index)
			RememberedItems[index] = RememberedItems[nextIndex]
			RememberedQuantities[index] = RememberedQuantities[nextIndex]
			RememberedLocations[index] = RememberedLocations[nextIndex]
			index = nextIndex
		EndWhile

		;Clear the top item of the stack.
		RememberedItems[top] = None
		RememberedLocations[top] = None
		top = GetPreviousStackIndex()

		GoToState("Ready")
	EndFunction

	Function SetSize(int newSize)
		{Set a new size. Thin wrapper around AlignAndResizeStack.}
		if newMaxRemembered != size    ;If the size of the stack is actually changing.
			GoToState("Working")

			AlignAndResizeStack(newSize)
			size = newSize

			GoToState("Ready")
		endif
	EndFunction

	Function RecordDuplicates()
		{Record duplicated items in the duplicates FormList.}
	EndFunction
EndState

Function HandleRememberAll(Form itemToRemember, int quantityToRemember, ObjectReference containerToRemember)
	{Remember the stack of items picked up to one stack slot, or in multiple stacks according to the modifier.}
	int i = 0

	if pickUpBehaviorModifier[0]
		While quantityToRemember > pickUpBehaviorModifier[0] && i < size
			RememberNewItem(itemToRemember, pickUpBehaviorModifier[0], containerToRemember)
			quantityToRemember -= pickUpBehaviorModifier[0]
			i += 1
		EndWhile
	endif

	if quantityToRemember && i < size
		RememberNewItem(itemToRemember, quantityToRemember, containerToRemember)
	endif
EndFunction

Function HandleCollapseAll(Form itemToRemember, int quantityToRemember, ObjectReference containerToRemember)
	{Remember the stack of items picked up in a combined stack slot of this type, up to the amount allowed by the modifier.}
	int existingItemIndex

	if QuickDropDuplicateItems.HasForm(itemToRemember)  ;If this type of item currently occupies two or more slots in the stack.
		int[] indices = FindAllInstancesInStack(itemToRemember) ;Get a list of the stack slots occupied by this item.
		SwapIndexToTop(indices[0])  ;Swap the first instance of this item to the top of the stack.

		int i = 1
		While i < indices.Length && indices[i] >= 0 ;Add all other slots to the first one.
			RememberedQuantities[top] = RememberedQuantities[top] + RememberedQuantities[indices[i]]
			RemoveIndexFromStack(indices[i])
			i += 1
		EndWhile

		RememberedLocations[top] = None    ;Clear any replacement data, as it's no longer valid.

		if pickUpBehaviorModifier[1] && RememberedQuantities[top] > pickUpBehaviorModifier[1]  ;If we have more remembered than we're allowed, forget some.
			RememberedQuantities[top] = pickUpBehaviorModifier[1]
		endif

		QuickDropDuplicateItems.RemoveAddedForm(itemToRemember) ;Remove this item from the list of duplicates.
		existingItemIndex = top    ;Record that this item is now on the top of the stack.
	else    ;If this item occupies one or no slots in the stack.
		existingItemIndex = RememberedItems.Find(itemToRemember)    ;Search for this item in the stack.
	endif

	if existingItemIndex < 0    ;If we don't already have this item in the stack.
		;Remember replacement data until we combine stack slots, as it will be valid until then.
		if !pickUpBehaviorModifier[1] || quantityToRemember <= pickUpBehaviorModifier[1]
			RememberNewItem(itemToRemember, quantityToRemember, containerToRemember)
		else
			RememberNewItem(itemToRemember, pickUpBehaviorModifier[1], containerToRemember)
		endif
	else                        ;If we do have this item in the stack somewhere.
		SwapIndexToTop(existingItemIndex)           ;Move it to the top and add the number we just picked up.
		if !pickUpBehaviorModifier[1] || RememberedQuantities[top] + quantityToRemember <= pickUpBehaviorModifier[1]
			RememberedQuantities[top] = RememberedQuantities[top] + quantityToRemember
		else
			RememberedQuantities[top] = pickUpBehaviorModifier[1]
		endif
		RememberedLocations[top] = None    ;Clear any replacement data, as it's no longer valid.
	endif
EndFunction

Function HandleRememberEach(Form itemToRemember, int quantityToRemember, ObjectReference containerToRemember)
	{Remember the items individually, up to the amount allowed by the modifier.}
	if pickUpBehaviorModifier[2] && pickUpBehaviorModifier[2] < quantityToRemember
		quantityToRemember = pickUpBehaviorModifier[2]
	endif

	int i = 0
	While i < quantityToRemember && i < size
		RememberNewItem(itemToRemember, 1, containerToRemember)
		i += 1
	EndWhile
EndFunction

Function HandleRememberSome(Form itemToRemember, int quantityToRemember, ObjectReference containerToRemember)
	{Remember in one stack some of these items, as allowed by the modifier.}
	RememberNewItem(itemToRemember, pickUpBehaviorModifier[3], containerToRemember)
EndFunction

ObjectReference Function GetLocationRef(ObjectReference containerRef)
	{Return the appropriate world location or container reference to remember, if either.}
	if containerRef != None && (rememberContainer || replaceInContainer)    ;If we have a container and are remembering containers.
		return containerRef

	elseif containerRef == None && (rememberWorldLocation || replaceInWorld)    ;If we don't have a container and are remembering world locations.
		ObjectReference toReturn = locationXMarker
		locationXMarker = None  ;Clear our reference to locationXMarker, so that a new XMarker is created on next CrosshairRefChange.
		return toReturn

	endif

	return None ;Otherwise, don't remember any location data.
EndFunction

bool Function CanReplaceInContainer(int index = -1)
	{Determines whether the item at index can currently be replaced in its container.}
	if index < 0
		index = top
	endif

	if RememberedLocations[index] != None && RememberedLocations[index].GetBaseObject() != XMarker && (!replaceInContainerDistance || PlayerRef.GetDistance(RememberedLocations[index]) <= replaceInContainerDistance)
		return True
	endif

	return False
EndFunction

bool Function CanReplaceInWorld(int index = -1)
	{Determines whether the item at index can currently be replaced in its original world location.}
	if index < 0
		index = top
	endif

	if RememberedLocations[index] != None && RememberedLocations[index].GetBaseObject() == XMarker && (!replaceInWorldDistance || PlayerRef.GetDistance(RememberedLocations[index]) <= replaceInWorldDistance)
		return True
	endif

	return False
EndFunction

int Function GetNextStackIndex(int index = -1)
	{Get the next stack index from the passed-in index, or from top if no index is passed.}
	if index < 0
		index = top
	endif
	index += 1
	if index >= size
		return 0
	endif
	return index
EndFunction

int Function GetPreviousStackIndex(int index = -1)
	{Get the previous stack index from the passed-in index, or from top if no index is passed.}
	if index < 0
		index = top
	endif
	index -= 1
	if index < 0
		return size - 1
	endif
	return index
EndFunction

int Function IncrementCurrentIndex()
	{Increment top, keeping it within the bounds set by size.}
	top = GetNextStackIndex()
	return top
EndFunction

int Function DecrementCurrentIndex()
	{Decrement top, keeping it within the bounds set by size.}
	top = GetPreviousStackIndex()
	return top
EndFunction

int Function CountRememberedItems()
	{Count the number of remembered item stack slots that are filled.}
	int i = top
	int iterations = 0
	int rememberedCount = 0

	While RememberedItems[i] != None && iterations < size
		rememberedCount += 1
		i = GetPreviousStackIndex(i)
		iterations += 1
	EndWhile

	return rememberedCount
EndFunction

int[] Function FindAllInstancesInStack(Form searchFor)
	{Starting from top, find all stack indices occupied by searchFor. Return as an int array populated with indices, terminated by -1 if not full.}
	int[] results = new int[10]
	int resultsIndex = 0

	;Mock a do-while structure.
	if RememberedItems[top] == searchFor
		results[resultsIndex] = top
		resultsIndex += 1
	endif

	int i = GetPreviousStackIndex(top)
	While i != top && RememberedItems[i] != None
		if RememberedItems[i] == searchFor
			results[resultsIndex] = i
			resultsIndex += 1
		endif
		i = GetPreviousStackIndex(i)
	EndWhile

	if resultsIndex < results.Length    ;If we haven't filled the results array.
		results[resultsIndex] = -1      ;Terminate it with -1.
	endif

	return results
EndFunction

Function SwapIndexToTop(int index)
	{Move the item(s) at index to the top of the stack, pushing down the others.}
	if index != top    ;No-op if this index is already the top of the stack.
		Form itemToTop = RememberedItems[index]
		int quantityToTop = RememberedQuantities[index]
		ObjectReference locationToTop = RememberedLocations[index]

		RemoveIndexFromStack(index)
		RememberNewItem(itemToTop, quantityToTop, locationToTop)
		RememberedLocations[top] = locationToTop   ;Ensure that the existing location was swapped to the top regardless of current location remembering settings.
	endif
EndFunction

Function SwapIndices(int indexOne, int indexTwo)
	{Swap the item(s) at the given indices.}
	Form tempItem = RememberedItems[indexOne]
	RememberedItems[indexOne] = RememberedItems[indexTwo]
	RememberedItems[indexTwo] = tempItem

	int tempQuantity = RememberedQuantities[indexOne]
	RememberedQuantities[indexOne] = RememberedQuantities[indexTwo]
	RememberedQuantities[indexTwo] = tempQuantity

	ObjectReference tempLocation = RememberedLocations[indexOne]
	RememberedLocations[indexOne] = RememberedLocations[indexTwo]
	RememberedLocations[indexTwo] = tempLocation
EndFunction

Function AlignAndResizeStack(int newStackSize = -1)
	{Align the stack with the arrays, so that the bottom item on the stack is at the array's 0 index. Optionally re-size the stack.}
	if RememberedItems[top] == None    ;If the stack is empty.
		top = RememberedItems.Length - 1   ;Reset top so the next item remembered is at 0.
	else    ;If we have at least one item remembered.
		Form[] newItems = new Form[10]              ;Build new, aligned stack arrays.
		int[] newQuantities = new int[10]
		ObjectReference[] newContainers = new ObjectReference[10]

		int i = 0
		While i < newItems.Length
			newItems[i] = None
			newQuantities[i] = 0
			newContainers[i] = None
			i += 1
		EndWhile

		if newStackSize < 1 ;If no argument was passed, keep the stack the same size.
			newStackSize = size
		endif

		int rememberedCount = CountRememberedItems()    ;Count the number of slots we currently have filled.
		if rememberedCount >= newStackSize  ;If the currently occupied slots match or overflow the stack size.
			i = newStackSize - 1                ;Then we start our stack at the highest allowed position.
		else                                ;If the currently occupied slots don't fill the new limit.
			i = rememberedCount - 1             ;Then we start our stack as high as needed to accomodate all slots.
		endif
		int newCurrentIndex = i

		While i >= 0
			newItems[i] = RememberedItems[top]
			newQuantities[i] = RememberedQuantities[top]
			newContainers[i] = RememberedLocations[top]
			DecrementCurrentIndex()
			i -= 1
		EndWhile

		RememberedItems = newItems
		RememberedQuantities = newQuantities
		RememberedLocations = newContainers
		top = newCurrentIndex
	endif
EndFunction
