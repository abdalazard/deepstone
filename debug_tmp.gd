
extends SceneTree

func _init():
    var inv = root.get_node('Inventory')
    var save = root.get_node('SaveManager')
    print('save._get_inventory(): ', save._get_inventory())
    save.clear_save()
    inv.iron = 12
    save.save_game(false)
    inv.iron = 0
    var loaded = save.load_game()
    print('loaded: ', loaded, ' inv.iron: ', inv.iron)
    quit(0)
