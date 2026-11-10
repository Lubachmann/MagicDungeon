extends SceneTree
const Preview=preload("res://shrine_preview.gd")
const Presenter=preload("res://equipment_presenter.gd")
const Stats=preload("res://build_stats.gd")
var checks=0
var failures=[]
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.clarity016";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true;g.skills={};preload("res://tools/historical_run.gd").start(g,42,18)
 for key in Presenter.ORDER+g.build_view.META.keys():check(g.stat_ui.info(key).size()==3 and g.stat_ui.info(key)[2]!="","Every displayed stat has icon, title and explanation: "+key)
 var item=g.make_gear("weapon",4,2,["health","fire_dps"],"dagger");g.inventory=[item];g.equipped={"weapon":0};g.recalculate_stats();g.hp=g.max_hp
 var original=var_to_bytes([g.inventory,g.equipped,g.hp,g.max_hp,g.vitality_tax,g.rng.state]);var data=Preview.preview(g)
 check(original==var_to_bytes([g.inventory,g.equipped,g.hp,g.max_hp,g.vitality_tax,g.rng.state]),"Shrine preview is pure")
 check(data.item.level==5 and g.Gear.stats(data.item).fire_power>g.Gear.stats(item).fire_power,"Preview includes the weapon's own iron-tier changes")
 g.mode="shrine";g.rooms[g.room].entities[g.pos]={"kind":"shrine","used":false};g.session_actions.handle("shrine_temper")
 check(g.hp==data.after.current_hp and g.max_hp==data.after.max_hp and g.attack==data.after.attack and g.speed==data.after.speed,"Shrine actual result equals preview, including current and max HP cost")
 check("power" not in Presenter.keys({},Presenter.numbers(item)),"Character multiplier is separated from item stats")
 check("armor_reduction" not in Presenter.affected({},g.make_gear("helmet",2,0)),"Physical reduction is not presented as an item bonus")
 check("Physical reduction" in g.build_view.details("armor",Stats.calculate(g)),"Physical reduction remains available in armor details")
 check(g.stat_ui.info("enemy_current_hp")[2]!=g.stat_ui.info("current_hp")[2],"Enemy and player health explanations have the correct context")
 g.mode="play";g.stat_ui.notice_left=0;g.log_line("Chest sealed: defeat its guardian first.")
 check(g.stat_ui.blocked and g.stat_ui.notice_left==5,"Locked actions receive a prominent five-second notice")
 g.stat_ui.tick(0.12);var age=g.stat_ui.notice_age;g.log_line("Chest sealed: defeat its guardian first.")
 check(g.stat_ui.notice_age==age,"Repeated blocked actions extend the notice without replaying its pop")
 g.log_line("Entered chamber II.");check(g.stat_ui.blocked,"Routine movement does not immediately overwrite a blocked-action reason")
 g.stat_ui.notice_left=0;g.mode="fight";g.log_line("Your strike: 12 damage.");check(g.stat_ui.notice_left==0,"Combat logs do not spam notification pop-ups")
 preload("res://tools/historical_run.gd").start(g,42,18);check(not g.equipped.has("weapon") and Preview.preview(g).is_empty(),"No-weapon shrine preview is safely unavailable")
 g.free();print(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
