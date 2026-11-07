extends SceneTree
var checks=0
var failures=[]
func check(value: bool,msg: String) -> void:
	checks+=1
	if not value:failures.append(msg)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.contextui.json";root.add_child(g);preload("res://tools/test_equipment.gd").arm(g);await process_frame;g.session.enabled=false;g.new_run(12);preload("res://tools/test_equipment.gd").arm(g);g.set_process(false)
	g.mode="expedition";g.career.wins=0;g.replay.draft={"mode":"standard","vows":{}}
	var rng_before=g.rng.state;g.action("run_mode:endless")
	check(g.ui_help.topic=="endless" and g.replay.draft.mode=="standard","Locked Endless explains unlock without selecting it")
	check(g.rng.state==rng_before and g.mode=="expedition","Help leaves mode and world randomness unchanged")
	var event=InputEventKey.new();event.pressed=true;event.keycode=KEY_ENTER;g._unhandled_input(event)
	check(g.ui_help.topic=="" and g.mode=="expedition","Dismissing help does not trigger the background menu")
	g.action("vow:fury");check(g.ui_help.topic=="vows" and g.replay.draft.vows.is_empty(),"Locked Vows explain rather than altering difficulty")
	g.action("help:close");g.career.wins=1;g.replay.draft.mode="daily";g.action("vow:iron")
	check(g.ui_help.topic=="daily_vows" and g.replay.draft.vows.is_empty(),"Daily Vows have their own explanation")
	g.action("help:close");g.replay.draft.mode="standard";g.action("vow:iron");check(g.replay.draft.vows.iron==1,"Unlocked Vows still work")
	g.action("run_mode:endless");check(g.replay.draft.mode=="endless","Unlocked Endless still works")
	g.new_run(12);preload("res://tools/test_equipment.gd").arm(g);g.shards=123;g.mode="loot";g.inventory.append(g.Gear.make("weapon",3,2,["vampirism","speed"],"dagger"));g.last_loot_index=g.inventory.size()-1;g.last_chest_tier=2
	g.queue_redraw();await process_frame;await process_frame
	check(g.buttons.size()>=2 and g.buttons[-2].id=="loot_equip" and g.buttons[-1].id=="loot_keep", "Pickup offers equip and keep actions")
	check(Rect2(328,172,624,528).encloses(g.buttons[0].rect), "Pickup action stays inside dungeon viewport")
	g.action("loot_inventory");check(g.mode=="equipment" and g.selected_item==g.last_loot_index,"Compare selects the new item")
	g.action("help:scrap");check(g.ui_help.content()[0]=="SCRAP SPARE GEAR","Scrap has a direct explanation")
	var old_equipped=g.equipped.duplicate();g._unhandled_input(event)
	check(g.ui_help.topic=="" and g.equipped==old_equipped,"Enter closes help without equipping anything")
	g.room=Vector2i.ZERO;g.pos=Vector2i(2,5);g.rooms[g.room].entities[Vector2i(3,5)]={"kind":"salvage"}
	g.run_skills["salvage_master"]=2;var fragments=g.iron_fragments;var iron=g.iron;g.action("salvage_selected")
	check(g.iron*3+g.iron_fragments==iron*3+fragments+5,"Scrap reward includes rarity and skill bonus")
	check(g.salvage_charges==2,"Scrap consumes exactly one floor use")
	g.mode="play";g.shards=123456;g.queue_redraw();await process_frame
	check(g.ui_help.EMBERS.position.y<45,"Ember counter lives in the top HUD")
	g.action("help:equipment");g.new_run(44);preload("res://tools/test_equipment.gd").arm(g);check(g.ui_help.topic=="","A new run cannot inherit an old help popup")
	g.queue_free();await process_frame
	if failures.is_empty():print("PASS: %d context UI checks; unlock messages, Daily restrictions, modal isolation, large loot choices, scrap yields and HUD state."%checks);quit(0)
	else:
		for message in failures:push_error(message)
		quit(1)
