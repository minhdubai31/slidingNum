extends SceneTree
# Use an isolated user-data directory; this test creates/saves games.
var failures: int = 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func count(audio, cue: String) -> int:
	return int(audio.cue_counts.get(cue, 0))
func run() -> void:
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.profile.settings.sound = true
	app.profile.settings.sfx_volume = .75
	app.profile.settings.music = false
	app.apply_preferences()
	app.new_game(3)
	await process_frame
	await process_frame
	var audio = app.audio
	audio._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	check(not audio.effects.has("drag"), "No drag sound is loaded")
	for cue in ["button", "drop", "cancel", "undo", "redo", "hint", "restart", "win"]:
		check(audio.effects[cue].get_length() > 0, "Effect decodes: " + cue)
	app.hint_move()
	check(count(audio, "hint") == 1, "Successful hint plays its cue")
	var board = app.board
	var neighbor: int = app.puzzle.neighbors(app.puzzle.cells.find(0))[0]
	var point: Vector2 = board.target(neighbor) + Vector2.ONE * board.tile_step() * .5
	board.press(point, -1)
	var before: Dictionary = audio.cue_counts.duplicate()
	for fraction in [.08, .12, .18]:
		board.motion(point + board.drag_axis * board.tile_step() * fraction)
	check(audio.cue_counts == before, "Dragging is completely silent")
	board.release_drag(point + board.drag_axis * board.tile_step() * .18)
	check(count(audio, "cancel") == 1, "Returning a short drag plays a quiet cue")
	board.press(point, -1)
	board.motion(point + board.drag_axis * board.tile_step() * .65)
	board.release_drag(point + board.drag_axis * board.tile_step() * .65)
	check(count(audio, "drop") == 1, "Committed move plays placement once")
	app.undo_move()
	check(count(audio, "undo") == 1 and count(audio, "drop") == 1, "Undo has a distinct cue without duplicate placement")
	app.redo_move()
	check(count(audio, "redo") == 1 and count(audio, "drop") == 1, "Redo has a distinct cue without duplicate placement")
	app.restart_game()
	check(count(audio, "restart") == 1, "Confirmed restart has a cue")
	await process_frame
	await process_frame
	app.puzzle.reset(3, false)
	app.puzzle.slide(7)
	app.board.sync_positions()
	point = app.board.target(8) + Vector2.ONE * app.board.tile_step() * .5
	app.board.press(point, -1)
	app.board.release_drag(point)
	check(app.won_recorded and audio.victory.playing, "Winning move starts dedicated victory audio")
	audio.play_win()
	check(count(audio, "win") == 1, "Victory does not stack")
	await create_timer(1.25).timeout
	check(app.screen == "result" and not audio.celebrating, "Result opens and music duck clears")
	audio.configure({"sound": false})
	before = audio.cue_counts.duplicate()
	for cue in ["drop", "undo", "redo", "hint", "restart"]:
		audio.play_action(cue)
	audio.play_cancel()
	audio.play_win()
	check(before == audio.cue_counts, "Muted gameplay cues stay silent")
	audio.configure({"sound": true, "sfx_volume": 0.0})
	audio.play_win()
	check(not audio.victory.playing, "Zero volume silences victory")
	audio.configure({"sound": true, "sfx_volume": .75})
	audio.play_win()
	audio._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not audio.victory.playing and audio.music.stream_paused, "Backgrounding stops sound and music")
	app.queue_free()
	await process_frame
	print("PASS: silent dragging, action cues, victory, mute and focus" if failures == 0 else "FAILED: %d sound checks" % failures)
	quit(0 if failures == 0 else 1)
