Scriptname QuickDropPlayerForgetScript Extends ReferenceAlias
{QuickDrop player script for handling OnItemRemoved.}

QuickDropQuestScript Property QuickDropQuest Auto
{A reference to the quest script.}

Auto State Enabled
	Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
	    {Pass along items dropped to the main script.}
	    QuickDropQuest.ForgetItems(akBaseItem, aiItemCount, akItemReference, akDestContainer)
	EndEvent
EndState

State Disabled
	;Take no action when items are remembered.
EndState
