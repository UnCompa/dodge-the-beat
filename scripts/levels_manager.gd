extends Node

const SAVE_PATH = "user://level_progress.cfg"

# Definición central de todos los niveles del juego
var levels: Array[Dictionary] = [
	{
		"title": "Nivel 1",
		"subtitle": "Tutorial",
		"scene": "res://escenas/levels/level01/level01.tscn",
		"state": "available",  # El primer nivel siempre disponible
		"neon_color": Color(0.0, 1.0, 0.8),   # Cyan
	},
	{
		"title": "Nivel 2",
		"subtitle": "Marea",
		"scene": "res://escenas/levels/level02/level02.tscn",
		"state": "locked",
		"neon_color": Color(0.0, 0.683, 1.0, 1.0),   # Verde
	},
	{
		"title": "Nivel 3",
		"subtitle": "Panic",
		"scene": "res://escenas/levels/level03/level03.tscn",
		"state": "locked",
		"neon_color": Color(0.4, 1.0, 0.0),   # Verde
	},
	{
		"title": "Nivel 4",
		"subtitle": "Party",
		"scene": "res://escenas/levels/level04/level04.tscn",
		"state": "locked",
		"neon_color": Color(0.583, 0.0, 1.0, 1.0),   # Verde
	},
	{
		"title": "Nivel 5",
		"subtitle": "Emergency",
		"scene": "res://escenas/levels/level05/level05.tscn",
		"state": "locked",
		"neon_color": Color(1.0, 0.717, 0.0, 1.0),   # Verde
	},
	{
		"title": "Nivel 0",
		"subtitle": "Caos",
		"scene": "res://escenas/levels/level06/level06.tscn",
		"state": "available",
		"neon_color": Color(1.0, 0.0, 0.0, 1.0),   # Verde
	},
]

var current_level_index: int = 0

func _ready():
	load_progress()

# ──────────────────────────────────────────────
#  CARGA / GUARDADO
# ──────────────────────────────────────────────

func save_progress():
	var cfg = ConfigFile.new()
	for i in range(levels.size()):
		cfg.set_value("levels", "level_%d_state" % i, levels[i].state)
		cfg.set_value("levels", "level_%d_best_time" % i, levels[i].get("best_time", 0.0))
	cfg.save(SAVE_PATH)

func load_progress():
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return  # Primera vez: sin progreso guardado
	for i in range(levels.size()):
		if cfg.has_section_key("levels", "level_%d_state" % i):
			levels[i].state = cfg.get_value("levels", "level_%d_state" % i)
		if cfg.has_section_key("levels", "level_%d_best_time" % i):
			levels[i]["best_time"] = cfg.get_value("levels", "level_%d_best_time" % i)

func reset_progress():
	for i in range(levels.size()):
		levels[i].state = "locked" if i > 0 else "available"
		levels[i]["best_time"] = 0.0
	save_progress()

# ──────────────────────────────────────────────
#  LÓGICA DE PROGRESIÓN
# ──────────────────────────────────────────────

func complete_level(index: int, time: float = 0.0):
	if index < 0 or index >= levels.size():
		return
	levels[index].state = "completed"
	if time > 0.0:
		var prev = levels[index].get("best_time", 0.0)
		levels[index]["best_time"] = time if prev == 0.0 else min(prev, time)
	# Desbloquear el siguiente nivel
	var next = index + 1
	if next < levels.size() and levels[next].state == "locked":
		levels[next].state = "available"
	save_progress()

func is_unlocked(index: int) -> bool:
	if index < 0 or index >= levels.size():
		return false
	return levels[index].state != "locked"

func is_completed(index: int) -> bool:
	if index < 0 or index >= levels.size():
		return false
	return levels[index].state == "completed"

# ──────────────────────────────────────────────
#  CARGA DE ESCENAS
# ──────────────────────────────────────────────

func load_level(index: int):
	if not is_unlocked(index):
		push_warning("LevelManager: Nivel %d bloqueado." % index)
		return
	current_level_index = index
	var scene_path = levels[index].scene
	if not ResourceLoader.exists(scene_path):
		push_error("LevelManager: Escena no encontrada: " + scene_path)
		return
	get_tree().change_scene_to_file(scene_path)

func load_next_level():
	var next_level = current_level_index + 1
	print('Loading next level..' + str(next_level))
	load_level(next_level)

func load_current_level():
	load_level(current_level_index)

func go_to_level_select():
	get_tree().change_scene_to_file("res://escenas/selector_levels/selector_levels.tscn")

func go_to_main_menu():
	get_tree().change_scene_to_file("res://escenas/menu_principal/menu_principal.tscn")
