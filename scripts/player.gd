extends CharacterBody2D

@export var speed: float = 120.0
@export var jump_velocity: float = -250.0

var gravity: float = 980.0
var last_direction: Vector2 = Vector2.DOWN
const MINE_DISTANCE: float = 24.0

var in_ladder_count: int = 0
var on_ladder: bool:
	get: return in_ladder_count > 0
func _physics_process(delta: float) -> void:
	if on_ladder:
		if Input.is_action_pressed("ui_up"):
			velocity.y = -100
		elif Input.is_action_pressed("ui_down"):
			velocity.y = 100
		else:
			velocity.y = 0
	else:
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
	
	# Push only resource RigidBodies when holding Drag key
	var push_force = 40.0
	if Input.is_action_pressed("action_drag"):
		for i in get_slide_collision_count():
			var c = get_slide_collision(i)
			var collider = c.get_collider()
			if collider is RigidBody2D and collider.has_method("is_resource"):
				collider.apply_central_impulse(-c.get_normal() * push_force)
	
	if Input.is_action_just_pressed("slot_1"): set_slot(0)
	if Input.is_action_just_pressed("slot_2"): set_slot(1)
	if Input.is_action_just_pressed("slot_3"): set_slot(2)
	if Input.is_action_just_pressed("slot_4"): set_slot(3)
	if Input.is_action_just_pressed("slot_5"): set_slot(4)
	
	if Input.is_action_just_pressed("action_mine"):
		if Inventory.active_slot == 0:
			try_mine()
		elif Inventory.active_slot == 1 and Inventory.signs > 0:
			place_torch()
		elif Inventory.active_slot == 2 and Inventory.ladders > 0:
			place_ladder()
			
	if Input.is_action_just_pressed("action_collect"):
		try_collect()
		
	if Input.is_action_just_pressed("action_inventory"):
		toggle_inventory()

func set_slot(slot: int) -> void:
	Inventory.active_slot = slot
	Inventory.inventory_changed.emit()

func place_torch() -> void:
	Inventory.signs -= 1
	Inventory.inventory_changed.emit()
	
	var torch_scene = load("res://scenes/environment/torch.tscn")
	var torch = torch_scene.instantiate()
	var snapped_x = floor(global_position.x / 16.0) * 16.0 + 8.0
	var snapped_y = floor(global_position.y / 16.0) * 16.0 + 8.0
	torch.position = Vector2(snapped_x, snapped_y)
	get_tree().current_scene.add_child(torch)

func place_ladder() -> void:
	Inventory.ladders -= 1
	Inventory.inventory_changed.emit()
	
	var ladder_scene = load("res://scenes/environment/ladder_segment.tscn")
	if not ladder_scene: return
	var ladder = ladder_scene.instantiate()
	var snapped_x = floor(global_position.x / 16.0) * 16.0 + 8.0
	var snapped_y = floor(global_position.y / 16.0) * 16.0 + 8.0
	ladder.position = Vector2(snapped_x, snapped_y)
	get_tree().current_scene.add_child(ladder)

func try_collect() -> void:
	if has_node("PickupArea"):
		for body in $PickupArea.get_overlapping_bodies():
			if body.has_method("collect"):
				body.collect()

func toggle_inventory() -> void:
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.toggle()

func try_mine() -> void:
	# First check if we can interact with a chest
	if has_node("PickupArea"):
		for body in $PickupArea.get_overlapping_bodies():
			if body.has_method("is_chest") and not body.is_closed:
				if Inventory.current_load > 0:
					var dropped = Inventory.remove_all()
					body.deposit(dropped)
					return # Stop here, we just deposited

	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + last_direction * MINE_DISTANCE)
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.hit_from_inside = true
	query.exclude = [get_rid()]
	
	var result = space_state.intersect_ray(query)
	if result and result.has("collider"):
		var collider = result.collider
		if collider and collider.has_method("hit"):
			collider.hit()
		elif collider and collider.has_method("collect"):
			collider.collect()
