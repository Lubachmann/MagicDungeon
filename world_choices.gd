extends RefCounted
var g
func _init(game):g=game
func generate() -> void:
	if g.run_rules<6:return
	if g.run_rules<15:
		var target_room=Vector2i(-1,-1);var guardian=Vector2i(-1,-1)
		for coord in g.rooms:
			if coord in [Vector2i.ZERO,g.boss_room]:continue
			var data=g.rooms[coord];var chest=data.entities.get(data.chest,{})
			var guard=chest.get("guardian",Vector2i(-1,-1))
			if data.entities.get(guard,{}).get("kind","")=="enemy" and not data.entities[guard].get("gatekeeper",false):target_room=coord;guardian=guard;break
		if target_room.x>=0:
			var source=Vector2i.ZERO
			for coord in g.rooms:
				if coord not in [target_room,g.boss_room,Vector2i.ZERO]:source=coord;break
			var tile=g.dungeon_threads.place(source,{"kind":"wardstone","target_room":target_room,"guardian":guardian})
			if tile.x>=0:
				var data=g.rooms[target_room];var e=data.entities[guardian];var chest=data.entities[data.chest]
				e["ward_active"]=true;e["ward_base_mending"]=e.get("mending",false);e["ward_base_regen"]=e.get("regen",4);e["mending"]=true;e["regen"]=6+2*g.floor_number;e["ward_source"]=source;e["ward_reward_room"]=target_room;e["ward_chest"]=data.chest
				var reward=chest.item.duplicate(true);reward.rarity=2;reward.level+=1
				for affix in ["crit_chance","health"]:
					if reward.affixes.size()<2 and affix not in reward.affixes:reward.affixes.append(affix)
				chest["ward_item"]=reward;chest["ward_guardian"]=guardian
	# Choose a random reachable non-start, non-boss room for the rest site.
	if g.run_rules>=15:
		var candidates=[]
		for coord in g.dungeon_threads.distances_from(Vector2i.ZERO):
			if coord not in [Vector2i.ZERO,g.boss_room]:candidates.append(coord)
		var placed=false
		while not candidates.is_empty():
			var coord=candidates.pop_at(g.rng.randi_range(0,candidates.size()-1))
			if g.dungeon_threads.place(coord,{"kind":"rest_site","used":false}).x>=0:
				g.floor_flags["rest_room"]=coord;placed=true;break
		assert(placed,"No reachable rest site location")
	var supply_room=Vector2i.ZERO
	for coord in g.roles:
		if g.roles[coord]=="Fountain":supply_room=coord;break
	if g.floor_flags.has("key_room"):g.dungeon_threads.place(supply_room,{"kind":"provisions"})
	# A run always starts with one modest, chosen foundation; later caches remain a mastery reward.
	if g.floor_number==1 and g.run_rules<15:
		var items=[g.make_gear("weapon",1,1,["fire_dps"],"ember"),g.make_gear("weapon",1,1,["crit_chance"],"dagger")]
		if g.run_rules>=7:items=[g.make_gear("weapon",1,1,["fire_dps"],"balanced"),g.make_gear("weapon",1,1,["crit_chance"],"dagger"),g.make_gear("weapon",1,1,["crit_mult"],"axe")]
		if g.run_rules>=9:
			var rank=g.ember_tree.rank("smithcraft");items=[]
			for weapon in ["balanced","dagger","axe"]:
				var rarity=0 if rank==0 else 2 if rank>=3 else 1
				var affixes=[] if rank==0 else [{"balanced":"fire_dps","dagger":"poison_weak","axe":"acid_strip"}[weapon]]
				if rank>=3:affixes.append("crit_mult")
				var item=g.make_gear("weapon",2 if rank>=2 else 1,rarity,affixes,weapon)
				if rank==0:item["plain"]=true
				items.append(item)
		place_foundation({"kind":"build_cache","items":items,"basic":true})
	if g.floor_number==1 and g.run_rules>=9:
		var distances=g.dungeon_threads.distances_from(Vector2i.ZERO);var candidates=[]
		for coord in distances:
			if coord not in [Vector2i.ZERO,g.boss_room]:candidates.append(coord)
		candidates.sort_custom(func(a,b): return distances[a]<distances[b])
		var placed=false
		for coord in candidates:
			if g.dungeon_threads.place(coord,{"kind":"boss_preparation"}).x>=0:placed=true;break
		if not placed:place_foundation({"kind":"boss_preparation"})
	if g.run_rules>=9:
		var found=false
		for coord in g.rooms:
			for entity in g.rooms[coord].entities.values():
				if entity.kind=="salvage":found=true
		if not found:place_foundation({"kind":"salvage"})
	if g.floor_number>=2 and g.mastery.available("draft_cache"):
		var pair=["fire_dps","ice_slow"] if g.floor_number%2==0 else ["acid_strip","poison_weak"]
		var items=[g.mastery.roll_variant(g.make_gear("weapon",g.loot_level(g.floor_number,1),1,[pair[0]],"ember" if g.floor_number%2==0 else "greatblade")),g.make_gear("amulet",g.loot_level(g.floor_number,1),1,[pair[1]])]
		for coord in g.roles:
			if coord not in [Vector2i.ZERO,g.boss_room]:
				if g.dungeon_threads.place(coord,{"kind":"build_cache","items":items}).x>=0:break
func place_foundation(entity: Dictionary) -> Vector2i:
	# Always reachable from the spawn before fighting, opening chests or finding traversal tools.
	var data=g.rooms[Vector2i.ZERO];var start=Vector2i(2,5);var seen={start:true};var queue=[start];var spots=[]
	while not queue.is_empty():
		var tile=queue.pop_front()
		if tile!=start and tile.x!=6 and tile.y!=5 and not data.entities.has(tile) and tile not in data.get("chest_path",[]):spots.append(tile)
		for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var next=tile+direction
			if seen.has(next) or not data.bounds.grow(-1).has_point(next) or data.walls.has(next):continue
			if data.entities.get(next,{}).get("kind","") in ["enemy","chest","water","crack","reliquary"]:continue
			seen[next]=true;queue.append(next)
	if spots.is_empty():return Vector2i(-1,-1)
	data.entities[spots[0]]=entity
	return spots[0]
func touch(tile: Vector2i,e: Dictionary) -> bool:
	if e.kind=="rest_site":
		g.animate_move(tile)
		if e.get("used",false):g.log_line("This rest site has already been used.")
		else:g.puzzle_tile=tile;g.mode="decision"
		return true
	if e.kind in ["runesmith","rarity_altar"] and g.run_rules>=20:
		if not e.get("used",false):e.used=true;g.smithy.cargo().ore+=3;g.log_line("Old forge: +3 ore for the Hearth.")
		else:g.log_line("This forge has been searched.")
		g.animate_move(tile);return true
	if e.kind=="runesmith":
		g.animate_move(tile)
		e.kind="salvage";g.log_line("Forge nearby: press E to upgrade, imprint or scrap gear.")
		return true
	if e.kind=="wardstone":
		var data=g.rooms[e.target_room];var guard=data.entities.get(e.guardian,{})
		if guard.get("ward_active",false):g.puzzle_tile=tile;g.animate_move(tile);g.mode="decision";return true
		g.log_line("The guardian is already gone. The rune fades.");g.rooms[g.room].entities.erase(tile);g.animate_move(tile);return true
	if e.kind=="rarity_altar" and g.forge_menu.used("rarity"):g.animate_move(tile);g.log_line("Rarity upgrade already used on this floor.");return true
	if e.kind in ["provisions","build_cache","boss_preparation","rarity_altar"]:g.puzzle_tile=tile;g.animate_move(tile);g.mode="decision";return true
	return false
func record(choice: String) -> void:
	if not g.run_metrics.has("decisions"):g.run_metrics["decisions"]=[]
	if g.run_metrics.decisions.size()<32:g.run_metrics.decisions.append({"floor":g.floor_number,"choice":choice})
func enemy_defeated(enemy: Dictionary) -> void:
	if not enemy.get("ward_active",false):return
	var data=g.rooms.get(enemy.ward_reward_room,{})
	if data.is_empty():return
	var chest=data.entities.get(enemy.ward_chest,{})
	if chest.has("ward_item"):chest.item=chest.ward_item.duplicate(true);chest["ward_won"]=true;record("guardian_powered");g.log_line("Powered guardian defeated: its chest now holds a blueprint and extra ore." if g.run_rules>=20 else "Powered guardian defeated: its chest now holds Very rare gear.")
func handle(id: String) -> bool:
	if g.mode!="decision":return false
	var e=g.rooms[g.room].entities.get(g.puzzle_tile,{})
	if id=="decision_leave":g.mode="equipment" if e.get("kind","")=="salvage" else "play";return true
	if id in ["rest_heal","rest_flask","rest_train"] and e.get("kind","")=="rest_site":
		if e.get("used",false):return true
		if id=="rest_heal":
			var healed=mini(maxi(0,g.max_hp-g.hp),ceili(g.max_hp*0.4))
			if healed<=0:g.log_line("Already at full HP. Choose another reward or return later.");return true
			g.hp+=healed;g.summary.healed+=healed;g.log_line("Rested: +%d HP."%healed);g.sfx("heal")
		elif id=="rest_flask":
			g.potions+=1;g.log_line("Rest site: +1 healing flask.");g.sfx("pickup")
		else:
			g.bonus.attack+=2.0;g.recalculate_stats();g.log_line("Trained: +2 character power for this run.");g.sfx("relic")
		e["used"]=true;g.mode="play";record(id);return true
	if id in ["prepare_weaken","prepare_supply"] and e.get("kind","")=="boss_preparation":
		if id=="prepare_weaken":
			for boss in g.rooms[g.boss_room].entities.values():
				if boss.get("kind","")=="enemy" and boss.get("boss_kind","")!="":boss.armor=maxf(0,float(boss.armor)-4);boss.attack=maxf(1,float(boss.attack)-1);boss["preparation_weakened"]=true
			g.log_line("Boss weakened: -4 armor and -1 attack.")
		else:
			g.potions+=1
			if g.run_rules>=20:g.smithy.cargo().ore+=1;g.log_line("Supplies collected: +1 ore and +1 flask.")
			else:g.iron+=1;g.log_line("Supplies collected: +1 iron and +1 flask.")
		g.rooms[g.room].entities.erase(g.puzzle_tile);g.mode="play";record(id);g.sfx("pickup");return true
	if id=="ward_disable" and e.get("kind","")=="wardstone":
		var guard=g.rooms[e.target_room].entities.get(e.guardian,{})
		if guard.get("ward_active",false):guard.ward_active=false;guard.mending=guard.ward_base_mending;guard.regen=guard.ward_base_regen;record("rune_disabled")
		g.rooms[e.target_room].entities[g.rooms[e.target_room].chest]["ward_disabled"]=true
		g.rooms[g.room].entities.erase(g.puzzle_tile);g.mode="play";g.sfx("break");g.log_line("Rune disabled. The guardian loses bonus healing, but the bonus reward is lost.");return true
	if id=="provisions_buy" and e.get("kind","")=="provisions":
		if not g.floor_keys.get("copper",false):g.log_line("The Copper key was already spent." if g.floor_flags.has("copper_spent") else "Find the Copper key first.");g.sfx("error");return true
		g.floor_keys.erase("copper");g.floor_flags["copper_spent"]="supplies";g.potions+=1
		if g.run_rules>=20:g.smithy.cargo().ore+=1
		else:g.iron+=1
		g.rooms[g.room].entities.erase(g.puzzle_tile);g.mode="play";record("key_for_supplies");g.log_line("Copper key spent: +1 flask and +1 "+("ore" if g.run_rules>=20 else "iron")+". The locked chest stays closed.");g.sfx("pickup");return true
	if id.begins_with("cache_pick:") and e.get("kind","")=="build_cache":
		var index=int(id.get_slice(":",1))
		if index<0 or index>=e.items.size():return true
		if g.run_rules>=20:
			var reward=g.smithy.reward(e.items[index]);g.rooms[g.room].entities.erase(g.puzzle_tile);g.mode="play";g.log_line(reward);record("cache_"+str(index));g.sfx("relic");return true
		g.inventory.append(e.items[index].duplicate(true));g.last_loot_index=g.inventory.size()-1;g.last_chest_tier=1;g.rooms[g.room].entities.erase(g.puzzle_tile);g.mode="loot";g.loot_window.start();record("cache_"+str(index));g.sfx("relic");return true
	return false
func draw() -> void:
	var e=g.rooms[g.room].entities[g.puzzle_tile];g.front_end.overlay(Rect2(170,95,940,650))
	if e.kind=="wardstone":
		g.ui_icon("brazier",Vector2(210,135),48);g.text(Vector2(280,176),"HEALING OR BETTER LOOT?",30,g.GOLD)
		g.draw_wrapped("This rune heals the treasure guardian in room %s. Disable it to make that fight easier."%g.room_number(e.target_room),Vector2(210,250),850,24,g.INK,3)
		g.draw_wrapped(("Leave it active and beat the guardian to earn a blueprint and 3 extra ore." if g.run_rules>=20 else "Leave it active and beat the guardian to earn Very rare gear with +1 item level."),Vector2(210,370),850,24,g.GOLD,3)
		g.button(Rect2(210,510,850,80),"Disable healing / give up the bonus loot","ward_disable")
	elif e.kind=="rest_site":
		g.draw_rest_icon(Vector2(210,135),48);g.text(Vector2(280,176),"REST SITE",30,g.GOLD)
		g.draw_wrapped("Choose one reward for this floor, or leave and return later.",Vector2(210,235),850,23,g.INK,2)
		var capacity=ceili(g.max_hp*0.4);var restored=mini(capacity,maxi(0,g.max_hp-g.hp))
		g.front_end.icon_button(Rect2(210,305,850,72),"health","REST  /  Restore %d of %d HP"%[restored,capacity],"rest_heal",false,restored>0)
		g.front_end.icon_button(Rect2(210,395,850,72),"potion","PREPARE  /  +1 healing flask","rest_flask")
		g.front_end.icon_button(Rect2(210,485,850,72),"stat_attack","TRAIN  /  +2 character power","rest_train")
	elif e.kind=="boss_preparation":
		g.ui_icon("brazier",Vector2(210,135),48);g.text(Vector2(280,176),"PREPARE FOR THE BOSS",30,g.GOLD)
		g.draw_wrapped("Choose one way to prepare for the first-floor boss. You can return later before deciding.",Vector2(210,245),850,24,g.INK,3)
		g.button(Rect2(210,345,850,75),"Weaken boss: -4 armor and -1 attack","prepare_weaken")
		g.front_end.icon_button(Rect2(210,455,850,75),"iron",("Take supplies: +1 ore and +1 flask" if g.run_rules>=20 else "Take supplies: +1 iron and +1 flask"),"prepare_supply")
	elif e.kind=="provisions":
		g.ui_icon("key",Vector2(210,135),48);g.text(Vector2(280,176),"SUPPLIES OR TREASURE?",30,g.GOLD)
		g.draw_wrapped("Spend this floor's Copper key here for supplies, or save it for the locked treasure chest. You cannot open both.",Vector2(210,240),850,23,g.INK,3)
		g.ui_icon("potion",Vector2(290,355),64);g.text(Vector2(375,400),"1 healing flask",27,g.GOLD)
		g.ui_icon("iron",Vector2(690,355),64);g.text(Vector2(775,400),"1 ore" if g.run_rules>=20 else "1 iron",27,g.GOLD)
		g.button(Rect2(210,510,850,80),"Spend Copper key" if g.floor_keys.get("copper",false) else ("Copper key already spent" if g.floor_flags.has("copper_spent") else "Find the Copper key first"),"provisions_buy")
	else:
		g.text(Vector2(210,164),"CHOOSE A STARTER WEAPON" if e.get("basic",false) else "CHOOSE YOUR BUILD REWARD",30,g.GOLD)
		for i in range(e.items.size()):
			var item=e.items[i];var width=280 if e.items.size()==3 else 410;var at=Vector2(210+i*(width+15),205);g.button(Rect2(at,Vector2(width,400)),"","cache_pick:"+str(i))
			g.gear_icon(item.slot,at+Vector2(20,20),64,g.Gear.COLORS[item.rarity],item);g.text(at+Vector2(20,103),item.name,24,g.GOLD)
			g.text(at+Vector2(20,140),"Blueprint" if g.run_rules>=20 else "%s / Level %d"%[g.Gear.RARITIES[item.rarity],item.level],20,g.TEAL)
			if g.run_rules>=20:
				g.text(at+Vector2(20,185),"Blueprint / returns to Hearth",18,g.TEAL);continue
			var stats=g.choice_ui.display_stats(item);var y=185
			for key in stats:
				g.stat_ui.label("base_interval" if key=="speed" else key,at+Vector2(20,y),24);g.text(at+Vector2(50,y),g.stat_ui.short_name("base_interval" if key=="speed" else key),16,g.INK);g.text(at+Vector2(165,y),g.choice_ui.inline_stat(key,stats[key],item).trim_prefix("Every ") if key=="speed" else preload("res://equipment_presenter.gd").value(key,stats),22,g.INK);y+=29
			if g.run_rules>=7 and item.slot=="weapon":g.stat_ui.scaling(item,at+Vector2(20,y+10),width-40)
			if item.get("plain",false):g.text(at+Vector2(20,y+54),"Plain / no innate ability",18,g.INK)
	g.front_end.icon_button(Rect2(210,640,850,60),"boots","Leave powered" if e.kind=="wardstone" else "Leave / decide later","decision_leave")
func inspect(e: Dictionary) -> bool:
	if e.kind=="rarity_altar":
		g.panel(Rect2(972,210,260,470));g.text(Vector2(988,250),"RARITY ALTAR",22,g.GOLD)
		g.draw_wrapped("Used." if e.get("used",false) else "Raise one item's rarity and choose a new bonus. Costs 1 or 2 iron; once per altar.",Vector2(988,300),225,20,g.INK,10);return true
	if e.kind=="runesmith":
		g.panel(Rect2(972,210,260,470));g.text(Vector2(988,250),"OLD FORGE",22,g.GOLD)
		g.draw_wrapped("Step here to use the forge.",Vector2(988,300),225,20,g.INK,3);return true
	if e.kind not in ["wardstone","provisions","build_cache","boss_preparation","rest_site"]:return false
	g.panel(Rect2(972,210,260,470))
	g.text(Vector2(988,250),{"wardstone":"HEALING RUNE","provisions":"SUPPLY STASH","build_cache":"BUILD CACHE","boss_preparation":"BOSS PREPARATION","rest_site":"REST SITE"}[e.kind],22,g.GOLD)
	var text="Choose one blueprint. Unchosen options are lost." if g.run_rules>=20 else "Step here to choose one item. Unchosen items are lost. Your weapon can be changed later."
	if e.kind=="rest_site":text="Already used on this floor." if e.get("used",false) else "Choose one: restore 40% max HP, gain 1 flask, or gain 2 character power. Leave and return whenever you want."
	if e.kind=="wardstone":text=("Heals a guardian in room %s. Disable it, or defeat the powered guardian for extra ore." if g.run_rules>=20 else "Heals a guardian in room %s. Disable it, or defeat the powered guardian for Very rare gear and +1 item level.")%g.room_number(e.target_room)
	if e.kind=="boss_preparation":text="Choose to weaken the first-floor boss or take 1 "+("ore" if g.run_rules>=20 else "iron")+" and 1 flask."
	if e.kind=="provisions":text="Trade the Copper key for 1 flask + 1 "+("ore" if g.run_rules>=20 else "iron")+". This uses the same key as the locked chest."
	g.draw_wrapped(text,Vector2(988,300),225,20,g.INK,12);return true
