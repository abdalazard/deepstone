extends Node

signal inventory_changed

var stone: int = 0
var copper: int = 0

func add_resource(type: int, amount: int = 1) -> void:
	if type == 0: # STONE
		stone += amount
	elif type == 1: # COPPER
		copper += amount
		
	inventory_changed.emit()
