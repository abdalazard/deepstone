extends Node2D

func _ready() -> void:
	add_to_group("random_rocks")
	var sprite = get_node_or_null("Sprite2D")
	if not sprite:
		return
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = _load_or_build_rock_texture()
	# Maior visibilidade no mapa
	sprite.scale = Vector2(2.5, 2.5)
	# Centraliza o sprite sobre a origem do nó, com a BASE tocando o chão
	var h := float(sprite.texture.get_height())
	sprite.position = Vector2(0, -h * 0.5 * sprite.scale.y)

func _load_or_build_rock_texture() -> Texture2D:
	var tex: Texture2D = load("res://assets/sprites/decorations/random_rock.png")
	if tex:
		return tex
	return _build_rock_texture()

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