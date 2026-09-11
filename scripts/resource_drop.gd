extends Area2D

enum ResourceType { STONE, COPPER }
@export var type: ResourceType = ResourceType.STONE

func _ready() -> void:
	var poly = $Polygon2D
	if type == ResourceType.STONE:
		poly.color = Color(0.5, 0.5, 0.55, 1.0)
	else:
		poly.color = Color(0.9, 0.5, 0.2, 1.0)
		
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
		if type == ResourceType.STONE:
			print("Collected Stone")
		else:
			print("Collected Copper")
		queue_free()
