# MagicDungeon 0.7 — Clear choices and fuller rooms

Upgrade cards now show an icon, a short effect and prominent numbers. Hover a card or focus it with the keyboard/controller to see the full explanation in the side panel. Element choices use stacks, show capped stacks explicitly, and explain damage, slowing, armor stripping and weakening in the detail panel. The formulas and effects themselves are unchanged.

Attack timing is displayed as an interval: interval in seconds = 1 / attacks per second. For example, 1.25 attacks/second becomes every 0.80 seconds. This is a presentation change; combat timings are unchanged. The enemy panel updates its interval during chill and rage. Haste, the Tempo tree node, weapon comparisons, iron previews and reliquary rewards use seconds too. Fire damage per second remains damage per second.

Equipment emphasizes item values in gold and comparison changes in green/red. Weapon interval comparisons show the resulting interval for your whole build if you equip that item, including speed from other equipment and upgrades. A negative interval change is an improvement. A normal sword also shows its interval, even without a speed affix.

Non-boss rooms gain additional walls, scaled to their interior area. Generation checks connectivity before and after ability gates are opened. Required items, door landings, chest approaches and authored boss arenas are protected. Non-start, non-fountain rooms gain an optional weaker enemy with half the usual XP/ember reward. Rooms also contain breakable urns: step onto one to find a small heal, an ember, or nothing. Rewards are determined at generation and are saved with the room. No equipment is added outside treasure rewards.

Existing profiles and runs remain compatible. Start a new run or ascend to a newly generated floor to see the denser rooms.

Validation includes a dedicated 100-floor density/connectivity suite, boss access across 500 floors, treasure access, progression, replay/profile saves, combat forecasts and existing regression checks. Native previews were used to inspect the new upgrade layout. Longer playtesting will help tune the added optional combat and small urn rewards.
