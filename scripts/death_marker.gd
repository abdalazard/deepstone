extends Node2D

func _ready() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.texture = _build_skull_texture()

# Caveirinha pixel art 16x16 gerada em código (X=branco, E=olhos pretos,
# N=nariz, .=transparente)
func _build_skull_texture() -> Texture2D:
	var rows := [
		"................",
		"................",
		"................",
		".....XXXXXX.....",
		"....XXXXXXXX....",
		"...XXXXXXXXXX...",
		"..XXXXXXXXXXXX..",
		"..XXEEXXXXXXEEX.",
		"..XXEEXXXXXXEEX.",
		"..XXEEXXXXXXEEX.",
		"..XXXXXXXXXXXX..",
		"...XXNNNNNNXX...",
		"..XXXXXXXXXXXX..",
		"...XXXXXXXXXX...",
		"....XXXXXXXX....",
		"................",
	]
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		var line: String = rows[y]
		for x in range(16):
			var c: String = line[x]
			match c:
				"X":
					img.set_pixel(x, y, Color(1, 1, 1, 1))
				"E":
					img.set_pixel(x, y, Color(0.04, 0.02, 0.02, 1))
				"N":
					img.set_pixel(x, y, Color(0.1, 0.05, 0.05, 1))
				_:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)