extends SceneTree
const Rules=preload("res://element_rules.gd")
var failures=[]
func check(ok: bool,message: String) -> void:
 if not ok:failures.append(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-element-clarity";root.add_child(g);await process_frame
 g.session.enabled=false;g.set_process(false);g.muted=true;g.skills={};g.new_run(42)
 var build={"fire":1,"ice":1,"acid":1,"poison":1,"element_interval_scale":1.0,"burn_duration":3.0,"freeze_cooldown":8.0}
 check(Rules.describe("poison",build,10).contains("3 stacks deal 1.5 damage every 0.5s"),"Poison gives a correct worked example")
 check(Rules.describe("fire",build,10).contains("1.0 damage/s"),"Fire description uses actual attack and potency")
 check(Rules.describe("ice",build,10).contains("10 stacks") and Rules.describe("acid",build,10).contains("1 armor"),"Frost and Acid rules include their main effects")
 g.session.preferences.large_text=true
 for id in g.choice_ui.STACKS:
  var sentence=g.relic_description(id)
  check(g.font.get_string_size(sentence,HORIZONTAL_ALIGNMENT_LEFT,-1,g.readable_size(18)).x<=1120,"Upgrade effect fits on its line: "+id)
 g.mode="relic";g.choices=["black_ice","venom","cinder"];g.menu_keyboard=false;g.choice_ui.pointer=Vector2(500,250);g.queue_redraw();await process_frame;await process_frame
 check(g.choice_ui.preview_index==1,"Mouse hover selects second upgrade")
 g.choice_ui.pointer=Vector2(650,680);g.queue_redraw();await process_frame;await process_frame
 check(g.choice_ui.preview_index==1,"Moving to element help keeps the selected upgrade")
 print(JSON.stringify({"failures":failures}))
 g.free();quit(0 if failures.is_empty() else 1)
