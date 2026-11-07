extends RefCounted
var g
var sparks=[]
var evade_time=0.0
var impact_time=0.0
var state: Dictionary={}
var hitstop=0.0
var shake_time=0.0
var strength=0.0
var bar_ghost=0.0
var bar_time=0.0
var level_time=0.0
var reward_time=0.0
var rewards={"xp":0,"ember":0,"flasks":0}
func _init(game):g=game
func reduced() -> bool:return g.session and g.session.preferences.reduced_flashes
func tick(delta: float) -> void:
	bar_time=maxf(0,bar_time-delta)
	hitstop=maxf(0,hitstop-delta);shake_time=maxf(0,shake_time-delta);level_time=maxf(0,level_time-delta);reward_time=maxf(0,reward_time-delta)
	if reduced():hitstop=0;shake_time=0
	evade_time=maxf(0,evade_time-delta);impact_time=maxf(0,impact_time-delta)
	for i in range(sparks.size()-1,-1,-1):
		sparks[i].ttl-=delta
		if sparks[i].ttl<=0:sparks.remove_at(i)
func emit(kind: String,color: Color,at: Vector2) -> void:
	if reduced():return
	sparks.append({"kind":kind,"color":color,"at":at,"ttl":0.35,"scale":0.7+strength*0.7})
	if sparks.size()>20:sparks.pop_front()
func hit(event: Dictionary,battle: Dictionary) -> void:
	state=battle
	if event.player and event.actual_damage>0:bar_ghost=maxf(float(g.fight.hp),float(battle.enemy.hp));bar_time=0.22
	if not reduced() and float(event.actual_damage)>0 and not event.get("dot",event.burn) and not event.regen:
		strength=impact_strength(float(event.damage),event.crit)
		shake_time=0.10+strength*0.08
		if event.crit or float(event.damage)>=18:hitstop=0.025+strength*0.03
		if event.player and strength>=0.6:g.sfx("heavy_impact")
	if event.has("effect"):
		var effect=str(event.effect);var hero=event.get("evaded",false) or effect in ["SWORD WARD","ACID SHIELD","BLACK ICE SHIELD","HEX","HEXFANG","HEX RESISTED"]
		var at=g.ORIGIN+Vector2(g.pos if hero else g.fight.position)*g.TILE+Vector2(-10,-25)
		g.motes.append({"at":at,"value":effect,"ttl":1.0,"color":g.TEAL if hero else g.GOLD})
	var player=g.ORIGIN+Vector2(g.pos)*g.TILE+Vector2(24,24)
	var enemy=g.ORIGIN+Vector2(g.fight.position)*g.TILE+Vector2(24,24)
	if event.get("breakthrough_armed",false):g.motes.append({"at":player+Vector2(-30,-45),"value":"NEXT HIT +75%","ttl":1.1,"color":g.GOLD})
	if event.get("frost_shatter",false) and event.get("effect","")!="FROST SHATTER":g.motes.append({"at":enemy+Vector2(-35,-65),"value":"FROST SHATTER","ttl":1.0,"color":Color("8ad9df")})
	if event.get("breakthrough_hit",false) and event.get("effect","")!="BREAKTHROUGH":g.motes.append({"at":enemy+Vector2(-35,-85),"value":"BREAKTHROUGH","ttl":1.0,"color":g.GOLD})
	if event.get("evaded",false):
		evade_time=0.28;g.summary["evades"]=int(g.summary.get("evades",0))+1;emit("evade",Color("91d9eb"),player);g.sfx("evade")
	elif event.get("enemy_evade",false):emit("evade",Color("ba95df"),enemy);g.sfx("evade")
	elif event.crit:emit("critical",g.GOLD,enemy);g.sfx("critical");impact_time=0.16
	elif event.get("guard_break",false) or event.get("sunder",false):emit("shatter",Color("eeb485"),enemy);g.sfx("guard_break");impact_time=0.18
	elif event.get("interrupt",false):emit("shatter",Color("99ddeb"),enemy);g.sfx("interrupt")
	elif event.get("shielded",false) or event.get("effect","") in ["SWORD WARD","ACID SHIELD","BLACK ICE SHIELD"]:
		emit("shield",Color("d0de78") if event.get("effect","")=="ACID SHIELD" else g.TEAL,player);g.sfx("ward")
	elif event.get("effect","")=="FLARE":emit("critical",Color("ed9a65"),enemy);g.sfx("flare")
	elif event.get("poison_tick",false):emit("shatter",Color("96cc79"),enemy)
	elif event.burn:emit("shatter",Color("eaa16b"),enemy);g.sfx("burn")
	elif not event.regen:g.sfx("block" if event.damage==0 else ("swing" if event.player else "hurt"))
	if event.get("combo_element","")!="":
		var id=event.combo_element;var color={"fire":Color("eaa16b"),"poison":Color("96cc79"),"frost":Color("8ad9df"),"steam":Color("8ad9df"),"caustic":Color("ccdc76"),"black_ice":Color("a19edb"),"toxic":Color("b1c88a")}[id]
		emit("shatter",color,enemy);g.sfx("resonance")
		g.motes.append({"at":enemy+Vector2(-32,-50),"value":str(id).replace("_"," ").to_upper(),"ttl":0.8,"color":color})
	if event.crit and (event.get("guard_break",false) or event.get("sunder",false)):emit("shatter",Color("eeb485"),enemy);g.sfx("guard_break")
	if event.get("interrupt",false):g.summary["interrupts"]=int(g.summary.get("interrupts",0))+1
	if int(event.get("vamp_heal",0))>0:
		g.summary["vamp_healed"]=int(g.summary.get("vamp_healed",0))+int(event.vamp_heal);g.mastery.add("vamp_healed",int(event.vamp_heal));emit("drain",Color("dc7b90"),enemy);g.sfx("vamp")
	if event.player and event.actual_damage>0 and not event.get("dot",event.burn):impact_time=0.13;emit("slash",Color("f2bd83") if event.get("finisher",false) else g.INK,enemy)
	if event.get("effect","").contains("FROST"):emit("shatter",Color("87c7ef"),enemy)
func player_offset() -> Vector2:
	if reduced() or g.mode!="fight":return Vector2.ZERO
	return Vector2(0,-sin(evade_time/0.28*PI)*10)
func enemy_offset() -> Vector2:
	if reduced():return Vector2.ZERO
	return Vector2(sin(impact_time/0.18*PI)*(2+strength*4),0)
func draw() -> void:
	if g.mode not in ["play","fight","inspect","bomb"] or reduced():return
	var player=g.ORIGIN+Vector2(g.pos)*g.TILE+Vector2(24,24)
	if g.mode=="fight" and state.get("shield",0)>0:g.draw_rect(Rect2(player-Vector2(23,23),Vector2(46,46)),Color(g.TEAL,0.7),false,2)
	if g.mode=="fight" and state.get("heat",0)>0:
		var enemy=g.ORIGIN+Vector2(g.fight.position)*g.TILE+Vector2(24,24)
		for i in range(int(state.heat)):g.draw_rect(Rect2(enemy+Vector2(-20+i*11,29),Vector2(8,4)),Color("ed9a65"))
	for spark in sparks:
		var t=1.0-float(spark.ttl)/0.35;var at=spark.at;var scale=float(spark.get("scale",1));var color=Color(spark.color,1.0-t)
		match spark.kind:
			"drain":
				var point=at.lerp(player,t)
				g.draw_rect(Rect2(point-Vector2(2,2),Vector2(4,4)),color)
			"slash":g.draw_line(at+Vector2(-16+25*t,16-25*t),at+Vector2(12+12*t,-12-12*t),color,3)
			"shield":g.draw_rect(Rect2(at-Vector2.ONE*(18+12*t),Vector2.ONE*(36+24*t)),color,false,2)
			_:
				for i in range(8):
					var dir=Vector2.from_angle(i*TAU/8)
					g.draw_rect(Rect2(at+dir*(12+18*t)*scale-Vector2(2,2),Vector2(4,4)),color)

static func impact_strength(damage: float,critical: bool=false) -> float:
	return clampf(log(1.0+maxf(0,damage)/8.0)/log(12.0)+(0.15 if critical else 0),0,1)
func number_size(event: Dictionary) -> int:
	return roundi(20+impact_strength(float(event.damage),event.crit)*12) if not event.get("dot",event.burn) else 20
func camera_offset() -> Vector2:
	if reduced() or shake_time<=0:return Vector2.ZERO
	var amplitude=(0.5+strength*3.5)*clampf(shake_time/0.18,0,1)
	return Vector2(sin(g.pulse*113),cos(g.pulse*137))*amplitude
func clear() -> void:
	sparks.clear();evade_time=0;impact_time=0;hitstop=0;shake_time=0;bar_time=0;level_time=0;reward_time=0;state={}
func level_up(_count: int) -> void:
	level_time=3.0;g.sfx("blessing")
	var at=g.ORIGIN+Vector2(g.pos)*g.TILE+Vector2(24,24)
	emit("shield",g.GOLD,at)
	g.motes.append({"at":at+Vector2(-35,-24),"value":"LEVEL UP!","ttl":1.8,"size":28,"color":g.GOLD})
func reward(xp: int,embers: int,flasks: int=0) -> void:
	if reward_time<=0:rewards={"xp":0,"ember":0,"flasks":0}
	rewards.xp+=xp;rewards.ember+=embers;rewards.flasks+=flasks;reward_time=4.5
func draw_ui() -> void:
	if g.mode=="upgrade" and level_time>0 and not reduced():
		g.draw_rect(Rect2(54,31,755,77),Color(g.GOLD,0.25+0.3*(sin(g.pulse*5)+1)/2),false,2)
	if reward_time<=0 or g.mode not in ["play","fight","upgrade","floor"]:return
	var at=Vector2(720,691) if g.mode in ["play","fight","floor"] else Vector2(60,112)
	if g.mode in ["play","fight","floor"]:g.panel(Rect2(at,Vector2(490,40)))
	g.text(at+Vector2(10,27),"RECENT",18,g.INK)
	for i in range(3):
		var amount=int(rewards[["xp","ember","flasks"][i]])
		if amount==0:continue
		var pos=at+Vector2(76+i*135,7);g.ui_icon(["book","ember","potion"][i],pos,24)
		g.text(pos+Vector2(32,21),"+%d %s"%[amount,["XP","Ember","flask"][i]],20,g.GOLD)

func damage_text(event: Dictionary) -> String:
	if event.get("poison_tick",false):return "P −%.1f"%float(event.damage)
	if event.damage==0:return "EVADE" if event.get("evaded",false) else "PHASE" if event.get("enemy_evade",false) else "BLOCK"
	return "−%.0f"%float(event.damage) if event.crit or float(event.damage)>=100 else "−%.1f"%float(event.damage)
