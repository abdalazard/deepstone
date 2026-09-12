extends Area2D

@export var max_hp: int = 3
var hp: int = 3
var is_falling: bool = false
var is_stump: bool = false
var regrow_time_left: float = 0.0
const REGROW_DURATION: float = 120.0 # 2 minutos para crescer

@onready var sprite: Sprite2D = $Sprite2D
@onready var stump_sprite: Sprite2D = get_node_or_null("StumpSprite")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	hp = max_hp
	collision_layer = 1
	collision_mask = 0
	if stump_sprite:
		stump_sprite.visible = false
	if sprite:
		sprite.visible = true
		sprite.rotation = 0.0
		sprite.modulate = Color.WHITE

func _process(delta: float) -> void:
	if is_stump:
		regrow_time_left -= delta
		if regrow_time_left <= 0.0:
			regrow()

func hit() -> void:
	if is_falling or is_stump or hp <= 0:
		return
	hp -= 1
	
	# Shake effect
	if sprite:
		var tween = create_tween()
		sprite.position = Vector2(randf_range(-3, 3), -36)
		tween.tween_property(sprite, "position", Vector2(0, -36), 0.12)
		sprite.modulate = Color(1.4, 1.2, 0.8, 1.0)
		tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.15)
		
	_spawn_leaf_particles()
	
	if hp <= 0:
		fell_tree()

func fell_tree() -> void:
	is_falling = true
	is_stump = true
	regrow_time_left = REGROW_DURATION
	if stump_sprite:
		stump_sprite.visible = true
	if collision_shape:
		collision_shape.disabled = true
		
	var inv = _get_inv()
	if inv and inv.has_method("add_wood"):
		inv.add_wood(10)
	elif inv and "wood_logs" in inv:
		inv.wood_logs += 10
		if inv.has_method("notify"):
			inv.notify("+10 Troncos de Madeira!", "wood")
		inv.inventory_changed.emit()
		
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "rotation", 1.4, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.35)
		tween.finished.connect(func():
			is_falling = false
			if sprite:
				sprite.visible = false
		)
	else:
		is_falling = false

func regrow() -> void:
	is_stump = false
	is_falling = false
	hp = max_hp
	if stump_sprite:
		stump_sprite.visible = false
	if sprite:
		sprite.visible = true
		sprite.rotation = 0.0
		sprite.modulate = Color.WHITE
		sprite.modulate.a = 0.0
		sprite.scale = Vector2(0.3, 0.3)
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(sprite, "modulate:a", 1.0, 0.4)
	if collision_shape:
		collision_shape.disabled = false
	_spawn_leaf_particles()
	var inv = _get_inv()
	if inv and inv.has_method("notify"):
		inv.notify("Árvore cresceu novamente!", "wood")

func _spawn_leaf_particles() -> void:
	if not is_inside_tree() or not get_parent(): return
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.lifetime = 0.5
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(16, 24)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 80)
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 50.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(0.3, 0.7, 0.25, 1)
	particles.global_position = global_position - Vector2(0, 32)
	get_parent().add_child(particles)
	particles.emitting = true
	if get_tree():
		get_tree().create_timer(0.6).timeout.connect(particles.queue_free)

func _get_inv() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("Inventory"):
		return get_tree().root.get_node("Inventory")
	return null
