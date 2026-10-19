extends SceneTree
# Captures every screen at a given size and language for visual review.
# Usage: godot --path . --script tools/capture_screens.gd -- <out_dir> <lang> <width> <height>
func _initialize() -> void:
	call_deferred("run")

const SAVES = ["user://session-v2.json", "user://profile.json", "user://custom_picture.png"]

func run() -> void:
	var backups: Dictionary = {}
	for path in SAVES:
		if FileAccess.file_exists(path):
			backups[path] = FileAccess.get_file_as_bytes(path)
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var dimensions := Vector2i(int(args[2]), int(args[3]))
	root.content_scale_size = dimensions
	root.size = dimensions
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.profile = SlideProfile.new()
	app.profile.settings.language = args[1]
	app.profile.settings.animation = false
	app.active_session = false
	app.apply_preferences()
	var screens := ["home", "levels", "gallery", "themes", "settings", "stats", "help", "daily"]
	for destination in screens:
		app.go(destination)
		await create_timer(0.3).timeout
		root.get_texture().get_image().save_png("%s/%s-%s.png" % [out, args[1], destination])
	app.pending_photo = false
	app.new_game(4)
	await create_timer(0.3).timeout
	root.get_texture().get_image().save_png("%s/%s-game.png" % [out, args[1]])
	app.pause_game()
	await create_timer(0.3).timeout
	root.get_texture().get_image().save_png("%s/%s-pause.png" % [out, args[1]])
	app.close_overlay()
	app.photo_mode = true
	app.new_record = true
	app.go("result")
	await create_timer(0.4).timeout
	root.get_texture().get_image().save_png("%s/%s-result.png" % [out, args[1]])
	app.active_session = false
	root.remove_child(app)
	app.free()
	# Leave the player's saves exactly as they were.
	for path in SAVES:
		if backups.has(path):
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(backups[path])
			file.close()
		elif FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit()
