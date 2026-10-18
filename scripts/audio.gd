class_name SlideAudio
extends Node

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
var last_drag_sound: int = -1000
var last_cue: String = ""
var cue_counts: Dictionary = {}

func _ready() -> void:
	var files: Dictionary = {"button": "click_003", "drag": "wood-slide-soft", "drop": "wood-place-soft", "cancel": "wood-place-soft", "win": "confirmation_001"}
	for key in files:
		effects[key] = load("res://assets/audio/%s.wav" % files[key])
	for i in range(6):
		var player := AudioStreamPlayer.new()
		add_child(player)
		players.append(player)
	music = AudioStreamPlayer.new()
	music.name = "BackgroundMusic"
	var track: AudioStreamOggVorbis = load("res://assets/audio/exploration-theme.ogg")
	track.loop = true
	music.stream = track
	music.volume_db = -60
	add_child(music)
	music.play()

func configure(settings: Dictionary) -> void:
	effects_enabled = bool(settings.get("sound", true))
	music_enabled = bool(settings.get("music", true))
	effects_gain = clampf(float(settings.get("sfx_volume", 0.75)), 0, 1)
	music_gain = clampf(float(settings.get("music_volume", 0.35)), 0, 1)
	if not effects_enabled or effects_gain == 0:
		for player in players:
			player.stop()
	update_music()

func play_cue(cue: String, gain_db: float = 0.0, pitch: float = 1.0) -> void:
	if not effects_enabled or effects_gain <= 0 or not focused or not effects.has(cue):
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

func play_drag() -> void:
	var now: int = Time.get_ticks_msec()
	if now - last_drag_sound < 95:
		return
	last_drag_sound = now
	play_cue("drag", -5, 1.0)

func play_drop() -> void:
	play_cue("drop", -7, randf_range(0.96, 1.02))

func play_cancel() -> void:
	play_cue("cancel", -12, 0.98)

func play_win() -> void:
	play_cue("win", -9)

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
	var target: float = linear_to_db(music_gain) - 13.0 - (7.0 if ducked else 0.0)
	fade = create_tween()
	fade.tween_property(music, "volume_db", target, 0.45)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		focused = false
		for player in players:
			player.stop()
		update_music()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focused = true
		update_music()
