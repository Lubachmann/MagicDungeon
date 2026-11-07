# MagicDungeon 0.6 — Automatic combat and build identity

> Current combat update: guards in modern fights absorb 8 physical damage across attacks; greatblades break them and active Fire and Poison bypass them. Older saved battles keep their existing one-hit guard until the fight ends.

Guard, Interrupt and Mend buttons are retired. Encounters advance automatically; Escape still pauses. Continue migrates an old pending decision without consuming a new resource. Existing profiles, gear and tree purchases remain intact. Start a new run to generate the new exclusive floor enemies.

## Evade and vampirism

Evade rolls separately for each incoming strike and prevents all damage and its on-hit debuff. It preserves shields and dagger combos. The final chance is capped at 50%. Daggers have a small innate chance; gear affixes and the Veil infusion add more.

Vampirism heals from actual weapon health damage after armor, critical hits, blocks and overkill are resolved: healing credit = damage × vampirism. At 10%, a 20-damage hit heals 2 HP. Fractions accumulate between strikes; healing cannot exceed maximum HP and unused credit is cleared at full health. Burns, flares, bombs and damage against shields do not generate healing. Final vampirism is capped at 35%. Amulets carry innate vampirism; affixes and Blood infusions add more.

Let n = item level − 1. A rare affix supplies evade = 4% + 0.25% × n or vampirism = 5% + 0.25% × n. Very rare affixes double these values. Dagger innate evade = 3% + 0.1% × n. Amulet innate vampirism = (2% + 0.15% × n) × rarity multiplier (1, 1, 1.4). Veil/Blood infusions each supply 3% + 0.2% × n to their respective stat. Iron upgrades recalculate these from the resulting level. The existing tree layout is preserved.

## Weapons

- Sword: every fourth successful hit grants 3 shield, up to 8.
- Dagger: the third consecutive successful hit deals 150% weapon damage. Health damage or a blocked/missed hit resets the combo; dodges and fully absorbed hits preserve it.
- Greatblade: breaks weapon guards; every third swing deals 120% damage, strips armor and automatically interrupts the enemy for half a combat second. Only one interrupt delay can be pending, preventing permanent stun locks at extreme attack speed.
- Ember blade: every third successful hit adds an armor-ignoring flare equal to 150% of fire damage per second. The flare does not grant vampirism.

## Floors and counters

| Floor | Exclusive enemy | Boss signature |
|---|---|---|
| Fallen Keep | Pikeman: armor-piercing prepared thrust | Castellan: one additional guard below half HP; greatblades and fire counter it |
| Drowned Archive | Leech: heals from health damage dealt | Regent: two-hit tidal waves; each hit can be evaded |
| Ashen Crypt | Wisp: halves burns until iced or corroded | Abbot: five Soulmends; burns halve healing and automatic interrupts delay it |
| Shattered Foundry | Construct: three breakable plates | Furnace Knight: heat builds toward a stronger piercing attack; ice cools it |
| Eclipse Sanctum | Shade: phases through every fourth weapon strike; ice, dagger finishers and sunders counter it | Sovereign: alternates physical and burn resistance; critical hits or stripped armor break a seal |

Each newly generated floor includes two of its exclusive enemy type, without moving blockers, chests or doorways. Existing sprites gain identifying colors and badges; floor-specific ambient marks reinforce their identity. These are composed from the existing licensed art.

## Feedback and controls

Combat displays the weapon behavior and current evade/vampirism values. Hits include sidesteps, slashes, critical bursts, guard fragments, shield outlines and drain trails. Boss status shows heat, guards and seals. Elemental combinations have colored cues and labels; sounds use the existing licensed library with pitch and volume variations. Reduced flashes also disables the new motion and particles.

Arrow keys move; E opens equipment; hover the map icon to view the map. Existing remapped controls remain available in Settings. Escape pauses. No timed ability input is required.

## Verification

The regression suites cover generation, locked chest access, progression, gear, tree/profile persistence, replay systems, audio and combat. New tests compare 396 weapon/enemy/passive combinations against live simulation, sample 10,000 dodge rolls and generate 250 themed floors. Checkpoint tests preserve dodge RNG, combos, fractional healing and Contagion carry. A prepared first-floor build can beat the Castellan without permanent upgrades. Longer playtesting is still needed to tune rare evade/vampirism combinations and deep Endless runs.
