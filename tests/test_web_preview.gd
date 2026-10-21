extends SceneTree

var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func run() -> void:
	var preview = load("res://web_preview.tscn").instantiate()
	root.add_child(preview)
	await process_frame
	await process_frame
	check(preview.screen == "home", "Preview starts at Home")
	for destination in preview.PREVIEW_SCREENS:
		preview.on_preview_selected([destination, 3, "vi", 0])
		await process_frame
		check(is_instance_valid(preview.page), "Screen renders: " + destination)
		if is_instance_valid(preview.board):
			check(preview.board.locked, "Preview board is locked: " + destination)
		check(preview.input_guard.get_index() == preview.get_child_count() - 1, "Preview input guard stays above screen: " + destination)
	preview.on_preview_selected(["game", 7, "en", 0])
	check(preview.board.theme_id == 7 and SlideI18n.language == "en", "Theme and language selectors update the actual screen")
	var cells: Array[int] = preview.puzzle.cells.duplicate()
	var time: float = preview.elapsed
	await create_timer(0.15).timeout
	check(preview.elapsed == time and preview.puzzle.cells == cells, "Preview does not run a game timer or change the board")
	preview.go("settings")
	check(preview.screen == "game", "App navigation cannot leave the selected preview screen")
	preview.save_session()
	preview.profile.save()
	check(not FileAccess.file_exists(preview.SAVE_PATH) and not FileAccess.file_exists(SlideProfile.PATH), "Preview does not create game saves or a player profile")
	root.remove_child(preview)
	preview.free()
	await process_frame
	print("PASS: Home and game previews, theme/language, locked board, input guard, no game saves" if failures == 0 else "FAILED: %d checks" % failures)
	quit(0 if failures == 0 else 1)
