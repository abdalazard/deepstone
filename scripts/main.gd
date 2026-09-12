extends Node2D

const ROCK_SCENE = preload("res://scenes/cave/rock.tscn")
const DIRT_SCENE = preload("res://scenes/cave/dirt.tscn")

func _ready() -> void:
	generate_world()

func generate_world() -> void:
	var start_x = 0
	var start_y = 120
	var cols = 30
	var rows = 50
	
	for col in range(cols):
		for row in range(rows):
			var block
			var rand = randf()
			
			if rand < 0.8:
				block = DIRT_SCENE.instantiate()
			else:
				block = ROCK_SCENE.instantiate()
				if rand > 0.95:
					block.is_copper = true
					
			block.global_position = Vector2(start_x + col * 16 + 8, start_y + row * 16 + 8)
			$Cave.add_child(block)
