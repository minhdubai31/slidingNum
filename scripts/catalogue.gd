class_name SlideCatalogue
extends Node

# Keeps the picture catalogue in sync with the backend. Each launch checks the API. New pictures are
# downloaded in the background into a pending manifest, and only become active once the player
# accepts the update (apply_pending). Offline or on errors nothing changes.

signal pending_ready

const API_URL := "https://slide-puzzle-backend.vercel.app/api/topics"
const ACTIVE_PATH := "user://catalogue.json"
const PENDING_PATH := "user://catalogue_pending.json"
const FILES_DIR := "user://catalogue"
const STORAGE_MARKER := "/object/public/pictures/"

var active: Dictionary = {}
var pending: Dictionary = {}
var fetching: bool = false
var phase: String = ""
var candidate: Dictionary = {}
var queue: Array[String] = []
var current_url: String = ""
var http: HTTPRequest

func _ready() -> void:
	active = read_manifest(ACTIVE_PATH)
	pending = read_manifest(PENDING_PATH)
	http = HTTPRequest.new()
	http.timeout = 20
	http.request_completed.connect(on_request_completed)
	add_child(http)

# Starts a background check. Ignored while one is still running.
func check() -> void:
	if fetching:
		return
	fetching = true
	phase = "manifest"
	start_request(API_URL)

# Makes the staged catalogue the active one. Returns false when nothing is staged.
func apply_pending() -> bool:
	if pending.is_empty():
		return false
	if not write_manifest(ACTIVE_PATH, pending):
		return false
	active = pending
	pending = {}
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PENDING_PATH))
	prune()
	return true

func start_request(url: String) -> void:
	if http.request(url) != OK:
		finish()

func on_request_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		finish()
		return
	if phase == "manifest":
		on_manifest(body)
	else:
		on_file(body)

func on_manifest(body: PackedByteArray) -> void:
	var data = JSON.parse_string(body.get_string_from_utf8())
	if not data is Dictionary or not data.get("topics") is Array:
		finish()
		return
	var version := str(data.get("version", ""))
	if version.is_empty():
		finish()
		return
	if version == str(active.get("version", "")):
		# Already up to date; any staged copy is now stale.
		if not pending.is_empty():
			pending = {}
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PENDING_PATH))
			prune()
		finish()
		return
	if version == str(pending.get("version", "")) and files_ready(pending):
		finish()
		pending_ready.emit()
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FILES_DIR))
	candidate = data
	queue.clear()
	for url in picture_urls(candidate):
		if not picture_ready(url) and not queue.has(url):
			queue.append(url)
	next_download()

func next_download() -> void:
	if queue.is_empty():
		commit_candidate()
		return
	phase = "file"
	current_url = queue.pop_front()
	start_request(current_url)

func on_file(body: PackedByteArray) -> void:
	var image := Image.new()
	var error: Error = ERR_FILE_UNRECOGNIZED
	match current_url.get_extension().to_lower():
		"png": error = image.load_png_from_buffer(body)
		"jpg", "jpeg": error = image.load_jpg_from_buffer(body)
		"webp": error = image.load_webp_from_buffer(body)
	if error != OK or image.is_empty():
		finish()
		return
	var path := picture_path(current_url)
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		finish()
		return
	file.store_buffer(body)
	var saved := file.get_error() == OK
	file.close()
	if not saved or DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path)) != OK:
		finish()
		return
	next_download()

func commit_candidate() -> void:
	if not write_manifest(PENDING_PATH, candidate):
		finish()
		return
	pending = candidate
	candidate = {}
	prune()
	finish()
	pending_ready.emit()

func finish() -> void:
	fetching = false
	phase = ""
	queue.clear()
	candidate = {}

# Deletes image files that neither the active nor the pending catalogue refers to.
func prune() -> void:
	var keep := {}
	for file in files_of(active) + files_of(pending):
		keep[file] = true
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(FILES_DIR)):
		return
	for file in DirAccess.get_files_at(FILES_DIR):
		if not keep.has(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(FILES_DIR.path_join(file)))

func has_pending() -> bool:
	return not pending.is_empty()

static func picture_urls(manifest: Dictionary) -> Array[String]:
	var urls: Array[String] = []
	for topic in manifest.get("topics", []):
		for picture in topic.get("pictures", []):
			urls.append(str(picture.get("url", "")))
	var backgrounds: Dictionary = manifest.get("backgrounds", {})
	for slot in [backgrounds.get("home"), backgrounds.get("game")] + backgrounds.get("themes", {}).values():
		if slot is Dictionary and not str(slot.get("url", "")).is_empty():
			urls.append(str(slot.url))
	return urls

static func files_of(manifest: Dictionary) -> Array[String]:
	var files: Array[String] = []
	for url in picture_urls(manifest):
		files.append(file_for_url(url))
	return files

# Storage path "<picture id>/<timestamp>.png" becomes one flat file name, so a replaced image never reuses a file.
static func file_for_url(url: String) -> String:
	return url.get_slice(STORAGE_MARKER, 1).replace("/", "_")

static func picture_path(url: String) -> String:
	return FILES_DIR.path_join(file_for_url(url))

static func read_manifest(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary and data.get("topics") is Array:
		return data
	return {}

static func picture_ready(url: String) -> bool:
	var path := picture_path(url)
	if not FileAccess.file_exists(path):
		return false
	var image := Image.load_from_file(path)
	return image != null and not image.is_empty()

static func files_ready(manifest: Dictionary) -> bool:
	for url in picture_urls(manifest):
		if not picture_ready(url):
			return false
	return true

static func write_manifest(path: String, manifest: Dictionary) -> bool:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(manifest))
	var saved := file.get_error() == OK
	file.close()
	return saved and DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path)) == OK
