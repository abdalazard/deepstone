extends Node2D

const ROCK_SCENE = preload("res://scenes/cave/rock.tscn")
const DIRT_SCENE = preload("res://scenes/cave/dirt.tscn")
const CONCRETE_SCENE = preload("res://scenes/cave/concrete.tscn")
const TORCH_SCENE = preload("res://scenes/environment/torch.tscn")

const UNBREAKABLE_SCENE = preload("res://scenes/cave/unbreakable_rock.tscn")

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
	const GRID_W = 30
	const GRID_H = 50
	
	# Dictionary of coordinates (Vector2i) reserved for unbreakable labyrinth blocks
	var unbreakable_blocks = {}
	
	# Horizontal barrier shelves at regular depth intervals
	var shelves = [6, 11, 16, 21, 26, 31, 36, 41, 46]
	for i in range(shelves.size()):
		var s = shelves[i]
		# 2-3 randomized passage gates (2 blocks wide each) on each shelf
		var g1 = randi_range(2, 8)
		var g2 = randi_range(11, 18)
		var g3 = randi_range(21, 27)
		var gate_cols = [g1, g1 + 1, g2, g2 + 1, g3, g3 + 1]
		
		for x in range(GRID_W):
			if not (x in gate_cols):
				unbreakable_blocks[Vector2i(x, s)] = true
		
		# Vertical labyrinth baffles between shelves
		var y_start = 2 if i == 0 else shelves[i - 1] + 1
		var y_end = s - 1
		if y_end >= y_start:
			var vx1 = randi_range(5, 11)
			var vx2 = randi_range(18, 24)
			for vx in [vx1, vx2]:
				var gap_y = randi_range(y_start, y_end)
				for y in range(y_start, y_end + 1):
					if y != gap_y:
						unbreakable_blocks[Vector2i(vx, y)] = true
	
	# Scattered natural unbreakable clusters / obstacles (organic maze features)
	for y in range(2, GRID_H):
		for x in range(GRID_W):
			var pos = Vector2i(x, y)
			if not unbreakable_blocks.has(pos) and randf() < 0.035:
				unbreakable_blocks[pos] = true

	# Instantiate blocks
	for x in range(GRID_W):
		for y in range(GRID_H):
			var tile_pos = Vector2(x * 32 + 16, y * 32 + 128)
			var instance: Node2D
			
			# Surface is all concrete with only 1 dirt block for entrance at column 17
			if y == 0:
				if x == 17:
					instance = DIRT_SCENE.instantiate()
				else:
					instance = CONCRETE_SCENE.instantiate()
			elif unbreakable_blocks.has(Vector2i(x, y)):
				instance = UNBREAKABLE_SCENE.instantiate()
			else:
				var ore_roll = randf()
				var gold_thresh = 0.85 if y < 25 else 0.75
				var iron_thresh = 0.65
				
				if ore_roll > gold_thresh:
					var rock = ROCK_SCENE.instantiate()
					rock.is_copper = true # Gold ore
					instance = rock
				elif ore_roll > iron_thresh:
					var rock = ROCK_SCENE.instantiate()
					rock.is_copper = false # Iron ore
					instance = rock
				else:
					instance = DIRT_SCENE.instantiate()
			
			instance.position = tile_pos
			add_child(instance)
