class_name SlideButton
extends Button

var motion: Tween
var activation_pending: bool = false
var pointer_inside: bool = false
var primary: bool = false
var dark: bool = false
var corner_radius: float = 22.0
var body: ColorRect
var body_material: ShaderMaterial
var was_disabled: bool = false
var show_surface: bool = true
var hover_motion: Tween
var round_button: bool = false

func _ready() -> void:
	body = ColorRect.new()
	body.name = "CandySurface"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.show_behind_parent = true
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = -5
	body.offset_top = -3
	body.offset_right = 5
	body.offset_bottom = 12
	body_material = ShaderMaterial.new()
	body_material.shader = load("res://shaders/candy_button.gdshader")
	body_material.set_shader_parameter("press_depth", 0.0)
	body_material.set_shader_parameter("hover_amount", 0.0)
	body.material = body_material
	body.visible = not flat and show_surface
	add_child(body)
	resized.connect(refresh_surface)
	refresh_surface()
	pivot_offset = size * 0.5
	button_down.connect(press_feedback)
	button_up.connect(release_feedback)
	mouse_entered.connect(func(): pointer_inside = true; if not button_pressed: hover_feedback())
	mouse_exited.connect(func(): pointer_inside = false; if not button_pressed: hover_feedback())
	visibility_changed.connect(func():
		if not visible:
			reset_feedback()
	)

func refresh_surface() -> void:
	pivot_offset = size * 0.5
	if not body_material:
		return
	body_material.set_shader_parameter("control_size", size)
	body_material.set_shader_parameter("corner_radius", corner_radius)
	body_material.set_shader_parameter("round_button", round_button)
	body_material.set_shader_parameter("top_color", Color("46dc30") if primary else (Color("736c5f") if dark else Color("fffdf8")))
	body_material.set_shader_parameter("bottom_color", Color("17b421") if primary else (Color("504a41") if dark else Color("f4efe4")))
	body_material.set_shader_parameter("base_color", Color("188e20") if primary else (Color("39352f") if dark else Color("cbbda6")))
	body_material.set_shader_parameter("disabled_amount", 1.0 if disabled else 0.0)
	was_disabled = disabled

func _process(_delta: float) -> void:
	if was_disabled != disabled:
		refresh_surface()

func animate_to(target: Vector2, duration: float, bounce: bool = false) -> void:
	if motion and motion.is_valid():
		motion.kill()
	if not SlideUI.animations_enabled:
		scale = Vector2.ONE
		if body_material:
			body_material.set_shader_parameter("press_depth", 0.0)
		return
	pivot_offset = size * 0.5
	motion = create_tween()
	if bounce:
		motion.tween_property(self, "scale", Vector2.ONE * 1.022, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		motion.tween_property(self, "scale", target, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if body_material:
		var depth: float = 1.0 if target.x < 1.0 else 0.0
		motion.parallel().tween_method(func(value): body_material.set_shader_parameter("press_depth", value), float(body_material.get_shader_parameter("press_depth")), depth, 0.10)
	if bounce:
		motion.chain().tween_property(self, "scale", target, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func press_feedback() -> void:
	if disabled:
		return
	animate_to(Vector2.ONE * 0.965, 0.075)
	if SlideUI.click_feedback.is_valid():
		SlideUI.click_feedback.call()

func release_feedback() -> void:
	if disabled:
		reset_feedback()
		return
	animate_to(Vector2.ONE, 0.2, true)

func hover_feedback() -> void:
	if disabled or activation_pending:
		return
	animate_to(Vector2.ONE * (1.015 if pointer_inside else 1.0), 0.13)
	if body_material:
		if hover_motion and hover_motion.is_valid():
			hover_motion.kill()
		var target: float = 1.0 if pointer_inside else 0.0
		if SlideUI.animations_enabled:
			hover_motion = create_tween()
			hover_motion.tween_method(func(value): body_material.set_shader_parameter("hover_amount", value), float(body_material.get_shader_parameter("hover_amount")), target, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		else:
			body_material.set_shader_parameter("hover_amount", target)

func reset_feedback() -> void:
	if motion and motion.is_valid():
		motion.kill()
	scale = Vector2.ONE
	if body_material:
		body_material.set_shader_parameter("press_depth", 0.0)

func activate(callback: Callable) -> void:
	if activation_pending or disabled:
		return
	activation_pending = true
	# Let the release spring become visible before navigation removes this page.
	if SlideUI.animations_enabled:
		await get_tree().create_timer(0.065).timeout
	if is_inside_tree() and not disabled:
		activation_pending = false
		callback.call()
	else:
		activation_pending = false
