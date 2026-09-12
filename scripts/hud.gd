extends CanvasLayer

@onready var stone_label: Label = $MarginContainer/VBoxContainer/StoneLabel
@onready var copper_label: Label = $MarginContainer/VBoxContainer/CopperLabel

func _ready() -> void:
	Inventory.inventory_changed.connect(_on_inventory_changed)
	_on_inventory_changed() # Update text immediately

func _on_inventory_changed() -> void:
	stone_label.text = "STONE x " + str(Inventory.stone)
	copper_label.text = "COPPER x " + str(Inventory.copper)
