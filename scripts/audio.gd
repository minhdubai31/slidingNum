class_name SlideAudio
extends Node

const MUSIC_FILES = ["res://assets/audio/exploration-theme.ogg", "res://assets/audio/calm-theme.ogg", "res://assets/audio/waiting-ii.ogg"]
var track_index: int = 0
var track_queue: Array[int] = []

var victory: AudioStreamPlayer
var celebrating: bool = false
var music: AudioStreamPlayer
var players: Array[AudioStreamPlayer] = []
var effects: Dictionary = {}
var effects_enabled: bool = true
var music_enabled: bool = true
var effects_gain: float = 0.75
var music_gain: float = 0.35
var focused: bool = true
var ducked: bool = false
var fade: Tween
var last_cue: String = ""
var cue_counts: Dictionary = {}

func _ready() -> void:
	var files: Dictionary = {"button": "click_003", "drop": "drop_003", "cancel": "back_001", "undo": "back_001", "redo": "drop_004", "hint": "confirmation_001", "restart": "drop_004", "win": "success-soft"}
	for key in files:
		effects[key] = load("res://assets/audio/%s.wav" % files[key])
	victory = AudioStreamPlayer.new()
	victory.name = "VictorySound"
	add_child(victory)
	victory.finished.connect(func():
		celebrating = false
		update_music()
	)
	for i in range(6):
		var player := AudioStreamPlayer.new()
		add_child(player)
		players.append(player)
	music = AudioStreamPlayer.new()
	music.name = "BackgroundMusic"
	music.volume_db = -60
	add_child(music)
	music.finished.connect(next_track)
	play_track(0)

func play_track(index: int) -> void:
	track_index = index
	var track: AudioStreamOggVorbis = load(MUSIC_FILES[index])
	track.loop = false
	music.stream = track
	music.volume_db = -60
	music.play()
	update_music()

func next_track() -> void:
	if track_queue.is_empty():
		for index in range(MUSIC_FILES.size()):
			if index != track_index:
				track_queue.append(index)
		track_queue.shuffle()
	play_track(track_queue.pop_front())

func configure(settings: Dictionary) -> void:
	effects_enabled = bool(settings.get("sound", true))
	music_enabled = bool(settings.get("music", true))
	effects_gain = clampf(float(settings.get("sfx_volume", 0.75)), 0, 1)
	music_gain = clampf(float(settings.get("music_volume", 0.35)), 0, 1)
	if not effects_enabled or effects_gain == 0:
		for player in players:
			player.stop()
		victory.stop()
		celebrating = false
	update_music()

func play_cue(cue: String, gain_db: float = 0.0, pitch: float = 1.0) -> void:
	if not effects_enabled or effects_gain <= 0 or not focused or not effects.has(cue):
		return
	if celebrating and cue != "button":
		return
	var voice: AudioStreamPlayer = players[0]
	for candidate in players:
		if not candidate.playing:
			voice = candidate
			break
	voice.stream = effects[cue]
	voice.volume_db = linear_to_db(effects_gain) + gain_db
	voice.pitch_scale = pitch
	voice.play()
	last_cue = cue
	cue_counts[cue] = int(cue_counts.get(cue, 0)) + 1

func play_button() -> void:
	play_cue("button", -12, 1.0)

func play_drop() -> void:
	play_cue("drop", -12, randf_range(0.98, 1.02))

func play_cancel() -> void:
	play_cue("cancel", -18, 0.94)

func play_action(cue: String) -> void:
	match cue:
		"drop": play_drop()
		"undo": play_cue("undo", -14, 0.92)
		"redo": play_cue("redo", -16, 1.08)
		"hint": play_cue("hint", -16, 1.18)
		"restart": play_cue("restart", -17, 0.85)

func play_win() -> void:
	if not effects_enabled or effects_gain <= 0 or not focused or celebrating:
		return
	for player in players:
		player.stop()
	celebrating = true
	victory.stream = effects["win"]
	victory.volume_db = linear_to_db(effects_gain) - 5.0
	victory.play()
	last_cue = "win"
	cue_counts["win"] = int(cue_counts.get("win", 0)) + 1
	update_music()

func set_context(is_paused: bool) -> void:
	if ducked != is_paused:
		ducked = is_paused
		update_music()

func update_music() -> void:
	if not is_instance_valid(music):
		return
	if fade and fade.is_valid():
		fade.kill()
	if not focused or not music_enabled or music_gain == 0:
		music.stream_paused = true
		return
	music.stream_paused = false
	if not music.playing:
		music.play()
	var target: float = linear_to_db(music_gain) - 13.0 - (10.0 if celebrating else (7.0 if ducked else 0.0))
	fade = create_tween()
	fade.tween_property(music, "volume_db", target, 0.45)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		focused = false
		if is_instance_valid(victory):
			victory.stop()
		celebrating = false
		for player in players:
			player.stop()
		update_music()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focused = true
		update_music()
