extends SceneTree
var checks=0
var failures=[]
var rows=[]
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.family_balance";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.skills={};g.new_run(302)
 for weapon in ["sword","dagger","axe","greatblade","ember"]:
  for level in [1,3,5]:
   for style in ["base","keen","swift","bloodbound"]:
    var id=weapon if style=="base" else weapon+"_"+style
    var item=g.smithy.make_item(id,level);var legacy=item.duplicate(true);legacy.erase("family_revision")
    if level==1:
     var old=g.Gear.stats(legacy)
     if style=="keen":check(is_equal_approx(float(old.crit_chance)-(0.02 if weapon=="dagger" else 0),0.03),"Saved Keen retains original crit bonus")
     if style=="swift":check(is_equal_approx(old.speed,0.035),"Saved Swift retains original speed")
     if style=="bloodbound":check(is_equal_approx(old.vampirism,0.0525),"Saved Bloodbound retains original lifesteal")
    for scenario in ["short","armored","critical","elemental","sustained"]:
     for revision in [1,2]:
      item=g.smithy.make_item(id,level,"poison" if scenario=="elemental" else "");item.family_revision=revision
      g.inventory=[item];g.equipped={"weapon":0};g.character_level=level*2-1;g.bonus={"attack":0.0,"armor":0.0,"speed":0.0,"crit_chance":0.35 if scenario=="critical" else 0.0,"crit_mult":0.4 if scenario=="critical" else 0.0};g.relics=[];g.recalculate_stats()
      var total_time=0.0;var total_loss=0.0;var wins=0
      for sample in range(8):
       var health=mini(g.max_hp,roundi(g.max_hp*0.7));var start=health
       for encounter in range(4 if scenario=="sustained" else 1):
        var hp=25+level*10 if scenario=="short" else 100+level*35
        var foe={"type":0,"name":"Audit foe","hp":hp,"max":hp,"attack":3+level,"armor":12+level*3 if scenario=="armored" else 0,"speed":0.25,"trait":"none","roll_seed":100+sample*7919+encounter*5231}
        var state=g.Combat.begin(foe,health,g.max_hp,g.attack,g.armor,g.speed,g.relics,g.combat_build());var steps=0
        while not state.done and steps<10000:g.Combat.step(state);steps+=1
        check(state.done,"Simulation finishes")
        total_time+=state.time;health=state.hp
        if not state.won:break
        wins+=1
       total_loss+=start-health
      rows.append({"weapon":weapon,"level":level,"style":style,"revision":revision,"scenario":scenario,"seconds":total_time/8,"hp_loss":total_loss/8,"wins":wins})
 var dir="res://work";DirAccess.make_dir_recursive_absolute(dir)
 var file=FileAccess.open(dir+"/weapon_family_balance.json",FileAccess.WRITE);file.store_string(JSON.stringify(rows,"  "));file.close()
 g.free();print(JSON.stringify({"checks":checks,"failures":failures,"rows":rows.size()}));quit(0 if failures.is_empty() else 1)
