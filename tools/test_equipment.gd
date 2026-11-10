extends RefCounted
## Regression encounter fixture, not starting equipment. New-run behavior is tested without this helper.
static func arm(g) -> void:
	# These historical mechanics suites verify the saved rules-6 contract. Rules 7 has its own audit/suite.
	if g.run_rules>=7:
		g.run_rules=6;g.inventory.clear();g.equipped.clear();g.bombs=1+g.ember_tree.rank("blastcraft");g.iron=g.ember_tree.rank("smithcraft");g.rng.seed=g.run_seed;g.generate_floor();g.recalculate_stats();g.hp=g.max_hp
	if g.inventory.is_empty():
		g.inventory.append(g.Gear.make("weapon",1,0));g.equipped["weapon"]=0;g.selected_item=0;g.recalculate_stats()
