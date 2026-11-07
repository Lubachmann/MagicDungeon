# MagicDungeon 0.15 — elements, plain starters and Quartermaster

> Update: Frost, Acid and Poison power now apply counters per hit equal to power × weapon base interval / 2 seconds. Attack-speed bonuses increase hit frequency without changing the per-hit multiplier. Fire remains unchanged. Equipment lists raw elemental power; build and level-up previews show the resulting counters per hit. In-progress battles without the new multiplier retain their saved behavior until the fight ends.

Start a new run to use rules 9. Continued older runs retain their original elemental combat and equipment formulas. No progress reset is required. Existing Smithcraft purchases become Quartermaster ranks.

## Plain starting weapons

A character with no Quartermaster ranks still starts unarmed and chooses a weapon from the first-room cache. All three options are Common level 1 with no affixes and no innate weapon ability. Daggers have no innate critical-chance or evade bonus. Swords grant no ward, daggers no combo, and axes no cleave. Damage, weapon scaling and attack intervals remain distinct. The character's intrinsic critical chance is a character stat, not an item bonus.

Fresh, with no tree or run bonuses:

| Weapon | Item attack | Total hit power | Interval | Physical DPS before armor/crit |
|---|---:|---:|---:|---:|
| Sword | +9 | 14 | 2s | 7 |
| Dagger | +4.5 | 7 | 1s | 7 |
| Axe | +17.1 | 26.6 | 3s | 8.87 |

A plain weapon can later receive an elemental imprint. It keeps its plain weapon identity; the imprint supplies the new element. Normal dungeon weapons retain their archetype abilities, so finding another Common sword can still provide a useful new ability. Pickup and equipment views identify the weapon ability.

## Quartermaster in the Ember Tree

Smithcraft's node is now named Quartermaster, in its existing Arsenal location after Rune Forge. Its saved identifier, prices, purchased ranks and starting-iron benefit are preserved.

| Rank | Starter choices | Bonus | Starting iron |
|---:|---|---|---:|
| 0 | Common L1 | Plain; no innate abilities or affixes | 0 |
| 1 | Rare L1 | One elemental affix; normal weapon ability | 1 |
| 2 | Rare L2 | One elemental affix; normal weapon ability | 2 |
| 3 | Very rare L2 | Elemental affix + critical damage; normal weapon ability | 3 |

The upgraded sword offers Fire, dagger Poison and axe Acid. You still choose the weapon, and can shape its element later. Rank prices remain 220 / 550 / 1,050 embers. Changes apply to new runs.

## Shared elemental stats

Equipment, infusions and run upgrades contribute to the same four totals. Player stats show Fire burn damage/s and Frost, Acid and Poison applied per landed hit. Hover details explain potency, sources and mastery. Enemy inspection shows current counters, actual burn damage/s, poison damage/s, frost slow and acid exposure. Its armor number reflects corrosion. Long HP values no longer collide with attack values.

Mastery increases the associated elemental potency/application by 5% per rank. It does not create an element on its own. Upgrade headlines and before/after previews include this multiplier. Elemental run upgrades no longer stop at the old 3-stack limit.

## Fire — hit strength

Each landed weapon hit applies a burn snapshot: 10% of that hit's pre-armor power per Fire potency, per second, for 3 seconds. Criticals and hit-power bonuses can create stronger burns. Only the strongest active snapshot deals damage. Weaker hits never extend a stronger snapshot. Equal-strength hits refresh their own snapshot.

Burn ticks occur every 1 second, ignore armor and do not trigger vampirism. Cinder extends burns to 5 seconds and retains its every-third-tick bonus. The ember floor adds another second. Flare uses the current burn strength. Fire remains useful against the healing boss.

## Poison — repeated hits

Every landed hit adds the player's Poison application in counters. Each counter deals 0.5 damage every 0.5 seconds: 1 damage per second. Counters accumulate for that encounter and reset for the next. Poison ignores armor, does not weaken enemy attack, and does not trigger vampirism.

Venom veil starts the fight with twice the player's Poison application in counters. Plague vessel grants +1 Poison application for the next encounter after a poisoned victory. Poison ticks have their own feedback and damage accounting; they do not play weapon swing animations or cause physical impact pauses.

## Frost — control

Every landed hit adds Frost counters. Each counter slows attacks by 5%, up to 50%. At 10 counters, a freeze delays the next attack by 1 second, can interrupt a special, and leaves 5 counters. The normal freeze cooldown is 8 seconds; Winter bell reduces it to 4 seconds. Frost cannot repeatedly freeze during that cooldown. Slow changes rescale the remaining attack interval rather than resetting it.

## Acid — armor and exposure

Every landed hit adds Acid counters. Each counter removes 1 armor for following hits, down to 0. Corrosion beyond the remaining armor adds 1% physical hit power per excess counter, capped at +20%. This keeps acid useful against lightly armored enemies. Exposure does not increase burn snapshot power. Armor uses the uncapped diminishing-return curve introduced in 0.14.

## Equipment levels and infusions

New equipment uses balance version 4. Physical item growth remains unchanged. Element tiers are 1 + floor((item level - 1) / 4), increasing at levels 5, 9, 13 and so on. A Rare elemental affix adds that tier; a Very rare affix adds round(tier × 1.5). Ember blades innately supply Fire potency. An infusion adds one tier of its chosen element. Winterblade adds a tier of Frost; Caustic adds a tier of Acid and retains its Fire reduction. Iron recalculates the same formulas at the new level.

Each floor provides one free elemental imprint at a forge, without tree purchases or currency. Choose Fire, Frost, Acid or Poison for any carried equipment. It replaces that item's previous infusion while leaving its ordinary affixes intact. The free allowance is saved and resets on ascent. A forge is guaranteed on each floor. Rune Forge unlocks additional infusions for 1 iron + 4 embers, including critical stats, evade and vampirism. Forge cards explain each effect before selection.

## Validation and limits

27 regression suites passed. The dedicated elemental suite covers common starter stats and suppressed abilities, elemental gear totals and iron tiers, burn snapshots, poison timing/no vampirism, frost cooldown, corrosion/exposure, deterministic forecasts and save round trips, Quartermaster, and free-imprint limits/reset. Older-run behavior has a separate compatibility check.

A fixed-seed audit covers 960 first-floor encounters across three plain weapons, five elemental choices (including none), two enemy strengths and 32 roll seeds. Common defensive gear is provided equally to isolate each imprint. Plain weak encounters average 4.31–5.31 seconds; strong encounters 16.41–18.94 seconds. Poison particularly benefits daggers, Fire benefits heavy hits, and Frost reduces incoming damage without directly increasing strike damage. This is a controlled encounter audit, not a full-run or deep Endless balance guarantee.

Native macOS checks verified common starter cards, aggregate elemental stats, free imprint application with zero currency, upgrade previews, Quartermaster, and live counters with effective enemy armor. Windows packages are validated structurally, not played natively.
