# game_manager.gd
extends Node

signal lives_changed(new_lives)
signal score_changed(new_score)
signal game_over
signal game_started

@export var max_lives: int = 5
var current_lives: int = 5:
	set(value):
		current_lives = clamp(value, 0, max_lives)
		lives_changed.emit(current_lives)
		if current_lives <= 0:
			print("MANAGER: ¡Vida en 0! Disparando secuencia de muerte...")
			_trigger_death_sequence()
var score: int = 0

# Referencia al bus Master
@onready var master_bus_idx = AudioServer.get_bus_index("Master")

func _ready() -> void:
	# Asegurarnos de que al arrancar el motor esté a velocidad normal
	Engine.time_scale = 1.0
	reset_game()

func reset_game() -> void:
	# 1. Limpiar efectos de audio (Desactivar el filtro de la muerte)
	# Usamos un bucle para apagar cualquier efecto de filtro que hayamos activado
	for i in AudioServer.get_bus_effect_count(master_bus_idx):
		if AudioServer.get_bus_effect(master_bus_idx, i) is AudioEffectLowPassFilter:
			AudioServer.set_bus_effect_enabled(master_bus_idx, i, false)
	
	# 2. Resetear el tiempo del motor
	Engine.time_scale = 1.0
	
	# 3. Resetear valores
	current_lives = max_lives
	score = 0
	lives_changed.emit(current_lives)
	score_changed.emit(score)
	game_started.emit()

func decrease_lives():
	if current_lives <= 0: return
	
	current_lives -= 1
	lives_changed.emit(current_lives)
	
	if current_lives <= 0:
		_trigger_death_sequence()

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

func _trigger_death_sequence() -> void:
	# Emitir señal de fin de juego
	game_over.emit()
	
	# Activar Filtro (buscamos el LowPassFilter en el Master)
	for i in AudioServer.get_bus_effect_count(master_bus_idx):
		var effect = AudioServer.get_bus_effect(master_bus_idx, i)
		if effect is AudioEffectLowPassFilter:
			AudioServer.set_bus_effect_enabled(master_bus_idx, i, true)
			
			# Animación del filtro y el tiempo
			var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			# Ponemos la música "sorda"
			tween.tween_property(effect, "cutoff_hz", 400.0, 2.0).from(20000.0)
			# Ralentizamos el mundo
			tween.parallel().tween_property(Engine, "time_scale", 0.1, 2.0)
