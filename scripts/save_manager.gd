extends Node

const SAVE_PATH: String = "user://savegame.json"

var world_seed: int = 0
var has_loaded_save: bool = false
var current_biome: int = 0

# Dados por bioma: índice 0=Terra, 1=Frost, 2=Molten
var biome_mined_blocks: Array = [{}, {}, {}]
var biome_placed_torches: Array = [[], [], []]
var biome_placed_ropes: Array = [[], [], []]
var biome_placed_planks: Array = [[], [], []]
var biome_placed_slabs: Array = [[], [], []]
var biome_placed_forges: Array = [[], [], []]
var biome_death_markers: Array = [[], [], []]

# Propriedades de compatibilidade (apontam para o bioma atual)
var mined_blocks: Dictionary:
	get: return biome_mined_blocks[current_biome]
var placed_torches_data: Array:
	get: return biome_placed_torches[current_biome]
	set(v): biome_placed_torches[current_biome] = v
var placed_ropes_data: Array:
	get: return biome_placed_ropes[current_biome]
	set(v): biome_placed_ropes[current_biome] = v
var placed_planks_data: Array:
	get: return biome_placed_planks[current_biome]
	set(v): biome_placed_planks[current_biome] = v
var placed_slabs_data: Array:
	get: return biome_placed_slabs[current_biome]
	set(v): biome_placed_slabs[current_biome] = v
var placed_forges_data: Array:
	get: return biome_placed_forges[current_biome]
	set(v): biome_placed_forges[current_biome] = v
var death_markers_data: Array:
	get: return biome_death_markers[current_biome]
	set(v): biome_death_markers[current_biome] = v

var player_saved_pos: Vector2 = Vector2.ZERO
var chest_saved_load: int = 0
var chest_saved_closed: bool = false
var chest_saved_coal: int = 0
var chest_saved_iron: int = 0
var chest_saved_gold: int = 0

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
	for i in 3:
		biome_mined_blocks[i].clear()
		biome_placed_torches[i].clear()
		biome_placed_ropes[i].clear()
		biome_placed_planks[i].clear()
		biome_placed_slabs[i].clear()
		biome_placed_forges[i].clear()
		biome_death_markers[i].clear()
	current_biome = 0
	has_loaded_save = false
	world_seed = randi()
	player_saved_pos = Vector2(640, 96)
	chest_saved_load = 0
	chest_saved_closed = false
	chest_saved_coal = 0
	chest_saved_iron = 0
	chest_saved_gold = 0
	var inv = _get_inventory()
	if inv:
		inv.reset_inventory()

func reset_mine_completely() -> void:
	clear_save()
	var tree = get_tree() if is_inside_tree() else null
	if tree:
		tree.paused = false
		tree.change_scene_to_file("res://scenes/main/main.tscn")

func mark_block_mined(grid_pos: Vector2i) -> void:
	var key = "%d,%d" % [grid_pos.x, grid_pos.y]
	biome_mined_blocks[current_biome][key] = true
	request_save()

func is_block_mined(grid_pos: Vector2i) -> bool:
	var key = "%d,%d" % [grid_pos.x, grid_pos.y]
	return biome_mined_blocks[current_biome].has(key)

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
	var chest = null
	if tree:
		var chests = tree.get_nodes_in_group("chest")
		if not chests.is_empty():
			chest = chests[0]
	if not chest and current:
		var candidate = current.get_node_or_null("Chest")
		if candidate and "stored_coal" in candidate:
			chest = candidate
	var inv = _get_inventory()

	var p_pos = player_saved_pos if player_saved_pos != Vector2.ZERO else Vector2(640, 96)
	if is_instance_valid(player):
		p_pos = player.global_position

	var player_data = {
		"x": p_pos.x,
		"y": p_pos.y,
		"active_slot": inv.active_slot if inv else 0
	}

	var has_chest = is_instance_valid(chest) and ("stored_coal" in chest)
	var chest_data = {
		"stored_coal": chest.stored_coal if has_chest else chest_saved_coal,
		"stored_iron": chest.stored_iron if has_chest else chest_saved_iron,
		"stored_gold": chest.stored_gold if has_chest else chest_saved_gold,
		"stored_load": chest.stored_load if has_chest else (chest_saved_coal + chest_saved_iron + chest_saved_gold),
		"is_closed": false
	}

	# Coleta itens do bioma atual a partir da cena
	var torches_list = []
	if tree:
		for t in tree.get_nodes_in_group("placed_torches"):
			if is_instance_valid(t):
				torches_list.append({"x": t.global_position.x, "y": t.global_position.y})
	if torches_list.is_empty() and not biome_placed_torches[current_biome].is_empty():
		torches_list = biome_placed_torches[current_biome]
	biome_placed_torches[current_biome] = torches_list

	var ropes_list = []
	if tree:
		for r in tree.get_nodes_in_group("placed_ropes"):
			if is_instance_valid(r):
				ropes_list.append({"x": r.global_position.x, "y": r.global_position.y})
	if ropes_list.is_empty() and not biome_placed_ropes[current_biome].is_empty():
		ropes_list = biome_placed_ropes[current_biome]
	biome_placed_ropes[current_biome] = ropes_list

	var planks_list = []
	if tree:
		for p in tree.get_nodes_in_group("placed_planks"):
			if is_instance_valid(p):
				planks_list.append({"x": p.global_position.x, "y": p.global_position.y})
	if planks_list.is_empty() and not biome_placed_planks[current_biome].is_empty():
		planks_list = biome_placed_planks[current_biome]
	biome_placed_planks[current_biome] = planks_list

	var slabs_list = []
	if tree:
		for s in tree.get_nodes_in_group("placed_slabs"):
			if is_instance_valid(s):
				slabs_list.append({"x": s.global_position.x, "y": s.global_position.y})
	if slabs_list.is_empty() and not biome_placed_slabs[current_biome].is_empty():
		slabs_list = biome_placed_slabs[current_biome]
	biome_placed_slabs[current_biome] = slabs_list

	var forges_list = []
	if tree:
		for f in tree.get_nodes_in_group("placed_forges"):
			if is_instance_valid(f):
				forges_list.append({"x": f.global_position.x, "y": f.global_position.y})
	if forges_list.is_empty() and not biome_placed_forges[current_biome].is_empty():
		forges_list = biome_placed_forges[current_biome]
	biome_placed_forges[current_biome] = forges_list

	# Serializa dados de todos os biomas
	var biome_data_arr = []
	for i in 3:
		biome_data_arr.append({
			"mined_blocks": biome_mined_blocks[i].keys(),
			"placed_torches": biome_placed_torches[i],
			"placed_ropes": biome_placed_ropes[i],
			"placed_planks": biome_placed_planks[i],
			"placed_slabs": biome_placed_slabs[i],
			"placed_forges": biome_placed_forges[i],
			"death_markers": biome_death_markers[i]
		})

	var save_data = {
		"version": 2,
		"world_seed": world_seed,
		"current_biome": current_biome,
		"player": player_data,
		"inventory": {
			"iron": inv.iron if inv else 0,
			"gold": inv.gold if inv else 0,
			"coal": inv.coal if inv else 0,
			"coins": inv.coins if (inv and "coins" in inv) else 0,
			"signs": inv.signs if inv else 10,
			"starter_lamps": inv.starter_lamps if (inv and "starter_lamps" in inv) else 1,
			"planks": inv.planks if inv else 0,
			"wood_logs": inv.wood_logs if (inv and "wood_logs" in inv) else 0,
			"ladders": inv.ladders if (inv and "ladders" in inv) else 0,
			"dirt": inv.dirt if (inv and "dirt" in inv) else 0,
			"stone": inv.stone if (inv and "stone" in inv) else 0,
			"columns": inv.columns if (inv and "columns" in inv) else 0,
			"slabs": inv.slabs if (inv and "slabs" in inv) else 0,
			"portable_forges": inv.portable_forges if (inv and "portable_forges" in inv) else 0,
			"has_pickaxe": inv.has_pickaxe if (inv and "has_pickaxe" in inv) else true,
			"pickaxe_durability": inv.pickaxe_durability if (inv and "pickaxe_durability" in inv) else 100,
			"level": inv.level if (inv and "level" in inv) else 0,
			"current_exp": inv.current_exp if (inv and "current_exp" in inv) else 0,
			"hotbar_slots": inv.hotbar_slots if (inv and "hotbar_slots" in inv) else ["pickaxe", "lamp"],
			"equipped_helmet": inv.equipped_helmet if (inv and "equipped_helmet" in inv) else "helmet_miner",
			"equipped_pickaxe": inv.equipped_pickaxe if (inv and "equipped_pickaxe" in inv) else "pickaxe_copper",
			"equipped_armor": inv.equipped_armor if (inv and "equipped_armor" in inv) else "armor_miner",
			"equipped_boots": inv.equipped_boots if (inv and "equipped_boots" in inv) else "boots_mud",
			"equipped_glove": inv.equipped_glove if (inv and "equipped_glove" in inv) else "glove_leather",
			"owned_helmets": inv.owned_helmets if (inv and "owned_helmets" in inv) else ["helmet_miner"],
			"owned_pickaxes": inv.owned_pickaxes if (inv and "owned_pickaxes" in inv) else ["pickaxe_copper"],
			"owned_armors": inv.owned_armors if (inv and "owned_armors" in inv) else ["armor_miner"],
			"owned_boots": inv.owned_boots if (inv and "owned_boots" in inv) else ["boots_mud"],
			"owned_gloves": inv.owned_gloves if (inv and "owned_gloves" in inv) else ["glove_leather"]
		},
		"chest": chest_data,
		"biome_data": biome_data_arr
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.flush()
		file.close()
		has_loaded_save = true
		if show_notify and inv:
			inv.notify("Progresso Salvo!", "save")

func restart_run_to_surface() -> void:
	current_biome = 0
	player_saved_pos = Vector2(640, 96)
	save_game(false)
	var tree = get_tree() if is_inside_tree() else null
	if tree:
		tree.change_scene_to_file("res://scenes/main/main.tscn")

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
	current_biome = data.get("current_biome", 0)

	# Carrega dados dos biomas
	var biome_data_arr = data.get("biome_data", [])
	if not biome_data_arr.is_empty():
		for i in 3:
			var bd: Dictionary = biome_data_arr[i] if i < biome_data_arr.size() else {}
			biome_mined_blocks[i].clear()
			for k in bd.get("mined_blocks", []):
				biome_mined_blocks[i][str(k)] = true
			biome_placed_torches[i] = bd.get("placed_torches", [])
			biome_placed_ropes[i] = bd.get("placed_ropes", [])
			biome_placed_planks[i] = bd.get("placed_planks", [])
			biome_placed_slabs[i] = bd.get("placed_slabs", [])
			biome_placed_forges[i] = bd.get("placed_forges", [])
			biome_death_markers[i] = bd.get("death_markers", [])
	else:
		# Compatibilidade com saves antigos (formato v1)
		biome_mined_blocks[0].clear()
		for k in data.get("mined_blocks", []):
			biome_mined_blocks[0][str(k)] = true
		biome_placed_torches[0] = data.get("placed_torches", [])
		biome_placed_ropes[0] = data.get("placed_ropes", [])
		biome_placed_planks[0] = data.get("placed_planks", [])
		biome_placed_slabs[0] = data.get("placed_slabs", [])
		biome_placed_forges[0] = data.get("placed_forges", [])
		biome_death_markers[0] = data.get("death_markers", [])

	var inv = _get_inventory()
	var inv_data = data.get("inventory", {})
	if inv:
		inv.iron = inv_data.get("iron", 0)
		inv.gold = inv_data.get("gold", 0)
		inv.coal = inv_data.get("coal", 0)
		if "coins" in inv:
			inv.coins = inv_data.get("coins", 0)
		inv.signs = inv_data.get("signs", 10)
		if "starter_lamps" in inv:
			inv.starter_lamps = inv_data.get("starter_lamps", 1)
		inv.planks = inv_data.get("planks", 0)
		if "wood_logs" in inv:
			inv.wood_logs = inv_data.get("wood_logs", 0)
		if "ladders" in inv:
			inv.ladders = inv_data.get("ladders", 0)
		if "dirt" in inv:
			inv.dirt = inv_data.get("dirt", 0)
		if "stone" in inv:
			inv.stone = inv_data.get("stone", 0)
		if "columns" in inv:
			inv.columns = inv_data.get("columns", 0)
		if "slabs" in inv:
			inv.slabs = inv_data.get("slabs", 0)
		if "portable_forges" in inv:
			inv.portable_forges = inv_data.get("portable_forges", 0)
		if "has_pickaxe" in inv:
			inv.has_pickaxe = inv_data.get("has_pickaxe", true)
		if "pickaxe_durability" in inv:
			inv.pickaxe_durability = inv_data.get("pickaxe_durability", 100)
		if "level" in inv:
			inv.level = inv_data.get("level", 0)
		if "current_exp" in inv:
			inv.current_exp = inv_data.get("current_exp", 0)
		if "hotbar_slots" in inv:
			var saved_slots: Array = inv_data.get("hotbar_slots", ["pickaxe", "lamp"])
			inv.hotbar_slots = []
			for s in saved_slots:
				if s not in ["forge"]:
					inv.hotbar_slots.append(s)
			if inv.has_method("ensure_hotbar_slots"):
				inv.ensure_hotbar_slots(5)
		if "equipped_helmet" in inv:
			inv.equipped_helmet = inv_data.get("equipped_helmet", "helmet_miner")
		if "equipped_pickaxe" in inv:
			inv.equipped_pickaxe = inv_data.get("equipped_pickaxe", "pickaxe_copper")
		if "equipped_armor" in inv:
			inv.equipped_armor = inv_data.get("equipped_armor", "armor_miner")
		if "equipped_boots" in inv:
			inv.equipped_boots = inv_data.get("equipped_boots", "boots_mud")
		if "equipped_glove" in inv:
			inv.equipped_glove = inv_data.get("equipped_glove", "glove_leather")
		if "owned_helmets" in inv:
			inv.owned_helmets = inv_data.get("owned_helmets", ["helmet_miner"])
		if "owned_pickaxes" in inv:
			inv.owned_pickaxes = inv_data.get("owned_pickaxes", ["pickaxe_copper"])
		if "owned_armors" in inv:
			inv.owned_armors = inv_data.get("owned_armors", ["armor_miner"])
		if "owned_boots" in inv:
			inv.owned_boots = inv_data.get("owned_boots", ["boots_mud"])
		if "owned_gloves" in inv:
			inv.owned_gloves = inv_data.get("owned_gloves", ["glove_leather"])

	var p_data = data.get("player", {})
	if p_data.has("x") and p_data.has("y"):
		player_saved_pos = Vector2(p_data["x"], p_data["y"])
	if inv:
		inv.active_slot = p_data.get("active_slot", 0)

	var c_data = data.get("chest", {})
	chest_saved_coal = c_data.get("stored_coal", 0)
	chest_saved_iron = c_data.get("stored_iron", 0)
	chest_saved_gold = c_data.get("stored_gold", 0)
	chest_saved_load = c_data.get("stored_load", chest_saved_coal + chest_saved_iron + chest_saved_gold)
	chest_saved_closed = false

	has_loaded_save = true
	return true

func register_death(pos: Vector2, level: int = 0) -> void:
	biome_death_markers[current_biome].append({"x": pos.x, "y": pos.y, "level": level})
	request_save()

func remove_death_marker(pos: Vector2) -> void:
	var filtered: Array = []
	for dm in biome_death_markers[current_biome]:
		if absf(float(dm.get("x", -9999)) - pos.x) > 1.0 or absf(float(dm.get("y", -9999)) - pos.y) > 1.0:
			filtered.append(dm)
	biome_death_markers[current_biome] = filtered
	request_save()
