# Validation and balance maintenance

Build 0.17.0 / current rules 20. New expeditions are Standard five-floor runs. Legacy Daily and Endless behavior remains available only when continuing existing saves; compatibility fixtures exercise it explicitly.

## Regression command

Run `python tools/run_regressions.py` with Godot 4.6 installed, or pass `--godot PATH`. Use `--all` for the full historical and current suite, or `--suite standard_expeditions validation_reports` for selected scripts. `--timeout` sets each script's deadline in seconds.

The runner stages each script under `work`, rewrites fixture output locations to an isolated directory, invokes the original production modules, detects script errors even when Godot returns zero, and removes the staging directory. Results go to `work/regression_results.json`. Known Godot resource-at-exit cleanup warnings are reported separately from assertion/script failures. Tests of retired starter-chest/forge rules use `tools/historical_run.gd`; current crafted-loadout behavior has dedicated coverage. Never use a personal save as a fixture.

## Progression audit

Run Godot headless with `--path . --log-file ABSOLUTE_PATH --script res://tests/run_balance_audit.gd`. Add `-- --quick` for a nine-expedition smoke run. The complete audit runs 88 campaigns of three consecutive attempts: 264 expeditions across four seed trials, two policies and three profiles. Output is `work/progression_audit.json`.

Fresh uses the actual initial Sword, no permanent skills or extra resources. Developing seeds the chosen base weapon, shield, heavy armor, helmet and amulet at slot level 2, with Kindling 1, Vigor 2, Armor Training 1, Might 2 and Tempo 1. It initially knows only those recipes. Established seeds slot level 5 equipment, discovered runes, all blueprints and a moderate tree investment; its weapons are Bloodbound Sword, Swift Dagger, Keen Axe, Keen Greatblade and Swift Emberblade. Exact starting workshop/tree snapshots are in every result. Resource budgets used to construct fixtures are cleared before expeditions; this audit does not claim those profiles can be earned in three attempts.

Both policies use real movement, encounter processing, pickups, rewards, preparation choices, extraction, crafting, equipment selection and tree purchases. Equipment cannot change during an expedition. The policy solves displayed rune orders, visits one elemental passage per floor and uses flasks below 55% HP. Cautious avoids encounters labelled Deadly by the visible estimator and attempts to retrace its route home. Focused pushes onward. Skill preferences and shopping order are scripted; neither policy models human learning, reaction time or optimal play.

Interpret results as reproducible probes, not human win rates. Inspect ending floors, encounter duration, healing/flasks, unusable offers and purchases together. An eligible elemental investment may be inactive until enough power is acquired; incompatible fixed weapon requirements must never be offered. Zero equipment-mutation or blocked-policy failures is a correctness gate, not a balance target. Family comparisons must hold profile, seed and policy constant.

## Local reports

Settings > help category > Export playtest report writes schema-2 JSON under `user://playtests`. Active-run metrics include independent starting workshop/tree/loadout snapshots, up to 32 floor entries, 128 skill offers/selections and 256 encounter summaries, plus incompatible-offer totals. Encounters record preparation, HP, duration, flasks, healing and the combat recap. Craft metrics record the first crafted item, completed expeditions and previously recorded play seconds; those seconds exclude menu time and the current unfinished expedition, so observe wall-clock time separately. Telemetry consumes no gameplay RNG and persists in ordinary saves and run history. Reports are local and require manual sharing.

## Human validation

Follow `PLAYTEST_GUIDE.md` with three to five new players. Record time to first alternative weapon, explanation of first death, understanding of fixed loadouts/rewards, floor identity and voluntary replay. Automated checks cannot complete this stage. Keep observer notes separate from simulated results and do not label scripted durations as human session durations.

## Recorded automated baseline (2026-11-10)

The complete Standard audit passed its correctness gates: 88 campaigns / 264 expeditions, zero unusable offers, zero equipment changes during expeditions and zero blocked terminal routes. Fresh attempts ended on floors 1-2; developing attempts reached floors 1-5 without a victory in this three-attempt window. Established profiles won 88 of 120 scripted attempts.

| Established weapon | Attempts | Victories | Returned | Deaths |
| --- | ---: | ---: | ---: | ---: |
| Sword | 24 | 24 | 0 | 0 |
| Dagger | 24 | 24 | 0 | 0 |
| Axe | 24 | 6 | 7 | 11 |
| Greatblade | 24 | 11 | 7 | 6 |
| Ember | 24 | 23 | 1 | 0 |

These results identify follow-up questions rather than justify an immediate global difficulty change. Check early crafting pace with fresh humans and compare Axe sustain, armor interaction and floor-4 matchups against the other established weapons. Mean simulated encounter times were 6.10s fresh, 3.52s developing and 2.83s established; they exclude travel/menu time. No human session results are available yet.

Regression verification covered 74 suites: the full pass completed with 73 passing and an obsolete progression expectation failing; after updating the ascent-healing and crafted-restart expectations, that suite and the strengthened validation-report suite both passed targeted reruns. Existing Godot cleanup warnings were tracked separately.
