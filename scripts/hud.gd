extends CanvasLayer

func _safe_grab_focus(ctrl: Control) -> void:
	if is_instance_valid(ctrl):
		if ctrl.focus_mode == Control.FOCUS_NONE:
			ctrl.focus_mode = Control.FOCUS_ALL
		ctrl.grab_focus()

# True quando algum menu (inventário, equipamentos, forja, baú, loja, pausa ou
# configuração de atalhos) está aberto. Usado para travar o movimento do player
# enquanto o teclado navega os menus.
func is_some_panel_open() -> bool:
	var panels: Array = [
		inventory_panel, equipment_panel, shop_panel,
		forge_panel, chest_panel, pause_panel, hotbar_config_panel, death_panel
	]
	for p in panels:
		if is_instance_valid(p) and p.visible:
			return true
	return false

@onready var hotbar = find_child("HotbarVisual", true, false)
@onready var capacity_badge_label = find_child("CapacityLabel", true, false)
@onready var inventory_panel = find_child("InventoryPanel", true, false)
@onready var hotbar_setup_hbox = find_child("HotbarSetBtnsHBox", true, false)
@onready var hotbar_setup_hint = find_child("SetupHint", true, false)
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
var equip_swap_slot: String = "" # Current slot being replaced

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
var column_tex: Texture2D = null

func _get_column_tex() -> Texture2D:
	if column_tex == null:
		var img := Image.create(18, 52, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.12, 0.09, 0.05, 1))
		var base: Image = brick_tex.get_image()
		if base and not base.is_empty():
			var tile := base.duplicate()
			tile.resize(18, 16, Image.INTERPOLATE_NEAREST)
			for i in range(3):
				var yy := 4 + i * 16
				var ox := 3 if i % 2 == 0 else 5
				img.blit_rect(tile, Rect2(0, 0, 18, 16), Vector2i(ox, yy))
		else:
			img.fill(Color(0.6, 0.45, 0.28, 1))
		column_tex = ImageTexture.create_from_image(img)
	return column_tex

func _setup_forge_recipe_icons() -> void:
	var col_row = find_child("ColumnRecipeRow", true, false)
	if col_row:
		var ic = col_row.find_child("Icon", true, false)
		if ic: ic.texture = _get_column_tex()
	var slab_row = find_child("SlabRecipeRow", true, false)
	if slab_row:
		var ic2 = slab_row.find_child("Icon", true, false)
		if ic2: ic2.texture = brick_tex
var broken_pickaxe_tex = preload("res://assets/sprites/broken_pickaxe.png")
var helmet_tex = preload("res://assets/sprites/equip_helmet.png")
var armor_tex = preload("res://assets/sprites/equip_armor.png")
var boots_tex = preload("res://assets/sprites/equip_boots.png")
var pickaxe_tex = preload("res://assets/sprites/equip_pickaxe.png")

# Coins HUD
@onready var coins_badge_container = find_child("CoinsBadgeContainer", true, false)
@onready var coins_hud_label = find_child("CoinsLabel", true, false)

# Profile Badge & EXP HUD
@onready var profile_badge_container = find_child("ProfileBadgeContainer", true, false)
@onready var avatar_rect = find_child("AvatarRect", true, false)
@onready var level_badge_label = find_child("LevelBadgeLabel", true, false)
@onready var exp_progress_bar = find_child("ExpProgressBar", true, false)
@onready var health_bar = find_child("HealthBar", true, false)
@onready var death_panel = find_child("DeathPanel", true, false)
@onready var death_restart_btn = find_child("RestartBtn", true, false)
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
@onready var craft_column_btn = find_child("CraftColumnBtn", true, false)
@onready var craft_slab_btn = find_child("CraftSlabBtn", true, false)
@onready var craft_portable_forge_btn = find_child("CraftPortableForgeBtn", true, false)
var current_forge_node: Node = null
var forge_tab_upgrade: bool = false
var forge_tab_create_btn: Button = null
var forge_tab_upgrade_btn: Button = null
var forge_create_view: VBoxContainer = null
var forge_upgrade_view: VBoxContainer = null

# Pause Menu Reset
@onready var reset_mine_btn = find_child("ResetMineBtn", true, false)

# Equipment Idle Animation
var idle_anim_timer: float = 0.0
var idle_anim_frame: int = 0

# Hotbar Configuration Modal
var hotbar_config_panel: PanelContainer = null
var selected_config_slot: int = -1

var chest_items_def = [
	{
		"key": "pickaxe",
		"name": "Picareta de Mineração",
		"desc": "Ferramenta para escavar lama e minérios. Possui durabilidade e desgasta ao bater em minérios pesados.",
		"icon_type": "atlas",
		"atlas": "extras",
		"region": Rect2(0, 0, 16, 16),
		"shortcut": "1",
		"is_tool": true,
		"tool_slot": 0
	},
	{
		"key": "lamp",
		"name": "Poste de Luz Portátil",
		"desc": "Ilumina cavernas profundas. Posicionável no solo rochoso e sobre tábuas de madeira.",
		"icon_type": "atlas",
		"atlas": "extras",
		"region": Rect2(16, 0, 16, 16),
		"shortcut": "2",
		"is_tool": true,
		"tool_slot": 1
	},
	{
		"key": "ladder",
		"name": "Escada de Madeira",
		"desc": "Construção de madeira para escalar poços verticais. Forjada na Forja com troncos de árvores.",
		"icon_type": "direct",
		"tex": "rope",
		"shortcut": "3",
		"is_tool": true,
		"tool_slot": 2
	},
	{
		"key": "plank",
		"name": "Tábua de Madeira",
		"desc": "Plataforma horizontal resistente para pontes subterrâneas. Permite transpor abismos e sustenta postes de luz.",
		"icon_type": "direct",
		"tex": "plank",
		"shortcut": "4",
		"is_tool": true,
		"tool_slot": 3
	},
	{
		"key": "forge",
		"name": "Forja Portátil",
		"desc": "Forja compacta forjada na superfície. Implante em qualquer lugar do subsolo para forjar sem voltar à superfície!",
		"icon_type": "direct",
		"tex": "stone",
		"shortcut": "6",
		"is_tool": true,
		"tool_slot": 5
	},
	{
		"key": "column",
		"name": "Coluna de Suporte",
		"desc": "Pilar estrutural forjado com lama e pedra. Sustenta blocos 'pendurados' para evitar quedas.",
		"icon_type": "direct",
		"tex": "brick",
		"shortcut": "",
		"is_tool": true,
		"tool_slot": 6
	},
	{
		"key": "slab",
		"name": "Laje de Tijolos",
		"desc": "Laje estrutural de tijolos. Serve de base para apoiar e segurar blocos acima.",
		"icon_type": "direct",
		"tex": "brick",
		"shortcut": "",
		"is_tool": true,
		"tool_slot": 7
	},
	{
		"key": "wood",
		"name": "Madeira (Troncos)",
		"desc": "Troncos nobres obtidos ao podar árvores da superfície ou raízes subterrâneas. Matéria-prima essencial na Forja.",
		"icon_type": "direct",
		"tex": "wood",
		"shortcut": "",
		"is_tool": false
	},
	{
		"key": "iron",
		"name": "Minério de Ferro",
		"desc": "Minério bruto resistente e condutor. Usado para criar ferramentas, postes e aprimorar equipamentos.",
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
		"name": "Lama",
		"desc": "Lama coletada das escavações. Usada para moldar e forjar pisos de tijolo.",
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
	idle_anim_timer += delta
	if idle_anim_timer >= 0.1: # 10 FPS
		idle_anim_timer = 0.0
		idle_anim_frame = (idle_anim_frame + 1) % 16
		
		# Animate HUD Top-Left Avatar (Focused tightly on character face/head)
		if is_instance_valid(avatar_rect) and avatar_rect.texture is AtlasTexture:
			avatar_rect.texture.region = Rect2(idle_anim_frame * 32.0 + 9.0, 11.0, 14.0, 10.0)
			
		# Animate Equipment Menu Character Preview
		if is_instance_valid(equipment_panel) and equipment_panel.visible:
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
	var sell_all_btn = find_child("SellAllMineralsBtn", true, false)
	if sell_all_btn and not sell_all_btn.pressed.is_connected(_on_sell_all_minerals):
		sell_all_btn.pressed.connect(_on_sell_all_minerals)

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
	if death_restart_btn and not death_restart_btn.pressed.is_connected(_on_death_restart):
		death_restart_btn.pressed.connect(_on_death_restart)
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
	if craft_pickaxe_btn and not craft_pickaxe_btn.pressed.is_connected(_on_craft_pickaxe):
		craft_pickaxe_btn.pressed.connect(_on_craft_pickaxe)
	if craft_column_btn and not craft_column_btn.pressed.is_connected(_on_craft_column):
		craft_column_btn.pressed.connect(_on_craft_column)
	if craft_slab_btn and not craft_slab_btn.pressed.is_connected(_on_craft_slab):
		craft_slab_btn.pressed.connect(_on_craft_slab)
	if craft_portable_forge_btn and not craft_portable_forge_btn.pressed.is_connected(_on_craft_portable_forge):
		craft_portable_forge_btn.pressed.connect(_on_craft_portable_forge)
		
	_setup_forge_tabs()
	_setup_equipment_slot_interactions()
	_setup_forge_recipe_icons()
	
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

		# Toggle Shop Menu with [L]
		if event.physical_keycode == KEY_L:
			toggle_shop()
			_consume_input()
			return

		# Toggle Inventory with [I]
		if event.physical_keycode == KEY_I:
			toggle()
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
	hotbar_config_panel.custom_minimum_size = Vector2(420, 260)
	hotbar_config_panel.anchors_preset = Control.PRESET_CENTER
	hotbar_config_panel.anchor_left = 0.5
	hotbar_config_panel.anchor_top = 0.5
	hotbar_config_panel.anchor_right = 0.5
	hotbar_config_panel.anchor_bottom = 0.5
	hotbar_config_panel.offset_left = -210
	hotbar_config_panel.offset_top = -130
	hotbar_config_panel.offset_right = 210
	hotbar_config_panel.offset_bottom = 130
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.12, 0.06, 0.98)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.8, 0.6, 0.2, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	hotbar_config_panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	hotbar_config_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "⚙ CONFIGURAR ATALHOS DA HOTBAR (1-6)"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = "Clique em um slot (1-6) e depois selecione o item desejado:"
	desc.add_theme_font_size_override("font_size", 11)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)
	
	var slots_hbox = HBoxContainer.new()
	slots_hbox.name = "SlotsHBox"
	slots_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slots_hbox.add_theme_constant_override("separation", 6)
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
			{"key": "pickaxe", "label": "Picareta"},
			{"key": "lamp", "label": "Poste de Luz"},
			{"key": "ladder", "label": "Escada"},
			{"key": "plank", "label": "Tabua"}
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

# Setup Forge Tabs and Views
func _setup_forge_tabs() -> void:
	if not is_instance_valid(forge_panel): return
	var content_margin = forge_panel.find_child("ContentMargin", true, false)
	if not content_margin: return
	var inner_vbox = content_margin.get_node_or_null("InnerVBox")
	if not inner_vbox: return
	
	# Check if Tab bar already exists
	var tab_bar = inner_vbox.get_node_or_null("ForgeTabBar")
	if not tab_bar:
		tab_bar = HBoxContainer.new()
		tab_bar.name = "ForgeTabBar"
		tab_bar.add_theme_constant_override("separation", 10)
		inner_vbox.add_child(tab_bar)
		inner_vbox.move_child(tab_bar, 0)
		
		forge_tab_create_btn = Button.new()
		forge_tab_create_btn.text = "⚒ CRIAR ITENS"
		forge_tab_create_btn.custom_minimum_size = Vector2(0, 32)
		forge_tab_create_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		forge_tab_create_btn.add_theme_font_size_override("font_size", 13)
		forge_tab_create_btn.pressed.connect(func():
			forge_tab_upgrade = false
			_update_forge_tab_visibility()
		)
		tab_bar.add_child(forge_tab_create_btn)
		
		forge_tab_upgrade_btn = Button.new()
		forge_tab_upgrade_btn.text = "⭐ APRIMORAR EQUIPES"
		forge_tab_upgrade_btn.custom_minimum_size = Vector2(0, 32)
		forge_tab_upgrade_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		forge_tab_upgrade_btn.add_theme_font_size_override("font_size", 13)
		forge_tab_upgrade_btn.pressed.connect(func():
			forge_tab_upgrade = true
			_update_forge_tab_visibility()
		)
		tab_bar.add_child(forge_tab_upgrade_btn)
		
		# Upgrade View container
		forge_upgrade_view = VBoxContainer.new()
		forge_upgrade_view.name = "ForgeUpgradeView"
		forge_upgrade_view.custom_minimum_size = Vector2(0, 240)
		forge_upgrade_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
		forge_upgrade_view.add_theme_constant_override("separation", 8)
		forge_upgrade_view.visible = false
		
		var scroll = ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		forge_upgrade_view.add_child(scroll)
		
		var up_rows = VBoxContainer.new()
		up_rows.name = "UpgradeRowsContainer"
		up_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		up_rows.add_theme_constant_override("separation", 8)
		scroll.add_child(up_rows)
		
		inner_vbox.add_child(forge_upgrade_view)

func _update_forge_tab_visibility() -> void:
	if not is_instance_valid(forge_panel): return
	var content_margin = forge_panel.find_child("ContentMargin", true, false)
	if not content_margin: return
	var inner_vbox = content_margin.get_node_or_null("InnerVBox")
	if not inner_vbox: return
	
	var recipes = inner_vbox.get_node_or_null("RecipesVBox")
	var up_view = inner_vbox.get_node_or_null("ForgeUpgradeView")
	
	if forge_tab_upgrade:
		if recipes: recipes.visible = false
		if up_view: up_view.visible = true
		if forge_tab_create_btn: forge_tab_create_btn.modulate = Color(0.7, 0.7, 0.7, 1.0)
		if forge_tab_upgrade_btn: forge_tab_upgrade_btn.modulate = Color(1.2, 1.2, 0.8, 1.0)
	else:
		if recipes: recipes.visible = true
		if up_view: up_view.visible = false
		if forge_tab_create_btn: forge_tab_create_btn.modulate = Color(1.2, 1.2, 0.8, 1.0)
		if forge_tab_upgrade_btn: forge_tab_upgrade_btn.modulate = Color(0.7, 0.7, 0.7, 1.0)
		
	update_forge_ui()

# Setup Equipment Slot Interactions (Replacing/Equipping Gear)
func _setup_equipment_slot_interactions() -> void:
	if not is_instance_valid(equipment_panel): return
	var slots_vbox = equipment_panel.find_child("SlotsVBox", true, false)
	if not slots_vbox: return
	
	var slot_nodes = [
		{"node": slots_vbox.get_node_or_null("SlotHelmet"), "slot": "helmet"},
		{"node": slots_vbox.get_node_or_null("SlotPickaxe"), "slot": "pickaxe"},
		{"node": slots_vbox.get_node_or_null("SlotArmor"), "slot": "armor"},
		{"node": slots_vbox.get_node_or_null("SlotBoots"), "slot": "boots"},
		{"node": slots_vbox.get_node_or_null("SlotGlove"), "slot": "glove"}
	]
	
	for sn in slot_nodes:
		if is_instance_valid(sn.node):
			var slot_type = sn.slot
			var hbox = sn.node.find_child("HBox", true, false)
			if hbox and not hbox.has_node("SwapBtn"):
				var swap_btn = Button.new()
				swap_btn.name = "SwapBtn"
				swap_btn.text = "Substituir [Z]"
				swap_btn.custom_minimum_size = Vector2(100, 28)
				swap_btn.pressed.connect(func(): _open_equipment_swap(slot_type))
				hbox.add_child(swap_btn)

func _open_equipment_swap(slot_type: String) -> void:
	equip_swap_slot = slot_type
	var inv = _get_inv()
	if not inv: return
	
	# Create or show replacement selection modal
	var modal = find_child("EquipSwapModal", true, false)
	if is_instance_valid(modal):
		modal.queue_free()
		
	modal = PanelContainer.new()
	modal.name = "EquipSwapModal"
	modal.custom_minimum_size = Vector2(360, 240)
	modal.anchors_preset = Control.PRESET_CENTER
	modal.anchor_left = 0.5
	modal.anchor_top = 0.5
	modal.anchor_right = 0.5
	modal.anchor_bottom = 0.5
	modal.offset_left = -180
	modal.offset_top = -120
	modal.offset_right = 180
	modal.offset_bottom = 120
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.12, 0.06, 0.98)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.85, 0.7, 0.25, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	modal.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	modal.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	var slot_title = "CAPACETE"
	var owned_list = inv.owned_helmets
	var cur_equipped = inv.equipped_helmet
	if slot_type == "pickaxe":
		slot_title = "PICARETA"
		owned_list = inv.owned_pickaxes
		cur_equipped = inv.equipped_pickaxe
	elif slot_type == "armor":
		slot_title = "TRAJE"
		owned_list = inv.owned_armors
		cur_equipped = inv.equipped_armor
	elif slot_type == "boots":
		slot_title = "BOTAS"
		owned_list = inv.owned_boots
		cur_equipped = inv.equipped_boots
	elif slot_type == "glove":
		slot_title = "LUVAS"
		owned_list = inv.owned_gloves
		cur_equipped = inv.equipped_glove
		
	var tlabel = Label.new()
	tlabel.text = "SUBSTITUIR %s:" % slot_title
	tlabel.add_theme_font_size_override("font_size", 13)
	tlabel.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1.0))
	vbox.add_child(tlabel)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	var list_vbox = VBoxContainer.new()
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(list_vbox)
	
	for item_id in owned_list:
		var def = inv.EQUIPMENT_DEFS.get(item_id, {})
		var row = PanelContainer.new()
		var r_style = StyleBoxFlat.new()
		r_style.bg_color = Color(0.12, 0.08, 0.04, 0.9)
		r_style.border_width_left = 1
		r_style.border_width_top = 1
		r_style.border_width_right = 1
		r_style.border_width_bottom = 1
		r_style.border_color = Color(0.4, 0.3, 0.15, 1)
		r_style.corner_radius_top_left = 4
		r_style.corner_radius_top_right = 4
		r_style.corner_radius_bottom_right = 4
		r_style.corner_radius_bottom_left = 4
		row.add_theme_stylebox_override("panel", r_style)
		
		var rm = MarginContainer.new()
		rm.add_theme_constant_override("margin_left", 6)
		rm.add_theme_constant_override("margin_top", 4)
		rm.add_theme_constant_override("margin_right", 6)
		rm.add_theme_constant_override("margin_bottom", 4)
		row.add_child(rm)
		
		var rhbox = HBoxContainer.new()
		rhbox.add_theme_constant_override("separation", 8)
		rm.add_child(rhbox)
		
		var ilbl = Label.new()
		ilbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ilbl.text = "%s
%s" % [def.get("name", item_id), def.get("desc", "")]
		ilbl.add_theme_font_size_override("font_size", 11)
		rhbox.add_child(ilbl)
		
		var ebtn = Button.new()
		if item_id == cur_equipped:
			ebtn.text = "✓ Em Uso"
			ebtn.disabled = true
		else:
			ebtn.text = "Equipar"
			var i_key = item_id
			ebtn.pressed.connect(func():
				inv.equip_gear(i_key)
				modal.queue_free()
				update_equipment_ui()
				update_ui()
			)
		rhbox.add_child(ebtn)
		list_vbox.add_child(row)
		
	var close_b = Button.new()
	close_b.text = "Fechar [X]"
	close_b.pressed.connect(func(): modal.queue_free())
	vbox.add_child(close_b)
	
	add_child(modal)

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

func _on_craft_column() -> void:
	var inv = _get_inv()
	if inv:
		if inv.craft_column():
			update_forge_ui()
			update_ui()
		else:
			show_toast("Recursos insuficientes! Requer 3 Lamas e 3 Pedras.", "plank")

func _on_craft_slab() -> void:
	var inv = _get_inv()
	if inv:
		if inv.craft_slab():
			update_forge_ui()
			update_ui()
		else:
			show_toast("Recursos insuficientes! Requer 2 Lamas e 2 Pedras.", "plank")

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
		_update_forge_tab_visibility()
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
	
	# Update Forge materials scoreboard
	_update_forge_materials()
	
	if not craft_pickaxe_btn: craft_pickaxe_btn = find_child("CraftPickaxeBtn", true, false)
	if craft_pickaxe_btn:
		craft_pickaxe_btn.disabled = not inv.can_craft_pickaxe()
	if craft_lamp_btn:
		craft_lamp_btn.disabled = not inv.can_craft_lamp()
	if craft_ladder_btn:
		craft_ladder_btn.disabled = not inv.can_craft_ladders()
	if craft_plank_btn:
		craft_plank_btn.disabled = not inv.can_craft_planks()
	if not craft_column_btn: craft_column_btn = find_child("CraftColumnBtn", true, false)
	if craft_column_btn:
		craft_column_btn.disabled = not inv.can_craft_column()
	if not craft_slab_btn: craft_slab_btn = find_child("CraftSlabBtn", true, false)
	if craft_slab_btn:
		craft_slab_btn.disabled = not inv.can_craft_slab()
	if not craft_portable_forge_btn: craft_portable_forge_btn = find_child("CraftPortableForgeBtn", true, false)
	if craft_portable_forge_btn:
		craft_portable_forge_btn.disabled = not inv.can_craft_portable_forge()
		
	# Update Forge Upgrade View rows
	var up_rows = find_child("UpgradeRowsContainer", true, false)
	if up_rows:
		for c in up_rows.get_children(): c.queue_free()
		for up in inv.build_forge_upgrade_rows():
			var row = _create_forge_upgrade_row(up)
			up_rows.add_child(row)

func _make_ores_icon(kind: String) -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.atlas = ores_tex
	match kind:
		"coal": atlas.region = Rect2(0, 128, 16, 16)
		"iron": atlas.region = Rect2(32, 128, 16, 16)
		"gold": atlas.region = Rect2(128, 128, 16, 16)
	return atlas

func _update_forge_materials() -> void:
	var inv = _get_inv()
	if not inv: return
	var panel = find_child("MaterialsPanel", true, false)
	if not panel: return
	var margin = panel.get_child(0) if panel.get_child_count() > 0 else null
	if not margin: return
	for c in margin.get_children():
		margin.remove_child(c)
		c.queue_free()
	
	var mats: Array = [
		{"tex": wood_tex, "name": "Troncos", "count": inv.wood_logs},
		{"tex": _make_ores_icon("coal"), "name": "Carvoes", "count": inv.coal},
		{"tex": _make_ores_icon("iron"), "name": "Ferros", "count": inv.iron},
		{"tex": _make_ores_icon("gold"), "name": "Ouros", "count": inv.gold},
		{"tex": stone_tex, "name": "Pedras", "count": inv.stone},
		{"tex": dirt_tex, "name": "Lamas", "count": inv.dirt},
		{"tex": plank_tex, "name": "Tabuas", "count": inv.planks},
		{"tex": rope_tex, "name": "Escadas", "count": inv.ladders},
		{"tex": _get_column_tex(), "name": "Colunas", "count": inv.columns},
		{"tex": brick_tex, "name": "Lajes", "count": inv.slabs}
	]
	
	var owned: Array = []
	for m in mats:
		if m.count > 0:
			owned.append(m)
	
	var empty_lbl = Label.new()
	empty_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_lbl.add_theme_font_size_override("font_size", 12)
	empty_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.7, 1))
	
	if owned.is_empty():
		empty_lbl.text = "Nenhum material util"
		margin.add_child(empty_lbl)
		return
	
	var grid = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 4)
	margin.add_child(grid)
	
	for m in owned:
		var chip = HBoxContainer.new()
		chip.add_theme_constant_override("separation", 4)
		var icon = TextureRect.new()
		icon.texture = m.tex
		icon.custom_minimum_size = Vector2(14, 14)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		chip.add_child(icon)
		var count_lbl = Label.new()
		count_lbl.text = "%d %s" % [m.count, m.name]
		count_lbl.add_theme_font_size_override("font_size", 11)
		count_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.7, 1))
		chip.add_child(count_lbl)
		grid.add_child(chip)

func _create_forge_upgrade_row(up: Dictionary) -> PanelContainer:
	var inv = _get_inv()
	var row = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.10, 0.05, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.35, 0.18, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	row.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	row.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)
	
	var equip_def: Dictionary = {}
	if inv:
		equip_def = inv.get_equipped_def(up.get("target_slot", ""))
	var row_icon = TextureRect.new()
	row_icon.custom_minimum_size = Vector2(28, 28)
	row_icon.texture = _equip_icon_tex(equip_def.get("icon", ""))
	row_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	row_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row_icon.modulate = _equip_tint(equip_def, up.get("current_level", 0), up.get("max_level", 5))
	hbox.add_child(row_icon)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = "%s  (%d/%d)" % [up.get("name", ""), up.get("current_level", 0), up.get("max_level", 5)]
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4, 1.0))
	vbox.add_child(title_lbl)
	
	var desc_lbl = Label.new()
	var cost_text = _format_upgrade_cost(up.get("cost", {}))
	desc_lbl.text = up.get("desc", "") + (("\nCusto: " + cost_text) if not cost_text.is_empty() else "")
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7, 1.0))
	vbox.add_child(desc_lbl)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(130, 32)
	var req_lvl = up.get("level_req", 0)
	
	if up.get("maxed", false):
		btn.text = "✓ Nível Máximo"
		btn.disabled = true
	elif inv and inv.level < req_lvl:
		btn.text = "🔒 Nível %d" % req_lvl
		btn.disabled = true
	else:
		var can_up = inv.can_forge_upgrade(up) if inv else false
		btn.text = "Aprimorar"
		btn.disabled = not can_up
		var up_def = up
		btn.pressed.connect(func():
			if inv and inv.execute_forge_upgrade_def(up_def):
				update_forge_ui()
				update_ui()
		)
	hbox.add_child(btn)
	
	return row

func _format_upgrade_cost(cost: Dictionary) -> String:
	var parts = []
	for k in cost:
		var name_str = k.capitalize()
		if k == "iron": name_str = "Ferro"
		elif k == "gold": name_str = "Ouro"
		elif k == "coal": name_str = "Carvão"
		elif k == "wood": name_str = "Madeira"
		elif k == "stone": name_str = "Pedra"
		elif k == "plank": name_str = "Tábua"
		elif k == "dirt": name_str = "Lama"
		parts.append("%d %s" % [cost[k], name_str])
	return ", ".join(parts)

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
		update_equipment_ui()
		if equip_close_btn:
			_safe_grab_focus(equip_close_btn)

func close_equipment() -> void:
	if equipment_panel:
		equipment_panel.visible = false
	var swap_modal = find_child("EquipSwapModal", true, false)
	if is_instance_valid(swap_modal):
		swap_modal.queue_free()

func update_equipment_ui() -> void:
	var inv = _get_inv()
	if not inv or not is_instance_valid(equipment_panel): return
	
	var lvl = inv.level if "level" in inv else 0
	
	var slots_vbox = equipment_panel.find_child("SlotsVBox", true, false)
	if not slots_vbox: return
	
	var h_def = inv.get_equipped_def("helmet")
	var p_def = inv.get_equipped_def("pickaxe")
	var a_def = inv.get_equipped_def("armor")
	var b_def = inv.get_equipped_def("boots")
	var g_def = inv.get_equipped_def("glove")
	
	_update_single_slot_ui(slots_vbox.get_node_or_null("SlotHelmet"), h_def, "helmet")
	_update_single_slot_ui(slots_vbox.get_node_or_null("SlotPickaxe"), p_def, "pickaxe")
	_update_single_slot_ui(slots_vbox.get_node_or_null("SlotArmor"), a_def, "armor")
	_update_single_slot_ui(slots_vbox.get_node_or_null("SlotBoots"), b_def, "boots")
	_update_single_slot_ui(slots_vbox.get_node_or_null("SlotGlove"), g_def, "glove")
	
	var stats_lbl = equipment_panel.find_child("StatsLabel", true, false)
	if stats_lbl:
		var dmg = inv.get_strength() if inv.has_method("get_strength") else inv.get_pickaxe_damage()
		var limit = _status_limit(lvl)
		var spd = mini(int(round(inv.get_boots_speed_multiplier() * 10.0)), limit)
		var jmp = mini(int(round(inv.get_boots_jump_multiplier() * 10.0)), limit)
		stats_lbl.text = "%d\n%d/%d\n%d/%d" % [dmg, spd, limit, jmp, limit]

	var char_desc = equipment_panel.find_child("CharDesc", true, false)
	if char_desc:
		char_desc.text = "Nível: %d" % lvl

	var health_badge = equipment_panel.find_child("HealthBadge", true, false)
	if health_badge:
		var hp_lbl = health_badge.find_child("HealthText", true, false)
		if hp_lbl:
			var max_hp = inv.get_max_health() if inv.has_method("get_max_health") else 100
			var cur_hp = int(inv.current_health if "current_health" in inv else max_hp)
			hp_lbl.text = "%d / %d" % [cur_hp, max_hp]

	var res_badge = equipment_panel.find_child("ResBadge", true, false)
	if res_badge:
		var res_lbl = res_badge.find_child("ResText", true, false)
		if res_lbl:
			res_lbl.text = "%d" % (inv.get_resistance() if inv.has_method("get_resistance") else 0)
func _status_limit(level: int) -> int:
	var decades: int = level / 10
	return 10 + level * 3 + decades * (decades + 1) / 2
func _update_single_slot_ui(slot_node: Node, def: Dictionary, slot: String) -> void:
	if not is_instance_valid(slot_node) or def.is_empty(): return
	var inv = _get_inv()
	var name_lbl = slot_node.find_child("ItemName", true, false)
	var desc_lbl = slot_node.find_child("ItemDesc", true, false)
	var lvl = inv.get_upgrade_level(slot) if inv else 0
	var icon = slot_node.find_child("SlotIcon", true, false)
	if icon:
		icon.modulate = _equip_tint(def, lvl, inv.UPGRADE_MAX_LEVEL if inv else 5)
	if name_lbl:
		var nm = def.get("name", "")
		if lvl > 0:
			nm += "  [Nivel %d/%d]" % [lvl, inv.UPGRADE_MAX_LEVEL]
		name_lbl.text = nm
	if desc_lbl:
		var desc = def.get("desc", "")
		if lvl > 0:
			var bonus := ""
			match slot:
				"pickaxe": bonus = "+%d de dano e +%d%% de durabilidade/velocidade de mineracao" % [lvl * 2, lvl * 10]
				"helmet": bonus = "+%d de alcance de luz na escuridao" % int(lvl * 60)
				"armor": bonus = "+%d de carga maxima na mochila" % (lvl * 20)
				"boots": bonus = "+%d%% de altura de pulo e +%d%% de velocidade" % [lvl * 20, lvl * 15]
				"glove": bonus = "+%d de forca e +%d de dano de chute" % [lvl, lvl]
			desc += "\nNivel %d: %s." % [lvl, bonus]
		desc_lbl.text = desc

func _equip_icon_tex(icon_type: String) -> Texture2D:
	match icon_type:
		"helmet": return helmet_tex
		"pickaxe": return pickaxe_tex
		"armor": return armor_tex
		"boots": return boots_tex
		"glove": return pickaxe_tex
		_: return helmet_tex

func _equip_tint(def: Dictionary, lvl: int = 0, max_lvl: int = 5) -> Color:
	var base = def.get("color", Color.WHITE)
	if lvl > 0 and max_lvl > 0:
		return base.lerp(Color(1.0, 0.92, 0.4), clampf(float(lvl) / float(max_lvl), 0.0, 1.0))
	return base

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
		_refresh_inventory_hotbar_setup()
		if close_button:
			_safe_grab_focus(close_button)

func _refresh_inventory_hotbar_setup() -> void:
	if not is_instance_valid(hotbar_setup_hbox): return
	var inv = _get_inv()
	if not inv: return
	for c in hotbar_setup_hbox.get_children():
		c.queue_free()
	for i in range(inv.hotbar_slots.size()):
		var key = inv.hotbar_slots[i]
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(44, 44)
		panel.focus_mode = Control.FOCUS_NONE
		
		var st = StyleBoxFlat.new()
		st.bg_color = Color(0.16, 0.1, 0.05, 0.95)
		st.border_width_left = 2
		st.border_width_top = 2
		st.border_width_right = 2
		st.border_width_bottom = 2
		st.border_color = Color(0.45, 0.3, 0.15, 1)
		st.corner_radius_top_left = 6
		st.corner_radius_top_right = 6
		st.corner_radius_bottom_right = 6
		st.corner_radius_bottom_left = 6
		
		if i == selected_config_slot:
			st.border_color = Color(1.0, 0.88, 0.25, 1.0)
			st.border_width_left = 3
			st.border_width_top = 3
			st.border_width_right = 3
			st.border_width_bottom = 3
			st.bg_color = Color(0.28, 0.16, 0.08, 0.98)
		
		panel.add_theme_stylebox_override("panel", st)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 2)
		margin.add_theme_constant_override("margin_top", 2)
		margin.add_theme_constant_override("margin_right", 2)
		margin.add_theme_constant_override("margin_bottom", 2)
		panel.add_child(margin)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 1)
		margin.add_child(vbox)
		
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		if key == "ladder": icon.texture = rope_tex
		elif key == "plank": icon.texture = plank_tex
		elif key == "column": icon.texture = _get_column_tex()
		elif key == "slab": icon.texture = brick_tex
		elif key == "forge": icon.texture = stone_tex
		elif key == "lamp":
			var atlas = AtlasTexture.new()
			atlas.atlas = lamp_tex
			atlas.region = Rect2(0, 0, 16, 16)
			icon.texture = atlas
		elif key == "pickaxe":
			var atlas2 = AtlasTexture.new()
			atlas2.atlas = extras_tex
			atlas2.region = Rect2(0, 0, 16, 16)
			icon.texture = atlas2
		else:
			var atlas3 = AtlasTexture.new()
			atlas3.atlas = extras_tex
			atlas3.region = Rect2(0, 0, 16, 16)
			icon.texture = atlas3
		
		vbox.add_child(icon)
		
		var num_label = Label.new()
		num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num_label.add_theme_font_size_override("font_size", 9)
		num_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6, 1))
		num_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		num_label.add_theme_constant_override("outline_size", 3)
		num_label.text = str(i + 1)
		vbox.add_child(num_label)
		
		panel.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				selected_config_slot = i
				_refresh_inventory_hotbar_setup()
				if is_instance_valid(hotbar_setup_hint):
					hotbar_setup_hint.text = "Atalho %d selecionado. Clique num item." % (i + 1)
		)
		hotbar_setup_hbox.add_child(panel)
	if is_instance_valid(hotbar_setup_hint) and selected_config_slot < 0:
		hotbar_setup_hint.text = "Selecione o atalho, depois o item."

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

func show_death_screen() -> void:
	if death_panel:
		death_panel.visible = true
	update_ui()
	if death_restart_btn:
		_safe_grab_focus(death_restart_btn)

func _on_death_restart() -> void:
	if death_panel:
		death_panel.visible = false
	var inv = _get_inv()
	if inv and inv.has_method("heal_full"):
		inv.heal_full()
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").restart_run_to_surface()
	update_ui()

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
		_on_shop_tab_buy()
		update_shop_ui()
		if shop_tab_buy_btn:
			_safe_grab_focus(shop_tab_buy_btn)

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
	update_shop_ui()

func _on_shop_tab_sell() -> void:
	if shop_buy_view: shop_buy_view.visible = false
	if shop_sell_view: shop_sell_view.visible = true
	if shop_tab_sell_btn: shop_tab_sell_btn.modulate = Color(1.2, 1.2, 0.8, 1.0)
	if shop_tab_buy_btn: shop_tab_buy_btn.modulate = Color(0.7, 0.7, 0.7, 1.0)
	update_shop_ui()

func _on_sell_all_minerals() -> void:
	var inv = _get_inv()
	if inv and inv.sell_all_minerals() > 0:
		update_shop_ui()
		update_ui()

func update_shop_ui() -> void:
	var inv = _get_inv()
	if not inv: return
	
	if shop_coins_label:
		shop_coins_label.text = "[O] Moedas de Ouro: %d" % inv.coins
		
	# 1. Update BUY tab with purchasable equipment
	var buy_container = find_child("BuyRowsContainer", true, false)
	if buy_container:
		for child in buy_container.get_children(): child.queue_free()
		var buyable_keys = [
			"pickaxe_iron",
			"pickaxe_gold",
			"helmet_lamp",
			"boots_leather",
			"armor_reinforced",
			"helmet_iron_lamp",
			"boots_steel",
			"armor_explorer",
			"glove_iron",
			"glove_gold"
		]
		for key in buyable_keys:
			var def = inv.EQUIPMENT_DEFS.get(key, {})
			if not def.is_empty():
				var row = _create_shop_buy_row(def)
				buy_container.add_child(row)
		
	# 2. Update SELL tab (STRICTLY only items with count > 0)
	var sell_container = find_child("SellRowsContainer", true, false)
	if sell_container:
		for child in sell_container.get_children():
			child.queue_free()
			
		var sellable = [
			{"key": "coal", "name": "Carvão Mineral", "price": inv.COAL_PRICE, "count": inv.coal, "tex": _make_ores_icon("coal")},
			{"key": "iron", "name": "Minério de Ferro", "price": inv.IRON_PRICE, "count": inv.iron, "tex": _make_ores_icon("iron")},
			{"key": "gold", "name": "Minério de Ouro", "price": inv.GOLD_PRICE, "count": inv.gold, "tex": _make_ores_icon("gold")},
			{"key": "wood", "name": "Madeira (Troncos)", "price": inv.WOOD_PRICE, "count": inv.wood_logs, "tex": wood_tex},
			{"key": "stone", "name": "Pedra", "price": inv.STONE_PRICE, "count": inv.stone, "tex": stone_tex},
			{"key": "dirt", "name": "Lama", "price": inv.DIRT_PRICE, "count": inv.dirt, "tex": dirt_tex},
			{"key": "plank", "name": "Tábua de Madeira", "price": inv.PLANK_PRICE, "count": inv.planks, "tex": plank_tex},
			{"key": "ladder", "name": "Escada", "price": inv.LADDER_PRICE, "count": inv.ladders, "tex": rope_tex}
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
		
		var sell_all_btn = find_child("SellAllMineralsBtn", true, false)
		if sell_all_btn:
			sell_all_btn.disabled = not has_any

func _create_shop_buy_row(def: Dictionary) -> PanelContainer:
	var inv = _get_inv()
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
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	row.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	margin.add_child(hbox)
	
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(28, 28)
	icon_rect.texture = _equip_icon_tex(def.get("icon", ""))
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_rect.modulate = _equip_tint(def, 0, 5)
	hbox.add_child(icon_rect)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = "%s — Custo: %d Moedas" % [def.get("name", ""), def.get("cost_coins", 0)]
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45, 1.0))
	vbox.add_child(title_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = def.get("desc", "")
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7, 1.0))
	vbox.add_child(desc_lbl)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(110, 30)
	
	var item_id = def.get("id", "")
	var req_lvl = def.get("level_req", 0)
	var cost = def.get("cost_coins", 0)
	
	var already_owned = false
	if inv:
		if item_id in inv.owned_helmets or item_id in inv.owned_pickaxes or item_id in inv.owned_armors or item_id in inv.owned_boots or item_id in inv.owned_gloves:
			already_owned = true
			
	if already_owned:
		btn.text = "✓ Possui"
		btn.disabled = true
	elif inv and inv.level < req_lvl:
		btn.text = "🔒 Nível %d" % req_lvl
		btn.disabled = true
	else:
		btn.text = "Comprar [Z]"
		btn.disabled = (inv == null or inv.coins < cost)
		btn.pressed.connect(func():
			if inv and inv.buy_shop_item(item_id):
				update_shop_ui()
				update_ui()
		)
	hbox.add_child(btn)
	
	return row

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
	
	if item.has("tex") and item.tex:
		var sell_icon = TextureRect.new()
		sell_icon.texture = item.tex
		sell_icon.custom_minimum_size = Vector2(20, 20)
		sell_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sell_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sell_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hbox.add_child(sell_icon)
	
	var lbl = Label.new()
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.text = "%s (x%d) — Preço: %d moedas cada" % [item.name, item.count, item.price]
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.8, 1.0))
	hbox.add_child(lbl)
	
	# Botões empilhados (um abaixo do outro), alinhados à direita
	var margin_btns = MarginContainer.new()
	var margin_vbox = VBoxContainer.new()
	margin_vbox.add_theme_constant_override("separation", 4)
	var btn_1 = Button.new()
	btn_1.text = "Vender 1 (+%d)" % item.price
	btn_1.custom_minimum_size = Vector2(160, 26)
	btn_1.size_flags_horizontal = Control.SIZE_SHRINK_END
	var item_key = item.key
	btn_1.pressed.connect(func():
		var inv = _get_inv()
		if inv:
			inv.sell_resource(item_key, 1)
			update_shop_ui()
			update_ui()
	)
	margin_vbox.add_child(btn_1)
	
	var btn_all = Button.new()
	btn_all.text = "Vender Tudo (+%d)" % (item.price * item.count)
	btn_all.custom_minimum_size = Vector2(160, 26)
	btn_all.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn_all.pressed.connect(func():
		var inv = _get_inv()
		if inv:
			inv.sell_all_resource(item_key)
			update_shop_ui()
			update_ui()
	)
	margin_vbox.add_child(btn_all)
	margin_btns.add_child(margin_vbox)
	hbox.add_child(margin_btns)
	
	return row

func setup_hotbar() -> void:
	slots.clear()
	if not hotbar: return
	for child in hotbar.get_children():
		child.queue_free()
		
	var inv = _get_inv()
	var h_slots = inv.hotbar_slots if (inv and "hotbar_slots" in inv) else ["pickaxe", "lamp", "ladder", "plank"]
	
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
	panel.custom_minimum_size = Vector2(44, 44)
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
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
	margin.add_theme_constant_override("margin_left", 2)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_right", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 1)
	margin.add_child(vbox)
	
	var icon = TextureRect.new()
	icon.name = "SlotIcon"
	icon.custom_minimum_size = Vector2(20, 22)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	var k = def.get("key", "")
	if k == "ladder": icon.texture = rope_tex
	elif k == "plank": icon.texture = plank_tex
	elif k == "column": icon.texture = _get_column_tex()
	elif k == "slab": icon.texture = brick_tex
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
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
	elif k == "column": icon.texture = _get_column_tex()
	elif k == "slab": icon.texture = brick_tex
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
	count_label.add_theme_font_size_override("font_size", 10)
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
				if idx >= 0 and idx < chest_items_def.size():
					var def = chest_items_def[idx]
					var item_k = def.get("key", "")
					var inv = _get_inv()
					if item_k != "" and selected_config_slot >= 0 and inv \
							and "hotbar_slots" in inv and selected_config_slot < inv.hotbar_slots.size():
						inv.set_hotbar_slot(selected_config_slot, item_k)
						update_ui()
						_refresh_inventory_hotbar_setup()
						show_toast("Atalho %d: %s" % [selected_config_slot + 1, def.get("name", item_k)], item_k)
						selected_config_slot = -1
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
				item_desc.text = "%s

Durabilidade: %d/%d" % [def.desc, inv.pickaxe_durability, inv.max_pickaxe_durability]
			else:
				item_desc.text = def.desc
		if equip_button:
			equip_button.visible = def.is_tool
			equip_button.text = "Equipar [%s]" % def.shortcut
		if drop_button:
			drop_button.visible = not def.is_tool or (def.key in ["plank", "lamp", "forge"])

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
		"column": return inv.columns if "columns" in inv else 0
		"slab": return inv.slabs if "slabs" in inv else 0
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

	if health_bar:
		var max_hp = inv.get_max_health() if inv.has_method("get_max_health") else 100
		health_bar.max_value = float(max_hp)
		health_bar.value = float(inv.current_health if "current_health" in inv else max_hp)
	
	# Update Hotbar Slots
	var h_slots = inv.hotbar_slots if "hotbar_slots" in inv else ["pickaxe", "lamp", "ladder", "plank"]
	if slots.size() != h_slots.size():
		setup_hotbar()
		
	for i in range(slots.size()):
		var slot = slots[i]
		var key = h_slots[i] if i < h_slots.size() else "pickaxe"
		var count_lbl = slot.find_child("CountLabel", true, false)
		var icon = slot.find_child("SlotIcon", true, false)
		if icon:
			if key == "ladder": icon.texture = rope_tex
			elif key == "plank": icon.texture = plank_tex
			elif key == "column": icon.texture = _get_column_tex()
			elif key == "slab": icon.texture = brick_tex
			elif key == "forge": icon.texture = stone_tex
			elif key == "lamp":
				var atlas = AtlasTexture.new()
				atlas.atlas = lamp_tex
				atlas.region = Rect2(0, 0, 16, 16)
				icon.texture = atlas
			elif key == "pickaxe":
				var atlas = AtlasTexture.new()
				atlas.atlas = extras_tex
				atlas.region = Rect2(0, 0, 16, 16)
				icon.texture = atlas
			else:
				var atlas = AtlasTexture.new()
				atlas.atlas = extras_tex
				atlas.region = Rect2(0, 0, 16, 16)
				icon.texture = atlas

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
			if icon:
				var p_def = inv.get_equipped_def("pickaxe")
				icon.modulate = _equip_tint(p_def, inv.pickaxe_upgrade_level if "pickaxe_upgrade_level" in inv else 0, 5)
			if inv.has_pickaxe:
				count_lbl.text = "%d/%d" % [inv.pickaxe_durability, inv.max_pickaxe_durability]
				var pct = (float(inv.pickaxe_durability) / float(inv.max_pickaxe_durability)) * 100.0
				if pct <= 10.0:
					slot.modulate = Color(1.0, 0.35, 0.35, 1.0)
					style.border_color = Color(1.0, 0.25, 0.25, 1.0)
				elif pct <= 20.0:
					slot.modulate = Color(1.0, 0.9, 0.2, 1.0)
					style.border_color = Color(1.0, 0.8, 0.1, 1.0)
				else:
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
		elif key == "forge":
			count_lbl.text = "%d" % inv.portable_forges
			slot.modulate = Color.WHITE if inv.portable_forges > 0 else Color(1, 1, 1, 0.4)
		elif key == "column":
			count_lbl.text = "%d" % inv.columns
			slot.modulate = Color.WHITE if inv.columns > 0 else Color(1, 1, 1, 0.4)
		elif key == "slab":
			count_lbl.text = "%d" % inv.slabs
			slot.modulate = Color.WHITE if inv.slabs > 0 else Color(1, 1, 1, 0.4)

	# Update Chest Grid slots counts
	for i in range(chest_slots.size()):
		if i < chest_items_def.size():
			var card = chest_slots[i]
			var def = chest_items_def[i]
			var count_label = card.find_child("SlotCount", true, false)
			if count_label:
				var c = _get_item_count(def.key)
				if def.key == "pickaxe":
					count_label.text = "%d/%d" % [inv.pickaxe_durability, inv.max_pickaxe_durability] if inv.has_pickaxe else "QUEBRADA"
				else:
					count_label.text = "%d" % c
				
				if c == 0 and def.key != "pickaxe":
					card.modulate = Color(1, 1, 1, 0.4)
				else:
					card.modulate = Color(1, 1, 1, 1.0)
					
	_update_capacity_badge()
	update_equipment_ui()

func _update_capacity_badge() -> void:
	var inv = _get_inv()
	if not inv: return
	var max_cap = inv.get_max_capacity() if inv.has_method("get_max_capacity") else 60
	var cur_load = inv.get_current_load() if inv.has_method("get_current_load") else (inv.iron + inv.gold + inv.coal)
	
	if capacity_badge_label:
		capacity_badge_label.text = "%d / %d" % [cur_load, max_cap]
		if cur_load >= max_cap:
			capacity_badge_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
		else:
			capacity_badge_label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.85, 1.0))

func show_toast(text: String, icon_type: String = "") -> void:
	if not toast_list: return
	
	var toast = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.04, 0.92)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.85, 0.65, 0.2, 1.0)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	toast.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	toast.add_child(margin)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	margin.add_child(hbox)
	
	if icon_type != "":
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		if icon_type == "coin_gold": icon.texture = coin_gold_tex
		elif icon_type == "coin_silver": icon.texture = coin_silver_tex
		elif icon_type == "coin_copper": icon.texture = coin_copper_tex
		elif icon_type == "wood": icon.texture = wood_tex
		elif icon_type == "stone": icon.texture = stone_tex
		elif icon_type == "dirt": icon.texture = dirt_tex
		elif icon_type == "brick": icon.texture = brick_tex
		elif icon_type == "lamp": icon.texture = lamp_tex
		elif icon_type == "ladder": icon.texture = rope_tex
		elif icon_type == "plank": icon.texture = plank_tex
		elif icon_type == "helmet": icon.texture = helmet_tex
		elif icon_type == "armor": icon.texture = armor_tex
		elif icon_type == "boots": icon.texture = boots_tex
		elif icon_type == "pickaxe" or icon_type == "glove": icon.texture = pickaxe_tex
		else:
			var atlas = AtlasTexture.new()
			atlas.atlas = ores_tex
			if icon_type == "coal": atlas.region = Rect2(0, 128, 16, 16)
			elif icon_type == "iron": atlas.region = Rect2(32, 128, 16, 16)
			elif icon_type == "gold": atlas.region = Rect2(128, 128, 16, 16)
			else:
				atlas.atlas = extras_tex
				atlas.region = Rect2(0, 0, 16, 16)
			icon.texture = atlas
		hbox.add_child(icon)
		
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85, 1.0))
	hbox.add_child(label)
	
	toast_list.add_child(toast)
	
	var tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(toast, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		if is_instance_valid(toast):
			toast.queue_free()
	)

# Chest Menu Handlers
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
	if not inv: return
	
	var c_coal = current_chest_node.stored_coal if current_chest_node else 0
	var c_iron = current_chest_node.stored_iron if current_chest_node else 0
	var c_gold = current_chest_node.stored_gold if current_chest_node else 0
	
	if chest_coal_lbl:
		chest_coal_lbl.visible = (c_coal > 0)
		chest_coal_lbl.text = "• Carvão: %d" % c_coal
	if chest_iron_lbl:
		chest_iron_lbl.visible = (c_iron > 0)
		chest_iron_lbl.text = "• Minério de Ferro: %d" % c_iron
	if chest_gold_lbl:
		chest_gold_lbl.visible = (c_gold > 0)
		chest_gold_lbl.text = "• Minério de Ouro: %d" % c_gold
		
	if backpack_coal_lbl:
		backpack_coal_lbl.visible = (inv.coal > 0)
		backpack_coal_lbl.text = "• Carvão: %d" % inv.coal
	if backpack_iron_lbl:
		backpack_iron_lbl.visible = (inv.iron > 0)
		backpack_iron_lbl.text = "• Minério de Ferro: %d" % inv.iron
	if backpack_gold_lbl:
		backpack_gold_lbl.visible = (inv.gold > 0)
		backpack_gold_lbl.text = "• Minério de Ouro: %d" % inv.gold

func _on_chest_deposit() -> void:
	var inv = _get_inv()
	if current_chest_node and inv:
		current_chest_node.stored_coal += inv.coal
		current_chest_node.stored_iron += inv.iron
		current_chest_node.stored_gold += inv.gold
		current_chest_node.stored_load += (inv.coal + inv.iron + inv.gold)
		
		inv.coal = 0
		inv.iron = 0
		inv.gold = 0
		
		inv.inventory_changed.emit()
		update_chest_ui()
		show_toast("Recursos guardados no Baú!", "chest")
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()

func _on_chest_retrieve() -> void:
	var inv = _get_inv()
	if current_chest_node and inv:
		var max_cap = inv.get_max_capacity() if inv.has_method("get_max_capacity") else 60
		var cur_load = inv.get_current_load() if inv.has_method("get_current_load") else (inv.iron + inv.gold + inv.coal)
		var free_space = max(0, max_cap - cur_load)
		if free_space <= 0:
			show_toast("Sua mochila já está cheia!", "chest")
			return
			
		var take_coal = min(current_chest_node.stored_coal, free_space)
		inv.coal += take_coal
		current_chest_node.stored_coal -= take_coal
		free_space -= take_coal
		
		var take_iron = min(current_chest_node.stored_iron, free_space)
		inv.iron += take_iron
		current_chest_node.stored_iron -= take_iron
		free_space -= take_iron
		
		var take_gold = min(current_chest_node.stored_gold, free_space)
		inv.gold += take_gold
		current_chest_node.stored_gold -= take_gold
		
		current_chest_node.stored_load = current_chest_node.stored_coal + current_chest_node.stored_iron + current_chest_node.stored_gold
		inv.inventory_changed.emit()
		update_chest_ui()
		show_toast("Recursos retirados do Baú!", "chest")
		if has_node("/root/SaveManager"):
			get_node("/root/SaveManager").request_save()
