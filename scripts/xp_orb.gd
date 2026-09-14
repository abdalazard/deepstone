extends Node2D
# Orbe azul de XP: pausa 0.5s, voa até o player e emite um brilho azul ao encostar.

var target: Node2D

const DELAY_SECONDS: float = 0.5
const FLY_SECONDS: float = 0.45

var _phase: int = 0 # 0 = espera, 1 = voando
var _timer: float = 0.0
var _start_pos := Vector2.ZERO
var _glow: Sprite2D

func _ready() -> void:
	z_index = 10
	var tex := _build_glow_texture()
	_glow = Sprite2D.new()
	_glow.texture = tex
	_glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_glow.material = _make_additive_material()
	_glow.modulate = Color(0.45, 0.78, 1.3)
	add_child(_glow)
	var light := PointLight2D.new()
	light.texture = tex
	light.scale = Vector2(1.2, 1.2)
	light.color = Color(0.4, 0.75, 1.0)
	light.energy = 1.1
	add_child(light)
	_start_pos = global_position
	scale = Vector2(0.62, 0.62)

func _process(delta: float) -> void:
	match _phase:
		0:
			_timer += delta
			var pulse := 1.0 + 0.14 * sin(_timer * 10.0)
			_glow.scale = Vector2(pulse, pulse)
			if _timer >= DELAY_SECONDS:
				_phase = 1
				_timer = 0.0
		1:
			_timer += delta
			var t := clampf(_timer / FLY_SECONDS, 0.0, 1.0)
			var eased := 1.0 - pow(1.0 - t, 2.5)
			global_position = _start_pos.lerp(_target_point(), eased)
			if t >= 1.0:
				_release_glow_flash()
				queue_free()

func _target_point() -> Vector2:
	if is_instance_valid(target):
		return target.global_position + Vector2(0, -6)
	return _start_pos

func _release_glow_flash() -> void:
	if not is_inside_tree():
		return
	var flash := Sprite2D.new()
	flash.texture = _build_glow_texture()
	flash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	flash.material = _make_additive_material()
	flash.modulate = Color(0.5, 0.85, 1.5, 0.95)
	flash.position = global_position
	get_parent().add_child(flash)
	var tween := get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(3.6, 3.6), 0.3)
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(func():
		if is_instance_valid(flash):
			flash.queue_free()
	)

func _make_additive_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat

func _build_glow_texture() -> Texture2D:
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half := size / 2.0
	for y in range(size):
		for x in range(size):
			var dx := (float(x) - half) / half
			var dy := (float(y) - half) / half
			var d := clampf(1.0 - (dx * dx + dy * dy) * 1.9, 0.0, 1.0)
			var a := d * d
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)
