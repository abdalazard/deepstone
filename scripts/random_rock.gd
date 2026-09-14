extends Node2D

func _ready() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.texture = _load_or_build_rock_texture()

func _load_or_build_rock_texture() -> Texture2D:
	var tex: Texture2D = load("res://assets/sprites/decorations/random_rock.png")
	if tex:
		return tex
	return _build_rock_texture()

func _build_rock_texture() -> Texture2D:
	var img := Image.create(16, 12, false, Image.FORMAT_RGBA8)
	var rows := [
		"................",
		"....XXXXXXXX....",
		"...XXXXXXXXXX...",
		"..XXXXXXXXXXXX..",
		"..XXXXXXXXXXXX..",
		"..XXXXXXXXXXXX..",
		"..XXXXXXXXXXXX..",
		"..XXXXXXXXXXXX..",
		"...XXXXXXXXXX...",
		"....XXXXXXXX....",
		"................",
		"................",
	]
	for y in range(12):
		var line: String = rows[y]
		for x in range(16):
			match line[x]:
				"X": img.set_pixel(x, y, Color(0.48, 0.46, 0.43, 1))
				_: img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)
