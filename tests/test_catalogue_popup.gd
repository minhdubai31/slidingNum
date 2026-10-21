extends SceneTree

var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func run() -> void:
	var app = load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.profile.settings.language = "vi"
	app.go("settings", false)
	app.catalogue.pending = {"version": "popup-test", "topics": []}
	app.catalogue.pending_ready.emit()
	check(not is_instance_valid(app.overlay), "Update does not interrupt another screen")
	app.go("home", false)
	await process_frame
	check(is_instance_valid(app.overlay), "Returning Home offers the staged update")
	if is_instance_valid(app.overlay):
		var buttons: Array[Node] = app.overlay.find_children("*", "Button", true, false)
		check(buttons.size() == 2 and buttons[0].text == "Tải lại" and buttons[1].text == "Để sau", "Popup offers Reload and Later")
		if buttons.size() == 2:
			buttons[1].pressed.emit()
	await create_timer(0.15).timeout
	app.go("settings", false)
	app.go("home", false)
	await process_frame
	check(not is_instance_valid(app.overlay) and app.catalogue.has_pending(), "Later preserves the download without repeatedly prompting")
	app.show_overlay("Test", "", [["OK", func(): pass]])
	app.catalogue.pending = {"version": "popup-test-2", "topics": []}
	app.catalogue.pending_ready.emit()
	check(app.catalogue_offered == "popup-test", "An existing popup delays the update offer")
	app.close_overlay()
	await process_frame
	check(is_instance_valid(app.overlay) and app.catalogue_offered == "popup-test-2", "Closing another popup reveals the waiting update")
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.GREEN)
	var url := "https://example.supabase.co/storage/v1/object/public/pictures/popup/1.png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SlideCatalogue.FILES_DIR))
	image.save_png(SlideCatalogue.picture_path(url))
	app.catalogue.pending = {"version": "popup-test-2", "topics": [{"name": "Updated", "pictures": [{"id": "popup", "url": url}]}]}
	if is_instance_valid(app.overlay):
		var reload_buttons: Array[Node] = app.overlay.find_children("*", "Button", true, false)
		if not reload_buttons.is_empty():
			reload_buttons[0].pressed.emit()
	await create_timer(0.15).timeout
	check(app.screen == "home" and app.picture_keys == ["remote:popup"] and app.catalogue.active.get("version") == "popup-test-2", "Reload activates the downloaded catalogue and refreshes Home")
	check(not app.catalogue.has_pending() and not is_instance_valid(app.overlay), "Reload clears the staged update and popup")
	root.remove_child(app)
	app.free()
	await process_frame
	await process_frame
	print("PASS: Home update popup, Later, and waiting for another overlay" if failures == 0 else "FAILED: %d checks" % failures)
	quit(0 if failures == 0 else 1)
