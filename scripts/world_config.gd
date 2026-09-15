extends Node

# ============================================================
#  WorldConfig — Autoload singleton
#  Fonte única de verdade para as dimensões do mundo.
#  Altere aqui e todos os sistemas se adaptam automaticamente.
# ============================================================

# ── Superfície ──
const SURFACE_Y: float = 112.0    # Y onde começa o subsolo (topo da caverna)

# ── Limites de bioma (Y em world units) ──
# Altere esses valores para expandir ou contrair cada bioma.
const BIOME_TERRA_END:   float = 6496.0  # Terra:    SURFACE_Y → BIOME_TERRA_END  (grid y=0-199)
const BIOME_GELO_END:    float = 12896.0 # Gelo:     BIOME_TERRA_END → BIOME_GELO_END   (grid y=200-399)
const BIOME_VULCAO_END:  float = 19296.0 # Vulcânico: BIOME_GELO_END → BIOME_VULCAO_END (grid y=400-599)

# ── Limites derivados (arrays prontos para iterar) ──
# [Terra, Gelo, Vulcânico]
var BAND_MIN_Y: Array[float]:
	get: return [SURFACE_Y,       BIOME_TERRA_END, BIOME_GELO_END]

var BAND_MAX_Y: Array[float]:
	get: return [BIOME_TERRA_END, BIOME_GELO_END,  BIOME_VULCAO_END]

# ── Helpers ──
func biome_at(world_y: float) -> int:
	# Retorna: 0=Terra, 1=Gelo, 2=Vulcânico, -1=Superfície
	if world_y < SURFACE_Y:       return -1
	if world_y < BIOME_TERRA_END: return 0
	if world_y < BIOME_GELO_END:  return 1
	return 2

func is_underground(world_y: float) -> bool:
	return world_y >= SURFACE_Y
