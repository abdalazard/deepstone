extends CanvasLayer

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
		
	select_slot(0)
	update_ui()

func _consume_input() -> void:
	if is_inside_tree() and get_viewport():
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Toggle Equipment Menu with [E]
		if event.physical_keycode == KEY_E:
			toggle_equipment()
			_consume_input()
			return

		# Toggle Pause Menu with [P] or [Esc]
		if event.physical_keycode == KEY_P or event.physical_keycode == KEY_ESCAPE:
			if is_instance_valid(equipment_panel) and equipment_panel.visible:
				close_equipment()
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
	if (not pause_panel or not pause_panel.visible) and event.is_action_pressed("shop_menu"):
		_on_shop_pressed()
		_consume_input()
		return
		
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_L and (not pause_panel or not pause_panel.visible):
		_on_shop_pressed()
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
	if is_instance_valid(inventory_panel) and inventory_panel.visible:
		close_inventory()
	if is_instance_valid(pause_panel) and pause_panel.visible:
		close_pause()
	if is_instance_valid(equipment_panel):
		equipment_panel.visible = true

func close_equipment() -> void:
	if is_instance_valid(equipment_panel):
		equipment_panel.visible = false

func toggle_pause() -> void:
	if is_instance_valid(pause_panel) and pause_panel.visible:
		close_pause()
	else:
		open_pause()

func open_pause() -> void:
	if is_instance_valid(inventory_panel) and inventory_panel.visible:
		close_inventory()
	if is_instance_valid(equipment_panel) and equipment_panel.visible:
		close_equipment()
	if is_instance_valid(pause_panel):
		pause_panel.visible = true
	if is_inside_tree() and get_tree():
		get_tree().paused = true
	if is_inside_tree() and is_instance_valid(resume_btn):
		resume_btn.grab_focus()

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

func _on_restart_pressed() -> void:
	if is_inside_tree() and get_tree():
		get_tree().paused = false
		if is_instance_valid(pause_panel):
			pause_panel.visible = false
		if get_tree().root and get_tree().root.has_node("SaveManager"):
			get_tree().root.get_node("SaveManager").player_saved_pos = Vector2(640, 96)
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
	show_toast("Loja em breve! Guarde seus ouros para novas ferramentas e melhorias.", "gold")
	if shop_button:
		var tween = create_tween()
		tween.tween_property(shop_button, "scale", Vector2(1.15, 1.15), 0.08)
		tween.tween_property(shop_button, "scale", Vector2.ONE, 0.08)

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
	card.custom_minimum_size = Vector2(85, 75)
	
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
		if def.key == "lamp" and (inv.coal < 3 or inv.iron < 2):
			show_toast("Poste indisponível! (Requer 3 Carvões + 2 Ferros)", "lamp")
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
		"lamp": return min(inv.coal / 3, inv.iron / 2)
		"ladder": return 99
		"plank": return inv.planks
		"iron": return inv.iron
		"gold": return inv.gold
		"coal": return inv.coal
		_: return 0

func update_ui() -> void:
	var inv = _get_inv()
	if not inv: return
	
	var can_craft_lamp = (inv.coal >= 3 and inv.iron >= 2)
	var craftable_lamps = min(inv.coal / 3, inv.iron / 2)
	
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
			count_lbl.text = "∞"
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
				lbl.text = "Infinito"
			elif def.key == "pickaxe":
				lbl.text = "Nível 1"
			elif def.key == "lamp":
				lbl.text = "%d un. (3C+2Fe)" % craftable_lamps
			else:
				lbl.text = "%d un." % c
				
	_update_capacity_badge()

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
	if is_instance_valid(equipment_panel) and equipment_panel.visible:
		close_equipment()
	if is_instance_valid(pause_panel) and pause_panel.visible:
		close_pause()
	if is_instance_valid(inventory_panel):
		inventory_panel.visible = true
	select_slot(selected_index)
	update_ui()

func close_inventory() -> void:
	if is_instance_valid(inventory_panel):
		inventory_panel.visible = false

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
		
		if icon_type == "iron":
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
