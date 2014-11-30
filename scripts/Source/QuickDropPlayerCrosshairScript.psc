Scriptname QuickDropPlayerCrosshairScript extends ReferenceAlias
{QuickDrop player script for tracking OnCrosshairRefChanged events.}

QuickDropQuestScript Property QuickDropQuest Auto
{The QuickDrop main script.}

Form Property XMarker Auto
{An XMarker, for use in marking world replace locations.}

Event OnInit()
	RegisterForCrosshairRef()
EndEvent

Auto State Enabled
	Event OnCrosshairRefChange(ObjectReference crosshairRef)
		{When the player focuses on an object, move the XMarker reference, or create a new one if it doesn't exist.}
		GoToState("Disabled")

		if QuickDropQuest.locationXMarker != None
			QuickDropQuest.locationXMarker.MoveTo(crosshairRef)	;If we have an XMarker already, move it here.
		else
			QuickDropQuest.locationXMarker = crosshairRef.PlaceAtMe(XMarker)	;Otherwise, create a new XMarker and place it here.
		endif

		GoToState("Enabled")
	EndEvent
EndState

State Disabled
	;Don't listen for OnCrosshairRefChange when disabled.
EndState