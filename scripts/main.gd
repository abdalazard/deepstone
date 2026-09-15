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
const XP_ORB_SCRIPT: GDScript = preload("res://scripts/xp_orb.gd")

@onready var player = $Player

var _minimap_node: Node2D = null
var _minimap_layer: CanvasLayer = null
var _biome_announcement: Label = null
var _last_biome: int = -99

var sky_color: Color = Color(0.4, 0.65, 0.9, 1.0)
var earth_cave_color: Color = Color(0.06, 0.05, 0.04, 1.0) # Camada de Terra (Dark earth)
var ice_cave_color: Color = Color(0.02, 0.08, 0.16, 1.0) # Camada de Gelo (Abyssal cold blue)
var lava_cave_color: Color = Color(0.14, 0.03, 0.02, 1.0) # Camada de Lava (Magmatic ember dark)

# Geração do mundo em pedaços: descritores de blocos instanciados aos poucos
# (linha a linha, superfície primeiro) para não travar a inicialização.
var _block_queue: Array = []
var _world_done := false
const BLOCKS_PER_FRAME: int = 1400
var _cave_cells: Dictionary = {}
var _excavated_cells: Dictionary = {}
var _unbreakable_blocks: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if has_node("/root/SaveManager"):
		seed(SaveManager.world_seed)
	
	# Spawn signpost AFTER entrance hole (column 18, X = 592, Y = 96)
	var sign = SIGNPOST_SCENE.instantiate()
	sign.position = Vector2(592, 96)
	add_child(sign)
	
	generate_world()
	_setup_subsurface_shade()
	_setup_surface_light()
	_connect_exp_gained()
	_setup_minimap()
	_setup_biome_announcement()

# Geração do mundo em pedaços: os descritores são instanciados em lotes por
# frame (linha a linha, superfície primeiro) para não travar a inicialização.
func is_world_ready() -> bool:
	return _world_done

func _drain_world_queue() -> void:
	if _world_done:
		return
	var batch := mini(BLOCKS_PER_FRAME, _block_queue.size())
	for i in range(batch):
		var desc = _block_queue.pop_back()
		if desc == null:
			continue
		var inst: Node2D = _instantiate_block_desc(desc)
		if is_instance_valid(inst):
			add_child(inst)
	if _block_queue.is_empty():
		_world_done = true
		_finish_world_generation()

func _instantiate_block_desc(desc: Dictionary) -> Node2D:
	var scene: PackedScene = desc.get("scene")
	if scene == null:
		return null
	var biome: int = desc.get("biome", 0)
	var instance: Node2D = scene.instantiate()
	var pos: Vector2 = desc.get("pos", Vector2.ZERO)
	var grid: Vector2i = desc.get("grid", Vector2i(-1, -1))
	instance.position = pos
	if desc.get("kind") == "rock":
		instance.is_copper = desc.get("is_copper", false)
		instance.is_coal = desc.get("is_coal", false)
	elif desc.get("kind") == "dirt":
		instance.is_roots = desc.get("is_roots", false)
	if "biome" in instance:
		instance.biome = biome
	if instance.has_method("apply_biome"):
		instance.apply_biome(biome)
	if instance.has_method("set_grid_pos"):
		instance.set_grid_pos(grid)
	elif "grid_pos" in instance:
		instance.grid_pos = grid
	return instance

func _finish_world_generation() -> void:
	restore_placed_items()
	# Pedras decorativas e outras decorações que dependem do chão existente
	_spawn_cave_rocks(_cave_cells, _excavated_cells, _unbreakable_blocks)
	# Árvores e arbustos cortáveis (acima da linha da grama em Y = 112)
	var tree_positions = [48, 112, 176, 240, 304, 368, 672, 736, 800, 864, 912]
	for tx in tree_positions:
		var tree = TREE_SCENE.instantiate()
		tree.position = Vector2(tx, 112)
		add_child(tree)
	var bush_positions = [80, 144, 208, 272, 336, 608, 704, 768, 832, 888]
	for bx in bush_positions:
		var bush = BUSH_SCENE.instantiate()
		bush.position = Vector2(bx, 112)
		add_child(bush)
	for sx in [96.0, 448.0, 864.0]:
		var srock = RANDOM_ROCK_SCENE.instantiate()
		srock.position = Vector2(sx, 112.0)
		srock.z_index = 1
		add_child(srock)

func _process(delta: float) -> void:
	_drain_world_queue()
	if is_instance_valid(player):
		var target_color: Color
		var py: float = player.global_position.y
		Music.update_biome(py)
		_check_biome_change(py)
		if py < 120.0:
			target_color = sky_color
		elif py < WorldConfig.BIOME_TERRA_END: # Terra
			target_color = earth_cave_color
		elif py < WorldConfig.BIOME_GELO_END: # Gelo
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

		# Atualiza minimapa (só no subsolo)
		var underground: bool = py >= WorldConfig.SURFACE_Y
		if is_instance_valid(_minimap_layer):
			_minimap_layer.visible = underground
		if underground and is_instance_valid(_minimap_node):
			_minimap_node.queue_redraw()

		# Dinâmica de descoberta: na superfície a câmera sobe para mostrar mais
		# céu e menos chão; ao descer para o primeiro andar do subsolo ela volta
		# a centralizar o personagem no meio da tela.
		var cam = player.get_node_or_null("Camera2D")
		if cam:
			var target_offset := Vector2.ZERO
			if py < WorldConfig.SURFACE_Y:
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
# Orbes de experiência: surgem após 0.5s e voam até o player
# ---------------------------------------------------------------------------
func _connect_exp_gained() -> void:
	var inv = get_tree().root.get_node_or_null("Inventory")
	if inv and inv.has_signal("exp_gained") and not inv.exp_gained.is_connected(_on_exp_gained):
		inv.exp_gained.connect(_on_exp_gained)

func _on_exp_gained(_amount: int, origin: Vector2 = Vector2.ZERO) -> void:
	if not is_instance_valid(player):
		return
	var orb := Node2D.new()
	orb.set_script(XP_ORB_SCRIPT)
	orb.target = player
	# Orbe nasce no bloco quebrado; se não houver origem, perto do player
	if origin != Vector2.ZERO:
		orb.global_position = origin
	else:
		orb.global_position = player.global_position + Vector2(randf_range(-48.0, 48.0), randf_range(-56.0, -8.0))
	add_child(orb)

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
	const GRID_H = 600 # Escavação expandida até profundidade 600 (~19328 pixels)
	
	# Cavernas naturais distribuídas por todas as camadas
	var cave_chambers = []
	var depth_zones = [
		# Bioma Terra (1-199)
		Vector2i(5,8),Vector2i(20,23),Vector2i(38,41),Vector2i(58,61),
		Vector2i(80,83),Vector2i(104,107),Vector2i(130,133),Vector2i(158,161),Vector2i(183,186),
		# Bioma Gelo (200-399)
		Vector2i(205,208),Vector2i(225,228),Vector2i(248,251),Vector2i(272,275),
		Vector2i(298,301),Vector2i(325,328),Vector2i(353,356),Vector2i(380,383),
		# Bioma Lava (400-598)
		Vector2i(405,408),Vector2i(428,431),Vector2i(453,456),Vector2i(480,483),
		Vector2i(508,511),Vector2i(537,540),Vector2i(566,569),Vector2i(590,593)
	]
	for zone in depth_zones:
		var cx = randi_range(3, GRID_W - 4)
		var cy = randi_range(zone.x, zone.y)
		var rx = randf_range(2.0, 3.8)
		var ry = randf_range(1.5, 2.8)
		cave_chambers.append({"center": Vector2(cx, cy), "rx": rx, "ry": ry})
	
	_unbreakable_blocks.clear()
	_cave_cells.clear()
	_excavated_cells.clear()

	# ══════════════════════════════════════════════════════════════════
	#  Linhas horizontais de blocos rígidos
	#  Cada linha atravessa quase toda a largura, com 1 brecha aleatória
	#  de 3-4 tiles. Força o jogador a mineirar em busca da passagem.
	# ══════════════════════════════════════════════════════════════════

	# Bedrock intransponível (última fileira)
	for x in range(GRID_W):
		_unbreakable_blocks[Vector2i(x, GRID_H - 1)] = true

	# Linhas horizontais rígidas com brechas aleatórias
	var line_y := randi_range(8, 12)
	while line_y < GRID_H - 3:
		var gap_x := randi_range(2, GRID_W - 6)
		var gap_w := randi_range(3, 5)
		for lx in range(GRID_W):
			if lx >= gap_x and lx < gap_x + gap_w:
				continue # Brecha: passagem livre
			_unbreakable_blocks[Vector2i(lx, line_y)] = true
		line_y += randi_range(8, 13)

	# ══════════════════════════════════════════════════════════════════
	#  Pilares verticais de blocos rígidos (obstáculos perpendiculares)
	#  Dispersos pelo mundo inteiro para forçar desvios laterais.
	# ══════════════════════════════════════════════════════════════════
	for _pi in range(90):
		var px: int = randi_range(2, GRID_W - 3)
		var py_top: int = randi_range(5, GRID_H - 8)
		var ph: int = randi_range(3, 7)
		for pdy in range(ph):
			var pcoord := Vector2i(px, py_top + pdy)
			if pcoord.y < GRID_H - 1:
				_unbreakable_blocks[pcoord] = true

	# ── Cavernas naturais ──
	for chamber in cave_chambers:
		var cx2 = int(chamber.center.x)
		var cy2 = int(chamber.center.y)
		var rx  = chamber.rx
		var ry  = chamber.ry
		for dy in range(-int(ry) - 2, int(ry) + 3):
			for dx in range(-int(rx) - 2, int(rx) + 3):
				var ddx = float(dx) / rx
				var ddy = float(dy) / ry
				if ddx * ddx + ddy * ddy < 1.0:
					var gx = cx2 + dx
					var gy = cy2 + dy
					if gx > 0 and gx < GRID_W - 1 and gy > 0 and gy < GRID_H - 1:
						_cave_cells[Vector2i(gx, gy)] = true

	# Inst instanciação de blocos com biomas
	for x in range(GRID_W):
		for y in range(GRID_H):
			var grid_coord = Vector2i(x, y)
			
			# Classificação do bioma atual
			var current_biome = 0 # 0=Terra
			if y >= 400:
				current_biome = 2 # Lava
			elif y >= 200:
				current_biome = 1 # Gelo
			
			if has_node("/root/SaveManager") and SaveManager.is_block_mined(grid_coord):
				_excavated_cells[grid_coord] = true
				continue
			
			# Células pré-definidas como espaço vazio (corredores, lobby, base do U)
			if _cave_cells.has(grid_coord) and not _unbreakable_blocks.has(grid_coord):
				continue
			
			# Cavernas naturais escuras
			var in_natural_cave = false
			if y >= 3 and y < GRID_H - 1 and x > 0 and x < GRID_W - 1 and not _unbreakable_blocks.has(grid_coord):
				for chamber in cave_chambers:
					var dx = (x - chamber.center.x) / chamber.rx
					var dy = (y - chamber.center.y) / chamber.ry
					var dist = dx * dx + dy * dy
					var jitter = sin(x * 2.5 + y * 3.1) * 0.15
					if dist + jitter < 1.0:
						in_natural_cave = true
						break
			
			if in_natural_cave:
				_cave_cells[grid_coord] = true
				continue
			
			var tile_pos = Vector2(x * 32 + 16, y * 32 + 128)
			var desc := {
				"scene": GRASS_SCENE,
				"kind": "grass",
				"pos": tile_pos,
				"grid": grid_coord,
				"biome": current_biome,
			}
			
			# Superfície (y == 0) é gramado, com coluna 17 como entrada de terra
			if y == 0:
				if x == 17:
					desc["scene"] = GRASS_DIRT_SCENE
			elif _unbreakable_blocks.has(grid_coord):
				desc["scene"] = UNBREAKABLE_SCENE
				desc["kind"] = "unbreakable"
				desc["unbreakable"] = true
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
				elif current_biome == 0: # Terra profunda (y: 11 a 199)
					gold_thresh = 0.99 # ~1.0% ouro (raro e recompensador!)
					iron_thresh = 0.77 # ~22% ferro
					coal_thresh = 0.35 # ~42% carvão
				elif current_biome == 1: # Gelo (y: 200 a 399)
					gold_thresh = 0.975 # ~2.5% ouro
					iron_thresh = 0.725 # ~25% ferro
					coal_thresh = 0.325 # ~40% carvão
				else: # Lava (y: 400 a 599)
					gold_thresh = 0.96 # ~4.0% ouro
					iron_thresh = 0.68 # ~28% ferro
					coal_thresh = 0.32 # ~36% carvão
				
				if ore_roll > gold_thresh:
					desc["scene"] = ROCK_SCENE
					desc["kind"] = "rock"
					desc["is_copper"] = true # Ouro
				elif ore_roll > iron_thresh:
					desc["scene"] = ROCK_SCENE
					desc["kind"] = "rock"
					desc["is_copper"] = false
					desc["is_coal"] = false # Ferro
				elif ore_roll > coal_thresh:
					desc["scene"] = ROCK_SCENE
					desc["kind"] = "rock"
					desc["is_copper"] = false
					desc["is_coal"] = true # Carvão Mineral
				else:
					if y >= 1 and y <= 6 and randf() < 0.35:
						desc["scene"] = DIRT_SCENE
						desc["kind"] = "dirt"
						desc["is_roots"] = true
					elif randf() < 0.5:
						desc["scene"] = DIRT_SCENE
						desc["kind"] = "dirt"
					else:
						desc["scene"] = STONE_SCENE
						desc["kind"] = "stone"
			
			_block_queue.append(desc)

	# Ordena para a superfície (y pequeno) ser instanciada primeiro: fila em
	# ordem decrescente de y, `_drain_world_queue` usa pop_back() -> menor y 1º.
	_block_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("grid", Vector2i(-1, -1)).y > b.get("grid", Vector2i(-1, -1)).y)

func _spawn_cave_rocks(cave_cells: Dictionary, excavated_cells: Dictionary, unbreakable_blocks: Dictionary) -> void:
	var seen_cols := {}
	for coord in cave_cells:
		_place_rock_on_bedrock(coord, unbreakable_blocks, seen_cols)
	for coord in excavated_cells:
		_place_rock_on_bedrock(coord, unbreakable_blocks, seen_cols)

func _place_rock_on_bedrock(coord: Vector2i, unbreakable_blocks: Dictionary, seen_cols: Dictionary) -> void:
	var below := Vector2i(coord.x, coord.y + 1)
	# Coloca pedra sobre qualquer piso sólido (inquebrável OU rocha/terra normal)
	var has_solid_floor: bool = unbreakable_blocks.has(below) or \
		(not _cave_cells.has(below) and not _excavated_cells.has(below) and \
		 below.x > 0 and below.x < 29 and below.y > 0 and below.y < 599)
	if not has_solid_floor:
		return
	# ~18%: espalha mais do que antes, mas sem exagero
	if randf() > 0.18:
		return
	# Espaçamento mínimo de 2 colunas entre pedras decorativas
	if seen_cols.has(below.x - 1) or seen_cols.has(below.x) or seen_cols.has(below.x + 1):
		return
	seen_cols[below.x] = true
	var rock := RANDOM_ROCK_SCENE.instantiate()
	rock.position = Vector2(below.x * 32.0 + 16.0, below.y * 32.0 + 112.0)
	rock.z_index = 1
	add_child(rock)

# ── Minimapa ──────────────────────────────────────────────────────────────────
func _setup_minimap() -> void:
	var cl := CanvasLayer.new()
	cl.name = "MinimapLayer"
	cl.layer = 10
	cl.visible = false  # Só aparece no subsolo
	add_child(cl)
	_minimap_layer = cl

	# Fundo sólido
	var bg := ColorRect.new()
	bg.name = "MinimapBg"
	bg.color = Color(0.05, 0.05, 0.05, 0.80)
	bg.size = Vector2(182, 422)
	bg.position = Vector2(1082, 78)
	cl.add_child(bg)

	var mm := Node2D.new()
	mm.name = "MinimapNode"
	cl.add_child(mm)
	_minimap_node = mm
	mm.draw.connect(_draw_minimap)

func _draw_minimap() -> void:
	if not is_instance_valid(player):
		return
	const MAP_X: float = 1083.0
	const MAP_Y: float = 79.0
	const MAP_W: float = 180.0
	const MAP_H: float = 420.0
	const GRID_W_F: float = 30.0
	const GRID_H_F: float = 600.0
	const CELL_W: float = MAP_W / GRID_W_F  # 6.0 px por coluna
	const CELL_H: float = MAP_H / GRID_H_F  # 0.70 px por linha

	# Borda
	_minimap_node.draw_rect(Rect2(MAP_X, MAP_Y, MAP_W, MAP_H), Color(0.55, 0.50, 0.42, 0.9), false, 1.5)

	# Tuneis escavados (células mineiradas do SaveManager)
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		for key: String in sm.mined_blocks.keys():
			var parts: PackedStringArray = key.split(",")
			if parts.size() < 2:
				continue
			var cx: float = float(parts[0])
			var cy: float = float(parts[1])
			if cy < 0.0 or cy >= GRID_H_F:
				continue
			var px: float = MAP_X + cx * CELL_W
			var py: float = MAP_Y + cy * CELL_H
			# Retângulo de 1 célula — visível mesmo quando CELL_H < 1
			_minimap_node.draw_rect(
				Rect2(px, py, maxf(CELL_W - 0.3, 1.0), maxf(CELL_H, 1.5)),
				Color(0.90, 0.90, 0.90, 0.75))

	# Linha da superfície
	var surf_y: float = MAP_Y + (1.0 / GRID_H_F) * MAP_H
	_minimap_node.draw_line(
		Vector2(MAP_X, surf_y), Vector2(MAP_X + MAP_W, surf_y),
		Color(0.5, 0.8, 0.3, 0.7), 1.0)

	# Posição do jogador
	var world_y: float = player.global_position.y
	var grid_y: float = (world_y - 128.0) / 32.0
	var ratio: float = clampf(grid_y / GRID_H_F, 0.0, 1.0)
	var dot_y: float = MAP_Y + ratio * MAP_H
	var world_x: float = player.global_position.x
	var grid_x: float = (world_x - 16.0) / 32.0
	var dot_x: float = MAP_X + clampf(grid_x / GRID_W_F, 0.0, 1.0) * MAP_W
	_minimap_node.draw_circle(Vector2(dot_x, dot_y), 4.0, Color(1.0, 1.0, 1.0, 1.0))
	_minimap_node.draw_circle(Vector2(dot_x, dot_y), 2.0, Color(0.25, 0.85, 1.0, 1.0))

# ── Anúncio de Bioma ─────────────────────────────────────────────────────────
func _setup_biome_announcement() -> void:
	var cl := CanvasLayer.new()
	cl.name = "BiomeAnnouncementLayer"
	cl.layer = 12
	add_child(cl)

	var lbl := Label.new()
	lbl.name = "BiomeLabel"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = Vector2(640, 80)
	lbl.position = Vector2(0, 140)
	lbl.modulate.a = 0.0
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	cl.add_child(lbl)
	_biome_announcement = lbl

func _check_biome_change(world_y: float) -> void:
	var b: int = WorldConfig.biome_at(world_y)
	if b == _last_biome:
		return
	_last_biome = b
	if b < 0:
		return # Superfície — sem anúncio
	# Aguarda 1 segundo; não mostra se o tutorial (StartScreen) estiver aberto
	var capture_b: int = b
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		var scene = get_tree().current_scene if get_tree() else null
		if scene and scene.get_node_or_null("StartScreen") != null:
			return # Tutorial aberto — suprime anúncio
		if not is_instance_valid(_biome_announcement):
			return
		var names2 := [
			tr("Vale do Quartzo Cantante"),
			tr("Além das Neves Eternas"),
			tr("A Ascensão Ardente")
		]
		var colors2 := [Color(0.92, 0.78, 0.48), Color(0.55, 0.88, 1.0), Color(1.0, 0.52, 0.22)]
		if capture_b >= names2.size():
			return
		_biome_announcement.text = names2[capture_b]
		_biome_announcement.add_theme_color_override("font_color", colors2[capture_b])
		var tw := create_tween()
		tw.tween_property(_biome_announcement, "modulate:a", 1.0, 0.45)
		tw.tween_interval(1.8)
		tw.tween_property(_biome_announcement, "modulate:a", 0.0, 0.55)
	)
