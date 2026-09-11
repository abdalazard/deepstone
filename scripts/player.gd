extends CharacterBody2D

@export var speed: float = 120.0

var last_direction: Vector2 = Vector2.DOWN
const MINE_DISTANCE: float = 24.0

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		last_direction = direction.normalized()
		
	velocity = direction * speed
	move_and_slide()
	
	if Input.is_action_just_pressed("ui_accept"):
		try_mine()

func try_mine() -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + last_direction * MINE_DISTANCE)
	query.collide_with_bodies = true
	
	var result = space_state.intersect_ray(query)
	if result and result.has("collider"):
		var collider = result.collider
		if collider and collider.has_method("hit"):
			collider.hit()
