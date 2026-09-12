extends CharacterBody2D

@export var speed: float = 120.0
@export var jump_velocity: float = -250.0

var gravity: float = 980.0
var last_direction: Vector2 = Vector2.DOWN
const MINE_DISTANCE: float = 24.0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_velocity

	# Aiming logic (for mining)
	var aim_dir = Vector2.ZERO
	if Input.is_action_pressed("ui_up"): aim_dir.y = -1
	elif Input.is_action_pressed("ui_down"): aim_dir.y = 1
	
	if Input.is_action_pressed("ui_left"): aim_dir.x = -1
	elif Input.is_action_pressed("ui_right"): aim_dir.x = 1
	
	if aim_dir != Vector2.ZERO:
		last_direction = aim_dir.normalized()
	elif velocity.x != 0:
		last_direction = Vector2(sign(velocity.x), 0)

	# Handle movement
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	
	# Push RigidBodies
	var push_force = 20.0
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		var collider = c.get_collider()
		if collider is RigidBody2D:
			collider.apply_central_impulse(-c.get_normal() * push_force)
	
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
