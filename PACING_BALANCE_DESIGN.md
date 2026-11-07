# MagicDungeon 0.12 — Combat pacing and build progression

Start a new run to play these changes. Existing saved runs keep their old combat rules and item formulas. Profiles, earned embers, unlocks and the Ember Tree are preserved.

## Starting weapons

New runs remain unarmed, now with an attack interval of 2 seconds. The entrance cache offers one of three Rare level-1 weapons: a sword with a small fire bonus, a dagger with critical chance, or an axe with critical damage. These are equipment choices, not classes; you can change weapons later.

Fresh-character, common level-1 examples before enemy armor:

| Weapon | Interval | Normal hit power | Character-power multiplier |
|---|---:|---:|---:|
| Sword | 2s | 14 | 100% |
| Dagger | 1s | 7 | 50% |
| Axe | 3s | 26.6 | 190% |
| Greatblade | 2.8s | 23.1 | 165% |
| Ember blade | 2.2s | 11.9 + fire | 85% |

The multiplier applies to character attack, then item attack is added. This prevents the character's starting attack from making a fast dagger hit almost as hard as a slow sword. The item's own bonuses, character-power modifier, resulting build and actual interval are shown in the equipment/loot interfaces.

Daggers gain +4% base speed per item level after level 1. Axes gain substantially more item attack per level. Axes have a new identity: every third swing has +35% hit power. Swords keep their shield, greatblades keep guard breaking and armor removal, and ember blades keep fire flares.

Speed bonuses multiply weapon cadence rather than adding a flat attack rate. An equal speed bonus therefore preserves the difference between fast and heavy weapons. The old hidden 1.25x combat playback multiplier is removed in new runs: displayed seconds now match the combat clock, apart from the brief impact pauses. Opening attacks wind up for half a weapon interval, followed by full intervals; both combatants use the same shared clock.

## Opening benchmarks

32 fixed combat seeds per weapon/enemy pair. Characters are level 1 with no tree or relics. Weak encounters use a common level-1 weapon. Strong encounters also equip common level-1 shield, armor and helmet, and begin at full HP. No flask or bomb is used. These are controlled fight durations, not full-run guarantees. Impact pauses add a small amount of real time.

| Weapon | Weak enemy mean | Strong enemy mean | Wins in each test |
|---|---:|---:|---:|
| Sword | 4.75s | 18.94s | 32 / 32 |
| Dagger | 5.13s | 18.19s | 32 / 32 |
| Axe | 4.31s | 16.22s | 32 / 32 |

A character without defensive equipment can lose the strong encounter. The longer fight is meant to make preparation, defense, healing and build choices matter.

## Health and floor scaling

New starting HP is 80, compensating for longer encounters. Character levels grant +3 max HP, +0.35 character attack and +0.15 armor. Weapon and armor item growth is slower, and Very rare gear gives +18% primary stats and 1.5x affix strength instead of +40% and 2x. Elemental Fire stacks deal 2 damage/s each before mastery instead of 4, so early fire alone does not bypass the pacing change.

Let f = floor - 1 and d = room depth. Normal enemy HP is:

    ceil((base_HP + depth_growth × d) × (1 + 0.55f + 0.15f²))

Base HP: Mossling 33, Iron husk 84, Needle bat 32. Depth growth: 2, 3, 2 respectively. Bosses use base HP 200, depth growth 4 and the gentler multiplier 1 + 0.45f + 0.075f², keeping late boss fights from becoming excessively long.

Enemy attack is base_attack + 0.30d + 2.5f + 0.20f², rounded up by the existing run modifiers. Base attack: 5 / 7 / 4 / 8 for Mossling / husk / bat / boss. Armor gains 0.8 per floor. Base attack rate is 0.5 × (1 + 0.025f), with the Tide boss's additional speed. Thus ordinary floor-1 enemies start at 2s per attack. Boss mechanics, elites, family effects and Vows still modify encounters.

For a depth-0 Mossling, floor 1 → 5 now means 33 → 185 HP and 5 → 19 attack. This is substantially stronger floor progression than the previous health curve.

## Later builds

A second audit covers 1,920 controlled fights: 5 floors × 4 weapons × 3 enemy categories × 32 seeds. It uses fixed, attainable loadouts and increasing character levels, with a specified tree investment on later floors. The final reference build has eight relics at character level 9, plus Rare level-5 equipment. It is a composed defensive build, not random loot or a simulated full run. Full details are in tests/pacing_audit.gd and the attached JSON.

| Floor 5 reference weapon | Attack | Interval | Weak fight | Strong fight | Boss fight |
|---|---:|---:|---:|---:|---:|
| Sword | 22.2 | 1.75s | 10.81s | 31.80s | 62.79s |
| Dagger | 10.9 | 0.74s | 7.86s | 23.11s | 46.96s |
| Axe | 43.4 | 2.63s | 8.47s | 24.69s | 47.46s |
| Ember blade | 18.7 | 1.93s | 10.59s | 30.13s | 57.89s |

These numbers demonstrate different weapon rhythms and tougher floors. They do not prove every seed is fair or that complete runs have the right attrition. The audit also includes a level-1 boss attempt with basic gear; that underprepared reference loses. The first boss should be approached after gaining levels and making build choices.

## Critical builds

Critical chance still starts at 5%, with an initial 60% limit. Early chance gains are smaller:

- Critical affix: 3% + 0.3% per extra item level, multiplied by rarity strength.
- Amulet innate chance: 2% + 0.2% per extra item level, multiplied by primary rarity strength.
- Dagger innate chance: 2%.
- Hawk eye: +8%, down from +20%.
- Keen edge blessing: +6%, down from +20%.
- Precision tree training: +0.3% per rank.

Even a complete level-1 Very rare crit set with Hawk eye remains around 40% before tree/blessing bonuses. A single early lucky weapon does not fill the crit chance limit.

Two later level-up choices extend the build:

- **Critical horizon:** +15% maximum chance and +3% actual chance. Available from level 5 once raw chance reaches 35%. Limit becomes 75%.
- **Unbound aim:** another +15% maximum chance and +3% actual chance. Requires Critical horizon, level 9 and at least 55% raw chance. Limit becomes 90%.

When a build reaches its current limit, an eligible cap upgrade is guaranteed as one option at its next initial level-up offer. It still costs the choice; rerolling can reject it. The build overview, upgrade preview, saved battle and actual combat rolls all use the same limit. A 10,000-hit test checks that an 85% build genuinely crits above the old 60% ceiling.

Critical damage remains capped at 300%. Its affixes grow more slowly, Ruin prism adds 25% instead of 50%, and Ruin training adds 1.5% per rank. You can develop both frequency and hit size rather than finish the frequency side on floor 1.

## Equipment and upgrade math

Let n = item level - 1. Primary rarity multipliers are 1 / 1 / 1.18; affix strengths are 1 / 1 / 1.5 for Common / Rare / Very rare.

Weapon item attack before rarity: Sword 5+n; Dagger 2.5+0.45n; Axe 9.5+2.2n; Greatblade 8.25+1.8n; Ember blade 4.25+0.8n. The character attack component is 9 + 0.35 per extra character level + run attack bonuses + 0.35 per Might rank. Apply the weapon's character-power multiplier, then add item attack.

Attack interval is weapon_base_interval / (1 + equipment speed bonuses + run speed bonuses + 0.5% per Tempo rank + 12% from Clockwork heart). A speed affix grants 3.5% + 0.6% per extra item level, multiplied by affix strength. Iron upgrades and bonus transfers recompute from the receiving item's level, rarity and balance version, so growth never compounds accidentally.

Other major slower affix growth: Fire 0.6+0.18n damage/s; ice/poison 3.5%+0.4%n; acid 0.4+0.12n armor/hit; critical damage 10%+1.5%n; vampirism 3.5%+0.15%n. Existing evade, vampirism, slow and poison safety caps remain. Attack blessings now grant 3 character attack; defensive blessings grant 2 armor and 6% base speed.

## Compatibility and verification

Balance rules are versioned as run rules 7. Newly generated gear carries balance version 2. Old saved runs and unversioned items retain their old calculations; they are not silently rescaled mid-run. Playtest reports now include run rules so results can be compared correctly.

All 22 automated suites pass. Historical encounter suites explicitly verify the saved rules-6 contract; new-rule coverage includes 76 pacing checks, the modern build/feedback suites, the opening benchmark and the 1,920-encounter audit. Native Mac visual review verified the three weapon choices and critical-limit previews, including a 90% cap in the build overview. Windows is exported and archive-checked but has not been played on a Windows machine here.

Next playtest: start fresh, try each entrance weapon, and record the first floor where fights feel tedious or become trivial. Compare time-to-kill and HP loss together. This is a first measured balance pass, not a claim of finished tuning.
