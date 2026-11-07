# MagicDungeon 0.11 — Playtest feedback

## Starting gear and equipment readability

New runs begin with no equipment. Base attack is 9 before permanent upgrades. The entrance cache remains reachable before combat and offers two level-1 weapons. Equipping your first weapon now adds its full attack bonus. Unarmed characters do not get the sword's shield passive. Existing saved equipment is preserved; start a new run to test the change.

Treasure pickups show the item's own bonuses on the left and whole-build totals before/after equipping on the right. Equipment opens on the item's own stats by default; Show build impact switches to combined totals. Weapon identity details remain available by hovering the item art. Speed bonuses are shown as modifiers on items; the resulting attack interval remains visible in the build comparison. Critical damage bonuses use %.

## Candles

Sun/Moon candles are an optional chest puzzle:

1. Step onto SUN in the Hammer room.
2. Step onto MOON in the Forge room.
3. Return to the Fountain room's chest.

They do not cost a key or health. Their labels now show order and whether they are lit. Hover text and interaction messages explain the reward and destination. The map shows current candle progress, or says that this floor has no candle seal. Healing runes are a different interaction, marked RUNE: disable guardian healing or leave it active for better loot. Misleading flask-shaped floor clutter was removed.

## Combat feedback

Every enemy has a small health bar. In combat, it follows actual remaining HP and briefly shows the chunk removed by a hit.

Heavy hits and criticals add 25–55 ms of hit pause; both combatants pause together. They do not change the simulation's event order, damage or random rolls. The dungeon shakes by at most 4 design pixels, while the HUD remains still. Shake strength, recoil and damage-number size grow with hit damage and saturate at a readable limit. Strong hits have a layered impact sound. Critical numbers are larger and gold; burns are smaller and orange. Floating numbers render behind character sprites. Kill particles persist briefly after a fight.

Reduced effects disables hit pauses, camera shake and particles while retaining health bars, readable numbers, level-up text and rewards. No global time scale is changed.

The approach was informed by Lin et al.'s impact-feedback study, especially its discussion of hit stop, coherent sound and camera feedback: https://arxiv.org/abs/2208.06155 . These are design choices for this game, not a claim to reproduce another game's timings.

## Flasks, bombs and rewards

Flasks and bombs now have 48-pixel icons, larger count labels and bigger controls. A usable flask gets an extra outline when health is low. H heals between fights; B aims a bomb between fights. Combat remains automatic.

After a kill, a RECENT strip shows actual XP and embers gained, plus any Forager flask drop. Rapid consecutive kills are grouped into recent gains; the strip lasts 4.5 seconds after the latest reward. It is also visible on an immediately following upgrade screen.

## Level-up choices

The choice screen explicitly announces LEVEL UP, with a short border animation and sound. Current elemental stacks remain visible while comparing an upgrade. The side panel shows NOW / GAIN / AFTER, including effects such as maximum armor removal and the shield added by Vitriol shell. For example, Acid 2 + 1 becomes 3, the removal limit becomes 12 and the armor-break shield is 12.

Ability icons show current relics plus the proposed new one, outlined in green. Hover an icon for its name and explanation in the detail strip. Your full build opens the full overview; Back or Esc returns to the same pending choices. Candidate previews are pure calculations and match actual upgrades without changing HP, inventory or random rolls. Keyboard focus starts on a choice, not the full-build button.

## Doors and art

Room connections use an open-door sprite. Stairs are reserved for the floor exit and ascent presentation. The door and bomb are existing sprites from 0x72 DungeonTileset II, already used by this project, with CC0 licensing: https://0x72.itch.io/dungeontileset-ii . No new generated artwork was introduced.

## Verification

All 20 automated suites pass, including 65 new playtest-feedback checks, empty-inventory saving, all relic/blessing preview comparisons, pending-choice return, actual reward values, reduced effects and damage scaling. Earlier encounter tests use an explicit equipped-sword fixture where they need their original combat baseline; separate new-run tests verify that real players start unarmed. Generation, boss access, progression, save restoration and existing build systems still pass.

Native Mac review covered the level-up comparison, ability icons, reward notification, raw equipment bonuses beside build totals, the unarmed HUD, consumable controls, doors, enemy health bars and live damage feedback. Windows is exported and archive-checked, but has not been played on a Windows machine here.
