extends RigidBody2D

enum ResourceType { IRON, GOLD, COAL, PLANK, LAMP }
@export var type: ResourceType = ResourceType.IRON
var is_player_drop: bool = false
var pickup_delay: float = 0.0
var inventory_override: Node = null

func _ready() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		if type == ResourceType.IRON:
			var atlas = AtlasTexture.new()
			atlas.atlas = load("res://assets/Caves and Mines/ores.png")
			atlas.region = Rect2(32, 128, 16, 16)
			sprite.texture = atlas
			sprite.hframes = 1
			sprite.vframes = 1
			sprite.frame = 0
			sprite.scale = Vector2(1.2, 1.2)
			sprite.modulate = Color(1, 1, 1, 1)
		elif type == ResourceType.GOLD:
			var atlas = AtlasTexture.new()
			atlas.atlas = load("res://assets/Caves and Mines/ores.png")
			atlas.region = Rect2(128, 128, 16, 16)
			sprite.texture = atlas
			sprite.hframes = 1
			sprite.vframes = 1
			sprite.frame = 0
			sprite.scale = Vector2(1.2, 1.2)
			sprite.modulate = Color(1, 1, 1, 1)
		elif type == ResourceType.COAL:
			var atlas = AtlasTexture.new()
			atlas.atlas = load("res://assets/Caves and Mines/ores.png")
			atlas.region = Rect2(0, 128, 16, 16)
			sprite.texture = atlas
			sprite.hframes = 1
			sprite.vframes = 1
			sprite.frame = 0
			sprite.scale = Vector2(1.2, 1.2)
			sprite.modulate = Color(1, 1, 1, 1)
		elif type == ResourceType.PLANK:
			sprite.texture = load("res://assets/sprites/plank.png")
			sprite.hframes = 1
			sprite.vframes = 1
			sprite.frame = 0
			sprite.scale = Vector2(0.8, 0.8)
		elif type == ResourceType.LAMP:
			sprite.texture = load("res://assets/sprites/lamp_post.png")
			sprite.hframes = 4
			sprite.vframes = 1
			sprite.frame = 0
			sprite.scale = Vector2(1.2, 1.2)
		
	# Pop out effect
	apply_impulse(Vector2(randf_range(-50, 50), randf_range(-150, -50)))
	
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BOUNCE)
	
	if is_player_drop:
		pickup_delay = 1.2
	else:
		# Auto collect for basic mined ores
		var timer = Timer.new()
		timer.wait_time = 0.3
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

var target_player: Node2D = null

func _get_inv() -> Node:
	if inventory_override:
		return inventory_override
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("Inventory"):
		return get_tree().root.get_node("Inventory")
	var loop = Engine.get_main_loop()
	if loop and "root" in loop and loop.root and loop.root.has_node("Inventory"):
		return loop.root.get_node("Inventory")
	return null

func _can_be_collected() -> bool:
	if pickup_delay > 0.0:
		return false
	var inv = _get_inv()
	if not inv: return false
	if type == ResourceType.IRON:
		return inv.can_add(0)
	elif type == ResourceType.GOLD:
		return inv.can_add(1)
	elif type == ResourceType.COAL:
		return inv.can_add(2)
	elif type == ResourceType.PLANK:
		return inv.planks < 99
	elif type == ResourceType.LAMP:
		return inv.signs < 99
	return false

func _auto_fly_to_player() -> void:
	if not _can_be_collected():
		return # Inventory full or cannot receive this item! Stay at rest where mined.
	var tree = get_tree()
	if not tree: return
	var parent_node = tree.current_scene if tree.current_scene else tree.root
	target_player = parent_node.get_node_or_null("Player") if parent_node else null
	if not target_player: return
	
	set_deferred("freeze", true)
	if has_node("CollisionShape2D"):
		get_node("CollisionShape2D").set_deferred("disabled", true)

func _process(delta: float) -> void:
	if pickup_delay > 0.0:
		pickup_delay -= delta
	if target_player:
		if not _can_be_collected():
			# Abort flight if inventory filled up while flying!
			target_player = null
			set_deferred("freeze", false)
			if has_node("CollisionShape2D"):
				get_node("CollisionShape2D").set_deferred("disabled", false)
			return
		global_position = global_position.lerp(target_player.global_position, 10.0 * delta)
		if global_position.distance_to(target_player.global_position) < 8.0:
			collect()
			target_player = null

func collect() -> void:
	if not _can_be_collected(): return
	var inv = _get_inv()
	if not inv:
		queue_free()
		return
		
	if type in [ResourceType.IRON, ResourceType.GOLD, ResourceType.COAL]:
		inv.add_resource(type, 1)
	elif type == ResourceType.PLANK:
		inv.planks = min(inv.planks + 1, 99)
		inv.notify("+1 Tábua", "plank")
		inv.inventory_changed.emit()
	elif type == ResourceType.LAMP:
		if "starter_lamps" in inv:
			inv.add_starter_lamp(1)
		else:
			inv.signs = min(inv.signs + 1, 99)
		inv.notify("+1 Lanterna", "lamp")
		inv.inventory_changed.emit()
	
	# Create light flash effect
	var flash = PointLight2D.new()
	var flash_col = Color(1.0, 0.8, 0.2, 1.0)
	if type == ResourceType.COAL: flash_col = Color(0.6, 0.6, 0.7, 1.0)
	elif type == ResourceType.PLANK: flash_col = Color(0.7, 0.5, 0.3, 1.0)
	flash.color = flash_col
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
