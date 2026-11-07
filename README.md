# MagicDungeon

Open `project.godot` in Godot 4.6 and press F5.

Explore five procedural floors to recover the dying sanctuary flame. Find people, manuscripts and boss fragments; discoveries return to the Hearth even if you die. Find equipment and iron, gain temporary levels, and spend earned embers on permanent upgrades between runs. The player starts unarmed and finds a random weapon in the first room. Equipment and levels are lost when the run ends.

Move with the arrow keys or WASD. E opens Equipment, C opens the journal, and hovering over the map icon shows the map. The equipment pickup window compares the found item with the worn item: press 1 to equip it or 2 to keep it in the bag. Settings lists remappable controls and audio/accessibility options.

The equipment screen shows current and prospective total stats when an item is selected; its item-stat view shows the equipment's own bonuses. Your Build shows combined stats and acquired skills. Forge actions are available in Equipment while near a forge. A rest site provides a place to recover during a floor. The west door in each floor’s starting room leads to an optional side passage: choose an armory, an elemental chamber, a dangerous vault, or a restful passage. Only one side passage can be chosen on each floor.

`PLAYTEST_GUIDE.md` contains the current external-test brief. `ASSET_CREDITS.md` records asset licenses. The other design documents describe earlier iterations and may contain historical mechanics; use the game and current playtest guide as the source of truth for present behavior.

Run a regression script with `Godot --headless --path . --script res://tests/onboarding_controls.gd`, or use the other scripts under `tests/`.

## The Last Hearth

Choose **Hearth** on the title or run-end screen to visit the sanctuary. Find Mara, Iven and manuscripts in the dungeon; discoveries and Warden fragments are carried home at the end of a standard run, including after death. Their unlocks apply to the next run. The Hearth journal shows the locations and rewards. Reaching the final exit presents a story choice, and a victory still unlocks the existing Endless and Vow modes.

Existing characters retain their previous unlocks; their sanctuary starts with the discovery-based options available. Standard new characters begin with the ordinary weapons, equipment and skill pool, with four advanced elemental skills unlocked by manuscripts. The existing Ember Tree remains available; Tinkering now adds a defensive-item choice to Mara's armory service.
