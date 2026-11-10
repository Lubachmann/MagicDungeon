extends SceneTree
# Saved rules 18 contract; current expeditions are covered by the Hearth suites.
const Offers=preload("res://skill_offers.gd")
const Combat=preload("res://combat.gd")
var failures=[]
func check(ok: bool,message: String) -> void:
 if not ok:failures.append(message)
func _initialize() -> void:call_deferred("run")
func foe() -> Dictionary:return {"kind":"enemy","type":1,"name":"Target","hp":500.0,"max":500.0,"attack":5,"armor":0.0,"speed":0.5,"trait":"none","elite":false,"roll_seed":123}
func battle(relics: Array,weapon: String,extra: Dictionary={}) -> Dictionary:
 var build={"auto_flow":true,"elemental_v2":true,"fair_physical":true,"weapon":weapon,"vampirism":0.0,"fire":0,"ice":0,"acid":0,"poison":0,"crit_chance":0.0,"element_interval_scale":1.0}
 build.merge(extra,true)
 var s=Combat.begin(foe(),50,100,10.0,0,0.5,relics,build);s.e_time=100;return s
func run() -> void:
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-skill-tests";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true;g.skills={};preload("res://tools/historical_run.gd").start(g,72,18)
 check(g.run_rules==18,"New runs use new skill rules")
 g.inventory=[g.make_gear("weapon",1,0,[],"axe")];g.equipped={"weapon":0};g.base_elements.ice=1;g.base_elements.poison=1;g.base_elements.acid=1;g.base_elements.fire=1;g.recalculate_stats()
 g.reward_level=3;g.rng.seed=100
 for i in range(100):
  var picked=Offers.choose(g);check(picked.size()==3 and picked.all(func(x):return Offers.rarity(x)=="Common"),"First levels offer three common skills")
 g.reward_level=5;var mid={"Common":0,"Rare":0,"Epic":0};g.rng.seed=200
 for i in range(300):
  for id in Offers.choose(g):mid[Offers.rarity(id)]+=1
 check(mid.Common>0 and mid.Rare>0 and mid.Epic==0,"Middle levels mix common and rare")
 g.reward_level=8;g.rng.seed=300;var seen={};var lucky={"Common":0,"Rare":0,"Epic":0}
 for i in range(600):
  var pick=Offers.choose(g);check(pick.size()==3 and pick[0]!=pick[1] and pick[1]!=pick[2] and pick[0]!=pick[2],"Offers are unique")
  for id in pick:seen[id]=true;lucky[Offers.rarity(id)]+=1
 check(lucky.Common>0 and lucky.Rare>0 and lucky.Epic>0,"Higher levels can offer all rarities")
 check(seen.has("glacial_crusher") and seen.has("toxic_glacier") and seen.has("venom_edge"),"Offers include future-facing weapon and element skills")
 check(lucky.Epic<1800,"Element synergy is not guaranteed")
 g.run_skills={"transmutation":1,"convergence":1,"insight":1};g.rng.seed=300;var upgraded={"Rare":0,"Epic":0}
 for i in range(600):
  var pick=Offers.choose(g);check(pick.size()==4,"Insight offers four choices")
  for id in pick:
   if Offers.rarity(id) in upgraded:upgraded[Offers.rarity(id)]+=1
 check(float(upgraded.Rare+upgraded.Epic)/2400.0>float(lucky.Rare+lucky.Epic)/1800.0,"Skill luck increases higher rarity share")
 var s=battle(["glacial_crusher"],"axe");s.iced=true;var hit=Combat.step(s);check(is_equal_approx(hit.actual_damage,13.0),"Heavy Frost skill increases damage vs slowed enemy")
 s=battle(["glacial_crusher"],"dagger");s.iced=true;hit=Combat.step(s);check(is_equal_approx(hit.actual_damage,10.0),"Heavy Frost skill does not apply to daggers")
 g.inventory[0].plain=true;g.recalculate_stats();var plain_build=g.combat_build();plain_build.crit_chance=0.0
 s=Combat.begin(foe(),50,100,10,0,0.5,["glacial_crusher"],plain_build);s.iced=true;s.e_time=100;hit=Combat.step(s)
 check(is_equal_approx(hit.actual_damage,13.0),"Heavy weapon skill also works with a plain starter axe")
 s=battle(["venom_edge"],"dagger");s.poisoned=true;hit=Combat.step(s);check(is_equal_approx(hit.actual_damage,12.5),"Poison dagger skill works")
 s=battle(["toxic_glacier"],"dagger",{"poison":1,"ice":1});s.poison_counters=2;s.poison_time=0.5;s.p_time=100;hit=Combat.step(s)
 check(hit.poison_tick and is_equal_approx(s.frost_counters,0.5),"Poison tick applies Frost")
 s=battle(["caustic_burn"],"unarmed",{"fire":1});s.acid_stacks=1;s.burns=[{"power":4.0,"until":10.0}];s.fire_time=1;s.fire_until=10;s.p_time=100;hit=Combat.step(s)
 check(hit.burn and is_equal_approx(hit.damage,5.0),"Acid improves burn damage")
 g.run_skills={};preload("res://tools/historical_run.gd").start(g,11,18);g.rooms[g.room].entities[g.pos]={"kind":"salvage"};g.inventory=[g.make_gear("weapon",1,0,[],"balanced"),g.make_gear("helmet",1,0,[],"")];g.equipped={"weapon":0};g.iron=3;g.mode="equipment";g.selected_item=0
 g.queue_redraw();await process_frame;await process_frame
 var actions=[];for button in g.buttons:actions.append(button.id)
 check("iron_selected" in actions and "infuse_open" in actions and "help:scrap" in actions and "forge_open" not in actions,"All crafting options appear in equipment")
 g.action("iron_selected");check(g.inventory[0].level==2 and g.iron==2,"Equipment upgrades selected gear")
 g.action("infuse_open");check(g.mode=="infuse","Equipment opens infusion")
 g.action("infuse:poison");check(g.mode=="equipment" and g.inventory[0].infusion=="poison","Infusion returns to equipment")
 g.selected_item=1;g.action("salvage_selected");check(g.inventory.size()==1,"Equipment scraps selected spare gear")
 g.mode="relic";g.relics=["toxic_glacier"];g.choices=["glacial_crusher","caustic_burn","warded_blade"];g.queue_redraw();await process_frame;await process_frame
 check(g.mode=="relic" and g.choice_ui.summary("glacial_crusher").contains("30%"),"New skill cards render with clear effects")
 g.session.enabled=true;g.session.active=true
 check(g.session.checkpoint() and g.session.continue_run() and "toxic_glacier" in g.relics and "glacial_crusher" in g.choices,"New skills and pending choices survive save and continue")
 g.session.enabled=false
 for suffix in [".run",".run.bak",".run.tmp"]:DirAccess.remove_absolute(g.save_path+suffix)
 print(JSON.stringify({"failures":failures,"normal":lucky,"luck":upgraded}));g.free();quit(0 if failures.is_empty() else 1)
