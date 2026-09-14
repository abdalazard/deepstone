extends Node

signal inventory_changed
signal notification_triggered(text: String, icon_type: String)
signal level_up(new_level: int, exp_needed_next: int)
signal pickaxe_broken
signal player_hurt

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
var columns: int = 0 # Colunas de suporte estrutural (3 lama + 3 pedra)
var slabs: int = 0 # Lajes de tijolo estruturais (2 lama + 2 pedra)
var portable_forges: int = 0 # Forjas portáteis (5 lama + 4 pedra + 2 ferro)

# Saúde e Resistência do jogador
var current_health: float = 30.0

func get_max_health() -> int:
	return 30 + level * 5

func get_resistance() -> int:
	var armor_def = get_equipped_def("armor")
	var helmet_def = get_equipped_def("helmet")
	var armor_res = armor_def.get("capacity_bonus", 0) / 4 + armor_upgrade_level * 5
	var helmet_res = int(helmet_def.get("light_radius", 110.0) / 30.0) + helmet_upgrade_level * 5
	return armor_res + helmet_res

func take_damage(amount: int) -> bool:
	var mitigation = get_resistance()
	var final_dmg = max(1, amount - mitigation)
	current_health = max(0.0, current_health - final_dmg)
	notify("-%d de Vida" % final_dmg, "pickaxe")
	player_hurt.emit()
	inventory_changed.emit()
	if current_health <= 0.0:
		die()
		return true
	return false

func die() -> void:
	# Ao morrer perde-se SOMENTE os recursos brutos que não foram guardados no baú.
	# Itens forjados/colocáveis (escadas, tábuas, colunas, lajes, forjas, bombas,
	# lampiões) e equipamentos NÃO são perdidos.
	iron = 0
	gold = 0
	coal = 0
	wood_logs = 0
	dirt = 0
	stone = 0
	notify("Você morreu! Os recursos coletados foram perdidos.", "pickaxe")
	inventory_changed.emit()
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").request_save()
	var hud = _get_hud()
	if hud and hud.has_method("show_death_screen"):
		hud.show_death_screen()

func heal_full() -> void:
	current_health = float(get_max_health())
	inventory_changed.emit()

func _get_hud() -> Node:
	if is_inside_tree() and get_tree() and get_tree().current_scene:
		return get_tree().current_scene.get_node_or_null("HUD")
	return null
var bombs: int = 0 # Bombas de dinamite para escavação rápida

# Picareta & Durabilidade
var has_pickaxe: bool = true
var pickaxe_durability: int = 100
var max_pickaxe_durability: int = 100
var _pickaxe_wear_accum: float = 0.0 # Desgaste fracionado (desgasta na metade da velocidade)

# Níveis de Aprimoramento de Equipamentos na Forja (0 a UPGRADE_MAX_LEVEL)
var pickaxe_upgrade_level: int = 0 # +2 dano por golpe e +10% durabilidade por nível
var helmet_upgrade_level: int = 0 # +60 de luz por nível
var boots_upgrade_level: int = 0 # +0.20 pulo e +0.15 velocidade por nível
var armor_upgrade_level: int = 0 # +20 de carga por nível
var glove_upgrade_level: int = 0 # +1 força e +1 dano de chute por nível

# Nível e Progressão
var level: int = 0 # Começa no nível zero
var current_exp: int = 0 # EXP acumulada no nível atual

# Hotbar e Atalhos customizáveis
var active_slot: int = 0 # 0..4
var hotbar_slots: Array = ["pickaxe", "lamp"]

func _ready() -> void:
	ensure_hotbar_slots()

func ensure_hotbar_slots(count: int = 5) -> void:
	# Garante pelo menos 2 slots iniciais (picareta + poste)
	while hotbar_slots.size() < 2:
		var defaults = ["pickaxe", "lamp"]
		hotbar_slots.append(defaults[hotbar_slots.size() % defaults.size()])
	if hotbar_slots.size() > count:
		hotbar_slots = hotbar_slots.slice(0, count)

# Adiciona automaticamente um item forjado ao atalho se ainda não estiver lá
func _auto_add_hotbar(item_key: String) -> void:
	if item_key in hotbar_slots:
		return # Já está no atalho
	if hotbar_slots.size() >= 5:
		return # Atalho cheio (máx 5)
	hotbar_slots.append(item_key)
	inventory_changed.emit()

# Equipamentos Ativos e Posse
var equipped_helmet: String = "helmet_miner"
var equipped_pickaxe: String = "pickaxe_copper"
var equipped_armor: String = "armor_miner"
var equipped_boots: String = "boots_mud"
var equipped_glove: String = "glove_leather"

var owned_helmets: Array = ["helmet_miner"]
var owned_pickaxes: Array = ["pickaxe_copper"]
var owned_armors: Array = ["armor_miner"]
var owned_boots: Array = ["boots_mud"]
var owned_gloves: Array = ["glove_leather"]

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
		"color": Color(0.72, 0.68, 0.6),
		"icon": "helmet"
	},
	"helmet_lamp": {
		"id": "helmet_lamp",
		"name": "Capacete com Lanterna",
		"slot": "helmet",
		"desc": "Possui foco luminoso frontal acoplado para iluminar o subsolo.",
		"cost_coins": 150,
		"level_req": 3,
		"light_radius": 170.0,
		"color": Color(1.0, 0.85, 0.35),
		"icon": "helmet"
	},
	"helmet_iron_lamp": {
		"id": "helmet_iron_lamp",
		"name": "Capacete de Ferro Iluminado",
		"slot": "helmet",
		"desc": "Lanterna de alto alcance e casco blindado forjado em ferro espesso.",
		"cost_coins": 650,
		"level_req": 8,
		"light_radius": 240.0,
		"color": Color(0.88, 0.9, 0.95),
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
		"color": Color(0.86, 0.55, 0.3),
		"icon": "pickaxe"
	},
	"pickaxe_iron": {
		"id": "pickaxe_iron",
		"name": "Picareta de Ferro Reforçada",
		"slot": "pickaxe",
		"desc": "+60% de resistência. Durabilidade: 160 HP e corte 25% mais rápido.",
		"cost_coins": 400,
		"level_req": 6,
		"max_durability": 160,
		"mine_speed_mult": 1.25,
		"color": Color(0.68, 0.72, 0.8),
		"icon": "pickaxe"
	},
	"pickaxe_gold": {
		"id": "pickaxe_gold",
		"name": "Picareta de Ouro Nobre",
		"slot": "pickaxe",
		"desc": "Super resistente (+150%) e veloz. Durabilidade: 250 HP e corte 60% mais rápido.",
		"cost_coins": 1300,
		"level_req": 11,
		"max_durability": 250,
		"mine_speed_mult": 1.6,
		"color": Color(1.0, 0.82, 0.25),
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
		"color": Color(0.6, 0.52, 0.42),
		"icon": "armor"
	},
	"armor_reinforced": {
		"id": "armor_reinforced",
		"name": "Traje Reforçado",
		"slot": "armor",
		"desc": "Costura reforçada com bolsos extras (+20 carga: total 80).",
		"cost_coins": 220,
		"level_req": 5,
		"capacity_bonus": 20,
		"color": Color(0.78, 0.68, 0.5),
		"icon": "armor"
	},
	"armor_explorer": {
		"id": "armor_explorer",
		"name": "Traje do Explorador",
		"slot": "armor",
		"desc": "Mochila integrada de alta resistência (+40 carga: total 100).",
		"cost_coins": 800,
		"level_req": 10,
		"capacity_bonus": 40,
		"color": Color(0.48, 0.72, 0.55),
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
		"color": Color(0.55, 0.42, 0.3),
		"icon": "boots"
	},
	"boots_leather": {
		"id": "boots_leather",
		"name": "Botas de Couro Leves",
		"slot": "boots",
		"desc": "+15% de velocidade de corrida e +15% de altura no salto.",
		"cost_coins": 120,
		"level_req": 4,
		"jump_mult": 1.15,
		"speed_mult": 1.15,
		"color": Color(0.72, 0.5, 0.28),
		"icon": "boots"
	},
	"boots_steel": {
		"id": "boots_steel",
		"name": "Botas de Aço com Molas",
		"slot": "boots",
		"desc": "+25% de velocidade e +30% de altura de salto extraordinário.",
		"cost_coins": 550,
		"level_req": 9,
		"jump_mult": 1.30,
		"speed_mult": 1.25,
		"color": Color(0.82, 0.86, 0.92),
		"icon": "boots"
	},
	
	# LUVAS
	"glove_leather": {
		"id": "glove_leather",
		"name": "Luva de Couro",
		"slot": "glove",
		"desc": "Aumenta a força (+1) e gera dano no chute (+1) ao apertar [X] em blocos.",
		"cost_coins": 0,
		"level_req": 0,
		"strength_bonus": 1,
		"kick_damage": 1,
		"color": Color(0.7, 0.52, 0.32),
		"icon": "glove"
	},
	"glove_iron": {
		"id": "glove_iron",
		"name": "Luva de Ferro",
		"slot": "glove",
		"desc": "Manopla reforçada de ferro (+2 força, +2 dano de chute).",
		"cost_coins": 350,
		"level_req": 7,
		"strength_bonus": 2,
		"kick_damage": 2,
		"color": Color(0.6, 0.68, 0.75),
		"icon": "glove"
	},
	"glove_gold": {
		"id": "glove_gold",
		"name": "Luva de Ouro Nobre",
		"slot": "glove",
		"desc": "Luva resiliente banhada a ouro (+3 força, +3 dano de chute).",
		"cost_coins": 1100,
		"level_req": 12,
		"strength_bonus": 3,
		"kick_damage": 3,
		"color": Color(1.0, 0.82, 0.25),
		"icon": "glove"
	}
}

# Aprimoramentos de Equipamentos na Forja (Capacete, Picareta, Traje, Botas, Luvas)
const UPGRADE_MAX_LEVEL: int = 5
const UPGRADE_SLOTS: Array = ["helmet", "pickaxe", "armor", "boots", "glove"]

func get_upgrade_level(slot: String) -> int:
	match slot:
		"helmet": return helmet_upgrade_level
		"pickaxe": return pickaxe_upgrade_level
		"armor": return armor_upgrade_level
		"boots": return boots_upgrade_level
		"glove": return glove_upgrade_level
	return 0

func get_upgrade_display_name(slot: String) -> String:
	match slot:
		"helmet": return EQUIPMENT_DEFS.get(equipped_helmet, {}).get("name", "Capacete")
		"pickaxe": return EQUIPMENT_DEFS.get(equipped_pickaxe, {}).get("name", "Picareta")
		"armor": return EQUIPMENT_DEFS.get(equipped_armor, {}).get("name", "Traje")
		"boots": return EQUIPMENT_DEFS.get(equipped_boots, {}).get("name", "Botas")
		"glove": return EQUIPMENT_DEFS.get(equipped_glove, {}).get("name", "Luvas")
	return ""

func get_upgrade_cost(slot: String, tier: int) -> Dictionary:
	match slot:
		"pickaxe": return {"iron": tier * 2 + 1, "coal": tier}
		"helmet": return {"coal": tier * 2 + 1, "gold": tier}
		"armor": return {"wood": tier * 2 + 2, "iron": tier + 1}
		"boots": return {"iron": tier + 2, "plank": tier + 1}
		"glove": return {"stone": tier + 2, "iron": tier + 1}
		_: return {}

func get_upgrade_desc(slot: String, tier: int) -> String:
	match slot:
		"pickaxe":
			return "+1 Força (+2 de dano por golpe) e +10%% de Resistência (durabilidade). Nível %d" % tier
		"helmet":
			return "+60 de Alcance de Luz na escuridão. Nível %d" % tier
		"armor":
			return "+20 de Carga máxima na mochila. Nível %d" % tier
		"boots":
			return "+0.20 de Força de Pulo e +0.15 de Velocidade. Nível %d" % tier
		"glove":
			return "+1 de Força e +1 de Dano no Chute. Nível %d" % tier
		_: return ""

func build_forge_upgrade_rows() -> Array:
	var rows: Array = []
	for slot in UPGRADE_SLOTS:
		var cur_level: int = get_upgrade_level(slot)
		if cur_level >= UPGRADE_MAX_LEVEL:
			rows.append({
				"key": slot + "_max",
				"target_slot": slot,
				"tier": cur_level,
				"name": get_upgrade_display_name(slot),
				"desc": "Equipamento no nível máximo (%d/%d)." % [cur_level, UPGRADE_MAX_LEVEL],
				"cost": {},
				"level_req": 0,
				"exp_gain": 0,
				"maxed": true,
				"current_level": cur_level,
				"max_level": UPGRADE_MAX_LEVEL
			})
		else:
			var next_level: int = cur_level + 1
			var up_level_req: Array = [3, 5, 7, 9, 12]
			rows.append({
				"key": "%s_%d" % [slot, next_level],
				"target_slot": slot,
				"tier": next_level,
				"name": get_upgrade_display_name(slot),
				"desc": get_upgrade_desc(slot, next_level),
				"cost": get_upgrade_cost(slot, next_level),
				"level_req": up_level_req[next_level - 1] if next_level - 1 < up_level_req.size() else 12,
				"exp_gain": next_level * 30,
				"maxed": false,
				"current_level": cur_level,
				"max_level": UPGRADE_MAX_LEVEL
			})
	return rows

# Preços de Venda na Loja
const COAL_PRICE: int = 5
const IRON_PRICE: int = 15
const GOLD_PRICE: int = 50
const WOOD_PRICE: int = 8
const STONE_PRICE: int = 4
const DIRT_PRICE: int = 2
const PLANK_PRICE: int = 10
const LADDER_PRICE: int = 8
const BOMB_PRICE: int = 20

func get_max_capacity() -> int:
	var def = EQUIPMENT_DEFS.get(equipped_armor, {})
	var bonus = def.get("capacity_bonus", 0)
	return BASE_CAPACITY + bonus + (armor_upgrade_level * 20)

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
	_pickaxe_wear_accum += amount * 0.5
	var wear = int(_pickaxe_wear_accum)
	_pickaxe_wear_accum -= wear
	pickaxe_durability = max(0, pickaxe_durability - wear)
	inventory_changed.emit()
	if pickaxe_durability <= 0:
		has_pickaxe = false
		_pickaxe_wear_accum = 0.0
		pickaxe_broken.emit()
		notify("Sua picareta quebrou! Escave com as mãos ou forje uma nova.", "pickaxe")

# Equipment Getters
func get_equipped_def(slot: String) -> Dictionary:
	var id = ""
	match slot:
		"helmet": id = equipped_helmet
		"pickaxe": id = equipped_pickaxe
		"armor": id = equipped_armor
		"boots": id = equipped_boots
		"glove": id = equipped_glove
	return EQUIPMENT_DEFS.get(id, {})

func get_boots_speed_multiplier() -> float:
	var def = EQUIPMENT_DEFS.get(equipped_boots, {})
	var base_m = def.get("speed_mult", 1.0)
	return base_m + (boots_upgrade_level * 0.15)

func get_boots_jump_multiplier() -> float:
	var def = EQUIPMENT_DEFS.get(equipped_boots, {})
	var base_m = def.get("jump_mult", 1.0)
	return base_m + (boots_upgrade_level * 0.20)

func get_helmet_light_radius() -> float:
	var def = EQUIPMENT_DEFS.get(equipped_helmet, {})
	var base_r = def.get("light_radius", 110.0)
	return base_r + (helmet_upgrade_level * 60.0)

func get_pickaxe_speed_multiplier() -> float:
	var def = EQUIPMENT_DEFS.get(equipped_pickaxe, {})
	return def.get("mine_speed_mult", 1.0) * (1.0 + pickaxe_upgrade_level * 0.10)

func get_pickaxe_damage() -> int:
	if not has_pickaxe: return 1
	return 1 + pickaxe_upgrade_level * 2

func get_strength() -> int:
	return get_pickaxe_damage() + get_glove_def().get("strength_bonus", 0) + glove_upgrade_level

func get_glove_def() -> Dictionary:
	return EQUIPMENT_DEFS.get(equipped_glove, {})

func get_glove_kick_damage() -> int:
	return int(get_glove_def().get("kick_damage", 0)) + glove_upgrade_level

func get_pickaxe_max_durability() -> int:
	var def = EQUIPMENT_DEFS.get(equipped_pickaxe, {})
	var base_dur = def.get("max_durability", 100)
	return int(base_dur * (1.0 + pickaxe_upgrade_level * 0.10))

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
			max_pickaxe_durability = get_pickaxe_max_durability()
			pickaxe_durability = max_pickaxe_durability
			has_pickaxe = true
		"armor":
			if not item_id in owned_armors: return false
			equipped_armor = item_id
		"boots":
			if not item_id in owned_boots: return false
			equipped_boots = item_id
		"glove":
			if not item_id in owned_gloves: return false
			equipped_glove = item_id
	inventory_changed.emit()
	notify("Equipado: %s" % def.name, def.get("icon", "equip"))
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").request_save()
	return true

func buy_shop_item(item_id: String) -> bool:
	if item_id == "bomb":
		if coins < BOMB_PRICE:
			notify("Moedas insuficientes!", "coin_gold")
			return false
		coins -= BOMB_PRICE
		bombs += 1
		add_exp(10)
		inventory_changed.emit()
		notify("+1 Bomba Adquirida!", "chest")
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true

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
		"glove":
			if item_id in owned_gloves: return false
			owned_gloves.append(item_id)
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
	var slot = upgrade.get("target_slot", "")
	var tier = upgrade.get("tier", 1)
	
	if slot == "pickaxe" and pickaxe_upgrade_level >= tier: return false
	elif slot == "helmet" and helmet_upgrade_level >= tier: return false
	elif slot == "boots" and boots_upgrade_level >= tier: return false
	elif slot == "armor" and armor_upgrade_level >= tier: return false
	elif slot == "glove" and glove_upgrade_level >= tier: return false
			
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

func execute_forge_upgrade_def(up_def: Dictionary) -> bool:
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
		
	var slot = up_def.get("target_slot", "")
	var tier = up_def.get("tier", 1)
	if slot == "pickaxe":
		pickaxe_upgrade_level = max(pickaxe_upgrade_level, tier)
		max_pickaxe_durability = get_pickaxe_max_durability()
		pickaxe_durability = max_pickaxe_durability
		has_pickaxe = true
	elif slot == "helmet":
		helmet_upgrade_level = max(helmet_upgrade_level, tier)
	elif slot == "boots":
		boots_upgrade_level = max(boots_upgrade_level, tier)
	elif slot == "armor":
		armor_upgrade_level = max(armor_upgrade_level, tier)
	elif slot == "glove":
		glove_upgrade_level = max(glove_upgrade_level, tier)
			
	add_exp(up_def.get("exp_gain", 40))
	inventory_changed.emit()
	notify("Equipamento Aprimorado!", "equip")
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

# Receitas de Forja (Criar Itens)
func can_craft_pickaxe() -> bool:
	return iron >= 1 and wood_logs >= 2 and stone >= 1

func craft_pickaxe() -> bool:
	if can_craft_pickaxe():
		iron -= 1
		wood_logs -= 2
		stone -= 1
		max_pickaxe_durability = get_pickaxe_max_durability()
		if has_pickaxe and pickaxe_durability > 0:
			pickaxe_durability += max_pickaxe_durability
			notify("Picareta reforçada! +%d de Resistência (%d/%d)" % [max_pickaxe_durability, pickaxe_durability, max_pickaxe_durability], "pickaxe")
		else:
			has_pickaxe = true
			pickaxe_durability = max_pickaxe_durability
			notify("Nova Picareta Forjada!", "pickaxe")
		add_exp(20)
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
		add_exp(15)
		inventory_changed.emit()
		_auto_add_hotbar("lamp")
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
		_auto_add_hotbar("ladder")
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
		_auto_add_hotbar("plank")
		notify("+5 Tábuas Forjadas!", "wood")
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	return false

func can_craft_column() -> bool:
	return dirt >= 3 and stone >= 3

func craft_column() -> bool:
	if can_craft_column():
		dirt -= 3
		stone -= 3
		columns += 1
		add_exp(8)
		inventory_changed.emit()
		_auto_add_hotbar("column")
		notify("+1 Coluna de Suporte Forjada!", "plank")
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	return false

func can_craft_slab() -> bool:
	return dirt >= 2 and stone >= 2

func craft_slab() -> bool:
	if can_craft_slab():
		dirt -= 2
		stone -= 2
		slabs += 1
		add_exp(8)
		inventory_changed.emit()
		_auto_add_hotbar("slab")
		notify("+1 Laje de Tijolos Forjada!", "plank")
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	return false

func can_craft_portable_forge() -> bool:
	return dirt >= 5 and stone >= 4 and iron >= 2

func craft_portable_forge() -> bool:
	if can_craft_portable_forge():
		dirt -= 5
		stone -= 4
		iron -= 2
		portable_forges += 1
		add_exp(30)
		inventory_changed.emit()
		_auto_add_hotbar("forge")
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

func get_active_item_key() -> String:
	if active_slot >= 0 and active_slot < hotbar_slots.size():
		return hotbar_slots[active_slot]
	return "pickaxe"

func get_current_load() -> int:
	return iron + gold + coal

func is_full() -> bool:
	return get_current_load() >= get_max_capacity()

func can_add(type = null, amount: int = 1) -> bool:
	return (get_current_load() + amount) <= get_max_capacity()

func can_add_item(type, amount: int = 1) -> bool:
	if type in ["iron", "gold", "coal", 0, 1, 2]:
		return (get_current_load() + amount) <= get_max_capacity()
	return true

func add_resource(type, amount: int = 1) -> bool:
	if type is int:
		match type:
			0: return add_item("iron", amount)
			1: return add_item("gold", amount)
			2: return add_item("coal", amount)
			3: return add_item("plank", amount)
			4: return add_item("lamp", amount)
			5: return add_item("wood", amount)
			6: return add_item("ladder", amount)
			7: return add_item("stone", amount)
			8: return add_item("dirt", amount)
			9: return add_item("broken_pickaxe", amount)
			10: return add_item("forge", amount)
			_: return false
	elif type is String:
		return add_item(type, amount)
	return false

func add_wood(amount: int = 1) -> void:
	add_item("wood", amount)

func add_starter_lamp(amount: int = 1) -> void:
	add_item("lamp", amount)

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
		notify("+" + str(amount) + " Lama", "dirt")
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
	elif type == "column":
		columns += amount
		notify("+" + str(amount) + " Coluna de Suporte", "plank")
		inventory_changed.emit()
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	elif type == "slab":
		slabs += amount
		notify("+" + str(amount) + " Laje de Tijolos", "plank")
		inventory_changed.emit()
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
		return true
	elif type == "bomb":
		bombs += amount
		notify("+%d Bomba!" % amount, "chest")
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
	columns = 0
	slabs = 0
	portable_forges = 0
	bombs = 0
	has_pickaxe = true
	pickaxe_durability = 100
	max_pickaxe_durability = 100
	_pickaxe_wear_accum = 0.0
	pickaxe_upgrade_level = 0
	helmet_upgrade_level = 0
	boots_upgrade_level = 0
	armor_upgrade_level = 0
	glove_upgrade_level = 0
	level = 0
	current_exp = 0
	active_slot = 0
	hotbar_slots = ["pickaxe", "lamp"]
	equipped_helmet = "helmet_miner"
	equipped_pickaxe = "pickaxe_copper"
	equipped_armor = "armor_miner"
	equipped_boots = "boots_mud"
	equipped_glove = "glove_leather"
	owned_helmets = ["helmet_miner"]
	owned_pickaxes = ["pickaxe_copper"]
	owned_armors = ["armor_miner"]
	owned_boots = ["boots_mud"]
	owned_gloves = ["glove_leather"]
	inventory_changed.emit()
