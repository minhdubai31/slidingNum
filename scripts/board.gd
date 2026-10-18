extends Control

signal moved
signal completed
signal drag_sound_requested
signal drag_cancelled

var puzzle: SlidePuzzle
var picture: Texture2D
var photo_mode: bool = false
var show_numbers: bool = true
var preview: bool = false
var locked: bool = false
var theme_id: int = 0
var reduced_motion: bool = false
var hide_numbers: bool = false
var hint_tile: int = -1
var hint_until: float = 0.0
var photo_atlas: Texture2D
var atlas_source: int = 0
var atlas_dimension: int = 0
var positions: Dictionary = {}
var drag_id: int = -1
var drag_index: int = -1
var drag_pointer: int = -2
var drag_start: Vector2
var drag_axis: Vector2
var drag_distance: float = 0.0
var drag_time: float = 0.0
var drag_sound_distance: float = 0.0
var drag_sound_played: bool = false
var last_motion_time: float = 0.0
var last_motion_distance: float = 0.0
var release_speed: float = 0.0
var clock: float = 0.0
var celebration: float = -1.0
var particles: Array[Dictionary] = []
var landing: Dictionary = {}
var font: Font = ThemeDB.fallback_font
const INK = Color("243b43")
const ORANGE = Color("ed784e")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	resized.connect(func(): sync_positions())

func tile_step() -> float:
	return (size.x - 24.0 * unit()) / puzzle.dimension

func unit() -> float:
	return size.x / 390.0

func tile_gap() -> float:
	return (2.4 if photo_mode else 7.0) * unit()

func target(index: int) -> Vector2:
	return Vector2(12, 12) * unit() + Vector2(index % puzzle.dimension, index / puzzle.dimension) * tile_step()

func sync_positions() -> void:
	cancel_drag()
	positions.clear()
	if puzzle == null:
		return
	for i in range(puzzle.cells.size()):
		positions[puzzle.cells[i]] = target(i)
	queue_redraw()

func cancel_drag() -> void:
	drag_id = -1
	drag_index = -1
	drag_pointer = -2

func _process(delta: float) -> void:
	clock += delta
	for id in landing.keys():
		landing[id] -= delta
		if landing[id] <= 0.0:
			landing.erase(id)
	if puzzle == null:
		return
	if photo_mode and picture and (atlas_source != picture.get_instance_id() or atlas_dimension != puzzle.dimension):
		prepare_photo()
	for i in range(puzzle.cells.size()):
		var id: int = puzzle.cells[i]
		if id == drag_id:
			continue
		positions[id] = target(i) if reduced_motion else Vector2(positions.get(id, target(i))).lerp(target(i), 1.0 - exp(-24.0 * delta))
	if celebration >= 0.0:
		celebration += delta
	for p in particles:
		p["position"] += p["velocity"] * delta
		p["velocity"].y += 380.0 * delta
		p["life"] -= delta
	particles = particles.filter(func(p): return p["life"] > 0)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if puzzle == null or locked or preview:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			press(event.position - global_position, event.index)
		elif event.index == drag_pointer:
			release_drag(event.position - global_position)
	elif event is InputEventScreenDrag and event.index == drag_pointer:
		motion(event.position - global_position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			press(event.position - global_position, -1)
		elif drag_pointer == -1:
			release_drag(event.position - global_position)
	elif event is InputEventMouseMotion and drag_pointer == -1:
		motion(event.position - global_position)
		get_viewport().set_input_as_handled()

func press(point: Vector2, pointer: int) -> void:
	if locked or preview or size.x < 24 or drag_id != -1 or not Rect2(Vector2(12, 12) * unit(), size - Vector2(24, 24) * unit()).has_point(point) or puzzle.solved():
		return
	var grid: Vector2i = Vector2i((point - Vector2(12, 12) * unit()) / tile_step())
	var index: int = grid.y * puzzle.dimension + grid.x
	if not puzzle.can_move(index):
		return
	# A rapidly tapped moving tile can be grabbed at its current visual position.
	drag_id = puzzle.cells[index]
	drag_index = index
	drag_pointer = pointer
	drag_start = point
	drag_axis = (target(puzzle.cells.find(0)) - target(index)).normalized()
	drag_distance = 0.0
	drag_sound_distance = 0.0
	drag_sound_played = false
	drag_time = clock
	last_motion_time = clock
	last_motion_distance = 0.0
	release_speed = 0.0
	get_viewport().set_input_as_handled()

func motion(point: Vector2) -> void:
	drag_distance = clampf((point - drag_start).dot(drag_axis), 0.0, tile_step())
	var elapsed: float = clock - last_motion_time
	if elapsed > 0.001:
		release_speed = (drag_distance - last_motion_distance) / elapsed
	last_motion_time = clock
	last_motion_distance = drag_distance
	positions[drag_id] = target(drag_index) + drag_axis * drag_distance
	if not drag_sound_played and drag_distance > tile_step() * 0.06:
		drag_sound_played = true
		drag_sound_requested.emit()

func release_drag(point: Vector2) -> void:
	var is_tap: bool = point.distance_to(drag_start) < 10.0 and clock - drag_time < 0.45
	var flick: bool = release_speed > 650.0 and clock - last_motion_time < 0.1 and drag_distance > 8.0
	if is_tap or drag_distance > tile_step() * 0.24 or flick:
		if not reduced_motion:
			landing[drag_id] = 0.32
		puzzle.slide(drag_index)
		moved.emit()
		if puzzle.solved():
			celebrate()
			completed.emit()
	elif drag_distance > 4:
		drag_cancelled.emit()
	cancel_drag()

func celebrate() -> void:
	celebration = 0.0
	if reduced_motion:
		return
	for i in range(65):
		particles.append({"position": size * 0.5, "velocity": Vector2(randf_range(-210, 210), randf_range(-340, -70)), "life": randf_range(0.8, 1.8), "color": [ORANGE, Color("e6bc67"), Color("649b86")].pick_random()})

func box(rect: Rect2, color: Color, radius: int = 14, shadow: bool = false) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	if shadow:
		style.shadow_color = Color(0.12, 0.22, 0.24, 0.10)
		style.shadow_size = 5
		style.shadow_offset = Vector2(0, 4)
	draw_style_box(style, rect)

func prepare_photo() -> void:
	var image: Image = picture.get_image()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var n: int = puzzle.dimension
	var radius: int = maxi(2, int(float(image.get_width()) / n * 0.063))
	for row in range(n):
		for col in range(n):
			var left: int = int(float(col) * image.get_width() / n)
			var right: int = int(float(col + 1) * image.get_width() / n) - 1
			var top: int = int(float(row) * image.get_height() / n)
			var bottom: int = int(float(row + 1) * image.get_height() / n) - 1
			for y in range(radius):
				for x in range(radius):
					var distance: float = Vector2(x + 0.5 - radius, y + 0.5 - radius).length()
					var alpha: float = clampf(radius - distance + 0.5, 0, 1)
					if alpha < 1:
						for point in [Vector2i(left + x, top + y), Vector2i(right - x, top + y), Vector2i(left + x, bottom - y), Vector2i(right - x, bottom - y)]:
							var color: Color = image.get_pixelv(point)
							color.a *= alpha
							image.set_pixelv(point, color)
	image.generate_mipmaps()
	photo_atlas = ImageTexture.create_from_image(image)
	atlas_source = picture.get_instance_id()
	atlas_dimension = n

func _draw() -> void:
	if puzzle == null:
		return
	var palette: Array = SlideUI.PALETTES[theme_id]
	var frame_color := Color("985b2d") if theme_id < 2 else Color(palette[2])
	var scale_unit: float = unit()
	box(Rect2(Vector2(0, 5) * scale_unit, size), Color(0.08, 0.04, 0.01, 0.45), int(19 * scale_unit), true)
	box(Rect2(Vector2.ZERO, size), frame_color.lightened(0.25), int(18 * scale_unit))
	box(Rect2(Vector2.ONE * 4 * scale_unit, size - Vector2.ONE * 8 * scale_unit), frame_color, int(15 * scale_unit))
	box(Rect2(Vector2.ONE * 10 * scale_unit, size - Vector2.ONE * 20 * scale_unit), frame_color.darkened(0.48), int(10 * scale_unit))
	var step: float = tile_step()
	var gutter: float = tile_gap()
	var tile_size: Vector2 = Vector2.ONE * (step - gutter)
	if preview and picture:
		draw_texture_rect(picture, Rect2(Vector2(15, 15), size - Vector2(30, 30)), false)
		return
	for i in range(puzzle.cells.size()):
		box(Rect2(target(i) + Vector2.ONE * gutter * 0.5, tile_size), frame_color.darkened(0.48), int(8 * scale_unit))
	for i in range(puzzle.cells.size()):
		var id: int = puzzle.cells[i]
		if id == 0:
			continue
		var pos: Vector2 = positions.get(id, target(i))
		if not reduced_motion and celebration >= 0.0 and celebration < 0.8:
			pos.y -= sin(clampf((celebration - float(id) * 0.018) * 7.0, 0, PI)) * 7.0
		var rect := Rect2(pos + Vector2.ONE * gutter * 0.5, tile_size)
		var movable: bool = puzzle.can_move(i)
		var lift: float = 2.8 * scale_unit if photo_mode else 2.0 * scale_unit
		box(Rect2(rect.position + Vector2(0, lift), rect.size), Color(0.12, 0.06, 0.02, 0.5), maxi(2, int(step * 0.063)))
		if photo_mode:
			box(rect, Color("ac8053"), maxi(2, int(step * 0.063)))
		else:
			draw_texture_rect(SlideUI.tile_texture(theme_id), rect, false)
		if photo_mode and picture:
			var image_step: Vector2 = picture.get_size() / float(puzzle.dimension)
			var source := Rect2(Vector2((id - 1) % puzzle.dimension, (id - 1) / puzzle.dimension) * image_step, image_step)
			var face: Rect2 = rect.grow(-0.65 * scale_unit)
			face.size.y -= 1.3 * scale_unit
			draw_texture_rect_region(photo_atlas if photo_atlas else picture, face, source)
			draw_texture_rect(SlideUI.photo_finish_texture(), face, false)
			if show_numbers:
				box(Rect2(rect.position + Vector2(5, 5), Vector2(24, 23)), Color(0.1, 0.2, 0.23, 0.73), 7)
				draw_string(font, rect.position + Vector2(5, 22), str(id), HORIZONTAL_ALIGNMENT_CENTER, 24, 14, Color.WHITE)
		elif not hide_numbers:
			var fs: int = int(step * 0.38)
			var baseline := rect.position + Vector2(0, tile_size.y * 0.5 + fs * 0.35)
			draw_string(font, baseline + Vector2(0, 1), str(id), HORIZONTAL_ALIGNMENT_CENTER, tile_size.x, fs, Color(1, 1, 1, 0.5))
			draw_string(font, baseline, str(id), HORIZONTAL_ALIGNMENT_CENTER, tile_size.x, fs, Color(palette[3]))
		if landing.has(id) and not reduced_motion:
			var pulse := StyleBoxFlat.new()
			pulse.bg_color = Color(1, 0.94, 0.77, sin(float(landing[id]) / 0.32 * PI) * 0.13)
			pulse.set_corner_radius_all(maxi(2, int(step * 0.063)))
			draw_style_box(pulse, rect)
		if id == hint_tile and clock < hint_until:
			var glow := StyleBoxFlat.new()
			glow.bg_color = Color(1, 0.8, 0.15, 0.12 + sin(clock * 8) * 0.08)
			glow.border_color = Color("ffe768")
			glow.set_border_width_all(3)
			glow.set_corner_radius_all(10)
			draw_style_box(glow, rect)
	for p in particles:
		var color: Color = p["color"]
		color.a = minf(p["life"], 1.0)
		draw_circle(p["position"], 4, color)
