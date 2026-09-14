extends StaticBody2D

var hp: int = 1

func _ready() -> void:
	add_to_group("placed_planks")

func hit() -> void:
	hp -= 1
	if hp <= 0:
		break_brick()

func collect() -> void:
	break_brick()

func _get_inv() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("Inventory"):
		return get_tree().root.get_node("Inventory")
	return null

func break_brick() -> void:
	var inv = _get_inv()
	if inv:
		inv.stone = min(inv.stone + 1, 99)
		inv.dirt = min(inv.dirt + 1, 99)
		inv.inventory_changed.emit()
		inv.notify("+1 Pedra, +1 Lama", "stone")
	
	# Partículas cinzas
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.lifetime = 0.35
	particles.spread = 180.0
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 50.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 3.5
	particles.color = Color(0.6, 0.55, 0.5, 1.0)
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