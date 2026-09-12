extends StaticBody2D

const MAX_CAPACITY: int = 50
var stored_load: int = 0
var is_closed: bool = false

@onready var sprite = $Sprite2D
@onready var prompt_label = $PromptLabel
@onready var player_detect = $InteractArea

func _ready() -> void:
	if has_node("/root/SaveManager") and SaveManager.has_loaded_save:
		stored_load = SaveManager.chest_saved_load
		is_closed = SaveManager.chest_saved_closed
	if prompt_label:
		prompt_label.modulate.a = 0.0
		prompt_label.visible = false
	if player_detect:
		player_detect.body_entered.connect(_on_player_entered)
		player_detect.body_exited.connect(_on_player_exited)
	update_visuals()

func update_visuals() -> void:
	# 32 = Open, 30 = Closed in extras.png (assuming 11x11 grid)
	if is_closed:
		sprite.frame = 30
	else:
		sprite.frame = 32
	if prompt_label and prompt_label.visible:
		_update_prompt_text()

func _on_player_entered(body: Node2D) -> void:
	if body.name == "Player":
		_update_prompt_text()
		if prompt_label:
			prompt_label.visible = true
			var tween = create_tween()
			tween.tween_property(prompt_label, "modulate:a", 1.0, 0.2)

func _on_player_exited(body: Node2D) -> void:
	if body.name == "Player":
		if prompt_label:
			var tween = create_tween()
			tween.tween_property(prompt_label, "modulate:a", 0.0, 0.2)
			tween.tween_callback(prompt_label.hide)

func _update_prompt_text() -> void:
	if is_closed:
		prompt_label.text = "[Z] Extrair Baú"
	else:
		prompt_label.text = "[Z] Armazenar recursos"

var in_ladder: bool = false
var gravity_scale_default: float = 1.0

func deposit(items: Dictionary) -> void:
	if is_closed: 
		extract()
		return
	
	var total_weight = items["iron"] * 1 + items["gold"] * 2
	stored_load += total_weight
	
	if stored_load >= MAX_CAPACITY:
		close_chest()
	update_visuals()
	
	Inventory.notify("Recursos guardados no Baú! (Carga: %d/%d)" % [stored_load, MAX_CAPACITY], "chest")
	if has_node("/root/SaveManager"):
		SaveManager.request_save()

func close_chest() -> void:
	is_closed = true
	update_visuals()
	
	# Light effect when closed
	var flash = PointLight2D.new()
	flash.color = Color(0.2, 1.0, 0.4, 1.0)
	flash.energy = 2.0
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(1,1,1,1), Color(0,0,0,1)])
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.8, 0.2)
	tex.width = 64
	tex.height = 64
	flash.texture = tex
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "scale", Vector2(2.0, 2.0), 0.5)
	tween.parallel().tween_property(flash, "energy", 0.0, 0.5)
	tween.finished.connect(flash.queue_free)

func extract() -> void:
	if is_closed:
		# Player gains EXP
		print("Chest extracted! Gained EXP based on load: ", stored_load)
		Inventory.notify("Carga do Baú extraída com sucesso!", "chest")
		# Reset Chest
		stored_load = 0
		is_closed = false
		update_visuals()
		if has_node("/root/SaveManager"):
			SaveManager.request_save()

func is_chest() -> bool:
	return true
