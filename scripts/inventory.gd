extends Node

signal inventory_changed

const MAX_STACK: int = 20
var iron: int = 0
var gold: int = 0
var signs: int = 10
var active_slot: int = 0 # 0=Pickaxe, 1=Sign, 2=Rope, 3=Iron, 4=Gold

func can_add(type: int) -> bool:
	if type == 0: return iron < MAX_STACK
	if type == 1: return gold < MAX_STACK
	return false

func add_resource(type: int, amount: int) -> void:
	if type == 0:
		iron = min(iron + amount, MAX_STACK)
	elif type == 1:
		gold = min(gold + amount, MAX_STACK)
	inventory_changed.emit()

func remove_all() -> Dictionary:
	var dropped = {"iron": iron, "gold": gold}
	iron = 0
	gold = 0
	inventory_changed.emit()
	return dropped
