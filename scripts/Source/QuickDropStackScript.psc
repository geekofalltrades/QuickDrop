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

Static Property XMarker Auto
{An XMarker, of the type used to mark world locations. Needed in this script for comparison operations.}

Form[] duplicates
{An array containing items that are duplicated in this stack.}

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

bool Function ClearDuplicates(Form query)
	{Always assume no duplication while not Ready.}
	return False
EndFunction

Auto State Ready
	;In Ready state, state-dependent entry points into the stack are available to callers.
	;These are driver functions that call underlying workhorse functions, so that stack methods
	;can reliably make internal calls to other state-dependent stack methods.

	Function Push(Form itemToRemember, int quantityToRemember, ObjectReference locationToRemember)
		{Push a new item onto the stack.}
		GoToState("Working")
		_Push(Form itemToRemember, int quantityToRemember, ObjectReference locationToRemember)
		GoToState("Ready")
	EndFunction

	Function Pop()
		{Pop an item from the stack. The item is not returned.}
		GoToState("Working")
		_Pop()
		GoToState("Ready")
	EndFunction

	Function Remove(int index)
		{Remove an item from the stack. Shift others down into its place. Doesn't check if index is within stack bounds. The item removed is not returned.}
		GoToState("Working")
		_Remove(index)
		GoToState("Ready")
	EndFunction

	Function SetSize(int newSize)
		{Set a new size. Thin wrapper around AlignAndResizeStack.}
		GoToState("Working")
		_SetSize(newSize)
		GoToState("Ready")
	EndFunction

	Function RecordDuplicates()
		GoToState("Working")
		_RecordDuplicates()
		GoToState("Ready")
	EndFunction

	Function ClearDuplicates()
		{Don't clear duplicate items while not Ready.}
	EndFunction

	bool Function ClearDuplicates(Form query)
		{Always assume no duplication while not Ready.}
		return False
	EndFunction
EndState

Function _Push(Form itemToRemember, int quantityToRemember, ObjectReference locationToRemember)
	{Push a new item onto the stack.}
	GoToState("Working")

	top = GetNextStackIndex(top)
	RememberedItems[top] = itemToRemember
	RememberedQuantities[top] = quantityToRemember
	RememberedLocations[top] = locationToRemember

	GoToState("Ready")
EndFunction

Function _Pop()
	{Pop an item from the stack. The item is not returned.}
	GoToState("Working")

	;If we have world location data stored at the top index.
	if RememberedLocations[index] != None && RememberedLocations[index].GetBaseObject() == XMarker
		RememberedLocations[index].Delete()	;Mark the XMarker for deletion.
	endif

	RememberedItems[top] = None
	RememberedLocations[top] = None
	top = GetPreviousStackIndex(top)

	GoToState("Ready")
EndFunction

Function _Remove(int index)
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

Function _Swap(int indexOne, int indexTwo)
	{Swap the item(s) at the given indices.}
	GoToState("Working")

	Form tempItem = RememberedItems[indexOne]
	RememberedItems[indexOne] = RememberedItems[indexTwo]
	RememberedItems[indexTwo] = tempItem

	int tempQuantity = RememberedQuantities[indexOne]
	RememberedQuantities[indexOne] = RememberedQuantities[indexTwo]
	RememberedQuantities[indexTwo] = tempQuantity

	ObjectReference tempLocation = RememberedLocations[indexOne]
	RememberedLocations[indexOne] = RememberedLocations[indexTwo]
	RememberedLocations[indexTwo] = tempLocation

	GoToState("Ready")
EndFunction

Function _SwapToTop(int index)
	{Move the item(s) at index to the top of the stack, pushing down the others. Convenience method replacing }
	if index != top    ;No-op if this index is already the top of the stack.
		Form itemToTop = RememberedItems[index]
		int quantityToTop = RememberedQuantities[index]
		ObjectReference locationToTop = RememberedLocations[index]

		Remove(index)
		RememberNewItem(itemToTop, quantityToTop, locationToTop)
		RememberedLocations[top] = locationToTop   ;Ensure that the existing location was swapped to the top regardless of current location remembering settings.
	endif
EndFunction

Function _SetSize(int newSize)
	{Set a new size. Thin wrapper around AlignAndResizeStack.}
	if newMaxRemembered != size    ;If the size of the stack is actually changing.
		GoToState("Working")

		AlignAndResizeStack(newSize)
		size = newSize

		GoToState("Ready")
	endif
EndFunction

Function _RecordDuplicates()
	{Record duplicated items in the duplicates array.}
	GoToState("Working")

	;The most space we will ever need to record duplicate items is N/2, where N is the Length of the RememberedItems array.
	;This is the case in which the stack is full and every item is duplicated exactly one time.
	duplicates = new Form[5]

	int duplicateIndex = 0
	int i = 0
	While i < RememberedItems.Length - 1
		if RememberedItems[i] != None && RememberedItems.Find(RememberedItems[i], i + 1) >= 0 && duplicates.Find(RememberedItems[i]) < 0
			duplicates[duplicateIndex] = RememberedItems[i]
			duplicateIndex += 1
		endif
		i += 1
	EndWhile

	GoToState("Ready")
EndFunction

Function _ClearDuplicates()
	{Clear the duplicated items.}
	GoToState("Working")
	duplicates = None
	GoToState("Ready")
EndFunction

bool Function _HasDuplicates(Form query)
	{Check whether the given form is recorded as a duplicate.}
	if duplicates != None && duplicates.Find(query) >= 0
		return True
	endif
	return False
EndFunction

int Function GetNextStackIndex(int index)
	{Get the next stack index from the passed-in index.}
	index += 1
	if index >= size
		return 0
	endif
	return index
EndFunction

int Function GetPreviousStackIndex(int index)
	{Get the previous stack index from the passed-in index.}
	index -= 1
	if index < 0
		return size - 1
	endif
	return index
EndFunction

int Function CountRememberedItems()
	{Count the number of remembered item stack slots that are filled.}
	int remembered

	;Add the count of items from the first array index up to and including the top index.
	int firstNone = RememberedItems.Rfind(None, top)
	if firstNone == top		;The stack is empty.
		return 0
	elseif firstNone < 0	;The array is full from its first index to the top index.
		remembered = top + 1
	else					;The array begins with one or more "None"s.
		remembered = top - firstNone
	endif

	;Add the count items from but NOT including the top index up to the last array index.
	int lastNone = RememberedItems.Find(None, top)
	if lastNone < 0	;The array is full from the top index to its last index.
		remembered += RememberedItems.Length - top - 1
	else			;The array ends with one or more "None"s.
		remembered += lastNone - top - 1
	endif

	return remembered
EndFunction

int[] Function FindAllInstancesInStack(Form searchFor)
	{Starting from top, find all stack indices occupied by searchFor. Return as an int array populated with indices, terminated by -1 if not full.}
	int[] results = new int[10]
	int resultsIndex = 0

	;Search from the top index to the first array index.
	int i = RememberedItems.Rfind(searchFor, top)
	While i >= 0
		results[resultsIndex] = i
		resultsIndex += 1
		i = RememberedItems.Rfind(searchFor, i - 1)
	EndWhile

	;Search from the last array index to the top index.
	i = RememberedItems.Rfind(searchFor)
	While i > top
		results[resultsIndex] = i
		resultsIndex += 1
		i = RememberedItems.Rfind(searchFor, i - 1)
	EndWhile

	if resultsIndex < results.Length    ;If we haven't filled the results array.
		results[resultsIndex] = -1      ;Terminate it with -1.
	endif

	return results
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
