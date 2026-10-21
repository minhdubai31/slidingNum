extends SceneTree

# Logic checks for the backend catalogue. The player's real catalogue is moved aside first and restored afterwards,
# because applying an update prunes image files that the test does not own.

class OfflineCatalogue extends SlideCatalogue:
	func start_request(_url: String) -> void:
		pass

const MAIN = preload("res://scripts/main.gd")
const BACKUP := "user://catalogue_test_backup"
const BASE := "https://example.supabase.co/storage/v1/object/public/pictures/"
const LEGACY_ID := "c45b07f2-8e78-41ad-8463-522fe427da6f"

var failures := 0

func _init() -> void:
	backup_user_catalogue()
	run_checks()
	restore_user_catalogue()
	print("PASS: catalogue naming, legacy record keys, building from files, applying a staged update" if failures == 0 else "FAILED: %d checks" % failures)
	quit(0 if failures == 0 else 1)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func run_checks() -> void:
	check(SlideCatalogue.file_for_url(BASE + "c45b/1792.png") == "c45b_1792.png", "Storage path becomes one flat file name")
	check(SlideCatalogue.picture_path(BASE + "c45b/1792.png") == "user://catalogue/c45b_1792.png", "Pictures are stored in the catalogue folder")

	var fresh := fixture("v1", [
		["Thiên nhiên", [[LEGACY_ID, "c45b/1.png", Color.RED], ["new-1", "new-1/2.png", Color.GREEN]]],
		["Biển", [["new-2", "new-2/3.png", Color.BLUE]]],
	])
	var app = MAIN.new()
	check(app.build_catalogue(fresh), "A complete download builds the catalogue")
	check(app.pictures.size() == 3, "Every picture of every topic is loaded")
	check(str(app.picture_keys) == str(["res://assets/alpine.png", "remote:new-1", "remote:new-2"]), "Seeded pictures keep their legacy keys and new ones get remote keys")
	check(str(app.topic_names) == str(["Thiên nhiên", "Biển"]), "Topic names follow the backend order")
	check(str(app.topic_members) == str([[0, 1], [2]]), "Topics list their picture indexes")
	check(str(app.picture_topics) == str([0, 0, 1]), "Each picture knows its topic")
	check(app.index_of_key("remote:new-2") == 2 and app.index_of_key("missing") == -1, "Keys resolve to picture indexes")

	var before: int = app.pictures.size()
	var broken := fixture("v2", [["Biển", [["new-3", "new-3/4.png", Color.YELLOW]]]], false)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SlideCatalogue.picture_path(BASE + "new-3/4.png")))
	check(not app.build_catalogue(broken) and app.pictures.size() == before, "A missing file leaves the current catalogue untouched")

	var catalogue := SlideCatalogue.new()
	catalogue.active = fixture("v0", [["Cũ", [["old-1", "old/5.png", Color.WHITE]]]])
	catalogue.pending = fresh
	check(catalogue.has_pending(), "A staged catalogue is reported as pending")
	check(catalogue.apply_pending(), "A staged catalogue can be applied")
	check(str(catalogue.active.get("version")) == "v1", "The staged version becomes active")
	check(catalogue.pending.is_empty(), "Applying clears the pending catalogue")
	check(not FileAccess.file_exists(SlideCatalogue.picture_path(BASE + "old/5.png")), "Images of the replaced catalogue are removed")
	check(FileAccess.file_exists(SlideCatalogue.picture_path(BASE + "c45b/1.png")), "Images still in use are kept")
	check(str(SlideCatalogue.read_manifest(SlideCatalogue.ACTIVE_PATH).get("version")) == "v1", "The active manifest is saved to disk")
	check(not FileAccess.file_exists(SlideCatalogue.PENDING_PATH), "The pending manifest file is removed")
	# A cached pending version with missing files must be repaired before it is offered.
	var repair := OfflineCatalogue.new()
	repair.pending = fresh
	var missing_path := SlideCatalogue.picture_path(BASE + "c45b/1.png")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(missing_path))
	repair.on_manifest(JSON.stringify(fresh).to_utf8_buffer())
	check(repair.phase == "file" and repair.current_url == BASE + "c45b/1.png", "Missing staged files are queued for download again")
	var ready_count := [0]
	repair.pending_ready.connect(func(): ready_count[0] += 1)
	var downloaded := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	downloaded.fill(Color.RED)
	repair.on_file(downloaded.save_png_to_buffer())
	check(ready_count[0] == 1 and SlideCatalogue.files_ready(repair.pending), "Update is offered only after the missing image is saved")
	var old_version: String = str(repair.pending.version)
	repair.on_manifest('{"topics":[]}'.to_utf8_buffer())
	check(str(repair.pending.version) == old_version and ready_count[0] == 1, "An invalid manifest does not replace or offer staged content")
	# Failed downloads must not publish a partial candidate.
	repair.candidate = {"version": "broken", "topics": []}
	repair.fetching = true
	repair.on_request_completed(HTTPRequest.RESULT_SUCCESS, 500, PackedStringArray(), PackedByteArray())
	check(not repair.fetching and repair.candidate.is_empty() and str(repair.pending.version) == old_version, "HTTP failure preserves the previous pending update")
	repair.free()
	catalogue.free()
	app.free()

# Builds a manifest shaped like GET /api/topics. Each picture is [id, path under BASE, colour].
func fixture(version: String, topics: Array, write_files: bool = true) -> Dictionary:
	var out: Array = []
	for topic in topics:
		var pictures: Array = []
		for entry in topic[1]:
			var url: String = BASE + str(entry[1])
			if write_files:
				write_png(SlideCatalogue.picture_path(url), entry[2])
			pictures.append({"id": entry[0], "url": url})
		out.append({"name": topic[0], "pictures": pictures})
	return {"version": version, "topics": out}

func write_png(path: String, color: Color) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SlideCatalogue.FILES_DIR))
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(color)
	image.save_png(path)

func backup_user_catalogue() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BACKUP))
	move_if_exists(SlideCatalogue.ACTIVE_PATH, BACKUP + "/catalogue.json")
	move_if_exists(SlideCatalogue.PENDING_PATH, BACKUP + "/catalogue_pending.json")
	move_if_exists(SlideCatalogue.FILES_DIR, BACKUP + "/files")

func restore_user_catalogue() -> void:
	remove_tree(SlideCatalogue.FILES_DIR)
	remove_tree(SlideCatalogue.ACTIVE_PATH)
	remove_tree(SlideCatalogue.PENDING_PATH)
	move_if_exists(BACKUP + "/catalogue.json", SlideCatalogue.ACTIVE_PATH)
	move_if_exists(BACKUP + "/catalogue_pending.json", SlideCatalogue.PENDING_PATH)
	move_if_exists(BACKUP + "/files", SlideCatalogue.FILES_DIR)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP))

func move_if_exists(from: String, to: String) -> void:
	var source := ProjectSettings.globalize_path(from)
	if FileAccess.file_exists(from) or DirAccess.dir_exists_absolute(source):
		DirAccess.rename_absolute(source, ProjectSettings.globalize_path(to))

func remove_tree(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if DirAccess.dir_exists_absolute(absolute):
		for file in DirAccess.get_files_at(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path.path_join(file)))
		DirAccess.remove_absolute(absolute)
	elif FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute)
