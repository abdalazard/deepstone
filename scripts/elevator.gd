extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.in_ladder_count += 1
	elif body.has_method("is_chest"):
		body.in_ladder = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		body.in_ladder_count = max(0, body.in_ladder_count - 1)
	elif body.has_method("is_chest"):
		body.in_ladder = false
