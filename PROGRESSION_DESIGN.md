> Historical 0.3 design. The 0.5 expanded tree, characters and replay systems are documented in LEGACY_REPLAY_DESIGN.md.

# Ember progression and dungeon threads — 0.3

**0.4 update:** See TACTICAL_DESIGN.md. New runs select two optional encounter types; basic rune vaults are open to everyone. Runic Sight reveals a clue and improves one reward. The fixed three-encounter pattern and paid access described below apply to retained 0.3 Continue runs.

## Research informing the change

Supergiant's [Hades update notes](https://www.supergiantgames.com/blog/hades-welcome-to-hell-update-patch-notes/) describe changes to Mirror costs, permanent pickup upgrades, unlockable chambers, and Fated Authority. The useful principle here is that repeated attempts can fund new options and world interactions as well as small stat gains. MagicDungeon uses that principle with its own tree, run snapshots and equipment infusion system; it does not copy Hades' combat or content.

The official [Rogue Legacy 2 tips article](https://news.xbox.com/en-us/2022/04/29/rogue-legacy-2-tips-and-tricks/) discusses an initially demanding game, Manor investments, progression outside simple stat purchases, and learnable challenges. MagicDungeon now gives the player several independent upgrade branches and a free full respec, with build decisions continuing inside the run.

Joris Dormans' [Level Design as Model Transformation](https://www.pcgworkshop.com/archive/dormans2011design.pdf) describes lock/key relationships and the value of encountering a lock before its key. The adaptation here is an early chest with a key in a physically reachable distant room. Dependencies are generated explicitly and tested, rather than placing unrelated locks and hoping the seed is solvable.

These are design inferences, not a claim that the new balance has been validated by Hades/Rogue Legacy's developers or by external players.

## Class-free runs

There is no starting class or favored relic. Every new run starts with a common level-one balanced sword, no elemental ranks, and the same base attributes. Equipment drops, level-up relic choices, iron, infusions, routes and permanent utility unlocks shape the build. The old starting-build selection is removed.

The title offers New Run, Continue, Ember Tree, Settings, tutorial and the first-floor playtest. A confirmation only appears when starting a new run would replace an existing Continue save.

## Ember Tree

Spend banked embers between runs. Prerequisites are single-rank parent unlocks. Branches are not mutually exclusive. Resetting refunds exactly what was spent, with no fee. Purchases apply to new runs; Continue retains that run's frozen skill snapshot.

| Node | Cost by rank | Parent | Effect |
| --- | --- | --- | --- |
| Kindling | 4 | None | +4 max HP and opens branches |
| Vigor | 6 / 10 / 14 | Kindling | +4 max HP per rank |
| Cartography | 6 | Kindling | Reveal adjacent chamber roles; resource details still need exploration |
| Tinkering | 6 | Kindling | First iron pickup each floor gives one extra iron |
| Flaskcraft | 12 | Vigor | Flasks restore 33 rather than 25 HP |
| Runic Sight | 14 | Cartography | Access optional rune reliquaries |
| Relic Lens | 14 | Tinkering | One relic-offering reroll per floor |
| Second Wind | 30 | Flaskcraft | One fatal-strike revival per run at 25% max HP |
| Recall | 18 | Runic Sight | One return to the entrance per floor, outside combat |
| Rune Forge | 22 | Relic Lens | Choose an item infusion at a forge for 1 iron and 4 run embers |

A reroll excludes the current choices when sufficient alternatives exist. It cannot be spent when three or fewer unowned relics remain. Charges and the new choices persist through save/Continue.

## New-run difficulty

Base health is 48, unarmed attack 9, armor 1, speed 1.0 attacks/sec and critical chance 5%. The starter sword adds 5 attack, for 14 total. Enemies get 10% more generated HP and +1 attack compared with the preceding prototype's floor/depth formula. There is no enemy scaling based on purchased skills, bank size or number of attempts.

Permanent raw-stat growth is limited to 16 maximum HP across Kindling and all Vigor ranks. Most nodes create choices, exploration access or resource utility. A first unsuccessful run can collect enough for the four-ember root through an enemy and starting treasure. The intent is a demanding beginning with visible progress, not forced losses or concealed forecast errors. Actual clear rates and run length still need human playtests.

## Optional dungeon dependencies

Every new-rule floor has:

- An early copper-locked chest. Its unique key is at least two non-flooded room connections away. The key never spawns behind that chest, a paid gate or another chest. Opening consumes it once.
- A Sun/Moon seal on the Fountain chamber's chest. Light the Sun brazier in the Hammer chamber, then the Moon brazier at the Forge. A wrong order gives feedback without taking health. The fountain itself remains usable.
- A sealed reliquary in the Armory. Runic Sight grants access. A generated inscription specifies the order of Flame, Moon and Ivy glyphs. Wrong inputs reset progress without damage. Solving offers three fixed equipment choices; exactly one can be collected, plus six embers.

All these rewards are optional. They never alter the mandatory room graph or put a paid skill gate in the boss corridor. Markers avoid the central cross and door landings. Placement checks preserve access to keys, switches and basic resources even while reliquaries remain sealed.

Map notes: K key, L locked chest, R reliquary, Sun/Moon braziers. Resource markers describe remaining objects in visited chambers. Journal shows held key, revival and Recall charges. R recalls if unlocked, or use the journal button.

## Infusions

Infuse any owned item while beside a forge. Spend one iron and four current-run embers, not banked embers. Replacing an infusion pays the same cost; there is at most one infusion per item. Its numeric value is recalculated with item level n = level − 1, independent of rarity, and added to the item's normal stats:

| Choice | Added effect |
| --- | --- |
| Fire | 1 + 0.5n fire DPS |
| Ice | 5% + 1%n slow |
| Acid | 0.5 + 0.25n armor stripped per hit |
| Poison | 5% + 1%n damage weakening |
| Critical chance | 5% + 1%n |
| Critical multiplier | 0.15 + 0.025n |

Existing aggregate combat caps still apply. Iron upgrades increase the effect because level remains the source of truth. The infusion menu previews the resulting item stat before purchase.

## Save migration

Old three-stat investments are refunded as embers: a legacy stat at rank L returns 3L² + 5L, the exact sum of its prior purchase prices. New profiles use version-three permanent JSON data. The complete run save retains its checksum/backup envelope and now includes profile skills, frozen run skills, keys, seal flags, puzzle progress/rewards, infusions and utility charges.

An existing pre-0.3 Continue run keeps its old baseline and legacy stat effects until it ends. Its investment is refunded once for future tree purchases. New runs use the harder class-free rules. Buying or resetting the tree while a Continue save exists updates only the profile in the checkpoint; its run skill snapshot stays unchanged.

## Verification

`tests/ember_exploration.gd` exercises tree prerequisites/caps/costs/refunds, profile and active-run separation, migration idempotence, 500 generated floors, distant and reachable key sources, paired seals, skill gates, puzzle save/restore, one-time reward claims, level-scaled infusions and revival forecast agreement. Existing traversal and boss-access tests remain in place. These checks validate rules and reachability; they do not replace external balance playtests.
