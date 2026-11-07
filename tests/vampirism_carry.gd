extends SceneTree
var failures=[]
var game
func check(value: bool, description: String) -> void:
 if not value: failures.append(description)
func _initialize() -> void: call_deferred("run")
func fight_once() -> void:
 var enemy=game.make_enemy(0,0)
 enemy.hp=10.0;enemy.max=10.0;enemy.armor=0.0;enemy.trait="none";enemy.elite=false;enemy.position=game.pos+Vector2i.RIGHT
 enemy.erase("family");enemy.erase("signature");enemy.erase("affix")
 game.rooms[game.room].entities[enemy.position]=enemy.duplicate(true)
 game.fight=enemy;game.attack=10.0;game.speed=1.0;game.crit_chance=0.0;game.gear_stats["vampirism"]=0.05
 game.battle=game.Combat.begin(enemy,game.hp,game.max_hp,10.0,0.0,1.0,[],game.combat_build())
 game.battle.e_time=100.0;game.clock=-0.15;game.mode="fight"
 game._process(1.2)
func run() -> void:
 game=load("res://main.tscn").instantiate();game.save_path="/private/tmp/magicdungeon-vamp-carry";root.add_child(game);await process_frame
 game.session.enabled=false;game.set_process(false);game.muted=true;game.skills={};game.new_run(41);game.hp=10
 fight_once()
 check(game.mode=="play" and game.hp==10 and is_equal_approx(float(game.run_metrics.get("vamp_fraction",-1)),0.5),"A 10 damage hit at 5% stores half a health point after victory")
 game.session.enabled=true;game.session.active=true
 check(game.session.checkpoint() and game.session.continue_run(),"Between-fights save loads")
 check(is_equal_approx(float(game.run_metrics.get("vamp_fraction",-1)),0.5),"Save retains fractional healing")
 game.session.enabled=false;game.session.active=false
 fight_once()
 check(game.hp==11 and is_zero_approx(float(game.run_metrics.get("vamp_fraction",-1))),"A second hit in another fight heals exactly 1 HP")
 check(int(game.summary.get("vamp_healed",0))==1,"Vampirism healing is counted in run summary")
 var visible=false
 for mote in game.motes:
  if str(mote.value)=="VAMP +1":visible=true
 check(visible,"Vampirism healing has a labelled visual number")
 game.run_metrics["vamp_fraction"]=0.5;game.hp=game.max_hp-1;game.potions=1;game.mode="play";game.action("heal")
 check(game.hp==game.max_hp and is_zero_approx(float(game.run_metrics.vamp_fraction)),"Reaching full health clears unused fractional healing")
 game.run_metrics["vamp_fraction"]=0.5;game.new_run(42)
 check(float(game.run_metrics.get("vamp_fraction",0))==0.0,"Starting a run resets fractional healing")
 for suffix in [".run",".run.bak",".run.tmp"]:DirAccess.remove_absolute(game.save_path+suffix)
 print(JSON.stringify({"failures":failures}))
 game.free();quit(0 if failures.is_empty() else 1)
