extends SceneTree
var failures=[]
func check(ok:bool, message:String):
 if not ok:failures.append(message)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-levelup-presentation";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.new_run(27)
 g.reward_level=2;g.offer_relic();check(g.mode=="relic" and not g.choice_ui.level_ready(),"A level-up starts with the announcement")
 g.queue_redraw();await process_frame;await process_frame
 check(not g.buttons.any(func(b):return str(b.id).begins_with("relic")),"Choices are hidden during the announcement")
 g.choice_ui.tick(0.5);check(not g.choice_ui.level_ready(),"The announcement remains visible before choices")
 g.choice_ui.tick(0.6);g.menu_keyboard=false;g.choice_ui.pointer=Vector2(100,100);g.queue_redraw();await process_frame;await process_frame
 check(g.choice_ui.level_ready() and g.choice_ui.preview_index==0,"The first choice is previewed by default after the announcement")
 var cards=g.buttons.filter(func(b):return str(b.id).begins_with("relic") and str(b.id).trim_prefix("relic").is_valid_int())
 check(cards.size()>=3,"Level-up choices are available after the animation")
 if cards.size()>=3:
  check(cards[0].rect.position.x==cards[1].rect.position.x and cards[0].rect.position.y<cards[1].rect.position.y,"Choices form a vertical list")
  g.choice_ui.pointer=cards[1].rect.get_center();g.queue_redraw();await process_frame;await process_frame
  check(g.choice_ui.preview_index==1,"Hovering reveals the corresponding details")
 g.choice_ui.start_level();g.controls.confirm();check(g.choice_ui.level_ready() and g.mode=="relic","Confirm skips the animation without selecting an upgrade")
 print(JSON.stringify({"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
