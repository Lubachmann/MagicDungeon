# MagicDungeon 0.7.1 — Plain-language descriptions

Rewrote all 33 Ember Tree skills, all 20 level-up upgrades, element explanations, weapon descriptions, enemy/boss explanations, tutorial pages and longer forge/chest instructions. Gameplay, prices, drop rates and save data are unchanged.

Examples:

- Prospector: +1.5% chance to find Rare gear in chests per rank. Also shows the basic chest chance before and after buying the next rank.
- Gilded Touch: +0.5% chance to find Very rare gear in chests per rank.
- Poison: each stack makes enemies deal 18% less damage. The tooltip shows your actual total with gear, mastery and the 65% cap.
- Ice: each stack makes enemy attacks 18% slower. Shows the actual total and the 65% cap.
- Fire: each stack deals 4 damage/s. Shows total damage and burn duration. Hits restart the timer.
- Acid: hits remove enemy armor. Shows armor removed per hit and the maximum removed from one enemy.
- Critical damage upgrades show the resulting damage as a % of a normal hit, instead of an unexplained multiplier.

Percentages use %. Descriptions avoid terms such as potency, percentage points and affixes. Chance increases are shown with before-and-after values so their meaning is clear. Mastery descriptions explain that they strengthen an element, rather than adding it to your attacks.

Existing profiles and runs remain compatible. These text changes appear immediately; no new run is required.

Validation checks actual skill ranks against displayed chest odds, Poison mastery and caps against combat formulas, burn durations, and text fitting at the larger font setting.
