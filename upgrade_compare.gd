extends RefCounted
const Stats=preload("res://build_stats.gd")
var g
var hovered_ability=""
func _init(game):g=game
func draw(id: String,blessing: bool) -> void:
	blessing=blessing or (g.run_rules>=20 and g.UPGRADE_INFO.has(id))
	var old=Stats.calculate(g);var next=Stats.upgrade_preview(g,id,blessing)
	g.panel(Rect2(840,150,380,520));g.text(Vector2(860,185),"YOUR BUILD / PREVIEW",23,g.GOLD)
	g.text(Vector2(1005,220),"NOW",18);g.text(Vector2(1066,220),"GAIN",18);g.text(Vector2(1136,220),"AFTER",18,g.TEAL)
	var rows=[]
	var before=old.get("element_totals",old.elements);var after=next.get("element_totals",next.elements)
	for element in ["fire","ice","acid","poison"]:
		if before[element]>0 or after[element]>0:rows.append({"name":(("Fire potency" if element=="fire" else "Frost / hit" if element=="ice" else element.capitalize()+" / hit") if g.run_rules>=9 else element.capitalize()+" stacks"),"old":"%.1f"%before[element],"new":"%.1f"%after[element],"delta":"%+.1f"%(after[element]-before[element])})
	var keys=g.build_view.active(old,next)
	for key in ["attack","armor","max_hp","interval"]:
		if not is_equal_approx(float(old[key]),float(next[key])):keys.push_front(key)
	for key in keys:
		if g.run_rules>=9 and key in ["ice","acid","poison"]:continue
		if not is_equal_approx(float(old[key]),float(next[key])):rows.append({"name":"Crit chance limit" if key=="crit_cap" else g.build_view.meta(key)[0],"old":g.build_view.value(key,old),"new":g.build_view.value(key,next),"delta":difference(key,old,next)})
	if not is_equal_approx(old.acid_cap,next.acid_cap):rows.append({"name":"Max armor removed","old":"%.0f"%old.acid_cap,"new":"%.0f"%next.acid_cap,"delta":"%+.0f"%(next.acid_cap-old.acid_cap)})
	if id=="bulwark" and not blessing and "bulwark" not in g.relics:rows.append({"name":"Armor-break shield","old":"0","new":str(6+2*next.elements.acid),"delta":"+%d"%(6+2*next.elements.acid)})
	for i in range(mini(9,rows.size())):
		var row=rows[i];var at=Vector2(860,251+i*29)
		g.stat_ui.label(g.stat_ui.resolve(row.name),at,23);g.text(at+Vector2(27,0),g.stat_ui.short_name(g.stat_ui.resolve(row.name)),15,g.INK);g.text(at+Vector2(145,0),row.old,18)
		g.text(at+Vector2(208,0),row.delta,19,g.TEAL if row.old!=row.new else g.INK)
		g.text(at+Vector2(275,0),row.new,20,g.TEAL if row.old!=row.new else g.INK)
	if rows.is_empty():g.draw_wrapped("Your stats stay the same. This upgrade adds the ability described below.",Vector2(860,270),330,20,g.INK,3)
	g.text(Vector2(860,520),"ABILITIES / HOVER FOR DETAILS",18,g.GOLD)
	var abilities=g.relics.duplicate()
	if not blessing and id not in abilities:abilities.append(id)
	hovered_ability=""
	for i in range(abilities.size()):
		var ability=abilities[i];var at=Vector2(860+(i%8)*43,535+(i/8)*34)
		g.ui_icon(g.replay.relic_icon(ability),at,28)
		if ability==id:g.draw_rect(Rect2(at-Vector2.ONE*2,Vector2(32,32)),g.TEAL,false,1)
		if Rect2(at,Vector2(32,32)).has_point(g.design_mouse()):hovered_ability=ability
	# Changes are pure calculations; the detail strip belongs to the hovered ability or candidate.
	var detail_id=hovered_ability if hovered_ability!="" else id
	var detail_blessing=blessing and hovered_ability==""
	var elements=([detail_id] if detail_blessing and detail_id in ["fire","ice","acid","poison"] else g.choice_ui.STACKS.get(detail_id,[])) if g.run_rules>=9 else []
	g.panel(Rect2(60,635,1160,83))
	if elements.is_empty():
		var detail=(g.RELICS[hovered_ability][0]+": "+g.choice_ui.explain(hovered_ability,false)) if hovered_ability!="" else g.choice_ui.explain(id,blessing)
		g.draw_wrapped(detail,Vector2(78,662),1120,18,g.INK,3)
	else:
		var effect="Adds "+{"fire":"Fire","ice":"Frost","acid":"Acid","poison":"Poison"}.get(detail_id,"")+" power." if detail_blessing else g.relic_description(detail_id)
		if g.run_rules>=17:
			var milestones=[];var rules=preload("res://element_rules.gd")
			for element in elements:
				var before_power=rules.element_power(old.build,element);var after_power=rules.element_power(next.build,element)
				if before_power<4 and after_power>=4:milestones.append({"fire":"Heat unlocked","ice":"Freeze damage unlocked","acid":"Armor-break burst unlocked","poison":"Poison bursts unlocked"}[element])
				if element in ["fire","acid"] and before_power<8 and after_power>=8:milestones.append("Stronger "+("Heat" if element=="fire" else "Corrosion")+" limit")
			if not milestones.is_empty():effect="UNLOCKED: "+" / ".join(milestones)
		g.draw_wrapped(effect,Vector2(78,658),1120,18,g.GOLD,1)
		for i in range(elements.size()):
			var element=elements[i];var at=Vector2(78+i*560,674)
			g.stat_ui.icon({"fire":"fire_power","ice":"ice","acid":"acid","poison":"poison"}[element],at,27)
			g.draw_wrapped(preload("res://element_rules.gd").brief(element,g.run_rules>=17),at+Vector2(36,18),500 if elements.size()>1 else 1030,18,g.INK,2)

func difference(key: String,old: Dictionary,next: Dictionary) -> String:
	var delta=float(next[key])-float(old[key])
	if key=="interval":return "%+.2fs"%delta
	if key in (["ice","poison","evade","vampirism","crit_chance","crit_mult","crit_cap","armor_pierce","opening_damage","first_hit_reduction"] if g.run_rules<9 else ["evade","vampirism","crit_chance","crit_mult","crit_cap","armor_pierce","opening_damage","first_hit_reduction"]):return "%+.1f%%"%(delta*100)
	return "%+.1f"%delta

func draw_side(id: String,rect: Rect2) -> void:
	var old=Stats.calculate(g);var next=Stats.upgrade_preview(g,id,false)
	var at=rect.position
	g.panel(rect);g.text(at+Vector2(20,32),g.relic_name(id),23,g.GOLD)
	g.draw_wrapped(g.relic_description(id),at+Vector2(20,65),rect.size.x-40,19,g.INK,5)
	var elements=[id] if id in ["fire","ice","acid","poison"] else g.choice_ui.STACKS.get(id,[])
	if not elements.is_empty():
		var element=elements[0]
		g.stat_ui.icon({"fire":"fire_power","ice":"ice","acid":"acid","poison":"poison"}[element],at+Vector2(20,145),24)
		g.draw_wrapped(preload("res://element_rules.gd").brief(element,g.run_rules>=17),at+Vector2(52,164),rect.size.x-70,17,g.INK,2)
	var offers=preload("res://skill_offers.gd")
	if offers.has_build_requirement(id):
		var missing=offers.build_requirements(g,id,old)
		g.draw_wrapped("Needs: "+", ".join(missing) if not missing.is_empty() else "Build ready; trigger during combat",at+Vector2(20,198),rect.size.x-40,16,Color("e99f88") if not missing.is_empty() else g.TEAL,1)
	else:g.text(at+Vector2(20,198),"See effect and trigger above",16,g.TEAL)
	g.text(at+Vector2(20,220),"YOUR BUILD",20,g.GOLD)
	g.text(at+Vector2(235,220),"NOW",16,g.INK);g.text(at+Vector2(310,220),"AFTER",16,g.TEAL)
	var rows=[];var before=old.get("element_totals",old.elements);var after=next.get("element_totals",next.elements)
	for element in ["fire","ice","acid","poison"]:
		if before[element]>0 or after[element]>0:
			rows.append({"key":element,"name":"Fire" if element=="fire" else "Frost" if element=="ice" else element.capitalize(),"old":"%.1f"%before[element],"new":"%.1f"%after[element]})
	var keys=g.build_view.active(old,next)
	for key in ["attack","armor","max_hp","interval"]:
		if not is_equal_approx(float(old[key]),float(next[key])) and key not in keys:keys.push_front(key)
	for key in keys:
		if g.run_rules>=9 and key in ["ice","acid","poison"]:continue
		if not is_equal_approx(float(old[key]),float(next[key])):
			rows.push_front({"key":key,"name":g.build_view.meta(key)[0],"old":g.build_view.value(key,old),"new":g.build_view.value(key,next)})
	for i in range(mini(5,rows.size())):
		var row=rows[i];var p=at+Vector2(20,250+i*27)
		g.stat_ui.label(row.key,p,20);g.text(p+Vector2(26,0),row.name,16,g.INK)
		g.text(p+Vector2(215,0),row.old,17,g.INK);g.text(p+Vector2(290,0),row.new,17,g.TEAL if row.old!=row.new else g.INK)
	if rows.is_empty():g.draw_wrapped("Adds the ability above to your build.",at+Vector2(20,255),rect.size.x-40,18,g.INK,3)
