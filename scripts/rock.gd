class_name Rock
extends RigidBody2D

@export var is_copper: bool = false
@export var is_dirt: bool = false

var max_hp: int = 3
var hp: int = 3

@onready var sprite_2d: Sprite2D = $Sprite2D
const DROP_SCENE = preload("res://scenes/items/resource_drop.tscn")
var cracks: Node2D

func _ready() -> void:
	if is_dirt:
		max_hp = 1
		hp = 1
		if sprite_2d:
			sprite_2d.frame = 1 # Generic block
			sprite_2d.modulate = Color(0.5, 0.35, 0.2, 1.0) # Brown tint for dirt
	elif is_copper:
		max_hp = 4
		hp = 4
		if sprite_2d:
			sprite_2d.frame = 2 # Row 1 Col 3 (Copper ore)
	else:
		max_hp = 3
		hp = 3
		if sprite_2d:
			sprite_2d.frame = 1 # Row 1 Col 2 (Stone/Iron ore)
			
	# Setup node to draw cracks over the rock
	cracks = Node2D.new()
	cracks.name = "Cracks"
	cracks.z_index = 1
	add_child(cracks)
	cracks.draw.connect(_on_cracks_draw)
	
	lock_rotation = true
	mass = 100.0 # Heavy so player doesn't push it easily
	
	if is_dirt:
		freeze = true
		freeze_mode = RigidBody2D.FREEZE_MODE_STATIC

func hit() -> void:
	if hp <= 0: return
	
	hp -= 1
	cracks.queue_redraw()
	
	if sprite_2d:
		sprite_2d.modulate = sprite_2d.modulate + Color(0.5, 0, 0, 0) # Flash reddish
		var original_color = Color(0.5, 0.35, 0.2, 1.0) if is_dirt else Color(1, 1, 1, 1)
		var tween = create_tween()
		tween.tween_property(sprite_2d, "modulate", original_color, 0.15)
		
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
	spawn_particles()
	
	if not is_dirt:
		var drop = DROP_SCENE.instantiate()
		drop.type = 1 if is_copper else 0
		drop.global_position = global_position
		get_parent().add_child(drop)
	
	queue_free()

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
	if is_copper: p_color = Color(0.9, 0.8, 0.2, 1) # Gold color
	if is_dirt: p_color = Color(0.5, 0.35, 0.2, 1)
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
