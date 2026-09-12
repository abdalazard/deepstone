extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("is_resource"):
		# Extract the resource
		Inventory.add_resource(body.type, 1)
		
		# Visual effect for extraction
		var tween = create_tween()
		tween.tween_property(body, "scale", Vector2.ZERO, 0.2)
		tween.tween_property(body, "global_position", global_position + Vector2(0, -24), 0.2)
		tween.finished.connect(body.queue_free)
		
		# Disable physics on the body immediately so it doesn't get extracted twice
		body.set_deferred("freeze", true)
		if body.has_node("CollisionShape2D"):
			body.get_node("CollisionShape2D").set_deferred("disabled", true)
