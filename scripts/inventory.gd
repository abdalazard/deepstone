extends Node

signal inventory_changed
signal notification_triggered(text: String, icon_type: String)
signal level_up(new_level: int, exp_needed_next: int)

const MAX_STACK: int = 20
const MAX_CAPACITY: int = 60 # Capacidade total de minérios (Ferro + Ouro + Carvão)
var iron: int = 0
var gold: int = 0
var coal: int = 0
var coins: int = 0 # Moedas obtidas na loja
var signs: int = 10 # Mini-poste / lamp
var starter_lamps: int = 1 # 1 lanterna inicial grátis (forja exclusiva para novas)
var wood_logs: int = 0 # Troncos de madeira obtidos de árvores
var ladders: int = 0 # Escadas de madeira forjadas (1 tronco -> 5 escadas)
var planks: int = 0 # Tábuas de madeira forjadas (1 tronco -> 5 tábuas)
var dirt: int = 0 # Lama/Terra obtida de escavação
var stone: int = 0 # Pedra obtida de escavação
var brick_floors: int = 0 # Pisos de tijolo forjados (1 lama + 1 pedra)
var level: int = 0 # Começa no nível zero
var current_exp: int = 0 # EXP acumulada no nível atual
var active_slot: int = 0 # 0=Pickaxe, 1=Lamp, 2=Escada, 3=Tábua

const COAL_PRICE: int = 5
const IRON_PRICE: int = 15
const GOLD_PRICE: int = 50

func get_exp_required_for_level(lvl: int) -> int:
	return 100 + lvl * 70

func get_current_level_max_exp() -> int:
	return get_exp_required_for_level(level)

func add_exp(amount: int) -> void:
	if amount <= 0: return
	current_exp += amount
	var req = get_exp_required_for_level(level)
	while current_exp >= req:
		current_exp -= req
		level += 1
		req = get_exp_required_for_level(level)
		level_up.emit(level, req)
		notify("Nível %d Alcançado!" % level, "coin_gold")
	inventory_changed.emit()
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").request_save()

func add_coins(amount: int) -> void:
	coins += amount
	inventory_changed.emit()
	notify("+%d Moedas de Ouro!" % amount, "coin_gold")
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").request_save()

func sell_resource(key: String, amount: int = 1) -> int:
	var earned = 0
	var exp_gain = 0
	if key == "coal" and coal >= amount:
		coal -= amount
		earned = amount * COAL_PRICE
		exp_gain = amount * 2
	elif key == "iron" and iron >= amount:
		iron -= amount
		earned = amount * IRON_PRICE
		exp_gain = amount * 5
	elif key == "gold" and gold >= amount:
		gold -= amount
		earned = amount * GOLD_PRICE
		exp_gain = amount * 15
		
	if earned > 0:
		coins += earned
		if exp_gain > 0:
			add_exp(exp_gain)
		inventory_changed.emit()
		notify("+%d Moedas de Ouro!" % earned, "coin_gold")
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
	return earned

func sell_all_resource(key: String) -> int:
	var count = 0
	if key == "coal": count = coal
	elif key == "iron": count = iron
	elif key == "gold": count = gold
	if count > 0:
		return sell_resource(key, count)
	return 0

func sell_all_minerals() -> int:
	var total_earned = 0
	total_earned += sell_all_resource("coal")
	total_earned += sell_all_resource("iron")
	total_earned += sell_all_resource("gold")
	return total_earned

func get_available_lamps() -> int:
	return starter_lamps

func can_place_lamp() -> bool:
	return starter_lamps > 0

func consume_lamp() -> bool:
	if starter_lamps > 0:
		starter_lamps -= 1
		inventory_changed.emit()
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	return false

func can_craft_lamp() -> bool:
	return coal >= 3 and iron >= 2

func craft_lamp() -> bool:
	if can_craft_lamp():
		coal -= 3
		iron -= 2
		starter_lamps += 1
		add_exp(25)
		inventory_changed.emit()
		notify("+1 Poste de Luz Forjado!", "lamp")
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	return false

func can_craft_ladders() -> bool:
	return wood_logs >= 1

func craft_ladders() -> bool:
	if can_craft_ladders():
		wood_logs -= 1
		ladders += 5
		add_exp(10)
		inventory_changed.emit()
		notify("+5 Escadas Forjadas!", "ladder")
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	return false

func can_craft_planks() -> bool:
	return wood_logs >= 1

func craft_planks() -> bool:
	if can_craft_planks():
		wood_logs -= 1
		planks += 5
		add_exp(10)
		inventory_changed.emit()
		notify("+5 Tábuas Forjadas!", "plank")
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	return false

func can_craft_brick_floor() -> bool:
	return dirt >= 1 and stone >= 1

func craft_brick_floor() -> bool:
	if can_craft_brick_floor():
		dirt -= 1
		stone -= 1
		brick_floors += 1
		add_exp(15)
		inventory_changed.emit()
		notify("+1 Piso de Tijolo Forjado!", "plank")
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	return false

func add_wood(amount: int = 10) -> void:
	wood_logs += amount
	add_exp(10)
	inventory_changed.emit()
	notify("+%d Troncos de Madeira!" % amount, "wood")
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").request_save()

func reset_inventory() -> void:
	iron = 0
	gold = 0
	coal = 0
	coins = 0
	wood_logs = 0
	ladders = 0
	planks = 0
	dirt = 0
	stone = 0
	brick_floors = 0
	level = 0
	current_exp = 0
	starter_lamps = 1
	active_slot = 0
	inventory_changed.emit()

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
	elif (item_key == "wood" or item_key == "wood_logs") and wood_logs >= amount:
		wood_logs -= amount
		drop.type = 5 # WOOD
		dropped_amount = amount
	elif (item_key == "ladder" or item_key == "ladders") and ladders >= amount:
		ladders -= amount
		drop.type = 6 # LADDER
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

