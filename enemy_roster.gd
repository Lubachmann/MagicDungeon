extends RefCounted
## Visual identity is independent of saved combat-rule versions.
const BASE_NAMES=["Mire Slime","Bone Guard","Cave Imp"]
const BASE_SPRITES=["mossling","husk","bat"]
const BOSSES={"castellan":["Mire Colossus","colossus"],"tide":["Tide Ogre","tide_ogre"],"abbot":["Ash Necromancer","necromancer"],"furnace":["Furnace Demon","furnace_demon"],"eclipse":["Eclipse Seraph","seraph"]}
const EXTRA=["orc_raider","revenant","fiend","skullguard","cultist","colossus","tide_ogre","necromancer","furnace_demon","seraph","sentinel"]
const GUARD_NAMES={"Vault champion":"Vault Knight","Passage sentinel":"Passage Knight","Gate champion":"Gate Knight","Chest keeper":"Chest Knight"}
static func title(e: Dictionary) -> String:
	if int(e.type)==3:return BOSSES.get(signature(e),BOSSES.castellan)[0]
	if e.name in GUARD_NAMES:return GUARD_NAMES[e.name]
	if e.name in ["Mossling","Iron husk","Needle bat"]:return BASE_NAMES[int(e.type)]
	return e.name
static func signature(e: Dictionary) -> String:
	return e.get("signature",{"iron":"castellan","tide":"tide","ash":"abbot"}.get(e.get("boss_kind","iron"),"castellan"))
static func sprite(e: Dictionary) -> String:
	if int(e.type)==3:return BOSSES.get(signature(e),BOSSES.castellan)[1]
	if e.get("gatekeeper",false) or e.name in GUARD_NAMES or e.name in GUARD_NAMES.values():return "sentinel"
	var family=e.get("family","")
	if family in preload("res://flow_combat.gd").FAMILIES:return preload("res://flow_combat.gd").FAMILIES[family].sprite
	return BASE_SPRITES[int(e.type)]
static func level(e: Dictionary,fallback_floor: int=1) -> int:
	if e.has("level"):return int(e.level)
	var depth=int(e.get("depth",0));var floor_number=int(e.get("floor",fallback_floor))
	return 1+2*maxi(0,floor_number-1)+int(depth/3)+[0,1,0,3][int(e.type)]+(1 if e.get("family","")!="" else 0)+(1 if e.get("elite",false) else 0)+(1 if e.get("gatekeeper",false) else 0)+(1 if e.get("affix","")!="" else 0)
