extends Control

var scenic: Texture2D
var table: Texture2D
var game_override: Texture2D
var kind: String = "scenic"
var result_glow: GradientTexture2D
var paper_glow: GradientTexture2D
var home_shade: GradientTexture2D
var photo: Texture2D
var animated: bool = true
var clock: float = 0.0
var photo_background: Texture2D
var photo_source: int = 0
var focus_y: float = 0.25
const CONFETTI = [Color("ff7a9c"), Color("ffcf3f"), Color("5ec8ff"), Color("6fd67a"), Color("b48cff"), Color("ff9a4a")]

func _process(delta: float) -> void:
	if animated and kind == "result":
		clock += delta
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if kind == "result":
		draw_result()
		return
	if kind == "paper":
		draw_rect(Rect2(Vector2.ZERO, size), Color("f3ece0"))
		if not paper_glow:
			paper_glow = radial([Color("fbf7ef"), Color("f5efe4"), Color("ebe2d3")], [0.0, 0.55, 1.0], Vector2(0.5, 0.3), Vector2(1.1, 1.0))
		draw_texture_rect(paper_glow, Rect2(Vector2.ZERO, size), false)
		return
	var background: Texture2D = table if kind == "game" and table else scenic
	if kind == "game" and game_override:
		background = game_override
	elif kind == "game" and photo:
		if photo_source != photo.get_instance_id():
			var soft := photo.get_image()
			if soft.is_compressed():
				soft.decompress()
			soft.clear_mipmaps()
			# Only soften the automatic photo backdrop; configured backgrounds bypass this branch.
			soft.resize(16, 16, Image.INTERPOLATE_LANCZOS)
			soft.adjust_bcs(1.0, 0.85, 0.45)
			soft.resize(512, 512, Image.INTERPOLATE_CUBIC)
			photo_background = ImageTexture.create_from_image(soft)
			photo_source = photo.get_instance_id()
		background = photo_background
	if background:
		var ratio: float = maxf(size.x / background.get_width(), size.y / background.get_height())
		var source_size: Vector2 = size / ratio
		var source := Rect2((background.get_size() - source_size) / 2, source_size)
		draw_texture_rect_region(background, Rect2(Vector2.ZERO, size), source)
	if kind == "game":
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.10, 0.05, 0.12, 0.42) if photo else Color(0.08, 0.04, 0.01, 0.12))
	else:
		if not home_shade:
			home_shade = GradientTexture2D.new()
			var colors := Gradient.new()
			colors.colors = PackedColorArray([Color(0.02, 0.08, 0.12, 0.10), Color(0.025, 0.09, 0.10, 0.0), Color(0.025, 0.09, 0.10, 0.12), Color(0.02, 0.07, 0.08, 0.86)])
			colors.offsets = PackedFloat32Array([0.0, 0.18, 0.45, 1.0])
			home_shade.gradient = colors
			home_shade.width = 8
			home_shade.height = 512
			home_shade.fill_from = Vector2(0.5, 0)
			home_shade.fill_to = Vector2(0.5, 1)
		draw_texture_rect(home_shade, Rect2(Vector2.ZERO, size), false)

func radial(colors: Array, offsets: Array, from: Vector2, to: Vector2) -> GradientTexture2D:
	var texture := GradientTexture2D.new()
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray(colors)
	gradient.offsets = PackedFloat32Array(offsets)
	texture.gradient = gradient
	texture.width = 256
	texture.height = 512
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = from
	texture.fill_to = to
	return texture

func draw_result() -> void:
	if not result_glow:
		result_glow = radial([Color("7a5226"), Color("3a2a19"), Color("1a1510")], [0.0, 0.55, 1.0], Vector2(0.5, focus_y), Vector2(1.05, 0.95))
	draw_texture_rect(result_glow, Rect2(Vector2.ZERO, size), false)
	var center := Vector2(size.x * 0.5, size.y * focus_y)
	# Slowly turning sunburst behind the reward.
	var reach: float = size.length() * 0.7
	var turn: float = clock * 0.12 if animated else 0.0
	for i in range(16):
		var a: float = turn + i * TAU / 16.0
		var spread: float = 0.09
		var ray := PackedVector2Array([center, center + Vector2.from_angle(a - spread) * reach, center + Vector2.from_angle(a + spread) * reach])
		draw_colored_polygon(ray, Color(1.0, 0.86, 0.5, 0.045))
	for r in range(6):
		draw_circle(center, size.x * (0.42 - r * 0.06), Color(1.0, 0.78, 0.38, 0.03))
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	# Falling confetti loops forever; positions derive from time so nothing accumulates.
	for i in range(34):
		var speed: float = rng.randf_range(38, 80)
		var x0: float = rng.randf_range(0.02, 0.98) * size.x
		var phase: float = rng.randf_range(0, size.y + 40)
		var y: float = fposmod(phase + (clock * speed if animated else 0.0), size.y + 40) - 20
		var x: float = x0 + sin(clock * 1.4 + i) * 14.0
		var color: Color = CONFETTI[i % CONFETTI.size()]
		color.a = 0.75
		draw_set_transform(Vector2(x, y), clock * rng.randf_range(-3, 3) + i, Vector2(1.0, absf(cos(clock * 2.5 + i)) * 0.8 + 0.2))
		if i % 3 == 0:
			draw_circle(Vector2.ZERO, 3.2, color)
		else:
			draw_rect(Rect2(-3, -6, 6, 12), color)
	draw_set_transform(Vector2.ZERO)
	# Twinkling sparkles around the hero.
	for i in range(10):
		var angle: float = rng.randf_range(0, TAU)
		var distance: float = rng.randf_range(0.30, 0.48) * size.x
		var point: Vector2 = center + Vector2(cos(angle) * distance * 1.05, sin(angle) * distance * 0.75)
		var twinkle: float = 0.5 + 0.5 * sin(clock * 3.0 + i * 1.7) if animated else 0.8
		var radius: float = rng.randf_range(4, 9) * (0.45 + twinkle * 0.7)
		var color := Color(1.0, 0.92, 0.6, 0.35 + twinkle * 0.6)
		draw_colored_polygon(PackedVector2Array([point + Vector2(0, -radius * 1.6), point + Vector2(radius * 0.32, -radius * 0.32), point + Vector2(radius * 1.6, 0), point + Vector2(radius * 0.32, radius * 0.32), point + Vector2(0, radius * 1.6), point + Vector2(-radius * 0.32, radius * 0.32), point + Vector2(-radius * 1.6, 0), point + Vector2(-radius * 0.32, -radius * 0.32)]), color)
