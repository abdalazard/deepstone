extends RigidBody2D

const MAX_CAPACITY: int = 50
var stored_load: int = 0
var is_closed: bool = false

@onready var sprite = $Sprite2D
@onready var interact_area = $InteractArea

func _ready() -> void:
	# 32 = Open, 30 = Closed in extras.png (assuming 11x11 grid)
	sprite.frame = 32

var in_ladder: bool = false
var gravity_scale_default: float = 1.0

func _physics_process(delta: float) -> void:
	if in_ladder and is_closed:
		gravity_scale = 0.0
		linear_velocity.y = move_toward(linear_velocity.y, 0, 10)
		
		# Check surface extraction
		if global_position.y < 120:
			extract()
	else:
		gravity_scale = gravity_scale_default

func deposit(items: Dictionary) -> void:
	if is_closed: return
	
	var total_weight = items["iron"] * 1 + items["gold"] * 2
	stored_load += total_weight
	
	if stored_load >= MAX_CAPACITY:
		close_chest()

func close_chest() -> void:
	is_closed = true
	sprite.frame = 30 # Closed chest
	mass = 50.0 # Make it heavy!
	
	# Add a physical collision so it can be pushed by X
	collision_mask = 3 # Collides with player(2) and world(1)
	
	# Light effect when closed
	var flash = PointLight2D.new()
	flash.color = Color(0.2, 1.0, 0.4, 1.0)
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
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "scale", Vector2(2.0, 2.0), 0.5)
	tween.parallel().tween_property(flash, "energy", 0.0, 0.5)
	tween.finished.connect(flash.queue_free)

func extract() -> void:
	if is_closed:
		# Player gains EXP
		print("Chest extracted! Gained EXP based on load: ", stored_load)
		# Future: Add EXP to player stats
		queue_free()

func is_chest() -> bool:
	return true
