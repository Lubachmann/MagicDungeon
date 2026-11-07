extends Node
## Separate footstep voice and a bounded effects pool allow overlapping cues.
const EVENTS = ["step_a", "step_b", "swing", "hurt", "block", "door", "pickup", "equip", "break", "heal", "blessing", "relic", "victory", "death", "click", "error"]
const CUES={"heavy_impact":["hurt",0.72,-5.0],"evade":["swing",1.8,-5.0],"critical":["swing",0.7,1.0],"guard_break":["break",0.8,0.0],"interrupt":["block",1.5,-2.0],"vamp":["heal",1.35,-6.0],"ward":["blessing",0.7,-4.0],"flare":["blessing",0.85,-1.0],"burn":["hurt",1.4,-9.0],"resonance":["relic",1.3,-5.0]}
var streams: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var footstep: AudioStreamPlayer
var next_voice = 0
var step_count = 0
var volume = 0.7
var muted = false
var ambience_volume=0.25
var ambience_voice: AudioStreamPlayer
var ambient_streams: Array=[]
var ambient_theme=-1
var music_volume=0.35
var music_voice: AudioStreamPlayer
var music_streams={}
var current_music=""

func _ready() -> void:
	for event in EVENTS:
		var stream = load("res://assets/audio/" + event + ".ogg") as AudioStreamOggVorbis
		stream.loop = false
		streams[event] = stream
	for theme in ["keep","archive","crypt"]:
		var track=load("res://assets/ambience/"+theme+".wav") as AudioStreamWAV
		track.loop_mode=AudioStreamWAV.LOOP_FORWARD
		track.loop_begin=0
		track.loop_end=int(track.get_length()*track.mix_rate)
		ambient_streams.append(track)
	for track_id in ["hearth","dungeon","dungeon_fire","dungeon_mystic"]:
		var track=load("res://assets/music/"+track_id+".ogg") as AudioStreamOggVorbis
		if track:track.loop=true;music_streams[track_id]=track
	music_voice=AudioStreamPlayer.new();add_child(music_voice)
	ambience_voice=AudioStreamPlayer.new()
	add_child(ambience_voice)
	footstep = AudioStreamPlayer.new()
	add_child(footstep)
	for i in range(8):
		var voice = AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)

func play(event: String) -> void:
	if muted or volume <= 0.0: return
	var pitch=1.0;var gain=0.0
	if CUES.has(event):pitch=CUES[event][1];gain=CUES[event][2];event=CUES[event][0]
	var voice: AudioStreamPlayer
	if event == "step":
		if footstep.playing: return
		voice = footstep
		event = "step_a" if step_count % 2 == 0 else "step_b"
		step_count += 1
	else:
		if not streams.has(event): return
		voice = voices[next_voice]
		next_voice = (next_voice + 1) % voices.size()
	voice.pitch_scale=pitch
	voice.stream = streams[event]
	voice.volume_db = linear_to_db(volume) - (15.0 if voice == footstep else 7.0)+gain
	voice.play()

func set_muted(value: bool) -> void:
	muted = value
	if muted:
		ambience_voice.stop()
		if is_instance_valid(music_voice):music_voice.stop()
		footstep.stop()
		for voice in voices: voice.stop()

func change_volume(amount: float) -> void:
	volume = clampf(volume + amount, 0.0, 1.0)
	if volume <= 0.0:
		footstep.stop()
		for voice in voices: voice.stop()
	else:
		footstep.volume_db = linear_to_db(volume) - 15.0
		for voice in voices: voice.volume_db = linear_to_db(volume) - 7.0

func music(track_id: String) -> void:
	if DisplayServer.get_name()=="headless" or not is_instance_valid(music_voice):return
	if not music_streams.has(track_id):return
	if track_id!=current_music:
		current_music=track_id;music_voice.stop();music_voice.stream=music_streams[track_id]
	if muted or music_volume<=0.0:music_voice.stop();return
	music_voice.volume_db=linear_to_db(music_volume)-8.0
	if not music_voice.playing:music_voice.play()

func _exit_tree() -> void:
	if is_instance_valid(music_voice):music_voice.stop();music_voice.stream=null
	music_streams.clear()
	if is_instance_valid(ambience_voice):ambience_voice.stop();ambience_voice.stream=null
	ambient_streams.clear()
	if is_instance_valid(footstep):
		footstep.stop()
		footstep.stream = null
	for voice in voices:
		voice.stop()
		voice.stream = null
	streams.clear()

func ambience(theme: int,quiet: bool=false) -> void:
	if DisplayServer.get_name()=="headless":return
	if not is_instance_valid(ambience_voice):return
	if muted or ambience_volume<=0:
		ambience_voice.stop()
		return
	if theme!=ambient_theme or ambience_voice.stream==null:
		ambient_theme=theme
		ambience_voice.stream=ambient_streams[clampi(theme,0,2)]
		ambience_voice.stop()
	ambience_voice.volume_db=linear_to_db(ambience_volume)-15.0-(4.0 if quiet else 0.0)
	if not ambience_voice.playing:ambience_voice.play()
