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
	var draft_image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	draft_image.fill(Color.RED)
	var draft := ImageTexture.create_from_image(draft_image)
	preview.draft_slot = "home"
	preview.draft_texture = draft
	preview.on_preview_selected(["home", 3, "vi", 0])
	check(preview.backdrop.scenic == draft, "Unsaved Home background is rendered without changing catalogue")
	preview.draft_slot = "theme-3"
	preview.on_preview_selected(["game", 3, "vi", 0])
	check(preview.backdrop.game_override == draft, "Unsaved theme background appears on its game preview")
	preview.draft_texture = null
	preview.background_textures["game"] = draft
	preview.show_preview()
	check(preview.backdrop.game_override == draft, "Staged theme reset previews the shared background")
	preview.background_textures.clear()
	preview.draft_slot = ""
	preview.on_preview_selected(["home", 0, "vi", 0])
	check(preview.backdrop.scenic == preload("res://assets/home-soft.png"), "Discarding a draft restores the configured background")
	preview.save_session()
	preview.profile.save()
	check(not FileAccess.file_exists(preview.SAVE_PATH) and not FileAccess.file_exists(SlideProfile.PATH), "Preview does not create game saves or a player profile")
	root.remove_child(preview)
	preview.free()
	await process_frame
	print("PASS: Home and game previews, theme/language, locked board, input guard, no game saves" if failures == 0 else "FAILED: %d checks" % failures)
	quit(0 if failures == 0 else 1)
