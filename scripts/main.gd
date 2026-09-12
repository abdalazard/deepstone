extends Node2D

const ROCK_SCENE = preload("res://scenes/cave/rock.tscn")
const DIRT_SCENE = preload("res://scenes/cave/dirt.tscn")
const CONCRETE_SCENE = preload("res://scenes/cave/concrete.tscn")
const TORCH_SCENE = preload("res://scenes/environment/torch.tscn")

func _ready() -> void:
	generate_world()

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
