extends Area2D

@onready var prompt_label: Label = $PromptLabel
var player_inside: bool = false

func _ready() -> void:
	if prompt_label:
		prompt_label.modulate.a = 0.0
		prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_inside = true
		if prompt_label:
			prompt_label.visible = true
			var tween = create_tween()
			tween.tween_property(prompt_label, "modulate:a", 1.0, 0.2)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_inside = false
		if prompt_label:
			var tween = create_tween()
			tween.tween_property(prompt_label, "modulate:a", 0.0, 0.2)
			tween.tween_callback(prompt_label.hide)

func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("action_mine"):
		read_sign()

func read_sign() -> void:
	Inventory.notify("Mina: Cave o bloco à direita para descer!", "sign")
	if prompt_label:
		# Quick bounce effect on prompt
		var tween = create_tween()
		tween.tween_property(prompt_label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(prompt_label, "scale", Vector2.ONE, 0.1)
