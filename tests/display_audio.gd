extends SceneTree
var checks = 0
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://main.gd").new()
	game.save_path = "res://tests/.display-save.json"
	root.add_child(game);preload("res://tools/test_equipment.gd").arm(game)
	game.set_process(false)
	check(ProjectSettings.get_setting("display/window/size/mode") == 3, "Fullscreen default")
	# Resize the viewport and check the input inverse at HUD buttons and board tiles.
	root.content_scale_size = Vector2i.ZERO
	for size in [Vector2i(1280,840), Vector2i(1920,1080), Vector2i(2560,1440), Vector2i(3440,1440), Vector2i(1024,768)]:
		root.size = size
		await process_frame
		var actual = root.get_visible_rect().size
		var scale_factor = minf(actual.x / 1280, actual.y / 840)
		var offset = (actual - Vector2(1280,840) * scale_factor) / 2
		for point in [Vector2(810,240), Vector2(640,420), game.ORIGIN + Vector2(3,5) * game.TILE]:
			check(game.screen_to_design(offset + point * scale_factor).is_equal_approx(point), "Input mapping at " + str(size))
		check(offset.x >= 0 and offset.y >= 0, "Layout stays on screen")
	var sound = game.sound
	check(sound.streams.size() == 16 and sound.voices.size() == 8, "Sounds and voice pool loaded")
	for id in sound.EVENTS:
		check(sound.streams[id] is AudioStreamOggVorbis and sound.streams[id].get_length() > 0 and not sound.streams[id].loop, "Valid one-shot: " + id)
	var rng_before = game.rng.state
	sound.play("step")
	sound.play("swing")
	sound.play("pickup")
	check(sound.footstep != sound.voices[0], "Steps cannot interrupt combat cues")
	check(game.rng.state == rng_before, "Audio cannot change dungeon randomness")
	sound.set_muted(true)
	check(not sound.footstep.playing, "Mute stops steps")
	for voice in sound.voices: check(not voice.playing, "Mute stops effects")
	sound.change_volume(-100)
	check(sound.volume == 0, "Volume lower clamp")
	sound.change_volume(100)
	check(sound.volume == 1, "Volume upper clamp")
	game.queue_free()
	await create_timer(0.2).timeout
	if failures.is_empty(): print("PASS: %d display/audio checks." % checks)
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
