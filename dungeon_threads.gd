extends RefCounted
## Optional lock/key dependencies never change the mandatory room graph.
var g
const RUNE_NAMES={"fire":"Flame","ice":"Moon","poison":"Ivy"}
const INFUSIONS={"fire":"Fire","ice":"Ice","acid":"Acid","poison":"Poison","focus":"Critical chance","ruin":"Critical damage","veil":"Evasion","blood":"Vampirism"}
func _init(game):g=game
func distances_from(start: Vector2i) -> Dictionary:
	var found={start:0};var queue=[start]
	while not queue.is_empty():
		var current=queue.pop_front()
		for next in g.links[current]:
			if found.has(next) or g.is_water_link(current,next):continue
			found[next]=found[current]+1;queue.append(next)
	return found
func reachable(data: Dictionary) -> Dictionary:
	var seen={Vector2i(6,5):true};var queue=[Vector2i(6,5)];var bounds: Rect2i=data.bounds
	while not queue.is_empty():
		var p=queue.pop_front()
		for d in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
			var q=p+d
			if q.x<=bounds.position.x or q.x>=bounds.end.x-1 or q.y<=bounds.position.y or q.y>=bounds.end.y-1 or data.walls.has(q) or seen.has(q):continue
			if data.entities.get(q,{}).get("kind","") in ["water","crack","chest","reliquary"]:continue
			seen[q]=true;queue.append(q)
	return seen
func place(coord: Vector2i,entity: Dictionary) -> Vector2i:
	var data=g.rooms[coord];var candidates=[];var open=reachable(data)
	var reserved=data.get("chest_path",[]).duplicate()
	reserved.append(data.get("chest_approach",Vector2i(-1,-1)));reserved.append(data.special)
	for tile in open:
		if tile.x==6 or tile.y==5 or tile in reserved or data.entities.has(tile):continue
		candidates.append(tile)
	while not candidates.is_empty():
		var tile=candidates.pop_at(g.rng.randi_range(0,candidates.size()-1))
		data.entities[tile]=entity
		if entity.kind=="reliquary":
			var still_open=reachable(data);var safe=true
			for other in data.entities:
				if data.entities[other].kind in ["dungeon_key","brazier","hammer","boots","iron","fountain","salvage","shrine"] and not still_open.has(other):safe=false
			if g.run_rules>=4:
				for neighbor in g.links[coord]:
					var direction=neighbor-coord;var b: Rect2i=data.bounds
					var landing=Vector2i(b.position.x+1,5) if direction==Vector2i.LEFT else (Vector2i(b.end.x-2,5) if direction==Vector2i.RIGHT else (Vector2i(6,b.position.y+1) if direction==Vector2i.UP else Vector2i(6,b.end.y-2)))
					if not still_open.has(landing):safe=false
			if not safe:data.entities.erase(tile);continue
		return tile
	return Vector2i(-1,-1)
func generate_classic() -> void:
	g.floor_keys={};g.floor_flags={"sun":false,"moon":false}
	g.recall_charges=1 if g.ember_tree.rank("recall")>0 else 0
	g.rerolls_left=g.ember_tree.rank("relic_lens")
	g.iron_bonus_claimed=false
	if g.run_rules<3:return
	var from_start=distances_from(Vector2i.ZERO)
	var lock_room=Vector2i(-1,-1);var best=100
	for coord in g.rooms:
		if coord in [Vector2i.ZERO,g.boss_room] or g.roles[coord]=="Fountain":continue
		if from_start[coord]<best:best=from_start[coord];lock_room=coord
	var from_lock=distances_from(lock_room)
	var key_room=Vector2i(-1,-1);best=-1
	for coord in g.rooms:
		if coord in [Vector2i.ZERO,lock_room,g.boss_room]:continue
		if from_lock[coord]>best:best=from_lock[coord];key_room=coord
	var key_tile=place(key_room,{"kind":"dungeon_key","id":"copper","lock_room":lock_room})
	assert(key_tile.x>=0,"No reachable key location")
	var chest=g.rooms[lock_room].entities[g.rooms[lock_room].chest]
	chest["key_id"]="copper"
	g.floor_flags["lock_room"]=lock_room;g.floor_flags["key_room"]=key_room
	for coord in g.rooms:
		if g.roles[coord]=="Fountain":g.rooms[coord].entities[g.rooms[coord].chest]["seal"]="sun_moon"
	place(g.hammer_room,{"kind":"brazier","rune":"sun"})
	for coord in g.rooms:
		if g.roles[coord]=="Forge":place(coord,{"kind":"brazier","rune":"moon"})
		if g.roles[coord]=="Armory":
			var order=["fire","ice","poison"]
			for i in range(2,0,-1):
				var j=g.rng.randi_range(0,i);var value=order[i];order[i]=order[j];order[j]=value
			var rewards=[g.make_gear("weapon",g.loot_level(g.floor_number,1),1,[g.Gear.AFFIXES[g.rng.randi_range(0,g.Gear.AFFIXES.size()-1)]],["balanced","dagger","greatblade","ember"][g.rng.randi_range(0,3)]),g.make_gear("armor",g.loot_level(g.floor_number,1),1,["health"]),g.make_gear("amulet",g.loot_level(g.floor_number,1),1,["crit_chance"])]
			place(coord,{"kind":"reliquary","order":order,"progress":0,"solved":false,"used":false,"rewards":rewards})
func generate() -> void:
	generate_classic()
	if g.run_rules<4:return
	var pool=["key","seal","runes","curse"]
	for i in range(pool.size()-1,0,-1):
		var j=g.rng.randi_range(0,i);var value=pool[i];pool[i]=pool[j];pool[j]=value
	var chosen=pool.slice(0,2)
	g.floor_flags["encounters"]=chosen
	for coord in g.rooms:
		var data=g.rooms[coord]
		for tile in data.entities.keys():
			var e=data.entities[tile]
			if (e.kind=="dungeon_key" and "key" not in chosen) or (e.kind=="brazier" and "seal" not in chosen) or (e.kind=="reliquary" and "runes" not in chosen):data.entities.erase(tile);continue
			if e.kind=="chest":
				if "key" not in chosen:e.erase("key_id")
				if "seal" not in chosen:e.erase("seal")
			if e.kind=="reliquary" and g.ember_tree.rank("runic_sight")>0:
				e.rewards[2]=g.make_gear("amulet",g.loot_level(g.floor_number,1),2,["crit_chance","health"])
	if "key" not in chosen:g.floor_flags.erase("lock_room");g.floor_flags.erase("key_room")
	if "curse" in chosen:
		var candidates=[]
		for coord in g.rooms:
			if coord in [Vector2i.ZERO,g.boss_room]:continue
			var chest=g.rooms[coord].entities[g.rooms[coord].chest]
			if not chest.has("key_id") and not chest.has("seal"):candidates.append(coord)
		var coord=candidates[g.rng.randi_range(0,candidates.size()-1)]
		var chest=g.rooms[coord].entities[g.rooms[coord].chest]
		chest["cursed"]=true;chest["paid"]=false
		chest.tier=2
		var rolled=g.chest_item(2,false,str(chest.item.slot) if g.run_rules>=12 else "")
		chest.item=g.make_gear(chest.item.slot,rolled.level,rolled.rarity,rolled.affixes,chest.item.get("archetype","balanced"))
		if g.run_rules>=14 and chest.item.slot=="weapon" and chest.item.archetype in ["axe","greatblade"] and chest.item.rarity>=1 and g.rng.randf()<0.60:
			chest.item["heavy_form"]="colossus";chest.item.name="Colossus "+("axe" if chest.item.archetype=="axe" else "greatblade")
func draw_curse() -> void:
	g.front_end.overlay(Rect2(205,160,870,540))
	g.text(Vector2(250,215),"THE BLOODBOUND CHEST",30,g.GOLD)
	g.draw_wrapped("Open this chest for 8 HP or 4 embers. Your max HP stays the same. You must have more than 8 HP to pay with health.",Vector2(250,270),770,23,g.INK,5)
	g.button(Rect2(250,460,770,54),"Pay 8 HP / open chest","curse_blood",false,g.hp>8)
	g.button(Rect2(250,530,770,54),"Pay 4 run embers / open chest","curse_embers",false,g.shards>=4)
	g.button(Rect2(250,600,770,54),"Leave untouched","curse_leave")
func chest_requirements(chest: Dictionary) -> String:
	var needs=[]
	if chest.get("cursed",false) and not chest.get("paid",false):needs.append("Bloodbound: choose 8 current HP or 4 run embers")
	if chest.has("key_id") and not g.floor_keys.has(chest.key_id):needs.append("Copper key was traded for supplies" if g.floor_flags.get("copper_spent","")=="supplies" else "Copper key from a distant chamber")
	if chest.get("seal","")=="sun_moon" and not (g.floor_flags.get("sun",false) and g.floor_flags.get("moon",false)):needs.append("Light Sun, then Moon, in separate rooms")
	return "; ".join(needs)
func touch(tile: Vector2i,entity: Dictionary) -> bool:
	match entity.kind:
		"dungeon_key":
			g.floor_keys[entity.id]=true
			g.rooms[g.room].entities.erase(tile)
			g.animate_move(tile);g.sfx("pickup")
			g.log_line("Copper key found. Open the chest in chamber %s, or trade it at the supply stash."%g.room_number(entity.lock_room))
		"brazier":
			g.animate_move(tile)
			if g.floor_flags.get(entity.rune,false):
				g.log_line("Already lit. The Fountain chest in chamber %s is unlocked."%g.fountain_chamber() if g.floor_flags.get("moon",false) else "SUN is already lit. Light MOON in the Forge to unlock the Fountain chest.")
				return true
			if entity.rune=="sun":g.floor_flags.sun=true;g.log_line("1/2: SUN lit. Light MOON in the Forge next. Both unlock the Fountain chest in chamber %s."%g.fountain_chamber())
			elif g.floor_flags.get("sun",false):g.floor_flags.moon=true;g.log_line("2/2: MOON lit. The Fountain chest in chamber %s is unlocked!"%g.fountain_chamber())
			else:g.log_line("MOON is second. Light the SUN candle first, then return. Reward: the Fountain chest.")
			g.sfx("blessing")
		"reliquary":
			if entity.used:g.animate_move(tile);g.log_line("This reliquary has already given its treasure.");return true
			if g.run_rules<4 and g.ember_tree.rank("runic_sight")==0:g.log_line("Sealed reliquary: learn Runic Sight in the Ember Tree between runs.");return true
			g.puzzle_tile=tile;g.mode="vault_reward" if entity.solved else "runes"
		_:return false
	return true
func recall() -> void:
	if g.mode not in ["play","character"] or g.recall_charges<=0:return
	g.recall_charges-=1;g.room=Vector2i.ZERO;g.pos=Vector2i(2,5);g.render_pos=Vector2(g.pos)
	if g.movement:g.movement.kill()
	g.mode="play";g.sfx("door");g.log_line("Recall returns you to the entrance. Recharges on the next floor.")
func handle(id: String) -> bool:
	if id=="curse_leave" and g.mode=="curse":g.mode="play";return true
	if id in ["curse_blood","curse_embers"] and g.mode=="curse":
		var chest=g.rooms[g.room].entities.get(g.puzzle_tile,{})
		if not chest.get("cursed",false) or chest.get("paid",false):return true
		if id=="curse_blood":
			if g.hp<=8:return true
			g.hp-=8;g.summary.taken+=8
		else:
			if g.shards<4:return true
			g.shards-=4
		chest.paid=true;g.mode="play";g.open_chest(g.puzzle_tile);return true
	if id=="recall":recall();return true
	if id=="relic_reroll" and g.mode=="relic":
		if g.rerolls_left>0 and g.choice_ui.can_reroll():g.rerolls_left-=1;g.offer_relic(g.choices.duplicate());g.sfx("relic")
		return true
	if id=="infuse_open" and g.mode=="equipment":
		if can_infuse():g.mode="infuse"
		return true
	if id=="infuse_back":g.mode="equipment";return true
	if id.begins_with("infuse:") and g.mode=="infuse":
		var element=id.get_slice(":",1)
		if INFUSIONS.has(element) and can_infuse(element):
			g.inventory[g.selected_item]["infusion"]=element
			if g.run_rules>=9 and element in ["fire","ice","acid","poison"] and not g.floor_flags.get("free_imprint_used",false):g.floor_flags["free_imprint_used"]=true
			else:g.iron-=1;g.shards-=4
			g.recalculate_stats();g.mode="equipment";g.log_line("Inscribed "+INFUSIONS[element]+" onto selected gear.");g.sfx("blessing")
		return true
	if id=="runes_leave" and g.mode in ["runes","vault_reward"]:g.mode="play";return true
	if id.begins_with("rune:") and g.mode=="runes":
		var vault=g.rooms[g.room].entities[g.puzzle_tile]
		if id.get_slice(":",1)==vault.order[vault.progress]:vault.progress+=1;g.sfx("blessing")
		else:vault.progress=0;g.log_line("The runes fall silent. Read the inscription and try again.");g.sfx("error")
		if vault.progress==3:
			vault.solved=true;g.mode="vault_reward"
			if g.run_rules>=5:g.run_metrics.runes+=1
			g.mastery.add("runes_solved",1)
		return true
	if id.begins_with("vault_pick:") and g.mode=="vault_reward":
		var index=int(id.get_slice(":",1));var vault=g.rooms[g.room].entities[g.puzzle_tile]
		if not vault.solved or vault.used or index<0 or index>=3:return true
		if g.run_rules>=20:
			vault.used=true;g.log_line(g.smithy.reward(vault.rewards[index]));g.smithy.cargo().ore+=3 if g.ember_tree.rank("runic_sight")>0 else 0;g.shards+=6;g.summary.chests+=1;g.mode="play";g.sfx("pickup");return true
		vault.used=true;g.inventory.append(vault.rewards[index].duplicate(true));g.last_loot_index=g.inventory.size()-1;g.last_chest_tier=1;g.shards+=6;g.summary.chests+=1;g.mode="loot";g.loot_window.start();g.sfx("pickup")
		return true
	return false
func can_infuse(element: String="") -> bool:
	if g.run_rules>=20:return false
	if g.run_rules>=9 and g.near_forge() and g.selected_item>=0 and g.selected_item<g.inventory.size() and not g.floor_flags.get("free_imprint_used",false) and element in ["","fire","ice","acid","poison"]:return true
	return g.ember_tree.rank("runeforge")>0 and g.near_forge() and g.iron>=1 and g.shards>=4 and g.selected_item>=0 and g.selected_item<g.inventory.size()
func draw_puzzle() -> void:
	g.front_end.overlay(Rect2(180,125,920,580))
	var vault=g.rooms[g.room].entities[g.puzzle_tile]
	g.text(Vector2(230,185),"THE SEALED RELIQUARY",32,g.GOLD)
	var order=vault.order
	g.draw_wrapped("Order: %s before %s. %s after %s. Choose all 3 symbols."%[RUNE_NAMES[order[0]],RUNE_NAMES[order[1]],RUNE_NAMES[order[2]],RUNE_NAMES[order[1]]],Vector2(230,250),800,24,g.INK,5)
	if g.run_rules>=4 and g.ember_tree.rank("runic_sight")>0:g.text(Vector2(230,355),"Runic Sight: begin with "+RUNE_NAMES[order[0]],21,g.TEAL)
	g.text(Vector2(230,390),"Glyphs awakened: %d / 3"%vault.progress,22,g.TEAL)
	var i=0
	for rune in RUNE_NAMES:
		var at=Vector2(230+i*280,440)
		g.button(Rect2(at,Vector2(240,88)),"","rune:"+rune)
		g.text(at+Vector2(76,38),RUNE_NAMES[rune],24,g.GOLD)
		g.ui_icon(rune,at+Vector2(12,10),48);i+=1
	g.button(Rect2(230,585,800,52),"Leave / return later","runes_leave")
	g.text(Vector2(230,675),"A wrong answer resets the glyphs; it never costs health.",18)
func draw_rewards() -> void:
	g.front_end.overlay(Rect2(105,70,1070,700))
	g.text(Vector2(150,125),"CHOOSE ONE RELIQUARY TREASURE",30,g.GOLD)
	var vault=g.rooms[g.room].entities[g.puzzle_tile]
	for i in range(3):
		var item=vault.rewards[i];var at=Vector2(150+i*330,175)
		g.button(Rect2(at,Vector2(310,420)),"","vault_pick:%d"%i)
		g.gear_icon(item.slot,at+Vector2(20,20),64,g.Gear.COLORS[item.rarity],item)
		g.text(at+Vector2(18,125),item.name,23,g.GOLD)
		if g.run_rules>=20:g.text(at+Vector2(18,160),"Blueprint / returns to Hearth",19,g.TEAL)
		else:
			g.text(at+Vector2(18,160),"%s / Level %d"%[g.Gear.RARITIES[item.rarity],item.level],20,g.TEAL)
			preload("res://equipment_presenter.gd").draw_item(g,item,at+Vector2(18,210),265,190)
	g.button(Rect2(150,665,970,50),"Leave / choose later","runes_leave")
func draw_infusions() -> void:
	g.front_end.overlay(Rect2(180,60,920,740))
	g.text(Vector2(230,150),"RUNE FORGE",32,g.GOLD)
	g.stat_ui.icon("iron",Vector2(650,126),24);g.text(Vector2(682,147),"Iron %d"%g.iron,20,g.TEAL)
	g.ui_icon("ember",Vector2(815,126),24);g.text(Vector2(847,147),"Embers %d"%g.shards,20,g.TEAL)
	g.draw_wrapped(("Choose one free elemental imprint per floor. Replaces the item infusion. Rune Forge unlocks extra paid infusions: 1 iron + 4 embers." if g.run_rules>=9 else "Cost: 1 iron + 4 embers. Add a bonus to this item. Replaces its old infusion. Higher item levels give a stronger bonus."),Vector2(230,205),800,22,g.INK,3)
	var i=0;var detail="fire"
	for key in INFUSIONS:
		var at=Vector2(230+(i%2)*420,285+(i/2)*82)
		g.button(Rect2(at,Vector2(380,76)),"","infuse:"+key,false,can_infuse(key))
		g.text(at+Vector2(48,28),"Frost" if key=="ice" and g.run_rules>=9 else INFUSIONS[key],20,g.GOLD if can_infuse(key) else g.INK)
		if Rect2(at,Vector2(380,76)).has_point(g.design_mouse()) or (g.menu_keyboard and g.session.focused<g.buttons.size() and g.buttons[g.session.focused].id=="infuse:"+key):detail=key
		g.ui_icon({"focus":"crit","ruin":"crit_damage","veil":"evade","blood":"vampirism"}.get(key,key),at+Vector2(12,9),24)
		var candidate=g.inventory[g.selected_item].duplicate(true);candidate["infusion"]=key
		var stat={"fire":"fire_dps","ice":"ice_slow","acid":"acid_strip","poison":"poison_weak","focus":"crit_chance","ruin":"crit_mult","veil":"evade","blood":"vampirism"}[key]
		stat=g.Gear.stat_key(stat,candidate)
		g.stat_ui.label(stat,at+Vector2(16,60),20)
		g.text(at+Vector2(48,60),(g.stat_ui.short_name(stat)+" "+preload("res://equipment_presenter.gd").value(stat,g.Gear.stats(candidate))) if can_infuse(key) else "Requires Rune Forge + cost",18,g.TEAL)
		i+=1
	var hints={"fire":"Fire: stronger hits make stronger burns. Only the strongest burn deals damage.","ice":"Frost: 5% slower attacks per stack (max 50%). At 10 stacks: freeze for 1s. Normal cooldown: 8s.","acid":"Acid: each stack removes 1 armor. After armor reaches 0, each extra stack adds 1% weapon damage (max 20%).","poison":"Poison: each stack deals 0.5 damage every 0.5s. Example: 3 stacks deal 1.5 damage every 0.5s.","focus":"Critical chance: more weapon strikes become critical hits, up to your current critical chance limit.","ruin":"Critical damage: increase how much damage your critical strikes deal.","veil":"Evade: chance to avoid an entire enemy attack. Max 50%.","blood":"Vampirism: heal from actual weapon damage. Damage over time does not trigger vampirism. Max 35%."}
	if g.run_rules>=17:
		hints["ice"]="Frost: 2.5% slower per counter. At 20: freeze 1s. At 4 power, freezing also deals damage."
		hints["acid"]="Acid removes armor, then adds physical damage. At 4 power, breaking armor causes an Acid burst."
		hints["fire"]="Fire burns over time. At 4 Fire power, repeated hits build Heat and strengthen the burn."
		hints["poison"]="Poison counters deal 0.25 damage every 0.5s. At 4 power, every 10 counters triggers a burst."
	g.draw_wrapped(hints[detail],Vector2(230,646),800,18,g.TEAL,3)
	g.button(Rect2(230,710,800,52),"Back to equipment","infuse_back")
