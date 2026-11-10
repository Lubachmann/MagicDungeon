extends SceneTree
# Saved rules 18 contract; current expeditions are covered by the Hearth suites.
var failures=[]
func check(v:bool,msg:String):
 if not v:failures.append(msg)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/core_improvements_test";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true;g.skills={};preload("res://tools/historical_run.gd").start(g,42,18)
 check(g.run_rules==18,"New rules apply to new runs")
 var dps=[]
 for weapon in ["balanced","dagger","axe"]:
  var item=g.make_gear("weapon",1,0,[],weapon);item.plain=true;g.inventory=[item];g.equipped={"weapon":0};g.recalculate_stats();dps.append(g.attack*g.speed)
 check(is_equal_approx(dps[0],dps[1]) and is_equal_approx(dps[0],dps[2]),"Plain starting weapons have equal pre-armor base damage per second")
 g.run_rules=9;var old=g.make_gear("weapon",1,0,[],"axe");g.inventory=[old];g.equipped={"weapon":0};g.recalculate_stats();check(is_equal_approx(g.attack,26.6),"Existing run keeps old axe balance")
 preload("res://tools/historical_run.gd").start(g,42,18);g.hp=10;g.potions=1;g.fight=g.make_enemy(0,0);g.fight.position=g.pos+Vector2i.RIGHT;g.battle=g.Combat.begin(g.fight,g.hp,g.max_hp,g.attack,g.armor,g.speed,g.relics,g.combat_build());g.mode="fight"
 var expected=mini(g.max_hp,10+25);g.action("heal");check(g.hp==expected and g.battle.hp==expected and g.potions==0 and g.summary.flasks==1,"Combat flask heals current battle and consumes one")
 g.action("heal");check(g.hp==expected and g.potions==0,"No extra healing without flasks")
 g.session.enabled=true;g.session.active=true;check(g.session.checkpoint() and g.session.continue_run() and g.hp==expected and g.battle.hp==expected and g.potions==0,"Combat flask survives save and continue")
 g.session.enabled=false;g.session.active=false
 for suffix in [".run",".run.bak",".run.tmp"]:DirAccess.remove_absolute(g.save_path+suffix)
 g.battle.done=true;g.potions=1;g.hp=1;g.battle.hp=1;g.action("heal");check(g.hp==1 and g.potions==1,"Finished combat cannot be revived with a flask")
 preload("res://tools/historical_run.gd").start(g,42,18);g.run_rules=10;check("black_ice" in g.relic_pool(),"Older run keeps its early Black Ice pool")
 g.base_elements.ice=1;g.character_level=3;g.recalculate_stats();g.offer_relic();check("black_ice" in g.choices,"Early Frost investment offers a visible synergy")
 g.run_rules=9;check("black_ice" not in g.relic_pool(),"Older run keeps original unlock pool")
 g.run_rules=10;g.recalculate_stats();var enemy=g.make_enemy(0,0);enemy.hp=1000;enemy.max=1000;var build=g.combat_build();build["ice"]=1;var battle=g.Combat.begin(enemy,100,100,20,0,1,["frost"],build);battle.iced=true;battle.e_time=100;var hit=g.Combat.step(battle)
 check(hit.get("combo_element","")=="frost" and hit.damage>0,"Frost damage synergy produces visible feedback")
 g.mode="equipment";g.rooms[g.room].entities[g.pos]={"kind":"salvage"};g.queue_redraw();await process_frame;await process_frame
 var craft=[];for b in g.buttons:craft.append(b.id)
 check(not craft.has("forge_open") and (craft.has("infuse_open") or craft.has("help:infuse")),"Crafting is accessible directly in equipment")
 g.mode="settings";g.session.preferences.exact_forecasts=true;g.action("exact_forecasts");check(not g.session.preferences.exact_forecasts,"Exact forecast option disabled for existing preferences")
 check(g.front_end.TUTORIAL.size()==2,"Opening guidance is concise")
 g.free();print(JSON.stringify({"failures":failures,"starter_dps":dps}));quit(0 if failures.is_empty() else 1)
