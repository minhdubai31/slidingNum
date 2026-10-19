class_name SlideSwitch
extends Button

# A pill toggle whose knob glides between states.

const ON = Color("34c759")
const OFF = Color("d9d0c2")
var knob: float = 0.0
var slide: Tween

func _init() -> void:
	toggle_mode = true
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(54, 32)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())

func _ready() -> void:
	knob = 1.0 if button_pressed else 0.0
	toggled.connect(func(value: bool):
		if slide and slide.is_valid():
			slide.kill()
		if SlideUI.click_feedback.is_valid():
			SlideUI.click_feedback.call()
		if not SlideUI.animations_enabled:
			knob = 1.0 if value else 0.0
			queue_redraw()
			return
		slide = create_tween()
		slide.tween_method(func(v: float): knob = v; queue_redraw(), knob, 1.0 if value else 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)

func _draw() -> void:
	var track := Rect2(Vector2(0, (size.y - 30) * 0.5), Vector2(size.x, 30))
	var style := StyleBoxFlat.new()
	style.bg_color = OFF.lerp(ON, clampf(knob, 0, 1))
	style.set_corner_radius_all(15)
	style.border_color = Color(0, 0, 0, 0.08)
	style.border_width_top = 2
	draw_style_box(style, track)
	var diameter: float = 26.0
	var x: float = lerpf(track.position.x + 2, track.end.x - diameter - 2, knob)
	var stretch: float = 1.0 + (1.0 - absf(knob * 2.0 - 1.0)) * 0.12
	var knob_rect := Rect2(Vector2(x, track.position.y + 2), Vector2(diameter * stretch, diameter))
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0, 0, 0, 0.0)
	shadow.set_corner_radius_all(13)
	shadow.shadow_color = Color(0, 0, 0, 0.22)
	shadow.shadow_size = 3
	shadow.shadow_offset = Vector2(0, 2)
	draw_style_box(shadow, knob_rect)
	var face := StyleBoxFlat.new()
	face.bg_color = Color.WHITE
	face.set_corner_radius_all(13)
	draw_style_box(face, knob_rect)
