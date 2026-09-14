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
const STONE_SCENE = preload("res://scenes/cave/stone.tscn")
const TREE_SCENE = preload("res://scenes/environment/tree.tscn")
const FORGE_SCENE = preload("res://scenes/environment/forge.tscn")
const BUSH_SCENE = preload("res://scenes/environment/bush.tscn")
const RANDOM_ROCK_SCENE = preload("res://scenes/environment/random_rock.tscn")
const DEATH_MARKER_SCENE = preload("res://scenes/markers/death_marker.tscn")

# Músicas por ambiente
var music_earth: AudioStreamMP3 = preload("res://assets/sounds/Valley_of_Singing_Quartz.mp3")
var music_ice: AudioStreamMP3 = preload("res://assets/sounds/Beneath_the_Frost.mp3")
var music_lava: AudioStreamMP3 = preload("res://assets/sounds/Molten_Ascent.mp3")

@onready var player = $Player

var sky_color: Color = Color(0.4, 0.65, 0.9, 1.0)
var earth_cave_color: Color = Color(0.06, 0.05, 0.04, 1.0) # Camada de Terra (Dark earth)
var ice_cave_color: Color = Color(0.02, 0.08, 0.16, 1.0) # Camada de Gelo (Abyssal cold blue)
var lava_cave_color: Color = Color(0.14, 0.03, 0.02, 1.0) # Camada de Lava (Magmatic ember dark)

func _ready() -> void:
	if has_node("/root/SaveManager"):
		seed(SaveManager.world_seed)
	
	# Spawn signpost AFTER entrance hole (column 18, X = 592, Y = 96)
	var sign = SIGNPOST_SCENE.instantiate()
	sign.position = Vector2(592, 96)
	add_child(sign)
	
	generate_world()
	restore_placed_items()
	_setup_subsurface_shade()
	_setup_surface_light()
	_setup_music()

func _process(delta: float) -> void:
	if is_instance_valid(player):
		var target_color: Color
		var py = player.global_position.y
		_update_music(py)
		if py < 120.0:
			target_color = sky_color
		elif py < 1280.0: # Rows 0 to 35: Terra
			target_color = earth_cave_color
		elif py < 2560.0: # Rows 36 to 75: Gelo
			target_color = ice_cave_color
		else: # Rows 76+: Lava
			target_color = lava_cave_color
			
		var dir_light = get_node_or_null("DirectionalLight2D")
		if dir_light:
			# Efeito luz/sombra: acima da superfície há luz; ao entrar no túnel fica escuro
			dir_light.visible = (py < 150.0)

		# Banda de luz que ilumina o gramado da superfície (onde árvores/forja/baú
		# tocam o chão). Só acende enquanto o player está na superfície.
		var surface_light = get_node_or_null("SurfaceLight")
		if surface_light:
			surface_light.visible = (py < 150.0)

		# Na superfície o subsolo fica 100% oculto por uma camada escura (silhueta).
		var shade = get_node_or_null("SubsurfaceShade")
		if shade:
			shade.visible = py < 144.0

		# Dinâmica de descoberta: na superfície a câmera sobe para mostrar mais
		# céu e menos chão; ao descer para o primeiro andar do subsolo ela volta
		# a centralizar o personagem no meio da tela.
		var cam = player.get_node_or_null("Camera2D")
		if cam:
			var target_offset := Vector2.ZERO
			if py < 112.0:
				target_offset.y = -64.0
			cam.offset = cam.offset.lerp(target_offset, minf(1.0, 6.0 * delta))

		var current_color = RenderingServer.get_default_clear_color()
		if not current_color.is_equal_approx(target_color):
			RenderingServer.set_default_clear_color(current_color.lerp(target_color, 4.0 * delta))

# Camada 100% escura que oculta todo o subsolo (y >= 112, abaixo da linha da
# superfície) enquanto o player está na superfície. Fica acima do parallax e do
# fundo da caverna (z = -6) e abaixo dos blocos (z = 0), que continuam visíveis.
func _setup_subsurface_shade() -> void:
	var shade := Polygon2D.new()
	shade.name = "SubsurfaceShade"
	shade.z_index = 2
	shade.color = Color(0, 0, 0, 1)
	# Cobrimos tudo a partir de 144 (abaixo da fileira do gramado), deixando o
	# subsolo como silhueta preta quando o player está na superfície.
	shade.polygon = PackedVector2Array([
		Vector2(-10000, 144),
		Vector2(10000, 144),
		Vector2(10000, 10000),
		Vector2(-10000, 10000),
	])
	shade.visible = false
	add_child(shade)

# Luz em banda que ilumina o gramado da superfície (a linha onde árvores,
# forja e baú tocam o chão). Acende na superfície e apaga ao entrar no túnel.
func _setup_surface_light() -> void:
	var light := PointLight2D.new()
	light.name = "SurfaceLight"
	light.texture = _build_surface_light_texture()
	light.texture_scale = 2.0
	light.position = Vector2(480, 128)
	light.energy = 0.7
	light.color = Color(1.0, 0.99, 0.93)
	light.visible = false
	add_child(light)

func _build_surface_light_texture() -> Texture2D:
	var w := 512
	var h := 96
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var a := 1.0
		if y < 16:
			a = float(y) / 16.0
		elif y > h - 17:
			a = float(h - 1 - y) / 16.0
		for x in range(w):
			var ax := 1.0
			if x < 24:
				ax = float(x) / 24.0
			elif x > w - 25:
				ax = float(w - 1 - x) / 24.0
			img.set_pixel(x, y, Color(1, 1, 1, a * ax))
	return ImageTexture.create_from_image(img)

# ---------------------------------------------------------------------------
# Música por ambiente (fade suave + alerta com o nome da música)
# ---------------------------------------------------------------------------
var music_player: AudioStreamPlayer
var _current_biome_music: int = 0 # 0 terra/superfície, 1 gelo, 2 lava

func _setup_music() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)
	# Loop em todas as músicas (Beneath the Frost e Molten Ascent também)
	music_earth.loop = true
	music_ice.loop = true
	music_lava.loop = true
	music_player.stream = music_earth
	music_player.volume_db = -40.0
	music_player.play()
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -8.0, 1.8)

func _update_music(py: float) -> void:
	var biome := 0
	if py >= 2560.0:
		biome = 2 # Lava
	elif py >= 1280.0:
		biome = 1 # Gelo
	# Superfície e caverna de terra compartilham a mesma música (Valley)
	if biome == _current_biome_music:
		return
	_current_biome_music = biome
	var stream: AudioStream = null
	var label := ""
	match biome:
		1:
			stream = music_ice
			label = "Beneath the Frost"
		2:
			stream = music_lava
			label = "Molten Ascent"
		_:
			stream = music_earth
			label = "Valley of Singing Quartz"
	# Transição suave ao trocar de música/ambiente
	_fade_music_to(stream, label)

func _fade_music_to(stream: AudioStream, label: String) -> void:
	if not is_instance_valid(music_player):
		return
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -50.0, 1.1)
	tween.tween_callback(func():
		if stream == null:
			music_player.stop()
			return
		music_player.stream = stream
		music_player.volume_db = -40.0
		music_player.play()
		var hud = get_node_or_null("HUD")
		if hud and hud.has_method("show_toast"):
			hud.show_toast("🎵 " + label, "wood")
	)
	tween.tween_property(music_player, "volume_db", -8.0, 1.6)

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

	for f in SaveManager.placed_forges_data:
		var forge = FORGE_SCENE.instantiate()
		forge.position = Vector2(f.x, f.y)
		forge.add_to_group("placed_forges")
		add_child(forge)

	for dm in SaveManager.death_markers_data:
		var mark = DEATH_MARKER_SCENE.instantiate()
		mark.death_level = int(dm.get("level", 0))
		mark.position = Vector2(dm.x, dm.y)
		add_child(mark)

func generate_world() -> void:
	const GRID_W = 30
	const GRID_H = 120 # Escavação expandida até profundidade 120 (~3968 pixels)
	
	# Cavernas naturais distribuídas por todas as camadas
	var cave_chambers = []
	var depth_zones = [
		Vector2i(4, 5),
		Vector2i(8, 10),
		Vector2i(13, 15),
		Vector2i(18, 20),
		Vector2i(24, 26),
		Vector2i(31, 33),
		# Bioma Gelo (36 a 75)
		Vector2i(38, 40),
		Vector2i(45, 47),
		Vector2i(53, 55),
		Vector2i(62, 65),
		Vector2i(70, 72),
		# Bioma Lava (76 a 118)
		Vector2i(78, 80),
		Vector2i(87, 89),
		Vector2i(96, 99),
		Vector2i(107, 110)
	]
	for zone in depth_zones:
		var cx = randi_range(3, GRID_W - 4)
		var cy = randi_range(zone.x, zone.y)
		var rx = randf_range(2.0, 3.8)
		var ry = randf_range(1.5, 2.8)
		cave_chambers.append({"center": Vector2(cx, cy), "rx": rx, "ry": ry})
	
	# Dicionário de blocos inquebráveis do labirinto
	var unbreakable_blocks = {}
	# Células vazias por caverna natural / escavação (para decorar sobre bedrock)
	var cave_cells := {}
	var excavated_cells := {}
	
	# Prateleiras de transição e barreiras estruturais
	var shelves = [6, 11, 16, 21, 26, 31, 35, 41, 46, 51, 56, 61, 66, 71, 75, 81, 86, 91, 96, 101, 106, 111, 116]
	for i in range(shelves.size()):
		var s = shelves[i]
		var g1 = randi_range(2, 8)
		var g2 = randi_range(11, 18)
		var g3 = randi_range(21, 27)
		var gate_cols = [g1, g1 + 1, g2, g2 + 1, g3, g3 + 1]
		
		for x in range(GRID_W):
			if not (x in gate_cols):
				unbreakable_blocks[Vector2i(x, s)] = true
		
		# Paredes verticais do labirinto entre prateleiras
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
	
	# Fundo rochoso intransponível (Bedrock floor) no limite inferior (y = 119)
	for x in range(GRID_W):
		unbreakable_blocks[Vector2i(x, 119)] = true
	
	# Obstáculos naturais pontuais
	for y in range(2, GRID_H - 1):
		for x in range(GRID_W):
			var pos = Vector2i(x, y)
			if not unbreakable_blocks.has(pos) and randf() < 0.035:
				unbreakable_blocks[pos] = true

	# Inst instanciação de blocos com biomas
	for x in range(GRID_W):
		for y in range(GRID_H):
			var grid_coord = Vector2i(x, y)
			
			# Classificação do bioma atual
			var current_biome = 0 # 0=Terra
			if y >= 76:
				current_biome = 2 # Lava
			elif y >= 36:
				current_biome = 1 # Gelo
			
			if has_node("/root/SaveManager") and SaveManager.is_block_mined(grid_coord):
				excavated_cells[grid_coord] = true
				continue
			
			# Cavernas naturais escuras
			var in_natural_cave = false
			if y >= 3 and y < 119 and x > 0 and x < GRID_W - 1 and not unbreakable_blocks.has(grid_coord):
				for chamber in cave_chambers:
					var dx = (x - chamber.center.x) / chamber.rx
					var dy = (y - chamber.center.y) / chamber.ry
					var dist = dx * dx + dy * dy
					var jitter = sin(x * 2.5 + y * 3.1) * 0.15
					if dist + jitter < 1.0:
						in_natural_cave = true
						break
			
			if in_natural_cave:
				cave_cells[grid_coord] = true
				continue
			
			var tile_pos = Vector2(x * 32 + 16, y * 32 + 128)
			var instance: Node2D
			
			# Superfície (y == 0) é gramado, com coluna 17 como entrada de terra
			if y == 0:
				if x == 17:
					instance = GRASS_DIRT_SCENE.instantiate()
				else:
					instance = GRASS_SCENE.instantiate()
			elif unbreakable_blocks.has(grid_coord):
				var unbr = UNBREAKABLE_SCENE.instantiate()
				unbr.biome = current_biome
				instance = unbr
			else:
				var ore_roll = randf()
				# Hierarquia estrita: Carvão (muito abundante) > Ferro > Ouro (raro)
				var gold_thresh: float
				var iron_thresh: float
				var coal_thresh: float
				
				if y <= 10:
					gold_thresh = 1.5 # Sem ouro perto da superfície (y <= 10)
					iron_thresh = 0.82 # ~18% ferro
					coal_thresh = 0.38 # ~44% carvão
				elif current_biome == 0: # Terra profunda (y: 11 a 35)
					gold_thresh = 0.99 # ~1.0% ouro (raro e recompensador!)
					iron_thresh = 0.77 # ~22% ferro
					coal_thresh = 0.35 # ~42% carvão
				elif current_biome == 1: # Gelo (y: 36 a 75)
					gold_thresh = 0.975 # ~2.5% ouro
					iron_thresh = 0.725 # ~25% ferro
					coal_thresh = 0.325 # ~40% carvão
				else: # Lava (y: 76 a 120)
					gold_thresh = 0.96 # ~4.0% ouro
					iron_thresh = 0.68 # ~28% ferro
					coal_thresh = 0.32 # ~36% carvão
				
				if ore_roll > gold_thresh:
					var rock = ROCK_SCENE.instantiate()
					rock.is_copper = true # Ouro
					rock.biome = current_biome
					instance = rock
				elif ore_roll > iron_thresh:
					var rock = ROCK_SCENE.instantiate()
					rock.is_copper = false
					rock.is_coal = false # Ferro
					rock.biome = current_biome
					instance = rock
				elif ore_roll > coal_thresh:
					var rock = ROCK_SCENE.instantiate()
					rock.is_copper = false
					rock.is_coal = true # Carvão Mineral
					rock.biome = current_biome
					instance = rock
				else:
					if y >= 1 and y <= 6 and randf() < 0.35:
						var dirt = DIRT_SCENE.instantiate()
						dirt.is_roots = true
						dirt.biome = current_biome
						instance = dirt
					elif randf() < 0.5:
						var dirt = DIRT_SCENE.instantiate()
						dirt.biome = current_biome
						instance = dirt
					else:
						var stone = STONE_SCENE.instantiate()
						stone.biome = current_biome
						instance = stone
			
			instance.position = tile_pos
			if instance.has_method("apply_biome"):
				instance.apply_biome(current_biome)
			if instance.has_method("set_grid_pos"):
				instance.set_grid_pos(grid_coord)
			elif "grid_pos" in instance:
				instance.grid_pos = grid_coord
			add_child(instance)

	# Spawn cuttable surface trees (above grass line at Y = 112)
	var tree_positions = [48, 112, 176, 240, 304, 368, 672, 736, 800, 864, 912]
	for tx in tree_positions:
		var tree = TREE_SCENE.instantiate()
		tree.position = Vector2(tx, 112)
		add_child(tree)

	# Spawn decorative bushes on surface
	var bush_positions = [80, 144, 208, 272, 336, 608, 704, 768, 832, 888]
	for bx in bush_positions:
		var bush = BUSH_SCENE.instantiate()
		bush.position = Vector2(bx, 112)
		add_child(bush)
	
	# 3 pedras decorativas na superfície (na frente de árvores/arbustos)
	for sx in [96.0, 448.0, 864.0]:
		var srock = RANDOM_ROCK_SCENE.instantiate()
		srock.position = Vector2(sx, 112.0)
		srock.z_index = 1
		add_child(srock)
	
	# Pedras decorativas em escavações/cavernas, apenas sobre blocos indestrutíveis
	_spawn_cave_rocks(cave_cells, excavated_cells, unbreakable_blocks)

func _spawn_cave_rocks(cave_cells: Dictionary, excavated_cells: Dictionary, unbreakable_blocks: Dictionary) -> void:
	var seen_cols := {}
	for coord in cave_cells:
		_place_rock_on_bedrock(coord, unbreakable_blocks, seen_cols)
	for coord in excavated_cells:
		_place_rock_on_bedrock(coord, unbreakable_blocks, seen_cols)

func _place_rock_on_bedrock(coord: Vector2i, unbreakable_blocks: Dictionary, seen_cols: Dictionary) -> void:
	var below = Vector2i(coord.x, coord.y + 1)
	if not unbreakable_blocks.has(below):
		return
	# Equilíbrio: ~45% dos pontos elegíveis recebem pedra (populado, não lotado)
	if randf() > 0.45:
		return
	# Espaçamento: não colocar pedras coladas umas às outras (pelo menos 1 coluna de folga)
	if seen_cols.has(below.x - 1) or seen_cols.has(below.x) or seen_cols.has(below.x + 1):
		return
	seen_cols[below.x] = true
	var rock = RANDOM_ROCK_SCENE.instantiate()
	rock.position = Vector2(below.x * 32.0 + 16.0, below.y * 32.0 + 112.0) # base do nó = topo do bloco
	rock.z_index = 1
	add_child(rock)
