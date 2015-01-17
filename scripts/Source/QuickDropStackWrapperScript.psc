ScriptName QuickDropStackWrapperScript extends QuickDropStackScript
{A wrapper around QuickDropStackScript that handles non-stack-related functionality related to that single stack.}

;This script tracks properties and provides functionality for each stack that
;aren't directly related to the stack data structure, like duplicate tracking,
;filtering, and buffering.

Form Property itemBuffer = None Auto
{Contains the item we most recently pushed, popped, or removed, so that it can be accessed for notifications.}

int Property quantityBuffer = 0 Auto
{Contains the quantity we most recently pushed, popped, or removed, so that it can be accessed for notifications.}

Form[] duplicates
;An array that tracks whether items are duplicated in the wrapped stack.
;For use with the Remember to One Slot pickup functionality.

Event OnInit()
	duplicates = new Form[1]	;Placeholder array.
EndEvent

State Working
	;Disallow access by other threads when state-dependent actions are
	;taking place. The following empty prototypes are all state-dependent
	;methods of the stack wrapper that must be thread-locked.
EndState

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

Auto State Ready
	;In Ready state, state-dependent entry points into the stack wrapper are available to callers.
	;These are driver functions that call underlying workhorse functions, so that the empty-state
	;workhorse methods can reliably be called by other internal stack wrapper methods.
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
EndState

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
