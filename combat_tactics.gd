extends RefCounted
var g
const FLOORS=[
	["The Fallen Keep","Pikeman specials ignore 75% armor. The Castellan raises a guard below 50% HP.","keep"],
	["The Drowned Archive","Leeches heal from damage. The Regent uses 2-hit attacks. Enemy opening attacks are delayed by 0.5s.","water"],
	["The Ashen Crypt","Burns last 1s longer. Ice or acid removes Wisp fire resistance. Fire reduces boss healing by 50%.","embers"],
	["The Shattered Foundry","Each hit removes 1 armor. Greatblades break Construct plates. Ice cools the boss.","brittle"],
	["The Eclipse Sanctum","Enemies use specials every 2 attacks. Ice stops Shade dodges. Critical hits break boss resistance.","eclipse"]]
func _init(game):g=game
func rule() -> String:return FLOORS[posmod(g.floor_number-1,5)][2] if g.run_rules>=4 else ""
func handle(id: String) -> bool:
	# Old bindings/actions are harmless when loading older settings.
	return id in ["ability_use","ability_cycle","fight_continue"]
func victory(_enemy: Dictionary,tile: Vector2i) -> void:
	if g.run_rules<4:return
	g.toxic_echo=(1.0 if g.run_rules>=9 else 0.10) if "contagion" in g.relics and g.battle.get("poisoned",false) else 0.0
	if "wildfire" not in g.relics or g.battle.get("fire_until",-1.0)<g.battle.get("time",0.0):return
	var blast=8+4*int(g.elements.fire)
	if g.run_rules>=9:blast=roundi(8+4*preload("res://build_stats.gd").calculate(g).element_totals.fire)
	var victims=[]
	for p in g.rooms[g.room].entities:
		var other=g.rooms[g.room].entities[p]
		if p==tile or other.kind!="enemy" or absi(p.x-tile.x)+absi(p.y-tile.y)>2:continue
		var dealt=minf(other.hp,blast);other.hp-=dealt;g.summary.dealt+=dealt
		g.motes.append({"at":g.ORIGIN+Vector2(p)*g.TILE,"value":"BLAST -%d"%dealt,"ttl":1.2,"color":g.GOLD})
		if other.hp<=0:victims.append(p)
	for p in victims:g.defeat_enemy(p,g.rooms[g.room].entities[p])
	g.log_line("Wildfire explodes: %d damage to enemies within two tiles."%blast)
func draw() -> void:
	if g.mode not in ["play","fight"]:return
	var build=g.combat_build();var weapon=build.get("weapon","unarmed")
	var entry=g.Combat.Flow.WEAPONS.get(weapon,["Unarmed","Weapon strikes resolve automatically."])
	if weapon=="plain":entry=[g.inventory[g.equipped.weapon].name,"Plain starter: damage and attack interval. No innate weapon ability. Imprints and other gear can add effects."]
	if g.mode=="play":
		g.text(Vector2(430,727),"Auto combat / "+entry[0],17,g.TEAL)
		return
	g.panel(Rect2(64,245,242,290))
	g.text(Vector2(80,280),entry[0].to_upper(),23,g.GOLD)
	g.draw_wrapped(entry[1],Vector2(80,321),210,18,g.INK,6)
	g.stat_ui.icon("evade",Vector2(80,449),24);g.text(Vector2(117,470),"%.1f%%"%(build.evade*100),18,g.TEAL)
	g.stat_ui.icon("vampirism",Vector2(80,489),24);g.text(Vector2(117,510),"%.1f%%"%(build.vampirism*100),18,g.TEAL)
