extends RefCounted
## Item level is the source of truth: upgrading recomputes, never compounds stats.
const SLOTS = ["weapon", "shield", "armor", "helmet", "amulet"]
const RARITIES = ["Common", "Rare", "Very rare"]
const COLORS = [Color("c7d7d5"), Color("85bcf2"), Color("c49aef")]
const NAMES = {"weapon":"Sword", "shield":"Shield", "armor":"Cuirass", "helmet":"Helmet", "amulet":"Amulet"}
const AFFIXES = ["crit_chance", "speed", "fire_dps", "ice_slow", "acid_strip", "poison_weak", "crit_mult", "health", "armor", "evade", "vampirism"]
const AMULET_FOCUSES=["crit_chance","crit_mult","vampirism","speed","health","evade","fire","ice","acid","poison"]
const AMULET_NAMES={"crit_chance":"Keen amulet","crit_mult":"Ruin amulet","vampirism":"Blood amulet","speed":"Swift amulet","health":"Vital amulet","evade":"Veil amulet","fire":"Fire amulet","ice":"Frost amulet","acid":"Acid amulet","poison":"Poison amulet"}

static func chest_odds(odds: Array,slot: String,run_rules: int) -> Array:
	var result=odds.duplicate()
	if run_rules>=12 and slot=="amulet":
		var shift=float(result[1])*0.35;result[0]=float(result[0])+shift;result[1]=float(result[1])-shift
	return result

static func make(slot: String, level: int, rarity: int, affixes: Array = [], archetype: String = "balanced") -> Dictionary:
	return {"slot":slot,"level":maxi(1,level),"rarity":clampi(rarity,0,2),"affixes":affixes.duplicate(),"name":({"balanced":"Sword","dagger":"Dagger","greatblade":"Greatblade","axe":"Axe","ember":"Ember blade"}.get(archetype,"Sword") if slot=="weapon" else NAMES[slot]),"archetype":archetype}

static func roll(rng: RandomNumberGenerator, slot: String, floor_number: int) -> Dictionary:
	var roll = rng.randi_range(1,100)
	var rarity = 0 if roll <= 65 else (1 if roll <= 93 else 2)
	var pool: Array = AFFIXES.duplicate()
	var affixes: Array = []
	for i in range(rarity): affixes.append(pool.pop_at(rng.randi_range(0,pool.size()-1)))
	return make(slot,floor_number + (1 if rng.randf() < 0.25 else 0),rarity,affixes)

static func stats(item: Dictionary) -> Dictionary:
	if int(item.get("balance",1))>=2:return modern_stats(item)
	return legacy_stats(item)

static func legacy_stats(item: Dictionary) -> Dictionary:
	var n = maxi(1,int(item.level))-1
	var rarity = int(item.rarity)
	var multiplier = [1.0,1.0,1.4][rarity]
	var result: Dictionary = {}
	match item.slot:
		"weapon":
			var archetype=item.get("archetype","balanced")
			var factor={"balanced":1.0,"dagger":0.6,"greatblade":1.5,"ember":0.6}.get(archetype,1.0)
			result["attack"]=ceilf((5.0+2.0*n)*multiplier*factor)
			if archetype=="dagger":result["speed"]=0.2+0.02*n;result["crit_chance"]=0.03;result["evade"]=0.03+0.001*n
			if archetype=="greatblade":result["speed"]=-0.2
			if archetype=="ember":result["fire_dps"]=1.5+0.4*n
		"shield": result["armor"] = (2.0+n)*multiplier
		"armor": result["armor"] = (3.0+n)*multiplier; result["health"] = ceilf((8.0+3.0*n)*multiplier)
		"helmet": result["armor"] = (1.0+0.5*n)*multiplier; result["health"] = ceilf((5.0+2.0*n)*multiplier)
		"amulet": result["crit_chance"] = (0.03+0.005*n)*multiplier;result["vampirism"]=(0.02+0.0015*n)*multiplier
	var strength = 2.0 if rarity==2 else 1.0
	for affix in item.affixes:
		var value = 0.0
		match affix:
			"crit_chance": value=(0.05+0.01*n)*strength
			"speed": value=(0.10+0.02*n)*strength
			"fire_dps": value=(1.0+0.5*n)*strength
			"ice_slow", "poison_weak": value=(0.05+0.01*n)*strength
			"acid_strip": value=(0.5+0.25*n)*strength
			"crit_mult": value=(0.15+0.025*n)*strength
			"health": value=(5.0+2.0*n)*strength
			"evade": value=(0.04+0.0025*n)*strength
			"vampirism": value=(0.05+0.0025*n)*strength
			"armor": value=(1.0+0.5*n)*strength
		result[affix]=result.get(affix,0.0)+value
	var infusion=item.get("infusion","")
	var rune_stats={"fire":["fire_dps",1.0+0.5*n],"ice":["ice_slow",0.05+0.01*n],"acid":["acid_strip",0.5+0.25*n],"poison":["poison_weak",0.05+0.01*n],"focus":["crit_chance",0.05+0.01*n],"ruin":["crit_mult",0.15+0.025*n],"veil":["evade",0.03+0.002*n],"blood":["vampirism",0.03+0.002*n]}
	if rune_stats.has(infusion):
		var pair=rune_stats[infusion]
		result[pair[0]]=result.get(pair[0],0.0)+pair[1]
	match item.get("variant",""):
		"bloodletter":
			result["evade"]=maxf(0,float(result.get("evade",0))-(0.03+0.001*n))
			if is_zero_approx(result.evade):result.erase("evade")
			result["vampirism"]=float(result.get("vampirism",0))+0.05+0.001*n
		"winterblade":result.attack=ceilf(result.attack*0.85);result["ice_slow"]=float(result.get("ice_slow",0))+0.08+0.001*n
		"caustic":result.fire_dps*=0.65;result["acid_strip"]=float(result.get("acid_strip",0))+0.75+0.05*n
	return result

static func stat_key(key: String,item: Dictionary) -> String:
	return preload("res://element_rules.gd").OLD.get(key,key) if int(item.get("balance",1))>=4 else key

static func title(item: Dictionary) -> String:
	return "%s Lv.%d %s" % [RARITIES[item.rarity],item.level,item.name]

static func stat_text(key: String, value: float) -> String:
	if key in ["fire_power","frost_apply","acid_apply","poison_apply"] and is_equal_approx(value,roundf(value)):
		return "%s %+d"%[{"fire_power":"Fire potency","frost_apply":"Frost power","acid_apply":"Acid power","poison_apply":"Poison power"}[key],roundi(value)]
	var labels={"impact_power":"Physical power","impact_rate":"Attack rate","fire_power":"Fire potency","frost_apply":"Frost power","acid_apply":"Acid power","poison_apply":"Poison power","attack":"Attack","armor":"Armor","health":"Max HP","speed":"Attack speed","crit_chance":"Crit chance","crit_mult":"Crit multiplier","fire_dps":"Fire damage/sec","ice_slow":"Enemy attack slow","acid_strip":"Armor removed/hit","poison_weak":"Less enemy damage","evade":"Evasion","vampirism":"Vampirism"}
	if key in ["impact_power","impact_rate","crit_chance","ice_slow","poison_weak","evade","vampirism"]:return "%s %+0.1f%%"%[labels[key],value*100]
	return "%s %+.1f"%[labels.get(key,key),value]

static func modern_stats(item: Dictionary) -> Dictionary:
	var n=maxi(0,int(item.level)-1);var rarity=int(item.rarity);var mult=[1.0,1.0,1.18][rarity];var strength=1.5 if rarity==2 else 1.0
	var result={};var archetype=item.get("archetype","balanced")
	match item.slot:
		"weapon":
			var base={"balanced":5.0,"dagger":2.5,"axe":7.5 if int(item.get("balance",1))>=5 else 9.5,"greatblade":8.25,"ember":4.25}.get(archetype,5.0)
			if int(item.get("balance",1))>=3:base*=1.8 # Move four character power into weapon damage; preserve opening weapon DPS.
			var growth={"balanced":1.0,"dagger":0.45,"axe":1.5 if int(item.get("balance",1))>=5 else 2.2,"greatblade":1.8,"ember":0.8}.get(archetype,1.0)
			if int(item.get("balance",1))>=7:growth={"balanced":3.0,"dagger":1.35,"axe":4.5,"greatblade":5.4,"ember":2.4}.get(archetype,3.0)
			elif int(item.get("balance",1))>=6:growth*=1.25
			result.attack=(base+growth*n)*mult
			if archetype=="dagger":result.speed=0.04*n;result.crit_chance=0.02;result.evade=0.025+0.0008*n
			if archetype=="ember":result.fire_dps=0.6+0.18*n
		"shield":result.armor=((2.0+3.0*n) if int(item.get("balance",1))>=7 else (1.5+(0.65 if int(item.get("balance",1))>=6 else 0.45)*n))*mult
		"armor":result.armor=((3.0+3.0*n) if int(item.get("balance",1))>=7 else (2+(0.75 if int(item.get("balance",1))>=6 else 0.55)*n))*mult;result.health=ceilf((9+(4.0 if int(item.get("balance",1))>=7 else 2.4 if int(item.get("balance",1))>=6 else 1.8)*n)*mult)
		"helmet":result.armor=((1.0+1.5*n) if int(item.get("balance",1))>=7 else (0.8+(0.45 if int(item.get("balance",1))>=6 else 0.30)*n))*mult;result.health=ceilf((6+(3.0 if int(item.get("balance",1))>=7 else 1.8 if int(item.get("balance",1))>=6 else 1.2)*n)*mult)
		"amulet":
			if not item.has("amulet_focus"):result.crit_chance=(0.02+0.002*n)*mult;result.vampirism=(0.015+0.001*n)*mult
	if item.slot=="armor":
		match item.get("armor_class",""):
			"light":result.armor*=0.8;result.health=ceilf(result.health*0.85);result.speed=0.08
			"heavy":result.armor*=1.2;result.health=ceilf(result.health*1.15);result.speed=-0.04
	for affix in item.affixes:
		var values={"crit_chance":0.03+0.003*n,"speed":0.035+0.006*n,"fire_dps":0.6+0.18*n,"ice_slow":0.035+0.004*n,"acid_strip":0.4+0.12*n,"poison_weak":0.035+0.004*n,"crit_mult":0.10+0.015*n,"health":5.0+1.2*n,"armor":0.75+0.25*n,"evade":0.03+0.0015*n,"vampirism":0.035+0.0015*n}
		result[affix]=float(result.get(affix,0))+float(values.get(affix,0))*strength
	var infusion=item.get("infusion","")
	var runes={"fire":["fire_dps",0.6+0.18*n],"ice":["ice_slow",0.035+0.004*n],"acid":["acid_strip",0.4+0.12*n],"poison":["poison_weak",0.035+0.004*n],"focus":["crit_chance",0.025+0.002*n],"ruin":["crit_mult",0.10+0.015*n],"veil":["evade",0.025+0.001*n],"blood":["vampirism",0.025+0.001*n]}
	if runes.has(infusion):var pair=runes[infusion];result[pair[0]]=float(result.get(pair[0],0))+float(pair[1])
	match item.get("variant",""):
		"bloodletter":
			result.evade=maxf(0,float(result.get("evade",0))-(0.025+0.0008*n));result.vampirism=float(result.get("vampirism",0))+0.035+0.0008*n
		"winterblade":result.attack*=0.85;result.ice_slow=float(result.get("ice_slow",0))+0.06+0.0008*n
		"caustic":result.fire_dps*=0.65;result.acid_strip=float(result.get("acid_strip",0))+0.6+0.035*n
	if item.get("plain",false):
		if archetype=="dagger":
			result.crit_chance=maxf(0,float(result.get("crit_chance",0))-0.02)
			result.evade=maxf(0,float(result.get("evade",0))-(0.025+0.0008*n))
			for key in ["crit_chance","evade"]:
				if is_zero_approx(result.get(key,0)):result.erase(key)
	if int(item.get("balance",1))>=4:
		var mapping=preload("res://element_rules.gd").OLD
		var rank=1+int(n/2 if int(item.get("balance",1))>=7 else n/4)
		for old in mapping:
			var amount=0.0
			if old=="fire_dps" and archetype=="ember" and not item.get("plain",false):amount+=rank
			for affix in item.affixes:
				if affix==old:amount+=roundf(rank*strength)
			var rune={"fire_dps":"fire","ice_slow":"ice","acid_strip":"acid","poison_weak":"poison"}[old]
			if item.get("infusion","")==rune:amount+=rank
			if item.get("variant","")=="winterblade" and old=="ice_slow":amount+=rank
			if item.get("variant","")=="caustic":
				if old=="acid_strip":amount+=rank
				if old=="fire_dps":amount*=0.65
			result.erase(old)
			if amount>0:result[mapping[old]]=amount
	if int(item.get("balance",1))>=6 and item.has("amulet_focus"):
		var focus=str(item.amulet_focus)
		var focus_key={"fire":"fire_power","ice":"frost_apply","acid":"acid_apply","poison":"poison_apply"}.get(focus,focus)
		var values={"crit_chance":0.08+0.015*n,"crit_mult":0.25+0.04*n,"vampirism":0.07+0.0125*n,"speed":0.10+0.015*n,"health":12.0+2.4*n,"evade":0.06+0.008*n,"fire":1.0+0.4*n,"ice":1.0+0.4*n,"acid":1.0+0.4*n,"poison":1.0+0.4*n}
		if int(item.get("balance",1))>=7:
			values={"crit_chance":0.08+0.025*n,"crit_mult":0.25+0.06*n,"vampirism":0.07+0.02*n,"speed":0.10+0.025*n,"health":12.0+4.0*n,"evade":0.06+0.012*n,"fire":1.0+0.5*n,"ice":1.0+0.5*n,"acid":1.0+0.5*n,"poison":1.0+0.5*n}
		result[focus_key]=float(result.get(focus_key,0))+float(values.get(focus,0))*mult
	var sanctuary_bonus=str(item.get("sanctuary_bonus",""))
	if int(item.get("balance",1))>=4 and sanctuary_bonus in ["fire","ice","acid","poison"]:
		var key={"fire":"fire_power","ice":"frost_apply","acid":"acid_apply","poison":"poison_apply"}[sanctuary_bonus]
		result[key]=float(result.get(key,0))+1+int(n/4)
	if item.slot=="weapon" and item.get("heavy_form","")=="colossus":
		result["impact_power"]=0.60
		result["impact_rate"]=-0.20
	if int(item.get("balance",1))>=4:
		for key in result.keys():
			if is_zero_approx(float(result[key])):result.erase(key)
	return result
