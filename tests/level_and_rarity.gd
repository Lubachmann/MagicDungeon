extends SceneTree
const Pacing=preload("res://combat_pacing.gd")
var failures=[]
func check(ok:bool,why:String):
 if not ok:failures.append(why)
func _initialize():call_deferred("run")
func enemy(kind:int,floor_number:int,rules:int)->Dictionary:
 var e={"type":kind,"boss_kind":"none"};Pacing.enemy(e,floor_number,0,rules);return e
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-level-rarity";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true;g.skills={};g.new_run(91)
 check(g.run_rules==18 and g.hp==80 and g.max_hp==80,"New runs start at normal health")
 g.hp=40;g.gain_xp(g.xp_required(1));check(g.character_level==2 and g.max_hp==88 and g.hp==48 and g.summary.healed==8,"Level gives and restores 8 health")
 g.gain_xp(g.xp_required(2)+g.xp_required(3));check(g.character_level==4 and g.max_hp==104 and g.hp==64 and g.summary.healed==24,"Several levels grant and restore health per level")
 g.hp=g.max_hp;g.gain_xp(g.xp_required(4));check(g.hp==g.max_hp and g.max_hp==112,"Healing is capped at the increased maximum")
 g.new_run(92);g.run_rules=12;g.hp=40;g.gain_xp(g.xp_required(1));check(g.max_hp==83 and g.hp==40,"Saved older runs keep their level rules")
 for kind in [0,1,2,3]:
  var old_first=enemy(kind,1,12);var new_first=enemy(kind,1,13)
  check(old_first.hp==new_first.hp and old_first.attack==new_first.attack and old_first.armor==new_first.armor and old_first.speed==new_first.speed,"First floor enemy stats are unchanged")
  var prior={}
  for floor_number in range(2,6):
   var old=enemy(kind,floor_number,12);var next=enemy(kind,floor_number,13)
   check(next.hp>old.hp and next.attack>old.attack and next.armor>old.armor and next.speed>old.speed,"Later floor enemy exceeds old values")
   if not prior.is_empty():check(next.hp>prior.hp and next.attack>prior.attack,"Enemy scales between floors")
   prior=next
 g.new_run(93);g.mode="relic";g.choices=["venom","glacial_crusher","toxic_glacier"];g.queue_redraw();await process_frame;await process_frame
 check(g.mode=="relic" and g.buttons.any(func(b):return b.id=="relic2"),"Common, Rare and Epic cards render and remain selectable")
 g.mode="play";g.character_level=5;g.recalculate_stats();g.hp=40;g.session.enabled=true;g.session.active=true
 check(g.session.checkpoint() and g.session.continue_run() and g.max_hp==112 and g.hp==40,"New health progression survives save and continue")
 g.session.enabled=false
 for suffix in [".run",".run.bak",".run.tmp"]:DirAccess.remove_absolute(g.save_path+suffix)
 print(JSON.stringify({"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
