extends RefCounted
var g
const FLOORS=[
	["The Fallen Keep","Pikemen pierce armor. Hits break guards; elements bypass them. Explore for boss preparation.","keep"],
	["The Drowned Archive","Leeches drain HP; the Tide Ogre follows up. Frost, shields or draining the cisterns help.","water"],
	["The Ashen Crypt","Wisps resist Fire until chilled or corroded. Burn the Necromancer or douse braziers to cut healing.","embers"],
	["The Shattered Foundry","Fast hits or greatblades break plates; Frost cools the Furnace. Sabotage offers another answer.","brittle"],
	["The Eclipse Sanctum","Frequent specials and Shade dodges test your build. Frost, crits or lighting beacons can help.","eclipse"]]
const PREPARATION={
	"keep":{"label":"Weaken boss: -4 armor and -1 attack","help":"Repeated hits or a greatblade break guards; elements bypass them. Preparation weakens the boss.","element":"acid"},
	"water":{"label":"Drain cisterns: weaker life drain and follow-ups","help":"Preparation halves Leech healing and reduces Tide follow-up power from 60% to 40%. Frost slows attacks; shields deny Leech healing.","element":"ice"},
	"embers":{"label":"Douse braziers: halve enemy regeneration","help":"Preparation halves regeneration. Fire also halves the Necromancer's healing; Frost or Acid removes Wisp fire resistance.","element":"fire"},
	"brittle":{"label":"Sabotage forge: fewer plates and slower Heat","help":"Preparation leaves Constructs with one plate and halves Heat buildup. Repeated hits or greatblades break plates; Frost cools the Furnace.","element":"acid"},
	"eclipse":{"label":"Light beacons: weaken dodges and resistance","help":"Preparation makes Shades dodge every sixth hit and weakens boss resistance. Frost stops Shade dodges; crits or armor breaks cancel boss resistance.","element":"ice"}}
func preparation() -> Dictionary:return PREPARATION[rule()]
func prepare_floor() -> void:
	if g.floor_flags.get("prepared_floor",-1)==g.floor_number:return
	g.floor_flags["prepared_floor"]=g.floor_number
	for data in g.rooms.values():
		for enemy in data.entities.values():
			if enemy.get("kind","")!="enemy":continue
			enemy["floor_prepared"]=rule()
			if rule()=="keep" and int(enemy.type)==3:
				enemy.armor=maxf(0,float(enemy.armor)-4);enemy.attack=maxf(1,float(enemy.attack)-1);enemy["preparation_weakened"]=true
	g.log_line(preparation().label+". Applies on this floor.")
func _init(game):g=game
func rule() -> String:return FLOORS[posmod(g.floor_number-1,5)][2] if g.run_rules>=4 else ""
func handle(id: String) -> bool:
	if id=="combat_speed_toggle":
		if g.mode=="fight":
			g.battle["playback_rate"]=2 if int(g.battle.get("playback_rate",1))==1 and float(g.battle.hp)>float(g.battle.max_hp)*0.35 else 1
		return true
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
static func weapon_progress(s: Dictionary) -> Dictionary:
	var weapon=str(s.get("build",{}).get("weapon","unarmed"));var count=0;var total=3;var label=""
	match weapon:
		"balanced":count=int(s.get("successful_hits",0))%4;total=4;label="Shield"
		"dagger":count=int(s.get("combo",0));label="Combo"
		"axe":count=int(s.get("p_hits",0))%3;label="Cleave"
		"greatblade":count=int(s.get("p_hits",0))%3;label="Sunder"
		"ember":count=int(s.get("successful_hits",0))%3;label="Flare"
	return {"label":label,"count":count,"total":total}
func draw() -> void:
	if g.mode not in ["play","fight"]:return
	var build=g.combat_build();var weapon=build.get("weapon","unarmed")
	var entry=g.Combat.Flow.WEAPONS.get(weapon,["Unarmed","Weapon strikes resolve automatically."])
	if weapon=="plain":entry=[g.inventory[g.equipped.weapon].name,"Plain starter: damage and attack interval. No innate weapon ability. Imprints and other gear can add effects."]
	if g.mode=="play":
		g.text(Vector2(430,727),"Auto combat / "+entry[0],17,g.TEAL)
		return
	g.panel(Rect2(64,245,242,365))
	g.text(Vector2(80,280),entry[0].to_upper(),23,g.GOLD)
	g.draw_wrapped(entry[1],Vector2(80,321),210,18,g.INK,6)
	var progress=weapon_progress(g.battle)
	if progress.label!="":
		g.text(Vector2(80,450),"%s: %d / %d"%[progress.label,progress.count,progress.total],18,g.TEAL)
		g.draw_rect(Rect2(80,462,210,7),Color("39343e"));g.draw_rect(Rect2(80,462,210.0*progress.count/progress.total,7),g.TEAL)
	g.button(Rect2(80,560,210,36),"Speed: %dx / Enter"%int(g.battle.get("playback_rate",1)),"combat_speed_toggle")
	g.text(Vector2(80,638),"%s: flask / A: speed"%g.controls.label("heal"),17,g.INK)
	g.text(Vector2(80,664),"1x below 35% HP",17,g.INK)
	g.stat_ui.icon("evade",Vector2(80,485),24);g.text(Vector2(117,506),"%.1f%%"%(build.evade*100),18,g.TEAL)
	g.stat_ui.icon("vampirism",Vector2(80,525),24);g.text(Vector2(117,546),"%.1f%%"%(build.vampirism*100),18,g.TEAL)
