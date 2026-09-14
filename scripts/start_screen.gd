extends CanvasLayer

enum Mode { START, TUTORIAL }

var mode: int = Mode.START

@onready var start_info: Label = $Overlay/CenterContainer/TutorialPanel/PanelMargin/VBox/StartInfo

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	if mode == Mode.START and has_node("/root/SaveManager") and SaveManager.has_save():
		if start_info:
			start_info.text = "Pressione [ Z ] para Continuar\n[ R ] para Novo Jogo"
	elif mode == Mode.TUTORIAL and start_info:
		start_info.text = "Pressione [ Z ] ou [ Esc ] para Fechar"

func _process(_delta) -> void:
	if mode == Mode.START:
		if Input.is_action_just_pressed("action_mine"):
			get_tree().paused = false
			queue_free()
		elif Input.is_physical_key_pressed(KEY_R):
			if has_node("/root/SaveManager") and SaveManager.has_save():
				SaveManager.clear_save()
				get_tree().paused = false
				get_tree().reload_current_scene()
	else:
		if Input.is_action_just_pressed("action_mine") or Input.is_physical_key_pressed(KEY_ESCAPE):
			get_tree().paused = false
			queue_free()

func _close() -> void:
	get_tree().paused = false
	queue_free()
