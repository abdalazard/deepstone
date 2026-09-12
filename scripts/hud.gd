extends CanvasLayer

@onready var hotbar = $TopContainer/HotbarVisual
@onready var inventory_panel = $InventoryPanel
@onready var close_button = $InventoryPanel/VBoxContainer/HeaderPanel/HeaderMargin/HBoxContainer/CloseButton
@onready var chest_grid = $InventoryPanel/VBoxContainer/ContentMargin/InnerVBox/ChestGrid
@onready var item_title = $InventoryPanel/VBoxContainer/ContentMargin/InnerVBox/InfoPlaque/PlaqueMargin/PlaqueVBox/ItemTitle
@onready var item_desc = $InventoryPanel/VBoxContainer/ContentMargin/InnerVBox/InfoPlaque/PlaqueMargin/PlaqueVBox/ItemDesc
@onready var capacity_label = $InventoryPanel/VBoxContainer/ContentMargin/InnerVBox/FooterHBox/CapacityLabel

var slots: Array = []
var chest_slots: Array = []
var extras_tex = preload("res://assets/Caves and Mines/extras.png")
var ores_tex = preload("res://assets/Caves and Mines/ores.png")
var rope_tex = preload("res://assets/sprites/rope_tile.png")
var lamp_tex = preload("res://assets/sprites/lamp_post.png")

var chest_items_def = [
	{
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
		"name": "Corda de Escalada",
		"desc": "Corda de alta resistência para descer em abismos e subir poços profundos. Pressione [3].",
		"icon_type": "direct",
		"tex": "rope",
		"shortcut": "3",
		"is_tool": true,
		"tool_slot": 2
	},
	{
		"name": "Minério de Ferro",
		"desc": "Metal resistente e condutor. Deposite no baú da superfície para forjar ferramentas.",
		"icon_type": "atlas",
		"atlas": "ores",
		"region": Rect2(0, 0, 16, 16),
		"shortcut": "",
		"is_tool": false
	},
	{
		"name": "Minério de Ouro",
		"desc": "Metal nobre e brilhante de alto valor encontrado em veios profundos. Alto valor comercial.",
		"icon_type": "atlas",
		"atlas": "ores",
		"region": Rect2(64, 0, 16, 16),
		"shortcut": "",
		"is_tool": false
	},
	{
		"name": "Carvão Mineral",
		"desc": "Combustível fóssil que aquece forjas e alimenta fundições avançadas. [Em Breve]",
		"icon_type": "atlas",
		"atlas": "ores",
		"region": Rect2(32, 0, 16, 16),
		"shortcut": "",
		"is_tool": false
	},
	{
		"name": "Barra Forjada",
		"desc": "Lingote de metal puro fundido na fornalha da superfície para novos itens. [Em Breve]",
		"icon_type": "atlas",
		"atlas": "extras",
		"region": Rect2(32, 0, 16, 16),
		"shortcut": "",
		"is_tool": false
	},
	{
		"name": "Espaço Livre",
		"desc": "Compartimento vazio do baú reservado para novas ferramentas e gemas preciosas.",
		"icon_type": "none",
		"shortcut": "",
		"is_tool": false
	}
]

func _ready() -> void:
	_build_hotbar()
	_build_chest_grid()
	
	if close_button:
		close_button.pressed.connect(toggle)
		
	Inventory.inventory_changed.connect(_on_resources_changed)
	_on_resources_changed()
	inventory_panel.hide()

func _build_hotbar() -> void:
	for i in range(5):
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(56, 56)
		
		# Background color
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
			atlas.region = Rect2(0, 0, 16, 16) # Mini Poste / Lampião
			icon.texture = atlas
		elif i == 2:
			icon.texture = rope_tex # Corda (not Escada)
		elif i == 3:
			var atlas = AtlasTexture.new()
			atlas.atlas = ores_tex
			atlas.region = Rect2(0, 0, 16, 16) # Iron
			icon.texture = atlas
		elif i == 4:
			var atlas = AtlasTexture.new()
			atlas.atlas = ores_tex
			atlas.region = Rect2(64, 0, 16, 16) # Gold
			icon.texture = atlas
			
		# Number Label: only 1, 2, 3 for tools usable with button Z
		var num_lbl = Label.new()
		num_lbl.text = str(i + 1) if i < 3 else ""
		num_lbl.add_theme_font_size_override("font_size", 14)
		num_lbl.add_theme_color_override("font_color", Color(1,1,1))
		num_lbl.add_theme_color_override("font_outline_color", Color(0,0,0))
		num_lbl.add_theme_constant_override("outline_size", 4)
		
		# Qty Label
		var qty_lbl = Label.new()
		qty_lbl.text = ""
		qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		qty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		qty_lbl.add_theme_font_size_override("font_size", 14)
		qty_lbl.add_theme_color_override("font_outline_color", Color(0,0,0))
		qty_lbl.add_theme_constant_override("outline_size", 4)
		
		# Layout
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
		
		var icon_margin = MarginContainer.new()
		icon_margin.add_theme_constant_override("margin_left", 6)
		icon_margin.add_theme_constant_override("margin_top", 6)
		icon_margin.add_theme_constant_override("margin_right", 6)
		icon_margin.add_theme_constant_override("margin_bottom", 6)
		icon_margin.add_child(icon)
		slot_panel.add_child(icon_margin)
		
		# Top-left shortcut tag
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
		
		# Bottom-right quantity label
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
		
		# Interaction
		var slot_index = i
		slot_panel.mouse_entered.connect(func():
			_on_chest_slot_hover(slot_index)
		)
		slot_panel.mouse_exited.connect(func():
			_on_chest_slot_unhover(slot_index)
		)
		slot_panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_chest_slot_clicked(slot_index)
		)
		
		chest_grid.add_child(slot_panel)
		chest_slots.append({
			"panel": slot_panel,
			"style": style_normal,
			"qty_lbl": qty_lbl,
			"def": def
		})

func _on_chest_slot_hover(idx: int) -> void:
	if idx < chest_slots.size():
		var def = chest_slots[idx].def
		if item_title: item_title.text = def.name
		if item_desc: item_desc.text = def.desc
		var s: StyleBoxFlat = chest_slots[idx].style
		s.border_color = Color(1.0, 0.85, 0.35, 1.0) # Golden glow

func _on_chest_slot_unhover(idx: int) -> void:
	if idx < chest_slots.size():
		var s: StyleBoxFlat = chest_slots[idx].style
		if idx < 3 and idx == Inventory.active_slot:
			s.border_color = Color(0.9, 0.75, 0.2, 1.0)
		else:
			s.border_color = Color(0.38, 0.25, 0.14, 1.0)

func _on_chest_slot_clicked(idx: int) -> void:
	if idx < chest_slots.size():
		var def = chest_slots[idx].def
		if def.is_tool and def.has("tool_slot"):
			Inventory.active_slot = def.tool_slot
			Inventory.inventory_changed.emit()
		_on_chest_slot_hover(idx)

func toggle() -> void:
	var opening = !inventory_panel.visible
	inventory_panel.visible = opening
	if opening:
		_on_resources_changed()
		_on_chest_slot_hover(Inventory.active_slot)
		# Smooth popup animation
		inventory_panel.scale = Vector2(0.95, 0.95)
		inventory_panel.modulate.a = 0.5
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(inventory_panel, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_OUT)
		tween.tween_property(inventory_panel, "modulate:a", 1.0, 0.12)

func _on_resources_changed() -> void:
	# Update Hotbar Slots Qty
	if slots.size() >= 5:
		slots[0].qty.text = "" # Pickaxe is infinite
		slots[1].qty.text = str(Inventory.signs)
		slots[2].qty.text = "" # Rope is infinite
		slots[3].qty.text = str(Inventory.iron)
		slots[4].qty.text = str(Inventory.gold)
		
		# Reset Hotbar Selection Colors
		for i in range(slots.size()):
			if i < 3 and i == Inventory.active_slot:
				slots[i].bg.color = Color(0.8, 0.8, 0.2, 0.9) # Highlight yellow
			else:
				slots[i].bg.color = Color(0.2, 0.2, 0.2, 0.8) # Default dark

	# Update Chest Inventory Slots Qty & Active Borders
	if chest_slots.size() >= 8:
		chest_slots[0].qty_lbl.text = "∞"
		chest_slots[1].qty_lbl.text = str(Inventory.signs)
		chest_slots[2].qty_lbl.text = "∞"
		chest_slots[3].qty_lbl.text = str(Inventory.iron) + "/20"
		chest_slots[4].qty_lbl.text = str(Inventory.gold) + "/20"
		chest_slots[5].qty_lbl.text = "0"
		chest_slots[6].qty_lbl.text = "0"
		chest_slots[7].qty_lbl.text = "-"
		
		for i in range(chest_slots.size()):
			var s: StyleBoxFlat = chest_slots[i].style
			if i < 3 and i == Inventory.active_slot:
				s.border_color = Color(0.95, 0.8, 0.25, 1.0)
				s.bg_color = Color(0.2, 0.14, 0.07, 0.98)
			else:
				s.border_color = Color(0.38, 0.25, 0.14, 1.0)
				s.bg_color = Color(0.12, 0.08, 0.04, 0.95)

	# Update Capacity label
	if capacity_label:
		var total_ores = Inventory.iron + Inventory.gold
		capacity_label.text = "Carga: " + str(total_ores) + "/40 minérios  (Ferro: " + str(Inventory.iron) + "/20 | Ouro: " + str(Inventory.gold) + "/20)"
