Scriptname QuickDropStackScript extends ReferenceAlias
{QuickDrop stack script. This reusable data structure stores a stack of Forms, integer quantities, and ObjectReference locations. Also can remember which of the items it contains are duplicates.}

;Because Papyrus limits us to statically sized arrays, a true stack (of
;unlimited size) is not possible - without a linked list implementation,
;which Papyrus makes a real bitch. A stack of limited size that always
;starts at index 0 would be grossly inefficient, because an array shift
;of all items would need to be performed every time something was pushed.
;Instead, QuickDrop essentially treats its arrays as if they were circular.
;When the last index in the array is reached, the top loops back around to
;the beginning of the array and begins overwriting items from the bottom
;up. If items are popped at the bottom of the array, the stack top loops
;around to the array top and begins popping items from the top down. This
;stack implementation requires careful tracking, but doesn't ever require
;that the stack array be shifted (so long as it is used like a stack,
;which it often isn't - we can, and do, access, move, and remove items
;that aren't at the top of the stack).

;This stack is most easily maintained when all of its items are
;consecutive in the arrays. This does not imply that there can't be empty
;space on either or both sides of the remembered items. If the stack
;loops around and begins overwriting the bottom items in the array,
;then several items are popped off, we can reach a state where there is
;a consecutive block of remembered items in the middle of the arrays, with
;empty space on either side. In order to prevent ourselves from reaching a
;state where there are items at the beginning and the end of the arrays with
;empty space in between, or empty space between items, the stack is
;realigned with the arrays whenever its size changes and shifted down
;whenever items are removed from anywhere but the top.

Form[] Property items Auto
{Remembered items.}

int[] Property quantities Auto
{The quantity of the corresponding item remembered.}

ObjectReference[] Property locations Auto
{The world location or container the corresponding item came from, or None if no location data is remembered.}

Form Property itemBuffer = None Auto
{Contains the item we most recently pushed, popped, or removed, so that it can be accessed for notifications.}

int Property quantityBuffer = 0 Auto
{Contains the quantity we most recently pushed, popped, or removed, so that it can be accessed for notifications.}

;Start top at 9 so that the first call to Push sets it back to 0.
int Property top = 9 Auto
{The index representing the top of the stack.}

int Property size = 5 Auto
{The size (capacity) of the stack.}

int Property depth = 0 Auto
{The current depth of the stack - the number of slots that are actually filled.}

Static Property XMarker Auto
{An XMarker, of the type used to mark world locations. Needed in this script for comparison operations.}

Form[] duplicates
;An array containing items that are duplicated in this stack.

Event OnInit()
	{Perform script setup.}
	items = new Form[10]
	quantities = new int[10]
	locations = new ObjectReference[10]
	duplicates = new Form[1]	;Placeholder array.

	int i = 0
	While i < items.Length
		items[i] = None
		quantities[i] = 0
		locations[i] = None
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

Function Swap(int indexOne, int indexTwo)
	{Don't swap indices while not Ready.}
EndFunction

Function MoveToTop(int index)
	{Don't move to the top while not Ready.}
EndFunction

Function RecordDuplicates()
	{Don't record duplicate items while not Ready.}
EndFunction

Function ClearDuplicates()
	{Don't clear duplicate items while not Ready.}
EndFunction

bool Function HasDuplicate(Form query)
	{Always assume no duplication while not Ready.}
	return False
EndFunction

Function RemoveDuplicate(Form query)
	{Don't remove duplicate records while not Ready.}
EndFunction

Function BufferIndex(int index)
	{Do not set buffers while not Ready.}
EndFunction

Function ClearBuffers()
	{Do not clear buffers while not Ready.}
EndFunction

Function Allocate(int size)
	{Do not allocate while not Ready.}
EndFunction

Auto State Ready
	;In Ready state, state-dependent entry points into the stack are available to callers.
	;These are driver functions that call underlying workhorse functions, so that the empty-state
	;workhorse methods can reliably be called by other internal stack methods.

	Function Push(Form itemToRemember, int quantityToRemember, ObjectReference locationToRemember)
		{Push a new item onto the stack.}
		GoToState("Working")
		_Push(itemToRemember, quantityToRemember, locationToRemember)
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
		{Set a new size and align the stack.}
		GoToState("Working")
		_SetSize(newSize)
		GoToState("Ready")
	EndFunction

	Function Swap(int indexOne, int indexTwo)
		{Swap the item(s) at the given indices. Does not check whether the indices given are within stack bounds.}
		GoToState("Working")
		_Swap(indexOne, indexTwo)
		GoToState("Ready")
	EndFunction

	Function MoveToTop(int index)
		{Remove the item at the given index, pushing others down into its place, then place it on the top of the stack.}
		GoToState("Working")
		_MoveToTop(index)
		GoToState("Ready")
	EndFunction

	Function RecordDuplicates()
		{Record duplicated items in the duplicates array.}
		GoToState("Working")
		_RecordDuplicates()
		GoToState("Ready")
	EndFunction

	Function ClearDuplicates()
		{Clear the duplicated items.}
		GoToState("Working")
		_ClearDuplicates()
		GoToState("Ready")
	EndFunction

	bool Function HasDuplicate(Form query)
		{Check whether the given form is recorded as a duplicate.}
		GoToState("Working")
		bool duplicate = _HasDuplicate(query)
		GoToState("Ready")
		return duplicate
	EndFunction

	Function RemoveDuplicate(Form query)
		{Remove the record of this form in duplicates, if it exists.}
		GoToState("Working")
		_RemoveDuplicate(query)
		GoToState("Ready")
	EndFunction

	Function BufferIndex(int index)
		{Buffer the given index.}
		GoToState("Working")
		_BufferIndex(index)
		GoToState("Ready")
	EndFunction

	Function ClearBuffers()
		{Clear all stack buffers.}
		GoToState("Working")
		_ClearBuffers()
		GoToState("Ready")
	EndFunction

	Function Allocate(int size)
		{Allocate new stack arrays that will provide enough space for a stack of the given size. Back up existing stack arrays before calling this function!}
		GoToState("Working")
		_Allocate(size)
		GoToState("Ready")
	EndFunction
EndState

Function _Push(Form itemToRemember, int quantityToRemember, ObjectReference locationToRemember)
	{Push a new item onto the stack.}
	top = GetNextStackIndex(top)

	if items[top] == None
		depth += 1	;Unless we're overwriting an item, add 1 to depth.
	endif

	items[top] = itemToRemember
	quantities[top] = quantityToRemember
	locations[top] = locationToRemember

	_BufferIndex(top)
EndFunction

Function _Pop()
	{Pop an item from the stack. The item is not returned.}

	;If we have world location data stored at the top index.
	if locations[top] != None && locations[top].GetBaseObject() == XMarker
		locations[top].Delete()	;Mark the XMarker for deletion.
	endif

	_BufferIndex(top)

	items[top] = None
	locations[top] = None
	top = GetPreviousStackIndex(top)
	depth -= 1
EndFunction

Function _Remove(int index, bool del = True)
	{Remove an item from the stack. Shift others down into its place. Doesn't check if index is within stack bounds. The item removed is not returned.}

	;If we have world location data stored at the index being removed and we want to delete it.
	if del && locations[index] != None && locations[index].GetBaseObject() == XMarker
		locations[index].Delete()	;Mark the XMarker for deletion.
	endif

	_BufferIndex(index)

	;Shift stack down, overwriting this index.
	While index != top
		int nextIndex = GetNextStackIndex(index)
		items[index] = items[nextIndex]
		quantities[index] = quantities[nextIndex]
		locations[index] = locations[nextIndex]
		index = nextIndex
	EndWhile

	;Clear the top item of the stack.
	items[top] = None
	locations[top] = None
	top = GetPreviousStackIndex(top)
	depth -= 1
EndFunction

Function _SetSize(int newSize)
	{Set a new size and align the stack.}
	if newSize != size    ;If the size of the stack is actually changing.
		size = newSize
		Align()
	endif
EndFunction

Function _Swap(int indexOne, int indexTwo)
	{Swap the item(s) at the given indices. Does not check whether the indices given are within stack bounds.}

	Form tempItem = items[indexOne]
	items[indexOne] = items[indexTwo]
	items[indexTwo] = tempItem

	int tempQuantity = quantities[indexOne]
	quantities[indexOne] = quantities[indexTwo]
	quantities[indexTwo] = tempQuantity

	ObjectReference tempLocation = locations[indexOne]
	locations[indexOne] = locations[indexTwo]
	locations[indexTwo] = tempLocation
EndFunction

Function _MoveToTop(int index)
	{Remove the item at the given index, pushing others down into its place, then place it on the top of the stack.}
	Form tempItem = items[index]
	int tempQuantity = quantities[index]
	ObjectReference tempLocation = locations[index]

	_Remove(index, False)
	_Push(tempItem, tempQuantity, tempLocation)
EndFunction

Function _RecordDuplicates()
	{Record duplicated items in the duplicates array.}

	;The most space we will ever need to record duplicate items is N/2, where N is the Length of the items array.
	;This is the case in which the stack is full and every item is duplicated exactly one time.
	duplicates = new Form[5]

	int duplicateIndex = 0
	int i = 0
	While i < items.Length - 1
		if items[i] != None && items.Find(items[i], i + 1) >= 0 && duplicates.Find(items[i]) < 0
			duplicates[duplicateIndex] = items[i]
			duplicateIndex += 1
		endif
		i += 1
	EndWhile
EndFunction

Function _ClearDuplicates()
	{Clear the duplicated items.}
	;Papyrus can't actually deallocate arrays. Creating a new array of length 1 will get the other array garbage collected, though.
	duplicates = new Form[1]
EndFunction

bool Function _HasDuplicate(Form query)
	{Check whether the given form is recorded as a duplicate.}
	return duplicates.Find(query) >= 0
EndFunction

Function _RemoveDuplicate(Form query)
	{Remove the record of this form in duplicates, if it exists.}
	int index = duplicates.Find(query)
	if index >= 0
		duplicates[index] = None
	endif
EndFunction

Function _BufferIndex(int index)
	{Buffer the given index.}
	itemBuffer = items[index]
	quantityBuffer = quantities[index]
EndFunction

Function _ClearBuffers()
	{Clear all stack buffers.}
	itemBuffer = None
	quantityBuffer = 0
EndFunction

Function _Allocate(int numElements)
	{Allocate new stack arrays that will provide enough space for a stack of the given numElements. Back up existing stack arrays before calling this function!}
	;Allocate stack arrays in increments of 8 elements, up to the maximum of 128.
	;This seems like a reasonable tradeoff between granularity and memory usage and ridiculous if-else code.
	if numElements > 120
		items = new Form[128]
		quantities = new int[128]
		locations = new ObjectReference[128]
	elseif numElements > 112
		items = new Form[120]
		quantities = new int[120]
		locations = new ObjectReference[120]
	elseif numElements > 104
		items = new Form[112]
		quantities = new int[112]
		locations = new ObjectReference[112]
	elseif numElements > 96
		items = new Form[104]
		quantities = new int[104]
		locations = new ObjectReference[104]
	elseif numElements > 88
		items = new Form[96]
		quantities = new int[96]
		locations = new ObjectReference[96]
	elseif numElements > 80
		items = new Form[88]
		quantities = new int[88]
		locations = new ObjectReference[88]
	elseif numElements > 72
		items = new Form[80]
		quantities = new int[80]
		locations = new ObjectReference[80]
	elseif numElements > 64
		items = new Form[72]
		quantities = new int[72]
		locations = new ObjectReference[72]
	elseif numElements > 56
		items = new Form[64]
		quantities = new int[64]
		locations = new ObjectReference[64]
	elseif numElements > 48
		items = new Form[56]
		quantities = new int[56]
		locations = new ObjectReference[56]
	elseif numElements > 40
		items = new Form[48]
		quantities = new int[48]
		locations = new ObjectReference[48]
	elseif numElements > 32
		items = new Form[40]
		quantities = new int[40]
		locations = new ObjectReference[40]
	elseif numElements > 24
		items = new Form[32]
		quantities = new int[32]
		locations = new ObjectReference[32]
	elseif numElements > 16
		items = new Form[24]
		quantities = new int[24]
		locations = new ObjectReference[24]
	elseif numElements > 8
		items = new Form[16]
		quantities = new int[16]
		locations = new ObjectReference[16]
	elseif numElements > 0
		items = new Form[8]
		quantities = new int[8]
		locations = new ObjectReference[8]
	else
		;This is the closest we can come to deallocating these arrays.
		items = new Form[1]
		quantities = new int[1]
		locations = new ObjectReference[1]
	endif

	int i = 0
	While i < items.Length
		items[i] = None
		quantities[i] = 0
		locations[i] = None
		i += 1
	EndWhile
EndFunction

bool Function HasContainer(int index = -1)
	{Whether or not container data is stored at the given index.}
	if index == -1
		index = top
	endif

	return locations[index] != None && locations[index].GetBaseObject() != XMarker
EndFunction

bool Function HasWorldLocation(int index = -1)
	{Whether or not world location data is stored at the given index.}
	if index == -1
		index = top
	endif

	return locations[index] != None && locations[index].GetBaseObject() == XMarker
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

int Function Find(Form query, int index = -10)
	{Search down the stack for the first instance of query, starting from the passed-in index. Does not check whether index is within stack bounds. Returns -1 if the query is not found.}
	if index == -10	;Start from the top of the stack if no index was passed in.
		index = top
	endif

	;Array Rfind is faster than a Papyrus search loop.
	int i = items.Rfind(query, index)
	if index > top && i <= top		;If we passed the bottom of the stack in our search and didn't find the query.
		i = -1
	elseif index <= top && i < 0	;If we didn't pass the bottom of the stack and didn't find the query.
		i = items.Rfind(query, size - 1)	;Loop around to the top of the stack array and search down to the bottom of the stack.
		if i <= top						;If we passed the bottom of the stack and didn't find the query.
			i = -1
		endif
	endif

	return i
EndFunction

int Function Rfind(Form query, int index = -10)
	{Search up the stack for the first instance of query, starting from the passed-in index. Does not check whether index is within stack bounds. Returns -1 if the query is not found.}
	if index == -10	;Start from the bottom of the stack if no index was passed in.
		if depth == items.Length	;If the stack is full.
			index = GetNextStackIndex(top)			;Then the bottom of the stack is the next index from the top.
		else						;If the stack isn't full.
			index = GetNextStackIndex(Find(None))	;Then the bottom of the stack is the index following that of the first None.
		endif
	endif

	;Array Find is faster than a Papyrus search loop.
	int i = items.Find(query, index)
	if index <= top && (i < 0 || i > top)	;If we passed the top of the stack in our search and didn't find the query.
		i = -1
	elseif index > top && i < 0		;If we didn't pass the top of the stack and didn't find the query.
		i = items.Find(query)				;Loop around to the bottom of the stack array and search up to the top of the stack.
		if i < 0 || i > top				;If we passed the top of the stack and didn't find the query.
			i = -1
		endif
	endif

	return i
EndFunction

Function Align()
	{Align the stack with the arrays, so that the bottom item on the stack is at the array's 0 index. The stack is aligned according to the size property.}
	if !depth		;If the stack is empty.
		top = items.Length - 1	;Reset top so the next item remembered is at 0.

	else	;If we have at least one item remembered.
		Form[] newItems = new Form[10]		;Build new, aligned stack arrays.
		int[] newQuantities = new int[10]
		ObjectReference[] newLocations = new ObjectReference[10]

		int i = 0
		While i < newItems.Length
			newItems[i] = None
			newQuantities[i] = 0
			newLocations[i] = None
			i += 1
		EndWhile

		if depth >= size	;If the currently occupied slots match or overflow the stack size.
			i = size - 1		;Then we start our stack at the highest allowed position.
			depth = size
		else				;If the currently occupied slots don't fill the new limit.
			i = depth - 1		;Then we start our stack as high as needed to accomodate all slots.
		endif

		int j = top
		While i >= 0
			newItems[i] = items[j]
			newQuantities[i] = quantities[j]
			newLocations[i] = locations[j]
			j = GetPreviousStackIndex(j)
			i -= 1
		EndWhile

		items = newItems
		quantities = newQuantities
		locations = newLocations
		top = depth - 1
	endif
EndFunction
