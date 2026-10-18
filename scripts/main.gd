extends Control

const BoardScript = preload("res://scripts/board.gd")
const BackdropScript = preload("res://scripts/backdrop.gd")
const SAVE_PATH = "user://session-v2.json"
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
var audio: SlideAudio
var default_font: Font
var bold_font: Font
var test_mode: bool = false
var screen_parents: Dictionary = {"settings": "home", "themes": "home", "help": "home"}

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
	file_dialog.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Ảnh"])
	file_dialog.file_selected.connect(import_picture)
	add_child(file_dialog)
	resized.connect(layout_ui)
	test_mode = OS.get_cmdline_user_args().has("--test-mode")
	go("home" if test_mode else "splash")

func go(destination: String) -> void:
	apply_preferences()
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
	page.add_child(scroll)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 28)
	scroll.add_child(margin)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
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
	layout_ui()
	if profile.settings.animation and screen != "splash":
		page.modulate.a = 0.0
		create_tween().tween_property(page, "modulate:a", 1.0, 0.24)
		entrance.call_deferred()

func layout_ui() -> void:
	if not is_instance_valid(page):
		return
	var margin: MarginContainer = page.get_node("Scroll/Margin")
	var side: int = int(maxf(18, (size.x - 450) / 2.0))
	margin.add_theme_constant_override("margin_left", side)
	margin.add_theme_constant_override("margin_right", side)
	if OS.has_feature("mobile"):
		var safe: Rect2i = DisplayServer.get_display_safe_area()
		var display_size: Vector2i = DisplayServer.screen_get_size()
		var safe_top: float = float(safe.position.y) / maxf(1, display_size.y) * size.y
		var safe_bottom: float = float(display_size.y - safe.end.y) / maxf(1, display_size.y) * size.y
		margin.add_theme_constant_override("margin_top", int(maxf(24, safe_top + 10)))
		margin.add_theme_constant_override("margin_bottom", int(maxf(28, safe_bottom + 12)))
	if is_instance_valid(board):
		board.custom_minimum_size.y = maxf(100, minf(size.x - side * 2 - 8, 450))

func gap(height: float = 10) -> void:
	var item := Control.new()
	item.custom_minimum_size.y = height
	column.add_child(item)

func centered(value: String, font_size: int, color: Color = U.INK, bold: bool = false) -> Label:
	var item := U.text(value, font_size, color, bold)
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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

func header(title: String, back: String = "home", dark: bool = false) -> void:
	var line := hrow()
	var previous := U.action("", func(): go(back), false, "back")
	previous.flat = true
	previous.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	previous.custom_minimum_size = Vector2(44, 44)
	previous.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	line.add_child(previous)
	var title_label := U.text(title, 22, Color.WHITE if dark else U.INK, true)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(title_label)
	var balance := Control.new()
	balance.custom_minimum_size.x = 44
	line.add_child(balance)
	gap(4)

func panel_box(parent: Node = null, color: Color = U.CREAM) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", U.panel(color))
	(parent if parent else column).add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	panel.add_child(content)
	return content

func icon_image(name: String, length: float, color: String = "493929") -> TextureRect:
	var image := TextureRect.new()
	image.texture = U.icon(name, color)
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

func game_action(value: String, glyph: String, callback: Callable) -> Button:
	var b := U.action("", callback) as SlideButton
	var length: float = floorf(clampf((size.x - 78.0) / 3.0, 86, 116))
	b.custom_minimum_size = Vector2(length, length * 0.90)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.corner_radius = 23.0
	var stack := VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 7)
	b.add_child(stack)
	stack.add_child(icon_image(glyph, 42 if glyph == "bulb" else 34, "9c6c2a" if glyph == "bulb" else "493929"))
	var caption := U.text(value, 16, U.INK, true)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.name = "Caption"
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
	if image:
		mini.prepare_photo()
	mini.set_process(false)
	return mini

func splash_screen() -> void:
	gap(90)
	var center := CenterContainer.new()
	center.add_child(miniature(4, 195))
	column.add_child(center)
	gap(0)
	logo()
	centered("Mỗi bước nhỏ, một niềm vui.", 17, Color.WHITE, true)
	gap(100)
	var progress := ProgressBar.new()
	progress.custom_minimum_size.y = 9
	progress.show_percentage = false
	var track := U.panel(Color(1, 1, 1, 0.28), 5, false)
	track.set_content_margin_all(0)
	var fill := U.panel(Color("ffde83"), 5, false)
	fill.set_content_margin_all(0)
	progress.add_theme_stylebox_override("background", track)
	progress.add_theme_stylebox_override("fill", fill)
	column.add_child(progress)
	centered("Đang chuẩn bị những mảnh ghép…", 13, Color.WHITE)
	create_tween().tween_property(progress, "value", 100.0, 1.4)
	get_tree().create_timer(1.65).timeout.connect(func():
		if screen == "splash":
			go("home")
	)

func logo() -> void:
	var lockup := Control.new()
	lockup.custom_minimum_size.y = 140 if size.x < 390 else 167
	column.add_child(lockup)
	var title := U.text("SLIDE", 68 if size.x < 390 else 78, Color("fffdf6"), true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = -15
	title.add_theme_color_override("font_shadow_color", Color("4c718c"))
	title.add_theme_constant_override("shadow_offset_y", 5)
	title.add_theme_constant_override("shadow_outline_size", 2)
	lockup.add_child(title)
	var plate := PanelContainer.new()
	var wood := U.panel(Color("d9974e"), 12)
	wood.border_color = Color("f8d294")
	wood.border_width_top = 3
	wood.border_width_left = 2
	wood.border_width_right = 2
	wood.shadow_color = Color("70411f")
	wood.shadow_offset = Vector2(0, 6)
	wood.shadow_size = 2
	wood.content_margin_top = 0
	wood.content_margin_bottom = 0
	wood.content_margin_left = 12
	wood.content_margin_right = 12
	plate.add_theme_stylebox_override("panel", wood)
	plate.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	plate.offset_top = 65 if size.x < 390 else 77
	plate.offset_left = -145 if size.x < 390 else -159
	plate.offset_right = 145 if size.x < 390 else 159
	lockup.add_child(plate)
	var word := U.text("PUZZLE", 54 if size.x < 390 else 62, Color("a45b27"), true)
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word.add_theme_color_override("font_shadow_color", Color("562c18"))
	word.add_theme_constant_override("shadow_offset_y", 4)
	word.add_theme_color_override("font_outline_color", Color("ffe0a3"))
	word.add_theme_constant_override("outline_size", 3)
	plate.add_child(word)

func home_screen() -> void:
	column.add_theme_constant_override("separation", 10)
	var top := hrow()
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var settings_button := U.round_action("settings", func(): go("settings"), 42)
	settings_button.custom_minimum_size = Vector2(42, 42)
	settings_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	top.add_child(settings_button)
	logo()
	centered("Xếp số · Xếp ảnh · Thư giãn mỗi ngày", 14, Color.WHITE, true)
	gap(clampf(size.y - 760 - (60 if active_session else 0), 8, 60))
	mode_card(false)
	mode_card(true)
	if active_session and not puzzle.solved():
		var resume_button := U.action("Tiếp tục ván đang chơi", func(): go("game"), true, "play")
		resume_button.name = "ResumeButton"
		resume_button.custom_minimum_size.y = 50
		column.add_child(resume_button)
	gap(2)
	var nav := hrow(null, 8)
	for item in [["trophy", "Thành tích", "stats"], ["calendar", "Thử thách\nhằng ngày", "daily"], ["palette", "Giao diện", "themes"], ["settings", "Cài đặt", "settings"]]:
		var b := U.action("", func(): go(item[2]))
		b.flat = true
		b.custom_minimum_size.y = 92
		nav.add_child(b)
		var v := VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 7)
		b.add_child(v)
		var well := PanelContainer.new()
		well.mouse_filter = Control.MOUSE_FILTER_IGNORE
		well.custom_minimum_size = Vector2(72, 62)
		well.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var skin := U.panel(Color("294047"), 15, false)
		skin.set_content_margin_all(10)
		skin.border_color = Color(0.8, 0.9, 0.9, 0.16)
		skin.set_border_width_all(1)
		well.add_theme_stylebox_override("panel", skin)
		well.add_child(icon_image(item[0], 38, "fff8eb" if item[0] == "settings" else "9b682b"))
		v.add_child(well)
		var caption := U.text(item[1], 13, Color.WHITE, true)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(caption)

func mode_card(photo: bool) -> void:
	var card := U.action("", func(): begin_flow(photo))
	card.name = "PictureModeCard" if photo else "NumberModeCard"
	card.custom_minimum_size.y = clampf(size.x * 0.36, 132, 156)
	column.add_child(card)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 18)
	margin.add_child(line)
	line.add_child(miniature(3, clampf(size.x * 0.28, 100, 120), pictures[1] if photo else null))
	var words := VBoxContainer.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(words)
	words.add_child(U.text("Xếp ảnh" if photo else "Xếp số", 26, U.INK, true))
	var description := paragraph("Khám phá những\nhình ảnh tuyệt đẹp" if photo else "Thử thách logic\nvới những con số", words)
	description.add_theme_font_size_override("font_size", 14 if size.x < 390 else 15)
	line.add_child(icon_image("chevron", 22))

func begin_flow(photo: bool) -> void:
	pending_photo = photo
	pending_picture = picture_index
	go("gallery" if photo else "levels")

func levels_screen() -> void:
	header("Xếp ảnh" if pending_photo else "Xếp số", "gallery" if pending_photo else "home")
	gap(6)
	for n in [3, 4, 5]:
		var card := U.action("", func(): request_start(n))
		card.custom_minimum_size.y = 180
		if n == puzzle.dimension:
			var selected := U.panel(Color("fff9ee"))
			selected.border_color = U.BLUE
			selected.set_border_width_all(2)
			card.add_theme_stylebox_override("normal", selected)
		column.add_child(card)
		var line := HBoxContainer.new()
		line.position = Vector2(16, 18)
		line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		line.offset_left = 16
		line.offset_right = -16
		line.offset_top = 18
		line.offset_bottom = -18
		line.add_theme_constant_override("separation", 23)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(line)
		line.add_child(miniature(n, 133, selected_picture() if pending_photo else null))
		var words := VBoxContainer.new()
		words.alignment = BoxContainer.ALIGNMENT_CENTER
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(words)
		words.add_child(U.text("%d × %d" % [n, n], 32, U.BLUE if n == puzzle.dimension else U.INK, true))
		words.add_child(U.text("%d ô số" % (n * n - 1), 15, U.MUTED))
		words.add_child(U.text(["Dễ", "Trung bình", "Khó"][n - 3], 12, Color("368756") if n == 3 else (Color("bb8126") if n == 4 else Color("c46052")), true))
		line.add_child(icon_image("chevron", 18))
	gap(0)
	paragraph("Chạm vào cấp độ để bắt đầu. Mỗi bàn đều có lời giải.")

func gallery_screen() -> void:
	header("Chọn chủ đề ảnh")
	column.add_theme_constant_override("separation", 12)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	column.add_child(grid)
	for i in range(pictures.size()):
		var card := U.action("", func(): pending_picture = i; go("levels"))
		card.name = "PhotoCard%d" % i
		card.flat = true
		card.custom_minimum_size = Vector2(0, 192)
		grid.add_child(card)
		var cover := TextureRect.new()
		cover.texture = pictures[i]
		cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var finish := ShaderMaterial.new()
		finish.shader = load("res://shaders/photo_card.gdshader")
		cover.material = finish
		cover.resized.connect(func(): finish.set_shader_parameter("rect_size", cover.size))
		card.add_child(cover)
		var margin := MarginContainer.new()
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(margin)
		var bottom := VBoxContainer.new()
		bottom.alignment = BoxContainer.ALIGNMENT_END
		bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(bottom)
		var line := HBoxContainer.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bottom.add_child(line)
		var words := VBoxContainer.new()
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.add_theme_constant_override("separation", 0)
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(words)
		words.add_child(U.text(PHOTO_NAMES[i], 18, Color.WHITE, true))
		words.add_child(U.text("1 ảnh", 13, Color("e0edec")))
		line.add_child(icon_image("chevron", 16, "ffffff"))
	column.add_child(U.action("Chọn ảnh từ thiết bị", func(): file_dialog.popup_centered_ratio(0.85), true, "image"))

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

func game_screen() -> void:
	var top := hrow()
	column.add_theme_constant_override("separation", 12)
	var pause := U.round_action("pause", pause_game, 48)
	pause.name = "PauseButton"
	pause.custom_minimum_size = Vector2(48, 48)
	pause.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	top.add_child(pause)
	var title := U.text("%d × %d" % [puzzle.dimension, puzzle.dimension], 28, Color.WHITE, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	var home := U.round_action("home", pause_game, 48)
	home.name = "HomeButton"
	home.custom_minimum_size = Vector2(48, 48)
	home.size_flags_horizontal = Control.SIZE_SHRINK_END
	top.add_child(home)
	var stats := hrow()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	for entry in [["clock", format_time(elapsed)], ["steps", str(puzzle.moves)]]:
		var badge := PanelContainer.new()
		var badge_style := U.panel(Color(0.05, 0.03, 0.02, 0.48), 20, false)
		badge_style.content_margin_top = 8
		badge_style.content_margin_bottom = 8
		badge_style.content_margin_left = 16
		badge_style.content_margin_right = 16
		badge.add_theme_stylebox_override("panel", badge_style)
		stats.add_child(badge)
		var line := HBoxContainer.new()
		line.add_child(icon_image(entry[0], 22, "fff8eb"))
		var value := U.text(entry[1], 20, Color.WHITE, true)
		line.add_child(value)
		badge.add_child(line)
		if entry[0] == "clock":
			time_label = value
		else:
			moves_label = value
	gap(maxf(8, size.y * 0.025))
	board = BoardScript.new()
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
	board.drag_sound_requested.connect(audio.play_drag)
	board.drag_cancelled.connect(audio.play_cancel)
	column.add_child(board)
	board.sync_positions()
	status_label = centered("Vuốt hoặc chạm ô cạnh khoảng trống", 14, Color("f0dfc5"))
	gap(clampf(size.y - size.x - 365, 8, 58))
	var actions := hrow(null, 16)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	var first := game_action("Xem ảnh" if photo_mode else "Trộn số", "eye" if photo_mode else "shuffle", func():
		if not photo_mode:
			show_overlay("Trộn lại bàn?", "Bạn sẽ bắt đầu một ván mới.", [["Trộn số", func(): pending_photo = false; new_game(puzzle.dimension)], ["Hủy", func(): pass]])
	)
	if photo_mode:
		first.button_down.connect(func(): board.cancel_drag(); board.preview = true)
		first.button_up.connect(func(): if is_instance_valid(board): board.preview = false)
	actions.add_child(first)
	hint_button = game_action("Gợi ý", "bulb", hint_move)
	hint_button.name = "Hint"
	var counter := PanelContainer.new()
	counter.name = "HintBadge"
	counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	counter.offset_left = -28
	counter.offset_top = -8
	counter.offset_right = 2
	counter.offset_bottom = 22
	var badge_skin := U.panel(Color("f29122"), 15)
	badge_skin.set_content_margin_all(3)
	badge_skin.border_color = Color("fff1cf")
	badge_skin.set_border_width_all(2)
	counter.add_theme_stylebox_override("panel", badge_skin)
	var count_text := U.text(str(hints_left), 16, Color.WHITE, true)
	count_text.name = "HintCount"
	count_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter.add_child(count_text)
	hint_button.add_child(counter)
	hint_button.disabled = hints_left <= 0 or puzzle.solution.is_empty()
	actions.add_child(hint_button)
	var restart := game_action("Làm lại", "restart", request_restart)
	actions.add_child(restart)
	var extras := hrow()
	var undo := U.action("Hoàn tác", undo_move, false, "undo")
	undo.custom_minimum_size.y = 44
	undo.icon = U.icon("undo", "493929")
	undo.add_theme_constant_override("icon_max_width", 18)
	undo.add_theme_font_size_override("font_size", 14)
	undo.add_theme_color_override("font_color", U.INK)
	undo.disabled = puzzle.history.is_empty()
	undo.name = "Undo"
	extras.add_child(undo)
	var theme_button := U.action("Giao diện", func(): go("themes"), false, "palette")
	theme_button.name = "ThemeButton"
	theme_button.custom_minimum_size.y = 44
	theme_button.add_theme_constant_override("icon_max_width", 18)
	theme_button.add_theme_font_size_override("font_size", 14)
	theme_button.add_theme_color_override("font_color", U.INK)
	extras.add_child(theme_button)
	if not daily_date.is_empty():
		centered("THỬ THÁCH NGÀY " + display_date(daily_date), 12, Color("ffe0a2"), true)

func pause_game() -> void:
	show_overlay("Tạm dừng", "Ván chơi đã được lưu. Bạn muốn làm gì?", [["Tiếp tục", func(): pass], ["Về màn hình chính", func(): save_session(); go("home")]])

func request_restart() -> void:
	show_overlay("Chơi lại từ đầu?", "Giữ nguyên bàn xếp; đặt lại bước đi và thời gian.", [["Làm lại", restart_game], ["Hủy", func(): pass]])

func restart_game() -> void:
	puzzle.cells = initial_cells.duplicate()
	puzzle.solution = initial_solution.duplicate()
	puzzle.history.clear()
	puzzle.moves = 0
	elapsed = 0
	hints_left = 3
	won_recorded = false
	save_session()
	go("game")

func hint_move() -> void:
	if hints_left <= 0 or puzzle.solution.is_empty() or not is_instance_valid(board):
		return
	var value: int = puzzle.solution[0]
	if not puzzle.can_move(puzzle.cells.find(value)):
		return
	hints_left -= 1
	board.hint_tile = value
	board.hint_until = board.clock + 3.0
	status_label.text = "Di chuyển ô đang sáng vào khoảng trống"
	var counter := hint_button.find_child("HintCount", true, false) as Label
	if counter:
		counter.text = str(hints_left)
	hint_button.disabled = hints_left <= 0
	save_session()

func undo_move() -> void:
	if puzzle.solved():
		return
	board.cancel_drag()
	if puzzle.undo():
		board.hint_tile = -1
		on_moved()

func on_moved() -> void:
	play_tick()
	if profile.settings.haptic and OS.has_feature("mobile"):
		Input.vibrate_handheld(12)
	if is_instance_valid(moves_label):
		moves_label.text = str(puzzle.moves)
		if profile.settings.animation:
			moves_label.pivot_offset = moves_label.size * 0.5
			var bump := moves_label.create_tween()
			bump.tween_property(moves_label, "scale", Vector2.ONE * 1.13, 0.08)
			bump.tween_property(moves_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE)
	if is_instance_valid(board):
		board.hint_tile = -1
	if is_instance_valid(status_label):
		status_label.text = "Vuốt hoặc chạm ô cạnh khoảng trống"
	if is_instance_valid(page):
		var undo := page.find_child("Undo", true, false) as Button
		if undo:
			undo.disabled = puzzle.history.is_empty() or puzzle.solved()
	save_session()

func on_completed() -> void:
	if won_recorded or not puzzle.solved():
		return
	won_recorded = true
	audio.play_win()
	new_record = profile.record_win(photo_mode, elapsed, puzzle.moves, puzzle.dimension, daily_date)
	board.locked = true
	status_label.text = "Tuyệt vời! Bạn đã hoàn thành."
	save_session()
	get_tree().create_timer(0.85 if profile.settings.animation else 0.1).timeout.connect(func():
		if screen == "game" and puzzle.solved():
			go("result")
	)

func result_screen() -> void:
	column.add_theme_constant_override("separation", 10)
	gap(clampf(size.y * 0.055, 18, 50))
	var hero := Control.new()
	hero.name = "VictoryHero"
	hero.custom_minimum_size.y = clampf(size.y * 0.37, 280, 330)
	column.add_child(hero)
	var reward := image_view(current_picture() if photo_mode else load("res://assets/trophy-soft.png"), 0)
	reward.name = "VictoryReward"
	reward.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reward.offset_left = 32
	reward.offset_right = -32
	reward.offset_bottom = -40
	hero.add_child(reward)
	if photo_mode:
		var frame := PanelContainer.new()
		frame.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		frame.offset_left = -125
		frame.offset_right = 125
		frame.offset_top = 10
		frame.offset_bottom = 260
		var frame_skin := U.panel(Color("f7d6a4"), 18)
		frame_skin.set_content_margin_all(4)
		frame.add_theme_stylebox_override("panel", frame_skin)
		hero.add_child(frame)
		hero.remove_child(reward)
		frame.add_child(reward)
		reward.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var material := ShaderMaterial.new()
		material.shader = load("res://shaders/photo_card.gdshader")
		material.set_shader_parameter("shade_strength", 0.0)
		material.set_shader_parameter("radius", 14.0)
		reward.material = material
		reward.resized.connect(func(): material.set_shader_parameter("rect_size", reward.size))
	var ribbon := PanelContainer.new()
	var no_panel := U.panel(Color.TRANSPARENT, 0, false)
	no_panel.set_content_margin_all(0)
	ribbon.add_theme_stylebox_override("panel", no_panel)
	ribbon.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	ribbon.offset_top = -92
	ribbon.offset_bottom = 0
	hero.add_child(ribbon)
	var ribbon_art := image_view(load("res://assets/ui/victory-ribbon.svg"), 92)
	ribbon_art.stretch_mode = TextureRect.STRETCH_SCALE
	ribbon.add_child(ribbon_art)
	var congrats := U.text("Hoàn thành!", 38, Color.WHITE, true)
	congrats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	congrats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	congrats.add_theme_color_override("font_shadow_color", Color("a8241b"))
	congrats.add_theme_constant_override("shadow_offset_y", 2)
	ribbon.add_child(congrats)
	if profile.settings.animation:
		hero.resized.connect(func(): hero.pivot_offset = hero.size * 0.5)
		hero.scale = Vector2.ONE * 0.82
		var appear := hero.create_tween()
		appear.tween_property(hero, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var results := panel_box()
	results.add_theme_constant_override("separation", 13)
	var entries := [["clock", "Thời gian", format_time(elapsed)], ["steps", "Số bước", str(puzzle.moves)], ["grid", "Kích thước", "%d × %d" % [puzzle.dimension, puzzle.dimension]], ["star", "Kỷ lục mới", "NEW" if new_record else "—"]]
	for i in range(entries.size()):
		var item: Array = entries[i]
		var line := hrow(results)
		line.add_child(icon_image(item[0], 23, "35291f"))
		var caption := U.text(item[1], 17)
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(caption)
		if i == 3 and new_record:
			var pill := PanelContainer.new()
			var red := U.panel(Color("f05a3c"), 9, false)
			red.content_margin_left = 8
			red.content_margin_right = 8
			red.content_margin_top = 1
			red.content_margin_bottom = 1
			pill.add_theme_stylebox_override("panel", red)
			pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			pill.add_child(U.text("NEW", 12, Color.WHITE, true))
			line.add_child(pill)
		else:
			line.add_child(U.text(item[2], 17, U.INK, true))
		if i < entries.size() - 1:
			var separator := HSeparator.new()
			var rule := StyleBoxFlat.new()
			rule.bg_color = Color(0.63, 0.51, 0.34, 0.10)
			rule.content_margin_top = 1
			separator.add_theme_stylebox_override("separator", rule)
			results.add_child(separator)
	gap(5)
	var navigation := hrow()
	var home := U.action("", func(): go("home")) as SlideButton
	home.dark = true
	home.custom_minimum_size = Vector2(132, 68)
	home.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	navigation.add_child(home)
	var home_content := HBoxContainer.new()
	home_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home_content.alignment = BoxContainer.ALIGNMENT_CENTER
	home_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home_content.add_theme_constant_override("separation", 10)
	home.add_child(home_content)
	home_content.add_child(icon_image("home", 27, "fff8eb"))
	var home_label := U.text("Trang chủ", 16, Color("fff8eb"), true)
	home_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	home_content.add_child(home_label)
	var next := U.action("Chơi tiếp", func(): pending_photo = photo_mode; pending_picture = picture_index; new_game(puzzle.dimension), true, "play")
	next.custom_minimum_size.y = 68
	navigation.add_child(next)

func themes_screen() -> void:
	header("Chọn giao diện", screen_parents.get("themes", "home"))
	column.add_theme_constant_override("separation", 12)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	column.add_child(grid)
	for i in range(U.THEME_NAMES.size()):
		var card := U.action("", func(): profile.settings.theme = i; profile.save(); go("themes"))
		card.name = "ThemeCard%d" % i
		card.set("show_surface", false)
		card.custom_minimum_size = Vector2(0, 182)
		var skin := U.panel(Color("f4eee4"), 17, false)
		skin.set_content_margin_all(0)
		card.add_theme_stylebox_override("normal", skin)
		grid.add_child(card)
		var stack := VBoxContainer.new()
		stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stack.offset_left = 8
		stack.offset_right = -8
		stack.offset_top = 7
		stack.offset_bottom = -5
		stack.add_theme_constant_override("separation", 6)
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(stack)
		var center := CenterContainer.new()
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(center)
		var frame := PanelContainer.new()
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var outline := U.panel(Color.TRANSPARENT, 14, false)
		outline.set_content_margin_all(4)
		if i == int(profile.settings.theme):
			outline.border_color = U.BLUE
			outline.set_border_width_all(2)
		frame.add_theme_stylebox_override("panel", outline)
		frame.add_child(miniature(3, 134, null, i))
		center.add_child(frame)
		if i == int(profile.settings.theme):
			var badge := PanelContainer.new()
			badge.name = "SelectionBadge"
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			badge.custom_minimum_size = Vector2(29, 29)
			var blue := U.panel(U.BLUE, 15, false)
			blue.set_content_margin_all(6)
			badge.add_theme_stylebox_override("panel", blue)
			badge.add_child(icon_image("check", 16, "ffffff"))
			card.add_child(badge)
			card.resized.connect(func(): badge.position = Vector2(card.size.x * 0.5 + 54, 0))
			badge.position = Vector2(card.size.x * 0.5 + 54, 0)
		var caption := U.text(U.THEME_NAMES[i], 15, U.INK, true)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stack.add_child(caption)

func settings_screen() -> void:
	header("Cài đặt", screen_parents.get("settings", "home"))
	var settings_box := panel_box()
	settings_box.add_theme_constant_override("separation", 4)
	for item in [["sound", "Hiệu ứng âm thanh", "sound"], ["music", "Nhạc nền", "music"], ["haptic", "Rung khi di chuyển", "vibrate"], ["animation", "Hiệu ứng động", "star"], ["numbers", "Hiện số khi xếp ảnh", "grid"]]:
		var line := hrow(settings_box)
		line.add_child(icon_image(item[2], 25))
		var title := U.text(item[1], 16)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.custom_minimum_size.x = 120
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(title)
		var toggle := CheckButton.new()
		toggle.add_theme_icon_override("checked", U.icon("toggle_on"))
		toggle.add_theme_icon_override("unchecked", U.icon("toggle_off"))
		toggle.button_pressed = bool(profile.settings[item[0]])
		toggle.custom_minimum_size = Vector2(52, 44)
		toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		toggle.toggled.connect(func(value): profile.settings[item[0]] = value; apply_preferences(); profile.save())
		line.add_child(toggle)
		var rule := HSeparator.new()
		var rule_style := StyleBoxLine.new()
		rule_style.color = Color(0.65, 0.53, 0.38, 0.14)
		rule_style.thickness = 1
		rule.add_theme_stylebox_override("separator", rule_style)
		settings_box.add_child(rule)
	var volume_box := panel_box()
	for item in [["sfx_volume", "Âm lượng hiệu ứng"], ["music_volume", "Âm lượng nhạc"]]:
		var label_row := hrow(volume_box)
		var title := U.text(item[1], 16)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label_row.add_child(title)
		var percent := U.text("%d%%" % int(float(profile.settings[item[0]]) * 100), 16, U.MUTED, true)
		label_row.add_child(percent)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = 0.01
		slider.value = float(profile.settings[item[0]])
		slider.custom_minimum_size.y = 32
		var track := U.panel(Color("ded3c1"), 4, false)
		track.set_content_margin_all(3)
		var filled := U.panel(Color("3bc84b"), 4, false)
		filled.set_content_margin_all(3)
		slider.add_theme_stylebox_override("slider", track)
		slider.add_theme_stylebox_override("grabber_area", filled)
		slider.add_theme_stylebox_override("grabber_area_highlight", filled)
		slider.value_changed.connect(func(value):
			profile.settings[item[0]] = value
			percent.text = "%d%%" % int(value * 100)
			apply_preferences()
			profile.save()
		)
		volume_box.add_child(slider)
	column.add_child(U.action("Giao diện · " + U.THEME_NAMES[int(profile.settings.theme)], func(): go("themes"), false, "palette"))
	column.add_child(U.action("Hướng dẫn chơi", func(): go("help"), false, "help"))
	column.add_child(U.action("Nguồn tài nguyên", show_credits, false, "info"))
	var language := panel_box()
	language.add_child(U.text("Ngôn ngữ: Tiếng Việt", 17, U.INK, true))
	paragraph("Chơi ngoại tuyến. Tiến trình và ảnh riêng được lưu trên thiết bị.", language)
	gap(10)
	var reset := U.action("Xóa dữ liệu trò chơi", confirm_clear, false, "trash")
	reset.add_theme_color_override("font_color", Color("b94d3a"))
	column.add_child(reset)
	centered("SLIDE PUZZLE · Phiên bản 0.6", 12, U.MUTED)

func show_credits() -> void:
	show_overlay("Nguồn tài nguyên", "Icon: Font Awesome Free 6.7.2 · Fonticons (CC BY 4.0)\nIcon màu: Microsoft Fluent Emoji (MIT) · Google Noto Emoji (Apache 2.0 cho hình ảnh)\nTiếng gỗ: Board Game Wood Piece Slide · Jeff Final Boss (CC0)\nÂm thanh nút: Kenney Interface Sounds (CC0)\nNhạc: Exploration Theme · Cleyton Kauffman (CC0)\nFont: Nunito (OFL)\n\nNguồn và giấy phép đầy đủ đi kèm dự án.", [["Đóng", func(): pass]])

func confirm_clear() -> void:
	show_overlay("Xóa toàn bộ dữ liệu?", "Xóa tiến trình, thống kê, cài đặt và ảnh đã nhập trên thiết bị. Không thể hoàn tác.", [["Xóa dữ liệu", clear_data], ["Giữ lại", func(): pass]])

func clear_data() -> void:
	for path in [SAVE_PATH, SlideProfile.PATH, "user://custom_picture.png", "user://session.json"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	profile = SlideProfile.new()
	apply_preferences()
	active_session = false
	won_recorded = false
	initial_cells.clear()
	initial_solution.clear()
	puzzle.reset(4)
	elapsed = 0
	go("home")

func stats_screen() -> void:
	header("Thống kê")
	var tabs := hrow()
	tabs.add_child(U.action("Xếp số", func(): stats_photo = false; go("stats"), not stats_photo))
	tabs.add_child(U.action("Xếp ảnh", func(): stats_photo = true; go("stats"), stats_photo))
	var data: Dictionary = profile.stats["pictures" if stats_photo else "numbers"]
	var cards := hrow(null, 8)
	for item in [["trophy", str(data.wins), "Đã hoàn thành", "fff0d6", "d68f1e"], ["stats", format_time(data.best_time) if int(data.best_time) > 0 else "—", "Nhanh nhất", "e1f0ff", "168cff"], ["steps", str(data.best_moves) if int(data.best_moves) > 0 else "—", "Ít bước nhất", "e0f2ed", "237b68"]]:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var skin := U.panel(Color(item[3]), 18)
		skin.set_content_margin_all(9)
		panel.add_theme_stylebox_override("panel", skin)
		cards.add_child(panel)
		var stack := VBoxContainer.new()
		panel.add_child(stack)
		stack.add_child(icon_image(item[0], 36, item[4]))
		var value := U.text(item[1], 27, U.INK, true)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stack.add_child(value)
		var desc := U.text(item[2], 11)
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stack.add_child(desc)
	gap(10)
	column.add_child(U.text("Thành tích", 23, U.INK, true))
	var unlocked: Array[bool] = profile.achievements(stats_photo)
	var names := ["Người mới bắt đầu", "Nhanh như chớp", "Ít bước nhất", "Chuyên gia 4 × 4"]
	var descs := ["Hoàn thành 1 màn chơi", "Hoàn thành trong 1 phút", "Hoàn thành với tối đa 50 bước", "Hoàn thành 10 màn 4 × 4"]
	for i in range(4):
		var box := panel_box(null, Color("fff9ed") if unlocked[i] else Color("ede7dc"))
		var line := hrow(box)
		line.add_child(icon_image(["star", "bolt", "steps", "trophy"][i], 38, ["3ea657", "168cff", "e99c30", "9260d5"][i]))
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(words)
		words.add_child(U.text(names[i], 18, U.INK, true))
		paragraph(descs[i], words)
		line.add_child(icon_image("check" if unlocked[i] else "lock", 22, "36a454" if unlocked[i] else "a39580"))
	paragraph("Thành tích được cập nhật sau mỗi ván hoàn thành.")

func help_screen() -> void:
	header("Hướng dẫn", screen_parents.get("help", "home"))
	column.add_child(U.text("Cách chơi", 25, U.INK, true))
	for item in [["1", "Chạm hoặc vuốt ô nằm cạnh khoảng trống để di chuyển."], ["2", "Xếp các số tăng dần từ trái sang phải, từ trên xuống dưới; để trống ô cuối."], ["3", "Với xếp ảnh, ghép các mảnh thành ảnh gốc. Giữ nút Xem ảnh để xem mẫu."]]:
		var box := panel_box()
		var line := hrow(box)
		line.add_child(U.text(item[0], 30, Color("b98037"), true))
		var words := paragraph(item[1], line, U.INK)
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(U.text("Một bước nữa là hoàn thành", 22, U.INK, true))
	var examples := hrow()
	examples.alignment = BoxContainer.ALIGNMENT_CENTER
	var before = miniature(3, 130)
	before.puzzle.slide(7)
	examples.add_child(before)
	examples.add_child(icon_image("chevron", 24))
	examples.add_child(miniature(3, 130))
	paragraph("Gợi ý làm sáng một ô có thể đi theo đường giải. Mỗi ván có 3 lượt gợi ý. Hoàn tác không giới hạn; Làm lại đưa bạn về bàn ban đầu.")
	column.add_child(U.action("Đã hiểu, chơi thôi!", func(): go("game") if active_session and not puzzle.solved() else begin_flow(false), true, "play"))

func daily_screen() -> void:
	header("Thử thách hằng ngày")
	var center := CenterContainer.new()
	center.add_child(icon_image("calendar", 86, "d79427"))
	column.add_child(center)
	centered("Hôm nay, " + display_date(today()), 19, U.INK, true)
	centered("Một bức ảnh. Một thử thách mới mỗi ngày.", 14, U.MUTED)
	var line := hrow()
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	var unix_today: int = int(Time.get_unix_time_from_datetime_string(today() + "T12:00:00"))
	for i in range(7):
		var date: String = Time.get_datetime_string_from_unix_time(unix_today - (6 - i) * 86400).substr(0, 10)
		var day := VBoxContainer.new()
		line.add_child(day)
		day.add_child(icon_image("check" if profile.daily_wins.has(date) else "calendar", 30, "29a94f" if profile.daily_wins.has(date) else "c4b397"))
		var number := U.text(date.right(2), 12, U.MUTED)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day.add_child(number)
	gap(5)
	var preview_center := CenterContainer.new()
	preview_center.add_child(miniature(3, 250, pictures[0]))
	column.add_child(preview_center)
	var done: bool = profile.daily_wins.has(today())
	centered("Bạn đã chinh phục hôm nay!" if done else "Ghép khung cảnh núi hồ · 3 × 3", 16, Color("328c48") if done else U.INK, true)
	column.add_child(U.action("Chơi lại thử thách" if done else "Bắt đầu", func(): request_start(3, true), true, "play"))
	paragraph("Cùng một bàn xếp cho mỗi ngày. Những ngày hoàn thành sẽ được đánh dấu trên thiết bị.")

func show_overlay(title: String, message: String, actions: Array) -> void:
	close_overlay()
	if is_instance_valid(board):
		board.cancel_drag()
		board.preview = false
		board.locked = true
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.05, 0.03, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = minf(size.x - 42, 350)
	panel.add_theme_stylebox_override("panel", U.panel(U.CREAM, 28))
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 15)
	panel.add_child(content)
	var title_label := U.text(title, 25, U.INK, true)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title_label)
	var description := paragraph(message, content)
	description.custom_minimum_size.x = minf(size.x - 85, 310)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in range(actions.size()):
		var action: Array = actions[i]
		content.add_child(U.action(action[0], func(): close_overlay(); action[1].call(), i == 0))
	if is_instance_valid(audio):
		audio.set_context(true)
	if profile.settings.animation:
		overlay.modulate.a = 0.0
		overlay.create_tween().tween_property(overlay, "modulate:a", 1.0, 0.18)
		panel.resized.connect(func(): panel.pivot_offset = panel.size * 0.5)
		panel.scale = Vector2.ONE * 0.92
		panel.create_tween().tween_property(panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close_overlay() -> void:
	if is_instance_valid(overlay):
		remove_child(overlay)
		overlay.queue_free()
	overlay = null
	if is_instance_valid(audio):
		audio.set_context(false)
	if is_instance_valid(board):
		board.locked = screen != "game" or puzzle.solved()

func _process(delta: float) -> void:
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
	crop_texture(image).get_image().save_png("user://custom_picture.png")
	pending_picture = -1
	pending_photo = true
	go("levels")

func save_session() -> void:
	if not active_session:
		return
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if not file:
		return
	file.store_string(JSON.stringify({"dimension": puzzle.dimension, "cells": puzzle.cells, "history": puzzle.history, "solution": puzzle.solution, "initial": initial_cells, "initial_solution": initial_solution, "moves": puzzle.moves, "elapsed": elapsed, "photo": photo_mode, "picture": picture_index, "won": won_recorded, "record": new_record, "daily": daily_date, "hints": hints_left}))
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
	return "%d tháng %d, %d" % [int(parts[2]), int(parts[1]), int(parts[0])]

func format_time(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]

func build_sound() -> void:
	audio = SlideAudio.new()
	add_child(audio)
	U.click_feedback = audio.play_button
	apply_preferences()

func apply_preferences() -> void:
	U.animations_enabled = bool(profile.settings.animation)
	if is_instance_valid(audio):
		audio.configure(profile.settings)

func play_tick() -> void:
	if is_instance_valid(audio):
		audio.play_drop()


func entrance() -> void:
	if not is_instance_valid(column) or not profile.settings.animation:
		return
	var index: int = 0
	for child in column.get_children():
		if child is Control and child.custom_minimum_size.y != 0 or child is Container:
			child.modulate.a = 0.0
			var tween := child.create_tween()
			tween.tween_interval(minf(index * 0.035, 0.18))
			tween.tween_property(child, "modulate:a", 1.0, 0.24).set_trans(Tween.TRANS_SINE)
			index += 1
