extends CanvasLayer

enum Mode { START, TUTORIAL }

var mode: int = Mode.START
var _waiting_for_world := false

@onready var start_info: Label = $Overlay/CenterContainer/TutorialPanel/PanelMargin/VBox/StartInfo
@onready var background: TextureRect = $Background

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	if mode == Mode.TUTORIAL and background:
		background.visible = true
	if mode == Mode.START and has_node("/root/SaveManager") and SaveManager.has_save():
		if start_info:
			start_info.text = "Pressione [ Z ] para Continuar\n[ R ] para Novo Jogo"
	elif mode == Mode.TUTORIAL and start_info:
		start_info.text = "Pressione [ Z ] ou [ Esc ] para Fechar"

func _process(_delta) -> void:
	if mode == Mode.START:
		if _waiting_for_world:
			var main = get_tree().root.get_node_or_null("Main")
			if main == null or main.is_world_ready():
				get_tree().paused = false
				queue_free()
			return
		if Input.is_action_just_pressed("action_mine"):
			var main = get_tree().root.get_node_or_null("Main")
			if main != null and not main.is_world_ready():
				_waiting_for_world = true
				if start_info:
					start_info.text = "Carregando mundo..."
				return
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
