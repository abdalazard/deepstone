extends Area2D

var target_player: Node2D = null

func hit() -> void:
	Inventory.signs += 1
	Inventory.inventory_changed.emit()
	
	target_player = get_tree().current_scene.get_node_or_null("Player")
	if not target_player:
		queue_free()

func _process(delta: float) -> void:
	if target_player:
		var sprite = $Sprite2D
		sprite.global_position = sprite.global_position.lerp(target_player.global_position, 10.0 * delta)
		if sprite.global_position.distance_to(target_player.global_position) < 8.0:
			queue_free()
