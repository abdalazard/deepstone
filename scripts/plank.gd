extends StaticBody2D

var hp: int = 1

func _ready() -> void:
	add_to_group("placed_planks")

func hit() -> void:
	hp -= 1
	if hp <= 0:
		break_plank()

func collect() -> void:
	break_plank()

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

func break_plank() -> void:
	var inv = _get_inv()
	if inv:
		inv.planks = min(inv.planks + 1, 99)
		inv.inventory_changed.emit()
		inv.notify("+1 Tábua", "plank")
	
	# Spawn particles
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.lifetime = 0.35
	particles.spread = 180.0
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 50.0
	particles.color = Color(0.65, 0.45, 0.25, 1.0)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 3.5
	particles.global_position = global_position
	get_parent().add_child(particles)
	particles.emitting = true
	
	var timer = Timer.new()
	timer.wait_time = 0.8
	timer.one_shot = true
	timer.timeout.connect(particles.queue_free)
	particles.add_child(timer)
	timer.start()
	
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("SaveManager"):
		get_tree().root.get_node("SaveManager").request_save()
		
	queue_free()
