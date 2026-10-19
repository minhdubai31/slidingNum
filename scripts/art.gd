class_name SlideArt
extends RefCounted

# Procedural SVG art: tile/frame materials and colourful icons, rendered once and cached.

const MATERIALS = [
	{"top": "f7d9a4", "bottom": "e0a862", "side": "a2642c", "ink": "4b2a12", "ink_shade": "fff1d4", "frame_top": "dc9d5c", "frame_bottom": "a9662e", "rim": "ffd99f", "tray": "4a2913", "grain": "7a4419", "light": "fff3d0"},
	{"top": "a1653a", "bottom": "6c3a1e", "side": "3b1e0e", "ink": "ffe2b6", "ink_shade": "2a1207", "frame_top": "754124", "frame_bottom": "47230f", "rim": "b07444", "tray": "24120a", "grain": "2a1206", "light": "f4c690"},
	{"top": "fffdf8", "bottom": "e9e2d4", "side": "b8aa94", "ink": "5d5448", "ink_shade": "ffffff", "frame_top": "f3ede3", "frame_bottom": "d3c7b3", "rim": "ffffff", "tray": "c7baa5", "grain": "", "light": "ffffff"},
	{"top": "fbfbfc", "bottom": "dcdee4", "side": "959ca8", "ink": "3f4652", "ink_shade": "ffffff", "frame_top": "eef0f3", "frame_bottom": "c2c6ce", "rim": "ffffff", "tray": "9aa0ab", "grain": "7d8593", "light": "ffffff"},
	{"top": "c8cdd5", "bottom": "7e8693", "side": "3a414c", "ink": "2a3039", "ink_shade": "edf1f6", "frame_top": "939ba7", "frame_bottom": "4a525e", "rim": "dfe4eb", "tray": "2e343d", "grain": "", "light": "ffffff"},
	{"top": "cdf0fb", "bottom": "6fc0e5", "side": "3786b0", "ink": "174a68", "ink_shade": "ecfbff", "frame_top": "d6f2fc", "frame_bottom": "88cdea", "rim": "ffffff", "tray": "4b9bc3", "grain": "", "light": "ffffff"},
	{"top": "fac9d0", "bottom": "e590a3", "side": "b25a72", "ink": "7a3450", "ink_shade": "ffe8ee", "frame_top": "f7c3cc", "frame_bottom": "d78298", "rim": "ffe6eb", "tray": "bd6a82", "grain": "", "light": "ffffff"},
	{"top": "2b2663", "bottom": "15123a", "side": "0a081f", "ink": "8ff1ff", "ink_shade": "", "frame_top": "342983", "frame_bottom": "1c1550", "rim": "9b7cff", "tray": "0b0a22", "grain": "", "light": "ffffff"}]

static var cache: Dictionary = {}

static func material(theme_id: int) -> Dictionary:
	return MATERIALS[clampi(theme_id, 0, MATERIALS.size() - 1)]

static func svg_texture(key: String, svg: String, scale: float) -> Texture2D:
	if cache.has(key):
		return cache[key]
	var image := Image.new()
	image.load_svg_from_string(svg, scale)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	cache[key] = texture
	return texture

static func svg_doc(width: float, height: float, body: String) -> String:
	return '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %s %s">%s</svg>' % [int(width), int(height), str(width), str(height), body]

# ---------------------------------------------------------------- materials

static func grain_lines(rng: RandomNumberGenerator, width: float, height: float, color: String, light: String, vertical: bool, count: int) -> String:
	var out: String = ""
	for i in range(count):
		var base: float = rng.randf_range(-4, (width if vertical else height) + 4)
		var a: float = rng.randf_range(-6, 6)
		var b: float = rng.randf_range(-6, 6)
		var c: float = rng.randf_range(-3, 3)
		var path: String
		if vertical:
			path = "M%.1f -6C%.1f %.1f %.1f %.1f %.1f %.1f" % [base, base + a, height * 0.3, base + b, height * 0.7, base + c, height + 6]
		else:
			path = "M-6 %.1fC%.1f %.1f %.1f %.1f %.1f %.1f" % [base, width * 0.3, base + a, width * 0.7, base + b, width + 6, base + c]
		out += '<path d="%s" fill="none" stroke="#%s" stroke-opacity="%.3f" stroke-width="%.2f"/>' % [path, color, rng.randf_range(0.05, 0.17), rng.randf_range(0.35, 1.5)]
	for i in range(4):
		var base: float = rng.randf_range(0, width if vertical else height)
		var wobble: float = rng.randf_range(-9, 9)
		var path: String
		if vertical:
			path = "M%.1f -6C%.1f %.1f %.1f %.1f %.1f %.1f" % [base, base + wobble, height * 0.35, base - wobble, height * 0.65, base, height + 6]
		else:
			path = "M-6 %.1fC%.1f %.1f %.1f %.1f %.1f %.1f" % [base, width * 0.35, base + wobble, width * 0.65, base - wobble, width + 6, base]
		out += '<path d="%s" fill="none" stroke="#%s" stroke-opacity="%.3f" stroke-width="%.1f"/>' % [path, light, rng.randf_range(0.06, 0.13), rng.randf_range(5, 13)]
	return out

static func marble_veins(rng: RandomNumberGenerator, width: float, height: float, color: String, count: int) -> String:
	var out: String = ""
	for i in range(count):
		var start := Vector2(rng.randf_range(-10, width * 0.6), -8)
		var path: String = "M%.1f %.1f" % [start.x, start.y]
		var point := start
		while point.y < height + 8:
			var next := point + Vector2(rng.randf_range(-6, 30), rng.randf_range(18, 42))
			path += "Q%.1f %.1f %.1f %.1f" % [point.x + rng.randf_range(-16, 16), (point.y + next.y) * 0.5, next.x, next.y]
			point = next
		out += '<path d="%s" fill="none" stroke="#%s" stroke-opacity=".10" stroke-width="6"/>' % [path, color]
		out += '<path d="%s" fill="none" stroke="#%s" stroke-opacity=".42" stroke-width="%.2f"/>' % [path, color, rng.randf_range(0.6, 1.3)]
	for i in range(count + 2):
		var p := Vector2(rng.randf_range(0, width), rng.randf_range(0, height))
		out += '<path d="M%.1f %.1fq%.1f %.1f %.1f %.1f" fill="none" stroke="#%s" stroke-opacity=".25" stroke-width=".5"/>' % [p.x, p.y, rng.randf_range(-12, 12), rng.randf_range(4, 12), rng.randf_range(-20, 20), rng.randf_range(10, 26), color]
	return out

static func tile_detail(theme_id: int, variant: int, width: float, height: float) -> String:
	var m: Dictionary = material(theme_id)
	var rng := RandomNumberGenerator.new()
	rng.seed = theme_id * 97 + variant * 13 + 5
	match theme_id:
		0, 1:
			var out: String = grain_lines(rng, width, height, m.grain, m.light, true, 26)
			if variant % 3 == 1:
				var knot := Vector2(rng.randf_range(30, 98), rng.randf_range(30, 90))
				for r in range(4):
					out += '<ellipse cx="%.1f" cy="%.1f" rx="%.1f" ry="%.1f" fill="none" stroke="#%s" stroke-opacity=".13" stroke-width=".8"/>' % [knot.x, knot.y, 2.0 + r * 2.4, 4.5 + r * 4.0, m.grain]
			return out
		2:
			return '<ellipse cx="38" cy="14" rx="70" ry="34" fill="url(#gloss)" opacity=".85"/><ellipse cx="30" cy="22" rx="9" ry="4" fill="#ffffff" opacity=".9"/>'
		3:
			return marble_veins(rng, width, height, m.grain, 2)
		4:
			var out: String = ""
			var y: float = 0.0
			while y < height:
				out += '<path d="M0 %.1fH%.1f" stroke="#%s" stroke-opacity="%.3f" stroke-width=".55"/>' % [y, width, "ffffff" if rng.randf() > 0.5 else "1b1f26", rng.randf_range(0.04, 0.12)]
				y += rng.randf_range(1.0, 2.6)
			out += '<path d="M-20 %.1fL%.1f -20H%.1fL-20 %.1fZ" fill="#ffffff" opacity=".16"/>' % [height * 0.9, width * 0.75, width * 0.95, height * 1.1]
			return out
		5:
			return '<path d="M-10 %.1fL%.1f -10H%.1fL-10 %.1fZ" fill="#ffffff" opacity=".20"/><path d="M6 0H%.1fV30Q%.1f 16 6 54Z" fill="url(#gloss)" opacity=".55"/>' % [height * 0.85, width * 0.62, width * 0.8, height * 1.05, width - 6, width * 0.5]
		6:
			var out: String = '<ellipse cx="44" cy="16" rx="80" ry="40" fill="url(#gloss)" opacity=".28"/>'
			for i in range(45):
				out += '<circle cx="%.1f" cy="%.1f" r="%.2f" fill="#%s" opacity="%.2f"/>' % [rng.randf_range(0, width), rng.randf_range(0, height), rng.randf_range(0.4, 1.1), "7a3450" if i % 2 == 0 else "ffffff", rng.randf_range(0.06, 0.16)]
			return out
	return ""

static func tile_texture(theme_id: int, variant: int = 0) -> Texture2D:
	variant = variant % (4 if theme_id in [0, 1, 3] else 1)
	var key: String = "tile:%d:%d" % [theme_id, variant]
	if cache.has(key):
		return cache[key]
	var m: Dictionary = material(theme_id)
	var face_alpha: String = ".9" if theme_id == 5 else "1"
	var defs: String = '<defs><linearGradient id="g" x1="0" y1="0" x2=".35" y2="1"><stop stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient><linearGradient id="gloss" x2=".15" y2="1"><stop stop-color="#ffffff" stop-opacity=".95"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></linearGradient><linearGradient id="n" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#5fe3ff"/><stop offset="1" stop-color="#b56cff"/></linearGradient><clipPath id="c"><rect width="128" height="121" rx="16"/></clipPath></defs>' % [m.top, m.bottom]
	var body: String = defs
	body += '<rect y="5" width="128" height="123" rx="17" fill="#%s"/>' % m.side
	body += '<rect width="128" height="121" rx="16" fill="url(#g)" fill-opacity="%s"/>' % face_alpha
	body += '<g clip-path="url(#c)">%s</g>' % tile_detail(theme_id, variant, 128, 121)
	if theme_id == 7:
		body += '<rect x="5" y="5" width="118" height="111" rx="12" fill="none" stroke="url(#n)" stroke-width="10" opacity=".16"/><rect x="5" y="5" width="118" height="111" rx="12" fill="none" stroke="url(#n)" stroke-width="5.5" opacity=".32"/><rect x="5" y="5" width="118" height="111" rx="12" fill="none" stroke="url(#n)" stroke-width="2.4"/><rect x="5" y="5" width="118" height="111" rx="12" fill="none" stroke="#ffffff" stroke-opacity=".55" stroke-width=".7"/>'
	else:
		body += '<path d="M3 98V17Q3 3 17 3h94" fill="none" stroke="#ffffff" stroke-opacity="%s" stroke-width="3.2" stroke-linecap="round"/>' % (".38" if theme_id in [1, 4] else ".62")
		body += '<path d="M3 98V17Q3 3 17 3h94" fill="none" stroke="#ffffff" stroke-opacity=".9" stroke-width=".9" stroke-linecap="round"/>'
		body += '<path d="M12 118h100q13 0 13-13V24" fill="none" stroke="#1e1208" stroke-opacity=".16" stroke-width="3.5" stroke-linecap="round"/>'
	return svg_texture(key, svg_doc(128, 128, body), 3.0)

static func frame_texture(theme_id: int, columns: int, rows: int) -> Texture2D:
	var key: String = "frame:%d:%d:%d" % [theme_id, columns, rows]
	if cache.has(key):
		return cache[key]
	var m: Dictionary = material(theme_id)
	var h: float = 128.0
	var w: float = 128.0 * columns / rows
	var b: float = 3.95
	var rng := RandomNumberGenerator.new()
	rng.seed = theme_id * 31 + 7
	var body: String = '<defs><linearGradient id="f" x1="0" y1="0" x2=".3" y2="1"><stop stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient><linearGradient id="t" x2="0" y2="1"><stop stop-color="#000000" stop-opacity=".42"/><stop offset=".08" stop-color="#000000" stop-opacity=".0"/></linearGradient><linearGradient id="n" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#5fe3ff"/><stop offset="1" stop-color="#b56cff"/></linearGradient><clipPath id="c"><rect width="%s" height="%s" rx="7"/></clipPath></defs>' % [m.frame_top, m.frame_bottom, str(w), str(h)]
	body += '<rect width="%s" height="%s" rx="7" fill="url(#f)" fill-opacity="%s"/>' % [str(w), str(h), ".92" if theme_id == 5 else "1"]
	var detail: String = ""
	if theme_id in [0, 1]:
		detail = grain_lines(rng, w, h, m.grain, m.light, false, 34)
	elif theme_id == 3:
		detail = marble_veins(rng, w, h, m.grain, 3)
	elif theme_id == 4:
		for i in range(80):
			detail += '<path d="M0 %.1fH%s" stroke="#ffffff" stroke-opacity="%.3f" stroke-width=".4"/>' % [i * 1.6, str(w), rng.randf_range(0.03, 0.1)]
	body += '<g clip-path="url(#c)">%s</g>' % detail
	if theme_id == 7:
		body += '<rect x="1.4" y="1.4" width="%.1f" height="%.1f" rx="6" fill="none" stroke="url(#n)" stroke-width="4" opacity=".35"/><rect x="1.2" y="1.2" width="%.1f" height="%.1f" rx="6" fill="none" stroke="url(#n)" stroke-width="1.5"/>' % [w - 2.8, h - 2.8, w - 2.4, h - 2.4]
	else:
		body += '<rect x=".7" y=".7" width="%.1f" height="%.1f" rx="6.4" fill="none" stroke="#%s" stroke-opacity=".9" stroke-width="1.1"/>' % [w - 1.4, h - 1.4, m.rim]
	body += '<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="4.5" fill="#%s" fill-opacity="%s"/>' % [b, b, w - b * 2, h - b * 2, m.tray, ".85" if theme_id == 5 else "1"]
	body += '<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="4.5" fill="url(#t)"/>' % [b, b, w - b * 2, h - b * 2]
	body += '<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="4.8" fill="none" stroke="#%s" stroke-opacity=".55" stroke-width=".7"/>' % [b - 0.5, b - 0.5, w - b * 2 + 1, h - b * 2 + 1, m.rim if theme_id != 7 else "8e6bff"]
	return svg_texture(key, svg_doc(w, h, body), 4.0)

static func draw_frame(ci: CanvasItem, rect: Rect2, theme_id: int, columns: int = 1, rows: int = 1) -> void:
	var u: float = rect.size.y / 390.0
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0.1, 0.05, 0.02, 0.35)
	shadow.set_corner_radius_all(int(20 * u))
	shadow.shadow_color = Color(0.05, 0.02, 0.0, 0.38)
	shadow.shadow_size = int(maxf(4, 16 * u))
	shadow.shadow_offset = Vector2(0, 8 * u)
	ci.draw_style_box(shadow, Rect2(rect.position + Vector2(2, 6) * u, rect.size - Vector2(4, 6) * u))
	ci.draw_texture_rect(frame_texture(theme_id, columns, rows), rect, false)

static func draw_slot(ci: CanvasItem, rect: Rect2, theme_id: int, radius: float) -> void:
	var m: Dictionary = material(theme_id)
	var slot := StyleBoxFlat.new()
	slot.bg_color = Color(m.tray).darkened(0.16)
	slot.set_corner_radius_all(int(radius))
	slot.border_color = Color(0, 0, 0, 0.28)
	slot.border_width_top = int(maxf(2, radius * 0.28))
	slot.anti_aliasing_size = 0.8
	ci.draw_style_box(slot, rect)
	if theme_id == 7:
		var glow := StyleBoxFlat.new()
		glow.bg_color = Color.TRANSPARENT
		glow.border_color = Color(0.45, 0.4, 1.0, 0.22)
		glow.set_border_width_all(1)
		glow.set_corner_radius_all(int(radius))
		ci.draw_style_box(glow, rect)

static func draw_tile_shadow(ci: CanvasItem, rect: Rect2, radius: float, u: float, strength: float = 1.0) -> void:
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0, 0, 0, 0.0)
	shadow.set_corner_radius_all(int(radius))
	shadow.shadow_color = Color(0.06, 0.03, 0.01, 0.34 * strength)
	shadow.shadow_size = int(maxf(2, 5 * u))
	shadow.shadow_offset = Vector2(0, 3.2 * u)
	ci.draw_style_box(shadow, rect.grow(-1.5 * u))

static func draw_number(ci: CanvasItem, rect: Rect2, theme_id: int, value: int, font: Font, font_size: int, u: float) -> void:
	var m: Dictionary = material(theme_id)
	# The face is slightly shorter than the tile because the lower edge shows the tile side.
	var face_h: float = rect.size.y * 121.0 / 128.0
	var baseline := rect.position + Vector2(0, face_h * 0.5 + font_size * 0.36)
	var label: String = str(value)
	if theme_id == 7:
		ci.draw_string_outline(font, baseline, label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, int(9 * u), Color(0.37, 0.88, 1.0, 0.18))
		ci.draw_string_outline(font, baseline, label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, int(4 * u), Color(0.55, 0.45, 1.0, 0.45))
	elif not str(m.ink_shade).is_empty():
		ci.draw_string(font, baseline + Vector2(0, 1.6 * u), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, Color(m.ink_shade, 0.65))
	ci.draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, Color(m.ink))

# ---------------------------------------------------------------- icons

static func icon(name: String) -> Texture2D:
	var key: String = "icon:" + name
	if cache.has(key):
		return cache[key]
	var body: String = icon_svg(name)
	if body.is_empty():
		return null
	return svg_texture(key, svg_doc(128, 128, body), 1.5)

static func star_path(cx: float, cy: float, outer: float, inner: float) -> String:
	var path: String = ""
	for i in range(10):
		var r: float = outer if i % 2 == 0 else inner
		var angle: float = -PI / 2 + i * PI / 5
		path += ("M" if i == 0 else "L") + "%.2f %.2f" % [cx + cos(angle) * r, cy + sin(angle) * r]
	return path + "Z"

static func rounded_star(cx: float, cy: float, outer: float, fill: String, extra: String = "") -> String:
	return '<path d="%s" fill="%s" stroke="%s" stroke-width="%.1f" stroke-linejoin="round" %s/>' % [star_path(cx, cy, outer, outer * 0.5), fill, fill, outer * 0.16, extra]

static func icon_svg(name: String) -> String:
	match name:
		"trophy":
			return '<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#ffe993"/><stop offset=".45" stop-color="#ffc533"/><stop offset="1" stop-color="#e88a0d"/></linearGradient><linearGradient id="d" x2="0" y2="1"><stop stop-color="#f6ac25"/><stop offset="1" stop-color="#c46a0c"/></linearGradient></defs>' \
				+ '<path d="M36 30H20q-6 0-6 7c0 20 14 30 30 32M92 30h16q6 0 6 7c0 20-14 30-30 32" fill="none" stroke="url(#d)" stroke-width="9" stroke-linecap="round"/>' \
				+ '<path d="M29 16h70v24c0 25-16 42-35 42S29 65 29 40z" fill="url(#g)"/>' \
				+ '<rect x="25" y="11" width="78" height="12" rx="6" fill="#ffdc6a"/>' \
				+ '<path d="M56 79h16l4 17H52z" fill="url(#d)"/><rect x="40" y="94" width="48" height="10" rx="5" fill="#f2a524"/><rect x="33" y="102" width="62" height="15" rx="7" fill="#cf7811"/>' \
				+ rounded_star(64, 47, 17, "#fff6c4") \
				+ '<path d="M38 26c0 18 3 30 11 39" stroke="#ffffff" stroke-opacity=".5" stroke-width="5" stroke-linecap="round" fill="none"/>'
		"calendar", "calendar_star":
			var star: bool = name == "calendar_star"
			var out: String = '<defs><linearGradient id="r" x2="0" y2="1"><stop stop-color="#ff7466"/><stop offset="1" stop-color="#e3392c"/></linearGradient><linearGradient id="w" x2="0" y2="1"><stop stop-color="#ffffff"/><stop offset="1" stop-color="#eef0f5"/></linearGradient></defs>'
			out += '<rect x="13" y="25" width="102" height="92" rx="19" fill="#%s"/>' % ("2c2a33" if star else "c4cad7")
			out += '<rect x="%s" y="%s" width="%s" height="%s" rx="17" fill="url(#w)"/>' % (["17", "21", "94", "90"] if star else ["13", "20", "102", "92"])
			out += '<path d="M%s 40q0-19 19-19h%s q19 0 19 19v8H%sz" fill="url(#r)"/>' % (["17", "56", "17"] if star else ["13", "64", "13"])
			out += '<rect x="35" y="9" width="12" height="25" rx="6" fill="#ffd266" stroke="#7b3c17" stroke-width="3"/><rect x="81" y="9" width="12" height="25" rx="6" fill="#ffd266" stroke="#7b3c17" stroke-width="3"/>'
			if star:
				out += rounded_star(64, 82, 22, "#ffc21f", 'stroke-opacity="1"') + '<path d="%s" fill="#ffe27a"/>' % star_path(61, 78, 9, 4.5)
			else:
				for row in range(2):
					for col in range(4):
						var accent: bool = row == 1 and col == 2
						out += '<rect x="%d" y="%d" width="13" height="13" rx="4" fill="#%s"/>' % [27 + col * 20, 60 + row * 22, "ff5a4d" if accent else "9aa3b6"]
			return out
		"palette":
			var shape: String = "M64 14C35 14 14 35 14 62s20 52 46 52c8 0 12-5 12-10 0-7-6-8-6-15s5-10 12-10h11c15 0 25-10 25-25 0-23-22-40-50-40z"
			return '<defs><linearGradient id="p" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#e9b3ff"/><stop offset="1" stop-color="#8a3dd6"/></linearGradient></defs>' \
				+ '<path d="%s" fill="#5e2399" transform="translate(0 5)"/><path d="%s" fill="url(#p)"/>' % [shape, shape] \
				+ '<circle cx="42" cy="45" r="10" fill="#ff5d6c"/><circle cx="66" cy="32" r="10" fill="#ffd23f"/><circle cx="90" cy="44" r="10" fill="#45d47c"/><circle cx="36" cy="72" r="10" fill="#3fa8ff"/>' \
				+ '<circle cx="39" cy="42" r="3" fill="#ffffff" opacity=".6"/><circle cx="63" cy="29" r="3" fill="#ffffff" opacity=".6"/><circle cx="87" cy="41" r="3" fill="#ffffff" opacity=".6"/><circle cx="33" cy="69" r="3" fill="#ffffff" opacity=".6"/>'
		"gear":
			var teeth: String = ""
			for k in range(8):
				teeth += '<rect x="55" y="11" width="18" height="26" rx="5" transform="rotate(%d 64 64)"/>' % (k * 45)
			return '<defs><linearGradient id="w" x2="0" y2="1"><stop stop-color="#ffffff"/><stop offset="1" stop-color="#dfe3e6"/></linearGradient></defs><g fill="#000000" opacity=".25" transform="translate(0 4)"><circle cx="64" cy="64" r="36"/>%s</g><g fill="url(#w)"><circle cx="64" cy="64" r="36"/>%s</g><circle cx="64" cy="64" r="14" fill="#33413f"/>' % [teeth, teeth]
		"bulb":
			var rays: String = ""
			for angle in [-160, -125, -90, -55, -20]:
				var a: float = deg_to_rad(angle)
				rays += '<path d="M%.1f %.1fL%.1f %.1f" stroke="#ffb428" stroke-width="7" stroke-linecap="round"/>' % [64 + cos(a) * 44, 52 + sin(a) * 44, 64 + cos(a) * 56, 52 + sin(a) * 56]
			return '<defs><radialGradient id="y" cx=".42" cy=".38" r=".7"><stop stop-color="#fffbd1"/><stop offset=".55" stop-color="#ffd84a"/><stop offset="1" stop-color="#f6a412"/></radialGradient></defs>' + rays \
				+ '<path d="M64 22c-18 0-31 13-31 30 0 11 6 19 12 25 4 4 5 8 5 12h28c0-4 1-8 5-12 6-6 12-14 12-25 0-17-13-30-31-30z" fill="url(#y)"/>' \
				+ '<path d="M56 86q0-12 8-16 8 4 8 16" stroke="#e48b0e" stroke-width="3" fill="none"/><ellipse cx="52" cy="40" rx="7" ry="10" fill="#ffffff" opacity=".65" transform="rotate(30 52 40)"/>' \
				+ '<rect x="48" y="89" width="32" height="9" rx="4" fill="#9aa0ae"/><rect x="50" y="97" width="28" height="8" rx="4" fill="#757b8b"/><path d="M56 104h16l-3 7h-10z" fill="#565b68"/>'
		"chart":
			return '<defs><linearGradient id="b" x2="0" y2="1"><stop stop-color="#62b8ff"/><stop offset="1" stop-color="#1667ec"/></linearGradient></defs><rect x="20" y="60" width="24" height="50" rx="6" fill="url(#b)"/><rect x="52" y="20" width="24" height="90" rx="6" fill="url(#b)"/><rect x="84" y="42" width="24" height="68" rx="6" fill="url(#b)"/><rect x="25" y="64" width="5" height="40" rx="2.5" fill="#ffffff" opacity=".35"/><rect x="57" y="24" width="5" height="80" rx="2.5" fill="#ffffff" opacity=".35"/><rect x="89" y="46" width="5" height="58" rx="2.5" fill="#ffffff" opacity=".35"/>'
		"feet", "feet_white":
			var c: String = "#ffffff" if name == "feet_white" else "url(#f)"
			var foot: String = '<ellipse cx="0" cy="16" rx="12.5" ry="22"/><ellipse cx="1" cy="42" rx="10" ry="10"/><circle cx="-9" cy="-11" r="5.4"/><circle cx="-1" cy="-15" r="5"/><circle cx="7" cy="-13" r="4.4"/><circle cx="12.5" cy="-7" r="3.8"/>'
			return '<defs><linearGradient id="f" x2="0" y2="1"><stop stop-color="#3fae86"/><stop offset="1" stop-color="#1e6f55"/></linearGradient></defs><g fill="%s"><g transform="translate(42 48) rotate(-12)">%s</g><g transform="translate(86 62) rotate(12) scale(-1 1)">%s</g></g>' % [c, foot, foot]
		"gift":
			return '<rect x="20" y="52" width="88" height="60" rx="10" fill="#ff9a1f"/><rect x="14" y="38" width="100" height="22" rx="8" fill="#ffbd3a"/><rect x="56" y="38" width="16" height="74" fill="#ea3e2e"/><path d="M64 38c-10-20-34-22-30-8 3 9 20 9 30 8zm0 0c10-20 34-22 30-8-3 9-20 9-30 8z" fill="#ea3e2e"/><rect x="20" y="60" width="88" height="6" fill="#000000" opacity=".1"/>'
		"crown":
			return '<path d="M20 92 14 38l28 22 22-34 22 34 28-22-6 54z" fill="#ffffff" stroke="#ffffff" stroke-width="6" stroke-linejoin="round"/><rect x="20" y="98" width="88" height="12" rx="5" fill="#ffffff"/>'
		"star_white":
			return rounded_star(64, 66, 50, "#ffffff")
		"bolt_white":
			return '<path d="M74 10 26 72h32l-6 46 50-64H70z" fill="#ffffff" stroke="#ffffff" stroke-width="5" stroke-linejoin="round"/>'
		"check_circle":
			return '<circle cx="64" cy="64" r="58" fill="#23b04b"/><circle cx="64" cy="60" r="54" fill="#38c95c"/><path d="M38 64l18 18 35-37" fill="none" stroke="#ffffff" stroke-width="13" stroke-linecap="round" stroke-linejoin="round"/>'
		"sparkle":
			return '<path d="M64 2C69 50 78 59 126 64 78 69 69 78 64 126 59 78 50 69 2 64 50 59 59 50 64 2z" fill="#ffe489"/><path d="M64 30C66 56 72 62 98 64 72 66 66 72 64 98 62 72 56 66 30 64 56 62 62 56 64 30z" fill="#fffbe6"/>'
		"heart":
			return '<path d="M64 112C26 84 8 62 12 40 16 18 44 10 64 34 84 10 112 18 116 40 120 62 102 84 64 112z" fill="#ff7aa0"/><ellipse cx="38" cy="38" rx="10" ry="7" fill="#ffffff" opacity=".55" transform="rotate(-30 38 38)"/>'
		"globe_white":
			return '<circle cx="64" cy="64" r="46" fill="none" stroke="#ffffff" stroke-width="10"/><ellipse cx="64" cy="64" rx="20" ry="46" fill="none" stroke="#ffffff" stroke-width="9"/><path d="M20 50h88M20 78h88" stroke="#ffffff" stroke-width="9"/>'
		"knob":
			return '<circle cx="64" cy="68" r="50" fill="#000000" opacity=".18"/><circle cx="64" cy="62" r="50" fill="#ffffff"/><circle cx="64" cy="62" r="49" fill="none" stroke="#d8cfc0" stroke-width="2"/>'
	return ""

static func laurel(mirror: bool = false) -> Texture2D:
	var key: String = "laurel:%s" % mirror
	if cache.has(key):
		return cache[key]
	var body: String = '<defs><linearGradient id="l" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#a7e07a"/><stop offset="1" stop-color="#3f9a3c"/></linearGradient></defs>'
	var stem: String = "M98 236Q24 170 46 26"
	body += '<path d="%s" fill="none" stroke="#3f8a35" stroke-width="5" stroke-linecap="round"/>' % stem
	for i in range(7):
		var t: float = 0.1 + i * 0.13
		var p0 := Vector2(98, 236)
		var p1 := Vector2(24, 170)
		var p2 := Vector2(46, 26)
		var point: Vector2 = p0.lerp(p1, t).lerp(p1.lerp(p2, t), t)
		var tangent: Vector2 = (p1 - p0).lerp(p2 - p1, t).normalized()
		var angle: float = rad_to_deg(tangent.angle())
		for side in [-1, 1]:
			var leaf_angle: float = angle + side * 40.0
			var offset: Vector2 = Vector2.from_angle(deg_to_rad(leaf_angle)) * 15.0
			body += '<ellipse cx="%.1f" cy="%.1f" rx="16" ry="7.5" fill="url(#l)" transform="rotate(%.1f %.1f %.1f)"/>' % [point.x + offset.x, point.y + offset.y, leaf_angle, point.x + offset.x, point.y + offset.y]
	body += '<ellipse cx="44" cy="22" rx="8" ry="15" fill="url(#l)"/>'
	var svg: String = svg_doc(128, 256, '<g%s>%s</g>' % [' transform="translate(128 0) scale(-1 1)"' if mirror else "", body])
	return svg_texture(key, svg, 2.0)

static func wood_plaque() -> Texture2D:
	var key: String = "plaque"
	if cache.has(key):
		return cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var w: float = 320.0
	var h: float = 92.0
	var body: String = '<defs><linearGradient id="f" x2="0" y2="1"><stop stop-color="#e3a764"/><stop offset=".55" stop-color="#c8833f"/><stop offset="1" stop-color="#a5622a"/></linearGradient><clipPath id="c"><rect y="2" width="320" height="82" rx="16"/></clipPath></defs>'
	body += '<rect y="10" width="320" height="82" rx="16" fill="#5b2f14"/><rect y="6" width="320" height="82" rx="16" fill="#83491f"/>'
	body += '<rect y="2" width="320" height="82" rx="16" fill="url(#f)"/>'
	body += '<g clip-path="url(#c)">%s</g>' % grain_lines(rng, w, h, "6e3a14", "ffe2b0", false, 40)
	body += '<rect x="1.5" y="3.5" width="317" height="79" rx="15" fill="none" stroke="#ffd79c" stroke-opacity=".85" stroke-width="2.4"/>'
	body += '<rect x="7" y="9" width="306" height="68" rx="11" fill="none" stroke="#7a4219" stroke-opacity=".28" stroke-width="1.5"/>'
	return svg_texture(key, svg_doc(w, h, body), 2.0)

static func photo_bevel() -> Texture2D:
	# Light catches the upper-left lip of each photo piece; the lower-right edge falls into shade.
	var body: String = '<defs><linearGradient id="s" x1="0" y1="0" x2=".6" y2="1"><stop stop-color="#ffffff" stop-opacity=".16"/><stop offset=".35" stop-color="#ffffff" stop-opacity="0"/><stop offset=".8" stop-color="#1c0f06" stop-opacity="0"/><stop offset="1" stop-color="#1c0f06" stop-opacity=".16"/></linearGradient><clipPath id="c"><rect width="128" height="128" rx="11.5"/></clipPath></defs>'
	body += '<g clip-path="url(#c)"><rect width="128" height="128" fill="url(#s)"/>'
	body += '<path d="M2.2 116V13Q2.2 2.2 13 2.2h103" fill="none" stroke="#ffffff" stroke-opacity=".22" stroke-width="7" stroke-linecap="round"/>'
	body += '<path d="M1.6 116V13Q1.6 1.6 13 1.6h103" fill="none" stroke="#ffffff" stroke-opacity=".75" stroke-width="1.8" stroke-linecap="round"/>'
	body += '<path d="M12 126.2h103q11.2 0 11.2-11.2V12" fill="none" stroke="#1a0d05" stroke-opacity=".32" stroke-width="5" stroke-linecap="round"/>'
	body += '<path d="M12 126.8h103q11.8 0 11.8-11.8V12" fill="none" stroke="#1a0d05" stroke-opacity=".45" stroke-width="1.4" stroke-linecap="round"/></g>'
	return svg_texture("photo-bevel", svg_doc(128, 128, body), 4.0)
