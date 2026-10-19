class_name SlideUI
extends RefCounted

const INK = Color("35291f")
const MUTED = Color("877864")
const CREAM = Color("fff8eb")
const GREEN = Color("2dc52e")
const BLUE = Color("168cff")
const THEME_NAMES = ["Gỗ cổ điển", "Gỗ tối", "Gốm sứ", "Đá cẩm thạch", "Kim loại", "Kính mờ", "Đất sét", "Neon"]
static var icons: Dictionary = {}
static var tiles: Dictionary = {}
static var fonts: Dictionary = {}
static var animations_enabled: bool = true
static var click_feedback: Callable

static func font_at(weight: int) -> Font:
	if fonts.has(weight):
		return fonts[weight]
	var variation := FontVariation.new()
	variation.base_font = load("res://assets/Nunito.ttf")
	variation.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): float(weight)}
	fonts[weight] = variation
	return variation

static func panel(color: Color = CREAM, radius: int = 22, bevel: bool = true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(18)
	if bevel:
		s.border_color = color.lightened(0.14)
		s.set_border_width_all(1)
		s.border_width_top = 1
		s.shadow_color = Color(0.19, 0.12, 0.04, 0.19)
		s.shadow_size = 2
		s.shadow_offset = Vector2(0, 2)
	return s

static func t(value: String) -> String:
	return SlideI18n.t(value)

static func text(value: String, font_size: int = 18, color: Color = INK, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = t(value)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", font_at(850))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func action(value: String, callback: Callable, primary: bool = false, glyph: String = "") -> Button:
	var b := SlideButton.new()
	b.primary = primary
	b.text = t(value)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER if value.is_empty() else HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size.y = 58
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_font_override("font", font_at(800))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var empty := panel(Color.TRANSPARENT, 0, false)
		empty.set_content_margin_all(14)
		b.add_theme_stylebox_override(state, empty)
	b.add_theme_stylebox_override("focus", panel(Color(0, 0, 0, 0), 22, false))
	b.add_theme_color_override("font_color", Color.WHITE if primary else INK)
	b.add_theme_color_override("font_hover_color", Color.WHITE if primary else INK)
	b.add_theme_color_override("font_pressed_color", Color.WHITE if primary else INK)
	b.add_theme_color_override("font_disabled_color", MUTED)
	if value.is_empty():
		for state in ["normal", "hover", "pressed", "disabled"]:
			var skin: StyleBox = b.get_theme_stylebox(state).duplicate()
			skin.set_content_margin_all(9)
			b.add_theme_stylebox_override(state, skin)
	if not glyph.is_empty():
		b.icon = icon(glyph, "ffffff" if primary else "493929")
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 25)
		b.add_theme_constant_override("h_separation", 9)
	b.pressed.connect(func(): b.activate(callback))
	return b

static func round_action(glyph: String, callback: Callable, diameter: float = 46) -> Button:
	var b := action("", callback, false, glyph) as SlideButton
	b.round_button = true
	b.custom_minimum_size = Vector2.ONE * diameter
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_constant_override("icon_max_width", int(diameter * 0.44))
	for state in ["normal", "hover", "pressed", "disabled"]:
		var empty := StyleBoxEmpty.new()
		b.add_theme_stylebox_override(state, empty)
	b.add_theme_color_override("icon_disabled_color", Color(1, 1, 1, 0.32))
	return b

static func chip(value: String, background: Color, foreground: Color, font_size: int = 13) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var skin := panel(background, 12, false)
	skin.content_margin_left = 11
	skin.content_margin_right = 11
	skin.content_margin_top = 2
	skin.content_margin_bottom = 3
	pill.add_theme_stylebox_override("panel", skin)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	pill.add_child(text(value, font_size, foreground, true))
	return pill

# A glossy coloured rounded square holding a white glyph, used by lists and achievements.
static func badge_icon(texture: Texture2D, color: Color, length: float = 46, muted: bool = false) -> PanelContainer:
	var square := PanelContainer.new()
	square.mouse_filter = Control.MOUSE_FILTER_IGNORE
	square.custom_minimum_size = Vector2.ONE * length
	square.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tint: Color = color if not muted else Color("c9c0b2")
	var skin := panel(tint, int(length * 0.28), false)
	skin.set_content_margin_all(length * 0.2)
	skin.border_color = tint.lightened(0.28)
	skin.border_width_top = 2
	skin.shadow_color = Color(tint.darkened(0.45), 0.35)
	skin.shadow_size = 3
	skin.shadow_offset = Vector2(0, 2)
	square.add_theme_stylebox_override("panel", skin)
	var glyph := TextureRect.new()
	glyph.texture = texture
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	square.add_child(glyph)
	return square

static func photo_finish_texture() -> Texture2D:
	return SlideArt.photo_bevel()

static func icon(name: String, color: String = "493929") -> Texture2D:
	var key: String = name + color
	if icons.has(key):
		return icons[key]
	var art: Dictionary = {"bulb": "bulb", "trophy": "trophy", "palette": "palette", "calendar": "calendar", "stats": "chart", "feet": "feet", "gift": "gift"}
	if art.has(name) and color not in ["ffffff", "fff8eb"]:
		icons[key] = SlideArt.icon(art[name])
		return icons[key]
	if name == "star" and color not in ["ffffff", "fff8eb"]:
		icons[key] = load("res://assets/third_party/fluent/star.png")
		return icons[key]
	var colored: Dictionary = {"bulb": "1f4a1", "trophy": "1f3c6", "calendar": "1f4c5", "palette": "1f3a8", "stats": "1f4ca", "star": "2b50", "bolt": "26a1"}
	var solid: Dictionary = {"back": "chevron-left", "chevron": "chevron-right", "play": "play", "pause": "pause", "home": "house", "restart": "rotate-left", "shuffle": "shuffle", "eye": "eye", "bulb": "lightbulb", "undo": "arrow-rotate-left", "clock": "stopwatch", "steps": "shoe-prints", "grid": "table-cells", "stats": "chart-simple", "trophy": "trophy", "star": "star", "calendar": "calendar-days", "settings": "gear", "palette": "palette", "sound": "volume-high", "music": "music", "check": "check", "help": "circle-question", "image": "image", "close": "xmark", "lock": "lock", "leaf": "leaf", "bolt": "bolt", "trash": "trash-can", "vibrate": "mobile-screen-button", "toggle_on": "toggle-on", "toggle_off": "toggle-off", "info": "circle-info"}
	var use_color: bool = colored.has(name) and color != "ffffff" and color != "fff8eb"
	var path: String = "res://assets/third_party/noto/%s.svg" % colored[name] if use_color else "res://assets/third_party/fontawesome/%s.svg" % solid.get(name, "circle-question")
	var imported: Texture2D = load(path)
	var image: Image = imported.get_image()
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	var factor: float = 64.0 / maxf(image.get_width(), image.get_height())
	image.resize(maxi(1, int(image.get_width() * factor)), maxi(1, int(image.get_height() * factor)), Image.INTERPOLATE_LANCZOS)
	if not use_color:
		var tint := Color("27ba43" if name == "toggle_on" else ("b8afa0" if name == "toggle_off" else color))
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var pixel: Color = image.get_pixel(x, y)
				image.set_pixel(x, y, Color(tint.r, tint.g, tint.b, pixel.a))
	var canvas := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.TRANSPARENT)
	canvas.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), (Vector2i(64, 64) - image.get_size()) / 2)
	if name in ["toggle_on", "toggle_off"]:
		canvas.resize(44, 44, Image.INTERPOLATE_LANCZOS)
	var texture := ImageTexture.create_from_image(canvas)
	icons[key] = texture
	return texture
