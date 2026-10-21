extends "res://scripts/main.gd"

# The Web export renders the actual app screens with an in-memory profile and a locked board.
# It only writes the downloaded content cache; it never writes player settings, records or saves.
class PreviewProfile extends SlideProfile:
	func load_data() -> void:
		pass
	func save() -> void:
		pass

const PREVIEW_SCREENS = ["home", "game", "photo-game"]
var preview_screen := "home"
var preview_theme := 0
var preview_language := "vi"
var preview_picture := 0
var preview_initialized := false
var input_guard: Control
var select_callback: JavaScriptObject
var refresh_callback: JavaScriptObject
var draft_callback: JavaScriptObject
var draft_slot := ""
var draft_texture: Texture2D
var was_fetching := false

func _ready() -> void:
	profile = PreviewProfile.new()
	profile.settings.language = "vi"
	profile.settings.sound = false
	profile.settings.music = false
	super._ready()
	preview_initialized = true
	set_process_input(false)
	input_guard = Control.new()
	input_guard.name = "PreviewInputGuard"
	input_guard.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	input_guard.mouse_filter = Control.MOUSE_FILTER_STOP
	input_guard.mouse_force_pass_scroll_events = false
	add_child(input_guard)
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		select_callback = JavaScriptBridge.create_callback(on_preview_selected)
		refresh_callback = JavaScriptBridge.create_callback(func(_args): catalogue.check(); notify_preview())
		draft_callback = JavaScriptBridge.create_callback(on_draft_background)
		window.slidePreviewDraft = draft_callback
		window.slidePreview = select_callback
		window.slidePreviewRefresh = refresh_callback
	show_preview()

# Screen buttons, keyboard shortcuts and splash timers cannot navigate the preview.
func go(destination: String, animate: bool = true) -> void:
	if not preview_initialized:
		super.go(destination, animate)

func on_preview_selected(args: Array) -> void:
	if args.size() < 4:
		return
	if str(args[0]) in PREVIEW_SCREENS:
		preview_screen = str(args[0])
	preview_theme = clampi(int(args[1]), 0, U.THEME_NAMES.size() - 1)
	preview_language = str(args[2]) if str(args[2]) in SlideI18n.LANGUAGES else "vi"
	preview_picture = clampi(int(args[3]), 0, pictures.size() - 1)
	show_preview()

func show_preview() -> void:
	profile.settings.theme = preview_theme
	profile.settings.language = preview_language
	photo_mode = preview_screen == "photo-game"
	pending_photo = photo_mode
	picture_index = clampi(preview_picture, 0, pictures.size() - 1)
	pending_picture = picture_index
	picture_topic = picture_topics[picture_index]
	active_session = false
	daily_date = ""
	elapsed = 42.0
	new_record = false
	won_recorded = false
	puzzle.reset(3, true, 42)
	puzzle.moves = 24
	var destination := "game" if photo_mode else preview_screen
	super.go(destination, false)
	for control in page.find_children("*", "Control", true, false):
		control.focus_mode = Control.FOCUS_NONE
	if is_instance_valid(board):
		board.locked = true
	move_child(input_guard, get_child_count() - 1)
	notify_preview()

# Cached changes are applied automatically here, without a gameplay update popup.
func offer_catalogue_update() -> void:
	if not is_instance_valid(catalogue) or not catalogue.has_pending() or not SlideCatalogue.files_ready(catalogue.pending):
		return
	if catalogue.apply_pending():
		load_catalogue(catalogue.active)
		if preview_initialized:
			show_preview()

func notify_preview() -> void:
	if not OS.has_feature("web"):
		return
	var labels: Array[String] = []
	for index in range(pictures.size()):
		labels.append("%s · %d" % [topic_names[picture_topics[index]], index + 1])
	JavaScriptBridge.get_interface("window").slidePreviewStatus(JSON.stringify({"fetching": catalogue.fetching, "pictures": labels, "screen": preview_screen, "theme": preview_theme, "language": preview_language}))

func _process(delta: float) -> void:
	animate_logo(delta)
	if is_instance_valid(catalogue) and catalogue.fetching != was_fetching:
		was_fetching = catalogue.fetching
		notify_preview()

func _notification(_what: int) -> void:
	pass

func save_session() -> void:
	pass

func load_session() -> void:
	pass

# Unsaved images arrive directly from the admin iframe, never through a storage upload.
func on_draft_background(args: Array) -> void:
	draft_texture = null
	draft_slot = str(args[2]) if args.size() >= 3 else ""
	if args.size() >= 3 and args[0] != null:
		var bytes := JavaScriptBridge.js_buffer_to_packed_byte_array(args[0])
		var image := Image.new()
		var error := ERR_FILE_UNRECOGNIZED
		match str(args[1]):
			"png": error = image.load_png_from_buffer(bytes)
			"jpg": error = image.load_jpg_from_buffer(bytes)
			"webp": error = image.load_webp_from_buffer(bytes)
		if error != OK or image.is_empty():
			draft_slot = ""
			return
		draft_texture = ImageTexture.create_from_image(image)
	show_preview()

func apply_backgrounds() -> void:
	super.apply_backgrounds()
	if draft_slot == "home":
		backdrop.scenic = draft_texture if draft_texture else preload("res://assets/home-soft.png")
	elif draft_slot == "game":
		backdrop.game_override = draft_texture
	elif draft_slot == "theme-%d" % preview_theme:
		backdrop.game_override = draft_texture if draft_texture else background_textures.get("game")
