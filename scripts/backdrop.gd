extends Control

var scenic: Texture2D
var table: Texture2D
var kind: String = "scenic"
var result_glow: GradientTexture2D
var home_shade: GradientTexture2D
var photo: Texture2D
var animated: bool = true
var clock: float = 0.0
var photo_background: Texture2D
var photo_source: int = 0

func _process(delta: float) -> void:
	if animated and kind == "result":
		clock += delta
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if kind == "result":
		if not result_glow:
			result_glow = GradientTexture2D.new()
			var colors := Gradient.new()
			colors.colors = PackedColorArray([Color("65451f"), Color("302416"), Color("17150f")])
			colors.offsets = PackedFloat32Array([0.0, 0.65, 1.0])
			result_glow.gradient = colors
			result_glow.width = 512
			result_glow.height = 1024
			result_glow.fill = GradientTexture2D.FILL_RADIAL
			result_glow.fill_from = Vector2(0.5, 0.28)
			result_glow.fill_to = Vector2(1.0, 0.85)
		draw_texture_rect(result_glow, Rect2(Vector2.ZERO, size), false)
		var rng := RandomNumberGenerator.new()
		rng.seed = 42
		for i in range(18):
			var x: float = rng.randf_range(0.07, 0.26) if i % 2 == 0 else rng.randf_range(0.74, 0.93)
			var point := Vector2(x * size.x, rng.randf_range(0.07, 0.33) * size.y)
			var color: Color = [Color("efb94d"), Color("e99b79"), Color("86b86c")][i % 3]
			color.a = 0.55 + (sin(clock * 2.1 + i) * 0.24 if animated else 0.0)
			if animated:
				point.y += sin(clock * 1.3 + i * 0.8) * 7.0
			if i % 4 == 0:
				draw_colored_polygon(PackedVector2Array([point + Vector2(0, -5), point + Vector2(2, -1), point + Vector2(5, 0), point + Vector2(2, 1), point + Vector2(0, 5), point + Vector2(-2, 1), point + Vector2(-5, 0), point + Vector2(-2, -1)]), color)
			else:
				draw_set_transform(point, rng.randf_range(-0.8, 0.8))
				draw_style_box(_confetti_style(color), Rect2(-2, -4, 4, 8))
				draw_set_transform(Vector2.ZERO)
		return
	var background: Texture2D = table if kind in ["game", "result"] and table else scenic
	if kind == "game" and photo:
		if photo_source != photo.get_instance_id():
			var soft := photo.get_image()
			if soft.is_compressed():
				soft.decompress()
			soft.resize(40, 40, Image.INTERPOLATE_CUBIC)
			soft.resize(512, 512, Image.INTERPOLATE_CUBIC)
			photo_background = ImageTexture.create_from_image(soft)
			photo_source = photo.get_instance_id()
		background = photo_background
	if background:
		var ratio: float = maxf(size.x / background.get_width(), size.y / background.get_height())
		var source_size: Vector2 = size / ratio
		var source := Rect2((background.get_size() - source_size) / 2, source_size)
		draw_texture_rect_region(background, Rect2(Vector2.ZERO, size), source)
	if kind == "paper":
		draw_rect(Rect2(Vector2.ZERO, size), Color("f5eddf"))
	elif kind == "game" or kind == "result":
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.04, 0.10, 0.50 if photo else 0.15))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.07, 0.06, 0.06))
		if not home_shade:
			home_shade = GradientTexture2D.new()
			var colors := Gradient.new()
			colors.colors = PackedColorArray([Color.TRANSPARENT, Color(0.025, 0.09, 0.10, 0.05), Color(0.025, 0.09, 0.10, 0.88)])
			colors.offsets = PackedFloat32Array([0.0, 0.40, 1.0])
			home_shade.gradient = colors
			home_shade.width = 8
			home_shade.height = 512
			home_shade.fill_from = Vector2(0.5, 0)
			home_shade.fill_to = Vector2(0.5, 1)
		draw_texture_rect(home_shade, Rect2(Vector2.ZERO, size), false)

func _confetti_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(1)
	return style
