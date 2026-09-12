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
var plank_drop_timer: float = 0.0

var tex_idle = preload("res://assets/sprites/Idle.png")
var tex_walk = preload("res://assets/sprites/Walk.png")
var tex_jump = preload("res://assets/sprites/Jump.png")
var tex_mine = preload("res://assets/sprites/Minering.png")
var tex_climb = preload("res://assets/sprites/Rope.png")

var inventory_override: Node = null

func _get_inv() -> Node:
	if inventory_override:
		return inventory_override
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("Inventory"):
		return get_tree().root.get_node("Inventory")
	return null

func _get_save() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("SaveManager"):
		return get_tree().root.get_node("SaveManager")
	return null

func _ready() -> void:
	var sm = _get_save()
	if sm and sm.has_loaded_save and sm.player_saved_pos != Vector2.ZERO:
		global_position = sm.player_saved_pos
	else:
		global_position = Vector2(640, 96)
	safe_margin = 0.15
	var sprite = $Sprite2D
	if sprite:
		sprite.scale = sprite_scale
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.flip_h = true
		
	var inv = _get_inv()
	if inv and not inv.level_up.is_connected(_on_level_up):
		inv.level_up.connect(_on_level_up)

func _on_level_up(new_lvl: int, _req_exp: int) -> void:
	# In-world character Level Up VFX
	_spawn_level_up_aura(new_lvl)

func _spawn_level_up_aura(lvl: int) -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 24
	particles.lifetime = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 20.0
	particles.spread = 180.0
	particles.gravity = Vector2(0, -60)
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 50.0
	particles.scale_amount_min = 2.5
	particles.scale_amount_max = 5.0
	particles.color = Color(1.0, 0.85, 0.25, 1.0) # Golden sparks
	add_child(particles)
	
	# Floating label over player
	var lbl = Label.new()
	lbl.text = "★ NÍVEL %d! ★" % lvl
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.modulate = Color(1.0, 0.9, 0.3, 1.0)
	lbl.position = Vector2(-40, -45)
	add_child(lbl)
	
	var tween = create_tween()
	tween.tween_property(lbl, "position:y", -70.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 1.2).set_delay(0.4)
	tween.tween_callback(func():
		lbl.queue_free()
		particles.queue_free()
	)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Shift + A: Open Hotbar Shortcuts Config
		if event.physical_keycode == KEY_A and (event.shift_pressed or Input.is_key_pressed(KEY_SHIFT)):
			var hud = get_tree().current_scene.get_node_or_null("HUD") if get_tree() and get_tree().current_scene else null
			if hud and hud.has_method("toggle_hotbar_config"):
				hud.toggle_hotbar_config()
				if get_viewport(): get_viewport().set_input_as_handled()
				return
		# Numeric keys 1 to 6
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_6:
			var slot_idx = event.physical_keycode - KEY_1
			set_slot(slot_idx)

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
	
	if is_mining and last_direction.x != 0:
		sprite.flip_h = (last_direction.x < 0)
	elif facing_x != 0:
		sprite.flip_h = (facing_x < 0)

func _physics_process(delta: float) -> void:
	# Pass through planks (layer 6) freely when climbing on ladder or pressing down
	if Input.is_action_pressed("ui_down"):
		plank_drop_timer = 0.25
	elif plank_drop_timer > 0.0:
		plank_drop_timer -= delta

	var can_collide_plank = (not on_ladder) and (plank_drop_timer <= 0.0) and (not Input.is_action_pressed("ui_down"))
	set_collision_mask_value(6, can_collide_plank)

	# Double-tap down dash on ladder
	if Input.is_action_just_pressed("ui_down") and on_ladder:
		var now = Time.get_ticks_msec() / 1000.0
		if (now - last_down_press_time) <= DOUBLE_TAP_MAX_DELAY and not is_on_floor():
			down_dash_timer = 0.35
			velocity.y = 380.0
			var inv = _get_inv()
			if inv: inv.notify("Descida Rápida!", "dash")
		last_down_press_time = now

	if down_dash_timer > 0:
		down_dash_timer -= delta
		if is_on_floor():
			down_dash_timer = 0.0
			velocity.y = 0.0
		else:
			velocity.y = 300.0
	elif on_ladder:
		if is_mining:
			velocity.y = 0.0
		elif Input.is_action_pressed("ui_up"):
			velocity.y = -100.0
		elif Input.is_action_pressed("ui_down"):
			if not is_on_floor():
				velocity.y = 100.0
			else:
				velocity.y = 0.0
		elif is_on_floor():
			velocity.y = 0.0
		else:
			velocity.y = 0.0
	else:
		# Add the gravity.
		if not is_on_floor():
			velocity.y += gravity * delta
		elif velocity.y > 0.0:
			velocity.y = 0.0
	
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
	var is_dragging = Input.is_action_pressed("action_drag")
	var is_kick = Input.is_action_just_pressed("action_drag")
	var current_speed = speed

	if is_on_floor() or on_ladder:
		if direction != 0:
			facing_x = sign(direction)
			if is_dragging:
				# Pushing effort: slow speed to 40.0
				current_speed = 40.0
			velocity.x = direction * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
	else:
		# Air control: lateral impulse control via left/right arrows without instant ground friction
		if direction != 0:
			facing_x = sign(direction)
			velocity.x = move_toward(velocity.x, direction * speed, 320.0 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, 140.0 * delta)

	# Clamp velocity so external impulses never catapult or bury the character
	velocity.x = clamp(velocity.x, -speed, speed)
	velocity.y = clamp(velocity.y, -380.0, 340.0)

	move_and_slide()

	# Active depenetration: if character overlaps any solid blocks, step upward to top surface
	_depenetrate_from_blocks()

	# Push / Kick loose ores when interacting with [X]
	for i in get_slide_collision_count():
		if i < get_slide_collision_count():
			var c = get_slide_collision(i)
			var collider = c.get_collider()
			if collider is RigidBody2D and collider.has_method("is_ore") and collider.is_ore():
				if is_kick:
					# Second X tap: Kick the block with high force and distance
					if collider.has_method("kick_push"):
						collider.kick_push(facing_x, 220.0)
					velocity.x = -facing_x * 30.0 # Small recoil
					var inv_n = _get_inv()
					if inv_n: inv_n.notify("Chute no bloco!", "dash")
					break
				elif is_dragging and direction != 0:
					velocity.x = clamp(velocity.x, -40.0, 40.0)
					if collider.has_method("drag_push"):
						collider.drag_push(facing_x, 45.0)

	var inv = _get_inv()
	if Input.is_action_just_pressed("slot_1"): set_slot(0)
	if Input.is_action_just_pressed("slot_2"): set_slot(1)
	if Input.is_action_just_pressed("slot_3"): set_slot(2)
	if Input.is_action_just_pressed("slot_4"): set_slot(3)
	
	if Input.is_action_just_pressed("action_cycle_slot"):
		var cur_slot = inv.active_slot if inv else 0
		var max_s = inv.hotbar_slots.size() if (inv and "hotbar_slots" in inv) else 6
		var next_slot = (cur_slot + 1) % max_s
		set_slot(next_slot)
	
	if Input.is_action_just_pressed("action_mine"):
		execute_active_item()
			
	if Input.is_action_just_pressed("action_collect"):
		try_collect()
		
	if Input.is_action_just_pressed("action_inventory"):
		toggle_inventory()

func execute_active_item() -> void:
	var inv = _get_inv()
	var key = inv.get_active_item_key() if inv else "pickaxe"
	match key:
		"pickaxe":
			try_mine()
		"lamp":
			if inv and inv.can_place_lamp():
				place_torch()
			else:
				if inv: inv.notify("Sem postes disponíveis! Crie na Forja com carvão e ferro.", "lamp")
		"ladder":
			if inv and inv.ladders > 0:
				place_rope()
			else:
				if inv: inv.notify("Sem escadas! Crie na Forja usando madeira.", "ladder")
		"plank":
			if inv and inv.planks > 0:
				place_plank()
			else:
				if inv: inv.notify("Sem tábuas! Crie na Forja usando madeira.", "plank")
		"brick":
			if inv and inv.brick_floors > 0:
				place_brick_floor()
			else:
				if inv: inv.notify("Sem pisos de tijolo! Crie na Forja usando terra e pedra.", "plank")
		"forge":
			if inv and inv.portable_forges > 0:
				place_portable_forge()
			else:
				if inv: inv.notify("Sem forjas portáteis! Crie na Forja usando pedra e ferro.", "forge")
		_:
			try_mine()

func set_slot(slot: int) -> void:
	var inv = _get_inv()
	if inv:
		var max_s = inv.hotbar_slots.size() if "hotbar_slots" in inv else 6
		if slot >= 0 and slot < max_s:
			inv.active_slot = slot
			inv.inventory_changed.emit()

func place_torch() -> void:
	var inv = _get_inv()
	if not inv or not inv.can_place_lamp():
		if inv: inv.notify("Sem postes disponíveis! Crie na Forja.", "lamp")
		return
	inv.consume_lamp()
	
	var torch_scene = load("res://scenes/environment/torch.tscn")
	var torch = torch_scene.instantiate()
	var snapped_x = floor(global_position.x / 32.0) * 32.0 + 16.0
	var snapped_y = round(global_position.y / 32.0) * 32.0
	torch.position = Vector2(snapped_x, snapped_y)
	torch.add_to_group("placed_torches")
	get_tree().current_scene.add_child(torch)
	var sm = _get_save()
	if sm:
		sm.request_save()

func place_rope() -> void:
	var inv = _get_inv()
	if not inv or inv.ladders <= 0:
		if inv: inv.notify("Sem escadas! Crie na Forja usando madeira.", "ladder")
		return
	inv.ladders -= 1
	inv.inventory_changed.emit()
	
	var rope_scene = load("res://scenes/environment/rope_segment.tscn")
	if not rope_scene: return
	var rope = rope_scene.instantiate()
	var snapped_x = floor(global_position.x / 32.0) * 32.0 + 16.0
	var snapped_y = round(global_position.y / 32.0) * 32.0
	rope.position = Vector2(snapped_x, snapped_y)
	rope.add_to_group("placed_ropes")
	get_tree().current_scene.add_child(rope)
	var sm = _get_save()
	if sm:
		sm.request_save()

func place_plank() -> void:
	var inv = _get_inv()
	if not inv or inv.planks <= 0:
		if inv: inv.notify("Sem tábuas! Crie na Forja usando madeira.", "plank")
		return
	inv.planks -= 1
	inv.inventory_changed.emit()
	
	var platform_scene = load("res://scenes/environment/plank.tscn")
	if not platform_scene: return
	var platform = platform_scene.instantiate()
	var place_x = floor((global_position.x + facing_x * 24.0) / 32.0) * 32.0 + 16.0
	var grid_y = round((global_position.y + 11.0 - 112.0) / 32.0)
	if Input.is_action_pressed("ui_down"): grid_y += 1
	elif Input.is_action_pressed("ui_up"): grid_y -= 1
	var place_y = grid_y * 32.0 + 117.0
	platform.position = Vector2(place_x, place_y)
	platform.add_to_group("placed_planks")
	get_tree().current_scene.add_child(platform)
	var sm = _get_save()
	if sm:
		sm.request_save()

func place_brick_floor() -> void:
	var inv = _get_inv()
	if not inv or inv.brick_floors <= 0:
		if inv: inv.notify("Sem pisos de tijolo! Crie na Forja com terra e pedra.", "plank")
		return
	inv.brick_floors -= 1
	inv.inventory_changed.emit()
	
	var platform_scene = load("res://scenes/environment/brick_floor.tscn")
	if not platform_scene: return
	var platform = platform_scene.instantiate()
	var place_x = floor((global_position.x + facing_x * 24.0) / 32.0) * 32.0 + 16.0
	var grid_y = round((global_position.y + 11.0 - 112.0) / 32.0)
	if Input.is_action_pressed("ui_down"): grid_y += 1
	elif Input.is_action_pressed("ui_up"): grid_y -= 1
	var place_y = grid_y * 32.0 + 117.0
	platform.position = Vector2(place_x, place_y)
	platform.add_to_group("placed_planks")
	get_tree().current_scene.add_child(platform)
	var sm = _get_save()
	if sm:
		sm.request_save()

func place_portable_forge() -> void:
	var inv = _get_inv()
	if not inv or inv.portable_forges <= 0:
		if inv: inv.notify("Sem forjas portáteis! Crie na Forja com 5 pedras e 3 ferros.", "forge")
		return
	inv.portable_forges -= 1
	inv.inventory_changed.emit()
	
	var forge_scene = load("res://scenes/environment/forge.tscn")
	if not forge_scene: return
	var forge = forge_scene.instantiate()
	var place_x = floor((global_position.x + facing_x * 24.0) / 32.0) * 32.0 + 16.0
	var place_y = round(global_position.y / 32.0) * 32.0
	forge.position = Vector2(place_x, place_y)
	forge.add_to_group("placed_forges")
	get_tree().current_scene.add_child(forge)
	inv.notify("Forja Portátil Instalada!", "forge")
	var sm = _get_save()
	if sm:
		sm.request_save()

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
				var inv = _get_inv()
				if not body.is_closed and inv and (inv.iron > 0 or inv.gold > 0 or inv.coal > 0):
					var dropped = inv.remove_all()
					body.deposit(dropped)
				elif body.is_closed:
					body.extract()
				return true
	return false

func _is_ladder_segment(col: Node) -> bool:
	if not is_instance_valid(col): return false
	return col.is_in_group("placed_ropes") or col.name.begins_with("RopeSegment") or (col is Area2D and col.has_method("hit") and not col.has_method("is_ore") and not col.has_method("fell_tree") and not col.name.begins_with("Torch") and not col.name.begins_with("Plank"))

func _break_block_above() -> void:
	var world_2d = get_world_2d()
	if not world_2d and is_inside_tree() and get_viewport():
		world_2d = get_viewport().find_world_2d()
	if not world_2d or not world_2d.direct_space_state:
		return
	var space_state = world_2d.direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position + Vector2(0, -32)
	query.collision_mask = 1 # Solid blocks
	query.collide_with_bodies = true
	query.collide_with_areas = true
	var results = space_state.intersect_point(query)
	for r in results:
		var col = r.collider
		if is_instance_valid(col) and col != self:
			if col.has_method("hit") and not col.get("is_unbreakable"):
				col.hit()

func try_mine() -> void:
	var inv = _get_inv()
	if inv and not inv.has_pickaxe:
		inv.notify("Sua picareta está quebrada! Forje uma nova na forja.", "pickaxe")
		return

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
		
	is_mining = true
	mine_timer = 0.5
	
	# Britadeira (Jackhammer action) when pressing DOWN and stuck inside a block
	if Input.is_action_pressed("ui_down") and _is_overlapping_solid(global_position):
		velocity.y = -140.0 # Small jackhammer hop
		global_position.y -= 4.0 # Gradually pops player upward out of the block
		_break_block_above() # Breaks block above to clear overhead space!
		if inv: inv.notify("Britadeira!", "pickaxe")
	
	var world_2d = get_world_2d()
	if not world_2d and is_inside_tree() and get_viewport():
		world_2d = get_viewport().find_world_2d()
	if not world_2d or not world_2d.direct_space_state:
		return
	var space_state = world_2d.direct_space_state
	
	var excludes = [get_rid()]
	# Protect ladder: if on ladder and mining sideways, exclude ladders so pickaxe strikes surrounding blocks
	if on_ladder and last_direction.x != 0:
		if is_inside_tree() and get_tree():
			for r in get_tree().get_nodes_in_group("placed_ropes"):
				if is_instance_valid(r):
					excludes.append(r.get_rid())
	
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + last_direction * MINE_DISTANCE)
	query.collide_with_bodies = true
	query.collide_with_areas = true
	query.hit_from_inside = true
	query.exclude = excludes
	query.collision_mask = 37 # 1 (Blocks), 4 (Drops), 32 (Planks)
	
	var target_collider = null
	var result = space_state.intersect_ray(query)
	if result and result.has("collider"):
		target_collider = result.collider
		
	# If raycast didn't find a minable/collectible target, check point queries along aim direction and at player position
	if not target_collider or (not target_collider.has_method("hit") and not target_collider.has_method("collect")):
		var check_points = [
			global_position + last_direction * 24.0,
			global_position + last_direction * 36.0,
			global_position + Vector2(0, 16.0), # Feet / ground
			global_position + Vector2(0, -8.0), # Torso/head
			global_position # Exact center
		]
		for pt in check_points:
			var pt_query = PhysicsPointQueryParameters2D.new()
			pt_query.position = pt
			pt_query.collision_mask = 37
			pt_query.collide_with_bodies = true
			pt_query.collide_with_areas = true
			pt_query.exclude = excludes
			var pt_results = space_state.intersect_point(pt_query)
			for r in pt_results:
				var col = r.collider
				if is_instance_valid(col) and col != self:
					if on_ladder and last_direction.x != 0 and _is_ladder_segment(col):
						continue
					if col.has_method("hit") or col.has_method("collect"):
						target_collider = col
						break
			if target_collider:
				break

	if target_collider:
		# Check if target is a ladder segment while player is on ladder and aiming sideways
		if on_ladder and last_direction.x != 0 and _is_ladder_segment(target_collider):
			return # Shield ladder rung from lateral swings
		if target_collider.has_method("hit"):
			target_collider.hit()
		elif target_collider.has_method("collect"):
			target_collider.collect()

func _is_overlapping_solid(pos: Vector2) -> bool:
	var world_2d = get_world_2d()
	if not world_2d and is_inside_tree() and get_viewport():
		world_2d = get_viewport().find_world_2d()
	if not world_2d or not world_2d.direct_space_state:
		return false
	var space_state = world_2d.direct_space_state
	
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 1 # Solid terrain / bedrock / ores
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	
	var results = space_state.intersect_point(query)
	for r in results:
		var col = r.collider
		if is_instance_valid(col) and col != self and not col.is_in_group("placed_ropes") and not col.is_in_group("placed_torches") and not col.is_in_group("placed_planks"):
			return true
	return false

func _depenetrate_from_blocks() -> void:
	# Active safety check: if player center or feet are inside solid geometry (layer 1)
	# Push player upward step-by-step to the free space above
	var center_overlap = _is_overlapping_solid(global_position)
	var feet_overlap = _is_overlapping_solid(global_position + Vector2(0, 10.0))
	
	if center_overlap or feet_overlap:
		# Try stepping upward by 4px up to 8 iterations
		for step in range(8):
			global_position.y -= 4.0
			if not _is_overlapping_solid(global_position) and not _is_overlapping_solid(global_position + Vector2(0, 10.0)):
				velocity.y = min(velocity.y, 0.0)
				break
