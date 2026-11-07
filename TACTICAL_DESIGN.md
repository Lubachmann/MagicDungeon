# MagicDungeon 0.4 — decisions inside a run

This revision develops the existing first-floor playtest and five-floor game. It adds combat choices and encounter variation without adding another currency or a starting class. Existing 0.2/0.3 Continue saves retain their original run rules; start New Run to use 0.4. Ember Tree purchases and the 0.3 investment refund remain compatible.

## Combat

Equip Guard, Interrupt or Mend outside combat by clicking the ability button or pressing the bound Ability key (F by default). All three are available from the first attempt. Switching is free outside combat; the equipped ability is locked during an encounter. It has one use per encounter, with no consumable cost.

- **Guard** blocks the next enemy strike's damage, preserving any acid shield. It does not stop a regrowth heal or the hex status itself.
- **Interrupt** delays the next enemy strike by 1.5 simulation seconds and cancels that strike's special effect/multiplier. Using it before an ordinary strike still consumes the charge; time it for a prepared attack.
- **Mend** heals `clamp(round(maxHP * 0.2), 6, 12)` and removes a hex, while resisting the next hex. This makes using it at the prepared-attack pause useful without requiring a fast reaction afterward. Healing cannot exceed maximum HP.

Ordinary enemies prepare a special on strikes 2, 5, 8, etc.; bosses on strikes 3, 6, 9, etc. In the final floor these become every second strike. While an unused ability remains, reaching a special pauses simulation before the attack resolves. Press F/click the ability to act, or Enter/controller A/click Continue to accept it and retain the ability for later. Once spent, warnings remain visible but no further mandatory decision pauses occur. Escape still pauses at any time. Combat runs at 1.25 simulation seconds per wall-clock second, versus the previous 2x pace. The forecast intentionally spends no ability; after a manual action it forecasts the remaining actual state. Hovering consumes neither world RNG nor encounter crit rolls.

Enemy types now matter beyond raw stats:

- Mosslings: prepared bite has 1.3x power and restores 4 enemy HP. Interrupt prevents both effects.
- Iron husks: retain their opening shield, then prepare 1.8x crushing blows.
- Needle bats: prepared bite has 1.3x power and hexes the next three player weapon strikes to 75% power. Mend cleanses the hex.
- Wardens: prepared onslaught has 1.8x power, layered with their plate/rapid attacks/bounded regeneration and half-health rage.

Telegraph, charge use, hex duration, shields, interruptions and attack clocks survive Continue. The run summary counts ability uses. The keyboard binding migration preserves existing custom bindings even when a player already used F for another command. Controller L3 uses/cycles the ability; controller A resumes a pending attack.

## Elemental relics

Four new level-up relics each grant a matching elemental rank as well as a behavior:

- **Wildfire seed:** a burning combat kill deals `8 + 4 * fireRank` damage to enemies within Manhattan distance 2. No armor reduction, no recursive chain explosions. Victims killed by the blast award normal XP/embers once. Burn must still be active at death.
- **Winter bell:** the third successful chilling weapon hit disrupts the next enemy strike and delays it 1.5 simulation seconds, once per encounter.
- **Vitriol shell:** when acid removes all of an originally armored enemy's remaining armor, gain a shield of `6 + 2 * acidRank`, once per encounter. Shield absorbs damage before HP and is not a permanent stat.
- **Plague vessel:** winning a poisoned encounter carries an extra 10 percentage points of weakening into the next fight, including its opening attack. Total poison weakening remains capped at 65%. The carried charge is consumed when combat starts; it can be earned again by the next poisoned victory.

Existing relics, elements, critical hits and equipment formulas remain available. These are four distinct build directions rather than additional elemental currencies or skill trees.

## Optional encounter pool

Each new floor selects two different encounters from four possibilities (six possible pairs):

1. **Distant copper key:** one early chest is locked; the unique key is at least two non-water room connections away and reachable without opening treasure.
2. **Sun/Moon seal:** two reachable braziers open the Fountain chamber's chest, Sun before Moon. The fountain stays usable. Wrong order causes no damage.
3. **Rune reliquary:** everyone can read the inscription and solve the three-glyph order. One of three pre-rolled equipment rewards can be claimed. Runic Sight reveals the first glyph and improves the amulet option from Rare to Very rare with critical/health affixes. A purchased skill never buys basic permission to solve the puzzle.
4. **Bloodbound chest:** an optional gilded chest asks for either 8 current HP or 4 current-run embers, then gives its fixed normal gilded reward. HP payment cannot kill or reduce maximum HP. Price is presented before payment; leaving is free. If guarded, the guardian must be defeated before payment is offered. Opening/paying cannot be repeated.

Unselected encounter entities/locks are absent. Other chests retain the existing guarded, winding, wall, water, nook and stash approaches. Not all discoveries demand a riddle. Runes, keys and paid rewards avoid mandatory corridors. Ordinary stashes also avoid the central cross, fixing a rare case where a chest could obstruct a room's exit. Placement checks and tests treat all treasure as locked when checking mandatory door access.

## Five floor identities

| Floor | Place / boss | Rule |
| --- | --- | --- |
| 1 | Fallen Keep / Iron Castellan | Learn the three enemy intentions; no extra environmental modifier. |
| 2 | Drowned Archive / Tide Regent | Waterlogged enemies take 0.5 simulation seconds longer to make their opening attack. |
| 3 | Ashen Crypt / Ash Abbot | Player burns last one additional simulation second. |
| 4 | Shattered Foundry / Furnace Knight | Every successful player weapon strike removes one point of enemy armor; opening shield blocks do not strip it. |
| 5 | Eclipse Sanctum / Eclipse Sovereign | Enemies prepare specials every second strike. |

Floor art uses the existing licensed keep/archive/crypt sets. The later bosses reuse those visual families and existing boss traits with their new floor rule; this is not five wholly new sprite sets.

First-floor boss tuning: take the previous generated health and multiply by 0.75, rounded up; reduce generated attack by 4 and armor by 2. Thus a depth-four first-floor Castellan has **93 HP, 13 attack and 10 armor**. Basic enemies retain the 0.3 harder baseline. Later floors retain their previous floor/depth stat scaling. Permanent investment never scales enemies upward. There is no forced-loss counter or requirement to purchase a skill before winning.

An automated witness can beat the first boss using level 3, a common level-3 sword (the floor's two iron upgrades), common level-1 armor/shield/helmet, Frost prism and Venom veil, with no permanent upgrades, and Guard at the first prepared onslaught. This demonstrates combat viability for that build, not a full-run route proof or a measured player clear rate.

## Validation and next playtests

The tactical suite checks 500 generated floors, all six encounter pairs, all five floor rules, ordinary door reachability with every treasure locked, boss approaches, ability effects/limits, shield interactions, elemental behaviors, fresh-character rune access, payment safety, fixed one-time loot, binding migration and pending-decision Continue. Existing suites cover combat forecasts, equipment, traversal, treasure odds, legacy saves and boss access. The 0.3 progression suite explicitly exercises the retained 0.3 rules.

The design follows the previously discussed emphasis on readable decisions. [Subset Games describes Into the Breach's telegraphed attacks](https://www.subsetgames.com/itb.html); MagicDungeon adapts the clarity, not that game's combat. The Ember Tree rationale remains documented with the [Hades](https://www.supergiantgames.com/blog/hades-welcome-to-hell-update-patch-notes/) and [Rogue Legacy 2](https://news.xbox.com/en-us/2022/04/29/rogue-legacy-2-tips-and-tricks/) sources in PROGRESSION_DESIGN.md.

Next evaluation is observation, not another progression layer: can a new player explain a prepared attack, choose an appropriate response, recognize an elemental effect, and find their way back to a discovered lock? Record first-floor reach, cause of death, ability use and perceived fairness over several attempts. [Steam Playtest](https://partner.steamgames.com/doc/features/playtest) is a later distribution option. No telemetry, account, upload or Steam publishing is added by this build.
