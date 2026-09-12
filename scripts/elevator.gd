extends AnimatableBody2D

var moving_up = false
var moving_down = false
var speed = 60.0
var surface_y = 112.0 # Initial position

func _ready() -> void:
	$ExtractionArea.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if moving_up:
		var collision = move_and_collide(Vector2(0, -speed * delta))
		if position.y <= surface_y:
			position.y = surface_y
			moving_up = false
			extract_all_resources()
		elif collision:
			moving_up = false # Hit ceiling
			
	elif moving_down:
		var collision = move_and_collide(Vector2(0, speed * delta))
		if collision:
			moving_down = false # Hit bottom

func hit() -> void:
	# Called when player hits elevator with pickaxe
	if abs(position.y - surface_y) < 5.0:
		# We are at the surface, go down
		moving_down = true
		moving_up = false
	else:
		# We are down in the shaft, go up
		moving_up = true
		moving_down = false

func _on_body_entered(body: Node2D) -> void:
	# Just entering the area doesn't extract if we are down in the shaft
	# Only extract immediately if at surface
	if abs(position.y - surface_y) < 5.0:
		extract_body(body)

func extract_all_resources() -> void:
	for body in $ExtractionArea.get_overlapping_bodies():
		extract_body(body)

func extract_body(body: Node2D) -> void:
	if body.has_method("is_resource"):
		Inventory.add_resource(body.type, 1)
		
		var tween = create_tween()
		tween.tween_property(body, "scale", Vector2.ZERO, 0.2)
		tween.tween_property(body, "global_position", global_position + Vector2(0, -24), 0.2)
		tween.finished.connect(body.queue_free)
		
		body.set_deferred("freeze", true)
		if body.has_node("CollisionShape2D"):
			body.get_node("CollisionShape2D").set_deferred("disabled", true)
