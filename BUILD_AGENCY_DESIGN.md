# MagicDungeon 0.10 — Build ownership

The project now gives each run an early choice and a way to deliberately assemble gear, while retaining random treasure and strong combinations. The HUD stays unchanged.

## Your build

Press E, then **Your build**. This page is also available from the journal and the run-end screen.

- Attack, armor, max HP and attack interval are the main numbers.
- Active effects show their combined values across equipped items, infusions, level-up upgrades, relics and relevant Ember Tree ranks. Zero effects are hidden. Gear-only elemental effects remain visible even without an elemental stack.
- Select a number for its sources, rules and limits in the side panel. Critical chance and critical damage are separate values. Blood thread's flat healing is separate from vampirism.
- Equipment and loot previews show current totals versus totals if equipped, with changes first. Item details remain available in the equipment panel. Long builds show their full effects on the paged overview rather than squeezing every number into a comparison.
- Iron previews also calculate the whole build after upgrading and equipping the selected item. Previewing never changes HP, equipment or random rolls.

## A reliable starting choice

Every newly generated run has a cache near the first-room spawn, reachable before combat, traversal tools or opening another chest. Choose one Rare level-1 item:

- Ember blade with a fire bonus.
- Dagger with a critical chance bonus.

These are replaceable items, not classes. The unchosen item is lost. Later-floor elemental caches remain an achievement unlock, now called **Advanced caches**. Old active floors retain their saved layout; start another run to see the first-room cache.

## Bonus transfer

Find the purple transfer table in each floor's Forge room. Step onto it to open the workshop.

1. Choose an unequipped, unprotected Rare or Very rare donor.
2. Choose a different Rare or Very rare receiving item. Equipped and protected items may receive a bonus.
3. Choose which donor bonus to copy and which receiving bonus to replace.
4. Review the build preview, then spend **1 iron**. The donor is destroyed. Each table allows one transfer.

The receiver keeps its level, rarity, weapon identity, infusion and protection mark. A bonus already present cannot be added twice. Innate weapon properties and infusions are not transferable bonuses.

Only the bonus type transfers. Its value is recalculated using the receiving item's level, rarity and variant, including after later iron upgrades. For example, transferring Vampirism from a level-12 Very rare helmet onto a level-2 Rare sword adds **5.25%**, not the donor's **15.5%**. Raising that sword to level 3 changes the bonus to **5.5%**. The sword loses the bonus you chose to replace. Total vampirism is still capped at 35%.

This makes spare loot useful for planned combinations without introducing a new currency or importing a donor's higher-level power.

## Backpack and combat recap

Sort each slot by level, rarity or name. Filter All, Equipped, Spares or Protected. **Protect item** prevents scrapping or using that item as a transfer donor; it does not prevent equipping or upgrading it. Loot's **Keep** action simply stores the item and does not mark it protected.

The existing limit of 3 scrap uses per floor remains. Transfers create another use for spare gear and iron; increasing scrap income at the same time would obscure their balance impact.

**Fight recap** is available after a run and from the journal. It separates weapon damage, fire damage, enemy armor mitigation before shields, damage taken, enemy healing and vampirism healing. It includes critical-hit and dodge counts, with contextual advice. Enemy healing includes regeneration, lifesteal, siphoning and deathless revival. Recaps from old saves begin collecting at the next live fight.

## Validation and balance limits

19 automated suites pass, including generation, boss access, combat, progression, save migration and the new build systems. The new agency suite covers 440 checks. Native visual review covered the overview, source panel, equipment comparisons, workshop, a completed transfer, and recap.

The controlled audit below compares 960 boss fights (32 fixed seeds × 5 floors × 3 tree profiles × 2 weapons). These are isolated encounters at full health, not simulated full runs or evidence of player enjoyment. No potions, bombs, relic choices, route attrition or extra transfers are included. Character level is 1 + 2 × floor. Other items are fixed per floor. The fire loadout uses a Rare ember blade at floor + 1; the lucky loadout swaps only its weapon for a Very rare greatblade at floor + 3 with speed and critical chance. This weapon represents an upgraded standout find, not an ordinary fresh chest drop.

Profiles: Fresh costs 0 embers; Early costs 157; Developed costs 1,725. The developed profile includes health, armor, Might, Tempo, elemental mastery and Flaskcraft. Flaskcraft has no effect in these potion-free tests. Exact ranks and reproduction are in tests/progression_audit.gd. Set MAGICDUNGEON_AUDIT_OUTPUT to a writable JSON path to export results.

| Tree | Floor | Fire wins / 32 | Fire mean HP lost | Lucky wins / 32 | Lucky mean HP lost |
|---|---:|---:|---:|---:|---:|
| Fresh | 1 | 32 | 56.0 | 32 | 17.4 |
| Fresh | 2 | 0 | 86.0 | 32 | 45.3 |
| Fresh | 3 | 32 | 62.0 | 32 | 34.3 |
| Fresh | 4 | 32 | 82.0 | 32 | 34.0 |
| Fresh | 5 | 32 | 98.4 | 32 | 29.1 |
| Early | 1 | 32 | 55.0 | 32 | 16.6 |
| Early | 2 | 22 | 92.8 | 32 | 44.4 |
| Early | 3 | 32 | 61.0 | 32 | 32.0 |
| Early | 4 | 32 | 79.0 | 32 | 33.0 |
| Early | 5 | 32 | 94.0 | 32 | 28.3 |
| Developed | 1 | 32 | 41.0 | 32 | 11.5 |
| Developed | 2 | 32 | 89.0 | 32 | 29.8 |
| Developed | 3 | 32 | 56.0 | 32 | 27.3 |
| Developed | 4 | 32 | 66.4 | 32 | 30.7 |
| Developed | 5 | 32 | 82.0 | 32 | 26.5 |

The reference fire build has a floor-2 difficulty spike, while the standout greatblade substantially reduces HP loss. Permanent investment improves survival, but isolated boss wins cannot establish full-run difficulty. This release changes the reliability and ownership of rewards rather than silently weakening existing gear or scaling enemies to cancel a player's lucky find. The next balance test should compare floor-2 counterbuilds and record how often one weapon removes the need for further decisions.

## Playtest focus

Use a new run. Try both first-cache choices across attempts. Find a table, intentionally replace one bonus, then compare the result. Ask: “Which decisions made this build work?” Record whether a standout find still makes every later choice irrelevant. The updated playtest guide includes these observations. Real external playtests have not been conducted by the automated checks.
