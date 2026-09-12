extends CanvasLayer

@onready var start_info: Label = $ColorRect/VBoxContainer/StartInfo

func _ready():
	get_tree().paused = true
	if has_node("/root/SaveManager") and SaveManager.has_save():
		if start_info:
			start_info.text = "\nPressione [ Z ] para Continuar\n[ R ] para Novo Jogo"

func _process(_delta):
	if Input.is_action_just_pressed("action_mine"):
		get_tree().paused = false
		queue_free()
	elif Input.is_physical_key_pressed(KEY_R):
		if has_node("/root/SaveManager") and SaveManager.has_save():
			SaveManager.clear_save()
			get_tree().paused = false
			get_tree().reload_current_scene()
