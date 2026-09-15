extends Node2D

# Background parallax das camadas de bioma.
# As dimensões das bandas vêm do WorldConfig (autoload).

const TEX_PATHS: Array[String] = [
	"res://assets/sprites/background/cave_1_1.png",
	"res://assets/sprites/background/cave_1_2.png",
	"res://assets/sprites/background/cave_1_3.png",
]
const BAND_MODS: Array[Color] = [
	Color(0.78, 0.70, 0.90),
	Color(0.88, 0.96, 1.00),
	Color(1.00, 0.96, 0.88),
]

const BASE_W: float    = 1280.0
const BASE_H: float    = 720.0
const MS_X: float      = 0.12   # parallax horizontal leve
const FADE_RANGE: float = 180.0

var _unshaded: CanvasItemMaterial
var _layers: Array     = []
var _tex_heights: Array[float] = []

func _ready() -> void:
	_unshaded = CanvasItemMaterial.new()
	_unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for i in range(TEX_PATHS.size()):
		_build_band(i)

func _build_band(i: int) -> void:
	var tex: Texture2D = load(TEX_PATHS[i])
	if not tex:
		push_warning("cave1_background: não encontrou %s" % TEX_PATHS[i])
		_tex_heights.append(1.0)
		return

	_tex_heights.append(float(tex.get_height()))

	var layer := Node2D.new()
	layer.name = "Band%d" % i
	layer.set_meta("band_idx", i)
	layer.modulate = BAND_MODS[i]
	add_child(layer)

	var spr := Sprite2D.new()
	spr.texture        = tex
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spr.material       = _unshaded
	layer.add_child(spr)
	layer.set_meta("spr", spr)

	_layers.append(layer)

func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return

	var zoom_x: float = cam.zoom.x if cam.zoom.x > 0.0 else 1.0
	var zoom_y: float = cam.zoom.y if cam.zoom.y > 0.0 else 1.0
	var view_w: float = BASE_W / zoom_x
	var view_h: float = BASE_H / zoom_y
	var half_v: float = view_h * 0.5

	var cc: Vector2    = cam.get_screen_center_position()
	var cam_top: float = cc.y - half_v
	var cam_bot: float = cc.y + half_v

	# Lê limites atuais do WorldConfig — adapta se mudarem
	var band_mins: Array[float] = WorldConfig.BAND_MIN_Y
	var band_maxs: Array[float] = WorldConfig.BAND_MAX_Y

	# Só aparece quando o centro da câmera cruza a linha de superfície
	# (cam_bot usaria a borda inferior, que já está underground na superfície)
	visible = cc.y >= band_mins[0]
	if not visible:
		return

	for layer: Node2D in _layers:
		var i: int          = layer.get_meta("band_idx")
		var band_min: float = band_mins[i]
		var band_max: float = band_maxs[i]
		var band_h: float   = band_max - band_min

		if cam_bot < band_min - FADE_RANGE or cam_top > band_max + FADE_RANGE:
			layer.visible = false
			continue
		layer.visible = true

		var spr: Sprite2D    = layer.get_meta("spr")
		var s: float         = view_h / _tex_heights[i]  # preenche exatamente o viewport
		spr.scale            = Vector2(s, s)

		# Alpha
		var alpha: float = 1.0
		var enter_top: float = cam_bot - band_min
		if enter_top < FADE_RANGE:
			alpha = minf(alpha, maxf(enter_top / FADE_RANGE, 0.0))
		var enter_bot: float = band_max - cam_top
		if enter_bot < FADE_RANGE:
			alpha = minf(alpha, maxf(enter_bot / FADE_RANGE, 0.0))
		alpha = clampf(alpha, 0.0, 1.0)

		var base: Color = BAND_MODS[i]
		layer.modulate = Color(base.r, base.g, base.b, alpha)

		# ── Posição ──
		# X: parallax leve → sensação de profundidade lateral
		var cx: float = view_w * 0.5 + (cc.x - view_w * 0.5) * (1.0 - MS_X)

		# Y: centralizado na câmera, mas o TOPO do sprite nunca sobe acima de
		# SURFACE_Y — evita que o background apareça na área da superfície.
		# topo_sprite = cy - half_v  →  cy >= band_mins[0] + half_v
		var cy: float = maxf(cc.y, band_mins[0] + half_v)

		layer.position = Vector2(cx, cy)
