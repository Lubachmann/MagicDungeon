# MagicDungeon 0.9 — Builds, exploration and preparation

The loop is now more deliberate: explore for useful loot, prepare for a difficult encounter, and use that reward to strengthen the build. The Ember Tree remains the expected source of permanent progression. Victory is not artificially locked behind buying a skill.

## Designed rooms

Four authored formations replace random scattered cover: Pillar Court, Broken Shelves, Twin Barricades and Side Galleries. Roles select appropriate formations; the existing chest detours, guarded passages and boss arenas remain. Formations are placed as complete groups and rejected if they break existing or future routes through ability gates. Small rooms use authored pillar anchors. Existing already-dense rooms do not have to gain extra walls.

## Preparation decisions

- Healing runes power optional treasure guardians. Find the rune in another room and disable its bonus healing, or defeat the guardian while powered to upgrade its pre-generated reward to Very rare gear with +1 item level. Disabling is an explicit choice. The reward cannot be rerolled by inspecting or reopening the choice.
- On floors with a Copper key, a supply stash offers 1 flask + 1 iron for that key. The key is shared with the locked treasure chest: opening either consumes it, so the other reward is lost.
- After the puzzle achievement, build caches can appear on floors 2 and above. Choose one of two fixed Rare elemental items. The other item is discarded.

These choices occur before combat. Automatic fights continue without timed ability prompts. Choices can be left for later and survive save/Continue.

## Build achievements

Achievements are per character and persist between runs. Trial runs do not contribute. Starting equipment stays unchanged.

| Goal | Unlock | Trade-off |
|---|---|---|
| Heal 60 actual HP with vampirism | Bloodletter dagger | No innate dagger evade; +5% vampirism at level 1, increasing by 0.1% per additional level |
| Win 15 fights using a greatblade | Winterblade | 15% less base weapon attack; +8% enemy slow at level 1, increasing by 0.1% per additional level |
| Defeat 3 bosses while they are burning | Caustic brand | 35% less item fire damage/s; removes 0.75 enemy armor/hit at level 1, increasing by 0.05 per additional level |
| Solve 3 rune puzzles | Build caches | A new exploration reward with a choice between elemental items |

Unlocks expand future loot options rather than giving starting-class bonuses. An unlocked matching weapon has a 35% chance to use its variant when rolled. Gear level and rarity still use the existing formulas. Iron recomputes variant stats from the resulting level; it does not compound the previous result. View progress through Build unlocks in Expedition or the Chronicle. Daily uses the same complete variant/event pool for everyone, independent of profile achievements.

## Fight previews

Estimated previews are the default: Favorable, Dangerous or Deadly, plus an approximate HP-loss range. Seven private future-roll samples produce the estimate. The label is not a guarantee. Inspecting consumes no world RNG and changes no actual combat state. Results are cached until the inspected combat state changes. Settings offers exact forecasts for players who prefer the previous preview.

## Playtest tools

Settings can export a local JSON playtest report and open its folder. Reports include recent completed runs and an active-run snapshot: seeds, equipment, relics, elements, tree ranks, preparation decisions, damage and outcome. No character name, account data or full world/save file is exported. Nothing is uploaded automatically.

See the playtest guide for the proposed 5–10 person test. Recruiting and observing those people still requires the developer; automated tests cannot establish whether the game is enjoyable.

## Compatibility and validation

Existing profiles and active runs remain compatible. Old achievement progress begins at zero because earlier versions did not record these actions. New room formations and preparation encounters appear on newly generated floors. Start a new run to see them immediately. The forecast setting and report export are available immediately.

Checks cover room and boss access, save/Continue during choices, shared-key spending, rune regeneration/counterplay, fixed rewards, profile achievements, variant level upgrades, Daily fairness, stable estimates and local report export.

## Future design proposal

For eventual wins with an empty Ember Tree, test positional openings: visible enemy facing, useful terrain and different approach routes that grant an advantage before the automatic fight. This would reward planning without reintroducing mid-fight reaction buttons. It is a proposal for a later iteration, not an implemented zero-tree victory route.
