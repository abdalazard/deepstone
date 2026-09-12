extends CanvasLayer

func _ready():
	get_tree().paused = true

func _process(_delta):
	if Input.is_action_just_pressed("action_mine"):
		get_tree().paused = false
		queue_free()
