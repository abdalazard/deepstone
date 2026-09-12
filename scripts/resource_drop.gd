extends RigidBody2D

enum ResourceType { STONE, COPPER }
@export var type: ResourceType = ResourceType.STONE

func _ready() -> void:
	var sprite = $Sprite2D
	if type == ResourceType.STONE:
		sprite.frame = 24 # Row 5 Col 1 (stone/coal lump)
	else:
		sprite.frame = 26 # Row 5 Col 3 (copper ingot)
		
	# Pop out effect
	apply_impulse(Vector2(randf_range(-50, 50), randf_range(-150, -50)))
	
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BOUNCE)

# Identifier function for the elevator to recognize this object
func is_resource() -> bool:
	return true
