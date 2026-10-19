extends SceneTree

var app
var failures: int = 0
var backups: Dictionary = {}
const SAVES = ["user://session-v2.json", "user://profile.json", "user://custom_picture.png"]

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func capture(name: String) -> void:
	await create_timer(0.65).timeout
	if DisplayServer.get_name() != "headless":
		root.get_texture().get_image().save_png("res://artifacts/" + name + ".png")

func overview() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var sheet := Image.create(930, 942, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("e7dfd2"))
	var screens := ["02-home", "03-levels", "06-gallery", "09-themes", "04-numbers", "07-pictures", "14-number-result", "15-stats"]
	for i in range(screens.size()):
		var shot := Image.load_from_file(ProjectSettings.globalize_path("res://artifacts/" + screens[i] + ".png"))
		shot.convert(Image.FORMAT_RGBA8)
		shot.resize(215, 450, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(shot, Rect2i(0, 0, 215, 450), Vector2i(14 + i % 4 * 229, 14 + i / 4 * 464))
	sheet.save_png("res://artifacts/overview.png")
	var detail := Image.create(906, 624, false, Image.FORMAT_RGBA8)
	detail.fill(Color("e7dfd2"))
	var detail_screens := ["18-photo-detail", "14-number-result", "13-photo-result"]
	for i in range(detail_screens.size()):
		var shot := Image.load_from_file(ProjectSettings.globalize_path("res://artifacts/" + detail_screens[i] + ".png"))
		shot.convert(Image.FORMAT_RGBA8)
		shot.resize(286, 600, Image.INTERPOLATE_LANCZOS)
		detail.blit_rect(shot, Rect2i(0, 0, 286, 600), Vector2i(12 + i * 298, 12))
	detail.save_png("res://artifacts/polish-preview.png")

func run() -> void:
	for path in SAVES:
		if FileAccess.file_exists(path):
			backups[path] = FileAccess.get_file_as_bytes(path)
	app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	app.active_session = false
	app.profile = SlideProfile.new()
	app.profile.settings.language = "vi"
	app.apply_preferences()
	app.go("splash")
	await capture("01-splash")
	app.go("home")
	await capture("02-home")
	# Verify nested miniature/label controls do not consume card clicks.
	var home_buttons: Array[Node] = root.find_children("*", "Button", true, false)
	var mode_card: Button
	for item in home_buttons:
		if item.name == "NumberModeCard":
			mode_card = item
			break
	check(mode_card != null, "Home mode card exists")
	if mode_card:
		var point: Vector2 = mode_card.global_position + Vector2(65, 60)
		var hover := InputEventMouseMotion.new()
		hover.position = point
		Input.parse_input_event(hover)
		await process_frame
		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		down.position = point
		Input.parse_input_event(down)
		await process_frame
		var up := InputEventMouseButton.new()
		up.button_index = MOUSE_BUTTON_LEFT
		up.position = point
		Input.parse_input_event(up)
		await create_timer(0.12).timeout
		check(app.screen == "levels", "Card accepts clicks over its thumbnail (screen: %s, position: %s)" % [app.screen, point])
	app.begin_flow(false)
	await capture("03-levels")
	app.new_game(4)
	await process_frame
	await process_frame
	await capture("04-numbers")
	for node_name in ["PauseButton"]:
		var circle := app.page.find_child(node_name, true, false) as Button
		check(is_equal_approx(circle.size.x, circle.size.y), node_name + " stays square in its container")
		check(circle.icon_alignment == HORIZONTAL_ALIGNMENT_CENTER, node_name + " icon is centered")
	for node_name in ["Undo", "ThemeButton"]:
		var button := app.page.find_child(node_name, true, false) as SlideButton
		check(button.body.visible and not button.flat, node_name + " retains its button background")
	# Explicitly simulate foreground state; approval/UI focus can steal the test window.
	app.audio._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	app.apply_preferences()
	await create_timer(0.12).timeout
	check(app.audio.music.stream is AudioStreamOggVorbis and app.audio.music.stream.loop, "Background music is a looped imported Ogg")
	check(app.audio.music.stream.get_length() > 120, "Background music decodes full track")
	check(app.audio.music.playing and app.audio.music.get_playback_position() > 0, "Music playback advances")
	for cue in ["button", "drop", "cancel", "undo", "redo", "hint", "restart", "win"]:
		check(app.audio.effects[cue].get_length() > 0, "Imported SFX decodes: " + cue)
	var animated = app.hint_button
	animated.press_feedback()
	await create_timer(0.09).timeout
	check(animated.scale.x < 0.98, "Button visibly compresses on press")
	animated.release_feedback()
	await create_timer(0.075).timeout
	check(animated.scale.x > 1.0, "Button springs past rest scale on release")
	await create_timer(0.2).timeout
	check(is_equal_approx(animated.scale.x, 1.0), "Button returns to normal size")
	app.profile.settings.animation = false
	app.apply_preferences()
	check(app.profile.settings.animation and SlideUI.animations_enabled, "Animations are always on")
	var board = app.board
	var original: Array[int] = app.puzzle.cells.duplicate()
	var index: int = app.puzzle.neighbors(app.puzzle.cells.find(0))[0]
	var point: Vector2 = board.target(index) + Vector2.ONE * board.tile_step() * 0.5
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = board.global_position + point
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = down.position
	Input.parse_input_event(up)
	await process_frame
	check(app.puzzle.moves == 1, "Touch tap moves legal tile")
	app.undo_move()
	check(app.puzzle.cells == original, "Undo restores board")
	app.redo_move()
	check(app.puzzle.moves == 1 and app.puzzle.cells != original, "Redo replays the undone move")
	app.undo_move()
	check(app.puzzle.cells == original, "Undo after redo restores board")
	board.press(point, 0)
	board.motion(point + board.drag_axis * board.tile_step() * 0.12)
	board.release_drag(point + board.drag_axis * board.tile_step() * 0.12)
	check(app.puzzle.moves == 0, "Short drag cancels")
	board.press(point, 0)
	var sounds_before_drag: Dictionary = app.audio.cue_counts.duplicate()
	for fraction in [0.15, 0.3, 0.5, 0.65]:
		board.motion(point + board.drag_axis * board.tile_step() * fraction)
	check(app.audio.cue_counts == sounds_before_drag, "Dragging stays silent until release")
	board.release_drag(point + board.drag_axis * board.tile_step() * 0.65)
	check(app.puzzle.moves == 1, "Long drag commits")
	check(not app.audio.effects.has("drag"), "No drag sound is loaded")
	check(int(app.audio.cue_counts.get("drop", 0)) > 0, "Committed move plays tile placement")
	check(int(app.audio.cue_counts.get("cancel", 0)) > 0, "Cancelled drag plays return sound")
	app.hint_move()
	check(app.hints_left == 2 and board.hint_tile > 0, "Hint highlights a solution tile and spends one charge")
	check(app.puzzle.can_move(app.puzzle.cells.find(board.hint_tile)), "Hint is a legal move")
	app.pause_game()
	check(board.locked and is_instance_valid(app.overlay), "Pause locks board")
	var pause_buttons: Array[Node] = app.overlay.find_children("*", "Button", true, false)
	check(pause_buttons.size() == 2, "Home/pause menu contains exactly two options")
	if pause_buttons.size() == 2:
		check(pause_buttons[0].text == "Tiếp tục" and pause_buttons[1].text == "Về màn hình chính", "Home/pause menu labels match requested actions")
	check(app.audio.ducked, "Pause ducks background music")
	var saved: Array[int] = app.puzzle.cells.duplicate()
	board.press(point, 0)
	check(board.drag_id == -1, "Paused board rejects input")
	await capture("05-pause")
	app.close_overlay()
	check(not app.audio.ducked, "Resume restores normal music level")
	var home_button := app.page.find_child("PauseButton", true, false) as Button
	home_button.pressed.emit()
	await create_timer(0.12).timeout
	check(is_instance_valid(app.overlay), "In-game Home button opens pause choices")
	var home_options: Array[Node] = app.overlay.find_children("*", "Button", true, false)
	if home_options.size() == 2:
		home_options[1].pressed.emit()
		await create_timer(0.12).timeout
		check(app.screen == "home" and app.puzzle.cells == saved, "Home option returns to main screen and retains board")
		var resume := app.page.find_child("ResumeButton", true, false) as Button
		check(resume != null, "Home screen offers saved game resume")
		if resume:
			resume.pressed.emit()
			await create_timer(0.12).timeout
			check(app.screen == "game" and app.puzzle.cells == saved, "Continue returns to the exact saved board")
	app.save_session()
	app.puzzle.reset(3)
	app.load_session()
	check(app.puzzle.cells == saved and app.puzzle.history.size() == 1, "Save restores board and undo chain; cells=%s expected=%s history=%s" % [app.puzzle.cells, saved, app.puzzle.history])
	check(app.hints_left == 2, "Save restores remaining hints")
	app.restart_game()
	check(app.puzzle.cells == original and app.puzzle.moves == 0, "Restart restores original shuffle")
	app.begin_flow(true)
	await capture("06-gallery")
	var gallery_card := app.page.find_child("PhotoCard0", true, false) as Button
	gallery_card.pressed.emit()
	await create_timer(0.12).timeout
	check(app.screen == "levels" and app.pending_picture == 0, "Full-bleed photo card opens the selected image level flow")
	app.pending_picture = 1
	app.new_game(3)
	await capture("07-pictures")
	var picture_gap: float = app.board.tile_gap()
	app.board.photo_mode = false
	check(picture_gap < app.board.tile_gap() * 0.65, "Picture gaps are narrower than number gaps")
	app.board.photo_mode = true
	check(SlideUI.photo_finish_texture() != null, "Each photo tile has a beveled reflective finish")
	# A near-solved visual fixture makes picture seams and the bevel easy to inspect.
	app.puzzle.reset(3, false)
	app.puzzle.slide(7)
	app.board.sync_positions()
	app.on_moved()
	await capture("18-photo-detail")
	app.new_game(3)
	await process_frame
	await process_frame
	app.board.preview = true
	await capture("08-preview")
	app.board.preview = false
	app.go("themes")
	await capture("09-themes")
	var badge := app.page.find_child("SelectionBadge", true, false) as Control
	check(badge != null, "Selected material has a blue check badge")
	if badge:
		check(badge.position.x > badge.get_parent().size.x * 0.6 and badge.position.y < 10, "Selection badge stays at top-right of material preview")
	var theme_card := app.page.find_child("ThemeCard3", true, false) as Button
	theme_card.pressed.emit()
	await create_timer(0.12).timeout
	check(int(app.profile.settings.theme) == 3 and app.screen == "themes", "Material preview card changes and persists selection")
	app.profile.settings.theme = 1
	app.go("game")
	check(app.board.theme_id == 1, "Selected theme applied to game")
	app.go("settings")
	await capture("10-settings")
	app.profile.settings.sound = false
	app.profile.settings.music = false
	app.profile.settings.music_volume = 0.24
	app.profile.settings.animation = false
	app.apply_preferences()
	check(app.audio.music.stream_paused, "Music toggle pauses only music stream")
	var cue_total: int = int(app.audio.cue_counts.get("drop", 0))
	app.audio.play_drop()
	check(int(app.audio.cue_counts.get("drop", 0)) == cue_total, "Muted effects do not play")
	app.profile.save()
	var loaded := SlideProfile.new()
	loaded.load_data()
	check(not loaded.settings.sound and int(loaded.settings.theme) == 1, "Settings persist")
	check(not loaded.settings.music and is_equal_approx(loaded.settings.music_volume, 0.24), "Music preference and volume persist")
	app.profile.settings.sound = true
	app.profile.settings.music = true
	app.apply_preferences()
	app.audio._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(app.audio.music.stream_paused, "Music stops while app is in background")
	app.audio._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	check(not app.audio.music.stream_paused, "Music resumes with app focus")
	app.profile.settings.animation = true
	app.profile.settings.theme = 0
	app.go("help")
	await capture("11-help")
	app.go("daily")
	await capture("12-daily")
	app.new_game(3, true)
	var daily_cells: Array[int] = app.puzzle.cells.duplicate()
	app.new_game(3, true)
	check(app.puzzle.cells == daily_cells, "Daily shuffle deterministic")
	await process_frame
	await process_frame
	# Finish through the input controller and verify result bookkeeping once.
	app.puzzle.reset(3, false)
	app.puzzle.slide(7)
	app.board.sync_positions()
	app.elapsed = 42
	var finish: Vector2 = app.board.target(8) + Vector2.ONE * app.board.tile_step() * 0.5
	app.board.press(finish, 0)
	app.board.release_drag(finish)
	check(app.puzzle.solved(), "Final move solves board")
	check(app.profile.stats.pictures.wins == 1, "Win counted")
	app.on_completed()
	check(app.profile.stats.pictures.wins == 1, "Duplicate completion ignored")
	check(app.profile.daily_wins.has(app.today()), "Daily completion persisted")
	await create_timer(1.4).timeout
	check(app.screen == "result", "Completion opens result screen")
	app.picture_index = 1
	app.go("result")
	await capture("13-photo-result")
	app.photo_mode = false
	app.go("result")
	await capture("14-number-result")
	app.stats_photo = true
	app.go("stats")
	await capture("15-stats")
	check(app.profile.achievements(true)[0], "First-win achievement unlocked")
	app.import_picture(ProjectSettings.globalize_path("res://assets/kitten.png"))
	check(app.screen == "levels" and app.pending_picture == -1, "Custom image routes to level selection")
	check(app.selected_picture().get_width() == 1024, "Imported image square crop")
	root.content_scale_size = Vector2i(360, 780)
	root.size = Vector2i(360, 780)
	app.new_game(5)
	await create_timer(0.3).timeout
	check(app.board.size.x <= 360, "Small screen fits board width")
	check(is_equal_approx(app.board.size.x, app.board.size.y), "Small screen board stays square")
	await capture("16-small-screen")
	root.content_scale_size = Vector2i(430, 900)
	root.size = Vector2i(430, 900)
	app.go("home")
	await capture("17-home-resume")
	# The visual audit uses real laid-out controls at common portrait sizes.
	for dimensions in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(430, 900)]:
		root.content_scale_size = dimensions
		root.size = dimensions
		for destination in ["home", "levels", "gallery", "themes", "game", "result", "settings", "stats", "help", "daily"]:
			app.go(destination)
			await create_timer(0.12).timeout
			var margin := app.page.get_node("Scroll/Margin") as Control
			check(margin.size.x <= dimensions.x + 1, "%s fits %s without horizontal overflow (actual %s)" % [destination, dimensions, margin.size])
			if dimensions.x == 360:
				await capture("mobile-" + destination)
			if destination == "game":
				for node_name in ["PauseButton"]:
					var circle := app.page.find_child(node_name, true, false) as Control
					check(is_equal_approx(circle.size.x, circle.size.y), node_name + " remains round at " + str(dimensions))
	app.go("settings")
	await capture("settings-top")
	app.page.get_node("Scroll").scroll_vertical = 9999
	await capture("settings-bottom")
	overview()
	# Restore the user's data, leaving testing statistics out of the app.
	root.remove_child(app)
	app.free()
	for path in SAVES:
		if backups.has(path):
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(backups[path])
			file.close()
		elif FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("PASS: full app flow, two-option Home menu, imported icons/audio, button press/spring, silent dragging, placement/return sounds, looping music, mute/volume/focus, persistence, mobile layout" if failures == 0 else "FAILED: %d checks" % failures)
	quit(0 if failures == 0 else 1)
