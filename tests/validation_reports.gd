extends SceneTree
var failures=[]
var checks=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.validation_reports";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.career=g.replay.new_career();g.new_run(613)
 var rng_before=g.rng.state;var data=g.playtest.validation()
 check(data.floors.size()==1 and data.starting_loadout.size()>0,"Run starts with floor and equipment snapshot")
 var workshop=g.smithy.data();var old=int(data.starting_workshop.slot_levels.weapon);workshop.slot_levels.weapon=old+1
 check(data.starting_workshop.slot_levels.weapon==old,"Starting workshop is an independent snapshot")
 g.playtest.offer(["attack"]);g.playtest.selected("attack")
 check(data.offers.size()==1 and data.offers[0].chosen=="attack","Offer and selection recorded")
 for i in range(150):g.playtest.offer([])
 check(data.offers.size()==128,"Offer storage is bounded")
 for i in range(40):g.floor_number=i+2;g.playtest.floor_entered()
 check(data.floors.size()==32,"Floor storage is bounded")
 check(g.rng.state==rng_before,"Telemetry never consumes gameplay randomness")
 g.floor_number=1;g.playtest.crafted(workshop,"axe");g.playtest.crafted(workshop,"dagger")
 check(workshop.metrics.crafts==2 and workshop.metrics.first_craft.item=="axe","First craft recorded only once")
 g.session.active=true
 check(g.playtest.export_report("res://tests/.validation_export"),"Report exports")
 var report=JSON.parse_string(FileAccess.get_file_as_string(g.playtest.last_path))
 check(report.report_schema==2 and report.active_run.metrics.validation.offers.size()==128,"Export includes bounded validation data")
 var snapshot=g.session.snapshot();check(g.session.valid(snapshot),"Telemetry is valid in checkpoint schema")
 g.new_run(615);var tile=Vector2i(3,5);g.rooms[g.room].walls.erase(tile)
 g.rooms[g.room].entities[tile]={"kind":"enemy","type":0,"name":"Report target","level":1,"hp":1,"max":1,"attack":1,"armor":0,"speed":0.2,"trait":"none","elite":false,"roll_seed":123}
 g.game_move_player(Vector2i.RIGHT)
 check(g.playtest.validation().has("current"),"Encounter starts through real movement")
 for frame in range(100):
  if g.mode!="fight":break
  g._process(0.25)
 var fights=g.playtest.validation().encounters
 check(fights.size()==1 and fights[0].won and fights[0].seconds>0 and fights[0].has("recap"),"Real combat records outcome, duration and recap")
 g.session.enabled=true;g.session.active=true
 check(g.session.checkpoint() and g.session.continue_run() and g.playtest.validation().encounters.size()==1,"Validation data survives checkpoint roundtrip")
 g.session.enabled=false
 g.new_run(614);check(g.playtest.validation().offers.is_empty(),"Next expedition clears old telemetry")
 print(JSON.stringify({"checks":checks,"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
