extends Node2D

func _ready() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if not sprite:
		return
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var base := _load_or_build_rock_texture()
	sprite.texture = _apply_border(base, Color(0.22, 0.21, 0.2, 1))
	# Maior visibilidade no mapa (sprite 12x6 fica minúsculo)
	sprite.scale = Vector2(2.5, 2.5)
	# Centraliza com a BASE tocando a origem do nó (considera escala)
	var h := float(sprite.texture.get_height())
	sprite.position = Vector2(0, -h * 0.5 * sprite.scale.y)

func _load_or_build_rock_texture() -> Texture2D:
	var tex: Texture2D = load("res://assets/sprites/decorations/random_rock.png")
	if tex:
		return tex
	return _build_rock_texture()

# Adiciona uma borda escura ao redor dos pixels opacos da pedra
func _apply_border(base: Texture2D, border_color: Color) -> Texture2D:
	var src := base.get_image()
	if not src:
		return base
	var w := src.get_width()
	var h := src.get_height()
	var out := Image.create(w, h, false, src.get_format())
	for y in range(h):
		for x in range(w):
			out.set_pixel(x, y, src.get_pixel(x, y))
	for y in range(h):
		for x in range(w):
			if src.get_pixel(x, y).a > 0.1:
				continue
			var opaque := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var nx := x + dx
					var ny := y + dy
					if nx >= 0 and nx < w and ny >= 0 and ny < h:
						if src.get_pixel(nx, ny).a > 0.1:
							opaque = true
							break
				if opaque:
					break
			if opaque:
				out.set_pixel(x, y, border_color)
	return ImageTexture.create_from_image(out)

# Seixo decorativo 16x16 (fallback procedural, bem centrado)
func _build_rock_texture() -> Texture2D:
	var rows := [
		"................",
		"................",
		"....XXXXXXX.....",
		"...XXXXXXXXX....",
		"..XXXXXXXXXXX...",
		"..XXXXXXXXXXXX..",
		".XXXXXXXXXXXXXX.",
		".XXgXXXXXXXXXXXX",
		".XXXXXXXXXXXXXX.",
		".XXXXXXXXXXXXXX.",
		".XXXXXXXXXXXXXX.",
		"..XXXXXXXXXXXX..",
		"..XXXXXXXXXXXX..",
		"...XXXXXXXXXX...",
		"....XXXXXXXX....",
		"................",
	]
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		var line: String = rows[y]
		for x in range(16):
			match line[x]:
				"X":
					img.set_pixel(x, y, Color(0.50, 0.48, 0.45, 1))
				"g":
					img.set_pixel(x, y, Color(0.74, 0.72, 0.67, 1))
				_:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)