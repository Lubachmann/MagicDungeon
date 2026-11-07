extends Node2D
## CC0 artwork by Kenney. See ASSET_CREDITS.md for sources and licenses.
const Combat = preload("res://combat.gd")
const Gear = preload("res://equipment.gd")
const FLOOR_COUNT = 5
const TILE = 48
const ORIGIN = Vector2(328, 172)
const RW = 13
const RH = 11
var save_path = "user://progress.json"
const INK = Color("c7d7d5")
const GOLD = Color("ecc378")
const TEAL = Color("79d8c3")
var rng = RandomNumberGenerator.new()
var rooms: Dictionary = {}
var room = Vector2i.ZERO
var pos = Vector2i(2, 5)
var hp = 65
var max_hp = 65
var attack = 10
var armor = 2
var speed = 1.0
var breaker = false
var potions = 1
var shards = 0
var bank = 0
var levels = [0, 0, 0]
var visited: Dictionary = {}
var mode = "play"
var logs: Array[String] = []
var fight: Dictionary = {}
var clock = 0.0
var player_next = 0.0
var enemy_next = 0.0
var pulse = 0.0
var kills = 0
var run_seed = 0
var buttons: Array[Dictionary] = []
var textures: Dictionary = {}
var icons: Dictionary = {}
var font: FontFile
var heading_font: FontFile
var weapon_icons: Dictionary = {}
var stat_ui
var toast = ""
var toast_until=0.0
var ui_theme=0
var drawing_world=false
var map_pinned=false
var map_hover_open=false
var iron_fragments=0
var salvage_charges=3
const THEMES=["Ruined Keep","Drowned Archive","Ashen Crypt"]
var links: Dictionary = {}
var water_shortcuts: Array = []
var roles: Dictionary = {}
var distances: Dictionary = {}
var boss_room = Vector2i.ZERO
var hammer_room = Vector2i.ZERO
var passage_room = Vector2i.ZERO
var boots_room = Vector2i.ZERO
var boots = false
var relics: Array = []
var choices: Array = []
var battle: Dictionary = {}
var render_pos = Vector2.ZERO
var movement: Tween
var motes: Array = []
var flashes: Dictionary = {}
var sound: Node
var draw_scale = 1.0
var draw_offset = Vector2.ZERO
var muted = false
var elements = {"fire": 0, "ice": 0, "acid": 0, "poison": 0}
var crit_chance = 0.10
var crit_mult = 1.5
var blessings: Array = []
var floor_number = 1
var character_level = 1
var experience = 0
var pending_levels = 0
var reward_level = 1
var inventory: Array = []
var equipped: Dictionary = {}
var iron = 0
var gear_stats: Dictionary = {}
var bonus = {"attack":0.0,"armor":0.0,"speed":0.0,"crit_chance":0.0,"crit_mult":0.0}
var base_elements = {"fire":0,"ice":0,"acid":0,"poison":0}
var equipment_slot = "weapon"
var selected_item = 0
var inventory_page = 0
var floor_drop_index = 0
var gear_icons: Dictionary = {}
var ui_frames: Dictionary = {}
var last_loot_index = -1
var last_chest_tier = 0
const CHEST_NAMES = ["Weathered", "Reinforced", "Ornate"]
const CHEST_COLORS = [Color("b8a386"),Color("80bfe2"),Color("e5b86c")]
const CHEST_ODDS = [[75,23,2],[20,65,15],[0,55,45]]
const CHEST_STYLES = {"Threshold":"stash", "Hammer":"wall", "Boots":"water", "Elite":"sentinel", "Forge":"nook", "Fountain":"winding", "Armory":"guardian", "Warden":"warden"}
var completed_rooms = 0
var bombs = 1
var facing = Vector2i.RIGHT
var summary: Dictionary = {}
var session
var controls
var guided
var front_end
var session_actions
var loadout="wanderer" # Legacy save field; runs no longer select a class.
var ember_tree
var tactics
var mastery
var world_choices
var branch_paths
var sanctuary
var fight_preview
var playtest
var build_view
var inventory_tools
var bonus_transfer
var rarity_altar
var forge_menu
var combat_review
var ui_help
var loot_window
var choice_ui
var feedback
var active_ability="guard"
var toxic_echo=0.0
var dungeon_threads
var profiles
var replay
var tree_epoch=2
var tree_spent=0
var career: Dictionary={}
var run_settings: Dictionary={"mode":"standard","vows":{}}
var run_bounties: Dictionary={}
var run_metrics: Dictionary={"bosses":0,"runes":0,"breaks":0}
var run_recorded=false
var skills: Dictionary={}
var run_skills: Dictionary={}
var meta_revision=1
var inspection_tile=Vector2i(-100,-100)
var inspection_room=Vector2i(-100,-100)
var enemy_ability_open=false
var run_rules=19
var legacy_levels=[0,0,0]
var floor_keys: Dictionary={}
var floor_flags: Dictionary={}
var recall_charges=0
var rerolls_left=0
var revives_left=0
var iron_bonus_claimed=false
var puzzle_tile=Vector2i(-1,-1)
var demo_run=false
var vitality_tax=0
var death_reason=""
var tutorial_step=0
var tutorial_return="play"
var inspected_tile=Vector2i(3,5)
var menu_keyboard=false
var animation_sets: Dictionary={}
var attack_swing=0.0
const ELEMENT_COLORS = {"fire": Color("ef9c6b"), "ice": Color("85c8ed"), "acid": Color("d0de78"), "poison": Color("ad90d0")}
const UPGRADE_INFO = {
	"attack": ["Ember blade", "+5 attack", "attack"],
	"guard": ["Quick guard", "+3 armor. Attack more often; see the new interval.", "armor"],
	"fire": ["Fire infusion", "Each Fire stack deals 4 damage/s. Burns last 3s; your hits restart the timer.", "fire"],
	"ice": ["Ice infusion", "Each Ice stack makes enemy attacks 18% slower. Max 65%.", "ice"],
	"acid": ["Acid infusion", "Your hits remove 2 enemy armor each. Each Acid stack allows 4 armor to be removed per enemy.", "acid"],
	"poison": ["Poison infusion", "Each Poison stack makes enemies deal 18% less damage. Lasts the fight. Max 65%.", "poison"],
	"focus": ["Keen edge", "+20% critical chance (maximum 60%)", "crit"],
	"ferocity": ["Ruin edge", "Critical hits gain +50% of normal hit damage. Max 300% total.", "crit_damage"]
}
const RELICS = {
	"critical_horizon":["Critical horizon","+15% maximum critical chance and +3% critical chance."],
	"unbound_aim":["Unbound aim","+15% maximum critical chance and +3% critical chance. Maximum 90%."],
	"needle": ["Glass needle", "Your hits ignore 60% of enemy armor."],
	"bloom": ["Grave bloom", "+4 HP after every victory."],
	"spark": ["First spark", "+75% damage on your first hit in each fight."],
	"leech": ["Blood thread", "+2 HP every 3 attacks."],
	"ward": ["Ash ward", "Take 50% less damage from the first enemy hit."],
	"haste": ["Quick hands", "Attack interval −0.15s. Minimum 0.3s."],
	"heavy_momentum": ["Heavy momentum", "Axe or greatblade: +45% physical damage, −20% attack speed."],
	"quickdraw": ["Quickdraw", "Attack immediately at the start of each fight. Later attacks use your normal interval."],
	"cinder": ["Cinder crown", "+1 Fire stack. Burns last 2s longer. Every 3rd burn deals 50% more damage."],
	"frost": ["Frost prism", "+1 Ice stack. +20% hit power against enemies slowed by ice."],
	"solvent": ["Alchemist fang", "+1 Acid stack. Your hits remove 3 armor instead of 2."],
	"venom": ["Venom veil", "+1 Poison stack. Poison starts before the first hit."],
	"precision": ["Hawk eye", "+20% critical hit chance. Max 60%."],
	"ruin": ["Ruin prism", "Critical hits gain +50% of normal hit damage. Max 300% total."],
	"wildfire": ["Wildfire seed", "+1 Fire stack. Burning enemies explode when defeated. Damage: 8 + 4 per Fire stack. Range: 2 tiles."],
	"shatter": ["Winter bell", "+1 Ice stack. Your 3rd hit against a slowed enemy delays its next attack by 1.5s. Once per fight."],
	"bulwark": ["Vitriol shell", "+1 Acid stack. Remove all enemy armor to gain a shield. Blocks 6 damage + 2 per Acid stack. Once per fight."],
	"contagion": ["Plague vessel", "+1 Poison stack. Defeat a poisoned enemy: the next enemy deals 10% less damage."],
	"steamglass": ["Steamglass", "+1 Fire and +1 Ice stack. Critical hits gain +30% of normal hit damage against burning, slowed enemies."],
	"corrosive_flame": ["Caustic flame", "+1 Fire and +1 Acid stack. Each burn removes 1 enemy armor."],
	"black_ice": ["Black ice", "+1 Ice and +1 Poison stack. Every 3 attacks: gain 2 shield if the enemy is slowed and poisoned. Max 6 shield."],
	"toxic_spark": ["Toxic spark", "+1 Poison and +1 Fire stack. Every 3 burns: heal 1 HP if the enemy is poisoned."],
 "glacial_crusher":["Glacial crusher","Heavy weapon: +30% hit power against slowed enemies."],
 "venom_edge":["Venom edge","Dagger: +25% hit power against poisoned enemies."],
 "caustic_burn":["Corrosive embers","Burns deal +25% damage to enemies affected by Acid."],
 "frozen_precision":["Frozen precision","Critical hits against slowed enemies gain +20% normal hit damage."],
 "blood_harvest":["Blood harvest","+50% vampirism healing against poisoned enemies."],
 "shieldbreaker":["Armor crusher","Heavy weapon: +25% hit power while the enemy has armor."],
 "warded_blade":["Warded blade","Sword: +25% hit power while you have a shield."],
 "ashen_charge":["Ashen charge","Weapon hits deal +20% hit power against burning enemies."],
 "toxic_glacier":["Toxic glacier","Each Poison tick adds 0.5 Frost stacks."],
 "breakthrough":["Breakthrough","Heavy weapon: breaking armor or a guard empowers your next successful hit this fight: +75% physical damage."],
 "frost_shatter":["Frost shatter","Heavy weapon: spend 3 Frost stacks for +50% physical damage on a successful hit."],
 "combustion":["Combustion","Heavy hit at 4 Heat: consume Heat for a Fire burst equal to twice your burn damage."],
 "toxic_harvest":["Toxic harvest","Poison bursts deal double damage."],
 "exposed_core":["Exposed core","After breaking armor, physical hits deal +25% damage."]
}

func _ready() -> void:
	font=load("res://assets/fonts/PixelOperator.ttf")
	heading_font=load("res://assets/fonts/PixelOperator-Bold.ttf")
	for face in [font,heading_font]:
		face.antialiasing=TextServer.FONT_ANTIALIASING_NONE
		face.hinting=TextServer.HINTING_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for id in ["floor", "floor_dust", "floor_worn", "wall", "wall_top", "wall_cracked", "door", "stairs", "player", "mossling", "husk", "bat", "warden", "potion", "hammer", "chest", "chest_open", "blessing", "fountain", "shrine", "relic", "torch","boss_iron","boss_tide","boss_ash","forge","banner_keep","banner_archive","banner_crypt","bomb"]:
		textures[id] = load("res://assets/dark_dungeon/" + id + ".png")
	for id in ["health", "attack", "armor", "speed", "ember", "hammer", "potion", "relic", "boots","map","book","settings","salvage"]:
		icons[id] = load("res://assets/icons/" + id + ".png")
	for id in ["health","attack","speed","crit","ember","potion","relic","boots","map","book","iron","fire","ice","acid","poison","key","sun","moon","vault","brazier","bomb"]:
		icons[id]=load("res://assets/pixel_icons/"+id+".png")
	for id in ["stat_attack","stat_fire","stat_ice","stat_acid","stat_poison"]:icons[id]=load("res://assets/pixel_icons/"+id+".png")
	icons["armor"]=load("res://assets/pixel_icons/defense.png")
	for slot in Gear.SLOTS:gear_icons[slot]=load("res://assets/pixel_icons/"+slot+".png")
	weapon_icons["balanced"]=gear_icons["weapon"]
	for archetype in ["dagger","greatblade","ember","axe"]:weapon_icons[archetype]=load("res://assets/pixel_icons/weapon_"+archetype+".png")
	# Original artwork supplied by the game creator; unchanged 16×16 pixels.
	var user_ui={"armor":"armor_stat_shield","health":"health_heart","potion":"healing_flask","iron":"iron_ingot","boots":"boots","book":"book","map":"map","relic":"relic_gem","vault":"treasure_chest"}
	user_ui.merge({"attack":"attack_stat","stat_attack":"attack_stat","speed":"attack_time","crit":"critical_chance","crit_damage":"critical_damage","vampirism":"vampirism","evade":"evade","fire":"element_fire","stat_fire":"element_fire","ice":"element_ice","stat_ice":"element_ice","acid":"element_acid","stat_acid":"element_acid","poison":"element_poison","stat_poison":"element_poison"})
	for id in user_ui:icons[id]=load("res://assets/user_icons/"+user_ui[id]+".png")
	var user_gear={"weapon":"sword","shield":"shield","armor":"heavy_armor","helmet":"helmet","amulet":"amulet"}
	for slot in user_gear:gear_icons[slot]=load("res://assets/user_icons/"+user_gear[slot]+".png")
	weapon_icons["balanced"]=gear_icons.weapon
	weapon_icons["greatblade"]=load("res://assets/user_icons/greatblade.png")
	weapon_icons["axe"]=load("res://assets/user_icons/axe.png")
	gear_icons["light_armor"]=load("res://assets/user_icons/light_armor.png")
	for name in ["gothic","warm"]:ui_frames[name]=load("res://assets/dark_ui/"+name+"_frame.png")
	sound = preload("res://sound.gd").new()
	add_child(sound)
	rng.randomize()
	ember_tree=preload("res://ember_tree.gd").new(self)
	dungeon_threads=preload("res://dungeon_threads.gd").new(self)
	replay=preload("res://replay_systems.gd").new(self)
	sanctuary=preload("res://sanctuary.gd").new(self)
	profiles=preload("res://character_profiles.gd").new(self)
	stat_ui=preload("res://stat_ui.gd").new(self)
	load_progress()
	new_run()
	controls=preload("res://game_controls.gd").new(self)
	guided=preload("res://guided_tutorial.gd").new(self)
	session=preload("res://run_session.gd").new(self)
	front_end=preload("res://front_end.gd").new(self)
	session_actions=preload("res://session_actions.gd").new(self)
	# Legacy suites supply isolated res:// paths; normal players use user:// saves.
	session.enabled=save_path.begins_with("user://")
	if session.enabled:session.boot()
	get_tree().auto_accept_quit=false
	feedback=preload("res://combat_feedback.gd").new(self)
	choice_ui=preload("res://choice_ui.gd").new(self)
	ui_help=preload("res://context_help.gd").new(self)
	loot_window=preload("res://loot_window.gd").new(self)
	mastery=preload("res://build_mastery.gd").new(self)
	world_choices=preload("res://world_choices.gd").new(self)
	branch_paths=preload("res://branch_paths.gd").new(self)
	fight_preview=preload("res://fight_preview.gd").new(self)
	playtest=preload("res://playtest_report.gd").new(self)
	build_view=preload("res://build_view.gd").new(self)
	inventory_tools=preload("res://inventory_tools.gd").new(self)
	bonus_transfer=preload("res://bonus_transfer.gd").new(self)
	rarity_altar=preload("res://rarity_altar.gd").new(self)
	forge_menu=preload("res://forge_menu.gd").new(self)
	combat_review=preload("res://combat_review.gd").new(self)
	load_animations()

func load_progress() -> void:
	bank=0;skills={};levels=[0,0,0];tree_spent=0;tree_epoch=2;career=replay.new_career()
	if not FileAccess.file_exists(save_path):return
	var data=JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary:return
	bank=maxi(0,int(data.get("bank",0)))
	if int(data.get("version",0))<3:
		var old=data.get("levels",[0,0,0])
		if old is Array:bank+=ember_tree.legacy_refund(old)
		skills={}
	else:skills=ember_tree.clean(data.get("skills",{}))
	levels=[0,0,0]
	tree_spent=maxi(0,int(data.get("tree_spent",ember_tree.old_spent(skills))))
	career=replay.clean_career(data.get("career",{}))

func save_progress() -> bool:
	var file=FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if not file:return false
	file.store_string(JSON.stringify({"version":4,"bank":bank,"levels":[0,0,0],"skills":skills,"tree_epoch":2,"tree_spent":tree_spent,"career":career}))
	file.flush();var status=file.get_error();file.close()
	return status==OK and DirAccess.rename_absolute(save_path+".tmp",save_path)==OK

func new_run(seed_override: int = -1) -> void:
	var planned_demo=bool(replay.demo_next) if replay else false
	if stat_ui:stat_ui.notice_left=0;stat_ui.notice=""
	if ui_help:ui_help.topic=""
	active_ability="guard";toxic_echo=0.0
	if not tactics:tactics=preload("res://combat_tactics.gd").new(self)
	run_rules=19
	inspection_tile=Vector2i(-100,-100);inspection_room=inspection_tile;enemy_ability_open=false
	legacy_levels=[0,0,0]
	loadout="wanderer"
	run_skills=skills.duplicate(true)
	revives_left=0
	vitality_tax=0
	death_reason=""
	demo_run=planned_demo
	floor_number = 1
	character_level = 1
	experience = 0
	pending_levels = 0
	iron = 0
	iron_fragments=0
	map_pinned=false
	map_hover_open=false
	completed_rooms = 0
	if feedback:feedback.clear()
	inventory.clear()
	equipped.clear()
	# Base attack is your unarmed attack. All equipment is found during the run.
	bonus = {"attack":0.0,"armor":0.0,"speed":0.0,"crit_chance":0.0,"crit_mult":0.0}
	base_elements = {"fire":0,"ice":0,"acid":0,"poison":0}
	equipment_slot = "weapon"
	selected_item = -1
	inventory_page = 0
	rooms.clear()
	visited.clear()
	logs.clear()
	room = Vector2i.ZERO
	pos = Vector2i(2, 5)
	max_hp = 65 + levels[0] * 3
	hp = max_hp
	attack = 10.0 + levels[1] * 0.5
	armor = 2.0 + levels[2] * 0.5
	speed = 1.0
	elements = {"fire": 0, "ice": 0, "acid": 0, "poison": 0}
	crit_chance = 0.10
	crit_mult = 1.5
	blessings.clear()
	bombs = 0
	facing = Vector2i.RIGHT
	summary = {"time": 0.0, "taken": 0, "dealt": 0, "healed": 0, "flasks": 0, "bombs": 0, "crits": 0, "burn": 0, "chests":0,"abilities":0}
	breaker = false
	boots = false
	relics.clear()
	choices.clear()
	battle.clear()
	motes.clear()
	flashes.clear()
	if movement: movement.kill()
	render_pos = Vector2(pos)
	potions = 1
	shards = 0
	kills = 0
	mode = "play"
	fight.clear()
	run_seed = rng.randi_range(10000, 99999) if seed_override < 0 else seed_override
	rng.seed = run_seed
	if replay:replay.configure_run()
	if sanctuary:sanctuary.begin_run()
	revives_left=1 if ember_tree.rank("second_wind")>0 else 0
	potions=1+ember_tree.rank("flask_reserve")
	iron=ember_tree.rank("smithcraft")
	iron+=ember_tree.rank("blastcraft")
	bombs=0
	recalculate_stats()
	hp = max_hp
	generate_floor()
	if replay:replay.start_bounties()

func generate_floor() -> void:
	rooms.clear()
	visited.clear()
	floor_drop_index = 0
	salvage_charges=3
	map_pinned=false
	map_hover_open=false
	room = Vector2i.ZERO
	pos = Vector2i(2,5)
	render_pos = Vector2(pos)
	if movement: movement.kill()
	motes.clear()
	flashes.clear()
	fight.clear()
	battle.clear()
	generate_links()
	for y in range(2):
		for x in range(4): make_room(Vector2i(x,y))
	for coord in rooms: decorate_treasure(coord)
	if session and session.enabled and session.active:
		for coord in roles:
			if roles[coord]=="Fountain":
				var data=rooms[coord]
				var reserved=[data.special,data.chest,Vector2i(6,5),Vector2i(1,5),Vector2i(11,5),Vector2i(6,1),Vector2i(6,9)]
				var tile=room_spot(data.bounds,data.walls,data.entities,reserved)
				data.entities[tile]={"kind":"shrine","used":false}
	if dungeon_threads:dungeon_threads.generate()
	preload("res://room_detail.gd").fill(self)
	Combat.Flow.decorate_floor(self)
	if world_choices:world_choices.generate()
	if sanctuary:sanctuary.generate()
	if run_rules>=15 and floor_number==1:
		# Put the only starting chest on a route reachable without a fight.
		var data=rooms[Vector2i.ZERO];var old: Vector2i=data.chest
		var starting_chest=data.entities[old]
		data.entities.erase(old)
		var placement=world_choices if world_choices else preload("res://world_choices.gd").new(self)
		var placed=placement.place_foundation(starting_chest)
		if placed.x>=0:data.chest=placed
		else:data.entities[old]=starting_chest
	visited[room] = true
	mode = "play"
	if run_rules>=4:log_line(tactics.FLOORS[posmod(floor_number-1,5)][1])
	log_line("Floor %d/%d: defeat the Warden, then use the stairs."%[floor_number,FLOOR_COUNT])
	queue_redraw()


func make_room(coord: Vector2i) -> void:
	var size = Vector2i([9, 11, 13][rng.randi_range(0, 2)], [7, 9, 11][rng.randi_range(0, 2)])
	if roles[coord] in ["Threshold","Warden","Elite","Fountain"]: size = Vector2i(13, 11)
	var bounds = Rect2i(Vector2i((RW - size.x) / 2, (RH - size.y) / 2), size)
	var left = bounds.position.x
	var top = bounds.position.y
	var right = bounds.end.x - 1
	var bottom = bounds.end.y - 1
	var walls: Dictionary = {}
	var entities: Dictionary = {}
	var pattern = rng.randi_range(0,5)
	if theme_index()==0 and rng.randf()<0.35:pattern=3 if rng.randf()<0.5 else 4
	if theme_index()==1 and rng.randf()<0.35:pattern=5
	var depth = int(distances[coord])
	# A central cross joins every door; authored obstacles occupy the side chambers.
	for y in range(top + 1, bottom):
		for x in range(left + 1, right):
			if x == 6 or y == 5: continue
			if (pattern == 0 and x % 4 == 0 and y % 3 == 0) or (pattern == 1 and y in [top + 2, bottom - 2] and x in [left + 3, right - 3]) or (pattern == 2 and x in [left + 2, right - 2] and y in [top + 2, bottom - 2]): walls[Vector2i(x, y)] = true
	# Patterns 3/4 split a room into wings, with exactly one guarded passage.
	var gate = Vector2i(-1, -1)
	var horizontal_gate = false
	var right_door = coord + Vector2i.RIGHT in links[coord]
	var upper_door = coord + Vector2i.UP in links[coord]
	var guarded = coord != Vector2i.ZERO and coord != boss_room and (pattern in [3,4] or roles[coord] == "Elite" or coord == passage_room) and (right_door or upper_door or roles[coord] == "Elite")
	if guarded:
		horizontal_gate = upper_door and (not right_door or pattern == 4)
		if horizontal_gate:
			for x in range(left + 1, right): walls[Vector2i(x,4)] = true
			gate = Vector2i(6,4)
		else:
			for y in range(top + 1, bottom): walls[Vector2i(7,y)] = true
			gate = Vector2i(7,5)
		walls.erase(gate)
	elif pattern == 5:
		for p in [Vector2i(left+2,top+2), Vector2i(left+3,top+2), Vector2i(right-2,bottom-2), Vector2i(right-3,bottom-2)]:
			if p.x != 6 and p.y != 5: walls[p] = true
	# Every doorway's landing tile must stay free. Do not punch holes in partitions.
	var landings = [Vector2i(left+1,5), Vector2i(right-1,5), Vector2i(6,top+1), Vector2i(6,bottom-1)]
	var special = Vector2i(6,3) if top < 2 else Vector2i(6,5)
	var reserved: Array = landings + [Vector2i(6,5), Vector2i(6,3), special, gate, Vector2i(10,3), Vector2i(7,5)]
	if size == Vector2i(13,11):
		reserved += [Vector2i(9,1),Vector2i(10,1),Vector2i(11,1),Vector2i(10,2),Vector2i(11,2),Vector2i(2,8),Vector2i(3,8),Vector2i(4,9),Vector2i(1,9),Vector2i(2,9),Vector2i(3,9)]
	for tile in landings: walls.erase(tile)
	if roles[coord] in ["Threshold", "Hammer", "Boots", "Armory"]:
		entities[room_spot(bounds, walls, entities, reserved)] = {"kind":"potion"}
	if coord != Vector2i.ZERO:
		for i in range(1 if size.x <= 9 else 2):
			entities[room_spot(bounds, walls, entities, reserved)] = make_enemy(theme_enemy_type(), depth)
	else: entities[Vector2i(7,5)] = make_enemy(0,0)
	if roles[coord] in ["Elite", "Armory"]: entities[room_spot(bounds, walls, entities, reserved)] = {"kind":"iron"}
	if roles[coord] == "Armory": entities[room_spot(bounds,walls,entities,reserved)] = {"kind":"iron"}
	if guarded:
		var guard = make_enemy(1 if roles[coord] == "Elite" else rng.randi_range(0,2), depth, mini(6,depth+2) if run_rules>=15 else -1)
		guard.name = "Vault champion" if roles[coord]=="Elite" else "Passage sentinel"
		if roles[coord]=="Elite": guard.hp += 12; guard.max = guard.hp; guard.elite = true
		guard["gatekeeper"] = true
		entities[gate] = guard
	if coord == hammer_room: entities[special] = {"kind":"hammer" if not breaker else "potion"}
	if coord == boots_room: entities[special] = {"kind":"boots" if not boots else "potion"}
	match roles[coord]:
		"Forge":
			entities[special]={"kind":"salvage"}
			entities[room_spot(bounds,walls,entities,reserved)]={"kind":"iron"}
		"Fountain": entities[special] = {"kind":"fountain"}
		"Armory": pass
	var cache = Vector2i(-1,-1)
	var water_cache = Vector2i(-1,-1)
	if coord == boss_room:
		for y in range(2,5):
			for x in range(3,10):
				var tile = Vector2i(x,y)
				walls.erase(tile)
				entities.erase(tile)
				if y in [2,4] or x in [3,9]: walls[tile] = true
		entities[Vector2i(3,3)] = {"kind":"crack"}
		walls.erase(Vector2i(9,3))
		var guardian = make_enemy(1,depth)
		guardian.name = "Gate champion"
		guardian.hp += 25
		guardian.max = guardian.hp
		guardian.elite = true
		entities[Vector2i(9,3)] = guardian
		entities[Vector2i(6,3)] = make_enemy(3,4)
		walls.erase(Vector2i(7,2))
		entities[Vector2i(7,2)] = {"kind":"exit"}
	for tile in entities:
		if entities[tile].kind in ["hammer","boots","iron","fountain","equipment","salvage"]: walls.erase(tile)
	rooms[coord] = {"walls":walls,"entities":entities,"cleared":false,"seen_crack":false,"seen_water":false,"layout":pattern,"bounds":bounds,"gate":gate,"horizontal_gate":horizontal_gate,"cache":cache,"water_cache":water_cache,"special":special,"decor":{},"chest":Vector2i(-1,-1)}

func room_spot(bounds: Rect2i, walls: Dictionary, entities: Dictionary, reserved: Array) -> Vector2i:
	var spots: Array = []
	for y in range(bounds.position.y+1,bounds.end.y-1):
		for x in range(bounds.position.x+1,bounds.end.x-1):
			var p = Vector2i(x,y)
			if not walls.has(p) and not entities.has(p) and p not in reserved: spots.append(p)
	assert(not spots.is_empty(), "No free room tile")
	return spots[rng.randi_range(0,spots.size()-1)]

func theme_enemy_type() -> int:
	var pool=[[0,1,2],[0,1,2,2],[0,0,1,2]][theme_index()]
	return pool[rng.randi_range(0,pool.size()-1)]

func loot_level(floor: int,bonus: int=0) -> int:
	return (1+2*(maxi(1,floor)-1) if run_rules>=15 else 1+4*(maxi(1,floor)-1) if run_rules>=12 else maxi(1,floor))+bonus

func make_gear(slot: String,level: int,rarity: int,affixes: Array=[],archetype: String="balanced") -> Dictionary:
	var item=Gear.make(slot,level,rarity,affixes,archetype)
	if run_rules>=7:item["balance"]=7 if run_rules>=15 else 6 if run_rules>=12 else 5 if run_rules>=10 else 4 if run_rules>=9 else 3 if run_rules>=8 else 2
	if run_rules>=12 and slot=="amulet":
		var focus=Gear.AMULET_FOCUSES[rng.randi_range(0,Gear.AMULET_FOCUSES.size()-1)]
		item["amulet_focus"]=focus;item.name=Gear.AMULET_NAMES[focus]
	return item

func make_enemy(type: int, depth: int, forced_tier: int=-1) -> Dictionary:
	var names = ["Mire Slime", "Bone Guard", "Cave Imp", "The Warden"]
	var healths = [24, 40, 22, 100]
	var attacks = [8, 11, 7, 12]
	var armors = [1, 7, 2, 6]
	var speeds = [0.9, 0.75, 1.65, 1.05]
	var challenge=1.10 if run_rules>=3 else 1.0
	var enemy = {"kind": "enemy", "type": type, "name": names[type], "hp": ceili((healths[type] + depth * 3) * challenge * (1.0+0.30*(floor_number-1))), "max": ceili((healths[type] + depth * 3) * challenge * (1.0+0.30*(floor_number-1))), "attack": attacks[type] + depth + 2*(floor_number-1)+(1 if run_rules>=3 else 0), "armor": armors[type] + floor_number-1, "speed": speeds[type], "trait": ["none", "shield", "pierce", "heavy"][type], "elite": false, "floor":floor_number,"depth":depth,"roll_seed": rng.randi_range(1, 2147483646)}

	if type==3:
		var boss=["iron","tide","ash"][theme_index()]
		enemy["boss_kind"]=boss
		enemy.name={"iron":"Iron Castellan","tide":"Tide Regent","ash":"Ash Abbot"}[boss]
		if boss=="iron":enemy.armor+=6;enemy.trait="shield"
		elif boss=="tide":enemy.speed=1.4;enemy.trait="pierce"
		else:enemy["regen"]=4+floor_number-1
	if run_rules>=4:
		enemy["tactics"]=true
		if type==3:
			var title=["Iron Castellan","Tide Regent","Ash Abbot","The Furnace Knight","Eclipse Sovereign"][posmod(floor_number-1,5)]
			enemy.name=title
			if floor_number==1:
				enemy.hp=ceili(enemy.hp*(0.70 if run_rules>=6 else 0.75));enemy.max=enemy.hp;enemy.attack-=(5 if run_rules>=6 else 4);enemy.armor-=2
	if run_rules>=15:
		var tier=6 if type==3 else (forced_tier if forced_tier>0 else rng.randi_range(maxi(1,depth-1),mini(6,2+depth)))
		if depth==0 and forced_tier<0 and type!=3:tier=1
		enemy["level"]=1+6*(floor_number-1)+clampi(tier,1,6)-1
	if type==3 and run_rules>=6:enemy["signature"]=["castellan","tide","abbot","furnace","eclipse"][posmod(floor_number-1,5)]
	if run_rules>=7:preload("res://combat_pacing.gd").enemy(enemy,floor_number,depth,run_rules)
	if replay:replay.modify_enemy(enemy,depth)
	if run_rules>=10 and run_rules<15 and type==3 and floor_number==1:
		enemy.hp=ceili(float(enemy.hp)*0.85);enemy.max=enemy.hp;enemy.attack=maxf(1,float(enemy.attack)-1)
	if type==3:enemy.name=preload("res://enemy_roster.gd").title(enemy)
	return enemy

func log_line(message: String) -> void:
	if stat_ui:stat_ui.notify(message)
	toast=message
	toast_until=pulse+4.0
	logs.push_front(message)
	if logs.size() > 6:
		logs.resize(6)

func _unhandled_input(event: InputEvent) -> void:
	if choice_ui and (event is InputEventMouseMotion or event is InputEventMouseButton):choice_ui.pointer=screen_to_design(event.position)
	if ui_help and ui_help.input(event):queue_redraw();return
	if controls and controls.handle(event):
		if session:session.checkpoint()
		queue_redraw()
		return
	legacy_input(event)
	if session:
		session.checkpoint()
		if event is InputEventKey and event.pressed and event.keycode in [KEY_T,KEY_F11,KEY_M,KEY_MINUS,KEY_EQUAL]:session.save_preferences()

func legacy_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if mode == "bomb":
			var tile = Vector2i(((screen_to_design(event.position) - ORIGIN) / TILE).floor())
			throw_bomb(tile)
			return
		for button in buttons:
			if button.rect.has_point(screen_to_design(event.position)):
				action(button.id)
				return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if mode == "bomb" and event.keycode in [KEY_B, KEY_ESCAPE]:
		mode = "play"
		return
	if event.keycode==KEY_T:
		ui_theme=1-ui_theme
		return
	if event.keycode==KEY_F11:
		toggle_fullscreen()
		return
	if event.keycode == KEY_ESCAPE and mode not in ["equipment","floor","relic","loot","character","settings","credits"] and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		return
	if event.keycode in [KEY_MINUS, KEY_EQUAL]:
		sound.change_volume(-0.1 if event.keycode == KEY_MINUS else 0.1)
		log_line("Sound volume: %d%%" % roundi(sound.volume * 100))
		return
	if event.keycode == KEY_M:
		muted = not muted
		sound.set_muted(muted)
		log_line("Sound " + ("off" if muted else "on"))
		return
	if mode in ["character","settings","credits"]:
		if event.keycode in [KEY_C,KEY_ESCAPE]:
			if mode=="credits":mode="settings"
			else:resume_play()
		return
	if event.keycode==KEY_TAB and mode in ["play","fight"]:
		map_pinned=not map_pinned
		return
	if event.keycode==KEY_C and mode=="play":mode="character";return
	if mode=="loot":
		if event.keycode==KEY_1:action("loot_equip")
		elif event.keycode in [KEY_2,KEY_ESCAPE]:action("loot_keep")
		return
	if mode == "equipment":
		if event.keycode in [KEY_E,KEY_ESCAPE]: action("close_equipment")
		return
	if mode == "forge":
		if event.keycode in [KEY_E,KEY_ESCAPE]:action("forge_back")
		return
	if mode == "floor":
		if event.keycode == KEY_ENTER: action("ascend")
		return
	if mode == "bomb": return
	if mode == "relic":
		if choice_ui and not choice_ui.level_ready():return
		if event.keycode in [KEY_1, KEY_2, KEY_3, KEY_4]: action("relic%d" % (event.keycode - KEY_1))
		return
	if mode == "upgrade":
		if event.keycode == KEY_1: action("upgrade0")
		if event.keycode == KEY_2: action("upgrade1")
		if event.keycode == KEY_3: action("upgrade2")
		return
	if mode in ["dead", "won"]:
		if event.keycode == KEY_ENTER: action("restart")
		return
	if mode != "play": return
	if movement and movement.is_running(): return
	if event.keycode == KEY_E: action("equipment"); return
	if event.keycode == KEY_H: action("heal")
	var direction = Vector2i.ZERO
	match event.keycode:
		KEY_UP, KEY_W: direction = Vector2i.UP
		KEY_DOWN, KEY_S: direction = Vector2i.DOWN
		KEY_LEFT, KEY_A: direction = Vector2i.LEFT
		KEY_RIGHT, KEY_D: direction = Vector2i.RIGHT
	if direction != Vector2i.ZERO:
		move_player(direction)

func move_player(direction: Vector2i) -> void:
	game_move_player(direction)
	if session:session.checkpoint()

func game_move_player(direction: Vector2i) -> void:
	facing = direction
	var target = pos + direction
	var next_room = room
	var entry = target
	var bounds: Rect2i = rooms[room].bounds
	if target.x == bounds.position.x and target.y == 5: next_room.x -= 1
	elif target.x == bounds.end.x-1 and target.y == 5: next_room.x += 1
	elif target.y == bounds.position.y and target.x == 6: next_room.y -= 1
	elif target.y == bounds.end.y-1 and target.x == 6: next_room.y += 1
	if next_room != room:
		if branch_paths and branch_paths.at_entrance(room,next_room) and not rooms.has(next_room):
			branch_paths.prompt();return
		if next_room in links[room]:
			if is_water_link(room, next_room) and not boots:
				log_line("Flooded shortcut. Return with Tidewalk Boots.")
				return
			var neighbor: Rect2i = rooms[next_room].bounds
			if direction == Vector2i.LEFT: entry = Vector2i(neighbor.end.x-2,5)
			elif direction == Vector2i.RIGHT: entry = Vector2i(neighbor.position.x+1,5)
			elif direction == Vector2i.UP: entry = Vector2i(6,neighbor.end.y-2)
			else: entry = Vector2i(6,neighbor.position.y+1)
			room = next_room
			pos = entry
			render_pos = Vector2(pos)
			if movement: movement.kill()
			sfx("door")
			visited[room] = true
			log_line("Entered chamber %s." % room_number(room))
		return
	if target.x <= bounds.position.x or target.x >= bounds.end.x-1 or target.y <= bounds.position.y or target.y >= bounds.end.y-1: return
	var data = rooms[room]
	if data.entities.has(target):
		var entity = data.entities[target]
		if sanctuary and sanctuary.touch(target,entity):return
		if world_choices and world_choices.touch(target,entity):return
		if dungeon_threads and dungeon_threads.touch(target,entity):return
		match entity.kind:
			"shrine":
				animate_move(target)
				if not entity.get("used",false):mode="shrine"
				else:log_line("The shrine's bargain has been spent.")
				return
			"salvage":animate_move(target);log_line("Forge nearby: press E to upgrade, imprint or scrap gear.");return
			"chest":
				if open_chest(target): animate_move(target)
				return
			"opened_chest": animate_move(target); return
			"enemy":
				fight = entity.duplicate()
				fight["position"] = target
				battle = Combat.begin(fight, hp, max_hp, attack, armor, speed, relics, combat_build())
				if combat_review:combat_review.begin()
				toxic_echo=0.0
				clock = -0.15
				mode = "fight"
				if guided:guided.fight_started()
				run_metrics["battles"]=int(run_metrics.get("battles",0))+1
				log_line("Engaged %s. Your weapon winds up before the first hit." % fight.name)
				return
			"crack":
				data.seen_crack = true
				if not breaker:
					log_line("Sealed passage. Find the Stonebreaker Hammer.")
					return
				data.walls.erase(target)
				sfx("break")
				log_line("The cracked wall crumbles. A cache awaits.")
			"water":
				data.seen_water = true
				if not boots:
					log_line("Deep water. Find Tidewalk Boots, then return.")
					return
				animate_move(target)
				return
			"bomb": bombs += 1; sfx("pickup"); log_line("Bomb collected. B to aim; click a nearby enemy.")
			"water_cache": shards += 5; sfx("pickup"); log_line("Sunken cache: +5 embers.")
			"boots": boots = true; sfx("equip"); log_line("Tidewalk Boots! Cross water to reach sunken caches.")
			"equipment":
				inventory.append(entity.item.duplicate(true))
				log_line("Found " + Gear.title(entity.item) + ". E to equip.")
				sfx("pickup")
			"iron":
				var found_iron=1
				if ember_tree.rank("tinkering")>0 and not iron_bonus_claimed:found_iron+=1;iron_bonus_claimed=true
				iron+=found_iron
				log_line("+%d iron. Press E to upgrade equipment when ready."%found_iron)
				sfx("pickup")
			"fountain":
				var restored = mini(roundi((30+3*ember_tree.rank("wellkeeper"))*(0.75 if replay.vow("famine")>0 else 1.0)), max_hp - hp)
				hp += restored
				summary.healed += restored
				sfx("heal")
				log_line("Fountain restores %d HP. Its waters run dry." % restored)

			"urn":
				sfx("break")
				if entity.contents==0:
					var heal=mini(2,max_hp-hp);hp+=heal;summary.healed+=heal;log_line("Restorative dust: +%d HP."%heal)
				elif entity.contents==1:shards+=1;log_line("An ember inside the urn.")
				else:log_line("The old urn crumbles.")
			"potion":
				potions += 1; sfx("pickup"); log_line("Healing flask collected.")
				if guided:guided.potion_found()
			"upgrade": offer_blessing(); sfx("pickup"); log_line("Choose a blessing.")
			"hammer": breaker = true; sfx("equip"); log_line("Stonebreaker acquired! Walk into cracked walls.")
			"treasure": shards += 5; sfx("pickup"); log_line("Hidden cache: +5 embers.")
			"exit":
				if not rooms[room].cleared:
					log_line("The beacon is sealed by the Warden.")
					return
				if floor_limit()>0 and floor_number >= floor_limit():
					if sanctuary and sanctuary.active() and not demo_run:sanctuary.begin_ending()
					else:finish_run(true)
				else: mode = "floor"; sfx("victory")
				return
		data.entities.erase(target)
	if data.walls.has(target): return
	animate_move(target)

func _process(delta: float) -> void:
	if choice_ui:choice_ui.tick(delta)
	if controls:controls.tick(delta)
	if guided:guided.update()
	if mode!="fight" and hp>=max_hp:run_metrics["vamp_fraction"]=0.0
	if stat_ui:stat_ui.tick(delta)
	if mastery and mode not in ["relic","upgrade"]:mastery.tick(delta)
	pulse += delta
	if feedback:feedback.tick(delta)
	if mode in ["play","fight","bomb","inspect"]:summary.time+=delta
	attack_swing=maxf(0,attack_swing-delta)
	if is_instance_valid(sound) and sound.has_method("ambience"):
		sound.ambience(theme_index(),mode in ["pause","title"])
		var music_track="hearth" if mode in ["title","profiles","confirm_new","expedition","skills","sanctuary","dead","won","codex"] else ["dungeon","dungeon_mystic","dungeon_fire"][theme_index()]
		if mode in ["pause","settings","controls","credits"] and sound.current_music!="":music_track=sound.current_music
		sound.music(music_track)
	if session:session.tick(delta)
	for i in range(motes.size() - 1, -1, -1):
		motes[i].ttl -= delta
		motes[i].at.y -= delta * 32
		if motes[i].ttl <= 0: motes.remove_at(i)
	for tile in flashes.keys():
		flashes[tile] -= delta
		if flashes[tile] <= 0: flashes.erase(tile)
	if mode == "fight":
		battle.waiting=false
		if not feedback or feedback.hitstop<=0:clock += delta * (1.0 if run_rules>=7 else 1.25 if run_rules>=4 else 2.0)
		while not battle.done and not battle.get("waiting",false) and Combat.next_time(battle) <= clock and (not feedback or feedback.hitstop<=0):
			var hit = Combat.step(battle)
			if int(battle.hp)>=int(battle.max_hp):battle["life_fraction"]=0.0
			run_metrics["vamp_fraction"]=float(battle.get("life_fraction",0.0))
			if combat_review:combat_review.event(hit)
			if feedback:feedback.hit(hit,battle)
			if run_rules>=5 and float(battle.get("initial_armor",0))>0 and battle.acid_stacks>=float(battle.enemy.armor):run_metrics.breaks=1
			if hit.has("effect"):
				log_line(hit.effect)

			revives_left=int(battle.get("revives",0))
			if hit.get("revive",false):log_line("Second Wind restores you. No revivals remain this run.")
			if hit.regen:
				fight.hp=battle.enemy.hp
				motes.append({"at":ORIGIN+Vector2(fight.position)*TILE,"value":"MEND +%d"%hit.enemy_heal,"ttl":0.9,"color":TEAL})
				log_line("%s mends %d HP."%[fight.name,hit.enemy_heal])
				continue
			if hit.player:
				summary.dealt += hit.actual_damage
				if not hit.get("dot",hit.burn):attack_swing=0.16
			else: summary.taken += hit.actual_damage
			summary.healed += hit.heal
			if hit.crit: summary.crits += 1
			if hit.burn: summary.burn += hit.actual_damage
			if hit.get("poison_tick",false):summary["poison"]=float(summary.get("poison",0))+hit.actual_damage
			summary.burn+=float(hit.get("element_damage",0))
			hp = battle.hp
			fight.hp = battle.enemy.hp
			var target = fight.position if hit.player else pos
			flashes[target] = 0.09
			motes.append({"at": ORIGIN + Vector2(target) * TILE + Vector2(-3, -10), "value": feedback.damage_text(hit) if feedback else "−%.1f"%hit.damage, "ttl": 0.95, "size":feedback.number_size(hit) if feedback else 21,"color": Color("96cc79") if hit.get("poison_tick",false) else Color("eea36c") if hit.burn else GOLD if hit.player else Color("f28d86")})
			if hit.heal > 0:
				motes.append({"at": ORIGIN + Vector2(pos) * TILE, "value": ("VAMP +%d" % hit.heal if int(hit.get("vamp_heal",0))==int(hit.heal) else "+%d" % hit.heal), "ttl": 0.8, "color": Color("dc7b90") if int(hit.get("vamp_heal",0))>0 else TEAL})
			if hit.phase: log_line("Warden enraged: +25%% attack; interval %.2fs → %.2fs."%[choice_ui.interval(Combat.enemy_speed(battle)/1.25),choice_ui.interval(Combat.enemy_speed(battle))])
			if not feedback:sfx("block" if hit.damage == 0 else ("swing" if hit.player else "hurt"))
			log_line("%s: %.1f damage%s" % ["Poison" if hit.get("poison_tick",false) else "Burn" if hit.burn else ("Critical strike" if hit.crit else ("Your strike" if hit.player else fight.name)), hit.damage, " / +%d HP" % hit.heal if hit.heal > 0 else ""])
		if battle.done:
			if battle.won:
				if tactics:tactics.victory(fight,fight.position)
				defeat_enemy(fight.position, fight)
				animate_move(fight.position)
				resume_play()
				if replay:replay.observe()
			else:
				death_reason="%s defeated you on floor %d. %s"%[fight.name,floor_number,enemy_explanation(fight)]
				finish_run(false)
	queue_redraw()

func forecast(enemy: Dictionary) -> Dictionary:
	if mode == "bomb":
		var preview = enemy.duplicate(true)
		preview.hp = maxf(0.0, float(preview.hp) - 20.0)
		if preview.hp == 0: return {"won": true, "hp": mini(max_hp, hp + (4 if relics.has("bloom") else 0)), "loss": -(mini(max_hp, hp + 4) - hp) if relics.has("bloom") else 0}
		return Combat.predict(Combat.begin(preview, hp, max_hp, attack, armor, speed, relics, combat_build()))
	var state = battle if mode == "fight" else Combat.begin(enemy, hp, max_hp, attack, armor, speed, relics, combat_build())
	return Combat.predict(state)

func finish_run(won: bool) -> void:
	if mode in ["dead", "won"]: return
	if sanctuary:sanctuary.commit()
	if replay:replay.record(won)
	mode = "won" if won else "dead"
	sfx("victory" if won else "death")
	if won and not demo_run: shards += 10
	bank += replay.bank_reward(shards) if replay else shards
	if session:session.checkpoint()
	save_progress()

func action(id: String) -> void:
	if sanctuary and sanctuary.handle(id):
		if session:session.checkpoint()
		queue_redraw();return
	if branch_paths and branch_paths.handle(id):
		if session:session.checkpoint()
		queue_redraw();return
	if id=="guide_skip" and guided and guided.active():guided.finish(true);return
	if forge_menu and forge_menu.handle(id):return
	if rarity_altar and rarity_altar.handle(id):return
	if (build_view and build_view.handle(id)) or (inventory_tools and inventory_tools.handle(id)) or (bonus_transfer and bonus_transfer.handle(id)) or (combat_review and combat_review.handle(id)):
		if session:session.focused=0;session.checkpoint()
		queue_redraw();return
	if playtest and playtest.handle(id):return
	if world_choices and world_choices.handle(id):return
	if ui_help and ui_help.handle(id):queue_redraw();return
	if profiles and profiles.handle(id):queue_redraw();return
	if replay and replay.handle(id):
		replay.observe()
		if session:session.checkpoint()
		queue_redraw();return
	var old_mode=mode
	if dungeon_threads and dungeon_threads.handle(id):
		if replay:replay.observe()
		if session:session.checkpoint()
		queue_redraw()
		return
	if not session_actions or not session_actions.handle(id):game_action(id)
	if replay:replay.observe()
	if session:
		if mode!=old_mode:session.focused=0
		session.checkpoint()
		if id in ["toggle_theme","sound_toggle","volume_down","volume_up"]:session.save_preferences()

func game_action(id: String) -> void:
	if tactics and tactics.handle(id):return
	if id=="toggle_map" and mode in ["play","fight"]:map_pinned=not map_pinned;return
	if id=="character" and mode=="play":mode="character";return
	if id=="settings" and mode=="play":mode="settings";return
	if id=="show_credits" and mode=="settings":mode="credits";return
	if id=="close_credits" and mode=="credits":mode="settings";return
	if id=="close_menu" and mode in ["character","settings"]:resume_play();return
	if id=="toggle_theme":ui_theme=1-ui_theme;return
	if id=="sound_toggle":muted=not muted;sound.set_muted(muted);return
	if id=="volume_down":sound.change_volume(-0.1);return
	if id=="volume_up":sound.change_volume(0.1);return
	if mode=="loot":
		if id=="loot_equip":
			var item=inventory[last_loot_index]
			equipped[item.slot]=last_loot_index
			recalculate_stats();sfx("equip")
			log_line("Equipped "+item.name+".")
			resume_play()
		elif id=="loot_keep":
			log_line(inventory[last_loot_index].name+" kept in your bag. Press "+controls.label("inventory")+" to open Equipment.")
			resume_play()
		elif id=="loot_prev":loot_window.page=maxi(0,loot_window.page-1)
		elif id=="loot_next":loot_window.page+=1
		elif id=="loot_inventory":
			selected_item=last_loot_index
			open_equipment()
		return
	if id == "equipment" and mode == "play": open_equipment(); return
	if mode == "equipment":
		equipment_action(id)
		return
	if id == "ascend" and mode == "floor": ascend_floor(); return
	if id.begins_with("relic") and mode == "relic":
		var index = int(id.right(1))
		if index >= 0 and index < choices.size():
			grant_relic(choices[index])
			resume_play()
	elif id == "heal" and mode in ["play","fight"]:
		var current_hp=int(battle.hp) if mode=="fight" and not battle.is_empty() else hp
		if potions > 0 and current_hp < max_hp and (mode!="fight" or not battle.done):
			potions -= 1
			var flask_power=(33+4*(ember_tree.rank("flaskcraft")-1) if ember_tree.rank("flaskcraft")>0 else 25)+2*ember_tree.rank("field_medicine")
			var restored = mini(roundi(flask_power*(0.75 if replay.vow("famine")>0 else 1.0)), max_hp - current_hp)
			hp = current_hp + restored
			if mode=="fight":battle.hp=hp
			if hp>=max_hp:
				run_metrics["vamp_fraction"]=0.0
				if mode=="fight":battle["life_fraction"]=0.0
			summary.healed += restored
			summary.flasks += 1
			sfx("heal")
			log_line("Restored %d HP." % restored)
	elif id.begins_with("upgrade") and mode == "upgrade":
		var index = int(id.right(1))
		if index >= 0 and index < blessings.size():
			apply_blessing(blessings[index])
			sfx("blessing")
			mode = "play"
	elif id == "restart" and mode in ["dead", "won"]: sfx("click"); new_run()

func room_number(coord: Vector2i) -> String:
	if coord==Vector2i(-1,0):return "SIDE"
	return ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"][coord.y * 4 + coord.x]

func readable_size(size: int) -> int:
	return maxi(20 if session and session.preferences.large_text else 18,size)

func text_face(size: int) -> FontFile:
	return heading_font if size>=24 else font

func text(at: Vector2, value: String, size: int = 18, color: Color = INK) -> void:
	size=readable_size(size)
	draw_string(text_face(size),at.round(),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,ui_color(color))

func panel(rect: Rect2, color: Color=Color("14252c")) -> void:
	var box=StyleBoxFlat.new()
	box.bg_color=Color("24232a") if ui_theme==0 else Color("c7b298")
	box.shadow_size=0
	draw_style_box(box,rect)
	if ui_frames.is_empty():return
	var frame=StyleBoxTexture.new()
	frame.texture=ui_frames["gothic" if ui_theme==0 else "warm"]
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_BOTTOM]:frame.set_texture_margin(side,6)
	frame.set_texture_margin(SIDE_TOP,7)
	draw_style_box(frame,rect)

func style(color: Color) -> StyleBoxFlat:
	var box=StyleBoxFlat.new()
	box.bg_color=color
	return box

func button(rect: Rect2,label: String,id: String,selected: bool=false,enabled: bool=true) -> void:
	if enabled:buttons.append({"rect":rect,"id":id})
	panel(rect)
	if enabled and (selected or rect.has_point(design_mouse())):
		draw_rect(rect.grow(-5),Color(0.7,0.55,0.25,0.15))
	text(rect.position+Vector2(16,29),label,18,GOLD if enabled else Color("737078"))

func close_button(rect: Rect2,id: String) -> void:
	buttons.append({"rect":rect,"id":id})
	panel(rect)
	var hovered=rect.has_point(design_mouse())
	draw_rect(rect.grow(-4),Color("ae4549") if hovered else Color("763036"))
	draw_rect(rect.grow(-4),Color("e9867e"),false,2)
	var center=rect.get_center();var half=minf(rect.size.x,rect.size.y)*0.19
	draw_line(center-Vector2(half,half),center+Vector2(half,half),Color("fff0dc"),3.0)
	draw_line(center+Vector2(-half,half),center+Vector2(half,-half),Color("fff0dc"),3.0)

func _draw() -> void:
	var viewport_size=get_viewport_rect().size
	draw_scale=minf(viewport_size.x/1280.0,viewport_size.y/840.0)
	draw_offset=(viewport_size-Vector2(1280,840)*draw_scale)*0.5
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(Vector2.ZERO,viewport_size),Color("111116"))
	draw_set_transform(draw_offset,0.0,Vector2.ONE*draw_scale)
	buttons.clear()
	if controls and session:controls.sync_focus()
	if stat_ui:stat_ui.begin()
	if mode not in ["title","confirm_new","profiles","expedition","codex","skills"]:
		var shake=feedback.camera_offset() if feedback else Vector2.ZERO
		draw_set_transform(draw_offset+shake*draw_scale,0.0,Vector2.ONE*draw_scale)
		draw_world()
		draw_set_transform(draw_offset,0.0,Vector2.ONE*draw_scale)
		draw_hud()
	if mode not in ["play","fight","inspect","bomb"]:buttons.clear()
	if stat_ui and mode not in ["play","fight","inspect","bomb","floor"]:stat_ui.begin()
	if mode in ["inspect","bomb"]:
		draw_rect(Rect2(ORIGIN+Vector2(inspected_tile)*TILE,Vector2(TILE,TILE)).grow(-2),GOLD,false,2)
	if mode in ["play","fight","bomb","inspect"]:draw_context()
	if Rect2(1156,52,68,68).has_point(design_mouse()):map_hover_open=true
	elif not Rect2(780,120,452,400).has_point(design_mouse()):map_hover_open=false
	if mode in ["play","fight","inspect"] and (map_pinned or map_hover_open):draw_map_popup()
	if tactics:tactics.draw()
	if mode=="profiles":profiles.draw()
	elif mode=="expedition":replay.draw_setup()
	elif mode=="codex":replay.draw_codex()
	elif mode=="curse":dungeon_threads.draw_curse()
	elif mode=="branch":branch_paths.draw()
	elif mode=="sanctuary":sanctuary.draw()
	elif mode=="ending":sanctuary.draw_ending()
	elif mode=="discovery":sanctuary.draw_discovery()
	elif mode=="decision":
		if rooms[room].entities.get(puzzle_tile,{}).get("kind","") in ["rarity_altar","salvage"]:rarity_altar.draw()
		else:world_choices.draw()
	elif mode=="imprint":bonus_transfer.draw()
	elif mode=="forge":forge_menu.draw()
	elif mode=="build":build_view.draw()
	elif mode=="recap":combat_review.draw()
	elif mode=="skills":ember_tree.draw()
	elif mode=="runes":dungeon_threads.draw_puzzle()
	elif mode=="vault_reward":dungeon_threads.draw_rewards()
	elif mode=="infuse":dungeon_threads.draw_infusions()
	elif mode in ["title","confirm_new","pause","tutorial","controls","shrine"]:front_end.draw_mode()
	elif mode=="equipment":draw_equipment()
	elif mode=="character":draw_character()
	elif mode=="settings":front_end.draw_settings()
	elif mode=="credits":draw_credits()
	elif mode=="loot":draw_loot()
	elif mode=="floor":draw_floor_clear()
	elif mode=="relic":draw_relic()
	elif mode=="upgrade":draw_upgrade()
	elif mode in ["dead","won"]:draw_end()
	if menu_keyboard and session and mode not in ["play","fight","inspect","bomb"] and not buttons.is_empty():
		session.focused=clampi(session.focused,0,buttons.size()-1)
		draw_rect(buttons[session.focused].rect.grow(-3),ui_color(TEAL),false,2)
	if guided:guided.draw()
	if mastery and mode not in ["relic","upgrade"]:mastery.draw_notice()
	if feedback:feedback.draw_ui()
	if stat_ui:stat_ui.draw_notice()
	if ui_help:ui_help.draw()
	if stat_ui and (not ui_help or ui_help.topic==""):stat_ui.draw_tooltip()

func draw_world() -> void:
	drawing_world=true
	draw_rect(Rect2(ORIGIN-Vector2(10,10),Vector2(RW*TILE+20,RH*TILE+20)),Color("0b0c11"))
	var data = rooms[room]
	var bounds: Rect2i = data.bounds
	for y in range(RH):
		for x in range(RW):
			var p = Vector2i(x, y)
			var rect = Rect2(ORIGIN + Vector2(p) * TILE, Vector2(TILE, TILE))
			if not bounds.has_point(p): continue
			var edge = x == bounds.position.x or x == bounds.end.x-1 or y == bounds.position.y or y == bounds.end.y-1
			var door = (x == bounds.position.x and y == 5 and room + Vector2i.LEFT in links[room]) or (x == bounds.end.x-1 and y == 5 and room + Vector2i.RIGHT in links[room]) or (y == bounds.position.y and x == 6 and room + Vector2i.UP in links[room]) or (y == bounds.end.y-1 and x == 6 and room + Vector2i.DOWN in links[room])
			if branch_paths and branch_paths.available() and room==Vector2i.ZERO and x==bounds.position.x and y==5:door=true
			var wall = (edge and not door) or data.walls.has(p)
			var floor_id = "floor_dust" if (x * 7 + y * 11 + run_seed) % 13 == 0 else ("floor_worn" if (x + y * 3 + run_seed) % 9 == 0 else "floor")
			draw_texture_rect(textures[floor_id], rect, false, [Color("c4c1bc"),Color("85b5b1"),Color("c89985")][theme_index()])
			if wall:
				draw_texture_rect(textures["wall_top" if y==bounds.position.y else "wall"], rect, false, Color.WHITE)
			if wall and y==bounds.position.y and x%4==2 and not door:draw_texture_rect(textures[["banner_keep","banner_archive","banner_crypt"][theme_index()]],rect,false)
			if door:
				draw_texture_rect(textures["door"], rect, false, Color.WHITE)
				if room==Vector2i.ZERO and x==bounds.position.x and y==5 and branch_paths and branch_paths.available():text(rect.position+Vector2(-8,-4),"SIDE",15,GOLD)
			# Sparse floor decorations are deterministic and never affect collisions.
			if not wall and not door and not data.entities.has(p) and p != pos and (x * 17 + y * 19 + run_seed) % 59 == 0:
				draw_line(rect.position+Vector2(14,28),rect.position+Vector2(25,28),Color("514a45"),2)
			if p in data.get("atmosphere",[]) and not wall:
				var tint=[Color("ba9c6d"),Color("75bbcf"),Color("e49968"),Color("d3ab7f"),Color("b291db")][posmod(floor_number-1,5)]
				var shift=0.0 if session.preferences.reduced_flashes else sin(pulse*1.4+x+y)*2
				var at=rect.get_center()+Vector2(shift,-shift)
				if posmod(floor_number-1,5)==1:draw_line(at-Vector2(12,0),at+Vector2(12,0),Color(tint,0.4),2)
				elif posmod(floor_number-1,5)==4:draw_rect(Rect2(at-Vector2(5,5),Vector2(10,10)),Color(tint,0.45),false,2)
				else:draw_rect(Rect2(at-Vector2(2,2),Vector2(4,4)),Color(tint,0.5))
			if data.decor.has(p):
				draw_circle(rect.get_center(),2,Color("c3a16f"))
				if data.decor[p]=="lantern":draw_texture_rect(textures["torch"],rect.grow(-10),false,Color("e9b66a"))
	# Floating combat text sits above the floor but behind the character sprites.
	for mote in motes:text(mote.at,mote.value,int(mote.get("size",21)),mote.color)
	for tile in data.entities:draw_entity(ORIGIN+Vector2(tile)*TILE+Vector2(24,24),data.entities[tile])
	var center = ORIGIN + render_pos * TILE + Vector2(24, 24)
	if feedback:center+=feedback.player_offset()
	draw_ellipse_shadow(center)
	if attack_swing>0 and not (session and session.preferences.reduced_flashes) and mode=="fight":center+=(Vector2(fight.position)-Vector2(pos)).normalized()*sin(attack_swing/0.16*PI)*7
	draw_texture_rect(actor_texture("player"), Rect2(center - Vector2(24, 24), Vector2(48, 48)), false)

	if mode == "fight":
		var timer_center=center+Vector2(-19,-25)
		var player_interval=1.0/maxf(0.05,float(battle.speed))
		var player_progress=clampf(1.0-maxf(0.0,float(battle.p_time)-clock)/player_interval,0.0,1.0)
		draw_arc(timer_center,9,0,TAU,24,Color("27272e"),4.0,true)
		if player_progress>0.0:draw_arc(timer_center,9,-PI/2,-PI/2+TAU*player_progress,24,TEAL,3.0,true)
		var ec = ORIGIN + Vector2(fight.position) * TILE + Vector2(24, 24)
		draw_arc(ec, 24, 0, TAU, 32, Color("ed886d") if battle.rage else GOLD, 3)

	for tile in flashes:
		if session and session.preferences.reduced_flashes:continue
		draw_rect(Rect2(ORIGIN + Vector2(tile) * TILE, Vector2(TILE,TILE)), Color(1, 0.85, 0.65, flashes[tile] * 3))
	for tile in data.entities:
		var entity=data.entities[tile]
		if entity.kind!="enemy":continue
		var health=float(fight.hp) if mode=="fight" and tile==fight.get("position",Vector2i(-1,-1)) else float(entity.hp)
		var at=ORIGIN+Vector2(tile)*TILE+Vector2(5,43)
		draw_rect(Rect2(at-Vector2.ONE,Vector2(40,6)),Color("13131a"))
		draw_rect(Rect2(at,Vector2(38,4)),Color("49323a"))
		if feedback and feedback.bar_time>0 and tile==fight.get("position",Vector2i(-1,-1)) and mode=="fight":draw_rect(Rect2(at,Vector2(38*clampf(feedback.bar_ghost/maxf(1,entity.max),0,1),4)),Color("d5b995"))
		draw_rect(Rect2(at,Vector2(38*clampf(health/maxf(1,entity.max),0,1),4)),GOLD if entity.type==3 else Color("cd6965"))
	if mode == "bomb":
		for tile in rooms[room].entities:
			if valid_bomb_target(tile): draw_arc(ORIGIN + Vector2(tile) * TILE + Vector2(24,24), 23, 0, TAU, 24, GOLD, 3)
	if feedback:feedback.draw()
	drawing_world=false

func draw_rest_icon(at: Vector2,size: int,used: bool=false) -> void:
	var px=float(size)/12.0
	var stone=Color("555158");var wood=Color("644137");var flame=Color("e17a3b");var core=Color("ffd078")
	if used:wood=wood.darkened(0.35);flame=Color("625b55");core=Color("8c8173")
	for block in [[1,10,10,1],[2,9,8,1]]:draw_rect(Rect2(at+Vector2(block[0],block[1])*px,Vector2(block[2],block[3])*px),stone)
	for block in [[2,8,3,2],[7,8,3,2],[4,9,4,1],[3,7,2,1],[7,7,2,1]]:draw_rect(Rect2(at+Vector2(block[0],block[1])*px,Vector2(block[2],block[3])*px),wood)
	for block in [[4,3,4,5],[3,5,6,3],[5,1,2,3],[7,4,2,3]]:draw_rect(Rect2(at+Vector2(block[0],block[1])*px,Vector2(block[2],block[3])*px),flame)
	for block in [[5,5,2,3],[4,7,4,1],[6,4,1,1]]:draw_rect(Rect2(at+Vector2(block[0],block[1])*px,Vector2(block[2],block[3])*px),core)

func draw_entity(center: Vector2, entity: Dictionary) -> void:
	if entity.kind=="sanctuary_discovery":
		var id=str(entity.get("discovery",""));var info=sanctuary.DISCOVERIES.get(id,{})
		ui_icon(str(info.get("icon","relic")),center-Vector2(20,20),40)
		text(center+Vector2(-24,34),"RESCUE" if id in ["smith","cartographer"] else "LORE",15,GOLD)
		return
	if entity.kind=="rest_site":
		draw_rest_icon(center-Vector2(24,24),48,entity.get("used",false))
		text(center+Vector2(-21,34),"REST",16,Color("857971") if entity.get("used",false) else GOLD)
		return
	if entity.kind=="rarity_altar":
		draw_texture_rect(textures["shrine"],Rect2(center-Vector2(24,24),Vector2(48,48)),false,Color("d4ae6a"));ui_icon("relic",center+Vector2(7,-25),20);text(center+Vector2(-25,34),"RARITY",16,GOLD);return
	if entity.kind=="runesmith":
		draw_texture_rect(textures["shrine"],Rect2(center-Vector2(24,24),Vector2(48,48)),false,TEAL.darkened(0.4) if entity.get("used",false) else Color("9fa0d4"))
		ui_icon("hammer",center+Vector2(7,-25),20);return
	if entity.kind in ["wardstone","provisions","build_cache"]:
		draw_texture_rect(textures["shrine" if entity.kind=="wardstone" else "chest"],Rect2(center-Vector2(24,24),Vector2(48,48)),false,Color("8fc8b0") if entity.kind=="wardstone" else INK)
		ui_icon("brazier" if entity.kind=="wardstone" else ("key" if entity.kind=="provisions" else "fire"),center+Vector2(8,-25),20)
		text(center+Vector2(-22,34),{"wardstone":"RUNE","provisions":"KEY","build_cache":"CHOOSE"}[entity.kind],18,GOLD)
		return
	if entity.kind=="urn":
		draw_rect(Rect2(center+Vector2(-10,-11),Vector2(20,24)),Color("79534a"))
		draw_rect(Rect2(center+Vector2(-7,-16),Vector2(14,6)),Color("b08a63"))
		draw_rect(Rect2(center+Vector2(-10,-4),Vector2(20,4)),Color("b08a63"))
		draw_rect(Rect2(center+Vector2(4,-9),Vector2(4,19)),Color("503b3c"))
		return

	var rect = Rect2(center - Vector2(24, 24), Vector2(48, 48))
	var kind: String = entity.kind
	if kind=="boss_preparation":
		ui_icon("brazier",center-Vector2(24,24),48);text(center+Vector2(-23,34),"PREP",18,GOLD);return
	if kind=="enemy" and entity.get("ward_active",false):ui_icon("brazier",center+Vector2(-25,-25),20)
	if kind=="enemy" and mode=="fight" and feedback and center.distance_to(ORIGIN+Vector2(fight.position)*TILE+Vector2(24,24))<1:center+=feedback.enemy_offset()
	var id = {"equipment":"hammer", "iron":"armor", "bomb": "bomb", "hammer": "hammer", "potion": "potion", "upgrade": "blessing", "treasure": "chest", "water_cache": "chest", "shrine": "shrine", "fountain": "fountain", "relic": "relic", "exit": "stairs", "crack": "wall_cracked"}.get(kind, "")
	if kind in ["chest","opened_chest"]:
		var tint=CHEST_COLORS[entity.tier]
		if kind=="chest":
			draw_circle(center+Vector2(0,8),21,Color(tint,0.08+sin(pulse*2)*0.025))
			draw_texture_rect(textures["chest"],rect,false,tint)
			draw_circle(center+Vector2(0,3),2+entity.tier,tint.lightened(0.25))
			text(center+Vector2(-19,-20),["I","II","III"][entity.tier],11,tint)
		else:draw_texture_rect(textures["chest_open"],rect,false,tint.darkened(0.38))
		return
	if kind == "enemy":
		id = preload("res://enemy_roster.gd").sprite(entity)
		draw_ellipse_shadow(center)
		if entity.elite or entity.type == 3 or entity.get("gatekeeper",false): draw_arc(center, 21, 0, TAU, 24, GOLD, 2)
	elif kind == "water":
		draw_rect(rect, Color("24556b"))
		for row in range(3):
			draw_line(center + Vector2(-18, row * 12 - 12), center + Vector2(18, row * 12 - 12 + sin(pulse * 3) * 3), Color("64b4c6"), 2)
		return
	elif kind == "equipment":
		var gear_icon = {"weapon":"attack","shield":"armor","armor":"armor","helmet":"armor","amulet":"relic"}[entity.item.slot]
		ui_icon(gear_icon,center-Vector2(16,16),32,Gear.COLORS[entity.item.rarity])
		return
	elif kind in ["dungeon_key","brazier","reliquary"]:
		ui_icon({"dungeon_key":"key","brazier":"brazier","reliquary":"vault"}[kind],center-Vector2(24,24),48)
		if kind=="reliquary":text(center+Vector2(-6,-25),"R",16,GOLD)
		if kind=="brazier":
			ui_icon(entity.rune,center+Vector2(-9,-30),18)
			text(center+Vector2(-22,34),("1 " if entity.rune=="sun" else "2 ")+("LIT" if floor_flags.get(entity.rune,false) else "SUN" if entity.rune=="sun" else "MOON"),18,GOLD if floor_flags.get(entity.rune,false) else TEAL)
			if floor_flags.get(entity.rune,false):draw_circle(center+Vector2(0,-10),10,Color(1,0.7,0.3,0.25) if entity.rune=="sun" else Color(0.4,0.7,1,0.25))
		return
	elif kind=="shrine":
		draw_texture_rect(textures["shrine"],rect,false,Color("706579") if entity.get("used",false) else Color.WHITE)
		text(center+Vector2(-5,-25),"?",16,GOLD)
		return
	elif kind=="salvage":
		draw_texture_rect(textures["forge"],rect,false)
		draw_texture_rect(textures["hammer"],rect.grow(-8),false)
		text(center+Vector2(-5,-25),"S",14,GOLD)
		return
	elif kind == "potion":
		ui_icon("potion",center-Vector2(24,24),48)
		return
	elif kind == "iron":
		ui_icon("iron",center-Vector2(24,24),48)
		return
	elif kind == "bomb":
		draw_circle(center + Vector2(0, 4), 14, Color("171e29"))
		draw_arc(center + Vector2(0, 4), 14, 0, TAU, 24, GOLD, 2)
		draw_line(center + Vector2(0,-10), center + Vector2(6,-18), GOLD, 3)
		draw_circle(center + Vector2(7,-19), 3 + sin(pulse * 5), Color("ed9970"))
		return
	elif kind == "boots":
		ui_icon("boots", center - Vector2(16, 16), 32, TEAL)
		return
	if id != "":
		var tint = Combat.Flow.FAMILIES[entity.family].color if kind=="enemy" and entity.get("family","") in Combat.Flow.FAMILIES else (Color("efb5a0") if kind == "enemy" and entity.type == 3 else Color.WHITE)
		if kind == "water_cache": tint = TEAL
		if kind == "bomb": tint = Color("ed9970")
		if kind == "exit":
			draw_circle(center, 22, Color(0.4, 0.85, 0.75, 0.12 + sin(pulse * 3) * 0.05))
			tint = TEAL
		var texture=actor_texture(id)
		if kind=="enemy":
			var dimensions=texture.get_size();var fitted=dimensions*minf(rect.size.x/dimensions.x,rect.size.y/dimensions.y)
			rect=Rect2(Vector2(rect.get_center().x-fitted.x/2,rect.end.y-fitted.y),fitted)
		draw_texture_rect(texture, rect, false, tint)
	if kind == "crack":
		draw_polyline(PackedVector2Array([center + Vector2(3, -20), center + Vector2(-5, -5), center + Vector2(5, 4), center + Vector2(-6, 20)]), GOLD, 2)
	if kind=="enemy" and entity.get("family","") in Combat.Flow.FAMILIES:ui_icon(Combat.Flow.FAMILIES[entity.family].icon,center+Vector2(8,-25),16)
	if kind=="enemy" and entity.get("affix","") in replay.AFFIXES:ui_icon(replay.AFFIXES[entity.affix][1],center+Vector2(-24,-26),16)
	if kind == "enemy" and entity.trait != "none":
		panel(Rect2(center + Vector2(11, 9), Vector2(14, 16)), Color("14252c"))
		text(center + Vector2(13, 22), {"shield": "S", "pierce": "P", "heavy": "!"}[entity.trait], 12, GOLD)

func draw_ellipse_shadow(center: Vector2) -> void:
	draw_style_box(style(Color(0.03, 0.05, 0.08, 0.3)), Rect2(center + Vector2(-17, 13), Vector2(34, 9)))

func ui_icon(id: String, at: Vector2, size: int = 24, tint: Color = INK) -> void:
	draw_pixel_icon(icons[id],at,size)

func draw_upgrade() -> void:
	choice_ui.cards(true)

func draw_end() -> void:
	front_end.menu_backdrop();panel(Rect2(160,55,960,730))
	text(Vector2(210,125),"THE FLAME ENDURES" if mode=="won" and sanctuary and sanctuary.active() else "ASCENDED" if mode=="won" else "FALLEN",42,GOLD)
	var values=[str(floor_number),str(kills),"%dm %02ds"%[int(summary.time/60),int(summary.time)%60],str(replay.bank_reward(shards))]
	for i in range(4):
		var at=Vector2(210+i*220,170);panel(Rect2(at,Vector2(200,105)))
		ui_icon(["map","attack","speed","ember"][i],at+Vector2(12,12),32)
		text(at+Vector2(57,38),["Floor","Foes","Time","Earned"][i],17)
		text(at+Vector2(15,83),values[i],27,GOLD)
	for i in range(relics.size()):
		var at=Vector2(210+(i%12)*72,315+(i/12)*70)
		ui_icon(replay.relic_icon(relics[i]),at,48)
		if Rect2(at,Vector2(48,48)).has_point(design_mouse()):draw_wrapped(RELICS[relics[i]][0],Vector2(210,480),850,22,GOLD,1)
	if death_reason!="":draw_wrapped(death_reason,Vector2(210,525),850,19,Color("e1a18e"),2)
	if sanctuary and sanctuary.active() and (not run_metrics.get("sanctuary_found",[]).is_empty() or not run_metrics.get("flame_found",[]).is_empty()):text(Vector2(210,566),"Returned: %d discoveries / %d fragments"%[run_metrics.get("sanctuary_found",[]).size(),run_metrics.get("flame_found",[]).size()],18,TEAL)
	text(Vector2(210,592),"Daily best: %d"%int(career.daily.get(run_settings.get("date",""),0)) if run_settings.get("mode","")=="daily" else "Bank %d / Seed %d / %d dodges"%[bank,run_seed,summary.get("evades",0)],18,TEAL)
	front_end.icon_button(Rect2(210,635,410,65),"ember","Ember Tree","skills")
	front_end.icon_button(Rect2(650,635,420,65),"attack","Again","restart")
	front_end.icon_button(Rect2(210,720,235,44),"ember","Hearth","sanctuary")
	front_end.icon_button(Rect2(465,720,285,44),"attack","Fight recap","recap_open")
	front_end.icon_button(Rect2(770,720,300,44),"book","Your build","build_open")
func generate_links() -> void:
	links.clear()
	water_shortcuts.clear()
	roles.clear()
	distances.clear()
	for y in range(2):
		for x in range(4): links[Vector2i(x, y)] = []
	var stack = [Vector2i.ZERO]
	var seen = {Vector2i.ZERO: true}
	while not stack.is_empty():
		var current = stack.back()
		var candidates: Array = []
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var neighbor = current + d
			if links.has(neighbor) and not seen.has(neighbor): candidates.append(neighbor)
		if candidates.is_empty(): stack.pop_back(); continue
		var next = candidates[rng.randi_range(0, candidates.size() - 1)]
		connect_rooms(current, next)
		seen[next] = true
		stack.append(next)
	# One extra edge creates a loop; spanning-tree branches retain dead ends.
	var extras: Array = []
	for current in links:
		for d in [Vector2i.RIGHT, Vector2i.DOWN]:
			var neighbor = current + d
			if links.has(neighbor) and neighbor not in links[current]: extras.append([current, neighbor])
	if not extras.is_empty():
		var edge = extras.pop_at(rng.randi_range(0, extras.size() - 1))
		connect_rooms(edge[0], edge[1])
	var todo = [Vector2i.ZERO]
	distances[Vector2i.ZERO] = 0
	while not todo.is_empty():
		var current = todo.pop_front()
		for next in links[current]:
			if not distances.has(next):
				distances[next] = distances[current] + 1
				todo.append(next)
	var ordered = links.keys()
	ordered.sort_custom(func(a, b): return distances[a] < distances[b])
	hammer_room = ordered[1]
	boots_room = ordered[3]
	boss_room = ordered[7]
	roles[Vector2i.ZERO] = "Threshold"
	roles[hammer_room] = "Hammer"
	roles[boots_room] = "Boots"
	roles[boss_room] = "Warden"
	var remaining = ["Forge", "Fountain", "Elite", "Armory"]
	for coord in ordered:
		if not roles.has(coord):
			var index = rng.randi_range(0, remaining.size() - 1)
			roles[coord] = remaining.pop_at(index)

	# A second optional loop becomes a real traversal shortcut after finding boots.
	if not extras.is_empty():
		var shortcut = extras[rng.randi_range(0, extras.size() - 1)]
		connect_rooms(shortcut[0], shortcut[1])
		water_shortcuts.append(shortcut)

	if theme_index()==1:
		for coord in ordered:
			var candidate=coord+Vector2i.RIGHT
			if links.has(candidate) and candidate not in links[coord]:connect_rooms(coord,candidate);water_shortcuts.append([coord,candidate]);break
	passage_room = Vector2i.ZERO
	for coord in ordered:
		if coord not in [Vector2i.ZERO,boss_room] and (coord+Vector2i.RIGHT in links[coord] or coord+Vector2i.UP in links[coord]):
			passage_room = coord
			break

func is_water_link(a: Vector2i, b: Vector2i) -> bool:
	for edge in water_shortcuts:
		if a in edge and b in edge: return true
	return false

func connect_rooms(a: Vector2i, b: Vector2i) -> void:
	links[a].append(b)
	links[b].append(a)

func animate_move(target: Vector2i) -> void:
	pos = target
	if movement: movement.kill()
	movement = create_tween()
	movement.tween_property(self, "render_pos", Vector2(pos), 0.09).set_trans(Tween.TRANS_SINE)
	if mode != "fight": sfx("step")

func relic_pool() -> Array:
	if run_rules>=11:return preload("res://skill_offers.gd").pool(self)
	var pool=RELICS.keys()
	for id in preload("res://skill_offers.gd").NEW:pool.erase(id)
	for id in preload("res://skill_offers.gd").HEAVY_NEW:pool.erase(id)
	for id in preload("res://skill_offers.gd").SPECIALIZED:pool.erase(id)
	var totals=preload("res://build_stats.gd").calculate(self)
	if run_rules<7 or character_level<5 or totals.get("crit_raw",crit_chance)<0.35:pool.erase("critical_horizon")
	if run_rules<7 or character_level<9 or "critical_horizon" not in relics or totals.get("crit_raw",crit_chance)<0.55:pool.erase("unbound_aim")
	if run_rules<4:
		for id in ["wildfire","shatter","bulwark","contagion"]:pool.erase(id)
	if run_rules<5 or ember_tree.rank("convergence")==0:
		for id in ["steamglass","corrosive_flame","black_ice","toxic_spark"]:
			if run_rules<10 or id!="black_ice":pool.erase(id)
	return pool

func offer_relic(exclude: Array=[]) -> void:
	var fresh=mode!="relic"
	if run_rules>=11:
		choices=preload("res://skill_offers.gd").choose(self,exclude)
		if choices.is_empty():shards+=4;mode="play";log_line("All available upgrades owned. Received 4 embers instead.")
		else:
			mode="relic"
			if fresh and choice_ui:choice_ui.start_level()
		return
	var pool: Array = []
	for id in relic_pool():
		if id not in relics and id not in exclude:pool.append(id)
	if pool.size()<3:
		for id in exclude:
			if id in relic_pool() and id not in relics and id not in pool:pool.append(id)
	choices.clear()
	while choices.size() < (4 if run_rules>=5 and ember_tree.rank("insight")>0 else 3) and not pool.is_empty():
		choices.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	# Early elemental investment gets one visible synergy option, while the remaining choices vary.
	if run_rules>=10 and character_level>=3 and not choices.is_empty() and "black_ice" in pool and "black_ice" not in choices and "black_ice" not in exclude:
		var elemental=preload("res://build_stats.gd").calculate(self).element_totals
		if elemental.ice>0 or elemental.poison>0:choices[choices.size()-1]="black_ice"
	# A capped build can deliberately choose its next limit at a level-up instead of waiting on loot luck.
	if run_rules>=7 and not choices.is_empty():
		var totals=preload("res://build_stats.gd").calculate(self)
		var cap_choice="critical_horizon" if "critical_horizon" not in relics else "unbound_aim"
		if cap_choice in relic_pool() and cap_choice not in relics and cap_choice not in choices and cap_choice not in exclude and totals.crit_raw>=totals.crit_cap:choices[choices.size()-1]=cap_choice
	if choices.is_empty():
		shards += 4
		mode = "play"
		log_line("All relics owned. Received 4 embers instead.")
	else:
		mode = "relic"
		if fresh and choice_ui:choice_ui.start_level()

func relic_description(id: String) -> String:
	if run_rules>=18 and id=="haste":return "Attack interval −0.15s, to a minimum of 0.3s. This benefits faster weapons most."
	if run_rules>=18 and id=="heavy_momentum":return "Axe or greatblade: +45% physical damage and −20% attack speed. Other weapons gain nothing."
	if run_rules>=18 and id=="toxic_harvest":return "Requires 4 Poison power. Poison bursts deal double damage."
	if run_rules>=18 and id=="exposed_core":return "Requires 4 Acid power. After breaking armor, physical hits deal +25% damage."
	if run_rules>=17 and id=="frost_shatter":return "Next heavy hit after a freeze: +100% physical damage. Ends any remaining freeze and spends 10 Frost counters."
	if run_rules>=9:
		var descriptions={"cinder":"+1 Fire. Burns last 2s longer; every 3rd burn deals +50% damage.","frost":"+1 Frost. +20% hit power against slowed enemies.","solvent":"+1 Acid. Acid removes armor and then increases weapon damage.","venom":"+1 Poison. Start each fight with 2 hits of Poison stacks.","shatter":"+1 Frost. Freeze cooldown: 4s instead of 8s.","bulwark":"+1 Acid. Break armor: gain 6 shield + 2 per Acid upgrade, once per fight.","contagion":"+1 Poison. Poisoned victory: +1 Poison power next fight.","steamglass":"+1 Fire, +1 Frost. Crits vs burning + slowed: +30% normal hit damage.","corrosive_flame":"+1 Fire, +1 Acid. Each burn removes 1 armor.","black_ice":"+1 Frost, +1 Poison. Slowed + poisoned: +2 shield every 3 hits (max 6).","toxic_spark":"+1 Poison, +1 Fire. Burn poisoned enemies: +1 HP every 3 burns.","wildfire":"+1 Fire. Burning kills explode: 8 + 4 per Fire power, within 2 tiles."}
		if id in descriptions:return descriptions[id]

	if run_rules<7:return RELICS[id][1]
	return {"precision":"+8% critical chance. Your current limit is shown in Your build.","ruin":"Critical hits gain +25% of normal hit damage. Max 300% total.","haste":"+12% base attack speed. Check your new attack interval in the preview.","cinder":"+1 Fire stack. Burns last 2s longer. Every 3rd burn deals 50% more damage.","critical_horizon":"+15% maximum critical chance and +3% critical chance. Unlocks up to 75%.","unbound_aim":"+15% maximum critical chance and +3% critical chance. Unlocks up to 90%."}.get(id,RELICS[id][1])

func sfx(id: String) -> void:
	if not muted and is_instance_valid(sound): sound.play(id)

func screen_to_design(point: Vector2) -> Vector2:
	var viewport_size = get_viewport_rect().size
	var factor = minf(viewport_size.x / 1280.0, viewport_size.y / 840.0)
	return (point - (viewport_size - Vector2(1280, 840) * factor) * 0.5) / factor

func design_mouse() -> Vector2:
	if mode=="inspect" or (mode=="bomb" and menu_keyboard):return ORIGIN+Vector2(inspected_tile)*TILE+Vector2(24,24)
	return screen_to_design(get_global_mouse_position())

func toggle_fullscreen() -> void:
	var full = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
	sfx("click")

func draw_relic() -> void:
	choice_ui.cards()

func combat_build() -> Dictionary:
	var build = elements.duplicate()
	build["tactics"]=run_rules>=4
	build["elemental_specialization"]=run_rules>=17
	build["commitment_rules"]=run_rules>=18
	if run_rules>=5:
		for element in ["fire","ice","acid","poison"]:build[element+"_mastery"]=0.05*ember_tree.rank(element+"_mastery")
		build["recovery"]=ember_tree.rank("recovery")
	build["auto_flow"]=true
	build["evade"]=clampf(float(gear_stats.get("evade",0)),0.0,0.5)
	build["vampirism"]=clampf(float(gear_stats.get("vampirism",0)),0.0,0.35)
	build["impact_power"]=float(gear_stats.get("impact_power",0))
	build["life_fraction"]=float(run_metrics.get("vamp_fraction",0.0)) if hp<max_hp else 0.0
	var weapon_index=int(equipped.get("weapon",-1))
	build["weapon"]=inventory[weapon_index].get("archetype","balanced") if weapon_index>=0 and weapon_index<inventory.size() else "unarmed"
	build["weapon_archetype"]=build["weapon"]
	if run_rules>=18 and "heavy_momentum" in relics and build.weapon in ["axe","greatblade"]:build.impact_power=(1.0+float(build.impact_power))*1.45-1.0
	build["weapon_level"]=int(inventory[weapon_index].level) if weapon_index>=0 and weapon_index<inventory.size() else 1
	build["floor_rule"]=tactics.rule() if tactics else ""
	build["toxic_echo"]=toxic_echo
	build["revives"]=revives_left
	build["crit_chance"] = crit_chance
	build["crit_mult"] = crit_mult
	build["crit_cap"]=preload("res://build_stats.gd").calculate(self).get("crit_cap",0.6)
	if run_rules>=7:build["paced"]=true;build["full_opening"]=true;build["fire_stack_damage"]=2.0
	if run_rules>=9:
		build["fair_physical"]=true
		build["element_interval_scale"]=float(preload("res://combat_pacing.gd").INTERVALS.get(build.weapon,2.0))/2.0
		build["elemental_v2"]=true;build["preview_attack"]=attack;build["burn_duration"]=(5.0 if "cinder" in relics else 3.0)+(1.0 if build.floor_rule=="embers" else 0.0);build["freeze_cooldown"]=4.0 if "shatter" in relics else 8.0
		if weapon_index>=0 and inventory[weapon_index].get("plain",false):build["weapon"]="plain"
	for key in ["fire_dps","ice_slow","acid_strip","poison_weak","fire_power","frost_apply","acid_apply","poison_apply"]: build[key] = gear_stats.get(key,0.0)
	return build

func offer_blessing() -> void:
	var pool: Array = []
	for id in elements:
		if run_rules>=9 or elements[id] < 3: pool.append(id)
	if crit_chance < preload("res://build_stats.gd").calculate(self).get("crit_cap",0.6)-0.001: pool.append("focus")
	if crit_mult < 2.999: pool.append("ferocity")
	blessings.clear()
	# One substantial stat option and two elemental/critical options.
	blessings.append("attack" if rng.randi_range(0,1)==0 else "guard")
	while blessings.size() < 3 and not pool.is_empty(): blessings.append(pool.pop_at(rng.randi_range(0,pool.size()-1)))
	if blessings.size() < 3 and ("guard" not in blessings): blessings.append("guard")
	if blessings.size() < 3 and ("attack" not in blessings): blessings.append("attack")
	mode = "upgrade"

func apply_blessing(id: String) -> void:
	if base_elements.has(id): base_elements[id]=base_elements[id]+1 if run_rules>=9 else mini(3,base_elements[id]+1)
	elif id=="attack":bonus.attack+=preload("res://combat_pacing.gd").gains(self).attack
	elif id=="guard":bonus.armor+=preload("res://combat_pacing.gd").gains(self).guard;bonus.speed+=preload("res://combat_pacing.gd").gains(self).tempo
	elif id=="focus":bonus.crit_chance+=preload("res://combat_pacing.gd").gains(self).focus
	elif id=="ferocity":bonus.crit_mult+=preload("res://combat_pacing.gd").gains(self).ferocity
	recalculate_stats()

func status_text(state: Dictionary) -> String:
	var active: Array[String] = []
	if state.build.get("elemental_v2",false):
		if state.get("poison_counters",0)>0:active.append("POISON %.1f / %.1f/s"%[state.poison_counters,state.poison_counters])
		if state.get("frost_counters",0)>0:active.append("FROST %.1f / −%.0f%%"%[state.frost_counters,Combat.ice_slow(state)*100])
		if state.acid_stacks>0:active.append("ACID %.1f / EXPOSED %.0f%%"%[state.acid_stacks,preload("res://element_rules.gd").exposure(state)*100])
	if state.fire_time != INF: active.append("F:%.1f/s" % Combat.fire_damage(state))
	if state.iced and not state.build.get("elemental_v2",false): active.append("I:−%d%%" % roundi(Combat.ice_slow(state)*100))
	if state.acid_stacks > 0: active.append("A:−%.1f" % state.acid_stacks)
	if state.poisoned and not state.build.get("elemental_v2",false): active.append("P:−%d%%" % roundi(Combat.poison_weak(state)*100))
	if state.get("weapon_guard",0)>0:active.append("FOE GUARD %.1f"%float(state.get("guard_hp",8)) if state.build.get("fair_physical",false) else "FOE GUARD")
	if state.get("combo",0)>0:active.append("COMBO %d/3"%state.combo)
	if state.get("heat",0)>0:active.append("HEAT %d/4"%state.heat)
	if state.enemy.get("signature","")=="eclipse":active.append("SEAL BROKEN" if state.get("seal_broken",false) else ("SOLAR" if state.get("seal_phase",0)==0 else "LUNAR"))
	if state.get("shield",0)>0:active.append("SHIELD %d"%state.shield)
	if state.get("wound",0)>0:active.append("HEX %d"%state.wound)
	if state.get("guard",false):active.append("GUARD")
	if state.get("hex_guard",false):active.append("HEX WARD")
	if state.rage: active.append("RAGE")
	if state.enemy.get("ward_active",false):active.append("RUNE HEALS %d/3"%state.regens)
	if state.enemy.get("signature","")=="abbot" or (not Combat.Flow.modern(state) and state.enemy.get("boss_kind","")=="ash"):active.append("MEND %d/5"%state.regens)
	return "  ".join(active) if not active.is_empty() else "No active status effects"

func valid_bomb_target(tile: Vector2i) -> bool:
	if bombs <= 0 or not rooms[room].entities.has(tile): return false
	if rooms[room].entities[tile].kind != "enemy": return false
	if absi(tile.x - pos.x) + absi(tile.y - pos.y) > 3: return false
	# Sample the entire grid ray, including corner-adjacent tiles, so walls block throws.
	var previous = pos
	var from = Vector2(pos) + Vector2(0.5, 0.5)
	var to = Vector2(tile) + Vector2(0.5, 0.5)
	for i in range(1, 49):
		var sample = Vector2i(from.lerp(to, i / 48.0).floor())
		if rooms[room].walls.has(sample): return false
		if sample.x != previous.x and sample.y != previous.y:
			if rooms[room].walls.has(Vector2i(previous.x, sample.y)) or rooms[room].walls.has(Vector2i(sample.x, previous.y)): return false
		previous = sample
	return true

func throw_bomb(tile: Vector2i) -> void:
	game_throw_bomb(tile)
	if session:session.checkpoint()

func game_throw_bomb(tile: Vector2i) -> void:
	if mode != "bomb": return
	if not valid_bomb_target(tile):
		log_line("Invalid throw: choose a highlighted enemy within 3 tiles.")
		sfx("error")
		return
	bombs -= 1
	summary.bombs += 1
	var enemy = rooms[room].entities[tile]
	var dealt = minf(20.0, float(enemy.hp))
	enemy.hp -= dealt
	summary.dealt += dealt
	flashes[tile] = 0.25
	motes.append({"at": ORIGIN + Vector2(tile) * TILE, "value": "BOMB −%.1f" % dealt, "ttl": 0.9, "color": GOLD})
	sfx("break")
	log_line("Bomb deals %.1f damage; shields and armor bypassed." % dealt)
	mode = "play"
	if enemy.hp <= 0:
		if relics.has("bloom"):
			var healed = mini(4, max_hp - hp)
			hp += healed
			summary.healed += healed
		defeat_enemy(tile,enemy)
		resume_play()

func defeat_enemy(tile: Vector2i, enemy: Dictionary) -> void:
	if guided:guided.enemy_defeated()
	if sanctuary:sanctuary.defeated(enemy)
	if world_choices:world_choices.enemy_defeated(enemy)
	rooms[room].entities.erase(tile)
	var flasks_before=potions
	if replay:replay.enemy_defeated(enemy)
	var reward = 12 if enemy.type == 3 else (6 if enemy.elite else 2)
	if enemy.get("room_extra",false):reward=maxi(1,reward/2)
	shards += reward
	kills += 1
	if enemy.type == 3: rooms[room].cleared = true
	var xp = enemy_xp(enemy)
	gain_xp(xp)
	if feedback:feedback.reward(xp,reward,maxi(0,potions-flasks_before))
	log_line("%s: +%d embers, +%d XP." % [enemy.name,reward,xp])
	if kills==1 and int(career.get("runs",0))==0:log_line("Enemies give XP and embers. Fill the XP bar to choose an upgrade.")
	if mastery:mastery.enemy_defeated(enemy,tile)

func xp_required(level: int) -> int:
	if run_rules>=15:
		var n=maxi(1,level)-1
		return 40+60*n+10*n*(n-1)
	return 40 + 20*(maxi(1,level)-1) + 5*(maxi(1,level)-1)*(maxi(1,level)-1)

func enemy_xp(enemy: Dictionary) -> int:
	if run_rules>=15 and enemy.has("level"):
		var reward=10+15*maxi(0,int(enemy.level)-1)
		return reward*2 if int(enemy.type)==3 else reward
	var base = [12,18,14,60][enemy.type]
	return maxi(1,int(((base + (20 if enemy.get("elite",false) else 0)) + 4*(floor_number-1))*(0.5 if enemy.get("room_extra",false) else 1.0)))

func gain_xp(amount: int) -> void:
	var previous_level = character_level
	var previous_max_hp = max_hp
	experience += maxi(0,amount)
	while experience >= xp_required(character_level):
		experience -= xp_required(character_level)
		character_level += 1
		pending_levels += 1
	if character_level != previous_level:
		recalculate_stats()
		if run_rules>=13:
			var gained=maxi(0,max_hp-previous_max_hp)
			var restored=mini(max_hp-hp,gained)
			hp+=restored;summary.healed+=restored
			log_line("Level up: +%d max HP and +%d HP."%[gained,restored])
		if feedback:feedback.level_up(character_level-previous_level)

func resume_play() -> void:
	mode = "play"
	while pending_levels > 0:
		pending_levels -= 1
		reward_level = character_level-pending_levels
		offer_relic()
		if mode == "relic": return

func grant_relic(id: String) -> void:
	if id in relics: return
	relics.append(id)
	recalculate_stats()
	if replay:replay.observe()
	log_line("Level-up relic: " + RELICS[id][0])
	sfx("relic")

func ascend_floor() -> void:
	if mode != "floor" or (floor_limit()>0 and floor_number >= floor_limit()): return
	completed_rooms += visited.size()
	floor_number += 1
	var healed=mini(maxi(0,max_hp-hp),ceili(max_hp*0.6));hp+=healed;summary.healed+=healed
	if hp>=max_hp:run_metrics["vamp_fraction"]=0.0
	shards += 5
	# Levels, gear, iron, abilities and supplies persist.
	generate_floor()

func floor_limit() -> int:return 1 if demo_run else (0 if run_settings.get("mode","")=="endless" and run_rules>=5 else FLOOR_COUNT)

func roll_equipment() -> Dictionary:
	var slot = Gear.SLOTS[(floor_drop_index+floor_number-1)%Gear.SLOTS.size()]
	floor_drop_index += 1
	return Gear.roll(rng,slot,floor_number)

func recalculate_stats() -> void:
	var totals=preload("res://build_stats.gd").calculate(self)
	gear_stats=totals.gear;elements=totals.elements
	max_hp=totals.max_hp;attack=totals.attack;armor=totals.armor;speed=totals.speed
	crit_chance=totals.crit_chance;crit_mult=totals.crit_mult
	# A preview never calls this; real changes may reduce HP but cannot grant free healing.
	hp=mini(hp,max_hp)

func open_equipment() -> void:
	mode="equipment"
	if build_view:build_view.equipment_details=false
	if selected_item < 0 or selected_item >= inventory.size():selected_item=0 if not inventory.is_empty() else -1
	if selected_item>=0:equipment_slot=inventory[selected_item].slot
	inventory_page=0

func equipment_action(id: String) -> void:
	if id=="salvage_selected":salvage_selected();return
	if id=="close_equipment":resume_play();return
	if id.begins_with("slot:"):
		equipment_slot=id.get_slice(":",1)
		inventory_page=0
		selected_item=int(equipped.get(equipment_slot,-1))
	elif id=="page_prev":inventory_page=maxi(0,inventory_page-1)
	elif id=="page_next":inventory_page+=1
	elif id.begins_with("select:"):
		var index=int(id.get_slice(":",1))
		if index>=0 and index<inventory.size():selected_item=index
	elif id=="equip_selected" and selected_item>=0 and selected_item<inventory.size():
		equipped[inventory[selected_item].slot]=selected_item
		recalculate_stats()
		sfx("equip")
	elif id=="unequip_selected":
		equipped.erase(equipment_slot)
		recalculate_stats()
	elif id=="iron_selected" and iron>0 and selected_item>=0 and selected_item<inventory.size() and (run_rules<11 or near_forge()):
		inventory[selected_item].level+=1
		iron-=1
		recalculate_stats()
		sfx("equip")
		log_line("Upgraded " + Gear.title(inventory[selected_item]))

func draw_floor_clear() -> void:
	front_end.menu_backdrop();panel(Rect2(300,180,680,470))
	draw_texture_rect(textures.stairs,Rect2(580,220,120,120),false)
	text(Vector2(355,400),"FLOOR %d CLEARED"%floor_number,36,GOLD)
	text(Vector2(355,454),"Health restored. Gear and supplies carry on.",22,TEAL)
	text(Vector2(355,500),"Next floor: restore 60% of maximum HP",20,TEAL)
	front_end.icon_button(Rect2(355,520,570,75),"boots",("Descend / Floor %d" if sanctuary and sanctuary.active() else "Ascend / Floor %d")%(floor_number+1),"ascend")

func draw_equipment() -> void:
	draw_rect(Rect2(0,0,1280,840),Color(0.02,0.04,0.06,0.97))
	panel(Rect2(35,65,1210,710),Color("101e29"))
	text(Vector2(65,110),"EQUIPMENT",27,GOLD)
	stat_ui.icon("iron",Vector2(65,121),24)
	text(Vector2(96,141),"Iron %d  /  Fragments %d/3  /  %s"%[iron,iron_fragments,"Scrap uses left %d/3"%salvage_charges if near_forge() else "Visit a forge to scrap spare gear"],17,TEAL)
	button(Rect2(890,83,160,40),"Gear help ?","help:equipment")
	button(Rect2(450,83,205,40),"Your build","build_open")
	button(Rect2(665,83,205,40),"Unprotect" if selected_item>=0 and selected_item<inventory.size() and inventory[selected_item].get("kept",false) else "Protect item","keep_selected")
	close_button(Rect2(1170,83,45,40),"close_equipment")
	ui_icon("ember",Vector2(330,85),26);text(Vector2(369,109),str(shards),25,GOLD)
	panel(Rect2(55,158,255,458),Color("142631"))
	panel(Rect2(320,158,465,550),Color("142631"))
	panel(Rect2(795,158,420,550),Color("142631"))
	for i in range(Gear.SLOTS.size()):
		var slot=Gear.SLOTS[i]
		var rect=Rect2(65,170+i*85,235,70)
		var equipped_index=int(equipped.get(slot,-1))
		button(rect,"", "slot:"+slot,equipment_slot==slot)
		var texture: Texture2D=gear_icons[slot]
		draw_texture_rect(texture,Rect2(rect.position+Vector2(14,15),Vector2(40,40)),false,Color.WHITE if equipped_index>=0 else Color(0.12,0.12,0.12,1.0))
		text(rect.position+Vector2(68,43),slot.capitalize(),20,INK)
	panel(Rect2(65,633,235,75),Color("1c313d"))
	stat_ui.icon("attack",Vector2(80,642),22);text(Vector2(110,662),"%.1f"%attack,20,GOLD)
	stat_ui.icon("armor",Vector2(198,642),22);text(Vector2(228,662),"%.1f"%armor,20,GOLD)
	stat_ui.icon("crit_chance",Vector2(80,673),22);text(Vector2(110,693),"%.0f%%"%(crit_chance*100),20)
	stat_ui.icon("crit_mult",Vector2(198,673),22);text(Vector2(228,693),"%.0f%%"%(crit_mult*100),20)
	text(Vector2(337,183),"BACKPACK / " + equipment_slot.to_upper(),15,GOLD)
	var filtered: Array=inventory_tools.filtered()
	inventory_tools.controls()
	var pages=maxi(1,ceili(filtered.size()/8.0))
	inventory_page=clampi(inventory_page,0,pages-1)
	if filtered.is_empty():text(Vector2(350,280),"No items found for this slot yet.",17,Color("78929d"))
	for row in range(8):
		var location=inventory_page*8+row
		if location>=filtered.size():break
		var index=int(filtered[location])
		var item=inventory[index]
		var rect=Rect2(330,241+row*49,445,43)
		var color=Gear.COLORS[item.rarity]
		button(rect,"","select:%d"%index,selected_item==index)
		gear_icon(item.slot,rect.position+Vector2(10,7),28,color,item)
		text(rect.position+Vector2(52,20),"Lv.%d %s"%[item.level,item.name],16,color)
		text(rect.position+Vector2(52,35),Gear.RARITIES[item.rarity],11)
		if equipped.get(item.slot,-1)==index:text(rect.position+Vector2(340,26),"WORN",18,TEAL)
		elif item.get("kept",false):text(rect.position+Vector2(340,26),"PROTECTED",18,GOLD)
	button(Rect2(330,650,130,40),"Previous","page_prev",false,inventory_page>0)
	button(Rect2(645,650,130,40),"Next","page_next",false,inventory_page<pages-1)
	text(Vector2(493,677),"%d / %d"%[inventory_page+1,pages],17)
	if selected_item>=0 and selected_item<inventory.size():
		var item=inventory[selected_item]
		var color=Gear.COLORS[item.rarity]
		panel(Rect2(810,177,70,70),Color("233d4b"))
		gear_icon(item.slot,Vector2(819,186),52,color,item)
		text(Vector2(894,202),item.name,24,color)
		text(Vector2(894,229),"%s / Level %d"%[Gear.RARITIES[item.rarity],item.level],15)
		button(Rect2(812,252,210,35),"Show total stats" if build_view.equipment_details else "Show item stats","compare_details")
		text(Vector2(1025,279),"WORN" if build_view.equipment_details else "NOW",18,TEAL)
		text(Vector2(1115,279),"ITEM" if build_view.equipment_details else "AFTER",18,TEAL)
		var worn: Dictionary={}
		if equipped.has(item.slot):worn=inventory[equipped[item.slot]]
		var paged=false
		if not build_view.equipment_details:build_view.draw_compare(selected_item,{},Vector2(812,315),380,198);paged=build_view.compare_has_pages
		else:paged=preload("res://equipment_presenter.gd").draw_comparison(self,worn,item,Vector2(812,315),380,198,true)
		if not paged:text(Vector2(812,530),("Ability: "+choice_ui.ability_name(item)) if item.slot=="weapon" else "Total stats / current → equipped",14,Color("78929d"))
		var already=equipped.get(item.slot,-1)==selected_item
		button(Rect2(810,540,240,45),"Equipped" if already else "Equip selected","equip_selected",already,not already)
		button(Rect2(1060,540,140,45),"Unequip","unequip_selected",false,equipped.has(equipment_slot))
		if item.slot=="weapon" and Rect2(810,177,390,70).has_point(design_mouse()):
			panel(Rect2(802,365,405,166));draw_wrapped(choice_ui.weapon_description(item),Vector2(818,398),370,20,TEAL,5)

	else:
		gear_icon(equipment_slot,Vector2(955,240),64,Color("526773"))
		text(Vector2(830,345),"Select an item from your backpack.",17)
	draw_inline_crafting()
	if selected_item>=0 and selected_item<inventory.size():
		var item=inventory[selected_item]
		if Rect2(810,615,125,45).has_point(design_mouse()) or (menu_keyboard and not buttons.is_empty() and session.focused<buttons.size() and buttons[session.focused].id in ["iron_selected","help:craft_upgrade"]):
			panel(Rect2(330,160,455,520),Color("233d4b"))
			text(Vector2(350,202),"IRON / ITEM STATS",24,GOLD)
			text(Vector2(350,237),"Level %d → %d"%[item.level,item.level+1],20,TEAL)
			text(Vector2(580,237),"NOW",18)
			text(Vector2(680,237),"AFTER",18)
			var upgraded=item.duplicate(true)
			upgraded.level+=1
			preload("res://equipment_presenter.gd").draw_comparison(self,item,upgraded,Vector2(350,276),410,285)
			text(Vector2(350,587),"BUILD IF EQUIPPED",18,GOLD)
			var before=preload("res://build_stats.gd").prospective(self,selected_item)
			var after=preload("res://build_stats.gd").prospective(self,selected_item,{selected_item:upgraded})
			var line=0
			for key in preload("res://equipment_presenter.gd").affected(item,upgraded):
				if line>=2 or is_equal_approx(float(before[key]),float(after[key])):continue
				stat_ui.label(key,Vector2(350,617+line*26),22)
				text(Vector2(386,617+line*26),"%s → %s"%[build_view.value(key,before),build_view.value(key,after)],20,TEAL);line+=1


func draw_inline_crafting() -> void:
	var nearby=near_forge();var valid=selected_item>=0 and selected_item<inventory.size()
	if nearby:draw_rect(Rect2(800,588,410,112),Color(TEAL,0.5),false,2)
	var can_upgrade=valid and iron>0 and (run_rules<11 or nearby)
	var can_imprint=valid and dungeon_threads.can_infuse()
	var can_scrap=valid and nearby and salvage_charges>0 and selected_item not in equipped.values() and not inventory[selected_item].get("kept",false)
	text(Vector2(810,603),"FORGE NEARBY / CRAFTING" if nearby else "CRAFTING / FIND A FORGE",18,GOLD if nearby else Color("8d9693"))
	var entries=[["iron","UPGRADE","iron_selected" if can_upgrade else "help:craft_upgrade",can_upgrade],["stat_fire","IMPRINT","infuse_open" if can_imprint else "help:infuse",can_imprint],["salvage","SCRAP","salvage_selected" if can_scrap else "help:scrap",can_scrap]]
	for i in range(entries.size()):
		var entry=entries[i];var rect=Rect2(810+i*130,615,125,45)
		button(rect,"",entry[2]);ui_icon(entry[0],rect.position+Vector2(5,8),26)
		text(rect.position+Vector2(34,29),entry[1],16,GOLD if entry[3] else Color("858c88"))
		if nearby and entry[3]:
			var glow=0.75 if session.preferences.reduced_flashes else 0.55+0.3*(0.5+0.5*sin(pulse*3.0))
			draw_rect(rect.grow(-3),Color(TEAL,glow),false,2)
	var free=run_rules>=9 and not floor_flags.get("free_imprint_used",false)
	text(Vector2(810,684),"1 iron / "+("free element" if free else "paid imprint")+" / %d scraps left"%salvage_charges if nearby else "Find a forge to use these options.",16,TEAL if nearby else INK)
	text(Vector2(65,755),"Select gear above. Upgrade previews its changes; protected and equipped gear cannot be scrapped.",17,TEAL)

func decorate_treasure(coord: Vector2i) -> void:
	var data=rooms[coord]
	var style_id: String=CHEST_STYLES[roles[coord]]
	# An extra optional guardian chest makes the reward worth choosing a harder fight.
	if run_rules>=15 and roles[coord]=="Forge":style_id="guardian"
	var chest: Vector2i
	var guardian=Vector2i(-1,-1)
	var tier=0
	if style_id in ["wall","water","guardian","winding"]:
		var candidates: Array=[0,1,2,3]
		if data.bounds.size.x==9 and data.gate.x>=0 and not data.horizontal_gate: candidates=[0,2]
		var corner=int(candidates[rng.randi_range(0,candidates.size()-1)])
		var cx=data.bounds.position.x+1 if corner%2==0 else data.bounds.end.x-2
		var cy=data.bounds.position.y+1 if corner<2 else data.bounds.end.y-2
		var dx=1 if corner%2==0 else -1
		var dy=1 if corner<2 else -1
		chest=Vector2i(cx,cy)
		var path: Array=[chest,chest+Vector2i(dx,0),chest+Vector2i(2*dx,0)]
		var barriers: Array=[chest+Vector2i(0,dy),chest+Vector2i(dx,dy)]
		if style_id=="winding":
			path=[chest,chest+Vector2i(dx,0),chest+Vector2i(dx,dy),chest+Vector2i(2*dx,dy),chest+Vector2i(2*dx,2*dy),chest+Vector2i(3*dx,2*dy)]
			barriers=[chest+Vector2i(0,dy),chest+Vector2i(0,2*dy),chest+Vector2i(dx,2*dy),chest+Vector2i(2*dx,0),chest+Vector2i(3*dx,0),chest+Vector2i(3*dx,dy)]
		clear_motif(data,path+barriers)
		for tile in barriers:data.walls[tile]=true
		for tile in path:
			data.walls.erase(tile)
			data.decor[tile]="trail"
		connect_chest_approach(data,path.back())
		data.decor[path.back()]="lantern"
		data["chest_approach"]=path.back()
		data["chest_path"]=path.duplicate()
		var entrance: Vector2i=path[1]
		match style_id:
			"wall":
				data.walls[entrance]=true
				data.entities[entrance]={"kind":"crack"}
				data.cache=chest
				tier=1
			"water":
				data.entities[entrance]={"kind":"water"}
				data.water_cache=chest
				tier=1
			"guardian":
				guardian=entrance
				var guard=make_enemy(theme_enemy_type(),distances[coord],mini(6,int(distances[coord])+2) if run_rules>=15 else -1)
				guard.name="Chest keeper"
				data.entities[guardian]=guard
				tier=2 if run_rules>=15 else 1
			"winding":tier=0 if rng.randf()<0.5 else 1
	elif style_id=="warden":
		chest=Vector2i(5,2)
		data.entities.erase(chest)
		data.walls.erase(chest)
		guardian=Vector2i(6,3)
		tier=2
	elif style_id=="sentinel":
		var candidates=[Vector2i(10,3),Vector2i(9,2),Vector2i(11,3)] if data.horizontal_gate else [Vector2i(10,3),Vector2i(10,7),Vector2i(9,8)]
		chest=candidates[rng.randi_range(0,candidates.size()-1)]
		clear_motif(data,[chest])
		data.walls.erase(chest)
		guardian=data.gate
		tier=2
	else:
		var b: Rect2i=data.bounds
		var reserved: Array=[Vector2i(6,5),data.special,data.gate,Vector2i(b.position.x+1,5),Vector2i(b.end.x-2,5),Vector2i(6,b.position.y+1),Vector2i(6,b.end.y-2)]
		if run_rules>=4:
			for x in range(b.position.x+1,b.end.x-1):reserved.append(Vector2i(x,5))
			for y in range(b.position.y+1,b.end.y-1):reserved.append(Vector2i(6,y))
		chest=room_spot(b,data.walls,data.entities,reserved)
		tier=0
	var item=chest_item(tier,style_id=="warden")
	if run_rules>=15 and floor_number==1 and coord==Vector2i.ZERO:
		var archetypes=["balanced","dagger","axe","greatblade","ember"]
		var weapon: String=archetypes[rng.randi_range(0,archetypes.size()-1)]
		var rank=ember_tree.rank("smithcraft")
		var rarity=0 if rank==0 else 2 if rank>=3 else 1
		var affixes=[] if rank==0 else [{"balanced":"fire_dps","dagger":"poison_weak","axe":"acid_strip","greatblade":"ice_slow","ember":"fire_dps"}[weapon]]
		if rank>=3:affixes.append("crit_mult")
		item=make_gear("weapon",2 if rank>=2 else 1,rarity,affixes,weapon)
		if rank==0:item["plain"]=true
	data.entities[chest]={"kind":"chest","tier":tier,"style":style_id,"guardian":guardian,"item":item}
	if run_rules>=15 and floor_number==1 and coord==Vector2i.ZERO:data.entities[chest]["starting_weapon"]=true
	data.chest=chest

func clear_motif(data: Dictionary, tiles: Array) -> void:
	var b: Rect2i=data.bounds
	var reserved: Array=tiles+[Vector2i(6,5),data.special,data.gate,Vector2i(b.position.x+1,5),Vector2i(b.end.x-2,5),Vector2i(6,b.position.y+1),Vector2i(6,b.end.y-2)]
	for tile in tiles:
		if data.entities.has(tile):
			var entity=data.entities[tile]
			data.entities.erase(tile)
			var spot=room_spot(b,data.walls,data.entities,reserved)
			data.entities[spot]=entity

func chest_item(tier: int, boss_reward: bool=false,forced_slot: String="") -> Dictionary:
	var odds=replay.odds(tier) if replay else CHEST_ODDS[tier]
	var roll=rng.randf()*100.0 if run_rules>=5 else rng.randi_range(1,100)
	var rarity=0 if roll<=odds[0] else (1 if roll<=odds[0]+odds[1] else 2)
	if run_rules>=5:rarity=0 if roll<odds[0] else (1 if roll<odds[0]+odds[1] else 2)
	var affixes: Array=[]
	var pool: Array=Gear.AFFIXES.duplicate()
	for i in range(rarity):affixes.append(pool.pop_at(rng.randi_range(0,pool.size()-1)))
	var slot=forced_slot if forced_slot in Gear.SLOTS else Gear.SLOTS[(floor_drop_index+floor_number)%Gear.SLOTS.size()]
	floor_drop_index+=1
	if run_rules>=12 and slot=="amulet" and rarity==1 and roll<float(Gear.chest_odds(odds,slot,run_rules)[0]):rarity=0;affixes.clear()
	var item_level=loot_level(floor_number,1 if boss_reward or rng.randf()<0.25 else 0)
	var weapons=["balanced","dagger","greatblade","ember","axe"] if run_rules>=7 else ["balanced","dagger","greatblade","ember"]
	var result=make_gear(slot,item_level,rarity,affixes,weapons[rng.randi_range(0,weapons.size()-1)] if slot=="weapon" else "balanced")
	if slot=="armor" and run_rules>=9:
		result["armor_class"]="light" if rng.randi_range(0,1)==0 else "heavy"
		result.name="Light armor" if result.armor_class=="light" else "Heavy armor"
	result=mastery.roll_variant(result) if mastery else result
	if sanctuary and sanctuary.active() and result.rarity>0:
		var known=[]
		for element in ["fire","ice","acid","poison"]:
			if sanctuary.unlocked(element):known.append(element)
		if not known.is_empty() and rng.randf()<0.10:
			var element=known[rng.randi_range(0,known.size()-1)]
			result["sanctuary_bonus"]=element
			result.name={"fire":"Kindled ","ice":"Rimed ","acid":"Etched ","poison":"Venomed "}[element]+result.name
	if run_rules>=14 and result.slot=="weapon" and result.get("archetype","") in ["axe","greatblade"] and result.rarity>=1 and not result.has("variant") and rng.randf()<0.60:
		result["heavy_form"]="colossus";result.name="Colossus "+("axe" if result.archetype=="axe" else "greatblade")
	return result

func room_has_chest(coord: Vector2i) -> bool:
	for entity in rooms[coord].entities.values():
		if entity.kind=="chest":return true
	return false

func chest_access(chest: Dictionary) -> String:
	var needs=dungeon_threads.chest_requirements(chest)
	if needs!="":return needs
	var guardian: Vector2i=chest.guardian
	if guardian.x>=0 and rooms[room].entities.get(guardian,{}).get("kind","")=="enemy":return "defeat "+rooms[room].entities[guardian].name
	return {"stash":"nearby stash","nook":"side chamber","wall":"breakable-wall alcove","water":"cross water","guardian":"guardian defeated","winding":"follow the winding side passage","sentinel":"sentinel defeated","warden":"Warden defeated"}[chest.style]

func open_chest(tile: Vector2i) -> bool:
	var chest=rooms[room].entities.get(tile,{})
	if chest.get("kind","")!="chest":return false
	var needs=dungeon_threads.chest_requirements(chest)
	if chest.get("cursed",false):needs=""
	if needs!="":log_line(needs);sfx("error");return false
	var guardian: Vector2i=chest.guardian
	if guardian.x>=0 and rooms[room].entities.get(guardian,{}).get("kind","")=="enemy":
		log_line("Chest sealed: defeat "+rooms[room].entities[guardian].name+" first.")
		sfx("error")
		return false
	if chest.get("cursed",false) and not chest.get("paid",false):puzzle_tile=tile;mode="curse";return false
	inventory.append(chest.item.duplicate(true))
	last_loot_index=inventory.size()-1
	last_chest_tier=chest.tier
	shards+=3+chest.tier*3
	summary.chests+=1
	chest.kind="opened_chest"
	if chest.has("key_id"):
		floor_keys.erase(chest.key_id)
		if chest.key_id=="copper":floor_flags["copper_spent"]="treasure"
	mode="loot"
	if loot_window:loot_window.start()
	motes.append({"at":ORIGIN+Vector2(tile)*TILE,"value":"TREASURE","ttl":1.2,"color":CHEST_COLORS[chest.tier]})
	sfx("pickup")
	log_line("Found "+Gear.title(chest.item)+". Stored in your bag.")
	return true

func draw_pixel_icon(texture: Texture2D,at: Vector2,size: int) -> void:
	var pixels=maxi(1,size)
	var origin=(at+Vector2.ONE*(size-pixels)/2.0).round()
	draw_texture_rect(texture,Rect2(origin,Vector2(pixels,pixels)),false,Color.WHITE)

func gear_icon(slot: String, at: Vector2, size: int=32, tint: Color=INK,item: Dictionary={}) -> void:
	var texture: Texture2D=gear_icons[slot]
	if slot=="weapon" and not item.is_empty():texture=weapon_icons.get(item.get("archetype","balanced"),texture)
	if slot=="armor" and item.get("armor_class","")=="light":texture=gear_icons.light_armor
	draw_pixel_icon(texture,at,size)
	# Rarity marks preserve the original painted palette of the icon.
	if tint in Gear.COLORS:
		draw_rect(Rect2(at+Vector2(size-6,size-6),Vector2(6,6)),Color("18171d"))
		draw_rect(Rect2(at+Vector2(size-5,size-5),Vector2(4,4)),ui_color(tint))

func draw_loot() -> void:
	loot_window.draw()

func format_delta(key: String, delta: float) -> String:
	return "%+.1f%s"%[delta*100 if key in ["crit_chance","ice_slow","poison_weak","evade","vampirism"] else delta,"%" if key in ["crit_chance","ice_slow","poison_weak","evade","vampirism"] else ""]

func connect_chest_approach(data: Dictionary, approach: Vector2i) -> void:
	# Join the motif to its existing wing without cutting a hole through a sentinel partition.
	if data.gate.x>=0 and data.horizontal_gate and approach.y<4:
		for x in range(mini(approach.x,6),maxi(approach.x,6)+1):
			data.walls.erase(Vector2i(x,approach.y))
			data.decor[Vector2i(x,approach.y)]="trail"
		for y in range(approach.y,4):data.walls.erase(Vector2i(6,y))
	else:
		for y in range(mini(approach.y,5),maxi(approach.y,5)+1):
			data.walls.erase(Vector2i(approach.x,y))
			data.decor[Vector2i(approach.x,y)]="trail"

func theme_index() -> int:
	return [0,1,2,0,2][posmod(floor_number-1,5)] if run_rules>=4 else (0 if floor_number<=2 else (1 if floor_number<=4 else 2))

func ui_color(color: Color) -> Color:
	if ui_theme==1 and not drawing_world:
		if color==INK:return Color("342825")
		if color==GOLD:return Color("684b30")
		if color==TEAL:return Color("315d59")
		if color==Gear.COLORS[0]:return Color("51443a")
		if color==Gear.COLORS[1] or color==CHEST_COLORS[1]:return Color("315676")
		if color==Gear.COLORS[2]:return Color("704b85")
		if color==CHEST_COLORS[0] or color==CHEST_COLORS[2]:return Color("684b30")
	return color

func draw_hud() -> void:
	panel(Rect2(625,4,220,38));panel(Rect2(850,4,105,38))
	ui_icon("ember",Vector2(637,10),26)
	text(Vector2(674,31),"EMBERS",18)
	text(Vector2(760,34),str(shards),27,GOLD)
	stat_ui.icon("iron",Vector2(859,10),26)
	text(Vector2(895,34),str(iron),27,GOLD)
	text(Vector2(64,32),(tactics.FLOORS[posmod(floor_number-1,5)][0] if run_rules>=4 else THEMES[theme_index()]).to_upper(),24,Color("c8bea8"))
	text(Vector2(1060,32),"FLOOR %d / %s"%[floor_number,str(floor_limit()) if floor_limit()>0 else "INF"],20,Color("c8bea8"))
	panel(Rect2(58,46,370,93))
	text(Vector2(76,72),"HP",18,INK)
	
	text(Vector2(314,72),"%d / %d"%[hp,max_hp],18)
	draw_rect(Rect2(76,81,332,14),Color("35282c"))
	draw_rect(Rect2(76,81,332.0*hp/max_hp,14),Color("b5514d"))
	text(Vector2(76,117),"Level %d"%character_level,18,GOLD)
	draw_rect(Rect2(145,105,263,10),Color("33313e"))
	draw_rect(Rect2(145,105,263.0*experience/xp_required(character_level),10),Color("9f8a60"))
	text(Vector2(245,132),"XP %d / %d"%[experience,xp_required(character_level)],18)
	var values=["%.1f"%attack,"%.1f"%armor,"%.2fs"%choice_ui.interval(speed),"%d%%"%roundi(crit_chance*100)]
	for i in range(3):
		var x=452+i*126
		panel(Rect2(x,46,116,93))
		stat_ui.icon(["attack","armor","interval","crit_chance"][i],Vector2(x+8,55),32)
		text(Vector2(x+43,76),stat_ui.short_name(["attack","armor","interval","crit_chance"][i]),14,INK)
		text(Vector2(x+20,116),values[i],27,GOLD)
	button(Rect2(980,52,68,68),"", "equipment",false,mode=="play")
	gear_icon("armor",Vector2(998,66),32)
	text(Vector2(1008,136),controls.label("inventory") if controls else "E",12,Color("c8bea8"))
	button(Rect2(1068,52,68,68),"", "character",false,mode=="play")
	ui_icon("book",Vector2(1086,68),32)
	text(Vector2(1096,136),controls.label("journal") if controls else "C",12,Color("c8bea8"))
	button(Rect2(1156,52,68,68),"", "toggle_map",false,mode in ["play","fight","inspect"])
	ui_icon("map",Vector2(1174,68),32)
	text(Vector2(1166,136),"MAP / "+(controls.label("map") if controls else "Tab"),12,Color("c8bea8"))
	text(Vector2(ORIGIN.x,158),"CHAMBER "+room_number(room)+" / "+roles[room],14,Color("837c78"))
	for i in range(1):
		var at=Vector2(64+i*280,738);var count=potions if i==0 else bombs
		var ready=(mode in ["play","fight"] if i==0 else mode=="play") and count>0 and (hp<max_hp if i==0 else true)
		button(Rect2(at,Vector2(260,66)),"","heal" if i==0 else "bomb",mode=="bomb" and i==1,ready)
		ui_icon("potion" if i==0 else "bomb",at+Vector2(12,8),48)
		text(at+Vector2(80,25),("HEAL / " if i==0 else "BOMB / ")+(controls.label("heal" if i==0 else "bomb") if controls else "H" if i==0 else "B"),18)
		text(at+Vector2(80,55),"%d %s"%[count,"flasks" if i==0 else "bombs"],27,GOLD if count>0 else Color("8a7f83"))
		if i==0 and ready and hp<float(max_hp)*0.45:draw_rect(Rect2(at,Vector2(260,66)).grow(-2),TEAL,false,2)

	button(Rect2(1156,756,68,44),"...","settings",false,mode=="play")
	if mode=="bomb":draw_wrapped("Aim: arrows + Enter / A, or click. B / Esc cancels.",Vector2(640,770),490,17,Color("c8bea8"))
	elif mode=="inspect":draw_wrapped("Inspect: arrows move cursor / I or Esc exits.",Vector2(640,770),490,17,Color("c8bea8"))
	elif session and session.error!="":text(Vector2(640,783),"Save failed. Esc opens pause / retry.",18,Color("ee9b88"))
	elif pulse<toast_until and (not stat_ui or stat_ui.notice_left<=0 or mode=="fight"):draw_wrapped(toast,Vector2(640,770),490,16,Color("b4b0a6"),2)
	else:text(Vector2(640,783),"I: inspect / Esc: pause / Autosave on",16,Color("b4b0a6"))

func draw_wrapped(value: String,at: Vector2,width: float,size: int=16,color: Color=INK,max_lines: int=4) -> void:
	size=readable_size(size)
	var face=text_face(size)
	var line=""
	var row=0
	for word in value.split(" "):
		if face.get_string_size(line+" "+word,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width and line!="":
			text(at+Vector2(0,row*(size+5)),line,size,color)
			row+=1
			if row>=max_lines:return
			line=word
		else:line+=(" " if line!="" else "")+word
	if row<max_lines:text(at+Vector2(0,row*(size+5)),line,size,color)

func fountain_chamber() -> String:
	for coord in roles:
		if roles[coord]=="Fountain":return room_number(coord)
	return "?"

func context_entity(pointer: Vector2) -> Dictionary:
	if mode=="fight":return fight
	if mode=="inspect":return rooms[room].entities.get(Vector2i(((pointer-ORIGIN)/TILE).floor()),{})
	if enemy_ability_open and inspection_room==room and Rect2(610,330,378,350).has_point(pointer):return rooms[room].entities.get(inspection_tile,{})
	var tile=Vector2i(((pointer-ORIGIN)/TILE).floor())
	var entity: Dictionary=rooms[room].entities.get(tile,{})
	if not entity.is_empty():
		if inspection_tile!=tile or inspection_room!=room:enemy_ability_open=false
		inspection_tile=tile;inspection_room=room
	elif inspection_room==room and (Rect2(972,210,260,470).has_point(pointer) or (enemy_ability_open and Rect2(610,330,378,350).has_point(pointer))):
		entity=rooms[room].entities.get(inspection_tile,{})
	return entity

func draw_context() -> void:
	var entity=context_entity(design_mouse())
	if entity.is_empty():return
	var kind=entity.kind
	if kind=="sanctuary_discovery":
		var info=sanctuary.DISCOVERIES.get(str(entity.get("discovery","")),{})
		panel(Rect2(972,210,260,300));text(Vector2(988,250),"SANCTUARY",22,GOLD)
		draw_wrapped(str(info.get("name","Discovery"))+". Step here to bring this discovery back after your run.",Vector2(988,300),225,20,INK,8);return
	if world_choices and world_choices.inspect(entity):return
	if kind not in ["enemy","chest","salvage","fountain","iron","shrine","dungeon_key","brazier","reliquary","urn"]:return
	panel(Rect2(972,210,260,560 if kind=="enemy" and mode=="fight" and run_rules>=9 else 470))
	if kind=="enemy":
		var roster=preload("res://enemy_roster.gd")
		text(Vector2(988,240),"Level %d"%roster.level(entity,floor_number),22,TEAL)
		draw_wrapped(roster.title(entity),Vector2(988,270),226,23,GOLD,2)
		var rate=Combat.enemy_speed(battle) if mode=="fight" else float(entity.speed)
		var values=[("%.1fk"%(float(entity.hp)/1000) if entity.hp>=10000 else str(ceili(entity.hp))),"%.1f"%entity.attack,"%.1f"%(maxf(0,float(battle.enemy.armor)-float(battle.acid_stacks)) if mode=="fight" else entity.armor),"%.2fs"%(1.0/maxf(0.01,rate))]
		var labels=["HP / %d"%entity.max,"ATTACK","ARMOR","INTERVAL"];var icons=["health","attack","armor","speed"]
		for i in range(4):
			var at=Vector2(988+(i%2)*116,309+int(i/2)*65)
			stat_ui.icon(["enemy_current_hp","enemy_attack","enemy_armor","enemy_interval"][i],at,22)
			text(at+Vector2(28,18),stat_ui.short_name(["enemy_current_hp","enemy_attack","enemy_armor","enemy_interval"][i]),16,INK)
			if i==0:text(at+Vector2(45,46),"/ %d"%entity.max,16)
			text(at+Vector2(0,46),values[i],24,GOLD)
		if entity.get("affix","") in replay.AFFIXES:text(Vector2(1100,240),replay.AFFIXES[entity.affix][0],18,TEAL)
		if mode=="fight":
			var remain=maxf(0.0,float(battle.e_time)-clock)
			var interval=1.0/maxf(0.01,Combat.enemy_speed(battle))
			var progress=clampf(1.0-remain/interval,0.0,1.0)
			var cy=744.0 if run_rules>=9 else 658.0;var center=Vector2(1003,cy)
			draw_arc(center,11,0,TAU,32,Color("524641"),4.0,true)
			if progress>0.0:draw_arc(center,11,-PI/2,-PI/2+TAU*progress,32,GOLD,4.0,true)
			text(Vector2(1022,cy+6),"NEXT ATTACK"+(" / HEAVY" if entity.trait=="heavy" and (battle.e_hits+1)%3==0 else ""),16,GOLD)
		fight_preview.draw(entity)
		draw_wrapped(enemy_explanation(entity),Vector2(988,534),226,15,INK,2)
		text(Vector2(988,583),"Ability details / hover here",15,TEAL)
		enemy_ability_open=mode=="inspect" or Rect2(988,518,226,80).has_point(design_mouse()) or (enemy_ability_open and Rect2(610,330,378,350).has_point(design_mouse()))
		if enemy_ability_open:
			panel(Rect2(610,330,345,350));text(Vector2(630,369),"ENEMY ABILITY",23,GOLD)
			draw_wrapped(enemy_explanation(entity),Vector2(630,407),305,20,INK,10)
		if mode=="fight" and run_rules>=4:draw_wrapped(Combat.intent(battle),Vector2(988,608),226,15,GOLD,2)
		if mode=="fight" and run_rules<9:draw_wrapped(status_text(battle),Vector2(988,648),226,13,TEAL,1)
		if mode=="fight" and run_rules>=9:
			var lines=[]
			if battle.get("weapon_guard",0)>0 and battle.build.get("fair_physical",false):lines.append(["armor","Guard %.1f"%float(battle.get("guard_hp",0))])
			if battle.fire_time!=INF:
				var heat=" / Heat %d/%d"%[battle.fire_heat,preload("res://element_rules.gd").heat_cap(battle.build)] if battle.get("fire_heat",0)>0 else ""
				lines.append(["fire","Burn %.1f/s"%Combat.fire_damage(battle)+heat])
			if battle.get("poison_counters",0)>0:lines.append(["poison","Poison %.1f (%.1f/s)"%[battle.poison_counters,battle.poison_counters*(0.5 if battle.build.get("elemental_specialization",false) else 1.0)]])
			if battle.get("frost_counters",0)>0:lines.append(["ice","Frost %.1f (%.0f%% slow)"%[battle.frost_counters,Combat.ice_slow(battle)*100]])
			if battle.acid_stacks>0:lines.append(["acid","Acid %.1f / +%.0f%% dmg"%[battle.acid_stacks,preload("res://element_rules.gd").exposure(battle)*100]])
			for i in range(lines.size()):
				ui_icon(lines[i][0],Vector2(988,641+i*18),16);text(Vector2(1010,656+i*18),lines[i][1],16,TEAL)
				if Rect2(988,639+i*18,226,18).has_point(design_mouse()):
					panel(Rect2(610,330,345,350));text(Vector2(630,369),"ELEMENT EFFECT",23,GOLD)
					draw_wrapped("Guard absorbs physical damage until depleted. Greatblades break it. Active Fire and Poison bypass it; effects apply when a hit deals damage." if lines[i][0]=="armor" else preload("res://element_rules.gd").describe(lines[i][0],battle.build,attack),Vector2(630,407),305,20,INK,11)
		else:text(Vector2(988,642),"Reward: %d XP"%enemy_xp(entity),15,GOLD)
	elif kind=="chest":
		text(Vector2(988,245),CHEST_NAMES[entity.tier],21,CHEST_COLORS[entity.tier])
		text(Vector2(988,274),"TREASURE CHEST",16)
		draw_wrapped(chest_access(entity),Vector2(988,319),226,16,INK,3)
		if entity.get("starting_weapon",false):
			text(Vector2(988,410),"RANDOM WEAPON",18,GOLD)
			text(Vector2(988,455),"%s / Level %d"%[Gear.RARITIES[entity.item.rarity],entity.item.level],18,TEAL)
		elif entity.get("ward_won",false):
			text(Vector2(988,410),"GUARANTEED REWARD",18,GOLD)
			text(Vector2(988,456),"VERY RARE",25,Gear.COLORS[2])
			text(Vector2(988,493),"+1 item level",20,TEAL)
		else:
			text(Vector2(988,410),"ITEM ODDS",18,GOLD)
			var odds=Gear.chest_odds(replay.odds(entity.tier),str(entity.get("item",{}).get("slot","")),run_rules)
			for i in range(3):text(Vector2(988,445+i*29),"%s  %.1f%%"%[Gear.RARITIES[i],odds[i]],18)
		if entity.has("ward_item") and not entity.get("ward_won",false):draw_wrapped("Rune disabled: standard reward." if entity.get("ward_disabled",false) else "Beat its guardian with the rune active for Very rare gear.",Vector2(988,525),226,18,GOLD,2)
		text(Vector2(988,581),"One item + %d embers"%(3+entity.tier*3),15)
		draw_wrapped("Step onto the chest to open it.",Vector2(988,640),225,15)
	elif kind in ["dungeon_key","brazier","reliquary"]:
		text(Vector2(988,250),{"dungeon_key":"COPPER KEY","brazier":entity.get("rune","").to_upper()+" BRAZIER","reliquary":"SEALED RELIQUARY"}[kind],21,GOLD)
		var explanation="A unique key for this floor. Return to the marked locked chest."
		if kind=="brazier":explanation=("Already lit. " if floor_flags.get(entity.rune,false) else "Step onto this candle. ")+("Light 1: SUN, then 2: MOON. Both unlock the chest in chamber %s (Fountain). No key is spent."%fountain_chamber())
		if kind=="reliquary":explanation="Spent." if entity.used else ("Anyone can solve the inscription. Runic Sight reveals a clue and upgrades one reward." if run_rules>=4 else ("Read its inscription, solve the glyph order and choose your equipment." if ember_tree.rank("runic_sight")>0 else "Learn Runic Sight in the Ember Tree to enter this optional vault on a future run."))
		draw_wrapped(explanation,Vector2(988,300),225,20,INK,12)
	elif kind=="shrine":
		text(Vector2(988,250),"CINDER SHRINE",22,GOLD)
		draw_wrapped("Spent." if entity.get("used",false) else "Choose: +1 weapon level for 8 current and max HP, take embers, or leave.",Vector2(988,300),225,18,INK,8)
	elif kind=="salvage":
		text(Vector2(988,250),"SCRAP FORGE",21,GOLD)
		draw_wrapped("Scrap spare gear for fragments. 3 fragments = 1 iron. Equipped gear cannot be scrapped.",Vector2(988,300),225,17,INK,7)
		text(Vector2(988,510),"Uses left: %d / 3"%salvage_charges,18)
	elif kind=="urn":
		text(Vector2(988,250),"Old urn",22,GOLD)
		draw_wrapped("Step onto this urn to break it. Find 2 HP, 1 ember, or nothing.",Vector2(988,300),225,18)
	else:
		if kind=="iron":stat_ui.icon("iron",Vector2(988,227),26)
		text(Vector2(1021 if kind=="iron" else 988,250),"Fountain" if kind=="fountain" else "Iron",22,GOLD)
		draw_wrapped("Restores up to %d HP once."%roundi((30+3*ember_tree.rank("wellkeeper"))*(0.75 if replay.vow("famine")>0 else 1.0)) if kind=="fountain" else "Upgrade any owned item by one level.",Vector2(988,300),225,18)

func enemy_explanation(enemy: Dictionary) -> String:
	if enemy.get("ward_active",false):return "Rune in room %s: heals %d HP, 3 times. Disable it, or win powered for Very rare gear."%[room_number(enemy.ward_source),enemy.regen]
	if enemy.get("family","") in Combat.Flow.FAMILIES:return Combat.Flow.FAMILIES[enemy.family].desc
	if enemy.get("signature","") in Combat.Flow.BOSSES:
		if enemy.signature=="castellan" and run_rules<9:return "Below 50% HP: blocks 1 hit. Greatblades break the guard; fire ignores it."
		return Combat.Flow.BOSSES[enemy.signature][2]
	var basic=Combat.player_damage(attack,maxf(0,enemy.armor)*(0.4 if "needle" in relics else 1.0)) if run_rules>=9 else float(Combat.damage(attack,maxf(0,enemy.armor)*(0.4 if "needle" in relics else 1.0)))
	var why="Your unblocked hit: %.1f damage. "%basic
	if run_rules>=4:why+=["Regrowth bite restores 4 HP. ","Enemy special hits: +80% damage. ","Your next 3 attacks have 25% less power. ","Enemy special hits: +80% damage. "][int(enemy.type)]
	if enemy.trait=="shield":why+=("Opening guard absorbs 8 physical damage. " if run_rules>=9 else "Blocks your opening hit. ")
	if enemy.trait=="pierce":why+="Ignores 50% of your armor. "
	if enemy.get("boss_kind","")=="iron":why+="Heavy plate favors acid and armor piercing. "
	elif enemy.get("boss_kind","")=="tide":why+="Rapid attacks favor ice and defensive builds. "
	elif enemy.get("boss_kind","")=="ash":why+="Mends %d HP every 2 seconds, five times. Sustained fire helps; every third hit is heavy. "%enemy.regen
	elif enemy.trait=="heavy":why+="Every 3rd hit has 80% more power. "
	if enemy.type==3:why+="Below 50% HP: +25% attack and faster attacks."
	if enemy.get("affix","") in replay.AFFIXES:why+=" "+replay.AFFIXES[enemy.affix][2]
	return why

func draw_map_popup() -> void:
	panel(Rect2(780,142,452,378))
	text(Vector2(800,173),"FLOOR %d / REMEMBERED MAP"%floor_number,20,GOLD)
	for coord in links:
		if coord.x<0 or not visited.has(coord):continue
		var start=Vector2(802+coord.x*105,198+coord.y*94)
		for neighbor in links[coord]:
			if neighbor.x<0:continue
			var end=Vector2(802+neighbor.x*105,198+neighbor.y*94)
			draw_line(start+Vector2(47,37),end+Vector2(47,37),Color("547d8e") if is_water_link(coord,neighbor) else Color("786c59"),3)
	for coord in links:
		if coord.x<0:continue
		var at=Vector2(802+coord.x*105,198+coord.y*94)
		panel(Rect2(at,Vector2(94,76)))
		if coord==room:draw_rect(Rect2(at+Vector2(4,4),Vector2(86,68)),ui_color(GOLD),false,2)
		text(at+Vector2(10,19),room_number(coord) if visited.has(coord) else "?",16,GOLD)
		if sanctuary and sanctuary.unlocked("cartographer") and not visited.has(coord):
			var adjacent=false
			for neighbor in links[coord]:
				if visited.has(neighbor):adjacent=true
			if adjacent:
				var chest=rooms[coord].entities.get(rooms[coord].chest,{})
				if chest.get("kind","")=="chest":text(at+Vector2(8,61),"T%d"%(int(chest.tier)+1),12,TEAL)
		if not ember_tree.visible_role(coord):continue
		text(at+Vector2(8,38),roles[coord],12)
		if not visited.has(coord):continue
		var features=map_features(coord)
		text(at+Vector2(8,61)," ".join(features),12,TEAL)
	text(Vector2(802,402),"F: fountain I: iron S: forge G: guard",13)
	text(Vector2(802,425),"Rest: site / K: key / P: supplies" if run_rules>=15 else "K: key / P: supplies / H: healing rune",13)
	text(Vector2(802,448),("Candles: Sun %s > Moon %s"%["lit" if floor_flags.get("sun",false) else "dark","lit" if floor_flags.get("moon",false) else "dark"]) if run_rules<4 or "seal" in floor_flags.get("encounters",[]) else "No candle seal on this floor",13)
	text(Vector2(802,471),"Side passage: "+branch_paths.NAMES.get(floor_flags.get("branch_choice",""),"choose at entrance") if branch_paths and branch_paths.available() else "C: crack W: water T1-3: chest tier",13)
	text(Vector2(802,494),"Blue: flooded / Key: "+("Copper" if floor_keys.has("copper") else "none"),13)

func map_features(coord: Vector2i) -> Array[String]:
	var result: Array[String]=[]
	for entity in rooms[coord].entities.values():
		if entity.kind=="chest":
			result.append("T%d"%(entity.tier+1))
			if dungeon_threads.chest_requirements(entity)!="":result.append("L")
			if entity.style=="wall" and not breaker:result.append("C")
			if entity.style=="water" and not boots:result.append("W")
		elif entity.kind=="wardstone":result.append("H")
		elif entity.kind=="provisions":result.append("P")
		elif entity.kind=="build_cache":result.append("C+")
		elif entity.kind=="rest_site" and not entity.get("used",false):result.append("Rest")
		elif entity.kind=="fountain":result.append("F")
		elif entity.kind=="iron" and "I" not in result:result.append("I")
		elif entity.kind=="dungeon_key":result.append("K")
		elif entity.kind=="reliquary" and not entity.used:result.append("R")
		elif entity.kind=="brazier":result.append("Sun" if entity.rune=="sun" else "Moon")
		elif entity.kind=="salvage":result.append("S")
		elif entity.kind=="shrine" and not entity.get("used",false):result.append("?")
		elif entity.kind=="enemy" and entity.get("gatekeeper",false):result.append("G")
	return result

func draw_character() -> void:
	draw_rect(Rect2(0,0,1280,840),Color(0.02,0.02,0.03,0.95))
	panel(Rect2(120,80,1040,680))
	text(Vector2(158,125),"CHARACTER / JOURNAL",27,GOLD)
	close_button(Rect2(1075,95,45,42),"close_menu")
	text(Vector2(158,175),"Level %d"%character_level,24,GOLD)
	text(Vector2(300,175),"XP %d / %d"%[experience,xp_required(character_level)],22)
	text(Vector2(158,210),"Embers %d / Bank %d"%[shards,bank],18)
	stat_ui.icon("iron",Vector2(500,190),24)
	text(Vector2(532,210),"Iron %d / Fragments %d"%[iron,iron_fragments],18)
	stat_ui.icon("crit_chance",Vector2(158,226),24);text(Vector2(193,247),"%.0f%%"%(crit_chance*100),22)
	stat_ui.icon("crit_mult",Vector2(285,226),24);text(Vector2(320,247),"%.0f%%"%(crit_mult*100),22)
	ui_icon("hammer",Vector2(470,226),24);text(Vector2(505,247),"yes" if breaker else "no",20)
	ui_icon("boots",Vector2(600,226),24);text(Vector2(635,247),"yes" if boots else "no",20)
	button(Rect2(158,264,630,42),"Your build / totals and effects","build_open")
	text(Vector2(158,310),"Copper key: %s / Second Wind: %d / Recall: %d"%["held" if floor_keys.has("copper") else "none",revives_left,recall_charges],18,TEAL)
	button(Rect2(820,300,300,40),"Recall to entrance","recall",false,recall_charges>0)
	text(Vector2(158,358),"RELICS",18,GOLD)
	var description="Hover a relic for its effect."
	for i in range(relics.size()):
		var at=Vector2(158+(i%3)*320,383+(i/3)*27)
		text(at,RELICS[relics[i]][0],16)
		if Rect2(at-Vector2(0,20),Vector2(300,28)).has_point(design_mouse()):description=relic_description(relics[i])
	draw_wrapped(description,Vector2(158,508),900,16,TEAL,2)
	if run_rules>=5:
		replay.draw_bounties()
		front_end.icon_button(Rect2(158,680,300,48),"book","Chronicle","codex")
		front_end.icon_button(Rect2(478,680,300,48),"attack","Last fight recap","recap_open")
		return
	text(Vector2(158,558),"RECENT EVENTS",18,GOLD)
	if run_rules>=4:draw_wrapped(tactics.FLOORS[posmod(floor_number-1,5)][1],Vector2(158,537),900,15,TEAL,1)
	for i in range(mini(6,logs.size())):draw_wrapped(logs[i],Vector2(158,587+i*23),900,15,INK,1)

func draw_settings() -> void:
	draw_rect(Rect2(0,0,1280,840),Color(0.02,0.02,0.03,0.95))
	panel(Rect2(330,160,620,520))
	text(Vector2(370,208),"SETTINGS / CONTROLS",27,GOLD)
	button(Rect2(370,239,540,44),"UI: "+("Gothic stone" if ui_theme==0 else "Warm wood / parchment")+" (T)","toggle_theme")
	button(Rect2(370,301,540,44),"Sound: "+("muted" if muted else "%d%%"%roundi(sound.volume*100)),"sound_toggle")
	button(Rect2(370,360,250,44),"Volume -","volume_down")
	button(Rect2(660,360,250,44),"Volume +","volume_up")
	text(Vector2(370,452),"Arrows/WASD move / E equipment / C character",17)
	text(Vector2(370,484),"H heal / Hover map or press Tab",17)
	text(Vector2(370,516),"F11 fullscreen / M mute / T switch UI theme",17)
	text(Vector2(370,548),"Goal: defeat each floor's boss, then use the stairs.",17)
	button(Rect2(370,585,310,44),"Return to dungeon","close_menu")
	button(Rect2(700,585,210,44),"Credits","show_credits")

func near_forge() -> bool:
	if rooms.is_empty():return false
	for tile in rooms[room].entities:
		if rooms[room].entities[tile].kind=="salvage" and absi(tile.x-pos.x)+absi(tile.y-pos.y)<=1:return true
	return false

func salvage_selected() -> void:
	if not near_forge() or salvage_charges<=0 or selected_item<0 or selected_item>=inventory.size() or selected_item in equipped.values():return
	if inventory[selected_item].get("kept",false):log_line("Unprotect this item before scrapping it.");return
	var index=selected_item
	var amount=int(inventory[index].rarity)+1+(ember_tree.rank("salvage_master") if run_rules>=5 else 0)
	iron_fragments+=amount
	iron+=int(iron_fragments/3)
	iron_fragments%=3
	salvage_charges-=1
	inventory.remove_at(index)
	for slot in equipped:
		if equipped[slot]>index:equipped[slot]-=1
	selected_item=mini(index,inventory.size()-1)
	if selected_item>=0:equipment_slot=inventory[selected_item].slot
	recalculate_stats()
	sfx("pickup")
	log_line("Scrapped gear: +%d fragments. %d uses remain."%[amount,salvage_charges])

func draw_credits() -> void:
	draw_rect(Rect2(0,0,1280,840),Color(0.02,0.02,0.03,0.95))
	panel(Rect2(150,110,980,620))
	text(Vector2(190,160),"ART / AUDIO / FONT CREDITS",28,GOLD)
	text(Vector2(190,211),"Pixel icons: game creator; Kyrise (2018), CC BY 4.0",22)
	text(Vector2(190,243),"kyrise.itch.io/kyrises-free-16x16-rpg-icon-pack",18,TEAL)
	text(Vector2(190,273),"creativecommons.org/licenses/by/4.0/",18)
	text(Vector2(190,303),"Original PNGs renamed; artwork pixels unchanged.",18)
	text(Vector2(190,353),"DungeonTileset II and DungeonUI: 0x72 (Robert), CC0",22)
	text(Vector2(190,385),"0x72.itch.io / Cropped tiles and recolored Gothic UI frame.",18,TEAL)
	text(Vector2(190,435),"Pixel Operator font: Jayvee Enaguas (HarvettFox96), CC0",22)
	text(Vector2(190,467),"dafont.com/pixel-operator.font",18,TEAL)
	text(Vector2(190,517),"Additional pixel glyphs and sound effects: Kenney, CC0",22)
	text(Vector2(190,549),"kenney.nl / 1-Bit Pack, RPG Audio, Interface Sounds",18,TEAL)
	text(Vector2(190,594),"Music: Ruhinre and FazeDevWater / CC0",20,TEAL)
	button(Rect2(190,640,900,44),"Back to settings / Esc","close_credits")

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST and session:
		if session.checkpoint() and session.save_preferences():get_tree().quit()
		else:session.pause();queue_redraw()
	elif what==NOTIFICATION_APPLICATION_FOCUS_OUT and session and session.enabled:
		if controls:controls.clear_held()
		session.pause()

func actor_texture(id: String) -> Texture2D:
	var key=id+"_run" if id=="player" and movement and movement.is_running() else id
	if animation_sets.has(key):return animation_sets[key][int(pulse*(10 if key.ends_with("run") else 4))%4]
	return textures[id]

func load_animations() -> void:
	for id in ["player","player_run","mossling","husk","bat","boss_iron","boss_tide","boss_ash"]+preload("res://enemy_roster.gd").EXTRA:
		var frames=[]
		for frame in range(4):
			var file="res://assets/animations/%s_%d.png"%[id,frame]
			if ResourceLoader.exists(file):frames.append(load(file))
		if frames.size()==4:animation_sets[id]=frames
