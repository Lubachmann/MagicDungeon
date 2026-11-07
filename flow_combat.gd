extends RefCounted
## Automatic combat rules. Every counter and private RNG lives inside the saved battle.
const FAMILIES={
	"pikeman":{"name":"Orc Marauder","icon":"attack","sprite":"orc_raider","color":Color("c9b896"),"desc":"Special hits ignore 75% of your armor. Evade avoids the hit."},
	"leech":{"name":"Blood Revenant","icon":"ice","sprite":"revenant","color":Color("72bfc9"),"desc":"Heals for 25% of damage dealt to your HP. Blocked or evaded damage gives no healing."},
	"wisp":{"name":"Cinder Fiend","icon":"fire","sprite":"fiend","color":Color("f3ae72"),"desc":"Takes 50% less burn damage. Ice or acid removes this protection."},
	"construct":{"name":"Forge Skullguard","icon":"armor","sprite":"skullguard","color":Color("d39566"),"desc":"3 plates block 35% of weapon damage. Hits break 1 plate; greatblades break all. Fire ignores plates."},
	"shade":{"name":"Mirror Cultist","icon":"moon","sprite":"cultist","color":Color("b6a0e5"),"desc":"Dodges every 4th hit. Ice stops this. Dagger finishers and greatblade armor breaks still hit."}}
const FAMILY_ORDER=["pikeman","leech","wisp","construct","shade"]
const BOSSES={
	"castellan":["Mire Colossus","armor","Opening guard absorbs 8 physical damage and returns below 50% HP. Greatblades break it; active Fire and Poison bypass it."],
	"tide":["Tide Ogre","ice","Special attacks hit again after 0.25s. Each hit can be dodged."],
	"abbot":["Ash Necromancer","fire","Heals every 2s, up to 5 times. Fire cuts healing by 50%. Interrupts delay healing."],
	"furnace":["Furnace Demon","iron","At 4 heat: +6 attack and ignores 50% armor. Your hits add heat; ice hits cool it."],
	"eclipse":["Eclipse Seraph","moon","Takes 25% less weapon damage or 50% less burn damage. Crits or removing all armor cancel this."]}
const WEAPONS={"axe":["Axe","Every 3rd hit: +35% hit power. Slow swings reward attack, critical damage and armor removal."],"balanced":["Sword","Every 4 hits: gain 3 shield. Shield blocks incoming damage. Max 8 shield."],"dagger":["Dagger","Every 3 hits: +50% power on the 3rd. Losing HP or missing resets the count. Dodging keeps it."],"greatblade":["Greatblade","Breaks guards. Every 3rd swing: +20% power, removes armor and delays the enemy by 0.5s."],"ember":["Ember blade","Every 3 hits: extra fire damage equal to 150% of your fire damage/s. Ignores armor."]}
static func modern(s: Dictionary) -> bool:return s.build.get("auto_flow",false)
static func prepare(s: Dictionary) -> void:
	if s.get("flow_ready",false):return
	s["flow_ready"]=true;s.waiting=false
	s["combo"]=0;s["successful_hits"]=0;s["life_fraction"]=clampf(float(s.build.get("life_fraction",0.0)),0.0,0.999999) if s.hp<s.max_hp else 0.0;s["heat"]=0;s["seal_phase"]=0;s["seal_broken"]=false;s["tide_followup"]=false
	s["plates"]=3 if s.enemy.get("family","")=="construct" else 0
	s["weapon_guard"]=1 if s.enemy.trait=="shield" and s.p_hits==0 else 0
	if s.build.get("fair_physical",false):s["guard_hp"]=8.0 if s.weapon_guard>0 else 0.0
	s["evade_roll"]=maxi(1,(int(s.enemy.get("roll_seed",12345)) ^ 1540483477)%2147483647)
	if int(s.enemy.type)==3 and not s.enemy.has("signature"):
		s.enemy["signature"]={"keep":"castellan","water":"tide","embers":"abbot","brittle":"furnace","eclipse":"eclipse"}.get(s.build.get("floor_rule",""),"castellan")
	var abbot=s.enemy.get("signature","")=="abbot"
	s["regen_limit"]=5 if abbot else 3;s["regen_interval"]=2.0 if abbot else 3.0
	s["regen_amount"]=float(s.enemy.get("regen",4))+(4.0 if abbot and s.enemy.get("mending",false) else 0.0)
	if int(s.enemy.type)==3 or s.enemy.get("mending",false):s.regen_time=s.time+s.regen_interval if abbot or s.enemy.get("mending",false) else INF
static func dodge(s: Dictionary) -> bool:
	s.evade_roll=(int(s.evade_roll)*48271)%2147483647
	return float(s.evade_roll)/2147483647.0<clampf(float(s.build.get("evade",0.0)),0.0,0.5)
static func interrupt(s: Dictionary,delay: float,result: Dictionary) -> void:
	if not s.disrupted:
		s.e_time+=delay
		if s.enemy.get("signature","")=="abbot" and s.regen_time!=INF:s.regen_time+=delay
	s.disrupted=true
	result["interrupt"]=true
static func player_power(s: Dictionary,power: float,result: Dictionary) -> float:
	var weapon=s.build.get("weapon","balanced")
	if weapon=="axe" and (s.p_hits+1)%3==0:power*=1.35;result["effect"]="CLEAVE"
	if weapon=="dagger" and s.combo==2:power*=1.5;result["finisher"]=true;result["effect"]="COMBO"
	if weapon=="greatblade" and (s.p_hits+1)%3==0:
		s.enemy.armor=maxf(0,float(s.enemy.armor)-2.0-0.25*int(s.build.get("weapon_level",1)))
		interrupt(s,0.5,result);power*=1.2;result["sunder"]=true;result["effect"]="SUNDER"
	return power
static func weapon_damage(s: Dictionary,dealt: float,result: Dictionary) -> float:
	var weapon=s.build.get("weapon","balanced")
	if s.enemy.get("family","")=="shade" and (s.p_hits+1)%4==0 and not s.iced and not result.get("finisher",false) and not result.get("sunder",false):result["enemy_evade"]=true;result["effect"]="PHASE";return 0
	if s.weapon_guard>0:
		if s.build.get("fair_physical",false):
			if weapon=="greatblade":
				s.weapon_guard=0;s.guard_hp=0.0;result["guard_break"]=true;result["effect"]="GUARD BREAK"
			else:
				var absorbed=minf(dealt,float(s.get("guard_hp",8.0)));dealt-=absorbed;s.guard_hp=maxf(0.0,float(s.get("guard_hp",8.0))-absorbed);result["guard_absorbed"]=absorbed;result["effect"]="GUARD"
				if s.guard_hp<=0.000001:s.weapon_guard=0;result["guard_break"]=true;result["effect"]="GUARD BREAK"
				if dealt<=0.000001:return 0.0
		else:
			s.weapon_guard-=1
			if weapon!="greatblade":result["effect"]="GUARD";return 0.0
			result["guard_break"]=true;result["effect"]="GUARD BREAK"
	if s.plates>0:
		if weapon=="greatblade":s.enemy.armor=maxf(0,float(s.enemy.armor)-s.plates);s.plates=0;result["guard_break"]=true;result["effect"]="PLATES SHATTER"
		else:dealt=dealt*0.65 if s.build.get("fair_physical",false) else maxi(1,ceili(dealt*0.65));s.plates-=1;s.enemy.armor=maxf(0,float(s.enemy.armor)-1)
	if s.enemy.get("signature","")=="eclipse" and not s.seal_broken and s.seal_phase==0:
		if result.crit:s.seal_broken=true;result["effect"]="SEAL BREAK"
		else:dealt=dealt*0.75 if s.build.get("fair_physical",false) else maxi(1,ceili(dealt*0.75))
	return dealt
static func after_player(s: Dictionary,result: Dictionary,physical: float) -> void:
	if physical<=0:s.combo=0;return
	s.successful_hits+=1;s.combo=(s.combo+1)%3
	var missing=int(s.max_hp)-int(s.hp)
	if missing>0:
		var bonus=1.5 if "blood_harvest" in s.relics and s.poisoned else 1.0
		var credit=physical*clampf(float(s.build.get("vampirism",0.0)),0.0,0.35)*bonus+s.life_fraction
		var heal=mini(missing,floori(credit+0.000001));s.hp+=heal;result.heal+=heal;result["vamp_heal"]=heal
		s.life_fraction=maxf(0.0,credit-float(heal)) if s.hp<s.max_hp else 0.0
	else:s.life_fraction=0.0
	var weapon=s.build.get("weapon","balanced")
	if weapon=="balanced" and s.successful_hits%4==0:
		if s.shield<8:s.shield=mini(8,s.shield+3)
		result["effect"]="SWORD WARD";result["shielded"]=true
	if weapon=="ember" and s.successful_hits%3==0 and s.enemy.hp>0:
		var fire=(float(s.build.get("fire_stack_damage",4.0))*mini(3,int(s.build.get("fire",0)))+float(s.build.get("fire_dps",0.0)))*(1.0+float(s.build.get("fire_mastery",0.0)))
		if s.build.get("elemental_v2",false):fire=preload("res://element_rules.gd").burn_damage(s)
		var flare=minf(float(s.enemy.hp),fire*1.5);s.enemy.hp-=flare;result.actual_damage+=flare;result["element_damage"]=flare;result["effect"]="FLARE"
	if s.enemy.get("signature","")=="castellan" and s.enemy.hp>0 and s.enemy.hp<=float(s.enemy.max)*0.5 and not s.get("bastion_used",false):
		s["bastion_used"]=true;s.weapon_guard=1
		if s.build.get("fair_physical",false):s["guard_hp"]=8.0
		result["effect"]="BASTION"
	if s.enemy.get("signature","")=="furnace":s.heat=clampi(s.heat+1-(2 if s.iced else 0),0,4)
	if s.enemy.get("signature","")=="eclipse" and not s.seal_broken and (result.crit or (result.get("sunder",false) and float(s.enemy.armor)<=0) or (float(s.enemy.armor)>0 and s.acid_stacks>=float(s.enemy.armor))):s.seal_broken=true;result["effect"]="SEAL BREAK"
static func burn_multiplier(s: Dictionary) -> float:
	if s.enemy.get("family","")=="wisp" and not s.iced and s.acid_stacks<=0:return 0.5
	if s.enemy.get("signature","")=="eclipse" and not s.seal_broken and s.seal_phase==1:return 0.5
	return 1.0
static func special(s: Dictionary,power: float,result: Dictionary,is_special: bool) -> float:
	var family=s.enemy.get("family","");var sig=s.enemy.get("signature","")
	if s.get("current_followup",false):return power*0.6
	if not is_special or s.disrupted:return power
	if family!="":
		if family=="pikeman":result["pierce"]=0.25;result["effect"]="REACH THRUST";return power*1.3
		if family=="leech":result["enemy_lifesteal"]=true;result["effect"]="DRAINING BITE"
		return power*1.25
	if sig!="":
		match sig:
			"castellan":return power*1.35
			"tide":result["queue_wave"]=true;result["effect"]="TIDAL FLURRY";return power
			"abbot":result["effect"]="SOUL STRIKE";return power*1.4
			"furnace":return power*1.4
			"eclipse":return power*1.4
	if int(s.enemy.type)==0:
		var heal=minf(4,float(s.enemy.max)-float(s.enemy.hp));s.enemy.hp+=heal;result["enemy_heal"]=float(result.get("enemy_heal",0))+heal;result["effect"]="REGROW +4"
	if int(s.enemy.type)==2 or s.enemy.get("hexed",false):result["apply_hex"]=true
	return power*(1.8 if int(s.enemy.type) in [1,3] else 1.3)
static func enemy_hit(s: Dictionary,result: Dictionary,dealt: int,interrupted: bool) -> void:
	if s.enemy.get("family","")=="leech" and dealt>0:
		var amount=minf(float(s.enemy.max)-float(s.enemy.hp),minf(float(s.hp),dealt)*0.25);s.enemy.hp+=amount;result["enemy_heal"]=float(result.get("enemy_heal",0))+amount;result["effect"]="LEECH +%.1f"%amount
	if dealt>0:s.combo=0
	if s.enemy.get("signature","")=="furnace" and s.heat>=4 and not interrupted:s.heat=0;result["effect"]="FURNACE VENT"
static func after_enemy(s: Dictionary,result: Dictionary) -> void:
	if result.get("queue_wave",false):s.tide_followup=true;s.e_time=s.time+0.25
	elif s.get("current_followup",false):s.tide_followup=false
	if s.enemy.get("signature","")=="eclipse" and s.e_hits%2==0:s.seal_phase=1-int(s.seal_phase);s.seal_broken=false;result["effect"]="LUNAR SEAL" if s.seal_phase==1 else "SOLAR SEAL"
static func regenerate(s: Dictionary) -> float:
	var amount=float(s.regen_amount)
	if s.enemy.get("signature","")=="abbot" and s.fire_until>=s.time and s.fire_time!=INF:amount*=0.5
	var heal=minf(float(s.enemy.max)-float(s.enemy.hp),amount);s.enemy.hp+=heal;s.regens+=1
	s.regen_time=s.regen_time+s.regen_interval if s.regens<s.regen_limit else INF
	return heal
static func assign_family(e: Dictionary,index: int) -> void:
	var id=FAMILY_ORDER[index];e["family"]=id;e.name=FAMILIES[id].name;e.trait="pierce" if id=="pikeman" else "none"
static func decorate_floor(g) -> void:
	if g.run_rules<6:return
	var candidates=[];var index=posmod(g.floor_number-1,5)
	for coord in g.rooms:
		var data=g.rooms[coord];data["atmosphere"]=[]
		for tile in data.entities:
			var e=data.entities[tile]
			if coord!=Vector2i.ZERO and int(e.get("type",-1)) in [0,1,2] and e.kind=="enemy" and not e.get("gatekeeper",false):candidates.append(e)
		for x in range(data.bounds.position.x+1,data.bounds.end.x-1):
			for y in range(data.bounds.position.y+1,data.bounds.end.y-1):
				var tile=Vector2i(x,y)
				if not data.walls.has(tile) and not data.entities.has(tile) and (x*17+y*23+g.run_seed+coord.x*7+coord.y*11)%29==0:data.atmosphere.append(tile)
	var count=mini(2+(mini(2,g.floor_number-1) if g.run_rules>=18 else 0),candidates.size())
	for i in range(count):assign_family(candidates[(i+index)%candidates.size()],(index+i)%FAMILY_ORDER.size() if g.run_rules>=18 else index)
