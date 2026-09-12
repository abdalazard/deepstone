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
var stone_tex = preload("res://assets/sprites/stone_drop.png")
var dirt_tex = preload("res://assets/sprites/dirt_drop.png")
var brick_tex = preload("res://assets/sprites/brick_platform.png")
var broken_pickaxe_tex = preload("res://assets/sprites/broken_pickaxe.png")

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

# Forge Menu nodes
@onready var forge_panel = find_child("ForgePanel", true, false)
@onready var forge_close_btn = find_child("ForgeCloseBtn", true, false)
@onready var forge_close_footer_btn = find_child("ForgeCloseFooterBtn", true, false)
@onready var craft_pickaxe_btn = find_child("CraftPickaxeBtn", true, false)
@onready var craft_lamp_btn = find_child("CraftLampBtn", true, false)
@onready var craft_ladder_btn = find_child("CraftLadderBtn", true, false)
@onready var craft_plank_btn = find_child("CraftPlankBtn", true, false)
@onready var craft_brick_floor_btn = find_child("CraftBrickFloorBtn", true, false)
@onready var craft_portable_forge_btn = find_child("CraftPortableForgeBtn", true, false)
var current_forge_node: Node = null

# Pause Menu Reset
@onready var reset_mine_btn = find_child("ResetMineBtn", true, false)

# Equipment Idle Animation
var idle_anim_timer: float = 0.0
var idle_anim_frame: int = 0

# Hotbar Configuration Modal
var hotbar_config_panel: PanelContainer = null
var selected_config_slot: int = 0

var chest_items_def = [
	{
		"key": "pickaxe",
		"name": "Picareta de Mineração",
		"desc": "Ferramenta para escavar terra e minérios. Possui durabilidade e desgasta ao bater em minérios pesados.",
		"icon_type": "atlas",
		"atlas": "extras",
		"region": Rect2(0, 0, 16, 16),
		"shortcut": "1",
		"is_tool": true,
		"tool_slot": 0
	},
	{
		"key": "lamp",
		"name": "Poste de Luz",
		"desc": "Lampião portátil que ilumina a caverna e faz os minérios brilharem no escuro. Custa 3 Carvões + 2 Ferros.",
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
		"desc": "Escada portátil com degraus para descer e subir poços profundos.",
		"icon_type": "direct",
		"tex": "rope",
		"shortcut": "3",
		"is_tool": true,
		"tool_slot": 2
	},
	{
		"key": "plank",
		"name": "Tábua de Madeira",
		"desc": "Ponte horizontal sólida para cruzar fendas e abismos. Pressione [Z] para construir.",
		"icon_type": "direct",
		"tex": "plank",
		"shortcut": "4",
		"is_tool": true,
		"tool_slot": 3
	},
	{
		"key": "brick",
		"name": "Piso de Tijolo",
		"desc": "Plataforma reforçada de tijolo forjada com 1 terra e 1 pedra. Suporta postes de luz.",
		"icon_type": "direct",
		"tex": "brick",
		"shortcut": "5",
		"is_tool": true,
		"tool_slot": 4
	},
	{
		"key": "forge",
		"name": "Forja Portátil",
		"desc": "Forja portátil para implantar na mina e forjar itens longe da superfície. Custa 5 pedras + 3 ferros.",
		"icon_type": "direct",
		"tex": "stone",
		"shortcut": "6",
		"is_tool": true,
		"tool_slot": 5
	},
	{
		"key": "wood",
		"name": "Tronco de Madeira",
		"desc": "Madeira obtida de árvores da superfície ou raízes subterrâneas. Usada para criar escadas, tábuas e picaretas.",
		"icon_type": "direct",
		"tex": "wood",
		"shortcut": "",
		"is_tool": false
	},
	{
		"key": "iron",
		"name": "Minério de Ferro",
		"desc": "Metal versátil e resistente obtido nas profundezas. Usado na forja de ferramentas e postes.",
		"icon_type": "atlas",
		"atlas": "ores",
		"region": Rect2(32, 128, 16, 16),
		"shortcut": "",
		"is_tool": false
	},
	{
		"key": "gold",
		"name": "Minério de Ouro",
		"desc": "Metal nobre e reluzente de alto valor comercial e grande raridade. Venda na Loja por 50 moedas!",
		"icon_type": "atlas",
		"atlas": "ores",
		"region": Rect2(128, 128, 16, 16),
		"shortcut": "",
		"is_tool": false
	},
	{
		"key": "coal",
		"name": "Carvão Mineral",
		"desc": "Combustível fóssil primordial abundante. Usado para iluminação e forjas.",
		"icon_type": "atlas",
		"atlas": "ores",
		"region": Rect2(0, 128, 16, 16),
		"shortcut": "",
		"is_tool": false
	},
	{
		"key": "stone",
		"name": "Pedra Bruta",
		"desc": "Pedra escavada do subsolo. Usada na construção de pisos de tijolo, forjas portáteis e ferramentas.",
		"icon_type": "direct",
		"tex": "stone",
		"shortcut": "",
		"is_tool": false
	},
	{
		"key": "dirt",
		"name": "Lama / Terra",
		"desc": "Terra coletada das escavações. Usada para moldar e forjar pisos de tijolo.",
		"icon_type": "direct",
		"tex": "dirt",
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
		if inv.has_signal("level_up") and not inv.level_up.is_connected(_on_level_up):
			inv.level_up.connect(_on_level_up)
	
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

	# Pause Menu buttons
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
	if reset_mine_btn and not reset_mine_btn.pressed.is_connected(_on_reset_mine_pressed):
		reset_mine_btn.pressed.connect(_on_reset_mine_pressed)

	# Chest buttons
	if chest_close_btn and not chest_close_btn.pressed.is_connected(close_chest):
		chest_close_btn.pressed.connect(close_chest)
	if chest_close_footer_btn and not chest_close_footer_btn.pressed.is_connected(close_chest):
		chest_close_footer_btn.pressed.connect(close_chest)
	if chest_deposit_btn and not chest_deposit_btn.pressed.is_connected(_on_chest_deposit):
		chest_deposit_btn.pressed.connect(_on_chest_deposit)
	if chest_retrieve_btn and not chest_retrieve_btn.pressed.is_connected(_on_chest_retrieve):
		chest_retrieve_btn.pressed.connect(_on_chest_retrieve)

	# Forge buttons
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
	if craft_brick_floor_btn and not craft_brick_floor_btn.pressed.is_connected(_on_craft_brick_floor):
		craft_brick_floor_btn.pressed.connect(_on_craft_brick_floor)
	if craft_pickaxe_btn and not craft_pickaxe_btn.pressed.is_connected(_on_craft_pickaxe):
		craft_pickaxe_btn.pressed.connect(_on_craft_pickaxe)
	if craft_portable_forge_btn and not craft_portable_forge_btn.pressed.is_connected(_on_craft_portable_forge):
		craft_portable_forge_btn.pressed.connect(_on_craft_portable_forge)
		
	select_slot(0)
	update_ui()

func _consume_input() -> void:
	if is_inside_tree() and get_viewport():
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Shift + A: Open Hotbar Shortcut Config
		if event.physical_keycode == KEY_A and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT)):
			toggle_hotbar_config()
			_consume_input()
			return

		# Toggle Equipment Menu with [E]
		if event.physical_keycode == KEY_E or event.is_action_pressed("action_equip_menu"):
			toggle_equipment()
			_consume_input()
			return

		# Toggle Pause Menu with [P] or [Esc]
		if event.physical_keycode == KEY_P or event.physical_keycode == KEY_ESCAPE:
			if is_instance_valid(hotbar_config_panel) and hotbar_config_panel.visible:
				hotbar_config_panel.visible = false
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
			if is_instance_valid(hotbar_config_panel) and hotbar_config_panel.visible:
				hotbar_config_panel.visible = false
				_consume_input()
				return
			elif is_instance_valid(shop_panel) and shop_panel.visible:
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

		# Universal Confirm on [Z]
		if event.physical_keycode == KEY_Z:
			if is_instance_valid(forge_panel) and forge_panel.visible:
				var inv = _get_inv()
				if inv:
					if inv.can_craft_pickaxe() and not inv.has_pickaxe:
						_on_craft_pickaxe()
					elif inv.can_craft_lamp():
						_on_craft_lamp()
					elif inv.can_craft_portable_forge():
						_on_craft_portable_forge()
					elif inv.can_craft_brick_floor():
						_on_craft_brick_floor()
					elif inv.can_craft_planks():
						_on_craft_plank()
					elif inv.can_craft_ladders():
						_on_craft_ladder()
				_consume_input()
				return
			elif is_instance_valid(chest_panel) and chest_panel.visible:
				_on_chest_deposit()
				_consume_input()
				return
			elif is_instance_valid(inventory_panel) and inventory_panel.visible:
				_on_equip_pressed()
				_consume_input()
				return

func toggle_hotbar_config() -> void:
	if not is_instance_valid(hotbar_config_panel):
		_build_hotbar_config_panel()
	hotbar_config_panel.visible = not hotbar_config_panel.visible
	if hotbar_config_panel.visible:
		_update_hotbar_config_ui()

func _build_hotbar_config_panel() -> void:
	hotbar_config_panel = PanelContainer.new()
	hotbar_config_panel.name = "HotbarConfigPanel"
	hotbar_config_panel.custom_minimum_size = Vector2(400, 260)
	hotbar_config_panel.anchors_preset = Control.PRESET_CENTER
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.1, 0.05, 0.98)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.9, 0.75, 0.25, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.shadow_size = 10
	hotbar_config_panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	hotbar_config_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.name = "ConfigVBox"
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "⚙ CONFIGURAR ATALHOS DA HOTBAR [Shift + A]"
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1.0))
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = "Selecione o slot e clique no item para reatribuir:"
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7, 1.0))
	vbox.add_child(desc)
	
	var slots_hbox = HBoxContainer.new()
	slots_hbox.name = "SlotsHBox"
	slots_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(slots_hbox)
	
	var items_grid = GridContainer.new()
	items_grid.name = "ItemsGrid"
	items_grid.columns = 3
	items_grid.add_theme_constant_override("h_separation", 6)
	items_grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(items_grid)
	
	var close_b = Button.new()
	close_b.text = "Fechar [X]"
	close_b.pressed.connect(func(): hotbar_config_panel.visible = false)
	vbox.add_child(close_b)
	
	add_child(hotbar_config_panel)

func _update_hotbar_config_ui() -> void:
	if not is_instance_valid(hotbar_config_panel): return
	var inv = _get_inv()
	if not inv: return
	
	var slots_hbox = hotbar_config_panel.find_child("SlotsHBox", true, false)
	if slots_hbox:
		for c in slots_hbox.get_children(): c.queue_free()
		for i in range(inv.hotbar_slots.size()):
			var s_key = inv.hotbar_slots[i]
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(50, 32)
			btn.text = "[%d] %s" % [i + 1, s_key.capitalize()]
			if i == selected_config_slot:
				btn.modulate = Color(1.3, 1.3, 0.8, 1.0)
			var slot_i = i
			btn.pressed.connect(func():
				selected_config_slot = slot_i
				_update_hotbar_config_ui()
			)
			slots_hbox.add_child(btn)
			
	var items_grid = hotbar_config_panel.find_child("ItemsGrid", true, false)
	if items_grid:
		for c in items_grid.get_children(): c.queue_free()
		var available = [
			{"key": "pickaxe", "label": "⛏ Picareta"},
			{"key": "lamp", "label": "🏮 Poste de Luz"},
			{"key": "ladder", "label": "🪜 Escada"},
			{"key": "plank", "label": "🪵 Tábua"},
			{"key": "brick", "label": "🧱 Piso Tijolo"},
			{"key": "forge", "label": "⚒ Forja Portátil"}
		]
		for it in available:
			var ibtn = Button.new()
			ibtn.text = it.label
			var item_k = it.key
			ibtn.pressed.connect(func():
				inv.set_hotbar_slot(selected_config_slot, item_k)
				_update_hotbar_config_ui()
				update_ui()
				show_toast("Slot %d atribuído: %s" % [selected_config_slot + 1, it.label], item_k)
			)
			items_grid.add_child(ibtn)

func _on_level_up(new_lvl: int, exp_req: int) -> void:
	show_level_up_vfx(new_lvl, exp_req)

func show_level_up_vfx(new_lvl: int, exp_req: int) -> void:
	if not is_instance_valid(level_up_panel):
		level_up_panel = find_child("LevelUpPanel", true, false)
	if is_instance_valid(level_up_panel):
		level_up_panel.visible = true
		level_up_panel.modulate.a = 0.0
		level_up_panel.scale = Vector2(0.8, 0.8)
		if is_instance_valid(level_up_title):
			level_up_title.text = "★ NÍVEL %d ALCANÇADO! ★" % new_lvl
		if is_instance_valid(level_up_subtitle):
			level_up_subtitle.text = "EXP Necessária para Nível %d: %d EXP" % [new_lvl + 1, exp_req]
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(level_up_panel, "modulate:a", 1.0, 0.2)
		tween.tween_property(level_up_panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		var timer = get_tree().create_timer(1.2) if get_tree() else null
		if timer:
			timer.timeout.connect(func():
				if is_instance_valid(level_up_panel):
					var out_tween = create_tween()
					out_tween.tween_property(level_up_panel, "modulate:a", 0.0, 0.3)
					out_tween.tween_callback(func():
						if is_instance_valid(level_up_panel):
							level_up_panel.visible = false
					)
			)

# Forge Crafting Handlers
func _on_craft_pickaxe() -> void:
	var inv = _get_inv()
	if inv:
		if inv.craft_pickaxe():
			update_forge_ui()
			update_ui()
		else:
			show_toast("Recursos insuficientes! Requer 1 Ferro, 2 Madeiras e 1 Pedra.", "pickaxe")

func _on_craft_lamp() -> void:
	var inv = _get_inv()
	if inv:
		if inv.craft_lamp():
			update_forge_ui()
			update_ui()
		else:
			show_toast("Recursos insuficientes! Requer 3 Carvões e 2 Ferros.", "lamp")

func _on_craft_ladder() -> void:
	var inv = _get_inv()
	if inv:
		if inv.craft_ladders():
			update_forge_ui()
			update_ui()
		else:
			show_toast("Sem madeira suficiente! Requer 1 Tronco de Madeira.", "wood")

func _on_craft_plank() -> void:
	var inv = _get_inv()
	if inv:
		if inv.craft_planks():
			update_forge_ui()
			update_ui()
		else:
			show_toast("Sem madeira suficiente! Requer 1 Tronco de Madeira.", "wood")

func _on_craft_brick_floor() -> void:
	var inv = _get_inv()
	if inv:
		if inv.craft_brick_floor():
			update_forge_ui()
			update_ui()
		else:
			show_toast("Recursos insuficientes! Requer 1 Terra e 1 Pedra.", "plank")

func _on_craft_portable_forge() -> void:
	var inv = _get_inv()
	if inv:
		if inv.craft_portable_forge():
			update_forge_ui()
			update_ui()
		else:
			show_toast("Recursos insuficientes! Requer 5 Pedras e 3 Ferros.", "forge")

func toggle_forge(forge_node: Node = null) -> void:
	if not forge_panel: return
	if forge_panel.visible:
		close_forge()
	else:
		open_forge(forge_node)

func open_forge(forge_node: Node = null) -> void:
	current_forge_node = forge_node
	if forge_panel:
		forge_panel.visible = true
		update_forge_ui()
		if craft_lamp_btn:
			_safe_grab_focus(craft_lamp_btn)

func close_forge() -> void:
	if forge_panel:
		forge_panel.visible = false
	current_forge_node = null

func update_forge_ui() -> void:
	var inv = _get_inv()
	if not inv: return
	
	# Update Forge resource indicators
	var f_coal = find_child("ForgeCoalCount", true, false)
	var f_iron = find_child("ForgeIronCount", true, false)
	var f_wood = find_child("ForgeWoodCount", true, false)
	var f_stone = find_child("ForgeStoneCount", true, false)
	var f_dirt = find_child("ForgeDirtCount", true, false)
	
	if f_coal: f_coal.text = "%d" % inv.coal
	if f_iron: f_iron.text = "%d" % inv.iron
	if f_wood: f_wood.text = "%d" % inv.wood_logs
	if f_stone: f_stone.text = "%d" % inv.stone
	if f_dirt: f_dirt.text = "%d" % inv.dirt
	
	if not craft_pickaxe_btn: craft_pickaxe_btn = find_child("CraftPickaxeBtn", true, false)
	if craft_pickaxe_btn:
		craft_pickaxe_btn.disabled = not inv.can_craft_pickaxe()
	if craft_lamp_btn:
		craft_lamp_btn.disabled = not inv.can_craft_lamp()
	if craft_ladder_btn:
		craft_ladder_btn.disabled = not inv.can_craft_ladders()
	if craft_plank_btn:
		craft_plank_btn.disabled = not inv.can_craft_planks()
	if not craft_brick_floor_btn: craft_brick_floor_btn = find_child("CraftBrickFloorBtn", true, false)
	if craft_brick_floor_btn:
		craft_brick_floor_btn.disabled = not inv.can_craft_brick_floor()
	if not craft_portable_forge_btn: craft_portable_forge_btn = find_child("CraftPortableForgeBtn", true, false)
	if craft_portable_forge_btn:
		craft_portable_forge_btn.disabled = not inv.can_craft_portable_forge()

func toggle_equipment() -> void:
	if not equipment_panel: return
	if equipment_panel.visible:
		close_equipment()
	else:
		open_equipment()

func open_equipment() -> void:
	if equipment_panel:
		equipment_panel.visible = true
		idle_anim_timer = 0.0
		idle_anim_frame = 0
		if equip_close_btn:
			_safe_grab_focus(equip_close_btn)

func close_equipment() -> void:
	if equipment_panel:
		equipment_panel.visible = false

func toggle() -> void:
	if not inventory_panel: return
	if inventory_panel.visible:
		close_inventory()
	else:
		open_inventory()

func open_inventory() -> void:
	if inventory_panel:
		inventory_panel.visible = true
		update_ui()
		select_slot(selected_index)
		if close_button:
			_safe_grab_focus(close_button)

func close_inventory() -> void:
	if inventory_panel:
		inventory_panel.visible = false

func toggle_pause() -> void:
	if not pause_panel: return
	if pause_panel.visible:
		close_pause()
	else:
		open_pause()

func open_pause() -> void:
	if pause_panel:
		pause_panel.visible = true
		if resume_btn:
			_safe_grab_focus(resume_btn)

func close_pause() -> void:
	if pause_panel:
		pause_panel.visible = false

func _on_save_pressed() -> void:
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").save_game(true)
	close_pause()

func _on_restart_pressed() -> void:
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").restart_run_to_surface()
	close_pause()

func _on_reset_mine_pressed() -> void:
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").reset_mine_completely()

func _on_exit_pressed() -> void:
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").save_game(false)
	get_tree().quit()

func toggle_shop() -> void:
	if not shop_panel: return
	if shop_panel.visible:
		close_shop()
	else:
		open_shop()

func open_shop() -> void:
	if shop_panel:
		shop_panel.visible = true
		_on_shop_tab_sell()
		update_shop_ui()
		if shop_tab_sell_btn:
			_safe_grab_focus(shop_tab_sell_btn)

func close_shop() -> void:
	if shop_panel:
		shop_panel.visible = false

func _on_shop_pressed() -> void:
	toggle_shop()

func _on_shop_tab_buy() -> void:
	if shop_buy_view: shop_buy_view.visible = true
	if shop_sell_view: shop_sell_view.visible = false
	if shop_tab_buy_btn: shop_tab_buy_btn.modulate = Color(1.2, 1.2, 0.8, 1.0)
	if shop_tab_sell_btn: shop_tab_sell_btn.modulate = Color(0.7, 0.7, 0.7, 1.0)

func _on_shop_tab_sell() -> void:
	if shop_buy_view: shop_buy_view.visible = false
	if shop_sell_view: shop_sell_view.visible = true
	if shop_tab_sell_btn: shop_tab_sell_btn.modulate = Color(1.2, 1.2, 0.8, 1.0)
	if shop_tab_buy_btn: shop_tab_buy_btn.modulate = Color(0.7, 0.7, 0.7, 1.0)
	update_shop_ui()

func update_shop_ui() -> void:
	var inv = _get_inv()
	if not inv: return
	
	if shop_coins_label:
		shop_coins_label.text = "Suas Moedas de Ouro: %d" % inv.coins
		
	# Update dynamically sellable items list in Shop
	var sell_container = find_child("SellRowsContainer", true, false)
	if sell_container:
		for child in sell_container.get_children():
			child.queue_free()
			
		var sellable = [
			{"key": "coal", "name": "Carvão Mineral", "price": inv.COAL_PRICE, "count": inv.coal, "tex": "ores_coal"},
			{"key": "iron", "name": "Minério de Ferro", "price": inv.IRON_PRICE, "count": inv.iron, "tex": "ores_iron"},
			{"key": "gold", "name": "Minério de Ouro", "price": inv.GOLD_PRICE, "count": inv.gold, "tex": "ores_gold"},
			{"key": "wood", "name": "Madeira (Troncos)", "price": inv.WOOD_PRICE, "count": inv.wood_logs, "tex": "wood"},
			{"key": "stone", "name": "Pedra", "price": inv.STONE_PRICE, "count": inv.stone, "tex": "stone"},
			{"key": "dirt", "name": "Lama / Terra", "price": inv.DIRT_PRICE, "count": inv.dirt, "tex": "dirt"},
			{"key": "plank", "name": "Tábua de Madeira", "price": inv.PLANK_PRICE, "count": inv.planks, "tex": "plank"},
			{"key": "brick", "name": "Piso de Tijolo", "price": inv.BRICK_PRICE, "count": inv.brick_floors, "tex": "brick"},
			{"key": "ladder", "name": "Escada", "price": inv.LADDER_PRICE, "count": inv.ladders, "tex": "rope"}
		]
		
		var has_any = false
		for item in sellable:
			if item.count > 0:
				has_any = true
				var row = _create_shop_sell_row(item)
				sell_container.add_child(row)
				
		var empty_lbl = find_child("SellEmptyLabel", true, false)
		if empty_lbl:
			empty_lbl.visible = not has_any

func _create_shop_sell_row(item: Dictionary) -> PanelContainer:
	var row = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.11, 0.06, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.45, 0.3, 0.16, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	row.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	row.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)
	
	var lbl = Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.text = "%s (x%d) — Preço: %d moedas cada" % [item.name, item.count, item.price]
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.8, 1.0))
	hbox.add_child(lbl)
	
	var btn_1 = Button.new()
	btn_1.text = "Vender 1 (+%d)" % item.price
	var item_key = item.key
	btn_1.pressed.connect(func():
		var inv = _get_inv()
		if inv:
			inv.sell_resource(item_key, 1)
			update_shop_ui()
			update_ui()
	)
	hbox.add_child(btn_1)
	
	var btn_all = Button.new()
	btn_all.text = "Vender Tudo (+%d)" % (item.price * item.count)
	btn_all.pressed.connect(func():
		var inv = _get_inv()
		if inv:
			inv.sell_all_resource(item_key)
			update_shop_ui()
			update_ui()
	)
	hbox.add_child(btn_all)
	
	return row

func setup_hotbar() -> void:
	slots.clear()
	if not hotbar: return
	for child in hotbar.get_children():
		child.queue_free()
		
	var inv = _get_inv()
	var h_slots = inv.hotbar_slots if (inv and "hotbar_slots" in inv) else ["pickaxe", "lamp", "ladder", "plank", "brick", "forge"]
	
	for i in range(h_slots.size()):
		var key = h_slots[i]
		var def = {"key": key, "num": str(i + 1), "index": i}
		var slot = _create_slot_panel(def, true)
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
	icon.name = "SlotIcon"
	icon.custom_minimum_size = Vector2(22, 22)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	var k = def.get("key", "")
	if k == "ladder": icon.texture = rope_tex
	elif k == "plank": icon.texture = plank_tex
	elif k == "brick": icon.texture = brick_tex
	elif k == "forge": icon.texture = stone_tex
	elif k == "lamp":
		var atlas = AtlasTexture.new()
		atlas.atlas = lamp_tex
		atlas.region = Rect2(0, 0, 16, 16)
		icon.texture = atlas
	else:
		var atlas = AtlasTexture.new()
		atlas.atlas = extras_tex
		atlas.region = Rect2(0, 0, 16, 16)
		icon.texture = atlas
		
	vbox.add_child(icon)
	
	var label = Label.new()
	label.name = "CountLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.6, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 3)
	label.text = def.get("num", "1")
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
	
	var k = def.get("key", "")
	if k == "ladder": icon.texture = rope_tex
	elif k == "plank": icon.texture = plank_tex
	elif k == "brick": icon.texture = brick_tex
	elif k == "wood": icon.texture = wood_tex
	elif k == "stone" or k == "forge": icon.texture = stone_tex
	elif k == "dirt": icon.texture = dirt_tex
	elif k == "lamp":
		var atlas = AtlasTexture.new()
		atlas.atlas = lamp_tex
		atlas.region = Rect2(0, 0, 16, 16)
		icon.texture = atlas
	elif k == "pickaxe":
		var atlas = AtlasTexture.new()
		atlas.atlas = extras_tex
		atlas.region = Rect2(0, 0, 16, 16)
		icon.texture = atlas
	else:
		var atlas = AtlasTexture.new()
		atlas.atlas = ores_tex
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
		var inv = _get_inv()
		if item_title: item_title.text = def.name
		if item_desc:
			if def.key == "pickaxe" and inv:
				item_desc.text = "%s\n\nDurabilidade: %d%% (%d/100)" % [def.desc, inv.pickaxe_durability, inv.pickaxe_durability]
			else:
				item_desc.text = def.desc
		if equip_button:
			equip_button.visible = def.is_tool
			equip_button.text = "Equipar [%s]" % def.shortcut
		if drop_button:
			drop_button.visible = not def.is_tool or (def.key in ["plank", "lamp", "brick", "forge"])

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
		"pickaxe": return 1 if inv.has_pickaxe else 0
		"lamp": return inv.starter_lamps if "starter_lamps" in inv else 0
		"ladder": return inv.ladders if "ladders" in inv else 0
		"plank": return inv.planks
		"brick": return inv.brick_floors if "brick_floors" in inv else 0
		"forge": return inv.portable_forges if "portable_forges" in inv else 0
		"wood": return inv.wood_logs if "wood_logs" in inv else 0
		"iron": return inv.iron
		"gold": return inv.gold
		"coal": return inv.coal
		"stone": return inv.stone if "stone" in inv else 0
		"dirt": return inv.dirt if "dirt" in inv else 0
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
	
	# Update Hotbar Slots
	var h_slots = inv.hotbar_slots if "hotbar_slots" in inv else ["pickaxe", "lamp", "ladder", "plank", "brick", "forge"]
	if slots.size() != h_slots.size():
		setup_hotbar()
		
	for i in range(slots.size()):
		var slot = slots[i]
		var key = h_slots[i] if i < h_slots.size() else "pickaxe"
		var count_lbl = slot.find_child("CountLabel", true, false)
		var style = slot.get_theme_stylebox("panel")
		
		var is_selected = (i == inv.active_slot)
		if is_selected:
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
			
		if key == "pickaxe":
			if inv.has_pickaxe:
				count_lbl.text = "%d%%" % inv.pickaxe_durability
				slot.modulate = Color.WHITE
			else:
				count_lbl.text = "QUEBR."
				slot.modulate = Color(1.0, 0.4, 0.4, 0.8)
		elif key == "lamp":
			count_lbl.text = "%d" % inv.starter_lamps
			slot.modulate = Color.WHITE if inv.starter_lamps > 0 else Color(1, 1, 1, 0.4)
		elif key == "ladder":
			count_lbl.text = "%d" % inv.ladders
			slot.modulate = Color.WHITE if inv.ladders > 0 else Color(1, 1, 1, 0.4)
		elif key == "plank":
			count_lbl.text = "%d" % inv.planks
			slot.modulate = Color.WHITE if inv.planks > 0 else Color(1, 1, 1, 0.4)
		elif key == "brick":
			count_lbl.text = "%d" % inv.brick_floors
			slot.modulate = Color.WHITE if inv.brick_floors > 0 else Color(1, 1, 1, 0.4)
		elif key == "forge":
			count_lbl.text = "%d" % inv.portable_forges
			slot.modulate = Color.WHITE if inv.portable_forges > 0 else Color(1, 1, 1, 0.4)

	# Update Chest Grid slots counts
	for i in range(chest_slots.size()):
		if i < chest_items_def.size():
			var card = chest_slots[i]
			var def = chest_items_def[i]
			var count_label = card.find_child("SlotCount", true, false)
			if count_label:
				var c = _get_item_count(def.key)
				if def.key == "pickaxe":
					count_label.text = "%d%%" % inv.pickaxe_durability if inv.has_pickaxe else "QUEBRADA"
				else:
					count_label.text = "%d" % c
				
				if c == 0 and def.key != "pickaxe":
					card.modulate = Color(1, 1, 1, 0.4)
				else:
					card.modulate = Color(1, 1, 1, 1.0)
					
	_update_capacity_badge()

func _update_capacity_badge() -> void:
	var inv = _get_inv()
	if not inv: return
	if capacity_badge_label:
		var used = inv.get_total_used()
		capacity_badge_label.text = "Minérios: %d / %d" % [used, inv.MAX_CAPACITY]

func toggle_chest(chest_node: Node = null) -> void:
	if not chest_panel: return
	if chest_panel.visible:
		close_chest()
	else:
		open_chest(chest_node)

func open_chest(chest_node: Node = null) -> void:
	current_chest_node = chest_node
	if chest_panel:
		chest_panel.visible = true
		update_chest_ui()
		if chest_deposit_btn:
			_safe_grab_focus(chest_deposit_btn)

func close_chest() -> void:
	if chest_panel:
		chest_panel.visible = false
	current_chest_node = null

func update_chest_ui() -> void:
	var inv = _get_inv()
	var c_coal = 0
	var c_iron = 0
	var c_gold = 0
	if is_instance_valid(current_chest_node):
		c_coal = current_chest_node.stored_coal
		c_iron = current_chest_node.stored_iron
		c_gold = current_chest_node.stored_gold
		
	if chest_coal_lbl:
		chest_coal_lbl.visible = (c_coal > 0)
		chest_coal_lbl.text = "• Carvão: %d" % c_coal
	if chest_iron_lbl:
		chest_iron_lbl.visible = (c_iron > 0)
		chest_iron_lbl.text = "• Minério de Ferro: %d" % c_iron
	if chest_gold_lbl:
		chest_gold_lbl.visible = (c_gold > 0)
		chest_gold_lbl.text = "• Minério de Ouro: %d" % c_gold
		
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
		elif icon_type == "stone" or icon_type == "forge":
			icon.texture = stone_tex
		elif icon_type == "dirt":
			icon.texture = dirt_tex
		elif icon_type == "lamp":
			var atlas = AtlasTexture.new()
			atlas.atlas = lamp_tex
			atlas.region = Rect2(0, 0, 16, 16)
			icon.texture = atlas
		elif icon_type in ["save", "chest"]:
			var atlas = AtlasTexture.new()
			atlas.atlas = extras_tex
			atlas.region = Rect2(160, 32, 16, 16)
			icon.texture = atlas
		elif icon_type == "ladder":
			icon.texture = rope_tex
		elif icon_type in ["dash", "pickaxe"]:
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
