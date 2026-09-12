extends Node

signal inventory_changed
signal notification_triggered(text: String, icon_type: String)

const MAX_STACK: int = 20
const MAX_CAPACITY: int = 60 # Capacidade total de minérios (Ferro + Ouro + Carvão)
var iron: int = 0
var gold: int = 0
var coal: int = 0
var signs: int = 10 # Mini-poste / lamp
var starter_lamps: int = 1 # 1 lanterna inicial grátis
var planks: int = 15 # Tábuas de madeira
var active_slot: int = 0 # 0=Pickaxe, 1=Lamp, 2=Escada, 3=Tábua

func get_available_lamps() -> int:
	return starter_lamps + min(coal / 3, iron / 2)

func can_place_lamp() -> bool:
	return get_available_lamps() > 0

func consume_lamp() -> bool:
	if starter_lamps > 0:
		starter_lamps -= 1
		inventory_changed.emit()
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	elif coal >= 3 and iron >= 2:
		coal -= 3
		iron -= 2
		inventory_changed.emit()
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	return false

func add_starter_lamp(amount: int = 1) -> void:
	starter_lamps += amount
	inventory_changed.emit()
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").request_save()

func notify(text: String, icon_type: String = "") -> void:
	notification_triggered.emit(text, icon_type)

func get_total_used() -> int:
	return iron + gold + coal

func get_total_available() -> int:
	return max(0, MAX_CAPACITY - get_total_used())

func is_full() -> bool:
	return get_total_used() >= MAX_CAPACITY

func can_add(type: int) -> bool:
	if is_full(): return false
	if type == 0: return iron < MAX_STACK
	if type == 1: return gold < MAX_STACK
	if type == 2: return coal < MAX_STACK
	return false

func add_resource(type: int, amount: int) -> void:
	var space = get_total_available()
	if space <= 0:
		notify("Mochila Cheia! Guarde no Baú", "chest")
		return
		
	if type == 0:
		var added = min(amount, min(MAX_STACK - iron, space))
		iron += added
		if added > 0:
			notify("+%d Minério de Ferro" % added, "iron")
	elif type == 1:
		var added = min(amount, min(MAX_STACK - gold, space))
		gold += added
		if added > 0:
			notify("+%d Minério de Ouro" % added, "gold")
	elif type == 2:
		var added = min(amount, min(MAX_STACK - coal, space))
		coal += added
		if added > 0:
			notify("+%d Carvão Mineral" % added, "coal")
	inventory_changed.emit()
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").request_save()

func remove_all() -> Dictionary:
	var dropped = {"iron": iron, "gold": gold, "coal": coal}
	iron = 0
	gold = 0
	coal = 0
	inventory_changed.emit()
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").request_save()
	return dropped

func get_active_item_name() -> String:
	match active_slot:
		0: return "Picareta"
		1: return "Lâmpada"
		2: return "Escada"
		3: return "Tábua"
		_: return ""

func drop_item(item_key: String, amount: int = 1) -> int:
	var tree = get_tree()
	var player = tree.current_scene.get_node_or_null("Player") if tree and tree.current_scene else null
	var drop_pos = player.global_position if is_instance_valid(player) else Vector2(500, 100)
	
	var drop_scene = load("res://scenes/items/resource_drop.tscn")
	if not drop_scene: return 0
	
	var drop = drop_scene.instantiate()
	var dropped_amount = 0
	
	if item_key == "iron" and iron >= amount:
		iron -= amount
		drop.type = 0 # IRON
		dropped_amount = amount
	elif item_key == "gold" and gold >= amount:
		gold -= amount
		drop.type = 1 # GOLD
		dropped_amount = amount
	elif item_key == "coal" and coal >= amount:
		coal -= amount
		drop.type = 2 # COAL
		dropped_amount = amount
	elif (item_key == "plank" or item_key == "planks") and planks >= amount:
		planks -= amount
		drop.type = 3 # PLANK
		dropped_amount = amount
	elif (item_key == "lamp" or item_key == "signs"):
		if starter_lamps >= amount:
			starter_lamps -= amount
			drop.type = 4 # LAMP
			dropped_amount = amount
		elif signs >= amount:
			signs -= amount
			drop.type = 4 # LAMP
			dropped_amount = amount
		elif coal >= 3 * amount and iron >= 2 * amount:
			coal -= 3 * amount
			iron -= 2 * amount
			drop.type = 4 # LAMP
			dropped_amount = amount
		
	if dropped_amount > 0:
		drop.is_player_drop = true
		drop.global_position = drop_pos + Vector2(randf_range(-20, 20), -12)
		var target_parent = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
		if target_parent:
			target_parent.add_child(drop)
		inventory_changed.emit()
		notify("Item solto no mapa!", item_key)
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return dropped_amount
	return 0

