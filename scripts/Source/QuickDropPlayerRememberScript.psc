Scriptname QuickDropPlayerRememberScript Extends ReferenceAlias
{QuickDrop player script for remembering items OnItemAdded.}

QuickDropQuestScript Property QuickDropQuest Auto
{A reference to the quest script.}

Auto State Enabled
	Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
		{Pass along items picked up to the main script.}
		QuickDropQuest.RememberItems(akBaseItem, aiItemCount, akItemReference, akSourceContainer)
	EndEvent
EndState

State Disabled
	;Don't remember new items when disabled.
EndState
