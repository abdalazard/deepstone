extends CanvasLayer

# ─────────────── Mobile Controls ───────────────────────────────────────────
# Joystick flutuante + botões Z/X/C + DWN + PULO
# Slots do hotbar são tratados diretamente no hud.gd via touch
# ───────────────────────────────────────────────────────────────────────────

const JOY_RADIUS  := 70.0
const JOY_KNOB_R  := 26.0
const DEADZONE    := 18.0

var _joy_panel    : Panel
var _joy_draw     : Node2D
var _joy_origin   : Vector2
var _joy_active   : bool = false
var _joy_knob_pos : Vector2
var _pressed      : Dictionary = {}

func _ready() -> void:
	if not _should_show():
		queue_free()
		return
	layer = 10
	_build_ui()

func _should_show() -> bool:
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	if DisplayServer.is_touchscreen_available():
		return true
	if OS.has_feature("web"):
		var has_touch = JavaScriptBridge.eval("('ontouchstart' in window) || (navigator.maxTouchPoints > 0)", true)
		if has_touch:
			return true
	return false

# ─────────────────────────── BUILD ─────────────────────────────────────────

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var vw := 1280.0
	var vh := 720.0

	# ── Joystick panel (esquerda inferior, 40% × 55%) ──────────────────────
	var joy_panel := Panel.new()
	joy_panel.position = Vector2(0, vh * 0.45)
	joy_panel.size     = Vector2(vw * 0.40, vh * 0.55)
	joy_panel.self_modulate = Color(1, 1, 1, 0.0)
	joy_panel.gui_input.connect(_on_joy_gui_input)
	root.add_child(joy_panel)
	_joy_panel = joy_panel

	var jdraw := Node2D.new()
	jdraw.draw.connect(_draw_joystick)
	joy_panel.add_child(jdraw)
	_joy_draw = jdraw
	_joy_origin   = joy_panel.size * 0.5
	_joy_knob_pos = _joy_origin

	# Anel-guia transparente
	var hint := ColorRect.new()
	var hr := JOY_RADIUS
	hint.size     = Vector2(hr * 2, hr * 2)
	hint.position = Vector2(_joy_origin.x - hr, _joy_origin.y - hr)
	hint.color    = Color(1, 1, 1, 0.07)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joy_panel.add_child(hint)

	# ── Botão DWN (abaixar/agachar) ────────────────────────────────────────
	var joy_cx := vw * 0.12
	var joy_cy := vh * 0.72 + JOY_RADIUS + 28.0
	_add_hold_btn(root, "DWN", Vector2(joy_cx, joy_cy), 48.0, "ui_down",
		Color(0.5, 0.5, 0.5, 0.55))

	# ── Botão PULO ──────────────────────────────────────────────────────────
	var bx := vw * 0.865
	var by := vh * 0.68
	_add_pulse_btn(root, "PULO", Vector2(bx, by - 90.0), 80.0, "ui_up",
		Color(0.3, 0.55, 1.0, 0.75))

	# ── Z = Pick (action_mine) ──────────────────────────────────────────────
	_add_pulse_btn(root, "Z\nPick", Vector2(bx - 85.0, by + 10.0), 66.0, "action_mine",
		Color(0.9, 0.6, 0.1, 0.78))

	# ── X = Interagir/Chutar (action_drag) ─────────────────────────────────
	_add_hold_btn(root, "X\nKick", Vector2(bx + 85.0, by + 10.0), 66.0, "action_drag",
		Color(0.75, 0.3, 0.3, 0.75))

	# ── C = Coletar (action_collect) ────────────────────────────────────────
	_add_pulse_btn(root, "C\nCol", Vector2(bx, by + 10.0), 66.0, "action_collect",
		Color(0.25, 0.75, 0.35, 0.78))

# ─────────────────────────── JOYSTICK ──────────────────────────────────────

func _on_joy_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_joy_active   = true
			_joy_origin   = event.position
			_joy_knob_pos = event.position
			_joy_draw.queue_redraw()
		else:
			_joy_active   = false
			_joy_origin   = _joy_panel.size * 0.5
			_joy_knob_pos = _joy_origin
			_joy_draw.queue_redraw()
			_release_joy()
	elif event is InputEventScreenDrag and _joy_active:
		var delta: Vector2 = event.position - _joy_origin
		var dist: float    = delta.length()
		if dist > JOY_RADIUS:
			delta = delta.normalized() * JOY_RADIUS
		_joy_knob_pos = _joy_origin + delta
		_joy_draw.queue_redraw()
		_update_joy(delta)

func _draw_joystick() -> void:
	_joy_draw.draw_circle(_joy_origin, JOY_RADIUS, Color(1, 1, 1, 0.14))
	_joy_draw.draw_arc(_joy_origin, JOY_RADIUS, 0.0, TAU, 48,
		Color(0.8, 0.8, 0.8, 0.35), 2.0)
	var kc := Color(1, 1, 1, 0.55) if _joy_active else Color(0.7, 0.7, 0.7, 0.25)
	_joy_draw.draw_circle(_joy_knob_pos, JOY_KNOB_R, kc)

func _update_joy(delta: Vector2) -> void:
	if delta.x < -DEADZONE:
		_set_action("ui_left", true);  _set_action("ui_right", false)
	elif delta.x > DEADZONE:
		_set_action("ui_right", true); _set_action("ui_left", false)
	else:
		_set_action("ui_left", false); _set_action("ui_right", false)

	if delta.y < -DEADZONE:
		_set_action("ui_up", true);   _set_action("ui_down", false)
	elif delta.y > DEADZONE:
		_set_action("ui_down", true); _set_action("ui_up", false)
	else:
		_set_action("ui_up", false);  _set_action("ui_down", false)

func _release_joy() -> void:
	for a in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		_set_action(a, false)

# ─────────────────────────── BOTÕES ────────────────────────────────────────

func _add_hold_btn(parent, label, center, size, action, color) -> void:
	var btn := _make_btn(parent, label, center, size, color)
	btn.button_down.connect(func(): _set_action(action, true))
	btn.button_up.connect(func():   _set_action(action, false))

func _add_pulse_btn(parent, label, center, size, action, color) -> void:
	var btn := _make_btn(parent, label, center, size, color)
	btn.button_down.connect(func(): _pulse(action))

func _make_btn(parent, label, center, size, color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.size = Vector2(size, size)
	btn.position = center - Vector2(size * 0.5, size * 0.5)

	var sn := StyleBoxFlat.new()
	sn.bg_color = color
	sn.corner_radius_top_left    = int(size * 0.4)
	sn.corner_radius_top_right   = int(size * 0.4)
	sn.corner_radius_bottom_left = int(size * 0.4)
	sn.corner_radius_bottom_right= int(size * 0.4)
	var sp := sn.duplicate() as StyleBoxFlat
	sp.bg_color = color.lightened(0.25)

	btn.add_theme_stylebox_override("normal",  sn)
	btn.add_theme_stylebox_override("hover",   sn)
	btn.add_theme_stylebox_override("pressed", sp)
	btn.add_theme_stylebox_override("focus",   sn)
	btn.add_theme_font_size_override("font_size", int(size * 0.24))
	btn.add_theme_color_override("font_color",         Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))

	parent.add_child(btn)
	return btn

# ─────────────────────────── HELPERS ───────────────────────────────────────

func _pulse(action: String) -> void:
	if not InputMap.has_action(action): return
	Input.action_press(action)
	_pressed[action] = true
	get_tree().create_timer(0.05).timeout.connect(func():
		if _pressed.get(action, false):
			Input.action_release(action)
			_pressed[action] = false
	)

func _set_action(action: String, pressed: bool) -> void:
	if not InputMap.has_action(action): return
	if pressed:
		if not _pressed.get(action, false):
			Input.action_press(action)
			_pressed[action] = true
	else:
		if _pressed.get(action, false):
			Input.action_release(action)
			_pressed[action] = false
