extends Node2D
# Orbe de XP:
#   - nasce no local do bloco minerado
#   - flutua parado por DELAY_SECONDS (bob + pulso + pisca no final)
#   - depois voa até o player com flash de impacto

var target: Node2D

const DELAY_SECONDS: float = 1.5   # tempo parado flutuando
const FLY_SECONDS:   float = 0.45  # duração do voo

var _phase:     int   = 0   # 0 = espera, 1 = voando
var _timer:     float = 0.0
var _spawn_pos: Vector2 = Vector2.ZERO  # posição original do spawn
var _fly_from:  Vector2 = Vector2.ZERO  # posição no momento de iniciar o voo
var _glow:  Sprite2D
var _light: PointLight2D

func _ready() -> void:
	z_index = 10
	var tex := _build_glow_texture()

	_glow = Sprite2D.new()
	_glow.texture = tex
	_glow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_glow.material = _make_additive_material()
	_glow.modulate = Color(0.45, 0.78, 1.3)
	add_child(_glow)

	_light = PointLight2D.new()
	_light.texture = tex
	_light.scale = Vector2(1.2, 1.2)
	_light.color = Color(0.4, 0.75, 1.0)
	_light.energy = 1.1
	add_child(_light)

	_spawn_pos = global_position
	scale = Vector2(0.62, 0.62)

func _process(delta: float) -> void:
	match _phase:
		0: # Flutua parado no local do spawn
			_timer += delta

			# Bob suave para cima e para baixo
			var bob: float = -5.0 * sin(_timer * 5.5)
			global_position = _spawn_pos + Vector2(0.0, bob)

			# Pulso de escala
			var pulse: float = 1.0 + 0.16 * sin(_timer * 9.0)
			_glow.scale = Vector2(pulse, pulse)

			# Nos últimos 25% do delay: pisca para avisar que vai voar
			var t_norm: float = _timer / DELAY_SECONDS
			if t_norm >= 0.75:
				var blink: float = 0.55 + 0.45 * sin(_timer * 28.0)
				modulate.a = blink
			else:
				modulate.a = 1.0

			if _timer >= DELAY_SECONDS:
				modulate.a = 1.0
				_fly_from = global_position  # captura posição real após bob
				_phase = 1
				_timer = 0.0

		1: # Voa até o player
			_timer += delta
			var t: float     = clampf(_timer / FLY_SECONDS, 0.0, 1.0)
			var eased: float = 1.0 - pow(1.0 - t, 2.5)
			global_position  = _fly_from.lerp(_target_point(), eased)
			_light.energy    = 1.1 + t * 1.5  # fica mais brilhante ao chegar
			if t >= 1.0:
				_release_glow_flash()
				queue_free()

func _target_point() -> Vector2:
	if is_instance_valid(target):
		return target.global_position + Vector2(0, -6)
	return _fly_from

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
