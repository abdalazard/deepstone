extends Node2D

const ROCK_SCENE = preload("res://scenes/cave/rock.tscn")
const DIRT_SCENE = preload("res://scenes/cave/dirt.tscn")
const TORCH_SCENE = preload("res://scenes/environment/torch.tscn")

func _ready() -> void:
	generate_world()

func generate_world() -> void:
	# 30 columns x 50 rows of dirt/rocks
	for x in range(30):
		for y in range(50):
			var tile_pos = Vector2(x * 16 + 8, y * 16 + 128)
			
			# Don't place blocks in the elevator shaft (column 15)
			if x == 15:
				continue
				
			var instance
			if randf() > 0.7:
				instance = ROCK_SCENE.instantiate()
				if randf() > 0.8:
					instance.is_copper = true # It's GOLD now
			else:
				instance = DIRT_SCENE.instantiate()
				
			instance.position = tile_pos
			add_child(instance)
