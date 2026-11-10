extends RefCounted
var g
func _init(game):g=game
func handle(id: String) -> bool:
	var s=g.session
	if g.mode=="settings" and g.front_end.display_pending:
		if id=="display_confirm":g.front_end.display_finish(true)
		elif id in ["display_revert","close_menu"]:g.front_end.display_finish(false)
		return true
	if g.mode=="skills" and g.ember_tree.reset_pending:
		if id=="skills_reset_confirm":g.ember_tree.reset();g.ember_tree.reset_pending=false
		elif id in ["skills_reset_cancel","skills_back"]:g.ember_tree.reset_pending=false
		return true
	if id.begins_with("settings_tab:") and g.mode=="settings":g.front_end.settings_group=clampi(int(id.get_slice(":",1)),0,2);g.session.focused=0;return true
	if id.begins_with("tree_tab:") and g.mode=="skills":g.ember_tree.branch=clampi(int(id.get_slice(":",1)),0,3);g.ember_tree.selected="kindling";return true
	if id.begins_with("skill_select:") and g.mode=="skills":g.ember_tree.selected=id.get_slice(":",1);return true
	if id.begins_with("buy"):return true # The old three-stat shop has been replaced.
	if id.begins_with("bind_reset:") and g.mode=="controls":
		var command=id.get_slice(":",1)
		if command in g.controls.DEFAULTS and command!="pause":g.controls.bind(command,g.controls.DEFAULTS[command])
		return true
	if id.begins_with("bind:") and g.mode=="controls":g.controls.capture=id.get_slice(":",1);return true
	match id:
		"continue":
			if g.mode=="title":s.continue_run()
		"new_game","demo_game":
			if g.mode=="title":
				g.demo_run=id=="demo_game"
				g.loadout_menu.open("title",g.demo_run)
		"begin_run":
			if g.mode=="confirm_new":s.start_run(g.demo_run)
		"restart":
			if not s.enabled:return false
			if g.mode in ["dead","won"]:g.loadout_menu.open(g.mode,g.demo_run)
		"skills":
			if g.mode in ["title","dead","won"]:g.ember_tree.return_mode=g.mode;g.mode="skills"
		"skills_back":g.mode=g.ember_tree.return_mode
		"skill_buy":g.ember_tree.buy(g.ember_tree.selected)
		"skills_reset":
			if g.mode=="skills" and g.ember_tree.spent()>0:g.ember_tree.reset_pending=true
		"resume":
			if g.mode=="pause":g.mode=s.paused_from
		"title":s.title()
		"quit":
			if s.checkpoint() and s.save_preferences():g.get_tree().quit()
		"settings":
			if g.mode in ["title","pause","play"]:s.settings_from=g.mode;g.mode="settings"
		"close_menu":
			if g.mode=="settings":g.mode=s.settings_from
			else:return false
		"controls":
			if g.mode=="settings":g.mode="controls"
		"controls_back":g.controls.capture="";g.mode="settings"
		"reset_bindings":g.controls.bindings=g.controls.DEFAULTS.duplicate();s.save_preferences()
		"tutorial_review":g.tutorial_return=g.mode;g.tutorial_step=0;g.mode="tutorial"
		"tutorial_next","tutorial_skip":
			if g.mode!="tutorial":return true
			if id=="tutorial_skip" or g.tutorial_step>=g.front_end.TUTORIAL.size()-1:
				s.preferences.tutorial_done=true
				s.save_preferences()
				g.mode=g.tutorial_return
			else:g.tutorial_step+=1
		"exact_forecasts":s.preferences.exact_forecasts=false;s.save_preferences()
		"text_size":s.preferences.large_text=not s.preferences.large_text;s.save_preferences()
		"reduce_flashes":s.preferences.reduced_flashes=not s.preferences.reduced_flashes;s.save_preferences()
		"display_toggle":
			if g.mode=="settings":g.front_end.display_begin()
		"music_up","music_down":g.sound.music_volume=clampf(g.sound.music_volume+(0.1 if id=="music_up" else -0.1),0,1);s.save_preferences()
		"ambience_up","ambience_down":g.sound.ambience_volume=clampf(g.sound.ambience_volume+(0.1 if id=="ambience_up" else -0.1),0,1);s.save_preferences()
		"shrine_leave":
			if g.mode=="shrine":g.mode="play"
		"shrine_temper","shrine_embers":
			if g.mode!="shrine":return true
			var shrine=g.rooms[g.room].entities.get(g.pos,{})
			if shrine.get("kind","")!="shrine" or shrine.get("used",false):return true
			if id=="shrine_temper":
				if g.hp<=8 or g.max_hp<=28 or not g.equipped.has("weapon"):return true
				if g.run_rules>=20:
					g.vitality_tax+=8;g.hp-=8;g.bonus.attack+=3;g.recalculate_stats();shrine.used=true;g.mode="play";g.log_line("Shrine: +3 attack for this expedition; -8 current and maximum HP.");g.sfx("blessing");return true
				g.vitality_tax+=8
				g.hp-=8
				g.inventory[g.equipped.weapon].level+=1
				g.recalculate_stats()
				g.log_line("Shrine: weapon tempered; -8 current and maximum HP for this run.")
			else:g.shards+=4;g.log_line("Shrine extinguished: +4 embers.")
			shrine.used=true
			g.mode="play"
			g.sfx("blessing")
		_:return false
	return true
