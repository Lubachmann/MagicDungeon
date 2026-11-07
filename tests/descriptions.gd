extends SceneTree
var checks=0
var failures=[]
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:failures.append(message)
func _initialize() -> void:call_deferred("run")
func lines(value: String,font: Font,size: int,width: float) -> int:
	var count=1;var line=""
	for word in value.split(" "):
		if font.get_string_size(line+" "+word,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width and line!="":count+=1;line=word
		else:line+=(" " if line!="" else "")+word
	return count
func run() -> void:
	var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.copycheck.json";root.add_child(g);preload("res://tools/test_equipment.gd").arm(g);await process_frame;g.session.enabled=false;g.new_run(42);preload("res://tools/test_equipment.gd").arm(g);g.set_process(false)
	g.skills={"treasure_hunter":3,"gilded_touch":2};g.run_skills={}
	var rare=float(g.CHEST_ODDS[0][1])+4.5
	check(g.ember_tree.describe("treasure_hunter").contains("%.1f%% → %.1f%%"%[rare,rare+1.5]),"Prospector previews purchased ranks, not the previous run snapshot")
	for id in g.ember_tree.NODES:
		var text=g.ember_tree.describe(id)
		check(not text.contains("percentage") and not text.contains("potency"),"Tree uses plain numbers: "+id)
		check(lines(text,g.font,20,240)<=7,"Tree description fits at large text size: "+id)
	g.elements={"fire":0,"ice":0,"acid":0,"poison":0};g.gear_stats={};g.run_skills={}
	check(g.choice_ui.explain("poison",true).contains("18.0% less enemy damage"),"One Poison stack explains its damage reduction")
	check(g.choice_ui.explain("acid",true).contains("0.0 → 4.0"),"Acid separates per-hit removal and per-enemy limit")
	g.run_skills={"poison_mastery":2};check(g.choice_ui.explain("venom").contains("19.8%"),"Poison description includes mastery")
	g.elements.poison=3;g.gear_stats={"poison_weak":0.3};check(g.choice_ui.explain("venom").contains("65.0% → 65.0%"),"Capped Poison does not promise extra reduction")
	g.elements={"fire":0,"ice":0,"acid":0,"poison":0};g.gear_stats={};g.run_skills={}
	for id in g.RELICS:
		var text=g.choice_ui.explain(id)
		check(lines(text,g.font,20,325)<=11,"Upgrade details fit at large text size: "+id)
		check(g.choice_ui.summary(id)!="Upgrade","Each card has a concrete summary: "+id)
	check(g.choice_ui.explain("fire",true).contains("3s burn"),"Fire explains burn duration")
	check(g.choice_ui.explain("cinder").contains("5s burn"),"Cinder shows the longer burn duration")
	g.mode="skills";g.ember_tree.selected="treasure_hunter";g.queue_redraw();await process_frame
	g.mode="relic";g.choices=["venom","black_ice","wildfire"];g.menu_keyboard=true;g.session.focused=1;g.queue_redraw();await process_frame
	g.queue_free();await process_frame
	if failures.is_empty():print("PASS: %d description checks; all tree and upgrade text fits, loot odds match ranks, Poison mastery/caps match combat."%checks);quit(0)
	else:
		for message in failures:push_error(message)
		quit(1)
