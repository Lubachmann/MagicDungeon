# Enemy and equipment progression (run rules 16 and later)

New runs start unarmed. The first room has one reachable chest containing an equally likely sword, dagger, axe, greatblade or ember blade. With no Quartermaster ranks it is a plain common level-1 weapon; Quartermaster upgrades its rarity and level as described in the Ember Tree. The first room no longer has a weapon-choice cache. Existing runs retain their saved rules.

## Enemy levels and experience

Each floor has six levels: floor 1 has 1–6, floor 2 has 7–12, and so on. The starting enemy is level 1. Other levels are rolled using room depth; guardians tend to be stronger. Enemy types and special abilities can change actual danger even at the same level. Bosses are exceptional enemies and have their own health and attacks.

For an ordinary enemy at level E, let n = E − 1. Before type and encounter modifiers, health is rounded up from `12 + 13n + 0.5n²`, attack is `3 + n + 0.1n²` (rounded up by the combat setup), and armor is `0.5n`. XP remains `10 + 15n`. These are quadratic curves. Run-rules-15 saves retain the previous formulas.

A boss uses the level of the highest ordinary tier on its floor. With f = floor number − 1, boss health is `220 + 190f + 45f²`; base attack is the greater of 11 or `1.2 × (3 + n + 0.1n²) − 2`, rounded up. Boss armor is `0.5n + 0.5f`, plus 3 for an iron boss. Bosses retain their signature abilities. These curves keep the first boss close to its former strength and grow later bosses relative to other enemies.

Ordinary enemies give `10 + 15(E − 1)` XP, including extra room enemies; bosses give twice that. XP to advance from character level L is `40 + 60(L − 1) + 10(L − 1)(L − 2)`. Four level-1 enemies give the 40 XP needed for level 2. Level 3 needs another 100 XP: ten level-1 enemies or four level-2 enemies. Unspent XP carries over.

Each character level adds 8 maximum HP (also restoring up to 8 HP), 1 character attack before the weapon's power multiplier, and 0.35 armor. Level-up skill choices and equipment are separate.

## Equipment

Items use their current level, so iron upgrades use the same formula as items found at that level. With `n = item level − 1`:

- A common shield has `2 + 3n` armor: 2 at level 1, 5 at level 2.
- A common sword has `9 + 3n` item attack: 9 at level 1, 12 at level 2. Dagger, axe, greatblade and ember blade growth is adjusted for their attack intervals and character-power multipliers.
- Common armor has `3 + 3n` armor and `9 + 4n` maximum HP, before light/heavy class modifiers. Helmets have `1 + 1.5n` armor and `6 + 3n` HP.
- Common and rare items have the same primary-stat multiplier; rare items add an affix. Very rare items multiply primary stats by 1.18 and add two stronger affixes. Focused amulets, affixes, runes, weapon traits and armor classes have their own additional effects.
- Base loot level is `1 + 2(floor − 1)`; certain rewards add one level. Elemental equipment affixes gain another rank every two item levels.

The forge-room chest is now another optional guardian chest, using higher-tier reward odds. The guardian-weakening rune no longer generates in new runs; its saved state and behavior remain available to older runs.

The numbers above are a starting balance, not a measured win-rate guarantee. Run length, survival and build variety need player testing over complete runs, including empty-tree characters and all five starting weapons.
