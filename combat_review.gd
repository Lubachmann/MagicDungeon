extends RefCounted
var g
func _init(game):g=game
func begin() -> void:
	g.run_metrics["last_fight"]={"enemy":g.fight.name,"floor":g.floor_number,"signature":g.fight.get("signature",""),"enemy_max":g.fight.max,"ward":g.fight.get("ward_active",false),"healed":0.0,"physical":0.0,"fire":0.0,"poison":0.0,"armor":0.0,"taken":0.0,"drained":0,"dodges":0,"crits":0,"return":"dead"}
func event(hit: Dictionary) -> void:
	if not g.run_metrics.has("last_fight"):begin()
	var s=g.run_metrics.last_fight
	s.healed+=float(hit.get("enemy_heal",0));s.drained+=int(hit.get("vamp_heal",0));s.armor+=float(hit.get("armor_prevented",0))
	if hit.player:
		if hit.get("poison_tick",false):s["poison"]=float(s.get("poison",0))+hit.actual_damage
		elif hit.burn:s.fire+=hit.actual_damage
		else:s.physical+=float(hit.get("physical_damage",hit.actual_damage));s.fire+=float(hit.get("element_damage",0))
	else:s.taken+=float(hit.actual_damage)
	if hit.get("evaded",false):s.dodges+=1
	if hit.crit:s.crits+=1
	if g.battle.done:s["won"]=g.battle.won
func handle(id: String) -> bool:
	if id=="recap_open":g.run_metrics["recap_return"]=g.mode;g.mode="recap";return true
	if id=="recap_close":g.mode=g.run_metrics.get("recap_return","dead");return true
	return false
func advice(s: Dictionary) -> String:
	if s.get("healed",0)>=float(s.get("enemy_max",1))*0.2:
		if s.get("signature","")=="abbot":return "Burn the Abbot to cut healing by 50%. Interrupts delay the next heal."
		return "Explore for its healing rune before fighting. Disabling it removes bonus healing." if s.get("ward",false) else "Its healing extended the fight. Try more damage or a way to interrupt healing."
	if s.get("poison",0)>s.get("physical",0):return "Poison dealt most of your damage. Faster attacks apply more counters; Frost and armor give the poison time to build."
	if s.get("armor",0)>maxf(5,float(s.get("physical",0))*0.3):return "Armor blocked much of your weapon damage. Acid, a greatblade or armor-piercing relics can help."
	return "Compare the enemy's damage and attack interval with your build. Frost slows attacks; poison accumulates damage. Healing or another route may help."
func draw() -> void:
	g.front_end.menu_backdrop();g.panel(Rect2(150,75,980,680));g.text(Vector2(195,135),"LAST FIGHT",36,g.GOLD)
	var s=g.run_metrics.get("last_fight",{})
	if s.is_empty():g.text(Vector2(195,230),"No combat recap is available yet.",24)
	else:
		g.text(Vector2(195,185),"%s / Floor %d"%[s.enemy,s.floor],24,g.GOLD)
		var rows=[["attack","Weapon damage dealt",s.physical],["fire","Fire damage dealt",s.fire],["poison","Poison damage dealt",s.get("poison",0)],["armor","Armor mitigation before shields",s.armor],["potion","Enemy HP restored",s.healed],["health","Damage taken",s.taken],["health","HP from vampirism",s.drained]]
		for i in range(rows.size()):
			var at=Vector2(195,235+i*51);g.stat_ui.icon({"attack":"weapon_dps","fire":"fire","poison":"poison","armor":"armor","potion":"max_hp","health":"current_hp"}.get(rows[i][0],"attack"),at,28,rows[i][1],"Total for the last encounter. This is an encounter summary, not an item bonus.");g.text(at+Vector2(45,23),rows[i][1],21);g.text(at+Vector2(695,23),"%.1f"%float(rows[i][2]),27,g.GOLD)
		g.text(Vector2(195,565),"Critical hits: %d / Dodges: %d"%[s.crits,s.dodges],20,g.INK)
		g.draw_wrapped(advice(s),Vector2(195,595),870,22,g.TEAL,3)
	g.button(Rect2(195,685,870,48),"Back / Esc","recap_close")
