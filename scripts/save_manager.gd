extends Node

const SAVE_PATH: String = "user://savegame.json"

var world_seed: int = 0
var has_loaded_save: bool = false
var mined_blocks: Dictionary = {}
var placed_torches_data: Array = []
var placed_ropes_data: Array = []
var placed_planks_data: Array = []
var player_saved_pos: Vector2 = Vector2.ZERO
var chest_saved_load: int = 0
var chest_saved_closed: bool = false

var inventory_override: Node = null

var _save_timer: Timer
var _save_debounced: bool = false

func _ready() -> void:
	if has_save():
		load_game()
	else:
		world_seed = randi()
	
	_save_timer = Timer.new()
	_save_timer.wait_time = 15.0
	_save_timer.autostart = true
	_save_timer.one_shot = false
	_save_timer.timeout.connect(func():
		save_game(false)
	)
	add_child(_save_timer)

func _get_inventory() -> Node:
	if inventory_override:
		return inventory_override
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("Inventory"):
		return get_tree().root.get_node("Inventory")
	return null

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	mined_blocks.clear()
	placed_torches_data.clear()
	placed_ropes_data.clear()
	placed_planks_data.clear()
	has_loaded_save = false
	world_seed = randi()
	player_saved_pos = Vector2.ZERO
	chest_saved_load = 0
	chest_saved_closed = false

func mark_block_mined(grid_pos: Vector2i) -> void:
	var key = "%d,%d" % [grid_pos.x, grid_pos.y]
	mined_blocks[key] = true
	request_save()

func is_block_mined(grid_pos: Vector2i) -> bool:
	var key = "%d,%d" % [grid_pos.x, grid_pos.y]
	return mined_blocks.has(key)

func request_save() -> void:
	if _save_debounced: return
	_save_debounced = true
	var tree = get_tree() if is_inside_tree() else null
	if tree:
		tree.create_timer(0.5).timeout.connect(func():
			_save_debounced = false
			save_game(false)
		)
	else:
		_save_debounced = false
		save_game(false)

func save_game(show_notify: bool = false) -> void:
	var tree = get_tree() if is_inside_tree() else null
	var current = tree.current_scene if tree else null
	var player = current.get_node_or_null("Player") if current else null
	var chest = current.get_node_or_null("Chest") if current else null
	var inv = _get_inventory()
	
	var p_pos = player_saved_pos if player_saved_pos != Vector2.ZERO else Vector2(496, 96)
	if is_instance_valid(player):
		p_pos = player.global_position
		
	var player_data = {
		"x": p_pos.x,
		"y": p_pos.y,
		"active_slot": inv.active_slot if inv else 0
	}
	
	var chest_data = {
		"stored_load": chest.stored_load if is_instance_valid(chest) else chest_saved_load,
		"is_closed": chest.is_closed if is_instance_valid(chest) else chest_saved_closed
	}
	
	var torches_list = []
	if tree:
		for t in tree.get_nodes_in_group("placed_torches"):
			if is_instance_valid(t):
				torches_list.append({"x": t.global_position.x, "y": t.global_position.y})
	if torches_list.is_empty() and not placed_torches_data.is_empty():
		torches_list = placed_torches_data
	
	var ropes_list = []
	if tree:
		for r in tree.get_nodes_in_group("placed_ropes"):
			if is_instance_valid(r):
				ropes_list.append({"x": r.global_position.x, "y": r.global_position.y})
	if ropes_list.is_empty() and not placed_ropes_data.is_empty():
		ropes_list = placed_ropes_data
	
	var planks_list = []
	if tree:
		for p in tree.get_nodes_in_group("placed_planks"):
			if is_instance_valid(p):
				planks_list.append({"x": p.global_position.x, "y": p.global_position.y})
	if planks_list.is_empty() and not placed_planks_data.is_empty():
		planks_list = placed_planks_data
	
	var save_data = {
		"version": 1,
		"world_seed": world_seed,
		"mined_blocks": mined_blocks.keys(),
		"player": player_data,
		"inventory": {
			"iron": inv.iron if inv else 0,
			"gold": inv.gold if inv else 0,
			"coal": inv.coal if inv else 0,
			"signs": inv.signs if inv else 10,
			"planks": inv.planks if inv else 15
		},
		"chest": chest_data,
		"placed_torches": torches_list,
		"placed_ropes": ropes_list,
		"placed_planks": planks_list
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "	"))
		file.close()
		if show_notify and inv:
			inv.notify("Progresso Salvo!", "save")

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_str)
	if error != OK:
		return false
	
	var data = json.get_data()
	if not (data is Dictionary):
		return false
	
	world_seed = data.get("world_seed", randi())
	
	mined_blocks.clear()
	var mined_arr = data.get("mined_blocks", [])
	for k in mined_arr:
		mined_blocks[str(k)] = true
	
	var inv = _get_inventory()
	var inv_data = data.get("inventory", {})
	if inv:
		inv.iron = inv_data.get("iron", 0)
		inv.gold = inv_data.get("gold", 0)
		inv.coal = inv_data.get("coal", 0)
		inv.signs = inv_data.get("signs", 10)
		inv.planks = inv_data.get("planks", 15)
	
	var p_data = data.get("player", {})
	if p_data.has("x") and p_data.has("y"):
		player_saved_pos = Vector2(p_data["x"], p_data["y"])
	if inv:
		inv.active_slot = p_data.get("active_slot", 0)
	
	var c_data = data.get("chest", {})
	chest_saved_load = c_data.get("stored_load", 0)
	chest_saved_closed = c_data.get("is_closed", false)
	
	placed_torches_data = data.get("placed_torches", [])
	placed_ropes_data = data.get("placed_ropes", [])
	placed_planks_data = data.get("placed_planks", [])
	
	has_loaded_save = true
	if inv:
		inv.inventory_changed.emit()
	return true
