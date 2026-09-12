extends CharacterBody2D

@export var speed: float = 120.0
@export var jump_velocity: float = -250.0
@export var sprite_scale: Vector2 = Vector2(3.0, 3.0)

var gravity: float = 980.0
var last_direction: Vector2 = Vector2.LEFT
var facing_x: float = -1.0
const MINE_DISTANCE: float = 48.0
var in_ladder_count: int = 0
var on_ladder: bool:
	get: return in_ladder_count > 0

var anim_timer: float = 0.0
var anim_frame: int = 0
var anim_state: String = "idle" # idle, dig, walk
var is_mining: bool = false
var mine_timer: float = 0.0

var last_down_press_time: float = -1.0
const DOUBLE_TAP_MAX_DELAY: float = 0.28
var down_dash_timer: float = 0.0

var tex_idle = preload("res://assets/sprites/Idle.png")
var tex_walk = preload("res://assets/sprites/Walk.png")
var tex_jump = preload("res://assets/sprites/Jump.png")
var tex_mine = preload("res://assets/sprites/Minering.png")
var tex_climb = preload("res://assets/sprites/Rope.png")

func _ready() -> void:
	if has_node("/root/SaveManager") and SaveManager.has_loaded_save and SaveManager.player_saved_pos != Vector2.ZERO:
		global_position = SaveManager.player_saved_pos
	else:
		global_position = Vector2(640, 96)
	var sprite = $Sprite2D
	if sprite:
		sprite.scale = sprite_scale
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.flip_h = true

func _process(delta: float) -> void:
	if is_mining:
		mine_timer -= delta
		if mine_timer <= 0:
			is_mining = false
	
	if is_mining:
		anim_state = "dig"
	elif on_ladder:
		if is_on_floor() and not Input.is_action_pressed("ui_up"):
			if velocity.x != 0:
				anim_state = "walk"
			else:
				anim_state = "idle"
		elif velocity.y != 0:
			anim_state = "climb"
		else:
			anim_state = "climb_idle"
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
		sprite.scale = sprite_scale
		anim_frame = 0 # reset frame on state change
	
	if anim_timer > 1.0 / fps:
		anim_timer = 0.0
		anim_frame = (anim_frame + 1) % sprite.hframes
	
	sprite.frame = anim_frame
	
	if last_direction.x != 0:
		sprite.flip_h = (last_direction.x < 0)
	elif facing_x != 0:
		sprite.flip_h = (facing_x < 0)

func _physics_process(delta: float) -> void:
	# Pass through planks (layer 6) freely when climbing on ladder
	set_collision_mask_value(6, not on_ladder)

	# Double-tap down dash on ladder
	if Input.is_action_just_pressed("ui_down") and on_ladder:
		var now = Time.get_ticks_msec() / 1000.0
		if (now - last_down_press_time) <= DOUBLE_TAP_MAX_DELAY and not is_on_floor():
			down_dash_timer = 0.35
			velocity.y = 380.0
			Inventory.notify("Descida Rápida!", "dash")
		last_down_press_time = now

	if down_dash_timer > 0:
		down_dash_timer -= delta
		velocity.y = 380.0
		if is_on_floor():
			down_dash_timer = 0.0
	elif on_ladder:
		if is_mining:
			velocity.y = 0
		elif Input.is_action_pressed("ui_up"):
			velocity.y = -100
		elif Input.is_action_pressed("ui_down") and not is_on_floor():
			velocity.y = 100
		elif not is_on_floor():
			velocity.y = 0
		else:
			# On floor on ladder
			if not is_on_floor():
				velocity.y += gravity * delta
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
	
	if Input.is_action_pressed("ui_left"):
		aim_dir.x = -1
		facing_x = -1.0
	elif Input.is_action_pressed("ui_right"):
		aim_dir.x = 1
		facing_x = 1.0

	# Movement
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		facing_x = sign(direction)
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	# Clamp velocity so external impulses never catapult the character into walls
	velocity.x = clamp(velocity.x, -speed, speed)
	velocity.y = clamp(velocity.y, -400.0, 500.0)

	move_and_slide()

	# Push fallen ores/debris gently
	var push_force = 18.0
	for i in get_slide_collision_count():
		if i < get_slide_collision_count():
			var c = get_slide_collision(i)
			var collider = c.get_collider()
			if collider is RigidBody2D and collider.has_method("is_ore") and collider.is_ore():
				collider.apply_central_impulse(-c.get_normal() * push_force)
	
	# Only slots 1, 2, 3, 4 (Pickaxe, Lamp, Escada, Tábua) can be selected for button Z
	if Input.is_action_just_pressed("slot_1"): set_slot(0)
	if Input.is_action_just_pressed("slot_2"):
		if Inventory.coal < 3 or Inventory.iron < 2:
			Inventory.notify("Poste indisponível! (Requer 3 Carvões + 2 Ferros)", "lamp")
			set_slot(2) # Pula para o próximo (Escada)
		else:
			set_slot(1)
	if Input.is_action_just_pressed("slot_3"): set_slot(2)
	if Input.is_action_just_pressed("slot_4"): set_slot(3)
	
	if Input.is_action_just_pressed("action_cycle_slot"):
		# Cycle strictly between tools, skipping lamp if insufficient resources
		var next_slot = (Inventory.active_slot + 1) % 4
		if next_slot == 1 and (Inventory.coal < 3 or Inventory.iron < 2):
			next_slot = 2
		set_slot(next_slot)
	
	if Input.is_action_just_pressed("action_mine"):
		if _try_chest_interaction():
			pass # Interaction succeeded
		elif Inventory.active_slot == 0:
			try_mine()
		elif Inventory.active_slot == 1:
			if Inventory.coal >= 3 and Inventory.iron >= 2:
				place_torch()
			else:
				Inventory.notify("Recursos insuficientes! (Requer 3 Carvões + 2 Ferros)", "lamp")
				set_slot(2)
		elif Inventory.active_slot == 2:
			place_rope()
		elif Inventory.active_slot == 3 and Inventory.planks > 0:
			place_plank()
			
	if Input.is_action_just_pressed("action_collect"):
		try_collect()
		
	if Input.is_action_just_pressed("action_inventory"):
		toggle_inventory()

	if Input.is_action_just_pressed("action_equip_menu"):
		toggle_equipment()

func toggle_equipment() -> void:
	var hud = get_tree().current_scene.get_node_or_null("HUD") if (is_inside_tree() and get_tree() and get_tree().current_scene) else null
	if hud and hud.has_method("toggle_equipment"):
		hud.toggle_equipment()

func set_slot(slot: int) -> void:
	if slot == 1 and (Inventory.coal < 3 or Inventory.iron < 2):
		slot = 2
	if slot in [0, 1, 2, 3]:
		Inventory.active_slot = slot
		Inventory.inventory_changed.emit()

func place_torch() -> void:
	if Inventory.coal < 3 or Inventory.iron < 2:
		Inventory.notify("Recursos insuficientes! (Requer 3 Carvões + 2 Ferros)", "lamp")
		return
	Inventory.coal -= 3
	Inventory.iron -= 2
	Inventory.inventory_changed.emit()
	
	var torch_scene = load("res://scenes/environment/torch.tscn")
	var torch = torch_scene.instantiate()
	var snapped_x = floor(global_position.x / 32.0) * 32.0 + 16.0
	var snapped_y = round(global_position.y / 32.0) * 32.0
	torch.position = Vector2(snapped_x, snapped_y)
	torch.add_to_group("placed_torches")
	get_tree().current_scene.add_child(torch)
	if has_node("/root/SaveManager"):
		SaveManager.request_save()

func place_rope() -> void:
	# Rope / Ladder is infinite
	var rope_scene = load("res://scenes/environment/rope_segment.tscn")
	if not rope_scene: return
	var rope = rope_scene.instantiate()
	var snapped_x = floor(global_position.x / 32.0) * 32.0 + 16.0
	var snapped_y = round(global_position.y / 32.0) * 32.0
	rope.position = Vector2(snapped_x, snapped_y)
	rope.add_to_group("placed_ropes")
	get_tree().current_scene.add_child(rope)
	if has_node("/root/SaveManager"):
		SaveManager.request_save()

func place_plank() -> void:
	Inventory.planks -= 1
	Inventory.inventory_changed.emit()
	
	var plank_scene = load("res://scenes/environment/plank.tscn")
	if not plank_scene: return
	var plank = plank_scene.instantiate()
	var place_x = floor((global_position.x + facing_x * 24.0) / 32.0) * 32.0 + 16.0
	# Align top of plank exactly with top of blocks at grid_y * 32.0 + 112.0
	var grid_y = round((global_position.y + 11.0 - 112.0) / 32.0)
	if Input.is_action_pressed("ui_down"): grid_y += 1
	elif Input.is_action_pressed("ui_up"): grid_y -= 1
	var place_y = grid_y * 32.0 + 117.0
	plank.position = Vector2(place_x, place_y)
	plank.add_to_group("placed_planks")
	get_tree().current_scene.add_child(plank)
	if has_node("/root/SaveManager"):
		SaveManager.request_save()

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
				if not body.is_closed and (Inventory.iron > 0 or Inventory.gold > 0 or Inventory.coal > 0):
					var dropped = Inventory.remove_all()
					body.deposit(dropped)
				elif body.is_closed:
					body.extract()
				return true
	return false

func try_mine() -> void:
	# Determine mining aim: if no directional keys held, mine horizontally in current facing direction
	var has_dir = false
	var dir = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		dir.y = -1
		has_dir = true
	elif Input.is_action_pressed("ui_down"):
		dir.y = 1
		has_dir = true
		
	if Input.is_action_pressed("ui_left"):
		dir.x = -1
		facing_x = -1.0
		has_dir = true
	elif Input.is_action_pressed("ui_right"):
		dir.x = 1
		facing_x = 1.0
		has_dir = true
		
	if has_dir and dir != Vector2.ZERO:
		last_direction = dir.normalized()
	else:
		last_direction = Vector2(facing_x, 0)
		
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + last_direction * MINE_DISTANCE)
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.collision_mask = 37 # 1 (Blocks), 4 (Drops), 32 (Planks)
	
	is_mining = true
	mine_timer = 0.5
	
	var result = space_state.intersect_ray(query)
	if result and result.has("collider"):
		var collider = result.collider
		if collider and collider.has_method("hit"):
			collider.hit()
		elif collider and collider.has_method("collect"):
			collider.collect()
