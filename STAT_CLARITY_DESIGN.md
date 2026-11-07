# MagicDungeon 0.16 — Stat clarity

## Implemented

- Cinder Shrine weapon upgrades now preview the weapon’s own stats and the resulting build before accepting. The build includes both the current-health payment and the maximum-health sacrifice, including any health gained from leveling the weapon. Both comparisons have pages when needed.
- Important exploration messages appear in a prominent banner with a brief upward pop. Blocked actions stay visible for 5 seconds, play a cue, and are protected from being overwritten by ordinary movement messages. Reduced-motion settings disable the pop.
- Physical damage reduction is removed from equipment comparisons. It remains available in Your Build’s Armor details. Armor itself remains in comparisons.
- Shared pixel stat icons replace stat labels in item, comparison, upgrade, starter, infusion, build and enemy panels. Hover a stat icon for its name and explanation. Numeric values retain their units: seconds, %, /hit or /s.
- Character attack scaling has its own strip below weapon stats. Hover it for the formula and an example: character attack × weapon multiplier + weapon attack. It is no longer presented as an ordinary additive equipment stat.

These UI improvements apply to current saves. This release does not change combat rules, equipment growth, currency, permanent upgrades or the first boss’s stats.

## First-floor balance investigation — proposed next work

A controlled empty-tree probe ran 960 first-boss encounters: three starter archetypes, five preparations, with/without a bomb, and 32 combat seeds each. It assumed level 3, full health, common level-2 gear, Ward, one matching elemental relic and a free imprint. These preparations are generous and are not guaranteed in actual runs. This tests encounter/build behavior, not whole-run success rates.

Poison preparations won all tested encounters. Without a bomb, comparable physical, fire and acid preparations almost always lost; frost passed reliably only with daggers. The boss currently favors a narrow set of builds. The JSON supplied with this release contains the full results; the reproducible script is tools/first_floor_probe.gd.

Recommendation: add a reachable optional preparation encounter that weakens the boss’s guard or armor, then tune the first boss against several ordinary empty-tree builds. This makes exploration a deliberate way to prepare. More random loot alone would retain the same luck dependency. No balance adjustment has been applied in 0.16.

## Currency recommendation — not changed

Keep the name Ember, which fits permanent progression and the Ember Tree, and replace the gold coin art with a recognizable glowing coal. Renaming it Gold would fit a conventional shop economy but lose that connection.

## Verification

All 28 regression suites passed, including 51 new stat-clarity checks. Shrine preview purity and parity with the actual upgrade transaction are tested. Native macOS visual checks covered shrine comparisons, icon tooltips, loot and the blocked-action banner using an isolated test save. Existing player profiles were not used for testing.
