extends CanvasLayer

@onready var stone_label = $VBoxContainer/StoneCount
@onready var copper_label = $VBoxContainer/CopperCount
@onready var container = $VBoxContainer

func _ready() -> void:
	Inventory.resources_changed.connect(_on_resources_changed)
	_on_resources_changed()
	container.hide() # Inventory starts closed!

func toggle() -> void:
	container.visible = !container.visible

func _on_resources_changed() -> void:
	stone_label.text = "Pedra: " + str(Inventory.stone)
	copper_label.text = "Cobre: " + str(Inventory.copper)
