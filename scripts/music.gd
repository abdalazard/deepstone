extends Node
# Gerenciador global de música. Inicia a faixa da caverna de terra assim que o
# jogo abre (tela de título) e persiste entre cenas. As trocas de ambiente
# têm transição suave com alerta no HUD.

var music_earth: AudioStreamOggVorbis = preload("res://assets/sounds/Valley_of_Singing_Quartz.ogg")
var music_ice: AudioStreamOggVorbis = preload("res://assets/sounds/Beneath_the_Frost.ogg")
var music_lava: AudioStreamOggVorbis = preload("res://assets/sounds/Molten_Ascent.ogg")

var player: AudioStreamPlayer
var current_biome: int = 0 # 0 terra/superfície, 1 gelo, 2 lava

func _ready() -> void:
	player = AudioStreamPlayer.new()
	player.name = "MusicPlayer"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	# Loop em todas as músicas e início imediato (Valley of Singing Quartz)
	music_earth.loop = true
	music_ice.loop = true
	music_lava.loop = true
	player.stream = music_earth
	player.volume_db = -40.0
	player.play()
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -8.0, 1.8)

func update_biome(py: float) -> void:
	var biome := 0
	if py >= WorldConfig.BIOME_GELO_END:
		biome = 2 # Lava
	elif py >= WorldConfig.BIOME_TERRA_END:
		biome = 1 # Gelo
	# Superfície e caverna de terra compartilham a mesma música (Valley)
	if biome == current_biome:
		return
	current_biome = biome
	var stream: AudioStream = null
	var label := ""
	match biome:
		1:
			stream = music_ice
			label = "Beneath the Frost"
		2:
			stream = music_lava
			label = "Molten Ascent"
		_:
			stream = music_earth
			label = "Valley of Singing Quartz"
	# Transição suave ao trocar de música/ambiente
	_fade_to(stream, label)

func _fade_to(stream: AudioStream, label: String) -> void:
	if not is_instance_valid(player):
		return
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -50.0, 1.1)
	tween.tween_callback(func():
		if stream == null:
			player.stop()
			return
		player.stream = stream
		player.volume_db = -40.0
		player.play()
		var scene := get_tree().current_scene
		if scene:
			var hud := scene.get_node_or_null("HUD")
			if hud and hud.has_method("show_toast"):
				hud.show_toast("🎵 " + label, "wood")
	)
	tween.tween_property(player, "volume_db", -8.0, 1.6)