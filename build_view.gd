extends RefCounted
const Stats=preload("res://build_stats.gd")
var g
var selected=""
var page=0
var equipment_details=false
var item_compare_page=0
var item_compare_stamp=0
var compare_has_pages=false
var compare_page=0
var compare_key=0
var view="stats"
var selected_skill=""
var skill_page=0
const META={"armor_reduction":["Physical reduction","armor"],"weapon_dps":["Weapon DPS","attack"],"attack":["Attack","attack"],"armor":["Armor","armor"],"max_hp":["Max HP","health"],"interval":["Attack every","speed"],"crit_chance":["Critical chance","crit"],"crit_mult":["Critical hit damage","crit"],"crit_cap":["Critical chance limit","crit"],"fire":["Fire damage/s","fire"],"ice":["Enemy attack slow","ice"],"poison":["Less enemy damage","poison"],"acid":["Armor removed/hit","acid"],"evade":["Evade chance","boots"],"vampirism":["Vampirism","health"],"victory_heal":["HP after victory","health"],"third_heal":["HP every 3 attacks","health"],"armor_pierce":["Armor ignored","attack"],"opening_damage":["First hit bonus","attack"],"first_hit_reduction":["First hit protection","armor"]}
func _init(game):g=game
func meta(key: String) -> Array:
	if g.run_rules>=9:
		if key=="fire":return ["Burn damage/s","fire"]
		if key=="ice":return ["Frost / hit","ice"]
		if key=="poison":return ["Poison / hit","poison"]
		if key=="acid":return ["Acid / hit","acid"]
	return META[key]
func active(current: Dictionary,future: Dictionary={}) -> Array:
	var keys=[]
	for key in ["vampirism","fire","ice","acid","poison","evade","crit_chance","crit_mult","victory_heal","third_heal","armor_pierce","opening_damage","first_hit_reduction"]:
		if float(current.get(key,0))>0 or float(future.get(key,0))>0:keys.append(key)
	if float(current.get("crit_cap",0.6))>0.6001 or float(future.get("crit_cap",0.6))>0.6001:keys.append("crit_cap")
	return keys
func value(key: String,s: Dictionary) -> String:
	if key in ["fire","weapon_dps"]:return "%.1f/s"%float(s[key])
	if g.run_rules>=9 and key in ["ice","acid","poison"]:return "%.1f/hit"%float(s[key])
	if key=="current_hp":return str(int(s.current_hp))
	if key=="interval":return "%.2fs"%s.interval

	if key in (["armor_reduction","ice","poison","evade","vampirism","armor_pierce","opening_damage","first_hit_reduction","crit_chance","crit_mult","crit_cap"] if g.run_rules<9 else ["armor_reduction","evade","vampirism","armor_pierce","opening_damage","first_hit_reduction","crit_chance","crit_mult","crit_cap"]):return "%.1f%%"%(float(s[key])*100)
	return "%.1f"%float(s[key])
func handle(id: String) -> bool:
	if id=="build_open":g.run_metrics["build_return"]=g.mode;g.mode="build";page=0;selected="";view="stats";selected_skill="";skill_page=0;return true
	if id=="build_close":g.mode=g.run_metrics.get("build_return","equipment");return true
	if id=="build_skills":view="skills";return true
	if id=="build_stats":view="stats";return true
	if id=="build_skill_next":skill_page+=1;return true
	if id=="build_skill_prev":skill_page=maxi(0,skill_page-1);return true
	if id.begins_with("build_skill:"):selected_skill=id.get_slice(":",1);return true
	if id=="build_next":page+=1;return true
	if id=="build_prev":page=maxi(0,page-1);return true
	if id=="item_stats_next":item_compare_page+=1;return true
	if id=="item_stats_prev":item_compare_page=maxi(0,item_compare_page-1);return true
	if id=="compare_next":compare_page+=1;return true
	if id=="compare_prev":compare_page=maxi(0,compare_page-1);return true
	if id=="compare_details":equipment_details=not equipment_details;return true
	if id.begins_with("build_stat:"):selected=id.get_slice(":",1);return true
	return false
func draw_compare(index: int,overrides: Dictionary={},origin: Vector2=Vector2(812,300),width: float=380,height: float=218,health_cost: int=0) -> void:
	var current=Stats.calculate(g);var future=Stats.prospective(g,index,overrides)
	if health_cost>0:
		current["current_hp"]=g.hp;future.max_hp=maxi(20,future.max_hp-health_cost);future["current_hp"]=mini(g.hp-health_cost,future.max_hp)
	var item=overrides.get(index,g.inventory[index]);var previous={}
	if g.equipped.has(item.slot):previous=g.inventory[g.equipped[item.slot]]
	var presenter=preload("res://equipment_presenter.gd")
	var keys=presenter.affected(previous,item)
	if health_cost>0:
		keys.erase("attack");keys.push_front("attack");keys.erase("max_hp");keys.push_front("max_hp");keys.push_front("current_hp")
	# Relevant unchanged values stay beside changed values, including equal armor.
	for key in ["attack","armor","max_hp","interval"]+active(current,future):
		if key not in keys and not is_equal_approx(float(current[key]),float(future[key])):keys.append(key)
	var stamp=hash([g.mode,index,item,g.equipped,g.inventory])
	if stamp!=compare_key:compare_key=stamp;compare_page=0
	var per_page=maxi(1,int(height/28));var pages=maxi(1,ceili(float(keys.size())/per_page))
	compare_has_pages=pages>1
	compare_page=clampi(compare_page,0,pages-1)
	var visible=mini(keys.size()-compare_page*per_page,per_page)
	for i in range(visible):
		var key=keys[compare_page*per_page+i];var at=origin+Vector2(0,i*28)
		var delta=float(future[key])-float(current[key])
		var better=delta<0 if key=="interval" else delta>0
		g.stat_ui.label(key,at,24)
		g.text(at+Vector2(30,0),g.stat_ui.short_name(key),18,g.INK)
		g.text(at+Vector2(width*0.51,0),value(key,current),18,g.INK)
		g.text(at+Vector2(width*0.77,0),value(key,future),22,g.INK if is_zero_approx(delta) else g.TEAL if better else Color("e88882"))
	if pages>1:
		g.button(Rect2(origin+Vector2(0,height-8),Vector2(55,30)),"<","compare_prev",false,compare_page>0)
		g.text(origin+Vector2(80,height+14),"Stats %d / %d"%[compare_page+1,pages],18)
		g.button(Rect2(origin+Vector2(width-55,height-8),Vector2(55,30)),">","compare_next",false,compare_page<pages-1)
func details(key: String,s: Dictionary) -> String:
	if key=="armor_reduction":return "Armor blocks %.1f%% of physical hit power before rounding. Reduction = armor / (12 + armor). No hard cap. "%(s.armor_reduction*100)+( "Incoming hits round up to at least 1; your attacks retain fractional damage. " if g.run_rules>=9 else "Physical hits round up to at least 1. ")+"Shields apply separately. Fire ignores armor."
	if key=="weapon_dps":return "Attack × attacks/s, before criticals, enemy armor and weapon abilities. Includes character power and all equipped attack bonuses. Fire damage is separate."
	var gear_key={"fire":"fire_power","ice":"frost_apply","acid":"acid_apply","poison":"poison_apply","max_hp":"health","interval":"speed"}.get(key,key) if g.run_rules>=9 else {"fire":"fire_dps","ice":"ice_slow","acid":"acid_strip","poison":"poison_weak","max_hp":"health","interval":"speed"}.get(key,key)
	if g.run_rules>=9 and key in ["fire","ice","acid","poison"]:
		var names=[]
		for source in s.sources.get(gear_key,[]):names.append("%s: +%.1f."%[source.name,source.value])
		return preload("res://element_rules.gd").describe(key,s.build,s.attack)+" Upgrades: +%d. Mastery: +%.0f%%. "%[s.elements[key],float(s.build.get(key+"_mastery",0))*100]+" ".join(names)
	var parts=[]
	var contributions=s.sources.get(gear_key,[]).duplicate()
	for source in contributions:parts.append("%s (%s): %+.1f%s"%[source.name,source.slot,float(source.value)*100 if key in ["armor_reduction","ice","poison","evade","vampirism","crit_chance","crit_mult"] else float(source.value),"%" if key in ["armor_reduction","ice","poison","evade","vampirism","crit_chance","crit_mult"] else ""])
	if g.run_rules>=7:
		if key=="attack":return ("Colossus: +60% to your whole physical hit, not Fire. " if float(s.gear.get("impact_power",0))>0 else "")+" ".join(parts)+" Character attack × %.0f%% weapon power, plus item attack. Base: %.0f. Levels: +%.2f. Upgrades: +%.1f. Might: +%.2f. Daggers use 50%% character power; axes use 150%% in new runs."%[s.power_scale*100,5.0 if g.run_rules>=8 else 9.0,(minf(g.character_level-1,3.0)+maxf(0,g.character_level-4)*0.45 if g.run_rules>=18 else (g.character_level-1)*(1.0 if g.run_rules>=15 else 0.35)),g.bonus.attack,(0.7 if g.run_rules>=11 else 0.35)*g.ember_tree.rank("might")]
		if key=="interval":return ("Colossus: −20% final attack rate. " if float(s.gear.get("impact_rate",0))<0 else "")+" ".join(parts)+" Speed bonuses multiply weapon cadence. Sword/unarmed: 2s. Dagger: 1s. Axe: 3s. Lower is faster. Quick hands removes 0.15s; Heavy momentum slows heavy weapons." if g.run_rules>=18 else " Speed bonuses multiply weapon cadence. Sword/unarmed: 2s. Dagger: 1s. Axe: 3s. Lower is faster. Tempo adds 1% speed per rank in new runs."
		if key in ["crit_chance","crit_cap"]:return " ".join(parts)+" Total chance: %.1f%%; limit: %.0f%%. Keen edge: +%.1f%%. Precision: +%.1f%%. Hawk eye adds 8%%. Critical horizon and Unbound aim each add 15%% to the limit and 3%% chance, up to 90%%. Early gear has smaller chance bonuses."%[s.crit_chance*100,s.crit_cap*100,g.bonus.crit_chance*100,(1.0 if g.run_rules>=11 else 0.3)*g.ember_tree.rank("precision_training")]
		if key=="crit_mult":return " ".join(parts)+" Criticals deal %.0f%% of normal damage. Base: 150%%. Ruin prism adds 25%%; Ruin training adds %.1f%% per rank. Cap: 300%%."%[s.crit_mult*100,3.0 if g.run_rules>=11 else 1.5]
		if key=="armor":return " ".join(parts)+" Base: %d. Levels: +%.2f. Run upgrades: +%.1f. Fortitude: +%.2f. Physical reduction: %.1f%% before rounding. Reduction = armor / (12 + armor). No hard cap. Incoming hits round up to at least 1. Fire ignores armor; piercing bypasses some armor."%[0 if g.run_rules>=8 else 1,(minf(g.character_level-1,3.0)*0.35+maxf(0,g.character_level-4)*0.15 if g.run_rules>=18 else (g.character_level-1)*(0.35 if g.run_rules>=15 else 0.15)),g.bonus.armor,(0.6 if g.run_rules>=11 else 0.30)*g.ember_tree.rank("armor_training"),s.armor_reduction*100]
	match key:
		"vampirism":
			parts.append("Total is capped at 35%. Heals from actual weapon damage, not burns or overkill.")
			if "leech" in g.relics:parts.append("Blood thread is separate: 2 HP every 3 attacks. It does not add vampirism.")
		"evade":parts.append("Total is capped at 50%. A dodge prevents the whole incoming hit.")
		"fire":
			parts.append("Stacks: %d × %.1f damage/s. Fire mastery: +%.0f%%. Base burn damage includes gear and mastery. Hits refresh the burn."%[s.elements.fire,float(s.build.get("fire_stack_damage",4.0)),float(s.build.fire_mastery)*100])
			if "cinder" in g.relics:parts.append("Cinder crown adds 50% damage every 3rd burn tick.")
			if "wildfire" in g.relics:parts.append(g.RELICS.wildfire[1])
		"ice":parts.append("Stacks: %d × 18%% slow. Ice mastery: +%.0f%% effect strength. Total cap: 65%%."%[s.elements.ice,float(s.build.ice_mastery)*100])
		"poison":
			parts.append("Stacks: %d × 18%% less enemy attack damage. Poison mastery: +%.0f%% effect strength. Total cap: 65%%."%[s.elements.poison,float(s.build.poison_mastery)*100])
			if g.toxic_echo>0:parts.append("Next fight only: Contagion adds another 10% reduction, within the same cap.")
		"acid":parts.append("Acid stacks: %d. Mastery: +%.0f%%. Up to %.1f armor can be removed from one enemy. Removal helps following hits."%[s.elements.acid,float(s.build.acid_mastery)*100,s.acid_cap])
		"crit_chance":parts.append("Base: %.0f%%. Keen edge: +%.0f%%. Hawk eye: +%.0f%%. Precision: +%.1f%%. Chance cap: 60%%."%[10 if g.run_rules<3 else 5,g.bonus.crit_chance*100,20 if "precision" in g.relics else 0,0.5*g.ember_tree.rank("precision_training") if g.run_rules>=5 else 0])
		"crit_mult":
			parts.append("150%% means a critical hit deals 1.5 times normal damage. Base: 150%%. Ruin edge: +%.0f%%. Ruin prism: +%.0f%%. Ruin training: +%.0f%%. Total cap: 300%%."%[g.bonus.crit_mult*100,50 if "ruin" in g.relics else 0,2*g.ember_tree.rank("ruin_training") if g.run_rules>=5 else 0])
			if "steamglass" in g.relics:parts.append("Steamglass adds 30% of normal hit damage to critical hits against burning, slowed enemies.")
		"armor_pierce":parts.append("Glass needle ignores 60% of the enemy armor remaining after acid. It does not add direct damage.")
		"opening_damage":parts.append("First spark adds 75% hit power on your opening attack. This bonus applies once per fight.")
		"first_hit_reduction":parts.append("Ash ward reduces the first enemy hit by 50%. Later hits deal normal damage.")
		"attack":parts.append("Base: %.1f. Levels: +%.1f. Level-up bonuses: +%.1f. Might: +%.1f. Enemy armor changes actual damage."%[10.0+g.legacy_levels[1]*0.5 if g.run_rules<3 else 9.0,(g.character_level-1)*0.75,g.bonus.attack,0.5*g.ember_tree.rank("might") if g.run_rules>=5 else 0.0])
		"armor":parts.append("Base: %.1f. Levels: +%.1f. Level-up bonuses: +%.1f. Fortitude: +%.1f. Enemy piercing can bypass armor."%[2.0+g.legacy_levels[2]*0.5 if g.run_rules<3 else 1.0,(g.character_level-1)*0.25,g.bonus.armor,0.4*g.ember_tree.rank("armor_training") if g.run_rules>=5 else 0.0])
		"max_hp":
			parts.append("Each level adds 8 max HP and restores up to 8 HP." if g.run_rules>=15 else "Each level adds 6 max HP and restores up to 6 HP." if g.run_rules>=13 else "Each level adds 3 max HP." if g.run_rules>=7 else "Levels increase your max HP.")
			parts.append("Equipment and Ember Tree upgrades also add max HP. Equipping health does not heal you.")
		"interval":parts.append("Gear speed bonuses above are attacks/s. Includes upgrades, Clockwork heart and Tempo. Interval is 1 divided by total speed. Lower seconds means faster attacks.")
		"victory_heal":parts.append("Grave bloom: 4 HP. Renewal: 1 HP per rank. Heals after each victory, up to max HP.")
		"third_heal":parts.append("Blood thread heals 2 HP every 3 attacks. This is a flat heal, not vampirism.")
	return " ".join(parts)
func draw() -> void:
	g.front_end.menu_backdrop();g.text(Vector2(75,82),"YOUR BUILD",36,g.GOLD);g.close_button(Rect2(1157,48,48,48),"build_close")
	g.button(Rect2(605,48,180,48),"Stats","build_stats",view=="stats")
	g.button(Rect2(800,48,190,48),"Skills / %d"%g.relics.size(),"build_skills",view=="skills")
	var s=Stats.calculate(g);var core=["attack","armor","max_hp","interval"]
	for i in range(4):
		var key=core[i];var at=Vector2(75+i*285,125);g.button(Rect2(at,Vector2(260,110)),"","build_stat:"+key)
		g.stat_ui.icon(key,at+Vector2(15,15),32)
		g.text(at+Vector2(55,39),g.stat_ui.short_name(key),20,g.INK)
		g.text(at+Vector2(22,88),value(key,s),34,g.GOLD)
	g.panel(Rect2(75,265,730,440));g.panel(Rect2(825,265,380,440))
	if view=="skills":draw_skills();return
	var keys=active(s);page=clampi(page,0,maxi(0,ceili(keys.size()/8.0)-1))
	for row in range(8):
		var i=page*8+row
		if i>=keys.size():break
		var key=keys[i];var at=Vector2(95+(row%2)*350,285+(row/2)*100)
		g.button(Rect2(at,Vector2(330,88)),"","build_stat:"+key,selected==key);g.stat_ui.icon(key,at+Vector2(12,12),28)
		g.text(at+Vector2(50,34),g.stat_ui.short_name(key),20,g.INK)
		g.text(at+Vector2(52,68),value(key,s),27,g.GOLD)
	if selected!="":
		g.text(Vector2(850,310),meta(selected)[0],23,g.GOLD);g.text(Vector2(850,351),value(selected,s),30,g.TEAL)
		g.draw_wrapped(details(selected,s),Vector2(850,398),325,18,g.INK,12)
	else:
		g.draw_wrapped("Only active effects are shown. Select a number for its sources and rules.",Vector2(850,310),325,22,g.INK,4)
		var index=int(g.equipped.get("weapon",-1))
		if index>=0:
			g.text(Vector2(850,460),g.inventory[index].name,24,g.GOLD)
			g.draw_wrapped(g.choice_ui.weapon_description(g.inventory[index]),Vector2(850,500),325,19,g.INK,7)
	g.button(Rect2(75,730,180,50),"Previous","build_prev",false,page>0);g.button(Rect2(625,730,180,50),"Next","build_next",false,(page+1)*8<keys.size())

func draw_skills() -> void:
	var owned=g.relics.filter(func(id):return g.RELICS.has(id))
	skill_page=clampi(skill_page,0,maxi(0,ceili(owned.size()/8.0)-1))
	if owned.is_empty():g.draw_wrapped("No skills yet. Defeat enemies to level up and choose a skill.",Vector2(100,310),650,22,g.INK,3)
	for row in range(8):
		var i=skill_page*8+row
		if i>=owned.size():break
		var id=str(owned[i]);var at=Vector2(95+(row%2)*350,285+(row/2)*100)
		g.button(Rect2(at,Vector2(330,88)),"","build_skill:"+id,selected_skill==id)
		g.ui_icon(g.replay.relic_icon(id),at+Vector2(13,15),34)
		g.text(at+Vector2(55,39),g.RELICS[id][0],21,g.GOLD)
		var rarity=preload("res://skill_offers.gd").rarity(id)
		g.text(at+Vector2(55,67),rarity.to_upper(),17,Color("cb90e8") if rarity=="Epic" else Color("80bce2") if rarity=="Rare" else g.INK)
	if selected_skill!="" and selected_skill in owned:
		g.ui_icon(g.replay.relic_icon(selected_skill),Vector2(850,289),32)
		g.text(Vector2(892,315),g.RELICS[selected_skill][0],23,g.GOLD)
		g.draw_wrapped(g.relic_description(selected_skill),Vector2(850,360),325,20,g.INK,11)
	else:g.draw_wrapped("Select a skill to see what it does.",Vector2(850,310),325,22,g.INK,4)
	g.button(Rect2(75,730,180,50),"Previous","build_skill_prev",false,skill_page>0)
	g.button(Rect2(625,730,180,50),"Next","build_skill_next",false,(skill_page+1)*8<owned.size())
