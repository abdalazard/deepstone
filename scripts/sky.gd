extends Node2D

# Parallax / Drifting cloud controller
@export var wrap_min_x: float = -300.0
@export var wrap_max_x: float = 1350.0

var cloud_data: Array[Dictionary] = []

func _ready() -> void:
	var clouds_node = get_node_or_null("Clouds")
	if not clouds_node:
		return
		
	# Randomize slightly different drifting speeds for each cloud
	var speeds = [10.0, 18.0, 14.0, 22.0, 8.0, 16.0, 12.0, 25.0]
	var i = 0
	for child in clouds_node.get_children():
		if child is Node2D:
			var spd = speeds[i % speeds.size()]
			cloud_data.append({
				"node": child,
				"speed": spd
			})
			i += 1

func _process(delta: float) -> void:
	for item in cloud_data:
		var node: Node2D = item["node"]
		var speed: float = item["speed"]
		node.position.x += speed * delta
		if node.position.x > wrap_max_x:
			node.position.x = wrap_min_x
