Scriptname QuickDropPlayerScript Extends ReferenceAlias
{QuickDrop player script.}

QuickDropQuestScript Property QuickDropQuest Auto
{A reference to the quest script.}

Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	{Pass along items picked up to the main script.}
	QuickDropQuest.RememberItems(akBaseItem, aiItemCount, akItemReference, akSourceContainer)
EndEvent

Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
    {Pass along items dropped to the main script.}
    QuickDropQuest.ForgetItems(akBaseItem, aiItemCount, akItemReference, akDestContainer)
EndEvent
