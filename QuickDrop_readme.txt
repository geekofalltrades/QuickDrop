TITLE: QuickDrop

VERSION: 2.0

AUTHOR: geekofalltrades

RELEASED: December 30, 2014 at Skyrim Nexus

REQUIREMENTS:
  * SKSE
  * SkyUI v4.1

UPDATING FROM 1.0 TO 2.0:
  BEFORE STARTING A NEW GAME: Uninstall version 1.0 of QuickDrop, and install version 2.0. See
  installation and uninstallation instructions below for details.

  ON AN EXISTING SAVE: I do not recommend updating your QuickDrop version on an exsting save. If you are
  willing to risk damaging your save, try following these steps:

    1. Back up your save.
    2. Back up your save!
    3. In-game, open your console and enter "stopquest QuickDropQuest".
    4. Save your game and exit Skyrim.
    5. Uninstall QuickDrop.
    6. Open your save in Skyrim. Skyrim may display a message complaining about missing content.
    7. Save your game and exit Skyrim.
    8. Install QuickDrop 2.0.

  If you have trouble with the new version after following these steps, you could try restoring your old save
  from the back-up and starting over, and additionally using a savegame script cleaning tool in between steps
  5 and 6. Again, I do not explicitly recommend any of this, and cannot support you if anything goes wrong:
  Skyrim's script engine is famously finicky.

INSTALLATION: Either install with Nexus Mod Manager, or place QuickDrop.esp and QuickDrop.bsa in your
  Skyrim/Data directory.

UNINSTALLATION:
  BEFORE STARTING A NEW GAME: If installed with Nexus Mod Manager, deactivate or delete with Nexus Mod Manager.
  Otherwise, remove QuickDrop.esp and QuickDrop.bsa from your Skyrim/Data directory.

  FROM AN EXISTING SAVE: I do not recommend uninstalling QuickDrop from an existing save. Instead, unbind all
  hotkeys, run the "Clear Remembered Location Data" command in the General Settings menu, and turn off
  "Remember New Items" in the General Settings menu. This will effectively disable the mod, and you can then
  uninstall it before starting your next game. If you are willing to risk damaging your save by performing an
  uninstall, try following these steps:

    1. Back up your save.
    2. Back up your save!
    3. Run the "Clear Remembered Location Data" command in the MCM General Settings menu.
    4. Wait 20-30 seconds, real time, in game.
    5. Follow steps 3-7 in the "UPDATING: ON AN EXISTING SAVE" section above.

  Again, I do not explicitly recommend this, and cannot support you if anything goes wrong.

DESCRIPTION: Quickly decide whether to drop or keep the last few items you picked up with a selection of hotkeys.
  Use the MCM menu to decide how many items (from 1 to 10) to track, how to handle stacks of items when they're
  picked up, which notifications you'll receive, which keys are bound to the hotkeys, and whether to put items
  back in their original containers or locations. The MCM menu also displays a list of the items currently being
  remembered.

COMPATIBILITY: No incompatibilities known.

PERMISSIONS: Do not reupload this mod at sites other than Skyrim Nexus. If you alter this mod (by translating,
  adding functionality, etc) you may distribute it freely, so long as I am credited as its original author; in
  this case, I would prefer that it were made available at Skyrim Nexus. If you want to include this mod as
  part of a larger compilation, please contact me.

CORRESPONDENCE: For general questions, comments, complaints, compliments, musings, propositions, reticulations,
  etc, please post to this mod's thread on the Skyrim Nexus forums. To contact me directly, please send me a
  private message on the Nexus Mods website. My account name there is "thegeekofalltrades."

THANKS to Nexus Mods and to all contributors to the Creation Kit wiki and forums.

CHANGELOG:
  v2.0:
    * Fixed bug in case when "Remembered Items" slider was opened and closed with value of 10 and all stack slots
      full.
    * Implemented the forgetting of items when those items were removed from your inventory outside of QuickDrop.
    * Added the ability to toggle remembering of items on and off, both in-menu and with a hotkey.
    * Added the ability to remember items with persistent references.
    * Added the abilities to replace items in the world and in their original containers, plus accompanying
      configuration and notification options.
  v1.0:
    * Initial release.
