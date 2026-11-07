extends RefCounted
var g
var last_path=""
func _init(game):g=game
func export_report(directory: String="user://playtests") -> bool:
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))!=OK:return false
	var data={"build":"0.16.0","run_history":g.career.history.duplicate(true),"mastery":g.career.get("mastery",{}).duplicate(true),"exact_forecasts":bool(g.session.preferences.exact_forecasts)}
	if g.session.active:data["active_run"]={"rules":g.run_rules,"seed":g.run_seed,"floor":g.floor_number,"level":g.character_level,"kills":g.kills,"tree_ranks":g.run_skills.duplicate(true),"metrics":g.run_metrics.duplicate(true),"equipment":g.replay.equipment_report(),"relics":g.relics.duplicate(),"elements":g.elements.duplicate(),"vows":g.run_settings.get("vows",{}).duplicate(),"totals":preload("res://build_stats.gd").calculate(g)}
	last_path=directory.path_join("MagicDungeon-playtest-%d.json"%Time.get_unix_time_from_system())
	var file=FileAccess.open(last_path,FileAccess.WRITE)
	if not file:return false
	file.store_string(JSON.stringify(data,"  "));file.close();return true
func handle(id: String) -> bool:
	if id=="export_playtest":
		if export_report():g.ui_help.show("playtest_export")
		else:g.log_line("Could not save the report. Check that the game can write to its data folder.")
		return true
	if id=="report:open":OS.shell_open(ProjectSettings.globalize_path(last_path.get_base_dir()));return true
	return false
