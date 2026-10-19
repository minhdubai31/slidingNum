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
var frameless: bool = false
var intro: bool = false
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
const CORNER = 0.105
const CONFETTI = [Color("ff7a9c"), Color("ffcf3f"), Color("5ec8ff"), Color("6fd67a"), Color("b48cff"), Color("ff9a4a")]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	resized.connect(func(): sync_positions())

func tile_step() -> float:
	return (size.x - 24.0 * unit()) / puzzle.dimension

func unit() -> float:
	return size.x / 390.0

func tile_gap() -> float:
	return (4.0 if photo_mode else 7.0) * unit()

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
	if intro and clock > 0.5 + puzzle.cells.size() * 0.028:
		intro = false
	if celebration >= 0.0:
		celebration += delta
	for p in particles:
		p["position"] += p["velocity"] * delta
		p["velocity"].y += 420.0 * delta
		p["velocity"].x *= 1.0 - delta * 0.8
		p["spin"] += p["spin_speed"] * delta
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
	for i in range(90):
		var angle: float = randf_range(-PI * 0.92, -PI * 0.08)
		var speed: float = randf_range(220, 520)
		particles.append({"position": size * Vector2(0.5, 0.55), "velocity": Vector2.from_angle(angle) * speed, "life": randf_range(0.9, 1.9), "color": CONFETTI.pick_random(), "spin": randf() * TAU, "spin_speed": randf_range(-9, 9), "shape": i % 3})

func play_intro() -> void:
	if reduced_motion:
		return
	intro = true
	clock = 0.0

# Rounds every piece of the picture and lightly softens over-sharpened artwork so that
# fine hair and foliage do not shimmer when minified onto small tiles.
func prepare_photo() -> void:
	var image: Image = picture.get_image()
	if image.is_compressed():
		image.decompress()
	image.clear_mipmaps()
	image.convert(Image.FORMAT_RGBA8)
	var full: Vector2i = image.get_size()
	image.resize(int(full.x * 0.58), int(full.y * 0.58), Image.INTERPOLATE_CUBIC)
	image.resize(full.x, full.y, Image.INTERPOLATE_BILINEAR)
	var n: int = puzzle.dimension
	var radius: int = maxi(2, int(float(image.get_width()) / n * CORNER))
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

func rounded(color: Color, radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(radius))
	style.anti_aliasing_size = 0.8
	return style

func intro_scale(id: int) -> float:
	if not intro:
		return 1.0
	var order: int = puzzle.cells.find(id)
	var t: float = clampf((clock - 0.08 - order * 0.028) / 0.38, 0.0, 1.0)
	# Back-out easing gives each tile a small pop as it lands.
	var s: float = 1.7
	var k: float = t - 1.0
	return 1.0 + (s + 1.0) * k * k * k + s * k * k

func _draw() -> void:
	if puzzle == null:
		return
	var u: float = unit()
	if not frameless:
		SlideArt.draw_frame(self, Rect2(Vector2.ZERO, size), theme_id)
	var step: float = tile_step()
	var gutter: float = tile_gap()
	var tile_size: Vector2 = Vector2.ONE * (step - gutter)
	var radius: float = maxf(3.0, tile_size.x * CORNER)
	if preview and picture:
		var full := Rect2(Vector2(12, 12) * u + Vector2.ONE * gutter * 0.5, size - Vector2(24, 24) * u - Vector2.ONE * gutter)
		draw_style_box(rounded(Color(0, 0, 0, 0.3), radius), full)
		draw_texture_rect(picture, full, false)
		draw_texture_rect(SlideArt.photo_bevel(), full, false)
		return
	var slot_theme: int = theme_id
	for i in range(puzzle.cells.size()):
		SlideArt.draw_slot(self, Rect2(target(i) + Vector2.ONE * gutter * 0.5, tile_size), slot_theme, radius)
	var order: Array[int] = []
	for i in range(puzzle.cells.size()):
		if puzzle.cells[i] != 0 and puzzle.cells[i] != drag_id:
			order.append(i)
	if drag_id != -1:
		order.append(puzzle.cells.find(drag_id))
	for i in order:
		var id: int = puzzle.cells[i]
		var pos: Vector2 = positions.get(id, target(i))
		if not reduced_motion and celebration >= 0.0 and celebration < 1.0:
			pos.y -= sin(clampf((celebration - float(id) * 0.022) * 6.0, 0, PI)) * 9.0 * u
		var rect := Rect2(pos + Vector2.ONE * gutter * 0.5, tile_size)
		var grow: float = intro_scale(id)
		if id == drag_id:
			grow *= 1.03
		elif landing.has(id) and not reduced_motion:
			grow *= 1.0 + sin(float(landing[id]) / 0.32 * PI) * 0.035
		if not is_equal_approx(grow, 1.0):
			rect = Rect2(rect.get_center() - rect.size * grow * 0.5, rect.size * grow)
		if grow <= 0.02:
			continue
		SlideArt.draw_tile_shadow(self, rect, radius, u, 1.6 if id == drag_id else 1.0)
		if photo_mode and picture:
			draw_photo_tile(rect, id, radius, u)
		else:
			draw_texture_rect(SlideArt.tile_texture(theme_id, id * 7 + 3), rect, false)
			if not hide_numbers:
				SlideArt.draw_number(self, rect, theme_id, id, font, int(step * (0.42 if puzzle.dimension < 5 else 0.4)), u)
		if landing.has(id) and not reduced_motion:
			draw_style_box(rounded(Color(1, 0.96, 0.82, sin(float(landing[id]) / 0.32 * PI) * 0.16), radius), rect)
		if id == hint_tile and clock < hint_until:
			var glow := rounded(Color(1, 0.84, 0.2, 0.14 + sin(clock * 8) * 0.08), radius)
			glow.border_color = Color("ffe768")
			glow.set_border_width_all(int(maxf(2, 3 * u)))
			glow.shadow_color = Color(1, 0.85, 0.2, 0.45 + sin(clock * 8) * 0.2)
			glow.shadow_size = int(10 * u)
			draw_style_box(glow, rect)
	for p in particles:
		var color: Color = p["color"]
		color.a = minf(p["life"] * 1.5, 1.0)
		draw_set_transform(p["position"], p["spin"])
		match int(p["shape"]):
			0: draw_rect(Rect2(-3, -6, 6, 12), color)
			1: draw_circle(Vector2.ZERO, 4, color)
			_: draw_colored_polygon(PackedVector2Array([Vector2(0, -6), Vector2(1.8, -1.8), Vector2(6, 0), Vector2(1.8, 1.8), Vector2(0, 6), Vector2(-1.8, 1.8), Vector2(-6, 0), Vector2(-1.8, -1.8)]), color)
	draw_set_transform(Vector2.ZERO)

func draw_photo_tile(rect: Rect2, id: int, radius: float, u: float) -> void:
	# A thin darker body under the picture face gives each piece visible thickness.
	var lip: float = maxf(1.5, 3.0 * u * clampf(rect.size.x / 110.0, 0.55, 1.0))
	draw_style_box(rounded(Color("2b1a0f"), radius), rect)
	var face := Rect2(rect.position, rect.size - Vector2(0, lip))
	var image_step: Vector2 = picture.get_size() / float(puzzle.dimension)
	var source := Rect2(Vector2((id - 1) % puzzle.dimension, (id - 1) / puzzle.dimension) * image_step, image_step)
	draw_texture_rect_region(photo_atlas if photo_atlas else picture, face, source)
	draw_texture_rect(SlideArt.photo_bevel(), face, false)
	if show_numbers:
		var badge := Rect2(face.position + Vector2(5, 5) * u, Vector2(26, 24) * u)
		draw_style_box(rounded(Color(0.12, 0.08, 0.05, 0.68), 8 * u), badge)
		draw_string(font, badge.position + Vector2(0, 18 * u), str(id), HORIZONTAL_ALIGNMENT_CENTER, badge.size.x, int(15 * u), Color.WHITE)
