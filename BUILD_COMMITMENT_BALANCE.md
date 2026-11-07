# Build commitment balance — rules 18

New runs use rules 18. Existing runs retain their saved rules and original balance.

- The first three level-ups still grant 1 character attack and 0.35 armor each. Later level-ups grant 0.45 attack and 0.15 armor. Every level continues to grant 8 max HP and restore the gained health.
- Quick hands removes 0.15 seconds from the final attack interval (minimum 0.3 seconds). Heavy momentum gives axes and greatblades 45% more physical hit power and 20% less attack rate; the physical bonus is excluded from Fire damage.
- Advanced conditional skills can appear before their conditions are met. Their descriptions say what they require. One modest generally useful choice is included when one remains available. The 4-power elemental specialization thresholds remain; Exposed core now requires 4 Acid power in rules 18.
- Later-floor enemies gain additional health, attack, armor and speed. Armored enemy types gain more armor; fast enemy types gain more speed. More named enemy families appear on later floors. Floor-one enemy base scaling remains unchanged.
- The optional restful branch offers one rest-site choice, instead of also providing a loose flask. This applies to rules 18; previous runs retain their original reward.
- Vampirism's existing 35% cap was not changed by this pass.

`tests/build_commitment.gd` checks the new stats, previews, skill offers and compatibility. `tests/run_balance_audit.gd` simulates sequential battles with scripted item and skill choices. It does not reproduce physical routing, bombs, forge upgrades or side passages. Use it to identify concerns, not to claim a player win rate; verify both the first floor and late-floor builds in actual runs.
