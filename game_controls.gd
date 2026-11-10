extends RefCounted
const DEFAULTS={"up":KEY_W,"down":KEY_S,"left":KEY_A,"right":KEY_D,"inventory":KEY_E,"journal":KEY_C,"heal":KEY_H,"map":KEY_TAB,"inspect":KEY_I,"recall":KEY_R,"pause":KEY_ESCAPE}
var bindings=DEFAULTS.duplicate()
var capture=""
var axis_x=0
var axis_y=0
var held_keys=[]
var repeat_left=0.0
var focus_mode=""
var g
func _init(game):g=game
func restore(saved) -> void:
	if not saved is Dictionary:return
	var restored={};var values=[]
	for key in DEFAULTS:
		if not saved.has(key):continue
		var value=saved[key]
		if not value is int or value<=0 or value in values:return
		restored[key]=value;values.append(value)
	for key in DEFAULTS:
		if restored.has(key):continue
		var value=DEFAULTS[key]
		if value in values:
			for candidate in range(KEY_A,KEY_Z+1):
				if candidate not in values:value=candidate;break
		restored[key]=value;values.append(value)
	bindings=restored
func label(command: String) -> String:return OS.get_keycode_string(bindings[command])
func bind(command: String,key: int) -> bool:
	if key in [KEY_ESCAPE,KEY_F1,KEY_F11,KEY_T,KEY_M,KEY_MINUS,KEY_EQUAL,KEY_ENTER,KEY_SPACE,KEY_1,KEY_2,KEY_3,KEY_4] or key<=0:return false
	for other in bindings:
		if bindings[other]==key:bindings[other]=bindings[command];break
	bindings[command]=key
	g.session.save_preferences()
	return true
func step(direction: Vector2i) -> void:
	if g.mode in ["inspect","bomb"]:
		g.inspected_tile=(g.inspected_tile+direction).clamp(Vector2i.ZERO,Vector2i(g.RW-1,g.RH-1))
	elif g.mode=="play":
		if not g.movement or not g.movement.is_running():g.move_player(direction)
	else:navigate_spatial(direction)
func clear_held() -> void:
	held_keys.clear();repeat_left=0.0
func direction_for(key: int) -> Vector2i:
	if key in [KEY_UP,bindings.up]:return Vector2i.UP
	if key in [KEY_DOWN,bindings.down]:return Vector2i.DOWN
	if key in [KEY_LEFT,bindings.left]:return Vector2i.LEFT
	if key in [KEY_RIGHT,bindings.right]:return Vector2i.RIGHT
	return Vector2i.ZERO
func tick(delta: float) -> void:
	if g.mode!="play":clear_held();return
	if held_keys.is_empty():return
	repeat_left-=delta
	if repeat_left>0 or (g.movement and g.movement.is_running()):return
	var direction=direction_for(int(held_keys.back()))
	if direction!=Vector2i.ZERO:step(direction)
	repeat_left=0.14
func sync_focus() -> void:
	if focus_mode!=g.mode:
		focus_mode=g.mode;g.session.focused=0
func navigate(amount: int) -> void:
	if g.buttons.is_empty():return
	g.session.focused=posmod(g.session.focused+amount,g.buttons.size())
	g.menu_keyboard=true
func navigate_spatial(direction: Vector2i) -> void:
	if g.buttons.is_empty():return
	var current=clampi(g.session.focused,0,g.buttons.size()-1)
	var origin: Rect2=g.buttons[current].rect
	var center=origin.get_center();var best=-1;var best_score=INF
	for i in range(g.buttons.size()):
		if i==current:continue
		var rect: Rect2=g.buttons[i].rect;var delta=rect.get_center()-center
		var forward=delta.dot(Vector2(direction))
		if forward<=0.01:continue
		var perpendicular=absf(delta.y) if direction.x!=0 else absf(delta.x)
		var half_span=(origin.size.y+rect.size.y)/2.0 if direction.x!=0 else (origin.size.x+rect.size.x)/2.0
		var gap=maxf(0.0,perpendicular-half_span)
		var score=forward+gap*3.0+perpendicular*0.05
		if score<best_score:best=i;best_score=score
	if best>=0:g.session.focused=best
	g.menu_keyboard=true
func confirm() -> void:
	if g.mode=="relic" and g.choice_ui and not g.choice_ui.level_ready():g.choice_ui.skip_level_intro();return
	if g.mode=="fight":g.action("combat_speed_toggle");return
	if g.mode=="play":g.action("equipment");return
	if g.mode=="bomb":g.throw_bomb(g.inspected_tile);return
	if not g.buttons.is_empty():g.action(g.buttons[clampi(g.session.focused,0,g.buttons.size()-1)].id)
func back() -> void:
	match g.mode:
		"pause":g.mode=g.session.paused_from
		"title":pass
		"confirm_new":g.mode="title"
		"profiles":
			if g.profiles.pending_delete>=0:g.action("profile_delete_cancel")
			else:g.mode="title"
		"expedition":g.action("expedition_back")
		"codex":g.action("codex_back")
		"skills":g.action("skills_back")
		"curse":g.mode="play"
		"runes","vault_reward":g.action("runes_leave")
		"infuse":g.action("infuse_back")
		"controls":capture="";g.mode="settings"
		"credits":g.mode="settings"
		"settings":
			if g.front_end.display_pending:g.action("display_revert")
			else:g.mode=g.session.settings_from
		"tutorial":g.action("tutorial_skip")
		"equipment":g.action("close_equipment")
		"character":g.action("close_menu")
		"decision":g.action("decision_leave")
		"branch":g.action("branch_leave")
		"sanctuary":g.action("sanctuary_back")
		"smithy":g.action("smithy_back")
		"loadout":g.action("loadout_back")
		"extract":g.action("extract_cancel")
		"discovery":g.action("discovery_continue")
		"ending":pass
		"build":g.action("build_close")
		"recap":g.action("recap_close")
		"imprint":g.action("transfer_close")
		"forge":g.action("forge_back")
		"loot":g.action("loot_keep")
		"shrine":g.action("shrine_leave")
		"inspect","bomb":g.mode="play"
		_:g.session.pause()
	g.session.focused=0
func command(name: String) -> void:
	match name:
		"up":step(Vector2i.UP)
		"down":step(Vector2i.DOWN)
		"left":step(Vector2i.LEFT)
		"right":step(Vector2i.RIGHT)
		"pause":back()
		"map":
			if g.mode in ["play","fight","inspect"]:g.map_pinned=not g.map_pinned
		"inspect":
			if g.mode=="inspect":g.mode="play"
			elif g.mode=="play":g.mode="inspect";g.inspected_tile=g.pos+g.facing
		"inventory":
			if g.mode=="equipment":g.action("close_equipment")
			elif g.mode=="play":g.action("equipment")
		"journal":
			if g.mode=="character":g.action("close_menu")
			elif g.mode=="play":g.action("character")
		"recall":g.action("recall")
		"heal":g.action("heal")
func handle(event: InputEvent) -> bool:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		g.menu_keyboard=false
		return false
	if event is InputEventJoypadMotion:
		var value=signi(int(event.axis_value*100)) if absf(event.axis_value)>0.6 else 0
		if event.axis==JOY_AXIS_LEFT_X:
			if value!=axis_x and value!=0:step(Vector2i(value,0))
			axis_x=value
		elif event.axis==JOY_AXIS_LEFT_Y:
			if value!=axis_y and value!=0:step(Vector2i(0,value))
			axis_y=value
		return true
	if event is InputEventJoypadButton and event.pressed:
		g.menu_keyboard=true
		match event.button_index:
			JOY_BUTTON_DPAD_UP:step(Vector2i.UP)
			JOY_BUTTON_DPAD_DOWN:step(Vector2i.DOWN)
			JOY_BUTTON_DPAD_LEFT:step(Vector2i.LEFT)
			JOY_BUTTON_DPAD_RIGHT:step(Vector2i.RIGHT)
			JOY_BUTTON_A:confirm()
			JOY_BUTTON_B:back()
			JOY_BUTTON_START:back()
			JOY_BUTTON_X:command("inspect")
			JOY_BUTTON_Y:command("map")
			JOY_BUTTON_LEFT_SHOULDER:command("heal")
		return true
	if not event is InputEventKey:return false
	if not event.pressed:
		held_keys.erase(event.keycode)
		return false
	if event.echo:return true
	if g.mode=="codex" and g.replay.codex_search_active:
		if event.keycode in [KEY_ESCAPE,KEY_ENTER,KEY_KP_ENTER]:g.replay.codex_search_active=false
		elif event.keycode==KEY_BACKSPACE:g.replay.codex_search=g.replay.codex_search.left(maxi(0,g.replay.codex_search.length()-1));g.replay.codex_list_page=0
		elif event.unicode>=32 and g.replay.codex_search.length()<24:g.replay.codex_search+=char(event.unicode);g.replay.codex_list_page=0
		return true
	if capture=="" and event.keycode==KEY_F1:
		if g.guided and g.guided.active():g.action("guide_skip");return true
		if not preload("res://early_journey.gd").info(g).is_empty():g.action("journey_skip");return true
	if capture=="" and g.mode=="play" and direction_for(event.keycode)!=Vector2i.ZERO:
		held_keys.erase(event.keycode);held_keys.append(event.keycode);repeat_left=0.24
		g.menu_keyboard=true;step(direction_for(event.keycode));return true
	g.menu_keyboard=true
	if capture!="":
		if event.keycode==KEY_ESCAPE:capture="";return true
		if bind(capture,event.keycode):capture=""
		return true
	if event.keycode==KEY_ESCAPE:back();return true
	if g.mode=="loot" and event.keycode==KEY_1:g.action("loot_equip");return true
	if g.mode=="loot" and event.keycode==KEY_2:g.action("loot_keep");return true
	if g.mode=="loot" and event.keycode==bindings.inventory:g.action("loot_inventory");return true
	if event.keycode in [KEY_ENTER,KEY_SPACE] and g.mode not in ["play","inspect"]:
		confirm();return true
	if event.keycode==KEY_TAB and g.mode not in ["play","fight","inspect","bomb"]:
		navigate(-1 if event.shift_pressed else 1);return true
	var command_name=""
	for key in bindings:
		if bindings[key]==event.keycode:command_name=key;break
	if event.keycode in [KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]:command_name={KEY_UP:"up",KEY_DOWN:"down",KEY_LEFT:"left",KEY_RIGHT:"right"}[event.keycode]
	if command_name!="":
		if command_name in ["up","down","left","right"] or g.mode in ["play","inspect","bomb","fight","equipment","character"]:
			command(command_name);return true
	if event.keycode in DEFAULTS.values() and g.mode in ["play","fight","inspect","bomb"]:return true
	return false
