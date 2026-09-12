extends Area2D

enum ResourceType { STONE, COPPER }
@export var type: ResourceType = ResourceType.STONE

func _ready() -> void:
	var sprite = $Sprite2D
	if type == ResourceType.STONE:
		sprite.frame = 24 # Row 5 Col 1 (stone/coal lump)
	else:
		sprite.frame = 26 # Row 5 Col 3 (copper ingot)
		
	body_entered.connect(_on_body_entered)
	
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BOUNCE)
	
	var timer = Timer.new()
	timer.wait_time = 15.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		Inventory.add_resource(type, 1)
		queue_free()
