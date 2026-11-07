# Treasure design research and implementation

## Research

Leah Miller's GDC 2019 presentation, *Rewarding Exploration with Collectables and Gatherables*, discusses visible rewards behind challenges, rewards in less-traveled areas, observation patterns, and visual cues that suggest content. It also warns about tedious or inconsistent collection and too many unrewarding containers.

Primary source: https://media.gdcvault.com/gdc2019/presentations/Miller_Leah_Rewarding_Exploration_With.pdf (particularly slides 3, 18, 20, 30–34).

The following choices are our application of those ideas to this stat-driven game; they are not prescriptions made by the source.

## Implementation

- **Readable temptation:** visible chests, tier colors, I/II/III badges, and hover descriptions advertise both value and access requirements before a fight.
- **Different ways to earn a reward:** easy introductory stash, side-room nook, winding passage, Hammer alcove, Boots alcove, a physical chest keeper, a passage sentinel, and a Warden reward.
- **Learnable secrets:** lantern/trail cues in winding routes and four rotated corner layouts replace repeated identical alcoves.
- **Risk versus reward:** Weathered chests favor Common gear; Reinforced favor Rare gear; Ornate guarantee at least Rare. Guarded and boss chests have stronger odds.
- **No empty drawers:** every chest contains one equipment item and embers. The first stash starts the slot cycle with a shield rather than another starter sword.
- **No surprise health tax:** no hidden damage traps or unavoidable opening damage. Combat costs remain inspectable through existing forecasts.
- **Keep flow:** the reveal offers immediate equip, keep, or detailed comparison. Opened chests remain visible but cannot be looted twice.
- **Protect generation:** motifs preserve doors, partitions, essential pickups, and supplies. Intersecting ordinary entities are relocated rather than deleted.
- **No opening exploits:** all loot is rolled once at floor generation; opening, inspecting, or changing gear cannot reroll it.

## Chest odds

| Tier | Common | Rare | Very rare | Embers |
|---|---:|---:|---:|---:|
| Weathered I | 75% | 23% | 2% | 3 |
| Reinforced II | 20% | 65% | 15% | 6 |
| Ornate III | 0% | 55% | 45% | 9 |

Normal item levels: floor F (75%) or F+1 (25%). Warden chest: always F+1. Primary-stat, affix, XP, and iron formulas are unchanged; see PROGRESSION_MATH.md.

## Icons and licenses

Equipment icons are by Lorc on Game-icons.net under CC BY 3.0: broadsword, checked shield, breastplate, crested helmet, and gem necklace. Original transparent SVG shapes are tinted/scaled at runtime. Links, attribution, and licenses are in ASSET_CREDITS.md and assets/equipment/LICENSE.txt. Dungeon and chest sprites remain Kenney Tiny Dungeon, CC0.
