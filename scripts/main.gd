extends Control

const BoardScript = preload("res://scripts/board.gd")
const BackdropScript = preload("res://scripts/backdrop.gd")
const SAVE_PATH = "user://session-v2.json"
const VERSION = "0.7"
const U = preload("res://scripts/ui.gd")
const PHOTO_NAMES = ["Thiên nhiên", "Thú cưng", "Du lịch", "Sa mạc", "Hoa lá", "Vũ trụ"]
const PHOTO_FILES = ["res://assets/alpine.png", "res://assets/kitten-soft.png", "res://assets/seaside.png", "res://assets/oasis.png", "res://assets/flowers.png", "res://assets/cosmos.png"]

var puzzle := SlidePuzzle.new()
var profile := SlideProfile.new()
var board: Control
var page: Control
var column: VBoxContainer
var backdrop: Control
var overlay: Control
var screen: String = ""
var time_label: Label
var moves_label: Label
var status_label: Label
var hint_button: Button
var pictures: Array[Texture2D] = []
var elapsed: float = 0.0
var photo_mode: bool = false
var picture_index: int = 0
var pending_photo: bool = false
var pending_picture: int = 0
var custom_path: String = ""
var active_session: bool = false
var won_recorded: bool = false
var new_record: bool = false
var daily_date: String = ""
var hints_left: int = 3
var initial_cells: Array[int] = []
var initial_solution: Array[int] = []
var stats_photo: bool = false
var save_timer: float = 0.0
var file_dialog: FileDialog
var android_picker: Object
var audio: SlideAudio
var default_font: Font
var bold_font: Font
var test_mode: bool = false
var screen_parents: Dictionary = {"settings": "home", "themes": "home", "help": "home"}
var logo_node: Node2D
var logo_clock: float = 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	DisplayServer.window_set_title("Slide Puzzle")
	default_font = U.font_at(600)
	bold_font = U.font_at(850)
	var app_theme := Theme.new()
	app_theme.default_font = default_font
	app_theme.default_font_size = 17
	theme = app_theme
	profile.load_data()
	if str(profile.settings.language) not in SlideI18n.LANGUAGES:
		profile.settings.language = SlideI18n.detect()
	for path in PHOTO_FILES:
		var imported: Texture2D = load(path)
		pictures.append(crop_texture(imported.get_image()))
	puzzle.reset(4)
	load_session()
	build_sound()
	backdrop = BackdropScript.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.scenic = load("res://assets/home-soft.png")
	backdrop.table = load("res://assets/table-soft.png")
	add_child(backdrop)
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.use_native_dialog = true
	file_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Images"])
	file_dialog.file_selected.connect(import_picture)
	add_child(file_dialog)
	# On Android the system photo chooser is used; elsewhere a desktop file dialog.
	if Engine.has_singleton("ImagePicker"):
		android_picker = Engine.get_singleton("ImagePicker")
		android_picker.connect("image_picked", import_picture)
	resized.connect(on_resized)
	test_mode = OS.get_cmdline_user_args().has("--test-mode")
	go("home" if test_mode else "splash")

# ------------------------------------------------------------------ layout helpers

var last_layout_size: Vector2 = Vector2.ZERO

func on_resized() -> void:
	layout_ui()
	# Size-dependent screens are rebuilt when the window changes noticeably (rotation, split view).
	if last_layout_size != Vector2.ZERO and (absf(size.x - last_layout_size.x) > 24 or absf(size.y - last_layout_size.y) > 80) and screen not in ["splash", ""] and not is_instance_valid(overlay):
		last_layout_size = size
		rebuild.call_deferred()

func rebuild() -> void:
	if screen != "":
		go(screen, false)

func content_width() -> float:
	return size.x - side_margin() * 2.0

func side_margin() -> float:
	return maxf(16, (size.x - 450) / 2.0)

func compact() -> bool:
	return size.x < 390

func go(destination: String, animate: bool = true) -> void:
	apply_preferences()
	last_layout_size = size
	if destination in ["settings", "themes", "help"] and screen in ["home", "game", "settings", "result"] and destination != screen:
		screen_parents[destination] = screen
	if is_instance_valid(board):
		board.locked = true
	board = null
	if is_instance_valid(page):
		remove_child(page)
		page.queue_free()
	close_overlay()
	screen = destination
	time_label = null
	moves_label = null
	status_label = null
	hint_button = null
	backdrop.kind = "scenic" if screen in ["home", "splash"] else ("game" if screen == "game" else ("result" if screen == "result" else "paper"))
	backdrop.photo = current_picture() if screen == "game" and photo_mode else null
	backdrop.animated = bool(profile.settings.animation)
	backdrop.queue_redraw()
	page = Control.new()
	page.name = "Page"
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(page)
	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.add_theme_stylebox_override("scroll", U.panel(Color(0, 0, 0, 0), 0, false))
	var bar := StyleBoxFlat.new()
	bar.bg_color = Color(0.45, 0.36, 0.25, 0.25)
	bar.set_corner_radius_all(3)
	bar.content_margin_left = 3
	scroll.get_v_scroll_bar().add_theme_stylebox_override("grabber", bar)
	scroll.get_v_scroll_bar().add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
	page.add_child(scroll)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 26)
	scroll.add_child(margin)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	layout_ui()
	# Only the celebration and daily screens are centred vertically; list screens keep their header at the top.
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER if screen in ["result", "daily"] else BoxContainer.ALIGNMENT_BEGIN
	match screen:
		"splash": splash_screen()
		"home": home_screen()
		"levels": levels_screen()
		"gallery": gallery_screen()
		"game": game_screen()
		"result": result_screen()
		"themes": themes_screen()
		"settings": settings_screen()
		"stats": stats_screen()
		"help": help_screen()
		"daily": daily_screen()
	if profile.settings.animation and screen != "splash" and animate:
		page.modulate.a = 0.0
		create_tween().tween_property(page, "modulate:a", 1.0, 0.22)
		entrance.call_deferred()

func layout_ui() -> void:
	if not is_instance_valid(page):
		return
	var margin: MarginContainer = page.get_node("Scroll/Margin")
	var side: int = int(side_margin())
	margin.add_theme_constant_override("margin_left", side)
	margin.add_theme_constant_override("margin_right", side)
	if OS.has_feature("mobile"):
		var safe: Rect2i = DisplayServer.get_display_safe_area()
		var display_size: Vector2i = DisplayServer.screen_get_size()
		var safe_top: float = float(safe.position.y) / maxf(1, display_size.y) * size.y
		var safe_bottom: float = float(display_size.y - safe.end.y) / maxf(1, display_size.y) * size.y
		margin.add_theme_constant_override("margin_top", int(maxf(22, safe_top + 8)))
		margin.add_theme_constant_override("margin_bottom", int(maxf(26, safe_bottom + 10)))
	if is_instance_valid(board):
		board.custom_minimum_size.y = maxf(100, minf(size.x - side * 2 - 8, 450))

func gap(height: float = 10) -> Control:
	var item := Control.new()
	item.custom_minimum_size.y = height
	column.add_child(item)
	return item

func centered(value: String, font_size: int, color: Color = U.INK, bold: bool = false) -> Label:
	var item := U.text(value, font_size, color, bold)
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(item)
	return item

func paragraph(value: String, parent: Node = null, color: Color = U.MUTED) -> Label:
	var item := U.text(value, 15, color)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	(parent if parent else column).add_child(item)
	return item

func hrow(parent: Node = null, separation: int = 12) -> HBoxContainer:
	var item := HBoxContainer.new()
	item.add_theme_constant_override("separation", separation)
	(parent if parent else column).add_child(item)
	return item

# Shrinks a label's font until each of its lines fits the given width.
func fit(label: Label, width: float, minimum: int = 10) -> Label:
	var font: Font = label.get_theme_font("font") if label.has_theme_font_override("font") else default_font
	var font_size: int = label.get_theme_font_size("font_size") if label.has_theme_font_size_override("font_size") else 17
	for line in label.text.split("\n"):
		while font_size > minimum and font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
			font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)
	return label

func header(title: String, back: String = "home") -> void:
	var line := hrow()
	var previous := U.action("", func(): go(back), false, "back")
	previous.name = "BackButton"
	previous.flat = true
	previous.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	previous.custom_minimum_size = Vector2(44, 44)
	previous.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	line.add_child(previous)
	var title_label := U.text(title, 22, U.INK, true)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fit(title_label, content_width() - 110)
	line.add_child(title_label)
	var balance := Control.new()
	balance.custom_minimum_size.x = 44
	line.add_child(balance)

func panel_box(parent: Node = null, color: Color = U.CREAM, radius: int = 22) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", soft_card(color, radius))
	(parent if parent else column).add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	panel.add_child(content)
	return content

func soft_card(color: Color, radius: int = 22) -> StyleBoxFlat:
	var skin := U.panel(color, radius)
	skin.border_color = Color(1, 1, 1, 0.75)
	skin.set_border_width_all(0)
	skin.border_width_top = 1
	skin.shadow_color = Color(0.36, 0.25, 0.12, 0.05)
	skin.shadow_size = 6
	skin.shadow_offset = Vector2(0, 2)
	return skin

func icon_image(name: String, length: float, color: String = "493929") -> TextureRect:
	return texture_view(U.icon(name, color), length)

func art_image(name: String, length: float) -> TextureRect:
	return texture_view(SlideArt.icon(name), length)

func texture_view(texture: Texture2D, length: float) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.custom_minimum_size = Vector2.ONE * length
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image

func image_view(texture: Texture2D, height: float) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.custom_minimum_size.y = height
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image

func overlay_fill(parent: Control, child: Control) -> Control:
	child.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(child)
	return child

# Loops a gentle vertical float on an anchored control. Offsets are animated rather than
# position, so a later layout pass cannot snap the control back mid-motion.
func bob(item: Control, distance: float = 5.0, period: float = 2.4, delay: float = 0.0) -> void:
	var top: float = item.offset_top
	var bottom: float = item.offset_bottom
	var lift := func(v: float):
		item.offset_top = top - v
		item.offset_bottom = bottom - v
	var motion := item.create_tween().set_loops()
	motion.tween_interval(delay)
	motion.tween_method(lift, 0.0, distance, period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	motion.tween_method(lift, distance, 0.0, period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func pulse(item: Control, amount: float = 0.1, period: float = 1.4) -> void:
	item.resized.connect(func(): item.pivot_offset = item.size * 0.5)
	item.pivot_offset = item.size * 0.5
	var motion := item.create_tween().set_loops()
	motion.tween_property(item, "scale", Vector2.ONE * (1.0 + amount), period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	motion.tween_property(item, "scale", Vector2.ONE, period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func pop_in(item: Control, delay: float = 0.0, from: float = 0.4) -> void:
	if not profile.settings.animation:
		return
	item.scale = Vector2.ONE * from
	item.modulate.a = 0.0
	var motion := item.create_tween()
	motion.tween_interval(delay)
	motion.tween_callback(func(): item.pivot_offset = item.size * 0.5)
	motion.tween_property(item, "modulate:a", 1.0, 0.16)
	motion.parallel().tween_property(item, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# A primary button whose icon sits right beside its centred label.
func cta(value: String, glyph: String, callback: Callable, height: float = 62) -> SlideButton:
	var b := U.action("", callback, true) as SlideButton
	b.custom_minimum_size.y = height
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", 10)
	overlay_fill(b, line)
	var picture := icon_image(glyph, 22, "ffffff")
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(picture)
	var label := U.text(value, 20, Color.WHITE, true)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.add_theme_color_override("font_shadow_color", Color(0.05, 0.35, 0.05, 0.35))
	label.add_theme_constant_override("shadow_offset_y", 2)
	line.add_child(label)
	b.set_meta("label", label)
	return b

func game_action(value: String, glyph: String, callback: Callable) -> Button:
	var b := U.action("", callback) as SlideButton
	var length: float = floorf(clampf((content_width() - 36.0) / 3.0, 84, 118))
	b.custom_minimum_size = Vector2(length, length * 0.88)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.corner_radius = 24.0
	var stack := VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 5)
	b.add_child(stack)
	var art: bool = glyph == "bulb"
	var picture := art_image("bulb", length * 0.42) if art else icon_image(glyph, length * 0.3, "35291f")
	stack.add_child(picture)
	var caption := U.text(value, 16, U.INK, true)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.name = "Caption"
	fit(caption, length - 14, 11)
	stack.add_child(caption)
	return b

func miniature(n: int, length: float, image: Texture2D = null, theme_index: int = -1) -> Control:
	var mini = BoardScript.new()
	mini.puzzle = SlidePuzzle.new()
	mini.puzzle.reset(n, false)
	mini.locked = true
	mini.font = bold_font
	mini.theme_id = int(profile.settings.theme) if theme_index < 0 else theme_index
	mini.picture = image
	mini.photo_mode = image != null
	mini.show_numbers = false
	mini.hide_numbers = theme_index >= 0
	mini.custom_minimum_size = Vector2.ONE * length
	mini.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if image:
		mini.prepare_photo()
	mini.set_process(false)
	return mini

# ------------------------------------------------------------------ splash & home

func splash_screen() -> void:
	gap(clampf(size.y * 0.1, 30, 90))
	var center := CenterContainer.new()
	var mini := miniature(4, clampf(size.x * 0.45, 150, 200))
	center.add_child(mini)
	column.add_child(center)
	logo()
	centered("Mỗi bước nhỏ, một niềm vui.", 17, Color.WHITE, true)
	gap(clampf(size.y * 0.1, 30, 100))
	var progress := ProgressBar.new()
	progress.custom_minimum_size.y = 10
	progress.show_percentage = false
	var track := U.panel(Color(1, 1, 1, 0.28), 5, false)
	track.set_content_margin_all(0)
	var fill := U.panel(Color("ffd36b"), 5, false)
	fill.set_content_margin_all(0)
	progress.add_theme_stylebox_override("background", track)
	progress.add_theme_stylebox_override("fill", fill)
	column.add_child(progress)
	centered("Đang chuẩn bị những mảnh ghép…", 13, Color.WHITE)
	create_tween().tween_property(progress, "value", 100.0, 1.4).set_trans(Tween.TRANS_SINE)
	pop_in(mini, 0.05, 0.6)
	get_tree().create_timer(1.65).timeout.connect(func():
		if screen == "splash":
			go("home")
	)

func logo() -> void:
	var small: bool = compact() or size.y < 760
	var title_size: int = 66 if small else 78
	var plaque_size := Vector2(270, 78) if small else Vector2(310, 90)
	var lockup := Control.new()
	lockup.name = "Logo"
	lockup.custom_minimum_size.y = title_size * 0.92 + plaque_size.y + 2
	lockup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(lockup)
	# Controls are snapped to whole pixels; a Node2D carrier lets the logo glide at sub-pixel precision.
	var mover := Node2D.new()
	mover.name = "LogoMotion"
	lockup.add_child(mover)
	var floating := Control.new()
	floating.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mover.add_child(floating)
	var fit_logo := func():
		floating.size = lockup.size
		floating.position = -lockup.size * Vector2(0.5, 1.0)
	lockup.resized.connect(fit_logo)
	fit_logo.call()
	var title := U.text("SLIDE", title_size, Color("fffdf8"), true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = -title_size * 0.2
	title.add_theme_color_override("font_shadow_color", Color(0.17, 0.27, 0.36, 0.55))
	title.add_theme_constant_override("shadow_offset_y", 5)
	title.add_theme_constant_override("shadow_outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color("e4edf3"))
	title.add_theme_constant_override("outline_size", 3)
	floating.add_child(title)
	var plaque := TextureRect.new()
	plaque.texture = SlideArt.wood_plaque()
	plaque.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plaque.stretch_mode = TextureRect.STRETCH_SCALE
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plaque.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	plaque.offset_left = -plaque_size.x * 0.5
	plaque.offset_right = plaque_size.x * 0.5
	plaque.offset_top = title_size * 0.92
	plaque.offset_bottom = title_size * 0.92 + plaque_size.y
	floating.add_child(plaque)
	var word := U.text("PUZZLE", int(plaque_size.y * 0.66), Color("ffe3b0"), true)
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	word.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	word.offset_bottom = -plaque_size.y * 0.08
	word.add_theme_color_override("font_outline_color", Color("5a2c10"))
	word.add_theme_constant_override("outline_size", 9)
	word.add_theme_color_override("font_shadow_color", Color(0.22, 0.09, 0.02, 0.7))
	word.add_theme_constant_override("shadow_offset_y", 4)
	word.add_theme_constant_override("shadow_outline_size", 9)
	plaque.add_child(word)
	# Layout may re-place the anchored node at any time, so its offset is reapplied every frame.
	logo_node = mover
	logo_clock = 0.0
	mover.modulate.a = 0.0

func home_screen() -> void:
	column.add_theme_constant_override("separation", 10)
	var top := hrow()
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var settings_button := U.round_action("settings", func(): go("settings"), 44)
	settings_button.name = "SettingsButton"
	top.add_child(settings_button)
	logo()
	var subtitle := centered("Xếp số · Xếp ảnh · Thư giãn mỗi ngày", 15, Color.WHITE, true)
	subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	fit(subtitle, content_width())
	var flexible := gap(0)
	mode_card(false)
	mode_card(true)
	if active_session and not puzzle.solved():
		var resume_button := cta("Tiếp tục ván đang chơi", "play", func(): go("game"), 54)
		resume_button.name = "ResumeButton"
		fit(resume_button.get_meta("label"), content_width() - 60, 13)
		column.add_child(resume_button)
	gap(4)
	var nav := hrow(null, 8)
	nav.name = "HomeNav"
	var cell: float = (content_width() - 24) / 4.0
	var daily_done: bool = profile.daily_wins.has(today())
	var items := [["trophy", "Thành tích", "stats"], ["calendar", "Thử thách\nhằng ngày", "daily"], ["palette", "Giao diện", "themes"], ["gear", "Cài đặt", "settings"]]
	for index in range(items.size()):
		var item: Array = items[index]
		var well_size := Vector2(floorf(minf(cell, 92)), floorf(minf(cell, 92) * 0.72))
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 9)
		nav.add_child(v)
		var b := U.action("", func(): go(item[2])) as SlideButton
		b.name = "Nav" + item[2].capitalize()
		b.palette = ["566466", "343f41", "1c2425"]
		b.corner_radius = 18.0
		b.custom_minimum_size = well_size
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(b)
		var well := CenterContainer.new()
		well.name = "Well"
		overlay_fill(b, well)
		well.offset_bottom = -2
		var picture := art_image(item[0], well_size.y * 0.64)
		well.add_child(picture)
		var caption := U.text(item[1], 14, Color.WHITE, false)
		caption.add_theme_font_override("font", U.font_at(750))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		caption.add_theme_constant_override("shadow_offset_y", 1)
		caption.add_theme_constant_override("shadow_outline_size", 3)
		caption.add_theme_constant_override("line_spacing", -4)
		fit(caption, cell - 2, 10)
		v.add_child(caption)
		pop_in(v, 0.25 + index * 0.07, 0.5)
		if item[2] == "daily" and not daily_done:
			b.add_child(daily_badge(b, well_size))
	# Push the cards and navigation down toward the thumb on tall screens.
	var used: float = 44 + 10 + 165 + 30 + clampf(size.x * 0.36, 128, 156) * 2 + 20 + minf(cell, 92) * 0.7 + 50 + 70 + (62 if active_session and not puzzle.solved() else 0)
	flexible.custom_minimum_size.y = clampf(size.y - used - 40, 6, 150)

func daily_badge(button: Control, well_size: Vector2) -> Control:
	var badge := PanelContainer.new()
	badge.name = "DailyDot"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var red := U.panel(Color("ff3b30"), 11, false)
	red.set_content_margin_all(0)
	red.border_color = Color.WHITE
	red.set_border_width_all(2)
	red.shadow_color = Color(0.5, 0, 0, 0.35)
	red.shadow_size = 3
	red.shadow_offset = Vector2(0, 1)
	badge.add_theme_stylebox_override("panel", red)
	badge.custom_minimum_size = Vector2(22, 22)
	badge.size = Vector2(22, 22)
	var count := U.text("1", 12, Color.WHITE, true)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(count)
	badge.pivot_offset = Vector2(11, 22)
	const REST_Y = -8.0
	var place := func(): badge.position = Vector2(button.size.x - 15, REST_Y)
	button.resized.connect(place)
	place.call()
	badge.scale = Vector2.ZERO
	var appear := badge.create_tween()
	appear.tween_interval(0.7)
	appear.tween_property(badge, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	appear.tween_callback(func():
		# A small hop with squash and stretch every few seconds, instead of a constant pulse.
		var hop := badge.create_tween().set_loops()
		hop.tween_interval(2.6)
		hop.tween_property(badge, "scale", Vector2(1.18, 0.82), 0.09).set_trans(Tween.TRANS_SINE)
		hop.tween_property(badge, "scale", Vector2(0.88, 1.14), 0.11).set_trans(Tween.TRANS_SINE)
		var lift := func(v: float): badge.position.y = REST_Y - v
		hop.parallel().tween_method(lift, 0.0, 7.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		hop.tween_method(lift, 7.0, 0.0, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		hop.parallel().tween_property(badge, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	return badge

func mode_card(photo: bool) -> void:
	var card := U.action("", func(): begin_flow(photo))
	card.name = "PictureModeCard" if photo else "NumberModeCard"
	card.custom_minimum_size.y = clampf(size.x * 0.36, 128, 156)
	card.corner_radius = 24.0
	column.add_child(card)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 16)
	margin.add_child(line)
	var thumb: float = card.custom_minimum_size.y - 26
	line.add_child(miniature(3, thumb, pictures[1] if photo else null))
	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(words)
	var text_width: float = content_width() - thumb - 26 - 32 - 40
	words.add_child(fit(U.text("Xếp ảnh" if photo else "Xếp số", 26, U.INK, true), text_width))
	var description := U.text("Khám phá những\nhình ảnh tuyệt đẹp" if photo else "Thử thách logic\nvới những con số", 15, Color("6f6252"))
	fit(description, text_width, 11)
	words.add_child(description)
	var chevron := icon_image("chevron", 22, "35291f")
	chevron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(chevron)

func begin_flow(photo: bool) -> void:
	pending_photo = photo
	pending_picture = picture_index
	go("gallery" if photo else "levels")

# ------------------------------------------------------------------ levels & gallery

func levels_screen() -> void:
	header("Xếp ảnh" if pending_photo else "Xếp số", "gallery" if pending_photo else "home")
	var thumb: float = clampf(size.x * 0.31, 104, 136)
	for n in [3, 4, 5]:
		var selected: bool = n == puzzle.dimension
		var card := U.action("", func(): request_start(n)) as SlideButton
		card.name = "Level%d" % n
		card.custom_minimum_size.y = thumb + 34
		card.corner_radius = 24.0
		column.add_child(card)
		if selected:
			var ring := Panel.new()
			ring.name = "SelectedRing"
			ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var blue := U.panel(Color(0.85, 0.92, 1.0, 0.45), 24, false)
			blue.border_color = U.BLUE
			blue.set_border_width_all(3)
			ring.add_theme_stylebox_override("panel", blue)
			overlay_fill(card, ring)
			ring.offset_bottom = -2
		var line := HBoxContainer.new()
		line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		line.offset_left = 18
		line.offset_right = -16
		line.offset_top = 15
		line.offset_bottom = -17
		line.add_theme_constant_override("separation", 22)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(line)
		var mini := miniature(n, thumb, selected_picture() if pending_photo else null)
		if not pending_photo:
			mini.hide_numbers = false
		line.add_child(mini)
		var words := VBoxContainer.new()
		words.alignment = BoxContainer.ALIGNMENT_CENTER
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.add_theme_constant_override("separation", 3)
		line.add_child(words)
		words.add_child(U.text("%d × %d" % [n, n], 32 if not compact() else 28, U.BLUE if selected else U.INK, true))
		var count := U.text(U.t("%d mảnh ghép" if pending_photo else "%d ô số") % (n * n - 1), 15, U.BLUE if selected else U.MUTED)
		words.add_child(count)
		var tone: Array = [["Dễ", "d8f4de", "2e8a49"], ["Trung bình", "fdeccb", "c27812"], ["Khó", "fcdcd8", "c8443a"]][n - 3]
		words.add_child(U.chip(tone[0], Color(tone[1]), Color(tone[2])))
		var chevron := icon_image("chevron", 20, "1677ff" if selected else ["e0663a", "1677ff", "a8987f"][n - 3])
		chevron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(chevron)
	paragraph("Chạm vào cấp độ để bắt đầu. Mỗi bàn đều có lời giải.").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func gallery_screen() -> void:
	header("Chọn chủ đề ảnh")
	column.add_theme_constant_override("separation", 14)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	column.add_child(grid)
	var card_size: float = (content_width() - 12) / 2.0
	for i in range(pictures.size()):
		var card := U.action("", func(): pending_picture = i; go("levels"))
		card.name = "PhotoCard%d" % i
		card.flat = true
		card.custom_minimum_size = Vector2(0, card_size * 1.02)
		grid.add_child(card)
		var cover := TextureRect.new()
		cover.texture = pictures[i]
		cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		var finish := ShaderMaterial.new()
		finish.shader = load("res://shaders/photo_card.gdshader")
		cover.material = finish
		cover.resized.connect(func(): finish.set_shader_parameter("rect_size", cover.size))
		overlay_fill(card, cover)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		overlay_fill(card, margin)
		var bottom := VBoxContainer.new()
		bottom.alignment = BoxContainer.ALIGNMENT_END
		bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(bottom)
		var line := HBoxContainer.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bottom.add_child(line)
		var words := VBoxContainer.new()
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.add_theme_constant_override("separation", -2)
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(words)
		var name_label := U.text(PHOTO_NAMES[i], 18, Color.WHITE, true)
		name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
		name_label.add_theme_constant_override("shadow_offset_y", 1)
		words.add_child(fit(name_label, card_size - 50, 12))
		words.add_child(U.text("1 ảnh", 13, Color("e3eeee")))
		var chevron := icon_image("chevron", 16, "ffffff")
		chevron.size_flags_vertical = Control.SIZE_SHRINK_END
		line.add_child(chevron)
	var pick := cta("Chọn ảnh từ thiết bị", "image", open_picture_picker, 56)
	pick.name = "PickPicture"
	column.add_child(pick)

func open_picture_picker() -> void:
	if android_picker:
		android_picker.call("pick_image")
	else:
		file_dialog.popup_centered_ratio(0.85)

func selected_picture() -> Texture2D:
	if pending_picture == -1 and FileAccess.file_exists("user://custom_picture.png"):
		return ImageTexture.create_from_image(Image.load_from_file("user://custom_picture.png"))
	return pictures[posmod(pending_picture, pictures.size())]

func current_picture() -> Texture2D:
	if picture_index == -1 and FileAccess.file_exists("user://custom_picture.png"):
		return ImageTexture.create_from_image(Image.load_from_file("user://custom_picture.png"))
	return pictures[posmod(picture_index, pictures.size())]

func request_start(n: int, daily: bool = false) -> void:
	if active_session and puzzle.moves > 0 and not puzzle.solved():
		show_overlay("Bắt đầu ván mới?", "Ván đang chơi sẽ được thay thế.", [["Bắt đầu", func(): new_game(n, daily)], ["Giữ ván hiện tại", func(): go("game")]])
	else:
		new_game(n, daily)

func new_game(n: int, daily: bool = false) -> void:
	daily_date = today() if daily else ""
	puzzle.reset(n, true, int(today().replace("-", "")) if daily else -1)
	photo_mode = true if daily else pending_photo
	picture_index = 0 if daily else pending_picture
	initial_cells = puzzle.cells.duplicate()
	initial_solution = puzzle.solution.duplicate()
	elapsed = 0
	hints_left = 3
	active_session = true
	won_recorded = false
	new_record = false
	save_session()
	go("game")
	if is_instance_valid(board):
		board.play_intro()

# ------------------------------------------------------------------ game

func stat_pill(glyph: Texture2D, value: String) -> Label:
	var badge := PanelContainer.new()
	var badge_style := U.panel(Color(0.06, 0.035, 0.02, 0.5), 22, false)
	badge_style.content_margin_top = 7
	badge_style.content_margin_bottom = 7
	badge_style.content_margin_left = 14
	badge_style.content_margin_right = 16
	badge_style.border_color = Color(1, 1, 1, 0.08)
	badge_style.set_border_width_all(1)
	badge.add_theme_stylebox_override("panel", badge_style)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 7)
	var picture := texture_view(glyph, 22)
	line.add_child(picture)
	var label := U.text(value, 19, Color.WHITE, true)
	label.custom_minimum_size.x = 22
	line.add_child(label)
	badge.add_child(line)
	badge.set_meta("row", line)
	label.set_meta("pill", badge)
	return label

func game_screen() -> void:
	column.add_theme_constant_override("separation", 10)
	var top := hrow()
	var theme_button := U.round_action("palette", func(): go("themes"), 50)
	theme_button.name = "ThemeButton"
	theme_button.icon = SlideArt.icon("palette")
	theme_button.tooltip_text = U.t("Giao diện")
	top.add_child(theme_button)
	var title := U.text("%d × %d" % [puzzle.dimension, puzzle.dimension], 28, Color.WHITE, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	title.add_theme_constant_override("shadow_offset_y", 2)
	top.add_child(title)
	var pause := U.round_action("pause", pause_game, 50)
	pause.name = "PauseButton"
	top.add_child(pause)
	var stats := hrow(null, 10)
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	time_label = stat_pill(U.icon("clock", "fff8eb"), format_time(elapsed))
	stats.add_child(time_label.get_meta("pill"))
	moves_label = stat_pill(SlideArt.icon("feet_white"), str(puzzle.moves))
	stats.add_child(moves_label.get_meta("pill"))
	# Free space above and below the board is shared equally, so the board sits centred in its area.
	var top_space := Control.new()
	top_space.name = "TopSpace"
	top_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(top_space)
	board = BoardScript.new()
	board.name = "Board"
	board.puzzle = puzzle
	board.picture = current_picture()
	board.photo_mode = photo_mode
	board.font = bold_font
	board.show_numbers = profile.settings.numbers
	board.theme_id = int(profile.settings.theme)
	board.reduced_motion = not profile.settings.animation
	board.custom_minimum_size.y = 380
	board.resized.connect(func():
		if not is_equal_approx(board.custom_minimum_size.y, board.size.x):
			board.custom_minimum_size.y = board.size.x
	)
	board.moved.connect(on_moved)
	board.completed.connect(on_completed)
	board.drag_cancelled.connect(audio.play_cancel)
	column.add_child(board)
	board.sync_positions()
	status_label = centered("Vuốt hoặc chạm ô cạnh khoảng trống", 14, Color("f6e7cf"))
	status_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
	status_label.add_theme_constant_override("shadow_offset_y", 1)
	# Free space goes here, so the controls sit at the bottom of the screen.
	var spacer := Control.new()
	spacer.name = "Spacer"
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var undo_row := hrow(null, 12)
	undo_row.name = "UndoRow"
	undo_row.alignment = BoxContainer.ALIGNMENT_CENTER
	undo_row.add_child(history_button("Hoàn tác", "undo", undo_move, "Undo", puzzle.history.is_empty()))
	undo_row.add_child(history_button("Phục hồi", "redo", redo_move, "Redo", puzzle.redo_stack.is_empty()))
	gap(14)
	var actions := hrow(null, 14)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	var first := game_action("Xem ảnh" if photo_mode else "Trộn số", "eye" if photo_mode else "shuffle", func():
		if not photo_mode:
			show_overlay("Trộn lại bàn?", "Bạn sẽ bắt đầu một ván mới.", [["Trộn số", func(): pending_photo = false; new_game(puzzle.dimension)], ["Hủy", func(): pass]])
	)
	first.name = "Peek" if photo_mode else "Shuffle"
	if photo_mode:
		first.button_down.connect(func(): board.cancel_drag(); board.preview = true)
		first.button_up.connect(func(): if is_instance_valid(board): board.preview = false)
	actions.add_child(first)
	hint_button = game_action("Gợi ý", "bulb", hint_move)
	hint_button.name = "Hint"
	var counter := PanelContainer.new()
	counter.name = "HintBadge"
	counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter.custom_minimum_size = Vector2(30, 30)
	counter.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	counter.offset_left = -24
	counter.offset_top = -10
	counter.offset_right = 6
	counter.offset_bottom = 20
	var badge_skin := U.panel(Color("ff7a1a"), 15)
	badge_skin.set_content_margin_all(2)
	badge_skin.border_color = Color("fff1cf")
	badge_skin.set_border_width_all(2)
	counter.add_theme_stylebox_override("panel", badge_skin)
	var count_text := U.text(str(hints_left), 16, Color.WHITE, true)
	count_text.name = "HintCount"
	count_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	counter.add_child(count_text)
	hint_button.add_child(counter)
	counter.visible = hints_left > 0
	if hints_left > 0:
		pulse(counter, 0.12, 1.6)
	hint_button.disabled = hints_left <= 0 or puzzle.solution.is_empty()
	actions.add_child(hint_button)
	var restart := game_action("Làm lại", "restart", request_restart)
	restart.name = "Restart"
	actions.add_child(restart)
	if not daily_date.is_empty():
		centered(U.t("THỬ THÁCH NGÀY ") + display_date(daily_date), 12, Color("ffe0a2"), true)

func history_button(value: String, glyph: String, callback: Callable, node_name: String, disabled: bool) -> Button:
	var b := U.action(value, callback, false, glyph) as SlideButton
	b.name = node_name
	b.custom_minimum_size = Vector2(150, 46)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_constant_override("icon_max_width", 18)
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", U.INK)
	b.disabled = disabled
	return b

func pause_game() -> void:
	show_overlay("Tạm dừng", "Ván chơi đã được lưu. Bạn muốn làm gì?", [["Tiếp tục", func(): pass], ["Về màn hình chính", func(): save_session(); go("home")]], "pause")

func request_restart() -> void:
	show_overlay("Chơi lại từ đầu?", "Giữ nguyên bàn xếp; đặt lại bước đi và thời gian.", [["Làm lại", restart_game], ["Hủy", func(): pass]], "restart")

func restart_game() -> void:
	puzzle.cells = initial_cells.duplicate()
	puzzle.solution = initial_solution.duplicate()
	puzzle.history.clear()
	puzzle.redo_stack.clear()
	puzzle.moves = 0
	elapsed = 0
	hints_left = 3
	won_recorded = false
	save_session()
	go("game")
	if is_instance_valid(board):
		board.play_intro()
	audio.play_action("restart")

func hint_move() -> void:
	if hints_left <= 0 or puzzle.solution.is_empty() or not is_instance_valid(board):
		return
	var value: int = puzzle.solution[0]
	if not puzzle.can_move(puzzle.cells.find(value)):
		return
	hints_left -= 1
	audio.play_action("hint")
	board.hint_tile = value
	board.hint_until = board.clock + 3.0
	status_label.text = U.t("Di chuyển ô đang sáng vào khoảng trống")
	var counter := hint_button.find_child("HintCount", true, false) as Label
	if counter:
		counter.text = str(hints_left)
		hint_button.find_child("HintBadge", true, false).visible = hints_left > 0
	hint_button.disabled = hints_left <= 0
	save_session()

func undo_move() -> void:
	if puzzle.solved():
		return
	board.cancel_drag()
	if puzzle.undo():
		board.hint_tile = -1
		on_moved("undo")

func redo_move() -> void:
	if puzzle.solved():
		return
	board.cancel_drag()
	if puzzle.redo():
		board.hint_tile = -1
		on_moved("redo")

func on_moved(cue: String = "drop") -> void:
	audio.play_action(cue)
	if profile.settings.haptic and OS.has_feature("mobile"):
		Input.vibrate_handheld(12)
	if is_instance_valid(moves_label):
		moves_label.text = str(puzzle.moves)
		if profile.settings.animation:
			moves_label.pivot_offset = moves_label.size * 0.5
			var bump := moves_label.create_tween()
			bump.tween_property(moves_label, "scale", Vector2.ONE * 1.18, 0.08)
			bump.tween_property(moves_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_instance_valid(board):
		board.hint_tile = -1
	if is_instance_valid(status_label):
		status_label.text = U.t("Vuốt hoặc chạm ô cạnh khoảng trống")
	if is_instance_valid(page):
		var undo := page.find_child("Undo", true, false) as Button
		if undo:
			undo.disabled = puzzle.history.is_empty() or puzzle.solved()
		var redo := page.find_child("Redo", true, false) as Button
		if redo:
			redo.disabled = puzzle.redo_stack.is_empty() or puzzle.solved()
	save_session()

func on_completed() -> void:
	if won_recorded or not puzzle.solved():
		return
	won_recorded = true
	audio.play_win()
	new_record = profile.record_win(photo_mode, elapsed, puzzle.moves, puzzle.dimension, daily_date)
	board.locked = true
	status_label.text = U.t("Tuyệt vời! Bạn đã hoàn thành.")
	save_session()
	get_tree().create_timer(1.1 if profile.settings.animation else 0.1).timeout.connect(func():
		if screen == "game" and puzzle.solved():
			go("result")
	)

# ------------------------------------------------------------------ result

func result_screen() -> void:
	column.add_theme_constant_override("separation", 12)
	var top_gap: float = clampf(size.y * 0.04, 8, 40)
	gap(top_gap)
	var hero := Control.new()
	hero.name = "VictoryHero"
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hero_height: float = clampf(size.y * 0.4, 260, 340)
	hero.custom_minimum_size.y = hero_height
	column.add_child(hero)
	backdrop.focus_y = (22 + top_gap + hero_height * 0.4) / maxf(size.y, 1)
	backdrop.result_glow = null
	var stage := Control.new()
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.offset_bottom = -64
	hero.add_child(stage)
	if photo_mode:
		var side: float = minf(hero_height - 84, content_width() * 0.62)
		for mirror in [false, true]:
			var leaves := texture_view(SlideArt.laurel(mirror), 0)
			leaves.stretch_mode = TextureRect.STRETCH_SCALE
			leaves.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
			var leaf_w: float = side * 0.36
			leaves.offset_left = (side * 0.5 - leaf_w * 0.35) if mirror else (-side * 0.5 - leaf_w * 0.65)
			leaves.offset_right = leaves.offset_left + leaf_w
			leaves.offset_bottom = 30
			leaves.offset_top = 30 - leaf_w * 2.0
			stage.add_child(leaves)
			if profile.settings.animation:
				leaves.pivot_offset = Vector2(leaf_w * (0.2 if mirror else 0.8), leaf_w * 2.0)
				var sway := leaves.create_tween().set_loops()
				sway.tween_property(leaves, "rotation", deg_to_rad(4 if mirror else -4), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				sway.tween_property(leaves, "rotation", 0.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var frame := PanelContainer.new()
		frame.name = "VictoryReward"
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		frame.offset_left = -side * 0.5
		frame.offset_right = side * 0.5
		frame.offset_top = 22 - side
		frame.offset_bottom = 22
		var frame_skin := U.panel(Color("fff8ec"), 20)
		frame_skin.set_content_margin_all(6)
		frame_skin.shadow_color = Color(0, 0, 0, 0.35)
		frame_skin.shadow_size = 14
		frame_skin.shadow_offset = Vector2(0, 6)
		frame.add_theme_stylebox_override("panel", frame_skin)
		stage.add_child(frame)
		var reward := image_view(current_picture(), 0)
		var material := ShaderMaterial.new()
		material.shader = load("res://shaders/photo_card.gdshader")
		material.set_shader_parameter("shade_strength", 0.0)
		material.set_shader_parameter("radius", 15.0)
		reward.material = material
		reward.resized.connect(func(): material.set_shader_parameter("rect_size", reward.size))
		frame.add_child(reward)
		for corner in [[-0.5, -1.0, 34.0], [0.5, -0.92, 26.0]]:
			var heart := texture_view(SlideArt.icon("heart"), corner[2])
			heart.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
			heart.offset_left = side * corner[0] - corner[2] * 0.5
			heart.offset_top = 22 + side * corner[1] - corner[2] * 0.5
			heart.offset_right = heart.offset_left + corner[2]
			heart.offset_bottom = heart.offset_top + corner[2]
			heart.rotation = deg_to_rad(-18 if corner[0] < 0 else 16)
			stage.add_child(heart)
			pop_in(heart, 0.6 + corner[0] * 0.2, 0.0)
			bob(heart, 6.0, 1.4, 0.9 + corner[0] * 0.3)
		if profile.settings.animation:
			frame.resized.connect(func(): frame.pivot_offset = frame.size * Vector2(0.5, 1.0))
			frame.rotation = deg_to_rad(-8)
			frame.scale = Vector2.ONE * 0.5
			var appear := frame.create_tween()
			appear.tween_property(frame, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			appear.parallel().tween_property(frame, "rotation", deg_to_rad(-2.5), 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			appear.tween_callback(func():
				var rock := frame.create_tween().set_loops()
				rock.tween_property(frame, "rotation", deg_to_rad(2.0), 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				rock.tween_property(frame, "rotation", deg_to_rad(-2.5), 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			)
	else:
		var reward := image_view(load("res://assets/trophy-soft.png"), 0)
		reward.name = "VictoryReward"
		reward.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		reward.offset_top = 0
		reward.offset_bottom = 34
		stage.add_child(reward)
		if profile.settings.animation:
			reward.resized.connect(func(): reward.pivot_offset = reward.size * Vector2(0.5, 0.8))
			reward.scale = Vector2.ONE * 0.3
			var appear := reward.create_tween()
			appear.tween_property(reward, "scale", Vector2.ONE, 0.65).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			appear.tween_callback(func(): bob(reward, 6.0, 2.6))
	var ribbon := Control.new()
	ribbon.name = "Ribbon"
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribbon.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	var overhang: float = minf(side_margin() - 4, 22)
	ribbon.offset_left = -overhang
	ribbon.offset_right = overhang
	ribbon.offset_top = -86
	ribbon.offset_bottom = 0
	hero.add_child(ribbon)
	var ribbon_art := image_view(load("res://assets/ui/victory-ribbon.svg"), 0)
	ribbon_art.stretch_mode = TextureRect.STRETCH_SCALE
	overlay_fill(ribbon, ribbon_art)
	var congrats := U.text("Hoàn thành!", 38, Color.WHITE, true)
	congrats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	congrats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	congrats.add_theme_color_override("font_shadow_color", Color("a8241b"))
	congrats.add_theme_constant_override("shadow_offset_y", 3)
	congrats.add_theme_color_override("font_outline_color", Color("c53023"))
	congrats.add_theme_constant_override("outline_size", 4)
	fit(congrats, content_width() - 40)
	overlay_fill(ribbon, congrats)
	congrats.offset_bottom = -8
	if profile.settings.animation:
		ribbon.resized.connect(func(): ribbon.pivot_offset = ribbon.size * 0.5)
		ribbon.scale = Vector2(0.2, 0.6)
		ribbon.modulate.a = 0.0
		var unfurl := ribbon.create_tween()
		unfurl.tween_interval(0.25)
		unfurl.tween_property(ribbon, "modulate:a", 1.0, 0.1)
		unfurl.parallel().tween_property(ribbon, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		unfurl.tween_callback(func():
			var wiggle := congrats.create_tween().set_loops()
			congrats.pivot_offset = congrats.size * 0.5
			wiggle.tween_interval(1.6)
			wiggle.tween_property(congrats, "scale", Vector2(1.06, 0.95), 0.12)
			wiggle.tween_property(congrats, "scale", Vector2(0.97, 1.04), 0.12)
			wiggle.tween_property(congrats, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)
	var results := panel_box(null, Color("fff8ec"), 20)
	results.name = "ResultCard"
	results.add_theme_constant_override("separation", 10)
	var entries := [["clock", "Thời gian", elapsed, true], ["steps", "Số bước", float(puzzle.moves), false], ["grid", "Kích thước", "%d × %d" % [puzzle.dimension, puzzle.dimension], false], ["star", "Kỷ lục mới", "NEW" if new_record else "—", false]]
	for i in range(entries.size()):
		var item: Array = entries[i]
		var line := hrow(results)
		line.add_child(art_image("feet", 24) if item[0] == "steps" else icon_image(item[0], 24, "35291f"))
		var caption := U.text(item[1], 17)
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(caption)
		if i == 3 and new_record:
			var pill := U.chip("NEW", Color("f04a35"), Color.WHITE, 13)
			pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			line.add_child(pill)
			pulse(pill, 0.12, 1.0)
		else:
			var value := U.text(str(item[2]) if item[2] is String else (format_time(item[2]) if item[3] else str(int(item[2]))), 18, U.INK, true)
			line.add_child(value)
			if not item[2] is String and profile.settings.animation:
				var target: float = item[2]
				var as_time: bool = item[3]
				value.create_tween().tween_method(func(v: float): value.text = format_time(v) if as_time else str(int(round(v))), 0.0, target, 0.9).set_delay(0.45 + i * 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if i < entries.size() - 1:
			var separator := HSeparator.new()
			var rule := StyleBoxLine.new()
			rule.color = Color(0.63, 0.51, 0.34, 0.16)
			rule.thickness = 1
			separator.add_theme_stylebox_override("separator", rule)
			results.add_child(separator)
	gap(2)
	var navigation := hrow(null, 12)
	navigation.name = "ResultActions"
	var home := U.action("", func(): go("home")) as SlideButton
	home.name = "ResultHome"
	home.dark = true
	var home_label := U.text("Trang chủ", 17, Color("fff8eb"), true)
	fit(home_label, 96, 12)
	var home_width: float = maxf(128, 52 + bold_font.get_string_size(home_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, home_label.get_theme_font_size("font_size")).x + 22)
	home.custom_minimum_size = Vector2(home_width, 64)
	home.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	navigation.add_child(home)
	var home_content := HBoxContainer.new()
	home_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home_content.alignment = BoxContainer.ALIGNMENT_CENTER
	home_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home_content.add_theme_constant_override("separation", 9)
	home.add_child(home_content)
	home_content.add_child(icon_image("home", 26, "fff8eb"))
	home_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	home_content.add_child(home_label)
	var next := cta("Chơi tiếp", "play", func(): pending_photo = photo_mode; pending_picture = picture_index; new_game(puzzle.dimension), 64)
	next.name = "ResultNext"
	fit(next.get_meta("label"), content_width() - home_width - 70, 14)
	navigation.add_child(next)
	pop_in(home, 0.9, 0.5)
	pop_in(next, 1.0, 0.5)

# ------------------------------------------------------------------ themes

func material_preview(theme_index: int, width: float) -> Control:
	var preview := Control.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.custom_minimum_size = Vector2(width, width * 2.0 / 3.0)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var faces := Control.new()
	faces.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faces.texture_filter = preview.texture_filter
	var finish := ShaderMaterial.new()
	finish.shader = load("res://shaders/block.gdshader")
	finish.set_shader_parameter("light_strength", 0.22)
	finish.set_shader_parameter("shine", 0.07)
	finish.set_shader_parameter("shadow_strength", 0.45)
	faces.material = finish
	preview.add_child(faces)
	var cells: Array[Rect2] = []
	preview.draw.connect(func():
		var rect := Rect2(Vector2.ZERO, preview.size)
		SlideArt.draw_frame(preview, rect, theme_index, 3, 2)
		var u: float = rect.size.y / 260.0
		var pad: float = 15.0 * u
		var step := Vector2((rect.size.x - pad * 2) / 3.0, (rect.size.y - pad * 2) / 2.0)
		var gutter: float = 7.0 * u
		var tile := step - Vector2.ONE * gutter
		var radius: float = tile.x * 0.105
		finish.set_shader_parameter("block_size", tile)
		finish.set_shader_parameter("corner", maxf(3.0, radius))
		finish.set_shader_parameter("bevel", maxf(2.0, radius * 0.8))
		cells.clear()
		for i in range(6):
			var origin: Vector2 = Vector2(pad, pad) + Vector2(i % 3, i / 3) * step + Vector2.ONE * gutter * 0.5
			var cell := Rect2(origin, tile)
			SlideArt.draw_slot(preview, cell, theme_index, radius)
			if i == 5:
				continue
			SlideArt.draw_tile_shadow(preview, cell, radius, u)
			var side := StyleBoxFlat.new()
			side.bg_color = Color(SlideArt.material(theme_index).side)
			side.set_corner_radius_all(int(radius))
			preview.draw_style_box(side, Rect2(cell.position + Vector2(0, 3.2 * u), cell.size))
			cells.append(cell)
		faces.queue_redraw()
	)
	faces.draw.connect(func():
		for i in range(cells.size()):
			faces.draw_texture_rect(SlideArt.face_texture(theme_index, (i + 1) * 7 + 3), cells[i], false)
	)
	preview.resized.connect(func(): preview.queue_redraw())
	return preview

func themes_screen() -> void:
	header("Chọn giao diện", screen_parents.get("themes", "home"))
	column.add_theme_constant_override("separation", 12)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	column.add_child(grid)
	var card_width: float = (content_width() - 12) / 2.0
	var preview_width: float = card_width - 26
	for i in range(U.THEME_NAMES.size()):
		var chosen: bool = i == int(profile.settings.theme)
		var card := U.action("", func():
			profile.settings.theme = i
			profile.save()
			go("themes", false)
			var badge := page.find_child("SelectionBadge", true, false) as Control
			if badge:
				pop_in(badge, 0.0, 0.2)
		)
		card.name = "ThemeCard%d" % i
		card.set("show_surface", false)
		card.custom_minimum_size = Vector2(0, preview_width * 2.0 / 3.0 + 54)
		var skin := soft_card(Color("e9f3ff") if chosen else Color("fbf6ee"), 20)
		skin.set_content_margin_all(0)
		if chosen:
			skin.border_color = U.BLUE
			skin.set_border_width_all(3)
		for state in ["normal", "hover", "pressed"]:
			card.add_theme_stylebox_override(state, skin)
		grid.add_child(card)
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation", 7)
		overlay_fill(card, stack)
		stack.offset_top = 12
		stack.offset_bottom = -8
		var preview := material_preview(i, preview_width)
		stack.add_child(preview)
		var caption := U.text(U.THEME_NAMES[i], 15, U.INK, true)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fit(caption, card_width - 12, 11)
		stack.add_child(caption)
		if chosen:
			var badge := texture_view(SlideUI.icon("check", "ffffff"), 30)
			badge.name = "SelectionBadge"
			var circle := Panel.new()
			circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var dot := U.panel(U.BLUE, 16, false)
			dot.border_color = Color.WHITE
			dot.set_border_width_all(3)
			circle.add_theme_stylebox_override("panel", dot)
			circle.show_behind_parent = true
			circle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			circle.offset_left = -3
			circle.offset_top = -3
			circle.offset_right = 3
			circle.offset_bottom = 3
			badge.add_child(circle)
			card.add_child(badge)
			badge.size = Vector2(30, 30)
			var place := func(): badge.position = Vector2(card.size.x - 26, -6)
			card.resized.connect(place)
			place.call()

# ------------------------------------------------------------------ settings

func list_panel() -> VBoxContainer:
	var panel := PanelContainer.new()
	var skin := soft_card(Color("fffaf2"), 20)
	skin.content_margin_top = 4
	skin.content_margin_bottom = 4
	skin.content_margin_left = 14
	skin.content_margin_right = 14
	panel.add_theme_stylebox_override("panel", skin)
	column.add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	panel.add_child(rows)
	return rows

func section_title(value: String) -> void:
	var label := U.text(U.t(value).to_upper(), 13, Color("9a8a74"), true)
	var holder := MarginContainer.new()
	holder.add_theme_constant_override("margin_left", 6)
	holder.add_theme_constant_override("margin_top", 6)
	holder.add_child(label)
	column.add_child(holder)

func list_rule(rows: VBoxContainer) -> void:
	var rule := HSeparator.new()
	var rule_style := StyleBoxLine.new()
	rule_style.color = Color(0.65, 0.53, 0.38, 0.16)
	rule_style.thickness = 1
	rule_style.grow_begin = -50
	rule.add_theme_stylebox_override("separator", rule_style)
	rule.add_theme_constant_override("separation", 1)
	rows.add_child(rule)

func list_row(rows: VBoxContainer, glyph: Texture2D, tint: String, title: String, callback: Callable = Callable(), value: String = "", danger: bool = false) -> HBoxContainer:
	if rows.get_child_count() > 0:
		list_rule(rows)
	var holder: Control
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 13)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if callback.is_valid():
		var b := U.action("", callback)
		b.flat = true
		b.custom_minimum_size.y = 58
		rows.add_child(b)
		overlay_fill(b, line)
		holder = b
	else:
		var box := MarginContainer.new()
		box.custom_minimum_size.y = 58
		rows.add_child(box)
		box.add_child(line)
		holder = box
	line.add_child(U.badge_icon(glyph, Color(tint), 36, false, false))
	var label := U.text(title, 16, Color("c2412f") if danger else U.INK, danger)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	line.add_child(label)
	if not value.is_empty():
		var detail := U.text(value, 15, U.MUTED)
		detail.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fit(detail, content_width() * 0.34, 11)
		line.add_child(detail)
	if callback.is_valid():
		var chevron := icon_image("chevron", 15, "b6a790")
		chevron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(chevron)
	holder.set_meta("label", label)
	return line

func toggle_row(rows: VBoxContainer, key: String, title: String, glyph: Texture2D, tint: String) -> SlideSwitch:
	var line := list_row(rows, glyph, tint, title)
	var toggle := SlideSwitch.new()
	toggle.name = "Toggle_" + key
	toggle.button_pressed = bool(profile.settings[key])
	toggle.toggled.connect(func(value): profile.settings[key] = value; apply_preferences(); profile.save())
	line.add_child(toggle)
	return toggle

func volume_row(rows: VBoxContainer, key: String) -> void:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	line.custom_minimum_size.y = 34
	var indent := Control.new()
	indent.custom_minimum_size.x = 48
	line.add_child(indent)
	var slider := HSlider.new()
	slider.name = "Volume_" + key
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.01
	slider.value = float(profile.settings[key])
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size.y = 28
	var track := U.panel(Color("e4dacb"), 4, false)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	var filled := U.panel(Color("34c759"), 4, false)
	filled.content_margin_top = 4
	filled.content_margin_bottom = 4
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)
	var knob: Texture2D = scaled_icon(SlideArt.icon("knob"), 26)
	slider.add_theme_icon_override("grabber", knob)
	slider.add_theme_icon_override("grabber_highlight", knob)
	line.add_child(slider)
	var percent := U.text("%d%%" % int(float(profile.settings[key]) * 100), 14, U.MUTED, true)
	percent.custom_minimum_size.x = 42
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	percent.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(percent)
	slider.value_changed.connect(func(value):
		profile.settings[key] = value
		percent.text = "%d%%" % int(value * 100)
		apply_preferences()
		profile.save()
	)
	rows.add_child(line)
	var pad := Control.new()
	pad.custom_minimum_size.y = 6
	rows.add_child(pad)

func scaled_icon(texture: Texture2D, length: int) -> Texture2D:
	var image: Image = texture.get_image()
	if image.is_compressed():
		image.decompress()
	image.clear_mipmaps()
	image.resize(length, length, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)

func white(name: String) -> Texture2D:
	return U.icon(name, "ffffff")

func settings_screen() -> void:
	header("Cài đặt", screen_parents.get("settings", "home"))
	column.add_theme_constant_override("separation", 8)
	section_title("Âm thanh")
	var sound := list_panel()
	toggle_row(sound, "sound", "Hiệu ứng âm thanh", white("sound"), "ff9500")
	volume_row(sound, "sfx_volume")
	toggle_row(sound, "music", "Nhạc nền", white("music"), "ff4f86")
	volume_row(sound, "music_volume")
	toggle_row(sound, "haptic", "Rung khi di chuyển", white("vibrate"), "2fb5c9")
	section_title("Trò chơi")
	var game := list_panel()
	toggle_row(game, "numbers", "Hiện số khi xếp ảnh", white("grid"), "1677f2")
	list_row(game, white("palette"), "ff7a3d", "Giao diện", func(): go("themes"), U.t(U.THEME_NAMES[int(profile.settings.theme)]))
	list_row(game, white("help"), "34c759", "Hướng dẫn chơi", func(): go("help"))
	section_title("Khác")
	var more := list_panel()
	list_row(more, SlideArt.icon("globe_white"), "5b5bd6", "Ngôn ngữ", choose_language, SlideI18n.LANGUAGES[profile.settings.language])
	list_row(more, white("info"), "8e8a83", "Nguồn tài nguyên", show_credits)
	list_row(more, white("trash"), "ff3b30", "Xóa dữ liệu trò chơi", confirm_clear, "", true)
	gap(4)
	centered("Chơi ngoại tuyến. Tiến trình và ảnh riêng được lưu trên thiết bị.", 13, U.MUTED)
	centered(U.t("SLIDE PUZZLE · Phiên bản %s") % VERSION, 12, Color("b0a28c"), true)

func choose_language() -> void:
	var options: Array = []
	for code in SlideI18n.LANGUAGES:
		options.append([SlideI18n.LANGUAGES[code], func(): set_language(code)])
	show_overlay("Ngôn ngữ", "", options, "globe")

func set_language(code: String) -> void:
	profile.settings.language = code
	profile.save()
	apply_preferences()
	go("settings", false)

func show_credits() -> void:
	show_overlay("Nguồn tài nguyên", "Icon: Font Awesome Free 6.7.2 · Fonticons (CC BY 4.0)\nIcon màu: vẽ riêng cho dự án · Microsoft Fluent Emoji (MIT) · Google Noto Emoji (Apache 2.0)\nTiếng gỗ: Board Game Wood Piece Slide · Jeff Final Boss (CC0)\nÂm thanh nút: Kenney Interface Sounds (CC0)\nNhạc: Exploration Theme · Cleyton Kauffman (CC0)\nFont: Nunito (OFL)\n\nNguồn và giấy phép đầy đủ đi kèm dự án.", [["Đóng", func(): pass]])

func confirm_clear() -> void:
	show_overlay("Xóa toàn bộ dữ liệu?", "Xóa tiến trình, thống kê, cài đặt và ảnh đã nhập trên thiết bị. Không thể hoàn tác.", [["Xóa dữ liệu", clear_data], ["Giữ lại", func(): pass]], "trash")

func clear_data() -> void:
	var language: String = profile.settings.language
	for path in [SAVE_PATH, SlideProfile.PATH, "user://custom_picture.png", "user://session.json"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	profile = SlideProfile.new()
	profile.settings.language = language
	apply_preferences()
	active_session = false
	won_recorded = false
	initial_cells.clear()
	initial_solution.clear()
	puzzle.reset(4)
	elapsed = 0
	go("home")

# ------------------------------------------------------------------ stats, help, daily

func stats_screen() -> void:
	header("Thống kê")
	column.add_theme_constant_override("separation", 14)
	var tabs := hrow(null, 10)
	for photo in [false, true]:
		var tab := U.action("Xếp ảnh" if photo else "Xếp số", func(): stats_photo = photo; go("stats", false)) as SlideButton
		tab.name = "TabPictures" if photo else "TabNumbers"
		tab.blue = stats_photo == photo
		tab.custom_minimum_size.y = 50
		tab.corner_radius = 25.0
		tab.add_theme_color_override("font_color", Color.WHITE if tab.blue else U.INK)
		tab.add_theme_color_override("font_hover_color", Color.WHITE if tab.blue else U.INK)
		tab.add_theme_color_override("font_pressed_color", Color.WHITE if tab.blue else U.INK)
		tabs.add_child(tab)
	var data: Dictionary = profile.stats["pictures" if stats_photo else "numbers"]
	var cards := hrow(null, 8)
	var card_width: float = (content_width() - 16) / 3.0
	for item in [["trophy", str(data.wins), "Đã hoàn thành", "fff1dc", "f3d3a1"], ["chart", format_time(data.best_time) if int(data.best_time) > 0 else "—", "Nhanh nhất", "e6f1ff", "c3dcfb"], ["feet", str(data.best_moves) if int(data.best_moves) > 0 else "—", "Ít bước nhất", "e3f4ee", "bfe2d4"]]:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var skin := U.panel(Color(item[3]), 18)
		skin.set_content_margin_all(8)
		skin.content_margin_top = 12
		skin.content_margin_bottom = 12
		skin.border_color = Color(item[4])
		skin.set_border_width_all(1)
		skin.shadow_color = Color(0.36, 0.25, 0.12, 0.08)
		skin.shadow_size = 6
		panel.add_theme_stylebox_override("panel", skin)
		cards.add_child(panel)
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation", 2)
		panel.add_child(stack)
		var picture := art_image(item[0], 38)
		picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		stack.add_child(picture)
		var value := U.text(item[1], 27, U.INK, true)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stack.add_child(fit(value, card_width - 18, 16))
		var desc := U.text(item[2], 12, Color("5d5145"))
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stack.add_child(fit(desc, card_width - 18, 9))
		pop_in(panel, 0.1 + cards.get_child_count() * 0.07, 0.6)
	var unlocked: Array[bool] = profile.achievements(stats_photo)
	var title_row := hrow()
	var title := U.text("Thành tích", 20, U.INK, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)
	var tally := U.text(U.t("%d/4 đã mở") % unlocked.count(true), 14, U.MUTED, true)
	tally.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(tally)
	var rows := list_panel()
	var names := ["Người mới bắt đầu", "Nhanh như chớp", "Ít bước nhất", "Chuyên gia 4 × 4"]
	var descs := ["Hoàn thành 1 màn chơi", "Hoàn thành trong 1 phút", "Hoàn thành với ≤ 50 bước", "Hoàn thành 10 màn 4 × 4"]
	var glyphs := ["star_white", "bolt_white", "feet_white", "crown"]
	var tints := ["2fbf55", "2f8cff", "ff8a1f", "8f55e0"]
	for i in range(4):
		if i > 0:
			list_rule(rows)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 14)
		line.custom_minimum_size.y = 72
		rows.add_child(line)
		var square := U.badge_icon(SlideArt.icon(glyphs[i]), Color(tints[i]), 50, not unlocked[i])
		line.add_child(square)
		var words := VBoxContainer.new()
		words.alignment = BoxContainer.ALIGNMENT_CENTER
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.add_theme_constant_override("separation", 0)
		line.add_child(words)
		words.add_child(fit(U.text(names[i], 17, U.INK if unlocked[i] else Color("8a7d6b"), true), content_width() - 140, 13))
		words.add_child(fit(U.text(descs[i], 14, U.MUTED), content_width() - 140, 11))
		var state := art_image("check_circle", 26) if unlocked[i] else icon_image("lock", 20, "b3a690")
		state.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(state)

func help_screen() -> void:
	header("Hướng dẫn", screen_parents.get("help", "home"))
	column.add_child(U.text("Cách chơi", 22, U.INK, true))
	var steps := list_panel()
	var tips := ["Chạm hoặc vuốt ô nằm cạnh khoảng trống để di chuyển.", "Xếp các số tăng dần từ trái sang phải, từ trên xuống dưới; để trống ô cuối.", "Với xếp ảnh, ghép các mảnh thành ảnh gốc. Giữ nút Xem ảnh để xem mẫu."]
	for i in range(tips.size()):
		if i > 0:
			list_rule(steps)
		var box := MarginContainer.new()
		box.add_theme_constant_override("margin_top", 12)
		box.add_theme_constant_override("margin_bottom", 12)
		steps.add_child(box)
		var line := hrow(box, 14)
		var number := PanelContainer.new()
		var dot := U.panel(Color("f2b95c"), 17, false)
		dot.set_content_margin_all(0)
		number.add_theme_stylebox_override("panel", dot)
		number.custom_minimum_size = Vector2(34, 34)
		number.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var digit := U.text(str(i + 1), 17, Color.WHITE, true)
		digit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		digit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number.add_child(digit)
		line.add_child(number)
		var words := paragraph(tips[i], line, U.INK)
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(U.text("Một bước nữa là hoàn thành", 20, U.INK, true))
	var examples := hrow(null, 10)
	examples.alignment = BoxContainer.ALIGNMENT_CENTER
	var mini_size: float = clampf((content_width() - 50) / 2.0, 110, 150)
	var before = miniature(3, mini_size)
	before.hide_numbers = false
	before.puzzle.slide(7)
	examples.add_child(before)
	var arrow := icon_image("chevron", 22, "b98037")
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	examples.add_child(arrow)
	var after = miniature(3, mini_size)
	after.hide_numbers = false
	examples.add_child(after)
	paragraph("Gợi ý làm sáng một ô có thể đi theo đường giải. Mỗi ván có 3 lượt gợi ý. Hoàn tác không giới hạn; Làm lại đưa bạn về bàn ban đầu.")
	column.add_child(cta("Đã hiểu, chơi thôi!", "play", func(): go("game") if active_session and not puzzle.solved() else begin_flow(false), 56))

func daily_screen() -> void:
	header("Thử thách hằng ngày")
	column.add_theme_constant_override("separation", 12)
	var holder := Control.new()
	holder.custom_minimum_size.y = 92
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(holder)
	var calendar := art_image("calendar_star", 92)
	calendar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	calendar.offset_left = -46
	calendar.offset_right = 46
	calendar.offset_bottom = 92
	holder.add_child(calendar)
	pop_in(calendar, 0.0, 0.6)
	if profile.settings.animation:
		calendar.pivot_offset = Vector2(46, 80)
		var swing := calendar.create_tween().set_loops()
		swing.tween_property(calendar, "rotation", deg_to_rad(-5), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		swing.tween_property(calendar, "rotation", deg_to_rad(5), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fit(centered(U.t("Hôm nay, %s") % display_date(today()), 19, U.INK, true), content_width())
	centered("Một bức ảnh. Một thử thách mới mỗi ngày.", 14, U.MUTED)
	var unix_today: int = int(Time.get_unix_time_from_datetime_string(today() + "T12:00:00"))
	var days: Array = []
	for i in range(7):
		var date: String = Time.get_datetime_string_from_unix_time(unix_today - (6 - i) * 86400).substr(0, 10)
		days.append([date.right(2), profile.daily_wins.has(date), i == 6])
	var perfect: bool = days.all(func(d): return d[1])
	var track := Control.new()
	track.name = "DailyTrack"
	track.custom_minimum_size.y = 62
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(track)
	var check: Texture2D = SlideArt.icon("check_circle")
	var gift: Texture2D = SlideArt.icon("gift")
	var started: float = Time.get_ticks_msec() / 1000.0
	track.draw.connect(func():
		var count: int = days.size() + 1
		var node: float = minf(32.0, (track.size.x - 8) / count * 0.72)
		var spacing: float = (track.size.x - node) / (count - 1)
		var y: float = node * 0.5 + 2
		var now: float = Time.get_ticks_msec() / 1000.0 - started
		for i in range(count - 1):
			var a := Vector2(node * 0.5 + i * spacing, y)
			var done_pair: bool = days[i][1] and (i + 1 >= days.size() or days[i + 1][1])
			track.draw_line(a, a + Vector2(spacing, 0), Color("3fc565") if done_pair else Color("e2d8c8"), 5.0, true)
		for i in range(count):
			var center := Vector2(node * 0.5 + i * spacing, y)
			var appear: float = clampf((now - i * 0.06) / 0.3, 0.0, 1.0) if profile.settings.animation else 1.0
			var r: float = node * 0.5 * (1.0 - pow(1.0 - appear, 3.0))
			if i == count - 1:
				var size_g: float = r * 2.3
				track.draw_texture_rect(gift, Rect2(center - Vector2.ONE * size_g * 0.5, Vector2.ONE * size_g), false, Color(1, 1, 1, 1.0 if perfect else 0.45))
				continue
			var day: Array = days[i]
			if day[1]:
				track.draw_texture_rect(check, Rect2(center - Vector2.ONE * r, Vector2.ONE * r * 2), false)
			elif day[2]:
				var glow: float = 0.5 + 0.5 * sin(now * 3.0)
				track.draw_circle(center, r + 3 + glow * 2, Color(0.25, 0.77, 0.4, 0.15 + glow * 0.1))
				track.draw_circle(center, r, Color("d9f5e0"))
				track.draw_arc(center, r - 1.5, 0, TAU, 32, Color("3fc565"), 3.0, true)
			else:
				track.draw_circle(center, r, Color("efe7da"))
				track.draw_arc(center, r - 1, 0, TAU, 32, Color("ddd1bf"), 2.0, true)
			track.draw_string(default_font, Vector2(center.x - 20, y + node * 0.5 + 18), day[0], HORIZONTAL_ALIGNMENT_CENTER, 40, 12, Color("2f8a49") if day[2] else U.MUTED)
	)
	track.set_process(true)
	var redraw := func(): track.queue_redraw()
	get_tree().process_frame.connect(redraw)
	track.tree_exiting.connect(func(): get_tree().process_frame.disconnect(redraw))
	centered("Tuần hoàn hảo!" if perfect else "Hoàn thành 7 ngày liên tiếp để mở quà", 13, Color("c27812") if perfect else U.MUTED, true)
	var preview_center := CenterContainer.new()
	var preview = miniature(3, clampf(content_width() * 0.78, 220, 320), pictures[0])
	preview.frameless = true
	preview_center.add_child(preview)
	column.add_child(preview_center)
	var done: bool = profile.daily_wins.has(today())
	centered("Bạn đã chinh phục hôm nay!" if done else "Ghép khung cảnh núi hồ · 3 × 3", 16, Color("2f8a49") if done else U.INK, true)
	var start := cta("Chơi lại thử thách" if done else "Bắt đầu", "play", func(): request_start(3, true))
	start.name = "DailyStart"
	column.add_child(start)
	paragraph("Cùng một bàn xếp cho mỗi ngày. Những ngày hoàn thành sẽ được đánh dấu trên thiết bị.").horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

# ------------------------------------------------------------------ overlay

func show_overlay(title: String, message: String, actions: Array, glyph: String = "") -> void:
	close_overlay()
	if is_instance_valid(board):
		board.cancel_drag()
		board.preview = false
		board.locked = true
	overlay = Control.new()
	overlay.name = "Overlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.05, 0.03, 0.66)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = minf(size.x - 40, 350)
	var skin := soft_card(Color("fffaf2"), 28)
	skin.set_content_margin_all(22)
	skin.shadow_size = 24
	skin.shadow_color = Color(0, 0, 0, 0.3)
	panel.add_theme_stylebox_override("panel", skin)
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	if not glyph.is_empty():
		var glyph_texture: Texture2D = SlideArt.icon("globe_white") if glyph == "globe" else U.icon(glyph, "ffffff")
		var badge := U.badge_icon(glyph_texture, Color({"pause": "f2a33a", "restart": "2f8cff", "trash": "ff3b30", "globe": "5b5bd6"}.get(glyph, "f2a33a")), 56)
		badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		content.add_child(badge)
		pop_in(badge, 0.12, 0.3)
	var title_label := U.text(title, 25, U.INK, true)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(title_label)
	if not message.is_empty():
		var description := paragraph(message, content)
		description.custom_minimum_size.x = minf(size.x - 84, 306)
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in range(actions.size()):
		var action: Array = actions[i]
		var b := U.action(action[0], func(): close_overlay(); action[1].call(), i == 0)
		b.custom_minimum_size.y = 54
		content.add_child(b)
	if is_instance_valid(audio):
		audio.set_context(true)
	if profile.settings.animation:
		overlay.modulate.a = 0.0
		overlay.create_tween().tween_property(overlay, "modulate:a", 1.0, 0.18)
		panel.resized.connect(func(): panel.pivot_offset = panel.size * 0.5)
		panel.scale = Vector2.ONE * 0.86
		panel.create_tween().tween_property(panel, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close_overlay() -> void:
	if is_instance_valid(overlay):
		remove_child(overlay)
		overlay.queue_free()
	overlay = null
	if is_instance_valid(audio):
		audio.set_context(false)
	if is_instance_valid(board):
		board.locked = screen != "game" or puzzle.solved()

func animate_logo(delta: float) -> void:
	if not is_instance_valid(logo_node):
		return
	var lockup := logo_node.get_parent() as Control
	logo_clock += delta
	var t: float = clampf(logo_clock / 0.8, 0.0, 1.0)
	var k: float = t - 1.0
	var drop: float = 1.0 + 2.0 * k * k * k + 1.0 * k * k
	var drift: float = 0.0
	if logo_clock > 0.8:
		drift = (1.0 - cos((logo_clock - 0.8) * TAU / 3.6)) * 0.5 * -6.0
	logo_node.position = lockup.size * Vector2(0.5, 1.0) + Vector2(0, (1.0 - drop) * -40.0 + drift)
	logo_node.modulate.a = clampf(logo_clock / 0.35, 0.0, 1.0)
	var squash: float = sin(clampf((logo_clock - 0.5) / 0.4, 0.0, 1.0) * PI) * 0.045
	logo_node.scale = Vector2(1.0 + squash, 1.0 - squash)

func _process(delta: float) -> void:
	animate_logo(delta)
	if screen == "game" and not is_instance_valid(overlay) and puzzle.moves > 0 and not puzzle.solved() and is_instance_valid(board) and not board.preview and not file_dialog.visible and get_window().has_focus():
		elapsed += delta
	if is_instance_valid(time_label):
		time_label.text = format_time(elapsed)
	save_timer += delta
	if save_timer > 5:
		save_timer = 0
		save_session()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back_action()
		get_viewport().set_input_as_handled()

func back_action() -> void:
	if is_instance_valid(overlay):
		close_overlay()
	elif screen == "game":
		pause_game()
	elif screen in screen_parents:
		go(screen_parents[screen])
	elif screen == "levels":
		go("gallery" if pending_photo else "home")
	elif screen != "home":
		go("home")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(board):
			board.cancel_drag()
			board.preview = false
		if screen == "game" and not is_instance_valid(overlay) and not puzzle.solved():
			pause_game()
		save_session()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back_action()

# ------------------------------------------------------------------ persistence

func crop_texture(image: Image) -> Texture2D:
	var side: int = mini(image.get_width(), image.get_height())
	var cropped: Image = image.get_region(Rect2i((image.get_width() - side) / 2, (image.get_height() - side) / 2, side, side))
	cropped.resize(1024, 1024, Image.INTERPOLATE_CUBIC)
	cropped.generate_mipmaps()
	return ImageTexture.create_from_image(cropped)

func import_picture(path: String) -> void:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		show_overlay("Không mở được ảnh", "Hãy thử một ảnh PNG, JPG hoặc WebP khác.", [["Đóng", func(): pass]])
		return
	var square: Image = crop_texture(image).get_image()
	square.clear_mipmaps()
	square.save_png("user://custom_picture.png")
	pending_picture = -1
	pending_photo = true
	go("levels")

func save_session() -> void:
	if not active_session:
		return
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if not file:
		return
	file.store_string(JSON.stringify({"dimension": puzzle.dimension, "cells": puzzle.cells, "history": puzzle.history, "solution": puzzle.solution, "initial": initial_cells, "initial_solution": initial_solution, "moves": puzzle.moves, "elapsed": elapsed, "photo": photo_mode, "picture": picture_index, "won": won_recorded, "record": new_record, "daily": daily_date, "hints": hints_left, "redo": puzzle.redo_stack}))
	file.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH + ".tmp"), ProjectSettings.globalize_path(SAVE_PATH))

func load_session() -> void:
	var path: String = SAVE_PATH if FileAccess.file_exists(SAVE_PATH) else "user://session.json"
	if not FileAccess.file_exists(path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		return
	var n: int = int(data.get("dimension", 0))
	var cells: Array[int] = int_array(data.get("cells", []))
	if n < 3 or n > 5 or not valid_cells(cells, n):
		return
	puzzle.dimension = n
	puzzle.cells = cells
	puzzle.moves = maxi(0, int(data.get("moves", 0)))
	puzzle.history = int_array(data.get("history", []))
	puzzle.redo_stack = int_array(data.get("redo", []))
	var copy: Array[int] = cells.duplicate()
	for i in range(puzzle.history.size() - 1, -1, -1):
		var blank: int = copy.find(0)
		var previous: int = puzzle.history[i]
		if not puzzle.neighbors(blank).has(previous):
			puzzle.history.clear()
			break
		copy[blank] = copy[previous]
		copy[previous] = 0
	puzzle.solution = int_array(data.get("solution", []))
	initial_cells = int_array(data.get("initial", []))
	if not valid_cells(initial_cells, n):
		initial_cells = cells.duplicate()
	initial_solution = int_array(data.get("initial_solution", []))
	photo_mode = bool(data.get("photo", false))
	picture_index = clampi(int(data.get("picture", 0)), -1, pictures.size() - 1)
	elapsed = maxf(0, float(data.get("elapsed", 0)))
	won_recorded = bool(data.get("won", puzzle.solved()))
	new_record = bool(data.get("record", false))
	daily_date = str(data.get("daily", ""))
	hints_left = clampi(int(data.get("hints", 3)), 0, 3)
	active_session = true

func int_array(value) -> Array[int]:
	var result: Array[int] = []
	if value is Array:
		for entry in value:
			if not (entry is int or entry is float):
				return []
			result.append(int(entry))
	return result

func valid_cells(cells: Array[int], n: int) -> bool:
	if cells.size() != n * n:
		return false
	for value in range(n * n):
		if cells.count(value) != 1:
			return false
	return true

func today() -> String:
	return Time.get_date_string_from_system()

func display_date(date: String) -> String:
	var parts := date.split("-")
	return SlideI18n.date(int(parts[2]), int(parts[1]), int(parts[0]))

func format_time(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]

func build_sound() -> void:
	audio = SlideAudio.new()
	add_child(audio)
	U.click_feedback = audio.play_button
	apply_preferences()

func apply_preferences() -> void:
	# Motion is part of the design and is always on.
	profile.settings.animation = true
	U.animations_enabled = true
	if str(profile.settings.language) in SlideI18n.LANGUAGES:
		SlideI18n.language = profile.settings.language
	if is_instance_valid(audio):
		audio.configure(profile.settings)

# Staggered pop-in of each block on the page.
func entrance() -> void:
	if not is_instance_valid(column) or not profile.settings.animation:
		return
	var index: int = 0
	# Settings rows arrive together in one pass; other screens cascade.
	var stagger: float = 0.0 if screen == "settings" else 0.045
	for child in column.get_children():
		if not (child is Control) or (child.custom_minimum_size.y == 0 and not (child is Container) and not (child is Label)):
			continue
		if child.name in ["Logo", "VictoryHero", "Board", "HomeNav"]:
			continue
		child.modulate.a = 0.0
		var tween := child.create_tween()
		tween.tween_interval(minf(index * stagger, 0.32))
		tween.tween_callback(func():
			child.pivot_offset = child.size * 0.5
			child.scale = Vector2.ONE * 0.94
		)
		tween.tween_property(child, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(child, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		index += 1
