extends CanvasLayer

@onready var inventory_panel = $InventoryPanel
@onready var load_label = $InventoryPanel/MarginContainer/VBoxContainer/LoadLabel
@onready var iron_label = $InventoryPanel/MarginContainer/VBoxContainer/IronLabel
@onready var gold_label = $InventoryPanel/MarginContainer/VBoxContainer/GoldLabel
@onready var hotbar = $TopContainer/HotbarVisual

var slots: Array = []
var extras_tex = preload("res://assets/Caves and Mines/extras.png")
var ores_tex = preload("res://assets/Caves and Mines/ores.png")

func _ready() -> void:
	_build_hotbar()
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
		
		var atlas = AtlasTexture.new()
		if i == 0:
			atlas.atlas = extras_tex
			atlas.region = Rect2(0, 0, 16, 16) # Pickaxe
		elif i == 1:
			atlas.atlas = extras_tex
			atlas.region = Rect2(128, 0, 16, 16) # Sign
		elif i == 2:
			atlas.atlas = extras_tex
			atlas.region = Rect2(0, 64, 16, 16) # Ladder
		elif i == 3:
			atlas.atlas = ores_tex
			atlas.region = Rect2(0, 0, 16, 16) # Iron
		elif i == 4:
			atlas.atlas = ores_tex
			atlas.region = Rect2(64, 0, 16, 16) # Gold
			
		icon.texture = atlas
		
		# Number Label
		var num_lbl = Label.new()
		num_lbl.text = str(i + 1)
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

func toggle() -> void:
	inventory_panel.visible = !inventory_panel.visible

func _on_resources_changed() -> void:
	if is_instance_valid(iron_label):
		iron_label.text = "Ferro: " + str(Inventory.iron) + "/20"
	if is_instance_valid(gold_label):
		gold_label.text = "Ouro: " + str(Inventory.gold) + "/20"
	
	# Update Slots Qty
	slots[0].qty.text = "" # Pickaxe is infinite
	slots[1].qty.text = str(Inventory.signs)
	slots[2].qty.text = "" # Rope is infinite
	slots[3].qty.text = str(Inventory.iron)
	slots[4].qty.text = str(Inventory.gold)
	
	# Reset Selection Colors
	for i in range(slots.size()):
		if i == Inventory.active_slot:
			slots[i].bg.color = Color(0.8, 0.8, 0.2, 0.9) # Highlight yellow
		else:
			slots[i].bg.color = Color(0.2, 0.2, 0.2, 0.8) # Default dark
