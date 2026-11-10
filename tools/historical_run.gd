extends RefCounted
## Explicit fixture for contracts of saved runs before the Hearth crafting loop.
static func start(g,seed_value:int,rules:int) -> void:
 g.new_run(seed_value)
 g.run_rules=rules;g.inventory.clear();g.equipped.clear()
 g.bombs=1+g.ember_tree.rank("blastcraft");g.iron=g.ember_tree.rank("smithcraft")
 g.recalculate_stats();g.hp=g.max_hp;g.rng.seed=g.run_seed;g.generate_floor()

## Compatibility fixture only: production starts always use Standard.
static func start_mode(g,seed_value:int,mode:String,rules:int=20) -> void:
 g.new_run(seed_value)
 g.run_rules=rules;g.run_settings={"mode":mode,"vows":{}}
 g.run_skills={} if mode=="daily" else g.skills.duplicate(true)
 if mode=="daily":g.run_seed=g.replay.daily_seed()
 g.inventory.clear();g.equipped.clear()
 if rules>=20:g.smithy.start_loadout()
 g.potions=1+g.ember_tree.rank("flask_reserve")
 g.iron=0;g.run_metrics={"bosses":0,"runes":0,"breaks":0}
 g.recalculate_stats();g.hp=g.max_hp;g.rng.seed=g.run_seed;g.generate_floor()
