extends RefCounted
## Rules 9: all counters and burn snapshots are private, saved battle data.
const KEYS={"fire":"fire_power","ice":"frost_apply","acid":"acid_apply","poison":"poison_apply"}
const OLD={"fire_dps":"fire_power","ice_slow":"frost_apply","acid_strip":"acid_apply","poison_weak":"poison_apply"}
static func enabled(s: Dictionary) -> bool:return s.build.get("elemental_v2",false)
static func element_power(build: Dictionary,element: String) -> float:
	return (float(build.get(element,0))+float(build.get(KEYS[element],0))+(float(build.get("toxic_echo",0)) if element=="poison" else 0.0))*(1.0+float(build.get(element+"_mastery",0)))
static func potency(build: Dictionary,element: String) -> float:
	return element_power(build,element)*(float(build.get("element_interval_scale",1.0)) if element!="fire" else 1.0)
static func specialized(build: Dictionary) -> bool:return bool(build.get("elemental_specialization",false))
static func normalized_hit(build: Dictionary,attack: float) -> float:
	return attack/maxf(0.01,1.0+float(build.get("impact_power",0)))/maxf(0.1,float(build.get("element_interval_scale",1.0)))
static func heat_cap(build: Dictionary) -> int:
	var rank=element_power(build,"fire")
	return 8 if rank>=8 else 4 if rank>=4 else 0
static func acid_cap(build: Dictionary) -> int:
	if not specialized(build):return 20
	var rank=element_power(build,"acid")
	return 80 if rank>=8 else 40 if rank>=4 else 20
static func burn_power(build: Dictionary,power: float) -> float:return power*0.10*potency(build,"fire")/maxf(0.01,1.0+float(build.get("impact_power",0.0)))
static func burn_damage(s: Dictionary) -> float:
	var best=0.0
	if not s.has("burns"):return burn_power(s.build,float(s.get("attack",s.build.get("preview_attack",0))))
	for burn in s.burns:
		if float(burn.until)+0.00001>=float(s.time):best=maxf(best,float(burn.power))
	return best*(1.0+0.10*float(s.get("fire_heat",0))) if specialized(s.build) else best
static func slow(s: Dictionary) -> float:return minf(0.50,float(s.get("frost_counters",0))*(0.025 if specialized(s.build) else 0.05))
static func rate(s: Dictionary) -> float:return float(s.enemy.speed)*(1.25 if s.rage else 1.0)*(1.0-slow(s))
static func exposure(s: Dictionary) -> float:return minf(acid_cap(s.build)*0.01,maxf(0,float(s.acid_stacks)-float(s.enemy.armor))*0.01)
static func prepare(s: Dictionary) -> void:
	s["burns"]=[];s["poison_counters"]=0.0;s["poison_time"]=INF;s["frost_counters"]=0.0;s["freeze_ready"]=0.0;s["frozen_until"]=0.0;s["frost_shatter_ready"]=false;s["fire_heat"]=0;s["poison_next_burst"]=10.0
	if "venom" in s.relics:
		s.poison_counters=2*potency(s.build,"poison");s.poison_time=0.5 if s.poison_counters>0 else INF;s.poisoned=s.poison_counters>0
static func add_frost(s: Dictionary,amount: float,result: Dictionary) -> void:
	if amount<=0:return
	var threshold=20.0 if specialized(s.build) else 10.0
	var old=rate(s);s.frost_counters=minf(threshold,s.frost_counters+amount);s.iced=true
	s.e_time=s.time+maxf(0,s.e_time-s.time)*old/rate(s)
	if s.frost_counters>=threshold and s.time>=s.freeze_ready:
		s.frost_counters=threshold/2.0;s["frozen_until"]=s.time+1.0;
		if specialized(s.build) and "frost_shatter" in s.relics:s["frost_shatter_ready"]=true
		s.freeze_ready=s.time+(4.0 if "shatter" in s.relics else 8.0)
		var previous=float(s.enemy.speed)*(1.25 if s.rage else 1.0)*0.5
		s.e_time=s.time+maxf(0,s.e_time-s.time)*previous/rate(s)+1.0
		if s.enemy.get("signature","")=="abbot" and s.regen_time!=INF:s.regen_time+=1.0
		s.disrupted=true;result["interrupt"]=true;result["effect"]="FREEZE"
		if specialized(s.build) and element_power(s.build,"ice")>=4:
			var frost_power=element_power(s.build,"ice")
			var base_hit=normalized_hit(s.build,float(s.get("attack",0)))
			var burst=base_hit*minf(10.0,1.0*(frost_power-2.0))
			var dealt=minf(float(s.enemy.hp),burst);s.enemy.hp-=burst
			result["damage"]=float(result.get("damage",0))+dealt;result["actual_damage"]=float(result.get("actual_damage",0))+dealt
			result["element_damage"]=float(result.get("element_damage",0))+dealt;result["combo_element"]="frost"
static func spend_frost(s: Dictionary,amount: float) -> void:
	var old=rate(s)
	s.frost_counters=maxf(0.0,float(s.frost_counters)-amount)
	s.iced=s.frost_counters>0.0
	s.e_time=s.time+maxf(0.0,s.e_time-s.time)*old/rate(s)
static func end_freeze(s: Dictionary) -> void:
	var remaining=maxf(0.0,float(s.get("frozen_until",0.0))-float(s.time))
	s.e_time=maxf(float(s.time),float(s.e_time)-remaining)
	s["frozen_until"]=0.0;s.disrupted=false
	spend_frost(s,10.0)
static func on_hit(s: Dictionary,power: float,result: Dictionary) -> void:
	var fire=burn_power(s.build,power)
	if specialized(s.build) and fire>0 and heat_cap(s.build)>0:
		if s.fire_time==INF or s.time>s.fire_until:s.fire_heat=0
		else:
			var gain=2 if s.build.get("weapon_archetype",s.build.get("weapon","")) in ["axe","greatblade"] else 1
			s.fire_heat=mini(heat_cap(s.build),int(s.get("fire_heat",0))+gain)
	if fire>0:
		var until=s.time+(5.0 if "cinder" in s.relics else 3.0)+(1.0 if s.build.get("floor_rule","")=="embers" else 0.0)
		var active=[];var matched=false
		for burn in s.burns:
			if burn.until<s.time:continue
			if is_equal_approx(float(burn.power),fire):burn.until=until;matched=true
			active.append(burn)
		if not matched:active.append({"power":fire,"until":until})
		s.burns=active;s.fire_until=maxf(s.fire_until,until)
		if s.fire_time==INF:s.fire_time=s.time+1.0
	add_frost(s,potency(s.build,"ice"),result)
	if s.enemy.hp<=0:return
	var poison=potency(s.build,"poison")
	if poison>0:
		s.poison_counters+=poison;s.poisoned=true
		if s.poison_time==INF:s.poison_time=s.time+0.5
		if specialized(s.build) and element_power(s.build,"poison")>=4.0 and s.poison_counters>=float(s.get("poison_next_burst",10.0)):
			var crossed=1+floori((s.poison_counters-float(s.get("poison_next_burst",10.0)))/10.0)
			var burst=element_power(s.build,"poison")*2.0*crossed*(2.0 if "toxic_harvest" in s.relics else 1.0)
			var applied=minf(float(s.enemy.hp),burst);s.enemy.hp-=burst
			result["damage"]=float(result.get("damage",0))+applied;result["actual_damage"]=float(result.get("actual_damage",0))+applied
			result["element_damage"]=float(result.get("element_damage",0))+applied;result["effect"]="POISON BURST";result["combo_element"]="poison"
			s.poison_next_burst=(floorf(s.poison_counters/10.0)+1.0)*10.0
	if s.enemy.hp<=0:return
	var acid=potency(s.build,"acid")
	if acid>0:
		var armor_before=maxf(0.0,float(s.enemy.armor)-float(s.acid_stacks))
		s.acid_stacks=minf(float(s.initial_armor)+acid_cap(s.build),s.acid_stacks+acid)
		if specialized(s.build) and element_power(s.build,"acid")>=4 and armor_before>0 and float(s.enemy.armor)-s.acid_stacks<=0:
			var base_hit=normalized_hit(s.build,float(s.get("attack",0)))
			var burst=base_hit*minf(15.0,1.5*element_power(s.build,"acid"))
			var dealt=minf(float(s.enemy.hp),burst);s.enemy.hp-=burst
			result["damage"]=float(result.get("damage",0))+dealt;result["actual_damage"]=float(result.get("actual_damage",0))+dealt
			result["element_damage"]=float(result.get("element_damage",0))+dealt;result["effect"]="ACID BREAK";result["combo_element"]="caustic"
static func describe(element: String,build: Dictionary,power: float=0) -> String:
	var n=potency(build,element)
	if specialized(build):
		var raw=element_power(build,element)
		match element:
			"fire":return "Fire %.1f: burn %.1f/s for %.0fs; ignores armor. At 4 power: repeated hits build Heat, +10%% burn each (max 4). At 8 power: max 8. Heavy hits add 2 Heat."%[n,burn_power(build,power),float(build.get("burn_duration",3))]
			"ice":
				var bonus="Freeze: %.1f Frost damage."%(normalized_hit(build,power)*minf(10.0,maxf(0.0,raw-2.0))) if raw>=4 else "At 4 power: freezes deal Frost damage."
				return "Frost %.1f power / +%.1f per hit. 2.5%% slow per counter (max 50%%). At 20: freeze 1s, return to 10. Cooldown: %.0fs. %s"%[raw,n,float(build.get("freeze_cooldown",8)),bonus]
			"poison":return "Poison %.1f power / +%.1f per hit. Each counter deals 0.25 damage every 0.5s and ignores armor. At 4 power: hits trigger a burst at every 10 counters for twice your Poison power."%[raw,n]
			"acid":
				var bonus="Armor break: %.1f Acid damage."%(normalized_hit(build,power)*minf(15.0,1.5*raw)) if raw>=4 else "At 4 power: armor breaks deal Acid damage."
				return "Acid %.1f power / +%.1f per hit. Each counter removes 1 armor; extra counters add 1%% physical damage (max %d%%). At 4 power: max 40%%; at 8: max 80%%. %s"%[raw,n,acid_cap(build),bonus]

	match element:
		"fire":return "Fire %.1f: a normal hit burns for %.1f damage/s for %.0fs. Each Fire adds 10%% of hit power before physical-only bonuses. Only the strongest burn deals damage; it ignores armor."%[n,burn_power(build,power),float(build.get("burn_duration",3))]
		"ice":return "Frost +%.1f per hit. Each stack slows attacks by 5%% (max 50%%). At 10 stacks: freeze for 1s, then return to 5 stacks. Freeze cooldown: %.0fs."%[n,float(build.get("freeze_cooldown",8))]
		"poison":return "Poison +%.1f per hit. Each stack deals 0.5 damage every 0.5s. Example: 3 stacks deal 1.5 damage every 0.5s. Stacks last the fight and ignore armor."%n
		"acid":return "Acid +%.1f per hit. Each stack removes 1 armor. After armor reaches 0, each extra stack adds 1%% weapon damage (max 20%%). Stacks last the fight."%n
	return ""
static func brief(element: String,modern: bool=false) -> String:
	if modern:return {"fire":"Burns; 4 Fire power builds Heat.","ice":"2.5% slow / counter. 20: freeze; 4 power: damage.","poison":"0.25 damage / counter every 0.5s. 4 power: bursts.","acid":"−1 armor / counter. Extra: +1% damage."}.get(element,"")
	return {"fire":"Burns over time. Strongest burn counts.","ice":"5% slower / stack. 10 stacks: freeze 1s.","poison":"0.5 damage / stack every 0.5s.","acid":"−1 armor / stack. Extra: +1% damage."}.get(element,"")
