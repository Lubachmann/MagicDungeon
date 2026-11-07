# MagicDungeon 0.13 — equipment clarity and enemy identity

Historical note: ARMOR_CURVE_DESIGN.md supersedes the armor formula and cap in this document as of 0.14.

Start a new run for rules 8. Existing profiles and Ember Tree purchases remain; continued rules-7 runs retain their previous 9 base attack, 1 base armor and equipment formulas. New characters start unarmed with 5 base attack and 0 base armor. Levels, equipment and purchased tree nodes still add their bonuses.

## Equipment previews

Pickup cards show the weapon's base attack interval, its own attack and bonuses, and its character-power multiplier. If the item supplies a speed bonus, its item-only interval is also shown. The build comparison applies all equipped gear, levels, blessings and permanent upgrades, and includes weapon DPS before criticals, armor and special abilities.

Equipment's item view shows WORN and ITEM columns. Affected values remain visible when identical: two +2 armor helmets show +2 → +2. The build-impact view likewise retains affected unchanged stats. Long comparisons have explicit stat pages rather than hiding values or shrinking the text.

Hover the iron button to see the item's own NOW and AFTER columns. This recalculates the complete item at level +1, including rarity, affixes, infusion and variant, without changing the run or consuming RNG. A short build-impact summary sits below it. Previewing does not spend iron.

## Base attack, weapon damage and cadence

For new rules-8 weapons, item balance version is 3. Existing balance-2 gear keeps its original stats, including when upgraded with iron.

Attack per hit = character attack × weapon power + all equipment attack.

Character attack = 5 + 0.35 × (character level − 1) + run attack bonuses + 0.35 × Might ranks.

Weapon power: sword 100%, dagger 50%, axe 190%, greatblade 165%, ember blade 85%. Unarmed is 100%.

A common level-1 weapon now supplies 9 × weapon power attack. Moving four character attack into the weapon keeps the previous armed opening pace while making the first weapon a larger upgrade. With no tree or run bonuses:

| Weapon | Character contribution | Item attack | Total hit | Base interval | Weapon DPS |
|---|---:|---:|---:|---:|---:|
| Unarmed | 5 | 0 | 5 | 2s | 2.5 |
| Sword | 5 | 9 | 14 | 2s | 7 |
| Dagger | 2.5 | 4.5 | 7 | 1s | 7 |
| Axe | 9.5 | 17.1 | 26.6 | 3s | 8.87 |

These DPS values exclude criticals, armor, elemental damage and weapon abilities. The axe trades slower attacks for higher sustained physical power. Actual damage rounds per hit.

Item attack = [level-1 attack + growth × (item level − 1)] × rarity primary multiplier.

Growth: sword +1, dagger +0.45, axe +2.2, greatblade +1.8, ember blade +0.8 per item level. Primary rarity multipliers remain Common 1, Rare 1, Very rare 1.18. Existing affix and infusion growth is unchanged. Iron recomputes this formula at the new level, rather than multiplying the old rounded displayed value.

Base intervals: sword/unarmed 2s, dagger 1s, axe 3s, greatblade 2.8s, ember blade 2.2s. Effective interval = base interval / (1 + combined speed bonuses), with the existing minimum speed multiplier of 0.15. Item interval uses only that item's speed bonus; build interval includes all sources.

## Armor

Physical damage = max(1, ceil(hit power × max(0.4, 12 / (12 + effective armor)))). Negative effective armor counts as 0. Critical and hit-power bonuses apply before armor.

Armor reduction is armor / (12 + armor), capped at 60%. A 20-power strike deals 20 against 0 armor, 10 against 12 armor and 8 against 24 armor. Acid and piercing reduce effective armor. Guards, shields and other special defenses can change the resulting health damage. Fire bypasses armor.

Armor's build-details text explains the formula and cap in game.

## Enemy inspection and art

Inspection emphasizes LEVEL, name, and four icon-backed numbers: HP, attack, armor and attack interval. Estimated risk and reward remain below these. Hover the ability section for the complete description in a separate panel.

Enemy level is an indicator, not an additional stat multiplier: 1 + 2 × (floor − 1) + floor(room depth / 3) + type bonus (0 weak/imp, 1 armored, 3 boss) + 1 each for a floor family, elite, gatekeeper or affix. Actual stats and the build-specific fight preview remain the stronger measure of encounter risk.

The three base types, five floor-specific types and five bosses now use 13 distinct animated sprites. Knights visually identify passage, gate and treasure guardians. Names match the creatures: Mire Slime, Bone Guard, Cave Imp, Orc Marauder, Blood Revenant, Cinder Fiend, Forge Skullguard, Mirror Cultist, Mire Colossus, Tide Ogre, Ash Necromancer, Furnace Demon and Eclipse Seraph. Boss mechanics remain intact.

Art: [0x72 DungeonTileset II v1.7](https://0x72.itch.io/dungeontileset-ii), CC0 1.0, verified on the artist's official page. The pack already contains enough unused animated monsters, so the existing dungeon tiles remain a consistent match. Eleven additional animation sets are integrated; source mappings are recorded in assets/animations/enemy-sources.json. Tall sprites preserve their aspect ratio.

## Validation

23 regression suites, including the new equipment-clarity suite. It checks item cadence, item-level upgrade previews, equal-stat relevance, preview purity, armor examples, unique animated enemy identities, floor levels and rules-7 compatibility. The pacing audit checks fresh weapon ratios and early encounter durations. Native macOS previews check pickup, item comparison, iron preview and enemy inspection layouts. Windows exports are packaged and validated structurally, not played natively.
