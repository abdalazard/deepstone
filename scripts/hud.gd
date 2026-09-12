extends CanvasLayer

@onready var inventory_panel = $InventoryPanel
@onready var load_label = $InventoryPanel/MarginContainer/VBoxContainer/LoadLabel
@onready var iron_label = $InventoryPanel/MarginContainer/VBoxContainer/IronLabel
@onready var gold_label = $InventoryPanel/MarginContainer/VBoxContainer/GoldLabel

@onready var slot0 = $Hotbar/HBoxContainer/Slot0
@onready var slot1 = $Hotbar/HBoxContainer/Slot1
@onready var slot2 = $Hotbar/HBoxContainer/Slot2
@onready var slot3 = $Hotbar/HBoxContainer/Slot3
@onready var slot4 = $Hotbar/HBoxContainer/Slot4

func _ready() -> void:
	Inventory.inventory_changed.connect(_on_resources_changed)
	_on_resources_changed()
	inventory_panel.hide()

func toggle() -> void:
	inventory_panel.visible = !inventory_panel.visible

func _on_resources_changed() -> void:
	# Update Inventory Panel
	load_label.text = "Carga (Peso): " + str(Inventory.current_load) + "/" + str(Inventory.MAX_CAPACITY)
	iron_label.text = "Ferro: " + str(Inventory.iron)
	gold_label.text = "Ouro: " + str(Inventory.gold)
	
	# Update Hotbar Text
	slot1.text = "2:Placa (" + str(Inventory.signs) + ")"
	slot2.text = "3:Escada (" + str(Inventory.ladders) + ")"
	slot3.text = "4:Ferro (" + str(Inventory.iron) + ")"
	slot4.text = "5:Ouro (" + str(Inventory.gold) + ")"
	
	# Reset Selection Colors
	var slots = [slot0, slot1, slot2, slot3, slot4]
	for i in range(slots.size()):
		if i == Inventory.active_slot:
			slots[i].add_theme_color_override("font_color", Color(1.0, 1.0, 0.0))
			slots[i].text = "> " + slots[i].text + " <"
		else:
			# Default colors
			if i == 0: slots[i].add_theme_color_override("font_color", Color(1, 1, 1))
			elif i == 1: slots[i].add_theme_color_override("font_color", Color(0.5, 0.9, 1))
			elif i == 2: slots[i].add_theme_color_override("font_color", Color(0.8, 0.6, 0.4))
			elif i == 3: slots[i].add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			elif i == 4: slots[i].add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
