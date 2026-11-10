extends RefCounted
const Elements=preload("res://element_rules.gd")
const Flow=preload("res://flow_combat.gd")
## Events share a simulation clock. Forecasts clone state, including fixed encounter crit rolls.
static func armor_multiplier(defense: float) -> float:
	return 12.0 / (12.0 + maxf(0.0, defense))

static func armor_reduction(defense: float) -> float:
	return 1.0-armor_multiplier(defense)

static func damage(power: float, defense: float) -> int:
	return maxi(1, ceili(power * armor_multiplier(defense)))

# Player damage keeps fractional health internally in modern runs.
static func player_damage(power: float,defense: float) -> float:
	return maxf(0.0,power*armor_multiplier(defense))

static func begin(enemy: Dictionary, health: int, health_max: int, power: float, defense: float, rate: float, relics: Array, build: Dictionary = {}) -> Dictionary:
	var state = {"enemy": enemy.duplicate(true), "hp": health, "max_hp": health_max, "attack": power,
		"armor": defense, "speed": rate, "relics": relics.duplicate(), "p_time": (1.0 if build.get("full_opening",false) else 0.5)/maxf(0.05,rate) if build.get("paced",false) else 0.0,
		"e_time": 1.0 / float(enemy.speed), "p_hits": 0, "e_hits": 0, "done": false, "won": false,
		"time": 0.0, "regen_time": 2.0 if enemy.get("boss_kind","")=="ash" else INF,"regens":0,"revives":int(build.get("revives",0)),"burn_ticks":0, "fire_time": INF, "fire_until": -1.0, "iced": false, "poisoned": relics.has("venom") and int(build.get("poison",0)) > 0,
		"acid_stacks": 0, "rage": false, "build": build.duplicate(true),
		"initial_armor":float(enemy.armor), "tactics":bool(build.get("tactics",false)), "ability":str(build.get("ability","guard")), "ability_used":false, "waiting":false, "announced":-1, "disrupted":false, "shield":0, "wound":0, "chill_hits":0, "ice_triggered":false, "acid_triggered":false,
		"roll": maxi(1, int(enemy.get("roll_seed", 12345)) % 2147483647)}
	if "quickdraw" in relics:state.p_time=0.0
	state["deathless_used"]=false;state["burn_ward_used"]=false
	if enemy.get("mending",false) and enemy.get("boss_kind","")!="ash":state.regen_time=3.0
	if build.get("floor_rule","")=="water":state.e_time+=0.5
	if float(build.get("toxic_echo",0.0))>0:state.poisoned=true
	if Elements.enabled(state):Elements.prepare(state)
	update_phase(state)
	if Flow.modern(state):Flow.prepare(state)
	return state

static func ice_slow(state: Dictionary) -> float:
	if Elements.enabled(state):return Elements.slow(state)
	return minf(0.65,(0.18*mini(3,int(state.build.get("ice",0)))+float(state.build.get("ice_slow",0.0)))*(1.0+float(state.build.get("ice_mastery",0.0))))

static func poison_weak(state: Dictionary) -> float:
	if Elements.enabled(state):return 0.0
	return minf(0.65,(0.18*mini(3,int(state.build.get("poison",0)))+float(state.build.get("poison_weak",0.0)))*(1.0+float(state.build.get("poison_mastery",0.0)))+float(state.build.get("toxic_echo",0.0)))

static func fire_damage(state: Dictionary) -> float:
	if Elements.enabled(state):return Elements.burn_damage(state)
	return (float(state.build.get("fire_stack_damage",4.0))*mini(3,int(state.build.get("fire",0)))+float(state.build.get("fire_dps",0.0)))*(1.0+float(state.build.get("fire_mastery",0.0)))

static func enemy_speed(state: Dictionary) -> float:
	return float(state.enemy.speed)*(1.25 if state.rage else 1.0)*(1.0-ice_slow(state) if state.iced else 1.0)

static func update_phase(state: Dictionary) -> bool:
	if state.enemy.type != 3 or state.rage or state.enemy.hp <= 0 or state.enemy.hp > float(state.enemy.max) * 0.5: return false
	var old_speed = enemy_speed(state)
	state.rage = true
	state.e_time = state.time + maxf(0.0, state.e_time - state.time) * old_speed / enemy_speed(state)
	return true

static func next_time(state: Dictionary) -> float:
	return minf(float(state.get("poison_time",INF)),minf(state.regen_time,minf(state.p_time, minf(state.e_time, state.fire_time))))

static func step(state: Dictionary) -> Dictionary:
	if state.done: return {}
	if Flow.modern(state):Flow.prepare(state)
	var e: Dictionary = state.enemy
	var relics: Array = state.relics
	state.time = next_time(state)
	var toxic=Elements.enabled(state) and float(state.get("poison_time",INF))==state.time
	var burn = state.fire_time < minf(state.p_time, state.e_time)
	var regeneration=state.regen_time<minf(state.fire_time,minf(state.p_time,state.e_time))
	var result = {"player": toxic or burn or state.p_time <= state.e_time, "damage": 0, "actual_damage": 0.0, "heal": 0, "crit": false, "burn": burn and not toxic,"dot":burn or toxic,"poison_tick":toxic, "phase": false,"regen":regeneration,"enemy_heal":0,"revive":false}
	if toxic:
		result.damage=(0.25 if Elements.specialized(state.build) else 0.5)*float(state.poison_counters)
		result.actual_damage=minf(float(e.hp),result.damage);e.hp-=result.damage;state.poison_time+=0.5
		if "toxic_glacier" in relics and result.actual_damage>0 and e.hp>0:Elements.add_frost(state,0.5,result)
	elif regeneration:
		if Flow.modern(state):result.enemy_heal=Flow.regenerate(state)
		else:
			result.enemy_heal=minf(float(e.max)-float(e.hp),float(e.get("regen",4))+(4 if e.get("mending",false) and e.get("boss_kind","")=="ash" else 0))
			e.hp+=result.enemy_heal
			state.regens+=1
			state.regen_time=state.regen_time+(3.0 if e.get("mending",false) and e.get("boss_kind","")!="ash" else 2.0) if state.regens<(3 if e.get("mending",false) and e.get("boss_kind","")!="ash" else 5) else INF
	elif burn:
		state.burn_ticks+=1
		result.damage = fire_damage(state)*(1.5 if relics.has("cinder") and state.burn_ticks%3==0 else 1.0)*(Flow.burn_multiplier(state) if Flow.modern(state) else 1.0)
		if "caustic_burn" in relics and state.acid_stacks>0:result.damage*=1.25
		if e.get("affix","")=="warded" and not state.get("burn_ward_used",false):state.burn_ward_used=true;result.damage=0;result["effect"]="CINDER WARD"
		if relics.has("corrosive_flame"):
			state.acid_stacks=minf(float(state.initial_armor)+Elements.acid_cap(state.build) if Elements.specialized(state.build) else float(e.armor),state.acid_stacks+1);result["combo_element"]="caustic"
		if relics.has("toxic_spark") and state.poisoned and state.burn_ticks%3==0:
			result.heal=mini(1,int(state.max_hp)-int(state.hp));state.hp+=result.heal
			if result.heal>0:result["combo_element"]="toxic"
		result.actual_damage = minf(float(e.hp),float(result.damage))
		e.hp -= result.damage
		state.fire_time += 1.0
		if state.fire_time > state.fire_until + 0.00001:
			state.fire_time = INF
			if Elements.specialized(state.build):state.fire_heat=0
	elif result.player:
		var armor_before=maxf(0.0,float(e.armor)-float(state.acid_stacks))
		var power = float(state.attack)*(0.75 if int(state.get("wound",0))>0 else 1.0)
		state["wound"]=maxi(0,int(state.get("wound",0))-1)
		if Flow.modern(state):power=Flow.player_power(state,power,result)
		var weapon=str(state.build.get("weapon_archetype",state.build.get("weapon","")))
		if "glacial_crusher" in relics and weapon in ["axe","greatblade"] and state.iced:power*=1.30
		if "venom_edge" in relics and weapon=="dagger" and state.poisoned:power*=1.25
		if "shieldbreaker" in relics and weapon in ["axe","greatblade"] and float(e.armor)>state.acid_stacks:power*=1.25
		if "warded_blade" in relics and weapon=="balanced" and state.shield>0:power*=1.25
		if "ashen_charge" in relics and state.fire_until>=state.time:power*=1.20
		if relics.has("spark") and state.p_hits == 0: power *= 1.75
		# Private deterministic RNG: hovering never consumes rolls or changes future rooms.
		state.roll = (int(state.roll) * 48271) % 2147483647
		result.crit = float(state.roll) / 2147483647.0 < clampf(float(state.build.get("crit_chance", 0.0)), 0.0, clampf(float(state.build.get("crit_cap",0.6)),0.6,0.9))
		var frost_bonus=state.iced and relics.has("frost")
		if frost_bonus:power*=1.2
		if result.crit: power *= clampf(float(state.build.get("crit_mult", 1.5))+(0.3 if relics.has("steamglass") and state.iced and state.fire_until>=state.time else 0.0)+(0.2 if "frozen_precision" in relics and state.iced else 0.0), 1.0, 3.0)
		if result.crit and relics.has("steamglass") and state.iced and state.fire_until>=state.time:result["combo_element"]="steam"
		var burn_source_power=power
		var heavy=weapon in ["axe","greatblade"]
		var frost_shatter=heavy and "frost_shatter" in relics and Elements.enabled(state) and (bool(state.get("frost_shatter_ready",false)) if Elements.specialized(state.build) else float(state.get("frost_counters",0.0))>=3.0)
		var breakthrough=heavy and "breakthrough" in relics and bool(state.get("breakthrough_ready",false))
		if frost_shatter:power*=2.0 if Elements.specialized(state.build) else 1.5
		if "exposed_core" in relics and float(state.initial_armor)>0 and armor_before<=0.00001 and (not state.build.get("commitment_rules",false) or Elements.element_power(state.build,"acid")>=4):power*=1.25
		if breakthrough:power*=1.75
		if Elements.enabled(state):power*=1.0+Elements.exposure(state)
		var defense = maxf(0.0, float(e.armor) - state.acid_stacks) * (0.4 if relics.has("needle") else 1.0)
		var fair=bool(state.build.get("fair_physical",false))
		var armored_hit=player_damage(power,defense) if fair else float(damage(power,defense))
		var before_armor=player_damage(power,0) if fair else float(damage(power,0))
		var armor_prevented=maxf(0,minf(float(e.hp),before_armor)-minf(float(e.hp),armored_hit))
		var dealt = armored_hit
		if Flow.modern(state):dealt=Flow.weapon_damage(state,dealt,result)
		elif e.trait == "shield" and state.p_hits == 0: dealt = 0; result.crit = false
		if dealt==0:result.crit=false;result.erase("combo_element")
		elif frost_bonus and not state.get("frost_bonus_shown",false):
			state["frost_bonus_shown"]=true
			if not result.has("effect"):result["effect"]="FROST BONUS"
			if not result.has("combo_element"):result["combo_element"]="frost"
		result.actual_damage = minf(float(e.hp),dealt)
		e.hp -= dealt
		var physical_damage=float(result.actual_damage)
		result["physical_damage"]=physical_damage
		result["armor_prevented"]=armor_prevented if dealt>0 else 0.0
		if dealt>0 and frost_shatter:
			if Elements.specialized(state.build):state["frost_shatter_ready"]=false;Elements.end_freeze(state)
			else:Elements.spend_frost(state,3.0)
			result["frost_shatter"]=true;result["effect"]="FROST SHATTER";result["combo_element"]="frost"
		if dealt>0 and breakthrough:state["breakthrough_ready"]=false;result["breakthrough_hit"]=true;result["effect"]="BREAKTHROUGH"
		state.p_hits += 1
		state.p_time += 1.0 / float(state.speed)
		result.damage = dealt
		if dealt>0 and e.hp>0 and heavy and "combustion" in relics and int(state.get("fire_heat",0))>=4 and state.fire_time!=INF and state.fire_until>=state.time:
			var burst=Elements.burn_damage(state)*2.0;var applied=minf(float(e.hp),burst);e.hp-=burst
			state.fire_heat=0;result["combustion"]=true;result.damage+=applied;result.actual_damage+=applied;result["element_damage"]=float(result.get("element_damage",0))+applied;result["effect"]="COMBUSTION";result["combo_element"]="fire"
		if dealt > 0 and e.hp > 0:
			if Elements.enabled(state):
				Elements.on_hit(state,burn_source_power,result)
				if result.get("combustion",false):state.fire_heat=0
			else:
				var fire = fire_damage(state)
				if fire > 0:
					if state.fire_time == INF: state.fire_time = state.time + 1.0
					state.fire_until = state.time + (5.0 if relics.has("cinder") else 3.0) + (1.0 if state.build.get("floor_rule","")=="embers" else 0.0)
				if ice_slow(state) > 0 and not state.iced:
					var old_speed = enemy_speed(state)
					state.iced = true
					state.e_time = state.time + maxf(0.0, state.e_time - state.time) * old_speed / enemy_speed(state)
				state.poisoned = poison_weak(state) > 0
				var acid = float(state.build.get("acid_strip",0.0))
				var acid_rank = int(state.build.get("acid",0))
				var acid_boost=1.0+float(state.build.get("acid_mastery",0.0))
				state.acid_stacks = minf((acid_rank*4+acid*3)*acid_boost,state.acid_stacks+(((3 if relics.has("solvent") else 2) if acid_rank>0 else 0)+acid)*acid_boost)
		if state.get("tactics",false):
			if dealt>0 and state.build.get("floor_rule","")=="brittle": e.armor=maxf(0,float(e.armor)-1.0)
			if dealt>0 and relics.has("shatter") and state.iced and not Elements.enabled(state):
				state.chill_hits+=1
				if state.chill_hits>=3 and not state.ice_triggered:
					state.ice_triggered=true
					if Flow.modern(state):Flow.interrupt(state,1.5,result)
					else:state.disrupted=true;state.e_time+=1.5
					result["effect"]="FROST INTERRUPT"
			if relics.has("bulwark") and not state.acid_triggered and float(state.initial_armor)>0 and state.acid_stacks>=float(e.armor):
				state.acid_triggered=true;Flow.add_shield(state,6+2*int(state.build.get("acid",0)),2147483647,"acid");result["effect"]="ACID SHIELD"
		if heavy and "breakthrough" in relics:
			var armor_after=maxf(0.0,float(e.armor)-float(state.acid_stacks))
			if result.get("guard_break",false) or (armor_before>0.0 and armor_after<=0.00001):
				state["breakthrough_ready"]=true
				result["breakthrough_armed"]=true
				if not result.has("effect"):result["effect"]="BREAKTHROUGH READY"
		if relics.has("black_ice") and state.iced and state.poisoned and state.p_hits%3==0 and state.shield<6:Flow.add_shield(state,2,6,"black_ice");result["effect"]="BLACK ICE SHIELD";result["combo_element"]="black_ice"
		if relics.has("leech") and state.p_hits % 3 == 0:
			result.heal = mini(2, state.max_hp - state.hp)
			state.hp += result.heal
		if Flow.modern(state):Flow.after_player(state,result,physical_damage)
	else:
		var interrupted=bool(state.get("disrupted",false))
		state.e_hits += 1
		var power = float(e.attack) * (1.25 if state.rage else 1.0)
		if state.poisoned: power *= 1.0-poison_weak(state)
		var dodged=false
		if Flow.modern(state):
			state["current_followup"]=bool(state.get("tide_followup",false))
			dodged=Flow.dodge(state)
			var prepared=special_for_hit(state,state.e_hits) and not state.current_followup
			power=Flow.special(state,power,result,prepared)
			if prepared and not interrupted and e.get("hexed",false):result["apply_hex"]=true
			if e.get("signature","")=="furnace" and state.heat>=4 and not interrupted:power+=6;result["pierce"]=0.5
			if result.get("apply_hex",false) and not dodged:
				if state.get("hex_guard",false):state.hex_guard=false
				else:state.wound=3;result["effect"]="HEX"
			state.disrupted=false
		else:
			if state.get("tactics",false):
				if special_for_hit(state,state.e_hits) and not state.disrupted:
					power*=1.8 if e.type in [1,3] else 1.3
					if e.type==2 or e.get("hexed",false):
						if state.get("hex_guard",false):state["hex_guard"]=false;result["effect"]="HEX RESISTED"
						else:state.wound=3;result["effect"]="HEX: 3 STRIKES"
					if e.type==0:
						var heal=minf(4,float(e.max)-float(e.hp));e.hp+=heal;result.enemy_heal+=heal;result["effect"]="REGROW +4"
				state.disrupted=false
			elif e.trait == "heavy" and state.e_hits % 3 == 0: power *= 1.8
		var defense = float(state.armor) * float(result.get("pierce",0.5 if e.trait == "pierce" else 1.0))
		var dealt = damage(power, defense)
		if relics.has("ward") and state.e_hits == 1: dealt = maxi(1, ceili(dealt * 0.5))
		if dodged:dealt=0;result["evaded"]=true;result["effect"]="EVADE"
		elif state.get("guard",false):dealt=0;state["guard"]=false
		elif int(state.get("shield",0))>0:
			dealt=Flow.absorb_shield(state,dealt,result)
		if e.get("affix","")=="venomous" and state.e_hits==1 and not interrupted and not dodged:
			if state.get("hex_guard",false):state.hex_guard=false;result["effect"]="HEX RESISTED"
			else:state.wound=3;result["effect"]="HEXFANG"
		if e.get("affix","")=="siphon" and dealt>0:
			var heal=minf(2,float(e.max)-float(e.hp));e.hp+=heal;result.enemy_heal+=heal;result["effect"]="SIPHON +2"
		if Flow.modern(state):Flow.enemy_hit(state,result,dealt,interrupted)
		result.actual_damage = mini(int(state.hp), dealt)
		state.hp = maxi(0, state.hp - dealt)
		state.e_time += 1.0 / enemy_speed(state)
		if Flow.modern(state):Flow.after_enemy(state,result)
		result.damage = dealt
		if state.hp<=0:
			if int(state.get("revives",0))>0:
				state.revives-=1
				state.hp=maxi(1,ceili(state.max_hp*0.25))
				result.heal+=state.hp
				result.revive=true
			else:state.done=true
	if e.hp<=0 and e.get("affix","")=="stubborn" and not state.get("deathless_used",false):
		state.deathless_used=true;e.hp=maxi(1,ceili(float(e.max)*0.2));result.enemy_heal+=e.hp;result["effect"]="DEATHLESS RISE"
	if e.hp <= 0:
		var renewal=mini(int(state.build.get("recovery",0)),int(state.max_hp)-int(state.hp));state.hp+=renewal;result.heal+=renewal
		state.done = true
		state.won = true
		if relics.has("bloom"):
			var recovery = mini(4, state.max_hp - state.hp)
			state.hp += recovery
			result.heal += recovery
	elif not state.done: result.phase = update_phase(state)
	return result

static func predict(state: Dictionary) -> Dictionary:
	var copy = state.duplicate(true)
	var initial = int(copy.hp)
	while not copy.done: step(copy)
	return {"won": copy.won, "hp": copy.hp, "loss": initial - int(copy.hp)}

# Forecast deliberately spends no active ability. Manual choices never consume RNG.
static func special_for_hit(state: Dictionary,hit: int) -> bool:
	if not state.get("tactics",false):return false
	var period=2 if state.build.get("floor_rule","")=="eclipse" or state.enemy.get("affix","")=="frenzied" else 3
	return hit%period==(1 if state.enemy.get("ambush",false) else (0 if int(state.enemy.type)==3 else 2%period))

static func intent(state: Dictionary) -> String:
	if Flow.modern(state):
		if state.enemy.get("signature","") in Flow.BOSSES:return Flow.BOSSES[state.enemy.signature][0]+" / "+("Follow-up" if state.get("tide_followup",false) else ("Special" if special_for_hit(state,int(state.e_hits)+1) else "Strike"))
		if state.enemy.get("family","") in Flow.FAMILIES:return "Special" if special_for_hit(state,int(state.e_hits)+1) else "Strike"
	if state.enemy.get("affix","")=="venomous" and state.e_hits==0 and not state.get("disrupted",false):return "Hexfang bite / applies hex"
	if not special_for_hit(state,int(state.e_hits)+1) or state.get("disrupted",false):return "Strike"
	return ["Regrowth bite (1.3x, mends 4 HP)","Crushing blow (1.8x)","Hex bite (1.3x, weakens 3 strikes)","Warden's onslaught (1.8x)"][int(state.enemy.type)]

static func needs_decision(state: Dictionary) -> bool:
	if Flow.modern(state):return false
	return state.get("tactics",false) and not state.get("ability_used",false) and not state.done and state.e_time<=minf(state.p_time,minf(state.fire_time,state.regen_time)) and (special_for_hit(state,int(state.e_hits)+1) or (state.enemy.get("affix","")=="venomous" and state.e_hits==0)) and not state.get("disrupted",false) and int(state.get("announced",-1))!=int(state.e_hits)

static func use_ability(state: Dictionary) -> bool:
	if Flow.modern(state):return false
	if state.done or not state.get("tactics",false) or state.get("ability_used",false):return false
	state.ability_used=true
	match state.ability:
		"guard":state["guard"]=true
		"interrupt":state.e_time=maxf(float(state.time),float(state.e_time))+1.5;state.disrupted=true
		"mend":state.hp=mini(int(state.max_hp),int(state.hp)+mini(12,maxi(6,roundi(state.max_hp*0.2))));state.wound=0;state["hex_guard"]=true
	state.waiting=false
	state.announced=int(state.e_hits)
	return true
