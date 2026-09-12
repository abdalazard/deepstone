extends CanvasLayer

@onready var load_label = $MarginContainer/VBoxContainer/LoadLabel
@onready var iron_label = $MarginContainer/VBoxContainer/IronLabel
@onready var gold_label = $MarginContainer/VBoxContainer/GoldLabel
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
