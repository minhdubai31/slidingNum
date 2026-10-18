class_name SlideUI
extends RefCounted

const INK = Color("35291f")
const MUTED = Color("877864")
const CREAM = Color("fff8eb")
const GREEN = Color("2dc52e")
const BLUE = Color("168cff")
const THEME_NAMES = ["Gỗ cổ điển", "Gỗ tối", "Gốm sứ", "Đá cẩm thạch", "Kim loại", "Kính mờ", "Đất sét", "Neon"]
const PALETTES = [
	["f9d697", "e8aa5f", "b66d2d", "513017"],
	["a76a3b", "724326", "442717", "f9dfb0"],
	["fffef6", "e4dfd2", "b9ac98", "5c554a"],
	["f0f1f4", "c7cbd3", "9199a6", "4a5361"],
	["b9bdc5", "737b87", "464e5c", "ffffff"],
	["a6e3f2", "5eafd3", "3d83a3", "204c69"],
	["f4b4bc", "d98194", "b95673", "773951"],
	["292454", "14122c", "7164ef", "7feaff"]]
static var icons: Dictionary = {}
static var tiles: Dictionary = {}
static var fonts: Dictionary = {}
static var photo_finish: Texture2D
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

static func text(value: String, font_size: int = 18, color: Color = INK, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", font_at(850))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func action(value: String, callback: Callable, primary: bool = false, glyph: String = "") -> Button:
	var b := SlideButton.new()
	b.primary = primary
	b.text = value
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
	return b

static func photo_finish_texture() -> Texture2D:
	if photo_finish:
		return photo_finish
	var svg: String = '<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 128 128"><defs><linearGradient id="s" x1="0" y1="0" x2=".7" y2="1"><stop stop-color="#ffffff" stop-opacity=".035"/><stop offset=".45" stop-color="#ffffff" stop-opacity="0"/><stop offset="1" stop-color="#281a12" stop-opacity=".025"/></linearGradient><clipPath id="c"><rect x=".5" y=".5" width="127" height="127" rx="8"/></clipPath></defs><g clip-path="url(#c)"><rect width="128" height="128" rx="8" fill="url(#s)"/><path d="M2 118V9Q2 2 9 2h109" fill="none" stroke="#fffdf7" stroke-opacity=".11" stroke-width="6" stroke-linecap="round"/><path d="M2 118V9Q2 2 9 2h109" fill="none" stroke="#fffdf7" stroke-opacity=".17" stroke-width="3" stroke-linecap="round"/><path d="M1.6 118V9Q1.6 1.6 9 1.6h109" fill="none" stroke="#fffdf7" stroke-opacity=".38" stroke-width="1" stroke-linecap="round"/><path d="M10 126h109q7 0 7-7V10" fill="none" stroke="#291a10" stroke-opacity=".19" stroke-width="4" stroke-linecap="round"/><path d="M10 126.3h109q7.3 0 7.3-7.3V10" fill="none" stroke="#291a10" stroke-opacity=".28" stroke-width="1" stroke-linecap="round"/></g></svg>'
	var image := Image.new()
	image.load_svg_from_string(svg)
	photo_finish = ImageTexture.create_from_image(image)
	return photo_finish
static func icon(name: String, color: String = "493929") -> Texture2D:
	var key: String = name + color
	if icons.has(key):
		return icons[key]
	if name in ["bulb", "trophy", "palette", "calendar", "star", "stats"] and color not in ["ffffff", "fff8eb"]:
		var texture: Texture2D = load("res://assets/third_party/fluent/%s.png" % name)
		icons[key] = texture
		return texture
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
static func tile_texture(theme_id: int) -> Texture2D:
	if tiles.has(theme_id):
		return tiles[theme_id]
	var p: Array = PALETTES[theme_id]
	var detail: String = ""
	if theme_id < 2:
		for i in range(24):
			var x: float = 2.0 + i * 5.4
			detail += '<path d="M%.1f 0C%.1f 26 %.1f 39 %.1f 64S%.1f 101 %.1f 128" stroke="#673513" stroke-opacity=".085" stroke-width=".55" fill="none"/>' % [x, x-3, x+4, x, x-4, x+1]
		detail += '<path d="M34 0q-8 35 0 64t0 64M94 0q7 38-1 72t0 56" stroke="#fff2c9" stroke-opacity=".21" stroke-width="1.2" fill="none"/>'
	elif theme_id == 2:
		detail = '<ellipse cx="34" cy="20" rx="64" ry="34" fill="url(#gloss)" opacity=".7"/>'
	elif theme_id == 3:
		for offset in [0, 43, 87]:
			detail += '<path d="M%d-15C%d 14 %d 35 %d 51S%d 82 %d 145" stroke="#717988" stroke-opacity=".11" stroke-width="7" fill="none"/>' % [offset,offset+44,offset-19,offset+15,offset+38,offset-5]
			detail += '<path d="M%d-15C%d 14 %d 35 %d 51S%d 82 %d 145" stroke="#697584" stroke-opacity=".28" stroke-width="1.2" fill="none"/>' % [offset,offset+44,offset-19,offset+15,offset+38,offset-5]
		detail += '<path d="M0 80q35-12 58-47m-4 41q30 6 74-9" stroke="#9da1aa" stroke-opacity=".27" stroke-width=".7" fill="none"/>'
	elif theme_id == 4:
		for i in range(60):
			detail += '<path d="M0 %sH128" stroke="#ffffff" stroke-opacity=".075" stroke-width=".35"/>' % (i*2.1)
		detail += '<path d="M-20 100 58-20H97L15 148Z" fill="url(#gloss)" opacity=".22"/>'
	elif theme_id == 5:
		detail = '<path d="M-15 115 71-10H103L18 140Z" fill="#ffffff" opacity=".14"/><path d="M6 0H122V36Q63 19 6 65Z" fill="url(#gloss)" opacity=".55"/>'
	elif theme_id == 6:
		detail = '<ellipse cx="48" cy="12" rx="85" ry="48" fill="url(#gloss)" opacity=".18"/>'
	else:
		detail = '<rect x="6" y="6" width="116" height="113" rx="10" stroke="#3fa8ff" stroke-width="4" opacity=".22" fill="none"/><rect x="6" y="6" width="116" height="113" rx="10" stroke="#b881ff" stroke-width="1.1" fill="none"/>'
	var svg: String = '<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 128 128"><defs><linearGradient id="g" x1="0" y1="0" x2=".75" y2="1"><stop stop-color="#%s"/><stop offset=".48" stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient><linearGradient id="gloss" x2=".2" y2="1"><stop stop-color="#ffffff" stop-opacity=".9"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></linearGradient><clipPath id="c"><rect x="3" y="3" width="122" height="119" rx="12"/></clipPath></defs><rect x="1" y="2" width="126" height="125" rx="14" fill="#%s"/><rect x="2" y="1" width="124" height="122" rx="13" fill="url(#g)"/><g clip-path="url(#c)">%s</g><path d="M4 112V15Q4 4 15 4h98" fill="none" stroke="#fff9e7" stroke-opacity=".26" stroke-width="4"/><path d="M4 112V15Q4 4 15 4h98" fill="none" stroke="#ffffff" stroke-opacity=".52" stroke-width="1"/><path d="M14 121h99q10 0 10-10V14" fill="none" stroke="#28180f" stroke-opacity=".21" stroke-width="2.7"/></svg>' % [p[0], Color(p[0]).lerp(Color(p[1]), 0.48).to_html(false), p[1], p[2], detail]
	var image := Image.new()
	image.load_svg_from_string(svg)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	tiles[theme_id] = texture
	return texture
