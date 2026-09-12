extends StaticBody2D

@onready var prompt_label: Label = $PromptLabel
@onready var fire_light: PointLight2D = $PointLight2D
@onready var interact_area: Area2D = $InteractArea

var player_in_range: bool = false
var base_energy: float = 0.8
var flicker_timer: float = 0.0

func _ready() -> void:
	if prompt_label:
		prompt_label.modulate.a = 0.0
		prompt_label.visible = false
	if interact_area:
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	# Subtle flame flicker effect
	flicker_timer += delta * 8.0
	if fire_light:
		fire_light.energy = base_energy + sin(flicker_timer) * 0.12 + randf_range(-0.04, 0.04)

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("action_mine"):
		_show_feedback()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true
			var tween = create_tween()
			tween.tween_property(prompt_label, "modulate:a", 1.0, 0.2)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false
		if prompt_label:
			var tween = create_tween()
			tween.tween_property(prompt_label, "modulate:a", 0.0, 0.2)
			tween.tween_callback(prompt_label.hide)

func _show_feedback() -> void:
	if prompt_label:
		prompt_label.text = "Forja (EM BREVE)"
		var tween = create_tween()
		tween.tween_property(prompt_label, "modulate", Color(1.5, 1.2, 0.3, 1.0), 0.1)
		tween.tween_property(prompt_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
		tween.tween_interval(1.2)
		tween.tween_callback(func():
			if is_instance_valid(prompt_label):
				prompt_label.text = "[Z] Forja (Em Breve)"
		)
