extends SceneTree
var g
var failures=[]
var checks=0
func check(ok:bool,why:String):
 checks+=1
 if not ok:failures.append(why)
func _initialize():call_deferred("run")
func key(code:int,pressed:bool=true,echo:bool=false):
 var e=InputEventKey.new();e.keycode=code;e.pressed=pressed;e.echo=echo;g.controls.handle(e)
func clear_anim():
 if g.movement:g.movement.kill()
func run():
 g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-onboarding";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true;g.skills={};g.new_run(42)
 # Create a clear corridor independent of procedural decoration.
 g.room=Vector2i.ZERO;g.pos=Vector2i(2,5);g.mode="play";g.rooms[g.room].walls.clear();g.rooms[g.room].entities.clear()
 key(KEY_RIGHT);check(g.pos==Vector2i(3,5),"Pressing a movement key moves one tile")
 clear_anim();g.controls.tick(0.25);check(g.pos==Vector2i(4,5),"Holding repeats movement")
 clear_anim();g.controls.tick(0.15);check(g.pos==Vector2i(5,5),"Holding continues at a paced interval")
 key(KEY_RIGHT,false);clear_anim();g.controls.tick(1.0);check(g.pos==Vector2i(5,5),"Releasing stops movement")
 key(KEY_LEFT);clear_anim();g.mode="fight";g.controls.tick(0.2);g.mode="play";g.controls.tick(1.0);check(g.pos==Vector2i(4,5) and g.controls.held_keys.is_empty(),"Leaving gameplay clears held input")
 g.new_run(91);g.run_rules=19;g.inventory.clear();g.equipped.clear();g.room=Vector2i.ZERO;g.pos=Vector2i(2,5);g.rooms[g.room].walls.clear();g.rooms[g.room].entities.clear()
 var blocking_item=g.make_gear("weapon",1,0);g.rooms[g.room].entities[Vector2i(3,5)]={"kind":"chest","tier":0,"style":"stash","guardian":Vector2i(-1,-1),"item":blocking_item}
 key(KEY_RIGHT);check(g.mode=="loot","Holding into a chest opens its loot screen")
 g.controls.tick(0.2);g.action("loot_keep");clear_anim();g.controls.tick(1.0)
 check(g.pos==Vector2i(3,5) and g.controls.held_keys.is_empty(),"Held movement does not continue after a loot screen")
 g.buttons.clear();g.buttons.append_array([{"id":"a","rect":Rect2(0,0,100,50)},{"id":"b","rect":Rect2(200,0,100,50)},{"id":"c","rect":Rect2(0,100,100,50)},{"id":"d","rect":Rect2(200,100,100,50)}])
 g.session.focused=0;g.controls.navigate_spatial(Vector2i.RIGHT);check(g.buttons[g.session.focused].id=="b","Right chooses the button on the right")
 g.controls.navigate_spatial(Vector2i.DOWN);check(g.buttons[g.session.focused].id=="d","Down chooses the button below")
 g.controls.navigate_spatial(Vector2i.LEFT);check(g.buttons[g.session.focused].id=="c","Left chooses the button on the left")
 g.controls.navigate_spatial(Vector2i.UP);check(g.buttons[g.session.focused].id=="a","Up chooses the button above")
 g.new_run(12);g.run_rules=19;g.inventory.clear();g.equipped.clear();g.inventory.append(g.make_gear("weapon",1,0));g.last_loot_index=0;g.session.focused=12;g.mode="loot";g.queue_redraw();await process_frame;await process_frame
 check(g.session.focused==0,"A newly opened dialog starts with its first action focused")
 check(g.buttons.size()==2 and g.buttons[0].id=="loot_equip" and g.buttons[1].id=="loot_keep","Loot dialog offers equip and keep actions")
 g.controls.back();check(g.mode=="play" and g.inventory.size()==1 and not g.equipped.has("weapon") and "kept in your bag" in g.toast,"Escape keeps item and gives clear feedback")
 g.mode="loot";g.last_loot_index=0;g.loot_window.start();g._process(30.0)
 check(g.mode=="loot" and g.inventory.size()==1,"Pickup waits for the player to choose")
 g.mode="loot";g.last_loot_index=0;g.loot_window.start();key(KEY_1)
 check(g.mode=="play" and g.equipped.get("weapon",-1)==0,"1 equips the new item directly")
 g.equipped.clear();g.recalculate_stats();g.mode="loot";g.loot_window.start();key(KEY_2)
 check(g.mode=="play" and not g.equipped.has("weapon") and g.inventory.size()==1,"2 keeps the new item in the bag")
 g.mode="relic";g.choices=["venom","frost","cinder","solvent"];g.reward_level=4;g.queue_redraw();await process_frame;await process_frame
 g.session.focused=0;g.controls.navigate_spatial(Vector2i.DOWN);check(g.buttons[g.session.focused].id=="relic1","Down moves to the next level-up choice")
 g.controls.navigate_spatial(Vector2i.DOWN);check(g.buttons[g.session.focused].id=="relic2","Down follows the vertical list")
 g.controls.navigate_spatial(Vector2i.UP);check(g.buttons[g.session.focused].id=="relic1","Up moves to the choice directly above")
 # Start with the shared guide preference already completed: each new character gets its own tutorial.
 g.career=g.replay.new_career();g.session.preferences.tutorial_done=true;g.session.enabled=true;g.session.active=false
 check(g.session.start_run(false) and g.guided.active() and g.mode=="play","A new character starts the interactive guide")
 g.queue_redraw();await process_frame;await process_frame
 check(g.buttons.any(func(b):return b.id=="guide_skip"),"Tutorial prompt is visible with a skip action")
 var data=g.rooms[Vector2i.ZERO];check(g.equipped.has("weapon"),"Tutorial starts with an equipped starter weapon")
 g.guided.update();check(g.run_metrics.guide_step==1,"The starter weapon advances the guide to inspection")
 var enemy_tile=Vector2i(-1,-1)
 for tile in data.entities:
  if data.entities[tile].kind=="enemy":enemy_tile=tile;break
 g.mode="inspect";g.inspected_tile=enemy_tile;g.guided.update();check(g.run_metrics.guide_step==2,"Inspecting the enemy advances the guide")
 g.mode="play";g.pos=enemy_tile+Vector2i.LEFT;g.move_player(Vector2i.RIGHT);check(g.mode=="fight" and g.run_metrics.guide_step==3,"Entering combat advances the guide")
 g.defeat_enemy(enemy_tile,g.fight);g.mode="play";check(g.run_metrics.guide_step==4,"Winning prompts the flask pickup")
 var potion=Vector2i(-1,-1)
 for tile in data.entities:
  if data.entities[tile].kind=="potion":potion=tile;break
 check(potion.x>=0,"A flask is placed in the starting room")
 g.pos=potion+Vector2i.LEFT;data.walls.erase(g.pos);g.move_player(Vector2i.RIGHT)
 check(not g.guided.active() and g.career.guided_done,"Picking up the flask completes the guide")
 check(g.session.checkpoint() and g.session.continue_run() and g.career.guided_done,"Completed tutorial remains completed after loading")
 g.session.enabled=false
 g.career=g.replay.new_career();g.new_run(88);g.guided.start();key(KEY_F1)
 check(not g.guided.active() and g.career.guided_done,"F1 skips the guide for the current character")
 g.career=g.replay.new_career();g.new_run(89);g.guided.start();g.guided.potion_found();g.run_metrics.guide_step=3;g.guided.enemy_defeated()
 check(not g.guided.active() and g.career.guided_done,"Picking up the flask early does not leave the guide stuck")
 for suffix in ["", ".tmp", ".run", ".run.bak", ".run.tmp"]:DirAccess.remove_absolute(g.save_path+suffix)
 print(JSON.stringify({"checks":checks,"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
