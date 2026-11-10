extends SceneTree
var failures=[]
func check(ok: bool,message: String):
 if not ok:failures.append(message)
func _initialize():call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate();g.save_path="/private/tmp/magic-ui-synergy";root.add_child(g);await process_frame;g.session.enabled=false;g.set_process(false);g.career=g.replay.new_career();g.new_run(9)
 var offers=load("res://skill_offers.gd");var stats=load("res://build_stats.gd")
 var needs=offers.build_requirements(g,"venom_edge",stats.calculate(g))
 check("dagger" in needs and "Poison" in needs,"Synergy shows missing weapon and element")
 var dagger=g.smithy.make_item("dagger",1);g.inventory=[dagger];g.equipped={"weapon":0};g.base_elements.poison=1
 needs=offers.build_requirements(g,"venom_edge",stats.calculate(g));check(needs.is_empty(),"Synergy recognizes the current weapon and element")
 check(offers.build_requirements(g,"toxic_glacier",stats.calculate(g)).is_empty(),"Poison-to-Frost synergy does not falsely require Frost")
 g.mode="character";g.action("journal_permanent");check(g.journal_permanent_open,"Permanent progress opens separately from run information")
 g.queue_redraw();await process_frame;check(g.buttons.any(func(b):return b.id=="journal_permanent_back"),"Permanent progress has a return action")
 g.action("close_menu");check(not g.journal_permanent_open and g.mode=="character","Back returns to the run journal")
 g.run_bounties={"slayer":false,"wardens":true};g.action("journal_bounties");check(g.journal_bounties_open,"Bounties open separately from the tracked goal")
 g.queue_redraw();await process_frame;check(g.buttons.any(func(b):return b.id=="journal_bounties_back"),"Bounty panel has a back action")
 g.action("close_menu");check(not g.journal_bounties_open and g.mode=="character","Back from bounties returns to journal")
 g.mode="expedition";g.replay.draft={"mode":"standard","vows":{"fury":1}};g.action("expedition_details");check(g.replay.expedition_details_open,"Mode and vow details open")
 g.queue_redraw();await process_frame;check(g.buttons.any(func(b):return b.id=="expedition_details_back"),"Mode details can be closed")
 g.action("expedition_back");check(not g.replay.expedition_details_open and g.mode=="expedition","Back closes details without leaving setup")
 g.mode="settings";g.action("settings_tab:1");check(g.front_end.settings_group==1,"Settings can switch to Audio")
 g.queue_redraw();await process_frame;check(g.buttons.any(func(b):return b.id=="music_up"),"Audio controls appear in Audio tab")
 g.action("settings_tab:2");g.queue_redraw();await process_frame;check(g.buttons.any(func(b):return b.id=="controls"),"Controls appear in their own tab")
 g.mode="codex";g.action("codex_keyboard");g.queue_redraw();await process_frame;check(g.buttons.any(func(b):return b.id=="codex_key:A"),"Controller keyboard provides letter buttons")
 print(JSON.stringify({"failures":failures}));g.free();quit(0 if failures.is_empty() else 1)
