Scriptname QuickDropPlayerScript Extends ReferenceAlias
{QuickDrop player script.}

QuickDropQuestScript Property QuickDropQuest Auto
{A reference to the quest script.}

bool Property notifyOnSkip = False Auto
{Whether or not to display a message when an item is skipped.}

int Property quantityHandling = 0 Auto
{How to handle multiple items. 0 = Remember Quantity, 1 = Remember Individually, 2 = Remember Only One.}

Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	{Remember items picked up and update the quest script.}
	if akItemReference == None
		if quantityHandling == 0		;Remember the item and how many we picked up
			int currentIndex = QuickDropQuest.IncrementCurrentIndex()
			QuickDropQuest.RememberedItems[currentIndex] = akBaseItem
			QuickDropQuest.RememberedQuantities[currentIndex] = aiItemCount
		elseif quantityHandling == 1	;Remember as many individual instances of the item as we can.
			int i = 0
			While i < aiItemCount && i < QuickDropQuest.maxRemembered
				int currentIndex = QuickDropQuest.IncrementCurrentIndex()
				QuickDropQuest.RememberedItems[currentIndex] = akBaseItem
				QuickDropQuest.RememberedQuantities[currentIndex] = 1
				i += 1
			EndWhile
		elseif quantityHandling == 2	;Remember only one instance of the item.
			int currentIndex = QuickDropQuest.IncrementCurrentIndex()
			QuickDropQuest.RememberedItems[currentIndex] = akBaseItem
			QuickDropQuest.RememberedQuantities[currentIndex] = 1
		endif
	elseif notifyOnSkip
		Debug.Notification("QuickDrop: " + akBaseItem.GetName() + " not remembered.")
	endif
EndEvent

int Function IncrementQuantityHandling()
	quantityHandling += 1
	if quantityHandling > 2
		quantityHandling = 0
	endif
	return quantityHandling
EndFunction