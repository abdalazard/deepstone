extends CanvasLayer

@onready var load_label = $MarginContainer/VBoxContainer/LoadLabel
@onready var iron_label = $MarginContainer/VBoxContainer/IronLabel
@onready var gold_label = $MarginContainer/VBoxContainer/GoldLabel
@onready var sign_label = $MarginContainer/VBoxContainer/SignLabel
@onready var container = $MarginContainer/VBoxContainer

func _ready() -> void:
	Inventory.inventory_changed.connect(_on_resources_changed)
	_on_resources_changed()
	container.hide() # Inventory starts closed!

func toggle() -> void:
	container.visible = !container.visible

func _on_resources_changed() -> void:
	load_label.text = "Carga: " + str(Inventory.current_load) + "/" + str(Inventory.MAX_CAPACITY)
	iron_label.text = "Ferro: " + str(Inventory.iron)
	gold_label.text = "Ouro: " + str(Inventory.gold)
	
	if Inventory.sign_selected:
		sign_label.text = "> PLACA EQUIPADA < (" + str(Inventory.signs) + ")"
		sign_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0))
	else:
		sign_label.text = "Placas (Z): " + str(Inventory.signs)
		sign_label.add_theme_color_override("font_color", Color(0.5, 0.9, 1.0))
