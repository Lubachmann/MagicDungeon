extends SceneTree
var failures=[]
func check(ok: bool, message: String):
 if not ok:failures.append(message)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-blueprint-planning";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.career=g.replay.new_career();g.new_run(15)
 var p=g.smithy.data();var view=load("res://equipment_presenter.gd")
 var normal=view.numbers(g.smithy.make_item("dagger",1));var keen=view.numbers(g.smithy.make_item("dagger_keen",1));var blood=view.numbers(g.smithy.make_item("dagger_bloodbound",1))
 check(keen.crit_chance>normal.crit_chance and keen.crit_mult>float(normal.get("crit_mult",0)),"Keen dagger supports both crit chance and damage")
 check(blood.vampirism>0 and blood.evade<normal.evade,"Bloodbound dagger trades evasion for vampirism")
 var plain_shield=view.numbers(g.smithy.make_item("shield",1));var swift_shield=view.numbers(g.smithy.make_item("shield_swift",1))
 check(swift_shield.armor<plain_shield.armor and swift_shield.evade>0 and swift_shield.speed>0,"Swift shield trades armor for evasion and speed")
 var blood_shield=view.numbers(g.smithy.make_item("shield_bloodbound",1))
 check(blood_shield.armor<plain_shield.armor and blood_shield.vampirism>0,"Bloodbound shield trades armor for sustain even after rarity scaling")
 for id in g.smithy.VARIANTS:
  var item=g.smithy.make_item(id,1);check(g.smithy.style_description(item)!="","Each blueprint family explains its identity: "+id)
 g.mode="sanctuary";g.action("smithy_open");g.action("smithy_select:dagger_keen");check(g.smithy.selected_blueprint=="dagger_keen","Undiscovered designs can be inspected")
 g.action("smithy_track:dagger_keen");var goal=g.smithy.goal_info();check(goal.blueprint_missing and not goal.ready and "F2+" in goal.sources[0],"Undiscovered recipe tracks its source and materials")
 p.materials.ore=3;p.materials.monster=2;p.materials.alloy=1;check(not g.smithy.goal_info().ready,"Materials alone do not complete an unknown blueprint")
 g.new_run(52);g.floor_number=2;var reward=g.make_gear("weapon",1,1,[],"dagger");g.smithy.reward(reward);g.smithy.reward(reward)
 check(g.smithy.cargo().blueprints.has("dagger_keen"),"Matching rare floor-two rewards can reveal keen dagger")
 check(not g.smithy.goal_info(true).blueprint_missing and g.smithy.goal_info(true).ready,"Run cargo updates tracked blueprint progress")
 g.run_settings.mode="daily";check(g.smithy.goal_info(true).blueprint_missing,"Daily rewards never count toward permanent goals")
 g.run_settings.mode="standard";g.smithy.commit();check(g.smithy.goal_info().ready,"Returning keeps the discovered blueprint")
 g.mode="sanctuary";g.action("smithy_open");g.action("smithy_make:dagger_keen");check(p.items.has("dagger_keen") and g.smithy.goal_info().finished,"Tracked blueprint can be crafted and completed")
 g.action("smithy_select:shield_swift");g.action("smithy_tab:shield");g.action("smithy_select:shield_swift");g.queue_redraw();await process_frame
 print(JSON.stringify({"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
