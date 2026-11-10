extends RefCounted
## Seeded variety, optional difficulty, collections and exact per-run rewards.
var g
var draft={"mode":"standard","vows":{}}
var selected=""
var goal_source_page=0
var expedition_details_open=false
var demo_next=false
const VOWS={
	"iron":["Ironclad","armor",3,"+2 enemy armor per rank."],
	"fury":["Fury","attack",3,"+8% enemy attack per rank."],
	"ambush":["Ambush","speed",1,"Enemy specials start on the first strike."],
	"hexed":["Hexed","poison",1,"Enemy specials reduce your next 3 attacks by 25%."],
	"restless":["Restless","health",1,"Enemies heal 3 times. Each heal restores 4 HP; Ash bosses restore 4 extra HP."],
	"famine":["Famine","potion",1,"Flasks and fountains heal 25% less."]}
const AFFIXES={"siphon":["Leeching","health","Enemy hits heal it for 2 HP."],"frenzied":["Frenzied","speed","Every 2nd attack is a special."],"warded":["Cinder ward","fire","Blocks the first burn damage."],"stubborn":["Deathless","vault","Returns once at 20% health."],"venomous":["Hexfang","poison","First hit reduces your next 3 attacks by 25%."],"regenerator":["Mending","potion","Heals 4 HP every 3s, up to 3 times."]}
const BOUNTIES={"slayer":["Slayer","attack",10,30],"delver":["Delver","key",6,30],"runes":["Runesmith","vault",1,25],"arcanist":["Arcanist","fire",2,25],"quartermaster":["Quartermaster","armor",5,25],"breaker":["Armorbreaker","acid",1,20],"tactician":["Skirmisher","speed",3,20],"wardens":["Warden hunter","sun",2,50]}
var codex_from="title"
var codex_page=0
var codex_list_page=0
var codex_found_only=false
var codex_search=""
var codex_search_active=false
var codex_keyboard=false
func _init(game):g=game
static func new_career() -> Dictionary:return {"guided_done":false,"runs":0,"wins":0,"deaths":0,"best_floor":0,"best_threat":0,"bestiary":{},"relics":{},"gear":{},"bounties":0,"history":[],"daily":{},"tiers":[],"mastery":preload("res://build_mastery.gd").empty_progress(),"sanctuary":preload("res://sanctuary.gd").empty(),"workshop":preload("res://smithy.gd").empty()}
static func clean_career(data) -> Dictionary:
	var result=new_career()
	if data is Dictionary:
		for key in result:
			if data.has(key):
				if result[key] is int and (data[key] is int or data[key] is float):result[key]=maxi(0,int(data[key]))
				elif typeof(data[key])==typeof(result[key]):result[key]=data[key]
	if data is Dictionary and not data.is_empty() and not data.has("sanctuary"):
		result.sanctuary=preload("res://sanctuary.gd").migrate_old(data)
	var sanctuary=preload("res://sanctuary.gd").empty()
	for key in sanctuary:
		if result.sanctuary.has(key) and typeof(result.sanctuary[key])==typeof(sanctuary[key]):sanctuary[key]=result.sanctuary[key]
	result.sanctuary=sanctuary
	var progress=preload("res://build_mastery.gd").empty_progress()
	for key in progress:
		var value=result.mastery.get(key,0)
		progress[key]=clampi(int(value),0,1000000000) if value is int or value is float else 0
	result.mastery=progress
	return result
func reset_draft() -> void:draft={"mode":"standard","vows":{}}
func threat(settings: Dictionary={}) -> int:
	var value=g.run_settings if settings.is_empty() else settings
	var total=0
	for id in VOWS:total+=clampi(int(value.get("vows",{}).get(id,0)),0,VOWS[id][2])
	return total
func vow(id: String) -> int:return int(g.run_settings.get("vows",{}).get(id,0)) if g.run_rules>=5 else 0
func daily_seed(date: String="") -> int:
	var day=Time.get_date_string_from_system(true) if date=="" else date
	return int(("MagicDungeon-05-"+day).hash()) & 0x7fffffff
func configure_run() -> void:
	g.run_settings=draft.duplicate(true)
	if demo_next:g.run_settings={"mode":"standard","vows":{}}
	if g.run_settings.mode=="daily":g.run_settings={"mode":"daily","vows":{},"date":Time.get_date_string_from_system(true)}
	if g.run_settings.mode=="daily":g.run_skills={};g.rng.seed=daily_seed();g.run_seed=daily_seed()
	demo_next=false
	g.run_bounties={};g.run_recorded=false;g.run_metrics={"bosses":0,"runes":0,"breaks":0,"started_from":g.mode}
func start_bounties() -> void:
	if g.run_rules<5:return
	var pool=BOUNTIES.keys()
	for i in range(3):g.run_bounties[pool.pop_at(g.rng.randi_range(0,pool.size()-1))]=false
func modify_enemy(enemy: Dictionary,depth: int) -> void:
	if g.run_rules<5:return
	if g.run_settings.get("mode","")=="endless" and g.floor_number>5:
		enemy.hp=ceili(enemy.hp*pow(1.10,mini(100,g.floor_number-5)));enemy.max=enemy.hp;enemy.attack=ceili(enemy.attack*pow(1.03,mini(100,g.floor_number-5)))
	enemy.armor+=2*vow("iron");enemy.attack=ceili(enemy.attack*(1.0+0.08*vow("fury")))
	enemy["ambush"]=vow("ambush")>0;enemy["hexed"]=vow("hexed")>0
	if vow("restless")>0:enemy["mending"]=true
	if enemy.type!=3 and depth>0 and g.rng.randf()<minf(0.4,0.16+0.025*g.floor_number):
		var ids=AFFIXES.keys();var affix=ids[g.rng.randi_range(0,ids.size()-1)];enemy["affix"]=affix
		if affix=="regenerator":enemy["mending"]=true
func odds(tier: int) -> Array:
	var base=g.CHEST_ODDS[tier]
	if g.run_rules<5:return base.duplicate()
	var very=minf(95,float(base[2])+(1.0 if g.run_rules>=11 else 0.5)*g.ember_tree.rank("gilded_touch"))
	var common=maxf(0,float(base[0])-(3.0 if g.run_rules>=11 else 1.5)*g.ember_tree.rank("treasure_hunter")-(1.0 if g.run_rules>=11 else 0.5)*g.ember_tree.rank("gilded_touch"))
	return [common,100.0-common-very,very]
func bank_reward(amount: int) -> int:
	if g.run_rules<5:return amount
	return floori(amount*(1.0+0.02*g.ember_tree.rank("embercraft"))*(1.0+0.08*threat()))
func observe() -> void:
	if g.run_rules<5 or (g.session and not g.session.active):return
	for id in g.relics:g.career.relics[id]=true
	for item in g.inventory:
		g.career.gear[item.slot+":"+str(item.rarity)+":"+item.get("archetype","balanced")]=true
	if g.mode not in ["play","fight","relic","loot","equipment","upgrade","floor","runes","vault_reward","curse"]:return
	var element_relics=0
	for id in g.relics:
		if id in ["cinder","frost","solvent","venom","wildfire","shatter","bulwark","contagion","steamglass","corrosive_flame","black_ice","toxic_spark"]:element_relics+=1
	var values={"slayer":g.kills,"delver":g.summary.chests,"runes":g.run_metrics.get("runes",0),"arcanist":element_relics,"quartermaster":g.equipped.size(),"breaker":g.run_metrics.get("breaks",0),"tactician":int(g.summary.get("evades",0))+int(g.summary.get("interrupts",0)),"wardens":g.run_metrics.get("bosses",0)}
	for id in g.run_bounties:
		if not g.run_bounties[id] and values[id]>=BOUNTIES[id][2]:
			g.run_bounties[id]=true;g.shards+=BOUNTIES[id][3];g.career.bounties+=1;g.log_line("Bounty: "+BOUNTIES[id][0]+" +%d embers"%BOUNTIES[id][3]);g.sfx("relic")
func enemy_defeated(enemy: Dictionary) -> void:
	if g.run_rules<5:return
	if enemy.has("family"):g.career.bestiary["family:"+enemy.family]=int(g.career.bestiary.get("family:"+enemy.family,0))+1
	if enemy.has("signature"):g.career.bestiary["boss:"+enemy.signature]=int(g.career.bestiary.get("boss:"+enemy.signature,0))+1
	var id=str(enemy.type)+":"+enemy.get("affix","")
	g.career.bestiary[id]=int(g.career.bestiary.get(id,0))+1
	if enemy.type==3:g.run_metrics.bosses+=1;g.career.best_floor=maxi(int(g.career.best_floor),g.floor_number)
	if g.ember_tree.rank("supply_cache")>0 and g.rng.randf()<0.02*g.ember_tree.rank("supply_cache"):g.potions+=1;g.log_line("Forager: a healing flask found.")
func record(won: bool) -> void:
	if g.run_recorded:return
	observe();g.run_recorded=true;g.career.runs+=1
	if won and not g.demo_run:g.career.wins+=1
	elif not won and not g.run_metrics.get("extracted",false):g.career.deaths+=1
	g.career.best_floor=maxi(int(g.career.best_floor),g.floor_number)
	if won and not g.demo_run and g.run_settings.mode!="daily":
		g.career.best_threat=maxi(int(g.career.best_threat),threat())
		if threat()>0 and threat() not in g.career.tiers:g.career.tiers.append(threat());g.shards+=50;g.log_line("First clear at Threat %d: +50 embers."%threat())
	var report={"seed":g.run_seed,"mode":g.run_settings.mode,"floor":g.floor_number,"won":won,"threat":threat(),"time":int(g.summary.time),"level":g.character_level,"kills":g.kills,"tree_ranks":g.run_skills.duplicate(true),"metrics":g.run_metrics.duplicate(true),"build":"0.16.0","rules":g.run_rules,"exact_forecasts":bool(g.session.preferences.exact_forecasts),"death_reason":g.death_reason if not won else "","damage_dealt":g.summary.dealt,"damage_taken":g.summary.taken}
	report["equipment"]=equipment_report();report["relics"]=g.relics.duplicate();report["elements"]=g.elements.duplicate();report["vows"]=g.run_settings.get("vows",{}).duplicate()
	g.career.history.push_front(report)
	if g.career.history.size()>12:g.career.history.resize(12)
	if g.run_settings.mode=="daily":
		var date=g.run_settings.get("date","");var score=g.kills*10+g.summary.chests*15+(500 if won else 0)+g.floor_number*50
		g.career.daily[date]=maxi(int(g.career.daily.get(date,0)),score)
func can_reforge() -> bool:return g.run_rules>=5 and g.ember_tree.rank("transmutation")>0 and g.near_forge() and g.iron>=2 and g.shards>=8 and g.selected_item>=0 and g.selected_item<g.inventory.size() and g.inventory[g.selected_item].rarity>0
func handle(id: String) -> bool:
	if id=="expedition" and g.mode=="title":g.mode="expedition";return true
	if id=="expedition_back" and g.mode=="expedition":
		if expedition_details_open:expedition_details_open=false
		else:g.mode="title"
		return true
	if id=="expedition_details" and g.mode=="expedition":expedition_details_open=true;g.session.focused=0;return true
	if id=="expedition_details_back" and g.mode=="expedition":expedition_details_open=false;g.session.focused=0;return true
	if id=="expedition_goal_source" and g.mode=="expedition":goal_source_page+=1;return true
	if id=="expedition_start" and g.mode=="expedition":
		g.demo_run=false
		g.loadout_menu.open("expedition")
		return true
	if id.begins_with("run_mode:") and g.mode=="expedition":
		var value=id.get_slice(":",1)
		if value=="endless" and int(g.career.wins)==0:g.ui_help.show("endless");return true
		if value in ["standard","daily"] or (value=="endless" and int(g.career.wins)>0):
			draft.mode=value
			if value=="daily":draft.vows={}
		return true
	if id.begins_with("vow:") and g.mode=="expedition":
		var key=id.get_slice(":",1)
		if int(g.career.wins)==0:g.ui_help.show("vows");return true
		if draft.mode=="daily":g.ui_help.show("daily_vows");return true
		if VOWS.has(key) and int(g.career.wins)>0 and draft.mode!="daily":draft.vows[key]=(int(draft.vows.get(key,0))+1)%(VOWS[key][2]+1)
		selected=key;return true
	if id=="reforge" and g.mode=="equipment":
		if can_reforge():
			var item=g.inventory[g.selected_item];var pool=g.Gear.AFFIXES.duplicate();var previous=item.affixes.duplicate();var fresh=[]
			# Pick a new first affix when possible; no free preview or save reroll.
			for affix in previous:pool.erase(affix)
			for i in range(int(item.rarity)):fresh.append(pool.pop_at(g.rng.randi_range(0,pool.size()-1)))
			item.affixes=fresh;g.iron-=2;g.shards-=8;g.recalculate_stats();g.log_line("Bonus stats changed. Level and rarity stay the same.");g.sfx("equip")
		return true
	if id=="codex" and g.mode in ["title","character"]:codex_from=g.mode;g.mode="codex";codex_page=0;codex_list_page=0;selected="";return true
	if id=="build_unlocks" and g.mode in ["title","character","expedition"]:codex_from=g.mode;g.mode="codex";codex_page=3;return true
	if id=="codex_back" and g.mode=="codex":
		if codex_keyboard:codex_keyboard=false
		else:codex_search_active=false;g.mode=codex_from
		return true
	if id=="codex_keyboard" and g.mode=="codex":codex_search_active=false;codex_keyboard=true;g.session.focused=0;return true
	if id=="codex_keyboard_done" and g.mode=="codex":codex_keyboard=false;g.session.focused=0;return true
	if id.begins_with("codex_key:") and g.mode=="codex" and codex_keyboard:
		var key=id.trim_prefix("codex_key:")
		if key=="back":codex_search=codex_search.left(maxi(0,codex_search.length()-1))
		elif codex_search.length()<24:codex_search+=(" " if key=="space" else key)
		codex_list_page=0;return true
	if id=="codex_search" and g.mode=="codex":codex_search_active=true;return true
	if id=="codex_search_clear" and g.mode=="codex":codex_search="";codex_search_active=false;codex_list_page=0;return true
	if id=="codex_filter" and g.mode=="codex":codex_found_only=not codex_found_only;codex_list_page=0;selected="";return true
	if id.begins_with("codex:") and g.mode=="codex":selected=id.get_slice(":",1);return true
	if id=="codex_next" and g.mode=="codex":codex_page=(codex_page+1)%4;codex_list_page=0;selected="";codex_search_active=false;codex_search="";return true
	if id=="codex_list_prev" and g.mode=="codex":codex_list_page=maxi(0,codex_list_page-1);return true
	if id=="codex_list_next" and g.mode=="codex":codex_list_page+=1;return true
	return false
func draw_expedition_details() -> void:
	g.front_end.menu_backdrop();g.panel(Rect2(180,95,920,640))
	g.text(Vector2(220,150),"EXPEDITION RULES",30,g.GOLD)
	var description={"standard":"Five floors. Take materials and discoveries home on death, extraction or victory.","daily":"Fixed sword, empty Ember Tree and no vows. Score and banked embers persist; materials and blueprints do not.","endless":"Continue beyond floor five. Take materials and discoveries home when you return."}.get(str(draft.mode),"")
	g.draw_wrapped(description,Vector2(220,195),830,20,g.INK,3)
	g.text(Vector2(220,280),"SELECTED VOWS / THREAT %d"%threat(draft),20,g.GOLD)
	var i=0
	for id in VOWS:
		var rank=int(draft.vows.get(id,0))
		if rank<=0:continue
		var at=Vector2(220+(i%2)*425,310+int(i/2)*100);g.ui_icon(VOWS[id][1],at,32)
		g.text(at+Vector2(42,20),VOWS[id][0]+" / Rank %d"%rank,18,g.GOLD)
		g.draw_wrapped(VOWS[id][3],at+Vector2(42,45),355,17,g.INK,2);i+=1
	if i==0:g.text(Vector2(220,340),"No vows selected.",20,g.TEAL)
	g.text(Vector2(220,655),"Banked embers: +%d%% from Threat."%(8*threat(draft)),18,g.TEAL)
	g.button(Rect2(220,680,300,42),"Back","expedition_details_back")
func draw_setup() -> void:
	if expedition_details_open:draw_expedition_details();return
	g.front_end.menu_backdrop();g.text(Vector2(75,82),"EXPEDITION",36,g.GOLD)
	var modes=["standard","daily","endless"]
	for i in range(3):
		var at=Vector2(75+i*395,125);var id=modes[i]
		g.front_end.icon_button(Rect2(at,Vector2(370,110)),["attack","sun","vault"][i],(["Dungeon","Daily","Endless"][i]+(" / Locked" if id=="endless" and int(g.career.wins)==0 else "")),"run_mode:"+id,draft.mode==id,true)
		g.text(at+Vector2(72,91),["Keep rewards on return","Fixed loadout / no materials kept","Beyond floor 5 / keep rewards"][i],15,g.TEAL)
	g.button(Rect2(530,246,250,40),"Mode / vow details","expedition_details")
	g.text(Vector2(75,280),"VOWS",24,g.GOLD)
	g.text(Vector2(850,280),"THREAT %d / +%d%%"%[threat(draft),8*threat(draft)],23,g.TEAL)
	var i=0
	for id in VOWS:
		var value=VOWS[id];var at=Vector2(75+(i%3)*395,320+(i/3)*125)
		g.front_end.icon_button(Rect2(at,Vector2(370,100)),value[1],value[0]+(" / Locked" if int(g.career.wins)==0 or draft.mode=="daily" else "  %d/%d"%[int(draft.vows.get(id,0)),value[2]]),"vow:"+id,false,true)
		g.draw_wrapped(value[3],at+Vector2(75,85),280,15,g.TEAL,1);i+=1
	var hint="Clear the dungeon to unlock Vows and Endless."
	if draft.mode=="daily":hint="UTC %s / empty tree / best score %d"%[Time.get_date_string_from_system(true),int(g.career.daily.get(Time.get_date_string_from_system(true),0))]
	elif selected in VOWS:hint=VOWS[selected][3]
	elif int(g.career.wins)>0:hint="Optional Vows change the rules. +8% banked embers per Threat."
	g.draw_wrapped(hint,Vector2(75,615),1120,22,g.INK,2)
	var goal=g.smithy.goal_info()
	if not goal.is_empty():
		g.text(Vector2(75,659),"TRACKING: "+goal.title+"  /  "+("Completed" if goal.finished else "Ready at the Smithy" if goal.ready else "Find blueprint and materials" if goal.get("blueprint_missing",false) else "Materials needed"),18,g.TEAL)
		if not goal.finished and not goal.ready:g.smithy.draw_materials(goal.entries,Vector2(75,667),200,18)
		if not goal.sources.is_empty():
			goal_source_page=posmod(goal_source_page,goal.sources.size())
			g.draw_wrapped("Find: "+goal.sources[goal_source_page],Vector2(75,709),510,16,g.INK,1)
			if goal.sources.size()>1:g.button(Rect2(600,686,165,34),"Source %d/%d"%[goal_source_page+1,goal.sources.size()],"expedition_goal_source")
	g.front_end.icon_button(Rect2(75,730,260,60),"boots","Back","expedition_back")
	g.front_end.icon_button(Rect2(360,730,370,60),"relic","Build unlocks","build_unlocks")
	g.front_end.icon_button(Rect2(800,710,360,80),"attack","Choose equipment","expedition_start")
func relic_icon(id: String) -> String:
	if id=="heavy_momentum":return "attack"
	if id=="quickdraw":return "speed"
	if id=="combustion":return "fire"
	if id=="toxic_harvest":return "poison"
	if id=="exposed_core":return "acid"
	if id=="frost_shatter":return "ice"
	if id=="breakthrough":return "attack"
	if id in ["glacial_crusher","frozen_precision","toxic_glacier"]:return "ice"
	if id in ["venom_edge","blood_harvest"]:return "poison"
	if id in ["caustic_burn","ashen_charge"]:return "fire"
	if id=="shieldbreaker":return "attack"
	if id=="warded_blade":return "armor"
	if id in ["cinder","wildfire","corrosive_flame","toxic_spark"]:return "fire"
	if id in ["frost","shatter","steamglass","black_ice"]:return "ice"
	if id in ["solvent","bulwark"]:return "acid"
	if id in ["venom","contagion"]:return "poison"
	if id=="ruin":return "crit_damage"
	if id in ["precision","critical_horizon","unbound_aim"]:return "crit"
	return {"needle":"attack","bloom":"health","spark":"fire","leech":"health","ward":"armor","haste":"speed"}.get(id,"relic")
func draw_codex_keyboard() -> void:
	g.front_end.menu_backdrop();g.panel(Rect2(200,100,880,630))
	g.text(Vector2(240,155),"SEARCH THE CHRONICLE",30,g.GOLD)
	g.text(Vector2(240,207),"Search: "+codex_search,22,g.TEAL)
	var letters="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	for i in range(letters.length()):
		var at=Vector2(240+(i%8)*95,240+int(i/8)*75)
		g.button(Rect2(at,Vector2(80,60)),letters.substr(i,1),"codex_key:"+letters.substr(i,1))
	g.button(Rect2(240,560,245,55),"Space","codex_key:space")
	g.button(Rect2(505,560,245,55),"Backspace","codex_key:back")
	g.button(Rect2(770,560,245,55),"Done","codex_keyboard_done")
	g.text(Vector2(240,680),"Select letters with the D-pad; B closes the keyboard.",18,g.INK)
func draw_codex() -> void:
	if codex_keyboard:draw_codex_keyboard();return
	if codex_page==3:g.mastery.draw();return
	g.front_end.menu_backdrop();g.text(Vector2(75,82),"CHRONICLE",36,g.GOLD)
	g.text(Vector2(75,119),"%d runs / %d clears / best floor %d / threat %d"%[g.career.runs,g.career.wins,g.career.best_floor,g.career.best_threat],20,g.TEAL)
	g.front_end.icon_button(Rect2(840,45,350,60),"book",["Bestiary","Runs","Build unlocks"][codex_page],"codex_next")
	if codex_page==2:
		for i in range(g.career.history.size()):
			var report=g.career.history[i];var at=Vector2(75,180+i*40)
			g.ui_icon("sun" if report.won else "moon",at-Vector2(0,20),24)
			g.text(at+Vector2(40,0),"%s / F%d / Lv%d / %dm / Threat %d / Seed %d"%[str(report.mode).capitalize(),report.floor,report.level,int(report.time/60),report.threat,report.seed],20)
		if g.career.history.is_empty():g.text(Vector2(75,220),"Your expeditions will be remembered here.",24,g.TEAL)
		g.front_end.icon_button(Rect2(75,730,250,60),"boots","Back","codex_back");return
	var ids=g.RELICS.keys() if codex_page==0 else AFFIXES.keys()+g.Combat.Flow.FAMILIES.keys()+g.Combat.Flow.BOSSES.keys()
	g.button(Rect2(75,128,340,34),"Search: "+codex_search+("_" if codex_search_active else ""),"codex_search")
	g.button(Rect2(430,128,130,34),"Clear","codex_search_clear")
	g.button(Rect2(575,128,185,34),"A-Z keyboard","codex_keyboard")
	g.button(Rect2(610,47,210,55),"Found only" if codex_found_only else "All entries","codex_filter")
	if codex_found_only:
		var filtered=[]
		for id in ids:
			if (g.career.relics.has(id) if codex_page==0 else has_affix(id)):filtered.append(id)
		ids=filtered
	if codex_search!="":
		var matching=[]
		for id in ids:
			var known=g.career.relics.has(id) if codex_page==0 else has_affix(id)
			var title=str(g.RELICS[id][0]) if codex_page==0 else str(creature(id)[0])
			if known and codex_search.to_lower() in title.to_lower():matching.append(id)
		ids=matching
	if ids.is_empty():g.text(Vector2(90,220),"No matching discovered entries.",20,g.TEAL)
	var pages=maxi(1,ceili(ids.size()/20.0));codex_list_page=clampi(codex_list_page,0,pages-1)
	for i in range(mini(20,ids.size()-codex_list_page*20)):
		var id=ids[codex_list_page*20+i];var at=Vector2(75+(i%5)*150,170+(i/5)*125)
		var known=g.career.relics.has(id) if codex_page==0 else has_affix(id)
		g.button(Rect2(at,Vector2(130,104)),"","codex:"+id,selected==id)
		g.ui_icon(relic_icon(id) if codex_page==0 else creature(id)[1],at+Vector2(41,12),48)
		g.text(at+Vector2(15,88),"Found" if known else "?",17,g.TEAL if known else g.INK)
	g.panel(Rect2(870,170,320,520))
	if selected!="":
		var known=g.career.relics.has(selected) if codex_page==0 else has_affix(selected)
		var entry=[g.RELICS[selected][0],g.relic_description(selected)] if codex_page==0 else [creature(selected)[0],creature(selected)[2]]
		g.text(Vector2(895,220),entry[0] if known else "Undiscovered",24,g.GOLD)
		g.draw_wrapped(entry[1] if known else ("Epic skills can appear from level 7." if g.run_rules>=11 and selected in preload("res://skill_offers.gd").EPIC else "Find it in the dungeon."),Vector2(895,275),265,22,g.INK,10)
	else:g.draw_wrapped("Discover relics and enemy variants. Select an icon.",Vector2(895,245),265,22,g.INK,5)
	g.text(Vector2(895,620),"%d gear variations"%g.career.gear.size(),18,g.TEAL)
	g.text(Vector2(895,653),"%d bounties"%g.career.bounties,18,g.TEAL)
	g.front_end.icon_button(Rect2(75,730,250,60),"boots","Back","codex_back")
	if pages>1:
		g.button(Rect2(355,730,150,60),"Previous","codex_list_prev",false,codex_list_page>0)
		g.text(Vector2(535,768),"%d / %d"%[codex_list_page+1,pages],20,g.TEAL)
		g.button(Rect2(635,730,150,60),"Next","codex_list_next",false,codex_list_page+1<pages)
func creature(id: String) -> Array:
	if id in AFFIXES:return AFFIXES[id]
	if id in g.Combat.Flow.BOSSES:return g.Combat.Flow.BOSSES[id]
	var e=g.Combat.Flow.FAMILIES[id]
	return [e.name,e.icon,e.desc]
func has_affix(id: String) -> bool:
	for key in g.career.bestiary:
		if str(key).ends_with(":"+id):return true
	return false
func bounty_progress(id: String) -> int:
	match id:
		"slayer":return g.kills
		"delver":return g.summary.chests
		"runes":return g.run_metrics.get("runes",0)
		"quartermaster":return g.equipped.size()
		"breaker":return g.run_metrics.get("breaks",0)
		"tactician":return int(g.summary.get("evades",0))+int(g.summary.get("interrupts",0))
		"wardens":return g.run_metrics.get("bosses",0)
		"arcanist":
			var total=0
			for id_relic in g.relics:
				if relic_icon(id_relic) in ["fire","ice","acid","poison"] and id_relic!="spark":total+=1
			return total
	return 0
func draw_bounty_panel() -> void:
	g.text(Vector2(158,132),"RUN BOUNTIES",28,g.GOLD)
	g.text(Vector2(158,170),"Optional goals / rewards are earned during this run",18,g.TEAL)
	var hints={"slayer":"Defeat 10 enemies","delver":"Open 6 chests","runes":"Solve a rune reliquary","arcanist":"Collect 2 elemental relics","quartermaster":"Equip all 5 slots","breaker":"Fully strip an enemy's armor","tactician":"Dodge or automatically interrupt 3 attacks","wardens":"Defeat 2 floor bosses"}
	var i=0
	for id in g.run_bounties:
		if not BOUNTIES.has(id):continue
		var at=Vector2(158+(i%3)*315,220+int(i/3)*185);g.panel(Rect2(at,Vector2(290,165)))
		g.ui_icon(BOUNTIES[id][1],at+Vector2(15,15),38);g.text(at+Vector2(65,40),BOUNTIES[id][0],20,g.GOLD)
		g.draw_wrapped(hints[id],at+Vector2(15,77),255,18,g.INK,2)
		g.text(at+Vector2(15,140),"Complete" if g.run_bounties[id] else "%d / %d  /  +%d embers"%[mini(bounty_progress(id),BOUNTIES[id][2]),BOUNTIES[id][2],BOUNTIES[id][3]],17,g.TEAL);i+=1
	if i==0:g.text(Vector2(158,250),"No bounties for this run.",20,g.INK)
	g.button(Rect2(158,680,300,48),"Back to journal","journal_bounties_back")

func equipment_report() -> Dictionary:
	var result={}
	for slot in g.equipped:
		var item=g.inventory[g.equipped[slot]].duplicate(true);item["stats"]=g.Gear.stats(item);result[slot]=item
	return result
