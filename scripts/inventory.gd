extends Node

signal inventory_changed

const MAX_CAPACITY: int = 10
var iron: int = 0
var gold: int = 0
var current_load: int = 0
var signs: int = 10
var sign_selected: bool = false

func get_weight(type: int) -> int:
	if type == 0: # IRON
		return 1
	elif type == 1: # GOLD
		return 2
	return 0

func can_add(type: int) -> bool:
	return current_load + get_weight(type) <= MAX_CAPACITY

func add_resource(type: int, amount: int = 1) -> void:
	var weight = get_weight(type) * amount
	if current_load + weight > MAX_CAPACITY:
		return
		
	if type == 0:
		iron += amount
	elif type == 1:
		gold += amount
		
	current_load += weight
	inventory_changed.emit()

func remove_all() -> Dictionary:
	var dropped = {"iron": iron, "gold": gold}
	iron = 0
	gold = 0
	current_load = 0
	inventory_changed.emit()
	return dropped
