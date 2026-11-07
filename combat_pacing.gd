extends RefCounted
## Run rules 7. Saved older runs keep their original combat economy.
const INTERVALS={"unarmed":2.0,"balanced":2.0,"dagger":1.0,"axe":3.0,"greatblade":2.8,"ember":2.2}
const POWER={"unarmed":1.0,"balanced":1.0,"dagger":0.5,"axe":1.9,"greatblade":1.65,"ember":0.85}
static func power_scale(weapon: String,balance: int=4) -> float:
	return 1.5 if weapon=="axe" and balance>=5 else float(POWER.get(weapon,1.0))
static func gains(g) -> Dictionary:
	return {"attack":3.0,"guard":2.0,"tempo":0.06,"focus":0.06,"ferocity":0.20,"haste":0.12,"precision":0.08,"ruin":0.25} if g.run_rules>=7 else {"attack":5.0,"guard":3.0,"tempo":0.15,"focus":0.20,"ferocity":0.50,"haste":0.25,"precision":0.20,"ruin":0.50}
static func player(g,gear: Dictionary,bonus: Dictionary,relics: Array) -> Dictionary:
	var index=int(g.equipped.get("weapon",-1));var weapon="unarmed"
	if index>=0 and index<g.inventory.size():weapon=g.inventory[index].get("archetype","balanced")
	return player_for_weapon(g,gear,bonus,relics,weapon)
static func player_for_weapon(g,gear: Dictionary,bonus: Dictionary,relics: Array,weapon: String) -> Dictionary:
	var weapon_power=power_scale(weapon,5 if g.run_rules>=10 else 4)
	var level=maxi(0,g.character_level-1);var cap=0.60+(0.15 if "critical_horizon" in relics else 0)+(0.15 if "unbound_aim" in relics else 0)
	var raw=0.05+bonus.crit_chance+gear.get("crit_chance",0)+(0.08 if "precision" in relics else 0)+(0.01 if g.run_rules>=11 else 0.003)*g.ember_tree.rank("precision_training")+(0.03 if "critical_horizon" in relics else 0)+(0.03 if "unbound_aim" in relics else 0)
	var speed=(1.0/float(INTERVALS.get(weapon,2.0)))*maxf(0.15,1.0+bonus.speed+gear.get("speed",0)+(0.12 if "haste" in relics and g.run_rules<18 else 0)+(0.01 if g.run_rules>=11 else 0.005)*g.ember_tree.rank("tempo"))
	speed*=maxf(0.15,1.0+float(gear.get("impact_rate",0)))
	if g.run_rules>=18 and "haste" in relics:speed=1.0/maxf(0.3,1.0/speed-0.15)
	if g.run_rules>=18 and "heavy_momentum" in relics and weapon in ["axe","greatblade"]:speed*=0.8
	var attack=(((5.0 if g.run_rules>=8 else 9.0)+(minf(level,3.0)+maxf(0.0,level-3.0)*0.45 if g.run_rules>=18 else level*(1.0 if g.run_rules>=15 else 0.35))+bonus.attack+(0.7 if g.run_rules>=11 else 0.35)*g.ember_tree.rank("might"))*weapon_power+gear.get("attack",0))*(1.0+float(gear.get("impact_power",0)))
	if g.run_rules>=18 and "heavy_momentum" in relics and weapon in ["axe","greatblade"]:attack*=1.45
	return {"max_hp":maxi(20,80+g.ember_tree.health_bonus()+level*(8 if g.run_rules>=15 else 6 if g.run_rules>=13 else 3)+roundi(gear.get("health",0))-g.vitality_tax),"attack":attack,"armor":(0.0 if g.run_rules>=8 else 1.0)+(minf(level,3.0)*0.35+maxf(0.0,level-3.0)*0.15 if g.run_rules>=18 else level*(0.35 if g.run_rules>=15 else 0.15))+bonus.armor+gear.get("armor",0)+(0.6 if g.run_rules>=11 else 0.30)*g.ember_tree.rank("armor_training"),"speed":speed,"crit_chance":minf(cap,raw),"crit_raw":raw,"crit_cap":cap,"crit_mult":minf(3.0,1.5+bonus.crit_mult+gear.get("crit_mult",0)+(0.25 if "ruin" in relics else 0)+(0.03 if g.run_rules>=11 else 0.015)*g.ember_tree.rank("ruin_training")),"weapon":weapon,"power_scale":weapon_power}
static func enemy(enemy: Dictionary,floor_number: int,depth: int,run_rules: int=11) -> void:
	var f=float(maxi(0,floor_number-1));var kind=int(enemy.type)
	if run_rules>=16:
		# Level sets the base; enemy type and encounter modifiers add variety.
		var n=float(maxi(0,int(enemy.level)-1))
		var health=12.0+13.0*n+(1.0 if run_rules>=19 else 0.5)*n*n
		var factor=[1.0,1.08,0.94,1.0][kind]
		if kind==3:health=220.0+190.0*f+45.0*f*f
		enemy.hp=ceili(health*factor);enemy.max=enemy.hp
		enemy.attack=3.0+n+(0.2 if run_rules>=19 else 0.1)*n*n
		enemy.armor=0.5*n
		enemy.speed=0.5*(1.0+0.06*f)
		if run_rules>=18 and f>0:
			if run_rules<19 or kind==3:
				enemy.hp=ceili(float(enemy.hp)*(1.0+0.10*f));enemy.max=enemy.hp
				enemy.attack=ceilf(float(enemy.attack)*(1.0+0.10*f))
			enemy.armor+=f*(0.75 if kind==1 else 0.25)
			enemy.speed*=1.0+(0.035 if kind==2 else 0.015)*f
		if kind==3:
			# Keep the opening boss close to its previous damage, then outpace
			# the floor's strongest standard enemies by roughly 20%.
			enemy.attack=maxf(11.0,1.2*enemy.attack-2.0)
			enemy.armor+=0.5*f
			if enemy.get("boss_kind","")=="iron":enemy.armor+=3
			if enemy.get("signature","")=="tide":enemy.speed*=1.10
			enemy["regen"]=roundi(8+2*f)
		return
	if run_rules>=15:
		# Base strength rises continuously across floors; enemy type adds variety.
		var n=float(maxi(0,int(enemy.level)-1))
		var health=12.0+13.0*n+0.2*n*n
		var factor=[1.0,1.08,0.94,1.0][kind]
		if kind==3:health=220.0+90.0*f+20.0*f*f
		enemy.hp=ceili(health*factor);enemy.max=enemy.hp
		enemy.attack=3.0+1.5*n
		if kind==3:enemy.attack=11.0+5.0*f+0.6*f*f
		enemy.armor=0.4*n
		enemy.speed=0.5*(1.0+0.06*f)
		if kind==3:
			if enemy.get("boss_kind","")=="iron":enemy.armor+=3
			if enemy.get("signature","")=="tide":enemy.speed*=1.10
			enemy["regen"]=roundi(8+2*f)
		return

	var growth=1.0+0.55*f+0.15*f*f
	if kind==3:growth=1.0+0.45*f+0.075*f*f
	if run_rules>=12:
		growth=(1.0+0.80*f+0.15*f*f) if kind==3 else (1.0+1.10*f+0.25*f*f)
	if run_rules>=13:
		growth=(1.0+0.95*f+0.20*f*f) if kind==3 else (1.0+1.45*f+0.35*f*f)
	var hp=ceili(([33.0,84.0,32.0,200.0][kind]+depth*([2.0,3.0,2.0,4.0][kind]))*growth)
	enemy.hp=hp;enemy.max=hp
	enemy.attack=[5.0,7.0,4.0,8.0][kind]+depth*0.30+((4.0*f+0.45*f*f) if run_rules>=12 else (2.5*f+0.20*f*f))
	enemy.armor=[1.0,5.0,0.5,7.0][kind]+(1.5 if run_rules>=12 else 0.8)*f
	enemy.speed=0.5*(1.0+(0.04 if run_rules>=12 else 0.025)*f)
	if run_rules>=13:
		enemy.attack=[5.0,7.0,4.0,8.0][kind]+depth*0.30+4.8*f+0.65*f*f
		enemy.armor=[1.0,5.0,0.5,7.0][kind]+2.0*f
		enemy.speed=0.5*(1.0+0.06*f)
	if kind==3:
		if enemy.get("boss_kind","")=="iron":enemy.armor+=3
		if enemy.get("signature","")=="tide":enemy.speed*=1.10
		enemy["regen"]=roundi(8*growth)
static func preview_interval(g,item: Dictionary) -> float:
	var slot=str(item.slot);var old_index=int(g.equipped.get(slot,-1));var old_speed=0.0
	if old_index>=0 and old_index<g.inventory.size():old_speed=float(g.Gear.stats(g.inventory[old_index]).get("speed",0))
	var weapon_index=int(g.equipped.get("weapon",-1));var weapon="unarmed"
	if weapon_index>=0 and weapon_index<g.inventory.size():weapon=g.inventory[weapon_index].get("archetype","balanced")
	if slot=="weapon":weapon=item.get("archetype","balanced")
	var mods=1.0+g.bonus.speed+float(g.gear_stats.get("speed",0))-old_speed+float(g.Gear.stats(item).get("speed",0))+(0.12 if "haste" in g.relics and g.run_rules<18 else 0)+(0.01 if g.run_rules>=11 else 0.005)*g.ember_tree.rank("tempo")
	var old_impact=0.0
	if old_index>=0 and old_index<g.inventory.size():old_impact=float(g.Gear.stats(g.inventory[old_index]).get("impact_rate",0))
	var impact=float(g.gear_stats.get("impact_rate",0))-old_impact+float(g.Gear.stats(item).get("impact_rate",0))
	var rate=maxf(0.15,mods)*maxf(0.15,1.0+impact)/float(INTERVALS.get(weapon,2.0))
	if g.run_rules>=18 and "haste" in g.relics:rate=1.0/maxf(0.3,1.0/rate-0.15)
	if g.run_rules>=18 and "heavy_momentum" in g.relics and weapon in ["axe","greatblade"]:rate*=0.8
	return 1.0/rate
