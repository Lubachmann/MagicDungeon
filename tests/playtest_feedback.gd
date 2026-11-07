extends SceneTree
const Stats=preload("res://build_stats.gd")
var g
var checks=0
var failures=[]
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	g=load("res://main.tscn").instantiate();g.save_path="res://tests/.feedback011.json";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false)
	g.new_run(42)
	check(g.inventory.is_empty() and g.equipped.is_empty() and g.combat_build().weapon=="unarmed","A real new run has no starting weapon or sword passive")
	check(g.attack==5,"Unarmed base attack is visible without hidden equipment")
	check(g.session.valid(g.session.snapshot()),"Empty inventory saves correctly")
	g.open_equipment();g.queue_redraw();await process_frame
	check(not g.build_view.equipment_details,"Inventory defaults to the total stat comparison")
	g.action("compare_details");check(g.build_view.equipment_details,"Item-only stats remain available")
	g.action("compare_details");check(not g.build_view.equipment_details,"Total stats can be restored")
	var chest: Vector2i=g.rooms[Vector2i.ZERO].chest
	check(g.rooms[Vector2i.ZERO].entities[chest].item.slot=="weapon","A random starting weapon is in the entrance chest")
	g.open_chest(chest);g.action("loot_inventory");g.action("equip_selected");g.action("close_equipment");check(g.equipped.has("weapon") and g.attack>5,"The first found weapon adds real attack")
	g.base_elements={"fire":0,"ice":0,"acid":2,"poison":0};g.relics=[];g.recalculate_stats()
	for id in g.RELICS:
		var before=var_to_bytes([g.inventory,g.equipped,g.bonus,g.base_elements,g.relics,g.hp,g.rng.state]);var preview=Stats.upgrade_preview(g,id)
		check(before==var_to_bytes([g.inventory,g.equipped,g.bonus,g.base_elements,g.relics,g.hp,g.rng.state]),"Upgrade preview is pure: "+id)
		var relics=g.relics.duplicate();g.grant_relic(id);var actual=Stats.calculate(g)
		check(preview.elements==actual.elements and preview.attack==actual.attack and preview.fire==actual.fire and preview.ice==actual.ice and preview.acid==actual.acid and preview.crit_chance==actual.crit_chance and preview.crit_mult==actual.crit_mult and preview.speed==actual.speed,"Upgrade preview matches actual outcome: "+id)
		g.relics=relics;g.recalculate_stats()
	check(Stats.upgrade_preview(g,"bulwark").elements.acid==3,"Acid upgrade previews 2 + 1 = 3")
	for id in g.UPGRADE_INFO:
		var p=Stats.upgrade_preview(g,id,true);var base=g.base_elements.duplicate();var bonus=g.bonus.duplicate();g.apply_blessing(id);var a=Stats.calculate(g);check(p.attack==a.attack and p.armor==a.armor and p.speed==a.speed and p.elements==a.elements and p.crit_chance==a.crit_chance and p.crit_mult==a.crit_mult,"Blessing preview matches actual: "+id);g.base_elements=base;g.bonus=bonus;g.recalculate_stats()
	g.feedback.clear();g.gain_xp(g.xp_required(g.character_level));check(g.feedback.level_time>0 and g.pending_levels>0,"Level gains produce a visible notification")
	var e=g.make_enemy(0,0);g.rooms[g.room].entities[Vector2i(3,5)]=e;var xp=g.experience;var ember=g.shards;g.defeat_enemy(Vector2i(3,5),e)
	check(g.feedback.rewards.xp==g.enemy_xp(e) and g.feedback.rewards.ember==g.shards-ember,"Reward feedback uses actual XP and ember amounts")
	g.feedback.reward(2,3,1);check(g.feedback.rewards.flasks==1,"Flask rewards are included")
	check(g.feedback.impact_strength(100)>g.feedback.impact_strength(5),"Hit intensity scales with damage")
	g.fight=g.make_enemy(0,0);g.fight.position=Vector2i(7,5);g.battle=g.Combat.begin(g.fight,100,100,30,1,1,[],g.combat_build());var hit=g.Combat.step(g.battle);g.feedback.hit(hit,g.battle)
	check(g.feedback.hitstop>0 and g.feedback.shake_time>0,"Heavy hits create brief pauses and shake")
	g.session.preferences.reduced_flashes=true;g.feedback.tick(0.001);check(g.feedback.camera_offset()==Vector2.ZERO and g.feedback.hitstop==0,"Reduced effects disables shake and pauses")
	g.session.preferences.reduced_flashes=false
	g.mode="relic";g.choices=["bulwark","venom","haste"];g.reward_level=g.character_level;g.queue_redraw();await process_frame
	var options=g.choices.duplicate();g.action("build_open");g.action("build_close");check(g.mode=="relic" and g.choices==options,"Build inspection returns to the pending upgrade without consuming it")
	g.floor_flags.sun=false;g.floor_flags.moon=false
	g.dungeon_threads.touch(Vector2i(3,4),{"kind":"brazier","rune":"moon"});check(not g.floor_flags.moon,"Moon cannot be lit before Sun")
	g.dungeon_threads.touch(Vector2i(3,4),{"kind":"brazier","rune":"sun"});g.dungeon_threads.touch(Vector2i(3,4),{"kind":"brazier","rune":"moon"});check(g.floor_flags.sun and g.floor_flags.moon,"Both candles open the seal in order")
	g.dungeon_threads.touch(Vector2i(3,4),{"kind":"brazier","rune":"sun"});check("unlocked" in g.toast,"Revisiting a lit candle reports completed progress")
	for large in [false,true]:
		g.session.preferences.large_text=large
		for mode in ["play","relic","equipment","loot","character"]:
			g.mode=mode;g.last_loot_index=0;g.selected_item=0;g.queue_redraw();await process_frame
	print("PLAYTEST FEEDBACK: %d checks / %d failures"%[checks,failures.size()])
	for message in failures:print("FAIL: "+message)
	g.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
