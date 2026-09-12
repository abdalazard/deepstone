extends CharacterBody2D

@export var speed: float = 120.0
@export var jump_velocity: float = -250.0

var gravity: float = 980.0
var last_direction: Vector2 = Vector2.DOWN
const MINE_DISTANCE: float = 48.0
var in_ladder_count: int = 0
var on_ladder: bool:
	get: return in_ladder_count > 0

var anim_timer: float = 0.0
var anim_frame: int = 0
var anim_state: String = "idle" # idle, dig, walk
var is_mining: bool = false
var mine_timer: float = 0.0

var tex_idle = preload("res://assets/sprites/Idle.png")
var tex_walk = preload("res://assets/sprites/Walk.png")
var tex_jump = preload("res://assets/sprites/Jump.png")
var tex_mine = preload("res://assets/sprites/Minering.png")
var tex_climb = preload("res://assets/sprites/Rope.png")

func _process(delta: float) -> void:
	if is_mining:
		mine_timer -= delta
		if mine_timer <= 0:
			is_mining = false
	
	if on_ladder:
		if velocity.y != 0:
			anim_state = "climb"
		else:
			anim_state = "climb_idle"
	elif is_mining:
		anim_state = "dig"
	elif not is_on_floor():
		anim_state = "jump"
	elif velocity.x != 0:
		anim_state = "walk"
	else:
		anim_state = "idle"
		
	# Update frames
	if anim_state != "climb_idle":
		anim_timer += delta
	
	var fps = 8.0 if anim_state in ["walk", "dig", "climb", "jump"] else 4.0
	
	var current_tex = tex_idle
	if anim_state == "walk": current_tex = tex_walk
	elif anim_state == "jump": current_tex = tex_jump
	elif anim_state == "dig": current_tex = tex_mine
	elif anim_state in ["climb", "climb_idle"]: current_tex = tex_climb
	
	var sprite = $Sprite2D
	if sprite.texture != current_tex:
		sprite.texture = current_tex
		sprite.vframes = 1
		sprite.hframes = int(current_tex.get_width() / 32.0)
		sprite.scale = Vector2(1, 1) # Reset scale since new sprites are 32x32
		anim_frame = 0 # reset frame on state change
	
	if anim_timer > 1.0 / fps:
		anim_timer = 0.0
		anim_frame = (anim_frame + 1) % sprite.hframes
	
	sprite.frame = anim_frame
	
	if anim_state not in ["climb", "climb_idle"] and last_direction.x != 0:
		sprite.flip_h = last_direction.x < 0

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
			if collider is RigidBody2D and collider.has_method("is_ore") and collider.is_ore():
				collider.apply_central_impulse(-c.get_normal() * push_force)
	
	if Input.is_action_just_pressed("slot_1"): set_slot(0)
	if Input.is_action_just_pressed("slot_2"): set_slot(1)
	if Input.is_action_just_pressed("slot_3"): set_slot(2)
	if Input.is_action_just_pressed("slot_4"): set_slot(3)
	if Input.is_action_just_pressed("slot_5"): set_slot(4)
	
	if Input.is_action_just_pressed("action_cycle_slot"):
		# Cycle between 0, 1, 2 (Pickaxe, Sign, Rope)
		set_slot((Inventory.active_slot + 1) % 3)
	
	if Input.is_action_just_pressed("action_mine"):
		if _try_chest_interaction():
			pass # Interaction succeeded
		elif Inventory.active_slot == 0:
			try_mine()
		elif Inventory.active_slot == 1 and Inventory.signs > 0:
			place_torch()
		elif Inventory.active_slot == 2:
			place_rope()
			
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
	var snapped_x = floor(global_position.x / 32.0) * 32.0 + 16.0
	var snapped_y = round(global_position.y / 32.0) * 32.0
	torch.position = Vector2(snapped_x, snapped_y)
	get_tree().current_scene.add_child(torch)

func place_rope() -> void:
	# Rope is infinite, no decrement needed
	var rope_scene = load("res://scenes/environment/rope_segment.tscn")
	if not rope_scene: return
	var rope = rope_scene.instantiate()
	var snapped_x = floor(global_position.x / 32.0) * 32.0 + 16.0
	var snapped_y = round(global_position.y / 32.0) * 32.0
	rope.position = Vector2(snapped_x, snapped_y)
	get_tree().current_scene.add_child(rope)

func try_collect() -> void:
	if has_node("PickupArea"):
		for body in $PickupArea.get_overlapping_bodies():
			if body.has_method("collect"):
				body.collect()

func toggle_inventory() -> void:
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.toggle()

func _try_chest_interaction() -> bool:
	if has_node("PickupArea"):
		for body in $PickupArea.get_overlapping_bodies():
			if body.has_method("is_chest"):
				if not body.is_closed and (Inventory.iron > 0 or Inventory.gold > 0):
					var dropped = Inventory.remove_all()
					body.deposit(dropped)
				elif body.is_closed:
					body.extract()
				return true
	return false

func try_mine() -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + last_direction * MINE_DISTANCE)
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.collision_mask = 5 # Block and Placed items
	
	is_mining = true
	mine_timer = 0.5
	
	var result = space_state.intersect_ray(query)
	if result and result.has("collider"):
		var collider = result.collider
		if collider and collider.has_method("hit"):
			collider.hit()
		elif collider and collider.has_method("collect"):
			collider.collect()
