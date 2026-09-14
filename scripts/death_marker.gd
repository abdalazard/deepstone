extends Node2D

# Nível do player no momento da morte: define a quantidade de vida recuperada
# ao tocar na caveira e o texto do marcador.
var death_level: int = 0
var collected: bool = false

func _ready() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.texture = _load_or_build_texture()
	var lbl = get_node_or_null("LevelLabel")
	if lbl:
		lbl.text = "Caveira Nv. %d" % death_level
	var la = get_node_or_null("CollectArea")
	if la and not la.body_entered.is_connected(_on_collected):
		la.body_entered.connect(_on_collected)

# Usa a sprite de caveira fornecida (skull.png), se existir; caso contrário,
# gera uma caveirinha pixel art em código.
func _load_or_build_texture() -> Texture2D:
	var tex: Texture2D = load("res://assets/sprites/decorations/skeleton.png")
	if tex:
		return tex
	return _build_skull_texture()

func _on_collected(body: Node2D) -> void:
	if collected or not is_instance_valid(body) or body.name != "Player":
		return
	collected = true
	var inv = _build_inv()
	if inv:
		if inv.has_method("heal_amount"):
			inv.heal_amount(death_level)
		if inv.has_method("notify"):
			inv.notify("+%d de Vida (Caveira Nv.%d)" % [death_level, death_level], "pickaxe")
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").remove_death_marker(global_position)
	queue_free()

func _build_inv() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root and get_tree().root.has_node("Inventory"):
		return get_tree().root.get_node("Inventory")
	return null

# Caveirinha pixel art 16x16 (fallback caso não exista skull.png)
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