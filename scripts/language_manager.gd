extends Node

signal language_changed(code: String)

const SETTINGS_PATH: String = "user://settings.cfg"
const CODE_EN: String = "en"
const CODE_PT: String = "pt"

# Dicionário PT-BR (chave) -> EN (valor), registrado como Translation com locale "en".
# O texto-fonte do jogo permanece em português; o inglês é aplicado em runtime via tr().
const EN: Dictionary = {
	# --- hud.tscn: barra superior ---
	"⏸️ [P]": "⏸️ [P]",
	"🏪 LOJA [L]": "🏪 SHOP [L]",
	"Ver tutorial rápido": "View quick tutorial",
	"Idioma: EN": "Language: EN",
	"Idioma: PT": "Language: PT",

	# --- hud.tscn: inventário ---
	"📦 MOCHILA & RECURSOS [I]": "📦 BACKPACK & RESOURCES [I]",
	"ITENS NA MOCHILA:": "ITEMS IN BACKPACK:",
	"Selecione um item": "Select an item",
	"Clique ou navegue com as setas para inspecionar e interagir.": "Click or navigate with the arrow keys to inspect and interact.",
	"Equipar [Z]": "Equip [Z]",
	"Soltar no Mapa [X]": "Drop on Map [X]",
	"ATALHOS:": "HOTKEYS:",
	"Selecione o atalho, depois o item.": "Select the hotkey, then the item.",

	# --- hud.tscn: equipamentos ---
	"🛡️ EQUIPAMENTOS [E]": "🛡️ EQUIPMENT [E]",
	"🧍 PERSONAGEM": "🧍 CHARACTER",
	"Mineirador": "Miner",
	"Nível: 0": "Level: 0",
	"FORCA\nVELOCIDADE\nPULO": "STRENGTH\nSPEED\nJUMP",
	"Capacete de Mineirador Pobre": "Poor Miner's Helmet",
	"Proteção rústica contra poeira e pedregulhos.": "Rustic protection against dust and rubble.",
	"Picareta de Cobre": "Copper Pickaxe",
	"Ferramenta básica para escavação de blocos.": "Basic tool for digging blocks.",
	"Traje do Mineirador Pobre": "Poor Miner's Suit",
	"Roupas simples de trabalho com remendos de couro.": "Simple work clothes with leather patches.",
	"Bota de Lama": "Mud Boots",
	"Botas de borracha impermeáveis para terrenos úmidos.": "Waterproof rubber boots for wet terrain.",
	"Luva de Couro": "Leather Gloves",
	"Aumenta a força (+1) e gera dano no chute (+1).": "Increases strength (+1) and adds kick damage (+1).",
	"🛡️ Menu de Equipamentos | [E] ou [Esc] para Fechar": "🛡️ Equipment Menu | [E] or [Esc] to Close",

	# --- hud.tscn: loja ---
	"🏪 LOJA DA MINA [L]": "🏪 MINE SHOP [L]",
	"Moedas de Ouro: 0": "Gold Coins: 0",
	"🛒 COMPRAR": "🛒 BUY",
	"💰 VENDER": "💰 SELL",
	"COMPRE EQUIPAMENTOS E UPGRADES COM SUAS MOEDAS:": "BUY EQUIPMENT AND UPGRADES WITH YOUR COINS:",
	"VENDA SEUS RECURSOS POR MOEDAS DE OURO:": "SELL YOUR RESOURCES FOR GOLD COINS:",
	"Você não tem recursos para vender.": "You have no resources to sell.",
	"Vender Todos os Minérios (Carvão, Ferro e Ouro)": "Sell All Ores (Coal, Iron and Gold)",
	"🏪 Loja da Mina | [L] ou [Esc] para Fechar": "🏪 Mine Shop | [L] or [Esc] to Close",

	# --- hud.tscn: baú ---
	"🧰 BAÚ DE ARMAZENAMENTO [X]": "🧰 STORAGE CHEST [X]",
	"Guarde seus minérios com segurança. Itens guardados no baú nunca são perdidos!": "Store your ores safely. Items kept in the chest are never lost!",
	"📦 NO BAÚ:": "📦 IN CHEST:",
	"• Carvão: 0": "• Coal: 0",
	"• Minério de Ferro: 0": "• Iron Ore: 0",
	"• Minério de Ouro: 0": "• Gold Ore: 0",
	"🎒 NA MOCHILA:": "🎒 IN BACKPACK:",
	"📥 Guardar da Mochila": "📥 Store from Backpack",
	"📤 Pegar Tudo do Baú": "📤 Take All from Chest",

	# --- hud.tscn: pausa /config ---
	"⏸️ JOGO PAUSADO": "⏸️ GAME PAUSED",
	"▶  Continuar ([P] / [Esc])": "▶  Resume ([P] / [Esc])",
	"💾  Salvar Progresso ([S])": "💾  Save Progress ([S])",
	"⚙️  Configurações": "⚙️  Settings",
	"🚪  Sair do Jogo ([Q])": "🚪  Quit Game ([Q])",
	"⚙️ CONFIGURAÇÕES": "⚙️ SETTINGS",
	"🔄  Voltar para Superfície ([R])": "🔄  Return to Surface ([R])",
	"⚠️  Resetar Jogo (Zerar Tudo)": "⚠️  Reset Game (Wipe Everything)",
	"✖  Fechar": "✖  Close",

	# --- hud.tscn: forja ---
	"FORJA DA SUPERFÍCIE [X]": "SURFACE FORGE [X]",
	"Materiais: 0 Troncos | 0 Carvões | 0 Ferros": "Materials: 0 Logs | 0 Coal | 0 Iron",
	"Poste de Luz (Lampião Portátil)": "Light Post (Portable Lantern)",
	"Custo: 3 Carvões + 2 Ferros -> 1 Poste": "Cost: 3 Coal + 2 Iron -> 1 Post",
	"Forjar 1 Poste": "Forge 1 Post",
	"Escadas de Madeira": "Wooden Ladders",
	"Custo: 1 Tronco de Madeira -> 5 Escadas": "Cost: 1 Wood Log -> 5 Ladders",
	"Forjar 5 Escadas": "Forge 5 Ladders",
	"Tábuas de Madeira": "Wooden Planks",
	"Custo: 1 Tronco de Madeira -> 5 Tábuas": "Cost: 1 Wood Log -> 5 Planks",
	"Forjar 5 Tábuas": "Forge 5 Planks",
	"Coluna de Suporte": "Support Column",
	"Custo: 3 Lamas + 3 Pedras -> 1 Coluna": "Cost: 3 Mud + 3 Stone -> 1 Column",
	"Forjar 1 Coluna": "Forge 1 Column",
	"Laje de Tijolos": "Brick Slab",
	"Custo: 2 Lamas + 2 Pedras -> 1 Laje": "Cost: 2 Mud + 2 Stone -> 1 Slab",
	"Forjar 1 Laje": "Forge 1 Slab",
	"Nova Picareta": "New Pickaxe",
	"Custo: 1 Ferro + 2 Madeiras + 1 Pedra": "Cost: 1 Iron + 2 Wood + 1 Stone",
	"Forjar Picareta": "Forge Pickaxe",
	"Forja Portátil": "Portable Forge",
	"Custo: 5 Pedras + 3 Ferros": "Cost: 5 Stone + 3 Iron",
	"Forjar Forja": "Forge Forge",
	"Fechar": "Close",

	# --- hud.tscn: morte / level up ---
	"💀 VOCÊ MORREU!": "💀 YOU DIED!",
	"Todos os recursos coletados foram perdidos (o que estava guardado no baú ficou salvo). Seus equipamentos foram preservados. Deseja voltar para a superfície e começar da onde parou?": "All collected resources were lost (what was stored in the chest is safe). Your equipment was preserved. Do you want to return to the surface and pick up where you left off?",
	"Voltar à Superfície": "Return to Surface",
	"⭐ NÍVEL 1 ALCANÇADO! ⭐": "⭐ LEVEL 1 REACHED! ⭐",
	"Próximo Nível: 170 EXP": "Next Level: 170 EXP",

	# --- hud.gd: defs da mochila ---
	"Picareta de Mineração": "Mining Pickaxe",
	"Ferramenta para escavar lama e minérios. Possui durabilidade e desgasta ao bater em minérios pesados.": "Tool for digging dirt and ores. Has durability and wears down when hitting heavy ores.",
	"Poste de Luz Portátil": "Portable Light Post",
	"Ilumina cavernas profundas. Posicionável no solo rochoso e sobre tábuas de madeira.": "Illuminates deep caves. Placeable on rocky ground and on wooden planks.",
	"Escada de Madeira": "Wooden Ladder",
	"Construção de madeira para escalar poços verticais. Forjada na Forja com troncos de árvores.": "Wooden construction for climbing vertical shafts. Forged at the Forge with tree logs.",
	"Tábua de Madeira": "Wooden Plank",
	"Plataforma horizontal resistente para pontes subterrâneas. Permite transpor abismos e sustenta postes de luz.": "Sturdy horizontal platform for underground bridges. Lets you cross chasms and supports light posts.",
	"Forja compacta forjada na superfície. Implante em qualquer lugar do subsolo para forjar sem voltar à superfície!": "Compact forge crafted on the surface. Deploy it anywhere underground to forge without returning to the surface!",
	"Pilar estrutural forjado com lama e pedra. Sustenta blocos 'pendurados' para evitar quedas.": "Structural pillar forged with mud and stone. Supports 'hanging' blocks to prevent collapses.",
	"Laje estrutural de tijolos. Serve de base para apoiar e segurar blocos acima.": "Structural brick slab. Serves as a base to support and hold blocks above.",
	"Madeira (Troncos)": "Wood (Logs)",
	"Troncos nobres obtidos ao podar árvores da superfície ou raízes subterrâneas. Matéria-prima essencial na Forja.": "Fine logs obtained by chopping surface trees or underground roots. Essential raw material at the Forge.",
	"Minério de Ferro": "Iron Ore",
	"Minério bruto resistente e condutor. Usado para criar ferramentas, postes e aprimorar equipamentos.": "Strong, conductive raw ore. Used to craft tools, posts and upgrade equipment.",
	"Minério de Ouro": "Gold Ore",
	"Metal nobre e reluzente de alto valor comercial e grande raridade. Venda na Loja por 50 moedas!": "Noble, gleaming metal of great commercial value and rarity. Sell it at the Shop for 50 coins!",
	"Carvão Mineral": "Coal Ore",
	"Combustível fóssil primordial abundante. Usado para iluminação e forjas.": "Abundant primordial fossil fuel. Used for lighting and forges.",
	"Pedra Bruta": "Raw Stone",
	"Pedra escavada do subsolo. Usada na construção de pisos de tijolo, forjas portáteis e ferramentas.": "Stone dug from underground. Used to build brick floors, portable forges and tools.",
	"Lama": "Mud",
	"Lama coletada das escavações. Usada para moldar e forjar pisos de tijolo.": "Mud collected from excavations. Used to mold and forge brick floors.",

	# --- hud.gd: hotbar config ---
	"⚙ CONFIGURAR ATALHOS DA HOTBAR (1-6)": "⚙ SET UP HOTBAR HOTKEYS (1-6)",
	"Clique em um slot (1-6) e depois selecione o item desejado:": "Click a slot (1-6) and then select the desired item:",
	"Fechar [X]": "Close [X]",
	"[%d] %s": "[%d] %s",
	"Picareta": "Pickaxe",
	"Poste de Luz": "Light Post",
	"Escada": "Ladder",
	"Tabua": "Plank",
	"%s (label de item)": "Item",
	"Slot %d atribuído: %s": "Slot %d assigned: %s",

	# --- hud.gd: level up ---
	"★ NÍVEL %d ALCANÇADO! ★": "★ LEVEL %d REACHED! ★",
	"EXP Necessária para Nível %d: %d EXP": "EXP Needed for Level %d: %d EXP",

	# --- hud.gd: níveis / bonus de upgrade nas slots ---
	"  [Nivel %d/%d]": "  [Level %d/%d]",
	"+%d de dano e +%d%% de durabilidade/velocidade de mineracao": "+%d damage and +%d%% durability/mining speed",
	"+%d de alcance de luz na escuridao": "+%d light range in darkness",
	"+%d de carga maxima na mochila": "+%d max backpack capacity",
	"+%d%% de altura de pulo e +%d%% de velocidade": "+%d%% jump height and +%d%% speed",
	"+%d de forca e +%d de dano de chute": "+%d strength and +%d kick damage",
	"\nNivel %d: %s.": "\nLevel %d: %s.",
	"[color=#9b6]Requer:[/color]": "[color=#9b6]Requires:[/color]",

	# --- inventory.gd: fallback names de slots de equipamento ---
	"Botas": "Boots",
	"Luvas": "Gloves",

	# --- hud.gd: materiais da forja (nomes plurais) ---
	"Troncos": "Logs",
	"Carvoes": "Coal",
	"Ferros": "Iron",
	"Ouros": "Gold",
	"Pedras": "Stone",
	"Lamas": "Mud",
	"Tabuas": "Planks",
	"Escadas": "Ladders",
	"Colunas": "Columns",
	"Lajes": "Slabs",

	# --- hud.gd: forja abas ---
	"⚒ CRIAR ITENS": "⚒ CREATE ITEMS",
	"⭐ APRIMORAR EQUIPES": "⭐ UPGRADE EQUIPMENT",
	"🔧 REPARAR": "🔧 REPAIR",
	"Reparar Tudo (0 moedas)": "Repair All (0 coins)",

	# --- hud.gd: equipamentos ---
	"Substituir [Z]": "Replace [Z]",
	"CAPACETE": "HELMET",
	"PICARETA": "PICKAXE",
	"TRAJE": "SUIT",
	"BOTAS": "BOOTS",
	"LUVAS": "GLOVES",
	"SUBSTITUIR %s:": "REPLACE %s:",
	"%s\n%s": "%s\n%s",
	"✓ Em Uso": "✓ In Use",
	"Equipar": "Equip",

	# --- hud.gd: forja craft toasts ---
	"Recursos insuficientes! Requer 1 Ferro, 2 Madeiras e 1 Pedra.": "Not enough resources! Requires 1 Iron, 2 Wood and 1 Stone.",
	"Recursos insuficientes! Requer 3 Carvões e 2 Ferros.": "Not enough resources! Requires 3 Coal and 2 Iron.",
	"Sem madeira suficiente! Requer 1 Tronco de Madeira.": "Not enough wood! Requires 1 Wood Log.",
	"Recursos insuficientes! Requer 3 Lamas e 3 Pedras.": "Not enough resources! Requires 3 Mud and 3 Stone.",
	"Recursos insuficientes! Requer 2 Lamas e 2 Pedras.": "Not enough resources! Requires 2 Mud and 2 Stone.",
	"Recursos insuficientes! Requer 5 Pedras e 3 Ferros.": "Not enough resources! Requires 5 Stone and 3 Iron.",

	# --- hud.gd: resource names ---
	"Ferro": "Iron",
	"Ouro": "Gold",
	"Carvão": "Coal",
	"Madeira": "Wood",
	"Pedra": "Stone",
	"Tábua": "Plank",

	# --- hud.gd: reparo ---
	"[color=#cfc7b0]Custo:[/color]": "[color=#cfc7b0]Cost:[/color]",
	"Quebrada": "Broken",
	"Desgastada": "Worn",
	"Capacete": "Helmet",
	"Desgastado": "Worn",
	"Nenhum equipamento precisa de reparo.": "No equipment needs repair.",
	"🔧 Reparar Tudo (%d moedas)": "🔧 Repair All (%d coins)",
	"%s  (%s)": "%s  (%s)",
	"🛠 Reparar (%d moedas)": "🛠 Repair (%d coins)",
	"Nenhum material util": "No useful material",
	"%d %s": "%d %s",

	# --- hud.gd: upgrade ---
	"%s  (%d/%d)": "%s  (%d/%d)",
	"Requer:": "Requires:",
	"✓ Nível Máximo": "✓ Max Level",
	"🔒 Nível %d": "🔒 Level %d",
	"Aprimorar": "Upgrade",

	# --- hud.gd: estatísticas / hotbar ---
	"%d\n%d/%d\n%d/%d": "%d\n%d/%d\n%d/%d",
	"Nível: %d": "Level: %d",
	"%d / %d": "%d / %d",
	"Atalho %d selecionado. Clique num item.": "Hotkey %d selected. Click an item.",

	# --- hud.gd: loja ---
	"[O] Moedas de Ouro: %d": "[O] Gold Coins: %d",
	"%s — Custo: %d Moedas": "%s — Cost: %d Coins",
	"✓ Possui": "✓ Owned",
	"Comprar [Z]": "Buy [Z]",
	"%s (x%d) — Preço: %d moedas cada": "%s (x%d) — Price: %d coins each",
	"Vender 1 (+%d)": "Sell 1 (+%d)",
	"Vender Tudo (+%d)": "Sell All (+%d)",

	# --- hud.gd: inventário toasts ---
	"Atalho %d: %s": "Hotkey %d: %s",
	"%s\n\nDurabilidade: %d/%d": "%s\n\nDurability: %d/%d",
	"Equipar [%s]": "Equip [%s]",
	"%s equipada!": "%s equipped!",
	"Sem unidades para dropar!": "No units to drop!",
	"Nv. %d": "Lv. %d",
	"QUEBR.": "BROKEN",
	"QUEBRADA": "BROKEN",
	"• Carvão: %d": "• Coal: %d",
	"• Minério de Ferro: %d": "• Iron Ore: %d",
	"• Minério de Ouro: %d": "• Gold Ore: %d",
	"Recursos guardados no Baú!": "Resources stored in the Chest!",
	"Sua mochila já está cheia!": "Your backpack is already full!",
	"Recursos retirados do Baú!": "Resources taken from the Chest!",

	# --- inventory.gd: dano/reparo/morte ---
	"-%d de Dano (Recebido %d, Absorvido %d)": "-%d Damage (Taken %d, Absorbed %d)",
	"Moedas insuficientes para reparar (%d necessárias)!": "Not enough coins to repair (%d required)!",
	"Picareta reparada!": "Pickaxe repaired!",
	"Capacete reparado!": "Helmet repaired!",
	"Moedas insuficientes (%d necessárias)!": "Not enough coins (%d required)!",
	"Todos os equipamentos reparados!": "All equipment repaired!",
	"Você morreu! Os recursos coletados foram perdidos.": "You died! Collected resources were lost.",

	# --- inventory.gd: equip definitions ---
	"Capacete com Lanterna": "Helmet with Lantern",
	"Possui foco luminoso frontal acoplado para iluminar o subsolo.": "Has an attached frontal light to illuminate the underground.",
	"Capacete de Ferro Iluminado": "Illuminated Iron Helmet",
	"Lanterna de alto alcance e casco blindado forjado em ferro espesso.": "Long-range lantern and armored shell forged from thick iron.",
	"Ferramenta básica de mineração. Durabilidade: 100 HP.": "Basic mining tool. Durability: 100 HP.",
	"Picareta de Ferro Reforçada": "Reinforced Iron Pickaxe",
	"+60% de resistência. Durabilidade: 160 HP e corte 25% mais rápido.": "+60% durability. 160 HP and 25% faster mining.",
	"Picareta de Ouro Nobre": "Noble Gold Pickaxe",
	"Super resistente (+150%) e veloz. Durabilidade: 250 HP e corte 60% mais rápido.": "Super sturdy (+150%) and fast. 250 HP and 60% faster mining.",
	"Roupas simples de algodão com bolsos básicos (60 carga).": "Simple cotton clothes with basic pockets (60 capacity).",
	"Traje Reforçado": "Reinforced Suit",
	"Costura reforçada com bolsos extras (+20 carga: total 80).": "Reinforced stitching with extra pockets (+20 capacity: 80 total).",
	"Traje do Explorador": "Explorer's Suit",
	"Mochila integrada de alta resistência (+40 carga: total 100).": "High-durability integrated backpack (+40 capacity: 100 total).",
	"Botas comuns de borracha para trabalho pesado na lama.": "Common rubber boots for heavy work in the mud.",
	"Botas de Couro Leves": "Light Leather Boots",
	"+15% de velocidade de corrida e +15% de altura no salto.": "+15% running speed and +15% jump height.",
	"Botas de Aço com Molas": "Steel Spring Boots",
	"+25% de velocidade e +30% de altura de salto extraordinário.": "+25% speed and +30% extraordinary jump height.",
	"Aumenta a força (+1) e gera dano no chute (+1) ao apertar [X] em blocos.": "Increases strength (+1) and adds kick damage (+1) when pressing [X] on blocks.",
	"Luva de Ferro": "Iron Gauntlets",
	"Manopla reforçada de ferro (+2 força, +2 dano de chute).": "Reinforced iron gauntlet (+2 strength, +2 kick damage).",
	"Luva de Ouro Nobre": "Noble Gold Gauntlets",
	"Luva resiliente banhada a ouro (+3 força, +3 dano de chute).": "Resilient gold-plated glove (+3 strength, +3 kick damage).",
	"Traje": "Suit",
	"+1 Força (+2 de dano por golpe) e +10%% de Resistência (durabilidade). Nível %d": "+1 Strength (+2 damage per hit) and +10%% Durability. Level %d",
	"+60 de Alcance de Luz na escuridão. Nível %d": "+60 Light Range in darkness. Level %d",
	"+20 de Carga máxima na mochila. Nível %d": "+20 Maximum backpack capacity. Level %d",
	"+0.20 de Força de Pulo e +0.15 de Velocidade. Nível %d": "+0.20 Jump Strength and +0.15 Speed. Level %d",
	"+1 de Força e +1 de Dano no Chute. Nível %d": "+1 Strength and +1 Kick Damage. Level %d",
	"Equipamento no nível máximo (%d/%d).": "Equipment at maximum level (%d/%d).",

	# --- inventory.gd: toasts ---
	"Nível %d Alcançado!": "Level %d Reached!",
	"+%d Moedas de Ouro!": "+%d Gold Coins!",
	"Sua picareta quebrou! Escave com as mãos ou forje uma nova.": "Your pickaxe broke! Dig with your hands or forge a new one.",
	"Equipado: %s": "Equipped: %s",
	"Moedas insuficientes!": "Not enough coins!",
	"+1 Bomba Adquirida!": "+1 Bomb Acquired!",
	"Requer Nível %d!": "Requires Level %d!",
	"Comprado: %s!": "Bought: %s!",
	"Equipamento Aprimorado!": "Equipment Upgraded!",
	"Picareta reforçada! +%d de Resistência (%d/%d)": "Pickaxe reinforced! +%d Durability (%d/%d)",
	"Nova Picareta Forjada!": "New Pickaxe Forged!",
	"Poste de Luz Forjado!": "Light Post Forged!",
	"+5 Escadas Forjadas!": "+5 Ladders Forged!",
	"+5 Tábuas Forjadas!": "+5 Planks Forged!",
	"+1 Coluna de Suporte Forjada!": "+1 Support Column Forged!",
	"+1 Laje de Tijolos Forjada!": "+1 Brick Slab Forged!",
	"Forja Portátil Forjada!": "Portable Forge Forged!",
	"Mochila Cheia! (%d/%d)": "Backpack Full! (%d/%d)",
	"+%d Ferro": "+%d Iron",
	"+%d Ouro": "+%d Gold",
	"+%d Carvão": "+%d Coal",
	"+%d Madeira": "+%d Wood",
	"+%d Pedra": "+%d Stone",
	"+%d Lama": "+%d Mud",
	"Picareta quebrada recuperada! Forje uma nova.": "Broken pickaxe recovered! Forge a new one.",
	"Forja Portátil recuperada!": "Portable Forge recovered!",
	"+%d Coluna de Suporte": "+%d Support Column",
	"+%d Laje de Tijolos": "+%d Brick Slab",
	"+%d Bomba!": "+%d Bomb!",
	"Item solto no chão!": "Item dropped on the ground!",

	# --- player.gd ---
	"★ LEVEL UP! NÍVEL %d! ★": "★ LEVEL UP! LEVEL %d! ★",
	"Descida Rápida!": "Fast Descent!",
	"Chute no bloco!": "Block kick!",
	"Sem postes disponíveis! Crie na Forja com carvão e ferro.": "No posts available! Craft some at the Forge with coal and iron.",
	"Sem escadas! Crie na Forja usando madeira.": "No ladders! Craft some at the Forge using wood.",
	"Sem tábuas! Crie na Forja usando madeira.": "No planks! Craft some at the Forge using wood.",
	"Sem forjas portáteis! Crie na Forja com 5 terra, 4 pedra e 2 ferro.": "No portable forges! Craft one at the Forge with 5 dirt, 4 stone and 2 iron.",
	"Sem colunas de suporte! Forje na Forja.": "No support columns! Forge some at the Forge.",
	"Sem lajes de tijolos! Forje na Forja.": "No brick slabs! Forge some at the Forge.",
	"Sem postes disponíveis! Crie na Forja.": "No posts available! Craft some at the Forge.",
	"Sem colunas de suporte!": "No support columns!",
	"Coluna Instalada!": "Column Installed!",
	"Sem lajes de tijolos!": "No brick slabs!",
	"Sem chão para manter a laje": "No ground to support the slab",
	"Laje Instalada!": "Slab Installed!",
	"Sem forjas portáteis! Crie na Forja com 5 lama, 4 pedra e 2 ferro.": "No portable forges! Craft one at the Forge with 5 mud, 4 stone and 2 iron.",
	"Forja Portátil Instalada!": "Portable Forge Installed!",
	"Sua picareta está quebrada! Forje uma nova na forja.": "Your pickaxe is broken! Forge a new one at the forge.",
	"Britadeira!": "Jackhammer!",

	# --- world prompts/efeitos ---
	"[X] Abrir Baú": "[X] Open Chest",
	"Guardou %d minérios no Baú!": "Stored %d ores in the Chest!",
	"Nenhum recurso na mochila para guardar.": "No resources in your backpack to store.",
	"O Baú está vazio!": "The Chest is empty!",
	"Retirou %d minérios do Baú!": "Took %d ores from the Chest!",
	"Mochila cheia! Não há espaço para retirar itens.": "Backpack full! No room to take items out.",
	"[X] Usar Forja": "[X] Use Forge",
	"+1 Pedra, +1 Lama": "+1 Stone, +1 Mud",
	"Entrada da Mina": "Mine Entrance",
	"Mina: Cave o bloco à esquerda para descer!": "Mine: Dig the block on the left to descend!",
	"Caveira Nv. %d": "Skull Lv. %d",
	"+%d de Vida (Caveira Nv.%d)": "+%d Health (Skull Lv.%d)",
	"+1 Tábua": "+1 Plank",
	"+1 Carvão, +1 Ferro (Poste Desmontado)": "+1 Coal, +1 Iron (Post Dismantled)",
	"+10 Troncos de Madeira!": "+10 Wood Logs!",
	"Árvore cresceu novamente!": "The tree grew back!",
	"+1 Lanterna": "+1 Lantern",
	"+1 Tronco de Madeira": "+1 Wood Log",
	"+1 Escada": "+1 Ladder",
	"+1 Pedra": "+1 Stone",
	"+1 Lama": "+1 Mud",
	"Materiais da Picareta Recuperados!": "Pickaxe materials recovered!",
	"+1 Forja Portátil": "+1 Portable Forge",
	"Progresso Salvo!": "Progress Saved!",
	"🎵 %s": "🎵 %s",

	# --- start_screen / title_screen / mundo ---
	"TUTORIAL RÁPIDO": "QUICK TUTORIAL",
	"MOVIMENTO": "MOVEMENT",
	"← →   Andar": "← →   Walk",
	"↑   Pular / Subir Escada": "↑   Jump / Climb Ladder",
	"↓ ↓   Descer Rápido da Escada": "↓ ↓   Slide Down the Ladder",
	"AÇÃO": "ACTION",
	"Z   Cavar / Coletar": "Z   Dig / Collect",
	"X (Segurar)   Arrastar Pedras Pesadas · Chutar": "X (Hold)   Drag Heavy Rocks · Kick",
	"C   Coletar Itens Próximos": "C   Collect Nearby Items",
	"MENUS": "MENUS",
	"I   Abrir / Fechar Inventário": "I   Open / Close Inventory",
	"E   Equipamentos": "E   Equipment",
	"L   Loja": "L   Shop",
	"P   Pausa / Configurações": "P   Pause / Settings",
	"Pressione [ Z ] para Iniciar": "Press [ Z ] to Start",
	"Pressione qualquer tecla para continuar...": "Press any key to continue...",
	"ESCADA": "LADDER",
	"Caveira Nv. 0": "Skull Lv. 0",
	"Pressione [ Z ] para Continuar\n[ R ] para Novo Jogo": "Press [ Z ] to Continue\n[ R ] for New Game",
	"Pressione [ Z ] ou [ Esc ] para Fechar": "Press [ Z ] or [ Esc ] to Close",
	# --- Forja portátil / capacete quebrado ---
	"Sua lanterna quebrou! Repare o capacete na forja.": "Your headlamp broke! Repair your helmet at the forge.",
	"Só é possível criar uma forja sobre uma rocha! Procure uma pedra por perto.": "A portable forge can only be placed on a rock! Look for a boulder nearby.",
	# --- Nomes dos biomas ---
	"Vale do Quartzo Cantante": "Valley of Singing Quartz",
	"Além das Neves Eternas": "Beneath the Frost",
	"A Ascensão Ardente": "Molten Ascent",
}

var current_code: String = CODE_EN

func _ready() -> void:
	# Tabela EN: PT -> EN
	var translation_en := Translation.new()
	translation_en.locale = CODE_EN
	for key in EN:
		translation_en.add_message(key, EN[key])
	TranslationServer.add_translation(translation_en)

	# Tabela PT: chave -> propria chave (o texto-fonte do jogo ja e PT)
	# Sem isso, o fallback do Godot vai usar "en" e exibir ingles mesmo com locale PT
	var translation_pt := Translation.new()
	translation_pt.locale = CODE_PT
	for key in EN:
		translation_pt.add_message(key, key)
	TranslationServer.add_translation(translation_pt)

	_load_saved()
	apply_code(current_code)

func get_code() -> String:
	return current_code

func get_short() -> String:
	return "EN" if current_code == CODE_EN else "PT"

func is_english() -> bool:
	return current_code == CODE_EN

func toggle() -> void:
	set_code(CODE_PT if is_english() else CODE_EN)

func set_code(code: String) -> void:
	if code != CODE_EN and code != CODE_PT:
		return
	current_code = code
	apply_code(code)
	_save()
	language_changed.emit(current_code)

func apply_code(code: String) -> void:
	if code != CODE_EN and code != CODE_PT:
		return
	current_code = code
	TranslationServer.set_locale(code)

func _load_saved() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) == OK:
		var saved: String = cf.get_value("app", "language", CODE_EN)
		if saved == CODE_PT or saved == CODE_EN:
			current_code = saved

func _save() -> void:
	var cf := ConfigFile.new()
	cf.set_value("app", "language", current_code)
	cf.save(SETTINGS_PATH)