class_name Rock
extends RigidBody2D

@export var is_copper: bool = false
@export var is_coal: bool = false
@export var is_dirt: bool = false
@export var is_stone: bool = false
@export var is_roots: bool = false
@export var is_unbreakable: bool = false
@export var biome: int = 0 # 0=Terra (0-35), 1=Gelo (36-75), 2=Lava (76-120)

var max_hp: int = 3
var hp: int = 3

@onready var sprite_2d: Sprite2D = get_node_or_null("Sprite2D")
const DROP_SCENE = preload("res://scenes/items/resource_drop.tscn")
var cracks: Node2D
var health_bar: Node2D

var light_sources: Array = []
var is_shining: bool = false
var shine_timer: float = 0.0
var sparkle_overlay: Node2D
var sparkle_alpha: float = 0.0
var sparkle_points: Array[Vector2] = []
var grid_pos: Vector2i = Vector2i(-1, -1)
var base_modulate: Color = Color(1, 1, 1, 1)

func set_grid_pos(pos: Vector2i) -> void:
	grid_pos = pos

func apply_biome(b: int) -> void:
	biome = b
	if is_unbreakable:
		if sprite_2d:
			if biome == 1: sprite_2d.modulate = Color(0.65, 0.85, 1.15, 1.0)
			elif biome == 2: sprite_2d.modulate = Color(1.2, 0.45, 0.35, 1.0)
			else: sprite_2d.modulate = Color(1.0, 1.0, 1.0, 1.0)
			base_modulate = sprite_2d.modulate
		return
	
	var base_hp = 3 # Iron default
	if is_dirt: base_hp = 1
	elif is_roots: base_hp = 2 # Raízes de árvore
	elif is_stone: base_hp = 2 # Stone (Pedra)
	elif is_coal: base_hp = 2 # Coal (easy)
	elif is_copper: base_hp = 6 # Gold (demora mais tempo)
	
	if biome == 1: # Gelo (+1 HP)
		max_hp = base_hp + 1
		hp = max_hp
		if sprite_2d:
			if is_dirt or is_roots: sprite_2d.modulate = Color(0.42, 0.65, 0.88, 1.0)
			elif is_stone: sprite_2d.modulate = Color(0.65, 0.85, 1.1, 1.0)
			else: sprite_2d.modulate = Color(0.72, 0.88, 1.1, 1.0)
	elif biome == 2: # Lava (+2 HP)
		max_hp = base_hp + 2
		hp = max_hp
		if sprite_2d:
			if is_dirt or is_roots: sprite_2d.modulate = Color(0.45, 0.22, 0.16, 1.0)
			elif is_stone: sprite_2d.modulate = Color(1.15, 0.5, 0.35, 1.0)
			else: sprite_2d.modulate = Color(1.15, 0.55, 0.35, 1.0)
	else: # Terra
		max_hp = base_hp
		hp = max_hp
		if sprite_2d:
			if is_dirt or is_roots: sprite_2d.modulate = Color(0.5, 0.35, 0.2, 1.0)
			elif is_stone: sprite_2d.modulate = Color(1.0, 1.0, 1.0, 1.0)
			else: sprite_2d.modulate = Color(1.0, 1.0, 1.0, 1.0)
			
	if sprite_2d:
		base_modulate = sprite_2d.modulate

func _ready() -> void:
	if is_unbreakable:
		max_hp = 999999
		hp = 999999
		if sprite_2d:
			sprite_2d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite_2d.frame = randi() % 3
	elif is_roots:
		max_hp = 2
		hp = 2
		if sprite_2d:
			sprite_2d.texture = load("res://assets/sprites/dirt_roots.png")
			sprite_2d.hframes = 1
			sprite_2d.vframes = 1
			sprite_2d.frame = 0
			sprite_2d.scale = Vector2(1, 1)
	elif is_dirt:
		max_hp = 1
		hp = 1
		if sprite_2d and sprite_2d.hframes == 11:
			sprite_2d.frame = 2 # Dirt block
			sprite_2d.modulate = Color(0.5, 0.35, 0.2, 1.0) # Brown tint for dirt
	elif is_stone:
		max_hp = 2
		hp = 2
	elif is_coal:
		max_hp = 2
		hp = 2
		if sprite_2d:
			sprite_2d.frame = 0 # Frame 0: Coal specks
	elif is_copper:
		max_hp = 6
		hp = 6
		if sprite_2d:
			sprite_2d.frame = 8 # Frame 8: Gold specks
	else:
		max_hp = 3
		hp = 3
		if sprite_2d:
			sprite_2d.frame = 2 # Frame 2: Iron specks
			
	apply_biome(biome)
			
	# Setup node to draw cracks over the rock
	if not is_unbreakable:
		cracks = Node2D.new()
		cracks.name = "Cracks"
		cracks.z_index = 1
		add_child(cracks)
		cracks.draw.connect(_on_cracks_draw)
		
		# Health status bar above the block
		health_bar = Node2D.new()
		health_bar.name = "HealthBar"
		health_bar.z_index = 3
		health_bar.position = Vector2(0, -22)
		health_bar.visible = false
		add_child(health_bar)
		health_bar.draw.connect(_on_health_bar_draw)
	
	if not is_dirt and not is_stone and not is_unbreakable:
		sparkle_overlay = Node2D.new()
		sparkle_overlay.name = "Sparkles"
		sparkle_overlay.z_index = 2
		add_child(sparkle_overlay)
		sparkle_overlay.draw.connect(_on_sparkle_draw)
		sparkle_points = [
			Vector2(randf_range(-8, 8), randf_range(-8, 8)),
			Vector2(randf_range(-8, 8), randf_range(-8, 8))
		]
		shine_timer = randf_range(0.2, 1.2)
	
	if self is RigidBody2D:
		lock_rotation = true
		mass = 1.5 # Balanced mass so it never launches the player
		freeze = true
		freeze_mode = RigidBody2D.FREEZE_MODE_STATIC

	set_process(false)
	set_physics_process(false)

var is_falling: bool = false
var fall_timer: float = 0.0
var drag_timer: float = 0.0

func unfreeze_ore() -> void:
	if is_ore() and freeze:
		freeze = false
		is_falling = true
		fall_timer = 0.0
		set_physics_process(true)

func drag_push(dir_x: float, push_speed: float) -> void:
	if not is_ore():
		return
	freeze = false
	drag_timer = 0.25
	linear_velocity.x = dir_x * push_speed
	set_physics_process(true)

func kick_push(dir_x: float, force: float = 200.0) -> void:
	if not is_ore():
		return
	freeze = false
	drag_timer = 0.6
	linear_velocity.x = dir_x * force
	set_physics_process(true)
	spawn_particles()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if is_falling:
		# Cap fall speed to 240 px/s so it never hits with catastrophic force
		if state.linear_velocity.y > 240.0:
			state.linear_velocity.y = 240.0
		state.linear_velocity.x = clamp(state.linear_velocity.x, -30.0, 30.0)
	elif drag_timer > 0.0:
		state.linear_velocity.x = clamp(state.linear_velocity.x, -240.0, 240.0)

func _physics_process(delta: float) -> void:
	if drag_timer > 0.0:
		drag_timer -= delta
		if drag_timer <= 0.0 and not is_falling:
			freeze = true
			freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
			# Snap gently to nearest tile column
			global_position.x = round((global_position.x - 16.0) / 32.0) * 32.0 + 16.0
			set_physics_process(false)
	elif is_falling:
		fall_timer += delta
		# After at least 0.2s of falling, if it has settled or stopped:
		if fall_timer > 0.2 and linear_velocity.length_squared() < 100.0:
			is_falling = false
			freeze = true
			freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
			# Snap gently to nearest tile column
			global_position.x = round((global_position.x - 16.0) / 32.0) * 32.0 + 16.0
			set_physics_process(false)
			_wake_block_above()

func is_ore() -> bool:
	return !is_dirt and !is_unbreakable and !is_stone

func hit(damage: int = 1) -> void:
	if is_unbreakable:
		if sprite_2d:
			sprite_2d.modulate = Color(1.8, 1.8, 2.0, 1.0)
			var tween = create_tween()
			tween.tween_property(sprite_2d, "modulate", Color(1, 1, 1, 1), 0.15)
			var offset = Vector2(randf_range(-2, 2), randf_range(-2, 2))
			sprite_2d.position = offset
			tween.parallel().tween_property(sprite_2d, "position", Vector2.ZERO, 0.1)
		spawn_particles()
		return

	if hp <= 0: return
	
	hp -= max(1, damage)
	
	# Damage pickaxe based on block hardness
	var inv = null
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("Inventory"):
		inv = get_tree().root.get_node("Inventory")
	if inv and inv.has_method("damage_pickaxe"):
		var wear = 1
		if is_roots or is_stone: wear = 2
		elif is_coal or (not is_dirt and not is_copper): wear = 3
		elif is_copper: wear = 5 # Gold is much harder and wears pickaxe faster
		inv.damage_pickaxe(wear)
		
	if cracks: cracks.queue_redraw()
	if health_bar:
		health_bar.visible = hp > 0 and hp < max_hp
		health_bar.queue_redraw()
	
	if sprite_2d:
		sprite_2d.modulate = sprite_2d.modulate + Color(0.5, 0, 0, 0) # Flash reddish
		var tween = create_tween()
		tween.tween_property(sprite_2d, "modulate", base_modulate, 0.15)
		
		# Displacement and Scale shake
		var original_pos = Vector2.ZERO
		var offset = Vector2(randf_range(-3, 3), randf_range(-3, 3))
		sprite_2d.position = original_pos + offset
		cracks.position = sprite_2d.position
		
		var tween_pos = create_tween()
		tween_pos.set_parallel(true)
		tween_pos.tween_property(sprite_2d, "position", original_pos, 0.1)
		tween_pos.tween_property(cracks, "position", original_pos, 0.1)
		
		scale = Vector2(1.1, 1.1)
		var tween_scale = create_tween()
		tween_scale.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

	if hp <= 0:
		destroy()

func destroy() -> void:
	if grid_pos != Vector2i(-1, -1) and has_node("/root/SaveManager"):
		get_node("/root/SaveManager").mark_block_mined(grid_pos)
	spawn_particles()
	_wake_block_above()
	
	var inv = null
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("Inventory"):
		inv = get_tree().root.get_node("Inventory")
	
	if is_roots:
		if inv:
			inv.add_exp(3)
		var drop = DROP_SCENE.instantiate()
		drop.type = 5 # WOOD
		drop.global_position = global_position
		get_parent().add_child(drop)
	elif is_stone:
		if inv:
			inv.add_exp(2)
		var drop = DROP_SCENE.instantiate()
		drop.type = 7 # STONE
		drop.global_position = global_position
		get_parent().add_child(drop)
	elif is_dirt:
		if inv:
			inv.dirt += 1
			inv.add_exp(1)
			inv.inventory_changed.emit()
	elif not is_unbreakable:
		if inv:
			if is_coal: inv.add_exp(3)
			elif is_copper: inv.add_exp(15)
			else: inv.add_exp(5)
		var drop = DROP_SCENE.instantiate()
		if is_coal:
			drop.type = 2 # COAL
		elif is_copper:
			drop.type = 1 # GOLD
		else:
			drop.type = 0 # IRON
		drop.global_position = global_position
		get_parent().add_child(drop)
	
	queue_free()

func _wake_block_above() -> void:
	var space = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position + Vector2(0, -32)
	query.collision_mask = 1
	var results = space.intersect_point(query)
	for r in results:
		var col = r.collider
		if is_instance_valid(col) and col != self and col.has_method("unfreeze_ore"):
			col.unfreeze_ore()

func spawn_particles() -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.lifetime = 0.4
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(8, 8)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 50)
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 60.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	
	var p_color = Color(0.4, 0.4, 0.45, 1)
	if is_unbreakable:
		if biome == 1: p_color = Color(0.68, 0.88, 1.0, 1)
		elif biome == 2: p_color = Color(1.0, 0.42, 0.2, 1)
		else: p_color = Color(0.85, 0.9, 1.0, 1)
	elif is_copper:
		p_color = Color(0.95, 0.82, 0.25, 1) # Gold color
	elif is_coal:
		p_color = Color(0.18, 0.18, 0.2, 1) # Charcoal black
	elif is_dirt:
		if biome == 1: p_color = Color(0.45, 0.65, 0.85, 1)
		elif biome == 2: p_color = Color(0.55, 0.28, 0.2, 1)
		else: p_color = Color(0.5, 0.35, 0.2, 1)
	elif is_stone:
		if biome == 1: p_color = Color(0.65, 0.85, 1.0, 1)
		elif biome == 2: p_color = Color(0.85, 0.45, 0.3, 1)
		else: p_color = Color(0.6, 0.6, 0.65, 1)
	else:
		if biome == 1: p_color = Color(0.65, 0.85, 1.0, 1)
		elif biome == 2: p_color = Color(1.0, 0.5, 0.25, 1)
		else: p_color = Color(0.7, 0.7, 0.75, 1)
	particles.color = p_color
	
	particles.global_position = global_position
	get_parent().add_child(particles)
	particles.emitting = true
	
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(particles.queue_free)
	particles.add_child(timer)
	timer.start()

func _on_cracks_draw() -> void:
	if hp >= max_hp: return
	var ratio = float(hp) / float(max_hp)
	var crack_color = Color(0.1, 0.1, 0.1, 0.9)
	
	if ratio <= 0.67:
		cracks.draw_line(Vector2(-6, -6), Vector2(-1, 0), crack_color, 1.5)
		cracks.draw_line(Vector2(-1, 0), Vector2(-3, 4), crack_color, 1.5)
	if ratio <= 0.34:
		cracks.draw_line(Vector2(6, -4), Vector2(1, 1), crack_color, 1.5)
		cracks.draw_line(Vector2(1, 1), Vector2(4, 5), crack_color, 1.5)
		cracks.draw_line(Vector2(-1, 0), Vector2(2, -2), crack_color, 1.5)

func _on_health_bar_draw() -> void:
	if not health_bar: return
	var w = 30.0
	var h = 5.0
	var ratio = clamp(float(hp) / float(max_hp), 0.0, 1.0)
	health_bar.draw_rect(Rect2(-w / 2.0, -h / 2.0, w, h), Color(0.0, 0.0, 0.0, 0.75))
	var bar_color = Color(0.35, 0.9, 0.4)
	if ratio <= 0.67: bar_color = Color(0.95, 0.8, 0.2)
	if ratio <= 0.34: bar_color = Color(0.9, 0.25, 0.25)
	health_bar.draw_rect(Rect2(-w / 2.0 + 1, -h / 2.0 + 1, (w - 2.0) * ratio, h - 2.0), bar_color)

func _process(delta: float) -> void:
	if is_shining and not is_dirt and not is_coal and hp > 0:
		shine_timer -= delta
		if shine_timer <= 0.0:
			shine_timer = randf_range(1.0, 1.8)
			_trigger_sparkle()

func _trigger_sparkle() -> void:
	if not sprite_2d: return
	var flash_color = Color(1.8, 1.6, 0.9, 1.0) if is_copper else Color(1.4, 1.5, 1.7, 1.0)
	var tween = create_tween()
	tween.tween_property(sprite_2d, "modulate", flash_color, 0.15)
	tween.tween_property(sprite_2d, "modulate", Color(1, 1, 1, 1), 0.25)
	
	if sparkle_overlay:
		sparkle_alpha = 1.0
		sparkle_overlay.queue_redraw()
		var s_tween = create_tween()
		s_tween.tween_property(self, "sparkle_alpha", 0.0, 0.35)
		s_tween.tween_callback(sparkle_overlay.queue_redraw)

func _on_sparkle_draw() -> void:
	if sparkle_alpha <= 0.01: return
	var col = Color(1.0, 0.9, 0.3, sparkle_alpha) if is_copper else Color(0.9, 0.95, 1.0, sparkle_alpha)
	for pt in sparkle_points:
		sparkle_overlay.draw_line(pt - Vector2(3, 0), pt + Vector2(3, 0), col, 1.5)
		sparkle_overlay.draw_line(pt - Vector2(0, 3), pt + Vector2(0, 3), col, 1.5)
		sparkle_overlay.draw_rect(Rect2(pt - Vector2(1, 1), Vector2(2, 2)), Color(1, 1, 1, sparkle_alpha))

func set_illuminated(active: bool, source: Node2D) -> void:
	if active:
		if not light_sources.has(source):
			light_sources.append(source)
	else:
		light_sources.erase(source)
		
	var should_shine = (!light_sources.is_empty()) and (!is_dirt) and (!is_coal)
	if should_shine != is_shining:
		is_shining = should_shine
		set_process(is_shining)
		if not is_shining:
			sparkle_alpha = 0.0
			if sparkle_overlay: sparkle_overlay.queue_redraw()
			if sprite_2d and hp > 0:
				sprite_2d.modulate = Color(1, 1, 1, 1)
		else:
			_trigger_sparkle()
