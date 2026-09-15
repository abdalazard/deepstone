extends CanvasLayer

# ─── Mobile Virtual Controls ───────────────────────────────────────────────
# Joystick esquerdo: movimento + subir/descer escada
# Botões direita: Pulo, Minerar, Coletar, Arrastar
# Botões topo: Inventário, Equipamentos, Próx. slot
# ───────────────────────────────────────────────────────────────────────────

const JOY_RADIUS     := 72.0
const JOY_KNOB_R     := 28.0
const DEADZONE       := 16.0
const BTN_SIZE       := 64.0
const BTN_SIZE_BIG   := 80.0

# ── Touch tracking ──
var _joy_finger   : int = -1
var _joy_center   : Vector2
var _joy_origin   : Vector2   # posição fixa do joystick

var _btn_fingers  : Dictionary = {}  # action_name -> finger_id
var _btn_rects    : Dictionary = {}  # action_name -> Rect2 (em coords de viewport)

# ── Nodes ──
var _joy_base  : Control
var _joy_knob  : Control
var _labels    : Dictionary = {}

# ── Actions atualmente pressionadas por este script ──
var _pressed   : Dictionary = {}

func _ready() -> void:
	if not _should_show():
		queue_free()
		return
	layer = 10
	_build_ui()

func _should_show() -> bool:
	return DisplayServer.is_touchscreen_available() \
		or OS.has_feature("mobile") \
		or OS.has_feature("web_android") \
		or OS.has_feature("web_ios")

# ─────────────────────────── BUILD UI ──────────────────────────────────────

func _build_ui() -> void:
	var vp := get_viewport().get_visible_rect().size

	# Fundo semitransparente dos botões (para debug/visualização)
	# Joystick base — canto inferior esquerdo
	_joy_origin = Vector2(vp.x * 0.15, vp.y * 0.78)
	_joy_center = _joy_origin

	_joy_base = _make_circle_control(_joy_origin, JOY_RADIUS, Color(1,1,1,0.12))
	add_child(_joy_base)

	_joy_knob = _make_circle_control(_joy_origin, JOY_KNOB_R, Color(1,1,1,0.35))
	add_child(_joy_knob)

	# ── Botões principais (direita) ──────────────────────────────────────
	var bx := vp.x * 0.88
	var by := vp.y * 0.72

	# Jump — grande, topo direito do cluster
	_add_btn("ui_up",        Vector2(bx, by - 72),  BTN_SIZE_BIG, "↑", Color(0.3,0.6,1,0.7))
	# Mine  — ação primária
	_add_btn("action_mine",  Vector2(bx - 72, by),  BTN_SIZE,     "⛏", Color(0.9,0.6,0.1,0.75))
	# Collect
	_add_btn("action_collect",Vector2(bx + 72, by), BTN_SIZE,     "⬆", Color(0.2,0.8,0.4,0.7))
	# Drag/Kick
	_add_btn("action_drag",  Vector2(bx, by + 8),   BTN_SIZE,     "👊", Color(0.8,0.3,0.3,0.7))

	# ── Botões de UI (topo, menores) ────────────────────────────────────
	var sm := 48.0
	_add_btn("action_inventory",  Vector2(vp.x * 0.80, 28), sm, "🎒", Color(0.5,0.4,0.8,0.7))
	_add_btn("action_equip_menu", Vector2(vp.x * 0.87, 28), sm, "🛡", Color(0.4,0.6,0.5,0.7))
	_add_btn("action_pause",      Vector2(vp.x * 0.94, 28), sm, "⏸", Color(0.5,0.5,0.5,0.65))

	# Prev / Next slot (ciclo de hotbar)
	_add_btn("_slot_prev", Vector2(vp.x * 0.44, vp.y * 0.04), sm, "◀", Color(0.4,0.4,0.4,0.6))
	_add_btn("_slot_next", Vector2(vp.x * 0.56, vp.y * 0.04), sm, "▶", Color(0.4,0.4,0.4,0.6))

	# Botão Down (escada / agachar) — pequeno, abaixo do joystick
	_add_btn("ui_down", Vector2(_joy_origin.x, _joy_origin.y + JOY_RADIUS + 24), sm, "▼", Color(0.6,0.6,0.6,0.55))

# ─────────────────────────── INPUT ─────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)

func _on_touch(ev: InputEventScreenTouch) -> void:
	var pos := ev.position
	if ev.pressed:
		# Joystick?
		if _joy_finger < 0 and _dist(pos, _joy_origin) <= JOY_RADIUS * 1.5:
			_joy_finger = ev.index
			_joy_center = _joy_origin
			return
		# Botões?
		for action in _btn_rects:
			if _btn_rects[action].has_point(pos) and not _btn_fingers.has(action):
				_btn_fingers[action] = ev.index
				_press_action(action)
				return
	else:
		# Soltou joystick?
		if ev.index == _joy_finger:
			_joy_finger = -1
			_joy_center = _joy_origin
			_joy_knob.position = _joy_origin - Vector2(JOY_KNOB_R, JOY_KNOB_R)
			_release_joy()
			return
		# Soltou botão?
		for action in _btn_fingers.keys():
			if _btn_fingers[action] == ev.index:
				_btn_fingers.erase(action)
				_release_action(action)
				return

func _on_drag(ev: InputEventScreenDrag) -> void:
	if ev.index != _joy_finger:
		return
	var delta := ev.position - _joy_center
	var dist  := delta.length()
	if dist > JOY_RADIUS:
		delta = delta.normalized() * JOY_RADIUS
	_joy_knob.position = (_joy_center + delta) - Vector2(JOY_KNOB_R, JOY_KNOB_R)

	# ── Horizontal ──
	if delta.x < -DEADZONE:
		_set_action("ui_left",  true);  _set_action("ui_right", false)
	elif delta.x > DEADZONE:
		_set_action("ui_right", true);  _set_action("ui_left",  false)
	else:
		_set_action("ui_left",  false); _set_action("ui_right", false)

	# ── Vertical ──
	if delta.y < -DEADZONE:
		_set_action("ui_up",   true);  _set_action("ui_down", false)
	elif delta.y > DEADZONE:
		_set_action("ui_down", true);  _set_action("ui_up",   false)
	else:
		_set_action("ui_up",   false); _set_action("ui_down", false)

func _release_joy() -> void:
	for a in ["ui_left","ui_right","ui_up","ui_down"]:
		_set_action(a, false)

# ─────────────────────────── ACTION HELPERS ────────────────────────────────

func _press_action(action: String) -> void:
	if action == "_slot_prev":
		_cycle_slot(-1); return
	if action == "_slot_next":
		_cycle_slot(1);  return
	_set_action(action, true)
	# Botões que são "just_pressed": soltar no próximo frame
	if action in ["action_mine","action_collect","action_drag","action_inventory","action_equip_menu","action_pause"]:
		await get_tree().process_frame
		await get_tree().process_frame
		_set_action(action, false)
		if _btn_fingers.has(action):
			_btn_fingers.erase(action)

func _release_action(action: String) -> void:
	if action in ["_slot_prev","_slot_next"]: return
	_set_action(action, false)

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

func _cycle_slot(dir: int) -> void:
	# Aciona action_cycle_slot ou slot_X diretamente
	var inv_node := get_tree().root.get_node_or_null("Inventory")
	if inv_node and inv_node.has_method("get_active_slot_index"):
		var cur : int = inv_node.get_active_slot_index()
		var next : int = wrapi(cur + dir, 0, 5)
		var slot_action := "slot_%d" % (next + 1)
		if InputMap.has_action(slot_action):
			Input.action_press(slot_action)
			await get_tree().process_frame
			Input.action_release(slot_action)
	else:
		# Fallback: cycle_slot toggle
		Input.action_press("action_cycle_slot")
		await get_tree().process_frame
		Input.action_release("action_cycle_slot")

# ─────────────────────────── UI HELPERS ────────────────────────────────────

func _add_btn(action: String, center: Vector2, size: float, label: String, color: Color) -> void:
	var half := size * 0.5
	var rect  := Rect2(center - Vector2(half, half), Vector2(size, size))
	_btn_rects[action] = rect

	var ctrl := ColorRect.new()
	ctrl.color = color
	ctrl.size  = Vector2(size, size)
	ctrl.position = rect.position
	# Cantos arredondados via shader
	ctrl.material = _rounded_material(size * 0.5)
	add_child(ctrl)

	var lbl := Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_font_size_override("font_size", int(size * 0.38))
	ctrl.add_child(lbl)
	_labels[action] = lbl

func _make_circle_control(center: Vector2, radius: float, color: Color) -> Control:
	var ctrl := ColorRect.new()
	ctrl.color    = color
	ctrl.size     = Vector2(radius * 2, radius * 2)
	ctrl.position = center - Vector2(radius, radius)
	ctrl.material = _rounded_material(radius)
	return ctrl

func _rounded_material(radius: float) -> ShaderMaterial:
	var mat  := ShaderMaterial.new()
	var shdr := Shader.new()
	shdr.code = """
shader_type canvas_item;
uniform float radius : hint_range(0,512) = 32.0;
void fragment() {
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	vec2 uv = UV * size;
	vec2 center = size * 0.5;
	vec2 d = abs(uv - center) - (center - vec2(radius));
	float dist = length(max(d, vec2(0.0))) - radius;
	float alpha = 1.0 - smoothstep(-1.0, 1.0, dist);
	COLOR.a *= alpha;
}
"""
	mat.shader = shdr
	mat.set_shader_parameter("radius", radius)
	return mat

func _dist(a: Vector2, b: Vector2) -> float:
	return (a - b).length()
