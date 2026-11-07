# MagicDungeon 0.14 — armor without a hard reduction cap

> Current combat update: in modern runs, player physical hits keep fractional damage after armor; enemy hits still round up with a minimum of 1. Guards absorb 8 physical damage rather than one complete hit. Existing battles saved before this change retain their previous rules until they end. The original release notes below describe the earlier implementation.

Physical hit damage = max(1, ceil(hit power × 12 / (12 + max(0, effective armor)))).

Reduction before rounding = armor / (12 + armor). There is no 60% reduction cap. The same rule applies to player and enemy armor, including continued saves; no restart or save conversion is necessary.

| Armor | Physical reduction before rounding |
|---:|---:|
| 0 | 0% |
| 6 | 33.33% |
| 12 | 50% |
| 18 | 60% |
| 24 | 66.67% |
| 36 | 75% |
| 60 | 83.33% |

Individual hits still round up and deal at least 1 damage before shields and other defenses. Consequently, a small armor increase may not change a particular low-damage hit, even though its unrounded protection increases. Negative armor is treated as 0.

Acid and armor piercing reduce effective armor before the formula. Critical and hit-power effects apply before armor. Fire continues to bypass armor. Shields, evade and other combat mechanics retain their existing rules. The elemental overhaul discussed with the user is a proposal; none of it is implemented in this release.

## Balance decision

The curve is exactly the same as 0.13 up to 18 effective armor. Existing equipment armor values, iron growth, tree armor bonuses and enemy stats are retained after controlled comparison, preserving early encounter pacing and making committed armor builds viable beyond the previous threshold. There is no new armor limit hidden elsewhere.

Physical effective HP before rounding is HP × (1 + armor / 12). More armor gives smaller percentage-point increases in reduction, while equal armor additions give equal absolute increases in physical effective HP. Armor therefore remains an investment with opportunity costs, rather than becoming worthless at 18.

A paired audit compared 2,304 encounters under each curve (4,608 total): floors 1, 3, 5 and 10; offense, balanced and armor-focused allocations; three enemy types; 32 fixed roll seeds; both with and without a shared four-reward support package. Gear rarity and upgrade budgets match between the allocation styles. Support rewards consume the same level-up budget. This isolates armor behavior; it is not a full-run completion simulation and does not use consumables or optimize boss counter-builds.

Example on floor 5 against a strong enemy, with support:

| Allocation | Armor | Old wins / 32 | New wins / 32 | Mean new fight time |
|---|---:|---:|---:|---:|
| Offense | 13.61 | 32 | 32 | 31.25s |
| Balanced | 17.61 | 32 | 32 | 36.56s |
| Armor | 32.11 | 2 | 32 | 46.06s |

The armor allocation now survives the stress encounter, while the offensive alternatives finish substantially sooner. This supports keeping current armor rewards instead of offsetting the improvement with a blanket enemy-damage increase. The audit is reproducible with tests/armor_balance_audit.gd; its comparison reference lives in the workspace, outside the shipped project.

## UI

Build-impact comparisons show both armor and physical reduction, including unchanged affected values. Iron previews include the resulting reduction in their build summary. Armor details explain the curve, current percentage, rounding and minimum damage, and identify gear, base, levels, run upgrades and Fortitude contributions. These details stay out of the main HUD.

## Validation

25 regression suites validated, including the updated historical armor expectation and a new 335-check armor suite. Checks cover the curve through 150 armor, diminishing returns, unchanged damage below 18 armor, minimum damage, actual combat events, acid/piercing, fire bypass and pure gear previews. Native macOS UI checks verified a 36 → 36.3 armor comparison displaying 75.0% → 75.2% reduction and the armor explanation panel. Exported packages are checked for integrity and startup script errors. Windows is structurally validated, not played natively.
