extends SceneTree
const Flow=preload("res://flow_combat.gd")
const Combat=preload("res://combat.gd")
const SAVE="res://tests/.floor_identity"
var g
var checks=0
var failures=[]
var report=[]
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func state(family:String="",signature:String="",prepared:String="",weapon:String="plain") -> Dictionary:
 var e={"kind":"enemy","name":"Counter test","type":3 if signature!="" else 1,"hp":900.0,"max":1000.0,"attack":20,"armor":0,"speed":0.5,"trait":"none","elite":false,"roll_seed":89123,"regen":8,"floor_prepared":prepared}
 if family!="":e.family=family
 if signature!="":e.signature=signature
 var build={"auto_flow":true,"fair_physical":true,"elemental_v2":true,"elemental_specialization":true,"paced":true,"full_opening":true,"weapon":weapon,"weapon_level":1,"crit_chance":0.0,"crit_mult":2.0,"evade":0.0}
 return Combat.begin(e,1000,1000,20,0,0.5,[],build)
func run():
 g=load("res://main.tscn").instantiate();g.save_path=SAVE;root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true;g.career=g.replay.new_career();g.career.journey={"skipped":true}
 for seed in range(12):
  g.new_run(seed)
  for floor_num in range(1,6):
   g.floor_number=floor_num;g.generate_floor();var prep=[];var primary=0;var support=0;var expected=Flow.FAMILY_ORDER[floor_num-1]
   for coord in g.rooms:
    for tile in g.rooms[coord].entities:
     var e=g.rooms[coord].entities[tile]
     if e.kind=="boss_preparation":prep.append([coord,tile])
     if e.get("family","")==expected:primary+=1
     elif e.has("family"):support+=1
     if e.kind=="enemy" and (coord in [Vector2i.ZERO,g.boss_room] or e.get("gatekeeper",false)):check(not e.has("family"),"Mandatory entrances and bosses avoid extra family mechanics")
     if e.get("expedition_reward",false):check(e.reward_element==g.tactics.preparation().element,"Reward offers a counter suited to the floor")
   check(prep.size()==1 and primary>=2 and primary>support,"Every floor has preparation and a dominant themed family")
   var place=prep[0];check(g.dungeon_threads.distances_from(Vector2i.ZERO).has(place[0]) and g.dungeon_threads.reachable(g.rooms[place[0]]).has(place[1]),"Preparation is reachable without traversal tools")
   g.room=place[0];g.puzzle_tile=place[1];g.mode="decision";g.world_choices.handle("prepare_weaken")
   check(g.floor_flags.prepared_floor==floor_num,"Preparation records its floor")
   for data in g.rooms.values():
    for e in data.entities.values():
     if e.kind=="enemy":check(e.floor_prepared==g.tactics.rule(),"Preparation reaches existing enemies")
   g.branch_paths.create_room("ice");check(g.rooms[Vector2i(-1,0)].entities[Vector2i(7,5)].floor_prepared==g.tactics.rule(),"Later branch guardians inherit preparation")
   var before=var_to_bytes(g.rooms);g.tactics.prepare_floor();check(var_to_bytes(g.rooms)==before,"Preparation cannot stack")
   g.generate_floor()
   check(not g.floor_flags.has("prepared_floor"),"New floors clear previous preparation")
   check(g.rooms.values().all(func(data):return data.entities.values().all(func(e):return not e.has("floor_prepared"))),"Regenerated floors do not inherit stale preparation")
 # Actual combat events verify alternative counters, without requiring a weapon swap.
 var normal=state("leech");var prepared=state("leech","","water");normal.p_time=100;prepared.p_time=100
 var a=Combat.step(normal);var b=Combat.step(prepared)
 check(is_equal_approx(b.enemy_heal,a.enemy_heal*0.5),"Cisterns halve Leech healing")
 var shielded=state("leech");shielded.p_time=100;Flow.add_shield(shielded,50,50,"sword");var hit=Combat.step(shielded)
 check(hit.enemy_heal==0,"Shields independently counter Leech healing")
 normal=state("","tide");prepared=state("","tide","water");normal.tide_followup=true;prepared.tide_followup=true;normal.p_time=100;prepared.p_time=100
 a=Combat.step(normal);b=Combat.step(prepared);check(a.damage==12 and b.damage==8,"Cisterns weaken actual Tide follow-ups")
 normal=state("","abbot");prepared=state("","abbot","embers");normal.p_time=100;normal.e_time=100;prepared.p_time=100;prepared.e_time=100
 a=Combat.step(normal);b=Combat.step(prepared);check(a.enemy_heal==8 and b.enemy_heal==4,"Dousing halves regeneration")
 var burning=state("","abbot");burning.p_time=100;burning.e_time=100;burning.fire_time=3;burning.fire_until=5
 hit=Combat.step(burning);check(hit.enemy_heal==4,"Fire provides an independent regeneration counter")
 normal=state("construct");prepared=state("construct","","brittle");normal.e_time=100;prepared.e_time=100
 Combat.step(normal);Combat.step(prepared);a=Combat.step(normal);b=Combat.step(prepared)
 check(a.damage==13 and b.damage==20,"Sabotage removes plates after the first hit")
 var heavy=state("construct","","","greatblade");heavy.e_time=100;hit=Combat.step(heavy);check(hit.damage==20 and heavy.plates==0,"Greatblade independently shatters plates")
 normal=state("","furnace");prepared=state("","furnace","brittle");normal.e_time=100;prepared.e_time=100
 for i in range(4):Combat.step(normal);Combat.step(prepared)
 check(normal.heat==4 and prepared.heat==2,"Sabotage halves Heat buildup")
 var cold=state("","furnace");cold.e_time=100;cold.iced=true;cold.build.ice=1
 for i in range(4):Combat.step(cold)
 check(cold.heat==0,"Frost independently cools Furnace Heat")
 normal=state("shade");prepared=state("shade","","eclipse");normal.p_hits=3;prepared.p_hits=3;normal.e_time=100;prepared.e_time=100
 a=Combat.step(normal);b=Combat.step(prepared);check(a.damage==0 and b.damage==20,"Beacons let the fourth swing hit a Shade")
 cold=state("shade");cold.p_hits=3;cold.iced=true;cold.e_time=100;hit=Combat.step(cold);check(hit.damage==20,"Frost independently stops Shade dodges")
 normal=state("","eclipse");prepared=state("","eclipse","eclipse");normal.e_time=100;prepared.e_time=100
 a=Combat.step(normal);b=Combat.step(prepared);check(a.damage==15 and b.damage==18,"Beacons weaken physical boss resistance")
 normal.seal_phase=1;prepared.seal_phase=1;check(Flow.burn_multiplier(normal)==0.5 and Flow.burn_multiplier(prepared)==0.75,"Beacons weaken burn resistance")
 var critical=state("","eclipse");critical.roll=1;critical.build.crit_chance=0.6;critical.e_time=100;hit=Combat.step(critical)
 check(hit.crit and critical.seal_broken,"Critical hits independently cancel boss resistance")
 for weapon in ["balanced","dagger","axe","greatblade","ember"]:
  for family in Flow.FAMILY_ORDER:
   var s=state(family,"","",weapon);s.e_time=100;s.enemy.hp=1000
   for i in range(6):Combat.step(s)
   check(s.enemy.hp<1000,"Every weapon can damage every family without a required element")
 # Save the changed floor, then confirm the choice is spent and its effect retained.
 g.floor_number=3;g.generate_floor();var location=[]
 for coord in g.rooms:
  for tile in g.rooms[coord].entities:
   if g.rooms[coord].entities[tile].kind=="boss_preparation":location=[coord,tile]
 g.room=location[0];g.puzzle_tile=location[1];g.mode="decision";g.world_choices.handle("prepare_weaken");g.session.enabled=true;g.session.active=true
 check(g.session.checkpoint() and g.session.continue_run(),"Prepared floor saves and restores")
 check(g.floor_flags.prepared_floor==3 and not g.rooms[g.room].entities.has(g.puzzle_tile),"Loading preserves preparation and consumed choice")
 g.session.enabled=false;g.session.active=false;g.session.cached={}
 g.floor_number=4;g.generate_floor();location=[]
 for coord in g.rooms:
  for tile in g.rooms[coord].entities:
   if g.rooms[coord].entities[tile].kind=="boss_preparation":location=[coord,tile]
 g.room=location[0];g.puzzle_tile=location[1];g.mode="decision";var flasks=g.potions;g.world_choices.handle("prepare_supply")
 check(g.potions==flasks+1 and not g.floor_flags.has("prepared_floor"),"Supplies are a mutually exclusive preparation alternative")
 # Representative real-stat boss encounters are reported, not treated as player win rates.
 for weapon in ["sword","dagger","axe","greatblade","ember"]:
  for floor_num in range(1,6):
   for build in ["physical","elemental"]:
    g.floor_number=floor_num;g.generate_floor();g.inventory=[];g.equipped={};g.run_skills={"might":4,"vigor":4,"armor_training":4};g.character_level=1+6*(floor_num-1);g.relics=["leech","ward","haste"]
    g.bonus={"attack":3.0*(floor_num-1),"armor":2.0*(floor_num-1),"speed":0.0,"crit_chance":0.0,"crit_mult":0.0}
    for slot in ["weapon","shield","heavy_armor","helmet"]:
     var id=weapon if slot=="weapon" else slot;var item=g.smithy.make_item(id,floor_num,"ice" if build=="elemental" else "");g.inventory.append(item);g.equipped[item.slot]=g.inventory.size()-1
    g.base_elements={"fire":0,"ice":0,"acid":0,"poison":0};g.recalculate_stats()
    var enemy_seed=g.rng.state
    for use_prep in [false,true]:
     if use_prep:g.tactics.prepare_floor()
     g.rng.state=enemy_seed
     var boss=g.make_enemy(3,4);g.potions=3;var s=Combat.begin(boss,g.max_hp,g.max_hp,g.attack,g.armor,g.speed,g.relics,g.combat_build());var steps=0
     while not s.done and steps<10000:
      if s.hp<s.max_hp*0.35 and g.potions>0:g.battle=s;g.mode="fight";g.action("heal")
      Combat.step(s);steps+=1
     check(s.done,"Every representative boss encounter resolves")
     report.append({"weapon":weapon,"floor":floor_num,"build":build,"prepared":use_prep,"won":s.won,"hp":s.hp,"seconds":s.time,"player_level":g.character_level,"max_hp":g.max_hp,"attack":g.attack,"armor":g.armor,"flasks_used":3-g.potions})
 DirAccess.make_dir_recursive_absolute("res://work");var file=FileAccess.open("res://work/floor_identity_audit.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 g.free()
 for suffix in ["", ".tmp", ".run", ".run.bak", ".run.tmp"]:
  if FileAccess.file_exists(SAVE+suffix):DirAccess.remove_absolute(SAVE+suffix)
 print(JSON.stringify({"checks":checks,"failures":failures,"boss_encounters":report.size()}));quit(0 if failures.is_empty() else 1)
