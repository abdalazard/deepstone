extends RigidBody2D

enum ResourceType { STONE, COPPER }
@export var type: ResourceType = ResourceType.STONE

func _ready() -> void:
	var sprite = $Sprite2D
	if type == ResourceType.STONE:
		sprite.frame = 24 # Row 5 Col 1 (stone/coal lump)
	else:
		sprite.frame = 26 # Row 5 Col 3 (copper ingot)
		
	# Pop out effect
	apply_impulse(Vector2(randf_range(-50, 50), randf_range(-150, -50)))
	
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BOUNCE)
	
	# Auto collect for basic ores (Stone, Copper)
	# Future ores like Gold will skip this to force manual hauling
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(_auto_fly_to_player)
	add_child(timer)
	timer.start()
	
	# Add area for auto-pickup (when player presses C)
	var pickup_area = Area2D.new()
	pickup_area.collision_layer = 0
	pickup_area.collision_mask = 2 # Player layer
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	collision.shape = shape
	pickup_area.add_child(collision)
	
	add_child(pickup_area)

func _auto_fly_to_player() -> void:
	var player = get_tree().current_scene.get_node_or_null("Player")
	if not player: return
	
	set_deferred("freeze", true)
	if has_node("CollisionShape2D"):
		get_node("CollisionShape2D").set_deferred("disabled", true)
		
	var tween = create_tween()
	tween.tween_property(self, "global_position", player.global_position, 0.4).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.finished.connect(collect)

func collect() -> void:
	Inventory.add_resource(type, 1)
	
	# Create light flash effect
	var flash = PointLight2D.new()
	flash.color = Color(1.0, 0.8, 0.2, 1.0) # Golden flash
	flash.energy = 2.0
	
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(1,1,1,1), Color(0,0,0,1)])
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.8, 0.2)
	tex.width = 64
	tex.height = 64
	flash.texture = tex
	
	flash.global_position = global_position
	get_tree().current_scene.add_child(flash)
	
	var tween = get_tree().create_tween()
	tween.tween_property(flash, "scale", Vector2(3.0, 3.0), 0.2)
	tween.parallel().tween_property(flash, "energy", 0.0, 0.2)
	tween.finished.connect(flash.queue_free)
	
	queue_free()

func is_resource() -> bool:
	return true
