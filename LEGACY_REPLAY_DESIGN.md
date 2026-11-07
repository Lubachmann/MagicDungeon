# MagicDungeon 0.5 — characters, lasting progression and replay systems

## Starting fresh

Open **Characters → New character** on the title screen. This creates a separate Wanderer with zero banked embers, no purchased skills and no career records. The previous character and its Continue remain intact. Select a card to switch back. More heroes can be created; the selector pages through three at a time. There is no destructive reset or deletion button.

Hero zero retains the original `user://progress.json` and `.run` paths. Other heroes use `.hero-N` suffixes; a backed-up `.characters` registry selects the active hero. Settings and bindings are shared. Each hero has an independent bank, tree, ledger, career and Continue. Purchases still apply to new runs; an active run's skill snapshot cannot be changed by respec.

Existing 0.2–0.4 saves are migrated. Owned old tree ranks remain owned. Their exact old purchase prices are entered in the paid ledger, so resetting cannot mint currency at the new higher prices. A previously saved full-dungeon victory unlocks the endgame modes; a one-floor Trial does not.

## Expanded Ember Tree

The old tree cost 156 embers. The new tree has **33 nodes, 187 total ranks, and a complete investment of 39,411 embers**. All branches can be combined; resets refund the paid ledger exactly. This is optional completionist investment, not a requirement to clear the dungeon.

Repeatable prices use `base + step*r + ceil(base*0.035*r*r)`, where `r` is the number of ranks already owned. Utility unlocks use explicit prices. Small early purchases remain available; late ranks and major utilities take multiple attempts. The first Kindling purchase costs 8 embers.

| Branch | Skill | Ranks | Total cost | Effect |
| --- | --- | ---: | ---: | --- |
| Root | Kindling | 1 | 8 | +4 max HP. Opens every branch. |
| Vitality | Vigor | 15 | 1446 | +3 maximum HP per rank. |
| Vitality | Fortitude | 12 | 1492 | +0.4 armor per rank. |
| Vitality | Flaskcraft | 3 | 820 | Flasks heal 33 / 37 / 41 HP. |
| Vitality | Wellkeeper | 5 | 665 | Fountains restore +3 HP per rank. |
| Vitality | Reserves | 3 | 1960 | +1 starting flask per rank. |
| Vitality | Rekindle | 5 | 836 | Ascending restores 2 HP per rank. |
| Vitality | Renewal | 2 | 1400 | Restore 1 HP per rank after combat victories. |
| Vitality | Second Wind | 1 | 1800 | Once per run, revive at 25% max HP. |
| Arsenal | Might | 15 | 1858 | +0.5 attack per rank. |
| Arsenal | Tempo | 10 | 1479 | +0.01 attack speed per rank. |
| Arsenal | Precision | 10 | 1714 | +0.5% critical chance per rank. |
| Arsenal | Ruin | 10 | 1904 | +0.02 critical multiplier per rank. |
| Arsenal | Tinkering | 1 | 75 | First iron pickup each floor gives one extra iron. |
| Arsenal | Rune Forge | 1 | 180 | Choose elemental or critical infusions at a forge. |
| Arsenal | Smithcraft | 3 | 1820 | +1 starting iron per rank. Upgrade any owned gear. |
| Arsenal | Salvage | 3 | 1280 | +1 salvage fragment per rank per dismantled item. |
| Fortune | Cartography | 1 | 40 | Reveal adjacent chamber roles. |
| Fortune | Prospector | 10 | 1245 | +1.5 percentage points Rare chance per rank, taken from Common chest odds. |
| Fortune | Runic Sight | 1 | 180 | Reveal the first glyph and improve one rune reward. Basic puzzles stay open to everyone. |
| Fortune | Gilded Touch | 10 | 2484 | +0.5 percentage points Very rare chance per rank. Applies to all randomly rolled chests. |
| Fortune | Recall | 1 | 300 | Once per floor, return to the entrance outside combat. |
| Fortune | Embercraft | 10 | 953 | +2% banked embers per rank. Bonus applies when the run ends. |
| Fortune | Relic Lens | 3 | 1480 | 1 / 2 / 3 relic rerolls per floor. |
| Fortune | Forager | 5 | 726 | Each defeated enemy has +2% chance per rank to grant a flask. |
| Runes | Pyromancy | 10 | 1434 | +5% fire damage per rank when your run build has fire. |
| Runes | Cryomancy | 10 | 1434 | +5% ice potency per rank when your run build has ice. Slow remains capped at 65%. |
| Runes | Alchemy | 10 | 1434 | +5% acid stripping per rank when your run build has acid. |
| Runes | Venomcraft | 10 | 1434 | +5% poison potency per rank when your run build has poison. Weaken remains capped at 65%. |
| Runes | Insight | 1 | 1800 | Level-ups offer four relics instead of three. |
| Runes | Reforge | 1 | 950 | At a forge, reroll a Rare or Very rare item's affixes for 2 iron and 8 run embers. Level and rarity stay. |
| Runes | Convergence | 1 | 1500 | Adds four dual-element relics to the level-up pool. |
| Runes | Demolition | 3 | 1280 | +1 starting bomb per rank. |

Stat growth is bounded: Kindling plus Vigor add 49 max HP, Might adds 7.5 attack, Fortitude 4.8 armor, Tempo 0.10 attacks/sec, Precision 5 percentage points crit and Ruin 0.20 critical multiplier. Gear and in-run levels still shape the build. Element masteries multiply the potency of an element already present in the run; they do not give every fresh character all four elements. Slow/weaken remain capped at 65% and critical chance/multiplier at 60%/3x.

### Chest probabilities

Prospector removes 1.5 percentage points of Common chance per rank and reallocates it to Rare. Gilded Touch adds 0.5 percentage points Very rare per rank, taking from Common first, then Rare. The displayed odds use the actual run snapshot. Fixed rune rewards are unchanged by luck.

| Chest tier | Base Common / Rare / Very rare | Both fortune nodes maxed |
| --- | --- | --- |
| Wooden | 75 / 23 / 2 | 55 / 38 / 7 |
| Iron | 20 / 65 / 15 | 0 / 80 / 20 |
| Ornate | 0 / 55 / 45 | 0 / 50 / 50 |

The item is rolled when the floor is generated. Opening, hovering or reloading does not reroll it. Reforge instead deliberately spends 2 iron and 8 run embers to replace a Rare/Very rare item's affixes; its slot, level, rarity, weapon style and infusion remain unchanged. Equipped items can be reforged. The new affixes and paid cost are checkpointed together.

## Replay loops

**Dungeon** retains the five-floor campaign and free in-run build choices.

**Daily** uses a date-derived UTC seed. Every character uses an empty skill snapshot and no Vows, regardless of bank or permanent investment. Loot, initial supplies and relic pool are therefore independent of the hero's progression. Repeated attempts are allowed. The current date's best score is local to the hero, not an online leaderboard. Score is `kills*10 + chests*15 + floor*50 + (500 if cleared)`; the setup and ending screen show the stored best.

**Endless** unlocks after a full campaign or Daily clear. It starts at floor one and continues beyond five until death. Floor identities cycle; gear levels continue to grow. Beyond floor five, generated enemy HP also multiplies by `1.10^(floor-5)` and attack by `1.03^(floor-5)` (exponents capped at 100 for numerical safety), on top of existing depth/floor scaling. This gives the player a depth record to chase instead of promising an infinite supply of new authored environments.

**Vows** also unlock after a full clear. Two have three ranks and four are toggles: **256 combinations**, Threat 0–10. Ironclad adds armor; Fury raises attack; Ambush prepares opening attacks; Hexed makes prepared attacks hex; Restless adds bounded regeneration (and strengthens existing Ash-boss mending); Famine reduces flask/fountain healing by 25%. These are optional, visible changes to rules and enemy pressure. First campaign clear at each nonzero Threat awards 50 run embers once.

At run end, banked income is `floor(runEmbers * (1 + 0.02*EmbercraftRank) * (1 + 0.08*Threat))`. Each factor is capped by its rank limit: 1.20 and 1.80, respectively, for a maximum combined multiplier of 2.16. The multiplier applies to the bank deposit, not forge spending money. Existing older-rule Continue runs keep their original economy.

**Bounties** choose three seeded goals from eight: defeat foes, open chests, solve a reliquary, collect elemental relics, fill equipment slots, break armor, use abilities or defeat bosses. Each pays 20–50 run embers once. The journal shows progress; hover a bounty for its exact objective. Completion and payment survive Continue.

**Chronicle** keeps discovered relics, enemy affixes, gear variations, career records and the last twelve runs. Its pages cycle between Relics, Bestiary and Runs. Unknown dual relics point toward Convergence rather than silently requiring a hidden unlock.

## New combat variety

Ordinary enemies outside the starting encounter may have one of six visible affixes: Leeching heals from successful strikes; Frenzied prepares specials more often; Cinder ward blocks the first burn tick; Deathless rises once at 20% health; Hexfang hexes on its opening strike; Mending supplies three regeneration pulses. Hexfang offers a decision window, so interruption/cleansing does not require a fast reaction. Affix identity, consumed wards, regeneration counters and Deathless use are part of the encounter state and forecast.

Convergence unlocks four dual-element relics:

- **Steamglass:** fire + ice; +0.3 critical multiplier against burning, chilled foes, subject to the normal 3x cap.
- **Caustic flame:** fire + acid; burn ticks strip one armor.
- **Black ice:** ice + poison; every third strike on a chilled, poisoned foe grants 2 shield, capped at 6.
- **Toxic spark:** poison + fire; every third burn tick against a poisoned foe restores 1 HP.

All three active abilities remain available to a fresh character. Mandatory doors and bosses remain independent of purchased skills. First-floor boss tuning is unchanged from 0.4.

## Interface

The HUD remains focused on health, XP and combat stats. The title uses short icon tiles and a small dungeon illustration built from the existing licensed pixel assets. Tree branches show eight icon cards at a time; only the selected skill displays its explanation. Pause, settings, relic rewards, floor transitions and ending screens use shorter labels and larger visual elements. Character selection, expedition setup and Chronicle use the same frame and icon language. No generated raster artwork or new external asset licensing was introduced.

## Research and evaluation

The optional difficulty layer draws on the idea of player-selected conditions discussed in Supergiant's [Hades Superstar update](https://www.supergiantgames.com/blog/hades-superstar-update-patch-notes/), which introduced/revised the Pact and weapon aspects. The Vows, costs, bounties and balance here are original prototype choices, not copied or externally validated formulas.

A bigger tree is only one retention tool. Daily seeds, different enemy behaviors, changing builds, collections and optional constraints give reasons to return after learning a route or finishing the basic campaign. No fixed number of entertaining hours is claimed. Human tests should measure time to the first purchase, first full clear, repeated-build frequency, bounty clarity and whether Vows change decisions meaningfully.

Automated suites cover profile isolation/reboot, exact costs and refunds, legacy migration, 20,000 sampled chest rolls, empty-tree Daily fairness, Endless saves through floor 25, Vow effects, bounty one-time payment, Reforge transactions, 24 affix/dual-relic combinations, forecast consistency, treasure reachability and boss access. Native title/tree inspection uses an isolated preview. Physical Windows/controller and sustained human balance tests remain pending.
