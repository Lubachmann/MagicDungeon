extends SceneTree
## Current expedition/crafting campaign audit. See VALIDATION_GUIDE.md for assumptions.
const Audit=preload("res://tools/progression_audit.gd")
var failures=[]
var rows=[]
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="res://tests/.progression_audit";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.muted=true;g.sound.set_muted(true)
 var quick="--quick" in OS.get_cmdline_user_args();var seeds=1 if quick else 4;var runs=3
 var profiles=["fresh","developing","established"];var policies=["focused"] if quick else ["cautious","focused"]
 for profile in profiles:
  var weapons=["sword"] if quick or profile=="fresh" else ["sword","dagger","axe","greatblade","ember"]
  for weapon in weapons:
   for policy in policies:
    for seed in range(seeds):
     var audit=Audit.new(g);audit.policy=policy;audit.setup(profile,weapon)
     var campaign=[]
     for attempt in range(runs):
      var row=audit.expedition(900+seed*31+attempt);row["attempt"]=attempt+1
      row["shopping"]=audit.shop()
      campaign.append(row)
      failures.append_array(row.invariant_failures)
      if row.outcome=="blocked":failures.append("Policy could not complete or return: "+profile+" / "+str(row.blocked))
     rows.append({"profile":profile,"weapon":weapon,"policy":policy,"trial":seed,"campaign":campaign})
     print("AUDIT %s / %s / %s / trial %d: %s"%[profile,weapon,policy,seed,str(campaign.map(func(x):return str(x.floor)+":"+x.outcome))])
 var summary=[]
 for profile in profiles:
  var expeditions=[]
  for row in rows:
   if row.profile==profile:expeditions.append_array(row.campaign)
  var wins=0;var floors=[0,0,0,0,0];var unusable=0;var fights=0;var seconds=0.0;var flasks=0
  for row in expeditions:
   wins+=int(row.outcome=="victory");floors[int(row.floor)-1]+=1;unusable+=int(row.validation.unusable_offers)
   for fight in row.validation.encounters:fights+=1;seconds+=float(fight.seconds);flasks+=int(fight.flasks_used)
  summary.append({"profile":profile,"expeditions":expeditions.size(),"victories":wins,"ending_floors":floors,"unusable_offers":unusable,"encounters":fights,"mean_encounter_seconds":seconds/maxi(1,fights),"combat_flasks":flasks})
 DirAccess.make_dir_recursive_absolute("res://work")
 var file=FileAccess.open("res://work/progression_audit.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"build":preload("res://playtest_report.gd").BUILD,"rules":20,"assumptions":["Scripted policies, not human win rates","Tile BFS avoids blocked terrain and locked rewards; rooms use connected graph routes","Combat uses real event loop at 0.25s frames; automatic flasks below 55% HP","Cautious policy uses the visible risk estimator to avoid deadly encounters","One elemental passage per floor; puzzles solved from the displayed order","Profile fixtures seed starting progression explicitly; all later rewards and purchases use game actions"],"failures":failures,"summary":summary,"campaigns":rows},"  "));file.close()
 print(JSON.stringify({"failures":failures,"campaigns":rows.size(),"summary":summary}))
 g.free()
 for suffix in ["", ".tmp", ".run", ".run.bak", ".run.tmp"]:
  if FileAccess.file_exists("res://tests/.progression_audit"+suffix):DirAccess.remove_absolute("res://tests/.progression_audit"+suffix)
 quit(0 if failures.is_empty() else 1)
