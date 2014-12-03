Scriptname QuickDropStackScript extends Quest
{QuickDrop stack script. This reusable data structure stores a stack of Forms, integer quantities, and ObjectReference locations.}

;Because Papyrus limits us to statically sized arrays, a true stack (of
;unlimited size) is not possible. A stack of limited size that always
;starts at index 0 would be grossly inefficient, because, if the stack
;were full, an array shift of all items would need to be performed every
;time something was pushed. Instead, QuickDrop essentially treats its
;arrays as if they were circular. When the last index in the array is
;reached, the currentIndex loops back around to the beginning of the
;array and begins overwriting items from the bottom up. If items are
;popped at the bottom of the array, the currentIndex loops around to the
;top and begins popping items from the top down. This stack implementation
;requires careful tracking, but doesn't ever require that the stack array
;be shifted (so long as it is used like a stack, which it often isn't -
;we can, and do, access, move, and pop items that aren't at the head of
;the stack).

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

FormList Property DuplicateItems Auto
{A FormList containing items that are duplicated in this stack.}

;Remember the index of the current item.
;Start it at 9 so that the first call to IncrementCurrentIndex sets it back to 0.
int Property currentIndex = 9 Auto
{The index representing the top of the stack.}

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

Auto State Ready
    Event OnKeyDown(int KeyCode)
        {Map key presses to their respective hotkey actions.}
        if !Utility.IsInMenuMode()  ;Try to disable hotkeys when menus are open.
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
            if pickUpBehavior == 0      ;Remember the item and how many we picked up as a stack.
                HandleRememberAll(akBaseItem, aiItemCount, akSourceContainer)
            elseif pickUpBehavior == 1  ;Remember as a stack and combine with any other stacks of this item on top of the remembered items stack.
                HandleCollapseAll(akBaseItem, aiItemCount, akSourceContainer)
            elseif pickUpBehavior == 2  ;Remember as many individual instances of the item as we can.
                HandleRememberEach(akBaseItem, aiItemCount, akSourceContainer)
            elseif pickUpBehavior == 3  ;Remember only some instances of the item.
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

        if indices[0] >= 0  ;If some of this item are remembered.
            int numToForget = aiItemCount

            if forgetOnRemoved  ;If we're forgetting picked-up items first.
                int i = 0   ;Start with the top stack index.
                While i < indices.Length && indices[i] >= 0 && numToForget > 0
                    if numToForget >= RememberedQuantities[indices[i]]  ;If this slot doesn't have enough to satisfy numToForget, or has just enough.
                        numToForget -= RememberedQuantities[indices[i]]
                        RemoveIndexFromStack(indices[i])    ;Remove this slot. It was removed from the top, so remaining indices are still valid.
                    elseif numToForget < RememberedQuantities[indices[i]]   ;If this slot does have enough to satsify numToForget.
                        RememberedQuantities[indices[i]] = RememberedQuantities[indices[i]] - numToForget   ;Remove numToForget items from this slot.
                        numToForget = 0
                    endif
                    i += 1
                EndWhile

            else    ;If we're forgetting picked-up items last.
                int totalRemembered = 0
                int i = 0
                While i < indices.Length && indices[i] >= 0
                    totalRemembered += RememberedQuantities[indices[i]]
                    i += 1
                EndWhile

                if PlayerRef.GetItemCount(akBaseItem) < totalRemembered ;If we don't have enough of this item left to remember.
                    i -= 1  ;Start with the bottom stack index.
                    While i >= 0 && numToForget > 0
                        if numToForget >= RememberedQuantities[indices[i]]  ;If this slot doesn't have enough to satisfy numToForget, or has just enough.
                            numToForget -= RememberedQuantities[indices[i]]
                            RemoveIndexFromStack(indices[i])    ;Remove this slot.
                            int j = i - 1   ;This slot was removed from the bottom, so adjust our remaining stack indices, because they've all shifted down 1.
                            While j >= 0
                                indices[j] = GetPreviousStackIndex(indices[j])
                                j -= 1
                            EndWhile
                        elseif numToForget < RememberedQuantities[indices[i]]   ;If this slot does have enough to satisfy numToForget.
                            RememberedQuantities[indices[i]] = RememberedQuantities[indices[i]] - numToForget   ;Remove numToForget items from this slot.
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
        if newMaxRemembered != maxRemembered    ;If the size of the stack is actually changing.
            GoToState("Working")
            AlignAndResizeStack(newMaxRemembered)
            maxRemembered = newMaxRemembered
            GoToState("Ready")
        endif
    EndFunction

    Function AdjustPickUpBehavior(int newPickUpBehavior)
        {Set a new pickUpBehavior. Perform necessary maintenance.}
        if newPickUpBehavior != pickUpBehavior  ;If pickUpBehavior is actually changing.
            GoToState("Working")

            if newPickUpBehavior == 1   ;If we're changing to Remember to One Stack Slot.
                int i = 0                   ;Remember all duplicate items so we can collapse them on next pickup.
                While i < RememberedItems.Length - 1    ;Search through the second-to-last array index.
                    if RememberedItems[i] != None && RememberedItems.Find(RememberedItems[i], i + 1) >= 0 && !QuickDropDuplicateItems.HasForm(RememberedItems[i])
                        QuickDropDuplicateItems.AddForm(RememberedItems[i])
                    endif
                    i += 1
                EndWhile

            elseif pickUpBehavior == 1  ;If we're changing from Remember to One Stack Slot.
                QuickDropDuplicateItems.Revert()        ;Forget duplicate items, if any.
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
    if RememberedItems[currentIndex] != None
        Debug.Notification("QuickDrop: Current: " + RememberedItems[currentIndex].GetName() + " (" + RememberedQuantities[currentIndex] + ").")
    else
        QuickDropNoItemsRemembered.Show()
    endif
EndFunction

Function HandleDropHotkey(int index = -1)
    {Drop the current item and move to the next. Doubles as a general-purpose function for dropping an item at any index.}
    if index < 0
        index = currentIndex
    endif

    if RememberedItems[index] != None
        ForgetScript.GoToState("Disabled")  ;Don't receive an OnItemRemoved when this item is dropped.

        if replaceInContainer && RememberedLocations[index] != None && RememberedLocations[index].GetBaseObject() != XMarker    ;We're replacing items in containers and have a container to replace to.
            if CanReplaceInContainer()
                if notifyOnReplaceInContainer
                    Debug.Notification("QuickDrop: " + RememberedItems[index].GetName() + " (" + RememberedQuantities[index] + ") replaced in container.")
                endif

                PlayerRef.RemoveItem(RememberedItems[index], RememberedQuantities[index], True, RememberedLocations[index])
                RemoveIndexFromStack()

            else
                if notifyOnFailToReplaceInContainer
                    Debug.Notification("QuickDrop: " + RememberedItems[index].GetName() + " (" + RememberedQuantities[index] + ") could not be replaced in container.")
                endif

                if replaceInContainerDropOnFail
                    if notifyOnDrop
                        Debug.Notification("QuickDrop: " + RememberedItems[index].GetName() + " (" + RememberedQuantities[index] + ") dropped.")
                    endif

                    PlayerRef.DropObject(RememberedItems[index], RememberedQuantities[index])
                    RemoveIndexFromStack()
                endif
            endif

        elseif replaceInWorld && RememberedLocations[index] != None && RememberedLocations[index].GetBaseObject() == XMarker    ;We're replacing items in the world and have an XMarker to replace to.
            if CanReplaceInWorld()
                if notifyOnReplaceInWorld
                    Debug.Notification("QuickDrop: " + RememberedItems[index].GetName() + " (" + RememberedQuantities[index] + ") replaced in world.")
                endif

                PlayerRef.DropObject(RememberedItems[index], RememberedQuantities[index]).MoveTo(RememberedLocations[index])
                RemoveIndexFromStack()

            else
                if notifyOnFailToReplaceInWorld
                    Debug.Notification("QuickDrop: " + RememberedItems[index].GetName() + " (" + RememberedQuantities[index] + ") could not be replaced in world.")
                endif

                if replaceInWorldDropOnFail
                    if notifyOnDrop
                        Debug.Notification("QuickDrop: " + RememberedItems[index].GetName() + " (" + RememberedQuantities[index] + ") dropped.")
                    endif

                    PlayerRef.DropObject(RememberedItems[index], RememberedQuantities[index])
                    RemoveIndexFromStack()
                endif
            endif

        else    ;We're not replacing items or don't have a place to replace this item to.
            if notifyOnDrop
                Debug.Notification("QuickDrop: " + RememberedItems[index].GetName() + " (" + RememberedQuantities[index] + ") dropped.")
            endif

            PlayerRef.DropObject(RememberedItems[index], RememberedQuantities[index])
            RemoveIndexFromStack()

        endif

        ForgetScript.GoToState("Enabled")

    else
        QuickDropNoItemsRemembered.Show()
    endif
EndFunction

Function HandleKeepHotkey(int index = -1)
    {Keep the current item and move to the next. Doubles as a general-purpose function for keeping the item at the passed-in index.}
    if index < 0
        index = currentIndex
    endif

    if RememberedItems[index] != None
        if notifyOnKeep
            Debug.Notification("QuickDrop: " + RememberedItems[index].GetName() + " (" + RememberedQuantities[index] + ") kept.")
        endif

        RemoveIndexFromStack(index)
    else
        QuickDropNoItemsRemembered.Show()
    endif
EndFunction

Function HandleDropAllHotkey(int[] indices = None)
    {Drop/replace all remembered items. Operates as if we're attempting a drop/replace on each individual item. Doubles as a general-purpose function for dropping the items at the given indices. Passed-in indices should be be an array of indexes in top-down stack order, either full or terminated with -1.}
    if RememberedItems[currentIndex] != None
        ForgetScript.GoToState("Disabled")  ;Don't receive OnItemRemoved when these items are dropped.

        int notify = 0  ;What type of notification to display for this action.
        int iterations = 0
        int terminate = CountRememberedItems()  ;Stop after this many iterations.

        int i
        if indices == None
            i = currentIndex
        else
            i = indices[iterations]
        endif

        ;Two sets of conditions: one for when we weren't passed indices, and one for when we were.
        While (indices == None && iterations < terminate) || (indices != None && i >= 0 && iterations < indices.Length)
            if replaceInContainer && RememberedLocations[i] != None && RememberedLocations[i].GetBaseObject() != XMarker ;We're replacing items in containers and have a container to replace to.
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

                    elseif notifyOnFailToReplaceInContainer ;Special-case notification: some items couldn't be dropped/replaced.
                        notify = 2

                    endif
                endif

            elseif replaceInWorld && RememberedLocations[i] != None && RememberedLocations[i].GetBaseObject() == XMarker    ;We're replacing items in the world and have an XMarker to replace to.
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

                    elseif notifyOnFailToReplaceInWorld ;Special-case notification: some items couldn't be dropped/replaced.
                        notify = 2

                    endif
                endif

            else    ;We're not replacing items or don't have a place to replace this item to.
                if notifyOnDrop && notify < 2
                    notify = 1
                endif

                PlayerRef.DropObject(RememberedItems[i], RememberedQuantities[i])
                RemoveIndexFromStack(i)

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

        if RememberedItems[currentIndex] == None    ;If we succeeded in clearing the entire stack.
            currentIndex = RememberedItems.Length - 1   ;Reset to last index so the next call to IncrementCurrentIndex returns 0.
        endif

    else
        QuickDropNoItemsRemembered.Show()

    endif
EndFunction

Function HandleKeepAllHotkey(int[] indices = None)
    {Keep all remembered items. Doubles as a general-purpose function for keeping the items at the passed-in indices. The indices must be an array of indices in top-down stack order, either full or terminated with -1.}
    if RememberedItems[currentIndex] != None
        if notifyOnKeep
            QuickDropAllItemsKept.Show()
        endif

        ;Two separate while loops, one for no passed-in indices and one for passed-in indices.
        if indices == None
            While RememberedItems[currentIndex] != None
                RemoveIndexFromStack(currentIndex)
            EndWhile

            currentIndex = RememberedItems.Length - 1   ;Reset to last index so the next call to IncrementCurrentIndex returns 0.

        else
            int iterations = 0
            While indices[iterations] >= 0 && iterations < indices.Length
                RemoveIndexFromStack(indices[iterations])
                iterations += 1
            EndWhile
        endif
    else
        QuickDropNoItemsRemembered.Show()
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

    if QuickDropDuplicateItems.HasForm(itemToRemember)  ;If this type of item currently occupies two or more slots in the stack.
        int[] indices = FindAllInstancesInStack(itemToRemember) ;Get a list of the stack slots occupied by this item.
        SwapIndexToTop(indices[0])  ;Swap the first instance of this item to the top of the stack.

        int i = 1
        While i < indices.Length && indices[i] >= 0 ;Add all other slots to the first one.
            RememberedQuantities[currentIndex] = RememberedQuantities[currentIndex] + RememberedQuantities[indices[i]]
            RemoveIndexFromStack(indices[i])
            i += 1
        EndWhile

        RememberedLocations[currentIndex] = None    ;Clear any replacement data, as it's no longer valid.

        if pickUpBehaviorModifier[1] && RememberedQuantities[currentIndex] > pickUpBehaviorModifier[1]  ;If we have more remembered than we're allowed, forget some.
            RememberedQuantities[currentIndex] = pickUpBehaviorModifier[1]
        endif

        QuickDropDuplicateItems.RemoveAddedForm(itemToRemember) ;Remove this item from the list of duplicates.
        existingItemIndex = currentIndex    ;Record that this item is now on the top of the stack.
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
        if !pickUpBehaviorModifier[1] || RememberedQuantities[currentIndex] + quantityToRemember <= pickUpBehaviorModifier[1]
            RememberedQuantities[currentIndex] = RememberedQuantities[currentIndex] + quantityToRemember
        else
            RememberedQuantities[currentIndex] = pickUpBehaviorModifier[1]
        endif
        RememberedLocations[currentIndex] = None    ;Clear any replacement data, as it's no longer valid.
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
    IncrementCurrentIndex()
    RememberedItems[currentIndex] = itemToRemember
    RememberedQuantities[currentIndex] = quantityToRemember
    RememberedLocations[currentIndex] = GetLocationRef(containerToRemember)
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

int Function GetNextStackIndex(int index = -1)
    {Get the next stack index from the passed-in index, or from currentIndex if no index is passed.}
    if index < 0
        index = currentIndex
    endif
    index += 1
    if index >= maxRemembered
        return 0
    endif
    return index
EndFunction

int Function GetPreviousStackIndex(int index = -1)
    {Get the previous stack index from the passed-in index, or from currentIndex if no index is passed.}
    if index < 0
        index = currentIndex
    endif
    index -= 1
    if index < 0
        return maxRemembered - 1
    endif
    return index
EndFunction

int Function IncrementCurrentIndex()
    {Increment currentIndex, keeping it within the bounds set by maxRemembered.}
    currentIndex = GetNextStackIndex()
    return currentIndex
EndFunction

int Function DecrementCurrentIndex()
    {Decrement currentIndex, keeping it within the bounds set by maxRemembered.}
    currentIndex = GetPreviousStackIndex()
    return currentIndex
EndFunction

int Function CountRememberedItems()
    {Count the number of remembered item stack slots that are filled.}
    int i = currentIndex
    int iterations = 0
    int rememberedCount = 0

    While RememberedItems[i] != None && iterations < maxRemembered
        rememberedCount += 1
        i = GetPreviousStackIndex(i)
        iterations += 1
    EndWhile

    return rememberedCount
EndFunction

int[] Function FindAllInstancesInStack(Form searchFor)
    {Starting from currentIndex, find all stack indices occupied by searchFor. Return as an int array populated with indices, terminated by -1 if not full.}
    int[] results = new int[10]
    int resultsIndex = 0

    ;Mock a do-while structure.
    if RememberedItems[currentIndex] == searchFor
        results[resultsIndex] = currentIndex
        resultsIndex += 1
    endif

    int i = GetPreviousStackIndex(currentIndex)
    While i != currentIndex && RememberedItems[i] != None
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
    if index != currentIndex    ;No-op if this index is already the top of the stack.
        Form itemToTop = RememberedItems[index]
        int quantityToTop = RememberedQuantities[index]
        ObjectReference locationToTop = RememberedLocations[index]

        RemoveIndexFromStack(index)
        RememberNewItem(itemToTop, quantityToTop, locationToTop)
        RememberedLocations[currentIndex] = locationToTop   ;Ensure that the existing location was swapped to the top regardless of current location remembering settings.
    endif
EndFunction

Function RemoveIndexFromStack(int index = -1)
    {Remove the item(s) at index from the stack, shifting others down into its place. Doesn't check if index is within stack bounds - make sure to verify this!}
    if index < 0
        index = currentIndex
    endif

    While index != currentIndex     ;Shift stack down, overwriting this index.
        int nextIndex = GetNextStackIndex(index)
        RememberedItems[index] = RememberedItems[nextIndex]
        RememberedQuantities[index] = RememberedQuantities[nextIndex]

        if RememberedLocations[index] != None && RememberedLocations[index].GetBaseObject() == XMarker  ;If the stored location data is a world location XMarker.
            RememberedLocations[index].Delete() ;Mark it for deletion.
        endif

        RememberedLocations[index] = RememberedLocations[nextIndex]
        index = nextIndex
    EndWhile

    RememberedItems[currentIndex] = None    ;Clear the top item of the stack.
    RememberedLocations[currentIndex] = None
    DecrementCurrentIndex()
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
    if RememberedItems[currentIndex] == None    ;If the stack is empty.
        currentIndex = RememberedItems.Length - 1   ;Reset currentIndex so the next item remembered is at 0.
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
            newStackSize = maxRemembered
        endif

        int rememberedCount = CountRememberedItems()    ;Count the number of slots we currently have filled.
        if rememberedCount >= newStackSize  ;If the currently occupied slots match or overflow the stack size.
            i = newStackSize - 1                ;Then we start our stack at the highest allowed position.
        else                                ;If the currently occupied slots don't fill the new limit.
            i = rememberedCount - 1             ;Then we start our stack as high as needed to accomodate all slots.
        endif
        int newCurrentIndex = i

        While i >= 0
            newItems[i] = RememberedItems[currentIndex]
            newQuantities[i] = RememberedQuantities[currentIndex]
            newContainers[i] = RememberedLocations[currentIndex]
            DecrementCurrentIndex()
            i -= 1
        EndWhile

        RememberedItems = newItems
        RememberedQuantities = newQuantities
        RememberedLocations = newContainers
        currentIndex = newCurrentIndex
    endif
EndFunction
