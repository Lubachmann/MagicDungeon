extends SceneTree
# Saved rules 18 contract; current expeditions are covered by the Hearth suites.
const Combat=preload("res://combat.gd")
const Presenter=preload("res://equipment_presenter.gd")
const Offers=preload("res://skill_offers.gd")
var failures=[]
func check(ok:bool,why:String):
 if not ok:failures.append(why)
func _initialize():call_deferred("run")
func enemy()->Dictionary:return {"kind":"enemy","type":1,"name":"Target","hp":500.0,"max":500.0,"attack":4,"armor":0.0,"speed":0.5,"trait":"none","elite":false,"roll_seed":123}
func battle(relics:Array,build:Dictionary={},power:float=20)->Dictionary:
 var b={"auto_flow":true,"elemental_v2":true,"fair_physical":true,"weapon":"plain","weapon_archetype":"axe","ice":0,"fire":0,"acid":0,"poison":0,"crit_chance":0.0,"vampirism":0.0,"element_interval_scale":1.0}
 b.merge(build,true);var s=Combat.begin(enemy(),40,100,power,0,0.5,relics,b);s.e_time=100;return s
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-heavy-builds";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true;g.skills={};preload("res://tools/historical_run.gd").start(g,42,18)
 check(g.run_rules==18,"New runs have the new heavy-weapon loot")
 var normal=g.make_gear("weapon",5,1,[],"axe");normal.infusion="fire"
 var heavy=normal.duplicate(true);heavy.heavy_form="colossus";heavy.name="Colossus axe"
 g.inventory=[normal,heavy];g.equipped={"weapon":0};g.recalculate_stats();var before=preload("res://build_stats.gd").calculate(g)
 var preview=preload("res://build_stats.gd").prospective(g,1);g.equipped.weapon=1;g.recalculate_stats();var after=preload("res://build_stats.gd").calculate(g)
 check(is_equal_approx(after.attack,before.attack*1.6) and is_equal_approx(after.speed,before.speed*0.8),"Colossus scales the complete hit and final attack rate")
 check(is_equal_approx(preview.attack,after.attack) and is_equal_approx(preview.interval,after.interval),"Equipment preview matches equipped damage and interval")
 check(is_equal_approx(before.fire,after.fire),"Physical impact does not increase Fire burn damage")
 check(is_equal_approx(preload("res://combat_pacing.gd").preview_interval(g,heavy),after.interval),"Item interval preview matches full interval")
 check(is_equal_approx(preload("res://combat_pacing.gd").preview_interval(g,normal),before.interval),"Replacing a Colossus removes its rate penalty in preview")
 check("+60%" in g.choice_ui.weapon_description(heavy) and "−20%" in g.choice_ui.weapon_description(heavy),"Weapon description explains the tradeoff")
 g.last_loot_index=1;g.last_chest_tier=1;g.mode="loot";g.queue_redraw();await process_frame;await process_frame
 g.mode="equipment";g.selected_item=1;g.queue_redraw();await process_frame;await process_frame
 g.rooms[g.room].entities[g.pos]={"kind":"salvage"};g.mode="equipment";g.selected_item=1;g.queue_redraw();await process_frame;await process_frame
 check(g.mode=="equipment","New equipment and inline crafting render in equipment")
 var numbers=Presenter.numbers(heavy);check(Presenter.value("impact_power",numbers)=="+60.0%" and Presenter.value("impact_rate",numbers)=="-20.0%","Equipment shows both tradeoff numbers")
 check("attack" in Presenter.affected(normal,heavy) and "interval" in Presenter.affected(normal,heavy),"Affected stats include attack and interval")
 var level_stats=g.Gear.stats(heavy).attack;heavy.level+=1;check(g.Gear.stats(heavy).attack>level_stats and g.Gear.stats(heavy).impact_power==0.6,"Iron improves base gear while preserving the bonus")
 var s=battle(["frost_shatter"]);s.frost_counters=4.0;s.iced=true;var hit=Combat.step(s)
 check(is_equal_approx(hit.actual_damage,30.0) and is_equal_approx(s.frost_counters,1.0) and hit.get("frost_shatter",false),"Frost Shatter deals 50% more physical damage and spends 3 Frost")
 check(s.e_time<100,"Spending Frost correctly speeds up the enemy's next attack")
 s=battle(["frost_shatter"],{},5);s.frost_counters=3;s.iced=true;s.enemy.trait="shield";s.weapon_guard=1;s.guard_hp=8
 hit=Combat.step(s);check(hit.actual_damage==0 and s.frost_counters==3,"Blocked hits do not spend Frost")
 s=battle(["frost_shatter"],{"ice":1});s.frost_counters=3;s.iced=true;hit=Combat.step(s);check(is_equal_approx(s.frost_counters,1.0),"The same successful hit applies its normal Frost after spending stacks")
 s=battle(["frost_shatter"],{"weapon_archetype":"dagger"});s.frost_counters=4;s.iced=true;hit=Combat.step(s);check(is_equal_approx(hit.actual_damage,20.0) and s.frost_counters==4,"Frost Shatter does not affect daggers")
 s=battle([], {"fire":1},20);Combat.step(s);var base_burn=s.burns[0].power
 s=battle([], {"fire":1,"impact_power":0.6},32);Combat.step(s);check(is_equal_approx(s.burns[0].power,base_burn),"Colossus physical bonus does not boost Fire burn")
 s=battle(["frost_shatter"],{"fire":1},20);s.frost_counters=3;s.iced=true;Combat.step(s);check(is_equal_approx(s.burns[0].power,base_burn),"Frost Shatter physical bonus does not boost Fire burn")
 s=battle(["breakthrough"],{},10);s.enemy.trait="shield";s.weapon_guard=1;s.guard_hp=8;hit=Combat.step(s)
 check(hit.guard_break and hit.get("breakthrough_armed",false) and s.get("breakthrough_ready",false),"Breaking a guard arms Breakthrough and signals the player")
 hit=Combat.step(s);check(is_equal_approx(hit.actual_damage,17.5) and hit.get("breakthrough_hit",false) and not s.breakthrough_ready,"Next successful hit gains 75% damage once")
 s=battle(["breakthrough","frost_shatter"],{"ice":1,"impact_power":0.6},32);s.frost_counters=4;s.iced=true;s.breakthrough_ready=true
 var saved=s.duplicate(true);var prediction=Combat.predict(s);check(s==saved,"Inspecting the fight does not spend Frost or Breakthrough")
 var played=s.duplicate(true)
 while not played.done:Combat.step(played)
 check(played.won==prediction.won and played.hp==prediction.hp,"Prediction and combat use the same heavy mechanics")
 s=battle(["breakthrough"],{"acid":2},10);s.enemy.armor=2;s.initial_armor=2;hit=Combat.step(s)
 check(s.get("breakthrough_ready",false),"Removing all armor arms Breakthrough")
 hit=Combat.step(s);check(hit.actual_damage>17.0 and not s.breakthrough_ready,"Armor break empowers the following hit")
 s=battle(["breakthrough"],{},5);s.breakthrough_ready=true;s.enemy.trait="shield";s.weapon_guard=1;s.guard_hp=20;hit=Combat.step(s)
 check(hit.actual_damage==0 and s.breakthrough_ready,"A blocked hit does not consume Breakthrough")
 g.base_elements.ice=1;g.reward_level=8;g.recalculate_stats();var pool=Offers.pool(g)
 check("breakthrough" in pool and "frost_shatter" in pool and Offers.rarity("frost_shatter")=="Epic","Heavy Frost build can find both skills at later levels")
 g.run_rules=13;check("breakthrough" not in Offers.pool(g) and "frost_shatter" not in Offers.pool(g),"Older runs keep their original offer pool")
 for i in range(100):check(not g.chest_item(1,false,"weapon").has("heavy_form"),"Older runs keep their original weapon drops")
 g.run_rules=14;g.equipped.weapon=0;g.inventory[0]=g.make_gear("weapon",1,0,[],"dagger");g.recalculate_stats()
 check("breakthrough" not in Offers.pool(g) and "frost_shatter" not in Offers.pool(g),"Heavy skills are not offered to dagger builds")
 g.rng.seed=188;var found=0;var allowed=0
 for i in range(2500):
  var item=g.chest_item(1,false,"weapon")
  if item.get("heavy_form","")=="colossus":
   found+=1;check(item.rarity>=1 and item.archetype in ["axe","greatblade"] and not item.get("plain",false),"Colossus only appears on rare heavy weapons")
  if item.rarity>=1 and item.archetype in ["axe","greatblade"]:allowed+=1
 check(found>0 and found<allowed,"Colossus is obtainable without replacing every heavy weapon")
 g.mode="codex";g.replay.codex_page=0;g.replay.codex_list_page=1;g.queue_redraw();await process_frame;await process_frame
 var codex_buttons=[];for button in g.buttons:codex_buttons.append(button.id)
 check("codex:frost_shatter" in codex_buttons and "codex:breakthrough" in codex_buttons,"New skills are reachable in the paginated Codex")
 g.inventory=[heavy];g.equipped={"weapon":0};g.relics=["breakthrough"];g.recalculate_stats();g.hp=40;g.fight=g.make_enemy(1,0);g.fight.position=g.pos+Vector2i.RIGHT
 g.battle=Combat.begin(g.fight,g.hp,g.max_hp,g.attack,g.armor,g.speed,g.relics,g.combat_build());g.battle.breakthrough_ready=true;g.mode="fight";g.session.enabled=true;g.session.active=true
 check(g.session.checkpoint() and g.session.continue_run() and g.inventory[0].get("heavy_form","")=="colossus" and g.battle.get("breakthrough_ready",false),"Colossus and queued Breakthrough survive save and continue")
 g.session.enabled=false
 for suffix in [".run",".run.bak",".run.tmp"]:DirAccess.remove_absolute(g.save_path+suffix)
 print(JSON.stringify({"failures":failures,"colossus":found,"eligible_drops":allowed}));g.free();quit(0 if failures.is_empty() else 1)
