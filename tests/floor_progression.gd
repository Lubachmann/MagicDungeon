extends SceneTree
const Combat=preload("res://combat.gd")
var failures=[]
func check(ok: bool,message: String):
 if not ok:failures.append(message)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-floor-progression";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true;g.skills={};g.new_run(77)
 check(g.run_rules==18,"New runs use new progression rules")
 var floor_data=[];var previous={}
 for floor_number in range(1,6):
  g.floor_number=floor_number;var enemy=g.make_enemy(0,0);enemy.erase("family");enemy.erase("signature");enemy.erase("affix");enemy.trait="none";enemy["mending"]=false
  var outcome=Combat.begin(enemy,150,150,20,5,0.5,[],{"auto_flow":true,"elemental_v2":true,"fair_physical":true,"weapon":"plain","fire":0,"ice":0,"acid":0,"poison":0,"crit_chance":0.0})
  while not outcome.done:Combat.step(outcome)
  var gear=g.make_gear("weapon",g.loot_level(floor_number),0,[],"balanced");var stats=g.Gear.stats(gear)
  floor_data.append({"floor":floor_number,"enemy_hp":enemy.hp,"enemy_attack":enemy.attack,"seconds":outcome.time,"player_hp_left":outcome.hp,"gear_level":gear.level,"gear_attack":stats.attack})
  if not previous.is_empty():
   check(enemy.hp>previous.enemy_hp and enemy.attack>previous.enemy_attack,"Enemies get stronger each floor")
   check(gear.level>previous.gear_level and stats.attack>previous.gear_attack,"Same weapon gets stronger each floor")
  previous=floor_data.back()
 g.floor_number=2;g.rng.seed=527;var focuses={};var rarities=[0,0,0];var observed=0
 for i in range(1000):
  g.floor_drop_index=posmod(4-g.floor_number,5)
  var item=g.chest_item(0,false)
  if item.slot!="amulet":continue
  observed+=1;focuses[item.get("amulet_focus","")]=true;rarities[item.rarity]+=1
  check(item.level>=3 and item.get("balance",0)==7,"Floor two amulets have improved level and balance")
 check(observed==1000 and focuses.size()==g.Gear.AMULET_FOCUSES.size(),"Amulets cover all ten focuses")
 check(rarities[0]>rarities[1] and rarities[1]>0 and rarities[2]>0,"Most amulets are common but all rarities remain possible")
 var expected_odds=g.Gear.chest_odds(g.replay.odds(0),"amulet",g.run_rules)
 check(absf(rarities[0]/10.0-float(expected_odds[0]))<5.0 and absf(rarities[2]/10.0-float(expected_odds[2]))<3.0,"Displayed amulet odds match sampled chest drops")
 var crit={"slot":"amulet","level":1,"rarity":0,"affixes":[],"balance":6,"amulet_focus":"crit_chance"}
 var vamp=crit.duplicate();vamp.amulet_focus="vampirism"
 check(g.Gear.stats(crit).crit_chance>=0.08 and g.Gear.stats(vamp).vampirism>=0.07,"Common focused crit and vampirism amulets have useful values")
 for focus in g.Gear.AMULET_FOCUSES:
  var item=crit.duplicate();item.amulet_focus=focus;var one=g.Gear.stats(item);item.level=2;var two=g.Gear.stats(item)
  var key={"fire":"fire_power","ice":"frost_apply","acid":"acid_apply","poison":"poison_apply"}.get(focus,focus)
  check(float(two[key])>float(one[key]),"Iron improves amulet "+focus)
 var old={"slot":"amulet","level":1,"rarity":0,"affixes":[],"balance":5}
 check(is_equal_approx(g.Gear.stats(old).crit_chance,0.02) and is_equal_approx(g.Gear.stats(old).vampirism,0.015),"Old amulet values remain stable")
 var e={"kind":"enemy","type":1,"name":"Test","hp":100.0,"max":100.0,"attack":1,"armor":0,"speed":1.0,"trait":"none","elite":false,"roll_seed":1}
 var build={"auto_flow":true,"fair_physical":true,"elemental_v2":true,"poison":1,"weapon":"plain","vampirism":0.10,"crit_chance":0.0}
 var s=Combat.begin(e,10,100,20,0,1,["blood_harvest"],build);s.poisoned=true;s.e_time=100;var hit=Combat.step(s)
 check(hit.vamp_heal==3 and s.hp==13,"Blood Harvest boosts vampirism healing by 50% against poison")
 build.poison=0;s=Combat.begin(e,10,100,20,0,1,["blood_harvest"],build);s.e_time=100;hit=Combat.step(s)
 check(hit.vamp_heal==2,"Blood Harvest does not boost unpoisoned targets")
 g.mode="play";g.relics=["blood_harvest","leech"];g.action("build_open");g.action("build_skills");g.queue_redraw();await process_frame;await process_frame
 var buttons=[];for b in g.buttons:buttons.append(b.id)
 check("build_skill:blood_harvest" in buttons and "build_skill:leech" in buttons,"Build screen lists owned skills")
 g.action("build_skill:blood_harvest");check(g.build_view.selected_skill=="blood_harvest","Selecting a skill opens its explanation")
 g.relics=g.RELICS.keys().slice(0,11);g.action("build_skill_next");g.queue_redraw();await process_frame;await process_frame
 check(g.build_view.skill_page==1,"Skill list supports more than eight skills")
 g.action("build_close");check(g.mode=="play","Build returns to its previous screen")
 g.rooms[g.room].entities[g.pos]={"kind":"salvage"};g.mode="equipment";g.queue_redraw();await process_frame;await process_frame
 var ids=[];for b in g.buttons:ids.append(b.id)
 check(not ids.has("forge_open") and (ids.has("iron_selected") or ids.has("help:craft_upgrade")) and (ids.has("infuse_open") or ids.has("help:infuse")) and (ids.has("salvage_selected") or ids.has("help:scrap")),"Crafting actions are shown directly in equipment")
 print(JSON.stringify({"failures":failures,"floors":floor_data,"amulets":rarities}));g.free();quit(0 if failures.is_empty() else 1)
