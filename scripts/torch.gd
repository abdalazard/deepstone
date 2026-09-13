extends Area2D

var target_player: Node2D = null
var velocity_y: float = 0.0
var is_falling: bool = false
var illuminated_ores: Array = []

@onready var light_area = $LightArea

func _ready() -> void:
	if light_area:
		if not light_area.body_entered.is_connected(_on_light_area_body_entered):
			light_area.body_entered.connect(_on_light_area_body_entered)
		if not light_area.body_exited.is_connected(_on_light_area_body_exited):
			light_area.body_exited.connect(_on_light_area_body_exited)
		# Defer checking initial overlapping bodies so tree is fully populated
		call_deferred("_check_initial_overlaps")

func _check_initial_overlaps() -> void:
	if light_area:
		for body in light_area.get_overlapping_bodies():
			_on_light_area_body_entered(body)

func _on_light_area_body_entered(body: Node2D) -> void:
	if body.has_method("set_illuminated"):
		body.set_illuminated(true, self)
		if not illuminated_ores.has(body):
			illuminated_ores.append(body)

func _on_light_area_body_exited(body: Node2D) -> void:
	if body.has_method("set_illuminated"):
		body.set_illuminated(false, self)
		illuminated_ores.erase(body)

func _exit_tree() -> void:
	for ore in illuminated_ores:
		if is_instance_valid(ore) and ore.has_method("set_illuminated"):
			ore.set_illuminated(false, self)

var inventory_override: Node = null

func _get_inv() -> Node:
	if inventory_override:
		return inventory_override
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("Inventory"):
		return get_tree().root.get_node("Inventory")
	var loop = Engine.get_main_loop()
	if loop and "root" in loop and loop.root and loop.root.has_node("Inventory"):
		return loop.root.get_node("Inventory")
	return null

func hit() -> void:
	for ore in illuminated_ores:
		if is_instance_valid(ore) and ore.has_method("set_illuminated"):
			ore.set_illuminated(false, self)
	illuminated_ores.clear()
	
	var inv = _get_inv()
	if inv:
		inv.coal = min(inv.coal + 1, inv.get_max_capacity())
		inv.iron = min(inv.iron + 1, inv.get_max_capacity())
		inv.inventory_changed.emit()
		inv.notify("+1 Carvão, +1 Ferro (Poste Desmontado)", "lamp")
	
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("SaveManager"):
		get_tree().root.get_node("SaveManager").request_save()
	
	target_player = get_tree().current_scene.get_node_or_null("Player") if (is_inside_tree() and get_tree() and get_tree().current_scene) else null
	if not target_player:
		queue_free()

var anim_timer: float = 0.0
var anim_frame: int = 0
const ANIM_FPS: float = 6.0

func _process(delta: float) -> void:
	if target_player:
		var sprite = $Sprite2D
		if sprite:
			sprite.global_position = sprite.global_position.lerp(target_player.global_position, 10.0 * delta)
			if sprite.global_position.distance_to(target_player.global_position) < 8.0:
				queue_free()
	else:
		anim_timer += delta
		if anim_timer >= 1.0 / ANIM_FPS:
			anim_timer = 0.0
			anim_frame = (anim_frame + 1) % 4
			if has_node("Sprite2D"):
				$Sprite2D.frame = anim_frame
			if has_node("PointLight2D"):
				$PointLight2D.energy = 1.8 + randf_range(-0.06, 0.06)

var check_support_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if target_player:
		return
		
	if not is_falling:
		check_support_timer -= delta
		if check_support_timer > 0.0:
			return
		check_support_timer = 0.25

	var space_state = get_world_2d().direct_space_state
	# Cast downward to detect supporting block
	var from_pos = global_position + Vector2(0, 10)
	var to_pos = global_position + Vector2(0, 18)
	var query = PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	query.collision_mask = 1 | 32 # Terrain blocks (1) + Planks (32)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	
	var hit_down = space_state.intersect_ray(query)
	if not hit_down:
		# Block underneath is gone, fall down with gravity!
		is_falling = true
		velocity_y += 700.0 * delta
		var step = velocity_y * delta
		
		# Check if we land on anything during this step
		var fall_query = PhysicsRayQueryParameters2D.create(from_pos, from_pos + Vector2(0, step + 8))
		fall_query.collision_mask = 1 | 32 # Terrain blocks (1) + Planks (32)
		fall_query.collide_with_bodies = true
		var hit_fall = space_state.intersect_ray(fall_query)
		if hit_fall:
			global_position.y = hit_fall.position.y - 16.0
			velocity_y = 0.0
			is_falling = false
		else:
			global_position.y += step
	else:
		if is_falling:
			global_position.y = hit_down.position.y - 16.0
			velocity_y = 0.0
			is_falling = false
