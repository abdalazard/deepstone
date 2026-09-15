extends Node
# SoundManager — autoload global para SFX
# Uso: SoundManager.play("picking") / SoundManager.play("drop_item") / SoundManager.play("game_start")

const SFX: Dictionary = {
	"picking":    "res://assets/sounds/SFX/picking.ogg",
	"drop_item":  "res://assets/sounds/SFX/drop-item.ogg",
	"game_start": "res://assets/sounds/SFX/game-start.ogg",
	"xp_points":  "res://assets/sounds/SFX/xp-points.ogg",
	"level_up":    "res://assets/sounds/SFX/level-up.ogg",
	"walk":        "res://assets/sounds/SFX/walk.ogg",
	"dying_voice": "res://assets/sounds/SFX/dying-voice.ogg",
	"jump_voice":  "res://assets/sounds/SFX/jump-voice.ogg",
}

# Pool de players para permitir sobreposição (ex: picking em ritmo rápido)
const POOL_SIZE := 6
var _pool: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}

func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)
	# Pré-carrega streams
	for key in SFX:
		var res = load(SFX[key])
		if res:
			_streams[key] = res

func play(sfx_key: String, volume_db: float = 0.0) -> void:
	var stream = _streams.get(sfx_key)
	if not stream:
		push_warning("SoundManager: SFX '%s' não encontrado." % sfx_key)
		return
	# Pega o primeiro player livre do pool
	for p in _pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.play()
			return
	# Se todos ocupados, interrompe o mais antigo (sem posição de busca = recomeça)
	_pool[0].stream = stream
	_pool[0].volume_db = volume_db
	_pool[0].play()
