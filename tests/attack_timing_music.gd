extends SceneTree
const Combat=preload("res://combat.gd")
var failures=[]
var checks=0
func check(ok:bool,message:String):
 checks+=1
 if not ok:failures.append(message)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-attack-music-test";root.add_child(g);await process_frame;g.set_process(false);g.session.enabled=false;g.new_run(43)
 var enemy={"kind":"enemy","name":"Dummy","type":0,"hp":200,"max":200,"attack":1,"armor":0,"speed":0.5,"trait":"none","elite":false,"roll_seed":120}
 var build=g.combat_build();build.crit_chance=0.0;var state=Combat.begin(enemy,100,100,10,0,1.0/3.8,[],build)
 check(is_equal_approx(state.p_time,3.8) and is_equal_approx(state.e_time,2.0),"Both combatants wait their full interval for the first attack")
 var first=Combat.step(state);check(not first.player and is_equal_approx(state.time,2.0),"A 2-second enemy attacks before a 3.8-second player")
 var second=Combat.step(state);check(second.player and is_equal_approx(state.time,3.8),"The player attacks at 3.8 seconds")
 state=Combat.begin(enemy,100,100,10,0,1.0/1.0,[],build);first=Combat.step(state)
 check(first.player and is_equal_approx(state.time,1.0),"A faster player attacks first")
 state=Combat.begin(enemy,100,100,10,0,0.5,[],build);first=Combat.step(state)
 check(first.player and is_equal_approx(state.time,2.0),"Equal attack times resolve in the player's favor")
 for interval in [1.0,3.8]:
  var quick=Combat.begin(enemy,100,100,10,0,1.0/interval,["quickdraw"],build)
  check(is_zero_approx(quick.p_time),"Quickdraw schedules an immediate strike")
  var opening=Combat.step(quick)
  check(opening.player and is_zero_approx(quick.time) and is_equal_approx(quick.p_time,interval),"Quickdraw attacks once immediately, then waits the normal interval")
 var combo=Combat.begin(enemy,100,100,10,0,1.0/3.8,["quickdraw","spark"],build);var combo_hit=Combat.step(combo)
 check(combo_hit.player and is_equal_approx(combo_hit.actual_damage,17.5),"Quickdraw combines with opening-hit bonuses")
 g.reward_level=4;check("quickdraw" in preload("res://skill_offers.gd").pool(g) and preload("res://skill_offers.gd").rarity("quickdraw")=="Rare","Quickdraw enters rare skill offers at level 4")
 g.reward_level=3;check("quickdraw" not in preload("res://skill_offers.gd").pool(g),"Quickdraw respects rare skill level requirements")
 var old=Combat.begin(enemy,100,100,10,0,0.5,[],{"paced":true});check(is_equal_approx(old.p_time,1.0),"Legacy timing stays available for old simulated states")
 check(g.sound.music_streams.size()==4,"All four music tracks load")
 for track in g.sound.music_streams.values():check(track is AudioStreamOggVorbis and track.get_length()>1.0 and track.loop,"Music is valid and loops")
 g.mode="settings";g.sound.music_volume=0.35;g.action("music_down");check(is_equal_approx(g.sound.music_volume,0.25),"Music has an independent volume control")
 g.action("music_up");check(is_equal_approx(g.sound.music_volume,0.35),"Music volume can be increased")
 g.session.enabled=true;g.session.active=false;g.sound.music_volume=0.55;check(g.session.save_preferences() and is_equal_approx(float(g.session.read_file(g.session.settings_path()).preferences.music),0.55),"Music volume persists in settings")
 for suffix in [".settings",".settings.tmp",".settings.bak"]:DirAccess.remove_absolute(g.session.settings_path().trim_suffix(".settings")+suffix)
 g.session.enabled=false
 g.mode="fight";g.fight=enemy;g.fight.position=Vector2i(4,5);g.rooms[g.room].entities[g.fight.position]=enemy;g.battle=Combat.begin(enemy,100,100,10,0,1.0/3.8,[],build);g.clock=0;g.queue_redraw();await process_frame;await process_frame
 check(g.mode=="fight","Fight and attack timer render")
 print(JSON.stringify({"checks":checks,"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
