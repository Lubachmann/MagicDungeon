extends SceneTree
var failures=[]
var checks=0
const SAVE="res://tests/.safe_return"
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func mine(g):
 g.mode="play";g.room=Vector2i.ZERO;g.pos=Vector2i(2,5);var tile=Vector2i(3,5);g.rooms[g.room].walls.erase(tile);g.rooms[g.room].entities[tile]={"kind":"ore_deposit"};g.game_move_player(Vector2i.RIGHT)
func run():
 for suffix in ["", ".tmp", ".run", ".run.bak", ".run.tmp"]:
  if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(SAVE+suffix)
 var g=load("res://main.tscn").instantiate();g.save_path=SAVE;root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.career=g.replay.new_career();g.skills={"smithcraft":2,"blastcraft":3}
 for i in range(3):
  g.new_run(88+i);var before=int(g.smithy.data().materials.ore)
  check(g.smithy.cargo().ore==0,"Starting an expedition yields no free ore")
  g.action("extract_prompt");g.action("extract_confirm")
  check(g.smithy.data().materials.ore==before and g.run_metrics.return_bonus==0,"Empty returns grant no ore or return bonus")
 g.new_run(92);mine(g);check(g.smithy.cargo().ore==8,"First deposit adds both permanent mining bonuses")
 mine(g);check(g.smithy.cargo().ore==11,"Second deposit gives normal ore")
 g.floor_number=2;g.generate_floor();mine(g);check(g.smithy.cargo().ore==15,"Mining bonus does not reset on floor change")
 g.session.enabled=true;g.session.active=true
 check(g.session.checkpoint() and g.session.continue_run(),"Mining state survives save/load")
 mine(g);check(g.smithy.cargo().ore==19,"Loading cannot duplicate first-deposit bonus")
 g.session.enabled=false;g.session.active=false;g.session.cached={}
 g.shards=100;g.run_metrics.bosses=1
 check(g.safe_return_bonus()==10,"A defeated Warden unlocks a 10 percent return bonus")
 g.room=Vector2i.ZERO;g.mode="play";g.action("extract_prompt");g.queue_redraw();await process_frame;await process_frame
 check(g.buttons.any(func(b):return b.id=="extract_confirm"),"Return confirmation renders with bonus")
 var bank_before=g.bank;g.action("extract_confirm")
 check(g.bank-bank_before==110 and g.run_metrics.return_bonus==10,"Extraction banks the displayed bonus")
 check(g.career.deaths==0,"Returning safely never counts as death")
 g.finish_run(false);check(g.bank-bank_before==110,"Finishing again cannot duplicate payout")
 g.session.enabled=true;g.session.active=true;check(g.session.checkpoint(),"Completed return can be saved")
 check(not g.session.continue_run(),"Completed return cannot be resumed for another payout")
 g.session.enabled=false;g.session.active=false;g.session.cached={}
 g.new_run(93);g.shards=100;g.run_metrics.bosses=1;g.smithy.cargo().ore=7;g.smithy.cargo().blueprints.axe=true;bank_before=g.bank;var ore_before=g.smithy.data().materials.ore;g.finish_run(false)
 check(g.bank-bank_before==100 and g.run_metrics.return_bonus==0,"Death banks collected embers without safe-return bonus")
 check(g.smithy.data().materials.ore==ore_before+7 and g.smithy.data().blueprints.has("axe"),"Death still retains materials and blueprints")
 g.new_run(94);g.shards=100;g.run_metrics.bosses=5;bank_before=g.bank;g.finish_run(true)
 check(g.bank-bank_before==121 and g.run_metrics.return_bonus==11,"Victory receives ordinary victory embers and the safe-return bonus")
 check(g.career.history[0].metrics.return_bonus==11,"Run history records the bonus")
 g.new_run(95);g.shards=100;g.run_metrics.bosses=1;g.demo_run=true;check(g.safe_return_bonus()==0,"Practice does not grant return bonuses")
 g.demo_run=false;g.run_settings.mode="daily";check(g.safe_return_bonus()==0,"Daily does not grant return bonuses")
 g.run_settings.mode="standard";g.run_rules=19;check(g.safe_return_bonus()==0,"Older rules retain their payout")
 g.free()
 for suffix in ["", ".tmp", ".run", ".run.bak", ".run.tmp"]:
  if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(SAVE+suffix)
 print(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
