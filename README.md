# MagicDungeon

Open `project.godot` in Godot 4.6 and press F5.

Explore five procedural floors to recover the dying sanctuary flame. Start an expedition with equipment crafted at the Hearth. Enemies drop monster parts, ore deposits yield ore, and chests hold permanent equipment blueprints. Rare and Very rare designs appear on later floors and require Guard alloy (guards, floor 2+), Imp essence (imps, floor 3+) or Mire gel (slimes, floor 4+). Warden cores come from bosses. Crafting and upgrades are guaranteed when their material costs are paid. The player keeps blueprints and materials after leaving, dying or winning. At the smithy, craft equipment and upgrade the five shared equipment slots. Every item in a slot benefits from its slot level. Before every new expedition, review and select your loadout in the separate equipment screen. Dungeon levels and skill choices reset when an expedition ends. Return safely from the entrance of any floor, or continue deeper for greater rewards.

This experimental branch is a work in progress: secondary systems, interface text and balance are still being adapted.

Move with the arrow keys or WASD. E opens Equipment, C opens the journal, and hovering over the map icon shows the map. Equipment is chosen on the preparation screen and stays fixed during the expedition. The Smithy is accessible from the main menu or the Hearth. Settings lists remappable controls and audio/accessibility options.

The equipment screen shows current and prospective total stats when an item is selected; its item-stat view shows the equipment's own bonuses. Your Build shows combined stats and acquired skills. Discover elemental rune blueprints in elemental passages; the Hearth smithy can apply them to crafted gear. A rest site provides a place to recover during a floor. The west door in each floor’s starting room leads to an optional side passage: choose an armory, an elemental chamber, a dangerous vault, or a restful passage. Only one side passage can be chosen on each floor.

`PLAYTEST_GUIDE.md` contains the current external-test brief. `ASSET_CREDITS.md` records asset licenses. The other design documents describe earlier iterations and may contain historical mechanics; use the game and current playtest guide as the source of truth for present behavior.

Run a regression script with `Godot --headless --path . --script res://tests/onboarding_controls.gd`, or use the other scripts under `tests/`.

## The Last Hearth

Choose **Hearth** on the title or run-end screen to visit the sanctuary. Find Mara, Iven and manuscripts in the dungeon; discoveries and Warden fragments are carried home at the end of a standard run, including after death. Their unlocks apply to the next run. The Hearth journal shows the locations and rewards. Reaching the final exit presents a story choice, and a victory still unlocks the existing Endless and Vow modes.

Existing characters retain their previous unlocks; their sanctuary starts with the discovery-based options available. Standard new characters begin with the ordinary weapons, equipment and skill pool, with four advanced elemental skills unlocked by manuscripts. The existing Ember Tree remains available; Tinkering now adds a defensive-item choice to Mara's armory service.
