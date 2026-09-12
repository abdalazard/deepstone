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

var target_player: Node2D = null

func hit() -> void:
	target_player = get_tree().current_scene.get_node_or_null("Player")
	if not target_player:
		queue_free()

func _process(delta: float) -> void:
	if target_player:
		var sprite = $Sprite2D
		if sprite:
			sprite.global_position = sprite.global_position.lerp(target_player.global_position, 10.0 * delta)
			if sprite.global_position.distance_to(target_player.global_position) < 8.0:
				queue_free()
		else:
			queue_free()
