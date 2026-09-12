extends Node

signal inventory_changed
signal notification_triggered(text: String, icon_type: String)

const MAX_STACK: int = 20
var iron: int = 0
var gold: int = 0
var signs: int = 10
var active_slot: int = 0 # 0=Pickaxe, 1=Sign, 2=Rope, 3=Iron, 4=Gold

func notify(text: String, icon_type: String = "") -> void:
	notification_triggered.emit(text, icon_type)

func can_add(type: int) -> bool:
	if type == 0: return iron < MAX_STACK
	if type == 1: return gold < MAX_STACK
	return false

func add_resource(type: int, amount: int) -> void:
	if type == 0:
		var added = min(amount, MAX_STACK - iron)
		iron += added
		if added > 0:
			notify("+%d Minério de Ferro" % added, "iron")
	elif type == 1:
		var added = min(amount, MAX_STACK - gold)
		gold += added
		if added > 0:
			notify("+%d Minério de Ouro" % added, "gold")
	inventory_changed.emit()
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").request_save()

func remove_all() -> Dictionary:
	var dropped = {"iron": iron, "gold": gold}
	iron = 0
	gold = 0
	inventory_changed.emit()
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").request_save()
	return dropped
