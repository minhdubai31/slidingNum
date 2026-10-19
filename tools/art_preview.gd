extends SceneTree
# Renders every procedural material and icon to one sheet for visual review.
func _initialize() -> void:
	var sheet := Image.create(1100, 760, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("e9e1d4"))
	for t in range(8):
		var frame: Image = SlideArt.frame_texture(t, 3, 2).get_image()
		frame.clear_mipmaps()
		frame.resize(240, 160, Image.INTERPOLATE_LANCZOS)
		sheet.blend_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(10 + (t % 4) * 270, 10 + (t / 4) * 180))
		for v in range(3):
			var tile: Image = SlideArt.tile_texture(t, v).get_image()
			tile.clear_mipmaps()
			tile.resize(64, 64, Image.INTERPOLATE_LANCZOS)
			sheet.blend_rect(tile, Rect2i(0, 0, 64, 64), Vector2i(24 + (t % 4) * 270 + v * 72, 30 + (t / 4) * 180))
	var names := ["trophy", "calendar", "calendar_star", "palette", "gear", "bulb", "chart", "feet", "feet_white", "gift", "crown", "star_white", "bolt_white", "check_circle", "sparkle", "heart", "knob"]
	for i in range(names.size()):
		var img: Image = SlideArt.icon(names[i]).get_image()
		img.clear_mipmaps()
		img.resize(96, 96, Image.INTERPOLATE_LANCZOS)
		sheet.blend_rect(img, Rect2i(0, 0, 96, 96), Vector2i(10 + (i % 10) * 105, 380 + (i / 10) * 110))
	var laurel: Image = SlideArt.laurel().get_image()
	laurel.clear_mipmaps()
	sheet.blend_rect(laurel, Rect2i(Vector2i.ZERO, laurel.get_size()), Vector2i(800, 480))
	var plaque: Image = SlideArt.wood_plaque().get_image()
	plaque.clear_mipmaps()
	sheet.blend_rect(plaque, Rect2i(Vector2i.ZERO, plaque.get_size()), Vector2i(10, 600))
	sheet.save_png(OS.get_cmdline_user_args()[0])
	quit()
