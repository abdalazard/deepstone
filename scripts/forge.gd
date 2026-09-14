extends StaticBody2D

@onready var prompt_label: Label = $PromptLabel
@onready var fire_light: PointLight2D = $PointLight2D
@onready var interact_area: Area2D = $InteractArea

var player_in_range: bool = false
var base_energy: float = 0.8
var flicker_timer: float = 0.0

func _ready() -> void:
	if prompt_label:
		prompt_label.modulate.a = 0.0
		prompt_label.visible = false
		prompt_label.text = "[Z/X] Usar Forja"
	if interact_area:
		if not interact_area.body_entered.is_connected(_on_body_entered):
			interact_area.body_entered.connect(_on_body_entered)
		if not interact_area.body_exited.is_connected(_on_body_exited):
			interact_area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	# Subtle flame flicker effect
	flicker_timer += delta * 8.0
	if fire_light:
		fire_light.energy = base_energy + sin(flicker_timer) * 0.12 + randf_range(-0.04, 0.04)

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and (
		event.is_action_pressed("action_drag")
		or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_X)
	):
		var hud = _get_hud()
		if hud and hud.has_method("toggle_forge"):
			hud.toggle_forge(self)
			if get_viewport(): get_viewport().set_input_as_handled()

func hit() -> void:
	_break_forge()

func _break_forge() -> void:
	var hud = _get_hud()
	if hud and hud.has_method("close_forge"):
		hud.close_forge()
	
	var inv = _get_inv()
	if inv:
		inv.stone = min(inv.stone + 2, inv.get_max_capacity())
		inv.dirt = min(inv.dirt + 2, inv.get_max_capacity())
		inv.iron = min(inv.iron + 1, inv.get_max_capacity())
		inv.inventory_changed.emit()
		inv.notify("+2 Pedra, +2 Lama, +1 Ferro (Forja Desmontada)", "forge")
	
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("SaveManager"):
		get_tree().root.get_node("SaveManager").request_save()
	
	queue_free()

func _get_inv() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("Inventory"):
		return get_tree().root.get_node("Inventory")
	return null

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true
			var tween = create_tween()
			tween.tween_property(prompt_label, "modulate:a", 1.0, 0.2)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false
		if prompt_label:
			var tween = create_tween()
			tween.tween_property(prompt_label, "modulate:a", 0.0, 0.2)
			tween.tween_callback(prompt_label.hide)
		var hud = _get_hud()
		if hud and hud.has_method("close_forge"):
			hud.close_forge()

func _get_hud() -> Node:
	if is_inside_tree() and get_tree() and get_tree().current_scene:
		return get_tree().current_scene.get_node_or_null("HUD")
	return null
