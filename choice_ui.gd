extends RefCounted
var g
var comparison
var pointer=Vector2(-10000,-10000)
var preview_index=-1
var preview_stamp=0
const SHORT={"critical_horizon":"+15% Crit limit","unbound_aim":"+15% Crit limit","precision":"+20% Crit chance","needle":"Ignore 60% armor","bloom":"+4 HP / victory","spark":"+75% opening damage","leech":"+2 HP / 3 hits","ward":"−50% opening damage","cinder":"+1 Fire stack","frost":"+1 Ice stack","solvent":"+1 Acid stack","venom":"+1 Poison stack","shatter":"+1 Ice stack","bulwark":"+1 Acid stack","contagion":"+1 Poison stack","steamglass":"+1 Fire · +1 Ice","corrosive_flame":"+1 Fire · +1 Acid","black_ice":"+1 Ice · +1 Poison","toxic_spark":"+1 Poison · +1 Fire"}
const NEW_HEADLINES={"quickdraw":"Attack instantly at fight start","heavy_momentum":"+45% heavy hit / −20% speed","combustion":"4 Heat: Fire burst","toxic_harvest":"Poison bursts ×2","exposed_core":"+25% after armor break","glacial_crusher":"+30% vs slowed","venom_edge":"+25% vs poisoned","caustic_burn":"Burns: +25% damage","frozen_precision":"Crits: +20% damage","blood_harvest":"+50% vampirism healing","shieldbreaker":"+25% vs armor","warded_blade":"+25% while shielded","ashen_charge":"+20% vs burning","toxic_glacier":"Poison adds Frost","breakthrough":"+75% after a break","frost_shatter":"+50% for 3 Frost"}
const NEW_NOTES={"quickdraw":"Then use normal interval","heavy_momentum":"Axe / greatblade","combustion":"Heavy weapon + 4 Fire","toxic_harvest":"4 Poison power","exposed_core":"4 Acid power","glacial_crusher":"Axe / greatblade + Frost","venom_edge":"Dagger + Poison","caustic_burn":"Fire + Acid","frozen_precision":"Critical hits + Frost","blood_harvest":"Vampirism + Poison","shieldbreaker":"Axe / greatblade","warded_blade":"Sword + shield","ashen_charge":"Fire + weapon hits","toxic_glacier":"Frost + Poison","breakthrough":"Axe / greatblade + defense break","frost_shatter":"Axe / greatblade + Frost"}
const STACKS={"wildfire":["fire"],"cinder":["fire"],"frost":["ice"],"shatter":["ice"],"solvent":["acid"],"bulwark":["acid"],"venom":["poison"],"contagion":["poison"],"steamglass":["fire","ice"],"corrosive_flame":["fire","acid"],"black_ice":["ice","poison"],"toxic_spark":["poison","fire"]}
const BONUS={"wildfire":"Burning kills explode","precision":"Max 60% Crit chance","ruin":"Max 300% of normal damage","cinder":"Every 3rd burn: +50% damage","frost":"+20% vs chilled foes","solvent":"3 armor stripped / hit","venom":"Poison before combat","shatter":"3rd ice hit delays the enemy","bulwark":"Shield when armor breaks","contagion":"Next enemy: 10% less damage","steamglass":"Stronger critical hits","corrosive_flame":"Burns strip armor","black_ice":"Ice + poison: +2 shield / 3 hits","toxic_spark":"Poison + fire restore HP"}
func _init(game):g=game;comparison=preload("res://upgrade_compare.gd").new(game)
static func interval(rate: float) -> float:return 1.0/maxf(0.1,rate)
static func timing(rate: float) -> String:return "Every %.2fs"%interval(rate)
func element_gain(element: String) -> String:
	var current=preload("res://build_stats.gd").calculate(g)
	var future=preload("res://build_stats.gd").upgrade_preview(g,element,true)
	var gain=float(future.element_totals[element])-float(current.element_totals[element])
	return "+%d"%roundi(gain) if is_equal_approx(gain,roundf(gain)) else "+%.1f"%gain
func summary(id: String) -> String:
	if g.run_rules>=17 and id=="frost_shatter":return "After freeze: +100% hit"
	if NEW_HEADLINES.has(id):return NEW_HEADLINES[id]
	if g.run_rules>=9 and STACKS.has(id):
		var labels={"fire":"Fire potency","ice":"Frost / hit","acid":"Acid / hit","poison":"Poison / hit"};var values=[]
		for element in STACKS[id]:values.append(element_gain(element)+" "+labels[element])
		return " · ".join(values)
	if g.run_rules>=7:
		var next=preload("res://build_stats.gd").upgrade_preview(g,id)
		if id=="precision":return "+8% Crit chance"
		if id=="ruin":return "Crit: %.0f%% → %.0f%%"%[g.crit_mult*100,next.crit_mult*100]
		if id=="haste":return "%.2fs → %.2fs"%[interval(g.speed),next.interval]
		if id in ["critical_horizon","unbound_aim"]:return "+15% Crit limit"
	if id=="ruin":return "Crit: %.0f%% → %.0f%%"%[g.crit_mult*100,minf(3,g.crit_mult+0.5)*100]
	if id=="haste":return "%.2fs → %.2fs"%[interval(g.speed),interval(g.speed+0.25)]
	if STACKS.has(id):
		var parts=[]
		for element in STACKS[id]:parts.append("+%d %s%s"%[1 if g.run_rules>=9 or g.elements[element]<3 else 0,element.capitalize()," (MAX)" if g.run_rules<9 and g.elements[element]>=3 else (" stack" if STACKS[id].size()==1 else "")])
		return " · ".join(parts)
	return SHORT.get(id,"Upgrade")
var level_elapsed=10.0
const INTRO_TIME=1.0
func start_level() -> void:
	level_elapsed=0.0;preview_index=-1;preview_stamp=0
func level_ready() -> bool:return level_elapsed>=INTRO_TIME
func skip_level_intro() -> void:
	level_elapsed=INTRO_TIME;g.queue_redraw()
func tick(delta: float) -> void:
	if g.mode=="relic" and not level_ready():level_elapsed=minf(INTRO_TIME,level_elapsed+delta)
func cards(blessing: bool=false) -> void:
	if blessing:legacy_cards(true);return
	level_cards()
func level_cards() -> void:
	g.draw_rect(Rect2(0,0,1280,840),Color(0.01,0.01,0.02,0.80))
	var progress=clampf((level_elapsed-0.35)/0.55,0.0,1.0)
	progress=progress*progress*(3.0-2.0*progress)
	var size=roundi(lerpf(66,48,progress))
	var heading="LEVEL UP!"
	var width=g.text_face(size).get_string_size(heading,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	g.text(Vector2(640-width/2.0,lerpf(430,145,progress)),heading,size,g.GOLD)
	if not level_ready():
		g.text(Vector2(550,475),"Enter to continue",18,g.INK)
		return
	g.text(Vector2(507,175),"LEVEL %d  /  CHOOSE ONE"%g.reward_level,20,g.TEAL)
	var options=g.choices
	var stamp=hash([options,g.reward_level])
	if stamp!=preview_stamp:preview_stamp=stamp;preview_index=-1
	var mouse=pointer if pointer.x>-9999 else g.design_mouse()
	var hovered=-1
	for i in range(options.size()):
		var id=options[i];var at=Vector2(245,205+i*100);var rect=Rect2(at,Vector2(465,90))
		var rank=preload("res://skill_offers.gd").rarity(id) if g.run_rules>=11 else "Common"
		g.button(rect,"","relic"+str(i))
		if rank!="Common":
			var accent=Color("85bcf2") if rank=="Rare" else Color("d7a4ff")
			g.draw_rect(rect.grow(-5),Color(accent,0.12));g.draw_rect(rect.grow(-5),accent,false,2)
		if not g.menu_keyboard and rect.has_point(mouse):hovered=i
		g.ui_icon(g.replay.relic_icon(id),at+Vector2(15,20),48,g.GOLD)
		g.text(at+Vector2(78,33),g.RELICS[id][0],23,g.GOLD)
		g.draw_wrapped(summary(id),at+Vector2(78,61),300,19,g.TEAL,1)
		if rank!="Common":g.text(at+Vector2(375,30),rank.to_upper(),16,Color("85bcf2") if rank=="Rare" else Color("d7a4ff"))
	g.front_end.icon_button(Rect2(245,625,465,50),"relic","Reroll / %d"%g.rerolls_left,"relic_reroll",false,g.rerolls_left>0 and can_reroll())
	g.button(Rect2(710,625,400,50),"Your full build","build_open")
	if g.menu_keyboard and not g.buttons.is_empty():
		var focused=str(g.buttons[clampi(g.session.focused,0,g.buttons.size()-1)].id)
		var suffix=focused.trim_prefix("relic")
		preview_index=int(suffix) if focused.begins_with("relic") and suffix.is_valid_int() and int(suffix)<options.size() else -1
	elif hovered>=0:preview_index=hovered
	elif not Rect2(710,205,400,390).has_point(mouse):preview_index=-1
	if preview_index>=0 and preview_index<options.size():comparison.draw_side(options[preview_index],Rect2(710,205,400,390))

func legacy_cards(blessing: bool=false) -> void:
	g.front_end.menu_backdrop()
	g.text(Vector2(78,70),"CHOOSE A BLESSING" if blessing else "LEVEL UP! / LEVEL %d"%g.reward_level,30,g.GOLD)
	g.text(Vector2(78,99),"Choose one upgrade. Hover to compare with your current build.",20)
	if not blessing and g.run_rules>=11:g.text(Vector2(78,125),"Rare skills: level 4+  /  Epic skills: level 7+",18,g.TEAL)
	var options=g.blessings if blessing else g.choices
	var stamp=hash([options,blessing,g.reward_level])
	if stamp!=preview_stamp:preview_stamp=stamp;preview_index=0
	var selected=clampi(g.session.focused if g.menu_keyboard else preview_index,0,maxi(0,options.size()-1))
	for i in range(options.size()):
		var id=options[i];var at=Vector2(60+(i%2)*380,150+(i/2)*245);var rect=Rect2(at,Vector2(355,215))
		var rank=preload("res://skill_offers.gd").rarity(id) if not blessing and g.run_rules>=11 else "Common"
		g.button(rect,"",("upgrade" if blessing else "relic")+str(i))
		if rank!="Common":
			var accent=Color("85bcf2") if rank=="Rare" else Color("d7a4ff")
			var tint=Color("294964") if rank=="Rare" else Color("573568")
			g.draw_rect(rect.grow(-5),Color(tint,0.38 if rank=="Rare" else 0.48))
			g.draw_rect(rect.grow(-5),accent,false,2 if rank=="Rare" else 3)
			if rank=="Epic":
				g.draw_rect(rect.grow(-10),Color(accent,0.55),false,1)
				g.draw_rect(Rect2(at+Vector2(9,9),Vector2(9,9)),accent)
				g.draw_rect(Rect2(at+Vector2(337,9),Vector2(9,9)),accent)
		if not g.menu_keyboard and rect.has_point(pointer if pointer.x>-9999 else g.design_mouse()):selected=i
		var icon=g.UPGRADE_INFO[id][2] if blessing else g.replay.relic_icon(id)
		g.ui_icon(icon,at+Vector2(20,20),44,g.ELEMENT_COLORS.get(id,g.GOLD))
		g.text(at+Vector2(80,48),("Frost infusion" if id=="ice" and g.run_rules>=9 else g.UPGRADE_INFO[id][0]) if blessing else g.RELICS[id][0],22,g.GOLD)
		if not blessing and g.run_rules>=11:
			g.text(at+Vector2(230,72),rank.to_upper(),16,Color("cb90e8") if rank=="Epic" else Color("80bce2") if rank=="Rare" else g.INK)
		var headline=summary(id)
		if g.run_rules>=17 and id=="frost_shatter":headline="After freeze: +100% hit"
		if blessing:headline={"attack":"+5 Attack","guard":"+3 Armor","fire":"+1 Fire stack","ice":"+1 Ice stack","acid":"+1 Acid stack","poison":"+1 Poison stack","focus":"+20% Crit chance","ferocity":"Crits: +50% base damage"}[id]
		if blessing and g.run_rules>=7:headline={"attack":"+3 Attack","guard":"+2 Armor / +6% speed","focus":"+6% Crit chance","ferocity":"Crits: +20% base damage"}.get(id,headline)
		if blessing and g.run_rules>=9 and id in ["fire","ice","acid","poison"]:headline=element_gain(id)+" "+{"fire":"Fire potency","ice":"Frost / hit","acid":"Acid / hit","poison":"Poison / hit"}[id]
		var element_types=([id] if blessing and id in ["fire","ice","acid","poison"] else STACKS.get(id,[])) if g.run_rules>=9 else []
		if element_types.is_empty():g.draw_wrapped(headline,at+Vector2(20,110),315,27,g.TEAL,2)
		else:
			for element_index in range(element_types.size()):
				var element=element_types[element_index];var p=at+Vector2(20+element_index*157,84)
				g.stat_ui.icon({"fire":"fire_power","ice":"ice","acid":"acid","poison":"poison"}[element],p,26)
				g.text(p+Vector2(32,21),element_gain(element)+" "+{"fire":"Fire","ice":"Frost/hit","acid":"Acid/hit","poison":"Poison/hit"}[element],18 if element_types.size()>1 else 21,g.TEAL)
		var footer=("%.2fs → %.2fs"%[interval(g.speed),preload("res://build_stats.gd").upgrade_preview(g,id,true).interval] if id=="guard" else "Hover to preview") if blessing else BONUS.get(id,"Faster attacks" if id=="haste" else "Hover for details")
		if not blessing and NEW_NOTES.has(id):footer=NEW_NOTES[id]
		if g.run_rules>=17 and id=="frost_shatter":footer="Next heavy hit after freeze"
		if g.run_rules>=9:footer={"solvent":"Corrode armor, then expose","venom":"Poison before your first hit","shatter":"Freeze cooldown: 4s","contagion":"Next fight: +1 Poison power"}.get(id,footer)
		if g.run_rules>=7 and id=="precision":footer="Limit: %.0f%%"%(float(preload("res://build_stats.gd").calculate(g).crit_cap)*100)
		if id in ["critical_horizon","unbound_aim"]:footer="Also +3% Crit chance"
		g.draw_wrapped(footer,at+Vector2(20,179),315,16,g.INK,2)
	g.button(Rect2(960,52,260,50),"Your full build","build_open")
	if not options.is_empty():preview_index=selected;comparison.draw(options[selected],blessing)
	if not blessing:g.front_end.icon_button(Rect2(60,730,500,60),"relic","Reroll / %d"%g.rerolls_left,"relic_reroll",false,g.rerolls_left>0 and can_reroll())
func item_row(key: String,value: float,current: Dictionary,at: Vector2,width: float,font: int=21) -> void:
	var labels={"attack":"Attack","armor":"Armor","health":"Health","speed":"Speed bonus","crit_chance":"Crit chance","crit_mult":"Crit damage","fire_dps":"Fire / sec","ice_slow":"Enemy slow","acid_strip":"Armor / hit","poison_weak":"Less enemy dmg","evade":"Evade","vampirism":"Vampirism"}
	var delta=value-float(current.get(key,0.0));var number="%+.1f"%value;var change=g.format_delta(key,delta)
	if key in ["crit_chance","ice_slow","poison_weak","evade","vampirism"]:number="%+.1f%%"%(value*100)
	if key=="crit_mult":number="%+.2f×"%value
	if key=="speed":number="%+.0f%%"%(value*100);change="%+.0f%%"%(delta*100)
	if key=="crit_mult":number="%+.0f%%"%(value*100);change="%+.0f%%"%(delta*100)
	if is_zero_approx(delta):change="—"
	g.stat_ui.label(key,at,22)
	g.text(at+Vector2(27,0),g.stat_ui.short_name(key),16,g.INK)
	g.text(at+Vector2(width*0.47,0),number,font,g.GOLD)
	g.text(at+Vector2(width*0.78,0),change,mini(18,font),Color("a49da5") if is_zero_approx(delta) else (g.TEAL if delta>0 else Color("e88882")))

func inline_stat(key: String,value: float,item: Dictionary) -> String:
	if key=="speed" and g.run_rules>=7:return "Every %.2fs"%preload("res://combat_pacing.gd").preview_interval(g,item)
	if key=="crit_mult":return "Critical damage +%.0f%%"%(value*100)
	if key!="speed":return g.Gear.stat_text(key,value)
	var old=g.Gear.stats(g.inventory[g.equipped[item.slot]]).get("speed",0.0) if g.equipped.has(item.slot) else 0.0
	return timing(g.speed-old+value)

func display_stats(item: Dictionary) -> Dictionary:
	var result=g.Gear.stats(item)
	if item.slot=="weapon" and not result.has("speed"):result["speed"]=0.0
	return result

func explain(id: String,blessing: bool=false) -> String:
	if g.run_rules>=7:return paced_explain(id,blessing)
	if id=="haste":return "Attack every %.2fs → %.2fs for this run. Lower is faster."%[interval(g.speed),interval(g.speed+0.25)]
	if blessing and id=="guard":return "+3 armor. Attack every %.2fs → %.2fs. Lower is faster."%[interval(g.speed),interval(g.speed+0.15)]
	if id in ["ruin","ferocity"]:return "Critical hits deal %.0f%% → %.0f%% of normal hit damage. Max 300%%."%[g.crit_mult*100,minf(3,g.crit_mult+0.5)*100]
	var result=g.UPGRADE_INFO[id][1] if blessing else g.RELICS[id][1]
	var types=[id] if blessing and g.elements.has(id) else STACKS.get(id,[])
	var before=g.combat_build();var after=before.duplicate(true)
	for element in types:after[element]=mini(3,int(after[element])+1)
	# Element cards use the same combat formulas as the encounter forecast.
	for element in types:
		var mastery=1.0+float(after.get(element+"_mastery",0.0))
		if blessing:result=""
		match element:
			"fire":
				var old=g.Combat.fire_damage({"build":before});var new=g.Combat.fire_damage({"build":after});var duration=(5 if id=="cinder" or "cinder" in g.relics else 3)+(1 if after.get("floor_rule","")=="embers" else 0)
				result+=" Each Fire stack: %.1f damage/s. Total: %.1f → %.1f damage/s. Hits reset a %ds burn."%[4*mastery,old,new,duration]
			"ice":
				result+=" Each Ice stack: %.1f%% slower enemy attacks. Total: %.1f%% → %.1f%%. Max 65%%."%[18*mastery,g.Combat.ice_slow({"build":before})*100,g.Combat.ice_slow({"build":after})*100]
			"poison":
				result+=" Each Poison stack: %.1f%% less enemy damage. Total: %.1f%% → %.1f%%. Lasts the fight; max 65%%."%[18*mastery,g.Combat.poison_weak({"build":before})*100,g.Combat.poison_weak({"build":after})*100]
			"acid":
				var gear=float(after.get("acid_strip",0));var per_hit=((3 if id=="solvent" or "solvent" in g.relics else 2)+gear)*mastery
				result+=" Your hits remove %.1f armor each. Max armor removed per enemy: %.1f → %.1f. +%.1f max per Acid stack."%[per_hit,(4*int(before.acid)+3*gear)*mastery,(4*int(after.acid)+3*gear)*mastery,4*mastery]
	return result.strip_edges()

func ability_name(item: Dictionary) -> String:
	if item.get("plain",false):return "None (plain)"
	return {"balanced":"Sword ward","dagger":"Combo","axe":"Cleave","greatblade":"Sunder","ember":"Flare"}.get(item.get("archetype","balanced"),"None")

func weapon_description(item: Dictionary) -> String:
	if item.get("plain",false):return "Plain starter weapon. No innate weapon ability or bonus stats. Imprints and other equipment can add elemental effects."
	var base=g.Combat.Flow.WEAPONS.get(item.get("archetype","balanced"),["",""])[1]
	var n=maxi(0,int(item.level)-1)
	if int(item.get("balance",1))>=2:base="%.0f%% character hit power + item attack. Base interval %.1fs. "%[preload("res://combat_pacing.gd").power_scale(item.get("archetype","balanced"),int(item.get("balance",1)))*100,float(preload("res://combat_pacing.gd").INTERVALS.get(item.get("archetype","balanced"),2))]+base
	if item.get("heavy_form","")=="colossus":base="+60% physical hit power; −20% attack rate. "+base
	if int(item.get("balance",1))>=4:
		var tier=1+int(n/2 if int(item.get("balance",1))>=7 else n/4)
		if item.get("variant","")=="winterblade":return "15%% less item attack; +%d Frost power. "%tier+base
		if item.get("variant","")=="caustic":return "35%% less Fire potency; +%d Acid power. "%tier+base
	match item.get("variant",""):
		"bloodletter":return "No innate evade; +%.1f%% vampirism. "%(((0.035+0.0008*n) if int(item.get("balance",1))>=2 else (0.05+0.001*n))*100)+base
		"winterblade":return "15%% less base attack; +%.1f%% enemy slow. "%(((0.06+0.0008*n) if int(item.get("balance",1))>=2 else (0.08+0.001*n))*100)+base
		"caustic":return "35%% less fire damage/s; +%.2f armor removed/hit. "%((0.6+0.035*n) if int(item.get("balance",1))>=2 else (0.75+0.05*n))+base
	return base

func paced_explain(id: String,blessing: bool=false) -> String:
	if g.run_rules>=9:
		var future=preload("res://build_stats.gd").upgrade_preview(g,id,blessing)
		var text=g.relic_description(id) if not blessing else {"attack":"+3 character attack.","guard":"+2 armor and +6% base attack speed.","focus":"+6% critical chance.","ferocity":"+20% critical hit damage.","fire":"+1 Fire potency.","ice":"+1 Frost power.","acid":"+1 Acid power.","poison":"+1 Poison power."}.get(id,"")
		for element in ([id] if blessing and id in ["fire","ice","acid","poison"] else STACKS.get(id,[])):text+=" "+preload("res://element_rules.gd").describe(element,future.build,future.attack)
		return text
	var stats=preload("res://build_stats.gd");var old=stats.calculate(g);var next=stats.upgrade_preview(g,id,blessing)
	var result=g.relic_description(id) if not blessing else {"attack":"+3 character attack. Your weapon scales this hit power.","guard":"+2 armor and +6% base attack speed.","focus":"+6% critical chance, up to your current limit.","ferocity":"Critical hits gain +20% of normal damage."}.get(id,"+1 "+id.capitalize()+" stack.")
	if old.interval!=next.interval:result+=" Attack every %.2fs → %.2fs."%[old.interval,next.interval]
	if old.crit_cap!=next.crit_cap:result+=" Critical chance limit: %.0f%% → %.0f%%."%[old.crit_cap*100,next.crit_cap*100]
	if old.crit_chance!=next.crit_chance:result+=" Critical chance: %.1f%% → %.1f%%."%[old.crit_chance*100,next.crit_chance*100]
	for element in ["fire","ice","acid","poison"]:
		if old.elements[element]==next.elements[element]:continue
		match element:
			"fire":result+=" Each stack: %.1f damage/s. Total %.1f → %.1f damage/s."%[2*(1+float(next.build.fire_mastery)),old.fire,next.fire]
			"ice":result+=" Enemy slow: %.1f%% → %.1f%%. Max 65%%."%[old.ice*100,next.ice*100]
			"poison":result+=" Less enemy damage: %.1f%% → %.1f%%. Max 65%%."%[old.poison*100,next.poison*100]
			"acid":result+=" Removes %.1f armor/hit, up to %.1f per enemy."%[next.acid,next.acid_cap]
	return result

func can_reroll() -> bool:
	if g.run_rules<11:return g.relic_pool().size()-g.relics.size()>g.choices.size()
	for id in g.relic_pool():
		if id not in g.choices:return true
	return false
