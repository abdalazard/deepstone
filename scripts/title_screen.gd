extends Node2D
# Tela de apresentação: exibe o gif (frames) por 3s com a música rodando.
# Qualquer tecla (ou clique) pula direto para o jogo.

const PRESENTATION_SECONDS := 3.0
const FRAME_COUNT := 240
const FRAMES_DIR := "res://assets/sprites/title_frames/"
const MAIN_SCENE := "res://scenes/main/main.tscn"

var _started := false

func _ready() -> void:
	var anim := AnimatedSprite2D.new()
	anim.name = "TitleAnim"
	anim.centered = true
	anim.position = Vector2(640, 350)
	anim.scale = Vector2(2.0, 2.0)
	anim.sprite_frames = _build_frames()
	add_child(anim)
	anim.animation_finished.connect(_on_animation_finished)
	anim.play("title")

func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("title")
	for i in FRAME_COUNT:
		var tex = load(FRAMES_DIR + "frame_%03d.png" % i)
		if tex:
			frames.add_frame("title", tex)
	frames.set_animation_loop("title", false)
	frames.set_animation_speed("title", float(FRAME_COUNT) / PRESENTATION_SECONDS)
	return frames

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_start_game()
	elif event is InputEventMouseButton and event.pressed:
		_start_game()

func _on_animation_finished() -> void:
	_start_game()

func _start_game() -> void:
	if _started:
		return
	_started = true
	get_tree().change_scene_to_file(MAIN_SCENE)