extends SceneTree
const Journey=preload("res://early_journey.gd")
const SAVE="res://tests/.early_journey"
var g
var checks=0
var failures=[]
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 for suffix in ["", ".tmp", ".run", ".run.bak", ".run.tmp"]:
  if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(SAVE+suffix)
 g=load("res://main.tscn").instantiate();g.save_path=SAVE;root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true
 for seed in range(20):
  g.career=g.replay.new_career();g.replay.draft.mode="standard";g.skills={};g.new_run(seed)
  check(Journey.info(g).stage=="inspect","Fresh character starts with a weapon lesson")
  g.open_equipment();check(Journey.progress(g).inspected,"Inspecting equipment records the milestone")
  g.mode="play";var tile=Vector2i(3,5);var enemy=g.make_enemy(0,0);g.rooms[g.room].entities[tile]=enemy;g.defeat_enemy(tile,enemy)
  var cargo=g.smithy.cargo()
  check(cargo.blueprints.has("dagger") and cargo.ore>=3 and cargo.monster>=2,"First victory guarantees a craftable alternative")
  var contents=cargo.duplicate(true);Journey.first_victory(g)
  check(cargo==contents,"Revisiting first-victory reward cannot duplicate materials")
  check(Journey.info(g).stage=="return","Discovery prompts returning home")
 g.mode="play";g.session.enabled=true;g.session.active=true
 check(g.session.checkpoint() and g.session.continue_run(),"Milestones and starter cargo survive interrupted expedition")
 check(Journey.progress(g).inspected and g.smithy.cargo().blueprints.has("dagger"),"Restored discovery retains learning progress")
 g.finish_run(false)
 check(Journey.info(g).stage=="craft","Death retains discoveries and points toward crafting")
 var before=g.smithy.data().materials.duplicate();g.mode="dead";g.action("sanctuary");g.queue_redraw();await process_frame;await process_frame
 check(g.buttons.any(func(b):return b.id=="journey_next"),"Hearth presents one next-step action")
 g.action("journey_next")
 check(g.mode=="smithy" and g.smithy.selected_blueprint=="dagger","Crafting guidance selects the discovered blueprint")
 g.action("smithy_make:dagger");check(g.smithy.data().items.has("dagger"),"Starter materials pay the real crafting cost")
 check(Journey.info(g).stage=="equip","Crafting points to equipment preparation")
 g.mode="sanctuary";g.action("journey_next")
 check(g.mode=="loadout" and g.loadout_menu.selected=="dagger","Equip guidance opens the new weapon")
 g.action("loadout_equip");check(Journey.info(g).stage=="goal","Equipped alternative prompts a deliberate crafting goal")
 g.mode="sanctuary";g.action("journey_next")
 check(g.mode=="smithy" and g.smithy.selected_blueprint=="shield","Goal guidance opens an attainable next recipe")
 g.action("smithy_track:shield");check(Journey.info(g).stage=="expedition","Player-selected goal completes the preparation lesson")
 g.session.active=false;g.session.cached={};g.session.start_run(false)
 check(Journey.progress(g).tried_alternate and g.inventory[g.equipped.weapon].archetype=="dagger","Starting the next expedition records trying the alternative")
 var hit={"player":true,"actual_damage":1.0,"damage":1.0,"crit":false,"regen":false,"burn":false,"effect":"COMBO"}
 g.fight=g.make_enemy(0,0);g.fight.position=Vector2i(3,5);g.battle=g.Combat.begin(g.fight,g.hp,g.max_hp,g.attack,g.armor,g.speed,g.relics,g.combat_build());g.feedback.hit(hit,g.battle)
 check(Journey.progress(g).ability_seen and Journey.info(g).is_empty(),"An actual weapon effect completes the final learning milestone")
 check(g.session.checkpoint() and g.session.continue_run() and Journey.info(g).is_empty(),"Completed guidance stays completed after save/load")
 var old=g.replay.new_career();old.erase("journey");old.runs=5;g.career=g.replay.clean_career(old)
 check(Journey.info(g).is_empty(),"Established characters are not forced through new onboarding")
 g.session.enabled=false;g.session.active=false;g.session.cached={};g.career=g.replay.new_career();g.new_run(100);g.guided.start();g.action("journey_skip")
 check(Journey.info(g).is_empty() and not g.guided.active(),"Skip dismisses both learning layers")
 var banked=g.smithy.data().materials.duplicate();Journey.first_victory(g);check(g.smithy.cargo().blueprints.is_empty(),"Skipped guidance does not grant repeated starter gifts")
 g.career=g.replay.new_career();g.demo_run=true;check(Journey.info(g).is_empty(),"Practice does not advance character onboarding")
 g.demo_run=false;g.run_settings.mode="daily";Journey.first_victory(g);check(g.smithy.cargo().blueprints.is_empty(),"Daily cannot grant the starter discovery")
 g.run_settings.mode="standard";g.mode="title";g.queue_redraw();await process_frame;await process_frame
 check(g.buttons.any(func(b):return b.id=="sanctuary" and b.rect.size.x>500),"Hearth is a prominent title action")
 g.mode="dead";g.queue_redraw();await process_frame;await process_frame
 check(g.buttons.any(func(b):return b.id=="sanctuary" and b.rect.size.y>=60),"Run-end screen prominently leads to the Hearth")
 g.free()
 for suffix in ["", ".tmp", ".run", ".run.bak", ".run.tmp"]:
  if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(SAVE+suffix)
 print(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
