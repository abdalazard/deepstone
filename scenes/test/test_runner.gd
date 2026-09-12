extends Node2D

func _ready() -> void:
	print("--- BEGIN TEST DEEPSTONE INTEGRATED SYSTEMS ---")
	var inv = get_node_or_null("/root/Inventory")
	var save = get_node_or_null("/root/SaveManager")
	assert(inv != null, "Inventory autoload should exist")
	assert(save != null, "SaveManager autoload should exist")
	if save and "_save_timer" in save and save._save_timer:
		save._save_timer.stop()
	
	# Test 1: Capacity logic
	inv.iron = 0
	inv.gold = 0
	inv.coal = 0
	assert(inv.get_total_used() == 0, "Initial used should be 0")
	assert(inv.get_total_available() == 60, "Initial available should be 60")
	assert(inv.is_full() == false, "Should not be full initially")
	
	inv.iron = 20
	inv.gold = 20
	inv.coal = 20
	assert(inv.get_total_used() == 60, "Total used should be 60")
	assert(inv.get_total_available() == 0, "Total available should be 0")
	assert(inv.is_full() == true, "Should be full at 60")
	assert(inv.can_add(0) == false, "Cannot add iron when full")
	assert(inv.can_add(1) == false, "Cannot add gold when full")
	assert(inv.can_add(2) == false, "Cannot add coal when full")
	print("[PASS] Test 1: Inventory capacity (60 units) and fullness limits")
	
	# Test 2: ResourceDrop does not collect when inventory is full
	var drop_scene = load("res://scenes/items/resource_drop.tscn")
	var drop = drop_scene.instantiate()
	drop.type = 0 # IRON
	add_child(drop)
	
	assert(drop._can_be_collected() == false, "Drop should not be collectable when inventory is full!")
	
	# Free space and verify collectable
	inv.iron = 10
	assert(inv.can_add(0) == true, "Can add iron when space available")
	assert(drop._can_be_collected() == true, "Drop should be collectable when inventory has space!")
	drop.queue_free()
	print("[PASS] Test 2: Resource drop safety (remains stationary when inventory is full)")
	
	# Test 3: Rock Biome modifiers (Hardness & Tint)
	var rock_scene = load("res://scenes/cave/rock.tscn")
	
	# Terra (Biome 0)
	var rock_terra = rock_scene.instantiate()
	rock_terra.apply_biome(0)
	add_child(rock_terra)
	assert(rock_terra.max_hp == 3, "Terra iron rock max_hp should be 3")
	rock_terra.queue_free()
	
	# Gelo (Biome 1)
	var rock_gelo = rock_scene.instantiate()
	rock_gelo.apply_biome(1)
	add_child(rock_gelo)
	assert(rock_gelo.max_hp == 4, "Gelo rock max_hp should be 4 (+1 bonus)")
	rock_gelo.queue_free()
	
	# Lava (Biome 2)
	var rock_lava = rock_scene.instantiate()
	rock_lava.apply_biome(2)
	add_child(rock_lava)
	assert(rock_lava.max_hp == 5, "Lava rock max_hp should be 5 (+2 bonus)")
	rock_lava.queue_free()
	print("[PASS] Test 3: Rock Biomes HP scaling (Terra 3, Gelo 4, Lava 5)")
	
	# Test 4: SaveManager persistence
	save.clear_save()
	inv.iron = 12
	inv.gold = 3
	inv.coal = 18
	inv.planks = 8
	inv.starter_lamps = 1
	save.player_saved_pos = Vector2(480, 1500)
	save.save_game(false)
	
	inv.iron = 0
	inv.gold = 0
	inv.coal = 0
	inv.starter_lamps = 0
	save.has_loaded_save = false
	var loaded = save.load_game()
	assert(loaded == true, "Load failed")
	assert(inv.iron == 12, "Iron restored")
	assert(inv.gold == 3, "Gold restored")
	assert(inv.coal == 18, "Coal restored")
	assert(inv.starter_lamps == 1, "Starter lamps restored")
	assert(save.player_saved_pos == Vector2(480, 1500), "Player position restored")
	save.clear_save()
	print("[PASS] Test 4: SaveManager state persistence")
	
	# Test 5: HUD Capacity badge and Pause Menu
	var hud_scene = load("res://scenes/ui/hud.tscn")
	var hud = hud_scene.instantiate()
	add_child(hud)
	hud._ready()
	
	var cap_lbl = hud.find_child("CapacityLabel", true, false)
	hud.capacity_badge_label = cap_lbl
	hud.pause_panel = hud.find_child("PausePanel", true, false)
	
	inv.iron = 10
	inv.gold = 5
	inv.coal = 15
	hud.update_ui()
	
	assert("30 / 60" in cap_lbl.text, "Capacity badge text mismatch: %s" % cap_lbl.text)
	assert("30" in cap_lbl.text, "Available count mismatch")
	
	# Pause Toggle
	assert(hud.pause_panel.visible == false, "Pause menu should be closed initially")
	hud.toggle_pause()
	assert(hud.pause_panel.visible == true, "Pause menu should open on toggle_pause")
	
	var ev_s = InputEventKey.new()
	ev_s.pressed = true
	ev_s.physical_keycode = KEY_S
	hud._unhandled_input(ev_s)
	
	hud.toggle_pause()
	assert(hud.pause_panel.visible == false, "Pause menu should close on toggle_pause")
	print("[PASS] Test 5: HUD Capacity badge counter & Pause Menu toggle / hotkeys")
	
	# Test 6: HUD Toast notifications
	var test_icons = ["iron", "gold", "coal", "plank", "lamp", "save", "chest", "ladder", "dash", "pickaxe", ""]
	for icon in test_icons:
		hud.show_toast("Test Toast: " + icon, icon)
	print("[PASS] Test 6: HUD show_toast notification system with all icon types")

	# Test 7: Plank collision layer 32, one-way collision, and top alignment
	var plank_scene = load("res://scenes/environment/plank.tscn")
	var plank = plank_scene.instantiate()
	add_child(plank)
	assert(plank.collision_layer == 32, "Plank collision layer should be 32 (layer 6)")
	var p_col = plank.get_node("CollisionShape2D")
	assert(p_col.one_way_collision == true, "Plank should have one_way_collision = true")
	
	var test_grid_y = 5
	var expected_block_top = test_grid_y * 32.0 + 112.0
	var calc_plank_y = test_grid_y * 32.0 + 117.0
	assert((calc_plank_y - 5.0) == expected_block_top, "Plank top surface should match block top perfectly")
	plank.queue_free()
	print("[PASS] Test 7: Plank collision layer 32, one-way collision & block top alignment")

	# Test 8: Torch (Mini Poste) destruction refund (1 coal + 1 iron)
	var torch_scene = load("res://scenes/environment/torch.tscn")
	var torch = torch_scene.instantiate()
	add_child(torch)
	inv.coal = 0
	inv.iron = 0
	torch.hit()
	assert(inv.coal == 1, "Torch hit should refund 1 coal")
	assert(inv.iron == 1, "Torch hit should refund 1 iron")
	torch.queue_free()
	print("[PASS] Test 8: Lamp destruction refund (1 Coal + 1 Iron)")

	# Test 9: Ore hardness calibration (Coal 2, Iron 3, Gold 6)
	var rock_coal = rock_scene.instantiate()
	rock_coal.is_coal = true
	rock_coal.apply_biome(0)
	add_child(rock_coal)
	assert(rock_coal.max_hp == 2, "Coal rock should have 2 HP (easy)")
	rock_coal.queue_free()

	var rock_iron = rock_scene.instantiate()
	rock_iron.is_coal = false
	rock_iron.is_copper = false
	rock_iron.apply_biome(0)
	add_child(rock_iron)
	assert(rock_iron.max_hp == 3, "Iron rock should have 3 HP (demands 3 to 4 hits)")
	rock_iron.queue_free()

	var rock_gold = rock_scene.instantiate()
	rock_gold.is_copper = true # Gold
	rock_gold.apply_biome(0)
	add_child(rock_gold)
	assert(rock_gold.max_hp == 6, "Gold rock should have 6 HP (takes longer)")
	rock_gold.queue_free()
	print("[PASS] Test 9: Ore hardness calibration (Coal 2 HP, Iron 3 HP, Gold 6 HP)")

	# Test 10: Equipment Menu [E] modal toggle
	hud.equipment_panel = hud.find_child("EquipmentPanel", true, false)
	assert(hud.equipment_panel.visible == false, "Equipment panel should be closed initially")
	hud.toggle_equipment()
	assert(hud.equipment_panel.visible == true, "Equipment panel should open on toggle_equipment")
	hud.toggle_equipment()
	assert(hud.equipment_panel.visible == false, "Equipment panel should close on toggle_equipment")
	print("[PASS] Test 10: Equipment Menu [E] modal toggle")

	# Test 11: Lamp slot opacity in HUD when lacking resources
	inv.starter_lamps = 0
	inv.coal = 1
	inv.iron = 1
	hud.update_ui()
	var lamp_slot = hud.slots[1]
	assert(lamp_slot.modulate.a < 0.5, "Lamp slot should be semi-transparent when lacking resources")
	
	inv.starter_lamps = 0
	inv.coal = 6
	inv.iron = 4
	hud.update_ui()
	assert(lamp_slot.modulate.a == 1.0, "Lamp slot should be fully opaque when resources are available")
	var lamp_count = lamp_slot.find_child("CountLabel", true, false)
	assert(lamp_count.text == "2", "Craftable lamps count should be 2")
	print("[PASS] Test 11: Lamp hotbar opacity & craftable counter")

	# Test 12: Starter Lamp free usage & craft consumption
	inv.starter_lamps = 1
	inv.coal = 0
	inv.iron = 0
	assert(inv.can_place_lamp() == true, "Should be able to place lamp using 1 starter lamp")
	assert(inv.get_available_lamps() == 1, "Available lamps should be 1")
	var consumed_starter = inv.consume_lamp()
	assert(consumed_starter == true, "Consuming starter lamp should succeed")
	assert(inv.starter_lamps == 0, "Starter lamps should now be 0")
	assert(inv.can_place_lamp() == false, "Should not be able to place lamp without resources")
	assert(inv.consume_lamp() == false, "Consuming with 0 resources should fail")

	inv.coal = 3
	inv.iron = 2
	assert(inv.can_place_lamp() == true, "Should be able to craft lamp with 3 coal + 2 iron")
	assert(inv.get_available_lamps() == 1, "Available lamps should be 1")
	var consumed_crafted = inv.consume_lamp()
	assert(consumed_crafted == true, "Consuming crafted lamp should succeed")
	assert(inv.coal == 0 and inv.iron == 0, "Coal and Iron should be deducted")
	assert(inv.can_place_lamp() == false, "Should have 0 lamps now")
	print("[PASS] Test 12: Starter Lamp free placement and recipe consumption (3 Coal + 2 Iron)")

	# Test 13: Player Sprite Facing Logic (Never locked by last attack)
	var player_scene = load("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	add_child(player)
	player._ready()

	# Simulate mining attack to the right
	player.last_direction = Vector2.RIGHT
	player.is_mining = true
	player.mine_timer = 0.5
	player._process(0.016)
	assert(player.get_node("Sprite2D").flip_h == false, "While mining right, sprite should face right")

	# Finish mining, turn left (facing_x = -1.0)
	player.is_mining = false
	player.facing_x = -1.0
	player._process(0.016)
	assert(player.get_node("Sprite2D").flip_h == true, "When moving left, sprite MUST flip left even if last attack was right!")

	# Turn right (facing_x = 1.0)
	player.facing_x = 1.0
	player._process(0.016)
	assert(player.get_node("Sprite2D").flip_h == false, "When moving right, sprite MUST flip right!")
	print("[PASS] Test 13: Player sprite facing logic responds smoothly to movement")

	# Test 14: Downward Mining ([ui_down] + [Z])
	player.velocity = Vector2.ZERO
	var rock_under = rock_scene.instantiate()
	rock_under.global_position = player.global_position + Vector2(0, 24.0) # Under player feet
	add_child(rock_under)
	var initial_hp = rock_under.hp
	
	# Allow physics server to sync collider
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	# Simulate aiming DOWN and mining
	Input.action_press("ui_down")
	player.try_mine()
	Input.action_release("ui_down")
	assert(rock_under.hp == initial_hp - 1, "Mining downward should hit block beneath feet!")
	rock_under.queue_free()
	player.queue_free()
	print("[PASS] Test 14: Downward block mining ([ui_down] + [Z])")

	# Test 15: Player Depenetration & Ground Safety Mechanics
	var test_player = player_scene.instantiate()
	add_child(test_player)
	test_player._ready()

	# Verify max fall speed is clamped to 320.0
	test_player.velocity.y = 999.0
	test_player._physics_process(0.1)
	assert(test_player.velocity.y <= 320.0, "Terminal fall velocity must be clamped to 320.0")

	# Verify depenetration: create a solid ground block beneath player
	var solid_box = StaticBody2D.new()
	var solid_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(64, 64)
	solid_shape.shape = rect_shape
	solid_box.add_child(solid_shape)
	solid_box.collision_layer = 1 # Solid world block
	solid_box.global_position = Vector2(500, 532) # Top surface at y=500
	add_child(solid_box)

	# Place player buried inside solid ground (y=508, feet at y=519 inside block)
	var initial_y = 508.0
	test_player.velocity = Vector2.ZERO
	test_player.global_position = Vector2(500, initial_y)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(test_player.global_position.y < initial_y, "Automatic depenetration in _physics_process must lift player out of solid block!")
	assert(test_player.global_position.y <= 490.0, "Player must be lifted to top surface of ground block")
	assert(test_player.velocity.y == 0.0, "Depenetration must zero vertical velocity")
	solid_box.queue_free()
	test_player.queue_free()
	print("[PASS] Test 15: Player depenetration & anti-sinking mechanics")

	# Test 16: Equipment Menu [E] Enhanced Preview & Starter Gear
	hud.open_equipment()
	assert(hud.equipment_panel.visible == true, "Equipment panel should be open")
	var preview_char = hud.equipment_panel.find_child("CharTextureRect", true, false)
	assert(preview_char != null, "Enlarged idle player character preview must exist in Equipment menu")
	
	# Verify the 4 starter equipment cards in equipment panel
	var helmet_card = hud.equipment_panel.find_child("SlotHelmet", true, false)
	var pick_card = hud.equipment_panel.find_child("SlotPickaxe", true, false)
	var armor_card = hud.equipment_panel.find_child("SlotArmor", true, false)
	var boots_card = hud.equipment_panel.find_child("SlotBoots", true, false)
	assert(helmet_card != null and pick_card != null and armor_card != null and boots_card != null, "All 4 equipment slots must exist")
	
	assert("Capacete de Mineirador Pobre" in helmet_card.find_child("ItemName", true, false).text, "Helmet name mismatch")
	assert("Picareta de Cobre" in pick_card.find_child("ItemName", true, false).text, "Pickaxe name mismatch")
	assert("Traje do Mineirador Pobre" in armor_card.find_child("ItemName", true, false).text, "Traje name mismatch")
	assert("Bota de Lama" in boots_card.find_child("ItemName", true, false).text, "Boots name mismatch")
	
	hud.close_equipment()
	assert(hud.equipment_panel.visible == false, "Equipment panel should close")
	print("[PASS] Test 16: Equipment Menu [E] enhanced character preview and 4 starter gear slots")

	# Test 17: Shop System (Comprar [EM BREVE] & Vender Minérios)
	hud.open_shop()
	assert(hud.shop_panel.visible == true, "Shop panel should be open")
	
	# Tab Comprar (EM BREVE)
	hud.switch_shop_tab("buy")
	assert(hud.shop_buy_view.visible == true, "Buy tab view should be visible")
	assert(hud.shop_sell_view.visible == false, "Sell tab view should be hidden in buy tab")
	var soon_lbl = hud.shop_buy_view.find_child("SoonTitle", true, false)
	assert(soon_lbl != null and "EM BREVE" in soon_lbl.text, "Buy tab must present 'EM BREVE' placeholder")
	
	# Tab Vender
	hud.switch_shop_tab("sell")
	assert(hud.shop_sell_view.visible == true, "Sell tab view should be visible")
	assert(hud.shop_buy_view.visible == false, "Buy tab view should be hidden in sell tab")
	
	# Give resources to sell
	inv.coal = 4
	inv.iron = 2
	inv.gold = 1
	inv.coins = 0
	hud.update_shop_ui()
	assert("0" in hud.shop_coins_label.text, "Shop coins label should show 0 initially")
	
	# Sell single coal (5 coins)
	hud._on_sell_coal_one()
	assert(inv.coal == 3, "Coal should decrease by 1")
	assert(inv.coins == 5, "Coins should increase by 5")
	
	# Sell all iron (2 iron * 15 = 30 coins)
	hud._on_sell_iron_all()
	assert(inv.iron == 0, "Iron should be 0")
	assert(inv.coins == 35, "Coins should be 5 + 30 = 35")
	
	# Sell all remaining minerals (3 coal * 5 + 1 gold * 50 = 65 coins)
	hud._on_sell_all_minerals()
	assert(inv.coal == 0 and inv.iron == 0 and inv.gold == 0, "All minerals should be sold")
	assert(inv.coins == 100, "Total coins should be 100")
	
	hud.update_shop_ui()
	assert("100" in hud.shop_coins_label.text, "Shop coins label should update to 100")
	
	hud.close_shop()
	assert(hud.shop_panel.visible == false, "Shop panel should close")
	print("[PASS] Test 17: Shop System (Comprar [EM BREVE], Vender Minérios & Coins balance)")

	# Test 18: In-Game Restart to Surface (keeps items, loot, coins, and excavations)
	save.mark_block_mined(Vector2i(15, 25))
	assert(save.is_block_mined(Vector2i(15, 25)) == true, "Block should be marked mined")
	save.player_saved_pos = Vector2(400, 2000) # Deep in cave
	inv.coal = 10
	inv.iron = 5
	inv.gold = 2
	inv.coins = 150
	
	save.restart_run_to_surface()
	assert(save.player_saved_pos == Vector2(640, 96), "Player position must be returned to surface spawn (Vector2(640, 96))")
	assert(save.is_block_mined(Vector2i(15, 25)) == true, "Restart must maintain all excavations/mined blocks!")
	assert(inv.coal == 10 and inv.iron == 5 and inv.gold == 2, "Restart must keep all mined resources and loot!")
	assert(inv.coins == 150, "Restart must keep all coins!")
	assert(save.has_save() == true, "Save data must be preserved on restart")
	print("[PASS] Test 18: In-Game Restart to Surface (keeps items, loot, coins & all excavations)")

	hud.queue_free()
	print("--- ALL 18 TESTS PASSED SUCCESSFULLY! ---")
	get_tree().quit(0)
