extends Node2D

# Background parallax das camadas de bioma.
# Seleciona a banda com base no bioma atual (SaveManager.current_biome),
# em vez de tentar mapear o Y global — que seria inválido com cenas separadas.

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

const BASE_W: float = 1280.0
const BASE_H: float = 720.0
const MS_X: float   = 0.12

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

	var cc: Vector2 = cam.get_screen_center_position()

	# Só aparece quando a câmera está underground
	visible = cc.y >= WorldConfig.SURFACE_Y
	if not visible:
		return

	# Descobre o bioma da cena atual
	var current_biome: int = 0
	var sm := get_node_or_null("/root/SaveManager")
	if sm:
		current_biome = sm.current_biome

	var zoom_x: float = cam.zoom.x if cam.zoom.x > 0.0 else 1.0
	var zoom_y: float = cam.zoom.y if cam.zoom.y > 0.0 else 1.0
	var view_w: float = BASE_W / zoom_x
	var view_h: float = BASE_H / zoom_y
	var half_v: float = view_h * 0.5

	for layer: Node2D in _layers:
		var i: int = layer.get_meta("band_idx")

		# Mostra apenas a banda do bioma atual
		if i != current_biome:
			layer.visible = false
			continue

		layer.visible = true

		var spr: Sprite2D = layer.get_meta("spr")
		var s: float = view_h / _tex_heights[i]
		spr.scale = Vector2(s, s)

		var cx: float = view_w * 0.5 + (cc.x - view_w * 0.5) * (1.0 - MS_X)
		var cy: float = maxf(cc.y, WorldConfig.SURFACE_Y + half_v)

		layer.position = Vector2(cx, cy)
		layer.modulate = BAND_MODS[i]
