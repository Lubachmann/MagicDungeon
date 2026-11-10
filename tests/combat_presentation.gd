extends SceneTree
const Flow=preload("res://flow_combat.gd")
var g
var checks=0
var failures=[]
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func simulate(weapon:String,rate:int,calm:bool) -> Dictionary:
 g.career=g.replay.new_career();g.skills={};g.new_run(512);g.inventory=[g.smithy.make_item(weapon,3,"poison")];g.equipped={"weapon":0};g.base_elements.ice=2;g.recalculate_stats();g.hp=g.max_hp;g.session.preferences.reduced_flashes=calm
 var tile=Vector2i(3,5);g.rooms[g.room].walls.erase(tile)
 var foe={"elite":false,"level":1,"kind":"enemy","type":1,"name":"Presentation foe","hp":180,"max":180,"attack":4,"armor":5,"speed":0.35,"trait":"none","roll_seed":123456}
 g.rooms[g.room].entities[tile]=foe;g.game_move_player(Vector2i.RIGHT)
 check(g.mode=="fight" and int(g.battle.get("playback_rate",1))==1,"Encounter defaults to normal speed")
 if rate==2:g.action("combat_speed_toggle")
 var frames=0;var healed=false
 while not g.battle.done and frames<20000:
  if float(g.battle.time)>=6 and g.battle.hp<g.battle.max_hp and not healed:
   g.action("heal");healed=true
  g._process(1.0/60.0);frames+=1
 check(g.battle.done,"Playback completes")
 return {"hp":g.battle.hp,"enemy_hp":g.battle.enemy.hp,"hits":g.battle.p_hits,"enemy_hits":g.battle.e_hits,"roll":g.battle.roll,"evade_roll":g.battle.evade_roll,"time":g.battle.time,"recap":g.run_metrics.last_fight.duplicate(true),"frames":frames,"flasks":g.potions}
func run():
 g=load("res://main.tscn").instantiate();g.save_path="res://tests/.combat_presentation";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true
 for weapon in ["sword","dagger","axe","greatblade","ember"]:
  for calm in [false,true]:
   var normal=simulate(weapon,1,calm);var fast=simulate(weapon,2,calm)
   var normal_frames=normal.frames;var fast_frames=fast.frames;normal.erase("frames");fast.erase("frames")
   check(normal==fast,"Speed preserves outcome, counters, RNG, flask use and recap for "+weapon)
   check(fast_frames<normal_frames,"Double speed completes sooner for "+weapon)
 var state={"shield":0};Flow.add_shield(state,3,8,"sword");Flow.add_shield(state,4,10,"acid");var event={}
 check(Flow.absorb_shield(state,5,event)==0 and event.shield_sources=={"sword":3,"acid":2},"Mixed shields are attributed to their actual sources")
 check(state.shield==2,"Shield remainder is correct")
 state={"shield":5};event={};Flow.absorb_shield(state,3,event)
 check(event.shield_sources=={"other":3},"Old saved shields are not falsely attributed to Sword ward")
 for weapon in ["balanced","dagger","axe","greatblade","ember"]:
  state={"build":{"weapon":weapon},"successful_hits":2,"combo":2,"p_hits":2}
  var progress=g.tactics.weapon_progress(state);check(progress.count==2 and progress.total==(4 if weapon=="balanced" else 3),"Weapon counter uses actual combat state")
 g.feedback.clear();g.feedback.announce({"effect":"FREEZE"});g.feedback.announce({"effect":"CLEAVE"})
 check(g.feedback.major_text=="FREEZE","Lower-priority events do not erase a freeze announcement")
 g.feedback.tick(2);g.feedback.announce({"combo_lost":true});check(g.feedback.major_text=="COMBO LOST","Combo reset is explained")
 g.mode="fight";g.battle.hp=1;g.battle.playback_rate=2;g.combat_clock_delta(0.01)
 check(g.battle.playback_rate==1,"Low HP returns playback to normal")
 g.battle.hp=g.battle.max_hp;g.controls.confirm();check(g.battle.playback_rate==2,"Keyboard/controller confirm toggles speed")
 var before=g.hp;g.potions=1;g.hp=g.max_hp-10;g.battle.hp=g.hp;g.battle.done=false;g.action("heal")
 check(g.battle.hp>g.max_hp-10 and g.potions==0,"Flasks remain usable during accelerated combat")
 g.queue_redraw();await process_frame;await process_frame
 check(g.buttons.any(func(b):return b.id=="combat_speed_toggle"),"Speed button is rendered")
 g.mode="recap";g.queue_redraw();await process_frame;await process_frame
 check(g.buttons.any(func(b):return b.id=="recap_close"),"Expanded recap renders")
 g.new_run(513);g.room=Vector2i.ZERO;g.pos=Vector2i(2,5);var tile=Vector2i(3,5);g.rooms[g.room].walls.erase(tile);g.rooms[g.room].entities[tile]=g.make_enemy(1,1);g.mode="play";g.game_move_player(Vector2i.RIGHT)
 Flow.add_shield(g.battle,3,8,"sword");g.battle.playback_rate=2;var sources=g.battle.shield_sources.duplicate(true)
 g.session.enabled=true;g.session.active=true
 check(g.session.checkpoint() and g.session.continue_run(),"Accelerated fight can be saved and restored")
 check(g.battle.playback_rate==1 and g.battle.shield_sources==sources,"Resume returns to normal speed and preserves shield attribution")
 g.session.enabled=false
 g.free()
 for suffix in ["", ".tmp", ".run", ".run.bak", ".run.tmp"]:
  if FileAccess.file_exists("res://tests/.combat_presentation"+suffix):DirAccess.remove_absolute("res://tests/.combat_presentation"+suffix)
 print(JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
