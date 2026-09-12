extends CanvasLayer

func _safe_grab_focus(ctrl: Control) -> void:
	if is_instance_valid(ctrl):
		if ctrl.focus_mode == Control.FOCUS_NONE:
			ctrl.focus_mode = Control.FOCUS_ALL
		ctrl.grab_focus()

@onready var hotbar = find_child("HotbarVisual", true, false)
@onready var capacity_badge_label = find_child("CapacityLabel", true, false)
@onready var inventory_panel = find_child("InventoryPanel", true, false)
@onready var close_button = find_child("CloseButton", true, false)
@onready var chest_grid = find_child("ChestGrid", true, false)
@onready var item_title = find_child("ItemTitle", true, false)
@onready var item_desc = find_child("ItemDesc", true, false)
@onready var equip_button = find_child("EquipButton", true, false)
@onready var drop_button = find_child("DropButton", true, false)
@onready var capacity_label = find_child("CapacityLabel", true, false)
@onready var shop_button = find_child("ShopButton", true, false)
@onready var pause_button = find_child("PauseButton", true, false)
@onready var toast_list = find_child("ToastList", true, false)

# Equipment Menu nodes
@onready var equipment_panel = find_child("EquipmentPanel", true, false)
@onready var equip_close_btn = find_child("EquipCloseButton", true, false)

# Shop Menu nodes
@onready var shop_panel = find_child("ShopPanel", true, false)
@onready var shop_coins_label = find_child("ShopCoinsLabel", true, false)
@onready var shop_close_btn = find_child("ShopCloseButton", true, false)
@onready var shop_tab_buy_btn = find_child("ShopTabBuyBtn", true, false)
@onready var shop_tab_sell_btn = find_child("ShopTabSellBtn", true, false)
@onready var shop_buy_view = find_child("ShopBuyView", true, false)
@onready var shop_sell_view = find_child("ShopSellView", true, false)

# Chest Menu nodes
@onready var chest_panel = find_child("ChestPanel", true, false)
@onready var chest_close_btn = find_child("ChestCloseBtn", true, false)
@onready var chest_close_footer_btn = find_child("ChestCloseFooterBtn", true, false)
@onready var chest_deposit_btn = find_child("ChestDepositBtn", true, false)
@onready var chest_retrieve_btn = find_child("ChestRetrieveBtn", true, false)
@onready var chest_coal_lbl = find_child("ChestCoalLabel", true, false)
@onready var chest_iron_lbl = find_child("ChestIronLabel", true, false)
@onready var chest_gold_lbl = find_child("ChestGoldLabel", true, false)
@onready var backpack_coal_lbl = find_child("BackpackCoalLabel", true, false)
@onready var backpack_iron_lbl = find_child("BackpackIronLabel", true, false)
@onready var backpack_gold_lbl = find_child("BackpackGoldLabel", true, false)
var current_chest_node: Node = null

# Pause Menu nodes
@onready var pause_panel = find_child("PausePanel", true, false)
@onready var resume_btn = find_child("ResumeBtn", true, false)
@onready var save_btn = find_child("SaveBtn", true, false)
@onready var restart_btn = find_child("RestartBtn", true, false)
@onready var exit_btn = find_child("ExitBtn", true, false)

var slots: Array = []
var chest_slots: Array = []
var selected_index: int = 0
var drag_start_idx: int = -1

var extras_tex = preload("res://assets/Caves and Mines/extras.png")
var ores_tex = preload("res://assets/Caves and Mines/ores.png")
var rope_tex = preload("res://assets/sprites/rope_tile.png")
var lamp_tex = preload("res://assets/sprites/lamp_post.png")
var plank_tex = preload("res://assets/sprites/plank.png")
var coin_gold_tex = preload("res://assets/sprites/coin_gold.png")
var coin_silver_tex = preload("res://assets/sprites/coin_silver.png")
var coin_copper_tex = preload("res://assets/sprites/coin_copper.png")
var wood_tex = preload("res://assets/sprites/wood_log.png")

# Coins HUD
@onready var coins_badge_container = find_child("CoinsBadgeContainer", true, false)
@onready var coins_hud_label = find_child("CoinsLabel", true, false)

# Profile Badge & EXP HUD
@onready var profile_badge_container = find_child("ProfileBadgeContainer", true, false)
@onready var avatar_rect = find_child("AvatarRect", true, false)
@onready var level_badge_label = find_child("LevelBadgeLabel", true, false)
@onready var exp_progress_bar = find_child("ExpProgressBar", true, false)
@onready var level_up_panel = find_child("LevelUpPanel", true, false)
@onready var level_up_title = find_child("LevelUpTitle", true, false)
@onready var level_up_subtitle = find_child("LevelUpSubtitle", true, false)
@onready var craft_brick_floor_btn = find_child("CraftBrickFloorBtn", true, false)

# Forge Menu nodes
@onready var forge_panel = find_child("ForgePanel", true, false)
@onready var forge_close_btn = find_child("ForgeCloseBtn", true, false)
@onready var forge_close_footer_btn = find_child("ForgeCloseFooterBtn", true, false)
@onready var craft_lamp_btn = find_child("CraftLampBtn", true, false)
@onready var craft_ladder_btn = find_child("CraftLadderBtn", true, false)
@onready var craft_plank_btn = find_child("CraftPlankBtn", true, false)
var current_forge_node: Node = null

# Pause Menu Reset
@onready var reset_mine_btn = find_child("ResetMineBtn", true, false)

# Equipment Idle Animation
var idle_anim_timer: float = 0.0
var idle_anim_frame: int = 0

var chest_items_def = [
	{
		"key": "pickaxe",
		"name": "Picareta de Ferro",
		"desc": "Ferramenta para escavar terra e rochas. Pressione [1] para equipar (Botão Z para minerar).",
		"icon_type": "atlas",
		"atlas": "extras",
		"region": Rect2(0, 0, 16, 16),
		"shortcut": "1",
		"is_tool": true,
		"tool_slot": 0
	},
	{
		"key": "lamp",
		"name": "Mini Poste de Luz",
		"desc": "Lampião portátil que ilumina a caverna e faz os minérios brilharem no escuro. Custa 3 Carvões + 2 Ferros. Pressione [2].",
		"icon_type": "atlas",
		"atlas": "lamp",
		"region": Rect2(0, 0, 16, 16),
		"shortcut": "2",
		"is_tool": true,
		"tool_slot": 1
	},
	{
		"key": "ladder",
		"name": "Escada de Madeira",
		"desc": "Escada portátil com degraus para descer e subir poços profundos. Pressione [3] para equipar.",
		"icon_type": "direct",
		"tex": "rope",
		"shortcut": "3",
		"is_tool": true,
		"tool_slot": 2
	},
	{
		"key": "plank",
		"name": "Tábua de Madeira",
		"desc": "Ponte horizontal sólida para cruzar fendas e abismos. Pressione [4] para equipar e [Z] para construir.",
		"icon_type": "direct",
		"tex": "plank",
		"shortcut": "4",
		"is_tool": true,
		"tool_slot": 3
	},
	{
		"key": "iron",
		"name": "Minério de Ferro",
		"desc": "Metal versátil e resistente obtido nas profundezas. Usado na construção de postes e melhorias futuras.",
		"icon_type": "atlas",
		"atlas": "ores",
		"region": Rect2(32, 128, 16, 16),
		"shortcut": "",
		"is_tool": false
	},
	{
		"key": "gold",
		"name": "Minério de Ouro",
		"desc": "Metal nobre e reluzente de alto valor comercial e grande raridade. Guarde seus ouros para comprar itens na Loja.",
		"icon_type": "atlas",
		"atlas": "ores",
		"region": Rect2(128, 128, 16, 16),
		"shortcut": "",
		"is_tool": false
	},
	{
		"key": "coal",
		"name": "Carvão Mineral",
		"desc": "Combustível fóssil primordial abundante. Usado na forja e consumido na instalação de postes de luz.",
		"icon_type": "atlas",
		"atlas": "ores",
		"region": Rect2(0, 128, 16, 16),
		"shortcut": "",
		"is_tool": false
	}
]

var inventory_override: Node = null

func _get_inv() -> Node:
	if inventory_override:
		return inventory_override
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("Inventory"):
		return get_tree().root.get_node("Inventory")
	var loop = Engine.get_main_loop()
	if loop and "root" in loop and loop.root and loop.root.has_node("Inventory"):
		return loop.root.get_node("Inventory")
	return null


func _process(delta: float) -> void:
	if is_instance_valid(equipment_panel) and equipment_panel.visible:
		idle_anim_timer += delta
		if idle_anim_timer >= 0.1: # 10 FPS
			idle_anim_timer = 0.0
			idle_anim_frame = (idle_anim_frame + 1) % 16
			var char_rect = find_child("CharTextureRect", true, false)
			if char_rect and char_rect.texture is AtlasTexture:
				char_rect.texture.region = Rect2(idle_anim_frame * 32.0, 0, 32.0, 30.0)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var inv = _get_inv()
	if inv:
		if not inv.inventory_changed.is_connected(update_ui):
			inv.inventory_changed.connect(update_ui)
		if not inv.notification_triggered.is_connected(show_toast):
			inv.notification_triggered.connect(show_toast)
	
	setup_hotbar()
	setup_chest_grid()
	
	if close_button and not close_button.pressed.is_connected(close_inventory):
		close_button.pressed.connect(close_inventory)
	if equip_close_btn and not equip_close_btn.pressed.is_connected(close_equipment):
		equip_close_btn.pressed.connect(close_equipment)
	if equip_button and not equip_button.pressed.is_connected(_on_equip_pressed):
		equip_button.pressed.connect(_on_equip_pressed)
	if drop_button and not drop_button.pressed.is_connected(_on_drop_pressed):
		drop_button.pressed.connect(_on_drop_pressed)
	if shop_button and not shop_button.pressed.is_connected(_on_shop_pressed):
		shop_button.pressed.connect(_on_shop_pressed)
	if shop_close_btn and not shop_close_btn.pressed.is_connected(close_shop):
		shop_close_btn.pressed.connect(close_shop)
	if shop_tab_buy_btn and not shop_tab_buy_btn.pressed.is_connected(_on_shop_tab_buy):
		shop_tab_buy_btn.pressed.connect(_on_shop_tab_buy)
	if shop_tab_sell_btn and not shop_tab_sell_btn.pressed.is_connected(_on_shop_tab_sell):
		shop_tab_sell_btn.pressed.connect(_on_shop_tab_sell)

	var sell_coal_1 = find_child("SellCoalOneBtn", true, false)
	if sell_coal_1 and not sell_coal_1.pressed.is_connected(_on_sell_coal_one): sell_coal_1.pressed.connect(_on_sell_coal_one)
	var sell_coal_all = find_child("SellCoalAllBtn", true, false)
	if sell_coal_all and not sell_coal_all.pressed.is_connected(_on_sell_coal_all): sell_coal_all.pressed.connect(_on_sell_coal_all)

	var sell_iron_1 = find_child("SellIronOneBtn", true, false)
	if sell_iron_1 and not sell_iron_1.pressed.is_connected(_on_sell_iron_one): sell_iron_1.pressed.connect(_on_sell_iron_one)
	var sell_iron_all = find_child("SellIronAllBtn", true, false)
	if sell_iron_all and not sell_iron_all.pressed.is_connected(_on_sell_iron_all): sell_iron_all.pressed.connect(_on_sell_iron_all)

	var sell_gold_1 = find_child("SellGoldOneBtn", true, false)
	if sell_gold_1 and not sell_gold_1.pressed.is_connected(_on_sell_gold_one): sell_gold_1.pressed.connect(_on_sell_gold_one)
	var sell_gold_all = find_child("SellGoldAllBtn", true, false)
	if sell_gold_all and not sell_gold_all.pressed.is_connected(_on_sell_gold_all): sell_gold_all.pressed.connect(_on_sell_gold_all)

	var sell_all_btn = find_child("SellAllMineralsBtn", true, false)
	if sell_all_btn and not sell_all_btn.pressed.is_connected(_on_sell_all_minerals): sell_all_btn.pressed.connect(_on_sell_all_minerals)

	if pause_button and not pause_button.pressed.is_connected(toggle_pause):
		pause_button.pressed.connect(toggle_pause)
		
	if resume_btn and not resume_btn.pressed.is_connected(close_pause):
		resume_btn.pressed.connect(close_pause)
	if save_btn and not save_btn.pressed.is_connected(_on_save_pressed):
		save_btn.pressed.connect(_on_save_pressed)
	if restart_btn and not restart_btn.pressed.is_connected(_on_restart_pressed):
		restart_btn.pressed.connect(_on_restart_pressed)
	if exit_btn and not exit_btn.pressed.is_connected(_on_exit_pressed):
		exit_btn.pressed.connect(_on_exit_pressed)
		
	if chest_close_btn and not chest_close_btn.pressed.is_connected(close_chest):
		chest_close_btn.pressed.connect(close_chest)
	if chest_close_footer_btn and not chest_close_footer_btn.pressed.is_connected(close_chest):
		chest_close_footer_btn.pressed.connect(close_chest)
	if chest_deposit_btn and not chest_deposit_btn.pressed.is_connected(_on_chest_deposit):
		chest_deposit_btn.pressed.connect(_on_chest_deposit)
	if chest_retrieve_btn and not chest_retrieve_btn.pressed.is_connected(_on_chest_retrieve):
		chest_retrieve_btn.pressed.connect(_on_chest_retrieve)
		
	if reset_mine_btn and not reset_mine_btn.pressed.is_connected(_on_reset_mine_pressed):
		reset_mine_btn.pressed.connect(_on_reset_mine_pressed)
	if forge_close_btn and not forge_close_btn.pressed.is_connected(close_forge):
		forge_close_btn.pressed.connect(close_forge)
	if forge_close_footer_btn and not forge_close_footer_btn.pressed.is_connected(close_forge):
		forge_close_footer_btn.pressed.connect(close_forge)
	if craft_lamp_btn and not craft_lamp_btn.pressed.is_connected(_on_craft_lamp):
		craft_lamp_btn.pressed.connect(_on_craft_lamp)
	if craft_ladder_btn and not craft_ladder_btn.pressed.is_connected(_on_craft_ladder):
		craft_ladder_btn.pressed.connect(_on_craft_ladder)
	if craft_plank_btn and not craft_plank_btn.pressed.is_connected(_on_craft_plank):
		craft_plank_btn.pressed.connect(_on_craft_plank)
	if not craft_brick_floor_btn:
		craft_brick_floor_btn = find_child("CraftBrickFloorBtn", true, false)
	if craft_brick_floor_btn and not craft_brick_floor_btn.pressed.is_connected(_on_craft_brick_floor):
		craft_brick_floor_btn.pressed.connect(_on_craft_brick_floor)
	if inv:
		if inv.has_signal("level_up") and not inv.level_up.is_connected(_on_level_up):
			inv.level_up.connect(_on_level_up)
		
	select_slot(0)
	update_ui()

func _consume_input() -> void:
	if is_inside_tree() and get_viewport():
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Toggle Equipment Menu with [E]
		if event.physical_keycode == KEY_E or event.is_action_pressed("action_equip_menu"):
			toggle_equipment()
			_consume_input()
			return

		# Toggle Pause Menu with [P] or [Esc]
		if event.physical_keycode == KEY_P or event.physical_keycode == KEY_ESCAPE:
			if is_instance_valid(forge_panel) and forge_panel.visible:
				close_forge()
				_consume_input()
				return
			elif is_instance_valid(chest_panel) and chest_panel.visible:
				close_chest()
				_consume_input()
				return
			elif is_instance_valid(equipment_panel) and equipment_panel.visible:
				close_equipment()
				_consume_input()
				return
			elif is_instance_valid(shop_panel) and shop_panel.visible:
				close_shop()
				_consume_input()
				return
			elif is_instance_valid(inventory_panel) and inventory_panel.visible:
				close_inventory()
				_consume_input()
				return
			else:
				toggle_pause()
				_consume_input()
				return

		# Universal Close on [X] for any open modal
		if event.physical_keycode == KEY_X:
			if is_instance_valid(shop_panel) and shop_panel.visible:
				close_shop()
				_consume_input()
				return
			elif is_instance_valid(forge_panel) and forge_panel.visible:
				close_forge()
				_consume_input()
				return
			elif is_instance_valid(chest_panel) and chest_panel.visible:
				close_chest()
				_consume_input()
				return
			elif is_instance_valid(equipment_panel) and equipment_panel.visible:
				close_equipment()
				_consume_input()
				return
			elif is_instance_valid(inventory_panel) and inventory_panel.visible:
				close_inventory()
				_consume_input()
				return

		# Universal Confirm on [Z] for any open modal with focused button
		if event.physical_keycode == KEY_Z:
			var focus_node = get_viewport().gui_get_focus_owner() if get_viewport() else null
			if focus_node and (focus_node is BaseButton) and focus_node.is_inside_tree() and focus_node.visible:
				focus_node.pressed.emit()
				_consume_input()
				return
			elif is_instance_valid(shop_panel) and shop_panel.visible and is_instance_valid(shop_sell_view) and shop_sell_view.visible:
				_on_sell_all_minerals()
				_consume_input()
				return
			elif is_instance_valid(chest_panel) and chest_panel.visible:
				_on_chest_deposit()
				_consume_input()
				return
				
		# Hotkeys inside Pause Menu
		if is_instance_valid(pause_panel) and pause_panel.visible:
			if event.physical_keycode == KEY_S:
				_consume_input()
				_on_save_pressed()
				return
			elif event.physical_keycode == KEY_R:
				_consume_input()
				_on_restart_pressed()
				return
			elif event.physical_keycode == KEY_Q:
				_consume_input()
				_on_exit_pressed()
				return
	
	# Open Shop with [L]
	if (not pause_panel or not pause_panel.visible) and (event.is_action_pressed("shop_menu") or (event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_L)):
		toggle_shop()
		_consume_input()
		return

	# Shop Tab Switching with Left/Right Arrows
	if is_instance_valid(shop_panel) and shop_panel.visible and (not pause_panel or not pause_panel.visible):
		if event.is_action_pressed("ui_left"):
			switch_shop_tab("buy")
			if is_instance_valid(shop_tab_buy_btn): _safe_grab_focus(shop_tab_buy_btn)
			_consume_input()
			return
		elif event.is_action_pressed("ui_right"):
			switch_shop_tab("sell")
			if is_instance_valid(shop_tab_sell_btn): _safe_grab_focus(shop_tab_sell_btn)
			_consume_input()
			return

	# Inventory Keyboard Navigation
	if is_instance_valid(inventory_panel) and inventory_panel.visible and (not pause_panel or not pause_panel.visible):
		if event.is_action_pressed("ui_right"):
			_nav_grid(1, 0)
			_consume_input()
		elif event.is_action_pressed("ui_left"):
			_nav_grid(-1, 0)
			_consume_input()
		elif event.is_action_pressed("ui_down"):
			_nav_grid(0, 1)
			_consume_input()
		elif event.is_action_pressed("ui_up"):
			_nav_grid(0, -1)
			_consume_input()
		elif event.is_action_pressed("action_mine") or event.is_action_pressed("ui_accept"):
			_on_equip_pressed()
			_consume_input()
		elif event.is_action_pressed("action_drag") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_X):
			_on_drop_pressed()
			_consume_input()

func toggle_equipment() -> void:
	if is_instance_valid(equipment_panel) and equipment_panel.visible:
		close_equipment()
	else:
		open_equipment()

func open_equipment() -> void:
	if is_instance_valid(forge_panel) and forge_panel.visible:
		close_forge()
	if is_instance_valid(chest_panel) and chest_panel.visible:
		close_chest()
	if is_instance_valid(inventory_panel) and inventory_panel.visible:
		close_inventory()
	if is_instance_valid(shop_panel) and shop_panel.visible:
		close_shop()
	if is_instance_valid(pause_panel) and pause_panel.visible:
		close_pause()
	if is_instance_valid(equipment_panel):
		equipment_panel.visible = true
		if is_instance_valid(equip_close_btn):
			_safe_grab_focus(equip_close_btn)

func close_equipment() -> void:
	if is_instance_valid(equipment_panel):
		equipment_panel.visible = false

func toggle_pause() -> void:
	if is_instance_valid(pause_panel) and pause_panel.visible:
		close_pause()
	else:
		open_pause()

func open_pause() -> void:
	if is_instance_valid(forge_panel) and forge_panel.visible:
		close_forge()
	if is_instance_valid(chest_panel) and chest_panel.visible:
		close_chest()
	if is_instance_valid(inventory_panel) and inventory_panel.visible:
		close_inventory()
	if is_instance_valid(equipment_panel) and equipment_panel.visible:
		close_equipment()
	if is_instance_valid(shop_panel) and shop_panel.visible:
		close_shop()
	if is_instance_valid(pause_panel):
		pause_panel.visible = true
	if is_inside_tree() and get_tree():
		get_tree().paused = true
	if is_inside_tree() and is_instance_valid(resume_btn):
		_safe_grab_focus(resume_btn)

func close_pause() -> void:
	if is_instance_valid(pause_panel):
		pause_panel.visible = false
	if is_inside_tree() and get_tree():
		get_tree().paused = false

func _on_save_pressed() -> void:
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("SaveManager"):
		get_tree().root.get_node("SaveManager").save_game(true)
	else:
		show_toast("Progresso Salvo!", "save")


func toggle_forge(forge_node: Node = null) -> void:
	if is_instance_valid(forge_panel) and forge_panel.visible:
		close_forge()
	else:
		open_forge(forge_node)

func open_forge(forge_node: Node = null) -> void:
	if forge_node:
		current_forge_node = forge_node
	elif not is_instance_valid(current_forge_node):
		if is_inside_tree() and get_tree() and get_tree().current_scene:
			current_forge_node = get_tree().current_scene.get_node_or_null("Forge")
			
	if is_instance_valid(chest_panel) and chest_panel.visible: close_chest()
	if is_instance_valid(inventory_panel) and inventory_panel.visible: close_inventory()
	if is_instance_valid(equipment_panel) and equipment_panel.visible: close_equipment()
	if is_instance_valid(shop_panel) and shop_panel.visible: close_shop()
	if is_instance_valid(pause_panel) and pause_panel.visible: close_pause()
	
	if is_instance_valid(forge_panel):
		forge_panel.visible = true
		update_forge_ui()
		if is_instance_valid(craft_lamp_btn):
			_safe_grab_focus(craft_lamp_btn)

func close_forge() -> void:
	if is_instance_valid(forge_panel):
		forge_panel.visible = false

func update_forge_ui() -> void:
	var inv = _get_inv()
	if not inv: return
	var mat_lbl = find_child("MaterialsLabel", true, false)
	if mat_lbl:
		mat_lbl.text = "🪵 Troncos: %d  |  🪨 Carvão: %d  |  ⛓️ Ferro: %d  |  🟫 Lama: %d  |  🗿 Pedra: %d" % [
			inv.wood_logs if "wood_logs" in inv else 0,
			inv.coal,
			inv.iron,
			inv.dirt if "dirt" in inv else 0,
			inv.stone if "stone" in inv else 0
		]
	var btn_lamp = find_child("CraftLampBtn", true, false)
	if btn_lamp:
		btn_lamp.disabled = not (inv.has_method("can_craft_lamp") and inv.can_craft_lamp())
	var btn_ladder = find_child("CraftLadderBtn", true, false)
	if btn_ladder:
		btn_ladder.disabled = not (inv.has_method("can_craft_ladders") and inv.can_craft_ladders())
	var btn_plank = find_child("CraftPlankBtn", true, false)
	if btn_plank:
		btn_plank.disabled = not (inv.has_method("can_craft_planks") and inv.can_craft_planks())
	var btn_brick = find_child("CraftBrickFloorBtn", true, false)
	if btn_brick:
		btn_brick.disabled = not (inv.has_method("can_craft_brick_floor") and inv.can_craft_brick_floor())

func _on_craft_lamp() -> void:
	var inv = _get_inv()
	if inv and inv.has_method("craft_lamp"):
		inv.craft_lamp()
		update_forge_ui()
		update_ui()

func _on_craft_ladder() -> void:
	var inv = _get_inv()
	if inv and inv.has_method("craft_ladders"):
		inv.craft_ladders()
		update_forge_ui()
		update_ui()

func _on_craft_plank() -> void:
	var inv = _get_inv()
	if inv and inv.has_method("craft_planks"):
		inv.craft_planks()
		update_forge_ui()
		update_ui()

func _on_craft_brick_floor() -> void:
	var inv = _get_inv()
	if inv and inv.has_method("craft_brick_floor"):
		inv.craft_brick_floor()
		update_forge_ui()
		update_ui()

func _on_level_up(new_level: int, exp_needed_next: int) -> void:
	show_level_up_vfx(new_level, exp_needed_next)

func show_level_up_vfx(new_level: int, exp_needed_next: int) -> void:
	if not is_instance_valid(level_up_panel):
		level_up_panel = find_child("LevelUpPanel", true, false)
	if not is_instance_valid(level_up_panel): return
	if not is_instance_valid(level_up_title):
		level_up_title = find_child("LevelUpTitle", true, false)
	if not is_instance_valid(level_up_subtitle):
		level_up_subtitle = find_child("LevelUpSubtitle", true, false)
		
	if is_instance_valid(level_up_title):
		level_up_title.text = "⭐ NÍVEL %d ALCANÇADO! ⭐" % new_level
	if is_instance_valid(level_up_subtitle):
		level_up_subtitle.text = "Próximo Nível: %d EXP" % exp_needed_next
		
	level_up_panel.visible = true
	level_up_panel.modulate.a = 0.0
	level_up_panel.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.tween_property(level_up_panel, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(level_up_panel, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.0)
	tween.tween_property(level_up_panel, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func(): if is_instance_valid(level_up_panel): level_up_panel.visible = false)

func _on_reset_mine_pressed() -> void:
	if is_inside_tree() and get_tree():
		get_tree().paused = false
		if is_instance_valid(pause_panel): pause_panel.visible = false
		if is_instance_valid(shop_panel): shop_panel.visible = false
		if is_instance_valid(equipment_panel): equipment_panel.visible = false
		if is_instance_valid(inventory_panel): inventory_panel.visible = false
		if is_instance_valid(chest_panel): chest_panel.visible = false
		if is_instance_valid(forge_panel): forge_panel.visible = false
		if get_tree().root and get_tree().root.has_node("SaveManager"):
			get_tree().root.get_node("SaveManager").reset_mine_completely()
		else:
			get_tree().reload_current_scene()

func _on_restart_pressed() -> void:
	if is_inside_tree() and get_tree():
		get_tree().paused = false
		if is_instance_valid(pause_panel):
			pause_panel.visible = false
		if is_instance_valid(shop_panel):
			shop_panel.visible = false
		if is_instance_valid(equipment_panel):
			equipment_panel.visible = false
		if is_instance_valid(inventory_panel):
			inventory_panel.visible = false
		if get_tree().root and get_tree().root.has_node("SaveManager"):
			get_tree().root.get_node("SaveManager").restart_run_to_surface()
		get_tree().reload_current_scene()

func _on_exit_pressed() -> void:
	if is_inside_tree() and get_tree():
		get_tree().paused = false
		if OS.has_feature("pc") and not OS.has_feature("web"):
			get_tree().quit()
		else:
			get_tree().change_scene_to_file("res://scenes/ui/start_screen.tscn")

func _nav_grid(dx: int, dy: int) -> void:
	var total = chest_items_def.size()
	var cols = 4
	var cur_col = selected_index % cols
	var cur_row = selected_index / cols
	
	var new_col = clamp(cur_col + dx, 0, cols - 1)
	var new_row = clamp(cur_row + dy, 0, (total - 1) / cols)
	var new_idx = new_row * cols + new_col
	
	if new_idx < total and new_idx != selected_index:
		select_slot(new_idx)

func _on_shop_pressed() -> void:
	if shop_button:
		var tween = create_tween()
		tween.tween_property(shop_button, "scale", Vector2(1.15, 1.15), 0.08)
		tween.tween_property(shop_button, "scale", Vector2.ONE, 0.08)
	toggle_shop()

func toggle_shop() -> void:
	if is_instance_valid(shop_panel) and shop_panel.visible:
		close_shop()
	else:
		open_shop()

func open_shop() -> void:
	if is_instance_valid(forge_panel) and forge_panel.visible:
		close_forge()
	if is_instance_valid(chest_panel) and chest_panel.visible:
		close_chest()
	if is_instance_valid(inventory_panel) and inventory_panel.visible:
		close_inventory()
	if is_instance_valid(equipment_panel) and equipment_panel.visible:
		close_equipment()
	if is_instance_valid(pause_panel) and pause_panel.visible:
		close_pause()
	if is_instance_valid(shop_panel):
		shop_panel.visible = true
		switch_shop_tab("sell")
		update_shop_ui()
		if is_instance_valid(shop_tab_sell_btn):
			_safe_grab_focus(shop_tab_sell_btn)

func close_shop() -> void:
	if is_instance_valid(shop_panel):
		shop_panel.visible = false

func _on_shop_tab_buy() -> void:
	switch_shop_tab("buy")

func _on_shop_tab_sell() -> void:
	switch_shop_tab("sell")

func switch_shop_tab(tab: String) -> void:
	if tab == "buy":
		if is_instance_valid(shop_buy_view): shop_buy_view.visible = true
		if is_instance_valid(shop_sell_view): shop_sell_view.visible = false
		if is_instance_valid(shop_tab_buy_btn):
			shop_tab_buy_btn.modulate = Color(1, 1, 1, 1.0)
		if is_instance_valid(shop_tab_sell_btn):
			shop_tab_sell_btn.modulate = Color(0.7, 0.7, 0.7, 0.8)
	else:
		if is_instance_valid(shop_buy_view): shop_buy_view.visible = false
		if is_instance_valid(shop_sell_view): shop_sell_view.visible = true
		if is_instance_valid(shop_tab_sell_btn):
			shop_tab_sell_btn.modulate = Color(1, 1, 1, 1.0)
		if is_instance_valid(shop_tab_buy_btn):
			shop_tab_buy_btn.modulate = Color(0.7, 0.7, 0.7, 0.8)
		update_shop_ui()

func update_shop_ui() -> void:
	var inv = _get_inv()
	if not inv: return
	
	if is_instance_valid(shop_coins_label):
		shop_coins_label.text = "Moedas: %d" % inv.coins
		
	var coal_row = find_child("CoalRow", true, false)
	var iron_row = find_child("IronRow", true, false)
	var gold_row = find_child("GoldRow", true, false)
	
	if coal_row: coal_row.visible = (inv.coal > 0)
	if iron_row: iron_row.visible = (inv.iron > 0)
	if gold_row: gold_row.visible = (inv.gold > 0)
	
	var sell_coal_lbl = find_child("SellCoalCount", true, false)
	if sell_coal_lbl:
		sell_coal_lbl.text = "x%d" % inv.coal
		
	var sell_iron_lbl = find_child("SellIronCount", true, false)
	if sell_iron_lbl:
		sell_iron_lbl.text = "x%d" % inv.iron
		
	var sell_gold_lbl = find_child("SellGoldCount", true, false)
	if sell_gold_lbl:
		sell_gold_lbl.text = "x%d" % inv.gold
		
	var sc1 = find_child("SellCoalOneBtn", true, false)
	if sc1: sc1.disabled = (inv.coal <= 0)
	var sca = find_child("SellCoalAllBtn", true, false)
	if sca: sca.disabled = (inv.coal <= 0)
	
	var si1 = find_child("SellIronOneBtn", true, false)
	if si1: si1.disabled = (inv.iron <= 0)
	var sia = find_child("SellIronAllBtn", true, false)
	if sia: sia.disabled = (inv.iron <= 0)
	
	var sg1 = find_child("SellGoldOneBtn", true, false)
	if sg1: sg1.disabled = (inv.gold <= 0)
	var sga = find_child("SellGoldAllBtn", true, false)
	if sga: sga.disabled = (inv.gold <= 0)
	
	var sell_all = find_child("SellAllMineralsBtn", true, false)
	if sell_all:
		sell_all.visible = (inv.coal > 0 or inv.iron > 0 or inv.gold > 0)
		sell_all.disabled = (inv.coal <= 0 and inv.iron <= 0 and inv.gold <= 0)

	var sell_header = find_child("SellHeaderLabel", true, false)
	if sell_header:
		if inv.coal <= 0 and inv.iron <= 0 and inv.gold <= 0:
			sell_header.text = "Nenhum minério disponível para venda na mochila."
		else:
			sell_header.text = "VENDA SEUS RECURSOS POR MOEDAS DE OURO:" 

func _on_sell_coal_one() -> void:
	var inv = _get_inv()
	if inv:
		inv.sell_resource("coal", 1)
		update_shop_ui()

func _on_sell_coal_all() -> void:
	var inv = _get_inv()
	if inv:
		inv.sell_all_resource("coal")
		update_shop_ui()

func _on_sell_iron_one() -> void:
	var inv = _get_inv()
	if inv:
		inv.sell_resource("iron", 1)
		update_shop_ui()

func _on_sell_iron_all() -> void:
	var inv = _get_inv()
	if inv:
		inv.sell_all_resource("iron")
		update_shop_ui()

func _on_sell_gold_one() -> void:
	var inv = _get_inv()
	if inv:
		inv.sell_resource("gold", 1)
		update_shop_ui()

func _on_sell_gold_all() -> void:
	var inv = _get_inv()
	if inv:
		inv.sell_all_resource("gold")
		update_shop_ui()

func _on_sell_all_minerals() -> void:
	var inv = _get_inv()
	if inv:
		inv.sell_all_minerals()
		update_shop_ui()

func setup_hotbar() -> void:
	slots.clear()
	if not hotbar: return
	for child in hotbar.get_children():
		child.queue_free()
		
	# 7 Hotbar items: 4 Tools (1-4) + 3 Ores (Ferro, Ouro, Carvão)
	var defs = [
		{"key": "pickaxe", "num": "1", "type": "tool", "atlas": "extras", "region": Rect2(0, 0, 16, 16)},
		{"key": "lamp", "num": "2", "type": "tool", "atlas": "lamp", "region": Rect2(0, 0, 16, 16)},
		{"key": "ladder", "num": "3", "type": "tool", "direct": "rope"},
		{"key": "plank", "num": "4", "type": "tool", "direct": "plank"},
		{"key": "iron", "num": "Fe", "type": "res", "atlas": "ores", "region": Rect2(32, 128, 16, 16)},
		{"key": "gold", "num": "Au", "type": "res", "atlas": "ores", "region": Rect2(128, 128, 16, 16)},
		{"key": "coal", "num": "C", "type": "res", "atlas": "ores", "region": Rect2(0, 128, 16, 16)}
	]
	
	for i in range(defs.size()):
		var d = defs[i]
		var slot = _create_slot_panel(d, i < 4)
		hotbar.add_child(slot)
		slots.append(slot)

func setup_chest_grid() -> void:
	chest_slots.clear()
	if not chest_grid: return
	for child in chest_grid.get_children():
		child.queue_free()
		
	for i in range(chest_items_def.size()):
		var def = chest_items_def[i]
		var slot_card = _create_chest_slot_card(def, i)
		chest_grid.add_child(slot_card)
		chest_slots.append(slot_card)

func _create_slot_panel(def: Dictionary, is_tool: bool) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(46, 46)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.1, 0.05, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.45, 0.3, 0.15, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(22, 22)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	if def.has("direct"):
		if def.direct == "rope": icon.texture = rope_tex
		elif def.direct == "plank": icon.texture = plank_tex
	else:
		var atlas = AtlasTexture.new()
		atlas.atlas = extras_tex if def.atlas == "extras" else (lamp_tex if def.atlas == "lamp" else ores_tex)
		atlas.region = def.region
		icon.texture = atlas
		
	vbox.add_child(icon)
	
	var label = Label.new()
	label.name = "CountLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.6, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 3)
	label.text = def.num
	vbox.add_child(label)
	
	panel.set_meta("def", def)
	return panel

func _create_chest_slot_card(def: Dictionary, idx: int) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(80, 75)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.08, 0.04, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.45, 0.3, 0.16, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	card.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(28, 28)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	if def.get("icon_type") == "direct" or def.has("direct") or def.has("tex"):
		var tname = def.get("tex", def.get("direct", ""))
		if tname == "rope": icon.texture = rope_tex
		elif tname == "plank": icon.texture = plank_tex
	else:
		var atlas = AtlasTexture.new()
		var aname = def.get("atlas", "ores")
		atlas.atlas = extras_tex if aname == "extras" else (lamp_tex if aname == "lamp" else ores_tex)
		atlas.region = def.get("region", Rect2(0, 0, 16, 16))
		icon.texture = atlas
	vbox.add_child(icon)
	
	var count_label = Label.new()
	count_label.name = "SlotCount"
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 11)
	count_label.add_theme_color_override("font_color", Color(1, 0.92, 0.7, 1))
	count_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	count_label.add_theme_constant_override("outline_size", 3)
	vbox.add_child(count_label)
	
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(func(event): _on_slot_gui_input(event, idx))
	
	return card

func _on_slot_gui_input(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				select_slot(idx)
				drag_start_idx = idx
			else:
				if drag_start_idx != -1 and drag_start_idx == idx:
					var mpos = event.global_position
					if inventory_panel and not inventory_panel.get_global_rect().has_point(mpos):
						_drop_item_at_idx(idx)
				drag_start_idx = -1

func select_slot(idx: int) -> void:
	selected_index = idx
	
	for i in range(chest_slots.size()):
		var card = chest_slots[i]
		var style = card.get_theme_stylebox("panel")
		if i == selected_index:
			style.border_color = Color(1.0, 0.85, 0.3, 1.0)
			style.border_width_left = 3
			style.border_width_top = 3
			style.border_width_right = 3
			style.border_width_bottom = 3
			style.bg_color = Color(0.24, 0.14, 0.07, 0.98)
		else:
			style.border_color = Color(0.45, 0.3, 0.16, 1)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.bg_color = Color(0.14, 0.08, 0.04, 0.95)
			
	if selected_index >= 0 and selected_index < chest_items_def.size():
		var def = chest_items_def[selected_index]
		if item_title: item_title.text = def.name
		if item_desc: item_desc.text = def.desc
		if equip_button:
			equip_button.visible = def.is_tool
			equip_button.text = "Equipar [%s]" % def.shortcut
		if drop_button:
			drop_button.visible = not def.is_tool or (def.key == "plank" or def.key == "lamp")

func _on_equip_pressed() -> void:
	if selected_index < 0 or selected_index >= chest_items_def.size(): return
	var def = chest_items_def[selected_index]
	var inv = _get_inv()
	if def.is_tool and inv:
		var lamp_available = inv.can_place_lamp() if inv.has_method("can_place_lamp") else (inv.starter_lamps > 0 if "starter_lamps" in inv else false)
		if def.key == "lamp" and not lamp_available:
			show_toast("Sem postes disponíveis! Crie na Forja.", "lamp")
			return
		inv.active_slot = def.tool_slot
		inv.inventory_changed.emit()
		close_inventory()
		show_toast("%s equipada!" % def.name, def.key)

func _on_drop_pressed() -> void:
	_drop_item_at_idx(selected_index)

func _drop_item_at_idx(idx: int) -> void:
	if idx < 0 or idx >= chest_items_def.size(): return
	var def = chest_items_def[idx]
	var count = _get_item_count(def.key)
	var inv = _get_inv()
	if count > 0 and inv:
		inv.drop_item(def.key, 1)
		_update_capacity_badge()
	else:
		show_toast("Sem unidades para dropar!", "chest")

func _get_item_count(key: String) -> int:
	var inv = _get_inv()
	if not inv: return 0
	match key:
		"pickaxe": return 1
		"lamp": return inv.starter_lamps if "starter_lamps" in inv else 0
		"ladder": return inv.ladders if "ladders" in inv else 0
		"plank": return inv.planks
		"iron": return inv.iron
		"gold": return inv.gold
		"coal": return inv.coal
		"wood": return inv.wood_logs if "wood_logs" in inv else 0
		_: return 0

func update_ui() -> void:
	var inv = _get_inv()
	if not inv: return
	
	if is_instance_valid(coins_badge_container):
		coins_badge_container.visible = (inv.coins > 0)
		if is_instance_valid(coins_hud_label):
			coins_hud_label.text = "%d" % inv.coins
			
	if not is_instance_valid(level_badge_label):
		level_badge_label = find_child("LevelBadgeLabel", true, false)
	if is_instance_valid(level_badge_label):
		level_badge_label.text = "Nv. %d" % (inv.level if "level" in inv else 0)
		
	if not is_instance_valid(exp_progress_bar):
		exp_progress_bar = find_child("ExpProgressBar", true, false)
	if is_instance_valid(exp_progress_bar):
		var req = inv.get_exp_required_for_level(inv.level) if inv.has_method("get_exp_required_for_level") else 100
		var cur = inv.current_exp if "current_exp" in inv else 0
		exp_progress_bar.max_value = float(req)
		exp_progress_bar.value = float(cur)
	
	var can_craft_lamp = inv.can_place_lamp() if inv.has_method("can_place_lamp") else (inv.starter_lamps > 0 if "starter_lamps" in inv else false)
	var craftable_lamps = inv.starter_lamps if "starter_lamps" in inv else 0
	
	# Update 7 Hotbar items
	for i in range(slots.size()):
		var slot = slots[i]
		var def = slot.get_meta("def")
		var count_lbl = slot.find_child("CountLabel", true, false)
		var style = slot.get_theme_stylebox("panel")
		
		var is_selected_tool = (i == inv.active_slot and i < 4)
		if is_selected_tool:
			style.border_color = Color(1.0, 0.88, 0.25, 1.0)
			style.border_width_left = 3
			style.border_width_top = 3
			style.border_width_right = 3
			style.border_width_bottom = 3
			style.bg_color = Color(0.28, 0.16, 0.08, 0.98)
		else:
			style.border_color = Color(0.45, 0.3, 0.15, 1)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.bg_color = Color(0.16, 0.1, 0.05, 0.95)
			
		if def.key == "pickaxe":
			count_lbl.text = "[1]"
			slot.modulate = Color(1, 1, 1, 1.0)
		elif def.key == "lamp":
			count_lbl.text = "%d" % craftable_lamps
			if can_craft_lamp:
				slot.modulate = Color(1, 1, 1, 1.0)
			else:
				slot.modulate = Color(1, 1, 1, 0.4) # Semi-opaco indicando indisponibilidade
		elif def.key == "ladder":
			count_lbl.text = "%d" % (inv.ladders if "ladders" in inv else 0)
			slot.modulate = Color(1, 1, 1, 1.0)
		elif def.key == "plank":
			count_lbl.text = "%d" % inv.planks
			slot.modulate = Color(1, 1, 1, 1.0)
		elif def.key == "iron":
			count_lbl.text = "%d" % inv.iron
			slot.modulate = Color(1, 1, 1, 1.0)
		elif def.key == "gold":
			count_lbl.text = "%d" % inv.gold
			slot.modulate = Color(1, 1, 1, 1.0)
		elif def.key == "coal":
			count_lbl.text = "%d" % inv.coal
			slot.modulate = Color(1, 1, 1, 1.0)
			
	# Update chest slot cards
	for i in range(chest_slots.size()):
		var card = chest_slots[i]
		var def = chest_items_def[i]
		var lbl = card.find_child("SlotCount", true, false)
		if lbl:
			var c = _get_item_count(def.key)
			if def.key == "ladder":
				lbl.text = "%d un." % (inv.ladders if "ladders" in inv else 0)
			elif def.key == "pickaxe":
				lbl.text = "Nível 1"
			elif def.key == "lamp":
				lbl.text = "%d un." % (inv.starter_lamps if "starter_lamps" in inv else 0)
			else:
				lbl.text = "%d un." % c
				
	_update_capacity_badge()
	if is_instance_valid(shop_panel) and shop_panel.visible:
		update_shop_ui()
	if is_instance_valid(chest_panel) and chest_panel.visible:
		update_chest_ui()
	if is_instance_valid(forge_panel) and forge_panel.visible:
		update_forge_ui()

func _update_capacity_badge() -> void:
	var inv = _get_inv()
	if not is_instance_valid(capacity_badge_label) or not inv:
		return
	
	var used = inv.get_total_used()
	var max_cap = inv.MAX_CAPACITY
	var avail = inv.get_total_available()
	
	capacity_badge_label.text = "🎒 Carga: %d / %d  |  Livre: %d" % [used, max_cap, avail]
	
	var ratio = float(used) / float(max_cap)
	if ratio >= 1.0:
		capacity_badge_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
	elif ratio >= 0.75:
		capacity_badge_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1.0))
	else:
		capacity_badge_label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.85, 1.0))

func toggle() -> void:
	if is_instance_valid(inventory_panel) and inventory_panel.visible:
		close_inventory()
	else:
		open_inventory()

func open_inventory() -> void:
	if is_instance_valid(forge_panel) and forge_panel.visible:
		close_forge()
	if is_instance_valid(chest_panel) and chest_panel.visible:
		close_chest()
	if is_instance_valid(equipment_panel) and equipment_panel.visible:
		close_equipment()
	if is_instance_valid(shop_panel) and shop_panel.visible:
		close_shop()
	if is_instance_valid(pause_panel) and pause_panel.visible:
		close_pause()
	if is_instance_valid(inventory_panel):
		inventory_panel.visible = true
	select_slot(selected_index)
	update_ui()

func close_inventory() -> void:
	if is_instance_valid(inventory_panel):
		inventory_panel.visible = false

func toggle_chest(chest_node: Node = null) -> void:
	if is_instance_valid(chest_panel) and chest_panel.visible:
		close_chest()
	else:
		open_chest(chest_node)

func open_chest(chest_node: Node = null) -> void:
	if is_instance_valid(forge_panel) and forge_panel.visible:
		close_forge()
	if chest_node:
		current_chest_node = chest_node
	elif not is_instance_valid(current_chest_node):
		if is_inside_tree() and get_tree() and get_tree().current_scene:
			current_chest_node = get_tree().current_scene.get_node_or_null("Chest")
			
	if is_instance_valid(inventory_panel) and inventory_panel.visible:
		close_inventory()
	if is_instance_valid(equipment_panel) and equipment_panel.visible:
		close_equipment()
	if is_instance_valid(shop_panel) and shop_panel.visible:
		close_shop()
	if is_instance_valid(pause_panel) and pause_panel.visible:
		close_pause()
		
	if is_instance_valid(chest_panel):
		chest_panel.visible = true
		update_chest_ui()
		if is_instance_valid(chest_deposit_btn):
			_safe_grab_focus(chest_deposit_btn)

func close_chest() -> void:
	if is_instance_valid(chest_panel):
		chest_panel.visible = false

func update_chest_ui() -> void:
	var inv = _get_inv()
	var c_coal = current_chest_node.stored_coal if is_instance_valid(current_chest_node) else 0
	var c_iron = current_chest_node.stored_iron if is_instance_valid(current_chest_node) else 0
	var c_gold = current_chest_node.stored_gold if is_instance_valid(current_chest_node) else 0
	
	if chest_coal_lbl:
		chest_coal_lbl.visible = (c_coal > 0)
		chest_coal_lbl.text = "• Carvão: %d" % c_coal
	if chest_iron_lbl:
		chest_iron_lbl.visible = (c_iron > 0)
		chest_iron_lbl.text = "• Minério de Ferro: %d" % c_iron
	if chest_gold_lbl:
		chest_gold_lbl.visible = (c_gold > 0)
		chest_gold_lbl.text = "• Minério de Ouro: %d" % c_gold
	
	var left_box = find_child("LeftBox", true, false)
	var chest_empty_lbl = find_child("ChestEmptyLabel", true, false)
	if not chest_empty_lbl and left_box:
		var vbox = left_box.find_child("VBox", true, false)
		if vbox:
			chest_empty_lbl = Label.new()
			chest_empty_lbl.name = "ChestEmptyLabel"
			chest_empty_lbl.add_theme_font_size_override("font_size", 12)
			chest_empty_lbl.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6, 1))
			chest_empty_lbl.text = "(Baú vazio)"
			vbox.add_child(chest_empty_lbl)
	if chest_empty_lbl:
		chest_empty_lbl.visible = (c_coal <= 0 and c_iron <= 0 and c_gold <= 0)
	
	var b_coal = inv.coal if inv else 0
	var b_iron = inv.iron if inv else 0
	var b_gold = inv.gold if inv else 0
	
	if backpack_coal_lbl:
		backpack_coal_lbl.visible = (b_coal > 0)
		backpack_coal_lbl.text = "• Carvão: %d" % b_coal
	if backpack_iron_lbl:
		backpack_iron_lbl.visible = (b_iron > 0)
		backpack_iron_lbl.text = "• Minério de Ferro: %d" % b_iron
	if backpack_gold_lbl:
		backpack_gold_lbl.visible = (b_gold > 0)
		backpack_gold_lbl.text = "• Minério de Ouro: %d" % b_gold
	
	var right_box = find_child("RightBox", true, false)
	var bp_empty_lbl = find_child("BackpackEmptyLabel", true, false)
	if not bp_empty_lbl and right_box:
		var vbox = right_box.find_child("VBox", true, false)
		if vbox:
			bp_empty_lbl = Label.new()
			bp_empty_lbl.name = "BackpackEmptyLabel"
			bp_empty_lbl.add_theme_font_size_override("font_size", 12)
			bp_empty_lbl.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6, 1))
			bp_empty_lbl.text = "(Mochila sem recursos)"
			vbox.add_child(bp_empty_lbl)
	if bp_empty_lbl:
		bp_empty_lbl.visible = (b_coal <= 0 and b_iron <= 0 and b_gold <= 0)
	
	if chest_deposit_btn:
		chest_deposit_btn.disabled = (b_coal <= 0 and b_iron <= 0 and b_gold <= 0)
	if chest_retrieve_btn:
		chest_retrieve_btn.disabled = (c_coal <= 0 and c_iron <= 0 and c_gold <= 0)

func _on_chest_deposit() -> void:
	if is_instance_valid(current_chest_node) and current_chest_node.has_method("deposit_resources"):
		current_chest_node.deposit_resources()
		update_chest_ui()
		update_ui()

func _on_chest_retrieve() -> void:
	if is_instance_valid(current_chest_node) and current_chest_node.has_method("retrieve_resources"):
		current_chest_node.retrieve_resources()
		update_chest_ui()
		update_ui()

func show_toast(text: String, icon_type: String = "") -> void:
	if not toast_list: return
	
	var toast = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.04, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.65, 0.25, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 6
	toast.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 6)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	
	if icon_type != "":
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		if icon_type in ["coin", "coin_gold"]:
			icon.texture = coin_gold_tex
		elif icon_type == "coin_silver":
			icon.texture = coin_silver_tex
		elif icon_type == "coin_copper":
			icon.texture = coin_copper_tex
		elif icon_type in ["wood", "wood_log"]:
			icon.texture = wood_tex
		elif icon_type == "iron":
			var atlas = AtlasTexture.new()
			atlas.atlas = ores_tex
			atlas.region = Rect2(32, 128, 16, 16)
			icon.texture = atlas
		elif icon_type == "gold":
			var atlas = AtlasTexture.new()
			atlas.atlas = ores_tex
			atlas.region = Rect2(128, 128, 16, 16)
			icon.texture = atlas
		elif icon_type == "coal":
			var atlas = AtlasTexture.new()
			atlas.atlas = ores_tex
			atlas.region = Rect2(0, 128, 16, 16)
			icon.texture = atlas
		elif icon_type == "plank":
			icon.texture = plank_tex
		elif icon_type == "lamp":
			var atlas = AtlasTexture.new()
			atlas.atlas = lamp_tex
			atlas.region = Rect2(0, 0, 16, 16)
			icon.texture = atlas
		elif icon_type == "save" or icon_type == "chest":
			var atlas = AtlasTexture.new()
			atlas.atlas = extras_tex
			atlas.region = Rect2(160, 32, 16, 16)
			icon.texture = atlas
		elif icon_type == "ladder":
			icon.texture = rope_tex
		elif icon_type == "dash":
			var atlas = AtlasTexture.new()
			atlas.atlas = extras_tex
			atlas.region = Rect2(0, 0, 16, 16)
			icon.texture = atlas
		elif icon_type == "pickaxe":
			var atlas = AtlasTexture.new()
			atlas.atlas = extras_tex
			atlas.region = Rect2(0, 0, 16, 16)
			icon.texture = atlas
		hbox.add_child(icon)
		
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.82, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	label.add_theme_constant_override("outline_size", 4)
	hbox.add_child(label)
	
	margin.add_child(hbox)
	toast.add_child(margin)
	toast_list.add_child(toast)
	
	toast.modulate.a = 0.0
	toast.scale = Vector2(0.85, 0.85)
	var tween = toast.create_tween()
	tween.set_parallel(true)
	tween.tween_property(toast, "modulate:a", 1.0, 0.15)
	tween.tween_property(toast, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	var timer = toast.get_tree().create_timer(2.2) if (toast.is_inside_tree() and toast.get_tree()) else null
	if timer:
		timer.timeout.connect(func():
			if is_instance_valid(toast):
				var out_tween = toast.create_tween()
				out_tween.set_parallel(true)
				out_tween.tween_property(toast, "modulate:a", 0.0, 0.25)
				out_tween.tween_property(toast, "position:x", toast.position.x - 25.0, 0.25)
				out_tween.finished.connect(func():
					if is_instance_valid(toast):
						toast.queue_free()
				)
		)
