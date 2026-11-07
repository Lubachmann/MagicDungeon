> Historical formulas for saved rules 6 and earlier. New runs use PACING_BALANCE_DESIGN.md.

# MagicDungeon: progression and equipment math

These formulas are implemented in `main.gd`, `equipment.gd`, and `combat.gd`.

## Character experience

Let L be the current character level. XP needed to advance from L to L+1 is:

**T(L) = 40 + 20(L − 1) + 5(L − 1)²**

| Current level | XP for the next level | Total XP to reach the next level from level 1 |
|---|---:|---:|
| 1 | 40 | 40 |
| 2 | 65 | 105 |
| 3 | 100 | 205 |
| 4 | 145 | 350 |
| 5 | 200 | 550 |
| 6 | 265 | 815 |
| 7 | 340 | 1,155 |
| 8 | 425 | 1,580 |

On earning XP, subtract T(L), increment L, and repeat while enough XP remains. Overflow is preserved. Every gained level queues one relic choice; large XP awards can queue several choices. Each choice offers up to three different unowned relics. After all twelve relics are owned, further level rewards give four embers instead. Levels do not directly heal current HP.

Enemy XP on floor F:

**XP = enemy base XP + elite bonus + 4(F − 1)**

Base XP: Mossling 12; Iron Husk 18; Needle Bat 14; Warden 60. Elite/champion bonus: +20. Ordinary passage sentinels use their underlying enemy type; elite champions get the bonus. Both automatic-combat kills and bomb kills grant XP and embers exactly once.

Level-based character gains, relative to level 1:

- Maximum health: +5(L − 1).
- Attack: +0.75(L − 1).
- Armor: +0.25(L − 1).

Equipment and permanent ember upgrades are added separately. Death restarts at character level 1 with zero XP and no earned relics.

## Item level and rarity

Let I be the item's **current** level, and let n = I − 1.

| Rarity | Primary-stat multiplier M | Affix count | Affix strength A |
|---|---:|---:|---:|
| Common | 1.0 | 0 | — |
| Rare | 1.0 | 1 | 1.0 |
| Very rare | 1.4 | 2 | 2.0 |

Equipment is now found in eight chests per floor, covering all five slots. Chest tiers determine the rarity roll:

| Chest tier | Common | Rare | Very rare |
|---|---:|---:|---:|
| Weathered / I | 75% | 23% | 2% |
| Reinforced / II | 20% | 65% | 15% |
| Ornate / III | 0% | 55% | 45% |

Ornate chests guarantee at least Rare equipment. Most chest items use the level roll below; the Warden chest always gives item level F+1. The chest's item, affixes, and level are fixed when the floor is generated, not rerolled when opened.

A new item on floor F is level F with 75% probability or F+1 with 25% probability. Eight chest rewards cover all five equipment slots each floor. Affixes are rolled once, without duplicates, when the item is generated.

Rarity, slot, and affix identities do not change when the item is upgraded. Current item level is the source of truth. A level-three upgraded item has exactly the same stats as a newly created level-three item of the same slot, rarity, and affixes.

### Primary stats

`ceil` means round upward to a whole number. Other stats retain decimals.

| Slot | Primary stats |
|---|---|
| Weapon | Attack = ceil((5 + 2n) × M) |
| Shield | Armor = (2 + n) × M |
| Body armor | Armor = (3 + n) × M; max HP = ceil((8 + 3n) × M) |
| Helmet | Armor = (1 + 0.5n) × M; max HP = ceil((5 + 2n) × M) |
| Amulet | Critical chance = (3% + 0.5% × n) × M |

### Affix stats

Rare equipment has one affix; very rare equipment has two. Each affix contributes its value in addition to the item's primary stats:

| Affix | Value at current item level |
|---|---|
| Critical chance | (5% + 1% × n) × A |
| Attack speed | (0.10 + 0.02n) × A attacks/sec |
| Fire | (1 + 0.5n) × A damage/sec |
| Ice | (5% + 1% × n) × A enemy attack-speed reduction |
| Acid | (0.5 + 0.25n) × A armor stripped per damaging hit |
| Poison | (5% + 1% × n) × A enemy power reduction |
| Critical damage | (0.15 + 0.025n) × A added to critical multiplier |
| Maximum health | (5 + 2n) × A |
| Armor | (1 + 0.5n) × A |

If an affix uses the same stat as the slot's primary stat, they add together. Health contributions across equipped items are rounded to a whole maximum-health value when combined with the character.

## Your sword examples

- Common level 1: ceil((5 + 0) × 1) = **+5 attack**.
- Common level 2: ceil((5 + 2) × 1) = **+7 attack**.
- Rare level 1 with critical chance: **+5 attack, +5 percentage points critical chance**.
- Rare level 1 with speed: **+5 attack, +0.10 attack speed**.
- Very rare level 1 with speed and fire: ceil(5 × 1.4) = **+7 attack**, 0.10 × 2 = **+0.20 attack speed**, 1 × 2 = **2 fire damage/sec**.

Upgrade that last sword using iron:

| Item level | Attack | Attack speed | Fire damage/sec |
|---|---:|---:|---:|
| 1 | 7 | 0.20 | 2 |
| 2 | 10 | 0.24 | 3 |
| 3 | 13 | 0.28 | 4 |
| 4 | 16 | 0.32 | 5 |

Each iron raises any one owned item by one level and is consumed only on a successful upgrade. Backpack items can be upgraded too. There is no additional ember cost and no level cap imposed by the floor. Repeated upgrades recalculate the formulas from the new level; bonuses are never multiplied on top of previously calculated bonuses.

## Combining character and equipped stats

Only one item per slot contributes. Items in the backpack do not grant stats.

- Max HP = max(20, 48 + 4×Kindling + 4×Vigor + 5(L−1) + equipped HP − shrine tax).
- Attack = 9 + run attack bonuses + 0.75(L−1) + equipped attack.
- Armor = 1 + run armor bonuses + 0.25(L−1) + equipped armor.
- Attack speed = 1 + equipped speed + Clockwork Heart's 0.25 if owned.
- Crit chance = min(60%, 5% + equipped crit chance + Hawk Eye's 20 percentage points if owned).
- Crit multiplier = min(3.0, 1.5 + equipped critical multiplier bonuses + Ruin Prism's 0.5 if owned).

The previous three stat tracks are replaced by the Ember Tree; old investments are refunded exactly once. Every new run receives a fresh common level-one starter sword; found/upgraded equipment is lost.

Equipping, unequipping, or upgrading health gear does not increase current HP. Current HP is only clamped down if the new maximum is lower. This prevents healing by repeatedly swapping equipment. The equipment comparison shows the selected item's raw contribution relative to the current item in that slot; final character caps still apply.

## Elemental gear and combat

Gear effects add to relic-granted elemental ranks:

- Fire DPS = 4 × fire rank + equipped fire DPS. A damaging strike ignites or refreshes the burn for three combat seconds; Cinder Crown extends this to five. Fire ticks once per combat second and can deal fractional damage. It ignores armor and cannot crit.
- Ice slow = min(65%, 18% × ice rank + equipped ice slow). It adjusts pending enemy attacks immediately when applied.
- Poison weaken = min(65%, 18% × poison rank + equipped poison weaken). It reduces enemy attack power, including heavy attacks.
- Acid removes `rank strip + equipped acid strip` armor per damaging hit. Rank strip is 2 when acid rank > 0, or 3 with Alchemist Fang. Armor-removal cap = 4 × acid rank + 3 × equipped acid strip. Effective enemy armor never drops below zero.

Elemental ranks cap at three. Cinder Crown, Frost Prism, Alchemist Fang, and Venom Veil each grant one corresponding rank. Gear can supply an element even without its relic. All debuffs reset between enemies. Critical damage, armor, shields, and Warden enrage otherwise retain their previous rules.

Damage before shield/relic exceptions:

`ceil(attack power × max(0.4, 12 / (12 + effective armor)))`

Critical strikes multiply direct attack power by the character's critical multiplier before armor mitigation. Armor can prevent at most 60% of an incoming hit. Forecasts clone the same state, equipment totals, and fixed encounter critical rolls used by live combat.

## Floor scaling and reset rules

There are five floors. Defeat the current Warden, then enter the stairs. Floors 1–4 show an ascent prompt; floor 5 completes the dungeon. Other enemies are optional unless they block a required passage.

For floor F, before fixed champion bonuses:

- Enemy HP = ceil((base HP + 3 × graph-distance tier) × (1 + 0.30(F−1)) × 1.10).
- Enemy attack = base attack + graph-distance tier + 2(F−1) + 1.
- Enemy armor = base armor + F−1.

Warden tier is four. Elite and gate champion flat HP bonuses are added after scaling. Item levels and XP increase with floor as described above.

Ascending preserves current HP, character levels/XP, relics, all equipment, iron, traversal abilities, potions, bombs, and unbanked embers. Each ascent adds five embers. There is no automatic floor heal. Already-owned traversal pickups are replaced with healing flasks on later floors.

Death banks earned embers as before. Restart creates floor 1, character level 1, zero XP, no earned relics, no found equipment, zero iron, and a new level-one starter sword. Permanent ember upgrades remain. Quitting mid-run also abandons temporary progression; the prototype does not save/resume active runs.

## Weapon archetypes and salvage

Weapon archetype and affix identities remain fixed when iron raises the level. With n = level − 1 and rarity multiplier M = 1 for Common/Rare, 1.4 for Very rare, weapon attack is `ceil((5 + 2n) × M × A)`:

| Archetype | A | Extra stats before affixes |
| --- | ---: | --- |
| Sword | 1.0 | None |
| Dagger | 0.6 | +(0.20 + 0.02n) attacks/sec, +3% crit chance |
| Greatblade | 1.5 | −0.20 attacks/sec |
| Ember blade | 0.6 | +(1.5 + 0.4n) fire DPS |

Rarity affixes then add their existing level-scaled values. Thus a Very rare level-one Greatblade has ceil(5×1.4×1.5) = 11 attack before affixes; level two has ceil(7×1.4×1.5) = 15. Its speed penalty stays −0.20. A Common Ember blade goes from 3 attack / 1.5 fire DPS at level one to 5 attack / 1.9 fire DPS at level two. Every iron recomputes from the new level, so rounding never compounds.

Salvaging an unequipped item yields rarity index + 1 fragments: 1 Common, 2 Rare, 3 Very rare. Add them to the carried total, grant `floor(total / 3)` iron, and retain `total mod 3` fragments. Three items can be salvaged per floor. Item level does not increase its salvage value, so spending iron cannot manufacture more iron. Unspent iron/fragments carry between floors and reset on death.


## 0.3 class-free baseline and permanent progression

New-run maximum HP = max(20, 48 + 4×KindlingRank + 4×VigorRank + 5×(characterLevel−1) + gearHP − shrineTax).

Attack = 9 + 0.75×(characterLevel−1) + runBonusAttack + gearAttack. Armor = 1 + 0.25×(characterLevel−1) + runBonusArmor + gearArmor. Base attack speed remains 1.0; base crit chance is now 5%, before gear/relic bonuses and the existing 60% cap. A common level-one starter sword therefore gives 14 total attack. The old class bonuses and favored relics are removed.

Enemy HP now uses ceil((baseHP + 3×depth) × (1 + 0.30×(floor−1)) × 1.10), and attack adds 1 to the prior floor/depth formula. Tree ownership is not an input to enemy generation. Existing saved runs retain their earlier baseline and stat effects until they finish.

Permanent node costs, prerequisites, exact infusion formulas and refund behavior are listed in PROGRESSION_DESIGN.md. A legacy stat rank L refunds 3L² + 5L embers, exactly the sum of its prior purchase costs. Resetting the new tree refunds its purchased rank costs without a fee. The current run's skill snapshot never changes through a respec.

Second Wind restores ceil(maxHP × 0.25) once per run when an enemy strike would be fatal. That charge is part of both the combat simulation and saved run. Flaskcraft raises flask healing from 25 to 33 HP. Tinkering adds one iron to the first iron pickup each floor.

Infusions are an additional level-scaled contribution, independent of rarity: with n = itemLevel−1, fire adds 1+0.5n DPS; ice/poison/critical chance add 0.05+0.01n; acid adds 0.5+0.25n armor stripping per hit; critical multiplier adds 0.15+0.025n. Only one infusion is present on an item, and all aggregate caps still apply. Iron recalculates these values at the new level instead of compounding them.

Cinder Crown's every-third burn pulse still deals 1.5 times ordinary fire DPS and cannot crit. The shrine still trades 8 current/max HP for one equipped weapon level, once per floor, subject to its existing survival checks.


## 0.4 combat and first boss

XP, equipment rarity, level scaling and iron recomputation are unchanged. For new-rule first-floor bosses only, multiply generated HP by 0.75 (round up), subtract 4 attack and 2 armor. A depth-four Castellan is 93 HP / 13 attack / 10 armor. Active abilities and the five floor rules are specified in TACTICAL_DESIGN.md; permanent skills do not scale enemy strength.


## 0.5 permanent progression

XP and equipment/iron formulas are unchanged. The permanent tree now has 33 nodes and 187 ranks (39,411 embers total). Repeatable costs use base + step*r + ceil(base*0.035*r²), with rank-specific utility prices. Fortune and banked-income formulas, exact rank caps and old-price refund migration are documented in LEGACY_REPLAY_DESIGN.md. Daily runs use an empty permanent-skill snapshot.
