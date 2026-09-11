extends SceneTree

func _init() -> void:
	print("Setting up Input Map...")
	_add_action_key("move_left", KEY_A)
	_add_action_key("move_left", KEY_LEFT)
	
	_add_action_key("move_right", KEY_D)
	_add_action_key("move_right", KEY_RIGHT)
	
	_add_action_key("move_up", KEY_W)
	_add_action_key("move_up", KEY_UP)
	
	_add_action_key("move_down", KEY_S)
	_add_action_key("move_down", KEY_DOWN)
	
	_add_action_key("mine", KEY_SPACE)
	
	ProjectSettings.save()
	print("Input Map updated successfully.")
	quit()

func _add_action_key(action_name: String, keycode: int) -> void:
	if not ProjectSettings.has_setting("input/" + action_name):
		ProjectSettings.set_setting("input/" + action_name, {"deadzone": 0.5, "events": []})
	
	var setting = ProjectSettings.get_setting("input/" + action_name)
	var events = setting.get("events", [])
	
	var event = InputEventKey.new()
	event.physical_keycode = keycode
	
	# Check if already exists
	var exists = false
	for e in events:
		if e is InputEventKey and e.physical_keycode == keycode:
			exists = true
			break
			
	if not exists:
		events.append(event)
		setting["events"] = events
		ProjectSettings.set_setting("input/" + action_name, setting)
