extends StaticBody2D

var stored_coal: int = 0
var stored_iron: int = 0
var stored_gold: int = 0
var player_inside: bool = false

var stored_load: int:
	get: return get_total_stored()

@onready var sprite = $Sprite2D
@onready var prompt_label = $PromptLabel
@onready var player_detect = $InteractArea

func _ready() -> void:
	if has_node("/root/SaveManager") and SaveManager.has_loaded_save:
		stored_coal = SaveManager.chest_saved_coal
		stored_iron = SaveManager.chest_saved_iron
		stored_gold = SaveManager.chest_saved_gold
	if prompt_label:
		prompt_label.text = "[X] Abrir Baú"
		prompt_label.modulate.a = 0.0
		prompt_label.visible = false
	if player_detect:
		if not player_detect.body_entered.is_connected(_on_player_entered):
			player_detect.body_entered.connect(_on_player_entered)
		if not player_detect.body_exited.is_connected(_on_player_exited):
			player_detect.body_exited.connect(_on_player_exited)
	update_visuals()

func update_visuals() -> void:
	if sprite:
		sprite.frame = 32 # Always open/accessible style
	if prompt_label and prompt_label.visible:
		prompt_label.text = "[X] Abrir Baú"

func _on_player_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_inside = true
		if prompt_label:
			prompt_label.text = "[X] Abrir Baú"
			prompt_label.visible = true
			var tween = create_tween()
			tween.tween_property(prompt_label, "modulate:a", 1.0, 0.2)

func _on_player_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_inside = false
		if prompt_label:
			var tween = create_tween()
			tween.tween_property(prompt_label, "modulate:a", 0.0, 0.2)
			tween.tween_callback(prompt_label.hide)
		var hud = _get_hud()
		if hud and hud.has_method("close_chest"):
			hud.close_chest()

func _unhandled_input(event: InputEvent) -> void:
	if player_inside:
		if event.is_action_pressed("action_drag") or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_X):
			interact()
			if is_inside_tree() and get_viewport():
				get_viewport().set_input_as_handled()

func interact() -> void:
	var hud = _get_hud()
	if hud and hud.has_method("open_chest"):
		hud.open_chest(self)

func _get_hud() -> Node:
	if is_inside_tree() and get_tree() and get_tree().current_scene:
		return get_tree().current_scene.get_node_or_null("HUD")
	return null

func deposit_resources() -> int:
	var inv = get_node_or_null("/root/Inventory")
	if not inv: return 0
	
	var count = 0
	if inv.coal > 0:
		stored_coal += inv.coal
		count += inv.coal
		inv.coal = 0
	if inv.iron > 0:
		stored_iron += inv.iron
		count += inv.iron
		inv.iron = 0
	if inv.gold > 0:
		stored_gold += inv.gold
		count += inv.gold
		inv.gold = 0
		
	if count > 0:
		inv.inventory_changed.emit()
		inv.notify("Guardou %d minérios no Baú!" % count, "chest")
		if has_node("/root/SaveManager"):
			SaveManager.request_save()
	else:
		inv.notify("Nenhum recurso na mochila para guardar.", "chest")
		
	update_visuals()
	return count

func retrieve_resources() -> int:
	var inv = get_node_or_null("/root/Inventory")
	if not inv: return 0
	
	if get_total_stored() <= 0:
		inv.notify("O Baú está vazio!", "chest")
		return 0
		
	var retrieved = 0
	# Prioritize retrieving gold, then iron, then coal as capacity allows
	while stored_gold > 0 and inv.can_add(1):
		stored_gold -= 1
		inv.gold += 1
		retrieved += 1
	while stored_iron > 0 and inv.can_add(0):
		stored_iron -= 1
		inv.iron += 1
		retrieved += 1
	while stored_coal > 0 and inv.can_add(2):
		stored_coal -= 1
		inv.coal += 1
		retrieved += 1
		
	if retrieved > 0:
		inv.inventory_changed.emit()
		inv.notify("Retirou %d minérios do Baú!" % retrieved, "chest")
		if has_node("/root/SaveManager"):
			SaveManager.request_save()
	else:
		inv.notify("Mochila cheia! Não há espaço para retirar itens.", "chest")
		
	update_visuals()
	return retrieved

func get_total_stored() -> int:
	return stored_coal + stored_iron + stored_gold

func is_chest() -> bool:
	return true
