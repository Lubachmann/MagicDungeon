extends RefCounted
var g
var notice=""
var notice_left=0.0
const GOALS={
	"bloodletter":{"name":"Bloodletter","metric":"vamp_healed","target":60,"requirement":"Heal 60 HP with vampirism across runs.","reward":"Base: +5% vampirism; loses innate dagger evade.","icon":"health","archetype":"dagger"},
	"winterblade":{"name":"Winterblade","metric":"greatblade_kills","target":15,"requirement":"Win 15 fights with a greatblade.","reward":"Base: +8% enemy slow; 15% less base attack.","icon":"ice","archetype":"greatblade"},
	"caustic":{"name":"Caustic brand","metric":"fire_bosses","target":3,"requirement":"Defeat 3 bosses while they are burning.","reward":"Base: remove 0.75 armor/hit; 35% less fire damage/s.","icon":"acid","archetype":"ember"},
	"draft_cache":{"name":"Advanced caches","metric":"runes_solved","target":3,"requirement":"Solve 3 rune puzzles across runs.","reward":"Unlock later-floor caches with different elemental item choices.","icon":"vault","archetype":""}}
static func empty_progress() -> Dictionary:return {"vamp_healed":0,"greatblade_kills":0,"fire_bosses":0,"runes_solved":0}
func _init(game):g=game
func unlocked(id: String) -> bool:return int(g.career.get("mastery",{}).get(GOALS[id].metric,0))>=int(GOALS[id].target)
func available(id: String) -> bool:return g.run_settings.get("mode","")=="daily" or unlocked(id)
func add(metric: String,amount: int) -> void:
	if amount<=0 or g.demo_run:return
	if not g.career.has("mastery"):g.career["mastery"]=empty_progress()
	var before=[]
	for id in GOALS:
		if unlocked(id):before.append(id)
	g.career.mastery[metric]=int(g.career.mastery.get(metric,0))+amount
	for id in GOALS:
		if id not in before and unlocked(id):notice="Unlocked: "+GOALS[id].name+" / Build unlocks in Expedition";notice_left=7;g.log_line(notice)
func enemy_defeated(enemy: Dictionary,tile: Vector2i) -> void:
	if g.mode!="fight" or g.fight.get("position",Vector2i(-1,-1))!=tile:return
	var index=int(g.equipped.get("weapon",-1))
	if index>=0 and g.inventory[index].get("archetype","")=="greatblade":add("greatblade_kills",1)
	if enemy.type==3 and g.battle.get("fire_until",-1)>=g.battle.get("time",0):add("fire_bosses",1)
func roll_variant(item: Dictionary) -> Dictionary:
	if item.slot!="weapon":return item
	var possible=[]
	for id in GOALS:
		if GOALS[id].archetype==item.get("archetype","balanced") and available(id):possible.append(id)
	if not possible.is_empty() and g.rng.randf()<0.35:
		var id=possible[g.rng.randi_range(0,possible.size()-1)];item["variant"]=id;item.name=GOALS[id].name
	return item
func draw() -> void:
	g.front_end.menu_backdrop();g.text(Vector2(75,82),"BUILD UNLOCKS",36,g.GOLD)
	g.front_end.icon_button(Rect2(840,45,350,60),"relic","Relics","codex_next")
	g.draw_wrapped("Earn new loot options by using builds. Unlocks do not change your starting character. Daily includes all variants for everyone.",Vector2(75,124),1100,19,g.INK,2)
	var i=0
	for id in GOALS:
		var info=GOALS[id];var at=Vector2(75+(i%2)*580,185+(i/2)*245);g.panel(Rect2(at,Vector2(550,220)))
		g.ui_icon(info.icon,at+Vector2(20,20),40);g.text(at+Vector2(80,50),info.name,27,g.GOLD)
		var value=mini(info.target,int(g.career.get("mastery",{}).get(info.metric,0)))
		g.draw_wrapped(info.requirement,at+Vector2(20,92),510,19,g.INK,2)
		g.draw_rect(Rect2(at+Vector2(20,125),Vector2(510,8)),Color("39343e"));g.draw_rect(Rect2(at+Vector2(20,125),Vector2(510.0*value/info.target,8)),g.TEAL)
		g.text(at+Vector2(20,160),"UNLOCKED" if unlocked(id) else "%d / %d"%[value,info.target],19,g.TEAL)
		var reward=info.reward
		if g.run_rules>=9 and id=="winterblade":reward="Level 1: +1 Frost power; 15% less item attack."
		if g.run_rules>=9 and id=="caustic":reward="Level 1: +1 Acid power; 35% less Fire potency."
		if g.run_rules>=9 and id=="bloodletter":reward="Level 1: +3.5% vampirism; loses innate dagger evade."
		g.draw_wrapped(reward,at+Vector2(20,190),510,18,g.INK,2);i+=1
	g.front_end.icon_button(Rect2(75,730,250,60),"boots","Back","codex_back")
func tick(delta: float) -> void:
	if g.mode in ["play","fight","inspect","bomb"]:notice_left=maxf(0,notice_left-delta)
func draw_notice() -> void:
	if notice_left>0 and g.mode in ["play","fight","inspect","bomb"]:g.text(Vector2(420,748),notice,18,g.GOLD)
