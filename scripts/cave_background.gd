extends Node2D

# Background de caverna em parallax: 8 tiles (assets/tiles/0..7.png) empilhadas
# como camadas de profundidade (0 = fundo/lento, 7 = frente/rápido).
# A faixa começa no teto da caverna (ROOF_Y) e desce até abaixo do bedrock.
# A posição é travada no teto quando a câmera está na superfície, para nunca
# vazar blocos de caverna para dentro do céu.
#
# Importante: o brilho por camada deve ficar BEM abaixo de 1.0 de estouro por
# canal (tile 7 tem canal azul ~0.39; se multiplayer por ~2.7 vira 1.05 e o
# fundo fica BRANCO, dividindo a cena). Aqui o brilho fica ~1.1..1.55 para o
# tom azul-marinho original aparecer sem clarear.
#
# As colunas são estendidas para além das bordas da câmera (a câmera pode
# chegar perto de x=960 e a tela cobre até ±320 do centro), evitando o "vão"
# que deixava metade sem parallax (revelando o polígono azul direto).

const TILE_W: float = 384.0
const TILE_H: float = 216.0
const ROOF_Y:    float = WorldConfig.SURFACE_Y
const BOTTOM_Y:  float = WorldConfig.BIOME_VULCAO_END

var textures: Array = []

func _ready() -> void:
	for i in range(8):
		textures.append(load("res://assets/tiles/%d.png" % i))
	build_layers()

func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return
	var cam_center := cam.get_screen_center_position()
	# Profundidade da câmera abaixo do teto; travada em 0 na superfície para o
	# conteúdo nunca subir acima do teto da caverna (senão as tiles vazam no céu).
	var dc := maxf(cam_center.y, ROOF_Y) - ROOF_Y

	# Tinge as camadas por bioma para o fundo combinar com a profundidade atual.
	var biome_color := Color(1, 1, 1)
	var py := cam_center.y
	if py >= 2560.0:                     # Lava
		biome_color = Color(1.0, 0.8, 0.7)
	elif py >= 1280.0:                   # Gelo
		biome_color = Color(0.72, 0.84, 1.0)

	for layer in get_children():
		var ms_y: float = layer.get_meta("ms_y")
		# A camada fica ancorada no teto: o conteúdo começa exatamente na linha
		# do teto (ROOF_Y) e desce; camadas mais próximas descem mais rápido.
		layer.position = Vector2(cam_center.x, ROOF_Y + dc * (1.0 - ms_y))
		layer.modulate = layer.get_meta("mod") * biome_color

func build_layers() -> void:
	var half_h := get_viewport().get_visible_rect().size.y * 0.5 / 2.0

	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

	# Camada 0 (fundo, lenta) -> camada 7 (frente, rápida)
	for i in range(8):
		var ms_y := 0.35 + float(i) / 7.0 * 0.60
		var layer := Node2D.new()
		layer.name = "Layer%d" % i
		layer.set_meta("ms_y", ms_y)
		# Posição inicial já ancorada no teto: evita que, no primeiro frame (ex.:
		# quando o menu inicial abre), as camadas fiquem em y=0 e as tiles da
		# caverna se misturem com o céu. O _process ajusta todo frame seguinte.
		layer.position = Vector2(0, ROOF_Y)
		# Brilho moderado (sem estourar canais >1.0, que lavaria o fundo de branco).
		var bright := 1.1 + float(i) / 7.0 * 0.45
		layer.set_meta("mod", Color(bright, bright * 0.96, bright * 0.9))
		add_child(layer)

		var tex: Texture2D = textures[i]
		# Rows cobrem do teto (local 0) até o fundo do mundo na profundidade máxima.
		var rows := int(ceil((BOTTOM_Y - ROOF_Y) * ms_y / TILE_H + half_h / TILE_H)) + 2
		var cols := int(ceil(1280.0 / TILE_W)) + 2
		for r in range(rows):
			var y := r * TILE_H + TILE_H * 0.5
			for c in range(-1, cols + 1):
				var spr := Sprite2D.new()
				spr.texture = tex
				spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				spr.material = unshaded
				spr.position = Vector2(c * TILE_W + TILE_W * 0.5, y)
				layer.add_child(spr)