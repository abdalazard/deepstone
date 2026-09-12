extends Node2D

const ROCK_SCENE = preload("res://scenes/cave/rock.tscn")
const DIRT_SCENE = preload("res://scenes/cave/dirt.tscn")
const CONCRETE_SCENE = preload("res://scenes/cave/concrete.tscn")
const GRASS_SCENE = preload("res://scenes/cave/grass.tscn")
const GRASS_DIRT_SCENE = preload("res://scenes/cave/grass_dirt.tscn")
const TORCH_SCENE = preload("res://scenes/environment/torch.tscn")
const ROPE_SCENE = preload("res://scenes/environment/rope_segment.tscn")
const SIGNPOST_SCENE = preload("res://scenes/environment/signpost.tscn")
const UNBREAKABLE_SCENE = preload("res://scenes/cave/unbreakable_rock.tscn")
const PLANK_SCENE = preload("res://scenes/environment/plank.tscn")

@onready var player = $Player

var sky_color: Color = Color(0.4, 0.65, 0.9, 1.0)
var cave_color: Color = Color(0.005, 0.105, 0.21, 1.0) # #011B35

func _ready() -> void:
	if has_node("/root/SaveManager"):
		seed(SaveManager.world_seed)
	
	# Spawn signpost AFTER entrance hole (column 18, X = 592, Y = 96)
	var sign = SIGNPOST_SCENE.instantiate()
	sign.position = Vector2(592, 96)
	add_child(sign)
	
	generate_world()
	restore_placed_items()

func _process(delta: float) -> void:
	if is_instance_valid(player):
		# When player enters excavation (Y >= 120), background turns to dark blue
		var target_color = cave_color if player.global_position.y >= 120.0 else sky_color
		var current_color = RenderingServer.get_default_clear_color()
		RenderingServer.set_default_clear_color(current_color.lerp(target_color, 4.0 * delta))

func restore_placed_items() -> void:
	if not has_node("/root/SaveManager"): return
	
	for t in SaveManager.placed_torches_data:
		var torch = TORCH_SCENE.instantiate()
		torch.position = Vector2(t.x, t.y)
		torch.add_to_group("placed_torches")
		add_child(torch)
		
	for r in SaveManager.placed_ropes_data:
		var rope = ROPE_SCENE.instantiate()
		rope.position = Vector2(r.x, r.y)
		rope.add_to_group("placed_ropes")
		add_child(rope)

	for p in SaveManager.placed_planks_data:
		var plank = PLANK_SCENE.instantiate()
		plank.position = Vector2(p.x, p.y)
		plank.add_to_group("placed_planks")
		add_child(plank)

func generate_world() -> void:
	const GRID_W = 30
	const GRID_H = 50
	
	# Procedural natural subterranean caverns / empty cave pockets (depths 4 to 48)
	var cave_chambers = []
	var depth_zones = [
		Vector2i(4, 5),
		Vector2i(8, 10),
		Vector2i(13, 15),
		Vector2i(18, 20),
		Vector2i(23, 25),
		Vector2i(32, 35),
		Vector2i(42, 45)
	]
	for zone in depth_zones:
		var cx = randi_range(3, GRID_W - 4)
		var cy = randi_range(zone.x, zone.y)
		var rx = randf_range(2.0, 3.8)
		var ry = randf_range(1.5, 2.8)
		cave_chambers.append({"center": Vector2(cx, cy), "rx": rx, "ry": ry})
	
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
			var grid_coord = Vector2i(x, y)
			
			# Check if already mined in saved game
			if has_node("/root/SaveManager") and SaveManager.is_block_mined(grid_coord):
				continue
			
			# Check if tile falls within a natural empty cavern chamber (no lamps, dark air)
			var in_natural_cave = false
			if y >= 3 and x > 0 and x < GRID_W - 1 and not unbreakable_blocks.has(grid_coord):
				for chamber in cave_chambers:
					var dx = (x - chamber.center.x) / chamber.rx
					var dy = (y - chamber.center.y) / chamber.ry
					var dist = dx * dx + dy * dy
					var jitter = sin(x * 2.5 + y * 3.1) * 0.15
					if dist + jitter < 1.0:
						in_natural_cave = true
						break
			
			if in_natural_cave:
				# Natural empty cavern chamber: leave as dark air (enemies spawn here in future)
				continue
			
			var tile_pos = Vector2(x * 32 + 16, y * 32 + 128)
			var instance: Node2D
			
			# Surface (y == 0) is lush lawn, with only column 17 as breakable entrance dirt
			if y == 0:
				if x == 17:
					instance = GRASS_DIRT_SCENE.instantiate()
				else:
					instance = GRASS_SCENE.instantiate()
			elif unbreakable_blocks.has(grid_coord):
				instance = UNBREAKABLE_SCENE.instantiate()
			else:
				var ore_roll = randf()
				# Abundance hierarchy: Carvão (Coal) > Ferro (Iron) > Ouro (Gold)
				var gold_thresh = 0.88 if y < 25 else 0.84
				var iron_thresh = 0.70
				var coal_thresh = 0.44
				
				if ore_roll > gold_thresh:
					var rock = ROCK_SCENE.instantiate()
					rock.is_copper = true # Gold ore (rarest: ~15%)
					instance = rock
				elif ore_roll > iron_thresh:
					var rock = ROCK_SCENE.instantiate()
					rock.is_copper = false
					rock.is_coal = false # Iron ore (intermediate: ~33%)
					instance = rock
				elif ore_roll > coal_thresh:
					var rock = ROCK_SCENE.instantiate()
					rock.is_copper = false
					rock.is_coal = true # Coal ore (most abundant: ~52%)
					instance = rock
				else:
					instance = DIRT_SCENE.instantiate()
			
			instance.position = tile_pos
			if instance.has_method("set_grid_pos"):
				instance.set_grid_pos(grid_coord)
			elif "grid_pos" in instance:
				instance.grid_pos = grid_coord
			add_child(instance)
