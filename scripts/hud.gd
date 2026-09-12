extends CanvasLayer

@onready var hotbar = $TopContainer/HotbarVisual
@onready var inventory_panel = $InventoryPanel
@onready var close_button = $InventoryPanel/VBoxContainer/HeaderPanel/HeaderMargin/HBoxContainer/CloseButton
@onready var chest_grid = $InventoryPanel/VBoxContainer/ContentMargin/InnerVBox/ChestGrid
@onready var item_title = $InventoryPanel/VBoxContainer/ContentMargin/InnerVBox/InfoPlaque/PlaqueMargin/PlaqueVBox/ItemTitle
@onready var item_desc = $InventoryPanel/VBoxContainer/ContentMargin/InnerVBox/InfoPlaque/PlaqueMargin/PlaqueVBox/ItemDesc
@onready var equip_button = $InventoryPanel/VBoxContainer/ContentMargin/InnerVBox/InfoPlaque/PlaqueMargin/PlaqueVBox/ActionHBox/EquipButton
@onready var drop_button = $InventoryPanel/VBoxContainer/ContentMargin/InnerVBox/InfoPlaque/PlaqueMargin/PlaqueVBox/ActionHBox/DropButton
@onready var capacity_label = $InventoryPanel/VBoxContainer/ContentMargin/InnerVBox/FooterHBox/CapacityLabel
@onready var shop_button = $TopRightContainer/ShopButton
@onready var toast_list = $ToastContainer/ToastList

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
		"desc": "Lampião portátil que ilumina a caverna e faz os minérios brilharem no escuro. Pressione [2].",
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
		"desc": "Prancha de madeira reforçada para criar pontes horizontais sobre vãos e fossos. Pressione [4].",
		"icon_type": "direct",
		"tex": "plank",
		"shortcut": "4",
		"is_tool": true,
		"tool_slot": 3
	},
	{
		"key": "iron",
		"name": "Minério de Ferro",
		"desc": "Metal resistente e condutor. Deposite no baú da superfície para forjar ferramentas.",
		"icon_type": "atlas",
		"atlas": "ores",
		"region": Rect2(32, 0, 16, 16), # Iron specks
		"shortcut": "",
		"is_tool": false
	},
	{
		"key": "gold",
		"name": "Minério de Ouro",
		"desc": "Metal nobre e brilhante de alto valor encontrado em veios profundos. Alto valor comercial.",
		"icon_type": "atlas",
		"atlas": "ores",
		"region": Rect2(128, 0, 16, 16), # Gold specks (col 8)
		"shortcut": "",
		"is_tool": false
	},
	{
		"key": "coal",
		"name": "Carvão Mineral",
		"desc": "Combustível fóssil que aquece forjas e alimenta fundições avançadas. Deposite no baú.",
		"icon_type": "atlas",
		"atlas": "ores",
		"region": Rect2(0, 0, 16, 16), # Charcoal specks
		"shortcut": "",
		"is_tool": false
	},
	{
		"key": "bar",
		"name": "Barra Forjada",
		"desc": "Lingote de metal puro fundido na fornalha da superfície para novos itens. [Em Breve]",
		"icon_type": "atlas",
		"atlas": "extras",
		"region": Rect2(32, 0, 16, 16),
		"shortcut": "",
		"is_tool": false
	}
]

func _ready() -> void:
	_build_hotbar()
	_build_chest_grid()
	
	if close_button:
		close_button.pressed.connect(toggle)
	if shop_button:
		shop_button.pressed.connect(_on_shop_pressed)
	if equip_button:
		equip_button.pressed.connect(_on_slot_equip_pressed)
	if drop_button:
		drop_button.pressed.connect(_on_slot_drop_pressed)
		
	Inventory.inventory_changed.connect(_on_resources_changed)
	Inventory.notification_triggered.connect(show_toast)
	_on_resources_changed()
	inventory_panel.hide()

func _unhandled_input(event: InputEvent) -> void:
	# Hotkey for Shop [L] or [P]
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_L, KEY_P]:
			_on_shop_pressed()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_ESCAPE and inventory_panel.visible:
			toggle()
			get_viewport().set_input_as_handled()
			return
	
	# Keyboard navigation inside inventory
	if inventory_panel.visible:
		if event.is_action_pressed("ui_right"):
			_select_slot((selected_index + 1) % chest_slots.size())
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_left"):
			_select_slot((selected_index - 1 + chest_slots.size()) % chest_slots.size())
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_down"):
			_select_slot((selected_index + 4) % chest_slots.size())
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up"):
			_select_slot((selected_index - 4 + chest_slots.size()) % chest_slots.size())
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("action_mine") or event.is_action_pressed("ui_accept"): # Z or Enter
			_on_slot_equip_pressed()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("action_drag"): # X to drop
			_on_slot_drop_pressed()
			get_viewport().set_input_as_handled()

func _build_hotbar() -> void:
	for i in range(7):
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(50, 50)
		
		var rect = ColorRect.new()
		rect.color = Color(0.2, 0.2, 0.2, 0.8)
		panel.add_child(rect)
		
		var icon = TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		if i == 0:
			var atlas = AtlasTexture.new()
			atlas.atlas = extras_tex
			atlas.region = Rect2(0, 0, 16, 16) # Pickaxe
			icon.texture = atlas
		elif i == 1:
			var atlas = AtlasTexture.new()
			atlas.atlas = lamp_tex
			atlas.region = Rect2(0, 0, 16, 16) # Mini Poste
			icon.texture = atlas
		elif i == 2:
			icon.texture = rope_tex # Escada
		elif i == 3:
			icon.texture = plank_tex # Tábua
		elif i == 4:
			var atlas = AtlasTexture.new()
			atlas.atlas = ores_tex
			atlas.region = Rect2(32, 0, 16, 16) # Iron
			icon.texture = atlas
		elif i == 5:
			var atlas = AtlasTexture.new()
			atlas.atlas = ores_tex
			atlas.region = Rect2(128, 0, 16, 16) # Gold
			icon.texture = atlas
		elif i == 6:
			var atlas = AtlasTexture.new()
			atlas.atlas = ores_tex
			atlas.region = Rect2(0, 0, 16, 16) # Coal
			icon.texture = atlas
			
		var num_lbl = Label.new()
		num_lbl.text = str(i + 1) if i < 4 else ""
		num_lbl.add_theme_font_size_override("font_size", 13)
		num_lbl.add_theme_color_override("font_color", Color(1,1,1))
		num_lbl.add_theme_color_override("font_outline_color", Color(0,0,0))
		num_lbl.add_theme_constant_override("outline_size", 4)
		
		var qty_lbl = Label.new()
		qty_lbl.text = ""
		qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		qty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		qty_lbl.add_theme_font_size_override("font_size", 13)
		qty_lbl.add_theme_color_override("font_outline_color", Color(0,0,0))
		qty_lbl.add_theme_constant_override("outline_size", 4)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 4)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_right", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		margin.add_child(icon)
		
		var num_margin = MarginContainer.new()
		num_margin.add_theme_constant_override("margin_left", 4)
		num_margin.add_theme_constant_override("margin_top", 0)
		num_margin.add_child(num_lbl)
		
		var qty_margin = MarginContainer.new()
		qty_margin.add_theme_constant_override("margin_right", 4)
		qty_margin.add_theme_constant_override("margin_bottom", 0)
		qty_margin.add_child(qty_lbl)
		
		panel.add_child(margin)
		panel.add_child(num_margin)
		panel.add_child(qty_margin)
		
		hotbar.add_child(panel)
		slots.append({
			"panel": panel,
			"bg": rect,
			"qty": qty_lbl
		})

func _build_chest_grid() -> void:
	if not chest_grid: return
	
	for i in range(chest_items_def.size()):
		var def = chest_items_def[i]
		
		var slot_panel = PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(98, 54)
		
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(0.12, 0.08, 0.04, 0.95)
		style_normal.border_width_left = 2
		style_normal.border_width_top = 2
		style_normal.border_width_right = 2
		style_normal.border_width_bottom = 2
		style_normal.border_color = Color(0.38, 0.25, 0.14, 1.0)
		style_normal.corner_radius_top_left = 4
		style_normal.corner_radius_top_right = 4
		style_normal.corner_radius_bottom_right = 4
		style_normal.corner_radius_bottom_left = 4
		slot_panel.add_theme_stylebox_override("panel", style_normal)
		
		var icon = TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		if def.icon_type == "atlas":
			var atlas = AtlasTexture.new()
			if def.atlas == "extras": atlas.atlas = extras_tex
			elif def.atlas == "lamp": atlas.atlas = lamp_tex
			elif def.atlas == "ores": atlas.atlas = ores_tex
			atlas.region = def.region
			icon.texture = atlas
		elif def.icon_type == "direct":
			if def.tex == "rope": icon.texture = rope_tex
			elif def.tex == "plank": icon.texture = plank_tex
		
		var icon_margin = MarginContainer.new()
		icon_margin.add_theme_constant_override("margin_left", 6)
		icon_margin.add_theme_constant_override("margin_top", 6)
		icon_margin.add_theme_constant_override("margin_right", 6)
		icon_margin.add_theme_constant_override("margin_bottom", 6)
		icon_margin.add_child(icon)
		slot_panel.add_child(icon_margin)
		
		if def.shortcut != "":
			var tag_lbl = Label.new()
			tag_lbl.text = "[" + def.shortcut + "]"
			tag_lbl.add_theme_font_size_override("font_size", 11)
			tag_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1))
			tag_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			tag_lbl.add_theme_constant_override("outline_size", 3)
			
			var tag_margin = MarginContainer.new()
			tag_margin.add_theme_constant_override("margin_left", 4)
			tag_margin.add_theme_constant_override("margin_top", 2)
			tag_margin.add_child(tag_lbl)
			slot_panel.add_child(tag_margin)
		
		var qty_lbl = Label.new()
		qty_lbl.text = ""
		qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		qty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		qty_lbl.add_theme_font_size_override("font_size", 12)
		qty_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		qty_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		qty_lbl.add_theme_constant_override("outline_size", 3)
		
		var qty_margin = MarginContainer.new()
		qty_margin.add_theme_constant_override("margin_right", 4)
		qty_margin.add_theme_constant_override("margin_bottom", 2)
		qty_margin.add_child(qty_lbl)
		slot_panel.add_child(qty_margin)
		
		var slot_index = i
		slot_panel.mouse_entered.connect(func():
			_select_slot(slot_index)
		)
		slot_panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					drag_start_idx = slot_index
					_select_slot(slot_index)
				else:
					# On release, check if dropped outside inventory panel onto world
					if drag_start_idx == slot_index:
						var mouse_pos = slot_panel.get_global_mouse_position()
						if not inventory_panel.get_global_rect().has_point(mouse_pos):
							_drop_slot_item(slot_index)
					drag_start_idx = -1
		)
		
		chest_grid.add_child(slot_panel)
		chest_slots.append({
			"panel": slot_panel,
			"style": style_normal,
			"qty_lbl": qty_lbl,
			"def": def
		})

func _select_slot(idx: int) -> void:
	if idx < 0 or idx >= chest_slots.size(): return
	selected_index = idx
	
	# Update borders
	for i in range(chest_slots.size()):
		var s: StyleBoxFlat = chest_slots[i].style
		if i == selected_index:
			s.border_color = Color(1.0, 0.88, 0.35, 1.0)
			s.bg_color = Color(0.24, 0.16, 0.08, 0.98)
		elif i < 4 and i == Inventory.active_slot:
			s.border_color = Color(0.85, 0.7, 0.2, 1.0)
			s.bg_color = Color(0.18, 0.12, 0.06, 0.96)
		else:
			s.border_color = Color(0.38, 0.25, 0.14, 1.0)
			s.bg_color = Color(0.12, 0.08, 0.04, 0.95)
			
	var def = chest_slots[idx].def
	if item_title: item_title.text = def.name
	if item_desc: item_desc.text = def.desc
	
	# Update action buttons visibility
	if equip_button:
		equip_button.visible = def.is_tool
	if drop_button:
		var has_drop = false
		if def.key == "iron": has_drop = Inventory.iron > 0
		elif def.key == "gold": has_drop = Inventory.gold > 0
		elif def.key == "coal": has_drop = Inventory.coal > 0
		elif def.key == "plank": has_drop = Inventory.planks > 0
		elif def.key == "lamp": has_drop = Inventory.signs > 0
		drop_button.visible = has_drop

func _on_slot_equip_pressed() -> void:
	if selected_index < chest_slots.size():
		var def = chest_slots[selected_index].def
		if def.is_tool and def.has("tool_slot"):
			Inventory.active_slot = def.tool_slot
			Inventory.inventory_changed.emit()
			Inventory.notify("Equipado: " + def.name, def.key)
		_select_slot(selected_index)

func _on_slot_drop_pressed() -> void:
	_drop_slot_item(selected_index)

func _drop_slot_item(idx: int) -> void:
	if idx < chest_slots.size():
		var def = chest_slots[idx].def
		Inventory.drop_item(def.key, 1)
		_select_slot(idx)

func toggle() -> void:
	var opening = !inventory_panel.visible
	inventory_panel.visible = opening
	if opening:
		_on_resources_changed()
		_select_slot(Inventory.active_slot)
		inventory_panel.scale = Vector2(0.95, 0.95)
		inventory_panel.modulate.a = 0.5
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(inventory_panel, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_OUT)
		tween.tween_property(inventory_panel, "modulate:a", 1.0, 0.12)

func _on_resources_changed() -> void:
	# Update Hotbar Slots Qty
	if slots.size() >= 7:
		slots[0].qty.text = "" # Picareta
		slots[1].qty.text = str(Inventory.signs) # Lamp
		slots[2].qty.text = "" # Escada
		slots[3].qty.text = str(Inventory.planks) # Tábua
		slots[4].qty.text = str(Inventory.iron) # Ferro
		slots[5].qty.text = str(Inventory.gold) # Ouro
		slots[6].qty.text = str(Inventory.coal) # Carvão
		
		for i in range(slots.size()):
			if i < 4 and i == Inventory.active_slot:
				slots[i].bg.color = Color(0.85, 0.8, 0.2, 0.9)
			else:
				slots[i].bg.color = Color(0.2, 0.2, 0.2, 0.8)

	# Update Chest Inventory Slots Qty
	if chest_slots.size() >= 8:
		chest_slots[0].qty_lbl.text = "∞"
		chest_slots[1].qty_lbl.text = str(Inventory.signs)
		chest_slots[2].qty_lbl.text = "∞"
		chest_slots[3].qty_lbl.text = str(Inventory.planks)
		chest_slots[4].qty_lbl.text = str(Inventory.iron) + "/20"
		chest_slots[5].qty_lbl.text = str(Inventory.gold) + "/20"
		chest_slots[6].qty_lbl.text = str(Inventory.coal) + "/20"
		chest_slots[7].qty_lbl.text = "0"
		_select_slot(selected_index)

	if capacity_label:
		var total_ores = Inventory.iron + Inventory.gold + Inventory.coal
		capacity_label.text = "Carga: %d/60 minérios (Fe: %d | Au: %d | C: %d)" % [total_ores, Inventory.iron, Inventory.gold, Inventory.coal]

func _on_shop_pressed() -> void:
	if shop_button:
		var tween = create_tween()
		tween.tween_property(shop_button, "scale", Vector2(1.1, 1.1), 0.08)
		tween.tween_property(shop_button, "scale", Vector2.ONE, 0.08)
	show_toast("Loja em breve! Guarde seus ouros para novas ferramentas e melhorias.", "shop")

func show_toast(text: String, icon_type: String = "") -> void:
	if not toast_list: return
	
	if toast_list.get_child_count() >= 4:
		var oldest = toast_list.get_child(0)
		if is_instance_valid(oldest):
			oldest.queue_free()
	
	var toast = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.09, 0.05, 0.94)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.85, 0.7, 0.25, 1.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 4
	toast.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	
	if icon_type != "":
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		if icon_type in ["iron", "ores"]:
			var atlas = AtlasTexture.new()
			atlas.atlas = ores_tex
			atlas.region = Rect2(32, 0, 16, 16)
			icon.texture = atlas
		elif icon_type == "gold":
			var atlas = AtlasTexture.new()
			atlas.atlas = ores_tex
			atlas.region = Rect2(128, 0, 16, 16)
			icon.texture = atlas
		elif icon_type == "coal":
			var atlas = AtlasTexture.new()
			atlas.atlas = ores_tex
			atlas.region = Rect2(0, 0, 16, 16)
			icon.texture = atlas
		elif icon_type in ["save", "chest"]:
			var atlas = AtlasTexture.new()
			atlas.atlas = extras_tex
			atlas.region = Rect2(160, 32, 16, 16)
			icon.texture = atlas
		elif icon_type == "shop":
			var atlas = AtlasTexture.new()
			atlas.atlas = extras_tex
			atlas.region = Rect2(32, 0, 16, 16)
			icon.texture = atlas
		elif icon_type == "sign":
			var sign_tex = load("res://assets/sprites/signpost.png")
			if sign_tex: icon.texture = sign_tex
		elif icon_type == "plank":
			icon.texture = plank_tex
		elif icon_type == "lamp":
			var atlas = AtlasTexture.new()
			atlas.atlas = lamp_tex
			atlas.region = Rect2(0, 0, 16, 16)
			icon.texture = atlas
		elif icon_type == "ladder":
			icon.texture = rope_tex
		elif icon_type == "dash":
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
	
	var timer = toast.get_tree().create_timer(2.2)
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
