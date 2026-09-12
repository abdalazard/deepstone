extends Node

signal inventory_changed
signal notification_triggered(text: String, icon_type: String)
signal level_up(new_level: int, exp_needed_next: int)
signal pickaxe_broken

const BASE_CAPACITY: int = 60
var iron: int = 0
var gold: int = 0
var coal: int = 0
var coins: int = 0 # Moedas obtidas na loja
var signs: int = 10 # Mini-poste / lamp
var starter_lamps: int = 1 # 1 lanterna inicial grátis
var wood_logs: int = 0 # Troncos de madeira obtidos de árvores
var ladders: int = 0 # Escadas de madeira forjadas (1 tronco -> 5 escadas)
var planks: int = 0 # Tábuas de madeira forjadas (1 tronco -> 5 tábuas)
var dirt: int = 0 # Lama/Terra obtida de escavação
var stone: int = 0 # Pedra obtida de escavação
var brick_floors: int = 0 # Pisos de tijolo forjados (1 lama + 1 pedra)
var portable_forges: int = 0 # Forjas portáteis (5 pedras + 3 ferros)

# Picareta & Durabilidade
var has_pickaxe: bool = true
var pickaxe_durability: int = 100
var max_pickaxe_durability: int = 100

# Nível e Progressão
var level: int = 0 # Começa no nível zero
var current_exp: int = 0 # EXP acumulada no nível atual

# Hotbar e Atalhos customizáveis
var active_slot: int = 0 # 0..5
var hotbar_slots: Array = ["pickaxe", "lamp", "ladder", "plank", "brick", "forge"]

# Equipamentos Ativos e Posse
var equipped_helmet: String = "helmet_miner"
var equipped_pickaxe: String = "pickaxe_copper"
var equipped_armor: String = "armor_miner"
var equipped_boots: String = "boots_mud"

var owned_helmets: Array = ["helmet_miner"]
var owned_pickaxes: Array = ["pickaxe_copper"]
var owned_armors: Array = ["armor_miner"]
var owned_boots: Array = ["boots_mud"]

const EQUIPMENT_DEFS = {
	# CAPACETES
	"helmet_miner": {
		"id": "helmet_miner",
		"name": "Capacete de Mineirador Pobre",
		"slot": "helmet",
		"desc": "Proteção rústica contra poeira e pedregulhos.",
		"cost_coins": 0,
		"level_req": 0,
		"light_radius": 110.0,
		"icon": "helmet"
	},
	"helmet_lamp": {
		"id": "helmet_lamp",
		"name": "Capacete com Lanterna",
		"slot": "helmet",
		"desc": "Possui foco luminoso frontal acoplado para iluminar o subsolo.",
		"cost_coins": 40,
		"level_req": 0,
		"light_radius": 170.0,
		"icon": "helmet"
	},
	"helmet_iron_lamp": {
		"id": "helmet_iron_lamp",
		"name": "Capacete de Ferro Iluminado",
		"slot": "helmet",
		"desc": "Lanterna de alto alcance e casco blindado forjado em ferro espesso.",
		"cost_coins": 90,
		"level_req": 2,
		"light_radius": 240.0,
		"icon": "helmet"
	},
	
	# PICARETAS
	"pickaxe_copper": {
		"id": "pickaxe_copper",
		"name": "Picareta de Cobre",
		"slot": "pickaxe",
		"desc": "Ferramenta básica de mineração. Durabilidade: 100 HP.",
		"cost_coins": 0,
		"level_req": 0,
		"max_durability": 100,
		"mine_speed_mult": 1.0,
		"icon": "pickaxe"
	},
	"pickaxe_iron": {
		"id": "pickaxe_iron",
		"name": "Picareta de Ferro Reforçada",
		"slot": "pickaxe",
		"desc": "+60% de resistência. Durabilidade: 160 HP e corte 25% mais rápido.",
		"cost_coins": 0,
		"level_req": 1,
		"max_durability": 160,
		"mine_speed_mult": 1.25,
		"icon": "pickaxe"
	},
	"pickaxe_gold": {
		"id": "pickaxe_gold",
		"name": "Picareta de Ouro Nobre",
		"slot": "pickaxe",
		"desc": "Super resistente (+150%) e veloz. Durabilidade: 250 HP e corte 60% mais rápido.",
		"cost_coins": 0,
		"level_req": 2,
		"max_durability": 250,
		"mine_speed_mult": 1.6,
		"icon": "pickaxe"
	},
	
	# TRAJES
	"armor_miner": {
		"id": "armor_miner",
		"name": "Traje do Mineirador Pobre",
		"slot": "armor",
		"desc": "Roupas simples de algodão com bolsos básicos (60 carga).",
		"cost_coins": 0,
		"level_req": 0,
		"capacity_bonus": 0,
		"icon": "armor"
	},
	"armor_reinforced": {
		"id": "armor_reinforced",
		"name": "Traje Reforçado",
		"slot": "armor",
		"desc": "Costura reforçada com bolsos extras (+20 carga: total 80).",
		"cost_coins": 60,
		"level_req": 1,
		"capacity_bonus": 20,
		"icon": "armor"
	},
	"armor_explorer": {
		"id": "armor_explorer",
		"name": "Traje do Explorador",
		"slot": "armor",
		"desc": "Mochila integrada de alta resistência (+40 carga: total 100).",
		"cost_coins": 120,
		"level_req": 2,
		"capacity_bonus": 40,
		"icon": "armor"
	},
	
	# BOTAS
	"boots_mud": {
		"id": "boots_mud",
		"name": "Bota de Lama",
		"slot": "boots",
		"desc": "Botas comuns de borracha para trabalho pesado na lama.",
		"cost_coins": 0,
		"level_req": 0,
		"jump_mult": 1.0,
		"speed_mult": 1.0,
		"icon": "boots"
	},
	"boots_leather": {
		"id": "boots_leather",
		"name": "Botas de Couro Leves",
		"slot": "boots",
		"desc": "+15% de velocidade de corrida e +15% de altura no salto.",
		"cost_coins": 35,
		"level_req": 0,
		"jump_mult": 1.15,
		"speed_mult": 1.15,
		"icon": "boots"
	},
	"boots_steel": {
		"id": "boots_steel",
		"name": "Botas de Aço com Molas",
		"slot": "boots",
		"desc": "+25% de velocidade e +30% de altura de salto extraordinário.",
		"cost_coins": 85,
		"level_req": 2,
		"jump_mult": 1.30,
		"speed_mult": 1.25,
		"icon": "boots"
	}
}

# Aprimoramentos da Forja
const FORGE_UPGRADES = [
	{
		"key": "upgrade_pickaxe_iron",
		"target_item": "pickaxe_iron",
		"name": "Aprimorar Picareta para Ferro",
		"desc": "Reforça a lâmina com liga de ferro (+60% Resistência: 160 HP e corte ágil).",
		"cost": {"iron": 5, "coal": 3},
		"level_req": 1,
		"exp_gain": 40
	},
	{
		"key": "upgrade_pickaxe_gold",
		"target_item": "pickaxe_gold",
		"name": "Aprimorar Picareta para Ouro",
		"desc": "Lâmina polida com ouro maciço (+150% Resistência: 250 HP e corte instantâneo).",
		"cost": {"gold": 4, "iron": 6},
		"level_req": 2,
		"exp_gain": 70
	},
	{
		"key": "upgrade_boots_springs",
		"target_item": "boots_steel",
		"name": "Aprimorar Botas com Molas de Aço",
		"desc": "Instala amortecedores de impacto (+30% Pulo e +25% Velocidade).",
		"cost": {"iron": 4, "plank": 3},
		"level_req": 1,
		"exp_gain": 40
	},
	{
		"key": "upgrade_armor_pockets",
		"target_item": "armor_reinforced",
		"name": "Aprimorar Traje com Bolsos Reforçados",
		"desc": "Adiciona compartimentos de couro e madeira (+20 Carga na Mochila).",
		"cost": {"wood": 5, "iron": 3},
		"level_req": 1,
		"exp_gain": 35
	},
	{
		"key": "upgrade_helmet_lamp",
		"target_item": "helmet_iron_lamp",
		"name": "Aprimorar Capacete com Refletor de Ouro",
		"desc": "Instala lente polida e suporte de ouro (+130% Raio de Luz contínua).",
		"cost": {"gold": 2, "coal": 4},
		"level_req": 2,
		"exp_gain": 50
	}
]

# Preços de Venda na Loja
const COAL_PRICE: int = 5
const IRON_PRICE: int = 15
const GOLD_PRICE: int = 50
const WOOD_PRICE: int = 8
const STONE_PRICE: int = 4
const DIRT_PRICE: int = 2
const PLANK_PRICE: int = 10
const BRICK_PRICE: int = 12
const LADDER_PRICE: int = 8

func get_max_capacity() -> int:
	var def = EQUIPMENT_DEFS.get(equipped_armor, {})
	var bonus = def.get("capacity_bonus", 0)
	return BASE_CAPACITY + bonus

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

func damage_pickaxe(amount: int = 1) -> void:
	if not has_pickaxe: return
	pickaxe_durability = max(0, pickaxe_durability - amount)
	inventory_changed.emit()
	if pickaxe_durability <= 0:
		has_pickaxe = false
		pickaxe_broken.emit()
		notify("Sua picareta quebrou! Colete os materiais e forje uma nova.", "pickaxe")

# Equipment Getters
func get_equipped_def(slot: String) -> Dictionary:
	var id = ""
	match slot:
		"helmet": id = equipped_helmet
		"pickaxe": id = equipped_pickaxe
		"armor": id = equipped_armor
		"boots": id = equipped_boots
	return EQUIPMENT_DEFS.get(id, {})

func get_boots_speed_multiplier() -> float:
	var def = EQUIPMENT_DEFS.get(equipped_boots, {})
	return def.get("speed_mult", 1.0)

func get_boots_jump_multiplier() -> float:
	var def = EQUIPMENT_DEFS.get(equipped_boots, {})
	return def.get("jump_mult", 1.0)

func get_helmet_light_radius() -> float:
	var def = EQUIPMENT_DEFS.get(equipped_helmet, {})
	return def.get("light_radius", 110.0)

func get_pickaxe_speed_multiplier() -> float:
	var def = EQUIPMENT_DEFS.get(equipped_pickaxe, {})
	return def.get("mine_speed_mult", 1.0)

func equip_gear(item_id: String) -> bool:
	if not EQUIPMENT_DEFS.has(item_id): return false
	var def = EQUIPMENT_DEFS[item_id]
	var slot = def.get("slot", "")
	match slot:
		"helmet":
			if not item_id in owned_helmets: return false
			equipped_helmet = item_id
		"pickaxe":
			if not item_id in owned_pickaxes: return false
			equipped_pickaxe = item_id
			max_pickaxe_durability = def.get("max_durability", 100)
			pickaxe_durability = max_pickaxe_durability
			has_pickaxe = true
		"armor":
			if not item_id in owned_armors: return false
			equipped_armor = item_id
		"boots":
			if not item_id in owned_boots: return false
			equipped_boots = item_id
	inventory_changed.emit()
	notify("Equipado: %s" % def.name, def.get("icon", "equip"))
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").request_save()
	return true

func buy_shop_item(item_id: String) -> bool:
	if not EQUIPMENT_DEFS.has(item_id): return false
	var def = EQUIPMENT_DEFS[item_id]
	var cost = def.get("cost_coins", 0)
	var req_lvl = def.get("level_req", 0)
	if coins < cost:
		notify("Moedas insuficientes!", "coin_gold")
		return false
	if level < req_lvl:
		notify("Requer Nível %d!" % req_lvl, "coin_gold")
		return false
	var slot = def.get("slot", "")
	match slot:
		"helmet":
			if item_id in owned_helmets: return false
			owned_helmets.append(item_id)
		"pickaxe":
			if item_id in owned_pickaxes: return false
			owned_pickaxes.append(item_id)
		"armor":
			if item_id in owned_armors: return false
			owned_armors.append(item_id)
		"boots":
			if item_id in owned_boots: return false
			owned_boots.append(item_id)
	coins -= cost
	add_exp(35)
	equip_gear(item_id)
	inventory_changed.emit()
	notify("Comprado: %s!" % def.name, def.get("icon", "equip"))
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").request_save()
	return true

func can_forge_upgrade(upgrade: Dictionary) -> bool:
	if level < upgrade.get("level_req", 0): return false
	var target = upgrade.get("target_item", "")
	var def = EQUIPMENT_DEFS.get(target, {})
	var slot = def.get("slot", "")
	match slot:
		"helmet":
			if target in owned_helmets and equipped_helmet == target: return false
		"pickaxe":
			if target in owned_pickaxes and equipped_pickaxe == target: return false
		"armor":
			if target in owned_armors and equipped_armor == target: return false
		"boots":
			if target in owned_boots and equipped_boots == target: return false
			
	var cost = upgrade.get("cost", {})
	for rk in cost:
		var req_amt = cost[rk]
		if rk == "iron" and iron < req_amt: return false
		elif rk == "gold" and gold < req_amt: return false
		elif rk == "coal" and coal < req_amt: return false
		elif rk == "wood" and wood_logs < req_amt: return false
		elif rk == "stone" and stone < req_amt: return false
		elif rk == "plank" and planks < req_amt: return false
		elif rk == "dirt" and dirt < req_amt: return false
	return true

func execute_forge_upgrade(upgrade_key: String) -> bool:
	var up_def = null
	for u in FORGE_UPGRADES:
		if u.key == upgrade_key:
			up_def = u
			break
	if not up_def: return false
	if not can_forge_upgrade(up_def): return false
	
	var cost = up_def.get("cost", {})
	for rk in cost:
		var amt = cost[rk]
		if rk == "iron": iron -= amt
		elif rk == "gold": gold -= amt
		elif rk == "coal": coal -= amt
		elif rk == "wood": wood_logs -= amt
		elif rk == "stone": stone -= amt
		elif rk == "plank": planks -= amt
		elif rk == "dirt": dirt -= amt
		
	var target = up_def.get("target_item", "")
	var def = EQUIPMENT_DEFS.get(target, {})
	var slot = def.get("slot", "")
	match slot:
		"helmet":
			if not target in owned_helmets: owned_helmets.append(target)
		"pickaxe":
			if not target in owned_pickaxes: owned_pickaxes.append(target)
		"armor":
			if not target in owned_armors: owned_armors.append(target)
		"boots":
			if not target in owned_boots: owned_boots.append(target)
			
	equip_gear(target)
	add_exp(up_def.get("exp_gain", 40))
	inventory_changed.emit()
	notify("Aprimorado: %s!" % def.name, def.get("icon", "equip"))
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").request_save()
	return true

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
	elif key == "wood" and wood_logs >= amount:
		wood_logs -= amount
		earned = amount * WOOD_PRICE
		exp_gain = amount * 3
	elif key == "stone" and stone >= amount:
		stone -= amount
		earned = amount * STONE_PRICE
		exp_gain = amount * 2
	elif key == "dirt" and dirt >= amount:
		dirt -= amount
		earned = amount * DIRT_PRICE
		exp_gain = amount * 1
	elif key == "plank" and planks >= amount:
		planks -= amount
		earned = amount * PLANK_PRICE
		exp_gain = amount * 4
	elif key == "brick" and brick_floors >= amount:
		brick_floors -= amount
		earned = amount * BRICK_PRICE
		exp_gain = amount * 5
	elif key == "ladder" and ladders >= amount:
		ladders -= amount
		earned = amount * LADDER_PRICE
		exp_gain = amount * 3
		
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
	elif key == "wood": count = wood_logs
	elif key == "stone": count = stone
	elif key == "dirt": count = dirt
	elif key == "plank": count = planks
	elif key == "brick": count = brick_floors
	elif key == "ladder": count = ladders
	if count > 0:
		return sell_resource(key, count)
	return 0

func sell_all_minerals() -> int:
	var total_earned = 0
	total_earned += sell_all_resource("coal")
	total_earned += sell_all_resource("iron")
	total_earned += sell_all_resource("gold")
	total_earned += sell_all_resource("wood")
	total_earned += sell_all_resource("stone")
	total_earned += sell_all_resource("dirt")
	total_earned += sell_all_resource("plank")
	total_earned += sell_all_resource("brick")
	total_earned += sell_all_resource("ladder")
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

# Receitas de Forja (Criar)
func can_craft_pickaxe() -> bool:
	return iron >= 1 and wood_logs >= 2 and stone >= 1

func craft_pickaxe() -> bool:
	if can_craft_pickaxe():
		iron -= 1
		wood_logs -= 2
		stone -= 1
		has_pickaxe = true
		var cur_def = EQUIPMENT_DEFS.get(equipped_pickaxe, {})
		max_pickaxe_durability = cur_def.get("max_durability", 100)
		pickaxe_durability = max_pickaxe_durability
		add_exp(20)
		inventory_changed.emit()
		notify("Nova Picareta Forjada!", "pickaxe")
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
		add_exp(15)
		inventory_changed.emit()
		notify("Poste de Luz Forjado!", "lamp")
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
		notify("+5 Escadas Forjadas!", "wood")
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
		notify("+5 Tábuas Forjadas!", "wood")
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
		add_exp(12)
		inventory_changed.emit()
		notify("+1 Piso de Tijolo Forjado!", "plank")
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	return false

func can_craft_portable_forge() -> bool:
	return stone >= 5 and iron >= 3

func craft_portable_forge() -> bool:
	if can_craft_portable_forge():
		stone -= 5
		iron -= 3
		portable_forges += 1
		add_exp(30)
		inventory_changed.emit()
		notify("Forja Portátil Forjada!", "forge")
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	return false

func set_hotbar_slot(slot_idx: int, item_key: String) -> void:
	if slot_idx >= 0 and slot_idx < hotbar_slots.size():
		hotbar_slots[slot_idx] = item_key
		inventory_changed.emit()
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()

func get_current_load() -> int:
	return iron + gold + coal

func is_full() -> bool:
	return get_current_load() >= get_max_capacity()

func add_item(type: String, amount: int = 1) -> bool:
	if type in ["iron", "gold", "coal"]:
		if is_full():
			notify("Mochila Cheia! (" + str(get_current_load()) + "/" + str(get_max_capacity()) + ")", "chest")
			return false
		var space = get_max_capacity() - get_current_load()
		var to_add = min(amount, space)
		if type == "iron":
			iron += to_add
			notify("+" + str(to_add) + " Ferro", "iron")
			add_exp(to_add * 2)
		elif type == "gold":
			gold += to_add
			notify("+" + str(to_add) + " Ouro", "gold")
			add_exp(to_add * 5)
		elif type == "coal":
			coal += to_add
			notify("+" + str(to_add) + " Carvão", "coal")
			add_exp(to_add * 1)
		inventory_changed.emit()
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	elif type == "wood":
		wood_logs += amount
		notify("+" + str(amount) + " Madeira", "wood")
		add_exp(amount * 1)
		inventory_changed.emit()
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	elif type == "stone":
		stone += amount
		notify("+" + str(amount) + " Pedra", "stone")
		add_exp(amount * 1)
		inventory_changed.emit()
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	elif type == "dirt":
		dirt += amount
		notify("+" + str(amount) + " Terra", "dirt")
		inventory_changed.emit()
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	elif type == "broken_pickaxe":
		notify("Picareta quebrada recuperada! Forje uma nova.", "pickaxe")
		inventory_changed.emit()
		return true
	elif type == "forge":
		portable_forges += amount
		notify("Forja Portátil recuperada!", "forge")
		inventory_changed.emit()
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	elif type == "lamp":
		starter_lamps += amount
		inventory_changed.emit()
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	elif type == "ladder":
		ladders += amount
		inventory_changed.emit()
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	elif type == "plank":
		planks += amount
		inventory_changed.emit()
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	elif type == "brick":
		brick_floors += amount
		inventory_changed.emit()
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	return false

func drop_item(type: String, amount: int = 1) -> bool:
	var tree = get_tree() if is_inside_tree() else null
	var current = tree.current_scene if tree else null
	var player = current.get_node_or_null("Player") if current else null
	var drop_pos = player.global_position + Vector2(0, -10) if is_instance_valid(player) else Vector2.ZERO

	var drop_res_type = -1
	if type == "iron" and iron >= amount:
		iron -= amount
		drop_res_type = 1 # IRON
	elif type == "gold" and gold >= amount:
		gold -= amount
		drop_res_type = 2 # GOLD
	elif type == "coal" and coal >= amount:
		coal -= amount
		drop_res_type = 0 # COAL
	elif type == "wood" and wood_logs >= amount:
		wood_logs -= amount
		drop_res_type = 3 # WOOD
	elif type == "stone" and stone >= amount:
		stone -= amount
		drop_res_type = 4 # STONE
	elif type == "dirt" and dirt >= amount:
		dirt -= amount
		drop_res_type = 5 # DIRT
	elif type == "lamp" and starter_lamps >= amount:
		starter_lamps -= amount
		drop_res_type = 8 # LAMP
	elif type == "ladder" and ladders >= amount:
		ladders -= amount
		drop_res_type = 9 # LADDER
	elif type == "plank" and planks >= amount:
		planks -= amount
		drop_res_type = 10 # PLANK
	elif type == "brick" and brick_floors >= amount:
		brick_floors -= amount
		drop_res_type = 11 # BRICK
	elif type == "forge" and portable_forges >= amount:
		portable_forges -= amount
		drop_res_type = 7 # FORGE
	elif type == "pickaxe" and has_pickaxe:
		has_pickaxe = false
		drop_res_type = 6 # BROKEN_PICKAXE

	if drop_res_type != -1:
		inventory_changed.emit()
		notify("Item solto no chão!", "chest")
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		if is_instance_valid(current) and drop_pos != Vector2.ZERO:
			var drop_scene = preload("res://scenes/items/resource_drop.tscn")
			for i in range(amount):
				var drop = drop_scene.instantiate()
				drop.type = drop_res_type
				drop.global_position = drop_pos + Vector2(randf_range(-10, 10), randf_range(-5, 0))
				current.add_child(drop)
		return true
	return false

func notify(text: String, icon_type: String = "") -> void:
	notification_triggered.emit(text, icon_type)

func reset_inventory() -> void:
	iron = 0
	gold = 0
	coal = 0
	coins = 0
	signs = 10
	starter_lamps = 1
	wood_logs = 0
	ladders = 0
	planks = 0
	dirt = 0
	stone = 0
	brick_floors = 0
	portable_forges = 0
	has_pickaxe = true
	pickaxe_durability = 100
	max_pickaxe_durability = 100
	level = 0
	current_exp = 0
	active_slot = 0
	hotbar_slots = ["pickaxe", "lamp", "ladder", "plank", "brick", "forge"]
	equipped_helmet = "helmet_miner"
	equipped_pickaxe = "pickaxe_copper"
	equipped_armor = "armor_miner"
	equipped_boots = "boots_mud"
	owned_helmets = ["helmet_miner"]
	owned_pickaxes = ["pickaxe_copper"]
	owned_armors = ["armor_miner"]
	owned_boots = ["boots_mud"]
	inventory_changed.emit()
