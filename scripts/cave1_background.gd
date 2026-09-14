extends Node2D

# Background parallax do nivel 1 da escavacao (linhas 1..5, y 144..304).
# A imagem cave_1_1.png e usada apenas nesta faixa, repetida na horizontal
# cobrindo toda a largura da escavacao, e desliza mais devagar que a camera.

const TEX_PATH := "res://assets/sprites/background/cave_1_1.png"
const TILE_W := 128.0
const TILE_H := 216.0
const LEVEL_MIN_Y := 144.0
const LEVEL_MAX_Y := 304.0
const MS_X := 0.25
const VISIBLE_MARGIN := 8.0

var _layer: Node2D
var _tile_w: float = TILE_W
var _scale: float = 1.0

func _ready() -> void:
	var tex: Texture2D = load(TEX_PATH)
	_scale = (LEVEL_MAX_Y - LEVEL_MIN_Y) / TILE_H
	_tile_w = TILE_W * _scale

	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

	_layer = Node2D.new()
	_layer.name = "ParallaxLayer"
	add_child(_layer)

	var cols := int(ceil(480.0 / _tile_w)) + 2
	for c in range(-cols, cols + 1):
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.scale = Vector2(_scale, _scale)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.material = unshaded
		spr.position = Vector2(c * _tile_w, 0.0)
		_layer.add_child(spr)
	visible = false

func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return
	var cam_center := cam.get_screen_center_position()
	var in_level := cam_center.y >= LEVEL_MIN_Y - VISIBLE_MARGIN and cam_center.y <= LEVEL_MAX_Y + VISIBLE_MARGIN
	visible = in_level
	if not in_level:
		return
	_layer.position = Vector2(cam_center.x * (1.0 - MS_X), (LEVEL_MIN_Y + LEVEL_MAX_Y) * 0.5)