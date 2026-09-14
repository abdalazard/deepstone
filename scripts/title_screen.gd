extends Control
# Tela de apresentação: exibe o vídeo .ogv (Theora) com a música rodando.
# Qualquer tecla (ou clique) pula direto para o jogo.
# O vídeo é decodificado quadro a quadro (streaming), sem carregar frames
# inteiros na memória nem travar a thread principal.

const MAIN_SCENE := "res://scenes/main/main.tscn"
const VIDEO_FILE := "res://assets/videos/title.ogv"

var _started := false
var _video: VideoStreamPlayer

func _ready() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_video = VideoStreamPlayer.new()
	_video.name = "TitleVideo"
	_video.set_anchors_preset(Control.PRESET_FULL_RECT)
	_video.expand = true
	_video.loop = false
	add_child(_video)
	_video.finished.connect(_on_video_finished)
	_try_load_stream()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _try_load_stream() -> void:
	if _video.stream:
		return
	var stream = load(VIDEO_FILE)
	if stream:
		_video.stream = stream
		_video.play()
	else:
		push_warning("Intro: arquivo '%s' indisponivel; tentando novamente." % VIDEO_FILE)

func _process(_delta: float) -> void:
	if not _started and not _video.stream:
		_try_load_stream()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_start_game()
	elif event is InputEventMouseButton and event.pressed:
		_start_game()

func _on_video_finished() -> void:
	_start_game()

func _start_game() -> void:
	if _started:
		return
	_started = true
	get_tree().change_scene_to_file(MAIN_SCENE)
