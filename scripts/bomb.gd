extends RigidBody2D

var fuse_time: float = 1.5
var timer: float = 0.0
var has_exploded: bool = false
@export var blast_radius: float = 72.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	
	# Small initial toss impulse based on player direction
	var tree = get_tree() if is_inside_tree() else null
	var player = tree.current_scene.get_node_or_null("Player") if (tree and tree.current_scene) else null
	var dir_x = player.facing_x if (is_instance_valid(player) and "facing_x" in player) else 1.0
	apply_central_impulse(Vector2(dir_x * 80.0, -90.0))
	
	# Fuse pulse tween
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "modulate", Color(2.0, 0.4, 0.4, 1.0), 0.15)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func _process(delta: float) -> void:
	if has_exploded: return
	timer += delta
	if timer >= fuse_time:
		explode()

func explode() -> void:
	if has_exploded: return
	has_exploded = true
	
	var cur_scene = get_tree().current_scene if (get_tree() and get_tree().current_scene) else null
	var center = global_position
	
	# Physical overlap query for blocks
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = blast_radius
	query.shape = circle
	query.transform = Transform2D(0, center)
	query.collision_mask = 1 # Solid terrain layer
	
	var results = space.intersect_shape(query, 64)
	for r in results:
		var collider = r.collider
		if is_instance_valid(collider):
			if collider.has_method("destroy"):
				collider.destroy()
			elif collider.has_method("hit"):
				collider.hit()
				if is_instance_valid(collider) and collider.has_method("hit"):
					collider.hit()
				if is_instance_valid(collider) and collider.has_method("destroy"):
					collider.destroy()
					
	# Visual Explosion Particles
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 40
	particles.lifetime = 0.6
	particles.spread = 180.0
	particles.gravity = Vector2(0, 80)
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 140.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color = Color(1.0, 0.5, 0.1, 1.0)
	particles.global_position = center
	if is_instance_valid(cur_scene):
		cur_scene.add_child(particles)
		
	# Light flash
	var light = PointLight2D.new()
	light.color = Color(1.0, 0.7, 0.2, 1.0)
	light.energy = 3.0
	light.texture = preload("res://assets/sprites/world/lamp_post.png")
	light.texture_scale = 8.0
	light.global_position = center
	if is_instance_valid(cur_scene):
		cur_scene.add_child(light)
		var ltween = cur_scene.create_tween()
		ltween.tween_property(light, "energy", 0.0, 0.35)
		ltween.tween_callback(func(): light.queue_free())
		
	# Self clean up
	queue_free()
