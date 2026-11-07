extends RefCounted
## One pure calculation powers actual stats, build totals and prospective gear changes.
static func calculate(g,equipment: Variant=null,overrides: Dictionary={},upgrade: Dictionary={}) -> Dictionary:
	var limit=2147483647 if g.run_rules>=9 else 3
	var bonus=g.bonus.duplicate();var relics=g.relics.duplicate();var base=g.base_elements.duplicate()
	var gains=preload("res://combat_pacing.gd").gains(g)
	var choice_id=str(upgrade.get("id",""))
	if upgrade.get("blessing",false):
		if choice_id in base:base[choice_id]=mini(limit,base[choice_id]+1)
		elif choice_id=="attack":bonus.attack+=gains.attack
		elif choice_id=="guard":bonus.armor+=gains.guard;bonus.speed+=gains.tempo
		elif choice_id=="focus":bonus.crit_chance+=gains.focus
		elif choice_id=="ferocity":bonus.crit_mult+=gains.ferocity
	elif choice_id!="" and choice_id not in relics:relics.append(choice_id)
	var equipped: Dictionary=g.equipped if equipment==null else equipment
	var gear={};var sources={}
	for slot in g.Gear.SLOTS:
		var index=int(equipped.get(slot,-1))
		if index<0 or index>=g.inventory.size():continue
		var item=overrides.get(index,g.inventory[index]);var values=g.Gear.stats(item)
		for key in values:
			gear[key]=float(gear.get(key,0))+float(values[key])
			if not sources.has(key):sources[key]=[]
			sources[key].append({"name":item.name,"slot":slot,"value":values[key]})
	var elements=base.duplicate(true)
	var single={"cinder":"fire","frost":"ice","solvent":"acid","venom":"poison","wildfire":"fire","shatter":"ice","bulwark":"acid","contagion":"poison"}
	for id in single:
		if id in relics:elements[single[id]]=mini(limit,int(elements[single[id]])+1)
	var dual={"steamglass":["fire","ice"],"corrosive_flame":["fire","acid"],"black_ice":["ice","poison"],"toxic_spark":["poison","fire"]}
	for id in dual:
		if id in relics:
			for element in dual[id]:elements[element]=mini(limit,int(elements[element])+1)
	var modern=g.run_rules>=5
	var hp=maxi(20,(65+int(g.legacy_levels[0])*3 if g.run_rules<3 else 48+g.ember_tree.health_bonus())+(g.character_level-1)*5+roundi(gear.get("health",0))-g.vitality_tax)
	var attack=(10.0+g.legacy_levels[1]*0.5 if g.run_rules<3 else 9.0)+(g.character_level-1)*0.75+bonus.attack+gear.get("attack",0)+(0.5*g.ember_tree.rank("might") if modern else 0)
	var armor=(2.0+g.legacy_levels[2]*0.5 if g.run_rules<3 else 1.0)+(g.character_level-1)*0.25+bonus.armor+gear.get("armor",0)+(0.4*g.ember_tree.rank("armor_training") if modern else 0)
	var speed=1.0+bonus.speed+gear.get("speed",0)+(0.25 if "haste" in relics else 0)+(0.01*g.ember_tree.rank("tempo") if modern else 0)
	var chance=minf(0.6,(0.10 if g.run_rules<3 else 0.05)+bonus.crit_chance+gear.get("crit_chance",0)+(0.2 if "precision" in relics else 0))
	var crit=minf(3,1.5+bonus.crit_mult+gear.get("crit_mult",0)+(0.5 if "ruin" in relics else 0))
	if modern:chance=minf(0.6,chance+0.005*g.ember_tree.rank("precision_training"));crit=minf(3,crit+0.02*g.ember_tree.rank("ruin_training"))
	var paced={}
	if g.run_rules>=7:
		var weapon_index=int(equipped.get("weapon",-1));var weapon="unarmed"
		if weapon_index>=0 and weapon_index<g.inventory.size():weapon=overrides.get(weapon_index,g.inventory[weapon_index]).get("archetype","balanced")
		paced=preload("res://combat_pacing.gd").player_for_weapon(g,gear,bonus,relics,weapon)
		hp=paced.max_hp;attack=paced.attack;armor=paced.armor;speed=paced.speed;chance=paced.crit_chance;crit=paced.crit_mult
	var build=elements.duplicate()
	build["elemental_specialization"]=g.run_rules>=17
	build["commitment_rules"]=g.run_rules>=18
	build["impact_power"]=float(gear.get("impact_power",0))
	if g.run_rules>=18 and "heavy_momentum" in relics and paced.get("weapon","") in ["axe","greatblade"]:build.impact_power=(1.0+float(build.impact_power))*1.45-1.0
	for element in ["fire","ice","acid","poison"]:build[element+"_mastery"]=0.05*g.ember_tree.rank(element+"_mastery") if modern else 0.0
	for key in ["fire_dps","ice_slow","acid_strip","poison_weak","fire_power","frost_apply","acid_apply","poison_apply"]:build[key]=gear.get(key,0.0)
	build["toxic_echo"]=g.toxic_echo if g.run_rules>=9 else 0.0
	if g.run_rules>=9:build["element_interval_scale"]=float(preload("res://combat_pacing.gd").INTERVALS.get(paced.get("weapon","unarmed"),2.0))/2.0;build["elemental_v2"]=true;build["preview_attack"]=attack;build["burn_duration"]=(5.0 if "cinder" in relics else 3.0)+(1.0 if g.tactics and g.tactics.rule()=="embers" else 0.0);build["freeze_cooldown"]=4.0 if "shatter" in relics else 8.0
	if g.run_rules>=7:build["fire_stack_damage"]=2.0
	var acid_boost=1.0+float(build.acid_mastery)
	var acid=(float(gear.get("acid_strip",0))+(3.0 if "solvent" in relics else 2.0 if elements.acid>0 else 0.0))*acid_boost
	var result={"max_hp":hp,"attack":attack,"armor":armor,"speed":speed,"interval":1.0/maxf(0.1,speed),"crit_chance":chance,"crit_mult":crit,"gear":gear,"sources":sources,"elements":elements,"build":build,"fire":g.Combat.fire_damage({"build":build}),"ice":g.Combat.ice_slow({"build":build}),"poison":g.Combat.poison_weak({"build":build}),"acid":acid,"acid_cap":(float(elements.acid)*4+float(gear.get("acid_strip",0))*3)*acid_boost,"evade":clampf(gear.get("evade",0),0,0.5),"vampirism":clampf(gear.get("vampirism",0),0,0.35),"victory_heal":(4 if "bloom" in relics else 0)+(g.ember_tree.rank("recovery") if modern else 0),"third_heal":2 if "leech" in relics else 0}
	if g.run_rules>=9:
		var rules=preload("res://element_rules.gd")
		result["element_totals"]={}
		for element in ["fire","ice","acid","poison"]:result.element_totals[element]=rules.potency(build,element)
		result.fire=rules.burn_power(build,attack);result.ice=result.element_totals.ice;result.poison=result.element_totals.poison;result.acid=result.element_totals.acid;result.acid_cap=0
	result["armor_pierce"]=0.6 if "needle" in relics else 0.0
	result["opening_damage"]=0.75 if "spark" in relics else 0.0
	result["first_hit_reduction"]=0.5 if "ward" in relics else 0.0
	result["crit_cap"]=paced.get("crit_cap",0.6);result["crit_raw"]=paced.get("crit_raw",chance);result["power_scale"]=paced.get("power_scale",1.0)
	result["armor_reduction"]=g.Combat.armor_reduction(float(result.armor))
	result["weapon_dps"]=float(result.attack)*float(result.speed)
	return result
static func prospective(g,index: int,overrides: Dictionary={}) -> Dictionary:
	var map=g.equipped.duplicate()
	if index>=0 and index<g.inventory.size():map[g.inventory[index].slot]=index
	return calculate(g,map,overrides)

static func upgrade_preview(g,id: String,blessing: bool=false) -> Dictionary:
	return calculate(g,null,{}, {"id":id,"blessing":blessing})
