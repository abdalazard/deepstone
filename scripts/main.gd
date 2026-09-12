extends Node2D

const ROCK_SCENE = preload("res://scenes/cave/rock.tscn")
const DIRT_SCENE = preload("res://scenes/cave/dirt.tscn")
const CONCRETE_SCENE = preload("res://scenes/cave/concrete.tscn")
const TORCH_SCENE = preload("res://scenes/environment/torch.tscn")

@onready var player = $Player

var sky_color: Color = Color(0.4, 0.65, 0.9, 1.0)
var cave_color: Color = Color(0.005, 0.105, 0.21, 1.0) # #011B35

func _ready() -> void:
	generate_world()

func _process(delta: float) -> void:
	if is_instance_valid(player):
		# When player enters excavation (Y >= 120), background turns to dark blue
		var target_color = cave_color if player.global_position.y >= 120.0 else sky_color
		var current_color = RenderingServer.get_default_clear_color()
		RenderingServer.set_default_clear_color(current_color.lerp(target_color, 4.0 * delta))

func generate_world() -> void:
	# 30 columns x 50 rows of dirt/rocks
	for x in range(30):
		for y in range(50):
			var tile_pos = Vector2(x * 32 + 16, y * 32 + 128)
				
			var instance
			
			# Create a 3-block wide concrete platform for the chest at the surface (y=0)
			if y == 0 and x in [14, 15, 16]:
				instance = CONCRETE_SCENE.instantiate()
			elif randf() > 0.7:
				instance = ROCK_SCENE.instantiate()
				if randf() > 0.8:
					instance.is_copper = true # It's GOLD now
			else:
				instance = DIRT_SCENE.instantiate()
				
			instance.position = tile_pos
			add_child(instance)
